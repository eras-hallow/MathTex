--!strict

local Layout = require(game:GetService("ReplicatedStorage").MathTex.Layout)
local Parser = require(game:GetService("ReplicatedStorage").MathTex.Parser)

local function measureText(text: string, fontSize: number): Vector2
	return Vector2.new(#text * fontSize * 0.5, fontSize)
end

return function()
	local simple = Layout.calculate(Parser.parse("x+1"), 20, measureText)
	assert(simple.width > 0 and simple.height >= 20)
	assert(#simple.items == 3)

	local fraction = Layout.calculate(Parser.parse([[\frac{a}{bc}]]), 20, measureText)
	assert(fraction.width > 0 and fraction.height > 20)
	local rules = 0
	for _, item in fraction.items do
		if item.kind == "Rule" then
			rules += 1
		end
	end
	assert(rules == 1)

	local nested = Layout.calculate(Parser.parse([[\sqrt{\frac{x_1}{y^2}}]]), 24, measureText)
	assert(nested.width > fraction.width and nested.height > 0)

	local halfSize = Vector2.new(simple.width / 2, simple.height / 2)
	assert(math.abs(Layout.fitScale(simple, halfSize) - 0.5) < 0.001)
	assert(Layout.fitScale(simple, Vector2.new(simple.width * 2, simple.height * 2)) == 1)

	local text = Layout.calculate(Parser.parse([=[\text{vitesse moyenne}]=]), 20, measureText)
	assert(text.width > Layout.calculate(Parser.parse("vitesse"), 20, measureText).width)
	local delimiters = Layout.calculate(Parser.parse([=[\left(\frac{a}{b}\right]=]), 20, measureText)
	assert(delimiters.height > fraction.height and #delimiters.items > #fraction.items)
	local matrix = Layout.calculate(Parser.parse([=[\begin{bmatrix}a&bb\\ccc&d\end{bmatrix}]=]), 20, measureText)
	assert(matrix.width > simple.width and matrix.height > simple.height and #matrix.items > 0)
end
