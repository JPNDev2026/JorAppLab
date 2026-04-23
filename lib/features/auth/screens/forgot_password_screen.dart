import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../theme/jorapp_theme.dart';
import '../auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthService authService;

  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _requestSent = false;

  final FocusNode _emailFocus = FocusNode();
  bool _emailFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(
      () => setState(() => _emailFocused = _emailFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.authService.requestPasswordReset(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _requestSent = true);
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
                        child: _requestSent ? _successView() : _formView(),
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

  Widget _formView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Illustration header
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: JorappColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: JorappColors.teal,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mot de passe oublié ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: JorappColors.tealDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrez votre email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: JorappColors.muted,
                height: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Tag pill
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
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
                    color: JorappColors.ink.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'RÉINITIALISATION SÉCURISÉE',
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
        // Email field
        _fieldLabel('EMAIL'),
        const SizedBox(height: 6),
        _styledEmailField(),
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
              disabledBackgroundColor: JorappColors.teal.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isSubmitting ? 'Envoi en cours...' : 'Envoyer le lien',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: JorappColors.muted),
          child: const Text(
            '← Retour à la connexion',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: JorappColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: JorappColors.teal,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Email envoyé !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: JorappColors.tealDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un email de réinitialisation a été envoyé à votre adresse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: JorappColors.muted,
                height: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: JorappColors.teal),
          child: const Text(
            '← Retour à la connexion',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
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

  Widget _styledEmailField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 42,
      decoration: BoxDecoration(
        color: _emailFocused ? Colors.white : JorappColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _emailFocused
              ? JorappColors.teal
              : JorappColors.teal.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: _emailFocused
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
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        onSubmitted: (_) => _submit(),
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
