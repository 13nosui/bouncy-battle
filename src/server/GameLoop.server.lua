local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local INTERMISSION_TIME = 10
local WIN_SCORE = 5
local ROUND_TIME = 180
local SHOW_LOBBY_MESSAGE = false

local MapsFolder = ServerStorage:WaitForChild("Maps")
local CurrentMap = nil
local BuildToolTemplate = ServerStorage:WaitForChild("BuildTool", 5)

local isMatchActive = false
local gameMode = "FFA"

local ZONES = {
	{ name = "JoinZone_FFA", mode = "FFA", color = Color3.new(1, 0.4, 0.4) },
	{ name = "JoinZone_TDM", mode = "TDM", color = Color3.new(0.4, 0.6, 1) },
	{ name = "JoinZone_BUILD", mode = "BUILD", color = Color3.new(1, 0.9, 0.2) },
}

local messageEvent = ReplicatedStorage:FindFirstChild("GameMessage")
if not messageEvent then
	messageEvent = Instance.new("RemoteEvent")
	messageEvent.Name = "GameMessage"
	messageEvent.Parent = ReplicatedStorage
end

local roundStatus = ReplicatedStorage:FindFirstChild("RoundStatus")
if not roundStatus then
	roundStatus = Instance.new("StringValue")
	roundStatus.Name = "RoundStatus"
	roundStatus.Value = "LOBBY"
	roundStatus.Parent = ReplicatedStorage
end

local cameraEvent = ReplicatedStorage:FindFirstChild("CameraEvent")
if not cameraEvent then
	cameraEvent = Instance.new("RemoteEvent")
	cameraEvent.Name = "CameraEvent"
	cameraEvent.Parent = ReplicatedStorage
end

-- ★変更: 初期状態（何もクリックしていない時）を「Empty Canvas」にしました
local selectedMapIndex = 2
local availableMaps = {
	{ type = "Official", name = "Empty Canvas", mapName = "Map_BuildBase" },
	{ type = "Official", name = "Park Stage", mapName = "Map_Park" },
	{ type = "Official", name = "Battle Arena", mapName = "Map_Arena" },
}

local mapBoard = Instance.new("Part")
mapBoard.Name = "MapSelectorBoard"
mapBoard.Size = Vector3.new(12, 6, 1)

local lobbySpawn = Workspace:FindFirstChild("LobbySpawn", true)
if lobbySpawn then
	mapBoard.Position = lobbySpawn.Position + Vector3.new(0, 6, -15)
else
	mapBoard.Position = Vector3.new(0, 10, -25)
end

mapBoard.Anchored = true
mapBoard.Material = Enum.Material.SmoothPlastic
mapBoard.Color = Color3.fromRGB(30, 30, 30)
mapBoard.Parent = Workspace

local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Face = Enum.NormalId.Back
surfaceGui.Parent = mapBoard

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "--- NEXT MAP ---"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = surfaceGui

local mapNameLabel = Instance.new("TextLabel")
mapNameLabel.Size = UDim2.new(1, 0, 0.7, 0)
mapNameLabel.Position = UDim2.new(0, 0, 0.3, 0)
mapNameLabel.BackgroundTransparency = 1
mapNameLabel.Text = "Loading..."
mapNameLabel.TextColor3 = Color3.fromRGB(80, 240, 255)
mapNameLabel.TextScaled = true
mapNameLabel.Font = Enum.Font.GothamBlack
mapNameLabel.Parent = surfaceGui

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 30
clickDetector.Parent = mapBoard

local function updateBoardDisplay()
	local current = availableMaps[selectedMapIndex]
	if not current then
		return
	end

	if current.type == "Official" then
		mapNameLabel.Text = "[CLICK HERE]\n" .. current.name
		mapNameLabel.TextColor3 = Color3.fromRGB(80, 240, 255)
	else
		mapNameLabel.Text = "[CLICK HERE]\nStage " .. current.stageId .. "\n(by " .. current.creator .. ")"
		mapNameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	end
end

