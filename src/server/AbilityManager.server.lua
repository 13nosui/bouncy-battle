-- src/server/AbilityManager.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

-- リモートイベントの準備
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

					-- プレイヤーに能力をセット
					player:SetAttribute("CurrentAbility", abilityName)

					-- 取得音を鳴らす
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://86070307558627" -- キラキラ音
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

-- ロビーがロードされてから台を探す
task.spawn(function()
	task.wait(3)
	setupAbilitySpawners()
end)

-- === 2. 能力の発動処理 ===
abilityEvent.OnServerEvent:Connect(function(player)
	-- 現在持っている能力をチェック
	local abilityName = player:GetAttribute("CurrentAbility")
	if not abilityName then
		return
	end

	local abilityConfig = GameConfig.Abilities[abilityName]
	if not abilityConfig then
		return
	end

	-- クールダウンのチェック
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
		-- local currentVel = rootPart.AssemblyLinearVelocity
		-- rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, abilityConfig.JumpVelocity, currentVel.Z)

		abilityEvent:FireClient(player, "HighJump", abilityConfig)

		-- ジャンプ音
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://12222208"
		sound.Volume = 1.0
		sound.Parent = rootPart
		sound:Play()
		Debris:AddItem(sound, 1)

		-- 足元に広がる光のリングエフェクト
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.5, 4, 4)
		ring.Color = Color3.fromRGB(80, 240, 255)
		ring.Material = Enum.Material.Neon
		ring.Anchored = true
		ring.CanCollide = false
		ring.CastShadow = false
		-- キャラクターの足元で水平になるように回転
		ring.CFrame = rootPart.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Parent = workspace

		TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.5, 20, 20),
			Transparency = 1,
		}):Play()
		Debris:AddItem(ring, 0.5)
	end
end)
