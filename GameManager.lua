-- GameManager.lua (Script)
-- Path: ServerScriptService/Script/GameManager.lua
-- Script Place: ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local BindableEvents = game.ReplicatedStorage.BindableEvents
local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local PlaceData = require(ModuleScriptServerScriptService:WaitForChild("PlaceData"))
local SpawnerModule = require(ModuleScriptServerScriptService:WaitForChild("SpawnerModule"))
local BuildingManager = require(ModuleScriptServerScriptService:WaitForChild("BuildingModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local PerkHandler = require(ModuleScriptServerScriptService:WaitForChild("PerkModule"))

local WaveCountdownEvent = RemoteEvents:WaitForChild("WaveCountdownEvent")
local PlayerCountEvent   = RemoteEvents:WaitForChild("PlayerCountEvent")
local OpenStartUIEvent   = RemoteEvents:WaitForChild("OpenStartUIEvent")
local ReadyCountEvent    = RemoteEvents:WaitForChild("ReadyCountEvent")
local RestartGameEvent = RemoteEvents:WaitForChild("RestartGameEvent")
local StartGameEvent = RemoteEvents:WaitForChild("StartGameEvent")
local ExitGameEvent = RemoteEvents:WaitForChild("ExitGameEvent")
local WaveUpdateEvent = RemoteEvents:WaitForChild("WaveUpdateEvent")
local StartVoteCountdownEvent = RemoteEvents:WaitForChild("StartVoteCountdownEvent")
local StartVoteCanceledEvent  = RemoteEvents:WaitForChild("StartVoteCanceledEvent")
local CancelStartVoteEvent = RemoteEvents:WaitForChild("CancelStartVoteEvent")

local ZombieDiedEvent = BindableEvents:WaitForChild("ZombieDiedEvent")

-- Penanda sesi voting agar timer lama tidak 'menimpa' sesi baru
local currentVoteSession = 0
local zombiesToSpawn = 0
local zombiesKilled = 0
local chamsApplied = false
local wave = 1
local gameStarted = false
-- Token sesi untuk membatalkan loop lama
local runToken = 0
local activePlayers = 0
-- Kumpulan pemain yang sudah menekan YES
local readyPlayers = {}

local Lighting = game:GetService("Lighting")
-- Simpan nilai default lighting untuk dipulihkan nanti
local defaultLightingSettings = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient
}

-- >>> TRANSISI LIGHTING ANTAR-WAVE <<<
local TweenService = game:GetService("TweenService")

-- Preset target lighting
local DARK_SETTINGS = {
	Brightness = 0.25,
	ClockTime = 0,
	Ambient = Color3.new(0, 0, 0),
	OutdoorAmbient = Color3.new(0, 0, 0)
}

local BLOOD_SETTINGS = {
	Brightness = 0.5,
	ClockTime = 2,
	Ambient = Color3.fromRGB(64, 0, 0),
	OutdoorAmbient = Color3.fromRGB(128, 0, 0)
}

local function tweenLightingTo(targetSettings, duration)
	duration = duration or 10
	-- Siapkan goal dari settings table
	local goal = {
		Brightness = targetSettings.Brightness,
		ClockTime = targetSettings.ClockTime,
		Ambient = targetSettings.Ambient,
		OutdoorAmbient = targetSettings.OutdoorAmbient
	}

	-- Cek apakah ClockTime perlu "memutar" ke depan
	if goal.ClockTime < Lighting.ClockTime then
		goal.ClockTime = goal.ClockTime + 24 -- Tambah 24 jam agar tween berjalan maju
	end

	-- Tween halus (Sine InOut)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, goal):Play()
end
-- <<< END TRANSISI LIGHTING >>>

-- Interval wave gelap (kelipatan wave). Ubah angka ini sesuai keinginan
-- Dengan interval 2, pemain memainkan satu wave siang (normal) dan satu wave malam (dark).
local DarkWaveInterval = 2

local BloodMoonChance = 0.3 -- 30% peluang Blood Moon pada dark wave
local BloodMoonSpawnMultiplier = 1.5 -- zombie spawn 50% lebih banyak saat Blood Moon

-- Fungsi untuk menerapkan efek Blood Moon
local function applyBloodMoon()
	-- Gunakan ambient merah gelap untuk suasana seram
	Lighting.Brightness = 0.5
	Lighting.ClockTime = 2 -- senja/malam merah
	Lighting.Ambient = Color3.fromRGB(64, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 0, 0)
end

