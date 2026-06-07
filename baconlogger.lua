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
	advReplacements = {},
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
	spawnDummy = nil,
	spawnDummyAnimator = nil,
	spawnDummyTrack = nil,
	vpTrack = nil,
	vpAnimator = nil,
	vpRootPart = nil,
	vpScrubTrack = nil,
	dummyTracks = {},
	logOrder = 0,         
    
	logLastMove = {},     
    
}

local function cleanupOldUI()
	local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if success and coreGui then
		local existing = coreGui:FindFirstChild("BaconLoggerGui")
		if existing then pcall(function() existing:Destroy() end) end
	end
	local success2, playerGui = pcall(function() return game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") end)
	if success2 and playerGui then
		local existing = playerGui:FindFirstChild("BaconLoggerGui")
		if existing then pcall(function() existing:Destroy() end) end
	end
end
cleanupOldUI()

local State = {
	replacementFrozen = false,
	looped = false,
	globalLogging = false,
	isFrozen = false,
	autoCopy = false,
	filterPlayer = "",
	filterPriority = "",
	advancedFilters = {
		enabled = false,
		currentPreset = "Default",
		presets = {
			["Default"] = {
				name = "Default",
				filters = {
					{type = "search", param = "", enabled = true},
					{type = "player", param = "", enabled = true},
					{type = "priority", param = "", enabled = true}
				},
				logic = "AND"
			}
		},
		activeFilters = {
			{type = "search", param = "", enabled = true},
			{type = "player", param = "", enabled = true},
			{type = "priority", param = "", enabled = true}
		},
		logic = "AND"
	},
	performance = {
		enabled = true,
		frameTimes = {},
		fps = 0,
		avgFrameTime = 0,
		activeScriptTracks = 0,
		peakScriptTracks = 0,
		totalScriptTracks = 0,
		animTrackCount = 0,
		totalLogs = 0,
		logRate = 0,
		frameCount = 0,
		droppedFrames = 0,
		logTickStart = tick(),
		lastLogTick = tick(),
		history = {}
	},
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
	vpPitch = 0,
	vpZoomDist = 11,
	vpRigType = "R6",
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
		advReplacements = Data.advReplacements,
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
				if v == conn then table.remove(Data.connections, i); break end
			end
			conn:Disconnect()
		end

		local anyLeft = false
		for _ in pairs(Data.scriptTracks) do anyLeft = true; break end
		if not anyLeft and State.mainPaused then
			State.mainPaused = false
			UI.mainPauseBtn.Text = "⏸ Pause"
			UI.mainPauseBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
			UI.mainPauseBtn.TextColor3 = Color3.fromRGB(180,180,180)
		end
		if loop and not Data.banned[id] and not intentional then
			local holdBindOwns = false
			for _, bind in pairs(Data.keybinds) do
				if grabId(tostring(bind.id)) == id and bind.hold then
					holdBindOwns = true; break
				end
			end
			if not holdBindOwns then
				task.defer(function() fireAnim(id, speed, loop) end)
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

local function mkCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 4)
	c.Parent = parent
end
local function mkStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(65,65,65)
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

UI.mainFrame = Instance.new("Frame")
UI.mainFrame.Name = "MainFrame"
UI.mainFrame.Size = UDim2.new(0, 820, 0, 630)
UI.mainFrame.Position = UDim2.new(0, 50, 0, 50)
UI.mainFrame.BackgroundColor3 = Color3.fromRGB(14,14,14)
UI.mainFrame.BackgroundTransparency = 0.15
UI.mainFrame.BorderSizePixel = 0
UI.mainFrame.Active = true
UI.mainFrame.Draggable = false
UI.mainFrame.ClipsDescendants = true
UI.mainFrame.ZIndex = 1
UI.mainFrame.Parent = UI.gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = UI.mainFrame
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(65,65,65); s.Thickness = 1.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.mainFrame
end

UI.notifLabel.Size = UDim2.new(0, 400, 0, 32)
UI.notifLabel.AnchorPoint = Vector2.new(0.5, 0)
UI.notifLabel.Position = UDim2.new(0.5, 0, 0, 8)
UI.notifLabel.BackgroundColor3 = Color3.fromRGB(42,42,42)
UI.notifLabel.BackgroundTransparency = 1
UI.notifLabel.TextColor3 = Color3.fromRGB(210,210,210)
UI.notifLabel.Font = Enum.Font.GothamSemibold
UI.notifLabel.TextSize = 13
UI.notifLabel.Text = ""
UI.notifLabel.ZIndex = 100
UI.notifLabel.Visible = false
UI.notifLabel.Parent = UI.gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = UI.notifLabel
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(65,65,65); s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.notifLabel
end
local function flashNotif(msg, duration, color, level)
	duration = duration or 3
	level = (level or "info"):lower()
	local levelColors = {
		info = Color3.fromRGB(170,170,170),
		success = Color3.fromRGB(140,210,145),
		warn = Color3.fromRGB(230,190,120),
		error = Color3.fromRGB(210,130,130)
	}
	color = color or levelColors[level] or Color3.fromRGB(210,210,210)
	UI.notifLabel.Text = tostring(msg)
	UI.notifLabel.TextColor3 = color
	UI.notifLabel.BackgroundTransparency = 0
	UI.notifLabel.Visible = true
	if UI.notifThread then task.cancel(UI.notifThread) end
	local startTime = tick()
	UI.notifThread = task.spawn(function()
		local fadeIn = 0.2
		local fadeOut = 0.3
		local hold = duration - fadeIn - fadeOut
		if hold < 0 then hold = 0 end
		local elapsed = 0
		while elapsed < fadeIn do
			elapsed = tick() - startTime
			local t = elapsed / fadeIn
			UI.notifLabel.BackgroundTransparency = 1 - t
			task.wait()
		end
		task.wait(hold)
		local fadeStart = tick()
		while elapsed < duration do
			elapsed = tick() - startTime
			local t = (elapsed - (duration - fadeOut)) / fadeOut
			if t > 0 then
				UI.notifLabel.BackgroundTransparency = t
			end
			task.wait()
		end
		UI.notifLabel.Visible = false
		UI.notifLabel.Text = ""
		UI.notifLabel.BackgroundTransparency = 1
	end)
end

local function dragMain(input)
	local delta = input.Position - State.dragStart
	UI.mainFrame.Position = UDim2.new(State.startPos.X.Scale, State.startPos.X.Offset + delta.X, State.startPos.Y.Scale, State.startPos.Y.Offset + delta.Y)
end
table.insert(Data.connections, UI.mainFrame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UI.activeDragger then
		UI.activeDragger = "main"; State.dragging = true; State.dragStart = input.Position; State.startPos = UI.mainFrame.Position
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
UI.resizeHandle.BackgroundColor3 = Color3.fromRGB(42,42,42)
UI.resizeHandle.Text = ""
UI.resizeHandle.BorderSizePixel = 0
UI.resizeHandle.ZIndex = 10
UI.resizeHandle.Parent = UI.mainFrame
mkCorner(UI.resizeHandle, 3)
do
	local grip = Instance.new("TextLabel"); grip.Text = "⠿"; grip.Size = UDim2.new(1,0,1,0)
	grip.BackgroundTransparency = 1; grip.TextColor3 = Color3.fromRGB(95,95,95)
	grip.Font = Enum.Font.Code; grip.TextSize = 11; grip.ZIndex = 11; grip.Parent = UI.resizeHandle
end
table.insert(Data.connections, UI.resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.resizing = true; State.resizeStart = input.Position; State.resizeStartSize = UI.mainFrame.AbsoluteSize
	end
end))
table.insert(Data.connections, Services.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		State.resizing = false; UI.activeDragger = nil
	end
end))
table.insert(Data.connections, Services.UserInputService.InputChanged:Connect(function(input)
	if State.resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - State.resizeStart
		UI.mainFrame.Size = UDim2.new(0, math.max(600, State.resizeStartSize.X + delta.X), 0, math.max(400, State.resizeStartSize.Y + delta.Y))
	end
end))

UI.top = Instance.new("Frame")
UI.top.Name = "TopBar"; UI.top.Size = UDim2.new(1,0,0,28); UI.top.BackgroundColor3 = Color3.fromRGB(20,20,20); UI.top.BackgroundTransparency = 0
UI.top.BorderSizePixel = 0; UI.top.ZIndex = 3; UI.top.Parent = UI.mainFrame
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(20,20,20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,8))})
	g.Rotation = 90; g.Parent = UI.top
end
UI.title = Instance.new("TextLabel")
UI.title.Text = "bacons advanced logger or wtv"
UI.title.Size = UDim2.new(1,-220,1,0); UI.title.Position = UDim2.new(0,10,0,0)
UI.title.BackgroundTransparency = 1; UI.title.TextColor3 = Color3.fromRGB(210,210,210)
UI.title.Font = Enum.Font.GothamBold; UI.title.TextSize = 15; UI.title.TextXAlignment = Enum.TextXAlignment.Left
UI.title.ZIndex = 3; UI.title.Parent = UI.top

UI.closeButton = Instance.new("TextButton")
UI.closeButton.Size = UDim2.new(0,26,0,20); UI.closeButton.Position = UDim2.new(1,-28,0,4)
UI.closeButton.Text = "X"; UI.closeButton.BackgroundColor3 = Color3.fromRGB(120,30,30)
UI.closeButton.TextColor3 = Color3.fromRGB(255,255,255); UI.closeButton.BorderSizePixel = 0
UI.closeButton.Font = Enum.Font.GothamSemibold; UI.closeButton.TextSize = 13; UI.closeButton.ZIndex = 3; UI.closeButton.Parent = UI.top
mkCorner(UI.closeButton, 4)

UI.minimize = Instance.new("TextButton")
UI.minimize.Size = UDim2.new(0,26,0,20); UI.minimize.Position = UDim2.new(1,-56,0,4)
UI.minimize.Text = "-"; UI.minimize.BackgroundColor3 = Color3.fromRGB(22,38,24)
UI.minimize.TextColor3 = Color3.fromRGB(140,210,145); UI.minimize.BorderSizePixel = 0
UI.minimize.Font = Enum.Font.GothamSemibold; UI.minimize.TextSize = 13; UI.minimize.ZIndex = 3; UI.minimize.Parent = UI.top
mkCorner(UI.minimize, 4); mkStroke(UI.minimize, Color3.fromRGB(45,80,48), 1)

UI.openSide = Instance.new("TextButton")
UI.openSide.Size = UDim2.new(0,52,0,20); UI.openSide.Position = UDim2.new(1,-110,0,4)
UI.openSide.Text = "Binds"; UI.openSide.BackgroundColor3 = Color3.fromRGB(28,28,28)
UI.openSide.TextColor3 = Color3.fromRGB(160,160,160); UI.openSide.BorderSizePixel = 0
UI.openSide.Font = Enum.Font.GothamSemibold; UI.openSide.TextSize = 13; UI.openSide.ZIndex = 3; UI.openSide.Parent = UI.top
mkCorner(UI.openSide, 4); mkStroke(UI.openSide, Color3.fromRGB(65,65,65), 1)

UI.previewToggle = Instance.new("TextButton")
UI.previewToggle.Size = UDim2.new(0,60,0,20); UI.previewToggle.Position = UDim2.new(1,-174,0,4)
UI.previewToggle.Text = "Preview"; UI.previewToggle.BackgroundColor3 = Color3.fromRGB(28,28,28)
UI.previewToggle.TextColor3 = Color3.fromRGB(160,160,160); UI.previewToggle.BorderSizePixel = 0
UI.previewToggle.Font = Enum.Font.GothamSemibold; UI.previewToggle.TextSize = 13; UI.previewToggle.ZIndex = 3; UI.previewToggle.Parent = UI.top
mkCorner(UI.previewToggle, 4); mkStroke(UI.previewToggle, Color3.fromRGB(65,65,65), 1)

UI.searchBox = Instance.new("TextBox")
UI.searchBox.Text = ""; UI.searchBox.PlaceholderText = "Search animations..."
UI.searchBox.Position = UDim2.new(0,6,0,32); UI.searchBox.Size = UDim2.new(0.60,-12,0,22)
UI.searchBox.BackgroundColor3 = Color3.fromRGB(20,20,20); UI.searchBox.TextColor3 = Color3.fromRGB(210,210,210)
UI.searchBox.PlaceholderColor3 = Color3.fromRGB(65,65,65); UI.searchBox.BorderSizePixel = 0
UI.searchBox.Font = Enum.Font.Code; UI.searchBox.TextSize = 12; UI.searchBox.ZIndex = 2; UI.searchBox.Parent = UI.mainFrame
mkCorner(UI.searchBox, 4); mkStroke(UI.searchBox, Color3.fromRGB(42,42,42), 1)

UI.playerFilterBox = Instance.new("TextBox")
UI.playerFilterBox.Text = ""; UI.playerFilterBox.PlaceholderText = "Filter player..."
UI.playerFilterBox.Position = UDim2.new(0,5,0,55); UI.playerFilterBox.Size = UDim2.new(0.30,-5,0,20)
UI.playerFilterBox.BackgroundColor3 = Color3.fromRGB(20,20,20); UI.playerFilterBox.TextColor3 = Color3.fromRGB(210,210,210)
UI.playerFilterBox.PlaceholderColor3 = Color3.fromRGB(65,65,65); UI.playerFilterBox.BorderSizePixel = 0
UI.playerFilterBox.Font = Enum.Font.Code; UI.playerFilterBox.TextSize = 12; UI.playerFilterBox.ZIndex = 2; UI.playerFilterBox.Parent = UI.mainFrame
mkCorner(UI.playerFilterBox, 4); mkStroke(UI.playerFilterBox, Color3.fromRGB(65,65,65), 1)

UI.priorityFilterBox = Instance.new("TextBox")
UI.priorityFilterBox.Text = ""; UI.priorityFilterBox.PlaceholderText = "Filter priority..."
UI.priorityFilterBox.Position = UDim2.new(0.30,5,0,55); UI.priorityFilterBox.Size = UDim2.new(0.30,-10,0,20)
UI.priorityFilterBox.BackgroundColor3 = Color3.fromRGB(20,20,20); UI.priorityFilterBox.TextColor3 = Color3.fromRGB(210,210,210)
UI.priorityFilterBox.PlaceholderColor3 = Color3.fromRGB(65,65,65); UI.priorityFilterBox.BorderSizePixel = 0
UI.priorityFilterBox.Font = Enum.Font.Code; UI.priorityFilterBox.TextSize = 12; UI.priorityFilterBox.ZIndex = 2; UI.priorityFilterBox.Parent = UI.mainFrame
mkCorner(UI.priorityFilterBox, 4); mkStroke(UI.priorityFilterBox, Color3.fromRGB(65,65,65), 1)

UI.logTabBtn = Instance.new("TextButton")
UI.logTabBtn.Text = "[ Log ]"; UI.logTabBtn.Position = UDim2.new(0,5,0,102); UI.logTabBtn.Size = UDim2.new(0.20,-4,0,18)
UI.logTabBtn.BackgroundColor3 = Color3.fromRGB(220,220,220); UI.logTabBtn.TextColor3 = Color3.fromRGB(20,20,20)
UI.logTabBtn.Font = Enum.Font.GothamSemibold; UI.logTabBtn.TextSize = 13; UI.logTabBtn.BorderSizePixel = 0; UI.logTabBtn.ZIndex = 2; UI.logTabBtn.Parent = UI.mainFrame
mkCorner(UI.logTabBtn, 4)

UI.favsTabBtn = Instance.new("TextButton")
UI.favsTabBtn.Text = "[ Favs ]"; UI.favsTabBtn.Position = UDim2.new(0.20,2,0,102); UI.favsTabBtn.Size = UDim2.new(0.20,-4,0,18)
UI.favsTabBtn.BackgroundColor3 = Color3.fromRGB(255,215,0); UI.favsTabBtn.TextColor3 = Color3.fromRGB(20,20,20)
UI.favsTabBtn.Font = Enum.Font.GothamSemibold; UI.favsTabBtn.TextSize = 13; UI.favsTabBtn.BorderSizePixel = 0; UI.favsTabBtn.ZIndex = 2; UI.favsTabBtn.Parent = UI.mainFrame
mkCorner(UI.favsTabBtn, 4)

UI.bannedTabBtn = Instance.new("TextButton")
UI.bannedTabBtn.Text = "[ Banned ]"; UI.bannedTabBtn.Position = UDim2.new(0.40,2,0,102); UI.bannedTabBtn.Size = UDim2.new(0.20,-6,0,18)
UI.bannedTabBtn.BackgroundColor3 = Color3.fromRGB(200,50,50); UI.bannedTabBtn.TextColor3 = Color3.fromRGB(255,255,255)
UI.bannedTabBtn.Font = Enum.Font.GothamSemibold; UI.bannedTabBtn.TextSize = 13; UI.bannedTabBtn.BorderSizePixel = 0; UI.bannedTabBtn.ZIndex = 2; UI.bannedTabBtn.Parent = UI.mainFrame
mkCorner(UI.bannedTabBtn, 4)

UI.logCountLabel = Instance.new("TextLabel")
UI.logCountLabel.Text = "0 logged"; UI.logCountLabel.Position = UDim2.new(0.60,-92,0,32); UI.logCountLabel.Size = UDim2.new(0,88,0,22)
UI.logCountLabel.BackgroundTransparency = 1; UI.logCountLabel.TextColor3 = Color3.fromRGB(80,80,80)
UI.logCountLabel.TextXAlignment = Enum.TextXAlignment.Right; UI.logCountLabel.Font = Enum.Font.Gotham
UI.logCountLabel.TextSize = 11; UI.logCountLabel.ZIndex = 2; UI.logCountLabel.Parent = UI.mainFrame

UI.commandBar = Instance.new("TextBox")
UI.commandBar.Text = ""; UI.commandBar.PlaceholderText = "cmd bar... (/capture, /ban 123, play 123; wait 0.3; stop)"
UI.commandBar.Position = UDim2.new(0,6,0,78); UI.commandBar.Size = UDim2.new(0.60,-74,0,22)
UI.commandBar.BackgroundColor3 = Color3.fromRGB(20,20,20); UI.commandBar.TextColor3 = Color3.fromRGB(210,210,210)
UI.commandBar.PlaceholderColor3 = Color3.fromRGB(65,65,65); UI.commandBar.BorderSizePixel = 0
UI.commandBar.Font = Enum.Font.Code; UI.commandBar.TextSize = 12; UI.commandBar.ZIndex = 2; UI.commandBar.Parent = UI.mainFrame
mkCorner(UI.commandBar, 4); mkStroke(UI.commandBar, Color3.fromRGB(42,42,42), 1)

UI.commandPaletteBtn = Instance.new("TextButton")
UI.commandPaletteBtn.Text = "⌘"; UI.commandPaletteBtn.Position = UDim2.new(0.60,-56,0,78); UI.commandPaletteBtn.Size = UDim2.new(0,26,0,22)
UI.commandPaletteBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.commandPaletteBtn.TextColor3 = Color3.fromRGB(180,180,180)
UI.commandPaletteBtn.Font = Enum.Font.Code; UI.commandPaletteBtn.TextSize = 12; UI.commandPaletteBtn.BorderSizePixel = 0; UI.commandPaletteBtn.ZIndex = 2; UI.commandPaletteBtn.Parent = UI.mainFrame
mkCorner(UI.commandPaletteBtn, 4); mkStroke(UI.commandPaletteBtn, Color3.fromRGB(65,65,65), 1)

UI.commandRunBtn = Instance.new("TextButton")
UI.commandRunBtn.Text = "Run"; UI.commandRunBtn.Position = UDim2.new(0.60,-28,0,78); UI.commandRunBtn.Size = UDim2.new(0,30,0,22)
UI.commandRunBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.commandRunBtn.TextColor3 = Color3.fromRGB(140,210,145)
UI.commandRunBtn.Font = Enum.Font.Code; UI.commandRunBtn.TextSize = 10; UI.commandRunBtn.BorderSizePixel = 0; UI.commandRunBtn.ZIndex = 2; UI.commandRunBtn.Parent = UI.mainFrame
mkCorner(UI.commandRunBtn, 4); mkStroke(UI.commandRunBtn, Color3.fromRGB(45,80,48), 1)

UI.commandPalette = Instance.new("Frame")
UI.commandPalette.Size = UDim2.new(0.60,-10,0,122); UI.commandPalette.Position = UDim2.new(0,5,0,124)
UI.commandPalette.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.commandPalette.BackgroundTransparency = 0.08
UI.commandPalette.BorderSizePixel = 0; UI.commandPalette.ZIndex = 20; UI.commandPalette.Visible = false; UI.commandPalette.Parent = UI.mainFrame
mkCorner(UI.commandPalette, 5); mkStroke(UI.commandPalette, Color3.fromRGB(60,60,60), 1)

local paletteLayout = Instance.new("UIListLayout"); paletteLayout.Padding = UDim.new(0,3); paletteLayout.Parent = UI.commandPalette
local palettePad = Instance.new("UIPadding"); palettePad.PaddingTop = UDim.new(0,4); palettePad.PaddingBottom = UDim.new(0,4); palettePad.PaddingLeft = UDim.new(0,4); palettePad.PaddingRight = UDim.new(0,4); palettePad.Parent = UI.commandPalette
for _, item in ipairs({
	{label = "Capture Current", cmd = "/capture"},
	{label = "Toggle Loop", cmd = "loop"},
	{label = "Toggle Freeze", cmd = "freeze"},
	{label = "Export Log", cmd = "export"},
	{label = "Import Names", cmd = "import"}
}) do
	local b = Instance.new("TextButton")
	b.Name = item.cmd
	b.Text = item.label
	b.Size = UDim2.new(1,0,0,20)
	b.BackgroundColor3 = Color3.fromRGB(22,22,22)
	b.TextColor3 = Color3.fromRGB(200,200,200)
	b.Font = Enum.Font.Code
	b.TextSize = 10
	b.BorderSizePixel = 0
	b.ZIndex = 21
	b.Parent = UI.commandPalette
	mkCorner(b, 3); mkStroke(b, Color3.fromRGB(55,55,55), 1)
end

UI.list = Instance.new("ScrollingFrame")
UI.list.Name = "AnimList"; UI.list.Position = UDim2.new(0,5,0,124); UI.list.Size = UDim2.new(0.60,-10,1,-129)
UI.list.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.list.BackgroundTransparency = 0.15; UI.list.BorderSizePixel = 0
UI.list.ScrollBarThickness = 4; UI.list.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
UI.list.CanvasSize = UDim2.new(0,0,0,0); UI.list.ClipsDescendants = true; UI.list.ZIndex = 2; UI.list.Visible = true; UI.list.Parent = UI.mainFrame
mkCorner(UI.list, 4); mkStroke(UI.list, Color3.fromRGB(42,42,42), 1)
do
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0,1)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = UI.list
	table.insert(Data.connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		UI.list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
	end))
end

UI.favsList = Instance.new("ScrollingFrame")
UI.favsList.Name = "FavsList"; UI.favsList.Position = UDim2.new(0,5,0,124); UI.favsList.Size = UDim2.new(0.60,-10,1,-129)
UI.favsList.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.favsList.BackgroundTransparency = 0.15; UI.favsList.BorderSizePixel = 0
UI.favsList.ScrollBarThickness = 4; UI.favsList.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
UI.favsList.CanvasSize = UDim2.new(0,0,0,0); UI.favsList.ClipsDescendants = true; UI.favsList.ZIndex = 2; UI.favsList.Visible = false; UI.favsList.Parent = UI.mainFrame
mkCorner(UI.favsList, 4); mkStroke(UI.favsList, Color3.fromRGB(65,65,65), 1)
do
	local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0,2); fl.Parent = UI.favsList
	table.insert(Data.connections, fl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		UI.favsList.CanvasSize = UDim2.new(0,0,0,fl.AbsoluteContentSize.Y)
	end))
end

UI.bannedList = Instance.new("ScrollingFrame")
UI.bannedList.Name = "BannedList"; UI.bannedList.Position = UDim2.new(0,5,0,124); UI.bannedList.Size = UDim2.new(0.60,-10,1,-129)
UI.bannedList.BackgroundColor3 = Color3.fromRGB(8,8,8); UI.bannedList.BackgroundTransparency = 0.15; UI.bannedList.BorderSizePixel = 0
UI.bannedList.ScrollBarThickness = 4; UI.bannedList.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
UI.bannedList.CanvasSize = UDim2.new(0,0,0,0); UI.bannedList.ClipsDescendants = true; UI.bannedList.ZIndex = 2; UI.bannedList.Visible = false; UI.bannedList.Parent = UI.mainFrame
mkCorner(UI.bannedList, 4); mkStroke(UI.bannedList, Color3.fromRGB(42,42,42), 1)
do
	local bl = Instance.new("UIListLayout"); bl.Padding = UDim.new(0,2); bl.Parent = UI.bannedList
	table.insert(Data.connections, bl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		UI.bannedList.CanvasSize = UDim2.new(0,0,0,bl.AbsoluteContentSize.Y)
	end))
end

local function rebuildBannedList()
	local query = ""
	for _, child in ipairs(UI.bannedList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for id, isBanned in pairs(Data.banned) do
		if isBanned and (query == "" or tostring(id):lower():find(query, 1, true)) then
			local row = Instance.new("Frame"); row.Size = UDim2.new(1,-5,0,22); row.BackgroundTransparency = 1; row.ZIndex = 3; row.Parent = UI.bannedList
			local label = Instance.new("TextButton")
			label.Size = UDim2.new(1,-110,1,0); label.BackgroundColor3 = Color3.fromRGB(8,8,8)
			label.TextColor3 = Data.trueBanned[id] and Color3.fromRGB(139,0,0) or Color3.fromRGB(200,50,50); label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = (Data.trueBanned[id] and "⬛ " or "") .. id
			label.Font = Enum.Font.Code; label.TextSize = 11; label.BorderSizePixel = 0; label.ZIndex = 4; label.TextTruncate = Enum.TextTruncate.AtEnd; label.Parent = row
			mkCorner(label, 3)
			local copyBtn = Instance.new("TextButton"); copyBtn.Size = UDim2.new(0,50,1,0); copyBtn.Position = UDim2.new(1,-105,0,0)
			copyBtn.BackgroundColor3 = Color3.fromRGB(20,20,20); copyBtn.TextColor3 = Color3.fromRGB(210,210,210); copyBtn.Text = "Copy"
			copyBtn.Font = Enum.Font.GothamSemibold; copyBtn.TextSize = 10; copyBtn.BorderSizePixel = 0; copyBtn.ZIndex = 4; copyBtn.Parent = row
			mkCorner(copyBtn, 3)
			local unbanBtn = Instance.new("TextButton"); unbanBtn.Size = UDim2.new(0,50,1,0); unbanBtn.Position = UDim2.new(1,-55,0,0)
			unbanBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); unbanBtn.TextColor3 = Color3.fromRGB(140,210,145); unbanBtn.Text = "Unban"
			unbanBtn.Font = Enum.Font.Code; unbanBtn.TextSize = 10; unbanBtn.BorderSizePixel = 0; unbanBtn.ZIndex = 4; unbanBtn.Parent = row
			mkCorner(unbanBtn, 3)
			table.insert(Data.connections, label.MouseButton1Click:Connect(function() UI.idBox.Text = id end))
			table.insert(Data.connections, copyBtn.MouseButton1Click:Connect(function() yoink(id) end))
			table.insert(Data.connections, unbanBtn.MouseButton1Click:Connect(function()
				Data.banned[id] = nil; Data.trueBanned[id] = nil; dumpCfg(); row:Destroy()
			end))
		end
	end
	for id, isLogBanned in pairs(Data.logBlacklist) do
		if isLogBanned and (query == "" or tostring(id):lower():find(query, 1, true)) then
			local row = Instance.new("Frame"); row.Size = UDim2.new(1,-5,0,22); row.BackgroundTransparency = 1; row.ZIndex = 3; row.Parent = UI.bannedList
			local label = Instance.new("TextButton")
			label.Size = UDim2.new(1,-110,1,0); label.BackgroundColor3 = Color3.fromRGB(14,14,14)
			label.TextColor3 = Color3.fromRGB(180,140,230); label.TextXAlignment = Enum.TextXAlignment.Left
			label.Text = "◈ " .. id
			label.Font = Enum.Font.Code; label.TextSize = 11; label.BorderSizePixel = 0; label.ZIndex = 4; label.TextTruncate = Enum.TextTruncate.AtEnd; label.Parent = row
			mkCorner(label, 3); mkStroke(label, Color3.fromRGB(65,65,65), 1)
			local copyBtn = Instance.new("TextButton"); copyBtn.Size = UDim2.new(0,50,1,0); copyBtn.Position = UDim2.new(1,-105,0,0)
			copyBtn.BackgroundColor3 = Color3.fromRGB(20,20,20); copyBtn.TextColor3 = Color3.fromRGB(160,160,160); copyBtn.Text = "Copy"
			copyBtn.Font = Enum.Font.GothamSemibold; copyBtn.TextSize = 10; copyBtn.BorderSizePixel = 0; copyBtn.ZIndex = 4; copyBtn.Parent = row
			mkCorner(copyBtn, 3)
			local unlogbanBtn = Instance.new("TextButton"); unlogbanBtn.Size = UDim2.new(0,50,1,0); unlogbanBtn.Position = UDim2.new(1,-55,0,0)
			unlogbanBtn.BackgroundColor3 = Color3.fromRGB(20,20,20); unlogbanBtn.TextColor3 = Color3.fromRGB(160,160,160); unlogbanBtn.Text = "Unban"
			unlogbanBtn.Font = Enum.Font.Code; unlogbanBtn.TextSize = 10; unlogbanBtn.BorderSizePixel = 0; unlogbanBtn.ZIndex = 4; unlogbanBtn.Parent = row
			mkCorner(unlogbanBtn, 3)
			table.insert(Data.connections, label.MouseButton1Click:Connect(function() UI.idBox.Text = id end))
			table.insert(Data.connections, copyBtn.MouseButton1Click:Connect(function() yoink(id) end))
			table.insert(Data.connections, unlogbanBtn.MouseButton1Click:Connect(function()
				Data.logBlacklist[id] = nil; dumpCfg(); row:Destroy()
			end))
		end
	end
end

local function switchTab(tab)
	State.currentTab = tab
	UI.list.Visible = (tab == "log"); UI.favsList.Visible = (tab == "favs"); UI.bannedList.Visible = (tab == "banned")
	if tab == "banned" then rebuildBannedList() end
	UI.logTabBtn.BackgroundColor3 = (tab == "log") and Color3.fromRGB(220,220,220) or Color3.fromRGB(42,42,42)
	UI.logTabBtn.TextColor3 = (tab == "log") and Color3.fromRGB(20,20,20) or Color3.fromRGB(160,160,160)
	UI.favsTabBtn.BackgroundColor3 = (tab == "favs") and Color3.fromRGB(255,215,0) or Color3.fromRGB(28,28,28)
	UI.favsTabBtn.TextColor3 = (tab == "favs") and Color3.fromRGB(20,20,20) or Color3.fromRGB(160,160,160)
	UI.bannedTabBtn.BackgroundColor3 = (tab == "banned") and Color3.fromRGB(200,50,50) or Color3.fromRGB(14,14,14)
	UI.bannedTabBtn.TextColor3 = (tab == "banned") and Color3.fromRGB(255,255,255) or Color3.fromRGB(80,80,80)
end
switchTab("log")
table.insert(Data.connections, UI.logTabBtn.MouseButton1Click:Connect(function() switchTab("log") end))
table.insert(Data.connections, UI.favsTabBtn.MouseButton1Click:Connect(function() switchTab("favs") end))
table.insert(Data.connections, UI.bannedTabBtn.MouseButton1Click:Connect(function() switchTab("banned") end))

UI.controls = Instance.new("ScrollingFrame")
UI.controls.Name = "Controls"; UI.controls.Position = UDim2.new(0.60,5,0,30); UI.controls.Size = UDim2.new(0.40,-10,1,-35)
UI.controls.BackgroundColor3 = Color3.fromRGB(20,20,20); UI.controls.BackgroundTransparency = 0.15; UI.controls.BorderSizePixel = 0; UI.controls.ClipsDescendants = true
UI.controls.ScrollBarThickness = 3; UI.controls.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
UI.controls.CanvasSize = UDim2.new(0,0,0,1130); UI.controls.ZIndex = 2; UI.controls.Visible = true; UI.controls.Parent = UI.mainFrame
mkCorner(UI.controls, 5); mkStroke(UI.controls, Color3.fromRGB(42,42,42), 1)

local function mkLabel(text, y)
	local l = Instance.new("TextLabel"); l.Text = text; l.Position = UDim2.new(0,10,0,y); l.Size = UDim2.new(1,-20,0,20)
	l.BackgroundTransparency = 1; l.TextColor3 = Color3.fromRGB(160,160,160); l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.Code; l.ZIndex = 3; l.Visible = true; l.Parent = UI.controls
end

mkLabel("Animation ID", 10)
UI.idBox = Instance.new("TextBox")
UI.idBox.Text = ""; UI.idBox.Position = UDim2.new(0,10,0,30); UI.idBox.Size = UDim2.new(1,-20,0,25)
UI.idBox.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.idBox.TextColor3 = Color3.fromRGB(240,240,240)
UI.idBox.PlaceholderColor3 = Color3.fromRGB(65,65,65); UI.idBox.PlaceholderText = "animation id..."
UI.idBox.BorderSizePixel = 0; UI.idBox.ZIndex = 3; UI.idBox.Visible = true; UI.idBox.Parent = UI.controls
mkCorner(UI.idBox, 4); mkStroke(UI.idBox, Color3.fromRGB(65,65,65), 1)

mkLabel("Speed", 65)
UI.speedBox = Instance.new("TextBox")
UI.speedBox.Text = "1"; UI.speedBox.PlaceholderText = "speed (1 = normal)"
UI.speedBox.Position = UDim2.new(0,10,0,85); UI.speedBox.Size = UDim2.new(1,-20,0,25)
UI.speedBox.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.speedBox.TextColor3 = Color3.fromRGB(210,210,210)
UI.speedBox.BorderSizePixel = 0; UI.speedBox.ZIndex = 3; UI.speedBox.Visible = true; UI.speedBox.Parent = UI.controls
mkCorner(UI.speedBox, 4); mkStroke(UI.speedBox, Color3.fromRGB(65,65,65), 1)

mkLabel("Time (Scrub)", 120)
UI.timeBox = Instance.new("TextBox")
UI.timeBox.Text = "0"; UI.timeBox.PlaceholderText = "scrub time (secs)"
UI.timeBox.Position = UDim2.new(0,10,0,140); UI.timeBox.Size = UDim2.new(1,-20,0,25)
UI.timeBox.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.timeBox.TextColor3 = Color3.fromRGB(210,210,210)
UI.timeBox.BorderSizePixel = 0; UI.timeBox.ZIndex = 3; UI.timeBox.Visible = true; UI.timeBox.Parent = UI.controls
mkCorner(UI.timeBox, 4); mkStroke(UI.timeBox, Color3.fromRGB(65,65,65), 1)
table.insert(Data.connections, UI.timeBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(UI.timeBox.Text:match("[%d%.]+"))
	if num then
		for track in pairs(Data.scriptTracks) do
			if track.IsPlaying then track.TimePosition = math.clamp(num, 0, track.Length) end
		end
	end
end))

UI.mainTimerLabel = Instance.new("TextLabel")
UI.mainTimerLabel.Text = "no anim playing"; UI.mainTimerLabel.Position = UDim2.new(0,10,0,168); UI.mainTimerLabel.Size = UDim2.new(1,-20,0,14)
UI.mainTimerLabel.BackgroundTransparency = 1; UI.mainTimerLabel.TextColor3 = Color3.fromRGB(160,160,160)
UI.mainTimerLabel.TextXAlignment = Enum.TextXAlignment.Left; UI.mainTimerLabel.Font = Enum.Font.Code
UI.mainTimerLabel.TextSize = 11; UI.mainTimerLabel.ZIndex = 3; UI.mainTimerLabel.Visible = true; UI.mainTimerLabel.Parent = UI.controls

