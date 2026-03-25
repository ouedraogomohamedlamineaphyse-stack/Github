import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../l10n/traductions.dart';
import '../screens/attractions_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final langue = provider.langue;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(langue),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),
                _buildSectionLabel('EXPLORER', context),
                _buildCategorieTile(
                  context,
                  icon: Icons.landscape,
                  label: Traductions.t('attractions', langue),
                  color: AppTheme.vert,
                  categorie: 'attraction',
                  langue: langue,
                ),
                _buildCategorieTile(
                  context,
                  icon: Icons.restaurant,
                  label: Traductions.t('restaurants', langue),
                  color: AppTheme.rouge,
                  categorie: 'restaurant',
                  langue: langue,
                ),
                _buildCategorieTile(
                  context,
                  icon: Icons.hotel,
                  label: Traductions.t('hebergements', langue),
                  color: Colors.orange,
                  categorie: 'hebergement',
                  langue: langue,
                ),
                _buildCategorieTile(
                  context,
                  icon: Icons.event,
                  label: Traductions.t('culture', langue),
                  color: const Color(0xFFE6A800),
                  categorie: 'culture',
                  langue: langue,
                ),
                const Divider(height: 30, indent: 16, endIndent: 16),
                _buildSectionLabel('APP', context),
                // Thème
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dark_mode,
                        color: Colors.deepPurple, size: 20),
                  ),
                  title: Text(
                    Traductions.t('theme', langue),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Switch(
                    value: provider.isDark,
                    activeThumbColor: AppTheme.rouge,
                    onChanged: (_) => provider.toggleTheme(),
                  ),
                ),
                // Langue
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language,
                        color: Colors.blue, size: 20),
                  ),
                  title: Text(
                    Traductions.t('langue', langue),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _langueBtn('FR', 'fr', provider),
                      const SizedBox(width: 6),
                      _langueBtn('EN', 'en', provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  // ___Header du drawer____
  Widget _buildHeader(String langue) {
    return DrawerHeader(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(color: AppTheme.rouge),
        child: Stack(
          children: [
            // Cercles décoratifs
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Drapeau
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      'https://flagcdn.com/w40/bf.png',
                      width: 42,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        '🇧🇫',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Burkina Tourisme',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    langue == 'fr'
                        ? 'Pays des hommes intègres 🇧🇫'
                        : 'Land of upright people 🇧🇫',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ___Label de section___
  Widget _buildSectionLabel(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ___Tile de catégorie____
  Widget _buildCategorieTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String categorie,
    required String langue,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey[400]),
      onTap: () {
        // Ferme le drawer
        Navigator.pop(context);
        // Navigue vers la liste
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttractionsScreen(
              categorie: categorie,
              titre: label,
            ),
          ),
        );
      },
    );
  }

  //___Bouton langue____
  Widget _langueBtn(String label, String code, AppProvider provider) {
    final isSelected = provider.langue == code;
    return GestureDetector(
      onTap: () => provider.setLangue(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.rouge : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.rouge : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ____Footer____
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.place, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            'Burkina Tourisme v1.0.0',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}