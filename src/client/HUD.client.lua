local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- 標準HPバー無効化
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- === デザイン設定 ===
local FONT = Enum.Font.GothamBlack -- カッコいい太字フォント
local BAR_COLOR_HIGH = Color3.fromRGB(80, 255, 120) -- 緑
local BAR_COLOR_MED = Color3.fromRGB(255, 200, 50) -- 黄
local BAR_COLOR_LOW = Color3.fromRGB(255, 60, 60) -- 赤
local NEON_CYAN = Color3.fromRGB(80, 240, 255)

-- UI生成
local gui = Instance.new("ScreenGui")
gui.Name = "GameHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
gui.IgnoreGuiInset = true
gui.Enabled = false

-- === ヘルパー関数: 枠線付きパネルを作る ===
local function createPanel(name, size, pos, anchor)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = pos
	frame.AnchorPoint = anchor or Vector2.new(0, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Parent = gui

	-- 角丸
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	-- 枠線
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Transparency = 0.8
	stroke.Parent = frame

	return frame
end

-- ▼▼ 1. スコア表示 (上部中央) ▼▼
local scoreFrame = createPanel("ScoreFrame", UDim2.new(0, 180, 0, 40), UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0))

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(1, 0, 1, 0)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "KILLS: 0 / 5"
scoreLabel.TextColor3 = Color3.new(1, 1, 1)
scoreLabel.Font = FONT
scoreLabel.TextSize = 22
scoreLabel.Parent = scoreFrame

-- ▼▼ 2. HPバー (左下) ▼▼
local healthContainer =
	createPanel("HealthContainer", UDim2.new(0, 320, 0, 50), UDim2.new(0, 20, 1, -20), Vector2.new(0, 1))

-- HPアイコン（文字）
local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(0, 50, 1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "HP"
hpLabel.TextColor3 = Color3.new(1, 1, 1)
hpLabel.Font = FONT
hpLabel.TextSize = 24
hpLabel.Parent = healthContainer

-- バーの背景
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -70, 0, 20)
barBg.Position = UDim2.new(0, 60, 0.5, 0)
barBg.AnchorPoint = Vector2.new(0, 0.5)
barBg.BackgroundColor3 = Color3.new(0, 0, 0)
barBg.BackgroundTransparency = 0.5
barBg.Parent = healthContainer
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

-- ダメージバー（赤いやつ：遅れて減る演出用）
local damageBar = Instance.new("Frame")
damageBar.Name = "DamageBar"
damageBar.Size = UDim2.new(1, 0, 1, 0)
damageBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
damageBar.BorderSizePixel = 0
damageBar.Parent = barBg
Instance.new("UICorner", damageBar).CornerRadius = UDim.new(1, 0)

-- メインHPバー
local healthBar = Instance.new("Frame")
healthBar.Name = "MainBar"
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = BAR_COLOR_HIGH
healthBar.BorderSizePixel = 0
healthBar.Parent = barBg
Instance.new("UICorner", healthBar).CornerRadius = UDim.new(1, 0)

-- グラデーション（光沢感）
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8)),
})
gradient.Rotation = 90
gradient.Parent = healthBar

