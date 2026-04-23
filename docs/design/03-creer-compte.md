# 03 — Écran Créer un compte

> **Prérequis :** lire `docs/design/00-tokens.md` avant.

## Contexte

Restyle l'écran de création de compte (probablement `lib/screens/register_screen.dart` ou `lib/features/auth/register_screen.dart`).

## Règles

⚠️ **Ne pas toucher** : logique d'inscription, validation des champs, validation de la checkbox, appels API, navigations. **Uniquement visuel**.

## Avant de coder

Liste les fichiers que tu vas modifier et confirme le plan.

## Spec

**1. Scaffold**
- `backgroundColor: JorappColors.surface`
- Fond topographique radial subtil (cf. tokens)

**2. Logo zone compacte**
- `paddingTop: 32` (plus compact qu'en Connexion pour laisser de la place aux 4 champs)
- Logo SVG 36x43 centré
- **Pas** de texte "JorApp" en dessous

**3. Form card**
- `margin: top 14, horizontal 16`
- Background white, radius 20, padding 24/20/20
- Shadow `0 4px 24px rgba(20,34,40,0.09)`

**4. Dans la card**

*Titre* :
- "Créer un compte" DM Sans 20px weight 700 `tealDark`, `marginBottom: 20`

*4 champs (Nom, Email, Mot de passe, Confirmation)* :
- Même style de label + input que Connexion
- Labels : "NOM", "EMAIL", "MOT DE PASSE", "CONFIRMATION"
- Gap 16 entre champs, 12 sur le dernier

*Bloc checkbox conditions* :
- Row `alignItems: flex-start`, gap 10, margin `4/0/16`
- Checkbox 20x20, border 1.5px `rgba(31,100,129,0.3)`, radius 6, background `surface`
- État cochée : background `teal`, border `teal`, icône check blanche
- À droite (flex 1) :
  - Titre "J'accepte les conditions d'utilisation" DM Sans 12px weight 600 `teal`, `marginBottom: 4`
  - Body (garder le texte existant sur cession de droits) : DM Sans 11px weight 300 `muted` line-height 1.5
  - Lien "Lire les conditions complètes →" DM Sans 11px `tealLight` underline, `marginTop: 4`

*Bouton "Créer mon compte"* :
- Même style que Connexion : `teal` full-width height 46 radius 14
- **État désactivé** (checkbox non cochée) : background `rgba(31,100,129,0.2)`, text `muted`, pas de shadow
- **État actif** : background `teal`, text white, shadow standard
- ⚠️ **PAS d'anneau lime rotatif**

*Lien "Déjà un compte"* :
- Center, DM Sans 13px weight 500 `teal`, `marginTop: 12`

## Validation

- [ ] Tous les `TextEditingController` intacts
- [ ] Checkbox controller conservé
- [ ] Validations conservées
- [ ] Submit + navigation conservés
- [ ] Aucun hex inline
- [ ] DM Sans partout
