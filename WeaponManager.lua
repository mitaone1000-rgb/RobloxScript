-- WeaponManager.lua (Script)
-- Path: ServerScriptService/Script/WeaponManager.lua
-- Script Place: ACT 1: Village

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))

local ShootEvent = RemoteEvents:WaitForChild("ShootEvent")
local ReloadEvent = RemoteEvents:WaitForChild("ReloadEvent")
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")
local HitmarkerEvent = RemoteEvents:WaitForChild("HitmarkerEvent")
local BulletholeEvent = RemoteEvents:WaitForChild("BulletholeEvent")
local DamageDisplayEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("DamageDisplayEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
DamageDisplayEvent.Name = "DamageDisplayEvent"

-- Anti-spam tembak: catat waktu tembak terakhir per-player per-senjata
local lastFireTime = {}

local playerAmmo = {}
local playerReserveAmmo = {}

local function ensureToolHasId(tool)
	if not tool then return nil end
	if not tool:GetAttribute("WeaponId") then
		tool:SetAttribute("WeaponId", HttpService:GenerateGUID(false))
	end
	return tool:GetAttribute("WeaponId")
end

local function setupToolAmmoForPlayer(player, tool)
	if not tool or not tool:IsA("Tool") then return end
	local weaponName = tool.Name
	if not WeaponModule.Weapons[weaponName] then return end
	local id = ensureToolHasId(tool)
	if not id then return end
	playerAmmo[player] = playerAmmo[player] or {}
	playerReserveAmmo[player] = playerReserveAmmo[player] or {}

	local weaponStats = WeaponModule.Weapons[weaponName]
	local defaultMax = weaponStats and weaponStats.MaxAmmo or 0
	local defaultReserve = weaponStats and weaponStats.ReserveAmmo or 0

	local customMax = tool:GetAttribute("CustomMaxAmmo")
	local customReserve = tool:GetAttribute("CustomReserveAmmo")

	local initMax = customMax or defaultMax
	local initReserve = customReserve or defaultReserve

	if playerAmmo[player][id] == nil then
		playerAmmo[player][id] = initMax
		playerReserveAmmo[player][id] = initReserve
	end

	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)

	if not tool:GetAttribute("_AmmoListenerAttached") then
		tool:SetAttribute("_AmmoListenerAttached", true)
		tool.AttributeChanged:Connect(function(attr)
			if attr == "CustomMaxAmmo" or attr == "CustomReserveAmmo" then
				local newMax = tool:GetAttribute("CustomMaxAmmo") or (weaponStats and weaponStats.MaxAmmo) or 0
				local newReserve = tool:GetAttribute("CustomReserveAmmo") or (weaponStats and weaponStats.ReserveAmmo) or 0

				playerAmmo[player] = playerAmmo[player] or {}
				playerReserveAmmo[player] = playerReserveAmmo[player] or {}

				playerAmmo[player][id] = newMax
				playerReserveAmmo[player][id] = newReserve

				AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)
			end
		end)
	end
end

