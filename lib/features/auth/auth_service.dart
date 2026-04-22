import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/services/pb_client.dart';

class AuthService extends ChangeNotifier {
  final PocketBase pb;
  late final StreamSubscription<AuthStoreEvent> _authSubscription =
      pb.authStore.onChange.listen((_) {
        notifyListeners();
      });

  AuthService({PocketBase? pocketBase}) : pb = pocketBase ?? PbClient.instance.pb;

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

  Future<void> updateName(String name) async {
    final id = currentUser!.id;
    await pb.collection('users').update(id, body: {'name': name.trim()});
    await pb.collection('users').authRefresh();
    notifyListeners();
  }

  Future<void> updateEmail(String email) async {
    final id = currentUser!.id;
    await pb.collection('users').update(id, body: {
      'email': email.trim(),
      'emailVisibility': true,
    });
    await pb.collection('users').authRefresh();
    notifyListeners();
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final id = currentUser!.id;
    final email = currentUser!.getStringValue('email');
    await pb.collection('users').update(id, body: {
      'password': newPassword,
      'passwordConfirm': newPassword,
      'oldPassword': oldPassword,
    });
    await login(email, newPassword);
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
