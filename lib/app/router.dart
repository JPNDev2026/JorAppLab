import 'package:flutter/material.dart';

import '../features/auth/auth_service.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/audio_guide/screens/audio_guide_screen.dart';
import '../features/geofencing/geofencing_controller.dart';
import '../features/geofencing/screens/map_screen.dart';
import '../features/landing/screens/landing_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/welcome/screens/welcome_screen.dart';

class AppRouter {
  static const String welcome = '/welcome';
  static const String home = '/';
  static const String map = '/map';
  static const String landing = '/landing';
  static const String audioGuide = '/audio-guide';
  static const String partenaires = '/partenaires';
  static const String orientation = '/orientation';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required AuthService authService,
    required GeofencingController geofencingController,
  }) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const WelcomeScreen(),
        );
      case landing:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => LandingScreen(
            authService: authService,
            geofencingController: geofencingController,
          ),
        );
      case map:
      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MapScreen(
            authService: authService,
            geofencingController: geofencingController,
          ),
        );
      case partenaires:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _PlaceholderScreen(
            title: 'Découvertes',
            icon: Icons.explore_rounded,
            message: 'Cet écran sera branché dans l’étape suivante.',
          ),
        );
      case orientation:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => OrientationMapScreen(
            geofencingController: geofencingController,
          ),
        );
      case audioGuide:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AudioGuideScreen(
            geofencingController: geofencingController,
          ),
        );
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => LoginScreen(
            authService: authService,
            redirectRoute: settings.arguments as String?,
          ),
        );
      case register:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RegisterScreen(
            authService: authService,
            redirectRoute: settings.arguments as String?,
          ),
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: const Color(0xFF15495F)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
