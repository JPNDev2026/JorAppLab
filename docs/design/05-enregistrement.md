# 05 — Écran Enregistrement

> **Prérequis :** lire `docs/design/00-tokens.md` avant.

## Contexte

Restyle l'écran d'enregistrement vocal (probablement `lib/screens/recording_screen.dart` ou `lib/features/recording/...`).

## Règles

⚠️ **Ne pas toucher** : logique d'enregistrement, permissions micro, appels PocketBase, providers, gestion du state, strings existants. **Uniquement visuel**.

## Avant de coder

Liste les fichiers que tu vas modifier et confirme le plan.

## Spec

**1. Scaffold**
- `backgroundColor: JorappColors.surface`
- Fond topographique radial subtil (cf. tokens)
- Optionnel : superposer un pattern topographique léger si un asset SVG de courbes de niveau existe (opacity 0.04) ; sinon skip

**2. AppBar (header "Enregistrement")**
- Garder la structure existante (logo goutte + titre + boutons profil/bibliothèque)
- Les deux boutons icône à droite deviennent des **carrés arrondis** 40x40, radius 14, background `rgba(31,100,129,0.09)`, icône `teal`. Pas de cercle.
- Titre "Enregistrement" : DM Sans 20px weight 700 `ink`

**3. Bloc central (copy "Il existe une autre géographie…")**

*Tag pill au-dessus du titre (NOUVEAU)* :
- Background `lime`, radius 20, padding 4x12
- Contenu : dot ink opacity 0.4 + "SCIENCE PARTICIPATIVE" DM Sans 10px weight 700 letterSpacing 1.5 uppercase `ink`
- `marginBottom: 20`

*Titre principal* :
- DM Sans 24px weight 700 `tealDark`, line-height 1.25

*Sous-titre* :
- DM Sans 13px weight 300 `muted`, line-height 1.65

**4. Card explicative (OPTIONNELLE)**
- Juste sous le sous-titre, une card blanche :
  - Background white, radius 16, border-left 3px `lime`
  - Padding 16
  - Shadow `0 2px 16px rgba(20,34,40,0.07)`
  - Row avec icône micro à gauche + texte à droite :
    - "Vous décidez" DM Sans 13px weight 500 `ink`
    - Sous-texte : "Enregistrez, réécoutez, recommencez. Ne partagez que ce que vous souhaitez." DM Sans 12px weight 300 `muted`

⚠️ **Si ce texte n'existe pas dans les strings actuels, NE PAS AJOUTER la card.** On ne crée pas de contenu qui n'existe pas.

**5. Zone micro en bas**

*Label au-dessus du bouton* :
- "Appuyez pour démarrer un enregistrement" : DM Sans 11px `muted`, letterSpacing 0.5, centered

*Bouton micro* :
- Cercle 76x76
- Background `teal` plein
- Icône micro blanche 28px
- Shadow `0 8px 24px rgba(31,100,129,0.35)`
- ⚠️ **PAS d'anneau lime rotatif autour. Le bouton est statique.**

*Optionnel* : quand l'enregistrement est actif (state déjà existant), on peut ajouter un ripple/scale animation sur le bouton lui-même. Mais **pas** d'anneau qui tourne en continu.

## Validation

- [ ] Logique d'enregistrement et permissions intactes
- [ ] Tous les callbacks onTap conservés
- [ ] Navigations vers profil/bibliothèque conservées
- [ ] Aucun hex inline
- [ ] DM Sans partout
