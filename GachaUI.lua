-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Memuat modul dan event
local AudioManager = require(ReplicatedStorage.ModuleScript:WaitForChild("AudioManager"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local GachaRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaRollEvent")
local GachaMultiRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaMultiRollEvent")
local GetGachaConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetGachaConfig")

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
legendaryChanceLabel.Text = "Memuat peluang..."
legendaryChanceLabel.Font = Enum.Font.SourceSans
legendaryChanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
legendaryChanceLabel.TextSize = 18
legendaryChanceLabel.BackgroundTransparency = 1

local commonChanceLabel = Instance.new("TextLabel", mainFrame)
commonChanceLabel.Name = "CommonChanceLabel"
commonChanceLabel.Size = UDim2.new(1, 0, 0, 30)
commonChanceLabel.Position = UDim2.new(0, 0, 0, 70)
commonChanceLabel.Text = ""
commonChanceLabel.Font = Enum.Font.SourceSans
commonChanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
commonChanceLabel.TextSize = 18
commonChanceLabel.BackgroundTransparency = 1

-- Mengatur ulang posisi tombol roll
local rollButton = Instance.new("TextButton", mainFrame)
rollButton.Name = "RollButton"
rollButton.Size = UDim2.new(0, 180, 0, 50)
rollButton.Position = UDim2.new(0.5, -200, 0.8, 0)
rollButton.Text = "Roll x1 (100)"
rollButton.Font = Enum.Font.SourceSansBold
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.TextSize = 20
rollButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
rollButton.BorderSizePixel = 0

local rollButtonCorner = Instance.new("UICorner", rollButton)
rollButtonCorner.CornerRadius = UDim.new(0, 8)

local rollButtonGradient = Instance.new("UIGradient", rollButton)
rollButtonGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(108, 121, 252)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 101, 242))
})

-- Tombol baru untuk multi-roll
local multiRollButton = Instance.new("TextButton", mainFrame)
multiRollButton.Name = "MultiRollButton"
multiRollButton.Size = UDim2.new(0, 180, 0, 50)
multiRollButton.Position = UDim2.new(0.5, 20, 0.8, 0)
multiRollButton.Text = "Roll 10+1 (1000)"
multiRollButton.Font = Enum.Font.SourceSansBold
multiRollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
multiRollButton.TextSize = 20
multiRollButton.BackgroundColor3 = Color3.fromRGB(255, 128, 0)
multiRollButton.BorderSizePixel = 0

local multiRollButtonCorner = Instance.new("UICorner", multiRollButton)
multiRollButtonCorner.CornerRadius = UDim.new(0, 8)

local multiRollButtonGradient = Instance.new("UIGradient", multiRollButton)
multiRollButtonGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 128, 0))
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

-- Frame untuk hasil multi-roll
local multiResultFrame = Instance.new("Frame", screenGui)
multiResultFrame.Name = "MultiResultFrame"
multiResultFrame.Size = UDim2.new(0, 600, 0, 400)
multiResultFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
multiResultFrame.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
multiResultFrame.BorderSizePixel = 0
multiResultFrame.Visible = false

local multiResultCorner = Instance.new("UICorner", multiResultFrame)
multiResultCorner.CornerRadius = UDim.new(0, 12)

local multiResultTitle = Instance.new("TextLabel", multiResultFrame)
multiResultTitle.Name = "Title"
multiResultTitle.Size = UDim2.new(1, 0, 0, 50)
multiResultTitle.Text = "HASIL ROLL 10+1"
multiResultTitle.Font = Enum.Font.Sarpanch
multiResultTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
multiResultTitle.TextSize = 32
multiResultTitle.BackgroundTransparency = 1

local prizeContainer = Instance.new("ScrollingFrame", multiResultFrame)
prizeContainer.Size = UDim2.new(1, -20, 1, -120)
prizeContainer.Position = UDim2.new(0, 10, 0, 60)
prizeContainer.BackgroundTransparency = 1
prizeContainer.BorderSizePixel = 0

local multiResultGrid = Instance.new("UIGridLayout", prizeContainer)
multiResultGrid.CellPadding = UDim2.new(0, 10, 0, 10)
multiResultGrid.CellSize = UDim2.new(0, 120, 0, 80)
multiResultGrid.StartCorner = Enum.StartCorner.TopLeft
multiResultGrid.SortOrder = Enum.SortOrder.LayoutOrder