UI.mainScrubBg = Instance.new("Frame")
UI.mainScrubBg.Position = UDim2.new(0,10,0,185); UI.mainScrubBg.Size = UDim2.new(1,-20,0,12)
UI.mainScrubBg.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.mainScrubBg.BorderSizePixel = 0; UI.mainScrubBg.ZIndex = 3; UI.mainScrubBg.Parent = UI.controls
mkCorner(UI.mainScrubBg, 6)
UI.mainScrubFill = Instance.new("Frame")
	UI.mainScrubFill.Size = UDim2.new(0,0,1,0); UI.mainScrubFill.BackgroundColor3 = Color3.fromRGB(200,50,50); UI.mainScrubFill.BorderSizePixel = 0; UI.mainScrubFill.ZIndex = 4; UI.mainScrubFill.Parent = UI.mainScrubBg
UI.mainScrubBtn = Instance.new("TextButton")
UI.mainScrubBtn.Size = UDim2.new(1,0,1,0); UI.mainScrubBtn.BackgroundTransparency = 1; UI.mainScrubBtn.Text = ""; UI.mainScrubBtn.ZIndex = 5; UI.mainScrubBtn.Parent = UI.mainScrubBg

State.mainPaused = false
UI.mainPauseBtn = Instance.new("TextButton")
UI.mainPauseBtn.Text = "⏸ Pause"; UI.mainPauseBtn.Position = UDim2.new(0,10,0,196); UI.mainPauseBtn.Size = UDim2.new(1,-20,0,20)
UI.mainPauseBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.mainPauseBtn.TextColor3 = Color3.fromRGB(180,180,180)
UI.mainPauseBtn.BorderSizePixel = 0; UI.mainPauseBtn.Font = Enum.Font.GothamSemibold; UI.mainPauseBtn.TextSize = 11; UI.mainPauseBtn.ZIndex = 3; UI.mainPauseBtn.Parent = UI.controls
mkCorner(UI.mainPauseBtn, 4); mkStroke(UI.mainPauseBtn, Color3.fromRGB(55,55,55), 1)
table.insert(Data.connections, UI.mainPauseBtn.MouseButton1Click:Connect(function()
	local hasTracks = false
	for track in pairs(Data.scriptTracks) do if track.IsPlaying or State.mainPaused then hasTracks = true; break end end
	if not hasTracks and not State.mainPaused then return end 
	State.mainPaused = not State.mainPaused
	for track in pairs(Data.scriptTracks) do
		if State.mainPaused then track:AdjustSpeed(0) else track:AdjustSpeed(tonumber(UI.speedBox.Text) or 1) end
	end
	UI.mainPauseBtn.Text = State.mainPaused and "▶ Resume" or "⏸ Pause"
	UI.mainPauseBtn.BackgroundColor3 = State.mainPaused and Color3.fromRGB(16,35,35) or Color3.fromRGB(28,28,28)
	UI.mainPauseBtn.TextColor3 = State.mainPaused and Color3.fromRGB(100,210,200) or Color3.fromRGB(180,180,180)
end))
table.insert(Data.connections, UI.mainScrubBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then State.mainScrubbing = true end
end))
table.insert(Data.connections, UI.mainScrubBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then State.mainScrubbing = false end
end))

UI.loopToggle = Instance.new("TextButton")
UI.loopToggle.Text = "Loop: OFF"; UI.loopToggle.Position = UDim2.new(0,10,0,220); UI.loopToggle.Size = UDim2.new(1,-20,0,25)
UI.loopToggle.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.loopToggle.TextColor3 = Color3.fromRGB(140,140,140)
UI.loopToggle.BorderSizePixel = 0; UI.loopToggle.Font = Enum.Font.GothamSemibold; UI.loopToggle.TextSize = 12; UI.loopToggle.ZIndex = 3; UI.loopToggle.Visible = true; UI.loopToggle.Parent = UI.controls
mkCorner(UI.loopToggle, 4)
local loopToggleStroke = Instance.new("UIStroke"); loopToggleStroke.Color = Color3.fromRGB(42,42,42); loopToggleStroke.Thickness = 1; loopToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; loopToggleStroke.Parent = UI.loopToggle

local function refreshLoopBtn()
	UI.loopToggle.Text = "Loop: " .. (State.looped and "ON" or "OFF")
	UI.loopToggle.BackgroundColor3 = State.looped and Color3.fromRGB(200,50,50) or Color3.fromRGB(14,14,14)
	UI.loopToggle.TextColor3 = State.looped and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
	loopToggleStroke.Color = State.looped and Color3.fromRGB(150,30,30) or Color3.fromRGB(42,42,42)
end
table.insert(Data.connections, UI.loopToggle.MouseButton1Click:Connect(function()
	State.looped = not State.looped; refreshLoopBtn(); dumpCfg()
end))


local function button(text, y, callback, bgColor, borderColor, textColor)
	local b = Instance.new("TextButton"); b.Text = text; b.Position = UDim2.new(0,10,0,y); b.Size = UDim2.new(1,-20,0,26)
	b.BackgroundColor3 = bgColor or Color3.fromRGB(32,32,32); b.TextColor3 = textColor or Color3.fromRGB(200,200,200)
	b.BorderSizePixel = 0; b.Font = Enum.Font.GothamSemibold; b.TextSize = 12; b.ZIndex = 3; b.Visible = true; b.Parent = UI.controls
	mkCorner(b, 4); mkStroke(b, borderColor or Color3.fromRGB(60,60,60), 1)
	table.insert(Data.connections, b.MouseButton1Click:Connect(callback))
	return b
end

local refreshColors


button("Play", 255, function()
	local id = UI.idBox.Text; local speed = tonumber(UI.speedBox.Text) or 1; local scrub = tonumber(UI.timeBox.Text) or 0
	local track = fireAnim(id, speed, State.looped)
	if track and scrub > 0 then task.defer(function() if track then track.TimePosition = math.clamp(scrub, 0, track.Length) end end) end
end, Color3.fromRGB(22,38,24), Color3.fromRGB(45,80,48), Color3.fromRGB(140,210,145))

button("Stop", 290, function() killAnim(UI.idBox.Text) end,
	Color3.fromRGB(38,22,22), Color3.fromRGB(75,40,40), Color3.fromRGB(210,130,130))

button("Stop All", 325, function()
	local animator = grabAnimator()
	if animator then for _, track in pairs(animator:GetPlayingAnimationTracks()) do Data.scriptTracks[track] = nil; track:Stop() end end
	for k in pairs(Data.scriptTracks) do Data.scriptTracks[k] = nil end
end, Color3.fromRGB(42,20,20), Color3.fromRGB(85,38,38), Color3.fromRGB(220,120,120))

button("Ban", 360, function()
	Data.banned[UI.idBox.Text] = true; killAnim(UI.idBox.Text); dumpCfg()
end, Color3.fromRGB(48,16,16), Color3.fromRGB(90,30,30), Color3.fromRGB(220,80,80))

button("True Ban", 395, function()
	local id = UI.idBox.Text; if id == "" then return end
	Data.trueBanned[id] = true; Data.banned[id] = true; killAnim(id); dumpCfg(); refreshColors()
end, Color3.fromRGB(55,10,10), Color3.fromRGB(100,25,25), Color3.fromRGB(180,50,50))

button("Unban", 430, function()
	local id = UI.idBox.Text; Data.banned[id] = nil; Data.trueBanned[id] = nil; dumpCfg(); refreshColors()
end, Color3.fromRGB(22,38,24), Color3.fromRGB(45,80,48), Color3.fromRGB(140,210,145))

button("Log Ban", 465, function()
	local id = grabId(UI.idBox.Text)
	if not id or id == "" then return end
	Data.logBlacklist[id] = true; dumpCfg(); refreshColors()
end, Color3.fromRGB(34,22,48), Color3.fromRGB(70,45,95), Color3.fromRGB(180,140,230))

button("Log Unban", 500, function()
	local id = grabId(UI.idBox.Text)
	if not id or id == "" then return end
	Data.logBlacklist[id] = nil; dumpCfg(); refreshColors()
end, Color3.fromRGB(28,18,40), Color3.fromRGB(60,38,80), Color3.fromRGB(160,120,210))

button("Copy ID", 535, function() yoink(UI.idBox.Text) end,
	Color3.fromRGB(18,28,48), Color3.fromRGB(38,65,105), Color3.fromRGB(120,175,240))

local function nukeList()
	for id, entry in pairs(Data.animFrames) do
		if id:find("__frame") then
			if entry and entry.Parent then entry:Destroy() end
		elseif entry.Parent and entry.Parent:IsA("Frame") then
			entry.Parent:Destroy()
		else
			pcall(function() entry:Destroy() end)
		end
	end
	Data.animCounts = {}; Data.animFrames = {}; Data.seenTracks = {}; UI.logCountLabel.Text = "0 logged"
	Data.animLastFired = {}; Data.animFireIntervals = {}; Data.loopingAnims = {}; Data.logLastMove = {}; Data.logOrder = 0
end
button("Clear List", 570, nukeList,
	Color3.fromRGB(42,28,14), Color3.fromRGB(85,55,20), Color3.fromRGB(220,165,90))

UI.globalToggle = Instance.new("TextButton")
UI.globalToggle.Text = "Global Log: OFF"; UI.globalToggle.Position = UDim2.new(0,10,0,597); UI.globalToggle.Size = UDim2.new(1,-20,0,25)
UI.globalToggle.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.globalToggle.TextColor3 = Color3.fromRGB(140,140,140)
UI.globalToggle.BorderSizePixel = 0; UI.globalToggle.Font = Enum.Font.GothamSemibold; UI.globalToggle.TextSize = 12; UI.globalToggle.ZIndex = 3; UI.globalToggle.Visible = true; UI.globalToggle.Parent = UI.controls
mkCorner(UI.globalToggle, 4)
local globalToggleStroke = Instance.new("UIStroke"); globalToggleStroke.Color = Color3.fromRGB(42,42,42); globalToggleStroke.Thickness = 1; globalToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; globalToggleStroke.Parent = UI.globalToggle
local function refreshGlobalBtn()
	UI.globalToggle.Text = "Global Log: " .. (State.globalLogging and "ON" or "OFF")
	UI.globalToggle.BackgroundColor3 = State.globalLogging and Color3.fromRGB(22,38,24) or Color3.fromRGB(14,14,14)
	UI.globalToggle.TextColor3 = State.globalLogging and Color3.fromRGB(140,210,145) or Color3.fromRGB(140,140,140)
	globalToggleStroke.Color = State.globalLogging and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42)
end
table.insert(Data.connections, UI.globalToggle.MouseButton1Click:Connect(function()
	State.globalLogging = not State.globalLogging; refreshGlobalBtn(); dumpCfg()
end))

UI.autoCopyToggle = Instance.new("TextButton")
UI.autoCopyToggle.Text = "Auto-Copy: OFF"; UI.autoCopyToggle.Position = UDim2.new(0,10,0,625); UI.autoCopyToggle.Size = UDim2.new(1,-20,0,22)
UI.autoCopyToggle.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.autoCopyToggle.TextColor3 = Color3.fromRGB(140,140,140)
UI.autoCopyToggle.BorderSizePixel = 0; UI.autoCopyToggle.Font = Enum.Font.GothamSemibold; UI.autoCopyToggle.TextSize = 12; UI.autoCopyToggle.ZIndex = 3; UI.autoCopyToggle.Visible = true; UI.autoCopyToggle.Parent = UI.controls
mkCorner(UI.autoCopyToggle, 4)
local autoCopyStroke = Instance.new("UIStroke"); autoCopyStroke.Color = Color3.fromRGB(42,42,42); autoCopyStroke.Thickness = 1; autoCopyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; autoCopyStroke.Parent = UI.autoCopyToggle
local function refreshAutoCopyBtn()
	UI.autoCopyToggle.Text = "Auto-Copy: " .. (State.autoCopy and "ON" or "OFF")
	UI.autoCopyToggle.BackgroundColor3 = State.autoCopy and Color3.fromRGB(22,38,24) or Color3.fromRGB(14,14,14)
	UI.autoCopyToggle.TextColor3 = State.autoCopy and Color3.fromRGB(140,210,145) or Color3.fromRGB(140,140,140)
	autoCopyStroke.Color = State.autoCopy and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42)
end
table.insert(Data.connections, UI.autoCopyToggle.MouseButton1Click:Connect(function()
	State.autoCopy = not State.autoCopy; refreshAutoCopyBtn(); dumpCfg()
end))

UI.exportBtn = Instance.new("TextButton")
UI.exportBtn.Text = "Export Log"; UI.exportBtn.Position = UDim2.new(0,10,0,651); UI.exportBtn.Size = UDim2.new(1,-20,0,22)
UI.exportBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.exportBtn.TextColor3 = Color3.fromRGB(160,160,160)
UI.exportBtn.BorderSizePixel = 0; UI.exportBtn.ZIndex = 3; UI.exportBtn.Visible = true; UI.exportBtn.Parent = UI.controls
mkCorner(UI.exportBtn, 4); mkStroke(UI.exportBtn, Color3.fromRGB(65,65,65), 1)
table.insert(Data.connections, UI.exportBtn.MouseButton1Click:Connect(function()
	local out = {}
	for key, entry in pairs(Data.animFrames) do
		if key:find("__frame", 1, true) then continue end
		local pureId = key:match("^([%d]+)")
		table.insert(out, {id=pureId, key=key, name=entry.Text, count=Data.animCounts[key] or 1,
			lastSeen=Data.animTimestamps[key] or "?", favorited=Data.favorites[pureId] or false, customName=Data.customNames[pureId] or nil})
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
		UI.exportBtn.Text = "Exported!"; UI.exportBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
		task.delay(2, function() UI.exportBtn.Text = "Export Log"; UI.exportBtn.BackgroundColor3 = Color3.fromRGB(28,28,28) end)
	else
		yoink(json)
		UI.exportBtn.Text = "Copied!"; UI.exportBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
		task.delay(2, function() UI.exportBtn.Text = "Export Log"; UI.exportBtn.BackgroundColor3 = Color3.fromRGB(28,28,28) end)
	end
end))


UI.advancedFiltersToggle = Instance.new("TextButton")
UI.advancedFiltersToggle.Text = "Advanced Filters: OFF"; UI.advancedFiltersToggle.Position = UDim2.new(0,10,0,880); UI.advancedFiltersToggle.Size = UDim2.new(1,-20,0,25)
UI.advancedFiltersToggle.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.advancedFiltersToggle.TextColor3 = Color3.fromRGB(140,140,140)
UI.advancedFiltersToggle.BorderSizePixel = 0; UI.advancedFiltersToggle.Font = Enum.Font.GothamSemibold; UI.advancedFiltersToggle.TextSize = 12; UI.advancedFiltersToggle.ZIndex = 3; UI.advancedFiltersToggle.Visible = true; UI.advancedFiltersToggle.Parent = UI.controls
mkCorner(UI.advancedFiltersToggle, 4)
local advancedFiltersStroke = Instance.new("UIStroke"); advancedFiltersStroke.Color = Color3.fromRGB(42,42,42); advancedFiltersStroke.Thickness = 1; advancedFiltersStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; advancedFiltersStroke.Parent = UI.advancedFiltersToggle

local function evaluateFilter(filter, animData)
	local filterType = filter.type
	local param = filter.param or ""
	local enabled = filter.enabled ~= false

	if not enabled then return true end

	local id = animData.id or ""
	local name = animData.name or ""
	local player = animData.player or ""
	local priority = animData.priority or ""

	if filterType == "search" then
		if param == "" then return true end
		return id:lower():find(param:lower(), 1, true) or name:lower():find(param:lower(), 1, true)
	elseif filterType == "player" then
		if param == "" then return true end
		return player:lower():find(param:lower(), 1, true)
	elseif filterType == "priority" then
		if param == "" then return true end
		return priority:lower():find(param:lower(), 1, true)
	elseif filterType == "id_exact" then
		return id == param
	elseif filterType == "name_exact" then
		return name == param
	elseif filterType == "player_exact" then
		return player == param
	elseif filterType == "priority_exact" then
		return priority == param
	elseif filterType == "id_pattern" then
		return id:find(param, 1, true)
	elseif filterType == "name_pattern" then
		return name:find(param, 1, true)
	elseif filterType == "count_min" then
		local minCount = tonumber(param) or 0
		return (animData.count or 1) >= minCount
	elseif filterType == "count_max" then
		local maxCount = tonumber(param) or math.huge
		return (animData.count or 1) <= maxCount
	elseif filterType == "favorited" then
		local shouldBeFavorited = param == "true"
		return (animData.favorited or false) == shouldBeFavorited
	end

	return true
end

local function shouldShowAnimation(animData)
	if not State.advancedFilters.enabled then
		local query = (UI.searchBox and UI.searchBox.Text or ""):lower()
		local pf = (UI.playerFilterBox and UI.playerFilterBox.Text or ""):lower()
		local priF = (UI.priorityFilterBox and UI.priorityFilterBox.Text or ""):lower()

		local text = animData.name:lower()
		return (query == "" or animData.id:lower():find(query,1,true) or text:find(query,1,true))
			and (pf == "" or text:find(pf,1,true))
			and (priF == "" or text:find(priF,1,true))
	end

	local filters = State.advancedFilters.activeFilters
	local logic = State.advancedFilters.logic

	if logic == "AND" then
		for _, filter in ipairs(filters) do
			if not evaluateFilter(filter, animData) then
				return false
			end
		end
		return true
	elseif logic == "OR" then
		for _, filter in ipairs(filters) do
			if evaluateFilter(filter, animData) then
				return true
			end
		end
		return false
	end

	return true
end

local function doFilter()
	for id, entry in pairs(Data.animFrames) do
		if id:find("__frame", 1, true) then continue end

		local animData = {
			id = id:match("^([%d]+)") or id,
			name = entry.Text,
			player = "",
			priority = "",
			count = Data.animCounts[id] or 1,
			favorited = Data.favorites[id:match("^([%d]+)") or id] or false
		}

		local shouldShow = shouldShowAnimation(animData)
		local container = entry.Parent
		if container and container:IsA("Frame") then
			container.Visible = shouldShow
		end
	end
end

local function refreshAdvancedFiltersBtn()
	UI.advancedFiltersToggle.Text = "Advanced Filters: " .. (State.advancedFilters.enabled and "ON" or "OFF")
	UI.advancedFiltersToggle.BackgroundColor3 = State.advancedFilters.enabled and Color3.fromRGB(22,38,24) or Color3.fromRGB(14,14,14)
	UI.advancedFiltersToggle.TextColor3 = State.advancedFilters.enabled and Color3.fromRGB(140,210,145) or Color3.fromRGB(140,140,140)
	advancedFiltersStroke.Color = State.advancedFilters.enabled and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42)
end

table.insert(Data.connections, UI.advancedFiltersToggle.MouseButton1Click:Connect(function()
	State.advancedFilters.enabled = not State.advancedFilters.enabled
	refreshAdvancedFiltersBtn()
	doFilter()
	if dumpCfg then dumpCfg() end
end))


UI.advancedFiltersPanel = Instance.new("Frame")
UI.advancedFiltersPanel.Size = UDim2.new(1, -20, 0, 200)
UI.advancedFiltersPanel.Position = UDim2.new(0, 10, 0, 910)
UI.advancedFiltersPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
UI.advancedFiltersPanel.BackgroundTransparency = 0.1
UI.advancedFiltersPanel.BorderSizePixel = 0
UI.advancedFiltersPanel.ZIndex = 3
UI.advancedFiltersPanel.Visible = false
UI.advancedFiltersPanel.Parent = UI.controls
mkCorner(UI.advancedFiltersPanel, 6)
mkStroke(UI.advancedFiltersPanel, Color3.fromRGB(60, 60, 60), 1)


UI.filterPresetLabel = Instance.new("TextLabel")
UI.filterPresetLabel.Text = "Preset:"
UI.filterPresetLabel.Size = UDim2.new(0, 50, 0, 20)
UI.filterPresetLabel.Position = UDim2.new(0, 10, 0, 10)
UI.filterPresetLabel.BackgroundTransparency = 1
UI.filterPresetLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
UI.filterPresetLabel.Font = Enum.Font.Code
UI.filterPresetLabel.TextSize = 11
UI.filterPresetLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.filterPresetLabel.ZIndex = 4
UI.filterPresetLabel.Parent = UI.advancedFiltersPanel

UI.filterPresetDropdown = Instance.new("TextButton")
UI.filterPresetDropdown.Size = UDim2.new(0, 120, 0, 20)
UI.filterPresetDropdown.Position = UDim2.new(0, 60, 0, 10)
UI.filterPresetDropdown.Text = State.advancedFilters.currentPreset
UI.filterPresetDropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
UI.filterPresetDropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
UI.filterPresetDropdown.Font = Enum.Font.Code
UI.filterPresetDropdown.TextSize = 10
UI.filterPresetDropdown.ZIndex = 4
UI.filterPresetDropdown.Parent = UI.advancedFiltersPanel
mkCorner(UI.filterPresetDropdown, 3)


UI.filterLogicLabel = Instance.new("TextLabel")
UI.filterLogicLabel.Text = "Logic:"
UI.filterLogicLabel.Size = UDim2.new(0, 40, 0, 20)
UI.filterLogicLabel.Position = UDim2.new(0, 190, 0, 10)
UI.filterLogicLabel.BackgroundTransparency = 1
UI.filterLogicLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
UI.filterLogicLabel.Font = Enum.Font.Code
UI.filterLogicLabel.TextSize = 11
UI.filterLogicLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.filterLogicLabel.ZIndex = 4
UI.filterLogicLabel.Parent = UI.advancedFiltersPanel

UI.filterLogicDropdown = Instance.new("TextButton")
UI.filterLogicDropdown.Size = UDim2.new(0, 50, 0, 20)
UI.filterLogicDropdown.Position = UDim2.new(0, 230, 0, 10)
UI.filterLogicDropdown.Text = State.advancedFilters.logic
UI.filterLogicDropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
UI.filterLogicDropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
UI.filterLogicDropdown.Font = Enum.Font.Code
UI.filterLogicDropdown.TextSize = 10
UI.filterLogicDropdown.ZIndex = 4
UI.filterLogicDropdown.Parent = UI.advancedFiltersPanel
mkCorner(UI.filterLogicDropdown, 3)


UI.saveFilterPresetBtn = Instance.new("TextButton")
UI.saveFilterPresetBtn.Size = UDim2.new(0, 40, 0, 20)
UI.saveFilterPresetBtn.Position = UDim2.new(0, 290, 0, 10)
UI.saveFilterPresetBtn.Text = "Save"
UI.saveFilterPresetBtn.BackgroundColor3 = Color3.fromRGB(22, 38, 24)
UI.saveFilterPresetBtn.TextColor3 = Color3.fromRGB(140, 210, 145)
UI.saveFilterPresetBtn.Font = Enum.Font.Code
UI.saveFilterPresetBtn.TextSize = 10
UI.saveFilterPresetBtn.ZIndex = 4
UI.saveFilterPresetBtn.Parent = UI.advancedFiltersPanel
mkCorner(UI.saveFilterPresetBtn, 3)

UI.loadFilterPresetBtn = Instance.new("TextButton")
UI.loadFilterPresetBtn.Size = UDim2.new(0, 40, 0, 20)
UI.loadFilterPresetBtn.Position = UDim2.new(0, 335, 0, 10)
UI.loadFilterPresetBtn.Text = "Load"
UI.loadFilterPresetBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
UI.loadFilterPresetBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
UI.loadFilterPresetBtn.Font = Enum.Font.Code
UI.loadFilterPresetBtn.TextSize = 10
UI.loadFilterPresetBtn.ZIndex = 4
UI.loadFilterPresetBtn.Parent = UI.advancedFiltersPanel
mkCorner(UI.loadFilterPresetBtn, 3)


UI.filterList = Instance.new("ScrollingFrame")
UI.filterList.Size = UDim2.new(1, -20, 0, 140)
UI.filterList.Position = UDim2.new(0, 10, 0, 40)
UI.filterList.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
UI.filterList.BackgroundTransparency = 0.2
UI.filterList.BorderSizePixel = 0
UI.filterList.ScrollBarThickness = 4
UI.filterList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
UI.filterList.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.filterList.ClipsDescendants = true
UI.filterList.ZIndex = 4
UI.filterList.Parent = UI.advancedFiltersPanel
mkCorner(UI.filterList, 4)
mkStroke(UI.filterList, Color3.fromRGB(42, 42, 42), 1)

local filterListLayout = Instance.new("UIListLayout")
filterListLayout.Padding = UDim.new(0, 4)
filterListLayout.Parent = UI.filterList

table.insert(Data.connections, filterListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	UI.filterList.CanvasSize = UDim2.new(0, 0, 0, filterListLayout.AbsoluteContentSize.Y)
end))


UI.addFilterBtn = Instance.new("TextButton")
UI.addFilterBtn.Size = UDim2.new(0, 80, 0, 20)
UI.addFilterBtn.Position = UDim2.new(0, 10, 0, 185)
UI.addFilterBtn.Text = "+ Add Filter"
UI.addFilterBtn.BackgroundColor3 = Color3.fromRGB(22, 38, 24)
UI.addFilterBtn.TextColor3 = Color3.fromRGB(140, 210, 145)
UI.addFilterBtn.Font = Enum.Font.Code
UI.addFilterBtn.TextSize = 10
UI.addFilterBtn.ZIndex = 4
UI.addFilterBtn.Parent = UI.advancedFiltersPanel
mkCorner(UI.addFilterBtn, 3)


UI.filterStatsLabel = Instance.new("TextLabel")
UI.filterStatsLabel.Text = "Stats: 0/0 visible"
UI.filterStatsLabel.Size = UDim2.new(0, 120, 0, 20)
UI.filterStatsLabel.Position = UDim2.new(0, 100, 0, 185)
UI.filterStatsLabel.BackgroundTransparency = 1
UI.filterStatsLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
UI.filterStatsLabel.Font = Enum.Font.Code
UI.filterStatsLabel.TextSize = 10
UI.filterStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.filterStatsLabel.ZIndex = 4
UI.filterStatsLabel.Parent = UI.advancedFiltersPanel


UI.performancePanel = Instance.new("Frame")
UI.performancePanel.Size = UDim2.new(1, -20, 0, 164)
UI.performancePanel.Position = UDim2.new(0, 10, 0, 678)
UI.performancePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
UI.performancePanel.BackgroundTransparency = 0.15
UI.performancePanel.BorderSizePixel = 0
UI.performancePanel.ZIndex = 3
UI.performancePanel.Visible = true
UI.performancePanel.Parent = UI.controls
mkCorner(UI.performancePanel, 6)
mkStroke(UI.performancePanel, Color3.fromRGB(60, 60, 60), 1)

UI.performanceTitle = Instance.new("TextLabel")
UI.performanceTitle.Text = "Performance"
UI.performanceTitle.Size = UDim2.new(0, 120, 0, 18)
UI.performanceTitle.Position = UDim2.new(0, 10, 0, 8)
UI.performanceTitle.BackgroundTransparency = 1
UI.performanceTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
UI.performanceTitle.Font = Enum.Font.Code
UI.performanceTitle.TextSize = 12
UI.performanceTitle.TextXAlignment = Enum.TextXAlignment.Left
UI.performanceTitle.ZIndex = 4
UI.performanceTitle.Parent = UI.performancePanel

UI.captureTrackBtn = Instance.new("TextButton")
UI.captureTrackBtn.Text = "Capture Track"
UI.captureTrackBtn.Size = UDim2.new(0, 94, 0, 18)
UI.captureTrackBtn.Position = UDim2.new(1, -104, 0, 8)
UI.captureTrackBtn.BackgroundColor3 = Color3.fromRGB(22,38,24)
UI.captureTrackBtn.TextColor3 = Color3.fromRGB(140,210,145)
UI.captureTrackBtn.Font = Enum.Font.Code
UI.captureTrackBtn.TextSize = 10
UI.captureTrackBtn.BorderSizePixel = 0
UI.captureTrackBtn.ZIndex = 4
UI.captureTrackBtn.Parent = UI.performancePanel
mkCorner(UI.captureTrackBtn, 3)
mkStroke(UI.captureTrackBtn, Color3.fromRGB(45,80,48), 1)

UI.performanceFpsLabel = Instance.new("TextLabel")
UI.performanceFpsLabel.Text = "FPS: --"
UI.performanceFpsLabel.Size = UDim2.new(0, 120, 0, 16)
UI.performanceFpsLabel.Position = UDim2.new(0, 10, 0, 30)
UI.performanceFpsLabel.BackgroundTransparency = 1
UI.performanceFpsLabel.TextColor3 = Color3.fromRGB(160, 220, 160)
UI.performanceFpsLabel.Font = Enum.Font.Code
UI.performanceFpsLabel.TextSize = 11
UI.performanceFpsLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.performanceFpsLabel.ZIndex = 4
UI.performanceFpsLabel.Parent = UI.performancePanel

UI.performanceTrackLabel = Instance.new("TextLabel")
UI.performanceTrackLabel.Text = "Script tracks: 0"
UI.performanceTrackLabel.Size = UDim2.new(0, 140, 0, 16)
UI.performanceTrackLabel.Position = UDim2.new(0, 10, 0, 50)
UI.performanceTrackLabel.BackgroundTransparency = 1
UI.performanceTrackLabel.TextColor3 = Color3.fromRGB(160, 220, 220)
UI.performanceTrackLabel.Font = Enum.Font.Code
UI.performanceTrackLabel.TextSize = 11
UI.performanceTrackLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.performanceTrackLabel.ZIndex = 4
UI.performanceTrackLabel.Parent = UI.performancePanel

UI.performanceLogRateLabel = Instance.new("TextLabel")
UI.performanceLogRateLabel.Text = "Log rate: --/s"
UI.performanceLogRateLabel.Size = UDim2.new(0, 140, 0, 16)
UI.performanceLogRateLabel.Position = UDim2.new(0, 10, 0, 70)
UI.performanceLogRateLabel.BackgroundTransparency = 1
UI.performanceLogRateLabel.TextColor3 = Color3.fromRGB(220, 180, 120)
UI.performanceLogRateLabel.Font = Enum.Font.Code
UI.performanceLogRateLabel.TextSize = 11
UI.performanceLogRateLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.performanceLogRateLabel.ZIndex = 4
UI.performanceLogRateLabel.Parent = UI.performancePanel

UI.performanceMsLabel = Instance.new("TextLabel")
UI.performanceMsLabel.Text = "Frame ms: --"
UI.performanceMsLabel.Size = UDim2.new(0, 150, 0, 16)
UI.performanceMsLabel.Position = UDim2.new(0, 160, 0, 30)
UI.performanceMsLabel.BackgroundTransparency = 1
UI.performanceMsLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
UI.performanceMsLabel.Font = Enum.Font.Code
UI.performanceMsLabel.TextSize = 11
UI.performanceMsLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.performanceMsLabel.ZIndex = 4
UI.performanceMsLabel.Parent = UI.performancePanel

UI.performancePeakTrackLabel = Instance.new("TextLabel")
UI.performancePeakTrackLabel.Text = "Peak tracks: 0"
UI.performancePeakTrackLabel.Size = UDim2.new(0, 150, 0, 16)
UI.performancePeakTrackLabel.Position = UDim2.new(0, 160, 0, 50)
UI.performancePeakTrackLabel.BackgroundTransparency = 1
UI.performancePeakTrackLabel.TextColor3 = Color3.fromRGB(180, 220, 220)
UI.performancePeakTrackLabel.Font = Enum.Font.Code
UI.performancePeakTrackLabel.TextSize = 11
UI.performancePeakTrackLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.performancePeakTrackLabel.ZIndex = 4
UI.performancePeakTrackLabel.Parent = UI.performancePanel

UI.performanceDropLabel = Instance.new("TextLabel")
UI.performanceDropLabel.Text = "Drop >33ms: 0%"
UI.performanceDropLabel.Size = UDim2.new(0, 170, 0, 16)
UI.performanceDropLabel.Position = UDim2.new(0, 160, 0, 70)
UI.performanceDropLabel.BackgroundTransparency = 1
UI.performanceDropLabel.TextColor3 = Color3.fromRGB(220, 170, 150)
UI.performanceDropLabel.Font = Enum.Font.Code
UI.performanceDropLabel.TextSize = 11
UI.performanceDropLabel.TextXAlignment = Enum.TextXAlignment.Left
UI.performanceDropLabel.ZIndex = 4
UI.performanceDropLabel.Parent = UI.performancePanel

UI.performanceGraph = Instance.new("Frame")
UI.performanceGraph.Size = UDim2.new(1, -20, 0, 46)
UI.performanceGraph.Position = UDim2.new(0, 10, 0, 112)
UI.performanceGraph.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
UI.performanceGraph.BorderSizePixel = 0
UI.performanceGraph.ZIndex = 4
UI.performanceGraph.Parent = UI.performancePanel
mkCorner(UI.performanceGraph, 4)

UI.performanceBars = {}
for i = 1, 25 do
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 4, 1, 0)
	bar.Position = UDim2.new(0, (i-1) * 5, 0, 0)
	bar.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Parent = UI.performanceGraph
	mkCorner(bar, 2)
	UI.performanceBars[i] = bar
end

table.insert(Data.connections, UI.filterPresetDropdown.MouseButton1Click:Connect(function()
	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(0, 120, 0, 100)
	menu.Position = UDim2.new(0, 0, 1, 5)
	menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	menu.BorderSizePixel = 0
	menu.ZIndex = 10
	menu.Parent = UI.filterPresetDropdown
	mkCorner(menu, 3)
	mkStroke(menu, Color3.fromRGB(60, 60, 60), 1)

	local yPos = 0
	for name, _ in pairs(State.advancedFilters.presets) do
		local optBtn = Instance.new("TextButton")
		optBtn.Size = UDim2.new(1, 0, 0, 20)
		optBtn.Position = UDim2.new(0, 0, 0, yPos)
		optBtn.Text = name
		optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		optBtn.Font = Enum.Font.Code
		optBtn.TextSize = 10
		optBtn.ZIndex = 11
		optBtn.Parent = menu
		mkCorner(optBtn, 2)

		table.insert(Data.connections, optBtn.MouseButton1Click:Connect(function()
			loadFilterPreset(name)
			refreshAdvancedFiltersUI()
			doFilter()
			menu:Destroy()
		end))

		yPos = yPos + 20
	end

	task.delay(5, function() if menu and menu.Parent then menu:Destroy() end end)
end))

table.insert(Data.connections, UI.filterLogicDropdown.MouseButton1Click:Connect(function()
	local menu = Instance.new("Frame")
	menu.Size = UDim2.new(0, 50, 0, 40)
	menu.Position = UDim2.new(0, 0, 1, 5)
	menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	menu.BorderSizePixel = 0
	menu.ZIndex = 10
	menu.Parent = UI.filterLogicDropdown
	mkCorner(menu, 3)
	mkStroke(menu, Color3.fromRGB(60, 60, 60), 1)

	local logics = {"AND", "OR"}
	for i, logic in ipairs(logics) do
		local optBtn = Instance.new("TextButton")
		optBtn.Size = UDim2.new(1, 0, 0, 18)
		optBtn.Position = UDim2.new(0, 0, 0, (i-1)*18)
		optBtn.Text = logic
		optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		optBtn.Font = Enum.Font.Code
		optBtn.TextSize = 10
		optBtn.ZIndex = 11
		optBtn.Parent = menu
		mkCorner(optBtn, 2)

		table.insert(Data.connections, optBtn.MouseButton1Click:Connect(function()
			State.advancedFilters.logic = logic
			UI.filterLogicDropdown.Text = logic
			doFilter()
			if dumpCfg then dumpCfg() end
			menu:Destroy()
		end))
	end

	task.delay(5, function() if menu and menu.Parent then menu:Destroy() end end)
end))

