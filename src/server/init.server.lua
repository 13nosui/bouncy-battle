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
local MAX_AMMO = 10
local RELOAD_TIME = 2.0

-- === 音源ID ===
local SOUND_SHOOT = "rbxassetid://1194860475" -- ポンッという軽い発射音
local SOUND_BOUNCE = "rbxassetid://9117581790" -- ビヨン（ゴムの跳ねる音）
local SOUND_HIT = "rbxassetid://123589129673882" -- ヒット音
local SOUND_EMPTY = "rbxassetid://9117048518" -- ★カチッ（弾切れ）
local SOUND_RELOAD = "rbxassetid://506273075" -- ★ジャキッ（リロード音）

local cooldowns = {}
local reloadingStatus = {}

local function getRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local fireEvent = getRemote("FireBullet")
local effectEvent = getRemote("PlayEffect")
local reloadEvent = getRemote("Reload")

local function playSound(soundId, parentPart, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = parentPart
	sound:Play()
	Debris:AddItem(sound, 2)
end

-- ★追加: 誰が攻撃したかを記録するタグ付け関数
local function tagHumanoid(humanoid, player)
	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Value = player
	creator_tag.Name = "creator"
	creator_tag.Parent = humanoid
	Debris:AddItem(creator_tag, 2) -- 2秒後に消える（死ぬ直前の攻撃だけ有効）
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:SetAttribute("Ammo", MAX_AMMO)
		character:SetAttribute("MaxAmmo", MAX_AMMO)
		character:SetAttribute("IsReloading", false)
	end)
end)

reloadEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then
		return
	end
	if reloadingStatus[player.UserId] then
		return
	end

	local current = character:GetAttribute("Ammo") or MAX_AMMO
	if current >= MAX_AMMO then
		return
	end

	reloadingStatus[player.UserId] = true
	character:SetAttribute("IsReloading", true)
	playSound(SOUND_RELOAD, character.Head, 1, 1)

	task.wait(RELOAD_TIME)

	if character then
		character:SetAttribute("Ammo", MAX_AMMO)
		character:SetAttribute("IsReloading", false)
	end
	reloadingStatus[player.UserId] = false
end)

fireEvent.OnServerEvent:Connect(function(player, mousePosition)
	local character = player.Character
	if not character then
		return
	end
	if reloadingStatus[player.UserId] then
		return
	end

	local now = tick()
	if cooldowns[player.UserId] and (now - cooldowns[player.UserId] < FIRE_COOLDOWN) then
		return
	end
	cooldowns[player.UserId] = now

	local currentAmmo = character:GetAttribute("Ammo") or MAX_AMMO
	if currentAmmo <= 0 then
		playSound(SOUND_EMPTY, character.Head, 1, 1)
		return
	end

	character:SetAttribute("Ammo", currentAmmo - 1)

	local tool = character:FindFirstChildOfClass("Tool")
	local muzzle = nil
	if tool and tool:FindFirstChild("Handle") then
		muzzle = tool.Handle:FindFirstChild("Muzzle")
	end

	local spawnPos
	local spawnDirection
	local sourcePart

	if muzzle then
		spawnPos = muzzle.WorldPosition
		spawnDirection = (mousePosition - spawnPos).Unit
		sourcePart = tool.Handle
		effectEvent:FireAllClients("Muzzle", tool.Handle)
	else
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end
		spawnDirection = (mousePosition - rootPart.Position).Unit
		spawnPos = rootPart.Position + spawnDirection * 5
		sourcePart = rootPart
	end

	playSound(SOUND_SHOOT, sourcePart, 0.5, 1.2)

	local bullet = Instance.new("Part")
	bullet.Name = "RubberBullet"
	bullet.Shape = Enum.PartType.Ball
	bullet.Size = Vector3.new(BULLET_SIZE, BULLET_SIZE, BULLET_SIZE)
	bullet.Color = Color3.fromHSV(math.random(), 1, 1)
	bullet.Material = Enum.Material.Neon
	bullet.Position = spawnPos
	bullet.CanCollide = true
	bullet.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.1, BOUNCINESS, 1.0, 1.0)

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

	local hasHitHumanoid = false
	local lastBounceTime = 0
	local canHitOwner = false

	bullet.Touched:Connect(function(hit)
		if hasHitHumanoid then
			return
		end
		if bullet.AssemblyLinearVelocity.Magnitude < 10 then
			return
		end

		local isOwner = hit:IsDescendantOf(character)

		if isOwner then
			if not canHitOwner then
				return
			end
		else
			canHitOwner = true
		end

		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			hasHitHumanoid = true

			-- ★追加: ダメージを与える前に「誰がやったか」をタグ付けする
			tagHumanoid(humanoid, player)

			humanoid:TakeDamage(DAMAGE)
			playSound(SOUND_HIT, hit, 1.0, 1.0)
			bullet:Destroy()
		else
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