local multiResultCloseButton = Instance.new("TextButton", multiResultFrame)
multiResultCloseButton.Name = "MultiResultCloseButton"
multiResultCloseButton.Size = UDim2.new(0, 180, 0, 50)
multiResultCloseButton.Position = UDim2.new(0.5, -90, 0.85, 0)
multiResultCloseButton.Text = "OK"
multiResultCloseButton.Font = Enum.Font.SourceSansBold
multiResultCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
multiResultCloseButton.TextSize = 24
multiResultCloseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
multiResultCloseButton.BorderSizePixel = 0

local multiResultCloseCorner = Instance.new("UICorner", multiResultCloseButton)
multiResultCloseCorner.CornerRadius = UDim.new(0, 8)

-- [NEW] Tombol untuk melihat hadiah
local viewPrizesButton = Instance.new("TextButton", mainFrame)
viewPrizesButton.Name = "ViewPrizesButton"
viewPrizesButton.Size = UDim2.new(0.8, 0, 0, 35)
viewPrizesButton.Position = UDim2.new(0.1, 0, 0.65, 0) -- Disesuaikan posisinya
viewPrizesButton.Text = "Lihat Hadiah Legendaris"
viewPrizesButton.Font = Enum.Font.SourceSans
viewPrizesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
viewPrizesButton.TextSize = 18
viewPrizesButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
viewPrizesButton.BorderSizePixel = 0
local vpButtonCorner = Instance.new("UICorner", viewPrizesButton)
vpButtonCorner.CornerRadius = UDim.new(0, 8)

-- [NEW] Frame untuk Pratinjau Hadiah
local prizePreviewFrame = Instance.new("Frame", screenGui)
prizePreviewFrame.Name = "PrizePreviewFrame"
prizePreviewFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
prizePreviewFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
prizePreviewFrame.AnchorPoint = Vector2.new(0.5, 0.5)
prizePreviewFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 30)
prizePreviewFrame.BorderSizePixel = 1
prizePreviewFrame.BorderColor3 = Color3.fromRGB(55, 58, 64)
prizePreviewFrame.Visible = false
local ppfCorner = Instance.new("UICorner", prizePreviewFrame)
ppfCorner.CornerRadius = UDim.new(0, 12)

local ppfTitle = Instance.new("TextLabel", prizePreviewFrame)
ppfTitle.Name = "Title"
ppfTitle.Size = UDim2.new(1, 0, 0, 50)
ppfTitle.Text = "DAFTAR HADIAH LEGENDARIS"
ppfTitle.Font = Enum.Font.Sarpanch
ppfTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
ppfTitle.TextSize = 32
ppfTitle.BackgroundTransparency = 1

local ppfBackButton = Instance.new("TextButton", prizePreviewFrame)
ppfBackButton.Name = "BackButton"
ppfBackButton.Size = UDim2.new(0, 100, 0, 40)
ppfBackButton.Position = UDim2.new(0.05, 0, 0.9, 0)
ppfBackButton.Text = "Kembali"
ppfBackButton.Font = Enum.Font.SourceSansBold
ppfBackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ppfBackButton.TextSize = 18
ppfBackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
local ppfBackCorner = Instance.new("UICorner", ppfBackButton)
ppfBackCorner.CornerRadius = UDim.new(0, 8)

local prizeListContainer = Instance.new("ScrollingFrame", prizePreviewFrame)
prizeListContainer.Name = "PrizeListContainer"
prizeListContainer.Size = UDim2.new(1, -20, 1, -120)
prizeListContainer.Position = UDim2.new(0, 10, 0, 60)
prizeListContainer.BackgroundTransparency = 1
prizeListContainer.BorderSizePixel = 0
prizeListContainer.CanvasSize = UDim2.new(0,0,0,0)
prizeListContainer.ScrollBarThickness = 6

local prizeListLayout = Instance.new("UIGridLayout", prizeListContainer)
prizeListLayout.CellPadding = UDim2.new(0, 15, 0, 15)
prizeListLayout.CellSize = UDim2.new(0, 200, 0, 220) -- Ukuran untuk ViewportFrame + label
prizeListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center


-- ================== SCRIPT LOGIC (REFACTORED WITH TIMEOUT) ==================

local isRolling = false
local potentialPrizes = {}
local latestResult = nil
local rarityChances = nil
local activePreviewModels = {}
local previewRotationConnection = nil

-- Fungsi untuk memulai/menghentikan rotasi pratinjau
local function stopPreviewRotation()
	if previewRotationConnection then
		previewRotationConnection:Disconnect()
		previewRotationConnection = nil
	end
end

