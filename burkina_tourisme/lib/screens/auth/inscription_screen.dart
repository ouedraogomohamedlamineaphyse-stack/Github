import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.inscrire(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      pin: _pinCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final langue = context.watch<AppProvider>().langue;
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // __Header__
              Container(
                width: double.infinity,
                height: 200,
                decoration: const BoxDecoration(
                  color: AppTheme.rouge,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30, right: -30,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add,
                              size: 48, color: Colors.white),
                          const SizedBox(height: 12),
                          Text(
                            langue == 'fr'
                                ? 'Créer un compte'
                                : 'Create Account',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            langue == 'fr'
                                ? 'Rejoignez Burkina Tourisme 🇧🇫'
                                : 'Join Burkina Tourisme 🇧🇫',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // __Formulaire__
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // __Nom__
                      _buildChamp(
                        controller: _nomCtrl,
                        label: langue == 'fr' ? 'Nom' : 'Last Name',
                        icon: Icons.person,
                        validator: (v) => v!.isEmpty
                            ? (langue == 'fr'
                                ? 'Nom requis'
                                : 'Last name required')
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // __Prénom__
                      _buildChamp(
                        controller: _prenomCtrl,
                        label: langue == 'fr' ? 'Prénom' : 'First Name',
                        icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty
                            ? (langue == 'fr'
                                ? 'Prénom requis'
                                : 'First name required')
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // __Username__
                      _buildChamp(
                        controller: _usernameCtrl,
                        label: langue == 'fr'
                            ? "Nom d'utilisateur"
                            : 'Username',
                        icon: Icons.alternate_email,
                        validator: (v) {
                          if (v!.isEmpty) {
                            return langue == 'fr'
                                ? "Nom d'utilisateur requis"
                                : 'Username required';
                          }
                          if (v.contains(' ')) {
                            return langue == 'fr'
                                ? 'Pas d\'espace autorisé'
                                : 'No spaces allowed';
                          }
                          if (v.length < 3) {
                            return langue == 'fr'
                                ? 'Minimum 3 caractères'
                                : 'Minimum 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // __Email__
                      _buildChamp(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) {
                            return langue == 'fr'
                                ? 'Email requis'
                                : 'Email required';
                          }
                          if (!v.contains('@')) {
                            return langue == 'fr'
                                ? 'Email invalide'
                                : 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // __PIN__
                      _buildChamp(
                        controller: _pinCtrl,
                        label: langue == 'fr'
                            ? 'Code PIN (4 chiffres)'
                            : 'PIN Code (4 digits)',
                        icon: Icons.lock,
                        keyboardType: TextInputType.number,
                        obscureText: _obscurePin,
                        maxLength: 4,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              color: Colors.grey),
                          onPressed: () =>
                              setState(() => _obscurePin = !_obscurePin),
                        ),
                        validator: (v) {
                          if (v!.length != 4) {
                            return langue == 'fr'
                                ? '4 chiffres requis'
                                : '4 digits required';
                          }
                          if (!RegExp(r'^\d{4}$').hasMatch(v)) {
                            return langue == 'fr'
                                ? 'Chiffres uniquement'
                                : 'Digits only';
                          }
                          return null;
                        },
                      ),

                      // __Confirmer PIN__
                      _buildChamp(
                        controller: _confirmPinCtrl,
                        label: langue == 'fr'
                            ? 'Confirmer le PIN'
                            : 'Confirm PIN',
                        icon: Icons.lock_outline,
                        keyboardType: TextInputType.number,
                        obscureText: _obscureConfirm,
                        maxLength: 4,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              color: Colors.grey),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) {
                          if (v != _pinCtrl.text) {
                            return langue == 'fr'
                                ? 'Les PIN ne correspondent pas'
                                : 'PINs do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // __Erreur__
                      if (auth.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(auth.errorMessage!,
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // __Bouton inscription__
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _inscrire,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.rouge,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  langue == 'fr'
                                      ? 'Créer mon compte'
                                      : 'Create Account',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // __Lien connexion__
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/login'),
                        child: Text(
                          langue == 'fr'
                              ? 'Déjà un compte ? Se connecter'
                              : 'Already have an account? Sign In',
                          style:
                              const TextStyle(color: AppTheme.rouge),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChamp({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.rouge),
        suffixIcon: suffixIcon,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.rouge, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}