--!strict

local Lexer = require(game:GetService("ReplicatedStorage").MathTex.Lexer)

return function()
	local tokens = Lexer.tokenize([[x_12+\alpha^{β}]])
	assert(tokens[1].kind == "Character" and tokens[1].value == "x")
	assert(tokens[2].kind == "Subscript")
	assert(tokens[3].kind == "Number" and tokens[3].value == "12")
	assert(tokens[4].kind == "Operator" and tokens[4].value == "+")
	assert(tokens[5].kind == "Command" and tokens[5].value == "alpha")
	assert(tokens[8].kind == "Character" and tokens[8].value == "β")
	assert(tokens[#tokens].kind == "EOF")

	local valid, problem = pcall(function()
		Lexer.tokenize("\\")
	end)
	assert(not valid and string.find(tostring(problem), "trailing backslash", 1, true) ~= nil)
end
