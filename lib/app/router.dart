import 'package:flutter/material.dart';

import '../features/auth/auth_service.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/geofencing/geofencing_controller.dart';
import '../features/geofencing/screens/map_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required AuthService authService,
    required GeofencingController geofencingController,
  }) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MapScreen(
            authService: authService,
            geofencingController: geofencingController,
          ),
        );
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => LoginScreen(authService: authService),
        );
      case register:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RegisterScreen(authService: authService),
        );
      case forgotPassword:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ForgotPasswordScreen(authService: authService),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MapScreen(
            authService: authService,
            geofencingController: geofencingController,
          ),
        );
    }
  }
}
