-- ProfileUI.lua (LocalScript)
-- Path: StarterGui/ProfileUI.lua
-- Script Place: Lobby

-- Ensure this script only runs in the Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create a single ScreenGui for all profile elements
local profileScreenGui = Instance.new("ScreenGui")
profileScreenGui.Name = "ProfileUI"
profileScreenGui.Parent = playerGui
profileScreenGui.Enabled = true -- Enabled by default to show the button

--[[ Profile Button (always visible) ]]--
local profileButton = Instance.new("TextButton")
profileButton.Name = "ProfileButton"
profileButton.Parent = profileScreenGui -- Add to the same ScreenGui
profileButton.Size = UDim2.new(0, 120, 0, 50)
profileButton.Position = UDim2.new(1, -130, 0, 10) -- Top-right corner
profileButton.Text = "Profile"
profileButton.Font = Enum.Font.SourceSansBold
profileButton.TextSize = 20
profileButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
profileButton.TextColor3 = Color3.fromRGB(255, 255, 255)

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = profileButton

--[[ Main Profile Panel (initially hidden) ]]--
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = profileScreenGui
mainFrame.Size = UDim2.new(0, 400, 0, 420) -- Increased height
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -210) -- Adjusted position
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 2
mainFrame.Visible = false -- Initially hidden

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = mainFrame
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Text = "Player Profile"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

-- Helper function to create a stat label
local function createStatLabel(name, positionY)
    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Parent = mainFrame
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.new(0, 10, 0, positionY)
    label.Text = name .. ": "
    label.Font = Enum.Font.SourceSans
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

-- Create all labels
local nameLabel = createStatLabel("Name", 60)
local levelLabel = createStatLabel("Level", 100)
local xpLabel = createStatLabel("XP", 140)
local totalCoinsLabel = createStatLabel("Total Coins", 180)
local totalKillsLabel = createStatLabel("Total Kills", 220)
local totalRevivesLabel = createStatLabel("Total Revives", 260)
local totalKnocksLabel = createStatLabel("Total Knocks", 300)

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Parent = mainFrame
closeButton.Size = UDim2.new(0, 100, 0, 40)
closeButton.Position = UDim2.new(0.5, -50, 1, -50)
closeButton.Text = "Close"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 20
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)

--[[ Logic ]]--
local profileRemoteFunction = ReplicatedStorage:WaitForChild("GetProfileData")

local function updateProfileData()
	local success, profileData = pcall(function()
		return profileRemoteFunction:InvokeServer()
	end)

	if success and profileData then
		nameLabel.Text = "Name: " .. (profileData.Name or "N/A")
		levelLabel.Text = "Level: " .. (profileData.Level or 0)
		xpLabel.Text = "XP: " .. (profileData.XP or 0)
		totalCoinsLabel.Text = "Total Coins: " .. (profileData.TotalCoins or 0)
		totalKillsLabel.Text = "Total Kills: " .. (profileData.TotalKills or 0)
		totalRevivesLabel.Text = "Total Revives: " .. (profileData.TotalRevives or 0)
		totalKnocksLabel.Text = "Total Knocks: " .. (profileData.TotalKnocks or 0)
	else
		warn("Failed to get profile data.")
	end
end

-- Update data when the panel becomes visible
mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if mainFrame.Visible then
		updateProfileData()
	end
end)

-- Button logic to show/hide the panel
profileButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
end)

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)