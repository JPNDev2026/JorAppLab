# 06 — Écran Mes récits — Vue liste

> **Prérequis :** lire `docs/design/00-tokens.md` avant.

## Contexte

Restyle l'écran "Mes récits" vue liste (probablement `lib/screens/my_stories_screen.dart` ou `lib/features/stories/...`).

## Règles

⚠️ **Ne pas toucher** : logique de fetch, sync PocketBase, état des récits, modèles de données. **Uniquement visuel**.

## Avant de coder

Liste les fichiers que tu vas modifier et confirme le plan.

## Spec

**1. Scaffold**
- `backgroundColor: JorappColors.surface`
- Fond topographique radial subtil (cf. tokens)

**2. AppBar**
- Back button à gauche + logo goutte + titre "Mes récits"
- Titre DM Sans 20px weight 700 `ink`
- Bouton toggle carte à droite (icône map) : carré arrondi 40x40, radius 14, background `rgba(31,100,129,0.09)`, icône `teal`

**3. Stats strip (NOUVEAU — en haut, sous AppBar)**
- Container margin horizontal 20, padding 12x16, radius 12, background `rgba(31,100,129,0.05)`
- Row avec 3 stats séparés par divider verticaux 1px `rgba(31,100,129,0.1)` :
  - Count récits total : nombre DM Sans 20px weight 700 `teal` + label "RÉCITS" en 9px `muted` uppercase letterSpacing 1
  - Count synchronisés : même style
  - Durée totale cumulée : même style (ex: "14s")

⚠️ **Si les stats ne sont pas calculables depuis le modèle actuel, SKIP cette section.** Ne pas créer de nouveaux providers.

**4. Sub-header "Récits terrain" + bouton Tout synchroniser**
- Label "Récits terrain" : DM Sans 11px weight 500, letterSpacing 2, uppercase, `muted`
- Bouton "Tout synchroniser" :
  - Background `teal`, radius 14, padding 9x16
  - Shadow `0 4px 14px rgba(31,100,129,0.25)`
  - Contenu : icône refresh (↻) `lime` 13px + texte "Tout synchroniser" white DM Sans 12px weight 600
  - ⚠️ **PAS d'anneau lime rotatif autour**

**5. Card de récit (chaque item)**
- Background white, radius 16, padding 16
- Shadow `0 2px 16px rgba(20,34,40,0.07)`
- `borderLeft: 3px solid lime` (solide pour synchronisé, ou `lime opacity 0.5` pour brouillon non-synchronisé)

Row avec 3 zones :

*a) Avatar* :
- Container 40x40, radius 12, background `lime opacity 0.18`
- Cercle interne 26x26 `teal` avec icône mic blanche 14px
- Si synchronisé : petit badge 14x14 `lime` en bottom-right de l'avatar avec checkmark `ink` bold (overflow visible)

*b) Info au centre (flex 1)* :
- Date formatée "Mer 22 avr · 19:34" DM Sans 14px weight 700 `ink`
- Row meta : "2 s" 11px `muted` + dot separator 3px `muted` + coords en Space Mono 9px `muted` (ex: "46.5443°N 6.6544°E")
- **Mini waveform** : 7 barres 2px large, hauteurs variées (5,10,7,13,6,9,4), color `teal opacity 0.25`, height 14px, gap 2px

*c) Actions à droite* :
- Bouton play 34x34 cercle `teal` avec icône play blanche 12px, shadow `0 3px 10px rgba(31,100,129,0.3)`
- Bouton more (⋮) 28x28 en `muted` 18px

**6. État "brouillon non synchronisé"**
- `opacity: 0.65`
- Avatar background : `teal opacity 0.35` au lieu du lime

**7. Espacement**
- Gap 12px entre les cards
- Padding horizontal 20px sur la liste

## Validation

- [ ] `ListView.builder` et logique de fetch intacts
- [ ] Callbacks play/delete/sync conservés
- [ ] Providers et state conservés
- [ ] Aucun hex inline
- [ ] DM Sans partout (+ Space Mono pour les coordonnées uniquement)
