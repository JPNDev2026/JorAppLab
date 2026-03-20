import 'package:flutter/material.dart';

import '../../../theme/jorapp_theme.dart';
import 'category_card_painter.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String count;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: JorappColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: JorappColors.surfaceStrong,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: accentColor),
                    CustomPaint(
                      painter: CategoryCardPainter(
                        accentColor: accentColor,
                        lime: JorappColors.lime,
                      ),
                      size: Size.infinite,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.55],
                          colors: [
                            JorappColors.ink.withOpacity(0.72),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.32),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              count,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              size: 16,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catégorie',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accentColor.withOpacity(0.72),
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: JorappColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: JorappColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: accentColor.withOpacity(0.18),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: accentColor,
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
}
