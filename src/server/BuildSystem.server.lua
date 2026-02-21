local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local buildEvent = ReplicatedStorage:WaitForChild("BuildEvent")

-- 連続で置きすぎないようにするためのクールダウン管理
local cooldowns = {}
local BUILD_COOLDOWN = 0.5 -- 0.5秒に1回置ける

buildEvent.OnServerEvent:Connect(function(player, targetCFrame)
	-- クールダウンのチェック
	if cooldowns[player.UserId] and (tick() - cooldowns[player.UserId] < BUILD_COOLDOWN) then
		return
	end
	cooldowns[player.UserId] = tick()

	-- 壁（ブロック）を生成
	local block = Instance.new("Part")
	block.Name = "PlayerWall"
	block.Size = Vector3.new(10, 8, 2) -- 横10、高さ8、厚さ2の壁
	block.Anchored = true -- 動かないように固定

	-- BouncyBattleっぽく、弾がよく跳ねる素材にする
	block.Material = Enum.Material.SmoothPlastic
	block.Color = Color3.fromRGB(0, 200, 255) -- 目立つシアン色
	block.Transparency = 0.2 -- 少し透けさせる

	-- よく跳ねる物理特性を追加
	block.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 1.2, 1.0, 1.0)

	-- プレイヤーが向いている方向を向くように配置
	block.CFrame = targetCFrame + Vector3.new(0, 4, 0) -- 地面にめり込まないように少し上げる
	block.Parent = workspace

	-- 配置した時にポンッという音を鳴らす
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://135549838877133" -- ブロックを置く音
	sound.Volume = 0.8
	sound.Parent = block
	sound:Play()

	-- マップが壁だらけにならないように、10秒後に自動で消去する
	Debris:AddItem(block, 10)
end)

print("Server: BuildSystem Loaded")
