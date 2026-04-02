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
      home: const _WebLandingScreen(),
    );
  }
}

class _WebLandingScreen extends StatefulWidget {
  const _WebLandingScreen();

  @override
  State<_WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<_WebLandingScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void _openMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _openPlaceholder(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _WebFeaturePlaceholderScreen(
          title: title,
          icon: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      appBar: AppBar(
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'JorAppLab',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Parc du Jorat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            iconSize: 30,
            padding: const EdgeInsets.all(10),
            icon: const Icon(Icons.menu_rounded),
            onPressed: _openMenu,
          ),
          const SizedBox(width: 12),
        ],
      ),
      endDrawer: Drawer(
        width: 280,
        child: Column(
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
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Visiteur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.biotech_rounded,
                color: JorappColors.tealDark,
                size: 28,
              ),
              title: const Text(
                'Science participative',
                style: TextStyle(
                  color: JorappColors.ink,
                  fontSize: 15,
                ),
              ),
              onTap: () => _openPlaceholder(
                context,
                title: 'Science participative',
                icon: Icons.biotech_rounded,
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.headset_rounded,
                color: JorappColors.tealDark,
                size: 28,
              ),
              title: const Text(
                'Balade audio',
                style: TextStyle(
                  color: JorappColors.ink,
                  fontSize: 15,
                ),
              ),
              onTap: () => _openPlaceholder(
                context,
                title: 'Balade audio',
                icon: Icons.headset_rounded,
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.explore_rounded,
                color: JorappColors.tealDark,
                size: 28,
              ),
              title: const Text(
                'Découvertes',
                style: TextStyle(
                  color: JorappColors.ink,
                  fontSize: 15,
                ),
              ),
              onTap: () => _openPlaceholder(
                context,
                title: 'Découvertes',
                icon: Icons.explore_rounded,
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.signpost_rounded,
                color: JorappColors.tealDark,
                size: 28,
              ),
              title: const Text(
                'Orientation',
                style: TextStyle(
                  color: JorappColors.ink,
                  fontSize: 15,
                ),
              ),
              onTap: () => _openPlaceholder(
                context,
                title: 'Orientation',
                icon: Icons.signpost_rounded,
              ),
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openPlaceholder(
                    context,
                    title: 'Connexion',
                    icon: Icons.login_rounded,
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Se connecter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: JorappColors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAF5), Color(0xFFEAF2E3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
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
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
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
      ),
    );
  }
}

class _WebFeaturePlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _WebFeaturePlaceholderScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/branding/jorapp_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAF5), Color(0xFFEAF2E3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: JorappColors.surfaceStrong,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 44,
                      color: JorappColors.tealDark,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: JorappColors.tealDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cette feature existe déjà côté Android. Ici, on prépare d’abord la structure web en réutilisant le menu et les points d’entrée.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xFF50616A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