table.insert(Data.connections, UI.saveFilterPresetBtn.MouseButton1Click:Connect(function()

	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0, 200, 0, 80)
	dialog.Position = UDim2.new(0.5, -100, 0.5, -40)
	dialog.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	dialog.BorderSizePixel = 0
	dialog.ZIndex = 20
	dialog.Parent = UI.gui
	mkCorner(dialog, 6)
	mkStroke(dialog, Color3.fromRGB(60, 60, 60), 1)

	local title = Instance.new("TextLabel")
	title.Text = "Save Preset"
	title.Size = UDim2.new(1, -20, 0, 20)
	title.Position = UDim2.new(0, 10, 0, 5)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(200, 200, 200)
	title.Font = Enum.Font.Code
	title.TextSize = 12
	title.ZIndex = 21
	title.Parent = dialog

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -20, 0, 20)
	input.Position = UDim2.new(0, 10, 0, 30)
	input.Text = ""
	input.PlaceholderText = "Preset name..."
	input.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	input.TextColor3 = Color3.fromRGB(240, 240, 240)
	input.Font = Enum.Font.Code
	input.TextSize = 11
	input.ZIndex = 21
	input.Parent = dialog
	mkCorner(input, 3)

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0, 40, 0, 20)
	saveBtn.Position = UDim2.new(0, 10, 0, 55)
	saveBtn.Text = "Save"
	saveBtn.BackgroundColor3 = Color3.fromRGB(22, 38, 24)
	saveBtn.TextColor3 = Color3.fromRGB(140, 210, 145)
	saveBtn.Font = Enum.Font.Code
	saveBtn.TextSize = 10
	saveBtn.ZIndex = 21
	saveBtn.Parent = dialog
	mkCorner(saveBtn, 3)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 40, 0, 20)
	cancelBtn.Position = UDim2.new(0, 55, 0, 55)
	cancelBtn.Text = "Cancel"
	cancelBtn.BackgroundColor3 = Color3.fromRGB(38, 22, 22)
	cancelBtn.TextColor3 = Color3.fromRGB(210, 130, 130)
	cancelBtn.Font = Enum.Font.Code
	cancelBtn.TextSize = 10
	cancelBtn.ZIndex = 21
	cancelBtn.Parent = dialog
	mkCorner(cancelBtn, 3)

	table.insert(Data.connections, saveBtn.MouseButton1Click:Connect(function()
		local name = input.Text:match("^%s*(.-)%s*$")
		if name ~= "" then
			saveFilterPreset(name)
			UI.filterPresetDropdown.Text = name
		end
		dialog:Destroy()
	end))

	table.insert(Data.connections, cancelBtn.MouseButton1Click:Connect(function()
		dialog:Destroy()
	end))
end))

table.insert(Data.connections, UI.loadFilterPresetBtn.MouseButton1Click:Connect(function()
	loadFilterPreset(State.advancedFilters.currentPreset)
	refreshAdvancedFiltersUI()
	doFilter()
end))

table.insert(Data.connections, UI.addFilterBtn.MouseButton1Click:Connect(function()
	table.insert(State.advancedFilters.activeFilters, {type = "search", param = "", enabled = true})
	refreshFilterList()
	doFilter()
	if dumpCfg then dumpCfg() end
end))

local function buildFilterRow(filterIndex, filterData)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	row.BorderSizePixel = 0
	row.ZIndex = 5
	mkCorner(row, 4)


	local enableCheck = Instance.new("TextButton")
	enableCheck.Size = UDim2.new(0, 20, 0, 20)
	enableCheck.Position = UDim2.new(0, 5, 0, 5)
	enableCheck.Text = filterData.enabled ~= false and "✓" or "✗"
	enableCheck.BackgroundColor3 = filterData.enabled ~= false and Color3.fromRGB(22, 38, 24) or Color3.fromRGB(38, 22, 22)
	enableCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
	enableCheck.Font = Enum.Font.Code
	enableCheck.TextSize = 12
	enableCheck.ZIndex = 6
	enableCheck.Parent = row
	mkCorner(enableCheck, 2)


	local typeDropdown = Instance.new("TextButton")
	typeDropdown.Size = UDim2.new(0, 90, 1, 0)
	typeDropdown.Position = UDim2.new(0, 30, 0, 0)
	typeDropdown.Text = filterData.type or "search"
	typeDropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	typeDropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
	typeDropdown.Font = Enum.Font.Code
	typeDropdown.TextSize = 10
	typeDropdown.ZIndex = 6
	typeDropdown.Parent = row
	mkCorner(typeDropdown, 3)


	local paramInput = Instance.new("TextBox")
	paramInput.Size = UDim2.new(1, -140, 1, 0)
	paramInput.Position = UDim2.new(0, 125, 0, 0)
	paramInput.Text = filterData.param or ""
	paramInput.PlaceholderText = "parameter..."
	paramInput.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	paramInput.TextColor3 = Color3.fromRGB(240, 240, 240)
	paramInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
	paramInput.Font = Enum.Font.Code
	paramInput.TextSize = 11
	paramInput.ZIndex = 6
	paramInput.Parent = row
	mkCorner(paramInput, 3)


	local removeBtn = Instance.new("TextButton")
	removeBtn.Size = UDim2.new(0, 20, 0, 20)
	removeBtn.Position = UDim2.new(1, -25, 0, 5)
	removeBtn.Text = "×"
	removeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	removeBtn.Font = Enum.Font.Code
	removeBtn.TextSize = 12
	removeBtn.ZIndex = 6
	removeBtn.Parent = row
	mkCorner(removeBtn, 3)


	table.insert(Data.connections, enableCheck.MouseButton1Click:Connect(function()
		filterData.enabled = not (filterData.enabled ~= false)
		enableCheck.Text = filterData.enabled and "✓" or "✗"
		enableCheck.BackgroundColor3 = filterData.enabled and Color3.fromRGB(22, 38, 24) or Color3.fromRGB(38, 22, 22)
		doFilter()
		if dumpCfg then dumpCfg() end
	end))

	table.insert(Data.connections, typeDropdown.MouseButton1Click:Connect(function()
		local menu = Instance.new("Frame")
		menu.Size = UDim2.new(0, 90, 0, 200)
		menu.Position = UDim2.new(0, 0, 1, 5)
		menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		menu.BorderSizePixel = 0
		menu.ZIndex = 10
		menu.Parent = typeDropdown
		mkCorner(menu, 3)
		mkStroke(menu, Color3.fromRGB(60, 60, 60), 1)

		local filterTypes = {
			"search", "player", "priority", "id_exact", "name_exact",
			"player_exact", "priority_exact", "id_pattern", "name_pattern",
			"count_min", "count_max", "favorited"
		}

		for i, filterType in ipairs(filterTypes) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1, 0, 0, 18)
			optBtn.Position = UDim2.new(0, 0, 0, (i-1)*18)
			optBtn.Text = filterType
			optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
			optBtn.Font = Enum.Font.Code
			optBtn.TextSize = 9
			optBtn.ZIndex = 11
			optBtn.Parent = menu
			mkCorner(optBtn, 2)

			table.insert(Data.connections, optBtn.MouseButton1Click:Connect(function()
				filterData.type = filterType
				typeDropdown.Text = filterType
				menu:Destroy()
				doFilter()
				if dumpCfg then dumpCfg() end
			end))
		end

		task.delay(5, function() if menu and menu.Parent then menu:Destroy() end end)
	end))

	table.insert(Data.connections, paramInput:GetPropertyChangedSignal("Text"):Connect(function()
		filterData.param = paramInput.Text
		doFilter()
		if dumpCfg then dumpCfg() end
	end))

	table.insert(Data.connections, removeBtn.MouseButton1Click:Connect(function()
		table.remove(State.advancedFilters.activeFilters, filterIndex)
		row:Destroy()
		doFilter()
		if dumpCfg then dumpCfg() end
	end))

	return row
end

local function refreshFilterList()

	for _, child in ipairs(UI.filterList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end


	for i, filter in ipairs(State.advancedFilters.activeFilters) do
		local row = buildFilterRow(i, filter)
		row.Parent = UI.filterList
	end


	local stats = getFilterStatistics()
	UI.filterStatsLabel.Text = string.format("Stats: %d/%d visible", stats.visible, stats.total)
end

local function refreshAdvancedFiltersUI()
	refreshAdvancedFiltersBtn()
	UI.filterPresetDropdown.Text = State.advancedFilters.currentPreset
	UI.filterLogicDropdown.Text = State.advancedFilters.logic
	UI.advancedFiltersPanel.Visible = State.advancedFilters.enabled
	if State.advancedFilters.enabled then
		refreshFilterList()
	end
end

refreshAdvancedFiltersUI()

local function refreshPerformanceUI()
	local perf = State.performance
	UI.performanceFpsLabel.Text = string.format("FPS: %d", math.floor(perf.fps + 0.5))
	UI.performanceTrackLabel.Text = string.format("Script tracks: %d", perf.activeScriptTracks)
	UI.performancePeakTrackLabel.Text = string.format("Peak tracks: %d", perf.peakScriptTracks or 0)
	UI.performanceLogRateLabel.Text = string.format("Log rate: %.1f/s", perf.logRate)
	UI.performanceMsLabel.Text = string.format("Frame ms: %.2f", (perf.avgFrameTime or 0) * 1000)
	local dropPct = ((perf.droppedFrames or 0) / math.max(perf.frameCount or 1, 1)) * 100
	UI.performanceDropLabel.Text = string.format("Drop >33ms: %.1f%%", dropPct)

	for i, bar in ipairs(UI.performanceBars) do
		local ratio = math.clamp(perf.fps / 60, 0, 1)
		local height = math.clamp((i / #UI.performanceBars) * ratio, 0.05, 1)
		bar.Size = UDim2.new(0, 4, height, 0)
		bar.Position = UDim2.new(0, (i - 1) * 5, 1 - height, 0)
		bar.BackgroundColor3 = Color3.fromHSV(math.clamp(0.4 * ratio, 0, 0.4), 0.85, 0.9)
	end
end

local function updatePerformance(dt)
	local perf = State.performance
	perf.frameCount = (perf.frameCount or 0) + 1
	if dt > (1/30) then perf.droppedFrames = (perf.droppedFrames or 0) + 1 end
	table.insert(perf.frameTimes, dt)
	if #perf.frameTimes > 25 then table.remove(perf.frameTimes, 1) end

	local sum = 0
	for _, v in ipairs(perf.frameTimes) do sum = sum + v end
	perf.avgFrameTime = sum / #perf.frameTimes
	perf.fps = perf.avgFrameTime > 0 and (1 / perf.avgFrameTime) or 0

	local active = 0
	for _ in pairs(Data.scriptTracks) do active = active + 1 end
	perf.activeScriptTracks = active
	perf.peakScriptTracks = math.max(perf.peakScriptTracks or 0, active)
	perf.totalScriptTracks = perf.totalScriptTracks + active

	local elapsed = tick() - perf.logTickStart
	perf.logRate = elapsed > 0 and (perf.totalLogs / elapsed) or 0

	refreshPerformanceUI()
end

local function captureCurrentTrack()
	local animator = grabAnimator()
	if not animator then
		flashNotif("No local animator found", 2, nil, "warn")
		return false
	end
	local chosen
	for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
		if t and t.IsPlaying then chosen = t; break end
	end
	if not chosen then
		flashNotif("No active local track to capture", 2, nil, "warn")
		return false
	end
	local id = grabId(chosen.Animation and chosen.Animation.AnimationId)
	if not id or id == "" then
		flashNotif("Could not resolve animation id", 2, nil, "error")
		return false
	end
	UI.idBox.Text = id
	UI.speedBox.Text = string.format("%.2f", chosen.Speed or 1)
	UI.timeBox.Text = string.format("%.2f", chosen.TimePosition or 0)
	UI.priorityFilterBox.Text = chosen.Priority and chosen.Priority.Name or UI.priorityFilterBox.Text
	flashNotif("Captured track " .. id, 2, nil, "success")
	return true
end

table.insert(Data.connections, UI.captureTrackBtn.MouseButton1Click:Connect(captureCurrentTrack))

UI.toggleKeyBtn = Instance.new("TextButton")
UI.toggleKeyBtn.Text = "Hide Key: " .. State.toggleKey.Name; UI.toggleKeyBtn.Position = UDim2.new(0,10,0,846); UI.toggleKeyBtn.Size = UDim2.new(1,-20,0,26)
UI.toggleKeyBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.toggleKeyBtn.TextColor3 = Color3.fromRGB(160,160,160)
UI.toggleKeyBtn.BorderSizePixel = 0; UI.toggleKeyBtn.Font = Enum.Font.Code; UI.toggleKeyBtn.TextSize = 12; UI.toggleKeyBtn.ZIndex = 3; UI.toggleKeyBtn.Visible = true; UI.toggleKeyBtn.Parent = UI.controls
mkCorner(UI.toggleKeyBtn, 4); mkStroke(UI.toggleKeyBtn, Color3.fromRGB(65,65,65), 1)
table.insert(Data.connections, UI.toggleKeyBtn.MouseButton1Click:Connect(function()
	if State.settingToggleKey then return end
	State.settingToggleKey = true; UI.toggleKeyBtn.Text = "Press any key..."; UI.toggleKeyBtn.TextColor3 = Color3.fromRGB(210,210,210)
	local conn
	conn = Services.UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			conn:Disconnect(); State.settingToggleKey = false; State.toggleKey = input.KeyCode
			UI.toggleKeyBtn.Text = "Hide Key: " .. State.toggleKey.Name; UI.toggleKeyBtn.TextColor3 = Color3.fromRGB(160,160,160); dumpCfg()
		end
	end)
end))

UI.discordBtn = Instance.new("TextButton")
UI.discordBtn.Text = "discord"; UI.discordBtn.Size = UDim2.new(0,70,0,18); UI.discordBtn.Position = UDim2.new(0,6,1,-22)
UI.discordBtn.BackgroundColor3 = Color3.fromRGB(55,60,150); UI.discordBtn.BackgroundTransparency = 0.25; UI.discordBtn.TextColor3 = Color3.fromRGB(180,190,255)
UI.discordBtn.BorderSizePixel = 0; UI.discordBtn.Font = Enum.Font.Code; UI.discordBtn.TextSize = 10; UI.discordBtn.ZIndex = 3; UI.discordBtn.Parent = UI.mainFrame
mkCorner(UI.discordBtn, 4); mkStroke(UI.discordBtn, Color3.fromRGB(80,90,200), 1)
table.insert(Data.connections, UI.discordBtn.MouseButton1Click:Connect(function()
	yoink("discord.gg/u8FTncR4dF"); UI.discordBtn.Text = "copied!"; UI.discordBtn.TextColor3 = Color3.fromRGB(140,220,140)
	task.delay(2, function() UI.discordBtn.Text = "discord"; UI.discordBtn.TextColor3 = Color3.fromRGB(180,190,255) end)
end))

table.insert(Data.connections, Services.RunService.RenderStepped:Connect(function(dt)
	if State.performance.enabled then
		updatePerformance(dt)
	end
end))

table.insert(Data.connections, UI.minimize.MouseButton1Click:Connect(function()
	State.minimized = not State.minimized
	if State.minimized then
		UI.mainFrame.Size = UDim2.new(0,460,0,28)
		for _, v in ipairs({UI.list, UI.favsList, UI.bannedList, UI.controls, UI.searchBox, UI.playerFilterBox, UI.priorityFilterBox,
			UI.logTabBtn, UI.favsTabBtn, UI.bannedTabBtn, UI.logCountLabel, UI.resizeHandle, UI.discordBtn, UI.advancedFiltersPanel, UI.performancePanel,
			UI.commandBar, UI.commandPaletteBtn, UI.commandRunBtn, UI.commandPalette}) do
			v.Visible = false
		end
		UI.minimize.Text = "+"
	else
		UI.mainFrame.Size = UDim2.new(0,820,0,630)
		UI.list.Visible = (State.currentTab == "log"); UI.favsList.Visible = (State.currentTab == "favs"); UI.bannedList.Visible = (State.currentTab == "banned")
		for _, v in ipairs({UI.controls, UI.searchBox, UI.playerFilterBox, UI.priorityFilterBox,
			UI.logTabBtn, UI.favsTabBtn, UI.bannedTabBtn, UI.logCountLabel, UI.resizeHandle, UI.discordBtn, UI.commandBar, UI.commandPaletteBtn, UI.commandRunBtn}) do
			v.Visible = true
		end
		UI.performancePanel.Visible = true
		UI.advancedFiltersPanel.Visible = State.advancedFilters.enabled
		UI.minimize.Text = "-"
	end
end))

table.insert(Data.connections, UI.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if not State.advancedFilters.enabled then
		State.advancedFilters.activeFilters[1].param = UI.searchBox.Text
		doFilter()
	end
end))
table.insert(Data.connections, UI.playerFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
	if not State.advancedFilters.enabled then
		State.advancedFilters.activeFilters[2].param = UI.playerFilterBox.Text
		doFilter()
	end
end))
table.insert(Data.connections, UI.priorityFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
	if not State.advancedFilters.enabled then
		State.advancedFilters.activeFilters[3].param = UI.priorityFilterBox.Text
		doFilter()
	end
end))


UI.sideFrame = Instance.new("Frame")
UI.sideFrame.Name = "SideFrame"
UI.sideFrame.Size = UDim2.new(0, 280, 0, 540)
UI.sideFrame.Position = UDim2.new(0, 660, 0, 50)
UI.sideFrame.BackgroundColor3 = Color3.fromRGB(14,14,14)
UI.sideFrame.BackgroundTransparency = 0.08
UI.sideFrame.BorderSizePixel = 0
UI.sideFrame.Active = true
UI.sideFrame.ClipsDescendants = true
UI.sideFrame.ZIndex = 10
UI.sideFrame.Visible = false
UI.sideFrame.Parent = UI.gui
mkCorner(UI.sideFrame, 8)
do
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(95,95,95)
	s.Thickness = 1.2; s.Transparency = 0.4; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.sideFrame
end


do
	local glow = Instance.new("Frame"); glow.Size = UDim2.new(1,0,0,1); glow.BackgroundColor3 = Color3.fromRGB(160,160,160)
	glow.BackgroundTransparency = 0.6; glow.BorderSizePixel = 0; glow.ZIndex = 10; glow.Parent = UI.sideFrame
end


local function dragSide(input)
	local delta = input.Position - State.dragStartSide
	UI.sideFrame.Position = UDim2.new(State.startPosSide.X.Scale, State.startPosSide.X.Offset + delta.X, State.startPosSide.Y.Scale, State.startPosSide.Y.Offset + delta.Y)
end
table.insert(Data.connections, UI.sideFrame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UI.activeDragger then
		UI.activeDragger = "side"; State.draggingSide = true; State.dragStartSide = input.Position; State.startPosSide = UI.sideFrame.Position
		table.insert(Data.connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				State.draggingSide = false; if UI.activeDragger == "side" then UI.activeDragger = nil end
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


UI.sideResizeHandle = Instance.new("TextButton")
UI.sideResizeHandle.Size = UDim2.new(0, 14, 0, 14)
UI.sideResizeHandle.Position = UDim2.new(1, -14, 1, -14)
UI.sideResizeHandle.BackgroundColor3 = Color3.fromRGB(42,42,42)
UI.sideResizeHandle.BackgroundTransparency = 0.4
UI.sideResizeHandle.Text = "⠿"
UI.sideResizeHandle.TextColor3 = Color3.fromRGB(130,130,130)
UI.sideResizeHandle.Font = Enum.Font.Code
UI.sideResizeHandle.TextSize = 10
UI.sideResizeHandle.BorderSizePixel = 0
UI.sideResizeHandle.ZIndex = 15
UI.sideResizeHandle.Parent = UI.sideFrame
mkCorner(UI.sideResizeHandle, 3)
do
	local sideResizeStart, sideResizeStartSize
	table.insert(Data.connections, UI.sideResizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sideResizeStart = input.Position; sideResizeStartSize = UI.sideFrame.AbsoluteSize
		end
	end))
	table.insert(Data.connections, Services.UserInputService.InputChanged:Connect(function(input)
		if sideResizeStart and input.UserInputType == Enum.UserInputType.MouseMovement then
			if Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				local delta = input.Position - sideResizeStart
				UI.sideFrame.Size = UDim2.new(0, math.max(230, sideResizeStartSize.X + delta.X), 0, math.max(300, sideResizeStartSize.Y + delta.Y))
			else
				sideResizeStart = nil
			end
		end
	end))
end


local sideTop = Instance.new("Frame")
sideTop.Size = UDim2.new(1, 0, 0, 32)
sideTop.BackgroundColor3 = Color3.fromRGB(8,8,8)
sideTop.BackgroundTransparency = 0
sideTop.BorderSizePixel = 0; sideTop.ZIndex = 11; sideTop.Parent = UI.sideFrame
mkCorner(sideTop, 8)
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(20,20,20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,8))})
	g.Rotation = 90; g.Parent = sideTop

	local cover = Instance.new("Frame"); cover.Size = UDim2.new(1,0,0,8); cover.Position = UDim2.new(0,0,1,-8)
	cover.BackgroundColor3 = Color3.fromRGB(8,8,8); cover.BorderSizePixel = 0; cover.ZIndex = 11; cover.Parent = sideTop
end

local sideTitleLbl = Instance.new("TextLabel")
sideTitleLbl.Text = "binds & rules"
sideTitleLbl.Size = UDim2.new(1,-100,1,0); sideTitleLbl.Position = UDim2.new(0,10,0,0)
sideTitleLbl.BackgroundTransparency = 1; sideTitleLbl.TextColor3 = Color3.fromRGB(200,210,220)
sideTitleLbl.Font = Enum.Font.GothamBold; sideTitleLbl.TextSize = 14
sideTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; sideTitleLbl.ZIndex = 12; sideTitleLbl.Parent = sideTop

UI.sideClose = Instance.new("TextButton")
UI.sideClose.Size = UDim2.new(0,22,0,20); UI.sideClose.Position = UDim2.new(1,-25,0,6); UI.sideClose.Text = "X"
UI.sideClose.BackgroundColor3 = Color3.fromRGB(200,50,50); UI.sideClose.TextColor3 = Color3.fromRGB(255,255,255)
UI.sideClose.Font = Enum.Font.GothamSemibold; UI.sideClose.TextSize = 11; UI.sideClose.BorderSizePixel = 0; UI.sideClose.ZIndex = 12; UI.sideClose.Parent = sideTop
mkCorner(UI.sideClose, 4)

UI.sideMinimize = Instance.new("TextButton")
UI.sideMinimize.Size = UDim2.new(0,22,0,20); UI.sideMinimize.Position = UDim2.new(1,-50,0,6); UI.sideMinimize.Text = "-"
UI.sideMinimize.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.sideMinimize.TextColor3 = Color3.fromRGB(140,210,145)
UI.sideMinimize.Font = Enum.Font.GothamSemibold; UI.sideMinimize.TextSize = 11; UI.sideMinimize.BorderSizePixel = 0; UI.sideMinimize.ZIndex = 12; UI.sideMinimize.Parent = sideTop
mkCorner(UI.sideMinimize, 4)


UI.cmdsBtn = Instance.new("TextButton")
UI.cmdsBtn.Size = UDim2.new(0,44,0,20); UI.cmdsBtn.Position = UDim2.new(1,-97,0,6); UI.cmdsBtn.Text = "cmds"
UI.cmdsBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.cmdsBtn.TextColor3 = Color3.fromRGB(140,200,240)
UI.cmdsBtn.Font = Enum.Font.GothamSemibold; UI.cmdsBtn.TextSize = 11; UI.cmdsBtn.BorderSizePixel = 0; UI.cmdsBtn.ZIndex = 12; UI.cmdsBtn.Parent = sideTop
mkCorner(UI.cmdsBtn, 4)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(95,95,95); s.Thickness = 1; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.cmdsBtn end


UI.cmdsPanel = Instance.new("Frame")
UI.cmdsPanel.Size = UDim2.new(1,-10,0,210); UI.cmdsPanel.Position = UDim2.new(0,5,0,36)
UI.cmdsPanel.BackgroundColor3 = Color3.fromRGB(8,8,8); UI.cmdsPanel.BorderSizePixel = 0
UI.cmdsPanel.ZIndex = 13; UI.cmdsPanel.Visible = false; UI.cmdsPanel.ClipsDescendants = true; UI.cmdsPanel.Parent = UI.sideFrame
mkCorner(UI.cmdsPanel, 6)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(95,95,95); s.Thickness = 1; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.cmdsPanel end
do
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1,-10,1,-10); tl.Position = UDim2.new(0,6,0,5)
	tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(160,160,160)
	tl.TextXAlignment = Enum.TextXAlignment.Left; tl.TextYAlignment = Enum.TextYAlignment.Top
	tl.TextWrapped = true; tl.Font = Enum.Font.Code; tl.TextSize = 11; tl.ZIndex = 14
	tl.Text = "COMMANDS (main id box):\npause/freeze  speed [n]  ban [id]  unban [id]\nstop [id]  step [n]  loop  clear  global\nautocopy  priority [name]  weight [n]  fade [t]\nreverse  scrub [pos]  length [n]  export  import\n\nMACRO (use ; to chain):\nplay [id] [speed] [loop?]  wait [secs]  stop [id]\nspeed [n]  ramp [start] [end] [time]  priority [name]\nweight [n]  fade [t]  reverse  scrub [pos]  step [n]\nlength [n]  var [name] [val]  add [name] [amt]  mul [name] [fac]\nuse [name]  if [var] [op] [val]  goto [label]  label [name]\nrepeat [count] ... endrepeat  random [min] [max]\nsin [freq] [amp] [offset] [time]  cos [freq] [amp] [offset] [time]\nlerp [start] [end] [time]\n\nEXAMPLES:\nramp 1 3 2; wait 2; ramp 3 0.5 1\nrepeat 3 play 123; wait 0.5 endrepeat\nvar spd 1; add spd 0.5; use spd\nif spd > 2 goto fast; speed 1; label fast"
	tl.Parent = UI.cmdsPanel
end
table.insert(Data.connections, UI.cmdsBtn.MouseButton1Click:Connect(function()
	UI.cmdsPanel.Visible = not UI.cmdsPanel.Visible
	UI.cmdsBtn.BackgroundColor3 = UI.cmdsPanel.Visible and Color3.fromRGB(65,65,65) or Color3.fromRGB(28,28,28)
end))


UI.cmdsTooltip = Instance.new("Frame")
UI.cmdsTooltip.Size = UDim2.new(0,1,0,1); UI.cmdsTooltip.Visible = false; UI.cmdsTooltip.Parent = UI.gui

local groupBar = Instance.new("Frame")
groupBar.Name = "GroupBar"
groupBar.Size = UDim2.new(1,-10,0,26); groupBar.Position = UDim2.new(0,5,0,36)
groupBar.BackgroundColor3 = Color3.fromRGB(8,8,8); groupBar.BackgroundTransparency = 0.15; groupBar.BorderSizePixel = 0; groupBar.ZIndex = 11; groupBar.Parent = UI.sideFrame
mkCorner(groupBar, 5)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(95,95,95); s.Thickness = 1; s.Transparency = 0.6; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = groupBar end

UI.groupNameBox = Instance.new("TextBox")
UI.groupNameBox.PlaceholderText = "group name..."; UI.groupNameBox.Text = ""
UI.groupNameBox.Size = UDim2.new(1,-106,1,-4); UI.groupNameBox.Position = UDim2.new(0,4,0,2)
UI.groupNameBox.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.groupNameBox.TextColor3 = Color3.fromRGB(210,210,210)
UI.groupNameBox.PlaceholderColor3 = Color3.fromRGB(65,65,65); UI.groupNameBox.Font = Enum.Font.Code
UI.groupNameBox.TextSize = 11; UI.groupNameBox.BorderSizePixel = 0; UI.groupNameBox.ZIndex = 12; UI.groupNameBox.Parent = groupBar
mkCorner(UI.groupNameBox, 4)

UI.saveGroupBtn = Instance.new("TextButton")
UI.saveGroupBtn.Text = "Save"; UI.saveGroupBtn.Size = UDim2.new(0,48,1,-4); UI.saveGroupBtn.Position = UDim2.new(1,-102,0,2)
UI.saveGroupBtn.BackgroundColor3 = Color3.fromRGB(42,42,42); UI.saveGroupBtn.TextColor3 = Color3.fromRGB(160,160,160)
UI.saveGroupBtn.Font = Enum.Font.GothamSemibold; UI.saveGroupBtn.TextSize = 11; UI.saveGroupBtn.BorderSizePixel = 0; UI.saveGroupBtn.ZIndex = 12; UI.saveGroupBtn.Parent = groupBar
mkCorner(UI.saveGroupBtn, 4)

UI.loadGroupBtn = Instance.new("TextButton")
UI.loadGroupBtn.Text = "Load"; UI.loadGroupBtn.Size = UDim2.new(0,48,1,-4); UI.loadGroupBtn.Position = UDim2.new(1,-50,0,2)
UI.loadGroupBtn.BackgroundColor3 = Color3.fromRGB(20,20,20); UI.loadGroupBtn.TextColor3 = Color3.fromRGB(160,160,160)
UI.loadGroupBtn.Font = Enum.Font.GothamSemibold; UI.loadGroupBtn.TextSize = 11; UI.loadGroupBtn.BorderSizePixel = 0; UI.loadGroupBtn.ZIndex = 12; UI.loadGroupBtn.Parent = groupBar
mkCorner(UI.loadGroupBtn, 4)

UI.groupDropdown = Instance.new("Frame")
UI.groupDropdown.Size = UDim2.new(1,-10,0,0); UI.groupDropdown.Position = UDim2.new(0,5,0,66)
UI.groupDropdown.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.groupDropdown.BorderSizePixel = 0
UI.groupDropdown.ZIndex = 25; UI.groupDropdown.ClipsDescendants = true; UI.groupDropdown.Visible = false; UI.groupDropdown.Parent = UI.sideFrame
mkCorner(UI.groupDropdown, 5)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(65,65,65); s.Thickness = 1; s.Transparency = 0.4; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.groupDropdown end
do local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0,2); l.Parent = UI.groupDropdown end


local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1,-10,0,30); tabBar.Position = UDim2.new(0,5,0,66)
tabBar.BackgroundColor3 = Color3.fromRGB(8,8,8); tabBar.BackgroundTransparency = 0.15; tabBar.BorderSizePixel = 0; tabBar.ZIndex = 11; tabBar.Parent = UI.sideFrame
mkCorner(tabBar, 6)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(95,95,95); s.Thickness = 1; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = tabBar end


local sideSearchBox = Instance.new("TextBox")
sideSearchBox.PlaceholderText = "search binds / repls..."; sideSearchBox.Text = ""
sideSearchBox.Size = UDim2.new(1,-10,0,24); sideSearchBox.Position = UDim2.new(0,5,0,100)
sideSearchBox.BackgroundColor3 = Color3.fromRGB(8,8,8); sideSearchBox.TextColor3 = Color3.fromRGB(210,210,210)
sideSearchBox.PlaceholderColor3 = Color3.fromRGB(65,65,65); sideSearchBox.Font = Enum.Font.Code; sideSearchBox.TextSize = 11
sideSearchBox.BorderSizePixel = 0; sideSearchBox.ZIndex = 11; sideSearchBox.Parent = UI.sideFrame
mkCorner(sideSearchBox, 5)
do local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(95,95,95); s.Thickness=1; s.Transparency=0.5; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=sideSearchBox end

local TAB_NAMES = {"Binds","Repls","Adv"}
local TAB_COLORS = {
	active   = {Color3.fromRGB(220,220,220), Color3.fromRGB(255,215,0), Color3.fromRGB(200,50,50)},
	inactive = {Color3.fromRGB(20,20,20), Color3.fromRGB(20,20,20), Color3.fromRGB(20,20,20)},
}
local sideTabBtns = {}
local sideTabLists = {}
local sideTabLayouts = {}
local sideTabUnderlines = {}
local State_sideTab = 1

for i, name in ipairs(TAB_NAMES) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1/#TAB_NAMES, -4, 1, -6)
	btn.Position = UDim2.new((i-1)/#TAB_NAMES, 2+((i-1)*2), 0, 3)
	btn.Text = name
	btn.BackgroundColor3 = i == 1 and TAB_COLORS.active[i] or TAB_COLORS.inactive[i]
	btn.TextColor3 = i == 1 and Color3.fromRGB(20,20,20) or Color3.fromRGB(95,95,95)
	btn.Font = Enum.Font.Code; btn.TextSize = 12; btn.BorderSizePixel = 0; btn.ZIndex = 12; btn.Parent = tabBar
	mkCorner(btn, 5)
	
	local underline = Instance.new("Frame")
	underline.Size = UDim2.new(0.7, 0, 0, 2)
	underline.Position = UDim2.new(0.15, 0, 1, -3)
	underline.BackgroundColor3 = i == 1 and Color3.fromRGB(20,20,20) or (i == 2 and Color3.fromRGB(200,170,0) or Color3.fromRGB(180,40,40))
	underline.BorderSizePixel = 0; underline.ZIndex = 13
	underline.Visible = i == 1; underline.Parent = btn
	mkCorner(underline, 1)
	sideTabBtns[i] = btn
	sideTabUnderlines[i] = underline

	local sf = Instance.new("ScrollingFrame")
	sf.Size = UDim2.new(1,-10,1,-164); sf.Position = UDim2.new(0,5,0,128)
	sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 3; sf.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
	sf.CanvasSize = UDim2.new(0,0,0,0); sf.ClipsDescendants = true
	sf.ZIndex = 11; sf.Visible = i == 1; sf.Parent = UI.sideFrame
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0,6); layout.Parent = sf
	table.insert(Data.connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sf.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
	end))
	sideTabLists[i] = sf
	sideTabLayouts[i] = layout
end


UI.sideList  = sideTabLists[1]
UI.sideLayout = sideTabLayouts[1]

local function switchSideTab(idx)
	State_sideTab = idx
	for i, btn in ipairs(sideTabBtns) do
		btn.BackgroundColor3 = i == idx and TAB_COLORS.active[i] or TAB_COLORS.inactive[i]
		btn.TextColor3 = i == idx and Color3.fromRGB(20,20,20) or Color3.fromRGB(95,95,95)
		sideTabLists[i].Visible = i == idx
		if sideTabUnderlines[i] then 
			sideTabUnderlines[i].Visible = i == idx
			sideTabUnderlines[i].BackgroundColor3 = i == 1 and Color3.fromRGB(20,20,20) or (i == 2 and Color3.fromRGB(200,170,0) or Color3.fromRGB(180,40,40))
		end
	end
end
switchSideTab(1)
for i in ipairs(TAB_NAMES) do
	table.insert(Data.connections, sideTabBtns[i].MouseButton1Click:Connect(function() switchSideTab(i) end))
end


local sideBottomBar = Instance.new("Frame")
sideBottomBar.Size = UDim2.new(1,-10,0,32); sideBottomBar.Position = UDim2.new(0,5,1,-38)
sideBottomBar.BackgroundColor3 = Color3.fromRGB(8,8,8); sideBottomBar.BackgroundTransparency = 0.15; sideBottomBar.BorderSizePixel = 0; sideBottomBar.ZIndex = 11; sideBottomBar.Parent = UI.sideFrame
mkCorner(sideBottomBar, 6)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(95,95,95); s.Thickness = 1; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = sideBottomBar end

UI.addB = Instance.new("TextButton")
UI.addB.Size = UDim2.new(1,-10,1,-6); UI.addB.Position = UDim2.new(0,5,0,3)
UI.addB.Text = "＋ Add Bind"
UI.addB.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.addB.TextColor3 = Color3.fromRGB(140,210,145)
UI.addB.Font = Enum.Font.GothamBold; UI.addB.TextSize = 14; UI.addB.BorderSizePixel = 0; UI.addB.ZIndex = 12; UI.addB.Parent = sideBottomBar
mkCorner(UI.addB, 5)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(45,80,48); s.Thickness = 1; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.addB end

UI.addR = Instance.new("TextButton")
UI.addR.Size = UDim2.new(1,-10,1,-6); UI.addR.Position = UDim2.new(0,5,0,3)
UI.addR.Text = "＋ Add Replacement"
UI.addR.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.addR.TextColor3 = Color3.fromRGB(140,210,145)
UI.addR.Font = Enum.Font.GothamBold; UI.addR.TextSize = 14; UI.addR.BorderSizePixel = 0; UI.addR.ZIndex = 12; UI.addR.Visible = false; UI.addR.Parent = sideBottomBar
mkCorner(UI.addR, 5)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(45,80,48); s.Thickness = 1; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.addR end

