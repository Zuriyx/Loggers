local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local connections = {}
local closed = false
local logCounter = 0
local thumbnailItems = {}
local currentViewerPreview = nil
local currentViewerRecord = nil
local viewerHovering = false
local viewerDragging = false
local viewerDragLastPos = nil
local isMinimized = false

local function trackConnection(conn)
	table.insert(connections, conn)
	return conn
end

local function disconnectAll()
	for _, conn in ipairs(connections) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	table.clear(connections)
end

local function clearThumbnailItems()
	for _, item in ipairs(thumbnailItems) do
		if item and item.destroy then
			pcall(item.destroy)
		end
	end
	table.clear(thumbnailItems)
end

local function destroyCurrentViewerPreview()
	if currentViewerPreview and currentViewerPreview.destroy then
		pcall(currentViewerPreview.destroy)
	end
	currentViewerPreview = nil
	currentViewerRecord = nil
	viewerDragging = false
	viewerDragLastPos = nil
end

local function copyToClipboard(text)
	local ok = false
	if typeof(setclipboard) == "function" then
		ok = pcall(setclipboard, text)
	elseif typeof(toclipboard) == "function" then
		ok = pcall(toclipboard, text)
	end
	return ok
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MeshLoggerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainSizeNormal = UDim2.new(0, 460, 0, 320)
local mainSizeMin = UDim2.new(0, 460, 0, 30)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = mainSizeNormal
main.Position = UDim2.new(0, 20, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
main.BorderSizePixel = 1
main.BorderColor3 = Color3.fromRGB(0, 0, 0)
main.ZIndex = 1
main.Parent = screenGui

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 60)
mainStroke.Thickness = 1
mainStroke.Parent = main

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 1
topBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
topBar.Active = true
topBar.Selectable = false
topBar.ZIndex = 2
topBar.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Font = Enum.Font.SourceSansSemibold
title.Text = "Mesh Logger"
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 45, 1, 0)
closeButton.Position = UDim2.new(1, -45, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.SourceSans
closeButton.Text = "X"
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
closeButton.AutoButtonColor = false
closeButton.ZIndex = 3
closeButton.Parent = topBar

local minButton = Instance.new("TextButton")
minButton.Name = "MinButton"
minButton.Size = UDim2.new(0, 45, 1, 0)
minButton.Position = UDim2.new(1, -90, 0, 0)
minButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
minButton.BorderSizePixel = 0
minButton.Font = Enum.Font.SourceSans
minButton.Text = "-"
minButton.TextSize = 22
minButton.TextColor3 = Color3.fromRGB(220, 220, 220)
minButton.AutoButtonColor = false
minButton.ZIndex = 3
minButton.Parent = topBar

trackConnection(closeButton.MouseEnter:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end))
trackConnection(closeButton.MouseLeave:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
end))

trackConnection(minButton.MouseEnter:Connect(function()
	minButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end))
trackConnection(minButton.MouseLeave:Connect(function()
	minButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
end))

local contentContainer = Instance.new("Frame")
contentContainer.Name = "Content"
contentContainer.Size = UDim2.new(1, 0, 1, -30)
contentContainer.Position = UDim2.new(0, 0, 0, 30)
contentContainer.BackgroundTransparency = 1
contentContainer.ZIndex = 2
contentContainer.Parent = main

local listPanel = Instance.new("Frame")
listPanel.Name = "ListPanel"
listPanel.BackgroundTransparency = 1
listPanel.Size = UDim2.new(1, 0, 1, 0)
listPanel.ZIndex = 2
listPanel.Parent = contentContainer

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 28)
searchBox.Position = UDim2.new(0, 10, 0, 10)
searchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
searchBox.BorderColor3 = Color3.fromRGB(60, 60, 60)
searchBox.Font = Enum.Font.SourceSans
searchBox.PlaceholderText = "Search..."
searchBox.Text = ""
searchBox.TextSize = 14
searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 3
searchBox.Parent = listPanel

local countLabel = Instance.new("TextLabel")
countLabel.BackgroundTransparency = 1
countLabel.Size = UDim2.new(1, -20, 0, 18)
countLabel.Position = UDim2.new(0, 10, 0, 42)
countLabel.Font = Enum.Font.SourceSans
countLabel.Text = "Logged meshes: 0"
countLabel.TextSize = 13
countLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.ZIndex = 3
countLabel.Parent = listPanel

