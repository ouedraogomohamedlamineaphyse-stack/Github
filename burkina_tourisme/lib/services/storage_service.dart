import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'cloudinary_service.dart';

// ✅ CLASSE RÉSULTAT — interface identique à l'ancienne version

class StorageResult {
  final String? url;
  final String? path; // correspond au publicId Cloudinary
  final String? error;
  final bool isSuccess;

  const StorageResult._({
    this.url,
    this.path,
    this.error,
    required this.isSuccess,
  });

  factory StorageResult.success(String url, {String? path}) =>
      StorageResult._(url: url, path: path, isSuccess: true);

  factory StorageResult.error(String message) =>
      StorageResult._(error: message, isSuccess: false);
}

// ✅ CLASSE SERVICE
class StorageService {
  static final ImagePicker _picker = ImagePicker();
  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB

  // ___Choisir une image____
  
  static Future<XFile?> choisirImage({
    bool depuisCamera = false,
    double maxWidth = 1920,
    double maxHeight = 1920,
    int quality = 85,
  }) async {
    try {
      final source = depuisCamera ? ImageSource.camera : ImageSource.gallery;
      return await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
      return null;
    }
  }

  // ___Compression avant upload___
  static Future<Uint8List> _compresserImage(
      Uint8List bytes, String extension) async {
    if (kIsWeb) return bytes;
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1200,
        minHeight: 1200,
        quality: 85,
        format:
            extension == 'png' ? CompressFormat.png : CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      debugPrint('Erreur compression: $e');
      return bytes;
    }
  }

  // ___Upload avec progression____
  
  static Future<StorageResult> uploadImageAvecProgression({
    required XFile image,
    required String dossier,
    required Function(double) onProgression,
    String? userId,
    bool compresser = true,
  }) async {
    try {
      Uint8List bytes = await image.readAsBytes();

      if (bytes.length > _maxFileSize) {
        return StorageResult.error('Fichier trop volumineux (max 5MB)');
      }

      final extension = image.name.split('.').last.toLowerCase();

      if (compresser && !kIsWeb) {
        bytes = await _compresserImage(bytes, extension);
      }

      // Délégation à CloudinaryService
      final result = await CloudinaryService.uploadBytes(
        bytes: bytes,
        dossier: dossier,
        nomFichier: image.name,
        onProgression: onProgression,
        userId: userId,
      );

      if (result.isSuccess) {
        return StorageResult.success(result.url!, path: result.publicId);
      }
      return StorageResult.error(result.error ?? 'Upload échoué');
    } catch (e) {
      debugPrint('Erreur inattendue StorageService: $e');
      return StorageResult.error('Erreur: $e');
    }
  }

  // ___Supprimer une image____
  
  static Future<bool> supprimerImage(String imageUrlOuPublicId) async {
    try {
      // Si c'est une URL complète Cloudinary, on extrait le publicId
      String publicId = imageUrlOuPublicId;
      if (imageUrlOuPublicId.contains('cloudinary.com')) {
        publicId = _extrairePublicId(imageUrlOuPublicId);
      }
      return await CloudinaryService.supprimerImage(publicId);
    } catch (e) {
      debugPrint('Erreur suppression: $e');
      return false;
    }
  }

  // ___Obtenir une URL redimensionnée____
  
  static String getThumbnailUrl(String url,
      {int width = 300, int height = 300}) {
    return CloudinaryService.transformerUrl(url,
        width: width, height: height, crop: 'fill');
  }

  // ___Upload multiple____
  static Future<List<StorageResult>> uploadMultiple({
    required List<XFile> images,
    required String dossier,
    required Function(int index, double progress) onProgression,
    String? userId,
  }) async {
    final results = <StorageResult>[];
    for (var i = 0; i < images.length; i++) {
      final result = await uploadImageAvecProgression(
        image: images[i],
        dossier: dossier,
        onProgression: (p) => onProgression(i, p),
        userId: userId,
      );
      results.add(result);
    }
    return results;
  }

  // ── Utilitaire privé : extraire publicId depuis URL Cloudinary ─
  static String _extrairePublicId(String url) {
    // URL type: https://res.cloudinary.com/cloud/image/upload/v123/dossier/nom.jpg
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    // On cherche "upload" puis on saute la version (vXXX)
    final uploadIndex = segments.indexOf('upload');
    if (uploadIndex == -1 || uploadIndex + 1 >= segments.length) return url;
    final afterUpload = segments.sublist(uploadIndex + 1);
    // Supprimer le segment de version s'il commence par "v"
    final withoutVersion = afterUpload.first.startsWith('v') &&
            int.tryParse(afterUpload.first.substring(1)) != null
        ? afterUpload.sublist(1)
        : afterUpload;
    // Supprimer l'extension du dernier segment
    final last = withoutVersion.last;
    final withoutExt = last.contains('.') ? last.split('.').first : last;
    final pathParts = [...withoutVersion.sublist(0, withoutVersion.length - 1), withoutExt];
    return pathParts.join('/');
  }
}