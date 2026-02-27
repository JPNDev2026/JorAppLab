import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/jorapp_theme.dart';

class MapWidget extends StatefulWidget {
  final List<List<LatLng>> paths;
  final List<List<LatLng>> protectedAreas;
  final List<LatLng> recordedPoints;
  final LatLng? latestPoint;
  final LatLng? selectedPoint;
  final bool showPaths;
  final bool showProtectedAreas;

  const MapWidget({
    super.key,
    required this.paths,
    required this.protectedAreas,
    required this.recordedPoints,
    required this.latestPoint,
    required this.selectedPoint,
    required this.showPaths,
    required this.showProtectedAreas,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  String? _lastRenderLogKey;

  @override
  void initState() {
    super.initState();
    _focusPoint(widget.selectedPoint);
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDifferentPoint(oldWidget.selectedPoint, widget.selectedPoint)) {
      _focusPoint(widget.selectedPoint);
    }
  }

  bool _isDifferentPoint(LatLng? a, LatLng? b) {
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    return a.latitude != b.latitude || a.longitude != b.longitude;
  }

  void _focusPoint(LatLng? point) {
    if (point == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(point, 16);
    });
  }

  @override
  Widget build(BuildContext context) {
    final renderLogKey =
        'paths:${widget.paths.length}|polygons:${widget.protectedAreas.length}|'
        'showPaths:${widget.showPaths}|showProtected:${widget.showProtectedAreas}';
    if (_lastRenderLogKey != renderLogKey) {
      _lastRenderLogKey = renderLogKey;
      developer.log('[MapWidget] render $renderLogKey');
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: const LatLng(46.58, 6.67),
        zoom: 13,
        rotation: 0,
        interactiveFlags:
            InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ch.jorat.geofence',
        ),

        // 🔴 Zone protégée (SOUS les chemins)
        if (widget.showProtectedAreas)
          PolygonLayer(
            polygons: widget.protectedAreas
                .map(
                  (polygon) => Polygon(
                    points: polygon,
                    borderColor: JorappColors.tealDark,
                    borderStrokeWidth: 2,
                    color: JorappColors.lime.withOpacity(0.30),
                    isFilled: true,
                  ),
                )
                .toList(),
          ),

        // 🟤 Chemins
        if (widget.showPaths)
          PolylineLayer(
            polylines: widget.paths
                .map(
                  (line) => Polyline(
                    points: line,
                    color: JorappColors.tealDark,
                    strokeWidth: 3.2,
                  ),
                )
                .toList(),
          ),

        if (widget.recordedPoints.isNotEmpty)
          MarkerLayer(
            markers: widget.recordedPoints
                .map(
                  (point) => Marker(
                    point: point,
                    width: 8,
                    height: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: JorappColors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

        if (widget.latestPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.latestPoint!,
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: JorappColors.lime.withOpacity(0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: JorappColors.lime, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.my_location,
                      size: 12,
                      color: JorappColors.tealDark,
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (widget.selectedPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.selectedPoint!,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: JorappColors.teal.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: JorappColors.tealDark, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.place,
                      size: 16,
                      color: JorappColors.tealDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
