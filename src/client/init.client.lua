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
local buildEvent = ReplicatedStorage:WaitForChild("BuildEvent")

local CROSSHAIR_IMAGE = "rbxassetid://128000667256203"
local CROSSHAIR_SIZE = 80
local BLOCK_SIZE = 4

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrosshairGui"
screenGui.IgnoreGuiInset = true
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

local shapeLabel = Instance.new("TextLabel")
shapeLabel.Name = "ShapeLabel"
shapeLabel.Size = UDim2.new(0, 300, 0, 40)
shapeLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
shapeLabel.AnchorPoint = Vector2.new(0.5, 0)
shapeLabel.BackgroundTransparency = 1
shapeLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
shapeLabel.TextStrokeTransparency = 0
shapeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
shapeLabel.Font = Enum.Font.GothamBlack
shapeLabel.TextSize = 24
shapeLabel.Text = "SHAPE: BLOCK"
shapeLabel.Parent = screenGui

local SHAPES = { "Block", "Wedge", "Cylinder", "Sphere" }
local currentShapeIndex = 1

local isEquipped = false
local isBuildEquipped = false

local function getRayResult()
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { player.Character }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 100, rayParams)
end

local function handleFireOrBuild(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		if isEquipped then
			local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * 1000)
			local rayResult = getRayResult()
			if rayResult then
				targetPos = rayResult.Position
			end
			fireEvent:FireServer(targetPos)
			return Enum.ContextActionResult.Sink
		elseif isBuildEquipped then
			local rayResult = getRayResult()
			local targetPos
			if rayResult then
				targetPos = rayResult.Position + (rayResult.Normal * (BLOCK_SIZE / 2))
			else
				targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * 15)
			end
			local currentShape = SHAPES[currentShapeIndex]
			buildEvent:FireServer("Build", targetPos, currentShape)
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end

-- ★新設: 回転の処理を独立させました
local function tryRotate()
	if not isBuildEquipped then
		return
	end
	local rayResult = getRayResult()
	if rayResult and rayResult.Instance and rayResult.Instance.Name == "PlayerWall" then
		buildEvent:FireServer("Rotate", rayResult.Instance)
	end
end

local function handleReloadOrRotate(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		if isEquipped then
			reloadEvent:FireServer()
			return Enum.ContextActionResult.Sink
		elseif isBuildEquipped then
			tryRotate()
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end

local function tryDestroy()
	if not isBuildEquipped then
		return
	end
	local rayResult = getRayResult()
	if rayResult and rayResult.Instance and rayResult.Instance.Name == "PlayerWall" then
		buildEvent:FireServer("Destroy", rayResult.Instance)
	end
end

local function handleDestroy(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		tryDestroy()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

-- ★ 強化: Eキー(破壊)とRキー(回転)が他の操作に邪魔されないように確実に拾う！
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if isBuildEquipped then
		if input.KeyCode == Enum.KeyCode.E then
			tryDestroy()
		elseif input.KeyCode == Enum.KeyCode.R then
			tryRotate()
		end
	end
end)

local function handleToggleShape(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		currentShapeIndex = currentShapeIndex + 1
		if currentShapeIndex > #SHAPES then
			currentShapeIndex = 1
		end
		shapeLabel.Text = "SHAPE: " .. string.upper(SHAPES[currentShapeIndex])

		shapeLabel.TextSize = 30
		TweenService:Create(shapeLabel, TweenInfo.new(0.2), { TextSize = 24 }):Play()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleToggleWeapon(actionName, inputState, inputObject)
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

ContextActionService:BindAction(
	"FireAction",
	handleFireOrBuild,
	true,
	Enum.UserInputType.MouseButton1,
	Enum.KeyCode.ButtonR2
)
ContextActionService:BindAction(
	"ReloadOrRotateAction",
	handleReloadOrRotate,
	true,
	Enum.KeyCode.R,
	Enum.KeyCode.ButtonX
)
ContextActionService:BindAction(
	"DestroyAction",
	handleDestroy,
	true,
	Enum.KeyCode.E,
	Enum.UserInputType.MouseButton2,
	Enum.KeyCode.ButtonL2
)
ContextActionService:BindAction("ToggleShapeAction", handleToggleShape, true, Enum.KeyCode.F, Enum.KeyCode.DPadUp)
ContextActionService:BindAction("ToggleWeapon", handleToggleWeapon, false, Enum.KeyCode.ButtonY)

ContextActionService:SetPosition("FireAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("ReloadOrRotateAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("DestroyAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("ToggleShapeAction", UDim2.new(1, -100, 1, -100))

local function onGunEquip()
	isEquipped = true
	screenGui.Enabled = true
	shapeLabel.Visible = false
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	ContextActionService:SetTitle("FireAction", "FIRE")
	ContextActionService:SetTitle("ReloadOrRotateAction", "RLD")
end

local function onGunUnequip()
	isEquipped = false
	if not isBuildEquipped then
		screenGui.Enabled = false
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function onBuildEquip()
	isBuildEquipped = true
	screenGui.Enabled = true
	shapeLabel.Visible = true
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	ContextActionService:SetTitle("FireAction", "BUILD")
	ContextActionService:SetTitle("ReloadOrRotateAction", "ROTATE")
	ContextActionService:SetTitle("DestroyAction", "BREAK")
	ContextActionService:SetTitle("ToggleShapeAction", "SHAPE")
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
		TweenService:Create(
			flash,
			TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(3.5, 3.5, 3.5), Transparency = 1 }
		):Play()
		Debris:AddItem(flash, 0.1)
	end
end)
