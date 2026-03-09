--this is the only script ill ever leave unobfuscated, because velocity is a little bitch about obfuscating
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

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

local function getAnimator()
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	return hum:FindFirstChildOfClass("Animator") or hum
end

local function playAnim(id,speed,loop)
	local animator = getAnimator()
	if not animator or not id or id == "" then return end
	
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..id

	local track = animator:LoadAnimation(anim)
	track.Looped = loop or false
	track:Play()

	if speed then
		track:AdjustSpeed(speed)
	end
end

local function stopAnim(id)
	local animator = getAnimator()
	if not animator then return end
	
	for _,track in pairs(animator:GetPlayingAnimationTracks()) do
		local tid = getId(track.Animation.AnimationId)
		if tid == id then
			track:Stop()
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

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0,600,0,420)
mainFrame.Position = UDim2.new(0,50,0,50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(0, 80, 80)
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.ClipsDescendants = false
mainFrame.ZIndex = 1
mainFrame.Parent = gui

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
title.Text = "bacon logger"
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

local list = Instance.new("ScrollingFrame")
list.Name = "AnimList"
list.Position = UDim2.new(0,5,0,30)
list.Size = UDim2.new(0.55,-10,1,-35)
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
		mainFrame.Size = UDim2.new(0,600,0,25)
		list.Visible = false
		controls.Visible = false
		minimize.Text = "+"
	else
		mainFrame.Size = UDim2.new(0,600,0,420)
		list.Visible = true
		controls.Visible = true
		minimize.Text = "-"
	end
end))

closeButton.MouseButton1Click:Connect(function()
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

button("Ban",230,function()

	banned[idBox.Text] = true
	stopAnim(idBox.Text)

end)

button("Unban",265,function()

	banned[idBox.Text] = nil

end)

button("Copy ID",300,function()

	copyClipboard(idBox.Text)

end)

button("Clear List",335,function()

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

local function createEntry(id,name)

	local entryFrame = Instance.new("Frame")
	entryFrame.Name = id
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

	animFrames[id] = entry

end

local function logAnim(id,name)

	if banned[id] then return end

	if not animCounts[id] then
		animCounts[id] = 1
		createEntry(id,name)
	else
		animCounts[id] += 1

		local entryFrame = animFrames[id]
		entryFrame.Text = "("..animCounts[id]..") "..id.." | "..name
	end

end

local function registerTrack(track)

	if seenTracks[track] then return end
	seenTracks[track] = true

	local anim = track.Animation
	if not anim then return end

	local id = getId(anim.AnimationId)
	if not id then return end

	logAnim(id,anim.Name or "Unknown")

	if banned[id] then
		track:Stop()
	end

end

local function connectAnimator()
	local animator = getAnimator()
	if animator then
		table.insert(connections, animator.AnimationPlayed:Connect(registerTrack))
		for _,track in pairs(animator:GetPlayingAnimationTracks()) do
			registerTrack(track)
		end
	end
end

table.insert(connections, player.CharacterAdded:Connect(function()
	wait(1)
	connectAnimator()
end))

connectAnimator()

spawn(function()

	while true do
		local animator = getAnimator()
		if animator then
			for _,track in pairs(animator:GetPlayingAnimationTracks()) do
				registerTrack(track)
			end
		end

		wait(0.25)
	end

end)
