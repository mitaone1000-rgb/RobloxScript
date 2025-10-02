-- WeaponClient.lua (LocalScript)
-- Path: StarterPack/Weapon (tool)/WeaponClient.lua

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent
tool.CanBeDropped = false
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local ViewmodelModule = require(ModuleScriptReplicatedStorage:WaitForChild("ViewmodelModule"))
local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

local ShootEvent = RemoteEvents:WaitForChild("ShootEvent")
local ReloadEvent = RemoteEvents:WaitForChild("ReloadEvent")
local TracerEvent = RemoteEvents:WaitForChild("TracerEvent")
local MuzzleFlashEvent = RemoteEvents:WaitForChild("MuzzleFlashEvent")
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")
local KnockEvent = RemoteEvents:WaitForChild("KnockEvent")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")

local currentReloadSound = nil
local weaponName = tool.Name
local canShoot = true
local reloading = false
local isMouseDown = false
local currentAmmo = WeaponModule.Weapons[weaponName].MaxAmmo
local isAiming = false
local isGameOver = false
local originalFoV = camera.FieldOfView
local originalWalkSpeed = 16
local nextFireTime = 0

-- Initialize Viewmodel
local viewmodel = ViewmodelModule.new(tool, player, weaponName, WeaponModule)

local function _computeFireRate()
	local def = WeaponModule.Weapons[weaponName]
	if not def then return 0 end
	local rate = def.FireRate
	if player.Character and player.Character:GetAttribute("RateBoost") then
		rate = rate * 0.7
	end
	return rate
end

local function isFireCooldownReady()
	return tick() >= (nextFireTime or 0)
end

local function markJustFired()
	nextFireTime = tick() + _computeFireRate()
end

if player:GetAttribute("DoubleTapUsesADS") == nil then
	player:SetAttribute("DoubleTapUsesADS", true)
end

local function getDoubleTapUsesADS()
	local v = player:GetAttribute("DoubleTapUsesADS")
	return v == nil and true or v
end

local function setDoubleTapUsesADS(v)
	player:SetAttribute("DoubleTapUsesADS", v)
end

local adsHeldByFire = false     
local adsTransitionTime = WeaponModule.Weapons[weaponName].TransitionTime or 0.2
local isKnocked = false
local RELOAD_WALK_SPEED = 8
local hasPlayedReloadSound = false
local currentRecoil = 0
local recoilDecayRate = 1
local defaultGrip = nil
local adsTween = nil
local fovTween = nil
local lastTargetFoV = originalFoV

local function stopAdsTween()
	if adsTween then
		adsTween:Cancel()
		adsTween = nil
	end
end

local function stopFovTween()
	if fovTween then
		fovTween:Cancel()
		fovTween = nil
	end
end

local function transitionToADS()
	stopAdsTween()

	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local adsPosition
	local adsRotation

	if weaponStats.Skins and weaponStats.Use_Skin and weaponStats.Skins[weaponStats.Use_Skin] then
		local skin = weaponStats.Skins[weaponStats.Use_Skin]

		if UserInputService.TouchEnabled and skin.ADS_Position_Mobile then
			adsPosition = skin.ADS_Position_Mobile
			adsRotation = skin.ADS_Rotation_Mobile or skin.ADS_Rotation
		else
			adsPosition = skin.ADS_Position
			adsRotation = skin.ADS_Rotation
		end
	end

	if not adsPosition then return end

	local targetCFrame = CFrame.new(adsPosition)
	if adsRotation then
		targetCFrame = targetCFrame * CFrame.Angles(
			math.rad(adsRotation.X),
			math.rad(adsRotation.Y),
			math.rad(adsRotation.Z)
		)
	end

	local tweenInfo = TweenInfo.new(
		adsTransitionTime,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	adsTween = TweenService:Create(tool, tweenInfo, {Grip = targetCFrame})
	adsTween:Play()
end

local function transitionToHip()
	stopAdsTween()

	if not defaultGrip then return end

	local tweenInfo = TweenInfo.new(
		adsTransitionTime,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	adsTween = TweenService:Create(tool, tweenInfo, {Grip = defaultGrip})
	adsTween:Play()
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if tool.Parent == player.Character and not reloading and not isKnocked then
			isAiming = true
			tool:SetAttribute("IsAiming", true)
			transitionToADS()

			-- Client-side prediction for immediate walk speed change.
			-- The server will ultimately enforce this via ServerWalkSpeedManager,
			-- but this provides a responsive feel for the player.
			-- SprintClient is aware of the "IsAiming" attribute and will not interfere.
			local weaponStats = WeaponModule.Weapons[weaponName]
			if weaponStats and player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = weaponStats.ADS_WalkSpeed
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
		tool:SetAttribute("IsAiming", false)
		transitionToHip()

		-- Restore original walk speed. The SprintClient will take over if the
		-- sprint key is still held down, ensuring a smooth transition.
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = originalWalkSpeed
		end
	end
end)

tool.Unequipped:Connect(function()
	tool:SetAttribute("IsAiming", false)
	if player.Character then player.Character:SetAttribute("IsReloading", false) end
	stopAdsTween()
	stopFovTween()

	camera.FieldOfView = originalFoV
	lastTargetFoV = originalFoV

	if currentReloadSound then
		currentReloadSound:Stop()
		currentReloadSound = nil
	end
	reloading = false
	isAiming = false

	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = originalWalkSpeed
	end

	viewmodel:destroyViewmodel()
end)

tool.Destroying:Connect(function()
	viewmodel:destroyViewmodel()
end)

tool.AncestryChanged:Connect(function(_, parent)
	if parent ~= player.Character then
		viewmodel:destroyViewmodel()
	end
end)

player.CharacterRemoving:Connect(function()
	viewmodel:destroyViewmodel()
end)

mouse.Button1Down:Connect(function()
	if tool.Parent == player.Character and not reloading and not isKnocked then
		isMouseDown = true

		if currentAmmo <= 0 then
			AudioManager.playSound(WeaponModule.Weapons[weaponName].Sounds.Empty, tool)
			return
		end
	end
end)

mouse.Button1Up:Connect(function()
	isMouseDown = false
end)

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
	if gpe then return end

	local isSprinting = player.Character and player.Character:GetAttribute("IsSprinting")
	if input.KeyCode == Enum.KeyCode.R and not reloading and not isSprinting and not isKnocked then
		if tool.Parent == player.Character then
			reloading = true
			if player.Character then player.Character:SetAttribute("IsReloading", true) end
			hasPlayedReloadSound = false

			isAiming = false
			tool:SetAttribute("IsAiming", false)
			transitionToHip()

			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = RELOAD_WALK_SPEED
			end

			ReloadEvent:FireServer(tool)
		end
	end
end)

