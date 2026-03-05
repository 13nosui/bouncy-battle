-- src/client/DamageFeedback.client.lua
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- 設定
local DAMAGE_SOUND_ID = "rbxassetid://133994443620530" -- ヒット音
local FLASH_COLOR = Color3.fromRGB(200, 0, 0) -- 濃い血の赤色
local DANGER_THRESHOLD = 0.3 -- HPが30%以下でピンチ演出開始

-- GUI作成
local gui = Instance.new("ScreenGui")
gui.Name = "DamageEffectGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- ==========================================
-- ★修正: 画像読み込みエラーを完全に回避する「グラデーションFrame」の魔法！
-- ==========================================
-- 1. 左右のフチを赤くするフレーム
local flashFrameLR = Instance.new("Frame")
flashFrameLR.Size = UDim2.new(1, 0, 1, 0)
flashFrameLR.BackgroundColor3 = FLASH_COLOR
flashFrameLR.BackgroundTransparency = 1
flashFrameLR.BorderSizePixel = 0
flashFrameLR.Parent = gui

local gradientLR = Instance.new("UIGradient")
gradientLR.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0), -- 左端は濃い赤
	NumberSequenceKeypoint.new(0.15, 1), -- 少し進むと透明に
	NumberSequenceKeypoint.new(0.85, 1), -- 右端の手前まで透明
	NumberSequenceKeypoint.new(1, 0), -- 右端は濃い赤
})
gradientLR.Parent = flashFrameLR

-- 2. 上下のフチを赤くするフレーム
local flashFrameTB = Instance.new("Frame")
flashFrameTB.Size = UDim2.new(1, 0, 1, 0)
flashFrameTB.BackgroundColor3 = FLASH_COLOR
flashFrameTB.BackgroundTransparency = 1
flashFrameTB.BorderSizePixel = 0
flashFrameTB.Parent = gui

local gradientTB = Instance.new("UIGradient")
gradientTB.Rotation = 90 -- 縦方向にグラデーションを回転
gradientTB.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0), -- 上端は濃い赤
	NumberSequenceKeypoint.new(0.2, 1), -- 少し進むと透明に
	NumberSequenceKeypoint.new(0.8, 1), -- 下端の手前まで透明
	NumberSequenceKeypoint.new(1, 0), -- 下端は濃い赤
})
gradientTB.Parent = flashFrameTB

-- ピンチ時の「ドクン…ドクン…」という点滅アニメーション
local pulseInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local pulseTweenLR = TweenService:Create(flashFrameLR, pulseInfo, { BackgroundTransparency = 0.5 })
local pulseTweenTB = TweenService:Create(flashFrameTB, pulseInfo, { BackgroundTransparency = 0.5 })

local isPinching = false

-- ダメージ処理
local function onHealthChanged(newHealth, maxHealth, oldHealth, humanoid)
	-- 1. ピンチ状態（HP30%以下）の判定と、点滅のオンオフ
	local hpRatio = newHealth / maxHealth
	if hpRatio <= DANGER_THRESHOLD and newHealth > 0 then
		if not isPinching then
			isPinching = true
			pulseTweenLR:Play()
			pulseTweenTB:Play()
		end
	else
		if isPinching then
			isPinching = false
			pulseTweenLR:Cancel()
			pulseTweenTB:Cancel()
			TweenService:Create(flashFrameLR, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(flashFrameTB, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		end
	end

	-- 2. ダメージを受けた瞬間のフラッシュ演出
	if newHealth < oldHealth then
		local sound = Instance.new("Sound")
		sound.SoundId = DAMAGE_SOUND_ID
		sound.Volume = 0.5
		sound.Parent = player.PlayerGui
		sound:Play()
		Debris:AddItem(sound, 2)

		-- アニメーションを一時停止して一瞬濃くする
		pulseTweenLR:Cancel()
		pulseTweenTB:Cancel()
		flashFrameLR.BackgroundTransparency = 0.2
		flashFrameTB.BackgroundTransparency = 0.2

		local targetTransparency = isPinching and 0.5 or 1
		local flashOutLR =
			TweenService:Create(flashFrameLR, TweenInfo.new(0.4), { BackgroundTransparency = targetTransparency })
		local flashOutTB =
			TweenService:Create(flashFrameTB, TweenInfo.new(0.4), { BackgroundTransparency = targetTransparency })
		flashOutLR:Play()
		flashOutTB:Play()

		flashOutLR.Completed:Connect(function()
			if isPinching and humanoid.Health > 0 then
				pulseTweenLR:Play()
				pulseTweenTB:Play()
			end
		end)
	end
end

-- キャラクター更新の監視
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local lastHealth = humanoid.Health

	isPinching = false
	pulseTweenLR:Cancel()
	pulseTweenTB:Cancel()
	flashFrameLR.BackgroundTransparency = 1
	flashFrameTB.BackgroundTransparency = 1

	humanoid.HealthChanged:Connect(function(health)
		onHealthChanged(health, humanoid.MaxHealth, lastHealth, humanoid)
		lastHealth = health
	end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end
