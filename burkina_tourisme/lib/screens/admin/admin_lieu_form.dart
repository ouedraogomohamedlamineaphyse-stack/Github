// lib/screens/admin/admin_lieu_form.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../models/lieu.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class AdminLieuForm extends StatefulWidget {
  final Lieu? lieu;
  const AdminLieuForm({super.key, this.lieu});

  @override
  State<AdminLieuForm> createState() => _AdminLieuFormState();
}

class _AdminLieuFormState extends State<AdminLieuForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();

  String _categorie = 'attraction';
  bool _isLoading = false;
  double _progression = 0.0;
  String _etapeMessage = '';

  List<String> _imagesExistantes = [];
  final List<_ImageLocale> _nouvellesImages = [];

  bool get _estEdition => widget.lieu != null;
  bool get _aAuMoinsUneImage =>
      _imagesExistantes.isNotEmpty || _nouvellesImages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_estEdition) {
      final l = widget.lieu!;
      _nomCtrl.text = l.nom;
      _villeCtrl.text = l.ville;
      _descCtrl.text = l.description;
      _adresseCtrl.text = l.adresse;
      _contactCtrl.text = l.contact;
      _noteCtrl.text = l.note.toString();
      _videoCtrl.text = l.videoUrl;
      _categorie = l.categorie;
      _imagesExistantes = List<String>.from(l.toutesLesImages);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _villeCtrl.dispose();
    _descCtrl.dispose();
    _adresseCtrl.dispose();
    _contactCtrl.dispose();
    _noteCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _ajouterImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    for (final image in images) {
      final bytes = await image.readAsBytes();
      setState(() {
        _nouvellesImages.add(_ImageLocale(fichier: image, bytes: bytes));
      });
    }
  }

  void _supprimerImageExistante(int index) {
    setState(() => _imagesExistantes.removeAt(index));
  }

  void _supprimerNouvelleImage(int index) {
    setState(() => _nouvellesImages.removeAt(index));
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aAuMoinsUneImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _progression = 0.0;
      _etapeMessage = 'Préparation...';
    });

    try {
      final List<String> urlsNouvellesImages = [];
      final total = _nouvellesImages.length;

      for (var i = 0; i < total; i++) {
        setState(() {
          _etapeMessage = 'Upload photo ${i + 1}/$total...';
        });

        final result = await StorageService.uploadImageAvecProgression(
          image: _nouvellesImages[i].fichier,
          dossier: 'burkina_tourisme/lieux/photos',
          onProgression: (p) {
            if (mounted) {
              final base = i / (total == 0 ? 1 : total);
              final step = p / (total == 0 ? 1 : total);
              setState(() =>
                  _progression = (base + step).clamp(0.0, 0.95));
            }
          },
        );

        if (result.isSuccess && result.url != null) {
          urlsNouvellesImages.add(result.url!);
        } else {
          throw Exception('Échec upload photo ${i + 1}: ${result.error}');
        }
      }

      final toutesLesUrls = [
        ..._imagesExistantes,
        ...urlsNouvellesImages,
      ];

      setState(() {
        _progression = 0.97;
        _etapeMessage = 'Enregistrement...';
      });

      final lieu = Lieu(
        id: widget.lieu?.id ?? '',
        nom: _nomCtrl.text.trim(),
        ville: _villeCtrl.text.trim(),
        categorie: _categorie,
        description: _descCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
        contact: _contactCtrl.text.trim(),
        note: double.tryParse(_noteCtrl.text) ?? 0.0,
        imageUrl: toutesLesUrls.isNotEmpty ? toutesLesUrls.first : '',
        images: toutesLesUrls.length > 1 ? toutesLesUrls.sublist(1) : [],
        videoUrl: _videoCtrl.text.trim(),
      );

      if (_estEdition) {
        await FirestoreService.modifierLieu(lieu);
      } else {
        await FirestoreService.ajouterLieu(lieu);
      }

      setState(() => _progression = 1.0);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _estEdition ? '✅ Lieu modifié !' : '✅ Lieu ajouté !'),
          backgroundColor: AppTheme.vert,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _progression = 0.0;
          _etapeMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Couleurs adaptatives mode clair/sombre ───────────
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.grey.withOpacity(0.3);
    final fillColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.withOpacity(0.04);
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final infoBoxColor = isDark
        ? Colors.blue.withOpacity(0.12)
        : Colors.blue.withOpacity(0.07);
    final infoBoxBorder = isDark
        ? Colors.blue.withOpacity(0.3)
        : Colors.blue.withOpacity(0.2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.rouge,
        title: Text(
          _estEdition ? 'Modifier le lieu' : 'Ajouter un lieu',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section Photos ───────────────────
                  _sectionTitre('Photos', Icons.photo_library),
                  const SizedBox(height: 10),
                  _buildGalerieAdmin(),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _ajouterImages,
                      icon: const Icon(Icons.add_photo_alternate,
                          color: AppTheme.rouge),
                      label: const Text('Ajouter des photos',
                          style: TextStyle(color: AppTheme.rouge)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.rouge),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section Vidéo ────────────────────
                  _sectionTitre('Vidéo (optionnel)', Icons.videocam),
                  const SizedBox(height: 10),
                  _champ(
                    _videoCtrl,
                    'URL YouTube ou lien vidéo',
                    Icons.link,
                    keyboardType: TextInputType.url,
                    borderColor: borderColor,
                    fillColor: fillColor,
                    labelColor: labelColor!,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: infoBoxColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: infoBoxBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ex: https://youtube.com/watch?v=xxx',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.blue[300]
                                    : Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Catégorie ────────────────────────
                  _sectionTitre('Catégorie', Icons.category),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _categorieChip('attraction', 'Attraction',
                          Icons.landscape),
                      _categorieChip('restaurant', 'Restaurant',
                          Icons.restaurant),
                      _categorieChip('hebergement', 'Hébergement',
                          Icons.hotel),
                      _categorieChip(
                          'culture', 'Culture', Icons.museum),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Informations ─────────────────────
                  _sectionTitre('Informations', Icons.info_outline),
                  const SizedBox(height: 12),
                  _champ(_nomCtrl, 'Nom du lieu', Icons.place,
                      borderColor: borderColor,
                      fillColor: fillColor,
                      labelColor: labelColor,
                      validator: (v) =>
                          v!.isEmpty ? 'Nom requis' : null),
                  const SizedBox(height: 14),
                  _champ(_villeCtrl, 'Ville', Icons.location_city,
                      borderColor: borderColor,
                      fillColor: fillColor,
                      labelColor: labelColor,
                      validator: (v) =>
                          v!.isEmpty ? 'Ville requise' : null),
                  const SizedBox(height: 14),
                  _champ(_adresseCtrl, 'Adresse', Icons.map_outlined,
                      borderColor: borderColor,
                      fillColor: fillColor,
                      labelColor: labelColor),
                  const SizedBox(height: 14),
                  _champ(_contactCtrl, 'Contact / Téléphone',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                      borderColor: borderColor,
                      fillColor: fillColor,
                      labelColor: labelColor),
                  const SizedBox(height: 14),
                  _champ(
                    _noteCtrl,
                    'Note (0.0 - 5.0)',
                    Icons.star_outline,
                    keyboardType: TextInputType.number,
                    borderColor: borderColor,
                    fillColor: fillColor,
                    labelColor: labelColor,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 5) {
                        return 'Note entre 0 et 5';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // Description (multiline)
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: labelColor),
                      prefixIcon: const Icon(
                          Icons.description_outlined,
                          color: AppTheme.rouge),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppTheme.rouge, width: 2)),
                      filled: true,
                      fillColor: fillColor,
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Description requise' : null,
                  ),
                  const SizedBox(height: 28),

                  // ── Bouton sauvegarder ───────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.rouge,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _estEdition ? 'Modifier' : 'Ajouter',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Overlay progression ──────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_upload,
                          size: 48, color: AppTheme.rouge),
                      const SizedBox(height: 16),
                      Text(
                        _etapeMessage,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progression,
                          minHeight: 10,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[200],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  AppTheme.rouge),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_progression * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.rouge),
                      ),
                      const SizedBox(height: 8),
                      Text('Veuillez patienter...',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Galerie admin ────────────────────────────────────────
  Widget _buildGalerieAdmin() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total =
        _imagesExistantes.length + _nouvellesImages.length;

    if (total == 0) {
      return GestureDetector(
        onTap: _isLoading ? null : _ajouterImages,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 52,
                  color: isDark ? Colors.grey[500] : Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Appuyer pour ajouter des photos',
                  style: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text('Plusieurs photos acceptées',
                  style: TextStyle(
                      color: isDark
                          ? Colors.grey[600]
                          : Colors.grey[400],
                      fontSize: 11)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._imagesExistantes.asMap().entries.map((e) =>
              _vignetteExistante(e.value, e.key)),
          ..._nouvellesImages.asMap().entries.map((e) =>
              _vignetteLocale(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _vignetteExistante(String url, int index) {
    final isPrincipal = index == 0;
    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isPrincipal
                ? Border.all(color: AppTheme.rouge, width: 2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[700],
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey))),
          ),
        ),
        if (isPrincipal)
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AppTheme.rouge,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('Principal',
                  style: TextStyle(color: Colors.white, fontSize: 9)),
            ),
          ),
        Positioned(
          top: 4, right: 14,
          child: GestureDetector(
            onTap: () => _supprimerImageExistante(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vignetteLocale(_ImageLocale img, int index) {
    final isPrincipal = _imagesExistantes.isEmpty && index == 0;
    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPrincipal
                  ? AppTheme.rouge
                  : Colors.green.withOpacity(0.6),
              width: isPrincipal ? 2 : 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(img.bytes, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          bottom: 4, left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPrincipal ? AppTheme.rouge : Colors.green,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(isPrincipal ? 'Principal' : 'Nouveau',
                style: const TextStyle(
                    color: Colors.white, fontSize: 9)),
          ),
        ),
        Positioned(
          top: 4, right: 14,
          child: GestureDetector(
            onTap: () => _supprimerNouvelleImage(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets utilitaires ──────────────────────────────────
  Widget _sectionTitre(String titre, IconData icon) => Row(
        children: [
          Icon(icon, color: AppTheme.rouge, size: 20),
          const SizedBox(width: 8),
          Text(titre,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );

  Widget _champ(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required Color borderColor,
    required Color fillColor,
    Color? labelColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: labelColor ??
                (isDark ? Colors.grey[400] : Colors.grey[600])),
        prefixIcon: Icon(icon, color: AppTheme.rouge),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.rouge, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.red, width: 1)),
        filled: true,
        fillColor: fillColor,
      ),
    );
  }

  Widget _categorieChip(
      String valeur, String label, IconData icon) {
    final isSelected = _categorie == valeur;
    final couleur = {
          'attraction': AppTheme.vert,
          'restaurant': Colors.orange,
          'hebergement': Colors.blue,
          'culture': Colors.purple,
        }[valeur] ??
        Colors.grey;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? Colors.white : couleur),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.white : couleur,
                  fontWeight: FontWeight.w600)),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _categorie = valeur),
      selectedColor: couleur,
      backgroundColor: couleur.withOpacity(0.1),
      side: BorderSide(color: couleur.withOpacity(0.3)),
    );
  }
}

// ── Classe utilitaire pour images locales ────────────────
class _ImageLocale {
  final XFile fichier;
  final Uint8List bytes;
  _ImageLocale({required this.fichier, required this.bytes});
}