-- src/server/AbilityManager.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local abilityEvent = ReplicatedStorage:FindFirstChild("AbilityEvent")
if not abilityEvent then
	abilityEvent = Instance.new("RemoteEvent")
	abilityEvent.Name = "AbilityEvent"
	abilityEvent.Parent = ReplicatedStorage
end

local cooldowns = {}

-- === 1. 能力ピックアップ台の処理 ===
local function setupAbilitySpawners()
	for _, spawner in ipairs(Workspace:GetDescendants()) do
		if spawner.Name == "AbilitySpawner" and spawner:IsA("Model") then
			local clickDetector = spawner:FindFirstChildOfClass("ClickDetector")
			local abilityNameValue = spawner:FindFirstChild("AbilityName")

			if clickDetector and abilityNameValue then
				clickDetector.MouseClick:Connect(function(player)
					local abilityName = abilityNameValue.Value
					if not GameConfig.Abilities[abilityName] then
						return
					end

					player:SetAttribute("CurrentAbility", abilityName)

					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://86070307558627"
						sound.Volume = 1.0
						sound.Parent = char.HumanoidRootPart
						sound:Play()
						Debris:AddItem(sound, 1)
					end
				end)
			end
		end
	end
end

task.spawn(function()
	task.wait(3)
	setupAbilitySpawners()
end)

