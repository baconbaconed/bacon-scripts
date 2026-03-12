--this is the only script ill ever leave unobfuscated, because velocity is a little bitch about obfuscating
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local HttpService = game:GetService("HttpService")

local wait = task and task.wait or wait
local spawn = task and task.spawn or spawn

local player = Players.LocalPlayer
while not player do
	wait()
	player = Players.LocalPlayer
end

local connections = {}

local animCounts = {}
local animFrames = {}
local banned = {}
local seenTracks = {}
local scriptTracks = {}

local selectedId = nil

local function getId(raw)
	if not raw then return nil end
	local s = tostring(raw)
	return s:match("%d+")
end

local function copyClipboard(text)
	local func = setclipboard or toclipboard or (Clipboard and Clipboard.set) or print
	pcall(function() func(text) end)
end

local function getAnimator(char)
	char = char or player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	return hum:FindFirstChildOfClass("Animator") or hum
end

local function playAnim(id,speed,loop)
	if banned[id] then return end
	local animator = getAnimator()
	if not animator or not id or id == "" then return end
	
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..id

	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = loop or false
	track:Play(0, 1, speed or 1)

	scriptTracks[track] = true
	table.insert(connections, track.Stopped:Connect(function()
		scriptTracks[track] = nil
	end))
end

local function stopAnim(id)
	local animator = getAnimator()
	if not animator then return end
	
	for _,track in pairs(animator:GetPlayingAnimationTracks()) do
		local tid = getId(track.Animation.AnimationId)
		if tid == id then
			track:Stop()
			scriptTracks[track] = nil
		end
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "BaconLoggerGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success, parent = pcall(function() return game:GetService("CoreGui") end)
if success and parent then
	gui.Parent = parent
else
	gui.Parent = player:WaitForChild("PlayerGui")
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.RightControl then
		gui.Enabled = not gui.Enabled
	end
end))

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0,600,0,480)
mainFrame.Position = UDim2.new(0,50,0,50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(0, 80, 80)
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.ClipsDescendants = false
mainFrame.ZIndex = 1
mainFrame.Parent = gui

local keybinds = {}
local keybindFile = "bacon_logger_binds.json"

local function saveBinds()
	local data = {}
	for _, bind in pairs(keybinds) do
		table.insert(data, {
			id = bind.id,
			key = bind.key and bind.key.Name or nil,
			hold = bind.hold,
			speed = bind.speed,
			loop = bind.loop
		})
	end
	if writefile then
		writefile(keybindFile, HttpService:JSONEncode(data))
	end
end

local sideFrame = Instance.new("Frame")
sideFrame.Name = "SideFrame"
sideFrame.Size = UDim2.new(0, 200, 0, 480)
sideFrame.Position = UDim2.new(0, 655, 0, 50)
sideFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
sideFrame.BorderSizePixel = 1
sideFrame.BorderColor3 = Color3.fromRGB(0, 80, 80)
sideFrame.Active = true
sideFrame.ZIndex = 1
sideFrame.Visible = true
sideFrame.Parent = gui

local draggingSide
local dragInputSide
local dragStartSide
local startPosSide

local function updateSide(input)
	local delta = input.Position - dragStartSide
	sideFrame.Position = UDim2.new(startPosSide.X.Scale, startPosSide.X.Offset + delta.X, startPosSide.Y.Scale, startPosSide.Y.Offset + delta.Y)
end

table.insert(connections, sideFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSide = true
		dragStartSide = input.Position
		startPosSide = sideFrame.Position

		table.insert(connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingSide = false
			end
		end))
	end
end))

table.insert(connections, sideFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInputSide = input
	end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInputSide and draggingSide then
		updateSide(input)
	end
end))

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

table.insert(connections, mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		table.insert(connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end))
	end
end))

table.insert(connections, mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end))

local top = Instance.new("Frame")
top.Name = "TopBar"
top.Size = UDim2.new(1,0,0,25)
top.BackgroundColor3 = Color3.fromRGB(0, 40, 40)
top.BorderSizePixel = 0
top.ZIndex = 2
top.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Text = "bacon's advanced logger"
title.Size = UDim2.new(1,-30,1,0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 200)
title.Font = Enum.Font.Code
title.ZIndex = 3
title.Parent = top

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 25, 1, 0)
closeButton.Position = UDim2.new(1, -25, 0, 0)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 3
closeButton.Parent = top

