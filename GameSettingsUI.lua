-- GameSettingsUI.lua (LocalScript)
-- StarterGui/GameSettingsUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local settingsFolder = playerGui:FindFirstChild("MobileButtonsSettings") or Instance.new("Folder")
settingsFolder.Name = "MobileButtonsSettings"
settingsFolder.Parent = playerGui

-- Ambil/siapkan ScreenGui umum
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameSettingsUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Ambil/siapkan ScreenGui umum
local screenGui2 = Instance.new("ScreenGui")
screenGui2.Name = "GameSettingsUI2"
screenGui2.ResetOnSpawn = false
screenGui2.IgnoreGuiInset = false
screenGui2.Parent = playerGui

-- Util: simpan & ambil setting
local function saveButtonSettings(button, pos, size)
	if not button or not button.Parent then return end
	local name = button.Name

	-- JSON yang akan disimpan
	local valueJson = HttpService:JSONEncode({
		position = {X = pos.X.Scale, Y = pos.Y.Scale, OffsetX = pos.X.Offset, OffsetY = pos.Y.Offset},
		size     = {X = size.X.Scale, Y = size.Y.Scale, OffsetX = size.X.Offset, OffsetY = size.Y.Offset}
	})

	-- Helper menulis node
	local function writeNode(key)
		local node = settingsFolder:FindFirstChild(key) or Instance.new("StringValue")
		node.Name = key
		node.Value = valueJson
		node.Parent = settingsFolder
	end

	-- Jika salah satu dari dua prompt elemen: tulis ke KEDUANYA
	if name == "ElementActivatePrompt" or name == "ElementPurchasedPrompt" then
		writeNode("ElementActivatePrompt")
		writeNode("ElementPurchasedPrompt")
	else
		writeNode(name)
	end
end

local function loadButtonSettings(button)
	local key = button.Name
	local node = settingsFolder:FindFirstChild(key)

	-- Fallback: pakai kembarannya jika tidak ditemukan
	if not node and (key == "ElementActivatePrompt" or key == "ElementPurchasedPrompt") then
		node = settingsFolder:FindFirstChild("ElementActivatePrompt")
			or settingsFolder:FindFirstChild("ElementPurchasedPrompt")
	end

	if not node then return end

	local ok, data = pcall(function() return HttpService:JSONDecode(node.Value) end)
	if ok and data and data.position and data.size then
		button.Position = UDim2.new(data.position.X, data.position.OffsetX, data.position.Y, data.position.OffsetY)
		button.Size     = UDim2.new(data.size.X,     data.size.OffsetX,     data.size.Y,     data.size.OffsetY)
	end
end

-- Daftar tombol yang akan bisa diatur
local TARGET_BUTTON_NAMES = {
	"MobileReloadButton",
	"MobileAimButton",
	"MobileSprintButton",
	"HPContainer",
	"StaminaContainer",
	"AmmoContainer",
	"ElementActivatePrompt",
	"PerkDisplayContainer",
	"WaveContainer", -- Wave counter dari WaveCounterClient
	"BloodContainer", -- PointsClient (BP)
	"BossTimerContainer", -- BossTimerClient

}

-- === PLACEHOLDER untuk Settings Mode ===
local function ensurePlaceholders(screenGui, playerGui)
	-- Buat 1 placeholder generik
	local function ensureOne(name, defaultText)
		-- Sudah ada (di PlayerGui atau ScreenGui)? skip
		local existing = playerGui:FindFirstChild(name, true) or screenGui:FindFirstChild(name, true)
		if existing and existing:IsA("GuiObject") then
			-- pastikan terlihat saat settings
			existing.Visible = true
			return existing
		end

		-- Buat placeholder sederhana
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = UDim2.new(0, 200, 0, 70)
		frame.Position = UDim2.new(1, -12, 0, 12)
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		frame.BorderSizePixel = 0
		frame.Visible = true
		frame.ZIndex = 6
		frame:SetAttribute("SettingsPlaceholder", true)
		frame.Parent = screenGui

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -20, 1, -20)
		label.Position = UDim2.new(0, 10, 0, 10)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255,255,255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = defaultText
		label.ZIndex = frame.ZIndex + 1
		label.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(80, 200, 255)
		stroke.Parent = frame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame

		return frame
	end

	-- Buat placeholder untuk dua container penting:
	ensureOne("ElementActivatePrompt", "Element ACTIVE: 10s")
	ensureOne("WaveContainer", "Wave Counter")
	ensureOne("BloodContainer", "BP: 0")
	ensureOne("BossTimerContainer", "BOSS TIMER")
