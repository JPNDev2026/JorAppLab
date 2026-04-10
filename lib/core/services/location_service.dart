import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';

/// Singleton centralisant toute la logique Geolocator.
/// Accès via [LocationService.instance].
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // ── Permission ───────────────────────────────────────────────────────────────

  /// Vérifie et demande la permission GPS si nécessaire.
  /// - Si [denied] : demande via [Geolocator.requestPermission].
  /// - Si [deniedForever] : ouvre les réglages de l'app.
  /// Retourne [true] si la permission est [whileInUse] ou [always].
  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      developer.log('[LocationService] permission deniedForever → openAppSettings');
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── Position ponctuelle ──────────────────────────────────────────────────────

  /// Retourne la position courante avec [LocationAccuracy.high].
  /// Retourne [null] si le service GPS est désactivé ou la permission refusée.
  Future<Position?> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      developer.log('[LocationService] service GPS désactivé');
      return null;
    }
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      developer.log('[LocationService] permission GPS refusée');
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      developer.log('[LocationService] getCurrentPosition error: $e');
      return null;
    }
  }

  // ── Flux de positions ────────────────────────────────────────────────────────

  /// Stream de positions continues avec [LocationAccuracy.high].
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ── Statut du service GPS ────────────────────────────────────────────────────

  /// Stream du statut du service GPS système ([enabled] / [disabled]).
  Stream<ServiceStatus> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }

  // ── Ouverture des réglages ───────────────────────────────────────────────────

  /// Ouvre les réglages de l'application (pour permission [deniedForever]).
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Ouvre les réglages GPS du système (pour service désactivé).
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
