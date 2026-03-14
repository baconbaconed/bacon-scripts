print("enjoy bacon logger, open source if u wanna check github, JOIN THE DISCORD")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local wait = task and task.wait or wait
local spawn = task and task.spawn or spawn
local player = Players.LocalPlayer
while not player do
	task.wait()
	player = Players.LocalPlayer
end
local connections = {}
local animCounts = {}
local animFrames = {}
local banned = {}
local trueBanned = {}
local seenTracks = {}
local scriptTracks = {}
local keybinds = {}
local replacements = {}
local favorites = {}
local customNames = {}
local favoriteEntries = {}
local bindIndicators = {}
local animTimestamps = {}
local looped = false
local globalLogging = false
local isFrozen = false
local autoCopy = false
local filterPlayer = ""
local filterPriority = ""
local configFile = "bacon_logger_config.json"
local keybindFile = "bacon_logger_binds.json"
local function dumpCfg()
	local data = {
		looped = looped,
		globalLogging = globalLogging,
		banned = banned,
		trueBanned = trueBanned,
		replacements = replacements,
		favorites = favorites,
		customNames = customNames,
		autoCopy = autoCopy,
		toggleKey = toggleKey and toggleKey.Name or "RightControl"
	}
	if writefile then
		writefile(configFile, HttpService:JSONEncode(data))
	end
end
local function dumpBinds()
	local data = {}
	for _, bind in pairs(keybinds) do
		table.insert(data, {
			id = bind.id,
			key = bind.key and bind.key.Name or nil,
			hold = bind.hold or false,
			speed = bind.speed or 1,
			loop = bind.loop or false
		})
	end
	if writefile then
		writefile(keybindFile, HttpService:JSONEncode(data))
	end
end
local function grabId(raw)
	if not raw then return nil end
	local s = tostring(raw)
	return s:match("%d+")
end
local function yoink(text)
	local func = setclipboard or toclipboard or (Clipboard and Clipboard.set) or print
	pcall(function() func(text) end)
end
local function grabAnimator(char)
	char = char or player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	return hum:FindFirstChildOfClass("Animator") or hum
end
local function fireAnim(id, speed, loop)
	if banned[id] then return nil end
	local animator = grabAnimator()
	if not animator or not id or id == "" then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. id
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = loop or false
	local playSpeed = speed or 1
	if isFrozen then playSpeed = 0 end
	track:Play(0, 1, playSpeed)
	scriptTracks[track] = true
	table.insert(connections, track.Stopped:Connect(function()
		local intentional = not scriptTracks[track]
		scriptTracks[track] = nil
		if loop and not banned[id] and not intentional then
			local holdBindOwns = false
			for _, bind in pairs(keybinds) do
				if grabId(tostring(bind.id)) == id and bind.hold then
					holdBindOwns = true
					break
				end
			end
			if not holdBindOwns then
				task.defer(function()
					fireAnim(id, speed, loop)
				end)
			end
		end
	end))
	return track
end

local function killAnim(id)
	local animator = grabAnimator()
	if not animator then return end
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		local tid = grabId(track.Animation.AnimationId)
		if tid == id then
			scriptTracks[track] = nil
			track:Stop()
		end
	end
end
local gui = Instance.new("ScreenGui")
gui.Name = "BaconLoggerGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
if success and coreGui then
	gui.Parent = coreGui
else
	gui.Parent = player:WaitForChild("PlayerGui")
end
local toggleKey = Enum.KeyCode.RightControl
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == toggleKey then
		gui.Enabled = not gui.Enabled
	end
end))
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 820, 0, 630)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
mainFrame.BorderSizePixel = 0
mainFrame.BorderColor3 = Color3.fromRGB(0, 80, 80)
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = mainFrame
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 90, 100)
	s.Thickness = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = mainFrame
end

local function mkCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 4)
	c.Parent = parent
end
local function mkStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(0, 80, 90)
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.ClipsDescendants = false
mainFrame.ZIndex = 1
mainFrame.Parent = gui
local dragging, dragInput, dragStart, startPos
local draggingSide, dragInputSide, dragStartSide, startPosSide
local draggingVP, dragInputVP, dragStartVP, startPosVP
local activeDragger = nil

local function dragMain(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
table.insert(connections, mainFrame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeDragger then
		activeDragger = "main"
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		table.insert(connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if activeDragger == "main" then activeDragger = nil end
			end
		end))
	end
end))
table.insert(connections, mainFrame.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		dragInput = input
	end
end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then dragMain(input) end
end))

local resizing = false
local resizeStart, resizeStartSize
local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0, 14, 0, 14)
resizeHandle.Position = UDim2.new(1, -14, 1, -14)
resizeHandle.BackgroundColor3 = Color3.fromRGB(0, 80, 90)
resizeHandle.Text = ""
resizeHandle.BorderSizePixel = 0
resizeHandle.ZIndex = 10
resizeHandle.Parent = mainFrame
mkCorner(resizeHandle, 3)
do
	local grip = Instance.new("TextLabel")
	grip.Text = "⠿"
	grip.Size = UDim2.new(1, 0, 1, 0)
	grip.BackgroundTransparency = 1
	grip.TextColor3 = Color3.fromRGB(0, 200, 160)
	grip.Font = Enum.Font.Code
	grip.TextSize = 11
	grip.ZIndex = 11
	grip.Parent = resizeHandle
end
table.insert(connections, resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		resizeStart = input.Position
		resizeStartSize = mainFrame.AbsoluteSize
	end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
		if not dragging and not draggingSide and not draggingVP then
			activeDragger = nil
		end
	end
end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - resizeStart
		local newW = math.max(600, resizeStartSize.X + delta.X)
		local newH = math.max(400, resizeStartSize.Y + delta.Y)
		mainFrame.Size = UDim2.new(0, newW, 0, newH)
	end
end))

local top = Instance.new("Frame")
top.Name = "TopBar"
top.Size = UDim2.new(1, 0, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(8, 28, 32)
top.BorderSizePixel = 0
top.ZIndex = 2
top.Parent = mainFrame
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 55, 65)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 25, 30)),
	})
	g.Rotation = 90
	g.Parent = top
end
local title = Instance.new("TextLabel")
title.Text = "⬡ bacon's advanced logger"
title.Size = UDim2.new(1, -220, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 220, 170)
title.Font = Enum.Font.Code
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = top
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 26, 0, 20)
closeButton.Position = UDim2.new(1, -28, 0, 4)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.Code
closeButton.TextSize = 12
closeButton.ZIndex = 3
closeButton.Parent = top
mkCorner(closeButton, 4)
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 26, 0, 20)
minimize.Position = UDim2.new(1, -56, 0, 4)
minimize.Text = "-"
minimize.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BorderSizePixel = 0
minimize.Font = Enum.Font.Code
minimize.TextSize = 12
minimize.ZIndex = 3
minimize.Parent = top
mkCorner(minimize, 4)
local openSide = Instance.new("TextButton")
openSide.Size = UDim2.new(0, 52, 0, 20)
openSide.Position = UDim2.new(1, -110, 0, 4)
openSide.Text = "Binds"
openSide.BackgroundColor3 = Color3.fromRGB(0, 75, 85)
openSide.TextColor3 = Color3.fromRGB(0, 220, 170)
openSide.BorderSizePixel = 0
openSide.Font = Enum.Font.Code
openSide.TextSize = 12
openSide.ZIndex = 3
openSide.Parent = top
mkCorner(openSide, 4)
local previewToggle = Instance.new("TextButton")
previewToggle.Size = UDim2.new(0, 60, 0, 20)
previewToggle.Position = UDim2.new(1, -174, 0, 4)
previewToggle.Text = "Preview"
previewToggle.BackgroundColor3 = Color3.fromRGB(0, 55, 80)
previewToggle.TextColor3 = Color3.fromRGB(0, 200, 220)
previewToggle.BorderSizePixel = 0
previewToggle.Font = Enum.Font.Code
previewToggle.TextSize = 12
previewToggle.ZIndex = 3
previewToggle.Parent = top
mkCorner(previewToggle, 4)
local searchBox = Instance.new("TextBox")
searchBox.Text = ""
searchBox.Name = "SearchBox"
searchBox.PlaceholderText = "Search animations..."
searchBox.Position = UDim2.new(0, 6, 0, 32)
searchBox.Size = UDim2.new(0.60, -12, 0, 22)
searchBox.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderColor3 = Color3.fromRGB(0, 100, 90)
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Code
searchBox.TextSize = 12
searchBox.ZIndex = 2
searchBox.Parent = mainFrame
mkCorner(searchBox, 4)
mkStroke(searchBox, Color3.fromRGB(0, 80, 90), 1)
local playerFilterBox = Instance.new("TextBox")
playerFilterBox.Text = ""
playerFilterBox.Name = "PlayerFilter"
playerFilterBox.PlaceholderText = "Filter player..."
playerFilterBox.Position = UDim2.new(0, 5, 0, 55)
playerFilterBox.Size = UDim2.new(0.30, -5, 0, 20)
playerFilterBox.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
playerFilterBox.TextColor3 = Color3.new(1, 1, 1)
playerFilterBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 0)
playerFilterBox.BorderSizePixel = 0
playerFilterBox.Font = Enum.Font.Code
playerFilterBox.TextSize = 12
playerFilterBox.ZIndex = 2
playerFilterBox.Parent = mainFrame
local priorityFilterBox = Instance.new("TextBox")
priorityFilterBox.Text = ""
priorityFilterBox.Name = "PriorityFilter"
priorityFilterBox.PlaceholderText = "Filter priority..."
priorityFilterBox.Position = UDim2.new(0.30, 5, 0, 55)
priorityFilterBox.Size = UDim2.new(0.30, -10, 0, 20)
priorityFilterBox.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
priorityFilterBox.TextColor3 = Color3.new(1, 1, 1)
priorityFilterBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 0)
priorityFilterBox.BorderSizePixel = 0
priorityFilterBox.Font = Enum.Font.Code
priorityFilterBox.TextSize = 12
priorityFilterBox.ZIndex = 2
priorityFilterBox.Parent = mainFrame
mkCorner(playerFilterBox, 4)
mkStroke(playerFilterBox, Color3.fromRGB(80, 80, 0), 1)
mkCorner(priorityFilterBox, 4)
mkStroke(priorityFilterBox, Color3.fromRGB(80, 80, 0), 1)
local logTabBtn = Instance.new("TextButton")
logTabBtn.Text = "[ Log ]"
logTabBtn.Position = UDim2.new(0, 5, 0, 78)
logTabBtn.Size = UDim2.new(0.20, -4, 0, 18)
logTabBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 70)
logTabBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
logTabBtn.Font = Enum.Font.Code
logTabBtn.TextSize = 12
logTabBtn.BorderSizePixel = 0
logTabBtn.ZIndex = 2
logTabBtn.Parent = mainFrame
mkCorner(logTabBtn, 4)
local favsTabBtn = Instance.new("TextButton")
favsTabBtn.Text = "[ Favs ]"
favsTabBtn.Position = UDim2.new(0.20, 2, 0, 78)
favsTabBtn.Size = UDim2.new(0.20, -4, 0, 18)
favsTabBtn.BackgroundColor3 = Color3.fromRGB(40, 38, 0)
favsTabBtn.TextColor3 = Color3.fromRGB(220, 210, 0)
favsTabBtn.Font = Enum.Font.Code
favsTabBtn.TextSize = 12
favsTabBtn.BorderSizePixel = 0
favsTabBtn.ZIndex = 2
favsTabBtn.Parent = mainFrame
mkCorner(favsTabBtn, 4)
local bannedTabBtn = Instance.new("TextButton")
bannedTabBtn.Text = "[ Banned ]"
bannedTabBtn.Position = UDim2.new(0.40, 2, 0, 78)
bannedTabBtn.Size = UDim2.new(0.20, -6, 0, 18)
bannedTabBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
bannedTabBtn.TextColor3 = Color3.fromRGB(255, 120, 100)
bannedTabBtn.Font = Enum.Font.Code
bannedTabBtn.TextSize = 12
bannedTabBtn.BorderSizePixel = 0
bannedTabBtn.ZIndex = 2
bannedTabBtn.Parent = mainFrame
mkCorner(bannedTabBtn, 4)

