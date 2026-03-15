print("enjoy bacon logger, open source if u wanna check github, JOIN THE DISCORD")
local Services = {
	Players = game:GetService("Players"),
	UserInputService = game:GetService("UserInputService"),
	RunService = game:GetService("RunService"),
	HttpService = game:GetService("HttpService")
}
local wait = task and task.wait or wait
local spawn = task and task.spawn or spawn
local player = Services.Players.LocalPlayer
while not player do
	task.wait()
	player = Services.Players.LocalPlayer
end
local Data = {
	connections = {},
	animCounts = {},
	animFrames = {},
	banned = {},
	trueBanned = {},
	logBlacklist = {},  
	seenTracks = {},
	replacingTargets = {},
	scriptTracks = {},
	keybinds = {},
	replacements = {},
	favorites = {},
	customNames = {},
	favoriteEntries = {},
	bindIndicators = {},
	animTimestamps = {},
	keybindGroups = {},
	animLastFired = {},
	animFireIntervals = {},
	loopingAnims = {},
	ghostChar = nil,
	vpTrack = nil,
	vpAnimator = nil,
	vpRootPart = nil,
	vpScrubTrack = nil
}
local State = {
	replacementFrozen = false,
	looped = false,
	globalLogging = false,
	isFrozen = false,
	autoCopy = false,
	filterPlayer = "",
	filterPriority = "",
	configFile = "bacon_logger_config.json",
	keybindFile = "bacon_logger_binds.json",
	keybindGroupsFile = "bacon_logger_groups.json",
	toggleKey = Enum.KeyCode.RightControl,
	running = true,
	minimized = false,
	sideMinimized = false,
	vpMinimized = false,
	mainPaused = false,
	currentTab = "log",
	vpPaused = false,
	vpLastPos = 0,
	vpLoopFlash = 0,
	vpLooped = false,
	vpPausedAt = 0,
	vpPausedLength = 0,
	vpYaw = 0,
	vpZoomDist = 11,
	vpCurrentId = nil,
	vpSkinQuery = nil,  
	vpSkinCache = nil,  
	vpScrubbing = false,
	mainScrubbing = false,
	dragging = false,
	dragInput = nil,
	dragStart = nil,
	startPos = nil,
	resizing = false,
	resizeStart = nil,
	resizeStartSize = nil
}

local function dumpGroups()
	if writefile then
		writefile(State.keybindGroupsFile, Services.HttpService:JSONEncode(Data.keybindGroups))
	end
end
local function loadGroups()
	if readfile and isfile and isfile(State.keybindGroupsFile) then
		local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(State.keybindGroupsFile)) end)
		if ok and type(data) == "table" then Data.keybindGroups = data end
	end
end
local function dumpCfg()
	local data = {
		looped = State.looped,
		globalLogging = State.globalLogging,
		banned = Data.banned,
		trueBanned = Data.trueBanned,
		logBlacklist = Data.logBlacklist,  
		replacements = Data.replacements,
		favorites = Data.favorites,
		customNames = Data.customNames,
		autoCopy = State.autoCopy,
		toggleKey = State.toggleKey and State.toggleKey.Name or "RightControl"
	}
	if writefile then
		writefile(State.configFile, Services.HttpService:JSONEncode(data))
	end
end
local function dumpBinds()
	local data = {}
	for _, bind in pairs(Data.keybinds) do
		table.insert(data, {
			id = bind.id,
			key = bind.key and bind.key.Name or nil,
			hold = bind.hold or false,
			speed = bind.speed or 1,
			loop = bind.loop or false
		})
	end
	if writefile then
		writefile(State.keybindFile, Services.HttpService:JSONEncode(data))
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
	if Data.banned[id] then return nil end
	local animator = grabAnimator()
	if not animator or not id or id == "" then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. id
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = loop or false
	local playSpeed = speed or 1
	if State.isFrozen then playSpeed = 0 end
	Data.scriptTracks[track] = true
	track:Play(0, 1, playSpeed)
	local conn
	conn = track.Stopped:Connect(function()
		local intentional = not Data.scriptTracks[track]
		Data.scriptTracks[track] = nil
		if conn then
			for i, v in ipairs(Data.connections) do
				if v == conn then
					table.remove(Data.connections, i)
					break
				end
			end
			conn:Disconnect()
		end
		if loop and not Data.banned[id] and not intentional then
			local holdBindOwns = false
			for _, bind in pairs(Data.keybinds) do
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
	end)
	return track
end

local function killAnim(id)
	local animator = grabAnimator()
	if not animator then return end
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		local tid = grabId(track.Animation.AnimationId)
		if tid == id then
			Data.scriptTracks[track] = nil
			track:Stop()
		end
	end
end
local UI = {
	gui = Instance.new("ScreenGui"),
	notifLabel = Instance.new("TextLabel"),
	notifThread = nil,
	activeDragger = nil,
	mainFrame = nil,
	resizeHandle = nil,
	top = nil,
	title = nil,
	closeButton = nil,
	minimize = nil,
	openSide = nil,
	previewToggle = nil,
	searchBox = nil,
	playerFilterBox = nil,
	priorityFilterBox = nil,
	logTabBtn = nil,
	favsTabBtn = nil,
	bannedTabBtn = nil,
	logCountLabel = nil,
	list = nil,
	favsList = nil,
	bannedList = nil,
	controls = nil,
	idBox = nil,
	speedBox = nil,
	timeBox = nil,
	mainTimerLabel = nil,
	mainScrubBg = nil,
	mainScrubFill = nil,
	mainScrubBtn = nil,
	mainPauseBtn = nil,
	loopToggle = nil,
	globalToggle = nil,
	autoCopyToggle = nil,
	exportBtn = nil,
	toggleKeyBtn = nil,
	discordBtn = nil,
	sideFrame = nil,
	sideTitle = nil,
	sideList = nil,
	sideLayout = nil,
	groupNameBox = nil,
	saveGroupBtn = nil,
	loadGroupBtn = nil,
	groupDropdown = nil,
	addB = nil,
	addR = nil,
	sideClose = nil,
	sideMinimize = nil,
	cmdsBtn = nil,
	cmdsTooltip = nil,
	tooltipLabel = nil,
	viewportWin = nil,
	vpTop = nil,
	vpTitle = nil,
	vpClose = nil,
	vpMinimize = nil,
	vpIdInput = nil,
	vpIdGoBtn = nil,
	vpFrame = nil,
	vpCamera = nil,
	worldModel = nil,
	vpIdLabel = nil,
	vpTimerLabel = nil,
	vpScrubBg = nil,
	vpScrubFill = nil,
	vpScrubBtn = nil,
	vpPauseBtn = nil,
	vpSpeedBox = nil,
	vpLoopToggle = nil,
	vpTimeBox = nil,
	vpPlayBtn = nil,
	vpStopBtn = nil,
	vpPlaySelfBtn = nil,
	vpRotateCCW = nil,
	vpRotateCW = nil,
	vpPrecisionBox = nil,
	vpZoomIn = nil,
	vpZoomOut = nil
}
UI.gui.Name = "BaconLoggerGui"
UI.gui.ResetOnSpawn = false
UI.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
if success and coreGui then
	UI.gui.Parent = coreGui
else
	UI.gui.Parent = player:WaitForChild("PlayerGui")
end
table.insert(Data.connections, Services.UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == State.toggleKey then
		UI.gui.Enabled = not UI.gui.Enabled
	end
end))
UI.mainFrame = Instance.new("Frame")
UI.mainFrame.Name = "MainFrame"
UI.mainFrame.Size = UDim2.new(0, 820, 0, 630)
UI.mainFrame.Position = UDim2.new(0, 50, 0, 50)
UI.mainFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
UI.mainFrame.BorderSizePixel = 0
UI.mainFrame.BorderColor3 = Color3.fromRGB(0, 80, 80)
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = UI.mainFrame
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 90, 100)
	s.Thickness = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = UI.mainFrame
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

UI.notifLabel.Size = UDim2.new(0, 400, 0, 32)
UI.notifLabel.AnchorPoint = Vector2.new(0.5, 0)
UI.notifLabel.Position = UDim2.new(0.5, 0, 0, 8)
UI.notifLabel.BackgroundColor3 = Color3.fromRGB(80, 20, 10)
UI.notifLabel.BackgroundTransparency = 1
UI.notifLabel.TextColor3 = Color3.fromRGB(255, 120, 80)
UI.notifLabel.Font = Enum.Font.Code
UI.notifLabel.TextSize = 13
UI.notifLabel.Text = ""
UI.notifLabel.ZIndex = 100
UI.notifLabel.Visible = false
UI.notifLabel.Parent = UI.gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = UI.notifLabel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180, 60, 30); s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.notifLabel
end
local function flashNotif(msg)
	UI.notifLabel.Text = msg
	UI.notifLabel.BackgroundTransparency = 0
	UI.notifLabel.Visible = true
	if UI.notifThread then task.cancel(UI.notifThread) end
	UI.notifThread = task.delay(3, function()
		UI.notifLabel.Visible = false
		UI.notifLabel.Text = ""
	end)
end
UI.mainFrame.Active = true
UI.mainFrame.Draggable = false
UI.mainFrame.ClipsDescendants = false
UI.mainFrame.ZIndex = 1
UI.mainFrame.Parent = UI.gui

local function dragMain(input)
	local delta = input.Position - State.dragStart
	UI.mainFrame.Position = UDim2.new(State.startPos.X.Scale, State.startPos.X.Offset + delta.X, State.startPos.Y.Scale, State.startPos.Y.Offset + delta.Y)
end
table.insert(Data.connections, UI.mainFrame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UI.activeDragger then
		UI.activeDragger = "main"
		State.dragging = true
		State.dragStart = input.Position
		State.startPos = UI.mainFrame.Position
		table.insert(Data.connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				State.dragging = false
				if UI.activeDragger == "main" then UI.activeDragger = nil end
			end
		end))
	end
end))
table.insert(Data.connections, UI.mainFrame.InputChanged:Connect(function(input)
	if State.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		State.dragInput = input
	end
end))
table.insert(Data.connections, Services.UserInputService.InputChanged:Connect(function(input)
	if input == State.dragInput and State.dragging then dragMain(input) end
end))

UI.resizeHandle = Instance.new("TextButton")
UI.resizeHandle.Size = UDim2.new(0, 14, 0, 14)
UI.resizeHandle.Position = UDim2.new(1, -14, 1, -14)
UI.resizeHandle.BackgroundColor3 = Color3.fromRGB(0, 80, 90)
UI.resizeHandle.Text = ""
UI.resizeHandle.BorderSizePixel = 0
UI.resizeHandle.ZIndex = 10
UI.resizeHandle.Parent = UI.mainFrame
mkCorner(UI.resizeHandle, 3)
do
	local grip = Instance.new("TextLabel")
	grip.Text = "⠿"
	grip.Size = UDim2.new(1, 0, 1, 0)
	grip.BackgroundTransparency = 1
	grip.TextColor3 = Color3.fromRGB(0, 200, 160)
	grip.Font = Enum.Font.Code
	grip.TextSize = 11
	grip.ZIndex = 11
	grip.Parent = UI.resizeHandle
end
table.insert(Data.connections, UI.resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.resizing = true
		State.resizeStart = input.Position
		State.resizeStartSize = UI.mainFrame.AbsoluteSize
	end
end))
table.insert(Data.connections, Services.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.resizing = false
		UI.activeDragger = nil
	end
end))
table.insert(Data.connections, Services.UserInputService.InputChanged:Connect(function(input)
	if State.resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - State.resizeStart
		local newW = math.max(600, State.resizeStartSize.X + delta.X)
		local newH = math.max(400, State.resizeStartSize.Y + delta.Y)
		UI.mainFrame.Size = UDim2.new(0, newW, 0, newH)
	end
end))

UI.top = Instance.new("Frame")
UI.top.Name = "TopBar"
UI.top.Size = UDim2.new(1, 0, 0, 28)
UI.top.BackgroundColor3 = Color3.fromRGB(8, 28, 32)
UI.top.BorderSizePixel = 0
UI.top.ZIndex = 2
UI.top.Parent = UI.mainFrame
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 55, 65)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 25, 30)),
	})
	g.Rotation = 90
	g.Parent = UI.top
end
UI.title = Instance.new("TextLabel")
UI.title.Text = "⬡ bacon's advanced logger"
UI.title.Size = UDim2.new(1, -220, 1, 0)
UI.title.Position = UDim2.new(0, 10, 0, 0)
UI.title.BackgroundTransparency = 1
UI.title.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.title.Font = Enum.Font.Code
UI.title.TextSize = 13
UI.title.TextXAlignment = Enum.TextXAlignment.Left
UI.title.ZIndex = 3
UI.title.Parent = UI.top
UI.closeButton = Instance.new("TextButton")
UI.closeButton.Size = UDim2.new(0, 26, 0, 20)
UI.closeButton.Position = UDim2.new(1, -28, 0, 4)
UI.closeButton.Text = "X"
UI.closeButton.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
UI.closeButton.TextColor3 = Color3.new(1, 1, 1)
UI.closeButton.BorderSizePixel = 0
UI.closeButton.Font = Enum.Font.Code
UI.closeButton.TextSize = 12
UI.closeButton.ZIndex = 3
UI.closeButton.Parent = UI.top
mkCorner(UI.closeButton, 4)
UI.minimize = Instance.new("TextButton")
UI.minimize.Size = UDim2.new(0, 26, 0, 20)
UI.minimize.Position = UDim2.new(1, -56, 0, 4)
UI.minimize.Text = "-"
UI.minimize.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
UI.minimize.TextColor3 = Color3.new(1, 1, 1)
UI.minimize.BorderSizePixel = 0
UI.minimize.Font = Enum.Font.Code
UI.minimize.TextSize = 12
UI.minimize.ZIndex = 3
UI.minimize.Parent = UI.top
mkCorner(UI.minimize, 4)
UI.openSide = Instance.new("TextButton")
UI.openSide.Size = UDim2.new(0, 52, 0, 20)
UI.openSide.Position = UDim2.new(1, -110, 0, 4)
UI.openSide.Text = "Binds"
UI.openSide.BackgroundColor3 = Color3.fromRGB(0, 75, 85)
UI.openSide.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.openSide.BorderSizePixel = 0
UI.openSide.Font = Enum.Font.Code
UI.openSide.TextSize = 12
UI.openSide.ZIndex = 3
UI.openSide.Parent = UI.top
mkCorner(UI.openSide, 4)
UI.previewToggle = Instance.new("TextButton")
UI.previewToggle.Size = UDim2.new(0, 60, 0, 20)
UI.previewToggle.Position = UDim2.new(1, -174, 0, 4)
UI.previewToggle.Text = "Preview"
UI.previewToggle.BackgroundColor3 = Color3.fromRGB(0, 55, 80)
UI.previewToggle.TextColor3 = Color3.fromRGB(0, 200, 220)
UI.previewToggle.BorderSizePixel = 0
UI.previewToggle.Font = Enum.Font.Code
UI.previewToggle.TextSize = 12
UI.previewToggle.ZIndex = 3
UI.previewToggle.Parent = UI.top
mkCorner(UI.previewToggle, 4)
UI.searchBox = Instance.new("TextBox")
UI.searchBox.Text = ""
UI.searchBox.Name = "SearchBox"
UI.searchBox.PlaceholderText = "Search animations..."
UI.searchBox.Position = UDim2.new(0, 6, 0, 32)
UI.searchBox.Size = UDim2.new(0.60, -12, 0, 22)
UI.searchBox.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
UI.searchBox.TextColor3 = Color3.new(1, 1, 1)
UI.searchBox.PlaceholderColor3 = Color3.fromRGB(0, 100, 90)
UI.searchBox.BorderSizePixel = 0
UI.searchBox.Font = Enum.Font.Code
UI.searchBox.TextSize = 12
UI.searchBox.ZIndex = 2
UI.searchBox.Parent = UI.mainFrame
mkCorner(UI.searchBox, 4)
mkStroke(UI.searchBox, Color3.fromRGB(0, 80, 90), 1)
UI.playerFilterBox = Instance.new("TextBox")
UI.playerFilterBox.Text = ""
UI.playerFilterBox.Name = "PlayerFilter"
UI.playerFilterBox.PlaceholderText = "Filter player..."
UI.playerFilterBox.Position = UDim2.new(0, 5, 0, 55)
UI.playerFilterBox.Size = UDim2.new(0.30, -5, 0, 20)
UI.playerFilterBox.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
UI.playerFilterBox.TextColor3 = Color3.new(1, 1, 1)
UI.playerFilterBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 0)
UI.playerFilterBox.BorderSizePixel = 0
UI.playerFilterBox.Font = Enum.Font.Code
UI.playerFilterBox.TextSize = 12
UI.playerFilterBox.ZIndex = 2
UI.playerFilterBox.Parent = UI.mainFrame
UI.priorityFilterBox = Instance.new("TextBox")
UI.priorityFilterBox.Text = ""
UI.priorityFilterBox.Name = "PriorityFilter"
UI.priorityFilterBox.PlaceholderText = "Filter priority..."
UI.priorityFilterBox.Position = UDim2.new(0.30, 5, 0, 55)
UI.priorityFilterBox.Size = UDim2.new(0.30, -10, 0, 20)
UI.priorityFilterBox.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
UI.priorityFilterBox.TextColor3 = Color3.new(1, 1, 1)
UI.priorityFilterBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 0)
UI.priorityFilterBox.BorderSizePixel = 0
UI.priorityFilterBox.Font = Enum.Font.Code
UI.priorityFilterBox.TextSize = 12
UI.priorityFilterBox.ZIndex = 2
UI.priorityFilterBox.Parent = UI.mainFrame
mkCorner(UI.playerFilterBox, 4)
mkStroke(UI.playerFilterBox, Color3.fromRGB(80, 80, 0), 1)
mkCorner(UI.priorityFilterBox, 4)
mkStroke(UI.priorityFilterBox, Color3.fromRGB(80, 80, 0), 1)
UI.logTabBtn = Instance.new("TextButton")
UI.logTabBtn.Text = "[ Log ]"
UI.logTabBtn.Position = UDim2.new(0, 5, 0, 78)
UI.logTabBtn.Size = UDim2.new(0.20, -4, 0, 18)
UI.logTabBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 70)
UI.logTabBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.logTabBtn.Font = Enum.Font.Code
UI.logTabBtn.TextSize = 12
UI.logTabBtn.BorderSizePixel = 0
UI.logTabBtn.ZIndex = 2
UI.logTabBtn.Parent = UI.mainFrame
mkCorner(UI.logTabBtn, 4)
UI.favsTabBtn = Instance.new("TextButton")
UI.favsTabBtn.Text = "[ Favs ]"
UI.favsTabBtn.Position = UDim2.new(0.20, 2, 0, 78)
UI.favsTabBtn.Size = UDim2.new(0.20, -4, 0, 18)
UI.favsTabBtn.BackgroundColor3 = Color3.fromRGB(40, 38, 0)
UI.favsTabBtn.TextColor3 = Color3.fromRGB(220, 210, 0)
UI.favsTabBtn.Font = Enum.Font.Code
UI.favsTabBtn.TextSize = 12
UI.favsTabBtn.BorderSizePixel = 0
UI.favsTabBtn.ZIndex = 2
UI.favsTabBtn.Parent = UI.mainFrame
mkCorner(UI.favsTabBtn, 4)
UI.bannedTabBtn = Instance.new("TextButton")
UI.bannedTabBtn.Text = "[ Banned ]"
UI.bannedTabBtn.Position = UDim2.new(0.40, 2, 0, 78)
UI.bannedTabBtn.Size = UDim2.new(0.20, -6, 0, 18)
UI.bannedTabBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
UI.bannedTabBtn.TextColor3 = Color3.fromRGB(255, 120, 100)
UI.bannedTabBtn.Font = Enum.Font.Code
UI.bannedTabBtn.TextSize = 12
UI.bannedTabBtn.BorderSizePixel = 0
UI.bannedTabBtn.ZIndex = 2
UI.bannedTabBtn.Parent = UI.mainFrame
mkCorner(UI.bannedTabBtn, 4)

