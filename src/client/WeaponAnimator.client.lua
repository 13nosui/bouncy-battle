local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

-- ★ここにさっきコピーしたIDを入れる (例: "rbxassetid://123456789")
local ANIMATION_ID = "rbxassetid://102580514746799"

local holdTrack = nil

-- アニメーションの準備
local animation = Instance.new("Animation")
animation.AnimationId = ANIMATION_ID

-- 装備したとき
local function onEquip()
	if not holdTrack then
		holdTrack = animator:LoadAnimation(animation)
	end
	holdTrack:Play()
end

-- 外したとき
local function onUnequip()
	if holdTrack then
		holdTrack:Stop()
	end
end

-- ツール（銃）の監視
local function setupTool(tool)
	if tool:IsA("Tool") then
		tool.Equipped:Connect(onEquip)
		tool.Unequipped:Connect(onUnequip)
	end
end

player.Character.ChildAdded:Connect(setupTool)

-- すでに持っている場合
local currentTool = player.Character:FindFirstChildOfClass("Tool")
if currentTool then
	setupTool(currentTool)
	onEquip() -- すぐ再生
end
