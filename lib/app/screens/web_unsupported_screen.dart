import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/jorapp_theme.dart';
import '../widgets/jorapp_app_bar.dart';

const String _kPlayStoreUrl = '#';
const String _kAppStoreUrl = '#';

class WebUnsupportedScreen extends StatelessWidget {
  const WebUnsupportedScreen({super.key});

  Future<void> _openUrl(String url) async {
    if (url == '#') return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JorappAppBar(
        onMenuPressed: () => Navigator.of(context).maybePop(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAF5), Color(0xFFEAF2E3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: JorappColors.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smartphone_rounded,
                        size: 40,
                        color: JorappColors.teal,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Fonctionnalité non disponible sur le web',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: JorappColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Téléchargez l\'application officielle JorAppLab pour accéder à cette fonctionnalité sur votre mobile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: JorappColors.ink.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openUrl(_kPlayStoreUrl),
                        style: FilledButton.styleFrom(
                          backgroundColor: JorappColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.android_rounded, size: 20),
                        label: const Text(
                          'Google Play',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openUrl(_kAppStoreUrl),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: JorappColors.teal,
                          side: const BorderSide(
                            color: JorappColors.teal,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.apple_rounded, size: 20),
                        label: const Text(
                          'App Store',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
