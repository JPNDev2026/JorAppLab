import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/pb_client.dart';
import '../models/field_recording.dart';
import 'stories_local_datasource.dart';

// ── Erreurs métier ────────────────────────────────────────────────────────────

class AuthException implements Exception {
  const AuthException();
  @override
  String toString() => 'Vous devez être connecté pour enregistrer.';
}

enum RecordingError {
  micPermissionDenied,
  locationPermissionDenied,
  locationServiceDisabled,
  locationUnavailable,
  storageError;

  @override
  String toString() => switch (this) {
    RecordingError.micPermissionDenied =>
      'Permission microphone refusée. Autorisez l\'accès dans les réglages.',
    RecordingError.locationPermissionDenied =>
      'Permission localisation refusée. Autorisez l\'accès dans les réglages.',
    RecordingError.locationServiceDisabled =>
      'Les services de localisation sont désactivés. Activez-les dans Réglages → Confidentialité et sécurité → Service de localisation.',
    RecordingError.locationUnavailable =>
      'Position GPS indisponible. Activez le GPS et réessayez.',
    RecordingError.storageError =>
      'Stockage insuffisant pour démarrer l\'enregistrement.',
  };
}

class RecordingException implements Exception {
  final RecordingError error;
  const RecordingException(this.error);
  @override
  String toString() => error.toString();
}

// ── Config ────────────────────────────────────────────────────────────────────

class AppConfig {
  static const int maxRecordingDurationSeconds = 180;
}

// ── État ──────────────────────────────────────────────────────────────────────

enum RecordingState { idle, requestingPermission, recording, stopping }

// ── Service ───────────────────────────────────────────────────────────────────

class RecordingService extends ChangeNotifier {
  final StoriesLocalDatasource datasource;

  RecordingService({required this.datasource});

  final AudioRecorder _recorder = AudioRecorder();
  final _elapsedController = StreamController<Duration>.broadcast();

  RecordingState _state = RecordingState.idle;
  double? _currentLatitude;
  double? _currentLongitude;

  // Données intermédiaires conservées entre start et stop.
  String? _currentFilePath;
  double? _recordingLatitude;
  double? _recordingLongitude;
  DateTime? _recordingStartedAt;
  Timer? _maxDurationTimer;
  Timer? _chronoTimer;

  // ── Lecture d'état ───────────────────────────────────────────────────────────

  RecordingState get state => _state;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;

  /// Stream du chronomètre, émis chaque seconde pendant l'enregistrement.
  Stream<Duration> get elapsedTime => _elapsedController.stream;

  // ── startRecording ───────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (_state != RecordingState.idle) return;

    // 1. Auth
    final pb = PbClient.instance.pb;
    if (!pb.authStore.isValid) {
      throw const AuthException();
    }

    _setState(RecordingState.requestingPermission);