UI.logCountLabel = Instance.new("TextLabel")
UI.logCountLabel.Text = "0 logged"
UI.logCountLabel.Position = UDim2.new(0.60, -92, 0, 32)
UI.logCountLabel.Size = UDim2.new(0, 88, 0, 22)
UI.logCountLabel.BackgroundTransparency = 1
UI.logCountLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
UI.logCountLabel.TextXAlignment = Enum.TextXAlignment.Right
UI.logCountLabel.Font = Enum.Font.Code
UI.logCountLabel.TextSize = 11
UI.logCountLabel.ZIndex = 2
UI.logCountLabel.Parent = UI.mainFrame
UI.list = Instance.new("ScrollingFrame")
UI.list.Name = "AnimList"
UI.list.Position = UDim2.new(0, 5, 0, 100)
UI.list.Size = UDim2.new(0.60, -10, 1, -105)
UI.list.BackgroundColor3 = Color3.fromRGB(14, 17, 22)
UI.list.BorderSizePixel = 0
UI.list.ScrollBarThickness = 4
UI.list.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 150)
UI.list.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.list.ClipsDescendants = true
UI.list.ZIndex = 2
UI.list.Visible = true
UI.list.Parent = UI.mainFrame
mkCorner(UI.list, 4)
mkStroke(UI.list, Color3.fromRGB(0, 65, 75), 1)
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 1)
	layout.Parent = UI.list
	local conn
	conn = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		UI.list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end)
	table.insert(Data.connections, conn)
end
UI.favsList = Instance.new("ScrollingFrame")
UI.favsList.Name = "FavsList"
UI.favsList.Position = UDim2.new(0, 5, 0, 100)
UI.favsList.Size = UDim2.new(0.60, -10, 1, -105)
UI.favsList.BackgroundColor3 = Color3.fromRGB(16, 15, 10)
UI.favsList.BorderSizePixel = 0
UI.favsList.ScrollBarThickness = 4
UI.favsList.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 0)
UI.favsList.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.favsList.ClipsDescendants = true
UI.favsList.ZIndex = 2
UI.favsList.Visible = false
UI.favsList.Parent = UI.mainFrame
mkCorner(UI.favsList, 4)
mkStroke(UI.favsList, Color3.fromRGB(80, 75, 0), 1)
do
	local favsLayout = Instance.new("UIListLayout")
	favsLayout.Padding = UDim.new(0, 2)
	favsLayout.Parent = UI.favsList
	local conn
	conn = favsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		UI.favsList.CanvasSize = UDim2.new(0, 0, 0, favsLayout.AbsoluteContentSize.Y)
	end)
	table.insert(Data.connections, conn)
end
UI.bannedList = Instance.new("ScrollingFrame")
UI.bannedList.Name = "BannedList"
UI.bannedList.Position = UDim2.new(0, 5, 0, 100)
UI.bannedList.Size = UDim2.new(0.60, -10, 1, -105)
UI.bannedList.BackgroundColor3 = Color3.fromRGB(18, 10, 10)
UI.bannedList.BorderSizePixel = 0
UI.bannedList.ScrollBarThickness = 4
UI.bannedList.ScrollBarImageColor3 = Color3.fromRGB(200, 80, 80)
UI.bannedList.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.bannedList.ClipsDescendants = true
UI.bannedList.ZIndex = 2
UI.bannedList.Visible = false
UI.bannedList.Parent = UI.mainFrame
mkCorner(UI.bannedList, 4)
mkStroke(UI.bannedList, Color3.fromRGB(100, 30, 30), 1)
do
	local bannedLayout = Instance.new("UIListLayout")
	bannedLayout.Padding = UDim.new(0, 2)
	bannedLayout.Parent = UI.bannedList
	local conn
	conn = bannedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		UI.bannedList.CanvasSize = UDim2.new(0, 0, 0, bannedLayout.AbsoluteContentSize.Y)
	end)
	table.insert(Data.connections, conn)
end
local function rebuildBannedList()
	for _, child in ipairs(UI.bannedList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	for id, isBanned in pairs(Data.banned) do
		if isBanned then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -5, 0, 22)
			row.BackgroundTransparency = 1
			row.ZIndex = 3
			row.Parent = UI.bannedList
			local label = Instance.new("TextButton")
			label.Size = UDim2.new(1, -80, 1, 0)
			label.BackgroundColor3 = Color3.fromRGB(30, 12, 12)
			label.TextColor3 = Color3.fromRGB(255, 100, 80)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = (Data.trueBanned[id] and "⬛ " or "") .. id
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
			table.insert(Data.connections, label.MouseButton1Click:Connect(function()
				UI.idBox.Text = id
			end))
			table.insert(Data.connections, copyBtn.MouseButton1Click:Connect(function()
				yoink(id)
			end))
			table.insert(Data.connections, unbanBtn.MouseButton1Click:Connect(function()
				Data.banned[id] = nil
				Data.trueBanned[id] = nil
				dumpCfg()
				row:Destroy()
			end))
		end
	end
	
	for id, isLogBanned in pairs(Data.logBlacklist) do
		if isLogBanned then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -5, 0, 22)
			row.BackgroundTransparency = 1
			row.ZIndex = 3
			row.Parent = UI.bannedList
			local label = Instance.new("TextButton")
			label.Size = UDim2.new(1, -80, 1, 0)
			label.BackgroundColor3 = Color3.fromRGB(22, 12, 32)
			label.TextColor3 = Color3.fromRGB(190, 130, 255)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = "◈ " .. id
			label.Font = Enum.Font.Code
			label.TextSize = 11
			label.BorderSizePixel = 0
			label.ZIndex = 4
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = row
			mkCorner(label, 3)
			mkStroke(label, Color3.fromRGB(90, 40, 140), 1)
			local copyBtn = Instance.new("TextButton")
			copyBtn.Size = UDim2.new(0, 46, 1, 0)
			copyBtn.Position = UDim2.new(1, -80, 0, 0)
			copyBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
			copyBtn.TextColor3 = Color3.fromRGB(200, 160, 255)
			copyBtn.Text = "Copy"
			copyBtn.Font = Enum.Font.Code
			copyBtn.TextSize = 10
			copyBtn.BorderSizePixel = 0
			copyBtn.ZIndex = 4
			copyBtn.Parent = row
			mkCorner(copyBtn, 3)
			local unlogbanBtn = Instance.new("TextButton")
			unlogbanBtn.Size = UDim2.new(0, 46, 1, 0)
			unlogbanBtn.Position = UDim2.new(1, -30, 0, 0)
			unlogbanBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 70)
			unlogbanBtn.TextColor3 = Color3.fromRGB(210, 170, 255)
			unlogbanBtn.Text = "Remove"
			unlogbanBtn.Font = Enum.Font.Code
			unlogbanBtn.TextSize = 9
			unlogbanBtn.BorderSizePixel = 0
			unlogbanBtn.ZIndex = 4
			unlogbanBtn.Parent = row
			mkCorner(unlogbanBtn, 3)
			table.insert(Data.connections, label.MouseButton1Click:Connect(function()
				UI.idBox.Text = id
			end))
			table.insert(Data.connections, copyBtn.MouseButton1Click:Connect(function()
				yoink(id)
			end))
			table.insert(Data.connections, unlogbanBtn.MouseButton1Click:Connect(function()
				Data.logBlacklist[id] = nil
				dumpCfg()
				row:Destroy()
			end))
		end
	end
end
local function switchTab(tab)
	State.currentTab = tab
	UI.list.Visible = (tab == "log")
	UI.favsList.Visible = (tab == "favs")
	UI.bannedList.Visible = (tab == "banned")
	if tab == "banned" then rebuildBannedList() end
	UI.logTabBtn.BackgroundColor3 = (tab == "log") and Color3.fromRGB(0, 80, 90) or Color3.fromRGB(0, 35, 40)
	UI.favsTabBtn.BackgroundColor3 = (tab == "favs") and Color3.fromRGB(80, 76, 0) or Color3.fromRGB(35, 33, 0)
	UI.bannedTabBtn.BackgroundColor3 = (tab == "banned") and Color3.fromRGB(100, 20, 20) or Color3.fromRGB(50, 10, 10)
end
table.insert(Data.connections, UI.logTabBtn.MouseButton1Click:Connect(function() switchTab("log") end))
table.insert(Data.connections, UI.favsTabBtn.MouseButton1Click:Connect(function() switchTab("favs") end))
table.insert(Data.connections, UI.bannedTabBtn.MouseButton1Click:Connect(function() switchTab("banned") end))
UI.controls = Instance.new("ScrollingFrame")
UI.controls.Name = "Controls"
UI.controls.Position = UDim2.new(0.60, 5, 0, 30)
UI.controls.Size = UDim2.new(0.40, -10, 1, -35)
UI.controls.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
UI.controls.BorderSizePixel = 0
UI.controls.ClipsDescendants = true
UI.controls.ScrollBarThickness = 3
UI.controls.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 130)
UI.controls.CanvasSize = UDim2.new(0, 0, 0, 820)  
UI.controls.ZIndex = 2
UI.controls.Visible = true
UI.controls.Parent = UI.mainFrame
mkCorner(UI.controls, 5)
mkStroke(UI.controls, Color3.fromRGB(0, 65, 75), 1)
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
	l.Parent = UI.controls
end
mkLabel("Animation ID", 10)
UI.idBox = Instance.new("TextBox")
UI.idBox.Text = ""
UI.idBox.Position = UDim2.new(0, 10, 0, 30)
UI.idBox.Size = UDim2.new(1, -20, 0, 25)
UI.idBox.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
UI.idBox.TextColor3 = Color3.new(1, 1, 1)
UI.idBox.PlaceholderColor3 = Color3.fromRGB(0, 100, 80)
UI.idBox.PlaceholderText = "animation id..."
UI.idBox.BorderSizePixel = 0
UI.idBox.ZIndex = 3
UI.idBox.Visible = true
UI.idBox.Parent = UI.controls
mkCorner(UI.idBox, 4)
mkStroke(UI.idBox, Color3.fromRGB(0, 90, 100), 1)
mkLabel("Speed", 65)
UI.speedBox = Instance.new("TextBox")
UI.speedBox.Text = "1"
UI.speedBox.PlaceholderText = "speed (1 = normal)"
UI.speedBox.Position = UDim2.new(0, 10, 0, 85)
UI.speedBox.Size = UDim2.new(1, -20, 0, 25)
UI.speedBox.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
UI.speedBox.TextColor3 = Color3.new(1, 1, 1)
UI.speedBox.BorderSizePixel = 0
UI.speedBox.ZIndex = 3
UI.speedBox.Visible = true
UI.speedBox.Parent = UI.controls
mkCorner(UI.speedBox, 4)
mkStroke(UI.speedBox, Color3.fromRGB(0, 90, 100), 1)
mkLabel("Time (Scrub)", 120)
UI.timeBox = Instance.new("TextBox")
UI.timeBox.Text = "0"
UI.timeBox.PlaceholderText = "scrub time (secs)"
UI.timeBox.Position = UDim2.new(0, 10, 0, 140)
UI.timeBox.Size = UDim2.new(1, -20, 0, 25)
UI.timeBox.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
UI.timeBox.TextColor3 = Color3.new(1, 1, 1)
UI.timeBox.BorderSizePixel = 0
UI.timeBox.ZIndex = 3
UI.timeBox.Visible = true
UI.timeBox.Parent = UI.controls
mkCorner(UI.timeBox, 4)
mkStroke(UI.timeBox, Color3.fromRGB(0, 90, 100), 1)
table.insert(Data.connections, UI.timeBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(UI.timeBox.Text:match("[%d%.]+"))
	if num then
		for track in pairs(Data.scriptTracks) do
			if track.IsPlaying then
				track.TimePosition = math.clamp(num, 0, track.Length)
			end
		end
	end
end))

UI.mainTimerLabel = Instance.new("TextLabel")
UI.mainTimerLabel.Text = "no anim playing"
UI.mainTimerLabel.Position = UDim2.new(0, 10, 0, 168)
UI.mainTimerLabel.Size = UDim2.new(1, -20, 0, 14)
UI.mainTimerLabel.BackgroundTransparency = 1
UI.mainTimerLabel.TextColor3 = Color3.fromRGB(0, 160, 120)
UI.mainTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.mainTimerLabel.Font = Enum.Font.Code
UI.mainTimerLabel.TextSize = 11
UI.mainTimerLabel.ZIndex = 3
UI.mainTimerLabel.Visible = true
UI.mainTimerLabel.Parent = UI.controls

UI.mainScrubBg = Instance.new("Frame")
UI.mainScrubBg.Position = UDim2.new(0, 10, 0, 185)
UI.mainScrubBg.Size = UDim2.new(1, -20, 0, 12)
UI.mainScrubBg.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
UI.mainScrubBg.BorderSizePixel = 0
UI.mainScrubBg.ZIndex = 3
UI.mainScrubBg.Parent = UI.controls
mkCorner(UI.mainScrubBg, 6)

UI.mainScrubFill = Instance.new("Frame")
UI.mainScrubFill.Size = UDim2.new(0, 0, 1, 0)
UI.mainScrubFill.BackgroundColor3 = Color3.fromRGB(0, 210, 160)
UI.mainScrubFill.BorderSizePixel = 0
UI.mainScrubFill.ZIndex = 4
UI.mainScrubFill.Parent = UI.mainScrubBg

UI.mainScrubBtn = Instance.new("TextButton")
UI.mainScrubBtn.Size = UDim2.new(1, 0, 1, 0)
UI.mainScrubBtn.BackgroundTransparency = 1
UI.mainScrubBtn.Text = ""
UI.mainScrubBtn.ZIndex = 5
UI.mainScrubBtn.Parent = UI.mainScrubBg

State.mainPaused = false
UI.mainPauseBtn = Instance.new("TextButton")
UI.mainPauseBtn.Text = "⏸ Pause"
UI.mainPauseBtn.Position = UDim2.new(0, 10, 0, 196)
UI.mainPauseBtn.Size = UDim2.new(1, -20, 0, 20)
UI.mainPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 55, 70)
UI.mainPauseBtn.TextColor3 = Color3.new(1, 1, 1)
UI.mainPauseBtn.BorderSizePixel = 0
UI.mainPauseBtn.Font = Enum.Font.Code
UI.mainPauseBtn.TextSize = 11
UI.mainPauseBtn.ZIndex = 3
UI.mainPauseBtn.Parent = UI.controls
mkCorner(UI.mainPauseBtn, 4)
mkStroke(UI.mainPauseBtn, Color3.fromRGB(0, 110, 130), 1)

