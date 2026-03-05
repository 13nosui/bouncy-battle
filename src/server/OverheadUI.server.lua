-- src/server/OverheadUI.server.lua
local Players = game:GetService("Players")

local function createOverheadUI(player, character)
	-- ★修正: 不安定な Head ではなく、絶対に消えない HumanoidRootPart を使う！
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not rootPart then return end

	-- すでに頭上UIがあれば一旦消す（重複防止）
	local oldGui = rootPart:FindFirstChild("OverheadGui")
	if oldGui then oldGui:Destroy() end

	-- ==========================================
	-- ★ 頭上に浮かぶUI（BillboardGui）の作成
	-- ==========================================
	local gui = Instance.new("BillboardGui")
	gui.Name = "OverheadGui"
	gui.Adornee = rootPart -- ★超重要: 確実についていくターゲットを指定
	gui.Size = UDim2.new(0, 200, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3.5, 0) -- RootPart(お腹)から3.5スタッド上に浮かせる
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- 黄金色
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0) -- 黒の縁取り
	textLabel.TextStrokeTransparency = 0
	textLabel.Parent = gui
	gui.Parent = rootPart -- RootPartの中にしまう

	-- ==========================================
	-- ★ テキスト（Lv.〇 | 名前）を更新する処理
	-- ==========================================
	local function updateText()
		local levelVal = 1
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local levelObj = leaderstats:FindFirstChild("Level")
			if levelObj then
				levelVal = levelObj.Value
			end
		end
		
		textLabel.Text = "Lv." .. levelVal .. " | " .. player.Name
	end

	-- ==========================================
	-- ★ 試合中かロビーかで表示/非表示を切り替える処理
	-- ==========================================
	local function updateVisibility()
		local inMatch = player:GetAttribute("InMatch")
		gui.Enabled = not inMatch
	end

	-- 初期設定の実行
	updateText()
	updateVisibility()

	-- ==========================================
	-- ★ イベントの監視
	-- ==========================================
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if leaderstats then
		local levelObj = leaderstats:WaitForChild("Level", 5)
		if levelObj then
			levelObj.Changed:Connect(updateText)
		end
	end

	player:GetAttributeChangedSignal("InMatch"):Connect(updateVisibility)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		createOverheadUI(player, character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		createOverheadUI(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		createOverheadUI(player, character)
	end)
end