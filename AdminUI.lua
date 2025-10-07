-- AdminUI.lua (LocalScript)
-- Path: StarterGui/AdminUI.lua
-- Script Place: Lobby

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Player and Admin Check
local player = Players.LocalPlayer
local isAdmin = false

-- Fungsi untuk membuat UI
local function CreateAdminUI()
	-- Hapus UI lama jika ada
	local oldGui = player.PlayerGui:FindFirstChild("AdminPanelGui")
	if oldGui then oldGui:Destroy() end

	-- Remote Events/Functions
	local adminEventsFolder = ReplicatedStorage:WaitForChild("AdminEvents")
	local requestDataFunc = adminEventsFolder:WaitForChild("AdminRequestData")
	local updateDataEvent = adminEventsFolder:WaitForChild("AdminUpdateData")
	local deleteDataEvent = adminEventsFolder:WaitForChild("AdminDeleteData")

	-- State untuk konfirmasi
	local pendingAction, pendingTargetId, pendingData = nil, nil, nil

	-- UI Creation
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanelGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 360) -- Tambah tinggi untuk input Koin
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -180)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
	mainFrame.Visible = false
	mainFrame.Draggable = true
	mainFrame.Active = true
	mainFrame.ZIndex = 1
	mainFrame.Parent = screenGui
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

	local mainLayout = Instance.new("UIListLayout")
	mainLayout.Padding = UDim.new(0, 10)
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.Parent = mainFrame

	local mainPadding = Instance.new("UIPadding")
	mainPadding.PaddingTop = UDim.new(0, 10)
	mainPadding.PaddingBottom = UDim.new(0, 10)
	mainPadding.PaddingLeft = UDim.new(0, 10)
	mainPadding.PaddingRight = UDim.new(0, 10)
	mainPadding.Parent = mainFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Text = "Admin Panel"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 18
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = mainFrame

	-- UserID Input
	local userIdBox = Instance.new("TextBox")
	userIdBox.Name = "UserIdBox"
	userIdBox.Size = UDim2.new(1, 0, 0, 35)
	userIdBox.PlaceholderText = "Masukkan UserID Target..."
	userIdBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	userIdBox.TextColor3 = Color3.new(1, 1, 1)
	userIdBox.LayoutOrder = 2
	userIdBox.Parent = mainFrame
	Instance.new("UICorner", userIdBox).CornerRadius = UDim.new(0, 6)

	-- Input Fields Frame
	local inputFields = Instance.new("Frame")
	inputFields.Size = UDim2.new(1, 0, 0, 80) -- Tinggi untuk dua baris
	inputFields.BackgroundTransparency = 1
	inputFields.LayoutOrder = 3
	inputFields.Parent = mainFrame

	local inputsLayout = Instance.new("UIListLayout")
	inputsLayout.Padding = UDim.new(0, 10)
	inputsLayout.Parent = inputFields

	-- Baris 1: Level & XP
	local levelXpFrame = Instance.new("Frame")
	levelXpFrame.Size = UDim2.new(1, 0, 0, 35)
	levelXpFrame.BackgroundTransparency = 1
	levelXpFrame.Parent = inputFields

	local levelXpLayout = Instance.new("UIListLayout")
	levelXpLayout.FillDirection = Enum.FillDirection.Horizontal
	levelXpLayout.Padding = UDim.new(0, 10)
	levelXpLayout.Parent = levelXpFrame

	local levelBox = Instance.new("TextBox")
	levelBox.Name = "LevelBox"
	levelBox.Size = UDim2.new(0.5, -5, 1, 0)
	levelBox.PlaceholderText = "Level..."
	levelBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	levelBox.TextColor3 = Color3.new(1, 1, 1)
	levelBox.Parent = levelXpFrame
	Instance.new("UICorner", levelBox).CornerRadius = UDim.new(0, 6)

	local xpBox = Instance.new("TextBox")
	xpBox.Name = "XpBox"
	xpBox.Size = UDim2.new(0.5, -5, 1, 0)
	xpBox.PlaceholderText = "XP..."
	xpBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	xpBox.TextColor3 = Color3.new(1, 1, 1)
	xpBox.Parent = levelXpFrame
	Instance.new("UICorner", xpBox).CornerRadius = UDim.new(0, 6)

	-- Baris 2: Koin
	local coinsBox = Instance.new("TextBox")
	coinsBox.Name = "CoinsBox"
	coinsBox.Size = UDim2.new(1, 0, 0, 35)
	coinsBox.PlaceholderText = "Koin..."
	coinsBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	coinsBox.TextColor3 = Color3.new(1, 1, 1)
	coinsBox.Parent = inputFields
	Instance.new("UICorner", coinsBox).CornerRadius = UDim.new(0, 6)

	-- Buttons Frame
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Size = UDim2.new(1, 0, 0, 35)
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.LayoutOrder = 4
	buttonsFrame.Parent = mainFrame

	local buttonsLayout = Instance.new("UIListLayout")
	buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonsLayout.Padding = UDim.new(0, 10)
	buttonsLayout.Parent = buttonsFrame

	local function createButton(name, text, parent, size)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Text = text
		button.Size = size or UDim2.new(0.33, -7, 1, 0)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.SourceSansBold
		button.Parent = parent
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
		return button
	end

	local getDataButton = createButton("GetDataButton", "Get Data", buttonsFrame)
	getDataButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

	local setDataButton = createButton("SetDataButton", "Set Data", buttonsFrame)
	setDataButton.BackgroundColor3 = Color3.fromRGB(70, 90, 150)

	local deleteDataButton = createButton("DeleteDataButton", "Delete Data", buttonsFrame)
	deleteDataButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)

	-- Player List Button
	local playerListButton = createButton("PlayerListButton", "Daftar Pemain", mainFrame, UDim2.new(1, 0, 0, 35))
	playerListButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	playerListButton.LayoutOrder = 5

	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 40)
	statusLabel.Text = "Status: Idle | Tekan 'P' untuk Buka/Tutup"
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextWrapped = true
	statusLabel.LayoutOrder = 6
	statusLabel.Parent = mainFrame

	-- Pop-up Frames
	local function createPopupFrame(name, size, zIndex)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = size
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		frame.BorderColor3 = Color3.fromRGB(120, 120, 120)
		frame.Visible = false
		frame.ZIndex = zIndex
		frame.Parent = screenGui
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = frame

		return frame
	end

	-- Player List UI
	local playerListFrame = createPopupFrame("PlayerListFrame", UDim2.new(0, 300, 0, 400), 4)
	local playerListLayout = Instance.new("UIListLayout")
	playerListLayout.Padding = UDim.new(0, 5)
	playerListLayout.Parent = playerListFrame

	local playerListTitle = Instance.new("TextLabel")
	playerListTitle.Size = UDim2.new(1, 0, 0, 25)
	playerListTitle.Text = "Pemain Online"
	playerListTitle.Font = Enum.Font.SourceSansBold
	playerListTitle.TextColor3 = Color3.new(1, 1, 1)
	playerListTitle.BackgroundTransparency = 1
	playerListTitle.Parent = playerListFrame

	local playerListScroll = Instance.new("ScrollingFrame")
	playerListScroll.Size = UDim2.new(1, 0, 1, -65)
	playerListScroll.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	playerListScroll.Parent = playerListFrame
	Instance.new("UICorner", playerListScroll).CornerRadius = UDim.new(0, 6)

	local playerListScrollLayout = Instance.new("UIListLayout")
	playerListScrollLayout.Padding = UDim.new(0, 5)
	playerListScrollLayout.Parent = playerListScroll

	local closePlayerListButton = createButton("ClosePlayerListButton", "Tutup", playerListFrame, UDim2.new(1, 0, 0, 30))
	closePlayerListButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

	-- Data Display UI
	local dataDisplayFrame = createPopupFrame("DataDisplayFrame", UDim2.new(0, 300, 0, 210), 2)
	local dataDisplayLayout = Instance.new("UIListLayout")
	dataDisplayLayout.Padding = UDim.new(0, 10)
	dataDisplayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dataDisplayLayout.Parent = dataDisplayFrame

	local displayTitle = Instance.new("TextLabel")
	displayTitle.Size = UDim2.new(1, 0, 0, 25)
	displayTitle.Text = "Player Data"
	displayTitle.Font = Enum.Font.SourceSansBold
	displayTitle.TextColor3 = Color3.new(1, 1, 1)
	displayTitle.BackgroundTransparency = 1
	displayTitle.Parent = dataDisplayFrame

	local displayUserIdLabel = createButton("displayUserIdLabel", "", dataDisplayFrame, UDim2.new(1,0,0,20))
	local displayLevelLabel = createButton("displayLevelLabel", "", dataDisplayFrame, UDim2.new(1,0,0,20))
	local displayXpLabel = createButton("displayXpLabel", "", dataDisplayFrame, UDim2.new(1,0,0,20))
	local displayCoinsLabel = createButton("displayCoinsLabel", "", dataDisplayFrame, UDim2.new(1,0,0,20))

	local closeDisplayButton = createButton("CloseDisplayButton", "Close", dataDisplayFrame, UDim2.new(1, 0, 0, 30))
	closeDisplayButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

	-- Confirmation Dialog UI
	local confirmationFrame = createPopupFrame("ConfirmationFrame", UDim2.new(0, 350, 0, 130), 3)
	local confirmationLayout = Instance.new("UIListLayout")
	confirmationLayout.Padding = UDim.new(0, 10)
	confirmationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	confirmationLayout.Parent = confirmationFrame

	local confirmationLabel = Instance.new("TextLabel")
	confirmationLabel.Size = UDim2.new(1, 0, 0, 50)
	confirmationLabel.TextColor3 = Color3.new(1, 1, 1)
	confirmationLabel.BackgroundTransparency = 1
	confirmationLabel.TextWrapped = true
	confirmationLabel.Parent = confirmationFrame

	local confirmButtonsFrame = Instance.new("Frame")
	confirmButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
	confirmButtonsFrame.BackgroundTransparency = 1
	confirmButtonsFrame.Parent = confirmationFrame

	local confirmButtonsLayout = Instance.new("UIListLayout")
	confirmButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
	confirmButtonsLayout.Padding = UDim.new(0, 10)
	confirmButtonsLayout.Parent = confirmButtonsFrame

	local confirmYesButton = createButton("ConfirmYesButton", "Ya", confirmButtonsFrame, UDim2.new(0.5, -5, 1, 0))
	confirmYesButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

	local confirmNoButton = createButton("ConfirmNoButton", "Tidak", confirmButtonsFrame, UDim2.new(0.5, -5, 1, 0))
	confirmNoButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

	-- UI Logic
	local function togglePanel()
		mainFrame.Visible = not mainFrame.Visible
		if not mainFrame.Visible then -- Sembunyikan semua popup
			dataDisplayFrame.Visible, confirmationFrame.Visible, playerListFrame.Visible = false, false, false
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or userIdBox:IsFocused() or levelBox:IsFocused() or xpBox:IsFocused() then return end
		if input.KeyCode == Enum.KeyCode.P then togglePanel() end
	end)

	-- Player List Logic
	local function updatePlayerList()
		for _, v in ipairs(playerListScroll:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			local playerButton = createButton(p.Name, p.Name, playerListScroll, UDim2.new(1, 0, 0, 30))
			playerButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			playerButton.MouseButton1Click:Connect(function()
				userIdBox.Text = tostring(p.UserId)
				playerListFrame.Visible = false
				statusLabel.Text = "Status: UserID " .. p.UserId .. " dipilih."
			end)
		end
	end

	playerListButton.MouseButton1Click:Connect(function()
		updatePlayerList()
		playerListFrame.Visible = true
	end)
	closePlayerListButton.MouseButton1Click:Connect(function() playerListFrame.Visible = false end)
	Players.PlayerAdded:Connect(updatePlayerList)
	Players.PlayerRemoving:Connect(updatePlayerList)

	-- Main Buttons Logic
	getDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then statusLabel.Text = "Status: UserID tidak valid."; return end

		statusLabel.Text = "Status: Meminta data..."
		local data, message = requestDataFunc:InvokeServer(targetUserId)

		if data and data.Stats and data.Inventory then
			levelBox.Text = tostring(data.Stats.Level)
			xpBox.Text = tostring(data.Stats.XP)
			coinsBox.Text = tostring(data.Inventory.Coins)
			statusLabel.Text = "Status: Data berhasil dimuat untuk UserID " .. targetUserId
			displayUserIdLabel.Text = "UserID: " .. targetUserId
			displayLevelLabel.Text = "Level: " .. data.Stats.Level
			displayXpLabel.Text = "XP: " .. data.Stats.XP
			displayCoinsLabel.Text = "Koin: " .. data.Inventory.Coins
			dataDisplayFrame.Visible = true
		else
			levelBox.Text, xpBox.Text, coinsBox.Text = "", "", ""
			statusLabel.Text = "Status: Gagal memuat data. Pesan: " .. (message or "Tidak ada data.")
			dataDisplayFrame.Visible = false
		end
	end)

	local function triggerConfirmation(action, id, data)
		pendingAction, pendingTargetId, pendingData = action, id, data
		if action == "set" then
			confirmationLabel.Text = "Apakah Anda yakin ingin mengubah data untuk UserID " .. id .. "?"
		else
			confirmationLabel.Text = "PERINGATAN: Aksi ini akan menghapus data secara permanen. Apakah Anda yakin ingin menghapus data untuk UserID " .. id .. "?"
		end
		confirmationFrame.Visible = true
	end

	setDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		local newLevel = tonumber(levelBox.Text)
		local newXp = tonumber(xpBox.Text)
		local newCoins = tonumber(coinsBox.Text)

		if not (targetUserId and newLevel and newXp and newCoins) then
			statusLabel.Text = "Status: Semua kolom harus diisi angka valid."
			return
		end

		local newData = {
			Stats = {Level = newLevel, XP = newXp},
			Inventory = {Coins = newCoins}
		}
		triggerConfirmation("set", targetUserId, newData)
	end)

	deleteDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then statusLabel.Text = "Status: UserID tidak valid."; return end
		triggerConfirmation("delete", targetUserId)
	end)

	closeDisplayButton.MouseButton1Click:Connect(function() dataDisplayFrame.Visible = false end)

	local function resetConfirmationState()
		pendingAction, pendingTargetId, pendingData = nil, nil, nil
		confirmationFrame.Visible = false
	end

	confirmYesButton.MouseButton1Click:Connect(function()
		if pendingAction == "set" then
			updateDataEvent:FireServer(pendingTargetId, pendingData)
			statusLabel.Text = "Status: Permintaan perubahan data dikirim."
		elseif pendingAction == "delete" then
			deleteDataEvent:FireServer(pendingTargetId)
			statusLabel.Text = "Status: Permintaan hapus data dikirim."
			levelBox.Text, xpBox.Text, coinsBox.Text = "", "", ""
		end
		dataDisplayFrame.Visible = false
		resetConfirmationState()
	end)

	confirmNoButton.MouseButton1Click:Connect(function()
		resetConfirmationState()
		statusLabel.Text = "Status: Aksi dibatalkan."
	end)
end

-- Main Logic
player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
	isAdmin = player:GetAttribute("IsAdmin")
	if isAdmin then CreateAdminUI()
	else
		local adminGui = player.PlayerGui:FindFirstChild("AdminPanelGui")
		if adminGui then adminGui:Destroy() end
	end
end)

isAdmin = player:GetAttribute("IsAdmin")
if isAdmin then CreateAdminUI() end