table.insert(Data.connections, UI.mainPauseBtn.MouseButton1Click:Connect(function()
	State.mainPaused = not State.mainPaused
	for track in pairs(Data.scriptTracks) do
		if State.mainPaused then
			track:AdjustSpeed(0)
		else
			track:AdjustSpeed(tonumber(UI.speedBox.Text) or 1)
		end
	end
	UI.mainPauseBtn.Text = State.mainPaused and "▶ Resume" or "⏸ Pause"
	UI.mainPauseBtn.BackgroundColor3 = State.mainPaused and Color3.fromRGB(0, 80, 0) or Color3.fromRGB(0, 50, 60)
end))

table.insert(Data.connections, UI.mainScrubBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.mainScrubbing = true
	end
end))
table.insert(Data.connections, UI.mainScrubBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.mainScrubbing = false
	end
end))

UI.loopToggle = Instance.new("TextButton")
UI.loopToggle.Text = "Loop: OFF"
UI.loopToggle.Position = UDim2.new(0, 10, 0, 220)
UI.loopToggle.Size = UDim2.new(1, -20, 0, 25)
UI.loopToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
UI.loopToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
UI.loopToggle.BorderSizePixel = 0
UI.loopToggle.ZIndex = 3
UI.loopToggle.Visible = true
UI.loopToggle.Parent = UI.controls
mkCorner(UI.loopToggle, 4)
mkStroke(UI.loopToggle, Color3.fromRGB(120, 0, 0), 1)
local function refreshLoopBtn()
	UI.loopToggle.Text = "Loop: " .. (State.looped and "ON" or "OFF")
	UI.loopToggle.BackgroundColor3 = State.looped and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
	UI.loopToggle.TextColor3 = State.looped and Color3.fromRGB(160, 255, 180) or Color3.fromRGB(255, 180, 160)
end
table.insert(Data.connections, UI.loopToggle.MouseButton1Click:Connect(function()
	State.looped = not State.looped
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
	b.Parent = UI.controls
	mkCorner(b, 4)
	mkStroke(b, borderColor or Color3.fromRGB(0, 110, 120), 1)
	table.insert(Data.connections, b.MouseButton1Click:Connect(callback))
end
button("Play", 255, function()
	local id = UI.idBox.Text
	local speed = tonumber(UI.speedBox.Text) or 1
	local scrub = tonumber(UI.timeBox.Text) or 0
	local track = fireAnim(id, speed, State.looped)
	if track and scrub > 0 then
		task.defer(function()
			if track then
				track.TimePosition = math.clamp(scrub, 0, track.Length)
			end
		end)
	end
end)
button("Stop", 290, function()
	killAnim(UI.idBox.Text)
end, Color3.fromRGB(80, 20, 20), Color3.fromRGB(160, 40, 40))
button("Stop All", 325, function()
	local animator = grabAnimator()
	if animator then
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			Data.scriptTracks[track] = nil
			track:Stop()
		end
	end
	Data.scriptTracks = {}
end, Color3.fromRGB(80, 20, 20), Color3.fromRGB(160, 40, 40))
button("Ban", 360, function()
	Data.banned[UI.idBox.Text] = true
	killAnim(UI.idBox.Text)
	dumpCfg()
end, Color3.fromRGB(80, 20, 20), Color3.fromRGB(160, 40, 40))
button("True Ban", 395, function()
	local id = UI.idBox.Text
	if id == "" then return end
	Data.trueBanned[id] = true
	Data.banned[id] = true
	killAnim(id)
	dumpCfg()
	refreshColors()
end, Color3.fromRGB(100, 0, 0), Color3.fromRGB(200, 0, 0))
button("Unban", 430, function()
	local id = UI.idBox.Text
	Data.banned[id] = nil
	Data.trueBanned[id] = nil
	dumpCfg()
	refreshColors()
end, Color3.fromRGB(70, 45, 0), Color3.fromRGB(140, 90, 0))


button("Log Ban", 465, function()
	local id = UI.idBox.Text
	if id == "" then return end
	Data.logBlacklist[id] = true
	dumpCfg()
	refreshColors()
	flashNotif("◈ Log-banned " .. id .. " (still plays)")
end, Color3.fromRGB(50, 15, 80), Color3.fromRGB(130, 50, 200))


button("Log Unban", 500, function()
	local id = UI.idBox.Text
	if id == "" then return end
	Data.logBlacklist[id] = nil
	dumpCfg()
	refreshColors()
	flashNotif("◈ Log-unban " .. id)
end, Color3.fromRGB(35, 10, 55), Color3.fromRGB(100, 40, 160))

button("Copy ID", 535, function()
	yoink(UI.idBox.Text)
end, Color3.fromRGB(0, 40, 80), Color3.fromRGB(0, 80, 160))
local function nukeList()
	for id, entry in pairs(Data.animFrames) do
		if entry.Parent and entry.Parent:IsA("Frame") then
			entry.Parent:Destroy()
		else
			entry:Destroy()
		end
	end
	Data.animCounts = {}
	Data.animFrames = {}
	Data.seenTracks = {}
	UI.logCountLabel.Text = "0 logged"
	Data.animLastFired = {}
	Data.animFireIntervals = {}
	Data.loopingAnims = {}
end
button("Clear List", 570, nukeList)
UI.globalToggle = Instance.new("TextButton")
UI.globalToggle.Text = "Global Log: OFF"
UI.globalToggle.Position = UDim2.new(0, 10, 0, 597)
UI.globalToggle.Size = UDim2.new(1, -20, 0, 25)
UI.globalToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
UI.globalToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
UI.globalToggle.BorderSizePixel = 0
UI.globalToggle.ZIndex = 3
UI.globalToggle.Visible = true
UI.globalToggle.Parent = UI.controls
mkCorner(UI.globalToggle, 4)
mkStroke(UI.globalToggle, Color3.fromRGB(110, 0, 0), 1)
local function refreshGlobalBtn()
	UI.globalToggle.Text = "Global Log: " .. (State.globalLogging and "ON" or "OFF")
	UI.globalToggle.BackgroundColor3 = State.globalLogging and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
end
table.insert(Data.connections, UI.globalToggle.MouseButton1Click:Connect(function()
	State.globalLogging = not State.globalLogging
	refreshGlobalBtn()
	dumpCfg()
end))
UI.autoCopyToggle = Instance.new("TextButton")
UI.autoCopyToggle.Text = "Auto-Copy: OFF"
UI.autoCopyToggle.Position = UDim2.new(0, 10, 0, 625)
UI.autoCopyToggle.Size = UDim2.new(1, -20, 0, 22)
UI.autoCopyToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
UI.autoCopyToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
UI.autoCopyToggle.BorderSizePixel = 0
UI.autoCopyToggle.ZIndex = 3
UI.autoCopyToggle.Visible = true
UI.autoCopyToggle.Parent = UI.controls
mkCorner(UI.autoCopyToggle, 4)
mkStroke(UI.autoCopyToggle, Color3.fromRGB(110, 0, 0), 1)
local function refreshAutoCopyBtn()
	UI.autoCopyToggle.Text = "Auto-Copy: " .. (State.autoCopy and "ON" or "OFF")
	UI.autoCopyToggle.BackgroundColor3 = State.autoCopy and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
end
table.insert(Data.connections, UI.autoCopyToggle.MouseButton1Click:Connect(function()
	State.autoCopy = not State.autoCopy
	refreshAutoCopyBtn()
	dumpCfg()
end))
UI.exportBtn = Instance.new("TextButton")
UI.exportBtn.Text = "Export Log"
UI.exportBtn.Position = UDim2.new(0, 10, 0, 651)
UI.exportBtn.Size = UDim2.new(1, -20, 0, 22)
UI.exportBtn.BackgroundColor3 = Color3.fromRGB(0, 38, 75)
UI.exportBtn.TextColor3 = Color3.fromRGB(160, 200, 255)
UI.exportBtn.BorderSizePixel = 0
UI.exportBtn.ZIndex = 3
UI.exportBtn.Visible = true
UI.exportBtn.Parent = UI.controls
mkCorner(UI.exportBtn, 4)
mkStroke(UI.exportBtn, Color3.fromRGB(0, 75, 150), 1)

UI.toggleKeyBtn = Instance.new("TextButton")
UI.toggleKeyBtn.Text = "Hide Key: " .. State.toggleKey.Name
UI.toggleKeyBtn.Position = UDim2.new(0, 10, 0, 686)
UI.toggleKeyBtn.Size = UDim2.new(1, -20, 0, 26)
UI.toggleKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
UI.toggleKeyBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
UI.toggleKeyBtn.BorderSizePixel = 0
UI.toggleKeyBtn.Font = Enum.Font.Code
UI.toggleKeyBtn.TextSize = 12
UI.toggleKeyBtn.ZIndex = 3
UI.toggleKeyBtn.Visible = true
UI.toggleKeyBtn.Parent = UI.controls
mkCorner(UI.toggleKeyBtn, 4)
mkStroke(UI.toggleKeyBtn, Color3.fromRGB(90, 60, 180), 1)

table.insert(Data.connections, UI.toggleKeyBtn.MouseButton1Click:Connect(function()
	if State.settingToggleKey then return end
	State.settingToggleKey = true
	UI.toggleKeyBtn.Text = "Press any key..."
	UI.toggleKeyBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
	local conn
	conn = Services.UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			conn:Disconnect()
			State.settingToggleKey = false
			State.toggleKey = input.KeyCode
			UI.toggleKeyBtn.Text = "Hide Key: " .. State.toggleKey.Name
			UI.toggleKeyBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
			dumpCfg()
		end
	end)
end))
table.insert(Data.connections, UI.exportBtn.MouseButton1Click:Connect(function()
	local out = {}
	for key, entry in pairs(Data.animFrames) do
		local pureId = key:match("^([%d]+)")
		table.insert(out, {
			id = pureId,
			key = key,
			name = entry.Text,
			count = Data.animCounts[key] or 1,
			lastSeen = Data.animTimestamps[key] or "?",
			favorited = Data.favorites[pureId] or false,
			customName = Data.customNames[pureId] or nil,
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
		UI.exportBtn.Text = "Exported!"
		UI.exportBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
		task.delay(2, function()
			UI.exportBtn.Text = "Export Log"
			UI.exportBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
		end)
	else
		yoink(json)
		UI.exportBtn.Text = "Copied!"
		UI.exportBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
		task.delay(2, function()
			UI.exportBtn.Text = "Export Log"
			UI.exportBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
		end)
	end
end))
UI.discordBtn = Instance.new("TextButton")
UI.discordBtn.Text = "discord"
UI.discordBtn.Size = UDim2.new(0, 70, 0, 18)
UI.discordBtn.Position = UDim2.new(0, 6, 1, -22)
UI.discordBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 80)
UI.discordBtn.TextColor3 = Color3.fromRGB(140, 160, 255)
UI.discordBtn.BorderSizePixel = 0
UI.discordBtn.Font = Enum.Font.Code
UI.discordBtn.TextSize = 10
UI.discordBtn.ZIndex = 3
UI.discordBtn.Parent = UI.mainFrame
mkCorner(UI.discordBtn, 4)
mkStroke(UI.discordBtn, Color3.fromRGB(60, 80, 200), 1)
table.insert(Data.connections, UI.discordBtn.MouseButton1Click:Connect(function()
	yoink("discord.gg/u8FTncR4dF")
	UI.discordBtn.Text = "copied!"
	UI.discordBtn.TextColor3 = Color3.fromRGB(160, 255, 180)
	task.delay(2, function()
		UI.discordBtn.Text = "discord"
		UI.discordBtn.TextColor3 = Color3.fromRGB(140, 160, 255)
	end)
end))

table.insert(Data.connections, UI.minimize.MouseButton1Click:Connect(function()
	State.minimized = not State.minimized
	if State.minimized then
		UI.mainFrame.Size = UDim2.new(0, 460, 0, 28)
		UI.list.Visible = false
		UI.favsList.Visible = false
		UI.bannedList.Visible = false
		UI.controls.Visible = false
		UI.searchBox.Visible = false
		UI.playerFilterBox.Visible = false
		UI.priorityFilterBox.Visible = false
		UI.logTabBtn.Visible = false
		UI.favsTabBtn.Visible = false
		UI.bannedTabBtn.Visible = false
		UI.logCountLabel.Visible = false
		UI.resizeHandle.Visible = false
		UI.discordBtn.Visible = false
		UI.minimize.Text = "+"
	else
		UI.mainFrame.Size = UDim2.new(0, 820, 0, 630)
		UI.list.Visible = (State.currentTab == "log")
		UI.favsList.Visible = (State.currentTab == "favs")
		UI.bannedList.Visible = (State.currentTab == "banned")
		UI.controls.Visible = true
		UI.searchBox.Visible = true
		UI.playerFilterBox.Visible = true
		UI.priorityFilterBox.Visible = true
		UI.logTabBtn.Visible = true
		UI.favsTabBtn.Visible = true
		UI.bannedTabBtn.Visible = true
		UI.logCountLabel.Visible = true
		UI.resizeHandle.Visible = true
		UI.discordBtn.Visible = true
		UI.minimize.Text = "-"
	end
end))

table.insert(Data.connections, UI.closeButton.MouseButton1Click:Connect(function()
	State.running = false
	for _, connection in pairs(Data.connections) do
		connection:Disconnect()
	end
	UI.gui:Destroy()
end))
local function doFilter()
	local query = UI.searchBox.Text:lower()
	local pf = UI.playerFilterBox.Text:lower()
	local priF = UI.priorityFilterBox.Text:lower()
	for id, entry in pairs(Data.animFrames) do
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
table.insert(Data.connections, UI.searchBox:GetPropertyChangedSignal("Text"):Connect(doFilter))
table.insert(Data.connections, UI.playerFilterBox:GetPropertyChangedSignal("Text"):Connect(doFilter))
table.insert(Data.connections, UI.priorityFilterBox:GetPropertyChangedSignal("Text"):Connect(doFilter))
UI.sideFrame = Instance.new("Frame")
UI.sideFrame.Name = "SideFrame"
UI.sideFrame.Size = UDim2.new(0, 200, 0, 480)
UI.sideFrame.Position = UDim2.new(0, 655, 0, 50)
UI.sideFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
UI.sideFrame.BorderSizePixel = 0
UI.sideFrame.Active = true
UI.sideFrame.ClipsDescendants = true
UI.sideFrame.ZIndex = 1
UI.sideFrame.Visible = false
UI.sideFrame.Parent = UI.gui
mkCorner(UI.sideFrame, 6)
mkStroke(UI.sideFrame, Color3.fromRGB(0, 90, 100), 1)
local function dragSide(input)
	local delta = input.Position - State.dragStartSide
	UI.sideFrame.Position = UDim2.new(State.startPosSide.X.Scale, State.startPosSide.X.Offset + delta.X, State.startPosSide.Y.Scale, State.startPosSide.Y.Offset + delta.Y)
end
table.insert(Data.connections, UI.sideFrame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UI.activeDragger then
		UI.activeDragger = "side"
		State.draggingSide = true
		State.dragStartSide = input.Position
		State.startPosSide = UI.sideFrame.Position
		table.insert(Data.connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				State.draggingSide = false
				if UI.activeDragger == "side" then UI.activeDragger = nil end
			end
		end))
	end
end))
table.insert(Data.connections, UI.sideFrame.InputChanged:Connect(function(input)
	if State.draggingSide and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		State.dragInputSide = input
	end
end))
table.insert(Data.connections, Services.UserInputService.InputChanged:Connect(function(input)
	if input == State.dragInputSide and State.draggingSide then dragSide(input) end
end))
table.insert(Data.connections, UI.openSide.MouseButton1Click:Connect(function()
	UI.sideFrame.Visible = not UI.sideFrame.Visible
end))
UI.sideTitle = Instance.new("TextLabel")
UI.sideTitle.Size = UDim2.new(1, 0, 0, 28)
UI.sideTitle.BackgroundColor3 = Color3.fromRGB(8, 28, 32)
UI.sideTitle.Text = "  keybinds"
UI.sideTitle.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.sideTitle.Font = Enum.Font.Code
UI.sideTitle.TextSize = 13
UI.sideTitle.TextXAlignment = Enum.TextXAlignment.Left
UI.sideTitle.ZIndex = 2
UI.sideTitle.Parent = UI.sideFrame
do local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 55, 65)), ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 25, 30))}); g.Rotation = 90; g.Parent = UI.sideTitle end
UI.sideList = Instance.new("ScrollingFrame")
UI.sideList.Position = UDim2.new(0, 5, 0, 58)
UI.sideList.Size = UDim2.new(1, -10, 1, -93)
UI.sideList.BackgroundColor3 = Color3.fromRGB(14, 17, 22)
UI.sideList.BorderSizePixel = 0
UI.sideList.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.sideList.ScrollBarThickness = 2
UI.sideList.ZIndex = 2
UI.sideList.Parent = UI.sideFrame
UI.sideLayout = Instance.new("UIListLayout")
UI.sideLayout.Padding = UDim.new(0, 5)
UI.sideLayout.Parent = UI.sideList
table.insert(Data.connections, UI.sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	UI.sideList.CanvasSize = UDim2.new(0, 0, 0, UI.sideLayout.AbsoluteContentSize.Y)
end))