local scrolling = Instance.new("ScrollingFrame")
scrolling.Name = "List"
scrolling.Size = UDim2.new(1, -20, 1, -65)
scrolling.Position = UDim2.new(0, 10, 0, 60)
scrolling.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scrolling.BorderColor3 = Color3.fromRGB(50, 50, 50)
scrolling.ScrollBarThickness = 6
scrolling.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
scrolling.AutomaticCanvasSize = Enum.AutomaticSize.None
scrolling.ZIndex = 3
scrolling.Parent = listPanel

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 6)
listPadding.PaddingRight = UDim.new(0, 6)
listPadding.Parent = scrolling

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrolling

local viewerPanel = Instance.new("Frame")
viewerPanel.Name = "ViewerPanel"
viewerPanel.BackgroundTransparency = 1
viewerPanel.Size = UDim2.new(1, 0, 1, 0)
viewerPanel.Visible = false
viewerPanel.ZIndex = 4
viewerPanel.Parent = contentContainer

local viewerTitle = Instance.new("TextLabel")
viewerTitle.BackgroundTransparency = 1
viewerTitle.Size = UDim2.new(1, -20, 0, 20)
viewerTitle.Position = UDim2.new(0, 10, 0, 5)
viewerTitle.Font = Enum.Font.SourceSansSemibold
viewerTitle.Text = "Mesh Viewer"
viewerTitle.TextSize = 16
viewerTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
viewerTitle.TextXAlignment = Enum.TextXAlignment.Left
viewerTitle.ZIndex = 5
viewerTitle.Parent = viewerPanel

local viewerInfo = Instance.new("TextLabel")
viewerInfo.BackgroundTransparency = 1
viewerInfo.Size = UDim2.new(1, -20, 0, 32)
viewerInfo.Position = UDim2.new(0, 10, 0, 25)
viewerInfo.Font = Enum.Font.SourceSans
viewerInfo.Text = ""
viewerInfo.TextSize = 13
viewerInfo.TextWrapped = true
viewerInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
viewerInfo.TextXAlignment = Enum.TextXAlignment.Left
viewerInfo.TextYAlignment = Enum.TextYAlignment.Top
viewerInfo.ZIndex = 5
viewerInfo.Parent = viewerPanel

local backButton = Instance.new("TextButton")
backButton.Size = UDim2.new(0, 70, 0, 24)
backButton.Position = UDim2.new(0, 10, 0, 60)
backButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
backButton.BorderColor3 = Color3.fromRGB(80, 80, 80)
backButton.Font = Enum.Font.SourceSans
backButton.Text = "Back"
backButton.TextSize = 14
backButton.TextColor3 = Color3.fromRGB(240, 240, 240)
backButton.AutoButtonColor = true
backButton.ZIndex = 5
backButton.Parent = viewerPanel

local copyIdsViewerBtn = Instance.new("TextButton")
copyIdsViewerBtn.Size = UDim2.new(0, 80, 0, 24)
copyIdsViewerBtn.Position = UDim2.new(0, 85, 0, 60)
copyIdsViewerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
copyIdsViewerBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
copyIdsViewerBtn.Font = Enum.Font.SourceSans
copyIdsViewerBtn.Text = "Copy IDs"
copyIdsViewerBtn.TextSize = 14
copyIdsViewerBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
copyIdsViewerBtn.AutoButtonColor = true
copyIdsViewerBtn.ZIndex = 5
copyIdsViewerBtn.Parent = viewerPanel

local copyPathViewerBtn = Instance.new("TextButton")
copyPathViewerBtn.Size = UDim2.new(0, 80, 0, 24)
copyPathViewerBtn.Position = UDim2.new(0, 170, 0, 60)
copyPathViewerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
copyPathViewerBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
copyPathViewerBtn.Font = Enum.Font.SourceSans
copyPathViewerBtn.Text = "Copy Path"
copyPathViewerBtn.TextSize = 14
copyPathViewerBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
copyPathViewerBtn.AutoButtonColor = true
copyPathViewerBtn.ZIndex = 5
copyPathViewerBtn.Parent = viewerPanel

