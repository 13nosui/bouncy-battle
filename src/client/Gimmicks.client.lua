local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- === 設定値 ===
local WIND_FORCE_BULLET = 10.0
local WIND_FORCE_PLAYER = 10.0
local TRAMPOLINE_POWER = 120 -- 跳ねる強さ

local TAG_WIND = "WindZone"
local TAG_TRAMPOLINE = "Trampoline"

-- === 1. 風の処理 (継続的な力) ===
RunService.Heartbeat:Connect(function(deltaTime)
	local windZones = CollectionService:GetTagged(TAG_WIND)

	for _, zone in ipairs(windZones) do
		local partsInZone = Workspace:GetPartsInPart(zone)
		local windDirection = zone.CFrame.LookVector

		for _, part in ipairs(partsInZone) do
			if part.Name == "RubberBullet" then
				part.AssemblyLinearVelocity += windDirection * WIND_FORCE_BULLET
			elseif part.Parent == player.Character and part.Name == "HumanoidRootPart" then
				part.AssemblyLinearVelocity += windDirection * WIND_FORCE_PLAYER
			end
		end
	end
end)

-- === 2. トランポリンの処理 (瞬発的な力) ===
-- パーツが追加されたらTouchedイベントを設定する関数
local function setupTrampoline(part)
	part.Touched:Connect(function(hit)
		local char = player.Character
		if not char then
			return
		end
		local root = char:FindFirstChild("HumanoidRootPart")

		-- 自分自身が触れた場合のみ発動
		if hit.Parent == char and root then
			-- 既に跳んでいる最中に連続で判定が出ないように少し制御してもいいが、今回は単純に上書き
			-- 現在の移動速度(X, Z)は維持しつつ、Y軸(高さ)だけ書き換える
			local currentVel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(currentVel.X, TRAMPOLINE_POWER, currentVel.Z)

			-- 音を鳴らす
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://12222030" -- ボヨンという音
			sound.Volume = 0.5
			sound.Parent = root
			sound:Play()
			Debris:AddItem(sound, 1)
		end
	end)
end

-- 既存のトランポリンに適用
for _, part in ipairs(CollectionService:GetTagged(TAG_TRAMPOLINE)) do
	setupTrampoline(part)
end

-- 後から追加されたトランポリンにも適用
CollectionService:GetInstanceAddedSignal(TAG_TRAMPOLINE):Connect(setupTrampoline)

print("Client Gimmick System Loaded: Wind & Trampoline active")
