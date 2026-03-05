-- src/server/BotSpawner.server.lua
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- ==========================================
-- ★ 撮影・テスト用：同時に出現させるBotの数
-- ==========================================
local TARGET_BOT_COUNT = 5

local dummyTemplate = ServerStorage:FindFirstChild("Dummy") or Workspace:FindFirstChild("Dummy")
local WeaponsFolder = ServerStorage:FindFirstChild("Weapons")

if dummyTemplate and dummyTemplate.Parent == Workspace then
	dummyTemplate.Archivable = true
	dummyTemplate = dummyTemplate:Clone()
	dummyTemplate.Parent = ServerStorage

	local original = Workspace:FindFirstChild("Dummy")
	if original then
		original:Destroy()
	end
end

if not dummyTemplate then
	warn("BotSpawner: Dummyのテンプレートが見つかりません！")
	return
end

-- ==========================================
-- ★ 追加: 乱闘を演出する本格的なBot AI！
-- ==========================================
local function startBotAI(bot)
	local humanoid = bot:FindFirstChild("Humanoid")
	local rootPart = bot:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		return
	end

	-- 見た目を良くするため、武器リストの中からランダムな武器を持たせる！
	if WeaponsFolder then
		local weapons = WeaponsFolder:GetChildren()
		if #weapons > 0 then
			local randomWeapon = weapons[math.random(1, #weapons)]:Clone()
			randomWeapon.Parent = bot
			humanoid:EquipTool(randomWeapon)
		end
	end

	-- AIの思考ループ
	task.spawn(function()
		while humanoid.Health > 0 do
			-- 0.5〜1.5秒間隔で行動を判断する（人間らしいランダムなテンポ）
			task.wait(math.random(5, 15) / 10)

			-- 1. 一番近い敵（プレイヤーまたは他のBot）を探す
			local nearestTarget = nil
			local shortestDistance = 150 -- 索敵範囲

			for _, char in ipairs(Workspace:GetChildren()) do
				if char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and char ~= bot then
					-- アリーナ内にいるキャラだけを狙う
					if char.PrimaryPart and char.PrimaryPart.Position.Y > -50 then
						local targetRoot = char:FindFirstChild("HumanoidRootPart")
						if targetRoot then
							local dist = (targetRoot.Position - rootPart.Position).Magnitude
							if dist < shortestDistance then
								shortestDistance = dist
								nearestTarget = targetRoot
							end
						end
					end
				end
			end

			if nearestTarget then
				-- 2. 敵の近くに向かって少しバラけながら移動する
				local offset = Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
				humanoid:MoveTo(nearestTarget.Position + offset)

				-- 3. たまにジャンプして弾を避けるような「キャラコン」をする
				if math.random() < 0.3 then
					humanoid.Jump = true
				end

				-- 4. 敵の方向を向いて弾を撃つ！
				-- （少しエイムをずらして百発百中にならないようにする）
				local aimOffset = Vector3.new(math.random(-3, 3), math.random(-2, 2), math.random(-3, 3))
				local direction = (nearestTarget.Position + aimOffset - rootPart.Position).Unit

				-- Bot専用の「赤い跳ねる弾」を生成
				local bullet = Instance.new("Part")
				bullet.Size = Vector3.new(1.5, 1.5, 1.5)
				bullet.Shape = Enum.PartType.Ball
				bullet.Color = Color3.fromRGB(255, 50, 50) -- 危険な赤色！
				bullet.Material = Enum.Material.Neon
				bullet.CFrame = rootPart.CFrame * CFrame.new(0, 1, -3)

				-- Bouncy Battleらしい跳ねる物理設定
				bullet.CustomPhysicalProperties = PhysicalProperties.new(0.5, 1.0, 1.0, 100, 100)
				bullet.Parent = Workspace
				bullet.AssemblyLinearVelocity = direction * 120 -- 弾速
				Debris:AddItem(bullet, 3)

				-- 発射音
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://6808892437"
				sound.Volume = 0.5
				sound.Parent = rootPart
				sound:Play()
				Debris:AddItem(sound, 2)

				-- 当たり判定（当たったらダメージ＆キル判定）
				local connection
				connection = bullet.Touched:Connect(function(hit)
					local hitChar = hit.Parent
					if hitChar and hitChar ~= bot and hitChar:FindFirstChild("Humanoid") then
						local hitHum = hitChar.Humanoid
						if hitHum.Health > 0 then
							hitHum:TakeDamage(20)

							-- キルログやエフェクトのために誰が倒したかを記録
							if hitHum.Health <= 0 and not hitHum:FindFirstChild("creator") then
								local tag = Instance.new("ObjectValue")
								tag.Name = "creator"
								tag.Value = bot -- Bot自身が倒したと記録する
								tag.Parent = hitHum
							end
						end
						connection:Disconnect()
						bullet:Destroy()
					end
				end)
			else
				-- 敵がいない時は適当にアリーナ内を散歩する
				humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30)))
			end
		end
	end)
end

-- ==========================================

local function spawnBot()
	local bot = dummyTemplate:Clone()
	bot.Name = "Dummy"

	local activeMap = Workspace:FindFirstChild("ActiveMap")
	local spawns = {}
	if activeMap then
		for _, child in ipairs(activeMap:GetDescendants()) do
			if child:IsA("SpawnLocation") then
				table.insert(spawns, child)
			end
		end
	end

	if #spawns > 0 then
		local randomSpawn = spawns[math.random(1, #spawns)]
		bot:PivotTo(randomSpawn.CFrame + Vector3.new(0, 3, 0))
	else
		bot:PivotTo(CFrame.new(math.random(-20, 20), 10, math.random(-20, 20)))
	end

	bot.Parent = Workspace

	-- ★ スポーンしたBotに思考回路（AI）を接続する！
	startBotAI(bot)
end

task.spawn(function()
	while true do
		task.wait(2)

		if Workspace:FindFirstChild("ActiveMap") then
			local currentBotCount = 0

			for _, child in ipairs(Workspace:GetChildren()) do
				if child.Name == "Dummy" and child:FindFirstChild("Humanoid") then
					if child.Humanoid.Health > 0 then
						currentBotCount = currentBotCount + 1
					end
				end
			end

			if currentBotCount < TARGET_BOT_COUNT then
				for i = 1, (TARGET_BOT_COUNT - currentBotCount) do
					spawnBot()
				end
			end
		else
			for _, child in ipairs(Workspace:GetChildren()) do
				if child.Name == "Dummy" and child:FindFirstChild("Humanoid") then
					child:Destroy()
				end
			end
		end
	end
end)