-- HP数値テキスト
local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, 0, 1, 25) -- バーの上に表示
healthText.Position = UDim2.new(0, 0, -1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "100"
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.Font = FONT
healthText.TextSize = 18
healthText.TextXAlignment = Enum.TextXAlignment.Right
healthText.Parent = barBg

-- ▼▼ 3. 弾数表示 (右下) ▼▼
local ammoContainer =
	createPanel("AmmoContainer", UDim2.new(0, 160, 0, 80), UDim2.new(1, -20, 1, -20), Vector2.new(1, 1))

-- 残弾数（デカく！）
local currentAmmoText = Instance.new("TextLabel")
currentAmmoText.Name = "Current"
currentAmmoText.Size = UDim2.new(0.6, 0, 1, 0)
currentAmmoText.Position = UDim2.new(0, 0, 0, 0)
currentAmmoText.BackgroundTransparency = 1
currentAmmoText.Text = "10"
currentAmmoText.TextColor3 = NEON_CYAN
currentAmmoText.Font = FONT
currentAmmoText.TextSize = 60
currentAmmoText.Parent = ammoContainer

-- 最大弾数（小さく）
local maxAmmoText = Instance.new("TextLabel")
maxAmmoText.Name = "Max"
maxAmmoText.Size = UDim2.new(0.4, 0, 1, -15)
maxAmmoText.Position = UDim2.new(0.6, 0, 0, 10)
maxAmmoText.BackgroundTransparency = 1
maxAmmoText.Text = "/ 10"
maxAmmoText.TextColor3 = Color3.fromRGB(200, 200, 200)
maxAmmoText.Font = FONT
maxAmmoText.TextSize = 24
maxAmmoText.TextXAlignment = Enum.TextXAlignment.Left
maxAmmoText.Parent = ammoContainer

-- "AMMO" ラベル
local labelText = Instance.new("TextLabel")
labelText.Size = UDim2.new(0.4, 0, 0, 20)
labelText.Position = UDim2.new(0.6, 0, 1, -25)
labelText.BackgroundTransparency = 1
labelText.Text = "AMMO"
labelText.TextColor3 = Color3.fromRGB(150, 150, 150)
labelText.Font = FONT
labelText.TextSize = 12
labelText.TextXAlignment = Enum.TextXAlignment.Left
labelText.Parent = ammoContainer

-- ▼▼ 4. メッセージ表示 (中央) ▼▼
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(1, 0, 0, 100)
messageLabel.Position = UDim2.new(0, 0, 0.35, 0) -- 少し上に
messageLabel.BackgroundTransparency = 1
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.new(1, 1, 1)
messageLabel.TextStrokeTransparency = 0 -- 縁取りあり
messageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
messageLabel.Font = FONT
messageLabel.TextSize = 50
messageLabel.Parent = gui

-- === ロジック部分 ===

-- HP更新
local function updateHealth()
	if not humanoid then
		return
	end
	local health = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
	local max = humanoid.MaxHealth
	local ratio = health / max

	healthText.Text = math.floor(health)

	-- 色の決定
	local targetColor = BAR_COLOR_HIGH
	if ratio < 0.3 then
		targetColor = BAR_COLOR_LOW
	elseif ratio < 0.6 then
		targetColor = BAR_COLOR_MED
	end

	-- メインバーのアニメーション (素早く)
	TweenService:Create(healthBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0),
		BackgroundColor3 = targetColor,
	}):Play()

	-- ダメージバーのアニメーション (遅れて減る)
	task.delay(0.2, function()
		TweenService:Create(damageBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(ratio, 0, 1, 0),
		}):Play()
	end)
end

-- 弾数更新
local function updateAmmo()
	if not character then
		return
	end
	local current = character:GetAttribute("Ammo") or 10
	local max = character:GetAttribute("MaxAmmo") or 10
	local isReloading = character:GetAttribute("IsReloading")

	maxAmmoText.Text = "/ " .. max

	if isReloading then
		currentAmmoText.Text = "R"
		currentAmmoText.TextColor3 = Color3.fromRGB(255, 255, 100)
		currentAmmoText.TextSize = 40
	else
		currentAmmoText.Text = tostring(current)
		currentAmmoText.TextSize = 60
		if current == 0 then
			currentAmmoText.TextColor3 = Color3.fromRGB(255, 50, 50)
		else
			currentAmmoText.TextColor3 = NEON_CYAN
		end
	end
end

-- スコア更新
local function updateScore()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local kills = leaderstats:FindFirstChild("Kills")
		if kills then
			scoreLabel.Text = "KILLS: " .. kills.Value .. " / 5"
		end
	end
end

-- メッセージ受信
local messageEvent = ReplicatedStorage:WaitForChild("GameMessage", 5)
if messageEvent then
	messageEvent.OnClientEvent:Connect(function(text, color)
		messageLabel.Text = text
		messageLabel.TextColor3 = color or Color3.new(1, 1, 1)

		-- バウンドするようなアニメーション
		messageLabel.TextTransparency = 0
		messageLabel.TextStrokeTransparency = 0
		messageLabel.Position = UDim2.new(0, 0, 0.4, 0)

		local tweenIn = TweenService:Create(
			messageLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Bounce),
			{ Position = UDim2.new(0, 0, 0.35, 0) }
		)
		tweenIn:Play()

		task.delay(2.5, function()
			local tweenOut = TweenService:Create(
				messageLabel,
				TweenInfo.new(0.5),
				{ TextTransparency = 1, TextStrokeTransparency = 1 }
			)
			tweenOut:Play()
		end)
	end)
end

-- イベント接続
local function setupCharacter(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")

	humanoid.HealthChanged:Connect(updateHealth)
	updateHealth()

	newChar.AttributeChanged:Connect(updateAmmo)
	updateAmmo()
end

player.CharacterAdded:Connect(setupCharacter)
if character then
	setupCharacter(character)
end

local function setupLeaderstats()
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if leaderstats then
		local kills = leaderstats:WaitForChild("Kills", 5)
		if kills then
			kills.Changed:Connect(updateScore)
			updateScore()
		end
	end
end
setupLeaderstats()
