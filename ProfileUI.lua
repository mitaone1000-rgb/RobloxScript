-- ProfileUI.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/ProfileUI.lua
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
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
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

-- Name Label
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Parent = mainFrame
nameLabel.Size = UDim2.new(1, -20, 0, 30)
nameLabel.Position = UDim2.new(0, 10, 0, 60)
nameLabel.Text = "Name: "
nameLabel.Font = Enum.Font.SourceSans
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 18
nameLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Level Label
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Parent = mainFrame
levelLabel.Size = UDim2.new(1, -20, 0, 30)
levelLabel.Position = UDim2.new(0, 10, 0, 100)
levelLabel.Text = "Level: "
levelLabel.Font = Enum.Font.SourceSans
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.TextSize = 18
levelLabel.TextXAlignment = Enum.TextXAlignment.Left

-- XP Label
local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "XPLabel"
xpLabel.Parent = mainFrame
xpLabel.Size = UDim2.new(1, -20, 0, 30)
xpLabel.Position = UDim2.new(0, 10, 0, 140)
xpLabel.Text = "XP: "
xpLabel.Font = Enum.Font.SourceSans
xpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
xpLabel.TextSize = 18
xpLabel.TextXAlignment = Enum.TextXAlignment.Left

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
        nameLabel.Text = "Name: " .. profileData.Name
        levelLabel.Text = "Level: " .. profileData.Level
        xpLabel.Text = "XP: " .. profileData.XP
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