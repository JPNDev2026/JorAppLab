import 'package:pocketbase/pocketbase.dart';

import '../../../core/constants.dart';

class AudioPoint {
  final String id;
  final String collectionId;
  final String baladeId;
  final String titre;
  final double latCentre;
  final double lngCentre;
  final double rayonMetres;
  final int ordre;
  final String mp3Url;
  String? localPath;

  AudioPoint({
    required this.id,
    required this.collectionId,
    required this.baladeId,
    required this.titre,
    required this.latCentre,
    required this.lngCentre,
    required this.rayonMetres,
    required this.ordre,
    required this.mp3Url,
    this.localPath,
  });

  factory AudioPoint.fromRecord(RecordModel r) {
    final fileName = r.getStringValue('fichier_mp3');

    return AudioPoint(
      id: r.id,
      collectionId: r.collectionId,
      baladeId: r.getStringValue('balade'),
      titre: r.getStringValue('titre'),
      latCentre: r.getDoubleValue('lat_centre'),
      lngCentre: r.getDoubleValue('lng_centre'),
      rayonMetres: r.getDoubleValue('rayon_metres'),
      ordre: r.getIntValue('ordre'),
      mp3Url:
          '${AppConstants.pbUrl}/api/files/${r.collectionId}/${r.id}/$fileName',
    );
  }
}