local logCountLabel = Instance.new("TextLabel")
logCountLabel.Text = "0 logged"
logCountLabel.Position = UDim2.new(0.60, -92, 0, 32)
logCountLabel.Size = UDim2.new(0, 88, 0, 22)
logCountLabel.BackgroundTransparency = 1
logCountLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
logCountLabel.TextXAlignment = Enum.TextXAlignment.Right
logCountLabel.Font = Enum.Font.Code
logCountLabel.TextSize = 11
logCountLabel.ZIndex = 2
logCountLabel.Parent = mainFrame
local list = Instance.new("ScrollingFrame")
list.Name = "AnimList"
list.Position = UDim2.new(0, 5, 0, 100)
list.Size = UDim2.new(0.60, -10, 1, -105)
list.BackgroundColor3 = Color3.fromRGB(14, 17, 22)
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 150)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ClipsDescendants = true
list.ZIndex = 2
list.Visible = true
list.Parent = mainFrame
mkCorner(list, 4)
mkStroke(list, Color3.fromRGB(0, 65, 75), 1)
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 1)
layout.Parent = list
table.insert(connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end))
local favsList = Instance.new("ScrollingFrame")
favsList.Name = "FavsList"
favsList.Position = UDim2.new(0, 5, 0, 100)
favsList.Size = UDim2.new(0.60, -10, 1, -105)
favsList.BackgroundColor3 = Color3.fromRGB(16, 15, 10)
favsList.BorderSizePixel = 0
favsList.ScrollBarThickness = 4
favsList.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 0)
favsList.CanvasSize = UDim2.new(0, 0, 0, 0)
favsList.ClipsDescendants = true
favsList.ZIndex = 2
favsList.Visible = false
favsList.Parent = mainFrame
mkCorner(favsList, 4)
mkStroke(favsList, Color3.fromRGB(80, 75, 0), 1)
local favsLayout = Instance.new("UIListLayout")
favsLayout.Padding = UDim.new(0, 2)
favsLayout.Parent = favsList
table.insert(connections, favsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	favsList.CanvasSize = UDim2.new(0, 0, 0, favsLayout.AbsoluteContentSize.Y)
end))
local bannedList = Instance.new("ScrollingFrame")
bannedList.Name = "BannedList"
bannedList.Position = UDim2.new(0, 5, 0, 100)
bannedList.Size = UDim2.new(0.60, -10, 1, -105)
bannedList.BackgroundColor3 = Color3.fromRGB(18, 10, 10)
bannedList.BorderSizePixel = 0
bannedList.ScrollBarThickness = 4
bannedList.ScrollBarImageColor3 = Color3.fromRGB(200, 80, 80)
bannedList.CanvasSize = UDim2.new(0, 0, 0, 0)
bannedList.ClipsDescendants = true
bannedList.ZIndex = 2
bannedList.Visible = false
bannedList.Parent = mainFrame
mkCorner(bannedList, 4)
mkStroke(bannedList, Color3.fromRGB(100, 30, 30), 1)
local bannedLayout = Instance.new("UIListLayout")
bannedLayout.Padding = UDim.new(0, 2)
bannedLayout.Parent = bannedList
table.insert(connections, bannedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	bannedList.CanvasSize = UDim2.new(0, 0, 0, bannedLayout.AbsoluteContentSize.Y)
end))
local idBox
local function rebuildBannedList()
	for _, child in ipairs(bannedList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for id, isBanned in pairs(banned) do
		if isBanned then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -5, 0, 22)
			row.BackgroundTransparency = 1
			row.ZIndex = 3
			row.Parent = bannedList
			local label = Instance.new("TextButton")
			label.Size = UDim2.new(1, -80, 1, 0)
			label.BackgroundColor3 = Color3.fromRGB(30, 12, 12)
			label.TextColor3 = Color3.fromRGB(255, 100, 80)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = (trueBanned[id] and "⬛ " or "") .. id
			label.Font = Enum.Font.Code
			label.TextSize = 11
			label.BorderSizePixel = 0
			label.ZIndex = 4
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = row
			mkCorner(label, 3)
			local copyBtn = Instance.new("TextButton")
			copyBtn.Size = UDim2.new(0, 46, 1, 0)
			copyBtn.Position = UDim2.new(1, -80, 0, 0)
			copyBtn.BackgroundColor3 = Color3.fromRGB(0, 45, 55)
			copyBtn.TextColor3 = Color3.new(1, 1, 1)
			copyBtn.Text = "Copy"
			copyBtn.Font = Enum.Font.Code
			copyBtn.TextSize = 10
			copyBtn.BorderSizePixel = 0
			copyBtn.ZIndex = 4
			copyBtn.Parent = row
			mkCorner(copyBtn, 3)
			local unbanBtn = Instance.new("TextButton")
			unbanBtn.Size = UDim2.new(0, 46, 1, 0)
			unbanBtn.Position = UDim2.new(1, -30, 0, 0)
			unbanBtn.BackgroundColor3 = Color3.fromRGB(55, 30, 0)
			unbanBtn.TextColor3 = Color3.fromRGB(255, 180, 80)
			unbanBtn.Text = "Unban"
			unbanBtn.Font = Enum.Font.Code
			unbanBtn.TextSize = 9
			unbanBtn.BorderSizePixel = 0
			unbanBtn.ZIndex = 4
			unbanBtn.Parent = row
			mkCorner(unbanBtn, 3)
			table.insert(connections, label.MouseButton1Click:Connect(function()
				idBox.Text = id
			end))
			table.insert(connections, copyBtn.MouseButton1Click:Connect(function()
				yoink(id)
			end))
			table.insert(connections, unbanBtn.MouseButton1Click:Connect(function()
				banned[id] = nil
				trueBanned[id] = nil
				dumpCfg()
				row:Destroy()
			end))
		end
	end
end
local currentTab = "log"
local function switchTab(tab)
	currentTab = tab
	list.Visible = (tab == "log")
	favsList.Visible = (tab == "favs")
	bannedList.Visible = (tab == "banned")
	if tab == "banned" then rebuildBannedList() end
	logTabBtn.BackgroundColor3 = (tab == "log") and Color3.fromRGB(0, 80, 90) or Color3.fromRGB(0, 35, 40)
	favsTabBtn.BackgroundColor3 = (tab == "favs") and Color3.fromRGB(80, 76, 0) or Color3.fromRGB(35, 33, 0)
	bannedTabBtn.BackgroundColor3 = (tab == "banned") and Color3.fromRGB(100, 20, 20) or Color3.fromRGB(50, 10, 10)
end
table.insert(connections, logTabBtn.MouseButton1Click:Connect(function() switchTab("log") end))
table.insert(connections, favsTabBtn.MouseButton1Click:Connect(function() switchTab("favs") end))
table.insert(connections, bannedTabBtn.MouseButton1Click:Connect(function() switchTab("banned") end))
local controls = Instance.new("ScrollingFrame")
controls.Name = "Controls"
controls.Position = UDim2.new(0.60, 5, 0, 30)
controls.Size = UDim2.new(0.40, -10, 1, -35)
controls.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
controls.BorderSizePixel = 0
controls.ClipsDescendants = true
controls.ScrollBarThickness = 3
controls.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 130)
controls.CanvasSize = UDim2.new(0, 0, 0, 750)
controls.ZIndex = 2
controls.Visible = true
controls.Parent = mainFrame
mkCorner(controls, 5)
mkStroke(controls, Color3.fromRGB(0, 65, 75), 1)
local function mkLabel(text, y)
	local l = Instance.new("TextLabel")
	l.Text = text
	l.Position = UDim2.new(0, 10, 0, y)
	l.Size = UDim2.new(1, -20, 0, 20)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(0, 200, 150)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.Code
	l.ZIndex = 3
	l.Visible = true
	l.Parent = controls
end
mkLabel("Animation ID", 10)
idBox = Instance.new("TextBox")
idBox.Text = ""
idBox.Position = UDim2.new(0, 10, 0, 30)
idBox.Size = UDim2.new(1, -20, 0, 25)
idBox.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
idBox.TextColor3 = Color3.new(1, 1, 1)
idBox.PlaceholderColor3 = Color3.fromRGB(0, 100, 80)
idBox.PlaceholderText = "animation id..."
idBox.BorderSizePixel = 0
idBox.ZIndex = 3
idBox.Visible = true
idBox.Parent = controls
mkCorner(idBox, 4)
mkStroke(idBox, Color3.fromRGB(0, 90, 100), 1)
mkLabel("Speed", 65)
local speedBox = Instance.new("TextBox")
speedBox.Text = "1"
speedBox.PlaceholderText = "speed (1 = normal)"
speedBox.Position = UDim2.new(0, 10, 0, 85)
speedBox.Size = UDim2.new(1, -20, 0, 25)
speedBox.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.BorderSizePixel = 0
speedBox.ZIndex = 3
speedBox.Visible = true
speedBox.Parent = controls
mkCorner(speedBox, 4)
mkStroke(speedBox, Color3.fromRGB(0, 90, 100), 1)
mkLabel("Time (Scrub)", 120)
local timeBox = Instance.new("TextBox")
timeBox.Text = "0"
timeBox.PlaceholderText = "scrub time (secs)"
timeBox.Position = UDim2.new(0, 10, 0, 140)
timeBox.Size = UDim2.new(1, -20, 0, 25)
timeBox.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
timeBox.TextColor3 = Color3.new(1, 1, 1)
timeBox.BorderSizePixel = 0
timeBox.ZIndex = 3
timeBox.Visible = true
timeBox.Parent = controls
mkCorner(timeBox, 4)
mkStroke(timeBox, Color3.fromRGB(0, 90, 100), 1)
table.insert(connections, timeBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(timeBox.Text:match("[%d%.]+"))
	if num then
		for track in pairs(scriptTracks) do
			if track.IsPlaying then
				track.TimePosition = math.clamp(num, 0, track.Length)
			end
		end
	end
end))

local mainTimerLabel = Instance.new("TextLabel")
mainTimerLabel.Text = "no anim playing"
mainTimerLabel.Position = UDim2.new(0, 10, 0, 168)
mainTimerLabel.Size = UDim2.new(1, -20, 0, 14)
mainTimerLabel.BackgroundTransparency = 1
mainTimerLabel.TextColor3 = Color3.fromRGB(0, 160, 120)
mainTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
mainTimerLabel.Font = Enum.Font.Code
mainTimerLabel.TextSize = 11
mainTimerLabel.ZIndex = 3
mainTimerLabel.Visible = true
mainTimerLabel.Parent = controls

local mainScrubBg = Instance.new("Frame")
mainScrubBg.Position = UDim2.new(0, 10, 0, 185)
mainScrubBg.Size = UDim2.new(1, -20, 0, 12)
mainScrubBg.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
mainScrubBg.BorderSizePixel = 0
mainScrubBg.ZIndex = 3
mainScrubBg.Parent = controls
mkCorner(mainScrubBg, 6)

local mainScrubFill = Instance.new("Frame")
mainScrubFill.Size = UDim2.new(0, 0, 1, 0)
mainScrubFill.BackgroundColor3 = Color3.fromRGB(0, 210, 160)
mainScrubFill.BorderSizePixel = 0
mainScrubFill.ZIndex = 4
mainScrubFill.Parent = mainScrubBg

local mainScrubBtn = Instance.new("TextButton")
mainScrubBtn.Size = UDim2.new(1, 0, 1, 0)
mainScrubBtn.BackgroundTransparency = 1
mainScrubBtn.Text = ""
mainScrubBtn.ZIndex = 5
mainScrubBtn.Parent = mainScrubBg

local mainPaused = false
local mainPauseBtn = Instance.new("TextButton")
mainPauseBtn.Text = "⏸ Pause"
mainPauseBtn.Position = UDim2.new(0, 10, 0, 196)
mainPauseBtn.Size = UDim2.new(1, -20, 0, 20)
mainPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 55, 70)
mainPauseBtn.TextColor3 = Color3.new(1, 1, 1)
mainPauseBtn.BorderSizePixel = 0
mainPauseBtn.Font = Enum.Font.Code
mainPauseBtn.TextSize = 11
mainPauseBtn.ZIndex = 3
mainPauseBtn.Parent = controls
mkCorner(mainPauseBtn, 4)
mkStroke(mainPauseBtn, Color3.fromRGB(0, 110, 130), 1)

table.insert(connections, mainPauseBtn.MouseButton1Click:Connect(function()
	mainPaused = not mainPaused
	for track in pairs(scriptTracks) do
		if mainPaused then
			track:AdjustSpeed(0)
		else
			track:AdjustSpeed(tonumber(speedBox.Text) or 1)
		end
	end
	mainPauseBtn.Text = mainPaused and "▶ Resume" or "⏸ Pause"
	mainPauseBtn.BackgroundColor3 = mainPaused and Color3.fromRGB(0, 80, 0) or Color3.fromRGB(0, 50, 60)
end))

local mainScrubbing = false
table.insert(connections, mainScrubBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mainScrubbing = true
	end
end))
table.insert(connections, mainScrubBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mainScrubbing = false
	end
end))

local loopToggle = Instance.new("TextButton")
loopToggle.Text = "Loop: OFF"
loopToggle.Position = UDim2.new(0, 10, 0, 220)
loopToggle.Size = UDim2.new(1, -20, 0, 25)
loopToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
loopToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
loopToggle.BorderSizePixel = 0
loopToggle.ZIndex = 3
loopToggle.Visible = true
loopToggle.Parent = controls
mkCorner(loopToggle, 4)
mkStroke(loopToggle, Color3.fromRGB(120, 0, 0), 1)
local function refreshLoopBtn()
	loopToggle.Text = "Loop: " .. (looped and "ON" or "OFF")
	loopToggle.BackgroundColor3 = looped and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
	loopToggle.TextColor3 = looped and Color3.fromRGB(160, 255, 180) or Color3.fromRGB(255, 180, 160)
end
table.insert(connections, loopToggle.MouseButton1Click:Connect(function()
	looped = not looped
	refreshLoopBtn()
	dumpCfg()
end))
local function button(text, y, callback, bgColor, borderColor)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Position = UDim2.new(0, 10, 0, y)
	b.Size = UDim2.new(1, -20, 0, 26)
	b.BackgroundColor3 = bgColor or Color3.fromRGB(0, 60, 70)
	b.TextColor3 = Color3.fromRGB(200, 240, 230)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.Code
	b.TextSize = 12
	b.ZIndex = 3
	b.Visible = true
	b.Parent = controls
	mkCorner(b, 4)
	mkStroke(b, borderColor or Color3.fromRGB(0, 110, 120), 1)
	table.insert(connections, b.MouseButton1Click:Connect(callback))
end
button("Play", 255, function()
	local id = idBox.Text
	local speed = tonumber(speedBox.Text) or 1
	local scrub = tonumber(timeBox.Text) or 0
	local track = fireAnim(id, speed, looped)
	if track and scrub > 0 then
		task.defer(function()
			if track then
				track.TimePosition = math.clamp(scrub, 0, track.Length)
			end
		end)
	end
end)
button("Stop", 290, function()
	killAnim(idBox.Text)
end, Color3.fromRGB(80, 20, 20), Color3.fromRGB(160, 40, 40))
button("Stop All", 325, function()
	local animator = grabAnimator()
	if animator then
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			scriptTracks[track] = nil
			track:Stop()
		end
	end
	scriptTracks = {}
end, Color3.fromRGB(80, 20, 20), Color3.fromRGB(160, 40, 40))
button("Ban", 360, function()
	banned[idBox.Text] = true
	killAnim(idBox.Text)
	dumpCfg()
end, Color3.fromRGB(80, 20, 20), Color3.fromRGB(160, 40, 40))
button("True Ban", 395, function()
	local id = idBox.Text
	if id == "" then return end
	trueBanned[id] = true
	banned[id] = true
	killAnim(id)
	dumpCfg()
	refreshColors()
end, Color3.fromRGB(100, 0, 0), Color3.fromRGB(200, 0, 0))
button("Unban", 430, function()
	local id = idBox.Text
	banned[id] = nil
	trueBanned[id] = nil
	dumpCfg()
	refreshColors()
end, Color3.fromRGB(70, 45, 0), Color3.fromRGB(140, 90, 0))
button("Copy ID", 465, function()
	yoink(idBox.Text)
end, Color3.fromRGB(0, 40, 80), Color3.fromRGB(0, 80, 160))
local function nukeList()
	for id, entry in pairs(animFrames) do
		if entry.Parent and entry.Parent:IsA("Frame") then
			entry.Parent:Destroy()
		else
			entry:Destroy()
		end
	end
	animCounts = {}
	animFrames = {}
	seenTracks = {}
	logCountLabel.Text = "0 logged"
