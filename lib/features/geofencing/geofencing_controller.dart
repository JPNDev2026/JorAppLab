import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'models/location_sample.dart';
import 'services/geojson_service.dart';
import 'services/tracking_controller.dart';

class GeofencingController extends ChangeNotifier {
  static const String loaderVersion = 'bundle-load-v3';
  static const String protectedAreaAsset = 'assets/data/aire_protegee.geojson';
  static const String pathsAsset = 'assets/data/chemins.geojson';

  final TrackingController trackingController;
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _trackingErrorSubscription;
  bool _isLoadingPaths = false;
  bool _isLoadingProtectedAreas = false;

  bool showPaths = false;
  bool showProtectedAreas = false;
  List<List<LatLng>> paths = [];
  List<List<LatLng>> protectedAreas = [];

  GeofencingController({required this.trackingController}) {
    developer.log('[GeofencingController] init loader=$loaderVersion');
    trackingController.addListener(_onTrackingChanged);
    _trackingErrorSubscription = trackingController.errors.listen((error) {
      if (!_errorController.isClosed) {
        _errorController.add(error);
      }
    });
  }

  Stream<String> get errors => _errorController.stream;

  List<LocationSample> get samples => trackingController.samples;
  LocationSample? get latestSample => trackingController.latestSample;
  bool get isCollecting => trackingController.isCollecting;
  bool get useNetworkAssisted => trackingController.useNetworkAssisted;

  Future<void> setCollecting(bool enabled) async {
    await trackingController.setCollecting(enabled);
  }

  Future<void> setUseNetworkAssisted(bool enabled) async {
    await trackingController.setUseNetworkAssisted(enabled);
  }

  Future<void> bootstrapLayers() async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      developer.log('[GeofencingController] _bootstrapLayers attempt $attempt');
      await _retryBothLayersIfNeeded();

      if (paths.isNotEmpty && protectedAreas.isNotEmpty) {
        developer.log(
          '[GeofencingController] _bootstrapLayers loaded: '
          'paths=${paths.length}, polygons=${protectedAreas.length}',
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    _emitError('Impossible de charger les couches locales.');
  }

  Future<void> _retryBothLayersIfNeeded() async {
    if (paths.isEmpty) {
      await _loadPaths();
    }
    if (protectedAreas.isEmpty) {
      await _loadProtectedAreas();
    }
  }

  Future<void> _loadPaths() async {
    if (_isLoadingPaths) return;
    _isLoadingPaths = true;
    Object? lastError;

    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        developer.log(
          '[GeofencingController] _loadPaths attempt $attempt start: $pathsAsset',
        );
        try {
          final result = await GeoJsonService.loadPaths(pathsAsset);

          if (result.isNotEmpty) {
            paths = result;
            notifyListeners();
            developer.log(
              '[GeofencingController] _loadPaths success attempt $attempt: '
              '${result.length} lignes',
            );
            return;
          }

          developer.log(
            '[GeofencingController] _loadPaths empty result attempt $attempt',
          );
        } catch (e, st) {
          lastError = e;
          developer.log(
            '[GeofencingController] _loadPaths error attempt $attempt: $e',
            stackTrace: st,
          );
        }

        await Future.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      _isLoadingPaths = false;
    }

    _emitError('Erreur chargement chemins: ${lastError ?? "aucune ligne chargée"}');
  }

  Future<void> _loadProtectedAreas() async {
    if (_isLoadingProtectedAreas) return;
    _isLoadingProtectedAreas = true;
    Object? lastError;

    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        developer.log(
          '[GeofencingController] _loadProtectedAreas attempt $attempt start: '
          '$protectedAreaAsset',
        );
        try {
          final result = await GeoJsonService.loadPolygons(protectedAreaAsset);
          if (result.isNotEmpty) {
            protectedAreas = result;
            notifyListeners();
            developer.log(
              '[GeofencingController] _loadProtectedAreas success attempt '
              '$attempt: ${result.length} polygones',
            );
            return;
          }
          developer.log(
            '[GeofencingController] _loadProtectedAreas empty result attempt '
            '$attempt',
          );
        } catch (e, st) {
          lastError = e;
          developer.log(
            '[GeofencingController] _loadProtectedAreas error attempt '
            '$attempt: $e',
            stackTrace: st,
          );
        }

        await Future.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      _isLoadingProtectedAreas = false;
    }

    _emitError(
      'Erreur chargement aire protégée: '
      '${lastError ?? "aucun polygone chargé"}',
    );
  }

  void togglePaths(bool value) {
    developer.log('[GeofencingController] toggle paths: $value');
    if (value && paths.isEmpty) {
      unawaited(_loadPaths());
    }
    showPaths = value;
    notifyListeners();
  }

  void toggleProtectedAreas(bool value) {
    developer.log('[GeofencingController] toggle protected areas: $value');
    if (value && protectedAreas.isEmpty) {
      unawaited(_loadProtectedAreas());
    }
    showProtectedAreas = value;
    notifyListeners();
  }

  void _onTrackingChanged() {
    notifyListeners();
  }

  void _emitError(String message) {
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }

  @override
  void dispose() {
    trackingController.removeListener(_onTrackingChanged);
    _trackingErrorSubscription?.cancel();
    _errorController.close();
    super.dispose();
  }
}