local minimize = Instance.new("TextButton")
minimize.Name = "MinimizeButton"
minimize.Size = UDim2.new(0, 25, 1, 0)
minimize.Position = UDim2.new(1, -50, 0, 0)
minimize.Text = "-"
minimize.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BorderSizePixel = 0
minimize.ZIndex = 3
minimize.Parent = top

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.PlaceholderText = "Search animations..."
searchBox.Position = UDim2.new(0,5,0,30)
searchBox.Size = UDim2.new(0.55,-10,0,25)
searchBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
searchBox.TextColor3 = Color3.new(1,1,1)
searchBox.BorderSizePixel = 1
searchBox.BorderColor3 = Color3.fromRGB(0, 100, 100)
searchBox.ZIndex = 2
searchBox.Parent = mainFrame

table.insert(connections, searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = searchBox.Text:lower()
	for id, entry in pairs(animFrames) do
		local visible = (id:lower():find(query) or entry.Text:lower():find(query))
		entry.Parent.Visible = visible
	end
end))

local list = Instance.new("ScrollingFrame")
list.Name = "AnimList"
list.Position = UDim2.new(0,5,0,60)
list.Size = UDim2.new(0.55,-10,1,-65)
list.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
list.BorderSizePixel = 1
list.BorderColor3 = Color3.fromRGB(0, 60, 60)
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 150)
list.CanvasSize = UDim2.new(0,0,0,0)
list.ClipsDescendants = true
list.ZIndex = 2
list.Visible = true
list.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,2)
layout.Parent = list

table.insert(connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end))

local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.Position = UDim2.new(0.55,5,0,30)
controls.Size = UDim2.new(0.45,-10,1,-35)
controls.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controls.BorderSizePixel = 1
controls.BorderColor3 = Color3.fromRGB(0, 60, 60)
controls.ClipsDescendants = false
controls.ZIndex = 2
controls.Visible = true
controls.Parent = mainFrame

local minimized = false

table.insert(connections, minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		mainFrame.Size = UDim2.new(0,200,0,25)
		list.Visible = false
		controls.Visible = false
		searchBox.Visible = false
		minimize.Text = "+"
	else
		mainFrame.Size = UDim2.new(0,600,0,480)
		list.Visible = true
		controls.Visible = true
		searchBox.Visible = true
		minimize.Text = "-"
	end
end))

local running = true

closeButton.MouseButton1Click:Connect(function()
	running = false
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	gui:Destroy()
end)

local function makeLabel(text,y)
	local l = Instance.new("TextLabel")
	l.Text = text
	l.Position = UDim2.new(0,10,0,y)
	l.Size = UDim2.new(1,-20,0,20)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(0, 200, 150)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.Code
	l.ZIndex = 3
	l.Visible = true
	l.Parent = controls
end

makeLabel("Animation ID",10)

local idBox = Instance.new("TextBox")
idBox.Position = UDim2.new(0,10,0,30)
idBox.Size = UDim2.new(1,-20,0,25)
idBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
idBox.TextColor3 = Color3.new(1,1,1)
idBox.PlaceholderColor3 = Color3.fromRGB(0, 100, 80)
idBox.BorderSizePixel = 1
idBox.BorderColor3 = Color3.fromRGB(0, 120, 100)
idBox.ZIndex = 3
idBox.Visible = true
idBox.Parent = controls

makeLabel("Speed",65)

local speedBox = Instance.new("TextBox")
speedBox.Text = "1"
speedBox.Position = UDim2.new(0,10,0,85)
speedBox.Size = UDim2.new(1,-20,0,25)
speedBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.BorderSizePixel = 1
speedBox.BorderColor3 = Color3.fromRGB(0, 120, 100)
speedBox.ZIndex = 3
speedBox.Visible = true
speedBox.Parent = controls

local loopToggle = Instance.new("TextButton")
loopToggle.Text = "Loop: OFF"
loopToggle.Position = UDim2.new(0,10,0,120)
loopToggle.Size = UDim2.new(1,-20,0,25)
loopToggle.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
loopToggle.TextColor3 = Color3.new(1,1,1)
loopToggle.BorderSizePixel = 1
loopToggle.BorderColor3 = Color3.fromRGB(120, 0, 0)
loopToggle.ZIndex = 3
loopToggle.Visible = true
loopToggle.Parent = controls

local looped = false

