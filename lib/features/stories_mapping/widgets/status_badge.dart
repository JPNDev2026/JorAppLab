import 'package:flutter/material.dart';

import '../../../theme/jorapp_theme.dart';
import '../models/field_recording.dart';

class StatusBadge extends StatelessWidget {
  final SyncStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      SyncStatus.pending => _Badge(
        icon: Icons.schedule_rounded,
        color: const Color(0xFFE65100),
        backgroundColor: const Color(0xFFFFF3E0),
      ),
      SyncStatus.uploading => const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1565C0),
            ),
          ),
        ),
      ),
      SyncStatus.synced => _Badge(
        icon: Icons.cloud_done_rounded,
        color: JorappColors.tealDark,
        backgroundColor: JorappColors.lime.withValues(alpha: 0.25),
      ),
      SyncStatus.error => _Badge(
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFC62828),
        backgroundColor: const Color(0xFFFFEBEE),
      ),
    };
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _Badge({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