end
button("Clear List", 500, nukeList)
local globalToggle = Instance.new("TextButton")
globalToggle.Text = "Global Log: OFF"
globalToggle.Position = UDim2.new(0, 10, 0, 527)
globalToggle.Size = UDim2.new(1, -20, 0, 25)
globalToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
globalToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
globalToggle.BorderSizePixel = 0
globalToggle.ZIndex = 3
globalToggle.Visible = true
globalToggle.Parent = controls
mkCorner(globalToggle, 4)
mkStroke(globalToggle, Color3.fromRGB(110, 0, 0), 1)
local function refreshGlobalBtn()
	globalToggle.Text = "Global Log: " .. (globalLogging and "ON" or "OFF")
	globalToggle.BackgroundColor3 = globalLogging and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
end
table.insert(connections, globalToggle.MouseButton1Click:Connect(function()
	globalLogging = not globalLogging
	refreshGlobalBtn()
	dumpCfg()
end))
local autoCopyToggle = Instance.new("TextButton")
autoCopyToggle.Text = "Auto-Copy: OFF"
autoCopyToggle.Position = UDim2.new(0, 10, 0, 555)
autoCopyToggle.Size = UDim2.new(1, -20, 0, 22)
autoCopyToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
autoCopyToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
autoCopyToggle.BorderSizePixel = 0
autoCopyToggle.ZIndex = 3
autoCopyToggle.Visible = true
autoCopyToggle.Parent = controls
mkCorner(autoCopyToggle, 4)
mkStroke(autoCopyToggle, Color3.fromRGB(110, 0, 0), 1)
local function refreshAutoCopyBtn()
	autoCopyToggle.Text = "Auto-Copy: " .. (autoCopy and "ON" or "OFF")
	autoCopyToggle.BackgroundColor3 = autoCopy and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
end
table.insert(connections, autoCopyToggle.MouseButton1Click:Connect(function()
	autoCopy = not autoCopy
	refreshAutoCopyBtn()
	dumpCfg()
end))
local exportBtn = Instance.new("TextButton")
exportBtn.Text = "Export Log"
exportBtn.Position = UDim2.new(0, 10, 0, 581)
exportBtn.Size = UDim2.new(1, -20, 0, 22)
exportBtn.BackgroundColor3 = Color3.fromRGB(0, 38, 75)
exportBtn.TextColor3 = Color3.fromRGB(160, 200, 255)
exportBtn.BorderSizePixel = 0
exportBtn.ZIndex = 3
exportBtn.Visible = true
exportBtn.Parent = controls
mkCorner(exportBtn, 4)
mkStroke(exportBtn, Color3.fromRGB(0, 75, 150), 1)

local toggleKeyBtn = Instance.new("TextButton")
toggleKeyBtn.Text = "Hide Key: " .. toggleKey.Name
toggleKeyBtn.Position = UDim2.new(0, 10, 0, 616)
toggleKeyBtn.Size = UDim2.new(1, -20, 0, 26)
toggleKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
toggleKeyBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
toggleKeyBtn.BorderSizePixel = 0
toggleKeyBtn.Font = Enum.Font.Code
toggleKeyBtn.TextSize = 12
toggleKeyBtn.ZIndex = 3
toggleKeyBtn.Visible = true
toggleKeyBtn.Parent = controls
mkCorner(toggleKeyBtn, 4)
mkStroke(toggleKeyBtn, Color3.fromRGB(90, 60, 180), 1)
local settingToggleKey = false
table.insert(connections, toggleKeyBtn.MouseButton1Click:Connect(function()
	if settingToggleKey then return end
	settingToggleKey = true
	toggleKeyBtn.Text = "Press any key..."
	toggleKeyBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
	local conn
	conn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			conn:Disconnect()
			settingToggleKey = false
			toggleKey = input.KeyCode
			toggleKeyBtn.Text = "Hide Key: " .. toggleKey.Name
			toggleKeyBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
			dumpCfg()
		end
	end)
end))
table.insert(connections, exportBtn.MouseButton1Click:Connect(function()
	local out = {}
	for key, entry in pairs(animFrames) do
		local pureId = key:match("^([%d]+)")
		table.insert(out, {
			id = pureId,
			key = key,
			name = entry.Text,
			count = animCounts[key] or 1,
			lastSeen = animTimestamps[key] or "?",
			favorited = favorites[pureId] or false,
			customName = customNames[pureId] or nil,
		})
	end
	local lines = {"["}
	for i, entry in ipairs(out) do
		local comma = i < #out and "," or ""
		table.insert(lines, "  {")
		table.insert(lines, '    "id": "' .. (entry.id or "") .. '",')
		table.insert(lines, '    "key": "' .. (entry.key or "") .. '",')
		table.insert(lines, '    "name": "' .. tostring(entry.name or ""):gsub('"', '\\"') .. '",')
		table.insert(lines, '    "count": ' .. tostring(entry.count) .. ',')
		table.insert(lines, '    "lastSeen": "' .. tostring(entry.lastSeen) .. '",')
		table.insert(lines, '    "favorited": ' .. tostring(entry.favorited) .. ',')
		table.insert(lines, '    "customName": ' .. (entry.customName and ('"' .. tostring(entry.customName):gsub('"', '\\"') .. '"') or "null"))
		table.insert(lines, "  }" .. comma)
	end
	table.insert(lines, "]")
	local json = table.concat(lines, "\n")
	if writefile then
		writefile("bacon_logger_export.json", json)
		exportBtn.Text = "Exported!"
		exportBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
		task.delay(2, function()
			exportBtn.Text = "Export Log"
			exportBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
		end)
	else
		yoink(json)
		exportBtn.Text = "Copied!"
		exportBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
		task.delay(2, function()
			exportBtn.Text = "Export Log"
			exportBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
		end)
	end
end))
local discordBtn = Instance.new("TextButton")
discordBtn.Text = "discord"
discordBtn.Size = UDim2.new(0, 70, 0, 18)
discordBtn.Position = UDim2.new(0, 6, 1, -22)
discordBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 80)
discordBtn.TextColor3 = Color3.fromRGB(140, 160, 255)
discordBtn.BorderSizePixel = 0
discordBtn.Font = Enum.Font.Code
discordBtn.TextSize = 10
discordBtn.ZIndex = 3
discordBtn.Parent = mainFrame
mkCorner(discordBtn, 4)
mkStroke(discordBtn, Color3.fromRGB(60, 80, 200), 1)
table.insert(connections, discordBtn.MouseButton1Click:Connect(function()
	yoink("discord.gg/u8FTncR4dF")
	discordBtn.Text = "copied!"
	discordBtn.TextColor3 = Color3.fromRGB(160, 255, 180)
	task.delay(2, function()
		discordBtn.Text = "discord"
		discordBtn.TextColor3 = Color3.fromRGB(140, 160, 255)
	end)
end))

local minimized = false
table.insert(connections, minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		mainFrame.Size = UDim2.new(0, 460, 0, 28)
		list.Visible = false
		favsList.Visible = false
		bannedList.Visible = false
		controls.Visible = false
		searchBox.Visible = false
		playerFilterBox.Visible = false
		priorityFilterBox.Visible = false
		logTabBtn.Visible = false
		favsTabBtn.Visible = false
		bannedTabBtn.Visible = false
		logCountLabel.Visible = false
		resizeHandle.Visible = false
		discordBtn.Visible = false
		minimize.Text = "+"
	else
		mainFrame.Size = UDim2.new(0, 820, 0, 630)
		list.Visible = (currentTab == "log")
		favsList.Visible = (currentTab == "favs")
		bannedList.Visible = (currentTab == "banned")
		controls.Visible = true
		searchBox.Visible = true
		playerFilterBox.Visible = true
		priorityFilterBox.Visible = true
		logTabBtn.Visible = true
		favsTabBtn.Visible = true
		bannedTabBtn.Visible = true
		logCountLabel.Visible = true
		resizeHandle.Visible = true
		discordBtn.Visible = true
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
local function doFilter()
	local query = searchBox.Text:lower()
	local pf = playerFilterBox.Text:lower()
	local priF = priorityFilterBox.Text:lower()
	for id, entry in pairs(animFrames) do
		local text = entry.Text:lower()
		local matchSearch = (query == "" or id:lower():find(query, 1, true) or text:find(query, 1, true))
		local matchPlayer = (pf == "" or text:find(pf, 1, true))
		local matchPri = (priF == "" or text:find(priF, 1, true))
		local container = entry.Parent
		if container and container:IsA("Frame") then
			container.Visible = matchSearch and matchPlayer and matchPri
		end
	end
end
table.insert(connections, searchBox:GetPropertyChangedSignal("Text"):Connect(doFilter))
table.insert(connections, playerFilterBox:GetPropertyChangedSignal("Text"):Connect(doFilter))
table.insert(connections, priorityFilterBox:GetPropertyChangedSignal("Text"):Connect(doFilter))
local sideFrame = Instance.new("Frame")
sideFrame.Name = "SideFrame"
sideFrame.Size = UDim2.new(0, 200, 0, 480)
sideFrame.Position = UDim2.new(0, 655, 0, 50)
sideFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
sideFrame.BorderSizePixel = 0
sideFrame.Active = true
sideFrame.ClipsDescendants = true
sideFrame.ZIndex = 1
sideFrame.Visible = false
sideFrame.Parent = gui
mkCorner(sideFrame, 6)
mkStroke(sideFrame, Color3.fromRGB(0, 90, 100), 1)
local function dragSide(input)
	local delta = input.Position - dragStartSide
	sideFrame.Position = UDim2.new(startPosSide.X.Scale, startPosSide.X.Offset + delta.X, startPosSide.Y.Scale, startPosSide.Y.Offset + delta.Y)
end
table.insert(connections, sideFrame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeDragger then
		activeDragger = "side"
		draggingSide = true
		dragStartSide = input.Position
		startPosSide = sideFrame.Position
		table.insert(connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingSide = false
				if activeDragger == "side" then activeDragger = nil end
			end
		end))
	end
end))
table.insert(connections, sideFrame.InputChanged:Connect(function(input)
	if draggingSide and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		dragInputSide = input
	end
end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInputSide and draggingSide then dragSide(input) end
end))
table.insert(connections, openSide.MouseButton1Click:Connect(function()
	sideFrame.Visible = not sideFrame.Visible
end))
local sideTitle = Instance.new("TextLabel")
sideTitle.Size = UDim2.new(1, 0, 0, 28)
sideTitle.BackgroundColor3 = Color3.fromRGB(8, 28, 32)
sideTitle.Text = "  keybinds"
sideTitle.TextColor3 = Color3.fromRGB(0, 220, 170)
sideTitle.Font = Enum.Font.Code
sideTitle.TextSize = 13
sideTitle.TextXAlignment = Enum.TextXAlignment.Left
sideTitle.ZIndex = 2
sideTitle.Parent = sideFrame
do local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 55, 65)), ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 25, 30))}); g.Rotation = 90; g.Parent = sideTitle end
local sideList = Instance.new("ScrollingFrame")
sideList.Position = UDim2.new(0, 5, 0, 33)
sideList.Size = UDim2.new(1, -10, 1, -68)
sideList.BackgroundColor3 = Color3.fromRGB(14, 17, 22)
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
addB.Size = UDim2.new(0.5, -10, 0, 25)
addB.Position = UDim2.new(0, 5, 1, -30)
addB.Text = "Add Bind"
addB.BackgroundColor3 = Color3.fromRGB(0, 60, 70)
addB.TextColor3 = Color3.fromRGB(0, 220, 170)
addB.ZIndex = 3
addB.Parent = sideFrame
mkCorner(addB, 4)
mkStroke(addB, Color3.fromRGB(0, 110, 120), 1)
local addR = Instance.new("TextButton")
addR.Size = UDim2.new(0.5, -10, 0, 25)
addR.Position = UDim2.new(0.5, 5, 1, -30)
addR.Text = "Add Repl"
addR.BackgroundColor3 = Color3.fromRGB(60, 57, 0)
addR.TextColor3 = Color3.fromRGB(220, 210, 0)
addR.ZIndex = 3
addR.Parent = sideFrame
mkCorner(addR, 4)
mkStroke(addR, Color3.fromRGB(120, 110, 0), 1)
local sideClose = Instance.new("TextButton")
sideClose.Size = UDim2.new(0, 22, 0, 20)
sideClose.Position = UDim2.new(1, -24, 0, 4)
sideClose.Text = "X"
sideClose.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
sideClose.TextColor3 = Color3.new(1, 1, 1)
sideClose.Font = Enum.Font.Code
sideClose.TextSize = 11
sideClose.ZIndex = 3
sideClose.Parent = sideFrame
mkCorner(sideClose, 4)
local sideMinimize = Instance.new("TextButton")
sideMinimize.Size = UDim2.new(0, 22, 0, 20)
sideMinimize.Position = UDim2.new(1, -48, 0, 4)
sideMinimize.Text = "-"
sideMinimize.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
sideMinimize.TextColor3 = Color3.new(1, 1, 1)
sideMinimize.Font = Enum.Font.Code
sideMinimize.TextSize = 11
sideMinimize.ZIndex = 3
sideMinimize.Parent = sideFrame
mkCorner(sideMinimize, 4)
local cmdsBtn = Instance.new("TextButton")
cmdsBtn.Size = UDim2.new(0, 44, 0, 20)
cmdsBtn.Position = UDim2.new(1, -94, 0, 4)
cmdsBtn.Text = "cmds"
cmdsBtn.BackgroundColor3 = Color3.fromRGB(0, 65, 75)
cmdsBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
cmdsBtn.Font = Enum.Font.Code
cmdsBtn.TextSize = 11
cmdsBtn.ZIndex = 3
cmdsBtn.Parent = sideFrame
mkCorner(cmdsBtn, 4)
mkStroke(cmdsBtn, Color3.fromRGB(0, 90, 100), 1)
local cmdsTooltip = Instance.new("Frame")
cmdsTooltip.Size = UDim2.new(0, 250, 0, 295)
cmdsTooltip.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
cmdsTooltip.BorderSizePixel = 0
cmdsTooltip.ClipsDescendants = true
cmdsTooltip.ZIndex = 30
cmdsTooltip.Visible = false
cmdsTooltip.Parent = gui
mkCorner(cmdsTooltip, 4)
mkStroke(cmdsTooltip, Color3.fromRGB(0, 180, 150), 1)
table.insert(connections, cmdsBtn.MouseEnter:Connect(function()
	local abs = cmdsBtn.AbsolutePosition
	cmdsTooltip.Position = UDim2.new(0, abs.X - 255, 0, abs.Y)
	cmdsTooltip.Visible = true
end))
table.insert(connections, cmdsBtn.MouseLeave:Connect(function()
	cmdsTooltip.Visible = false
end))
local tooltipLabel = Instance.new("TextLabel")
tooltipLabel.Size = UDim2.new(1, -10, 1, -10)
tooltipLabel.Position = UDim2.new(0, 5, 0, 5)
tooltipLabel.BackgroundTransparency = 1
tooltipLabel.TextColor3 = Color3.fromRGB(0, 220, 170)
tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
tooltipLabel.TextYAlignment = Enum.TextYAlignment.Top
tooltipLabel.TextWrapped = true
tooltipLabel.Font = Enum.Font.Code
tooltipLabel.TextSize = 11
tooltipLabel.ZIndex = 31
tooltipLabel.Text = [[COMMANDS (ID box):
pause/freeze, speed [n], ban [id]
unban [id], stop [id], step [n]
loop, clear
MACRO FORMAT (use ; to chain):
play [id] [speed] [loop?]
wait [seconds]
stop [id] (or stop for all)
speed [n]
EXAMPLE:
play 111; wait 0.5; play 222 2 true; wait 1; stop 111
Tip: Use Hold: ON for temp freeze.
Speed/loop in viewport are separate
from your main playback settings.]]
tooltipLabel.Parent = cmdsTooltip
local sideMinimized = false
table.insert(connections, sideMinimize.MouseButton1Click:Connect(function()
	sideMinimized = not sideMinimized
	if sideMinimized then
		sideFrame.Size = UDim2.new(0, 200, 0, 28)
		sideList.Visible = false
		addB.Visible = false
		addR.Visible = false
		cmdsBtn.Visible = false
		sideMinimize.Text = "+"
	else
		sideFrame.Size = UDim2.new(0, 200, 0, 480)
		sideList.Visible = true
		addB.Visible = true
		addR.Visible = true
		cmdsBtn.Visible = true
		sideMinimize.Text = "-"
	end
end))
table.insert(connections, sideClose.MouseButton1Click:Connect(function()
	sideFrame.Visible = false
end))
local viewportWin = Instance.new("Frame")
viewportWin.Name = "ViewportWindow"
viewportWin.Size = UDim2.new(0, 300, 0, 488)
viewportWin.Position = UDim2.new(0, 670, 0, 380)
viewportWin.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
viewportWin.BorderSizePixel = 0
viewportWin.Active = true
viewportWin.ClipsDescendants = true
viewportWin.ZIndex = 5
viewportWin.Visible = false
viewportWin.Parent = gui
mkCorner(viewportWin, 6)
mkStroke(viewportWin, Color3.fromRGB(0, 90, 100), 1)
local function dragVP(input)
	local delta = input.Position - dragStartVP
	viewportWin.Position = UDim2.new(startPosVP.X.Scale, startPosVP.X.Offset + delta.X, startPosVP.Y.Scale, startPosVP.Y.Offset + delta.Y)
