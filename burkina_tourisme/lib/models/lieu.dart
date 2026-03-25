class Lieu {
  final String id;
  final String nom;
  final String ville;
  final String categorie;
  final String description;
  final String adresse;
  final String contact;
  final double note;
  final String imageUrl;      // ← image principale (rétrocompatibilité)
  final List<String> images;  // ← galerie multi-images
  final String videoUrl;      // ← URL vidéo (YouTube, MP4, etc.)
  bool isFavori;

  Lieu({
    required this.id,
    required this.nom,
    required this.ville,
    required this.categorie,
    required this.description,
    required this.adresse,
    required this.contact,
    required this.note,
    required this.imageUrl,
    this.images = const [],
    this.videoUrl = '',
    this.isFavori = false,
  });

  // Toutes les images 
  List<String> get toutesLesImages {
    final liste = <String>[];
    if (imageUrl.isNotEmpty) liste.add(imageUrl);
    for (final img in images) {
      if (img.isNotEmpty && !liste.contains(img)) liste.add(img);
    }
    return liste;
  }

  bool get aVideo => videoUrl.isNotEmpty;
  bool get aGalerie => toutesLesImages.length > 1;

  //  Firestore → Lieu 
  factory Lieu.fromMap(Map<String, dynamic> map, String id) => Lieu(
        id: id,
        nom: map['nom'] ?? '',
        ville: map['ville'] ?? '',
        categorie: map['categorie'] ?? 'attraction',
        description: map['description'] ?? '',
        adresse: map['adresse'] ?? '',
        contact: map['contact'] ?? '',
        note: (map['note'] ?? 0.0).toDouble(),
        imageUrl: map['imageUrl'] ?? '',
        images: List<String>.from(map['images'] ?? []),
        videoUrl: map['videoUrl'] ?? '',
      );

  //  Lieu → Firestore 
  Map<String, dynamic> toMap() => {
        'nom': nom,
        'ville': ville,
        'categorie': categorie,
        'description': description,
        'adresse': adresse,
        'contact': contact,
        'note': note,
        'imageUrl': imageUrl,
        'images': images,
        'videoUrl': videoUrl,
      };
}