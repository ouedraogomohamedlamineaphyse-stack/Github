class AppUser {
  final String uid;
  final String nom;
  final String prenom;
  final String username;
  final String email;
  final String pinHash;
  final String role;

  AppUser({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.username,
    required this.email,
    required this.pinHash,
    this.role = 'user',
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nom': nom,
    'prenom': prenom,
    'username': username,
    'email': email,
    'pinHash': pinHash,
    'role': role,
    'createdAt': DateTime.now().toIso8601String(),
    'favoris': [],
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] ?? '',
    nom: map['nom'] ?? '',
    prenom: map['prenom'] ?? '',
    username: map['username'] ?? '',
    email: map['email'] ?? '',
    pinHash: map['pinHash'] ?? '',
    role: map['role'] ?? 'user',
  );
}