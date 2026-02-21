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
local buildEvent = ReplicatedStorage:WaitForChild("BuildEvent") -- ★追加

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

-- ★状態管理
local isEquipped = false -- BouncyGun用
local isBuildEquipped = false -- BuildTool用

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

-- ★追加: 壁を建てる処理
local function handleBuild(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		-- 視線の先にレイを飛ばす（最大30スタッド）
		local rayResult = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 30, rayParams)
		local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * 15) -- 基本は15スタッド先

		if rayResult and rayResult.Distance < 15 then
			targetPos = rayResult.Position
		end

		-- プレイヤーの水平方向を向かせる
		local lookDir = camera.CFrame.LookVector
		local flatLook = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
		if flatLook.Magnitude < 0.001 then
			flatLook = Vector3.new(0, 0, -1)
		end
		local buildCFrame = CFrame.lookAt(targetPos, targetPos + flatLook)

		buildEvent:FireServer(buildCFrame)
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

-- 初期バインド
ContextActionService:BindAction("FireAction", handleFire, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
ContextActionService:BindAction("ReloadAction", handleReload, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
ContextActionService:BindAction(
	"BuildAction",
	handleBuild,
	true,
	Enum.UserInputType.MouseButton1,
	Enum.KeyCode.ButtonR2
) -- ★追加
ContextActionService:BindAction("ToggleWeapon", handleToggle, false, Enum.KeyCode.ButtonY)

ContextActionService:SetTitle("FireAction", "FIRE")
ContextActionService:SetTitle("ReloadAction", "RLD")
ContextActionService:SetTitle("BuildAction", "BUILD") -- ★追加

-- 自動整列防止のダミー座標
ContextActionService:SetPosition("FireAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("ReloadAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("BuildAction", UDim2.new(1, -100, 1, -100)) -- ★追加

local function onGunEquip()
	isEquipped = true
	screenGui.Enabled = true
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function onGunUnequip()
	isEquipped = false
	if not isBuildEquipped then
		screenGui.Enabled = false
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

-- ★追加: ビルドツール装備時
local function onBuildEquip()
	isBuildEquipped = true
	screenGui.Enabled = true
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function onBuildUnequip()
	isBuildEquipped = false
	if not isEquipped then
		screenGui.Enabled = false
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "BouncyGun" then
			onGunEquip()
		elseif child:IsA("Tool") and child.Name == "BuildTool" then
			onBuildEquip()
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == "BouncyGun" then
			onGunUnequip()
		elseif child:IsA("Tool") and child.Name == "BuildTool" then
			onBuildUnequip()
		end
	end)
end)

if player.Character then
	if player.Character:FindFirstChild("BouncyGun") then
		onGunEquip()
	end
	if player.Character:FindFirstChild("BuildTool") then
		onBuildEquip()
	end
end

RunService.RenderStepped:Connect(function()
	if isEquipped or isBuildEquipped then
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

print("Client: Mobile Ready Gun & Build System (No Unbind)")