local function refreshAvailableMaps()
	-- ★変更: リスト更新時も「Empty Canvas」を先頭に
	local newList = {
		{ type = "Official", name = "Empty Canvas", mapName = "Map_BuildBase" },
		{ type = "Official", name = "Park Stage", mapName = "Map_Park" },
		{ type = "Official", name = "Battle Arena", mapName = "Map_Arena" },
	}

	local getStageListBindable = ReplicatedStorage:FindFirstChild("GetCommunityStageList")
	if getStageListBindable then
		local communityList = getStageListBindable:Invoke()
		if communityList then
			for _, stage in ipairs(communityList) do
				table.insert(newList, {
					type = "Community",
					creator = stage.creatorName,
					stageId = stage.id,
				})
			end
		end
	end

	availableMaps = newList
	if selectedMapIndex > #availableMaps then
		selectedMapIndex = 1
	end
	updateBoardDisplay()
end

clickDetector.MouseClick:Connect(function()
	selectedMapIndex = selectedMapIndex + 1
	if selectedMapIndex > #availableMaps then
		selectedMapIndex = 1
	end
	updateBoardDisplay()

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://138470560522298"
	sound.Volume = 0.5
	sound.Parent = mapBoard
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1)
end)

task.spawn(function()
	task.wait(3)
	refreshAvailableMaps()
end)

local function getPlayersInZone(joinZone)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { joinZone }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local partsInZone = Workspace:GetPartsInPart(joinZone, overlapParams)
	local readyPlayers = {}
	local foundUserIds = {}

	for _, part in ipairs(partsInZone) do
		local character = part.Parent
		if character and character:FindFirstChild("Humanoid") then
			local player = Players:GetPlayerFromCharacter(character)
			if player and not foundUserIds[player.UserId] and player:GetAttribute("IsReady") then
				foundUserIds[player.UserId] = true
				table.insert(readyPlayers, player)
			end
		end
	end
	return readyPlayers
end

local function getModeAndPlayers()
	local bestMode = nil
	local bestPlayers = {}
	local bestColor = Color3.new(1, 1, 1)

	for _, zoneInfo in ipairs(ZONES) do
		local joinZone = Workspace:FindFirstChild(zoneInfo.name, true)
		if joinZone then
			local playersInZone = getPlayersInZone(joinZone)
			if #playersInZone > #bestPlayers then
				bestPlayers = playersInZone
				bestMode = zoneInfo.mode
				bestColor = zoneInfo.color
			end
		end
	end
	return bestMode, bestPlayers, bestColor
end

local function broadcast(text, color)
	messageEvent:FireAllClients(text, color)
end

local function teleportToLobby()
	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn", true)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("InMatch", false)
		if player.Team ~= nil then
			player.Team = nil
		end
		player:LoadCharacter()
	end
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "Dummy" and child:FindFirstChild("Humanoid") then
			child:Destroy()
		end
	end
	task.spawn(refreshAvailableMaps)
end

local function teleportToArena(players)
	local spawns = {}
	if CurrentMap then
		for _, child in ipairs(CurrentMap:GetDescendants()) do
			if child:IsA("SpawnLocation") then
				table.insert(spawns, child)
			end
		end
	end

	if #spawns == 0 then
		return
	end

	if gameMode == "TDM" then
		for i, player in ipairs(players) do
			if i % 2 == 1 then
				player.Team = Teams.RedTeam
			else
				player.Team = Teams.BlueTeam
			end
		end
	end

	for i, player in ipairs(players) do
		player:SetAttribute("InMatch", true)
		local spawn = spawns[math.random(1, #spawns)]
		if player.Character then
			player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 3, 0))
		end
	end
end

local function loadMap(mapName)
	if CurrentMap then
		CurrentMap:Destroy()
	end
	local mapTemplate = MapsFolder:FindFirstChild(mapName)
	if not mapTemplate then
		return
	end
	CurrentMap = mapTemplate:Clone()
	CurrentMap.Name = "ActiveMap"
	CurrentMap.Parent = Workspace

	-- ★修正: 高さをミリ単位で合わせる処理は「ビルド用のステージ(Map_BuildBase)」かつ「Model」の時だけ実行する！
	if mapName == "Map_BuildBase" and CurrentMap:IsA("Model") then
		local spawnLoc = CurrentMap:FindFirstChildWhichIsA("SpawnLocation", true)
		local origin = spawnLoc and (spawnLoc.Position + Vector3.new(0, 5, 0)) or Vector3.new(0, 100, 0)

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { CurrentMap }
		params.FilterType = Enum.RaycastFilterType.Include

		local result = workspace:Raycast(origin, Vector3.new(0, -500, 0), params)

		if result then
			local topY = result.Position.Y
			local BLOCK_SIZE = 2
			local nearestGridY = math.round(topY / BLOCK_SIZE) * BLOCK_SIZE
			local offset = nearestGridY - topY

			if math.abs(offset) > 0.001 then
				CurrentMap:PivotTo(CurrentMap:GetPivot() + Vector3.new(0, offset, 0))
			end
		end
	end
