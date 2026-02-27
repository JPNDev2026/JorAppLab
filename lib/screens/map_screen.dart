import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/geojson_service.dart';
import '../models/location_sample.dart';
import '../services/tracking_controller.dart';
import 'measurements_screen.dart';
import '../widgets/map_widget.dart';
import '../widgets/layer_menu.dart';

class MapScreen extends StatefulWidget {
  final TrackingController trackingController;

  const MapScreen({super.key, required this.trackingController});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const String _loaderVersion = 'bundle-load-v3';
  static const String _protectedAreaAsset = 'assets/data/aire_protegee.geojson';
  static const String _pathsAsset = 'assets/data/chemins.geojson';

  // État des couches
  bool showPaths = false;
  bool showProtectedAreas = false;

  // Données cartographiques
  List<List<LatLng>> paths = [];
  List<List<LatLng>> protectedAreas = [];

  StreamSubscription<String>? _errorSubscription;
  LocationSample? _selectedSample;
  bool _isLoadingPaths = false;
  bool _isLoadingProtectedAreas = false;

  @override
  void initState() {
    super.initState();
    developer.log('[MapScreen] initState loader=$_loaderVersion');
    _bootstrapLayers();
    widget.trackingController.addListener(_onTrackingChanged);
    _errorSubscription = widget.trackingController.errors.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });
  }

  @override
  void dispose() {
    widget.trackingController.removeListener(_onTrackingChanged);
    _errorSubscription?.cancel();
    super.dispose();
  }

  // ─────────────────────────────
  // Chargement des chemins
  // ─────────────────────────────
  Future<void> _loadPaths() async {
    if (_isLoadingPaths) return;
    _isLoadingPaths = true;
    Object? lastError;

    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        developer.log('[MapScreen] _loadPaths attempt $attempt start: $_pathsAsset');
        try {
          final result = await GeoJsonService.loadPaths(_pathsAsset);

          if (result.isNotEmpty) {
            if (!mounted) return;
            setState(() {
              paths = result;
            });
            developer.log(
              '[MapScreen] _loadPaths success attempt $attempt: ${result.length} lignes',
            );
            return;
          }

          developer.log('[MapScreen] _loadPaths empty result attempt $attempt');
        } catch (e, st) {
          lastError = e;
          developer.log(
            '[MapScreen] _loadPaths error attempt $attempt: $e',
            stackTrace: st,
          );
        }

        await Future.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      _isLoadingPaths = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur chargement chemins: ${lastError ?? "aucune ligne chargée"}')),
    );
  }

  Future<void> _retryBothLayersIfNeeded() async {
    if (paths.isEmpty) {
      await _loadPaths();
    }
    if (protectedAreas.isEmpty) {
      await _loadProtectedAreas();
    }
  }

  // ─────────────────────────────
  // Chargement des zones protégées
  // ─────────────────────────────
  Future<void> _loadProtectedAreas() async {
    if (_isLoadingProtectedAreas) return;
    _isLoadingProtectedAreas = true;
    Object? lastError;

    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        developer.log(
          '[MapScreen] _loadProtectedAreas attempt $attempt start: $_protectedAreaAsset',
        );
        try {
          final result = await GeoJsonService.loadPolygons(_protectedAreaAsset);
          if (result.isNotEmpty) {
            if (!mounted) return;
            setState(() {
              protectedAreas = result;
            });
            developer.log(
              '[MapScreen] _loadProtectedAreas success attempt $attempt: ${result.length} polygones',
            );
            return;
          }
          developer.log(
            '[MapScreen] _loadProtectedAreas empty result attempt $attempt',
          );
        } catch (e, st) {
          lastError = e;
          developer.log(
            '[MapScreen] _loadProtectedAreas error attempt $attempt: $e',
            stackTrace: st,
          );
        }

        await Future.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      _isLoadingProtectedAreas = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erreur chargement aire protégée: ${lastError ?? "aucun polygone chargé"}',
        ),
      ),
    );
  }

  Future<void> _bootstrapLayers() async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      developer.log('[MapScreen] _bootstrapLayers attempt $attempt');
      await _retryBothLayersIfNeeded();

      if (!mounted) return;
      if (paths.isNotEmpty && protectedAreas.isNotEmpty) {
        developer.log(
          '[MapScreen] _bootstrapLayers loaded: paths=${paths.length}, polygons=${protectedAreas.length}',
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible de charger les couches locales.'),
      ),
    );
  }

  void _onTrackingChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openMeasurements() async {
    final selectedSample = await Navigator.of(context).push<LocationSample>(
      MaterialPageRoute(
        builder: (_) => MeasurementsScreen(
          trackingController: widget.trackingController,
        ),
      ),
    );

    if (!mounted || selectedSample == null) return;
    setState(() {
      _selectedSample = selectedSample;
    });
  }

  String _locationStatusText() {
    final sample = widget.trackingController.latestSample;
    if (sample == null) {
      return widget.trackingController.isCollecting
          ? 'Collecte GPS en cours...'
          : 'Collecte GPS inactive';
    }

    final measuredAt = sample.measuredAtUtc.toLocal().toIso8601String();
    final accuracy = sample.accuracyMeters.toStringAsFixed(1);
    final lat = sample.latitude.toStringAsFixed(6);
    final lon = sample.longitude.toStringAsFixed(6);

    return 'Dernier point: $lat, $lon | ±$accuracy m | ${sample.quality} | $measuredAt';
  }

  // ─────────────────────────────
  // Menu des couches
  // ─────────────────────────────
  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => LayerMenu(
        showPaths: showPaths,
        showProtectedAreas: showProtectedAreas,
        onTogglePaths: (bool value) {
          developer.log('[MapScreen] toggle paths: $value');
          if (value && paths.isEmpty) {
            _loadPaths();
          }
          setState(() {
            showPaths = value;
          });
        },
        onToggleProtectedAreas: (bool value) {
          developer.log('[MapScreen] toggle protected areas: $value');
          if (value && protectedAreas.isEmpty) {
            _loadProtectedAreas();
          }
          setState(() {
            showProtectedAreas = value;
          });
        },
      ),
    );
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    developer.log(
      '[MapScreen] build showPaths=$showPaths showProtectedAreas=$showProtectedAreas '
      'paths=${paths.length} polygons=${protectedAreas.length}',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte – Parc du Jorat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_rows),
            onPressed: _openMeasurements,
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _openMenu,
          ),
        ],
      ),
      body: MapWidget(
        paths: paths,
        protectedAreas: protectedAreas,
        recordedPoints: widget.trackingController.samples
            .map((sample) => LatLng(sample.latitude, sample.longitude))
            .toList(),
        latestPoint: widget.trackingController.latestSample == null
            ? null
            : LatLng(
                widget.trackingController.latestSample!.latitude,
                widget.trackingController.latestSample!.longitude,
              ),
        selectedPoint: _selectedSample == null
            ? null
            : LatLng(_selectedSample!.latitude, _selectedSample!.longitude),
        showPaths: showPaths,
        showProtectedAreas: showProtectedAreas,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_locationStatusText()}\nMesures collectees: ${widget.trackingController.samples.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