end
table.insert(connections, viewportWin.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeDragger then
		activeDragger = "vp"
		draggingVP = true
		dragStartVP = input.Position
		startPosVP = viewportWin.Position
		table.insert(connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingVP = false
				if activeDragger == "vp" then activeDragger = nil end
			end
		end))
	end
end))
table.insert(connections, viewportWin.InputChanged:Connect(function(input)
	if draggingVP and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		dragInputVP = input
	end
end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInputVP and draggingVP then dragVP(input) end
end))
local vpTop = Instance.new("Frame")
vpTop.Size = UDim2.new(1, 0, 0, 25)
vpTop.BackgroundColor3 = Color3.fromRGB(8, 28, 32)
vpTop.BorderSizePixel = 0
vpTop.ZIndex = 6
vpTop.Parent = viewportWin
do local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 55, 65)), ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 25, 30))}); g.Rotation = 90; g.Parent = vpTop end
local vpTitle = Instance.new("TextLabel")
vpTitle.Text = "preview"
vpTitle.Size = UDim2.new(1, -120, 1, 0)
vpTitle.BackgroundTransparency = 1
vpTitle.TextColor3 = Color3.fromRGB(0, 220, 170)
vpTitle.Font = Enum.Font.Code
vpTitle.TextSize = 13
vpTitle.ZIndex = 7
vpTitle.Parent = vpTop
local vpClose = Instance.new("TextButton")
vpClose.Size = UDim2.new(0, 25, 0, 20)
vpClose.Position = UDim2.new(1, -27, 0, 3)
vpClose.Text = "X"
vpClose.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
vpClose.TextColor3 = Color3.new(1, 1, 1)
vpClose.BorderSizePixel = 0
vpClose.Font = Enum.Font.Code
vpClose.TextSize = 11
vpClose.ZIndex = 7
vpClose.Parent = vpTop
mkCorner(vpClose, 4)

local vpMinimize = Instance.new("TextButton")
vpMinimize.Size = UDim2.new(0, 25, 0, 20)
vpMinimize.Position = UDim2.new(1, -54, 0, 3)
vpMinimize.Text = "-"
vpMinimize.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
vpMinimize.TextColor3 = Color3.new(1, 1, 1)
vpMinimize.BorderSizePixel = 0
vpMinimize.Font = Enum.Font.Code
vpMinimize.TextSize = 11
vpMinimize.ZIndex = 7
vpMinimize.Parent = vpTop
mkCorner(vpMinimize, 4)

local vpMinimized = false
table.insert(connections, vpClose.MouseButton1Click:Connect(function()
	viewportWin.Visible = false
end))
table.insert(connections, vpMinimize.MouseButton1Click:Connect(function()
	vpMinimized = not vpMinimized
	if vpMinimized then
		viewportWin.Size = UDim2.new(0, 300, 0, 28)
		vpMinimize.Text = "+"
	else
		viewportWin.Size = UDim2.new(0, 300, 0, 488)
		vpMinimize.Text = "-"
	end
end))

local vpIdInput = Instance.new("TextBox")
vpIdInput.Text = ""
vpIdInput.PlaceholderText = "animation id..."
vpIdInput.Position = UDim2.new(0, 5, 0, 30)
vpIdInput.Size = UDim2.new(1, -55, 0, 24)
vpIdInput.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
vpIdInput.TextColor3 = Color3.new(1, 1, 1)
vpIdInput.PlaceholderColor3 = Color3.fromRGB(0, 100, 80)
vpIdInput.BorderSizePixel = 0
vpIdInput.Font = Enum.Font.Code
vpIdInput.TextSize = 12
vpIdInput.ZIndex = 7
vpIdInput.Parent = viewportWin
mkCorner(vpIdInput, 4)
mkStroke(vpIdInput, Color3.fromRGB(0, 90, 100), 1)

local vpIdGoBtn = Instance.new("TextButton")
vpIdGoBtn.Text = "▶"
vpIdGoBtn.Position = UDim2.new(1, -47, 0, 30)
vpIdGoBtn.Size = UDim2.new(0, 42, 0, 24)
vpIdGoBtn.BackgroundColor3 = Color3.fromRGB(0, 70, 75)
vpIdGoBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
vpIdGoBtn.BorderSizePixel = 0
vpIdGoBtn.Font = Enum.Font.Code
vpIdGoBtn.TextSize = 13
vpIdGoBtn.ZIndex = 7
vpIdGoBtn.Parent = viewportWin

local vpFrame = Instance.new("ViewportFrame")
vpFrame.Size = UDim2.new(1, -10, 0, 220)
vpFrame.Position = UDim2.new(0, 5, 0, 58)
vpFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
vpFrame.BorderSizePixel = 0
vpFrame.ZIndex = 6
vpFrame.Parent = viewportWin
mkCorner(vpFrame, 4)
mkStroke(vpFrame, Color3.fromRGB(0, 80, 90), 1)
local vpCamera = Instance.new("Camera")
vpCamera.Parent = vpFrame
vpFrame.CurrentCamera = vpCamera
local worldModel = Instance.new("WorldModel")
worldModel.Parent = vpFrame
vpFrame.Ambient = Color3.fromRGB(120, 120, 120)
vpFrame.LightDirection = Vector3.new(-1, -2, -1)
local vpIdLabel = Instance.new("TextLabel")
vpIdLabel.Text = "no animation selected"
vpIdLabel.Position = UDim2.new(0, 5, 0, 284)
vpIdLabel.Size = UDim2.new(1, -10, 0, 14)
vpIdLabel.BackgroundTransparency = 1
vpIdLabel.TextColor3 = Color3.fromRGB(80, 130, 120)
vpIdLabel.Font = Enum.Font.Code
vpIdLabel.TextSize = 11
vpIdLabel.TextXAlignment = Enum.TextXAlignment.Left
vpIdLabel.ZIndex = 6
vpIdLabel.Parent = viewportWin

local vpTimerLabel = Instance.new("TextLabel")
vpTimerLabel.Text = "-- / --"
vpTimerLabel.Position = UDim2.new(0, 5, 0, 300)
vpTimerLabel.Size = UDim2.new(1, -10, 0, 14)
vpTimerLabel.BackgroundTransparency = 1
vpTimerLabel.TextColor3 = Color3.fromRGB(0, 220, 160)
vpTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
vpTimerLabel.Font = Enum.Font.Code
vpTimerLabel.TextSize = 11
vpTimerLabel.ZIndex = 6
vpTimerLabel.Parent = viewportWin

local vpScrubBg = Instance.new("Frame")
vpScrubBg.Position = UDim2.new(0, 5, 0, 317)
vpScrubBg.Size = UDim2.new(1, -10, 0, 12)
vpScrubBg.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
vpScrubBg.BorderSizePixel = 0
vpScrubBg.ZIndex = 6
vpScrubBg.Parent = viewportWin
mkCorner(vpScrubBg, 6)

local vpScrubFill = Instance.new("Frame")
vpScrubFill.Size = UDim2.new(0, 0, 1, 0)
vpScrubFill.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
vpScrubFill.BorderSizePixel = 0
vpScrubFill.ZIndex = 7
vpScrubFill.Parent = vpScrubBg

local vpScrubBtn = Instance.new("TextButton")
vpScrubBtn.Size = UDim2.new(1, 0, 1, 0)
vpScrubBtn.BackgroundTransparency = 1
vpScrubBtn.Text = ""
vpScrubBtn.ZIndex = 8
vpScrubBtn.Parent = vpScrubBg

local vpPaused = false
local vpLastPos = 0
local vpLoopFlash = 0
local vpLooped = false
local vpSpeedBox = nil
local vpPausedAt = 0
local vpPausedLength = 0
local ghostChar = nil
local vpTrack = nil
local vpCurrentId = nil
local vpAnimator = nil
local vpRootPart = nil
local vpYaw = 0
local vpZoomDist = 11

local function nukeGhost()
	if vpTrack then
		pcall(function() vpTrack:Stop(0) end)
		vpTrack = nil
	end
	vpAnimator = nil
	vpRootPart = nil
	if ghostChar then
		pcall(function() ghostChar:Destroy() end)
		ghostChar = nil
	end
	for _, obj in ipairs(worldModel:GetChildren()) do
		pcall(function() obj:Destroy() end)
	end
end

local vpPauseBtn = Instance.new("TextButton")
vpPauseBtn.Text = "⏸ Pause"
vpPauseBtn.Position = UDim2.new(0, 5, 0, 328)
vpPauseBtn.Size = UDim2.new(1, -10, 0, 20)
vpPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 65)
vpPauseBtn.TextColor3 = Color3.new(1, 1, 1)
vpPauseBtn.BorderSizePixel = 0
vpPauseBtn.Font = Enum.Font.Code
vpPauseBtn.TextSize = 11
vpPauseBtn.ZIndex = 6
vpPauseBtn.Parent = viewportWin
mkCorner(vpPauseBtn, 4)

table.insert(connections, vpPauseBtn.MouseButton1Click:Connect(function()
	if not vpPaused and not vpTrack then return end
	vpPaused = not vpPaused
	if vpPaused then
		vpPausedAt = vpTrack and vpTrack.TimePosition or 0
		vpPausedLength = vpTrack and vpTrack.Length or 0
		if vpTrack then
			pcall(function() vpTrack:Stop(0) end)
			vpTrack = nil
		end
		if vpAnimator then
			pcall(function() vpAnimator:Destroy() end)
			vpAnimator = nil
		end
	else
		if vpCurrentId and vpCurrentId ~= "" and ghostChar then
			local hum = ghostChar:FindFirstChildOfClass("Humanoid")
			if hum then
				if vpAnimator then
					pcall(function() vpAnimator:Destroy() end)
				end
				local animator = Instance.new("Animator")
				animator.Parent = hum
				vpAnimator = animator
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. vpCurrentId
				local track
				pcall(function() track = animator:LoadAnimation(anim) end)
				if track then
					track.Priority = Enum.AnimationPriority.Action4
					track.Looped = vpLooped
					track:Play(0, 1, 0)
					track.TimePosition = vpPausedAt
					vpTrack = track
					task.defer(function()
						if vpTrack == track then
							track:AdjustSpeed(tonumber(vpSpeedBox.Text) or 1)
						end
					end)
				end
			end
		end
	end
	vpPauseBtn.Text = vpPaused and "▶ Resume" or "⏸ Pause"
	vpPauseBtn.BackgroundColor3 = vpPaused and Color3.fromRGB(0, 80, 0) or Color3.fromRGB(0, 50, 60)
end))

