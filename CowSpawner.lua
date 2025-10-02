-- CowSpawner.lua
-- Model sapi yang lebih realistis dan immersive dengan memanfaatkan fitur Roblox Studio

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- CONFIG
local SPAWN_AREA_NAME = "SpawnArea"
local SPAWN_INTERVAL = 3       -- detik antara percobaan spawn
local MAX_COWS = 6
local COW_WALK_SPEED = 8
local WANDER_WAIT_MIN = 1.5
local WANDER_WAIT_MAX = 4
local RANDOM = Random.new()

-- Helpers
local spawnArea = Workspace:FindFirstChild(SPAWN_AREA_NAME)
if not spawnArea or not spawnArea:IsA("BasePart") then
	warn("SimpleCowSpawner: Tidak menemukan workspace."..SPAWN_AREA_NAME.." (harus berupa Part).")
	return
end

local function randomPointInArea()
	local size = spawnArea.Size
	local ox = (RANDOM:NextNumber() - 0.5) * size.X
	local oz = (RANDOM:NextNumber() - 0.5) * size.Z
	local worldPos = (spawnArea.CFrame * CFrame.new(ox, 0, oz)).p
	local y = spawnArea.Position.Y + spawnArea.Size.Y/2 + 2
	return Vector3.new(worldPos.X, y, worldPos.Z)
end

local function projectToGround(pos)
	local origin = pos + Vector3.new(0, 50, 0)
	local result = Workspace:Raycast(origin, Vector3.new(0, -200, 0))
	if result and result.Position then
		return result.Position + Vector3.new(0, 1, 0)
	end
	return pos
end

