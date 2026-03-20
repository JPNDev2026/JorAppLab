import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../theme/jorapp_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const List<String> _slideImagePaths = <String>[
    'assets/welcome/photo_1.jpg',
    'assets/welcome/photo_2.jpg',
    'assets/welcome/photo_3.jpg',
  ];
  static const List<Color> _slideColors = <Color>[
    Color(0xFF2E4A3E),
    Color(0xFF1F3D35),
    Color(0xFF163028),
  ];
  static const List<_WelcomeSlide> _slides = <_WelcomeSlide>[
    _WelcomeSlide(
      title: 'Découvrir la région',
      subtitle: 'Restauration, artisans du goût, offres culturelles, séjours',
    ),
    _WelcomeSlide(
      title: 'Explorer le parc',
      subtitle: 'Itinéraires, activités, lieux d’accueil, balades contées',
    ),
    _WelcomeSlide(
      title: 'Observer et Soigner',
      subtitle:
          'Relevés faune et flore, cartographie collaborative, activités régénératrices',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JorappColors.ink,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: 3,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final screenHeight = MediaQuery.sizeOf(context).height;
              final textTop = screenHeight * 0.38;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _slideImagePaths[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: _slideColors[index]);
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.28),
                            Colors.black.withOpacity(0.16),
                            Colors.black.withOpacity(0.34),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/branding/jorapp_logo.png',
                        width: 88,
                      ),
                    ),
                  ),
                  Positioned(
                    top: textTop,
                    left: 24,
                    right: 24,
                    child: Column(
                      children: [
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 140),
                      child: Container(
                        width: 72,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 48,
            right: 16,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.landing,
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Passer'),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(3, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isActive ? 12 : 9,
                  height: isActive ? 12 : 9,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? JorappColors.lime
                        : Colors.white.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSlide {
  final String title;
  final String subtitle;

  const _WelcomeSlide({
    required this.title,
    required this.subtitle,
  });
}
