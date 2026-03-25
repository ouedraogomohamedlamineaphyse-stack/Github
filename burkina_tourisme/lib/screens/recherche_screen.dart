import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/lieu.dart';
import '../providers/lieu_provider.dart';
import 'detail_screen.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rechercher(String query) {
    setState(() => _query = query);
  }

  void _effacer() {
    _controller.clear();
    setState(() => _query = '');
  }

  List<Lieu> _filtrer(List<Lieu> lieux) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return lieux.where((l) =>
        l.nom.toLowerCase().contains(q) ||
        l.ville.toLowerCase().contains(q) ||
        l.categorie.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Données depuis Firestore via LieuProvider
    final tousLieux = context.watch<LieuProvider>().lieux;
    final resultats = _filtrer(tousLieux);
    final aRecherche = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recherche',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildContenu(aRecherche, resultats)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.rouge,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _controller,
        onChanged: _rechercher,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher un lieu, une ville...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon:
              const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.grey),
                  onPressed: _effacer,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildContenu(bool aRecherche, List<Lieu> resultats) {
    if (!aRecherche) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Recherchez un lieu ou une ville',
              style: TextStyle(
                  fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (resultats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                  fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resultats.length,
      itemBuilder: (context, index) {
        return _buildResultatCard(resultats[index]);
      },
    );
  }

  Widget _buildResultatCard(Lieu lieu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailScreen(lieu: lieu)),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            lieu.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(
          lieu.nom,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          lieu.ville,
          style:
              TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: _buildCategorieBadge(lieu.categorie),
      ),
    );
  }

  Widget _buildCategorieBadge(String categorie) {
    final Map<String, Map<String, dynamic>> styles = {
      'attraction': {
        'color': AppTheme.vert,
        'label': 'Attraction'
      },
      'restaurant': {
        'color': AppTheme.rouge,
        'label': 'Restaurant'
      },
      'hebergement': {
        'color': Colors.orange,
        'label': 'Hôtel'
      },
      'culture': {
        'color': const Color(0xFFE6A800),
        'label': 'Culture'
      },
    };

    final style = styles[categorie] ??
        {'color': Colors.grey, 'label': categorie};

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (style['color'] as Color).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: style['color'] as Color, width: 1),
      ),
      child: Text(
        style['label'] as String,
        style: TextStyle(
          color: style['color'] as Color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}