import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _appUser;
  String? _errorMessage;
  bool _isLoading = false;

  AppUser? get appUser => _appUser;
  bool get isLoggedIn => _appUser != null;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String get userName => _appUser != null
      ? '${_appUser!.prenom} ${_appUser!.nom}'
      : 'Voyageur Burkinabè';
  String get userEmail => _appUser?.email ?? '';

  // ─ Hash du PIN ─
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  //  Vérifier si username existe ─
  Future<bool> _usernameExiste(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // Inscriptions 
  Future<bool> inscrire({
    required String nom,
    required String prenom,
    required String username,
    required String email,
    required String pin,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (await _usernameExiste(username)) {
        _setLoading(false);
        _setError("Ce nom d'utilisateur est déjà pris");
        return false;
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: _hashPin(pin).substring(0, 20),
      );

      await credential.user?.updateDisplayName('$prenom $nom');

      final appUser = AppUser(
        uid: credential.user!.uid,
        nom: nom,
        prenom: prenom,
        username: username,
        email: email,
        pinHash: _hashPin(pin),
        role: 'user',
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(appUser.toMap());

      _appUser = appUser;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e.code));
      return false;
    }
  }

  // Connexion étape 1 — chercher username 
  Future<AppUser?> chercherUtilisateur(String username) async {
    try {
      _setLoading(true);
      _setError(null);

      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      _setLoading(false);

      if (query.docs.isEmpty) {
        _setError("Nom d'utilisateur introuvable");
        return null;
      }

      final doc = query.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['uid'] = doc.id;
      return AppUser.fromMap(data);
    } catch (e) {
      _setLoading(false);
      _setError('Erreur réseau. Vérifiez votre connexion');
      return null;
    }
  }

  //  Connexion étape 2 — vérifier PIN 
  Future<bool> verifierPin({
    required AppUser utilisateur,
    required String pin,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_hashPin(pin) != utilisateur.pinHash) {
        _setLoading(false);
        _setError('Code PIN incorrect');
        return false;
      }

      await _auth.signInWithEmailAndPassword(
        email: utilisateur.email,
        password: utilisateur.pinHash.substring(0, 20),
      );

      _appUser = utilisateur;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e.code));
      return false;
    }
  }

  //  Récupérer username par email 
  Future<RecupUsernameResult> recupererUsername(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      _setLoading(false);

      if (query.docs.isEmpty) {
        return RecupUsernameResult.introuvable;
      }

      final data = query.docs.first.data();
      final username = data['username'] as String? ?? '';
      return RecupUsernameResult.succes(username);
    } catch (e) {
      _setLoading(false);
      _setError('Erreur réseau');
      return RecupUsernameResult.erreur;
    }
  }

  // Vérifier si email existe 
  Future<VerifEmailResult> verifierEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      _setLoading(false);

      if (query.docs.isEmpty) {
        _setError('Aucun compte associé à cet email');
        return VerifEmailResult.introuvable;
      }

      final doc = query.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['uid'] = doc.id;
      return VerifEmailResult.trouve(AppUser.fromMap(data));
    } catch (e) {
      _setLoading(false);
      _setError('Erreur réseau. Vérifiez votre connexion');
      return VerifEmailResult.erreur;
    }
  }

  //  Définir un nouveau PIN
  Future<bool> definirNouveauPin({
    required String uid,
    required String email,
    required String ancienPinHash,
    required String nouveauPin,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final newPinHash = _hashPin(nouveauPin);

      // Mettre à jour Firestore
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'pinHash': newPinHash});

      // Mettre à jour Firebase Auth
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: ancienPinHash.substring(0, 20),
        );
        await _auth.currentUser
            ?.updatePassword(newPinHash.substring(0, 20));
        await _auth.signOut();
      } catch (authError) {
        // Firestore est mis à jour — l'utilisateur peut se connecter
        debugPrint('Auth update optionnel échoué: $authError');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la mise à jour : $e');
      return false;
    }
  }

  // Déconnexion 
  Future<void> deconnecter() async {
    try {
      await _auth.signOut();
    } finally {
      _appUser = null;
      notifyListeners();
    }
  }

  //  Messages d'erreur Firebase 
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé pour cet email';
      case 'wrong-password':
        return 'Code PIN incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Code trop faible';
      case 'invalid-email':
        return 'Email invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion';
      default:
        return 'Une erreur est survenue. Réessayez';
    }
  }
}

//  Résultat récupération username 
class RecupUsernameResult {
  final bool succes_;
  final String? username;
  final bool introuvable_;
  final bool erreur_;

  const RecupUsernameResult._({
    this.succes_ = false,
    this.username,
    this.introuvable_ = false,
    this.erreur_ = false,
  });

  static RecupUsernameResult succes(String username) =>
      RecupUsernameResult._(succes_: true, username: username);
  static const RecupUsernameResult introuvable =
      RecupUsernameResult._(introuvable_: true);
  static const RecupUsernameResult erreur =
      RecupUsernameResult._(erreur_: true);

  bool get estSucces => succes_;
  bool get estIntrouvable => introuvable_;
  bool get estErreur => erreur_;
}

//  Résultat vérification email 
class VerifEmailResult {
  final bool trouve_;
  final AppUser? utilisateur;
  final bool introuvable_;
  final bool erreur_;

  const VerifEmailResult._({
    this.trouve_ = false,
    this.utilisateur,
    this.introuvable_ = false,
    this.erreur_ = false,
  });

  static VerifEmailResult trouve(AppUser user) =>
      VerifEmailResult._(trouve_: true, utilisateur: user);
  static const VerifEmailResult introuvable =
      VerifEmailResult._(introuvable_: true);
  static const VerifEmailResult erreur =
      VerifEmailResult._(erreur_: true);

  bool get estTrouve => trouve_;
  bool get estIntrouvable => introuvable_;
  bool get estErreur => erreur_;
}