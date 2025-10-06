-- LobbyRoomManager.lua (Script)
-- Path: ServerScriptService/Script/LobbyRoomManager.lua
-- Script Place: Lobby

--==============================================================================
--// SERVICES & MODULES
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local PlaceData = require(script.Parent.Parent.ModuleScript.PlaceDataConfig)

--==============================================================================
--// NETWORKING
--==============================================================================

local lobbyRemote = Instance.new("RemoteEvent")
lobbyRemote.Name = "LobbyRemote"
lobbyRemote.Parent = ReplicatedStorage

--==============================================================================
--// STATE
--==============================================================================

--[[
    RoomData = {
        [roomId] = {
            Host = Player,
            Players = {Player},
            MaxPlayers = number,
            IsPrivate = boolean,
            RoomCode = string or nil,
            RoomId = string
        }
    }
]]
local rooms = {}

-- matchmakingQueues[playerCount] = {player1, player2, ...}
local matchmakingQueues = {}
local activeCountdowns = {}


--==============================================================================
--// UTILITY FUNCTIONS
--==============================================================================

-- Function to generate a unique room ID/code
local function generateRoomCode()
	-- Simple 5-digit code for now. In a real scenario, you'd want to ensure it's unique.
	return string.format("%05d", math.random(1, 99999))
end

-- Finds and returns the room data a specific player is in
local function getPlayerRoom(player)
	for roomId, roomData in pairs(rooms) do
		for _, p in ipairs(roomData.Players) do
			if p == player then
				return roomData
			end
		end
	end
	return nil
end

--==============================================================================
--// CORE LOGIC: ROOM & PLAYER MANAGEMENT
--==============================================================================

-- Sends updated room information to all players within that room
local function updateRoomInfo(roomData)
	local playersData = {}
	for _, p in ipairs(roomData.Players) do
		table.insert(playersData, {
			Name = p.Name,
			UserId = p.UserId
		})
	end

	local payload = {
		roomId = roomData.RoomId,
		hostName = roomData.Host.Name,
		players = playersData,
		maxPlayers = roomData.MaxPlayers
	}

	for _, p in ipairs(roomData.Players) do
		lobbyRemote:FireClient(p, "roomUpdate", payload)
	end
end

-- Sends an updated list of public rooms to all clients
local function broadcastPublicRoomsUpdate()
	local publicRooms = {}
	for id, data in pairs(rooms) do
		if not data.IsPrivate then
			publicRooms[id] = {
				playerCount = #data.Players,
				maxPlayers = data.MaxPlayers,
				hostName = data.Host.Name,
				roomId = data.RoomId
			}
		end
	end
	lobbyRemote:FireAllClients("publicRoomsUpdate", publicRooms)
end

-- Creates a new room
local function handleCreateRoom(hostPlayer, settings, initialPlayers)
	local maxPlayers = math.clamp(tonumber(settings.maxPlayers) or 4, 2, 8)
	local isPrivate = settings.isPrivate or false

	local roomId = generateRoomCode()
	while rooms[roomId] do
		roomId = generateRoomCode()
	end

	local playersInRoom = initialPlayers or {hostPlayer}

	local newRoom = {
		Host = hostPlayer,
		Players = playersInRoom,
		MaxPlayers = maxPlayers,
		IsPrivate = isPrivate,
		RoomCode = isPrivate and roomId or nil,
		RoomId = roomId
	}

	rooms[roomId] = newRoom
	print(string.format("Room created. ID: %s, Host: %s, Private: %s, Max Players: %d", roomId, hostPlayer.Name, tostring(isPrivate), maxPlayers))

	-- Fire back to the original host client if they created it manually
	if not initialPlayers then
		lobbyRemote:FireClient(hostPlayer, "roomCreated", {
			success = true,
			roomCode = newRoom.RoomCode,
			roomId = newRoom.RoomId
		})
	end

	if not newRoom.IsPrivate then
		broadcastPublicRoomsUpdate()
	end

	updateRoomInfo(newRoom)
	return roomId -- Return the ID for matchmaking
end

-- Handles a player joining an existing room
local function handleJoinRoom(player, joinData)
	if getPlayerRoom(player) then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "You are already in a room." })
		return
	end

	local roomIdToJoin = joinData.roomId or joinData.roomCode
	local room = rooms[roomIdToJoin]

	if not room then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "Room not found." })
		return
	end

	if joinData.roomCode and room.IsPrivate and room.RoomCode ~= joinData.roomCode then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "Invalid room code." })
		return
	end

	if #room.Players >= room.MaxPlayers then
		lobbyRemote:FireClient(player, "joinFailed", { reason = "Room is full." })
		return
	end

	table.insert(room.Players, player)
	print(string.format("Player %s joined room %s", player.Name, room.RoomId))

	lobbyRemote:FireClient(player, "joinSuccess", { roomId = room.RoomId })

	if not room.IsPrivate then
		broadcastPublicRoomsUpdate()
	end

	updateRoomInfo(room)

	if #room.Players >= room.MaxPlayers then
		startCountdown(room)
	end
end

-- Removes a player from any matchmaking queue they are in
local function handleCancelMatchmaking(player)
	for playerCount, queue in pairs(matchmakingQueues) do
		for i, p in ipairs(queue) do
			if p == player then
				table.remove(queue, i)
				print(string.format("Player %s cancelled matchmaking for %d players.", player.Name, playerCount))
				lobbyRemote:FireClient(player, "matchmakingCancelled")
				return
			end
		end
	end
end

