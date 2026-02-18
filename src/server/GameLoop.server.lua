local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

-- === 設定 ===
local INTERMISSION_TIME = 10
local WIN_SCORE = 5
local ROUND_TIME = 180

local MapsFolder = ServerStorage:WaitForChild("Maps")
local CurrentMap = nil

local isMatchActive = false
local gameMode = "FFA"

-- 参加受付ゾーンの名前
local JOIN_ZONE_NAME = "JoinZone"

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

-- === ヘルパー関数 ===

-- ★変更: 「JoinZone」をフォルダの中まで探すように修正
local function getReadyPlayers()
	-- 第2引数に true を入れると、Workspaceの中にあるフォルダやモデルの中も探してくれます
	local joinZone = Workspace:FindFirstChild(JOIN_ZONE_NAME, true)

	if not joinZone then
		warn("JoinZone not found anywhere in Workspace!")
		return {}
	end

	-- OverlapParams: 判定の設定
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { joinZone }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	-- ゾーン内のパーツを取得
	local partsInZone = Workspace:GetPartsInPart(joinZone, overlapParams)
	local readyPlayers = {}
	local foundUserIds = {} -- 重複防止用

	for _, part in ipairs(partsInZone) do
		local character = part.Parent
		if character and character:FindFirstChild("Humanoid") then
			local player = Players:GetPlayerFromCharacter(character)
			-- プレイヤーが存在し、まだリストに入っておらず、かつ「PLAY」を押してロビーにいる人
			if player and not foundUserIds[player.UserId] and player:GetAttribute("IsReady") then
				foundUserIds[player.UserId] = true
				table.insert(readyPlayers, player)
			end
		end
	end

	return readyPlayers
end

local function broadcast(text, color)
	messageEvent:FireAllClients(text, color)
end

local function teleportToLobby()
	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn", true) -- ここも念の為 true にしておきます

	if lobbySpawn then
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Team ~= nil then
				player.Team = nil
				player:LoadCharacter()
			end
		end
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
		for _, child in ipairs(CurrentMap:GetChildren()) do
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

-- === ゲームループ ===

local function startRound(participants)
	isMatchActive = true
	resetScores()

	if math.random() > 0.5 then
		gameMode = "FFA"
		broadcast("MODE: FREE FOR ALL", Color3.new(1, 1, 0))
	else
		gameMode = "TDM"
		broadcast("MODE: TEAM DEATHMATCH", Color3.new(0, 1, 1))
	end

	task.wait(3)

	loadMap("Map_City")

	teleportToArena(participants)

	broadcast("START!", Color3.new(0, 1, 0))

	local startTime = tick()
	while isMatchActive do
		task.wait(1)
		if tick() - startTime > ROUND_TIME then
			broadcast("TIME UP!", Color3.new(1, 1, 1))
			isMatchActive = false
		end

		local activePlayers = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Team ~= nil then
				activePlayers += 1
			end
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
		local readyPlayers = getReadyPlayers()
		local readyCount = #readyPlayers

		if readyCount == 0 then
			broadcast("Stand in the ZONE to join!", Color3.new(0.5, 1, 1))
			task.wait(1)
		else
			for i = INTERMISSION_TIME, 1, -1 do
				broadcast("Match starts in " .. i .. " (" .. readyCount .. " players)", Color3.new(1, 1, 1))
				task.wait(1)

				readyPlayers = getReadyPlayers()
				readyCount = #readyPlayers
				if readyCount == 0 then
					break
				end
			end

			if readyCount >= 1 then
				startRound(readyPlayers)
			end
		end
	end
end

-- === イベント接続 ===

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
	end)
end)

task.spawn(gameLoop)
