-- TeleportManager.lua (Script)
-- Path: ServerScriptService/Script/TeleportManager.lua
-- Script Place: Lobby, ACT 1: Village

-- Layanan yang diperlukan
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- Memuat data tempat dari ModuleScript
local PlaceData = require(script.Parent.Parent.ModuleScript.PlaceData)

-- Debounce table untuk teleportasi
local teleportingPlayers = {}

-- Fungsi untuk menangani teleportasi ketika ProximityPrompt dipicu
local function onTeleportTriggered(player, teleportPart)
	-- Cek debounce
	if teleportingPlayers[player.UserId] then
		warn("Player " .. player.Name .. " is already being teleported.")
		return
	end

	-- Dapatkan atribut "Tujuan" dari part
	local destinationName = teleportPart:GetAttribute("Tujuan")

	if not destinationName then
		warn("Part 'Teleport' di " .. teleportPart:GetFullName() .. " tidak memiliki atribut 'Tujuan'.")
		return
	end

	-- Dapatkan ID Tempat dari tabel PlaceData
	local placeId = PlaceData[destinationName]

	if not placeId then
		warn("Tujuan '" .. destinationName .. "' tidak ditemukan di PlaceData.")
		return
	end

	-- Set debounce
	teleportingPlayers[player.UserId] = true

	-- Panggil TeleportAsync dalam pcall
	local success, result = pcall(function()
		return TeleportService:TeleportAsync(placeId, {player})
	end)

	if success then
		print("Successfully initiated teleport for " .. player.Name .. " to '" .. destinationName .. "' (ID: " .. placeId .. ")")
	else
		warn("TeleportAsync failed for " .. player.Name .. " to '" .. destinationName .. "': " .. tostring(result))
	end

	-- Hapus debounce setelah beberapa saat, meskipun gagal
	task.delay(5, function()
		teleportingPlayers[player.UserId] = nil
	end)
end

-- Fungsi untuk menyiapkan ProximityPrompt pada sebuah part
local function setupTeleportPart(part)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		-- Hubungkan event 'Triggered' ke fungsi teleportasi
		prompt.Triggered:Connect(function(player)
			onTeleportTriggered(player, part)
		end)
		print("Menyiapkan ProximityPrompt untuk part: " .. part:GetFullName())
	else
		warn("Part 'Teleport' di " .. part:GetFullName() .. " tidak memiliki ProximityPrompt.")
	end
end

-- Cari semua part "Teleport" yang sudah ada di Workspace
for _, descendant in ipairs(workspace:GetDescendants()) do
	if descendant:IsA("BasePart") and descendant.Name == "Teleport" then
		setupTeleportPart(descendant)
	end
end

-- Dengarkan jika ada part "Teleport" baru yang ditambahkan
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") and descendant.Name == "Teleport" then
		setupTeleportPart(descendant)
	end
end)