table.insert(connections, loopToggle.MouseButton1Click:Connect(function()
	looped = not looped
	loopToggle.Text = "Loop: "..(looped and "ON" or "OFF")
	loopToggle.BackgroundColor3 = looped and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
	loopToggle.BorderColor3 = looped and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end))

local function button(text,y,callback)

	local b = Instance.new("TextButton")
	b.Text = text
	b.Position = UDim2.new(0,10,0,y)
	b.Size = UDim2.new(1,-20,0,25)
	b.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 1
	b.BorderColor3 = Color3.fromRGB(0, 120, 100)
	b.ZIndex = 3
	b.Visible = true
	b.Parent = controls

	table.insert(connections, b.MouseButton1Click:Connect(callback))

end

button("Play",160,function()

	local id = idBox.Text
	local speed = tonumber(speedBox.Text) or 1

	playAnim(id,speed,looped)

end)

button("Stop",195,function()

	stopAnim(idBox.Text)

end)

button("Stop All",230,function()

	local animator = getAnimator()
	if animator then
		for _,track in pairs(animator:GetPlayingAnimationTracks()) do
			track:Stop()
		end
	end
	scriptTracks = {}

end)

button("Ban",265,function()

	banned[idBox.Text] = true
	stopAnim(idBox.Text)

end)

button("Unban",300,function()

	banned[idBox.Text] = nil

end)

button("Copy ID",335,function()

	copyClipboard(idBox.Text)

end)

button("Clear List",370,function()

	for id,entry in pairs(animFrames) do
		if entry.Parent and entry.Parent:IsA("Frame") then
			entry.Parent:Destroy()
		else
			entry:Destroy()
		end
	end
	
	animCounts = {}
	animFrames = {}
	seenTracks = {}

end)

local globalLogging = false
local globalToggle = Instance.new("TextButton")
globalToggle.Text = "Global Log: OFF"
globalToggle.Position = UDim2.new(0,10,0,405)
globalToggle.Size = UDim2.new(1,-20,0,25)
globalToggle.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
globalToggle.TextColor3 = Color3.new(1,1,1)
globalToggle.BorderSizePixel = 1
globalToggle.BorderColor3 = Color3.fromRGB(120, 0, 0)
globalToggle.ZIndex = 3
globalToggle.Visible = true
globalToggle.Parent = controls

table.insert(connections, globalToggle.MouseButton1Click:Connect(function()
	globalLogging = not globalLogging
	globalToggle.Text = "Global Log: "..(globalLogging and "ON" or "OFF")
	globalToggle.BackgroundColor3 = globalLogging and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
	globalToggle.BorderColor3 = globalLogging and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
end))

local openSide = Instance.new("TextButton")
openSide.Name = "OpenSideButton"
openSide.Size = UDim2.new(0, 50, 1, 0)
openSide.Position = UDim2.new(1, -100, 0, 0)
openSide.Text = "Binds"
openSide.BackgroundColor3 = Color3.fromRGB(0, 80, 80)
openSide.TextColor3 = Color3.new(1, 1, 1)
openSide.BorderSizePixel = 0
openSide.ZIndex = 3
openSide.Parent = top

table.insert(connections, openSide.MouseButton1Click:Connect(function()
	sideFrame.Visible = not sideFrame.Visible
end))

local sideTitle = Instance.new("TextLabel")
sideTitle.Size = UDim2.new(1, 0, 0, 25)
sideTitle.BackgroundColor3 = Color3.fromRGB(0, 40, 40)
sideTitle.Text = "keybinds"
sideTitle.TextColor3 = Color3.fromRGB(0, 255, 200)
sideTitle.Font = Enum.Font.Code
sideTitle.ZIndex = 2
sideTitle.Parent = sideFrame

local sideList = Instance.new("ScrollingFrame")
sideList.Position = UDim2.new(0, 5, 0, 30)
sideList.Size = UDim2.new(1, -10, 1, -65)
sideList.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
sideList.BorderSizePixel = 0
sideList.CanvasSize = UDim2.new(0, 0, 0, 0)
sideList.ScrollBarThickness = 2
sideList.ZIndex = 2
sideList.Parent = sideFrame

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 5)
sideLayout.Parent = sideList

table.insert(connections, sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	sideList.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y)
end))

local addB = Instance.new("TextButton")
addB.Size = UDim2.new(1, -10, 0, 25)
addB.Position = UDim2.new(0, 5, 1, -30)
addB.Text = "Add Bind"
addB.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
addB.TextColor3 = Color3.new(1, 1, 1)
addB.ZIndex = 3
addB.Parent = sideFrame

