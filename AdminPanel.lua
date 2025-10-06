-- AdminPanel.lua (LocalScript)
-- LOKASI: StarterGui
-- FUNGSI: Membuat UI Panel Admin yang rapi dan menangani semua logika di sisi klien.

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
	mainFrame.Size = UDim2.new(0, 400, 0, 280)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
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

	-- Level and XP Frame
	local levelXpFrame = Instance.new("Frame")
	levelXpFrame.Size = UDim2.new(1, 0, 0, 35)
	levelXpFrame.BackgroundTransparency = 1
	levelXpFrame.LayoutOrder = 3
	levelXpFrame.Parent = mainFrame

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

	local function createButton(name, text, parent)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Text = text
		button.Size = UDim2.new(0.33, -7, 1, 0)
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

	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 40)
	statusLabel.Text = "Status: Idle | Tekan 'P' untuk Buka/Tutup"
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextWrapped = true
	statusLabel.LayoutOrder = 5
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

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Parent = frame

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = frame

		return frame
	end

	-- Data Display UI
	local dataDisplayFrame = createPopupFrame("DataDisplayFrame", UDim2.new(0, 300, 0, 180), 2)

	local displayTitle = Instance.new("TextLabel")
	displayTitle.Size = UDim2.new(1, 0, 0, 25)
	displayTitle.Text = "Player Data"
	displayTitle.Font = Enum.Font.SourceSansBold
	displayTitle.TextSize = 16
	displayTitle.TextColor3 = Color3.new(1, 1, 1)
	displayTitle.BackgroundTransparency = 1
	displayTitle.Parent = dataDisplayFrame

	local function createDisplayLabel(name, parent)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(1, 0, 0, 20)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = parent
		return label
	end

	local displayUserIdLabel = createDisplayLabel("DisplayUserIdLabel", dataDisplayFrame)
	local displayLevelLabel = createDisplayLabel("DisplayLevelLabel", dataDisplayFrame)
	local displayXpLabel = createDisplayLabel("DisplayXpLabel", dataDisplayFrame)

	local closeDisplayButton = createButton("CloseDisplayButton", "Close", dataDisplayFrame)
	closeDisplayButton.Size = UDim2.new(1, 0, 0, 30)
	closeDisplayButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

	-- Confirmation Dialog UI
	local confirmationFrame = createPopupFrame("ConfirmationFrame", UDim2.new(0, 350, 0, 130), 3)

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

	local confirmYesButton = createButton("ConfirmYesButton", "Ya", confirmButtonsFrame)
	confirmYesButton.Size = UDim2.new(0.5, -5, 1, 0)
	confirmYesButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

	local confirmNoButton = createButton("ConfirmNoButton", "Tidak", confirmButtonsFrame)
	confirmNoButton.Size = UDim2.new(0.5, -5, 1, 0)
	confirmNoButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

	-- UI Logic
	local function togglePanel()
		mainFrame.Visible = not mainFrame.Visible
		if not mainFrame.Visible then
			dataDisplayFrame.Visible = false
			confirmationFrame.Visible = false
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or userIdBox:IsFocused() or levelBox:IsFocused() or xpBox:IsFocused() then return end
		if input.KeyCode == Enum.KeyCode.P then
			togglePanel()
		end
	end)

	getDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then
			statusLabel.Text = "Status: UserID tidak valid."
			return
		end

		statusLabel.Text = "Status: Meminta data..."
		local data, message = requestDataFunc:InvokeServer(targetUserId)

		if data then
			levelBox.Text = tostring(data.Level)
			xpBox.Text = tostring(data.XP)
			statusLabel.Text = "Status: Data berhasil dimuat untuk UserID " .. targetUserId
			displayUserIdLabel.Text = "UserID: " .. tostring(targetUserId)
			displayLevelLabel.Text = "Level: " .. tostring(data.Level)
			displayXpLabel.Text = "XP: " .. tostring(data.XP)
			dataDisplayFrame.Visible = true
		else
			levelBox.Text = ""
			xpBox.Text = ""
			statusLabel.Text = "Status: Gagal memuat data. Pesan: " .. (message or "Tidak ada data.")
			dataDisplayFrame.Visible = false
		end
	end)

	local function triggerConfirmation(action, id, data)
		pendingAction = action
		pendingTargetId = id
		pendingData = data

		if action == "set" then
			confirmationLabel.Text = "Apakah Anda yakin ingin mengubah data untuk UserID " .. tostring(id) .. "?"
		else
			confirmationLabel.Text = "PERINGATAN: Aksi ini akan menghapus data secara permanen. Apakah Anda yakin ingin menghapus data untuk UserID " .. tostring(id) .. "?"
		end
		confirmationFrame.Visible = true
	end

	setDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		local newLevel = tonumber(levelBox.Text)
		local newXp = tonumber(xpBox.Text)

		if not targetUserId or not newLevel or not newXp then
			statusLabel.Text = "Status: Semua kolom harus diisi dengan angka valid."
			return
		end
		triggerConfirmation("set", targetUserId, {Level = newLevel, XP = newXp})
	end)

	deleteDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then
			statusLabel.Text = "Status: UserID tidak valid."
			return
		end
		triggerConfirmation("delete", targetUserId)
	end)

	closeDisplayButton.MouseButton1Click:Connect(function()
		dataDisplayFrame.Visible = false
	end)

	local function resetConfirmationState()
		pendingAction, pendingTargetId, pendingData = nil, nil, nil
		confirmationFrame.Visible = false
	end

	confirmYesButton.MouseButton1Click:Connect(function()
		if pendingAction == "set" then
			updateDataEvent:FireServer(pendingTargetId, pendingData)
			statusLabel.Text = "Status: Permintaan perubahan data dikirim."
			dataDisplayFrame.Visible = false
		elseif pendingAction == "delete" then
			deleteDataEvent:FireServer(pendingTargetId)
			statusLabel.Text = "Status: Permintaan hapus data dikirim."
			levelBox.Text, xpBox.Text = "", ""
			dataDisplayFrame.Visible = false
		end
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
	if isAdmin then
		CreateAdminUI()
	else
		local adminGui = player.PlayerGui:FindFirstChild("AdminPanelGui")
		if adminGui then
			adminGui:Destroy()
		end
	end
end)

isAdmin = player:GetAttribute("IsAdmin")
if isAdmin then
	CreateAdminUI()
end