# Audit des écrans et découpage — charte d'interface v1 (28/10/2026)

Pour chaque écran : l'état actuel en une phrase, puis la cible (maquette ASCII, 296 px ≈ 48 colonnes ici).
Légende : `[ic]` icône 16 px, `▸` tête fermée, `▾` tête ouverte (les flèches ne sont pas dessinées dans le jeu), `{…}` couleur de rôle.
PNJ et Village servent de modèle et ne changent pas, sauf pour passer leurs constantes dans ui_style.gd (aucun changement visible).

## Déplié

### Perso (jalon 20) — fait (jalon 20)
**Actuel** : un seul Label qui empile 3 lignes de vocations, 2 lignes de stats et l'équipement avec affixes en retrait, sans icône ni repère visuel.
**Cible** :
```
VOCATIONS {TITLE}
[héros]  Combattant, niveau 6
         1 000 / 1 150 XP
[pioche] Mineur, niveau 3          Rattrapage ×2 {GOOD}
         10 / 490 XP
[encl.]  Forgeron, niveau 2        Rattrapage ×2 {GOOD}
         0 / 330 XP
STATS {TITLE}
PV 154  ATK 30  DEF 13
Cadence 1,20/s  Critique 5 % ×1,5
ÉQUIPEMENT {TITLE}
▾[épée]  Arme : Épée & Écu
         Commune, ilvl 1
  ┌ Enclume 3/3 {couleur d'École}
  │ ATK d'arme 10,4
  └ +1,2 ATK
▸[casque] Casque                   Supérieur {SUPERIOR}
          Bon, ilvl 3
▸[plastr] Plastron
          Vide          (fiche : « Forge-le à la Forge, ou purifie un Éclat »)
▸[bottes] Bottes
          Rares, ilvl 12
```
Vocations = `_line`. Équipement = 4 `_card` (une seule ouverte). Maquette rendue : jalon-20/maquette-jalon20.png.

### Sacoche (jalon 20) — fait (jalon 20)
**Actuel** : un Label de 3 lignes (Lanterne, Éclats, Coffre), le bouton Purifier et sa raison. L'ilvl des Éclats n'est visible nulle part.
**Cible** :
```
[feu]     Cendre 120/150
          Lanterne niveau 1
▾[cristal] Éclats 5/6, dont 2 d'Élite
           Purification au village ou au Brasero
  ┌ 2 Éclats d'Élite, ilvl 6 (en premier)
  │ 1 Éclat, ilvl 4
  └ 2 Éclats, ilvl 3
[filon]   Coffre : 12 minerais
          4 minerais par pièce à la Forge
[ Purifier un Éclat ]
Purification au village ou au Brasero {MUTED, si grisé}
```
L'ordre de la fiche est celui de Purification.next_index : Élite d'abord, puis l'ilvl le plus haut.

### Forge (jalon 20 bis) — fait (jalon 20 bis)
**Actuel** : une ligne « Tu as », un CheckButton « Avec Cendre (25) », une aide de 5 lignes, 4 boutons « Forger l'Arme… » et la raison.
**Cible** :
```
[filon] Minerai 12        [feu] Cendre 100        (2 _line courtes ou 1 ligne à 2 icônes)
MODE {TITLE}
[ Sans Cendre ][ Avec Cendre (25) ]               (_block : remplace le CheckButton)
Rareté : Commun 65 %, Bon 25 %, Rare 10 % {MUTED}
Qualité Supérieure : 20 % de chance, +2 ilvl {MUTED}
Pièce d'ilvl 6 (niveau de ton Forgeron) · +126 XP {MUTED}
FORGER {TITLE}
[épée]   Forger l'Arme
         Équipée : Commune, ilvl 1
[casque] Forger le Casque
         Équipé : vide
… (Plastron, Bottes)
Il manque 2 minerais {MUTED, si grisé}
```
Les 4 boutons d'action prennent l'icône de leur emplacement et rappellent la pièce équipée. Les textes de l'aide ne changent pas : ils viennent de forge_help.

