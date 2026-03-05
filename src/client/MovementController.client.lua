-- src/client/MovementController.client.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local WALK_SPEED = 16
local RUN_SPEED = 28
local CROUCH_SPEED = 8
local SLIDE_SPEED = 60
local SLIDE_DURATION = 0.6
local SLIDE_COOLDOWN = 1.0

local BASE_FOV = 70
local RUN_FOV = 85
local TILT_ANGLE = 3
local TILT_SPEED = 0.1

-- local WALL_JUMP_FORCE = 70
-- local WALL_KICK_FORCE = 80
-- local WALL_CHECK_DIST = 4
-- local WALL_JUMP_COOLDOWN = 0.5

local STAND_HIP_HEIGHT = 2
local CROUCH_HIP_HEIGHT = 0.5

local isSprinting = false
local isCrouching = false
local isSliding = false
local lastSlideTime = 0
-- local lastWallJumpTime = 0

local currentTilt = 0

-- ★修正: 常に最新の本物のカメラ(CurrentCamera)を使うように修正
local function updateCameraTilt()
	local currentCamera = workspace.CurrentCamera
	if not currentCamera then return end

	local moveDir = humanoid.MoveDirection
	local rightVec = currentCamera.CFrame.RightVector
	local dot = moveDir:Dot(rightVec)
	local targetTilt = 0
	if math.abs(dot) > 0.5 then
		targetTilt = (dot > 0) and -TILT_ANGLE or TILT_ANGLE
	end
	currentTilt = currentTilt + (targetTilt - currentTilt) * TILT_SPEED
	currentCamera.CFrame = currentCamera.CFrame * CFrame.Angles(0, 0, math.rad(currentTilt))
end

local function updateMovementState()
	if isSliding then
		return
	end

	local heightScale = 1.0
	local val = humanoid:FindFirstChild("BodyHeightScale")
	if val and val:IsA("NumberValue") then
		heightScale = val.Value
	end

	local targetSpeed = WALK_SPEED
	local targetFOV = BASE_FOV
	local targetHipHeight = STAND_HIP_HEIGHT * heightScale

	if isCrouching then
		targetSpeed = CROUCH_SPEED
		targetHipHeight = CROUCH_HIP_HEIGHT * heightScale
	elseif isSprinting then
		targetSpeed = RUN_SPEED
		targetFOV = RUN_FOV
	end

	local speedBoost = character:GetAttribute("SpeedBoostMultiplier") or 1
	targetSpeed = targetSpeed * speedBoost

	humanoid.WalkSpeed = targetSpeed
	
	-- ★修正: 最新のカメラにTweenを適用する
	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.2), { FieldOfView = targetFOV }):Play()
	TweenService:Create(humanoid, TweenInfo.new(0.2), { HipHeight = targetHipHeight }):Play()
end

local function startSlide()
	local now = tick()
	if now - lastSlideTime < SLIDE_COOLDOWN then
		return
	end
	if isSliding then
		return
	end
	if not isSprinting or humanoid.MoveDirection.Magnitude < 0.1 then
		isCrouching = true
		updateMovementState()
		return
	end

	isSliding = true
	lastSlideTime = now

	local slideVelocity = Instance.new("BodyVelocity")
	slideVelocity.Name = "SlideVelocity"
	slideVelocity.MaxForce = Vector3.new(100000, 0, 100000)
	slideVelocity.Velocity = rootPart.CFrame.LookVector * SLIDE_SPEED
	slideVelocity.Parent = rootPart

	local heightScale = 1.0
	local val = humanoid:FindFirstChild("BodyHeightScale")
	if val and val:IsA("NumberValue") then
		heightScale = val.Value
	end

	TweenService:Create(humanoid, TweenInfo.new(0.1), { HipHeight = CROUCH_HIP_HEIGHT * heightScale }):Play()
	-- ★修正: 最新のカメラにTweenを適用する
	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.1), { FieldOfView = RUN_FOV + 10 }):Play()

	task.delay(SLIDE_DURATION, function()
		if slideVelocity then
			slideVelocity:Destroy()
		end
		isSliding = false
		if isSprinting then
			isCrouching = false
		elseif isCrouching then
			isSprinting = false
		else
			isSprinting = false
			isCrouching = false
		end
		updateMovementState()
	end)
end

local function handleSprint(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		isSprinting = true
		if isCrouching then
			isCrouching = false
		end
		updateMovementState()
	elseif inputState == Enum.UserInputState.End then
		isSprinting = false
		updateMovementState()
	end
end

local function handleCrouch(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		if isSprinting then
			startSlide()
		else
			isCrouching = true
			updateMovementState()
		end
	elseif inputState == Enum.UserInputState.End then
		if not isSliding then
			isCrouching = false
			updateMovementState()
		end
	end
end

ContextActionService:BindAction("SprintAction", handleSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:BindAction("CrouchAction", handleCrouch, true, Enum.KeyCode.C, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("SprintAction", "DASH")
ContextActionService:SetTitle("CrouchAction", "SLIDE")

local function setupScaleListener(hum)
	local heightScaleVal = hum:WaitForChild("BodyHeightScale", 5)
	if heightScaleVal then
		heightScaleVal.Changed:Connect(function()
			if not isSliding then
				updateMovementState()
			end
		end)
	end
end

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")

	setupScaleListener(humanoid)

	newChar:GetAttributeChangedSignal("SpeedBoostMultiplier"):Connect(function()
		updateMovementState()
	end)
end)

if character then
	setupScaleListener(humanoid)
	character:GetAttributeChangedSignal("SpeedBoostMultiplier"):Connect(function()
		updateMovementState()
	end)
end

-- ==========================================
-- ★超重要修正: 試合中の時だけカメラを傾ける！
-- （これがないとロビーでもカメラが上書きされて右クリックが効かなくなります）
-- ==========================================
RunService.RenderStepped:Connect(function()
	if player:GetAttribute("InMatch") then
		updateCameraTilt()
	end
end)

-- ==========================================
-- ★変更: スライディング中の大ジャンプ（スライドジャンプ）
-- ==========================================
UserInputService.JumpRequest:Connect(function()
	-- もしスライディング中なら大ジャンプを発動！
	if isSliding then
		-- 1. スライディング状態を強制解除する
		isSliding = false
		isCrouching = false
		
		-- 前に押し出す力を消す
		local slideVel = rootPart:FindFirstChild("SlideVelocity")
		if slideVel then
			slideVel:Destroy()
		end
		
		-- カメラと姿勢を元に戻す
		updateMovementState()
		
		-- 2. 上方向へ強い力を加える（XとZの勢いはそのまま維持！）
		local currentVel = rootPart.AssemblyLinearVelocity
		-- ★ 80の部分が大ジャンプの高さです（通常のジャンプは50程度）。好みに合わせて調整してください！
		rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, 100, currentVel.Z)
		
		-- 3. 大ジャンプの気持ちいい効果音
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://108486895030065" -- 勢いのあるジャンプ音
		sound.Volume = 1.0
		sound.Parent = rootPart
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 1)
	end
end)