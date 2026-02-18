local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui") -- 追加: CoreGui制御用

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

-- ★追加: タイトル画面ではバックパック（ツールバー）を隠す
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
titleLabel.Position = UDim2.new(0, 0, 0.1, 0) -- ★変更: 少し上へ調整
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BOUNCY BATTLE"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextColor3 = Color3.fromRGB(80, 240, 255)
titleLabel.TextSize = 80
titleLabel.TextStrokeTransparency = 0
titleLabel.Parent = screenGui

-- サブタイトル
local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0.1, 0)
subLabel.Position = UDim2.new(0, 0, 0.4, 0) -- ★変更: タイトルの下に来るように調整
subLabel.BackgroundTransparency = 1
subLabel.Text = "CHAOTIC PHYSICS FPS"
subLabel.Font = Enum.Font.GothamBold
subLabel.TextColor3 = Color3.new(1, 1, 1)
subLabel.TextSize = 24
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
playButton.Parent = screenGui

-- ボタン装飾
local uiCorner = Instance.new("UICorner", playButton)
uiCorner.CornerRadius = UDim.new(0, 20)
local uiStroke = Instance.new("UIStroke", playButton)
uiStroke.Thickness = 4
uiStroke.Color = Color3.new(1, 1, 1)

-- ボタンアニメーション
playButton.MouseEnter:Connect(function()
	TweenService:Create(playButton, TweenInfo.new(0.1), { Size = UDim2.new(0, 270, 0, 90) }):Play()
end)
playButton.MouseLeave:Connect(function()
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

local function updateCamera()
	if not isTitleActive then
		return
	end

	angle = angle + 0.005
	local x = math.cos(angle) * CAMERA_DIST
	local z = math.sin(angle) * CAMERA_DIST

	local camPos = CAMERA_CENTER + Vector3.new(x, CAMERA_HEIGHT, z)

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(camPos, CAMERA_CENTER)
end

RunService.RenderStepped:Connect(updateCamera)

-- === ゲーム開始処理 ===
playButton.MouseButton1Click:Connect(function()
	isTitleActive = false

	-- UIを消すアニメーション
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bgFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(titleLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(subLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	local buttonTween = TweenService:Create(playButton, tweenInfo, { BackgroundTransparency = 1, TextTransparency = 1 })
	buttonTween:Play()

	-- アニメーション完了を待つ
	buttonTween.Completed:Wait()

	screenGui:Destroy()

	-- ★追加: ロビーに入るのでバックパックを表示に戻す
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

	-- カメラを戻す
	camera.CameraType = Enum.CameraType.Custom
end)
