import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../theme/jorapp_theme.dart';

class ComingSoonApp extends StatelessWidget {
  const ComingSoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _ComingSoonPage(),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonAnimatedContent();
  }
}

class _ComingSoonAnimatedContent extends StatefulWidget {
  const _ComingSoonAnimatedContent();

  @override
  State<_ComingSoonAnimatedContent> createState() =>
      _ComingSoonAnimatedContentState();
}

class _ComingSoonAnimatedContentState extends State<_ComingSoonAnimatedContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.72,
    end: 1,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ),
  );

  late final Animation<double> _textOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.62, 1, curve: Curves.easeOut),
  );

  late final Animation<Offset> _textOffset = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 1, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: JorappColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = constraints.maxWidth < 600 ? 120.0 : 160.0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'assets/branding/jorapp_logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _textOpacity,
                        child: SlideTransition(
                          position: _textOffset,
                          child: Text(
                            'Bientôt disponible',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: JorappColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
