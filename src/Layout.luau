--!strict

local AST = require(script.Parent.AST)

local Layout = {}

export type DrawItem = {
	kind: "Text" | "Rule",
	x: number,
	y: number,
	width: number,
	height: number,
	text: string?,
	fontSize: number?,
}

export type Result = {
	width: number,
	height: number,
	baseline: number,
	items: { DrawItem },
}

type MeasureText = (text: string, fontSize: number) -> Vector2
type Node = AST.Node

local function textResult(text: string, fontSize: number, measureText: MeasureText): Result
	local measured = measureText(text, fontSize)
	local height = math.max(fontSize, measured.Y + 2)
	local width = math.max(0, measured.X)
	return {
		width = width,
		height = height,
		baseline = height * 0.78,
		items = {
			{ kind = "Text", text = text, x = 0, y = 0, width = width, height = height, fontSize = fontSize },
		},
	}
end

local function shifted(items: { DrawItem }, x: number, y: number, into: { DrawItem })
	for _, item in items do
		table.insert(into, {
			kind = item.kind,
			text = item.text,
			x = item.x + x,
			y = item.y + y,
			width = item.width,
			height = item.height,
			fontSize = item.fontSize,
		})
	end
end

local layoutNode: (node: Node, fontSize: number, measureText: MeasureText) -> Result

local function layoutSequence(children: { Node }, fontSize: number, measureText: MeasureText): Result
	local boxes: { Result } = {}
	local positions: { number } = {}
	local baseline = 0
	local depth = 0
	local cursor = 0
	local minX = 0
	local maxX = 0
	for _, child in children do
		local box = layoutNode(child, fontSize, measureText)
		table.insert(boxes, box)
		table.insert(positions, cursor)
		cursor += box.width
		minX = math.min(minX, cursor)
		maxX = math.max(maxX, cursor)
		baseline = math.max(baseline, box.baseline)
		depth = math.max(depth, box.height - box.baseline)
	end

	local items: { DrawItem } = {}
	for index, box in boxes do
		shifted(box.items, positions[index] - minX, baseline - box.baseline, items)
	end
	return { width = maxX - minX, height = baseline + depth, baseline = baseline, items = items }
end

layoutNode = function(node: Node, fontSize: number, measureText: MeasureText): Result
	if node.kind == "Glyph" then
		return textResult(node.text, fontSize, measureText)
	elseif node.kind == "Space" then
		return { width = fontSize * node.width, height = fontSize, baseline = fontSize * 0.78, items = {} }
	elseif node.kind == "Sequence" then
		return layoutSequence(node.children, fontSize, measureText)
	elseif node.kind == "Group" then
		return layoutSequence(node.body.children, fontSize, measureText)
	elseif node.kind == "Fraction" then
		local numerator = layoutSequence(node.numerator.children, fontSize * 0.82, measureText)
		local denominator = layoutSequence(node.denominator.children, fontSize * 0.82, measureText)
		local padding = math.max(2, fontSize * 0.12)
		local gap = math.max(2, fontSize * 0.1)
		local width = math.max(numerator.width, denominator.width) + padding * 2
		local numeratorX = (width - numerator.width) / 2
		local denominatorX = (width - denominator.width) / 2
		local ruleY = numerator.height + gap
		local denominatorY = ruleY + gap + 1
		local items: { DrawItem } = {}
		shifted(numerator.items, numeratorX, 0, items)
		table.insert(items, { kind = "Rule", x = 0, y = ruleY, width = width, height = 1 })
		shifted(denominator.items, denominatorX, denominatorY, items)
		return {
			width = width,
			height = denominatorY + denominator.height,
			baseline = ruleY + 0.5,
			items = items,
		}
	elseif node.kind == "Root" then
		local body = layoutSequence(node.body.children, fontSize, measureText)
		local radicalFontSize = math.max(fontSize, body.height * 0.88)
		local radical = textResult("√", radicalFontSize, measureText)
		local indexBox: Result? = nil
		if node.index ~= nil then
			indexBox = layoutSequence(node.index.children, fontSize * 0.52, measureText)
		end
		local indexWidth = if indexBox ~= nil then indexBox.width else 0
		local gap = math.max(1, fontSize * 0.04)
		local radicalX = indexWidth
		local bodyX = radicalX + radical.width + gap
		local baseline = math.max(radical.baseline, body.baseline)
		local radicalY = baseline - radical.baseline
		local bodyY = baseline - body.baseline
		local top = math.min(radicalY, bodyY)
		radicalY -= top
		bodyY -= top
		local height = math.max(radicalY + radical.height, bodyY + body.height)
		local items: { DrawItem } = {}
		if indexBox ~= nil then
			shifted(indexBox.items, 0, 0, items)
		end
		shifted(radical.items, radicalX, radicalY, items)
		shifted(body.items, bodyX, bodyY, items)
		table.insert(items, {
			kind = "Rule",
			x = bodyX,
			y = math.max(0, bodyY - 1),
			width = body.width + 1,
			height = 1,
		})
		return { width = bodyX + body.width + 1, height = height, baseline = baseline - top, items = items }
	elseif node.kind == "Scripts" then
		local base = layoutNode(node.base, fontSize, measureText)
		local scriptFontSize = fontSize * 0.7
		local superscript = if node.superscript ~= nil then layoutNode(node.superscript, scriptFontSize, measureText) else nil
		local subscript = if node.subscript ~= nil then layoutNode(node.subscript, scriptFontSize, measureText) else nil
		local superscriptY = if superscript ~= nil then base.baseline - fontSize * 0.88 - superscript.height else 0
		local subscriptY = if subscript ~= nil then base.baseline + fontSize * 0.08 else 0
		local top = math.min(0, superscriptY)
		local bottom = math.max(base.height, if subscript ~= nil then subscriptY + subscript.height else 0)
		local items: { DrawItem } = {}
		shifted(base.items, 0, -top, items)
		if superscript ~= nil then
			shifted(superscript.items, base.width, superscriptY - top, items)
		end
		if subscript ~= nil then
			shifted(subscript.items, base.width, subscriptY - top, items)
		end
		local scriptWidth = math.max(
			if superscript ~= nil then superscript.width else 0,
			if subscript ~= nil then subscript.width else 0
		)
		return {
			width = base.width + scriptWidth,
			height = bottom - top,
			baseline = base.baseline - top,
			items = items,
		}
	end

	error("MathTex layout: unsupported AST node", 0)
end

function Layout.calculate(node: Node, fontSize: number, measureText: MeasureText): Result
	return layoutNode(node, fontSize, measureText)
end

function Layout.fitScale(layout: Result, availableSize: Vector2): number
	if availableSize.X <= 0 or availableSize.Y <= 0 then
		return 1
	end
	return math.min(1, availableSize.X / math.max(layout.width, 1), availableSize.Y / math.max(layout.height, 1))
end

return Layout