-- === 2. 能力の発動処理 ===
abilityEvent.OnServerEvent:Connect(function(player)
	local abilityName = player:GetAttribute("CurrentAbility")
	if not abilityName then
		return
	end

	local abilityConfig = GameConfig.Abilities[abilityName]
	if not abilityConfig then
		return
	end

	local now = tick()
	if cooldowns[player.UserId] and (now - cooldowns[player.UserId] < abilityConfig.Cooldown) then
		return
	end

	local char = player.Character
	if not char then
		return
	end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	cooldowns[player.UserId] = now

	-- ★大ジャンプ（HighJump）の発動
	if abilityName == "HighJump" then
		abilityEvent:FireClient(player, "HighJump", abilityConfig)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://1222208"
		sound.Volume = 1.0
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 1)

		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.5, 4, 4)
		ring.Color = Color3.fromRGB(80, 240, 255)
		ring.Material = Enum.Material.Neon
		ring.Anchored = true
		ring.CanCollide = false
		ring.CastShadow = false
		ring.CFrame = rootPart.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Parent = workspace

		TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.5, 20, 20),
			Transparency = 1,
		}):Play()
		Debris:AddItem(ring, 0.5)

	-- ★高速移動（SpeedBoost）の発動
	elseif abilityName == "SpeedBoost" then
		char:SetAttribute("SpeedBoostMultiplier", abilityConfig.SpeedMultiplier)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://12222084"
		sound.Volume = 1.0
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 1)

		local trail = Instance.new("Trail")
		local att0 = Instance.new("Attachment", rootPart)
		att0.Position = Vector3.new(0, 1, 0)
		local att1 = Instance.new("Attachment", rootPart)
		att1.Position = Vector3.new(0, -1, 0)
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = 0.3
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
		trail.Parent = rootPart

		task.delay(abilityConfig.Duration, function()
			if char then
				char:SetAttribute("SpeedBoostMultiplier", 1)
			end
			if trail then
				trail:Destroy()
			end
			if att0 then
				att0:Destroy()
			end
			if att1 then
				att1:Destroy()
			end
		end)

	-- ★透明化（Invisibility）の発動
	elseif abilityName == "Invisibility" then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://2868285516"
		sound.Volume = 1.0
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 1)

		local originalTransparencies = {}
		for _, part in ipairs(char:GetDescendants()) do
			if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("Decal") then
				originalTransparencies[part] = part.Transparency
				TweenService:Create(part, TweenInfo.new(0.5), { Transparency = abilityConfig.Transparency }):Play()
			end
		end

		task.delay(abilityConfig.Duration, function()
			for part, origTrans in pairs(originalTransparencies) do
				if part and part.Parent then
					TweenService:Create(part, TweenInfo.new(0.5), { Transparency = origTrans }):Play()
				end
			end
		end)

	-- ★瞬間移動（Teleport）の発動
	elseif abilityName == "Teleport" then
		local startPos = rootPart.Position
		local forwardDir = rootPart.CFrame.LookVector

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { char }
		params.FilterType = Enum.RaycastFilterType.Exclude

		local rayResult = workspace:Raycast(startPos, forwardDir * abilityConfig.Distance, params)

		local targetPos
		if rayResult then
			targetPos = rayResult.Position - (forwardDir * 3)
		else
			targetPos = startPos + (forwardDir * abilityConfig.Distance)
		end

		local eff1 = Instance.new("Part")
		eff1.Shape = Enum.PartType.Ball
		eff1.Size = Vector3.new(5, 5, 5)
		eff1.Position = startPos
		eff1.Anchored = true
		eff1.CanCollide = false
		eff1.Material = Enum.Material.Neon
		eff1.Color = Color3.fromRGB(200, 100, 255)
		eff1.Parent = workspace
		TweenService:Create(eff1, TweenInfo.new(0.3), { Size = Vector3.new(0, 0, 0), Transparency = 1 }):Play()
		Debris:AddItem(eff1, 0.5)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://2868285516"
		sound.Volume = 1.0
		sound.Pitch = 1.5
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 1)

		char:PivotTo(CFrame.new(targetPos) * char:GetPivot().Rotation)
		rootPart.AssemblyLinearVelocity = Vector3.zero

	-- ★周囲の弾を遅くする（TimeSlow）の発動
	elseif abilityName == "TimeSlow" then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://12222030"
		sound.Volume = 1.0
		sound.Pitch = 0.5
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 2)

		-- 1. 当たり判定用の「透明なドーム（球体）」
		local hitZone = Instance.new("Part")
		hitZone.Name = "TimeSlowZone"
		hitZone.Shape = Enum.PartType.Ball
		hitZone.Size = Vector3.new(abilityConfig.Radius * 2, abilityConfig.Radius * 2, abilityConfig.Radius * 2)
		hitZone.Transparency = 1
		hitZone.CanCollide = false
		hitZone.Massless = true
		hitZone.CastShadow = false
		hitZone.CFrame = rootPart.CFrame
		hitZone.Parent = workspace

		-- 2. 見た目用の「地面に広がる光るエリア（シリンダー）」
		local visualZone = Instance.new("Part")
		visualZone.Name = "VisualZone"
		visualZone.Shape = Enum.PartType.Cylinder
		visualZone.Size = Vector3.new(0.5, abilityConfig.Radius * 2, abilityConfig.Radius * 2)
		visualZone.Material = Enum.Material.Neon
		visualZone.Color = Color3.fromRGB(100, 255, 100)
		visualZone.Transparency = 0.65
		visualZone.CanCollide = false
		visualZone.Massless = true
		visualZone.CastShadow = false
		visualZone.CFrame = rootPart.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.pi / 2)
		visualZone.Parent = hitZone

		local weld1 = Instance.new("WeldConstraint")
		weld1.Part0 = rootPart
		weld1.Part1 = hitZone
		weld1.Parent = hitZone

		local weld2 = Instance.new("WeldConstraint")
		weld2.Part0 = rootPart
		weld2.Part1 = visualZone
		weld2.Parent = visualZone

		hitZone.Touched:Connect(function(hit)
			if hit.Name == "RubberBullet" or hit.Name == "BotBullet" then
				local isOwnBullet = false
				if hit.Name == "RubberBullet" then
					local success, owner = pcall(function()
						return hit:GetNetworkOwner()
					end)
					if success and owner == player then
						isOwnBullet = true
					end
				end
				if isOwnBullet then
					return
				end

				if hit:GetAttribute("Slowed") then
					return
				end
				hit:SetAttribute("Slowed", true)

				local currentVel = hit.AssemblyLinearVelocity
				hit.AssemblyLinearVelocity = currentVel * abilityConfig.SpeedMultiplier

				local antiGravity = Instance.new("BodyForce")
				antiGravity.Force = Vector3.new(0, hit:GetMass() * workspace.Gravity, 0)
				antiGravity.Parent = hit

				local trail = hit:FindFirstChildOfClass("Trail")
				if trail then
					trail.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
				end
			end
		end)

		Debris:AddItem(hitZone, abilityConfig.Duration)
	elseif abilityName == "Giant" or abilityName == "Mini" then
		-- 音の再生（Giantは低い音、Miniは高い音）
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://2868285516"
		sound.Volume = 1.0
		sound.Pitch = (abilityName == "Giant") and 0.5 or 2.0
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 2)

		-- 攻撃力倍率のセット（init.server.luaでダメージ計算に使われます）
		char:SetAttribute("DamageMultiplier", abilityConfig.DamageMultiplier)

		-- スケール（サイズ）の変更
		local humanoid = char:FindFirstChild("Humanoid")
		local originalScales = {}
		if humanoid then
			local scaleProps = { "BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale" }
			for _, propName in ipairs(scaleProps) do
				local val = humanoid:FindFirstChild(propName)
				if val and val:IsA("NumberValue") then
					originalScales[val] = val.Value
					-- Tweenを使って滑らかに伸び縮みさせる
					TweenService:Create(
						val,
						TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Value = abilityConfig.Scale }
					):Play()
				end
			end
		end

		-- 変身時のエフェクト（ポン！という煙）
		local attachment = Instance.new("Attachment", rootPart)
		local poof = Instance.new("ParticleEmitter")
		poof.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		poof.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, abilityConfig.Scale * 5),
		})
		poof.Texture = "rbxassetid://243660364"
		poof.Lifetime = NumberRange.new(0.5, 1)
		poof.Speed = NumberRange.new(5, 10)
		poof.EmissionDirection = Enum.NormalId.Top
		poof.Parent = attachment
		poof:Emit(20)
		Debris:AddItem(attachment, 2)

		-- 一定時間後に元に戻す
		task.delay(abilityConfig.Duration, function()
			if char then
				char:SetAttribute("DamageMultiplier", 1.0)
			end

			-- 戻る時の音と煙
			if rootPart and rootPart.Parent then
				local revSound = Instance.new("Sound")
				revSound.SoundId = "rbxassetid://2868285516"
				revSound.Volume = 1.0
				revSound.Pitch = (abilityName == "Giant") and 2.0 or 0.5
				revSound.Parent = rootPart
				revSound:Play()
				Debris:AddItem(revSound, 2)

				local revAtt = Instance.new("Attachment", rootPart)
				local revPoof = poof:Clone()
				revPoof.Parent = revAtt
				revPoof:Emit(20)
				Debris:AddItem(revAtt, 2)
			end

			-- スケールを元に戻す
			for val, origScale in pairs(originalScales) do
				if val and val.Parent then
					TweenService:Create(
						val,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Value = origScale }
					):Play()
				end
			end
		end)
	elseif abilityName == "XRay" then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://2868285516" -- ピコーン！という起動音
		sound.Volume = 1.0
		sound.Pitch = 1.2
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 2)

		-- 透視エフェクトは「自分だけ」に見える必要があるので、クライアント（自分の画面）に命令を送る
		abilityEvent:FireClient(player, "XRay", abilityConfig)
	end
end)
