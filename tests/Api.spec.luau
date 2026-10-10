--!strict

local MathTex = require(game:GetService("ReplicatedStorage").MathTex)

return function()
	local expression = MathTex.new([[\frac{-b+\sqrt{b^2-4ac}}{2a}]], {
		FontSize = 32,
		Color = Color3.new(1, 1, 1),
		Backend = "Auto",
	})
	local measured = expression:Measure()
	assert(measured.X > 0 and measured.Y > 0)

	local parent = Instance.new("ScreenGui")
	parent.Name = "MathTexTestGui"
	parent.Parent = game:GetService("StarterGui")
	local firstRender = expression:Render(parent)
	assert(firstRender.Parent == parent and #firstRender:GetChildren() > 0)
	assert(firstRender:FindFirstChildOfClass("UIScale") ~= nil)

	local secondRender = expression:Render(parent)
	assert(firstRender.Parent == nil and secondRender.Parent == parent)
	expression:Destroy()
	assert(secondRender.Parent == nil)
	local quickExpression = MathTex.render(parent, "x_1")
	assert(quickExpression:Measure().X > 0)
	quickExpression:Destroy()
	parent:Destroy()

	local ok, problem = pcall(function()
		MathTex.new("\\alpha", { Backend = "Image" })
	end)
	assert(not ok and string.find(tostring(problem), "not configured", 1, true) ~= nil)

	ok, problem = pcall(function()
		MathTex.new("\\alpha", { FontSize = 0 })
	end)
	assert(not ok and string.find(tostring(problem), "FontSize", 1, true) ~= nil)

	ok, problem = pcall(function()
		MathTex.new("\\alpha", { FitToContainer = "yes" :: any })
	end)
	assert(not ok and string.find(tostring(problem), "FitToContainer", 1, true) ~= nil)
end
