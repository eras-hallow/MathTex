--!strict

local AST = require(game:GetService("ReplicatedStorage").MathTex.AST)

return function()
	local glyph = AST.glyph("x")
	assert(glyph.kind == "Glyph" and glyph.text == "x")

	local sequence = AST.sequence({ glyph })
	local group = AST.group(sequence)
	assert(group.kind == "Group" and group.body.children[1].kind == "Glyph")

	local fraction = AST.fraction(sequence, AST.sequence({ AST.glyph("2") }), "display")
	assert(fraction.kind == "Fraction" and fraction.numerator.children[1].kind == "Glyph")
	assert(fraction.size == "display")

	local root = AST.root(sequence, nil)
	local scripts = AST.scripts(root, AST.glyph("2"), nil)
	assert(scripts.kind == "Scripts" and scripts.superscript ~= nil)

	local vector = AST.accent("vec", sequence)
	local bold = AST.styled("bold", sequence)
	local aligned = AST.aligned({ { sequence, sequence } })
	assert(vector.kind == "Accent" and bold.kind == "Styled" and aligned.kind == "Aligned")
end