local vpScrubbing = false
local vpScrubTrack = nil
table.insert(connections, vpScrubBtn.MouseButton1Down:Connect(function()
	vpScrubbing = true
	if vpPaused and ghostChar and vpCurrentId and vpCurrentId ~= "" then
		local hum = ghostChar:FindFirstChildOfClass("Humanoid")
		if hum then
			if vpAnimator then pcall(function() vpAnimator:Destroy() end) end
			local animator = Instance.new("Animator")
			animator.Parent = hum
			vpAnimator = animator
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. vpCurrentId
			pcall(function() vpScrubTrack = animator:LoadAnimation(anim) end)
			if vpScrubTrack then
				vpScrubTrack.Priority = Enum.AnimationPriority.Action4
				vpScrubTrack:Play(0, 1, 0)
				vpScrubTrack.TimePosition = vpPausedAt
			end
		end
	end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and vpScrubbing then
		vpScrubbing = false
		vpScrubTrack = nil
	end
end))

local vpSpeedLabel = Instance.new("TextLabel")
vpSpeedLabel.Text = "Speed"
vpSpeedLabel.Position = UDim2.new(0, 5, 0, 353)
vpSpeedLabel.Size = UDim2.new(0, 40, 0, 20)
vpSpeedLabel.BackgroundTransparency = 1
vpSpeedLabel.TextColor3 = Color3.fromRGB(0, 180, 140)
vpSpeedLabel.Font = Enum.Font.Code
vpSpeedLabel.TextSize = 12
vpSpeedLabel.ZIndex = 6
vpSpeedLabel.Parent = viewportWin
vpSpeedBox = Instance.new("TextBox")
vpSpeedBox.Text = "1"
vpSpeedBox.PlaceholderText = "speed"
vpSpeedBox.Position = UDim2.new(0, 50, 0, 353)
vpSpeedBox.Size = UDim2.new(0, 55, 0, 20)
vpSpeedBox.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
vpSpeedBox.TextColor3 = Color3.new(1, 1, 1)
vpSpeedBox.BorderSizePixel = 0
vpSpeedBox.Font = Enum.Font.Code
vpSpeedBox.TextSize = 12
vpSpeedBox.ZIndex = 6
vpSpeedBox.Parent = viewportWin
mkCorner(vpSpeedBox, 3)
mkStroke(vpSpeedBox, Color3.fromRGB(0, 80, 90), 1)
local vpLoopToggle = Instance.new("TextButton")
vpLoopToggle.Text = "Loop: OFF"
vpLoopToggle.Position = UDim2.new(0, 113, 0, 353)
vpLoopToggle.Size = UDim2.new(0, 80, 0, 20)
vpLoopToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
vpLoopToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
vpLoopToggle.BorderSizePixel = 0
vpLoopToggle.Font = Enum.Font.Code
vpLoopToggle.TextSize = 11
vpLoopToggle.ZIndex = 6
vpLoopToggle.Parent = viewportWin
mkCorner(vpLoopToggle, 4)
local vpTimeLabel = Instance.new("TextLabel")
vpTimeLabel.Text = "Time"
vpTimeLabel.Position = UDim2.new(0, 200, 0, 353)
vpTimeLabel.Size = UDim2.new(0, 35, 0, 20)
vpTimeLabel.BackgroundTransparency = 1
vpTimeLabel.TextColor3 = Color3.fromRGB(0, 180, 140)
vpTimeLabel.Font = Enum.Font.Code
vpTimeLabel.TextSize = 12
vpTimeLabel.ZIndex = 6
vpTimeLabel.Parent = viewportWin
local vpTimeBox = Instance.new("TextBox")
vpTimeBox.Text = "0"
vpTimeBox.PlaceholderText = "time"
vpTimeBox.Position = UDim2.new(0, 238, 0, 353)
vpTimeBox.Size = UDim2.new(0, 52, 0, 20)
vpTimeBox.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
vpTimeBox.TextColor3 = Color3.new(1, 1, 1)
vpTimeBox.BorderSizePixel = 0
vpTimeBox.Font = Enum.Font.Code
vpTimeBox.TextSize = 12
vpTimeBox.ZIndex = 6
vpTimeBox.Parent = viewportWin
mkCorner(vpTimeBox, 3)
mkStroke(vpTimeBox, Color3.fromRGB(0, 80, 90), 1)
local vpPlayBtn = Instance.new("TextButton")
vpPlayBtn.Text = "▶ Play Preview"
vpPlayBtn.Position = UDim2.new(0, 5, 0, 378)
vpPlayBtn.Size = UDim2.new(0.5, -8, 0, 25)
vpPlayBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 70)
vpPlayBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
vpPlayBtn.BorderSizePixel = 0
vpPlayBtn.Font = Enum.Font.Code
vpPlayBtn.ZIndex = 6
vpPlayBtn.Parent = viewportWin
mkCorner(vpPlayBtn, 4)
local vpStopBtn = Instance.new("TextButton")
vpStopBtn.Text = "■ Stop Preview"
vpStopBtn.Position = UDim2.new(0.5, 3, 0, 378)
vpStopBtn.Size = UDim2.new(0.5, -8, 0, 25)
vpStopBtn.BackgroundColor3 = Color3.fromRGB(80, 15, 15)
vpStopBtn.TextColor3 = Color3.fromRGB(255, 160, 140)
vpStopBtn.BorderSizePixel = 0
vpStopBtn.Font = Enum.Font.Code
vpStopBtn.ZIndex = 6
vpStopBtn.Parent = viewportWin
mkCorner(vpStopBtn, 4)
local vpPlaySelfBtn = Instance.new("TextButton")
vpPlaySelfBtn.Text = "★ Play on Self"
vpPlaySelfBtn.Position = UDim2.new(0, 5, 0, 408)
vpPlaySelfBtn.Size = UDim2.new(1, -10, 0, 22)
vpPlaySelfBtn.BackgroundColor3 = Color3.fromRGB(0, 45, 75)
vpPlaySelfBtn.TextColor3 = Color3.fromRGB(140, 190, 255)
vpPlaySelfBtn.BorderSizePixel = 0
vpPlaySelfBtn.Font = Enum.Font.Code
vpPlaySelfBtn.ZIndex = 6
vpPlaySelfBtn.Parent = viewportWin
mkCorner(vpPlaySelfBtn, 4)
local vpRotateCCW = Instance.new("TextButton")
vpRotateCCW.Text = "◄"
vpRotateCCW.Position = UDim2.new(0, 5, 0, 435)
vpRotateCCW.Size = UDim2.new(0.22, -4, 0, 20)
vpRotateCCW.BackgroundColor3 = Color3.fromRGB(20, 22, 38)
vpRotateCCW.TextColor3 = Color3.fromRGB(160, 170, 255)
vpRotateCCW.BorderSizePixel = 0
vpRotateCCW.Font = Enum.Font.Code
vpRotateCCW.TextSize = 13
vpRotateCCW.ZIndex = 6
vpRotateCCW.Parent = viewportWin
mkCorner(vpRotateCCW, 4)
local vpRotateCW = Instance.new("TextButton")
vpRotateCW.Text = "►"
vpRotateCW.Position = UDim2.new(0.78, 3, 0, 435)
vpRotateCW.Size = UDim2.new(0.22, -8, 0, 20)
vpRotateCW.BackgroundColor3 = Color3.fromRGB(20, 22, 38)
vpRotateCW.TextColor3 = Color3.fromRGB(160, 170, 255)
vpRotateCW.BorderSizePixel = 0
vpRotateCW.Font = Enum.Font.Code
vpRotateCW.TextSize = 13
vpRotateCW.ZIndex = 6
vpRotateCW.Parent = viewportWin
mkCorner(vpRotateCW, 4)
local vpPrecisionBox = Instance.new("TextBox")
vpPrecisionBox.Text = "90"
vpPrecisionBox.PlaceholderText = "step"
vpPrecisionBox.Position = UDim2.new(0.22, 2, 0, 435)
vpPrecisionBox.Size = UDim2.new(0.56, -4, 0, 20)
vpPrecisionBox.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
vpPrecisionBox.TextColor3 = Color3.new(1, 1, 1)
vpPrecisionBox.PlaceholderColor3 = Color3.fromRGB(60, 65, 100)
vpPrecisionBox.BorderSizePixel = 0
vpPrecisionBox.Font = Enum.Font.Code
vpPrecisionBox.TextSize = 11
vpPrecisionBox.ZIndex = 6
vpPrecisionBox.Parent = viewportWin
mkCorner(vpPrecisionBox, 3)
mkStroke(vpPrecisionBox, Color3.fromRGB(60, 65, 120), 1)
local vpZoomIn = Instance.new("TextButton")
vpZoomIn.Text = "+ Zoom"
vpZoomIn.Position = UDim2.new(0, 5, 0, 460)
vpZoomIn.Size = UDim2.new(0.5, -8, 0, 20)
vpZoomIn.BackgroundColor3 = Color3.fromRGB(15, 40, 22)
vpZoomIn.TextColor3 = Color3.fromRGB(140, 230, 160)
vpZoomIn.BorderSizePixel = 0
vpZoomIn.Font = Enum.Font.Code
vpZoomIn.TextSize = 11
vpZoomIn.ZIndex = 6
vpZoomIn.Parent = viewportWin
mkCorner(vpZoomIn, 4)
local vpZoomOut = Instance.new("TextButton")
vpZoomOut.Text = "- Zoom"
vpZoomOut.Position = UDim2.new(0.5, 3, 0, 460)
vpZoomOut.Size = UDim2.new(0.5, -8, 0, 20)
vpZoomOut.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
vpZoomOut.TextColor3 = Color3.fromRGB(255, 160, 140)
vpZoomOut.BorderSizePixel = 0
vpZoomOut.Font = Enum.Font.Code
vpZoomOut.TextSize = 11
vpZoomOut.ZIndex = 6
vpZoomOut.Parent = viewportWin
mkCorner(vpZoomOut, 4)
local function makeRig()
	local model = Instance.new("Model")
	model.Name = "PreviewRig"
	local function part(name, size)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.BrickColor = BrickColor.new("Medium stone grey")
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = false
		p.CanCollide = false
		p.CastShadow = false
		p.Parent = model
		return p
	end
	local root  = part("HumanoidRootPart", Vector3.new(2, 2, 1))
	local torso = part("Torso",            Vector3.new(2, 2, 1))
	local head  = part("Head",             Vector3.new(2, 1, 1))
	local rArm  = part("Right Arm",        Vector3.new(1, 2, 1))
	local lArm  = part("Left Arm",         Vector3.new(1, 2, 1))
	local rLeg  = part("Right Leg",        Vector3.new(1, 2, 1))
	local lLeg  = part("Left Leg",         Vector3.new(1, 2, 1))
	root.Anchored = true
	root.Transparency = 1
	root.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, vpYaw, 0)
	model.PrimaryPart = root
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.Parent = model
	local function motor(name, p0, p1, c0, c1)
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Part0 = p0
		m.Part1 = p1
		m.C0 = c0
		m.C1 = c1
		m.Parent = p0
	end
	motor("RootJoint",  root,  torso,
		CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	motor("Neck",       torso, head,
		CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	motor("Right Shoulder", torso, rArm,
		CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Shoulder",  torso, lArm,
		CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	motor("Right Hip",  torso, rLeg,
		CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Hip",   torso, lLeg,
		CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	local nose = Instance.new("Part")
	nose.Name = "Nose"
	nose.Size = Vector3.new(0.3, 0.3, 0.4)
	nose.BrickColor = BrickColor.new("Bright red")
	nose.Color = Color3.fromRGB(255, 0, 0)
	nose.Material = Enum.Material.SmoothPlastic
	nose.Anchored = false
	nose.CanCollide = false
	nose.CastShadow = false
	nose.Parent = model
	local noseWeld = Instance.new("Weld")
	noseWeld.Part0 = head
	noseWeld.Part1 = nose
	noseWeld.C0 = CFrame.new(0, 0, -0.65)
	noseWeld.Parent = head
	model.Parent = worldModel
	local animator = Instance.new("Animator")
	animator.Parent = hum
	return model, animator, root
end
local function previewAnim(id)
	if not id or id == "" then return end
	vpPaused = false
	vpPauseBtn.Text = "⏸ Pause"
	vpPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 60)
	nukeGhost()
	task.spawn(function()
		local rig, animator, rootPart = makeRig()
		if not rig or not animator then return end
		ghostChar = rig
		vpAnimator = animator
		vpRootPart = rootPart
		task.wait(0.1)
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. id
		local track
		pcall(function() track = animator:LoadAnimation(anim) end)
		if track then
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = vpLooped
			track:Play(0, 1, tonumber(vpSpeedBox.Text) or 1)
			vpTrack = track
			local scrub = tonumber(vpTimeBox.Text) or 0
			if scrub > 0 then
				task.defer(function()
					if vpTrack then
						vpTrack.TimePosition = math.clamp(scrub, 0, vpTrack.Length)
					end
				end)
			end
		end
		vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, vpZoomDist), Vector3.new(0, 4, 0))
	end)
end

local function fmtTime(n)
	return string.format("%.2f", n)
end

table.insert(connections, RunService.Heartbeat:Connect(function()
end))

table.insert(connections, RunService.RenderStepped:Connect(function()
	local mouse = UserInputService:GetMouseLocation()

	if viewportWin.Visible and ghostChar then
		vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, vpZoomDist), Vector3.new(0, 4, 0))
	end

	-- VP scrub drag
	if vpScrubbing then
		local bx = vpScrubBg.AbsolutePosition.X
		local bw = vpScrubBg.AbsoluteSize.X
		local rel = math.clamp((mouse.X - bx) / bw, 0, 1)
		if vpTrack and vpTrack.Length > 0 then
			vpPausedAt = rel * vpTrack.Length
			vpTrack.TimePosition = vpPausedAt
		elseif vpPaused and vpPausedLength > 0 then
			vpPausedAt = rel * vpPausedLength
			if vpScrubTrack then
				vpScrubTrack.TimePosition = vpPausedAt
			end
		end
	end

	-- VP scrubber fill
	if vpPaused and vpPausedLength > 0 then
		vpScrubFill.Size = UDim2.new(math.clamp(vpPausedAt / vpPausedLength, 0, 1), 0, 1, 0)
		vpScrubFill.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
	elseif vpTrack and vpTrack.Length > 0 then
		vpScrubFill.Size = UDim2.new(math.clamp(vpTrack.TimePosition / vpTrack.Length, 0, 1), 0, 1, 0)
		vpScrubFill.BackgroundColor3 = vpScrubbing and Color3.fromRGB(0, 180, 130) or Color3.fromRGB(0, 200, 150)
	elseif not vpScrubbing then
		vpScrubFill.Size = UDim2.new(0, 0, 1, 0)
	end

	-- VP timer label
	if vpPaused then
		vpTimerLabel.Text = "⏸ " .. fmtTime(vpPausedAt) .. "s / " .. fmtTime(vpPausedLength) .. "s"
		vpTimerLabel.TextColor3 = Color3.fromRGB(180, 120, 0)
	elseif vpTrack then
		local pos = vpTrack.TimePosition
		local len = vpTrack.Length
		if vpTrack.IsPlaying then
			if vpLooped and pos < vpLastPos and vpLastPos > 0.1 then
				vpLoopFlash = 0.25
			end
			vpLastPos = pos
			if vpLoopFlash > 0 then
				vpLoopFlash = math.max(0, vpLoopFlash - 0.016)
				local t = vpLoopFlash / 0.25
				vpTimerLabel.TextColor3 = Color3.fromRGB(
					math.floor(0 + 255 * t),
					math.floor(220 + (255-220) * t),
					math.floor(160 + (100-160) * t))
			else
				vpTimerLabel.TextColor3 = Color3.fromRGB(0, 220, 160)
			end
			vpTimerLabel.Text = "▶ " .. fmtTime(pos) .. "s / " .. fmtTime(len) .. "s"
		else
			vpLastPos = 0
			vpTimerLabel.Text = "stopped"
			vpTimerLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		end
	else
		vpTimerLabel.Text = "-- / --"
		vpTimerLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
	end

	-- Main scrub drag
	local activeTrack = nil
	local activeCount = 0
	for t in pairs(scriptTracks) do
		if t.IsPlaying or (mainPaused and scriptTracks[t]) then
			activeCount += 1
			if not activeTrack then activeTrack = t end
		end
	end
	-- fallback: find any scriptTrack even if speed=0 (paused)
	if not activeTrack then
		for t in pairs(scriptTracks) do
			activeTrack = t
			break
		end
	end

	if mainScrubbing and activeTrack and activeTrack.Length > 0 then
		local bx = mainScrubBg.AbsolutePosition.X
		local bw = mainScrubBg.AbsoluteSize.X
		local rel = math.clamp((mouse.X - bx) / bw, 0, 1)
		activeTrack.TimePosition = rel * activeTrack.Length
	end

	-- Main scrubber fill
	if activeTrack and activeTrack.Length > 0 then
		local pct = math.clamp(activeTrack.TimePosition / activeTrack.Length, 0, 1)
		mainScrubFill.Size = UDim2.new(pct, 0, 1, 0)
		mainScrubFill.BackgroundColor3 = mainPaused and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(0, 200, 150)
	else
		mainScrubFill.Size = UDim2.new(0, 0, 1, 0)
	end

	-- Main timer label
	if activeTrack and activeTrack.Length > 0 then
		local pos = activeTrack.TimePosition
		local len = activeTrack.Length
		local id = grabId(activeTrack.Animation.AnimationId) or "?"
		mainTimerLabel.Text = (mainPaused and "⏸ " or "▶ ") .. id .. "  " .. fmtTime(pos) .. "s / " .. fmtTime(len) .. "s" .. (activeCount > 1 and ("  (+" .. (activeCount-1) .. ")") or "")
		mainTimerLabel.TextColor3 = mainPaused and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(0, 220, 160)
	else
		mainTimerLabel.Text = "no anim playing"
		mainTimerLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
		if mainPaused then
			mainPaused = false
			mainPauseBtn.Text = "⏸ Pause"
			mainPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 55, 70)
		end
	end
