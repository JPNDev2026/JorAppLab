import 'package:flutter/material.dart';

import '../../../theme/jorapp_theme.dart';
import '../models/field_recording.dart';
import '../services/recording_player_service.dart';
import 'status_badge.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: JorappColors.surfaceStrong,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: JorappColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: StatusBadge(status: recording.syncStatus),
        title: Text(
          _formatDate(recording.recordedAt),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: JorappColors.ink,
          ),
        ),
        subtitle: ListenableBuilder(
          listenable: playerService,
          builder: (context, _) {
            final isActive = playerService.isActive(recording.id);
            final total = playerService.totalDuration;
            final progressValue = isActive && total != null && total.inMilliseconds > 0
                ? (playerService.position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${_formatDuration(recording.durationSeconds)}  ·  '
                    '${_formatCoords(recording.latitude, recording.longitude)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: JorappColors.ink.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 6),
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
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: playerService,
              builder: (context, _) {
                final isActive = playerService.isActive(recording.id);
                final isPlaying = isActive && playerService.isPlaying;
                return IconButton(
                  onPressed: _togglePlay,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    color: isActive
                        ? JorappColors.teal
                        : JorappColors.ink.withValues(alpha: 0.45),
                    size: 26,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            PopupMenuButton<_MenuAction>(
          icon: Icon(
            Icons.more_vert,
            color: JorappColors.ink.withValues(alpha: 0.45),
            size: 20,
          ),
          onSelected: (action) {
            // Async depuis un callback sync : pattern fire-and-forget local.
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
          ],
        ),
      ),
    );
  }
}