-- Membuat model sapi yang lebih realistis
local function createCowModel(id)
	local model = Instance.new("Model")
	model.Name = "Cow_"..tostring(id)

	-- HumanoidRootPart
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 2)
	root.Anchored = false
	root.CanCollide = true
	root.Position = Vector3.new(0, 5, 0)
	root.Transparency = 1 -- Sembunyikan root part
	root.Parent = model

	-- Body utama (lebih oval)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4.5, 2.8, 7)
	body.Anchored = false
	body.CanCollide = true
	body.BrickColor = BrickColor.new("Reddish brown")
	body.Material = Enum.Material.Fabric
	body.Parent = model

	-- Perut (lebih terlihat realistis)
	local belly = Instance.new("Part")
	belly.Name = "Belly"
	belly.Size = Vector3.new(4, 1.8, 5.5)
	belly.Anchored = false
	belly.CanCollide = true
	belly.BrickColor = BrickColor.new("Medium stone grey")
	belly.Material = Enum.Material.Fabric
	belly.Parent = model

	-- Kepala (lebih berbentuk)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.4, 2.2, 2.8)
	head.Anchored = false
	head.CanCollide = true
	head.BrickColor = BrickColor.new("Pastel brown")
	head.Material = Enum.Material.Fabric
	head.Parent = model

	-- Moncong
	local snout = Instance.new("Part")
	snout.Name = "Snout"
	snout.Size = Vector3.new(1.8, 1.2, 1.6)
	snout.Anchored = false
	snout.CanCollide = true
	snout.BrickColor = BrickColor.new("Medium stone grey")
	snout.Material = Enum.Material.Fabric
	snout.Parent = model

	-- Leher (menghubungkan kepala dan tubuh)
	local neck = Instance.new("Part")
	neck.Name = "Neck"
	neck.Size = Vector3.new(2.2, 1.6, 2)
	neck.Anchored = false
	neck.CanCollide = true
	neck.BrickColor = BrickColor.new("Reddish brown")
	neck.Material = Enum.Material.Fabric
	neck.Parent = model

	-- Four legs dengan bentuk yang lebih realistis
	local legs = {}
	local legOffsets = {
		Vector3.new(1.5, -2.2, 2.2),  -- Front right
		Vector3.new(-1.5, -2.2, 2.2), -- Front left
		Vector3.new(1.5, -2.2, -2.2), -- Back right
		Vector3.new(-1.5, -2.2, -2.2),-- Back left
	}

	for i, offset in ipairs(legOffsets) do
		local leg = Instance.new("Part")
		leg.Name = "Leg"..i
		leg.Size = Vector3.new(1, 2.8, 1)
		leg.Anchored = false
		leg.CanCollide = true
		leg.BrickColor = BrickColor.new("Reddish brown")
		leg.Material = Enum.Material.Fabric
		leg.Parent = model
		table.insert(legs, leg)
	end

	-- Hooves (kuku)
	local hooves = {}
	for i, offset in ipairs(legOffsets) do
		local hoof = Instance.new("Part")
		hoof.Name = "Hoof"..i
		hoof.Size = Vector3.new(1.2, 0.4, 1.2)
		hoof.Anchored = false
		hoof.CanCollide = true
		hoof.BrickColor = BrickColor.new("Black")
		hoof.Material = Enum.Material.Plastic
		hoof.Parent = model
		table.insert(hooves, hoof)
	end

	-- Tail yang lebih realistis
	local tailBase = Instance.new("Part")
	tailBase.Name = "TailBase"
	tailBase.Size = Vector3.new(0.8, 0.8, 1.5)
	tailBase.Anchored = false
	tailBase.CanCollide = false
	tailBase.BrickColor = BrickColor.new("Reddish brown")
	tailBase.Material = Enum.Material.Fabric
	tailBase.Parent = model

	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.3, 0.3, 2.5)
	tail.Anchored = false
	tail.CanCollide = false
	tail.BrickColor = BrickColor.new("Black")
	tail.Material = Enum.Material.Fabric
	tail.Parent = model

	-- Ears (telinga)
	local leftEar = Instance.new("Part")
	leftEar.Name = "LeftEar"
	leftEar.Size = Vector3.new(0.4, 0.8, 0.6)
	leftEar.Anchored = false
	leftEar.CanCollide = false
	leftEar.BrickColor = BrickColor.new("Pastel brown")
	leftEar.Material = Enum.Material.Fabric
	leftEar.Parent = model

	local rightEar = Instance.new("Part")
	rightEar.Name = "RightEar"
	rightEar.Size = Vector3.new(0.4, 0.8, 0.6)
	rightEar.Anchored = false
	rightEar.CanCollide = false
	rightEar.BrickColor = BrickColor.new("Pastel brown")
	rightEar.Material = Enum.Material.Fabric
	rightEar.Parent = model

	-- Horns (tanduk - opsional)
	local leftHorn = Instance.new("Part")
	leftHorn.Name = "LeftHorn"
	leftHorn.Size = Vector3.new(0.4, 0.8, 0.4)
	leftHorn.Anchored = false
	leftHorn.CanCollide = false
	leftHorn.BrickColor = BrickColor.new("Dark stone grey")
	leftHorn.Material = Enum.Material.Plastic
	leftHorn.Parent = model

	local rightHorn = Instance.new("Part")
	rightHorn.Name = "RightHorn"
	rightHorn.Size = Vector3.new(0.4, 0.8, 0.4)
	rightHorn.Anchored = false
	rightHorn.CanCollide = false
	rightHorn.BrickColor = BrickColor.new("Dark stone grey")
	rightHorn.Material = Enum.Material.Plastic
	rightHorn.Parent = model

	-- Eyes (mata)
	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Size = Vector3.new(0.3, 0.3, 0.3)
	leftEye.Anchored = false
	leftEye.CanCollide = false
	leftEye.BrickColor = BrickColor.new("Black")
	leftEye.Material = Enum.Material.Plastic
	leftEye.Parent = model

	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Size = Vector3.new(0.3, 0.3, 0.3)
	rightEye.Anchored = false
	rightEye.CanCollide = false
	rightEye.BrickColor = BrickColor.new("Black")
	rightEye.Material = Enum.Material.Plastic
	rightEye.Parent = model

	-- Nostrils (lubang hidung)
	local leftNostril = Instance.new("Part")
	leftNostril.Name = "LeftNostril"
	leftNostril.Size = Vector3.new(0.2, 0.2, 0.2)
	leftNostril.Anchored = false
	leftNostril.CanCollide = false
	leftNostril.BrickColor = BrickColor.new("Black")
	leftNostril.Material = Enum.Material.Plastic
	leftNostril.Parent = model

	local rightNostril = Instance.new("Part")
	rightNostril.Name = "RightNostril"
	rightNostril.Size = Vector3.new(0.2, 0.2, 0.2)
	rightNostril.Anchored = false
	rightNostril.CanCollide = false
	rightNostril.BrickColor = BrickColor.new("Black")
	rightNostril.Material = Enum.Material.Plastic
	rightNostril.Parent = model

	-- Udder (ambing untuk sapi betina)
	local udder = Instance.new("Part")
	udder.Name = "Udder"
	udder.Size = Vector3.new(1.5, 0.8, 1.2)
	udder.Anchored = false
	udder.CanCollide = false
	udder.BrickColor = BrickColor.new("Light reddish violet")
	udder.Material = Enum.Material.Fabric
	udder.Parent = model

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.Parent = model
	humanoid.WalkSpeed = COW_WALK_SPEED
	humanoid.MaxHealth = 100
	humanoid.Health = 100

	-- PrimaryPart
	model.PrimaryPart = root

	-- Pasang weld constraints
	local function weldPart(partA, partB, offsetCFrame)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = partA
		weld.Part1 = partB
		weld.Parent = partB
		if offsetCFrame then
			partB.CFrame = partA.CFrame * offsetCFrame
		end
	end

	-- Atur posisi dan weld semua bagian
	local function setupModel()
		-- Body utama
		body.CFrame = root.CFrame * CFrame.new(0, 0.8, 0)
		weldPart(root, body)

		-- Perut
		belly.CFrame = body.CFrame * CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(10))
		weldPart(body, belly)

		-- Leher
		neck.CFrame = body.CFrame * CFrame.new(0, 0.6, -3.2)
		weldPart(body, neck)

		-- Kepala
		head.CFrame = neck.CFrame * CFrame.new(0, 0.2, -1.8)
		weldPart(neck, head)

		-- Moncong
		snout.CFrame = head.CFrame * CFrame.new(0, -0.3, -1.2)
		weldPart(head, snout)

		-- Kaki
		for i, leg in ipairs(legs) do
			local offset = legOffsets[i]
			leg.CFrame = body.CFrame * CFrame.new(offset)
			weldPart(body, leg)
		end

		-- Kuku
		for i, hoof in ipairs(hooves) do
			local leg = legs[i]
			hoof.CFrame = leg.CFrame * CFrame.new(0, -1.6, 0)
			weldPart(leg, hoof)
		end

		-- Ekor
		tailBase.CFrame = body.CFrame * CFrame.new(0, 0.8, 3.6)
		weldPart(body, tailBase)

		tail.CFrame = tailBase.CFrame * CFrame.new(0, 0, 1.2)
		weldPart(tailBase, tail)

		-- Telinga
		leftEar.CFrame = head.CFrame * CFrame.new(-0.8, 0.6, 0.2) * CFrame.Angles(math.rad(-30), 0, math.rad(-20))
		weldPart(head, leftEar)

		rightEar.CFrame = head.CFrame * CFrame.new(0.8, 0.6, 0.2) * CFrame.Angles(math.rad(-30), 0, math.rad(20))
		weldPart(head, rightEar)

		-- Tanduk
		leftHorn.CFrame = head.CFrame * CFrame.new(-0.5, 0.8, -0.4) * CFrame.Angles(math.rad(45), 0, 0)
		weldPart(head, leftHorn)

		rightHorn.CFrame = head.CFrame * CFrame.new(0.5, 0.8, -0.4) * CFrame.Angles(math.rad(45), 0, 0)
		weldPart(head, rightHorn)

		-- Mata
		leftEye.CFrame = head.CFrame * CFrame.new(-0.6, 0.2, -0.8)
		weldPart(head, leftEye)

		rightEye.CFrame = head.CFrame * CFrame.new(0.6, 0.2, -0.8)
		weldPart(head, rightEye)

		-- Lubang hidung
		leftNostril.CFrame = snout.CFrame * CFrame.new(-0.3, 0.1, -0.6)
		weldPart(snout, leftNostril)

		rightNostril.CFrame = snout.CFrame * CFrame.new(0.3, 0.1, -0.6)
		weldPart(snout, rightNostril)

		-- Ambing
		udder.CFrame = body.CFrame * CFrame.new(0, -1.6, -1.5)
		weldPart(body, udder)
	end

	-- Panggil setup setelah semua part dibuat
	setupModel()

	-- Pastikan semua parts non-anchored
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = false
		end
	end

	return model
