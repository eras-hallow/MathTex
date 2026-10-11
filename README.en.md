# MathTex

[English](README.en.md) | [Français](README.md)

MathTex is an experimental Luau library that turns an explicit subset of LaTeX-inspired math syntax into native Roblox UI. It does not compile LaTeX and does not claim full LaTeX compatibility.

## Status

Usable prototype for common mathematical expressions. The public API is intentionally small, and the native backend uses no external services.

## Features

- Lexer with token categories and byte offsets in the source.
- Recursive parser with positioned diagnostics and a depth limit.
- ASCII and literal Unicode glyphs, numbers, ordinary operators, and registered symbol commands.
- Greek letters, selected operators and relations, arrows, and common symbols.
- Math spacing commands `\,`, `\:`, `\;`, `\quad`, `\qquad`, and `\!`.
- Superscripts and subscripts, grouped or ungrouped, including both on one atom.
- The native backend uses RichText internally to apply the computed size to each glyph. RichText tags in the source are not interpreted: `<`, `>`, and `&` are escaped and remain literal text.
- Each script level is laid out at 70% of its parent level's size. `\sum` and `\prod` are enlarged to 145%; when scripts are attached, their limits are centered. `\lim`, `\min`, `\max`, `\sup`, and `\inf` center their limits when scripted, without enlargement. `\int` is enlarged to 135% and retains side scripts.
- `\frac{numerator}{denominator}`, `\sqrt{content}`, and `\sqrt[index]{content}`, including nesting.
- Plain text with preserved spaces using `\text{...}` and `\operatorname{...}`.
- Vertically adaptive delimiters using `\left(...\right)`, `\left[...\right]`, `\left\{...\right\}`, and `\left|...\right|`.
- `matrix`, `pmatrix`, `bmatrix`, `Bmatrix`, `vmatrix`, `Vmatrix`, and `cases` environments, with column-count validation.
- Common operators such as `\sin`, `\cos`, `\log`, `\lim`, `\min`, `\max`, `\land`, and `\lor`.
- Literal parentheses and brackets; unescaped braces are grouping syntax.
- Layout based on `TextService:GetTextSize`; fractions, scripts, and roots are measured before rendering.
- Rendering with `Frame`, `TextLabel`, and bar `Frame` instances, with measurement, replacement without orphaned instances, and destruction. Rendering is limited to 1024 primitives per expression.

## Installation and Studio Sync

### Recommended: Roblox plugin