GameOverEvent.OnClientEvent:Connect(function()
	isGameOver = true
	-- Matikan input senjata & keluar dari ADS
	isMouseDown = false
	isAiming = false
	tool:SetAttribute("IsAiming", false)
	transitionToHip()

	-- Paksa lepas semua tool yang sedang dipakai
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:UnequipTools() end

	-- Bersihkan viewmodel supaya tidak menempel di kamera
	viewmodel:destroyViewmodel()
end)

tool.Equipped:Connect(function()
	-- Jika sudah Game Over, langsung batalkan equip
	if isGameOver then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:UnequipTools() end
		return
	end
	if isKnocked then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:UnequipTools() end
		return
	end
	defaultGrip = tool.Grip
	originalFoV = camera.FieldOfView 
	lastTargetFoV = originalFoV

	reloading = false
	isAiming = false
	tool:SetAttribute("IsAiming", false)

	viewmodel:createViewmodel()

	local function applySkinClient()
		local def = WeaponModule.Weapons[weaponName]
		if not def or not def.Skins or not def.Use_Skin then return end
		local skin = def.Skins[def.Use_Skin]
		if not skin then return end

		local function setMesh(part)
			if not part or not part:IsA("BasePart") then return end
			local mesh = part:FindFirstChildOfClass("SpecialMesh")
			if not mesh then
				mesh = Instance.new("SpecialMesh")
				mesh.Name = "Mesh"
				mesh.Parent = part
			end
			if skin.MeshId and skin.MeshId ~= "" then
				mesh.MeshId = skin.MeshId
			end
			if skin.TextureId and skin.TextureId ~= "" then
				mesh.TextureId = skin.TextureId
			end
		end

		setMesh(tool:FindFirstChild("Handle"))
		if viewmodel.viewmodelHandle then
			setMesh(viewmodel.viewmodelHandle)
		end
	end

	applySkinClient()
end)

KnockEvent.OnClientEvent:Connect(function(knockStatus)
	isKnocked = knockStatus

	if isKnocked then
		isMouseDown = false
		isAiming = false
		tool:SetAttribute("IsAiming", false)
		transitionToHip()

		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:UnequipTools() end

		viewmodel:destroyViewmodel()
	else
		if tool.Parent == player.Character then
			viewmodel:destroyViewmodel()
			viewmodel:createViewmodel()
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	viewmodel:updateViewmodel(dt, isAiming)
end)

local lastTapTime = 0
local lastTapPosition = nil

local SNIPER_SET = { ["L115A1"]=true, ["DSR"]=true, ["Barrett-M82"]=true }
local function isSniperWeapon()
	return SNIPER_SET[weaponName] == true
end

local sniperHoldTouch = nil
local sniperHoldActive = false
local autoFireTouch = nil
local isAutoFiring = false

