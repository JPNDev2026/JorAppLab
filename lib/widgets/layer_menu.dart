import 'package:flutter/material.dart';

import '../theme/jorapp_theme.dart';

class LayerMenu extends StatelessWidget {
  final bool showPaths;
  final bool showProtectedAreas;
  final ValueChanged<bool> onTogglePaths;
  final ValueChanged<bool> onToggleProtectedAreas;

  const LayerMenu({
    super.key,
    required this.showPaths,
    required this.showProtectedAreas,
    required this.onTogglePaths,
    required this.onToggleProtectedAreas,
  });

  @override
  Widget build(BuildContext context) {
    bool localShowPaths = showPaths;
    bool localShowProtectedAreas = showProtectedAreas;

    return StatefulBuilder(
      builder: (context, setState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: JorappColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: JorappColors.tealDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Couches cartographiques',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Afficher les chemins'),
                        value: localShowPaths,
                        onChanged: (value) {
                          setState(() => localShowPaths = value);
                          onTogglePaths(value);
                        },
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Afficher la zone protégée'),
                        value: localShowProtectedAreas,
                        onChanged: (value) {
                          setState(() => localShowProtectedAreas = value);
                          onToggleProtectedAreas(value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
