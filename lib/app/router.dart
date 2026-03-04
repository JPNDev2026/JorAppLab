import 'package:flutter/material.dart';

import '../features/geofencing/geofencing_controller.dart';
import '../features/geofencing/screens/map_screen.dart';

class AppRouter {
  static const String home = '/';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required GeofencingController geofencingController,
  }) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MapScreen(geofencingController: geofencingController),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MapScreen(geofencingController: geofencingController),
        );
    }
  }
}
