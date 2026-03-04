local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService") -- ★追加

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- イベント取得
local readyEvent = ReplicatedStorage:WaitForChild("PlayerReady", 10)
if not readyEvent then
	readyEvent = Instance.new("RemoteEvent")
	readyEvent.Name = "PlayerReady"
end

-- === UI作成 ===

-- タイトル画面ではバックパック（ツールバー）を隠す
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TitleScreenGui"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
bgFrame.BackgroundTransparency = 0.5
bgFrame.Parent = screenGui

-- タイトルロゴ
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BOUNCY BATTLE"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextColor3 = Color3.fromRGB(0, 161, 254)
titleLabel.TextSize = 80
titleLabel.TextStrokeTransparency = 0
titleLabel.Parent = screenGui

-- サブタイトル
local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0.1, 0)
subLabel.Position = UDim2.new(0, 0, 0.3, 0)
subLabel.BackgroundTransparency = 1
subLabel.Text = "CHAOTIC PHYSICS FPS"
subLabel.Font = Enum.Font.GothamBold
subLabel.TextColor3 = Color3.new(1, 1, 1)
subLabel.TextSize = 32
subLabel.TextStrokeTransparency = 0.5
subLabel.Parent = screenGui

-- PLAYボタン
local playButton = Instance.new("TextButton")
playButton.Size = UDim2.new(0, 250, 0, 80)
playButton.Position = UDim2.new(0.5, 0, 0.7, 0)
playButton.AnchorPoint = Vector2.new(0.5, 0.5)
playButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
playButton.Text = "PLAY"
playButton.Font = Enum.Font.GothamBlack
playButton.TextSize = 40
playButton.TextColor3 = Color3.new(0, 0, 0)
playButton.Selectable = true -- ★追加: コントローラーで選択可能にする
playButton.Parent = screenGui

-- ボタン装飾
local uiCorner = Instance.new("UICorner", playButton)
uiCorner.CornerRadius = UDim.new(0, 20)

-- ボタンアニメーション
playButton.MouseEnter:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.1), { Size = UDim2.new(0, 270, 0, 90) }):Play()
end)
playButton.MouseLeave:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.1), { Size = UDim2.new(0, 250, 0, 80) }):Play()
end)

-- ★修正: コントローラーで選択された時のデフォルトの青い枠線を完全に透明にする
local emptySelection = Instance.new("Frame")
emptySelection.BackgroundTransparency = 1
playButton.SelectionImageObject = emptySelection

playButton.SelectionGained:Connect(function()
	-- 選択されたら少し大きく
	TweenService:Create(playButton, TweenInfo.new(0.1), { Size = UDim2.new(0, 270, 0, 90) }):Play()
end)
playButton.SelectionLost:Connect(function()
	-- 選択が外れたら戻す
	TweenService:Create(playButton, TweenInfo.new(0.1), { Size = UDim2.new(0, 250, 0, 80) }):Play()
end)

-- === カメラ演出 ===
local isTitleActive = true
local angle = 0
local CAMERA_CENTER = Vector3.new(0, 5000, 0)
local CAMERA_DIST = 40
local CAMERA_HEIGHT = 20

local lobbySpawn = Workspace:FindFirstChild("LobbySpawn")
if lobbySpawn then
	CAMERA_CENTER = lobbySpawn.Position
end

local runConnection = nil

local function updateCamera()
	if not isTitleActive then
		-- タイトルが終わったら、カメラを回すループ処理自体を完全に破壊する
		if runConnection then
			runConnection:Disconnect()
			runConnection = nil
		end
		return
	end

	angle = angle + 0.005
	local x = math.cos(angle) * CAMERA_DIST
	local z = math.sin(angle) * CAMERA_DIST

	local camPos = CAMERA_CENTER + Vector3.new(x, CAMERA_HEIGHT, z)

	-- ★修正: 常に最新の本物のカメラを取得して回す
	local currentCam = Workspace.CurrentCamera
	currentCam.CameraType = Enum.CameraType.Scriptable
	currentCam.CFrame = CFrame.lookAt(camPos, CAMERA_CENTER)
end

runConnection = RunService.RenderStepped:Connect(updateCamera)

-- 起動時にコントローラーのフォーカスをPLAYボタンに合わせる
task.delay(0.5, function()
	if isTitleActive and screenGui.Parent then
		GuiService.SelectedObject = playButton
	end
end)

-- === ゲーム開始処理 ===
playButton.MouseButton1Click:Connect(function()
	if not isTitleActive then
		return
	end
	isTitleActive = false

	GuiService.SelectedObject = nil

	-- UIを消すアニメーション
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bgFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(titleLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(subLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	local buttonTween = TweenService:Create(playButton, tweenInfo, { BackgroundTransparency = 1, TextTransparency = 1 })
	buttonTween:Play()

	-- アニメーション完了を待つ
	buttonTween.Completed:Wait()

	-- ==========================================
	-- ★超重要修正: 完璧なカメラロック解除の手順（読み込み待ち追加版）
	-- ==========================================
	local realCamera = Workspace.CurrentCamera

	-- 手順1: キャラクターとHumanoidが完全に読み込まれるまで確実に待つ！
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	-- 手順2: 迷子にならないよう、確実に自分をターゲットにセット！
	realCamera.CameraSubject = humanoid

	-- 手順3: カメラをCustom（自由操作）に戻す！
	realCamera.CameraType = Enum.CameraType.Custom

	-- 手順4: 念押しでマウスのロック状態をデフォルトに戻す
	local UserInputService = game:GetService("UserInputService")
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	screenGui:Destroy()

	-- ロビーに入るのでバックパックを表示に戻す
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)

	-- サーバーに準備完了を通知
	readyEvent:FireServer()

	-- HUDを表示
	local hud = playerGui:FindFirstChild("GameHUD")
	if hud then
		hud.Enabled = true
	end
	
	-- ※一番下にあった古い camera.CameraType... のコードは削除しました！
end)