local viewerViewport = Instance.new("ViewportFrame")
viewerViewport.Name = "ViewerViewport"
viewerViewport.Size = UDim2.new(1, -20, 1, -95)
viewerViewport.Position = UDim2.new(0, 10, 0, 88)
viewerViewport.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
viewerViewport.BorderColor3 = Color3.fromRGB(60, 60, 60)
viewerViewport.Ambient = Color3.fromRGB(190, 190, 190)
viewerViewport.LightColor = Color3.fromRGB(255, 255, 255)
viewerViewport.LightDirection = Vector3.new(-1, -1, -1)
viewerViewport.Active = true
viewerViewport.Selectable = false
viewerViewport.ZIndex = 5
viewerViewport.Parent = viewerPanel

local records = {}
local seen = {}

local function getPath(inst)
	local parts = {}
	local current = inst
	while current and current ~= game do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, " > ")
end

local function normalize(text)
	return string.lower(tostring(text or ""))
end

local function matchesQuery(record, query)
	query = normalize(query)
	if query == "" then
		return true
	end
	local fields = {
		record.displayName,
		record.path,
		record.kind,
		record.meshId,
		record.textureId,
		record.meshType,
	}
	for _, field in ipairs(fields) do
		if normalize(field):find(query, 1, true) then
			return true
		end
	end
	return false
end

local function refreshCanvas()
	task.defer(function()
		scrolling.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
end

trackConnection(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas))

