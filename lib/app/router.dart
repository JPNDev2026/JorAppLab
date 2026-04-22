import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/auth/auth_service.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/stories_mapping/screens/recording_screen.dart';
import '../features/stories_mapping/screens/recordings_list_screen.dart';
import '../features/stories_mapping/services/recording_service.dart';
import '../features/stories_mapping/services/stories_local_datasource.dart';
import '../features/stories_mapping/services/sync_service.dart';
import '../features/welcome/screens/welcome_screen.dart';
import 'screens/web_unsupported_screen.dart';

class AppRouter {
  static const String welcome = '/welcome';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String stories = '/stories/record';
  static const String storiesList = '/stories/list';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required AuthService authService,
    required StoriesLocalDatasource storiesDatasource,
    required RecordingService recordingService,
    required SyncService syncService,
  }) {
    switch (settings.name) {
      case welcome:
        if (kIsWeb) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const WebUnsupportedScreen(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const WelcomeScreen(),
        );
      case landing:
        if (kIsWeb) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const WebUnsupportedScreen(),
          );
        }
        if (!authService.isLoggedIn) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LoginScreen(
              authService: authService,
              redirectRoute: AppRouter.stories,
            ),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RecordingScreen(
            authService: authService,
            recordingService: recordingService,
            syncService: syncService,
          ),
        );
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => LoginScreen(
            authService: authService,
            redirectRoute: (settings.arguments as String?) ?? AppRouter.stories,
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
      case stories:
        if (kIsWeb) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const WebUnsupportedScreen(),
          );
        }
        if (!authService.isLoggedIn) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LoginScreen(
              authService: authService,
              redirectRoute: AppRouter.stories,
            ),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RecordingScreen(
            authService: authService,
            recordingService: recordingService,
            syncService: syncService,
          ),
        );
      case storiesList:
        if (kIsWeb) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const WebUnsupportedScreen(),
          );
        }
        if (!authService.isLoggedIn) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LoginScreen(
              authService: authService,
              redirectRoute: AppRouter.storiesList,
            ),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RecordingsListScreen(
            datasource: storiesDatasource,
            syncService: syncService,
          ),
        );
      default:
        if (kIsWeb) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const WebUnsupportedScreen(),
          );
        }
        if (!authService.isLoggedIn) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LoginScreen(
              authService: authService,
              redirectRoute: AppRouter.stories,
            ),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RecordingScreen(
            authService: authService,
            recordingService: recordingService,
            syncService: syncService,
          ),
        );
    }
  }
}