end

-- Buat tombol ⚙️
local gearBtn = Instance.new("ImageButton")
gearBtn.Name = "GameSettingsButton"
gearBtn.Size = UDim2.new(0.055, 0, 0.0, 0) -- Menggunakan ukuran responsif 8% dari parent
gearBtn.Position = UDim2.new(0.01, 0, 0.01, 0) -- Posisi di kiri atas dengan padding 10px
gearBtn.AnchorPoint = Vector2.new(0, 0)
gearBtn.BackgroundTransparency = 1
gearBtn.Image = "rbxassetid://128019335135588"
gearBtn.ZIndex = 100
gearBtn.Parent = screenGui2

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = gearBtn

-- Overlay panel saat Settings Mode
local overlay = Instance.new("Frame")
overlay.Name = "GameSettingsOverlay"
overlay.Visible = false
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel = 0
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.ZIndex = 99
overlay.Parent = screenGui

-- Container untuk tombol Simpan dan Batal
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(0, 260, 0, 50)
buttonContainer.AnchorPoint = Vector2.new(0.5, 1) -- Anchor ke bawah tengah
buttonContainer.Position = UDim2.new(0.5, 0, 1, -20) -- Posisi di bawah dengan offset 20 pixel
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 100
buttonContainer.Parent = overlay

-- UIListLayout untuk mengatur tombol secara horizontal dengan jarak
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 20)
listLayout.Parent = buttonContainer

local btnSimpan = Instance.new("TextButton")
btnSimpan.Name = "SaveBtn"
btnSimpan.Size = UDim2.new(0, 120, 0, 40)
btnSimpan.LayoutOrder = 1
btnSimpan.Text = "Simpan"
btnSimpan.Font = Enum.Font.GothamBold
btnSimpan.TextScaled = true
btnSimpan.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
btnSimpan.TextColor3 = Color3.new(1, 1, 1)
btnSimpan.ZIndex = 100
btnSimpan.Parent = buttonContainer
Instance.new("UICorner", btnSimpan).CornerRadius = UDim.new(0, 8)

local btnBatal = Instance.new("TextButton")
btnBatal.Name = "CancelBtn"
btnBatal.Size = UDim2.new(0, 120, 0, 40)
btnBatal.LayoutOrder = 2
btnBatal.Text = "Batal"
btnBatal.Font = Enum.Font.GothamBold
btnBatal.TextScaled = true
btnBatal.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
btnBatal.TextColor3 = Color3.new(1, 1, 1)
btnBatal.ZIndex = 100
btnBatal.Parent = buttonContainer
Instance.new("UICorner", btnBatal).CornerRadius = UDim.new(0, 8)

-- Handle drag & resize untuk tombol target
local activeEditors = {}

local function makeDraggable(frame)
	local dragging = false
	local dragStart, startPos
	local inputConn1, inputConn2, inputConn3

	inputConn1 = frame.InputBegan:Connect(function(input)
		if frame:GetAttribute("IsResizing") then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	inputConn2 = frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			-- noop
		end
	end)

	inputConn3 = UserInputService.InputChanged:Connect(function(input)
		if frame:GetAttribute("IsResizing") then
			return
		end

		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	return {inputConn1, inputConn2, inputConn3}
end

local function makeResizable(frame)
	local handle = Instance.new("Frame")
	handle.Name = "ResizeHandle"
	handle.AnchorPoint = Vector2.new(1, 1)
	handle.Size = UDim2.new(0, 20, 0, 20)
	handle.Position = UDim2.new(1, 0, 1, 0)
	handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	handle.BackgroundTransparency = 0.2
	handle.BorderSizePixel = 0
	handle.ZIndex = frame.ZIndex + 2
	handle.Parent = frame
	handle.Active = true
	frame.Active = true
	Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 6)

	local resizing = false
	frame:SetAttribute("IsResizing", false)
	local startSize, startPos, startInputPos
	local c1, c2, c3

	c1 = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			frame:SetAttribute("IsResizing", true)

			startInputPos = input.Position
			startSize = frame.Size
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
					frame:SetAttribute("IsResizing", false)
				end
			end)
		end
	end)

	c2 = handle.InputChanged:Connect(function(input)
		-- noop
	end)

	c3 = UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInputPos
			local newW = startSize.X.Offset + delta.X
			local newH = startSize.Y.Offset + delta.Y
			frame.Size = UDim2.new(startSize.X.Scale, newW, startSize.Y.Scale, newH)	
			local ax, ay = frame.AnchorPoint.X, frame.AnchorPoint.Y
			if ax ~= 0 or ay ~= 0 then
				local dW = newW - startSize.X.Offset
				local dH = newH - startSize.Y.Offset

				frame.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + math.floor(dW * ax + 0.5),
					startPos.Y.Scale,
					startPos.Y.Offset + math.floor(dH * ay + 0.5)
				)
			end
		end
	end)

	return {c1, c2, c3}, handle
