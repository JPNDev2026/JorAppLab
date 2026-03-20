import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/services/pb_client.dart';

class AuthService extends ChangeNotifier {
  final PocketBase pb = PbClient.instance.pb;
  late final StreamSubscription<AuthStoreEvent> _authSubscription =
      pb.authStore.onChange.listen((_) {
        notifyListeners();
      });

  bool get isLoggedIn => pb.authStore.isValid;
  RecordModel? get currentUser => pb.authStore.record;

  Future<void> login(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
      notifyListeners();
    } on ClientException {
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      final username = name.trim();
      await pb.collection('users').create(
        body: {
          'username': username,
          'email': email,
          'emailVisibility': true,
          'password': password,
          'passwordConfirm': password,
          'name': name,
        },
      );
      await login(email, password);
    } on ClientException {
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await pb.collection('users').requestPasswordReset(email);
    } on ClientException {
      rethrow;
    }
  }

  void logout() {
    pb.authStore.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
