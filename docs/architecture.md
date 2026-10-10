# Architecture

[English](architecture.en.md) | Français

MathTex sépare la reconnaissance de la syntaxe, la représentation et le dessin :

1. `Lexer` produit des tokens avec leur position (offset en octets).
2. `Parser` consomme les tokens récursivement et construit des nœuds typés via `AST`. Les commandes non enregistrées et les arguments invalides provoquent une erreur contextualisée.
3. `Layout` transforme l'AST en dimensions (largeur, hauteur, ligne de base) et en primitives positionnées. Il reçoit une fonction de mesure de texte au lieu de créer des instances Roblox.
4. `Backends.Native` convertit ces primitives en UI Roblox. `init.luau` valide les options, expose les objets d'expression et choisit un backend configuré.

Le contrat interne d'un backend est constitué d'une vérification `canRender(layout)` et d'une opération `render(layout, parent, options)`. Seul le backend natif est actuellement fourni. `Auto` ne sélectionne que ce backend et signale l'absence de compatibilité au lieu de produire un résultat factice.

L'API publique reste `MathTex.new(source, options)`, `expression:Measure()`, `expression:Render(parent)` et `expression:Destroy()`. Les erreurs de syntaxe, de validation et de rendu sont levées avec un message direct destiné à l'appelant.

Le layout calcule une taille intrinsèque à partir de `FontSize`. Le backend natif applique ensuite, par défaut, un facteur uniforme plafonné à `1` pour faire tenir le rendu dans un `GuiObject` ou le viewport courant d'un `ScreenGui`. Il suit les changements de taille et libère ses connexions à la destruction du rendu. `FitToContainer = false` désactive cet ajustement.
