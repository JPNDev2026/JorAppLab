import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/jorapp_theme.dart';
import '../../auth/auth_service.dart';
import '../geofencing_controller.dart';
import '../models/location_sample.dart';
import '../widgets/layer_menu.dart';
import '../widgets/map_widget.dart';
import 'measurements_screen.dart';

class MapScreen extends StatefulWidget {
  final AuthService authService;
  final GeofencingController geofencingController;

  const MapScreen({
    super.key,
    required this.authService,
    required this.geofencingController,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  LocationSample? _selectedSample;
  bool _isLocationServiceEnabled = false;
  LocationPermission _locationPermission = LocationPermission.unableToDetermine;
  late final AnimationController _gpsBlinkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    developer.log(
      '[MapScreen] initState loader=${GeofencingController.loaderVersion}',
    );
    unawaited(_prepareLocationTracking());
    unawaited(widget.geofencingController.bootstrapLayers());
    widget.geofencingController.addListener(_onControllerChanged);
    _errorSubscription = widget.geofencingController.errors.listen((error) {
      _handleError(error);
    });
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      status,
    ) {
      if (!mounted) return;
      setState(() {
        _isLocationServiceEnabled = status == ServiceStatus.enabled;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.geofencingController.removeListener(_onControllerChanged);
    _errorSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    _gpsBlinkController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_prepareLocationTracking());
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _prepareLocationTracking() async {
    await _refreshLocationAccessState();
    await _requestLocationPermissionIfNeeded();
    await _ensureTrackingActive();
  }

  Future<void> _refreshLocationAccessState() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      _isLocationServiceEnabled = enabled;
      _locationPermission = permission;
    });
  }

  Future<void> _requestLocationPermissionIfNeeded() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    setState(() {
      _locationPermission = permission;
    });
  }

  Future<void> _ensureTrackingActive() async {
    await widget.geofencingController.trackingController.initialize(
      autoStart: true,
    );
    if (!widget.geofencingController.isCollecting) {
      await widget.geofencingController.trackingController.setCollecting(true);
    }
  }

  void _handleError(String error) {
    if (!mounted) return;
    if (_isLocationAccessMessage(error)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  bool _isLocationAccessMessage(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('service de localisation desactive') ||
        normalized.contains('permission de localisation') ||
        normalized.contains('permission en arriere-plan');
  }

  bool get _hasLocationPermission =>
      _locationPermission == LocationPermission.always ||
      _locationPermission == LocationPermission.whileInUse;

  bool get _showLocationBanner =>
      !_isLocationServiceEnabled || !_hasLocationPermission;

  Future<void> _handleLocationBannerPressed() async {
    if (!_hasLocationPermission) {
      if (_locationPermission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      } else {
        await _requestLocationPermissionIfNeeded();
      }
      return;
    }

    await Geolocator.openLocationSettings();
  }

  Future<void> _openMeasurements() async {
    final selectedSample = await Navigator.of(context).push<LocationSample>(
      MaterialPageRoute(
        builder: (_) => MeasurementsScreen(
          trackingController: widget.geofencingController.trackingController,
        ),
      ),
    );

    if (!mounted || selectedSample == null) return;
    setState(() {
      _selectedSample = selectedSample;
    });
  }

  String _locationStatusText() {
    final sample = widget.geofencingController.latestSample;
    if (sample == null) {
      return widget.geofencingController.isCollecting
          ? 'Collecte GPS en cours...'
          : 'Collecte GPS inactive';
    }

    final measuredAt = sample.measuredAtUtc.toLocal().toIso8601String();
    final accuracy = sample.accuracyMeters.toStringAsFixed(1);
    final lat = sample.latitude.toStringAsFixed(6);
    final lon = sample.longitude.toStringAsFixed(6);

    return 'Dernier point: $lat, $lon | precision $accuracy | ${sample.quality} | $measuredAt';
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LayerMenu(
        showPaths: widget.geofencingController.showPaths,
        showProtectedAreas: widget.geofencingController.showProtectedAreas,
        onTogglePaths: (bool value) {
          widget.geofencingController.togglePaths(value);
        },
        onToggleProtectedAreas: (bool value) {
          widget.geofencingController.toggleProtectedAreas(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      '[MapScreen] build showPaths=${widget.geofencingController.showPaths} '
      'showProtectedAreas=${widget.geofencingController.showProtectedAreas} '
      'paths=${widget.geofencingController.paths.length} '
      'polygons=${widget.geofencingController.protectedAreas.length}',
    );

    final isGpsActive =
        _isLocationServiceEnabled &&
        _hasLocationPermission &&
        widget.geofencingController.isCollecting;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'JorAppLab',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Parc du Jorat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: JorappColors.surfaceStrong,
              foregroundColor: JorappColors.tealDark,
            ),
            icon: const Icon(Icons.table_rows_rounded),
            onPressed: _openMeasurements,
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: JorappColors.surfaceStrong,
              foregroundColor: JorappColors.tealDark,
            ),
            icon: const Icon(Icons.layers_rounded),
            onPressed: _openMenu,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MapWidget(
              paths: widget.geofencingController.paths,
              protectedAreas: widget.geofencingController.protectedAreas,
              recordedPoints: widget.geofencingController.samples
                  .map((sample) => LatLng(sample.latitude, sample.longitude))
                  .toList(),
              latestPoint: widget.geofencingController.latestSample == null
                  ? null
                  : LatLng(
                      widget.geofencingController.latestSample!.latitude,
                      widget.geofencingController.latestSample!.longitude,
                    ),
              selectedPoint: _selectedSample == null
                  ? null
                  : LatLng(_selectedSample!.latitude, _selectedSample!.longitude),
              showPaths: widget.geofencingController.showPaths,
              showProtectedAreas: widget.geofencingController.showProtectedAreas,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _GpsStatusBadge(
              animation: _gpsBlinkController,
              isActive: isGpsActive,
            ),
          ),
          if (_showLocationBanner)
            Positioned(
              top: 12,
              left: 12,
              right: 120,
              child: _LocationSettingsBanner(
                title: _hasLocationPermission
                    ? 'Activez le GPS pour afficher votre position'
                    : 'Autorisez la localisation pour afficher votre position',
                actionLabel: _hasLocationPermission ? 'Activer' : 'Autoriser',
                icon: _hasLocationPermission
                    ? Icons.gps_off_rounded
                    : Icons.location_disabled_rounded,
                onPressed: _handleLocationBannerPressed,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [JorappColors.teal, JorappColors.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: JorappColors.lime.withOpacity(0.7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Mesures collectees: ${widget.geofencingController.samples.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _locationStatusText(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GpsStatusBadge extends StatelessWidget {
  final Animation<double> animation;
  final bool isActive;

  const _GpsStatusBadge({
    required this.animation,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? JorappColors.tealDark.withOpacity(0.28)
              : JorappColors.ink.withOpacity(0.12),
          width: 0.5,
        ),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final dotColor = isActive
              ? JorappColors.lime.withOpacity(0.45 + (animation.value * 0.55))
              : Colors.grey.shade400;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'GPS actif' : 'GPS inactif',
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? JorappColors.tealDark : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationSettingsBanner extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onPressed;

  const _LocationSettingsBanner({
    required this.title,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JorappColors.tealDark.withOpacity(0.14),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: JorappColors.ink.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: JorappColors.tealDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: JorappColors.ink,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: JorappColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