UI.addAdvReplBtn = Instance.new("TextButton")
UI.addAdvReplBtn.Size = UDim2.new(1,-10,1,-6); UI.addAdvReplBtn.Position = UDim2.new(0,5,0,3)
UI.addAdvReplBtn.Text = "＋ Add Adv Replacement"
UI.addAdvReplBtn.BackgroundColor3 = Color3.fromRGB(200,50,50); UI.addAdvReplBtn.TextColor3 = Color3.fromRGB(255,255,255)
UI.addAdvReplBtn.Font = Enum.Font.GothamBold; UI.addAdvReplBtn.TextSize = 14; UI.addAdvReplBtn.BorderSizePixel = 0; UI.addAdvReplBtn.ZIndex = 12; UI.addAdvReplBtn.Visible = false; UI.addAdvReplBtn.Parent = sideBottomBar
mkCorner(UI.addAdvReplBtn, 5)
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180,40,40); s.Thickness = 1; s.Transparency = 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = UI.addAdvReplBtn end


local origSwitchSideTab = switchSideTab
switchSideTab = function(idx)
	origSwitchSideTab(idx)
	UI.addB.Visible        = idx == 1
	UI.addR.Visible        = idx == 2
	UI.addAdvReplBtn.Visible = idx == 3
	
	local q = sideSearchBox.Text:lower()
	if q ~= "" then
		for _, child in ipairs(sideTabLists[idx]:GetChildren()) do
			if child:IsA("Frame") then
				local text = child.Name:lower()
				
				for _, d in ipairs(child:GetDescendants()) do
					if (d:IsA("TextBox") or d:IsA("TextLabel")) and d.Text ~= "" then
						text = text .. " " .. d.Text:lower()
					end
				end
				child.Visible = text:find(q, 1, true) ~= nil
			end
		end
	else
		for _, child in ipairs(sideTabLists[idx]:GetChildren()) do
			if child:IsA("Frame") then child.Visible = true end
		end
	end
end

local function applySideSearch()
	local q = sideSearchBox.Text:lower()
	local sf = sideTabLists[State_sideTab]
	for _, child in ipairs(sf:GetChildren()) do
		if child:IsA("Frame") then
			if q == "" then child.Visible = true; continue end
			local text = child.Name:lower()
			for _, d in ipairs(child:GetDescendants()) do
				if (d:IsA("TextBox") or d:IsA("TextLabel")) and d.Text ~= "" then
					text = text .. " " .. d.Text:lower()
				end
			end
			child.Visible = text:find(q, 1, true) ~= nil
		end
	end
end
table.insert(Data.connections, sideSearchBox:GetPropertyChangedSignal("Text"):Connect(applySideSearch))


local function refreshGroupDropdown()
	for _, c in ipairs(UI.groupDropdown:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	local count = 0
	for name, _ in pairs(Data.keybindGroups) do
		count += 1
		local btn = Instance.new("TextButton"); btn.Text = name; btn.Size = UDim2.new(1,0,0,24)
		btn.BackgroundColor3 = Color3.fromRGB(14,14,14); btn.TextColor3 = Color3.fromRGB(160,160,160)
		btn.Font = Enum.Font.Code; btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BorderSizePixel = 0; btn.ZIndex = 26; btn.Parent = UI.groupDropdown
		table.insert(Data.connections, btn.MouseButton1Click:Connect(function()
			local data = Data.keybindGroups[name]; if not data then return end
			for _, bind in pairs(Data.keybinds) do killAnim(bind.id) end
			for _, c in ipairs(UI.sideList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			Data.keybinds = {}
			for _, b in pairs(data) do
				local nb = {id=b.id, key=b.key and Enum.KeyCode[b.key] or nil, hold=b.hold or false, speed=b.speed or 1, loop=b.loop or false, active=false, tracks={}, token=0}
				table.insert(Data.keybinds, nb); addBind(nb)
			end
			dumpBinds(); UI.groupNameBox.Text = name; UI.groupDropdown.Visible = false
		end))
	end
	UI.groupDropdown.Size = UDim2.new(1,-10,0,count * 26)
end

table.insert(Data.connections, UI.saveGroupBtn.MouseButton1Click:Connect(function()
	local name = UI.groupNameBox.Text:match("^%s*(.-)%s*$"); if name == "" then return end
	local data = {}
	for _, bind in pairs(Data.keybinds) do
		table.insert(data, {id=bind.id, key=bind.key and bind.key.Name or nil, hold=bind.hold or false, speed=bind.speed or 1, loop=bind.loop or false})
	end
	Data.keybindGroups[name] = data; dumpGroups(); UI.saveGroupBtn.Text = "Saved!"
	task.delay(1.5, function() UI.saveGroupBtn.Text = "Save" end)
end))
table.insert(Data.connections, UI.loadGroupBtn.MouseButton1Click:Connect(function()
	refreshGroupDropdown(); UI.groupDropdown.Visible = not UI.groupDropdown.Visible
end))


table.insert(Data.connections, UI.sideMinimize.MouseButton1Click:Connect(function()
	State.sideMinimized = not State.sideMinimized
	if State.sideMinimized then
		State.sideFrameLastH = UI.sideFrame.AbsoluteSize.Y
		UI.sideFrame.Size = UDim2.new(0, UI.sideFrame.AbsoluteSize.X, 0, 32)
		for _, sf in ipairs(sideTabLists) do sf.Visible = false end
		tabBar.Visible = false; groupBar.Visible = false; sideBottomBar.Visible = false
		sideSearchBox.Visible = false
		UI.sideResizeHandle.Visible = false
		UI.sideMinimize.Text = "+"
	else
		UI.sideFrame.Size = UDim2.new(0, UI.sideFrame.AbsoluteSize.X, 0, State.sideFrameLastH or 540)
		sideTabLists[State_sideTab].Visible = true
		tabBar.Visible = true; groupBar.Visible = true; sideBottomBar.Visible = true
		sideSearchBox.Visible = true
		UI.sideResizeHandle.Visible = true
		UI.sideMinimize.Text = "-"
	end
end))
table.insert(Data.connections, UI.sideClose.MouseButton1Click:Connect(function() UI.sideFrame.Visible = false end))

UI.viewportWin = Instance.new("Frame")
local viewportWin = UI.viewportWin
viewportWin.Name = "ViewportWindow"; viewportWin.Size = UDim2.new(0,300,0,660); viewportWin.Position = UDim2.new(0,670,0,380)
viewportWin.BackgroundColor3 = Color3.fromRGB(14,14,14); viewportWin.BackgroundTransparency = 0.15; viewportWin.BorderSizePixel = 0; viewportWin.Active = true
viewportWin.ClipsDescendants = true; viewportWin.ZIndex = 5; viewportWin.Visible = false; viewportWin.Parent = UI.gui
mkCorner(viewportWin, 10); mkStroke(viewportWin, Color3.fromRGB(65,65,65), 1)

local function dragVP(input)
	local delta = input.Position - State.dragStartVP
	viewportWin.Position = UDim2.new(State.startPosVP.X.Scale, State.startPosVP.X.Offset + delta.X, State.startPosVP.Y.Scale, State.startPosVP.Y.Offset + delta.Y)
end

table.insert(Data.connections, viewportWin.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UI.activeDragger then
		UI.activeDragger = "vp"; State.draggingVP = true; State.dragStartVP = input.Position; State.startPosVP = viewportWin.Position
		do local px, py = input.Position.X, input.Position.Y; local fp = UI.vpFrame.AbsolutePosition; local fs = UI.vpFrame.AbsoluteSize
			if px >= fp.X and px <= fp.X + fs.X and py >= fp.Y and py <= fp.Y + fs.Y then State.draggingVP = false; if UI.activeDragger == "vp" then UI.activeDragger = nil end; return end
		end
		table.insert(Data.connections, input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				State.draggingVP = false; if UI.activeDragger == "vp" then UI.activeDragger = nil end
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

local vpTop = Instance.new("Frame"); vpTop.Size = UDim2.new(1,0,0,25); vpTop.BackgroundColor3 = Color3.fromRGB(20,20,20); vpTop.BackgroundTransparency = 0; vpTop.BorderSizePixel = 0; vpTop.ZIndex = 6; vpTop.Parent = viewportWin
do local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(42,42,42)),ColorSequenceKeypoint.new(1,Color3.fromRGB(20,20,20))}); g.Rotation = 90; g.Parent = vpTop end
UI.vpTitle = Instance.new("TextLabel"); UI.vpTitle.Text = "preview"; UI.vpTitle.Position = UDim2.new(0,55,0,0); UI.vpTitle.Size = UDim2.new(1,-175,1,0); UI.vpTitle.BackgroundTransparency = 1; UI.vpTitle.TextColor3 = Color3.fromRGB(160,160,160); UI.vpTitle.Font = Enum.Font.Code; UI.vpTitle.TextSize = 13; UI.vpTitle.ZIndex = 7; UI.vpTitle.Parent = vpTop
UI.vpClose = Instance.new("TextButton"); UI.vpClose.Size = UDim2.new(0,25,0,20); UI.vpClose.Position = UDim2.new(1,-27,0,3); UI.vpClose.Text = "X"; UI.vpClose.BackgroundColor3 = Color3.fromRGB(120,30,30); UI.vpClose.TextColor3 = Color3.fromRGB(255,255,255); UI.vpClose.BorderSizePixel = 0; UI.vpClose.Font = Enum.Font.Code; UI.vpClose.TextSize = 11; UI.vpClose.ZIndex = 7; UI.vpClose.Parent = vpTop; mkCorner(UI.vpClose,4); mkStroke(UI.vpClose, Color3.fromRGB(200,50,50), 1)
UI.vpMinimize = Instance.new("TextButton"); UI.vpMinimize.Size = UDim2.new(0,25,0,20); UI.vpMinimize.Position = UDim2.new(1,-54,0,3); UI.vpMinimize.Text = "-"; UI.vpMinimize.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.vpMinimize.TextColor3 = Color3.fromRGB(140,210,145); UI.vpMinimize.BorderSizePixel = 0; UI.vpMinimize.Font = Enum.Font.Code; UI.vpMinimize.TextSize = 11; UI.vpMinimize.ZIndex = 7; UI.vpMinimize.Parent = vpTop; mkCorner(UI.vpMinimize,4); mkStroke(UI.vpMinimize, Color3.fromRGB(45,80,48), 1)
table.insert(Data.connections, UI.vpClose.MouseButton1Click:Connect(function() UI.viewportWin.Visible = false end))
table.insert(Data.connections, UI.vpMinimize.MouseButton1Click:Connect(function()
	State.vpMinimized = not State.vpMinimized
	UI.viewportWin.Size = State.vpMinimized and UDim2.new(0,300,0,28) or UDim2.new(0,300,0,660)
	UI.vpMinimize.Text = State.vpMinimized and "+" or "-"
end))

UI.vpIdInput = Instance.new("TextBox"); UI.vpIdInput.Text = ""; UI.vpIdInput.PlaceholderText = "animation id..."
UI.vpIdInput.Position = UDim2.new(0,5,0,30); UI.vpIdInput.Size = UDim2.new(1,-55,0,24)
UI.vpIdInput.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.vpIdInput.TextColor3 = Color3.fromRGB(210,210,210); UI.vpIdInput.PlaceholderColor3 = Color3.fromRGB(65,65,65)
UI.vpIdInput.BorderSizePixel = 0; UI.vpIdInput.Font = Enum.Font.Code; UI.vpIdInput.TextSize = 12; UI.vpIdInput.ZIndex = 7; UI.vpIdInput.Parent = UI.viewportWin
mkCorner(UI.vpIdInput,4); mkStroke(UI.vpIdInput, Color3.fromRGB(42,42,42), 1)

UI.vpIdGoBtn = Instance.new("TextButton"); UI.vpIdGoBtn.Text = "▶"; UI.vpIdGoBtn.Position = UDim2.new(1,-47,0,30); UI.vpIdGoBtn.Size = UDim2.new(0,42,0,24)
UI.vpIdGoBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.vpIdGoBtn.TextColor3 = Color3.fromRGB(140,210,145); UI.vpIdGoBtn.BorderSizePixel = 0; UI.vpIdGoBtn.Font = Enum.Font.Code; UI.vpIdGoBtn.TextSize = 13; UI.vpIdGoBtn.ZIndex = 7; UI.vpIdGoBtn.Parent = UI.viewportWin
mkCorner(UI.vpIdGoBtn, 4)

UI.vpFrame = Instance.new("ViewportFrame"); UI.vpFrame.Size = UDim2.new(1,-10,0,220); UI.vpFrame.Position = UDim2.new(0,5,0,58)
UI.vpFrame.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.vpFrame.BorderSizePixel = 0; UI.vpFrame.ZIndex = 6; UI.vpFrame.Parent = UI.viewportWin
mkCorner(UI.vpFrame,4); mkStroke(UI.vpFrame, Color3.fromRGB(42,42,42), 1)
UI.vpCamera = Instance.new("Camera"); UI.vpCamera.Parent = UI.vpFrame; UI.vpFrame.CurrentCamera = UI.vpCamera
UI.worldModel = Instance.new("WorldModel"); UI.worldModel.Parent = UI.vpFrame
UI.vpFrame.Ambient = Color3.fromRGB(95,95,95); UI.vpFrame.LightDirection = Vector3.new(-1,-2,-1)
local vpCamHint = Instance.new("TextLabel"); vpCamHint.Size = UDim2.new(1,-10,0,12); vpCamHint.Position = UDim2.new(0,5,0,260); vpCamHint.Text = "Left/Right-drag: rotate  |  Scroll: zoom"
vpCamHint.BackgroundTransparency = 1; vpCamHint.TextColor3 = Color3.fromRGB(100,100,100); vpCamHint.Font = Enum.Font.Code; vpCamHint.TextSize = 10; vpCamHint.ZIndex = 6; vpCamHint.Parent = UI.viewportWin
local worldModel = UI.worldModel
local vpCamera = UI.vpCamera

UI.vpIdLabel = Instance.new("TextLabel"); UI.vpIdLabel.Text = "no animation selected"; UI.vpIdLabel.Position = UDim2.new(0,5,0,284); UI.vpIdLabel.Size = UDim2.new(1,-10,0,14)
UI.vpIdLabel.BackgroundTransparency = 1; UI.vpIdLabel.TextColor3 = Color3.fromRGB(95,95,95); UI.vpIdLabel.Font = Enum.Font.Code; UI.vpIdLabel.TextSize = 11; UI.vpIdLabel.TextXAlignment = Enum.TextXAlignment.Left; UI.vpIdLabel.ZIndex = 6; UI.vpIdLabel.Parent = viewportWin

UI.vpTimerLabel = Instance.new("TextLabel"); UI.vpTimerLabel.Text = "-- / --"; UI.vpTimerLabel.Position = UDim2.new(0,5,0,300); UI.vpTimerLabel.Size = UDim2.new(1,-10,0,14)
UI.vpTimerLabel.BackgroundTransparency = 1; UI.vpTimerLabel.TextColor3 = Color3.fromRGB(160,160,160); UI.vpTimerLabel.TextXAlignment = Enum.TextXAlignment.Left; UI.vpTimerLabel.Font = Enum.Font.Code; UI.vpTimerLabel.TextSize = 11; UI.vpTimerLabel.ZIndex = 6; UI.vpTimerLabel.Parent = viewportWin

UI.vpScrubBg = Instance.new("Frame"); UI.vpScrubBg.Position = UDim2.new(0,5,0,317); UI.vpScrubBg.Size = UDim2.new(1,-10,0,12)
UI.vpScrubBg.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.vpScrubBg.BackgroundTransparency = 0.15; UI.vpScrubBg.BorderSizePixel = 0; UI.vpScrubBg.ZIndex = 6; UI.vpScrubBg.Parent = viewportWin; mkCorner(UI.vpScrubBg,6)
UI.vpScrubFill = Instance.new("Frame"); UI.vpScrubFill.Size = UDim2.new(0,0,1,0); UI.vpScrubFill.BackgroundColor3 = Color3.fromRGB(200,50,50); UI.vpScrubFill.BorderSizePixel = 0; UI.vpScrubFill.ZIndex = 7; UI.vpScrubFill.Parent = UI.vpScrubBg
UI.vpScrubBtn = Instance.new("TextButton"); UI.vpScrubBtn.Size = UDim2.new(1,0,1,0); UI.vpScrubBtn.BackgroundTransparency = 1; UI.vpScrubBtn.Text = ""; UI.vpScrubBtn.ZIndex = 8; UI.vpScrubBtn.Parent = UI.vpScrubBg

local function nukeGhost()
	if Data.vpTrack then pcall(function() Data.vpTrack:Stop(0) end); Data.vpTrack = nil end
	Data.vpAnimator = nil; Data.vpRootPart = nil
	if Data.ghostChar then pcall(function() Data.ghostChar:Destroy() end); Data.ghostChar = nil end
	for _, obj in ipairs(worldModel:GetChildren()) do pcall(function() obj:Destroy() end) end
	for k in pairs(Data.dummyTracks) do Data.dummyTracks[k] = nil end
end

UI.vpPauseBtn = Instance.new("TextButton"); UI.vpPauseBtn.Text = "⏸ Pause"; UI.vpPauseBtn.Position = UDim2.new(0,5,0,328); UI.vpPauseBtn.Size = UDim2.new(1,-10,0,20)
UI.vpPauseBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); UI.vpPauseBtn.TextColor3 = Color3.fromRGB(210,210,210); UI.vpPauseBtn.BorderSizePixel = 0; UI.vpPauseBtn.Font = Enum.Font.Code; UI.vpPauseBtn.TextSize = 11; UI.vpPauseBtn.ZIndex = 6; UI.vpPauseBtn.Parent = UI.viewportWin; mkCorner(UI.vpPauseBtn,4)
mkStroke(UI.vpPauseBtn, Color3.fromRGB(65,65,65), 1)
local spawnDummyPaused = false
local spawnDummyPausedAt = 0
table.insert(Data.connections, UI.vpPauseBtn.MouseButton1Click:Connect(function()
	if not State.vpPaused and not Data.vpTrack and not Data.spawnDummyTrack then return end
	State.vpPaused = not State.vpPaused
	if State.vpPaused then
		State.vpPausedAt = Data.vpTrack and Data.vpTrack.TimePosition or 0
		State.vpPausedLength = Data.vpTrack and Data.vpTrack.Length or 0
		if Data.vpTrack then 
			local pos = Data.vpTrack.TimePosition
			pcall(function() Data.vpTrack:Stop(0) end); Data.vpTrack = nil
			State.vpPausedAt = pos
		end
		if Data.vpAnimator then pcall(function() Data.vpAnimator:Destroy() end); Data.vpAnimator = nil end
		if Data.spawnDummyTrack then
			spawnDummyPausedAt = Data.spawnDummyTrack.TimePosition
			spawnDummyPaused = true
			pcall(function() Data.spawnDummyTrack:Stop(0) end); Data.spawnDummyTrack = nil
			if Data.spawnDummyAnimator then pcall(function() Data.spawnDummyAnimator:Destroy() end); Data.spawnDummyAnimator = nil end
		end
	else
		if State.vpCurrentId and State.vpCurrentId ~= "" and Data.ghostChar then
			local hum = Data.ghostChar:FindFirstChildOfClass("Humanoid")
			if hum then
				if Data.vpAnimator then pcall(function() Data.vpAnimator:Destroy() end) end
				local animator = Instance.new("Animator"); animator.Parent = hum; Data.vpAnimator = animator
				local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. State.vpCurrentId
				local track; pcall(function() track = animator:LoadAnimation(anim) end)
				if track then
					track.Priority = Enum.AnimationPriority.Action4; track.Looped = State.vpLooped
					track:Play(0,1,0); track.TimePosition = State.vpPausedAt; Data.vpTrack = track
					task.defer(function() if Data.vpTrack == track then track:AdjustSpeed(tonumber(UI.vpSpeedBox.Text) or 1) end end)
				end
			end
		end
		if spawnDummyPaused and Data.spawnDummy and State.vpCurrentId then
			local hum = Data.spawnDummy:FindFirstChildOfClass("Humanoid")
			if hum then
				if Data.spawnDummyAnimator then pcall(function() Data.spawnDummyAnimator:Destroy() end) end
				local animator = Instance.new("Animator"); animator.Parent = hum; Data.spawnDummyAnimator = animator
				local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. State.vpCurrentId
				local track; pcall(function() track = animator:LoadAnimation(anim) end)
				if track then
					track.Priority = Enum.AnimationPriority.Action4; track.Looped = State.vpLooped
					track:Play(0,1,0); track.TimePosition = spawnDummyPausedAt; Data.spawnDummyTrack = track
					task.defer(function() if Data.spawnDummyTrack == track then track:AdjustSpeed(tonumber(UI.vpSpeedBox.Text) or 1) end end)
				end
			end
			spawnDummyPaused = false
		end
	end
	UI.vpPauseBtn.Text = State.vpPaused and "▶ Resume" or "⏸ Pause"
	UI.vpPauseBtn.BackgroundColor3 = State.vpPaused and Color3.fromRGB(42,42,42) or Color3.fromRGB(28,28,28)
end))

table.insert(Data.connections, UI.vpScrubBtn.MouseButton1Down:Connect(function()
	State.vpScrubbing = true
	if State.vpPaused and Data.ghostChar and State.vpCurrentId and State.vpCurrentId ~= "" then
		local hum = Data.ghostChar:FindFirstChildOfClass("Humanoid")
		if hum then
			if Data.vpAnimator then pcall(function() Data.vpAnimator:Destroy() end) end
			local animator = Instance.new("Animator"); animator.Parent = hum; Data.vpAnimator = animator
			local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. State.vpCurrentId
			pcall(function() Data.vpScrubTrack = animator:LoadAnimation(anim) end)
			if Data.vpScrubTrack then
				Data.vpScrubTrack.Priority = Enum.AnimationPriority.Action4; Data.vpScrubTrack:Play(0,1,0); Data.vpScrubTrack.TimePosition = State.vpPausedAt
			end
		end
	end
	if State.vpPaused and Data.spawnDummy and State.vpCurrentId then
		local hum = Data.spawnDummy:FindFirstChildOfClass("Humanoid")
		if hum then
			local animator = Instance.new("Animator"); animator.Parent = hum
			local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. State.vpCurrentId
			local track; pcall(function() track = animator:LoadAnimation(anim) end)
			if track then
				track.Priority = Enum.AnimationPriority.Action4; track:Play(0,1,0); track.TimePosition = spawnDummyPausedAt
				Data.tempSpawnScrubTrack = track
			end
		end
	end
end))
table.insert(Data.connections, Services.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and State.vpScrubbing then
		State.vpScrubbing = false; Data.vpScrubTrack = nil
		if Data.tempSpawnScrubTrack then pcall(function() Data.tempSpawnScrubTrack:Stop(0) end); Data.tempSpawnScrubTrack = nil end
	end
end))

do
	local vpSpeedLabel = Instance.new("TextLabel"); vpSpeedLabel.Text = "Speed"; vpSpeedLabel.Position = UDim2.new(0,5,0,353); vpSpeedLabel.Size = UDim2.new(0,40,0,20)
	vpSpeedLabel.BackgroundTransparency = 1; vpSpeedLabel.TextColor3 = Color3.fromRGB(95,95,95); vpSpeedLabel.Font = Enum.Font.Code; vpSpeedLabel.TextSize = 12; vpSpeedLabel.ZIndex = 6; vpSpeedLabel.Parent = UI.viewportWin
end
UI.vpSpeedBox = Instance.new("TextBox"); UI.vpSpeedBox.Text = "1"; UI.vpSpeedBox.PlaceholderText = "speed"
UI.vpSpeedBox.Position = UDim2.new(0,50,0,353); UI.vpSpeedBox.Size = UDim2.new(0,55,0,20)
UI.vpSpeedBox.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.vpSpeedBox.TextColor3 = Color3.fromRGB(210,210,210); UI.vpSpeedBox.BorderSizePixel = 0; UI.vpSpeedBox.Font = Enum.Font.Code; UI.vpSpeedBox.TextSize = 12; UI.vpSpeedBox.ZIndex = 6; UI.vpSpeedBox.Parent = UI.viewportWin
mkCorner(UI.vpSpeedBox,3); mkStroke(UI.vpSpeedBox, Color3.fromRGB(42,42,42), 1)

UI.vpLoopToggle = Instance.new("TextButton"); UI.vpLoopToggle.Text = "Loop: OFF"; UI.vpLoopToggle.Position = UDim2.new(0,113,0,353); UI.vpLoopToggle.Size = UDim2.new(0,80,0,20)
UI.vpLoopToggle.BackgroundColor3 = Color3.fromRGB(8,8,8); UI.vpLoopToggle.TextColor3 = Color3.fromRGB(210,210,210); UI.vpLoopToggle.BorderSizePixel = 0; UI.vpLoopToggle.Font = Enum.Font.Code; UI.vpLoopToggle.TextSize = 11; UI.vpLoopToggle.ZIndex = 6; UI.vpLoopToggle.Parent = UI.viewportWin; mkCorner(UI.vpLoopToggle,4)

do
	local vpTimeLabel = Instance.new("TextLabel"); vpTimeLabel.Text = "Time"; vpTimeLabel.Position = UDim2.new(0,200,0,353); vpTimeLabel.Size = UDim2.new(0,35,0,20)
	vpTimeLabel.BackgroundTransparency = 1; vpTimeLabel.TextColor3 = Color3.fromRGB(95,95,95); vpTimeLabel.Font = Enum.Font.Code; vpTimeLabel.TextSize = 12; vpTimeLabel.ZIndex = 6; vpTimeLabel.Parent = UI.viewportWin
end
UI.vpTimeBox = Instance.new("TextBox"); UI.vpTimeBox.Text = "0"; UI.vpTimeBox.PlaceholderText = "time"
UI.vpTimeBox.Position = UDim2.new(0,238,0,353); UI.vpTimeBox.Size = UDim2.new(0,52,0,20)
UI.vpTimeBox.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.vpTimeBox.TextColor3 = Color3.fromRGB(210,210,210); UI.vpTimeBox.BorderSizePixel = 0; UI.vpTimeBox.Font = Enum.Font.Code; UI.vpTimeBox.TextSize = 12; UI.vpTimeBox.ZIndex = 6; UI.vpTimeBox.Parent = UI.viewportWin
mkCorner(UI.vpTimeBox,3); mkStroke(UI.vpTimeBox, Color3.fromRGB(42,42,42), 1)

UI.vpPlayBtn = Instance.new("TextButton"); UI.vpPlayBtn.Text = "▶ Play Preview"; UI.vpPlayBtn.Position = UDim2.new(0,5,0,378); UI.vpPlayBtn.Size = UDim2.new(0.5,-8,0,25)
UI.vpPlayBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.vpPlayBtn.TextColor3 = Color3.fromRGB(140,210,145); UI.vpPlayBtn.BorderSizePixel = 0; UI.vpPlayBtn.Font = Enum.Font.GothamSemibold; UI.vpPlayBtn.ZIndex = 6; UI.vpPlayBtn.Parent = UI.viewportWin; mkCorner(UI.vpPlayBtn,4)
mkStroke(UI.vpPlayBtn, Color3.fromRGB(45,80,48), 1)

UI.vpStopBtn = Instance.new("TextButton"); UI.vpStopBtn.Text = "■ Stop Preview"; UI.vpStopBtn.Position = UDim2.new(0.5,3,0,378); UI.vpStopBtn.Size = UDim2.new(0.5,-8,0,25)
UI.vpStopBtn.BackgroundColor3 = Color3.fromRGB(38,22,22); UI.vpStopBtn.TextColor3 = Color3.fromRGB(210,130,130); UI.vpStopBtn.BorderSizePixel = 0; UI.vpStopBtn.Font = Enum.Font.GothamSemibold; UI.vpStopBtn.ZIndex = 6; UI.vpStopBtn.Parent = UI.viewportWin; mkCorner(UI.vpStopBtn,4)
mkStroke(UI.vpStopBtn, Color3.fromRGB(75,40,40), 1)
UI.vpPlaySelfBtn = Instance.new("TextButton"); UI.vpPlaySelfBtn.Text = "★ Play on Self"; UI.vpPlaySelfBtn.Position = UDim2.new(0,5,0,408); UI.vpPlaySelfBtn.Size = UDim2.new(1,-10,0,22)
UI.vpPlaySelfBtn.BackgroundColor3 = Color3.fromRGB(180,140,230); UI.vpPlaySelfBtn.TextColor3 = Color3.fromRGB(20,20,20); UI.vpPlaySelfBtn.BorderSizePixel = 0; UI.vpPlaySelfBtn.Font = Enum.Font.Code; UI.vpPlaySelfBtn.ZIndex = 6; UI.vpPlaySelfBtn.Parent = UI.viewportWin; mkCorner(UI.vpPlaySelfBtn,4)
mkStroke(UI.vpPlaySelfBtn, Color3.fromRGB(140,100,200), 1)

UI.vpRotateCCW = Instance.new("TextButton"); UI.vpRotateCCW.Text = "◄"; UI.vpRotateCCW.Position = UDim2.new(0,5,0,435); UI.vpRotateCCW.Size = UDim2.new(0.22,-4,0,20)
UI.vpRotateCCW.BackgroundColor3 = Color3.fromRGB(35,60,35); UI.vpRotateCCW.TextColor3 = Color3.fromRGB(160,230,160); UI.vpRotateCCW.BorderSizePixel = 0; UI.vpRotateCCW.Font = Enum.Font.Code; UI.vpRotateCCW.TextSize = 13; UI.vpRotateCCW.ZIndex = 6; UI.vpRotateCCW.Parent = UI.viewportWin; mkCorner(UI.vpRotateCCW,4)
UI.vpRotateCW = Instance.new("TextButton"); UI.vpRotateCW.Text = "►"; UI.vpRotateCW.Position = UDim2.new(0.78,3,0,435); UI.vpRotateCW.Size = UDim2.new(0.22,-8,0,20)
UI.vpRotateCW.BackgroundColor3 = Color3.fromRGB(35,60,35); UI.vpRotateCW.TextColor3 = Color3.fromRGB(160,230,160); UI.vpRotateCW.BorderSizePixel = 0; UI.vpRotateCW.Font = Enum.Font.Code; UI.vpRotateCW.TextSize = 13; UI.vpRotateCW.ZIndex = 6; UI.vpRotateCW.Parent = UI.viewportWin; mkCorner(UI.vpRotateCW,4)
UI.vpPrecisionBox = Instance.new("TextBox"); UI.vpPrecisionBox.Text = "90"; UI.vpPrecisionBox.PlaceholderText = "step"
UI.vpPrecisionBox.Position = UDim2.new(0.22,2,0,435); UI.vpPrecisionBox.Size = UDim2.new(0.56,-4,0,20)
UI.vpPrecisionBox.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.vpPrecisionBox.TextColor3 = Color3.fromRGB(210,210,210); UI.vpPrecisionBox.PlaceholderColor3 = Color3.fromRGB(65,65,65)
UI.vpPrecisionBox.BorderSizePixel = 0; UI.vpPrecisionBox.Font = Enum.Font.Code; UI.vpPrecisionBox.TextSize = 11; UI.vpPrecisionBox.ZIndex = 6; UI.vpPrecisionBox.Parent = UI.viewportWin
mkCorner(UI.vpPrecisionBox,3); mkStroke(UI.vpPrecisionBox, Color3.fromRGB(65,65,65), 1)

UI.vpZoomIn = Instance.new("TextButton"); UI.vpZoomIn.Text = "+ Zoom"; UI.vpZoomIn.Position = UDim2.new(0,5,0,460); UI.vpZoomIn.Size = UDim2.new(0.5,-8,0,20)
UI.vpZoomIn.BackgroundColor3 = Color3.fromRGB(35,60,35); UI.vpZoomIn.TextColor3 = Color3.fromRGB(160,230,160); UI.vpZoomIn.BorderSizePixel = 0; UI.vpZoomIn.Font = Enum.Font.Code; UI.vpZoomIn.TextSize = 11; UI.vpZoomIn.ZIndex = 6; UI.vpZoomIn.Parent = UI.viewportWin; mkCorner(UI.vpZoomIn,4)

UI.vpZoomOut = Instance.new("TextButton"); UI.vpZoomOut.Text = "- Zoom"; UI.vpZoomOut.Position = UDim2.new(0.5,3,0,460); UI.vpZoomOut.Size = UDim2.new(0.5,-8,0,20)
UI.vpZoomOut.BackgroundColor3 = Color3.fromRGB(35,60,35); UI.vpZoomOut.TextColor3 = Color3.fromRGB(160,230,160); UI.vpZoomOut.BorderSizePixel = 0; UI.vpZoomOut.Font = Enum.Font.Code; UI.vpZoomOut.TextSize = 11; UI.vpZoomOut.ZIndex = 6; UI.vpZoomOut.Parent = UI.viewportWin; mkCorner(UI.vpZoomOut,4)

local vpSkinLabel = Instance.new("TextLabel"); vpSkinLabel.Text = "username or userid"; vpSkinLabel.Position = UDim2.new(0,5,0,484); vpSkinLabel.Size = UDim2.new(1,-10,0,12)
vpSkinLabel.BackgroundTransparency = 1; vpSkinLabel.TextColor3 = Color3.fromRGB(95,95,95); vpSkinLabel.TextXAlignment = Enum.TextXAlignment.Left; vpSkinLabel.Font = Enum.Font.Code; vpSkinLabel.TextSize = 10; vpSkinLabel.ZIndex = 6; vpSkinLabel.Parent = UI.viewportWin

UI.vpSkinInput = Instance.new("TextBox"); UI.vpSkinInput.Text = ""; UI.vpSkinInput.PlaceholderText = "e.g. Builderman or 156"
UI.vpSkinInput.Position = UDim2.new(0,5,0,498); UI.vpSkinInput.Size = UDim2.new(1,-110,0,22)
UI.vpSkinInput.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.vpSkinInput.TextColor3 = Color3.fromRGB(210,210,210); UI.vpSkinInput.PlaceholderColor3 = Color3.fromRGB(65,65,65)
UI.vpSkinInput.BorderSizePixel = 0; UI.vpSkinInput.Font = Enum.Font.Code; UI.vpSkinInput.TextSize = 11; UI.vpSkinInput.ZIndex = 6; UI.vpSkinInput.Parent = UI.viewportWin
mkCorner(UI.vpSkinInput,3); mkStroke(UI.vpSkinInput, Color3.fromRGB(42,42,42), 1)

UI.vpSkinLoadBtn = Instance.new("TextButton"); UI.vpSkinLoadBtn.Text = "Load Skin"; UI.vpSkinLoadBtn.Position = UDim2.new(1,-102,0,498); UI.vpSkinLoadBtn.Size = UDim2.new(0,60,0,22)
UI.vpSkinLoadBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.vpSkinLoadBtn.TextColor3 = Color3.fromRGB(140,210,145); UI.vpSkinLoadBtn.BorderSizePixel = 0; UI.vpSkinLoadBtn.Font = Enum.Font.Code; UI.vpSkinLoadBtn.TextSize = 10; UI.vpSkinLoadBtn.ZIndex = 6; UI.vpSkinLoadBtn.Parent = UI.viewportWin
mkCorner(UI.vpSkinLoadBtn,3); mkStroke(UI.vpSkinLoadBtn, Color3.fromRGB(45,80,48), 1)

UI.vpSkinResetBtn = Instance.new("TextButton"); UI.vpSkinResetBtn.Text = "Reset"; UI.vpSkinResetBtn.Position = UDim2.new(1,-38,0,498); UI.vpSkinResetBtn.Size = UDim2.new(0,33,0,22)
UI.vpSkinResetBtn.BackgroundColor3 = Color3.fromRGB(38,22,22); UI.vpSkinResetBtn.TextColor3 = Color3.fromRGB(210,130,130); UI.vpSkinResetBtn.BorderSizePixel = 0; UI.vpSkinResetBtn.Font = Enum.Font.Code; UI.vpSkinResetBtn.TextSize = 10; UI.vpSkinResetBtn.ZIndex = 6; UI.vpSkinResetBtn.Parent = UI.viewportWin
mkCorner(UI.vpSkinResetBtn,3); mkStroke(UI.vpSkinResetBtn, Color3.fromRGB(75,40,40), 1)

