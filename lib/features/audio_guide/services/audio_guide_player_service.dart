import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/audio_point.dart';

class AudioGuidePlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final Set<String> _playedPointIds = <String>{};
  StreamSubscription<PlayerState>? _playerStateSubscription;

  String? _currentPointId;
  String? _currentTitle;
  String? _errorMessage;

  AudioGuidePlayerService() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _currentPointId = null;
        _currentTitle = null;
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  String? get currentPointId => _currentPointId;
  String? get currentTitle => _currentTitle;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _player.playing;
  bool get hasActiveTrack => _currentPointId != null && _currentTitle != null;
  bool get isPaused => hasActiveTrack && !_player.playing;
  Set<String> get playedPointIds => Set<String>.unmodifiable(_playedPointIds);

  bool hasPlayed(String pointId) => _playedPointIds.contains(pointId);

  Future<void> playPoint(AudioPoint point) async {
    final path = point.localPath;
    if (path == null || path.isEmpty) {
      throw Exception('Fichier audio local introuvable pour ${point.titre}.');
    }

    _errorMessage = null;
    _currentPointId = point.id;
    _currentTitle = point.titre;
    _playedPointIds.add(point.id);
    notifyListeners();

    try {
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
    } catch (error) {
      _errorMessage = error.toString();
      _currentPointId = null;
      _currentTitle = null;
      rethrow;
    }

    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPointId = null;
    _currentTitle = null;
    notifyListeners();
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

  @override
  void dispose() {
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
