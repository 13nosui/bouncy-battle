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
local SOUND_EXPLODE = "rbxassetid://12222030"

local cooldowns = {}
local guardCooldowns = {}
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
local guardEvent = getRemote("GuardEvent")

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
	-- ★変更: HasShieldなどを廃止し、SlotQとSlotZを用意する
	player:SetAttribute("SlotQ", "")
	player:SetAttribute("SlotZ", "")

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

		-- ★修正: 復活してもスキルを没収しないように、SlotQとSlotZのリセット処理を削除しました！
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
	-- ★変更: Q枠かZ枠のどちらかにシールドがセットされているか確認
	local sq = player:GetAttribute("SlotQ")
	local sz = player:GetAttribute("SlotZ")
	if sq ~= "Energy Shield" and sz ~= "Energy Shield" then
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

	local shield = Instance.new("Part")
	shield.Name = "PlayerShield"
	shield.Shape = Enum.PartType.Block
	shield.Size = Vector3.new(8, 6, 0.5)
	shield.Material = Enum.Material.Glass
	shield.Transparency = 0.7
	shield.Color = Color3.fromRGB(0, 255, 255)
	shield.CanCollide = false
	shield.Massless = true
	shield.CastShadow = false

	shield.CFrame = hrp.CFrame * CFrame.new(0, 0, -3.5)
	shield.Parent = workspace
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

	if stats.IsExplosive then
		playSound(SOUND_SHOOT, sourcePart, 1.2, 0.6)
	else
		playSound(SOUND_SHOOT, sourcePart, 0.5, 1.2)
	end

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

			if not stats.IsExplosive and bullet.AssemblyLinearVelocity.Magnitude < 10 then
				return
			end

			if not hit or not hit.Parent then
				return
			end

			if hit.Name == "PlayerShield" then
				local ownerId = hit:GetAttribute("OwnerId")
				if ownerId == player.UserId then
					return
				else
					local normal = hit.CFrame.LookVector
					local currentVel = bullet.AssemblyLinearVelocity

					if currentVel:Dot(normal) < 0 then
						local reflectVel = currentVel - 2 * currentVel:Dot(normal) * normal
						bullet.AssemblyLinearVelocity = reflectVel * GameConfig.Shield.BounceMultiplier
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

			-- ==============================================
			-- ★爆発処理
			-- ==============================================
			if stats.IsExplosive then
				hasHitHumanoid = true
				playSound(SOUND_EXPLODE, bullet, 1.5, 0.8)

				local explosion = Instance.new("Explosion")
				explosion.Position = bullet.Position
				explosion.BlastRadius = stats.ExplosionRadius
				explosion.BlastPressure = 500000
				explosion.DestroyJointRadiusPercent = 0
				explosion.Visible = false
				explosion.Parent = workspace

				effectEvent:FireAllClients("RubberExplosion", {
					Position = bullet.Position,
					Color = bullet.Color,
				})

				local CLUSTER_COUNT = 15
				local CLUSTER_DAMAGE = 15

				for j = 1, CLUSTER_COUNT do
					local mini = Instance.new("Part")
					mini.Name = "RubberBullet"
					mini.Shape = Enum.PartType.Ball
					mini.Size = Vector3.new(0.8, 0.8, 0.8)
					mini.Material = Enum.Material.Neon
					mini.Color = bullet.Color
					mini.Position = bullet.Position
						+ Vector3.new((math.random() - 0.5) * 2, (math.random() - 0.5) * 2, (math.random() - 0.5) * 2)
					mini.CanCollide = true
					mini.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.1, 1.0, 1.0, 1.0)
					mini.Parent = workspace

					local trail2 = Instance.new("Trail")
					local att0_2 = Instance.new("Attachment", mini)
					att0_2.Position = Vector3.new(0, 0.4, 0)
					local att1_2 = Instance.new("Attachment", mini)
					att1_2.Position = Vector3.new(0, -0.4, 0)
					trail2.Attachment0 = att0_2
					trail2.Attachment1 = att1_2
					trail2.Lifetime = 0.2
					trail2.Color = ColorSequence.new(mini.Color)
					trail2.Parent = mini

					local randomDir = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
					mini.Velocity = randomDir * math.random(80, 150)
					mini:SetNetworkOwner(player)

					local miniHitHumanoid = false
					local spawnTime = tick()

					mini.Touched:Connect(function(hitObj)
						if miniHitHumanoid then
							return
						end
						if mini.AssemblyLinearVelocity.Magnitude < 10 then
							return
						end
						if not hitObj or not hitObj.Parent then
							return
						end

						if hitObj.Name == "PlayerShield" then
							local ownerId = hitObj:GetAttribute("OwnerId")
							if ownerId == player.UserId then
								return
							end
							local normal = hitObj.CFrame.LookVector
							local currentVel = mini.AssemblyLinearVelocity
							if currentVel:Dot(normal) < 0 then
								mini.AssemblyLinearVelocity = (currentVel - 2 * currentVel:Dot(normal) * normal)
									* GameConfig.Shield.BounceMultiplier
								mini.Color = Color3.fromRGB(255, 255, 255)
								trail2.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
								playSound(SOUND_BOUNCE, mini, 0.8, 1.5)
							end
							return
						end

						local hitHum = hitObj.Parent:FindFirstChild("Humanoid")
						if hitHum then
							local isShooter = hitObj:IsDescendantOf(character)
							if isShooter and (tick() - spawnTime < 0.2) then
								return
							end

							local targetPlayer = game.Players:GetPlayerFromCharacter(hitObj.Parent)
							if targetPlayer and player.Team and targetPlayer.Team == player.Team then
								miniHitHumanoid = true
								mini:Destroy()
								return
							end

							miniHitHumanoid = true
							tagHumanoid(hitHum, player)
							local damageMult = character:GetAttribute("DamageMultiplier") or 1.0
							hitHum:TakeDamage(CLUSTER_DAMAGE * damageMult)
							playSound(SOUND_HIT, hitObj, 0.8, 1.5)
							mini:Destroy()
						else
							playSound(SOUND_BOUNCE, mini, 0.2, math.random(1.2, 1.5))
						end
					end)

					Debris:AddItem(mini, 2.0 + math.random())
				end

				bullet:Destroy()
				return
			end
			-- ==============================================

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

				local damageMult = character:GetAttribute("DamageMultiplier") or 1.0
				humanoid:TakeDamage(stats.Damage * damageMult)

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