ShootEvent.OnServerEvent:Connect(function(player, tool, hitPosition, isAiming)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	if not tool or not tool:IsA("Tool") then return end
	if not player.Character or not tool:IsDescendantOf(player.Character) then
		return
	end

	-- NEW: Cek jika player sedang knock
	if char:FindFirstChild("Knocked") then
		return
	end

	local weaponName = tool.Name
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local id = ensureToolHasId(tool)
	playerAmmo[player] = playerAmmo[player] or {}
	playerReserveAmmo[player] = playerReserveAmmo[player] or {}
	if playerAmmo[player][id] == nil then
		playerAmmo[player][id] = weaponStats.MaxAmmo
		playerReserveAmmo[player][id] = weaponStats.ReserveAmmo
	end

	-- ===== Server-side fire-rate gate =====
	-- Jangan izinkan menembak kalau masih dalam jeda fire rate atau sedang reload
	if player.Character and player.Character:GetAttribute("IsReloading") then
		return
	end

	lastFireTime[player] = lastFireTime[player] or {}

	local now = tick()
	local cooldown = weaponStats.FireRate
	-- Hormati buff RateBoost jika ada (sesuai logika client)
	if player.Character and player.Character:GetAttribute("RateBoost") then
		cooldown = cooldown * 0.7
	end

	local last = lastFireTime[player][id] or 0
	if (now - last) < cooldown then
		-- Belum waktunya nembak lagi → tolak
		return
	end

	-- Lewat gate: set timestamp tembakan
	lastFireTime[player][id] = now
	-- ===== End gate =====

	if playerAmmo[player][id] <= 0 then
		return
	end

	playerAmmo[player][id] = playerAmmo[player][id] - 1
	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)

	local origin = char.Head.Position
	local direction = (hitPosition - origin).Unit * 300
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}
	-- Abaikan semua instance drop di workspace (nama diawali "Drop_")
	for _, child in ipairs(workspace:GetChildren()) do
		if typeof(child.Name) == "string" and string.sub(child.Name, 1, 5) == "Drop_" then
			table.insert(raycastParams.FilterDescendantsInstances, child)
		end
	end
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local hasHeadshot = false
	local hasBodyshot = false

	if weaponStats.Pellets then
		local spread = isAiming and weaponStats.ADS_Spread or weaponStats.Spread
		for i = 1, weaponStats.Pellets do
			local pelletOffset = Vector3.new(
				math.random(-100, 100) / 100 * spread,
				math.random(-100, 100) / 100 * spread,
				math.random(-100, 100) / 100 * spread
			)
			local pelletDir = (hitPosition + pelletOffset - origin).Unit * 300
			local res = workspace:Raycast(origin, pelletDir, raycastParams)

			if res and res.Instance then
				local hitPart = res.Instance
				local hitModel = hitPart:FindFirstAncestorOfClass("Model")
				-- hanya buat bullethole kalau yang kena bukan zombie
				local isZombie = hitModel and hitModel:FindFirstChild("IsZombie")
				if not isZombie then
					BulletholeEvent:FireClient(player, res.Position, res.Normal)
				end

				if hitModel and hitModel:FindFirstChild("Humanoid") then
					local targetHumanoid = hitModel:FindFirstChild("Humanoid")
					local immune = (hitModel:GetAttribute("Immune") == true)
					local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
					local base = weaponStats.Damage or 0
					local cfg = weaponStats.UpgradeConfig
					local damage = base
					if cfg then
						damage = base + (cfg.DamagePerLevel * instanceLevel)
					end
					local isHeadshotPellet = false

					if hitModel:FindFirstChild("IsZombie") and targetHumanoid.Health > 0 then
						if hitPart.Name == "Head" or hitPart.Parent and hitPart.Parent.Name == "Head" then
							damage *= weaponStats.HeadshotMultiplier
							isHeadshotPellet = true
							if not immune then hasHeadshot = true end
						else
							if not immune then hasBodyshot = true end
						end
					end

					local finalDamage = damage
					if hitModel:FindFirstChild("IsZombie") then
						finalDamage = ElementModule.OnPlayerHit(player, hitModel, damage) or damage
						-- TAMBAHKAN BLOK INI untuk memeriksa imunitas dan DR
						if immune then
							finalDamage = 0
						else
							local dr = hitModel:GetAttribute("DamageReductionPct") or 0
							finalDamage = finalDamage * (1 - math.clamp(dr, 0, 0.95))
						end					
					end
					targetHumanoid:TakeDamage(finalDamage)
					if finalDamage > 0 and hitModel:FindFirstChild("IsZombie") then
						PointsSystem.AddDamage(player, finalDamage)
						DamageDisplayEvent:FireAllClients(finalDamage, hitModel, isHeadshotPellet)
					end
					local creatorTag = hitModel:FindFirstChild("creator")
					if not creatorTag then
						creatorTag = Instance.new("ObjectValue")
						creatorTag.Name = "creator"
						creatorTag.Parent = hitModel
					end
					creatorTag.Value = player
				end
			end
		end

		if hasHeadshot then
			PointsSystem.AddPoints(player, 20)
			print(player.Name .. " mendapatkan 20 poin (Headshot)!")
			HitmarkerEvent:FireClient(player, true)
		elseif hasBodyshot then
			PointsSystem.AddPoints(player, 10)
			print(player.Name .. " mendapatkan 10 poin (Body Shot)!")
			HitmarkerEvent:FireClient(player, false)
		end
	else
		local spread = isAiming and weaponStats.ADS_Spread or weaponStats.Spread
		local randomOffset = Vector3.new(
			math.random(-100, 100) / 100 * spread,
			math.random(-100, 100) / 100 * spread,
			math.random(-100, 100) / 100 * spread
		)
		direction = (hitPosition + randomOffset - origin).Unit * 300

		local result = workspace:Raycast(origin, direction, raycastParams)

		if result and result.Instance then
			local hitPart = result.Instance
			local hitModel = hitPart:FindFirstAncestorOfClass("Model")
			-- hanya buat bullethole kalau yang kena bukan zombie
			local isZombie = hitModel and hitModel:FindFirstChild("IsZombie")
			if not isZombie then
				BulletholeEvent:FireClient(player, result.Position, result.Normal)
			end

			if hitModel and hitModel:FindFirstChild("Humanoid") then
				local targetHumanoid = hitModel:FindFirstChild("Humanoid")
				local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
				local base = weaponStats.Damage or 0
				local cfg = weaponStats.UpgradeConfig
				local damage = base
				if cfg then
					damage = base + (cfg.DamagePerLevel * instanceLevel)
				end
				local isHeadshot = false

				if hitModel:FindFirstChild("IsZombie") and targetHumanoid.Health > 0 then

					if hitPart.Name == "Head" or hitPart.Parent and hitPart.Parent.Name == "Head" then
						damage *= weaponStats.HeadshotMultiplier
						if not hitModel:GetAttribute("Immune") then
							PointsSystem.AddPoints(player, 20)
						end
						isHeadshot = true
						print(player.Name .. " mendapatkan 20 poin (Headshot)!")
					else
						if not hitModel:GetAttribute("Immune") then
							PointsSystem.AddPoints(player, 10)
						end
						print(player.Name .. " mendapatkan 10 poin (Body Shot)!")
					end
				end

				HitmarkerEvent:FireClient(player, isHeadshot)
				local finalDamage = damage
				if hitModel:FindFirstChild("IsZombie") then
					finalDamage = ElementModule.OnPlayerHit(player, hitModel, damage) or damage
					-- Boss/Zombie attribute-based mitigation
					if hitModel:FindFirstChild("IsZombie") then
						if hitModel:GetAttribute("Immune") then
							finalDamage = 0
						else
							local dr = hitModel:GetAttribute("DamageReductionPct") or 0
							finalDamage = finalDamage * (1 - math.clamp(dr, 0, 0.95))
						end
					end
				end
				targetHumanoid:TakeDamage(finalDamage)
				if finalDamage > 0 and hitModel:FindFirstChild("IsZombie") then
					PointsSystem.AddDamage(player, finalDamage)
					DamageDisplayEvent:FireAllClients(finalDamage, hitModel, isHeadshot)
				end
				local creatorTag = hitModel:FindFirstChild("creator")
				if not creatorTag then
					creatorTag = Instance.new("ObjectValue")
					creatorTag.Name = "creator"
					creatorTag.Parent = hitModel
				end
				creatorTag.Value = player
			end
		end
	end
