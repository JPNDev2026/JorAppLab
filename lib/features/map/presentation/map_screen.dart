import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/jorapp_theme.dart';
import '../../geofencing/geofencing_controller.dart';
import '../../geofencing/models/location_sample.dart';
import 'widgets/layer_toggle_card.dart';
import 'widgets/user_location_marker.dart';

class OrientationMapScreen extends StatefulWidget {
  final GeofencingController geofencingController;

  const OrientationMapScreen({
    super.key,
    required this.geofencingController,
  });

  @override
  State<OrientationMapScreen> createState() => _OrientationMapScreenState();
}

class _OrientationMapScreenState extends State<OrientationMapScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF3D6B35);
  static const _surface = Color(0xFFF5F3EE);
  static const _surfaceAlt = Color(0xFFE8E5DC);
  static const _border = Color(0xFFE0DDD5);
  static const _text = Color(0xFF1C1C1C);

  // Slightly shifted north so the park remains visually centered
  // once the bottom sheet is open.
  static const _initialCenter = LatLng(46.623, 6.703);
  static const _initialZoom = 13.5;

  late final AnimationController _gpsBlinkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  bool _isSheetExpanded = true;
  bool _isZoneAlertEnabled = true;

  @override
  void initState() {
    super.initState();
    widget.geofencingController.addListener(_onGeoChanged);
  }

  @override
  void dispose() {
    widget.geofencingController.removeListener(_onGeoChanged);
    _gpsBlinkController.dispose();
    super.dispose();
  }

  void _onGeoChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _setSheetExpanded(bool value) {
    if (_isSheetExpanded == value) return;
    setState(() {
      _isSheetExpanded = value;
    });
  }

  void _setZoneAlertEnabled(bool value) {
    setState(() {
      _isZoneAlertEnabled = value;
    });
    // TODO: activer/désactiver géofence
  }

  @override
  Widget build(BuildContext context) {
    final latestSample = widget.geofencingController.latestSample;
    final userPosition = _sampleToLatLng(latestSample);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 76,
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Orientation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 36,
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  color: _text,
                  onPressed: () {
                    // TODO: recentrer sur position utilisateur
                  },
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _border),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.jorat_geofence',
                ),
                // TODO: PolylineLayer sentiers pédestres (couleur #2196F3)
                // TODO: PolylineLayer sentiers cyclistes (couleur #F59E0B)
                // TODO: PolylineLayer sentiers cavaliers (couleur #9C6FE4)
                // TODO: PolygonLayer périmètre du parc
                // (stroke #3D6B35, fill opacity 0.06)
                if (userPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 72,
                        height: 72,
                        point: userPosition,
                        child: const UserLocationMarker(color: _primary),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _GpsBadge(animation: _gpsBlinkController),
          ),
          Positioned(
            left: 12,
            bottom: _isSheetExpanded ? 278 : 116,
            child: const _ScaleBar(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomSheet(
              isExpanded: _isSheetExpanded,
              onExpandedChanged: _setSheetExpanded,
              onPedestreToggle: (value) {
                // TODO: activer/désactiver la couche correspondante sur la carte
              },
              onCyclisteToggle: (value) {
                // TODO: activer/désactiver la couche correspondante sur la carte
              },
              onCavalierToggle: (value) {
                // TODO: activer/désactiver la couche correspondante sur la carte
              },
              isZoneAlertEnabled: _isZoneAlertEnabled,
              onGeofenceToggle: _setZoneAlertEnabled,
            ),
          ),
        ],
      ),
    );
  }

  LatLng? _sampleToLatLng(LocationSample? sample) {
    if (sample == null) return null;
    return LatLng(sample.latitude, sample.longitude);
  }
}

class _GpsBadge extends StatelessWidget {
  final Animation<double> animation;

  const _GpsBadge({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D6B35), width: 0.5),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3D6B35)
                      .withOpacity(0.35 + (animation.value * 0.65)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'GPS actif',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF3D6B35),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScaleBar extends StatelessWidget {
  const _ScaleBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 2, height: 8, color: Colors.white),
            Container(width: 40, height: 2, color: Colors.white),
            Container(width: 2, height: 8, color: Colors.white),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '500 m',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF6B6B60),
          ),
        ),
      ],
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<bool> onPedestreToggle;
  final ValueChanged<bool> onCyclisteToggle;
  final ValueChanged<bool> onCavalierToggle;
  final bool isZoneAlertEnabled;
  final ValueChanged<bool> onGeofenceToggle;

  const _BottomSheet({
    required this.isExpanded,
    required this.onExpandedChanged,
    required this.onPedestreToggle,
    required this.onCyclisteToggle,
    required this.onCavalierToggle,
    required this.isZoneAlertEnabled,
    required this.onGeofenceToggle,
  });

  void _handleDrag(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta == null) return;

    if (delta > 6 && isExpanded) {
      onExpandedChanged(false);
    } else if (delta < -6 && !isExpanded) {
      onExpandedChanged(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _handleDrag,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: JorappColors.surface,
            border: const Border(
              top: BorderSide(color: JorappColors.surfaceStrong, width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: JorappColors.tealDark.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => onExpandedChanged(!isExpanded),
                    child: Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: JorappColors.teal.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Choisissez vos itinéraires',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: JorappColors.tealDark,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: JorappColors.tealDark,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.9,
                    children: [
                      LayerToggleCard(
                        label: 'Pédestre',
                        sublabel: '42 km',
                        iconData: Icons.directions_walk,
                        accentColor: const Color(0xFF2196F3),
                        initActive: true,
                        onToggle: onPedestreToggle,
                      ),
                      LayerToggleCard(
                        label: 'Cycliste',
                        sublabel: '28 km',
                        iconData: Icons.directions_bike,
                        accentColor: const Color(0xFFF59E0B),
                        initActive: true,
                        onToggle: onCyclisteToggle,
                      ),
                      LayerToggleCard(
                        label: 'Cavalier',
                        sublabel: '17 km',
                        iconData: Icons.pets_rounded,
                        accentColor: const Color(0xFF9C6FE4),
                        initActive: false,
                        onToggle: onCavalierToggle,
                      ),
                      const LayerToggleCard(
                        label: 'Nature',
                        sublabel: 'Bientôt',
                        iconData: Icons.eco_outlined,
                        accentColor: Color(0xFF9E9E9E),
                        initActive: false,
                        disabled: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: JorappColors.lime.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: JorappColors.teal.withOpacity(0.28),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: JorappColors.tealDark.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: JorappColors.surfaceStrong,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.crop_free,
                            size: 16,
                            color: JorappColors.tealDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Zone centrale',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: JorappColors.tealDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Activer l\'alerte lorsque je suis dans la zone protégée',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: JorappColors.tealDark.withOpacity(0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.72,
                          child: Switch(
                            value: isZoneAlertEnabled,
                            onChanged: onGeofenceToggle,
                            activeColor: JorappColors.tealDark,
                            activeTrackColor: JorappColors.lime.withOpacity(0.7),
                            inactiveThumbColor: JorappColors.tealDark
                                .withOpacity(0.35),
                            inactiveTrackColor: JorappColors.surfaceStrong,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
