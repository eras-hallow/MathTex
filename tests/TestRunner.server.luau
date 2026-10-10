--!strict

local specs = {
	require(script.Parent["AST.spec"]),
	require(script.Parent["Lexer.spec"]),
	require(script.Parent["Parser.spec"]),
	require(script.Parent["Layout.spec"]),
	require(script.Parent["Api.spec"]),
}

for index, runSpec in specs do
	local ok, problem = pcall(runSpec)
	if not ok then
		error(string.format("MathTex spec %d failed: %s", index, tostring(problem)), 0)
	end
	print(string.format("MathTex spec %d passed", index))
end

print("All MathTex specs passed")