UI.vpSkinStatusLabel = Instance.new("TextLabel"); UI.vpSkinStatusLabel.Text = ""; UI.vpSkinStatusLabel.Position = UDim2.new(0,5,0,522); UI.vpSkinStatusLabel.Size = UDim2.new(1,-10,0,12)
UI.vpSkinStatusLabel.BackgroundTransparency = 1; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(95,95,95); UI.vpSkinStatusLabel.TextXAlignment = Enum.TextXAlignment.Left; UI.vpSkinStatusLabel.Font = Enum.Font.Code; UI.vpSkinStatusLabel.TextSize = 10; UI.vpSkinStatusLabel.ZIndex = 6; UI.vpSkinStatusLabel.Parent = UI.viewportWin


local vpDummyDivider = Instance.new("Frame")
vpDummyDivider.Size = UDim2.new(1,-10,0,1); vpDummyDivider.Position = UDim2.new(0,5,0,540)
vpDummyDivider.BackgroundColor3 = Color3.fromRGB(42,42,42); vpDummyDivider.BorderSizePixel = 0; vpDummyDivider.ZIndex = 6; vpDummyDivider.Parent = UI.viewportWin

local vpDummyLabel = Instance.new("TextLabel")
vpDummyLabel.Size = UDim2.new(1,-10,0,14); vpDummyLabel.Position = UDim2.new(0,5,0,544)
vpDummyLabel.BackgroundTransparency = 1; vpDummyLabel.TextColor3 = Color3.fromRGB(160,160,160)
vpDummyLabel.Font = Enum.Font.Code; vpDummyLabel.TextSize = 11; vpDummyLabel.TextXAlignment = Enum.TextXAlignment.Left
vpDummyLabel.Text = "dummy test"; vpDummyLabel.ZIndex = 6; vpDummyLabel.Parent = UI.viewportWin

UI.vpTestDummyBtn = Instance.new("TextButton"); UI.vpTestDummyBtn.Text = "▶ test on dummy"; UI.vpTestDummyBtn.Position = UDim2.new(0,5,0,560); UI.vpTestDummyBtn.Size = UDim2.new(0.5,-7,0,22)
UI.vpTestDummyBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.vpTestDummyBtn.TextColor3 = Color3.fromRGB(140,210,145); UI.vpTestDummyBtn.BorderSizePixel = 0; UI.vpTestDummyBtn.Font = Enum.Font.Code; UI.vpTestDummyBtn.TextSize = 10; UI.vpTestDummyBtn.ZIndex = 6; UI.vpTestDummyBtn.Parent = UI.viewportWin; mkCorner(UI.vpTestDummyBtn,4)
mkStroke(UI.vpTestDummyBtn, Color3.fromRGB(45,80,48), 1)

UI.vpStopDummyBtn = Instance.new("TextButton"); UI.vpStopDummyBtn.Text = "■ stop dummy"; UI.vpStopDummyBtn.Position = UDim2.new(0.5,2,0,560); UI.vpStopDummyBtn.Size = UDim2.new(0.5,-7,0,22)
UI.vpStopDummyBtn.BackgroundColor3 = Color3.fromRGB(38,22,22); UI.vpStopDummyBtn.TextColor3 = Color3.fromRGB(210,130,130); UI.vpStopDummyBtn.BorderSizePixel = 0; UI.vpStopDummyBtn.Font = Enum.Font.Code; UI.vpStopDummyBtn.TextSize = 10; UI.vpStopDummyBtn.ZIndex = 6; UI.vpStopDummyBtn.Parent = UI.viewportWin; mkCorner(UI.vpStopDummyBtn,4)
mkStroke(UI.vpStopDummyBtn, Color3.fromRGB(75,40,40), 1)

UI.vpDummyMacroBox = Instance.new("TextBox"); UI.vpDummyMacroBox.PlaceholderText = "macro on dummy... (play id; wait 0.5; stop)"; UI.vpDummyMacroBox.Text = ""
UI.vpDummyMacroBox.Position = UDim2.new(0,5,0,586); UI.vpDummyMacroBox.Size = UDim2.new(0.75,-7,0,22)
UI.vpDummyMacroBox.BackgroundColor3 = Color3.fromRGB(14,14,14); UI.vpDummyMacroBox.TextColor3 = Color3.fromRGB(210,210,210); UI.vpDummyMacroBox.PlaceholderColor3 = Color3.fromRGB(65,65,65)
UI.vpDummyMacroBox.BorderSizePixel = 0; UI.vpDummyMacroBox.Font = Enum.Font.Code; UI.vpDummyMacroBox.TextSize = 10; UI.vpDummyMacroBox.ZIndex = 6; UI.vpDummyMacroBox.Parent = UI.viewportWin
mkCorner(UI.vpDummyMacroBox,3); mkStroke(UI.vpDummyMacroBox, Color3.fromRGB(42,42,42), 1)

UI.vpRunDummyMacroBtn = Instance.new("TextButton"); UI.vpRunDummyMacroBtn.Text = "run"; UI.vpRunDummyMacroBtn.Position = UDim2.new(0.75,2,0,586); UI.vpRunDummyMacroBtn.Size = UDim2.new(0.25,-7,0,22)
UI.vpRunDummyMacroBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.vpRunDummyMacroBtn.TextColor3 = Color3.fromRGB(140,210,145); UI.vpRunDummyMacroBtn.BorderSizePixel = 0; UI.vpRunDummyMacroBtn.Font = Enum.Font.Code; UI.vpRunDummyMacroBtn.TextSize = 10; UI.vpRunDummyMacroBtn.ZIndex = 6; UI.vpRunDummyMacroBtn.Parent = UI.viewportWin; mkCorner(UI.vpRunDummyMacroBtn,4)
mkStroke(UI.vpRunDummyMacroBtn, Color3.fromRGB(45,80,48), 1)

local spawnDummySectionY = 610
UI.vpSpawnDummyBtn = Instance.new("TextButton"); UI.vpSpawnDummyBtn.Text = "＋ Spawn Dummy"; UI.vpSpawnDummyBtn.Position = UDim2.new(0,5,0,spawnDummySectionY); UI.vpSpawnDummyBtn.Size = UDim2.new(0.5,-8,0,22)
UI.vpSpawnDummyBtn.BackgroundColor3 = Color3.fromRGB(22,38,24); UI.vpSpawnDummyBtn.TextColor3 = Color3.fromRGB(140,210,145); UI.vpSpawnDummyBtn.BorderSizePixel = 0; UI.vpSpawnDummyBtn.Font = Enum.Font.Code; UI.vpSpawnDummyBtn.TextSize = 10; UI.vpSpawnDummyBtn.ZIndex = 6; UI.vpSpawnDummyBtn.Parent = UI.viewportWin; mkCorner(UI.vpSpawnDummyBtn,4)
mkStroke(UI.vpSpawnDummyBtn, Color3.fromRGB(45,80,48), 1)

UI.vpDespawnDummyBtn = Instance.new("TextButton"); UI.vpDespawnDummyBtn.Text = "- despawn"; UI.vpDespawnDummyBtn.Position = UDim2.new(0.5,3,0,spawnDummySectionY); UI.vpDespawnDummyBtn.Size = UDim2.new(0.5,-8,0,22)
UI.vpDespawnDummyBtn.BackgroundColor3 = Color3.fromRGB(38,22,22); UI.vpDespawnDummyBtn.TextColor3 = Color3.fromRGB(210,130,130); UI.vpDespawnDummyBtn.BorderSizePixel = 0; UI.vpDespawnDummyBtn.Font = Enum.Font.Code; UI.vpDespawnDummyBtn.TextSize = 10; UI.vpDespawnDummyBtn.ZIndex = 6; UI.vpDespawnDummyBtn.Parent = UI.viewportWin; mkCorner(UI.vpDespawnDummyBtn,4)
mkStroke(UI.vpDespawnDummyBtn, Color3.fromRGB(75,40,40), 1)

local function makeSpawnDummy()
	if Data.spawnDummy then pcall(function() Data.spawnDummy:Destroy() end); Data.spawnDummy = nil; Data.spawnDummyAnimator = nil end
	local char = Services.Players.LocalPlayer.Character
	if not char then return end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	local spawnPos = rootPart.CFrame * CFrame.new(0, 0, -6)

	if State.vpRigType == "R15" then
		local r15, r15anim, r15root
		local ok = pcall(function()
			r15 = Services.Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
		end)
		if ok and r15 then
			r15.Name = "SpawnDummy"
			r15root = r15:FindFirstChild("HumanoidRootPart")
			local r15hum = r15:FindFirstChildOfClass("Humanoid")
			if r15root and r15hum then
				r15hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				r15hum.WalkSpeed = 0; r15hum.JumpPower = 0
				r15root.Anchored = false; r15root.CanCollide = false; r15root.Transparency = 1
				r15.PrimaryPart = r15root
				r15:SetPrimaryPartCFrame(spawnPos)

				local rigColor = Color3.fromRGB(160,160,160)
				for _, p in ipairs(r15:GetDescendants()) do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
						p.Color = rigColor
					end
				end

				local r15head = r15:FindFirstChild("Head")
				if r15head then
					for _, obj in ipairs(r15head:GetChildren()) do
						if obj:IsA("Decal") or obj:IsA("SurfaceAppearance") or obj:IsA("FaceControls") then obj:Destroy() end
					end
					pcall(function() r15head.TextureID = "" end)
					local nose = Instance.new("Part"); nose.Name = "Nose"; nose.Size = Vector3.new(0.3,0.3,0.4)
					nose.Color = Color3.fromRGB(200,50,50); nose.Material = Enum.Material.SmoothPlastic
					nose.Anchored = false; nose.CanCollide = false; nose.CastShadow = false; nose.Parent = r15
					local nw = Instance.new("Weld"); nw.Part0 = r15head; nw.Part1 = nose; nw.C0 = CFrame.new(0,0,-0.65); nw.Parent = r15head
				end
				r15anim = r15hum:FindFirstChildOfClass("Animator")
				if not r15anim then r15anim = Instance.new("Animator"); r15anim.Parent = r15hum end
				r15.Parent = workspace
				Data.spawnDummy = r15; Data.spawnDummyAnimator = r15anim
				return
			end
		end

	end


	local model = Instance.new("Model"); model.Name = "SpawnDummy"
	local function part(name, size)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.BrickColor = BrickColor.new("Medium stone grey")
		p.Material = Enum.Material.SmoothPlastic; p.Anchored = false; p.CanCollide = false; p.CastShadow = false; p.Parent = model; return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2,2,1)); root.Transparency = 1; root.CanCollide = false
	local torso = part("Torso", Vector3.new(2,2,1)); local head = part("Head", Vector3.new(1.1589776277542114, 1.1820125579833984, 1.1606383323669434))
	local rArm = part("Right Arm", Vector3.new(1,2,1)); local lArm = part("Left Arm", Vector3.new(1,2,1))
	local rLeg = part("Right Leg", Vector3.new(1,2,1)); local lLeg = part("Left Leg", Vector3.new(1,2,1))
	root.CFrame = spawnPos; root.Anchored = false; model.PrimaryPart = root
	local hum = Instance.new("Humanoid"); hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.WalkSpeed = 0; hum.JumpPower = 0; hum.Parent = model
	local function motor(name, p0, p1, c0, c1) local m = Instance.new("Motor6D"); m.Name = name; m.Part0 = p0; m.Part1 = p1; m.C0 = c0; m.C1 = c1; m.Parent = p0 end
	motor("RootJoint", root, torso, CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0), CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0))
	motor("Neck", torso, head, CFrame.new(0,1,0,-1,0,0,0,0,1,0,1,0), CFrame.new(0,-0.5,0,-1,0,0,0,0,1,0,1,0))
	motor("Right Shoulder", torso, rArm, CFrame.new(1,0.5,0,0,0,1,0,1,0,-1,0,0), CFrame.new(-0.5,0.5,0,0,0,1,0,1,0,-1,0,0))
	motor("Left Shoulder", torso, lArm, CFrame.new(-1,0.5,0,0,0,-1,0,1,0,1,0,0), CFrame.new(0.5,0.5,0,0,0,-1,0,1,0,1,0,0))
	motor("Right Hip", torso, rLeg, CFrame.new(1,-1,0,0,0,1,0,1,0,-1,0,0), CFrame.new(0.5,1,0,0,0,1,0,1,0,-1,0,0))
	motor("Left Hip", torso, lLeg, CFrame.new(-1,-1,0,0,0,-1,0,1,0,1,0,0), CFrame.new(-0.5,1,0,0,0,-1,0,1,0,1,0,0))
	local nose = Instance.new("Part"); nose.Name = "Nose"; nose.Size = Vector3.new(0.3,0.3,0.4); nose.BrickColor = BrickColor.new("Bright red"); nose.Color = Color3.fromRGB(200,50,50); nose.Material = Enum.Material.SmoothPlastic; nose.Anchored = false; nose.CanCollide = false; nose.CastShadow = false; nose.Parent = model
	local noseWeld = Instance.new("Weld"); noseWeld.Part0 = head; noseWeld.Part1 = nose; noseWeld.C0 = CFrame.new(0,0,-0.65); noseWeld.Parent = head
	local headMesh = Instance.new("SpecialMesh"); headMesh.MeshType = Enum.MeshType.Head; headMesh.Scale = Vector3.new(1,1,1); headMesh.Parent = head
	local function att(parent, name, cf) local a = Instance.new("Attachment"); a.Name = name; a.CFrame = cf; a.Parent = parent end
	att(head,"HatAttachment",CFrame.new(0,0.6,0)); att(head,"HairAttachment",CFrame.new(0,0.6,0)); att(head,"FaceFrontAttachment",CFrame.new(0,0,-0.6)); att(head,"FaceBackAttachment",CFrame.new(0,0,0.6))
	att(torso,"BodyFrontAttachment",CFrame.new(0,0,-0.5)); att(torso,"BodyBackAttachment",CFrame.new(0,0,0.5)); att(torso,"NeckAttachment",CFrame.new(0,1,0))
	att(torso,"WaistFrontAttachment",CFrame.new(0,-1,-0.5)); att(torso,"WaistBackAttachment",CFrame.new(0,-1,0.5)); att(torso,"WaistCenterAttachment",CFrame.new(0,-1,0))
	att(rArm,"RightShoulderAttachment",CFrame.new(0,1,0)); att(lArm,"LeftShoulderAttachment",CFrame.new(0,1,0))
	model.Parent = workspace
	local animator = Instance.new("Animator"); animator.Parent = hum
	Data.spawnDummy = model; Data.spawnDummyAnimator = animator
end

local function despawnSpawnDummy()
	if Data.spawnDummy then pcall(function() Data.spawnDummy:Destroy() end); Data.spawnDummy = nil; Data.spawnDummyAnimator = nil end
end

table.insert(Data.connections, UI.closeButton.MouseButton1Click:Connect(function()
	State.running = false
	despawnSpawnDummy()
	for _, connection in pairs(Data.connections) do connection:Disconnect() end
	UI.gui:Destroy()
end))

local function ensureSpawnDummyAnimator()
	if not Data.spawnDummy then return nil end
	local hum = Data.spawnDummy:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	if Data.spawnDummyAnimator and Data.spawnDummyAnimator.Parent == hum then return Data.spawnDummyAnimator end
	local anim = hum:FindFirstChildOfClass("Animator")
	if not anim then
		anim = Instance.new("Animator")
		anim.Parent = hum
	end
	Data.spawnDummyAnimator = anim
	return anim
end

local function playOnSpawnDummy(animId, speed, loop)
	if not Data.spawnDummy then return end
	local animator = ensureSpawnDummyAnimator()
	if not animator then return end
	local aid = grabId(tostring(animId)) or tostring(animId)
	if aid == "" then return end
	if Data.spawnDummyTrack then pcall(function() Data.spawnDummyTrack:Stop(0) end); Data.spawnDummyTrack = nil end
	local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. aid
	local track
	pcall(function() track = animator:LoadAnimation(anim) end)
	if track then
		track.Priority = Enum.AnimationPriority.Action4; track.Looped = loop ~= false
		track:Play(0,1,speed or 1); Data.spawnDummyTrack = track
	end
end

local function stopSpawnDummyTrack()
	if Data.spawnDummyTrack then pcall(function() Data.spawnDummyTrack:Stop(0) end); Data.spawnDummyTrack = nil end
end

table.insert(Data.connections, UI.vpSpawnDummyBtn.MouseButton1Click:Connect(function()
	makeSpawnDummy()
	if not Data.spawnDummy then return end
	if not State.vpSkinCache and State.vpSkinQuery then
		UI.vpSkinStatusLabel.Text = "skin loading..."; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160)
		local checks = 0
		while not State.vpSkinCache and checks < 30 do task.wait(0.1); checks = checks + 1 end
	end
	if State.vpSkinCache then
		task.wait(0.2)
		local rig = Data.spawnDummy
		local function stripRig(rig)
			for _, obj in ipairs(rig:GetChildren()) do
				if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then obj:Destroy() end
			end
			local defaultColor = Color3.fromRGB(160,160,160)
			for _, name in ipairs({"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
				local p = rig:FindFirstChild(name)
				if p then p.Color = defaultColor
					for _, m in ipairs(p:GetChildren()) do if m:IsA("SpecialMesh") or m:IsA("BlockMesh") then m:Destroy() end end
				end
			end
			local head = rig:FindFirstChild("Head")
			if head then local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = Vector3.new(1,1,1); mesh.Parent = head end
			local nose = rig:FindFirstChild("Nose"); if nose then nose:Destroy() end
		end
		local function applyFromDesc(rig, desc)
			local hum = rig:FindFirstChildOfClass("Humanoid"); if not hum then return false end
			local ok = pcall(function() hum:ApplyDescription(desc) end); return ok
		end
		local function applyFromCharSource(rig, srcChar)
			local bc = srcChar:FindFirstChildOfClass("BodyColors")
			if bc then
				local colorMap = {Head=bc.HeadColor3,Torso=bc.TorsoColor3,["Left Arm"]=bc.LeftArmColor3,["Right Arm"]=bc.RightArmColor3,["Left Leg"]=bc.LeftLegColor3,["Right Leg"]=bc.RightLegColor3}
				for partName, color in pairs(colorMap) do local p = rig:FindFirstChild(partName); if p then p.Color = color end end
				bc:Clone().Parent = rig
			end
			local srcHead = srcChar:FindFirstChild("Head"); local dstHead = rig:FindFirstChild("Head")
			if srcHead and dstHead then
				dstHead.Color = srcHead.Color
				for _, m in ipairs(dstHead:GetChildren()) do if m:IsA("SpecialMesh") or m:IsA("BlockMesh") then m:Destroy() end end
				local srcMesh = srcHead:FindFirstChildOfClass("SpecialMesh")
				if srcMesh then srcMesh:Clone().Parent = dstHead
				else local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = Vector3.new(1,1,1); mesh.Parent = dstHead end
			end
			for _, obj in ipairs(srcChar:GetChildren()) do
				if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then obj:Clone().Parent = rig end
			end
			for _, obj in ipairs(srcChar:GetChildren()) do
				if obj:IsA("Accessory") then
					local acc = obj:Clone(); local handle = acc:FindFirstChild("Handle")
					if handle then
						for _, w in ipairs(handle:GetChildren()) do if w:IsA("Weld") or w:IsA("Motor6D") or w:IsA("Snap") then w:Destroy() end end
						local att = handle:FindFirstChildOfClass("Attachment"); local targetPartName = "Head"
						if att then
							local n = att.Name:lower()
							if n:find("hat") or n:find("hair") or n:find("facefront") or n:find("face") then targetPartName = "Head"
							elseif n:find("neck") or n:find("bodyfront") or n:find("body") or n:find("torso") then targetPartName = "Torso"
							elseif n:find("leftarm") or n:find("left_arm") then targetPartName = "Left Arm"
							elseif n:find("rightarm") or n:find("right_arm") then targetPartName = "Right Arm"
							elseif n:find("leftleg") or n:find("left_leg") then targetPartName = "Left Leg"
							elseif n:find("rightleg") or n:find("right_leg") then targetPartName = "Right Leg" end
						end
						local targetPart = rig:FindFirstChild(targetPartName)
						if targetPart then
							local weld = Instance.new("Weld"); weld.Part0 = targetPart; weld.Part1 = handle
							if att then local dstAtt = targetPart:FindFirstChild(att.Name); if dstAtt then weld.C0 = dstAtt.CFrame; weld.C1 = att.CFrame end end
							weld.Parent = handle
						end
						handle.Anchored = false; handle.CanCollide = false
					end
					acc.Parent = rig
				end
			end
		end
		stripRig(rig)
		local cache = State.vpSkinCache
		if cache and cache.type == "desc" and cache.data then
			applyFromDesc(rig, cache.data)
		elseif cache and cache.type == "char" and cache.data then
			applyFromCharSource(rig, cache.data)
		end
		removeClownNosePart(rig)
		ensureSpawnDummyAnimator()
	end
end))

table.insert(Data.connections, UI.vpDespawnDummyBtn.MouseButton1Click:Connect(function()
	despawnSpawnDummy()
end))

local function makeRig()
	if State.vpRigType == "R15" then
		local r15
		local okR15 = pcall(function()
			r15 = Services.Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
		end)
		if okR15 and r15 then
			r15.Name = "PreviewRig"
			local r15root = r15:FindFirstChild("HumanoidRootPart")
			local r15hum = r15:FindFirstChildOfClass("Humanoid")
			if r15root and r15hum then
				r15hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; r15hum.WalkSpeed = 0; r15hum.JumpPower = 0
				r15root.Anchored = true; r15root.Transparency = 1; r15.PrimaryPart = r15root
				r15root.CFrame = CFrame.new(0,5,0)

				local rigColor = Color3.fromRGB(160,160,160)
				for _, p in ipairs(r15:GetDescendants()) do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
						p.Color = rigColor
					end
				end
				local r15head = r15:FindFirstChild("Head")
				if r15head then
					for _, obj in ipairs(r15head:GetChildren()) do
						if obj:IsA("Decal") or obj:IsA("SurfaceAppearance") or obj:IsA("FaceControls") then obj:Destroy() end
					end
					pcall(function() r15head.TextureID = "" end)
					local nose = Instance.new("Part"); nose.Name = "Nose"; nose.Size = Vector3.new(0.3,0.3,0.4); nose.Color = Color3.fromRGB(200,50,50); nose.Material = Enum.Material.SmoothPlastic; nose.Anchored = false; nose.CanCollide = false; nose.CastShadow = false; nose.Parent = r15
					local nw = Instance.new("Weld"); nw.Part0 = r15head; nw.Part1 = nose; nw.C0 = CFrame.new(0,0,-0.65); nw.Parent = r15head
				end
				local r15anim = r15hum:FindFirstChildOfClass("Animator"); if not r15anim then r15anim = Instance.new("Animator"); r15anim.Parent = r15hum end
				r15.Parent = worldModel
				return r15, r15anim, r15root
			elseif r15 then
				pcall(function() r15:Destroy() end)
			end
		end

	end
	local model = Instance.new("Model"); model.Name = "PreviewRig"
	local function part(name, size)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.BrickColor = BrickColor.new("Medium stone grey")
		p.Material = Enum.Material.SmoothPlastic; p.Anchored = false; p.CanCollide = false; p.CastShadow = false; p.Parent = model; return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2,2,1)); local torso = part("Torso", Vector3.new(2,2,1)); local head = part("Head", Vector3.new(1.1589776277542114, 1.1820125579833984, 1.1606383323669434))
	local rArm = part("Right Arm", Vector3.new(1,2,1)); local lArm = part("Left Arm", Vector3.new(1,2,1))
	local rLeg = part("Right Leg", Vector3.new(1,2,1)); local lLeg = part("Left Leg", Vector3.new(1,2,1))
	root.Anchored = true; root.Transparency = 1; root.CFrame = CFrame.new(0,5,0); model.PrimaryPart = root
	local hum = Instance.new("Humanoid"); hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.WalkSpeed = 0; hum.JumpPower = 0; hum.Parent = model
	local function motor(name, p0, p1, c0, c1) local m = Instance.new("Motor6D"); m.Name = name; m.Part0 = p0; m.Part1 = p1; m.C0 = c0; m.C1 = c1; m.Parent = p0 end
	motor("RootJoint", root, torso, CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0), CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0))
	motor("Neck", torso, head, CFrame.new(0,1,0,-1,0,0,0,0,1,0,1,0), CFrame.new(0,-0.5,0,-1,0,0,0,0,1,0,1,0))
	motor("Right Shoulder", torso, rArm, CFrame.new(1,0.5,0,0,0,1,0,1,0,-1,0,0), CFrame.new(-0.5,0.5,0,0,0,1,0,1,0,-1,0,0))
	motor("Left Shoulder", torso, lArm, CFrame.new(-1,0.5,0,0,0,-1,0,1,0,1,0,0), CFrame.new(0.5,0.5,0,0,0,-1,0,1,0,1,0,0))
	motor("Right Hip", torso, rLeg, CFrame.new(1,-1,0,0,0,1,0,1,0,-1,0,0), CFrame.new(0.5,1,0,0,0,1,0,1,0,-1,0,0))
	motor("Left Hip", torso, lLeg, CFrame.new(-1,-1,0,0,0,-1,0,1,0,1,0,0), CFrame.new(-0.5,1,0,0,0,-1,0,1,0,1,0,0))
	local nose = Instance.new("Part"); nose.Name = "Nose"; nose.Size = Vector3.new(0.3,0.3,0.4); nose.BrickColor = BrickColor.new("Bright red"); nose.Color = Color3.fromRGB(200,50,50); nose.Material = Enum.Material.SmoothPlastic; nose.Anchored = false; nose.CanCollide = false; nose.CastShadow = false; nose.Parent = model
	local noseWeld = Instance.new("Weld"); noseWeld.Part0 = head; noseWeld.Part1 = nose; noseWeld.C0 = CFrame.new(0,0,-0.65); noseWeld.Parent = head
	local headMesh = Instance.new("SpecialMesh"); headMesh.MeshType = Enum.MeshType.Head; headMesh.Scale = Vector3.new(1,1,1); headMesh.Parent = head
	local function att(parent, name, cf) local a = Instance.new("Attachment"); a.Name = name; a.CFrame = cf; a.Parent = parent end
	att(head,"HatAttachment",CFrame.new(0,0.6,0)); att(head,"HairAttachment",CFrame.new(0,0.6,0)); att(head,"FaceFrontAttachment",CFrame.new(0,0,-0.6)); att(head,"FaceBackAttachment",CFrame.new(0,0,0.6))
	att(torso,"BodyFrontAttachment",CFrame.new(0,0,-0.5)); att(torso,"BodyBackAttachment",CFrame.new(0,0,0.5)); att(torso,"NeckAttachment",CFrame.new(0,1,0))
	att(torso,"WaistFrontAttachment",CFrame.new(0,-1,-0.5)); att(torso,"WaistBackAttachment",CFrame.new(0,-1,0.5)); att(torso,"WaistCenterAttachment",CFrame.new(0,-1,0))
	att(rArm,"RightShoulderAttachment",CFrame.new(0,1,0)); att(lArm,"LeftShoulderAttachment",CFrame.new(0,1,0))
	model.Parent = worldModel
	local animator = Instance.new("Animator"); animator.Parent = hum
	return model, animator, root
end

local function removeClownNosePart(rig)
	if not rig then return end
	for _, inst in ipairs(rig:GetDescendants()) do
		if inst:IsA("BasePart") and inst.Name == "Nose" then
			local s = inst.Size
			if s.X <= 0.45 and s.Y <= 0.45 and s.Z <= 0.5 then inst:Destroy() end
		end
	end
end

local function stripRigAppearance(rig)
	for _, obj in ipairs(rig:GetChildren()) do
		if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then obj:Destroy() end
	end
	local defaultColor = Color3.fromRGB(160,160,160)

	for _, name in ipairs({"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
		local p = rig:FindFirstChild(name)
		if p then
			p.Color = defaultColor
			for _, m in ipairs(p:GetChildren()) do if m:IsA("SpecialMesh") or m:IsA("BlockMesh") then m:Destroy() end end
		end
	end

	for _, name in ipairs({"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}) do
		local p = rig:FindFirstChild(name)
		if p then p.Color = defaultColor end
	end

	local head = rig:FindFirstChild("Head")
	if head then
		for _, obj in ipairs(head:GetChildren()) do if obj:IsA("Decal") or obj:IsA("SurfaceAppearance") or obj:IsA("FaceControls") then obj:Destroy() end end
		pcall(function() head.TextureID = "" end)
		if not head:FindFirstChildOfClass("SpecialMesh") and rig:FindFirstChild("Torso") then

			local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = Vector3.new(1,1,1); mesh.Parent = head
		end
	end
	removeClownNosePart(rig)
end

local function applyFromChar(rig, srcChar)
	local bc = srcChar:FindFirstChildOfClass("BodyColors")
	if bc then
		local colorMap = {Head=bc.HeadColor3,Torso=bc.TorsoColor3,["Left Arm"]=bc.LeftArmColor3,["Right Arm"]=bc.RightArmColor3,["Left Leg"]=bc.LeftLegColor3,["Right Leg"]=bc.RightLegColor3}
		for partName, color in pairs(colorMap) do local p = rig:FindFirstChild(partName); if p then p.Color = color end end
		bc:Clone().Parent = rig
	end
	local srcHead = srcChar:FindFirstChild("Head"); local dstHead = rig:FindFirstChild("Head")
	if srcHead and dstHead then
		dstHead.Color = srcHead.Color
		for _, m in ipairs(dstHead:GetChildren()) do if m:IsA("SpecialMesh") or m:IsA("BlockMesh") then m:Destroy() end end
		local srcMesh = srcHead:FindFirstChildOfClass("SpecialMesh")
		if srcMesh then srcMesh:Clone().Parent = dstHead
		else local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Head; mesh.Scale = Vector3.new(1,1,1); mesh.Parent = dstHead end
	end
	for _, obj in ipairs(srcChar:GetChildren()) do
		if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then obj:Clone().Parent = rig end
	end
	for _, obj in ipairs(srcChar:GetChildren()) do
		if obj:IsA("Accessory") then
			local acc = obj:Clone(); local handle = acc:FindFirstChild("Handle")
			if handle then
				for _, w in ipairs(handle:GetChildren()) do if w:IsA("Weld") or w:IsA("Motor6D") or w:IsA("Snap") then w:Destroy() end end
				local att = handle:FindFirstChildOfClass("Attachment"); local targetPartName = "Head"
				if att then
					local n = att.Name:lower()
					if n:find("hat") or n:find("hair") or n:find("facefront") or n:find("face") then targetPartName = "Head"
					elseif n:find("neck") or n:find("bodyfront") or n:find("body") or n:find("torso") then targetPartName = "Torso"
					elseif n:find("leftarm") or n:find("left_arm") then targetPartName = "Left Arm"
					elseif n:find("rightarm") or n:find("right_arm") then targetPartName = "Right Arm"
					elseif n:find("leftleg") or n:find("left_leg") then targetPartName = "Left Leg"
					elseif n:find("rightleg") or n:find("right_leg") then targetPartName = "Right Leg" end
				end
				local targetPart = rig:FindFirstChild(targetPartName)
				if targetPart then
					local weld = Instance.new("Weld"); weld.Part0 = targetPart; weld.Part1 = handle
					if att then local dstAtt = targetPart:FindFirstChild(att.Name); if dstAtt then weld.C0 = dstAtt.CFrame; weld.C1 = att.CFrame end end
					weld.Parent = handle
				end
				handle.Anchored = false; handle.CanCollide = false
			end
			acc.Parent = rig
		end
	end
end

local function applyFromDescription(rig, desc)
	local hum = rig:FindFirstChildOfClass("Humanoid"); if not hum then return false end
	local ok = pcall(function() hum:ApplyDescription(desc) end)

	local head = rig:FindFirstChild("Head")
	if head then
		for _, obj in ipairs(head:GetChildren()) do if obj:IsA("Decal") or obj:IsA("SurfaceAppearance") or obj:IsA("FaceControls") then obj:Destroy() end end
		pcall(function() head.TextureID = "" end)
	end
	return ok
end

local function applyPlayerSkin(query)
	State.vpSkinQuery = query
	local rigsToApply = {}
	if Data.ghostChar then table.insert(rigsToApply, Data.ghostChar) end
	if Data.spawnDummy then table.insert(rigsToApply, Data.spawnDummy) end
	if #rigsToApply == 0 then 
		UI.vpSkinStatusLabel.Text = "waiting for dummy..."; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160)
		local checks = 0
		while checks < 20 do
			task.wait(0.1)
			if Data.ghostChar then 
				table.insert(rigsToApply, Data.ghostChar)
				break 
			end
			checks = checks + 1
		end
		if #rigsToApply == 0 then return end
	end
	UI.vpSkinStatusLabel.Text = "loading..."; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160)
	task.spawn(function()
		local resolvedId
		if tostring(query):match("^%d+$") then
			resolvedId = tonumber(query)
		else
			local ok, uid = pcall(function() return Services.Players:GetUserIdFromNameAsync(query) end)
			if ok and uid then resolvedId = uid
			else UI.vpSkinStatusLabel.Text = "user not found"; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(65,65,65); State.vpSkinCache = nil; return end
		end
		local ingameChar = nil
		for _, p in ipairs(Services.Players:GetPlayers()) do
			if p.UserId == resolvedId and p.Character then ingameChar = p.Character; break end
		end
		if ingameChar then
			local clonedChar = ingameChar:Clone()
			for _, rig in ipairs(rigsToApply) do stripRigAppearance(rig); applyFromChar(rig, clonedChar); removeClownNosePart(rig) end
			if Data.spawnDummy then ensureSpawnDummyAnimator() end
			State.vpSkinCache = {type="char", data=clonedChar}
			UI.vpSkinStatusLabel.Text = "from server: " .. tostring(resolvedId); UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160); return
		end
		local desc; local ok, result = pcall(function() desc = Services.Players:GetHumanoidDescriptionFromUserId(resolvedId) end)
		if ok and desc then
			for _, rig in ipairs(rigsToApply) do stripRigAppearance(rig); applyFromDescription(rig, desc); removeClownNosePart(rig) end
			if Data.spawnDummy then ensureSpawnDummyAnimator() end
			State.vpSkinCache = {type="desc", data=desc}
			UI.vpSkinStatusLabel.Text = "from api: " .. tostring(resolvedId); UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160)
			return
		end
		local appearanceModel; ok, result = pcall(function() appearanceModel = Services.Players:GetCharacterAppearanceAsync(resolvedId) end)
		if ok and appearanceModel then
			local clonedAppearance = appearanceModel:Clone()
			for _, rig in ipairs(rigsToApply) do stripRigAppearance(rig); applyFromChar(rig, clonedAppearance); removeClownNosePart(rig) end
			if Data.spawnDummy then ensureSpawnDummyAnimator() end
			State.vpSkinCache = {type="char", data=clonedAppearance}
			UI.vpSkinStatusLabel.Text = "from appearance: " .. tostring(resolvedId); UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160); return
		end
		State.vpSkinCache = nil
		UI.vpSkinStatusLabel.Text = "failed to load skin"; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(65,65,65)
	end)
end

local function resetDummySkin()
	if not Data.ghostChar then return end
	local rig = Data.ghostChar; stripRigAppearance(rig)
	local head = rig:FindFirstChild("Head")
	if head and not rig:FindFirstChild("Nose") then
		local nose = Instance.new("Part"); nose.Name = "Nose"; nose.Size = Vector3.new(0.3,0.3,0.4); nose.BrickColor = BrickColor.new("Bright red"); nose.Color = Color3.fromRGB(200,50,50); nose.Material = Enum.Material.SmoothPlastic; nose.Anchored = false; nose.CanCollide = false; nose.CastShadow = false; nose.Parent = rig
		local nw = Instance.new("Weld"); nw.Part0 = head; nw.Part1 = nose; nw.C0 = CFrame.new(0,0,-0.65); nw.Parent = head
	end
	UI.vpSkinStatusLabel.Text = "reset to default"; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(100,100,100)
	UI.vpSkinInput.Text = ""; State.vpSkinQuery = nil; State.vpSkinCache = nil
