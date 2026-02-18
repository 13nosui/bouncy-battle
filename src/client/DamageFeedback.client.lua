local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- 設定
-- 一旦、確実に鳴るRoblox標準のヒット音を入れています
local DAMAGE_SOUND_ID = "rbxassetid://12222084"
local FLASH_COLOR = Color3.fromRGB(255, 0, 0) -- 赤色

-- GUI作成
local gui = Instance.new("ScreenGui")
gui.Name = "DamageEffectGui"
gui.IgnoreGuiInset = true -- 画面の端まで覆う
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- ★変更: 画像(ImageLabel)ではなく、単純な色付きフレーム(Frame)を使用
-- これにより「画像読み込みエラー」で光らない問題を回避します
local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = FLASH_COLOR
flashFrame.BackgroundTransparency = 1 -- 最初は透明
flashFrame.BorderSizePixel = 0
flashFrame.Parent = gui

-- ダメージ処理
local function onHealthChanged(newHealth, maxHealth, oldHealth)
	-- HPが減った時だけ反応
	if newHealth < oldHealth then
		-- 1. 音を鳴らす
		local sound = Instance.new("Sound")
		sound.SoundId = DAMAGE_SOUND_ID
		sound.Volume = 0.5
		sound.Parent = player.PlayerGui
		sound:Play()
		Debris:AddItem(sound, 2)

		-- 2. 画面を赤くフラッシュさせる
		-- 一瞬で赤くして(0.05秒)、すぐに消す(0.3秒)
		local tweenIn = TweenService:Create(flashFrame, TweenInfo.new(0.05), { BackgroundTransparency = 0.5 }) -- 50%の赤さ
		local tweenOut = TweenService:Create(flashFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }) -- 透明に戻す

		tweenIn:Play()
		tweenIn.Completed:Connect(function()
			tweenOut:Play()
		end)
	end
end

-- キャラクター更新の監視
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(health)
		onHealthChanged(health, humanoid.MaxHealth, lastHealth)
		lastHealth = health
	end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end