end))

local function popPreview(id)
	vpCurrentId = id
	vpIdLabel.Text = "ID: " .. id
	vpTitle.Text = "preview — " .. id
	vpIdInput.Text = id
	viewportWin.Visible = true
	previewAnim(id)
end
table.insert(connections, vpIdGoBtn.MouseButton1Click:Connect(function()
	local id = grabId(vpIdInput.Text)
	if id and id ~= "" then popPreview(id) end
end))
table.insert(connections, vpIdInput.FocusLost:Connect(function(enter)
	if enter then
		local id = grabId(vpIdInput.Text)
		if id and id ~= "" then popPreview(id) end
	end
end))
table.insert(connections, vpPlayBtn.MouseButton1Click:Connect(function()
	if vpCurrentId then previewAnim(vpCurrentId) end
end))
table.insert(connections, vpStopBtn.MouseButton1Click:Connect(function()
	if vpTrack then
		pcall(function() vpTrack:Stop(0) end)
		vpTrack = nil
	end
	nukeGhost()
end))
table.insert(connections, vpPlaySelfBtn.MouseButton1Click:Connect(function()
	if vpCurrentId then
		fireAnim(vpCurrentId, tonumber(vpSpeedBox.Text) or 1, vpLooped)
	end
end))
table.insert(connections, vpRotateCCW.MouseButton1Click:Connect(function()
	local deg = tonumber(vpPrecisionBox.Text) or 90
	vpYaw = vpYaw + math.rad(deg)
	if vpRootPart then
		vpRootPart.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, vpYaw, 0)
	end
end))
table.insert(connections, vpRotateCW.MouseButton1Click:Connect(function()
	local deg = tonumber(vpPrecisionBox.Text) or 90
	vpYaw = vpYaw - math.rad(deg)
	if vpRootPart then
		vpRootPart.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, vpYaw, 0)
	end
end))
table.insert(connections, vpZoomIn.MouseButton1Click:Connect(function()
	local step = tonumber(vpPrecisionBox.Text) or 2
	vpZoomDist = vpZoomDist - step
	vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, vpZoomDist), Vector3.new(0, 4, 0))
end))
table.insert(connections, vpZoomOut.MouseButton1Click:Connect(function()
	local step = tonumber(vpPrecisionBox.Text) or 2
	vpZoomDist = vpZoomDist + step
	vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, vpZoomDist), Vector3.new(0, 4, 0))