-- Fungsi untuk menerapkan efek gelap
local function applyDarkWave()
	-- Set pencahayaan malam dengan brightness rendah
	Lighting.Brightness = 0.25
	Lighting.ClockTime = 0 -- tengah malam
	Lighting.Ambient = Color3.new(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
end

-- Fungsi untuk memulihkan lighting ke kondisi awal
local function restoreLighting()
	Lighting.Brightness = defaultLightingSettings.Brightness
	Lighting.ClockTime = defaultLightingSettings.ClockTime
	Lighting.Ambient = defaultLightingSettings.Ambient
	Lighting.OutdoorAmbient = defaultLightingSettings.OutdoorAmbient
end

local function ApplyChamsToZombies()
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("IsZombie") and not m:FindFirstChild("IsBoss") then
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				-- Hanya zombie yang masih hidup yang diberi highlight
				if not m:FindFirstChild("ChamsHighlight") then
					local h = Instance.new("Highlight")
					h.Name = "ChamsHighlight"
					h.FillTransparency = 1 -- hanya outline
					h.OutlineTransparency = 0
					h.OutlineColor = Color3.fromRGB(0, 255, 0) -- hijau
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- tembus tembok
					h.Parent = m
				end
			else
				-- Jika mayat masih tersisa dan sempat punya highlight, cabut supaya tidak ikut ter-highlight
				local h = m:FindFirstChild("ChamsHighlight")
				if h then h:Destroy() end
			end
		end
	end
end

local function ClearChams()
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("IsZombie") then
			local h = m:FindFirstChild("ChamsHighlight")
			if h then h:Destroy() end
		end
	end
end

-- Fungsi untuk menghitung pemain aktif
local function countActivePlayers()
	-- Di lobby/awal, Character bisa belum spawn → hitung taotal pemain saja
	if not gameStarted then
		return #game.Players:GetPlayers()
	end

	-- Saat game berjalan, hitung pemain yang benar-benar aktif (punya Character dan tidak Knocked)
	local count = 0
	for _, player in ipairs(game.Players:GetPlayers()) do
		if player.Character and not player.Character:FindFirstChild("Knocked") then
			count += 1
		end
	end
	return count
end


-- Fungsi update jumlah pemain ke semua client
local function updatePlayerCount()
	activePlayers = countActivePlayers()
	PlayerCountEvent:FireAllClients(activePlayers)
	return activePlayers
end

-- Fungsi reset game
local function ResetGame()
	gameStarted = false
	wave = 1
	zombiesKilled = 0
	-- Naikkan token agar loop lama segera berhenti
	runToken += 1

	-- Bersihkan semua zombie sisa sesi sebelumnya
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("IsZombie") then
			m:Destroy()
		end
	end

	restoreLighting() -- pastikan lighting balik normal saat reset
	ClearChams()
	-- Reset purchased elements
	ElementModule.ClearPurchasedElements()

	-- Reset perks, points & leaderstats untuk semua player
	for _, player in ipairs(game.Players:GetPlayers()) do
		PerkHandler.clearPlayerPerks(player)
		PointsSystem.SetupPlayer(player)
	end
end

-- Event zombie mati
ZombieDiedEvent.Event:Connect(function()
	-- Abaikan kill jika game tidak berjalan (hindari wave skip)
	if not gameStarted then return end
	zombiesKilled += 1
end)

-- Fungsi start loop game
local function startGameLoop()
	if gameStarted then return end
	gameStarted = true
	-- Buat sesi baru dan ikat loop ke sesi ini
	runToken += 1
	local myToken = runToken

	-- Update jumlah pemain
	activePlayers = updatePlayerCount()

	-- Tambahkan ini untuk menginisialisasi UI pada semua pemain saat game dimulai
	for _, plr in pairs(game.Players:GetPlayers()) do
		PointsSystem.AddPoints(plr, 0) -- Menginisialisasi poin dan menampilkan UI
	end

	task.spawn(function()
		while true do
			-- Stop cepat jika sesi diganti/di-reset
			if (myToken ~= runToken) or (not gameStarted) then break end

			print("Wave " .. wave .. " dimulai! Jumlah Pemain: " .. activePlayers)
			WaveUpdateEvent:FireAllClients(wave, activePlayers)
			local isDarkWave = false
			local isBloodMoonWave = false
			if DarkWaveInterval and DarkWaveInterval > 0 and (wave % DarkWaveInterval == 0) then
				isDarkWave = true
				-- Cek peluang Blood Moon di awal
				if BloodMoonChance and math.random() < BloodMoonChance then
					isBloodMoonWave = true
					print("Blood Moon wave! Memulai transisi ke dark lalu ke blood.")
					-- Transisi 2 tahap: Normal -> Dark -> Blood
					task.spawn(function()
						tweenLightingTo(DARK_SETTINGS, 5) -- 5 detik ke gelap
						task.wait(5)
						tweenLightingTo(BLOOD_SETTINGS, 5) -- 5 detik ke merah darah
					end)
				else
					print("Wave gelap! Memulai transisi ke dark.")
					-- Transisi 1 tahap: Normal -> Dark
					tweenLightingTo(DARK_SETTINGS, 10)
				end
			end

			-- Sesuaikan jumlah zombie berdasarkan jumlah pemain
			zombiesToSpawn = wave * 5 * activePlayers
			-- Pastikan jumlah pemain selalu up-to-date tiap awal wave
			activePlayers = updatePlayerCount()

			-- Modifikasi jumlah zombie saat Blood Moon: spawn lebih banyak
			if isBloodMoonWave and BloodMoonSpawnMultiplier and BloodMoonSpawnMultiplier > 1 then
				zombiesToSpawn = math.floor(zombiesToSpawn * BloodMoonSpawnMultiplier)
			end
			zombiesKilled = 0
			chamsApplied = false
			ClearChams()
			local isBossWave = SpawnerModule.SpawnWave(zombiesToSpawn, wave, activePlayers)
			print("Menunggu " .. zombiesToSpawn .. " zombie dikalahkan.")
			while zombiesKilled < zombiesToSpawn do
				local remaining = math.max(0, zombiesToSpawn - zombiesKilled)
				if (not chamsApplied) and remaining == 3 then
					chamsApplied = true
					ApplyChamsToZombies()
				end
				-- Jika sesi berubah saat menunggu, hentikan segera
				if (myToken ~= runToken) or (not gameStarted) then
					-- keluar dari coroutine agar loop lama benar-benar selesai
					return
				end

				task.wait(1)
			end
			print("Wave " .. wave .. " selesai!")
			-- Cek lagi sebelum memberi reward/lanjut wave
			if (myToken ~= runToken) or (not gameStarted) then break end

			if isBossWave then
				BuildingManager.restoreBuildings()
			end

			-- Jika ini Blood Moon atau wave gelap, kembalikan pencahayaan ke semula sebelum memberikan reward
			if isBloodMoonWave or isDarkWave then
				print("Wave khusus selesai. Memulihkan pencahayaan.")
			end

			-- Berikan 100 BP kepada setiap pemain yang masih hidup (tidak knocked)
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character and not player.Character:FindFirstChild("Knocked") then
					PointsSystem.AddPoints(player, 100)
					print(player.Name .. " mendapatkan 100 BP (Wave Bonus)!")
				end
			end

			-- NEW: Heal semua player 10% setiap naik wave
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character and not player.Character:FindFirstChild("Knocked") then
					local humanoid = player.Character:FindFirstChild("Humanoid")
					if humanoid then
						local healAmount = humanoid.MaxHealth * 0.1
						humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
						print(player.Name .. " mendapatkan heal 10% (Wave Heal)!")
					end
				end
			end

			-- Kirim countdown selama 10 detik
			-- Kirim countdown 10 detik + TRANSISI LIGHTING ke wave berikutnya
			local nextWave = wave + 1
			local nextIsDark = DarkWaveInterval and DarkWaveInterval > 0 and (nextWave % DarkWaveInterval == 0)

			-- Tentukan target lighting untuk WAVE BERIKUTNYA.
			-- Catatan: Blood Moon diacak saat wave mulai; untuk transisi kita pakai dark standar.
			local targetSettings
			if nextIsDark then
				targetSettings = DARK_SETTINGS
			else
				targetSettings = {
					Brightness = defaultLightingSettings.Brightness,
					ClockTime = defaultLightingSettings.ClockTime,
					Ambient = defaultLightingSettings.Ambient,
					OutdoorAmbient = defaultLightingSettings.OutdoorAmbient
				}
			end

			-- Mulai tween lighting selama 10 detik selagi countdown berjalan
			tweenLightingTo(targetSettings, 10)

			for count = 10, 1, -1 do
				WaveCountdownEvent:FireAllClients(count)
				task.wait(1)
			end
			WaveCountdownEvent:FireAllClients(0)
			task.wait(0.1)

			-- Hapus purchased elements yang belum diaktifkan untuk semua player
			ElementModule.ClearPurchasedElements()

			-- Update jumlah pemain untuk wave berikutnya
			activePlayers = updatePlayerCount()

			wave += 1
		end
	end)
end

-- Saat 1 pemain menekan YES -> tandai siap, broadcast progres, dan mulai jika semua siap
StartGameEvent.OnServerEvent:Connect(function(player)
	if gameStarted then return end

	readyPlayers[player.UserId] = true

	-- hitung progres
	local total = #game.Players:GetPlayers()
	local ready = 0
	for _, plr in ipairs(game.Players:GetPlayers()) do
		if readyPlayers[plr.UserId] then
			ready += 1
		end
	end

	-- broadcast "x/total" ke semua client
	ReadyCountEvent:FireAllClients(ready, total)

	-- kalau semua sudah siap -> mulai game & reset penanda
	if ready >= total then
		readyPlayers = {}
		print("Semua pemain siap. Memulai game...")
		-- Akhiri sesi voting agar timer berhenti
		currentVoteSession += 1
		startGameLoop()
	end
end)

-- NEW: jika satu pemain batalkan, hentikan sesi & reset untuk semua
CancelStartVoteEvent.OnServerEvent:Connect(function(player)
	if gameStarted then return end

	-- hentikan countdown sesi ini
	currentVoteSession += 1

	-- reset daftar siap
	readyPlayers = {}

	local total = #game.Players:GetPlayers()

	-- broadcast ke semua client: tutup UI + tampilkan nama pembatal
	local who = (player.DisplayName or player.Name)
	StartVoteCanceledEvent:FireAllClients(who)

	-- reset progres ready di UI
	ReadyCountEvent:FireAllClients(0, total)
end)

-- Debounce table untuk teleportasi
local teleportingPlayers = {}

-- Exit Game
ExitGameEvent.OnServerEvent:Connect(function(player)
	-- Cek debounce
	if teleportingPlayers[player.UserId] then
		warn("Player " .. player.Name .. " is already being teleported.")
		return
	end

	print(player.Name .. " memilih Exit")
	local lobbyId = PlaceData["Lobby"]

	if lobbyId then
		-- Set debounce
		teleportingPlayers[player.UserId] = true

		-- Panggil TeleportAsync dalam pcall
		local success, result = pcall(function()
			return TeleportService:TeleportAsync(lobbyId, {player})
		end)

		if success then
			print("Successfully initiated teleport for " .. player.Name .. " to Lobby (ID: " .. lobbyId .. ")")
		else
			warn("TeleportAsync failed for " .. player.Name .. ": " .. tostring(result))
		end

		-- Hapus debounce setelah beberapa saat, meskipun gagal
		task.delay(5, function()
			teleportingPlayers[player.UserId] = nil
		end)
	else
		warn("Lobby place ID not found in PlaceData.")
	end

	-- Reset game
	ResetGame()
end)

-- Update jumlah pemain ketika pemain bergabung atau keluar
game.Players.PlayerAdded:Connect(function(player)
	updatePlayerCount()
	-- inisialisasi leaderstats & points sementara saat join
	if PointsSystem and type(PointsSystem.SetupPlayer) == "function" then
		PointsSystem.SetupPlayer(player)
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	updatePlayerCount()
end)

-- Update jumlah pemain ketika status knocked berubah
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child.Name == "Knocked" then
				updatePlayerCount()
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child.Name == "Knocked" then
				updatePlayerCount()
			end
		end)
	end)
