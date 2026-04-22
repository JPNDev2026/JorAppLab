import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../app/router.dart';
import '../../../theme/jorapp_theme.dart';
import '../auth_service.dart';

class AccountScreen extends StatelessWidget {
  final AuthService authService;

  const AccountScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon compte',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: authService,
        builder: (context, _) {
          final user = authService.currentUser;
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _NameSection(authService: authService, user: user),
              const SizedBox(height: 16),
              _EmailSection(authService: authService, user: user),
              const SizedBox(height: 16),
              _PasswordSection(authService: authService),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  authService.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.login,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Nom ───────────────────────────────────────────────────────────────────────

class _NameSection extends StatefulWidget {
  final AuthService authService;
  final dynamic user;

  const _NameSection({required this.authService, required this.user});

  @override
  State<_NameSection> createState() => _NameSectionState();
}

class _NameSectionState extends State<_NameSection> {
  late final TextEditingController _ctrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.user.getStringValue('name'),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.authService.updateName(_ctrl.text);
      if (!mounted) return;
      _showSnack(context, 'Nom mis à jour.');
    } on ClientException catch (e) {
      if (!mounted) return;
      _showSnack(context, _pbMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Nom d'utilisateur",
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(width: 12),
          _SaveButton(onPressed: _submitting ? null : _save, loading: _submitting),
        ],
      ),
    );
  }
}

// ── Email ─────────────────────────────────────────────────────────────────────

class _EmailSection extends StatefulWidget {
  final AuthService authService;
  final dynamic user;

  const _EmailSection({required this.authService, required this.user});

  @override
  State<_EmailSection> createState() => _EmailSectionState();
}

class _EmailSectionState extends State<_EmailSection> {
  late final TextEditingController _ctrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.user.getStringValue('email'),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.authService.updateEmail(_ctrl.text);
      if (!mounted) return;
      _showSnack(context, 'Email mis à jour.');
    } on ClientException catch (e) {
      if (!mounted) return;
      _showSnack(context, _pbMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Adresse email',
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(width: 12),
          _SaveButton(onPressed: _submitting ? null : _save, loading: _submitting),
        ],
      ),
    );
  }
}

// ── Mot de passe ──────────────────────────────────────────────────────────────

class _PasswordSection extends StatefulWidget {
  final AuthService authService;

  const _PasswordSection({required this.authService});

  @override
  State<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends State<_PasswordSection> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (_newCtrl.text != _confirmCtrl.text) {
      _showSnack(context, 'Les mots de passe ne correspondent pas.', error: true);
      return;
    }
    if (_newCtrl.text.length < 8) {
      _showSnack(context, 'Le mot de passe doit contenir au moins 8 caractères.', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.authService.updatePassword(_oldCtrl.text, _newCtrl.text);
      if (!mounted) return;
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      _showSnack(context, 'Mot de passe mis à jour.');
    } on ClientException catch (e) {
      if (!mounted) return;
      _showSnack(context, _pbMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Mot de passe',
      child: Column(
        children: [
          TextField(
            controller: _oldCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _SaveButton(
              onPressed: _submitting ? null : _save,
              loading: _submitting,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JorappColors.tealDark,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const _SaveButton({required this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: JorappColors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(72, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Enregistrer'),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? JorappColors.tealDark : JorappColors.teal,
    ),
  );
}

String _pbMessage(ClientException e) {
  final message = e.response['message'];
  if (message is String && message.isNotEmpty) return message;
  return e.toString();
}
