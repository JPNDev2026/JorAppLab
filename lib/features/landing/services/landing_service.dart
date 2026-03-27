import '../../../core/services/pb_client.dart';
import '../models/restaurant.dart';

class LandingService {
  Future<List<Restaurant>> fetchRestaurants() async {
    final records = await PbClient.instance.pb
        .collection('restaurants')
        .getFullList();

    final restaurants = records.map(Restaurant.fromRecord).toList();
    restaurants.sort((a, b) {
      final ordreA = a.ordre ?? double.infinity;
      final ordreB = b.ordre ?? double.infinity;
      final orderCompare = ordreA.compareTo(ordreB);
      if (orderCompare != 0) return orderCompare;
      return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
    });

    return restaurants.where((restaurant) => restaurant.actif).toList();
  }
}
