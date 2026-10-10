--!strict

local AST = require(script.AST)
local Layout = require(script.Layout)
local Native = require(script.Backends.Native)
local Parser = require(script.Parser)
local TextService = game:GetService("TextService")

local MathTex = {}

export type Options = {
	FontSize: number?,
	Color: Color3?,
	Font: Enum.Font?,
	Backend: "Auto" | "Native" | "Image"?,
	FitToContainer: boolean?,
}

type ResolvedOptions = {
	FontSize: number,
	Color: Color3,
	Font: Enum.Font,
	Backend: "Auto" | "Native" | "Image",
	FitToContainer: boolean,
}

export type Expression = {
	Source: string,
	Options: ResolvedOptions,
	_ast: AST.Sequence,
	_rendered: Frame?,
	_destroyed: boolean,
	Render: (self: Expression, parent: Instance) -> Frame,
	Measure: (self: Expression) -> Vector2,
	Destroy: (self: Expression) -> (),
}

local Expression = {}
Expression.__index = Expression

local MAX_SOURCE_LENGTH = 4096
local MAX_RENDER_ITEMS = 1024
local DEFAULT_OPTIONS: ResolvedOptions = {
	FontSize = 32,
	Color = Color3.new(1, 1, 1),
	Font = Enum.Font.SourceSans,
	Backend = "Auto",
	FitToContainer = true,
}

local function validateOptions(options: Options?): ResolvedOptions
	local resolved = table.clone(DEFAULT_OPTIONS)
	if options == nil then
		return resolved
	end
	if type(options) ~= "table" then
		error("MathTex: options must be a table", 0)
	end
	for key in options do
		if key ~= "FontSize" and key ~= "Color" and key ~= "Font" and key ~= "Backend" and key ~= "FitToContainer" then
			error("MathTex: unknown option '" .. tostring(key) .. "'", 0)
		end
	end
	if options.FontSize ~= nil then
		if type(options.FontSize) ~= "number" or options.FontSize % 1 ~= 0 or options.FontSize < 1 or options.FontSize > 256 then
			error("MathTex: FontSize must be an integer from 1 to 256", 0)
		end
		resolved.FontSize = options.FontSize
	end
	if options.Color ~= nil then
		if typeof(options.Color) ~= "Color3" then
			error("MathTex: Color must be a Color3", 0)
		end
		resolved.Color = options.Color
	end
	if options.Font ~= nil then
		if typeof(options.Font) ~= "EnumItem" or options.Font.EnumType ~= Enum.Font then
			error("MathTex: Font must be an Enum.Font value", 0)
		end
		resolved.Font = options.Font
	end
	if options.Backend ~= nil then
		if options.Backend ~= "Auto" and options.Backend ~= "Native" and options.Backend ~= "Image" then
			error("MathTex: Backend must be 'Auto', 'Native', or 'Image'", 0)
		end
		resolved.Backend = options.Backend
	end
	if options.FitToContainer ~= nil then
		if type(options.FitToContainer) ~= "boolean" then
			error("MathTex: FitToContainer must be a boolean", 0)
		end
		resolved.FitToContainer = options.FitToContainer
	end
	if resolved.Backend == "Image" then
		error("MathTex: the Image backend is not configured; use 'Auto' or 'Native'", 0)
	end
	return resolved
end

local function measure(ast: AST.Sequence, options: ResolvedOptions): Layout.Result
	return Layout.calculate(ast, options.FontSize, function(text: string, fontSize: number): Vector2
		return TextService:GetTextSize(text, math.max(1, math.floor(fontSize + 0.5)), options.Font, Vector2.new(100000, 100000))
	end)
end

function MathTex.new(source: string, options: Options?): Expression
	if type(source) ~= "string" then
		error("MathTex: source must be a string", 0)
	end
	if #source > MAX_SOURCE_LENGTH then
		error(string.format("MathTex: source exceeds the %d byte limit", MAX_SOURCE_LENGTH), 0)
	end
	if string.match(source, "^%s*$") ~= nil then
		error("MathTex: source cannot be empty", 0)
	end

	local resolvedOptions = validateOptions(options)
	local ast = Parser.parse(source)
	return setmetatable({
		Source = source,
		Options = resolvedOptions,
		_ast = ast,
		_rendered = nil,
		_destroyed = false,
	}, Expression) :: any
end

function Expression:Measure(): Vector2
	if self._destroyed then
		error("MathTex: cannot measure a destroyed expression", 0)
	end
	local layout = measure(self._ast, self.Options)
	return Vector2.new(math.ceil(layout.width), math.ceil(layout.height))
end

function Expression:Render(parent: Instance): Frame
	if self._destroyed then
		error("MathTex: cannot render a destroyed expression", 0)
	end
	if typeof(parent) ~= "Instance" or not (parent:IsA("GuiObject") or parent:IsA("LayerCollector")) then
		error("MathTex: parent must be a GuiObject or LayerCollector", 0)
	end

	local layout = measure(self._ast, self.Options)
	if #layout.items > MAX_RENDER_ITEMS then
		error(string.format("MathTex: expression needs %d render items; the limit is %d", #layout.items, MAX_RENDER_ITEMS), 0)
	end
	local available, reason = Native.canRender(layout)
	if self.Options.Backend == "Native" and not available then
		error("MathTex: native backend cannot render this expression: " .. (reason or "unsupported expression"), 0)
	elseif self.Options.Backend == "Auto" and not available then
		error("MathTex: no configured backend can render this expression: " .. (reason or "unsupported expression"), 0)
	end

	local rendered = Native.render(layout, parent, self.Options)
	if self._rendered ~= nil then
		self._rendered:Destroy()
	end
	self._rendered = rendered
	return rendered
end

function Expression:Destroy()
	if self._rendered ~= nil then
		self._rendered:Destroy()
		self._rendered = nil
	end
	self._destroyed = true
end

return MathTex
