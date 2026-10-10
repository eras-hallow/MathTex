--!strict

local AST = {}

export type Glyph = { kind: "Glyph", text: string }
export type Space = { kind: "Space", width: number }
export type Sequence = { kind: "Sequence", children: { Node } }
export type Group = { kind: "Group", body: Sequence }
export type Fraction = { kind: "Fraction", numerator: Sequence, denominator: Sequence }
export type Root = { kind: "Root", body: Sequence, index: Sequence? }
export type Scripts = { kind: "Scripts", base: Node, superscript: Node?, subscript: Node? }
export type Node = Glyph | Space | Sequence | Group | Fraction | Root | Scripts

function AST.glyph(text: string): Glyph
	return { kind = "Glyph", text = text }
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

function AST.fraction(numerator: Sequence, denominator: Sequence): Fraction
	return { kind = "Fraction", numerator = numerator, denominator = denominator }
end

function AST.root(body: Sequence, index: Sequence?): Root
	return { kind = "Root", body = body, index = index }
end

function AST.scripts(base: Node, superscript: Node?, subscript: Node?): Scripts
	return { kind = "Scripts", base = base, superscript = superscript, subscript = subscript }
end

return AST
