# 07 — Écran Mes récits — Vue carte

> **Prérequis :** lire `docs/design/00-tokens.md` avant.

## Contexte

Restyle l'écran "Mes récits" vue carte (probablement `lib/screens/stories_map_screen.dart` ou similaire).

## Règles

⚠️ **Ne pas toucher** : logique de carte, pins positions réelles, `MapController`, fetch des récits, providers de géolocalisation. **Uniquement le style visuel des éléments UI superposés**.

## Avant de coder

Liste les fichiers que tu vas modifier et confirme le plan.

## Spec

**1. Fond général**
- `Scaffold backgroundColor: JorappColors.surface`
- La map OSM garde son rendu natif

**2. AppBar**
- Même style que la vue liste (back + logo + "Mes récits")
- Bouton toggle liste à droite : carré arrondi 40x40 radius 14, bg `rgba(31,100,129,0.09)`, icône liste `teal`

**3. Container de la carte**
- Wrapper la carte dans un Container avec `borderRadius: 20` et `ClipRRect` pour arrondir les coins
- Margin 16 de chaque côté (top 10 sous le header)
- Shadow `0 4px 24px rgba(20,34,40,0.12)`

**4. Badge en haut à gauche de la carte (NOUVEAU — overlay)**
- Position absolute top 12, left 12
- Background white, radius 10, padding 5x10
- Shadow `0 2px 8px rgba(0,0,0,0.1)`
- Row : dot 7x7 `lime` avec border 2px `teal` + texte "JORAT · X RÉCITS" DM Sans 9px weight 600 `ink` letterSpacing 1 uppercase
- Count X = nombre dynamique de récits visibles

**5. Pins sur la carte (custom markers)**

Remplacer les markers actuels par des pins stylés via le système de markers du plugin de carte existant (`flutter_map MarkerLayer` ou équivalent). **Garder les coordonnées réelles de chaque récit**.

Container column : bubble (cercle 28x28) + petit dot 5x5 en dessous.

*Pin "récit synchronisé"* :
- Bubble : background `teal`, border 2px white, icône mic blanche 12px
- Shadow `0 3px 10px rgba(31,100,129,0.4)`
- Dot : 5x5 circle `teal opacity 0.7`

*Pin "brouillon"* :
- Bubble : background white, border 2px `lime`, icône mic `teal` 12px
- Dot : 5x5 circle `tealLight opacity 0.7`

**6. FAB "Enregistrer ici" (bottom right overlay)**
- Position absolute bottom 24, right 20
- Container pill : background `teal`, radius 20, padding 12x18
- Shadow `0 6px 20px rgba(31,100,129,0.4)`
- Row : icône mic blanche 16px + texte "Enregistrer ici" DM Sans 12px weight 600 white
- ⚠️ **PAS d'anneau lime rotatif autour. Le FAB est statique.**
- Le `onTap` doit déclencher la même navigation/action que l'ancien bouton mic flottant au centre

**7. Pill count au-dessus du FAB (OPTIONNEL)**
- Si pertinent, petit pill centré horizontalement, bottom 80
- Background white, radius 20, padding 6x14
- Shadow `0 2px 12px rgba(0,0,0,0.1)`
- Row : nombre DM Sans 16px weight 700 `teal` + label "récits enregistrés" DM Sans 11px `muted`

⚠️ **SKIP si le count est déjà montré dans le badge du haut.** On n'affiche pas l'info deux fois.

## Validation

- [ ] Logique map (zoom, pan, geolocation) intacte
- [ ] Tap sur pins ouvre le même détail/popup qu'avant
- [ ] Coordonnées réelles des pins conservées
- [ ] `MapController` et providers intacts
- [ ] Aucun hex inline
- [ ] DM Sans partout
