local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- 個人のセーブ用と、みんなの公開用で2つのデータベースを用意
local StageDataStore = DataStoreService:GetDataStore("BouncyBattle_Stages_v1")
local CommunityDataStore = DataStoreService:GetDataStore("BouncyBattle_Community_v1")

local function getRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

-- サーバー内で完結する通信（GameLoopから呼び出す用）
local function getBindable(name)
	local b = ReplicatedStorage:FindFirstChild(name)
	if not b then
		b = Instance.new("BindableFunction")
		b.Name = name
		b.Parent = ReplicatedStorage
	end
	return b
end

local saveEvent = getRemote("SaveStageEvent")
local loadEvent = getRemote("LoadStageEvent")
local publishEvent = getRemote("PublishStageEvent") -- ★追加
local messageEvent = getRemote("GameMessage")

local getRandomStageBindable = getBindable("GetRandomCommunityStage") -- ★追加

local BLOCK_SIZE = 4

-- === 既存のセーブ処理 ===
saveEvent.OnServerEvent:Connect(function(player)
	local stageData = {}
	local blockCount = 0

	for _, block in ipairs(workspace:GetChildren()) do
		if block.Name == "PlayerWall" then
			local shapeType = "Block"
			if block:IsA("WedgePart") then
				shapeType = "Wedge"
			elseif block.Shape == Enum.PartType.Cylinder then
				shapeType = "Cylinder"
			elseif block.Shape == Enum.PartType.Ball then
				shapeType = "Sphere"
			end

			local cx, cy, cz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = block.CFrame:GetComponents()
			table.insert(stageData, {
				cx = cx,
				cy = cy,
				cz = cz,
				r00 = r00,
				r01 = r01,
				r02 = r02,
				r10 = r10,
				r11 = r11,
				r12 = r12,
				r20 = r20,
				r21 = r21,
				r22 = r22,
				shape = shapeType,
			})
			blockCount = blockCount + 1
		end
	end

	local success, errorMessage = pcall(function()
		StageDataStore:SetAsync(player.UserId .. "_MyStage", stageData)
	end)

	if success then
		messageEvent:FireClient(player, "SAVED " .. blockCount .. " BLOCKS!", Color3.new(0.2, 1, 0.2))
	else
		messageEvent:FireClient(player, "SAVE FAILED", Color3.new(1, 0, 0))
	end
end)

-- === 既存のロード処理 ===
loadEvent.OnServerEvent:Connect(function(player)
	local stageData
	local success, errorMessage = pcall(function()
		stageData = StageDataStore:GetAsync(player.UserId .. "_MyStage")
	end)

	if success and stageData then
		for _, block in ipairs(workspace:GetChildren()) do
			if block.Name == "PlayerWall" then
				block:Destroy()
			end
		end

		for _, data in ipairs(stageData) do
			local block
			if data.shape == "Wedge" then
				block = Instance.new("WedgePart")
			else
				block = Instance.new("Part")
				if data.shape == "Cylinder" then
					block.Shape = Enum.PartType.Cylinder
				elseif data.shape == "Sphere" then
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
			block.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 1.0, 1.0, 1.0)

			block.CFrame = CFrame.new(
				data.cx,
				data.cy,
				data.cz,
				data.r00,
				data.r01,
				data.r02,
				data.r10,
				data.r11,
				data.r12,
				data.r20,
				data.r21,
				data.r22
			)
			block.Parent = workspace
		end
		messageEvent:FireClient(player, "STAGE LOADED!", Color3.new(0.2, 1, 0.2))
	else
		messageEvent:FireClient(player, "NO SAVED DATA", Color3.new(1, 1, 0))
	end
end)

-- === ★追加: PUBLISH（公開）処理 ===
publishEvent.OnServerEvent:Connect(function(player)
	local stageData = {}
	local blockCount = 0

	for _, block in ipairs(workspace:GetChildren()) do
		if block.Name == "PlayerWall" then
			local shapeType = "Block"
			if block:IsA("WedgePart") then
				shapeType = "Wedge"
			elseif block.Shape == Enum.PartType.Cylinder then
				shapeType = "Cylinder"
			elseif block.Shape == Enum.PartType.Ball then
				shapeType = "Sphere"
			end

			local cx, cy, cz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = block.CFrame:GetComponents()
			table.insert(stageData, {
				cx = cx,
				cy = cy,
				cz = cz,
				r00 = r00,
				r01 = r01,
				r02 = r02,
				r10 = r10,
				r11 = r11,
				r12 = r12,
				r20 = r20,
				r21 = r21,
				r22 = r22,
				shape = shapeType,
			})
			blockCount = blockCount + 1
		end
	end

	if blockCount == 0 then
		messageEvent:FireClient(player, "NOTHING TO PUBLISH", Color3.new(1, 1, 0))
		return
	end

	local success, errorMessage = pcall(function()
		-- コミュニティに登録されているステージの「総数」を1増やす
		local newCount = CommunityDataStore:UpdateAsync("CommunityStageCount", function(oldValue)
			return (oldValue or 0) + 1
		end)

		-- 新しいID（例: CommunityStage_1）で、誰が作ったかの名前と一緒に保存する
		CommunityDataStore:SetAsync("CommunityStage_" .. tostring(newCount), {
			creatorName = player.Name,
			data = stageData,
		})
	end)

	if success then
		messageEvent:FireClient(player, "PUBLISHED TO COMMUNITY!", Color3.new(1, 0.5, 0))
	else
		warn("Publish Error: " .. tostring(errorMessage))
		messageEvent:FireClient(player, "PUBLISH FAILED", Color3.new(1, 0, 0))
	end
end)

-- === ★追加: GameLoopからランダムなステージを要求された時の処理 ===
getRandomStageBindable.OnInvoke = function()
	local count = 0
	pcall(function()
		count = CommunityDataStore:GetAsync("CommunityStageCount") or 0
	end)

	if count > 0 then
		local randomId = math.random(1, count)
		local stageInfo
		local success = pcall(function()
			stageInfo = CommunityDataStore:GetAsync("CommunityStage_" .. tostring(randomId))
		end)

		if success and stageInfo then
			return stageInfo
		end
	end
	return nil
end

print("Server: StageSaveSystem Loaded (Publish Ready)")
