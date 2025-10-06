-- LobbyServer.lua (Script)
-- Path: ServerScriptService.LobbyServer
-- This script manages all server-side logic for the lobby system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- Module Scripts
local PlaceData = require(script.Parent.ModuleScript.PlaceData)

-- Remote Event for client-server communication
local lobbyRemote = Instance.new("RemoteEvent")
lobbyRemote.Name = "LobbyRemote"
lobbyRemote.Parent = ReplicatedStorage

-- Table to store all active rooms
--[[
    RoomData = {
        [roomId] = {
            Host = Player,
            Players = {Player},
            MaxPlayers = number,
            IsPrivate = boolean,
            RoomCode = string or nil
        }
    }
]]
local rooms = {}

-- Function to generate a unique room ID/code
local function generateRoomCode()
    -- Simple 5-digit code for now. In a real scenario, you'd want to ensure it's unique.
    return string.format("%05d", math.random(1, 99999))
end

-- Refactored to accept an optional list of players for matchmaking
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

    -- Update all players in the room with the initial info
    updateRoomInfo(newRoom)

    return roomId -- Return the ID for matchmaking
end

-- Function to get all public rooms and send them to clients
local function getPublicRooms()
    local publicRooms = {}
    for id, data in pairs(rooms) do
        if not data.IsPrivate then
            publicRooms[id] = {
                -- Don't send the full player objects
                playerCount = #data.Players,
                maxPlayers = data.MaxPlayers,
                hostName = data.Host.Name,
                roomId = data.RoomId
            }
        end
    end
    return publicRooms
end

local function broadcastPublicRoomsUpdate()
    local publicRooms = getPublicRooms()
    lobbyRemote:FireAllClients("publicRoomsUpdate", publicRooms)
end


-- Main server event handler
lobbyRemote.OnServerEvent:Connect(function(player, action, data)
    if action == "createRoom" then
        handleCreateRoom(player, data)
    elseif action == "getPublicRooms" then
        -- Send initial list to the player who just opened the menu
        lobbyRemote:FireClient(player, "publicRoomsUpdate", getPublicRooms())
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
    -- Also update the players in the room
    updateRoomInfo(room)

    -- Check if room is full to start countdown
    if #room.Players >= room.MaxPlayers then
        startCountdown(room)
    end
end

-- A table to hold players waiting for a match
-- matchmakingQueues[playerCount] = {player1, player2, ...}
local matchmakingQueues = {}
local activeCountdowns = {}

local function teleportPlayersToAct1(playersToTeleport)
    local act1Id = PlaceData["ACT 1: Village"]
    if not act1Id then
        warn("ACT 1 Place ID not found in PlaceData!")
        return
    end

    -- Using TeleportAsync for a better user experience with loading screens
    local success, result = pcall(function()
        return TeleportService:TeleportAsync(act1Id, playersToTeleport)
    end)

    if not success then
        warn("Failed to teleport players:", result)
    else
        print("Successfully initiated teleport for", #playersToTeleport, "players to ACT 1.")
    end
end

local function startCountdown(room)
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

local function handleStartMatchmaking(player, data)
    local playerCount = math.clamp(tonumber(data.playerCount) or 4, 2, 8)

    if not matchmakingQueues[playerCount] then
        matchmakingQueues[playerCount] = {}
    end

    -- Add player to the queue
    table.insert(matchmakingQueues[playerCount], player)
    print(string.format("Player %s entered matchmaking for %d players.", player.Name, playerCount))

    lobbyRemote:FireClient(player, "matchmakingStarted")

    checkForFullQueue(playerCount)
end


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

-- Function to handle player removal
local function handlePlayerRemoving(player)
    -- Also remove from matchmaking queue if they are in one
    handleCancelMatchmaking(player)

    local roomData = getPlayerRoom(player)
    if roomData then
        local wasPrivate = roomData.IsPrivate
        local roomId = roomData.RoomId

        -- Find and remove the player
        local playerIndex
        for i, p in ipairs(roomData.Players) do
            if p == player then
                playerIndex = i
                break
            end
        end
        if playerIndex then
            table.remove(roomData.Players, playerIndex)
            print(string.format("Player %s removed from room %s", player.Name, roomId))
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

-- Connect the function to the PlayerRemoving event
Players.PlayerRemoving:Connect(handlePlayerRemoving)

print("LobbyServer.lua loaded successfully.")