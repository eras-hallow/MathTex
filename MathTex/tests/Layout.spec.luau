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
end
