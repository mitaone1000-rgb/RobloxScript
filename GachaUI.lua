-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Memuat modul dan event
local AudioManager = require(ReplicatedStorage.ModuleScript:WaitForChild("AudioManager"))
local GachaConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("GachaConfig"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local GachaRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaRollEvent")

-- ================== UI CREATION ==================
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "GachaSkinGUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 350)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true

local mainFrameCorner = Instance.new("UICorner", mainFrame)
mainFrameCorner.CornerRadius = UDim.new(0, 12)

local mainFrameGradient = Instance.new("UIGradient", mainFrame)
mainFrameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 58, 64)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 37, 40))
})
mainFrameGradient.Rotation = 90

local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.Text = "SKIN GACHA"
titleLabel.Font = Enum.Font.Sarpanch
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 38
titleLabel.TextStrokeTransparency = 0.5
titleLabel.BackgroundTransparency = 1

-- Label untuk menampilkan peluang
local legendaryChanceLabel = Instance.new("TextLabel", mainFrame)
legendaryChanceLabel.Name = "LegendaryChanceLabel"
legendaryChanceLabel.Size = UDim2.new(1, 0, 0, 30)
legendaryChanceLabel.Position = UDim2.new(0, 0, 0, 50)
legendaryChanceLabel.Text = "Peluang Legendaris: " .. GachaConfig.RARITY_CHANCES.Legendary .. "%"
legendaryChanceLabel.Font = Enum.Font.SourceSans
legendaryChanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
legendaryChanceLabel.TextSize = 18
legendaryChanceLabel.BackgroundTransparency = 1

local commonChanceLabel = Instance.new("TextLabel", mainFrame)
commonChanceLabel.Name = "CommonChanceLabel"
commonChanceLabel.Size = UDim2.new(1, 0, 0, 30)
commonChanceLabel.Position = UDim2.new(0, 0, 0, 70)
commonChanceLabel.Text = "Peluang Biasa: " .. GachaConfig.RARITY_CHANCES.Common .. "%"
commonChanceLabel.Font = Enum.Font.SourceSans
commonChanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
commonChanceLabel.TextSize = 18
commonChanceLabel.BackgroundTransparency = 1

local rollButton = Instance.new("TextButton", mainFrame)
rollButton.Name = "RollButton"
rollButton.Size = UDim2.new(0, 250, 0, 60)
rollButton.Position = UDim2.new(0.5, -125, 0.75, 0)
rollButton.Text = "Roll (100 BloodCoins)"
rollButton.Font = Enum.Font.SourceSansBold
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.TextSize = 24
rollButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
rollButton.BorderSizePixel = 0

local rollButtonCorner = Instance.new("UICorner", rollButton)
rollButtonCorner.CornerRadius = UDim.new(0, 8)

local rollButtonGradient = Instance.new("UIGradient", rollButton)
rollButtonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(108, 121, 252)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 101, 242))
})

local closeButton = Instance.new("TextButton", mainFrame)
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -45, 0, 10)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 22
closeButton.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
closeButton.BackgroundTransparency = 0.2
closeButton.BorderSizePixel = 0

local closeButtonCorner = Instance.new("UICorner", closeButton)
closeButtonCorner.CornerRadius = UDim.new(1, 0)

local animationFrame = Instance.new("Frame", mainFrame)
animationFrame.Name = "AnimationFrame"
animationFrame.Size = UDim2.new(1, 0, 0.4, 0)
animationFrame.Position = UDim2.new(0, 0, 0.2, 0)
animationFrame.BackgroundTransparency = 1
animationFrame.Visible = false

local reelText = Instance.new("TextLabel", animationFrame)
reelText.Name = "ReelText"
reelText.Size = UDim2.new(1, 0, 1, 0)
reelText.Font = Enum.Font.SourceSans
reelText.TextSize = 32
reelText.TextColor3 = Color3.fromRGB(255, 255, 255)
reelText.TextWrapped = true
reelText.BackgroundTransparency = 1

local resultFrame = Instance.new("Frame", mainFrame)
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(1, 0, 1, 0)
resultFrame.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
resultFrame.BackgroundTransparency = 0.1
resultFrame.Visible = false

local resultText = Instance.new("TextLabel", resultFrame)
resultText.Name = "ResultText"
resultText.Size = UDim2.new(0.9, 0, 0.5, 0)
resultText.Position = UDim2.new(0.05, 0, 0.1, 0)
resultText.Font = Enum.Font.SourceSansBold
resultText.TextSize = 30
resultText.TextWrapped = true
resultText.TextXAlignment = Enum.TextXAlignment.Center
resultText.TextYAlignment = Enum.TextYAlignment.Center
resultText.BackgroundTransparency = 1

local resultShine = Instance.new("Frame", resultText)
resultShine.Name = "Shine"
resultShine.Size = UDim2.new(0.2, 0, 2, 0)
resultShine.Position = UDim2.new(-0.2, 0, -0.5, 0)
resultShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
resultShine.BorderSizePixel = 0
resultShine.Rotation = -20
resultShine.Visible = false
local shineGradient = Instance.new("UIGradient", resultShine)
shineGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1)
})