    try {
      // 2. Permissions
      await _ensureMicPermission();
      await _ensureLocationPermission();

      // 3. Position GPS
      final position = await LocationService.instance.getCurrentPosition();
      if (position == null) {
        throw const RecordingException(RecordingError.locationUnavailable);
      }

      // 4. Chemin fichier
      final uuid = const Uuid().v4();
      final filePath = await _buildFilePath(uuid);

      developer.log('[RecordingService] startRecording path=$filePath '
          'lat=${position.latitude} lon=${position.longitude}');

      // 5. Lancement enregistrement
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      // Mémoriser les données pour stopRecording
      _currentFilePath = filePath;
      _recordingLatitude = position.latitude;
      _recordingLongitude = position.longitude;
      _recordingStartedAt = DateTime.now();
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // 6. Timer durée max
      _maxDurationTimer = Timer(
        Duration(seconds: AppConfig.maxRecordingDurationSeconds),
        () {
          developer.log('[RecordingService] durée max atteinte, arrêt auto');
          unawaited(stopRecording());
        },
      );

      // 7. Chronomètre
      final startedAt = _recordingStartedAt!;
      _chronoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final elapsed = DateTime.now().difference(startedAt);
        _elapsedController.add(elapsed);
      });

      // 8. État
      _setState(RecordingState.recording);
    } catch (_) {
      _setState(RecordingState.idle);
      rethrow;
    }
  }

  // ── stopRecording ────────────────────────────────────────────────────────────

  Future<FieldRecording> stopRecording() async {
    if (_state != RecordingState.recording) {
      throw StateError('stopRecording() appelé hors état recording');
    }

    _setState(RecordingState.stopping);

    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _chronoTimer?.cancel();
    _chronoTimer = null;

    try {
      // 1. Arrêt enregistrement
      await _recorder.stop();

      // 2. Durée réelle
      final startedAt = _recordingStartedAt ?? DateTime.now();
      final durationSeconds = DateTime.now().difference(startedAt).inSeconds;

      // 3. Identité utilisateur
      final pb = PbClient.instance.pb;
      final userId = (pb.authStore.record?.id ?? '');
      final userEmail = (pb.authStore.record?.getStringValue('email') ?? '');

      // 4. Construction FieldRecording
      final recording = FieldRecording(
        id: const Uuid().v4(),
        filePath: _currentFilePath!,
        latitude: _recordingLatitude!,
        longitude: _recordingLongitude!,
        durationSeconds: durationSeconds,
        recordedAt: startedAt,
        syncStatus: SyncStatus.pending,
        userId: userId,
        userEmail: userEmail,
      );

      // 5. Persistance
      await datasource.save(recording);

      developer.log('[RecordingService] stopRecording id=${recording.id} '
          'duration=${recording.durationSeconds}s');

      return recording;
    } finally {
      _currentFilePath = null;
      _recordingLatitude = null;
      _recordingLongitude = null;
      _recordingStartedAt = null;
      _currentLatitude = null;
      _currentLongitude = null;
      _setState(RecordingState.idle);
    }
  }

  // ── Helpers internes ─────────────────────────────────────────────────────────

  void _setState(RecordingState newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    developer.log('[RecordingService] mic permission status: $status');
    print('🎙️ [MIC] status BEFORE request: $status '
        '| isGranted=${status.isGranted} '
        '| isDenied=${status.isDenied} '
        '| isPermanentlyDenied=${status.isPermanentlyDenied} '
        '| isRestricted=${status.isRestricted}');

    if (status.isGranted) {
      return;
    }

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      developer.log('[RecordingService] mic permission après request(): $result');
      print('🎙️ [MIC] status AFTER request: $result '
          '| isGranted=${result.isGranted} '
          '| isPermanentlyDenied=${result.isPermanentlyDenied}');
      if (result.isGranted) return;
      throw const RecordingException(RecordingError.micPermissionDenied);
    }

    // permanentlyDenied (iOS: denied) → l'utilisateur doit aller dans Réglages
    print('🎙️ [MIC] → permanentlyDenied → openAppSettings()');
    developer.log('[RecordingService] mic permission permanentement refusée → openAppSettings');
    await openAppSettings();
    throw const RecordingException(RecordingError.micPermissionDenied);
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('📍 [LOC] isLocationServiceEnabled: $serviceEnabled');
    if (!serviceEnabled) {
      throw const RecordingException(RecordingError.locationServiceDisabled);
    }

    final status = await Permission.locationWhenInUse.status;
    print('📍 [LOC] status BEFORE request: $status '
        '| isGranted=${status.isGranted} '
        '| isDenied=${status.isDenied} '
        '| isPermanentlyDenied=${status.isPermanentlyDenied} '
        '| isRestricted=${status.isRestricted}');

    if (status.isGranted) return;

    if (status.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      print('📍 [LOC] status AFTER request: $result '
          '| isGranted=${result.isGranted} '
          '| isPermanentlyDenied=${result.isPermanentlyDenied}');
      if (result.isGranted) return;
      throw const RecordingException(RecordingError.locationPermissionDenied);
    }

    print('📍 [LOC] → permanentlyDenied → openAppSettings()');
    await openAppSettings();
    throw const RecordingException(RecordingError.locationPermissionDenied);
  }

  Future<String> _buildFilePath(String uuid) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final storiesDir = Directory('${dir.path}/stories');
      await storiesDir.create(recursive: true);
      return '${storiesDir.path}/$uuid.m4a';
    } on FileSystemException catch (e) {
      developer.log('[RecordingService] _buildFilePath error: $e');
      throw const RecordingException(RecordingError.storageError);
    }
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _maxDurationTimer?.cancel();
    _chronoTimer?.cancel();
    _elapsedController.close();
    _recorder.dispose();
    super.dispose();
  }
}
