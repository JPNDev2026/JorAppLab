# 01 — Écran Connexion

> **Prérequis :** lire `docs/design/00-tokens.md` avant.

## Contexte

Restyle l'écran de connexion (probablement `lib/screens/login_screen.dart` ou `lib/features/auth/login_screen.dart`).

## Règles

⚠️ **Ne pas toucher** : auth PocketBase, validation des champs, providers d'auth, navigations vers register/forgot, `TextEditingController`. **Uniquement visuel**.

## Avant de coder

Liste les fichiers que tu vas modifier et confirme le plan.

## Spec

**1. Scaffold**
- `backgroundColor: JorappColors.surface`
- Fond topographique radial subtil (cf. tokens)

**2. Logo zone (top)**
- `Center`, `paddingTop: 48`
- Logo goutte SVG 52x62 avec shadow `0 4px 12px rgba(31,100,129,0.25)`
- Sous le logo : texte "JorApp" en DM Sans 11px weight 500, letterSpacing 3, uppercase, color `muted`

**3. Form card**
- `margin: top 20, horizontal 16`
- Background white, radius 20, padding 24/20/20
- Shadow `0 4px 24px rgba(20,34,40,0.09)`

**4. Dans la card**

*Tag pill en haut* :
- Background `lime`, radius 20, padding 3x10
- Row : dot ink opacity 0.4 + "ESPACE PERSONNEL" DM Sans 9px weight 700 letterSpacing 1.5 ink uppercase
- `marginBottom: 16`

*Titre "Connexion"* :
- DM Sans 20px weight 700 `tealDark`, `marginBottom: 20`

*Champs Email + Mot de passe* :
- Label "EMAIL" / "MOT DE PASSE" : DM Sans 10px weight 600 letterSpacing 1.5 uppercase `muted`, `marginBottom: 6`
- Input : height 42, border 1.5px `rgba(31,100,129,0.15)`, radius 10, background `surface`, padding horizontal 12, font DM Sans 14px `ink`
- État focused : border `teal`, background white, shadow `0 0 0 3px rgba(31,100,129,0.08)`
- Gap 16 entre champs

*Bouton "Se connecter"* :
- Full width, height 46, radius 14, background `teal`
- Text DM Sans 14px weight 600 white
- Shadow `0 4px 14px rgba(31,100,129,0.3)`
- ⚠️ **PAS d'anneau lime rotatif**

*Liens en dessous* :
- "Créer un compte" : center, DM Sans 13px weight 500 `teal`, `marginTop: 16`
- "Mot de passe oublié" : center, DM Sans 12px weight 400 `muted`, `marginTop: 8`

## Validation

Après les modifs, vérifie :
- [ ] Tous les `TextEditingController` intacts
- [ ] Callbacks de submit conservés
- [ ] Navigations vers register + forgot conservées
- [ ] Aucun hex inline dans le Dart (tout via JorappColors)
- [ ] DM Sans partout
