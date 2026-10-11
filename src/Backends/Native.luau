--!strict

local Layout = require(script.Parent.Parent.Layout)

local Native = {}

export type Options = {
	Color: Color3,
	Font: Enum.Font,
	FontSize: number,
	FitToContainer: boolean,
}

local function pixel(value: number): number
	return math.max(0, math.ceil(value))
end

local function escapeRichText(text: string): string
	return string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")
end

local function enableContainerFit(container: Frame, layout: Layout.Result, parent: Instance)
	local scale = Instance.new("UIScale")
	scale.Name = "FitToContainerScale"
	scale.Parent = container

	local connections: { RBXScriptConnection } = {}
	local cameraConnection: RBXScriptConnection? = nil
	local function updateScale(availableSize: Vector2)
		scale.Scale = Layout.fitScale(layout, availableSize)
	end
	local function disconnect()
		for _, connection in connections do
			connection:Disconnect()
		end
		if cameraConnection ~= nil then
			cameraConnection:Disconnect()
			cameraConnection = nil
		end
	end

	if parent:IsA("GuiObject") then
		local function update()
			updateScale(parent.AbsoluteSize)
		end
		table.insert(connections, parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
		update()
	elseif parent:IsA("ScreenGui") then
		local workspace = game:GetService("Workspace")
		local function updateCamera()
			if cameraConnection ~= nil then
				cameraConnection:Disconnect()
				cameraConnection = nil
			end
			local camera = workspace.CurrentCamera
			if camera ~= nil then
				cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					updateScale(camera.ViewportSize)
				end)
				updateScale(camera.ViewportSize)
			end
		end
		table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateCamera))
		updateCamera()
	end

	container.Destroying:Once(disconnect)
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
	local fitToContainer = options.FitToContainer and (parent:IsA("GuiObject") or parent:IsA("ScreenGui"))
	if fitToContainer then
		container.AnchorPoint = Vector2.new(0.5, 0.5)
		container.Position = UDim2.fromScale(0.5, 0.5)
	end

	for _, item in layout.items do
		if item.kind == "Text" then
			local label = Instance.new("TextLabel")
			label.Name = "Glyph"
			label.BackgroundTransparency = 1
			label.BorderSizePixel = 0
			local textSize = math.max(1, math.floor((item.fontSize or options.FontSize) + 0.5))
			local richText = string.format('<font size="%d">%s</font>', textSize, escapeRichText(item.text or ""))
			if item.bold then
				richText = "<b>" .. richText .. "</b>"
			end
			if item.roman then
				richText = '<font face="SourceSansPro">' .. richText .. "</font>"
			end
			label.RichText = true
			label.Text = richText
			label.TextColor3 = options.Color
			label.Font = options.Font
			label.TextSize = options.FontSize
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
			rule.Rotation = item.rotation or 0
			rule.Parent = container
		end
	end

	container.Parent = parent
	if fitToContainer then
		enableContainerFit(container, layout, parent)
	end
	return container
end

return Native