end

local function reapplyCachedSkin(rig)
	local cache = State.vpSkinCache; if not cache then return end
	stripRigAppearance(rig)
	if cache.type == "desc" then applyFromDescription(rig, cache.data)
	elseif cache.type == "char" then applyFromChar(rig, cache.data) end
	removeClownNosePart(rig)
end

local function getDummyAnimator()
	if not Data.ghostChar then return nil end
	local hum = Data.ghostChar:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local anim = hum:FindFirstChildOfClass("Animator")
	if not anim then
		anim = Instance.new("Animator")
		anim.Parent = hum
	end
	Data.vpAnimator = anim
	return anim
end

local function previewAnim(id)
	if not id or id == "" then return end
	State.vpPaused = false; UI.vpPauseBtn.Text = "⏸ Pause"; UI.vpPauseBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
	nukeGhost()
	task.spawn(function()
		local rig, animator, rootPart = makeRig()
		if not rig or not animator then return end
		Data.ghostChar = rig; Data.vpAnimator = animator; Data.vpRootPart = rootPart
		reapplyCachedSkin(rig)
		vpCamera.CFrame = CFrame.new(Vector3.new(0,5,State.vpZoomDist), Vector3.new(0,4,0))
		local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. id
		local track; pcall(function() track = animator:LoadAnimation(anim) end)
		if track then
			track.Priority = Enum.AnimationPriority.Action4; track.Looped = State.vpLooped
			track:Play(0,1, tonumber(UI.vpSpeedBox.Text) or 1); Data.vpTrack = track
			local scrub = tonumber(UI.vpTimeBox.Text) or 0
			if scrub > 0 then task.defer(function() if Data.vpTrack then Data.vpTrack.TimePosition = math.clamp(scrub,0,Data.vpTrack.Length) end end) end
		end
	end)
end

local function fmtTime(n) return string.format("%.2f", n) end

table.insert(Data.connections, Services.RunService.RenderStepped:Connect(function()
	local mouse = Services.UserInputService:GetMouseLocation()
	if UI.viewportWin.Visible and Data.ghostChar then
		local camPitch = State.vpPitch or 0


		local offsetX = State.vpCamOffsetX or 0
		local offsetY = State.vpCamOffsetY or 0
		local targetPos = Vector3.new(offsetX, 4 + offsetY, 0)
		local camPos = targetPos + (CFrame.Angles(camPitch, State.vpYaw, 0) * Vector3.new(0, 0, State.vpZoomDist))
		vpCamera.CFrame = CFrame.new(camPos, targetPos)
	end
	if State.vpScrubbing then
		local bx = UI.vpScrubBg.AbsolutePosition.X; local bw = UI.vpScrubBg.AbsoluteSize.X
		local rel = math.clamp((mouse.X - bx) / bw, 0, 1)
		if Data.vpTrack and Data.vpTrack.Length > 0 then State.vpPausedAt = rel * Data.vpTrack.Length; Data.vpTrack.TimePosition = State.vpPausedAt
		elseif State.vpPaused and State.vpPausedLength > 0 then
			State.vpPausedAt = rel * State.vpPausedLength
			if Data.vpScrubTrack then Data.vpScrubTrack.TimePosition = State.vpPausedAt end
			spawnDummyPausedAt = rel * (Data.tempSpawnScrubTrack and Data.tempSpawnScrubTrack.Length or 1)
			if Data.tempSpawnScrubTrack then Data.tempSpawnScrubTrack.TimePosition = spawnDummyPausedAt end
		end
	end
	local trackLen = Data.vpTrack and Data.vpTrack.Length > 0 and Data.vpTrack.Length or (Data.spawnDummyTrack and Data.spawnDummyTrack.Length > 0 and Data.spawnDummyTrack.Length or (Data.tempSpawnScrubTrack and Data.tempSpawnScrubTrack.Length > 0 and Data.tempSpawnScrubTrack.Length or 0))
	local trackPos = Data.vpTrack and Data.vpTrack.TimePosition or (Data.spawnDummyTrack and Data.spawnDummyTrack.TimePosition or (Data.tempSpawnScrubTrack and Data.tempSpawnScrubTrack.TimePosition or 0))
	if State.vpPaused and State.vpPausedLength > 0 then
		UI.vpScrubFill.Size = UDim2.new(math.clamp(State.vpPausedAt/State.vpPausedLength,0,1),0,1,0); UI.vpScrubFill.BackgroundColor3 = Color3.fromRGB(200,50,50)
	elseif trackLen > 0 then
		UI.vpScrubFill.Size = UDim2.new(math.clamp(trackPos/trackLen,0,1),0,1,0)
		UI.vpScrubFill.BackgroundColor3 = Color3.fromRGB(200,50,50)
	elseif not State.vpScrubbing then UI.vpScrubFill.Size = UDim2.new(0,0,1,0) end
	if State.vpPaused then
		UI.vpTimerLabel.Text = "⏸ " .. fmtTime(State.vpPausedAt) .. "s / " .. fmtTime(State.vpPausedLength) .. "s"; UI.vpTimerLabel.TextColor3 = Color3.fromRGB(95,95,95)
	elseif Data.vpTrack then
		local pos = Data.vpTrack.TimePosition; local len = Data.vpTrack.Length
		if Data.vpTrack.IsPlaying then
			if State.vpLooped and pos < State.vpLastPos and State.vpLastPos > 0.1 then State.vpLoopFlash = 0.25 end
			State.vpLastPos = pos
			if State.vpLoopFlash > 0 then
				State.vpLoopFlash = math.max(0, State.vpLoopFlash - 0.016); local t = State.vpLoopFlash/0.25
				UI.vpTimerLabel.TextColor3 = Color3.fromRGB(math.floor(255*t), math.floor(220+(255-220)*t), math.floor(160+(100-160)*t))
			else UI.vpTimerLabel.TextColor3 = Color3.fromRGB(160,160,160) end
			UI.vpTimerLabel.Text = "▶ " .. fmtTime(pos) .. "s / " .. fmtTime(len) .. "s"
		else State.vpLastPos = 0; UI.vpTimerLabel.Text = "stopped"; UI.vpTimerLabel.TextColor3 = Color3.fromRGB(100,100,100) end
	else UI.vpTimerLabel.Text = "-- / --"; UI.vpTimerLabel.TextColor3 = Color3.fromRGB(65,65,65) end
	local activeTrack = nil; local activeCount = 0
	for t in pairs(Data.scriptTracks) do
		if t.IsPlaying or (State.mainPaused and Data.scriptTracks[t]) then activeCount += 1; if not activeTrack then activeTrack = t end end
	end
	if not activeTrack then for t in pairs(Data.scriptTracks) do activeTrack = t; break end end
	if State.mainScrubbing and activeTrack and activeTrack.Length > 0 then
		local bx = UI.mainScrubBg.AbsolutePosition.X; local bw = UI.mainScrubBg.AbsoluteSize.X
		local rel = math.clamp((mouse.X - bx) / bw, 0, 1); activeTrack.TimePosition = rel * activeTrack.Length
	end
	if activeTrack and activeTrack.Length > 0 then
		local pct = math.clamp(activeTrack.TimePosition/activeTrack.Length,0,1)
		UI.mainScrubFill.Size = UDim2.new(pct,0,1,0); UI.mainScrubFill.BackgroundColor3 = Color3.fromRGB(200,50,50)
	else UI.mainScrubFill.Size = UDim2.new(0,0,1,0) end
	if activeTrack and activeTrack.Length > 0 then
		local pos = activeTrack.TimePosition; local len = activeTrack.Length; local id = grabId(activeTrack.Animation.AnimationId) or "?"
		UI.mainTimerLabel.Text = (State.mainPaused and "⏸ " or "▶ ") .. id .. "  " .. fmtTime(pos) .. "s / " .. fmtTime(len) .. "s" .. (activeCount > 1 and ("  (+" .. (activeCount-1) .. ")") or "")
		UI.mainTimerLabel.TextColor3 = State.mainPaused and Color3.fromRGB(95,95,95) or Color3.fromRGB(160,160,160)
	else
		UI.mainTimerLabel.Text = "no anim playing"; UI.mainTimerLabel.TextColor3 = Color3.fromRGB(65,65,65)
		if State.mainPaused then State.mainPaused = false; UI.mainPauseBtn.Text = "⏸ Pause"; UI.mainPauseBtn.BackgroundColor3 = Color3.fromRGB(42,42,42) end
	end
end))

local vpCamState = {orbiting = false, lastMouseX = 0, lastMouseY = 0}


table.insert(Data.connections, UI.vpFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
		local m = Services.UserInputService:GetMouseLocation()
		vpCamState.orbiting = true; vpCamState.lastMouseX = m.X; vpCamState.lastMouseY = m.Y
	end
end))

table.insert(Data.connections, UI.vpFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local scrollDir = input.Position.Z > 0 and 1 or -1
		State.vpZoomDist = math.clamp(State.vpZoomDist - (scrollDir * 2), 1, 200)
	end
end))
table.insert(Data.connections, Services.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then vpCamState.orbiting = false end
end))
table.insert(Data.connections, Services.UserInputService.InputChanged:Connect(function(input)
	if vpCamState.orbiting and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local mouse = Services.UserInputService:GetMouseLocation()
		local deltaX = mouse.X - vpCamState.lastMouseX
		local deltaY = mouse.Y - vpCamState.lastMouseY
		State.vpYaw = State.vpYaw - math.rad(deltaX * 0.65)
		State.vpPitch = math.clamp((State.vpPitch or 0) + math.rad(deltaY * 0.65), -math.pi/2.5, math.pi/2.5)
		vpCamState.lastMouseX = mouse.X; vpCamState.lastMouseY = mouse.Y
	end
end))

local function popPreview(id)
	State.vpCurrentId = id; UI.vpIdLabel.Text = "ID: " .. id; UI.vpTitle.Text = "preview — " .. id
	UI.vpIdInput.Text = id; UI.viewportWin.Visible = true; previewAnim(id)
	if Data.spawnDummy and id then playOnSpawnDummy(id, tonumber(UI.vpSpeedBox.Text) or 1, State.vpLooped) end
end
table.insert(Data.connections, UI.vpIdGoBtn.MouseButton1Click:Connect(function()
	local id = grabId(UI.vpIdInput.Text); if id and id ~= "" then popPreview(id) end
end))
table.insert(Data.connections, UI.vpIdInput.FocusLost:Connect(function(enter)
	if enter then local id = grabId(UI.vpIdInput.Text); if id and id ~= "" then popPreview(id) end end
end))
table.insert(Data.connections, UI.vpPlayBtn.MouseButton1Click:Connect(function()
	if State.vpCurrentId then previewAnim(State.vpCurrentId) end
	if Data.spawnDummy and State.vpCurrentId then playOnSpawnDummy(State.vpCurrentId, tonumber(UI.vpSpeedBox.Text) or 1, State.vpLooped) end
end))
table.insert(Data.connections, UI.vpStopBtn.MouseButton1Click:Connect(function()
	if Data.vpTrack then pcall(function() Data.vpTrack:Stop(0) end); Data.vpTrack = nil end; nukeGhost()
	for _, track in ipairs(Data.spawnDummyAnimator and Data.spawnDummyAnimator:GetPlayingAnimationTracks() or {}) do track:Stop(0) end
	Data.spawnDummyTrack = nil
end))
table.insert(Data.connections, UI.vpPlaySelfBtn.MouseButton1Click:Connect(function()
	if State.vpCurrentId then fireAnim(State.vpCurrentId, tonumber(UI.vpSpeedBox.Text) or 1, State.vpLooped) end
end))
UI.vpRigToggle = Instance.new("TextButton"); UI.vpRigToggle.Size = UDim2.new(0,46,0,20); UI.vpRigToggle.Position = UDim2.new(0,10,25.4,3)
UI.vpRigToggle.Text = State.vpRigType; UI.vpRigToggle.BackgroundColor3 = Color3.fromRGB(28,40,55); UI.vpRigToggle.TextColor3 = Color3.fromRGB(150,190,235)
UI.vpRigToggle.BorderSizePixel = 0; UI.vpRigToggle.Font = Enum.Font.Code; UI.vpRigToggle.TextSize = 11; UI.vpRigToggle.ZIndex = 7; UI.vpRigToggle.Parent = vpTop
mkCorner(UI.vpRigToggle,4); mkStroke(UI.vpRigToggle, Color3.fromRGB(55,90,125), 1)
table.insert(Data.connections, UI.vpRigToggle.MouseButton1Click:Connect(function()
	State.vpRigType = (State.vpRigType == "R15") and "R6" or "R15"
	UI.vpRigToggle.Text = State.vpRigType
	if State.vpCurrentId and State.vpCurrentId ~= "" then previewAnim(State.vpCurrentId) end
end))
table.insert(Data.connections, UI.vpRotateCCW.MouseButton1Click:Connect(function()
	local deg = tonumber(UI.vpPrecisionBox.Text) or 90; State.vpYaw = State.vpYaw + math.rad(deg)
end))
table.insert(Data.connections, UI.vpRotateCW.MouseButton1Click:Connect(function()
	local deg = tonumber(UI.vpPrecisionBox.Text) or 90; State.vpYaw = State.vpYaw - math.rad(deg)
end))
table.insert(Data.connections, UI.vpZoomIn.MouseButton1Click:Connect(function()
	local step = tonumber(UI.vpPrecisionBox.Text) or 2; State.vpZoomDist = math.clamp(State.vpZoomDist - step, 1, 200)
end))
table.insert(Data.connections, UI.vpZoomOut.MouseButton1Click:Connect(function()
	local step = tonumber(UI.vpPrecisionBox.Text) or 2; State.vpZoomDist = math.clamp(State.vpZoomDist + step, 1, 200)
end))
table.insert(Data.connections, UI.vpSpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(UI.vpSpeedBox.Text:match("[%d%.]+"))
	if num and Data.vpTrack and Data.vpTrack.IsPlaying then Data.vpTrack:AdjustSpeed(num) end
	if num and Data.spawnDummyTrack and Data.spawnDummyTrack.IsPlaying then Data.spawnDummyTrack:AdjustSpeed(num) end
end))
table.insert(Data.connections, UI.vpTimeBox:GetPropertyChangedSignal("Text"):Connect(function()
	local num = tonumber(UI.vpTimeBox.Text:match("[%d%.]+"))
	if num and Data.vpTrack and Data.vpTrack.IsPlaying then Data.vpTrack.TimePosition = math.clamp(num,0,Data.vpTrack.Length) end
	if num and Data.spawnDummyTrack and Data.spawnDummyTrack.IsPlaying then Data.spawnDummyTrack.TimePosition = math.clamp(num,0,Data.spawnDummyTrack.Length) end
end))
table.insert(Data.connections, UI.vpLoopToggle.MouseButton1Click:Connect(function()
	State.vpLooped = not State.vpLooped
	UI.vpLoopToggle.Text = "Loop: " .. (State.vpLooped and "ON" or "OFF")
	UI.vpLoopToggle.BackgroundColor3 = State.vpLooped and Color3.fromRGB(28,28,28) or Color3.fromRGB(8,8,8)
	if Data.vpTrack then Data.vpTrack.Looped = State.vpLooped end
	if Data.spawnDummyTrack then Data.spawnDummyTrack.Looped = State.vpLooped end
end))
table.insert(Data.connections, UI.previewToggle.MouseButton1Click:Connect(function()
	UI.viewportWin.Visible = not UI.viewportWin.Visible
end))
table.insert(Data.connections, UI.vpSkinLoadBtn.MouseButton1Click:Connect(function()
	local query = UI.vpSkinInput.Text:match("^%s*(.-)%s*$")
	if query == "" then UI.vpSkinStatusLabel.Text = "enter a username or userid"; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160); return end
	if not Data.ghostChar then UI.vpSkinStatusLabel.Text = "load an animation first"; UI.vpSkinStatusLabel.TextColor3 = Color3.fromRGB(160,160,160); return end
	applyPlayerSkin(query)
end))
table.insert(Data.connections, UI.vpSkinInput.FocusLost:Connect(function(enter)
	if enter then local query = UI.vpSkinInput.Text:match("^%s*(.-)%s*$"); if query ~= "" and Data.ghostChar then applyPlayerSkin(query) end end
end))
table.insert(Data.connections, UI.vpSkinResetBtn.MouseButton1Click:Connect(function() resetDummySkin() end))
table.insert(Data.connections, UI.vpTestDummyBtn.MouseButton1Click:Connect(function()
	if not State.vpCurrentId or State.vpCurrentId == "" then flashNotif("no animation loaded"); return end
	local spd = tonumber(UI.vpSpeedBox.Text) or 1
	if Data.spawnDummy then
		ensureSpawnDummyAnimator()
		stopSpawnDummyTrack()
		playOnSpawnDummy(State.vpCurrentId, spd, State.vpLooped)
	elseif Data.ghostChar then
		stopAllDummyTracks()
		playOnDummy(State.vpCurrentId, spd, State.vpLooped, 0, "Action4")
	else
		flashNotif("spawn dummy or load preview first")
		return
	end
	UI.vpTestDummyBtn.Text = "▶ playing!"; UI.vpTestDummyBtn.BackgroundColor3 = Color3.fromRGB(42,42,42)
	task.delay(1.5, function() UI.vpTestDummyBtn.Text = "▶ test on dummy"; UI.vpTestDummyBtn.BackgroundColor3 = Color3.fromRGB(42,42,42) end)
end))
table.insert(Data.connections, UI.vpStopDummyBtn.MouseButton1Click:Connect(stopAllDummyTracks))
table.insert(Data.connections, UI.vpRunDummyMacroBtn.MouseButton1Click:Connect(function()
	local macro = UI.vpDummyMacroBox.Text:match("^%s*(.-)%s*$"); if macro == "" then return end
	runMacroOnDummy(macro)
end))

local function playOnDummy(id, speed, loop, startOffset, priorityName)
	local aid = grabId(tostring(id)) or tostring(id)
	if aid == "" then return nil end
	local animator = getDummyAnimator(); if not animator then return nil end
	local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. aid
	local track; pcall(function() track = animator:LoadAnimation(anim) end); if not track then return nil end
	local pri = Enum.AnimationPriority[priorityName] or Enum.AnimationPriority.Action4
	track.Priority = pri; track.Looped = loop or false
	track:Play(0, 1, speed or 1)
	if startOffset and startOffset > 0 then
		task.defer(function() if track then track.TimePosition = math.clamp(startOffset, 0, track.Length) end end)
	end
	Data.dummyTracks[track] = true
	track.Stopped:Connect(function() Data.dummyTracks[track] = nil end)
	return track
end

local function stopAllDummyTracks()
	for track in pairs(Data.dummyTracks) do
		pcall(function() track:Stop(0) end); Data.dummyTracks[track] = nil
	end
end

local function runMacroOnDummy(macroStr)
	if not Data.ghostChar then flashNotif("load an animation first"); return end
	task.spawn(function()
		
		local animator = getDummyAnimator()
		local waited = 0
		while not animator and waited < 2 do
			task.wait(0.05); waited += 0.05
			animator = getDummyAnimator()
		end
		if not animator then flashNotif("dummy not ready"); return end
		local steps = macroStr:split(";")
		for _, step in ipairs(steps) do
			step = step:match("^%s*(.-)%s*$"); if step == "" then continue end
			local parts = step:split(" "); local cmd = parts[1]:lower()
			if cmd == "play" then
				local id = parts[2]; local spd = tonumber(parts[3]) or 1; local lp = (parts[4] == "true")
				if id and id ~= "" then
					local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. id
					local track; pcall(function() track = animator:LoadAnimation(anim) end)
					if track then
						track.Priority = Enum.AnimationPriority.Action4; track.Looped = lp; track:Play(0,1,spd)
						Data.dummyTracks[track] = true; track.Stopped:Connect(function() Data.dummyTracks[track] = nil end)
					end
				end
			elseif cmd == "wait" then
				local t = tonumber(parts[2]) or 0.5; task.wait(t)
			elseif cmd == "stop" then
				local id = parts[2]
				if id and id ~= "" then
					for track in pairs(Data.dummyTracks) do
						if grabId(track.Animation.AnimationId) == id then pcall(function() track:Stop(0) end); Data.dummyTracks[track] = nil end
					end
				else stopAllDummyTracks() end
			elseif cmd == "speed" then
				local num = tonumber(parts[2])
				if num then for track in pairs(Data.dummyTracks) do if track.IsPlaying then track:AdjustSpeed(num) end end end
			end
		end
	end)
end

local PRIORITY_OPTIONS = {"Action4","Action3","Action2","Action","Movement","Idle","Core"}


local function saveFilterPreset(name)
	State.advancedFilters.presets[name] = {
		name = name,
		filters = table.clone(State.advancedFilters.activeFilters),
		logic = State.advancedFilters.logic
	}
	if dumpCfg then dumpCfg() end
end

local function loadFilterPreset(name)
	local preset = State.advancedFilters.presets[name]
	if preset then
		State.advancedFilters.activeFilters = table.clone(preset.filters)
		State.advancedFilters.logic = preset.logic
		State.advancedFilters.currentPreset = name
		if dumpCfg then dumpCfg() end
		return true
	end
	return false
end

local function deleteFilterPreset(name)
	if name ~= "Default" and State.advancedFilters.presets[name] then
		State.advancedFilters.presets[name] = nil
		if State.advancedFilters.currentPreset == name then
			loadFilterPreset("Default")
		end
		if dumpCfg then dumpCfg() end
		return true
	end
	return false
end

local function getFilterStatistics()
	local total = 0
	local visible = 0
	local filters = {}

	for id, entry in pairs(Data.animFrames) do
		if id:find("__frame", 1, true) then continue end
		total = total + 1

		local animData = {
			id = id:match("^([%d]+)") or id,
			name = entry.Text,
			player = "", 
			priority = "", 
			count = Data.animCounts[id] or 1,
			favorited = Data.favorites[id:match("^([%d]+)") or id] or false
		}

		if shouldShowAnimation(animData) then
			visible = visible + 1
		end
	end

	return {total = total, visible = visible, hidden = total - visible}
end

local function buildTriggerRow(ruleData, triggerIndex, triggerData)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	row.BorderSizePixel = 0
	row.ZIndex = 4
	mkCorner(row, 4)

	local typeDropdown = Instance.new("TextButton")
	typeDropdown.Size = UDim2.new(0, 80, 1, 0)
	typeDropdown.Position = UDim2.new(0, 5, 0, 0)
	typeDropdown.Text = triggerData.type or "animId"
	typeDropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	typeDropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
	typeDropdown.Font = Enum.Font.Code
	typeDropdown.TextSize = 10
	typeDropdown.ZIndex = 5
	typeDropdown.Parent = row
	mkCorner(typeDropdown, 3)

	local paramInput = Instance.new("TextBox")
	paramInput.Size = UDim2.new(1, -95, 1, 0)
	paramInput.Position = UDim2.new(0, 90, 0, 0)
	paramInput.Text = triggerData.param or ""
	paramInput.PlaceholderText = "parameter..."
	paramInput.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	paramInput.TextColor3 = Color3.fromRGB(240, 240, 240)
	paramInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
	paramInput.Font = Enum.Font.Code
	paramInput.TextSize = 11
	paramInput.ZIndex = 5
	paramInput.Parent = row
	mkCorner(paramInput, 3)

	local removeBtn = Instance.new("TextButton")
	removeBtn.Size = UDim2.new(0, 20, 0, 20)
	removeBtn.Position = UDim2.new(1, -25, 0, 5)
	removeBtn.Text = "×"
	removeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	removeBtn.Font = Enum.Font.Code
	removeBtn.TextSize = 12
	removeBtn.ZIndex = 5
	removeBtn.Parent = row
	mkCorner(removeBtn, 3)

	table.insert(Data.connections, typeDropdown.MouseButton1Click:Connect(function()
		local menu = Instance.new("Frame")
		menu.Size = UDim2.new(0, 80, 0, 120)
		menu.Position = UDim2.new(0, 0, 1, 5)
		menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		menu.BorderSizePixel = 0
		menu.ZIndex = 10
		menu.Parent = typeDropdown
		mkCorner(menu, 3)
		mkStroke(menu, Color3.fromRGB(60, 60, 60), 1)

		local options = {"animId", "animName", "player", "priority", "anyAnim"}
		for i, opt in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1, 0, 0, 20)
			optBtn.Position = UDim2.new(0, 0, 0, (i-1)*20)
			optBtn.Text = opt
			optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
			optBtn.Font = Enum.Font.Code
			optBtn.TextSize = 10
			optBtn.ZIndex = 11
			optBtn.Parent = menu
			mkCorner(optBtn, 2)

			table.insert(Data.connections, optBtn.MouseButton1Click:Connect(function()
				triggerData.type = opt
				typeDropdown.Text = opt
				menu:Destroy()
				if dumpCfg then dumpCfg() end
			end))
		end

		task.delay(5, function() if menu and menu.Parent then menu:Destroy() end end)
	end))

	table.insert(Data.connections, paramInput:GetPropertyChangedSignal("Text"):Connect(function()
		triggerData.param = paramInput.Text
		if dumpCfg then dumpCfg() end
	end))

	table.insert(Data.connections, removeBtn.MouseButton1Click:Connect(function()
		table.remove(ruleData.triggers, triggerIndex)
		row:Destroy()
		if dumpCfg then dumpCfg() end
	end))

	return row
end

local function buildActionRow(ruleData, actionIndex, actionData)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	row.BorderSizePixel = 0
	row.ZIndex = 4
	mkCorner(row, 4)

	local typeDropdown = Instance.new("TextButton")
	typeDropdown.Size = UDim2.new(0, 80, 1, 0)
	typeDropdown.Position = UDim2.new(0, 5, 0, 0)
	typeDropdown.Text = actionData.type or "play"
	typeDropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	typeDropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
	typeDropdown.Font = Enum.Font.Code
	typeDropdown.TextSize = 10
	typeDropdown.ZIndex = 5
	typeDropdown.Parent = row
	mkCorner(typeDropdown, 3)

	local paramInput = Instance.new("TextBox")
	paramInput.Size = UDim2.new(1, -95, 1, 0)
	paramInput.Position = UDim2.new(0, 90, 0, 0)
	paramInput.Text = actionData.param or ""
	paramInput.PlaceholderText = "parameters..."
	paramInput.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	paramInput.TextColor3 = Color3.fromRGB(240, 240, 240)
	paramInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
	paramInput.Font = Enum.Font.Code
	paramInput.TextSize = 11
	paramInput.ZIndex = 5
	paramInput.Parent = row
	mkCorner(paramInput, 3)

	local removeBtn = Instance.new("TextButton")
	removeBtn.Size = UDim2.new(0, 20, 0, 20)
	removeBtn.Position = UDim2.new(1, -25, 0, 5)
	removeBtn.Text = "×"
	removeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	removeBtn.Font = Enum.Font.Code
	removeBtn.TextSize = 12
	removeBtn.ZIndex = 5
	removeBtn.Parent = row
	mkCorner(removeBtn, 3)

	table.insert(Data.connections, typeDropdown.MouseButton1Click:Connect(function()
		local menu = Instance.new("Frame")
		menu.Size = UDim2.new(0, 80, 0, 160)
		menu.Position = UDim2.new(0, 0, 1, 5)
		menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		menu.BorderSizePixel = 0
		menu.ZIndex = 10
		menu.Parent = typeDropdown
		mkCorner(menu, 3)
		mkStroke(menu, Color3.fromRGB(60, 60, 60), 1)

		local options = {"play", "stop", "speed", "priority", "weight", "fade", "wait", "macro", "var", "flash"}
		for i, opt in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1, 0, 0, 20)
			optBtn.Position = UDim2.new(0, 0, 0, (i-1)*20)
			optBtn.Text = opt
			optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
			optBtn.Font = Enum.Font.Code
			optBtn.TextSize = 10
			optBtn.ZIndex = 11
			optBtn.Parent = menu
			mkCorner(optBtn, 2)

			table.insert(Data.connections, optBtn.MouseButton1Click:Connect(function()
				actionData.type = opt
				typeDropdown.Text = opt
				menu:Destroy()
				if dumpCfg then dumpCfg() end
			end))
		end

		task.delay(5, function() if menu and menu.Parent then menu:Destroy() end end)
	end))

	table.insert(Data.connections, paramInput:GetPropertyChangedSignal("Text"):Connect(function()
		actionData.param = paramInput.Text
		if dumpCfg then dumpCfg() end
	end))

	table.insert(Data.connections, removeBtn.MouseButton1Click:Connect(function()
		table.remove(ruleData.actions, actionIndex)
		row:Destroy()
		if dumpCfg then dumpCfg() end
	end))

	return row
end

