import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

import '../constants.dart';

class PbClient {
  PbClient._();

  static final PbClient _instance = PbClient._();

  static PbClient get instance => _instance;

  static const _storage = FlutterSecureStorage();

  late final PocketBase pb = PocketBase(
    AppConstants.pbUrl,
    authStore: AsyncAuthStore(
      save: (token) async => _storage.write(key: 'pb_auth', value: token),
      initial: null,
    ),
  );

  Future<void> init() async {
    final saved = await _storage.read(key: 'pb_auth');
    if (saved != null) {
      pb.authStore.save(saved, null);
    }
  }
}