local function refreshFilter()
	local query = searchBox.Text
	for _, record in ipairs(records) do
		record.row.Visible = matchesQuery(record, query)
	end
	countLabel.Text = ("Logged meshes: %d"):format(#records)
	refreshCanvas()
end

local function animateNewRow(row)
	local baseColor = Color3.fromRGB(40, 40, 40)
	local litColor = Color3.fromRGB(70, 70, 70)
	row.BackgroundColor3 = litColor
	local tweenInfo = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(row, tweenInfo, { BackgroundColor3 = baseColor }):Play()
end

local function createPreview(viewportFrame, inst, zoomMultiplier, destroyViewportOnCleanup)
	for _, child in ipairs(viewportFrame:GetChildren()) do
		child:Destroy()
	end
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera
	local renderObject
	if inst:IsA("MeshPart") then
		local clone = inst:Clone()
		clone.Anchored = true
		clone.CanCollide = false
		clone.CanTouch = false
		clone.CanQuery = false
		clone.CastShadow = false
		clone.Parent = worldModel
		renderObject = clone
	elseif inst:IsA("SpecialMesh") then
		local basePart = Instance.new("Part")
		basePart.Anchored = true
		basePart.CanCollide = false
		basePart.CanTouch = false
		basePart.CanQuery = false
		basePart.CastShadow = false
		basePart.Size = Vector3.new(1, 1, 1)
		basePart.Transparency = 0
		basePart.Color = Color3.fromRGB(235, 235, 235)
		basePart.Material = Enum.Material.SmoothPlastic
		basePart.Parent = worldModel
		local mesh = inst:Clone()
		mesh.Parent = basePart
		renderObject = basePart
	end
	if not renderObject then
		return nil
	end
	local cf, size = worldModel:GetBoundingBox()
	local maxAxis = math.max(size.X, size.Y, size.Z)
	local dist = math.max(6.5, maxAxis * (zoomMultiplier or 2.35))
	camera.CFrame = CFrame.new(cf.Position + Vector3.new(dist, dist * 0.35, dist), cf.Position)
	local item = {
		worldModel = worldModel,
		camera = camera,
		object = renderObject,
		destroy = function()
			if destroyViewportOnCleanup then
				if viewportFrame then
					viewportFrame:Destroy()
				end
			else
				if viewportFrame and viewportFrame.Parent then
					for _, child in ipairs(viewportFrame:GetChildren()) do
						child:Destroy()
					end
					viewportFrame.CurrentCamera = nil
				end
			end
		end,
	}
	return item
end

local function spinThumbnailItem(item, dt)
	local obj = item and item.object
	if not obj or not obj.Parent then
		return
	end
	local pivot
	if obj:IsA("BasePart") then
		pivot = obj.CFrame
	elseif obj:IsA("Model") then
		pivot = obj:GetPivot()
	end
	if not pivot then
		return
	end
	local rotated = pivot * CFrame.Angles(0, dt * 0.9, 0)
	if obj:IsA("BasePart") then
		obj.CFrame = rotated
	elseif obj:IsA("Model") then
		obj:PivotTo(rotated)
	end
	local worldModel = item.worldModel
	local camera = item.camera
	if worldModel and camera then
		local cf, size = worldModel:GetBoundingBox()
		local maxAxis = math.max(size.X, size.Y, size.Z)
		local dist = math.max(6.5, maxAxis * 2.35)
		camera.CFrame = CFrame.new(cf.Position + Vector3.new(dist, dist * 0.35, dist), cf.Position)
	end
end

local function updateViewerCamera(viewerState)
	if not viewerState then
		return
	end
	local camera = viewerState.camera
	if not camera then
		return
	end
	local target = viewerState.target
	local yaw = viewerState.yaw
	local pitch = viewerState.pitch
	local distance = viewerState.distance
	local offset = Vector3.new(
		math.cos(pitch) * math.sin(yaw),
		math.sin(pitch),
		math.cos(pitch) * math.cos(yaw)
	) * distance
	camera.CFrame = CFrame.lookAt(target + offset, target)
end

local function closeViewer()
	if not viewerPanel.Visible then
		return
	end
	destroyCurrentViewerPreview()
	viewerPanel.Visible = false
	listPanel.Visible = true
end

local function openViewer(record)
	if not record or not record.instance or not record.instance.Parent then
		return
	end
	destroyCurrentViewerPreview()
	listPanel.Visible = false
	viewerPanel.Visible = true
	viewerInfo.Text = string.format(
		"%s | MeshId: %s | TextureId: %s | Path: %s",
		record.kind or "Mesh",
		(record.meshId ~= "" and record.meshId or "None"),
		(record.textureId ~= "" and record.textureId or "None"),
		record.path or "Unknown"
	)
	currentViewerRecord = record
	for _, child in ipairs(viewerViewport:GetChildren()) do
		child:Destroy()
	end
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewerViewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	camera.Parent = viewerViewport
	viewerViewport.CurrentCamera = camera
	local renderObject
	if record.instance:IsA("MeshPart") then
		local clone = record.instance:Clone()
		clone.Anchored = true
		clone.CanCollide = false
		clone.CanTouch = false
		clone.CanQuery = false
		clone.CastShadow = false
		clone.Parent = worldModel
		renderObject = clone
	elseif record.instance:IsA("SpecialMesh") then
		local basePart = Instance.new("Part")
		basePart.Anchored = true
		basePart.CanCollide = false
		basePart.CanTouch = false
		basePart.CanQuery = false
		basePart.CastShadow = false
		basePart.Size = Vector3.new(1, 1, 1)
		basePart.Transparency = 0
		basePart.Color = Color3.fromRGB(235, 235, 235)
		basePart.Material = Enum.Material.SmoothPlastic
		basePart.Parent = worldModel
		local mesh = record.instance:Clone()
		mesh.Parent = basePart
		renderObject = basePart
	end
	if not renderObject then
		return
	end
	local cf, size = worldModel:GetBoundingBox()
	local maxAxis = math.max(size.X, size.Y, size.Z)
	currentViewerPreview = {
		worldModel = worldModel,
		camera = camera,
		object = renderObject,
		target = cf.Position,
		yaw = math.rad(45),
		pitch = math.rad(-18),
		distance = math.max(6.5, maxAxis * 3.2),
		destroy = function()
			if viewerViewport and viewerViewport.Parent then
				for _, child in ipairs(viewerViewport:GetChildren()) do
					child:Destroy()
				end
				viewerViewport.CurrentCamera = nil
			end
		end,
	}
	updateViewerCamera(currentViewerPreview)
end

local function makeCopyString(meshId, textureId)
	return string.format(
		"MESHID: %s TEXTUREID: %s",
		(meshId ~= "" and meshId or "None"),
		(textureId ~= "" and textureId or "None")
	)
end

local function addRecord(kind, inst, meshId, textureId, meshType)
	logCounter += 1
	local displayName = inst.Name
	local path = getPath(inst)
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.new(1, 0, 0, 72)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	row.BorderColor3 = Color3.fromRGB(60, 60, 60)
	row.LayoutOrder = -logCounter
	row.ZIndex = 3
	row.Parent = scrolling

	local previewButton = Instance.new("TextButton")
	previewButton.Name = "PreviewButton"
	previewButton.Size = UDim2.new(0, 56, 0, 56)
	previewButton.Position = UDim2.new(0, 8, 0, 8)
	previewButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	previewButton.BorderColor3 = Color3.fromRGB(70, 70, 70)
	previewButton.Text = ""
	previewButton.AutoButtonColor = false
	previewButton.ZIndex = 4
	previewButton.Parent = row

	local previewViewport = Instance.new("ViewportFrame")
	previewViewport.Name = "Preview"
	previewViewport.Size = UDim2.new(1, 0, 1, 0)
	previewViewport.BackgroundTransparency = 1
	previewViewport.Ambient = Color3.fromRGB(180, 180, 180)
	previewViewport.LightColor = Color3.fromRGB(255, 255, 255)
	previewViewport.LightDirection = Vector3.new(-1, -1, -1)
	previewViewport.ZIndex = 4
	previewViewport.Parent = previewButton

	local kindLabel = Instance.new("TextLabel")
	kindLabel.BackgroundTransparency = 1
	kindLabel.Position = UDim2.new(0, 74, 0, 6)
	kindLabel.Size = UDim2.new(1, -84, 0, 16)
	kindLabel.Font = Enum.Font.SourceSansSemibold
	kindLabel.TextSize = 14
	kindLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	kindLabel.TextXAlignment = Enum.TextXAlignment.Left
	kindLabel.Text = kind
	kindLabel.ZIndex = 4
	kindLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 74, 0, 22)
	nameLabel.Size = UDim2.new(1, -84, 0, 14)
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = "Name: " .. displayName
	nameLabel.ZIndex = 4
	nameLabel.Parent = row

	local pathLabel = Instance.new("TextLabel")
	pathLabel.BackgroundTransparency = 1
	pathLabel.Position = UDim2.new(0, 74, 0, 36)
	pathLabel.Size = UDim2.new(1, -84, 0, 14)
	pathLabel.Font = Enum.Font.SourceSans
	pathLabel.TextSize = 12
	pathLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	pathLabel.TextXAlignment = Enum.TextXAlignment.Left
	pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
	pathLabel.Text = "Path: " .. path
	pathLabel.ZIndex = 4
	pathLabel.Parent = row

	local normalizedMeshId = tostring(meshId or "")
	local normalizedTextureId = tostring(textureId or "")

	local infoLabel = Instance.new("TextLabel")
	infoLabel.BackgroundTransparency = 1
	infoLabel.Position = UDim2.new(0, 74, 0, 50)
	infoLabel.Size = UDim2.new(1, -84, 0, 14)
	infoLabel.Font = Enum.Font.SourceSans
	infoLabel.TextSize = 12
	infoLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
	infoLabel.Text = string.format(
		"MESH: %s | TEX: %s",
		(normalizedMeshId ~= "" and normalizedMeshId or "None"),
		(normalizedTextureId ~= "" and normalizedTextureId or "None")
	)
	infoLabel.ZIndex = 4
	infoLabel.Parent = row

	local record = {
		instance = inst,
		kind = kind,
		displayName = displayName,
		path = path,
		meshId = normalizedMeshId,
		textureId = normalizedTextureId,
		meshType = meshType or "",
		row = row,
	}

	local thumbnailItem = createPreview(previewViewport, inst, 2.35, true)
	if thumbnailItem then
		table.insert(thumbnailItems, thumbnailItem)
	end

	trackConnection(previewButton.MouseButton1Click:Connect(function()
		openViewer(record)
	end))

	table.insert(records, 1, record)
	animateNewRow(row)
	refreshFilter()