end

local function resetScores()
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			stats.Kills.Value = 0
		end
	end
end

local function startRound(mode, participants)
	isMatchActive = true
	gameMode = mode
	resetScores()

	if gameMode == "FFA" then
		broadcast("MODE: FREE FOR ALL", Color3.new(1, 0.4, 0.4))
	elseif gameMode == "TDM" then
		broadcast("MODE: TEAM DEATHMATCH", Color3.new(0.4, 0.6, 1))
	elseif gameMode == "BUILD" then
		broadcast("MODE: BUILD BATTLE", Color3.new(1, 0.9, 0.2))
	end
	task.wait(3)

	local targetMap = availableMaps[selectedMapIndex]

	if gameMode == "BUILD" then
		-- BUILDモードなのに戦闘用マップ（ParkやArena）が選ばれていた場合、Empty Canvasに強制する
		if targetMap.type == "Official" and targetMap.mapName ~= "Map_BuildBase" then
			targetMap = { type = "Official", name = "Empty Canvas", mapName = "Map_BuildBase" }
		end
	elseif gameMode == "FFA" or gameMode == "TDM" then
		-- 戦闘モードなのに建築用マップ（Empty Canvasやコミュニティ）が選ばれていた場合、Battle Arenaに強制する
		if targetMap.mapName == "Map_BuildBase" or targetMap.type == "Community" then
			targetMap = { type = "Official", name = "Battle Arena", mapName = "Map_Arena" }
		end
	end

	if targetMap.type == "Community" then
		broadcast(
			"MAP: STAGE " .. targetMap.stageId .. "\nBY " .. string.upper(targetMap.creator),
			Color3.new(1, 0.8, 0.2)
		)
		task.wait(3)

		loadMap("Map_BuildBase")

		local getStageByIdBindable = ReplicatedStorage:FindFirstChild("GetCommunityStageById")
		local stageInfo = nil
		if getStageByIdBindable then
			stageInfo = getStageByIdBindable:Invoke(targetMap.stageId)
		end

		if stageInfo and stageInfo.data then
			local BLOCK_SIZE = 2
			for _, data in ipairs(stageInfo.data) do
				local block
				if data.shape == "Wedge" then
					block = Instance.new("WedgePart")
				else
					block = Instance.new("Part")
					block.Shape = Enum.PartType.Block
				end
				block.Name = "PlayerWall"
				block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
				block.Anchored = true

				if data.color then
					block.Color = Color3.new(data.color[1], data.color[2], data.color[3])
				else
					block.Color = Color3.fromRGB(0, 200, 255)
				end
				if data.material then
					local s, mat = pcall(function()
						return Enum.Material[data.material]
					end)
					block.Material = s and mat or Enum.Material.SmoothPlastic
				else
					block.Material = Enum.Material.SmoothPlastic
				end

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

				if CurrentMap then
					block.Parent = CurrentMap
				else
					block.Parent = workspace
				end
			end
		end
	else
		-- Official（Cyber City または Empty Canvas）の場合
		broadcast("MAP: " .. string.upper(targetMap.name), Color3.new(0.8, 1, 0.8))
		task.wait(3)
		loadMap(targetMap.mapName)
	end

	teleportToArena(participants)

	if gameMode == "BUILD" and BuildToolTemplate then
		for _, player in ipairs(participants) do
			local backpack = player:FindFirstChild("Backpack")
			if backpack and not backpack:FindFirstChild("BuildTool") then
				local tool = BuildToolTemplate:Clone()
				tool:SetAttribute("Slot", 0) -- スロット1に登録
				tool.Parent = backpack

				local char = player.Character
				local hum = char and char:FindFirstChild("Humanoid")
				if hum then
					hum:EquipTool(tool) -- 強制的に手に持たせる
				end
			end
		end
	end

	broadcast("START!", Color3.new(0, 1, 0))

	local startTime = tick()
	while isMatchActive do
		task.wait(1)

		if gameMode ~= "BUILD" then
			local timeLeft = ROUND_TIME - (tick() - startTime)
			if timeLeft <= 0 then
				broadcast("TIME UP!", Color3.new(1, 1, 1))
				roundStatus.Value = ""
				isMatchActive = false
			else
				local mins = math.floor(timeLeft / 60)
				local secs = math.floor(timeLeft % 60)
				roundStatus.Value = string.format("%s - %02d:%02d", gameMode, mins, secs)
			end
		else
			roundStatus.Value = "BUILD MODE"
		end
	end

	task.wait(5)
	roundStatus.Value = "LOBBY"
	if CurrentMap then
		CurrentMap:Destroy()
	end
	teleportToLobby()
