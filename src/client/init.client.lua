local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local fireEvent = ReplicatedStorage:WaitForChild("FireBullet")
local effectEvent = ReplicatedStorage:WaitForChild("PlayEffect")
local reloadEvent = ReplicatedStorage:WaitForChild("Reload")

local CROSSHAIR_IMAGE = "rbxassetid://128000667256203"
local CROSSHAIR_SIZE = 80

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

local isEquipped = false

local function handleFire(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isEquipped then
		local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * 1000)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local rayResult = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 1000, rayParams)
		if rayResult then
			targetPos = rayResult.Position
		end
		fireEvent:FireServer(targetPos)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleReload(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isEquipped then
		reloadEvent:FireServer()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleToggle(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		local currentTool = character:FindFirstChild("BouncyGun")
		if currentTool then
			humanoid:UnequipTools()
		else
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				local tool = backpack:FindFirstChild("BouncyGun")
				if tool then
					humanoid:EquipTool(tool)
				end
			end
		end
	end
end

-- ★変更: 起動時に最初からバインドしておく（二度と消さない）
ContextActionService:BindAction("FireAction", handleFire, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
ContextActionService:BindAction("ReloadAction", handleReload, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("FireAction", "FIRE")
ContextActionService:SetTitle("ReloadAction", "RLD")
ContextActionService:BindAction("ToggleWeapon", handleToggle, false, Enum.KeyCode.ButtonY)

local function onEquip()
	isEquipped = true
	screenGui.Enabled = true
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	-- (ここにあったボタンのBindを削除)
end

local function onUnequip()
	isEquipped = false
	screenGui.Enabled = false
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	-- (ここにあったボタンのUnbindを削除)
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

RunService.RenderStepped:Connect(function()
	if isEquipped then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

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
		local tween = TweenService:Create(flash, tweenInfo, { Size = Vector3.new(3.5, 3.5, 3.5), Transparency = 1 })
		tween:Play()
		Debris:AddItem(flash, 0.1)
	end
end)

print("Client: Mobile Ready Gun System (No Unbind)")
