import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';

class ImageUploader extends StatefulWidget {
  final String dossier;
  final Function(String url) onUploaded;
  final double? height;
  final String? existingImageUrl;

  const ImageUploader({
    super.key,
    required this.dossier,
    required this.onUploaded,
    this.height = 200,
    this.existingImageUrl,
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  double _progress = 0.0;
  bool _isUploading = false;
  String? _error;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.existingImageUrl;
  }

  Future<void> _choisirEtUploader(bool depuisCamera) async {
    final image = await StorageService.choisirImage(depuisCamera: depuisCamera);
    if (image == null) return;

    setState(() {
      _isUploading = true;
      _progress = 0.0;
      _error = null;
    });

    // ✅ CORRECTION : Récupérer userId avec gestion d'erreur
    String? userId;
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      userId = authProvider.appUser?.uid; // ✅ Utiliser uid, pas id
    } catch (e) {
      debugPrint('Provider non disponible: $e');
      userId = null;
    }
    
    final result = await StorageService.uploadImageAvecProgression(
      image: image,
      dossier: widget.dossier,
      userId: userId,
      onProgression: (p) {
        if (mounted) {
          setState(() => _progress = p);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isUploading = false;
        if (result.isSuccess && result.url != null) {
          _imageUrl = result.url;
          widget.onUploaded(result.url!);
        } else {
          _error = result.error ?? 'Erreur lors de l\'upload';
        }
      });
    }
  }

  Future<void> _supprimerImage() async {
    if (_imageUrl == null) return;
    
    final success = await StorageService.supprimerImage(_imageUrl!);
    if (success && mounted) {
      setState(() => _imageUrl = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zone d'aperçu
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _imageUrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => 
                            progress == null ? child : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: _supprimerImage,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Aucune image', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
        ),
        
        const SizedBox(height: 12),
        
        // Barre de progression
        if (_isUploading) ...[
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _progress < 1.0 ? Colors.blue : Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text('${(_progress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 12),
        ],
        
        // Message d'erreur
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        
        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _choisirEtUploader(false),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _choisirEtUploader(true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}