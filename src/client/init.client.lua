-- src/client/init.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- ★修正: 武器を拾うたびにRobloxが勝手にUIを復活させるのを防ぐ「最強の対策」
local StarterGui = game:GetService("StarterGui")
task.spawn(function()
	-- ゲーム中ずっと、0.1秒ごとに「消せ！」と命令し続ける（重くはならないので安心してください）
	while true do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		task.wait(0.1)
	end
end)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local fireEvent = ReplicatedStorage:WaitForChild("FireBullet")
local effectEvent = ReplicatedStorage:WaitForChild("PlayEffect")
local guardEvent = ReplicatedStorage:WaitForChild("GuardEvent")
local reloadEvent = ReplicatedStorage:WaitForChild("Reload")
local abilityEvent = ReplicatedStorage:WaitForChild("AbilityEvent")
local buildEvent = ReplicatedStorage:WaitForChild("BuildEvent")

local CROSSHAIR_IMAGE = "rbxassetid://128000667256203"
local CROSSHAIR_SIZE = 80
local BLOCK_SIZE = 2

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrosshairGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
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

local SHAPES = { "Block", "Wedge" }
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

local pcControlsFrame = Instance.new("Frame")
pcControlsFrame.Name = "PCControlsFrame"
pcControlsFrame.Size = UDim2.new(0, 180, 0, 350)
pcControlsFrame.Position = UDim2.new(0, 20, 0.5, 0)
pcControlsFrame.AnchorPoint = Vector2.new(0, 0.5)
pcControlsFrame.BackgroundTransparency = 1
pcControlsFrame.Parent = screenGui
pcControlsFrame.Visible = false

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Parent = pcControlsFrame

local pcButtons = {}

local function createPCButton(text, order, actionName)
	local btn = Instance.new("TextButton")
	btn.Name = actionName
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	btn.BackgroundTransparency = 0.4
	btn.LayoutOrder = order
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = pcControlsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 200, 200)
	stroke.Transparency = 0.7
	stroke.Thickness = 1
	stroke.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = btn

	pcButtons[actionName] = btn
	return btn
end

createPCButton("[ R ]  ROTATE", 1, "ReloadOrRotateAction")
createPCButton("[ F ]  SHAPE", 2, "ToggleShapeAction")
createPCButton("[ G ]  COLOR", 3, "ToggleColorAction")
createPCButton("[ V ]  MATERIAL", 4, "ToggleMaterialAction")
createPCButton("[ J ]  SAVE", 5, "SaveAction")
createPCButton("[ K ]  LOAD", 6, "LoadAction")
createPCButton("[ P ]  PUBLISH", 7, "PublishAction")

local function flashButton(actionName)
	local btn = pcButtons[actionName]
	if btn then
		local originalColor = Color3.fromRGB(20, 20, 20)
		local flashColor = Color3.fromRGB(255, 255, 255)
		btn.BackgroundColor3 = flashColor
		btn.BackgroundTransparency = 0.1
		TweenService:Create(btn, TweenInfo.new(0.3), { BackgroundColor3 = originalColor, BackgroundTransparency = 0.4 })
			:Play()
	end
end

local isEquipped = false
local isBuildEquipped = false
local isMouseFree = false

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
			flashButton("ReloadOrRotateAction")
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end

-- === ★スキル（シールド・超能力）の発動 ===
local function triggerSkill(slotName)
	local skillName = player:GetAttribute(slotName)
	if skillName == "Energy Shield" then
		if isEquipped then
			guardEvent:FireServer()
		end
	elseif skillName and skillName ~= "" then
		-- 超能力の場合は、発動したい能力の名前をサーバーに送る
		abilityEvent:FireServer(skillName)
	end
end

