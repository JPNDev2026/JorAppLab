import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_sample.dart';

class LocationCollectionService {
  static const MethodChannel _networkChannel = MethodChannel('jorat/network');

  final Duration interval;
  final Duration fixWindow;
  bool _useNetworkAssisted;

  LocationCollectionService({
    this.interval = const Duration(minutes: 1),
    this.fixWindow = const Duration(seconds: 20),
    bool useNetworkAssisted = true,
  }) : _useNetworkAssisted = useNetworkAssisted;

  final StreamController<LocationSample> _sampleController =
      StreamController<LocationSample>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<LocationSample> get samples => _sampleController.stream;
  Stream<String> get errors => _errorController.stream;
  bool get useNetworkAssisted => _useNetworkAssisted;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _samplingTimer;
  Timer? _windowTimer;

  final List<Position> _windowPositions = <Position>[];
  Position? _latestPosition;

  bool _windowOpen = false;
  bool _isEmittingSample = false;

  Future<bool> setUseNetworkAssisted(bool enabled) async {
    if (_useNetworkAssisted == enabled) return true;

    _useNetworkAssisted = enabled;
    developer.log(
      '[LocationCollectionService] mode changed: '
      '${_useNetworkAssisted ? "network-assisted" : "gps-only"}',
    );

    final wasRunning = _positionSubscription != null;
    if (!wasRunning) return true;

    await stop();
    return start();
  }

  Future<bool> start() async {
    if (_positionSubscription != null) return true;

    final ready = await _ensureLocationReady();
    if (!ready) return false;

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _streamLocationSettings(),
      ).listen(
        (position) {
          _latestPosition = position;
          if (_windowOpen) {
            _windowPositions.add(position);
          }
        },
        onError: (error) {
          _errorController.add('Flux GPS interrompu: $error');
        },
      );

      developer.log(
        '[LocationCollectionService] stream started '
        'interval=$interval window=$fixWindow mode='
        '${_useNetworkAssisted ? "network-assisted" : "gps-only"}',
      );

      _openSamplingWindow();
      _samplingTimer = Timer.periodic(interval, (_) {
        _openSamplingWindow();
      });

