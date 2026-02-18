local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- RemoteEvents
local fireEvent = ReplicatedStorage:WaitForChild("FireBullet")
local effectEvent = ReplicatedStorage:WaitForChild("PlayEffect")
local reloadEvent = ReplicatedStorage:WaitForChild("Reload") -- ★リロード用

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

-- === 3. 入力処理（発射 & リロード & 装備切り替え） ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- 発射 (左クリック OR R2トリガー)
	if
		(input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2)
		and isEquipped
	then
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

	-- リロード (Rキー OR コントローラーXボタン/PSなら□)
	if (input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX) and isEquipped then
		reloadEvent:FireServer()
	end

	-- ★追加: 武器の装備/解除 (コントローラーYボタン/PSなら△)
	if input.KeyCode == Enum.KeyCode.ButtonY then
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		-- 今持っているかチェック
		local currentTool = character:FindFirstChild("BouncyGun")

		if currentTool then
			-- 持っているならしまう
			humanoid:UnequipTools()
		else
			-- 持っていないならバックパックから探して装備する
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				local tool = backpack:FindFirstChild("BouncyGun")
				if tool then
					humanoid:EquipTool(tool)
				end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if isEquipped then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

-- === 4. エフェクト ===
effectEvent.OnClientEvent:Connect(function(effectType, data)
	if effectType == "Muzzle" then
		local toolHandle = data
		if not toolHandle then
			return
		end

		local spawnCFrame
		local muzzle = toolHandle:FindFirstChild("Muzzle")

		if muzzle then
			spawnCFrame = muzzle.WorldCFrame
		else
			spawnCFrame = toolHandle.CFrame * CFrame.new(0, 0, -2)
		end

		local flash = Instance.new("Part")
		flash.Shape = Enum.PartType.Ball
		flash.Color = Color3.fromRGB(255, 230, 150)
		flash.Material = Enum.Material.Neon
		flash.Size = Vector3.new(0.8, 0.8, 0.8)
		flash.CFrame = spawnCFrame * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		flash.Anchored = true
		flash.CanCollide = false
		flash.Transparency = 0.1
		flash.Parent = workspace

		local tweenInfo = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = { Size = Vector3.new(3.5, 3.5, 3.5), Transparency = 1 }
		local tween = TweenService:Create(flash, tweenInfo, goal)
		tween:Play()
		Debris:AddItem(flash, 0.1)
	end
end)

print("Client: Reload Input Added")