end)

-- Jika satu pemain meminta buka UI start, tampilkan ke semua client
OpenStartUIEvent.OnServerEvent:Connect(function(_player)
	if gameStarted then return end
	-- reset progres ready setiap kali sesi baru pemungutan siap dimulai
	readyPlayers = {}
	-- update total lalu broadcast tampilkan UI
	updatePlayerCount()
	ReadyCountEvent:FireAllClients(0, #game.Players:GetPlayers())
	OpenStartUIEvent:FireAllClients() -- client akan showFrame()
	-- Mulai sesi voting baru + timer 30 detik
	currentVoteSession += 1
	local mySession = currentVoteSession

	task.spawn(function()
		for t = 30, 0, -1 do
			-- Jika game sudah mulai atau sesi tergantikan, hentikan timer
			if gameStarted or currentVoteSession ~= mySession then
				return
			end
			StartVoteCountdownEvent:FireAllClients(t)
			task.wait(1)
		end

		-- Sampai sini: waktu habis. Jika belum mulai dan masih sesi ini, batalkan voting.
		if not gameStarted and currentVoteSession == mySession then
			-- Cek progres siap
			local total = #game.Players:GetPlayers()
			local ready = 0
			for _, plr in ipairs(game.Players:GetPlayers()) do
				if readyPlayers[plr.UserId] then
					ready += 1
				end
			end

			if ready < total then
				readyPlayers = {} -- reset daftar yang sudah siap
				StartVoteCanceledEvent:FireAllClients() -- minta client tutup UI & mulai lagi
				-- (opsional) kirim progres reset
				ReadyCountEvent:FireAllClients(0, total)
			end
		end
	end)
end)