UI.groupNameBox = Instance.new("TextBox")
UI.groupNameBox.PlaceholderText = "group name..."
UI.groupNameBox.Text = ""
UI.groupNameBox.Size = UDim2.new(0.55, -8, 0, 22)
UI.groupNameBox.Position = UDim2.new(0, 5, 0, 33)
UI.groupNameBox.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
UI.groupNameBox.TextColor3 = Color3.new(1, 1, 1)
UI.groupNameBox.PlaceholderColor3 = Color3.fromRGB(0, 100, 80)
UI.groupNameBox.Font = Enum.Font.Code
UI.groupNameBox.TextSize = 11
UI.groupNameBox.BorderSizePixel = 0
UI.groupNameBox.ZIndex = 3
UI.groupNameBox.Parent = UI.sideFrame
mkCorner(UI.groupNameBox, 3)
mkStroke(UI.groupNameBox, Color3.fromRGB(0, 70, 80), 1)

UI.saveGroupBtn = Instance.new("TextButton")
UI.saveGroupBtn.Text = "Save"
UI.saveGroupBtn.Size = UDim2.new(0.22, -4, 0, 22)
UI.saveGroupBtn.Position = UDim2.new(0.55, 2, 0, 33)
UI.saveGroupBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 70)
UI.saveGroupBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.saveGroupBtn.Font = Enum.Font.Code
UI.saveGroupBtn.TextSize = 11
UI.saveGroupBtn.BorderSizePixel = 0
UI.saveGroupBtn.ZIndex = 3
UI.saveGroupBtn.Parent = UI.sideFrame
mkCorner(UI.saveGroupBtn, 3)
mkStroke(UI.saveGroupBtn, Color3.fromRGB(0, 110, 120), 1)

UI.loadGroupBtn = Instance.new("TextButton")
UI.loadGroupBtn.Text = "Load"
UI.loadGroupBtn.Size = UDim2.new(0.22, -4, 0, 22)
UI.loadGroupBtn.Position = UDim2.new(0.77, 2, 0, 33)
UI.loadGroupBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
UI.loadGroupBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
UI.loadGroupBtn.Font = Enum.Font.Code
UI.loadGroupBtn.TextSize = 11
UI.loadGroupBtn.BorderSizePixel = 0
UI.loadGroupBtn.ZIndex = 3
UI.loadGroupBtn.Parent = UI.sideFrame
mkCorner(UI.loadGroupBtn, 3)
mkStroke(UI.loadGroupBtn, Color3.fromRGB(90, 60, 180), 1)

UI.groupDropdown = Instance.new("Frame")
UI.groupDropdown.Size = UDim2.new(1, -10, 0, 0)
UI.groupDropdown.Position = UDim2.new(0, 5, 0, 57)
UI.groupDropdown.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
UI.groupDropdown.BorderSizePixel = 0
UI.groupDropdown.ZIndex = 20
UI.groupDropdown.ClipsDescendants = true
UI.groupDropdown.Visible = false
UI.groupDropdown.Parent = UI.sideFrame
mkCorner(UI.groupDropdown, 4)
mkStroke(UI.groupDropdown, Color3.fromRGB(90, 60, 180), 1)
do
	local groupDropLayout = Instance.new("UIListLayout")
	groupDropLayout.Padding = UDim.new(0, 1)
	groupDropLayout.Parent = UI.groupDropdown
end

local function refreshGroupDropdown()
	for _, c in ipairs(UI.groupDropdown:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local count = 0
	for name, _ in pairs(Data.keybindGroups) do
		count += 1
		local btn = Instance.new("TextButton")
		btn.Text = name
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.BackgroundColor3 = Color3.fromRGB(20, 16, 34)
		btn.TextColor3 = Color3.fromRGB(200, 180, 255)
		btn.Font = Enum.Font.Code
		btn.TextSize = 11
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.BorderSizePixel = 0
		btn.ZIndex = 21
		btn.Parent = UI.groupDropdown
		table.insert(Data.connections, btn.MouseButton1Click:Connect(function()
			local data = Data.keybindGroups[name]
			if not data then return end
			for _, bind in pairs(Data.keybinds) do
				killAnim(bind.id)
			end
			for _, c in ipairs(UI.sideList:GetChildren()) do
				if c:IsA("Frame") then c:Destroy() end
			end
			Data.keybinds = {}
			for _, b in pairs(data) do
				local nb = {
					id = b.id, key = b.key and Enum.KeyCode[b.key] or nil,
					hold = b.hold or false, speed = b.speed or 1,
					loop = b.loop or false, active = false, tracks = {}, token = 0
				}
				table.insert(Data.keybinds, nb)
				addBind(nb)
			end
			dumpBinds()
			UI.groupNameBox.Text = name
			UI.groupDropdown.Visible = false
		end))
	end
	UI.groupDropdown.Size = UDim2.new(1, -10, 0, count * 23)
end

table.insert(Data.connections, UI.saveGroupBtn.MouseButton1Click:Connect(function()
	local name = UI.groupNameBox.Text:match("^%s*(.-)%s*$")
	if name == "" then return end
	local data = {}
	for _, bind in pairs(Data.keybinds) do
		table.insert(data, {
			id = bind.id, key = bind.key and bind.key.Name or nil,
			hold = bind.hold or false, speed = bind.speed or 1, loop = bind.loop or false
		})
	end
	Data.keybindGroups[name] = data
	dumpGroups()
	UI.saveGroupBtn.Text = "Saved!"
	task.delay(1.5, function() UI.saveGroupBtn.Text = "Save" end)
end))

table.insert(Data.connections, UI.loadGroupBtn.MouseButton1Click:Connect(function()
	refreshGroupDropdown()
	UI.groupDropdown.Visible = not UI.groupDropdown.Visible
end))
UI.addB = Instance.new("TextButton")
UI.addB.Size = UDim2.new(0.5, -10, 0, 25)
UI.addB.Position = UDim2.new(0, 5, 1, -30)
UI.addB.Text = "Add Bind"
UI.addB.BackgroundColor3 = Color3.fromRGB(0, 60, 70)
UI.addB.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.addB.ZIndex = 3
UI.addB.Parent = UI.sideFrame
mkCorner(UI.addB, 4)
mkStroke(UI.addB, Color3.fromRGB(0, 110, 120), 1)
UI.addR = Instance.new("TextButton")
UI.addR.Size = UDim2.new(0.5, -10, 0, 25)
UI.addR.Position = UDim2.new(0.5, 5, 1, -30)
UI.addR.Text = "Add Repl"
UI.addR.BackgroundColor3 = Color3.fromRGB(60, 57, 0)
UI.addR.TextColor3 = Color3.fromRGB(220, 210, 0)
UI.addR.ZIndex = 3
UI.addR.Parent = UI.sideFrame
mkCorner(UI.addR, 4)
mkStroke(UI.addR, Color3.fromRGB(120, 110, 0), 1)
UI.sideClose = Instance.new("TextButton")
UI.sideClose.Size = UDim2.new(0, 22, 0, 20)
UI.sideClose.Position = UDim2.new(1, -24, 0, 4)
UI.sideClose.Text = "X"
UI.sideClose.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
UI.sideClose.TextColor3 = Color3.new(1, 1, 1)
UI.sideClose.Font = Enum.Font.Code
UI.sideClose.TextSize = 11
UI.sideClose.ZIndex = 3
UI.sideClose.Parent = UI.sideFrame
mkCorner(UI.sideClose, 4)
UI.sideMinimize = Instance.new("TextButton")
UI.sideMinimize.Size = UDim2.new(0, 22, 0, 20)
UI.sideMinimize.Position = UDim2.new(1, -48, 0, 4)
UI.sideMinimize.Text = "-"
UI.sideMinimize.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
UI.sideMinimize.TextColor3 = Color3.new(1, 1, 1)
UI.sideMinimize.Font = Enum.Font.Code
UI.sideMinimize.TextSize = 11
UI.sideMinimize.ZIndex = 3
UI.sideMinimize.Parent = UI.sideFrame
mkCorner(UI.sideMinimize, 4)
UI.cmdsBtn = Instance.new("TextButton")
UI.cmdsBtn.Size = UDim2.new(0, 44, 0, 20)
UI.cmdsBtn.Position = UDim2.new(1, -94, 0, 4)
UI.cmdsBtn.Text = "cmds"
UI.cmdsBtn.BackgroundColor3 = Color3.fromRGB(0, 65, 75)
UI.cmdsBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.cmdsBtn.Font = Enum.Font.Code
UI.cmdsBtn.TextSize = 11
UI.cmdsBtn.ZIndex = 3
UI.cmdsBtn.Parent = UI.sideFrame
mkCorner(UI.cmdsBtn, 4)
mkStroke(UI.cmdsBtn, Color3.fromRGB(0, 90, 100), 1)
UI.cmdsTooltip = Instance.new("Frame")
UI.cmdsTooltip.Size = UDim2.new(0, 250, 0, 295)
UI.cmdsTooltip.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
UI.cmdsTooltip.BorderSizePixel = 0
UI.cmdsTooltip.ClipsDescendants = true
UI.cmdsTooltip.ZIndex = 30
UI.cmdsTooltip.Visible = false
UI.cmdsTooltip.Parent = UI.gui
mkCorner(UI.cmdsTooltip, 4)
mkStroke(UI.cmdsTooltip, Color3.fromRGB(0, 180, 150), 1)
table.insert(Data.connections, UI.cmdsBtn.MouseEnter:Connect(function()
	local abs = UI.cmdsBtn.AbsolutePosition
	UI.cmdsTooltip.Position = UDim2.new(0, abs.X - 255, 0, abs.Y)
	UI.cmdsTooltip.Visible = true
end))
table.insert(Data.connections, UI.cmdsBtn.MouseLeave:Connect(function()
	UI.cmdsTooltip.Visible = false
end))
do
UI.tooltipLabel = Instance.new("TextLabel")
UI.tooltipLabel.Size = UDim2.new(1, -10, 1, -10)
UI.tooltipLabel.Position = UDim2.new(0, 5, 0, 5)
UI.tooltipLabel.BackgroundTransparency = 1
UI.tooltipLabel.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.tooltipLabel.TextYAlignment = Enum.TextYAlignment.Top
UI.tooltipLabel.TextWrapped = true
UI.tooltipLabel.Font = Enum.Font.Code
UI.tooltipLabel.TextSize = 11
UI.tooltipLabel.ZIndex = 31
UI.tooltipLabel.Text = [[COMMANDS (ID box):
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
UI.tooltipLabel.Parent = UI.cmdsTooltip
end
table.insert(Data.connections, UI.sideMinimize.MouseButton1Click:Connect(function()
	State.sideMinimized = not State.sideMinimized
	if State.sideMinimized then
		UI.sideFrame.Size = UDim2.new(0, 200, 0, 28)
		UI.sideList.Visible = false
		UI.addB.Visible = false
		UI.addR.Visible = false
		UI.cmdsBtn.Visible = false
		UI.groupNameBox.Visible = false
		UI.saveGroupBtn.Visible = false
		UI.loadGroupBtn.Visible = false
		UI.groupDropdown.Visible = false
		UI.sideMinimize.Text = "+"
	else
		UI.sideFrame.Size = UDim2.new(0, 200, 0, 480)
		UI.sideList.Visible = true
		UI.addB.Visible = true
		UI.addR.Visible = true
		UI.cmdsBtn.Visible = true
		UI.groupNameBox.Visible = true
		UI.saveGroupBtn.Visible = true
		UI.loadGroupBtn.Visible = true
		UI.sideMinimize.Text = "-"
	end
end))
table.insert(Data.connections, UI.sideClose.MouseButton1Click:Connect(function()
	UI.sideFrame.Visible = false
end))
UI.viewportWin = Instance.new("Frame")
local viewportWin = UI.viewportWin
viewportWin.Name = "ViewportWindow"
viewportWin.Size = UDim2.new(0, 300, 0, 538)
viewportWin.Position = UDim2.new(0, 670, 0, 380)
viewportWin.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
viewportWin.BorderSizePixel = 0
viewportWin.Active = true
viewportWin.ClipsDescendants = true
viewportWin.ZIndex = 5
viewportWin.Visible = false
viewportWin.Parent = UI.gui
mkCorner(viewportWin, 6)
mkStroke(viewportWin, Color3.fromRGB(0, 90, 100), 1)
local function dragVP(input)
	local delta = input.Position - State.dragStartVP
	viewportWin.Position = UDim2.new(State.startPosVP.X.Scale, State.startPosVP.X.Offset + delta.X, State.startPosVP.Y.Scale, State.startPosVP.Y.Offset + delta.Y)
end
table.insert(Data.connections, viewportWin.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UI.activeDragger then
		UI.activeDragger = "vp"
		State.draggingVP = true
		State.dragStartVP = input.Position
		State.startPosVP = viewportWin.Position
		table.insert(Data.connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				State.draggingVP = false
				if UI.activeDragger == "vp" then UI.activeDragger = nil end
			end
		end))
	end
end))
table.insert(Data.connections, viewportWin.InputChanged:Connect(function(input)
	if State.draggingVP and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		State.dragInputVP = input
	end
end))
table.insert(Data.connections, Services.RunService.Heartbeat:Connect(function()
	if State.dragInputVP and State.draggingVP then dragVP(State.dragInputVP) end
end))
local vpTop = Instance.new("Frame")
vpTop.Size = UDim2.new(1, 0, 0, 25)
vpTop.BackgroundColor3 = Color3.fromRGB(8, 28, 32)
vpTop.BorderSizePixel = 0
vpTop.ZIndex = 6
vpTop.Parent = viewportWin
do local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 55, 65)), ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 25, 30))}); g.Rotation = 90; g.Parent = vpTop end
local vpTitle = Instance.new("TextLabel")
UI.vpTitle = vpTitle
vpTitle.Text = "preview"
vpTitle.Size = UDim2.new(1, -120, 1, 0)
vpTitle.BackgroundTransparency = 1
vpTitle.TextColor3 = Color3.fromRGB(0, 220, 170)
vpTitle.Font = Enum.Font.Code
vpTitle.TextSize = 13
vpTitle.ZIndex = 7
vpTitle.Parent = vpTop
local vpClose = Instance.new("TextButton")
UI.vpClose = vpClose
UI.vpClose.Size = UDim2.new(0, 25, 0, 20)
UI.vpClose.Position = UDim2.new(1, -27, 0, 3)
UI.vpClose.Text = "X"
UI.vpClose.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
UI.vpClose.TextColor3 = Color3.new(1, 1, 1)
UI.vpClose.BorderSizePixel = 0
UI.vpClose.Font = Enum.Font.Code
UI.vpClose.TextSize = 11
UI.vpClose.ZIndex = 7
UI.vpClose.Parent = vpTop
mkCorner(UI.vpClose, 4)

local vpMinimize = Instance.new("TextButton")
UI.vpMinimize = vpMinimize
UI.vpMinimize.Size = UDim2.new(0, 25, 0, 20)
UI.vpMinimize.Position = UDim2.new(1, -54, 0, 3)
UI.vpMinimize.Text = "-"
UI.vpMinimize.BackgroundColor3 = Color3.fromRGB(0, 55, 65)
UI.vpMinimize.TextColor3 = Color3.new(1, 1, 1)
UI.vpMinimize.BorderSizePixel = 0
UI.vpMinimize.Font = Enum.Font.Code
UI.vpMinimize.TextSize = 11
UI.vpMinimize.ZIndex = 7
UI.vpMinimize.Parent = vpTop
mkCorner(UI.vpMinimize, 4)

table.insert(Data.connections, UI.vpClose.MouseButton1Click:Connect(function()
	UI.viewportWin.Visible = false
end))
table.insert(Data.connections, UI.vpMinimize.MouseButton1Click:Connect(function()
	State.vpMinimized = not State.vpMinimized
	if State.vpMinimized then
		UI.viewportWin.Size = UDim2.new(0, 300, 0, 28)
		UI.vpMinimize.Text = "+"
	else
		UI.viewportWin.Size = UDim2.new(0, 300, 0, 538)
		UI.vpMinimize.Text = "-"
	end
end))

local vpIdInput = Instance.new("TextBox")
UI.vpIdInput = vpIdInput
UI.vpIdInput.Text = ""
UI.vpIdInput.PlaceholderText = "animation id..."
UI.vpIdInput.Position = UDim2.new(0, 5, 0, 30)
UI.vpIdInput.Size = UDim2.new(1, -55, 0, 24)
UI.vpIdInput.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
UI.vpIdInput.TextColor3 = Color3.new(1, 1, 1)
UI.vpIdInput.PlaceholderColor3 = Color3.fromRGB(0, 100, 80)
UI.vpIdInput.BorderSizePixel = 0
UI.vpIdInput.Font = Enum.Font.Code
UI.vpIdInput.TextSize = 12
UI.vpIdInput.ZIndex = 7
UI.vpIdInput.Parent = UI.viewportWin
mkCorner(UI.vpIdInput, 4)
mkStroke(UI.vpIdInput, Color3.fromRGB(0, 90, 100), 1)