local function addBindUI(bindData)
	local bFrame = Instance.new("Frame")
	bFrame.Size = UDim2.new(1, 0, 0, 140)
	bFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bFrame.BorderSizePixel = 1
	bFrame.BorderColor3 = Color3.fromRGB(0, 60, 60)
	bFrame.ZIndex = 3
	bFrame.Parent = sideList

	local idL = Instance.new("TextBox")
	idL.Size = UDim2.new(1, -10, 0, 20)
	idL.Position = UDim2.new(0, 5, 0, 5)
	idL.Text = bindData.id or "ID"
	idL.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	idL.TextColor3 = Color3.new(1, 1, 1)
	idL.Font = Enum.Font.Code
	idL.ZIndex = 4
	idL.Parent = bFrame

	local keyB = Instance.new("TextButton")
	keyB.Size = UDim2.new(1, -10, 0, 20)
	keyB.Position = UDim2.new(0, 5, 0, 30)
	keyB.Text = "Key: " .. (bindData.key and bindData.key.Name or "None")
	keyB.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	keyB.TextColor3 = Color3.new(1, 1, 1)
	keyB.ZIndex = 4
	keyB.Parent = bFrame

	local holdT = Instance.new("TextButton")
	holdT.Size = UDim2.new(1, -10, 0, 20)
	holdT.Position = UDim2.new(0, 5, 0, 55)
	holdT.Text = "Hold: " .. (bindData.hold and "ON" or "OFF")
	holdT.BackgroundColor3 = bindData.hold and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
	holdT.TextColor3 = Color3.new(1, 1, 1)
	holdT.ZIndex = 4
	holdT.Parent = bFrame

	local speedB = Instance.new("TextBox")
	speedB.Size = UDim2.new(1, -10, 0, 20)
	speedB.Position = UDim2.new(0, 5, 0, 80)
	speedB.Text = "Speed: " .. (bindData.speed or 1)
	speedB.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	speedB.TextColor3 = Color3.new(1, 1, 1)
	speedB.ZIndex = 4
	speedB.Parent = bFrame

	local loopT = Instance.new("TextButton")
	loopT.Size = UDim2.new(1, -10, 0, 20)
	loopT.Position = UDim2.new(0, 5, 0, 105)
	loopT.Text = "Loop: " .. (bindData.loop and "ON" or "OFF")
	loopT.BackgroundColor3 = bindData.loop and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
	loopT.TextColor3 = Color3.new(1, 1, 1)
	loopT.ZIndex = 4
	loopT.Parent = bFrame

	local del = Instance.new("TextButton")
	del.Size = UDim2.new(0, 15, 0, 15)
	del.Position = UDim2.new(1, -15, 0, 0)
	del.Text = "X"
	del.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
	del.TextColor3 = Color3.new(1, 1, 1)
	del.ZIndex = 5
	del.Parent = bFrame

	local settingKey = false
	table.insert(connections, keyB.MouseButton1Click:Connect(function()
		settingKey = true
		keyB.Text = "..."
	end))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if settingKey and input.UserInputType == Enum.UserInputType.Keyboard then
			settingKey = false
			bindData.key = input.KeyCode
			keyB.Text = "Key: " .. input.KeyCode.Name
			saveBinds()
		end
	end))

	table.insert(connections, idL:GetPropertyChangedSignal("Text"):Connect(function()
		bindData.id = idL.Text
		saveBinds()
	end))

	table.insert(connections, holdT.MouseButton1Click:Connect(function()
		bindData.hold = not bindData.hold
		holdT.Text = "Hold: " .. (bindData.hold and "ON" or "OFF")
		holdT.BackgroundColor3 = bindData.hold and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
		saveBinds()
	end))

	table.insert(connections, speedB:GetPropertyChangedSignal("Text"):Connect(function()
		bindData.speed = tonumber(speedB.Text:match("[%d%.]+")) or 1
		saveBinds()
	end))

	table.insert(connections, loopT.MouseButton1Click:Connect(function()
		bindData.loop = not bindData.loop
		loopT.Text = "Loop: " .. (bindData.loop and "ON" or "OFF")
		loopT.BackgroundColor3 = bindData.loop and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
		saveBinds()
	end))

	table.insert(connections, del.MouseButton1Click:Connect(function()
		stopAnim(bindData.id)
		for i, v in pairs(keybinds) do
			if v == bindData then
				table.remove(keybinds, i)
				break
			end
		end
		bFrame:Destroy()
		saveBinds()
	end))
