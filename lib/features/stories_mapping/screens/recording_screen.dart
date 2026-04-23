import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../features/auth/auth_service.dart';
import '../../../features/auth/screens/account_screen.dart';
import '../../../theme/jorapp_theme.dart';
import '../services/recording_service.dart';
import '../services/sync_service.dart';

class RecordingScreen extends StatefulWidget {
  final AuthService authService;
  final RecordingService recordingService;
  final SyncService syncService;

  const RecordingScreen({
    super.key,
    required this.authService,
    required this.recordingService,
    required this.syncService,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Duration>? _elapsedSubscription;
  Duration _elapsed = Duration.zero;
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    widget.recordingService.addListener(_onServiceChanged);
    _elapsedSubscription = widget.recordingService.elapsedTime.listen((d) {
      if (!mounted) return;
      setState(() => _elapsed = d);
    });
  }

  @override
  void dispose() {
    widget.recordingService.removeListener(_onServiceChanged);
    _elapsedSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    setState(() {});
    final state = widget.recordingService.state;
    if (state == RecordingState.recording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    try {
      await widget.recordingService.startRecording();
      setState(() => _elapsed = Duration.zero);
    } on AuthException {
      if (!mounted) return;
      _showErrorSnackbar('Vous devez être connecté pour enregistrer.');
    } on RecordingException catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Erreur inattendue: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await widget.recordingService.stopRecording();
      if (!mounted) return;

      // Tenter sync si réseau disponible
      final results = await Connectivity().checkConnectivity();
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        await widget.syncService.syncPending();
        if (!mounted) return;
        final err = widget.syncService.lastSyncError.value;
        if (err != null) {
          _showErrorSnackbar('Enregistré mais sync échouée : $err');
        } else {
          _showSuccessSnackbar('Enregistrement synchronisé.');
        }
      } else {
        _showSuccessSnackbar(
          'Enregistrement sauvegardé. Sync en attente de réseau.',
        );
      }
    } on RecordingException catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Erreur à l\'arrêt: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: JorappColors.tealDark),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: JorappColors.teal),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JorappColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 45,
                height: 45,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Enregistrement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: JorappColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Mon compte',
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AccountScreen(authService: widget.authService),
                ),
              ),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: JorappColors.teal.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: JorappColors.teal,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Tooltip(
            message: 'Mes récits',
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.storiesList),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: JorappColors.teal.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.library_music_outlined,
                  color: JorappColors.teal,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
          _buildBody(),
        ],
      ),
    );
  }

  // ── Corps principal ───────────────────────────────────────────────────────────

  Widget _buildBody() {
    return ListenableBuilder(
      listenable: widget.recordingService,
      builder: (context, _) {
        final state = widget.recordingService.state;
        return switch (state) {
          RecordingState.idle || RecordingState.requestingPermission =>
            _buildIdleState(
              loading: state == RecordingState.requestingPermission,
            ),
          RecordingState.recording => _buildRecordingState(),
          RecordingState.stopping => _buildStoppingState(),
        };
      },
    );
  }

  // ── État idle ─────────────────────────────────────────────────────────────────

  Widget _buildIdleState({required bool loading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag pill
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: JorappColors.lime,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: JorappColors.ink.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'SCIENCE PARTICIPATIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: JorappColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Il existe une autre géographie du Jorat, invisible et sensible.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: JorappColors.tealDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aidez-nous à la cartographier avec vos mots.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: JorappColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              // Card explicative
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: JorappColors.ink.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: JorappColors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.mic_none_rounded,
                            color: JorappColors.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vous décidez',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: JorappColors.ink,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Enregistrez, réécoutez, recommencez. Vous décidez de ce que vous partagez.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                  color: JorappColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Accent lime gauche
                    Positioned(
                      left: -16,
                      top: -16,
                      bottom: -16,
                      child: Container(
                        width: 3,
                        decoration: const BoxDecoration(
                          color: JorappColors.lime,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Text(
          'Appuyez pour démarrer un enregistrement',
          style: TextStyle(
            fontSize: 16,
            color: JorappColors.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: loading ? null : _startRecording,
          child: Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: loading
                  ? JorappColors.teal.withValues(alpha: 0.5)
                  : JorappColors.teal,
              boxShadow: [
                BoxShadow(
                  color: JorappColors.teal.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── État recording ────────────────────────────────────────────────────────────

  Widget _buildRecordingState() {
    final lat = widget.recordingService.currentLatitude;
    final lon = widget.recordingService.currentLongitude;
    final progress = _elapsed.inSeconds / AppConfig.maxRecordingDurationSeconds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chronomètre + dot pulsant
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 1.0 + (_pulseController.value * 0.18);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDuration(_elapsed),
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: JorappColors.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ProgressBar vers durée max
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: JorappColors.surfaceStrong,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFE53935),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0:00',
                style: TextStyle(
                  fontSize: 11,
                  color: JorappColors.ink.withValues(alpha: 0.45),
                ),
              ),
              Text(
                _formatDuration(
                  Duration(seconds: AppConfig.maxRecordingDurationSeconds),
                ),
                style: TextStyle(
                  fontSize: 11,
                  color: JorappColors.ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Coordonnées GPS
          if (lat != null && lon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: JorappColors.surfaceStrong,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: JorappColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JorappColors.tealDark,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),

          // Bouton terminer
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JorappColors.lime,
                boxShadow: [
                  BoxShadow(
                    color: JorappColors.lime.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: JorappColors.tealDark,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Terminer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: JorappColors.tealDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── État stopping ─────────────────────────────────────────────────────────────

  Widget _buildStoppingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: JorappColors.teal),
          SizedBox(height: 20),
          Text(
            'Sauvegarde en cours...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: JorappColors.tealDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
