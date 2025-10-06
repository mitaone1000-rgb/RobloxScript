-- KnockManager.lua (Script) 
-- Path: ServerScriptService/Script/KnockManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))

local KnockEvent = RemoteEvents:WaitForChild("KnockEvent")
local ReviveEvent = RemoteEvents:WaitForChild("ReviveEvent")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")
local ReviveProgressEvent = RemoteEvents:WaitForChild("ReviveProgressEvent")
local CancelReviveEvent = RemoteEvents:WaitForChild("CancelReviveEvent")
local GlobalKnockNotificationEvent = RemoteEvents:WaitForChild("GlobalKnockNotificationEvent")

local activeRevivers = {} -- [reviver] = {target, startTime, connection}

local function cancelRevive(reviver)
	if activeRevivers[reviver] then
		if activeRevivers[reviver].connection then
			activeRevivers[reviver].connection:Disconnect()
		end
		ReviveProgressEvent:FireClient(reviver, 0, true, 0) -- Cancel progress
		activeRevivers[reviver] = nil
	end
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.BreakJointsOnDeath = false
		-- [Spawn Grace] Abaikan health spike awal saat baru respawn
		local justSpawned = true
		task.delay(2, function()  -- 2 detik cukup untuk inisialisasi
			justSpawned = false
		end)


		humanoid.HealthChanged:Connect(function(health)
			if (not justSpawned) and health <= 0 and not char:FindFirstChild("Knocked") then
				local activePlayers = 0
				for _, p in pairs(game.Players:GetPlayers()) do
					if p.Character and not p.Character:FindFirstChild("Knocked") then
						activePlayers = activePlayers + 1
					end
				end

				if activePlayers == 1 then
					GameOverEvent:FireAllClients()
					-- Bersihkan status knock & UI terkait pada semua pemain saat Game Over
					local Players = game:GetService("Players")

					-- Batalkan semua proses revive yang sedang berjalan
					for reviver, _ in pairs(activeRevivers) do
						cancelRevive(reviver)
					end

					-- Hapus tag "Knocked" & kirim KnockEvent(false) agar UI Knock ditutup
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr.Character then
							local tag = plr.Character:FindFirstChild("Knocked")
							if tag then tag:Destroy() end
							KnockEvent:FireClient(plr, false)
							-- Pastikan progress bar revive (jika ada) juga direset & disembunyikan
							ReviveProgressEvent:FireClient(plr, 0, true, 0)
						end
					end
					-- MATIKAN AUTORESPAWN & BEKUKAN KARAKTER SAAT GAME OVER
					local Players = game:GetService("Players")
					Players.CharacterAutoLoads = false
					for _, plr in ipairs(Players:GetPlayers()) do
						local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							if hum.Health <= 0 then
								-- biarkan ragdoll, JANGAN respawn (karena CharacterAutoLoads = false)
							else
								hum.Health = math.max(1, hum.Health)
								hum.WalkSpeed = 0
								hum.JumpPower = 0
								hum.PlatformStand = true
							end
						end
					end

					for _, zombie in pairs(workspace:GetChildren()) do
						if zombie:FindFirstChild("IsZombie") then
							zombie:Destroy()
						end
					end
				else
					local tag = Instance.new("BoolValue")
					tag.Name = "Knocked"
					tag.Parent = char
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
					humanoid.PlatformStand = true
					humanoid.Health = 1
					KnockEvent:FireClient(player, true)
					-- update leaderstat knock
					if PointsSystem and PointsSystem.AddKnock then
						PointsSystem.AddKnock(player)
					end

					-- NEW: Kirim notifikasi ke semua pemain
					GlobalKnockNotificationEvent:FireAllClients(player.Name, true, char.HumanoidRootPart.Position)
				end
			elseif char:FindFirstChild("Knocked") and humanoid.Health < 1 then
				humanoid.Health = 1
			end
		end)
	end)
end)



CancelReviveEvent.OnServerEvent:Connect(function(player)
	cancelRevive(player)
end)

