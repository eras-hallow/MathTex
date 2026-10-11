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
	bold: boolean?,
	roman: boolean?,
	rotation: number?,
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
			bold = item.bold,
			roman = item.roman,
			rotation = item.rotation,
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

local function layoutGrid(
	rows: { AST.MatrixRow },
	fontSize: number,
	measureText: MeasureText,
	columnGapScale: number,
	rowGapScale: number,
	alignedColumns: boolean
): Result
	local cells: { { Result } } = {}
	local columnWidths: { number } = {}
	local rowHeights: { number } = {}
	for rowIndex, row in rows do
		local measuredRow: { Result } = {}
		local rowHeight = 0
		for columnIndex, cell in row do
			local box = layoutSequence(cell.children, fontSize, measureText)
			measuredRow[columnIndex] = box
			columnWidths[columnIndex] = math.max(columnWidths[columnIndex] or 0, box.width)
			rowHeight = math.max(rowHeight, box.height)
		end
		cells[rowIndex] = measuredRow
		rowHeights[rowIndex] = rowHeight
	end

	local columnGap = fontSize * columnGapScale
	local rowGap = fontSize * rowGapScale
	local width = 0
	for _, columnWidth in columnWidths do
		width += columnWidth
	end
	width += math.max(0, #columnWidths - 1) * columnGap
	local height = 0
	for _, rowHeight in rowHeights do
		height += rowHeight
	end
	height += math.max(0, #rowHeights - 1) * rowGap

	local items: { DrawItem } = {}
	local y = 0
	for rowIndex, measuredRow in cells do
		local x = 0
		for columnIndex, box in measuredRow do
			local horizontalOffset = if alignedColumns
				then if columnIndex % 2 == 0 then 0 else columnWidths[columnIndex] - box.width
				else (columnWidths[columnIndex] - box.width) / 2
			shifted(box.items, x + horizontalOffset, y + (rowHeights[rowIndex] - box.height) / 2, items)
			x += columnWidths[columnIndex] + columnGap
		end
		y += rowHeights[rowIndex] + rowGap
	end
	return { width = width, height = height, baseline = height / 2, items = items }
end

layoutNode = function(node: Node, fontSize: number, measureText: MeasureText): Result
	if node.kind == "Glyph" then
		local glyphScale = if node.operatorStyle == "limits" then 1.45 elseif node.operatorStyle == "integral" then 1.35 else 1
		return textResult(node.text, fontSize * glyphScale, measureText)
	elseif node.kind == "Text" then
		return textResult(node.text, fontSize, measureText)
	elseif node.kind == "Space" then
		return { width = fontSize * node.width, height = fontSize, baseline = fontSize * 0.78, items = {} }
	elseif node.kind == "Sequence" then
		return layoutSequence(node.children, fontSize, measureText)
	elseif node.kind == "Group" then
		return layoutSequence(node.body.children, fontSize, measureText)
	elseif node.kind == "Fraction" then
		local fractionScale = if node.size == "display" then 1 elseif node.size == "text" then 0.7 else 0.82
		local numerator = layoutSequence(node.numerator.children, fontSize * fractionScale, measureText)
		local denominator = layoutSequence(node.denominator.children, fontSize * fractionScale, measureText)
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
	elseif node.kind == "Accent" then
		local body = layoutSequence(node.body.children, fontSize, measureText)
		local items: { DrawItem } = {}
		if node.style == "underline" then
			shifted(body.items, 0, 0, items)
			table.insert(items, {
				kind = "Rule",
				x = 0,
				y = body.height + math.max(1, fontSize * 0.06),
				width = body.width,
				height = 1,
			})
			return {
				width = body.width,
				height = body.height + math.max(2, fontSize * 0.12),
				baseline = body.baseline,
				items = items,
			}
		elseif node.style == "overline" then
			local gap = math.max(1, fontSize * 0.06)
			shifted(body.items, 0, gap + 1, items)
			table.insert(items, { kind = "Rule", x = 0, y = 0, width = body.width, height = 1 })
			return { width = body.width, height = body.height + gap + 1, baseline = body.baseline + gap + 1, items = items }
		elseif node.style == "vec" then
			local headLength = math.min(fontSize * 0.35, body.width * 0.35)
			local headHeight = headLength * 0.58
			local arrowY = headHeight + 0.5
			local markHeight = headHeight * 2 + 1
			local gap = math.max(1, fontSize * 0.06)
			shifted(body.items, 0, markHeight + gap, items)
			local shaftWidth = body.width - headLength * 0.82
			if shaftWidth > 0 then
				table.insert(items, { kind = "Rule", x = 0, y = arrowY, width = shaftWidth, height = 1 })
			end
			local headCenterX = body.width - headLength * 0.41
			table.insert(items, {
				kind = "Rule",
				x = headCenterX - headLength / 2,
				y = arrowY - headHeight / 2 - 0.5,
				width = headLength,
				height = 1,
				rotation = -35,
			})
			table.insert(items, {
				kind = "Rule",
				x = headCenterX - headLength / 2,
				y = arrowY + headHeight / 2 - 0.5,
				width = headLength,
				height = 1,
				rotation = 35,
			})
			return {
				width = body.width,
				height = markHeight + gap + body.height,
				baseline = markHeight + gap + body.baseline,
				items = items,
			}
		end

		local mark = textResult(if node.style == "hat" then "ˆ" else "¯", fontSize * 0.7, measureText)
		local bodyY = mark.height * 0.65 + math.max(1, fontSize * 0.04)
		local width = math.max(body.width, mark.width)
		shifted(mark.items, (width - mark.width) / 2, 0, items)
		shifted(body.items, (width - body.width) / 2, bodyY, items)
		return { width = width, height = bodyY + body.height, baseline = bodyY + body.baseline, items = items }
	elseif node.kind == "Styled" then
		local body = layoutSequence(node.body.children, fontSize, measureText)
		for _, item in body.items do
			if item.kind == "Text" then
				item.bold = item.bold or node.style == "bold"
				item.roman = item.roman or node.style == "roman"
			end
		end
		return body
	elseif node.kind == "Scripts" then
		local operatorStyle = if node.base.kind == "Glyph" then node.base.operatorStyle else nil
		local base = layoutNode(node.base, fontSize, measureText)
		local scriptFontSize = fontSize * 0.7
		local superscript = if node.superscript ~= nil then layoutNode(node.superscript, scriptFontSize, measureText) else nil
		local subscript = if node.subscript ~= nil then layoutNode(node.subscript, scriptFontSize, measureText) else nil
		if operatorStyle ~= nil and operatorStyle ~= "integral" then
			local gap = fontSize * 0.06
			local topHeight = if superscript ~= nil then superscript.height else 0
			local baseY = topHeight + (if superscript ~= nil then gap else 0)
			local subscriptY = baseY + base.height + (if subscript ~= nil then gap else 0)
			local width = math.max(
				base.width,
				if superscript ~= nil then superscript.width else 0,
				if subscript ~= nil then subscript.width else 0
			)
			local items: { DrawItem } = {}
			shifted(base.items, (width - base.width) / 2, baseY, items)
			if superscript ~= nil then
				shifted(superscript.items, (width - superscript.width) / 2, 0, items)
			end
			if subscript ~= nil then
				shifted(subscript.items, (width - subscript.width) / 2, subscriptY, items)
			end
			return {
				width = width,
				height = baseY + base.height + (if subscript ~= nil then gap + subscript.height else 0),
				baseline = baseY + base.baseline,
				items = items,
			}
		end
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
	elseif node.kind == "Matrix" then
		return layoutGrid(node.rows, fontSize, measureText, 0.8, 0.35, false)
	elseif node.kind == "Aligned" then
		return layoutGrid(node.rows, fontSize, measureText, 0.2, 0.35, true)
	elseif node.kind == "Delimited" then
		local body = layoutSequence(node.body.children, fontSize, measureText)
		local delimiterSize = math.max(fontSize, body.height * 1.12)
		local left = if node.left ~= "" then textResult(node.left, delimiterSize, measureText) else nil
		local right = if node.right ~= "" then textResult(node.right, delimiterSize, measureText) else nil
		local gap = fontSize * 0.08
		local leftWidth = if left ~= nil then left.width + gap else 0
		local rightWidth = if right ~= nil then right.width + gap else 0
		local height = math.max(body.height, if left ~= nil then left.height else 0, if right ~= nil then right.height else 0)
		local bodyY = (height - body.height) / 2
		local items: { DrawItem } = {}
		if left ~= nil then
			shifted(left.items, 0, (height - left.height) / 2, items)
		end
		shifted(body.items, leftWidth, bodyY, items)
		if right ~= nil then
			shifted(right.items, leftWidth + body.width + gap, (height - right.height) / 2, items)
		end
		return {
			width = leftWidth + body.width + rightWidth,
			height = height,
			baseline = bodyY + body.baseline,
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
