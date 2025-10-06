-- GameOverUI.lua (LocalScript)
-- Path: StarterGui/GameOverUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")
local ExitGameEvent = RemoteEvents:WaitForChild("ExitGameEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameOverUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = gui

-- Remove existing elements if they exist
if screenGui:FindFirstChild("GameOverLabel") then
	screenGui.GameOverLabel:Destroy()
end
if screenGui:FindFirstChild("ExitBtn") then
	screenGui.ExitBtn:Destroy()
end

-- Create a container frame for the game over UI
local gameOverContainer = Instance.new("Frame")
gameOverContainer.Name = "GameOverContainer"
gameOverContainer.Size = UDim2.new(1, 0, 1, 0)
gameOverContainer.Position = UDim2.new(0, 0, 0, 0)
gameOverContainer.BackgroundTransparency = 1
gameOverContainer.Visible = false
gameOverContainer.ZIndex = 10
gameOverContainer.Parent = screenGui

-- Animated background
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.Position = UDim2.new(0, 0, 0, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.7
background.ZIndex = 10
background.Parent = gameOverContainer

-- Particle effect for background
local particleConnection
background:GetPropertyChangedSignal("Visible"):Connect(function()
	if background.Visible then
		local time = 0
		particleConnection = RunService.Heartbeat:Connect(function(delta)
			time += delta
			background.BackgroundColor3 = Color3.fromRGB(
				math.sin(time * 0.5) * 10 + 10,
				0,
				0
			)
		end)
	else
		if particleConnection then
			particleConnection:Disconnect()
		end
	end
end)

-- Label "GAME OVER" with improved styling
local gameOverLabel = Instance.new("TextLabel")
gameOverLabel.Name = "GameOverLabel"
gameOverLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
gameOverLabel.Position = UDim2.new(0.1, 0, 0.2, 0)
gameOverLabel.AnchorPoint = Vector2.new(0, 0.5)
gameOverLabel.BackgroundTransparency = 1
gameOverLabel.TextScaled = true
gameOverLabel.Font = Enum.Font.GothamBlack
gameOverLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
gameOverLabel.Text = "GAME OVER"
gameOverLabel.TextStrokeTransparency = 0.8
gameOverLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
gameOverLabel.ZIndex = 11
gameOverLabel.Visible = false
gameOverLabel.Parent = gameOverContainer

-- Glow effect for the text
local glowEffect = Instance.new("UIGradient")
glowEffect.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))
})
glowEffect.Rotation = 90
glowEffect.Enabled = false
glowEffect.Parent = gameOverLabel

-- Subtitle text
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
subtitleLabel.Position = UDim2.new(0.2, 0, 0.35, 0)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.TextScaled = true
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
subtitleLabel.Text = "Better luck next time!"
subtitleLabel.ZIndex = 11
subtitleLabel.Visible = false
subtitleLabel.Parent = gameOverContainer

-- Exit button with improved styling
local exitBtn = Instance.new("TextButton")
exitBtn.Name = "ExitBtn"
exitBtn.Size = UDim2.new(0.3, 0, 0.12, 0)
exitBtn.Position = UDim2.new(0.35, 0, 0.65, 0)
exitBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
exitBtn.BorderSizePixel = 0
exitBtn.TextScaled = true
exitBtn.Font = Enum.Font.GothamBold
exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exitBtn.Text = "EXIT"
exitBtn.ZIndex = 11
exitBtn.Visible = false
exitBtn.Parent = gameOverContainer

-- Add rounded corners to the button
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.2, 0)
corner.Parent = exitBtn

-- Button hover effects
exitBtn.MouseEnter:Connect(function()
	TweenService:Create(exitBtn, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(200, 0, 0),
		Size = UDim2.new(0.32, 0, 0.13, 0)
	}):Play()
end)

exitBtn.MouseLeave:Connect(function()
	TweenService:Create(exitBtn, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		Size = UDim2.new(0.3, 0, 0.12, 0)
	}):Play()
end)

-- Animation function
local function animateGameOver()
	gameOverContainer.Visible = true

	-- Fade in background
	TweenService:Create(background, TweenInfo.new(1.5), {
		BackgroundTransparency = 0.4
	}):Play()

	-- Animate game over text with a bounce effect
	gameOverLabel.Visible = true
	gameOverLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
	gameOverLabel.TextTransparency = 1

	local textTween = TweenService:Create(gameOverLabel, TweenInfo.new(1.5, Enum.EasingStyle.Bounce), {
		Position = UDim2.new(0.1, 0, 0.2, 0),
		TextTransparency = 0
	})
	textTween:Play()

	-- Enable glow effect after animation
	textTween.Completed:Connect(function()
		glowEffect.Enabled = true

		-- Pulse animation for the text
		while gameOverLabel.Visible do
			TweenService:Create(gameOverLabel, TweenInfo.new(1.5), {
				TextStrokeTransparency = 0.5
			}):Play()
			wait(1.5)
			TweenService:Create(gameOverLabel, TweenInfo.new(1.5), {
				TextStrokeTransparency = 0.8
			}):Play()
			wait(1.5)
		end
	end)

	-- Animate subtitle with delay
	wait(0.5)
	subtitleLabel.Visible = true
	subtitleLabel.TextTransparency = 1
	TweenService:Create(subtitleLabel, TweenInfo.new(1), {
		TextTransparency = 0
	}):Play()

	-- Animate button with delay
	wait(0.5)
	exitBtn.Visible = true
	exitBtn.BackgroundTransparency = 1
	exitBtn.TextTransparency = 1
	TweenService:Create(exitBtn, TweenInfo.new(0.8), {
		BackgroundTransparency = 0,
		TextTransparency = 0
	}):Play()
end

-- Hide animation function
local function hideGameOver()
	TweenService:Create(background, TweenInfo.new(0.8), {
		BackgroundTransparency = 1
	}):Play()

	TweenService:Create(gameOverLabel, TweenInfo.new(0.5), {
		TextTransparency = 1
	}):Play()

	TweenService:Create(subtitleLabel, TweenInfo.new(0.5), {
		TextTransparency = 1
	}):Play()

	TweenService:Create(exitBtn, TweenInfo.new(0.5), {
		BackgroundTransparency = 1,
		TextTransparency = 1
	}):Play()

	wait(0.8)
	gameOverContainer.Visible = false
end

GameOverEvent.OnClientEvent:Connect(function()
	animateGameOver()
end)

exitBtn.MouseButton1Click:Connect(function()
	hideGameOver()
	ExitGameEvent:FireServer()

end)