-- Handles all logic when a player leaves the game
local function handlePlayerRemoving(player)
	-- Also remove from matchmaking queue if they are in one
	handleCancelMatchmaking(player)

	local roomData = getPlayerRoom(player)
	if roomData then
		local wasPrivate = roomData.IsPrivate
		local roomId = roomData.RoomId

		-- Find and remove the player
		for i, p in ipairs(roomData.Players) do
			if p == player then
				table.remove(roomData.Players, i)
				print(string.format("Player %s removed from room %s", player.Name, roomId))
				break
			end
		end

		-- Check if the room is now empty
		if #roomData.Players == 0 then
			print("Room " .. roomId .. " is empty, dissolving.")
			rooms[roomId] = nil
			if not wasPrivate then
				broadcastPublicRoomsUpdate()
			end
			return
		end

		-- Handle host migration
		if roomData.Host == player then
			roomData.Host = roomData.Players[1]
			print(string.format("Host migrated in room %s. New host is %s", roomId, roomData.Host.Name))
		end

		updateRoomInfo(roomData)
		if not wasPrivate then
			broadcastPublicRoomsUpdate()
		end
	end
end


--==============================================================================
--// CORE LOGIC: MATCHMAKING
--==============================================================================

-- Checks if a queue is full and, if so, creates a room for the players
local function checkForFullQueue(playerCount)
	local queue = matchmakingQueues[playerCount]
	if #queue >= playerCount then
		print(string.format("Full queue found for %d players. Creating room.", playerCount))

		local playersForGame = {}
		for i = 1, playerCount do
			table.insert(playersForGame, table.remove(queue, 1))
		end

		local settings = { maxPlayers = playerCount, isPrivate = true }
		local newRoomId = handleCreateRoom(playersForGame[1], settings, playersForGame)
		local newRoom = rooms[newRoomId]

		for _, p in ipairs(playersForGame) do
			if p then
				lobbyRemote:FireClient(p, "matchFound", { roomId = newRoomId })
			end
		end

		if newRoom and #newRoom.Players >= newRoom.MaxPlayers then
			startCountdown(newRoom)
		end
	end
end

-- Adds a player to a matchmaking queue
local function handleStartMatchmaking(player, data)
	local playerCount = math.clamp(tonumber(data.playerCount) or 4, 2, 8)

	if not matchmakingQueues[playerCount] then
		matchmakingQueues[playerCount] = {}
	end

	table.insert(matchmakingQueues[playerCount], player)
	print(string.format("Player %s entered matchmaking for %d players.", player.Name, playerCount))

	lobbyRemote:FireClient(player, "matchmakingStarted")
	checkForFullQueue(playerCount)
end

--==============================================================================
--// CORE LOGIC: GAME START & TELEPORTATION
--==============================================================================

-- Teleports a group of players to the game place
local function teleportPlayersToAct1(playersToTeleport)
	local act1Id = PlaceData["ACT 1: Village"]
	if not act1Id then
		warn("ACT 1 Place ID not found in PlaceData!")
		return
	end

	local success, result = pcall(function()
		return TeleportService:TeleportAsync(act1Id, playersToTeleport)
	end)

	if not success then
		warn("Failed to teleport players:", result)
	else
		print("Successfully initiated teleport for", #playersToTeleport, "players to ACT 1.")
	end
end

-- Starts the pre-game countdown for a given room
function startCountdown(room)
	local roomId = room.RoomId
	if activeCountdowns[roomId] then return end -- Already running

	activeCountdowns[roomId] = true
	print("Starting countdown for room:", roomId)

	task.spawn(function()
		for i = 10, 0, -1 do
			local currentRoom = rooms[roomId]
			if not currentRoom or #currentRoom.Players < currentRoom.MaxPlayers then
				print("Countdown cancelled for room:", roomId)
				activeCountdowns[roomId] = nil
				if currentRoom then
					for _, p in ipairs(currentRoom.Players) do
						lobbyRemote:FireClient(p, "countdownUpdate", { value = "Waiting for players..." })
					end
				end
				return -- Stop the countdown
			end

			for _, p in ipairs(currentRoom.Players) do
				lobbyRemote:FireClient(p, "countdownUpdate", { value = i })
			end

			if i == 0 then
				print("Countdown finished for room:", roomId, ". Teleporting players...")
				teleportPlayersToAct1(currentRoom.Players)
			end

			task.wait(1)
		end
		activeCountdowns[roomId] = nil
	end)
end


--==============================================================================
--// EVENT CONNECTIONS
--==============================================================================

-- Main server event handler
lobbyRemote.OnServerEvent:Connect(function(player, action, data)
	if action == "createRoom" then
		handleCreateRoom(player, data)
	elseif action == "getPublicRooms" then
		local publicRoomsData = {}
		for id, roomData in pairs(rooms) do
			if not roomData.IsPrivate then
				publicRoomsData[id] = {
					playerCount = #roomData.Players,
					maxPlayers = roomData.MaxPlayers,
					hostName = roomData.Host.Name,
					roomId = roomData.RoomId
				}
			end
		end
		lobbyRemote:FireClient(player, "publicRoomsUpdate", publicRoomsData)
	elseif action == "joinRoom" then
		handleJoinRoom(player, data)
	elseif action == "startMatchmaking" then
		handleStartMatchmaking(player, data)
	elseif action == "cancelMatchmaking" then
		handleCancelMatchmaking(player)
	elseif action == "startSoloGame" then
		print("Player", player.Name, "is starting a solo game.")
		teleportPlayersToAct1({player})
	else
		warn("Unknown action received: " .. tostring(action))
	end
end)

-- Connect the function to the PlayerRemoving event
Players.PlayerRemoving:Connect(handlePlayerRemoving)

--==============================================================================
--// INITIALIZATION
--==============================================================================

print("LobbyServer.lua loaded successfully.")
