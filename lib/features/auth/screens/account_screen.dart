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
      backgroundColor: JorappColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    JorappColors.teal.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header custom
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: JorappColors.teal,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mon compte',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: JorappColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: ListenableBuilder(
                    listenable: authService,
                    builder: (context, _) {
                      final user = authService.currentUser;
                      if (user == null) return const SizedBox.shrink();
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        children: [
                          _NameSection(authService: authService, user: user),
                          const SizedBox(height: 12),
                          _EmailSection(authService: authService, user: user),
                          const SizedBox(height: 12),
                          _PasswordSection(authService: authService),
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: JorappColors.ink.withValues(alpha: 0.06),
                          ),
                          // Bouton Se déconnecter
                          Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 16),
                            height: 46,
                            child: TextButton(
                              onPressed: () {
                                authService.logout();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRouter.login,
                                  (route) => false,
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: JorappColors.danger.withValues(
                                  alpha: 0.04,
                                ),
                                foregroundColor: JorappColors.danger,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: JorappColors.danger.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 14,
                                    color: JorappColors.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Se déconnecter',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: JorappColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final FocusNode _focus = FocusNode();
  bool _focused = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.user.getStringValue('name'));
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('NOM'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _styledField(
                  controller: _ctrl,
                  focusNode: _focus,
                  focused: _focused,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
              ),
              const SizedBox(width: 8),
              _SaveButton(
                onPressed: _submitting ? null : _save,
                loading: _submitting,
              ),
            ],
          ),
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
  final FocusNode _focus = FocusNode();
  bool _focused = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.user.getStringValue('email'));
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('EMAIL'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _styledField(
                  controller: _ctrl,
                  focusNode: _focus,
                  focused: _focused,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              _SaveButton(
                onPressed: _submitting ? null : _save,
                loading: _submitting,
              ),
            ],
          ),
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
  final FocusNode _oldFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  bool _oldFocused = false;
  bool _newFocused = false;
  bool _confirmFocused = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _oldFocus.addListener(() => setState(() => _oldFocused = _oldFocus.hasFocus));
    _newFocus.addListener(() => setState(() => _newFocused = _newFocus.hasFocus));
    _confirmFocus.addListener(
      () => setState(() => _confirmFocused = _confirmFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (_newCtrl.text != _confirmCtrl.text) {
      _showSnack(
        context,
        'Les mots de passe ne correspondent pas.',
        error: true,
      );
      return;
    }
    if (_newCtrl.text.length < 8) {
      _showSnack(
        context,
        'Le mot de passe doit contenir au moins 8 caractères.',
        error: true,
      );
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel('ACTUEL'),
          const SizedBox(height: 6),
          _styledField(
            controller: _oldCtrl,
            focusNode: _oldFocus,
            focused: _oldFocused,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _fieldLabel('NOUVEAU'),
          const SizedBox(height: 6),
          _styledField(
            controller: _newCtrl,
            focusNode: _newFocus,
            focused: _newFocused,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _fieldLabel('CONFIRMATION'),
          const SizedBox(height: 6),
          _styledField(
            controller: _confirmCtrl,
            focusNode: _confirmFocus,
            focused: _confirmFocused,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          _SaveButton(
            onPressed: _submitting ? null : _save,
            loading: _submitting,
            fullWidth: true,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JorappColors.lime, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: JorappColors.ink.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: JorappColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: JorappColors.teal.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;

  const _SaveButton({
    required this.onPressed,
    required this.loading,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: JorappColors.teal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: JorappColors.teal.withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fullWidth ? 14 : 10),
        ),
        padding: fullWidth
            ? null
            : const EdgeInsets.symmetric(horizontal: 14),
        minimumSize: fullWidth
            ? const Size(double.infinity, 46)
            : const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          : Text(
              'Enregistrer',
              style: TextStyle(
                fontSize: fullWidth ? 14 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    if (fullWidth) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: JorappColors.teal.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: button,
      );
    }

    return button;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _fieldLabel(String label) {
  return Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: JorappColors.muted,
    ),
  );
}

Widget _styledField({
  required TextEditingController controller,
  required FocusNode focusNode,
  required bool focused,
  TextInputType? keyboardType,
  bool obscureText = false,
  TextInputAction? textInputAction,
  ValueChanged<String>? onSubmitted,
  double? fontSize,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    height: 42,
    decoration: BoxDecoration(
      color: focused ? Colors.white : JorappColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: focused
            ? JorappColors.teal
            : JorappColors.teal.withValues(alpha: 0.15),
        width: 1.5,
      ),
      boxShadow: focused
          ? [
              BoxShadow(
                color: JorappColors.teal.withValues(alpha: 0.08),
                blurRadius: 0,
                spreadRadius: 3,
              ),
            ]
          : [],
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: fontSize ?? 12, color: JorappColors.ink),
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    ),
  );
}

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