      return true;
    } catch (e) {
      _errorController.add('Impossible de demarrer le suivi GPS: $e');
      await stop();
      return false;
    }
  }

  Future<void> stop() async {
    _samplingTimer?.cancel();
    _samplingTimer = null;

    _windowTimer?.cancel();
    _windowTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _windowPositions.clear();
    _latestPosition = null;
    _windowOpen = false;
    _isEmittingSample = false;

    developer.log('[LocationCollectionService] stream stopped');
  }

  void _openSamplingWindow() {
    if (_windowOpen || _isEmittingSample) {
      return;
    }

    _windowOpen = true;
    _windowPositions.clear();

    developer.log(
      '[LocationCollectionService] sampling window open for ${fixWindow.inSeconds}s',
    );

    _windowTimer?.cancel();
    _windowTimer = Timer(fixWindow, () {
      unawaited(_closeSamplingWindowAndEmit());
    });
  }

  Future<void> _closeSamplingWindowAndEmit() async {
    if (!_windowOpen) return;

    _windowOpen = false;
    _windowTimer?.cancel();
    _windowTimer = null;

    if (_isEmittingSample) return;
    _isEmittingSample = true;

    try {
      Position? selected = _bestAccuracyPosition(_windowPositions);
      selected ??= _latestPosition;

      selected ??= await Geolocator.getCurrentPosition(
        locationSettings: _currentLocationSettings(),
        timeLimit: const Duration(seconds: 15),
      );

      final measuredAt = DateTime.now().toUtc();
      final networkSnapshot = await _readNetworkSnapshot();
      final usedNetworkAssisted = _useNetworkAssisted;

      _sampleController.add(
        LocationSample(
          measuredAtUtc: measuredAt,
          latitude: selected.latitude,
          longitude: selected.longitude,
          accuracyMeters: selected.accuracy,
          altitudeMeters: selected.altitude,
          speedMps: selected.speed,
          headingDegrees: selected.heading,
          isMocked: selected.isMocked,
          wasNetworkAvailable: networkSnapshot.available,
          usedNetworkAssisted: usedNetworkAssisted,
          networkType: networkSnapshot.type,
        ),
      );

      developer.log(
        '[LocationCollectionService] sample emitted '
        'lat=${selected.latitude}, lon=${selected.longitude}, '
        'acc=${selected.accuracy}, points=${_windowPositions.length}, '
        'net=${networkSnapshot.available}, netType=${networkSnapshot.type}, '
        'assisted=$usedNetworkAssisted',
      );
    } catch (e) {
      _errorController.add('Echec collecte GPS: $e');
    } finally {
      _windowPositions.clear();
      _isEmittingSample = false;
    }
  }

  Position? _bestAccuracyPosition(List<Position> positions) {
    if (positions.isEmpty) return null;

    Position best = positions.first;
    for (final position in positions.skip(1)) {
      if (position.accuracy < best.accuracy) {
        best = position;
      }
    }
    return best;
  }

  LocationSettings _streamLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: _useNetworkAssisted
              ? LocationAccuracy.high
              : LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
          forceLocationManager: !_useNetworkAssisted,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Collecte GPS active',
            notificationText: 'Mesures en cours en arriere-plan',
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        );
    }
  }

  LocationSettings _currentLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(accuracy: LocationAccuracy.best);
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: _useNetworkAssisted
              ? LocationAccuracy.high
              : LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          forceLocationManager: !_useNetworkAssisted,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Collecte GPS active',
            notificationText: 'Mesures en cours en arriere-plan',
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return const LocationSettings(accuracy: LocationAccuracy.best);
    }
  }

  Future<_NetworkSnapshot> _readNetworkSnapshot() async {
    try {
      final dynamic raw = await Connectivity().checkConnectivity();
      final List<ConnectivityResult> values;

      if (raw is ConnectivityResult) {
        values = [raw];
      } else if (raw is List) {
        values = raw.whereType<ConnectivityResult>().toList();
      } else {
        values = const [];
      }

      if (values.isEmpty || values.contains(ConnectivityResult.none)) {
        return const _NetworkSnapshot(available: false, type: 'none');
      }

      if (values.contains(ConnectivityResult.wifi)) {
        return const _NetworkSnapshot(available: true, type: 'wifi');
      }

      if (values.contains(ConnectivityResult.ethernet)) {
        return const _NetworkSnapshot(available: true, type: 'ethernet');
      }

      if (values.contains(ConnectivityResult.mobile)) {
        final mobileType = await _readMobileGeneration();
        return _NetworkSnapshot(available: true, type: mobileType);
      }

      return const _NetworkSnapshot(available: true, type: 'other');
    } catch (_) {
      return const _NetworkSnapshot(available: false, type: 'unknown');
    }
  }

  Future<String> _readMobileGeneration() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'mobile';
    }

    try {
      final result = await _networkChannel.invokeMethod<String>('getNetworkType');
      if (result == null || result.isEmpty) return 'mobile';
      return result.toLowerCase();
    } on PlatformException {
      return 'mobile';
    }
  }

  Future<bool> _ensureLocationReady() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _errorController.add('Service de localisation desactive.');
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _errorController.add('Permission de localisation refusee.');
      return false;
    }

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        permission == LocationPermission.whileInUse) {
      final upgradedPermission = await Geolocator.requestPermission();
      if (upgradedPermission != LocationPermission.denied &&
          upgradedPermission != LocationPermission.deniedForever) {
        permission = upgradedPermission;
      }
      _errorController.add(
        'Permission en arriere-plan recommandee: Android > App > Autorisations > Localisation > Toujours autoriser.',
      );
    }

    return true;
  }

  void dispose() {
    unawaited(stop());
    _sampleController.close();
    _errorController.close();
  }
}

class _NetworkSnapshot {
  final bool available;
  final String type;

  const _NetworkSnapshot({
    required this.available,
    required this.type,
  });
}
