-- src/server/init.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- ★設定モジュールを読み込む
local GameConfig = require(script:WaitForChild("GameConfig"))
local WEAPON_DATA = GameConfig.Weapons

local DEFAULT_WEAPON = "BouncyGun"

-- 音源ID
local SOUND_SHOOT = "rbxassetid://1194860475"
local SOUND_BOUNCE = "rbxassetid://9117581790"
local SOUND_HIT = "rbxassetid://123589129673882"
local SOUND_EMPTY = "rbxassetid://9117048518"
local SOUND_RELOAD = "rbxassetid://506273075"
local SOUND_SHIELD = "rbxassetid://12222076"

local cooldowns = {}
local guardCooldowns = {} -- ★シールドのクールダウン管理
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
local guardEvent = getRemote("GuardEvent") -- ★シールド用イベント

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

local function getCurrentWeaponStats(character)
	local tool = character:FindFirstChildOfClass("Tool")
	local weaponName = tool and tool.Name or DEFAULT_WEAPON
	return WEAPON_DATA[weaponName] or WEAPON_DATA[DEFAULT_WEAPON]
end

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
		local newStats = getCurrentWeaponStats(character)
		character:SetAttribute("Ammo", newStats.MaxAmmo)
		character:SetAttribute("MaxAmmo", newStats.MaxAmmo)
		character:SetAttribute("IsReloading", false)
	end
	reloadingStatus[player.UserId] = false
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("IsReady", false)
	-- ★追加: 初期状態ではシールドを持っていない
	player:SetAttribute("HasShield", false)

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

		-- ★追加: 死んで復活するたびにシールドを失うようにする
		player:SetAttribute("HasShield", false)
	end)
end)

readyEvent.OnServerEvent:Connect(function(player)
	player:SetAttribute("IsReady", true)
	player:LoadCharacter()
end)

reloadEvent.OnServerEvent:Connect(function(player)
	performReload(player)
end)

-- === ★シールドの展開処理 ===
guardEvent.OnServerEvent:Connect(function(player)
	if not player:GetAttribute("HasShield") then
		return
	end

	local char = player.Character
	if not char then
		return
	end

	local now = tick()
	if guardCooldowns[player.UserId] and (now - guardCooldowns[player.UserId] < GameConfig.Shield.Cooldown) then
		return -- クールダウン中
	end

	guardCooldowns[player.UserId] = now
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- シールドを作成
	local shield = Instance.new("Part")
	shield.Name = "PlayerShield"

	-- ★変更: ボールではなく、前方に展開する「フラットな壁（シールド）」に変更
	shield.Shape = Enum.PartType.Block
	shield.Size = Vector3.new(8, 6, 0.5)

	shield.Material = Enum.Material.Glass
	shield.Transparency = 0.7
	shield.Color = Color3.fromRGB(0, 255, 255)

	shield.CanCollide = false
	shield.Massless = true
	shield.CastShadow = false

	-- ★変更: キャラクターの3.5スタッド「前」に展開する
	shield.CFrame = hrp.CFrame * CFrame.new(0, 0, -3.5)

	-- ★重要: 1人称視点で透明化されないように Workspace に入れる
	shield.Parent = workspace

	-- ★重要: 誰のシールドか判定するためにAttribute(目印)をつける
	shield:SetAttribute("OwnerId", player.UserId)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = shield
	weld.Parent = shield

	Debris:AddItem(shield, GameConfig.Shield.Duration)
	playSound(SOUND_SHIELD, hrp, 1.0, 1.0)
end)

-- === 射撃処理 ===
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

	if cooldowns[player.UserId] and (now - cooldowns[player.UserId] < stats.FireCooldown) then
		return
	end

	local currentAmmo = character:GetAttribute("Ammo") or stats.MaxAmmo

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

	for i = 1, stats.BulletsPerShot do
		local spawnDirection = baseDirection

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
		bullet.Material = Enum.Material.Neon

		if stats.UseRandomColor then
			bullet.Color = Color3.fromHSV(math.random(), 1, 1)
		else
			bullet.Color = stats.BulletColor
		end

		bullet.Position = spawnPos
		bullet.CanCollide = true
		bullet.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.1, stats.Bounciness, 1.0, 1.0)

		local trail = Instance.new("Trail")
		local att0 = Instance.new("Attachment", bullet)
		att0.Position = Vector3.new(0, stats.BulletSize / 2, 0)
		local localAtt1 = Instance.new("Attachment", bullet)
		localAtt1.Position = Vector3.new(0, -stats.BulletSize / 2, 0)
		trail.Attachment0 = att0
		trail.Attachment1 = localAtt1
		trail.Lifetime = stats.TrailDuration
		trail.Color = ColorSequence.new(bullet.Color)
		trail.Parent = bullet

		bullet.Parent = workspace
		bullet.Velocity = spawnDirection * stats.BulletSpeed
		bullet:SetNetworkOwner(player)

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
			if not hit or not hit.Parent then
				return
			end

			-- === ★シールドに当たった場合の「反射」処理 ===
			if hit.Name == "PlayerShield" then
				local ownerId = hit:GetAttribute("OwnerId")
				if ownerId == player.UserId then
					return -- 自分のシールドはすり抜ける
				else
					-- 敵のシールドに当たった！
					local normal = hit.CFrame.LookVector -- シールドが向いている方向
					local currentVel = bullet.AssemblyLinearVelocity

					-- 弾がシールドの「正面」からぶつかった場合のみ反射する
					if currentVel:Dot(normal) < 0 then
						local reflectVel = currentVel - 2 * currentVel:Dot(normal) * normal
						bullet.AssemblyLinearVelocity = reflectVel * GameConfig.Shield.BounceMultiplier

						-- 反射された弾は白く光る！
						bullet.Color = Color3.fromRGB(255, 255, 255)
						trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
						playSound(SOUND_BOUNCE, bullet, 1.0, 1.5)
					end
					return
				end
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

				-- ★ここから下を変更！（ダメージ計算に倍率を掛け算する）
				local damageMult = character:GetAttribute("DamageMultiplier") or 1.0
				humanoid:TakeDamage(stats.Damage * damageMult)
				-- ★変更ここまで

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
