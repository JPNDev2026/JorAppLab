import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/pb_client.dart';
import 'features/coming_soon/coming_soon_app.dart';

Future<void> main() async {
  if (kIsWeb) {
    runApp(const ComingSoonApp());
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  await PbClient.instance.init();
  runApp(const App());
}
