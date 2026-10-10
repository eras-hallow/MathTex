-- Copy this LocalScript into StarterPlayerScripts in a Rojo project.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MathTex = require(ReplicatedStorage.MathTex)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MathTexExample"
screenGui.ResetOnSpawn = false
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.Name = "Equation"
holder.BackgroundTransparency = 1
holder.Position = UDim2.fromOffset(24, 24)
holder.Size = UDim2.fromOffset(500, 120)
holder.Parent = screenGui

local equation = MathTex.render(holder, [[\left(\frac{\text{average speed}}{2a}\right)^2]], {
	FontSize = 32,
	Color = Color3.new(1, 1, 1),
})
