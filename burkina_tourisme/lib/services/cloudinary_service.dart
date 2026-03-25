import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//___Résultat d'une opération Cloudinary__
class CloudinaryResult {
  final String? url;
  final String? publicId; // équivalent du "path" Firebase
  final String? error;
  final bool isSuccess;

  const CloudinaryResult._({
    this.url,
    this.publicId,
    this.error,
    required this.isSuccess,
  });

  factory CloudinaryResult.success(String url, String publicId) =>
      CloudinaryResult._(url: url, publicId: publicId, isSuccess: true);

  factory CloudinaryResult.error(String message) =>
      CloudinaryResult._(error: message, isSuccess: false);
}

class CloudinaryService {
  // ____Configuration____
  static const String _cloudName = 'dw03j35lq';        // ← ton vrai cloud name
  static const String _uploadPreset = 'Burkina_tourisme'; // ← ton preset name
  static const String _baseUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ____Upload bytes avec progression simulée_____
  static Future<CloudinaryResult> uploadBytes({
    required Uint8List bytes,
    required String dossier,
    required String nomFichier,
    required Function(double) onProgression,
    String? userId,
  }) async {
    try {
      onProgression(0.1);

      // Construction de la requête multipart
      final uri = Uri.parse(_baseUrl);
      final request = http.MultipartRequest('POST', uri);

      // Paramètres obligatoires
      request.fields['upload_preset'] = _uploadPreset;

      // Dossier Cloudinary (ex: "lieux/photos")
      request.fields['folder'] = dossier;

      // Métadonnées personnalisées
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '${dossier}/${userId ?? 'anon'}_$timestamp';
      request.fields['public_id'] = publicId;
      request.fields['context'] =
          'uploadedAt=${DateTime.now().toIso8601String()}|userId=${userId ?? 'anonymous'}';

      // Fichier image
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: nomFichier,
        ),
      );

      onProgression(0.3);

      // Envoi de la requête
      final streamedResponse = await request.send();

      onProgression(0.8);

      // Lecture de la réponse
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = String.fromCharCodes(responseBytes);
      final jsonData = json.decode(responseBody);

      if (streamedResponse.statusCode == 200) {
        final url = jsonData['secure_url'] as String;
        final pid = jsonData['public_id'] as String;
        onProgression(1.0);
        debugPrint('Cloudinary upload OK: $url');
        return CloudinaryResult.success(url, pid);
      } else {
        final errMsg = jsonData['error']?['message'] ?? 'Erreur inconnue';
        debugPrint('Cloudinary erreur ${streamedResponse.statusCode}: $errMsg');
        return CloudinaryResult.error('Cloudinary: $errMsg');
      }
    } catch (e) {
      debugPrint('Erreur CloudinaryService.uploadBytes: $e');
      return CloudinaryResult.error('Erreur réseau: $e');
    }
  }

  // ─── Supprimer une image via son publicId ──────────────────
  
  static Future<bool> supprimerImage(String publicId) async {
    // TODO: implémenter via Cloud Function ou backend si nécessaire
    debugPrint('Cloudinary: suppression demandée pour $publicId (non implémentée côté client)');
    return true;
  }

  // ____Construire une URL transformée (redimensionnement auto)___
  
  static String transformerUrl(
    String url, {
    int? width,
    int? height,
    String crop = 'fill',
    int quality = 80,
  }) {
    if (!url.contains('cloudinary.com')) return url;

    final transformations = <String>[
      if (width != null) 'w_$width',
      if (height != null) 'h_$height',
      if (width != null || height != null) 'c_$crop',
      'q_$quality',
      'f_auto', // format automatique (webp si supporté)
    ].join(',');

    // Insertion des transformations dans l'URL Cloudinary
    return url.replaceFirst('/upload/', '/upload/$transformations/');
  }
}