local function addAdvReplUI(ruleData)
	if not ruleData then
		ruleData = {
			enabled = true,
			name = "New Rule",
			triggers = {{type="animId", value="", priority="any", player="any"}},
			conditions = {},
			actions = {{type="play", param=""}},
			variables = {},
			chainTo = "",
			cooldown = 0,
			lastFired = 0
		}
		table.insert(Data.advReplacements, ruleData)
	end

	local ruleIndex = nil
	for i, r in ipairs(Data.advReplacements) do if r == ruleData then ruleIndex = i; break end end
	if not ruleIndex then table.insert(Data.advReplacements, ruleData); ruleIndex = #Data.advReplacements end

	local rFrame = Instance.new("Frame")
	rFrame.Size = UDim2.new(1,-4,0,10)
	rFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
	rFrame.BorderSizePixel = 0; rFrame.ZIndex = 3; rFrame.Parent = sideTabLists[3]
	mkCorner(rFrame,8)
	do local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(100,150,200); s.Thickness=1.5; s.Transparency=0.3; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=rFrame end

	local innerList = Instance.new("UIListLayout")
	innerList.Padding = UDim.new(0,8)
	innerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	innerList.SortOrder = Enum.SortOrder.LayoutOrder
	innerList.Parent = rFrame
	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingTop=UDim.new(0,10); innerPad.PaddingBottom=UDim.new(0,10)
	innerPad.PaddingLeft=UDim.new(0,10); innerPad.PaddingRight=UDim.new(0,10)
	innerPad.Parent = rFrame
	table.insert(Data.connections, innerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		rFrame.Size = UDim2.new(1,-4,0,innerList.AbsoluteContentSize.Y+25)
	end))

	local rowOrder = 0
	local function mkRow(h)
		rowOrder+=1
		local r=Instance.new("Frame"); r.Size=UDim2.new(1,0,0,h); r.BackgroundTransparency=1
		r.BorderSizePixel=0; r.ZIndex=4; r.LayoutOrder=rowOrder; r.Parent=rFrame; return r
	end
	local function mkInput(parent, text, ph)
		local b=Instance.new("TextBox"); b.Size=UDim2.new(1,0,1,0); b.Text=text or ""; b.PlaceholderText=ph or ""
		b.BackgroundColor3=Color3.fromRGB(18,18,18); b.TextColor3=Color3.fromRGB(240,240,240)
		b.PlaceholderColor3=Color3.fromRGB(80,80,80); b.Font=Enum.Font.Code; b.TextSize=11
		b.BorderSizePixel=0; b.ZIndex=5; b.Parent=parent; mkCorner(b,4)
		do local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(60,60,60); s.Thickness=1; s.Transparency=0.5; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=b end
		return b
	end
	local function mkBtn(parent, text, bg, tc)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,1,0); b.Text=text or ""
		b.BackgroundColor3=bg or Color3.fromRGB(35,35,35); b.TextColor3=tc or Color3.fromRGB(200,200,200)
		b.Font=Enum.Font.Code; b.TextSize=11; b.BorderSizePixel=0; b.ZIndex=5; b.Parent=parent; mkCorner(b,4)
		do local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(80,80,80); s.Thickness=1; s.Transparency=0.5; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=b end
		return b
	end

	do
		local row=mkRow(28)
		local nameBox=mkInput(row, ruleData.name or "New Rule", "rule name...")
		table.insert(Data.connections, nameBox:GetPropertyChangedSignal("Text"):Connect(function() ruleData.name=nameBox.Text; dumpCfg() end))

		local enableT=Instance.new("TextButton"); enableT.Size=UDim2.new(0,60,1,0); enableT.Position=UDim2.new(1,-60,0,0)
		enableT.Text=ruleData.enabled and "ON" or "OFF"
		enableT.BackgroundColor3=ruleData.enabled and Color3.fromRGB(40,80,40) or Color3.fromRGB(80,40,40)
		enableT.TextColor3=Color3.fromRGB(255,255,255); enableT.Font=Enum.Font.GothamBold; enableT.TextSize=10; enableT.BorderSizePixel=0; enableT.ZIndex=5; enableT.Parent=row; mkCorner(enableT,4)
		table.insert(Data.connections, enableT.MouseButton1Click:Connect(function()
			ruleData.enabled=not ruleData.enabled
			enableT.Text=ruleData.enabled and "ON" or "OFF"
			enableT.BackgroundColor3=ruleData.enabled and Color3.fromRGB(40,80,40) or Color3.fromRGB(80,40,40)
			dumpCfg()
		end))
	end

	local triggerHolder=Instance.new("Frame")
	triggerHolder.Size=UDim2.new(1,0,0,0); triggerHolder.BackgroundTransparency=1; triggerHolder.BorderSizePixel=0
	triggerHolder.ZIndex=4; triggerHolder.LayoutOrder=rowOrder+1; triggerHolder.Parent=rFrame
	rowOrder+=1
	local triggerLayout=Instance.new("UIListLayout"); triggerLayout.Padding=UDim.new(0,4); triggerLayout.Parent=triggerHolder
	table.insert(Data.connections, triggerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		triggerHolder.Size=UDim2.new(1,0,0,triggerLayout.AbsoluteContentSize.Y)
	end))

	local function buildTriggerRow(triggerData, triggerIdx)
		local tCard=Instance.new("Frame"); tCard.Size=UDim2.new(1,0,0,10); tCard.BackgroundColor3=Color3.fromRGB(30,30,30)
		tCard.BorderSizePixel=0; tCard.ZIndex=5; tCard.Parent=triggerHolder; mkCorner(tCard,5)
		do local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(100,100,100); s.Thickness=1; s.Transparency=0.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=tCard end

		local tcList=Instance.new("UIListLayout"); tcList.Padding=UDim.new(0,3)
		tcList.HorizontalAlignment=Enum.HorizontalAlignment.Center; tcList.SortOrder=Enum.SortOrder.LayoutOrder; tcList.Parent=tCard
		local tcPad=Instance.new("UIPadding"); tcPad.PaddingTop=UDim.new(0,5); tcPad.PaddingBottom=UDim.new(0,5)
		tcPad.PaddingLeft=UDim.new(0,5); tcPad.PaddingRight=UDim.new(0,5); tcPad.Parent=tCard
		table.insert(Data.connections, tcList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tCard.Size=UDim2.new(1,0,0,tcList.AbsoluteContentSize.Y+14)
		end))

		local to=0
		local function tr(h) to+=1; local r=Instance.new("Frame"); r.Size=UDim2.new(1,0,0,h); r.BackgroundTransparency=1; r.BorderSizePixel=0; r.ZIndex=6; r.LayoutOrder=to; r.Parent=tCard; return r end

		do
			local hr=tr(20)
			local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-25,1,0); lbl.BackgroundTransparency=1
			lbl.TextColor3=Color3.fromRGB(150,150,150); lbl.Font=Enum.Font.Code; lbl.TextSize=10
			lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text="WHEN: " .. (triggerData.type or "animId"); lbl.ZIndex=7; lbl.Parent=hr
			local db=Instance.new("TextButton"); db.Size=UDim2.new(0,20,1,0); db.Position=UDim2.new(1,-20,0,0)
			db.Text="×"; db.BackgroundColor3=Color3.fromRGB(150,50,50); db.TextColor3=Color3.fromRGB(255,255,255)
			db.Font=Enum.Font.GothamBold; db.TextSize=12; db.BorderSizePixel=0; db.ZIndex=7; db.Parent=hr; mkCorner(db,3)
			table.insert(Data.connections, db.MouseButton1Click:Connect(function()
				table.remove(ruleData.triggers, triggerIdx); tCard:Destroy(); dumpCfg()
			end))
		end

		local triggerOpts={"animId","animName","player","priority","anyAnim"}
		local typeIdx=1
		for i,v in ipairs(triggerOpts) do if v==(triggerData.type or "animId") then typeIdx=i; break end end
		local openMenu = nil
		local typeBtn=mkBtn(tr(24), triggerOpts[typeIdx], Color3.fromRGB(50,50,80), Color3.fromRGB(180,180,220))
		table.insert(Data.connections, typeBtn.MouseButton1Click:Connect(function()
			if openMenu and openMenu.Parent then openMenu:Destroy(); openMenu = nil; return end
			local menu = Instance.new("Frame")
			menu.Size = UDim2.new(0, 120, 0, #triggerOpts * 22 + 4)
			menu.BackgroundColor3 = Color3.fromRGB(28,28,40)
			menu.BorderSizePixel = 0; menu.ZIndex = 50
			mkCorner(menu, 4); mkStroke(menu, Color3.fromRGB(80,80,120), 1)
			local menuList = Instance.new("UIListLayout"); menuList.Padding = UDim.new(0,2)
			local menuPad = Instance.new("UIPadding")
			menuPad.PaddingTop = UDim.new(0,2); menuPad.PaddingBottom = UDim.new(0,2)
			menuPad.PaddingLeft = UDim.new(0,2); menuPad.PaddingRight = UDim.new(0,2)
			menuList.Parent = menu; menuPad.Parent = menu
			local absPos = typeBtn.AbsolutePosition
			local absSize = typeBtn.AbsoluteSize
			menu.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
			menu.Parent = UI.gui
			openMenu = menu
			for _, opt in ipairs(triggerOpts) do
				local item = Instance.new("TextButton")
				item.Size = UDim2.new(1,0,0,20)
				item.BackgroundColor3 = opt == triggerOpts[typeIdx] and Color3.fromRGB(55,55,90) or Color3.fromRGB(35,35,55)
				item.TextColor3 = Color3.fromRGB(200,200,230)
				item.Font = Enum.Font.Code; item.TextSize = 10
				item.Text = opt; item.BorderSizePixel = 0; item.ZIndex = 51
				item.Parent = menu; mkCorner(item, 3)
				table.insert(Data.connections, item.MouseButton1Click:Connect(function()
					for i,v in ipairs(triggerOpts) do if v==opt then typeIdx=i; break end end
					triggerData.type = opt; typeBtn.Text = opt
					if openMenu then openMenu:Destroy(); openMenu = nil end
					dumpCfg()
				end))
			end
		end))

		local valBox=mkInput(tr(24), triggerData.value or "", "value/pattern...")
		table.insert(Data.connections, valBox:GetPropertyChangedSignal("Text"):Connect(function() triggerData.value=valBox.Text; dumpCfg() end))

		return tCard
	end

	for i,trigger in ipairs(ruleData.triggers or {}) do buildTriggerRow(trigger, i) end

	do
		local row=mkRow(26)
		local addTrigBtn=mkBtn(row, "+ Add Trigger", Color3.fromRGB(40,60,40), Color3.fromRGB(150,200,150))
		table.insert(Data.connections, addTrigBtn.MouseButton1Click:Connect(function()
			local newTrig={type="animId", value="", priority="any", player="any"}
			ruleData.triggers = ruleData.triggers or {}
			table.insert(ruleData.triggers, newTrig); buildTriggerRow(newTrig, #ruleData.triggers); dumpCfg()
		end))
	end

	local actionHolder=Instance.new("Frame")
	actionHolder.Size=UDim2.new(1,0,0,0); actionHolder.BackgroundTransparency=1; actionHolder.BorderSizePixel=0
	actionHolder.ZIndex=4; actionHolder.LayoutOrder=rowOrder+1; actionHolder.Parent=rFrame
	rowOrder+=1
	local actionLayout=Instance.new("UIListLayout"); actionLayout.Padding=UDim.new(0,4); actionLayout.Parent=actionHolder
	table.insert(Data.connections, actionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		actionHolder.Size=UDim2.new(1,0,0,actionLayout.AbsoluteContentSize.Y)
	end))

	local function buildActionRow(actionData, actionIdx)
		local aCard=Instance.new("Frame"); aCard.Size=UDim2.new(1,0,0,10); aCard.BackgroundColor3=Color3.fromRGB(35,35,35)
		aCard.BorderSizePixel=0; aCard.ZIndex=5; aCard.Parent=actionHolder; mkCorner(aCard,5)
		do local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(120,120,120); s.Thickness=1; s.Transparency=0.6; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=aCard end

		local acList=Instance.new("UIListLayout"); acList.Padding=UDim.new(0,3)
		acList.HorizontalAlignment=Enum.HorizontalAlignment.Center; acList.SortOrder=Enum.SortOrder.LayoutOrder; acList.Parent=aCard
		local acPad=Instance.new("UIPadding"); acPad.PaddingTop=UDim.new(0,5); acPad.PaddingBottom=UDim.new(0,5)
		acPad.PaddingLeft=UDim.new(0,5); acPad.PaddingRight=UDim.new(0,5); acPad.Parent=aCard
		table.insert(Data.connections, acList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			aCard.Size=UDim2.new(1,0,0,acList.AbsoluteContentSize.Y+14)
		end))

		local ao=0
		local function ar(h) ao+=1; local r=Instance.new("Frame"); r.Size=UDim2.new(1,0,0,h); r.BackgroundTransparency=1; r.BorderSizePixel=0; r.ZIndex=6; r.LayoutOrder=ao; r.Parent=aCard; return r end

		do
			local hr=ar(20)
			local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-25,1,0); lbl.BackgroundTransparency=1
			lbl.TextColor3=Color3.fromRGB(180,180,180); lbl.Font=Enum.Font.Code; lbl.TextSize=10
			lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text="DO: " .. (actionData.type or "play"); lbl.ZIndex=7; lbl.Parent=hr
			local db=Instance.new("TextButton"); db.Size=UDim2.new(0,20,1,0); db.Position=UDim2.new(1,-20,0,0)
			db.Text="×"; db.BackgroundColor3=Color3.fromRGB(150,50,50); db.TextColor3=Color3.fromRGB(255,255,255)
			db.Font=Enum.Font.GothamBold; db.TextSize=12; db.BorderSizePixel=0; db.ZIndex=7; db.Parent=hr; mkCorner(db,3)
			table.insert(Data.connections, db.MouseButton1Click:Connect(function()
				table.remove(ruleData.actions, actionIdx); aCard:Destroy(); dumpCfg()
			end))
		end

		local actionOpts={"play","stop","speed","priority","weight","fade","wait","macro","var","flash"}
		local typeIdx=1
		for i,v in ipairs(actionOpts) do if v==(actionData.type or "play") then typeIdx=i; break end end
		local openMenu = nil
		local typeBtn=mkBtn(ar(24), actionOpts[typeIdx], Color3.fromRGB(50,70,50), Color3.fromRGB(150,200,150))
		table.insert(Data.connections, typeBtn.MouseButton1Click:Connect(function()
			if openMenu and openMenu.Parent then openMenu:Destroy(); openMenu = nil; return end
			local menu = Instance.new("Frame")
			menu.Size = UDim2.new(0, 110, 0, #actionOpts * 22 + 4)
			menu.BackgroundColor3 = Color3.fromRGB(28,40,28)
			menu.BorderSizePixel = 0; menu.ZIndex = 50
			mkCorner(menu, 4); mkStroke(menu, Color3.fromRGB(60,100,60), 1)
			local menuList = Instance.new("UIListLayout"); menuList.Padding = UDim.new(0,2)
			local menuPad = Instance.new("UIPadding")
			menuPad.PaddingTop = UDim.new(0,2); menuPad.PaddingBottom = UDim.new(0,2)
			menuPad.PaddingLeft = UDim.new(0,2); menuPad.PaddingRight = UDim.new(0,2)
			menuList.Parent = menu; menuPad.Parent = menu
			local absPos = typeBtn.AbsolutePosition
			local absSize = typeBtn.AbsoluteSize
			menu.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
			menu.Parent = UI.gui
			openMenu = menu
			for _, opt in ipairs(actionOpts) do
				local item = Instance.new("TextButton")
				item.Size = UDim2.new(1,0,0,20)
				item.BackgroundColor3 = opt == actionOpts[typeIdx] and Color3.fromRGB(50,80,50) or Color3.fromRGB(32,48,32)
				item.TextColor3 = Color3.fromRGB(160,210,160)
				item.Font = Enum.Font.Code; item.TextSize = 10
				item.Text = opt; item.BorderSizePixel = 0; item.ZIndex = 51
				item.Parent = menu; mkCorner(item, 3)
				table.insert(Data.connections, item.MouseButton1Click:Connect(function()
					for i,v in ipairs(actionOpts) do if v==opt then typeIdx=i; break end end
					actionData.type = opt; typeBtn.Text = opt
					if openMenu then openMenu:Destroy(); openMenu = nil end
					dumpCfg()
				end))
			end
		end))

		local paramBox=mkInput(ar(24), actionData.param or "", "parameters...")
		table.insert(Data.connections, paramBox:GetPropertyChangedSignal("Text"):Connect(function() actionData.param=paramBox.Text; dumpCfg() end))

		return aCard
	end

	for i,action in ipairs(ruleData.actions or {}) do buildActionRow(action, i) end

	do
		local row=mkRow(26)
		local addActBtn=mkBtn(row, "+ Add Action", Color3.fromRGB(50,50,70), Color3.fromRGB(150,150,200))
		table.insert(Data.connections, addActBtn.MouseButton1Click:Connect(function()
			local newAct={type="play", param=""}
			ruleData.actions = ruleData.actions or {}
			table.insert(ruleData.actions, newAct); buildActionRow(newAct, #ruleData.actions); dumpCfg()
		end))
	end

	do
		local row=mkRow(24)
		local chainBox=mkInput(row, ruleData.chainTo or "", "chain to rule name...")
		local chainLbl=Instance.new("TextLabel"); chainLbl.Size=UDim2.new(0.3,0,1,0); chainLbl.Position=UDim2.new(0.7,5,0,0)
		chainLbl.BackgroundTransparency=1; chainLbl.TextColor3=Color3.fromRGB(120,120,120); chainLbl.Font=Enum.Font.Code; chainLbl.TextSize=9
		chainLbl.Text="then →"; chainLbl.ZIndex=5; chainLbl.Parent=row
		table.insert(Data.connections, chainBox:GetPropertyChangedSignal("Text"):Connect(function() ruleData.chainTo=chainBox.Text; dumpCfg() end))
	end

	do
		local row=mkRow(24)
		local delBtn=mkBtn(row, "Delete Rule", Color3.fromRGB(80,40,40), Color3.fromRGB(220,120,120))
		table.insert(Data.connections, delBtn.MouseButton1Click:Connect(function()
			for i,r2 in ipairs(Data.advReplacements) do if r2==ruleData then table.remove(Data.advReplacements,i); break end end
			rFrame:Destroy(); dumpCfg()
		end))
	end


end

table.insert(Data.connections, UI.addAdvReplBtn.MouseButton1Click:Connect(function()
	addAdvReplUI(nil)
end))

local function addReplUI(id, targetId, speed, loop, enabled)
	if enabled == nil then enabled = true end
	local rFrame = Instance.new("Frame"); rFrame.Size = UDim2.new(1,0,0,145); rFrame.BackgroundColor3 = Color3.fromRGB(20,20,20); rFrame.BorderSizePixel = 0; rFrame.ZIndex = 3; rFrame.Parent = sideTabLists[2]
	mkCorner(rFrame,4); mkStroke(rFrame, Color3.fromRGB(42,42,42), 1)
	local replaceL = Instance.new("TextBox"); replaceL.Size = UDim2.new(1,-10,0,20); replaceL.Position = UDim2.new(0,5,0,5); replaceL.Text = id or ""
	replaceL.PlaceholderText = "replace anim id..."; replaceL.BackgroundColor3 = Color3.fromRGB(14,14,14); replaceL.TextColor3 = Color3.fromRGB(210,210,210); replaceL.Font = Enum.Font.Code; replaceL.BorderSizePixel = 0; replaceL.ZIndex = 4; replaceL.Parent = rFrame
	mkCorner(replaceL,3); mkStroke(replaceL, Color3.fromRGB(42,42,42), 1)
	local targetL = Instance.new("TextBox"); targetL.Size = UDim2.new(1,-10,0,20); targetL.Position = UDim2.new(0,5,0,30); targetL.Text = targetId or ""
	targetL.PlaceholderText = "target anim id..."; targetL.BackgroundColor3 = Color3.fromRGB(14,14,14); targetL.TextColor3 = Color3.fromRGB(210,210,210); targetL.Font = Enum.Font.Code; targetL.BorderSizePixel = 0; targetL.ZIndex = 4; targetL.Parent = rFrame
	mkCorner(targetL,3); mkStroke(targetL, Color3.fromRGB(42,42,42), 1)
	local speedL = Instance.new("TextBox"); speedL.Size = UDim2.new(0.5,-10,0,20); speedL.Position = UDim2.new(0,5,0,55); speedL.Text = tostring(speed or 1)
	speedL.BackgroundColor3 = Color3.fromRGB(14,14,14); speedL.TextColor3 = Color3.fromRGB(210,210,210); speedL.BorderSizePixel = 0; speedL.ZIndex = 4; speedL.Parent = rFrame
	mkCorner(speedL,3); mkStroke(speedL, Color3.fromRGB(42,42,42), 1)
	local loopT = Instance.new("TextButton"); loopT.Size = UDim2.new(0.5,-10,0,20); loopT.Position = UDim2.new(0.5,5,0,55)
	loopT.Text = "Loop: " .. (loop and "ON" or "OFF"); loopT.BackgroundColor3 = loop and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); loopT.TextColor3 = loop and Color3.fromRGB(140,210,145) or Color3.fromRGB(210,210,210); loopT.BorderSizePixel = 0; loopT.ZIndex = 4; loopT.Parent = rFrame; mkCorner(loopT,3)
	local loopTStroke = Instance.new("UIStroke"); loopTStroke.Color = loop and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); loopTStroke.Thickness = 1; loopTStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; loopTStroke.Parent = loopT
	local enableT2 = Instance.new("TextButton"); enableT2.Size = UDim2.new(1,-10,0,20); enableT2.Position = UDim2.new(0,5,0,80)
	enableT2.Text = enabled and "Enabled: ON" or "Enabled: OFF"; enableT2.BackgroundColor3 = enabled and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); enableT2.TextColor3 = enabled and Color3.fromRGB(140,210,145) or Color3.fromRGB(240,240,240); enableT2.Font = Enum.Font.Code; enableT2.TextSize = 11; enableT2.BorderSizePixel = 0; enableT2.ZIndex = 4; enableT2.Parent = rFrame; mkCorner(enableT2,3)
	local enableT2Stroke = Instance.new("UIStroke"); enableT2Stroke.Color = enabled and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); enableT2Stroke.Thickness = 1; enableT2Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; enableT2Stroke.Parent = enableT2
	local del = Instance.new("TextButton"); del.Size = UDim2.new(1,-10,0,20); del.Position = UDim2.new(0,5,0,105); del.Text = "Delete Replacement"
	del.BackgroundColor3 = Color3.fromRGB(200,50,50); del.TextColor3 = Color3.fromRGB(255,255,255); del.Font = Enum.Font.Code; del.TextSize = 11; del.BorderSizePixel = 0; del.ZIndex = 5; del.Parent = rFrame; mkCorner(del,3)
	local function updateRep()
		local oldId = id; id = replaceL.Text
		if oldId and oldId ~= id then Data.replacements[oldId] = nil end
		Data.replacements[id] = {targetId=targetL.Text, speed=tonumber(speedL.Text) or 1, loop=loop, enabled=enabled}; dumpCfg()
	end
	table.insert(Data.connections, replaceL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(Data.connections, targetL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(Data.connections, speedL:GetPropertyChangedSignal("Text"):Connect(updateRep))
	table.insert(Data.connections, loopT.MouseButton1Click:Connect(function()
		loop = not loop; loopT.Text = "Loop: " .. (loop and "ON" or "OFF"); loopT.BackgroundColor3 = loop and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); loopT.TextColor3 = loop and Color3.fromRGB(140,210,145) or Color3.fromRGB(210,210,210); loopTStroke.Color = loop and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); updateRep()
	end))
	table.insert(Data.connections, enableT2.MouseButton1Click:Connect(function()
		enabled = not enabled; enableT2.Text = enabled and "Enabled: ON" or "Enabled: OFF"; enableT2.BackgroundColor3 = enabled and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); enableT2.TextColor3 = enabled and Color3.fromRGB(140,210,145) or Color3.fromRGB(240,240,240); enableT2Stroke.Color = enabled and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); updateRep()
	end))
	table.insert(Data.connections, del.MouseButton1Click:Connect(function()
		Data.replacements[id] = nil; rFrame:Destroy(); dumpCfg()
	end))
end
table.insert(Data.connections, UI.addR.MouseButton1Click:Connect(function() addReplUI("","",1,false,true) end))

local sideList = UI.sideList
local function addBind(bindData)
	local bFrame = Instance.new("Frame"); bFrame.Size = UDim2.new(1,0,0,190); bFrame.BackgroundColor3 = Color3.fromRGB(20,20,20); bFrame.BorderSizePixel = 0; bFrame.ZIndex = 3; bFrame.Parent = sideList
	mkCorner(bFrame,5); mkStroke(bFrame, Color3.fromRGB(42,42,42), 1)
	local activeBar = Instance.new("Frame"); activeBar.Name = "ActiveBar"; activeBar.Size = UDim2.new(1,0,0,3); activeBar.Position = UDim2.new(0,0,0,0); activeBar.BackgroundColor3 = Color3.fromRGB(35,35,35); activeBar.BorderSizePixel = 0; activeBar.ZIndex = 5; activeBar.Parent = bFrame
	local macroHint = Instance.new("TextLabel"); macroHint.Size = UDim2.new(1,-10,0,14); macroHint.Position = UDim2.new(0,5,0,8); macroHint.BackgroundTransparency = 1; macroHint.TextColor3 = Color3.fromRGB(100,100,100); macroHint.Font = Enum.Font.Code; macroHint.TextSize = 10; macroHint.TextXAlignment = Enum.TextXAlignment.Left; macroHint.Text = "ID or macro (play x; wait t; stop)"; macroHint.ZIndex = 4; macroHint.Parent = bFrame
	local idL = Instance.new("TextBox"); idL.Size = UDim2.new(1,-10,0,22); idL.Position = UDim2.new(0,5,0,25); idL.Text = bindData.id or ""; idL.PlaceholderText = "id or macro..."
	idL.BackgroundColor3 = Color3.fromRGB(14,14,14); idL.TextColor3 = Color3.fromRGB(210,210,210); idL.Font = Enum.Font.Code; idL.TextSize = 12; idL.ZIndex = 4; idL.Parent = bFrame; mkCorner(idL,3); mkStroke(idL, Color3.fromRGB(42,42,42), 1)
	local keyB = Instance.new("TextButton"); keyB.Size = UDim2.new(1,-10,0,22); keyB.Position = UDim2.new(0,5,0,52)
	keyB.Text = "Key: " .. (bindData.key and bindData.key.Name or "None"); keyB.BackgroundColor3 = Color3.fromRGB(22,38,24); keyB.TextColor3 = Color3.fromRGB(140,210,145); keyB.Font = Enum.Font.Code; keyB.TextSize = 12; keyB.ZIndex = 4; keyB.Parent = bFrame; mkCorner(keyB,3); mkStroke(keyB, Color3.fromRGB(45,80,48), 1)
	local holdT = Instance.new("TextButton"); holdT.Size = UDim2.new(1,-10,0,20); holdT.Position = UDim2.new(0,5,0,78)
	holdT.Text = "Hold: " .. (bindData.hold and "ON" or "OFF"); holdT.BackgroundColor3 = bindData.hold and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); holdT.TextColor3 = bindData.hold and Color3.fromRGB(140,210,145) or Color3.fromRGB(210,210,210); holdT.Font = Enum.Font.Code; holdT.TextSize = 12; holdT.ZIndex = 4; holdT.Parent = bFrame; mkCorner(holdT,3)
	local holdTStroke = Instance.new("UIStroke"); holdTStroke.Color = bindData.hold and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); holdTStroke.Thickness = 1; holdTStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; holdTStroke.Parent = holdT
	local speedB = Instance.new("TextBox"); speedB.Size = UDim2.new(1,-10,0,20); speedB.Position = UDim2.new(0,5,0,103)
	speedB.Text = "Speed: " .. (bindData.speed or 1); speedB.BackgroundColor3 = Color3.fromRGB(14,14,14); speedB.TextColor3 = Color3.fromRGB(210,210,210); speedB.Font = Enum.Font.Code; speedB.TextSize = 12; speedB.ZIndex = 4; speedB.Parent = bFrame; mkCorner(speedB,3); mkStroke(speedB, Color3.fromRGB(42,42,42), 1)
	local loopT = Instance.new("TextButton"); loopT.Size = UDim2.new(1,-10,0,20); loopT.Position = UDim2.new(0,5,0,128)
	loopT.Text = "Loop: " .. (bindData.loop and "ON" or "OFF"); loopT.BackgroundColor3 = bindData.loop and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); loopT.TextColor3 = bindData.loop and Color3.fromRGB(140,210,145) or Color3.fromRGB(210,210,210); loopT.Font = Enum.Font.Code; loopT.TextSize = 12; loopT.ZIndex = 4; loopT.Parent = bFrame; mkCorner(loopT,3)
	local loopTStroke = Instance.new("UIStroke"); loopTStroke.Color = bindData.loop and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); loopTStroke.Thickness = 1; loopTStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; loopTStroke.Parent = loopT
	local lastFiredLabel = Instance.new("TextLabel"); lastFiredLabel.Size = UDim2.new(1,-10,0,14); lastFiredLabel.Position = UDim2.new(0,5,0,153); lastFiredLabel.BackgroundTransparency = 1; lastFiredLabel.TextColor3 = Color3.fromRGB(80,80,80); lastFiredLabel.Font = Enum.Font.Code; lastFiredLabel.TextSize = 10; lastFiredLabel.TextXAlignment = Enum.TextXAlignment.Left; lastFiredLabel.Text = "never fired"; lastFiredLabel.ZIndex = 4; lastFiredLabel.Parent = bFrame
	local del = Instance.new("TextButton"); del.Size = UDim2.new(0,15,0,15); del.Position = UDim2.new(1,-15,0,0); del.Text = "X"; del.BackgroundColor3 = Color3.fromRGB(200,50,50); del.TextColor3 = Color3.fromRGB(255,255,255); del.ZIndex = 5; del.Parent = bFrame; mkCorner(del,3)
	bindData._activeBar = activeBar; bindData._lastFiredLabel = lastFiredLabel
	table.insert(Data.bindIndicators, bindData)
	local settingKey = false
	table.insert(Data.connections, keyB.MouseButton1Click:Connect(function() settingKey = true; keyB.Text = "Press a key..." end))
	table.insert(Data.connections, Services.UserInputService.InputBegan:Connect(function(input)
		if settingKey and input.UserInputType == Enum.UserInputType.Keyboard then
			settingKey = false; bindData.key = input.KeyCode; keyB.Text = "Key: " .. input.KeyCode.Name; dumpBinds()
		end
	end))
	table.insert(Data.connections, idL:GetPropertyChangedSignal("Text"):Connect(function() bindData.id = idL.Text; dumpBinds() end))
	table.insert(Data.connections, holdT.MouseButton1Click:Connect(function()
		bindData.hold = not bindData.hold; holdT.Text = "Hold: " .. (bindData.hold and "ON" or "OFF"); holdT.BackgroundColor3 = bindData.hold and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); holdT.TextColor3 = bindData.hold and Color3.fromRGB(140,210,145) or Color3.fromRGB(210,210,210); holdTStroke.Color = bindData.hold and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); dumpBinds()
	end))
	table.insert(Data.connections, speedB:GetPropertyChangedSignal("Text"):Connect(function()
		bindData.speed = tonumber(speedB.Text:match("[%d%.]+")) or 1; dumpBinds()
	end))
	table.insert(Data.connections, loopT.MouseButton1Click:Connect(function()
		bindData.loop = not bindData.loop; loopT.Text = "Loop: " .. (bindData.loop and "ON" or "OFF"); loopT.BackgroundColor3 = bindData.loop and Color3.fromRGB(22,38,24) or Color3.fromRGB(20,20,20); loopT.TextColor3 = bindData.loop and Color3.fromRGB(140,210,145) or Color3.fromRGB(210,210,210); loopTStroke.Color = bindData.loop and Color3.fromRGB(45,80,48) or Color3.fromRGB(42,42,42); dumpBinds()
	end))
	table.insert(Data.connections, del.MouseButton1Click:Connect(function()
		killAnim(bindData.id)
		for i, v in pairs(Data.keybinds) do if v == bindData then table.remove(Data.keybinds, i); break end end
		bFrame:Destroy(); dumpBinds()
	end))
end
table.insert(Data.connections, UI.addB.MouseButton1Click:Connect(function()
	local nb = {id="",key=nil,hold=false,speed=1,loop=false,active=false,tracks={},token=0}
	table.insert(Data.keybinds, nb); addBind(nb)
end))

local function addFavRow(id, displayName)
	if Data.favoriteEntries[id] then return end
	local fFrame = Instance.new("Frame"); fFrame.Name = "fav_"..id; fFrame.Size = UDim2.new(1,-5,0,25); fFrame.BackgroundTransparency = 1; fFrame.ZIndex = 3; fFrame.Parent = UI.favsList
	local fBtn = Instance.new("TextButton"); fBtn.Size = UDim2.new(1,-95,1,0); fBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); fBtn.TextColor3 = Color3.fromRGB(210,175,60); fBtn.TextXAlignment = Enum.TextXAlignment.Left
	fBtn.Text = "★ " .. id .. " | " .. (displayName or "Unknown"); fBtn.BorderSizePixel = 0; fBtn.Font = Enum.Font.Code; fBtn.TextSize = 12; fBtn.ZIndex = 4; fBtn.Parent = fFrame; mkCorner(fBtn,3)
	local fPreviewBtn = Instance.new("ImageButton"); fPreviewBtn.Size = UDim2.new(0,42,1,0); fPreviewBtn.Position = UDim2.new(1,-95,0,0)
	fPreviewBtn.Image = "rbxassetid://6523858394"; fPreviewBtn.ImageTransparency = 0; fPreviewBtn.BackgroundTransparency = 1; fPreviewBtn.BorderSizePixel = 0; fPreviewBtn.AutoButtonColor = false; fPreviewBtn.ScaleType = Enum.ScaleType.Fit; fPreviewBtn.ImageColor3 = Color3.fromRGB(210,210,210); fPreviewBtn.ZIndex = 4; fPreviewBtn.Parent = fFrame; mkCorner(fPreviewBtn,3)
	local fCopyBtn = Instance.new("TextButton"); fCopyBtn.Size = UDim2.new(0,42,1,0); fCopyBtn.Position = UDim2.new(1,-48,0,0)
	fCopyBtn.Text = "Copy"; fCopyBtn.BackgroundColor3 = Color3.fromRGB(42,42,42); fCopyBtn.TextColor3 = Color3.fromRGB(210,210,210); fCopyBtn.BorderSizePixel = 0; fCopyBtn.Font = Enum.Font.Code; fCopyBtn.TextSize = 11; fCopyBtn.ZIndex = 4; fCopyBtn.Parent = fFrame; mkCorner(fCopyBtn,3)
	local fUnstarBtn = Instance.new("TextButton"); fUnstarBtn.Size = UDim2.new(0,0,1,0); fUnstarBtn.BackgroundTransparency = 1; fUnstarBtn.ZIndex = 1; fUnstarBtn.Text = ""; fUnstarBtn.Parent = fFrame
	Data.favoriteEntries[id] = fFrame
	table.insert(Data.connections, fBtn.MouseButton1Click:Connect(function() UI.idBox.Text = id end))
	table.insert(Data.connections, fPreviewBtn.MouseButton1Click:Connect(function() popPreview(id) end))
	table.insert(Data.connections, fCopyBtn.MouseButton1Click:Connect(function() yoink(id) end))
end
local function killFavRow(id)
	if Data.favoriteEntries[id] then Data.favoriteEntries[id]:Destroy(); Data.favoriteEntries[id] = nil end
end

local function addLogRow(id, name, key, priority)
	key = key or id
	Data.logOrder += 1
	local entryFrame = Instance.new("Frame"); entryFrame.Name = key; entryFrame.Size = UDim2.new(1,-5,0,22); entryFrame.ClipsDescendants = true; entryFrame.BackgroundTransparency = 1; entryFrame.ZIndex = 3; entryFrame.Parent = UI.list
	
	entryFrame.LayoutOrder = Data.favorites[id] and -Data.logOrder or Data.logOrder
	local entry = Instance.new("TextButton"); entry.Size = UDim2.new(1,-142,1,0); entry.BackgroundColor3 = Color3.fromRGB(20,20,20); entry.TextColor3 = Color3.fromRGB(160,160,160); entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.Text = "(1) [" .. (priority or "N/A") .. "] " .. id .. " | " .. name .. " @" .. (Data.animTimestamps[key] or os.date("%H:%M:%S"))
	entry.BorderSizePixel = 0; entry.Font = Enum.Font.Code; entry.TextSize = 12; entry.TextTruncate = Enum.TextTruncate.AtEnd; entry.ZIndex = 4; entry.Visible = true; entry.Parent = entryFrame; mkCorner(entry,3)
	local previewBtn = Instance.new("ImageButton"); previewBtn.Size = UDim2.new(0,20,1,0); previewBtn.Position = UDim2.new(1,-140,0,0)
	previewBtn.Image = "rbxassetid://6523858394"; previewBtn.ImageTransparency = 0; previewBtn.BackgroundTransparency = 1; previewBtn.BorderSizePixel = 0; previewBtn.AutoButtonColor = false; previewBtn.ScaleType = Enum.ScaleType.Fit; previewBtn.ImageColor3 = Color3.fromRGB(210,210,210); previewBtn.ZIndex = 4; previewBtn.Visible = true; previewBtn.Parent = entryFrame; mkCorner(previewBtn,3)
	local favBtn = Instance.new("TextButton"); favBtn.Size = UDim2.new(0,20,1,0); favBtn.Position = UDim2.new(1,-118,0,0)
	favBtn.BackgroundColor3 = Color3.fromRGB(38,38,38); favBtn.TextColor3 = Color3.fromRGB(210,175,60); favBtn.Text = Data.favorites[id] and "★" or "☆"; favBtn.BorderSizePixel = 0; favBtn.Font = Enum.Font.GothamSemibold; favBtn.TextSize = 12; favBtn.ZIndex = 4; favBtn.Visible = true; favBtn.Parent = entryFrame; mkCorner(favBtn,3)
	local nameBtn = Instance.new("TextButton"); nameBtn.Size = UDim2.new(0,46,1,0); nameBtn.Position = UDim2.new(1,-96,0,0)
	nameBtn.BackgroundColor3 = Color3.fromRGB(28,28,28); nameBtn.TextColor3 = Color3.fromRGB(210,210,210); nameBtn.Text = "Name"; nameBtn.BorderSizePixel = 0; nameBtn.Font = Enum.Font.GothamSemibold; nameBtn.TextSize = 10; nameBtn.ZIndex = 4; nameBtn.Visible = true; nameBtn.Parent = entryFrame; mkCorner(nameBtn,3)
	local copyBtn = Instance.new("TextButton"); copyBtn.Size = UDim2.new(0,46,1,0); copyBtn.Position = UDim2.new(1,-48,0,0)
	copyBtn.BackgroundColor3 = Color3.fromRGB(42,42,42); copyBtn.TextColor3 = Color3.fromRGB(210,210,210); copyBtn.Text = "Copy"; copyBtn.BorderSizePixel = 0; copyBtn.Font = Enum.Font.GothamSemibold; copyBtn.TextSize = 10; copyBtn.ZIndex = 4; copyBtn.Visible = true; copyBtn.Parent = entryFrame; mkCorner(copyBtn,3)
	table.insert(Data.connections, entry.MouseButton1Click:Connect(function() UI.idBox.Text = id end))
	table.insert(Data.connections, previewBtn.MouseButton1Click:Connect(function() popPreview(id) end))
	table.insert(Data.connections, favBtn.MouseButton1Click:Connect(function()
		Data.favorites[id] = not Data.favorites[id]; favBtn.Text = Data.favorites[id] and "★" or "☆"
		
		if Data.favorites[id] then
			entryFrame.LayoutOrder = -Data.logOrder
			addFavRow(id, Data.customNames[id] or name)
		else
			entryFrame.LayoutOrder = Data.logOrder
			killFavRow(id)
		end
		dumpCfg()
	end))
	local function refreshEntryText()
		local displayName = Data.customNames[id] or name
		local prefix = Data.loopingAnims[key] and "\xe2\x86\xbb " or ""
		entry.Text = prefix .. "(" .. (Data.animCounts[key] or 1) .. ") [" .. (priority or "N/A") .. "] " .. id .. " | " .. displayName .. " @" .. (Data.animTimestamps[key] or "?")
		nameBtn.Text = Data.customNames[id] and "✎" or "Name"
		nameBtn.BackgroundColor3 = Data.customNames[id] and Color3.fromRGB(25,35,50) or Color3.fromRGB(28,28,28)
		nameBtn.TextColor3 = Data.customNames[id] and Color3.fromRGB(160,160,160) or Color3.new(1,1,1)
	end
	table.insert(Data.connections, nameBtn.MouseButton1Click:Connect(function()
		local nameInput = Instance.new("TextBox"); nameInput.Text = Data.customNames[id] or ""; nameInput.PlaceholderText = "blank = remove name"
		nameInput.Size = UDim2.new(1,-114,1,0); nameInput.Position = UDim2.new(0,0,0,0); nameInput.BackgroundColor3 = Color3.fromRGB(20,20,20)
		nameInput.TextColor3 = Color3.fromRGB(210,210,210); nameInput.PlaceholderColor3 = Color3.fromRGB(65,65,65); nameInput.BorderSizePixel = 1; nameInput.BorderColor3 = Color3.fromRGB(160,160,160)
		nameInput.Font = Enum.Font.Code; nameInput.TextSize = 11; nameInput.ZIndex = 6; nameInput.Parent = entryFrame; nameInput:CaptureFocus()
		local function applyName()
			local newName = nameInput.Text:match("^%s*(.-)%s*$"); nameInput:Destroy()
			if newName ~= "" then Data.customNames[id] = newName else Data.customNames[id] = nil end
			refreshEntryText()
			if Data.favoriteEntries[id] then
				local fBtn2 = Data.favoriteEntries[id]:FindFirstChildOfClass("TextButton")
				if fBtn2 then fBtn2.Text = "★ " .. id .. " | " .. (Data.customNames[id] or name) end
			end
			dumpCfg()
		end
		table.insert(Data.connections, nameInput.FocusLost:Connect(applyName))
	end))
	table.insert(Data.connections, copyBtn.MouseButton1Click:Connect(function() yoink(id) end))
	Data.animFrames[key] = entry
	Data.animFrames[key .. "__frame"] = entryFrame
	local n = 0; for k in pairs(Data.animFrames) do if not k:find("__frame", 1, true) then n += 1 end end
	UI.logCountLabel.Text = n .. " logged"
end

local function fixPriority(raw)
	local PRIORITY_NAMES = {Action="game",Action2="game2",Action3="game3",Action4="game4",Core="coreanims",Idle="idle",Movement="movement"}
	return PRIORITY_NAMES[raw] or raw or "?"
end

local function checkLoopDetect(id, key)
	local isScriptAnim = false
	local animator = grabAnimator()
	if animator then
		for _, t in pairs(animator:GetPlayingAnimationTracks()) do
			if Data.scriptTracks[t] and grabId(t.Animation.AnimationId) == id then isScriptAnim = true; break end
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
				for _, v in ipairs(Data.animFireIntervals[key]) do if math.abs(v - avg) > avg * 0.3 then consistent = false; break end end
				if consistent then
					Data.loopingAnims[key] = true
					local entry = Data.animFrames[key]
					if entry and not entry.Text:find("\xe2\x86\xbb") then entry.Text = "\xe2\x86\xbb " .. entry.Text end
				end
			end
		end
	end
	Data.animLastFired[key] = now
