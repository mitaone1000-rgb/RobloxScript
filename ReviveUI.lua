-- ReviveUI.lua (LocalScript)
-- Path: StarterGui/ReviveUI.lua
-- Script Place: ACT 1: Village

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local ReviveEvent = RemoteEvents:WaitForChild("ReviveEvent")
local CancelReviveEvent = RemoteEvents:WaitForChild("CancelReviveEvent")
local ReviveProgressEvent = RemoteEvents:WaitForChild("ReviveProgressEvent")

-- Revive progress UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ReviveUI"
screenGui.Parent = playerGui

local progressFrame = Instance.new("Frame")
progressFrame.Size = UDim2.new(0.3, 0, 0.05, 0)
progressFrame.Position = UDim2.new(0.35, 0, 0.5, 0)
progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
-- Make the progress frame slightly translucent so it blends into the HUD better
progressFrame.BackgroundTransparency = 0.3
progressFrame.BorderSizePixel = 0
progressFrame.Visible = false
progressFrame.Parent = screenGui

-- Add rounded corners and an outline to the progress frame for a cleaner look
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = progressFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(255, 255, 255)
frameStroke.Parent = progressFrame

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressFrame

-- Apply rounded corners to the progress bar so it matches its container
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 10)
barCorner.Parent = progressBar

-- Apply a gradient to the progress bar to make it more visually appealing
local barGradient = Instance.new("UIGradient")
barGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),    -- Start with green
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))  -- Transition to yellow
})
barGradient.Rotation = 0
barGradient.Parent = progressBar

local progressText = Instance.new("TextLabel")
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "Reviving: 0%"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextScaled = true
progressText.Parent = progressFrame

-- Mobile revive button
local mobileReviveBtn = Instance.new("TextButton")
mobileReviveBtn.Size = UDim2.new(0, 100, 0, 100)
mobileReviveBtn.Position = UDim2.new(0.5, -50, 0.7, -50)
mobileReviveBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
mobileReviveBtn.BackgroundTransparency = 0.5
mobileReviveBtn.Text = "+"
mobileReviveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileReviveBtn.TextScaled = true
mobileReviveBtn.Visible = false
mobileReviveBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 50)
corner.Parent = mobileReviveBtn

-- Revive prompt
local revivePrompt = Instance.new("TextLabel")
revivePrompt.Size = UDim2.new(0, 200, 0, 50)
revivePrompt.Position = UDim2.new(0.5, -100, 0.6, 0)
revivePrompt.BackgroundTransparency = 1
revivePrompt.Text = "Press E to Revive"
revivePrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
revivePrompt.TextScaled = true
revivePrompt.Visible = false
revivePrompt.Parent = screenGui

local isReviving = false
local currentTarget = nil
local totalReviveTime = 6 -- Default time

ReviveProgressEvent.OnClientEvent:Connect(function(progress, cancelled, reviveTime)
	if cancelled then
		progressFrame.Visible = false
		isReviving = false
		currentTarget = nil
		return
	end

	if reviveTime then
		totalReviveTime = reviveTime
	end

	progressBar.Size = UDim2.new(progress, 0, 1, 0)
	progressText.Text = string.format("Reviving: %d%% (%.1fs)", math.floor(progress * 100), totalReviveTime * (1 - progress))
	progressFrame.Visible = true

	if progress >= 1 then
		progressFrame.Visible = false
		isReviving = false
		currentTarget = nil
	end
end)

local function startRevive(target)
	if player.Character and player.Character:FindFirstChild("Knocked") then
		return
	end

	if isReviving then return end
	isReviving = true
	currentTarget = target
	ReviveEvent:FireServer(target)
end

local function cancelRevive()
	if isReviving then
		CancelReviveEvent:FireServer()
		isReviving = false
		currentTarget = nil
		progressFrame.Visible = false
	end
end

-- NEW: Cancel revive when shooting
local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	if isReviving then
		cancelRevive()
	end
end)

-- Check for movement/actions that cancel revive
RunService.RenderStepped:Connect(function()
	if isReviving then
		if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or
			UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D) or
			UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.R) or
			UIS:IsKeyDown(Enum.KeyCode.Q) then
			cancelRevive()
		end
	end
end)

-- Find player to revive
RunService.RenderStepped:Connect(function()
	-- HARD STOP: jangan tampilkan prompt kalau kita sendiri sedang knock
	local char = player.Character
	if char and char:FindFirstChild("Knocked") then
		revivePrompt.Visible = false
		mobileReviveBtn.Visible = false
		isReviving = false
		currentTarget = nil
		return
	end

	local targetToRevive = nil
	local char = player.Character

	if not char or not char:FindFirstChild("HumanoidRootPart") then
		revivePrompt.Visible = false
		mobileReviveBtn.Visible = false
		return
	end


	for _, other in pairs(game.Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("Knocked") then
			local dist = (char.HumanoidRootPart.Position - other.Character.HumanoidRootPart.Position).Magnitude
			if dist < 8 then
				targetToRevive = other
				break
			end
		end
	end

	-- Show appropriate UI based on platform
	if UIS.TouchEnabled then
		mobileReviveBtn.Visible = targetToRevive ~= nil and not isReviving
		revivePrompt.Visible = false
	else
		revivePrompt.Visible = targetToRevive ~= nil and not isReviving
		mobileReviveBtn.Visible = false
	end

	-- PC controls
	if targetToRevive and UIS:IsKeyDown(Enum.KeyCode.E) and not isReviving then
		startRevive(targetToRevive)
	end
end)

-- Mobile controls
mobileReviveBtn.MouseButton1Down:Connect(function()
	local char = player.Character
	if not char then return end

	for _, other in pairs(game.Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("Knocked") then
			local dist = (char.HumanoidRootPart.Position - other.Character.HumanoidRootPart.Position).Magnitude
			if dist < 8 and not isReviving then
				startRevive(other)
				break
			end
		end
	end
end)

-- Cancel if button is released
mobileReviveBtn.MouseButton1Up:Connect(cancelRevive)

mobileReviveBtn.MouseLeave:Connect(cancelRevive)
