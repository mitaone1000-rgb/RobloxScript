-- SkillTreeManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SkillTreeManager.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Pindahkan LevelManager ke atas untuk akses
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local SkillTreeManager = {}

-- Konfigurasi Skill
local SKILL_CONFIG = {
    DamageHeadshot = {
        MaxLevel = 5
    }
}

-- Remote Events for Skill Tree
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpgradeSkillEvent = RemoteEvents:FindFirstChild("UpgradeSkillEvent") or Instance.new("RemoteEvent", RemoteEvents)
UpgradeSkillEvent.Name = "UpgradeSkillEvent"

local SkillDataUpdateEvent = RemoteEvents:FindFirstChild("SkillDataUpdateEvent") or Instance.new("RemoteEvent", RemoteEvents)
SkillDataUpdateEvent.Name = "SkillDataUpdateEvent"


-- Fungsi untuk meng-upgrade skill
function SkillTreeManager.UpgradeSkill(player, skillName)
    -- Dapatkan data terbaru dari LevelManager
    local data = LevelManager.GetData(player)

    if not data or not SKILL_CONFIG[skillName] then
        return false, "Invalid skill"
    end

    -- Inisialisasi jika belum ada
    data.SkillPoints = data.SkillPoints or 0
    data.Skills = data.Skills or { DamageHeadshot = 0 }
    data.Skills[skillName] = data.Skills[skillName] or 0

    if data.SkillPoints <= 0 then
        return false, "Not enough skill points"
    end

    local currentLevel = data.Skills[skillName]
    if currentLevel >= SKILL_CONFIG[skillName].MaxLevel then
        return false, "Skill is already at max level"
    end

    -- Proses upgrade
    data.SkillPoints = data.SkillPoints - 1
    data.Skills[skillName] = currentLevel + 1

    -- Simpan data baru melalui DataStoreManager dengan scope Stats
    DataStoreManager.SaveData(player, "Stats", data)

    -- Kirim data terbaru ke client
    SkillDataUpdateEvent:FireClient(player, data)

    return true, "Skill upgraded successfully"
end

-- Listener untuk event upgrade dari client
UpgradeSkillEvent.OnServerEvent:Connect(function(player, skillName)
    SkillTreeManager.UpgradeSkill(player, skillName)
end)

-- Kirim data awal saat pemain bergabung
local function onPlayerAdded(player)
    task.wait(1) -- Beri waktu sedikit agar UI client siap
    local data = LevelManager.GetData(player)
    SkillDataUpdateEvent:FireClient(player, data)
end

Players.PlayerAdded:Connect(onPlayerAdded)

return SkillTreeManager