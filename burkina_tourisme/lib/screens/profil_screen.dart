import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart' as appAuth;
import '../providers/lieu_provider.dart';
import '../l10n/traductions.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => ProfilScreenState();
}

class ProfilScreenState extends State<ProfilScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chargerStats();
      _verifierAdmin();
    });
  }

  void chargerStats() {
    final authProvider = context.read<appAuth.AppAuthProvider>();
    final lieuProvider = context.read<LieuProvider>();
    if (authProvider.appUser != null) {
      lieuProvider.chargerFavoris(authProvider.appUser!.uid);
    }
  }

  void _verifierAdmin() {
    final authProvider = context.read<appAuth.AppAuthProvider>();
    if (authProvider.appUser?.isAdmin == true) {
      setState(() => _isAdmin = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final langue = provider.langue;
    final authProvider = context.watch<appAuth.AppAuthProvider>();

    // ✅ Redirection si déconnecté
    if (authProvider.appUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Traductions.t('profil', langue),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(langue, authProvider),
            const SizedBox(height: 20),
            _buildStats(langue),
            const SizedBox(height: 20),
            _buildMenu(context, provider),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      String langue, appAuth.AppAuthProvider authProvider) {
    final appUser = authProvider.appUser;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.rouge,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                appUser != null
                    ? appUser.prenom[0].toUpperCase()
                    : 'V',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.rouge,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            authProvider.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          if (appUser != null)
            Text(
              '@${appUser.username}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 4),

          Text(
            authProvider.userEmail,
            style: const TextStyle(
                color: Colors.white60, fontSize: 12),
          ),

          if (_isAdmin) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white54),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified,
                      color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Administrateur',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Bouton déconnexion
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        langue == 'fr'
                            ? 'Déconnexion'
                            : 'Sign Out',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        langue == 'fr'
                            ? 'Voulez-vous vraiment vous déconnecter ?'
                            : 'Are you sure you want to sign out?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: Text(
                            langue == 'fr'
                                ? 'Annuler'
                                : 'Cancel',
                            style: const TextStyle(
                                color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: Text(
                            langue == 'fr'
                                ? 'Déconnecter'
                                : 'Sign Out',
                            style: const TextStyle(
                              color: AppTheme.rouge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context
                        .read<appAuth.AppAuthProvider>()
                        .deconnecter();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil(
                              '/login', (_) => false);
                    }
                  }
                },
                icon: const Icon(Icons.logout,
                    color: Colors.white, size: 18),
                label: Text(
                  langue == 'fr'
                      ? 'Se déconnecter'
                      : 'Sign Out',
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),

              if (_isAdmin) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin'),
                  icon: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 18),
                  label: const Text('Admin',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.white54),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(String langue) {
    final lieuProvider = context.watch<LieuProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
              Icons.favorite,
              lieuProvider.favoris.length.toString(),
              Traductions.t('favoris', langue),
              AppTheme.rouge),
          const SizedBox(width: 12),
          _buildStatCard(
              Icons.place,
              lieuProvider.lieux.length.toString(),
              Traductions.t('lieux', langue),
              AppTheme.vert),
          const SizedBox(width: 12),
          _buildStatCard(
              Icons.explore,
              '4',
              Traductions.t('categories', langue),
              const Color(0xFFE6A800)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String valeur, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, AppProvider provider) {
    final langue = provider.langue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dark_mode,
                    color: Colors.deepPurple, size: 22),
              ),
              title: Text(
                Traductions.t('theme', langue),
                style: const TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w500),
              ),
              trailing: Switch(
                value: provider.isDark,
                activeThumbColor: AppTheme.rouge,
                onChanged: (_) => provider.toggleTheme(),
              ),
            ),
            const Divider(height: 1, indent: 60),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.language,
                    color: Colors.blue, size: 22),
              ),
              title: Text(
                Traductions.t('langue', langue),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _langueBtn('FR', 'fr', provider),
                  const SizedBox(width: 8),
                  _langueBtn('EN', 'en', provider),
                ],
              ),
            ),
            const Divider(height: 1, indent: 60),

            _buildMenuItem(
                context,
                Icons.notifications_outlined,
                Traductions.t('notifications', langue),
                Colors.orange,
                null),
            const Divider(height: 1, indent: 60),

            _buildMenuItem(
                context,
                Icons.share,
                Traductions.t('partager', langue),
                AppTheme.rouge,
                null),
            const Divider(height: 1, indent: 60),

            _buildMenuItem(
                context,
                Icons.star_outline,
                Traductions.t('noter', langue),
                Colors.amber,
                null),
            const Divider(height: 1, indent: 60),

            _buildMenuItem(
              context,
              Icons.info_outline,
              Traductions.t('a_propos', langue),
              AppTheme.vert,
              () => _showAbout(context, langue),
            ),
            const Divider(height: 1, indent: 60),

            _buildMenuItem(
                context,
                Icons.privacy_tip_outlined,
                Traductions.t('confidentialite', langue),
                Colors.grey,
                null),
          ],
        ),
      ),
    );
  }

  Widget _langueBtn(
      String label, String code, AppProvider provider) {
    final isSelected = provider.langue == code;
    return GestureDetector(
      onTap: () => provider.setLangue(code),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.rouge : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.rouge : Colors.grey),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon,
      String label, Color color, VoidCallback? onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showAbout(BuildContext context, String langue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppTheme.rouge),
            SizedBox(width: 8),
            Text('Burkina Tourisme'),
          ],
        ),
        content:
            Text(Traductions.t('a_propos_contenu', langue)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Traductions.t('fermer', langue),
              style: const TextStyle(color: AppTheme.rouge),
            ),
          ),
        ],
      ),
    );
  }
}