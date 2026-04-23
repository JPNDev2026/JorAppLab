# 04 — Écran Mon compte

> **Prérequis :** lire `docs/design/00-tokens.md` avant.

## Contexte

Restyle l'écran "Mon compte" (probablement `lib/screens/account_screen.dart` ou `lib/features/account/account_screen.dart`).

## Règles

⚠️ **Ne pas toucher** : les 3 actions d'update (nom, email, password), validations, snackbars, logout, dialog de confirmation. **Uniquement visuel**.

## Avant de coder

Liste les fichiers que tu vas modifier et confirme le plan.

## Spec

**1. Scaffold**
- `backgroundColor: JorappColors.surface`
- Fond topographique radial subtil (cf. tokens)

**2. Header (AppBar custom)**
- Row padding `48/20/0/20`
- Back button à gauche : 34x34, icône `teal` 18px, pas de background
- Titre "Mon compte" : DM Sans 18px weight 700 `ink` letterSpacing -0.3

**3. Body**
- Padding `16/16/0/16`
- Column avec gap 12 entre cards
- ScrollView pour gérer le contenu long

**4. Chaque section = une card**
- Background white, radius 16, padding 16
- Shadow `0 2px 16px rgba(20,34,40,0.07)`
- `borderLeft: 3px solid lime`

**5. Section header (dans chaque card)**
- Row, `marginBottom: 14`
- Label DM Sans 10px weight 700 letterSpacing 2 uppercase `teal`
- Ligne décorative 1px `rgba(31,100,129,0.1)` qui s'étend sur le reste de la row
  (utiliser `Expanded(Divider())` ou `Container(height: 1)`)
- Labels à utiliser : "NOM D'UTILISATEUR", "ADRESSE EMAIL", "MOT DE PASSE"

**6. Card 1 — Nom d'utilisateur**
- Label champ "NOM" DM Sans 10px weight 600 `muted` uppercase
- Row `alignItems: end` :
  - Input flex 1 avec valeur actuelle pré-remplie, état focused (border `teal`, bg white, shadow)
  - Bouton "Enregistrer" inline : height 36, radius 10, bg `teal`, padding horizontal 14, DM Sans 12px weight 600 white, `flexShrink: 0`, gap 8 avec l'input

**7. Card 2 — Adresse email**
- Même pattern que Card 1
- Si l'email est long, réduire fontSize de l'input à 12px pour éviter overflow

**8. Card 3 — Mot de passe**
- 3 champs en column (pas inline) :
  - Label "ACTUEL" + input placeholder `••••••••`
  - Label "NOUVEAU" + input
  - Label "CONFIRMATION" + input
- Bouton "Enregistrer" full-width en bas de la card :
  - Height 46, radius 14, bg `teal`
  - DM Sans 14px weight 600 white
  - Shadow `0 4px 14px rgba(31,100,129,0.3)`
  - ⚠️ **PAS d'anneau lime rotatif**

**9. Divider en bas**
- Height 1, bg `rgba(20,34,40,0.06)`, margin horizontal 16, `marginTop: 12`

**10. Bouton "Se déconnecter"**
- Margin `12/16/16/16` (bottom-safe)
- Height 46, radius 14
- Border `1.5px rgba(192,57,43,0.3)`
- Background `rgba(192,57,43,0.04)`
- Row centered : icône logout `danger` 14px + texte "Se déconnecter" DM Sans 13px weight 500 `danger`

## Validation

- [ ] Tous les `TextEditingController` intacts
- [ ] Bool `isEditing` et callbacks de save par section conservés
- [ ] Dialog de confirmation de logout conservé
- [ ] Aucun hex inline
- [ ] DM Sans partout
