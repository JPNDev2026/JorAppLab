import 'package:flutter/material.dart';

class FestiActivity {
  final String id;
  final String title;
  final String subtitle;
  final String weezeventUrl;
  final IconData icon;
  final Color accentColor;

  const FestiActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.weezeventUrl,
    required this.icon,
    required this.accentColor,
  });

  Uri trackedUrl() {
    final base = Uri.parse(weezeventUrl);
    final params = Map<String, String>.from(base.queryParameters);
    params['utm_source'] = 'jorapp';
    params['utm_medium'] = 'qr';
    params['utm_campaign'] = 'festijorat2026';
    params['utm_content'] = id;
    return base.replace(queryParameters: params);
  }
}