end

local function gameLoop()
	while true do
		local bestMode, readyPlayers, modeColor = getModeAndPlayers()
		local readyCount = #readyPlayers

		if readyCount == 0 then
			if SHOW_LOBBY_MESSAGE then
				broadcast("Stand in a ZONE to join!", Color3.new(0.5, 1, 1))
			else
				broadcast("", Color3.new(1, 1, 1))
			end
			task.wait(0.5)
		else
			local countdownCancelled = false
			for i = INTERMISSION_TIME, 1, -1 do
				broadcast(bestMode .. " starts in " .. i .. " (" .. readyCount .. " players)", modeColor)

				-- ★変更: 1秒待つ間も「0.1秒ごと」に高速監視して、離れたら即座に消す！
				local elapsed = 0
				while elapsed < 1 do
					elapsed = elapsed + task.wait()
					local currentMode, currentPlayers = getModeAndPlayers()
					if currentMode ~= bestMode or #currentPlayers == 0 then
						countdownCancelled = true
						broadcast("", Color3.new(1, 1, 1)) -- ★即座に文字を消す
						break
					end
					readyCount = #currentPlayers
				end

				if countdownCancelled then
					break
				end
			end

			if not countdownCancelled and readyCount >= 1 then
				startRound(bestMode, readyPlayers)
			end
		end
	end
end

local function onHumanoidDied(humanoid, player)
	if not isMatchActive then
		return
	end
	local creatorTag = humanoid:FindFirstChild("creator")
	if creatorTag and creatorTag.Value then
		local killer = creatorTag.Value
		local killerChar = nil
		if killer:IsA("Player") then
			killerChar = killer.Character
		elseif killer:IsA("Model") then
			killerChar = killer
		end
		if killerChar then
			cameraEvent:FireClient(player, "Kill", killerChar)
		end
		if killer:IsA("Player") and killer ~= player then
			if gameMode == "TDM" and killer.Team == player.Team and player.Team ~= nil then
				return
			end
			local stats = killer:FindFirstChild("leaderstats")
			if stats then
				stats.Kills.Value = stats.Kills.Value + 1

				-- ★追加: キルした時に10コインあげる！
				local coins = stats:FindFirstChild("Coins")
				if coins then
					coins.Value = coins.Value + 10
				end
			end

			-- ★追加: 累計キル数（セーブ用）も増やす
			local totalKills = killer:GetAttribute("TotalKills") or 0
			killer:SetAttribute("TotalKills", totalKills + 1)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	-- 少し待ってリーダータッツが作られるのを待つ
	task.wait(0.5)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local kills = leaderstats:FindFirstChild("Kills")
		if kills then
			kills.Changed:Connect(function(newValue)
				if isMatchActive and newValue >= WIN_SCORE then
					broadcast(player.Name .. " WINS!", Color3.new(1, 0.5, 0))
					if player.Character then
						cameraEvent:FireAllClients("Win", player.Character)
					end

					-- ★追加: 優勝した時にボーナスで100コインあげる！
					local coins = leaderstats:FindFirstChild("Coins")
					if coins then
						coins.Value = coins.Value + 100
					end

					isMatchActive = false
				end
			end)
		end
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			onHumanoidDied(humanoid, player)
		end)

		task.spawn(function()
			task.wait(0.5)
			if isMatchActive and gameMode == "BUILD" and BuildToolTemplate then
				local backpack = player:FindFirstChild("Backpack")
				if backpack and not backpack:FindFirstChild("BuildTool") then
					local tool = BuildToolTemplate:Clone()
					tool:SetAttribute("Slot", 0) -- スロット「0」に登録
					tool.Parent = backpack

					local hum = character:FindFirstChild("Humanoid")
					if hum then
						hum:EquipTool(tool)
					end
				end
			end
		end)
	end)
end)

task.spawn(gameLoop)
