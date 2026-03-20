import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../../../core/services/pb_client.dart';
import '../../../theme/jorapp_theme.dart';
import '../../geofencing/geofencing_controller.dart';
import '../models/balade.dart';
import '../services/audio_guide_service.dart';
import 'audio_guide_balade_screen.dart';

class AudioGuideScreen extends StatefulWidget {
  final GeofencingController geofencingController;

  const AudioGuideScreen({
    super.key,
    required this.geofencingController,
  });

  @override
  State<AudioGuideScreen> createState() => _AudioGuideScreenState();
}

class _AudioGuideScreenState extends State<AudioGuideScreen> {
  final AudioGuideService _audioGuideService = AudioGuideService();
  late final Future<List<Balade>> _baladesFuture = _audioGuideService.fetchBalades();
  String? _loadingBaladeId;
  double _downloadProgress = 0;

  String? get _authToken {
    final token = PbClient.instance.pb.authStore.token;
    return token.isEmpty ? null : token;
  }

  Future<void> _openBalade(Balade balade) async {
    if (_loadingBaladeId != null) return;

    setState(() {
      _loadingBaladeId = balade.id;
      _downloadProgress = 0;
    });

    try {
      final points = await _audioGuideService.fetchAudioPoints(balade.id);
      if (points.isEmpty) {
        throw Exception('Aucun point audio disponible pour cette balade.');
      }

      final downloadedPoints = await _audioGuideService.downloadBalade(
        balade.id,
        points,
        (progress) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AudioGuideBaladeScreen(
            balade: balade,
            points: downloadedPoints,
            geofencingController: widget.geofencingController,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingBaladeId = null;
          _downloadProgress = 0;
        });
      }
    }
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
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Balades audio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                ...balades.map((balade) {
                  final isLoading = _loadingBaladeId == balade.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _BaladeCard(
                      balade: balade,
                      authToken: _authToken,
                      isLoading: isLoading,
                      progress: isLoading ? _downloadProgress : null,
                      onTap: () => _openBalade(balade),
                    ),
                  );
                }),
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
  final bool isLoading;
  final double? progress;
  final VoidCallback onTap;

  const _BaladeCard({
    required this.balade,
    required this.authToken,
    required this.isLoading,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        balade.description != null && balade.description!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
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
                      _buildCover(),
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
                                balade.nom,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                              child: const Text(
                                'Balade audio',
                                style: TextStyle(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: JorappColors.teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.headset_rounded,
                          size: 16,
                          color: JorappColors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expérience',
                              style: TextStyle(
                                fontSize: 11,
                                color: JorappColors.teal.withOpacity(0.72),
                              ),
                            ),
                            Text(
                              hasDescription
                                  ? balade.description!.trim()
                                  : 'Balade géolocalisée à télécharger et lancer sur place',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: JorappColors.ink,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: JorappColors.surfaceStrong,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: JorappColors.teal.withOpacity(0.18),
                            width: 0.5,
                          ),
                        ),
                        child: isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  value: progress == null || progress == 0
                                      ? null
                                      : progress,
                                  color: JorappColors.tealDark,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: JorappColors.teal,
                              ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  LinearProgressIndicator(
                    value: progress == null || progress == 0 ? null : progress,
                    minHeight: 5,
                    color: JorappColors.teal,
                    backgroundColor: JorappColors.surfaceStrong,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (balade.coverUrl == null) {
      return Container(
        color: JorappColors.tealDark,
        alignment: Alignment.center,
        child: const Icon(
          Icons.headset_rounded,
          color: Colors.white,
          size: 36,
        ),
      );
    }

    return Image.network(
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
    );
  }
}
