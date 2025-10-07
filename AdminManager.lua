-- AdminManager.lua (Script)
-- Path: ServerScriptService/Script/AdminManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Memuat modul yang diperlukan
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
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

	local data = LevelManager.GetDataByUserId(targetUserId)
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

	local success, message = LevelManager.SetData(targetUserId, newData)

	if not success then
		warn("AdminService: Gagal mengubah data untuk UserID " .. targetUserId .. ". Pesan: " .. message)
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
end)

-- Memberi tahu klien apakah mereka admin atau bukan
Players.PlayerAdded:Connect(function(player)
	local isAdmin = AdminConfig.IsAdmin(player)
	if isAdmin then
		-- Menggunakan atribut untuk menandai admin di sisi klien
		player:SetAttribute("IsAdmin", true)
	end
end)
