import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';

class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() =>
      _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState
    extends State<MotDePasseOublieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.rouge,
        title: const Text('Récupération de compte',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.alternate_email, size: 18),
                text: "Username oublié"),
            Tab(icon: Icon(Icons.lock_reset, size: 18),
                text: "PIN oublié"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OngletUsernameOublie(),
          _OngletPinOublie(),
        ],
      ),
    );
  }
}

// ONGLET 1 : Username oublié

class _OngletUsernameOublie extends StatefulWidget {
  const _OngletUsernameOublie();

  @override
  State<_OngletUsernameOublie> createState() =>
      _OngletUsernameOublieState();
}

class _OngletUsernameOublieState
    extends State<_OngletUsernameOublie> {
  final _emailCtrl = TextEditingController();
  String? _usernameRetrouve;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechercherUsername() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    final auth = context.read<AppAuthProvider>();
    final result =
        await auth.recupererUsername(_emailCtrl.text.trim());

    if (result.estSucces) {
      setState(() => _usernameRetrouve = result.username);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucun compte associé à cet email'),
        backgroundColor: Colors.orange,
      ));
      setState(() => _usernameRetrouve = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _Icone(icon: Icons.manage_accounts, isDark: isDark),
          const SizedBox(height: 20),
          _Titre("Retrouver votre nom d'utilisateur",
              isDark: isDark),
          const SizedBox(height: 8),
          _SousTitre(
              "Entrez l'email associé à votre compte.\nVotre username vous sera affiché.",
              isDark: isDark),
          const SizedBox(height: 32),
          _ChampEmail(
              controller: _emailCtrl,
              isDark: isDark,
              label: 'Votre adresse email'),
          const SizedBox(height: 20),
          _BoutonPrincipal(
            label: 'Rechercher',
            icon: Icons.search,
            isLoading: auth.isLoading,
            onPressed: _rechercherUsername,
          ),

          // Résultat
          if (_usernameRetrouve != null) ...[
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.vert.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.vert.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.vert, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    "Votre nom d'utilisateur est :",
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.vert.withOpacity(0.3)),
                    ),
                    child: Text(
                      _usernameRetrouve!,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.vert,
                          letterSpacing: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.login,
                          color: AppTheme.rouge, size: 18),
                      label: const Text('Se connecter',
                          style: TextStyle(
                              color: AppTheme.rouge)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.rouge),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ONGLET 2 : PIN oublié — 2 étapes seulement

class _OngletPinOublie extends StatefulWidget {
  const _OngletPinOublie();

  @override
  State<_OngletPinOublie> createState() =>
      _OngletPinOublieState();
}

class _OngletPinOublieState extends State<_OngletPinOublie> {
  final _emailCtrl = TextEditingController();
  final _nouveauPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  // Étape 1 = email, étape 2 = nouveau PIN, étape 3 = succès
  int _etape = 1;
  AppUser? _utilisateurTrouve;
  bool _obscurPin = true;
  bool _obscurConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nouveauPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  // __Étape 1 : vérifier l'email__
  Future<void> _verifierEmail() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    final auth = context.read<AppAuthProvider>();
    final result =
        await auth.verifierEmail(_emailCtrl.text.trim());

    if (result.estTrouve && mounted) {
      setState(() {
        _utilisateurTrouve = result.utilisateur;
        _etape = 2;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            auth.errorMessage ?? 'Aucun compte associé à cet email'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // __Étape 2 : enregistrer le nouveau PIN__
  Future<void> _enregistrerNouveauPin() async {
    final pin = _nouveauPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();

    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le PIN doit contenir exactement 4 chiffres'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Les PIN ne correspondent pas'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final auth = context.read<AppAuthProvider>();
    final ok = await auth.definirNouveauPin(
      uid: _utilisateurTrouve!.uid,
      email: _utilisateurTrouve!.email,
      ancienPinHash: _utilisateurTrouve!.pinHash,
      nouveauPin: pin,
    );

    if (ok && mounted) {
      setState(() => _etape = 3);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            auth.errorMessage ?? 'Erreur lors de la mise à jour'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _IndicateurEtapes(etape: _etape, isDark: isDark),
          const SizedBox(height: 28),
          if (_etape == 1) _buildEtape1(auth, isDark),
          if (_etape == 2) _buildEtape2(auth, isDark),
          if (_etape == 3) _buildEtape3(isDark),
        ],
      ),
    );
  }

  // __Étape 1 : saisie email__
  Widget _buildEtape1(AppAuthProvider auth, bool isDark) {
    return Column(
      children: [
        _Icone(icon: Icons.email_outlined, isDark: isDark),
        const SizedBox(height: 16),
        _Titre('Vérification de votre compte', isDark: isDark),
        const SizedBox(height: 8),
        _SousTitre(
            'Entrez l\'adresse email associée à votre compte.\nSi elle est reconnue, vous pourrez définir un nouveau PIN.',
            isDark: isDark),
        const SizedBox(height: 28),
        _ChampEmail(
            controller: _emailCtrl,
            isDark: isDark,
            label: 'Votre adresse email'),
        const SizedBox(height: 20),
        _BoutonPrincipal(
          label: 'Vérifier mon email',
          icon: Icons.verified_user,
          isLoading: auth.isLoading,
          onPressed: _verifierEmail,
        ),
      ],
    );
  }

  // __Étape 2 : nouveau PIN__
  Widget _buildEtape2(AppAuthProvider auth, bool isDark) {
    return Column(
      children: [
        _Icone(
            icon: Icons.lock_open,
            isDark: isDark,
            color: AppTheme.vert),
        const SizedBox(height: 16),
        _Titre('Définir un nouveau PIN', isDark: isDark),
        const SizedBox(height: 8),

        // Afficher le nom de l'utilisateur trouvé

        if (_utilisateurTrouve != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.vert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.vert.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person,
                    color: AppTheme.vert, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_utilisateurTrouve!.prenom} ${_utilisateurTrouve!.nom}',
                  style: const TextStyle(
                      color: AppTheme.vert,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _SousTitre(
            'Choisissez un nouveau code PIN à 4 chiffres.',
            isDark: isDark),
        const SizedBox(height: 24),
        _ChampPin(
          controller: _nouveauPinCtrl,
          label: 'Nouveau PIN (4 chiffres)',
          isDark: isDark,
          obscure: _obscurPin,
          onToggle: () =>
              setState(() => _obscurPin = !_obscurPin),
        ),
        const SizedBox(height: 14),
        _ChampPin(
          controller: _confirmPinCtrl,
          label: 'Confirmer le PIN',
          isDark: isDark,
          obscure: _obscurConfirm,
          onToggle: () =>
              setState(() => _obscurConfirm = !_obscurConfirm),
        ),
        const SizedBox(height: 20),
        _BoutonPrincipal(
          label: 'Enregistrer le nouveau PIN',
          icon: Icons.save,
          isLoading: auth.isLoading,
          color: AppTheme.vert,
          onPressed: _enregistrerNouveauPin,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _etape = 1;
            _utilisateurTrouve = null;
          }),
          child: const Text('Changer d\'email',
              style: TextStyle(color: AppTheme.rouge)),
        ),
      ],
    );
  }