end))
table.insert(connections, vpSpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(vpSpeedBox.Text:match("[%d%.]+"))
	if num and vpTrack and vpTrack.IsPlaying then
		vpTrack:AdjustSpeed(num)
	end
end))
table.insert(connections, vpTimeBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(vpTimeBox.Text:match("[%d%.]+"))
	if num and vpTrack and vpTrack.IsPlaying then
		vpTrack.TimePosition = math.clamp(num, 0, vpTrack.Length)
	end
end))
table.insert(connections, vpLoopToggle.MouseButton1Click:Connect(function()
	vpLooped = not vpLooped
	vpLoopToggle.Text = "Loop: " .. (vpLooped and "ON" or "OFF")
	vpLoopToggle.BackgroundColor3 = vpLooped and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
	vpLoopToggle.BorderColor3 = vpLooped and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
	if vpTrack then vpTrack.Looped = vpLooped end
end))
table.insert(connections, previewToggle.MouseButton1Click:Connect(function()
	viewportWin.Visible = not viewportWin.Visible
end))
local function addReplUI(id, targetId, speed, loop)
	local rFrame = Instance.new("Frame")
	rFrame.Size = UDim2.new(1, 0, 0, 120)
	rFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 20)
	rFrame.BorderSizePixel = 1
	rFrame.BorderColor3 = Color3.fromRGB(80, 80, 0)
	rFrame.ZIndex = 3
	rFrame.Parent = sideList
	local replaceL = Instance.new("TextBox")
	replaceL.Size = UDim2.new(1, -10, 0, 20)
	replaceL.Position = UDim2.new(0, 5, 0, 5)
	replaceL.Text = id or ""
	replaceL.PlaceholderText = "replace anim id..."
	replaceL.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	replaceL.TextColor3 = Color3.new(1, 1, 1)
	replaceL.Font = Enum.Font.Code
	replaceL.ZIndex = 4
	replaceL.Parent = rFrame
	local targetL = Instance.new("TextBox")
	targetL.Size = UDim2.new(1, -10, 0, 20)
	targetL.Position = UDim2.new(0, 5, 0, 30)
	targetL.Text = targetId or ""
	targetL.PlaceholderText = "target anim id..."
	targetL.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	targetL.TextColor3 = Color3.new(1, 1, 1)
	targetL.Font = Enum.Font.Code
	targetL.ZIndex = 4
	targetL.Parent = rFrame
	local speedL = Instance.new("TextBox")
	speedL.Size = UDim2.new(0.5, -10, 0, 20)
	speedL.Position = UDim2.new(0, 5, 0, 55)
	speedL.Text = tostring(speed or 1)
	speedL.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	speedL.TextColor3 = Color3.new(1, 1, 1)
	speedL.ZIndex = 4
	speedL.Parent = rFrame
	local loopT = Instance.new("TextButton")
	loopT.Size = UDim2.new(0.5, -10, 0, 20)
	loopT.Position = UDim2.new(0.5, 5, 0, 55)
	loopT.Text = "Loop: " .. (loop and "ON" or "OFF")
	loopT.BackgroundColor3 = loop and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
	loopT.TextColor3 = Color3.new(1, 1, 1)
	loopT.ZIndex = 4
	loopT.Parent = rFrame
	local del = Instance.new("TextButton")
	del.Size = UDim2.new(1, -10, 0, 20)
	del.Position = UDim2.new(0, 5, 0, 80)
	del.Text = "Delete Replacement"
	del.BackgroundColor3 = Color3.fromRGB(120, 15, 15)
	del.TextColor3 = Color3.new(1, 1, 1)
	del.ZIndex = 5
	del.Parent = rFrame
	local function updateRep()
		local oldId = id
		id = replaceL.Text
		if oldId and oldId ~= id then replacements[oldId] = nil end
		replacements[id] = { targetId = targetL.Text, speed = tonumber(speedL.Text) or 1, loop = loop }
		dumpCfg()
	end
	table.insert(connections, replaceL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(connections, targetL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(connections, speedL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(connections, loopT.MouseButton1Click:Connect(function()
		loop = not loop
		loopT.Text = "Loop: " .. (loop and "ON" or "OFF")
		loopT.BackgroundColor3 = loop and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
		updateRep()
	end))
	table.insert(connections, del.MouseButton1Click:Connect(function()
		replacements[id] = nil
		rFrame:Destroy()
		dumpCfg()
	end))
end
table.insert(connections, addR.MouseButton1Click:Connect(function()
	addReplUI("", "", 1, false)
end))
local function addBind(bindData)
	local bFrame = Instance.new("Frame")
	bFrame.Size = UDim2.new(1, 0, 0, 190)
	bFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
	bFrame.BorderSizePixel = 0
	bFrame.ZIndex = 3
	bFrame.Parent = sideList
	mkCorner(bFrame, 5)
	mkStroke(bFrame, Color3.fromRGB(0, 60, 70), 1)
	local activeBar = Instance.new("Frame")
	activeBar.Name = "ActiveBar"
	activeBar.Size = UDim2.new(1, 0, 0, 3)
	activeBar.Position = UDim2.new(0, 0, 0, 0)
	activeBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	activeBar.BorderSizePixel = 0
	activeBar.ZIndex = 5
	activeBar.Parent = bFrame
	local macroHint = Instance.new("TextLabel")
	macroHint.Size = UDim2.new(1, -10, 0, 14)
	macroHint.Position = UDim2.new(0, 5, 0, 8)
	macroHint.BackgroundTransparency = 1
	macroHint.TextColor3 = Color3.fromRGB(100, 100, 100)
	macroHint.Font = Enum.Font.Code
	macroHint.TextSize = 10
	macroHint.TextXAlignment = Enum.TextXAlignment.Left
	macroHint.Text = "ID or macro (play x; wait t; stop)"
	macroHint.ZIndex = 4
	macroHint.Parent = bFrame
	local idL = Instance.new("TextBox")
	idL.Size = UDim2.new(1, -10, 0, 22)
	idL.Position = UDim2.new(0, 5, 0, 25)
	idL.Text = bindData.id or ""
	idL.PlaceholderText = "id or macro..."
	idL.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	idL.TextColor3 = Color3.new(1, 1, 1)
	idL.Font = Enum.Font.Code
	idL.TextSize = 12
	idL.ZIndex = 4
	idL.Parent = bFrame
	mkCorner(idL, 3)
	mkStroke(idL, Color3.fromRGB(0, 70, 80), 1)
	local keyB = Instance.new("TextButton")
	keyB.Size = UDim2.new(1, -10, 0, 22)
	keyB.Position = UDim2.new(0, 5, 0, 52)
	keyB.Text = "Key: " .. (bindData.key and bindData.key.Name or "None")
	keyB.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	keyB.TextColor3 = Color3.new(1, 1, 1)
	keyB.Font = Enum.Font.Code
	keyB.TextSize = 12
	keyB.ZIndex = 4
	keyB.Parent = bFrame
	mkCorner(keyB, 3)
	mkStroke(keyB, Color3.fromRGB(0, 60, 70), 1)
	local holdT = Instance.new("TextButton")
	holdT.Size = UDim2.new(1, -10, 0, 20)
	holdT.Position = UDim2.new(0, 5, 0, 78)
	holdT.Text = "Hold: " .. (bindData.hold and "ON" or "OFF")
	holdT.BackgroundColor3 = bindData.hold and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(60, 0, 0)
	holdT.TextColor3 = Color3.new(1, 1, 1)
	holdT.Font = Enum.Font.Code
	holdT.TextSize = 12
	holdT.ZIndex = 4
	holdT.Parent = bFrame
	mkCorner(holdT, 3)
	local speedB = Instance.new("TextBox")
	speedB.Size = UDim2.new(1, -10, 0, 20)
	speedB.Position = UDim2.new(0, 5, 0, 103)
	speedB.Text = "Speed: " .. (bindData.speed or 1)
	speedB.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	speedB.TextColor3 = Color3.new(1, 1, 1)
	speedB.Font = Enum.Font.Code
	speedB.TextSize = 12
	speedB.ZIndex = 4
	speedB.Parent = bFrame
	mkCorner(speedB, 3)
	mkStroke(speedB, Color3.fromRGB(0, 70, 80), 1)
	local loopT = Instance.new("TextButton")
	loopT.Size = UDim2.new(1, -10, 0, 20)
	loopT.Position = UDim2.new(0, 5, 0, 128)
	loopT.Text = "Loop: " .. (bindData.loop and "ON" or "OFF")
	loopT.BackgroundColor3 = bindData.loop and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(60, 0, 0)
	loopT.TextColor3 = Color3.new(1, 1, 1)
	loopT.Font = Enum.Font.Code
	loopT.TextSize = 12
	loopT.ZIndex = 4
	loopT.Parent = bFrame
	mkCorner(loopT, 3)
	local lastFiredLabel = Instance.new("TextLabel")
	lastFiredLabel.Size = UDim2.new(1, -10, 0, 14)
	lastFiredLabel.Position = UDim2.new(0, 5, 0, 153)
	lastFiredLabel.BackgroundTransparency = 1
	lastFiredLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
	lastFiredLabel.Font = Enum.Font.Code
	lastFiredLabel.TextSize = 10
	lastFiredLabel.TextXAlignment = Enum.TextXAlignment.Left
	lastFiredLabel.Text = "never fired"
	lastFiredLabel.ZIndex = 4
	lastFiredLabel.Parent = bFrame
	local del = Instance.new("TextButton")
	del.Size = UDim2.new(0, 15, 0, 15)
	del.Position = UDim2.new(1, -15, 0, 0)
	del.Text = "X"
	del.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
	del.TextColor3 = Color3.new(1, 1, 1)
	del.ZIndex = 5
	del.Parent = bFrame
	mkCorner(del, 3)
	bindData._activeBar = activeBar
	bindData._lastFiredLabel = lastFiredLabel
	table.insert(bindIndicators, bindData)
	local settingKey = false
	table.insert(connections, keyB.MouseButton1Click:Connect(function()
		settingKey = true
		keyB.Text = "Press a key..."
	end))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if settingKey and input.UserInputType == Enum.UserInputType.Keyboard then
			settingKey = false
			bindData.key = input.KeyCode
			keyB.Text = "Key: " .. input.KeyCode.Name
			dumpBinds()
		end
	end))
	table.insert(connections, idL:GetPropertyChangedSignal("Text"):Connect(function()
		bindData.id = idL.Text
		dumpBinds()
	end))
	table.insert(connections, holdT.MouseButton1Click:Connect(function()
		bindData.hold = not bindData.hold
		holdT.Text = "Hold: " .. (bindData.hold and "ON" or "OFF")
		holdT.BackgroundColor3 = bindData.hold and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
		dumpBinds()
	end))
	table.insert(connections, speedB:GetPropertyChangedSignal("Text"):Connect(function()
		bindData.speed = tonumber(speedB.Text:match("[%d%.]+")) or 1
		dumpBinds()
	end))
	table.insert(connections, loopT.MouseButton1Click:Connect(function()
		bindData.loop = not bindData.loop
		loopT.Text = "Loop: " .. (bindData.loop and "ON" or "OFF")
		loopT.BackgroundColor3 = bindData.loop and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
		dumpBinds()
	end))
	table.insert(connections, del.MouseButton1Click:Connect(function()
		killAnim(bindData.id)
		for i, v in pairs(keybinds) do
			if v == bindData then
				table.remove(keybinds, i)
				break
			end
		end
		bFrame:Destroy()
		dumpBinds()
	end))
end
table.insert(connections, addB.MouseButton1Click:Connect(function()
	local nb = {id = "", key = nil, hold = false, speed = 1, loop = false, active = false, tracks = {}, token = 0}
	table.insert(keybinds, nb)
	addBind(nb)
end))
local function addFavRow(id, displayName)
	if favoriteEntries[id] then return end
	local fFrame = Instance.new("Frame")
	fFrame.Name = "fav_" .. id
	fFrame.Size = UDim2.new(1, -5, 0, 25)
	fFrame.BackgroundTransparency = 1
	fFrame.ZIndex = 3
	fFrame.Parent = favsList
	local fBtn = Instance.new("TextButton")
	fBtn.Size = UDim2.new(1, -95, 1, 0)
	fBtn.BackgroundColor3 = Color3.fromRGB(22, 19, 5)
	fBtn.TextColor3 = Color3.fromRGB(220, 200, 0)
	fBtn.TextXAlignment = Enum.TextXAlignment.Left
	fBtn.Text = "★ " .. id .. " | " .. (displayName or "Unknown")
	fBtn.BorderSizePixel = 0
	fBtn.Font = Enum.Font.Code
	fBtn.TextSize = 12
	fBtn.ZIndex = 4
	fBtn.Parent = fFrame
	mkCorner(fBtn, 3)
	local fPreviewBtn = Instance.new("TextButton")
	fPreviewBtn.Size = UDim2.new(0, 42, 1, 0)
	fPreviewBtn.Position = UDim2.new(1, -95, 0, 0)
	fPreviewBtn.Text = "👁 View"
	fPreviewBtn.BackgroundColor3 = Color3.fromRGB(0, 48, 68)
	fPreviewBtn.TextColor3 = Color3.new(1, 1, 1)
	fPreviewBtn.BorderSizePixel = 0
	fPreviewBtn.Font = Enum.Font.Code
	fPreviewBtn.TextSize = 11
	fPreviewBtn.ZIndex = 4
	fPreviewBtn.Parent = fFrame
	mkCorner(fPreviewBtn, 3)
	local fCopyBtn = Instance.new("TextButton")
	fCopyBtn.Size = UDim2.new(0, 42, 1, 0)
	fCopyBtn.Position = UDim2.new(1, -48, 0, 0)
	fCopyBtn.Text = "Copy"
	fCopyBtn.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
	fCopyBtn.TextColor3 = Color3.new(1, 1, 1)
	fCopyBtn.BorderSizePixel = 0
	fCopyBtn.Font = Enum.Font.Code
	fCopyBtn.TextSize = 11
	fCopyBtn.ZIndex = 4
	fCopyBtn.Parent = fFrame
	mkCorner(fCopyBtn, 3)
	local fUnstarBtn = Instance.new("TextButton")
	fUnstarBtn.Size = UDim2.new(0, 0, 1, 0)
	fUnstarBtn.BackgroundTransparency = 1
	fUnstarBtn.ZIndex = 1
	fUnstarBtn.Text = ""
	fUnstarBtn.Parent = fFrame
	favoriteEntries[id] = fFrame
	table.insert(connections, fBtn.MouseButton1Click:Connect(function()
		idBox.Text = id
	end))
	table.insert(connections, fPreviewBtn.MouseButton1Click:Connect(function()
		popPreview(id)
	end))
	table.insert(connections, fCopyBtn.MouseButton1Click:Connect(function()
		yoink(id)
	end))
end
local function killFavRow(id)
	if favoriteEntries[id] then
		favoriteEntries[id]:Destroy()
		favoriteEntries[id] = nil
	end
end
local function addLogRow(id, name, key, priority)
	key = key or id
	local entryFrame = Instance.new("Frame")
	entryFrame.Name = key
	entryFrame.Size = UDim2.new(1, -5, 0, 22)
	entryFrame.ClipsDescendants = true
	entryFrame.BackgroundTransparency = 1
	entryFrame.ZIndex = 3
	entryFrame.Parent = list
	local entry = Instance.new("TextButton")
	entry.Size = UDim2.new(1, -142, 1, 0)
	entry.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
	entry.TextColor3 = Color3.fromRGB(0, 255, 200)
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.Text = "(1) [" .. (priority or "N/A") .. "] " .. id .. " | " .. name .. " @" .. (animTimestamps[key] or os.date("%H:%M:%S"))
	entry.BorderSizePixel = 0
	entry.Font = Enum.Font.Code
	entry.TextSize = 11
	entry.TextTruncate = Enum.TextTruncate.AtEnd
	entry.ZIndex = 4
	entry.Visible = true
	entry.Parent = entryFrame
	mkCorner(entry, 3)
	local previewBtn = Instance.new("TextButton")
	previewBtn.Name = "Preview"
	previewBtn.Size = UDim2.new(0, 20, 1, 0)
	previewBtn.Position = UDim2.new(1, -140, 0, 0)
	previewBtn.BackgroundColor3 = Color3.fromRGB(0, 48, 68)
	previewBtn.TextColor3 = Color3.new(1, 1, 1)
	previewBtn.Text = "👁"
	previewBtn.BorderSizePixel = 0
	previewBtn.Font = Enum.Font.Code
	previewBtn.TextSize = 12
	previewBtn.ZIndex = 4
	previewBtn.Visible = true
	previewBtn.Parent = entryFrame
	mkCorner(previewBtn, 3)
	local favBtn = Instance.new("TextButton")
	favBtn.Name = "Fav"
	favBtn.Size = UDim2.new(0, 20, 1, 0)
	favBtn.Position = UDim2.new(1, -118, 0, 0)
	favBtn.BackgroundColor3 = Color3.fromRGB(38, 36, 0)
	favBtn.TextColor3 = Color3.new(1, 1, 1)
	favBtn.Text = favorites[id] and "★" or "☆"
	favBtn.BorderSizePixel = 0
	favBtn.Font = Enum.Font.Code
	favBtn.TextSize = 12
	favBtn.ZIndex = 4
	favBtn.Visible = true
	favBtn.Parent = entryFrame
	mkCorner(favBtn, 3)
	local nameBtn = Instance.new("TextButton")
	nameBtn.Name = "Name"
	nameBtn.Size = UDim2.new(0, 46, 1, 0)
	nameBtn.Position = UDim2.new(1, -96, 0, 0)
	nameBtn.BackgroundColor3 = Color3.fromRGB(0, 38, 45)
	nameBtn.TextColor3 = Color3.new(1, 1, 1)
	nameBtn.Text = "Name"
	nameBtn.BorderSizePixel = 0
	nameBtn.Font = Enum.Font.Code
	nameBtn.TextSize = 10
	nameBtn.ZIndex = 4
	nameBtn.Visible = true
	nameBtn.Parent = entryFrame
	mkCorner(nameBtn, 3)
	local copyBtn = Instance.new("TextButton")
	copyBtn.Name = "Copy"
	copyBtn.Size = UDim2.new(0, 46, 1, 0)
	copyBtn.Position = UDim2.new(1, -48, 0, 0)
	copyBtn.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
	copyBtn.TextColor3 = Color3.new(1, 1, 1)
	copyBtn.Text = "Copy"
	copyBtn.BorderSizePixel = 0
	copyBtn.Font = Enum.Font.Code
	copyBtn.TextSize = 10
	copyBtn.ZIndex = 4
	copyBtn.Visible = true
	copyBtn.Parent = entryFrame
	mkCorner(copyBtn, 3)
	table.insert(connections, entry.MouseButton1Click:Connect(function()
		idBox.Text = id
	end))
	table.insert(connections, previewBtn.MouseButton1Click:Connect(function()
		popPreview(id)
	end))
	table.insert(connections, favBtn.MouseButton1Click:Connect(function()
		favorites[id] = not favorites[id]
		favBtn.Text = favorites[id] and "★" or "☆"
		if favorites[id] then
			addFavRow(id, customNames[id] or name)
		else
			killFavRow(id)
		end
		dumpCfg()
	end))
	table.insert(connections, nameBtn.MouseButton1Click:Connect(function()
		local nameInput = Instance.new("TextBox")
		nameInput.Text = customNames[id] or ""
		nameInput.PlaceholderText = "enter name..."
		nameInput.Size = UDim2.new(1, -114, 1, 0)
		nameInput.Position = UDim2.new(0, 0, 0, 0)
		nameInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		nameInput.TextColor3 = Color3.new(1, 1, 1)
		nameInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
		nameInput.BorderSizePixel = 1
		nameInput.BorderColor3 = Color3.fromRGB(0, 200, 150)
		nameInput.Font = Enum.Font.Code
		nameInput.TextSize = 11
		nameInput.ZIndex = 6
		nameInput.Parent = entryFrame
		nameInput:CaptureFocus()
		local function applyName()
			local newName = nameInput.Text:match("^%s*(.-)%s*$")
			nameInput:Destroy()
			if newName ~= "" then
				customNames[id] = newName
				entry.Text = "(" .. (animCounts[key] or 1) .. ") [" .. (priority or "N/A") .. "] " .. id .. " | " .. newName .. " (" .. name .. ") @" .. (animTimestamps[key] or "?")
				if favoriteEntries[id] then
					local fBtn = favoriteEntries[id]:FindFirstChildOfClass("TextButton")
					if fBtn then fBtn.Text = "★ " .. id .. " | " .. newName end
				end
				dumpCfg()
			end
		end
		table.insert(connections, nameInput.FocusLost:Connect(function()
			applyName()
		end))
	end))
	table.insert(connections, copyBtn.MouseButton1Click:Connect(function()
		yoink(id)
	end))
	animFrames[key] = entry
	local n = 0
	for _ in pairs(animFrames) do n += 1 end
	logCountLabel.Text = n .. " logged"
end
local PRIORITY_NAMES = {
	Action   = "game",
	Action2  = "game2",
	Action3  = "game3",
	Action4  = "game4",
	Core     = "coreanims",
	Idle     = "idle",
	Movement = "movement",
}
local function fixPriority(raw)
	return PRIORITY_NAMES[raw] or raw or "?"
end
local function logIt(id, name, playerName, priority)
	if banned[id] then return end
	if trueBanned[id] then return end
	local entryName = name
	local key = id
	if playerName then
		key = id .. "_" .. playerName
		if playerName ~= player.Name then
			entryName = "[" .. playerName .. "] " .. name
		end
	end
	if customNames[id] then
		entryName = customNames[id] .. " (" .. entryName .. ")"
	end
	if autoCopy then yoink(id) end
	if not animCounts[key] then
		animCounts[key] = 1
		animTimestamps[key] = os.date("%H:%M:%S")
		addLogRow(id, entryName, key, priority)
	else
		animCounts[key] += 1
		animTimestamps[key] = os.date("%H:%M:%S")
		local entry = animFrames[key]
		if entry then
			entry.Text = "(" .. animCounts[key] .. ") [" .. (priority or "N/A") .. "] " .. id .. " | " .. entryName .. " @" .. animTimestamps[key]
		end
	end
end
local function refreshColors()
	local animator = grabAnimator()
	local playingIds = {}
	if animator then
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			playingIds[grabId(track.Animation.AnimationId)] = true
		end
	end
	for id, entry in pairs(animFrames) do
		local pureId = id:match("^([%d]+)")
		if trueBanned[pureId] then
			entry.TextColor3 = Color3.fromRGB(180, 0, 0)
		elseif banned[pureId] then
			entry.TextColor3 = Color3.fromRGB(255, 50, 50)
		elseif playingIds[pureId] then
			entry.TextColor3 = Color3.fromRGB(50, 255, 50)
		else
			entry.TextColor3 = Color3.fromRGB(0, 255, 200)
		end
	end
end
task.spawn(function()
	while running do
		refreshColors()
		for _, bind in pairs(bindIndicators) do
			if bind._activeBar and bind._activeBar.Parent then
				bind._activeBar.BackgroundColor3 = bind.active
					and Color3.fromRGB(0, 220, 100)
					or Color3.fromRGB(40, 40, 40)
			end
		end
		task.wait(0.1)
	end
end)
local function trackSeen(track, playerName)
	local anim = track.Animation
	if not anim then return end
	local id = grabId(anim.AnimationId)
	if not id then return end
	if banned[id] then
		track:AdjustWeight(0, 0)
		track:AdjustSpeed(0)
		track:Stop(0)
		return
	end
	if trueBanned[id] then
		track:AdjustWeight(0, 0)
		track:AdjustSpeed(0)
		track:Stop(0)
		return
	end
	if replacements[id] and playerName == player.Name and not scriptTracks[track] then
		local rep = replacements[id]
		track:AdjustWeight(0, 0)
		track:AdjustSpeed(0)
		track:Stop(0)
		fireAnim(rep.targetId, rep.speed, rep.loop)
		return
	end
	if playerName ~= player.Name and not globalLogging then return end
	if seenTracks[track] then return end
	seenTracks[track] = true
	logIt(id, anim.Name or "Unknown", playerName, fixPriority(track.Priority.Name))
	local stopConn
	stopConn = track.Stopped:Connect(function()
		seenTracks[track] = nil
		if stopConn then stopConn:Disconnect() end
	end)
	table.insert(connections, stopConn)
end
local function hookAnimator(animator, playerName)
	if animator then
		table.insert(connections, animator.AnimationPlayed:Connect(function(track)
			if playerName == player.Name then
				local scriptAnimActive = false
				for t in pairs(scriptTracks) do
					if t.IsPlaying then
						scriptAnimActive = true
						break
					end
				end
				if scriptAnimActive and not scriptTracks[track] then
					track:AdjustWeight(0, 0)
					track:AdjustSpeed(0)
					track:Stop(0)
					for t in pairs(scriptTracks) do
						if t.IsPlaying then
							t:AdjustWeight(1, 0)
						end
					end
					return
				end
			end
			trackSeen(track, playerName)
		end))
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			trackSeen(track, playerName)
		end
	end
end
local function onJoin(p)
	table.insert(connections, p.CharacterAdded:Connect(function(char)
		if p == player then
			for _, bind in pairs(keybinds) do
				bind.active = false
			end
			scriptTracks = {}
		end
		task.wait(1)
		hookAnimator(grabAnimator(char), p.Name)
	end))
	if p.Character then
		hookAnimator(grabAnimator(p.Character), p.Name)
	end
end
table.insert(connections, Players.PlayerAdded:Connect(onJoin))
for _, p in pairs(Players:GetPlayers()) do
	onJoin(p)
end
task.spawn(function()
	while running do
		for _, bind in pairs(keybinds) do
			if bind.active and bind.hold and not banned[bind.id] then
				local isMacroCheck = tostring(bind.id):find(";") or tostring(bind.id):lower():match("^play%s")
				if not isMacroCheck then
					local isPlaying = false
					local animator = grabAnimator()
					if animator then
						for _, t in pairs(animator:GetPlayingAnimationTracks()) do
							if grabId(t.Animation.AnimationId) == bind.id and t.IsPlaying then
								isPlaying = true
								if isFrozen then t:AdjustSpeed(0) end
								break
							end
						end
					end
					if not isPlaying then
						fireAnim(bind.id, bind.speed, bind.loop)
					end
				end
			elseif bind.active and not bind.hold and not banned[bind.id] then
				local isMacroCheck = tostring(bind.id):find(";") or tostring(bind.id):lower():match("^play%s")
				if not isMacroCheck and bind.loop then
					local isPlaying = false
					local animator = grabAnimator()
					if animator then
						for _, t in pairs(animator:GetPlayingAnimationTracks()) do
							if grabId(t.Animation.AnimationId) == bind.id and t.IsPlaying then
								isPlaying = true
								break
							end
						end
					end
					if not isPlaying then
						fireAnim(bind.id, bind.speed, bind.loop)
					end
				end
			end
		end
		task.wait()
	end
end)
local function doCmd(cmd, isRelease)
	local parts = cmd:lower():split(" ")
	local action = parts[1]
	if action == "pause" or action == "freeze" then
		if isRelease then
			isFrozen = false
		else
			isFrozen = not isFrozen
		end
		for track in pairs(scriptTracks) do
			if track.IsPlaying then track:AdjustSpeed(isFrozen and 0 or 1) end
		end
	elseif action == "speed" and not isRelease then
		local num = tonumber(parts[2])
		if num then
			for track in pairs(scriptTracks) do
				if track.IsPlaying then track:AdjustSpeed(num) end
			end
		end
	elseif action == "ban" and not isRelease then
		local id = parts[2]
		if id then banned[id] = true; killAnim(id); dumpCfg() end
	elseif action == "unban" and not isRelease then
		local id = parts[2]
		if id then banned[id] = nil; dumpCfg() end
	elseif action == "stop" and not isRelease then
		local id = parts[2]
		if id then killAnim(id) end
	elseif action == "step" and not isRelease then
		local num = tonumber(parts[2]) or 0.1
		for track in pairs(scriptTracks) do
			if track.IsPlaying then
				track.TimePosition = math.clamp(track.TimePosition + num, 0, track.Length)
			end
		end
	elseif action == "loop" and not isRelease then
		looped = not looped
		refreshLoopBtn()
		dumpCfg()
	elseif action == "clear" and not isRelease then
		nukeList()
	end
end
local function isMacro(str)
	return str:find(";") ~= nil or str:lower():match("^play%s") ~= nil
end
local function doMacro(macroStr, bindData, stopFlag)
	task.spawn(function()
		local steps = macroStr:split(";")
		for _, step in ipairs(steps) do
			if not stopFlag.active then break end
			step = step:match("^%s*(.-)%s*$")
			if step == "" then continue end
			local parts = step:split(" ")
			local cmd = parts[1]:lower()
			if cmd == "play" then
				local id = parts[2]
				local spd = tonumber(parts[3]) or bindData.speed or 1
				local lp = (parts[4] == "true") or bindData.loop or false
				if id and id ~= "" then fireAnim(id, spd, lp) end
			elseif cmd == "wait" then
				local t = tonumber(parts[2]) or 0.5
				local elapsed = 0
				while elapsed < t and stopFlag.active do
					task.wait(0.05)
					elapsed = elapsed + 0.05
				end
			elseif cmd == "stop" then
				local id = parts[2]
				if id and id ~= "" then
					killAnim(id)
				else
					for track in pairs(scriptTracks) do pcall(function() track:Stop() end) end
					scriptTracks = {}
				end
			elseif cmd == "speed" then
				local num = tonumber(parts[2])
				if num then
					for track in pairs(scriptTracks) do
						if track.IsPlaying then track:AdjustSpeed(num) end
					end
				end
			elseif cmd == "loop" then
				looped = not looped
				refreshLoopBtn()
			elseif cmd == "freeze" or cmd == "pause" then
				isFrozen = not isFrozen
				for track in pairs(scriptTracks) do
					if track.IsPlaying then track:AdjustSpeed(isFrozen and 0 or 1) end
				end
			end
		end
		stopFlag.active = false
	end)
end
local COMMAND_PREFIXES = {"pause", "freeze", "speed", "ban", "unban", "stop", "step", "loop", "clear"}
local function isCmd(str)
	local low = str:lower()
	for _, c in pairs(COMMAND_PREFIXES) do
		if low:match("^" .. c) then return true end
	end
	return false
end
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for _, bind in pairs(keybinds) do
		if bind.key and input.KeyCode == bind.key then
			local idStr = tostring(bind.id)
			local timeStr = os.date("%H:%M:%S")
			bind._lastFired = timeStr
			if bind._lastFiredLabel and bind._lastFiredLabel.Parent then
				bind._lastFiredLabel.Text = "fired: " .. timeStr
				bind._lastFiredLabel.TextColor3 = Color3.fromRGB(0, 200, 150)
			end
			if isMacro(idStr) then
				if not bind.macroFlag or not bind.macroFlag.active then
					bind.macroFlag = { active = true }
					doMacro(idStr, bind, bind.macroFlag)
				end
			elseif isCmd(idStr) then
				if bind.hold then
					local low = idStr:lower()
					if low:match("^pause") or low:match("^freeze") then
						isFrozen = true
						for track in pairs(scriptTracks) do
							if track.IsPlaying then track:AdjustSpeed(0) end
						end
					else
						doCmd(idStr, false)
					end
				else
					doCmd(idStr, false)
				end
			else
				if bind.hold then
					bind.active = true
					fireAnim(bind.id, bind.speed, bind.loop)
				else
					bind.active = not bind.active
					if not bind.active then
						killAnim(bind.id)
					else
						local t = fireAnim(bind.id, bind.speed, bind.loop)
						if not bind.loop and t then
							t.Stopped:Connect(function()
								bind.active = false
							end)
						end
					end
				end
			end
		end
	end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	for _, bind in pairs(keybinds) do
		if bind.key and input.KeyCode == bind.key then
			local idStr = tostring(bind.id)
			if isMacro(idStr) then
				if bind.macroFlag then bind.macroFlag.active = false end
			elseif isCmd(idStr) then
				if bind.hold then
					local low = idStr:lower()
					if low:match("^pause") or low:match("^freeze") then
						isFrozen = false
						for track in pairs(scriptTracks) do
							if track.IsPlaying then track:AdjustSpeed(1) end
						end
					end
				end
			else
				if bind.hold then
					bind.active = false
					bind.token = (bind.token or 0) + 1
					for t in pairs(scriptTracks) do
						if grabId(t.Animation.AnimationId) == bind.id then
							scriptTracks[t] = nil
							pcall(function() t:Stop(0) end)
						end
					end
				end
			end
		end
	end
end))
local function loadSavedBinds()
	if readfile and isfile and isfile(keybindFile) then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(keybindFile)) end)
		if ok and type(data) == "table" then
			for _, b in pairs(data) do
				local nb = {
					id = b.id,
					key = b.key and Enum.KeyCode[b.key] or nil,
					hold = b.hold or false,
					speed = b.speed or 1,
					loop = b.loop or false,
					active = false,
					tracks = {},
					token = 0
				}
				table.insert(keybinds, nb)
				addBind(nb)
			end
		end
	end