local function canMobileShoot()
	return tool.Parent == player.Character and not reloading and not isKnocked and currentAmmo > 0
end

local function fireFromCenterOnce()
	if not isFireCooldownReady() then return end
	markJustFired()
	local viewportSize = camera.ViewportSize
	local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
	local ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
	local hitPosition = ray.Origin + ray.Direction * 1000

	ShootEvent:FireServer(tool, hitPosition, isAiming)
	viewmodel:applyVisualRecoil()

	local handle = viewmodel.viewmodelHandle or tool:FindFirstChild("Handle")
	if handle then
		local weaponStats = WeaponModule.Weapons[weaponName]
		local muzzleOffset = weaponStats.MuzzleOffset or Vector3.new(0, 0, 0)
		local tracerOffset = weaponStats.TracerOffset or Vector3.new(0, 0, 0)
		local startPos = handle.CFrame:PointToWorldSpace(tracerOffset)

		TracerEvent:FireServer(startPos, hitPosition, weaponName)
		MuzzleFlashEvent:FireServer(handle, weaponName)
	end

	AudioManager.playSound(WeaponModule.Weapons[weaponName].Sounds.Fire, tool)

	local weaponStats = WeaponModule.Weapons[weaponName]
	local recoilFactor = isAiming and 0.5 or 1
	currentRecoil = math.min(10, currentRecoil + (weaponStats.Recoil * recoilFactor))
end

local function startAutoFire(touchObj)
	if isAutoFiring then return end
	isAutoFiring = true
	autoFireTouch = touchObj

	task.spawn(function()
		while isAutoFiring do
			if not canMobileShoot() then break end

			while isAutoFiring and not isFireCooldownReady() do
				task.wait(0.01)
			end
			if not isAutoFiring or not canMobileShoot() then break end

			fireFromCenterOnce()

			local fireRate = _computeFireRate()
			task.wait(fireRate)
			-- Jika peluru habis saat autofire, paksa keluar dari ADS agar tidak nyangkut
			if currentAmmo <= 0 then
				if adsHeldByFire or isAiming then
					adsHeldByFire = false
					isAiming = false
					tool:SetAttribute("IsAiming", false)
					transitionToHip()
				end
			end
			if currentAmmo <= 0 or reloading or isKnocked or tool.Parent ~= player.Character then
				break
			end
		end
		isAutoFiring = false
		autoFireTouch = nil
	end)
end

UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
	if isFireCooldownReady() and canMobileShoot() and isAutoFiring then
		local isSprinting = player.Character and player.Character:GetAttribute("IsSprinting") == true
		if isSprinting then
			player.Character:SetAttribute("RequestStopSprint", true)
		end
		fireFromCenterOnce()
	end
	if gameProcessed then return end
	if not UserInputService.TouchEnabled then return end
	if tool.Parent ~= player.Character then return end
	if reloading or isKnocked then return end

	local currentTime = tick()
	local tapPosition = touch.Position
	local viewportSize = camera.ViewportSize

	if tapPosition.X > viewportSize.X / 2 then
		if currentTime - lastTapTime < 0.3 and lastTapPosition then
			local isSprinting = player.Character and player.Character:GetAttribute("IsSprinting") == true
			if isSprinting then
				player.Character:SetAttribute("RequestStopSprint", true)
			end

			if currentAmmo <= 0 then
				AudioManager.playSound(WeaponModule.Weapons[weaponName].Sounds.Empty, tool)
				return
			end
			if getDoubleTapUsesADS() then
				if not isAiming then
					isAiming = true
					tool:SetAttribute("IsAiming", true)
					transitionToADS()
				end
				adsHeldByFire = true
			else
				if isAiming then
					isAiming = false
					tool:SetAttribute("IsAiming", false)
					transitionToHip()
				end
				adsHeldByFire = false
			end
			if isSniperWeapon() then
				if not isAiming then
					isAiming = true
					tool:SetAttribute("IsAiming", true)
					transitionToADS()
				end
				adsHeldByFire = true
				sniperHoldActive = true
				sniperHoldTouch = touch
			else
				startAutoFire(touch)
			end
		end

		lastTapTime = currentTime
		lastTapPosition = tapPosition
	end
end)

UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
	if autoFireTouch and touch == autoFireTouch then
		isAutoFiring = false
		if adsHeldByFire then
			adsHeldByFire = false
			isAiming = false
			tool:SetAttribute("IsAiming", false)
			transitionToHip()
		end
	end
	if sniperHoldTouch and touch == sniperHoldTouch then
		if canMobileShoot() then
			if isFireCooldownReady() then
				fireFromCenterOnce()
			end
		end
		sniperHoldActive = false
		sniperHoldTouch = nil

		if adsHeldByFire then
			adsHeldByFire = false
			isAiming = false
			tool:SetAttribute("IsAiming", false)
			transitionToHip()
		end
	end