end

local function findTargetButtons()
	local found = {}
	for _, name in ipairs(TARGET_BUTTON_NAMES) do
		local btn = playerGui:FindFirstChild(name, true) or screenGui:FindFirstChild(name, true)
		if btn and btn:IsA("GuiObject") then
			table.insert(found, btn)
		end
	end
	return found
end

local function applySavedPositions()
	for _, btn in ipairs(findTargetButtons()) do
		btn.Visible = true
		loadButtonSettings(btn)
	end
end

-- NEW: helper untuk dummy perk di Settings Mode
local function showDummyPerksInSettings()
	-- pakai scope playerGui/screenGui yang sudah ada di GameSettings.lua
	local pdGui = playerGui:FindFirstChild("PerkDisplayGui")
	local main  = pdGui and pdGui:FindFirstChild("PerkDisplayContainer", true)
	local list  = main and main:FindFirstChild("PerksContainer")  -- dibuat di PerkDisplayClient.lua
	-- emoji mengikuti mapping di PerkDisplayClient (HPPlus, StaminaPlus, ReloadPlus)
	local emojis = {"❤️","⚡","🔧"}

	local function makeCard(emoji)
		local card = Instance.new("Frame")
		card.Name = "SettingsDummyPerk"
		card.Size = UDim2.new(0, 50, 0, 50)
		card.BackgroundColor3 = Color3.fromRGB(35,35,45)
		card.BorderSizePixel = 0
		card:SetAttribute("SettingsPlaceholder", true)

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = card

		local iconBg = Instance.new("Frame")
		iconBg.Size = UDim2.new(0, 36, 0, 36)
		iconBg.Position = UDim2.new(0, 7, 0, 7)
		iconBg.BackgroundColor3 = Color3.fromRGB(25,25,35)
		iconBg.BorderSizePixel = 0
		iconBg.Parent = card
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 6)
		iconCorner.Parent = iconBg

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = emoji
		icon.TextScaled = true
		icon.TextColor3 = Color3.fromRGB(255,215,0)
		icon.Parent = iconBg

		return card
	end

	if list then
		-- bersihkan dummy sebelumnya
		for _, ch in ipairs(list:GetChildren()) do
			if ch:IsA("GuiObject") and ch:GetAttribute("SettingsPlaceholder") then
				ch:Destroy()
			end
		end

		-- jika belum ada kartu perk asli, baru tampilkan dummy
		local hasReal = false
		for _, ch in ipairs(list:GetChildren()) do
			if ch:IsA("Frame") and string.find(ch.Name, "^Perk_") then
				hasReal = true
				break
			end
		end
		if not hasReal then
			for _, e in ipairs(emojis) do
				makeCard(e).Parent = list
			end
			-- lebarkan sedikit agar 3 kartu terlihat rapi
			main.Size = UDim2.new(0, math.max(100, 3*(50 + 8) + 10), 0, 50)
			main.BackgroundTransparency = 0.2
			main.Visible = true
		end
	else
		-- fallback: jika PerkDisplayClient belum sempat membuat GUI, buat placeholder ringan di GameSettings screenGui
		local placeholder = Instance.new("Frame")
		placeholder.Name = "PerkDisplayContainer"
		placeholder.Size = UDim2.new(0, 190, 0, 50)
		placeholder.Position = UDim2.new(1, -12, 0, 90)
		placeholder.AnchorPoint = Vector2.new(1, 0)
		placeholder.BackgroundColor3 = Color3.fromRGB(35,35,45)
		placeholder.BorderSizePixel = 0
		placeholder.ZIndex = 6
		placeholder:SetAttribute("SettingsPlaceholder", true)
		placeholder.Parent = screenGui

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -20, 1, -20)
		label.Position = UDim2.new(0, 10, 0, 10)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255,255,255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = "Perks: ❤️ ⚡ 🔧"
		label.Parent = placeholder

		local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(80,200,255); stroke.Parent = placeholder
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = placeholder
	end
