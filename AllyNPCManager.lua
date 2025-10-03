-- AllyNPCManager.lua (Script)
-- Path: ServerScriptService/Script/AllyNPCManager.lua

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Cari model, senjata, dan titik spawn. Tampilkan error jika tidak ditemukan.
local allyNpcModel = ServerStorage:FindFirstChild("AllyNPC")
if not allyNpcModel then
	error("KRITIS: Model 'AllyNPC' tidak ditemukan di ServerStorage! Pastikan model NPC ada di sana.")
end

-- Diasumsikan skrip AI sudah ada di dalam model 'AllyNPC'.
if not allyNpcModel:FindFirstChild("NPCAI") then
	warn("PERINGATAN: Skrip 'NPCAI' tidak ditemukan di dalam model 'AllyNPC' di ServerStorage. NPC tidak akan memiliki AI.")
end

-- Prioritaskan ReplicatedStorage untuk Tool, karena ini adalah praktik umum.
local weaponToGive = ReplicatedStorage:FindFirstChild("AK-47")
if not weaponToGive then
	weaponToGive = ServerStorage.Weapons:FindFirstChild("AK-47") -- Fallback ke ServerStorage
	if not weaponToGive then
		error("KRITIS: Senjata 'AK-47' tidak ditemukan di ReplicatedStorage atau ServerStorage!")
	end
end

local spawnPart = Workspace:FindFirstChild("SpawnNPC")
if not spawnPart then
	error("KRITIS: Part 'SpawnNPC' tidak ditemukan di Workspace!")
end

local function spawnAllyForPlayer(player)
	if not player or not player.Parent then
		return
	end

	-- Kloning model NPC (yang seharusnya sudah berisi skrip AI)
	local newNpc = allyNpcModel:Clone()
	newNpc.Name = player.Name .. "sAlly"

	-- [[ PERBAIKAN ]] Simpan UserId pemain (angka), bukan objek Player secara langsung.
	newNpc:SetAttribute("OwnerPlayerId", player.UserId)

	-- Posisikan NPC
	local humanoidRootPart = newNpc:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CFrame = spawnPart.CFrame
	else
		warn("Peringatan: 'HumanoidRootPart' tidak ditemukan di 'AllyNPC'. NPC tidak dapat diposisikan.")
		newNpc:Destroy()
		return
	end

	-- Berikan senjata
	local newWeapon = weaponToGive:Clone()
	newWeapon.Parent = newNpc

	-- Aktifkan skrip AI yang sudah ada di dalam model
	local aiScript = newNpc:FindFirstChild("NPCAI")
	if aiScript and aiScript:IsA("Script") then
		aiScript.Enabled = true
	end

	-- Tempatkan NPC di Workspace
	newNpc.Parent = Workspace

	print("AllyNPC dengan AI bawaan berhasil dibuat untuk pemain: " .. player.Name)
end

Players.PlayerAdded:Connect(function(player)
	-- Fungsi untuk memunculkan ally, dipanggil saat karakter ditambahkan atau jika sudah ada.
	local function trySpawnAlly(character)
		-- Hanya spawn jika belum ada ally untuk pemain ini
		if not Workspace:FindFirstChild(player.Name .. "sAlly") then
			spawnAllyForPlayer(player)
		end
	end

	if player.Character then
		trySpawnAlly(player.Character)
	end

	player.CharacterAdded:Connect(trySpawnAlly)
end)