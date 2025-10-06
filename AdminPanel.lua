-- AdminPanel.lua (LocalScript)
-- LOKASI: StarterGui
-- FUNGSI: Membuat UI Panel Admin dan menangani semua logika di sisi klien.

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Player and Admin Check
local player = Players.LocalPlayer
local isAdmin = false -- Default ke false

-- Fungsi untuk membuat UI
local function CreateAdminUI()
	-- Hapus UI lama jika ada (untuk kasus respawn atau duplikasi)
	local oldGui = player.PlayerGui:FindFirstChild("AdminPanelGui")
	if oldGui then
		oldGui:Destroy()
	end

	-- Remote Events/Functions
	local adminEventsFolder = ReplicatedStorage:WaitForChild("AdminEvents")
	local requestDataFunc = adminEventsFolder:WaitForChild("AdminRequestData")
	local updateDataEvent = adminEventsFolder:WaitForChild("AdminUpdateData")
	local deleteDataEvent = adminEventsFolder:WaitForChild("AdminDeleteData")

	-- UI Creation
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanelGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 250)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
	mainFrame.Visible = false -- Mulai dengan tersembunyi
	mainFrame.Draggable = true
	mainFrame.Active = true
	mainFrame.Parent = screenGui

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Text = "Admin Panel (Tekan 'P' untuk Buka/Tutup)"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	titleLabel.Parent = mainFrame

	-- UserID Input
	local userIdBox = Instance.new("TextBox")
	userIdBox.Name = "UserIdBox"
	userIdBox.Size = UDim2.new(1, -20, 0, 30)
	userIdBox.Position = UDim2.new(0.5, 0, 0, 40)
	userIdBox.AnchorPoint = Vector2.new(0.5, 0)
	userIdBox.PlaceholderText = "Masukkan UserID Target..."
	userIdBox.Text = ""
	userIdBox.Parent = mainFrame

	-- Level Input
	local levelBox = Instance.new("TextBox")
	levelBox.Name = "LevelBox"
	levelBox.Size = UDim2.new(0.5, -15, 0, 30)
	levelBox.Position = UDim2.new(0, 10, 0, 80)
	levelBox.PlaceholderText = "Level..."
	levelBox.Text = ""
	levelBox.Parent = mainFrame

	-- XP Input
	local xpBox = Instance.new("TextBox")
	xpBox.Name = "XpBox"
	xpBox.Size = UDim2.new(0.5, -15, 0, 30)
	xpBox.Position = UDim2.new(0.5, 5, 0, 80)
	xpBox.PlaceholderText = "XP..."
	xpBox.Text = ""
	xpBox.Parent = mainFrame

	-- Buttons Frame
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Name = "ButtonsFrame"
	buttonsFrame.Size = UDim2.new(1, -20, 0, 40)
	buttonsFrame.Position = UDim2.new(0.5, 0, 0, 120)
	buttonsFrame.AnchorPoint = Vector2.new(0.5, 0)
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.Parent = mainFrame

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 10)
	uiListLayout.Parent = buttonsFrame

	-- Buttons
	local getDataButton = Instance.new("TextButton")
	getDataButton.Name = "GetDataButton"
	getDataButton.Size = UDim2.new(0.3, 0, 1, 0)
	getDataButton.Text = "Get Data"
	getDataButton.LayoutOrder = 1
	getDataButton.Parent = buttonsFrame

	local setDataButton = Instance.new("TextButton")
	setDataButton.Name = "SetDataButton"
	setDataButton.Size = UDim2.new(0.3, 0, 1, 0)
	setDataButton.Text = "Set Data"
	setDataButton.LayoutOrder = 2
	setDataButton.Parent = buttonsFrame

	local deleteDataButton = Instance.new("TextButton")
	deleteDataButton.Name = "DeleteDataButton"
	deleteDataButton.Size = UDim2.new(0.3, 0, 1, 0)
	deleteDataButton.Text = "Delete Data"
	deleteDataButton.LayoutOrder = 3
	deleteDataButton.Parent = buttonsFrame

	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -20, 0, 50)
	statusLabel.Position = UDim2.new(0.5, 0, 1, -10)
	statusLabel.AnchorPoint = Vector2.new(0.5, 1)
	statusLabel.Text = "Status: Idle"
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = mainFrame

	-- UI Logic
	local function togglePanel()
		mainFrame.Visible = not mainFrame.Visible
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or userIdBox:IsFocused() or levelBox:IsFocused() or xpBox:IsFocused() then return end
		if input.KeyCode == Enum.KeyCode.P then
			togglePanel()
		end
	end)

	-- Button Functions
	getDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then
			statusLabel.Text = "Status: UserID tidak valid. Harap masukkan angka."
			return
		end

		statusLabel.Text = "Status: Meminta data..."
		local data, message = requestDataFunc:InvokeServer(targetUserId)

		if data then
			levelBox.Text = tostring(data.Level)
			xpBox.Text = tostring(data.XP)
			statusLabel.Text = "Status: Data berhasil dimuat untuk UserID " .. targetUserId
		else
			levelBox.Text = ""
			xpBox.Text = ""
			statusLabel.Text = "Status: Gagal memuat data. Pesan: " .. (message or "Tidak ada data atau error.")
		end
	end)

	setDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		local newLevel = tonumber(levelBox.Text)
		local newXp = tonumber(xpBox.Text)

		if not targetUserId or not newLevel or not newXp then
			statusLabel.Text = "Status: Semua kolom (UserID, Level, XP) harus diisi dengan angka yang valid."
			return
		end

		local newData = {
			Level = newLevel,
			XP = newXp,
		}

		updateDataEvent:FireServer(targetUserId, newData)
		statusLabel.Text = "Status: Permintaan perubahan data dikirim untuk UserID " .. targetUserId
	end)

	deleteDataButton.MouseButton1Click:Connect(function()
		local targetUserId = tonumber(userIdBox.Text)
		if not targetUserId then
			statusLabel.Text = "Status: UserID tidak valid."
			return
		end

		deleteDataEvent:FireServer(targetUserId)
		statusLabel.Text = "Status: Permintaan hapus data dikirim untuk UserID " .. targetUserId
		levelBox.Text = ""
		xpBox.Text = ""
	end)
end

-- Main Logic
-- Cek status admin saat pemain bergabung atau saat atribut berubah
isAdmin = player:GetAttribute("IsAdmin")
if isAdmin then
	CreateAdminUI()
end

player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
	isAdmin = player:GetAttribute("IsAdmin")
	if isAdmin then
		CreateAdminUI()
	else
		-- Jika status admin dicabut, hancurkan UI
		local adminGui = player.PlayerGui:FindFirstChild("AdminPanelGui")
		if adminGui then
			adminGui:Destroy()
		end
	end
end)