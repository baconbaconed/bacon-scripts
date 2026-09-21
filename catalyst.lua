--[[ i hate catalyst so much it give me pain in butt
like 64 modes? idk prob
best fling ever trust 
i love catalylyst
if you ever say catalylyst bad ill use sniper on your home 
benjamin netanyahu: wow catalyst is so good we are funding it 293 million taxpayer dollars from the united states and tel aviv!
bacon: wow thank you benjamin netanyahu you are so kind indeed
+293592 israel tel aviv respect points 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ]]



do
    local ok = false
    if type(sethiddenproperty) == "function" then
        local lp = game:GetService("Players").LocalPlayer
        ok = pcall(sethiddenproperty,
            lp, "SimulationRadius", math.huge)
    end
    if not ok then return end
end
pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(0) end)
pcall(function() settings().Physics.AllowSleep = false end)
pcall(function() workspace.StreamingEnabled = false end)
workspace.FallenPartsDestroyHeight = 0/0 -- PLEASE remove this if you deem necessary, i added this solely so your parts dont instantly get fucking obliterated by the void when u try flinging someone
pcall(function()
    for _, o in ipairs(workspace:GetChildren()) do
        if o.Name == "CatalystDeathFloor" then o:Destroy() end
    end
end)

local Players          = game:GetService("Players") -- local player = die.true
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local CoreGui          = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse  = LP:GetMouse() -- me <3 this guy

do
    local isMobile = false
    pcall(function()
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
            isMobile = true
        end
        local plat = UserInputService:GetPlatform()
        if plat == Enum.Platform.IOS or plat == Enum.Platform.Android then
            isMobile = true
        end
    end)
    if isMobile then
       -- pcall(function() LP:Kick("Catalyst is not built for mobile, and never will be, i apologize") end)
       -- return
    end
end

-- keybinds were a pain, dont touch pls
local keybindSettingButton = nil
local buttonKeybinds = setmetatable({}, {__mode = "k"})
local buttonOriginalAppearance = setmetatable({}, {__mode = "k"}) 
local savedKeybinds = {}
local KEYBIND_SETTING_COLOR = Color3.fromRGB(255, 255, 0)
local function resetButtonAppearance(button)
    if buttonKeybinds[button] then
        buttonKeybinds[button].conn:Disconnect()
        buttonKeybinds[button] = nil
    end
    local orig = buttonOriginalAppearance[button]
    if orig then
        button.BackgroundColor3 = orig.bg
        button.TextColor3 = orig.textColor
        button.Text = orig.text
        buttonOriginalAppearance[button] = nil
    else
        local currentText = button.Text
        local clean = string.gsub(currentText, "%s*%[.-%]", "")
        clean = clean:match("^%s*(.-)%s*$")
        button.Text = clean
    end
end
local function resetButtonAppearanceKeepKeybind(button)
    local orig = buttonOriginalAppearance[button]
    if orig then
        button.BackgroundColor3 = orig.bg
        button.TextColor3 = orig.textColor
        buttonOriginalAppearance[button] = nil
    end
end

local function updateAllButtonKeybindTexts()
    if _G.modeButtons then
        for name, mb in pairs(_G.modeButtons) do
            if buttonKeybinds[mb] and buttonKeybinds[mb].originalText then
                local keyName = buttonKeybinds[mb].key.Name
                local originalText = buttonKeybinds[mb].originalText
                mb.Text = originalText .. " [" .. keyName .. "]"
            end
        end
    end
    local guiParents = {}
    if UI and UI.ScreenGui then table.insert(guiParents, UI.ScreenGui) end
    if ScreenGui then table.insert(guiParents, ScreenGui) end
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then table.insert(guiParents, hui) end
    end
    
    for _, guiParent in ipairs(guiParents) do
        for _, btn in ipairs(guiParent:GetDescendants()) do
            if btn:IsA("TextButton") and buttonKeybinds[btn] and buttonKeybinds[btn].originalText then
                local keyName = buttonKeybinds[btn].key.Name
                local originalText = buttonKeybinds[btn].originalText
                btn.Text = originalText .. " [" .. keyName .. "]"
            end
        end
    end
end
local function startKeybindSetting(button)
    if keybindSettingButton == button then
        keybindSettingButton = nil
        if buttonKeybinds[button] then
            buttonKeybinds[button].conn:Disconnect()
            buttonKeybinds[button] = nil
        end
        resetButtonAppearance(button)
        return
    end
    if keybindSettingButton then
        resetButtonAppearance(keybindSettingButton)
    end
    keybindSettingButton = button
    if not buttonOriginalAppearance[button] then
        local cleanText = button.Text
        cleanText = string.gsub(cleanText, "%s*%[.-%]", "")
        cleanText = cleanText:match("^%s*(.-)%s*$")
        buttonOriginalAppearance[button] = {
            bg = button.BackgroundColor3,
            textColor = button.TextColor3,
            text = cleanText
        }
    end
    button.BackgroundColor3 = KEYBIND_SETTING_COLOR
    button.TextColor3 = Color3.fromRGB(0,0,0)
    button.Text = "Press a key..."
end

local function hasClickDetector(part)
    if not (part and typeof(part) == "Instance" and part:IsA("BasePart")) then return false end
    local found = false
    pcall(function()
        if part:FindFirstChildOfClass("ClickDetector") ~= nil then found = true end
    end)
    if not found then
        pcall(function()
            if part:FindFirstChild("ClickDetector", true) ~= nil then found = true end
        end)
    end
    return found
end
local function fixCanQueryForRaycast()
    local function processPart(part)
        if not part:IsA("BasePart") then return end
        if part.Name == "HLProxy" then
            pcall(function() part.CanQuery = false end) -- this annoys me
            return
        end
        local proxModel = part:FindFirstAncestorOfClass("Model")
        if proxModel and proxModel.Name == "CatalystSelectionProxy" then
            pcall(function() part.CanQuery = false end)
            return
        end
        if hasClickDetector(part) then
            pcall(function() part.CanQuery = true end)
            return
        end
        local char = part:FindFirstAncestorOfClass("Model")
        if char then
            local player = Players:GetPlayerFromCharacter(char)
            if player then
                return
            end
        end
        if part.Anchored then
            if part.Transparency > 0.80 then
                pcall(function() part.CanQuery = false end)
            else
                pcall(function() part.CanQuery = true end)
            end
            if not part:GetAttribute("_cat_canquery_hooked") then
                part:SetAttribute("_cat_canquery_hooked", true)
                part:GetPropertyChangedSignal("Transparency"):Connect(function()
                    if hasClickDetector(part) then
                        pcall(function() part.CanQuery = true end)
                        return
                    end
                    if part.Transparency > 0.80 then
                        pcall(function() part.CanQuery = false end)
                    else
                        pcall(function() part.CanQuery = true end)
                    end
                end)
            end
            return
        end
        if not part.Anchored and part.AssemblyMass ~= math.huge then
            if part.Transparency > 0.80 then
                pcall(function() part.CanQuery = false end)
            else
                pcall(function() part.CanQuery = true end)
            end
            if not part:GetAttribute("_cat_canquery_hooked") then
                part:SetAttribute("_cat_canquery_hooked", true)
                part:GetPropertyChangedSignal("Transparency"):Connect(function()
                    if hasClickDetector(part) then
                        pcall(function() part.CanQuery = true end)
                        return
                    end
                    if part.Transparency > 0.80 then
                        pcall(function() part.CanQuery = false end)
                    else
                        pcall(function() part.CanQuery = true end)
                    end
                end)
            end
            return
        end
        if part.AssemblyMass == math.huge then
            if part.Transparency <= 0.80 then
                pcall(function() part.CanQuery = true end)
            else
                pcall(function() part.CanQuery = false end)
            end
            return
        end

        pcall(function() part.CanQuery = true end)
        if part.Transparency > 0.80 then
            pcall(function() part.CanQuery = false end)
        end

        if not part:GetAttribute("_cat_canquery_hooked") then
            part:SetAttribute("_cat_canquery_hooked", true)
            part:GetPropertyChangedSignal("Transparency"):Connect(function()
                if hasClickDetector(part) then
                    pcall(function() part.CanQuery = true end)
                    return
                end
                if part.Transparency > 0.80 then
                    pcall(function() part.CanQuery = false end)
                else
                    pcall(function() part.CanQuery = true end)
                end
            end)
        end
    end
    for _, part in ipairs(workspace:GetDescendants()) do
        processPart(part)
    end
    if not _G._catDescendantDispatcher then
        _G._catDescendantDispatcher = true
        workspace.DescendantAdded:Connect(function(d)
            if d:IsA("ClickDetector") then
                pcall(function()
                    local par = d.Parent
                    if par and par:IsA("BasePart") then par.CanQuery = true end
                end)
            end
            processPart(d)
            if d:IsA("BasePart") then
                task.defer(function()
                    pcall(sethiddenproperty, d, "NetworkIsSleeping", false)
                end)
            end
        end)
    end
end

fixCanQueryForRaycast()
task.defer(function()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == "HLProxy" or (d.Parent and d.Parent.Name == "CatalystSelectionProxy") then
            pcall(function() d.CanQuery = false end)
        elseif d:IsA("BasePart") and d.Anchored and d.Transparency > 0.80 and d.CanQuery and not hasClickDetector(d) then
            pcall(function() d.CanQuery = false end)
        end
    end
end)
if not _G._hlProxyFix then
    _G._hlProxyFix = true
    task.spawn(function()
        while true do
            task.wait(0.15)
            if selectionProxyModel then
                for _, pr in pairs(selectionProxyParts) do
                    if typeof(pr) == "Instance" and pr.CanQuery then pcall(function() pr.CanQuery = false end) end
                end
            end
        end
    end)
    function runCanQuerySweep()
        if #selectedParts == 0 then return end
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local center = (hrp and hrp.Position) or (Camera and Camera.CFrame.Position)
        if not center then return end
        local ok, parts = pcall(function()
            return workspace:GetPartBoundsInBox(CFrame.new(center), Vector3.new(200, 200, 200))
        end)
        if not (ok and type(parts) == "table") then return end
        for _, d in ipairs(parts) do
            if hasClickDetector(d) then
                if not d.CanQuery then pcall(function() d.CanQuery = true end) end
            elseif d.Anchored and d.Transparency > 0.80 and d.CanQuery then
                local skip = false
                pcall(function()
                    local m = d:FindFirstAncestorOfClass("Model")
                    if m and (m == LP.Character or Players:GetPlayerFromCharacter(m)) then skip = true end
                end)
                if not skip then pcall(function() d.CanQuery = false end) end
            end
        end
    end
    task.spawn(function()
        while true do
            task.wait(10)
            pcall(runCanQuerySweep)
        end
    end)
end

if not _G._networkAwakeFix then
    _G._networkAwakeFix = true
    task.spawn(function()
        while true do
            task.wait(0.08)
            for _, part in ipairs(selectedParts) do
                if part and part.Parent and not part.Anchored then
                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                end
            end
            for part in pairs(frozenTargets) do
                if part and part.Parent and not part.Anchored then
                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                end
            end
            for part in pairs(assemblyExtras) do
                if part and part.Parent and not part.Anchored then
                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                end
            end
        end
    end)
end

if not _G._assemblyRootHammer then
    _G._assemblyRootHammer = true
    task.spawn(function()
        while true do
            task.wait(0.1)
            do
                for _, part in ipairs(selectedParts) do
                    if part and part.Parent and not part.Anchored then
                        local root = getAssemblyRoot(part)
                        if root ~= part and root.Parent and not root.Anchored then
                            pcall(sethiddenproperty, root, "NetworkIsSleeping", false)
                            local ownedR = false
                            pcall(function() ownedR = ownedCached(root) end)
                            if not ownedR then
                                pcall(function()
                                    local ov = root.AssemblyLinearVelocity
                                    root.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                                    root.AssemblyLinearVelocity = ov
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

if not _G._assemblyExtrasHammer then
    _G._assemblyExtrasHammer = true
    task.spawn(function()
        while true do
            task.wait(0.1)
            if assemblyDirtyAt ~= 0 and tick() - assemblyDirtyAt > 0.5 then
                assemblyDirtyAt = 0
                pcall(rebuildAssemblyCache, true)
            end
            pcall(updateSelfCollision)
            do
                for part in pairs(assemblyExtras) do
                    if part and part.Parent and not part.Anchored then
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                    end
                end
            end
        end
    end)
end

if not _G._catSeatRelease then
    _G._catSeatRelease = true
    task.spawn(function()
        while true do
            task.wait(1)
            if #selectedParts > 0 and not frozen then
                for _, s in ipairs(selectedParts) do
                    if s and s.Parent and not s.Anchored then
                        local busy = false
                        local ok, mates = pcall(function() return s:GetConnectedParts(true) end)
                        if ok and type(mates) == "table" then
                            local n = 0
                            for _, m in ipairs(mates) do
                                n += 1
                                if n > 120 then break end
                                if m and m.Parent and (m:IsA("Seat") or m:IsA("VehicleSeat")) then
                                    local occ = nil
                                    pcall(function() occ = m.Occupant end)
                                    if occ and occ.Parent then
                                        local ours = false
                                        pcall(function() ours = occ.Parent == LP.Character end)
                                        if not ours then
                                            busy = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if busy then
                            seatPin[s] = s.Position
                            pcall(function() frozenTargets[s] = s.Position end)
                            if tick() - (occupantToastAt or 0) > 3 then
                                occupantToastAt = tick()
                                toast("occupied - holding position")
                            end
                        elseif seatPin[s] then
                            local pin = seatPin[s]
                            seatPin[s] = nil
                            if frozenTargets[s] == pin then
                                frozenTargets[s] = nil
                            end
                        end
                    elseif seatPin[s] then
                        seatPin[s] = nil
                    end
                end
            end
        end
    end)
end

if not _G._ownershipWatchdog then
    _G._ownershipWatchdog = true
    task.spawn(function()
        local acc = 0
        RunService.Heartbeat:Connect(function(dt)
            acc += dt
            if acc < 0.1 then return end
            acc = 0
            if #selectedParts == 0 then return end
            local seen = {}
            for _, part in ipairs(selectedParts) do
                if part and part.Parent and not part.Anchored then
                    pcall(reclaimAssembly, part)
                    local root = getAssemblyRoot(part)
                    if root and root ~= part and root.Parent and not root.Anchored and not seen[root] then
                        seen[root] = true
                        reclaimAssembly(root)
                    elseif root == part then
                        seen[root] = true
                    end
                end
            end
        end)
    end)
end
_catJitterSign = _catJitterSign or {}
_catJitterAt = _catJitterAt or {}
_G._catGen = ((_G._catGen or 0) + 1)

if not _G._catSimLoop then
    _G._catSimLoop = true
    local myGen = _G._catGen
    task.spawn(function()
        while true do
            task.wait(0.1)
            if myGen ~= _G._catGen then return end
            pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
            pcall(function()
                if type(setsimulationradius) == "function" then
                    setsimulationradius(math.huge)
                end
            end)
            pcall(function()
                if workspace.StreamingEnabled then
                    workspace.StreamingEnabled = false
                end
            end)
        end
    end)
end
if _G._catSteppedRetainConn then
    pcall(function() _G._catSteppedRetainConn:Disconnect() end)
    _G._catSteppedRetainConn = nil
end
do
    _G._catSteppedRetain = true
    _G._catSteppedRetainConn = RunService.Stepped:Connect(function()
        pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
        if #selectedParts == 0 then return end
        for _, part in ipairs(selectedParts) do
            if part and part.Parent and not part.Anchored then
                pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                local ownedS = false
                pcall(function() ownedS = ownedCached(part) end)
                if not ownedS then
                    pcall(function()
                        local ov = part.AssemblyLinearVelocity
                        part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                        part.AssemblyLinearVelocity = ov
                        local oa = part.AssemblyAngularVelocity
                        part.AssemblyAngularVelocity = Vector3.new(500, 500, 500)
                        part.AssemblyAngularVelocity = oa
                    end)
                end
                pcall(function()
                    local now = tick()
                    if now - (_catJitterAt[part] or 0) > 0.2 then
                        _catJitterAt[part] = now
                        _catJitterSign[part] = not _catJitterSign[part]
                        local ageJ = nil
                        pcall(function()
                            if type(gethiddenproperty) == "function" then
                                ageJ = gethiddenproperty(part, "ReceiveAge")
                            end
                        end)
                        if ageJ == nil then
                            pcall(function() ageJ = part.ReceiveAge end)
                        end
                        if ageJ == 0 then
                            local d = _catJitterSign[part] and 0.02 or -0.02
                            local cf = part.CFrame
                            part.CFrame = cf + Vector3.new(0, d, 0)
                            part.CFrame = cf
                        end
                    end
                end)
                pcall(function()
                    local bv = part:FindFirstChild("OwnershipBV")
                    if bv and bv:IsA("BodyVelocity") then
                        local hasAP = false
                        pcall(function()
                            local att = part:FindFirstChild("NetAttach")
                            hasAP = att and att:FindFirstChild("NetAP") ~= nil
                        end)
                        if hasAP then
                            bv.MaxForce = Vector3.zero
                            bv.Enabled = false
                        else
                            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                            if type(netHoldVelocity) == "function" then
                                bv.Velocity = netHoldVelocity()
                            end
                        end
                    end
                    local bg = part:FindFirstChild("OwnershipBG")
                    if bg and bg:IsA("BodyGyro") then
                        local aoOn = true
                        local tgtRot = nil
                        local hasAO = false
                        pcall(function()
                            local att = part:FindFirstChild("NetAttach")
                            local ao = att and att:FindFirstChild("NetAO")
                            hasAO = ao ~= nil
                            if ao and ao:IsA("AlignOrientation") then aoOn = ao.Enabled end
                        end)
                        pcall(function()
                            local t = partTargets and partTargets[part]
                            if t then tgtRot = t.rotation end
                        end)
                        if hasAO then
                            bg.MaxTorque = Vector3.zero
                            bg.Enabled = false
                        else
                            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                            if tgtRot then bg.CFrame = tgtRot end
                            local dragging = rotDrag and rotDrag.active and rotDrag.part == part
                            bg.Enabled = (not dragging) and aoOn
                        end
                    end
                end)
            end
        end
    end)
end

if not _G._catHumanoidKeep then
    _G._catHumanoidKeep = true
    local myGen = _G._catGen
    task.spawn(function()
        while true do
            task.wait(1)
            if myGen ~= _G._catGen then return end
            pcall(function()
                local ch = LP.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local st = hum:GetState()
                    if st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.RunningNoPhysics or st == Enum.HumanoidStateType.Idle then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
            end)
        end
    end)
end


networkPaused = nil
pcall(function() networkPaused:Disconnect() end)
networkPaused = CoreGui.RobloxGui.ChildAdded:Connect(function(obj)
    if obj.Name == "CoreScripts/NetworkPause" then
        obj:Destroy()
    end
end)
pcall(function() CoreGui.RobloxGui["CoreScripts/NetworkPause"]:Destroy() end)

local GUI = {
    DISPLAY_ORDER = 50,
    ESP_ORDER     = 49,
    ESP_ACCENT    = Color3.fromRGB(225, 80, 85),
    Z             = 64,
}

local HL = {
    fillColor           = Color3.fromRGB(225, 80, 85),
    outlineColor        = Color3.fromRGB(225, 80, 85),
    fillTransparency    = 0.65,
    outlineTransparency = 0,
    depthMode           = Enum.HighlightDepthMode.AlwaysOnTop,
}

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return CoreGui
end

local function stampGui(obj, z)
    if obj:IsA("GuiObject") then
        obj.ZIndex = math.max(obj.ZIndex, z or GUI.Z)
    end
end


connections   = {}
pcall(function()
    local prev = _G._catalystConns
    _G._catalystConns = nil
    if type(prev) == "table" then
        for _, c in pairs(prev) do
            pcall(function() if c then c:Disconnect() end end)
        end
    end
    local gp = nil
    pcall(function() gp = getGuiParent() end)
    local cores = {CoreGui}
    if gp and gp ~= CoreGui then table.insert(cores, gp) end
    for _, parent in ipairs(cores) do
        pcall(function()
            for _, o in ipairs(parent:GetChildren()) do
                if o.Name == "Catalyst" or o.Name == "CatalystESP" or o.Name == "CatalystText" then
                    pcall(function() o:Destroy() end)
                end
            end
        end)
    end
end)
selectedParts = {}
partMissingSince = {}
partTrulyGone = {}
partDestroyingConns = {}
partSpinSaved = {}
partOffsets   = {}
partOffsetScale = {}
unfreezeFrom = {}
unfreezeBoostStart = {}
ownCheckAt = {}
densityRampGen = densityRampGen or {}
stabLastVel = Vector3.zero
stabLastAng = Vector3.zero
stabInit = false
reholdToastAt = {}
flightStuck = {}
flightTgt = {}
reholdCount = {}
holdLoud = {}
ownLogAt = {}
fallSuspect = {}
seatPin = {}
highlights    = {}
npcHighlights = {}
spcHighlight  = nil
selectionProxyModel     = nil
selectionProxyHighlight = nil
selectionProxyParts     = {}
partPhysProperties      = {}


EspScreenGui = Instance.new("ScreenGui")
EspScreenGui.Name             = "CatalystESP"
EspScreenGui.ResetOnSpawn     = false
EspScreenGui.IgnoreGuiInset   = true
EspScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
EspScreenGui.DisplayOrder     = GUI.ESP_ORDER
EspScreenGui.Parent           = getGuiParent()

TextScreenGui = Instance.new("ScreenGui")
TextScreenGui.Name             = "CatalystText"
TextScreenGui.ResetOnSpawn     = false
TextScreenGui.IgnoreGuiInset   = true
TextScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
TextScreenGui.DisplayOrder     = 100
TextScreenGui.Parent           = getGuiParent()

do
    local bar = Instance.new("Frame")
    bar.Name = "TextBar"
    bar.Size = UDim2.new(0, 400, 0, 28)
    bar.Position = UDim2.new(0.5, -200, 0, 4)
    bar.BackgroundColor3 = Color3.fromRGB(12, 8, 14)
    bar.BackgroundTransparency = 0.15
    bar.BorderSizePixel = 0
    bar.ZIndex = 110
    bar.Visible = false
    bar.Parent = TextScreenGui
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", bar)
    stroke.Color = Color3.fromRGB(62, 38, 66)
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    local tb = Instance.new("TextBox")
    tb.Name = "TextInput"
    tb.Size = UDim2.new(1, -12, 1, -6)
    tb.Position = UDim2.new(0, 6, 0, 3)
    tb.BackgroundTransparency = 1
    tb.Text = (textContent ~= nil and textContent or "CATALYST")
    tb.PlaceholderText = "TYPE TEXT (A-Z 0-9) ..."
    tb.PlaceholderColor3 = Color3.fromRGB(152, 106, 138)
    tb.TextColor3 = Color3.fromRGB(242, 212, 228)
    tb.TextSize = 14
    tb.Font = Enum.Font.GothamBold
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    tb.ZIndex = 111
    tb.Parent = bar
    textGui = bar
    textBox = tb
    tb:GetPropertyChangedSignal("Text"):Connect(function()
        local t = tb.Text or ""
        t = string.upper(t)
        t = t:gsub("[^%-A-Z0-9 !?+=]", "")
        if tb.Text ~= t then tb.Text = t end
        textContent = t
    end)
end

local function reg(c) table.insert(connections,c); return c end

-- i ate a huge garlic bread
activeMode   = "Tornado"
allowedTouchModes = { ["DroneV2"] = true, ["Drone"] = true }
partSpeed    = 50
maxVelocity  = math.huge
formRadius   = 7
formSizeX    = 10
formSizeY    = 3
formSizeZ    = 10
formOffsetY  = 0
formRotX     = 0
formRotY     = 0
formRotZ     = 0
formScale    = 1.0
wallDist     = 7
wallGap      = 0.1
flingForce   = 1500 -- flingforce = 1 binillion * inf
flingRange   = 300
tornadoSpeed = 8
spiralHeight = 14
waveAmp      = 3
orbitRadius  = 9
autoSelRange = 60
autoSelectAll        = false
autoSelectNear       = false
autoSelectLastScan   = 0
AUTO_SELECT_INTERVAL = 5
strengthenParts      = false
strengthenDensity    = 100
unfreezeT0 = {}
frozen          = false
frozenTargets   = {}
unfreezeBoost     = {}
riderNCCs = {}
partRideRad = {}
reclaimTouchAt = {}
riderShieldAt = {}
anchoredNoted = {}
anchorToastAt = 0
rotDrag           = { active=false, part=nil, yaw=0, pitch=0, roll=0, highlight=nil, savedMouse=nil, savedCamRot=nil, savedCamOff=nil, savedCamType=nil, savedCamSubject=nil, selBox=nil, savedProxyLook=nil }
dragGhost = dragGhost or {}
function ghostAssemblyForDrag(part)
    pcall(function()
        dragGhost = dragGhost or {}
        if not (part and part.Parent and part:IsA("BasePart")) then return end
        local root0 = part
        pcall(function()
            local rr = getAssemblyRoot(part)
            if rr and rr.Parent then root0 = rr end
        end)
        local seenG = {}
        local function ghostOne(m)
            if not (m and m.Parent and m:IsA("BasePart")) then return end
            if seenG[m] then return end
            seenG[m] = true
            if dragGhost[m] ~= nil then return end
            local rec = {}
            local need = false
            local cur = nil
            pcall(function() cur = m.CanCollide end)
            if cur then
                local sv = true
                pcall(function() sv = (m.CanCollide ~= false) end)
                rec.c = sv
                if partCollisionState[m] == nil then
                    partCollisionState[m] = sv
                end
                pcall(function() m.CanCollide = false end)
                need = true
            end
            if m ~= root0 then
                local mv = nil
                pcall(function() mv = m.Massless end)
                if mv == false then
                    rec.m = false
                    pcall(function() m.Massless = true end)
                    need = true
                end
            end
            if need then dragGhost[m] = rec end
        end
        ghostOne(part)
        ghostOne(root0)
        local okM, mates = pcall(function() return root0:GetConnectedParts(true) end)
        if okM and type(mates) == "table" then
            for _, m in ipairs(mates) do ghostOne(m) end
        end
    end)
end
function restoreDragGhost()
    pcall(function()
        if not dragGhost then return end
        for m, rec in pairs(dragGhost) do
            dragGhost[m] = nil
            pcall(function()
                if m and m.Parent and m:IsA("BasePart") then
                    if type(rec) == "table" then
                        if rec.c ~= nil then m.CanCollide = rec.c end
                        if rec.m ~= nil then m.Massless = rec.m end
                    elseif rec ~= nil then
                        m.CanCollide = true
                    end
                end
            end)
        end
    end)
end

local function rotLockFlag()
    if type(getgenv) == "function" then
        local ok, g = pcall(getgenv)
        if ok and type(g) == "table" then return g._catRotMouseLocked == true end
    end
    return _G._catRotMouseLocked == true
end
local function setRotLockFlag(v)
    if type(getgenv) == "function" then
        local ok, g = pcall(getgenv)
        if ok and type(g) == "table" then g._catRotMouseLocked = v and true or nil return end
    end
    _G._catRotMouseLocked = v and true or nil
end
local function healRotLock()
    pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
    pcall(function() RunService:UnbindFromRenderStep("CatalystRotCam") end)
    pcall(function()
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then Camera.CameraSubject = h end
        end
    end)
    setRotLockFlag(nil)
end

local function endRotDrag()
    pcall(restoreDragGhost)
    if rotDrag.highlight then pcall(function() rotDrag.highlight:Destroy() end) end
    rotDrag.highlight = nil
    if rotDrag.selBox then pcall(function() rotDrag.selBox:Destroy() end) end
    rotDrag.selBox = nil
    if rotDrag.savedProxyLook ~= nil then
        local pp = rotDrag.part and selectionProxyParts[rotDrag.part]
        if pp and pp.Parent then
            pcall(function()
                pp.Color = rotDrag.savedProxyLook.c
                pp.Material = rotDrag.savedProxyLook.m
                pp.Transparency = rotDrag.savedProxyLook.t
            end)
        end
    end
    rotDrag.savedProxyLook = nil
    local sm = rotDrag.savedMouse
    if sm == Enum.MouseBehavior.LockCenter or sm == Enum.MouseBehavior.LockCurrentPosition then
        sm = Enum.MouseBehavior.Default
    end
    if sm ~= nil then
        pcall(function() UserInputService.MouseBehavior = sm end)
    end
    rotDrag.savedMouse = nil
    pcall(function() RunService:UnbindFromRenderStep("CatalystRotCam") end)
    rotDrag.savedCamRot = nil
    rotDrag.savedCamOff = nil
    if rotDrag.savedCamType ~= nil or rotDrag.savedCamSubject ~= nil then
        pcall(function()
            if rotDrag.savedCamSubject ~= nil then Camera.CameraSubject = rotDrag.savedCamSubject end
            if rotDrag.savedCamType ~= nil then Camera.CameraType = rotDrag.savedCamType end
        end)
    end
    rotDrag.savedCamType = nil
    rotDrag.savedCamSubject = nil
    rotDrag.part = nil
    rotDrag.yaw = 0
    rotDrag.pitch = 0
    rotDrag.roll = 0
    rotDrag.wantRot = nil
    rotDrag.active = false
    setRotLockFlag(nil)
end

local function beginRotDrag(part)
    endRotDrag()
    rotDrag.active = true
    rotDrag.part = part
    rotDrag.wantRot = nil
    pcall(function() rotDrag.savedMouse = UserInputService.MouseBehavior end)
    pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end)
    setRotLockFlag(true)
    pcall(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local cf = Camera.CFrame
        rotDrag.savedCamRot = cf - cf.Position
        rotDrag.savedCamOff = hrp and (cf.Position - hrp.Position) or nil
        rotDrag.savedCamSubject = Camera.CameraSubject
        rotDrag.savedCamType = Camera.CameraType
    end)
    pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)
    pcall(function() RunService:UnbindFromRenderStep("CatalystRotCam") end)
    pcall(function()
        RunService:BindToRenderStep("CatalystRotCam", Enum.RenderPriority.Camera.Value + 1, function()
            if rotDrag.active and rotDrag.savedCamRot and rotDrag.savedCamOff then
                pcall(function()
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        Camera.CFrame = CFrame.new(hrp.Position + rotDrag.savedCamOff) * rotDrag.savedCamRot
                    end
                end)
            end
        end)
    end)
    local sb = Instance.new("SelectionBox")
    sb.Name = "CatalystRotDragBox"
    sb.Adornee = part
    sb.Color3 = Color3.fromRGB(0, 0, 0)
    sb.LineThickness = 0.05
    sb.SurfaceColor3 = Color3.fromRGB(0, 0, 0)
    sb.SurfaceTransparency = 1
    sb.Parent = getGuiParent()
    rotDrag.selBox = sb
    local pp = selectionProxyParts[part]
    if pp and pp.Parent then
        pcall(function()
            rotDrag.savedProxyLook = { c = pp.Color, m = pp.Material, t = pp.Transparency }
        end)
        pcall(function()
            pp.Material = Enum.Material.Neon
            pp.Transparency = 0
        end)
    end
    pcall(ghostAssemblyForDrag, part)
end

if rotLockFlag() then
    healRotLock()
end
clickSelActive  = false
boxSelectOn   = false
boxDragging   = false
boxStart      = Vector2.zero
boxCur        = Vector2.zero
boxOverlay    = nil
attracting      = false
attractTimer    = 0
fakeCollisions  = false
collisionMode   = "full"

partTargets = {}
minigunIdx       = 1
minigunShotStart = 0
minigunLastIdx   = 0
MINIGUN_STUCK    = 12
minigunRate      = 7
minigunSpread    = 2
minigunFlying    = {}
minigunFlyTgt    = {}
minigunFlyFrom   = {}
minigunFlyT0     = {}
minigunTouchConns = {}
minigunCursor    = 0
minigunAcc       = 0
minigunLastT     = 0
MINIGUN_FLY      = 0.22
MINIGUN_TIMEOUT  = 2.0
satFired           = {}
satTarget          = Vector3.zero
SAT_TTL            = 3.0
satTouchConns      = {}
barrageTouchConns  = {}
barrageBurst = {}
railgunTouchConns  = railgunTouchConns or {}
railgunHitRegistered = railgunHitRegistered or false
railgunHitTarget   = railgunHitTarget or nil
lightningFired      = {}
lightningTarget     = Vector3.zero
lightningFireTime   = 0
lightningBolt       = {}
lightningBoomed     = false
LIGHTNING_TRAVEL    = 0.35
LIGHTNING_HOLD      = 1.1
lightningTouchConns = {}
railgunBoomed       = false
strikeState      = "idle"
strikeTarget     = Vector3.zero
strikeStart      = 0
strikePulse      = 0
strikeDampUntil  = 0
strikeTouchConns = strikeTouchConns or {}
STRIKE_H         = 32
STRIKE_DESCEND   = 0.38
STRIKE_DRILL     = 2.2
STRIKE_RETURN    = 0.85
sniperFireTime   = 0
sniperTargetPos  = Vector3.zero
sniperTouchConns = {}
sniperBoomStage  = 0
sniperCaught     = false
sniperDampUntil  = 0 
SNIPER_CYCLE     = 1.5
SNIPER_R         = 5
blackholeTouchConns = blackholeTouchConns or {}
blackholePullT      = 0
blackholeSurgeUntil = 0
BH_PULL_EVERY       = 0.12
bridgeA          = nil
bridgeB          = nil
bridgeSlots      = {}
boomerangActive  = false
boomerangStart   = 0
boomerangOrigin  = Vector3.zero
boomerangTarget  = Vector3.zero
BOOMERANG_T      = 1.45
boomerangConns   = {}
stickWalkPhase   = 0
stickLastT       = nil
stickLastPos     = nil
stickSpeed       = 0
stickVelSmooth   = Vector3.zero
stickArmIsLeft   = true
stickGrabActive  = false
stickTPose       = false
stickSlapUntil   = 0
stickSlapConns   = {}
stickBeamActive    = false
stickBeamConns     = {}
stickMagnetActive = false
stickMagnetTick   = 0
stickWaveUntil   = 0
stickDanceActive = false
stickCrawlActive = false
stickFaceMode    = 0
stickFaceSet     = {}
stickFaceCount   = 10
networkRuleApplied = {}
stickBlinkUntil  = 0
stickNextBlink   = 0
lastAnchoredVelAudit = 0
anchoredAuditRadius  = 55
anchoredAuditInterval= 2.8
stickLastOrigin  = nil
stickLastOT      = nil
stickLastPosWalk = 0

if textContent == nil then textContent = "CATALYST" end

scytheState = "idle"
scytheStart = 0
scythePulse = 0
SCYTHE_SWING = 1.2
scytheConns = {}
scytheCenter = Vector3.zero
scytheSwingPos = Vector3.zero
chainedTarget = Vector3.zero
chainedFireTime = 0
CHAINED_TTL = 1.5
chainedFired = {}
chainedConns = {}
chainedActive = false

-- TEXT STUFF, IGNORE, DO NOT TICKLE OR TOUCH, THANKS
TEXT_FONT = {
    ["A"]={" XXX ","X   X","X   X","XXXXX","X   X","X   X","X   X"},
    ["B"]={"XXXX ","X   X","X   X","XXXX ","X   X","X   X","XXXX "},
    ["C"]={" XXX ","X    ","X    ","X    ","X    ","X    "," XXX "},
    ["D"]={"XXXX ","X   X","X   X","X   X","X   X","X   X","XXXX "},
    ["E"]={"XXXXX","X    ","X    ","XXXX ","X    ","X    ","XXXXX"},
    ["F"]={"XXXXX","X    ","X    ","XXXX ","X    ","X    ","X    "},
    ["G"]={" XXX ","X   X","X    ","X XXX","X   X","X   X"," XXX "},
    ["H"]={"X   X","X   X","X   X","XXXXX","X   X","X   X","X   X"},
    ["I"]={"XXXXX","  X  ","  X  ","  X  ","  X  ","  X  ","XXXXX"},
    ["J"]={"XXXXX","    X","    X","    X","X   X","X   X"," XXX "},
    ["K"]={"X   X","X  X ","X X  ","XX   ","X X  ","X  X ","X   X"},
    ["L"]={"X    ","X    ","X    ","X    ","X    ","X    ","XXXXX"},
    ["M"]={"X   X","XX XX","X X X","X   X","X   X","X   X","X   X"},
    ["N"]={"X   X","XX  X","X X X","X X X","X  XX","X   X","X   X"},
    ["O"]={" XXX ","X   X","X   X","X   X","X   X","X   X"," XXX "},
    ["P"]={"XXXX ","X   X","X   X","XXXX ","X    ","X    ","X    "},
    ["Q"]={" XXX ","X   X","X   X","X   X","X X X","X  X "," XX X"},
    ["R"]={"XXXX ","X   X","X   X","XXXX ","X X  ","X  X ","X   X"},
    ["S"]={" XXX ","X   X","X    "," XXX ","    X","X   X"," XXX "},
    ["T"]={"XXXXX","  X  ","  X  ","  X  ","  X  ","  X  ","  X  "},
    ["U"]={"X   X","X   X","X   X","X   X","X   X","X   X"," XXX "},
    ["V"]={"X   X","X   X","X   X","X   X"," X X "," X X ","  X  "},
    ["W"]={"X   X","X   X","X   X","X X X","X X X","XX XX","X   X"},
    ["X"]={"X   X"," X X ","  X  ","  X  ","  X  "," X X ","X   X"},
    ["Y"]={"X   X"," X X ","  X  ","  X  ","  X  ","  X  ","  X  "},
    ["Z"]={"XXXXX","    X","   X ","  X  "," X   ","X    ","XXXXX"},
    ["0"]={" XXX ","X   X","X  XX","X X X","XX  X","X   X"," XXX "},
    ["1"]={"  X  "," XX  ","  X  ","  X  ","  X  ","  X  ","XXXXX"},
    ["2"]={" XXX ","X   X","    X","  XX "," X   ","X    ","XXXXX"},
    ["3"]={"XXXXX","    X","   X ","  XX ","    X","X   X"," XXX "},
    ["4"]={"   X ","  XX "," X X ","X  X ","XXXXX","   X ","   X "},
    ["5"]={"XXXXX","X    ","XXXX ","    X","    X","X   X"," XXX "},
    ["6"]={" XXX ","X   X","X    ","XXXX ","X   X","X   X"," XXX "},
    ["7"]={"XXXXX","    X","   X ","  X  "," X   "," X   "," X   "},
    ["8"]={" XXX ","X   X","X   X"," XXX ","X   X","X   X"," XXX "},
    ["9"]={" XXX ","X   X","X   X"," XXXX","    X","X   X"," XXX "},
    [" "]={"     ","     ","     ","     ","     ","     ","     "},
    ["!"]={"  X  ","  X  ","  X  ","  X  ","     ","  X  ","     "},
    ["?"]={" XXX ","X   X","    X","  XX ","  X  ","     ","  X  "},
    ["+"]={"     ","  X  ","  X  ","XXXXX","  X  ","  X  ","     "},
    ["-"]={"     ","     ","     ","XXXXX","     ","     ","     "},
    ["="]={"     ","     ","XXXXX","     ","XXXXX","     ","     "},
}
TEXT_LETTER_W = 5
TEXT_LETTER_H = 7
TEXT_PIXEL_GAP = 0.1
TEXT_LETTER_SPACING = 2.2
TEXT_SPACE_EXTRA = 4.2
TEXT_PIXEL_SIZE = 1.0
textCachedPoints = nil
textCachedString = ""

local function getTextPixelPoints(txt)
    txt = string.upper(txt or "")
    local points = {}
    local cursorX = 0
    for i=1, #txt do
        local ch = txt:sub(i,i)
        local glyph = TEXT_FONT[ch]
        if not glyph then glyph = TEXT_FONT[" "] end
        if ch == " " then
            cursorX = cursorX + TEXT_LETTER_W + TEXT_SPACE_EXTRA
        else
            for row=1, TEXT_LETTER_H do
                local line = glyph[row]
                for col=1, TEXT_LETTER_W do
                    local c = line:sub(col,col)
                    if c=="X" then
                        local px = cursorX + (col-1)*(TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP)
                        local py = (TEXT_LETTER_H-row)*(TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP)
                        table.insert(points, Vector2.new(px, py))
                    end
                end
            end
            cursorX = cursorX + TEXT_LETTER_W*(TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP) + TEXT_LETTER_SPACING
        end
    end
    local minX, maxX = math.huge, -math.huge
    for _,p in ipairs(points) do
        if p.X < minX then minX=p.X end
        if p.X > maxX then maxX=p.X end
    end
    if #points>0 then
        local cx = (minX+maxX)*0.5
        for i,p in ipairs(points) do
            points[i] = Vector2.new(p.X - cx, p.Y)
        end
    end
    return points, cursorX
end
local textAvgCache = 1
local textAvgCacheCount = 0
local function getAvgPartSize()
    local total = #selectedParts
    if total == 0 then return 1 end
    if textAvgCacheCount == total then return textAvgCache end
    local sum = 0
    local cnt = 0
    for _,p in ipairs(selectedParts) do
        if p and p.Parent then
            local s = p.Size
            local m = math.max(s.X, s.Y, s.Z)
            sum = sum + m
            cnt = cnt + 1
        end
    end
    if cnt == 0 then return 1 end
    local avg = sum / cnt
    avg = math.clamp(avg, 0.8, 12)
    textAvgCache = avg
    textAvgCacheCount = total
    return avg
end
local textPointsDataCache = nil
local textPointsDataCacheStr = nil
local textAssignment = {}
local textPartAngles = {}
local textAssignmentCacheCount = 0
local textAssignmentCacheStr = nil
local function getPixelAngle(glyph, col, row)
    local hasLeft = col>1 and glyph[row]:sub(col-1,col-1)=="X"
    local hasRight = col<5 and glyph[row]:sub(col+1,col+1)=="X"
    local hasUp = row>1 and glyph[row-1]:sub(col,col)=="X"
    local hasDown = row<7 and glyph[row+1]:sub(col,col)=="X"
    local hasUpLeft = row>1 and col>1 and glyph[row-1]:sub(col-1,col-1)=="X"
    local hasUpRight = row>1 and col<5 and glyph[row-1]:sub(col+1,col+1)=="X"
    local hasDownLeft = row<7 and col>1 and glyph[row+1]:sub(col-1,col-1)=="X"
    local hasDownRight = row<7 and col<5 and glyph[row+1]:sub(col+1,col+1)=="X"
    if (hasLeft or hasRight) and not (hasUp or hasDown) then
        return 0
    elseif (hasUp or hasDown) and not (hasLeft or hasRight) then
        return 90
    elseif not (hasLeft or hasRight or hasUp or hasDown) and (hasUpLeft or hasDownRight or hasUpRight or hasDownLeft) then
        local backslash = (hasUpLeft and 1 or 0) + (hasDownRight and 1 or 0)
        local slash = (hasUpRight and 1 or 0) + (hasDownLeft and 1 or 0)
        if backslash > 0 and slash > 0 then return 0 end
        if backslash > 0 then return 45 end
        return 135
    elseif (hasLeft or hasRight) and (hasUp or hasDown) then
        local h = (hasLeft and 1 or 0) + (hasRight and 1 or 0)
        local v = (hasUp and 1 or 0) + (hasDown and 1 or 0)
        if v > h then return 90 else return 0 end
    else
        local backslash = (hasUpLeft and 1 or 0) + (hasDownRight and 1 or 0)
        local slash = (hasUpRight and 1 or 0) + (hasDownLeft and 1 or 0)
        if backslash > 0 and slash > 0 then return 0 end
        if backslash > 0 then return 45 end
        if slash > 0 then return 135 end
        return 0
    end
end
local function getPixelRunLen(glyph, col, row)
    local h=1; local c=col-1; while c>=1 and glyph[row]:sub(c,c)=="X" do h=h+1; c=c-1 end; c=col+1; while c<=5 and glyph[row]:sub(c,c)=="X" do h=h+1; c=c+1 end
    local v=1; local r=row-1; while r>=1 and glyph[r]:sub(col,col)=="X" do v=v+1; r=r-1 end; r=row+1; while r<=7 and glyph[r]:sub(col,col)=="X" do v=v+1; r=r+1 end
    local d1=1; c=col-1; r=row-1; while c>=1 and r>=1 and glyph[r]:sub(c,c)=="X" do d1=d1+1; c=c-1; r=r-1 end; c=col+1; r=row+1; while c<=5 and r<=7 and glyph[r]:sub(c,c)=="X" do d1=d1+1; c=c+1; r=r+1 end
    local d2=1; c=col+1; r=row-1; while c<=5 and r>=1 and glyph[r]:sub(c,c)=="X" do d2=d2+1; c=c+1; r=r-1 end; c=col-1; r=row+1; while c>=1 and r<=7 and glyph[r]:sub(c,c)=="X" do d2=d2+1; c=c-1; r=r+1 end
    return math.max(h, v, d1, d2)
end
local function buildTextPointsData(txt)
    txt = string.upper(txt or "")
    local points = {}
    local cursorX = 0
    for li=1, #txt do
        local ch = txt:sub(li,li)
        local glyph = TEXT_FONT[ch]
        if not glyph then glyph = TEXT_FONT[" "] end
        if ch == " " then
            cursorX = cursorX + TEXT_LETTER_W + TEXT_SPACE_EXTRA
        else
            for row=1, TEXT_LETTER_H do
                local line = glyph[row]
                for col=1, TEXT_LETTER_W do
                    if line:sub(col,col)=="X" then
                        local px = cursorX + (col-1)*(TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP)
                        local py = (TEXT_LETTER_H-row)*(TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP)
                        local ang = getPixelAngle(glyph, col, row)
                        local runLen = getPixelRunLen(glyph, col, row)
                        table.insert(points, {pos=Vector2.new(px, py), angle=ang, runLen=runLen, letter=ch, letterIdx=li})
                    end
                end
            end
            cursorX = cursorX + TEXT_LETTER_W*(TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP) + TEXT_LETTER_SPACING
        end
    end
    if #points>0 then
        local minX, maxX = math.huge, -math.huge
        for _,pd in ipairs(points) do
            if pd.pos.X < minX then minX=pd.pos.X end
            if pd.pos.X > maxX then maxX=pd.pos.X end
        end
        local cx = (minX+maxX)*0.5
        for _,pd in ipairs(points) do
            pd.pos = Vector2.new(pd.pos.X - cx, pd.pos.Y)
        end
    end
    return points
end
local function buildTextAssignment()
    local txt = textContent or ""
    local total = #selectedParts
    if txt == "" or #txt==0 or total==0 then
        textPointsDataCache = {}
        textPointsDataCacheStr = txt
        textAssignment = {}
        textPartAngles = {}
        textAssignmentCacheCount = total
        textAssignmentCacheStr = txt
        return
    end
    local pointsData = buildTextPointsData(txt)
    textPointsDataCache = pointsData
    textPointsDataCacheStr = txt
    if #pointsData==0 then
        textAssignment = {}
        textPartAngles = {}
        textAssignmentCacheCount = total
        textAssignmentCacheStr = txt
        return
    end
    local sortedPoints = {}
    for i,pd in ipairs(pointsData) do table.insert(sortedPoints, pd) end
    table.sort(sortedPoints, function(a,b) return a.runLen > b.runLen end)
    local partEntries = {}
    for idx, p in ipairs(selectedParts) do
        if p and p.Parent then
            local s = p.Size
            local wallLong = "X"
            local maxDim = s.X
            if s.Y > maxDim then wallLong = "Y"; maxDim = s.Y end
            if s.Z > maxDim then wallLong = "Z"; maxDim = s.Z end
            table.insert(partEntries, {idx=idx, part=p, len=maxDim, longAxis=wallLong})
        end
    end
    table.sort(partEntries, function(a,b) return a.len > b.len end)
    textAssignment = {}
    textPartAngles = {}
    for i, pe in ipairs(partEntries) do
        local pd = sortedPoints[((i-1) % #sortedPoints)+1]
        textAssignment[pe.part] = pd
        local partAngle = 0
        if pe.longAxis=="Y" then partAngle=90 end
        if pe.longAxis=="Z" then partAngle=0 end
        local mirroredAngle = (180 - pd.angle) % 180
        local need = mirroredAngle - partAngle
        need = ((need+90)%180)-90
        if need == -90 then need = 90 end
        textPartAngles[pe.part] = need
        textAssignment[pe.idx] = pd
    end
    textAssignmentCacheCount = total
    textAssignmentCacheStr = txt
end
local function ensureTextAssignment()
    local total = #selectedParts
    if textAssignmentCacheStr ~= textContent or textAssignmentCacheCount ~= total or not textPointsDataCache or #textPointsDataCache==0 then
        buildTextAssignment()
    end
end

spcActive = false
spcPart   = nil
spcDepth  = 15
spcYOff   = 0

dv2Target = nil
dv2Label  = nil

homingTarget = nil
homingEndTime = 0
homingLaunchPos = Vector3.zero
homingFireTime  = 0
homingTouchConns = homingTouchConns or {}
homingDone = homingDone or {}
homingLabel  = nil
groundY = groundY or nil
targetY = targetY or nil
wobble = 0

railgunChargeStart = 0
railgunCharging = false
railgunFired = false
railgunPhase = "idle"
railgunPhaseStart = 0
railgunHitPos = Vector3.zero
railgunLabel = nil

barrageActive = false
barrageLabel = nil


drawTrails     = {} 
drawIndicators = {}
isDrawing      = false
currentTrail   = nil
cometHistory   = {}
COMET_MAX      = 500
slinkyHistory  = {}
SLINKY_MAX     = 400


npcTarget               = nil
npcSaved                = {}
npcConns                = {}
npcCam                  = { yaw=0, pitch=-0.25, dist=12 }
npcControlEnabled       = false
npcControlWalkSpeed     = 16
npcControlJumpPower     = 50
npcControlFreezeAutoJump = true
npcControlHaltMoveTo    = true


killAura         = false  killAuraRange   = 25
sitAura          = false  sitAuraRange    = 25
jumpAura         = false  jumpAuraRange   = 25
followAura       = false  followAuraRange = 40
freezeAura       = false  freezeAuraRange = 25
speedAuraEnabled = false  speedAuraRange  = 30  speedAuraSpeed = 30
spinAuraEnabled  = false  spinAuraRange   = 30  spinAuraSpeed  = 6


fingerGunEnabled = false
grabGunEnabled   = false
sitGunEnabled    = false
grabbedNPC       = nil
grabbedRoot      = nil
localGrabArmed   = false


NX = {
    tkGun = false, held = nil, root = nil, savedPS = nil,
    FLOAT_Y = 2, DRAG = 16,
    freezeGun = false, frozen = {},
    dead = false,
}


_npcToolsRayParams = RaycastParams.new()
_npcToolsRayParams.FilterType = Enum.RaycastFilterType.Exclude

GRAB_HOVER_Y_OFFSET = 3
    GRAB_TOSS_POWER     = 2500
GRAB_DRAG_POWER     = 180
FINGER_GUN_RANGE    = 10000

useLimits    = false
partLimit    = 10
sizeFilterOn = false
sizeFilterBigger = true
sizeFilterSize = Vector3.new(4, 4, 4)
function sizeFilterPass(part)
    if not sizeFilterOn then return true end
    if not (part and part.Parent and part:IsA("BasePart")) then return false end
    local okS, sz = pcall(function() return part.Size end)
    if not (okS and sz) then return false end
    local f = sizeFilterSize
    if typeof(f) ~= "Vector3" then return true end
    if sizeFilterBigger then
        return sz.X >= f.X and sz.Y >= f.Y and sz.Z >= f.Z
    else
        return sz.X <= f.X and sz.Y <= f.Y and sz.Z <= f.Z
    end
end
flyOn = false
flyCtl = {F=0,B=0,L=0,R=0,U=0,D=0}
flySpd = 50
flyBG = nil
flyBV = nil
flyDownConn = nil
flyUpConn = nil
flyFallConn = nil
clipOn = false
clipConn = nil
clipSaved = {}
function flyCleanupPart()
    pcall(function() if flyBG then flyBG:Destroy() end end)
    pcall(function() if flyBV then flyBV:Destroy() end end)
    flyBG = nil
    flyBV = nil
end
function flyAttach()
    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (hrp and hrp.Parent and hum) then return false end
    flyCleanupPart()
    local bgOk, bg = pcall(function()
        local b = Instance.new("BodyGyro")
        b.Name = "CatalystFlyBG"
        b.P = 9e4
        b.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        b.CFrame = hrp.CFrame
        b.Parent = hrp
        return b
    end)
    local bvOk, bv = pcall(function()
        local v = Instance.new("BodyVelocity")
        v.Name = "CatalystFlyBV"
        v.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        v.Velocity = Vector3.zero
        v.Parent = hrp
        return v
    end)
    if not (bgOk and bg and bvOk and bv) then flyCleanupPart() return false end
    flyBG = bg
    flyBV = bv
    pcall(function() hum.PlatformStand = true end)
    task.spawn(function()
        while flyOn and hrp and hrp.Parent and flyBV and flyBV.Parent and flyBG and flyBG.Parent do
            local cam = workspace.CurrentCamera
            if cam then
                pcall(function()
                    local c = flyCtl
                    local fx = (c.F or 0) + (c.B or 0)
                    local sx = (c.L or 0) + (c.R or 0)
                    local vx = (c.U or 0) + (c.D or 0)
                    if fx ~= 0 or sx ~= 0 or vx ~= 0 then
                        flyBV.Velocity = ((cam.CFrame.LookVector * fx) + ((cam.CFrame * CFrame.new(sx, (fx + vx) * 0.2, 0)).Position - cam.CFrame.Position)) * flySpd
                    else
                        flyBV.Velocity = Vector3.zero
                    end
                    flyBG.CFrame = cam.CFrame
                end)
            end
            task.wait()
        end
    end)
    return true
end
function setFly(on)
    if on then
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not (hrp and hrp.Parent and hum) then
            flyOn = false
            pcall(function() toast("fly: no character") end)
            return false
        end
        flyOn = true
        flyCtl = {F=0,B=0,L=0,R=0,U=0,D=0}
        if flyDownConn then pcall(function() flyDownConn:Disconnect() end) flyDownConn = nil end
        if flyUpConn then pcall(function() flyUpConn:Disconnect() end) flyUpConn = nil end
        if flyFallConn then pcall(function() flyFallConn:Disconnect() end) flyFallConn = nil end
        flyDownConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if not flyOn then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.W then flyCtl.F = 1
            elseif kc == Enum.KeyCode.S then flyCtl.B = -1
            elseif kc == Enum.KeyCode.A then flyCtl.L = -1
            elseif kc == Enum.KeyCode.D then flyCtl.R = 1
            elseif kc == Enum.KeyCode.E then flyCtl.U = 2
            elseif kc == Enum.KeyCode.Q then flyCtl.D = -2
            end
        end)
        reg(flyDownConn)
        flyUpConn = UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if not flyOn then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.W then flyCtl.F = 0
            elseif kc == Enum.KeyCode.S then flyCtl.B = 0
            elseif kc == Enum.KeyCode.A then flyCtl.L = 0
            elseif kc == Enum.KeyCode.D then flyCtl.R = 0
            elseif kc == Enum.KeyCode.E then flyCtl.U = 0
            elseif kc == Enum.KeyCode.Q then flyCtl.D = 0
            end
        end)
        reg(flyUpConn)
        flyFallConn = RunService.Heartbeat:Connect(function()
            if not flyOn then return end
            local ch2 = LP.Character
            local r = ch2 and ch2:FindFirstChild("HumanoidRootPart")
            if not (r and r.Parent) then return end
            local v = r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = Vector3.zero
            RunService.RenderStepped:Wait()
            if r and r.Parent and flyOn then
                r.AssemblyLinearVelocity = v
            end
        end)
        reg(flyFallConn)
        if not flyAttach() then
            setFly(false)
            return false
        end
        return true
    else
        flyOn = false
        flyCtl = {F=0,B=0,L=0,R=0,U=0,D=0}
        if flyDownConn then pcall(function() flyDownConn:Disconnect() end) flyDownConn = nil end
        if flyUpConn then pcall(function() flyUpConn:Disconnect() end) flyUpConn = nil end
        if flyFallConn then pcall(function() flyFallConn:Disconnect() end) flyFallConn = nil end
        flyCleanupPart()
        pcall(function()
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end)
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
        return true
    end
end
function setClip(on)
    clipOn = on and true or false
    if clipConn then pcall(function() clipConn:Disconnect() end) clipConn = nil end
    if clipOn then
        clipSaved = {}
        clipConn = RunService.Stepped:Connect(function()
            if not clipOn then return end
            local ch = LP.Character
            if ch then
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("BasePart") then
                        if clipSaved[d] == nil then
                            pcall(function() clipSaved[d] = d.CanCollide end)
                        end
                        if d.CanCollide then
                            pcall(function() d.CanCollide = false end)
                        end
                    end
                end
            end
        end)
        reg(clipConn)
    else
        pcall(function()
            local ch = LP.Character
            if ch then
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local sv = clipSaved and clipSaved[d]
                        if sv ~= nil then
                            pcall(function() d.CanCollide = sv end)
                        end
                    end
                end
            end
        end)
        clipSaved = {}
    end
end
reg(LP.CharacterAdded:Connect(function()
    if flyOn then
        task.spawn(function()
            local ch = LP.Character
            if not ch then return end
            local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart", 10)
            if hrp and hrp.Parent then
                task.wait(0.5)
                if flyOn then flyAttach() end
            end
        end)
    end
end))
pcall(function()
    local ch = LP.Character
    if ch then
        for _, d in ipairs(ch:GetDescendants()) do
            if d and (d.Name == "CatalystFlyBG" or d.Name == "CatalystFlyBV") then
                pcall(function() d:Destroy() end)
            end
        end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.PlatformStand = false end) end
    end
end)
formationType = "Mouse"
clickFormPos  = Vector3.zero
anchorPos    = Vector3.zero
clickedPlayer = nil
clickedPlayerRef = nil
lastClickedPos   = Vector3.zero
useESP        = false
espStyle      = "Label"
lastVelWrite  = {}

CONFIG_FILE = "catalyst_saves.txt"
hasFileSystem = type(readfile) == "function" and type(writefile) == "function"
_lastConfigSave = 0
CONFIG_SAVE_INTERVAL = 2.5

CONFIG_KEYS = {
    "keybinds", "partSpeed", "maxVelocity", "formRadius", "formScale", "formSizeX", "formSizeY", "formSizeZ", "formOffsetY", "formRotX", "formRotY", "formRotZ",
    "wallDist", "wallGap", "flingForce", "flingRange", "tornadoSpeed", "spiralHeight", "waveAmp", "orbitRadius",
    "autoSelRange", "killAuraRange", "sitAuraRange", "jumpAuraRange",
    "followAuraRange", "freezeAuraRange", "speedAuraRange", "speedAuraSpeed",
    "spinAuraRange", "spinAuraSpeed", "useLimits", "partLimit",
    "formationType", "useESP", "espStyle", "activeMode", "minigunRate", "minigunSpread",
    "espColor", "highlightFillColor", "highlightOutlineColor", "espFillTransparency", "espOutlineTransparency", "fakeCollisions",
    "strengthenParts", "strengthenDensity",
}

local function encodeConfig(cfg)
    local lines = {
        "# Catalyst saves — edit values after the = sign",
        "# Lines starting with # are ignored",
    }
    for _, key in ipairs(CONFIG_KEYS) do
        local v = cfg[key]
        if v ~= nil then
            lines[#lines + 1] = key .. "=" .. tostring(v)
        end
    end
    return table.concat(lines, "\n")
end

local function decodeConfig(data)
    local cfg = {}
    for line in string.gmatch(data, "[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local key, val = line:match("^([^=]+)=(.*)$")
            if key and val then
                key = key:match("^%s*(.-)%s*$")
                val = val:match("^%s*(.-)%s*$")
                if val == "true" then
                    cfg[key] = true
                elseif val == "false" then
                    cfg[key] = false
                else
                    local n = tonumber(val)
                    cfg[key] = n ~= nil and n or val
                end
            end
        end
    end
    return cfg
end

local function readConfigFile()
    local data
    if pcall(function() data = readfile(CONFIG_FILE) end) and data and data ~= "" then
        return data
    end
    return nil
end

local function writeConfigFile(payload)
    pcall(function() writefile(CONFIG_FILE, payload) end)
end

local function saveConfig(force)
    if not hasFileSystem then return end
    local now = tick()
    if not force and (now - _lastConfigSave) < CONFIG_SAVE_INTERVAL then return end
    _lastConfigSave = now
    local function colorString(c)
        return math.floor(c.R * 255) .. ", " .. math.floor(c.G * 255) .. ", " .. math.floor(c.B * 255)
    end
    local colorStr = colorString(GUI.ESP_ACCENT)
    local cfg = { -- the fucking configs that i hate
        partSpeed=partSpeed, maxVelocity=maxVelocity, formRadius=formRadius,
        formScale=formScale, formSizeX=formSizeX, formSizeY=formSizeY, formSizeZ=formSizeZ, formOffsetY=formOffsetY,
        formRotX=formRotX, formRotY=formRotY, formRotZ=formRotZ,
        wallDist=wallDist, wallGap=wallGap,
        flingForce=flingForce, flingRange=flingRange, tornadoSpeed=tornadoSpeed,
        spiralHeight=spiralHeight, waveAmp=waveAmp, orbitRadius=orbitRadius,
        autoSelRange=autoSelRange,
        killAuraRange=killAuraRange, sitAuraRange=sitAuraRange,
        jumpAuraRange=jumpAuraRange, followAuraRange=followAuraRange,
        freezeAuraRange=freezeAuraRange,
        speedAuraRange=speedAuraRange, speedAuraSpeed=speedAuraSpeed,
        spinAuraRange=spinAuraRange, spinAuraSpeed=spinAuraSpeed,
        useLimits=useLimits, partLimit=partLimit,
        formationType=formationType, useESP=useESP, espStyle=espStyle, activeMode=activeMode,
        minigunRate=minigunRate, minigunSpread=minigunSpread,
        espColor=colorStr, highlightFillColor=colorString(HL.fillColor), highlightOutlineColor=colorString(HL.outlineColor),
        espFillTransparency=HL.fillTransparency, espOutlineTransparency=HL.outlineTransparency,
        fakeCollisions=fakeCollisions,
        strengthenParts=strengthenParts, strengthenDensity=strengthenDensity,
    }
    if buttonKeybinds and next(buttonKeybinds) then
        local kbList = {}
        for btn, data in pairs(buttonKeybinds) do
            local btnText = data.originalText or buttonOriginalAppearance[btn] and buttonOriginalAppearance[btn].text or btn.Text
            btnText = string.gsub(btnText, "%s*%[.-%]", "")
            btnText = btnText:match("^%s*(.-)%s*$")
            if btnText and data.key then
                table.insert(kbList, btnText .. "||" .. data.key.Name)
            end
        end
        if #kbList > 0 then
            cfg.keybinds = table.concat(kbList, ";")
        else
            cfg.keybinds = "" --local keybind = penis
        end
    end
    if cfg.keybinds == nil then
        local prevData = readConfigFile()
        if prevData then
            local prevCfg = decodeConfig(prevData)
            if type(prevCfg) == "table" and type(prevCfg.keybinds) == "string" and prevCfg.keybinds ~= "" then
                cfg.keybinds = prevCfg.keybinds
            end
        end
    end
    writeConfigFile(encodeConfig(cfg))
end

local function loadConfig()
    if not hasFileSystem then return end
    local data = readConfigFile()
    if not data then return end
    local cfg = decodeConfig(data)
    if type(cfg) ~= "table" then return end
    if cfg.partSpeed ~= nil then partSpeed = cfg.partSpeed end
    if cfg.maxVelocity ~= nil then maxVelocity = cfg.maxVelocity end
    if cfg.formRadius ~= nil then formRadius = cfg.formRadius end
    if cfg.formScale ~= nil then formScale = cfg.formScale end
    if cfg.formSizeX ~= nil then formSizeX = cfg.formSizeX end
    if cfg.formSizeY ~= nil then formSizeY = cfg.formSizeY end
    if cfg.formSizeZ ~= nil then formSizeZ = cfg.formSizeZ end
    if cfg.formOffsetY ~= nil then formOffsetY = cfg.formOffsetY end
    if cfg.formRotX ~= nil then formRotX = cfg.formRotX end
    if cfg.formRotY ~= nil then formRotY = cfg.formRotY end
    if cfg.formRotZ ~= nil then formRotZ = cfg.formRotZ end
    if cfg.wallDist ~= nil then wallDist = cfg.wallDist end
    if cfg.wallGap ~= nil then wallGap = cfg.wallGap end
    if cfg.flingForce ~= nil then flingForce = cfg.flingForce end
    if cfg.flingRange ~= nil then flingRange = cfg.flingRange end
    if cfg.tornadoSpeed ~= nil then tornadoSpeed = cfg.tornadoSpeed end
    if cfg.spiralHeight ~= nil then spiralHeight = cfg.spiralHeight end
    if cfg.waveAmp ~= nil then waveAmp = cfg.waveAmp end
    if cfg.orbitRadius ~= nil then orbitRadius = cfg.orbitRadius end
    if cfg.autoSelRange ~= nil then autoSelRange = cfg.autoSelRange end
    if cfg.killAuraRange ~= nil then killAuraRange = cfg.killAuraRange end
    if cfg.sitAuraRange ~= nil then sitAuraRange = cfg.sitAuraRange end
    if cfg.jumpAuraRange ~= nil then jumpAuraRange = cfg.jumpAuraRange end
    if cfg.followAuraRange ~= nil then followAuraRange = cfg.followAuraRange end
    if cfg.freezeAuraRange ~= nil then freezeAuraRange = cfg.freezeAuraRange end
    if cfg.speedAuraRange ~= nil then speedAuraRange = cfg.speedAuraRange end
    if cfg.speedAuraSpeed ~= nil then speedAuraSpeed = cfg.speedAuraSpeed end
    if cfg.spinAuraRange ~= nil then spinAuraRange = cfg.spinAuraRange end
    if cfg.spinAuraSpeed ~= nil then spinAuraSpeed = cfg.spinAuraSpeed end
    if cfg.useLimits ~= nil then useLimits = cfg.useLimits end
    if cfg.partLimit ~= nil then partLimit = cfg.partLimit end
    if cfg.formationType ~= nil then formationType = cfg.formationType end
    if cfg.minigunRate ~= nil then minigunRate = cfg.minigunRate end
    if cfg.minigunSpread ~= nil then minigunSpread = cfg.minigunSpread end
    if cfg.useESP ~= nil then useESP = cfg.useESP end
    if cfg.espStyle ~= nil then espStyle = cfg.espStyle end
    if cfg.activeMode ~= nil then activeMode = cfg.activeMode end
    local function parseColor(value)
        if type(value) ~= "string" then return nil end
        local r, g, b = value:match("([%d.]+),%s*([%d.]+),%s*([%d.]+)")
        if r and g and b then
            return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        end
    end
    local legacyColor = parseColor(cfg.espColor)
    if legacyColor then
        GUI.ESP_ACCENT = legacyColor
        HL.fillColor = legacyColor
        HL.outlineColor = legacyColor
    end
    local savedFill = parseColor(cfg.highlightFillColor)
    local savedOutline = parseColor(cfg.highlightOutlineColor)
    if savedFill then HL.fillColor = savedFill end
    if savedOutline then HL.outlineColor = savedOutline end
    if savedFill or savedOutline then GUI.ESP_ACCENT = savedFill or savedOutline end
    if cfg.espFillTransparency ~= nil then
        HL.fillTransparency = tonumber(cfg.espFillTransparency) or HL.fillTransparency
    end
    if cfg.espOutlineTransparency ~= nil then
        HL.outlineTransparency = tonumber(cfg.espOutlineTransparency) or HL.outlineTransparency
    end
    if cfg.fakeCollisions ~= nil then
        fakeCollisions = cfg.fakeCollisions
    end
    if cfg.strengthenParts ~= nil then
        strengthenParts = cfg.strengthenParts
    end
    if cfg.strengthenDensity ~= nil then
        strengthenDensity = cfg.strengthenDensity
    end
    if cfg.keybinds and type(cfg.keybinds) == "string" and cfg.keybinds ~= "" then
        savedKeybinds = {}
        local delim = string.find(cfg.keybinds, ";") and "[^;]+" or "[^|]+"
        if string.find(cfg.keybinds, ";") then
            for entry in string.gmatch(cfg.keybinds, "[^;]+") do
                local btnText, keyName = entry:match("^(.+)||(.+)$")
                if btnText and keyName then
                    savedKeybinds[btnText] = keyName
                end
            end
        else
            local parts = {}
            for part in string.gmatch(cfg.keybinds, "[^|]+") do
                if part ~= "" then table.insert(parts, part) end
            end
            for i=1, #parts, 2 do
                local btnText = parts[i]
                local keyName = parts[i+1]
                if btnText and keyName then
                    savedKeybinds[btnText] = keyName
                end
            end
        end
    end
end

loadConfig()


local MODES = { --why are there so many aaa [currently 68] send help theyre invading my house i hate these so much
    "Mouse",   "Tornado",    "Ring",      "Orbit",
    "Spiral",  "Wave",       "Halo",      "Drone",
    "DroneV2", "Shield",     "Comet",     "Wall",
    "Draw",    "Beam",       "Sphere",    "Vortex",
    "DNA",     "Pulse",      "Grid",      "Cube",
    "Scatter", "Star",       "Pendulum",  "Rain",
    "Galaxy",  "Blackhole",  "Lemniscate","Blender",
    "Crown",   "Swarm",      "Minigun",   "Satellite",
    "Seek",    "Stickman",   "Slinky",    "Fountain",
    "Bounce",  "Ripple",     "Juggle",    "Constellation",
    "Rose",    "OrbitSin",   "Liss",      "Swing",
    "Aura",    "Homing",     "Railgun",   "Barrage",
    "Sinewave", "Heart", "Wings", "Crystal",
    "TwinStars", "Tesseract", "Atom", "Lightning",
    "Sniper", "Bridge", "Strike", "Boomerang",
    "Text", "Scythe", "Pentagram", "Chained", -- PENIS MODE SOON I SWEAR ILL GIVE EVERYONE A MASSIVE DONG THAT SWINGS AROUND LIKE A POOL NOODLE
    "Knot", "Mobius", "Gyro", "RoseV2",
}




function netHoldVelocity()
    local t = tick()
    return Vector3.new(
        17.5555555 + math.sin(t*10) * 0.05,
        17.5555555 + math.cos(t*13) * 0.05,
        17.5555555 + math.sin(t*17 + 1) * 0.05
    )
end

local preSimConn = RunService.PreSimulation and
    RunService.PreSimulation:Connect(function(deltaTime)
        pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
        for _, part in ipairs(selectedParts) do
            if part and part.Parent and not part.Anchored then
                pcall(reinforceOwnershipConstraints, part, partTargets[part])
                pcall(reinforceOwnershipDrive, part, partTargets[part], deltaTime)
                local owned = false
                pcall(function() owned = ownedCached(part) end)
                if owned then
                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                else
                    local origVel = part.AssemblyLinearVelocity
                    part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                    part.AssemblyLinearVelocity = origVel
                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                end
            end
        end
    end) or nil
if preSimConn then reg(preSimConn) end

local ownerConn = RunService.Heartbeat:Connect(function()
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(reinforceOwnershipConstraints, part, partTargets[part])
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            local owned = false
            pcall(function() owned = ownedCached(part) end)
            pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
            if not owned then
                local origVel = part.AssemblyLinearVelocity
                part.AssemblyLinearVelocity = Vector3.new(75000, 75000, 75000)
                part.AssemblyLinearVelocity = origVel
            end
        end
    end
end)
reg(ownerConn)


local renderOwnAcc = 0
local renderOwnerConn = RunService.RenderStepped:Connect(function(dt)
    renderOwnAcc += dt or 0
    if renderOwnAcc < 1/30 then return end
    renderOwnAcc = 0
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(reinforceOwnershipConstraints, part, partTargets[part])
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            pcall(reinforceOwnershipRender, part, partTargets[part])
            local owned = false
            pcall(function() owned = ownedCached(part) end)
            pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
            if not owned then
                local origVel = part.AssemblyLinearVelocity
                part.AssemblyLinearVelocity = Vector3.new(100000, 100000, 100000)
                part.AssemblyLinearVelocity = origVel
            end
        end
    end
end)
reg(renderOwnerConn)
local aggressiveOwnerConn = RunService.Heartbeat:Connect(function()
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            pcall(reinforceOwnershipRender, part, partTargets[part])
            local owned = false
            pcall(function() owned = ownedCached(part) end)
            pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
            if not owned then
                local origVel = part.AssemblyLinearVelocity
                part.AssemblyLinearVelocity = Vector3.new(150000, 150000, 150000)
                part.AssemblyLinearVelocity = origVel
            end
        end
    end
end)
reg(aggressiveOwnerConn)

HEAVY_ASSIST_MASS = 1500


local function getNetAttach(part)
    return part and part:FindFirstChild("NetAttach")
end

local function getNetAP(part)
    local att = getNetAttach(part)
    return att and att:FindFirstChild("NetAP")
end

local function getNetAO(part)
    local att = getNetAttach(part)
    return att and att:FindFirstChild("NetAO")
end

local function alignForceFor(part)
    local m = 1
    pcall(function() m = part.AssemblyMass end)
    if m ~= m or m == math.huge then
        return 1000000000000
    end
    return math.huge
end
reinforceOwnershipConstraints = function(part, target)
    if not (part and part.Parent and target) then return end

    local AP = getNetAP(part)
    if AP then
        AP.Enabled = true
        AP.MaxForce = alignForceFor(part)
        AP.MaxVelocity = math.huge
        AP.RigidityEnabled = false
    end

    local AO = getNetAO(part)
    if AO then
        AO.Enabled = true
        AO.MaxTorque = alignForceFor(part)
        AO.MaxAngularVelocity = math.huge
    end
    local supMass = part.AssemblyMass
    if supMass == supMass and supMass ~= math.huge then
        local rigid = false
        pcall(function()
            local ap = getNetAP(part)
            rigid = ap and ap.RigidityEnabled == true
        end)
        local compFactor = 0
        if not rigid then
            compFactor = supMass > 100 and 1.0 or 0.08
        end
        local supportForce = Vector3.new(0, supMass * workspace.Gravity * compFactor, 0)
        for _, name in ipairs({"ServerResponse", "ServerResponse2"}) do
            local response = part:FindFirstChild(name)
            if response and response:IsA("BodyForce") then
                response.Force = supportForce
            end
        end
    end
end

reinforceOwnershipHeartbeat = function(part, target)
    if not (part and part.Parent and target and target.position) then return end

    local originalVelocity = part.AssemblyLinearVelocity
    local diff = target.position - part.Position
    local dist = diff.Magnitude
    if dist < 0.01 or dist ~= dist then
        part.AssemblyLinearVelocity = netHoldVelocity()
        return
    end
    local desiredVelocity = diff.Unit * 20000
    part.AssemblyLinearVelocity = originalVelocity:Lerp(desiredVelocity, 0.99)
    part.AssemblyLinearVelocity = originalVelocity
    part.AssemblyLinearVelocity = netHoldVelocity()
end

reinforceOwnershipRender = function(part, target)
    if not (part and part.Parent and target and target.position) then return end

    local originalVelocity = part.AssemblyLinearVelocity
    local diff = target.position - part.Position
    local dist = diff.Magnitude
    if dist < 0.01 or dist ~= dist then
        part.AssemblyLinearVelocity = netHoldVelocity()
        return
    end
    local desiredVelocity = diff.Unit * 30000
    part.AssemblyLinearVelocity = originalVelocity:Lerp(desiredVelocity, 0.995)
    part.AssemblyLinearVelocity = originalVelocity
    part.AssemblyLinearVelocity = netHoldVelocity() -- this is my trick, if you set speed to 15 or above 14.46262424 it stays still, pls no touchy touch touch
end

reinforceOwnershipDrive = function(part, target, deltaTime)
    if not (part and part.Parent and target and target.position) then return end

    local originalVelocity = part.AssemblyLinearVelocity
    local diff = target.position - part.Position
    local dist = diff.Magnitude
    if dist < 0.01 or dist ~= dist then
        part.AssemblyLinearVelocity = netHoldVelocity()
        return
    end
    local desiredVelocity = diff.Unit * 40000
    part.AssemblyLinearVelocity = originalVelocity:Lerp(desiredVelocity, 0.998)
    part.AssemblyLinearVelocity = originalVelocity
    part.AssemblyLinearVelocity = netHoldVelocity() -- again no touchy touch touch, needs to be above 14.46262424 at all times!!!!
end

local function reassertOwnershipAll()
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then -- no ancored part pls thx
            pcall(reinforceOwnershipConstraints, part, partTargets[part])
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
        end
    end
end

local function reassertOwnershipAggressive(duration) -- aggression is the key
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > duration then
            conn:Disconnect()
            return
        end
        pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
        for _, part in ipairs(selectedParts) do
            if part and part.Parent and not part.Anchored then
                pcall(reinforceOwnershipConstraints, part, partTargets[part])
                pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
                local AP = getNetAP(part)
                if AP then
                    AP.Enabled = true
                    AP.MaxForce = alignForceFor(part)
                    AP.MaxVelocity = math.huge
                    AP.Position = partTargets[part] and partTargets[part].position or part.Position
                end
                local AO = getNetAO(part)
                if AO then
                    AO.Enabled = true
                    AO.MaxTorque = alignForceFor(part)
                    AO.MaxAngularVelocity = math.huge
                    AO.CFrame = partTargets[part] and partTargets[part].rotation or part.CFrame
                end
            end
        end
    end)
end

deathStashActive = false
deathStashPos = Vector3.zero
stashAliveSince = nil

function startDeathStash()
    if #selectedParts == 0 and (not spcPart or not spcPart.Parent) then return end
    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local anchor = hrp and hrp.Position or nil
    if not anchor then
        if #selectedParts > 0 then
            local p0 = selectedParts[1]
            anchor = (p0 and p0.Parent) and p0.Position or Vector3.zero
        elseif spcPart and spcPart.Parent then
            anchor = spcPart.Position
        else
            anchor = Vector3.zero
        end
    end
    local cx, cy, cz, cn = 0, 0, 0, 0
    for _, p in ipairs(selectedParts) do
        if p and p.Parent then
            local pp = p.Position
            cx, cy, cz, cn = cx + pp.X, cy + pp.Y, cz + pp.Z, cn + 1
        end
    end
    if cn > 0 then
        anchor = Vector3.new(cx / cn, cy / cn, cz / cn)
    end
    deathStashPos = anchor
    deathStashActive = true
    deathCollideState = "dead"
end

function endDeathStash()
    if not deathStashActive then return end
    deathStashActive = false
    deathCollideState = "return"
    stashAliveSince = nil
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    for _, p in ipairs(selectedParts) do
        pcall(beginUnfreezeHold, p)
        pcall(function()
            p.AssemblyLinearVelocity = netHoldVelocity()
            p.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if spcPart and spcPart.Parent then pcall(reclaimAssembly, spcPart) end
    pcall(rebuildAssemblyCache, true)
    assemblyDirtyAt = 0
    for _, p in ipairs(selectedParts) do
        if p and p.Parent then pcall(ghostAssemblyForDrag, p) end
    end
    deathReturnGen = (deathReturnGen or 0) + 1
    local myRet = deathReturnGen
    local retGen = _G._catGen
    task.delay(3, function()
        if retGen ~= _G._catGen then return end
        if myRet ~= deathReturnGen then return end
        if rotDrag.active then return end
        pcall(restoreDragGhost)
    end)
end
reg(LP.CharacterAdded:Connect(function()
    pcall(function()
        for _, o in ipairs(workspace:GetChildren()) do
            if o.Name == "CatalystDeathFloor" then o:Destroy() end
        end
    end)
    task.delay(0.1, function() reassertOwnershipAggressive(5) end)
    task.delay(0.5, function() reassertOwnershipAggressive(5) end)
    task.spawn(function()
        task.wait(0.8)
        local ch = LP.Character
        if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
            or ch:WaitForChild("HumanoidRootPart", 15)
        if hrp then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if not h or h.Health > 0 then
                beginReturn()
            end
        end
    end)
end))

function buildDeathFloor()
    pcall(function()
        for _, o in ipairs(workspace:GetChildren()) do
            if o.Name == "CatalystDeathFloor" then o:Destroy() end
        end
    end)
    if #selectedParts == 0 then return end
    local hrp0 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local anchor0 = (hrp0 and hrp0.Parent and hrp0.Position) or nil
    if not anchor0 then
        local p0 = selectedParts[1]
        if p0 and p0.Parent then anchor0 = p0.Position end
    end
    if not anchor0 then return end
    local f = Instance.new("Part")
    f.Name = "CatalystDeathFloor"
    f.Size = Vector3.new(100, 4, 100)
    f.CFrame = CFrame.new(anchor0.X, anchor0.Y - 5, anchor0.Z)
    f.Anchored = true
    f.CanCollide = true
    f.Transparency = 1
    f.CanQuery = false
    f.CanTouch = false
    f.CastShadow = false
    f.Parent = workspace
end

do
    local function hookHum(ch)
        local h = ch:WaitForChild("Humanoid", 30) -- human is oid
        if h then
            pcall(function() h.BreakJointsOnDeath = false end)
            h.Died:Connect(function()
                pcall(endRotDrag)
                startDeathStash()
                buildDeathFloor()
                deathSpamUntil = tick() + 10
                task.spawn(function()
                    for _ = 1, 40 do
                        task.wait(0.25)
                        reassertOwnershipAggressive(2) -- MORE AGGRESSION
                    end
                end)
            end)
        end
    end
    if LP.Character then task.spawn(hookHum, LP.Character) end
    reg(LP.CharacterAdded:Connect(hookHum)) -- hooks human oid on crack
end

function syncAlignTarget(part, target)
    if not (part and part.Parent and target) then return end
    if frozenTargets[part] then
        target = { position = frozenTargets[part], rotation = target.rotation, responsiveness = target.responsiveness, rotResponsiveness = target.rotResponsiveness }
    end
    if unfreezeT0[part] then
        local ek = (tick() - unfreezeT0[part]) / 0.4
        if ek >= 1 then
            unfreezeT0[part] = nil
        else
            ek = math.clamp(ek, 0, 1)
            ek = ek * ek * (3 - 2 * ek)
            local tp = target.position
            if tp then
                target = { position = part.Position:Lerp(tp, ek), rotation = target.rotation, responsiveness = target.responsiveness, rotResponsiveness = target.rotResponsiveness }
            else
                unfreezeT0[part] = nil
            end
        end
    end

    local posResponsiveness = target.responsiveness or 100000
    local rotResponsiveness = target.rotResponsiveness or math.huge

    local AP = getNetAP(part)
    if AP then
        AP.Mode               = Enum.PositionAlignmentMode.OneAttachment
        AP.MaxForce           = alignForceFor(part)
        AP.MaxVelocity        = math.huge
        AP.Responsiveness     = math.huge
        AP.RigidityEnabled    = false
        AP.ApplyAtCenterOfMass = true
        AP.Enabled            = true
        AP.Position           = target.position or part.Position
    end

    local AO = getNetAO(part)
    if AO then
        AO.Mode               = Enum.OrientationAlignmentMode.OneAttachment
            AO.MaxTorque          = alignForceFor(part)
        AO.MaxAngularVelocity = math.huge
        AO.Responsiveness     = rotResponsiveness
        AO.RigidityEnabled    = false
        AO.Enabled            = true
        if not (rotDrag and rotDrag.active and rotDrag.part == part) then
            AO.CFrame             = target.rotation or part.CFrame
        end
    end
end
local smoothMoveAcc = 0
local smoothMovementConn = RunService.RenderStepped:Connect(function(dt)
    smoothMoveAcc += dt or 0
    if smoothMoveAcc < 1/30 then return end
    smoothMoveAcc = 0
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored and not frozenTargets[part] then
            pcall(function()
                if partBallistic(part) then
                    local ap = getNetAP(part)
                    if ap and not ap.Enabled then return end
                end
                syncAlignTarget(part, partTargets[part])
            end)
        end
    end
end)
reg(smoothMovementConn)

local function getMoveResponsiveness(multiplier)
    local base = 20 + partSpeed * 4
    return math.clamp(base * (multiplier or 1), 50, 500)
end

local partTouchConns = {}

partCollisionState = {}
local partCollisionConns = {}

charNCCs = {}
charNCCGen = 0
hookCharNCCGenConn = nil

local function unlinkNoCollide(part)
    local rec = charNCCs and charNCCs[part]
    if rec then
        for _, ncc in ipairs(rec.list) do pcall(function() ncc:Destroy() end) end
        charNCCs[part] = nil
    end
end

local function linkNoCollide(part)
    if not (part and part.Parent and part:IsA("BasePart")) then return end
    local char = LP.Character
    if not char then return end
    local rec = charNCCs[part]
    if rec and rec.char == char and rec.vsn == charNCCGen then return end
    unlinkNoCollide(part)
    local list = {}
    for _, cPart in ipairs(char:GetChildren()) do
        if cPart:IsA("BasePart") then
            local ok, ncc = pcall(function()
                local n = Instance.new("NoCollisionConstraint")
                n.Part0 = part
                n.Part1 = cPart
                n.Parent = part
                return n
            end)
            if ok and ncc then table.insert(list, ncc) end
        end
    end
    charNCCs[part] = {char = char, list = list, vsn = charNCCGen}
end

function hookCharNCCGen(ch)
    pcall(function()
        if hookCharNCCGenConn then pcall(function() hookCharNCCGenConn:Disconnect() end) end
        hookCharNCCGenConn = nil
        if ch and ch.Parent then
            hookCharNCCGenConn = ch.DescendantAdded:Connect(function(d)
                pcall(function()
                    if d and d:IsA("BasePart") then
                        charNCCGen = (charNCCGen or 0) + 1
                    end
                end)
            end)
        end
    end)
end

if not _G._atomizerCharNCC then
    _G._atomizerCharNCC = true
    LP.CharacterAdded:Connect(function()
        task.wait(0.5)
        local cur = LP.Character
        local ps = {}
        for part, rec in pairs(charNCCs) do
            if not rec or rec.char ~= cur then table.insert(ps, part) end
        end
        for _, part in ipairs(ps) do unlinkNoCollide(part) end
        hookCharNCCGen(LP.Character)
    end)
    hookCharNCCGen(LP.Character)
end

local function updateSelfCollision()
    local char = LP.Character
    if not char then return end
    local linked = 0
    for _, p in ipairs(selectedParts) do
        if linked >= 200 then break end
        if p and p.Parent and p:IsA("BasePart") then
            linkNoCollide(p) linked += 1
        end
    end
    local checked = {}
    local extraLinked = 0
    local function handle(p)
        if extraLinked >= 200 then return end
        if not (p and p.Parent and p:IsA("BasePart")) then return end
        linkNoCollide(p) extraLinked += 1
    end
    for p in pairs(assemblyExtras) do
        if extraLinked >= 200 then break end
        handle(p)
    end
end

function beginReturn()
    if not deathStashActive then return end
    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    stashAliveSince = nil
    for _, p in ipairs(selectedParts) do
        if p and p.Parent then pcall(linkNoCollide, p) end
    end
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    endDeathStash()
end


local function disableSelectedCollision(part)
    if not (part and part.Parent) then return end

    if partCollisionState[part] == nil then
        partCollisionState[part] = (part.CanCollide ~= false)
    end

    if fakeCollisions then
        part.CanCollide = false
        if not partCollisionConns[part] then
            partCollisionConns[part] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
                if part and part.Parent and fakeCollisions then
                    part.CanCollide = false
                end
            end)
        end
    end
end

local function restoreSelectedCollision(part)
    if not part then return end
    if partCollisionConns[part] then
        pcall(function() partCollisionConns[part]:Disconnect() end)
        partCollisionConns[part] = nil
    end

    pcall(function()
        if part.Parent then
            if partCollisionState[part] ~= nil then
                part.CanCollide = partCollisionState[part]
            else
                part.CanCollide = true
            end
        end
    end)
    partCollisionState[part] = nil
end

local function reclaimOnTouch(part, hit)
    if not part or not part.Parent then return end
    local lastT = reclaimTouchAt[part] or 0
    if tick() - lastT < 0.1 then return end
    reclaimTouchAt[part] = tick()

    local isVelMode = activeMode == "DroneV2"

pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    pcall(function()
        if type(setsimulationradius) == "function" then
            setsimulationradius(math.huge)
        end
    end)
    local target = partTargets[part]
    local _homingFly = (activeMode == "Homing" and homingTarget and homingTarget.Parent and tick() < homingEndTime)
    pcall(function()

        local AP = getNetAP(part)
        if AP then
            AP.MaxForce    = alignForceFor(part)
            AP.MaxVelocity = math.huge
            if not _homingFly then
                AP.Enabled     = true
                AP.Position    = (target and target.position) or part.Position
            end
        end
        local AO = getNetAO(part)
        if AO then
        AO.MaxTorque          = alignForceFor(part)
            AO.MaxAngularVelocity = math.huge
            local _dv2Spin = (activeMode == "DroneV2" and dv2Target and dv2Target.Parent)
            local _dragRot = (rotDrag and rotDrag.active and rotDrag.part == part)
            if not _dv2Spin and not _homingFly and not _dragRot then
                AO.Enabled            = true
                AO.CFrame             = (target and target.rotation) or part.CFrame
            end
        end

        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
        pcall(function() if part.RootPriority ~= 127 then part.RootPriority = 127 end end)
        pcall(ensureLegacyMovers, part)
        local _dv2Hover = (activeMode == "DroneV2" and dv2Target and dv2Target.Parent)
        if not _dv2Hover and not _homingFly then
            part.AssemblyLinearVelocity = netHoldVelocity()
        end
        do
            local _dv2Spin2 = (activeMode == "DroneV2" and dv2Target and dv2Target.Parent)
            if not _dv2Spin2 and not _homingFly then
                part.AssemblyAngularVelocity = Vector3.zero
            else
                pcall(function()
                    local oa = part.AssemblyAngularVelocity
                    part.AssemblyAngularVelocity = Vector3.new(500, 500, 500)
                    part.AssemblyAngularVelocity = oa
                end)
            end
        end
        if hit and hit.Parent then
            local m = hit:FindFirstAncestorOfClass("Model")
            if m and (Players:GetPlayerFromCharacter(m) or m:FindFirstChildOfClass("Humanoid")) then
                pcall(function()
                    local ov = part.AssemblyLinearVelocity
                    part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                    part.AssemblyLinearVelocity = ov
                end)
                pcall(function()
                    local rr = getAssemblyRoot(part)
                    if rr and rr.Parent and not rr.Anchored then
                        pcall(sethiddenproperty, rr, "NetworkIsSleeping", false)
                        pcall(function() if rr.RootPriority ~= 127 then rr.RootPriority = 127 end end)
                        if type(reclaimAssembly) == "function" then
                            pcall(reclaimAssembly, rr)
                        end
                    end
                end)
                if activeMode == "Ring" then
                    local _rr = getAssemblyRoot(part)
                    if _rr ~= part then pcall(reclaimAssembly, _rr) end
                end
            end
        end
    end)
end

local function isSelected(p)
    if selectedSetCache[p] then return true end
    for _,s in ipairs(selectedParts) do if s==p then return true end end
    return false
end

local function findSelectedAssemblyMate(part)
    if not (part and typeof(part) == "Instance" and part:IsA("BasePart")) then return nil end
    local okR, hitRoot = pcall(function() return part:GetRootPart() end)
    local okM, mates = pcall(function() return part:GetConnectedParts(true) end)
    if not ((okR and hitRoot and hitRoot.Parent) or (okM and type(mates) == "table")) then return nil end
    for _, s in ipairs(selectedParts) do
        if s and s.Parent and s ~= part then
            if okR and hitRoot and hitRoot.Parent then
                local okS, sRoot = pcall(function() return s:GetRootPart() end)
                if okS and sRoot == hitRoot then return s end
            end
            if okM and type(mates) == "table" then
                for _, m in ipairs(mates) do
                    if m == s then return s end
                end
            end
        end
    end
    return nil
end

selectedSetCache = {}
partRootCache = {}
passengerSet = {}
assemblyExtras = {}
rigidRoots = {}
disabledExtraSeats = {}
seatSweepModels = {}
extraRoots = {}
assemblyDirtyAt = 0
asmRebuildPending = false
canQuerySweepPending = false
ownVerdict = setmetatable({}, {__mode = "k"})
ownVerdictAt = setmetatable({}, {__mode = "k"})
releasedSet = {}
assemblyAnchoredCache = {}

function getAssemblyRoot(part)
    local ok, root = pcall(function() return part:GetRootPart() end)
    if ok and root and root.Parent then return root end
    return part
end

ownerCheckFn = nil
ownerFalseStreak = setmetatable({}, {__mode = "k"})

function ensureOwnerCheck()
    if ownerCheckFn ~= nil then return ownerCheckFn end
    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local anchorTest = nil
    pcall(function()
        local n = 0
        local stack = {workspace}
        while #stack > 0 and not anchorTest and n < 200 do
            local cur = table.remove(stack, 1)
            n += 1
            for _, d in ipairs(cur:GetChildren()) do
                if d:IsA("BasePart") and d.Anchored then
                    anchorTest = d
                    break
                elseif d:IsA("Model") or d:IsA("Folder") then
                    table.insert(stack, d)
                end
            end
        end
    end)
    local valid = {}
    local function tryAdd(fn)
        local okP, vP = pcall(fn, hrp)
        if not (okP and vP == true) then return end
        if anchorTest then
            local okA, vA = pcall(fn, anchorTest)
            if not (okA and vA == false) then return end
        end
        table.insert(valid, fn)
    end
    tryAdd(function(p) local o = p:GetNetworkOwner() return o == LP end)
    if type(isnetworkowner) == "function" then tryAdd(isnetworkowner) end
    if type(isNetworkOwner) == "function" and isNetworkOwner ~= isnetworkowner then tryAdd(isNetworkOwner) end
    if #valid == 0 then
        ownerCheckFn = function(p) return nil end
        return ownerCheckFn
    end
    ownerCheckFn = function(p)
        if not (p and p.Parent) then return nil end
        for _, fn in ipairs(valid) do
            local ok, v = pcall(fn, p)
            if ok and type(v) == "boolean" then return v end
        end
        return nil
    end
    return ownerCheckFn
end

function canDrivePart(part)
    if not (part and part.Parent and part:IsA("BasePart")) then return false end
    if part.Anchored then return false end
    local target = part
    pcall(function()
        local r = getAssemblyRoot(part)
        if r and r.Parent then target = r end
    end)
    if not (target and target.Parent) then return false end
    local okA, isAnch = pcall(function() return target.Anchored end)
    if okA and isAnch then return false end
    local okO, owner = pcall(function() return target:GetNetworkOwner() end)
    if okO and owner == LP then return true end
    if type(isnetworkowner) == "function" then
        local okI, vI = pcall(isnetworkowner, target)
        if okI and vI == true then return true end
    end
    if type(isNetworkOwner) == "function" and isNetworkOwner ~= isnetworkowner then
        local okJ, vJ = pcall(isNetworkOwner, target)
        if okJ and vJ == true then return true end
    end
    local age = nil
    pcall(function()
        if type(gethiddenproperty) == "function" then
            age = gethiddenproperty(target, "ReceiveAge")
        end
    end)
    if age == nil then
        pcall(function() age = target.ReceiveAge end)
    end
    if age ~= nil then return age == 0 end
    if okO then return false end
    return false
end

function ownedCached(part)
    if part and ownVerdictAt[part] then
        local vAge = tick() - ownVerdictAt[part]
        if vAge >= 0 and vAge < 0.1 then
            return ownVerdict[part]
        end
    end
    local v = false
    pcall(function() v = canDrivePart(part) end)
    if part then
        ownVerdict[part] = v
        ownVerdictAt[part] = tick()
    end
    return v
end

function rebuildAssemblyCache(includeExtras)
    selectedSetCache = {}
    partRootCache = {}
    passengerSet = {}
    pruneExtraSeats()
    if includeExtras then assemblyExtras = {} end
    for _, p in ipairs(selectedParts) do
        if p then selectedSetCache[p] = true end
    end
    for _, p in ipairs(selectedParts) do
        if p and p.Parent then
            local root = getAssemblyRoot(p)
            partRootCache[p] = root
            if root ~= p and selectedSetCache[root] then
                passengerSet[p] = true
                rigidRoots[root] = true
            elseif root ~= p then
                rigidRoots[p] = true
            end
        end
    end
    for r in pairs(rigidRoots) do
        if not selectedSetCache[r] then
            rigidRoots[r] = nil
        end
    end
    if includeExtras then
        local seenRoots = {}
        local queue = {}
        local qhead = 1
        local queued = {}
        local mateFound = {}
        local extraCount = 0
        local CAP = 400
        local function push(n)
            if not queued[n] then
                queued[n] = true
                queue[#queue + 1] = n
            end
        end
        local function isCharPart(c)
            local m = c:FindFirstAncestorOfClass("Model")
            if m and m:FindFirstChildOfClass("Humanoid") then return true end
            return false
        end
        seatSweepModels = {}
        assemblyAnchoredCache = {}
        local nodeLeader = {}
        local nodeSeed = {}
        local anchFound = {}
        for _, p in ipairs(selectedParts) do
            local r = partRootCache[p] or p
            if r and r.Parent and not seenRoots[r] then
                seenRoots[r] = true
                push(r)
                nodeSeed[r] = r
                nodeLeader[r] = (selectedSetCache[r] and r or p)
                killSeatsFor(r)
                if not selectedSetCache[r] and extraCount < CAP then
                    assemblyExtras[r] = true
                    extraCount += 1
                end
            end
        end
        while qhead <= #queue and extraCount < CAP do
            local cur = queue[qhead]
            qhead += 1
            if cur and cur.Parent and cur:IsA("BasePart") then
                local ok, conn = pcall(function() return cur:GetConnectedParts() end)
                if ok and conn and #conn > 0 then
                    if seenRoots[cur] then mateFound[cur] = true end
                    for _, c in ipairs(conn) do
                        if c and c ~= cur and c:IsA("BasePart") and not queued[c] and not isCharPart(c) then
                            push(c)
                            nodeLeader[c] = nodeLeader[cur]
                            nodeSeed[c] = nodeSeed[cur]
                            if c.Anchored and nodeSeed[cur] then
                                anchFound[nodeSeed[cur]] = true
                            end
                            if not selectedSetCache[c] then
                                assemblyExtras[c] = true
                                extraCount += 1
                                killSeatsFor(c)
                            end
                            if extraCount >= CAP then break end
                        end
                    end
                end
            end
        end
        for r in pairs(seenRoots) do
            if selectedSetCache[r] and mateFound[r] then
                rigidRoots[r] = true
            end
            if anchFound[r] then
                assemblyAnchoredCache[r] = true
            end
        end
        local oldExtraRoots = extraRoots
        extraRoots = {}
        for c in pairs(assemblyExtras) do
            local er = getAssemblyRoot(c)
            if er.Parent and not er.Anchored and not selectedSetCache[er] then
                local lead = nodeLeader[c] or nodeLeader[er]
                if lead and lead.Parent and selectedSetCache[lead] then
                    extraRoots[er] = lead
                end
            end
        end
        for er in pairs(oldExtraRoots) do
            if not extraRoots[er] and not selectedSetCache[er] then
                pcall(function()
                    local at = er:FindFirstChild("NetAttach")
                    if at then at:Destroy() end
                end)
            end
        end
    end
end

function scanCapped(root, cap, fn)
    if not (root and root.Parent) then return 0 end
    if type(cap) ~= "number" or cap <= 0 then return 0 end
    if type(fn) ~= "function" then return 0 end
    local n = 0
    local stack = {root}
    while #stack > 0 and n < cap do
        local cur = table.remove(stack)
        local kids = nil
        pcall(function() kids = cur:GetChildren() end)
        if type(kids) == "table" then
            for i = #kids, 1, -1 do
                if n >= cap then break end
                local d = kids[i]
                n += 1
                local okF, done = pcall(fn, d)
                if okF and done == true then return n end
                table.insert(stack, d)
            end
        end
    end
    return n
end

function pruneExtraSeats()
    for seat, m in pairs(disabledExtraSeats) do
        if not seat or not seat.Parent then
            disabledExtraSeats[seat] = nil
        else
            local still = false
            if m and m.Parent then
                for _, p in ipairs(selectedParts) do
                    if p and p.Parent then
                        local okI, isIn = pcall(function() return p:IsDescendantOf(m) end)
                        if okI and isIn then still = true break end
                    end
                end
                if not still then
                    for e in pairs(assemblyExtras) do
                        if e and e.Parent then
                            local okE, isInE = pcall(function() return e:IsDescendantOf(m) end)
                            if okE and isInE then still = true break end
                        end
                    end
                end
            end
            if not still then
                pcall(function() seat.Disabled = false end)
                disabledExtraSeats[seat] = nil
            end
        end
    end
end

function killSeatsFor(part)
    if not (part and part.Parent) then return end
    if seatSweepModels == nil then seatSweepModels = {} end
    local p = part.Parent
    for _ = 1, 3 do
        if not p then break end
        if (p:IsA("Model") or p:IsA("Folder")) and not seatSweepModels[p] then
            seatSweepModels[p] = true
            scanCapped(p, 300, function(d)
                if d:IsA("Seat") or d:IsA("VehicleSeat") then
                    if not d.Disabled then
                        pcall(function() d.Disabled = true end)
                        disabledExtraSeats[d] = p
                    end
                end
            end)
        end
        p = p.Parent
    end
end

function ensureAlign(part)
    if not (part and part.Parent) then return nil, nil end
    local attach = part:FindFirstChild("NetAttach")
    if not attach then
        local ok, att = pcall(function()
            local a = Instance.new("Attachment")
            a.Name = "NetAttach"
            a.Parent = part
            return a
        end)
        if not (ok and att) then return nil, nil end
        attach = att
    end
    local AP = attach:FindFirstChild("NetAP")
    if not AP then
        local ok, ap = pcall(function()
            local a = Instance.new("AlignPosition")
            a.Name = "NetAP"
            a.ApplyAtCenterOfMass = true
            a.Mode = Enum.PositionAlignmentMode.OneAttachment
            a.Attachment0 = attach
            a.Parent = attach
            return a
        end)
        if ok and ap then AP = ap end
    end
    local AO = attach:FindFirstChild("NetAO")
    if not AO then
        local ok, ao = pcall(function()
            local a = Instance.new("AlignOrientation")
            a.Name = "NetAO"
            a.Mode = Enum.OrientationAlignmentMode.OneAttachment
            a.Attachment0 = attach
            a.Parent = attach
            return a
        end)
        if ok and ao then AO = ao end
    end
    return AP, AO
end
function ensureLegacyMovers(part)
    if not (part and part.Parent and part:IsA("BasePart")) then return end
    if part.Anchored then return end
    local hasAP, hasAO = false, false
    pcall(function()
        local att = part:FindFirstChild("NetAttach")
        hasAP = att and att:FindFirstChild("NetAP") ~= nil
        hasAO = att and att:FindFirstChild("NetAO") ~= nil
    end)
    pcall(function()
        local bv = part:FindFirstChild("OwnershipBV")
        if hasAP then
            if bv and bv:IsA("BodyVelocity") then
                bv.MaxForce = Vector3.zero
                bv.Enabled = false
            end
            return
        end
        if not (bv and bv:IsA("BodyVelocity")) then
            if bv then bv:Destroy() end
            bv = Instance.new("BodyVelocity")
            bv.Name = "OwnershipBV"
            bv.Parent = part
        end
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        pcall(function() bv.P = 1e4 end)
        if type(netHoldVelocity) == "function" then
            bv.Velocity = netHoldVelocity()
        else
            bv.Velocity = Vector3.new(17.5555555, 17.5555555, 17.5555555)
        end
    end)
    pcall(function()
        local bg = part:FindFirstChild("OwnershipBG")
        if hasAO then
            if bg and bg:IsA("BodyGyro") then
                bg.MaxTorque = Vector3.zero
                bg.Enabled = false
            end
            return
        end
        if not (bg and bg:IsA("BodyGyro")) then
            if bg then bg:Destroy() end
            bg = Instance.new("BodyGyro")
            bg.Name = "OwnershipBG"
            bg.Parent = part
        end
        bg.P = 9e4
        bg.D = 1000
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        local tgtRot = nil
        pcall(function()
            local t = partTargets and partTargets[part]
            if t then tgtRot = t.rotation end
        end)
        bg.CFrame = tgtRot or part.CFrame
    end)
end

function shouldSkipAssemblyDrive(part)
    if frozenTargets[part] then return false end
    if passengerSet[part] then return true end
    local root = getAssemblyRoot(part)
    if root ~= part then
        local okr, ra = pcall(function() return root.Anchored end)
        if okr and ra then return true end
        if assemblyAnchoredCache[root] then return true end
    else
        if assemblyAnchoredCache[part] then return true end
    end
    return false
end

local function ownerApiState()
    local st, res = pcall(function()
        local oc = ensureOwnerCheck()
        if not oc then return "NONE" end
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not (hrp and hrp.Parent) then return "NOCONTROL" end
        local ohr = oc(hrp)
        if ohr == true then return "OK" end
        if ohr == false then return "BROKEN" end
        return "NONE"
    end)
    if not st then return "BROKEN" end
    return res
end
local function simReceiveAge(part)
    local age = nil
    pcall(function()
        if type(gethiddenproperty) == "function" then
            age = gethiddenproperty(part, "ReceiveAge")
        end
    end)
    if age == nil then
        pcall(function() age = part.ReceiveAge end)
    end
    return age
end
local function weSimulate(part)
    if not (part and part.Parent) then return nil end
    local target = part
    pcall(function()
        local r = getAssemblyRoot(part)
        if r and r.Parent then target = r end
    end)
    if target and target.Parent then
        local okO, owner = pcall(function() return target:GetNetworkOwner() end)
        if okO and owner == LP then return true end
    end
    local age = simReceiveAge(part)
    if age == nil and target ~= part then
        age = simReceiveAge(target)
    end
    if age == nil then return nil end
    return age == 0
end

local function ownSnapshot(part, tag)
    pcall(function()
        local apiS = ownerApiState()
        local ownV, ownBy = nil, "?"
        if apiS == "OK" then
            local oc0 = ensureOwnerCheck()
            if oc0 then
                local ok0, ow0 = pcall(oc0, part)
                if ok0 then ownV = ow0 end
            end
            local okN, ooN = pcall(function() return part:GetNetworkOwner() end)
            if okN then ownBy = (ooN and ooN.Name) or "Server" end
        end
        local ap0 = getNetAP(part)
        local apErr = -1
        if ap0 then pcall(function() apErr = (ap0.Position - part.Position).Magnitude end) end
        local vv = nil
        pcall(function() vv = part.AssemblyLinearVelocity.Magnitude end)
        local pp = nil
        pcall(function() pp = part.Position end)
        print(string.format("[cat-own] %s owned=%s api=%s by=%s ap=%s aperr=%d vel=%d pos=%s", tostring(tag), tostring(ownV), tostring(apiS), tostring(ownBy), tostring(ap0 ~= nil), apErr, vv and math.floor(vv + 0.5) or -1, pp and string.format("%d,%d,%d", pp.X, pp.Y, pp.Z) or "?"))
    end)
end

local function flightIneffective(part, dist)
    if not (part and part.Parent) then return nil end
    if dist < 40 then flightStuck[part] = nil; return nil end
    local now = tick()
    local rec = flightStuck[part]
    if not rec then
        flightStuck[part] = { d = dist, t = now, bad = 0 }
        return nil
    end
    local dt = now - rec.t
    if dt <= 0 then return nil end
    if dist < rec.d - 6 then
        rec.d = dist
        rec.t = now
        rec.bad = 0
        return false
    end
    rec.bad = rec.bad + dt
    rec.t = now
    if dist < rec.d then rec.d = dist end
    if rec.bad > 1.5 then return true end
    return nil
end

function reclaimAssembly(part)
    if not (part and part.Parent) then return end
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    pcall(function() if part.RootPriority ~= 127 then part.RootPriority = 127 end end)
    local root = nil
    pcall(function() root = getAssemblyRoot(part) end)
    if root and root ~= part and root.Parent and not root.Anchored then
        pcall(function() if root.RootPriority ~= 127 then root.RootPriority = 127 end end)
        pcall(sethiddenproperty, root, "NetworkIsSleeping", false)
    end
    if selectedSetCache[part] and (not getNetAP(part) or not getNetAO(part)) then
        pcall(ensureAlign, part)
    end

    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
    local ownedC = false
    pcall(function() ownedC = ownedCached(part) end)
    if not ownedC then
        for _ = 1, 1 do
            pcall(function()
                local ov = part.AssemblyLinearVelocity
                part.AssemblyLinearVelocity = Vector3.new(75000, 75000, 75000)
                part.AssemblyLinearVelocity = ov
            end)
        end
    end
    if selectedSetCache[part] and partTargets[part] then
        local tgt2 = partTargets[part]
        local ap = getNetAP(part)
        if ap then ap.Enabled = true; ap.MaxForce = alignForceFor(part); ap.MaxVelocity = math.huge end
        local ao = getNetAO(part)
        if ao then ao.Enabled = true; ao.MaxTorque = alignForceFor(part); ao.MaxAngularVelocity = math.huge end
        syncAlignTarget(part, tgt2)
    end
end

function rampDensity(part, targetD, fric, elas, dur)
    if not (part and part.Parent and part:IsA("BasePart")) then return end
    if type(targetD) ~= "number" or targetD ~= targetD or targetD <= 0 then return end
    fric = (type(fric) == "number" and fric == fric) and fric or 0
    elas = (type(elas) == "number" and elas == elas) and elas or 0
    dur = (type(dur) == "number" and dur > 0) and dur or 3
    local gen = ((densityRampGen[part] or 0) + 1)
    densityRampGen[part] = gen
    local startD = targetD
    pcall(function()
        local cpp = part.CustomPhysicalProperties
        if cpp and type(cpp.Density) == "number" and cpp.Density == cpp.Density and cpp.Density > 0 then
            startD = cpp.Density
        end
    end)
    if startD == targetD then return end
    local steps = math.clamp(math.floor(dur / 0.25), 2, 24)
    local ratio = targetD / startD
    task.spawn(function()
        for i = 1, steps do
            task.wait(dur / steps)
            if densityRampGen[part] ~= gen then return end
            if not (part and part.Parent) then return end
            local d = startD * (ratio ^ (i / steps))
            pcall(function()
                part.CustomPhysicalProperties = PhysicalProperties.new(d, fric, elas)
            end)
        end
        if densityRampGen[part] ~= gen then return end
        if not (part and part.Parent) then return end
        pcall(function()
            part.CustomPhysicalProperties = PhysicalProperties.new(targetD, fric, elas)
        end)
    end)
end
function stopDensityRamp(part)
    if not part then return end
    densityRampGen[part] = (densityRampGen[part] or 0) + 1
end

local function doUnfreeze(part, keepProps)
    if not part then return end
    frozenTargets[part] = nil
    if keepProps then return end
    pcall(function()
        if strengthenParts then
            rampDensity(part, strengthenDensity, 0.3, 0.5, 3)
        else
            rampDensity(part, 0.001, 0, 0, 3)
        end
    end)
end
function beginUnfreezeHold(part)
    if not (part and part.Parent) then return end
    pcall(function() unfreezeFrom[part] = part.Position end)
    unfreezeBoost[part] = 0
    unfreezeBoostStart[part] = nil
    unfreezeT0[part] = nil
    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    pcall(function() part.RootPriority = 127 end)
    local AP, AO = nil, nil
    pcall(function() AP, AO = ensureAlign(part) end)
    if AP then pcall(function()
        AP.Enabled = true
        AP.MaxForce = alignForceFor(part)
        AP.MaxVelocity = math.huge
        AP.RigidityEnabled = false
        if partTargets[part] and partTargets[part].position then
            AP.Position = partTargets[part].position
        else
            AP.Position = part.Position
        end
    end) end
    if AO then pcall(function()
        AO.Enabled = true
        AO.MaxTorque = alignForceFor(part)
        AO.MaxAngularVelocity = math.huge
        AO.CFrame = part.CFrame
    end) end
    pcall(reclaimAssembly, part)
    local r = nil
    pcall(function() r = getAssemblyRoot(part) end)
    if r and r ~= part then pcall(reclaimAssembly, r) end
    pcall(function()
        part.AssemblyLinearVelocity = netHoldVelocity()
        part.AssemblyAngularVelocity = Vector3.zero
    end)
    pcall(shieldRiders, part)
end
function shieldRiders(part)
    if not (part and part.Parent) then return end
    local last = riderShieldAt[part] or 0
    if tick() - last < 1.0 then return end
    riderShieldAt[part] = tick()
    local old = riderNCCs[part]
    if old then
        for _, c in ipairs(old) do pcall(function() c:Destroy() end) end
        riderNCCs[part] = nil
    end
    local ok, touching = pcall(function() return part:GetTouchingParts() end)
    if not ok or type(touching) ~= "table" then return end
    local list = {}
    local seenT = {}
    for _, t in ipairs(touching) do
        if t and t.Parent and t:IsA("BasePart") and t ~= part and not isSelected(t) then
            local m = t:FindFirstAncestorOfClass("Model")
            local isChar = false
            if m and m ~= LP.Character then
                isChar = m:FindFirstChildOfClass("Humanoid") ~= nil or Players:GetPlayerFromCharacter(m) ~= nil
            end
            if isChar then
                local okN, ncc = pcall(function()
                    local n = Instance.new("NoCollisionConstraint")
                    n.Part0 = part
                    n.Part1 = t
                    n.Parent = part
                    return n
                end)
                if okN and ncc then table.insert(list, ncc) seenT[t] = true end
            end
        end
    end
    local okR, near = pcall(function() return workspace:GetPartBoundsInRadius(part.Position, 12) end)
    if okR and type(near) == "table" then
        for _, t in ipairs(near) do
            if #list >= 60 then break end
            if t and t.Parent and t:IsA("BasePart") and t ~= part and not isSelected(t) and not seenT[t] then
                local m = t:FindFirstAncestorOfClass("Model")
                if m and m ~= LP.Character and (m:FindFirstChildOfClass("Humanoid") ~= nil or Players:GetPlayerFromCharacter(m) ~= nil) then
                    local okN, ncc = pcall(function()
                        local n = Instance.new("NoCollisionConstraint")
                        n.Part0 = part
                        n.Part1 = t
                        n.Parent = part
                        return n
                    end)
                    if okN and ncc then table.insert(list, ncc) seenT[t] = true end
                end
            end
        end
    end
    if #list > 0 then
        riderNCCs[part] = list
    else
        riderShieldAt[part] = nil
    end
end

local function riderStillNear(part)
    if not (part and part.Parent) then return false end
    local near = false
    local rad = partRideRad[part] or 8
    pcall(function() rad = math.max(rad, part.Size.Magnitude * 0.75) end)
    pcall(function()
        local found = workspace:GetPartBoundsInRadius(part.Position, rad)
        for _, t in ipairs(found) do
            if t and t.Parent and t:IsA("BasePart") and t ~= part and not isSelected(t) then
                local m = t:FindFirstAncestorOfClass("Model")
                if m and m ~= LP.Character and (m:FindFirstChildOfClass("Humanoid") ~= nil or Players:GetPlayerFromCharacter(m) ~= nil) then
                    near = true
                    break
                end
            end
        end
    end)
    return near
end

local function clearModeState(prevMode, nextMode)
    isDrawing = false

    if nextMode ~= "Draw" then
        clearDrawDots()
    end
    if nextMode ~= "Slinky" then
        slinkyHistory = {}
    end
    if prevMode ~= "Wall" and nextMode ~= "Wall" then
        _wallCache = nil
    end
    if prevMode == "Satellite" or nextMode ~= "Satellite" then
        satFired = {}
        satTarget = Vector3.zero
        for _, conn in pairs(satTouchConns) do
            pcall(function() conn:Disconnect() end)
        end
        satTouchConns = {}
    end
    if prevMode == "Stickman" or nextMode ~= "Stickman" then
        for _, conn in pairs(stickSlapConns) do
            pcall(function() conn:Disconnect() end)
        end
        stickSlapConns = {}
        stickSlapUntil = 0
        stickWaveUntil = 0
        stickDanceActive = false
        stickCrawlActive = false
        stickMagnetActive = false
        stickTPose = false
        stickBeamActive = false
    end
    if nextMode == "Stickman" then pcall(refreshStickFaceSet) end
    if prevMode == "Minigun" and nextMode ~= "Minigun" then
        minigunIdx = 1
        minigunShotStart = 0
        minigunLastIdx = 0
        minigunAcc = 0
        for p in pairs(minigunFlying) do minigunLand(p, true) end
    end
    if prevMode == "DroneV2" and nextMode ~= "DroneV2" then
        dv2Target = nil
        if dv2TouchConns then
            for p, c in pairs(dv2TouchConns) do pcall(function() c:Disconnect() end) end
            dv2TouchConns = {}
        end
        if prevMode == "DroneV2" then
            for _, part in ipairs(selectedParts) do
                local AP = getNetAP(part)
                if AP then AP.Enabled = true end
                local AO = getNetAO(part)
                if AO then AO.Enabled = true end
            end
        end
    end
    if prevMode == "Homing" and nextMode ~= "Homing" then
        homingTarget = nil
        homingEndTime = 0
        homingLaunchPos = Vector3.zero
        homingFireTime  = 0
        homingDone = {}
        if homingTouchConns then
            for p, c in pairs(homingTouchConns) do pcall(function() c:Disconnect() end) end
            homingTouchConns = {}
        end
        if prevMode == "Homing" then
            for _, part in ipairs(selectedParts) do
                local AP = getNetAP(part)
                if AP then AP.Enabled = true end
                local AO = getNetAO(part)
                if AO then AO.Enabled = true end
            end
        end
    end
    if prevMode == "Railgun" and nextMode ~= "Railgun" then
        railgunChargeStart = 0
        railgunCharging = false
        railgunFired = false
        railgunPhase = "idle"
        railgunPhaseStart = 0
        railgunHitPos = Vector3.zero
        railgunBoomed = false
        railgunHitRegistered = false
        railgunHitTarget = nil
        for part, conn in pairs(railgunTouchConns) do
            pcall(function() conn:Disconnect() end)
            railgunTouchConns[part] = nil
        end
    end
    if prevMode == "Barrage" and nextMode ~= "Barrage" then
        barrageActive = false
    end
    if prevMode == "Lightning" and nextMode ~= "Lightning" then
        lightningFired = {}
        lightningBolt = {}
        lightningBoomed = false
        for p, conn in pairs(lightningTouchConns) do
            pcall(function() conn:Disconnect() end)
        end
        lightningTouchConns = {}
    end
    if prevMode == "Sniper" and nextMode ~= "Sniper" then
        for p, c in pairs(sniperTouchConns) do pcall(function() c:Disconnect() end) end
        sniperTouchConns = {}
    end
    if prevMode == "Boomerang" and nextMode ~= "Boomerang" then
        boomerangActive = false
        for p, c in pairs(boomerangConns) do pcall(function() c:Disconnect() end) end
        boomerangConns = {}
    end
    if prevMode == "Bridge" and nextMode ~= "Bridge" then
        for p in pairs(bridgeSlots) do doUnfreeze(p) end
        bridgeSlots = {}
        bridgeA = nil
        bridgeB = nil
    end
    if prevMode == "Strike" and nextMode ~= "Strike" then
        strikeState = "idle"
        strikeTarget = Vector3.zero
    end
    if prevMode == "Barrage" and nextMode ~= "Barrage" then
        barrageActive = false
    end
    if prevMode == "Scythe" or nextMode ~= "Scythe" then
        if nextMode ~= "Scythe" then
            scytheState = "idle"
            scytheStart = 0
            for p,c in pairs(scytheConns) do pcall(function() c:Disconnect() end) end
            scytheConns = {}
            scytheSwingPos = Vector3.zero
            scytheCenter = Vector3.zero
        end
    end
    if prevMode == "Chained" or nextMode ~= "Chained" then
        if nextMode ~= "Chained" then
            chainedActive = false
            chainedTarget = Vector3.zero
            for p,c in pairs(chainedConns) do pcall(function() c:Disconnect() end) end
            chainedConns = {}
            chainedFired = {}
        end
    end
    if prevMode == "Blackhole" or nextMode ~= "Blackhole" then
        if nextMode ~= "Blackhole" then
            for p,c in pairs(blackholeTouchConns) do pcall(function() c:Disconnect() end) end
            blackholeTouchConns = {}
            blackholeSurgeUntil = 0
        end
    end
    if prevMode == "Text" or nextMode ~= "Text" then
        if textGui then
            textGui.Visible = (nextMode == "Text")
        end
    end
    if nextMode == "Text" and textGui then
        textGui.Visible = true
    elseif textGui then -- help
        if activeMode ~= "Text" and nextMode ~= "Text" then
            textGui.Visible = false
        end
    end

    for _, part in ipairs(selectedParts) do
        if part and part.Parent then
            pcall(function()
                part.AssemblyAngularVelocity = Vector3.zero
            end)
            if partTargets[part] then
                partTargets[part].rotation = part.CFrame
            end
        end
    end
end

local espLabels = {}

local function getPartScreenRect(part)

    local ok, pCFrame, pSize = pcall(function() return part:GetBoundingBox() end) -- IDK WHY I HAVE SO MUCH PCALLS DONT ASK PLS
    local half
    if ok and pCFrame and pSize then
        half = pSize * 0.5
    else
        half = part.Size * 0.5
        pCFrame = part.CFrame
    end

    local localOffsets = {
        Vector3.new(-half.X, -half.Y, -half.Z), Vector3.new(-half.X, -half.Y, half.Z),
        Vector3.new(-half.X, half.Y, -half.Z),  Vector3.new(-half.X, half.Y, half.Z),
        Vector3.new(half.X, -half.Y, -half.Z),  Vector3.new(half.X, -half.Y, half.Z),
        Vector3.new(half.X, half.Y, -half.Z),   Vector3.new(half.X, half.Y, half.Z),
    }

    local minX, minY, maxX, maxY
    local anyVisible = false
    for _, offset in ipairs(localOffsets) do
        local worldPos = pCFrame:PointToWorldSpace(offset)
        local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
        if onScreen and screenPos.Z > 0 then
            anyVisible = true
            minX = minX and math.min(minX, screenPos.X) or screenPos.X
            minY = minY and math.min(minY, screenPos.Y) or screenPos.Y
            maxX = maxX and math.max(maxX, screenPos.X) or screenPos.X
            maxY = maxY and math.max(maxY, screenPos.Y) or screenPos.Y
        end
    end
    return anyVisible, minX, minY, maxX, maxY
end

local function createEspOverlay(part, style)
    style = style or "Label"
    if style == "Box" then
        local tag = Instance.new("Frame")
        tag.Name = "ESP_BOX_" .. part.Name
        tag.Size = UDim2.new(0, 120, 0, 120)
        tag.AnchorPoint = Vector2.new(0.5, 0.5)
        tag.BackgroundTransparency = 1
        tag.BorderSizePixel = 0
        tag.Visible = true
        tag.ZIndex = 20
        tag.Parent = EspScreenGui

        local stroke = Instance.new("UIStroke", tag)
        stroke.Color = GUI.ESP_ACCENT -- my gui has a accent i wonder how it talks now
        stroke.Thickness = 2
        stroke.Transparency = 0

        local corner = Instance.new("UICorner", tag)
        corner.CornerRadius = UDim.new(0, 8)

        return { frame = tag, style = "Box", stroke = stroke }
    end

    local tag = Instance.new("Frame")
    tag.Name = "ESP_" .. part.Name
    tag.Size = UDim2.new(0, 140, 0, 44)
    tag.AnchorPoint = Vector2.new(0.5, 1)
    tag.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    tag.BackgroundTransparency = 0.15
    tag.BorderSizePixel = 0
    tag.Visible = true
    tag.ZIndex = 20
    tag.Parent = EspScreenGui

    Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", tag)
    stroke.Color = GUI.ESP_ACCENT
    stroke.Thickness = 1.2
    stroke.Transparency = 0.15

    local bar = Instance.new("Frame", tag)
    bar.Size = UDim2.new(1, 0, 0, 3)
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = GUI.ESP_ACCENT
    bar.BorderSizePixel = 0
    bar.ZIndex = 21
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 5)

    local nameLbl = Instance.new("TextLabel", tag)
    nameLbl.Name = "Name"
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, -10, 0, 18)
    nameLbl.Position = UDim2.new(0, 5, 0, 6)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextColor3 = GUI.ESP_ACCENT
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex = 22
    nameLbl.Text = part.Name

    local distLbl = Instance.new("TextLabel", tag)
    distLbl.Name = "Dist"
    distLbl.BackgroundTransparency = 1
    distLbl.Size = UDim2.new(1, -10, 0, 14)
    distLbl.Position = UDim2.new(0, 5, 0, 24)
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.TextColor3 = Color3.fromRGB(170, 200, 195)
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.ZIndex = 22
    distLbl.Text = "0 studs"

    local modeLbl = Instance.new("TextLabel", tag)
    modeLbl.Name = "Mode"
    modeLbl.BackgroundTransparency = 1
    modeLbl.Size = UDim2.new(0, 52, 0, 14)
    modeLbl.Position = UDim2.new(1, -57, 0, 6)
    modeLbl.Font = Enum.Font.GothamBold
    modeLbl.TextSize = 9
    modeLbl.TextColor3 = Color3.fromRGB(215, 125, 168)
    modeLbl.TextXAlignment = Enum.TextXAlignment.Right
    modeLbl.ZIndex = 22
    modeLbl.Text = "CTRL"

    return { frame = tag, nameLbl = nameLbl, distLbl = distLbl, modeLbl = modeLbl, style = "Label" }
end

local function weldProxy(part, proxy)
    if not (part and part.Parent and proxy and proxy.Parent) then return end
    proxy.CFrame = part.CFrame
    proxy.Anchored = false
    if not proxy:FindFirstChildOfClass("WeldConstraint") then
        local w = Instance.new("WeldConstraint")
        w.Part0 = part
        w.Part1 = proxy
        w.Parent = proxy
    end
end

local function proxySignature(part)
    local sig = part.ClassName
    pcall(function()
        if part:IsA("Part") then sig = sig .. "|" .. tostring(part.Shape) end
    end)
    pcall(function()
        if part:IsA("MeshPart") then sig = sig .. "|mesh:" .. tostring(part.MeshId) end
    end)
    local sm = part:FindFirstChildOfClass("SpecialMesh")
    if sm then
        sig = sig .. "|sm:" .. tostring(sm.MeshType) .. ":" .. tostring(sm.MeshId)
    end
    return sig
end
local function makeShapeProxy(part)
    local proxy = nil
    local ok, clone = pcall(function() return part:Clone() end)
    if ok and clone and typeof(clone) == "Instance" and clone:IsA("BasePart") then
        proxy = clone
        for _, ch in ipairs(proxy:GetChildren()) do
            local keep = false
            pcall(function()
                keep = ch:IsA("DataModelMesh") or ch:IsA("Decal")
            end)
            if not keep then pcall(function() ch:Destroy() end) end
        end
    else
        if clone and typeof(clone) == "Instance" then pcall(function() clone:Destroy() end) end
        local cls = "Part"
        if part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
            cls = part.ClassName
        end
        proxy = Instance.new(cls)
        pcall(function()
            if proxy:IsA("Part") and part:IsA("Part") then proxy.Shape = part.Shape end
        end)
        pcall(function() proxy.Color = part.Color end)
        local sm = part:FindFirstChildOfClass("SpecialMesh")
        if sm then
            local smCopy = sm:Clone()
            smCopy.Parent = proxy
        end
    end
    proxy.Name = "HLProxy"
    proxy.Anchored = false
    if fakeCollisions and collisionMode == "partial" then
        proxy.CanCollide = true
    else
        proxy.CanCollide = false
    end
    proxy.CanTouch = false
    proxy.CanQuery = false
    proxy:GetPropertyChangedSignal("CanQuery"):Connect(function()
        if proxy.CanQuery then
            pcall(function() proxy.CanQuery = false end)
        end
    end)
    proxy.CastShadow = false
    proxy.Locked = true
    proxy.Massless = true
    proxy.Transparency = 0.95
    proxy.Material = Enum.Material.SmoothPlastic
    local ps = part.Size
    proxy.Size = Vector3.new(
        math.max(ps.X, 0.05),
        math.max(ps.Y, 0.05),
        math.max(ps.Z, 0.05)
    )
    proxy.CFrame = part.CFrame
    pcall(function() proxy:SetAttribute("SrcSig", proxySignature(part)) end)
    return proxy
end
local function dropProxiesForMode()
    for part, proxy in pairs(selectionProxyParts) do
        if proxy and typeof(proxy) == "Instance" then pcall(function() proxy:Destroy() end) end
    end
end
local function ensureProxy(part)
    local proxy = selectionProxyParts[part]
    local wantSig = proxySignature(part)
    local haveSig = nil
    if proxy then pcall(function() haveSig = proxy:GetAttribute("SrcSig") end) end
    if proxy and proxy.Parent and haveSig == wantSig then return proxy end
    if proxy then pcall(function() proxy:Destroy() end) end
    proxy = makeShapeProxy(part)
    proxy.Parent = selectionProxyModel
    selectionProxyParts[part] = proxy
    return proxy
end

local function addHL(part)
    if highlights[part] then return end

    if useESP then
        local tag = createEspOverlay(part, espStyle)
        espLabels[part] = tag
        highlights[part] = tag.frame
    else
        if not selectionProxyModel or not selectionProxyModel.Parent then
            selectionProxyModel = Instance.new("Model")
            selectionProxyModel.Name = "CatalystSelectionProxy"
            selectionProxyModel.Parent = workspace

            local hum = Instance.new("Humanoid")
            hum.Name = "ProxyHumanoid"
            hum.Parent = selectionProxyModel

            selectionProxyHighlight = Instance.new("Highlight")
            selectionProxyHighlight.Name = "CatalystSelectionHighlight"
            selectionProxyHighlight.Adornee = selectionProxyModel
            selectionProxyHighlight.Parent = selectionProxyModel
            refreshAllHighlights()
        end

        local proxy = ensureProxy(part)

        proxy.CFrame = part.CFrame
        proxy.Size = Vector3.new(
            math.max(part.Size.X, 0.05),
            math.max(part.Size.Y, 0.05),
            math.max(part.Size.Z, 0.05)
        )
        weldProxy(part, proxy)
        highlights[part] = true
    end
end

refreshAllHighlights = function()
    for part, hl in pairs(highlights) do
        local tag = espLabels[part]
        if tag and tag.frame then
            local stroke = tag.frame:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = GUI.ESP_ACCENT
            end
            if tag.nameLbl then
                tag.nameLbl.TextColor3 = GUI.ESP_ACCENT
            end
        elseif typeof(hl) == "Instance" and hl:IsA("Highlight") then
            hl.FillColor           = HL.fillColor
            hl.OutlineColor        = HL.outlineColor
            hl.FillTransparency    = HL.fillTransparency
            hl.OutlineTransparency = HL.outlineTransparency
            hl.DepthMode           = HL.depthMode
        end
    end

    if selectionProxyHighlight and selectionProxyHighlight.Parent then
        selectionProxyHighlight.FillColor = HL.fillColor
        selectionProxyHighlight.OutlineColor = HL.outlineColor
        selectionProxyHighlight.FillTransparency = HL.fillTransparency
        selectionProxyHighlight.OutlineTransparency = HL.outlineTransparency
        selectionProxyHighlight.DepthMode = HL.depthMode
    end
end

local function removeHL(part)
    if highlights[part] then
        local hl = highlights[part]
        if typeof(hl) == "Instance" then
            hl:Destroy()
        end
        highlights[part] = nil
        espLabels[part] = nil
    end

    local proxy = selectionProxyParts[part]
    if proxy then
        pcall(function() proxy:Destroy() end)
        selectionProxyParts[part] = nil
    end

    if selectionProxyModel and not next(selectionProxyParts) then
        if selectionProxyHighlight then
            pcall(function() selectionProxyHighlight:Destroy() end)
            selectionProxyHighlight = nil
        end
        pcall(function() selectionProxyModel:Destroy() end)
        selectionProxyModel = nil
    end
end

local function syncSelectionProxyModel()
    if useESP then
        if selectionProxyHighlight then
            pcall(function() selectionProxyHighlight:Destroy() end)
            selectionProxyHighlight = nil
        end
        if selectionProxyModel then
            pcall(function() selectionProxyModel:Destroy() end)
            selectionProxyModel = nil
        end
        selectionProxyParts = {}
        return
    end

    for part, proxy in pairs(selectionProxyParts) do
        if not highlights[part] then
            if proxy and typeof(proxy) == "Instance" then pcall(function() proxy:Destroy() end) end
            selectionProxyParts[part] = nil
        elseif not part or not part.Parent then
            if proxy and typeof(proxy) == "Instance" then pcall(function() proxy:Destroy() end) end
            selectionProxyParts[part] = false
        else
            proxy = ensureProxy(part)
            if proxy.Anchored or not proxy:FindFirstChildOfClass("WeldConstraint") then
                weldProxy(part, proxy)
            end
            local ps = part.Size
            if proxy.Size.X ~= ps.X or proxy.Size.Y ~= ps.Y or proxy.Size.Z ~= ps.Z then
                proxy.Size = Vector3.new(
                    math.max(ps.X, 0.05),
                    math.max(ps.Y, 0.05),
                    math.max(ps.Z, 0.05)
                )
            end
        end
    end

    if selectionProxyModel and not next(selectionProxyParts) then
        if selectionProxyHighlight then
            pcall(function() selectionProxyHighlight:Destroy() end)
            selectionProxyHighlight = nil
        end
        pcall(function() selectionProxyModel:Destroy() end)
        selectionProxyModel = nil
    end
end


local function addNpcHighlight(model, color)
    if not model or npcHighlights[model] then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = model
    hl.FillColor = color or Color3.fromRGB(255, 100, 100)
    hl.OutlineColor = color or Color3.fromRGB(255, 100, 100)
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
    npcHighlights[model] = hl
end

local function removeNpcHighlight(model)
    if npcHighlights[model] then
        npcHighlights[model]:Destroy()
        npcHighlights[model] = nil
    end
end


local function updateSpcHighlight(part)
    if spcHighlight then
        spcHighlight:Destroy()
        spcHighlight = nil
    end
    if part and part.Parent then
        local hl = Instance.new("Highlight")
        hl.Adornee = part
        hl.FillColor = Color3.fromRGB(100, 200, 255)
        hl.OutlineColor = Color3.fromRGB(100, 200, 255)
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = part
        spcHighlight = hl
    end
end

spcSavedRootPri = nil

local function dropSpcPart(zeroVel)
    local p = spcPart
    spcPart = nil
    updateSpcHighlight(nil)
    if not p then return end
    mouseExcludeRemove(p)
    unlinkNoCollide(p)
    pcall(function()
        if zeroVel and p.Parent then
            p.AssemblyLinearVelocity = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
        local at = p:FindFirstChild("NetAttach")
        if at then at:Destroy() end
        if spcSavedRootPri ~= nil and p.Parent then
            p.RootPriority = spcSavedRootPri
        end
        pcall(sethiddenproperty, p, "NetworkIsSleeping", false)
    end)
    spcSavedRootPri = nil
end

local function grabSpcPart(part)
    if spcPart and spcPart ~= part then dropSpcPart(false) end
    spcPart = part
    mouseExcludeAdd(part)
    updateSpcHighlight(part)
    spcSavedRootPri = nil
    pcall(function() spcSavedRootPri = part.RootPriority end)
    pcall(function() part.RootPriority = 127 end)
    killSeatsFor(part)
    linkNoCollide(part)
    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
end

local function updateESP()
    if not next(espLabels) then return end

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = root and root.Position or Camera.CFrame.Position
    local inset = GuiService:GetGuiInset()

    for part, tag in pairs(espLabels) do
        local frame = tag.frame
        if not part or not part.Parent then
            espLabels[part] = nil
            if frame then pcall(function() frame:Destroy() end) end
        elseif frame then
            if tag.style == "Box" then
                local visible, minX, minY, maxX, maxY = getPartScreenRect(part)
                if visible and minX and minY and maxX and maxY then
                    frame.Visible = true
                    frame.Size = UDim2.fromOffset(math.max(10, maxX - minX + 8), math.max(10, maxY - minY + 8))
                    local centerX = (minX + maxX) * 0.5
                    local centerY = (minY + maxY) * 0.5
                    frame.Position = UDim2.fromOffset(centerX, centerY)
                else
                    frame.Visible = false
                end
            else
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    frame.Visible = true
                    frame.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
                    local dist = (part.Position - myPos).Magnitude
                    tag.distLbl.Text = string.format("%.0f studs", dist)
                    local pName = part.Parent and part.Parent:IsA("Model") and part.Parent.Name or part.Name
                    tag.nameLbl.Text = pName:sub(1, 18)
                    tag.modeLbl.Text = activeMode:sub(1, 6)
                else
                    frame.Visible = false
                end
            end
        end
    end
end

local function isPlayerPart(part)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and part:IsDescendantOf(plr.Character) then
            return true
        end
    end
    if part.Name == "Head" then
        return true
    end
    local parentModel = part:FindFirstAncestorOfClass("Model")
    if parentModel and parentModel:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end
local function isLocalPlayerPart(part)
    if not part then return false end
    if LP.Character and part:IsDescendantOf(LP.Character) then return true end
    local m = part:FindFirstAncestorOfClass("Model")
    if m and Players:GetPlayerFromCharacter(m) == LP then return true end
    return false
end

local function isVelImmune(obj)
    if not obj or not obj:IsA("BasePart") then return true end
    if obj == workspace.Terrain then return true end
    if obj.Anchored then return true end
    local ok, isHuge = pcall(function() return obj.AssemblyMass == math.huge end)
    if ok and isHuge then return true end
    return false
end

local function isVelImmuneChain(obj)
    local cur = obj
    local steps = 0
    while cur and steps < 20 do
        if isVelImmune(cur) then return true end
        cur = cur.Parent
        steps += 1
    end
    return false
end

local function doFreeze(part, pos)
    if not part or not part:IsA("BasePart") then return end
    frozenTargets[part] = pos
    pcall(function()
        if not partPhysProperties[part] then partPhysProperties[part] = {CustomPhysicalProperties = part.CustomPhysicalProperties} end
        rampDensity(part, 0.7, 0, 0, 3)
    end)
end

local function refreshStickFaceSet()
    stickFaceSet = {}
    local total = #selectedParts
    if total < 50 then return end
    local candidates = {}
    for idx, p in ipairs(selectedParts) do
        local u = total > 1 and (idx - 1) / (total - 1) or 0
        if u < 0.37 then
            table.insert(candidates, p)
        end
    end
    if #candidates == 0 then
        candidates = selectedParts
    end
    local sorted = {}
    for _, p in ipairs(candidates) do table.insert(sorted, p) end
    table.sort(sorted, function(a,b)
        local ok1, s1 = pcall(function() return a.Size.Magnitude end)
        local ok2, s2 = pcall(function() return b.Size.Magnitude end)
        if ok1 and ok2 then return s1 < s2 end
        return false
    end)
    local n = math.min(10, #sorted)
    for i = 1, n do stickFaceSet[sorted[i]] = i end
end
stickBodyRank = {}
stickBodyCount = 0
local function rebuildStickBodyRanks()
    refreshStickFaceSet()
    stickBodyRank = {}
    local order = {}
    for _, p in ipairs(selectedParts) do
        if p and p.Parent and not stickFaceSet[p] then
            table.insert(order, p)
        end
    end
    local n = #order
    stickBodyCount = n
    if n == 0 then return end
    local function buOf(r) return n > 1 and (r - 1) / (n - 1) or 0 end
    for r, p in ipairs(order) do stickBodyRank[p] = r end
    if n >= 4 then
        for _, half in ipairs({{0.37, 0.55}, {0.55, 0.73}}) do
            local members, slots = {}, {}
            for r, p in ipairs(order) do
                local b = buOf(r)
                if b >= half[1] and b < half[2] then
                    table.insert(members, p)
                    table.insert(slots, b)
                end
            end
            if #members > 1 then
                table.sort(slots)
                table.sort(members, function(a, b)
                    local sa, sb = 0, 0
                    pcall(function() sa = a.Size.Magnitude end)
                    pcall(function() sb = b.Size.Magnitude end)
                    return sa > sb
                end)
                for i, p in ipairs(members) do
                    stickBodyRank[p] = slots[#slots - i + 1] * (n - 1) + 1
                end
            end
        end
    end
end

local function getNearestNPC(fromPos, maxDist)
    local best, bestDist = nil, maxDist + 1
    local function check(model)
        if model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
            local d = (model:FindFirstChild("HumanoidRootPart").Position - fromPos).Magnitude
            if d < bestDist then best = model; bestDist = d end
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LP.Character then check(obj) end
        if (obj:IsA("Model") or obj:IsA("Folder")) then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Model") and child ~= LP.Character then check(child) end
            end
        end
    end
    return best
end
assemblyGhosted = {}
colAsmCache = {}
local function disableAssemblyCollision(root)
    if not fakeCollisions then return end
    if not (root and root.Parent and root:IsA("BasePart")) then return end
    local nowC = tick()
    if colAsmCache[root] and nowC - colAsmCache[root] < 1 then return end
    colAsmCache[root] = nowC
    local ok, mates = pcall(function() return root:GetConnectedParts(true) end)
    if not ok or type(mates) ~= "table" then return end
    for _, m in ipairs(mates) do
        if m ~= root and m.Parent and m:IsA("BasePart")
            and not m.Anchored and not isPlayerPart(m) and not isVelImmune(m) then
            if collisionMode == "partial" then
                if partCollisionState[m] == nil then
                    partCollisionState[m] = (m.CanCollide ~= false)
                end
                if partCollisionConns[m] then
                    pcall(function() partCollisionConns[m]:Disconnect() end)
                    partCollisionConns[m] = nil
                end
                if m.Parent then m.CanCollide = true end
            else
                pcall(disableSelectedCollision, m)
            end
            assemblyGhosted[m] = root
        end
    end
end
local function restoreAssemblyCollision(onlyRoot)
    for m, owner in pairs(assemblyGhosted) do
        if onlyRoot == nil or owner == onlyRoot then
            assemblyGhosted[m] = nil
            if m and not isSelected(m) then
                pcall(restoreSelectedCollision, m)
            end
        end
    end
end
local function refreshAllCollisionState()
    for _, part in ipairs(selectedParts) do
        if part and part.Parent then restoreSelectedCollision(part) end
    end
    restoreAssemblyCollision(nil)
    if fakeCollisions then
        for _, part in ipairs(selectedParts) do
            if part and part.Parent then
                pcall(function() disableSelectedCollision(part) end)
                pcall(function() disableAssemblyCollision(part) end)
            end
        end
        if spcPart and spcPart.Parent then linkNoCollide(spcPart) end
    else
        if spcPart and spcPart.Parent then linkNoCollide(spcPart) end
    end
    dropProxiesForMode()
end
lightenedParts = lightenedParts or {}
local function lightenAssemblyMass(root)
    if not (root and root.Parent and root:IsA("BasePart")) then return end
    local ok, mates = pcall(function() return root:GetConnectedParts(true) end)
    if not (ok and type(mates) == "table") then return end
    local asmMass = nil
    pcall(function() asmMass = root.AssemblyMass end)
    local isHeavy = asmMass and asmMass == asmMass and asmMass ~= math.huge
        and type(HEAVY_ASSIST_MASS) == "number" and asmMass >= HEAVY_ASSIST_MASS
    local dens = 0.001
    pcall(function() if strengthenParts then dens = strengthenDensity end end)
    for _, m in ipairs(mates) do
        if m and m ~= root and m.Parent and m:IsA("BasePart") and not m.Anchored
            and not isPlayerPart(m) and lightenedParts[m] == nil and not isSelected(m) then
            local rec = { ncc = true, props = nil, massless = nil }
            if isHeavy then
                local saved = nil
                local okP = pcall(function() saved = m.CustomPhysicalProperties end)
                if okP then rec.props = saved end
                pcall(function()
                    m.CustomPhysicalProperties = PhysicalProperties.new(dens, 0, 0, 0, 0)
                end)
                local okM = pcall(function() rec.massless = m.Massless end)
                if okM then
                    pcall(function() m.Massless = true end)
                end
            end
            lightenedParts[m] = rec
            pcall(linkNoCollide, m)
        end
    end
end
local function restoreLightenedMass(root)
    if lightenedParts == nil then return end
    local targets = {}
    if root and root.Parent and root:IsA("BasePart") then
        targets[1] = root
        local ok, mates = pcall(function() return root:GetConnectedParts(true) end)
        if ok and type(mates) == "table" then
            for _, m in ipairs(mates) do targets[#targets + 1] = m end
        end
    else
        for m in pairs(lightenedParts) do targets[#targets + 1] = m end
    end
    for _, m in ipairs(targets) do
        local rec = (m and lightenedParts[m]) or nil
        if rec then
            lightenedParts[m] = nil
            if rec.props ~= nil then
                pcall(function()
                    if m and m.Parent then m.CustomPhysicalProperties = rec.props end
                end)
            end
            if rec.massless ~= nil then
                pcall(function()
                    if m and m.Parent then m.Massless = rec.massless end
                end)
            end
            if m and m ~= root and not isSelected(m) then
                pcall(unlinkNoCollide, m)
            end
        end
    end
end
local function setCollisionMode(m)
    if collisionMode == m then return end
    collisionMode = m
    refreshAllCollisionState()
end
if _G._catAssemblyGhostConn then
    pcall(function() _G._catAssemblyGhostConn:Disconnect() end)
    _G._catAssemblyGhostConn = nil
end
do
    _G._catAssemblyGhostSweep = true
    local ghostAcc = 0
    _G._catAssemblyGhostConn = RunService.Heartbeat:Connect(function(dt)
        if not fakeCollisions then return end
        ghostAcc += dt or 0
        if ghostAcc < 5.5 then return end
        ghostAcc = 0
        if #selectedParts == 0 then return end
        for _, part in ipairs(selectedParts) do
            if part and part.Parent and not part.Anchored then
                pcall(disableAssemblyCollision, part)
            end
        end
    end)
end
local function spinDriveProps(obj)
    local cls = obj.ClassName
    if cls == "AngularVelocity" or cls == "BodyAngularVelocity" then
        return {"AngularVelocity"}
    elseif cls == "Torque" then
        return {"Torque"}
    elseif cls == "BodyGyro" then
        return {"MaxTorque"}
    elseif cls == "BodyPosition" then
        return {"MaxForce", "Position"}
    elseif cls == "BodyVelocity" then
        return {"MaxForce", "Velocity"}
    elseif cls == "VectorForce" or cls == "LineForce" then
        return {"Force"}
    elseif cls == "BodyThrust" then
        return {"Force"}
    elseif cls == "Motor" then
        return {"MaxVelocity"}
    elseif cls == "HingeConstraint" or cls == "PrismaticConstraint" or cls == "CylindricalConstraint" then
        return {"ActuatorType"}
    elseif cls == "AlignOrientation" or cls == "AlignPosition" then
        if obj.Name == "NetAP" or obj.Name == "NetAO" then return nil end
        local par = obj.Parent
        if par and par.Name == "NetAttach" then return nil end
        return {"Responsiveness"}
    end
    return nil
end
local function neutralizeSpinDrivers(part)
    if not (part and part.Parent and part:IsA("BasePart")) then return end
    if partSpinSaved[part] then return end
    local saved = {}
    local found = 0
    local seen = {}
    local linkQueue = {}
    local function consider(obj)
        if not (obj and obj.Parent) then return end
        if seen[obj] then return end
        seen[obj] = true
        local ccl = obj.ClassName
        if ccl == "HingeConstraint" or ccl == "PrismaticConstraint" or ccl == "CylindricalConstraint" then
            for _, an in ipairs({"Attachment0", "Attachment1"}) do
                pcall(function()
                    local at = obj[an]
                    local pp = at and at.Parent
                    if pp and pp ~= obj and typeof(pp) == "Instance" and pp:IsA("BasePart") then
                        table.insert(linkQueue, pp)
                    end
                end)
            end
        end
        local nm = obj.Name
        if nm == "OwnershipBV" or nm == "OwnershipBG" or nm == "ServerResponse" or nm == "ServerResponse2" or nm == "NetAP" or nm == "NetAO" then return end
        local par0 = obj.Parent
        if par0 and par0.Name == "NetAttach" then return end
        local okJ, isJ = pcall(function() return obj:IsA("JointInstance") end)
        if okJ and isJ and (string.find(obj.ClassName, "Rotate") or obj.Name == "Rotate") then
            local okE, ev = pcall(function() return obj.Enabled end)
            if okE then
                table.insert(saved, { obj = obj, vals = { Enabled = ev } })
                found += 1
            end
            return
        end
        local props = spinDriveProps(obj)
        if props == nil then return end
        local entry = { obj = obj, vals = {} }
        local touched = false
        for _, pr in ipairs(props) do
            local ok, v = pcall(function() return obj[pr] end)
            if ok then
                entry.vals[pr] = v
                touched = true
            end
        end
        if not touched then return end
        found += 1
        table.insert(saved, entry)
    end
    consider(part)
    for _, d in ipairs(part:GetDescendants()) do
        consider(d)
    end
    local seenJ = {}
    local okC, mates = pcall(function() return part:GetConnectedParts(true) end)
    if okC and type(mates) == "table" and #mates <= 300 then
        local n = 0
        for _, m in ipairs(mates) do
            if n >= 300 then break end
            if m and m.Parent then
                local okJ2, joints = pcall(function() return m:GetJoints() end)
                if okJ2 and type(joints) == "table" then
                    for _, j in ipairs(joints) do
                        if j and not seenJ[j] then
                            seenJ[j] = true
                            consider(j)
                        end
                    end
                end
                local okDs, dss = pcall(function() return m:GetDescendants() end)
                if okDs and type(dss) == "table" then
                    for _, dd in ipairs(dss) do
                        consider(dd)
                    end
                end
                n += 1
            end
        end
    end
    local seenM = {}
    local p0 = part.Parent
    for _ = 1, 3 do
        if not p0 then break end
        if (p0:IsA("Model") or p0:IsA("Folder")) and not seenM[p0] then
            seenM[p0] = true
            scanCapped(p0, 300, consider)
        end
        p0 = p0.Parent
    end
    local chased = {}
    local chaseN = 0
    for _, lp in ipairs(linkQueue) do
        if chaseN >= 100 then break end
        if lp and lp.Parent and lp:IsA("BasePart") and not chased[lp] then
            chased[lp] = true
            chaseN += 1
            consider(lp)
            local okD, ds = pcall(function() return lp:GetDescendants() end)
            if okD and type(ds) == "table" then
                for _, dd in ipairs(ds) do
                    consider(dd)
                end
            end
        end
    end
    for _, entry in ipairs(saved) do
        local obj = entry.obj
        if obj and obj.Parent then
            for pr, _ in pairs(entry.vals) do
                if pr == "Enabled" then
                    pcall(function() obj.Enabled = false end)
                elseif pr == "Disabled" then
                    pcall(function() obj.Disabled = true end)
                elseif pr == "Responsiveness" then
                    pcall(function() obj.Responsiveness = 0 end)
                elseif pr == "MaxTorque" then
                    pcall(function() obj.MaxTorque = 0 end)
                elseif pr == "ActuatorType" then
                    pcall(function() obj.ActuatorType = Enum.ActuatorType.None end)
                else
                    pcall(function()
                        local cur = obj[pr]
                        if typeof(cur) == "Vector3" then
                            obj[pr] = Vector3.zero
                        elseif typeof(cur) == "number" then
                            obj[pr] = 0
                        end
                    end)
                end
            end
        end
    end
    if found > 0 then
        partSpinSaved[part] = saved
    end
end
local function restoreSpinDrivers(part)
    local saved = partSpinSaved and partSpinSaved[part]
    if saved then
        partSpinSaved[part] = nil
        for _, entry in ipairs(saved) do
            local obj = entry.obj
            if obj and obj.Parent then
                for pr, v in pairs(entry.vals) do
                    pcall(function() obj[pr] = v end)
                end
            end
        end
    end
end
local function resolveAssemblyRoot(part, allowAnchored)
    if not (part and typeof(part) == "Instance" and part:IsA("BasePart")) then return part end
    if part.Anchored and not allowAnchored then return part end
    local ok, root = pcall(function() return part:GetRootPart() end)
    if ok and root and root ~= part and root:IsA("BasePart") and root.Parent
        and root ~= workspace.Terrain and not isPlayerPart(root)
        and (allowAnchored or not root.Anchored) then
        return root
    end
    return part
end
local function selectPart(part, allowAnchored)
    if not part or not part:IsA("BasePart") then return end
    if part==workspace.Terrain then return end
    if isPlayerPart(part) then return end
    if useLimits and #selectedParts >= math.max(1, math.floor(partLimit or 1)) then return end
    if not sizeFilterPass(part) then return end
    local clicked = part
    if not part.Anchored or allowAnchored then
        local root = resolveAssemblyRoot(part, allowAnchored)
        if root ~= part then
            if isSelected(root) then return end
            part = root
        end
    end
    if part.Anchored then
        local freeRoot = nil
        if clicked and clicked.Parent and not clicked.Anchored then
            pcall(neutralizeSpinDrivers, clicked)
            local okR, rr = pcall(function() return clicked:GetRootPart() end)
            if okR and rr and rr.Parent and rr:IsA("BasePart") and not rr.Anchored then freeRoot = rr end
            if not freeRoot then pcall(restoreSpinDrivers, clicked) end
        end
        if freeRoot then
            if partSpinSaved[clicked] and not partSpinSaved[freeRoot] then
                partSpinSaved[freeRoot] = partSpinSaved[clicked]
                partSpinSaved[clicked] = nil
            end
            if isSelected(freeRoot) then return end
            part = freeRoot
        elseif tick() - (groundToastAt or 0) > 3 then
            groundToastAt = tick()
            toast("assembly grounded - anchored, cannot move")
        end
    end
    if part.Anchored and not allowAnchored then return end
    if isSelected(part) then return end
    do
        local okR, newRoot = pcall(function() return part:GetRootPart() end)
        local okM, mates = pcall(function() return part:GetConnectedParts(true) end)
        local hasMates = okM and type(mates) == "table"
        if (okR and newRoot and newRoot.Parent) or hasMates then
            for _, s in ipairs(selectedParts) do
                if s and s.Parent and s ~= part then
                    local shared = false
                    if okR and newRoot and newRoot.Parent then
                        local okS, sRoot = pcall(function() return s:GetRootPart() end)
                        if okS and sRoot == newRoot then shared = true end
                    end
                    if not shared and hasMates then
                        for _, m in ipairs(mates) do
                            if m == s then shared = true break end
                        end
                    end
                    if shared then return end
                end
            end
        end
        if hasMates then
            local anchoredN = 0
            for _, m in ipairs(mates) do
                if m ~= part then
                    local okA, an = pcall(function() return m.Anchored end)
                    if okA and an then anchoredN += 1 end
                end
            end
            if anchoredN > 0 and tick() - (groundToastAt or 0) > 3 then
                groundToastAt = tick()
                toast("assembly grounded - " .. anchoredN .. " anchored parts")
            end
            if anchoredN > 0 and not allowAnchored then return end
        end
        if not allowAnchored then
            local okH, hugeM = pcall(function() return part.AssemblyMass == math.huge end)
            if okH and hugeM then
                if tick() - (groundToastAt or 0) > 3 then
                    groundToastAt = tick()
                    toast("assembly grounded - infinite mass, cannot move")
                end
                return
            end
        end
    end
local r=math.random

    local spreadX = formSizeX
    local spreadZ = formSizeZ
    local liftY   = formSizeY
    partOffsets[part]=Vector3.new(
        (r()-.5)*0.4*spreadX,
        (r()-.5)*0.4*liftY,
        (r()-.5)*0.4*spreadZ
    )
    partOffsetScale[part]=Vector3.new(spreadX, liftY, spreadZ)
    table.insert(selectedParts,part)
    selectedSetCache[part] = true
    mouseExcludeAdd(part)
    addHL(part)
    if partDestroyingConns[part] then pcall(function() partDestroyingConns[part]:Disconnect() end) end
    partTrulyGone[part] = nil
    partDestroyingConns[part] = part.Destroying:Connect(function()
        partTrulyGone[part] = true
    end)
    if not partPhysProperties[part] then
        partPhysProperties[part] = {
            CustomPhysicalProperties = part.CustomPhysicalProperties
        }
    end
    if partPhysProperties[part].RootPriority == nil then
        pcall(function()
            partPhysProperties[part].RootPriority = part.RootPriority
        end)
    end
    pcall(function()
        rampDensity(part, 0.001, 0, 0, 3)
        part.CanQuery = true
    end)
    pcall(function() if part.RootPriority ~= 127 then part.RootPriority = 127 end end)
    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
    pcall(ensureLegacyMovers, part)
    
    if strengthenParts then
        pcall(function()
            rampDensity(part, strengthenDensity, 0.3, 0.5, 3) -- part.customphysicalproperties = killbrick = true
        end)
    end
    pcall(function() disableSelectedCollision(part) end)
    pcall(function() disableAssemblyCollision(part) end)
    pcall(linkNoCollide, part)
    pcall(lightenAssemblyMass, part)
    if not canQuerySweepPending then
        canQuerySweepPending = true
        task.defer(function()
            canQuerySweepPending = false
            pcall(runCanQuerySweep)
        end)
    end
    local seat = part:FindFirstChildOfClass("Seat")
    if seat then
        seat.Disabled = true
    end
    if part:IsA("Seat") then
        part.Disabled = true
    end
    killSeatsFor(part)
    pcall(neutralizeSpinDrivers, part)

    if partTouchConns[part] then pcall(function() partTouchConns[part]:Disconnect() end) partTouchConns[part] = nil end
    partTouchConns[part] = part.Touched:Connect(function(hit)
        reclaimOnTouch(part, hit)
    end)
    

pcall(function()

        local oldBP = part:FindFirstChild("NetBP")
        if oldBP then oldBP:Destroy() end
        local oldBG = part:FindFirstChild("NetBG")
        if oldBG then oldBG:Destroy() end
        local oldAP = part:FindFirstChild("NetAP")
        if oldAP then oldAP:Destroy() end
        local oldAO = part:FindFirstChild("NetAO")
        if oldAO then oldAO:Destroy() end
        local oldAtt = part:FindFirstChild("NetAttachment")
        if oldAtt then oldAtt:Destroy() end

        local attach = part:FindFirstChild("NetAttach")
        if not attach then
            attach = Instance.new("Attachment", part)
            attach.Name = "NetAttach"
        end

        local AP = attach:FindFirstChild("NetAP")
        if not AP then
            AP = Instance.new("AlignPosition", attach)
            AP.Name = "NetAP"
        end
        AP.ApplyAtCenterOfMass = true
        AP.Mode = Enum.PositionAlignmentMode.OneAttachment
        AP.Position = part.Position
        AP.MaxForce = alignForceFor(part)
        AP.MaxVelocity = math.huge
        AP.Responsiveness = math.huge
        AP.RigidityEnabled = false
        AP.Attachment0 = attach

        local AO = attach:FindFirstChild("NetAO")
        if not AO then
            AO = Instance.new("AlignOrientation", attach)
            AO.Name = "NetAO"
        end
        AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        AO.RigidityEnabled = true
        AO.MaxTorque = alignForceFor(part)
        AO.MaxAngularVelocity = math.huge
        AO.Responsiveness = math.huge
        AO.CFrame = part.CFrame
        AO.Attachment0 = attach
        for _, name in ipairs({"ServerResponse", "ServerResponse2"}) do
            local response = part:FindFirstChild(name)
            if not response then
                response = Instance.new("BodyForce")
                response.Name = name
                response.Parent = part
            end
            if response:IsA("BodyForce") then
                local sm = part.AssemblyMass
                if sm == sm and sm ~= math.huge then
                    local isH = sm >= (HEAVY_ASSIST_MASS or 1500)
                    local compFactor = isH and 0 or (sm > 100 and 1.0 or 0.08)
                    response.Force = Vector3.new(0, sm * workspace.Gravity * compFactor, 0)
                end
            end
        end

        if not partTargets[part] then
            partTargets[part] = {
                position = part.Position,
                rotation = part.CFrame,
                responsiveness = getMoveResponsiveness(1),
            }
        end
        syncAlignTarget(part, partTargets[part])
    end)
    if activeMode == "Stickman" then pcall(refreshStickFaceSet) end
    releasedSet[part] = nil
    frozenTargets[part] = nil
    assemblyDirtyAt = tick()
    if not asmRebuildPending then
        asmRebuildPending = true
        task.defer(function()
            asmRebuildPending = false
            pcall(rebuildAssemblyCache, true)
        end)
    end
    toastSelectionSoon()
end

local function cleanupPartState(part, destroyPart)
    if not part then return end
    pcall(restoreDragGhost)
    selectedSetCache[part] = nil
    ownVerdict[part] = nil
    ownVerdictAt[part] = nil
    unlinkNoCollide(part)
    releasedSet[part] = true
    anchoredNoted[part] = nil
    reclaimTouchAt[part] = nil
    seatPin[part] = nil
    if riderNCCs[part] then
        for _, c in ipairs(riderNCCs[part]) do pcall(function() c:Destroy() end) end
        riderNCCs[part] = nil
    end
    riderShieldAt[part] = nil
    mouseExcludeRemove(part)
    partMissingSince[part] = nil
    partTrulyGone[part] = nil
    if partDestroyingConns[part] then pcall(function() partDestroyingConns[part]:Disconnect() end) partDestroyingConns[part] = nil end
    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
    partTargets[part] = nil
    networkRuleApplied[part] = nil
    partOffsets[part] = nil
    partOffsetScale[part] = nil
    doUnfreeze(part, true)
    unfreezeBoost[part] = nil
    unfreezeT0[part] = nil
    partRideRad[part] = nil
    unfreezeFrom[part] = nil
    unfreezeBoostStart[part] = nil
    ownCheckAt[part] = nil
    reholdToastAt[part] = nil
    flightStuck[part] = nil
    flightTgt[part] = nil
    reholdCount[part] = nil
    fallSuspect[part] = nil
    holdLoud[part] = nil
    satFired[part] = nil
    pcall(function()
        if part.Parent then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero

            local char = LP.Character
            if char then
                for _, cPart in ipairs(char:GetChildren()) do
                    if cPart:IsA("BasePart") then
                        pcall(function()
                            local ncc = Instance.new("NoCollisionConstraint")
                            ncc.Part0 = part
                            ncc.Part1 = cPart
                            ncc.Parent = part
                            game:GetService("Debris"):AddItem(ncc, 2.5)
                        end)
                    end
                end
            end

            local ap = part:FindFirstChild("NetAP")
            if ap then ap.Enabled = false end
            local ao = part:FindFirstChild("NetAO")
            if ao then ao.Enabled = false end

            local attach = part:FindFirstChild("NetAttach")
            if attach then
                local childAP = attach:FindFirstChild("NetAP")
                if childAP then childAP.Enabled = false end
                local childAO = attach:FindFirstChild("NetAO")
                if childAO then childAO.Enabled = false end
            end
            task.spawn(function()
                for _ = 1, 3 do
                    task.wait(0.03)
                    if part and part.Parent then
                        pcall(function()
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end)
        end
    end)

    removeHL(part)

    pcall(stopDensityRamp, part)
    if partPhysProperties[part] then
        pcall(function()
            if part.Parent then
                part.CustomPhysicalProperties = partPhysProperties[part].CustomPhysicalProperties
                if partPhysProperties[part].RootPriority ~= nil then
                    part.RootPriority = partPhysProperties[part].RootPriority
                end
            end
        end)
        partPhysProperties[part] = nil
    end

    if partTouchConns[part] then
        pcall(function() partTouchConns[part]:Disconnect() end)
        partTouchConns[part] = nil
    end

    if satTouchConns[part] then
        pcall(function() satTouchConns[part]:Disconnect() end)
        satTouchConns[part] = nil
    end

    if barrageTouchConns[part] then
        pcall(function() barrageTouchConns[part]:Disconnect() end)
        barrageTouchConns[part] = nil
    end
    barrageBurst[part] = nil

    if lightningTouchConns[part] then
        pcall(function() lightningTouchConns[part]:Disconnect() end)
        lightningTouchConns[part] = nil
    end

    if railgunTouchConns[part] then
        pcall(function() railgunTouchConns[part]:Disconnect() end)
        railgunTouchConns[part] = nil
    end

    if sniperTouchConns[part] then
        pcall(function() sniperTouchConns[part]:Disconnect() end)
        sniperTouchConns[part] = nil
    end
    if homingTouchConns and homingTouchConns[part] then
        pcall(function() homingTouchConns[part]:Disconnect() end)
        homingTouchConns[part] = nil
    end
    if homingDone then homingDone[part] = nil end
    if strikeTouchConns and strikeTouchConns[part] then
        pcall(function() strikeTouchConns[part]:Disconnect() end)
        strikeTouchConns[part] = nil
    end
    if dv2TouchConns and dv2TouchConns[part] then
        pcall(function() dv2TouchConns[part]:Disconnect() end)
        dv2TouchConns[part] = nil
    end
    if boomerangConns[part] then
        pcall(function() boomerangConns[part]:Disconnect() end)
        boomerangConns[part] = nil
    end
    if blackholeTouchConns and blackholeTouchConns[part] then
        pcall(function() blackholeTouchConns[part]:Disconnect() end)
        blackholeTouchConns[part] = nil
    end
    if minigunFlying[part] then minigunLand(part, true) end
    bridgeSlots[part] = nil

    restoreSelectedCollision(part)
    pcall(restoreSpinDrivers, part)
    pcall(function() restoreAssemblyCollision(part) end)
    pcall(restoreLightenedMass, part)

    pcall(function()
        if part.Parent then
            local bp = part:FindFirstChild("NetBP")
            if bp then bp:Destroy() end
            local netBg = part:FindFirstChild("NetBG")
            if netBg then netBg:Destroy() end
            local ownBg = part:FindFirstChild("OwnershipBG")
            if ownBg then ownBg:Destroy() end
            local ap = part:FindFirstChild("NetAP")
            if ap then ap:Destroy() end
            local ao = part:FindFirstChild("NetAO")
            if ao then ao:Destroy() end
            local att = part:FindFirstChild("NetAttachment")
            if att then att:Destroy() end
            local netAttach = part:FindFirstChild("NetAttach")
            if netAttach then netAttach:Destroy() end
            local sr = part:FindFirstChild("ServerResponse")
            if sr then sr:Destroy() end
            local sr2 = part:FindFirstChild("ServerResponse2")
            if sr2 then sr2:Destroy() end
            local bv = part:FindFirstChild("OwnershipBV")
            if bv then bv:Destroy() end
            local bav = part:FindFirstChild("OwnershipBAV")
            if bav then bav:Destroy() end
            local seat = part:FindFirstChildOfClass("Seat")
            if seat then
                seat.Disabled = false
            end
            if part:IsA("Seat") then
                part.Disabled = false
            end
            if destroyPart then
                part:Destroy()
            end
        end
    end)
end

local function updatePhysPropertiesForSelected()
    for _, part in ipairs(selectedParts) do
        if part and part.Parent then
            pcall(stopDensityRamp, part)
            if strengthenParts then
                if not partPhysProperties[part] then
                    partPhysProperties[part] = {
                        CustomPhysicalProperties = part.CustomPhysicalProperties
                    }
                end
                pcall(function()
                    part.CustomPhysicalProperties = PhysicalProperties.new(strengthenDensity, 0.3, 0.5)
                end)
            else
                if partPhysProperties[part] then
                    pcall(function()
                        part.CustomPhysicalProperties = partPhysProperties[part].CustomPhysicalProperties
                    end)
                    partPhysProperties[part] = nil
                end
            end
        end
    end
end

local function resetSelectionState()
    selectedParts = {}
    selectedSetCache = {}
    ownVerdict = setmetatable({}, {__mode = "k"})
    ownVerdictAt = setmetatable({}, {__mode = "k"})
    for _, list in pairs(riderNCCs) do
        if type(list) == "table" then
            for _, c in ipairs(list) do pcall(function() c:Destroy() end) end
        end
    end
    riderNCCs = {}
    riderShieldAt = {}
    anchoredNoted = {}
    reclaimTouchAt = {}
    colAsmCache = {}
    rebuildMouseExclude()
    pcall(restoreLightenedMass, nil)
    partPhysProperties = {}
    partOffsets = {}
    partOffsetScale = {}
    frozenTargets = {}
    partTargets = {}
    satFired = {}
    for p, c in pairs(partCollisionConns) do
        partCollisionConns[p] = nil
        pcall(function() if c then c:Disconnect() end end)
        local st = partCollisionState[p]
        partCollisionState[p] = nil
        assemblyGhosted[p] = nil
        if st ~= nil then
            pcall(function()
                if p and p.Parent then p.CanCollide = st end
            end)
        end
    end
    for p, st in pairs(partCollisionState) do
        partCollisionState[p] = nil
        assemblyGhosted[p] = nil
        pcall(function()
            if p and p.Parent then p.CanCollide = st end
        end)
    end
    partCollisionState = {}
    partCollisionConns = {}
    satTarget = Vector3.zero
    slinkyHistory = {}
    minigunIdx = 1
    minigunShotStart = 0
    minigunLastIdx = 0
    minigunAcc = 0
    for p in pairs(minigunFlying) do minigunLand(p, true) end
end

local function deselectPart(part)
    for i,p in ipairs(selectedParts) do
        if p==part then
            table.remove(selectedParts,i)
            cleanupPartState(part, false)
            if activeMode == "Stickman" then pcall(refreshStickFaceSet) end
            assemblyDirtyAt = tick()
            pcall(rebuildAssemblyCache, false)
            toastSelectionSoon()
            return
        end
    end
end

local function clearSelection(destroyParts)
    for i=#selectedParts,1,-1 do
        pcall(cleanupPartState, selectedParts[i], destroyParts)
    end
    resetSelectionState()
    pcall(rebuildAssemblyCache, false)
    toastSelectionSoon()
end

local function selectFakeAnchored()
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored
           and obj ~= workspace.Terrain
           and not isPlayerPart(obj)
           and obj.AssemblyMass ~= math.huge then
            selectPart(obj)
        end
    end
end

local function selectArea(r, includeAnchored)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myPos = root.Position
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart")
           and obj ~= workspace.Terrain
           and not isPlayerPart(obj)
           and (obj.Position - myPos).Magnitude <= r then
            if includeAnchored or not obj.Anchored then
                selectPart(obj, includeAnchored)
            end
        end
    end
end

local function selectNDSInRange(r)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myPos = root.Position
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored
           and obj ~= workspace.Terrain
           and not isPlayerPart(obj)
           and obj.AssemblyMass ~= math.huge
           and (obj.Position - myPos).Magnitude <= r then
            selectPart(obj)
        end
    end
end

local function runAutoSelectScan()
    if autoSelectAll then
        selectFakeAnchored()
    elseif autoSelectNear then
        selectNDSInRange(autoSelRange)
    end
end


local function addDrawDot(pos)
    local p=Instance.new("Part")
    p.Size=Vector3.new(0.28,0.28,0.28); p.Position=pos+Vector3.new(0,1.1,0)
    p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
    p.CastShadow=false; p.Material=Enum.Material.Neon
    p.Color=Color3.fromRGB(80,180,255)
    Instance.new("SpecialMesh",p).MeshType=Enum.MeshType.Sphere
    p.Parent=workspace; table.insert(drawIndicators,p)
end
clearDrawDots = function()
    for _,p in ipairs(drawIndicators) do pcall(function() p:Destroy() end) end
    drawIndicators={}; drawTrails={}; currentTrail=nil
end


local currentMouseHit = Vector3.zero
local _lastValidMouseHit = Vector3.zero
local _lastValidHitTick = 0

local RAY = { mouse = RaycastParams.new(), ground = RaycastParams.new() }
RAY.mouse.FilterType  = Enum.RaycastFilterType.Exclude
RAY.ground.FilterType = Enum.RaycastFilterType.Exclude
local _mouseRayParams  = RAY.mouse
local _groundRayParams = RAY.ground

mouseExcludeList = {}
mouseExcludeSet = {}
mouseExcludeChar = nil
function mouseExcludeAdd(inst)
    if inst and not mouseExcludeSet[inst] then
        mouseExcludeSet[inst] = true
        table.insert(mouseExcludeList, inst)
    end
end
function mouseExcludeRemove(inst)
    if inst and mouseExcludeSet[inst] then
        mouseExcludeSet[inst] = nil
        for i, e in ipairs(mouseExcludeList) do
            if e == inst then table.remove(mouseExcludeList, i) break end
        end
    end
end
function rebuildMouseExclude()
    mouseExcludeList = {}
    mouseExcludeSet = {}
    for _, part in ipairs(selectedParts) do mouseExcludeAdd(part) end
    if spcPart then mouseExcludeAdd(spcPart) end
    local char = LP.Character
    if char then mouseExcludeAdd(char) end
    mouseExcludeChar = char
    for _, dot in ipairs(drawIndicators) do mouseExcludeAdd(dot) end
    if selectionProxyModel then mouseExcludeAdd(selectionProxyModel) end
    for _, proxy in pairs(selectionProxyParts) do mouseExcludeAdd(proxy) end
end
local function getMouseExcludeList()
    return mouseExcludeList
end
rebuildMouseExclude()
reg(LP.CharacterAdded:Connect(function(ch)
    if mouseExcludeChar and mouseExcludeChar ~= ch then mouseExcludeRemove(mouseExcludeChar) end
    mouseExcludeChar = ch
    if ch then mouseExcludeAdd(ch) end
end))
mouseExcludeNext = 0

local function getGroundYAt(x, z, defaultY, ignorePart)
    local exclude = {}
    for _, e in ipairs(getMouseExcludeList()) do table.insert(exclude, e) end
    if ignorePart then
        table.insert(exclude, ignorePart)
    end
    _groundRayParams.FilterDescendantsInstances = exclude

    local castOriginY = math.max(defaultY + 200, Camera.CFrame.Position.Y + 100)
    local hit = workspace:Raycast(
        Vector3.new(x, castOriginY, z),
        Vector3.new(0, -4000, 0),
        _groundRayParams
    )
    if not hit then
        local fallback = RaycastParams.new()
        fallback.FilterType = Enum.RaycastFilterType.Exclude
        local fList = {LP.Character}
        if ignorePart then table.insert(fList, ignorePart) end
        fallback.FilterDescendantsInstances = fList
        fallback.IgnoreWater = true
        hit = workspace:Raycast(Vector3.new(x, castOriginY, z), Vector3.new(0, -4000, 0), fallback)
    end
    return hit and hit.Position.Y or nil
end
local function getClosestSelectablePartFromRay(origin, dir, maxDist, tolerance)
    tolerance = tolerance or 7
    local firstHitDist = math.huge
    do
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local exclSel = {LP.Character}
        if selectionProxyModel then table.insert(exclSel, selectionProxyModel) end
        params.FilterDescendantsInstances = exclSel
        params.IgnoreWater = true
        local hit = workspace:Raycast(origin, dir * maxDist, params)
        if hit then
            firstHitDist = (hit.Position - origin).Magnitude
            if hit.Instance and hit.Instance:IsA("BasePart") and not hit.Instance.Anchored then
                local p = hit.Instance
                for _, s in ipairs(selectedParts) do if s == p then return p end end
                if frozenTargets[p] then return p end
            end
        end
    end
    do
        local mp = UserInputService:GetMouseLocation()
        local ins = GuiService:GetGuiInset()
        local baseX = mp.X
        local baseY = mp.Y - ins.Y
        local paramsOff = RaycastParams.new()
        paramsOff.FilterType = Enum.RaycastFilterType.Exclude
        local exclOffSel = {LP.Character}
        if selectionProxyModel then table.insert(exclOffSel, selectionProxyModel) end
        paramsOff.FilterDescendantsInstances = exclOffSel
        paramsOff.IgnoreWater = true
        local bestOff, bestOffDist = nil, math.huge
        for _, off in ipairs({Vector2.new(2,0), Vector2.new(-2,0), Vector2.new(0,2), Vector2.new(0,-2), Vector2.new(2,2), Vector2.new(-2,2), Vector2.new(2,-2), Vector2.new(-2,-2)}) do
            local rayOff = Camera:ScreenPointToRay(baseX + off.X, baseY + off.Y)
            local hitOff = workspace:Raycast(rayOff.Origin, rayOff.Direction * maxDist, paramsOff)
            if hitOff and hitOff.Instance and hitOff.Instance:IsA("BasePart") and not hitOff.Instance.Anchored then
                local p2 = hitOff.Instance
                local isCand = false
                for _, s in ipairs(selectedParts) do if s==p2 then isCand=true; break end end
                if not isCand and frozenTargets[p2] then isCand=true end
                if isCand then
                    local distOff = (hitOff.Position - origin).Magnitude
                    if distOff < bestOffDist then bestOffDist=distOff; bestOff=p2 end
                end
            end
        end
        if bestOff then return bestOff end
    end
    do
        local paramsS = RaycastParams.new()
        paramsS.FilterType = Enum.RaycastFilterType.Exclude
        local exclS = {LP.Character}
        if selectionProxyModel then table.insert(exclS, selectionProxyModel) end
        paramsS.FilterDescendantsInstances = exclS
        paramsS.IgnoreWater = true
        local sDist = math.min(maxDist, 1000)
        local sHit = workspace:Spherecast(origin, 1.2, dir * sDist, paramsS)
        if sHit and sHit.Instance and sHit.Instance:IsA("BasePart") and not sHit.Instance.Anchored then
            local p = sHit.Instance
            for _, s in ipairs(selectedParts) do if s == p then return p end end
            if frozenTargets[p] then return p end
        end
    end
    return nil
end

local function getClosestUnselectedPartFromRay(origin, dir, maxDist, tolerance)
    tolerance = tolerance or 7
    local firstHitDist = math.huge
    do
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local exclU = {LP.Character}
        if selectionProxyModel then table.insert(exclU, selectionProxyModel) end
        for _, s in ipairs(selectedParts) do table.insert(exclU, s) end
        params.FilterDescendantsInstances = exclU
        params.IgnoreWater = true
        local hit = workspace:Raycast(origin, dir * maxDist, params)
        if hit then
            firstHitDist = (hit.Position - origin).Magnitude
            if hit.Instance and hit.Instance:IsA("BasePart") then
                local p = hit.Instance
                if not p.Anchored and not isSelected(p) and not isLocalPlayerPart(p) and p ~= workspace.Terrain then
                    return p
                end
            end
        end
    end
    do
        local mp = UserInputService:GetMouseLocation()
        local ins = GuiService:GetGuiInset()
        local baseX = mp.X
        local baseY = mp.Y - ins.Y
        local paramsOff = RaycastParams.new()
        paramsOff.FilterType = Enum.RaycastFilterType.Exclude
        local exclOffU = {LP.Character}
        if selectionProxyModel then table.insert(exclOffU, selectionProxyModel) end
        for _, s in ipairs(selectedParts) do table.insert(exclOffU, s) end
        paramsOff.FilterDescendantsInstances = exclOffU
        paramsOff.IgnoreWater = true
        local bestOff, bestOffDist = nil, math.huge
        for _, off in ipairs({Vector2.new(2,0), Vector2.new(-2,0), Vector2.new(0,2), Vector2.new(0,-2), Vector2.new(2,2), Vector2.new(-2,2), Vector2.new(2,-2), Vector2.new(-2,-2)}) do
            local rayOff = Camera:ScreenPointToRay(baseX + off.X, baseY + off.Y)
            local hitOff = workspace:Raycast(rayOff.Origin, rayOff.Direction * maxDist, paramsOff)
            if hitOff and hitOff.Instance and hitOff.Instance:IsA("BasePart") then
                local p2 = hitOff.Instance
                if not p2.Anchored and not isSelected(p2) and not isLocalPlayerPart(p2) and p2 ~= workspace.Terrain then
                    local distOff = (hitOff.Position - origin).Magnitude
                    if distOff < bestOffDist then bestOffDist=distOff; bestOff=p2 end
                end
            end
        end
        if bestOff then return bestOff end
    end
    do
        local paramsS = RaycastParams.new()
        paramsS.FilterType = Enum.RaycastFilterType.Exclude
        local exclSU = {LP.Character}
        if selectionProxyModel then table.insert(exclSU, selectionProxyModel) end
        for _, s in ipairs(selectedParts) do table.insert(exclSU, s) end
        paramsS.FilterDescendantsInstances = exclSU
        paramsS.IgnoreWater = true
        local sDist = math.min(maxDist, 1000)
        local sHit = workspace:Spherecast(origin, 1.2, dir * sDist, paramsS)
        if sHit and sHit.Instance and sHit.Instance:IsA("BasePart") then
            local p = sHit.Instance
            if not p.Anchored and not isSelected(p) and not isLocalPlayerPart(p) and p ~= workspace.Terrain then
                return p
            end
        end
    end
    return nil
end

local _blockerRayParams = RaycastParams.new()
_blockerRayParams.FilterType = Enum.RaycastFilterType.Exclude
local function stickmanBlocker(origin, target)
    local dir = target - origin
    if dir.Magnitude < 0.01 then return target end
    _blockerRayParams.FilterDescendantsInstances = getMouseExcludeList()
    local hit = workspace:Raycast(origin, dir, _blockerRayParams)
    if hit then
        local inst = hit.Instance
        if inst.Anchored or inst.AssemblyMass == math.huge then
            return hit.Position
        end
    end
    return target
end

local function raycastClean(origin, dir, params, tries)
    tries = tries or 3
    local excludeFix = nil
    local hit = nil
    for _ = 1, tries + 1 do
        hit = workspace:Raycast(origin, dir, params)
        if not hit or not hit.Instance then return hit end
        local inst = hit.Instance
        if inst:IsA("BasePart") and inst.Anchored and inst.Transparency > 0.80 and inst.CanQuery
            and inst ~= workspace.Terrain and not isPlayerPart(inst) and not hasClickDetector(inst) then
            pcall(function() inst.CanQuery = false end)
            if not excludeFix then
                excludeFix = {}
                for _, e in ipairs(params.FilterDescendantsInstances or {}) do table.insert(excludeFix, e) end
            end
            table.insert(excludeFix, inst)
            params.FilterDescendantsInstances = excludeFix
        else
            return hit
        end
    end
    return hit
end
local function updateMouseHit()
    _mouseRayParams.FilterDescendantsInstances = getMouseExcludeList()


    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local x = mousePos.X
    local y = mousePos.Y - inset.Y

    local ray = Camera:ScreenPointToRay(x, y)
    local hit = raycastClean(ray.Origin, ray.Direction * 5000, _mouseRayParams)
    if not hit then
        local fallback = RaycastParams.new()
        fallback.FilterType = Enum.RaycastFilterType.Exclude
        fallback.FilterDescendantsInstances = getMouseExcludeList()
        fallback.IgnoreWater = true
        hit = raycastClean(ray.Origin, ray.Direction * 5000, fallback)
    end
    if hit then
        currentMouseHit = hit.Position
        _lastValidMouseHit = hit.Position
        _lastValidHitTick = tick()
    else
        if tick() - _lastValidHitTick < 0.25 and _lastValidMouseHit ~= Vector3.zero then
            currentMouseHit = _lastValidMouseHit
        else
            local groundY = getGroundYAt(ray.Origin.X + ray.Direction.X * 150, ray.Origin.Z + ray.Direction.Z * 150, ray.Origin.Y, nil)
            if groundY then
                local dirXZ = Vector3.new(ray.Direction.X, 0, ray.Direction.Z)
                local dist = 0
                if math.abs(ray.Direction.Y) > 0.001 then
                    dist = (groundY - ray.Origin.Y) / ray.Direction.Y
                end
                if dist > 0 and dist < 3000 then
                    currentMouseHit = ray.Origin + ray.Direction * dist
                    _lastValidMouseHit = currentMouseHit
                    _lastValidHitTick = tick()
                else
                    currentMouseHit = ray.Origin + ray.Direction * 600
                end
            else
                currentMouseHit = ray.Origin + ray.Direction * 600
            end
        end
    end
end


local function sampleDrawTrailPoint(index, total)
    if #drawTrails == 0 then return nil end
    

    local numTrails = #drawTrails
    local trailIndex = ((index - 1) % numTrails) + 1
    local trail = drawTrails[trailIndex]
    
    if not trail or #trail < 2 then return nil end
    

    local partsInThisTrail = 0
    for i = 1, total do
        if ((i - 1) % numTrails) + 1 == trailIndex then
            partsInThisTrail = partsInThisTrail + 1
        end
    end
    

    local positionInGroup = 0
    for i = 1, index do
        if ((i - 1) % numTrails) + 1 == trailIndex then
            positionInGroup = positionInGroup + 1
        end
    end
    

    local ratio = partsInThisTrail > 1 and (positionInGroup - 1) / (partsInThisTrail - 1) or 0
    local pointIndex = math.floor(ratio * (#trail - 1)) + 1
    pointIndex = math.clamp(pointIndex, 1, #trail)
    
    return trail[pointIndex]
end

local function getFormationCenterTarget()

    if formationType == "Player" then
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        return root and root.Position or Vector3.zero
    elseif formationType == "ClosestNPC" then
        local npc = getNearestNPC(LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position or Vector3.zero, 500)
        if npc then
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
            return npcRoot and npcRoot.Position or Vector3.zero
        end
        return currentMouseHit
    elseif formationType == "ClickArea" then
        return clickFormPos ~= Vector3.zero and clickFormPos or currentMouseHit
    elseif formationType == "Anchor" then
        return anchorPos ~= Vector3.zero and anchorPos or currentMouseHit
    elseif formationType == "ClickedPlayer" then
        local charModel = clickedPlayer
        if clickedPlayerRef and clickedPlayerRef.Parent then
            charModel = clickedPlayerRef.Character or charModel
        end
        if charModel then
            local root = charModel:FindFirstChild("HumanoidRootPart")
            if root then
                lastClickedPos = root.Position
                return root.Position
            end
        end
        if lastClickedPos ~= Vector3.zero then
            return lastClickedPos
        end
        return currentMouseHit
    else
        return currentMouseHit
    end
end

local _wallCache = nil

local function wallPanelBasis(part)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local fwd = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
    fwd = Vector3.new(fwd.X, 0, fwd.Z)
    fwd = fwd.Magnitude > 0.01 and fwd.Unit or Vector3.new(0, 0, -1)
    local rightD = fwd:Cross(Vector3.yAxis)
    local upD    = Vector3.yAxis
    local s = { { a = 1, v = part.Size.X }, { a = 2, v = part.Size.Y }, { a = 3, v = part.Size.Z } }
    table.sort(s, function(x, y) return x.v > y.v end)
    local vec = {}
    vec[s[1].a] = rightD
    vec[s[2].a] = upD
    vec[s[3].a] = rightD:Cross(upD)
    return CFrame.fromMatrix(Vector3.zero, vec[1], vec[2], vec[3])
end

local function _wallSlots()
    local key = #selectedParts
    local nowT = tick()
    if _wallCache and _wallCache.key == key and (nowT - _wallCache.at) < 0.5 then
        return _wallCache.slots
    end
    local items = {}
    for i, p in ipairs(selectedParts) do
        local s = (p and p.Parent) and p.Size or Vector3.new(1, 1, 1)
        local d = { s.X, s.Y, s.Z }
        table.sort(d, function(a, b) return a > b end)
        items[#items + 1] = { idx = i, w = d[1], h = d[2] }
    end
    table.sort(items, function(a, b)
        if a.h ~= b.h then return a.h > b.h end
        return a.w > b.w
    end)
    local scY  = math.clamp(math.max(0, formSizeY) / 3, 0.5, 4)
    local sumH = 0
    for _, it in ipairs(items) do sumH += it.h end
    local H = math.max(sumH ^ 0.5, items[1] and items[1].h or 1) * scY
    local gap = wallGap
    local cols, slotByIdx = {}, {}
    for _, it in ipairs(items) do
        local best, bestRem = nil, nil
        for _, c in ipairs(cols) do
            local remH = H - c.usedH
            if remH >= it.h and c.w + gap >= it.w then
                if not bestRem or remH < bestRem then
                    best, bestRem = c, remH
                end
            end
        end
        if not best then
            local prevX = 0
            for _, c in ipairs(cols) do prevX = math.max(prevX, c.x + c.w + gap) end
            best = { x = prevX, w = it.w, usedH = 0 }
            cols[#cols + 1] = best
        elseif it.w > best.w then
            best.x -= (it.w - best.w) * 0.5
            best.w = it.w
        end
        local rx = best.x + best.w * 0.5
        local uy = best.usedH + it.h * 0.5
        best.usedH += it.h + gap
        slotByIdx[it.idx] = { r = rx, u = uy }
    end
    local minX, maxX = math.huge, -math.huge
    for _, s in pairs(slotByIdx) do
        minX = math.min(minX, s.r)
        maxX = math.max(maxX, s.r)
    end
    local midX = (minX + maxX) * 0.5
    for _, s in pairs(slotByIdx) do
        s.r -= midX
        s.u -= H * 0.5
    end
    _wallCache = { key = key, at = nowT, slots = slotByIdx }
    return slotByIdx
end

local function _wallTarget(index, total, part, t)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return currentMouseHit end

    local slots = _wallSlots()
    local slot  = slots[index]

    local rp  = root.Position
    local scX = math.max(0, formSizeX) / 10
    local scZ = math.max(0, formSizeZ) / 10
    local maxSc = math.max(scX, scZ)

    local fwd = root.CFrame.LookVector
    fwd = Vector3.new(fwd.X, 0, fwd.Z)
    fwd = fwd.Magnitude > 0.01 and fwd.Unit or Vector3.new(0, 0, -1)
    local rightD = fwd:Cross(Vector3.yAxis)

    local ctr = rp + fwd * (wallDist * maxSc)
    local r = slot and slot.r or 0
    local u = slot and slot.u or 0
    return ctr + rightD * (r * maxSc) + Vector3.new(0, u, 0)
end

local _tessVerts, _tessEdges

function minigunRig(total, t)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local look = Vector3.new(0, 0, -1)
    if root then
        local lv = root.CFrame.LookVector
        look = Vector3.new(lv.X, 0, lv.Z)
        look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
    end
    local right = look:Cross(Vector3.yAxis)
    local scY = math.max(0, formSizeY) / 3
    local rp0 = ((root and root.Position) or Vector3.zero) + Vector3.new(0, formOffsetY, 0)
    local C = rp0 + Vector3.new(0, 4*scY, 0) + look*6
    local B = math.clamp(math.ceil(math.max(total, 1)/6), 2, 5)
    return {C = C, look = look, right = right, B = B, scY = scY}
end

function minigunMuzzle(rig, b, t)
    local ba = (b/rig.B)*math.pi*2 + t*2.2
    return rig.C + rig.right*math.cos(ba)*2 + Vector3.yAxis*math.sin(ba)*2
end

ROT_BLOCK = {
    Sniper=true, Strike=true, Homing=true, Railgun=true, Barrage=true,
    Satellite=true, Lightning=true, Boomerang=true, Scythe=true, Chained=true,
    Bridge=true, Text=true, Stickman=true, Seek=true, Draw=true, Comet=true,
    Slinky=true, Minigun=true, DroneV2=true,
}
RP_PIVOT = {Halo=true, Shield=true, Pentagram=true, Heart=true, Wings=true}

local ringFitN, ringFitAt, ringFitPitch = -1, 0, 2.8
local function getTarget(index, total, part, t)
    local formYOffset = Vector3.new(0, formOffsetY, 0)
    local mHit   = getFormationCenterTarget() + formYOffset
    local char   = LP.Character
    local rp = ((char and char:FindFirstChild("HumanoidRootPart"))
               and char.HumanoidRootPart.Position or Vector3.zero) + formYOffset
    local ratio  = total>1 and (index-1)/(total-1) or 0
    local angle  = (index-1)/math.max(total,1)*math.pi*2
    

    local scX = math.max(0, formSizeX) / 10
    local scZ = math.max(0, formSizeZ) / 10
    local scR = math.max(scX, scZ)  
    local scY = math.max(0, formSizeY) / 3

    if attracting then
        return rp+(partOffsets[part] or Vector3.zero)*0.4+Vector3.new(0,2*scY,0)
    end


    if activeMode=="Mouse" then
        return mHit+(partOffsets[part] or Vector3.zero)*2.5

    elseif activeMode=="Tornado" then
        local band=(index-1)%6; local h=math.floor((index-1)/6)*2.2*scY
        local totalH=math.max(math.ceil(total/6)*2.2*scY, 1)
        local hf=math.clamp(h/totalH, 0, 1)
        local spin=band/6*math.pi*2+t*tornadoSpeed*(1.25-hf*0.5)
        local rMax = math.max(scX, scZ)
        local skirt=hf<0.12 and 1.25 or 1
        local r=((3+math.sin(t*1.5+index*0.7)*0.8)*rMax)*(1-0.55*hf)*skirt
        return Vector3.new(mHit.X+math.cos(spin)*r*scX,mHit.Y+h,mHit.Z+math.sin(spin)*r*scZ)

    elseif activeMode=="Ring" then
        if ringFitN ~= total or tick() - ringFitAt > 0.25 then
            ringFitN = total
            ringFitAt = tick()
            ringFitPitch = 2.8
            for _, p in ipairs(selectedParts) do
                local okS, s = pcall(function() return p.Size end)
                if okS and s then
                    local pp = math.max(s.X, s.Z) + 0.8
                    if pp > ringFitPitch then ringFitPitch = pp end
                end
            end
        end
        local liftY = math.max(1.5*scY, 1.5)
        if scX < 0.02 and scZ < 0.02 then
            return Vector3.new(mHit.X, mHit.Y + liftY, mHit.Z)
        end
        local rMax = math.max(scX, scZ)
        local r = formRadius*rMax; local a=angle+t*1.0
        local ox = math.cos(a)*r*scX
        local oz = math.sin(a)*r*scZ
        do
            local haveR = math.sqrt(ox*ox + oz*oz)
            if haveR < 2 then
                if haveR > 0 then
                    ox, oz = ox*2/haveR, oz*2/haveR
                else
                    ox, oz = math.cos(a)*2, math.sin(a)*2
                end
            end
        end
        return Vector3.new(mHit.X+ox,mHit.Y+liftY,mHit.Z+oz)

    elseif activeMode=="Orbit" then
        local a=angle+t*3.2; local vOff=math.sin(a*2+index)*4*scY
        return Vector3.new(mHit.X+math.cos(a)*orbitRadius*scX,mHit.Y+4*scY+vOff,mHit.Z+math.sin(a)*orbitRadius*scZ)

    elseif activeMode=="Spiral" then
        local a=ratio*2.5*math.pi*2+t*1.2; local r=ratio*8*math.max(scX,scZ)
        return Vector3.new(mHit.X+math.cos(a)*r*scX,mHit.Y+ratio*spiralHeight*scY,mHit.Z+math.sin(a)*r*scZ)

    elseif activeMode=="Wave" then
        local x=(ratio-.5)*math.max(total,1)*1.3*scX
        local wY=math.sin(ratio*math.pi*5+t*5.0)*waveAmp*scY
        local wZ=math.cos(ratio*math.pi*3+t*3.0)*1.2*scZ
        return Vector3.new(mHit.X+x,mHit.Y+wY+2*scY,mHit.Z+wZ)

    elseif activeMode=="Halo" then
        local rMax = math.max(scX, scZ)
        local baseR = math.max(total*0.4, formRadius)*rMax
        local center = rp + Vector3.new(0, 7*scY, 0)
        local half = math.ceil(total/2)
        if index <= half then
            local n = math.max(half, 1)
            local a = ((index-1)/n)*math.pi*2 + t*0.7
            local rr = baseR
            return Vector3.new(
                center.X + math.cos(a)*rr*scX,
                center.Y + math.sin(t*2.2 + index*0.5)*0.25,
                center.Z + math.sin(a)*rr*scZ)
        else
            local n2 = math.max(total-half, 1)
            local k = index-half
            local a2 = ((k-1)/n2)*math.pi*2 - t*0.7
            local rr2 = math.max(baseR*0.45, 1.2)*(1 + 0.25*math.sin(t*1.3 + k*2.1))
            local localP = Vector3.new(math.cos(a2)*rr2*scX, 0, math.sin(a2)*rr2*scZ)
            local tumble = CFrame.Angles(0.5, (t*0.5) % (math.pi*2), 0.3) * CFrame.Angles((t*0.9) % (math.pi*2), 0, (t*0.35) % (math.pi*2))
            return center + tumble * localP + Vector3.new(0, math.sin(t*2.6 + k)*0.2, 0)
        end

    elseif activeMode=="Drone" then
        local off=partOffsets[part] or Vector3.zero
        local driftX=math.sin(t*1.6+index*1.1)*2*scX
        local driftY=math.sin(t*2.6+index*0.9)*1*scY
        local driftZ=math.cos(t*1.3+index*1.4)*2*scZ
        return mHit+Vector3.new(off.X*1.8*scX,off.Y*1.8,off.Z*1.8*scZ)+Vector3.new(driftX,driftY,driftZ)+Vector3.new(0,4*scY,0)

    elseif activeMode=="DroneV2" then
        if dv2Target then
            return dv2PredictedPos()+Vector3.new(
                math.sin(t*16+index*1.7)*0.6,math.sin(t*12+index*0.9)*0.6,math.cos(t*16+index*1.3)*0.6)
        end
        local rX=formRadius*scX; local rZ=formRadius*scZ; local a=angle+t*0.9
        return Vector3.new(rp.X+math.cos(a)*rX,rp.Y+5.5*scY+math.sin(t*2+index*0.65)*0.35,rp.Z+math.sin(a)*rZ)

    elseif activeMode=="Shield" then
        local phi=(1+math.sqrt(5))/2; local i=index-1
        local theta=2*math.pi*i/phi + t*0.5
        local cosY=math.clamp(-0.2+(i/math.max(total-1,1))*1.2,-1,1)
        local sinY=math.sqrt(1-cosY*cosY); local r=(formRadius+0.5)*scR
        return Vector3.new(rp.X+sinY*math.cos(theta)*r*scX,rp.Y+cosY*r+1.5*scY+math.sin(t*2+i)*0.3,rp.Z+sinY*math.sin(theta)*r*scZ)

    elseif activeMode=="Comet" then
        if #cometHistory<2 then return rp end

        local trailLen = math.min(#cometHistory - 1, math.max(total * 3, 10))
        local histIdx  = math.max(1, #cometHistory - math.floor(ratio * trailLen))

        return cometHistory[histIdx] + (partOffsets[part] or Vector3.zero) * 0.6

    elseif activeMode=="Wall" then
        return _wallTarget(index, total, part, t)



    elseif activeMode=="Draw" then
        local trailPos = sampleDrawTrailPoint(index, total)
        if trailPos then
            return trailPos + Vector3.new(0, 1 * scY, 0)
        end
        return mHit + Vector3.new(0, 1 * scY, 0)

    elseif activeMode=="Beam" then
        local startP = rp + Vector3.new(0, 2 * scY, 0)
        local dirV   = mHit - startP
        local dist   = dirV.Magnitude
        if dist < 0.01 or dist ~= dist then return startP end
        local cf     = CFrame.lookAt(startP, mHit)
        local strand = (index - 1) % 2
        local turns  = math.max(math.floor(dist / 6), 2)
        local aa     = ratio * turns * math.pi * 2 + t * 6 + strand * math.pi
        local rr     = (0.6 + 0.9 * math.sin(ratio * math.pi)) * math.max(scX, scZ)
        return cf * Vector3.new(math.cos(aa) * rr, math.sin(aa) * rr, -(ratio * dist))


    elseif activeMode=="Sphere" then

        local phi=(1+math.sqrt(5))/2; local i=index-1
        local theta=2*math.pi*i/phi
        local cosY=1-2*(i/math.max(total-1,1))
        local sinY=math.sqrt(math.max(0,1-cosY*cosY))


        local rx = formRadius * scX * 2
        local ry = formRadius * scY * 2
        local rz = formRadius * scZ * 2


        local yLatScale = 0.28
        return Vector3.new(
            mHit.X + sinY*math.cos(theta+t*0.4)*rx,
            mHit.Y + cosY*ry*yLatScale,
            mHit.Z + sinY*math.sin(theta+t*0.4)*rz)

    elseif activeMode=="Vortex" then
        local band=(index-1)%6; local h=math.floor((index-1)/6)*2.2*scY
        local spin=band/6*math.pi*2-t*tornadoSpeed*2
        local maxR = math.max(scX, scZ)
        if maxR < 0.001 then maxR = 0.001 end
        local r=(1+(h/maxR)*0.35)*maxR
        local yPos = mHit.Y+14*scY-h
        if yPos < mHit.Y then yPos = mHit.Y end
        return Vector3.new(mHit.X+math.cos(spin)*r*scX,yPos,mHit.Z+math.sin(spin)*r*scZ)

    elseif activeMode=="DNA" then
        local strand=(index-1)%2; local pos=math.floor((index-1)/2)
        local pr=total>2 and pos/math.floor(total/2) or 0
        local a=pr*3*math.pi*2+t*1.6+strand*math.pi
        local r=3*scR; local h=pr*12*scY
        return Vector3.new(mHit.X+math.cos(a)*r*scX,mHit.Y+h,mHit.Z+math.sin(a)*r*scZ)

    elseif activeMode=="Pulse" then
        local pulseR=formRadius*(1+math.sin(t*6)*0.45)*math.max(scX,scZ)
        local a=angle
        return Vector3.new(
            mHit.X+math.cos(a)*pulseR*scX,
            mHit.Y+2*scY+math.sin(t*6)*0.5,
            mHit.Z+math.sin(a)*pulseR*scZ)

    elseif activeMode=="Grid" then
        local cols=math.ceil(math.sqrt(total))
        local col=((index-1)%cols)-(cols-1)/2
        local row=math.floor((index-1)/cols)-(math.ceil(total/cols)-1)/2
        local spX=(part.Size.X+wallGap)*scX
        local spZ=(part.Size.Z+wallGap)*scZ
        local jx = math.sin(t*2.2 + index*1.7) * 0.12
        local jy = math.sin(t*2.6 + index*1.3) * 0.12
        local jz = math.cos(t*2.4 + index*0.9) * 0.12
        return Vector3.new(mHit.X+col*spX+jx,mHit.Y+4*scY+jy,mHit.Z+row*spZ+jz)

    elseif activeMode=="Cube" then
        local verts = {
            Vector3.new(-1,-1,-1), Vector3.new(1,-1,-1), Vector3.new(1,1,-1), Vector3.new(-1,1,-1),
            Vector3.new(-1,-1, 1), Vector3.new(1,-1, 1), Vector3.new(1,1, 1), Vector3.new(-1,1, 1),
        }
        local edges = {
            {1,2},{2,3},{3,4},{4,1},
            {5,6},{6,7},{7,8},{8,5},
            {1,5},{2,6},{3,7},{4,8},
        }
        local perEdge = math.max(1, math.ceil(total / 12))
        local eIdx = (index - 1) % 12 + 1
        local seg  = math.floor((index - 1) / 12)
        local tEdge = perEdge > 1 and seg / (perEdge - 1) or 0.5
        local v = verts[edges[eIdx][1]]:Lerp(verts[edges[eIdx][2]], tEdge)
        local half = math.max(formRadius, 2)
        local rot  = CFrame.Angles((t * 0.45) % (math.pi*2), (t * 0.32) % (math.pi*2), 0)
        local scYc = 1 + (scY - 1) * 0.3
        local out  = Vector3.new(v.X * half * scX, v.Y * half * scYc, v.Z * half * scZ)
        return mHit + rot:VectorToWorldSpace(out) + Vector3.new(0, 3 * scY, 0)

    elseif activeMode=="Scatter" then
        local scatter=(math.sin(t*1.5)+1)/2
        local off=(partOffsets[part] or Vector3.zero)
        local far=mHit+Vector3.new(off.X*14*scX,off.Y*14,off.Z*14*scZ)+Vector3.new(0,math.abs(off.Y)*4*scY,0)
        return mHit:Lerp(far,scatter)+Vector3.new(0,1*scY,0)

    elseif activeMode=="Star" then
        local POINTS = 5
        local VERTS = POINTS*2
        local spin = t*0.7
        local outer = formRadius*2
        local inner = outer*0.42
        local f = ratio*VERTS
        local fi = math.floor(f)
        local seg = fi % VERTS
        local segT = f - fi
        local a1 = seg/VERTS*math.pi*2 + spin
        local a2 = ((seg+1)%VERTS)/VERTS*math.pi*2 + spin
        local r1 = (seg%2==0) and outer or inner
        local r2 = ((seg+1)%2==0) and outer or inner
        local lx = math.cos(a1)*r1 + (math.cos(a2)*r2 - math.cos(a1)*r1)*segT
        local lz = math.sin(a1)*r1 + (math.sin(a2)*r2 - math.sin(a1)*r1)*segT
        local center = mHit + Vector3.new(0, 2.5*scY, 0)
        return Vector3.new(center.X + lx*scX, center.Y + math.sin(t*2 + ratio*6)*0.3*scY, center.Z + lz*scZ)

    elseif activeMode=="Pendulum" then
        local swing=math.sin(t*4+index*0.55)*formRadius*scX
        local dip=-(1-math.cos(t*4+index*0.55))*formRadius*scY*0.5
        return Vector3.new(mHit.X+swing,mHit.Y+6*scY+dip,mHit.Z+(ratio-0.5)*4*scZ)

    elseif activeMode=="Rain" then
        local phase=(index-1)/math.max(total,1)*math.pi*2
        local hx = ((index * 0.61803398875) % 1) * 2 - 1
        local hz = ((index * 0.75487766625 + 0.37) % 1) * 2 - 1
        local x = mHit.X + hx * 0.6 * math.max(formSizeX, 0)
        local z = mHit.Z + hz * 0.6 * math.max(formSizeZ, 0)
        local topY = mHit.Y + 14 * scY
        local groundY = getGroundYAt(x, z, topY, part)
        local floorY = groundY and (groundY + part.Size.Y * 0.5 + 0.15) or (mHit.Y + 2 * scY)
        local dropHeight = math.max(topY - floorY, 2)
        local fall = (t * 38 + phase / (math.pi * 2) * dropHeight) % dropHeight
        return Vector3.new(x, topY - fall, z)

    elseif activeMode=="Galaxy" then

        local arms   = 3
        local arm    = (index-1) % arms
        local posInArm = math.floor((index-1) / arms)
        local tpa    = math.ceil(total / arms)
        local ar     = tpa>1 and posInArm/(tpa-1) or 0
        local base   = arm/arms * math.pi*2
        local spiral = base + ar*math.pi*2.5 + t*0.8
        local r      = ar * formRadius*2*scR
        local tilt   = math.sin(t*3.0 + index)*0.35*scY
        return Vector3.new(mHit.X+math.cos(spiral)*r*scX, mHit.Y+tilt+1*scY, mHit.Z+math.sin(spiral)*r*scZ)

    elseif activeMode=="Blackhole" then
        local center = mHit + Vector3.new(0, 4*scY, 0)
        local bhR = math.max(formRadius*2, 4)
        local tilt = 1.05
        local sT, cT = math.sin(tilt), math.cos(tilt)
        local u = total>1 and (index-1)/(total-1) or 0
        local surge = (tick() < blackholeSurgeUntil) and 2 or 1
        if u < 0.55 then
            local a = angle + t*9*surge
            local rr = bhR*scR
            return Vector3.new(center.X+math.cos(a)*rr*scX, center.Y+math.sin(a)*rr*sT*scY, center.Z+math.sin(a)*rr*cT*scZ)
        elseif u < 0.70 then
            local a = angle - t*13*surge
            local rr = bhR*0.55*scR
            return Vector3.new(center.X+math.cos(a)*rr*scX, center.Y+math.sin(a)*rr*sT*scY, center.Z+math.sin(a)*rr*cT*scZ)
        elseif u < 0.90 then
            local cyc = (t*1.2 + ratio*1.0) % 1
            local pr = math.max(0, 1-cyc)
            local rr = bhR*scR*pr + 0.3
            local spin = angle*2 - t*16*surge
            return Vector3.new(center.X+math.cos(spin)*rr*scX, center.Y-cyc*6*scY, center.Z+math.sin(spin)*rr*scZ)
        else
            local prog = (t*1.8 + index*0.13) % 1
            local up = (index % 2 == 0)
            local h = prog*16*scY*(up and 1 or -0.6)
            local wa = t*10*surge + index*1.7
            return center + Vector3.new(math.cos(wa)*1.0*scX, h, math.sin(wa)*1.0*scZ)
        end

    elseif activeMode=="Lemniscate" then

        local phase  = ratio * math.pi*2 + t*1.3
        local denom  = 1 + math.sin(phase)^2 + 0.001
        local a      = formRadius * scR * 1.6
        local x      = a * math.cos(phase) / denom * scX
        local z      = a * math.sin(phase)*math.cos(phase) / denom * scZ
        local y      = math.sin(t*3.2 + index*0.45) * 0.55 * scY
        return Vector3.new(mHit.X+x, mHit.Y+2*scY+y, mHit.Z+z)

    elseif activeMode=="Blender" then

        local off    = partOffsets[part] or Vector3.zero
        local ax     = math.sin(off.X*3.14+1)
        local ay     = math.cos(off.Y*2.71+2)
        local az     = math.sin(off.Z*1.73+3)
        local axis   = Vector3.new(ax,ay,az)
        if axis.Magnitude < 0.001 then axis = Vector3.new(0,1,0) end
        axis = axis.Unit
        local up     = math.abs(axis.Y) < 0.9 and Vector3.new(0,1,0) or Vector3.new(1,0,0)
        local p1     = (axis:Cross(up)).Unit
        local p2     = (axis:Cross(p1)).Unit
        local spd    = 5.6 + (index%7)*0.25
        local ph     = t*spd + index*1.37
        local maxR = math.max(scX, scZ)
        local r      = formRadius * maxR
        return mHit + Vector3.new(0,3*scY,0) + p1*(math.cos(ph)*r*scX) + p2*(math.sin(ph)*r*scZ)

    elseif activeMode=="Crown" then
        local spin = t*0.4
        local r = formRadius * scR
        local SPIKES = 6
        local gemN = math.clamp(math.floor(total*0.12), 3, 7)
        if total < 8 then gemN = 0 end
        local baseY = 3*scY
        if gemN > 0 and index <= gemN then
            local gs = 1.8*math.max(scX, scZ, 0.6)
            local gemHover = (formRadius*0.6+2.5)*scY + 4*scY
            local gc = Vector3.new(mHit.X, mHit.Y+baseY+gemHover, mHit.Z) + Vector3.new(0, math.sin(t*1.8)*0.4*scY, 0)
            if index == 1 then
                return gc + Vector3.new(0, gs, 0)
            elseif index == 2 then
                return gc + Vector3.new(0, -gs, 0)
            else
                local rn = math.max(gemN-2, 1)
                local a = ((index-3)/rn)*math.pi*2 + t*1.2
                return gc + Vector3.new(math.cos(a)*gs, 0, math.sin(a)*gs)
            end
        else
            local bi = index-gemN
            local bn = math.max(total-gemN, 1)
            local a = ((bi-1)/bn)*math.pi*2 + spin
            local spikeH = (formRadius*0.6+2.5)*scY
            if bi%2==1 then
                return Vector3.new(mHit.X+math.cos(a)*r*scX, mHit.Y+baseY, mHit.Z+math.sin(a)*r*scZ)
            else
                local s = 1-math.abs((((bi-1)/bn*SPIKES)%1)*2-1)
                local rr = r*(1+s*0.08)
                return Vector3.new(mHit.X+math.cos(a)*rr*scX, mHit.Y+baseY+s*spikeH, mHit.Z+math.sin(a)*rr*scZ)
            end
        end

    elseif activeMode=="Swarm" then

        local off    = partOffsets[part] or Vector3.zero
        local wanderX = math.sin(t*2.2 + index*2.3 + off.X) * formRadius*scX
        local wanderY = math.sin(t*1.8 + index*1.7 + off.Y) * formRadius*0.55*scY
        local wanderZ = math.cos(t*2.6 + index*2.1 + off.Z) * formRadius*scZ
        local jitter = Vector3.new(
            math.sin(t*18  + index*3.1) * 0.7,
            math.sin(t*14  + index*2.7) * 0.35,
            math.cos(t*16  + index*3.5) * 0.7)
        return mHit + Vector3.new(wanderX,wanderY,wanderZ) + jitter + Vector3.new(0,2*scY,0)

    elseif activeMode=="Satellite" then

        local high     = 14 * scY
        local clusterN = math.max(1, math.ceil(total / 4))

        if satFired[part] then
            return satTarget   
        end

        if index <= clusterN then
            local ringSlots = 8
            local layer = math.floor((index - 1) / ringSlots)
            local slot  = (index - 1) % ringSlots
            local a     = (slot / ringSlots) * math.pi * 2 + t * 0.4
            local r     = math.max(3.5 * scX, 3.5 * scZ)
            local y     = rp.Y + high + layer * (2.1 * scY)
            return Vector3.new(
                rp.X + math.cos(a) * r,
                y,
                rp.Z + math.sin(a) * r)
        else
      
            local hi = index - clusterN
            local hn = math.max(total - clusterN, 1)
            local a  = (hi - 1) / hn * math.pi * 2 + t * 0.56
            local r  = formRadius * math.max(scX, scZ)
            return Vector3.new(
                rp.X + math.cos(a) * r * scX,
                rp.Y + high,
                rp.Z + math.sin(a) * r * scZ)
        end

    elseif activeMode=="Minigun" then

        local rig = minigunRig(total, t)
        local b = (index-1) % rig.B
        local muzzle = minigunMuzzle(rig, b, t)
        if minigunFlying[part] then
            local from = minigunFlyFrom[part] or muzzle
            local ft = minigunFlyTgt[part]
            if not ft then ft = mHit end
            local t0 = minigunFlyT0[part] or t
            local prog = math.clamp((t - t0)/MINIGUN_FLY, 0, 1)
            return from:Lerp(ft, prog*prog)
        end
        local k = math.floor((index-1)/rig.B)
        local spacing = 2.4
        return muzzle - rig.look*(2 + k*spacing) + Vector3.new(0, -math.min(k*0.4, 3)*rig.scY, 0)

    elseif activeMode=="Seek" then

        local npc = getNearestNPC(part.Position, 200)
        if npc then
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
            if npcRoot then return npcRoot.Position + (partOffsets[part] or Vector3.zero) * 0.5 end
        end
        return mHit + (partOffsets[part] or Vector3.zero)

    elseif activeMode=="Stickman" then
        local charS   = LP.Character
        local rootS   = charS and charS:FindFirstChild("HumanoidRootPart")
        local originS, lookD, rightD
        local H       = 9 * scY
        local isSitting = false
        originS = rootS and rootS.Position or mHit
        lookD   = rootS and rootS.CFrame.LookVector or Vector3.new(0, 0, -1)
        rightD  = rootS and rootS.CFrame.RightVector or Vector3.new(1, 0, 0)
        local W       = 2.6 * scR
        local u       = ratio
        if not stickFaceSet[part] then
            if stickBodyCount > 1 then
                u = ((stickBodyRank[part] or 1) - 1) / (stickBodyCount - 1)
            elseif stickBodyCount == 1 then
                u = 0
            end
        end
        if stickBeamActive then
            local uu = index / math.max(total, 1)
            local inArm = uu >= 0.37 and uu < 0.73
            local armMatch = stickArmIsLeft and uu < 0.55 or (not stickArmIsLeft and uu >= 0.55)
            if inArm and armMatch then
                local lo, hi = 0.37, 0.73
                if stickArmIsLeft then hi = 0.55 else lo = 0.55 end
                local k = math.clamp((uu - lo) / math.max(hi - lo, 0.001), 0, 1)
                local shYb = H * 0.76
                local beamOrigin = originS
                    + rightD * ((stickArmIsLeft and -2.5 or 2.5) * scR)
                    + Vector3.new(0, shYb + 2.5 * scY, 0)
                local beamTarget = stickmanBlocker(beamOrigin, currentMouseHit)
                local jitter = Vector3.new(
                    (math.noise(index * 0.7, 0, 0)) * 1.5,
                    (math.noise(0, index * 0.7, 0)) * 1.5,
                    (math.noise(0, 0, index * 0.7)) * 1.5
                )
                return beamOrigin:Lerp(beamTarget, k) + jitter
            end
        end
        local groundY = isSitting and (0.2 * scY) or (-2.8 * scY)

        local flatV  = Vector3.new(stickVelSmooth.X, 0, stickVelSmooth.Z)
        local walkF  = isSitting and 0 or math.clamp(flatV.Magnitude / 12, 0, 1)
        local ph     = isSitting and 0 or stickWalkPhase
        local hipY   = isSitting and (H * 0.18) or (H * 0.42)
        local amp    = 0.55 * walkF
        local hipY   = isSitting and (H * 0.18) or (H * 0.42)
        local legLen = hipY - groundY
        local shY    = isSitting and (H * 0.32) or (H * 0.76)
        local headRW = 1.25 * scY
        local headRH = 1.85 * scY
        local headC  = H * 0.82 + headRH
        local armLen = H * 0.45
        local widenF = math.clamp(math.sqrt(scX), 0.7, 3)
        local px, py, pz = 0, 0, 0
        if not stickCrawlActive and stickFaceSet[part] then
            local faceIdx = stickFaceSet[part]
            local isBlink = (tick() % 4.15) < 0.14
            if stickFaceMode == 4 then isBlink = false end
            local curHeadY = headC
            local curHeadFwd = 0
            if stickDanceActive then curHeadY = headC end
            local fYAdd = 0
            if stickDanceActive then fYAdd = math.sin(t * 1.7 * 1.15) * 0.16 * 0.85 end
            local headWPos = originS + Vector3.new(0, curHeadY + 2.5 * scY, 0) + lookD * curHeadFwd
            local htm = currentMouseHit - headWPos
            local tiltRight = htm:Dot(rightD) / math.max(htm.Magnitude, 1)
            local tiltUp = htm.Y / math.max(htm.Magnitude, 1)
            local tiltFwd = htm:Dot(lookD) / math.max(htm.Magnitude, 1)
            local eyeYBase = 0.30 * headRH
            local eyeZBase = 0.62 * headRW + curHeadFwd
            local browYBase = 0.52 * headRH
            local mouthZBase = 0.58 * headRW + curHeadFwd
            local tiltRX = tiltRight * headRW * 0.22
            local tiltUY = tiltUp * headRH * 0.12
            local tiltFZ = tiltRight * headRW * 0.18 + tiltUp * headRW * 0.10 + tiltFwd * headRW * 0.14
            if faceIdx == 1 then
                local ex = -0.46 * headRW + tiltRX
                local ey = eyeYBase + tiltUY
                if stickFaceMode == 1 then ey = 0.20 * headRH + tiltUY * 0.6; ex = -0.40 * headRW + tiltRX * 0.7
                elseif stickFaceMode == 3 then ey = 0.18 * headRH + tiltUY * 0.6
                elseif stickFaceMode == 4 then ey = 0.06 * headRH end
                if isBlink then ey -= 0.26 * headRH end
                px = ex / math.max(scX, 0.001)
                py = curHeadY + ey + fYAdd
                pz = eyeZBase + tiltFZ
            elseif faceIdx == 2 then
                local ex = 0.46 * headRW + tiltRX
                local ey = eyeYBase + tiltUY
                if stickFaceMode == 1 then ey = 0.20 * headRH + tiltUY * 0.6; ex = 0.40 * headRW + tiltRX * 0.7
                elseif stickFaceMode == 3 then ey = 0.18 * headRH + tiltUY * 0.6
                elseif stickFaceMode == 4 then ey = 0.06 * headRH end
                if isBlink then ey -= 0.26 * headRH end
                px = ex / math.max(scX, 0.001)
                py = curHeadY + ey + fYAdd
                pz = eyeZBase + tiltFZ
            elseif faceIdx == 3 then
                local bx = -0.56 * headRW + tiltRX * 0.9
                local by = browYBase + tiltUY * 0.7
                if stickFaceMode == 1 then bx = -0.44 * headRW + tiltRX * 0.5; by = 0.42 * headRH + tiltUY * 0.5
                elseif stickFaceMode == 4 then by = 0.32 * headRH end
                px = bx / math.max(scX, 0.001)
                py = curHeadY + by + fYAdd
                pz = eyeZBase + 0.06 * headRW + tiltFZ
            elseif faceIdx == 4 then
                local bx = -0.30 * headRW + tiltRX * 0.9
                local by = browYBase + tiltUY * 0.7
                if stickFaceMode == 1 then bx = -0.18 * headRW + tiltRX * 0.5; by = 0.30 * headRH + tiltUY * 0.5
                elseif stickFaceMode == 4 then by = 0.32 * headRH end
                px = bx / math.max(scX, 0.001)
                py = curHeadY + by + fYAdd
                pz = eyeZBase + 0.06 * headRW + tiltFZ
            elseif faceIdx == 5 then
                local bx = 0.30 * headRW + tiltRX * 0.9
                local by = browYBase + tiltUY * 0.7
                if stickFaceMode == 1 then bx = 0.18 * headRW + tiltRX * 0.5; by = 0.30 * headRH + tiltUY * 0.5
                elseif stickFaceMode == 4 then by = 0.32 * headRH end
                px = bx / math.max(scX, 0.001)
                py = curHeadY + by + fYAdd
                pz = eyeZBase + 0.06 * headRW + tiltFZ
            elseif faceIdx == 6 then
                local bx = 0.56 * headRW + tiltRX * 0.9
                local by = browYBase + tiltUY * 0.7
                if stickFaceMode == 1 then bx = 0.44 * headRW + tiltRX * 0.5; by = 0.42 * headRH + tiltUY * 0.5
                elseif stickFaceMode == 4 then by = 0.32 * headRH end
                px = bx / math.max(scX, 0.001)
                py = curHeadY + by + fYAdd
                pz = eyeZBase + 0.06 * headRW + tiltFZ
            elseif faceIdx == 7 then
                local mx, my = -0.36 * headRW + tiltRX * 0.6, -0.22 * headRH + tiltUY * 0.4
                if stickFaceMode == 1 then my = -0.12 * headRH + tiltUY * 0.3; mx = -0.28 * headRW + tiltRX * 0.4
                elseif stickFaceMode == 2 then mx = -0.28 * headRW + tiltRX * 0.4; my = -0.28 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 3 then mx = -0.42 * headRW + tiltRX * 0.4; my = -0.30 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 4 then mx = -0.22 * headRW; my = -0.14 * headRH end
                px = mx / math.max(scX, 0.001)
                py = curHeadY + my + fYAdd
                pz = mouthZBase + tiltFZ * 0.7
            elseif faceIdx == 8 then
                local mx, my = -0.14 * headRW + tiltRX * 0.6, -0.32 * headRH + tiltUY * 0.4
                if stickFaceMode == 1 then my = -0.18 * headRH + tiltUY * 0.3
                elseif stickFaceMode == 2 then my = -0.38 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 3 then my = -0.38 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 4 then my = -0.16 * headRH end
                px = mx / math.max(scX, 0.001)
                py = curHeadY + my + fYAdd
                pz = mouthZBase + tiltFZ * 0.7 - (stickFaceMode == 2 and 0.03 * headRW or 0)
            elseif faceIdx == 9 then
                local mx, my = 0.14 * headRW + tiltRX * 0.6, -0.32 * headRH + tiltUY * 0.4
                if stickFaceMode == 1 then my = -0.18 * headRH + tiltUY * 0.3
                elseif stickFaceMode == 2 then my = -0.38 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 3 then my = -0.38 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 4 then my = -0.16 * headRH end
                px = mx / math.max(scX, 0.001)
                py = curHeadY + my + fYAdd
                pz = mouthZBase + tiltFZ * 0.7 - (stickFaceMode == 2 and 0.03 * headRW or 0)
            elseif faceIdx == 10 then
                local mx, my = 0.36 * headRW + tiltRX * 0.6, -0.22 * headRH + tiltUY * 0.4
                if stickFaceMode == 1 then my = -0.12 * headRH + tiltUY * 0.3; mx = 0.28 * headRW + tiltRX * 0.4
                elseif stickFaceMode == 2 then mx = 0.28 * headRW + tiltRX * 0.4; my = -0.28 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 3 then mx = 0.42 * headRW + tiltRX * 0.4; my = -0.30 * headRH + tiltUY * 0.4
                elseif stickFaceMode == 4 then mx = 0.22 * headRW; my = -0.14 * headRH end
                px = mx / math.max(scX, 0.001)
                py = curHeadY + my + fYAdd
                pz = mouthZBase + tiltFZ * 0.7
            end
        elseif stickCrawlActive then
            local crawlHipY  = H * 0.10
            local crawlShY   = H * 0.20
            local crawlHeadY = H * 0.28
            local cPh = ph * 2.9
            local crawlAmp = 1.15
            local scaryJitter = math.sin(t * 18 + u * 9) * 0.07 + math.cos(t * 23 + u * 7) * 0.05
            if u < 0.22 then
                local k = (u - 0.10) / 0.12
                local a = k * math.pi * 2 + t * 0.8
                local twitchA = math.sin(t * 14 + k * 8) * 0.08
                local headFwd = lookD * (0.42 * scZ)
                local headW = originS + Vector3.new(0, crawlHeadY + 2.5 * scY, 0) + headFwd
                local htm = currentMouseHit - headW
                local tiltRight = htm:Dot(rightD) / math.max(htm.Magnitude, 1)
                local tiltUp    = htm.Y / math.max(htm.Magnitude, 1)
                px = math.cos(a + twitchA) * headRW / math.max(scX, 0.001) ^ 0.75 + tiltRight * headRW * 0.10 + scaryJitter * 0.3
                py = crawlHeadY + math.sin(a + twitchA) * headRH * 0.38 + math.sin(cPh) * 0.03 + twitchA * 0.12 + scaryJitter * 0.15
                pz = math.sin(a) * headRW * 0.14
                    + (-math.cos(a) * tiltRight - math.sin(a) * tiltUp) * headRW * 0.26
                    + 0.42 * scZ + math.sin(t * 11 + k * 5) * 0.07
            elseif u < 0.37 then
                local tk = (u - 0.22) / 0.15
                local arch = math.sin(cPh * 1.3 + tk * 4) * 0.08
                py = crawlShY - tk * (crawlShY - crawlHipY) + arch + scaryJitter * 0.08
                px = scaryJitter * 0.15
                pz = (0.45 + tk * 0.30) * scZ + arch * 0.05
            elseif u < 0.73 then
                local isLeft = u < 0.55
                local k = isLeft and ((u - 0.37) / 0.18) or ((u - 0.55) / 0.18)
                local th = math.sin(cPh + (isLeft and 0 or math.pi)) * crawlAmp
                local fwd = math.sin(th) * k * (legLen * 0.62)
                local splay = (isLeft and -1 or 1) * W * 0.68 * k + math.cos(th * 1.4) * k * 0.38
                local down = -math.abs(math.cos(th)) * k * (crawlShY - groundY) * 0.88 + math.sin(t * 16 + k * 6) * 0.06
                px = (fwd * lookD:Dot(rightD) + splay) / math.max(scX, 0.001) + scaryJitter * 0.4
                py = crawlShY + down + scaryJitter * 0.2
                pz = fwd * lookD:Dot(lookD) + math.sin(cPh * 0.9 + k) * 0.16 + scaryJitter
            else
                local isLeft = u < 0.87
                local k = isLeft and ((u - 0.73) / 0.15) or ((u - 0.87) / 0.13)
                local th = math.sin(cPh + math.pi + (isLeft and 0 or math.pi)) * crawlAmp
                local fwd = math.sin(th) * k * (legLen * 0.58)
                local side = (isLeft and -1 or 1) * W * 0.58 * k + math.sin(th * 1.2) * k * 0.22
                local down = -math.cos(th) * k * (crawlHipY - groundY) * 0.94
                if down > 0 then down = down * 0.12 end
                down += math.cos(t * 17 + k * 8) * 0.05
                px = (fwd * lookD:Dot(rightD) + side) / math.max(scX, 0.001) + scaryJitter * 0.4
                py = crawlHipY + down + scaryJitter * 0.15
                pz = fwd * lookD:Dot(lookD) - 0.42 * scZ + math.sin(cPh * 1.0 + k) * 0.13
            end
        elseif stickDanceActive then
            local dT = t * 1.7
            local bob = math.sin(dT * 1.15) * 0.16
            if u < 0.22 then
                local k = (u - 0.10) / 0.12
                local a = k * math.pi * 2 + t * 0.8
                local headW = originS + Vector3.new(0, headC + 2.5 * scY, 0)
                local htm = currentMouseHit - headW
                local tiltRight = htm:Dot(rightD) / math.max(htm.Magnitude, 1)
                local tiltUp    = htm.Y / math.max(htm.Magnitude, 1)
                px = math.cos(a) * headRW / math.max(scX, 0.001) ^ 0.75
                py = headC + math.sin(a) * headRH * 0.55 + bob * 0.95
                pz = math.sin(a) * headRW * 0.22
                    + (-math.cos(a) * tiltRight - math.sin(a) * tiltUp) * headRW * 0.32
                    + math.sin(dT * 0.9 + k * 2) * 0.06
            elseif u < 0.37 then
                local tk = (u - 0.22) / 0.15
                local sway = math.sin(dT + tk * 2) * 0.06 * widenF
                py = (H * 0.80 - tk * (H * 0.80 - hipY)) + bob * 0.85
                px = sway
                pz = math.sin(dT * 0.7 + tk * 3) * 0.04 * scZ
            elseif u < 0.73 then
                local isLeft = u < 0.55
                local k = isLeft and ((u - 0.37) / 0.18) or ((u - 0.55) / 0.18)
                local swingT = dT + (isLeft and 0 or math.pi) + k * 0.6
                local upH    = math.sin(swingT) * k * armLen * 0.52
                local outH   = math.cos(swingT * 0.9) * k * armLen * 0.30
                local sideBase = (isLeft and -1 or 1) * W * 0.50 * k
                local shoulderOff = (isLeft and -2.5 or 2.5) * scR
                px = (sideBase + outH + shoulderOff) / math.max(scX, 0.001)
                py = shY + bob * 0.80 + upH
                pz = math.sin(swingT * 0.6) * k * armLen * 0.24
            else
                local isLeft = u < 0.87
                local k = isLeft and ((u - 0.73) / 0.15) or ((u - 0.87) / 0.13)
                local stepT = dT + (isLeft and 0 or math.pi)
                local thDance = math.sin(stepT) * 0.55
                local sideSway = math.sin(stepT) * k * W * 0.14
                local fwdSwing = lookD * (math.sin(thDance) * k * legLen * 0.14)
                local tapLift  = math.max(0, math.sin(stepT * 2.0)) * k * legLen * 0.22
                local spread = (isLeft and -1 or 1) * W * 0.45 * k + sideSway
                px = (fwdSwing:Dot(rightD) + spread) / math.max(scX, 0.001)
                py = hipY - math.cos(thDance) * k * legLen * 0.95 + bob * 0.80 + tapLift
                pz = fwdSwing:Dot(lookD) + math.sin(dT * 0.8 + k) * 0.04
            end
        elseif u < 0.22 then
            local k = (u - 0.10) / 0.12
            local a = k * math.pi * 2 + t * 0.8
            local headW = originS + Vector3.new(0, headC + 2.5 * scY, 0)
            local htm = currentMouseHit - headW
            local tiltRight = htm:Dot(rightD) / math.max(htm.Magnitude, 1)
            local tiltUp = htm.Y / math.max(htm.Magnitude, 1)
            px = math.cos(a) * headRW / math.max(scX, 0.001) ^ 0.75
            py = headC + math.sin(a) * headRH
            pz = math.sin(a) * headRW * 0.22
                + (-math.cos(a) * tiltRight - math.sin(a) * tiltUp) * headRW * 0.36
        elseif u < 0.37 then
            py = H * 0.80 - ((u - 0.22) / 0.15) * (H * 0.80 - hipY)
        elseif u < 0.73 then
            local isLeft = u < 0.55
            local k = isLeft and ((u - 0.37) / 0.18) or ((u - 0.55) / 0.18)
            local shW = originS
                + rightD * ((isLeft and -2.5 or 2.5) * scR)
                + Vector3.new(0, shY + 2.5 * scY, 0)
            local armLen = H * 0.45
            local blockedMouse = stickmanBlocker(shW, currentMouseHit)
            local delta
            if stickTPose then
                delta = rightD * ((isLeft and -1 or 1) * armLen * 2.5 * k)
            elseif tick() < stickSlapUntil and isLeft == stickArmIsLeft then
                local ad = blockedMouse - shW
                if ad.Magnitude > 0.01 and walkF < 0.3 then
                    local t = (tick() - (stickSlapUntil - 0.5)) / 0.5
                    local sweep = math.sin(t * math.pi) * armLen * 1.2
                    local perp = ad.Unit:Cross(Vector3.yAxis)
                    if perp.Magnitude < 0.01 then perp = rightD end
                    perp = perp.Unit
                    delta = ad.Unit * (k * armLen * 1.5) + perp * sweep * k
                else
                    delta = rightD * ((isLeft and -1 or 1) * armLen * 2.5 * k)
                end
            elseif isLeft == stickArmIsLeft then
                if stickGrabActive then
                    local grabTarget = currentMouseHit
                    local gd    = grabTarget - shW
                    local reach = gd.Magnitude
                    if reach > 0.01 then
                        delta = gd.Unit * (reach * k)
                        return shW + delta
                    end
                end
                local ad = blockedMouse - shW
                if ad.Magnitude > 0.01 then
                    delta = ad.Unit * (k * armLen * 2.0)
                else
                delta = rightD * ((isLeft and -1 or 1) * W * 0.5 * k)
                    + Vector3.new(0, -k * (shY - hipY) * 1.4, 0)
                end
            else
                if tick() < stickWaveUntil and isLeft ~= stickArmIsLeft then
                    local waveT = tick() * 6.2 + k * 0.8
                    local upH   = armLen * (0.88 + math.sin(waveT) * 0.11) * k
                    local sideW = math.sin(waveT * 0.92) * armLen * 0.18 * k
                    local baseSide = (isLeft and -1 or 1) * W * 0.30 * k
                    delta = Vector3.new(0, upH, 0) + rightD * (baseSide + sideW)
                else
                    delta = rightD * ((isLeft and -1 or 1) * W * 0.5 * k)
                        + Vector3.new(0, -k * (shY - hipY) * 1.4, 0)
                end
            end
            local yEnd = shY + delta.Y
            local minY = groundY + 0.4
            if yEnd < minY and delta.Y < -0.001 then
                delta = delta * ((minY - shY) / delta.Y)
            end
            if not stickTPose and not (tick() < stickSlapUntil and isLeft == stickArmIsLeft) and not (tick() < stickWaveUntil and isLeft ~= stickArmIsLeft) then
                if isLeft then
                    local swingTh = math.sin(ph) * amp * 0.75
                    local swingVec = lookD * (math.sin(swingTh) * k * armLen)
                        + Vector3.new(0, -math.cos(swingTh) * k * armLen * 1.0, 0)
                        + rightD * (-W * 0.5 * k)
                    delta = delta:Lerp(swingVec, walkF)
                else
                    local swingTh = math.sin(ph + math.pi) * amp * 0.75
                    local swingVec = lookD * (math.sin(swingTh) * k * armLen)
                        + Vector3.new(0, -math.cos(swingTh) * k * armLen * 1.0, 0)
                        + rightD * (W * 0.5 * k)
                    delta = delta:Lerp(swingVec, walkF)
                end
            end
            local shoulderOff = (isLeft and -2.5 or 2.5) * scR
            px = (delta:Dot(rightD) + shoulderOff) / math.max(scX, 0.001)
            py = shY + delta.Y
            pz = delta:Dot(lookD)
        else
            local isLeft = u < 0.87
            local k = isLeft and ((u - 0.73) / 0.15) or ((u - 0.87) / 0.13)
            local th = math.sin(ph + (isLeft and 0 or math.pi)) * amp
            local spread = (isLeft and -1 or 1) * W * 0.45 * k
            local swingF = lookD * (math.sin(th) * k * legLen)
            px = (swingF:Dot(rightD) + spread) / math.max(scX, 0.001)
            py = hipY - math.cos(th) * k * legLen
            pz = swingF:Dot(lookD)
        end
        return originS
            + rightD * (px * scX)
            + Vector3.new(0, py + 2.5 * scY + math.sin(t * 1.8) * 0.15 + math.abs(math.sin(ph)) * 0.22 * walkF, 0)
            + lookD * pz
            + Vector3.new(
                math.sin(t * 3 + index) * 0.06,
                math.cos(t * 2.6 + index * 1.3) * 0.06,
                math.sin(t * 2.8 + index * 0.7) * 0.06)

    elseif activeMode=="Slinky" then

        local step = math.max(2, math.floor(index * (formRadius * 0.35 + 1.5)))
        local idx  = math.max(1, #slinkyHistory - step)
        local pos  = slinkyHistory[idx] or mHit
        local off = partOffsets[part] or Vector3.zero
        return pos + Vector3.new(off.X*0.35*scX, off.Y*0.35, off.Z*0.35*scZ) + Vector3.new(0, 2 * scY, 0)

    elseif activeMode=="Fountain" then

        local jet = (t * 4.4 + ratio * 1.8) % 1
        local h   = math.sin(jet * math.pi) * formRadius * 2.8 * scY
        local off = partOffsets[part] or Vector3.zero
        local offScaled = Vector3.new(off.X*formRadius*0.35*scX, 0, off.Z*formRadius*0.35*scZ)
        return mHit + offScaled + Vector3.new(0, h + 1.5 * scY, 0)

    elseif activeMode=="Bounce" then

        local phase = (t * 2.8 + index * 0.12) % 2
        local alpha = phase < 1 and phase or (2 - phase)
        local off   = partOffsets[part] or Vector3.zero
        local offScaled = Vector3.new(off.X*0.5*scX, 0, off.Z*0.5*scZ)
        return mHit:Lerp(rp + Vector3.new(0, 7 * scY, 0), alpha) + offScaled

    elseif activeMode=="Ripple" then

        local maxR = math.max(scX, scZ)
        local waveR = ((t * 4.8 - index * 0.18) % (formRadius * 2.2 * maxR + 1)) + 1
        local a     = angle + t * 0.5
        return Vector3.new(mHit.X + math.cos(a) * waveR * scX, mHit.Y + 2 * scY, mHit.Z + math.sin(a) * waveR * scZ)

    elseif activeMode=="Juggle" then

        local toss = math.sin(t * 4.8 + index * 0.75)
        local h    = (toss + 1) * 0.5 * formRadius * scY * 2.2 + 2 * scY
        local spreadX = formRadius * 0.35 * scX
        local spreadZ = formRadius * 0.35 * scZ
        return Vector3.new(
            mHit.X + math.cos(angle) * spreadX,
            mHit.Y + h,
            mHit.Z + math.sin(angle) * spreadZ)

    elseif activeMode=="Constellation" then

        local a   = angle + t * 0.9
        local r   = formRadius * scR * (0.85 + 0.15 * math.sin(index * 1.9 + t * 2))
        local bob = math.sin(t * 3.6 + index * 0.6) * 0.4 * scY
        return Vector3.new(mHit.X + math.cos(a) * r * scX, mHit.Y + 2.5 * scY + bob, mHit.Z + math.sin(a) * r * scZ)


    elseif activeMode=="Rose" then

        local k = 3 + ((total % 4) - 1)  
        local theta = angle + t * 1.2
        local a = formRadius * scR * (0.75 + 0.25*math.sin(t*2.6 + ratio*6))
        local r = a * math.cos(k * theta)

        local y = 2*scY + (math.sin(theta*0.5 + t*3.4 + index*0.12) * 0.8 + ratio*0.3) * (6*scY)
        return Vector3.new(mHit.X + math.cos(theta) * r * scX, mHit.Y + y, mHit.Z + math.sin(theta) * r * scZ)

    elseif activeMode=="OrbitSin" then

        local a = angle + t*1.8
        local baseR = math.max(0.001, formRadius * scR)
        local r = baseR * (0.75 + 0.25*math.sin(t*4.2 + ratio*6 + index*0.08))
        local y = 2*scY + scY*2.5*math.sin(t*2.8 + ratio*math.pi*2) + (partOffsets[part] and partOffsets[part].Y or 0)*0.6
        return Vector3.new(mHit.X + math.cos(a)*r*scX, mHit.Y + y, mHit.Z + math.sin(a)*r*scZ)

    elseif activeMode=="Liss" then

        local u = ratio*math.pi*2 + t*1.1
        local x = math.sin(3*u + t*0.6 + index*0.02)
        local y = math.cos(2*u - t*0.44 + index*0.03)
        local z = math.sin(4*u + t*0.36 - index*0.01)
        local ampX = (formRadius * scR) * 1.0
        local ampY = (formRadius * scY) * 1.0
        local ampZ = (formRadius * scR) * 1.0
        return Vector3.new(mHit.X + x*ampX*scX,
            mHit.Y + y*ampY + 2*scY,
            mHit.Z + z*ampZ*scZ)

    elseif activeMode=="Swing" then

        local swingA = angle + math.sin(t*2.4)*0.35 + t*0.5
        local swingLen = (formRadius*scR) * (0.7 + 0.3*math.sin(t*4.0 + ratio*5))
        local pos = Vector3.new(
            mHit.X + math.cos(swingA)*swingLen*scX,
            mHit.Y + (2.5*scY + math.sin(t*3.2 + index*0.08)*scY*3),
            mHit.Z + math.sin(swingA)*swingLen*scZ)

        local toCursor = currentMouseHit - pos
        local d = toCursor.Magnitude
        if d > 25 then
            local extra = math.clamp((d-25)/60, 0, 2) * (0.18*scR)
            pos = pos + toCursor.Unit * extra
        end

        if formationType == "Mouse" or formationType == "ClickArea" then
            local blend = math.clamp(d / 80, 0, 1) * 0.35
            pos = pos:Lerp(currentMouseHit + Vector3.new(0, 2*scY, 0), blend)
        end
        return pos

    elseif activeMode=="Aura" then
        local rootA = char and char:FindFirstChild("HumanoidRootPart")
        local center = (rootA and rootA.Position or mHit) + Vector3.new(0, 4 * scY, 0)
        local layers = 4
        local layer = (index - 1) % layers
        local k = math.floor((index - 1) / layers)
        local perLayer = math.max(1, math.ceil(total / layers))
        local dirS = (layer % 2 == 0) and 1 or -1
        local a = (k / perLayer) * math.pi * 2 + dirS * t * (1.1 + layer * 0.22)
        local flatV = Vector3.new(stickVelSmooth.X, 0, stickVelSmooth.Z)
        local widen = 1 + math.clamp(flatV.Magnitude / 28, 0, 1) * 0.6
        local r = (formRadius * 1.4 + 3 + layer * 1.6) * scR * widen
        local yBase = (layer - (layers - 1) / 2) * 2.6 * scY
        local bob = math.sin(t * 2.4 + k * 0.9 + layer * 1.7) * 0.9 * scY
        local breathe = 1 + math.sin(t * 1.6 + index * 0.6) * 0.06
        return center + Vector3.new(
            math.cos(a) * r * breathe * scX,
            yBase + bob,
            math.sin(a) * r * breathe * scZ)

    elseif activeMode=="Homing" then
        if homingTarget and homingTarget.Parent and t < homingEndTime then
            local tPos   = homingTarget.Position
            local flight = math.clamp((t - homingFireTime) / 1.1, 0, 1)
            local center = homingLaunchPos:Lerp(tPos, flight * 0.94)
            local toT    = tPos - center
            local dirCF
            if toT.Magnitude > 0.01 then
                dirCF = CFrame.lookAt(center, tPos)
            else
                dirCF = CFrame.new(center)
            end
            local L    = 9 * scR
            local u    = ratio
            local roll = t * 5
            local ax   = (u - 0.5) * L
            local rr, aa
            if u < 0.22 then
                rr = 1.5 * (u / 0.22) * scR
                aa = angle + roll
            elseif u < 0.78 then
                rr = 1.5 * scR
                aa = angle + roll
            else
                rr = 2.6 * scR
                aa = ((index - 1) % 4) * (math.pi / 2) + roll * 0.5
                ax = ax + (u - 0.78) * 2.5 * scR + math.sin(t * 28 + index) * 0.35
            end
            return dirCF:PointToWorldSpace(Vector3.new(
                math.cos(aa) * rr,
                math.sin(aa) * rr,
                ax))
        end
        return mHit + (partOffsets[part] or Vector3.zero) * 0.5

    elseif activeMode=="Railgun" then
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local origin = (myRoot and myRoot.Position or mHit) + Vector3.new(0, 11 * scY, 0)
        local aimDir = currentMouseHit - origin
        aimDir = aimDir.Magnitude > 0.001 and aimDir.Unit or Vector3.new(0, 0, -1)
        if railgunFired then
            if railgunPhase == "firing" then
                local prog = math.clamp((t - railgunPhaseStart) / 0.4, 0, 1)
                local ease = prog * prog
                local bundleOff = (partOffsets[part] or Vector3.zero) * 0.35
                return origin:Lerp(railgunHitPos, ease) + bundleOff + Vector3.new(
                    math.sin(index * 1.9 + t * 40) * 0.3,
                    math.cos(index * 1.7 + t * 36) * 0.3,
                    math.sin(index * 2.5 + t * 44) * 0.3)
            elseif railgunPhase == "exploding" then
                local age = t - railgunPhaseStart
                local out = part.Position - railgunHitPos
                out = out.Magnitude > 0.01 and out.Unit or Vector3.new(0, 1, 0)
                local r = 2 + age * 14
                local a = index * 2.4 + t * 10
                return railgunHitPos + out * r * 0.4 + Vector3.new(
                    math.cos(a) * r,
                    math.abs(math.sin(a)) * r * 0.8 + 1,
                    math.sin(a) * r)
            elseif railgunPhase == "returning" then
                local backPos = origin + Vector3.new(0, 1, 0)
                local p = math.clamp((t - railgunPhaseStart) / 1.2, 0, 1)
                return railgunHitPos:Lerp(backPos, p * p)
            end
        end
        origin = origin + Vector3.new(
            math.sin(t * 0.9) * 1.6 * scX,
            math.sin(t * 1.4) * 0.7 * scY,
            math.cos(t * 0.9) * 1.6 * scZ)
        local aimCF = CFrame.lookAt(origin, origin + aimDir)
        local chargeP = 0
        if railgunCharging then
            chargeP = math.clamp((t - railgunChargeStart) / 1, 0, 1)
        end
        local maxSc   = math.max(scX, scZ)
        local len     = (formRadius * 2.2 + 8) * maxSc
        local spinA   = t * (1.4 + (chargeP ^ 3) * 100)
        local cs, sn  = math.cos(spinA), math.sin(spinA)
        local hw0     = 1.7 * scX
        local hh0     = 1.2 * math.max(scY, 1)
        local coilN   = math.min(math.floor(total * 0.45), math.max(total - 4, 0))
        if index <= coilN then
            local coils   = 5
            local perCoil = math.max(4, math.ceil(coilN / coils))
            local ci      = ((math.floor((index - 1) / perCoil)) % coils) + 1
            local frac    = ((index - 1) % perCoil) / perCoil
            local zi      = -len * 0.88
                + ((ci - 1) / math.max(coils - 1, 1)) * len * 0.84
                + (1 - chargeP) * len * 0.06
            local pulse   = math.sin(t * 9 - ci * 1.3) * 0.14 * (0.35 + chargeP)
            local rr      = 1.9 * maxSc + pulse - chargeP * 0.5 * maxSc
            local aa      = frac * math.pi * 2 + spinA
            local aspect  = (math.abs(hw0) > 0.001) and (hh0 / hw0) or 1
            local res     = aimCF * Vector3.new(math.cos(aa) * rr, math.sin(aa) * rr * aspect, zi)
            local away    = res - origin
            if away.Magnitude < 6 then
                res = origin + (away.Magnitude > 0.01 and away.Unit or Vector3.new(0, 1, 0)) * 6
            end
            return res
        end
        local railIdx = index - coilN
        local railN   = math.max(total - coilN, 1)
        local u       = (((railIdx - 1) % 4) + math.floor((railIdx - 1) / 4))
            / math.max(math.ceil(railN / 4), 1)
        local corner  = (railIdx - 1) % 4
        local taperK  = 1 - 0.38 * math.clamp(u, 0, 1)
        local hw      = hw0 * taperK * (1 - chargeP * 0.22)
        local hh      = hh0 * taperK * (1 - chargeP * 0.22)
        local zi      = -math.clamp(u, 0, 1) * len * 0.92
        local muzzleK = 1 - (u > 0.92 and (chargeP * 0.65) or 0)
        local lx      = ((corner == 0 or corner == 1) and 1 or -1) * hw * muzzleK
        local ly      = ((corner == 0 or corner == 3) and 1 or -1) * hh * muzzleK
        local res     = aimCF * Vector3.new(lx * cs - ly * sn, lx * sn + ly * cs, zi)
        local away    = res - origin
        if away.Magnitude < 6 then
            res = origin + (away.Magnitude > 0.01 and away.Unit or Vector3.new(0, 1, 0)) * 6
        end
        return res

    elseif activeMode=="Barrage" then
        groundY = getGroundYAt(mHit.X, mHit.Z, mHit.Y, part)
        targetY = groundY and (groundY + (part and part.Size.Y * 0.5 or 1) + 0.1) or (mHit.Y + (part and part.Size.Y * 0.5 or 1) + 0.1)
        local launchHeight = math.clamp(35 + math.max(scX, scZ) * 8, 35, 80)
        local dropTime = 0.5
        local timeInFlight = (t + index * 0.12) % dropTime
        local progress = timeInFlight / dropTime
        local spread = 3 * math.max(scX, scZ)
        local offsetX = math.sin(angle + t * 0.8 + index * 0.25) * spread
        local offsetZ = math.cos(angle + t * 0.8 + index * 0.25) * spread
        local height = launchHeight * (1 - progress)
        wobble = math.sin(progress * math.pi) * 2
        return Vector3.new(
            mHit.X + offsetX,
            targetY + height + wobble,
            mHit.Z + offsetZ)

    elseif activeMode=="Sinewave" then
        local x = (ratio - 0.5) * formRadius * 4 * scX
        local z = (ratio - 0.5) * formRadius * 4 * scZ
        local wave1 = math.sin(x * 0.5 + t * 4) * math.cos(z * 0.5 + t * 3)
        local wave2 = math.cos(x * 0.3 - t * 3.6) * math.sin(z * 0.4 + t * 4.4)
        local wave3 = math.sin((x + z) * 0.2 + t * 5)
        local y = (wave1 + wave2 + wave3) * formRadius * 0.8 * scY
        return Vector3.new(mHit.X + x, mHit.Y + y + 3 * scY, mHit.Z + z)

    elseif activeMode=="Heart" then
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or mHit
        local lookDir = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
        local rightDir = root and root.CFrame.RightVector or Vector3.new(1, 0, 0)
        local upDir = root and root.CFrame.UpVector or Vector3.new(0, 1, 0)
        
        local theta = ratio * math.pi * 2 + t * 1.0
        local heartScale = formRadius * scR * 0.8
        local x = 16 * math.sin(theta)^3
        local y = 13 * math.cos(theta) - 5 * math.cos(2*theta) - 2 * math.cos(3*theta) - math.cos(4*theta)
        local z = math.sin(theta * 2 + t * 2) * heartScale * 0.3
        local pulse = 1 + 0.1 * math.sin(t * 6)
        
        local localPos = Vector3.new(x * heartScale * 0.05, y * heartScale * 0.05 + 5, z * 0.3)
        local worldPos = origin + rightDir * localPos.X * scX * pulse + upDir * localPos.Y * scY * pulse + lookDir * localPos.Z * scZ
        
        return worldPos

    elseif activeMode=="Wings" then
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or mHit
        local lookDir = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
        local rightDir = root and root.CFrame.RightVector or Vector3.new(1, 0, 0)
        local upDir = root and root.CFrame.UpVector or Vector3.new(0, 1, 0)
        local side = (index % 2 == 0) and 1 or -1
        local k = math.floor((index - 1) / 2)
        local perWing = math.max(1, math.ceil(total / 2))
        local COLS = math.max(3, math.floor(math.sqrt(perWing * 2.2)))
        local ROWS = math.max(2, math.ceil(perWing / COLS))
        local col = k % COLS
        local row = math.floor(k / COLS) % ROWS
        local spanF = COLS > 1 and col / (COLS - 1) or 0
        local chordF = ROWS > 1 and row / (ROWS - 1) or 0.5

        local spanLen = formRadius * 2.2 * scR
        local chord0 = math.max(formRadius * 0.85, 1.5) * scR
        local chord = chord0 * (1 - 0.62 * spanF)
        local xOut = (1.0 * scR + spanF * spanLen)
        local zBack = (spanF * spanF * 1.4 * scR) + chordF * chord
        local camber = math.sin(chordF * math.pi) * 0.35 * scY

        local flap = math.sin(t * 4 - spanF * 1.6) * 0.55 + 0.12
        local xLift = xOut * math.sin(flap) + camber * math.cos(flap)
        local xFlat = xOut * math.cos(flap) - camber * math.sin(flap)
        local tipF = spanF * chordF
        local splay = tipF * tipF * 1.1 * scR

        local shoulderY = 2
        local lx = side * (xFlat + splay * 0.3)
        local ly = shoulderY + xLift + tipF * 0.8 * scY
        local lz = -(zBack + splay)
        return origin + rightDir * (lx * scX) + upDir * ly + lookDir * (lz * scZ)

    elseif activeMode=="Crystal" then
        local crystalLayers = 5
        local layer = (index - 1) % crystalLayers
        local layerIdx = math.floor((index - 1) / crystalLayers)
        local layerTotal = math.ceil(total / crystalLayers)
        
        local layerScale = 1 - layer * 0.15
        local layerRadius = formRadius * layerScale * scR
        local layerY = layer * formRadius * 0.8 * scY
        
        local phi = (1 + math.sqrt(5)) / 2
        local theta = 2 * math.pi * layerIdx / phi + t * 0.6 * (layer + 1)
        local yLat = 1 - 2 * (layerIdx / math.max(layerTotal - 1, 1))
        local yLatSin = math.sqrt(math.max(0, 1 - yLat * yLat))
        
        local x = yLatSin * math.cos(theta) * layerRadius
        local y = yLat * layerRadius + layerY
        local z = yLatSin * math.sin(theta) * layerRadius
        
        local sparkle = math.sin(t * 5 + index * 0.7) * 0.1
        return Vector3.new(
            mHit.X + x * scX * (1 + sparkle),
            mHit.Y + y + 3 * scY,
            mHit.Z + z * scZ * (1 + sparkle))

    elseif activeMode=="TwinStars" then
        local orbitR = (formRadius * 1.1 + 4) * scR
        local coreA  = t * 1.5
        local bob    = math.sin(t * 1.1) * 1.5 * scY
        local c1     = mHit + Vector3.new(math.cos(coreA) * orbitR, 4 * scY + bob, math.sin(coreA) * orbitR)
        local c2     = mHit + Vector3.new(math.cos(coreA + math.pi) * orbitR, 4 * scY - bob, math.sin(coreA + math.pi) * orbitR)
        local off    = partOffsets[part] or Vector3.zero
        local jx, jy, jz = index, index * 1.3, index * 1.7
        if index % 2 == 1 then
            return c1 + off * 0.55 + Vector3.new(
                math.sin(t * 9 + jx) * 0.18,
                math.cos(t * 8 + jx) * 0.18,
                math.sin(t * 7 + jx) * 0.18)
        else
            return c2 + off * 0.55 + Vector3.new(
                math.sin(t * 9 + jz) * 0.18,
                math.cos(t * 8 + jy) * 0.18,
                math.sin(t * 7 + jz) * 0.18)
        end

    elseif activeMode=="Tesseract" then
        if not _tessVerts then
            _tessVerts = {}
            for v = 0, 15 do
                _tessVerts[v + 1] = {
                    (v % 2 == 0) and -1 or 1,
                    (math.floor(v / 2) % 2 == 0) and -1 or 1,
                    (math.floor(v / 4) % 2 == 0) and -1 or 1,
                    (math.floor(v / 8) % 2 == 0) and -1 or 1,
                }
            end
            _tessEdges = {}
            for i = 0, 15 do
                for b = 0, 3 do
                    local j = bit32.bxor(i, bit32.lshift(1, b))
                    if j > i then
                        _tessEdges[#_tessEdges + 1] = { i + 1, j + 1 }
                    end
                end
            end
        end
        local H      = math.max(formRadius, 5) * math.max(scX, math.max(scY, scZ)) * 1.35
        local perEdge = math.max(1, math.ceil(total / #_tessEdges))
        local e       = _tessEdges[(math.floor((index - 1) / perEdge) % #_tessEdges) + 1]
        local f       = ((index - 1) % perEdge) / math.max(perEdge - 1, 1)
        local va, vb  = _tessVerts[e[1]], _tessVerts[e[2]]
        local ax = va[1] + (vb[1] - va[1]) * f
        local ay = va[2] + (vb[2] - va[2]) * f
        local az = va[3] + (vb[3] - va[3]) * f
        local aw = va[4] + (vb[4] - va[4]) * f

        local a1 = t * 0.55
        local a2 = t * 0.34
        local ca, sa = math.cos(a1), math.sin(a1)
        local cb, sb = math.cos(a2), math.sin(a2)
        local x1 = ax * ca - aw * sa
        local w1 = ax * sa + aw * ca
        local y1 = ay * cb - az * sb
        local z1 = ay * sb + az * cb

        local a3 = t * 0.21
        local cc, sc = math.cos(a3), math.sin(a3)
        local z2 = z1 * cc - w1 * sc
        local w2 = z1 * sc + w1 * cc

        local dist   = H * 3.2
        local denom  = math.max(dist - w2 * H, H * 0.9)
        local persp  = dist / denom
        local spinCF = CFrame.Angles((t * 0.19) % (math.pi*2), (t * 0.27) % (math.pi*2), 0)
        local sv     = Vector3.new(x1 * H * persp, y1 * H * persp, z2 * H * persp)
        local rv     = spinCF:VectorToWorldSpace(sv)
        return mHit + rv + Vector3.new(0, 5 * scY, 0)

    elseif activeMode=="Atom" then
        local nucleusN = math.max(1, math.floor(total * 0.12))
        if index <= nucleusN then
            local off   = partOffsets[part] or Vector3.zero
            local pulse = 1 + math.sin(t * 5 + index) * 0.12
            return mHit + Vector3.new(0, 4 * scY, 0) + off * 1.1 * pulse
        end
        local rem        = index - nucleusN
        local shells     = 3
        local shell      = (rem - 1) % shells
        local idxInShell = math.floor((rem - 1) / shells)
        local perShell   = math.ceil((total - nucleusN) / shells)
        local ringTilt   = (shell / shells) * math.pi + math.sin(t * 0.5 + shell) * 0.25
        local spin       = t * (1.5 + shell * 0.65)
        local a          = (idxInShell / math.max(perShell, 1)) * math.pi * 2 + spin
        local r          = (formRadius * 1.5 + shell * 3.2) * scR
        local lx = math.cos(a) * r
        local lz = math.sin(a) * r
        local ly = lz * math.sin(ringTilt)
        lz = lz * math.cos(ringTilt)
        return mHit + Vector3.new(lx * scX, ly + 4 * scY, lz * scZ)

    elseif activeMode=="Lightning" then
        if lightningFired[part] and #lightningBolt >= 2 then
            local age = t - lightningFireTime
            local stagger = ratio * 0.08
            local prog = (age - stagger) / LIGHTNING_TRAVEL
            if prog < 1 then
                prog = math.clamp(prog, 0, 1)
                local f   = prog * (#lightningBolt - 1)
                local seg = math.min(math.floor(f) + 1, #lightningBolt - 1)
                local frac = f - (seg - 1)
                local pa = lightningBolt[seg]
                local pb = lightningBolt[seg + 1]
                return pa:Lerp(pb, frac) + Vector3.new(
                    math.sin(t * 47 + index * 2.1) * 0.5,
                    math.cos(t * 39 + index * 1.7) * 0.5,
                    math.sin(t * 43 + index * 2.6) * 0.5)
            elseif age < LIGHTNING_TRAVEL + LIGHTNING_HOLD then
                local ia = angle * 3 + t * 14
                local ir = 2 + (age - LIGHTNING_TRAVEL) * 9
                return lightningTarget + Vector3.new(
                    math.cos(ia) * ir,
                    math.abs(math.sin(ia * 1.3)) * ir * 0.6 + 1,
                    math.sin(ia) * ir)
            end
        end
        local cl = ((index - 1) * 2.399) % (math.pi * 2)
        local cr = (2.5 + ((index * 13) % 7) * 0.35) * scR
        return rp + Vector3.new(
            math.cos(cl + t * 0.8) * cr,
            12 * scY + math.sin(t * 2.2 + index * 1.3) * 1.2,
            math.sin(cl + t * 0.8) * cr)

    elseif activeMode=="Sniper" then
        local rootN   = char and char:FindFirstChild("HumanoidRootPart")
        local centerS = (rootN and rootN.Position or mHit) + Vector3.new(0, 9 * scY, 0)
        local ringR   = math.max(SNIPER_R * scR, 2)
        local faceCF  = rootN and rootN.CFrame or CFrame.identity
        local since = t - sniperFireTime
        local tgtP  = sniperTargetPos
        local firingNow = (tgtP ~= Vector3.zero and since >= 0 and since <= SNIPER_CYCLE)
        local spin = t * (firingNow and 2.4 or 1.25)
        local rightV = faceCF.RightVector
        local upV = Vector3.yAxis
        if not firingNow then
            local crossN = math.clamp(math.floor(total * 0.4), 5, 16)
            crossN = math.min(crossN, total)
            if total < 6 then crossN = total end
            if index <= crossN then
                if index == 1 then
                    local wob = t * 2.4
                    return centerS
                        + rightV * (math.cos(wob) * 0.45 * scR)
                        + upV * (math.sin(wob * 1.3) * 0.45 * scR)
                        + Vector3.new(0, math.sin(t * 3.1) * 0.12, 0)
                end
                local arms = 4
                local perArm = math.max(1, math.ceil((crossN - 1) / arms))
                local k = index - 2
                local arm = k % arms
                local slot = math.floor(k / arms) + 1
                local armAng = -spin + arm * (math.pi / 2) 
                local dir = rightV * math.cos(armAng) + upV * math.sin(armAng)
                local frac = slot / perArm
                local dist = (0.25 + 0.55 * frac) * ringR
                local tang = rightV * (-math.sin(armAng)) + upV * math.cos(armAng)
                return centerS + dir * dist + tang * (0.35 * scR)
            else
                local ringCount = total - crossN
                local j = index - crossN 
                local ringAng = spin + ((j - 1) / math.max(ringCount, 1)) * math.pi * 2
                return centerS
                    + rightV * (math.cos(ringAng) * ringR)
                    + upV * (math.sin(ringAng) * ringR)
            end
        end
        local ca      = ((index - 1) / math.max(total, 1)) * math.pi * 2 + spin
        local slotP   = centerS
            + rightV * (math.cos(ca) * ringR)
            + Vector3.yAxis * (math.sin(ca) * ringR)
        local delay = ((index - 1) / math.max(total, 1)) * 0.35
        local tp    = since - delay
        local firing = firingNow
        if tgtP ~= Vector3.zero and tp >= 0 and tp <= SNIPER_CYCLE then
            if tp < 0.3 then
                local pr = tp / 0.3
                return slotP:Lerp(tgtP, pr * pr)
            elseif tp < 0.55 then
                local ba = angle * 3 + t * 18
                local br = 1.2 * scR + math.sin(t * 21 + index) * 0.3
                return tgtP + Vector3.new(
                    math.cos(ba) * br,
                    math.abs(math.sin(ba)) * br * 0.7,
                    math.sin(ba) * br)
            else
                local pr = math.clamp((tp - 0.55) / (SNIPER_CYCLE - 0.55), 0, 1)
                return tgtP:Lerp(slotP, pr * pr)
            end
        end
        return slotP

    elseif activeMode=="Bridge" then
        if bridgeSlots[part] and typeof(bridgeSlots[part]) == "Vector3" then
            return bridgeSlots[part]
        end
        return mHit + (partOffsets[part] or Vector3.zero) * 0.5

    elseif activeMode=="Boomerang" then
        local rootBm2 = char and char:FindFirstChild("HumanoidRootPart")
        local homeC   = (rootBm2 and rootBm2.Position or mHit) + Vector3.new(0, 7 * scY, 0)
        local centerB, travelD, tiltB
        if boomerangActive then
            local u     = math.clamp((t - boomerangStart) / BOOMERANG_T, 0, 1)
            local dv    = boomerangTarget - boomerangOrigin
            local D     = dv.Magnitude
            local dirU  = D > 0.01 and dv.Unit or Vector3.new(0, 0, -1)
            local sideU = Vector3.yAxis:Cross(dirU)
            local s     = math.sin(u * math.pi)
            centerB = boomerangOrigin
                + dirU * (s * (D + math.min(D * 0.48, 42)))
                + sideU * (math.sin(u * math.pi * 2) * -D * 0.16)
                + Vector3.new(0, math.sin(u * math.pi) * 6, 0)
            travelD = dirU * (u < 0.5 and 1 or -1)
            tiltB   = 76
        else
            centerB = homeC + Vector3.new(
                math.sin(t * 0.9) * 1.2,
                math.sin(t * 1.6) * 0.5,
                math.cos(t * 0.9) * 1.2)
            travelD = Vector3.new(math.cos(t * 0.5), 0, math.sin(t * 0.5))
            tiltB   = 14
        end
        local cfB   = CFrame.lookAt(centerB, centerB + travelD) * CFrame.Angles(math.rad(tiltB), 0, 0)
        local spinB = t * 22
        local ringB = (index - 1) % 3
        local rrB   = formRadius * scR * (0.45 + ringB * 0.32)
        local aaB   = (math.floor((index - 1) / 3) / math.max(math.ceil(total / 3), 1)) * math.pi * 2
            + spinB * (1 + ringB * 0.12)
        return cfB * Vector3.new(math.cos(aaB) * rrB, math.sin(t * 17 + index) * 0.15, math.sin(aaB) * rrB)

    elseif activeMode=="Strike" then
        local maxScL = math.max(scX, scZ)
        local baseC  = rp + Vector3.new(0, STRIKE_H * scY, 0)
        local nucN   = math.max(1, math.floor(total * 0.1))
        local function idlePos()
            if index <= nucN then
                local off   = partOffsets[part] or Vector3.zero
                local pulse = 1 + math.sin(t * 6 + index) * 0.15
                return baseC + off * 1.2 * pulse
            end
            local rem    = index - nucN
            local shells = 4
            local shell  = (rem - 1) % shells
            local iis    = math.floor((rem - 1) / shells)
            local perS   = math.ceil((total - nucN) / shells)
            local tilt   = (shell / shells) * math.pi + math.sin(t * 0.7 + shell * 1.7) * 0.35
            local a      = (iis / math.max(perS, 1)) * math.pi * 2 + t * (1.8 + shell * 0.5)
            local r      = (formRadius * 1.7 + shell * 2.6) * scR
            local lx = math.cos(a) * r
            local lz = math.sin(a) * r
            local ly = lz * math.sin(tilt)
            lz = lz * math.cos(tilt)
            return baseC + Vector3.new(lx * scX, ly, lz * scZ)
        end
        if strikeState ~= "idle" and strikeTarget ~= Vector3.zero then
            local age  = t - strikeStart
            local stag = ratio * 0.10
            if strikeState == "descend" then
                local prog = math.clamp((age - stag) / STRIKE_DESCEND, 0, 1)
                local aa   = angle * 2 + t * 20
                local rr   = (2.5 * (1 - prog) + 0.3) * maxScL
                local pos  = (strikeTarget + Vector3.new(0, 70, 0)):Lerp(strikeTarget, prog * prog)
                return pos + Vector3.new(math.cos(aa) * rr, 0, math.sin(aa) * rr)
            elseif strikeState == "drill" then
                local ia = angle * 3 + t * 24
                local ir = (0.8 + ((index * 7) % 5) * 0.35) * maxScL + math.sin(t * 24 + index) * 0.4
                return strikeTarget + Vector3.new(
                    math.cos(ia) * ir,
                    math.abs(math.sin(t * 13 + index * 1.3)) * ir * 0.8 + 0.5,
                    math.sin(ia) * ir)
            elseif strikeState == "return" then
                local prog = math.clamp((age - stag) / STRIKE_RETURN, 0, 1)
                return strikeTarget:Lerp(idlePos(), prog * prog)
            end
        end
        return idlePos()
    elseif activeMode=="Pentagram" then
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or mHit
        origin = origin + Vector3.new(0, 5*scY, 0)
        local lookDir = root and root.CFrame.LookVector or Vector3.new(0,0,-1)
        local rightDir = root and root.CFrame.RightVector or Vector3.new(1,0,0)
        local upDir = root and root.CFrame.UpVector or Vector3.new(0,1,0)
        local pentR = formRadius * 1.6
        local verts = {}
        for i=0,4 do
            local th = math.rad(-90) + i*math.pi*2/5
            verts[i+1] = Vector2.new(math.cos(th)*pentR, math.sin(th)*pentR)
        end
        local order = {1,3,5,2,4}
        local pulse = 1 + 0.06*math.sin(t*2.5 + index*0.15)
        local circleN = total < 12 and 0 or math.clamp(math.floor(total * 0.35), 8, 40)
        local starCount = total - circleN
        if circleN > 0 and index > starCount then
            local j = index - starCount
            local a = ((j - 1) / circleN) * math.pi * 2 + t * 0.5
            local cr = pentR * 1.18 * pulse
            local lx = math.cos(a) * cr
            local ly = math.sin(a) * cr
            return origin + rightDir*(lx*scX*0.55) + upDir*(ly*scY*0.55) + lookDir*0.2
        end
        local perEdge = math.max(1, math.ceil(starCount/5))
        local eIdx = ((index-1) % 5) + 1
        local seg = math.floor((index-1)/5)
        local tEdge = perEdge>1 and seg/(perEdge-1) or 0.5
        local aIdx = order[eIdx]
        local bIdx = order[eIdx %5 +1]
        local pa = verts[aIdx]; local pb = verts[bIdx]
        local lx = pa.X + (pb.X - pa.X)*tEdge
        local ly = pa.Y + (pb.Y - pa.Y)*tEdge
        lx = lx * pulse; ly = ly * pulse
        return origin + rightDir*(lx*scX*0.55) + upDir*(ly*scY*0.55) + lookDir*0.2

    elseif activeMode=="Text" then
        ensureTextAssignment()
        local pd = textAssignment[part] or textAssignment[index]
        if not pd or not pd.pos then
            if textCachedString ~= textContent or not textCachedPoints then
                textCachedPoints = getTextPixelPoints(textContent)
                textCachedString = textContent
            end
            local pts = textCachedPoints
            if not pts or #pts==0 then
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local origin = root and root.Position or mHit
                return origin + Vector3.new(0, 5*scY, 0)
            end
            local totalPts = #pts
            local pt
            if total >= totalPts and totalPts>0 then
                local pi = ((index-1) % totalPts)+1
                pt = pts[pi]
            elseif totalPts>0 then
                local fi = math.floor((index-1)/math.max(total-1,1)*(totalPts-1))+1
                pt = pts[math.clamp(fi,1,totalPts)]
            else
                pt = Vector2.new(0,0)
            end
            pd = {pos=pt, angle=0}
        end
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or mHit
        local look0 = root and root.CFrame.LookVector or Vector3.new(0,0,-1)
        local lookDir = Vector3.new(look0.X, 0, look0.Z)
        if lookDir.Magnitude < 0.01 then lookDir = Vector3.new(0,0,-1) else lookDir = lookDir.Unit end
        local upDir = Vector3.new(0,1,0)
        local rightDir = Vector3.new(lookDir.Z, 0, -lookDir.X).Unit
        origin = origin + lookDir*6*math.max(scX,scZ) + Vector3.new(0, 5*scY, 0)
        local avg = getAvgPartSize()
        local avgScale = avg * 0.78 + 0.22
        local formScale = (formRadius/7)*0.38 + 0.62
        local scScale = math.max(scX, math.max(scY, scZ))*0.38 + 0.62
        local textScale = avgScale * formScale * scScale
        textScale = math.clamp(textScale, 0.45, 6) * (TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP) * 0.92
        local pt = pd.pos
        local midY = TEXT_LETTER_H*0.5*(TEXT_PIXEL_SIZE+TEXT_PIXEL_GAP)
        local jitter = Vector3.new(math.sin(t*9+index*1.1)*0.06, math.cos(t*8+index)*0.06, math.sin(t*11+index)*0.06)
        return origin + rightDir*(pt.X*textScale) + upDir*((pt.Y - midY)*textScale) + jitter

    elseif activeMode=="Scythe" then
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local rpS = root and root.Position or mHit
        local lookDir = root and root.CFrame.LookVector or Vector3.new(0,0,-1)
        lookDir = Vector3.new(lookDir.X, 0, lookDir.Z)
        if lookDir.Magnitude < 0.01 or lookDir.Magnitude ~= lookDir.Magnitude then lookDir = Vector3.new(0,0,-1) else lookDir = lookDir.Unit end
        local rightDir = lookDir:Cross(Vector3.yAxis)
        local upDir = Vector3.yAxis
        local handleLen = formRadius*1.35*scY + 4.2
        local bladeR = formRadius*0.95*scR + 1.5
        local spin = t*0.85
        local swingP = 0
        local isSwing = scytheState=="swing"
        if isSwing then
            local rawP = (t - scytheStart)/SCYTHE_SWING
            if rawP < 1 then swingP = rawP
            elseif rawP < 2 then swingP = 2 - rawP
            else swingP = 1 end
            swingP = math.clamp(swingP,0,1)
        end
        local sweep = 0
        if isSwing then
            local ease = swingP*swingP*(3-2*swingP)
            sweep = math.rad(-85 + ease*170)
        end
        local cosS, sinS = math.cos(sweep), math.sin(sweep)
        local origin
        if isSwing then
            origin = scytheSwingPos
            if origin == Vector3.zero then
                origin = currentMouseHit + Vector3.new(0,0.4,0)
            end
        else
            origin = rpS - rightDir * (handleLen*0.6) + upDir * 2
            origin = origin + Vector3.new(math.sin(t*0.9)*0.7, math.sin(t*1.3)*0.35, math.cos(t*0.9)*0.7)
        end
        scytheCenter = origin
        local lx, ly, lz
        local r = ratio
        if r < 0.62 then
            local hr = r/0.62
            lx = math.sin(spin*0.6 + index*0.4)*0.12
            ly = hr*handleLen
            lz = math.cos(spin*0.4+index)*0.08
        else
            local br = (r-0.62)/0.38
            local tt = math.pow(br, 0.90)
            local tipU = handleLen - bladeR*0.38
            local tipL = bladeR*1.75
            local ctrlU = handleLen + bladeR*0.30
            local ctrlL = bladeR*0.80
            local au = handleLen + (ctrlU - handleLen)*tt
            local al = ctrlL*tt
            local bu = ctrlU + (tipU - ctrlU)*tt
            local bl = ctrlL + (tipL - ctrlL)*tt
            local belly = math.sin(br*math.pi) * bladeR*0.06
            lx = math.sin(br*math.pi*0.7)*bladeR*0.04
            ly = (au + (bu - au)*tt) - belly*0.55
            lz = (al + (bl - al)*tt) + belly*0.22
        end
        if isSwing then ly = ly - handleLen*0.5 end
        local wx, wy, wz
        if isSwing then
            local cosL, sinL = math.cos(math.rad(90)), math.sin(math.rad(90))
            local rx = lx*cosL - ly*sinL
            local ry = lx*sinL + ly*cosL
            wx = rx*cosS + lz*sinS
            wz = -rx*sinS + lz*cosS
            wy = ry
        else
            local leanP = math.rad(52 + math.sin(t*0.7)*6)
            local cosP, sinP = math.cos(leanP), math.sin(leanP)
            wx = lx
            wy = ly*cosP - lz*sinP
            wz = ly*sinP + lz*cosP
        end
        wx, wz = wz, -wx
        return origin + rightDir*wx + upDir*wy + lookDir*wz
    elseif activeMode=="Chained" then
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local rp = root and root.Position or mHit
        local rightDir = root and root.CFrame.RightVector or Vector3.new(1,0,0)
        local upDir = root and root.CFrame.UpVector or Vector3.new(0,1,0)
        local lookDir = root and root.CFrame.LookVector or Vector3.new(0,0,-1)
        local crownN = math.max(4, math.floor(total*0.22))
        if crownN > total then crownN = total end
        local ringTotal = total - crownN
        local leftN = math.floor(ringTotal/2)
        local rightN = ringTotal - leftN
        if index > leftN + rightN then
            local cIdx = index - leftN - rightN
            local cRatio = crownN>1 and (cIdx-1)/(crownN-1) or 0
            local a = cRatio*math.pi*2 + t*0.7
            local radius = formRadius*0.85*scR + 1.9
            local crownCenter = rp + upDir*(7.8*scY) + lookDir*0.2
            local rPulse = radius * (1 + math.sin(t*2.2 + cIdx*0.5)*0.06)
            local isSpike = (cIdx % 4 == 1)
            local h = isSpike and (1.4*scY + math.sin(t*3.2 + cIdx)*0.25) or (math.sin(t*2.6 + cIdx*0.7)*0.18*scY)
            local pos = crownCenter + rightDir*math.cos(a)*rPulse + lookDir*math.sin(a)*rPulse + upDir*h
            return pos + Vector3.new(math.sin(t*5+cIdx)*0.10, math.cos(t*4+cIdx)*0.07, math.sin(t*6+cIdx)*0.08)
        end
        local isLeft = index <= leftN
        local hand = isLeft and (rp + (-rightDir*1.45*scR + upDir*0.45*scY + lookDir*0.35*scR)) or (rp + (rightDir*1.45*scR + upDir*0.45*scY + lookDir*0.35*scR))
        local ringN = isLeft and leftN or rightN
        local localIdx = isLeft and index or (index - leftN)
        local firing = chainedActive and chainedFired[part] and chainedTarget ~= Vector3.zero
        if firing then
            local rRatio = ringN>1 and (localIdx-1)/(ringN-1) or 0
            local toT = chainedTarget - hand
            if toT.Magnitude < 0.1 then return hand end
            local targetPos = hand:Lerp(chainedTarget, rRatio)
            local helixTurns = 3.4
            local helixA = rRatio*helixTurns*math.pi*2 + t*4.2 + localIdx*0.35
            local helixR = 0.42*scR + math.sin(t*3.1 + localIdx*0.7)*0.06*scR
            local dir = toT.Magnitude>0.01 and toT.Unit or lookDir
            local perp = dir:Cross(Vector3.yAxis)
            if perp.Magnitude < 0.01 then perp = rightDir end
            perp = perp.Unit
            local binorm = dir:Cross(perp).Unit
            local helixOffset = perp*math.cos(helixA)*helixR + binorm*math.sin(helixA)*helixR
            local sag = math.sin(rRatio*math.pi) * 0.6*scY
            local twitch = Vector3.new(math.sin(t*7 + localIdx*1.2)*0.10, math.sin(t*6.5 + localIdx*0.9)*0.08, math.cos(t*5.2+localIdx*0.7)*0.10)
            local kink = (localIdx % 3 == 0) and (perp*math.sin(rRatio*18 + t*2)*0.18*scR) or Vector3.zero-- wow so kinky right
            return targetPos + helixOffset + Vector3.new(0, -sag, 0) + twitch*0.6 + kink
        else
            local radius = formRadius*0.95*scR + 2.4
            local center = isLeft and (hand + (-rightDir*radius*0.95)) or (hand + (rightDir*radius*0.95))
            local ringRatio = ringN>1 and (localIdx-1)/ringN or 0
            local a = ringRatio*math.pi*2 + t*1.5 + (isLeft and 0 or math.pi*0.12) + math.sin(t*2.2 + localIdx*0.9)*0.18
            local wobbleR = radius * (1 + math.sin(t*3.1 + localIdx*0.6)*0.05)-- stuff
            local basePos = center + (rightDir*math.cos(a) + lookDir*math.sin(a))*wobbleR
            local linkLift = (localIdx % 2 == 0 and 0.16 or -0.16)*scY + math.sin(t*2.4 + localIdx*1.1)*0.06*scY
            local linkPush = (localIdx % 2 == 0 and 0.10 or -0.10)*scR
            local tangent = (-rightDir*math.sin(a) + lookDir*math.cos(a)).Unit
            basePos = basePos + upDir*linkLift + tangent*linkPush*0.5
            basePos = basePos + upDir*(math.sin(a*2 + t*2.4)*0.12*scY) + Vector3.new(math.sin(t*3+localIdx)*0.05, 0, math.cos(t*3+localIdx)*0.05)
            return basePos
        end
    elseif activeMode=="Knot" then
        local a = angle + t*0.4
        local kx = formRadius*scX*2
        local ky = formRadius*scY*2
        local kz = formRadius*scZ*2
        local px = (math.sin(a) + 2*math.sin(2*a))/3
        local py = (math.cos(a) - 2*math.cos(2*a))/3
        local pz = -math.sin(3*a)/1.5
        return Vector3.new(mHit.X + px*kx, mHit.Y + py*ky + 3*scY, mHit.Z + pz*kz)
    elseif activeMode=="Mobius" then
        local u = angle + t*0.3
        local v = (((index * 0.61803398875) % 1) - 0.5)*0.9
        local tw = u*0.5 + t*0.1
        local rad = 1 + v*math.cos(tw)
        local mr = formRadius
        return Vector3.new(mHit.X + rad*math.cos(u)*mr*scX, mHit.Y + v*math.sin(tw)*mr*scY*0.6 + 3*scY, mHit.Z + rad*math.sin(u)*mr*scZ)
    elseif activeMode=="Gyro" then
        local k = (index-1) % 3
        local j = math.floor((index-1)/3)
        local n3 = math.max(math.ceil(total/3), 1)
        local spd = 0.9
        if k == 1 then spd = -1.2 elseif k == 2 then spd = 1.5 end
        local ga = j/n3*math.pi*2 + t*spd
        local R = formRadius*scR
        local px, py, pz = 0, 0, 0
        local rx, ry, rz = 0, 0, 0
        if k == 0 then
            px = math.cos(ga)*R*scX
            py = math.sin(ga)*R*scY
            rx = (t*0.5) % (math.pi*2)
            ry = (t*0.3) % (math.pi*2)
        elseif k == 1 then
            px = math.cos(ga)*R*scX
            pz = math.sin(ga)*R*scZ
            ry = (-t*0.7) % (math.pi*2)
            rz = (t*0.4) % (math.pi*2)
        else
            py = math.cos(ga)*R*scY
            pz = math.sin(ga)*R*scZ
            rx = (-t*0.5) % (math.pi*2)
            rz = (t*0.9) % (math.pi*2)
        end
        local off = CFrame.Angles(rx, ry, rz) * Vector3.new(px, py, pz)
        return Vector3.new(mHit.X + off.X, mHit.Y + off.Y + 3*scY, mHit.Z + off.Z)
    elseif activeMode=="RoseV2" then
        local th = index*1.239184 + t*0.2
        local mrr = math.sin(6*th)
        local R2 = formRadius*scR
        return Vector3.new(mHit.X + mrr*math.cos(th)*R2*scX, mHit.Y + 3*scY + math.sin(t*2 + index)*0.15*scY, mHit.Z + mrr*math.sin(th)*R2*scZ)
    end

    return mHit
end

local function applyFormRot(part, pos)
    if ROT_BLOCK[activeMode] then return pos end
    if formRotX == 0 and formRotY == 0 and formRotZ == 0 then return pos end
    local center
    if RP_PIVOT[activeMode] then
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        center = (root and root.Position or pos) + Vector3.new(0, formOffsetY, 0)
    else
        center = getFormationCenterTarget() + Vector3.new(0, formOffsetY, 0)
    end
    local rot = CFrame.Angles(math.rad(formRotX), math.rad(formRotY), math.rad(formRotZ))
    return center + rot * (pos - center)
end


local function impactBurst(pos, radius, power)
    local seen = 0
    local function fling(obj)
        if seen >= 120 then return end
        if obj:IsA("BasePart") and not obj.Anchored and not isVelImmune(obj) and obj ~= workspace.Terrain
           and not isSelected(obj) and not isLocalPlayerPart(obj)
           and (obj.Position - pos).Magnitude <= radius then
            seen += 1
            pcall(function()
                local dir = obj.Position - pos
                dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 1, 0)
                obj.AssemblyLinearVelocity = obj.AssemblyLinearVelocity
                    + dir * power + Vector3.new(0, power * 0.35, 0)
                obj.AssemblyAngularVelocity = obj.AssemblyAngularVelocity + Vector3.new(
                    (math.random() - 0.5) * power,
                    (math.random() - 0.5) * power,
                    (math.random() - 0.5) * power)
            end)
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        fling(obj)
        if obj:IsA("Model") or obj:IsA("Folder") then
            for _, child in ipairs(obj:GetChildren()) do fling(child) end
        end
    end
end

local function gravityWellPull(pos, radius, power)
    local seen = 0
    local function drag(obj)
        if seen >= 120 then return end
        if obj:IsA("BasePart") and not obj.Anchored and not isVelImmune(obj) and obj ~= workspace.Terrain
           and not isSelected(obj) and not isLocalPlayerPart(obj)
            and (obj.Position - pos).Magnitude <= radius then
            seen += 1
            pcall(function()
                local toC = pos - obj.Position
                local d = toC.Magnitude
                local dir = d > 0.01 and toC / d or Vector3.new(0, 1, 0)
                local tangent = Vector3.new(-dir.Z, 0, dir.X)
                if tangent.Magnitude < 0.01 then tangent = Vector3.new(1, 0, 0) else tangent = tangent.Unit end
                obj.AssemblyLinearVelocity = obj.AssemblyLinearVelocity
                    + dir * power + tangent * power * 0.6 + Vector3.new(0, -power * 0.15, 0)
            end)
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        drag(obj)
        if obj:IsA("Model") or obj:IsA("Folder") then
            for _, child in ipairs(obj:GetChildren()) do drag(child) end
        end
    end
end

local function ensureBlackholeConns()
    if blackholeTouchConns == nil then blackholeTouchConns = {} end
    for _, p in ipairs(selectedParts) do
        if p and p.Parent then
            if not blackholeTouchConns[p] then
                blackholeTouchConns[p] = p.Touched:Connect(function(hit)
                    if activeMode ~= "Blackhole" then return end
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if isVelImmune(hit) then return end
                    if hit == workspace.Terrain or hit == p then return end
                    if isSelected(hit) then return end
                    if isLocalPlayerPart(hit) then return end
                    pcall(function()
                        local dir = hit.Position - p.Position
                        dir = dir.Magnitude > 0.001 and dir.Unit or Vector3.new(0, 1, 0)
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*200000 + Vector3.new(0, 70000, 0) + Vector3.new((math.random()-0.5)*12000, 0, (math.random()-0.5)*12000)
                        hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*30000, (math.random()-0.5)*30000, (math.random()-0.5)*30000)
                    end)
                end)
            end
        end
    end
    for p, c in pairs(blackholeTouchConns) do
        if not p or not p.Parent or not isSelected(p) then
            pcall(function() c:Disconnect() end)
            blackholeTouchConns[p] = nil
        end
    end
end

function minigunLaunch(p, tgt)
    if minigunTouchConns[p] then pcall(function() minigunTouchConns[p]:Disconnect() end) end
    minigunFlying[p] = true
    minigunFlyTgt[p] = tgt
    minigunFlyFrom[p] = p.Position
    minigunFlyT0[p] = tick()
    minigunTouchConns[p] = p.Touched:Connect(function(hit)
        if activeMode ~= "Minigun" then return end
        if not minigunFlying[p] then return end
        if not hit or not hit.Parent or hit.Anchored then return end
        if isVelImmune(hit) then return end
        if hit == workspace.Terrain or hit == p then return end
        if isSelected(hit) then return end
        if isLocalPlayerPart(hit) then return end
        pcall(function()
            local d = hit.Position - p.Position
            d = d.Magnitude > 0.001 and d.Unit or Vector3.new(0, 1, 0)
            hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + d*180000 + Vector3.new(0, 60000, 0)
            hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*30000, (math.random()-0.5)*30000, (math.random()-0.5)*30000)
        end)
    end)
end

function minigunLand(p, silent)
    if minigunTouchConns[p] then pcall(function() minigunTouchConns[p]:Disconnect() end) end
    minigunTouchConns[p] = nil
    local tgt = minigunFlyTgt[p]
    minigunFlying[p] = nil
    minigunFlyTgt[p] = nil
    minigunFlyFrom[p] = nil
    minigunFlyT0[p] = nil
    if not silent and tgt and p and p.Parent then
        impactBurst(tgt, 5, 60000)
    end
end

function dv2TargetValid(tr)
    if not (tr and tr.Parent and tr:IsA("BasePart")) then return false end
    local okA, a = pcall(function() return tr.Anchored end)
    if okA and a then return false end
    local okM, m = pcall(function() return tr.AssemblyMass == math.huge end)
    if okM and m then return false end
    return true
end

function dv2PredictedPos()
    local base = Vector3.zero
    pcall(function() base = dv2Target.Position end)
    if typeof(base) ~= "Vector3" then base = Vector3.zero end
    local vv = Vector3.zero
    pcall(function() vv = dv2Target.AssemblyLinearVelocity end)
    if typeof(vv) ~= "Vector3" then vv = Vector3.zero end
    if vv.Magnitude ~= vv.Magnitude then vv = Vector3.zero end
    if vv.Magnitude > 100 then vv = vv.Unit * 100 end
    local lead = vv * 0.15
    if lead.Magnitude > 6 then lead = lead.Unit * 6 end
    return base + lead
end

function partBallistic(part)
    if not (part and part.Parent) then return false end
    if minigunFlying and minigunFlying[part] then return true end
    if railgunFired then return true end
    if boomerangActive then return true end
    if strikeState == "descend" or strikeState == "drill" then return true end
    if barrageActive then return true end
    if chainedActive and chainedFired and chainedFired[part] then return true end
    if homingTarget and homingTarget.Parent and tick() < homingEndTime then return true end
    if satFired and satFired[part] and tick() - satFired[part] < SAT_TTL then return true end
    if lightningFired and lightningFired[part] and tick() - lightningFired[part] < (LIGHTNING_TRAVEL + LIGHTNING_HOLD) then return true end
    if activeMode == "Sniper" and sniperTargetPos ~= Vector3.zero and (tick() - sniperFireTime) <= SNIPER_CYCLE then return true end
    if scytheState == "swing" then return true end
    if activeMode == "Stickman" and stickBeamActive then return true end
    if activeMode == "DroneV2" and dv2Target and dv2Target.Parent then
        local okV, valid = pcall(dv2TargetValid, dv2Target)
        if okV and valid then return true end
    end
    return false
end

local function tickParts()
    local t     = tick()
    local total = #selectedParts
    local char  = LP.Character
    if total > 0 then
        do
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Parent and not hrp.Anchored then
                local cv, ca = Vector3.zero, Vector3.zero
                pcall(function()
                    cv = hrp.AssemblyLinearVelocity
                    ca = hrp.AssemblyAngularVelocity
                end)
                if not stabInit then
                    stabInit = true
                    stabLastVel, stabLastAng = cv, ca
                else
                    local hot = false
                    pcall(function()
                        local nowS = tick()
                        hot = (sniperTargetPos ~= Vector3.zero and (nowS - sniperFireTime) <= SNIPER_CYCLE + 0.8)
                            or (strikeState == "descend" or strikeState == "drill")
                            or (dv2Target ~= nil and dv2Target.Parent ~= nil)
                            or (next(minigunFlying) ~= nil)
                            or barrageActive
                            or railgunFired
                            or chainedActive
                            or (scytheState == "swing")
                            or (next(satFired) ~= nil)
                            or (next(lightningFired) ~= nil)
                            or (nowS < blackholeSurgeUntil)
                    end)
                    if hot and cv.Magnitude > 150 and (cv - stabLastVel).Magnitude > 250 then
                        pcall(function() hrp.AssemblyLinearVelocity = stabLastVel end)
                    else
                        stabLastVel = cv
                    end
                    if hot and (ca - stabLastAng).Magnitude > 40 then
                        pcall(function() hrp.AssemblyAngularVelocity = stabLastAng end)
                    else
                        stabLastAng = ca
                    end
                end
            else
                stabInit = false
            end
        end
    end
    if tick() >= mouseExcludeNext then
        mouseExcludeNext = tick() + 3
        rebuildMouseExclude()
    end
    if #selectedParts > 0 and not deathStashActive then
        local h = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local deadGone = (not hrp or not hrp.Parent) and (not h or h.Health <= 0)
        if deadGone and tick() > (deathSpamUntil or 0) then
            startDeathStash()
            buildDeathFloor()
            deathSpamUntil = tick() + 10
            task.spawn(function()
                for _ = 1, 40 do
                    task.wait(0.25)
                    reassertOwnershipAggressive(2)
                end
            end)
        end
    end
    if not rotDrag.active and rotLockFlag() then
        local mb = nil
        pcall(function() mb = UserInputService.MouseBehavior end)
        if mb == Enum.MouseBehavior.LockCenter or mb == Enum.MouseBehavior.LockCurrentPosition then
            healRotLock()
        else
            setRotLockFlag(nil)
        end
    end
    

    local partsToUse = total

    local cRoot=char and char:FindFirstChild("HumanoidRootPart")
    if deathStashActive then
        local h = char and char:FindFirstChildOfClass("Humanoid")
        if cRoot and h and h.Health > 0 then
            stashAliveSince = stashAliveSince or t
            if t - stashAliveSince > 2.5 then beginReturn() end
        else
            stashAliveSince = nil
        end
    elseif stashAliveSince ~= nil then
        stashAliveSince = nil
    end
    if not deathStashActive and deathCollideState == "return" then
        deathCollideState = nil
        if fakeCollisions then
            for _, part in ipairs(selectedParts) do
                if part and part.Parent then
                    pcall(disableSelectedCollision, part)
                    pcall(disableAssemblyCollision, part)
                end
            end
        end
    end
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            local py, vy = nil, 0
            pcall(function() py = part.Position.Y end)
            pcall(function() vy = part.AssemblyLinearVelocity.Y end)
            local below = nil
            local tg0 = partTargets[part]
            if tg0 and tg0.position and py then
                pcall(function() below = tg0.position.Y - py end)
            end
            local deepVoid = (py and py < -300)
            local fastFall = (vy < -150 and below and below > 50)
            if fastFall and not deepVoid then
                if not fallSuspect[part] then fallSuspect[part] = tick() end
                fastFall = (tick() - fallSuspect[part] > 0.12)
            else
                fallSuspect[part] = nil
            end
            if deepVoid or fastFall then
                pcall(reclaimAssembly, part)
                if not unfreezeBoost[part] then unfreezeBoost[part] = 0 end
                if tg0 and tg0.position then
                    local ap = getNetAP(part)
                    if ap then
                        ap.Enabled = true
                        ap.MaxForce = alignForceFor(part)
                        ap.MaxVelocity = math.huge
                        ap.Position = tg0.position
                    end
                end
                pcall(function() part.AssemblyLinearVelocity = Vector3.new(17.5555555, 17.5555555, 17.5555555) end)
            end
        end
    end
    if cRoot and cRoot.Parent then
        local hy = nil
        pcall(function() hy = cRoot.Position.Y end)
        if hy and hy < -250 then
            local gy = nil
            pcall(function() gy = getGroundYAt(cRoot.Position.X, cRoot.Position.Z, hy, cRoot) end)
            if not gy then
                pcall(function()
                    cRoot.CFrame = CFrame.new(cRoot.Position.X, -200, cRoot.Position.Z)
                    cRoot.AssemblyLinearVelocity = Vector3.zero
                    cRoot.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end
    if cRoot then
        local p=cRoot.Position
        local step = (activeMode=="Comet") and 0.45 or 0.8
        if #cometHistory==0 or (cometHistory[#cometHistory]-p).Magnitude>step then
            table.insert(cometHistory,p)
            if #cometHistory>COMET_MAX then table.remove(cometHistory,1) end
        end
    end

    do
        local rs = char and char:FindFirstChild("HumanoidRootPart")
        if rs then
            local nowT = tick()
            local dt   = math.clamp(nowT - (stickLastT or nowT), 0, 0.1)
            local pnow = rs.Position
            if stickLastPos and dt > 0 then
                local dp = pnow - stickLastPos
                if dp.Magnitude < 25 then
                    local inst = dp / dt
                    stickVelSmooth = stickVelSmooth:Lerp(inst, 0.35)
                else
                    stickVelSmooth = Vector3.zero
                end
            end
            stickLastPos = pnow
            stickLastT = nowT
            if activeMode=="Stickman" then
                local fv  = Vector3.new(stickVelSmooth.X, 0, stickVelSmooth.Z)
                local spd = fv.Magnitude
                if spd > 0.5 then
                    local lv = rs.CFrame.LookVector
                    local lf = Vector3.new(lv.X, 0, lv.Z)
                    lf = lf.Magnitude > 0.01 and lf.Unit or Vector3.new(0, 0, -1)
                    local sgn = (fv:Dot(lf) >= 0) and 1 or -1
                    if not stickMagnetActive then
                        stickWalkPhase += dt * spd * 0.35 * sgn
                    end
                end
if false and stickMagnetActive then
                        _G._billySitPos = nil
                        _G._billySitCF = nil
                    else
                        _G._billySitPos = nil
                        _G._billySitCF = nil
                    end
            end
        end
    end

    do
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and cRoot and cRoot.Position.Y < -1000 then
            local killed = false
            if type(replicatesignal) == "function" then
                killed = pcall(function() replicatesignal(hum.Died) end)
            end
            if not killed then
                pcall(function()
                    local hd = char:FindFirstChild("Head")
                    if hd then hd:Destroy() end
                end)
                pcall(function() hum.Health = 0 end)
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
            end
        end
    end


    if spcActive and spcPart and spcPart.Parent then
        local tgt
        if deathStashActive then
            tgt = deathStashPos
        else
            tgt = currentMouseHit + Vector3.new(0, spcYOff, 0)
        end
        local diff = tgt - spcPart.Position
        local dist = diff.Magnitude
        pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
        pcall(sethiddenproperty, spcPart, "NetworkIsSleeping", false)
        local sroot = getAssemblyRoot(spcPart)
        if sroot ~= spcPart and sroot.Parent and not sroot.Anchored then
            pcall(sethiddenproperty, sroot, "NetworkIsSleeping", false)
            pcall(function()
                local ov = sroot.AssemblyLinearVelocity
                sroot.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                sroot.AssemblyLinearVelocity = ov
            end)
        end
        pcall(function()
            local ap, ao = ensureAlign(spcPart)
            if ap then
                ap.Enabled = true
                ap.MaxForce = alignForceFor(part)
                ap.MaxVelocity = math.huge
                ap.Responsiveness = math.huge
                ap.Position = tgt
            end
            if ao then
                ao.Enabled = true
                ao.MaxTorque = alignForceFor(part)
                ao.MaxAngularVelocity = math.huge
                ao.CFrame = spcPart.CFrame
            end
            local ov = spcPart.AssemblyLinearVelocity
            spcPart.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
            spcPart.AssemblyLinearVelocity = ov
            spcPart.AssemblyLinearVelocity = netHoldVelocity()
        end)
    end


    if activeMode=="DroneV2" and total>0 then
        local myRoot=char and char:FindFirstChild("HumanoidRootPart")
        dv2ScanNext = dv2ScanNext or 0
        local doScan = tick() >= dv2ScanNext
        if doScan then dv2ScanNext = tick() + 0.2 end
        if doScan then
            dv2Target=nil
            if myRoot then
                local myPos=myRoot.Position; local best=flingRange+1
                for _,plr in ipairs(Players:GetPlayers()) do
                    if plr~=LP and plr.Character then
                        local tr=plr.Character:FindFirstChild("HumanoidRootPart")
                        if tr and dv2TargetValid(tr) then local d=(tr.Position-myPos).Magnitude
                            if d<=flingRange and d<best then best=d; dv2Target=tr end end
                    end
                end
                for _,model in ipairs(workspace:GetChildren()) do
                    if model:IsA("Model") and model~=char then
                        local h=model:FindFirstChildOfClass("Humanoid")
                        local tr=h and model:FindFirstChild("HumanoidRootPart")
                        if tr and dv2TargetValid(tr) then local d=(tr.Position-myPos).Magnitude
                            if d<=flingRange and d<best then best=d; dv2Target=tr end end
                    end
                end
            end
        elseif dv2Target and (not dv2Target.Parent or not dv2TargetValid(dv2Target)) then
            dv2Target=nil
        end
    elseif activeMode~="DroneV2" then
        dv2Target=nil
    end

    if activeMode=="Homing" and total>0 then
        if homingTarget and tick() >= homingEndTime then
            homingTarget = nil
            if homingTouchConns then
                for p, c in pairs(homingTouchConns) do pcall(function() c:Disconnect() end) end
                homingTouchConns = {}
            end
        end
    elseif activeMode~="Homing" then
        homingTarget=nil
    end

    if activeMode=="Railgun" and total>0 then
        local now = tick()
        if railgunCharging then
            if now - railgunChargeStart >= 1 then
                railgunCharging = false
                railgunFired = true
                railgunPhase = "firing"
                railgunPhaseStart = now
                railgunBoomed = false
                for _, part in ipairs(selectedParts) do
                    if railgunTouchConns[part] then
                        pcall(function() railgunTouchConns[part]:Disconnect() end)
                    end
                    railgunTouchConns[part] = part.Touched:Connect(function(hit)
                        if not hit or not hit.Parent or hit.Anchored then return end
                        if isVelImmune(hit) then return end
                        if hit == workspace.Terrain or hit == part then return end
                        if isSelected(hit) then return end
                        if isLocalPlayerPart(hit) then return end
                        pcall(function()
                            local burstDir = hit.Position - part.Position
                            burstDir = burstDir.Magnitude > 0.001 and burstDir.Unit or Vector3.new(0, 1, 0)
                            part.AssemblyAngularVelocity = Vector3.new(
                                (math.random() - 0.5) * 9e10,
                                (math.random() - 0.5) * 9e10,
                                (math.random() - 0.5) * 9e10
                            )
                            part.AssemblyLinearVelocity = part.AssemblyLinearVelocity + burstDir * 15000
                            hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + burstDir * 60000
                        end)
                    end)
                end
                railgunHitPos = currentMouseHit
            end
        end
        if railgunFired then
            if railgunPhase == "firing" then
                local allArrived = true
                for _, part in ipairs(selectedParts) do
                    if part and part.Parent then
                        if (part.Position - railgunHitPos).Magnitude > 8 then
                            allArrived = false
                            break
                        end
                    end
                end
                if allArrived or now - railgunPhaseStart > 1.5 then
                    railgunPhase = "exploding"
                    railgunPhaseStart = now
                end
            elseif railgunPhase == "exploding" then
                if not railgunBoomed then
                    railgunBoomed = true
                    impactBurst(railgunHitPos, 28, 60000)
                end
                if now - railgunPhaseStart >= 1.2 then
                    railgunPhase = "returning"
                    railgunPhaseStart = now
                end
            elseif railgunPhase == "returning" then
                local allBack = false
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local homeY = math.max(0, formSizeY) / 3 * 9 + 1
                    local home = myRoot.Position + Vector3.new(0, homeY, 0)
                    allBack = true
                    for _, part in ipairs(selectedParts) do
                        if part and part.Parent and not frozenTargets[part] then
                            if (part.Position - home).Magnitude > 6 then
                                allBack = false
                                break
                            end
                        end
                    end
                end
                if allBack or (now - railgunPhaseStart) >= 2.5 then
                    railgunFired = false
                    railgunPhase = "idle"
                    railgunHitPos = Vector3.zero
                    for _, part in ipairs(selectedParts) do
                        if railgunTouchConns[part] then
                            pcall(function() railgunTouchConns[part]:Disconnect() end)
                            railgunTouchConns[part] = nil
                        end
                    end
                end
            end
        end
    elseif activeMode~="Railgun" then
        railgunCharging=false; railgunFired=false; railgunPhase="idle"; railgunHitPos=Vector3.zero
    end

    if activeMode=="Barrage" and total>0 then
        barrageActive = true
    elseif activeMode~="Barrage" then
        barrageActive=false
    end


    if attracting then
        attractTimer+=1/60
        if attractTimer>=2 then attracting=false; attractTimer=0 end
    end


    if activeMode=="Minigun" and #selectedParts > 0 then
        local now = tick()
        local dt = math.clamp(now - (minigunLastT > 0 and minigunLastT or now), 0, 0.5)
        minigunLastT = now
        for p in pairs(minigunFlying) do
            if not p or not p.Parent or not isSelected(p) then
                minigunLand(p, true)
            else
                local ft = minigunFlyTgt[p]
                local t0 = minigunFlyT0[p] or now
                local reach = false
                if ft then
                    local reachDist = math.max(4, p.Size.Magnitude * 1.25)
                    reach = (p.Position - ft).Magnitude < reachDist
                end
                if reach or (now - t0) >= MINIGUN_TIMEOUT then
                    minigunLand(p, false)
                end
            end
        end
        local rig = minigunRig(#selectedParts, now)
        minigunAcc = math.min(minigunAcc + dt * math.max(1, minigunRate), 3)
        while minigunAcc >= 1 do
            minigunAcc -= 1
            local launched = false
            for b = 0, rig.B - 1 do
                local bb = (minigunCursor + b) % rig.B
                for i, p in ipairs(selectedParts) do
                    if p and p.Parent and not minigunFlying[p] and ((i-1) % rig.B) == bb then
                        local sp = math.max(0, minigunSpread)
                        local ft = currentMouseHit + Vector3.new(
                            (math.random()-0.5)*2*sp,
                            (math.random()-0.5)*sp,
                            (math.random()-0.5)*2*sp)
                        minigunLaunch(p, ft)
                        minigunCursor = (bb + 1) % rig.B
                        launched = true
                        break
                    end
                end
                if launched then break end
            end
            if not launched then minigunAcc = 0; break end
        end
    else
        if next(minigunFlying) then
            for p in pairs(minigunFlying) do minigunLand(p, true) end
        end
        minigunAcc = 0
        minigunLastT = 0
        if minigunLastIdx ~= 0 then minigunLastIdx = 0 end
    end


    if activeMode=="Satellite" then
        local now = tick()
        for p, fireTime in pairs(satFired) do
            if p and p.Parent then
                if (now - fireTime) > SAT_TTL
                    or (p.Position - satTarget).Magnitude < 3 then
                    satFired[p] = nil
                    if satTouchConns[p] then
                        pcall(function() satTouchConns[p]:Disconnect() end)
                        satTouchConns[p] = nil
                    end
                    pcall(reclaimAssembly, p)
                end
            else
                satFired[p] = nil
                if satTouchConns[p] then
                    pcall(function() satTouchConns[p]:Disconnect() end)
                    satTouchConns[p] = nil
                end
            end
        end
    end


    if activeMode=="Lightning" then
        local now = tick()
        if next(lightningFired) and not lightningBoomed
           and (now - lightningFireTime) >= LIGHTNING_TRAVEL then
            lightningBoomed = true
            impactBurst(lightningTarget, 30, 60000)
        end
        for p, fireTime in pairs(lightningFired) do
            if p and p.Parent then
                if (now - fireTime) > LIGHTNING_TRAVEL + LIGHTNING_HOLD then
                    lightningFired[p] = nil
                    if lightningTouchConns[p] then
                        pcall(function() lightningTouchConns[p]:Disconnect() end)
                        lightningTouchConns[p] = nil
                    end
                end
            else
                lightningFired[p] = nil
                if lightningTouchConns[p] then
                    pcall(function() lightningTouchConns[p]:Disconnect() end)
                    lightningTouchConns[p] = nil
                end
            end
        end
    end

    if activeMode=="Sniper" then
        local age = tick() - sniperFireTime
        if sniperBoomStage < 1 and age >= 0.3 then
            sniperBoomStage = 1
            impactBurst(sniperTargetPos, 30, 250000)
        end
        if sniperBoomStage < 2 and age >= 0.62 then
            sniperBoomStage = 2
            impactBurst(sniperTargetPos, 20, 350000)
        end
        if sniperBoomStage < 3 and age >= 0.95 then
            sniperBoomStage = 3
            impactBurst(sniperTargetPos, 26, 300000)
        end
        if not sniperCaught and age >= SNIPER_CYCLE then
            sniperCaught = true
            for _, p in ipairs(selectedParts) do
                pcall(function()
                    local ap = getNetAP(p)
                    if ap then
                        ap.Enabled = true
                        ap.MaxForce = alignForceFor(p)
                        ap.MaxVelocity = math.huge
                    end
                    local ao = getNetAO(p)
                    if ao then
                        ao.Enabled = true
                        ao.MaxTorque = alignForceFor(p)
                        ao.MaxAngularVelocity = math.huge
                    end
                    p.AssemblyLinearVelocity = netHoldVelocity()
                    p.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
        if age > SNIPER_CYCLE and next(sniperTouchConns) then
            for p, c in pairs(sniperTouchConns) do
                pcall(function() c:Disconnect() end)
            end
            sniperTouchConns = {}
        end
        if tick() < sniperDampUntil then
            local sAgeD = tick() - sniperFireTime
            local sniperFiringD = (sniperTargetPos ~= Vector3.zero and sAgeD >= 0 and sAgeD <= SNIPER_CYCLE)
            for _, p in ipairs(selectedParts) do
                if p and p.Parent and not p.Anchored then
                    pcall(reclaimAssembly, p)
                    local _sdr = getAssemblyRoot(p)
                    if _sdr ~= p then pcall(reclaimAssembly, _sdr) end
                    pcall(sethiddenproperty, p, "NetworkIsSleeping", false)
                    if not sniperFiringD then
                        pcall(function()
                            p.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end
        elseif sniperTargetPos ~= Vector3.zero and age > SNIPER_CYCLE then
            sniperTargetPos = Vector3.zero
        end
    end

    if activeMode=="Boomerang" then
        if boomerangActive and (tick() - boomerangStart) >= BOOMERANG_T + 0.1 then
            boomerangActive = false
            for p, c in pairs(boomerangConns) do
                pcall(function() c:Disconnect() end)
            end
            boomerangConns = {}
        end
    end

    if activeMode=="Strike" and strikeState ~= "idle" then
        local age = tick() - strikeStart
        if strikeState == "descend" then
            if age >= STRIKE_DESCEND + 0.15 then
                strikeState = "drill"
                strikeStart = tick()
                strikePulse = 0
                impactBurst(strikeTarget, 30, 900000)
                impactBurst(strikeTarget, 18, 1800000)
            end
        elseif strikeState == "drill" then
            if age >= STRIKE_DRILL then
                strikeState = "return"
                strikeStart = tick()
            elseif age - strikePulse >= 0.15 then
                strikePulse = age
                impactBurst(strikeTarget, 18, 1800000)
                impactBurst(strikeTarget, 30, 900000)
            end
        elseif strikeState == "return" and age >= STRIKE_RETURN then
            strikeState = "idle"
            if strikeTouchConns then
                for p, c in pairs(strikeTouchConns) do pcall(function() c:Disconnect() end) end
                strikeTouchConns = {}
            end
        end
    end
    if activeMode=="Strike" and tick() < strikeDampUntil then
        for _, p in ipairs(selectedParts) do
            if p and p.Parent and not p.Anchored then
                pcall(reclaimAssembly, p)
                pcall(function() p.AssemblyAngularVelocity = Vector3.zero end)
            end
        end
    end

    if activeMode=="Blackhole" then
        ensureBlackholeConns()
        local now = tick()
        if now - blackholePullT >= BH_PULL_EVERY and #selectedParts > 0 then
            blackholePullT = now
            local c = getFormationCenterTarget() + Vector3.new(0, 4*math.max(0, formSizeY)/3, 0)
            local surge = (now < blackholeSurgeUntil) and 3 or 1
            local pr = math.max(formRadius*2.5, 18)
            gravityWellPull(c, pr, 30000*surge)
        end
    elseif blackholeTouchConns and next(blackholeTouchConns) then
        for p, c in pairs(blackholeTouchConns) do pcall(function() c:Disconnect() end) end
        blackholeTouchConns = {}
    end

    if activeMode=="Scythe" then
        if scytheState=="swing" then
            local sAge = tick() - scytheStart
            if sAge >= SCYTHE_SWING * 2 then
                scytheState = "idle"
                for p,c in pairs(scytheConns) do pcall(function() c:Disconnect() end) end
                scytheConns = {}
            else
                if sAge - scythePulse >= 0.15 then
                    scythePulse = sAge
                    impactBurst(scytheCenter, 18, 1800000)
                    impactBurst(scytheCenter, 30, 900000)
                end
                for _, p in ipairs(selectedParts) do
                    if p and p.Parent and not p.Anchored then
                        pcall(function()
                            p.AssemblyAngularVelocity = Vector3.new(
                                (math.random()-0.5)*3e6,
                                (math.random()-0.5)*3e6,
                                (math.random()-0.5)*3e6)
                        end)
                    end
                end
            end
        end
    end

    if activeMode=="Stickman" and stickBeamActive then
        local bTotal = #selectedParts
        for bIdx, bp in ipairs(selectedParts) do
            if bp and bp.Parent and not bp.Anchored then
                local bu = bIdx / math.max(bTotal, 1)
                if bu >= 0.37 and bu < 0.73 and (stickArmIsLeft and bu < 0.55 or (not stickArmIsLeft and bu >= 0.55)) then
                    pcall(function()
                        local s1 = (bIdx % 2 == 0) and 1 or -1
                        local s2 = (bIdx % 3 == 0) and -1 or 1
                        local s3 = (bIdx % 5 == 0) and -1 or 1
                        bp.AssemblyAngularVelocity = Vector3.new(s1 * 9e9, s2 * 9e9, s3 * 9e9)
                    end)
                end
            end
        end
    end

    if activeMode=="Chained" then
        if chainedActive and chainedTarget ~= Vector3.zero then
            chainedTarget = currentMouseHit
        end
    else
        if chainedActive then
            chainedActive = false
            chainedTarget = Vector3.zero
            for p,c in pairs(chainedConns) do pcall(function() c:Disconnect() end) end
            chainedConns = {}
            chainedFired = {}
        end
    end


    local isWall   = activeMode=="Wall"
    local isMG     = activeMode=="Minigun"
    local isSat    = activeMode=="Satellite"
    local wallRoot = isWall and (char and char:FindFirstChild("HumanoidRootPart"))
    local isDV2    = activeMode=="DroneV2"
    local isHoming = activeMode=="Homing"
    local isRail   = activeMode=="Railgun"
    local isBarr   = activeMode=="Barrage"
    local isLightning = activeMode=="Lightning"
    local isCube   = activeMode=="Cube"
    local isStrike = activeMode=="Strike"
    local isSniper = activeMode=="Sniper"
    local isBoom   = activeMode=="Boomerang"
    local isChained = activeMode=="Chained"
    local isText = activeMode=="Text"
    local isGrid = activeMode=="Grid"
    local isRing = activeMode=="Ring"
    local isBridge = activeMode=="Bridge"
    local isHalo = activeMode=="Halo"
    local isGyro = activeMode=="Gyro"
    local isStick = activeMode=="Stickman"

    if activeMode == "Stickman" then pcall(rebuildStickBodyRanks) end

    for i=#selectedParts,1,-1 do
        local part=selectedParts[i]
        if not part or not part.Parent then
            if part and isSelected(part) then
                local function dropMissing()
                    partMissingSince[part] = nil
                    partTrulyGone[part] = nil
                    if partDestroyingConns[part] then pcall(function() partDestroyingConns[part]:Disconnect() end) partDestroyingConns[part] = nil end
                    table.remove(selectedParts,i)
                    cleanupPartState(part, false)
                end
                if partTrulyGone[part] then
                    dropMissing()
                else
                    local miss = partMissingSince[part]
                    if not miss then
                        partMissingSince[part] = tick()
                    elseif tick() - miss > 8 then
                        dropMissing()
                    end
                end
            else
                removeHL(part); table.remove(selectedParts,i); frozenTargets[part]=nil; partTargets[part]=nil; selectedSetCache[part]=nil; ownVerdict[part]=nil; ownVerdictAt[part]=nil
            end
        else
            partMissingSince[part] = nil
            if part.Anchored then
                if not anchoredNoted[part] then
                    anchoredNoted[part] = true
                    if tick() - anchorToastAt > 3 then
                        anchorToastAt = tick()
                        toast("part anchored by game - holding selection")
                    end
                end
            elseif anchoredNoted[part] then
                anchoredNoted[part] = nil
            end
            local tgt
            local stickGrabOverride = (activeMode == "Stickman" and stickGrabActive)
            if frozenTargets[part] and not stickGrabOverride then
                tgt = frozenTargets[part]
            elseif frozen and not stickGrabOverride then
                if not frozenTargets[part] then frozenTargets[part] = part.Position end
                tgt = frozenTargets[part]
            else
                tgt = applyFormRot(part, getTarget(i, total, part, t))
            end

                if unfreezeBoost[part] then
                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                    if unfreezeBoost[part] == 0 then
                        unfreezeBoost[part] = tick() + 15
                        unfreezeBoostStart[part] = tick()
                        unfreezeT0[part] = nil
                        unfreezeFrom[part] = part.Position
                        pcall(function() part.RootPriority = 127 end)
                        pcall(reclaimAssembly, part)
                        local _ur = getAssemblyRoot(part)
                        if _ur ~= part then pcall(reclaimAssembly, _ur) end
                        pcall(function()
                            part.AssemblyLinearVelocity = netHoldVelocity()
                            part.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                    if tick() < unfreezeBoost[part] then
pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
                        local anchor = unfreezeFrom[part]
                        if typeof(anchor) ~= "Vector3" then
                            anchor = part.Position
                            unfreezeFrom[part] = anchor
                        end
                        unfreezeFrom[part] = tgt
                        local wishDist = (tgt - part.Position).Magnitude
                        local _riderNearHold = false
                        pcall(function() _riderNearHold = riderStillNear(part) end)
                        do
                            local heldFor = tick() - (unfreezeBoostStart[part] or tick())
                            local stayDist = 1e9
                            pcall(function() stayDist = (tgt - part.Position).Magnitude end)
                            if _riderNearHold and stayDist > 5 then
                                unfreezeBoost[part] = math.max(unfreezeBoost[part], tick() + 2)
                            elseif heldFor > 3 and stayDist < 5 then
                                unfreezeBoost[part] = tick()
                            end
                        end
                        pcall(function()
                            local ownedB = false
                            pcall(function() ownedB = ownedCached(part) end)
                            if not ownedB then
                                local ovb = part.AssemblyLinearVelocity
                                part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                                part.AssemblyLinearVelocity = ovb
                                pcall(reclaimAssembly, part)
                                local rrb = getAssemblyRoot(part)
                                if rrb ~= part then pcall(reclaimAssembly, rrb) end
                            else
                                pcall(reclaimAssembly, part)
                            end
                            part.AssemblyLinearVelocity = netHoldVelocity()
                            part.AssemblyAngularVelocity = Vector3.zero
                            pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                            if _riderNearHold then pcall(shieldRiders, part) end
                        end)
                        local _ownInterval = 0.3
                        pcall(function() if riderStillNear(part) then _ownInterval = 0.1 end end)
                        if tick() - (ownCheckAt[part] or 0) > _ownInterval then
                            ownCheckAt[part] = tick()
                            local ocf = nil
                            pcall(function() ocf = ensureOwnerCheck() end)
                            local apiDet = ownerApiState()
                            local okO, owned = false, nil
                            if apiDet == "OK" and ocf then okO, owned = pcall(ocf, part) end
                            local hardFalse = (apiDet == "OK") and okO and (owned == false)
                            if hardFalse ~= true then
                                local simNow = weSimulate(part)
                                if simNow == false then hardFalse = true end
                            end
                            local _pd = 1e9
                            pcall(function() _pd = (tgt - part.Position).Magnitude end)
                            local ineff = flightIneffective(part, _pd)
                            local failing = false
                            if hardFalse then
                                failing = (ineff ~= false)
                            elseif (not okO) or owned == nil then
                                failing = (ineff == true)
                            end
                            do
                                if failing then
                                    pcall(reclaimAssembly, part)
                                    local _rr = getAssemblyRoot(part)
                                    if _rr ~= part then pcall(reclaimAssembly, _rr) end
                                    pcall(function()
                                        local ov2 = part.AssemblyLinearVelocity
                                        part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                                        part.AssemblyLinearVelocity = ov2
                                    end)
                                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                                else
                                    ownerFalseStreak[part] = nil
                                end
                            end
                        end
                    else
                        unfreezeBoost[part] = nil
                        unfreezeT0[part] = nil
                        unfreezeBoostStart[part] = nil
                        pcall(function()
                            if strengthenParts then
                                rampDensity(part, strengthenDensity, 0.3, 0.5, 3)
                            else
                                rampDensity(part, 0.001, 0, 0, 3)
                            end
                        end)
                        unfreezeFrom[part] = nil
                        ownCheckAt[part] = nil
                        ownLogAt[part] = nil
                        reholdToastAt[part] = nil
                        flightStuck[part] = nil
                        flightTgt[part] = nil
                        reholdCount[part] = nil
                        fallSuspect[part] = nil
                        holdLoud[part] = nil
                        partRideRad[part] = nil
                        if riderNCCs[part] then
                            for _, c in ipairs(riderNCCs[part]) do pcall(function() c:Destroy() end) end
                            riderNCCs[part] = nil
                        end
                        riderShieldAt[part] = nil
                    end
                end

                local dist=(tgt-part.Position).Magnitude
                local targetRotation = part.CFrame
                local responsiveness = getMoveResponsiveness(1)
                if unfreezeBoost[part] then
                    local _boostRider = false
                    pcall(function() _boostRider = riderStillNear(part) end)
                    if _boostRider then
                        responsiveness = 500
                    else
                        responsiveness = 300 + 200 * math.clamp(dist / 120, 0, 1)
                    end
                end
                if not unfreezeBoost[part] and (frozenTargets[part] or frozen) then
                    local _frozenRider = false
                    pcall(function() _frozenRider = riderStillNear(part) end)
                    if _frozenRider then
                        responsiveness = 500
                        pcall(shieldRiders, part)
                    end
                end
                if dist > 30 then
                    shieldRiders(part)
                elseif riderNCCs[part] and not unfreezeBoost[part] then
                    if riderStillNear(part) then
                        shieldRiders(part)
                    else
                        for _, c in ipairs(riderNCCs[part]) do pcall(function() c:Destroy() end) end
                        riderNCCs[part] = nil
                        riderShieldAt[part] = nil
                        pcall(function() part.AssemblyLinearVelocity = Vector3.new(17.5555555, 17.5555555, 17.5555555) end)
                    end
                end


                if isSat and satFired[part] then
                    responsiveness = getMoveResponsiveness(55.0)
                end

                if isLightning and lightningFired[part] then
                    responsiveness = getMoveResponsiveness(50.0)
                end

                if isCube then
                    responsiveness = getMoveResponsiveness(2.5)
                end

                if isStrike and strikeState ~= "idle" then
                    responsiveness = getMoveResponsiveness(45)
                end

                if isStrike and strikeState == "idle" then
                    responsiveness = getMoveResponsiveness(8)
                end

                if isSniper then
                    local sniperAge = tick() - sniperFireTime
                    local sniperFiring = (sniperTargetPos ~= Vector3.zero and sniperAge >= 0 and sniperAge <= SNIPER_CYCLE)
                    responsiveness = getMoveResponsiveness(sniperFiring and 40 or 32)
                end

                if isBoom and boomerangActive then
                    responsiveness = getMoveResponsiveness(50)
                end

                if isChained and chainedActive and chainedFired[part] then
                    responsiveness = getMoveResponsiveness(52)
                end

                if isChained then
                    local d = (tgt - part.Position)
                    if d.Magnitude > 0.05 then
                        local baseCF = CFrame.lookAt(part.Position, tgt)
                        local twist = (i % 2 == 0) and 0 or 90
                        targetRotation = baseCF * CFrame.Angles(math.rad(90), 0, math.rad(twist)) * CFrame.Angles(math.sin(t*3 + i*0.7)*6, 0, 0)
                    end
                end

                if unfreezeBoost[part] then
                    local _keepRider = false
                    pcall(function() _keepRider = riderStillNear(part) end)
                    if _keepRider then
                        responsiveness = 500
                    elseif responsiveness < 300 then
                        responsiveness = 300 + 200 * math.clamp((tgt - part.Position).Magnitude / 120, 0, 1)
                    end
                end

                if unfreezeBoost[part] then
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part] = {} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                    end)
                elseif isDV2 and not part.Anchored then
                    local AP = getNetAP(part)
                    if AP then AP.Enabled = true; AP.MaxForce = alignForceFor(part); AP.MaxVelocity = math.huge end
                    local _dv2Attacking = (dv2Target and dv2Target.Parent and dv2TargetValid(dv2Target)) and true or false
                    local AO = getNetAO(part)
                    if AO then
                        if _dv2Attacking then AO.Enabled = false
                        else AO.Enabled = true; AO.MaxTorque = alignForceFor(part); AO.MaxAngularVelocity = math.huge end
                    end
                    pcall(sethiddenproperty, part, "NetworkIsSleeping", false)

                    if not partTargets[part] then partTargets[part] = {} end
                    if dv2TouchConns == nil then dv2TouchConns = {} end
                    if not dv2TouchConns[part] then
                        dv2TouchConns[part] = part.Touched:Connect(function(hit)
                            if activeMode ~= "DroneV2" then return end
                            if not hit or not hit.Parent or hit.Anchored then return end
                            if isVelImmune(hit) then return end
                            if hit == workspace.Terrain or hit == part then return end
                            if isSelected(hit) then return end
                            if isLocalPlayerPart(hit) then return end
                            if not (dv2Target and dv2Target.Parent and dv2TargetValid(dv2Target)) then return end
                            pcall(function()
                                local dir = hit.Position - part.Position
                                dir = dir.Magnitude > 0.001 and dir.Unit or Vector3.new(0, 1, 0)
                                local k = math.max(flingForce, 1) / 1500
                                hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*(2000000*k) + Vector3.new(0, 700000*k, 0) + Vector3.new((math.random()-0.5)*120000, 0, (math.random()-0.5)*120000)
                                hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*250000, (math.random()-0.5)*250000, (math.random()-0.5)*250000)
                            end)
                        end)
                    end

                    if dv2Target and dv2Target.Parent then
                        local vp = dv2PredictedPos()
                        local n = (total and total > 0) and total or 1
                        local cyc = (t * 0.9 + i / n) % 1
                        local tri = cyc < 0.5 and (cyc * 2) or (2 - cyc * 2)
                        local rang = i * 2.39996
                        tgt = vp + Vector3.new(math.cos(rang) * 1.2, -4 + tri * 6, math.sin(rang) * 1.2)

                        partTargets[part].rotResponsiveness = math.huge

                        local diff = tgt - part.Position
                        local dist = diff.Magnitude
                        if dist > 0.05 then
                            targetRotation = CFrame.lookAt(part.Position, tgt)
                        end
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                        local ownedV = false
                        pcall(function() ownedV = ownedCached(part) end)
                        if not ownedV then
                            pcall(function()
                                local ov = part.AssemblyLinearVelocity
                                part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                                part.AssemblyLinearVelocity = ov
                            end)
                        end
                        pcall(reclaimAssembly, part)
                        local _dv2r = getAssemblyRoot(part)
                        if _dv2r ~= part then pcall(reclaimAssembly, _dv2r) end
                        local s1 = (i % 2 == 0) and 1 or -1
                        local s2 = (i % 3 == 0) and -1 or 1
                        local s3 = (i % 5 == 0) and -1 or 1
                        part.AssemblyAngularVelocity = Vector3.new(s1 * 9e9, s2 * 9e9, s3 * 9e9)
                    else
                        if dv2TouchConns[part] then
                            pcall(function() dv2TouchConns[part]:Disconnect() end)
                            dv2TouchConns[part] = nil
                        end
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                        part.AssemblyLinearVelocity = netHoldVelocity()
                        part.AssemblyAngularVelocity = Vector3.zero
                    end

                    partTargets[part].position = tgt
                    partTargets[part].rotation = targetRotation
                    partTargets[part].responsiveness = responsiveness
                    syncAlignTarget(part, partTargets[part])
                elseif isHoming then
                    if homingTarget and homingTarget.Parent and tick() < homingEndTime and not homingDone[part] then
                        local diff = tgt - part.Position
                        local dist = diff.Magnitude
                        if dist > 0.05 then
                            local AP = getNetAP(part)
                            if AP then AP.Enabled = true; AP.MaxForce = alignForceFor(part); AP.MaxVelocity = math.huge end
                            local AO = getNetAO(part)
                            if AO then AO.Enabled = true; AO.MaxTorque = alignForceFor(part); AO.MaxAngularVelocity = math.huge end
                            if not partTargets[part] then partTargets[part] = {} end
                            partTargets[part].position = tgt
                            partTargets[part].rotation = targetRotation
                            partTargets[part].responsiveness = responsiveness
                            syncAlignTarget(part, partTargets[part])
                            part.AssemblyAngularVelocity = Vector3.new(
                                math.sin(t * 4 + i) * 50,
                                math.cos(t * 3 + i * 1.2) * 50,
                                math.sin(t * 3.7 + i * 0.8) * 50
                            )
                        else
                            local AP = getNetAP(part)
                            if AP then AP.Enabled = true end
                            local AO = getNetAO(part)
                            if AO then AO.Enabled = true end
                            if not partTargets[part] then partTargets[part] = {} end
                            partTargets[part].position = tgt
                            partTargets[part].rotation = targetRotation
                            partTargets[part].responsiveness = responsiveness
                            syncAlignTarget(part, partTargets[part])
                        end
                    else
                        local AP = getNetAP(part)
                        if AP then AP.Enabled = true end
                        local AO = getNetAO(part)
                        if AO then AO.Enabled = true end
                        if not partTargets[part] then partTargets[part] = {} end
                        local homeTgt = tgt
                        if homingTarget and homingTarget.Parent and homingDone[part] then
                            pcall(function()
                                homeTgt = getFormationCenterTarget() + Vector3.new(0, formOffsetY, 0) + (partOffsets[part] or Vector3.zero) * 0.5
                            end)
                        end
                        partTargets[part].position = homeTgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                    end
                elseif isRail and railgunFired then
                    pcall(function()
                        pcall(linkNoCollide, part)
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                        if railgunPhase == "exploding" then
                            part.AssemblyAngularVelocity = Vector3.new(
                                (math.random() - 0.5) * 9e9,
                                (math.random() - 0.5) * 9e9,
                                (math.random() - 0.5) * 9e9
                            )
                        else
                            part.AssemblyAngularVelocity = Vector3.new(
                                math.sin(t * 6 + i) * 20,
                                math.cos(t * 7 + i) * 20,
                                math.sin(t * 8 + i) * 20
                            )
                        end
                        if not partTargets[part] then partTargets[part] = {} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = part.CFrame
                        partTargets[part].responsiveness = railgunPhase == "firing"
                            and getMoveResponsiveness(60)
                            or  getMoveResponsiveness(25)
                        syncAlignTarget(part, partTargets[part])
                    end)
                elseif isSniper then
                    pcall(function()
                        pcall(linkNoCollide, part)
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                        local ap = getNetAP(part)
                        if ap then
                            ap.Enabled = true
                            ap.MaxForce = alignForceFor(part)
                            ap.MaxVelocity = math.huge
                        end
                        local sAge2 = tick() - sniperFireTime
                        local firing2 = (sniperTargetPos ~= Vector3.zero and sAge2 >= 0 and sAge2 <= SNIPER_CYCLE and not sniperCaught)
                        local ao = getNetAO(part)
                        if ao then
                            ao.Enabled = true
                            ao.MaxTorque = alignForceFor(part)
                            ao.MaxAngularVelocity = math.huge
                        end
                        if not partTargets[part] then partTargets[part] = {} end
                        partTargets[part].position = tgt
                        partTargets[part].responsiveness = getMoveResponsiveness(firing2 and 50 or 42)
                        syncAlignTarget(part, partTargets[part])
                        if not firing2 then
                            part.AssemblyAngularVelocity = Vector3.zero
                            part.AssemblyLinearVelocity = netHoldVelocity()
                        end
                        local ownedS2 = false
                        pcall(function() ownedS2 = ownedCached(part) end)
                        if not ownedS2 then
                            local ovS = part.AssemblyLinearVelocity
                            part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                            part.AssemblyLinearVelocity = ovS
                        else
                            pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                        end
                        pcall(reclaimAssembly, part)
                        local _sr = getAssemblyRoot(part)
                        if _sr ~= part then pcall(reclaimAssembly, _sr) end
                    end)
                elseif isCube then
                    pcall(function()
                        pcall(linkNoCollide, part)
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                        local ap = getNetAP(part); if ap then ap.Enabled = true end
                        local ao = getNetAO(part); if ao then ao.Enabled = true end
                        if not partTargets[part] then partTargets[part] = {} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = getMoveResponsiveness(3.0)
                        syncAlignTarget(part, partTargets[part])
                        local ap2 = getNetAP(part)
                        if ap2 then ap2.MaxForce = alignForceFor(part); ap2.MaxVelocity = math.huge; ap2.Enabled = true end
                        local ovC = part.AssemblyLinearVelocity
                        part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                        part.AssemblyLinearVelocity = ovC
                    end)
                elseif isMG and minigunFlying[part] then
                    pcall(function()
                        local ap = getNetAP(part); if ap then ap.Enabled = true end
                        local ao = getNetAO(part); if ao then ao.Enabled = false end
                        if not partTargets[part] then partTargets[part] = {} end
                        partTargets[part].position = tgt
                        partTargets[part].responsiveness = getMoveResponsiveness(50)
                        syncAlignTarget(part, partTargets[part])
                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 1.5e6,
                            (math.random() - 0.5) * 1.5e6,
                            (math.random() - 0.5) * 1.5e6)
                    end)
                elseif isStrike and (strikeState == "descend" or strikeState == "drill") then
                    pcall(function()
                        local ap = getNetAP(part); if ap then ap.Enabled = true end
                        local ao = getNetAO(part); if ao then ao.Enabled = false end
                        if not partTargets[part] then partTargets[part] = {} end
                        partTargets[part].position = tgt
                        partTargets[part].responsiveness = getMoveResponsiveness(50)
                        syncAlignTarget(part, partTargets[part])
                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 3e6,
                            (math.random() - 0.5) * 3e6,
                            (math.random() - 0.5) * 3e6)
                    end)
                elseif isBarr then
                    pcall(function()
                        local burstAt = barrageBurst[part]
                        if not (burstAt and tick() - burstAt < 1.2) then
                            part.AssemblyAngularVelocity = Vector3.new(
                                (math.random() - 0.5) * 15000,
                                (math.random() - 0.5) * 15000,
                                (math.random() - 0.5) * 15000
                            )
                            part.AssemblyLinearVelocity = Vector3.zero
                        end

                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].responsiveness = getMoveResponsiveness(6.0)
                        syncAlignTarget(part, partTargets[part])

                        if not barrageTouchConns[part] then
                            barrageTouchConns[part] = part.Touched:Connect(function(hit)
                                if not hit or not hit.Parent or hit.Anchored then return end
                                if isVelImmune(hit) then return end
                                if hit == part then return end
                                if isSelected(hit) then return end

                                if isLocalPlayerPart(hit) then return end
                                pcall(function()
                                    part.AssemblyAngularVelocity = Vector3.new(
                                        (math.random() - 0.5) * 9e9,
                                        (math.random() - 0.5) * 9e9,
                                        (math.random() - 0.5) * 9e9
                                    )

                                    local burstDir = (hit.Position - part.Position)
                                    if burstDir.Magnitude > 0.001 then
                                        part.AssemblyLinearVelocity = burstDir.Unit * 350000 + Vector3.new(
                                            (math.random() - 0.5) * 8000,
                                            (math.random() - 0.5) * 8000,
                                            (math.random() - 0.5) * 8000
                                        )
                                    else
                                        part.AssemblyLinearVelocity = Vector3.new(
                                            (math.random() - 0.5) * 8000,
                                            (math.random() - 0.5) * 8000,
                                            (math.random() - 0.5) * 8000
                                        )
                                    end
                                end)

                                barrageBurst[part] = tick()

                                if barrageTouchConns[part] then
                                    pcall(function() barrageTouchConns[part]:Disconnect() end)
                                    barrageTouchConns[part] = nil
                                end
                            end)
                        end
                    end)
                elseif isWall and wallRoot then
                    targetRotation = wallPanelBasis(part) + tgt
                    responsiveness = getMoveResponsiveness(3.8)
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                        local ap = getNetAP(part)
                        if ap then ap.MaxForce = alignForceFor(part); ap.MaxVelocity = math.huge; ap.Responsiveness = math.huge; ap.Enabled=true end
                        local ao = getNetAO(part)
                        if ao then ao.MaxTorque = alignForceFor(part); ao.MaxAngularVelocity = math.huge; ao.Responsiveness = math.huge; ao.Enabled=true end
                        part.AssemblyLinearVelocity = Vector3.new(17.5555555,17.5555555,17.5555555)
                    end)
                elseif isText then
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local look0 = root and root.CFrame.LookVector or Vector3.new(0,0,-1)
                    local lookDir = Vector3.new(look0.X, 0, look0.Z)
                    if lookDir.Magnitude < 0.01 then lookDir = Vector3.new(0,0,-1) else lookDir = lookDir.Unit end
                    local upDir = Vector3.new(0,1,0)
                    local ang = textPartAngles[part] or 0
                    local isZLong = false
                    pcall(function()
                        local s = part.Size
                        isZLong = s.Z > s.X and s.Z > s.Y
                    end)
                    local baseCF = CFrame.lookAt(tgt, tgt + lookDir, upDir)
                    if isZLong then
                        targetRotation = baseCF * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(ang))
                    else
                        targetRotation = baseCF * CFrame.Angles(0, 0, math.rad(ang))
                    end
                    responsiveness = getMoveResponsiveness(3.8)
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                        local ap = getNetAP(part)
                        if ap then ap.MaxForce = alignForceFor(part); ap.MaxVelocity = math.huge; ap.Responsiveness = math.huge; ap.Enabled=true end
                        local ao = getNetAO(part)
                        if ao then ao.MaxTorque = alignForceFor(part); ao.MaxAngularVelocity = math.huge; ao.Responsiveness = math.huge; ao.Enabled=true end
                        part.AssemblyLinearVelocity = Vector3.new(17.5555555,17.5555555,17.5555555)
                    end)
                elseif isGrid then
                    responsiveness = getMoveResponsiveness(3.8)
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                        local ap = getNetAP(part)
                        if ap then ap.MaxForce = alignForceFor(part); ap.MaxVelocity = math.huge; ap.Responsiveness = math.huge; ap.Enabled=true end
                        local ao = getNetAO(part)
                        if ao then ao.MaxTorque = alignForceFor(part); ao.MaxAngularVelocity = math.huge; ao.Responsiveness = math.huge; ao.Enabled=true end
                        part.AssemblyLinearVelocity = Vector3.new(17.5555555,17.5555555,17.5555555)
                    end)
                elseif isRing then
                    responsiveness = getMoveResponsiveness(3.8)
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                        local ap = getNetAP(part)
                        if ap then ap.MaxForce = alignForceFor(part); ap.MaxVelocity = math.huge; ap.Responsiveness = math.huge; ap.Enabled=true end
                        local ao = getNetAO(part)
                        if ao then ao.MaxTorque = alignForceFor(part); ao.MaxAngularVelocity = math.huge; ao.Responsiveness = math.huge; ao.Enabled=true end
                        part.AssemblyLinearVelocity = Vector3.new(17.5555555,17.5555555,17.5555555)
                        pcall(reclaimAssembly, part)
                        local _rrg = getAssemblyRoot(part)
                        if _rrg ~= part then pcall(reclaimAssembly, _rrg) end
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                    end)
                elseif isBridge then
                    responsiveness = getMoveResponsiveness(3.8)
                    pcall(function()
                        local curD = nil
                        pcall(function() curD = part.CustomPhysicalProperties.Density end)
                        if curD and curD > 0.1 and not strengthenParts then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)
                        end
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                        local ap = getNetAP(part)
                        if ap then ap.MaxForce = alignForceFor(part); ap.MaxVelocity = math.huge; ap.Responsiveness = math.huge; ap.Enabled=true end
                        local ao = getNetAO(part)
                        if ao then ao.MaxTorque = alignForceFor(part); ao.MaxAngularVelocity = math.huge; ao.Responsiveness = math.huge; ao.Enabled=true end
                        if type(netHoldVelocity) == "function" then
                            part.AssemblyLinearVelocity = netHoldVelocity()
                        else
                            part.AssemblyLinearVelocity = Vector3.new(17.5555555,17.5555555,17.5555555)
                        end
                        pcall(linkNoCollide, part)
                        pcall(reclaimAssembly, part)
                        local _rrb = getAssemblyRoot(part)
                        if _rrb ~= part then pcall(reclaimAssembly, _rrb) end
                        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
                    end)
                else
                    pcall(function()
                        if not partBallistic(part) then
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        if isHalo or isGyro then
                            partTargets[part].rotResponsiveness = 200
                        else
                            partTargets[part].rotResponsiveness = nil
                        end
                        syncAlignTarget(part, partTargets[part])
                        if isStick and part.Parent and not part.Anchored then
                            part.AssemblyLinearVelocity = Vector3.new(17.5555555, 17.5555555, 17.5555555)
                        end
                    end)
                end
                if rotDrag.active and rotDrag.part == part then
                    pcall(function()
                        if part and part.Parent and not part.Anchored then
                            if not partTargets[part] then partTargets[part] = {} end
                            local dragRot = nil
                            if rotDrag.wantRot then
                                dragRot = CFrame.new(part.Position) * rotDrag.wantRot
                            else
                                dragRot = part.CFrame
                            end
                            partTargets[part].rotation = dragRot
                            syncAlignTarget(part, partTargets[part])
                            local aoR = getNetAO(part)
                            if aoR then aoR.CFrame = dragRot end
                        end
                    end)
                end
            end
        end
end


local function freezePlayer(f)
    local char=LP.Character; if not char then return end
    local h=char:FindFirstChildOfClass("Humanoid")
    local root=char:FindFirstChild("HumanoidRootPart")
    if h then h.WalkSpeed=f and 0 or 16; h.JumpPower=f and 0 or 50; h.AutoRotate=not f end
    if root then root.Anchored=f end
end

local function releaseNPC()
    if not npcTarget then return end
    for _,c in ipairs(npcConns) do pcall(function() c:Disconnect() end) end
    npcConns={}
    local h=npcTarget:FindFirstChildOfClass("Humanoid")
    if h then
        if npcSaved.ws then h.WalkSpeed=npcSaved.ws end
        if npcSaved.jp then h.JumpPower=npcSaved.jp end
        if npcSaved.ar ~= nil then h.AutoRotate=npcSaved.ar end
    end
    npcTarget=nil; npcSaved={}
    npcControlEnabled=false
    freezePlayer(false)
    Camera.CameraType=Enum.CameraType.Custom
    local ch=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if ch then Camera.CameraSubject=ch end
    UserInputService.MouseBehavior=Enum.MouseBehavior.Default
    Mouse.Icon=""

    if npcCtrlBtn then
        npcCtrlBtn.BackgroundColor3=PAL.B_DEF
        npcCtrlBtn.TextColor3=PAL.T1
        npcCtrlBtn.Text="NPC Control: OFF"
    end
end

local function takeNPC(model)
    if npcTarget then releaseNPC() end
    local hum=model:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    npcTarget=model; npcSaved={ws=hum.WalkSpeed,jp=hum.JumpPower,ar=hum.AutoRotate}
    freezePlayer(true)
    Camera.CameraType=Enum.CameraType.Scriptable
    npcCam.dist = 12  
    

    hum.WalkSpeed = npcControlWalkSpeed
    hum.JumpPower = npcControlJumpPower
    hum.AutoRotate = npcControlFreezeAutoJump and false or true

    npcCam.yaw=math.atan2(root.CFrame.LookVector.X,root.CFrame.LookVector.Z)
    npcCam.pitch = -0.25  

    npcCam._lastMouse=UserInputService:GetMouseLocation()
    local cc=RunService.RenderStepped:Connect(function()
        if npcTarget then
          local mp=UserInputService:GetMouseLocation()
          if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            npcCam.yaw=npcCam.yaw+(mp.X-npcCam._lastMouse.X)*0.005
            npcCam.pitch=math.clamp(npcCam.pitch+(mp.Y-npcCam._lastMouse.Y)*0.005,-1.2,0.4)
          end
          npcCam._lastMouse=mp
        end
        if not npcTarget then return end
        local nr=npcTarget:FindFirstChild("HumanoidRootPart"); if not nr then return end
        local focus=nr.Position+Vector3.new(0,1.8,0)
        local cf=CFrame.new(focus)*CFrame.Angles(0,npcCam.yaw,0)*CFrame.Angles(npcCam.pitch,0,0)*CFrame.new(0,0,-npcCam.dist)
        Camera.CFrame=CFrame.new(cf.Position,focus)
    end)
    table.insert(npcConns,cc)


    local rotating=false
    local rcDown=UserInputService.InputBegan:Connect(function(inp,gpe)
        if not npcTarget then return end
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then
            rotating=true

        end
    end)
    table.insert(npcConns,rcDown)
    local rcUp=UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then
            rotating=false
            UserInputService.MouseBehavior=Enum.MouseBehavior.Default
        end
    end)
    table.insert(npcConns,rcUp)

    local mc=UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement then
          if rotating and false then 
            npcCam.yaw=npcCam.yaw+inp.Delta.X*0.005
            npcCam.pitch=math.clamp(npcCam.pitch+inp.Delta.Y*0.005,-1.2,0.4)
          end
        elseif inp.UserInputType==Enum.UserInputType.MouseWheel then
            npcCam.dist = math.clamp(npcCam.dist - inp.Delta.Z*3, 2, 60)
        end
    end)
    table.insert(npcConns,mc)

    local mv=RunService.Heartbeat:Connect(function(dt)
        if not npcTarget then return end
        local nh=npcTarget:FindFirstChildOfClass("Humanoid")
        local nr=npcTarget:FindFirstChild("HumanoidRootPart")
        if not nh or not nr then return end
        local mx,mz=0,0
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mz+=1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mz-=1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mx-=1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mx+=1 end
        if mx~=0 or mz~=0 then
            local spd = npcControlEnabled and npcControlWalkSpeed or nh.WalkSpeed
            local dir=CFrame.Angles(0,npcCam.yaw,0):VectorToWorldSpace(Vector3.new(mx,0,mz)).Unit
            nh:MoveTo(nr.Position+dir*spd*dt*8)
        else 
            if npcControlHaltMoveTo then nh:MoveTo(nr.Position) end
        end
    end)
    table.insert(npcConns,mv)

    local jc=UserInputService.InputBegan:Connect(function(inp,gpe)
        if gpe or not npcTarget then return end
        if inp.KeyCode==Enum.KeyCode.Space then
            local nh=npcTarget:FindFirstChildOfClass("Humanoid"); if nh then nh.Jump=true end
        end
    end)
    table.insert(npcConns,jc)

    return true
end

local auraPlayerCharSet = nil
local function isNPCModel(model)
    if model == LP.Character then return false end
    if auraPlayerCharSet then
        if auraPlayerCharSet[model] then return false end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character == model then return false end
        end
    end
    return model:FindFirstChildOfClass("Humanoid") ~= nil
       and model:FindFirstChild("HumanoidRootPart") ~= nil
end

local _auraFrame = 0
local function tickAuras()
    if not (killAura or sitAura or jumpAura or followAura or freezeAura
        or speedAuraEnabled or spinAuraEnabled
        or fingerGunEnabled or grabGunEnabled or sitGunEnabled) then

        for model in pairs(npcHighlights) do
            removeNpcHighlight(model)
        end
        return
    end


    _auraFrame = (_auraFrame + 1) % 8
    if _auraFrame ~= 0 then return end

    local char   = LP.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos  = myRoot.Position


    local function getMouseRayHit(maxDist)

        local origin = Camera.CFrame.Position
        local dir = (currentMouseHit - origin)
        if not dir or dir.Magnitude < 0.001 then return nil end
        dir = dir.Unit * (maxDist or 1000)
        return workspace:Raycast(origin, dir, _npcToolsRayParams)
    end

    local function applyOneNPC(obj)
        if not (obj:IsA("Model") and isNPCModel(obj)) then return end
        if obj == npcTarget and npcControlEnabled then return end

        local tr = obj:FindFirstChild("HumanoidRootPart")
        local h  = obj:FindFirstChildOfClass("Humanoid")
        if not (tr and h) then return end
        local trImmune = isVelImmune(tr)

        local d = (tr.Position - myPos).Magnitude

        local willAffect = (killAura and d <= killAuraRange) or (sitAura and d <= sitAuraRange) or (jumpAura and d <= jumpAuraRange) or (followAura and d <= followAuraRange) or (freezeAura and d <= freezeAuraRange) or (speedAuraEnabled and d <= speedAuraRange) or (spinAuraEnabled and d <= spinAuraRange)
        if willAffect and not trImmune then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored and not isVelImmune(part) then
                    pcall(reinforceOwnershipConstraints, part, nil)
                    pcall(reinforceOwnershipHeartbeat, part, nil)
                    local origVel = part.AssemblyLinearVelocity
                    part.AssemblyLinearVelocity = netHoldVelocity()
                    part.AssemblyLinearVelocity = origVel
                    part.AssemblyLinearVelocity = Vector3.new(-17.5555555, -17.5555555, -17.5555555)
                    part.AssemblyLinearVelocity = origVel
                    part.AssemblyLinearVelocity = Vector3.new(17.5555555, -17.5555555, 17.5555555)
                    part.AssemblyLinearVelocity = origVel
            end
        end
        end

        if killAura  and d <= killAuraRange  then pcall(function() h.Health = 0; addNpcHighlight(obj, Color3.fromRGB(255, 50, 50)) end) end
        if sitAura   and d <= sitAuraRange   then pcall(function() h.Sit = true; addNpcHighlight(obj, Color3.fromRGB(50, 100, 255)) end) end
        if jumpAura  and d <= jumpAuraRange  then pcall(function() h.Jump = true; addNpcHighlight(obj, Color3.fromRGB(50, 200, 100)) end) end
        if followAura and d <= followAuraRange then pcall(function() h:MoveTo(myPos); addNpcHighlight(obj, Color3.fromRGB(200, 100, 255)) end) end
        if freezeAura and d <= freezeAuraRange then
            pcall(function()
                addNpcHighlight(obj, Color3.fromRGB(140, 140, 255))

                h.WalkSpeed = 16
                h.JumpPower = 50
                h.AutoRotate = true

                local rootPart = obj:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local myRoot2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot2 then
                        local toMe = myRoot2.Position - rootPart.Position
                        local dir = (toMe.Magnitude > 0.001) and (-toMe.Unit) or rootPart.CFrame.LookVector

                        local retreatAlpha = math.clamp(d / math.max(freezeAuraRange, 0.001), 0, 1)
                        local retreatDist = math.max(0, freezeAuraRange * (1 - retreatAlpha))

                        local target = rootPart.Position + dir * retreatDist
                        pcall(function() h:MoveTo(target) end)

                        if d < freezeAuraRange * 0.7 then
                            local backImpulse = dir * math.clamp((freezeAuraRange * 0.7 - d), 0, freezeAuraRange) * 1.5
                            if not trImmune and rootPart.AssemblyLinearVelocity then
                                rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + backImpulse
                            end
                        end
                    end
                end
            end)
        end


        if speedAuraEnabled and d <= speedAuraRange then

            pcall(function()
                h.WalkSpeed = math.max(h.WalkSpeed, speedAuraSpeed)
                addNpcHighlight(obj, Color3.fromRGB(120, 255, 150))
            end)

            if d <= speedAuraRange * 0.35 then
                local dir = (myPos - tr.Position)
                if dir.Magnitude > 0.01 and not trImmune then
                    pcall(function()
                        tr.AssemblyLinearVelocity = tr.AssemblyLinearVelocity + dir.Unit * 10
                    end)
                end
            end
        end


        if spinAuraEnabled and d <= spinAuraRange and not trImmune then

            local toMe = (myPos - tr.Position)
            if toMe.Magnitude > 0.001 then
                local yaw = math.atan2(toMe.X, toMe.Z)

                pcall(function()
                    tr.AssemblyAngularVelocity = Vector3.new(0, spinAuraSpeed, 0)
                    addNpcHighlight(obj, Color3.fromRGB(210, 145, 255))

                    if d <= spinAuraRange * 0.4 then
                        h:MoveTo(myPos)
                    end
                end)
                _ = yaw
            else
                pcall(function()
                    tr.AssemblyAngularVelocity = Vector3.new(0, spinAuraSpeed, 0)
                end)
            end
        end


        if obj == npcTarget then
            local toolHit = nil
            if (fingerGunEnabled or grabGunEnabled or sitGunEnabled) then
                toolHit = getMouseRayHit(FINGER_GUN_RANGE)
            end

            if sitGunEnabled then

                if d <= speedAuraRange * 10 then
                    pcall(function() h.Sit = true; addNpcHighlight(obj, Color3.fromRGB(50, 150, 200)) end)
                end
            end

            if fingerGunEnabled and toolHit and toolHit.Position then
                local lookDir = (toolHit.Position - tr.Position)
                if lookDir.Magnitude > 0.2 then
                    pcall(function()
                        tr.AssemblyLinearVelocity = tr.AssemblyLinearVelocity + lookDir.Unit * 25
                        addNpcHighlight(obj, Color3.fromRGB(100, 150, 255))
                    end)
                end
            end

            if grabGunEnabled and toolHit and toolHit.Position then
                local dir = (toolHit.Position - tr.Position)
                if dir.Magnitude > 0.2 then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hrp and not isVelImmune(hrp) then
                        pcall(function()
                            hrp.AssemblyLinearVelocity = dir.Unit * GRAB_TOSS_POWER + Vector3.new(0, 100, 0)
                            addNpcHighlight(obj, Color3.fromRGB(255, 180, 80))
                        end)
                    end
                end
            end
        end
    end

    local affectedNPCs = {}
    local function markAffected(obj)
        if obj:IsA("Model") and isNPCModel(obj) then
            affectedNPCs[obj] = true
        end
    end
    auraPlayerCharSet = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then auraPlayerCharSet[plr.Character] = true end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        applyOneNPC(obj)
        markAffected(obj)
        if obj:IsA("Model") or obj:IsA("Folder") then
            for _, child in ipairs(obj:GetChildren()) do
                applyOneNPC(child)
                markAffected(child)
            end
        end
    end

    for model in pairs(npcHighlights) do
        if not affectedNPCs[model] or not model.Parent then
            removeNpcHighlight(model)
        end
    end
end


do
    local P={}
    P.BG      = Color3.fromRGB(10,  6,  7)
    P.SURFACE = Color3.fromRGB(22, 12, 14)
    P.BORDER  = Color3.fromRGB(64, 30, 34)
    P.TBAR    = Color3.fromRGB(28, 14, 17)
    P.ACC     = Color3.fromRGB(215,  75, 80)
    P.ACC2    = Color3.fromRGB(140,  70, 74) 
    P.B_DEF   = Color3.fromRGB(38,  19, 21)
    P.B_RED   = Color3.fromRGB(150,  35, 42)
    P.B_GRN   = Color3.fromRGB( 22,  90, 46)
    P.B_YEL   = Color3.fromRGB(115,  80, 18)
    P.B_BLU   = Color3.fromRGB( 28,  48, 105)
    P.ON      = Color3.fromRGB(100,  32, 38)
    P.ON_TXT  = Color3.fromRGB(240, 185, 185)
    P.GREY_BG = Color3.fromRGB(38,  38, 42)
    P.GREY_TX = Color3.fromRGB(128, 128, 134)
    P.DV2C    = Color3.fromRGB(195,  70, 35)
    P.T1      = Color3.fromRGB(235, 212, 212)
    P.T2      = Color3.fromRGB(155, 110, 114)
    P.T3      = Color3.fromRGB( 90,  58, 62)
    GUI.PAL = P
end
PAL = GUI.PAL



local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "Catalyst"
ScreenGui.ResetOnSpawn     = false
ScreenGui.IgnoreGuiInset   = true
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder     = GUI.DISPLAY_ORDER
ScreenGui.Parent           = getGuiParent()

do function unloadScript()
    pcall(function() saveConfig(true) end)
    pcall(function() if ownerConn then ownerConn:Disconnect() end end)
    pcall(function() if renderOwnerConn then renderOwnerConn:Disconnect() end end)
    pcall(function() if aggressiveOwnerConn then aggressiveOwnerConn:Disconnect() end end)
    pcall(function() if preSimConn then preSimConn:Disconnect() end end)
    pcall(function() if smoothMovementConn then smoothMovementConn:Disconnect() end end)
    pcall(function() if EspRenderConn then EspRenderConn:Disconnect() end end)
    pcall(function() if mainHeartbeatConn then mainHeartbeatConn:Disconnect() end end)
    pcall(function() if renderSteppedConn then renderSteppedConn:Disconnect() end end)
    if NX.dead then return end
    NX.dead = true

    stickGrabActive = false
    stickBeamActive = false
    stickMagnetActive = false
    stickDanceActive = false
    stickCrawlActive = false
    stickTPose = false
    for _, conn in pairs(stickSlapConns) do pcall(function() conn:Disconnect() end) end
    stickSlapConns = {}
    for _, conn in pairs(stickBeamConns) do pcall(function() conn:Disconnect() end) end
    stickBeamConns = {}

    autoSelectAll = false
    autoSelectNear = false
    attracting = false
    frozen = false
    spcActive = false
    spcPart = nil
    isDrawing = false
    killAura = false
    sitAura = false
    jumpAura = false
    followAura = false
    freezeAura = false
    speedAuraEnabled = false
    spinAuraEnabled = false
    fingerGunEnabled = false
    grabGunEnabled = false
    sitGunEnabled = false
    grabbedNPC = nil
    grabbedRoot = nil
    localGrabArmed = false

    NX.tkGun = false
    NX.freezeGun = false
    if NX.held then
        local h = NX.held:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.PlatformStand = (NX.savedPS == true) end) end
    end
    NX.held = nil; NX.root = nil; NX.savedPS = nil
    for model, s in pairs(NX.frozen) do
        local h = model and model:FindFirstChildOfClass("Humanoid")
        if h then pcall(function()
            h.WalkSpeed = s.ws; h.JumpPower = s.jp
            pcall(function() h.JumpHeight = s.jh end)
            h.AutoRotate = s.ar; h.PlatformStand = s.ps
        end) end
    end
    NX.frozen = {}

    if _G._setNPCPick then pcall(function() _G._setNPCPick(false) end) end
    _G._setNPCPick = nil
    _G._getNPCPickActive = nil

    pcall(function() releaseNPC() end)
    pcall(function() clearDrawDots() end)
    pcall(function() clearSelection(false) end)

    for part, conn in pairs(partTouchConns) do
        pcall(function() conn:Disconnect() end)
        partTouchConns[part] = nil
    end

    for part in pairs(highlights) do
        removeHL(part)
    end
    for part, tag in pairs(espLabels) do
        if tag and tag.frame then pcall(function() tag.frame:Destroy() end) end
        espLabels[part] = nil
    end
    for model in pairs(npcHighlights) do
        removeNpcHighlight(model)
    end
    if spcHighlight then
        spcHighlight:Destroy()
        spcHighlight = nil
    end

    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    pcall(function() if ownerConn then ownerConn:Disconnect() end end)
    pcall(function() if renderOwnerConn then renderOwnerConn:Disconnect() end end)
    pcall(function() if aggressiveOwnerConn then aggressiveOwnerConn:Disconnect() end end)
    pcall(function() if preSimConn then preSimConn:Disconnect() end end)
    pcall(function() if smoothMovementConn then smoothMovementConn:Disconnect() end end)

    pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
    pcall(function() Mouse.Icon = "" end)
    pcall(function()
        Camera.CameraType = Enum.CameraType.Custom
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then Camera.CameraSubject = h end
    end)
    pcall(function() freezePlayer(false) end)

    if ScreenGui and ScreenGui.Parent then pcall(function() ScreenGui:Destroy() end) end
    if EspScreenGui and EspScreenGui.Parent then pcall(function() EspScreenGui:Destroy() end) end
    if TextScreenGui and TextScreenGui.Parent then pcall(function() TextScreenGui:Destroy() end) end
    for p,c in pairs(scytheConns) do pcall(function() c:Disconnect() end) end
    scytheConns = {}
    scytheSwingPos = Vector3.zero
    scytheCenter = Vector3.zero
    for p,c in pairs(chainedConns) do pcall(function() c:Disconnect() end) end
    chainedConns = {}
    chainedFired = {}
    chainedTarget = Vector3.zero
    chainedActive = false
end end
function corner(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 5) end

function mkF(props,parent)
    local f=Instance.new("Frame"); f.BorderSizePixel=0
    for k,v in pairs(props) do f[k]=v end
    if props.BackgroundTransparency == nil then f.BackgroundTransparency = 0.12 end
    stampGui(f); f.Parent=parent; return f
end
function mkL(props,parent)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.BorderSizePixel=0
    for k,v in pairs(props) do l[k]=v end
    stampGui(l); l.Parent=parent; return l
end
function mkB(props,parent)
    local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.BorderSizePixel=0
    for k,v in pairs(props) do b[k]=v end
    if props.BackgroundTransparency == nil then b.BackgroundTransparency = 0.12 end
    stampGui(b); b.Parent=parent; corner(b,4)
    b.MouseEnter:Connect(function()
        if b:GetAttribute("hovOn") then return end
        b:SetAttribute("hovOn", true)
        b:SetAttribute("hovPrev", b.BackgroundColor3)
        b.BackgroundColor3 = b.BackgroundColor3:Lerp(Color3.new(1,1,1),.09)
    end)
    b.MouseLeave:Connect(function()
        b:SetAttribute("hovOn", nil)
        local prev = b:GetAttribute("hovPrev")
        b:SetAttribute("hovPrev", nil)
        if typeof(prev) == "Color3" then
            if b.BackgroundColor3 == prev:Lerp(Color3.new(1,1,1),.09) then
                b.BackgroundColor3 = prev
            end
        end
    end)
    local sc=Instance.new("UIScale"); sc.Scale=1; sc.Parent=b
    b.MouseButton1Down:Connect(function() sc.Scale=0.96 end)
    b.MouseButton1Up:Connect(function() sc.Scale=1 end)
    b.MouseLeave:Connect(function() sc.Scale=1 end)
    return b
end

toggleRegistry = {}

function mkToggleBtn(props, parent, get)
    local b=mkB(props,parent)
    b.TextXAlignment = Enum.TextXAlignment.Left
    local track=mkF({Size=UDim2.new(0,34,0,18),Position=UDim2.new(1,-40,0.5,-9),
        BackgroundColor3=PAL.BORDER,ZIndex=GUI.Z+1},b)
    corner(track,9)
    local knob=mkF({Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,2,0.5,-7),
        BackgroundColor3=PAL.T3,ZIndex=GUI.Z+2},track)
    corner(knob,7)
    local function refresh()
        local on = get()
        track.BackgroundColor3 = on and PAL.ON or PAL.BORDER
        knob.BackgroundColor3 = on and PAL.ON_TXT or PAL.T3
        knob.Position = on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    end
    toggleRegistry[b] = refresh
    refresh()
    return b
end

function refreshToggle(btn)
    local f = toggleRegistry[btn]
    if f then pcall(f) end
end

function refreshAllToggles()
    for b, f in pairs(toggleRegistry) do
        if b and b.Parent then pcall(f) end
    end
end

function mkTab(props,parent)
    local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.BorderSizePixel=0
    for k,v in pairs(props) do b[k]=v end
    if props.BackgroundTransparency == nil then b.BackgroundTransparency = 0.12 end
    b:SetAttribute("NoKeybind", true)
    stampGui(b); b.Parent=parent; corner(b,4)
    b.MouseEnter:Connect(function()
        if b:GetAttribute("hovOn") then return end
        b:SetAttribute("hovOn", true)
        b:SetAttribute("hovPrev", b.BackgroundColor3)
        b.BackgroundColor3 = b.BackgroundColor3:Lerp(Color3.new(1,1,1),.09)
    end)
    b.MouseLeave:Connect(function()
        b:SetAttribute("hovOn", nil)
        local prev = b:GetAttribute("hovPrev")
        b:SetAttribute("hovPrev", nil)
        if typeof(prev) == "Color3" then
            if b.BackgroundColor3 == prev:Lerp(Color3.new(1,1,1),.09) then
                b.BackgroundColor3 = prev
            end
        end
    end)
    local sc=Instance.new("UIScale"); sc.Scale=1; sc.Parent=b
    b.MouseButton1Down:Connect(function() sc.Scale=0.96 end)
    b.MouseButton1Up:Connect(function() sc.Scale=1 end)
    b.MouseLeave:Connect(function() sc.Scale=1 end)
    return b
end

function fadePanelIn(panel)
    if not (panel and panel.Parent) then return end
    local TS = game:GetService("TweenService")
    for _, o in ipairs(panel:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
            if not o:GetAttribute("fpFade") then
                local t0 = o.TextTransparency
                o:SetAttribute("fpFade", true)
                o.TextTransparency = 1
                local tw = nil
                local done = false
                local function clear()
                    if done then return end
                    done = true
                    pcall(function() o:SetAttribute("fpFade", nil) end)
                end
                pcall(function()
                    tw = TS:Create(o, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {TextTransparency = t0})
                    tw:Play()
                end)
                if tw then
                    pcall(function() tw.Completed:Connect(function() clear() end) end)
                    task.delay(0.3, clear)
                else
                    o.TextTransparency = t0
                    clear()
                end
            end
        end
    end
end


function mkDiv(parent,order)
    return mkF({Size=UDim2.new(1,0,0,1),BackgroundColor3=PAL.BORDER,LayoutOrder=order},parent)
end

function mkSec(text,parent,order)
    return mkL({Size=UDim2.new(1,0,0,16),Text=text,TextColor3=PAL.ACC2,TextSize=9,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order},parent)
end


function mkRow2(parent,order,p1,p2)
    local row=mkF({Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=order},parent)
    local o1={}; for k,v in pairs(p1) do o1[k]=v end; o1.Size=UDim2.new(0.5,-2,1,0); o1.Position=UDim2.new(0,0,0,0)
    local b1=mkB(o1,row)
    local o2={}; for k,v in pairs(p2) do o2[k]=v end; o2.Size=UDim2.new(0.5,-2,1,0); o2.Position=UDim2.new(0.5,2,0,0)
    local b2=mkB(o2,row)
    return row,b1,b2
end


function mkSlider(parent,ltext,lo,hi,def,order,onChange,step)
    local function formatValue(value)
        if step and step < 1 then
            return string.format("%.1f", value)
        end
        return tostring(value)
    end
    local wrap=mkF({Size=UDim2.new(1,0,0,42),BackgroundColor3=PAL.SURFACE,LayoutOrder=order},parent)
    corner(wrap,5)
    local lbl=mkL({Size=UDim2.new(1,-64,0,16),Position=UDim2.new(0,8,0,3),
        Text=ltext,TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left},wrap)
    local valBox=Instance.new("TextBox")
    valBox.Size=UDim2.new(0,56,0,16); valBox.Position=UDim2.new(1,-64,0,3)
    valBox.BackgroundTransparency=1; valBox.TextColor3=PAL.T1; valBox.TextSize=11
    valBox.Font=Enum.Font.Gotham; valBox.TextXAlignment=Enum.TextXAlignment.Right
    valBox.ClearTextOnFocus=false; valBox.Text=formatValue(def)
    stampGui(valBox); valBox.Parent=wrap
    local track=mkF({Size=UDim2.new(1,-16,0,4),Position=UDim2.new(0,8,0,28),
        BackgroundColor3=PAL.BORDER},wrap)
    corner(track,3)
    local r0=(def-lo)/(hi-lo)
    local fill=mkF({Size=UDim2.new(r0,0,1,0),BackgroundColor3=PAL.ACC},track); corner(fill,3)
    local thumb=mkB({Size=UDim2.new(0,11,0,11),Position=UDim2.new(r0,-5,0.5,-5),
        BackgroundColor3=Color3.fromRGB(230,205,205),Text="",ZIndex=GUI.Z+8},track)
    thumb:SetAttribute("NoKeybind", true)
    thumb.MouseEnter:Connect(function()
        local r = thumb.Position.X.Scale
        thumb.Size = UDim2.new(0,14,0,14)
        thumb.Position = UDim2.new(r,-7,0.5,-7)
    end)
    thumb.MouseLeave:Connect(function()
        local r = thumb.Position.X.Scale
        thumb.Size = UDim2.new(0,11,0,11)
        thumb.Position = UDim2.new(r,-5,0.5,-5)
    end)
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local sl=false
    local lastValue=def
    local lastMouseX=nil
    local typing=false
    local function roundVal(raw)
        local isF=(hi-lo)<=5
        if step then
            local v=lo+math.floor((raw-lo)/step+0.5)*step
            return math.clamp(v,lo,hi)
        else
            return isF and (math.floor(raw*10)/10) or math.floor(raw)
        end
    end
    local function showVal(val, skipBox)
        local valueRatio=(val-lo)/(hi-lo)
        fill.Size=UDim2.new(valueRatio,0,1,0); thumb.Position=UDim2.new(valueRatio,-5,0.5,-5)
        if not skipBox then valBox.Text=formatValue(val) end
        if onChange then onChange(val) end
        lastValue=val
    end
    valBox.Focused:Connect(function() typing=true end)
    valBox.FocusLost:Connect(function(enterPressed)
        typing=false
        if enterPressed then
            local n=tonumber(valBox.Text)
            if n then showVal(roundVal(math.clamp(n,lo,hi))) end
        end
        valBox.Text=formatValue(lastValue)
    end)
    thumb.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            sl=true
            lastMouseX=i.Position.X
        end
    end)
    reg(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            sl=false
            lastMouseX=nil
        end
    end))
    reg(UserInputService.InputChanged:Connect(function(i)
        if not sl or (i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch) then return end
        local ap=track.AbsolutePosition; local as=track.AbsoluteSize
        local r=math.clamp((i.Position.X-ap.X)/as.X,0,1)
        local raw=lo+(hi-lo)*r
        local val
        if step and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
            local deltaX=i.Position.X-(lastMouseX or i.Position.X)
            val=math.clamp(lastValue+deltaX*step,lo,hi)
            val=lo+math.floor((val-lo)/step+0.5)*step
        else
            val=roundVal(raw)
        end
        showVal(val, typing)
        lastMouseX=i.Position.X
    end))
    return wrap
end

local TweenService = game:GetService("TweenService")
activeToasts = {}

local TOAST_W, TOAST_H, TOAST_GAP, TOAST_TOP, TOAST_LIFE = 300, 44, 8, 10, 2.4

local function toastY(i)
    return TOAST_TOP + (i - 1) * (TOAST_H + TOAST_GAP)
end

local function restackToasts()
    for i, fr in ipairs(activeToasts) do
        if fr and fr.Parent then
            local y = toastY(i)
            pcall(function()
                TweenService:Create(fr, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = UDim2.new(1, -TOAST_W - 10, 0, y)}):Play()
            end)
        end
    end
end

function toast(msg)
    if not ScreenGui or not ScreenGui.Parent then return end
    while #activeToasts >= 5 do
        local old = table.remove(activeToasts, 1)
        if old then pcall(function() old:Destroy() end) end
    end
    local y = toastY(#activeToasts + 1)
    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(0, TOAST_W, 0, TOAST_H)
    fr.Position = UDim2.new(1, 10, 0, y)
    fr.BackgroundColor3 = PAL.SURFACE
    fr.BorderSizePixel = 0
    fr.ZIndex = GUI.Z + 50
    fr.Parent = ScreenGui
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", fr)
    st.Color = PAL.BORDER
    st.Thickness = 1
    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(1, -20, 1, -8)
    lb.Position = UDim2.new(0, 10, 0, 2)
    lb.Text = tostring(msg)
    lb.TextColor3 = PAL.T1
    lb.TextSize = 12
    lb.Font = Enum.Font.Gotham
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.TextTruncate = Enum.TextTruncate.AtEnd
    lb.ZIndex = GUI.Z + 51
    lb.Parent = fr
    local barWrap = Instance.new("Frame")
    barWrap.Name = "ToastTime"
    barWrap.BackgroundTransparency = 1
    barWrap.BorderSizePixel = 0
    barWrap.Size = UDim2.new(1, -20, 0, 3)
    barWrap.Position = UDim2.new(0, 10, 1, -8)
    barWrap.ClipsDescendants = true
    barWrap.ZIndex = GUI.Z + 51
    barWrap.Parent = fr
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.ZIndex = GUI.Z + 52
    bar.Parent = barWrap
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
    table.insert(activeToasts, fr)
    pcall(function()
        TweenService:Create(fr, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -TOAST_W - 10, 0, y)}):Play()
        TweenService:Create(bar, TweenInfo.new(TOAST_LIFE, Enum.EasingStyle.Linear),
            {Size = UDim2.new(0, 0, 1, 0)}):Play()
    end)
    task.delay(TOAST_LIFE, function()
        if not fr or not fr.Parent then return end
        local curY = y
        pcall(function() curY = fr.Position.Y.Offset end)
        pcall(function()
            local tw = TweenService:Create(fr, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 10, 0, curY)})
            tw:Play()
            tw.Completed:Connect(function()
                pcall(function() fr:Destroy() end)
            end)
        end)
        task.delay(0.35, function()
            for i, f in ipairs(activeToasts) do
                if f == fr then table.remove(activeToasts, i); break end
            end
            restackToasts()
        end)
    end)
end

selToastPending = false
function toastSelectionSoon()    if selToastPending then return end
    selToastPending = true
    task.delay(0.6, function()
        selToastPending = false
        local n = #selectedParts
        if n == 0 then
            toast("selection cleared")
        else
            toast(n .. (n == 1 and " part selected" or " parts selected"))
        end
    end)
end

greyStore = {}

function setGreyed(obj, grey)
    if not obj or not obj.Parent then return end
    if obj:GetAttribute("greyed") == grey then return end
    obj:SetAttribute("greyed", grey)
    local list = {obj}
    for _, o in ipairs(obj:GetDescendants()) do table.insert(list, o) end
    for _, o in ipairs(list) do
        if o:IsA("GuiObject") then
            local isText = o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")
            if grey then
                if o:GetAttribute("gInit") == nil then
                    o:SetAttribute("gInit", true)
                    o:SetAttribute("gBg", o.BackgroundColor3)
                    o:SetAttribute("gAct", o.Active)
                    if isText then o:SetAttribute("gTx", o.TextColor3) end
                end
                o.Active = false
                o.BackgroundColor3 = PAL.GREY_BG
                if isText then o.TextColor3 = PAL.GREY_TX end
            else
                if o:GetAttribute("gInit") ~= nil then
                    o.Active = o:GetAttribute("gAct")
                    o.BackgroundColor3 = o:GetAttribute("gBg")
                    if isText and o:GetAttribute("gTx") ~= nil then o.TextColor3 = o:GetAttribute("gTx") end
                end
            end
        end
    end
end

function refreshGreyed()
    if spcDepthWrap then setGreyed(spcDepthWrap, not spcActive) end
    if partLimitWrap then setGreyed(partLimitWrap, not useLimits) end
    if densityWrap then setGreyed(densityWrap, not strengthenParts) end
end

function setActiveMode(name)    if not name or activeMode == name then return end
    clearModeState(activeMode, name)
    activeMode = name
    if _G.refreshModes then
        pcall(_G.refreshModes)
    elseif _G.modeButtons then
        for nm, mb in pairs(_G.modeButtons) do
            local on = nm == activeMode
            local cat = (_G.MODE_CAT and _G.MODE_CAT[nm] or "blue")
            local col = (_G.CAT_COL and _G.CAT_COL[cat] or {bg=Color3.fromRGB(16,24,50), bgOn=Color3.fromRGB(38,70,148), tx=Color3.fromRGB(110,145,235)})
            mb.BackgroundColor3 = on and col.bgOn or col.bg
            mb.TextColor3 = col.tx
            if buttonKeybinds[mb] and buttonKeybinds[mb].originalText then
                mb.Text = buttonKeybinds[mb].originalText .. " [" .. buttonKeybinds[mb].key.Name .. "]"
            end
        end
    end
    toast("mode: " .. string.lower(tostring(name)))
end


UI = nil

function buildMinButton(TBar)
    local MinBtn=mkB({Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-58,0,9),
        BackgroundColor3=Color3.fromRGB(32,32,42),Text="-",TextColor3=PAL.T1,TextSize=13,
        Font=Enum.Font.GothamBold,ZIndex=GUI.Z+2},TBar)
    MinBtn:SetAttribute("NoKeybind", true)
    return MinBtn
end


function buildCloseButton(TBar)
    local CloseBtn=mkB({Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,0,9),
        BackgroundColor3=PAL.B_RED,Text="X",TextColor3=Color3.new(1,1,1),TextSize=12,
        Font=Enum.Font.GothamBold,ZIndex=GUI.Z+2},TBar)
    CloseBtn:SetAttribute("NoKeybind", true)
    CloseBtn.MouseButton1Click:Connect(function()
        unloadScript()
    end)
end


function buildTitleBarButtons(TBar)
    local MinBtn = buildMinButton(TBar)
    buildCloseButton(TBar)
    return MinBtn
end


function buildTitleBar(Main, MINI)
    local TBar=mkF({Size=UDim2.new(1,0,0,MINI),BackgroundColor3=PAL.TBAR,ZIndex=GUI.Z+1},Main)
    corner(TBar,8)
    mkF({Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=PAL.TBAR,ZIndex=GUI.Z+1},TBar)

    mkL({Size=UDim2.new(1,-80,1,0),Position=UDim2.new(0,12,0,0),
        Text="Catalyst!",TextColor3=PAL.T1,TextSize=13,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=GUI.Z+2},TBar)
    mkL({Size=UDim2.new(1,-170,1,0),Position=UDim2.new(0,90,0,0),
        Text="salami edition.",TextColor3=Color3.fromRGB(240,240,240),TextSize=10,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=GUI.Z+2},TBar)

    local MinBtn = buildTitleBarButtons(TBar)

    return TBar, MinBtn
end

function setupDrag(Main, TBar)
    local dragging,dStart,dOrigin=false,nil,nil
    reg(TBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dStart=inp.Position; dOrigin=Main.Position
        end
    end))
    reg(UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-dStart
            Main.Position=UDim2.new(dOrigin.X.Scale,dOrigin.X.Offset+d.X,dOrigin.Y.Scale,dOrigin.Y.Offset+d.Y)
        end
    end))
    reg(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
end

function buildBody(Main, MinBtn, W, H, MINI, ResizeHandle)
    local Body=mkF({Size=UDim2.new(1,0,1,-MINI-20),Position=UDim2.new(0,0,0,MINI),BackgroundTransparency=1},Main)
    local minimized=false
    local tweening=false
    local function fadeUI(root, out)
        for _, o in ipairs(root:GetDescendants()) do
            if o:IsA("GuiObject") then
                if o:GetAttribute("tzInit") == nil then
                    o:SetAttribute("tzInit", true)
                    o:SetAttribute("tzBg", o.BackgroundTransparency)
                    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
                        o:SetAttribute("tzTx", o.TextTransparency)
                    end
                end
                local tBg = out and 1 or o:GetAttribute("tzBg")
                pcall(function()
                    TweenService:Create(o, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundTransparency = tBg}):Play()
                end)
                if o:GetAttribute("tzTx") ~= nil then
                    local tTx = out and 1 or o:GetAttribute("tzTx")
                    pcall(function()
                        TweenService:Create(o, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {TextTransparency = tTx}):Play()
                    end)
                end
                local st = o:FindFirstChildOfClass("UIStroke")
                if st then
                    if o:GetAttribute("tzSt") == nil then o:SetAttribute("tzSt", st.Transparency) end
                    local tSt = out and 1 or o:GetAttribute("tzSt")
                    pcall(function()
                        TweenService:Create(st, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {Transparency = tSt}):Play()
                    end)
                end
            end
        end
    end
    MinBtn.MouseButton1Click:Connect(function()
        if tweening then return end
        tweening=true
        minimized=not minimized
        MinBtn.Text=minimized and "+" or "-"
        if minimized then
            fadeUI(Body, true)
            task.delay(0.17, function()
                Body.Visible=false
                if ResizeHandle then ResizeHandle.Visible = false end
                local tw
                pcall(function()
                    tw = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size=UDim2.new(0,W,0,MINI)})
                    tw:Play()
                end)
                if tw then tw.Completed:Connect(function() tweening=false end)
                else tweening=false end
            end)
        else
            Body.Visible=true
            if ResizeHandle then ResizeHandle.Visible = true end
            local tw
            pcall(function()
                tw = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size=UDim2.new(0,W,0,H)})
                tw:Play()
            end)
            fadeUI(Body, false)
            if tw then tw.Completed:Connect(function() tweening=false end)
            else tweening=false end
        end
    end)
    return Body, minimized
end


function buildMainFrame()
    local W,H,MINI=440,560,42

    local Main=mkF({Name="Main",Size=UDim2.new(0,W,0,H),
        Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=PAL.BG,BackgroundTransparency=0.12,ZIndex=GUI.Z},ScreenGui)
    corner(Main,8)

    local isMob = false
    pcall(function()
        local uis = game:GetService("UserInputService")
        if uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled then isMob = true end
        if uis:GetPlatform() == Enum.Platform.IOS or uis:GetPlatform() == Enum.Platform.Android then isMob = true end
    end)
    if isMob then
        Main.AnchorPoint = Vector2.new(0.5, 0.5)
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
        local uiScale = Instance.new("UIScale")
        uiScale.Scale = 0.65 -- Adjust this number (e.g. 0.5 to 0.8) to make it smaller or larger on mobile
        uiScale.Parent = Main
    end
    local shdw=mkF({Size=UDim2.new(1,10,1,10),Position=UDim2.new(0,-5,0,5),
        BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.58,ZIndex=GUI.Z-1},Main)
    corner(shdw,11)

    local TBar, MinBtn = buildTitleBar(Main, MINI)
    setupDrag(Main, TBar)
    local ResizeHandle = Instance.new("TextButton")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
    ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
    ResizeHandle.BackgroundColor3 = PAL.ACC
    ResizeHandle.BackgroundTransparency = 0
    ResizeHandle.BorderSizePixel = 0
    ResizeHandle.Text = "◢"
    ResizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ResizeHandle.TextSize = 14
    ResizeHandle.Font = Enum.Font.GothamBold
    ResizeHandle.TextXAlignment = Enum.TextXAlignment.Center
    ResizeHandle.TextYAlignment = Enum.TextYAlignment.Center
    ResizeHandle.ZIndex = GUI.Z + 10
    ResizeHandle.AutoButtonColor = false
    ResizeHandle:SetAttribute("NoKeybind", true)
    ResizeHandle.Parent = Main

    local resizeCorner = Instance.new("UICorner", ResizeHandle)
    resizeCorner.CornerRadius = UDim.new(0, 3)

    local Body, minimized = buildBody(Main, MinBtn, W, H, MINI, ResizeHandle)

    local Foot=mkF({Name="Footer",Size=UDim2.new(1,-28,0,20),Position=UDim2.new(0,0,1,-20),BackgroundColor3=PAL.TBAR,ZIndex=GUI.Z+1},Main)
    Foot.Visible = Body.Visible
    Body:GetPropertyChangedSignal("Visible"):Connect(function()
        if Foot and Foot.Parent then
            Foot.Visible = Body.Visible
        end
    end)    corner(Foot,8)
    mkF({Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,0,0),BackgroundColor3=PAL.TBAR,ZIndex=GUI.Z+1},Foot)
    local footLbl=mkL({Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),
        Text="ready",TextColor3=PAL.T3,TextSize=10,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=GUI.Z+2},Foot)
    local footAcc, footFps = 0, 60
    reg(RunService.RenderStepped:Connect(function(dt)
        if dt and dt > 0 then footFps = footFps*0.95 + (1/math.max(dt, 1e-4))*0.05 end
        footAcc += (dt or 0.016)
        if footAcc >= 1 and Foot.Parent and footLbl.Parent then
            footAcc = 0
            local n = #selectedParts
            local inpos, total = 0, 0
            for _, p in ipairs(selectedParts) do
                if p and p.Parent and not passengerSet[p] then
                    local tp = partTargets[p] and partTargets[p].position
                    if tp then
                        total += 1
                        local tol = 3
                        pcall(function() tol = math.max(3, p.Size.Magnitude * 0.75) end)
                        if (p.Position - tp).Magnitude <= tol then
                            inpos += 1
                        end
                    end
                end
            end
            local opct = total > 0 and math.floor(inpos/total*100 + 0.5) or 100
            local groundedTag = ""
            for _, gp in ipairs(selectedParts) do
                if gp and gp.Parent and gp.Anchored then groundedTag = " | GROUNDED" break end
            end
            local riderTag = ""
            for fp in pairs(frozenTargets) do
                if fp and fp.Parent and riderStillNear(fp) then riderTag = " | RIDER!" break end
            end
            local takeTag = ""
            footLbl.Text = string.format("%s | %d %s | %d%% in position | %d fps%s%s%s",
                string.lower(tostring(activeMode)), n, n == 1 and "part" or "parts",
                opct, math.floor(footFps + 0.5), groundedTag, riderTag, takeTag)
        end
    end))
    

    ResizeHandle.Visible = Body.Visible

    local resizing = false
    local resizeStart = Vector2.new()
    local startSize = Vector2.new(W, H)

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = Vector2.new(input.Position.X, input.Position.Y)
            startSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local currentPos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = currentPos - resizeStart
            local newSize = startSize + delta
            local clampedWidth = math.clamp(newSize.X, 300, 1200)
            local clampedHeight = math.clamp(newSize.Y, 400, 900)
            Main.Size = UDim2.new(0, clampedWidth, 0, clampedHeight)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)


    MinBtn.MouseButton1Click:Connect(function()
        ResizeHandle.Visible = Body.Visible
    end)
    local Hover = mkF({Name="HoverDesc",Size=UDim2.new(0, 280, 0, 360),Position=UDim2.new(1, 12, 0, 0),BackgroundColor3=PAL.SURFACE,BackgroundTransparency=0.35,ZIndex=GUI.Z,Visible=false}, Main)
    corner(Hover, 6)
    local hStroke = Instance.new("UIStroke", Hover)
    hStroke.Color = PAL.BORDER
    hStroke.Thickness = 1.2
    hStroke.Transparency = 0.25
    hStroke.Parent = Hover
    local hTitle = mkL({Name="HoverTitle",Size=UDim2.new(1,-12,0,22),Position=UDim2.new(0,6,0,6),Text="",TextColor3=PAL.ACC,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=GUI.Z+1,BackgroundTransparency=1}, Hover)
    local hScroll = Instance.new("ScrollingFrame")
    hScroll.Name = "HoverScroll"
    hScroll.Size = UDim2.new(1,-12,1,-34)
    hScroll.Position = UDim2.new(0,6,0,28)
    hScroll.BackgroundTransparency = 1
    hScroll.BorderSizePixel = 0
    hScroll.ScrollBarThickness = 3
    hScroll.ScrollBarImageColor3 = PAL.ACC2
    hScroll.CanvasSize = UDim2.new(0,0,0,0)
    hScroll.ZIndex = GUI.Z+1
    hScroll.Parent = Hover
    local hDesc = Instance.new("TextLabel")
    hDesc.Name = "HoverDescLabel"
    hDesc.Size = UDim2.new(1,-6,0,0)
    hDesc.BackgroundTransparency = 1
    hDesc.TextColor3 = PAL.T1
    hDesc.TextSize = 10
    hDesc.Font = Enum.Font.Gotham
    hDesc.TextXAlignment = Enum.TextXAlignment.Left
    hDesc.TextYAlignment = Enum.TextYAlignment.Top
    hDesc.TextWrapped = true
    hDesc.AutomaticSize = Enum.AutomaticSize.Y
    hDesc.ZIndex = GUI.Z+1
    hDesc.Text = ""
    hDesc.Parent = hScroll
    hDesc:GetPropertyChangedSignal("TextBounds"):Connect(function()
        hScroll.CanvasSize = UDim2.new(0,0,0,hDesc.TextBounds.Y+6)
    end)
    hDesc:GetPropertyChangedSignal("Text"):Connect(function()
        hScroll.CanvasSize = UDim2.new(0,0,0,hDesc.TextBounds.Y+6)
    end)
    _G.HoverPanel = Hover
    _G.HoverTitle = hTitle
    _G.HoverDescLabel = hDesc
    local function setHoverDesc(modeName)
        Hover.Visible = true
        if _G.MODE_DESC and _G.MODE_DESC[modeName] then
            local full = _G.MODE_DESC[modeName]
            local firstNL = string.find(full, "\n")
            if firstNL then
                hTitle.Text = string.sub(full, 1, firstNL-1)
                hDesc.Text = string.sub(full, firstNL+1)
            else
                hTitle.Text = modeName
                hDesc.Text = full
            end
            local key = nil
            if _G.modeButtons and _G.modeButtons[modeName] and buttonKeybinds and buttonKeybinds[_G.modeButtons[modeName]] then
                key = buttonKeybinds[_G.modeButtons[modeName]].key.Name
            end
            if key then
                hDesc.Text = hDesc.Text .. "\n\nKeybind: [" .. key .. "]"
            end
        else
            hTitle.Text = modeName
            hDesc.Text = "No description"
        end
        hScroll.CanvasSize = UDim2.new(0,0,0,hDesc.TextBounds.Y+6)
    end
    local function hideHoverDesc()
        Hover.Visible = false
    end
    _G.setHoverDesc = setHoverDesc
    _G.hideHoverDesc = hideHoverDesc

    return Main, Body
end

function buildMainTabs(Body)
    local mTabRow=mkF({Size=UDim2.new(1,-12,0,28),Position=UDim2.new(0,6,0,6),BackgroundTransparency=1},Body)
    local mTabLL=Instance.new("UIListLayout",mTabRow)
    mTabLL.FillDirection=Enum.FillDirection.Horizontal; mTabLL.Padding=UDim.new(0,4)
    mTabLL.SortOrder = Enum.SortOrder.LayoutOrder

    local mPanels={}; local mTabBtns={}
    local function setMTab(name)
        for _,n in ipairs({"Parts","NPC"}) do
            local on=n==name
            mTabBtns[n].BackgroundColor3=on and PAL.ACC or PAL.B_DEF
            mTabBtns[n].TextColor3=on and PAL.ON_TXT or PAL.T2
            if mPanels[n] then mPanels[n].Visible=on end
            if on and mPanels[n] then fadePanelIn(mPanels[n]) end
        end
    end
    for i,name in ipairs({"Parts","NPC"}) do
        local b=mkTab({Size=UDim2.new(0.5,-2,1,0),BackgroundColor3=PAL.B_DEF,Text=name,
            TextColor3=PAL.T2,TextSize=12,Font=Enum.Font.GothamBold,LayoutOrder=i},mTabRow)
        mTabBtns[name]=b; b.MouseButton1Click:Connect(function() setMTab(name) end)
    end

    local Cont=mkF({Size=UDim2.new(1,-12,1,-42),Position=UDim2.new(0,6,0,36),BackgroundTransparency=1},Body)

    return Cont, mPanels, setMTab
end


function buildPartsPanel(Cont, mPanels)
    local W=440

    local partsRoot=mkF({Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},Cont)
    mPanels["Parts"]=partsRoot


    local sTabRow=mkF({Size=UDim2.new(1,0,0,26),BackgroundColor3=PAL.SURFACE},partsRoot)
    corner(sTabRow,5)
    local sTabLL=Instance.new("UIListLayout",sTabRow)
    sTabLL.FillDirection=Enum.FillDirection.Horizontal; sTabLL.Padding=UDim.new(0,2)
    Instance.new("UIPadding",sTabRow).PaddingLeft=UDim.new(0,3)

    local sPanels={}; local sTabBtns={}
    local SUB_TABS={"Sel","Modes","Params","Tools"}
    local function setSTab(name)
        for _,n in ipairs(SUB_TABS) do
            local on=n==name
            sTabBtns[n].BackgroundColor3=on and PAL.ACC or PAL.B_DEF
            sTabBtns[n].BackgroundTransparency=0
            sTabBtns[n].TextColor3=on and PAL.ON_TXT or PAL.T2
            if sPanels[n] then sPanels[n].Visible=on end
            if on and sPanels[n] then fadePanelIn(sPanels[n]) end
        end
    end
    for i,name in ipairs(SUB_TABS) do
        local b=mkTab({Size=UDim2.new(0.25,-2,0,22),BackgroundColor3=PAL.B_DEF,
            BackgroundTransparency=0,Text=name,TextColor3=PAL.T2,
            TextSize=11,Font=Enum.Font.GothamBold,LayoutOrder=i},sTabRow)
        sTabBtns[name]=b; b.MouseButton1Click:Connect(function() setSTab(name) end)
    end

    local spCont=mkF({Size=UDim2.new(1,0,1,-30),Position=UDim2.new(0,0,0,28),BackgroundTransparency=1},partsRoot)

    local function makeSubPanel(name)
        local p=mkF({Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},spCont)
        sPanels[name]=p
        return p
    end


    local function buildSelSubPanel(spCont, sPanels)
        local selSF=Instance.new("ScrollingFrame")
        selSF.Size=UDim2.new(1,0,1,0); selSF.BackgroundTransparency=1; selSF.BorderSizePixel=0
        selSF.ScrollBarThickness=2; selSF.ScrollBarImageColor3=PAL.ACC2; selSF.Visible=false; selSF.Parent=spCont
        sPanels["Sel"]=selSF
        local selLL=Instance.new("UIListLayout",selSF); selLL.SortOrder=Enum.SortOrder.LayoutOrder; selLL.Padding=UDim.new(0,6)
        selLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            selSF.CanvasSize=UDim2.new(0,0,0,selLL.AbsoluteContentSize.Y+8)
        end)
        local selP=selSF

        local selInfo=mkL({Size=UDim2.new(1,0,0,16),Text="#0 selected · Tornado",
            TextColor3=PAL.T2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},selP)

        local clickSelBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Click-Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=2},selP,
            function() return clickSelActive end)
        clickSelBtn.MouseButton1Click:Connect(function()
            clickSelActive = not clickSelActive
            clickSelBtn.BackgroundColor3 = clickSelActive and PAL.ON or PAL.B_DEF
            clickSelBtn.TextColor3 = clickSelActive and PAL.ON_TXT or PAL.T1
            local base = "Click-Select: "..(clickSelActive and "ON" or "OFF")
            if buttonKeybinds[clickSelBtn] and buttonKeybinds[clickSelBtn].originalText then
                base = base .. " [" .. buttonKeybinds[clickSelBtn].key.Name .. "]"
            end
            clickSelBtn.Text = base
            refreshToggle(clickSelBtn)
        end)

        local selectUnweldedBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Select All",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=3},selP)
        selectUnweldedBtn.MouseButton1Click:Connect(function() selectFakeAnchored() end)

        local selectNDSRangeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Select In Range",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},selP)
        selectNDSRangeBtn.MouseButton1Click:Connect(function() selectNDSInRange(autoSelRange) end)

        local autoAllBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Auto Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=6},selP,
            function() return autoSelectAll end)
        local autoNearBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Auto Near Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},selP,
            function() return autoSelectNear end)

        local function refreshAutoSelectButtons()
            autoAllBtn.BackgroundColor3 = autoSelectAll and PAL.ON or PAL.B_DEF
            autoAllBtn.TextColor3 = autoSelectAll and PAL.ON_TXT or PAL.T1
            autoAllBtn.Text = "Auto Select: "..(autoSelectAll and "ON" or "OFF")

            autoNearBtn.BackgroundColor3 = autoSelectNear and PAL.ON or PAL.B_DEF
            autoNearBtn.TextColor3 = autoSelectNear and PAL.ON_TXT or PAL.T1
            autoNearBtn.Text = "Auto Near Select: "..(autoSelectNear and "ON" or "OFF")
        end

        autoAllBtn.MouseButton1Click:Connect(function()
            autoSelectAll = not autoSelectAll
            if autoSelectAll then
                autoSelectNear = false
                runAutoSelectScan()
            end
            refreshAutoSelectButtons()
            refreshToggle(autoAllBtn)
            refreshToggle(autoNearBtn)
        end)

        autoNearBtn.MouseButton1Click:Connect(function()
            autoSelectNear = not autoSelectNear
            if autoSelectNear then
                autoSelectAll = false
                runAutoSelectScan()
            end
            refreshAutoSelectButtons()
            refreshToggle(autoAllBtn)
            refreshToggle(autoNearBtn)
        end)

        mkSlider(selP,"Selection Range",5,300,autoSelRange,7,function(v) autoSelRange=v end)

        local clearBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_RED,
            Text="Clear Selection",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=8},selP)
        clearBtn.MouseButton1Click:Connect(function()
            autoSelectAll = false
            autoSelectNear = false
            dropSpcPart(false)
            clearSelection(false)
            refreshAutoSelectButtons()
        end)
        local boxSelBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Box Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=2},selP,
            function() return boxSelectOn end)
        _G.boxSelBtn = boxSelBtn
        boxSelBtn.MouseButton1Click:Connect(function()
            boxSelectOn = not boxSelectOn
            boxSelBtn.BackgroundColor3 = boxSelectOn and PAL.ON or PAL.B_DEF
            boxSelBtn.TextColor3 = boxSelectOn and PAL.ON_TXT or PAL.T1
            local base = "Box Select: "..(boxSelectOn and "ON" or "OFF")
            if buttonKeybinds[boxSelBtn] and buttonKeybinds[boxSelBtn].originalText then
                base = base .. " [" .. buttonKeybinds[boxSelBtn].key.Name .. "]"
            end
            boxSelBtn.Text = base
            refreshToggle(boxSelBtn)
        end)
        refreshAutoSelectButtons()

        return selInfo, clickSelBtn, clearBtn, refreshAutoSelectButtons, selectUnweldedBtn, selectNDSRangeBtn
    end


    local function buildFormationSection(selP)
        mkDiv(selP,8)
        mkSec("FORMATION", selP, 9)

        local freezeBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Formation Freeze: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=10},selP,
            function() return frozen end)
        freezeBtn.MouseButton1Click:Connect(function()
            frozen=not frozen
            if not frozen then
                for _, p in ipairs(selectedParts) do
                    pcall(beginUnfreezeHold, p)
                end
            end
            frozenTargets={}
            freezeBtn.BackgroundColor3=frozen and PAL.ON or PAL.B_DEF
            freezeBtn.TextColor3=frozen and PAL.ON_TXT or PAL.T1
            local base = "Formation Freeze: "..(frozen and "ON" or "OFF")
            if buttonKeybinds[freezeBtn] and buttonKeybinds[freezeBtn].originalText then
                base = base .. " [" .. buttonKeybinds[freezeBtn].key.Name .. "]"
            end
            freezeBtn.Text=base
            refreshToggle(freezeBtn)
        end)

        local attractBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Attract to Self (2s)",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=11},selP)
        attractBtn.MouseButton1Click:Connect(function() attracting=true; attractTimer=0 end)

        return freezeBtn
    end

    local function buildOwnershipSection(selP)
        mkDiv(selP,12)
        mkSec("OWNERSHIP", selP, 13)

        local fakeColBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Fake Collisions: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},selP,
            function() return fakeCollisions end)
        fakeColBtn.MouseButton1Click:Connect(function()
            fakeCollisions=not fakeCollisions
            deathCollideState = nil
            fakeColBtn.BackgroundColor3=fakeCollisions and PAL.ON or PAL.B_DEF
            fakeColBtn.TextColor3=fakeCollisions and PAL.ON_TXT or PAL.T1
            fakeColBtn.Text="Fake Collisions: "..(fakeCollisions and "ON" or "OFF")
            refreshAllCollisionState()
            refreshToggle(fakeColBtn)
        end)
        fakeColBtn.BackgroundColor3=fakeCollisions and PAL.ON or PAL.B_DEF
        fakeColBtn.TextColor3=fakeCollisions and PAL.ON_TXT or PAL.T1
        fakeColBtn.Text="Fake Collisions: "..(fakeCollisions and "ON" or "OFF")
        local colModeBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Partial Collisions: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},selP,
            function() return collisionMode == "partial" end)
        colModeBtn.MouseButton1Click:Connect(function()
            setCollisionMode(collisionMode=="partial" and "full" or "partial")
            local isPartial = collisionMode == "partial"
            colModeBtn.BackgroundColor3 = isPartial and PAL.ON or PAL.B_DEF
            colModeBtn.TextColor3 = isPartial and PAL.ON_TXT or PAL.T1
            colModeBtn.Text = "Partial Collisions: "..(isPartial and "ON" or "OFF")
            refreshToggle(colModeBtn)
        end)
    end

        local selInfo, clickSelBtn, clearBtn, _refreshAutoSel, selectUnweldedBtn, selectNDSRangeBtn = buildSelSubPanel(spCont, sPanels)
    local selSF = sPanels["Sel"]
    local freezeBtn = buildFormationSection(selSF)
    buildOwnershipSection(selSF)


    local function buildModesSubPanel(spCont, sPanels)
        local W=440
        local modSF=Instance.new("ScrollingFrame")
        modSF.Size=UDim2.new(1,0,1,0); modSF.BackgroundTransparency=1; modSF.BorderSizePixel=0
        modSF.ScrollBarThickness=3; modSF.ScrollBarImageColor3=PAL.ACC2
        modSF.ScrollingDirection=Enum.ScrollingDirection.Y
        modSF.CanvasSize=UDim2.new(0,0,0,0); modSF.Visible=false; modSF.Parent=spCont
        sPanels["Modes"]=modSF
        local modLL=Instance.new("UIListLayout",modSF)
        modLL.SortOrder=Enum.SortOrder.LayoutOrder; modLL.Padding=UDim.new(0,6)
        modLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            modSF.CanvasSize=UDim2.new(0,0,0,modLL.AbsoluteContentSize.Y+8)
        end)


        local mGrid=mkF({Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,LayoutOrder=2},modSF)
        local mgL=Instance.new("UIGridLayout",mGrid)
        local cellW=math.floor((W-18-9)/4)
        mgL.CellSize=UDim2.new(0,cellW,0,26); mgL.CellPadding=UDim2.new(0,3,0,3)
        mgL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            mGrid.Size=UDim2.new(1,0,0,mgL.AbsoluteContentSize.Y)
        end)

        local MODE_CAT = { -- i love cats i swear
            Tornado="red", Ring="blue", Orbit="blue", Spiral="blue", Wave="blue", Halo="green",
            Drone="blue", DroneV2="red", Shield="green", Comet="blue", Wall="green",
            Draw="blue", Beam="blue", Sphere="blue", Vortex="red", DNA="yellow", Pulse="blue", Grid="blue", Cube="green",
            Scatter="blue", Star="yellow", Pendulum="yellow", Rain="blue", Galaxy="yellow", Blackhole="red", Lemniscate="yellow", Blender="red",
            Crown="green", Swarm="blue", Minigun="red", Satellite="red",
            Seek="blue", Stickman="black", Slinky="blue", Fountain="blue", Bounce="blue", Ripple="blue", Juggle="blue", Constellation="yellow",
            Rose="yellow", OrbitSin="yellow", Liss="yellow", Swing="blue", Aura="blue", Homing="red", Railgun="red", Barrage="red",
            Sinewave="yellow", Heart="green", Wings="green", Crystal="yellow", TwinStars="yellow", Tesseract="yellow", Atom="yellow", Lightning="red",
            Sniper="red", Bridge="green", Strike="red", Boomerang="red",
            Text="green", Scythe="red", Pentagram="green",
            Chained="red", Knot="yellow", Mobius="yellow", Gyro="yellow", RoseV2="yellow", -- penisdingalingswingmode = "pink"
        }
        local CAT_COL = {
            red    = {bg=Color3.fromRGB(50,16,16), bgOn=Color3.fromRGB(148,30,30), tx=Color3.fromRGB(235,85,85)},
            blue   = {bg=Color3.fromRGB(16,24,50), bgOn=Color3.fromRGB(38,70,148), tx=Color3.fromRGB(110,145,235)},
            green  = {bg=Color3.fromRGB(16,40,16), bgOn=Color3.fromRGB(38,110,38), tx=Color3.fromRGB(110,195,110)},
            yellow = {bg=Color3.fromRGB(50,44,10), bgOn=Color3.fromRGB(168,148,30), tx=Color3.fromRGB(235,210,85)},
            black  = {bg=Color3.fromRGB(14,14,14), bgOn=Color3.fromRGB(38,38,38), tx=Color3.fromRGB(225,225,225)},
        }
        local MODE_DESC = {
            Mouse="Mouse\nTarget: Formation Target (default Mouse) - change in Modes > Formation Target\nParts cluster around Target plus offset*2.5 + up 1*scY\nControls: Move Target (move mouse by default, or set Formation Target to Player/ClosestNPC/ClickArea/Anchor/ClickedPlayer)\nLook: every part hovers near the Target point plus its own small saved offset (spread x2.5), floating 1 stud up\nMath: pos = Target + offset*2.5",
            Tornado="Tornado\nTarget: Formation Target - 6-band helical column with skirt, height = ceil(total/6)*2.2*scY\nControls: Move Target\nLook: parts split into 6 vertical bands that spin around the Target at tornadoSpeed (higher bands spin slower); each band sits 2.2 studs above the last, radius shrinks with height, bottom band flares into a wide skirt\nMath: band=(idx-1)%6 h=floor((idx-1)/6)*2.2*scY hf=h/totalH spin=band/6*2pi+t*tornadoSpeed*(1.25-hf*0.5) r=(3+sin)*rMax*(1-0.55*hf)*skirt",
            Ring="Ring\nTarget: Formation Target - single horizontal ring (0X 0Z = tight hover ball, Y sets height)\nControls: Move Target\nLook: parts spread evenly on one flat circle sized by X/Z only, circling slowly at fixed height\nMath: r=formRadius*rMax a=angle+t*1 y=max(1.5*scY,1.5) min radius 2",
            Orbit="Orbit\nTarget: Formation Target - tilted orbit with vertical bob\nControls: Move Target\nLook: parts circle the Target fast while weaving up and down in a wave (each part offset in phase), circle size from the orbitRadius slider\nMath: a=angle+t*3.2 vOff=sin(a*2+index)*4*scY pos= Target+cos(a)*orbitRadius*scX, y=4*scY+vOff",
            Spiral="Spiral\nTarget: Formation Target - flat spiral rising\nControls: Move Target\nLook: parts wind 2.5 turns from the center outward as their index grows, climbing to spiralHeight at the outer tip while the whole spiral slowly rotates\nMath: a=ratio*2.5*2pi+t*1.2 r=ratio*8*maxSc y=ratio*spiralHeight*scY",
            Wave="Wave\nTarget: Formation Target - sine wave line along X\nControls: Move Target\nLook: parts line up along X and ride two overlapping sine waves (tall vertical wave set by waveAmp, shallow depth wave), both traveling over time\nMath: x=(ratio-.5)*total*1.3*scX wY=sin(ratio*5pi+t*5)*waveAmp*scY wZ=cos(ratio*3pi+t*3)*1.2*scZ",
            Halo="Halo\nTarget: Around Player (not Formation Target) at 7*scY above root\nControls: Auto orbit around you\nLook: flat halo ring directly overhead plus a smaller tilted ring inside tumbling on 3 axes with a traveling bulge\nMath: outer flat a=angle+t*0.7 r=max(total*0.4,formRadius) y=7*scY inner 0.45x pulse r*(1+0.25sin) base tilt + flip t*0.9 roll t*0.35 yaw t*0.5",
            Drone="Drone\nTarget: Formation Target - jittery cloud + drift around Target\nControls: Move Target\nLook: parts hover in a loose buzzing cloud around the Target, each jittering on its own rhythm plus a slow shared drift\nMath: pos=Target+off*1.8*sc + drift sin/cos*2 + up 4*scY",
            DroneV2="DroneV2\nTarget: Auto nearest player/NPC within flingRange\nControls: Auto seek, Fling Force slider scales hits\nLook: parts drill inside the locked target spinning at 9e9, sawing up and down from below the feet to the top of the torso, touch detonates scaled fling into them\nMath: tri wave -4..+2 over 1.1s staggered per part, radial 1.2 ring, touch dir*2M*k+up 700k*k k=flingForce/1500",
            Shield="Shield\nTarget: Around Player - Fibonacci sphere\nControls: Auto around you\nLook: parts spread perfectly evenly over a sphere shell around you (sunflower-seed math, no clumping), shell slowly turning with a gentle bob\nMath: phi=(1+sqrt5)/2 theta=2pi*i/phi+t*0.5 cosY=-0.2+(i/total)*1.2 r=(formRadius+0.5)*scR y+=sin(t*2+i)*0.3",
            Comet="Comet\nTarget: Your movement history (trail behind you)\nControls: Move character\nLook: parts line up along the path you already walked, newest positions near you trailing off into older ones\nMath: cometHistory push if dist>0.45-0.8 histIdx = #history - ratio*trailLen",
            Wall="Wall\nTarget: In front of Player (wallDist in look dir, not Formation Target)\nControls: Face direction, wallDist/wallGap sliders pack by size via _wallSlots()\nLook: parts pack into a tight wall standing where you face (distance set by wallDist), auto-arranged in columns by each part's size with wallGap spacing\nMath: center=rp+look*wallDist*maxSc right*slot.r + up*slot.u",
            Draw="Draw\nTarget: Your drawn trail (mouse trail while holding)\nControls: Hold Mouse1 in Draw to draw path, Clear Draw Trail to reset\nLook: parts spread themselves evenly along the trail you drew, sliding along it as a chain\nMath: sampleDrawTrailPoint splits total across trails, lerp trail segment",
            Beam="Beam\nTarget: Line from Player to Formation Target - double helix\nControls: Move Target (beam follows)\nLook: parts form two intertwined spirals stretching from above you to the Target, more twists on long beams, bulging in the middle\nMath: start=rp+2*scY dir=Target-start dist=|dir| strand 0/1 turns=max(dist/6,2) aa=ratio*turns*2pi+t*6+strand*pi r=0.6+0.9*sin(ratio*pi)",
            Sphere="Sphere\nTarget: Formation Target - ball, squashed flat 0.28x vertically\nControls: Move Target\nLook: parts spread evenly over a ball around the Target (sunflower-seed math), slowly rotating; size follows formRadius per axis\nMath: yLatScale 0.28 rx=formRadius*scX ry=formRadius*scY rz=formRadius*scZ pos=Target+ sinY*cos(theta+t*0.4)*rx etc y=cosY*ry*0.28",
            Vortex="Vortex\nTarget: Formation Target - inverted tornado (narrowing upward)\nControls: Move Target\nLook: like Tornado upside-down - 6 spinning bands stacked from the Target up 14 studs, each higher band narrower, bands below the Target get clamped to it\nMath: spin=band/6*2pi -t*tornadoSpeed*2 r=(1+h/maxR*0.35)*maxR y=Target.Y+14*scY-h clamped",
            DNA="DNA\nTarget: Formation Target - double helix vertical 12*scY tall\nControls: Move Target\nLook: parts split into 2 strands winding 3 full turns around each other over 12 studs tall, slowly rotating as one\nMath: strand (idx%2) pr=pos/2 a=pr*3*2pi+t*1.6+strand*pi r=3*scR h=pr*12*scY",
            Pulse="Pulse\nTarget: Formation Target - expanding/contracting ring\nControls: Auto pulse\nLook: parts sit on one flat ring that breathes in and out (about half size each way) while slowly rotating, bobbing with the pulse\nMath: pulseR=formRadius*(1+sin(t*6)*0.45)*maxSc a=angle y=2*scY+sin(t*6)*0.5",
            Grid="Grid\nTarget: Formation Target - flat grid at Target y+4*scY\nControls: Move Target\nLook: parts snap into a flat checkerboard grid floating above the Target, spaced by part width + wallGap\nMath: cols=ceil(sqrt(total)) col=(idx%cols)-(cols-1)/2 row=floor(idx/cols) spacing=part.Size.X+wallGap",
            Cube="Cube\nTarget: Formation Target + 3*scY up, rotating cube edges\nControls: Move Target (cube follows)\nLook: parts spread evenly along the 12 edges of a wireframe cube (shared out when many parts), the whole cube slowly tumbles; half-size is formRadius (min 2), Y slider matches X/Z strength\nMath: 8 verts -1/1, 12 edges, perEdge=ceil(total/12) tEdge lerp, half=max(formRadius,2) rot Angles(t*0.45,t*0.32)",
            Scatter="Scatter\nTarget: Formation Target - expand/contract to far cloud\nControls: Auto\nLook: the whole formation slowly breathes between tight cluster and a far-flung cloud (offsets x14 wide, lifted by height), looping on a sine\nMath: scatter=(sin(t*1.5)+1)/2 far=Target+off*14*scX+up*4*scY pos=Target:Lerp(far,scatter)",
            Star="Star\nTarget: Formation Target - 2 radii alternating point/inner\nControls: Move Target\nLook: parts trace a spinning 5-point star outline, alternating outer tips and inner corners as they go around\nMath: isPoint=(idx%2==0) sAngle= spoke*2pi+ t*0.6 r=isPoint?formRadius*2:0.75",
            Pendulum="Pendulum\nTarget: Formation Target - swinging pendulum line\nControls: Auto\nLook: parts swing side to side like a pendulum row (swing width from formRadius), dipping slightly at the extremes of each swing\nMath: swing=sin(t*4+idx*0.55)*formRadius*scX dip=-(1-cos)*0.5*formRadius*scY",
            Rain="Rain\nTarget: Formation Target X/Z, Y is falling loop to ground\nControls: Move Target X/Z\nLook: parts endlessly rain down from 14 studs above the Target and loop back to the top on hitting the ground (real ground height detection)\nMath: topY=Target.Y+14*scY floorY=getGroundYAt(x,z) dropHeight=top-floor fall=(t*38+phase)%dropHeight y=top-fall",
            Galaxy="Galaxy\nTarget: Formation Target - 3-arm spiral\nControls: Move Target\nLook: parts wind along 3 spiral arms from center outward (2.5 turns total), the whole galaxy rotates and each arm gently tilts up/down\nMath: arm=(idx-1)%3 ar=posInArm/(perArm-1) spiral=arm/3*2pi+ar*2.5pi+t*0.8 r=ar*formRadius*2 tilt sin*0.35*scY",
            Blackhole="Blackhole\nTarget: Formation Target - collapse then spin out\nControls: Auto cycle 1.5s\nLook: every 1.5s parts plunge toward the Target then whip back out into a fast spin; also drags nearby loose parts inward while surging on click\nMath: cycle=t*1.5%1 pull=1-cycle*2.2 r=formRadius*pull spin=angle -t*10*(1.2-pull*0.9) h=pull*4",
            Lemniscate="Lemniscate\nTarget: Formation Target - figure-8 infinity\nControls: Move Target\nLook: parts ride a sideways figure-8 loop around the Target, size from formRadius, floating with a gentle vertical bob\nMath: phase=ratio*2pi+t*1.3 denom=1+sin(phase)^2 a=formRadius*1.6*scR x=a*cos/denom z=a*sin*cos/denom y=sin*0.55*scY",
            Blender="Blender\nTarget: Formation Target - random axis spin per offset\nControls: Move Target\nLook: parts swarm a ball around the Target, each tumbling on its own pseudo-random tilt axis at its own speed; radius from formRadius\nMath: axis=sin(off*3.14) spd=5.6+idx%7*0.25 r=formRadius*maxR pos=Target+up 3*scY + p1*cos* r + p2*sin*r",
            Crown="Crown\nTarget: Around Player (rp) - spiked ring + inner ring\nControls: Auto around you\nLook: parts form two rings above your head that slowly turn - an outer ring with every other part spiked outward, plus a smaller flat inner ring\nMath: isSpike=(idx%2==0) a=spoke*2pi+t*0.24 r=formRadius outer 2x inner 0.65 y 10*scY /7*scY",
            Swarm="Swarm\nTarget: Formation Target - wander + jitter\nControls: Move Target\nLook: parts drift in slow wandering loops around the Target with a fast angry buzz layered on top\nMath: wander sin*formRadius + jitter sin*18*0.7",
            Minigun="Minigun\nRotary barrels fire streams at Formation Target\nControls: Auto cycles barrels, MG Fire Rate shots/sec, MG Spread cone\nLook: parts arrange as spinning gun barrels on a ring that take turns spitting streams at the Target, feed lines trailing behind each muzzle\nMath: B=2-5 barrels on rotating ring, feed lines behind muzzle, 0.22s flights, touch 180k on contact",
            Satellite="Satellite\nTarget: High orbit 14*scY around player, on click fire cluster to Formation Target\nControls: Click to set satTarget (mouse)\nLook: parts idle in a high ring far above you; on click a cluster detaches, flies to the Target and detonates, then comes home\nMath: idle ring 3.5*scX high 14*scY, fire vel 4000+ burst 350000, touch 25k, TTL 3s",
            Seek="Seek\nTarget: Nearest NPC within 200 else Formation Target\nControls: Auto chase\nLook: parts pile onto the nearest NPC within 200 studs and ride it around; with no NPC nearby they cluster at the Target\nMath: getNearestNPC 200 if found -> npcRoot+offset*0.5 else Target+offset",
            Stickman="Stickman/Billy\nFull stick figure with face, walk, arms, beam, dance, crawl\nTarget: Around Player\nControls:\n Move = walk (walkPhase+=dt*spd*0.35*sgn)\n J = switch arm\n T = TPose\n P = slap 0.5s burst\n C = beam hold\n Y = wave 1.9s\n U = dance toggle\n Z = crawl toggle\n Q = face mode 0-4\n Mouse = aim arm\nLook: parts assemble into a walking stick figure (head band, torso, arms, legs by index order) that strides with your movement, aims an arm at your mouse, and can T-pose, slap, beam, wave, dance, or crawl; C stretches the aimed arm into a spinning fling lance shoulder-to-mouse that detonates on contact\nMath:\n walkPhase+=dt*spd*0.35*sgn\n u head 0.10-0.22 torso 0.22-0.37 arms 0.37-0.73 legs 0.73-1\n head/face tilt to mouse, legs sin/cos walk, face 10 parts eyes/brows/mouth, beam k=(u-lo)/(hi-lo) lerp shoulder->target spin 9e9 touch 2M+self 350k",
            Slinky="Slinky\nTarget: Mouse trail history (like Comet but spaced by formRadius)\nControls: Move mouse to leave slinkyHistory\nLook: parts string out along your recent mouse trail like a slinky, spaced by formRadius - wiggle the mouse to see it snake\nMath: step=index*(formRadius*0.35+1.5) idx=#history-step pos=history[idx]+off*0.35",
            Fountain="Fountain\nTarget: Formation Target - parabolic jets up from Target\nControls: Move Target\nLook: parts loop endlessly upward in fountain jets from the Target, arcing over and falling back, staggered so the flow never gaps\nMath: jet=(t*4.4+ratio*1.8)%1 h=sin(jet*pi)*formRadius*2.8 +1.5*scY off*formRadius*0.35",
            Bounce="Bounce\nTarget: Lerp between Formation Target and player 7*scY\nControls: Auto\nLook: parts shuttle back and forth between the Target and a point above you, each on a delayed phase so they stream both ways\nMath: phase=t*2.8+idx*0.12 alpha=phase<1?phase:2-phase pos=Target:Lerp(rp+7*scY,alpha)",
            Ripple="Ripple\nTarget: Formation Target - expanding waves per part\nControls: Move Target\nLook: each part rides its own expanding ring wave around the Target, staggered so waves ripple outward in sequence\nMath: waveR=(t*4.8-idx*0.18)%(formRadius*2.2*maxR+1)+1 a=angle+t*0.5 pos=Target+cos(a)*waveR*scX",
            Juggle="Juggle\nTarget: Formation Target - toss in circle\nControls: Move Target\nLook: parts get tossed in a circle like juggling balls, each at its own phase, spread in a ring around the Target\nMath: toss=sin(t*4.8+idx*0.75) h=(toss+1)*0.5*formRadius*2.2+2 spread 0.35*scX",
            Constellation="Constellation\nTarget: Formation Target - orbit with bob\nControls: Move Target\nLook: parts drift as a loose star-field cluster around the Target, each breathing in/out and bobbing on its own rhythm\nMath: r=formRadius*scR*(0.85+0.15*sin) bob=sin(t*3.6)*0.4 y=2.5*scY+bob",
            Rose="Rose\nTarget: Formation Target - rose k=3+(total%4)-1\nControls: Move Target\nLook: parts trace a spinning rose/petal pattern around the Target, lobes set by part count\nMath: k=3+... theta=angle+t*1.2 a=formRadius*scR*(0.75+0.25*sin) r=a*cos(k*theta) y=2*scY+sin*6*scY",
            OrbitSin="OrbitSin\nTarget: Formation Target - orbit radius pulses + Y sine\nControls: Move Target\nLook: parts circle the Target on a ring that swells and shrinks while riding up and down on a slow sine\nMath: baseR=formRadius*scR r=baseR*(0.75+0.25*sin(t*4.2+ratio*6)) y=2*scY+scY*2.5*sin(t*2.8+ratio*2pi)",
            Liss="Liss\nTarget: Formation Target - Lissajous 3D\nControls: Move Target\nLook: parts trace a 3D Lissajous knot (3:2:4 frequency weave) floating around the Target\nMath: u=ratio*2pi+t*1.1 x=sin(3*u+t*0.6) y=cos(2*u -t*0.44) z=sin(4*u+t*0.36)",
            Swing="Swing\nTarget: Formation Target but follows cursor if far\nControls: Move Target\nLook: parts swing around the Target like a pendulum that never settles, drifting toward your cursor when it wanders far\nMath: swingA=angle+sin(t*2.4)*0.35+t*0.5 swingLen=(formRadius*scR)*(0.7+0.3*sin) d>25 extra 0.18*scR lerp to Target+2*scY 0.35",
            Aura="Aura\nTarget: Around YOUR character +4*scY (falls back to Formation Target)\nControls: Follows you, no click needed - sprint to widen the shells\nLook: 4 stacked shells hug your character at different heights, neighboring shells turning opposite ways, shells widen as you move faster\nMath: layer=idx%4 r=(formRadius*1.4+3+layer*1.6)*widen widen=1+clamp(speed/28)*0.6 spin 1.1+layer*0.22",
            Homing="Homing\nTarget: Locked player (click) for 3s, else Formation Target\nControls: Click player/NPC to lock\nLook: parts coil into a spinning helix tunnel between you and the locked player, ride it downrange for 3 seconds, touch detonates 250k into them\nMath: homingTarget valid? center=launch:Lerp(target,0.94) dir=CFrame.lookAt helix L=9*scR u 0-1 rr 1.5/2.6 touch dir*250k+up 80k",
            Railgun="Railgun\nTarget: Barrel at player 11*scY aiming at Formation Target\nControls: Hold click 1s to charge (coil spin 1.4+charge^3*100) then fire to raycast hit\nLook: parts coil into a spinning barrel floating above you that aims at the Target; holding click winds the coils faster until it discharges down the aim line\nMath: origin=rp+11*scY + sin*1.6 aimDir=Target-origin coilN=total*0.45 len=(formRadius*2.2+8)*maxSc firing prog ease->hitPos",
            Barrage="Barrage\nTarget: Formation Target ground - fall from sky bombard\nControls: Move Target (bombs follow)\nLook: parts climb high into the sky above the Target, then rain straight down as bombs in staggered waves with a wobble\nMath: groundY=getGroundYAt(Target) targetY=ground+size*0.5 launchHeight 35+maxSc*8 drop (t+idx*0.12)%0.5 height=launch*(1-progress) wobble sin*pi*2",
            Sinewave="Sinewave\nTarget: Formation Target - 2D plane wave interference 3 waves\nControls: Move Target\nLook: parts form a rippling sheet where three crossing sine waves interfere, floating above the Target\nMath: x=(ratio-.5)*formRadius*4 y=(sin(x*0.5+t*4)*cos(z*0.5+t*3)+cos(x*0.3-t*3.6)*sin(z*0.4+t*4.4)+sin((x+z)*0.2+t*5))*formRadius*0.8 y=Target.Y+3*scY+y",
            Heart="Heart\nTarget: In front of Player (not Formation Target) facing your look - classic heart\nControls: Auto in front of you\nLook: parts arrange into the classic pixel-heart curve floating in front of you, turning with your look direction\nMath: origin=rp look/right/up theta=ratio*2pi+t heartScale=formRadius*0.8 x=16*sin^3 y=13*cos-5*cos2-2*cos3-cos4 localPos*heartScale*0.05+5",
            Wings="Wings\nTarget: Around Player - membrane wing pair off the back\nControls: Auto\nLook: parts form two solid wing surfaces (span stations x chord rows), tapered to the tips, swept trailing edge, flapping from shoulder hinges with tip lag\nMath: perWing grid COLSxROWS spanLen=formRadius*2.2 chord taper 1-0.62*span flap=sin(t*4-span*1.6)*0.55+0.12 shoulder 2",
            Crystal="Crystal\nTarget: Formation Target - 5 stacked fibonacci layers\nControls: Move Target\nLook: parts stack into 5 shrinking golden-ratio rings forming a crystal spire above the Target, upper rings spinning faster\nMath: layer=index%5 scale 1-layer*0.15 radius=formRadius*scale y=layer*0.8*formRadius phi golden theta=2pi*idx/phi+t*0.6*(layer+1)",
            TwinStars="TwinStars\nTarget: Formation Target - two orbiting blobs\nControls: Move Target (use Player to orbit yourself)\nLook: parts split evenly into two tight blobs circling each other, bobbing opposite\nMath: orbitR=(formRadius*1.1+4)*scR coreA=t*1.5 c1/c2=Target+cos/sin*orbitR y=4*scY+-bob odd/even split",
            Tesseract="Tesseract\nTarget: Formation Target +5*scY - 4D hypercube projection\nControls: Move Target\nLook: parts trace the edges of a rotating 4D hypercube projected into 3D above the Target, morphing as the 4th dimension turns\nMath: 16 verts 2^4 edges H=max(formRadius,5)*1.35 4D rotations a1 0.55 a2 0.34 a3 0.21 persp dist/(dist-w*H) spin 0.19/0.27",
            Atom="Atom\nTarget: Formation Target - nucleus 12% + 3 shells tilted\nControls: Move Target\nLook: a pulsing cluster forms the nucleus while the rest whirl on 3 tilted electron shells at staggered speeds\nMath: nucleus pulse sin*0.12 shells 3 tilt=shell/3*pi+sin*0.25 spin 1.5+shell*0.65 r=formRadius*1.5+shell*3.2",
            Lightning="Lightning\nTarget: Cloud 34 above player to Formation Target bolt\nControls: Click to set lightningTarget\nLook: parts gather as a crackling storm cloud high above you; on click a jagged bolt lances to the Target, then the blast ring expands\nMath: segs 8 bolt lerp cloud->target + rand*14 stagger ratio*0.08 prog=(age-stagger)/0.35 else explode ir=2+age*9",
            Sniper="Sniper\nTarget: Ring 8*scY in front of face, sequential fire to Formation Target\nControls: Click to set sniperTargetPos (hold to charge Railgun-style, but Sniper fires on click)\nLook: parts idle as a spinning crosshair + outer ring in front of your face; on click they converge onto the Target one after another, churning, then burst and fly home\nMath: ringR=5*scR ca=(idx/total)*2pi+t*2.4 slotP=center+right*cos+up*sin delay=idx/total*0.35 prog lerp slot->target 0.3 explode 1.2",
            Bridge="Bridge\nTarget: Formation Target ground - two-click bridge\nControls: Click A then B to build (arch), third click reset\nLook: click two ground points and parts lay themselves into an arched bridge between them (extra parts widen it side-by-side), third click starts over\nMath: dir=(B-A).Unit sideU=-dir.Z,0,dir.X arch=sin(u*pi)*min(D*0.08,3.5) y=g+arch+1.4 overflow fans across width",
            Strike="Strike\nTarget: Idle atom around player (10% nucleus +4 shells), on click descend to Formation Target\nControls: Click to set strikeTarget\nLook: parts idle as a mini-atom above you; on click the whole thing plunges onto the Target, drills in spinning circles, then floats home\nMath: idle atom, descend lerp 70->0 prog^2 + spin rr 2.5*(1-prog) drill circle ir 0.8+rand*0.35 return lerp",
            Boomerang="Boomerang\nTarget: Disc home 7*scY around player, on click boomerang to Formation Target +42 extra\nControls: Click to set boomerangTarget\nLook: parts idle as a flat spinning disc beside you; on click it flings out past the Target and curves home like a boomerang\nMath: u=clamp((t-start)/1.45) D=|target-origin| center=origin+dir*s*(D+min*0.48) side -D*0.16 tilt 76->14 spin 22 ringR 0.45+ring*0.32",
            Text="Text\nTarget: Vertical wall 6 studs in front of Player facing outwards (world up, not Formation Target) - 5x7 font A-Z0-9 !?+-= Uppercase, spacing 2.2/4.2 adapts to avg part size (avg*0.78+0.22), long parts auto-assigned to stick letters (I/L/T) longest run first, parts rotated Z to match stroke 0/90/45/135 (C less closed: middle rows open)\nControls: Type in top bar (live, filtered [^%-A-Z0-9 !?+=])\nLook: parts spell your typed text as a floating letter wall in front of you, longest parts auto-placed on long strokes (I/L/T), each rotated to match its stroke angle\nMath: points buildTextPointsData angle via 8-neighbor h/v/diag runLen, textScale= (0.78*avg+0.22)*(formRadius/7*0.38+0.62)*(maxSc*0.38+0.62)*1.1*0.92, pos=origin+right*X+up*(Y-midY)+jitter",
            Scythe="Scythe\nTarget: Idle arc over head (hilt low-left, middle overhead, blade diving right), swing at Formation Target\nControls: Click to swing through and back 2.4s (no cooldown) fling 2000000+700000 strike-scale\nLook: the scythe arcs over your head like a rainbow — hilt down-left, blade hooking down-right; on click it sweeps sideways through the Target and back, grinding with drill pulses\nMath: heart-frame, yaw-only frame (immune to look up/down), idle origin left H*0.6 + up 2, base yaw +90 blade-right, idle pitch-lean 52, swing roll-90 flat fan -85->+85->back ping-pong, pulses 18/1.8M+30/900k per 0.15s churn 3e6",
            Pentagram="Pentagram\nTarget: In front of Player 5*scY facing your look (not Formation Target) - 5-point star {5/2}\nControls: Move with your look\nLook: parts trace a glowing 5-pointed star polygon in front of you that turns with your look, gently pulsing\nMath: r=formRadius*1.6 verts 5 order 1,3,5,2,4 perEdge ceil(total/5) tEdge lerp pulse 1+sin*0.06 right*X+up*Y",
            Chained="Chained\nTarget: Idle 2 horizontal chain rings at hands (±right*1.45*scR+up*0.45*scY) + crown 7.8*scY above head r 0.85*scR+1.9, firing to Formation Target\nControls: Hold click to shoot both chains from hands to Target as tangled helix 3.4 turns helixR 0.42*scR, fling 200000+70000 velimmune filtered\nLook: parts idle as hand rings + a crown above your head; holding click lashes two tangled chain helixes from your hands to the Target\nMath: crown rPulse 1+sin*0.06 spike every 4th 1.4*scY, rings center hand±right*radius a=ratio*2pi+t*1.5 wobbleR 1+sin*0.05 linkLift ±0.16*scY, firing helix perp/binorm cos/sin*helixR + sag 0.6*scY",
            Knot="Knot\nTarget: Formation Target - spinning trefoil knot\nControls: Move Target\nLook: parts flow along a (2,3) torus knot tumbling above the Target\nMath: a=angle+t*0.4 x=sin+2sin2a y=cos-2cos2a z=-sin3a r=formRadius*2 lift 3*scY",
            Mobius="Mobius\nTarget: Formation Target - twisting band\nControls: Move Target\nLook: parts spread over a slowly rolling Mobius strip with a drifting half-twist above the Target\nMath: u=angle+t*0.3 v=golden hash across band tw=u/2+t*0.1 r=1+v*cos(tw) R=formRadius lift 3*scY",
            Gyro="Gyro\nTarget: Formation Target - triple gimbal\nControls: Move Target\nLook: parts split over 3 orthogonal gimbal rings flowing 0.9/-1.2/1.5 while each ring plane tumbles on its own axes\nMath: ring=index%3 flow=j/n3*2pi+t*speed planes CFrame.Angles per-ring rates R=formRadius*scR lift 3*scY",
            RoseV2="RoseV2\nTarget: Formation Target - Maurer string-art rose\nControls: Move Target\nLook: parts trace a 6-petal Maurer lace doily in 71-degree steps slowly turning above the Target\nMath: th=index*1.239+t*0.2 r=sin(6th) polar R=formRadius flat + bob lift 3*scY",
        }
        _G.MODE_CAT = MODE_CAT
        _G.CAT_COL = CAT_COL
        _G.MODE_DESC = MODE_DESC
        _G.refreshModes = nil
        local modeBtns={}
        for _,mn in ipairs(MODES) do
            local cat = MODE_CAT[mn] or "blue"
            local col = CAT_COL[cat]
            local dispName = mn == "Stickman" and "Billy" or mn
            local mb=mkTab({BackgroundColor3=col.bg,
                Text=dispName,TextColor3=col.tx,
                TextSize=10,Font=Enum.Font.Gotham},mGrid)
            modeBtns[mn]=mb
        end
        mkL({Size=UDim2.new(1,0,0,22),
            Text="red fling/impact | blue simple | yellow complex math\ngreen formation-free | black billy",
            TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0},modSF)
        local searchBox=Instance.new("TextBox")
        searchBox.Size=UDim2.new(1,0,0,24)
        searchBox.BackgroundColor3=PAL.SURFACE
        searchBox.PlaceholderText="search modes..."
        searchBox.Text=""
        searchBox.TextColor3=PAL.T1
        searchBox.PlaceholderColor3=PAL.T2
        searchBox.TextSize=11
        searchBox.Font=Enum.Font.Gotham
        searchBox.ClearTextOnFocus=false
        stampGui(searchBox); searchBox.LayoutOrder=1; searchBox.Parent=modSF; corner(searchBox,5)
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.lower(searchBox.Text or "")
            q = q:match("^%s*(.-)%s*$")
            for mn, mb in pairs(modeBtns) do
                if q == "" then
                    mb.Visible = true
                else
                    local cat = string.lower(MODE_CAT[mn] or "")
                    local disp = string.lower(mn == "Stickman" and "billy" or mn)
                    mb.Visible = (string.find(disp, q, 1, true) ~= nil)
                        or (string.find(cat, q, 1, true) ~= nil)
                end
            end
        end)

        local function refreshModes()
            for name,mb in pairs(modeBtns) do
                local on=name==activeMode
                local cat = MODE_CAT[name] or "blue"
                local col = CAT_COL[cat]
                mb.BackgroundColor3=on and col.bgOn or col.bg
                mb.TextColor3=col.tx
                if buttonKeybinds[mb] and buttonKeybinds[mb].originalText then
                    local keyName = buttonKeybinds[mb].key.Name
                    local originalText = buttonKeybinds[mb].originalText
                    mb.Text = originalText .. " [" .. keyName .. "]"
                end
            end
        end
        _G.refreshModes = refreshModes
        refreshModes()
        for name,mb in pairs(modeBtns) do
            mb.MouseButton1Click:Connect(function()
                setActiveMode(name)
            end)
            mb.MouseEnter:Connect(function() if _G.setHoverDesc then pcall(_G.setHoverDesc, name) end end)
            mb.MouseLeave:Connect(function() if _G.hideHoverDesc then pcall(_G.hideHoverDesc) end end)
        end
        _G.modeButtons = modeBtns

        mkDiv(modSF,2)
        mkSec("FORMATION TARGET", modSF, 3)

        local formTypeBtns = {}
        local function mkFormBtn(props, parent, pos)
            local o={}; for k,v in pairs(props) do o[k]=v end
            o.Size=UDim2.new(0.5,-2,1,0); o.Position=pos
            local b = mkTab(o, parent)
            return b
        end
        local formTypeRow1 = mkF({Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, LayoutOrder=4}, modSF)
        local ftb1 = mkFormBtn({BackgroundColor3=PAL.B_DEF, Text="Mouse", TextColor3=PAL.T1, TextSize=11, Font=Enum.Font.Gotham},
            formTypeRow1, UDim2.new(0,0,0,0))
        local ftb2 = mkFormBtn({BackgroundColor3=PAL.B_DEF, Text="Player", TextColor3=PAL.T1, TextSize=11, Font=Enum.Font.Gotham},
            formTypeRow1, UDim2.new(0.5,2,0,0))
        local formTypeRow2 = mkF({Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, LayoutOrder=5}, modSF)
        local ftb3 = mkFormBtn({BackgroundColor3=PAL.B_DEF, Text="Closest NPC", TextColor3=PAL.T1, TextSize=11, Font=Enum.Font.Gotham},
            formTypeRow2, UDim2.new(0,0,0,0))
        local ftb4 = mkFormBtn({BackgroundColor3=PAL.B_DEF, Text="Click Area", TextColor3=PAL.T1, TextSize=11, Font=Enum.Font.Gotham},
            formTypeRow2, UDim2.new(0.5,2,0,0))
        local formTypeRow3 = mkF({Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, LayoutOrder=6}, modSF)
        local ftb5 = mkFormBtn({BackgroundColor3=PAL.B_DEF, Text="Anchor", TextColor3=PAL.T1, TextSize=11, Font=Enum.Font.Gotham},
            formTypeRow3, UDim2.new(0,0,0,0))
        local ftb6 = mkFormBtn({BackgroundColor3=PAL.B_DEF, Text="Clicked Player", TextColor3=PAL.T1, TextSize=11, Font=Enum.Font.Gotham}, -- GONNA CHANGE THIS TO CLICKEDPENIS SOON
            formTypeRow3, UDim2.new(0.5,2,0,0))

        formTypeBtns["Mouse"] = ftb1
        formTypeBtns["Player"] = ftb2
        formTypeBtns["ClosestNPC"] = ftb3
        formTypeBtns["ClickArea"] = ftb4
        formTypeBtns["Anchor"] = ftb5
        formTypeBtns["ClickedPlayer"] = ftb6

        local function refreshFormationType()
            for ftype, btn in pairs(formTypeBtns) do
                local on = (ftype == formationType) or (ftype == "Mouse" and formationType == "Mouse")
                btn.BackgroundColor3 = on and PAL.ACC or PAL.B_DEF
                btn.TextColor3 = on and Color3.fromRGB(8,8,12) or PAL.T1
                if buttonKeybinds[btn] and buttonKeybinds[btn].originalText then
                    local keyName = buttonKeybinds[btn].key.Name
                    local originalText = buttonKeybinds[btn].originalText
                    btn.Text = originalText .. " [" .. keyName .. "]"
                end
            end
        end
        refreshFormationType()
        _G.formTypeBtns = formTypeBtns
        _G.refreshFormationType = refreshFormationType

        ftb1.MouseButton1Click:Connect(function() formationType="Mouse"; refreshFormationType() end)
        ftb2.MouseButton1Click:Connect(function() formationType="Player"; refreshFormationType() end)
        ftb3.MouseButton1Click:Connect(function() formationType="ClosestNPC"; refreshFormationType() end)
        ftb4.MouseButton1Click:Connect(function() formationType="ClickArea"; refreshFormationType() end)
        ftb5.MouseButton1Click:Connect(function() formationType="Anchor"; refreshFormationType() end)
        ftb6.MouseButton1Click:Connect(function() formationType="ClickedPlayer"; refreshFormationType() end)

        mkSec("SCALE", modSF, 6)

        mkSlider(modSF,"Form Size X",0,100,formSizeX,7,function(v) formSizeX=v end,0.1)
        mkSlider(modSF,"Form Size Y",0,100,formSizeY,8,function(v) formSizeY=v end,0.1)
        mkSlider(modSF,"Form Size Z",0,100,formSizeZ,9,function(v) formSizeZ=v end,0.1)
        mkSec("FORM ROTATION", modSF, 10)
        mkSlider(modSF,"Form Rot X",-180,180,formRotX,11,function(v) formRotX=v end,0.1)
        mkSlider(modSF,"Form Rot Y",-180,180,formRotY,12,function(v) formRotY=v end,0.1)
        mkSlider(modSF,"Form Rot Z",-180,180,formRotZ,13,function(v) formRotZ=v end,0.1)


mkSlider(modSF,"Form Offset Y",-20,20,formOffsetY,14,function(v) formOffsetY=v end)

         mkSec("DRAW", modSF, 15)
         local clearDrawBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
              Text="Clear Draw Trail",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},modSF)
          clearDrawBtn.MouseButton1Click:Connect(function() clearDrawDots() end)
          mkL({Size=UDim2.new(1,0,0,14),
               Text="Hold Mouse1 while in Draw mode to trace a path",
               TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=17},modSF)
         task.defer(function()
             if modLL.AbsoluteContentSize.Y > 0 then
                 modSF.CanvasSize=UDim2.new(0,0,0,modLL.AbsoluteContentSize.Y+8)
             end
         end)
    end

    buildModesSubPanel(spCont, sPanels)


    local function buildParamsSubPanel(spCont, sPanels)
        local parSF=Instance.new("ScrollingFrame")
        parSF.Size=UDim2.new(1,0,1,0); parSF.BackgroundTransparency=1; parSF.BorderSizePixel=0
        parSF.ScrollBarThickness=2; parSF.ScrollBarImageColor3=PAL.ACC2; parSF.Visible=false; parSF.Parent=spCont
        sPanels["Params"]=parSF
        local parLL=Instance.new("UIListLayout",parSF); parLL.SortOrder=Enum.SortOrder.LayoutOrder; parLL.Padding=UDim.new(0,6)
        parLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            parSF.CanvasSize=UDim2.new(0,0,0,parLL.AbsoluteContentSize.Y+6)
        end)

        mkSec("VELOCITY", parSF, 1)
        mkSlider(parSF,"Part Speed",   1,120,partSpeed,   2,function(v) partSpeed=v end)                                                --haha penis

        mkDiv(parSF,4)
        mkSec("MODE PARAMETERS", parSF, 5)
        mkSlider(parSF,"Form Radius",  2, 25,formRadius,  6,function(v) formRadius=v end)
        mkSlider(parSF,"Orbit Radius", 3, 30,orbitRadius, 7,function(v) orbitRadius=v end)
        mkSlider(parSF,"Spiral Height",4, 40,spiralHeight,8,function(v) spiralHeight=v end)
        mkSlider(parSF,"Wave Amp",     1, 12,waveAmp,     9,function(v) waveAmp=v end)
        mkSlider(parSF,"Tornado Speed",1, 12,tornadoSpeed,10,function(v) tornadoSpeed=v end)
        mkSlider(parSF,"Wall Distance",2, 20,wallDist,    11,function(v) wallDist=v end)
        mkSlider(parSF,"Wall Gap",     0,  3,wallGap,     12,function(v) wallGap=v end)
        mkDiv(parSF,13)
        mkSec("DRONE V2 FLING", parSF, 14)
        mkSlider(parSF,"Fling Force",50,20000,flingForce,16,function(v) flingForce=v end)
        mkSlider(parSF,"Fling Range", 5, 500,flingRange,17,function(v) flingRange=v end) --funny if u set it to 500 nglll
        mkDiv(parSF,18)
        mkSec("HOMING", parSF, 19)
        mkDiv(parSF,21)
        mkSec("RAILGUN", parSF, 22)
        mkDiv(parSF,24)
        mkSec("BARRAGE", parSF, 25)
        mkDiv(parSF,27)
        mkSec("MINIGUN", parSF, 28)
        mkSlider(parSF,"MG Fire Rate",1,20,minigunRate,29,function(v) minigunRate=v end)
        mkSlider(parSF,"MG Spread",0,12,minigunSpread,30,function(v) minigunSpread=v end,0.1)
    end

    buildParamsSubPanel(spCont, sPanels)
    noclipCam = (_G._catNoclipCam == true)
    noclipCamPatched = noclipCamPatched or {}

    function getPopperModule(timeout)
        timeout = timeout or 12
        local t0 = tick()
        while tick() - t0 < timeout do
            local pop = nil
            pcall(function()
                local ps = LP:FindFirstChild("PlayerScripts")
                if not ps then return end
                local pm = ps:FindFirstChild("PlayerModule")
                if not pm then return end
                local cm = pm:FindFirstChild("CameraModule")
                if not cm then return end
                local zc = cm:FindFirstChild("ZoomController")
                if not zc then return end
                pop = zc:FindFirstChild("Popper")
            end)
            if pop and pop.Parent then return pop end
            task.wait(0.5)
        end
        return nil
    end

    local function noclipPatchFns()
        local sc = (debug and debug.setconstant) or setconstant
        local gc = (debug and debug.getconstants) or getconstants
        local ggf = getgc or get_gc_functions or (debug and debug.getgc)
        if type(sc) ~= "function" or type(gc) ~= "function" or type(ggf) ~= "function" then
            return nil
        end
        return sc, gc, ggf
    end

    local function popperFnMatch(fn, popper)
        local okE, env = pcall(getfenv, fn)
        if okE and type(env) == "table" then
            local okS, s = pcall(function() return env.script end)
            if okS and s == popper then return true end
        end
        local okI, src = pcall(function()
            local d = debug and debug.getinfo
            local inf = d and d(fn, "s")
            return inf and inf.source
        end)
        if okI and type(src) == "string" and string.find(src, "Popper", 1, true) then return true end
        return false
    end

    function applyNoclipCam(on, silent)
        noclipCam = on and true or false
        _G._catNoclipCam = noclipCam and true or nil
        if not noclipCam then
            local sc = (debug and debug.setconstant) or setconstant
            if type(sc) == "function" then
                for _, rec in ipairs(noclipCamPatched) do
                    pcall(sc, rec.fn, rec.idx, rec.orig)
                end
            end
            noclipCamPatched = {}
            if not silent then toast("Noclip Cam: OFF") end
            return true
        end
        task.spawn(function()
            local sc, gc, ggf = noclipPatchFns()
            if not sc then
                noclipCam = false
                _G._catNoclipCam = nil
                if not silent then toast("Noclip Cam needs setconstant/getconstants/getgc") end
                pcall(refreshAllToggles)
                return
            end
            local popper = getPopperModule(12)
            if not popper then
                noclipCam = false
                _G._catNoclipCam = nil
                if not silent then toast("Noclip Cam: Popper not found") end
                pcall(refreshAllToggles)
                return
            end
            noclipCamPatched = {}
            local patchedNow = 0
            local okG, all = pcall(ggf)
            if not okG then okG, all = pcall(ggf, true) end
            if okG and type(all) == "table" then
                for _, fn in pairs(all) do
                    if type(fn) == "function" and popperFnMatch(fn, popper) then
                        local okC, consts = pcall(gc, fn)
                        if okC and type(consts) == "table" then
                            for idx, c in pairs(consts) do
                                if tonumber(c) == 0.25 then
                                    if pcall(sc, fn, idx, 0) then
                                        noclipCamPatched[#noclipCamPatched + 1] = {fn = fn, idx = idx, orig = 0.25}
                                        patchedNow += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if patchedNow > 0 then
                if not silent then toast("Noclip Cam: ON") end
            elseif silent then
            else
                noclipCam = false
                _G._catNoclipCam = nil
                toast("Noclip Cam: nothing to patch")
            end
            pcall(refreshAllToggles)
        end)
        return true
    end

    if not _G._catNoclipCamHook then
        _G._catNoclipCamHook = true
        LP.CharacterAdded:Connect(function()
            if _G._catNoclipCam ~= true then return end
            task.spawn(function()
                task.wait(2)
                if _G._catNoclipCam ~= true then return end
                if type(applyNoclipCam) == "function" then
                    applyNoclipCam(true, true)
                end
            end)
        end)
    end

    if noclipCam then
        task.spawn(function()
            task.wait(3)
            if _G._catNoclipCam == true and type(applyNoclipCam) == "function" then
                applyNoclipCam(true, true)
            end
        end)
    end

    local function buildToolsSubPanel(makeSubPanel)
        local toolP = Instance.new("ScrollingFrame")
        toolP.Size = UDim2.new(1,0,1,0)
        toolP.BackgroundTransparency = 1
        toolP.BorderSizePixel = 0
        toolP.ScrollBarThickness = 2
        toolP.ScrollBarImageColor3 = PAL.ACC2
        toolP.Visible = false
        toolP.Parent = spCont
        sPanels["Tools"] = toolP
        local toolLL=Instance.new("UIListLayout",toolP); toolLL.SortOrder=Enum.SortOrder.LayoutOrder; toolLL.Padding=UDim.new(0,6)
        toolLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            toolP.CanvasSize=UDim2.new(0,0,0,toolLL.AbsoluteContentSize.Y+8)
        end)

        mkSec("SINGLE PART CONTROL", toolP, 1)
        mkL({Size=UDim2.new(1,0,0,14),Text="enable > click any unanchored part > follows camera ray [this is old af might not keep ownership well]",
            TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=2},toolP)

        local spcBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Single Part Control: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=3},toolP,
            function() return spcActive end)
        local spcRelBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_RED,
            Text="Release Grabbed Part",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},toolP)
        spcDepthWrap = mkSlider(toolP,"SPC Depth",3,60,spcDepth,5,function(v) spcDepth=v end)
        setGreyed(spcDepthWrap, not spcActive)

        spcBtn.MouseButton1Click:Connect(function()
            spcActive=not spcActive
            if not spcActive then dropSpcPart(false) end
            refreshGreyed()
            spcBtn.BackgroundColor3=spcActive and PAL.ON or PAL.B_DEF
            spcBtn.TextColor3=spcActive and PAL.ON_TXT or PAL.T1
            local base = "Single Part Control: "..(spcActive and "ON" or "OFF")
            if buttonKeybinds[spcBtn] and buttonKeybinds[spcBtn].originalText then
                base = base .. " [" .. buttonKeybinds[spcBtn].key.Name .. "]"
            end
            spcBtn.Text=base
            refreshToggle(spcBtn)
        end)
        spcRelBtn.MouseButton1Click:Connect(function()
            dropSpcPart(true)
        end)
        reg(UserInputService.InputChanged:Connect(function(inp)
            if not spcActive then return end
            if inp.UserInputType==Enum.UserInputType.MouseWheel then
                spcYOff=spcYOff+inp.Position.Z*1.5
            end
        end))

        mkDiv(toolP,6)
        mkSec("PART LIMITS [WIP]", toolP, 7)

        local limitsBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Limits: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},toolP,
            function() return useLimits end)
        limitsBtn.MouseButton1Click:Connect(function()
            useLimits=not useLimits
            limitsBtn.BackgroundColor3=useLimits and PAL.ON or PAL.B_DEF
            limitsBtn.TextColor3=useLimits and PAL.ON_TXT or PAL.T1
            limitsBtn.Text="Limits: "..(useLimits and "ON (limit: "..partLimit..")" or "OFF")
            refreshGreyed()
            refreshToggle(limitsBtn)
        end)
        partLimitWrap = mkF({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.SURFACE,LayoutOrder=8},toolP)
        corner(partLimitWrap,5)
        mkL({Size=UDim2.new(1,-70,0,28),Position=UDim2.new(0,8,0,0),Text="Exact Count",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},partLimitWrap)
        local partLimitBox=Instance.new("TextBox")
        partLimitBox.Size=UDim2.new(0,54,0,20); partLimitBox.Position=UDim2.new(1,-62,0,4)
        partLimitBox.BackgroundColor3=PAL.B_DEF; partLimitBox.TextColor3=PAL.T1; partLimitBox.TextSize=12
        partLimitBox.Font=Enum.Font.GothamBold; partLimitBox.TextXAlignment=Enum.TextXAlignment.Center
        partLimitBox.ClearTextOnFocus=false; partLimitBox.Text=tostring(partLimit)
        stampGui(partLimitBox); partLimitBox.Parent=partLimitWrap
        partLimitBox.FocusLost:Connect(function(enterPressed)
            local n = tonumber(partLimitBox.Text:match("%d+"))
            if n then
                n = math.clamp(math.floor(n), 1, 1000)
                partLimit = n
                partLimitBox.Text = tostring(n)
                if useLimits then
                    limitsBtn.Text = "Limits: ON (limit: "..partLimit..")"
                end
            else
                partLimitBox.Text = tostring(partLimit)
            end
        end)
        setGreyed(partLimitWrap, not useLimits)

        mkDiv(toolP,9)
        mkSec("PART ACTIONS", toolP, 10)
        do
            local _,a1,a2=mkRow2(toolP,11,
                {BackgroundColor3=PAL.B_GRN,Text=" Anchor [does not replicate]",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham},
                {BackgroundColor3=PAL.B_BLU,Text=" Unanchor",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
            a1.MouseButton1Click:Connect(function()
                for _,p in ipairs(selectedParts) do pcall(function() p.Anchored=true end) end end)
            a2.MouseButton1Click:Connect(function()
                for _,p in ipairs(selectedParts) do pcall(function() p.Anchored=false end) end end)
        end
        local delBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_RED,
            Text="Delete Selected  [also does not replicate]",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=12},toolP)
        delBtn.MouseButton1Click:Connect(function()
            clearSelection(true)
        end)

        mkDiv(toolP,12.1)
        mkSec("PHYSICS & STRENGTH", toolP, 12.2)

        local physBtn
        physBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Strengthen Parts: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=12.3},toolP,
            function() return strengthenParts end)
        
        physBtn.BackgroundColor3 = strengthenParts and PAL.ON or PAL.B_DEF
        physBtn.TextColor3       = strengthenParts and PAL.ON_TXT or PAL.T1
        physBtn.Text = "Strengthen Parts: "..(strengthenParts and "ON" or "OFF")

        physBtn.MouseButton1Click:Connect(function()
            strengthenParts = not strengthenParts
            physBtn.BackgroundColor3 = strengthenParts and PAL.ON or PAL.B_DEF
            physBtn.TextColor3       = strengthenParts and PAL.ON_TXT or PAL.T1
            physBtn.Text = "Strengthen Parts: "..(strengthenParts and "ON" or "OFF")
            updatePhysPropertiesForSelected()
            refreshGreyed()
            refreshToggle(physBtn)
        end)

        densityWrap = mkSlider(toolP,"Custom Density",1,1000,strengthenDensity,12.4,function(v)
            strengthenDensity = v
            updatePhysPropertiesForSelected()
        end)
        setGreyed(densityWrap, not strengthenParts)

        mkDiv(toolP,13)
        mkSec("HIGHLIGHT", toolP, 14)

        local espBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Mode: Highlight (through walls)",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=15},toolP,
            function() return useESP end)
        local espStyleBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Style: ESP Labels",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},toolP)


        espBtn.BackgroundColor3 = useESP and PAL.ON or PAL.B_DEF
        espBtn.TextColor3 = useESP and PAL.ON_TXT or PAL.T1
        espBtn.Text = "Mode: "..(useESP and "ESP UI" or "Highlight (through walls)")
        espStyleBtn.BackgroundColor3 = useESP and (espStyle == "Label" and PAL.B_DEF or PAL.ON) or PAL.B_DEF
        espStyleBtn.TextColor3 = useESP and (espStyle == "Label" and PAL.T1 or PAL.ON_TXT) or PAL.T1
        espStyleBtn.Text = "Style: "..(espStyle == "Label" and "ESP Labels" or "ESP Box")

        espBtn.MouseButton1Click:Connect(function()
            useESP = not useESP
            espBtn.BackgroundColor3 = useESP and PAL.ON or PAL.B_DEF
            espBtn.TextColor3 = useESP and PAL.ON_TXT or PAL.T1
            espBtn.Text = "Mode: "..(useESP and "ESP UI" or "Highlight (through walls)")
            espStyleBtn.BackgroundColor3 = useESP and (espStyle == "Label" and PAL.B_DEF or PAL.ON) or PAL.B_DEF
            espStyleBtn.TextColor3 = useESP and (espStyle == "Label" and PAL.T1 or PAL.ON_TXT) or PAL.T1
            espStyleBtn.Text = "Style: "..(espStyle == "Label" and "ESP Labels" or "ESP Box")
            for _,part in ipairs(selectedParts) do removeHL(part); addHL(part) end
            refreshToggle(espBtn)
        end)

        espStyleBtn.MouseButton1Click:Connect(function()
            if not useESP then return end
            espStyle = espStyle == "Label" and "Box" or "Label"
            espStyleBtn.BackgroundColor3 = espStyle == "Label" and PAL.B_DEF or PAL.ON
            espStyleBtn.TextColor3 = espStyle == "Label" and PAL.T1 or PAL.ON_TXT
            espStyleBtn.Text = "Style: "..(espStyle == "Label" and "ESP Labels" or "ESP Box")
            for _,part in ipairs(selectedParts) do removeHL(part); addHL(part) end
        end)

        mkSec("HIGHLIGHT COLOR", toolP, 17)
        mkL({Size=UDim2.new(1,0,0,12),Text="Preset colors (fill + outline)",
            TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=18},toolP)

        local hlRow1=mkF({Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=18},toolP)
        local hlPresets = {
            {name="Teal",   fill=Color3.fromRGB(80,255,210),  outline=Color3.fromRGB(80,255,210)},
            {name="Pink",   fill=Color3.fromRGB(255,100,180),  outline=Color3.fromRGB(255,100,180)},
            {name="Red",    fill=Color3.fromRGB(255,60,60),    outline=Color3.fromRGB(255,60,60)},
            {name="Blue",   fill=Color3.fromRGB(80,160,255),   outline=Color3.fromRGB(80,160,255)},
            {name="Gold",   fill=Color3.fromRGB(255,200,50),   outline=Color3.fromRGB(255,200,50)},
            {name="White",  fill=Color3.fromRGB(235,235,235),  outline=Color3.fromRGB(235,235,235)},
            {name="Green",  fill=Color3.fromRGB(60,230,90),    outline=Color3.fromRGB(60,230,90)},
            {name="Purple", fill=Color3.fromRGB(180,80,255),   outline=Color3.fromRGB(180,80,255)},
        }
        local colW = math.floor((440-18-3*7)/4)
        local function mkColorBtn(preset, row, xpos)
            local b=mkB({Size=UDim2.new(0,colW,1,0),Position=UDim2.new(0,xpos,0,0),
                BackgroundColor3=preset.fill,Text=preset.name,
                TextColor3=Color3.fromRGB(12,12,12),TextSize=9,Font=Enum.Font.GothamBold},row)
            b.MouseButton1Click:Connect(function()
                HL.fillColor    = preset.fill
                HL.outlineColor = preset.outline
                GUI.ESP_ACCENT  = preset.fill
                refreshAllHighlights()
            end)
            return b
        end
        for i=1,4 do mkColorBtn(hlPresets[i], hlRow1, (i-1)*(colW+3)) end

        local hlRow2=mkF({Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=19},toolP)
        for i=5,8 do mkColorBtn(hlPresets[i], hlRow2, (i-5)*(colW+3)) end

        mkSec("HIGHLIGHT STYLE", toolP, 20)


        mkSlider(toolP,"Fill Opacity",0,1,1-HL.fillTransparency,21,function(v)
            HL.fillTransparency = 1 - v   
            refreshAllHighlights()
        end)


        local hlOutlineBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Outline: ON",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=22},toolP,
            function() return HL.outlineTransparency == 0 end)
        hlOutlineBtn.MouseButton1Click:Connect(function()
            HL.outlineTransparency = HL.outlineTransparency == 0 and 1 or 0
            local on = HL.outlineTransparency == 0
            hlOutlineBtn.BackgroundColor3 = on and PAL.ON or PAL.B_DEF
            hlOutlineBtn.TextColor3       = on and PAL.ON_TXT or PAL.T1
            hlOutlineBtn.Text = "Outline: "..(on and "ON" or "OFF")
            refreshAllHighlights()
            refreshToggle(hlOutlineBtn)
        end)


        local hlDepthBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.ON,
            Text="Through Walls: ON",TextColor3=PAL.ON_TXT,
            TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=23},toolP,
            function() return HL.depthMode == Enum.HighlightDepthMode.AlwaysOnTop end)
        hlDepthBtn.MouseButton1Click:Connect(function()
            local throughWalls = HL.depthMode == Enum.HighlightDepthMode.AlwaysOnTop
            HL.depthMode = throughWalls
                and Enum.HighlightDepthMode.Occluded
                or  Enum.HighlightDepthMode.AlwaysOnTop
            local on = HL.depthMode == Enum.HighlightDepthMode.AlwaysOnTop
            hlDepthBtn.BackgroundColor3 = on and PAL.ON or PAL.B_DEF
            hlDepthBtn.TextColor3       = on and PAL.ON_TXT or PAL.T1
            hlDepthBtn.Text = "Through Walls: "..(on and "ON" or "OFF")
            refreshAllHighlights()
            refreshToggle(hlDepthBtn)
        end)

        mkDiv(toolP,24)
        mkSec("CAMERA", toolP, 25)
        local noclipBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Noclip Cam: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=26},toolP,
            function() return noclipCam end)
        noclipBtn.MouseButton1Click:Connect(function()
            local want = not noclipCam
            noclipBtn.BackgroundColor3=want and PAL.ON or PAL.B_DEF
            noclipBtn.TextColor3=want and PAL.ON_TXT or PAL.T1
            noclipBtn.Text="Noclip Cam: "..(want and "ON" or "OFF")
            applyNoclipCam(want, false)
            refreshToggle(noclipBtn)
        end)
        noclipBtn.BackgroundColor3=noclipCam and PAL.ON or PAL.B_DEF
        noclipBtn.TextColor3=noclipCam and PAL.ON_TXT or PAL.T1
        noclipBtn.Text="Noclip Cam: "..(noclipCam and "ON" or "OFF")

        mkDiv(toolP,27)
        mkSec("SELECTION FILTERS", toolP, 28)
        mkL({Size=UDim2.new(1,0,0,14),Text="only parts bigger/smaller than the size below get selected",
            TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=29},toolP)
        local sizeFilterBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Size Filter: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=30},toolP,
            function() return sizeFilterOn end)
        sizeFilterBtn.MouseButton1Click:Connect(function()
            sizeFilterOn = not sizeFilterOn
            sizeFilterBtn.BackgroundColor3=sizeFilterOn and PAL.ON or PAL.B_DEF
            sizeFilterBtn.TextColor3=sizeFilterOn and PAL.ON_TXT or PAL.T1
            sizeFilterBtn.Text="Size Filter: "..(sizeFilterOn and "ON" or "OFF")
            refreshToggle(sizeFilterBtn)
        end)
        local sizeModeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Bigger Than",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=31},toolP)
        sizeModeBtn.Text = sizeFilterBigger and "Bigger Than" or "Smaller Than"
        sizeModeBtn.MouseButton1Click:Connect(function()
            sizeFilterBigger = not sizeFilterBigger
            sizeModeBtn.Text = sizeFilterBigger and "Bigger Than" or "Smaller Than"
        end)
        local sizeVecWrap=mkF({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.SURFACE,LayoutOrder=32},toolP)
        corner(sizeVecWrap,5)
        mkL({Size=UDim2.new(1,-130,0,28),Position=UDim2.new(0,8,0,0),Text="Size X,Y,Z",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1},sizeVecWrap)
        local sizeVecBox=Instance.new("TextBox")
        sizeVecBox.Size=UDim2.new(0,114,0,20); sizeVecBox.Position=UDim2.new(1,-122,0,4)
        sizeVecBox.BackgroundColor3=PAL.B_DEF; sizeVecBox.TextColor3=PAL.T1; sizeVecBox.TextSize=12
        sizeVecBox.Font=Enum.Font.GothamBold; sizeVecBox.TextXAlignment=Enum.TextXAlignment.Center
        sizeVecBox.ClearTextOnFocus=false
        sizeVecBox.Text=string.format("%g,%g,%g", sizeFilterSize.X, sizeFilterSize.Y, sizeFilterSize.Z)
        stampGui(sizeVecBox); sizeVecBox.Parent=sizeVecWrap
        sizeVecBox.FocusLost:Connect(function(enterPressed)
            local x,y,z = sizeVecBox.Text:match("^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*$")
            x,y,z = tonumber(x), tonumber(y), tonumber(z)
            if x and y and z then
                sizeFilterSize = Vector3.new(math.clamp(x,0,1000), math.clamp(y,0,1000), math.clamp(z,0,1000))
                sizeVecBox.Text = string.format("%g,%g,%g", sizeFilterSize.X, sizeFilterSize.Y, sizeFilterSize.Z)
            else
                sizeVecBox.Text = string.format("%g,%g,%g", sizeFilterSize.X, sizeFilterSize.Y, sizeFilterSize.Z)
            end
        end)

        mkDiv(toolP,33)
        mkSec("MOVEMENT", toolP, 34)
        mkL({Size=UDim2.new(1,0,0,14),Text="fly: WASD move - E/Q up/down - no fall damage while on",
            TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=35},toolP)
        local flyBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Fly: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=36},toolP,
            function() return flyOn end)
        flyBtn.MouseButton1Click:Connect(function()
            local ok = setFly(not flyOn)
            if ok ~= false then
                flyBtn.BackgroundColor3=flyOn and PAL.ON or PAL.B_DEF
                flyBtn.TextColor3=flyOn and PAL.ON_TXT or PAL.T1
                flyBtn.Text="Fly: "..(flyOn and "ON" or "OFF")
            end
            refreshToggle(flyBtn)
        end)
        local clipBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Noclip: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=37},toolP,
            function() return clipOn end)
        clipBtn.MouseButton1Click:Connect(function()
            setClip(not clipOn)
            clipBtn.BackgroundColor3=clipOn and PAL.ON or PAL.B_DEF
            clipBtn.TextColor3=clipOn and PAL.ON_TXT or PAL.T1
            clipBtn.Text="Noclip: "..(clipOn and "ON" or "OFF")
            refreshToggle(clipBtn)
        end)

        return spcBtn
    end

    local spcBtn = buildToolsSubPanel(makeSubPanel)
    setSTab("Sel")
    return selInfo, clickSelBtn, clearBtn, freezeBtn, spcBtn
end


buildNpcPanelFull = (function()
local function buildNpcSearchBox(npcControlPanel)
    local SB = {}  
    SB.box = Instance.new("TextBox")
    SB.box.Size = UDim2.new(1,0,0,24)
    SB.box.BackgroundColor3 = PAL.B_DEF
    SB.box.BorderSizePixel = 0
    SB.box.Text = ""
    SB.box.PlaceholderText = "Search NPCs..."
    SB.box.PlaceholderColor3 = PAL.T3
    SB.box.TextColor3 = PAL.T1
    SB.box.TextSize = 11
    SB.box.Font = Enum.Font.Gotham
    SB.box.ClearTextOnFocus = false
    SB.box.TextXAlignment = Enum.TextXAlignment.Left
    SB.box.LayoutOrder = -2
    stampGui(SB.box); corner(SB.box,4)
    Instance.new("UIPadding", SB.box).PaddingLeft = UDim.new(0,6)
    SB.box.Parent = npcControlPanel

    SB.results = Instance.new("ScrollingFrame")
    SB.results.Size = UDim2.new(1,0,0,0)
    SB.results.BackgroundColor3 = PAL.SURFACE
    SB.results.BorderSizePixel = 0
    SB.results.ScrollBarThickness = 3
    SB.results.ScrollBarImageColor3 = PAL.ACC2
    SB.results.CanvasSize = UDim2.new(0,0,0,0)
    SB.results.Visible = false
    SB.results.LayoutOrder = -1
    stampGui(SB.results); corner(SB.results,4)
    SB.results.Parent = npcControlPanel

    SB.ll = Instance.new("UIListLayout", SB.results)
    SB.ll.SortOrder = Enum.SortOrder.LayoutOrder
    SB.ll.Padding = UDim.new(0,2)
    SB.btns = {}

    local function clearR()
        for _,b in ipairs(SB.btns) do pcall(function() b:Destroy() end) end
        SB.btns = {}
    end
    local function collectNPCs()
        local out = {}
        local function tryAdd(o)
            if o:IsA("Model") and isNPCModel(o) then out[#out+1] = o end
        end
        for _,o in ipairs(workspace:GetChildren()) do
            tryAdd(o)
            if o:IsA("Model") or o:IsA("Folder") then
                for _,c in ipairs(o:GetChildren()) do tryAdd(c) end
            end
        end
        return out
    end
    local function runSearch(q)
        clearR()
        q = string.lower(q or "")
        if q == "" then SB.results.Visible=false; SB.results.Size=UDim2.new(1,0,0,0); return end
        local matched = {}
        for _,m in ipairs(collectNPCs()) do
            if string.find(string.lower(m.Name), q, 1, true) then matched[#matched+1] = m end
        end
        table.sort(matched, function(a,b) return string.lower(a.Name)<string.lower(b.Name) end)
        local shown = 0
        for _,m in ipairs(matched) do
            shown += 1; if shown > 40 then break end
            local rb = mkB({Size=UDim2.new(1,0,0,20),BackgroundColor3=PAL.B_DEF,
                Text="  "..m.Name,TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=shown}, SB.results)
            rb.MouseButton1Click:Connect(function()
                pcall(function() takeNPC(m) end)
                SB.box.Text = ""; runSearch("")
            end)
            SB.btns[#SB.btns+1] = rb
        end
        SB.results.Visible = shown > 0
        SB.results.Size = UDim2.new(1,0,0, math.min(shown,6)*22+2)
        SB.results.CanvasSize = UDim2.new(0,0,0, shown*22+2)
    end
    SB.box:GetPropertyChangedSignal("Text"):Connect(function() runSearch(SB.box.Text) end)
end

local function makeNpcSubScrollPanel(npcSpCont, npcSPanels, key)
    local panel = Instance.new("ScrollingFrame")
    panel.Size=UDim2.new(1,0,1,0); panel.BackgroundTransparency=1
    panel.BorderSizePixel=0; panel.ScrollBarThickness=2
    panel.ScrollBarImageColor3=PAL.ACC2; panel.Visible=false
    panel.Parent=npcSpCont
    npcSPanels[key]=panel
    local ll = Instance.new("UIListLayout", panel)
    ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,6)
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        panel.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8)
    end)
    return panel
end

local function buildNpcControlTab(npcControlPanel, npcStat)
    do
        local _,pb,rb=mkRow2(npcControlPanel,2,
            {BackgroundColor3=PAL.B_DEF,Text=" Pick NPC",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham},
            {BackgroundColor3=PAL.B_RED,Text=" Release [Tab]",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
        local npcPickActive=false
        local function setNPCPick(on)
            npcPickActive=on
            pb.BackgroundColor3=on and PAL.ON or PAL.B_DEF
            pb.TextColor3=on and PAL.ON_TXT or PAL.T1
            pb.Text=on and " Pick NPC: ON" or " Pick NPC"
            _G._npcPickActive=on
        end
        pb.MouseButton1Click:Connect(function() setNPCPick(not npcPickActive) end)
        rb.MouseButton1Click:Connect(function()
            releaseNPC(); npcStat.Text="Released"; setNPCPick(false)
        end)
        _G._setNPCPick=setNPCPick
        _G._getNPCPickActive=function() return npcPickActive end
    end

    mkL({Size=UDim2.new(1,0,0,28),
        Text="WASD → Move  ·  Space → Jump  ·  Tab → Release\nMouse → Camera  ·  Scroll → Zoom",
        TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true,LayoutOrder=3},npcControlPanel)

    mkDiv(npcControlPanel,4); mkSec("MOVEMENT",npcControlPanel,5)
    do
        local _,wb,jb=mkRow2(npcControlPanel,6,
            {BackgroundColor3=PAL.B_DEF,Text=" Walk to Mouse",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham},
            {BackgroundColor3=PAL.B_DEF,Text=" Jump",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham})
        local _,sb,wmb=mkRow2(npcControlPanel,7,
            {BackgroundColor3=PAL.B_DEF,Text=" Sit Toggle",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham},
            {BackgroundColor3=PAL.B_BLU,Text=" Warp→Mouse",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
        local wmeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_BLU,
            Text="  Warp NPC to Me",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=8},npcControlPanel)
        wb.MouseButton1Click:Connect(function()
            if not npcTarget then return end; updateMouseHit()
            local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h:MoveTo(currentMouseHit) end end)
        jb.MouseButton1Click:Connect(function()
            if not npcTarget then return end
            local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.Jump=true end end)
        sb.MouseButton1Click:Connect(function()
            if not npcTarget then return end
            local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.Sit=not h.Sit end end)
        wmb.MouseButton1Click:Connect(function()
            if not npcTarget then return end; updateMouseHit()
            local r=npcTarget:FindFirstChild("HumanoidRootPart")
            if r then pcall(function() r.CFrame=CFrame.new(currentMouseHit+Vector3.new(0,3,0)) end) end end)
        wmeBtn.MouseButton1Click:Connect(function()
            if not npcTarget then return end
            local c=LP.Character; local mr=c and c:FindFirstChild("HumanoidRootPart")
            local nr=npcTarget:FindFirstChild("HumanoidRootPart")
            if mr and nr then pcall(function() nr.CFrame=mr.CFrame*CFrame.new(3,0,0) end) end end)
    end

    mkDiv(npcControlPanel,9); mkSec("STATS",npcControlPanel,10)
    mkSlider(npcControlPanel,"Walk Speed",1,100,16,11,function(v)
        if npcTarget then local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=v end end end)
    mkSlider(npcControlPanel,"Jump Power",0,200,50,12,function(v)
        if npcTarget then local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=v end end end)

    mkDiv(npcControlPanel,13); mkSec("LIFECYCLE",npcControlPanel,14) -- jizztop was here
    do
        local _,hb,kb=mkRow2(npcControlPanel,16,
            {BackgroundColor3=PAL.B_GRN,Text=" Heal",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham},
            {BackgroundColor3=PAL.B_RED,Text=" Kill",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
        local _,rsb,db=mkRow2(npcControlPanel,17,
            {BackgroundColor3=PAL.B_YEL,Text=" Reset",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham},
            {BackgroundColor3=PAL.B_RED,Text=" Delete",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
        hb.MouseButton1Click:Connect(function()
            if not npcTarget then return end; local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.Health=h.MaxHealth end end)
        kb.MouseButton1Click:Connect(function()
            if not npcTarget then return end; local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 end end)
        rsb.MouseButton1Click:Connect(function()
            if not npcTarget then return end; local npc=npcTarget; releaseNPC()
            local h=npc:FindFirstChildOfClass("Humanoid")
            if h then h.Health=h.MaxHealth; h.WalkSpeed=16; h.JumpPower=50; h.Sit=false; h.Jump=false end
            npcStat.Text="NPC reset." end)
        db.MouseButton1Click:Connect(function()
            if not npcTarget then return end; local npc=npcTarget; releaseNPC(); npc:Destroy(); npcStat.Text="Deleted." end)
    end

    npcCtrlBtn = mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
        Text="NPC Control: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=18},npcControlPanel)
    npcCtrlBtn.MouseButton1Click:Connect(function()
        npcControlEnabled = not npcControlEnabled
        npcCtrlBtn.BackgroundColor3 = npcControlEnabled and PAL.ON or PAL.B_DEF
        npcCtrlBtn.TextColor3 = npcControlEnabled and PAL.ON_TXT or PAL.T1
        npcCtrlBtn.Text = "NPC Control: "..(npcControlEnabled and "ON" or "OFF")
        if npcControlEnabled and npcTarget then
            local h = npcTarget:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=npcControlWalkSpeed; h.JumpPower=npcControlJumpPower; h.AutoRotate=not npcControlFreezeAutoJump end
        end
    end)
    mkSlider(npcControlPanel,"Ctrl WalkSpd",1,100,npcControlWalkSpeed,19,function(v)
        npcControlWalkSpeed=v
        if npcControlEnabled and npcTarget then local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=v end end end)
    mkSlider(npcControlPanel,"Ctrl JumpPwr",0,200,npcControlJumpPower,20,function(v)
        npcControlJumpPower=v
        if npcControlEnabled and npcTarget then local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=v end end end)

    mkDiv(npcControlPanel,21)
    do  
        local fajBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Freeze AutoJump: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=22},npcControlPanel)
        fajBtn.MouseButton1Click:Connect(function()
            npcControlFreezeAutoJump=not npcControlFreezeAutoJump
            fajBtn.BackgroundColor3=npcControlFreezeAutoJump and PAL.ON or PAL.B_DEF
            fajBtn.TextColor3=npcControlFreezeAutoJump and PAL.ON_TXT or PAL.T1
            fajBtn.Text="Freeze AutoJump: "..(npcControlFreezeAutoJump and "ON" or "OFF")
        end)
        local hmBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Halt MoveTo: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=23},npcControlPanel)
        hmBtn.MouseButton1Click:Connect(function()
            npcControlHaltMoveTo=not npcControlHaltMoveTo
            hmBtn.BackgroundColor3=npcControlHaltMoveTo and PAL.ON or PAL.B_DEF
            hmBtn.TextColor3=npcControlHaltMoveTo and PAL.ON_TXT or PAL.T1
            hmBtn.Text="Halt MoveTo: "..(npcControlHaltMoveTo and "ON" or "OFF")
        end)
    end
end

local function buildNpcAurasTab(npcAurasPanel)
    local AURA_DEFS = {
        {"Kill Aura",   function() return killAura end,         function(v) killAura=v end,
         function() return killAuraRange end,   function(v) killAuraRange=v end,
         300, Color3.fromRGB(95,12,12), Color3.fromRGB(255,90,90), 1},
        {"Sit Aura",    function() return sitAura end,          function(v) sitAura=v end,
         function() return sitAuraRange end,    function(v) sitAuraRange=v end,
         300, Color3.fromRGB(14,32,88), Color3.fromRGB(100,148,255), 4},
        {"Jump Aura",   function() return jumpAura end,         function(v) jumpAura=v end,
         function() return jumpAuraRange end,   function(v) jumpAuraRange=v end,
         300, Color3.fromRGB(12,52,22), Color3.fromRGB(90,215,115), 7},
        {"Follow Aura", function() return followAura end,       function(v) followAura=v end,
         function() return followAuraRange end, function(v) followAuraRange=v end,
         300, Color3.fromRGB(65,20,90),  Color3.fromRGB(200,120,255), 10},
        {"Fear Aura",   function() return freezeAura end,       function(v) freezeAura=v end,
         function() return freezeAuraRange end, function(v) freezeAuraRange=v end,
         1000,Color3.fromRGB(32,32,95),  Color3.fromRGB(140,140,255), 13},
        {"Speed Aura",  function() return speedAuraEnabled end, function(v) speedAuraEnabled=v end,
         function() return speedAuraRange end,  function(v) speedAuraRange=v end,
         300, Color3.fromRGB(26,80,30),  Color3.fromRGB(120,255,150), 16},
        {"Spin Aura",   function() return spinAuraEnabled end,  function(v) spinAuraEnabled=v end,
         function() return spinAuraRange end,   function(v) spinAuraRange=v end,
         300, Color3.fromRGB(70,30,90),  Color3.fromRGB(210,145,255), 20},
    }
    for _,d in ipairs(AURA_DEFS) do
        local lbl,getF,setF,getR,setR,rMax,onBg,onTc,lo = d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9]
        local btn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text=lbl..": OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=lo},npcAurasPanel, getF)
        btn.MouseButton1Click:Connect(function()
            setF(not getF())
            btn.BackgroundColor3 = getF() and PAL.ON or PAL.B_DEF
            btn.TextColor3       = getF() and PAL.ON_TXT or PAL.T1
            btn.Text = lbl..": "..(getF() and "ON" or "OFF")
            refreshToggle(btn)
        end)
        mkSlider(npcAurasPanel,lbl:match("^%S+").." Range",3,rMax,getR(),lo+1,setR)

        if lbl=="Speed Aura" then
            mkSlider(npcAurasPanel,"Speed Amount",1,200,speedAuraSpeed,lo+2,function(v) speedAuraSpeed=v end)
        elseif lbl=="Spin Aura" then
            mkSlider(npcAurasPanel,"Spin Speed",1,40,spinAuraSpeed,lo+2,function(v) spinAuraSpeed=v end)
        end
    end
end

local function buildNpcGunsTab(npcToolsPanel)
    local GUN_DEFS = {
        {"Finger Gun", function() return fingerGunEnabled end, function(v) fingerGunEnabled=v end, -- gonna finger YOU that is reading
         Color3.fromRGB(60,60,140),  Color3.fromRGB(170,190,255), 1},
        {"Grab Gun",   function() return grabGunEnabled end,   function(v) grabGunEnabled=v end,
         Color3.fromRGB(110,70,20),  Color3.fromRGB(255,210,120), 2},
        {"Sit Gun",    function() return sitGunEnabled end,    function(v) sitGunEnabled=v end,
         Color3.fromRGB(20,90,110),  Color3.fromRGB(120,240,255), 3},
    }
    for _,d in ipairs(GUN_DEFS) do
        local lbl,getF,setF,onBg,onTc,lo = d[1],d[2],d[3],d[4],d[5],d[6]
        local btn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text=lbl..": OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=lo},npcToolsPanel, getF)
        btn.MouseButton1Click:Connect(function()
            setF(not getF())
            btn.BackgroundColor3 = getF() and PAL.ON or PAL.B_DEF
            btn.TextColor3       = getF() and PAL.ON_TXT or PAL.T1
            btn.Text = lbl..": "..(getF() and "ON" or "OFF")
            refreshToggle(btn)
        end)
    end

    local tkBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
        Text="Telekinesis Gun: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},npcToolsPanel,
        function() return NX.tkGun end)
    local fzBtn=mkToggleBtn({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
        Text="Freeze Gun: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=5},npcToolsPanel,
        function() return NX.freezeGun end)
    local function refreshTKFZ()
        tkBtn.BackgroundColor3=NX.tkGun and PAL.ON or PAL.B_DEF
        tkBtn.TextColor3=NX.tkGun and PAL.ON_TXT or PAL.T1
        tkBtn.Text="Telekinesis Gun: "..(NX.tkGun and "ON" or "OFF")
        fzBtn.BackgroundColor3=NX.freezeGun and PAL.ON or PAL.B_DEF
        fzBtn.TextColor3=NX.freezeGun and PAL.ON_TXT or PAL.T1
        fzBtn.Text="Freeze Gun: "..(NX.freezeGun and "ON" or "OFF")
        refreshToggle(tkBtn)
        refreshToggle(fzBtn)
    end
    tkBtn.MouseButton1Click:Connect(function() NX.tkGun=not NX.tkGun; if NX.tkGun then NX.freezeGun=false end; refreshTKFZ() end)
    fzBtn.MouseButton1Click:Connect(function() NX.freezeGun=not NX.freezeGun; if NX.freezeGun then NX.tkGun=false end; refreshTKFZ() end)
end

local function buildNpcSubTabs(npcSTabRow, npcSTabs, npcSBtns, npcSPanels)
    local npcActiveSTab = "Control"
    local function setNpcSTab(name)
        npcActiveSTab = name
        for _,t in ipairs(npcSTabs) do
            npcSBtns[t].BackgroundColor3 = (t==name) and PAL.ACC or PAL.B_DEF
            npcSBtns[t].TextColor3 = (t==name) and PAL.ON_TXT or PAL.T2
            npcSPanels[t].Visible = (t==name)
            if t == name then fadePanelIn(npcSPanels[t]) end
        end
    end
    for i,tname in ipairs(npcSTabs) do
        local b=mkTab({Size=UDim2.new(0,98,0,22),BackgroundColor3=PAL.B_DEF,BackgroundTransparency=0,
            Text=tname,TextColor3=PAL.T2,TextSize=11,Font=Enum.Font.GothamBold,LayoutOrder=i},npcSTabRow)
        npcSBtns[tname]=b
        b.MouseButton1Click:Connect(function() setNpcSTab(tname) end)
    end
    setNpcSTab("Control")
end

return function()
    local ctx = getgenv()._catalystNpcCtx
    if not ctx then return end
    buildNpcSearchBox(ctx.controlPanel)
    buildNpcControlTab(ctx.controlPanel, ctx.stat)
    buildNpcAurasTab(makeNpcSubScrollPanel(ctx.spCont, ctx.sPanels, "Auras"))
    buildNpcGunsTab(makeNpcSubScrollPanel(ctx.spCont, ctx.sPanels, "Guns"))
    buildNpcSubTabs(ctx.sTabRow, ctx.sTabs, ctx.sBtns, ctx.sPanels)
    getgenv()._catalystNpcCtx = nil
end end)()


function buildNpcPanel(Cont, mPanels)
    local npcRoot=mkF({Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},Cont)
    mPanels["NPC"]=npcRoot

    local npcSTabRow=mkF({Size=UDim2.new(1,0,0,26),BackgroundColor3=PAL.SURFACE},npcRoot)
    corner(npcSTabRow,5)
    local ll=Instance.new("UIListLayout",npcSTabRow)
    ll.FillDirection=Enum.FillDirection.Horizontal; ll.Padding=UDim.new(0,2)
    Instance.new("UIPadding",npcSTabRow).PaddingLeft=UDim.new(0,3)

    local npcSpCont=mkF({Size=UDim2.new(1,0,1,-26),Position=UDim2.new(0,0,0,26),BackgroundTransparency=1},npcRoot)

    local npcControlPanel=Instance.new("ScrollingFrame")
    npcControlPanel.Size=UDim2.new(1,0,1,0); npcControlPanel.BackgroundTransparency=1
    npcControlPanel.BorderSizePixel=0; npcControlPanel.ScrollBarThickness=2
    npcControlPanel.ScrollBarImageColor3=PAL.ACC2; npcControlPanel.Visible=true
    npcControlPanel.Parent=npcSpCont

    local cpLL=Instance.new("UIListLayout",npcControlPanel)
    cpLL.SortOrder=Enum.SortOrder.LayoutOrder; cpLL.Padding=UDim.new(0,6)
    cpLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        npcControlPanel.CanvasSize=UDim2.new(0,0,0,cpLL.AbsoluteContentSize.Y+8)
    end)

    mkDiv(npcControlPanel,1); mkSec("TARGET STATUS",npcControlPanel,2)
    local npcStat=mkL({Size=UDim2.new(1,0,0,16),Text="No NPC selected",
        TextColor3=PAL.T2,TextSize=10,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},npcControlPanel)


    local npcSPanels = {Control=npcControlPanel}
    local npcSBtns   = {}
    local npcSTabs   = {"Control","Auras","Guns"}
    getgenv()._catalystNpcCtx = {
        controlPanel = npcControlPanel,
        spCont       = npcSpCont,
        sPanels      = npcSPanels,
        sTabs        = npcSTabs,
        sBtns        = npcSBtns,
        sTabRow      = npcSTabRow,
        stat         = npcStat,
    }

    return npcStat
end

UI = (function()
    local Main, Body = buildMainFrame()
    _G.CatalystMain = Main
    local Cont, mPanels, setMTab = buildMainTabs(Body)
    local selInfo, clickSelBtn, clearBtn, freezeBtn, spcBtn = buildPartsPanel(Cont, mPanels)
    local npcStat = buildNpcPanel(Cont, mPanels)


    buildNpcPanelFull()
    setMTab("Parts")
    local keybindButtons = {}
    if clickSelBtn then table.insert(keybindButtons, clickSelBtn) end
    if clearBtn then table.insert(keybindButtons, clearBtn) end
    if freezeBtn then table.insert(keybindButtons, freezeBtn) end
    if spcBtn then table.insert(keybindButtons, spcBtn) end
    return {
        ScreenGui=ScreenGui, selInfo=selInfo, clickSelBtn=clickSelBtn,
        clearBtn=clearBtn, freezeBtn=freezeBtn, spcBtn=spcBtn, npcStat=npcStat,
        unload=unloadScript, keybindButtons=keybindButtons,
        selectUnweldedBtn = selectUnweldedBtn,
        selectNDSRangeBtn = selectNDSRangeBtn,
    }
end)()
_G.importantButtons = {
    clickSelBtn = UI.clickSelBtn,
    clearBtn = UI.clearBtn,
    freezeBtn = UI.freezeBtn,
    spcBtn = UI.spcBtn,
    selectUnweldedBtn = UI.selectUnweldedBtn,
    selectNDSRangeBtn = UI.selectNDSRangeBtn,
}

local function bindKeyToButton(button, key)
    if not button or not key then return end
    if buttonKeybinds[button] then return end
    if button:GetAttribute("NoKeybind") then return end
    if not buttonOriginalAppearance[button] then
        local cleanText = button.Text
        cleanText = string.gsub(cleanText, "%s*%[.-%]", "")
        cleanText = cleanText:match("^%s*(.-)%s*$")
        buttonOriginalAppearance[button] = {
            bg = button.BackgroundColor3,
            textColor = button.TextColor3,
            text = cleanText
        }
    end
    
    local originalText = buttonOriginalAppearance[button].text
    originalText = string.gsub(originalText, "%s*%[.-%]", "")
    originalText = originalText:match("^%s*(.-)%s*$")
    buttonOriginalAppearance[button].text = originalText
    
    local conn = UserInputService.InputBegan:Connect(function(inp, gameProcessed)
        if inp.KeyCode == key and UserInputService:GetFocusedTextBox() == nil then
            if button and button.Parent then
                local modeName = nil
                if _G.modeButtons then
                    for name, mb in pairs(_G.modeButtons) do
                        if mb == button then
                            modeName = name
                            break
                        end
                    end
                end
                local ftype = nil
                if _G.formTypeBtns then
                    for ft, btn in pairs(_G.formTypeBtns) do
                        if btn == button then ftype = ft; break end
                    end
                    if not ftype and buttonKeybinds[button] and buttonKeybinds[button].originalText then
                        local ot = string.lower(buttonKeybinds[button].originalText:gsub("%s*%[.-%]", ""):match("^%s*(.-)%s*$"))
                        for ft, _ in pairs(_G.formTypeBtns) do
                            if ot == string.lower(ft) or ot == string.lower(ft:gsub("([A-Z])", " %1"):match("^%s*(.-)%s*$")) then ftype = ft; break end
                            local ftSpaced = ft:gsub("([a-z])([A-Z])", "%1 %2")
                            if ot == string.lower(ftSpaced) then ftype = ft; break end
                        end
                    end
                    if not ftype then
                        local bt = string.lower(button.Text:gsub("%s*%[.-%]", ""):match("^%s*(.-)%s*$"))
                        for ft, _ in pairs(_G.formTypeBtns) do
                            if bt == string.lower(ft) then ftype = ft; break end
                            local ftSpaced = ft:gsub("([a-z])([A-Z])", "%1 %2")
                            if bt == string.lower(ftSpaced) then ftype = ft; break end
                        end
                    end
                end
                if modeName then
                    pcall(function()
                        setActiveMode(modeName)
                    end)
                elseif ftype then
                    pcall(function()
                        formationType = ftype
                        if _G.refreshFormationType then pcall(_G.refreshFormationType) end
                    end)
                elseif _G.importantButtons then
                    if button == _G.importantButtons.clickSelBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(string.lower(buttonKeybinds[button].originalText), "click-select")) or string.find(string.lower(button.Text), "click-select") then
                        pcall(function()
                            clickSelActive = not clickSelActive
                            button.BackgroundColor3 = clickSelActive and PAL.ON or PAL.B_DEF
                            button.TextColor3 = clickSelActive and PAL.ON_TXT or PAL.T1
                            local originalText = buttonKeybinds[button] and buttonKeybinds[button].originalText or "Click-Select: OFF"
                            button.Text = "Click-Select: "..(clickSelActive and "ON" or "OFF")
                            button.BackgroundColor3 = clickSelActive and PAL.ON or PAL.B_DEF
                            button.TextColor3 = clickSelActive and PAL.ON_TXT or PAL.T1
                            local originalText = buttonKeybinds[button] and buttonKeybinds[button].originalText or "Click-Select: OFF"
                            button.Text = "Click-Select: "..(clickSelActive and "ON" or "OFF")
                            if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                                local keyName = buttonKeybinds[button].key.Name
                                button.Text = button.Text .. " [" .. keyName .. "]"
                            end
                            refreshAllToggles()
                        end)
                      elseif button == _G.boxSelBtn then
                         pcall(function()
                             boxSelectOn = not boxSelectOn
                             button.BackgroundColor3 = boxSelectOn and PAL.ON or PAL.B_DEF
                             button.TextColor3 = boxSelectOn and PAL.ON_TXT or PAL.T1
                             button.Text = "Box Select: "..(boxSelectOn and "ON" or "OFF")
                             if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                                 button.Text = button.Text .. " [" .. buttonKeybinds[button].key.Name .. "]"
                             end
                             refreshToggle(button)
                         end)
                      elseif button == _G.importantButtons.spcBtn then
                         pcall(function()
                             spcActive = not spcActive
                             if not spcActive then dropSpcPart(false) end
                             refreshGreyed()
                             spcBtn.BackgroundColor3 = spcActive and PAL.ON or PAL.B_DEF
                             spcBtn.TextColor3 = spcActive and PAL.ON_TXT or PAL.T1
                             spcBtn.Text = "Single Part Control: "..(spcActive and "ON" or "OFF")
                             if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                                 local keyName = buttonKeybinds[button].key.Name
                              spcBtn.Text = spcBtn.Text .. " [" .. keyName .. "]"
                              end
                              refreshAllToggles()
                          end)
                    elseif button == _G.importantButtons.selectUnweldedBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(string.lower(buttonKeybinds[button].originalText), "select all") and not string.find(string.lower(buttonKeybinds[button].originalText), "range")) or string.find(string.lower(button.Text), "select all") and not string.find(string.lower(button.Text), "range") then
                          pcall(function()
                              local before=#selectedParts
                              local added=0
                              for _,obj in ipairs(workspace:GetDescendants()) do
                                  if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and not isSelected(obj) then
                                      selectPart(obj)
                                      added=added+1
                                      if added%50==0 then task.wait() end
                                  end
                              end
                          end)
                      elseif button == _G.importantButtons.selectNDSRangeBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(string.lower(buttonKeybinds[button].originalText), "in range")) or string.find(string.lower(button.Text), "in range") then
                           pcall(function()
                               local before=#selectedParts
                              local r = autoSelRange or 60
                              local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                              local myPos = root and root.Position or Vector3.zero
                              local added=0
                              for _,obj in ipairs(workspace:GetDescendants()) do
                                  if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and (obj.Position - myPos).Magnitude <= r and not isSelected(obj) then
                                      selectPart(obj)
                                      added=added+1
                                      if added%50==0 then task.wait() end
                                  end
                              end
                          end)
                     elseif button == _G.importantButtons.clearBtn then
                        pcall(function()
                             autoSelectAll = false
                             autoSelectNear = false
                             dropSpcPart(false)
                             clearSelection(false)
                             refreshAutoSelectButtons()
                        end)
                    elseif button == _G.importantButtons.freezeBtn then
                        pcall(function()
                            frozen = not frozen
                            if not frozen then
                                for _, p in ipairs(selectedParts) do
                                    pcall(beginUnfreezeHold, p)
                                end
                            end
                            frozenTargets = {}
                            button.BackgroundColor3 = frozen and PAL.ON or PAL.B_DEF
                            button.TextColor3 = frozen and PAL.ON_TXT or PAL.T1
                            local originalText = buttonKeybinds[button] and buttonKeybinds[button].originalText or "Formation Freeze: OFF"
                            button.Text = "Formation Freeze: "..(frozen and "ON" or "OFF")
                            if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                                local keyName = buttonKeybinds[button].key.Name
                                button.Text = button.Text .. " [" .. keyName .. "]"
                            end
                            refreshAllToggles()
                        end)
                    else
                        local bt = string.lower(button.Text)
                        local ot = buttonKeybinds[button] and buttonKeybinds[button].originalText and string.lower(buttonKeybinds[button].originalText) or bt
                        if string.find(ot, "select all") or string.find(bt, "select all") or string.find(ot, "in range") or string.find(bt, "in range") then
                            if string.find(ot, "range") or string.find(bt, "range") then
                                pcall(function()
                                    local before=#selectedParts
                                    local r = autoSelRange or 60
                                    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                    local myPos = root and root.Position or Vector3.zero
                                    local added=0
                                    for _,obj in ipairs(workspace:GetDescendants()) do
                                        if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and (obj.Position - myPos).Magnitude <= r and not isSelected(obj) then
                                            selectPart(obj)
                                            added=added+1
                                        end
                                    end
                                end)
                            else
                                pcall(function()
                                    local before=#selectedParts
                                    local added=0
                                    for _,obj in ipairs(workspace:GetDescendants()) do
                                        if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and not isSelected(obj) then
                                            selectPart(obj)
                                            added=added+1
                                        end
                                    end
                                end)
                            end
                        else
                            pcall(function()
                                button.MouseButton1Click:Fire()
                            end)
                            pcall(function()
                                button:Activate()
                            end)
                        end
                    end
                else
                    local bt2 = string.lower(button.Text)
                    local ot2 = buttonKeybinds[button] and buttonKeybinds[button].originalText and string.lower(buttonKeybinds[button].originalText) or bt2
                    if string.find(ot2, "select all") or string.find(bt2, "select all") or string.find(ot2, "in range") or string.find(bt2, "in range") then
                        if string.find(ot2, "range") or string.find(bt2, "range") then
                            pcall(function()
                                local r = autoSelRange or 60
                                local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                local myPos = root and root.Position or Vector3.zero
                                for _,obj in ipairs(workspace:GetDescendants()) do
                                    if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and (obj.Position - myPos).Magnitude <= r and not isSelected(obj) then
                                        selectPart(obj)
                                    end
                                end
                            end)
                        else
                            pcall(function()
                                for _,obj in ipairs(workspace:GetDescendants()) do
                                    if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and not isSelected(obj) then
                                        selectPart(obj)
                                    end
                                end
                            end)
                        end
                    else
                        pcall(function()
                            button.MouseButton1Click:Fire()
                        end)
                        pcall(function()
                            button:Activate()
                        end)
                    end
                end
            end
        end
    end)
    buttonKeybinds[button] = {conn = conn, key = key, button = button, originalText = originalText}
    button.Text = originalText .. " [" .. key.Name .. "]"
end
task.wait(0.5)

if savedKeybinds then
    for btnText, keyName in pairs(savedKeybinds) do
        local ok, key = pcall(function()
            return Enum.KeyCode[keyName]
        end)
        if ok and key then
            local function scanButtons(parent)
                if not parent then return end
                for _, child in ipairs(parent:GetDescendants()) do
                    if child:IsA("TextButton") then
                        local originalText = buttonOriginalAppearance[child] and buttonOriginalAppearance[child].text or child.Text
                        local currentOriginal = string.gsub(originalText, "%s*%[.-%]", "")
                        currentOriginal = currentOriginal:match("^%s*(.-)%s*$")
                        local cleanBtnText = string.gsub(btnText, "%s*%[.-%]", "")
                        cleanBtnText = cleanBtnText:match("^%s*(.-)%s*$")
                        if currentOriginal == cleanBtnText or currentOriginal == btnText or child.Text == btnText then
                            bindKeyToButton(child, key)
                            return true
                        end
                    end
                end
                return false
            end
            local guiParents = {}
            if UI and UI.ScreenGui then table.insert(guiParents, UI.ScreenGui) end
            if ScreenGui then table.insert(guiParents, ScreenGui) end
            if gethui then
                local ok, hui = pcall(gethui)
                if ok and hui then table.insert(guiParents, hui) end
            end
            
            local found = false
            for _, guiParent in ipairs(guiParents) do
                if scanButtons(guiParent) then
                    found = true
                    break
                end
            end
            
            if not found then
            end
        end
    end
    updateAllButtonKeybindTexts()
else
end


reg(UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if keybindSettingButton and inp.UserInputType == Enum.UserInputType.Keyboard then
        local key = inp.KeyCode
        if key == Enum.KeyCode.Escape then

            resetButtonAppearance(keybindSettingButton)
            keybindSettingButton = nil
            return
        end
        if key == Enum.KeyCode.W or key == Enum.KeyCode.A or key == Enum.KeyCode.S
        or key == Enum.KeyCode.D or key == Enum.KeyCode.Space then
            resetButtonAppearance(keybindSettingButton)
            keybindSettingButton = nil
            toast("movement keys are reserved")
            return
        end

        if buttonKeybinds[keybindSettingButton] then
            buttonKeybinds[keybindSettingButton].conn:Disconnect()
            buttonKeybinds[keybindSettingButton] = nil
        end
        bindKeyToButton(keybindSettingButton, key)
        local function fireButtonLogic(button)
            if button and _G.modeButtons then
                for name, mb in pairs(_G.modeButtons) do
                    if mb == button then
                        pcall(function()
                            setActiveMode(name)
                        end)
                        return
                    end
                end
            end
            if _G.formTypeBtns then
                for ftype, btn in pairs(_G.formTypeBtns) do
                    if btn == button then
                        pcall(function()
                            formationType = ftype
                            if _G.refreshFormationType then pcall(_G.refreshFormationType) end
                        end)
                        return
                    end
                    if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                        local ot = string.lower(buttonKeybinds[button].originalText)
                        if string.find(ot, string.lower(ftype), 1, true) then
                            pcall(function()
                                formationType = ftype
                                if _G.refreshFormationType then pcall(_G.refreshFormationType) end
                            end)
                            return
                        end
                    end
                end
                local bt = string.lower(button.Text)
                for ftype, _ in pairs(_G.formTypeBtns) do
                    if string.find(bt, string.lower(ftype), 1, true) then
                        pcall(function()
                            formationType = ftype
                            if _G.refreshFormationType then pcall(_G.refreshFormationType) end
                        end)
                        return
                    end
                end
            end
            if _G.importantButtons then
                if button == _G.importantButtons.clickSelBtn then -- IF BUTTON = IMPORTANT BUTTON THEN CLICK BUTTON ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
                    pcall(function()
                        clickSelActive = not clickSelActive
                        button.BackgroundColor3 = clickSelActive and PAL.ON or PAL.B_DEF
                        button.TextColor3 = clickSelActive and PAL.ON_TXT or PAL.T1
                        button.Text = "Click-Select: "..(clickSelActive and "ON" or "OFF")
                        if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                            button.Text = button.Text .. " [" .. keyName .. "]"
                        end
                        refreshAllToggles()
                    end)
                elseif button == _G.importantButtons.spcBtn then
                    pcall(function()
                        spcActive = not spcActive
                        if not spcActive then dropSpcPart(false) end
                        refreshGreyed()
                        spcBtn.BackgroundColor3 = spcActive and PAL.ON or PAL.B_DEF
                        spcBtn.TextColor3 = spcActive and PAL.ON_TXT or PAL.T1
                        spcBtn.Text = "Single Part Control: "..(spcActive and "ON" or "OFF")
                        if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                            spcBtn.Text = spcBtn.Text .. " [" .. buttonKeybinds[button].key.Name .. "]"
                        end
                        refreshAllToggles()
                    end)
                elseif button == _G.importantButtons.clearBtn then
                    pcall(function()
                        autoSelectAll = false
                        autoSelectNear = false
                        dropSpcPart(false)
                        clearSelection(false)
                        refreshAutoSelectButtons()
                    end)
                elseif button == _G.importantButtons.freezeBtn then
                    pcall(function()
                        frozen = not frozen
                        if not frozen then
                                for _, p in ipairs(selectedParts) do
                                pcall(beginUnfreezeHold, p)
                                end
                            end
                        frozenTargets = {}
                        button.BackgroundColor3 = frozen and PAL.ON or PAL.B_DEF
                        button.TextColor3 = frozen and PAL.ON_TXT or PAL.T1
                        button.Text = "Formation Freeze: "..(frozen and "ON" or "OFF")
                        if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                            button.Text = button.Text .. " [" .. keyName .. "]"
                        end
                        refreshAllToggles()
                    end)
                elseif button == _G.importantButtons.selectUnweldedBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(string.lower(buttonKeybinds[button].originalText), "select all") and not string.find(string.lower(buttonKeybinds[button].originalText), "range")) then
                    pcall(function() -- ppcall
                        local before=#selectedParts
                        local added=0
                        for _,obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and not isSelected(obj) then
                                selectPart(obj)
                                added=added+1
                            end
                        end
                    end)
                elseif button == _G.importantButtons.selectNDSRangeBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(string.lower(buttonKeybinds[button].originalText), "in range")) then
                    pcall(function()
                        local before=#selectedParts
                        local r = autoSelRange or 60
                        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        local myPos = root and root.Position or Vector3.zero
                        local added=0
                        for _,obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("BasePart") and not obj.Anchored and obj~=workspace.Terrain and not isPlayerPart(obj) and obj.AssemblyMass~=math.huge and (obj.Position - myPos).Magnitude <= r and not isSelected(obj) then
                                selectPart(obj)
                                added=added+1
                            end
                        end
                    end)
                end
            end
        end
        fireButtonLogic(keybindSettingButton)

        resetButtonAppearanceKeepKeybind(keybindSettingButton)
        keybindSettingButton = nil
        pcall(function() saveConfig(true) end)
    end
end))


task.wait(0.2)
reg(UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        if rotDrag.active then return end
        if UserInputService:GetFocusedTextBox() then return end
        
        local mousePos = UserInputService:GetMouseLocation() -- mouse stuffaslmda
        local guiInset = GuiService:GetGuiInset()
        

        local bestButton = nil
        local bestScore = -math.huge
        

        local guiParents = {}
        if UI and UI.ScreenGui then table.insert(guiParents, UI.ScreenGui) end
        for _, guiParent in ipairs(guiParents) do
            for _, btn in ipairs(guiParent:GetDescendants()) do
                if btn:IsA("TextButton") and btn.Visible and not btn:GetAttribute("NoKeybind") then
                    local allVisible = true
                    local parent = btn.Parent
                    while parent and parent ~= guiParent do
                        if parent:IsA("GuiObject") and not parent.Visible then
                            allVisible = false
                            break
                        end
                        parent = parent.Parent
                    end
                    
                    if allVisible then
                        local ap = btn.AbsolutePosition
                        local as = btn.AbsoluteSize
                        if as.X >= 1 and as.Y >= 1 then
                            local inBounds = mousePos.X >= ap.X and mousePos.X <= ap.X + as.X
                                and mousePos.Y - guiInset.Y >= ap.Y and mousePos.Y - guiInset.Y <= ap.Y + as.Y
                            if inBounds then -- inbound = ballistic nuclear missile
                                local area = as.X * as.Y
                                local zIndex = btn.ZIndex or 0
                                local score = (1000000 - area) + (zIndex * 10000)
                                if score > bestScore then
                                    bestScore = score
                                    bestButton = btn
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if bestButton then
            startKeybindSetting(bestButton)
        end
    end
end))


if hasFileSystem then saveConfig(true) end


reg(Mouse.Button1Up:Connect(function()
    if not NX.held then return end
    local model, root = NX.held, NX.root
    NX.held = nil; NX.root = nil
        if root and root.Parent then
            local dir = currentMouseHit - root.Position
            if dir.Magnitude > 0.001 and not isVelImmune(root) then
                pcall(function()
                    root.AssemblyLinearVelocity = dir.Unit * GRAB_TOSS_POWER + Vector3.new(0, 100, 0)
                end)
            end
        end -- secret penis
    if model then
        local h = model:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.PlatformStand = (NX.savedPS == true) end) end
    end
    NX.savedPS = nil
end))


reg(RunService.Heartbeat:Connect(function()

    if NX.held then
        local root = NX.root
        if not root or not root.Parent then
            NX.held = nil; NX.root = nil
        else
            local target = currentMouseHit + Vector3.new(0, NX.FLOAT_Y, 0)
            if not isVelImmune(root) then
                pcall(function()
                    root.AssemblyLinearVelocity = (target - root.Position) * NX.DRAG
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
    end

    for model, _ in pairs(NX.frozen) do
        if not model.Parent then
            NX.frozen[model] = nil
        else
            local root = model:FindFirstChild("HumanoidRootPart")
            local h = model:FindFirstChildOfClass("Humanoid") -- human = oid hahahaha again
            if root then pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end) end
            if h then pcall(function()
                h.WalkSpeed = 0; h.JumpPower = 0
                pcall(function() h.JumpHeight = 0 end)
                h.PlatformStand = true
            end) end
        end
    end
end))
local function ensureBoxOverlay()
    if boxOverlay and boxOverlay.Parent then return boxOverlay end
    local f = Instance.new("Frame")
    f.Name = "CatalystBoxSelect"
    f.BackgroundColor3 = Color3.fromRGB(215, 75, 80)
    f.BackgroundTransparency = 0.85
    f.BorderSizePixel = 0
    f.Visible = false
    f.ZIndex = 300
    local st = Instance.new("UIStroke", f)
    st.Color = Color3.fromRGB(235, 105, 110)
    st.Thickness = 1
    st.Transparency = 0.1
    f.Parent = TextScreenGui
    boxOverlay = f
    return f
end
local function updateBoxOverlay()
    local f = ensureBoxOverlay()
    local x1 = math.min(boxStart.X, boxCur.X)
    local y1 = math.min(boxStart.Y, boxCur.Y)
    local x2 = math.max(boxStart.X, boxCur.X)
    local y2 = math.max(boxStart.Y, boxCur.Y)
    f.Position = UDim2.new(0, x1, 0, y1)
    f.Size = UDim2.new(0, math.max(x2 - x1, 1), 0, math.max(y2 - y1, 1))
    f.Visible = true
end
local function hideBoxOverlay()
    if boxOverlay then pcall(function() boxOverlay.Visible = false end) end
end
local function boxOverUI(mp)
    local main = _G.CatalystMain
    if main and main.Parent then
        local ok, ap, as = pcall(function() return main.AbsolutePosition, main.AbsoluteSize end)
        if ok and ap and as then
            if mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y then
                return true
            end
        end
    end
    local ok, objs = pcall(function()
        return UserInputService:GetGuiObjectsAtPosition(mp.X, mp.Y)
    end)
    if not ok or not objs then return false end
    local roots = {}
    if UI and UI.ScreenGui then table.insert(roots, UI.ScreenGui) end
    if ScreenGui then table.insert(roots, ScreenGui) end
    if TextScreenGui then table.insert(roots, TextScreenGui) end
    if type(gethui) == "function" then
        local okH, hui = pcall(gethui)
        if okH and hui then table.insert(roots, hui) end
    end
    for _, o in ipairs(objs) do
        for _, root in ipairs(roots) do
            if o == root or o:IsDescendantOf(root) then
                return true
            end
        end
    end
    return false
end
local function boxSinglePick(mp)
    local inset = GuiService:GetGuiInset()
    local ray = Camera:ScreenPointToRay(mp.X, mp.Y - inset.Y)
    local target = getClosestSelectablePartFromRay(ray.Origin, ray.Direction, 5000, 7)
    if not target then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local excl = { LP.Character }
        params.FilterDescendantsInstances = excl
        for _ = 1, 10 do
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
            if not hit or not hit.Instance then break end
            local inst = hit.Instance
            if inst == workspace.Terrain then break end
            if inst:IsA("BasePart") and not inst.Anchored
                and not isPlayerPart(inst) and inst.AssemblyMass ~= math.huge then
                target = inst
                break
            end
            table.insert(excl, inst)
            params.FilterDescendantsInstances = excl
        end
    end
    if not target then return end
    local root = resolveAssemblyRoot(target)
    if isSelected(root) then
        deselectPart(root)
    else
        local mate = findSelectedAssemblyMate(target)
        if mate then
            deselectPart(mate)
        else
            selectPart(target)
        end
    end
end
local function boxEvaluate(a, b)
    local x1 = math.min(a.X, b.X)
    local x2 = math.max(a.X, b.X)
    local y1 = math.min(a.Y, b.Y)
    local y2 = math.max(a.Y, b.Y)
    local function inBox(pos3d)
        local v2, onScreen = Camera:WorldToViewportPoint(pos3d)
        if not onScreen then return false end
        return v2.X >= x1 and v2.X <= x2 and v2.Y >= y1 and v2.Y <= y2
    end
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if count >= 2000 then break end
        if obj:IsA("BasePart") and not obj.Anchored and obj ~= workspace.Terrain
            and not isPlayerPart(obj) and obj.AssemblyMass ~= math.huge then
            if inBox(obj.Position) then
                local root = resolveAssemblyRoot(obj)
                if isSelected(root) then
                    deselectPart(root)
                else
                    selectPart(obj)
                end
                count += 1
            end
        end
    end
end
reg(UserInputService.InputChanged:Connect(function(input, gpe)
    if not boxDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        boxCur = UserInputService:GetMouseLocation()
        updateBoxOverlay()
    end
end))
reg(Mouse.Button1Up:Connect(function()
    if not boxDragging then return end
    boxDragging = false
    hideBoxOverlay()
    if (boxCur - boxStart).Magnitude < 8 then
        boxSinglePick(boxCur)
    else
        boxEvaluate(boxStart, boxCur)
    end
end))
reg(Mouse.Button1Down:Connect(function()
    if rotDrag.active then
        endRotDrag()
        return
    end
    if boxOverUI(UserInputService:GetMouseLocation()) then return end
    if boxSelectOn then
        if UserInputService:GetFocusedTextBox() then return end
        local mp = UserInputService:GetMouseLocation()
        if boxOverUI(mp) then return end
        boxDragging = true
        boxStart = mp
        boxCur = mp
        updateBoxOverlay()
        return
    end
    local clickTarget = Mouse.Target
    if not clickTarget or not clickTarget:IsA("BasePart") or isLocalPlayerPart(clickTarget) or isVelImmune(clickTarget) then
        local mPos = UserInputService:GetMouseLocation()
        local inset2 = GuiService:GetGuiInset()
        local ray2 = Camera:ScreenPointToRay(mPos.X, mPos.Y - inset2.Y)
        local paramsC = RaycastParams.new()
        paramsC.FilterType = Enum.RaycastFilterType.Exclude
        paramsC.FilterDescendantsInstances = {LP.Character}
        paramsC.IgnoreWater = true
        local hit2 = workspace:Raycast(ray2.Origin, ray2.Direction * 5000, paramsC)
        if hit2 and hit2.Instance and hit2.Instance:IsA("BasePart") and not isLocalPlayerPart(hit2.Instance) and not isVelImmune(hit2.Instance) then
            clickTarget = hit2.Instance
        else
            if clickSelActive then
                local sel = getClosestSelectablePartFromRay(ray2.Origin, ray2.Direction, 5000, 7)
                if sel then
                    clickTarget = sel
                else
                    local unsel = getClosestUnselectedPartFromRay(ray2.Origin, ray2.Direction, 5000, 7)
                    if unsel then clickTarget = unsel end
                end
            else
                local unsel = getClosestUnselectedPartFromRay(ray2.Origin, ray2.Direction, 5000, 7)
                if unsel then
                    clickTarget = unsel
                elseif frozenTargets then
                    local sel = getClosestSelectablePartFromRay(ray2.Origin, ray2.Direction, 5000, 7)
                    if sel then clickTarget = sel end
                end
            end
        end
    end
    if activeMode=="Draw" then 
        isDrawing=true
        currentTrail = {}
        table.insert(drawTrails, currentTrail)
    end

    if activeMode=="Homing" then -- i hate homing so much someone fucking kill it 
        local newTarget = nil
        local lockFrom = clickTarget
        if lockFrom and (isSelected(lockFrom) or findSelectedAssemblyMate(lockFrom)) then
            lockFrom = nil
            local mPosH = UserInputService:GetMouseLocation()
            local insetH = GuiService:GetGuiInset()
            local rayH = Camera:ScreenPointToRay(mPosH.X, mPosH.Y - insetH.Y)
            local behind = getClosestUnselectedPartFromRay(rayH.Origin, rayH.Direction, 5000, 7)
            if behind then lockFrom = behind end
        end
        if lockFrom then
            local model = lockFrom:FindFirstAncestorOfClass("Model")
            if model and model ~= LP.Character then
                local plr = Players:GetPlayerFromCharacter(model)
                if plr and plr.Character then
                    newTarget = plr.Character:FindFirstChild("HumanoidRootPart")
                elseif model:FindFirstChildOfClass("Humanoid") then
                    newTarget = model:FindFirstChild("HumanoidRootPart")
                end
            end
            if not newTarget then
                local best = 8
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character then
                        local tr = plr.Character:FindFirstChild("HumanoidRootPart")
                        if tr then
                            local d = (tr.Position - lockFrom.Position).Magnitude
                            if d < best then best = d; newTarget = tr end
                        end
                    end
                end
            end
        end
        if newTarget then
            homingTarget = newTarget
            homingFireTime = tick()
            homingEndTime = tick() + 3
            homingDone = {}
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            homingLaunchPos = (myRoot and myRoot.Position + Vector3.new(0, 4, 0)) or newTarget.Position
            homingTouchConns = homingTouchConns or {}
            for _, p in ipairs(selectedParts) do
                if p and p.Parent then
                    if homingTouchConns[p] then pcall(function() homingTouchConns[p]:Disconnect() end) end
                    homingTouchConns[p] = p.Touched:Connect(function(hit)
                        if activeMode ~= "Homing" then return end
                        if not hit or not hit.Parent or hit.Anchored then return end
                        if isVelImmune(hit) then return end
                        if hit == workspace.Terrain or hit == p then return end
                        if isSelected(hit) then return end
                        if isLocalPlayerPart(hit) then return end
                        if not (homingTarget and homingTarget.Parent and tick() < homingEndTime) then return end
                        pcall(function()
                            local dir = hit.Position - p.Position
                            dir = dir.Magnitude > 0.001 and dir.Unit or Vector3.new(0, 1, 0)
                            hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*250000 + Vector3.new(0, 80000, 0)
                            hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*100000, (math.random()-0.5)*100000, (math.random()-0.5)*100000)
                        end)
                        pcall(function()
                            local pd = hit.Position - p.Position
                            pd = pd.Magnitude > 0.001 and pd.Unit or Vector3.new(0, 1, 0)
                            p.AssemblyLinearVelocity = pd * 350000 + Vector3.new(0, 120000, 0)
                            p.AssemblyAngularVelocity = Vector3.new(
                                (math.random() - 0.5) * 9e9,
                                (math.random() - 0.5) * 9e9,
                                (math.random() - 0.5) * 9e9)
                        end)
                        homingDone[p] = true
                    end)
                end
            end
        end
    end

    if activeMode=="Railgun" then
        if not railgunCharging and not railgunFired then -- boom
            railgunCharging = true
            railgunChargeStart = tick()
        end
    end

    if fingerGunEnabled or sitGunEnabled or grabGunEnabled then -- im gonna fjnger you reading
        local function raycastNpc()

            local origin = Camera.CFrame.Position
            local dir = (currentMouseHit - origin)
            if not dir or dir.Magnitude < 0.001 then return nil end
            dir = dir.Unit * FINGER_GUN_RANGE

            local hit = workspace:Raycast(origin, dir, _npcToolsRayParams)
            if not hit or not hit.Position or not hit.Instance then return nil end

            local inst = hit.Instance
            local model = inst:FindFirstAncestorOfClass("Model")
            if not model then model = inst.Parent end

            if model and isNPCModel(model) then
                return model, model:FindFirstChild("HumanoidRootPart")
            end
            return nil
        end


        if fingerGunEnabled then
            local model = raycastNpc()
            if model then
                local npcModel, _ = model, nil
                local h = (npcModel and npcModel:FindFirstChildOfClass("Humanoid")) or nil
                if h then pcall(function() h.Health = 0 end) end
            end
        end

        if sitGunEnabled then
            local model = raycastNpc()
            if model then
                local npcModel, _ = model, nil
                local h = (npcModel and npcModel:FindFirstChildOfClass("Humanoid")) or nil
                if h then pcall(function() h.Sit = true end) end
            end
        end


        if grabGunEnabled then
            if not grabbedRoot or not grabbedNPC or not grabbedRoot.Parent then
                local res = raycastNpc()
                if res then
                    grabbedNPC  = res
                    grabbedRoot = grabbedNPC and grabbedNPC:FindFirstChild("HumanoidRootPart") or nil
                    if grabbedRoot then

                        grabbedRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    end
                end
            else

                local targetPos = currentMouseHit
                local dir = targetPos - grabbedRoot.Position
                if dir.Magnitude > 0.001 and not isVelImmune(grabbedRoot) then
                    pcall(function()
                        grabbedRoot.AssemblyLinearVelocity = dir.Unit * GRAB_TOSS_POWER + Vector3.new(0, 100, 0)
                        if grabbedNPC then
                         local h=grabbedNPC:FindFirstChildOfClass("Humanoid"); if h then h.Sit=true end end
                    end)
                end
                grabbedNPC = nil
                grabbedRoot = nil
            end
        end
    end

    if NX.tkGun then
        local origin = Camera.CFrame.Position
        local dir = (currentMouseHit - origin)
        if dir.Magnitude > 0.001 then
            local hit = workspace:Raycast(origin, dir.Unit * FINGER_GUN_RANGE, _npcToolsRayParams)
            if hit and hit.Instance then
                local model = hit.Instance:FindFirstAncestorOfClass("Model") or hit.Instance.Parent
                if model and isNPCModel(model) then
                    NX.held     = model
                    NX.root = model:FindFirstChild("HumanoidRootPart")
                    local h = model:FindFirstChildOfClass("Humanoid")
                    if h then NX.savedPS = h.PlatformStand; pcall(function() h.PlatformStand = true end) end
                    if NX.root then pcall(function() NX.root.AssemblyLinearVelocity = Vector3.zero end) end
                end
            end
        end
        return
    end


    if NX.freezeGun then -- freeiz
        local origin = Camera.CFrame.Position
        local dir = (currentMouseHit - origin)
        if dir.Magnitude > 0.001 then
            local hit = workspace:Raycast(origin, dir.Unit * FINGER_GUN_RANGE, _npcToolsRayParams)
            if hit and hit.Instance then
                local model = hit.Instance:FindFirstAncestorOfClass("Model") or hit.Instance.Parent
                if model and isNPCModel(model) then
                    local h = model:FindFirstChildOfClass("Humanoid")
                    if NX.frozen[model] then

                        local s = NX.frozen[model]
                        if h then pcall(function()
                            h.WalkSpeed = s.ws; h.JumpPower = s.jp
                            pcall(function() h.JumpHeight = s.jh end)
                            h.AutoRotate = s.ar; h.PlatformStand = s.ps
                        end) end
                        NX.frozen[model] = nil
                    elseif h then

                        local jh = 0; pcall(function() jh = h.JumpHeight end)
                        NX.frozen[model] = {ws=h.WalkSpeed, jp=h.JumpPower, jh=jh, ar=h.AutoRotate, ps=h.PlatformStand}
                        pcall(function()
                            h.WalkSpeed = 0; h.JumpPower = 0
                            pcall(function() h.JumpHeight = 0 end)
                            h.AutoRotate = false; h.PlatformStand = true
                        end)
                    end
                end
            end
        end
        return
    end

    if formationType == "ClickArea" and not clickSelActive then
        clickFormPos = currentMouseHit
        return
    end

    if formationType == "Anchor" and not clickSelActive then
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        anchorPos = root and root.Position or currentMouseHit
        return
    end

    if formationType == "ClickedPlayer" then
        local clickTarget = Mouse.Target
        local foundChar, foundPlr = nil, nil
        if clickTarget then
            local model = clickTarget:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChildOfClass("Humanoid") and model ~= LP.Character then
                foundChar = model
                foundPlr = Players:GetPlayerFromCharacter(model)
            else
                local nearestDist = 5 + 1
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character then
                        local root = plr.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local dist = (root.Position - clickTarget.Position).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                foundChar = plr.Character
                                foundPlr = plr
                            end
                        end
                    end
                end
            end
        end
        if foundChar then
            clickedPlayer = foundChar
            clickedPlayerRef = foundPlr
            local root = foundChar:FindFirstChild("HumanoidRootPart")
            if root then lastClickedPos = root.Position end
        end
    end

    if activeMode=="Stickman" then
        stickGrabActive = true
    end

    if activeMode=="Blackhole" then
        if #selectedParts > 0 then
            local c = currentMouseHit + Vector3.new(0, 4*math.max(0, formSizeY)/3, 0)
            impactBurst(c, 26, 180000)
            impactBurst(c, 16, 130000)
            blackholeSurgeUntil = tick() + 1.0
        end
        return
    end

    if activeMode=="Sniper" then
        if #selectedParts > 0 then
            sniperTargetPos = currentMouseHit
            sniperFireTime = tick()
            sniperBoomStage = 0
            sniperCaught = false
            sniperDampUntil = tick() + SNIPER_CYCLE + 0.8
            for _, p in ipairs(selectedParts) do
                if p and p.Parent and not p.Anchored then
                    pcall(sethiddenproperty, p, "NetworkIsSleeping", false)
                    pcall(reclaimAssembly, p)
                    local _fr = getAssemblyRoot(p)
                    if _fr ~= p then pcall(reclaimAssembly, _fr) end
                    pcall(function()
                        p.AssemblyLinearVelocity = netHoldVelocity()
                        p.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            end
            for _, p in ipairs(selectedParts) do
                if sniperTouchConns[p] then pcall(function() sniperTouchConns[p]:Disconnect() end) end
                local myChar = LP.Character
                sniperTouchConns[p] = p.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if isVelImmune(hit) then return end
                    if hit == workspace.Terrain or isSelected(hit) then return end
                    if isLocalPlayerPart(hit) then return end
                    pcall(function()
                        local d2 = hit.Position - p.Position
                        d2 = d2.Magnitude > 0.001 and d2.Unit or Vector3.new(0, 1, 0)
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity
                            + d2 * 550000 + Vector3.new(0, 180000, 0)
                        hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new(
                            (math.random() - 0.5) * 750000,
                            (math.random() - 0.5) * 750000 + 350000,
                            (math.random() - 0.5) * 750000)
                    end)
                    pcall(function()
                        local pd = hit.Position - p.Position
                        pd = pd.Magnitude > 0.001 and pd.Unit or Vector3.new(0, 1, 0)
                        p.AssemblyLinearVelocity = pd * 350000 + Vector3.new(0, 120000, 0)
                        p.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 9e9,
                            (math.random() - 0.5) * 9e9,
                            (math.random() - 0.5) * 9e9)
                    end)
                end)
            end
        end
        return
    end

    if activeMode=="Boomerang" and #selectedParts > 0 then
        if not boomerangActive then
            local rootBm = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            boomerangOrigin = (rootBm and rootBm.Position or currentMouseHit) + Vector3.new(0, 4, 0)
            boomerangTarget = currentMouseHit
            boomerangStart = tick()
            boomerangActive = true
            for _, p in ipairs(selectedParts) do
                if boomerangConns[p] then pcall(function() boomerangConns[p]:Disconnect() end) end
                boomerangConns[p] = p.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if isVelImmune(hit) then return end
                    if hit == workspace.Terrain or isSelected(hit) then return end
                    if isSelected(hit) then return end
                    if isLocalPlayerPart(hit) then return end
                    pcall(function()
                        local d3 = hit.Position - p.Position
                        d3 = d3.Magnitude > 0.001 and d3.Unit or Vector3.new(0, 1, 0)
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + d3 * 80000 + Vector3.new(0, 20000, 0)
                        hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*20000, (math.random()-0.5)*20000, (math.random()-0.5)*20000)
                    end)
                end)
            end
        end
        return
    end

    if activeMode=="Bridge" then
        if #selectedParts == 0 then return end
        local g = getGroundYAt(currentMouseHit.X, currentMouseHit.Z, currentMouseHit.Y + 5)
        local clickPos = g and Vector3.new(currentMouseHit.X, g, currentMouseHit.Z) or currentMouseHit

        if not bridgeA then
            bridgeA = clickPos
        elseif not bridgeB then
            bridgeB = clickPos
                local D = (bridgeB - bridgeA).Magnitude
                if D > 1 then
                    local dirU = (bridgeB - bridgeA).Unit
                    local sideU = Vector3.new(-dirU.Z, 0, dirU.X)
                    if sideU.Magnitude < 0.01 then sideU = Vector3.new(1, 0, 0) else sideU = sideU.Unit end
                    local n = #selectedParts
                    local maxSX, maxSY, maxSZ = 0, 0, 0
                    for _, p in ipairs(selectedParts) do
                        local okS, s = pcall(function() return p.Size end)
                        if okS and s then
                            if s.X > maxSX then maxSX = s.X end
                            if s.Y > maxSY then maxSY = s.Y end
                            if s.Z > maxSZ then maxSZ = s.Z end
                        end
                    end
                    local longPitch = maxSZ + 1.2
                    local widePitch = maxSX + 1.2
                    local perLayer = math.max(1, math.floor(D / math.max(longPitch, 0.01)) + 1)
                    for i, p in ipairs(selectedParts) do
                        local li = i - 1
                        local layer = math.floor(li / perLayer)
                        local slot = li % perLayer
                        local u = perLayer > 1 and slot / (perLayer - 1) or 0.5
                        local arch = math.sin(u * math.pi) * math.min(D * 0.08, 3.5)
                        local sideStep = 0
                        if layer > 0 then
                            local k = math.ceil(layer / 2)
                            sideStep = (layer % 2 == 1) and k or -k
                        end
                        local pos = bridgeA:Lerp(bridgeB, u) + Vector3.new(0, arch + 1.4, 0) + sideU * (sideStep * widePitch)
                    pcall(function()
                        if not partPhysProperties[p] then partPhysProperties[p] = {CustomPhysicalProperties = p.CustomPhysicalProperties} end
                        local curD = nil
                        pcall(function() curD = p.CustomPhysicalProperties.Density end)
                        if curD and math.abs(curD - 0.001) > 0.0005 and not strengthenParts then
                            p.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0, 0, 0, 0)
                        elseif strengthenParts then
                            p.CustomPhysicalProperties = PhysicalProperties.new(strengthenDensity, 0.3, 0.5)
                        end
                        if type(netHoldVelocity) == "function" then
                            p.AssemblyLinearVelocity = netHoldVelocity()
                        end
                        p.AssemblyAngularVelocity = Vector3.zero
                        if fakeCollisions then
                            p.CanCollide = false
                        end
                        pcall(linkNoCollide, p)
                        pcall(reclaimAssembly, p)
                        local _br = getAssemblyRoot(p)
                        if _br ~= p then pcall(reclaimAssembly, _br) end
                    end)
                    if not partTargets[p] then partTargets[p] = {} end
                    partTargets[p].position  = pos
                    partTargets[p].rotation  = CFrame.lookAt(pos, pos + dirU)
                    syncAlignTarget(p, partTargets[p])
                    bridgeSlots[p] = pos
                end
            else
                bridgeB = nil
            end
        else
            bridgeA = clickPos
            bridgeB = nil
        end
        return
    end

    if activeMode=="Strike" and #selectedParts > 0 then
        strikeTarget = currentMouseHit
        strikeState = "descend"
        strikeStart = tick()
        strikePulse = 0
        strikeDampUntil = tick() + STRIKE_DESCEND + 0.15 + STRIKE_DRILL + STRIKE_RETURN + 1.2
strikeTouchConns = strikeTouchConns or {}
dv2TouchConns = dv2TouchConns or {}
        for _, p in ipairs(selectedParts) do
            if strikeTouchConns[p] then pcall(function() strikeTouchConns[p]:Disconnect() end) end
            strikeTouchConns[p] = p.Touched:Connect(function(hit)
                if not hit or not hit.Parent or hit.Anchored then return end
                if isVelImmune(hit) then return end
                if hit == workspace.Terrain or hit == p then return end
                if isSelected(hit) then return end
                if isLocalPlayerPart(hit) then return end
                if strikeState ~= "descend" and strikeState ~= "drill" then return end
                pcall(function()
                    local dir = hit.Position - p.Position
                    dir = dir.Magnitude > 0.001 and dir.Unit or Vector3.new(0, 1, 0)
                    hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*2000000 + Vector3.new(0, 700000, 0) + Vector3.new((math.random()-0.5)*120000, 0, (math.random()-0.5)*120000)
                    hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*300000, (math.random()-0.5)*300000, (math.random()-0.5)*300000)
                    p.AssemblyAngularVelocity = Vector3.new((math.random()-0.5)*150000, (math.random()-0.5)*150000, (math.random()-0.5)*150000)
                end)
            end)
        end
        return
    end

    if activeMode=="Lightning" and #selectedParts > 0 then
        local now = tick()
        lightningTarget = currentMouseHit
        lightningFireTime = now
        lightningBoomed = false
        local charL = LP.Character
        local rootL = charL and charL:FindFirstChild("HumanoidRootPart")
        local fromPos = (rootL and rootL.Position or lightningTarget) + Vector3.new(0, 34, 0)
        local pts = {}
        local segs = 8
        for i = 0, segs do
            local pt = fromPos:Lerp(lightningTarget, i / segs)
            if i > 0 and i < segs then
                pt = pt + Vector3.new(
                    (math.random() - 0.5) * 14,
                    (math.random() - 0.5) * 5,
                    (math.random() - 0.5) * 14)
            end
            pts[#pts + 1] = pt
        end
        pts[#pts + 1] = lightningTarget
        lightningBolt = pts
        for _, part in ipairs(selectedParts) do
            lightningFired[part] = now
            pcall(function() part.AssemblyAngularVelocity = Vector3.zero end)
            if not lightningTouchConns[part] then
                lightningTouchConns[part] = part.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if isVelImmune(hit) then return end
                    if hit == workspace.Terrain or hit == part then return end
                    if isSelected(hit) then return end
                    if isLocalPlayerPart(hit) then return end
                    pcall(function()
                        local burstDir = hit.Position - part.Position
                        burstDir = burstDir.Magnitude > 0.001 and burstDir.Unit or Vector3.new(0, 1, 0)
                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 9e10,
                            (math.random() - 0.5) * 9e10,
                            (math.random() - 0.5) * 9e10
                        )
                        part.AssemblyLinearVelocity = burstDir * 40000
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + burstDir * 60000
                    end)
                end)
            end
        end
        return
    end

    if activeMode=="Satellite" and #selectedParts > 0 then
        local now = tick()
        satTarget = currentMouseHit
        for i = 1, #selectedParts do
            if selectedParts[i] then
                local part = selectedParts[i]
                satFired[part] = now

 
                pcall(function()
                    part.AssemblyAngularVelocity = Vector3.new(
                        (math.random() - 0.5) * 20000,
                        (math.random() - 0.5) * 20000,
                        (math.random() - 0.5) * 20000
                    )

                    local toTarget = satTarget - part.Position
                    local toDir = toTarget.Magnitude > 0.01 and toTarget.Unit or Vector3.new(0, 1, 0)
                    part.AssemblyLinearVelocity = toDir * 4000 + Vector3.new(
                        (math.random() - 0.5) * 800,
                        (math.random() - 0.5) * 800 + 400,
                        (math.random() - 0.5) * 800
                    )
                end)


                if satTouchConns[part] then
                    pcall(function() satTouchConns[part]:Disconnect() end)
                end
                satTouchConns[part] = part.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if isVelImmune(hit) then return end
                    if hit == workspace.Terrain then return end
                    if isSelected(hit) then return end
                   if isLocalPlayerPart(hit) then return end
                    if isLocalPlayerPart(hit) then return end
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 9e10,
                            (math.random() - 0.5) * 9e10,
                            (math.random() - 0.5) * 9e10
                        )
                        local hitVel = hit.AssemblyLinearVelocity
                        local bdiff = hit.Position - part.Position
                        local burstDir = bdiff.Magnitude > 0.001 and bdiff.Unit or Vector3.new(0, 1, 0)
                        part.AssemblyLinearVelocity = burstDir * 350000 + Vector3.new(
                            (math.random() - 0.5) * 8000,
                            (math.random() - 0.5) * 8000,
                            (math.random() - 0.5) * 8000
                        )
                        if hitVel then
                            hit.AssemblyLinearVelocity = hitVel + burstDir * 25000
                        end
                    end)
                end)
            end
        end
        return
    end

    if activeMode=="Scythe" and #selectedParts>0 then
        scytheState = "swing"
        scytheStart = tick()
        scythePulse = 0
        scytheSwingPos = currentMouseHit + Vector3.new(0,0.4,0)
        scytheCenter = scytheSwingPos
        for _, p in ipairs(selectedParts) do
            if scytheConns[p] then pcall(function() scytheConns[p]:Disconnect() end) end
                scytheConns[p] = p.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if isVelImmune(hit) then return end
                    if hit == workspace.Terrain or hit == p then return end
                    if isSelected(hit) then return end
                   if isLocalPlayerPart(hit) then return end
                    if isLocalPlayerPart(hit) then return end
                    if scytheState ~= "swing" then return end
                pcall(function()
                    local dir = hit.Position - p.Position
                    dir = dir.Magnitude>0.001 and dir.Unit or Vector3.new(0,1,0) -- boom boom 
                    hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*2000000 + Vector3.new(0, 700000, 0) + Vector3.new((math.random()-0.5)*120000,0,(math.random()-0.5)*120000)
                    hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*300000, (math.random()-0.5)*300000, (math.random()-0.5)*300000)
                    p.AssemblyLinearVelocity = dir * 350000 + Vector3.new(0, 80000, 0)
                    p.AssemblyAngularVelocity = Vector3.new((math.random()-0.5)*9e9, (math.random()-0.5)*9e9, (math.random()-0.5)*9e9)
                end)
            end)
        end
        return
    end

    if activeMode=="Chained" and #selectedParts>0 then
        chainedTarget = currentMouseHit
        chainedActive = true
        chainedFireTime = tick()
        chainedFired = {}
        local crownN = math.max(4, math.floor(#selectedParts*0.22))
        if crownN > #selectedParts then crownN = #selectedParts end
        for i, p in ipairs(selectedParts) do
            if i <= (#selectedParts - crownN) then
                chainedFired[p] = true
                if chainedConns[p] then pcall(function() chainedConns[p]:Disconnect() end) end
                chainedConns[p] = p.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if isVelImmune(hit) then return end
                    if hit == workspace.Terrain or hit == p then return end
                    if isSelected(hit) then return end
                   if isLocalPlayerPart(hit) then return end
                    if isLocalPlayerPart(hit) then return end
                    if not chainedActive then return end
                    pcall(function()
                        local dir = hit.Position - p.Position
                        dir = dir.Magnitude>0.001 and dir.Unit or Vector3.new(0,1,0)
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*200000 + Vector3.new(0, 70000, 0) + Vector3.new((math.random()-0.5)*10000,0,(math.random()-0.5)*10000)
                        hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*120000, (math.random()-0.5)*120000, (math.random()-0.5)*120000)
                        p.AssemblyAngularVelocity = Vector3.new((math.random()-0.5)*20000, (math.random()-0.5)*20000, (math.random()-0.5)*20000)
                    end)
                end)
            end
        end
        return
    end
-- i pooped in a peanut butter jar and put it back in the target aisle and watched a grandma buy it
    if spcActive then
        if clickTarget and clickTarget:IsA("BasePart") and not clickTarget.Anchored then
            local char=LP.Character
            if not (char and clickTarget:IsDescendantOf(char)) then
                grabSpcPart(clickTarget); return
            end
        end
        return
    end

    if clickSelActive and clickTarget then
        local actual = resolveAssemblyRoot(clickTarget)
        local mate = nil
        if not isSelected(actual) then
            mate = findSelectedAssemblyMate(clickTarget)
        end
        if mate then
            deselectPart(mate)
        elseif isSelected(actual) then
            local mPos = UserInputService:GetMouseLocation()
            local inset3 = GuiService:GetGuiInset()
            local ray3 = Camera:ScreenPointToRay(mPos.X, mPos.Y - inset3.Y)
            local closestSel = getClosestSelectablePartFromRay(ray3.Origin, ray3.Direction, 5000, 7)
            if closestSel and isSelected(closestSel) then
                actual = closestSel
            end
            deselectPart(actual)
        else
            local mPos2 = UserInputService:GetMouseLocation()
            local inset4 = GuiService:GetGuiInset()
            local ray4 = Camera:ScreenPointToRay(mPos2.X, mPos2.Y - inset4.Y)
            local closestUnsel = getClosestUnselectedPartFromRay(ray4.Origin, ray4.Direction, 5000, 7)
            if closestUnsel then
                selectPart(closestUnsel)
            else
                selectPart(actual)
            end
        end
    end

    if _G._getNPCPickActive and _G._getNPCPickActive() and clickTarget then
        local model=clickTarget
        while model and not model:FindFirstChildOfClass("Humanoid") do
            model=model.Parent; if model==workspace then model=nil; break end
        end
        if model and model~=LP.Character then
            local ok=takeNPC(model)
            if ok then 
                UI.npcStat.Text="Controlling: "..model.Name
                _G._setNPCPick(false)
                npcCtrlBtn.BackgroundColor3=PAL.ON
                npcCtrlBtn.TextColor3=PAL.ON_TXT
                npcCtrlBtn.Text="NPC Control: ON"
            end
        end
    end
end))

reg(Mouse.Button1Up:Connect(function()
    isDrawing=false
    currentTrail = nil
    if activeMode=="Stickman" then
        stickGrabActive = false
    end
end))

reg(Mouse.Button1Up:Connect(function()
    if activeMode=="Railgun" and railgunCharging then
        railgunCharging = false
        railgunChargeStart = 0
    end
end))

reg(Mouse.Button1Up:Connect(function()
    if activeMode=="Chained" and chainedActive then
        chainedActive = false
        chainedTarget = Vector3.zero
        for p,c in pairs(chainedConns) do pcall(function() c:Disconnect() end) end
        chainedConns = {}
        chainedFired = {}
    end
end))


reg(UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if UserInputService:GetFocusedTextBox() then return end

    if inp.KeyCode==Enum.KeyCode.Tab and npcTarget then
        releaseNPC(); UI.npcStat.Text="Released via Tab"
    end
    if inp.KeyCode==Enum.KeyCode.Escape and spcActive then
        dropSpcPart(true); spcActive=false
        refreshGreyed()
        UI.spcBtn.BackgroundColor3=PAL.B_DEF; UI.spcBtn.TextColor3=PAL.T1
        UI.spcBtn.Text="Single Part Control: OFF"
    end
    if inp.KeyCode==Enum.KeyCode.J and activeMode=="Stickman" then
        stickArmIsLeft = not stickArmIsLeft
    end
    if inp.KeyCode==Enum.KeyCode.T and activeMode=="Stickman" then
        stickTPose = not stickTPose
    end
    if inp.KeyCode==Enum.KeyCode.P and activeMode=="Stickman" then
        for _, conn in pairs(stickSlapConns) do
            pcall(function() conn:Disconnect() end)
        end
        stickSlapConns = {}
        stickSlapUntil = tick() + 0.5
        for _, p in ipairs(selectedParts) do
            stickSlapConns[p] = p.Touched:Connect(function(hit)
                if not hit or not hit.Parent or hit.Anchored then return end
                if isVelImmune(hit) then return end
                if hit == workspace.Terrain or hit == p then return end
                if isSelected(hit) then return end
                if isLocalPlayerPart(hit) then return end
                pcall(function()
                    p.AssemblyAngularVelocity = Vector3.new(
                        (math.random() - 0.5) * 9e10,
                        (math.random() - 0.5) * 9e10,
                        (math.random() - 0.5) * 9e10
                    )
                end)
            end)
        end
    end
    if inp.KeyCode==Enum.KeyCode.C and activeMode=="Stickman" then
        stickBeamActive = not stickBeamActive
        if stickBeamActive then
            if #selectedParts == 0 then stickBeamActive = false; return end
            for _, conn in pairs(stickBeamConns) do
                pcall(function() conn:Disconnect() end)
            end
            stickBeamConns = {}
            local total = #selectedParts
            for idx, p in ipairs(selectedParts) do
                local u = idx / total
                local isArm = u >= 0.37 and u < 0.73
                local armMatch = stickArmIsLeft and u < 0.55 or (not stickArmIsLeft and u >= 0.55)
                if isArm and armMatch then
                    stickBeamConns[p] = p.Touched:Connect(function(hit)
                        if not hit or not hit.Parent or hit.Anchored then return end
                        if isVelImmune(hit) then return end
                        if hit == workspace.Terrain or hit == p then return end
                        if isSelected(hit) then return end
                        if isLocalPlayerPart(hit) then return end
                        pcall(function()
                            p.AssemblyAngularVelocity = Vector3.new(
                                (math.random() - 0.5) * 9e12,
                                (math.random() - 0.5) * 9e12,
                                (math.random() - 0.5) * 9e12
                            )
                            local ddiff = hit.Position - p.Position
                            local dir = ddiff.Magnitude > 0.001 and ddiff.Unit or Vector3.new(0, 1, 0)
                            local flingPower = 2000000
                            hit.AssemblyLinearVelocity = dir * flingPower + Vector3.new(0, 600000, 0)
                            p.AssemblyLinearVelocity = dir * 350000 + Vector3.new(0, 120000, 0)
                            for i = 1, 5 do
                                task.delay(i * 0.02, function()
                                    if hit and hit.Parent then
                                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir * (flingPower * 0.5) + Vector3.new(0, 200000, 0)
                                    end
                                end)
                            end
                        end)
                    end)
                end
            end
        else
            for _, conn in pairs(stickBeamConns) do
                pcall(function() conn:Disconnect() end)
            end
            stickBeamConns = {}
        end
    end
    if inp.KeyCode==Enum.KeyCode.M and activeMode=="Stickman" then
        do end
    end
    if inp.KeyCode==Enum.KeyCode.Y and activeMode=="Stickman" then
        stickWaveUntil = tick() + 1.9
    end
    if inp.KeyCode==Enum.KeyCode.U and activeMode=="Stickman" then
        stickDanceActive = not stickDanceActive
        if stickDanceActive then stickCrawlActive = false end
    end
    if inp.KeyCode==Enum.KeyCode.Z and activeMode=="Stickman" then
        stickCrawlActive = not stickCrawlActive
        if stickCrawlActive then stickDanceActive = false end
    end
    if inp.KeyCode==Enum.KeyCode.Q and activeMode=="Stickman" then
        stickFaceMode = (stickFaceMode + 1) % 5
    end
end))

reg(UserInputService.InputBegan:Connect(function(inp,gpe)
    if inp.KeyCode==Enum.KeyCode.F then
        if UserInputService:GetFocusedTextBox() then return end

        local mousePos = UserInputService:GetMouseLocation()
        local inset = GuiService:GetGuiInset()
        local x = mousePos.X
        local y = mousePos.Y - inset.Y

        local ray = Camera:ScreenPointToRay(x, y)
        local target = getClosestSelectablePartFromRay(ray.Origin, ray.Direction, 5000, 8)
        if not target then
            local paramsF = RaycastParams.new()
            paramsF.FilterType = Enum.RaycastFilterType.Exclude
            paramsF.FilterDescendantsInstances = {LP.Character}
            paramsF.IgnoreWater = true
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000, paramsF)
            if hit and hit.Instance and hit.Instance:IsA("BasePart") and isSelected(hit.Instance) then
                target = hit.Instance
            end
        end
        if not target or not target:IsA("BasePart") then return end
        if not isSelected(target) then return end
        do
            local _ = target
        end
        if true then
            local hit = {Instance = target, Position = target.Position}
            if hit and hit.Instance and hit.Instance:IsA("BasePart") then
                local target2 = hit.Instance
                if not isSelected(target2) then return end
            end
        end
        do
            local _ = target
        end
        if target and target:IsA("BasePart") then
            local _ = target
            local hit = {Instance = target, Position = target.Position}
            if hit and hit.Instance and hit.Instance:IsA("BasePart") then
                local target3 = hit.Instance
                if not isSelected(target3) then return end
            end
        end
        do
            if not target then return end
        end
        if true then
            if not isSelected(target) then return end
        end
        do
            local _ = target
        end
        if target and target:IsA("BasePart") then
            local _ = target
        end
        local hit = {Instance = target, Position = target.Position}
        if hit and hit.Instance and hit.Instance:IsA("BasePart") then
            local target4 = hit.Instance
            if not isSelected(target4) then return end
            if target.Anchored or target == workspace.Terrain then return end
            if LP.Character and target:IsDescendantOf(LP.Character) then return end
            if frozenTargets[target] then
                doUnfreeze(target, true)
                pcall(beginUnfreezeHold, target)
                task.delay(1.0, function()
                    if target and target.Parent and not frozenTargets[target] then
                        pcall(function() target.CanTouch = true end)
                    end
                end)
            else
                doFreeze(target, target.Position)
                pcall(function() target.CanTouch = false end)
            end
        end
    end
end))

reg(UserInputService.InputBegan:Connect(function(inp,gpe)
    if inp.KeyCode==Enum.KeyCode.R then
        if gpe then return end
        if UserInputService:GetFocusedTextBox() then return end

        if rotDrag.active then
            endRotDrag()
            return
        end
        local mousePos = UserInputService:GetMouseLocation()
        local inset = GuiService:GetGuiInset()
        local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y - inset.Y)
        local part = getClosestSelectablePartFromRay(ray.Origin, ray.Direction, 5000, 8)
        if part and not isSelected(part) then part = nil end
        if not part then
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000)
            local inst = hit and hit.Instance
            if inst and inst:IsA("BasePart") and isSelected(inst) then
                part = inst
            else
                return
            end
        end
        pcall(reclaimAssembly, part)
        local rr = getAssemblyRoot(part)
        if rr ~= part then pcall(reclaimAssembly, rr) end
        pcall(sethiddenproperty, part, "NetworkIsSleeping", false)

        beginRotDrag(part)
    end
end))
reg(UserInputService.InputBegan:Connect(function(inp,gpe)
    if not rotDrag.active then return end
    if inp.KeyCode==Enum.KeyCode.Escape then
        endRotDrag()
    end
end))

reg(UserInputService.InputChanged:Connect(function(input, gpe)
    if not rotDrag.active then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local rmb = false
        pcall(function() rmb = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
        if rmb then
            rotDrag.roll = rotDrag.roll + input.Delta.Y * 0.4
        else
            rotDrag.yaw = rotDrag.yaw + input.Delta.X * 0.4
            rotDrag.pitch = rotDrag.pitch + input.Delta.Y * 0.4
        end
    end
end))


reg(RunService.Heartbeat:Connect(function()
    updateMouseHit()

    if rotDrag.active and rotDrag.part then
        local part = rotDrag.part
        if not part.Parent or not isSelected(part) then
            endRotDrag()
        elseif math.abs(rotDrag.yaw) + math.abs(rotDrag.pitch) + math.abs(rotDrag.roll) > 0.0001 then
            pcall(function()
pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
                pcall(reclaimAssembly, part)
                local rr2 = getAssemblyRoot(part)
                if rr2 ~= part then pcall(reclaimAssembly, rr2) end
                pcall(linkNoCollide, part)
                local yawRad = math.rad(rotDrag.yaw)
                local pitchRad = math.rad(rotDrag.pitch)
                local rollRad = math.rad(rotDrag.roll)
                local camRight = Camera.CFrame.RightVector
                if camRight.Magnitude < 0.001 then camRight = Vector3.xAxis end
                local camLook = Camera.CFrame.LookVector
                if camLook.Magnitude < 0.001 then camLook = Vector3.new(0, 0, -1) end
                local r = CFrame.fromAxisAngle(Vector3.yAxis, yawRad)
                    * CFrame.fromAxisAngle(camRight.Unit, pitchRad)
                    * CFrame.fromAxisAngle(camLook.Unit, rollRad)
                local pos = part.Position
                rotDrag.wantRot = r * (rotDrag.wantRot or (part.CFrame - pos))
                local wantCF = CFrame.new(pos) * rotDrag.wantRot
                do
                    local okD, ownedD = pcall(canDrivePart, part)
                    if okD and ownedD then
                        part.CFrame = wantCF
                    else
                        rotDrag.wantRot = (part.CFrame - pos)
                        wantCF = part.CFrame
                    end
                end
                part.AssemblyAngularVelocity = Vector3.zero
                if not partTargets[part] then partTargets[part] = {} end
                partTargets[part].rotation = wantCF
                if frozenTargets[part] then
                    partTargets[part].position = frozenTargets[part]
                    local aoF = getNetAO(part)
                    if aoF then
                        aoF.MaxTorque = alignForceFor(part)
                        aoF.MaxAngularVelocity = math.huge
                        aoF.Responsiveness = math.huge
                        aoF.Enabled = true
                        aoF.CFrame = part.CFrame
                    end
                end
                syncAlignTarget(part, partTargets[part])
                pcall(function()
                    local aoD = getNetAO(part)
                    if aoD then aoD.CFrame = wantCF end
                end)
            end)
            rotDrag.yaw = 0
            rotDrag.pitch = 0
            rotDrag.roll = 0
        end
    end

    if autoSelectAll or autoSelectNear then
        runAutoSelectScan()
    end


    if activeMode=="Slinky" and #selectedParts>0 then
        local pos=currentMouseHit
        if #slinkyHistory==0 or (slinkyHistory[#slinkyHistory]-pos).Magnitude>0.12 then
            table.insert(slinkyHistory,pos)
            if #slinkyHistory>SLINKY_MAX then table.remove(slinkyHistory,1) end
        end
    end


    if activeMode=="Draw" and isDrawing and #selectedParts>0 then
        local pos=currentMouseHit
        if currentTrail and (#currentTrail==0 or (currentTrail[#currentTrail]-pos).Magnitude>1.0) then
            table.insert(currentTrail,pos)
            if #currentTrail>600 then table.remove(currentTrail,1) end
            if #currentTrail%8==0 then addDrawDot(pos) end  
        end
    end


    if #selectedParts>0 or spcActive or activeMode=="Comet" or activeMode=="Stickman" or activeMode=="Scythe" or activeMode=="Text" or activeMode=="Pentagram" or activeMode=="Chained" then
        tickParts()
    end


    tickAuras()


    UI.selInfo.Text="#"..#selectedParts.." selected · "..(activeMode=="Stickman" and "Billy" or activeMode)
        ..(frozen and " [FROZEN]" or "")..(attracting and " [ATTRACT]" or "")
        ..(hasFileSystem and " · cfg" or "")

    if textGui then
        local shouldShow = activeMode=="Text"
        if textGui.Visible ~= shouldShow then textGui.Visible = shouldShow end
    end


    saveConfig()
end))
if hasFileSystem then
    local saveGen = _G._catGen
    task.spawn(function()
        while true do
            task.wait(30)
            if saveGen ~= _G._catGen then return end
            pcall(saveConfig, true)
        end
    end)
    pcall(function()
        ScreenGui.AncestryChanged:Connect(function(_, parent)
            if not parent and saveGen == _G._catGen then pcall(saveConfig, true) end
        end)
    end)
    pcall(function() game:BindToClose(function() if saveGen == _G._catGen then pcall(saveConfig, true) end end) end)
    pcall(function()
        if Players and Players.PlayerRemoving then
            Players.PlayerRemoving:Connect(function(plr) if plr == LP and saveGen == _G._catGen then pcall(saveConfig, true) end end)
        end
    end)
    pcall(function()
        if getgenv then
            getgenv()._catalystSave = function() pcall(saveConfig, true) end
        end
    end)
end
if not hasFileSystem then
    task.delay(3, function()
        pcall(function() toast("no filesystem - settings won't save") end)
    end)
end

reg(RunService.Heartbeat:Connect(function()
    if #selectedParts == 0 then return end
    local now = tick()
    if now - lastAnchoredVelAudit < anchoredAuditInterval then return end
    lastAnchoredVelAudit = now
    pcall(rebuildAssemblyCache, true)
    for p in pairs(releasedSet) do
        if not p or not p.Parent then releasedSet[p] = nil end
    end
    for part in pairs(assemblyExtras) do
        if part and part.Parent and not part.Anchored then
            pcall(sethiddenproperty, part, "NetworkIsSleeping", false)
        end
    end
    local char = LP.Character
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, workspace.Terrain}
    local seen = {}
    local ownerFn = isnetworkowner or isNetworkOwner or function() return false end
    for _, src in ipairs(selectedParts) do
        if src and src.Parent then
            local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(src.Position, anchoredAuditRadius, params) end)
            if ok and parts then
                for _, p in ipairs(parts) do
                    if not seen[p] and p:IsA("BasePart") then
                        seen[p] = true
                        local isHuge = false
                        local ok2, v = pcall(function() return p.AssemblyMass == math.huge end)
                        if ok2 and v then isHuge = true end
                        if p.Anchored or isHuge then
                            if p.AssemblyLinearVelocity.Magnitude > 0.11 or p.AssemblyAngularVelocity.Magnitude > 0.11 then
                                local hasOwner = false
                                local ok3, own = pcall(function() return ownerFn(p) end)
                                if ok3 and own then hasOwner = true end
                                pcall(function()
                                    p.AssemblyLinearVelocity = Vector3.zero
                                    p.AssemblyAngularVelocity = Vector3.zero
                                end)
                            end
                        end
                    end
                end
            end
        end
        if tick() - now > 0.007 then break end
    end
end))
proxySyncAcc = 0
reg(RunService.RenderStepped:Connect(function(dt)
    if next(espLabels) then updateESP() end
    proxySyncAcc += dt or 0
    if proxySyncAcc < 0.25 then return end
    proxySyncAcc = 0
    syncSelectionProxyModel()
end))
_G._catalystConns = connections
print("catalyst loaded")
wait(2)
print("catalyst: salami edition")
wait(1)
warn("CATALYST ON TOP!!!!")
--i am the scary lion