end

local sideClose = Instance.new("TextButton")
sideClose.Size = UDim2.new(0, 20, 0, 20)
sideClose.Position = UDim2.new(1, -20, 0, 0)
sideClose.Text = "X"
sideClose.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
sideClose.TextColor3 = Color3.new(1, 1, 1)
sideClose.ZIndex = 3
sideClose.Parent = sideFrame

local sideMinimize = Instance.new("TextButton")
sideMinimize.Size = UDim2.new(0, 20, 0, 20)
sideMinimize.Position = UDim2.new(1, -45, 0, 0)
sideMinimize.Text = "-"
sideMinimize.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
sideMinimize.TextColor3 = Color3.new(1, 1, 1)
sideMinimize.ZIndex = 3
sideMinimize.Parent = sideFrame

local sideMinimized = false
table.insert(connections, sideMinimize.MouseButton1Click:Connect(function()
	sideMinimized = not sideMinimized
	if sideMinimized then
		sideFrame.Size = UDim2.new(0, 100, 0, 25)
		sideList.Visible = false
		addB.Visible = false
		sideMinimize.Text = "+"
	else
		sideFrame.Size = UDim2.new(0, 200, 0, 480)
		sideList.Visible = true
		addB.Visible = true
		sideMinimize.Text = "-"
	end
end))

table.insert(connections, sideClose.MouseButton1Click:Connect(function()
	sideFrame.Visible = false
end))

table.insert(connections, addB.MouseButton1Click:Connect(function()
	local nb = {id = "", key = nil, hold = false, speed = 1, loop = false, active = false, tracks = {}}
	table.insert(keybinds, nb)
	addBindUI(nb)
end))

local function loadBinds()
	if readfile and isfile and isfile(keybindFile) then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(keybindFile)) end)
		if ok and type(data) == "table" then
			for _, b in pairs(data) do
				local nb = {
					id = b.id,
					key = b.key and Enum.KeyCode[b.key] or nil,
					hold = b.hold,
					speed = b.speed,
					loop = b.loop,
					active = false,
					tracks = {}
				}
				table.insert(keybinds, nb)
				addBindUI(nb)
			end
		end
	end
end

loadBinds()

task.spawn(function()
	while running do
		for _, bind in pairs(keybinds) do
			if bind.active and not banned[bind.id] then
				local isPlaying = false
				local animator = getAnimator()
				if animator then
					for _, t in pairs(animator:GetPlayingAnimationTracks()) do
						if getId(t.Animation.AnimationId) == bind.id and t.IsPlaying then
							isPlaying = true
							break
						end
					end
				end
				if not isPlaying then
					playAnim(bind.id, bind.speed, bind.loop)
				end
			end
		end
		task.wait()
	end
end)

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for _, bind in pairs(keybinds) do
		if bind.key and input.KeyCode == bind.key then
			if bind.hold then
				bind.active = true
				playAnim(bind.id, bind.speed, bind.loop)
			else
				bind.active = not bind.active
				if not bind.active then
					stopAnim(bind.id)
				else
					playAnim(bind.id, bind.speed, bind.loop)
				end
			end
		end
	end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	for _, bind in pairs(keybinds) do
		if bind.key and input.KeyCode == bind.key and bind.hold then
			bind.active = false
			stopAnim(bind.id)
		end
	end
end))

