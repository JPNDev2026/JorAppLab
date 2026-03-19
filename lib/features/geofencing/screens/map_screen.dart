import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/router.dart';
import '../../../theme/jorapp_theme.dart';
import '../../auth/auth_service.dart';
import '../geofencing_controller.dart';
import '../models/location_sample.dart';
import '../widgets/layer_menu.dart';
import '../widgets/map_widget.dart';
import 'measurements_screen.dart';

class MapScreen extends StatefulWidget {
  final AuthService authService;
  final GeofencingController geofencingController;

  const MapScreen({
    super.key,
    required this.authService,
    required this.geofencingController,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  StreamSubscription<String>? _errorSubscription;
  LocationSample? _selectedSample;

  @override
  void initState() {
    super.initState();
    developer.log(
      '[MapScreen] initState loader=${GeofencingController.loaderVersion}',
    );
    unawaited(widget.geofencingController.bootstrapLayers());
    widget.geofencingController.addListener(_onControllerChanged);
    _errorSubscription = widget.geofencingController.errors.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });
  }

  @override
  void dispose() {
    widget.geofencingController.removeListener(_onControllerChanged);
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openMeasurements() async {
    final selectedSample = await Navigator.of(context).push<LocationSample>(
      MaterialPageRoute(
        builder: (_) => MeasurementsScreen(
          trackingController: widget.geofencingController.trackingController,
        ),
      ),
    );

    if (!mounted || selectedSample == null) return;
    setState(() {
      _selectedSample = selectedSample;
    });
  }

  String _locationStatusText() {
    final sample = widget.geofencingController.latestSample;
    if (sample == null) {
      return widget.geofencingController.isCollecting
          ? 'Collecte GPS en cours...'
          : 'Collecte GPS inactive';
    }

    final measuredAt = sample.measuredAtUtc.toLocal().toIso8601String();
    final accuracy = sample.accuracyMeters.toStringAsFixed(1);
    final lat = sample.latitude.toStringAsFixed(6);
    final lon = sample.longitude.toStringAsFixed(6);

    return 'Dernier point: $lat, $lon | precision $accuracy | ${sample.quality} | $measuredAt';
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LayerMenu(
        showPaths: widget.geofencingController.showPaths,
        showProtectedAreas: widget.geofencingController.showProtectedAreas,
        onTogglePaths: (bool value) {
          widget.geofencingController.togglePaths(value);
        },
        onToggleProtectedAreas: (bool value) {
          widget.geofencingController.toggleProtectedAreas(value);
        },
      ),
    );
  }

  Future<void> _openAudioGuide() async {
    if (!widget.authService.isLoggedIn) {
      await Navigator.pushNamed(
        context,
        AppRouter.login,
        arguments: AppRouter.audioGuide,
      );
      return;
    }

    await Navigator.pushNamed(context, AppRouter.audioGuide);
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      '[MapScreen] build showPaths=${widget.geofencingController.showPaths} '
      'showProtectedAreas=${widget.geofencingController.showProtectedAreas} '
      'paths=${widget.geofencingController.paths.length} '
      'polygons=${widget.geofencingController.protectedAreas.length}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'JORAPP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Parc du Jorat',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: JorappColors.surfaceStrong,
              foregroundColor: JorappColors.tealDark,
            ),
            icon: const Icon(Icons.headset_mic_rounded),
            tooltip: 'Audio-guide',
            onPressed: _openAudioGuide,
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: JorappColors.surfaceStrong,
              foregroundColor: JorappColors.tealDark,
            ),
            icon: const Icon(Icons.table_rows_rounded),
            onPressed: _openMeasurements,
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: JorappColors.surfaceStrong,
              foregroundColor: JorappColors.tealDark,
            ),
            icon: const Icon(Icons.layers_rounded),
            onPressed: _openMenu,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: MapWidget(
        paths: widget.geofencingController.paths,
        protectedAreas: widget.geofencingController.protectedAreas,
        recordedPoints: widget.geofencingController.samples
            .map((sample) => LatLng(sample.latitude, sample.longitude))
            .toList(),
        latestPoint: widget.geofencingController.latestSample == null
            ? null
            : LatLng(
                widget.geofencingController.latestSample!.latitude,
                widget.geofencingController.latestSample!.longitude,
              ),
        selectedPoint: _selectedSample == null
            ? null
            : LatLng(_selectedSample!.latitude, _selectedSample!.longitude),
        showPaths: widget.geofencingController.showPaths,
        showProtectedAreas: widget.geofencingController.showProtectedAreas,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [JorappColors.teal, JorappColors.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: JorappColors.lime.withOpacity(0.7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Mesures collectees: ${widget.geofencingController.samples.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _locationStatusText(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
