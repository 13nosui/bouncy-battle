local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- === 武器の設定データ (WEAPON_DATA) ===
local WEAPON_DATA = {
	["BouncyGun"] = {
		BulletSize = 1.5,
		BulletSpeed = 150,
		BulletGravity = 0.1,
		BulletLife = 15,
		Bounciness = 1.0,
		Damage = 20,
		FireCooldown = 0.5,
		MaxAmmo = 10,
		ReloadTime = 2.0,
		BulletsPerShot = 1, -- 一度に発射する弾数
		SpreadAngle = 0, -- 弾の拡散角度（ブレ）
	},
	["BouncyShotgun"] = {
		BulletSize = 1.0,
		BulletSpeed = 120,
		BulletGravity = 0.3, -- 重力が少し強い（早く落ちる）
		BulletLife = 5, -- 5秒で消滅（近距離用）
		Bounciness = 0.8,
		Damage = 10, -- 1発のダメージは低い
		FireCooldown = 1.0, -- 連射は遅い
		MaxAmmo = 5,
		ReloadTime = 2.5,
		BulletsPerShot = 5, -- 一度に5発発射！
		SpreadAngle = 15, -- 15度ばらける
	},
	["BouncySMG"] = {
		BulletSize = 0.8, -- 弾が小さい
		BulletSpeed = 180, -- 弾速が速い
		BulletGravity = 0.05,
		BulletLife = 8,
		Bounciness = 1.2, -- よく跳ねる
		Damage = 8,
		FireCooldown = 0.12, -- 超連射！
		MaxAmmo = 30,
		ReloadTime = 1.5,
		BulletsPerShot = 1,
		SpreadAngle = 5, -- 連射すると少しブレる
	},
}

-- 見つからなかった場合のデフォルト武器
local DEFAULT_WEAPON = "BouncyGun"

-- === 音源ID ===
local SOUND_SHOOT = "rbxassetid://1194860475"
local SOUND_BOUNCE = "rbxassetid://9117581790"
local SOUND_HIT = "rbxassetid://123589129673882"
local SOUND_EMPTY = "rbxassetid://9117048518"
local SOUND_RELOAD = "rbxassetid://506273075"

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
local readyEvent = getRemote("PlayerReady")

local function playSound(soundId, parentPart, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = parentPart
	sound:Play()
	Debris:AddItem(sound, 2)
end

local function tagHumanoid(humanoid, player)
	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Value = player
	creator_tag.Name = "creator"
	creator_tag.Parent = humanoid
	Debris:AddItem(creator_tag, 2)
end

-- プレイヤーが持っている武器のステータスを取得する関数
local function getCurrentWeaponStats(character)
	local tool = character:FindFirstChildOfClass("Tool")
	local weaponName = tool and tool.Name or DEFAULT_WEAPON
	return WEAPON_DATA[weaponName] or WEAPON_DATA[DEFAULT_WEAPON]
end

-- 共通リロード処理
local function performReload(player)
	local character = player.Character
	if not character then
		return
	end
	if reloadingStatus[player.UserId] then
		return
	end

	local stats = getCurrentWeaponStats(character)
	local current = character:GetAttribute("Ammo") or stats.MaxAmmo

	if current >= stats.MaxAmmo then
		return
	end

	reloadingStatus[player.UserId] = true
	character:SetAttribute("IsReloading", true)
	character:SetAttribute("EmptyClicked", false)

	playSound(SOUND_RELOAD, character.Head, 1, 1)

	task.wait(stats.ReloadTime)

	if character then
		-- 待ち時間の間に武器を持ち替えている可能性があるので再度取得
		local newStats = getCurrentWeaponStats(character)
		character:SetAttribute("Ammo", newStats.MaxAmmo)
		character:SetAttribute("MaxAmmo", newStats.MaxAmmo)
		character:SetAttribute("IsReloading", false)
	end
	reloadingStatus[player.UserId] = false
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("IsReady", false)

	player.CharacterAdded:Connect(function(character)
		local healthScript = character:WaitForChild("Health", 5)
		if healthScript then
			healthScript:Destroy()
		end

		local defaultStats = WEAPON_DATA[DEFAULT_WEAPON]
		character:SetAttribute("Ammo", defaultStats.MaxAmmo)
		character:SetAttribute("MaxAmmo", defaultStats.MaxAmmo)
		character:SetAttribute("IsReloading", false)
		character:SetAttribute("EmptyClicked", false)
	end)
end)

readyEvent.OnServerEvent:Connect(function(player)
	player:SetAttribute("IsReady", true)
	player:LoadCharacter()
end)

