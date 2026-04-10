import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/field_recording.dart';

class StoriesLocalDatasource {
  static const _key = 'stories_mapping_recordings';

  /// Notifier mis à jour après chaque opération d'écriture.
  /// L'UI peut écouter ce notifier avec [ListenableBuilder] ou [ValueListenableBuilder].
  final ValueNotifier<List<FieldRecording>> recordingsNotifier =
      ValueNotifier(const <FieldRecording>[]);

  StoriesLocalDatasource() {
    unawaited(_load());
  }

  // ── Initialisation ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final all = await getAll();
      recordingsNotifier.value = List.unmodifiable(all);
    } catch (e) {
      developer.log('[StoriesLocalDatasource] _load error: $e');
    }
  }

  // ── Lecture ──────────────────────────────────────────────────────────────────

  Future<List<FieldRecording>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FieldRecording.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retourne synchronement les enregistrements en attente de sync.
  /// Basé sur [recordingsNotifier.value] — appeler après que [_load] ait résolu.
  List<FieldRecording> getPending() => recordingsNotifier.value
      .where((r) => r.syncStatus == SyncStatus.pending)
      .toList();

  // ── Écriture ─────────────────────────────────────────────────────────────────

  Future<void> save(FieldRecording recording) async {
    final all = await getAll();
    all.add(recording);
    await _persist(all);
    developer.log('[StoriesLocalDatasource] saved ${recording.id}');
  }

  /// Remplace l'enregistrement existant dont l'[id] correspond.
  Future<void> update(FieldRecording recording) async {
    final all = await getAll();
    final index = all.indexWhere((r) => r.id == recording.id);
    if (index == -1) {
      developer.log(
        '[StoriesLocalDatasource] update: id ${recording.id} introuvable',
      );
      return;
    }
    all[index] = recording;
    await _persist(all);
  }

  /// Supprime l'entrée et efface le fichier .m4a local s'il existe.
  Future<void> delete(String id) async {
    final all = await getAll();
    final target = all.where((r) => r.id == id).firstOrNull;
    all.removeWhere((r) => r.id == id);
    await _persist(all);

    if (target != null) {
      final file = File(target.filePath);
      if (await file.exists()) {
        await file.delete();
        developer.log('[StoriesLocalDatasource] fichier supprimé: ${target.filePath}');
      }
    }
  }

  // ── Persistance interne ──────────────────────────────────────────────────────

  Future<void> _persist(List<FieldRecording> recordings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(recordings.map((r) => r.toJson()).toList()),
    );
    recordingsNotifier.value = List.unmodifiable(recordings);
  }
}