local vpIdGoBtn = Instance.new("TextButton")
UI.vpIdGoBtn = vpIdGoBtn
UI.vpIdGoBtn.Text = "▶"
UI.vpIdGoBtn.Position = UDim2.new(1, -47, 0, 30)
UI.vpIdGoBtn.Size = UDim2.new(0, 42, 0, 24)
UI.vpIdGoBtn.BackgroundColor3 = Color3.fromRGB(0, 70, 75)
UI.vpIdGoBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.vpIdGoBtn.BorderSizePixel = 0
UI.vpIdGoBtn.Font = Enum.Font.Code
UI.vpIdGoBtn.TextSize = 13
UI.vpIdGoBtn.ZIndex = 7
UI.vpIdGoBtn.Parent = UI.viewportWin

local vpFrame = Instance.new("ViewportFrame")
UI.vpFrame = vpFrame
UI.vpFrame.Size = UDim2.new(1, -10, 0, 220)
UI.vpFrame.Position = UDim2.new(0, 5, 0, 58)
UI.vpFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
UI.vpFrame.BorderSizePixel = 0
UI.vpFrame.ZIndex = 6
UI.vpFrame.Parent = UI.viewportWin
mkCorner(UI.vpFrame, 4)
mkStroke(UI.vpFrame, Color3.fromRGB(0, 80, 90), 1)
local vpCamera = Instance.new("Camera")
UI.vpCamera = vpCamera
UI.vpCamera.Parent = UI.vpFrame
UI.vpFrame.CurrentCamera = UI.vpCamera
local worldModel = Instance.new("WorldModel")
UI.worldModel = worldModel
UI.worldModel.Parent = UI.vpFrame
UI.vpFrame.Ambient = Color3.fromRGB(120, 120, 120)
UI.vpFrame.LightDirection = Vector3.new(-1, -2, -1)
local vpIdLabel = Instance.new("TextLabel")
UI.vpIdLabel = vpIdLabel
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
UI.vpTimerLabel = vpTimerLabel
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
UI.vpScrubBg = vpScrubBg
vpScrubBg.Position = UDim2.new(0, 5, 0, 317)
vpScrubBg.Size = UDim2.new(1, -10, 0, 12)
vpScrubBg.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
vpScrubBg.BorderSizePixel = 0
vpScrubBg.ZIndex = 6
vpScrubBg.Parent = viewportWin
mkCorner(vpScrubBg, 6)

local vpScrubFill = Instance.new("Frame")
UI.vpScrubFill = vpScrubFill
vpScrubFill.Size = UDim2.new(0, 0, 1, 0)
vpScrubFill.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
vpScrubFill.BorderSizePixel = 0
vpScrubFill.ZIndex = 7
vpScrubFill.Parent = vpScrubBg

local vpScrubBtn = Instance.new("TextButton")
UI.vpScrubBtn = vpScrubBtn
vpScrubBtn.Size = UDim2.new(1, 0, 1, 0)
vpScrubBtn.BackgroundTransparency = 1
vpScrubBtn.Text = ""
vpScrubBtn.ZIndex = 8
vpScrubBtn.Parent = vpScrubBg

local function nukeGhost()
	if Data.vpTrack then
		pcall(function() Data.vpTrack:Stop(0) end)
		Data.vpTrack = nil
	end
	Data.vpAnimator = nil
	Data.vpRootPart = nil
	if Data.ghostChar then
		pcall(function() Data.ghostChar:Destroy() end)
		Data.ghostChar = nil
	end
	for _, obj in ipairs(worldModel:GetChildren()) do
		pcall(function() obj:Destroy() end)
	end
end

local vpPauseBtn = Instance.new("TextButton")
UI.vpPauseBtn = vpPauseBtn
UI.vpPauseBtn.Text = "⏸ Pause"
UI.vpPauseBtn.Position = UDim2.new(0, 5, 0, 328)
UI.vpPauseBtn.Size = UDim2.new(1, -10, 0, 20)
UI.vpPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 65)
UI.vpPauseBtn.TextColor3 = Color3.new(1, 1, 1)
UI.vpPauseBtn.BorderSizePixel = 0
UI.vpPauseBtn.Font = Enum.Font.Code
UI.vpPauseBtn.TextSize = 11
UI.vpPauseBtn.ZIndex = 6
UI.vpPauseBtn.Parent = UI.viewportWin
mkCorner(UI.vpPauseBtn, 4)

table.insert(Data.connections, UI.vpPauseBtn.MouseButton1Click:Connect(function()
	if not State.vpPaused and not Data.vpTrack then return end
	State.vpPaused = not State.vpPaused
	if State.vpPaused then
		State.vpPausedAt = Data.vpTrack and Data.vpTrack.TimePosition or 0
		State.vpPausedLength = Data.vpTrack and Data.vpTrack.Length or 0
		if Data.vpTrack then
			pcall(function() Data.vpTrack:Stop(0) end)
			Data.vpTrack = nil
		end
		if Data.vpAnimator then
			pcall(function() Data.vpAnimator:Destroy() end)
			Data.vpAnimator = nil
		end
	else
		if State.vpCurrentId and State.vpCurrentId ~= "" and Data.ghostChar then
			local hum = Data.ghostChar:FindFirstChildOfClass("Humanoid")
			if hum then
				if Data.vpAnimator then
					pcall(function() Data.vpAnimator:Destroy() end)
				end
				local animator = Instance.new("Animator")
				animator.Parent = hum
				Data.vpAnimator = animator
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. State.vpCurrentId
				local track
				pcall(function() track = animator:LoadAnimation(anim) end)
				if track then
					track.Priority = Enum.AnimationPriority.Action4
					track.Looped = State.vpLooped
					track:Play(0, 1, 0)
					track.TimePosition = State.vpPausedAt
					Data.vpTrack = track
					task.defer(function()
						if Data.vpTrack == track then
							track:AdjustSpeed(tonumber(UI.vpSpeedBox.Text) or 1)
						end
					end)
				end
			end
		end
	end
	UI.vpPauseBtn.Text = State.vpPaused and "▶ Resume" or "⏸ Pause"
	UI.vpPauseBtn.BackgroundColor3 = State.vpPaused and Color3.fromRGB(0, 80, 0) or Color3.fromRGB(0, 50, 60)
end))

table.insert(Data.connections, UI.vpScrubBtn.MouseButton1Down:Connect(function()
	State.vpScrubbing = true
	if State.vpPaused and Data.ghostChar and State.vpCurrentId and State.vpCurrentId ~= "" then
		local hum = Data.ghostChar:FindFirstChildOfClass("Humanoid")
		if hum then
			if Data.vpAnimator then pcall(function() Data.vpAnimator:Destroy() end) end
			local animator = Instance.new("Animator")
			animator.Parent = hum
			Data.vpAnimator = animator
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. State.vpCurrentId
			pcall(function() Data.vpScrubTrack = animator:LoadAnimation(anim) end)
			if Data.vpScrubTrack then
				Data.vpScrubTrack.Priority = Enum.AnimationPriority.Action4
				Data.vpScrubTrack:Play(0, 1, 0)
				Data.vpScrubTrack.TimePosition = State.vpPausedAt
			end
		end
	end
end))
table.insert(Data.connections, Services.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and State.vpScrubbing then
		State.vpScrubbing = false
		Data.vpScrubTrack = nil
	end
end))

local vpSpeedLabel = Instance.new("TextLabel")
UI.vpSpeedLabel = vpSpeedLabel
UI.vpSpeedLabel.Text = "Speed"
UI.vpSpeedLabel.Position = UDim2.new(0, 5, 0, 353)
UI.vpSpeedLabel.Size = UDim2.new(0, 40, 0, 20)
UI.vpSpeedLabel.BackgroundTransparency = 1
UI.vpSpeedLabel.TextColor3 = Color3.fromRGB(0, 180, 140)
UI.vpSpeedLabel.Font = Enum.Font.Code
UI.vpSpeedLabel.TextSize = 12
UI.vpSpeedLabel.ZIndex = 6
UI.vpSpeedLabel.Parent = UI.viewportWin
UI.vpSpeedBox = Instance.new("TextBox")
UI.vpSpeedBox.Text = "1"
UI.vpSpeedBox.PlaceholderText = "speed"
UI.vpSpeedBox.Position = UDim2.new(0, 50, 0, 353)
UI.vpSpeedBox.Size = UDim2.new(0, 55, 0, 20)
UI.vpSpeedBox.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
UI.vpSpeedBox.TextColor3 = Color3.new(1, 1, 1)
UI.vpSpeedBox.BorderSizePixel = 0
UI.vpSpeedBox.Font = Enum.Font.Code
UI.vpSpeedBox.TextSize = 12
UI.vpSpeedBox.ZIndex = 6
UI.vpSpeedBox.Parent = UI.viewportWin
mkCorner(UI.vpSpeedBox, 3)
mkStroke(UI.vpSpeedBox, Color3.fromRGB(0, 80, 90), 1)
local vpLoopToggle = Instance.new("TextButton")
UI.vpLoopToggle = vpLoopToggle
UI.vpLoopToggle.Text = "Loop: OFF"
UI.vpLoopToggle.Position = UDim2.new(0, 113, 0, 353)
UI.vpLoopToggle.Size = UDim2.new(0, 80, 0, 20)
UI.vpLoopToggle.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
UI.vpLoopToggle.TextColor3 = Color3.fromRGB(255, 180, 160)
UI.vpLoopToggle.BorderSizePixel = 0
UI.vpLoopToggle.Font = Enum.Font.Code
UI.vpLoopToggle.TextSize = 11
UI.vpLoopToggle.ZIndex = 6
UI.vpLoopToggle.Parent = UI.viewportWin
mkCorner(UI.vpLoopToggle, 4)
local vpTimeLabel = Instance.new("TextLabel")
UI.vpTimeLabel = vpTimeLabel
UI.vpTimeLabel.Text = "Time"
UI.vpTimeLabel.Position = UDim2.new(0, 200, 0, 353)
UI.vpTimeLabel.Size = UDim2.new(0, 35, 0, 20)
UI.vpTimeLabel.BackgroundTransparency = 1
UI.vpTimeLabel.TextColor3 = Color3.fromRGB(0, 180, 140)
UI.vpTimeLabel.Font = Enum.Font.Code
UI.vpTimeLabel.TextSize = 12
UI.vpTimeLabel.ZIndex = 6
UI.vpTimeLabel.Parent = UI.viewportWin
local vpTimeBox = Instance.new("TextBox")
UI.vpTimeBox = vpTimeBox
UI.vpTimeBox.Text = "0"
UI.vpTimeBox.PlaceholderText = "time"
UI.vpTimeBox.Position = UDim2.new(0, 238, 0, 353)
UI.vpTimeBox.Size = UDim2.new(0, 52, 0, 20)
UI.vpTimeBox.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
UI.vpTimeBox.TextColor3 = Color3.new(1, 1, 1)
UI.vpTimeBox.BorderSizePixel = 0
UI.vpTimeBox.Font = Enum.Font.Code
UI.vpTimeBox.TextSize = 12
UI.vpTimeBox.ZIndex = 6
UI.vpTimeBox.Parent = UI.viewportWin
mkCorner(vpTimeBox, 3)
mkStroke(vpTimeBox, Color3.fromRGB(0, 80, 90), 1)
local vpPlayBtn = Instance.new("TextButton")
UI.vpPlayBtn = vpPlayBtn
UI.vpPlayBtn.Text = "▶ Play Preview"
UI.vpPlayBtn.Position = UDim2.new(0, 5, 0, 378)
UI.vpPlayBtn.Size = UDim2.new(0.5, -8, 0, 25)
UI.vpPlayBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 70)
UI.vpPlayBtn.TextColor3 = Color3.fromRGB(0, 220, 170)
UI.vpPlayBtn.BorderSizePixel = 0
UI.vpPlayBtn.Font = Enum.Font.Code
UI.vpPlayBtn.ZIndex = 6
UI.vpPlayBtn.Parent = UI.viewportWin
mkCorner(UI.vpPlayBtn, 4)
local vpStopBtn = Instance.new("TextButton")
UI.vpStopBtn = vpStopBtn
UI.vpStopBtn.Text = "■ Stop Preview"
UI.vpStopBtn.Position = UDim2.new(0.5, 3, 0, 378)
UI.vpStopBtn.Size = UDim2.new(0.5, -8, 0, 25)
UI.vpStopBtn.BackgroundColor3 = Color3.fromRGB(80, 15, 15)
UI.vpStopBtn.TextColor3 = Color3.fromRGB(255, 160, 140)
UI.vpStopBtn.BorderSizePixel = 0
UI.vpStopBtn.Font = Enum.Font.Code
UI.vpStopBtn.ZIndex = 6
UI.vpStopBtn.Parent = UI.viewportWin
mkCorner(UI.vpStopBtn, 4)
local vpPlaySelfBtn = Instance.new("TextButton")
UI.vpPlaySelfBtn = vpPlaySelfBtn
UI.vpPlaySelfBtn.Text = "★ Play on Self"
UI.vpPlaySelfBtn.Position = UDim2.new(0, 5, 0, 408)
UI.vpPlaySelfBtn.Size = UDim2.new(1, -10, 0, 22)
UI.vpPlaySelfBtn.BackgroundColor3 = Color3.fromRGB(0, 45, 75)
UI.vpPlaySelfBtn.TextColor3 = Color3.fromRGB(140, 190, 255)
UI.vpPlaySelfBtn.BorderSizePixel = 0
UI.vpPlaySelfBtn.Font = Enum.Font.Code
UI.vpPlaySelfBtn.ZIndex = 6
UI.vpPlaySelfBtn.Parent = UI.viewportWin
mkCorner(UI.vpPlaySelfBtn, 4)
local vpRotateCCW = Instance.new("TextButton")
UI.vpRotateCCW = vpRotateCCW
UI.vpRotateCCW.Text = "◄"
UI.vpRotateCCW.Position = UDim2.new(0, 5, 0, 435)
UI.vpRotateCCW.Size = UDim2.new(0.22, -4, 0, 20)
UI.vpRotateCCW.BackgroundColor3 = Color3.fromRGB(20, 22, 38)
UI.vpRotateCCW.TextColor3 = Color3.fromRGB(160, 170, 255)
UI.vpRotateCCW.BorderSizePixel = 0
UI.vpRotateCCW.Font = Enum.Font.Code
UI.vpRotateCCW.TextSize = 13
UI.vpRotateCCW.ZIndex = 6
UI.vpRotateCCW.Parent = UI.viewportWin
mkCorner(UI.vpRotateCCW, 4)
local vpRotateCW = Instance.new("TextButton")
UI.vpRotateCW = vpRotateCW
UI.vpRotateCW.Text = "►"
UI.vpRotateCW.Position = UDim2.new(0.78, 3, 0, 435)
UI.vpRotateCW.Size = UDim2.new(0.22, -8, 0, 20)
UI.vpRotateCW.BackgroundColor3 = Color3.fromRGB(20, 22, 38)
UI.vpRotateCW.TextColor3 = Color3.fromRGB(160, 170, 255)
UI.vpRotateCW.BorderSizePixel = 0
UI.vpRotateCW.Font = Enum.Font.Code
UI.vpRotateCW.TextSize = 13
UI.vpRotateCW.ZIndex = 6
UI.vpRotateCW.Parent = UI.viewportWin
mkCorner(UI.vpRotateCW, 4)
local vpPrecisionBox = Instance.new("TextBox")
UI.vpPrecisionBox = vpPrecisionBox
UI.vpPrecisionBox.Text = "90"
UI.vpPrecisionBox.PlaceholderText = "step"
UI.vpPrecisionBox.Position = UDim2.new(0.22, 2, 0, 435)
UI.vpPrecisionBox.Size = UDim2.new(0.56, -4, 0, 20)
UI.vpPrecisionBox.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
UI.vpPrecisionBox.TextColor3 = Color3.new(1, 1, 1)
UI.vpPrecisionBox.PlaceholderColor3 = Color3.fromRGB(60, 65, 100)
UI.vpPrecisionBox.BorderSizePixel = 0
UI.vpPrecisionBox.Font = Enum.Font.Code
UI.vpPrecisionBox.TextSize = 11
UI.vpPrecisionBox.ZIndex = 6
UI.vpPrecisionBox.Parent = UI.viewportWin
mkCorner(UI.vpPrecisionBox, 3)
mkStroke(UI.vpPrecisionBox, Color3.fromRGB(60, 65, 120), 1)
local vpZoomIn = Instance.new("TextButton")
UI.vpZoomIn = vpZoomIn
UI.vpZoomIn.Text = "+ Zoom"
UI.vpZoomIn.Position = UDim2.new(0, 5, 0, 460)
UI.vpZoomIn.Size = UDim2.new(0.5, -8, 0, 20)
UI.vpZoomIn.BackgroundColor3 = Color3.fromRGB(15, 40, 22)
UI.vpZoomIn.TextColor3 = Color3.fromRGB(140, 230, 160)
UI.vpZoomIn.BorderSizePixel = 0
UI.vpZoomIn.Font = Enum.Font.Code
UI.vpZoomIn.TextSize = 11
UI.vpZoomIn.ZIndex = 6
UI.vpZoomIn.Parent = UI.viewportWin
mkCorner(UI.vpZoomIn, 4)
local vpZoomOut = Instance.new("TextButton")
UI.vpZoomOut = vpZoomOut
UI.vpZoomOut.Text = "- Zoom"
UI.vpZoomOut.Position = UDim2.new(0.5, 3, 0, 460)
UI.vpZoomOut.Size = UDim2.new(0.5, -8, 0, 20)
UI.vpZoomOut.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
UI.vpZoomOut.TextColor3 = Color3.fromRGB(255, 160, 140)
UI.vpZoomOut.BorderSizePixel = 0
UI.vpZoomOut.Font = Enum.Font.Code
UI.vpZoomOut.TextSize = 11
UI.vpZoomOut.ZIndex = 6
UI.vpZoomOut.Parent = UI.viewportWin
mkCorner(UI.vpZoomOut, 4)


