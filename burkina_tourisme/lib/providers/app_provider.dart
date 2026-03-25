import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppProvider extends ChangeNotifier {
  bool _isDark = false;
  String _langue = 'fr';
  String _photoCouverture = '';

  bool get isDark => _isDark;
  String get langue => _langue;
  String get photoCouverture => _photoCouverture;

  static const String _photoDefaut =
      'https://images.unsplash.com/photo-1504701954957-2010ec3bcec1?w=800';

  String get photoCouvertureEffective =>
      _photoCouverture.isNotEmpty ? _photoCouverture : _photoDefaut;

  AppProvider() {
    _chargerPreferences();
    _chargerPhotoCouverture();
  }

  Future<void> _chargerPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
    _langue = prefs.getString('langue') ?? 'fr';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  Future<void> setLangue(String langue) async {
    _langue = langue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('langue', langue);
    notifyListeners();
  }

  Future<void> _chargerPhotoCouverture() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get();
      if (doc.exists) {
        _photoCouverture = doc.data()?['photoCouverture'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur chargement photo couverture: $e');
    }
  }

  Future<bool> mettreAJourPhotoCouverture(String url) async {
    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .set({'photoCouverture': url}, SetOptions(merge: true));
      _photoCouverture = url;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur mise à jour photo couverture: $e');
      return false;
    }
  }

  Future<void> recharger() async {
    await _chargerPhotoCouverture();
  }
}