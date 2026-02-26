import 'package:flutter/material.dart';

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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Afficher les chemins'),
                value: localShowPaths,
                onChanged: (value) {
                  setState(() => localShowPaths = value);
                  onTogglePaths(value);
                },
              ),
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
        );
      },
    );
  }
}