local resultCloseButton = Instance.new("TextButton", resultFrame)
resultCloseButton.Name = "ResultCloseButton"
resultCloseButton.Size = UDim2.new(0, 180, 0, 50)
resultCloseButton.Position = UDim2.new(0.5, -90, 0.7, 0)
resultCloseButton.Text = "OK"
resultCloseButton.Font = Enum.Font.SourceSansBold
resultCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resultCloseButton.TextSize = 24
resultCloseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
resultCloseButton.BorderSizePixel = 0

local resultCloseCorner = Instance.new("UICorner", resultCloseButton)
resultCloseCorner.CornerRadius = UDim.new(0, 8)

-- ================== SCRIPT LOGIC (REFACTORED WITH TIMEOUT) ==================

local isRolling = false
local potentialPrizes = {}
local latestResult = nil

GachaRollEvent.OnClientEvent:Connect(function(result)
	latestResult = result
end)

local function playSound(soundName, properties)
	local sound = AudioManager.createSound(soundName, screenGui, properties)
	if sound then
		sound:Play()
		game.Debris:AddItem(sound, sound.TimeLength)
	end
end

local function populatePrizes()
	table.clear(potentialPrizes)
	for _, weaponData in pairs(WeaponModule.Weapons) do
		for skinName, _ in pairs(weaponData.Skins) do
			if skinName ~= "Default Skin" then
				table.insert(potentialPrizes, {Name = skinName, Rarity = "Legendary"})
			end
		end
	end
	for i = 1, 10 do
		table.insert(potentialPrizes, {Name = tostring(math.random(10, 50)) .. " BloodCoins", Rarity = "Common"})
	end
end

local function playReelAnimation()
	animationFrame.Visible = true
	local sound = AudioManager.createSound("Elements.Wind", screenGui, { Looped = true, Volume = 0.3 })
	if sound then sound:Play() end

	local animationTime = 3
	local startTime = tick()

	while tick() - startTime < animationTime do
		local randomPrize = potentialPrizes[math.random(#potentialPrizes)]
		reelText.Text = randomPrize.Name
		if randomPrize.Rarity == "Legendary" then
			reelText.TextColor3 = Color3.fromRGB(255, 215, 0)
		else
			reelText.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
		task.wait(0.05)
	end

	if sound then sound:Stop(); sound:Destroy() end
	animationFrame.Visible = false
end

local function playShineAnimation()
    resultShine.Visible = true
    local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(resultShine, tweenInfo, { Position = UDim2.new(1, 0, -0.5, 0) })
    tween:Play()
    tween.Completed:Wait()
    resultShine.Visible = false
    resultShine.Position = UDim2.new(-0.2, 0, -0.5, 0)
end

local function showResult(resultData)
	if resultData.Success then
		local prize = resultData.Prize
		if prize.Type == "Skin" then
			resultText.Text = string.format("Selamat!\nAnda mendapatkan Skin:\n%s (%s)", prize.SkinName, prize.WeaponName)
			resultText.TextColor3 = Color3.fromRGB(255, 215, 0)
			playSound("Boss.Complete", { Volume = 0.8 })
            task.spawn(playShineAnimation)
		elseif prize.Type == "Coins" then
			resultText.Text = string.format("Anda mendapatkan:\n%d BloodCoins", prize.Amount)
			resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
			playSound("Weapons.Empty", { Volume = 0.7 })
		end
	else
		resultText.Text = "Gagal!\n" .. (resultData.Message or "Terjadi kesalahan.")
		resultText.TextColor3 = Color3.fromRGB(237, 66, 69)
		playSound("Weapons.Empty", { Volume = 0.5 })
	end
	resultFrame.Visible = true
end

local function toggleGachaUI(visible)
	if isRolling then return end
	if visible then
		populatePrizes()
		mainFrame.Visible = true
		resultFrame.Visible = false
		rollButton.Visible = true
	else
		mainFrame.Visible = false
	end
end

local gachaShopPart = Workspace:WaitForChild("GachaShopSkin")
if gachaShopPart then
	local proximityPrompt = gachaShopPart:WaitForChild("ProximityPrompt")
	proximityPrompt.Triggered:Connect(function()
		toggleGachaUI(true)
	end)
end

closeButton.MouseButton1Click:Connect(function()
	if not isRolling then
		playSound("Weapons.Pistol.Reload", { Volume = 0.5 })
		toggleGachaUI(false)
	end
end)

rollButton.MouseButton1Click:Connect(function()
	if isRolling then return end

	isRolling = true
	rollButton.Visible = false
	latestResult = nil

	playSound("Weapons.Pistol.Reload", { Volume = 0.5 })

	task.spawn(playReelAnimation)
	GachaRollEvent:FireServer()

	task.wait(3) -- Tunggu animasi selesai

	local startTime = tick()
	local timeout = 10 -- detik
    while not latestResult do
		if tick() - startTime > timeout then
			latestResult = { Success = false, Message = "Server tidak merespons. Coba lagi." }
			break
		end
        task.wait(0.1)
    end

    showResult(latestResult)
    isRolling = false
end)

resultCloseButton.MouseButton1Click:Connect(function()
	playSound("Weapons.Pistol.Reload", { Volume = 0.5 })
	resultFrame.Visible = false
	rollButton.Visible = true
end)

print("GachaUI.lua loaded for player with timeout fix.")