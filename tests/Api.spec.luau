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

	local richTextExpression = MathTex.new([=[\text{<b>&}]]=])
	local richTextFrame = richTextExpression:Render(parent)
	local richTextLabel = richTextFrame:FindFirstChildWhichIsA("TextLabel")
	assert(richTextLabel ~= nil and richTextLabel.RichText)
	assert(richTextLabel.Text == '<font size="32">&lt;b&gt;&amp;</font>')
	richTextExpression:Destroy()

	local boldExpression = MathTex.new([=[\mathbf{A}]=])
	local boldFrame = boldExpression:Render(parent)
	local boldLabel = boldFrame:FindFirstChildWhichIsA("TextLabel")
	assert(boldLabel ~= nil and boldLabel.Text == '<b><font size="32">A</font></b>')
	boldExpression:Destroy()
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
