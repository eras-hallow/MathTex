# Architecture

[English](architecture.en.md) | [Français](architecture.md)

MathTex separates syntax recognition, representation, and drawing:

1. `Lexer` produces tokens with their source positions (byte offsets).
2. `Parser` recursively consumes tokens and builds typed nodes through `AST`. Unknown commands and invalid arguments raise contextual errors.
3. `Layout` transforms the AST into dimensions (width, height, baseline) and positioned primitives. It receives a text-measurement function instead of creating Roblox instances.
4. `Backends.Native` converts these primitives into Roblox UI. `init.luau` validates options, exposes expression objects, and selects a configured backend.

A backend's internal contract consists of a `canRender(layout)` check and a `render(layout, parent, options)` operation. Only the native backend is currently provided. `Auto` selects only that backend and reports missing compatibility instead of producing a fake result.

The public API remains `MathTex.new(source, options)`, `expression:Measure()`, `expression:Render(parent)`, and `expression:Destroy()`. Syntax, validation, and rendering errors are raised with a direct message for the caller.

Layout computes intrinsic dimensions from `FontSize`. By default, the native backend then applies a uniform scale capped at `1` so rendering fits a `GuiObject` or the current `ScreenGui` viewport. It tracks size changes and releases its connections when the rendering is destroyed. Set `FitToContainer = false` to disable this behavior.