Install the [MathTex plugin from the Creator Store](https://create.roblox.com/store/asset/125824417127294/MathTex), then click **InstallMathTex** in its toolbar. The plugin downloads MathTex into `ReplicatedStorage.MathTex`.

To update MathTex, click **InstallMathTex** again. The plugin downloads the new version first, replaces the complete previous installation, and then cleans up the old module. Do not mix this installation with a Rojo-managed copy.

### Development with Rojo

Clone the repository, then open `default.project.json` in Rojo or run:

```sh
rojo serve default.project.json
```

Connect Roblox Studio to the Rojo server with the Rojo plugin. The library is mounted at `ReplicatedStorage.MathTex`; the test runner is at `ServerScriptService.MathTexTests`.

## Example

```lua
local MathTex = require(game:GetService("ReplicatedStorage").MathTex)

local equation = MathTex.render(
  script.Parent,
  [[\left(\frac{\text{average speed}}{2a}\right)^2]],
  { FontSize = 32, Color = Color3.new(1, 1, 1) }
)

if equation == nil then
  return -- The syntax error is already displayed in red in the container.
end

local size = equation:Measure()

-- Destroy the expression when it is no longer needed.
equation:Destroy()
```

### Writing an Equation in Luau

The math source is a string passed to MathTex; it is not evaluated as Lua code. A Luau long-bracket string preserves backslashes, so `\alpha` does not need to be written as `\\alpha`:

```lua
local source = [=[
\sum_{i=1}^{n} \frac{x_i^2}{\sqrt[3]{y}}
]=]
local equation = MathTex.render(container, source, { FontSize = 32 })
```

`[=[...]=]` also lets the content contain `]]` without ending the string. With a quoted Lua string, escape each backslash, for example `"\\alpha"`.
`container` must be a `GuiObject` (such as a `Frame`) or a `LayerCollector` (such as a `ScreenGui`). See the [complete client example](./examples/Basic.client.luau) for UI creation and Roblox setup.

The parser supports these constructs (whitespace outside `\text{...}` is ignored):

| Syntax | Example |
| --- | --- |
| Grouping and scripts | `x_{i+1}^{2}`; an unbraced script consumes one atom only (`x^ab` means `x` to the power `a`, followed by `b`). |
| Fractions and roots | `\frac{a}{b}`; `\dfrac{a}{b}` (normal size); `\tfrac{a}{b}` (smaller size); `\sqrt[3]{x}` |
| Math accents | `\vec{v}`, `\overline{AB}`, `\underline{x}`, `\hat{x}`, `\bar{x}` |
| Math text styles | `\mathbf{v}` for bold; `\mathrm{d}` for roman. |
| Literal text | `\text{average speed}`; content, including RichText tags, is not interpreted as commands. |
| Registered operators | `\alpha`, `\times`, `\le`, `\sin`, `\sum`, etc. See the full list in [Symbols.luau](./src/Symbols.luau). |
| Delimiters | `\left( ... \right)` and supported variants, including `\left\{ ... \right\}`. |
| Matrices | `\begin{bmatrix}a&b\\c&d\end{bmatrix}`; rows must have the same number of columns. |
| Aligned equations | `\begin{align}a&=b\\c&=d\end{align}`; each row needs an even number of cells, aligned at `&`. `aligned` is also supported. |
| Math spacing | `\,`, `\:`, `\;`, `\quad`, `\qquad`, `\!`. |

The parser does not implement full LaTeX: `\newcommand`, `\displaystyle`, `\textbf`, `\color`, `align*`, `array`, and automatic equation references are not supported. There is no `$...$` or `$$...$$` math mode; pass the expression directly without math-mode delimiters. Unknown commands raise an error.

`Render(parent)` accepts a `GuiObject` or `LayerCollector` (such as `ScreenGui`) and returns the created root `Frame`. By default, rendering fits a `GuiObject` or the `ScreenGui` viewport, shrinking uniformly without exceeding its base size and staying centered. If the container has no size yet, rendering is temporarily hidden until a size becomes available. Other `LayerCollector` instances retain a fixed size. Calling `Render` again destroys the previous rendering after creating the new one.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `FontSize` | integer from 1 to 256 | `32` | Base size in pixels. |
| `Color` | `Color3` | white | Text and bar color. |
| `Font` | `Enum.Font` | `Enum.Font.SourceSans` | Native Roblox font. |
| `Backend` | `"Auto"`, `"Native"`, or `"Image"` | `"Auto"` | Auto selects a configured compatible backend. Native forces native rendering. Image fails explicitly because no image provider is included. |
| `FitToContainer` | boolean | `true` | Shrinks rendering to fit a `GuiObject` or `ScreenGui`. Set to `false` to keep a fixed size and top-left anchor. |

For direct display, `MathTex.render(parent, source, options)` creates and renders an expression in one call, then returns the object for measurement or destruction. On syntax or option errors, it displays the error in red in the container and returns `nil`. Errors from `MathTex.new(...)` continue to raise normally. The `MathTex.new(...):Render(parent)` API remains available when you need to measure before rendering; rendering errors are displayed in red in the container.

Sources longer than 4096 bytes, unknown or invalid options, unknown commands, malformed groups, and missing or empty arguments are explicit errors: `MathTex.new` raises them, while `MathTex.render` displays them in red and returns `nil`. Ordinary whitespace is ignored according to mathematical convention.

## Known Limitations

- This is not a full TeX engine: macros, `array`, math styles, and many environments are unsupported. `align` and `aligned` provide only a simple alignment grid, without equation numbering or full TeX spacing. `\left` and `\right` enlarge supported glyphs, but do not reproduce all of TeX's delimiter typography.
- Supported commands are limited to those listed in `src/Symbols.luau`, along with the structural and spacing commands described above.
- Placement rules and metrics are a typographic approximation for UI, not a TeX engine. Font support for Unicode glyphs may vary.
- The image backend is absent. Roblox does not compile or interpret LaTeX source directly. A future extension would need a real, authorized provider (external generator or imported resources), a cache, and an explicit failure/fallback policy.
- This version makes no network calls and uses no image URLs. Any future network integration must document allowed domains in Roblox security settings, how resources are generated/loaded, and offline behavior.

## Tests

Tests are Luau specs with no external dependencies. With Rojo connected, start a Play session in Studio; `ServerScriptService.MathTexTests.TestRunner` runs automatically and prints results to Output. The runner checks the lexer, AST nodes, parser, layout, and API/rendering.

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

## Contributing

Contributions should add tests for new syntax and demonstrate the full lexer/parser/AST/layout/rendering path before claiming a feature is supported. Keep unknown commands as explicit errors and do not add fake backends. Open an issue to discuss API changes or extensions involving external services.

The registry can be extended before parsing by requiring `ReplicatedStorage.MathTex.Symbols` and calling `register` with a new alphabetic command name and its glyph. Extending the registry does not change the main public API.

## License

MathTex is distributed under the MIT license. See [LICENSE](LICENSE).