local function createEntry(id,name,key)

	key = key or id

	local entryFrame = Instance.new("Frame")
	entryFrame.Name = key
	entryFrame.Size = UDim2.new(1, -5, 0, 25)
	entryFrame.BackgroundTransparency = 1
	entryFrame.ZIndex = 3
	entryFrame.Parent = list

	local entry = Instance.new("TextButton")
	entry.Size = UDim2.new(1, -50, 1, 0)
	entry.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	entry.TextColor3 = Color3.fromRGB(0, 255, 200)
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.Text = "(1) " .. id .. " | " .. name
	entry.BorderSizePixel = 1
	entry.BorderColor3 = Color3.fromRGB(0, 100, 100)
	entry.Font = Enum.Font.Code
	entry.ZIndex = 4
	entry.Visible = true
	entry.Parent = entryFrame

	local copyBtn = Instance.new("TextButton")
	copyBtn.Name = "Copy"
	copyBtn.Size = UDim2.new(0, 45, 1, 0)
	copyBtn.Position = UDim2.new(1, -45, 0, 0)
	copyBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
	copyBtn.TextColor3 = Color3.new(1, 1, 1)
	copyBtn.Text = "Copy"
	copyBtn.BorderSizePixel = 1
	copyBtn.BorderColor3 = Color3.fromRGB(0, 120, 100)
	copyBtn.Font = Enum.Font.Code
	copyBtn.ZIndex = 4
	copyBtn.Visible = true
	copyBtn.Parent = entryFrame

	table.insert(connections, entry.MouseButton1Click:Connect(function()
		selectedId = id
		idBox.Text = id
	end))

	table.insert(connections, copyBtn.MouseButton1Click:Connect(function()
		copyClipboard(id)
	end))

	animFrames[key] = entry

end

local function logAnim(id,name,playerName)

	if banned[id] then return end

	local entryName = name
	local key = id
	if globalLogging and playerName then
		entryName = "["..playerName.."] "..name
		key = id.."_"..playerName
	end

	if not animCounts[key] then
		animCounts[key] = 1
		createEntry(id,entryName,key)
	else
		animCounts[key] += 1
		local entry = animFrames[key]
		if entry then
			entry.Text = "("..animCounts[key]..") "..id.." | "..entryName
		end
	end

end

local function updateColors()
	local animator = getAnimator()
	local playingIds = {}
	if animator then
		for _,track in pairs(animator:GetPlayingAnimationTracks()) do
			playingIds[getId(track.Animation.AnimationId)] = true
		end
	end

	for id, entry in pairs(animFrames) do
		if banned[id] then
			entry.TextColor3 = Color3.fromRGB(255, 50, 50)
		elseif playingIds[id] then
			entry.TextColor3 = Color3.fromRGB(50, 255, 50)
		else
			entry.TextColor3 = Color3.fromRGB(0, 255, 200)
		end
	end
end

task.spawn(function()
	while running do
		updateColors()
		task.wait(0.5)
	end
end)

local function registerTrack(track,playerName)

	local anim = track.Animation
	if not anim then return end

	local id = getId(anim.AnimationId)
	if not id then return end

	if banned[id] then
		track:AdjustWeight(0, 0)
		track:AdjustSpeed(0)
		track:Stop(0)
		return
	end

	if seenTracks[track] then return end
	seenTracks[track] = true

	logAnim(id,anim.Name or "Unknown",playerName)

	local stopConn
	stopConn = track.Stopped:Connect(function()
		seenTracks[track] = nil
		if stopConn then stopConn:Disconnect() end
	end)
	table.insert(connections, stopConn)

end

local function connectAnimator(animator,playerName)
	if animator then
		table.insert(connections, animator.AnimationPlayed:Connect(function(track)
			registerTrack(track,playerName)
		end))
		for _,track in pairs(animator:GetPlayingAnimationTracks()) do
			registerTrack(track,playerName)
		end
	end
end

local function onPlayerAdded(p)
	table.insert(connections, p.CharacterAdded:Connect(function(char)
		task.wait(1)
		connectAnimator(getAnimator(char), p.Name)
	end))
	if p.Character then
		connectAnimator(getAnimator(p.Character), p.Name)
	end
end

table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
for _, p in pairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

local function runLoop()
	for _, p in pairs(Players:GetPlayers()) do
		local isLocal = (p == player)
		local animator = getAnimator(p.Character)
		if animator then
			local scriptAnimActive = false
			if isLocal then
				for t in pairs(scriptTracks) do
					if t.IsPlaying then
						scriptAnimActive = true
						break
					end
				end
			end

			for _, track in pairs(animator:GetPlayingAnimationTracks()) do
				local tid = getId(track.Animation.AnimationId)
				if tid and banned[tid] then
					track:AdjustWeight(0, 0)
					track:AdjustSpeed(0)
					track:Stop(0)
					continue
				end
				if isLocal and scriptAnimActive and not scriptTracks[track] then
					track:AdjustWeight(0, 0)
				elseif globalLogging or isLocal then
					registerTrack(track, p.Name)
				end
			end
		end
	end
end

table.insert(connections, RunService.Stepped:Connect(runLoop))
table.insert(connections, RunService.RenderStepped:Connect(runLoop))
