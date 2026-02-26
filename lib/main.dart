import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'services/tracking_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TrackingController _trackingController = TrackingController();

  @override
  void initState() {
    super.initState();
    _trackingController.initialize(autoStart: true);
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
      home: MapScreen(trackingController: _trackingController),
    );
  }
}
