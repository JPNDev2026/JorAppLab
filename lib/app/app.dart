import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/auth_service.dart';
import '../features/geofencing/geofencing_controller.dart';
import '../features/geofencing/services/tracking_controller.dart';
import '../features/stories_mapping/services/recording_service.dart';
import '../features/stories_mapping/services/stories_local_datasource.dart';
import '../features/stories_mapping/services/sync_service.dart';
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

  final StoriesLocalDatasource _storiesDatasource = StoriesLocalDatasource();
  late final RecordingService _recordingService =
      RecordingService(datasource: _storiesDatasource);
  late final SyncService _syncService =
      SyncService(datasource: _storiesDatasource);

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
    _recordingService.dispose();
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JORAPP',
      theme: buildAppTheme(),
      initialRoute:
          _authService.isLoggedIn ? AppRouter.stories : AppRouter.welcome,
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        authService: _authService,
        storiesDatasource: _storiesDatasource,
        recordingService: _recordingService,
        syncService: _syncService,
      ),
    );
  }
}
