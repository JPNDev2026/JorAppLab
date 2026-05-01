import 'package:flutter/material.dart';

import '../../../theme/jorapp_theme.dart';
import '../models/festi_activity.dart';

const festiActivities = <FestiActivity>[
  FestiActivity(
    id: 'concert',
    title: 'Concert',
    subtitle: 'Concert live de balafon',
    weezeventUrl: 'https://my.weezevent.com/festijorat-2026-concerts',
    icon: Icons.music_note_rounded,
    accentColor: JorappColors.teal,
  ),
  FestiActivity(
    id: 'balade',
    title: 'Balade',
    subtitle: 'Balade immersive guidée dans le parc',
    weezeventUrl: 'https://my.weezevent.com/festijorat-2026',
    icon: Icons.hiking_rounded,
    accentColor: JorappColors.teal,
  ),
   FestiActivity(
    id: 'claquette',
    title: 'Claquette',
    subtitle: 'Spectacle de claquette avec le Théâtre de Vidy',
    weezeventUrl: 'https://my.weezevent.com/festijorat-2026-claquettes',
    icon: Icons.theater_comedy_rounded,
    accentColor: JorappColors.teal,
  ),
];
