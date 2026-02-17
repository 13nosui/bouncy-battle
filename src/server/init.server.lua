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

-- === 音源ID ===
local SOUND_SHOOT = "rbxassetid://124815381429574" -- ポンッという軽い発射音
local SOUND_BOUNCE = "rbxassetid://131916027000817" -- ビヨン（ゴムの跳ねる音）
local SOUND_HIT = "rbxassetid://123589129673882" -- ヒット音

local cooldowns = {}

local remoteEventName = "FireBullet"
local fireEvent = ReplicatedStorage:FindFirstChild(remoteEventName)
if not fireEvent then
	fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = remoteEventName
	fireEvent.Parent = ReplicatedStorage
end

local effectEventName = "PlayEffect"
local effectEvent = ReplicatedStorage:FindFirstChild(effectEventName)
if not effectEvent then
	effectEvent = Instance.new("RemoteEvent")
	effectEvent.Name = effectEventName
	effectEvent.Parent = ReplicatedStorage
end

local function playSound(soundId, parentPart, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = parentPart
	sound:Play()
	Debris:AddItem(sound, 2)
end

fireEvent.OnServerEvent:Connect(function(player, mousePosition)
	local character = player.Character
	if not character then
		return
	end

	local now = tick()
	if cooldowns[player.UserId] and (now - cooldowns[player.UserId] < FIRE_COOLDOWN) then
		return
	end
	cooldowns[player.UserId] = now

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
		playSound(SOUND_SHOOT, tool.Handle, 0.5, 1.2)
		effectEvent:FireAllClients("Muzzle", tool.Handle)
	else
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end
		spawnDirection = (mousePosition - rootPart.Position).Unit
		spawnPos = rootPart.Position + spawnDirection * 5
		playSound(SOUND_SHOOT, rootPart, 0.5, 1.2)
	end

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

	-- ★ここから修正：自爆判定ロジック
	local hasHitHumanoid = false
	local lastBounceTime = 0

	-- 「一度でも何かに当たったか？」を管理するフラグ
	local canHitOwner = false

	bullet.Touched:Connect(function(hit)
		if hasHitHumanoid then
			return
		end

		-- 速度が遅すぎる（転がらず止まっている）場合は判定しない
		if bullet.AssemblyLinearVelocity.Magnitude < 10 then
			return
		end

		-- 誰に当たったかチェック
		local isOwner = hit:IsDescendantOf(character)

		-- ★自爆制御
		if isOwner then
			-- まだ壁などに当たっていないなら、発射直後なので無視する
			if not canHitOwner then
				return
			end
			-- 壁に当たった後なら、自分でもダメージ処理へ進む
		else
			-- 自分以外（壁、床、敵）に当たった！
			-- これ以降、跳ね返って自分に当たったらダメージを受けるようにする
			canHitOwner = true
		end

		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			-- 人間（自分含む）に当たった時の処理
			hasHitHumanoid = true
			humanoid:TakeDamage(DAMAGE)
			playSound(SOUND_HIT, hit, 1.0, 1.0)

			-- 弾を消す
			bullet:Destroy()
			print(player.Name .. " hit " .. hit.Parent.Name)
		else
			-- 壁・床に当たった時の処理
			local t = tick()
			if t - lastBounceTime > 0.1 then
				lastBounceTime = t
				local randomPitch = 0.8 + math.random() * 0.4
				playSound(SOUND_BOUNCE, bullet, 0.3, randomPitch)
			end
		end
	end)

	Debris:AddItem(bullet, BULLET_LIFE)
end)

print("Server: Self-Damage Enabled (After Bounce)")
