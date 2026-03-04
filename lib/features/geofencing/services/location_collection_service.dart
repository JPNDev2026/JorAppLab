import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_sample.dart';
import '../models/network_measurement.dart';

class LocationCollectionService {
  static const MethodChannel _networkChannel = MethodChannel('jorat/network');
  static const List<String> _tcpProbeHosts = ['8.8.8.8', '1.1.1.1', '9.9.9.9'];
  static const List<String> _downlinkProbeUrls = [
    'https://speed.cloudflare.com/__down?bytes=50000',
    'https://proof.ovh.net/files/100Kb.dat',
  ];
  static const int _downlinkProbeTargetBytes = 50 * 1024;

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
      final networkSnapshotFuture = _readNetworkSnapshot();
      final networkMeasurementFuture = _readNetworkMeasurement();
      final networkSnapshot = await networkSnapshotFuture;
      final networkMeasurement = await networkMeasurementFuture;
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
          networkMeasurement: networkMeasurement,
        ),
      );

      developer.log(
        '[LocationCollectionService] sample emitted '
        'lat=${selected.latitude}, lon=${selected.longitude}, '
        'acc=${selected.accuracy}, points=${_windowPositions.length}, '
        'net=${networkSnapshot.available}, netType=${networkSnapshot.type}, '
        'radio=${networkMeasurement?.declaredNetworkType}, '
        'dbm=${networkMeasurement?.signalDbm}, '
        'voice=${networkMeasurement?.voiceCapable}, '
        'tcp=${networkMeasurement?.tcpLatencyMedianMs}, '
        'down=${networkMeasurement?.downlinkKbps}, '
        'usage=${networkMeasurement?.usageLabel}, '
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

  Future<NetworkMeasurement?> _readNetworkMeasurement() async {
    final radioFuture = _readRadioSnapshot();
    final tcpFuture = _probeTcpLatencyMedianMs();
    final downlinkFuture = _probeDownlinkKbps();

    final radio = await radioFuture;
    final tcpLatency = await tcpFuture;
    final downlink = await downlinkFuture;

    if (radio == null && tcpLatency == null && downlink == null) {
      return null;
    }

    final declaredType = radio?.declaredNetworkType ?? 'unknown';
    final signalDbm = radio?.signalDbm;
    final voiceCapable = radio?.voiceCapable;

    return NetworkMeasurement(
      declaredNetworkType: declaredType,
      signalDbm: signalDbm,
      voiceCapable: voiceCapable,
      tcpLatencyMedianMs: tcpLatency,
      downlinkKbps: downlink,
      usageLevel: NetworkMeasurement.deriveUsageLevel(
        declaredNetworkType: declaredType,
        voiceCapable: voiceCapable,
        tcpLatencyMedianMs: tcpLatency,
        downlinkKbps: downlink,
      ),
    );
  }

  Future<_RadioSnapshot?> _readRadioSnapshot() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final result = await _networkChannel.invokeMapMethod<String, dynamic>(
        'getRadioSnapshot',
      );
      if (result == null) return null;

      final declaredType =
          (result['declaredNetworkType'] as String? ?? 'unknown').toLowerCase();

      final signalDbm = _toIntOrNull(result['signalDbm']);
      final voiceCapable = result['voiceCapable'] as bool?;

      return _RadioSnapshot(
        declaredNetworkType: declaredType,
        signalDbm: signalDbm,
        voiceCapable: voiceCapable,
      );
    } on PlatformException {
      return null;
    }
  }

  Future<double?> _probeTcpLatencyMedianMs() async {
    final futures = _tcpProbeHosts
        .map(
          (host) => _probeTcpHostLatencyMs(
            host: host,
            port: 53,
            timeout: const Duration(seconds: 2),
          ),
        )
        .toList();

    final samples = await Future.wait<double?>(futures);
    final valid = samples.whereType<double>().toList()..sort();
    if (valid.isEmpty) return null;
    return _median(valid);
  }

  Future<double?> _probeTcpHostLatencyMs({
    required String host,
    required int port,
    required Duration timeout,
  }) async {
    Socket? socket;
    final stopwatch = Stopwatch()..start();
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / 1000.0;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  Future<double?> _probeDownlinkKbps() async {
    for (final url in _downlinkProbeUrls) {
      final kbps = await _measureDownlinkKbps(
        url: url,
        timeout: const Duration(seconds: 4),
        targetBytes: _downlinkProbeTargetBytes,
      );
      if (kbps != null) return kbps;
    }
    return null;
  }

  Future<double?> _measureDownlinkKbps({
    required String url,
    required Duration timeout,
    required int targetBytes,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..idleTimeout = timeout;

    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      request.headers.set(HttpHeaders.pragmaHeader, 'no-cache');
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      request.headers.set(
        HttpHeaders.rangeHeader,
        'bytes=0-${targetBytes - 1}',
      );

      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      var received = 0;
      final transferStopwatch = Stopwatch();
      await for (final chunk in response.timeout(timeout)) {
        if (!transferStopwatch.isRunning) {
          transferStopwatch.start();
        }
        received += chunk.length;
        if (received >= targetBytes) {
          break;
        }
      }
      if (transferStopwatch.isRunning) {
        transferStopwatch.stop();
      }

      if (received <= 0) return null;
      final seconds = transferStopwatch.elapsedMicroseconds / 1000000.0;
      if (seconds <= 0) return null;

      final kbps = (received * 8.0) / 1000.0 / seconds;
      if (kbps.isNaN || kbps.isInfinite) return null;
      developer.log(
        '[LocationCollectionService] downlink probe url=$url bytes=$received '
        'seconds=$seconds kbps=$kbps',
      );
      return kbps;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  double _median(List<double> sortedValues) {
    if (sortedValues.isEmpty) return 0;
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) {
      return sortedValues[middle];
    }
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2.0;
  }

  int? _toIntOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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

class _RadioSnapshot {
  final String declaredNetworkType;
  final int? signalDbm;
  final bool? voiceCapable;

  const _RadioSnapshot({
    required this.declaredNetworkType,
    required this.signalDbm,
    required this.voiceCapable,
  });
}
