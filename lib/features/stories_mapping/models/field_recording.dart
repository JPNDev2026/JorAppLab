import 'dart:convert';

enum SyncStatus { pending, uploading, synced, error }

// Sentinel pour distinguer "non fourni" de "null explicite" dans copyWith.
const Object _absent = Object();

class FieldRecording {
  final String id;
  final String filePath;
  final double latitude;
  final double longitude;
  final int durationSeconds;
  final DateTime recordedAt;
  final SyncStatus syncStatus;
  final String? remoteId;
  final String userId;
  final String userEmail;

  const FieldRecording({
    required this.id,
    required this.filePath,
    required this.latitude,
    required this.longitude,
    required this.durationSeconds,
    required this.recordedAt,
    required this.syncStatus,
    this.remoteId,
    required this.userId,
    required this.userEmail,
  });

  // ── Sérialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'latitude': latitude,
    'longitude': longitude,
    'durationSeconds': durationSeconds,
    'recordedAt': recordedAt.toIso8601String(),
    'syncStatus': syncStatus.name,
    'remoteId': remoteId,
    'userId': userId,
    'userEmail': userEmail,
  };

  factory FieldRecording.fromJson(Map<String, dynamic> json) => FieldRecording(
    id: json['id'] as String,
    filePath: json['filePath'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    durationSeconds: json['durationSeconds'] as int,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    syncStatus: SyncStatus.values.byName(json['syncStatus'] as String),
    remoteId: json['remoteId'] as String?,
    userId: json['userId'] as String,
    userEmail: json['userEmail'] as String,
  );

  /// Désérialise depuis une chaîne JSON brute (ex. valeur SharedPreferences).
  factory FieldRecording.fromJsonString(String raw) =>
      FieldRecording.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  // ── Mise à jour immutable ────────────────────────────────────────────────────

  /// [remoteId] utilise un sentinel pour permettre `copyWith(remoteId: null)`.
  FieldRecording copyWith({
    String? id,
    String? filePath,
    double? latitude,
    double? longitude,
    int? durationSeconds,
    DateTime? recordedAt,
    SyncStatus? syncStatus,
    Object? remoteId = _absent,
    String? userId,
    String? userEmail,
  }) =>
      FieldRecording(
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        recordedAt: recordedAt ?? this.recordedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        remoteId: identical(remoteId, _absent) ? this.remoteId : remoteId as String?,
        userId: userId ?? this.userId,
        userEmail: userEmail ?? this.userEmail,
      );
}
