-- GachaManager.lua (Script)
-- Path: ServerScriptService/Script/GachaManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Memuat modul yang diperlukan
local GachaModule = require(ServerScriptService.ModuleScript:WaitForChild("GachaModule"))

-- Mencari RemoteEvent untuk mengirim hasil gacha ke client
local gachaEventName = "GachaRollEvent"
local GachaRollEvent = ReplicatedStorage.RemoteEvents:FindFirstChild(gachaEventName)
if not GachaRollEvent then
	GachaRollEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
	GachaRollEvent.Name = gachaEventName
end

-- Fungsi yang akan dieksekusi saat ProximityPrompt dipicu
local function onGachaRollTriggered(player)
	-- Panggil fungsi Roll dari GachaModule
	local result = GachaModule.Roll(player)

	-- Kirim hasilnya kembali ke client yang bersangkutan
	if result then
		GachaRollEvent:FireClient(player, result)
	end
end

-- Menunggu part dan ProximityPrompt di Workspace
local gachaShopPart = Workspace:WaitForChild("GachaShopSkin")
if gachaShopPart then
	local proximityPrompt = gachaShopPart:FindFirstChildOfClass("ProximityPrompt")
	if proximityPrompt then
		-- Menghubungkan fungsi ke event Triggered dari ProximityPrompt
		proximityPrompt.Triggered:Connect(onGachaRollTriggered)
		print("GachaManager.lua successfully connected to ProximityPrompt in GachaShopSkin.")
	else
		warn("GachaManager.lua: ProximityPrompt tidak ditemukan di dalam GachaShopSkin.")
	end
else
	warn("GachaManager.lua: Part 'GachaShopSkin' tidak ditemukan di Workspace.")
end