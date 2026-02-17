local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- === 1. 標準の体力バーを無効化 ===
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- === 2. UIの生成 (ScreenGui) ===
local gui = Instance.new("ScreenGui")
gui.Name = "GameHUD"
gui.ResetOnSpawn = false -- リスポーンしても消さない
gui.Parent = player:WaitForChild("PlayerGui")

-- フォント設定
local FONT = Enum.Font.FredokaOne -- ポップなフォント

-- ▼▼ ヘルスバー (左下) ▼▼
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthFrame"
healthFrame.Size = UDim2.new(0, 300, 0, 30)
healthFrame.Position = UDim2.new(0, 20, 1, -50) -- 左下
healthFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- 背景：濃いグレー
healthFrame.BorderSizePixel = 0
healthFrame.Parent = gui

-- 角丸にする
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = healthFrame

-- 中身のバー
local healthBar = Instance.new("Frame")
healthBar.Name = "Bar"
healthBar.Size = UDim2.new(1, 0, 1, 0) -- 最初は満タン
healthBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127) -- 黄緑色
healthBar.BorderSizePixel = 0
healthBar.Parent = healthFrame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 8)
barCorner.Parent = healthBar

-- HPテキスト (数字)
local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "100 / 100"
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.Font = FONT
healthText.TextSize = 20
healthText.Parent = healthFrame

-- ▼▼ 弾数表示 (右下) ▼▼
local ammoFrame = Instance.new("Frame")
ammoFrame.Name = "AmmoFrame"
ammoFrame.Size = UDim2.new(0, 150, 0, 50)
ammoFrame.Position = UDim2.new(1, -170, 1, -60) -- 右下
ammoFrame.BackgroundColor3 = Color3.new(0, 0, 0)
ammoFrame.BackgroundTransparency = 0.5
ammoFrame.BorderSizePixel = 0
ammoFrame.Parent = gui

local ammoCorner = Instance.new("UICorner")
ammoCorner.CornerRadius = UDim.new(0, 8)
ammoCorner.Parent = ammoFrame

local ammoText = Instance.new("TextLabel")
ammoText.Name = "AmmoText"
ammoText.Size = UDim2.new(1, 0, 1, 0)
ammoText.BackgroundTransparency = 1
ammoText.Text = "∞ / ∞" -- 今は無限
ammoText.TextColor3 = Color3.fromRGB(100, 255, 255) -- 水色
ammoText.Font = FONT
ammoText.TextSize = 32
ammoText.Parent = ammoFrame

-- === 3. ロジック (更新処理) ===

local function updateHealth()
	if not humanoid then
		return
	end

	-- HPの割合計算
	local health = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
	local maxHealth = humanoid.MaxHealth
	local ratio = health / maxHealth

	-- テキスト更新
	healthText.Text = math.floor(health) .. " / " .. math.floor(maxHealth)

	-- バーの長さ更新 (Tweenで滑らかに)
	local goal = { Size = UDim2.new(ratio, 0, 1, 0) }
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(healthBar, tweenInfo, goal)
	tween:Play()

	-- 色の変化 (ピンチになると赤くする)
	if ratio > 0.5 then
		healthBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127) -- 緑
	elseif ratio > 0.2 then
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- オレンジ
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 85, 85) -- 赤
	end
end

-- イベント接続
local function onCharacterAdded(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")

	-- HPが変わったら更新
	humanoid.HealthChanged:Connect(updateHealth)
	updateHealth()
end

player.CharacterAdded:Connect(onCharacterAdded)

-- 初期実行
if humanoid then
	humanoid.HealthChanged:Connect(updateHealth)
	updateHealth()
end

print("Client: Custom HUD Loaded")