local vpSkinLabel = Instance.new("TextLabel")
vpSkinLabel.Text = "username or userid"
vpSkinLabel.Position = UDim2.new(0, 5, 0, 484)
vpSkinLabel.Size = UDim2.new(1, -10, 0, 12)
vpSkinLabel.BackgroundTransparency = 1
vpSkinLabel.TextColor3 = Color3.fromRGB(0, 160, 130)
vpSkinLabel.TextXAlignment = Enum.TextXAlignment.Left
vpSkinLabel.Font = Enum.Font.Code
vpSkinLabel.TextSize = 10
vpSkinLabel.ZIndex = 6
vpSkinLabel.Parent = UI.viewportWin

local vpSkinInput = Instance.new("TextBox")
UI.vpSkinInput = vpSkinInput
vpSkinInput.Text = ""
vpSkinInput.PlaceholderText = "e.g. Builderman or 156"
vpSkinInput.Position = UDim2.new(0, 5, 0, 498)
vpSkinInput.Size = UDim2.new(1, -110, 0, 22)
vpSkinInput.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
vpSkinInput.TextColor3 = Color3.new(1, 1, 1)
vpSkinInput.PlaceholderColor3 = Color3.fromRGB(60, 80, 70)
vpSkinInput.BorderSizePixel = 0
vpSkinInput.Font = Enum.Font.Code
vpSkinInput.TextSize = 11
vpSkinInput.ZIndex = 6
vpSkinInput.Parent = UI.viewportWin
mkCorner(vpSkinInput, 3)
mkStroke(vpSkinInput, Color3.fromRGB(0, 80, 90), 1)

local vpSkinLoadBtn = Instance.new("TextButton")
UI.vpSkinLoadBtn = vpSkinLoadBtn
vpSkinLoadBtn.Text = "Load Skin"
vpSkinLoadBtn.Position = UDim2.new(1, -102, 0, 498)
vpSkinLoadBtn.Size = UDim2.new(0, 60, 0, 22)
vpSkinLoadBtn.BackgroundColor3 = Color3.fromRGB(0, 55, 75)
vpSkinLoadBtn.TextColor3 = Color3.fromRGB(0, 210, 170)
vpSkinLoadBtn.BorderSizePixel = 0
vpSkinLoadBtn.Font = Enum.Font.Code
vpSkinLoadBtn.TextSize = 10
vpSkinLoadBtn.ZIndex = 6
vpSkinLoadBtn.Parent = UI.viewportWin
mkCorner(vpSkinLoadBtn, 3)
mkStroke(vpSkinLoadBtn, Color3.fromRGB(0, 110, 130), 1)

local vpSkinResetBtn = Instance.new("TextButton")
UI.vpSkinResetBtn = vpSkinResetBtn
vpSkinResetBtn.Text = "Reset"
vpSkinResetBtn.Position = UDim2.new(1, -38, 0, 498)
vpSkinResetBtn.Size = UDim2.new(0, 33, 0, 22)
vpSkinResetBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
vpSkinResetBtn.TextColor3 = Color3.fromRGB(255, 160, 140)
vpSkinResetBtn.BorderSizePixel = 0
vpSkinResetBtn.Font = Enum.Font.Code
vpSkinResetBtn.TextSize = 10
vpSkinResetBtn.ZIndex = 6
vpSkinResetBtn.Parent = UI.viewportWin
mkCorner(vpSkinResetBtn, 3)
mkStroke(vpSkinResetBtn, Color3.fromRGB(120, 40, 40), 1)

local vpSkinStatusLabel = Instance.new("TextLabel")
UI.vpSkinStatusLabel = vpSkinStatusLabel
vpSkinStatusLabel.Text = ""
vpSkinStatusLabel.Position = UDim2.new(0, 5, 0, 522)
vpSkinStatusLabel.Size = UDim2.new(1, -10, 0, 12)
vpSkinStatusLabel.BackgroundTransparency = 1
vpSkinStatusLabel.TextColor3 = Color3.fromRGB(0, 180, 140)
vpSkinStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
vpSkinStatusLabel.Font = Enum.Font.Code
vpSkinStatusLabel.TextSize = 10
vpSkinStatusLabel.ZIndex = 6
vpSkinStatusLabel.Parent = UI.viewportWin

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
	root.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, State.vpYaw, 0)
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
	
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1, 1, 1)
	headMesh.Parent = head
	
	local function att(parent, name, cf)
		local a = Instance.new("Attachment")
		a.Name = name
		a.CFrame = cf
		a.Parent = parent
	end
	att(head,  "HatAttachment",       CFrame.new(0,  0.6,  0))
	att(head,  "HairAttachment",      CFrame.new(0,  0.6,  0))
	att(head,  "FaceFrontAttachment", CFrame.new(0,  0,   -0.6))
	att(head,  "FaceBackAttachment",  CFrame.new(0,  0,    0.6))
	att(torso, "BodyFrontAttachment", CFrame.new(0,  0,   -0.5))
	att(torso, "BodyBackAttachment",  CFrame.new(0,  0,    0.5))
	att(torso, "NeckAttachment",      CFrame.new(0,  1,    0))
	att(torso, "WaistFrontAttachment",CFrame.new(0, -1,   -0.5))
	att(torso, "WaistBackAttachment", CFrame.new(0, -1,    0.5))
	att(torso, "WaistCenterAttachment",CFrame.new(0,-1,    0))
	att(rArm,  "RightShoulderAttachment", CFrame.new(0, 1, 0))
	att(lArm,  "LeftShoulderAttachment",  CFrame.new(0, 1, 0))
	model.Parent = worldModel
	local animator = Instance.new("Animator")
	animator.Parent = hum
	return model, animator, root
end


local function stripRigAppearance(rig)
	for _, obj in ipairs(rig:GetChildren()) do
		if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants")
			or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then
			obj:Destroy()
		end
	end
	local defaultColor = Color3.fromRGB(163, 162, 165)
	local partNames = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
	for _, name in ipairs(partNames) do
		local p = rig:FindFirstChild(name)
		if p then
			p.Color = defaultColor
			for _, m in ipairs(p:GetChildren()) do
				if m:IsA("SpecialMesh") or m:IsA("BlockMesh") then m:Destroy() end
			end
		end
	end
	
	local head = rig:FindFirstChild("Head")
	if head then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Head
		mesh.Scale = Vector3.new(1, 1, 1)
		mesh.Parent = head
	end
	local nose = rig:FindFirstChild("Nose")
	if nose then nose:Destroy() end
end


local function applyFromChar(rig, srcChar)
	
	local bc = srcChar:FindFirstChildOfClass("BodyColors")
	if bc then
		local colorMap = {
			Head        = bc.HeadColor3,
			Torso       = bc.TorsoColor3,
			["Left Arm"]  = bc.LeftArmColor3,
			["Right Arm"] = bc.RightArmColor3,
			["Left Leg"]  = bc.LeftLegColor3,
			["Right Leg"] = bc.RightLegColor3,
		}
		for partName, color in pairs(colorMap) do
			local p = rig:FindFirstChild(partName)
			if p then p.Color = color end
		end
		bc:Clone().Parent = rig
	end
	
	local srcHead = srcChar:FindFirstChild("Head")
	local dstHead = rig:FindFirstChild("Head")
	if srcHead and dstHead then
		dstHead.Color = srcHead.Color
		for _, m in ipairs(dstHead:GetChildren()) do
			if m:IsA("SpecialMesh") or m:IsA("BlockMesh") then m:Destroy() end
		end
		local srcMesh = srcHead:FindFirstChildOfClass("SpecialMesh")
		if srcMesh then
			srcMesh:Clone().Parent = dstHead
		else
			
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1, 1, 1)
			mesh.Parent = dstHead
		end
	end
	
	for _, obj in ipairs(srcChar:GetChildren()) do
		if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
			obj:Clone().Parent = rig
		end
	end
	
	for _, obj in ipairs(srcChar:GetChildren()) do
		if obj:IsA("Accessory") then
			local acc = obj:Clone()
			local handle = acc:FindFirstChild("Handle")
			if handle then
				
				for _, w in ipairs(handle:GetChildren()) do
					if w:IsA("Weld") or w:IsA("Motor6D") or w:IsA("Snap") then w:Destroy() end
				end
				
				local att = handle:FindFirstChildOfClass("Attachment")
				local targetPartName = "Head"
				if att then
					local n = att.Name:lower()
					if n:find("hat") or n:find("hair") or n:find("facefront") or n:find("face") then
						targetPartName = "Head"
					elseif n:find("neck") or n:find("bodyfront") or n:find("body") or n:find("torso") then
						targetPartName = "Torso"
					elseif n:find("leftarm") or n:find("left_arm") then
						targetPartName = "Left Arm"
					elseif n:find("rightarm") or n:find("right_arm") then
						targetPartName = "Right Arm"
					elseif n:find("leftleg") or n:find("left_leg") then
						targetPartName = "Left Leg"
					elseif n:find("rightleg") or n:find("right_leg") then
						targetPartName = "Right Leg"
					end
				end
				local targetPart = rig:FindFirstChild(targetPartName)
				if targetPart then
					local weld = Instance.new("Weld")
					weld.Part0 = targetPart
					weld.Part1 = handle
					if att then
						local dstAtt = targetPart:FindFirstChild(att.Name)
						if dstAtt then
							weld.C0 = dstAtt.CFrame
							weld.C1 = att.CFrame
						end
					end
					weld.Parent = handle
				end
				handle.Anchored = false
				handle.CanCollide = false
			end
			acc.Parent = rig
		end
	end
end


local function applyFromDescription(rig, desc)
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local ok, err = pcall(function()
		hum:ApplyDescription(desc)
	end)
	return ok
end


local function applyPlayerSkin(query)
	if not Data.ghostChar then return end
	local rig = Data.ghostChar

	UI.vpSkinStatusLabel.Text = "loading..."
	UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(180, 160, 0)

	task.spawn(function()
		
		local resolvedId
		if tostring(query):match("^%d+$") then
			resolvedId = tonumber(query)
		else
			local ok, uid = pcall(function()
				return Services.Players:GetUserIdFromNameAsync(query)
			end)
			if ok and uid then
				resolvedId = uid
			else
				UI.vpSkinStatusLabel.Text = "user not found"
				UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				return
			end
		end

		
		local ingameChar = nil
		for _, p in ipairs(Services.Players:GetPlayers()) do
			if p.UserId == resolvedId and p.Character then
				ingameChar = p.Character
				break
			end
		end

		if ingameChar then
			stripRigAppearance(rig)
			applyFromChar(rig, ingameChar)
			State.vpSkinQuery = query
			State.vpSkinCache = { type = "char", data = ingameChar }
			UI.vpSkinStatusLabel.Text = "from server: " .. tostring(resolvedId)
			UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(0, 220, 160)
			return
		end


		local desc
		local ok, result = pcall(function()
			desc = Players:GetHumanoidDescriptionFromUserId(resolvedId)
		end)
		
		if not ok or not desc then
			ok, result = pcall(function()
				desc = Services.Players:GetHumanoidDescriptionFromUserId(resolvedId)
			end)
		end

		if ok and desc then
			stripRigAppearance(rig)
			local applied = applyFromDescription(rig, desc)
			if applied then
				State.vpSkinQuery = query
				State.vpSkinCache = { type = "desc", data = desc }
				UI.vpSkinStatusLabel.Text = "from api: " .. tostring(resolvedId)
				UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(0, 220, 160)
			else
				UI.vpSkinStatusLabel.Text = "apply failed"
				UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			end
			return
		end

	
		local appearanceModel
		ok, result = pcall(function()
			appearanceModel = Services.Players:GetCharacterAppearanceAsync(resolvedId)
		end)
		if ok and appearanceModel then
			stripRigAppearance(rig)
			applyFromChar(rig, appearanceModel)
			State.vpSkinQuery = query
			State.vpSkinCache = { type = "char", data = appearanceModel }
			UI.vpSkinStatusLabel.Text = "from appearance: " .. tostring(resolvedId)
			UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(0, 220, 160)
			return
		end

		UI.vpSkinStatusLabel.Text = "failed to load skin"
		UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end)
end


local function resetDummySkin()
	if not Data.ghostChar then return end
	local rig = Data.ghostChar
	stripRigAppearance(rig)
	
	local head = rig:FindFirstChild("Head")
	if head and not rig:FindFirstChild("Nose") then
		local nose = Instance.new("Part")
		nose.Name = "Nose"
		nose.Size = Vector3.new(0.3, 0.3, 0.4)
		nose.BrickColor = BrickColor.new("Bright red")
		nose.Color = Color3.fromRGB(255, 0, 0)
		nose.Material = Enum.Material.SmoothPlastic
		nose.Anchored = false
		nose.CanCollide = false
		nose.CastShadow = false
		nose.Parent = rig
		local noseWeld = Instance.new("Weld")
		noseWeld.Part0 = head
		noseWeld.Part1 = nose
		noseWeld.C0 = CFrame.new(0, 0, -0.65)
		noseWeld.Parent = head
	end
	UI.vpSkinStatusLabel.Text = "reset to default"
	UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	UI.vpSkinInput.Text = ""
	State.vpSkinQuery = nil
	State.vpSkinCache = nil
end

local function reapplyCachedSkin(rig)
	local cache = State.vpSkinCache
	if not cache then return end
	stripRigAppearance(rig)
	if cache.type == "desc" then
		applyFromDescription(rig, cache.data)
	elseif cache.type == "char" then
		applyFromChar(rig, cache.data)
	end
end

local function previewAnim(id)
	if not id or id == "" then return end
	State.vpPaused = false
	UI.vpPauseBtn.Text = "⏸ Pause"
	UI.vpPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 60)
	nukeGhost()
	task.spawn(function()
		local rig, animator, rootPart = makeRig()
		if not rig or not animator then return end
		Data.ghostChar = rig
		Data.vpAnimator = animator
		Data.vpRootPart = rootPart
	
		reapplyCachedSkin(rig)
		vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, State.vpZoomDist), Vector3.new(0, 4, 0))
		task.wait(0.1)
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. id
		local track
		pcall(function() track = animator:LoadAnimation(anim) end)
		if track then
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = State.vpLooped
			track:Play(0, 1, tonumber(UI.vpSpeedBox.Text) or 1)
			Data.vpTrack = track
			local scrub = tonumber(UI.vpTimeBox.Text) or 0
			if scrub > 0 then
				task.defer(function()
					if Data.vpTrack then
						Data.vpTrack.TimePosition = math.clamp(scrub, 0, Data.vpTrack.Length)
					end
				end)
			end
		end
	end)
end

local function fmtTime(n)
	return string.format("%.2f", n)
end

