local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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

local TILT_ANGLE = 3 -- 傾く角度（度）
local TILT_SPEED = 0.1 -- 傾きの滑らかさ

-- R15用の高さ設定
local STAND_HIP_HEIGHT = 2 -- 立っている時の足の長さ
local CROUCH_HIP_HEIGHT = 0.5 -- しゃがんだ時の足の長さ

-- === 状態管理 ===
local isSprinting = false
local isCrouching = false
local isSliding = false
local lastSlideTime = 0

-- === 1. カメラティルト (横移動で画面を傾ける) ===
local currentTilt = 0

local function updateCameraTilt()
	-- 移動入力の取得 (W, A, S, D)
	local moveDir = humanoid.MoveDirection
	local rightVec = camera.CFrame.RightVector

	-- カメラの右方向と、移動方向の内積を取る
	-- (右に動いていればプラス、左ならマイナスになる)
	local dot = moveDir:Dot(rightVec)

	-- 目標の傾き角度
	local targetTilt = 0
	if math.abs(dot) > 0.5 then -- 横移動している時だけ
		targetTilt = (dot > 0) and -TILT_ANGLE or TILT_ANGLE
	end

	-- 滑らかに補間 (Lerp)
	currentTilt = currentTilt + (targetTilt - currentTilt) * TILT_SPEED

	-- カメラに適用
	camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(currentTilt))
end

-- === 2. アクション処理 ===

-- 速度とFOVの更新
local function updateMovementState()
	if isSliding then
		return
	end -- スライディング中は制御しない

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

	-- 速度適用
	humanoid.WalkSpeed = targetSpeed

	-- FOV適用 (Tween)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
	TweenService:Create(camera, tweenInfo, { FieldOfView = targetFOV }):Play()

	-- しゃがみ高さ適用 (Tween)
	-- ※HipHeightを変えると足が埋まるので、擬似的に背が低くなる
	local heightTween = TweenService:Create(humanoid, tweenInfo, { HipHeight = targetHipHeight })
	heightTween:Play()
end

-- スライディング実行
local function startSlide()
	local now = tick()
	if now - lastSlideTime < SLIDE_COOLDOWN then
		return
	end
	if isSliding then
		return
	end

	-- 走っている時かつ、移動している時のみ
	if not isSprinting or humanoid.MoveDirection.Magnitude < 0.1 then
		-- 止まっているならただのしゃがみ
		isCrouching = true
		updateMovementState()
		return
	end

	isSliding = true
	lastSlideTime = now

	-- 音 (もしあれば)
	-- local sound = Instance.new("Sound", rootPart) ...

	-- 物理的な力を加える
	local slideVelocity = Instance.new("BodyVelocity")
	slideVelocity.Name = "SlideVelocity"
	slideVelocity.MaxForce = Vector3.new(100000, 0, 100000) -- Y軸は重力に任せる
	slideVelocity.Velocity = rootPart.CFrame.LookVector * SLIDE_SPEED
	slideVelocity.Parent = rootPart

	-- 姿勢を低くする
	local tweenInfo = TweenInfo.new(0.1)
	TweenService:Create(humanoid, tweenInfo, { HipHeight = CROUCH_HIP_HEIGHT }):Play()
	TweenService:Create(camera, tweenInfo, { FieldOfView = RUN_FOV + 10 }):Play() -- 更に疾走感

	-- 指定時間後に終了
	task.delay(SLIDE_DURATION, function()
		if slideVelocity then
			slideVelocity:Destroy()
		end
		isSliding = false

		-- スライディング後の状態復帰
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			isSprinting = true
			isCrouching = false
		elseif UserInputService:IsKeyDown(Enum.KeyCode.C) then
			isSprinting = false
			isCrouching = true
		else
			isSprinting = false
			isCrouching = false
		end
		updateMovementState()
	end)
end

-- === 3. 入力監視 ===

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- ダッシュ (Shift)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		if isCrouching then
			isCrouching = false
		end -- しゃがみ解除
		updateMovementState()
	end

	-- しゃがみ / スライディング (C)
	if input.KeyCode == Enum.KeyCode.C then
		if isSprinting then
			startSlide()
		else
			isCrouching = true
			updateMovementState()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	-- ダッシュ解除
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		updateMovementState()
	end

	-- しゃがみ解除
	if input.KeyCode == Enum.KeyCode.C then
		if not isSliding then
			isCrouching = false
			updateMovementState()
		end
	end
end)

-- キャラクターがリスポーンした時の再設定
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- 毎フレーム処理
RunService.RenderStepped:Connect(function()
	updateCameraTilt()
end)

print("Client: Advanced Movement Loaded")
