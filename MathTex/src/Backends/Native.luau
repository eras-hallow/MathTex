--!strict

local Layout = require(script.Parent.Parent.Layout)

local Native = {}

export type Options = {
	Color: Color3,
	Font: Enum.Font,
	FontSize: number,
}

local function pixel(value: number): number
	return math.max(0, math.ceil(value))
end

function Native.canRender(_layout: Layout.Result): (boolean, string?)
	return true, nil
end

function Native.render(layout: Layout.Result, parent: Instance, options: Options): Frame
	local container = Instance.new("Frame")
	container.Name = "MathTex"
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ClipsDescendants = false
	container.Size = UDim2.fromOffset(pixel(layout.width), pixel(layout.height))

	for _, item in layout.items do
		if item.kind == "Text" then
			local label = Instance.new("TextLabel")
			label.Name = "Glyph"
			label.BackgroundTransparency = 1
			label.BorderSizePixel = 0
			label.RichText = false
			label.Text = item.text or ""
			label.TextColor3 = options.Color
			label.Font = options.Font
			label.TextSize = math.max(1, math.floor(item.fontSize or options.FontSize + 0.5))
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.TextWrapped = false
			label.Size = UDim2.fromOffset(pixel(item.width + 2), pixel(item.height))
			label.Position = UDim2.fromOffset(pixel(item.x), pixel(item.y))
			label.Parent = container
		else
			local rule = Instance.new("Frame")
			rule.Name = "Rule"
			rule.BackgroundColor3 = options.Color
			rule.BorderSizePixel = 0
			rule.Size = UDim2.fromOffset(math.max(1, pixel(item.width)), math.max(1, pixel(item.height)))
			rule.Position = UDim2.fromOffset(pixel(item.x), pixel(item.y))
			rule.Parent = container
		end
	end

	container.Parent = parent
	return container
end

return Native
