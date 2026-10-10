--!strict

local Parser = require(game:GetService("ReplicatedStorage").MathTex.Parser)

local function expectFailure(source: string, expected: string)
	local ok, problem = pcall(function()
		Parser.parse(source)
	end)
	assert(not ok, "Expected parsing to fail for " .. source)
	assert(string.find(tostring(problem), expected, 1, true) ~= nil, tostring(problem))
end

return function()
	local simple = Parser.parse("x+12")
	assert(#simple.children == 3 and simple.children[2].kind == "Glyph")

	local scripts = Parser.parse("x_i^2")
	assert(scripts.children[1].kind == "Scripts")

	local fraction = Parser.parse([[\frac{a}{\sqrt[3]{b^2}}]])
	local fractionNode = fraction.children[1]
	assert(fractionNode.kind == "Fraction")
	if fractionNode.kind == "Fraction" then
		local nestedRoot = fractionNode.denominator.children[1]
		assert(nestedRoot.kind == "Root")
		if nestedRoot.kind == "Root" then
			assert(nestedRoot.index ~= nil)
			assert(nestedRoot.body.children[1].kind == "Scripts")
		end
	end

	local unicode = Parser.parse("λ+β")
	local firstGreek = unicode.children[1]
	local secondGreek = unicode.children[3]
	assert(firstGreek.kind == "Glyph" and firstGreek.text == "λ")
	assert(secondGreek.kind == "Glyph" and secondGreek.text == "β")
	local bracketed = Parser.parse("[x]")
	assert(bracketed.children[1].text == "[" and bracketed.children[3].text == "]")
	assert(Parser.parse("x^ 2").children[1].kind == "Scripts")

	expectFailure("\\unknown", "unknown command")
	expectFailure("{x", "missing closing brace")
	expectFailure("\\frac{x}", "expects a braced argument")
	expectFailure("x^", "script marker must be followed")
	expectFailure("\\sqrt[n{x}", "missing closing bracket")
	expectFailure("x^a^b", "duplicate superscript")
	expectFailure("\\frac{}{x}", "argument cannot be empty")
	expectFailure(string.rep("{", 130) .. "x" .. string.rep("}", 130), "maximum nesting depth")
	expectFailure("x}", "unexpected closing brace")
end
