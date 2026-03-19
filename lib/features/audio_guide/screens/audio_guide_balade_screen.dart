import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/jorapp_theme.dart';
import '../../geofencing/geofencing_controller.dart';
import '../../geofencing/models/location_sample.dart';
import '../models/audio_point.dart';
import '../models/balade.dart';

class AudioGuideBaladeScreen extends StatefulWidget {
  final Balade balade;
  final List<AudioPoint> points;
  final GeofencingController geofencingController;

  const AudioGuideBaladeScreen({
    super.key,
    required this.balade,
    required this.points,
    required this.geofencingController,
  });

  @override
  State<AudioGuideBaladeScreen> createState() => _AudioGuideBaladeScreenState();
}

class _AudioGuideBaladeScreenState extends State<AudioGuideBaladeScreen> {
  static const Distance _distance = Distance();

  @override
  void initState() {
    super.initState();
    widget.geofencingController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.geofencingController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  LatLng _initialCenter() {
    final latest = widget.geofencingController.latestSample;
    if (widget.points.isEmpty) {
      if (latest != null) {
        return LatLng(latest.latitude, latest.longitude);
      }
      return const LatLng(46.58, 6.67);
    }

    var latSum = 0.0;
    var lngSum = 0.0;
    for (final point in widget.points) {
      latSum += point.latCentre;
      lngSum += point.lngCentre;
    }
    return LatLng(
      latSum / widget.points.length,
      lngSum / widget.points.length,
    );
  }

  List<LatLng> _buildRadiusPolygon(AudioPoint point) {
    const segments = 48;
    return List<LatLng>.generate(segments, (index) {
      final bearing = 360 * (index / segments);
      return _distance.offset(
        LatLng(point.latCentre, point.lngCentre),
        point.rayonMetres,
        bearing,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final latestSample = widget.geofencingController.latestSample;
    final latestPoint = latestSample == null
        ? null
        : LatLng(latestSample.latitude, latestSample.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.balade.nom),
            Text(
              '${widget.points.length} point(s) audio',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF50616A),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAF5), Color(0xFFEAF2E3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FlutterMap(
                    options: MapOptions(
                      center: _initialCenter(),
                      zoom: 15,
                      rotation: 0,
                      interactiveFlags:
                          InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'ch.jorat.geofence',
                      ),
                      PolygonLayer(
                        polygons: widget.points
                            .map(
                              (point) => Polygon(
                                points: _buildRadiusPolygon(point),
                                borderColor: JorappColors.tealDark,
                                borderStrokeWidth: 2,
                                color: JorappColors.lime.withOpacity(0.22),
                                isFilled: true,
                              ),
                            )
                            .toList(),
                      ),
                      MarkerLayer(
                        markers: widget.points
                            .map(
                              (point) => Marker(
                                point: LatLng(point.latCentre, point.lngCentre),
                                width: 54,
                                height: 54,
                                child: GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${point.titre} • rayon ${point.rayonMetres.toStringAsFixed(0)} m',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: JorappColors.tealDark,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: JorappColors.lime,
                                            width: 2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x22000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.headphones_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (latestPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latestPoint,
                              width: 34,
                              height: 34,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: JorappColors.lime.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: JorappColors.lime,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                    color: JorappColors.tealDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _AudioGuideStatusCard(
                pointCount: widget.points.length,
                latestSample: latestSample,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioGuideStatusCard extends StatelessWidget {
  final int pointCount;
  final LocationSample? latestSample;

  const _AudioGuideStatusCard({
    required this.pointCount,
    required this.latestSample,
  });

  @override
  Widget build(BuildContext context) {
    final locationText = latestSample == null
        ? 'Aucune position GPS disponible pour le moment.'
        : 'Position actuelle: '
            '${latestSample!.latitude.toStringAsFixed(6)}, '
            '${latestSample!.longitude.toStringAsFixed(6)} '
            '• précision ${latestSample!.accuracyMeters.toStringAsFixed(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [JorappColors.teal, JorappColors.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: JorappColors.lime.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$pointCount zone(s) audio prêtes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            locationText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