end

-- Behavior: biarkan sapi berjalan acak di dalam SpawnArea
local function startWandering(cowModel)
	local humanoid = cowModel:FindFirstChildWhichIsA("Humanoid", true)
	local root = cowModel.PrimaryPart
	if not humanoid or not root then return end

	-- ketika mati -> hapus setelah delay
	humanoid.Died:Connect(function()
		delay(3, function()
			if cowModel and cowModel.Parent then
				cowModel:Destroy()
			end
		end)
	end)

	spawn(function()
		while cowModel.Parent and humanoid.Health > 0 do
			local target = randomPointInArea()
			target = projectToGround(target)
			-- arahkan model menghadap target (hanya rotasi Y)
			local lookAt = CFrame.new(root.Position, Vector3.new(target.X, root.Position.Y, target.Z))
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, lookAt:ToEulerAnglesYXZ(), 0)
			-- MoveTo
			humanoid:MoveTo(target)
			local ok = humanoid.MoveToFinished:Wait()
			-- jeda acak
			local waitTime = (RANDOM:NextNumber() * (WANDER_WAIT_MAX - WANDER_WAIT_MIN)) + WANDER_WAIT_MIN
			wait(waitTime)
		end
	end)
end

-- Spawn loop
spawn(function()
	local idCounter = 0
	while true do
		-- hitung existing cows
		local count = 0
		for _, v in ipairs(Workspace:GetChildren()) do
			if v:IsA("Model") and v.Name:match("^Cow_%d+") then
				count = count + 1
			end
		end

		if count < MAX_COWS then
			idCounter = idCounter + 1
			local cow = createCowModel(idCounter)
			cow.Parent = Workspace

			-- posisikan di area spawn
			if cow.PrimaryPart then
				local spawnPos = randomPointInArea()
				cow:SetPrimaryPartCFrame(CFrame.new(spawnPos) * CFrame.Angles(0, RANDOM:NextNumber()*math.pi*2, 0))
			end

			-- mulai behavior
			startWandering(cow)
		end

		wait(SPAWN_INTERVAL)
	end
end)