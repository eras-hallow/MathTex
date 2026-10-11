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

	local displayFraction = Layout.calculate(Parser.parse([=[\dfrac{a}{b}]=]), 20, measureText)
	local textFraction = Layout.calculate(Parser.parse([=[\tfrac{a}{b}]=]), 20, measureText)
	assert(displayFraction.items[1].fontSize == 20)
	assert(textFraction.items[1].fontSize == 14)

	local nested = Layout.calculate(Parser.parse([[\sqrt{\frac{x_1}{y^2}}]]), 24, measureText)
	assert(nested.width > fraction.width and nested.height > 0)

	local vector = Layout.calculate(Parser.parse([=[\vec{AB}]=]), 20, measureText)
	local vectorRules = 0
	for _, item in vector.items do
		if item.kind == "Rule" then
			vectorRules += 1
		end
	end
	assert(vectorRules == 3 and vector.height > 20)

	local accents = Layout.calculate(Parser.parse([=[\overline{AB}\underline{CD}\hat{x}\bar{y}]=]), 20, measureText)
	assert(accents.height > 20 and #accents.items > 8)

	local styled = Layout.calculate(Parser.parse([=[\mathbf{AB}\mathrm{d}x]=]), 20, measureText)
	local hasBold = false
	local hasRoman = false
	for _, item in styled.items do
		hasBold = hasBold or item.bold == true
		hasRoman = hasRoman or item.roman == true
	end
	assert(hasBold and hasRoman)

	local aligned = Layout.calculate(Parser.parse([=[\begin{align}a&=b\\long&=c\end{align}]=]), 20, measureText)
	local equalsPositions: { number } = {}
	for _, item in aligned.items do
		if item.text == "=" then
			table.insert(equalsPositions, item.x)
		end
	end
	assert(#equalsPositions == 2 and equalsPositions[1] == equalsPositions[2])

	local standaloneSum = Layout.calculate(Parser.parse([[\sum]]), 20, measureText)
	assert(standaloneSum.items[1].fontSize == 29)

	local largeOperator = Layout.calculate(Parser.parse([[\sum_{i=1}^{n}]]), 20, measureText)
	local sumGlyph = nil
	local upperLimit = nil
	local lowerLimit = nil
	for _, item in largeOperator.items do
		if item.text == "∑" then
			sumGlyph = item
		elseif item.text == "n" then
			upperLimit = item
		elseif item.text == "i" then
			lowerLimit = item
		end
	end
	assert(sumGlyph ~= nil and sumGlyph.fontSize == 29)
	assert(upperLimit ~= nil and upperLimit.fontSize == 14 and upperLimit.y < sumGlyph.y)
	assert(lowerLimit ~= nil and lowerLimit.fontSize == 14 and lowerLimit.y > sumGlyph.y)

	local integral = Layout.calculate(Parser.parse([[\int_{a}^{b}]]), 20, measureText)
	local integralGlyph = nil
	local integralLimit = nil
	for _, item in integral.items do
		if item.text == "∫" then
			integralGlyph = item
		elseif item.text == "b" then
			integralLimit = item
		end
	end
	assert(integralGlyph ~= nil and integralGlyph.fontSize == 27)
	assert(integralLimit ~= nil and integralLimit.x >= integralGlyph.width)

	local namedLimit = Layout.calculate(Parser.parse([[\lim_{x\to0}]]), 20, measureText)
	assert(namedLimit.height > 20)

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
