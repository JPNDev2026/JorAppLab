import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/jorapp_theme.dart';
import '../../geofencing/geofencing_controller.dart';
import '../models/audio_point.dart';
import '../models/balade.dart';
import '../services/audio_guide_player_service.dart';

class AudioGuideBaladeScreen extends StatefulWidget {
  final Balade balade;
  final List<AudioPoint> points;
  final GeofencingController geofencingController;

  const AudioGuideBaladeScreen({
    super.key,
    required this.balade,
    required this.points,
    required this.geofencingController,
  });

  @override
  State<AudioGuideBaladeScreen> createState() => _AudioGuideBaladeScreenState();
}

class _AudioGuideBaladeScreenState extends State<AudioGuideBaladeScreen>
    with WidgetsBindingObserver {
  static const Distance _distance = Distance();
  final AudioGuidePlayerService _playerService = AudioGuidePlayerService();
  DateTime? _lastEvaluatedSampleAt;
  bool _isCheckingZone = false;
  bool _autoPlaySuppressedUntilNextSample = false;
  Set<String> _insideZoneIds = <String>{};
  StreamSubscription<String>? _errorSubscription;
  bool _isLocationPromptVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      widget.geofencingController.trackingController.initialize(
        autoStart: true,
      ),
    );
    widget.geofencingController.addListener(_onControllerChanged);
    _playerService.addListener(_onPlayerChanged);
    _errorSubscription = widget.geofencingController.errors.listen((error) {
      _handleError(error);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkZonesForPlayback());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.geofencingController.removeListener(_onControllerChanged);
    _playerService.removeListener(_onPlayerChanged);
    _errorSubscription?.cancel();
    _playerService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureTrackingActive());
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    unawaited(_checkZonesForPlayback());
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_playerService.hasActiveTrack) {
      unawaited(_checkZonesForPlayback());
    }
  }

  Future<void> _ensureTrackingActive() async {
    await widget.geofencingController.trackingController.initialize(
      autoStart: true,
    );
    if (!widget.geofencingController.isCollecting) {
      await widget.geofencingController.trackingController.setCollecting(true);
    }
  }

  void _handleError(String error) {
    if (!mounted) return;
    if (_isLocationServiceDisabledError(error)) {
      _showLocationSettingsPrompt(error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  bool _isLocationServiceDisabledError(String error) {
    return error.toLowerCase().contains('service de localisation desactive');
  }

  void _showLocationSettingsPrompt(String error) {
    if (_isLocationPromptVisible) return;
    _isLocationPromptVisible = true;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Activer le GPS',
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          ),
        )
        .closed
        .whenComplete(() {
          _isLocationPromptVisible = false;
        });
  }

  LatLng _initialCenter() {
    final latest = widget.geofencingController.latestSample;
    if (widget.points.isEmpty) {
      if (latest != null) {
        return LatLng(latest.latitude, latest.longitude);
      }
      return const LatLng(46.58, 6.67);
    }

    var latSum = 0.0;
    var lngSum = 0.0;
    for (final point in widget.points) {
      latSum += point.latCentre;
      lngSum += point.lngCentre;
    }
    return LatLng(
      latSum / widget.points.length,
      lngSum / widget.points.length,
    );
  }

  List<LatLng> _buildRadiusPolygon(AudioPoint point) {
    const segments = 48;
    return List<LatLng>.generate(segments, (index) {
      final bearing = 360 * (index / segments);
      return _distance.offset(
        LatLng(point.latCentre, point.lngCentre),
        point.rayonMetres,
        bearing,
      );
    });
  }

  Future<void> _checkZonesForPlayback() async {
    if (_isCheckingZone) return;

    final latestSample = widget.geofencingController.latestSample;
    if (latestSample == null) return;

    _isCheckingZone = true;
    try {
      final isNewSample = _lastEvaluatedSampleAt != latestSample.measuredAtUtc;
      _lastEvaluatedSampleAt = latestSample.measuredAtUtc;
      if (isNewSample) {
        _autoPlaySuppressedUntilNextSample = false;
      }

      final currentPosition = LatLng(
        latestSample.latitude,
        latestSample.longitude,
      );

      final insideZoneIds = <String>{};
      for (final point in widget.points) {
        final distanceMeters = _distance.as(
          LengthUnit.Meter,
          currentPosition,
          LatLng(point.latCentre, point.lngCentre),
        );
        if (distanceMeters <= point.rayonMetres) {
          insideZoneIds.add(point.id);
        }
      }
      _insideZoneIds = insideZoneIds;

      if (_autoPlaySuppressedUntilNextSample || _playerService.hasActiveTrack) {
        return;
      }

      AudioPoint? pointToPlay;
      for (final point in widget.points) {
        if (_playerService.hasPlayed(point.id)) continue;
        if (_insideZoneIds.contains(point.id)) {
          pointToPlay = point;
          break;
        }
      }

      if (pointToPlay == null) return;

      await _playerService.playPoint(pointToPlay);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lecture audio: ${pointToPlay.titre}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lecture audio impossible: $error')),
      );
    } finally {
      _isCheckingZone = false;
    }
  }

  Future<void> _playPointManually(AudioPoint point) async {
    try {
      await _playerService.playPoint(point);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lecture audio: ${point.titre}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lecture audio impossible: $error')),
      );
    }
  }

  Future<void> _pauseAudio() async {
    await _playerService.pause();
  }

  Future<void> _stopAudio() async {
    _autoPlaySuppressedUntilNextSample = true;
    await _playerService.stop();
  }

  @override
  Widget build(BuildContext context) {
    final latestSample = widget.geofencingController.latestSample;
    final latestPoint = latestSample == null
        ? null
        : LatLng(latestSample.latitude, latestSample.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.balade.nom),
            Text(
              '${widget.points.length} point(s) audio',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF50616A),
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
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FlutterMap(
                    options: MapOptions(
                      center: _initialCenter(),
                      zoom: 15,
                      rotation: 0,
                      interactiveFlags:
                          InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'ch.jorat.geofence',
                      ),
                      PolygonLayer(
                        polygons: widget.points
                            .map(
                              (point) => Polygon(
                                points: _buildRadiusPolygon(point),
                                borderColor: JorappColors.tealDark,
                                borderStrokeWidth: 2,
                                color: JorappColors.lime.withOpacity(0.22),
                                isFilled: true,
                              ),
                            )
                            .toList(),
                      ),
                      MarkerLayer(
                        markers: widget.points
                            .map(
                              (point) => Marker(
                                point: LatLng(point.latCentre, point.lngCentre),
                                width: 54,
                                height: 54,
                                child: GestureDetector(
                                  onTap: () {
                                    unawaited(_playPointManually(point));
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: JorappColors.tealDark,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: JorappColors.lime,
                                            width: 2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x22000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.headphones_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (latestPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latestPoint,
                              width: 34,
                              height: 34,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: JorappColors.lime.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: JorappColors.lime,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                    color: JorappColors.tealDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _AudioGuideStatusCard(
                pointCount: widget.points.length,
                currentTitle: _playerService.currentTitle,
                isPlaying: _playerService.isPlaying,
                isPaused: _playerService.isPaused,
                hasActiveTrack: _playerService.hasActiveTrack,
                playedCount: _playerService.playedPointIds.length,
                onPause: _pauseAudio,
                onStop: _stopAudio,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioGuideStatusCard extends StatelessWidget {
  final int pointCount;
  final String? currentTitle;
  final bool isPlaying;
  final bool isPaused;
  final bool hasActiveTrack;
  final int playedCount;
  final Future<void> Function() onPause;
  final Future<void> Function() onStop;

  const _AudioGuideStatusCard({
    required this.pointCount,
    required this.currentTitle,
    required this.isPlaying,
    required this.isPaused,
    required this.hasActiveTrack,
    required this.playedCount,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final playbackText = currentTitle == null
        ? 'Rendez-vous dans une zone audio pour lancer la lecture.'
        : isPlaying
            ? 'Lecture en cours: $currentTitle'
            : isPaused
                ? 'Lecture en pause: $currentTitle'
                : 'Audio sélectionné: $currentTitle';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [JorappColors.teal, JorappColors.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: JorappColors.lime.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$pointCount zone(s) audio prêtes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            playbackText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (hasActiveTrack) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: isPlaying ? onPause : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.16),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.pause_rounded),
                  label: const Text('Pause'),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: onStop,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.16),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                ),
                const Spacer(),
                Text(
                  'Lus: $playedCount / $pointCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Lus: $playedCount / $pointCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
