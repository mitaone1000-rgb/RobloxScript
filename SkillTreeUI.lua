-- SkillTreeUI.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/SkillTreeUI.lua
-- NOTE: This script should be placed in StarterPlayerScripts

-- Ensure this script only runs in the Lobby
local LOBBY_PLACE_ID = 101319079083908 -- Same as ProfileUI
if game.PlaceId ~= LOBBY_PLACE_ID then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpgradeSkillEvent = RemoteEvents:WaitForChild("UpgradeSkillEvent")
local SkillDataUpdateEvent = RemoteEvents:WaitForChild("SkillDataUpdateEvent")

-- Konfigurasi Skill (sama seperti di server)
local SKILL_CONFIG = {
    DamageHeadshot = {
        DisplayName = "Damage Headshot",
        MaxLevel = 5
    }
}

-- Buat UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkillTreeGui"
screenGui.Enabled = false -- Sembunyikan secara default
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Text = "Skill Tree"
titleLabel.TextSize = 24
titleLabel.Parent = mainFrame

local skillPointsLabel = Instance.new("TextLabel")
skillPointsLabel.Name = "SkillPointsLabel"
skillPointsLabel.Size = UDim2.new(1, -20, 0, 30)
skillPointsLabel.Position = UDim2.new(0, 10, 0, 50)
skillPointsLabel.BackgroundColor3 = Color3.new(0,0,0,0)
skillPointsLabel.TextColor3 = Color3.new(1, 1, 1)
skillPointsLabel.Font = Enum.Font.SourceSans
skillPointsLabel.Text = "Skill Points: 0"
skillPointsLabel.TextSize = 18
skillPointsLabel.TextXAlignment = Enum.TextXAlignment.Left
skillPointsLabel.Parent = mainFrame

local skillContainer = Instance.new("ScrollingFrame")
skillContainer.Name = "SkillContainer"
skillContainer.Size = UDim2.new(1, -20, 0, 200)
skillContainer.Position = UDim2.new(0, 10, 0, 90)
skillContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
skillContainer.BorderSizePixel = 0
skillContainer.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = skillContainer
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 5)

-- Fungsi untuk membuat tampilan skill
local function createSkillDisplay(skillName, config)
    local skillFrame = Instance.new("Frame")
    skillFrame.Name = skillName
    skillFrame.Size = UDim2.new(1, 0, 0, 50)
    skillFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    skillFrame.Parent = skillContainer

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.BackgroundColor3 = Color3.new(0,0,0,0)
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = config.DisplayName
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.Parent = skillFrame

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0.2, 0, 1, 0)
    levelLabel.BackgroundColor3 = Color3.new(0,0,0,0)
    levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    levelLabel.Font = Enum.Font.SourceSans
    levelLabel.Text = "0/" .. config.MaxLevel
    levelLabel.TextSize = 14
    levelLabel.Position = UDim2.new(0.5, 0, 0, 0)
    levelLabel.Parent = skillFrame

    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Name = "UpgradeButton"
    upgradeButton.Size = UDim2.new(0.25, 0, 0.8, 0)
    upgradeButton.Position = UDim2.new(0.72, 0, 0.1, 0)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(0, 128, 0)
    upgradeButton.TextColor3 = Color3.new(1, 1, 1)
    upgradeButton.Font = Enum.Font.SourceSansBold
    upgradeButton.Text = "Upgrade"
    upgradeButton.TextSize = 16
    upgradeButton.Parent = skillFrame

    upgradeButton.MouseButton1Click:Connect(function()
        UpgradeSkillEvent:FireServer(skillName)
    end)

    return skillFrame
end

-- Buat semua skill display
local skillDisplays = {}
for skillName, config in pairs(SKILL_CONFIG) do
    skillDisplays[skillName] = createSkillDisplay(skillName, config)
end

-- Fungsi untuk mengupdate UI dengan data baru dari server
local function updateUI(data)
    if not data then return end

    skillPointsLabel.Text = "Skill Points: " .. (data.SkillPoints or 0)

    for skillName, displayFrame in pairs(skillDisplays) do
        local level = data.Skills and data.Skills[skillName] or 0
        local config = SKILL_CONFIG[skillName]

        displayFrame.LevelLabel.Text = level .. "/" .. config.MaxLevel

        local upgradeButton = displayFrame.UpgradeButton
        if level >= config.MaxLevel then
            upgradeButton.Text = "Max"
            upgradeButton.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
            upgradeButton.Active = false
        elseif (data.SkillPoints or 0) > 0 then
            upgradeButton.Text = "Upgrade"
            upgradeButton.BackgroundColor3 = Color3.fromRGB(0, 128, 0)
            upgradeButton.Active = true
        else
            upgradeButton.Text = "Upgrade"
            upgradeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            upgradeButton.Active = false
        end
    end
end

-- Listener untuk update data dari server
SkillDataUpdateEvent.OnClientEvent:Connect(updateUI)

-- Fungsi untuk menampilkan/menyembunyikan UI
function ToggleSkillTreeUI(visible)
    screenGui.Enabled = visible
end

-- Expose function to be callable from other local scripts
_G.ToggleSkillTreeUI = ToggleSkillTreeUI