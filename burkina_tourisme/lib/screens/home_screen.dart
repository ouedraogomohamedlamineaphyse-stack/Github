import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/lieu_provider.dart';
import '../models/lieu.dart';
import '../l10n/traductions.dart';
import '../widgets/app_drawer.dart';
import 'detail_screen.dart';
import 'attractions_screen.dart';
import 'recherche_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final langue = provider.langue;
    final lieuProvider = context.watch<LieuProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          Traductions.t('accueil', langue),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                'https://flagcdn.com/w40/bf.png',
                width: 32,
                height: 22,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Text('🇧🇫', style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ],
      ),
      body: lieuProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(context, langue,
                      provider.photoCouvertureEffective),
                  const SizedBox(height: 20),
                  _buildCategories(context, langue),
                  const SizedBox(height: 20),
                  _buildSearchBar(context, langue),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                      Traductions.t('lieux_populaires', langue)),
                  const SizedBox(height: 10),
                  _buildPopularList(context, lieuProvider, langue),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ___Hero Banner avec photo dynamique____
  Widget _buildHeroBanner(
      BuildContext context, String langue, String photoUrl) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de couverture
          Image.network(
            photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[400],
              child: const Icon(Icons.image_not_supported,
                  size: 60, color: Colors.white),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Contenu texte
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        'https://flagcdn.com/w40/bf.png',
                        width: 36,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('🇧🇫',
                                style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Burkina Faso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  Traductions.t('decouvrez', langue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Traductions.t('slogan', langue),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ___Catégories____
  Widget _buildCategories(BuildContext context, String langue) {
    final categories = [
      {
        'label': Traductions.t('attractions', langue),
        'icon': Icons.landscape,
        'color': AppTheme.vert,
        'cat': 'attraction',
      },
      {
        'label': Traductions.t('restaurants', langue),
        'icon': Icons.restaurant,
        'color': AppTheme.rouge,
        'cat': 'restaurant',
      },
      {
        'label': Traductions.t('hebergements', langue),
        'icon': Icons.hotel,
        'color': AppTheme.rouge,
        'cat': 'hebergement',
      },
      {
        'label': Traductions.t('culture', langue),
        'icon': Icons.event,
        'color': const Color(0xFFE6A800),
        'cat': 'culture',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttractionsScreen(
                    categorie: cat['cat'] as String,
                    titre: cat['label'] as String,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: cat['color'] as Color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      cat['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ___Barre de recherche____
  Widget _buildSearchBar(BuildContext context, String langue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const RechercheScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[400]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  Traductions.t('rechercher', langue),
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 15),
                ),
              ),
              Icon(Icons.mic, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ___Titre de section____
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.rouge,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ___Liste populaire___
  Widget _buildPopularList(BuildContext context,
      LieuProvider lieuProvider, String langue) {
    final populaires = lieuProvider.lieux.take(4).toList();

    if (populaires.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aucun lieu disponible',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: populaires.length,
      itemBuilder: (context, index) {
        return _buildLieuCard(context, populaires[index], langue);
      },
    );
  }

  // ___Card lieu___
  Widget _buildLieuCard(
      BuildContext context, Lieu lieu, String langue) {
    final Map<String, Map<String, dynamic>> styles = {
      'attraction': {
        'color': AppTheme.vert,
        'label': Traductions.t('attractions', langue),
      },
      'restaurant': {
        'color': AppTheme.rouge,
        'label': Traductions.t('restaurants', langue),
      },
      'hebergement': {
        'color': Colors.orange,
        'label': Traductions.t('hebergements', langue),
      },
      'culture': {
        'color': const Color(0xFFE6A800),
        'label': Traductions.t('culture', langue),
      },
    };
    final style = styles[lieu.categorie] ??
        {'color': Colors.grey, 'label': lieu.categorie};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailScreen(lieu: lieu)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  lieu.imageUrl,
                  width: 75,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                    width: 75,
                    height: 75,
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lieu.nom,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          lieu.ville,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < lieu.note.floor()
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (style['color'] as Color)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (style['color'] as Color)
                          .withOpacity(0.4)),
                ),
                child: Text(
                  style['label'] as String,
                  style: TextStyle(
                    color: style['color'] as Color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}