# Architecture

[English](architecture.en.md) | Français

MathTex sépare la reconnaissance de la syntaxe, la représentation et le dessin :

1. `Lexer` produit des tokens avec leur position (offset en octets).
2. `Parser` consomme les tokens récursivement et construit des nœuds typés via `AST`. Les commandes non enregistrées et les arguments invalides provoquent une erreur contextualisée.
3. `Layout` transforme l'AST en dimensions (largeur, hauteur, ligne de base) et en primitives positionnées. Il reçoit une fonction de mesure de texte au lieu de créer des instances Roblox. Les nœuds texte préservent les espaces internes; les matrices centrent leurs cellules; `align` et `aligned` alignent alternativement les cellules avant et après `&`; les accents ajoutent leurs marques et les styles de texte sont conservés sur les primitives.
4. `Backends.Native` convertit ces primitives en UI Roblox. Chaque primitive texte est rendue dans un `TextLabel` avec une balise RichText de taille générée par le backend; le texte de la source est échappé avant insertion et ses balises RichText ne sont pas interprétées. `init.luau` valide les options, expose les objets d'expression et choisit un backend configuré.

Le contrat interne d'un backend est constitué d'une vérification `canRender(layout)` et d'une opération `render(layout, parent, options)`. Seul le backend natif est actuellement fourni. `Auto` ne sélectionne que ce backend et signale l'absence de compatibilité au lieu de produire un résultat factice.

L'API publique reste `MathTex.new(source, options)`, `expression:Measure()`, `expression:Render(parent)` et `expression:Destroy()`. Les erreurs de syntaxe, de validation et de rendu sont levées avec un message direct destiné à l'appelant.

`MathTex.render(parent, source, options)` est le raccourci pour créer et afficher une expression en un appel, tout en retournant l'objet pour le mesurer ou le détruire.

Le layout calcule une taille intrinsèque à partir de `FontSize`. Le backend natif applique ensuite, par défaut, un facteur uniforme plafonné à `1` pour faire tenir le rendu dans un `GuiObject` ou le viewport courant d'un `ScreenGui`. Il suit les changements de taille et libère ses connexions à la destruction du rendu. `FitToContainer = false` désactive cet ajustement.
