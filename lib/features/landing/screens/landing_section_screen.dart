import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../services/landing_service.dart';
import '../../../theme/jorapp_theme.dart';

class LandingSectionScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  static final LandingService _landingService = LandingService();

  const LandingSectionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  bool get _isRestaurantsSection => title == 'Restaurants';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAF5), Color(0xFFEAF2E3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isRestaurantsSection) ...[
              FutureBuilder<List<Restaurant>>(
                future: _landingService.fetchRestaurants(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _SectionMessageCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Impossible de charger les restaurants.',
                        message: snapshot.error.toString(),
                      ),
                    );
                  }

                  final restaurants = snapshot.data ?? const <Restaurant>[];
                  if (restaurants.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: _SectionMessageCard(
                        icon: Icons.restaurant_outlined,
                        title: 'Aucun restaurant disponible.',
                        message:
                            'La collection est bien branchée. Il ne reste plus qu’à publier les premières fiches.',
                      ),
                    );
                  }

                  return Column(
                    children: restaurants
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _RestaurantCard(
                              item: item,
                              accentColor: accentColor,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant item;
  final Color accentColor;

  const _RestaurantCard({
    required this.item,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: JorappColors.surfaceStrong,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: JorappColors.ink.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.coverUrl != null)
                    Image.network(
                      item.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _RestaurantFallbackCover(accentColor: accentColor);
                      },
                    )
                  else
                    _RestaurantFallbackCover(accentColor: accentColor),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          JorappColors.ink.withOpacity(0.28),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nom,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: JorappColors.ink,
                    ),
                  ),
                  if ((item.descriptionCourte ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.descriptionCourte!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF50616A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantFallbackCover extends StatelessWidget {
  final Color accentColor;

  const _RestaurantFallbackCover({
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.92),
            JorappColors.tealDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 42,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SectionMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SectionMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: JorappColors.surfaceStrong,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 36,
            color: JorappColors.tealDark,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: JorappColors.tealDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF50616A),
            ),
          ),
        ],
      ),
    );
  }
}
