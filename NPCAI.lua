-- NPCAI.lua (Script)
-- Path: ServerStorage/AllyNPC/NPCAI.lua

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local rootPart = npc:WaitForChild("HumanoidRootPart")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

-- Pengaturan AI
local FOLLOW_DISTANCE = 15       -- Jarak dari pemain saat mengikuti
local ATTACK_RANGE = 80          -- Jarak NPC mulai menyerang
local FIND_TARGET_RADIUS = 100   -- Radius pencarian zombie
local WEAPON_NAME = "AK-47"      -- Senjata yang digunakan NPC

-- Variabel status
local target = nil
local ownerPlayer = nil
local weapon = nil
local weaponStats = nil
local lastFireTime = 0
local isDead = false

-- Fungsi untuk menembakkan senjata
local function fireAt(targetPart)
	if not weaponStats or not targetPart then return end

	local now = tick()
	if (now - lastFireTime) < weaponStats.FireRate then
		return -- Hormati laju tembakan
	end
	lastFireTime = now

	local origin = rootPart.Position + Vector3.new(0, 2, 0)
	local direction = (targetPart.Position - origin).Unit * 300

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {npc}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(origin, direction, raycastParams)

	if result and result.Instance then
		local hitPart = result.Instance
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")

		if hitModel and hitModel:FindFirstChild("Humanoid") and hitModel:FindFirstChild("IsZombie") then
			local targetHumanoid = hitModel:FindFirstChild("Humanoid")
			local damage = weaponStats.Damage or 20

			if hitPart.Name == "Head" then
				damage = damage * (weaponStats.HeadshotMultiplier or 2)
			end

			targetHumanoid:TakeDamage(damage)
		end
	end
end

-- Fungsi untuk mencari target zombie terdekat
local function findTarget()
	local closestTarget = nil
	local minDistance = FIND_TARGET_RADIUS

	for _, entity in ipairs(Workspace:GetChildren()) do
		if entity:FindFirstChild("Humanoid") and entity:FindFirstChild("IsZombie") and entity ~= npc then
			local targetRoot = entity:FindFirstChild("HumanoidRootPart")
			if targetRoot and entity.Humanoid.Health > 0 then
				local distance = (rootPart.Position - targetRoot.Position).Magnitude
				if distance < minDistance then
					minDistance = distance
					closestTarget = entity
				end
			end
		end
	end
	target = closestTarget
end

-- Fungsi untuk mengikuti pemain pemilik
local function followOwner()
	if not ownerPlayer or not ownerPlayer.Character then return end

	local ownerChar = ownerPlayer.Character
	local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
	if not ownerRoot then return end

	if (rootPart.Position - ownerRoot.Position).Magnitude > FOLLOW_DISTANCE then
		humanoid:MoveTo(ownerRoot.Position)
	else
		humanoid:MoveTo(rootPart.Position) -- Berhenti jika sudah dekat
	end
end

-- Fungsi untuk menyerang target
local function attackTarget()
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		target = nil
		return
	end

	local distanceToTarget = (rootPart.Position - targetRoot.Position).Magnitude

	rootPart.CFrame = CFrame.new(rootPart.Position, Vector3.new(targetRoot.Position.X, rootPart.Position.Y, targetRoot.Position.Z))

	if distanceToTarget <= ATTACK_RANGE then
		humanoid:MoveTo(rootPart.Position)
		fireAt(targetRoot)
	else
		humanoid:MoveTo(targetRoot.Position)
	end
end

-- Fungsi inisialisasi AI
local function init()
	-- [[ PERBAIKAN ]] Dapatkan UserId dari atribut.
	local ownerId = npc:GetAttribute("OwnerPlayerId")
	if ownerId then
		-- [[ PERBAIKAN ]] Cari objek Player menggunakan UserId yang didapat.
		ownerPlayer = Players:GetPlayerByUserId(ownerId)
	end

	if not ownerPlayer then
		warn("NPC tidak memiliki pemilik yang valid! Menghancurkan diri sendiri.")
		npc:Destroy()
		return
	end

	weapon = npc:FindFirstChild(WEAPON_NAME)
	if weapon and weapon:IsA("Tool") and WeaponModule.Weapons[WEAPON_NAME] then
		weaponStats = WeaponModule.Weapons[WEAPON_NAME]
		-- PERBAIKAN: Lengkapi NPC dengan senjatanya
		humanoid:EquipTool(weapon)
	else
		warn("Statistik senjata atau senjata itu sendiri tidak ditemukan untuk " .. WEAPON_NAME)
	end

	humanoid.Died:Connect(function()
		isDead = true
		print(npc.Name .. " telah mati.")
	end)

	print("AI untuk " .. npc.Name .. " telah diinisialisasi.")
end

-- Panggil inisialisasi
init()

-- Loop utama AI
while not isDead and task.wait(0.2) do
	if not ownerPlayer or not ownerPlayer.Parent or not ownerPlayer.Character then
		print(npc.Name .. " kehilangan pemiliknya, menghancurkan diri.")
		npc:Destroy()
		break
	end

	findTarget()

	if target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
		attackTarget()
	else
		target = nil
		followOwner()
	end
end
