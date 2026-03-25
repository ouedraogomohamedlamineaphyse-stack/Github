import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/lieu.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart' as appAuth;
import '../providers/lieu_provider.dart';
import '../l10n/traductions.dart';
import 'detail_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => FavorisScreenState();
}

class FavorisScreenState extends State<FavorisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chargerFavoris();
    });
  }

  // ✅ Charge les favoris depuis Firestore
  void chargerFavoris() {
    final authProvider =
        context.read<appAuth.AppAuthProvider>();
    final lieuProvider = context.read<LieuProvider>();
    if (authProvider.appUser != null) {
      lieuProvider.chargerFavoris(authProvider.appUser!.uid);
    }
  }

  // ✅ Retirer favori via LieuProvider
  Future<void> _retirerFavori(Lieu lieu, String langue) async {
    final authProvider =
        context.read<appAuth.AppAuthProvider>();
    final lieuProvider = context.read<LieuProvider>();

    if (authProvider.appUser == null) return;

    await lieuProvider.toggleFavori(
      lieu.id,
      authProvider.appUser!.uid,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Traductions.t('retire_favori', langue)),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  Map<String, dynamic> _getCategorieStyle(String categorie) {
    switch (categorie) {
      case 'attraction':
        return {
          'color': AppTheme.vert,
          'label': 'Attraction',
          'icon': Icons.landscape
        };
      case 'restaurant':
        return {
          'color': AppTheme.rouge,
          'label': 'Restaurant',
          'icon': Icons.restaurant
        };
      case 'hebergement':
        return {
          'color': Colors.orange,
          'label': 'Hôtel',
          'icon': Icons.hotel
        };
      case 'culture':
        return {
          'color': const Color(0xFFE6A800),
          'label': 'Culture',
          'icon': Icons.event
        };
      default:
        return {
          'color': Colors.grey,
          'label': categorie,
          'icon': Icons.place
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final langue = provider.langue;
    // ✅ Favoris depuis LieuProvider en temps réel
    final favoris = context.watch<LieuProvider>().favoris;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Traductions.t('favoris', langue),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${favoris.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: favoris.isEmpty
          ? _buildEmpty(langue)
          : _buildListe(favoris, langue),
    );
  }

  Widget _buildEmpty(String langue) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.rouge.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 70,
              color: AppTheme.rouge.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            Traductions.t('aucun_favori', langue),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Traductions.t('ajouter_favori', langue),
            style:
                TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildListe(List<Lieu> favoris, String langue) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoris.length,
      itemBuilder: (context, index) {
        return _buildFavoriCard(favoris[index], langue);
      },
    );
  }

  Widget _buildFavoriCard(Lieu lieu, String langue) {
    final style = _getCategorieStyle(lieu.categorie);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DetailScreen(lieu: lieu)),
        );
        chargerFavoris();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                lieu.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                      Icons.image_not_supported, size: 50),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (style['color'] as Color)
                        .withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style['icon'] as IconData,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        style['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _retirerFavori(lieu, langue),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.red, size: 18),
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lieu.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          lieu.ville,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ...List.generate(5, (i) {
                          return Icon(
                            i < lieu.note.floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 12,
                            color: Colors.amber,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}