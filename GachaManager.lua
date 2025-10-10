-- GachaManager.lua (Script)
-- Path: ServerScriptService/GachaManager.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Memuat modul yang diperlukan
local GachaModule = require(ServerScriptService.ModuleScript:WaitForChild("GachaModule"))

-- Membuat atau mencari RemoteEvent
local gachaEventName = "GachaRollEvent"
local GachaRollEvent = ReplicatedStorage.RemoteEvents:FindFirstChild(gachaEventName)
if not GachaRollEvent then
	GachaRollEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaRollEvent.Name = gachaEventName
end

-- Fungsi yang akan dieksekusi saat client memanggil event
local function onGachaRollRequested(player)
	-- Panggil fungsi Roll dari GachaModule
	local result = GachaModule.Roll(player)

	-- Kirim hasilnya kembali ke client yang bersangkutan
	GachaRollEvent:FireClient(player, result)
end

-- Menghubungkan fungsi ke event OnServerEvent
GachaRollEvent.OnServerEvent:Connect(onGachaRollRequested)

print("GachaManager.lua loaded and listening for GachaRollEvent.")