end)

RunService.Stepped:Connect(function(dt)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local fireRate = weaponStats.FireRate
	if player.Character and player.Character:GetAttribute("RateBoost") then
		fireRate = fireRate * 0.7
	end

	local isEquipped = tool.Parent == player.Character

	if currentAmmo <= 0 then
		isMouseDown = false
	end

	if not UserInputService.TouchEnabled and isMouseDown and canShoot and not reloading and isEquipped and not isKnocked then
		local isSprinting = player.Character and player.Character:GetAttribute("IsSprinting") == true
		if isSprinting then return end

		if not isFireCooldownReady() then return end
		markJustFired()
		canShoot = false
		local hitPosition = mouse.Hit.Position
		ShootEvent:FireServer(tool, hitPosition, isAiming)

		viewmodel:applyVisualRecoil()

		local handle = viewmodel.viewmodelHandle or tool:FindFirstChild("Handle")
		if handle then
			local weaponStats = WeaponModule.Weapons[weaponName]
			local muzzleOffset = weaponStats.MuzzleOffset or Vector3.new(0, 0, 0)
			local tracerOffset = weaponStats.TracerOffset or Vector3.new(0, 0, 0)

			local startPos = handle.CFrame:PointToWorldSpace(tracerOffset)

			TracerEvent:FireServer(startPos, hitPosition, weaponName)
			MuzzleFlashEvent:FireServer(handle, weaponName)
		end

		AudioManager.playSound(WeaponModule.Weapons[weaponName].Sounds.Fire, tool)

		local recoilFactor = isAiming and 0.5 or 1
		currentRecoil = currentRecoil + (weaponStats.Recoil * recoilFactor)
		currentRecoil = math.min(10, currentRecoil)

		task.wait(fireRate)
		canShoot = true
	end

	if isEquipped and isAiming and not reloading then
		local targetFoV = weaponStats.ADSFoV

		if math.abs(targetFoV - lastTargetFoV) > 0.1 then
			stopFovTween()
			fovTween = TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = targetFoV})
			fovTween:Play()
			lastTargetFoV = targetFoV
		end
	else
		if math.abs(originalFoV - lastTargetFoV) > 0.1 then
			stopFovTween()
			fovTween = TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = originalFoV})
			fovTween:Play()
			lastTargetFoV = originalFoV
		end
	end

	local currentCFrame = camera.CFrame
	local recoilCFrame = CFrame.Angles(math.rad(currentRecoil), 0, 0)
	camera.CFrame = currentCFrame * recoilCFrame

	currentRecoil = math.max(0, currentRecoil - recoilDecayRate)
end)

AmmoUpdateEvent.OnClientEvent:Connect(function(reloadWeaponName, ammo, reserveAmmo, isVisible, isReloadingFromServer)
	local isEquipped = tool.Parent == player.Character
	if reloadWeaponName ~= tool.Name or not isEquipped then
		return
	end

	currentAmmo = ammo
	-- Jika ammo menjadi 0 dari update server, paksa keluar dari ADS (mobile & desktop)
	if currentAmmo <= 0 and (adsHeldByFire or isAiming) then
		adsHeldByFire = false
		isAiming = false
		tool:SetAttribute("IsAiming", false)
		transitionToHip()
	end

	if isReloadingFromServer then
		if not currentReloadSound then
			currentReloadSound = AudioManager.createSound(WeaponModule.Weapons[tool.Name].Sounds.Reload, tool)
			if currentReloadSound then
				currentReloadSound:Play()
				reloading = true
			end
		end
	else
		if currentReloadSound then
			currentReloadSound:Stop()
			currentReloadSound = nil
		end
		reloading = false
		if player.Character then player.Character:SetAttribute("IsReloading", false) end

		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			if isAiming then
				humanoid.WalkSpeed = WeaponModule.Weapons[weaponName].ADS_WalkSpeed
			else
				humanoid.WalkSpeed = originalWalkSpeed
			end
		end
	end
end)

-- [FIX] Boss2 gravity: jaga tarikan tetap kuat saat FPS/equip dengan impulse lokal
do
	if not player:GetAttribute("_GravityPullListener") then
		player:SetAttribute("_GravityPullListener", true)

		local GravityPullEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Boss2GravityLocalPull")
		local lastGravityTick = tick()

		GravityPullEvent.OnClientEvent:Connect(function(sourcePos, pullForce)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			local now = tick()
			local dt = math.clamp(now - (lastGravityTick or now), 1/120, 0.25)
			lastGravityTick = now

			local dir = (sourcePos - hrp.Position).Unit
			local adsBoost = (isAiming and 1.15 or 1.0)
			hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dir * (pullForce * 0.5 * dt * adsBoost)
		end)
	end
end