end

local function logIt(id, name, playerName, priority)
	if Data.banned[id] or Data.trueBanned[id] or Data.logBlacklist[id] then return end
	local entryName = name; local key = id
	if playerName then
		key = id .. "_" .. playerName
		if playerName ~= player.Name then entryName = "[" .. playerName .. "] " .. name end
	end
	if Data.customNames[id] then entryName = Data.customNames[id] end
	if State.autoCopy then yoink(id) end
	checkLoopDetect(id, key)
	if not Data.animCounts[key] then
		Data.animCounts[key] = 1; Data.animTimestamps[key] = os.date("%H:%M:%S"); addLogRow(id, entryName, key, priority)
	else
		Data.animCounts[key] += 1; Data.animTimestamps[key] = os.date("%H:%M:%S")
		local entry = Data.animFrames[key]
		if entry then
			local prefix = Data.loopingAnims[key] and "\xe2\x86\xbb " or ""
			entry.Text = prefix .. "(" .. Data.animCounts[key] .. ") [" .. (priority or "N/A") .. "] " .. id .. " | " .. entryName .. " @" .. Data.animTimestamps[key]
		end
		
		local now = tick()
		if not Data.logLastMove[key] or (now - Data.logLastMove[key]) > 0.15 then
			Data.logLastMove[key] = now
			Data.logOrder += 1
			local entryFrame = Data.animFrames[key .. "__frame"]
			if entryFrame and entryFrame.Parent then
				
				if not Data.favorites[id] then
					entryFrame.LayoutOrder = -Data.logOrder 
				end
				
			end
		end
	end
end

refreshColors = function()
	local animator = grabAnimator(); local playingIds = {}
	if animator then for _, track in pairs(animator:GetPlayingAnimationTracks()) do playingIds[grabId(track.Animation.AnimationId)] = true end end
	for id, entry in pairs(Data.animFrames) do
		if id:find("__frame", 1, true) then continue end 
		local pureId = id:match("^([%d]+)")
		if Data.trueBanned[pureId] then entry.TextColor3 = Color3.fromRGB(139,0,0)
		elseif Data.banned[pureId] then entry.TextColor3 = Color3.fromRGB(200,50,50)
		elseif Data.logBlacklist[pureId] then entry.TextColor3 = Color3.fromRGB(150,100,200)
		elseif playingIds[pureId] then entry.TextColor3 = Color3.fromRGB(220,240,255)
		else entry.TextColor3 = Color3.fromRGB(190,190,190) end
	end
end

task.spawn(function()
	while State.running do
		refreshColors()
		for _, bind in pairs(Data.bindIndicators) do
			if bind._activeBar and bind._activeBar.Parent then
				bind._activeBar.BackgroundColor3 = bind.active and Color3.fromRGB(100,190,255) or Color3.fromRGB(35,35,35)
			end
		end
		task.wait(0.1)
	end
end)

local function fireReplacement(id, rep)
	local targetId = rep.targetId; if State.replacementFrozen then return end
	Data.replacingTargets[targetId] = true
	local animator = grabAnimator(); if not animator then return end
	local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. targetId
	local newTrack = animator:LoadAnimation(anim); Data.scriptTracks[newTrack] = true
	newTrack.Priority = Enum.AnimationPriority.Action4; newTrack.Looped = rep.loop or false; newTrack:Play(0,1,rep.speed or 1)
	newTrack.Stopped:Connect(function()
		Data.scriptTracks[newTrack] = nil; Data.replacingTargets[targetId] = nil
		State.replacementFrozen = true; task.delay(0.5, function() State.replacementFrozen = false end)
	end)
end

local advReplActiveThreads = {}

local function fireAdvReplacement(rule, triggerInfo)
	if not rule.enabled then return end
	if tick() - (rule.lastFired or 0) < (rule.cooldown or 0) then return end
	rule.lastFired = tick()


	if rule.conditions then
		for _, cond in ipairs(rule.conditions) do

		end
	end

	local token = {}
	table.insert(advReplActiveThreads, token)
	task.spawn(function()
		local animator = grabAnimator(); if not animator then return end

		for _, action in ipairs(rule.actions or {}) do
			local actionType = action.type
			local param = action.param or ""

			if actionType == "play" then
				local parts = {}
				for p in param:gmatch("[^,]+") do table.insert(parts, p:match("^%s*(.-)%s*$")) end
				local id = grabId(parts[1]) or ""
				local speed = tonumber(parts[2]) or 1
				local loop = parts[3] == "true"
				local priority = parts[4] or "Action4"
				local weight = tonumber(parts[5]) or 1
				local startOffset = tonumber(parts[6]) or 0

				if id ~= "" then
					local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. id
					local track; pcall(function() track = animator:LoadAnimation(anim) end)
					if track then
						local pri = Enum.AnimationPriority[priority] or Enum.AnimationPriority.Action4
						track.Priority = pri; track.Looped = loop
						track:Play(0, weight, speed); Data.scriptTracks[track] = true
						if startOffset > 0 then
							task.defer(function() if track then track.TimePosition = math.clamp(startOffset,0,track.Length) end end)
						end
						track.Stopped:Connect(function() Data.scriptTracks[track] = nil end)
					end
				end

			elseif actionType == "stop" then

				for t in pairs(Data.scriptTracks) do
					if grabId(t.Animation.AnimationId):find(param, 1, true) then
						t:Stop(0); Data.scriptTracks[t] = nil
					end
				end

			elseif actionType == "speed" then
				local parts = {}
				for p in param:gmatch("[^,]+") do table.insert(parts, p:match("^%s*(.-)%s*$")) end
				local pattern = parts[1] or ""
				local newSpeed = tonumber(parts[2]) or 1
				for t in pairs(Data.scriptTracks) do
					if grabId(t.Animation.AnimationId):find(pattern, 1, true) then
						t:AdjustSpeed(newSpeed)
					end
				end

			elseif actionType == "priority" then
				local parts = {}
				for p in param:gmatch("[^,]+") do table.insert(parts, p:match("^%s*(.-)%s*$")) end
				local pattern = parts[1] or ""
				local newPri = Enum.AnimationPriority[parts[2]] or Enum.AnimationPriority.Action4
				for t in pairs(Data.scriptTracks) do
					if grabId(t.Animation.AnimationId):find(pattern, 1, true) then
						t.Priority = newPri
					end
				end

			elseif actionType == "weight" then
				local parts = {}
				for p in param:gmatch("[^,]+") do table.insert(parts, p:match("^%s*(.-)%s*$")) end
				local pattern = parts[1] or ""
				local newWeight = tonumber(parts[2]) or 1
				for t in pairs(Data.scriptTracks) do
					if grabId(t.Animation.AnimationId):find(pattern, 1, true) then
						t:AdjustWeight(newWeight, 0)
					end
				end

			elseif actionType == "fade" then
				local parts = {}
				for p in param:gmatch("[^,]+") do table.insert(parts, p:match("^%s*(.-)%s*$")) end
				local pattern = parts[1] or ""
				local fadeTime = tonumber(parts[2]) or 0.5
				for t in pairs(Data.scriptTracks) do
					if grabId(t.Animation.AnimationId):find(pattern, 1, true) then
						t:AdjustWeight(0, fadeTime)
						task.delay(fadeTime, function() if t then t:Stop(0); Data.scriptTracks[t] = nil end end)
					end
				end

			elseif actionType == "wait" then
				local waitTime = tonumber(param) or 1
				task.wait(waitTime)

			elseif actionType == "macro" then
				if param ~= "" then
					runMacro(param)
				end

			elseif actionType == "var" then

				local parts = {}
				for p in param:gmatch("[^,]+") do table.insert(parts, p:match("^%s*(.-)%s*$")) end
				local op = parts[1]
				local varName = parts[2]
				local value = parts[3]


			elseif actionType == "flash" then
				local parts = {}
				for p in param:gmatch("[^,]+") do table.insert(parts, p:match("^%s*(.-)%s*$")) end
				local msg = parts[1] or "Rule fired!"
				local duration = tonumber(parts[2]) or 5
				local colorArg = (parts[3] or ""):match("^%s*(.-)%s*$")
				local color

				local r, g, b = colorArg:match("^(%d+)[%s,]+(%d+)[%s,]+(%d+)$")
				if r then
					color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
				else
					local colorMap = {
						blue   = Color3.fromRGB(100,150,255),
						red    = Color3.fromRGB(210,130,130),
						green  = Color3.fromRGB(140,210,145),
						yellow = Color3.fromRGB(230,190,120),
						orange = Color3.fromRGB(230,160,80),
						white  = Color3.fromRGB(220,220,220),
						purple = Color3.fromRGB(180,140,220),
					}
					color = colorMap[colorArg:lower()] or colorMap["blue"]
				end
				flashNotif("[rpl] " .. msg, duration, color)
			end
		end


		if rule.chainTo and rule.chainTo ~= "" then
			for _, chainRule in ipairs(Data.advReplacements) do
				if chainRule.name == rule.chainTo and chainRule.enabled and chainRule ~= rule then
					fireAdvReplacement(chainRule, triggerInfo)
					break
				end
			end
		end
	end)
end

local function stopTrack(track)
	track:AdjustWeight(0,0); track:AdjustSpeed(0); track:Stop(0)
end

local function trackSeen(track, playerName)
	local anim = track.Animation; if not anim then return end
	local id = grabId(anim.AnimationId); if not id then return end
	if Data.trueBanned[id] then stopTrack(track); return end
	if Data.banned[id] and playerName == player.Name then stopTrack(track); return end
	if Data.logBlacklist[id] then
		if not Data.seenTracks[track] then
			Data.seenTracks[track] = true
			local conn; conn = track.Stopped:Connect(function() Data.seenTracks[track] = nil; if conn then conn:Disconnect() end end)
		end
		return
	end
	if Data.replacements[id] and playerName == player.Name and not Data.scriptTracks[track] then
		local rep = Data.replacements[id]
		if rep.enabled ~= false then stopTrack(track); Data.seenTracks[track] = true; fireReplacement(id, rep); return end
	end
	if playerName == player.Name and not Data.scriptTracks[track] then
		for _, rule in ipairs(Data.advReplacements) do
			if rule.enabled then
				local triggerMatch = false
				local triggerInfo = {
					animId = id,
					animName = anim.Name or "Unknown",
					player = playerName,
					priority = track.Priority.Name
				}

				for _, trigger in ipairs(rule.triggers or {}) do
					local triggerType = trigger.type
					local param = trigger.param or trigger.value or ""

					if triggerType == "animId" then
						local trigId = grabId(param)
						if trigId and id == trigId then triggerMatch = true; break end
					elseif triggerType == "animName" then
						if (anim.Name or "Unknown"):find(param, 1, true) then triggerMatch = true; break end
					elseif triggerType == "player" then
						if playerName == param then triggerMatch = true; break end
					elseif triggerType == "priority" then
						if track.Priority.Name == param then triggerMatch = true; break end
					elseif triggerType == "anyAnim" then
						triggerMatch = true; break
					end
				end

				if triggerMatch then
					stopTrack(track)
					fireAdvReplacement(rule, triggerInfo)
					Data.seenTracks[track] = true
					return
				end
			end
		end
	end
	if playerName ~= player.Name and not State.globalLogging then return end
	if Data.seenTracks[track] then return end
	Data.seenTracks[track] = true
	State.performance.totalLogs = (State.performance.totalLogs or 0) + 1
	logIt(id, anim.Name or "Unknown", playerName, fixPriority(track.Priority.Name))
	local conn; conn = track.Stopped:Connect(function()
		Data.seenTracks[track] = nil
		if conn then
			for i, v in ipairs(Data.connections) do if v == conn then table.remove(Data.connections, i); break end end
			conn:Disconnect()
		end
	end)
	table.insert(Data.connections, conn)
end

local function suppressCompeting(track)
	track:AdjustWeight(0,0); track:AdjustSpeed(0); track:Stop(0)
	for t in pairs(Data.scriptTracks) do if t.IsPlaying then t:AdjustWeight(1,0) end end
end

local function hookAnimator(animator, playerName)
	if not animator then return end
	table.insert(Data.connections, animator.AnimationPlayed:Connect(function(track)
		if playerName == player.Name then
			local scriptAnimActive = false
			for t in pairs(Data.scriptTracks) do if t.IsPlaying then scriptAnimActive = true; break end end
			if scriptAnimActive and not Data.scriptTracks[track] then suppressCompeting(track); return end
		end
		trackSeen(track, playerName)
	end))
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do trackSeen(track, playerName) end
end

local function onJoin(p)
	table.insert(Data.connections, p.CharacterAdded:Connect(function(char)
		if p == player then
			for _, bind in pairs(Data.keybinds) do bind.active = false end
			for k in pairs(Data.scriptTracks) do Data.scriptTracks[k] = nil end
		end
		task.wait(1); hookAnimator(grabAnimator(char), p.Name)
	end))
	if p.Character then hookAnimator(grabAnimator(p.Character), p.Name) end
end
table.insert(Data.connections, Services.Players.PlayerAdded:Connect(onJoin))
for _, p in pairs(Services.Players:GetPlayers()) do onJoin(p) end

task.spawn(function()
	while State.running do
		for _, bind in pairs(Data.keybinds) do
			if not bind.active then continue end
			local idStr = tostring(bind.id)
			local isMacroB = isMacro(idStr)
			local isCmdB = isCmd(idStr)
			if isCmdB then continue end 

			if isMacroB then
				
				if bind.hold and (not bind.macroFlag or not bind.macroFlag.active) then
					bind.macroFlag = {active=true}; doMacro(idStr, bind, bind.macroFlag)
				end
				
				if not bind.hold and (not bind.macroFlag or not bind.macroFlag.active) then
					bind.macroFlag = {active=true}; doMacro(idStr, bind, bind.macroFlag)
				end
			else
				
				if bind.hold and not Data.banned[bind.id] then
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
					if not isPlaying then fireAnim(bind.id, bind.speed, bind.loop) end
				end
				
				if not bind.hold and bind.loop and not Data.banned[bind.id] then
					local isPlaying = false
					local animator = grabAnimator()
					if animator then
						for _, t in pairs(animator:GetPlayingAnimationTracks()) do
							if grabId(t.Animation.AnimationId) == bind.id and t.IsPlaying then isPlaying = true; break end
						end
					end
					if not isPlaying then fireAnim(bind.id, bind.speed, bind.loop) end
				end
			end
		end
		task.wait()
	end
end)

local function doCmd(cmd, isRelease)
	local parts = cmd:lower():split(" "); local action = parts[1]
	if action == "pause" or action == "freeze" then
		State.isFrozen = isRelease and false or (not State.isFrozen)
		for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(State.isFrozen and 0 or 1) end end
	elseif action == "speed" and not isRelease then
		local num = tonumber(parts[2]); if num then for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(num) end end end
	elseif action == "ban" and not isRelease then
		local id = parts[2]; if id then Data.banned[id] = true; killAnim(id); dumpCfg() end
	elseif action == "unban" and not isRelease then
		local id = parts[2]; if id then Data.banned[id] = nil; dumpCfg() end
	elseif action == "stop" and not isRelease then
		local id = parts[2]; if id then killAnim(id) end
	elseif action == "step" and not isRelease then
		local num = tonumber(parts[2]) or 0.1
		for track in pairs(Data.scriptTracks) do if track.IsPlaying then track.TimePosition = math.clamp(track.TimePosition + num, 0, track.Length) end end
	elseif action == "loop" and not isRelease then
		State.looped = not State.looped; refreshLoopBtn(); dumpCfg()
	elseif action == "clear" and not isRelease then
		nukeList()
	elseif action == "global" and not isRelease then
		State.globalLogging = not State.globalLogging; refreshGlobalBtn(); dumpCfg()
	elseif action == "autocopy" and not isRelease then
		State.autoCopy = not State.autoCopy; refreshAutoCopyBtn(); dumpCfg()
	elseif action == "priority" and not isRelease then
		local pri = parts[2]; if pri then
			local priEnum = Enum.AnimationPriority[pri]
			if priEnum then for track in pairs(Data.scriptTracks) do track.Priority = priEnum end end
		end
	elseif action == "weight" and not isRelease then
		local w = tonumber(parts[2]); if w then for track in pairs(Data.scriptTracks) do track:AdjustWeight(w, 0.1) end end
	elseif action == "fade" and not isRelease then
		local t = tonumber(parts[2]) or 0.5; for track in pairs(Data.scriptTracks) do track:AdjustWeight(0, t); task.wait(t); track:Stop() end
	elseif action == "reverse" and not isRelease then
		for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(track.Speed * -1) end end
	elseif action == "scrub" and not isRelease then
		local pos = tonumber(parts[2]); if pos then for track in pairs(Data.scriptTracks) do if track.IsPlaying then track.TimePosition = math.clamp(pos, 0, track.Length) end end end
	elseif action == "length" and not isRelease then
		local len = tonumber(parts[2]); if len then for track in pairs(Data.scriptTracks) do if track.IsPlaying then track.Length = len end end end
	elseif action == "export" and not isRelease then
		local out = {}
		for key, entry in pairs(Data.animFrames) do
			if key:find("__frame", 1, true) then continue end
			local pureId = key:match("^([%d]+)")
			table.insert(out, {id=pureId, key=key, name=entry.Text, count=Data.animCounts[key] or 1,
				lastSeen=Data.animTimestamps[key] or "?", favorited=Data.favorites[pureId] or false, customName=Data.customNames[pureId] or nil})
		end
		local json = Services.HttpService:JSONEncode(out)
		if writefile then
			writefile("bacon_logger_export.json", json)
			flashNotif("Exported to file", 2, Color3.fromRGB(140,210,145))
		else
			yoink(json)
			flashNotif("Copied to clipboard", 2, Color3.fromRGB(140,210,145))
		end
	elseif action == "import" and not isRelease then
		if readfile and isfile and isfile("bacon_logger_import.json") then
			local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile("bacon_logger_import.json")) end)
			if ok and type(data) == "table" then
				for _, entry in ipairs(data) do
					if entry.favorited then Data.favorites[entry.id] = true end
					if entry.customName then Data.customNames[entry.id] = entry.customName end
				end
				dumpCfg()
				flashNotif("Imported successfully", 2, Color3.fromRGB(140,210,145))
			else
				flashNotif("Import failed", 2, Color3.fromRGB(210,130,130))
			end
		else
			flashNotif("No import file found", 2, Color3.fromRGB(210,130,130))
		end
	end
end

local function isMacro(str) return str:find(";") ~= nil or str:lower():match("^play%s") ~= nil or str:lower():match("^ramp%s") ~= nil or str:lower():match("^var%s") ~= nil or str:lower():match("^repeat%s") ~= nil end
local function doMacro(macroStr, bindData, stopFlag)
	task.spawn(function()
		local steps = macroStr:split(";")
		local variables = {}
		local ramping = {}
		for _, step in ipairs(steps) do
			if not stopFlag.active then break end
			step = step:match("^%s*(.-)%s*$"); if step == "" then continue end
			local parts = step:split(" "); local cmd = parts[1]:lower()
			if cmd == "play" then
				local id = parts[2]; local spd = tonumber(parts[3]) or bindData.speed or 1; local lp = (parts[4] == "true") or bindData.loop or false
				if id and id ~= "" then fireAnim(id, spd, lp) end
			elseif cmd == "wait" then
				local t = tonumber(parts[2]) or 0.5; local elapsed = 0
				while elapsed < t and stopFlag.active do task.wait(0.05); elapsed = elapsed + 0.05 end
			elseif cmd == "stop" then
				local id = parts[2]
				if id and id ~= "" then killAnim(id)
				else
					for track in pairs(Data.scriptTracks) do pcall(function() track:Stop() end) end
					for k in pairs(Data.scriptTracks) do Data.scriptTracks[k] = nil end
				end
			elseif cmd == "speed" then
				local num = tonumber(parts[2]); if num then for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(num) end end end
			elseif cmd == "ramp" then
				local startSpeed = tonumber(parts[2]) or 1; local endSpeed = tonumber(parts[3]) or 1; local duration = tonumber(parts[4]) or 1
				local startTime = tick()
				local initialSpeeds = {}
				for track in pairs(Data.scriptTracks) do if track.IsPlaying then initialSpeeds[track] = track.Speed end end
				while tick() - startTime < duration and stopFlag.active do
					local t = (tick() - startTime) / duration
					local currentSpeed = startSpeed + (endSpeed - startSpeed) * t
					for track, initial in pairs(initialSpeeds) do
						if track.IsPlaying then track:AdjustSpeed(currentSpeed) end
					end
					task.wait(0.05)
				end
			elseif cmd == "loop" then State.looped = not State.looped; refreshLoopBtn()
			elseif cmd == "freeze" or cmd == "pause" then
				State.isFrozen = not State.isFrozen
				for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(State.isFrozen and 0 or 1) end end
			elseif cmd == "priority" then
				local pri = parts[2]; if pri then
					local priEnum = Enum.AnimationPriority[pri]
					if priEnum then for track in pairs(Data.scriptTracks) do track.Priority = priEnum end end
				end
			elseif cmd == "weight" then
				local w = tonumber(parts[2]); if w then for track in pairs(Data.scriptTracks) do track:AdjustWeight(w, 0.1) end end
			elseif cmd == "fade" then
				local t = tonumber(parts[2]) or 0.5; for track in pairs(Data.scriptTracks) do track:AdjustWeight(0, t); task.wait(t); track:Stop() end
			elseif cmd == "reverse" then
				for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(track.Speed * -1) end end
			elseif cmd == "scrub" then
				local pos = tonumber(parts[2]); if pos then for track in pairs(Data.scriptTracks) do if track.IsPlaying then track.TimePosition = math.clamp(pos, 0, track.Length) end end end
			elseif cmd == "step" then
				local num = tonumber(parts[2]) or 0.1
				for track in pairs(Data.scriptTracks) do if track.IsPlaying then track.TimePosition = math.clamp(track.TimePosition + num, 0, track.Length) end end
			elseif cmd == "length" then
				local len = tonumber(parts[2]); if len then for track in pairs(Data.scriptTracks) do if track.IsPlaying then track.Length = len end end end
			elseif cmd == "var" then
				local name = parts[2]; local value = tonumber(parts[3]); if name and value then variables[name] = value end
			elseif cmd == "add" then
				local name = parts[2]; local amount = tonumber(parts[3]); if name and amount and variables[name] then variables[name] = variables[name] + amount end
			elseif cmd == "mul" then
				local name = parts[2]; local factor = tonumber(parts[3]); if name and factor and variables[name] then variables[name] = variables[name] * factor end
			elseif cmd == "use" then
				local name = parts[2]; if name and variables[name] then
					local value = variables[name]
					for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(value) end end
				end
			elseif cmd == "if" then
				local var = parts[2]; local op = parts[3]; local val = tonumber(parts[4])
				if var and op and val and variables[var] then
					local condition = false
					if op == ">" then condition = variables[var] > val
					elseif op == "<" then condition = variables[var] < val
					elseif op == "=" or op == "==" then condition = variables[var] == val
					elseif op == "!=" then condition = variables[var] ~= val
					elseif op == ">=" then condition = variables[var] >= val
					elseif op == "<=" then condition = variables[var] <= val
					end
					if not condition then continue end
				end
			elseif cmd == "goto" then
				local label = parts[2]; if label then
					local found = false
					for i, s in ipairs(steps) do
						if s:match("^%s*label%s+" .. label .. "%s*$") then
							steps = {table.unpack(steps, i)}
							found = true
							break
						end
					end
					if not found then continue end
				end
			elseif cmd == "label" then
			elseif cmd == "repeat" then
				local count = tonumber(parts[2]) or 1; local subSteps = {}
				local i = 2
				while i <= #steps do
					local nextStep = steps[i]:match("^%s*(.-)%s*$")
					if nextStep:lower() == "endrepeat" then break end
					table.insert(subSteps, steps[i])
					i = i + 1
				end
				for rep = 1, count do
					if not stopFlag.active then break end
					for _, subStep in ipairs(subSteps) do
						if not stopFlag.active then break end
						local subParts = subStep:split(" "); local subCmd = subParts[1]:lower()
						if subCmd == "play" then
							local id = subParts[2]; local spd = tonumber(subParts[3]) or bindData.speed or 1; local lp = (subParts[4] == "true") or bindData.loop or false
							if id and id ~= "" then fireAnim(id, spd, lp) end
						elseif subCmd == "wait" then
							local t = tonumber(subParts[2]) or 0.5; local elapsed = 0
							while elapsed < t and stopFlag.active do task.wait(0.05); elapsed = elapsed + 0.05 end
						elseif subCmd == "stop" then
							local id = subParts[2]
							if id and id ~= "" then killAnim(id)
							else
								for track in pairs(Data.scriptTracks) do pcall(function() track:Stop() end) end
								for k in pairs(Data.scriptTracks) do Data.scriptTracks[k] = nil end
							end
						end
					end
				end
			elseif cmd == "endrepeat" then
			elseif cmd == "random" then
				local min = tonumber(parts[2]) or 0; local max = tonumber(parts[3]) or 1
				local value = min + math.random() * (max - min)
				for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(value) end end
			elseif cmd == "sin" then
				local freq = tonumber(parts[2]) or 1; local amp = tonumber(parts[3]) or 1; local offset = tonumber(parts[4]) or 0; local duration = tonumber(parts[5]) or 1
				local startTime = tick()
				while tick() - startTime < duration and stopFlag.active do
					local t = tick() - startTime
					local value = math.sin(t * freq * 2 * math.pi) * amp + offset
					for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(value) end end
					task.wait(0.05)
				end
			elseif cmd == "cos" then
				local freq = tonumber(parts[2]) or 1; local amp = tonumber(parts[3]) or 1; local offset = tonumber(parts[4]) or 0; local duration = tonumber(parts[5]) or 1
				local startTime = tick()
				while tick() - startTime < duration and stopFlag.active do
					local t = tick() - startTime
					local value = math.cos(t * freq * 2 * math.pi) * amp + offset
					for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(value) end end
					task.wait(0.05)
				end
			elseif cmd == "lerp" then
				local start = tonumber(parts[2]) or 1; local end_ = tonumber(parts[3]) or 1; local duration = tonumber(parts[4]) or 1
				local startTime = tick()
				while tick() - startTime < duration and stopFlag.active do
					local t = (tick() - startTime) / duration
					local value = start + (end_ - start) * t
					for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(value) end end
					task.wait(0.05)
				end
			end
		end
		stopFlag.active = false
	end)
end

local function isCmd(str)
	local COMMAND_PREFIXES = {"pause","freeze","speed","ban","unban","stop","step","loop","clear","global","autocopy","priority","weight","fade","reverse","scrub","length","export","import"}
	local low = str:lower()
	for _, c in pairs(COMMAND_PREFIXES) do if low:match("^" .. c) then return true end end
	return false
end

local function runQuickCommand(raw)
	local cmd = tostring(raw or ""):match("^%s*(.-)%s*$")
	if cmd == "" then return end
	if cmd:sub(1,1) == "/" then cmd = cmd:sub(2) end
	local low = cmd:lower()
	if low == "capture" then
		captureCurrentTrack()
		return
	end
	if isCmd(cmd) then
		doCmd(cmd, false)
		flashNotif("Ran command: " .. cmd, 1.6, nil, "success")
		return
	end
	if isMacro(cmd) then
		local tempBind = {speed = tonumber(UI.speedBox.Text) or 1, loop = State.looped}
		doMacro(cmd, tempBind, {active = true})
		flashNotif("Macro started", 1.6, nil, "success")
		return
	end
	local numeric = grabId(cmd)
	if numeric then
		UI.idBox.Text = numeric
		flashNotif("Set ID box to " .. numeric, 1.6, nil, "info")
		return
	end
	flashNotif("Unknown quick command", 2, nil, "warn")
end

table.insert(Data.connections, UI.commandPaletteBtn.MouseButton1Click:Connect(function()
	UI.commandPalette.Visible = not UI.commandPalette.Visible
end))
table.insert(Data.connections, UI.commandRunBtn.MouseButton1Click:Connect(function()
	runQuickCommand(UI.commandBar.Text)
end))
table.insert(Data.connections, UI.commandBar.FocusLost:Connect(function(enterPressed)
	if enterPressed then runQuickCommand(UI.commandBar.Text) end
end))
for _, child in ipairs(UI.commandPalette:GetChildren()) do
	if child:IsA("TextButton") then
		table.insert(Data.connections, child.MouseButton1Click:Connect(function()
			UI.commandBar.Text = child.Name
			runQuickCommand(child.Name)
			UI.commandPalette.Visible = false
		end))
	end
end

table.insert(Data.connections, Services.UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for _, bind in pairs(Data.keybinds) do
		if bind.key and input.KeyCode == bind.key then
			local idStr = tostring(bind.id); local timeStr = os.date("%H:%M:%S"); bind._lastFired = timeStr
			if bind._lastFiredLabel and bind._lastFiredLabel.Parent then
				bind._lastFiredLabel.Text = "fired: " .. timeStr; bind._lastFiredLabel.TextColor3 = Color3.fromRGB(160,160,160)
			end
			if isMacro(idStr) then
				if not bind.macroFlag or not bind.macroFlag.active then bind.macroFlag = {active=true}; doMacro(idStr, bind, bind.macroFlag) end
			elseif isCmd(idStr) then
				if bind.hold then
					local low = idStr:lower()
					if low:match("^pause") or low:match("^freeze") then
						State.isFrozen = true; for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(0) end end
					else doCmd(idStr, false) end
				else doCmd(idStr, false) end
			else
				if bind.hold then
					bind.active = true; fireAnim(bind.id, bind.speed, bind.loop)
				else
					bind.active = not bind.active
					if not bind.active then killAnim(bind.id)
					else
						local t = fireAnim(bind.id, bind.speed, bind.loop)
						if not bind.loop and t then t.Stopped:Connect(function() bind.active = false end) end
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
				
				if bind.hold then
					if bind.macroFlag then bind.macroFlag.active = false; bind.macroFlag = nil end
					bind.active = false
					
					for t in pairs(Data.scriptTracks) do Data.scriptTracks[t] = nil; pcall(function() t:Stop(0) end) end
				end
			elseif isCmd(idStr) then
				if bind.hold then
					local low = idStr:lower()
					if low:match("^pause") or low:match("^freeze") then
						State.isFrozen = false; for track in pairs(Data.scriptTracks) do if track.IsPlaying then track:AdjustSpeed(1) end end
					end
				end
			else
				if bind.hold then
					bind.active = false; bind.token = (bind.token or 0) + 1
					for t in pairs(Data.scriptTracks) do
						if grabId(t.Animation.AnimationId) == bind.id then Data.scriptTracks[t] = nil; pcall(function() t:Stop(0) end) end
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
				local nb = {id=b.id, key=b.key and Enum.KeyCode[b.key] or nil, hold=b.hold or false, speed=b.speed or 1, loop=b.loop or false, active=false, tracks={}, token=0}
				table.insert(Data.keybinds, nb); addBind(nb)
			end
		end
	end
end

local function loadCfg()
	if readfile and isfile and isfile(State.configFile) then
		local ok, data = pcall(function() return Services.HttpService:JSONDecode(readfile(State.configFile)) end)
		if ok and type(data) == "table" then
			State.looped = data.looped or false; State.globalLogging = data.globalLogging or false; State.autoCopy = data.autoCopy or false
			Data.banned = data.banned or {}; Data.trueBanned = data.trueBanned or {}; Data.logBlacklist = data.logBlacklist or {}
			if data.toggleKey and Enum.KeyCode[data.toggleKey] then State.toggleKey = Enum.KeyCode[data.toggleKey] end
			Data.replacements = data.replacements or {}; Data.favorites = data.favorites or {}; Data.customNames = data.customNames or {}
			if data.advReplacements then
				Data.advReplacements = data.advReplacements
				for _, rule in ipairs(Data.advReplacements) do addAdvReplUI(rule) end
			end
			refreshLoopBtn(); refreshGlobalBtn(); refreshAutoCopyBtn()
			for id, rep in pairs(Data.replacements) do addReplUI(id, rep.targetId, rep.speed, rep.loop, rep.enabled ~= false) end
			for id, isFav in pairs(Data.favorites) do if isFav then addFavRow(id, Data.customNames[id] or id) end end
		end
	end
end
loadCfg()
UI.toggleKeyBtn.Text = "Hide Key: " .. State.toggleKey.Name
loadSavedBinds(); loadGroups()

local function tickLoop()
	for _, p in pairs(Services.Players:GetPlayers()) do
		local isLocal = (p == player); local animator = grabAnimator(p.Character)
		if animator then
			local scriptAnimActive = false
			if isLocal then for t in pairs(Data.scriptTracks) do if t.IsPlaying then scriptAnimActive = true; break end end end
			for _, track in pairs(animator:GetPlayingAnimationTracks()) do
				local tid = grabId(track.Animation.AnimationId)
				if tid and Data.trueBanned[tid] then
					track:AdjustWeight(0,0); track:AdjustSpeed(0); track:Stop(0); continue
				end
				if tid and Data.banned[tid] and isLocal then
					track:AdjustWeight(0,0); track:AdjustSpeed(0); track:Stop(0); continue
				end
				if isLocal and tid and Data.replacements[tid] and Data.replacements[tid].enabled ~= false and (Data.replacingTargets[Data.replacements[tid].targetId] or State.replacementFrozen) then
					track:AdjustWeight(0,0); track:AdjustSpeed(0); track:Stop(0); continue
				end
				if isLocal and scriptAnimActive and not Data.scriptTracks[track] then
					track:AdjustWeight(0,0); track:AdjustSpeed(0); track:Stop(0)
				elseif State.globalLogging or isLocal then
					trackSeen(track, p.Name)
				end
			end
		end
	end
end
table.insert(Data.connections, Services.RunService.Stepped:Connect(tickLoop))
local function migrateAdvReplacements()
	for _, rule in ipairs(Data.advReplacements) do

		if rule.layers and not rule.triggers then
			rule.triggers = {}
			rule.actions = {}
			rule.variables = rule.variables or {}
			rule.conditions = rule.conditions or {}
			rule.cooldown = rule.cooldown or 0
			rule.lastFired = rule.lastFired or 0

			if rule.triggerAnimId then
				table.insert(rule.triggers, {type = "animId", param = rule.triggerAnimId})
			elseif rule.triggerAnimName then
				table.insert(rule.triggers, {type = "animName", param = rule.triggerAnimName})
			else
				table.insert(rule.triggers, {type = "anyAnim", param = ""})
			end


			for _, layer in ipairs(rule.layers) do
				local action = {
					type = "play",
					param = string.format("%s,%s,%s,%s,%s,%s",
						layer.id or "",
						layer.speed or 1,
						layer.loop and "true" or "false",
						layer.priority or "Action4",
						layer.weight or 1,
						layer.startOffset or 0
					)
				}
				table.insert(rule.actions, action)
			end

			if rule.chainToId then
				rule.chainTo = rule.chainToId
			end


			rule.layers = nil
			rule.triggerAnimId = nil
			rule.triggerAnimName = nil
			rule.triggerPriority = nil
			rule.triggerDelay = nil
			rule.chainToId = nil
		end
	end


	if not State.advancedFilters then
		State.advancedFilters = {
			enabled = false,
			currentPreset = "Default",
			presets = {
				["Default"] = {
					name = "Default",
					filters = {
						{type = "search", param = State.filterPlayer or "", enabled = true},
						{type = "player", param = State.filterPlayer or "", enabled = true},
						{type = "priority", param = State.filterPriority or "", enabled = true}
					},
					logic = "AND"
				}
			},
			activeFilters = {
				{type = "search", param = State.filterPlayer or "", enabled = true},
				{type = "player", param = State.filterPlayer or "", enabled = true},
				{type = "priority", param = State.filterPriority or "", enabled = true}
			},
			logic = "AND"
		}
	end
end

table.insert(Data.connections, Services.RunService.RenderStepped:Connect(tickLoop))

migrateAdvReplacements()
if dumpCfg then dumpCfg() end
print("baconlogger finished loading, enjoy the script dude,")
-- soooo tuff 67 phonk sigma trollface trollge cool sonion fart
