--!strict

local AST = {}

export type OperatorStyle = "limits" | "integral" | "namedLimits"
export type Glyph = { kind: "Glyph", text: string, operatorStyle: OperatorStyle? }
export type Text = { kind: "Text", text: string }
export type Space = { kind: "Space", width: number }
export type Sequence = { kind: "Sequence", children: { Node } }
export type Group = { kind: "Group", body: Sequence }
export type FractionSize = "normal" | "display" | "text"
export type Fraction = { kind: "Fraction", numerator: Sequence, denominator: Sequence, size: FractionSize }
export type Root = { kind: "Root", body: Sequence, index: Sequence? }
export type AccentStyle = "vec" | "overline" | "underline" | "hat" | "bar"
export type Accent = { kind: "Accent", style: AccentStyle, body: Sequence }
export type TextStyle = "bold" | "roman"
export type Styled = { kind: "Styled", style: TextStyle, body: Sequence }
export type Scripts = { kind: "Scripts", base: Node, superscript: Node?, subscript: Node? }
export type Delimited = { kind: "Delimited", left: string, body: Sequence, right: string }
export type MatrixRow = { Sequence }
export type Matrix = { kind: "Matrix", rows: { MatrixRow } }
export type Aligned = { kind: "Aligned", rows: { MatrixRow } }
export type Node = Glyph | Text | Space | Sequence | Group | Fraction | Root | Accent | Styled | Scripts | Delimited | Matrix | Aligned

function AST.glyph(text: string, operatorStyle: OperatorStyle?): Glyph
	return { kind = "Glyph", text = text, operatorStyle = operatorStyle }
end

function AST.text(text: string): Text
	return { kind = "Text", text = text }
end

function AST.space(width: number): Space
	return { kind = "Space", width = width }
end

function AST.sequence(children: { Node }): Sequence
	return { kind = "Sequence", children = children }
end

function AST.group(body: Sequence): Group
	return { kind = "Group", body = body }
end

function AST.fraction(numerator: Sequence, denominator: Sequence, size: FractionSize?): Fraction
	return { kind = "Fraction", numerator = numerator, denominator = denominator, size = size or "normal" }
end

function AST.root(body: Sequence, index: Sequence?): Root
	return { kind = "Root", body = body, index = index }
end

function AST.accent(style: AccentStyle, body: Sequence): Accent
	return { kind = "Accent", style = style, body = body }
end

function AST.styled(style: TextStyle, body: Sequence): Styled
	return { kind = "Styled", style = style, body = body }
end

function AST.scripts(base: Node, superscript: Node?, subscript: Node?): Scripts
	return { kind = "Scripts", base = base, superscript = superscript, subscript = subscript }
end

function AST.delimited(left: string, body: Sequence, right: string): Delimited
	return { kind = "Delimited", left = left, body = body, right = right }
end

function AST.matrix(rows: { MatrixRow }): Matrix
	return { kind = "Matrix", rows = rows }
end

function AST.aligned(rows: { MatrixRow }): Aligned
	return { kind = "Aligned", rows = rows }
end

return AST