### Carte d'Aperçu (jalon 20 bis) — fait (jalon 20 bis)
**Actuel** : Supérieure et verdict en couleur, puis un Label qui empile la nouvelle pièce, « Équipée », l'ancienne pièce et la ligne d'écart, avec les boutons Équiper et Jeter.
**Cible** :
```
[épée] Pièce purifiée                 Supérieure {SUPERIOR}
Meilleure que l'équipée {GOOD / BAD / TEXT}
NOUVELLE {TITLE}          ÉQUIPÉE {TITLE}
Bonne, ilvl 6             Commune, ilvl 1
Enclume 3/3               Enclume 3/3
ATK d'arme 12,1           ATK d'arme 10,4
+2,4 ATK                  +1,2 ATK
+3 % critique
PV +0 {TEXT}   ATK +3 {GOOD}   DEF -1 {BAD}
[ Équiper ]  [ Jeter ]
```
Deux colonnes de 144 px (le jumeau vérifie les largeurs), et un écart stat par stat coloré, avec le signe écrit.

### Options (jalon 20 bis) — fait (jalon 20 bis)
**Actuel** : un seul bouton « Crédits ».
**Cible** : une `_line` à icône [TT 83] « Crédits », avec « Licences des assets » en 2e ligne, qui ouvre l'écran Crédits. Les futures options suivront le même modèle.

### Rapport de veillée (jalon 20 ter)
**Actuel** : des Labels créés à chaque show_report, sans icône. C'est le seul endroit qui reconstruit de l'UI dans un show_*.
**Cible** : 6 `_line` créées une fois, masquées quand leur valeur est nulle.
```
[feu]    Absence comptée : 7 h 12
[pièce]  Or : +120 {GOOD} / -8 {BAD}
[pièce]  Frais fixes du jour : 3 Or
[encl.]  Outils remplacés : 1
[PNJ]    PNJ en grève : 1 {BAD}
[…]      Fiches de rupture : 2
Touche pour fermer {MUTED}
```

## Plié (jalon 20 ter)
- **Bandeau** : conforme (icône + valeur, sans l'Or). Rien à changer.
- **Jauge de saturation** : 2 px, aujourd'hui sans couleur de rôle. Cible : TEXT, puis BAD quand elle est pleine (budget atteint, Élite éveillé), sans aucun seuil nouveau.
- **Boutons d'aptitude** : « I » et « II », compte à rebours, tous validés sur Fold au jalon 12. Rien à changer. Une icône par aptitude demanderait un asset (accord d'Antho).
- **Toasts** : un Label nu. Cible : icône de la notion à gauche (vocation ou PNJ), texte en TEXT. Montée de niveau : « Mineur niveau 4 ! » avec la pioche. Une ligne en plié.
- **Rapport sous le bandeau** : absence + Or. Il prend les mêmes `_line` que le rapport déplié, en mode compact.

## Découpage (du plus visible au moins visible)
| Jalon | Contenu | APK | Test |
|---|---|---|---|
| 20 | ui_style.gd (couleurs par rôle + icônes centralisées), `_line`, Perso, Sacoche, 5 icônes DB32 | 0.20.0 (code 23) | Z10 |
| 20 bis | Forge (mode en rangée de choix, boutons à icône), carte d'Aperçu en 2 colonnes, Options | 0.20.1 (code 24) | Z11 |
| 20 ter | Rapport de veillée créé une fois, toasts à icône, jauge pleine en BAD | 0.20.2 (code 25) | Z12 |

## Questions
- **Antho** :
  1. accord sur les 5 icônes DB32 (CC0, même pack que l'Éclat du bandeau) ;
  2. pas de couleur de rareté en tranche (recommandé).
- **Argon**, au prochain message, sans bloquer : Enclume et Brasier ont des teintes proches (#E69F00 et #FF7A1A). Le nom écrit suffit. On lui demande seulement s'il veut écarter Brasier avant l'isolat 3. La question d'une couleur par École est déjà tranchée : elle existe dans BalanceC.