end
local function loadCfg()
	if readfile and isfile and isfile(configFile) then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(configFile)) end)
		if ok and type(data) == "table" then
			looped = data.looped or false
			globalLogging = data.globalLogging or false
			autoCopy = data.autoCopy or false
			banned = data.banned or {}
			trueBanned = data.trueBanned or {}
			if data.toggleKey and Enum.KeyCode[data.toggleKey] then
				toggleKey = Enum.KeyCode[data.toggleKey]
			end
			replacements = data.replacements or {}
			favorites = data.favorites or {}
			customNames = data.customNames or {}
			refreshLoopBtn()
			refreshGlobalBtn()
			refreshAutoCopyBtn()
			for id, rep in pairs(replacements) do
				addReplUI(id, rep.targetId, rep.speed, rep.loop)
			end
			for id, isFav in pairs(favorites) do
				if isFav then addFavRow(id, customNames[id] or id) end
			end
		end
	end
end
loadCfg()
toggleKeyBtn.Text = "Hide Key: " .. toggleKey.Name
loadSavedBinds()
local function tickLoop()
	for _, p in pairs(Players:GetPlayers()) do
		local isLocal = (p == player)
		local animator = grabAnimator(p.Character)
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
				local tid = grabId(track.Animation.AnimationId)
				if tid and (banned[tid] or trueBanned[tid]) then
					track:AdjustWeight(0, 0)
					track:AdjustSpeed(0)
					track:Stop(0)
					continue
				end
				if isLocal and scriptAnimActive and not scriptTracks[track] then
					track:AdjustWeight(0, 0)
					track:AdjustSpeed(0)
					track:Stop(0)
				elseif globalLogging or isLocal then
					trackSeen(track, p.Name)
				end
			end
		end
	end
end
table.insert(connections, RunService.Stepped:Connect(tickLoop))
table.insert(connections, RunService.RenderStepped:Connect(tickLoop))