local function handleSkillQ(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		triggerSkill("SlotQ")
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function handleSkillZ(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		triggerSkill("SlotZ")
		return Enum.ContextActionResult.Sink
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
		flashButton("SaveAction")
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
		flashButton("LoadAction")
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
		flashButton("PublishAction")
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
		flashButton("ToggleShapeAction")
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
		flashButton("ToggleColorAction")
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
		flashButton("ToggleMaterialAction")
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

for actionName, btn in pairs(pcButtons) do
	btn.MouseButton1Click:Connect(function()
		if not isBuildEquipped then
			return
		end
		if actionName == "ToggleShapeAction" then
			handleToggleShape(actionName, Enum.UserInputState.Begin, nil)
		elseif actionName == "ToggleColorAction" then
			handleToggleColor(actionName, Enum.UserInputState.Begin, nil)
		elseif actionName == "ToggleMaterialAction" then
			handleToggleMaterial(actionName, Enum.UserInputState.Begin, nil)
		elseif actionName == "SaveAction" then
			handleSave(actionName, Enum.UserInputState.Begin, nil)
		elseif actionName == "LoadAction" then
			handleLoad(actionName, Enum.UserInputState.Begin, nil)
		elseif actionName == "PublishAction" then
			handlePublish(actionName, Enum.UserInputState.Begin, nil)
		elseif actionName == "ReloadOrRotateAction" then
			handleReloadOrRotate(actionName, Enum.UserInputState.Begin, nil)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		isMouseFree = true
	end

	if gameProcessed then
		return
	end

	if isBuildEquipped then
		if input.KeyCode == Enum.KeyCode.E then
			tryDestroy()
		elseif input.KeyCode == Enum.KeyCode.R then
			tryRotate()
			flashButton("ReloadOrRotateAction")
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		isMouseFree = false
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

		local currentTool = nil
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and child.Name:match("Bouncy") then
				currentTool = child
				break
			end
		end

		if currentTool then
			humanoid:UnequipTools()
		else
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				local toolToEquip = nil
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") and item.Name:match("Bouncy") then
						toolToEquip = item
						break
					end
				end
				if toolToEquip then
					humanoid:EquipTool(toolToEquip)
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
ContextActionService:BindAction("ToggleColorAction", handleToggleColor, true, Enum.KeyCode.G)
ContextActionService:BindAction("ToggleMaterialAction", handleToggleMaterial, true, Enum.KeyCode.V)
ContextActionService:BindAction("SaveAction", handleSave, true, Enum.KeyCode.J, Enum.KeyCode.DPadRight)
ContextActionService:BindAction("LoadAction", handleLoad, true, Enum.KeyCode.K, Enum.KeyCode.DPadDown)
ContextActionService:BindAction("PublishAction", handlePublish, true, Enum.KeyCode.P, Enum.KeyCode.DPadLeft)
ContextActionService:BindAction("ToggleWeapon", handleToggleWeapon, false, Enum.KeyCode.ButtonY)

-- ★Q枠とZ枠のキー登録
ContextActionService:BindAction("SkillQAction", handleSkillQ, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
ContextActionService:SetPosition("SkillQAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetTitle("SkillQAction", "SKILL (Q)")

ContextActionService:BindAction("SkillZAction", handleSkillZ, true, Enum.KeyCode.Z, Enum.KeyCode.ButtonR1)
ContextActionService:SetPosition("SkillZAction", UDim2.new(1, -100, 1, -100))
ContextActionService:SetTitle("SkillZAction", "SKILL (Z)")

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
	pcControlsFrame.Visible = false

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
	pcControlsFrame.Visible = true

	ContextActionService:SetTitle("FireAction", "BUILD")
	ContextActionService:SetTitle("ReloadOrRotateAction", "ROTATE")
	ContextActionService:SetTitle("DestroyAction", "BREAK")
	ContextActionService:SetTitle("ToggleShapeAction", "SHAPE")
	ContextActionService:SetTitle("ToggleColorAction", "COLOR(G)")
	ContextActionService:SetTitle("ToggleMaterialAction", "MAT(V)")
	ContextActionService:SetTitle("SaveAction", "SAVE(J)")
	ContextActionService:SetTitle("LoadAction", "LOAD(K)")
	ContextActionService:SetTitle("PublishAction", "PUBLISH(P)")
end

local function onBuildUnequip()
	isBuildEquipped = false
	pcControlsFrame.Visible = false
	if not isEquipped then
		screenGui.Enabled = false
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local WEAPONS = {
	["BouncyGun"] = true,
	["BouncyShotgun"] = true,
	["BouncySMG"] = true,
	["BouncyGrenade"] = true,
	["BouncySniper"] = true,
	["BouncyAssaultRifle"] = true,
}

player.CharacterAdded:Connect(function(char)
	isEquipped = false
	isBuildEquipped = false
	screenGui.Enabled = false
	shapeLabel.Visible = false
	colorLabel.Visible = false
	materialLabel.Visible = false
	pcControlsFrame.Visible = false
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and WEAPONS[child.Name] then
			onGunEquip()
		elseif child:IsA("Tool") and child.Name == "BuildTool" then
			onBuildEquip()
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and WEAPONS[child.Name] then
			onGunUnequip()
		elseif child:IsA("Tool") and child.Name == "BuildTool" then
			onBuildUnequip()
		end
	end)
end)

if player.Character then
	for weaponName, _ in pairs(WEAPONS) do
		if player.Character:FindFirstChild(weaponName) then
			onGunEquip()
			break
		end
	end
	if player.Character:FindFirstChild("BuildTool") then
		onBuildEquip()
	end
end

RunService.RenderStepped:Connect(function()
	if isEquipped or isBuildEquipped then
		if isMouseFree then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		end
	end
end)

effectEvent.OnClientEvent:Connect(function(effectType, data)
	if effectType == "Muzzle" then
		local toolHandle = data
		if not toolHandle then
			return
		end
		local spawnCFrame
		-- 修正: toolHandleの親(Tool)全体から Muzzle を探す
		local tool = toolHandle.Parent
		local muzzle = tool and tool:FindFirstChild("Muzzle", true)
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
	elseif effectType == "RubberExplosion" then
		local flash = Instance.new("Part")
		flash.Shape = Enum.PartType.Ball
		flash.Color = data.Color
		flash.Material = Enum.Material.Neon
		flash.Size = Vector3.new(1, 1, 1)
		flash.Position = data.Position
		flash.Anchored = true
		flash.CanCollide = false
		flash.Parent = workspace

		TweenService:Create(
			flash,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(15, 15, 15), Transparency = 1 }
		):Play()
		Debris:AddItem(flash, 0.2)
	end
end)

abilityEvent.OnClientEvent:Connect(function(abilityType, config)
	if abilityType == "HighJump" then
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local currentVel = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(currentVel.X, config.JumpVelocity, currentVel.Z)
			end
		end
	elseif abilityType == "XRay" then
		local char = player.Character
		if not char then
			return
		end

		local endTime = tick() + config.Duration

		task.spawn(function()
			while tick() < endTime do
				for _, child in ipairs(workspace:GetChildren()) do
					if child:IsA("Model") and child:FindFirstChild("Humanoid") and child ~= char then
						if not child:FindFirstChild("XRayHighlight") then
							local hl = Instance.new("Highlight")
							hl.Name = "XRayHighlight"
							hl.FillColor = Color3.fromRGB(255, 0, 0)
							hl.FillTransparency = 0.5
							hl.OutlineColor = Color3.fromRGB(255, 255, 255)
							hl.OutlineTransparency = 0
							hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
							hl.Parent = child
							Debris:AddItem(hl, endTime - tick())
						end
					end
				end
				task.wait(0.5)
			end
		end)
	end
end)

-- ==========================================
-- ★追加: 多段ジャンプの物理システム (連打バグ対策版)
-- ==========================================
local activeMultiJump = false
local maxMultiJumps = 0
local currentMultiJumps = 0
local multiJumpPower = 50
local lastMultiJumpTime = 0 -- ★追加: 連続発動を防ぐタイマー

-- サーバーから「多段ジャンプモード開始」の合図を受け取る
abilityEvent.OnClientEvent:Connect(function(abilityType, config)
	if abilityType == "MultiJump" then
		activeMultiJump = true
		maxMultiJumps = config.MaxJumps
		currentMultiJumps = 0
		multiJumpPower = config.JumpPower
		
		-- 効果時間が切れたらオフにする
		task.delay(config.Duration, function()
			activeMultiJump = false
		end)
	end
end)

-- 地面に着地したら、ジャンプ回数を0にリセットする処理
local function setupJumpReset(character)
	local hum = character:WaitForChild("Humanoid")
	hum.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Landed then
			currentMultiJumps = 0
		end
	end)
end

if player.Character then setupJumpReset(player.Character) end
player.CharacterAdded:Connect(setupJumpReset)

-- スペースキー（ジャンプボタン）が押された瞬間の処理
UserInputService.JumpRequest:Connect(function()
	if not activeMultiJump then return end
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum or hum:GetState() == Enum.HumanoidStateType.Dead then return end
	
	local currentState = hum:GetState()
	
	-- 空中にいる（Freefall または Jumping）時だけ追加ジャンプを許可
	if currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping then
		
		-- ★超重要: 0.2秒のクールダウンを設けて、スペース1回の長押しで回数を全消費するのを防ぐ！
		if tick() - lastMultiJumpTime < 0.2 then return end

		-- (最大回数 - 1) 回まで空中で跳べる（最初の地上ジャンプを1回と数えるため）
		if currentMultiJumps < maxMultiJumps - 1 then
			currentMultiJumps = currentMultiJumps + 1
			lastMultiJumpTime = tick() -- ★跳んだ時間を記録
			
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				-- ★落下中であっても確実に上へ飛ばすため、直接速度を上書きする
				local vel = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(vel.X, multiJumpPower, vel.Z)
				
				-- 空中ジャンプした時の風切り音
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://12222076" -- 軽快なジャンプ音
				sound.Volume = 0.5
				sound.Parent = root
				sound:Play()
				game:GetService("Debris"):AddItem(sound, 1)
			end
		end
	end
end)