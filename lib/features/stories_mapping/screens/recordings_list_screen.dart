import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/jorapp_theme.dart';
import '../models/field_recording.dart';
import '../services/recording_player_service.dart';
import '../services/stories_local_datasource.dart';
import '../services/sync_service.dart';
import '../widgets/recording_tile.dart';

enum _ViewMode { list, map }

class RecordingsListScreen extends StatefulWidget {
  final StoriesLocalDatasource datasource;
  final SyncService syncService;

  const RecordingsListScreen({
    super.key,
    required this.datasource,
    required this.syncService,
  });

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  _ViewMode _viewMode = _ViewMode.list;
  final RecordingPlayerService _playerService = RecordingPlayerService();

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _syncAll() async {
    await widget.syncService.syncPending();
    if (!mounted) return;
    final err = widget.syncService.lastSyncError.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Synchronisation terminée.'),
        backgroundColor:
            err != null ? JorappColors.tealDark : JorappColors.teal,
      ),
    );
  }

  Future<void> _uploadOne(FieldRecording r) async {
    try {
      await widget.syncService.uploadOne(r);
      if (!mounted) return;
      final err = widget.syncService.lastSyncError.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Upload réussi.'),
          backgroundColor:
              err != null ? JorappColors.tealDark : JorappColors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur upload : $e'),
          backgroundColor: JorappColors.tealDark,
        ),
      );
    }
  }

  Future<void> _deleteLocal(FieldRecording r) async {
    try {
      await widget.datasource.delete(r.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur suppression locale : $e'),
          backgroundColor: JorappColors.tealDark,
        ),
      );
    }
  }

  Future<void> _deleteEverywhere(FieldRecording r) async {
    try {
      if (r.remoteId != null) {
        await widget.syncService.deleteRemote(r.remoteId!);
      }
      await widget.datasource.delete(r.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur suppression : $e'),
          backgroundColor: JorappColors.tealDark,
        ),
      );
    }
  }

  LatLng _mapCenter(List<FieldRecording> recordings) {
    if (recordings.isEmpty) return const LatLng(46.58, 6.67);
    var latSum = 0.0;
    var lngSum = 0.0;
    for (final r in recordings) {
      latSum += r.latitude;
      lngSum += r.longitude;
    }
    return LatLng(latSum / recordings.length, lngSum / recordings.length);
  }

  String _formatTotalDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds.remainder(60);
    return s == 0 ? '${m}m' : '${m}m${s}s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JorappColors.surface,
      appBar: AppBar(
        title: const Text(
          'Mes récits',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: JorappColors.ink,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(
              () => _viewMode =
                  _viewMode == _ViewMode.list ? _ViewMode.map : _ViewMode.list,
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: JorappColors.teal.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _viewMode == _ViewMode.list
                    ? Icons.map_outlined
                    : Icons.list_rounded,
                color: JorappColors.teal,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    JorappColors.teal.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          ValueListenableBuilder<List<FieldRecording>>(
            valueListenable: widget.datasource.recordingsNotifier,
            builder: (context, recordings, _) {
              return _viewMode == _ViewMode.list
                  ? _buildListView(recordings)
                  : _buildMapView(recordings);
            },
          ),
        ],
      ),
    );
  }

  // ── Vue liste ─────────────────────────────────────────────────────────────────

  Widget _buildListView(List<FieldRecording> recordings) {
    final totalCount = recordings.length;
    final syncedCount =
        recordings.where((r) => r.syncStatus == SyncStatus.synced).length;
    final totalDuration = recordings.fold<int>(
      0,
      (sum, r) => sum + r.durationSeconds,
    );

    return Column(
      children: [
        // Stats strip
        if (totalCount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: JorappColors.teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _StatItem(
                  value: '$totalCount',
                  label: 'RÉCITS',
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: JorappColors.teal.withValues(alpha: 0.1),
                ),
                _StatItem(
                  value: '$syncedCount',
                  label: 'SYNCHRONISÉS',
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: JorappColors.teal.withValues(alpha: 0.1),
                ),
                _StatItem(
                  value: _formatTotalDuration(totalDuration),
                  label: 'DURÉE',
                ),
              ],
            ),
          ),
        _SyncHeader(
          syncService: widget.syncService,
          onSyncAll: _syncAll,
        ),
        Expanded(
          child: recordings.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: recordings.length,
                  itemBuilder: (context, index) {
                    final sorted = [...recordings]
                      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
                    final r = sorted[index];
                    return RecordingTile(
                      recording: r,
                      playerService: _playerService,
                      onUpload: () => _uploadOne(r),
                      onDeleteLocal: () => _deleteLocal(r),
                      onDeleteEverywhere: r.remoteId != null
                          ? () => _deleteEverywhere(r)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Vue carte ─────────────────────────────────────────────────────────────────

  Widget _buildMapView(List<FieldRecording> recordings) {
    if (recordings.isEmpty) return const _EmptyState();

    final center = _mapCenter(recordings);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ch.jorat.geofence',
            ),
            MarkerLayer(
              markers: recordings.map((r) {
                return Marker(
                  point: LatLng(r.latitude, r.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showRecordingSheet(r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _markerColor(r.syncStatus),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _markerColor(SyncStatus status) => switch (status) {
        SyncStatus.synced => JorappColors.teal,
        SyncStatus.pending => const Color(0xFFE65100),
        SyncStatus.uploading => Colors.blue,
        SyncStatus.error => const Color(0xFFC62828),
      };

  void _showRecordingSheet(FieldRecording r) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: RecordingTile(
          recording: r,
          playerService: _playerService,
          onUpload: () async {
            Navigator.pop(sheetContext);
            await _uploadOne(r);
          },
          onDeleteLocal: () async {
            Navigator.pop(sheetContext);
            await _deleteLocal(r);
          },
          onDeleteEverywhere: r.remoteId != null
              ? () async {
                  Navigator.pop(sheetContext);
                  await _deleteEverywhere(r);
                }
              : null,
        ),
      ),
    );
  }
}

// ── Stats item ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: JorappColors.teal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              color: JorappColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header sync ───────────────────────────────────────────────────────────────

class _SyncHeader extends StatelessWidget {
  final SyncService syncService;
  final VoidCallback onSyncAll;

  const _SyncHeader({required this.syncService, required this.onSyncAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: syncService.isSyncing,
            builder: (context, syncing, _) {
              if (syncing) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: JorappColors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Synchronisation…',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: JorappColors.teal,
                      ),
                    ),
                  ],
                );
              }
              return ValueListenableBuilder<String?>(
                valueListenable: syncService.lastSyncError,
                builder: (context, err, _) {
                  if (err != null) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Color(0xFFE65100),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Dernière sync échouée',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    );
                  }
                  return const Text(
                    'RÉCITS TERRAIN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: JorappColors.muted,
                    ),
                  );
                },
              );
            },
          ),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: syncService.isSyncing,
            builder: (context, syncing, _) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: syncing
                      ? []
                      : [
                          BoxShadow(
                            color: JorappColors.teal.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: TextButton.icon(
                  onPressed: syncing ? null : onSyncAll,
                  style: TextButton.styleFrom(
                    backgroundColor: syncing
                        ? JorappColors.teal.withValues(alpha: 0.5)
                        : JorappColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.sync_rounded,
                    size: 13,
                    color: JorappColors.lime,
                  ),
                  label: const Text(
                    'Tout synchroniser',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── État vide ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 48,
              color: JorappColors.teal.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun récit enregistré pour l\'instant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: JorappColors.tealDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Démarrez un enregistrement terrain pour le voir apparaître ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: JorappColors.ink.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