end

local function isMeshInstance(inst)
	return inst:IsA("MeshPart") or inst:IsA("SpecialMesh")
end

local function logIfMesh(inst)
	if closed or seen[inst] then
		return
	end
	if inst:IsA("MeshPart") then
		seen[inst] = true
		addRecord("MeshPart", inst, tostring(inst.MeshId), tostring(inst.TextureID), "")
	elseif inst:IsA("SpecialMesh") then
		seen[inst] = true
		addRecord("SpecialMesh", inst, tostring(inst.MeshId), tostring(inst.TextureId), tostring(inst.MeshType))
	end
end

for _, inst in ipairs(Workspace:GetDescendants()) do
	if isMeshInstance(inst) then
		logIfMesh(inst)
	end
end

trackConnection(Workspace.DescendantAdded:Connect(function(inst)
	if isMeshInstance(inst) then
		logIfMesh(inst)
	end
end))

trackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	refreshFilter()
end))

trackConnection(RunService.RenderStepped:Connect(function(dt)
	if closed then
		return
	end
	for _, item in ipairs(thumbnailItems) do
		spinThumbnailItem(item, dt)
	end
	if currentViewerPreview then
		updateViewerCamera(currentViewerPreview)
	end
end))

trackConnection(viewerViewport.MouseEnter:Connect(function()
	viewerHovering = true
end))

