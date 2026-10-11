--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")

local SOURCE_URL = "https://raw.githubusercontent.com/eras-hallow/MathTex/main/src/"
local FILES = {
	"init.luau",
	"AST.luau",
	"Layout.luau",
	"Lexer.luau",
	"Parser.luau",
	"Symbols.luau",
	"Backends/Native.luau",
}

local toolbar = plugin:CreateToolbar("MathTex")
local installButton = toolbar:CreateButton("InstallMathTex", "Install or update MathTex in ReplicatedStorage", "")

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing ~= nil then
		if not existing:IsA("Folder") then
			error(string.format("MathTex installer: %s is not a Folder", name), 0)
		end
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function install()
	local staging = Instance.new("ModuleScript")
	staging.Name = "MathTex_Installing_" .. HttpService:GenerateGUID(false)
	staging.Parent = ReplicatedStorage

	local ok, problem = pcall(function()
		for _, path in FILES do
			local source = HttpService:GetAsync(SOURCE_URL .. path)
			local target: ModuleScript
			if path == "init.luau" then
				target = staging
			else
				local segments = string.split(path, "/")
				local parent: Instance = staging
				for index = 1, #segments - 1 do
					parent = getOrCreateFolder(parent, segments[index])
				end

				local fileName = segments[#segments]
				target = Instance.new("ModuleScript")
				target.Name = string.gsub(fileName, "%.luau$", "")
				target.Parent = parent
			end
			ScriptEditorService:UpdateSourceAsync(target, function()
				return source
			end)
		end

		local previous = ReplicatedStorage:FindFirstChild("MathTex")
		if previous ~= nil then
			previous.Name = "MathTex_Previous_" .. HttpService:GenerateGUID(false)
		end

		local renamed, renameProblem = pcall(function()
			staging.Name = "MathTex"
		end)
		if not renamed then
			if previous ~= nil then
				previous.Name = "MathTex"
			end
			error(renameProblem, 0)
		end
		if previous ~= nil then
			previous:Destroy()
		end
	end)

	if not ok then
		staging:Destroy()
		error("MathTex installer failed: " .. tostring(problem), 0)
	end

	print("MathTex installed or updated at ReplicatedStorage.MathTex")
end

installButton.Click:Connect(function()
	installButton.Enabled = false
	local ok, problem = pcall(install)
	if not ok then
		warn(problem)
	end
	installButton.Enabled = true
end)