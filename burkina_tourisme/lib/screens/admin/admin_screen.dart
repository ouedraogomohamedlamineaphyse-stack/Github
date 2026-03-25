// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/lieu_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/lieu.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'admin_lieu_form.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lieux = context.watch<LieuProvider>().lieux;
    final isLoading = context.watch<LieuProvider>().isLoading;

    final categories = [
      {'key': 'attraction', 'label': 'Attractions', 'icon': Icons.landscape, 'color': AppTheme.vert},
      {'key': 'restaurant', 'label': 'Restaurants', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'key': 'hebergement', 'label': 'Hébergements', 'icon': Icons.hotel, 'color': Colors.blue},
      {'key': 'culture', 'label': 'Culture', 'icon': Icons.museum, 'color': Colors.purple},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.rouge,
        title: const Text('Panel Admin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminLieuForm())),
        backgroundColor: AppTheme.rouge,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),

                // ── Photo de couverture ──────────────
                const _SectionPhotoCouverture(),
                const SizedBox(height: 24),

                // ── Stats ────────────────────────────
                Text('Vue d\'ensemble',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: categories.map((cat) {
                    final count = lieux.where((l) => l.categorie == cat['key']).length;
                    return Container(
                      decoration: BoxDecoration(
                        color: (cat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (cat['color'] as Color).withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 28),
                          const SizedBox(height: 8),
                          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cat['color'] as Color)),
                          Text(cat['label'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Liste lieux ──────────────────────
                Text('Tous les lieux (${lieux.length})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 12),
                ...lieux.map((lieu) => _buildLieuTile(context, lieu)),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildLieuTile(BuildContext context, Lieu lieu) {
    final couleurCategorie = {
      'attraction': AppTheme.vert,
      'restaurant': Colors.orange,
      'hebergement': Colors.blue,
      'culture': Colors.purple,
    }[lieu.categorie] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            lieu.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 56, height: 56, color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        ),
        title: Text(lieu.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lieu.ville, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: couleurCategorie.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(lieu.categorie,
                      style: TextStyle(color: couleurCategorie, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                if (lieu.toutesLesImages.length > 1) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.photo_library, size: 10, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text('${lieu.toutesLesImages.length}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  ),
                ],
                if (lieu.aVideo) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.videocam, size: 10, color: Colors.red),
                      SizedBox(width: 3),
                      Text('vidéo', style: TextStyle(fontSize: 10, color: Colors.red)),
                    ]),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AdminLieuForm(lieu: lieu))),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmerSuppression(context, lieu),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, Lieu lieu) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous supprimer "${lieu.nom}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirestoreService.supprimerLieu(lieu.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Lieu supprimé !'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Widget section photo de couverture ────────────────────
class _SectionPhotoCouverture extends StatefulWidget {
  const _SectionPhotoCouverture();

  @override
  State<_SectionPhotoCouverture> createState() => _SectionPhotoCouvertureState();
}

class _SectionPhotoCouvertureState extends State<_SectionPhotoCouverture> {
  bool _isUploading = false;
  double _progression = 0.0;

  Future<void> _changerPhoto() async {
    final image = await StorageService.choisirImage();
    if (image == null) return;

    setState(() { _isUploading = true; _progression = 0.0; });

    final result = await StorageService.uploadImageAvecProgression(
      image: image,
      dossier: 'burkina_tourisme/config',
      onProgression: (p) { if (mounted) setState(() => _progression = p); },
    );

    if (result.isSuccess && result.url != null && mounted) {
      final success = await context.read<AppProvider>().mettreAJourPhotoCouverture(result.url!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? '✅ Photo de couverture mise à jour !' : '❌ Erreur lors de la mise à jour'),
        backgroundColor: success ? AppTheme.vert : Colors.red,
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Erreur upload: ${result.error}'),
        backgroundColor: Colors.red,
      ));
    }

    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = context.watch<AppProvider>().photoCouvertureEffective;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.rouge.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.rouge.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wallpaper, color: AppTheme.rouge, size: 20),
              SizedBox(width: 8),
              Text('Photo de couverture (Accueil)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),

          // Aperçu
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  photoUrl, width: double.infinity, height: 140, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140, color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
                  ),
                ),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 8, left: 10,
                  child: Text('Photo actuelle', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _progression,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.rouge),
            ),
            const SizedBox(height: 6),
            Text('${(_progression * 100).toInt()}% — Upload en cours...',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 8),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _changerPhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rouge,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
              label: Text(
                _isUploading ? 'Upload en cours...' : 'Changer la photo de couverture',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}