table.insert(Data.connections, Services.RunService.RenderStepped:Connect(function()
	local mouse = Services.UserInputService:GetMouseLocation()

	if UI.viewportWin.Visible and Data.ghostChar then
		vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, State.vpZoomDist), Vector3.new(0, 4, 0))
	end

	if State.vpScrubbing then
		local bx = UI.vpScrubBg.AbsolutePosition.X
		local bw = UI.vpScrubBg.AbsoluteSize.X
		local rel = math.clamp((mouse.X - bx) / bw, 0, 1)
		if Data.vpTrack and Data.vpTrack.Length > 0 then
			State.vpPausedAt = rel * Data.vpTrack.Length
			Data.vpTrack.TimePosition = State.vpPausedAt
		elseif State.vpPaused and State.vpPausedLength > 0 then
			State.vpPausedAt = rel * State.vpPausedLength
			if Data.vpScrubTrack then
				Data.vpScrubTrack.TimePosition = State.vpPausedAt
			end
		end
	end

	if State.vpPaused and State.vpPausedLength > 0 then
		UI.vpScrubFill.Size = UDim2.new(math.clamp(State.vpPausedAt / State.vpPausedLength, 0, 1), 0, 1, 0)
		UI.vpScrubFill.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
	elseif Data.vpTrack and Data.vpTrack.Length > 0 then
		UI.vpScrubFill.Size = UDim2.new(math.clamp(Data.vpTrack.TimePosition / Data.vpTrack.Length, 0, 1), 0, 1, 0)
		UI.vpScrubFill.BackgroundColor3 = State.vpScrubbing and Color3.fromRGB(0, 180, 130) or Color3.fromRGB(0, 200, 150)
	elseif not State.vpScrubbing then
		UI.vpScrubFill.Size = UDim2.new(0, 0, 1, 0)
	end

	if State.vpPaused then
		UI.vpTimerLabel.Text = "⏸ " .. fmtTime(State.vpPausedAt) .. "s / " .. fmtTime(State.vpPausedLength) .. "s"
		UI.vpTimerLabel.TextColor3 = Color3.fromRGB(180, 120, 0)
	elseif Data.vpTrack then
		local pos = Data.vpTrack.TimePosition
		local len = Data.vpTrack.Length
		if Data.vpTrack.IsPlaying then
			if State.vpLooped and pos < State.vpLastPos and State.vpLastPos > 0.1 then
				State.vpLoopFlash = 0.25
			end
			State.vpLastPos = pos
			if State.vpLoopFlash > 0 then
				State.vpLoopFlash = math.max(0, State.vpLoopFlash - 0.016)
				local t = State.vpLoopFlash / 0.25
				UI.vpTimerLabel.TextColor3 = Color3.fromRGB(
					math.floor(0 + 255 * t),
					math.floor(220 + (255-220) * t),
					math.floor(160 + (100-160) * t))
			else
				UI.vpTimerLabel.TextColor3 = Color3.fromRGB(0, 220, 160)
			end
			UI.vpTimerLabel.Text = "▶ " .. fmtTime(pos) .. "s / " .. fmtTime(len) .. "s"
		else
			State.vpLastPos = 0
			UI.vpTimerLabel.Text = "stopped"
			UI.vpTimerLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		end
	else
		UI.vpTimerLabel.Text = "-- / --"
		UI.vpTimerLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
	end

	local activeTrack = nil
	local activeCount = 0
	for t in pairs(Data.scriptTracks) do
		if t.IsPlaying or (State.mainPaused and Data.scriptTracks[t]) then
			activeCount += 1
			if not activeTrack then activeTrack = t end
		end
	end
	if not activeTrack then
		for t in pairs(Data.scriptTracks) do
			activeTrack = t
			break
		end
	end

	if State.mainScrubbing and activeTrack and activeTrack.Length > 0 then
		local bx = UI.mainScrubBg.AbsolutePosition.X
		local bw = UI.mainScrubBg.AbsoluteSize.X
		local rel = math.clamp((mouse.X - bx) / bw, 0, 1)
		activeTrack.TimePosition = rel * activeTrack.Length
	end

	if activeTrack and activeTrack.Length > 0 then
		local pct = math.clamp(activeTrack.TimePosition / activeTrack.Length, 0, 1)
		UI.mainScrubFill.Size = UDim2.new(pct, 0, 1, 0)
		UI.mainScrubFill.BackgroundColor3 = State.mainPaused and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(0, 200, 150)
	else
		UI.mainScrubFill.Size = UDim2.new(0, 0, 1, 0)
	end

	if activeTrack and activeTrack.Length > 0 then
		local pos = activeTrack.TimePosition
		local len = activeTrack.Length
		local id = grabId(activeTrack.Animation.AnimationId) or "?"
		UI.mainTimerLabel.Text = (State.mainPaused and "⏸ " or "▶ ") .. id .. "  " .. fmtTime(pos) .. "s / " .. fmtTime(len) .. "s" .. (activeCount > 1 and ("  (+" .. (activeCount-1) .. ")") or "")
		UI.mainTimerLabel.TextColor3 = State.mainPaused and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(0, 220, 160)
	else
		UI.mainTimerLabel.Text = "no anim playing"
		UI.mainTimerLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
		if State.mainPaused then
			State.mainPaused = false
			UI.mainPauseBtn.Text = "⏸ Pause"
			UI.mainPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 55, 70)
		end
	end
end))

local function popPreview(id)
	State.vpCurrentId = id
	UI.vpIdLabel.Text = "ID: " .. id
	UI.vpTitle.Text = "preview — " .. id
	UI.vpIdInput.Text = id
	UI.viewportWin.Visible = true
	previewAnim(id)
end
table.insert(Data.connections, UI.vpIdGoBtn.MouseButton1Click:Connect(function()
	local id = grabId(UI.vpIdInput.Text)
	if id and id ~= "" then popPreview(id) end
end))
table.insert(Data.connections, UI.vpIdInput.FocusLost:Connect(function(enter)
	if enter then
		local id = grabId(UI.vpIdInput.Text)
		if id and id ~= "" then popPreview(id) end
	end
end))
table.insert(Data.connections, UI.vpPlayBtn.MouseButton1Click:Connect(function()
	if State.vpCurrentId then previewAnim(State.vpCurrentId) end
end))
table.insert(Data.connections, UI.vpStopBtn.MouseButton1Click:Connect(function()
	if Data.vpTrack then
		pcall(function() Data.vpTrack:Stop(0) end)
		Data.vpTrack = nil
	end
	nukeGhost()
end))
table.insert(Data.connections, UI.vpPlaySelfBtn.MouseButton1Click:Connect(function()
	if State.vpCurrentId then
		fireAnim(State.vpCurrentId, tonumber(UI.vpSpeedBox.Text) or 1, State.vpLooped)
	end
end))
table.insert(Data.connections, UI.vpRotateCCW.MouseButton1Click:Connect(function()
	local deg = tonumber(UI.vpPrecisionBox.Text) or 90
	State.vpYaw = State.vpYaw + math.rad(deg)
	if Data.vpRootPart then
		Data.vpRootPart.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, State.vpYaw, 0)
	end
end))
table.insert(Data.connections, UI.vpRotateCW.MouseButton1Click:Connect(function()
	local deg = tonumber(UI.vpPrecisionBox.Text) or 90
	State.vpYaw = State.vpYaw - math.rad(deg)
	if Data.vpRootPart then
		Data.vpRootPart.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, State.vpYaw, 0)
	end
end))
table.insert(Data.connections, UI.vpZoomIn.MouseButton1Click:Connect(function()
	local step = tonumber(UI.vpPrecisionBox.Text) or 2
	State.vpZoomDist = State.vpZoomDist - step
	vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, State.vpZoomDist), Vector3.new(0, 4, 0))
