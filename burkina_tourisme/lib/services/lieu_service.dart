import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/lieu.dart';
import 'storage_service.dart';

class LieuService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'lieux';

  // ___Récupérer tous les lieux____
  static Future<List<Lieu>> getLieux() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('nom')
          .get();
      return snapshot.docs
          .map((doc) => Lieu.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Erreur getLieux: $e');
      return [];
    }
  }

  // ___Récupérer les lieux en temps réel (stream)___
  static Stream<List<Lieu>> getLieuxStream() {
    return _firestore
        .collection(_collection)
        .orderBy('nom')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Lieu.fromMap(doc.data(), doc.id))
            .toList());
  }

  //___Récupérer un lieu par ID____
  static Future<Lieu?> getLieuById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Lieu.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Erreur getLieuById: $e');
      return null;
    }
  }

  // ___Récupérer par catégorie____
  static Future<List<Lieu>> getLieuxParCategorie(String categorie) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('categorie', isEqualTo: categorie)
          .get();
      return snapshot.docs
          .map((doc) => Lieu.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Erreur getLieuxParCategorie: $e');
      return [];
    }
  }

  // ____Ajouter un lieu avec image___
  static Future<String?> ajouterLieu({
    required Lieu lieu,
    XFile? imageFile,
    Function(double)? onProgression,
    String? userId,
  }) async {
    try {
      String? imageUrl = lieu.imageUrl;
      String? imagePublicId;

      // Upload de l'image si fournie
      if (imageFile != null) {
        final storageResult = await StorageService.uploadImageAvecProgression(
          image: imageFile,
          dossier: 'lieux/photos',
          onProgression: onProgression ?? (_) {},
          userId: userId,
        );

        if (!storageResult.isSuccess) {
          debugPrint('Avertissement upload image: ${storageResult.error}');
          // On continue quand même l'ajout du lieu sans image
        } else {
          imageUrl = storageResult.url;
          imagePublicId = storageResult.path; // publicId Cloudinary
        }
      }

      // Création du document Firestore
      final data = lieu.toMap()
        ..addAll({
          'imageUrl': imageUrl ?? '',
          'imagePublicId': imagePublicId ?? '', // pour suppression future
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

      final docRef = await _firestore.collection(_collection).add(data);
      debugPrint('Lieu ajouté avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Erreur ajouterLieu: $e');
      return null;
    }
  }

  // ___Mettre à jour un lieu___
  static Future<bool> mettreAJourLieu({
    required String lieuId,
    required Map<String, dynamic> donnees,
    XFile? nouvelleImage,
    Function(double)? onProgression,
    String? ancienPublicId, // pour remplacer l'ancienne image
    String? userId,
  }) async {
    try {
      // Si nouvelle image fournie → upload et suppression de l'ancienne
      if (nouvelleImage != null) {
        final storageResult = await StorageService.uploadImageAvecProgression(
          image: nouvelleImage,
          dossier: 'lieux/photos',
          onProgression: onProgression ?? (_) {},
          userId: userId,
        );

        if (storageResult.isSuccess) {
          donnees['imageUrl'] = storageResult.url;
          donnees['imagePublicId'] = storageResult.path ?? '';

          // Supprimer l'ancienne image si elle existe
          if (ancienPublicId != null && ancienPublicId.isNotEmpty) {
            await StorageService.supprimerImage(ancienPublicId);
          }
        }
      }

      donnees['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_collection)
          .doc(lieuId)
          .update(donnees);
      return true;
    } catch (e) {
      debugPrint('Erreur mettreAJourLieu: $e');
      return false;
    }
  }

  // ___Supprimer un lieu___
  static Future<bool> supprimerLieu(String lieuId) async {
    try {
      // Récupérer le publicId avant suppression
      final doc =
          await _firestore.collection(_collection).doc(lieuId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final publicId = data['imagePublicId'] as String? ?? '';
        if (publicId.isNotEmpty) {
          await StorageService.supprimerImage(publicId);
        }
      }

      await _firestore.collection(_collection).doc(lieuId).delete();
      return true;
    } catch (e) {
      debugPrint('Erreur supprimerLieu: $e');
      return false;
    }
  }

  // ___Recherche par nom___
  static Future<List<Lieu>> rechercherLieux(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => Lieu.fromMap(doc.data(), doc.id))
          .where((lieu) =>
              lieu.nom.toLowerCase().contains(queryLower) ||
              (lieu.description?.toLowerCase().contains(queryLower) ?? false))
          .toList();
    } catch (e) {
      debugPrint('Erreur rechercherLieux: $e');
      return [];
    }
  }

  // ___Obtenir thumbnail optimisé d'un lieu____
  // Utilise la transformation Cloudinary pour les listes
  static String getThumbnail(String imageUrl,
      {int width = 300, int height = 200}) {
    return StorageService.getThumbnailUrl(imageUrl,
        width: width, height: height);
  }
}