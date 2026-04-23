import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../app/router.dart';
import '../../../theme/jorapp_theme.dart';
import '../auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  final String? redirectRoute;

  const RegisterScreen({
    super.key,
    required this.authService,
    this.redirectRoute,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isSubmitting = false;
  bool _termsAccepted = false;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _confirmFocused = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(
      () => setState(() => _nameFocused = _nameFocus.hasFocus),
    );
    _emailFocus.addListener(
      () => setState(() => _emailFocused = _emailFocus.hasFocus),
    );
    _passwordFocus.addListener(
      () => setState(() => _passwordFocused = _passwordFocus.hasFocus),
    );
    _confirmFocus.addListener(
      () => setState(() => _confirmFocused = _confirmFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le champ Nom est obligatoire.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
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
    final bool canSubmit = _termsAccepted && !_isSubmitting;

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
                      const SizedBox(height: 32),
                      // Logo zone compact — pas de label "JORAPP"
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Image.asset(
                          'assets/branding/jorapp_logo.png',
                          width: 46,
                          height: 53,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Form card
                      Container(
                        margin: const EdgeInsets.only(
                          top: 14,
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
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Créer un compte',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: JorappColors.tealDark,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel('NOM'),
                            const SizedBox(height: 6),
                            _styledField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              focused: _nameFocused,
                            ),
                            const SizedBox(height: 16),
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
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('CONFIRMATION'),
                            const SizedBox(height: 6),
                            _styledField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmFocus,
                              focused: _confirmFocused,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 12),
                            // Checkbox CGU
                            _TermsCheckbox(
                              accepted: _termsAccepted,
                              onChanged: (v) =>
                                  setState(() => _termsAccepted = v ?? false),
                              onReadTerms: () => _showTermsSheet(context),
                            ),
                            // Bouton
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: canSubmit
                                    ? [
                                        BoxShadow(
                                          color: JorappColors.teal.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    (_isSubmitting || !_termsAccepted)
                                        ? null
                                        : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: JorappColors.teal,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      JorappColors.teal.withValues(alpha: 0.2),
                                  disabledForegroundColor: JorappColors.muted,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _isSubmitting
                                      ? 'Création en cours...'
                                      : 'Créer mon compte',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: JorappColors.teal,
                              ),
                              child: const Text(
                                'Déjà un compte',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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

  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _TermsSheet(),
    );
  }

  String _clientExceptionMessage(ClientException e) {
    final response = e.response;
    if (response is Map<String, dynamic>) {
      final message = response['message'];
      if (message is String && message.isNotEmpty) {
        final data = response['data'];
        final details = _extractResponseDetails(data);
        if (details.isNotEmpty) {
          return '$message: $details';
        }
        return message;
      }
    }
    return e.toString();
  }

  String _extractResponseDetails(dynamic data) {
    if (data is! Map<String, dynamic>) return '';

    final messages = <String>[];
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final message = value['message'];
        if (message is String && message.isNotEmpty) {
          messages.add('$key: $message');
        }
      }
    });
    return messages.join(' | ');
  }
}

// ── Checkbox CGU ──────────────────────────────────────────────────────────────

class _TermsCheckbox extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onReadTerms;

  const _TermsCheckbox({
    required this.accepted,
    required this.onChanged,
    required this.onReadTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onChanged(!accepted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: accepted ? JorappColors.teal : JorappColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: accepted
                      ? JorappColors.teal
                      : JorappColors.teal.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: accepted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "J'accepte les conditions d'utilisation",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: JorappColors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "En soumettant des enregistrements, je cède mes droits d'usage à l'association Jorat Parc Naturel pour des fins scientifiques, artistiques et promotionnelles, dans le respect de mon anonymat.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: JorappColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onReadTerms,
                  child: const Text(
                    'Lire les conditions complètes →',
                    style: TextStyle(
                      fontSize: 12,
                      color: JorappColors.tealLight,
                      decoration: TextDecoration.underline,
                      decorationColor: JorappColors.tealLight,
                    ),
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

// ── Bottom sheet CGU ──────────────────────────────────────────────────────────

class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: JorappColors.surfaceStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Conditions d'utilisation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: JorappColors.tealDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "JorApp / Festi'Jorat 2026 — Version 1.0, Mai 2025",
                style: TextStyle(fontSize: 12, color: JorappColors.teal),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: const [
                  _CguSection(
                    title: '1. Qui sommes-nous ?',
                    body:
                        "L'application est éditée par l'Association Jorat Parc Naturel, dont le siège est situé à Lausanne dans le canton de Vaud, Suisse. Elle est utilisée dans le cadre du festival Festi'Jorat 2026 et de nos activités de science participative et de médiation territoriale.\n\nContact : info@jorat.org",
                  ),
                  _CguSection(
                    title: '2. À quoi servent vos enregistrements ?',
                    body:
                        "En utilisant cette application, vous pouvez soumettre des enregistrements sonores ou d'autres données de terrain (ci-après « contributions »).\n\nVos contributions peuvent être utilisées par l'association JPN dans les contextes suivants :\n\n• Scientifique : analyse des paysages sonores, recherche participative\n• Artistique : expositions, cartographies sensibles, installations sonores, créations numériques\n• Promotionnel : communication du parc, publications, supports pédagogiques",
                  ),
                  _CguSection(
                    title: '3. Cession de droits',
                    body:
                        "En soumettant une contribution, vous cédez à l'association JPN un droit d'usage non exclusif, gratuit et sans limitation géographique pour les finalités décrites à l'article 2.\n\nCela signifie concrètement :\n\n• Le JPN peut utiliser, reproduire, modifier et diffuser vos contributions\n• Vous conservez la possibilité de supprimer votre contribution dans les 24 heures suivant l'enregistrement (voir article 5)\n• Passé ce délai, la contribution est intégrée aux données du parc et ne peut plus être retirée individuellement",
                  ),
                  _CguSection(
                    title: '4. Anonymat et protection des données',
                    body:
                        "Vos contributions sont dissociées de votre identité dans tous les usages publics. L'association JPN s'engage à :\n\n• Ne jamais publier votre nom, pseudonyme ou toute information permettant de vous identifier\n• Utiliser vos données de compte (email, identifiant) uniquement pour la gestion de la relation entre vous et l'association JPN\n• Ne pas transmettre vos données personnelles à des tiers sans votre accord explicite\n\nVos données sont traitées conformément à la Loi fédérale sur la protection des données (LPD) et stockées sur des serveurs sécurisés.",
                  ),
                  _CguSection(
                    title: '5. Droit de retrait — fenêtre de 24 heures',
                    body:
                        "Vous disposez d'un délai de 24 heures après chaque enregistrement pour supprimer votre contribution, sans justification. Cette suppression est définitive et immédiate et peut être effectuée directement dans l'application.\n\nAu-delà de ce délai, la contribution est considérée comme définitivement cédée à l'association JPN.",
                  ),
                  _CguSection(
                    title: '6. Suppression de votre compte',
                    body:
                        "Vous pouvez demander la suppression de votre compte à tout moment en contactant info@jorat.org. Cela entraîne la suppression de vos données personnelles. Les contributions déjà intégrées aux données du parc (délai de 24h dépassé) restent utilisables, mais de manière entièrement anonyme.",
                  ),
                  _CguSection(
                    title: '7. Modifications des conditions',
                    body:
                        "L'association JPN se réserve le droit de modifier ces conditions. En cas de changement substantiel, vous en serez informé par notification dans l'application. La poursuite de l'utilisation après notification vaut acceptation.",
                  ),
                  _CguSection(
                    title: '8. Droit applicable',
                    body:
                        "Ces conditions sont soumises au droit suisse. Tout litige relève de la compétence des tribunaux du canton de Vaud.",
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CguSection extends StatelessWidget {
  final String title;
  final String body;

  const _CguSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: JorappColors.tealDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: JorappColors.ink,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
