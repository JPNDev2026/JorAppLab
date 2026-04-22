import 'package:flutter/material.dart';

import '../../features/auth/auth_service.dart';
import '../../theme/jorapp_theme.dart';
import '../router.dart';

class JorappDrawer extends StatelessWidget {
  final AuthService authService;
  final Future<void> Function(String routeName, {Object? arguments}) onNavigate;

  const JorappDrawer({
    super.key,
    required this.authService,
    required this.onNavigate,
  });

  String _displayName() {
    final user = authService.currentUser;
    if (user == null) return 'Visiteur';

    final name = user.getStringValue('name').trim();
    if (name.isNotEmpty) return name;

    final email = user.getStringValue('email').trim();
    if (email.isNotEmpty) return email;

    final rawEmail = user.data['email']?.toString().trim() ?? '';
    return rawEmail.isNotEmpty ? rawEmail : 'Visiteur';
  }

  String _initialForAvatar() {
    final label = _displayName().trim();
    if (label.isEmpty || label == 'Visiteur') return 'V';
    return label.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: ListenableBuilder(
        listenable: authService,
        builder: (context, _) {
          final isLoggedIn = authService.isLoggedIn;
          final displayName = _displayName();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [JorappColors.teal, JorappColors.tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: isLoggedIn
                          ? JorappColors.lime
                          : Colors.white.withValues(alpha: 0.2),
                      child: isLoggedIn
                          ? Text(
                              _initialForAvatar(),
                              style: const TextStyle(
                                color: JorappColors.tealDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            isLoggedIn ? FontWeight.w700 : FontWeight.w400,
                        fontStyle:
                            isLoggedIn ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.mic_rounded,
                  color: JorappColors.tealDark,
                  size: 28,
                ),
                title: const Text(
                  'Récits de terrain',
                  style: TextStyle(color: JorappColors.ink, fontSize: 15),
                ),
                onTap: () => onNavigate(AppRouter.stories),
              ),
              const Spacer(),
              const Divider(height: 1),
              if (!isLoggedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => onNavigate(AppRouter.login),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Se connecter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: JorappColors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        authService.logout();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Se déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: JorappColors.tealDark,
                        side: const BorderSide(color: JorappColors.teal),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
