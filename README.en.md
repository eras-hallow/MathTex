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
- `\frac{numerator}{denominator}`, `\sqrt{content}`, and `\sqrt[index]{content}`, including nesting.
- Literal parentheses and brackets; unescaped braces are grouping syntax.
- Layout based on `TextService:GetTextSize`; fractions, scripts, and roots are measured before rendering.
- Rendering with `Frame`, `TextLabel`, and bar `Frame` instances, with measurement, replacement without orphaned instances, and destruction. Rendering is limited to 1024 primitives per expression.

`\sum`, `\prod`, and `\int` are currently glyphs with standard script placement. Specialized limit placement for large operators is not implemented.

## Installation and Studio Sync

Clone the repository, then open `default.project.json` in Rojo or run:

```sh
rojo serve default.project.json
```

Connect Roblox Studio to the Rojo server with the Rojo plugin. The library is mounted at `ReplicatedStorage.MathTex`; the test runner is at `ServerScriptService.MathTexTests`.

## Example

```lua
local MathTex = require(game:GetService("ReplicatedStorage").MathTex)

local equation = MathTex.new(
	[[\frac{-b+\sqrt{b^2-4ac}}{2a}]],
	{
		FontSize = 32,
		Color = Color3.new(1, 1, 1),
		Backend = "Auto",
	}
)

local size = equation:Measure()
local rendered = equation:Render(script.Parent)

-- Destroy the expression when it is no longer needed.
equation:Destroy()
```

`Render(parent)` accepts a `GuiObject` or `LayerCollector` (such as `ScreenGui`) and returns the created root `Frame`. By default, rendering fits a `GuiObject` or the `ScreenGui` viewport, shrinking uniformly without exceeding its base size and staying centered. Other `LayerCollector` instances retain a fixed size. Calling `Render` again destroys the previous rendering after creating the new one.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `FontSize` | integer from 1 to 256 | `32` | Base size in pixels. |
| `Color` | `Color3` | white | Text and bar color. |
| `Font` | `Enum.Font` | `Enum.Font.SourceSans` | Native Roblox font. |
| `Backend` | `"Auto"`, `"Native"`, or `"Image"` | `"Auto"` | Auto selects a configured compatible backend. Native forces native rendering. Image fails explicitly because no image provider is included. |
| `FitToContainer` | boolean | `true` | Shrinks rendering to fit a `GuiObject` or `ScreenGui`. Set to `false` to keep a fixed size and top-left anchor. |

Sources longer than 4096 bytes, unknown or invalid options, unknown commands, malformed groups, and missing or empty arguments produce explicit errors. Ordinary whitespace is ignored according to mathematical convention.

## Known Limitations

- This is not a TeX engine and does not support macros, environments, matrices, alignments, math styles, or extensible delimiters.
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

## Contributing

Contributions should add tests for new syntax and demonstrate the full lexer/parser/AST/layout/rendering path before claiming a feature is supported. Keep unknown commands as explicit errors and do not add fake backends. Open an issue to discuss API changes or extensions involving external services.

The registry can be extended before parsing by requiring `ReplicatedStorage.MathTex.Symbols` and calling `register` with a new alphabetic command name and its glyph. Extending the registry does not change the main public API.

## License

MathTex is distributed under the MIT license. See [LICENSE](LICENSE).