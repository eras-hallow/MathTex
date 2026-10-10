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
	local inlineText = Parser.parse([[\text{vitesse moyenne} = \operatorname{moyenne}]])
	assert(inlineText.children[1].kind == "Text" and inlineText.children[1].text == "vitesse moyenne")
	assert(inlineText.children[3].kind == "Text" and inlineText.children[3].text == "moyenne")
	local delimited = Parser.parse([=[\left(\frac{a}{b}\right]=])
	assert(delimited.children[1].kind == "Delimited")
	local invisibleDelimiter = Parser.parse([=[\left. x \right|]=])
	assert(invisibleDelimiter.children[1].kind == "Delimited")
	assert(Parser.parse([=[\sin(x)+\log(y)]=]).children[1].kind == "Glyph")
	local matrix = Parser.parse([=[\begin{pmatrix}a&b\\c&d\end{pmatrix}]=])
	local matrixContainer = matrix.children[1]
	assert(matrixContainer.kind == "Delimited" and matrixContainer.left == "(" and matrixContainer.right == ")")
	if matrixContainer.kind == "Delimited" then
		local matrixNode = matrixContainer.body.children[1]
		assert(matrixNode.kind == "Matrix")
		if matrixNode.kind == "Matrix" then
			assert(#matrixNode.rows == 2 and #matrixNode.rows[1] == 2 and #matrixNode.rows[2] == 2)
		end
	end
	local cases = Parser.parse([=[\begin{cases}x&x>0\\-x&x\le0\end{cases}]=]).children[1]
	assert(cases.kind == "Delimited" and cases.left == "{" and cases.right == "")

	expectFailure("\\unknown", "unknown command")
	expectFailure("{x", "missing closing brace")
	expectFailure("\\frac{x}", "expects a braced argument")
	expectFailure("x^", "script marker must be followed")
	expectFailure("\\sqrt[n{x}", "missing closing bracket")
	expectFailure("x^a^b", "duplicate superscript")
	expectFailure("\\frac{}{x}", "argument cannot be empty")
	expectFailure(string.rep("{", 130) .. "x" .. string.rep("}", 130), "maximum nesting depth")
	expectFailure("x}", "unexpected closing brace")
	expectFailure([=[\left(x]=], "missing \\right")
	expectFailure([=[\right)]=], "no matching \\left")
	expectFailure([=[\begin{matrix}a&b\\c\end{matrix}]=], "same number of columns")
	expectFailure([=[\begin{align}x&=y\end{align}]=], "unsupported environment")
end
