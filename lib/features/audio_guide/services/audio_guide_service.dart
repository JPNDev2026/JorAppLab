import 'dart:io';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/pb_client.dart';
import '../models/audio_point.dart';
import '../models/balade.dart';

class AudioGuideService {
  Future<List<Balade>> fetchBalades() async {
    final pb = PbClient.instance.pb;
    developer.log(
      '[AudioGuideService] fetchBalades start '
      'baseUrl=${pb.baseURL} '
      'authValid=${pb.authStore.isValid} '
      'tokenPresent=${pb.authStore.token.isNotEmpty}',
    );
    final result = await pb.collection('balades').getList(
      filter: 'actif = true',
      sort: 'nom',
    );
    developer.log(
      '[AudioGuideService] fetchBalades active count=${result.items.length}',
    );

    if (result.items.isNotEmpty) {
      return result.items.map(Balade.fromRecord).toList();
    }

    final fallback = await pb.collection('balades').getList(
      sort: 'nom',
    );
    developer.log(
      '[AudioGuideService] fetchBalades fallback count=${fallback.items.length}',
    );
    return fallback.items.map(Balade.fromRecord).toList();
  }

  Future<List<AudioPoint>> fetchAudioPoints(String baladeId) async {
    final result = await PbClient.instance.pb.collection('audio_points').getList(
      filter: "balade = '$baladeId'",
      sort: 'ordre',
    );

    return result.items.map(AudioPoint.fromRecord).toList();
  }

  Future<List<AudioPoint>> downloadBalade(
    String baladeId,
    List<AudioPoint> points,
    void Function(double progress) onProgress,
  ) async {
    final sortedPoints = [...points]..sort((a, b) => a.ordre.compareTo(b.ordre));
    final docsDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${docsDir.path}/audio_guide/$baladeId');
    final token = PbClient.instance.pb.authStore.token;

    var treated = 0;

    for (final point in sortedPoints) {
      final filePath = '${baseDir.path}/${point.id}.mp3';
      final file = File(filePath);

      if (await file.exists()) {
        point.localPath = filePath;
        treated++;
        onProgress(treated / sortedPoints.length);
        continue;
      }

      final response = await http.get(
        Uri.parse(point.mp3Url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Téléchargement impossible (${response.statusCode}) pour ${point.id}',
        );
      }

      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      point.localPath = filePath;

      treated++;
      onProgress(treated / sortedPoints.length);
    }

    return sortedPoints;
  }

  Future<bool> isBaladeDownloaded(String baladeId, List<AudioPoint> points) async {
    final docsDir = await getApplicationDocumentsDirectory();

    for (final point in points) {
      final file = File('${docsDir.path}/audio_guide/$baladeId/${point.id}.mp3');
      if (!await file.exists()) {
        return false;
      }
    }

    return true;
  }

  Future<void> deleteLocalBalade(String baladeId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/audio_guide/$baladeId');

    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
