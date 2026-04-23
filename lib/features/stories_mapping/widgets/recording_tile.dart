import 'package:flutter/material.dart';

import '../../../theme/jorapp_theme.dart';
import '../models/field_recording.dart';
import '../services/recording_player_service.dart';

enum _MenuAction { upload, deleteLocal, deleteEverywhere }

class RecordingTile extends StatelessWidget {
  final FieldRecording recording;
  final RecordingPlayerService playerService;
  final Future<void> Function() onUpload;
  final Future<void> Function() onDeleteLocal;
  final Future<void> Function()? onDeleteEverywhere;

  const RecordingTile({
    super.key,
    required this.recording,
    required this.playerService,
    required this.onUpload,
    required this.onDeleteLocal,
    this.onDeleteEverywhere,
  });

  // ── Formatage ─────────────────────────────────────────────────────────────────

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _months = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
    'juil', 'août', 'sep', 'oct', 'nov', 'déc',
  ];

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final weekday = _weekdays[local.weekday - 1];
    final month = _months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$weekday ${local.day} $month · $hour:$min';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final m = seconds ~/ 60;
    final s = seconds.remainder(60);
    return s == 0 ? '$m min' : '$m min $s s';
  }

  String _formatCoords(double lat, double lon) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'O';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, '
        '${lon.abs().toStringAsFixed(4)}°$lonDir';
  }

  // ── Lecture ───────────────────────────────────────────────────────────────────

  void _togglePlay() {
    if (playerService.isActive(recording.id)) {
      if (playerService.isPlaying) {
        playerService.pause();
      } else {
        playerService.resume();
      }
    } else {
      playerService.play(recording);
    }
  }

  // ── Actions menu ──────────────────────────────────────────────────────────────

  Future<void> _handleAction(
    BuildContext context,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.upload:
        await onUpload();

      case _MenuAction.deleteLocal:
        if (recording.syncStatus == SyncStatus.synced &&
            recording.remoteId != null) {
          if (!context.mounted) return;
          final alsoRemote = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Supprimer localement'),
              content: const Text(
                'Cet enregistrement est synchronisé. '
                'Supprimer aussi la copie sur le serveur ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Non, local seulement'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Oui, supprimer partout'),
                ),
              ],
            ),
          );
          if (alsoRemote == true && onDeleteEverywhere != null) {
            await onDeleteEverywhere!();
          } else {
            await onDeleteLocal();
          }
        } else {
          await onDeleteLocal();
        }

      case _MenuAction.deleteEverywhere:
        if (!context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer partout'),
            content: const Text(
              'Cet enregistrement sera supprimé localement '
              'et sur le serveur. Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (confirmed == true && onDeleteEverywhere != null) {
          await onDeleteEverywhere!();
        }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canUpload = recording.syncStatus == SyncStatus.pending ||
        recording.syncStatus == SyncStatus.error;
    final isSynced = recording.syncStatus == SyncStatus.synced;
    final isDraft = recording.syncStatus == SyncStatus.pending ||
        recording.syncStatus == SyncStatus.error;

    return Opacity(
      opacity: isDraft ? 0.65 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDraft
                ? JorappColors.lime.withValues(alpha: 0.5)
                : JorappColors.lime,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: JorappColors.ink.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(isSynced),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo()),
            const SizedBox(width: 8),
            _buildActions(context, canUpload),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isSynced) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSynced
                ? JorappColors.lime.withValues(alpha: 0.18)
                : JorappColors.teal.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: JorappColors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        if (isSynced)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: JorappColors.lime,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 9, color: JorappColors.ink),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo() {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final isActive = playerService.isActive(recording.id);
        final total = playerService.totalDuration;
        final progressValue =
            isActive && total != null && total.inMilliseconds > 0
                ? (playerService.position.inMilliseconds /
                        total.inMilliseconds)
                    .clamp(0.0, 1.0)
                : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(recording.recordedAt),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: JorappColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  _formatDuration(recording.durationSeconds),
                  style: const TextStyle(
                    fontSize: 14,
                    color: JorappColors.muted,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: JorappColors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _formatCoords(recording.latitude, recording.longitude),
                    style: const TextStyle(
                      fontSize: 14,
                      color: JorappColors.muted,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildWaveform(),
            if (isActive) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 3,
                  backgroundColor: JorappColors.surfaceStrong,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    JorappColors.teal,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWaveform() {
    const heights = [5.0, 10.0, 7.0, 13.0, 6.0, 9.0, 4.0];
    return SizedBox(
      height: 14,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 2,
              height: heights[i],
              decoration: BoxDecoration(
                color: JorappColors.teal.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool canUpload) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: playerService,
          builder: (context, _) {
            final isActive = playerService.isActive(recording.id);
            final isPlaying = isActive && playerService.isPlaying;
            return GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: JorappColors.teal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: JorappColors.teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          height: 28,
          child: PopupMenuButton<_MenuAction>(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert,
              color: JorappColors.muted,
              size: 18,
            ),
            onSelected: (action) {
              () async {
                await _handleAction(context, action);
              }();
            },
            itemBuilder: (_) => [
              if (canUpload)
                const PopupMenuItem(
                  value: _MenuAction.upload,
                  child: ListTile(
                    leading: Icon(Icons.cloud_upload_rounded, size: 20),
                    title: Text('Uploader'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              const PopupMenuItem(
                value: _MenuAction.deleteLocal,
                child: ListTile(
                  leading: Icon(
                    Icons.phone_android_rounded,
                    size: 20,
                    color: Color(0xFFE65100),
                  ),
                  title: Text('Supprimer localement'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (recording.remoteId != null)
                const PopupMenuItem(
                  value: _MenuAction.deleteEverywhere,
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_forever_rounded,
                      size: 20,
                      color: Color(0xFFC62828),
                    ),
                    title: Text('Supprimer partout'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