local function startPreviewRotation()
	stopPreviewRotation()
	local cameraAngle = 0
	previewRotationConnection = RunService.RenderStepped:Connect(function(dt)
		cameraAngle = cameraAngle + (dt * 0.5)
		for _, data in ipairs(activePreviewModels) do
			if data.model and data.model.PrimaryPart then
				local rotation = CFrame.Angles(0, cameraAngle, 0)
				local offset = Vector3.new(0, 0, 5)
				local cameraPosition = data.model.PrimaryPart.Position + rotation:VectorToWorldSpace(offset)
				data.camera.CFrame = CFrame.new(cameraPosition, data.model.PrimaryPart.Position)
			end
		end
	end)
end

-- Fungsi untuk mengisi frame pratinjau hadiah
local function populatePrizePreview()
	-- Bersihkan item dan model yang ada
	for _, child in ipairs(prizeListContainer:GetChildren()) do
		if not child:IsA("UILayout") then
			child:Destroy()
		end
	end
	for _, data in ipairs(activePreviewModels) do
		if data.model then
			data.model:Destroy()
		end
	end
	table.clear(activePreviewModels)

	local allSkins = {}
	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinName ~= "Default Skin" then
				table.insert(allSkins, {
					WeaponName = weaponName,
					SkinName = skinName,
					SkinData = skinData
				})
			end
		end
	end

	table.sort(allSkins, function(a, b)
		if a.WeaponName ~= b.WeaponName then
			return a.WeaponName < b.WeaponName
		else
			return a.SkinName < b.SkinName
		end
	end)

	for _, skinInfo in ipairs(allSkins) do
		local prizeItemFrame = Instance.new("Frame")
		prizeItemFrame.Name = skinInfo.SkinName
		prizeItemFrame.Size = UDim2.new(0, 200, 0, 220)
		prizeItemFrame.BackgroundTransparency = 1
		prizeItemFrame.Parent = prizeListContainer

		local itemLayout = Instance.new("UIListLayout", prizeItemFrame)
		itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
		itemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		itemLayout.Padding = UDim.new(0, 5)

		local viewport = Instance.new("ViewportFrame")
		viewport.Size = UDim2.new(1, 0, 0, 150)
		viewport.BackgroundColor3 = Color3.fromRGB(25, 27, 30)
		viewport.LightColor = Color3.new(1, 1, 1)
		viewport.LightDirection = Vector3.new(-1, -1, -1)
		viewport.LayoutOrder = 1
		viewport.Parent = prizeItemFrame
		local vpCorner = Instance.new("UICorner", viewport)
		vpCorner.CornerRadius = UDim.new(0, 8)

		local worldModel = Instance.new("WorldModel", viewport)
		local viewportCamera = Instance.new("Camera")
		viewportCamera.Parent = viewport
		viewportCamera.FieldOfView = 30
		viewport.CurrentCamera = viewportCamera

		local weaponConfig = WeaponModule.Weapons[skinInfo.WeaponName]
		local skinData = weaponConfig.Skins[skinInfo.SkinName]
		local previewModel = Instance.new("Model")
		previewModel.Name = "PreviewModel"
		previewModel.Parent = worldModel

		local modelPart = Instance.new("Part")
		modelPart.Name = "Handle"
		modelPart.Anchored = true
		modelPart.CanCollide = false
		modelPart.Size = Vector3.new(1, 1, 1)
		modelPart.CFrame = CFrame.new(0, 0, 0)
		modelPart.Parent = previewModel
		previewModel.PrimaryPart = modelPart

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = skinData.MeshId
		mesh.TextureId = skinData.TextureId
		mesh.Scale = Vector3.new(1, 1, 1)
		mesh.Parent = modelPart

		table.insert(activePreviewModels, {model = previewModel, camera = viewportCamera})

		local weaponNameLabel = Instance.new("TextLabel")
		weaponNameLabel.Size = UDim2.new(1, 0, 0, 20)
		weaponNameLabel.Text = string.upper(skinInfo.WeaponName)
		weaponNameLabel.Font = Enum.Font.SourceSansBold
		weaponNameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		weaponNameLabel.TextSize = 16
		weaponNameLabel.BackgroundTransparency = 1
		weaponNameLabel.LayoutOrder = 2
		weaponNameLabel.Parent = prizeItemFrame

		local skinNameLabel = Instance.new("TextLabel")
		skinNameLabel.Size = UDim2.new(1, 0, 0, 30)
		skinNameLabel.Text = skinInfo.SkinName
		skinNameLabel.Font = Enum.Font.SourceSans
		skinNameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		skinNameLabel.TextSize = 20
		skinNameLabel.BackgroundTransparency = 1
		skinNameLabel.LayoutOrder = 3
		skinNameLabel.Parent = prizeItemFrame
	end

    -- Update CanvasSize after populating
	task.wait()
    prizeListContainer.CanvasSize = UDim2.new(0, 0, 0, prizeListLayout.AbsoluteContentSize.Y)
