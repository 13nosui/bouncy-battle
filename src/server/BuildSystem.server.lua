local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local buildEvent = ReplicatedStorage:WaitForChild("BuildEvent")

local cooldowns = {}
local BUILD_COOLDOWN = 0.2
local BLOCK_SIZE = 4

local function snapToGrid(position)
	local x = math.floor(position.X / BLOCK_SIZE) * BLOCK_SIZE + (BLOCK_SIZE / 2)
	local y = math.floor(position.Y / BLOCK_SIZE) * BLOCK_SIZE + (BLOCK_SIZE / 2)
	local z = math.floor(position.Z / BLOCK_SIZE) * BLOCK_SIZE + (BLOCK_SIZE / 2)
	return Vector3.new(x, y, z)
end

buildEvent.OnServerEvent:Connect(function(player, actionType, targetData, shapeType)
	if actionType == "Build" then
		if cooldowns[player.UserId] and (tick() - cooldowns[player.UserId] < BUILD_COOLDOWN) then
			return
		end
		cooldowns[player.UserId] = tick()

		local snappedPos = snapToGrid(targetData)

		local overlapParams = OverlapParams.new()
		local boxSize = Vector3.new(BLOCK_SIZE - 0.5, BLOCK_SIZE - 0.5, BLOCK_SIZE - 0.5)
		local hits = workspace:GetPartBoundsInBox(CFrame.new(snappedPos), boxSize, overlapParams)
		for _, hit in ipairs(hits) do
			if hit.Name == "PlayerWall" then
				return
			end
		end

		local block
		if shapeType == "Wedge" then
			block = Instance.new("WedgePart")
		else
			block = Instance.new("Part")
			if shapeType == "Cylinder" then
				block.Shape = Enum.PartType.Cylinder
			elseif shapeType == "Sphere" then
				block.Shape = Enum.PartType.Ball
			else
				block.Shape = Enum.PartType.Block
			end
		end

		block.Name = "PlayerWall"
		block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
		block.Anchored = true
		block.Material = Enum.Material.SmoothPlastic
		block.Color = Color3.fromRGB(0, 200, 255)

		-- ★警告を消すために上限値の1.0に修正
		block.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 1.0, 1.0, 1.0)

		local yaw = 0
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local look = player.Character.HumanoidRootPart.CFrame.LookVector
			local angle = math.atan2(look.X, look.Z)
			yaw = math.floor((angle / (math.pi / 2)) + 0.5) * (math.pi / 2)
			yaw = yaw + math.pi
		end

		local finalCFrame = CFrame.new(snappedPos) * CFrame.Angles(0, yaw, 0)

		if shapeType == "Cylinder" then
			finalCFrame = finalCFrame * CFrame.Angles(0, 0, math.pi / 2)
		end

		block.CFrame = finalCFrame
		block.Parent = workspace

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://135549838877133"
		sound.Volume = 0.8
		sound.Parent = block
		sound:Play()
	elseif actionType == "Destroy" then
		-- ▼ 破壊処理 ▼
		local targetBlock = targetData
		if targetBlock and targetBlock.Name == "PlayerWall" then
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://685857471"
			sound.Volume = 0.8
			-- ★エラーの原因だった position の指定を削除しました
			sound.Parent = workspace
			sound:Play()
			Debris:AddItem(sound, 2)
			targetBlock:Destroy()
		end
	elseif actionType == "Rotate" then
		-- ▼ 回転処理 ▼
		local targetBlock = targetData
		if targetBlock and targetBlock.Name == "PlayerWall" then
			targetBlock.CFrame = targetBlock.CFrame * CFrame.Angles(0, math.pi / 4, 0)

			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://12222084"
			sound.Volume = 0.5
			-- ★エラーの原因だった position の指定を削除しました
			sound.Parent = workspace
			sound:Play()
			Debris:AddItem(sound, 2)
		end
	end
end)
