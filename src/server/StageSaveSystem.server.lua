local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- "BouncyBattle_Stages_v1" という名前のデータベースを作成
local StageDataStore = DataStoreService:GetDataStore("BouncyBattle_Stages_v1")

-- 通信用イベントの準備
local function getRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local saveEvent = getRemote("SaveStageEvent")
local loadEvent = getRemote("LoadStageEvent")
local messageEvent = getRemote("GameMessage")

local BLOCK_SIZE = 4

-- === セーブ処理 ===
saveEvent.OnServerEvent:Connect(function(player)
	local stageData = {}
	local blockCount = 0

	-- ワークスペースにある "PlayerWall" をすべて探し出し、データを抽出する
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

			-- 位置と角度（CFrameの12個の要素）を完璧に記録する
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

	-- データベースに保存（非同期処理）
	local success, errorMessage = pcall(function()
		-- 現在はプレイヤー固有のIDに紐づけて保存しています
		StageDataStore:SetAsync(player.UserId .. "_MyStage", stageData)
	end)

	if success then
		messageEvent:FireClient(player, "SAVED " .. blockCount .. " BLOCKS!", Color3.new(0.2, 1, 0.2))
	else
		warn("Save Error: " .. tostring(errorMessage))
		messageEvent:FireClient(player, "SAVE FAILED", Color3.new(1, 0, 0))
	end
end)

-- === ロード処理 ===
loadEvent.OnServerEvent:Connect(function(player)
	local stageData
	local success, errorMessage = pcall(function()
		stageData = StageDataStore:GetAsync(player.UserId .. "_MyStage")
	end)

	if success and stageData then
		-- ロードする前に、今置かれているブロックをすべて消去する
		for _, block in ipairs(workspace:GetChildren()) do
			if block.Name == "PlayerWall" then
				block:Destroy()
			end
		end

		-- 保存されたデータからブロックを再構築する
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

			-- CFrameで正確な位置と角度を復元
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

print("Server: StageSaveSystem Loaded")