trackConnection(viewerViewport.MouseLeave:Connect(function()
	viewerHovering = false
	viewerDragging = false
	viewerDragLastPos = nil
end))

trackConnection(viewerViewport.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		viewerDragging = true
		viewerDragLastPos = input.Position
	end
end))

trackConnection(UserInputService.InputChanged:Connect(function(input)
	if closed then
		return
	end
	if viewerDragging and input.UserInputType == Enum.UserInputType.MouseMovement and currentViewerPreview then
		local lastPos = viewerDragLastPos
		if lastPos then
			local delta = input.Position - lastPos
			currentViewerPreview.yaw -= delta.X * 0.01
			currentViewerPreview.pitch = math.clamp(currentViewerPreview.pitch + delta.Y * 0.01, -1.45, 1.45)
			updateViewerCamera(currentViewerPreview)
		end
		viewerDragLastPos = input.Position
		return
	end
	if viewerHovering and input.UserInputType == Enum.UserInputType.MouseWheel and currentViewerPreview then
		local wheelDelta = input.Position.Z
		if wheelDelta ~= 0 then
			currentViewerPreview.distance = math.clamp(currentViewerPreview.distance - (wheelDelta * 0.75), 2.5, 60)
			updateViewerCamera(currentViewerPreview)
		end
	end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		viewerDragging = false
		viewerDragLastPos = nil
	end
end))

local dragging = false
local dragStart
local startPos

trackConnection(topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end))

trackConnection(topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end))

trackConnection(UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end))

trackConnection(minButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		main.Size = mainSizeMin
		contentContainer.Visible = false
	else
		main.Size = mainSizeNormal
		contentContainer.Visible = true
	end
end))

trackConnection(copyIdsViewerBtn.MouseButton1Click:Connect(function()
	if currentViewerRecord then
		local formatted = makeCopyString(currentViewerRecord.meshId, currentViewerRecord.textureId)
		local copied = copyToClipboard(formatted)
		local originalText = copyIdsViewerBtn.Text
		copyIdsViewerBtn.Text = copied and "Copied!" or "Failed"
		task.delay(1, function()
			if copyIdsViewerBtn and copyIdsViewerBtn.Parent then
				copyIdsViewerBtn.Text = originalText
			end
		end)
	end
end))

trackConnection(copyPathViewerBtn.MouseButton1Click:Connect(function()
	if currentViewerRecord then
		local copied = copyToClipboard(currentViewerRecord.path)
		local originalText = copyPathViewerBtn.Text
		copyPathViewerBtn.Text = copied and "Copied!" or "Failed"
		task.delay(1, function()
			if copyPathViewerBtn and copyPathViewerBtn.Parent then
				copyPathViewerBtn.Text = originalText
			end
		end)
	end
end))

local function closeGui()
	if closed then
		return
	end
	closed = true
	destroyCurrentViewerPreview()
	disconnectAll()
	clearThumbnailItems()
	if screenGui then
		screenGui:Destroy()
	end
end

trackConnection(closeButton.MouseButton1Click:Connect(closeGui))
trackConnection(backButton.MouseButton1Click:Connect(closeViewer))

refreshCanvas()
refreshFilter()
