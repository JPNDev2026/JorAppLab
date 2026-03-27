import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../theme/jorapp_theme.dart';
import '../../auth/auth_service.dart';
import '../../geofencing/geofencing_controller.dart';
import 'landing_section_screen.dart';
import '../widgets/category_card.dart';

class _CategoryData {
  final String title;
  final String subtitle;
  final String count;
  final Color accentColor;
  final IconData icon;

  const _CategoryData({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.accentColor,
    required this.icon,
  });
}

const _categories = <_CategoryData>[
  _CategoryData(
    title: 'Offres thématiques',
    subtitle: 'Idées & inspirations',
    count: '12 offres',
    accentColor: JorappColors.teal,
    icon: Icons.grid_view_rounded,
  ),
  _CategoryData(
    title: 'Visites & itinéraires',
    subtitle: 'Sentiers & parcours',
    count: '8 itinéraires',
    accentColor: JorappColors.tealDark,
    icon: Icons.route_rounded,
  ),
  _CategoryData(
    title: 'Restaurants',
    subtitle: 'Tables & terrasses',
    count: '24 adresses',
    accentColor: Color(0xFF2A7A6A),
    icon: Icons.restaurant_rounded,
  ),
  _CategoryData(
    title: 'Produits régionaux',
    subtitle: 'Terroir & artisans',
    count: '31 producteurs',
    accentColor: Color(0xFF7B8330),
    icon: Icons.eco_rounded,
  ),
  _CategoryData(
    title: 'Activités sportives',
    subtitle: 'Plein air & nature',
    count: '15 activités',
    accentColor: Color(0xFF476C32),
    icon: Icons.directions_run_rounded,
  ),
];

class LandingScreen extends StatefulWidget {
  final AuthService authService;
  final GeofencingController geofencingController;

  const LandingScreen({
    super.key,
    required this.authService,
    required this.geofencingController,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    developer.log(
      '[LandingScreen] initState loader=${GeofencingController.loaderVersion}',
    );
    unawaited(widget.geofencingController.bootstrapLayers());
    widget.geofencingController.addListener(_onControllerChanged);
    _errorSubscription = widget.geofencingController.errors.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });
  }

  @override
  void dispose() {
    widget.geofencingController.removeListener(_onControllerChanged);
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _openMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _openCategory(_CategoryData category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LandingSectionScreen(
          title: category.title,
          subtitle: category.subtitle,
          icon: category.icon,
          accentColor: category.accentColor,
        ),
      ),
    );
  }

  Future<void> _pushNamedFromDrawer(
    String routeName, {
    Object? arguments,
  }) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  String _displayName() {
    final user = widget.authService.currentUser;
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
    developer.log(
      '[LandingScreen] build paths=${widget.geofencingController.paths.length} '
      'polygons=${widget.geofencingController.protectedAreas.length}',
    );

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
        child: ListenableBuilder(
          listenable: widget.authService,
          builder: (context, _) {
            final isLoggedIn = widget.authService.isLoggedIn;
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
                            : Colors.white.withOpacity(0.2),
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
                  onTap: () => _pushNamedFromDrawer(AppRouter.map),
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
                  onTap: () => _pushNamedFromDrawer(
                    isLoggedIn ? AppRouter.audioGuide : AppRouter.login,
                    arguments: isLoggedIn ? null : AppRouter.audioGuide,
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
                  onTap: () => _pushNamedFromDrawer(AppRouter.partenaires),
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
                  onTap: () => _pushNamedFromDrawer(AppRouter.orientation),
                ),
                const Spacer(),
                const Divider(height: 1),
                if (!isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _pushNamedFromDrawer(AppRouter.login),
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
                          widget.authService.logout();
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAF5), Color(0xFFEAF2E3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => CategoryCard(
                    title: _categories[i].title,
                    subtitle: _categories[i].subtitle,
                    count: _categories[i].count,
                    accentColor: _categories[i].accentColor,
                    icon: _categories[i].icon,
                    onTap: () => _openCategory(_categories[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
