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

local SHAPES = { "Block", "Wedge", "Cylinder", "Sphere" }
local COLORS = {
	{ name = "CYAN", val = Color3.fromRGB(0, 200, 255) },
	{ name = "RED", val = Color3.fromRGB(255, 50, 50) },
	{ name = "GREEN", val = Color3.fromRGB(50, 255, 50) },
	{ name = "YELLOW", val = Color3.fromRGB(255, 255, 50) },
	{ name = "PURPLE", val = Color3.fromRGB(150, 50, 255) },
	{ name = "WHITE", val = Color3.fromRGB(255, 255, 255) },
	{ name = "BLACK", val = Color3.fromRGB(40, 40, 40) },
}
local MATERIALS = {
	{ name = "PLASTIC", val = Enum.Material.SmoothPlastic },
	{ name = "NEON", val = Enum.Material.Neon },
	{ name = "WOOD", val = Enum.Material.Wood },
	{ name = "BRICK", val = Enum.Material.Brick },
	{ name = "GLASS", val = Enum.Material.Glass },
	{ name = "ICE", val = Enum.Material.Ice },
	{ name = "FOIL", val = Enum.Material.Foil },
}

local currentShapeIndex = 1
local currentColorIndex = 1
local currentMaterialIndex = 1

local shapeLabel = Instance.new("TextLabel")
shapeLabel.Size = UDim2.new(0, 300, 0, 30)
shapeLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
shapeLabel.AnchorPoint = Vector2.new(0.5, 0)
shapeLabel.BackgroundTransparency = 1
shapeLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
shapeLabel.TextStrokeTransparency = 0
shapeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
shapeLabel.Font = Enum.Font.GothamBlack
shapeLabel.TextSize = 20
shapeLabel.Text = "SHAPE: " .. string.upper(SHAPES[currentShapeIndex])
shapeLabel.Parent = screenGui

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0, 300, 0, 30)
colorLabel.Position = UDim2.new(0.5, 0, 0.6, 25)
colorLabel.AnchorPoint = Vector2.new(0.5, 0)
colorLabel.BackgroundTransparency = 1
colorLabel.TextColor3 = COLORS[currentColorIndex].val
colorLabel.TextStrokeTransparency = 0
colorLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
colorLabel.Font = Enum.Font.GothamBlack
colorLabel.TextSize = 20
colorLabel.Text = "COLOR: " .. COLORS[currentColorIndex].name
colorLabel.Parent = screenGui

local materialLabel = Instance.new("TextLabel")
materialLabel.Size = UDim2.new(0, 300, 0, 30)
materialLabel.Position = UDim2.new(0.5, 0, 0.6, 50)
materialLabel.AnchorPoint = Vector2.new(0.5, 0)
materialLabel.BackgroundTransparency = 1
materialLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
materialLabel.TextStrokeTransparency = 0
materialLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
materialLabel.Font = Enum.Font.GothamBlack
materialLabel.TextSize = 20
materialLabel.Text = "MAT: " .. MATERIALS[currentMaterialIndex].name
materialLabel.Parent = screenGui

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
			local currentColor = COLORS[currentColorIndex].val
			local currentMaterial = MATERIALS[currentMaterialIndex].val
			buildEvent:FireServer("Build", targetPos, currentShape, currentColor, currentMaterial)
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end

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

local function handleSave(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		local saveEvent = ReplicatedStorage:FindFirstChild("SaveStageEvent")
		if saveEvent then
			saveEvent:FireServer()
		end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleLoad(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		local loadEvent = ReplicatedStorage:FindFirstChild("LoadStageEvent")
		if loadEvent then
			loadEvent:FireServer()
		end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handlePublish(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		local publishEvent = ReplicatedStorage:FindFirstChild("PublishStageEvent")
		if publishEvent then
			publishEvent:FireServer()
		end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleToggleShape(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		currentShapeIndex = currentShapeIndex + 1
		if currentShapeIndex > #SHAPES then
			currentShapeIndex = 1
		end
		shapeLabel.Text = "SHAPE: " .. string.upper(SHAPES[currentShapeIndex])
		shapeLabel.TextSize = 26
		TweenService:Create(shapeLabel, TweenInfo.new(0.2), { TextSize = 20 }):Play()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleToggleColor(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		currentColorIndex = currentColorIndex + 1
		if currentColorIndex > #COLORS then
			currentColorIndex = 1
		end
		colorLabel.Text = "COLOR: " .. COLORS[currentColorIndex].name
		colorLabel.TextColor3 = COLORS[currentColorIndex].val
		colorLabel.TextSize = 26
		TweenService:Create(colorLabel, TweenInfo.new(0.2), { TextSize = 20 }):Play()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleToggleMaterial(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isBuildEquipped then
		currentMaterialIndex = currentMaterialIndex + 1
		if currentMaterialIndex > #MATERIALS then
			currentMaterialIndex = 1
		end
		materialLabel.Text = "MAT: " .. MATERIALS[currentMaterialIndex].name
		materialLabel.TextSize = 26
		TweenService:Create(materialLabel, TweenInfo.new(0.2), { TextSize = 20 }):Play()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

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
ContextActionService:BindAction("ToggleColorAction", handleToggleColor, true, Enum.KeyCode.G) -- ★Gキーに変更
ContextActionService:BindAction("ToggleMaterialAction", handleToggleMaterial, true, Enum.KeyCode.V)
ContextActionService:BindAction("SaveAction", handleSave, true, Enum.KeyCode.J, Enum.KeyCode.DPadRight)
ContextActionService:BindAction("LoadAction", handleLoad, true, Enum.KeyCode.K, Enum.KeyCode.DPadDown)
ContextActionService:BindAction("PublishAction", handlePublish, true, Enum.KeyCode.P, Enum.KeyCode.DPadLeft)
ContextActionService:BindAction("ToggleWeapon", handleToggleWeapon, false, Enum.KeyCode.ButtonY)

ContextActionService:SetPosition("FireAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("ReloadOrRotateAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("DestroyAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("ToggleShapeAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("ToggleColorAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("ToggleMaterialAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("SaveAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("LoadAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetPosition("PublishAction", UDim2.new(1, -100, 1, -100))

local function onGunEquip()
	isEquipped = true
	screenGui.Enabled = true
	shapeLabel.Visible = false
	colorLabel.Visible = false
	materialLabel.Visible = false
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
	colorLabel.Visible = true
	materialLabel.Visible = true
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	ContextActionService:SetTitle("FireAction", "BUILD")
	ContextActionService:SetTitle("ReloadOrRotateAction", "ROTATE")
	ContextActionService:SetTitle("DestroyAction", "BREAK")
	ContextActionService:SetTitle("ToggleShapeAction", "SHAPE")
	ContextActionService:SetTitle("ToggleColorAction", "COLOR(G)") -- ★Gに変更
	ContextActionService:SetTitle("ToggleMaterialAction", "MAT(V)")
	ContextActionService:SetTitle("SaveAction", "SAVE(J)")
	ContextActionService:SetTitle("LoadAction", "LOAD(K)")
	ContextActionService:SetTitle("PublishAction", "PUBLISH(P)")
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
	isEquipped = false
	isBuildEquipped = false
	screenGui.Enabled = false
	shapeLabel.Visible = false
	colorLabel.Visible = false
	materialLabel.Visible = false
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

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
