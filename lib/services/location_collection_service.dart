import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/location_sample.dart';

class LocationCollectionService {
  final Duration interval;
  final Duration fixWindow;
  final double excellentAccuracyThresholdMeters;

  LocationCollectionService({
    this.interval = const Duration(minutes: 1),
    this.fixWindow = const Duration(seconds: 20),
    this.excellentAccuracyThresholdMeters = 6,
  });

  final StreamController<LocationSample> _sampleController =
      StreamController<LocationSample>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<LocationSample> get samples => _sampleController.stream;
  Stream<String> get errors => _errorController.stream;

  Timer? _timer;
  bool _isCollecting = false;

  Future<bool> start() async {
    if (_timer != null) return true;

    final ready = await _ensureLocationReady();
    if (!ready) return false;

    await _collectOnce();
    _timer = Timer.periodic(interval, (_) {
      _collectOnce();
    });

    return true;
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _collectOnce() async {
    if (_isCollecting) return;
    _isCollecting = true;

    try {
      final sample = await _collectBestSampleWithinWindow();
      _sampleController.add(sample);
    } catch (e) {
      _errorController.add('Echec collecte GPS: $e');
    } finally {
      _isCollecting = false;
    }
  }

  Future<LocationSample> _collectBestSampleWithinWindow() async {
    Position? best;
    final completer = Completer<Position?>();

    void completeIfNeeded([Position? position]) {
      if (!completer.isCompleted) {
        completer.complete(position);
      }
    }

    final subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(
      (position) {
        if (best == null || position.accuracy < best!.accuracy) {
          best = position;
        }

        if (position.accuracy <= excellentAccuracyThresholdMeters) {
          completeIfNeeded(position);
        }
      },
      onError: (_) {
        completeIfNeeded(best);
      },
    );

    final windowTimer = Timer(fixWindow, () {
      completeIfNeeded(best);
    });

    Position? selected = await completer.future;

    windowTimer.cancel();
    await subscription.cancel();

    selected ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
      timeLimit: const Duration(seconds: 10),
    );

    final measuredAt = DateTime.now().toUtc();

    return LocationSample(
      measuredAtUtc: measuredAt,
      latitude: selected.latitude,
      longitude: selected.longitude,
      accuracyMeters: selected.accuracy,
      altitudeMeters: selected.altitude,
      speedMps: selected.speed,
      headingDegrees: selected.heading,
      isMocked: selected.isMocked,
    );
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

    return true;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _sampleController.close();
    _errorController.close();
  }
}
