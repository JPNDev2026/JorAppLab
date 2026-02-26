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
  // État des couches
  bool showPaths = false;
  bool showProtectedAreas = false;

  // Données cartographiques
  List<List<LatLng>> paths = [];
  List<List<LatLng>> protectedAreas = [];

  StreamSubscription<String>? _errorSubscription;
  LocationSample? _selectedSample;

  @override
  void initState() {
    super.initState();
    developer.log('[MapScreen] initState');
    _loadPaths();
    _loadProtectedAreas();
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
    const path = 'assets/data/chemins.geojson';
    developer.log('[MapScreen] _loadPaths start: $path');
    try {
      final result = await GeoJsonService.loadPaths(path);
      if (!mounted) return;
      setState(() {
        paths = result;
      });
      developer.log('[MapScreen] _loadPaths done: ${result.length} lignes');
    } catch (e, st) {
      developer.log('[MapScreen] _loadPaths error: $e', stackTrace: st);
      rethrow;
    }
  }

  // ─────────────────────────────
  // Chargement des zones protégées
  // ─────────────────────────────
  Future<void> _loadProtectedAreas() async {
    const path = 'assets/data/aire_protegee.geojson';
    developer.log('[MapScreen] _loadProtectedAreas start: $path');
    try {
      final result = await GeoJsonService.loadPolygons(path);
      if (!mounted) return;
      setState(() {
        protectedAreas = result;
      });
      developer.log(
        '[MapScreen] _loadProtectedAreas done: ${result.length} polygones',
      );
    } catch (e, st) {
      developer.log('[MapScreen] _loadProtectedAreas error: $e', stackTrace: st);
      rethrow;
    }
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
          setState(() {
            showPaths = value;
          });
        },
        onToggleProtectedAreas: (bool value) {
          developer.log('[MapScreen] toggle protected areas: $value');
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
