import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

import '../constants.dart';

class PbClient {
  PbClient._();

  static final PbClient _instance = PbClient._();

  static PbClient get instance => _instance;

  static const _storage = FlutterSecureStorage();

  late PocketBase pb;

  Future<void> init() async {
    if (kIsWeb) {
      pb = PocketBase(AppConstants.pbUrl);
      return;
    }
    final saved = await _storage.read(key: 'pb_auth');
    pb = PocketBase(
      AppConstants.pbUrl,
      authStore: AsyncAuthStore(
        save: (data) async => _storage.write(key: 'pb_auth', value: data),
        initial: saved,
      ),
    );
  }
}
