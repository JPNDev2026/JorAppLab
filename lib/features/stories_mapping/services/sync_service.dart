import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/pb_client.dart';
import '../models/field_recording.dart';
import 'stories_local_datasource.dart';

class SyncService {
  final StoriesLocalDatasource datasource;

  SyncService({required this.datasource}) {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  static const String _collection = 'field_recordings';

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  final ValueNotifier<String?> lastSyncError = ValueNotifier(null);

  // ── Écoute réseau ─────────────────────────────────────────────────────────────

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (hasNetwork) {
      developer.log('[SyncService] réseau détecté → syncPending');
      unawaited(syncPending());
    }
  }

  // ── syncPending ───────────────────────────────────────────────────────────────

  Future<void> syncPending() async {
    if (isSyncing.value) return;

    final pending = datasource.getPending();
    if (pending.isEmpty) return;

    isSyncing.value = true;
    lastSyncError.value = null;
    developer.log('[SyncService] syncPending: ${pending.length} item(s)');

    try {
      for (final recording in pending) {
        await _uploadOne(recording);
      }
    } finally {
      isSyncing.value = false;
    }
  }

  /// Upload unitaire déclenché manuellement depuis l'UI.
  Future<void> uploadOne(FieldRecording recording) => _uploadOne(recording);

  Future<void> _uploadOne(FieldRecording recording) async {
    // Marque uploading
    await datasource.update(recording.copyWith(syncStatus: SyncStatus.uploading));

    try {
      final pb = PbClient.instance.pb;

      final audioFile = await http.MultipartFile.fromPath(
        'audio_file',
        recording.filePath,
        filename: '${recording.id}.m4a',
      );

      final record = await pb.collection(_collection).create(
        body: {
          'latitude': recording.latitude,
          'longitude': recording.longitude,
          'duration_seconds': recording.durationSeconds,
          'recorded_at': recording.recordedAt.toIso8601String(),
          'user': recording.userId,
        },
        files: [audioFile],
      );

      await datasource.update(
        recording.copyWith(
          syncStatus: SyncStatus.synced,
          remoteId: record.id,
        ),
      );

      developer.log('[SyncService] uploadOne ok id=${recording.id} remoteId=${record.id}');
    } on FileSystemException catch (e) {
      developer.log('[SyncService] fichier introuvable id=${recording.id}: $e');
      await datasource.update(recording.copyWith(syncStatus: SyncStatus.error));
      lastSyncError.value = 'Fichier audio introuvable pour ${recording.id}.';
    } catch (e) {
      developer.log('[SyncService] uploadOne error id=${recording.id}: $e');
      await datasource.update(recording.copyWith(syncStatus: SyncStatus.error));
      lastSyncError.value = 'Erreur upload: $e';
    }
  }

  // ── deleteRemote ──────────────────────────────────────────────────────────────

  Future<void> deleteRemote(String remoteId) async {
    try {
      final pb = PbClient.instance.pb;
      await pb.collection(_collection).delete(remoteId);
      developer.log('[SyncService] deleteRemote ok remoteId=$remoteId');
    } catch (e) {
      developer.log('[SyncService] deleteRemote error remoteId=$remoteId: $e');
      rethrow;
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────────

  void dispose() {
    _connectivitySubscription?.cancel();
    isSyncing.dispose();
    lastSyncError.dispose();
  }
}
