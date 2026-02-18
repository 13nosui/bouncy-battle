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
local gameMode = "FFA" -- "FFA" (個人戦) or "TDM" (チーム戦)

-- メッセージ通知用
local messageEvent = ReplicatedStorage:FindFirstChild("GameMessage")
if not messageEvent then
	messageEvent = Instance.new("RemoteEvent")
	messageEvent.Name = "GameMessage"
	messageEvent.Parent = ReplicatedStorage
end

-- === ヘルパー関数 ===

local function broadcast(text, color)
	-- 第3引数などはHUD側で制御しているので、ここではテキストと色だけ送る
	messageEvent:FireAllClients(text, color)
end

-- 全員をロビーに戻す & Botのお片付け
local function teleportToLobby()
	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn")

	-- 1. プレイヤーをロビーへ
	if lobbySpawn then
		for _, player in ipairs(Players:GetPlayers()) do
			player.Team = nil -- チーム解除
			player:LoadCharacter() -- リスポーン
		end
	end

	-- 2. 残っているBot (Dummy) をすべて削除
	-- (BotSpawnerがまた新しいのを生み出しますが、試合中のゴミはここで消します)
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "Dummy" and child:FindFirstChild("Humanoid") then
			child:Destroy()
		end
	end
end

-- 全員をアリーナに送る
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

	-- チーム分けロジック (TDMの場合)
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

	-- テレポート
	for i, player in ipairs(players) do
		local spawn = spawns[math.random(1, #spawns)]
		if player.Character then
			player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 3, 0))
		end
	end
end

-- マップの読み込み
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

-- スコアリセット
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

	-- ランダムにモード決定
	if math.random() > 0.5 then
		gameMode = "FFA"
		broadcast("MODE: FREE FOR ALL", Color3.new(1, 1, 0))
	else
		gameMode = "TDM"
		broadcast("MODE: TEAM DEATHMATCH", Color3.new(0, 1, 1))
	end

	task.wait(3) -- モード表示を少し長く見せる

	-- マップ読み込み
	loadMap("Map_City")

	-- プレイヤー転送
	teleportToArena()

	broadcast("START!", Color3.new(0, 1, 0))

	-- 試合監視ループ
	local startTime = tick()
	while isMatchActive do
		task.wait(1)

		-- 時間切れチェック
		if tick() - startTime > ROUND_TIME then
			broadcast("TIME UP!", Color3.new(1, 1, 1))
			isMatchActive = false
		end

		-- 勝利判定は onPlayerAdded 内の Changed イベントで行うようになりました
	end

	-- 試合終了処理
	task.wait(3)
	if CurrentMap then
		CurrentMap:Destroy()
	end
	teleportToLobby()
end

local function gameLoop()
	while true do
		-- ロビー待機
		broadcast("Waiting for players...", Color3.new(1, 1, 1))
		repeat
			task.wait(1)
		until #Players:GetPlayers() >= 1

		for i = INTERMISSION_TIME, 1, -1 do
			broadcast("Next match in " .. i, Color3.new(1, 1, 1))
			task.wait(1)
		end

		-- 試合開始
		startRound()
	end
end

-- === イベント接続 ===

-- キル加算処理（プレイヤー同士の場合）
-- Botキルの加算はBotSpawner側でやっているので、ここはプレイヤー用
local function onHumanoidDied(humanoid, player)
	if not isMatchActive then
		return
	end

	local creatorTag = humanoid:FindFirstChild("creator")
	if creatorTag and creatorTag.Value then
		local killer = creatorTag.Value
		if killer and killer:IsA("Player") and killer ~= player then
			-- チームキル防止
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
	-- リーダーボード
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	-- ★★★ 重要: スコアが変わったら即座に勝敗チェック！ ★★★
	-- これにより、Botを倒してもプレイヤーを倒しても勝利判定が動きます
	kills.Changed:Connect(function(newValue)
		if isMatchActive and newValue >= WIN_SCORE then
			broadcast(player.Name .. " WINS!", Color3.new(1, 0.5, 0))
			isMatchActive = false -- これでループが止まり、ロビーへ戻る処理が走る
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
