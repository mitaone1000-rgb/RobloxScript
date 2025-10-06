-- DamageDisplay.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/DamageDisplay.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DamageDisplayEvent = ReplicatedStorage.RemoteEvents:WaitForChild("DamageDisplayEvent")

-- Fungsi yang diperbarui untuk menerima model zombi
local function createDamageDisplay(damage, zombieModel, isHeadshot)
    -- Validasi bahwa kita memiliki model dan memiliki bagian Head
    if not zombieModel or not zombieModel:IsA("Model") or not zombieModel:FindFirstChild("Head") then
        return
    end

    local zombieHead = zombieModel.Head

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Adornee = zombieHead
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    -- Mulai sedikit di atas kepala
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = zombieHead -- Jadikan Head sebagai induk untuk memastikan dibersihkan saat zombi dihancurkan

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = tostring(math.floor(damage))
    -- Merah untuk headshot, putih untuk tembakan biasa
    textLabel.TextColor3 = isHeadshot and Color3.new(1, 0.2, 0.2) or Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextStrokeTransparency = 0
    textLabel.BackgroundTransparency = 1
    textLabel.Parent = billboardGui

    -- Animasikan GUI melayang ke atas dan memudar
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Kita akan menganimasikan StudsOffset dari GUI dan TextTransparency dari label
    local goalOffset = { StudsOffset = Vector3.new(0, 7, 0) } -- Pindahkan ke atas sejauh 5 stud
    local goalFade = { TextStrokeTransparency = 1, TextTransparency = 1 }

    local tweenOffset = TweenService:Create(billboardGui, tweenInfo, goalOffset)
    local tweenFade = TweenService:Create(textLabel, tweenInfo, goalFade)

    tweenOffset:Play()
    tweenFade:Play()

    -- Gunakan Debris untuk membersihkan BillboardGui setelah animasi selesai
    Debris:AddItem(billboardGui, 1.1)
end

DamageDisplayEvent.OnClientEvent:Connect(createDamageDisplay)
