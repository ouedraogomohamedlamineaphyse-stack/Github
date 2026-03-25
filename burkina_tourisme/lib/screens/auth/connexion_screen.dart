import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';
import 'mot_de_passe_oublie_screen.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _usernameCtrl = TextEditingController();
  AppUser? _utilisateurTrouve;
  int _etape = 1; // 1 = username; 2 = PIN

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _chercherUtilisateur() async {
    final auth = context.read<AppAuthProvider>();
    final user =
        await auth.chercherUtilisateur(_usernameCtrl.text.trim());
    if (user != null && mounted) {
      setState(() {
        _utilisateurTrouve = user;
        _etape = 2;
      });
    }
  }

  void _retourEtape1() {
    setState(() {
      _etape = 1;
      _utilisateurTrouve = null;
      _usernameCtrl.clear();
    });
  }

  void _ouvrirRecuperation() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const MotDePasseOublieScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const couleurPrimaire = Color(0xFFCC0000);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: couleurPrimaire.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.travel_explore,
                    size: 45, color: couleurPrimaire),
              ),
              const SizedBox(height: 16),
              const Text('Burkina Tourisme',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _etape == 1
                    ? "Entrez votre nom d'utilisateur"
                    : "Bonjour ${_utilisateurTrouve?.prenom} 👋",
                style: TextStyle(
                    color: Theme.of(context).brightness ==
                            Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              if (_etape == 1)
                _EtapeUsername(
                  controller: _usernameCtrl,
                  onSuivant: _chercherUtilisateur,
                  couleur: couleurPrimaire,
                  onUsernameOublie: _ouvrirRecuperation,
                )
              else
                _EtapePin(
                  utilisateur: _utilisateurTrouve!,
                  onRetour: _retourEtape1,
                  couleur: couleurPrimaire,
                  onPinOublie: _ouvrirRecuperation,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Étape 1 : Username ───────────────────────────────────
class _EtapeUsername extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSuivant;
  final VoidCallback onUsernameOublie;
  final Color couleur;

  const _EtapeUsername({
    required this.controller,
    required this.onSuivant,
    required this.couleur,
    required this.onUsernameOublie,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TextField(
          controller: controller,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: "Nom d'utilisateur",
            labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
            prefixIcon: const Icon(Icons.alternate_email,
                color: Color(0xFFCC0000)),
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
                borderSide:
                    const BorderSide(color: Color(0xFFCC0000), width: 2)),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
          ),
          onSubmitted: (_) => onSuivant(),
        ),
        const SizedBox(height: 8),

        // Lien username oublié
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onUsernameOublie,
            child: Text(
              "Nom d'utilisateur oublié ?",
              style: TextStyle(
                  color: couleur,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),

        if (auth.errorMessage != null)
          _ErrorBox(message: auth.errorMessage!),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : onSuivant,
            style: ElevatedButton.styleFrom(
              backgroundColor: couleur,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: auth.isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white)
                : const Text('Suivant',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/inscription'),
          child: Text("Pas de compte ? S'inscrire",
              style: TextStyle(color: couleur)),
        ),
      ],
    );
  }
}

// - Étape 2 : PIN -
class _EtapePin extends StatefulWidget {
  final AppUser utilisateur;
  final VoidCallback onRetour;
  final VoidCallback onPinOublie;
  final Color couleur;

  const _EtapePin({
    required this.utilisateur,
    required this.onRetour,
    required this.couleur,
    required this.onPinOublie,
  });

  @override
  State<_EtapePin> createState() => _EtapePinState();
}

class _EtapePinState extends State<_EtapePin> {
  final List<String> _digits = [];

  void _ajouterChiffre(String d) {
    if (_digits.length < 4) {
      setState(() => _digits.add(d));
      if (_digits.length == 4) _verifierPin();
    }
  }

  void _supprimerChiffre() {
    if (_digits.isNotEmpty) setState(() => _digits.removeLast());
  }

  Future<void> _verifierPin() async {
    final pin = _digits.join();
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.verifierPin(
      utilisateur: widget.utilisateur,
      pin: pin,
    );
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      setState(() => _digits.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: widget.couleur.withOpacity(0.15),
          child: Text(
            widget.utilisateur.prenom[0].toUpperCase(),
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: widget.couleur),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.utilisateur.prenom} ${widget.utilisateur.nom}',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),

        // Points PIN
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              4,
              (i) => Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _digits.length
                          ? widget.couleur
                          : Colors.grey.shade400,
                    ),
                  )),
        ),
        const SizedBox(height: 8),

        if (auth.errorMessage != null)
          _ErrorBox(message: auth.errorMessage!),

        const SizedBox(height: 16),

        _ClavierPin(
          onDigit: _ajouterChiffre,
          onSupprimer: _supprimerChiffre,
          couleur: widget.couleur,
          isLoading: auth.isLoading,
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: widget.onRetour,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Retour'),
            ),
            TextButton(
              onPressed: widget.onPinOublie,
              child: Text('PIN oublié ?',
                  style: TextStyle(color: widget.couleur)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─ Clavier numérique ─
class _ClavierPin extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onSupprimer;
  final Color couleur;
  final bool isLoading;

  const _ClavierPin({
    required this.onDigit,
    required this.onSupprimer,
    required this.couleur,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return InkWell(
          onTap: isLoading
              ? null
              : () => k == '⌫' ? onSupprimer() : onDigit(k),
          borderRadius: BorderRadius.circular(50),
          child: Center(
            child: k == '⌫'
                ? Icon(Icons.backspace_outlined, color: couleur)
                : Text(k,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.grey.shade800)),
          ),
        );
      }).toList(),
    );
  }
}

// ─ Widget erreur ─
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.withOpacity(0.15)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark
                ? Colors.red.withOpacity(0.3)
                : Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}