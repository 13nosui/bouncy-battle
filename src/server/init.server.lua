local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- === 設定値 ===
local BULLET_SIZE = 1.5
local BULLET_SPEED = 80
local BULLET_LIFE = 15
local BOUNCINESS = 1.0
local DAMAGE = 20
local FIRE_COOLDOWN = 0.5

-- === 音源ID (Roblox公式フリー素材) ===
local SOUND_SHOOT = "rbxassetid://2691586" -- ポンッという軽い発射音
local SOUND_BOUNCE = "rbxassetid://9117581790" -- ビヨン（ゴムの跳ねる音）
local SOUND_HIT = "rbxassetid://123589129673882" -- ヒット音

-- プレイヤーごとのクールダウン管理
local cooldowns = {}

-- RemoteEventの準備
local remoteEventName = "FireBullet"
local fireEvent = ReplicatedStorage:FindFirstChild(remoteEventName)
if not fireEvent then
	fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = remoteEventName
	fireEvent.Parent = ReplicatedStorage
end

-- 音を再生する便利関数
local function playSound(soundId, parentPart, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = parentPart
	sound:Play()
	Debris:AddItem(sound, 2) -- 鳴り終わったら消す
end

fireEvent.OnServerEvent:Connect(function(player, mousePosition)
	local character = player.Character
	if not character then
		return
	end

	-- 1. クールダウン判定
	local now = tick()
	if cooldowns[player.UserId] and (now - cooldowns[player.UserId] < FIRE_COOLDOWN) then
		return
	end
	cooldowns[player.UserId] = now

	-- 2. 発射位置の決定
	local tool = character:FindFirstChildOfClass("Tool")
	local muzzle = nil
	if tool and tool:FindFirstChild("Handle") then
		muzzle = tool.Handle:FindFirstChild("Muzzle")
	end

	local spawnPos
	local spawnDirection

	if muzzle then
		spawnPos = muzzle.WorldPosition
		spawnDirection = (mousePosition - spawnPos).Unit

		-- ★発射音を銃の位置で鳴らす
		playSound(SOUND_SHOOT, tool.Handle, 0.5, 1.2)
	else
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end
		spawnDirection = (mousePosition - rootPart.Position).Unit
		spawnPos = rootPart.Position + spawnDirection * 5
		playSound(SOUND_SHOOT, rootPart, 0.5, 1.2)
	end

	-- 3. 弾の生成
	local bullet = Instance.new("Part")
	bullet.Name = "RubberBullet"
	bullet.Shape = Enum.PartType.Ball
	bullet.Size = Vector3.new(BULLET_SIZE, BULLET_SIZE, BULLET_SIZE)
	bullet.Color = Color3.fromHSV(math.random(), 1, 1)
	bullet.Material = Enum.Material.Neon
	bullet.Position = spawnPos
	bullet.CanCollide = true

	local physicalProperties = PhysicalProperties.new(0.1, 0.1, BOUNCINESS, 1.0, 1.0)
	bullet.CustomPhysicalProperties = physicalProperties

	-- トレイル
	local trail = Instance.new("Trail")
	local att0 = Instance.new("Attachment", bullet)
	att0.Position = Vector3.new(0, 0.5, 0)
	local att1 = Instance.new("Attachment", bullet)
	att1.Position = Vector3.new(0, -0.5, 0)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.3
	trail.Color = ColorSequence.new(bullet.Color)
	trail.Parent = bullet

	bullet.Parent = workspace
	bullet.Velocity = spawnDirection * BULLET_SPEED

	bullet:SetNetworkOwner(player)

	-- 4. 衝突・ダメージ判定
	local hasHit = false

	bullet.Touched:Connect(function(hit)
		if hasHit then
			return
		end

		-- 人間に当たったか？
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			-- ヒット処理
			humanoid:TakeDamage(DAMAGE)
			hasHit = true
			playSound(SOUND_HIT, hit, 1.0, 1.0) -- 相手の体で音を鳴らす
			bullet:Destroy()
			print(player.Name .. " hit " .. hit.Parent.Name)
		else
			-- ★壁や床に当たった時：一定速度以上なら「跳ねる音」を鳴らす
			-- (スポーン直後の接触などで音が鳴りすぎないように速度チェック)
			if bullet.AssemblyLinearVelocity.Magnitude > 10 then
				-- 音が重なりすぎないよう、ピッチをランダムにして変化をつける
				local randomPitch = 0.8 + math.random() * 0.4
				playSound(SOUND_BOUNCE, bullet, 0.3, randomPitch)
			end
		end
	end)

	Debris:AddItem(bullet, BULLET_LIFE)
end)

print("Bouncy Battle: Sound FX Loaded")
