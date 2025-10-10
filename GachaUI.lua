-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Tunggu RemoteEvent
local GachaRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaRollEvent")

-- ================== PEMBUATAN UI ==================
-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GachaSkinGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Buat Frame Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
mainFrame.BorderSizePixel = 2
mainFrame.Visible = false -- Sembunyikan secara default
mainFrame.Parent = screenGui

-- Buat Judul
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Text = "Gacha Skin"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 30
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.Parent = mainFrame

-- Buat Tombol Roll
local rollButton = Instance.new("TextButton")
rollButton.Name = "RollButton"
rollButton.Size = UDim2.new(0, 200, 0, 50)
rollButton.Position = UDim2.new(0.5, -100, 0.6, 0)
rollButton.Text = "Roll (100 BloodCoins)"
rollButton.Font = Enum.Font.SourceSansBold
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.TextSize = 24
rollButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
rollButton.Parent = mainFrame

-- Buat Tombol Tutup
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeButton.Parent = mainFrame

-- Buat Frame Hasil
local resultFrame = Instance.new("Frame")
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(1, 0, 1, 0)
resultFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
resultFrame.BackgroundTransparency = 0.3
resultFrame.Visible = false
resultFrame.Parent = mainFrame

local resultText = Instance.new("TextLabel")
resultText.Name = "ResultText"
resultText.Size = UDim2.new(0.8, 0, 0.4, 0)
resultText.Position = UDim2.new(0.1, 0, 0.2, 0)
resultText.Text = "Selamat!\nAnda mendapatkan:\n[Hadiah]"
resultText.Font = Enum.Font.SourceSansBold
resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
resultText.TextSize = 26
resultText.TextWrapped = true
resultText.Parent = resultFrame

local resultCloseButton = Instance.new("TextButton")
resultCloseButton.Name = "ResultCloseButton"
resultCloseButton.Size = UDim2.new(0, 150, 0, 40)
resultCloseButton.Position = UDim2.new(0.5, -75, 0.7, 0)
resultCloseButton.Text = "OK"
resultCloseButton.Font = Enum.Font.SourceSansBold
resultCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resultCloseButton.TextSize = 22
resultCloseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
resultCloseButton.Parent = resultFrame


-- ================== LOGIKA SCRIPT ==================

-- Fungsi untuk menampilkan hasil
local function showResult(resultData)
	if resultData.Success then
		local prize = resultData.Prize
		if prize.Type == "Skin" then
			resultText.Text = string.format("Selamat!\nAnda mendapatkan Skin:\n%s (%s)", prize.SkinName, prize.WeaponName)
		elseif prize.Type == "Coins" then
			resultText.Text = string.format("Anda mendapatkan:\n%d BloodCoins", prize.Amount)
		end
	else
		resultText.Text = "Gagal!\n" .. (resultData.Message or "Terjadi kesalahan.")
	end
	resultFrame.Visible = true
	rollButton.Visible = false -- Sembunyikan tombol roll saat hasil ditampilkan
end

-- Fungsi untuk membuka/menutup UI Gacha
local function toggleGachaUI(visible)
	mainFrame.Visible = visible
end

-- Event listener untuk ProximityPrompt
local gachaShopPart = Workspace:WaitForChild("GachaShopSkin")
local proximityPrompt = gachaShopPart:WaitForChild("ProximityPrompt")

proximityPrompt.Triggered:Connect(function()
	toggleGachaUI(true)
end)

-- Event listener untuk tombol tutup
closeButton.MouseButton1Click:Connect(function()
	toggleGachaUI(false)
end)

-- Event listener untuk tombol roll
rollButton.MouseButton1Click:Connect(function()
	-- Kirim event ke server untuk memulai roll
	GachaRollEvent:FireServer()
end)

-- Event listener untuk menerima hasil dari server
GachaRollEvent.OnClientEvent:Connect(function(result)
	showResult(result)
end)

-- Event listener untuk tombol tutup pada frame hasil
resultCloseButton.MouseButton1Click:Connect(function()
	resultFrame.Visible = false
	rollButton.Visible = true -- Tampilkan kembali tombol roll
end)

print("GachaUI.lua loaded for player.")