end

local function setSettingsMode(enabled)
	overlay.Visible = enabled
	gearBtn.Visible = not enabled -- Sembunyikan/tampilkan tombol settings

	for _, btn in ipairs(findTargetButtons()) do
		btn:SetAttribute("IsInSettingsMode", enabled)
	end

	if enabled then
		ensurePlaceholders(screenGui, playerGui)
		applySavedPositions()
		showDummyPerksInSettings()  -- NEW: tampilkan 3 dummy perk saat settings mode

		for _, btn in ipairs(findTargetButtons()) do
			if not activeEditors[btn.Name] then
				local ghost = Instance.new("Frame")
				ghost.Name = "EditGhost"
				ghost.BackgroundTransparency = 1
				ghost.BorderSizePixel = 0
				ghost.Size = UDim2.new(1, 0, 1, 0)
				ghost.Position = UDim2.new(0, 0, 0, 0)
				ghost.ZIndex = btn.ZIndex + 1
				ghost.Parent = btn

				local stroke = Instance.new("UIStroke")
				stroke.Thickness = 2
				stroke.Transparency = 0
				stroke.Color = Color3.fromRGB(80, 200, 255)
				stroke.Parent = ghost

				local dragConns = makeDraggable(btn)
				local resizeConns, handle = makeResizable(btn)
				if btn.Name == "StaminaContainer" then
					btn.ClipsDescendants = true

					local function syncStaminaPanel()
						local panel = btn:FindFirstChild("Panel")
						if panel and panel:IsA("GuiObject") then
							-- Revert to original layout from SprintClient.lua to prevent it from disappearing
							panel.AnchorPoint = Vector2.new(0, 0)
							panel.Position    = UDim2.new(0, 0, 0, 0)
							panel.Size        = UDim2.new(1, 0, 1, 0)
						end
					end

					syncStaminaPanel()
					table.insert(resizeConns, btn:GetPropertyChangedSignal("Size"):Connect(syncStaminaPanel))
				end
				activeEditors[btn.Name] = { button = btn, dragConns = dragConns, resizeConns = resizeConns, ghost = ghost, handle = handle }
			end
		end
	else
		-- NEW: hapus dummy perk di PerkDisplay jika ada
		do
			local pdGui = playerGui:FindFirstChild("PerkDisplayGui")
			local main  = pdGui and pdGui:FindFirstChild("PerkDisplayContainer", true)
			local list  = main and main:FindFirstChild("PerksContainer")
			if list then
				for _, ch in ipairs(list:GetChildren()) do
					if ch:IsA("GuiObject") and ch:GetAttribute("SettingsPlaceholder") then
						ch:Destroy()
					end
				end
			end
		end
		for _, gui in ipairs(screenGui:GetDescendants()) do
			if gui:IsA("GuiObject") and gui:GetAttribute("SettingsPlaceholder") then
				gui:Destroy()
			end
		end
		for name, data in pairs(activeEditors) do
			if data.dragConns then for _, c in ipairs(data.dragConns) do pcall(function() c:Disconnect() end) end end
			if data.resizeConns then for _, c in ipairs(data.resizeConns) do pcall(function() c:Disconnect() end) end end
			if data.ghost and data.ghost.Parent then data.ghost:Destroy() end
			if data.handle and data.handle.Parent then data.handle:Destroy() end
			activeEditors[name] = nil
		end

		-- Perbaiki visibilitas AmmoContainer setelah keluar dari mode pengaturan
		local ammoContainer = playerGui:FindFirstChild("AmmoContainer", true)
		if ammoContainer then
			local character = player.Character
			ammoContainer.Visible = character and character:FindFirstChildOfClass("Tool") ~= nil
		end
	end
end

applySavedPositions()

gearBtn.MouseButton1Click:Connect(function()
	setSettingsMode(true)
end)

btnBatal.MouseButton1Click:Connect(function()
	applySavedPositions()
	setSettingsMode(false)
end)

btnSimpan.MouseButton1Click:Connect(function()
	for _, btn in ipairs(findTargetButtons()) do
		saveButtonSettings(btn, btn.Position, btn.Size)
	end
	setSettingsMode(false)
end)

playerGui.ChildAdded:Connect(function(child)
	for _, name in ipairs(TARGET_BUTTON_NAMES) do
		if child.Name == name and child:IsA("GuiObject") then
			loadButtonSettings(child)
		end
	end
end)
