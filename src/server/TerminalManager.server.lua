-- src/server/TerminalManager.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ★修正: クライアントより確実に先にイベントを作成する
local openLoadoutEvent = ReplicatedStorage:FindFirstChild("OpenLoadout")
if not openLoadoutEvent then
	openLoadoutEvent = Instance.new("RemoteEvent")
	openLoadoutEvent.Name = "OpenLoadout"
	openLoadoutEvent.Parent = ReplicatedStorage
end

local function createTerminal()
	local terminal = Instance.new("Part")
	terminal.Name = "LoadoutTerminal"
	terminal.Size = Vector3.new(5, 6, 2)

	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn", true)
	if lobbySpawn then
		terminal.Position = lobbySpawn.Position + Vector3.new(-15, 3, -15)
	else
		terminal.Position = Vector3.new(0, 3, -15)
	end

	terminal.Anchored = true
	terminal.Material = Enum.Material.Neon
	terminal.Color = Color3.fromRGB(0, 150, 255)
	terminal.Parent = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Access Terminal"
	prompt.ObjectText = "LOADOUT"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.Parent = terminal

	prompt.Triggered:Connect(function(player)
		print(player.Name .. " が端末にアクセスしました！") -- 動作確認用のログ
		openLoadoutEvent:FireClient(player)
	end)
end

task.spawn(function()
	task.wait(2)
	createTerminal()
end)
