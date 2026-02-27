import 'package:flutter/material.dart';

import '../screens/map_screen.dart';
import '../services/tracking_controller.dart';

class JoratApp extends StatefulWidget {
  const JoratApp({super.key});

  @override
  State<JoratApp> createState() => _JoratAppState();
}

class _JoratAppState extends State<JoratApp> {
  final TrackingController _trackingController = TrackingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _trackingController.initialize(autoStart: true);
    });
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jorat',
      theme: ThemeData(useMaterial3: true),
      home: MapScreen(trackingController: _trackingController),
    );
  }
}
