import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../app/widgets/jorapp_app_bar.dart';
import '../../../app/widgets/jorapp_drawer.dart';
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

  @override
  Widget build(BuildContext context) {
    developer.log(
      '[LandingScreen] build paths=${widget.geofencingController.paths.length} '
      'polygons=${widget.geofencingController.protectedAreas.length}',
    );

    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      appBar: JorappAppBar(
        onMenuPressed: _openMenu,
      ),
      endDrawer: JorappDrawer(
        authService: widget.authService,
        onNavigate: _pushNamedFromDrawer,
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
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
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
