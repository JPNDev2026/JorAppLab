# Design tokens — Concept 02 "Carte vivante"

> À inclure en tête de chaque session Claude Code restyle.

## Couleurs (JorappColors — déjà dans le thème)

```
teal        = #1F6481   // primaire / boutons / titres
tealDark    = #153f52   // texte foncé
tealLight   = #2a7fa0   // accents secondaires
lime        = #D7E337   // accent / borders / tags
ink         = #142228   // texte principal
surface     = #F5F8F0   // fond app
muted       = #7a9aaa   // texte secondaire
danger      = #c0392b   // déconnexion uniquement
```

## Typographie

- **DM Sans uniquement** (déjà configuré dans le thème)
- Pas de Playfair, pas de serif
- Labels uppercase : `letterSpacing 1.5–2`, `fontSize 10px`, `fontWeight 600–700`

## Primitives visuelles

**Cards blanches** :
- `background: white`
- `borderRadius: 16`
- `border-left: 3px solid lime`
- `boxShadow: 0 2px 16px rgba(20,34,40,0.07)`
- `padding: 16`

**Inputs** :
- `height: 42`
- `border: 1.5px rgba(31,100,129,0.15)`
- `borderRadius: 10`
- `background: surface`
- État focus : `border: teal`, `background: white`, `shadow: 0 0 0 3px rgba(31,100,129,0.08)`

**Boutons primaires** :
- `height: 46` (full-width) ou `36` (inline)
- `borderRadius: 14` ou `10`
- `background: teal`
- `text: white DM Sans 14px weight 600`
- `boxShadow: 0 4px 14px rgba(31,100,129,0.3)`
- ⚠️ **PAS d'anneau lime rotatif** autour

**Tag pill** :
- `background: lime`
- `borderRadius: 20`
- `padding: 3x10`
- Contenu : dot ink 0.4 + texte DM Sans 9px weight 700 letterSpacing 1.5 uppercase ink

**Fond d'écran** :
- `Scaffold backgroundColor: surface`
- Gradient radial subtil : `radial(rgba(31,100,129,0.07) → transparent)`
- Optionnel : pattern topographique `opacity 0.03–0.04`

## Règles transverses

- Couleurs via `JorappColors` (pas de hex inline en Dart)
- Pas de nouveaux packages Flutter
- Ne modifier que l'apparence : jamais la logique, les strings, les routes, les providers, les modèles
- Conserver tous les `TextEditingController`, callbacks `onTap`, navigations
- Tester sur Android ET web (`kIsWeb`)
- **Aucune rotation/animation sur les boutons ou FAB**. Tous statiques.
