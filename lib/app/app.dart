import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/auth_service.dart';
import '../features/geofencing/geofencing_controller.dart';
import '../features/geofencing/services/tracking_controller.dart';
import '../features/welcome/screens/welcome_screen.dart';
import 'router.dart';
import 'theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final TrackingController _trackingController = TrackingController();
  late final GeofencingController _geofencingController =
      GeofencingController(trackingController: _trackingController);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_trackingController.forceAutoSave());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_trackingController.forceAutoSave());
    _authService.dispose();
    _geofencingController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JORAPP',
      theme: buildAppTheme(),
      home: const WelcomeScreen(),
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        authService: _authService,
        geofencingController: _geofencingController,
      ),
    );
  }
}
