-- AdminManager.lua (Script)
-- Path: ServerScriptService/Script/AdminManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Memuat modul yang diperlukan
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local AdminConfig = require(ServerScriptService.ModuleScript:WaitForChild("AdminConfig"))

-- Membuat folder untuk event admin jika belum ada
local adminEventsFolder = ReplicatedStorage:FindFirstChild("AdminEvents")
if not adminEventsFolder then
	adminEventsFolder = Instance.new("Folder")
	adminEventsFolder.Name = "AdminEvents"
	adminEventsFolder.Parent = ReplicatedStorage
end

-- Membuat RemoteFunction dan RemoteEvent
local requestDataFunc = adminEventsFolder:FindFirstChild("AdminRequestData") or Instance.new("RemoteFunction", adminEventsFolder)
requestDataFunc.Name = "AdminRequestData"

local updateDataEvent = adminEventsFolder:FindFirstChild("AdminUpdateData") or Instance.new("RemoteEvent", adminEventsFolder)
updateDataEvent.Name = "AdminUpdateData"

local deleteDataEvent = adminEventsFolder:FindFirstChild("AdminDeleteData") or Instance.new("RemoteEvent", adminEventsFolder)
deleteDataEvent.Name = "AdminDeleteData"

-- Handler untuk mengambil data pemain
requestDataFunc.OnServerInvoke = function(player, targetUserId)
	-- Verifikasi admin
	if not AdminConfig.IsAdmin(player) then
		warn(player.Name .. " mencoba menggunakan fungsi admin tanpa izin.")
		return nil
	end

	-- Validasi input
	if type(targetUserId) ~= "number" then
		return nil, "Invalid UserID format"
	end

	local levelData = LevelManager.GetDataByUserId(targetUserId)
	local coinsData = CoinsManager.GetDataByUserId(targetUserId)

	-- Mengirim data dengan struktur yang sesuai dengan scope baru
	local data = {
		Stats = levelData,
		Inventory = coinsData,
	}

	return data
end

-- Handler untuk mengubah data pemain
updateDataEvent.OnServerEvent:Connect(function(player, targetUserId, newData)
	-- Verifikasi admin
	if not AdminConfig.IsAdmin(player) then
		warn(player.Name .. " mencoba mengubah data tanpa izin.")
		return
	end

	-- Validasi input
	if type(targetUserId) ~= "number" or type(newData) ~= "table" then
		warn("AdminService: Permintaan update data tidak valid dari " .. player.Name)
		return
	end

	-- Proses pembaruan data Level (sekarang menggunakan scope "Stats")
	if newData.Stats then
		local success, message = LevelManager.SetData(targetUserId, newData.Stats)
		if not success then
			warn("AdminService: Gagal mengubah data Level untuk UserID " .. targetUserId .. ". Pesan: " .. message)
		end
	end

	-- Proses pembaruan data Koin (sekarang menggunakan scope "Inventory" dan mengekstrak nilai)
	if newData.Inventory and newData.Inventory.Coins ~= nil then
		local success, message = CoinsManager.SetDataByUserId(targetUserId, newData.Inventory.Coins)
		if not success then
			warn("AdminService: Gagal mengubah data Koin untuk UserID " .. targetUserId .. ". Pesan: " .. message)
		end
	end
end)

-- Handler untuk menghapus data pemain
deleteDataEvent.OnServerEvent:Connect(function(player, targetUserId)
	-- Verifikasi admin
	if not AdminConfig.IsAdmin(player) then
		warn(player.Name .. " mencoba menghapus data tanpa izin.")
		return
	end

	-- Validasi input
	if type(targetUserId) ~= "number" then
		warn("AdminService: Permintaan hapus data tidak valid dari " .. player.Name)
		return
	end

	LevelManager.DeleteData(targetUserId)
	CoinsManager.RemoveDataByUserId(targetUserId)
end)

-- Memberi tahu klien apakah mereka admin atau bukan
Players.PlayerAdded:Connect(function(player)
	local isAdmin = AdminConfig.IsAdmin(player)
	if isAdmin then
		-- Menggunakan atribut untuk menandai admin di sisi klien
		player:SetAttribute("IsAdmin", true)
	end
end)
