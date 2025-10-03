-- AnimateScript.lua (Server Script)
-- Path: ServerStorage/AllyNPC/AnimateScript.lua

local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")

local animTable = {}
local animNames = {
	idle = {
		{ id = "http://www.roblox.com/asset/?id=507766388", weight = 10 }
	},
	walk = {
		{ id = "http://www.roblox.com/asset/?id=507777826", weight = 10 }
	},
	run = {
		{ id = "http://www.roblox.com/asset/?id=507767714", weight = 10 }
	},
	toolnone = {
		{ id = "http://www.roblox.com/asset/?id=507768375", weight = 10 }
	},
}

local currentAnim = ""
local currentAnimTrack = nil

local function configureAnimationSet(name, fileList)
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0

	for idx, anim in pairs(fileList) do
		local newAnim = Instance.new("Animation")
		newAnim.Name = name
		newAnim.AnimationId = anim.id
		animTable[name][idx] = {
			anim = newAnim,
			weight = anim.weight
		}
		animTable[name].count = animTable[name].count + 1
		animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
	end
end

for name, fileList in pairs(animNames) do
	configureAnimationSet(name, fileList)
end

local function stopAllAnimations()
	if currentAnimTrack then
		currentAnimTrack:Stop(0.1)
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end
	currentAnim = ""
end

local function playAnimation(animName, transitionTime, humanoid)
	if currentAnim == animName then return end

	stopAllAnimations()

	local animSet = animTable[animName]
	if not animSet or animSet.count == 0 then
		warn("Animasi tidak ditemukan: " .. animName)
		return
	end

	local roll = math.random(1, animSet.totalWeight)
	local idx = 1
	while roll > animSet[idx].weight do
		roll = roll - animSet[idx].weight
		idx = idx + 1
	end

	local anim = animSet[idx].anim
	currentAnim = animName
	currentAnimTrack = humanoid:LoadAnimation(anim)
	currentAnimTrack:Play(transitionTime)
end

local function onRunning(speed)
	if speed > 0.1 then
		playAnimation("walk", 0.2, Humanoid)
	else
		playAnimation("idle", 0.2, Humanoid)
	end
end

Humanoid.Running:Connect(onRunning)

playAnimation("idle", 0.1, Humanoid)
