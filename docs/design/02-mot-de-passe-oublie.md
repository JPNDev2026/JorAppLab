# 02 — Écran Mot de passe oublié

> **Prérequis :** lire `docs/design/00-tokens.md` avant.

## Contexte

Restyle l'écran de mot de passe oublié (probablement `lib/screens/forgot_password_screen.dart` ou `lib/features/auth/forgot_password_screen.dart`).

## Règles

⚠️ **Ne pas toucher** : logique d'envoi du mail de reset, appels API PocketBase, navigations, `TextEditingController`, validation email. **Uniquement visuel**.

## Avant de coder

Liste les fichiers que tu vas modifier et confirme le plan.

## Spec

**1. Scaffold**
- `backgroundColor: JorappColors.surface`
- Fond topographique radial subtil (cf. tokens)

**2. Logo zone (top)**
- `paddingTop: 48`
- Logo SVG 52x62 + texte "JorApp" en dessous (DM Sans 11px weight 500 letterSpacing 3 uppercase `muted`)

**3. Form card**
- `margin: top 20, horizontal 16`
- Background white, radius 20, padding 24/20/20
- Shadow `0 4px 24px rgba(20,34,40,0.09)`

**4. Dans la card**

*Bloc illustration header (centré)* :
- Icône cadenas dans container 56x56, radius 18, background `rgba(31,100,129,0.08)`, icône `teal` 26x26
- Titre "Mot de passe oublié ?" DM Sans 18px weight 700 `tealDark`
- Sous-titre "Entrez votre email et nous vous enverrons un lien pour réinitialiser votre mot de passe." DM Sans 12px weight 300 `muted` line-height 1.6 centered
- `marginBottom: 20`

*Tag pill* :
- "RÉINITIALISATION SÉCURISÉE" (style standard, cf. tokens)
- `marginBottom: 14`

*Champ Email* :
- Label "EMAIL" + input même style que Connexion

*Bouton "Envoyer le lien"* :
- Full-width, radius 14, background `teal`, shadow standard
- DM Sans 14px weight 600 white
- ⚠️ **PAS d'anneau lime rotatif**

*Lien retour* :
- "← Retour à la connexion" : center, DM Sans 12px weight 400 `muted`, `marginTop: 14`

## Validation

- [ ] `TextEditingController` intact
- [ ] Validation email conservée
- [ ] Submit + snackbar de confirmation conservés
- [ ] Navigation retour conservée
- [ ] Aucun hex inline
- [ ] DM Sans partout
