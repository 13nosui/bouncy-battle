local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local remoteEventName = "FireBullet"
local fireEvent = ReplicatedStorage:WaitForChild(remoteEventName)

-- === 設定: 照準（クロスヘア）のデザイン ===
local CROSSHAIR_IMAGE = "rbxassetid://128000667256203" -- 見やすい円形の照準
local CROSSHAIR_SIZE = 80 -- サイズ（ピクセル）大きくして見やすく

-- === 1. 照準GUIをコードで生成 ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrosshairGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.Enabled = false -- 最初は隠しておく

local crosshair = Instance.new("ImageLabel")
crosshair.Name = "Crosshair"
crosshair.Image = CROSSHAIR_IMAGE
crosshair.BackgroundTransparency = 1
crosshair.Size = UDim2.new(0, CROSSHAIR_SIZE, 0, CROSSHAIR_SIZE)
-- 画面のド真ん中に配置
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.Parent = screenGui

-- === 2. 銃を装備した時の処理 ===
local isEquipped = false

-- キャラクターが追加されるたびに監視
player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "BouncyGun" then
			-- 銃を持った！ -> 戦闘モードON
			isEquipped = true
			screenGui.Enabled = true
			UserInputService.MouseIconEnabled = false -- カーソルを消す
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter -- 視点固定
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == "BouncyGun" then
			-- 銃をしまった -> 通常モードOFF
			isEquipped = false
			screenGui.Enabled = false
			UserInputService.MouseIconEnabled = true -- カーソル復活
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- 固定解除
		end
	end)
end)

-- すでにキャラクターがいる場合の初期チェック
if player.Character then
	local tool = player.Character:FindFirstChild("BouncyGun")
	if tool then
		isEquipped = true
		screenGui.Enabled = true
		UserInputService.MouseIconEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

-- === 3. クリック処理（発射） ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and isEquipped then
		-- ★ここが重要：マウスの位置ではなく「カメラの中心」に向かって撃つ
		-- カメラから1000スタッド先をターゲットにする
		local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * 1000)

		-- もし目の前に壁があれば、そこをターゲットにする（Raycast）
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { player.Character } -- 自分は無視
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local rayResult = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 1000, rayParams)
		if rayResult then
			targetPos = rayResult.Position
		end

		fireEvent:FireServer(targetPos)
	end
end)

-- === 4. 強制ロック維持（メニューを開いた後などの対策） ===
RunService.RenderStepped:Connect(function()
	if isEquipped then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

print("Bouncy Battle: FPS/TPS Mode Loaded")
