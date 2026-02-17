local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remoteEventName = "FireBullet"
local fireEvent = ReplicatedStorage:WaitForChild(remoteEventName)

local effectEventName = "PlayEffect"
local effectEvent = ReplicatedStorage:WaitForChild(effectEventName)

-- === 設定 ===
local CROSSHAIR_IMAGE = "rbxassetid://128000667256203" -- 見やすい円形の照準
local CROSSHAIR_SIZE = 80 -- サイズ（ピクセル）大きくして見やすく

-- === 1. 照準GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrosshairGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.Enabled = false

local crosshair = Instance.new("ImageLabel")
crosshair.Name = "Crosshair"
crosshair.Image = CROSSHAIR_IMAGE
crosshair.BackgroundTransparency = 1
crosshair.Size = UDim2.new(0, CROSSHAIR_SIZE, 0, CROSSHAIR_SIZE)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.Parent = screenGui

-- === 2. 銃装備の監視 ===
local isEquipped = false

local function onEquip()
	isEquipped = true
	screenGui.Enabled = true
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function onUnequip()
	isEquipped = false
	screenGui.Enabled = false
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "BouncyGun" then
			onEquip()
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == "BouncyGun" then
			onUnequip()
		end
	end)
end)

if player.Character then
	local tool = player.Character:FindFirstChild("BouncyGun")
	if tool then
		onEquip()
	end
end

-- === 3. 発射入力 ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and isEquipped then
		local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * 1000)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local rayResult = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 1000, rayParams)
		if rayResult then
			targetPos = rayResult.Position
		end
		fireEvent:FireServer(targetPos)
	end
end)

RunService.RenderStepped:Connect(function()
	if isEquipped then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

-- === 4. 完成版マズルフラッシュ ===
effectEvent.OnClientEvent:Connect(function(effectType, data)
	if effectType == "Muzzle" then
		local toolHandle = data
		if not toolHandle then
			return
		end

		-- 位置を決める
		local spawnCFrame
		local muzzle = toolHandle:FindFirstChild("Muzzle")

		if muzzle then
			spawnCFrame = muzzle.WorldCFrame
		else
			-- Muzzleがない場合の保険（少し前に出す）
			spawnCFrame = toolHandle.CFrame * CFrame.new(0, 0, -2)
		end

		-- ★閃光エフェクト（黄色いネオン球）
		local flash = Instance.new("Part")
		flash.Shape = Enum.PartType.Ball
		flash.Color = Color3.fromRGB(255, 230, 150) -- 明るいクリームイエロー
		flash.Material = Enum.Material.Neon -- 発光
		flash.Size = Vector3.new(0.8, 0.8, 0.8) -- 最初は小さめ
		flash.CFrame = spawnCFrame * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) -- ランダム回転
		flash.Anchored = true
		flash.CanCollide = false
		flash.Transparency = 0.1 -- 最初はくっきり
		flash.Parent = workspace

		-- アニメーション（0.06秒で一気に膨らんで消える）
		local tweenInfo = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = {
			Size = Vector3.new(3.5, 3.5, 3.5), -- ドンと大きく
			Transparency = 1, -- 透明に
		}
		local tween = TweenService:Create(flash, tweenInfo, goal)
		tween:Play()

		-- ゴミ掃除
		Debris:AddItem(flash, 0.1)
	end
end)

print("Client: Final VFX Loaded")
