# AGENT.md — Contexte Codex pour JorAppLab

## Projet
Application Flutter pour le Parc naturel périurbain du Jorat (PNJ), canton Vaud, Suisse.
Backend : PocketBase auto-hébergé sur `https://jorapp.org` (DigitalOcean, Ubuntu 24.04).

## Architecture

### Principe
Feature-first : chaque feature est un dossier autonome sous `lib/features/`.
Les widgets et services partagés sont dans `lib/app/` et `lib/core/`.

### Plateforme
- **Native (Android/iOS)** : toutes les features nécessitant GPS, audio, signal réseau
- **Web** : landing page, réservation, contenu éditorial — pas de GPS, pas d'audio natif
- `main.dart` détecte `kIsWeb` pour éviter `PbClient.init()` (flutter_secure_storage non supporté sur web)
- Le router (`lib/app/router.dart`) gère les divergences web/native avec `kIsWeb`
- Sur web, l'écran d'entrée (route `/welcome` et `default`) est désormais `FestijoratScreen` (`features/festijorat/`) — page d'inscription au festival Festi'Jorat 2026 avec liens Weezevent trackés.

### Widgets partagés (lib/app/widgets/)
- `JorappAppBar` — AppBar standard avec logo et bouton menu burger
- `JorappDrawer` — Drawer de navigation partagé web + native, avec gestion auth

### Features actives
| Feature | Dossier | Plateforme | Statut |
|---|---|---|---|
| Welcome / onboarding | `features/welcome/` | Native | ✅ Actif |
| Landing | `features/landing/` | Native | ✅ Actif |
| Web landing | `features/web_landing/` | Web | ✅ Actif |
| Auth (login/register) | `features/auth/` | Native + Web | ✅ Actif |
| Audio guide GPS | `features/audio_guide/` | Native | ✅ En dev |
| Geofencing / GPS tracking | `features/geofencing/` | Native | ✅ Actif |
| Carte réseau (mesures) | `features/geofencing/screens/network_map_screen.dart` | Native | ✅ Actif |
| Carte orientation visiteur | `features/map/` | Native | ✅ Actif |
| Festi'Jorat landing | `features/festijorat/` | Web | ✅ Actif |

### Collections PocketBase
- `users` — authentification
- `balades` — parcours audio (champ `actif: bool`, `nom: string`)
- `audio_points` — points déclencheurs GPS (`balade: relation`, `lat_centre`, `lng_centre`, `rayon_metres`, `ordre`, `fichier_mp3`)

## Palette couleurs (JorappColors)
```dart
teal      = Color(0xFF1F6481)
tealDark  = Color(0xFF142F3D) // approx
lime      = Color(0xFFD7E337)
ink       = Color(0xFF142228)
surface   = Color(0xFFF5F8F0)
```

## Conventions
- State management : `ChangeNotifier` + `ListenableBuilder` (pas de Riverpod)
- Navigation : `Navigator.pushNamed` avec `AppRouter` comme source de vérité des routes
- Logs : `dart:developer` — préfixer avec `[NomDeLaClasse]`
- Pas de `BuildContext` dans les services
- Les méthodes de navigation depuis un drawer doivent : (1) fermer le drawer, (2) attendre 150ms, (3) naviguer

## Ce qu'il ne faut PAS faire
- Ne pas créer de second `MaterialApp` pour la version web
- Ne pas dupliquer le drawer ou l'AppBar — utiliser `JorappAppBar` et `JorappDrawer`
- Ne pas appeler `PbClient.instance.init()` côté web
- Ne pas mettre de logique métier dans `coming_soon_app.dart` — ce fichier n'existe plus