reloadEvent.OnServerEvent:Connect(function(player)
	performReload(player)
end)

-- 発射処理
fireEvent.OnServerEvent:Connect(function(player, mousePosition)
	if not player:GetAttribute("IsReady") then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	if reloadingStatus[player.UserId] then
		return
	end

	local stats = getCurrentWeaponStats(character)
	local now = tick()

	-- クールダウン（連射速度）の判定
	if cooldowns[player.UserId] and (now - cooldowns[player.UserId] < stats.FireCooldown) then
		return
	end

	local currentAmmo = character:GetAttribute("Ammo") or stats.MaxAmmo

	-- 残弾ゼロの処理
	if currentAmmo <= 0 then
		local hasEmptyClicked = character:GetAttribute("EmptyClicked") == true
		if not hasEmptyClicked then
			playSound(SOUND_EMPTY, character.Head, 1, 1)
			character:SetAttribute("EmptyClicked", true)
			cooldowns[player.UserId] = now
		else
			performReload(player)
		end
		return
	end

	cooldowns[player.UserId] = now
	character:SetAttribute("Ammo", currentAmmo - 1)
	character:SetAttribute("MaxAmmo", stats.MaxAmmo)
	character:SetAttribute("EmptyClicked", false)

	local tool = character:FindFirstChildOfClass("Tool")
	local muzzle = nil
	local sourcePart = character:FindFirstChild("HumanoidRootPart")
	local spawnPos = sourcePart and sourcePart.Position or Vector3.zero
	local baseDirection = Vector3.new(0, 0, -1)

	if tool and tool:FindFirstChild("Handle") then
		sourcePart = tool.Handle
		if sourcePart:FindFirstChild("Muzzle") then
			muzzle = sourcePart.Muzzle
		end
	end

	if muzzle then
		spawnPos = muzzle.WorldPosition
		baseDirection = (mousePosition - spawnPos).Unit
		effectEvent:FireAllClients("Muzzle", sourcePart)
	elseif sourcePart then
		baseDirection = (mousePosition - spawnPos).Unit
		spawnPos = spawnPos + baseDirection * 5
	end

	playSound(SOUND_SHOOT, sourcePart, 0.5, 1.2)

	-- ★複数弾（ショットガン等）に対応したループ発射
	for i = 1, stats.BulletsPerShot do
		local spawnDirection = baseDirection

		-- 拡散角度の計算
		if stats.SpreadAngle > 0 then
			local spreadRad = math.rad(stats.SpreadAngle)
			local randomAngles = CFrame.Angles(
				(math.random() - 0.5) * spreadRad,
				(math.random() - 0.5) * spreadRad,
				(math.random() - 0.5) * spreadRad
			)
			spawnDirection = (CFrame.new(Vector3.zero, baseDirection) * randomAngles).LookVector
		end

		local bullet = Instance.new("Part")
		bullet.Name = "RubberBullet"
		bullet.Shape = Enum.PartType.Ball
		bullet.Size = Vector3.new(stats.BulletSize, stats.BulletSize, stats.BulletSize)
		bullet.Color = Color3.fromHSV(math.random(), 1, 1)
		bullet.Material = Enum.Material.Neon
		bullet.Position = spawnPos
		bullet.CanCollide = true
		bullet.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.1, stats.Bounciness, 1.0, 1.0)

		local trail = Instance.new("Trail")
		local att0 = Instance.new("Attachment", bullet)
		att0.Position = Vector3.new(0, stats.BulletSize / 2, 0)
		local att1 = Instance.new("Attachment", bullet)
		att1.Position = Vector3.new(0, -stats.BulletSize / 2, 0)
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = 0.3
		trail.Color = ColorSequence.new(bullet.Color)
		trail.Parent = bullet

		bullet.Parent = workspace
		bullet.Velocity = spawnDirection * stats.BulletSpeed
		bullet:SetNetworkOwner(player)

		-- 重力の個別設定
		if stats.BulletGravity ~= 1 then
			local antiGravity = Instance.new("BodyForce")
			antiGravity.Force = Vector3.new(0, bullet:GetMass() * workspace.Gravity * (1 - stats.BulletGravity), 0)
			antiGravity.Parent = bullet
		end

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
				local targetPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
				if targetPlayer and player.Team and targetPlayer.Team == player.Team then
					hasHitHumanoid = true
					bullet:Destroy()
					return
				end

				hasHitHumanoid = true
				tagHumanoid(humanoid, player)
				humanoid:TakeDamage(stats.Damage)
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

		Debris:AddItem(bullet, stats.BulletLife)
	end
end)
