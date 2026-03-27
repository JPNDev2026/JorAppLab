import 'package:pocketbase/pocketbase.dart';

import '../../../core/constants.dart';

class Restaurant {
  final String id;
  final String collectionId;
  final String nom;
  final String? descriptionCourte;
  final String? coverUrl;
  final bool actif;
  final double? ordre;

  const Restaurant({
    required this.id,
    required this.collectionId,
    required this.nom,
    required this.descriptionCourte,
    required this.coverUrl,
    required this.actif,
    required this.ordre,
  });

  factory Restaurant.fromRecord(RecordModel r) {
    final cover = r.getStringValue('cover');
    final description =
        r.getStringValue('short_description').isNotEmpty
        ? r.getStringValue('short_description')
        : r.getStringValue('description_courte').isNotEmpty
        ? r.getStringValue('description_courte')
        : r.getStringValue('sort_description');

    return Restaurant(
      id: r.id,
      collectionId: r.collectionId,
      nom: r.getStringValue('nom'),
      descriptionCourte: description.isEmpty ? null : description,
      coverUrl: cover.isEmpty
          ? null
          : '${AppConstants.pbUrl}/api/files/${r.collectionId}/${r.id}/$cover',
      actif: r.getBoolValue('actif'),
      ordre: r.data['ordre'] is num ? (r.data['ordre'] as num).toDouble() : null,
    );
  }
}