end))
table.insert(Data.connections, UI.vpZoomOut.MouseButton1Click:Connect(function()
	local step = tonumber(UI.vpPrecisionBox.Text) or 2
	State.vpZoomDist = State.vpZoomDist + step
	vpCamera.CFrame = CFrame.new(Vector3.new(0, 5, State.vpZoomDist), Vector3.new(0, 4, 0))
end))
table.insert(Data.connections, UI.vpSpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(UI.vpSpeedBox.Text:match("[%d%.]+"))
	if num and Data.vpTrack and Data.vpTrack.IsPlaying then
		Data.vpTrack:AdjustSpeed(num)
	end
end))
table.insert(Data.connections, UI.vpTimeBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(UI.vpTimeBox.Text:match("[%d%.]+"))
	if num and Data.vpTrack and Data.vpTrack.IsPlaying then
		Data.vpTrack.TimePosition = math.clamp(num, 0, Data.vpTrack.Length)
	end
end))
table.insert(Data.connections, UI.vpLoopToggle.MouseButton1Click:Connect(function()
	State.vpLooped = not State.vpLooped
	UI.vpLoopToggle.Text = "Loop: " .. (State.vpLooped and "ON" or "OFF")
	UI.vpLoopToggle.BackgroundColor3 = State.vpLooped and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
	UI.vpLoopToggle.BorderColor3 = State.vpLooped and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
	if Data.vpTrack then Data.vpTrack.Looped = State.vpLooped end
end))
table.insert(Data.connections, UI.previewToggle.MouseButton1Click:Connect(function()
	UI.viewportWin.Visible = not UI.viewportWin.Visible
end))
table.insert(Data.connections, UI.vpSkinLoadBtn.MouseButton1Click:Connect(function()
	local query = UI.vpSkinInput.Text:match("^%s*(.-)%s*$")
	if query == "" then
		UI.vpSkinStatusLabel.Text = "enter a username or userid"
		UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
		return
	end
	if not Data.ghostChar then
		UI.vpSkinStatusLabel.Text = "load an animation first"
		UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
		return
	end
	applyPlayerSkin(query)
end))
table.insert(Data.connections, UI.vpSkinInput.FocusLost:Connect(function(enter)
	if enter then
		local query = UI.vpSkinInput.Text:match("^%s*(.-)%s*$")
		if query ~= "" and Data.ghostChar then
			applyPlayerSkin(query)
		end
	end
end))
table.insert(Data.connections, UI.vpSkinResetBtn.MouseButton1Click:Connect(function()
	resetDummySkin()
end))
local function addReplUI(id, targetId, speed, loop, enabled)
	if enabled == nil then enabled = true end
	local rFrame = Instance.new("Frame")
	rFrame.Size = UDim2.new(1, 0, 0, 145)
	rFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	rFrame.BorderSizePixel = 0
	rFrame.ZIndex = 3
	rFrame.Parent = UI.sideList
	mkCorner(rFrame, 4)
	mkStroke(rFrame, Color3.fromRGB(60, 60, 0), 1)
	local replaceL = Instance.new("TextBox")
	replaceL.Size = UDim2.new(1, -10, 0, 20)
	replaceL.Position = UDim2.new(0, 5, 0, 5)
	replaceL.Text = id or ""
	replaceL.PlaceholderText = "replace anim id..."
	replaceL.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	replaceL.TextColor3 = Color3.new(1, 1, 1)
	replaceL.Font = Enum.Font.Code
	replaceL.BorderSizePixel = 0
	replaceL.ZIndex = 4
	replaceL.Parent = rFrame
	mkCorner(replaceL, 3)
	mkStroke(replaceL, Color3.fromRGB(0, 80, 90), 1)
	local targetL = Instance.new("TextBox")
	targetL.Size = UDim2.new(1, -10, 0, 20)
	targetL.Position = UDim2.new(0, 5, 0, 30)
	targetL.Text = targetId or ""
	targetL.PlaceholderText = "target anim id..."
	targetL.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	targetL.TextColor3 = Color3.new(1, 1, 1)
	targetL.Font = Enum.Font.Code
	targetL.BorderSizePixel = 0
	targetL.ZIndex = 4
	targetL.Parent = rFrame
	mkCorner(targetL, 3)
	mkStroke(targetL, Color3.fromRGB(0, 80, 90), 1)
	local speedL = Instance.new("TextBox")
	speedL.Size = UDim2.new(0.5, -10, 0, 20)
	speedL.Position = UDim2.new(0, 5, 0, 55)
	speedL.Text = tostring(speed or 1)
	speedL.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	speedL.TextColor3 = Color3.new(1, 1, 1)
	speedL.BorderSizePixel = 0
	speedL.ZIndex = 4
	speedL.Parent = rFrame
	mkCorner(speedL, 3)
	mkStroke(speedL, Color3.fromRGB(0, 80, 90), 1)
	local loopT = Instance.new("TextButton")
	loopT.Size = UDim2.new(0.5, -10, 0, 20)
	loopT.Position = UDim2.new(0.5, 5, 0, 55)
	loopT.Text = "Loop: " .. (loop and "ON" or "OFF")
	loopT.BackgroundColor3 = loop and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
	loopT.TextColor3 = Color3.new(1, 1, 1)
	loopT.BorderSizePixel = 0
	loopT.ZIndex = 4
	loopT.Parent = rFrame
	mkCorner(loopT, 3)
	local enableT = Instance.new("TextButton")
	enableT.Size = UDim2.new(1, -10, 0, 20)
	enableT.Position = UDim2.new(0, 5, 0, 80)
	enableT.Text = enabled and "Enabled: ON" or "Enabled: OFF"
	enableT.BackgroundColor3 = enabled and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
	enableT.TextColor3 = Color3.new(1, 1, 1)
	enableT.Font = Enum.Font.Code
	enableT.TextSize = 11
	enableT.BorderSizePixel = 0
	enableT.ZIndex = 4
	enableT.Parent = rFrame
	mkCorner(enableT, 3)
	local del = Instance.new("TextButton")
	del.Size = UDim2.new(1, -10, 0, 20)
	del.Position = UDim2.new(0, 5, 0, 105)
	del.Text = "Delete Replacement"
	del.BackgroundColor3 = Color3.fromRGB(120, 15, 15)
	del.TextColor3 = Color3.new(1, 1, 1)
	del.Font = Enum.Font.Code
	del.TextSize = 11
	del.BorderSizePixel = 0
	del.ZIndex = 5
	del.Parent = rFrame
	mkCorner(del, 3)
	local function updateRep()
		local oldId = id
		id = replaceL.Text
		if oldId and oldId ~= id then Data.replacements[oldId] = nil end
		Data.replacements[id] = { targetId = targetL.Text, speed = tonumber(speedL.Text) or 1, loop = loop, enabled = enabled }
		dumpCfg()
	end
	table.insert(Data.connections, replaceL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(Data.connections, targetL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(Data.connections, speedL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(Data.connections, loopT.MouseButton1Click:Connect(function()
		loop = not loop
		loopT.Text = "Loop: " .. (loop and "ON" or "OFF")
		loopT.BackgroundColor3 = loop and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
		updateRep()
	end))
	table.insert(Data.connections, enableT.MouseButton1Click:Connect(function()
		enabled = not enabled
		enableT.Text = enabled and "Enabled: ON" or "Enabled: OFF"
		enableT.BackgroundColor3 = enabled and Color3.fromRGB(0, 55, 0) or Color3.fromRGB(55, 0, 0)
		updateRep()
	end))
	table.insert(Data.connections, del.MouseButton1Click:Connect(function()
		Data.replacements[id] = nil
		rFrame:Destroy()
		dumpCfg()
	end))
end
table.insert(Data.connections, UI.addR.MouseButton1Click:Connect(function()
	addReplUI("", "", 1, false, true)
end))
local sideList = UI.sideList
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
	table.insert(Data.bindIndicators, bindData)
	local settingKey = false
	table.insert(Data.connections, keyB.MouseButton1Click:Connect(function()
		settingKey = true
		keyB.Text = "Press a key..."
	end))
	table.insert(Data.connections, Services.UserInputService.InputBegan:Connect(function(input)
		if settingKey and input.UserInputType == Enum.UserInputType.Keyboard then
			settingKey = false
			bindData.key = input.KeyCode
			keyB.Text = "Key: " .. input.KeyCode.Name
			dumpBinds()
		end
	end))
	table.insert(Data.connections, idL:GetPropertyChangedSignal("Text"):Connect(function()
		bindData.id = idL.Text
		dumpBinds()
	end))
	table.insert(Data.connections, holdT.MouseButton1Click:Connect(function()
		bindData.hold = not bindData.hold
		holdT.Text = "Hold: " .. (bindData.hold and "ON" or "OFF")
		holdT.BackgroundColor3 = bindData.hold and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
		dumpBinds()
	end))
	table.insert(Data.connections, speedB:GetPropertyChangedSignal("Text"):Connect(function()
		bindData.speed = tonumber(speedB.Text:match("[%d%.]+")) or 1
		dumpBinds()
	end))
	table.insert(Data.connections, loopT.MouseButton1Click:Connect(function()
		bindData.loop = not bindData.loop
		loopT.Text = "Loop: " .. (bindData.loop and "ON" or "OFF")
		loopT.BackgroundColor3 = bindData.loop and Color3.fromRGB(0, 60, 0) or Color3.fromRGB(60, 0, 0)
		dumpBinds()
	end))
	table.insert(Data.connections, del.MouseButton1Click:Connect(function()
		killAnim(bindData.id)
		for i, v in pairs(Data.keybinds) do
			if v == bindData then
				table.remove(Data.keybinds, i)
				break
			end
		end
		bFrame:Destroy()
		dumpBinds()
	end))
end
table.insert(Data.connections, UI.addB.MouseButton1Click:Connect(function()
	local nb = {id = "", key = nil, hold = false, speed = 1, loop = false, active = false, tracks = {}, token = 0}
	table.insert(Data.keybinds, nb)
	addBind(nb)
end))
local function addFavRow(id, displayName)
	if Data.favoriteEntries[id] then return end
	local fFrame = Instance.new("Frame")
	fFrame.Name = "fav_" .. id
	fFrame.Size = UDim2.new(1, -5, 0, 25)
	fFrame.BackgroundTransparency = 1
	fFrame.ZIndex = 3
	fFrame.Parent = UI.favsList
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
	Data.favoriteEntries[id] = fFrame
	table.insert(Data.connections, fBtn.MouseButton1Click:Connect(function()
		UI.idBox.Text = id
	end))
	table.insert(Data.connections, fPreviewBtn.MouseButton1Click:Connect(function()
		popPreview(id)
	end))
	table.insert(Data.connections, fCopyBtn.MouseButton1Click:Connect(function()
		yoink(id)
	end))
end
local function killFavRow(id)
	if Data.favoriteEntries[id] then
		Data.favoriteEntries[id]:Destroy()
		Data.favoriteEntries[id] = nil
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
	entryFrame.Parent = UI.list
	local entry = Instance.new("TextButton")
	entry.Size = UDim2.new(1, -142, 1, 0)
	entry.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
	entry.TextColor3 = Color3.fromRGB(0, 255, 200)
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.Text = "(1) [" .. (priority or "N/A") .. "] " .. id .. " | " .. name .. " @" .. (Data.animTimestamps[key] or os.date("%H:%M:%S"))
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
	favBtn.Text = Data.favorites[id] and "★" or "☆"
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
	table.insert(Data.connections, entry.MouseButton1Click:Connect(function()
		UI.idBox.Text = id
	end))
	table.insert(Data.connections, previewBtn.MouseButton1Click:Connect(function()
		popPreview(id)
	end))
	table.insert(Data.connections, favBtn.MouseButton1Click:Connect(function()
		Data.favorites[id] = not Data.favorites[id]
		favBtn.Text = Data.favorites[id] and "★" or "☆"
		if Data.favorites[id] then
			addFavRow(id, Data.customNames[id] or name)
		else
			killFavRow(id)
		end
		dumpCfg()
	end))
	table.insert(Data.connections, nameBtn.MouseButton1Click:Connect(function()
		local nameInput = Instance.new("TextBox")
		nameInput.Text = Data.customNames[id] or ""
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
				Data.customNames[id] = newName
				entry.Text = "(" .. (Data.animCounts[key] or 1) .. ") [" .. (priority or "N/A") .. "] " .. id .. " | " .. newName .. " (" .. name .. ") @" .. (Data.animTimestamps[key] or "?")
				if Data.favoriteEntries[id] then
					local fBtn = Data.favoriteEntries[id]:FindFirstChildOfClass("TextButton")
					if fBtn then fBtn.Text = "★ " .. id .. " | " .. newName end
				end
				dumpCfg()
			end
		end
		table.insert(Data.connections, nameInput.FocusLost:Connect(function()
			applyName()
		end))
	end))
	table.insert(Data.connections, copyBtn.MouseButton1Click:Connect(function()
		yoink(id)
	end))
	Data.animFrames[key] = entry
	local n = 0
	for _ in pairs(Data.animFrames) do n += 1 end
	UI.logCountLabel.Text = n .. " logged"
end
local function fixPriority(raw)
	local PRIORITY_NAMES = {
		Action="game", Action2="game2", Action3="game3", Action4="game4",
		Core="coreanims", Idle="idle", Movement="movement",
	}
	return PRIORITY_NAMES[raw] or raw or "?"
end
local function checkLoopDetect(id, key)
	local isScriptAnim = false
	local animator = grabAnimator()
	if animator then
		for _, t in pairs(animator:GetPlayingAnimationTracks()) do
			if Data.scriptTracks[t] and grabId(t.Animation.AnimationId) == id then
				isScriptAnim = true
				break
			end
		end
	end
	if isScriptAnim then return end
	local now = tick()
	if Data.animLastFired[key] then
		local interval = now - Data.animLastFired[key]
		if interval > 0.3 and interval < 30 then
			if not Data.animFireIntervals[key] then Data.animFireIntervals[key] = {} end
			table.insert(Data.animFireIntervals[key], interval)
			if #Data.animFireIntervals[key] > 5 then table.remove(Data.animFireIntervals[key], 1) end
			if #Data.animFireIntervals[key] >= 3 then
				local avg = 0
				for _, v in ipairs(Data.animFireIntervals[key]) do avg += v end
				avg = avg / #Data.animFireIntervals[key]
				local consistent = true
				for _, v in ipairs(Data.animFireIntervals[key]) do
					if math.abs(v - avg) > avg * 0.3 then consistent = false break end
				end
				if consistent then
					Data.loopingAnims[key] = true
					local entry = Data.animFrames[key]
					if entry and not entry.Text:find("\xe2\x86\xbb") then
						entry.Text = "\xe2\x86\xbb " .. entry.Text
					end
				end
			end
		end
	end
	Data.animLastFired[key] = now
end

local function logIt(id, name, playerName, priority)
	if Data.banned[id] then return end
	if Data.trueBanned[id] then return end
	if Data.logBlacklist[id] then return end  
	local entryName = name
	local key = id
	if playerName then
		key = id .. "_" .. playerName
		if playerName ~= player.Name then
			entryName = "[" .. playerName .. "] " .. name
		end
	end
	if Data.customNames[id] then
		entryName = Data.customNames[id] .. " (" .. entryName .. ")"
	end
	if State.autoCopy then yoink(id) end
	checkLoopDetect(id, key)
	if not Data.animCounts[key] then
		Data.animCounts[key] = 1
		Data.animTimestamps[key] = os.date("%H:%M:%S")
		addLogRow(id, entryName, key, priority)
	else
		Data.animCounts[key] += 1
		Data.animTimestamps[key] = os.date("%H:%M:%S")
		local entry = Data.animFrames[key]
		if entry then
			local prefix = Data.loopingAnims[key] and "\xe2\x86\xbb " or ""
			entry.Text = prefix .. "(" .. Data.animCounts[key] .. ") [" .. (priority or "N/A") .. "] " .. id .. " | " .. entryName .. " @" .. Data.animTimestamps[key]
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
	for id, entry in pairs(Data.animFrames) do
		local pureId = id:match("^([%d]+)")
		if Data.trueBanned[pureId] then
			entry.TextColor3 = Color3.fromRGB(180, 0, 0)
		elseif Data.banned[pureId] then
			entry.TextColor3 = Color3.fromRGB(255, 50, 50)
		elseif Data.logBlacklist[pureId] then
			
			entry.TextColor3 = Color3.fromRGB(180, 100, 255)
		elseif playingIds[pureId] then
			entry.TextColor3 = Color3.fromRGB(50, 255, 50)
		else
			entry.TextColor3 = Color3.fromRGB(0, 255, 200)
		end
	end
end
task.spawn(function()
	while State.running do
		refreshColors()
		for _, bind in pairs(Data.bindIndicators) do
			if bind._activeBar and bind._activeBar.Parent then
				bind._activeBar.BackgroundColor3 = bind.active
					and Color3.fromRGB(0, 220, 100)
					or Color3.fromRGB(40, 40, 40)
			end
		end
		task.wait(0.1)
	end
end)
local function fireReplacement(id, rep)
	local targetId = rep.targetId
	if State.replacementFrozen then return end
	Data.replacingTargets[targetId] = true
	local animator = grabAnimator()
	if not animator then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. targetId
	local newTrack = animator:LoadAnimation(anim)
	Data.scriptTracks[newTrack] = true
	newTrack.Priority = Enum.AnimationPriority.Action4
	newTrack.Looped = rep.loop or false
	newTrack:Play(0, 1, rep.speed or 1)
	newTrack.Stopped:Connect(function()
		Data.scriptTracks[newTrack] = nil
		Data.replacingTargets[targetId] = nil
		State.replacementFrozen = true
		task.delay(0.5, function() State.replacementFrozen = false end)
	end)
end

local function stopTrack(track)
	track:AdjustWeight(0, 0)
	track:AdjustSpeed(0)
	track:Stop(0)
end

local function trackSeen(track, playerName)
	local anim = track.Animation
	if not anim then return end
	local id = grabId(anim.AnimationId)
	if not id then return end
	
	if Data.banned[id] or Data.trueBanned[id] then stopTrack(track); return end
	
	if Data.logBlacklist[id] then
		if not Data.seenTracks[track] then
			Data.seenTracks[track] = true
			local conn
			conn = track.Stopped:Connect(function()
				Data.seenTracks[track] = nil
				if conn then conn:Disconnect() end
			end)
		end
		return
	end
	if Data.replacements[id] and playerName == player.Name and not Data.scriptTracks[track] then
		local rep = Data.replacements[id]
		if rep.enabled ~= false then
			stopTrack(track)
			Data.seenTracks[track] = true
			fireReplacement(id, rep)
			return
		end
	end
	if playerName ~= player.Name and not State.globalLogging then return end
	if Data.seenTracks[track] then return end
	Data.seenTracks[track] = true
	logIt(id, anim.Name or "Unknown", playerName, fixPriority(track.Priority.Name))
	local conn
	conn = track.Stopped:Connect(function()
		Data.seenTracks[track] = nil
		if conn then
			for i, v in ipairs(Data.connections) do
				if v == conn then
					table.remove(Data.connections, i)
					break
				end
			end
			conn:Disconnect()
		end
	end)
	table.insert(Data.connections, conn)
end

local function suppressCompeting(track)
	track:AdjustWeight(0, 0)
	track:AdjustSpeed(0)
	track:Stop(0)
	for t in pairs(Data.scriptTracks) do
		if t.IsPlaying then t:AdjustWeight(1, 0) end
	end
end

local function hookAnimator(animator, playerName)
	if not animator then return end
	table.insert(Data.connections, animator.AnimationPlayed:Connect(function(track)
		if playerName == player.Name then
			local scriptAnimActive = false
			for t in pairs(Data.scriptTracks) do
				if t.IsPlaying then scriptAnimActive = true; break end
			end
			if scriptAnimActive and not Data.scriptTracks[track] then
				suppressCompeting(track)
				return
			end
		end
		trackSeen(track, playerName)
	end))
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		trackSeen(track, playerName)
	end
end
local function onJoin(p)
	table.insert(Data.connections, p.CharacterAdded:Connect(function(char)
		if p == player then
			for _, bind in pairs(Data.keybinds) do
				bind.active = false
			end
			Data.scriptTracks = {}
		end
		task.wait(1)
		hookAnimator(grabAnimator(char), p.Name)
	end))
	if p.Character then
		hookAnimator(grabAnimator(p.Character), p.Name)
	end
end
table.insert(Data.connections, Services.Players.PlayerAdded:Connect(onJoin))
for _, p in pairs(Services.Players:GetPlayers()) do
	onJoin(p)
end
task.spawn(function()
	while State.running do
		for _, bind in pairs(Data.keybinds) do
			if bind.active and bind.hold and not Data.banned[bind.id] then
				local isMacroCheck = tostring(bind.id):find(";") or tostring(bind.id):lower():match("^play%s")
				if not isMacroCheck then
					local isPlaying = false
					local animator = grabAnimator()
					if animator then
						for _, t in pairs(animator:GetPlayingAnimationTracks()) do
							if grabId(t.Animation.AnimationId) == bind.id and t.IsPlaying then
								isPlaying = true
								if State.isFrozen then t:AdjustSpeed(0) end
								break
							end
						end
					end
					if not isPlaying then
						fireAnim(bind.id, bind.speed, bind.loop)
					end
				end
			elseif bind.active and not bind.hold and not Data.banned[bind.id] then
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
			State.isFrozen = false
		else
			State.isFrozen = not State.isFrozen
		end
		for track in pairs(Data.scriptTracks) do
			if track.IsPlaying then track:AdjustSpeed(State.isFrozen and 0 or 1) end
		end
	elseif action == "speed" and not isRelease then
		local num = tonumber(parts[2])
		if num then
			for track in pairs(Data.scriptTracks) do
				if track.IsPlaying then track:AdjustSpeed(num) end
			end
		end
	elseif action == "ban" and not isRelease then
		local id = parts[2]
		if id then Data.banned[id] = true; killAnim(id); dumpCfg() end
	elseif action == "unban" and not isRelease then
		local id = parts[2]
		if id then Data.banned[id] = nil; dumpCfg() end
	elseif action == "stop" and not isRelease then
		local id = parts[2]
		if id then killAnim(id) end
	elseif action == "step" and not isRelease then
		local num = tonumber(parts[2]) or 0.1
		for track in pairs(Data.scriptTracks) do
			if track.IsPlaying then
				track.TimePosition = math.clamp(track.TimePosition + num, 0, track.Length)
			end
		end
	elseif action == "loop" and not isRelease then
		State.looped = not State.looped
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
					for track in pairs(Data.scriptTracks) do pcall(function() track:Stop() end) end
					Data.scriptTracks = {}
				end
			elseif cmd == "speed" then
				local num = tonumber(parts[2])
				if num then
					for track in pairs(Data.scriptTracks) do
						if track.IsPlaying then track:AdjustSpeed(num) end
					end
				end
			elseif cmd == "loop" then
				State.looped = not State.looped
				refreshLoopBtn()
			elseif cmd == "freeze" or cmd == "pause" then
				State.isFrozen = not State.isFrozen
				for track in pairs(Data.scriptTracks) do
					if track.IsPlaying then track:AdjustSpeed(State.isFrozen and 0 or 1) end
				end
			end
		end
		stopFlag.active = false
	end)
end
local function isCmd(str)
	local COMMAND_PREFIXES = {"pause", "freeze", "speed", "ban", "unban", "stop", "step", "loop", "clear"}
	local low = str:lower()
	for _, c in pairs(COMMAND_PREFIXES) do
		if low:match("^" .. c) then return true end
	end
	return false
end
table.insert(Data.connections, Services.UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for _, bind in pairs(Data.keybinds) do
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
						State.isFrozen = true
						for track in pairs(Data.scriptTracks) do
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
table.insert(Data.connections, Services.UserInputService.InputEnded:Connect(function(input)
	for _, bind in pairs(Data.keybinds) do
		if bind.key and input.KeyCode == bind.key then
			local idStr = tostring(bind.id)
			if isMacro(idStr) then
				if bind.macroFlag then bind.macroFlag.active = false end
			elseif isCmd(idStr) then
				if bind.hold then
					local low = idStr:lower()
					if low:match("^pause") or low:match("^freeze") then
						State.isFrozen = false
						for track in pairs(Data.scriptTracks) do
							if track.IsPlaying then track:AdjustSpeed(1) end
						end
					end
				end
			else
				if bind.hold then
					bind.active = false
					bind.token = (bind.token or 0) + 1
					for t in pairs(Data.scriptTracks) do
						if grabId(t.Animation.AnimationId) == bind.id then
							Data.scriptTracks[t] = nil
							pcall(function() t:Stop(0) end)
						end
					end
				end
			end
		end
	end
end))
local function loadSavedBinds()
	if readfile and isfile and isfile(State.keybindFile) then
		local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(State.keybindFile)) end)
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
				table.insert(Data.keybinds, nb)
				addBind(nb)
			end
		end
	end
end
local function loadCfg()
	if readfile and isfile and isfile(State.configFile) then
		local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(State.configFile)) end)
		if ok and type(data) == "table" then
			State.looped = data.looped or false
			State.globalLogging = data.globalLogging or false
			State.autoCopy = data.autoCopy or false
			Data.banned = data.banned or {}
			Data.trueBanned = data.trueBanned or {}
			Data.logBlacklist = data.logBlacklist or {}  
			if data.toggleKey and Enum.KeyCode[data.toggleKey] then
				State.toggleKey = Enum.KeyCode[data.toggleKey]
			end
			Data.replacements = data.replacements or {}
			Data.favorites = data.favorites or {}
			Data.customNames = data.customNames or {}
			refreshLoopBtn()
			refreshGlobalBtn()
			refreshAutoCopyBtn()
			for id, rep in pairs(Data.replacements) do
				addReplUI(id, rep.targetId, rep.speed, rep.loop, rep.enabled ~= false)
			end
			for id, isFav in pairs(Data.favorites) do
				if isFav then addFavRow(id, Data.customNames[id] or id) end
			end
		end
	end
end
loadCfg()
UI.toggleKeyBtn.Text = "Hide Key: " .. State.toggleKey.Name
loadSavedBinds()
loadGroups()
local function tickLoop()
	for _, p in pairs(Services.Players:GetPlayers()) do
		local isLocal = (p == player)
		local animator = grabAnimator(p.Character)
		if animator then
			local scriptAnimActive = false
			if isLocal then
				for t in pairs(Data.scriptTracks) do
					if t.IsPlaying then
						scriptAnimActive = true
						break
					end
				end
			end
			for _, track in pairs(animator:GetPlayingAnimationTracks()) do
				local tid = grabId(track.Animation.AnimationId)
				if tid and (Data.banned[tid] or Data.trueBanned[tid]) then
					track:AdjustWeight(0, 0)
					track:AdjustSpeed(0)
					track:Stop(0)
					continue
				end
				if isLocal and tid and Data.replacements[tid] and Data.replacements[tid].enabled ~= false and (Data.replacingTargets[Data.replacements[tid].targetId] or State.replacementFrozen) then
					track:AdjustWeight(0, 0)
					track:AdjustSpeed(0)
					track:Stop(0)
					continue
				end
				if isLocal and scriptAnimActive and not Data.scriptTracks[track] then
					track:AdjustWeight(0, 0)
					track:AdjustSpeed(0)
					track:Stop(0)
				elseif State.globalLogging or isLocal then
					trackSeen(track, p.Name)
				end
			end
		end
	end
end
table.insert(Data.connections, Services.RunService.Stepped:Connect(tickLoop))
table.insert(Data.connections, Services.RunService.RenderStepped:Connect(tickLoop))
