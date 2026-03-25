import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageActuelle = 0;

  // ── Données des slides ───────────────────────────────────
  List<_SlideData> _slides(String langue) => [
        _SlideData(
          couleurFond: AppTheme.rouge,
          couleurAccent: const Color(0xFFFF6B6B),
          icone: Icons.travel_explore,
          titre: langue == 'fr'
              ? 'Bienvenue sur\nBurkina Tourisme'
              : 'Welcome to\nBurkina Tourisme',
          description: langue == 'fr'
              ? 'Découvrez les merveilles du Burkina Faso — un pays riche en culture, en histoire et en beautés naturelles.'
              : 'Discover the wonders of Burkina Faso — a country rich in culture, history and natural beauty.',
          emoji: '🇧🇫',
        ),
        _SlideData(
          couleurFond: AppTheme.vert,
          couleurAccent: const Color(0xFF4CAF50),
          icone: Icons.landscape,
          titre: langue == 'fr'
              ? 'Explorez\ndes lieux uniques'
              : 'Explore\nunique places',
          description: langue == 'fr'
              ? 'Cascades, pics rocheux, sites culturels, restaurants et hébergements — tout en un seul endroit.'
              : 'Waterfalls, rocky peaks, cultural sites, restaurants and accommodations — all in one place.',
          emoji: '🏞️',
        ),
        _SlideData(
          couleurFond: const Color(0xFFE6A800),
          couleurAccent: const Color(0xFFFFD740),
          icone: Icons.favorite,
          titre: langue == 'fr'
              ? 'Planifiez\nvos aventures'
              : 'Plan\nyour adventures',
          description: langue == 'fr'
              ? 'Sauvegardez vos lieux favoris, obtenez les contacts et naviguez facilement vers chaque destination.'
              : 'Save your favorite places, get contacts and navigate easily to each destination.',
          emoji: '✨',
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _terminer() async {
    // Marquer l'onboarding comme vu
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_vu', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _pageSuivante() {
    if (_pageActuelle < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _terminer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langue = context.watch<AppProvider>().langue;
    final slides = _slides(langue);
    final slide = slides[_pageActuelle];
    final isDerniere = _pageActuelle == 2;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: slide.couleurFond,
        child: SafeArea(
          child: Column(
            children: [
              // ── Bouton passer ──────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _terminer,
                    child: Text(
                      langue == 'fr' ? 'Passer' : 'Skip',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // ── PageView des slides ────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) =>
                      setState(() => _pageActuelle = i),
                  itemCount: slides.length,
                  itemBuilder: (_, i) =>
                      _buildSlide(slides[i], langue),
                ),
              ),

              // ── Indicateurs + bouton ───────────────────
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Points indicateurs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final actif = i == _pageActuelle;
                        return AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          width: actif ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: actif
                                ? Colors.white
                                : Colors.white
                                    .withOpacity(0.4),
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Bouton suivant / commencer
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _pageSuivante,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: slide.couleurFond,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              isDerniere
                                  ? (langue == 'fr'
                                      ? 'Commencer'
                                      : 'Get Started')
                                  : (langue == 'fr'
                                      ? 'Suivant'
                                      : 'Next'),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: slide.couleurFond,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isDerniere
                                  ? Icons.rocket_launch
                                  : Icons.arrow_forward,
                              color: slide.couleurFond,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_SlideData slide, String langue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Illustration centrale ──────────────────────
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    slide.icone,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // ── Titre ──────────────────────────────────────
          Text(
            slide.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // ── Description ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              slide.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modèle d'une slide ───────────────────────────────────
class _SlideData {
  final Color couleurFond;
  final Color couleurAccent;
  final IconData icone;
  final String titre;
  final String description;
  final String emoji;

  const _SlideData({
    required this.couleurFond,
    required this.couleurAccent,
    required this.icone,
    required this.titre,
    required this.description,
    required this.emoji,
  });
}
