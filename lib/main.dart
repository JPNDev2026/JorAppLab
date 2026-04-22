import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/pb_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PbClient.instance.init();
  runApp(const App());
}
