import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/field_recording.dart';

class RecordingPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  String? _currentRecordingId;
  Duration _position = Duration.zero;
  Duration? _totalDuration;
  String? _errorMessage;

  RecordingPlayerService() {
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _currentRecordingId = null;
        _position = Duration.zero;
        _totalDuration = null;
      }
      notifyListeners();
    });
    _positionSubscription = _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
  }

  String? get currentRecordingId => _currentRecordingId;
  Duration get position => _position;
  Duration? get totalDuration => _totalDuration;
  bool get isPlaying => _player.playing;
  bool get hasActiveTrack => _currentRecordingId != null;
  bool get isPaused => hasActiveTrack && !_player.playing;
  String? get errorMessage => _errorMessage;

  bool isActive(String recordingId) => _currentRecordingId == recordingId;

  Future<void> play(FieldRecording recording) async {
    _errorMessage = null;
    _currentRecordingId = recording.id;
    _position = Duration.zero;
    _totalDuration = null;
    notifyListeners();

    try {
      await _player.stop();
      _totalDuration = await _player.setFilePath(recording.filePath);
      await _player.play();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _currentRecordingId = null;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (!_player.playing) return;
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    if (!hasActiveTrack || _player.playing) return;
    await _player.play();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentRecordingId = null;
    _position = Duration.zero;
    _totalDuration = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
