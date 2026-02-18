local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

-- === 設定 ===
local INTERMISSION_TIME = 10 -- ロビーでの待機時間
local WIN_SCORE = 5 -- 勝利キル数
local ROUND_TIME = 180 -- 1試合の制限時間（秒）

-- マップ格納場所
local MapsFolder = ServerStorage:WaitForChild("Maps")
local CurrentMap = nil

-- 状態管理
local isMatchActive = false
local gameMode = "FFA"

-- イベント作成
local messageEvent = ReplicatedStorage:FindFirstChild("GameMessage")
if not messageEvent then
	messageEvent = Instance.new("RemoteEvent")
	messageEvent.Name = "GameMessage"
	messageEvent.Parent = ReplicatedStorage
end

-- ★追加: カメラ制御用イベント
local cameraEvent = ReplicatedStorage:FindFirstChild("CameraEvent")
if not cameraEvent then
	cameraEvent = Instance.new("RemoteEvent")
	cameraEvent.Name = "CameraEvent"
	cameraEvent.Parent = ReplicatedStorage
end

-- === ヘルパー関数 ===

local function broadcast(text, color)
	messageEvent:FireAllClients(text, color)
end

local function teleportToLobby()
	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn")

	if lobbySpawn then
		for _, player in ipairs(Players:GetPlayers()) do
			player.Team = nil
			player:LoadCharacter()

			-- ★追加: ロビーに戻ったらカメラをリセットさせる指示を送る（ターゲットを自分に戻すため）
			-- クライアント側でLoadCharacter時に自動で戻るはずだが、念の為
		end
	end

	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "Dummy" and child:FindFirstChild("Humanoid") then
			child:Destroy()
		end
	end
end

local function teleportToArena()
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

	local players = Players:GetPlayers()
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

local function startRound()
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
	teleportToArena()

	broadcast("START!", Color3.new(0, 1, 0))

	local startTime = tick()
	while isMatchActive do
		task.wait(1)
		if tick() - startTime > ROUND_TIME then
			broadcast("TIME UP!", Color3.new(1, 1, 1))
			isMatchActive = false
		end
	end

	task.wait(5) -- 勝韻に浸る時間を少し長く
	if CurrentMap then
		CurrentMap:Destroy()
	end
	teleportToLobby()
end

local function gameLoop()
	while true do
		broadcast("Waiting for players...", Color3.new(1, 1, 1))
		repeat
			task.wait(1)
		until #Players:GetPlayers() >= 1

		for i = INTERMISSION_TIME, 1, -1 do
			broadcast("Next match in " .. i, Color3.new(1, 1, 1))
			task.wait(1)
		end
		startRound()
	end
end

-- === イベント接続 ===

local function onHumanoidDied(humanoid, player)
	if not isMatchActive then
		return
	end

	local creatorTag = humanoid:FindFirstChild("creator")
	if creatorTag and creatorTag.Value then
		local killer = creatorTag.Value -- Player または Bot(Model)

		-- ★追加: キルカメラ処理
		-- 倒されたプレイヤー(player)に対して、キラー(killer)を見ろと命令する
		local killerChar = nil
		if killer:IsA("Player") then
			killerChar = killer.Character
		elseif killer:IsA("Model") then
			killerChar = killer -- Botの場合
		end

		if killerChar then
			cameraEvent:FireClient(player, "Kill", killerChar)
		end

		-- 以下、スコア処理（Playerキラーのみ）
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

			-- ★追加: 勝利カメラ
			-- 全員に対して、勝者(player.Character)を映せと命令する
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
