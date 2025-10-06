-- ZombieModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ZombieModule.lua
-- Script Place: ACT 1: Village

local ZombieModule = {}

local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")
local PathfindingService = game:GetService("PathfindingService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local BindableEvents = ReplicatedStorage.BindableEvents
local ZombieVFX = ReplicatedStorage.ZombieVFX
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local ShooterVFXModule = require(ZombieVFX:WaitForChild("ShooterVFXModule"))
local BossVFXModule = require(ZombieVFX:WaitForChild("BossVFXModule"))
local Boss2VFXModule = require(ZombieVFX:WaitForChild("Boss2VFXModule"))
local Boss3VFXModule = require(ZombieVFX:WaitForChild("Boss3VFXModule"))
local ZombieConfig = require(ModuleScriptReplicatedStorage:WaitForChild("ZombieConfig"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))

local BossTimerEvent = RemoteEvents:WaitForChild("BossTimerEvent")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")

local ZombieDiedEvent = BindableEvents:WaitForChild("ZombieDiedEvent")

-- Helper function for a "hard wipe" mechanic used by bosses on timeout.
local function _executeHardWipe(zombie, humanoid)
	local bossPos = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p

	-- Make the boss immune and freeze them to signify the start of the wipe.
	zombie:SetAttribute("Immune", true)
	zombie:SetAttribute("MechanicFreeze", true) -- Prevent anti-stuck from interfering
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
	end
	zombie:SetAttribute("AttackRange", 0)

	-- Play a generic, intense VFX to warn players.
	-- We reuse Boss2's timeout VFX as it's suitable for a general wipe.
	Boss2VFXModule.PlayTimeoutVFX(bossPos)

	-- A short delay to let the VFX play out before the wipe.
	task.wait(3)

	-- Kill all players in the game.
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if h then
			h.Health = 0
		end
	end

	-- Stop the boss from moving permanently after the wipe.
	if humanoid then
		humanoid.WalkSpeed = 0
	end
end

function ZombieModule.SpawnZombie(spawnPoint, typeName, playerCount)
	-- choose template:
	typeName = typeName or "Base"
	local templateName = "Zombie"
	if typeName and typeName ~= "Base" then
		-- expect models named Runner, Shooter, Tank, Boss in ServerStorage
		local candidate = ServerStorage.Zombies:FindFirstChild(typeName)
		if candidate then
			templateName = typeName
		end
	end

	local zombieTemplate = ServerStorage.Zombies:FindFirstChild(templateName) or ServerStorage:FindFirstChild("Zombie")
	if not zombieTemplate then return end

	local zombie = zombieTemplate:Clone()
	zombie.Parent = workspace
	if zombie.PrimaryPart == nil then
		-- try to set primary part
		local hrp = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso")
		if hrp then zombie.PrimaryPart = hrp end
	end

	local humanoid = zombie:FindFirstChild("Humanoid")
	-- apply base or type config
	local cfg = ZombieConfig.BaseZombie
	if typeName and ZombieConfig.Types[typeName] then
		cfg = ZombieConfig.Types[typeName]
	end

	if humanoid then
		-- NEW: Sesuaikan health berdasarkan jumlah pemain
		local healthMultiplier = playerCount or 1
		humanoid.MaxHealth = (cfg.MaxHealth or humanoid.MaxHealth) * healthMultiplier
		humanoid.Health = humanoid.MaxHealth
		humanoid.WalkSpeed = cfg.WalkSpeed or humanoid.WalkSpeed
	end

	-- NEW: Set AttackRange attribute
	zombie:SetAttribute("AttackRange", cfg.AttackRange or 4)

	local isZombieTag = Instance.new("BoolValue")
	isZombieTag.Name = "IsZombie"
	isZombieTag.Value = true
	isZombieTag.Parent = zombie

	if zombie.PrimaryPart then
		zombie:SetPrimaryPartCFrame(CFrame.new(spawnPoint.Position))
	end

	-- specific behaviours
	if typeName == "Runner" then
		-- faster chase handled by WalkSpeed; keep standard attack
	elseif typeName == "Shooter" then
		-- shooter will periodically spit projectiles at nearest player
		spawn(function()
			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local target = ZombieModule.GetNearestPlayer(zombie)
				if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					local from = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
					local to = target.Character.HumanoidRootPart.Position
					ShooterVFXModule.ShootAcidProjectile(from + Vector3.new(0,2,0), to, (ZombieConfig.Types.Shooter.ProjectileSpeed or 80), zombie, ZombieConfig.Types.Shooter.Acid)
				end
				task.wait(2 + math.random()) -- interval
			end
		end)
	elseif typeName == "Tank" then
		-- tank: high HP & heavy attack (attack damage used in Chase)
	elseif typeName == "Boss3" then
		-- Tag boss
		local bossTag = Instance.new("BoolValue"); bossTag.Name = "IsBoss"; bossTag.Parent = zombie

		-- Alert UI boss masuk (pakai event yang sama)
		local bossAlert = ReplicatedStorage.RemoteEvents:FindFirstChild("BossIncoming")
		if not bossAlert then
			bossAlert = Instance.new("RemoteEvent"); bossAlert.Name = "BossIncoming"; bossAlert.Parent = ReplicatedStorage.RemoteEvents
		end
		bossAlert:FireAllClients()

		-- === SPECIAL TIMEOUT (WAJIB): jika waktu habis -> WIPE OUT ===
		local conf = ZombieConfig.Types.Boss3
		local specialTimeout = (conf and conf.SpecialTimeout) or 300
		local bossStartTime = tick()
		if BossTimerEvent then
			BossTimerEvent:FireAllClients(specialTimeout, specialTimeout)
		end

		spawn(function()
			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local remaining = math.max(0, specialTimeout - (tick() - bossStartTime))
				if BossTimerEvent then
					BossTimerEvent:FireAllClients(remaining, specialTimeout)
				end
				if remaining <= 0 then
					-- WIPE OUT using the new helper function.
					_executeHardWipe(zombie, humanoid)
					break
				end
				task.wait(1)
			end
		end)

		-- === RADIASI radius kecil (dipertahankan) ===
		spawn(function()
			local r = conf and conf.Radiation
			local tickTime = (r and r.Tick) or 0.5
			local hr = (r and r.HorizontalRadius) or 6       -- kecil (XZ)
			local vy = (r and r.VerticalHalfHeight) or 1000  -- kolom tinggi (Y)
			local dpsPct = (r and r.DamagePerSecondPct) or 0.01

			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local bossPos = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
				for _, plr in ipairs(game.Players:GetPlayers()) do
					local char = plr.Character
					if char and not ElementModule.IsPlayerInvincible(plr) then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and hrp then
							local dxz = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(bossPos.X, bossPos.Z)).Magnitude
							local dy  = math.abs(hrp.Position.Y - bossPos.Y)
							if dxz <= hr and dy <= vy then
								local dmg = hum.MaxHealth * dpsPct * tickTime
								dmg = ElementModule.ApplyDamageReduction(plr, dmg) -- hormati elemen
								hum:TakeDamage(dmg)
							end
						end
					end
				end
				task.wait(tickTime)
			end
		end)

		-- === SERANGAN BIASA: CORRUPTING BLAST ===
		spawn(function()
			local blastConf = conf and conf.CorruptingBlast
			if not blastConf then return end -- Jangan jalankan jika tidak ada konfigurasi

			while zombie.Parent and humanoid and humanoid.Health > 0 do
				-- Tunggu cooldown sebelum serangan berikutnya
				task.wait(blastConf.Cooldown or 10)

				if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end

				local target = ZombieModule.GetNearestPlayer(zombie)
				if target and target.Character then
					local targetPos = target.Character.HumanoidRootPart.Position

					-- 1. Buat tanda di lokasi target
					Boss3VFXModule.CreateCorruptingBlastTelegraph(targetPos, blastConf.BlastRadius or 15, blastConf.TelegraphDuration or 1.5)

					-- 2. Tunggu durasi tanda
					task.wait(blastConf.TelegraphDuration or 1.5)

					if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end

					-- 3. Buat efek ledakan dan genangan
					Boss3VFXModule.CreateCorruptingBlastEffect(targetPos, blastConf.BlastRadius or 15, blastConf.PuddleDuration or 3)

					-- 4. Berikan damage ledakan awal kepada pemain di area tersebut
					for _, plr in ipairs(game.Players:GetPlayers()) do
						if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
							local hum = plr.Character:FindFirstChildOfClass("Humanoid")
							local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
							if hum and hum.Health > 0 and hrp then
								if (hrp.Position - targetPos).Magnitude <= (blastConf.BlastRadius or 15) then
									local damage = ElementModule.ApplyDamageReduction(plr, blastConf.BlastDamage or 35)
									hum:TakeDamage(damage)
								end
							end
						end
					end

					-- 5. Logika untuk damage berkelanjutan dari genangan
					local puddleEndTime = tick() + (blastConf.PuddleDuration or 3)
					while tick() < puddleEndTime do
						if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end

						for _, plr in ipairs(game.Players:GetPlayers()) do
							if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
								local hum = plr.Character:FindFirstChildOfClass("Humanoid")
								local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
								if hum and hum.Health > 0 and hrp then
									if (hrp.Position - targetPos).Magnitude <= (blastConf.BlastRadius or 15) then
										local damage = ElementModule.ApplyDamageReduction(plr, blastConf.PuddleDamagePerTick or 5)
										hum:TakeDamage(damage)
									end
								end
							end
						end
						task.wait(blastConf.PuddleTickInterval or 0.5)
					end
				end
			end
		end)

		-- Matikan timer saat boss mati
		if humanoid then
			humanoid.Died:Connect(function()
				if BossTimerEvent then BossTimerEvent:FireAllClients(0, 0) end
			end)
		end

		-- === SERANGAN BIASA: GRASPING SOULS ===
		spawn(function()
			local soulConf = conf and conf.GraspingSouls
			if not soulConf then return end

			while zombie.Parent and humanoid and humanoid.Health > 0 do
				task.wait(soulConf.Cooldown or 12)

				if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end

				local players = game:GetService("Players"):GetPlayers()
				local availablePlayers = {}
				for _, p in ipairs(players) do
					if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and not p.Character:FindFirstChild("Knocked") then
						table.insert(availablePlayers, p)
					end
				end

				if #availablePlayers > 0 then
					local soulCount = math.random(soulConf.SoulCount[1], soulConf.SoulCount[2])
					soulCount = math.min(soulCount, #availablePlayers)

					Boss3VFXModule.CreateGraspingSoulsTelegraph(zombie, soulCount, soulConf.TelegraphDuration or 1.5)
					task.wait(soulConf.TelegraphDuration or 1.5)

					if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end

					for i = #availablePlayers, 2, -1 do
						local j = math.random(i)
						availablePlayers[i], availablePlayers[j] = availablePlayers[j], availablePlayers[i]
					end

					-- Helper function to apply explosion damage and effects
					local function applySoulExplosion(explosionPos)
						Boss3VFXModule.CreateSoulExplosion(explosionPos, soulConf.BlastRadius or 8)

						for _, plr in ipairs(game.Players:GetPlayers()) do
							if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
								local hum = plr.Character:FindFirstChildOfClass("Humanoid")
								local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
								if hum and hum.Health > 0 and hrp and (hrp.Position - explosionPos).Magnitude <= (soulConf.BlastRadius or 8) then
									hum:TakeDamage(ElementModule.ApplyDamageReduction(plr, soulConf.BlastDamage or 25))

									pcall(function()
										local debuffManager = require(script.Parent:WaitForChild("DebuffManager"))
										debuffManager.ApplySpeedDebuff(plr, "SoulTaint", 1 - soulConf.DebuffSlowPct, soulConf.DebuffDuration)
									end)
								end
							end
						end
					end

					for i = 1, soulCount do
						local targetPlayer = availablePlayers[i]
						if targetPlayer and targetPlayer.Character then
							local startPos = zombie.PrimaryPart.Position + Vector3.new(0, 5, 0)
							local soul = Boss3VFXModule.CreateGraspingSoul(startPos, soulConf)

							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							bv.P = 5000
							bv.Parent = soul

							task.spawn(function()
								local startTime = tick()
								local lifetime = 15 -- Detik

								local soulConnection
								soulConnection = game:GetService("RunService").Heartbeat:Connect(function()
									-- Periksa kondisi berhenti (target hilang, soul hilang)
									if not soul or not soul.Parent or not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
										if soulConnection then soulConnection:Disconnect() end
										if soul and soul.Parent then soul:Destroy() end
										return
									end

									local targetPos = targetPlayer.Character.HumanoidRootPart.Position

									-- Periksa kondisi ledakan (waktu habis atau jarak dekat)
									local timedOut = tick() - startTime > lifetime
									local tooClose = (soul.Position - targetPos).Magnitude < 3

									if timedOut or tooClose then
										if soulConnection then soulConnection:Disconnect() end

										local explosionPos = timedOut and soul.Position or targetPos
										applySoulExplosion(explosionPos)

										if soul and soul.Parent then soul:Destroy() end
										return
									end

									-- Jika tidak meledak, lanjutkan pengejaran
									local direction = (targetPos - soul.Position).Unit
									bv.Velocity = direction * soulConf.SoulSpeed
								end)
							end)
						end
					end
				end
			end
		end)

		-- === MEKANIK MIRROR QUARTET @50% HP (Implementasi Penuh) ===
		local mqTriggered = false
		local function startMirrorQuartet()
			if mqTriggered then return end
			mqTriggered = true
			zombie:SetAttribute("Immune", true)

			-- FREEZE boss
			local prevWalk  = humanoid and humanoid.WalkSpeed or 16
			local prevJump  = humanoid and humanoid.JumpPower or 50
			local prevAutoR = humanoid and humanoid.AutoRotate
			if humanoid then
				humanoid.WalkSpeed  = 0
				humanoid.JumpPower  = 0
				humanoid.AutoRotate = false
			end

			local mqConfig = conf.MirrorQuartet
			local duration = mqConfig.Duration or 25
			local requiredPlayers = math.min(#game:GetService("Players"):GetPlayers(), mqConfig.RequiredPlayers or 4)

			-- Tampilkan UI
			local mechGui = Boss2VFXModule.ShowMechanicCountdownUI(zombie, "Align the Mirrors", duration)

			-- Mulai VFX dan dapatkan konteksnya (termasuk BindableEvent)
			local mechanicContext = Boss3VFXModule.StartMirrorQuartet(zombie, mqConfig)

			task.spawn(function()
				local success = false
				local mechanicStartTime = tick()
				local allMirrorsLockedStartTime = nil

				-- Loop utama mekanik: berhenti jika waktu habis atau jika sukses
				while tick() - mechanicStartTime < duration do
					local allMirrorsAreLocked = true
					-- Periksa apakah semua cermin terkunci
					for i = 1, requiredPlayers do
						local mirrorData = mechanicContext.Mirrors[i]
						if not mirrorData or not mirrorData.locked then
							allMirrorsAreLocked = false
							break
						end
					end

					if allMirrorsAreLocked then
						if not allMirrorsLockedStartTime then
							allMirrorsLockedStartTime = tick()
						end
						-- Jika semua cermin sudah terkunci selama 3 detik, mekanik berhasil
						if tick() - allMirrorsLockedStartTime >= 3 then
							success = true
							print("MIRROR QUARTET SUCCESSFUL!")
							break -- Keluar dari loop lebih awal
						end
					else
						-- Reset timer jika ada cermin yang tidak terkunci
						allMirrorsLockedStartTime = nil
					end

					task.wait(0.1) -- Cek setiap 0.1 detik
				end

				-- Logika setelah mekanik selesai (baik karena sukses atau waktu habis)

				-- Bersihkan semua objek visual
				Boss3VFXModule.Cleanup(mechanicContext)
				if mechGui and mechGui.Parent then mechGui:Destroy() end

				-- RESTORE gerak boss
				if humanoid then
					humanoid.WalkSpeed  = prevWalk
					humanoid.JumpPower  = prevJump
					humanoid.AutoRotate = prevAutoR or true
				end

				if success then
					-- Jika berhasil, boss kembali normal
					zombie:SetAttribute("Immune", false)
				else
					-- Jika gagal (waktu habis), terapkan Damage Reduction
					print("MIRROR QUARTET FAILED!")
					local dr = mqConfig.FailDR or 0.5
					local drDuration = mqConfig.FailDRDuration or 30
					zombie:SetAttribute("DamageReductionPct", dr)
					Boss2VFXModule.ShowDamageReductionUI(zombie, dr, drDuration)
					zombie:SetAttribute("Immune", false)

					task.delay(drDuration, function()
						if zombie and zombie.Parent then
							zombie:SetAttribute("DamageReductionPct", 0)
						end
					end)
				end
			end)
		end

		-- === MEKANIK CHROMATIC REQUIEM @25% HP (SCALABLE REWORK) ===
		local crTriggered = false
		local function startChromaticRequiem()
			if crTriggered then return end
			crTriggered = true
			zombie:SetAttribute("Immune", true)

			local prevWalk = humanoid and humanoid.WalkSpeed or 16
			if humanoid then
				humanoid.WalkSpeed = 0
			end

			local crConfig = conf.ChromaticRequiem
			local duration = crConfig.Duration or 30
			local mechanicContext = Boss3VFXModule.StartChromaticRequiem(zombie, crConfig)

			local players = game:GetService("Players"):GetPlayers()
			local alivePlayers = {}
			for _, p in ipairs(players) do
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
					table.insert(alivePlayers, p)
				end
			end

			-- Tentukan jumlah kristal yang harus disucikan berdasarkan jumlah pemain yang hidup
			local activeCrystalsCount = math.min(#alivePlayers, 4)
			if activeCrystalsCount == 0 then activeCrystalsCount = 1 end -- Minimal 1 jika tidak ada pemain hidup (misalnya, semua knock)

			local allColors = {"North", "East", "South", "West"}
			local purificationOrder = {}
			-- Acak urutan dari semua warna yang ada
			for i = #allColors, 2, -1 do
				local j = math.random(i)
				allColors[i], allColors[j] = allColors[j], allColors[i]
			end
			-- Ambil sejumlah `activeCrystalsCount` dari urutan yang sudah diacak
			for i = 1, activeCrystalsCount do
				table.insert(purificationOrder, allColors[i])
			end

			local originalPurificationOrder = table.clone(purificationOrder)

			local uiEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("ChromaticRequiemUIEvent")
			if not uiEvent then
				uiEvent = Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
				uiEvent.Name = "ChromaticRequiemUIEvent"
			end
			-- Kirim UI ke SEMUA pemain dengan urutan LENGKAP di awal
			uiEvent:FireAllClients("show", originalPurificationOrder, zombie)

			task.spawn(function()
				local mechanicStartTime = tick()
				local success = false
				local currentPrompt = nil

				-- Fungsi untuk mengelola prompt di kristal
				local function updatePrompt()
					if currentPrompt and currentPrompt.Parent then
						currentPrompt:Destroy()
						currentPrompt = nil
					end

					if #purificationOrder > 0 then
						local nextColor = purificationOrder[1]
						local crystal = mechanicContext.Crystals[nextColor]
						if crystal then
							currentPrompt = Instance.new("ProximityPrompt", crystal)
							currentPrompt.ActionText = "Purify"
							currentPrompt.ObjectText = "Purify " .. nextColor .. " Crystal"
							currentPrompt.HoldDuration = 1.5
							currentPrompt.MaxActivationDistance = 15
							currentPrompt.RequiresLineOfSight = false
							table.insert(mechanicContext.Objects, currentPrompt)

							currentPrompt.Triggered:Connect(function(player)
								local purifiedColor = table.remove(purificationOrder, 1)

								-- Kirim sisa urutan ke client untuk diperbarui
								uiEvent:FireAllClients("update", purificationOrder, zombie)

								if mechanicContext.Crystals[purifiedColor] then
									mechanicContext.Crystals[purifiedColor].Color = Color3.fromRGB(50, 50, 50)
								end

								local beam = mechanicContext.Beams[purifiedColor]
								if beam and beam.Parent then
									beam:Destroy()
								end

								-- Pindah ke prompt berikutnya
								updatePrompt()
							end)
						end
					end
				end

				updatePrompt() -- Inisialisasi prompt pertama

				-- Loop utama mekanik
				while tick() - mechanicStartTime < duration do
					if #purificationOrder == 0 then
						success = true
						break
					end
					task.wait(0.2)
				end

				-- Sembunyikan UI untuk semua pemain
				uiEvent:FireAllClients("hide")

				Boss3VFXModule.CleanupChromaticRequiem(mechanicContext)
				if humanoid then humanoid.WalkSpeed = prevWalk end

				if success then
					zombie:SetAttribute("Stunned", true)
					task.wait(crConfig.SuccessStunDuration or 5)
					zombie:SetAttribute("Stunned", false)
				else
					local dr = crConfig.FailDR or 0.5
					local drDuration = crConfig.FailDRDuration or 30
					zombie:SetAttribute("DamageReductionPct", dr)
					task.delay(drDuration, function()
						if zombie and zombie.Parent then
							zombie:SetAttribute("DamageReductionPct", 0)
						end
					end)
				end
				zombie:SetAttribute("Immune", false)
			end)
		end

		humanoid.HealthChanged:Connect(function(h)
			if humanoid.MaxHealth > 0 and conf.MirrorQuartet and not mqTriggered then
				local triggerHP = conf.MirrorQuartet.TriggerHPPercent or 0.5
				if (h / humanoid.MaxHealth) <= triggerHP then
					startMirrorQuartet()
				end
			end
			if humanoid.MaxHealth > 0 and conf.ChromaticRequiem and not crTriggered then
				local triggerHP = conf.ChromaticRequiem.TriggerHPPercent or 0.25
				if (h / humanoid.MaxHealth) <= triggerHP then
					startChromaticRequiem()
				end
			end
		end)

	elseif typeName == "Boss2" then
		-- Tag boss
		local bossTag = Instance.new("BoolValue"); bossTag.Name = "IsBoss"; bossTag.Parent = zombie

		-- Alert UI boss masuk (pakai event yang sama)
		local bossAlert = ReplicatedStorage.RemoteEvents:FindFirstChild("BossIncoming")
		if not bossAlert then
			bossAlert = Instance.new("RemoteEvent"); bossAlert.Name = "BossIncoming"; bossAlert.Parent = ReplicatedStorage.RemoteEvents
		end
		bossAlert:FireAllClients()

		-- Timer & wipe on timeout
		local conf = ZombieConfig.Types.Boss2
		local specialTimeout = (conf and conf.SpecialTimeout) or 300
		local bossStartTime = tick()
		BossTimerEvent:FireAllClients(specialTimeout, specialTimeout)
		spawn(function()
			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local remaining = math.max(0, specialTimeout - (tick() - bossStartTime))
				BossTimerEvent:FireAllClients(remaining, specialTimeout)
				if remaining <= 0 then
					-- WIPE OUT using the new helper function.
					_executeHardWipe(zombie, humanoid)
					break
				end
				task.wait(1)
			end
		end)

		-- RADIASI radius kecil (dipertahankan)
		spawn(function()
			local r = conf and conf.Radiation
			local tickTime = (r and r.Tick) or 0.5
			local hr = (r and r.HorizontalRadius) or 6
			local vy = (r and r.VerticalHalfHeight) or 1000
			local dpsPct = (r and r.DamagePerSecondPct) or 0.02
			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local bossPos = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
				for _, plr in ipairs(game.Players:GetPlayers()) do
					local char = plr.Character
					if char and not ElementModule.IsPlayerInvincible(plr) then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and hrp then
							local dxz = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(bossPos.X, bossPos.Z)).Magnitude
							local dy  = math.abs(hrp.Position.Y - bossPos.Y)
							if dxz <= hr and dy <= vy then
								local dmg = ElementModule.ApplyDamageReduction(plr, hum.MaxHealth * dpsPct * tickTime)
								hum:TakeDamage(dmg)
							end
						end
					end
				end
				task.wait(tickTime)
			end
		end)

		-- GRAVITY WELL follow (ganti poison follow)
		spawn(function()
			local g = conf and conf.Gravity
			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local target = ZombieModule.GetNearestPlayer(zombie)
				if target and target.Character then
					local hrp = target.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						Boss2VFXModule.CreateGravityWellStatic(
							hrp.Position,                 -- spawn tepat di atas player terdekat
							(g and g.Duration) or 6,      -- durasi sama seperti config
							15,                           -- radius fix 15 stud (sesuai permintaan)
							(g and g.PullForce) or 0      -- gaya tarik (pakai angka config bila ada)
						)
					end
				end
				task.wait((g and g.Interval) or 12)
			end
		end)

		-- GRAVITY SLAM (Implode -> Explode)
		spawn(function()
			local s = conf and conf.GravitySlam
			local ReplicatedStorage = game:GetService("ReplicatedStorage")

			local function groundAt(pos: Vector3)
				-- raycast ke bawah supaya cincin pas di lantai
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {workspace.Terrain}
				rayParams.FilterType = Enum.RaycastFilterType.Include
				local res = workspace:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -300, 0), rayParams)
				return res and Vector3.new(pos.X, res.Position.Y + 0.05, pos.Z) or (pos + Vector3.new(0, 0.05, 0))
			end

			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local radius    = (s and s.Radius) or 18
				local warnTime  = (s and s.TelegraphTime) or 2
				local implodeT  = (s and s.ImplodeDuration) or 0.3
				local implodeF  = (s and s.ImplodeForce) or 1200
				local explodeF  = (s and s.ExplodeForce) or 1600
				local dmgPct    = (s and s.DamagePct) or 0.15

				-- pusat slam = posisi boss saat ini (diproyeksikan ke lantai)
				local center = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
				center = groundAt(center)

				-- 1) Telegraph ring
				Boss2VFXModule.ShowSlamTelegraph(center, radius, warnTime)

				-- beri waktu counterplay ~2 detik
				task.wait(warnTime)

				-- 2) Implosion singkat (hisap ke pusat)
				do
					local t0 = tick()
					local lastTick = tick()
					while tick() - t0 < implodeT do
						local now = tick()
						local dt = math.clamp(now - lastTick, 1/120, 0.25)
						lastTick = now

						for _, plr in ipairs(game.Players:GetPlayers()) do
							local char = plr.Character
							local hrp  = char and char:FindFirstChild("HumanoidRootPart")
							local hum  = char and char:FindFirstChildOfClass("Humanoid")
							if hrp and hum and hum.Health > 0 then
								local dxz = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(center.X, center.Z)).Magnitude
								if dxz <= radius then
									local dir = (center - hrp.Position).Unit
									hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dir * (implodeF * 0.5 * dt)

									-- mirror tarikan di client bila event ada (opsional)
									local re = ReplicatedStorage.RemoteEvents:FindFirstChild("Boss2GravityLocalPull")
									if re then re:FireClient(plr, center, implodeF) end
								end
							end
						end

						task.wait(0.05)
					end
				end

				-- 3) Explosion: dorong keluar + damage %HP
				Boss2VFXModule.PlaySlamExplosion(center, radius)

				for _, plr in ipairs(game.Players:GetPlayers()) do
					local char = plr.Character
					local hrp  = char and char:FindFirstChild("HumanoidRootPart")
					local hum  = char and char:FindFirstChildOfClass("Humanoid")
					if hrp and hum and hum.Health > 0 then
						local dxz = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(center.X, center.Z)).Magnitude
						if dxz <= radius then
							local dir = (hrp.Position - center).Unit
							hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dir * explodeF

							-- hormati invincibility & pengurangan Earth
							if not ElementModule.IsPlayerInvincible(plr) then
								local damage = hum.MaxHealth * dmgPct
								damage = ElementModule.ApplyDamageReduction(plr, damage)
								hum:TakeDamage(damage)
							end
						end
					end
				end

				-- cooldown antar slam
				task.wait((s and s.Cooldown) or 14)
			end
		end)

		-- MEKANIK KOOP 4 PEMAIN @50% HP (boss immune saat mekanik)
		local coopTriggered = false
		local function startCoop()
			if coopTriggered then return end
			coopTriggered = true
			zombie:SetAttribute("Immune", true) -- dipakai oleh WeaponHandler DR/Immune
			-- FREEZE boss selama mekanik Coop
			local prevWalk  = humanoid and humanoid.WalkSpeed or 16
			local prevJump  = humanoid and humanoid.JumpPower or 50
			local prevAutoR = humanoid and humanoid.AutoRotate

			if humanoid then
				humanoid.WalkSpeed  = 0
				humanoid.JumpPower  = 0
				humanoid.AutoRotate = false
			end

			local c = conf and conf.Coop
			local duration = (c and c.Duration) or 20
			-- Tampilkan UI countdown mekanik di atas Boss
			local mechGui = Boss2VFXModule.ShowMechanicCountdownUI(zombie, "Destroy pad", duration)
			local required = math.max(1, math.min((c and c.RequiredPlayers) or 4, #game.Players:GetPlayers()))
			local okPlayers = {}
			local destroyedBy = {}
			local limitPerPlayer = (#game:GetService("Players"):GetPlayers() > 1)
			local center = zombie.PrimaryPart and zombie.PrimaryPart.Position or zombie:GetModelCFrame().p
			local pads = Boss2VFXModule.SpawnCoopPads(center, required, duration, limitPerPlayer, destroyedBy, okPlayers)

			-- Ganti task.delay dengan loop pemantauan
			task.spawn(function()
				local startTime = tick()
				local success = false

				-- Loop selama durasi mekanik
				while tick() - startTime < duration do
					local destroyedCount = 0
					for _ in pairs(okPlayers) do destroyedCount += 1 end

					-- Cek kondisi sukses
					if destroyedCount >= required then
						success = true
						break -- Keluar dari loop jika berhasil
					end

					task.wait(0.25) -- Cek setiap seperempat detik
				end

				-- --- Cleanup & Logic setelah loop selesai ---

				-- Hancurkan pad yang tersisa
				for _, p in ipairs(pads) do
					if p and p.Parent then p:Destroy() end
				end
				-- Hancurkan UI countdown
				if mechGui and mechGui.Parent then
					mechGui:Destroy()
				end

				-- Kembalikan status boss
				if humanoid then
					humanoid.WalkSpeed  = prevWalk
					humanoid.JumpPower  = prevJump
					humanoid.AutoRotate = prevAutoR or true
				end

				if success then
					-- Sukses: boss kembali normal
					zombie:SetAttribute("Immune", false)
				else
					-- Gagal (timeout): berikan DR
					local dr = (c and c.FailDR) or 0.5
					local durn = (c and c.FailDRDuration) or 30
					zombie:SetAttribute("DamageReductionPct", dr)
					Boss2VFXModule.ShowDamageReductionUI(zombie, dr, durn)
					zombie:SetAttribute("Immune", false)
					task.delay(durn, function()
						if zombie and zombie.Parent then
							zombie:SetAttribute("DamageReductionPct", 0)
						end
					end)
				end
			end)
		end

		humanoid.HealthChanged:Connect(function(h)
			if humanoid.MaxHealth > 0 then
				if (h / humanoid.MaxHealth) <= ((conf and conf.Coop and conf.Coop.TriggerHPPercent) or 0.5) then
					startCoop()
				end
			end
		end)

		humanoid.Died:Connect(function()
			BossTimerEvent:FireAllClients(0, 0)
		end)

	elseif typeName == "Boss" then
		-- boss tag
		local bossTag = Instance.new("BoolValue")
		bossTag.Name = "IsBoss"
		bossTag.Parent = zombie

		-- Boss incoming alert to clients
		local bossAlert = ReplicatedStorage.RemoteEvents:FindFirstChild("BossIncoming")
		if not bossAlert then
			bossAlert = Instance.new("RemoteEvent")
			bossAlert.Name = "BossIncoming"
			bossAlert.Parent = ReplicatedStorage.RemoteEvents
		end
		bossAlert:FireAllClients() -- client should show "Boss Zombie incoming" UI

		-- NEW: Boss timer
		local pconf = ZombieConfig.Types.Boss.Poison
		local bossStartTime = tick()
		local specialTimeout = pconf.SpecialTimeout or 300

		-- Send initial timer to all clients
		BossTimerEvent:FireAllClients(specialTimeout, specialTimeout)

		-- Update timer every second and trigger wipe on timeout.
		spawn(function()
			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local elapsed = tick() - bossStartTime
				local remaining = math.max(0, specialTimeout - elapsed)
				BossTimerEvent:FireAllClients(remaining, specialTimeout)

				if remaining <= 0 then
					-- WIPE OUT using the new helper function.
					_executeHardWipe(zombie, humanoid)
					break
				end

				task.wait(1)
			end
		end)

		-- Boss radiation damage (kolom sempit, vertikal besar)
		spawn(function()
			local rconf = ZombieConfig.Types.Boss.Radiation
			local tickTime = (rconf and rconf.Tick) or 0.5
			local hr = (rconf and rconf.HorizontalRadius) or 10
			local vy = (rconf and rconf.VerticalHalfHeight) or 1000
			local dpsPct = (rconf and rconf.DamagePerSecondPct) or 0.02

			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local bossPos = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
				for _, plr in ipairs(game.Players:GetPlayers()) do
					local char = plr.Character
					if char and not ElementModule.IsPlayerInvincible(plr) then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and hrp then
							-- hitung jarak horizontal (XZ) & beda tinggi (Y)
							local dxz = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(bossPos.X, bossPos.Z)).Magnitude
							local dy  = math.abs(hrp.Position.Y - bossPos.Y)

							-- kolom: radius kecil di XZ, vertikal tinggi (tembus lantai/atap)
							if dxz <= hr and dy <= vy then
								local dmg = hum.MaxHealth * dpsPct * tickTime
								-- hormati pengurangan elemen Earth yang sudah ada
								dmg = ElementModule.ApplyDamageReduction(plr, dmg)
								hum:TakeDamage(dmg)
							end
						end
					end
				end
				task.wait(tickTime)
			end
		end)

		-- Boss poison skill (only initial attacks, timeout is handled above)
		spawn(function()
			local pconf = ZombieConfig.Types.Boss.Poison

			-- Create poison aura around boss
			BossVFXModule.CreateBossPoisonAura(zombie)

			-- immediate first poison
			local function doPoisonOnce()
				-- Create normal poison VFX
				for _, plr in ipairs(game.Players:GetPlayers()) do
					local char = plr.Character
					if char then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						local head = char:FindFirstChild("Head")
						local pos = (head and head.Position) or (hrp and hrp.Position)
						if pos then
							-- spawn cloud di atas player supaya tetesan jatuh ke bawah
							BossVFXModule.CreateBossPoisonEffectFollow(plr.Character, false, (ZombieConfig.Types.Boss.Poison and ZombieConfig.Types.Boss.Poison.Duration) or 5)
						end
					end
				end

				for _, plr in pairs(game.Players:GetPlayers()) do
					-- PERBAIKAN: Tambahkan pengecekan invincibility setiap tick
					if plr.Character and not ElementModule.IsPlayerInvincible(plr) then
						local hum = plr.Character:FindFirstChild("Humanoid")
						if hum and hum.Health > 0 then
							-- NEW: Apply poison visual effect to player
							BossVFXModule.ApplyPlayerPoisonEffect(plr.Character, false, pconf.Duration)

							local totalDamage = hum.MaxHealth * pconf.SinglePoisonPct
							local ticks = math.max(1, math.floor(pconf.Duration / 0.5))
							local dmgPerTick = totalDamage / ticks
							for t=1, ticks do
								-- PERBAIKAN: Cek invincibility setiap tick
								if hum.Health > 0 and not ElementModule.IsPlayerInvincible(plr) then
									local damage = dmgPerTick
									-- Apply Earth element damage reduction
									damage = ElementModule.ApplyDamageReduction(plr, damage)
									hum:TakeDamage(damage)
								end
								task.wait(pconf.Duration / ticks)
							end
						end
					end
				end
			end

			-- run initial + further times
			for i=1, (pconf.InitialCount or 4) do
				if not zombie.Parent or not humanoid or humanoid.Health <= 0 then break end
				-- do poison
				doPoisonOnce()
				if i == 1 then
					-- first poison done immediately
				end
				-- wait interval unless last
				if i < (pconf.InitialCount or 4) then
					task.wait(pconf.Interval or 60)
				end
			end
		end)
	end

	-- [[ REVISED ZOMBIE CHASE AND PATHFINDING LOOP ]]
	spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 3,
			AgentHeight = 6,
			AgentCanJump = true
		})

		-- Variables to track the current path and target's position
		local currentWaypoints = {}
		local currentWaypointIndex = 1
		local lastTargetPosition = Vector3.new()

		-- Cooldowns to manage behavior frequency
		local attackCooldown = (cfg and cfg.AttackCooldown) or ZombieConfig.BaseZombie.AttackCooldown or 1.5
		local lastAttackTime = 0

		while zombie.Parent and humanoid and humanoid.Health > 0 do
			task.wait(0.2) -- The main logic loop runs 5 times per second

			-- Handle special states like being stunned or frozen by a mechanic
			if zombie:GetAttribute("MechanicFreeze") or zombie:GetAttribute("Stunned") then
				if humanoid.WalkSpeed > 0 then humanoid.WalkSpeed = 0 end
				continue -- Skip all logic below
			else
				-- Restore speed if it was zeroed out by a mechanic or an attack
				if humanoid.WalkSpeed == 0 and not zombie:GetAttribute("Attacking") then
					humanoid.WalkSpeed = cfg.WalkSpeed or 16
				end
			end

			-- Find the nearest player
			local target = ZombieModule.GetNearestPlayer(zombie)
			if not target or not target.Character or not target.Character.PrimaryPart then
				continue -- No target, wait for the next cycle
			end

			local currentPos = zombie.PrimaryPart.Position
			local targetPos = target.Character.PrimaryPart.Position
			local distanceToTarget = (targetPos - currentPos).Magnitude
			local attackRange = zombie:GetAttribute("AttackRange") or 4

			-- 1. ATTACK LOGIC: Highest priority. If in range, attack.
			if distanceToTarget <= attackRange then
				-- Clear any existing path since we've reached the target
				currentWaypoints = {}

				-- Check attack cooldown
				if tick() - lastAttackTime > attackCooldown then
					lastAttackTime = tick()
					zombie:SetAttribute("Attacking", true)
					humanoid.WalkSpeed = 0 -- Stop moving to attack

					-- Face the target for the attack
					zombie:SetPrimaryPartCFrame(CFrame.new(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)))

					-- Perform the attack damage in a separate thread
					task.spawn(function()
						local playerHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
						if playerHumanoid and not target.Character:FindFirstChild("Knocked") and not ElementModule.IsPlayerInvincible(target) then
							local damage = (cfg and cfg.AttackDamage) or ZombieConfig.BaseZombie.AttackDamage
							damage = ElementModule.ApplyDamageReduction(target, damage)
							playerHumanoid:TakeDamage(damage)
						end

						-- Brief delay after attacking before moving again
						task.wait(0.5) 
						zombie:SetAttribute("Attacking", false)
					end)
				end
				continue -- Do not proceed to movement logic this cycle
			end

			-- 2. MOVEMENT LOGIC: Diverge based on whether it's a boss
			if zombie:FindFirstChild("IsBoss") then
				-- BOSS MOVEMENT: Simple, direct chase.
				humanoid:MoveTo(targetPos)
			else
				-- NON-BOSS MOVEMENT: Use existing pathfinding.
				local needsNewPath = false
				-- Reason a) Target has moved a significant distance since last path calculation
				if (targetPos - lastTargetPosition).Magnitude > 10 then
					needsNewPath = true
				-- Reason b) We don't have a path, or we've reached the end of our current one
				elseif not currentWaypoints or currentWaypointIndex >= #currentWaypoints then
					needsNewPath = true
				-- Reason c) Check if we've arrived at the current waypoint to advance the index
				else
					local nextWaypointPos = currentWaypoints[currentWaypointIndex].Position
					if (Vector2.new(nextWaypointPos.X, nextWaypointPos.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude < 4 then
						-- We are close enough to the waypoint, so advance to the next one
						currentWaypointIndex += 1
					end
				end

				if needsNewPath then
					local success, err = pcall(function()
						path:ComputeAsync(currentPos, targetPos)
					end)

					if success and path.Status == Enum.PathStatus.Success and #path:GetWaypoints() > 1 then
						currentWaypoints = path:GetWaypoints()
						currentWaypointIndex = 2 -- Start with the second waypoint (first is current location)
						lastTargetPosition = targetPos -- Update last known target position
					else
						-- Path failed, clear old path and attempt to move directly as a fallback
						currentWaypoints = {}
						humanoid:MoveTo(targetPos)
						continue -- Skip to the next iteration
					end
				end

				-- 3. MOVEMENT EXECUTION: Follow the current path.
				if currentWaypoints and currentWaypoints[currentWaypointIndex] then
					local waypoint = currentWaypoints[currentWaypointIndex]
					humanoid:MoveTo(waypoint.Position)

					-- If the path requires a jump, make the humanoid jump
					if waypoint.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end
				else
					-- Fallback if something is wrong with the path
					humanoid:MoveTo(targetPos)
				end
			end
		end
	end)

	humanoid.Died:Connect(function()
		-- Cabut highlight saat mati supaya mayat tidak ter-highlight
		local ch = zombie:FindFirstChild("ChamsHighlight")
		if ch then ch:Destroy() end
		-- Berikan 5000 BP kepada semua pemain yang masih hidup saat boss mati
		if zombie:FindFirstChild("IsBoss") then
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character and not player.Character:FindFirstChild("Knocked") then
					PointsSystem.AddPoints(player, 5000)
				end
			end
		end

		ZombieDiedEvent:Fire()
		-- credit killer (jika ada creator tag pada zombie)
		local creatorTag = zombie:FindFirstChild("creator")
		if creatorTag and creatorTag.Value and creatorTag.Value:IsA("Player") then
			if PointsSystem and PointsSystem.AddKill then
				PointsSystem.AddKill(creatorTag.Value)
			end
		end
		task.wait(5)
		if zombie and zombie.Parent then zombie:Destroy() end

		-- NEW: Stop boss timer when boss dies
		BossTimerEvent:FireAllClients(0, 0)
	end)

	return zombie
end

function ZombieModule.GetNearestPlayer(zombie)
	local closestPlayer = nil
	local closestDistance = math.huge

	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character
			and player.Character:FindFirstChild("HumanoidRootPart")
			and not player.Character:FindFirstChild("Knocked") then

			local dist = (player.Character.HumanoidRootPart.Position - zombie.PrimaryPart.Position).Magnitude
			if dist < closestDistance then
				closestDistance = dist
				closestPlayer = player
			end
		end
	end
	return closestPlayer
end

return ZombieModule
