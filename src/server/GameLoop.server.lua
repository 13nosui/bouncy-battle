local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

-- === 設定 ===
local INTERMISSION_TIME = 10
local WIN_SCORE = 5
local ROUND_TIME = 180
local SHOW_LOBBY_MESSAGE = false

local MapsFolder = ServerStorage:WaitForChild("Maps")
local CurrentMap = nil

-- ★追加: ServerStorageからBuildToolを取得しておく
local BuildToolTemplate = ServerStorage:WaitForChild("BuildTool", 5)

local isMatchActive = false
local gameMode = "FFA"

local ZONES = {
	{ name = "JoinZone_FFA", mode = "FFA", color = Color3.new(1, 0.4, 0.4) },
	{ name = "JoinZone_TDM", mode = "TDM", color = Color3.new(0.4, 0.6, 1) },
	{ name = "JoinZone_BUILD", mode = "BUILD", color = Color3.new(1, 0.9, 0.2) },
}

local MAP_ZONES = {
	{ name = "MapVote_City", mapName = "Map_City" },
	{ name = "MapVote_Village", mapName = "Map_Village" },
}

local messageEvent = ReplicatedStorage:FindFirstChild("GameMessage")
if not messageEvent then
	messageEvent = Instance.new("RemoteEvent")
	messageEvent.Name = "GameMessage"
	messageEvent.Parent = ReplicatedStorage
end

local cameraEvent = ReplicatedStorage:FindFirstChild("CameraEvent")
if not cameraEvent then
	cameraEvent = Instance.new("RemoteEvent")
	cameraEvent.Name = "CameraEvent"
	cameraEvent.Parent = ReplicatedStorage
end

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

local function getVotedMap()
	local bestMap = "Map_City"
	local maxVotes = -1

	for _, zoneInfo in ipairs(MAP_ZONES) do
		local voteZone = Workspace:FindFirstChild(zoneInfo.name, true)
		if voteZone then
			local playersInZone = getPlayersInZone(voteZone)
			if #playersInZone > maxVotes then
				maxVotes = #playersInZone
				bestMap = zoneInfo.mapName
			end
		end
	end

	if maxVotes <= 0 then
		local randomZone = MAP_ZONES[math.random(1, #MAP_ZONES)]
		bestMap = randomZone.mapName
	end

	return bestMap
end

local function broadcast(text, color)
	messageEvent:FireAllClients(text, color)
end

local function teleportToLobby()
	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn", true)

	for _, player in ipairs(Players:GetPlayers()) do
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
		warn("No spawns found in map!")
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
		warn("Map not found: " .. mapName)
		return
	end
	CurrentMap = mapTemplate:Clone()
	CurrentMap.Parent = Workspace
	print("Map Loaded: " .. mapName)
end

local function resetScores()
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			stats.Kills.Value = 0
		end
	end
end

local function startRound(mode, participants, mapName)
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

	task.wait(2)

	broadcast("MAP: " .. (mapName == "Map_City" and "CYBER CITY" or "VILLAGE"), Color3.new(0.8, 1, 0.8))
	task.wait(2)

	loadMap(mapName)
	teleportToArena(participants)

	-- ★追加: BUILDモードの場合、参加者にビルドツールを配布する
	if gameMode == "BUILD" and BuildToolTemplate then
		for _, player in ipairs(participants) do
			local backpack = player:FindFirstChild("Backpack")
			if backpack and not backpack:FindFirstChild("BuildTool") then
				local tool = BuildToolTemplate:Clone()
				tool.Parent = backpack
			end
		end
	end

	broadcast("START!", Color3.new(0, 1, 0))

	local startTime = tick()
	while isMatchActive do
		task.wait(1)
		if tick() - startTime > ROUND_TIME then
			broadcast("TIME UP!", Color3.new(1, 1, 1))
			isMatchActive = false
		end
	end

	task.wait(5)
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
			end
			task.wait(1)
		else
			local countdownCancelled = false

			for i = INTERMISSION_TIME, 1, -1 do
				broadcast(bestMode .. " starts in " .. i .. " (" .. readyCount .. " players)", modeColor)
				task.wait(1)

				local currentMode, currentPlayers = getModeAndPlayers()
				if currentMode ~= bestMode or #currentPlayers == 0 then
					countdownCancelled = true
					break
				end
				readyCount = #currentPlayers
			end

			if not countdownCancelled and readyCount >= 1 then
				local selectedMap = getVotedMap()
				startRound(bestMode, readyPlayers, selectedMap)
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
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	kills.Changed:Connect(function(newValue)
		if isMatchActive and newValue >= WIN_SCORE then
			broadcast(player.Name .. " WINS!", Color3.new(1, 0.5, 0))

			if player.Character then
				cameraEvent:FireAllClients("Win", player.Character)
			end

			isMatchActive = false
		end
	end)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			onHumanoidDied(humanoid, player)
		end)

		-- ★追加: リスポーンした時に、もしBUILDモード中ならツールを再配布する
		task.spawn(function()
			task.wait(0.5) -- バックパックが作られるのを少し待つ
			if isMatchActive and gameMode == "BUILD" and BuildToolTemplate then
				local backpack = player:FindFirstChild("Backpack")
				if backpack and not backpack:FindFirstChild("BuildTool") then
					local tool = BuildToolTemplate:Clone()
					tool.Parent = backpack
				end
			end
		end)
	end)
end)

task.spawn(gameLoop)