end)

ReloadEvent.OnServerEvent:Connect(function(player, tool)
	-- HARD GUARD: cegah spam reload (double-tap/berkali-kali)
	if player.Character then
		-- kalau sudah sedang reload ATAU ada lock aktif, tolak segera
		if player.Character:GetAttribute("IsReloading") or player.Character:GetAttribute("_ReloadLock") then
			return
		end
		-- pasang lock sedini mungkin untuk menutup race condition
		player.Character:SetAttribute("_ReloadLock", true)
	end
	if not tool or not tool:IsA("Tool") then return end
	if not player.Character or not tool:IsDescendantOf(player.Character) then return end

	-- NEW: Cek jika player sedang knock
	if player.Character:FindFirstChild("Knocked") then
		return
	end

	local weaponName = tool.Name
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local id = ensureToolHasId(tool)
	local currentAmmo = (playerAmmo[player] and playerAmmo[player][id]) or weaponStats.MaxAmmo
	local reserveAmmo = (playerReserveAmmo[player] and playerReserveAmmo[player][id]) or weaponStats.ReserveAmmo
	local maxAmmo = tool:GetAttribute("CustomMaxAmmo") or weaponStats.MaxAmmo

	local ammoNeeded = maxAmmo - currentAmmo
	local ammoToReload = math.min(ammoNeeded, reserveAmmo)

	if ammoToReload > 0 then
		-- Tandai RELOADING seawal mungkin (lock sudah terpasang di atas)
		if player.Character then
			player.Character:SetAttribute("IsReloading", true)
		end
		-- Cek perk ReloadPlus
		-- Tandai karakter sedang reload (atribut global & konsisten untuk semua senjata)
		if player.Character then
			player.Character:SetAttribute("IsReloading", true)
		end

		local reloadTime = weaponStats.ReloadTime
		if player.Character and player.Character:GetAttribute("ReloadBoost") then
			reloadTime = reloadTime * 0.7 -- 30% faster
		end

		for i = 1, 20 do
			if not tool.Parent or not player.Character or not tool:IsDescendantOf(player.Character) then
				break
			end
			local progress = i / 20
			local reloadPercentage = math.floor(progress * 100)
			AmmoUpdateEvent:FireClient(player, weaponName, reloadPercentage, 0, true, true)
			task.wait(reloadTime / 20)
		end

		if tool.Parent and player.Character and tool:IsDescendantOf(player.Character) then
			playerAmmo[player][id] = currentAmmo + ammoToReload
			playerReserveAmmo[player][id] = reserveAmmo - ammoToReload
		else
			-- Tidak ada peluru untuk di-reload → bebaskan lock bila ada
			if player.Character then
				player.Character:SetAttribute("_ReloadLock", false)
			end
		end
	end
	-- Selesai reload → hapus tanda reload
	if player.Character then
		player.Character:SetAttribute("IsReloading", false)
		-- Bersihkan lock setelah reload beres
		player.Character:SetAttribute("_ReloadLock", false)
	end
	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true, false)
end)

game.Players.PlayerAdded:Connect(function(player)
	playerAmmo[player] = {}
	playerReserveAmmo[player] = {}
	player.CharacterAdded:Connect(function(char)
		for _, v in pairs(char:GetChildren()) do
			if v:IsA("Tool") then
				setupToolAmmoForPlayer(player, v)
			end
		end
		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				setupToolAmmoForPlayer(player, child)
			end
		end)
	end)

	local backpack = player:WaitForChild("Backpack")
	for _, v in pairs(backpack:GetChildren()) do
		if v:IsA("Tool") then
			setupToolAmmoForPlayer(player, v)
		end
	end
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.02)
			setupToolAmmoForPlayer(player, child)
		end
	end)

	PointsSystem.SetupPlayer(player)
	-- Bersihkan state saat player keluar
	game.Players.PlayerRemoving:Connect(function(plr)
		playerAmmo[plr] = nil
		playerReserveAmmo[plr] = nil
		lastFireTime[plr] = nil
	end)
end)
