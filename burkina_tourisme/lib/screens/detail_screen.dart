import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lieu.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart' as appAuth;
import '../providers/lieu_provider.dart';
import '../l10n/traductions.dart';

class DetailScreen extends StatefulWidget {
  final Lieu lieu;
  const DetailScreen({super.key, required this.lieu});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late bool isFavori;
  int _indexImageActuel = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    isFavori = widget.lieu.isFavori;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ___Toggle favori___
  Future<void> _toggleFavori(String langue) async {
    final authProvider = context.read<appAuth.AppAuthProvider>();
    final lieuProvider = context.read<LieuProvider>();
    if (authProvider.appUser == null) return;

    await lieuProvider.toggleFavori(
        widget.lieu.id, authProvider.appUser!.uid);
    setState(() => isFavori = !isFavori);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isFavori
            ? Traductions.t('ajoute_favori', langue)
            : Traductions.t('retire_favori', langue)),
        duration: const Duration(seconds: 1),
        backgroundColor: isFavori ? AppTheme.vert : Colors.grey,
      ));
    }
  }

  Future<void> _appeler() async {
    final uri = Uri.parse('tel:${widget.lieu.contact}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible d\'ouvrir le téléphone')),
        );
      }
    }
  }

  Future<void> _voirSurCarte() async {
    final adresseEncodee = Uri.encodeComponent(widget.lieu.adresse);
    final nomEncode = Uri.encodeComponent(widget.lieu.nom);
    final uriGoogleMaps = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$nomEncode+$adresseEncodee');
    final uriGeo =
        Uri.parse('geo:0,0?q=$adresseEncodee(${widget.lieu.nom})');

    try {
      if (await canLaunchUrl(uriGeo)) {
        await launchUrl(uriGeo, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriGoogleMaps)) {
        await launchUrl(uriGoogleMaps,
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  // ___Ouvrir la vidéo (YouTube ou lien direct)___
  Future<void> _ouvrirVideo() async {
    final videoUrl = widget.lieu.videoUrl;
    if (videoUrl.isEmpty) return;

    // Conversion YouTube watch → youtu.be pour compatibilité mobile
    String urlFinale = videoUrl;
    if (videoUrl.contains('youtube.com/watch?v=')) {
      final videoId =
          Uri.parse(videoUrl).queryParameters['v'] ?? '';
      urlFinale = 'https://www.youtube.com/watch?v=$videoId';
    }

    final uri = Uri.parse(urlFinale);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible d\'ouvrir la vidéo')),
        );
      }
    }
  }

  // ___Afficher une image en plein écran___
  void _ouvrirGalerieFullscreen(int indexInitial) {
    final images = widget.lieu.toutesLesImages;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GalerieFullscreen(
          images: images,
          indexInitial: indexInitial,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final langue = provider.langue;
    final images = widget.lieu.toutesLesImages;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, langue, images),
          SliverToBoxAdapter(
            child: _buildBody(context, langue),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(langue),
    );
  }

  //___AppBar avec galerie____
  Widget _buildAppBar(
      BuildContext context, String langue, List<String> images) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.rouge,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(Traductions.t('detail', langue),
          style: const TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(
            isFavori ? Icons.favorite : Icons.favorite_border,
            color: isFavori ? Colors.red[300] : Colors.white,
          ),
          onPressed: () => _toggleFavori(langue),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            //___PageView des images___
            images.isEmpty
                ? Container(color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported,
                        size: 60))
                : PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _indexImageActuel = i),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _ouvrirGalerieFullscreen(i),
                      child: Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                              Icons.image_not_supported,
                              size: 60),
                        ),
                      ),
                    ),
                  ),

            // __Gradient bas__
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),

            // ___Indicateurs de page (points)__
            if (images.length > 1)
              Positioned(
                bottom: 56,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 3),
                      width: _indexImageActuel == i ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _indexImageActuel == i
                            ? Colors.white
                            : Colors.white54,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

            // ___Compteur images___
            if (images.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_indexImageActuel + 1}/${images.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
              ),

            // __Nom + adresse en bas__
            Positioned(
              bottom: 20,
              left: 16,
              right: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.lieu.nom,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(widget.lieu.adresse,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // __Corps principal___
  Widget _buildBody(BuildContext context, String langue) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //__Note étoiles___
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                    i < widget.lieu.note.floor()
                        ? Icons.star
                        : Icons.star_border,
                    size: 22,
                    color: Colors.amber,
                  )),
              const SizedBox(width: 8),
              Text('${widget.lieu.note}/5',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),

          // __Description__
          Text(widget.lieu.description,
              style:
                  const TextStyle(fontSize: 15, height: 1.6)),
          const SizedBox(height: 24),

          // __Bouton vidéo (si disponible)__
          if (widget.lieu.aVideo) ...[
            GestureDetector(
              onTap: _ouvrirVideo,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(14),
                  image: widget.lieu.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                              widget.lieu.imageUrl),
                          fit: BoxFit.cover,
                          opacity: 0.5,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.rouge,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.rouge
                                .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Voir la vidéo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          //__Miniatures galerie (si > 1 image)__
          if (widget.lieu.aGalerie) ...[
            Row(
              children: [
                const Icon(Icons.photo_library,
                    color: AppTheme.rouge, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Photos (${widget.lieu.toutesLesImages.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.lieu.toutesLesImages.length,
                itemBuilder: (_, i) {
                  final img =
                      widget.lieu.toutesLesImages[i];
                  final isActif = i == _indexImageActuel;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(i,
                          duration:
                              const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                      setState(
                          () => _indexImageActuel = i);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      margin:
                          const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: isActif
                              ? AppTheme.rouge
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8),
                        child: Image.network(img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    color:
                                        Colors.grey[200])),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // __Adresse + contact__
          GestureDetector(
            onTap: _voirSurCarte,
            child: _buildInfoRow(
              Icons.location_on,
              Traductions.t('adresse', langue),
              widget.lieu.adresse,
              isLink: true,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _appeler,
            child: _buildInfoRow(
              Icons.phone,
              Traductions.t('contact', langue),
              widget.lieu.contact,
              isLink: true,
            ),
          ),
          const SizedBox(height: 24),

          // __Bouton Google Maps__
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _voirSurCarte,
              icon: const Icon(Icons.map, color: AppTheme.rouge),
              label: const Text('Ouvrir dans Google Maps',
                  style: TextStyle(
                      color: AppTheme.rouge,
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.rouge),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String valeur,
      {bool isLink = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLink
            ? AppTheme.rouge.withOpacity(0.06)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLink
              ? AppTheme.rouge.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.rouge, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(valeur,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isLink ? AppTheme.rouge : null,
                        decoration: isLink
                            ? TextDecoration.underline
                            : null)),
              ],
            ),
          ),
          if (isLink)
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.rouge),
        ],
      ),
    );
  }

  Widget _buildBottomBar(String langue) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _appeler,
              icon: const Icon(Icons.phone, color: Colors.white),
              label: Text(Traductions.t('appeler', langue),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vert,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _voirSurCarte,
              icon: const Icon(Icons.location_on,
                  color: Colors.white),
              label: Text(Traductions.t('voir_carte', langue),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.rouge,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
            ),
          ),
        ],
      ),
    );
  }
}

//__Galerie plein écran__
class _GalerieFullscreen extends StatefulWidget {
  final List<String> images;
  final int indexInitial;

  const _GalerieFullscreen(
      {required this.images, required this.indexInitial});

  @override
  State<_GalerieFullscreen> createState() =>
      _GalerieFullscreenState();
}

class _GalerieFullscreenState extends State<_GalerieFullscreen> {
  late int _index;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _index = widget.indexInitial;
    _ctrl = PageController(initialPage: widget.indexInitial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_index + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.images[i],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 60),
            ),
          ),
        ),
      ),
    );
  }
}