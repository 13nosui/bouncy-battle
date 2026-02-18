local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService") -- ★追加
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- === 設定値 ===
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

local WALL_JUMP_FORCE = 70
local WALL_KICK_FORCE = 80
local WALL_CHECK_DIST = 4
local WALL_JUMP_COOLDOWN = 0.5

local STAND_HIP_HEIGHT = 2
local CROUCH_HIP_HEIGHT = 0.5

-- === 状態管理 ===
local isSprinting = false
local isCrouching = false
local isSliding = false
local lastSlideTime = 0
local lastWallJumpTime = 0

-- === 1. カメラティルト ===
local currentTilt = 0
local function updateCameraTilt()
	local moveDir = humanoid.MoveDirection
	local rightVec = camera.CFrame.RightVector
	local dot = moveDir:Dot(rightVec)

	local targetTilt = 0
	if math.abs(dot) > 0.5 then
		targetTilt = (dot > 0) and -TILT_ANGLE or TILT_ANGLE
	end
	currentTilt = currentTilt + (targetTilt - currentTilt) * TILT_SPEED
	camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(currentTilt))
end

-- === 2. アクション処理 ===

local function updateMovementState()
	if isSliding then
		return
	end

	local targetSpeed = WALK_SPEED
	local targetFOV = BASE_FOV
	local targetHipHeight = STAND_HIP_HEIGHT

	if isCrouching then
		targetSpeed = CROUCH_SPEED
		targetHipHeight = CROUCH_HIP_HEIGHT
	elseif isSprinting then
		targetSpeed = RUN_SPEED
		targetFOV = RUN_FOV
	end

	humanoid.WalkSpeed = targetSpeed
	TweenService:Create(camera, TweenInfo.new(0.2), { FieldOfView = targetFOV }):Play()
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

	TweenService:Create(humanoid, TweenInfo.new(0.1), { HipHeight = CROUCH_HIP_HEIGHT }):Play()
	TweenService:Create(camera, TweenInfo.new(0.1), { FieldOfView = RUN_FOV + 10 }):Play()

	task.delay(SLIDE_DURATION, function()
		if slideVelocity then
			slideVelocity:Destroy()
		end
		isSliding = false

		if isSprinting then -- まだダッシュボタン押してたら
			isCrouching = false
		elseif isCrouching then -- しゃがみボタン押してたら
			isSprinting = false
		else
			isSprinting = false
			isCrouching = false
		end
		updateMovementState()
	end)
end

-- === 3. 入力バインド (PC & Mobile) ===

-- ダッシュ処理
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

-- しゃがみ/スライド処理
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

-- 初期設定
local function setupControls()
	-- PCキー + モバイルボタン(true) をバインド
	ContextActionService:BindAction("SprintAction", handleSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:BindAction("CrouchAction", handleCrouch, true, Enum.KeyCode.C, Enum.KeyCode.ButtonB)

	-- ボタン装飾
	local sprintBtn = ContextActionService:GetButton("SprintAction")
	if sprintBtn then
		ContextActionService:SetTitle("SprintAction", "DASH")
		-- 左手親指の上あたり
		ContextActionService:SetPosition("SprintAction", UDim2.new(0.15, 0, 0.6, 0))
	end

	local crouchBtn = ContextActionService:GetButton("CrouchAction")
	if crouchBtn then
		ContextActionService:SetTitle("CrouchAction", "SLIDE")
		-- 右手親指、リロードの横あたり
		ContextActionService:SetPosition("CrouchAction", UDim2.new(0.85, 0, 0.7, 0))
	end
end

setupControls()

-- === その他処理 ===

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")
	setupControls() -- キャラ復活時に再バインド
end)

RunService.RenderStepped:Connect(function()
	updateCameraTilt()
end)

-- 壁ジャンプ (PCスペースキー用)
-- モバイルのジャンプボタンはRoblox標準のものが右下にあります
UserInputService.JumpRequest:Connect(function()
	local now = tick()
	if now - lastWallJumpTime < WALL_JUMP_COOLDOWN then
		return
	end
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local rayOrigin = rootPart.Position
	local rayDirection = rootPart.CFrame.LookVector * WALL_CHECK_DIST
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, params)

	if rayResult then
		lastWallJumpTime = now
		local wallNormal = rayResult.Normal
		local jumpVelocity = (Vector3.new(0, 1, 0) * WALL_JUMP_FORCE) + (wallNormal * WALL_KICK_FORCE)
		rootPart.AssemblyLinearVelocity = jumpVelocity

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://108486895030065"
		sound.Volume = 1.0
		sound.Parent = rootPart
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 1)
	end
end)

print("Client: Mobile Ready Movement")
