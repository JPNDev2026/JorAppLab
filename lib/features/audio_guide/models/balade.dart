import 'package:pocketbase/pocketbase.dart';

import '../../../core/constants.dart';

class Balade {
  final String id;
  final String collectionId;
  final String nom;
  final String? description;
  final String? coverUrl;
  final bool actif;

  const Balade({
    required this.id,
    required this.collectionId,
    required this.nom,
    required this.description,
    required this.coverUrl,
    required this.actif,
  });

  factory Balade.fromRecord(RecordModel r) {
    final cover = r.getStringValue('cover');

    return Balade(
      id: r.id,
      collectionId: r.collectionId,
      nom: r.getStringValue('nom'),
      description: r.getStringValue('description').isEmpty
          ? null
          : r.getStringValue('description'),
      coverUrl: cover.isEmpty
          ? null
          : '${AppConstants.pbUrl}/api/files/${r.collectionId}/${r.id}/$cover',
      actif: r.getBoolValue('actif'),
    );
  }
}
