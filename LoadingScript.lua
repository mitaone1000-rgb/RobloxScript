-- LoadingScript.lua (LocalScript)
-- ReplicatedFirst/LoadingScript.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Menghilangkan layar loading default
ReplicatedFirst:RemoveDefaultLoadingScreen()

--// Player & GUI Setup
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clone UI dan letakkan di PlayerGui
local loadingScreen = script:WaitForChild("LoadingScreen"):Clone()
loadingScreen.Parent = playerGui

-- Referensi ke elemen UI
local frame = loadingScreen:WaitForChild("Frame")
local loadingText = frame:WaitForChild("TextLabel")
local bar = frame:WaitForChild("LoadingBar"):WaitForChild("Bar")

--// Preloading Logic
-- Gunakan game:GetDescendants() untuk mengambil SEMUA objek di dalam game
local assets = game:GetDescendants()
local totalAssets = #assets

for index, asset in ipairs(assets) do
	-- Tampilkan progres di UI
	local progress = index / totalAssets
	local assetName = asset.Name

	loadingText.Text = "Memuat Aset: " .. assetName
	bar.Size = UDim2.new(progress, 0, 1, 0)

	-- Panggil PreloadAsync di dalam pcall untuk menghindari error jika aset tidak bisa dimuat
	pcall(function()
		ContentProvider:PreloadAsync({asset})
	end)

	-- Beri jeda singkat agar UI sempat diperbarui
	-- RunService.Heartbeat lebih baik daripada task.wait() untuk update per frame
	if index % 10 == 0 then
		RunService.Heartbeat:Wait()
	end
end

--// Selesai
loadingText.Text = "Selesai!"
bar.Size = UDim2.new(1, 0, 1, 0)
task.wait(2)

loadingScreen:Destroy()
