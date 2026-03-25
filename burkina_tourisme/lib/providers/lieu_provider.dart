// lib/providers/lieu_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lieu.dart';
import '../services/firestore_service.dart';
import '../data/data_source.dart';

class LieuProvider extends ChangeNotifier {
  List<Lieu> _lieux = [];
  bool _isLoading = false;
  bool _migrationFaite = false;
  String? _error;

  List<Lieu> get lieux => _lieux;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtres par catégorie
  List<Lieu> parCategorie(String categorie) =>
      _lieux.where((l) => l.categorie == categorie).toList();

  List<Lieu> get attractions =>
      _lieux.where((l) => l.categorie == 'attraction').toList();
  List<Lieu> get restaurants =>
      _lieux.where((l) => l.categorie == 'restaurant').toList();
  List<Lieu> get hebergements =>
      _lieux.where((l) => l.categorie == 'hebergement').toList();
  List<Lieu> get culture =>
      _lieux.where((l) => l.categorie == 'culture').toList();
  List<Lieu> get favoris =>
      _lieux.where((l) => l.isFavori).toList();

  // Écouter Firestore en temps réel
  void ecouterLieux() {
    _isLoading = true;
    notifyListeners();

    FirestoreService.lieuxStream().listen(
      (lieux) async {
        if (lieux.isEmpty && !_migrationFaite) {
          await FirestoreService.migrerDonneesLocales(DataSource.lieux);
          _migrationFaite = true;
        } else {
          _lieux = lieux;
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (e) {
        _error = 'Erreur chargement : $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Charger les favoris depuis Firestore
  Future<void> chargerFavoris(String userUid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .get();

      if (doc.exists) {
        final List<dynamic> favorisIds =
            doc.data()?['favoris'] ?? [];
        for (final lieu in _lieux) {
          lieu.isFavori = favorisIds.contains(lieu.id);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur chargement favoris : $e';
    }
  }

  // Toggle favori avec Firestore
  Future<void> toggleFavori(String lieuId, String userUid) async {
    final index = _lieux.indexWhere((l) => l.id == lieuId);
    if (index == -1) return;

    _lieux[index].isFavori = !_lieux[index].isFavori;
    notifyListeners();

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userUid);

    try {
      if (_lieux[index].isFavori) {
        await userRef.update({
          'favoris': FieldValue.arrayUnion([lieuId])
        });
      } else {
        await userRef.update({
          'favoris': FieldValue.arrayRemove([lieuId])
        });
      }
    } catch (e) {
      // Annuler si erreur
      _lieux[index].isFavori = !_lieux[index].isFavori;
      notifyListeners();
    }
  }
}
