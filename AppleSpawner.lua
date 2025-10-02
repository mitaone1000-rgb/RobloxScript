-- AppleSpawner.lua (Server)
-- Letakkan di ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- CONFIG
local APPLE_HEAL = 20            -- nilai heal
local RESPAWN_TIME = 15          -- detik sebelum apple respawn
local INITIAL_COUNT = 8
local MIN_APPLES = 6

-- Ganti ini dengan assetmu: "rbxassetid://12345678"
local EAT_ANIM_ID = "rbxassetid://12345678"
local EAT_SOUND_ID = "rbxassetid://12345678"

-- Create / get folders & remote event
local applesFolder = Workspace:FindFirstChild("Apples")
if not applesFolder then
	applesFolder = Instance.new("Folder")
	applesFolder.Name = "Apples"
	applesFolder.Parent = Workspace
end

local template = ReplicatedStorage:FindFirstChild("AppleTemplate")
if not template then
	template = Instance.new("Model")
	template.Name = "AppleTemplate"

	local applePart = Instance.new("Part")
	applePart.Name = "Apple"
	applePart.Size = Vector3.new(1, 1, 1)
	applePart.Shape = Enum.PartType.Ball
	applePart.Anchored = true
	applePart.CanCollide = false
	applePart.Material = Enum.Material.SmoothPlastic
	applePart.Color = Color3.fromRGB(227, 38, 54)
	applePart.Parent = template

	-- stem visual
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.15, 0.4, 0.15)
	stem.Shape = Enum.PartType.Cylinder
	stem.Anchored = true
	stem.CanCollide = false
	stem.Material = Enum.Material.SmoothPlastic
	stem.Color = Color3.fromRGB(101, 67, 33)
	stem.Parent = template

	template.PrimaryPart = applePart
	template.Parent = ReplicatedStorage
end

local remoteName = "AppleEatEvent"
local appleEvent = ReplicatedStorage:FindFirstChild(remoteName)
if not appleEvent then
	appleEvent = Instance.new("RemoteEvent")
	appleEvent.Name = remoteName
	appleEvent.Parent = ReplicatedStorage
end

-- Spawn area: gunakan Part bernama "SpawnArea" di Workspace kalau ada
local spawnPart = Workspace:FindFirstChild("SpawnArea")
local function randomPosition()
	if spawnPart and spawnPart:IsA("BasePart") then
		local pos = spawnPart.Position
		local size = spawnPart.Size
		local x = pos.X + (math.random() - 0.5) * size.X
		local y = pos.Y + (math.random() - 0.5) * size.Y
		local z = pos.Z + (math.random() - 0.5) * size.Z
		return Vector3.new(x, y + 0.5, z) -- sedikit naik supaya bagian tidak tertanam
	else
		-- fallback: area default
		local center = Vector3.new(0, 5, 0)
		local s = Vector3.new(50, 10, 50)
		return Vector3.new(center.X + (math.random()-0.5)*s.X,
			center.Y + (math.random()-0.5)*s.Y,
			center.Z + (math.random()-0.5)*s.Z)
	end
end

-- Spawn single apple function
local function spawnApple(position)
	local clone = template:Clone()
	clone.Name = "Apple_" .. tostring(tick()):gsub("%.", "")
	local applePart = clone:FindFirstChild("Apple")
	local stem = clone:FindFirstChild("Stem")

	if not clone.PrimaryPart and applePart then
		clone.PrimaryPart = applePart
	end

	if clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new(position))
	else
		if applePart then applePart.CFrame = CFrame.new(position) end
		if stem then stem.CFrame = CFrame.new(position + Vector3.new(0, 0.55, 0)) end
	end

	clone.Parent = applesFolder

	-- Click detector (server-side)
	if applePart and not applePart:FindFirstChildOfClass("ClickDetector") then
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 10
		cd.Parent = applePart

		cd.MouseClick:Connect(function(player)
			local character = player.Character
			if not character then return end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + APPLE_HEAL)
				-- notify client to play anim/sound/UI
				pcall(function()
					appleEvent:FireClient(player, {
						heal = APPLE_HEAL,
						animId = EAT_ANIM_ID,
						soundId = EAT_SOUND_ID
					})
				end)

				if clone and clone.Parent then
					clone:Destroy()
					delay(RESPAWN_TIME, function()
						spawnApple(randomPosition())
					end)
				end
			end
		end)
	end

	-- Touch pickup (server-side)
	if applePart then
		local touchedDebounce = {}
		applePart.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then return end
			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end

			local pid = player.UserId
			if touchedDebounce[pid] then return end
			touchedDebounce[pid] = true

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + APPLE_HEAL)
				pcall(function()
					appleEvent:FireClient(player, {
						heal = APPLE_HEAL,
						animId = EAT_ANIM_ID,
						soundId = EAT_SOUND_ID
					})
				end)

				if clone and clone.Parent then
					clone:Destroy()
					delay(RESPAWN_TIME, function()
						spawnApple(randomPosition())
					end)
				end
			end

			-- clear debounce after short delay
			delay(1, function()
				touchedDebounce[pid] = nil
			end)
		end)
	end
end

-- initial spawn
for i = 1, INITIAL_COUNT do
	spawnApple(randomPosition())
end

-- keep minimum apples
spawn(function()
	while true do
		local count = #applesFolder:GetChildren()
		if count < MIN_APPLES then
			spawnApple(randomPosition())
		end
		wait(5)
	end
end)
