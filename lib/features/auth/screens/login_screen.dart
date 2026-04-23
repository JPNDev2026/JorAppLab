import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../app/router.dart';
import '../../../theme/jorapp_theme.dart';
import '../auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final String? redirectRoute;

  const LoginScreen({
    super.key,
    required this.authService,
    this.redirectRoute,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(
      () => setState(() => _emailFocused = _emailFocus.hasFocus),
    );
    _passwordFocus.addListener(
      () => setState(() => _passwordFocused = _passwordFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        widget.redirectRoute ?? AppRouter.stories,
      );
    } on ClientException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_clientExceptionMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 48),
                      // Logo zone
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),                         
                        ),
                        child: Image.asset(
                          'assets/branding/jorapp_logo.png',
                          width: 80,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'JORAPP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3,
                          color: JorappColors.muted,
                        ),
                      ),
                      // Form card
                      Container(
                        margin: const EdgeInsets.only(
                          top: 20,
                          left: 16,
                          right: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: JorappColors.ink.withValues(alpha: 0.09),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tag pill
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: JorappColors.lime,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: JorappColors.ink.withValues(alpha: 
                                          0.4,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'ESPACE PERSONNEL',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: JorappColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Text(
                              'Connexion',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: JorappColors.tealDark,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel('EMAIL'),
                            const SizedBox(height: 6),
                            _styledField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              focused: _emailFocused,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('MOT DE PASSE'),
                            const SizedBox(height: 6),
                            _styledField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              focused: _passwordFocused,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 20),
                            // Submit button
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: JorappColors.teal.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: JorappColors.teal,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      JorappColors.teal.withValues(alpha: 0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _isSubmitting
                                      ? 'Connexion...'
                                      : 'Se connecter',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pushNamed(
                                        context,
                                        '/register',
                                        arguments: widget.redirectRoute,
                                      ),
                              style: TextButton.styleFrom(
                                foregroundColor: JorappColors.teal,
                              ),
                              child: const Text(
                                'Créer un compte',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pushNamed(
                                        context,
                                        '/forgot-password',
                                        arguments: widget.redirectRoute,
                                      ),
                              style: TextButton.styleFrom(
                                foregroundColor: JorappColors.muted,
                              ),
                              child: const Text(
                                'Mot de passe oublié',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
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
    ValueChanged<String>? onSubmitted,
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
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 14, color: JorappColors.ink),
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

  String _clientExceptionMessage(ClientException e) {
    final response = e.response;
    if (response is Map<String, dynamic>) {
      final message = response['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return e.toString();
  }
}