  // __Étape 3 : succès___
  Widget _buildEtape3(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppTheme.vert.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle,
              size: 55, color: AppTheme.vert),
        ),
        const SizedBox(height: 20),
        _Titre('PIN modifié avec succès !', isDark: isDark),
        const SizedBox(height: 12),
        _SousTitre(
            'Votre nouveau code PIN a été enregistré.\nVous pouvez maintenant vous connecter.',
            isDark: isDark),
        const SizedBox(height: 32),
        _BoutonPrincipal(
          label: 'Se connecter',
          icon: Icons.login,
          isLoading: false,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/login'),
        ),
      ],
    );
  }
}


// __WIDGETS RÉUTILISABLES___

class _Icone extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color color;

  const _Icone({
    required this.icon,
    required this.isDark,
    this.color = AppTheme.rouge,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: color),
        ),
      );
}

class _Titre extends StatelessWidget {
  final String texte;
  final bool isDark;
  const _Titre(this.texte, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
        texte,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        textAlign: TextAlign.center,
      );
}

class _SousTitre extends StatelessWidget {
  final String texte;
  final bool isDark;
  const _SousTitre(this.texte, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
        texte,
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      );
}

class _BoutonPrincipal extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color color;

  const _BoutonPrincipal({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
    this.color = AppTheme.rouge,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 18),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      );
}

class _ChampEmail extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String label;

  const _ChampEmail({
    required this.controller,
    required this.isDark,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: isDark
                  ? Colors.grey[400]
                  : Colors.grey[600]),
          prefixIcon: const Icon(Icons.email_outlined,
              color: AppTheme.rouge),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppTheme.rouge, width: 2)),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey[50],
        ),
      );
}

class _ChampPin extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isDark;
  final bool obscure;
  final VoidCallback onToggle;

  const _ChampPin({
    required this.controller,
    required this.label,
    required this.isDark,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: obscure,
        maxLength: 4,
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: isDark
                  ? Colors.grey[400]
                  : Colors.grey[600]),
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppTheme.rouge),
          suffixIcon: IconButton(
            icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey),
            onPressed: onToggle,
          ),
          counterText: '',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppTheme.rouge, width: 2)),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey[50],
        ),
      );
}

// __Indicateur d'étapes___
class _IndicateurEtapes extends StatelessWidget {
  final int etape;
  final bool isDark;

  const _IndicateurEtapes(
      {required this.etape, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final etapes = ['Email', 'Nouveau PIN', 'Terminé'];
    return Row(
      children: List.generate(etapes.length * 2 - 1, (i) {
        if (i.isOdd) {
          final idx = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: idx < etape - 1
                  ? AppTheme.vert
                  : (isDark
                      ? Colors.grey[700]
                      : Colors.grey[300]),
            ),
          );
        }
        final index = i ~/ 2;
        final actif = index < etape;
        final courant = index == etape - 1;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: actif
                    ? (courant ? AppTheme.rouge : AppTheme.vert)
                    : (isDark
                        ? Colors.grey[700]
                        : Colors.grey[300]),
              ),
              child: Center(
                child: actif && !courant
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 16)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                            color: actif
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500]),
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etapes[index],
              style: TextStyle(
                  fontSize: 10,
                  color: actif
                      ? (courant
                          ? AppTheme.rouge
                          : AppTheme.vert)
                      : (isDark
                          ? Colors.grey[600]
                          : Colors.grey[400])),
            ),
          ],
        );
      }),
    );
  }
}