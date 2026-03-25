// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lieu_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/favoris_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/auth/connexion_screen.dart';
import 'screens/auth/inscription_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'l10n/traductions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Vérifier si l'onboarding a déjà été vu
  final prefs = await SharedPreferences.getInstance();
  final onboardingVu = prefs.getBool('onboarding_vu') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(
            create: (_) => LieuProvider()..ecouterLieux()),
      ],
      builder: (context, _) =>
          BurkinaTourismeApp(onboardingVu: onboardingVu),
    ),
  );
}

class BurkinaTourismeApp extends StatelessWidget {
  final bool onboardingVu;

  const BurkinaTourismeApp({super.key, required this.onboardingVu});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final authProvider = context.watch<AppAuthProvider>();

    // Déterminer l'écran de démarrage
    Widget ecranDepart;
    if (!onboardingVu) {
      ecranDepart = const OnboardingScreen();
    } else if (authProvider.appUser != null) {
      ecranDepart = const MainScreen();
    } else {
      ecranDepart = const ConnexionScreen();
    }

    return MaterialApp(
      title: 'Burkina Tourisme',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routes: {
        '/home':         (_) => const MainScreen(),
        '/login':        (_) => const ConnexionScreen(),
        '/inscription':  (_) => const InscriptionScreen(),
        '/admin':        (_) => const AdminScreen(),
        '/onboarding':   (_) => const OnboardingScreen(),
      },
      home: ecranDepart,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<FavorisScreenState> _favorisKey =
      GlobalKey<FavorisScreenState>();
  final GlobalKey<ProfilScreenState> _profilKey =
      GlobalKey<ProfilScreenState>();

  @override
  Widget build(BuildContext context) {
    final langue = context.watch<AppProvider>().langue;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          FavorisScreen(key: _favorisKey),
          ProfilScreen(key: _profilKey),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 1) _favorisKey.currentState?.chargerFavoris();
            if (index == 2) _profilKey.currentState?.chargerStats();
            setState(() => _currentIndex = index);
          },
          selectedItemColor: AppTheme.rouge,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: Traductions.t('accueil', langue),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline),
              activeIcon: const Icon(Icons.favorite),
              label: Traductions.t('favoris', langue),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: Traductions.t('profil', langue),
            ),
          ],
        ),
      ),
    );
  }
}