end

-- Fungsi untuk mengambil konfigurasi dari server
local function fetchGachaConfig()
	local success, result = pcall(function()
		return GetGachaConfig:InvokeServer()
	end)

	if success and result then
		rarityChances = result
		legendaryChanceLabel.Text = "Peluang Legendaris: " .. (rarityChances.Legendary or "N/A") .. "%"
		commonChanceLabel.Text = "Peluang Biasa: " .. (rarityChances.Common or "N/A") .. "%"
	else
		legendaryChanceLabel.Text = "Gagal memuat peluang."
		warn("GachaUI Error: Gagal mengambil konfigurasi gacha dari server - " .. tostring(result))
	end
end

GachaRollEvent.OnClientEvent:Connect(function(result)
	latestResult = result
end)

local latestMultiResult = nil
GachaMultiRollEvent.OnClientEvent:Connect(function(result)
	latestMultiResult = result
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

local function createPrizeLabel(prize)
	local prizeLabel = Instance.new("TextLabel")
	prizeLabel.Size = UDim2.new(0, 120, 0, 80)
	prizeLabel.Font = Enum.Font.SourceSans
	prizeLabel.TextWrapped = true
	prizeLabel.BackgroundColor3 = Color3.fromRGB(55, 58, 64)
	prizeLabel.BorderSizePixel = 0
	local corner = Instance.new("UICorner", prizeLabel)
	corner.CornerRadius = UDim.new(0, 8)

	if prize.Type == "Skin" then
		prizeLabel.Text = string.format("%s\n(%s)", prize.SkinName, prize.WeaponName)
		prizeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		prizeLabel.LayoutOrder = 1 -- Legendary items first
	else
		prizeLabel.Text = string.format("+%d\nBloodCoins", prize.Amount)
		prizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		prizeLabel.LayoutOrder = 2 -- Common items after
	end
	return prizeLabel
end

local function showMultiResult(resultData)
	for _, child in ipairs(prizeContainer:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if resultData.Success then
		for _, prize in ipairs(resultData.Prizes) do
			local prizeLabel = createPrizeLabel(prize)
			prizeLabel.Parent = prizeContainer
		end
		playSound("Boss.Complete", { Volume = 0.8 })
	else
		multiResultTitle.Text = "Gagal!"
		local errorLabel = Instance.new("TextLabel", multiResultFrame)
		errorLabel.Size = UDim2.new(1, 0, 0.5, 0)
		errorLabel.Position = UDim2.new(0, 0, 0.25, 0)
		errorLabel.Text = resultData.Message or "Terjadi kesalahan."
		errorLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
	end
	multiResultFrame.Visible = true
end

local function toggleGachaUI(visible)
	if isRolling then return end
	if visible then
		populatePrizes()
		if not rarityChances then
			fetchGachaConfig()
		end
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

-- Koneksi tombol baru
viewPrizesButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	populatePrizePreview()
	prizePreviewFrame.Visible = true
	startPreviewRotation()
end)

ppfBackButton.MouseButton1Click:Connect(function()
	prizePreviewFrame.Visible = false
	mainFrame.Visible = true
	stopPreviewRotation()
end)

rollButton.MouseButton1Click:Connect(function()
	if isRolling then return end

	isRolling = true
	rollButton.Visible = false
	multiRollButton.Visible = false
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

multiRollButton.MouseButton1Click:Connect(function()
	if isRolling then return end

	isRolling = true
	rollButton.Visible = false
	multiRollButton.Visible = false
	latestMultiResult = nil

	playSound("Weapons.Pistol.Reload", { Volume = 0.5 })

	task.spawn(playReelAnimation)
	GachaMultiRollEvent:FireServer()

	task.wait(3) -- Tunggu animasi selesai

	local startTime = tick()
	local timeout = 10 -- detik
	while not latestMultiResult do
		if tick() - startTime > timeout then
			latestMultiResult = { Success = false, Message = "Server tidak merespons. Coba lagi." }
			break
		end
		task.wait(0.1)
	end

	showMultiResult(latestMultiResult)
	isRolling = false
end)


resultCloseButton.MouseButton1Click:Connect(function()
	playSound("Weapons.Pistol.Reload", { Volume = 0.5 })
	resultFrame.Visible = false
	rollButton.Visible = true
	multiRollButton.Visible = true
end)

multiResultCloseButton.MouseButton1Click:Connect(function()
	playSound("Weapons.Pistol.Reload", { Volume = 0.5 })
	multiResultFrame.Visible = false
	rollButton.Visible = true
	multiRollButton.Visible = true
end)

print("GachaUI.lua loaded for player with prize preview.")