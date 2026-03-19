import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../../../core/services/pb_client.dart';
import '../../../theme/jorapp_theme.dart';
import '../models/balade.dart';
import '../services/audio_guide_service.dart';

class AudioGuideScreen extends StatefulWidget {
  const AudioGuideScreen({super.key});

  @override
  State<AudioGuideScreen> createState() => _AudioGuideScreenState();
}

class _AudioGuideScreenState extends State<AudioGuideScreen> {
  late final Future<List<Balade>> _baladesFuture =
      AudioGuideService().fetchBalades();

  String? get _authToken {
    final token = PbClient.instance.pb.authStore.token;
    return token.isEmpty ? null : token;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 26,
                height: 26,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Balades audio'),
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
        child: FutureBuilder<List<Balade>>(
          future: _baladesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: JorappColors.tealDark,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Impossible de charger les balades audio.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF50616A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final balades = snapshot.data ?? const <Balade>[];
            developer.log(
              '[AudioGuideScreen] balades loaded=${balades.length}',
            );
            if (balades.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.headset_off_rounded,
                            size: 40,
                            color: JorappColors.tealDark,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Aucune balade audio disponible pour le moment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: JorappColors.tealDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Choisis une balade',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: JorappColors.tealDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Télécharge et lance une expérience audio géolocalisée dans le parc.',
                  style: TextStyle(
                    color: Color(0xFF50616A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ...balades.map(
                  (balade) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _BaladeCard(
                      balade: balade,
                      authToken: _authToken,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BaladeCard extends StatelessWidget {
  final Balade balade;
  final String? authToken;

  const _BaladeCard({
    required this.balade,
    required this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'La balade "${balade.nom}" sera branchée à l’étape suivante.',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (balade.coverUrl != null)
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Image.network(
                  balade.coverUrl!,
                  fit: BoxFit.cover,
                  headers: authToken == null
                      ? null
                      : <String, String>{
                          'Authorization': 'Bearer $authToken',
                        },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: JorappColors.surfaceStrong,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: JorappColors.surfaceStrong,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: JorappColors.tealDark,
                      size: 32,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 132,
                color: JorappColors.surfaceStrong,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.headset_rounded,
                  color: JorappColors.tealDark,
                  size: 36,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balade.nom,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: JorappColors.tealDark,
                          ),
                        ),
                        if (balade.description != null &&
                            balade.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            balade.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF50616A),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: JorappColors.surfaceStrong,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: JorappColors.tealDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
