import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/location_sample.dart';
import 'location_collection_service.dart';

class TrackingController extends ChangeNotifier {
  final LocationCollectionService _locationService;
  final List<LocationSample> _samples = [];
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  StreamSubscription<LocationSample>? _sampleSubscription;
  StreamSubscription<String>? _errorSubscription;

  bool _isCollecting = false;
  bool _initialized = false;

  TrackingController({LocationCollectionService? locationService})
      : _locationService = locationService ?? LocationCollectionService();

  List<LocationSample> get samples => List.unmodifiable(_samples);
  LocationSample? get latestSample => _samples.isEmpty ? null : _samples.last;
  bool get isCollecting => _isCollecting;
  Stream<String> get errors => _errorController.stream;

  Future<void> initialize({bool autoStart = true}) async {
    if (_initialized) return;
    _initialized = true;

    _sampleSubscription = _locationService.samples.listen((sample) {
      _samples.add(sample);
      notifyListeners();
    });

    _errorSubscription = _locationService.errors.listen((error) {
      _errorController.add(error);
    });

    if (autoStart) {
      await start();
    }
  }

  Future<void> start() async {
    if (_isCollecting) return;
    _isCollecting = await _locationService.start();
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_isCollecting) return;
    await _locationService.stop();
    _isCollecting = false;
    notifyListeners();
  }

  Future<void> setCollecting(bool enabled) async {
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }

  @override
  void dispose() {
    _sampleSubscription?.cancel();
    _errorSubscription?.cancel();
    _errorController.close();
    _locationService.dispose();
    super.dispose();
  }
}
