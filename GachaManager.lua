-- GachaManager.lua (Script)
-- Path: ServerScriptService/Script/GachaManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Memuat modul yang diperlukan
local GachaModule = require(ServerScriptService.ModuleScript:WaitForChild("GachaModule"))
local GachaConfig = require(ServerScriptService.ModuleScript:WaitForChild("GachaConfig"))

-- Mencari RemoteFunction untuk mengambil konfigurasi
local getConfigFuncName = "GetGachaConfig"
local GetGachaConfig = ReplicatedStorage.RemoteFunctions:FindFirstChild(getConfigFuncName)
if not GetGachaConfig then
	GetGachaConfig = Instance.new("RemoteFunction", ReplicatedStorage.RemoteFunctions)
	GetGachaConfig.Name = getConfigFuncName
end

-- Atur callback untuk RemoteFunction
GetGachaConfig.OnServerInvoke = function(player)
	-- Hanya kirim data yang aman untuk dilihat klien
	return GachaConfig.RARITY_CHANCES
end

-- Mencari RemoteEvent untuk komunikasi gacha
local gachaEventName = "GachaRollEvent"
local GachaRollEvent = ReplicatedStorage.RemoteEvents:FindFirstChild(gachaEventName)
if not GachaRollEvent then
	GachaRollEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaRollEvent.Name = gachaEventName
end

-- Fungsi ini akan dieksekusi ketika client mengirim permintaan roll dari UI
local function onGachaRollRequested(player)
	-- Panggil fungsi Roll dari GachaModule secara aman menggunakan pcall
	local success, resultOrError = pcall(GachaModule.Roll, player)

	if success then
		-- Jika pcall berhasil, 'resultOrError' berisi hasil dari GachaModule.Roll
		GachaRollEvent:FireClient(player, resultOrError)
	else
		-- Jika pcall gagal, 'resultOrError' berisi pesan error.
		-- Ini mencegah server crash dan memastikan klien selalu mendapat respons.
		warn("GachaManager Error: Terjadi error saat menjalankan GachaModule.Roll - " .. tostring(resultOrError))

		-- Kirim pesan error yang jelas ke klien
		local errorResult = {
			Success = false,
			Message = "Terjadi kesalahan internal pada server. Silakan coba lagi nanti."
		}
		GachaRollEvent:FireClient(player, errorResult)
	end
end

-- [PERUBAHAN KUNCI] Ganti listener dari ProximityPrompt ke OnServerEvent
GachaRollEvent.OnServerEvent:Connect(onGachaRollRequested)

-- Hapus koneksi ke ProximityPrompt dari sisi server
-- Kode di bawah ini tidak lagi diperlukan dan telah dihapus.
-- local gachaShopPart = Workspace:WaitForChild("GachaShopSkin")
-- ... proximityPrompt.Triggered:Connect(...)

print("GachaManager.lua now correctly listening to GachaRollEvent from the client.")