ReviveEvent.OnServerEvent:Connect(function(player, target)
	-- HARD GUARD: reviver tidak boleh knock / self-target / target harus knock
	if not player.Character or player.Character:FindFirstChild("Knocked") then
		return
	end
	if not target or target == player then
		return
	end
	if not target.Character or not target.Character:FindFirstChild("Knocked") then
		return
	end

	if activeRevivers[player] then
		cancelRevive(player)
		return
	end

	if target and target.Character and target.Character:FindFirstChild("Knocked") then
		local humanoid = target.Character:FindFirstChild("Humanoid")
		if humanoid then
			local startTime = tick()
			-- SIMPAN DI BAWAH: local startTime = tick()
			local startTime = time()
			activeRevivers[player] = {
				target = target,
				startTime = startTime,
				connection = nil
			}

			-- Listen for movement/actions that cancel revive
			activeRevivers[player].connection = player.Character.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
				if activeRevivers[player] and tick() - startTime < 6 then
					cancelRevive(player)
				end
			end)

			local reviveTime = 6 -- default 6 detik
			if player.Character and player.Character:GetAttribute("ReviveBoost") then
				reviveTime = 3 -- 3 detik dengan perk
			end

			-- Progress update loop
			spawn(function()
				local reviverChar = player.Character
				local targetChar = target.Character

				-- TEMPATKAN DI ATAS: for i = 1, reviveTime * 10 do
				local RunService = game:GetService("RunService")
				local reviverChar = player.Character
				local targetChar = target.Character
				local endTime = time() + reviveTime

				while time() < endTime do
					-- CANCEL GUARD: berhenti kalau sudah dibatalkan dari mana pun
					if not activeRevivers[player] then
						ReviveProgressEvent:FireClient(player, 0, true, 0)
						break
					end
					-- Batal jika status berubah
					if not reviverChar or not targetChar 
						or not reviverChar.Parent or not targetChar.Parent
						or reviverChar:FindFirstChild("Knocked")
						or not targetChar:FindFirstChild("Knocked")
						or (reviverChar.HumanoidRootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude > 8 then
						cancelRevive(player)
						break
					end

					local remaining = endTime - time()
					local progress = 1 - math.clamp(remaining / reviveTime, 0, 1)
					ReviveProgressEvent:FireClient(player, progress, false, reviveTime)

					RunService.Heartbeat:Wait() -- frame-accurate, tidak molor saat lag
				end

				if activeRevivers[player] then
					-- Successfully revived
					humanoid.Health = humanoid.MaxHealth * 0.1
					humanoid.WalkSpeed = 16
					humanoid.JumpPower = 50
					humanoid.PlatformStand = false
					-- FIX: reset fisika & paksa humanoid bangun agar tidak melayang/berputar
					local targetChar = target.Character
					local hrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
					if hrp then
						-- buang momentum sisa
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero

						-- jaga orientasi tegak lurus (tanpa memaksa rotasi yaw)
						local _, yaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
						local pos = hrp.Position
						hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
					end

					-- pastikan humanoid “bangun” normal
					humanoid.AutoRotate = true
					humanoid.Sit = false
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

					-- jaga-jaga: setelah satu frame, nolkan lagi kalau masih ada sisa momentum
					task.defer(function()
						if hrp then
							hrp.AssemblyLinearVelocity = Vector3.zero
							hrp.AssemblyAngularVelocity = Vector3.zero
						end
					end)

					target.Character.Knocked:Destroy()
					-- PULIHKAN GERAK SETELAH REVIVE
					humanoid.PlatformStand = false
					humanoid.WalkSpeed = 16
					if PointsSystem and PointsSystem.AddRevive then
						PointsSystem.AddRevive(player) -- player = reviver
					end
					-- atur sesuai desainmu
					humanoid.UseJumpPower = true
					humanoid.JumpPower = 30              -- samakan dengan JumpPower.lua
					KnockEvent:FireClient(target, false)
					-- Pastikan progress bar hilang di client setelah sukses
					ReviveProgressEvent:FireClient(player, 1, false, reviveTime)
					task.defer(function()
						ReviveProgressEvent:FireClient(player, 0, true)
					end)

					-- NEW: Kirim notifikasi revive ke semua pemain
					GlobalKnockNotificationEvent:FireAllClients(target.Name, false, targetChar.HumanoidRootPart.Position)

					activeRevivers[player] = nil
				end
			end)
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	cancelRevive(player)

end)
