import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

class GeoJsonService {
  static Future<Map<String, dynamic>> _loadJsonMap(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final jsonText = utf8.decode(bytes);
    final decoded = json.decode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GeoJSON invalide: racine non objet');
    }
    return decoded;
  }

  /// =========================
  /// LIGNES (chemins)
  /// =========================
  static Future<List<List<LatLng>>> loadPaths(String assetPath) async {
    developer.log('[GeoJsonService] loadPaths start: $assetPath');
    final jsonData = await _loadJsonMap(assetPath);

    final List<List<LatLng>> paths = [];

    final features = jsonData['features'];
    if (features is! List) {
      throw const FormatException('GeoJSON invalide: "features" absent');
    }

    for (final feature in features) {
      if (feature is! Map) continue;
      final geometry = feature['geometry'];
      if (geometry is! Map) continue;

      final type = geometry['type'];
      final coords = geometry['coordinates'];

      if (type == 'LineString') {
        paths.add(_parseLine(coords));
      } else if (type == 'MultiLineString') {
        for (final line in coords) {
          paths.add(_parseLine(line));
        }
      }
    }

    developer.log(
      '[GeoJsonService] loadPaths done: ${paths.length} lignes depuis $assetPath',
    );
    return paths;
  }

  static List<LatLng> _parseLine(List coords) {
    return coords
        .where((p) => p is List && p.length >= 2)
        .map<LatLng>((p) => LatLng(
              (p[1] as num).toDouble(),
              (p[0] as num).toDouble(),
            ))
        .toList();
  }

  /// =========================
  /// POLYGONES (aires protégées)
  /// =========================
  static Future<List<List<LatLng>>> loadPolygons(String assetPath) async {
    developer.log('[GeoJsonService] loadPolygons start: $assetPath');
    final jsonData = await _loadJsonMap(assetPath);

    final List<List<LatLng>> polygons = [];
    int polygonFeatures = 0;
    int multiPolygonFeatures = 0;

    final features = jsonData['features'];
    if (features is! List) {
      throw const FormatException('GeoJSON invalide: "features" absent');
    }

    for (final feature in features) {
      if (feature is! Map) continue;
      final geometry = feature['geometry'];
      if (geometry is! Map) continue;

      final type = geometry['type'];
      final coords = geometry['coordinates'];

      if (type == 'Polygon') {
        polygonFeatures++;
        _parsePolygon(coords, polygons);
      } else if (type == 'MultiPolygon') {
        multiPolygonFeatures++;
        for (final polygon in coords) {
          _parsePolygon(polygon, polygons);
        }
      }
    }

    developer.log(
      '[GeoJsonService] loadPolygons done: ${polygons.length} polygones '
      '(features Polygon=$polygonFeatures, MultiPolygon=$multiPolygonFeatures) '
      'depuis $assetPath',
    );
    if (polygons.isNotEmpty) {
      final first = polygons.first.first;
      developer.log(
        '[GeoJsonService] first polygon first point: lat=${first.latitude}, lon=${first.longitude}',
      );
    }
    return polygons;
  }

  static void _parsePolygon(
    List polygonCoords,
    List<List<LatLng>> output,
  ) {
    if (polygonCoords.isEmpty) return;

    // Anneau extérieur uniquement (GeoJSON spec)
    final exteriorRing = polygonCoords[0];

    final List<LatLng> polygon = [];

    for (final p in exteriorRing) {
      if (p is List && p.length >= 2) {
        polygon.add(
          LatLng(
            (p[1] as num).toDouble(),
            (p[0] as num).toDouble(),
          ),
        );
      }
    }

    if (polygon.length >= 3) {
      output.add(polygon);
    } else {
      developer.log(
        '[GeoJsonService] polygon ignore: moins de 3 points (${polygon.length})',
      );
    }
  }
}
