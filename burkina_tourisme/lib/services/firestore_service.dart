import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lieu.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'lieux';

  static Stream<List<Lieu>> lieuxStream() {
    return _db
        .collection(_collection)
        .orderBy('nom')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Lieu.fromMap(doc.data(), doc.id))
            .toList());
  }

  static Future<String> ajouterLieu(Lieu lieu) async {
    final doc = await _db.collection(_collection).add(lieu.toMap());
    return doc.id;
  }

  static Future<void> modifierLieu(Lieu lieu) async {
    await _db
        .collection(_collection)
        .doc(lieu.id)
        .update(lieu.toMap());
  }

  static Future<void> supprimerLieu(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  static Future<void> migrerDonneesLocales(List<Lieu> lieux) async {
    final batch = _db.batch();
    for (final lieu in lieux) {
      final ref = _db.collection(_collection).doc();
      batch.set(ref, lieu.toMap());
    }
    await batch.commit();
  }
}