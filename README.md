# MathTex

[English](README.en.md) | Français

MathTex est une bibliothèque Luau expérimentale qui transforme un sous-ensemble explicite de la syntaxe mathématique inspirée de LaTeX en interface Roblox native. Elle ne compile pas du LaTeX et ne prétend pas être compatible avec LaTeX dans son ensemble.

## Statut

Prototype utilisable pour des expressions mathématiques courantes. L'API publique est volontairement petite et le backend natif n'utilise aucun service externe.

## Fonctionnalités disponibles

- Lexer avec catégories de tokens et positions en octets dans la source.
- Parser récursif avec groupes, diagnostics positionnés et limite de profondeur.
- Glyphes ASCII et Unicode littéraux, nombres, opérateurs ordinaires et commandes de symboles du registre.
- Lettres grecques, quelques opérateurs et relations, flèches et symboles usuels.
- Espaces mathématiques `\,`, `\:`, `\;`, `\quad`, `\qquad` et `\!`.
- Exposants et indices, seuls ou groupés, y compris les deux sur un même atome.
- `\frac{numérateur}{dénominateur}`, `\sqrt{contenu}` et `\sqrt[indice]{contenu}`, y compris l'imbrication.
- Texte courant avec espaces préservés via `\text{...}` et `\operatorname{...}`.
- Délimiteurs verticaux adaptatifs via `\left(...\right)`, `\left[...\right]`, `\left\{...\right\}` et `\left|...\right|`.
- Matrices `matrix`, `pmatrix`, `bmatrix`, `Bmatrix`, `vmatrix`, `Vmatrix` et `cases`, avec validation du nombre de colonnes.
- Opérateurs courants comme `\sin`, `\cos`, `\log`, `\lim`, `\min`, `\max`, `\land` et `\lor`.
- Parenthèses et crochets littéraux ; les accolades non échappées servent au groupement.
- Mise en page fondée sur les mesures de `TextService:GetTextSize`; fractions, scripts et racines ont des boîtes calculées avant le rendu.
- Rendu en `Frame`, `TextLabel` et `Frame` de barre, avec mesure, nouveau rendu sans orphelins, et destruction. Le rendu est limité à 1024 primitives par expression.

`\sum`, `\prod` et `\int` sont pour l'instant des glyphes avec placement standard des scripts. Les limites typographiques spécifiques des grands opérateurs ne sont pas implémentées.

## Installation et synchronisation Studio

Clonez le dépôt, puis ouvrez `default.project.json` dans Rojo ou lancez :

```sh
rojo serve default.project.json
```

Connectez Roblox Studio au serveur Rojo avec le plugin Rojo. La bibliothèque est montée dans `ReplicatedStorage.MathTex`; le runner de tests est dans `ServerScriptService.MathTexTests`.

## Exemple

```lua
local MathTex = require(game:GetService("ReplicatedStorage").MathTex)

local equation = MathTex.render(
  script.Parent,
  [[\left(\frac{\text{vitesse moyenne}}{2a}\right)^2]],
  { FontSize = 32, Color = Color3.new(1, 1, 1) }
)

local size = equation:Measure()

-- Quand le rendu n'est plus nécessaire :
equation:Destroy()
```

`Render(parent)` accepte un `GuiObject` ou un `LayerCollector` (`ScreenGui`, par exemple) et retourne le `Frame` racine créé. Par défaut, le rendu s'adapte à la taille d'un `GuiObject` ou du viewport d'un `ScreenGui`; il se réduit sans dépasser sa taille de base et reste centré. Les autres `LayerCollector` conservent une taille fixe. Un nouvel appel à `Render` détruit le rendu précédent après la création du nouveau.

## Options

| Option | Type | Valeur par défaut | Description |
| --- | --- | --- | --- |
| `FontSize` | entier de 1 à 256 | `32` | Taille de base en pixels. |
| `Color` | `Color3` | blanc | Couleur du texte et des barres. |
| `Font` | `Enum.Font` | `Enum.Font.SourceSans` | Police native Roblox. |
| `Backend` | `"Auto"`, `"Native"` ou `"Image"` | `"Auto"` | Auto choisit un backend compatible configuré. Native impose le rendu natif. Image échoue explicitement car aucun fournisseur d'images n'est inclus. |
| `FitToContainer` | booléen | `true` | Réduit le rendu pour qu'il tienne dans un `GuiObject` ou un `ScreenGui`. Mettre à `false` pour conserver une taille fixe et un ancrage en haut à gauche. |

Pour un affichage direct, `MathTex.render(parent, source, options)` crée et affiche l'expression en un appel, puis retourne l'objet pour le mesurer ou le détruire. L'API `MathTex.new(...):Render(parent)` reste disponible si la mesure doit précéder le rendu.

Les sources dépassant 4096 octets, les options inconnues ou invalides, les commandes inconnues, les groupes malformés et les arguments manquants ou vides produisent une erreur explicite. Les espaces blancs ordinaires sont ignorés selon la convention mathématique.

## Limites connues

- Ce projet n'est pas un moteur TeX complet: les macros, `array`, `align`, les styles mathématiques et de nombreux environnements ne sont pas pris en charge. `\left` et `\right` agrandissent les glyphes pris en charge, sans reproduire toute la typographie TeX des délimiteurs.
- Les commandes prises en charge sont uniquement celles répertoriées dans `src/Symbols.luau`, ainsi que les commandes structurelles et d'espacement décrites ci-dessus.
- Les règles de placement et métriques sont une approximation typographique pour UI, pas un moteur TeX. Les polices peuvent différer dans leur prise en charge des glyphes Unicode.
- Le backend image est absent. Roblox ne compile ni n'interprète les sources LaTeX directement. Une future extension devra fournir un fournisseur réel et autorisé (générateur externe ou ressources importées), un cache et une politique explicite d'échec/repli.
- Aucun appel réseau ni aucune URL d'image n'est utilisé ou autorisé par cette version. Si une intégration réseau est développée, elle devra documenter les domaines autorisés dans les paramètres de sécurité Roblox, le mode de génération/chargement des ressources et le comportement hors ligne.

## Tests

Les tests sont des specs Luau sans dépendance externe. Avec Rojo connecté, lancez une session Play dans Studio ; le script `ServerScriptService.MathTexTests.TestRunner` s'exécute automatiquement et affiche les résultats dans Output. Le runner vérifie le lexer, les nœuds AST, le parser, la mise en page et l'API/rendu.

## Structure

```text
src/
  init.luau
  AST.luau
  Lexer.luau
  Parser.luau
  Layout.luau
  Symbols.luau
  Backends/Native.luau
examples/
tests/
default.project.json
```
[![Architecture diagram of eras-hallow/mathtex](https://gitdiagram.com/eras-hallow/mathtex/diagram.png)](https://gitdiagram.com/eras-hallow/mathtex?utm_source=readme&utm_medium=picture)

## Contribuer

Les contributions doivent ajouter des tests aux nouvelles syntaxes et démontrer le chemin complet lexer/parser/AST/layout/rendu avant d'annoncer une fonctionnalité prise en charge. Gardez les commandes inconnues en erreur explicite et n'ajoutez pas de backend factice. Ouvrez une issue pour discuter des changements d'API ou des extensions impliquant des services externes.

Le registre peut être étendu avant le parsing en important `ReplicatedStorage.MathTex.Symbols` et en appelant `register` avec un nom de commande alphabétique inédit et son glyphe. Une extension de registre ne modifie pas l'API publique principale.

## Licence

MathTex est distribué sous licence MIT. Voir [LICENSE](LICENSE).
