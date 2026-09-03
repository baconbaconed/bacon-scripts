--[[ i hate catalyst so much it give me pain in butt
like 64 modes? idk prob
best fling ever trust 
i love catalylyst
if you ever say catalylyst bad ill use sniper on your home                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ]]



do
    local ok = false
    if type(sethiddenproperty) == "function" then
        local lp = game:GetService("Players").LocalPlayer
        pcall(sethiddenproperty, lp, "ReplicationFocus", nil)
        ok = pcall(sethiddenproperty,
            lp, "SimulationRadius", math.huge)
    end
    if not ok then return end
end
workspace.FallenPartsDestroyHeight = 0/0 -- PLEASE remove this if you deem necessary, i added this solely so your parts dont instantly get fucking obliterated by the void when u try flinging someone

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
        pcall(function() LP:Kick("Catalyst is not built for mobile, and never will be, i apologize") end)
        return
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

local function fixCanQueryForRaycast()
    local function processPart(part)
        if not part:IsA("BasePart") then return end
        local char = part:FindFirstAncestorOfClass("Model")
        if char then
            local player = Players:GetPlayerFromCharacter(char)
            if player then
                return
            end
        end
        if part.Anchored then
            pcall(function() part.CanQuery = true end)
            if not part:GetAttribute("_cat_canquery_hooked") then
                part:SetAttribute("_cat_canquery_hooked", true)
                part:GetPropertyChangedSignal("Transparency"):Connect(function()
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
    workspace.DescendantAdded:Connect(function(desc)
        processPart(desc)
    end)
end

fixCanQueryForRaycast()


local networkPaused
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
    ESP_ACCENT    = Color3.fromRGB(80, 255, 210),
    Z             = 64,
}

local HL = {
    fillColor           = Color3.fromRGB(80, 255, 210),
    outlineColor        = Color3.fromRGB(80, 255, 210),
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
selectedParts = {}
partOffsets   = {}
highlights    = {}
npcHighlights = {}
spcHighlight  = nil
selectionProxyModel     = nil
selectionProxyHighlight = nil
selectionProxyParts     = {}
partPhysProperties      = {}
local refreshAllHighlights


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
ownerRadius  = 100
autoSelectAll        = false
autoSelectNear       = false
autoSelectLastScan   = 0
AUTO_SELECT_INTERVAL = 5
strengthenParts      = false
strengthenDensity    = 100
frozen          = false
frozenTargets   = {}
individuallyFrozen = {}
unfreezeBoost     = {}
rotDrag           = { active=false, part=nil, axis="X", pending=0 }
globalOwnership = false
clickSelActive  = false
attracting      = false
attractTimer    = 0
fakeCollisions  = false

partTargets = {}
_bumpSign   = 1
minigunIdx       = 1
minigunShotStart = 0
minigunLastIdx   = 0
MINIGUN_STUCK    = 12
satFired           = {}
satTarget          = Vector3.zero
SAT_TTL            = 2.0
satTouchConns      = {}
barrageTouchConns  = {}
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
STRIKE_H         = 32
STRIKE_DESCEND   = 0.52
STRIKE_DRILL     = 1.8
STRIKE_RETURN    = 0.85
sniperFireTime   = 0
sniperTargetPos  = Vector3.zero
sniperTouchConns = {}
sniperBoomStage  = 0
sniperCaught     = false
SNIPER_CYCLE     = 1.5
SNIPER_R         = 5
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
SCYTHE_SWING = 0.6
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
    ["A"]={"  X  "," X X ","X   X","XXXXX","X   X","X   X","X   X"},
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
    elseif (hasUpLeft or hasDownRight) and not (hasLeft or hasRight or hasUp or hasDown) then
        return 45
    elseif (hasUpRight or hasDownLeft) and not (hasLeft or hasRight or hasUp or hasDown) then
        return 135
    elseif (hasLeft or hasRight) and (hasUp or hasDown) then
        return 0
    else
        if hasUpLeft or hasDownRight then return 45 end
        if hasUpRight or hasDownLeft then return 135 end
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
            local wallLong = s.X >= s.Y and "X" or "Y"
            local maxDim = math.max(s.X, s.Y)
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
        local mirroredAngle = (180 - pd.angle) % 180
        local need = mirroredAngle - partAngle
        need = ((need+45)%180)-90
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
GRAB_TOSS_POWER     = 720
GRAB_DRAG_POWER     = 180
FINGER_GUN_RANGE    = 10000

useLimits    = false
partLimit    = 10
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
    "keybinds", "partSpeed", "maxVelocity", "formRadius", "formScale", "formSizeX", "formSizeY", "formSizeZ", "formOffsetY",
    "wallDist", "wallGap", "flingForce", "flingRange", "tornadoSpeed", "spiralHeight", "waveAmp", "orbitRadius",
    "autoSelRange", "ownerRadius", "killAuraRange", "sitAuraRange", "jumpAuraRange",
    "followAuraRange", "freezeAuraRange", "useLimits", "partLimit",
    "formationType", "useESP", "espStyle", "activeMode",
    "espColor", "highlightFillColor", "highlightOutlineColor", "espFillTransparency", "espOutlineTransparency", "globalOwnership", "fakeCollisions",
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
    if pcall(function() data = readfile("atomizer_saves.txt") end) and data and data ~= "" then
        pcall(function() writefile(CONFIG_FILE, data) end)
        return data
    end
    if pcall(function() data = readfile(CONFIG_FILE) end) and data and data ~= "" then -- i put shi in pcall because theres no ppcall to call with my pp twin
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
        wallDist=wallDist, wallGap=wallGap,
        flingForce=flingForce, flingRange=flingRange, tornadoSpeed=tornadoSpeed,
        spiralHeight=spiralHeight, waveAmp=waveAmp, orbitRadius=orbitRadius,
        autoSelRange=autoSelRange, ownerRadius=ownerRadius,
        killAuraRange=killAuraRange, sitAuraRange=sitAuraRange,
        jumpAuraRange=jumpAuraRange, followAuraRange=followAuraRange,
        freezeAuraRange=freezeAuraRange,
        useLimits=useLimits, partLimit=partLimit,
        formationType=formationType, useESP=useESP, espStyle=espStyle, activeMode=activeMode,
        espColor=colorStr, highlightFillColor=colorString(HL.fillColor), highlightOutlineColor=colorString(HL.outlineColor),
        espFillTransparency=HL.fillTransparency, espOutlineTransparency=HL.outlineTransparency,
        globalOwnership=globalOwnership, fakeCollisions=fakeCollisions,
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
    if cfg.wallDist ~= nil then wallDist = cfg.wallDist end
    if cfg.wallGap ~= nil then wallGap = cfg.wallGap end
    if cfg.flingForce ~= nil then flingForce = cfg.flingForce end
    if cfg.flingRange ~= nil then flingRange = cfg.flingRange end
    if cfg.tornadoSpeed ~= nil then tornadoSpeed = cfg.tornadoSpeed end
    if cfg.spiralHeight ~= nil then spiralHeight = cfg.spiralHeight end
    if cfg.waveAmp ~= nil then waveAmp = cfg.waveAmp end
    if cfg.orbitRadius ~= nil then orbitRadius = cfg.orbitRadius end
    if cfg.autoSelRange ~= nil then autoSelRange = cfg.autoSelRange end
    if cfg.ownerRadius ~= nil then ownerRadius = cfg.ownerRadius end
    if cfg.killAuraRange ~= nil then killAuraRange = cfg.killAuraRange end
    if cfg.sitAuraRange ~= nil then sitAuraRange = cfg.sitAuraRange end
    if cfg.jumpAuraRange ~= nil then jumpAuraRange = cfg.jumpAuraRange end
    if cfg.followAuraRange ~= nil then followAuraRange = cfg.followAuraRange end
    if cfg.freezeAuraRange ~= nil then freezeAuraRange = cfg.freezeAuraRange end
    if cfg.useLimits ~= nil then useLimits = cfg.useLimits end
    if cfg.partLimit ~= nil then partLimit = cfg.partLimit end
    if cfg.formationType ~= nil then formationType = cfg.formationType end
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
    if cfg.globalOwnership ~= nil then
        globalOwnership = cfg.globalOwnership
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
}




local _OWN = { preSim=1, hb=1, render=1 } -- i own robuk
local reinforceOwnershipDrive, reinforceOwnershipConstraints, reinforceOwnershipHeartbeat, reinforceOwnershipRender
pcall(function() LP.ReplicationFocus = workspace end)

local preSimConn = RunService.PreSimulation and
    RunService.PreSimulation:Connect(function(deltaTime)
        pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
        for _, part in ipairs(selectedParts) do
            if part and part.Parent and not part.Anchored then
                pcall(reinforceOwnershipConstraints, part, partTargets[part])
                pcall(reinforceOwnershipDrive, part, partTargets[part], deltaTime)
                local origVel = part.AssemblyLinearVelocity
                part.AssemblyLinearVelocity = Vector3.new(50000, 50000, 50000)
                part.AssemblyLinearVelocity = origVel
                part.AssemblyLinearVelocity = Vector3.new(-50000, -50000, -50000)
                part.AssemblyLinearVelocity = origVel
                part.AssemblyLinearVelocity = Vector3.new(50000, -50000, 50000)
                part.AssemblyLinearVelocity = origVel -- this is improtant pls no touchy touch touch
            end
        end
    end) or nil

local ownerConn = RunService.Heartbeat:Connect(function()
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    if activeMode == "DroneV2" then return end
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(reinforceOwnershipConstraints, part, partTargets[part])
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            local origVel = part.AssemblyLinearVelocity
            part.AssemblyLinearVelocity = Vector3.new(75000, 75000, 75000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(-75000, -75000, -75000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(75000, -75000, 75000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(-75000, 75000, -75000)
            part.AssemblyLinearVelocity = origVel
        end
    end
end)


local renderOwnerConn = RunService.RenderStepped:Connect(function()
    if activeMode == "DroneV2"  then return end
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(reinforceOwnershipConstraints, part, partTargets[part])
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            pcall(reinforceOwnershipRender, part, partTargets[part])
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            pcall(reinforceOwnershipRender, part, partTargets[part])
            local origVel = part.AssemblyLinearVelocity
            part.AssemblyLinearVelocity = Vector3.new(100000, 100000, 100000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(-100000, -100000, -100000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(100000, -100000, 100000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(-100000, 100000, -100000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(100000, 100000, -100000)
            part.AssemblyLinearVelocity = origVel
        end
    end
end)
local aggressiveOwnerConn = RunService.Heartbeat:Connect(function()
    if activeMode == "DroneV2" then return end
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
            pcall(reinforceOwnershipRender, part, partTargets[part])
            local origVel = part.AssemblyLinearVelocity
            part.AssemblyLinearVelocity = Vector3.new(150000, 150000, 150000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(-150000, -150000, -150000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(150000, -150000, 150000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(-150000, 150000, -150000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(150000, 150000, -150000)
            part.AssemblyLinearVelocity = origVel
            part.AssemblyLinearVelocity = Vector3.new(-150000, -150000, 150000)
            part.AssemblyLinearVelocity = origVel
        end
    end
end)


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

reinforceOwnershipConstraints = function(part, target)
    if not (part and part.Parent and target) then return end
    if activeMode == "DroneV2" then return end

    local AP = getNetAP(part)
    if AP then
        AP.Enabled = true
        AP.MaxForce = math.huge
        AP.MaxVelocity = math.huge
        AP.RigidityEnabled = false
    end

    local AO = getNetAO(part)
    if AO then
        AO.Enabled = true
        AO.MaxTorque = math.huge
        AO.MaxAngularVelocity = math.huge
    end
    local supportForce = Vector3.new(0, part.AssemblyMass * workspace.Gravity * 0.08, 0)
    for _, name in ipairs({"ServerResponse", "ServerResponse2"}) do
        local response = part:FindFirstChild(name)
        if response and response:IsA("BodyForce") then
            response.Force = supportForce
        end
    end
end

reinforceOwnershipHeartbeat = function(part, target)
    if not (part and part.Parent and target and target.position) then return end
    if activeMode == "DroneV2" then return end

    local originalVelocity = part.AssemblyLinearVelocity
    local diff = target.position - part.Position
    local dist = diff.Magnitude
    local desiredVelocity = diff.Unit * 20000
    part.AssemblyLinearVelocity = originalVelocity:Lerp(desiredVelocity, 0.99)
    part.AssemblyLinearVelocity = originalVelocity
    part.AssemblyLinearVelocity = Vector3.new(15, 15, 15)
end

reinforceOwnershipRender = function(part, target)
    if not (part and part.Parent and target and target.position) then return end
    if activeMode == "DroneV2" then return end

    local originalVelocity = part.AssemblyLinearVelocity
    local diff = target.position - part.Position
    local dist = diff.Magnitude
    local desiredVelocity = diff.Unit * 30000
    part.AssemblyLinearVelocity = originalVelocity:Lerp(desiredVelocity, 0.995)
    part.AssemblyLinearVelocity = originalVelocity
    part.AssemblyLinearVelocity = Vector3.new(15, 15, 15) -- this is my trick, if you set speed to 15 or above 14.46262424 it stays still, pls no touchy touch touch
end

reinforceOwnershipDrive = function(part, target, deltaTime)
    if not (part and part.Parent and target and target.position) then return end
    if activeMode == "DroneV2" then return end

    local originalVelocity = part.AssemblyLinearVelocity
    local diff = target.position - part.Position
    local dist = diff.Magnitude
    local desiredVelocity = diff.Unit * 40000
    part.AssemblyLinearVelocity = originalVelocity:Lerp(desiredVelocity, 0.998)
    part.AssemblyLinearVelocity = originalVelocity
    part.AssemblyLinearVelocity = Vector3.new(15, 15, 15) -- again no touchy touch touch, needs to be above 14.46262424 at all times!!!!
end

local function reassertOwnershipAll()
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    pcall(function() LP.ReplicationFocus = workspace end)
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
        pcall(function() LP.ReplicationFocus = workspace end)
        for _, part in ipairs(selectedParts) do
            if part and part.Parent and not part.Anchored then
                pcall(reinforceOwnershipConstraints, part, partTargets[part])
                pcall(reinforceOwnershipHeartbeat, part, partTargets[part])
                local AP = getNetAP(part)
                if AP then
                    AP.Enabled = true
                    AP.MaxForce = math.huge
                    AP.MaxVelocity = math.huge
                    AP.Position = partTargets[part] and partTargets[part].position or part.Position
                end
                local AO = getNetAO(part)
                if AO then
                    AO.Enabled = true
                    AO.MaxTorque = math.huge
                    AO.MaxAngularVelocity = math.huge
                    AO.CFrame = partTargets[part] and partTargets[part].rotation or part.CFrame
                end
            end
        end
    end)
end

reg(LP.CharacterAdded:Connect(function()
    task.delay(0.1, function() reassertOwnershipAggressive(5) end)
    task.delay(0.5, function() reassertOwnershipAggressive(5) end)
end))

do
    local function hookHum(ch)
        local h = ch:WaitForChild("Humanoid", 8) -- human is oid
        if h then
            h.Died:Connect(function()
                task.spawn(function()
                    for _ = 1, 20 do
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
    if frozenTargets[part] then return end

    local posResponsiveness = target.responsiveness or 100000
    local rotResponsiveness = target.rotResponsiveness or math.max(40000, posResponsiveness * 0.7)

    local AP = getNetAP(part)
    if AP then
        AP.Mode               = Enum.PositionAlignmentMode.OneAttachment
        AP.MaxForce           = math.huge
        AP.MaxVelocity        = math.huge
        AP.Responsiveness     = posResponsiveness
        AP.RigidityEnabled    = false
        AP.ApplyAtCenterOfMass = true
        AP.Enabled            = true
        AP.Position           = target.position or part.Position
    end

    local AO = getNetAO(part)
    if AO then
        AO.Mode               = Enum.OrientationAlignmentMode.OneAttachment
        AO.MaxTorque          = math.huge
        AO.MaxAngularVelocity = math.huge
        AO.Responsiveness     = rotResponsiveness
        AO.RigidityEnabled    = false
        AO.Enabled            = true
        AO.CFrame             = target.rotation or part.CFrame
    end
end
local smoothMovementConn = RunService.RenderStepped:Connect(function()
    if activeMode == "DroneV2" then return end
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored and not frozenTargets[part] then
            pcall(function()
                syncAlignTarget(part, partTargets[part])
            end)
        end
    end
end)

local function getMoveResponsiveness(multiplier)
    local base = 20 + partSpeed * 4
    return math.clamp(base * (multiplier or 1), 50, 500)
end

local useRotationTargets = false

local partTouchConns = {}

partCollisionState = {}
local partCollisionConns = {}


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

local function reclaimOnTouch(part)
    if not part or not part.Parent then return end

    local isVelMode = activeMode == "DroneV2"

pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    local target = partTargets[part]
    pcall(function()

        local AP = getNetAP(part)
        if AP then
            AP.MaxForce    = math.huge
            AP.MaxVelocity = math.huge
            if not isVelMode then
                AP.Position    = (target and target.position) or part.Position
            end
        end
        local AO = getNetAO(part)
        if AO then
            AO.MaxTorque          = math.huge
            AO.MaxAngularVelocity = math.huge
            AO.CFrame             = (target and target.rotation) or part.CFrame
        end

        if isVelMode then
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function isSelected(p)
    for _,s in ipairs(selectedParts) do if s==p then return true end end
    return false
end

local clearDrawDots

local function doUnfreeze(part)
    if not part then return end
    frozenTargets[part] = nil
    pcall(function()
        if partPhysProperties[part] and partPhysProperties[part].CustomPhysicalProperties ~= nil then
            part.CustomPhysicalProperties = partPhysProperties[part].CustomPhysicalProperties
        else
            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
        end
    end)
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
    end
    if prevMode == "DroneV2" and nextMode ~= "DroneV2" then
        dv2Target = nil
        if dv2Label and nextMode ~= "DroneV2" then
            dv2Label.Text = "Inactive"
        end
        if prevMode == "DroneV2" then
            for _, part in ipairs(selectedParts) do
                if part and part.Parent then
                    pcall(sethiddenproperty, part, "PhysicsRepRootPart", nil)
                end
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
        if homingLabel and nextMode ~= "Homing" then
            homingLabel.Text = "Inactive"
        end
        if prevMode == "Homing" then
            for _, part in ipairs(selectedParts) do
                if part and part.Parent then
                    pcall(sethiddenproperty, part, "PhysicsRepRootPart", nil)
                end
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
        if railgunLabel and nextMode ~= "Railgun" then
            railgunLabel.Text = "Inactive"
        end
    end
    if prevMode == "Barrage" and nextMode ~= "Barrage" then
        barrageActive = false
        if barrageLabel and nextMode ~= "Barrage" then
            barrageLabel.Text = "Inactive"
        end
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
        if barrageLabel and nextMode ~= "Barrage" then
            barrageLabel.Text = "Inactive"
        end
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
    for _, offset in ipairs(localOffsets) do -- FOR OFFSET ROBLOX DO GET SOLARA EXECUTOR = TRUE SOLARA.OFFSETS = UPDATED 🤑🤑🤑🤑🤑🤑🤑🤑🤑🤑🤑🤑🤑🤑 SOLARA.UPDATE = NOW ROBLOX.INTERNAL OFFSETS PRINT() ELSE DIE.TRUE = TRUE IF SOLARA.UPDATED = FALSE THEN REPLICATESIGNAL(PLAYER.SUPERKILL) ELSEIF PRINT("HAPPY SOLARA") PRINT.OFFSET = 0x0
        local worldPos = pCFrame:PointToWorldSpace(offset)
        local screenPos, onScreen = Camera:WorldToScreenPoint(worldPos)
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

        local proxy = selectionProxyParts[part]
        if not proxy or not proxy.Parent then
            proxy = Instance.new("Part")
            proxy.Name = "HLProxy"
            proxy.Anchored = true
            proxy.CanCollide = false
            proxy.CanTouch = false
            proxy.CanQuery = false
            proxy.CastShadow = false
            proxy.Locked = true
            proxy.Massless = true
            proxy.Transparency = 0.95
            proxy.Material = Enum.Material.SmoothPlastic
            proxy.Size = Vector3.new(1, 1, 1)
            proxy.Parent = selectionProxyModel
            selectionProxyParts[part] = proxy
        end

        proxy.CFrame = part.CFrame
        proxy.Size = Vector3.new(
            math.max(part.Size.X, 0.05),
            math.max(part.Size.Y, 0.05),
            math.max(part.Size.Z, 0.05)
        )
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
        if not highlights[part] or not part or not part.Parent then
            pcall(function() proxy:Destroy() end)
            selectionProxyParts[part] = nil
        elseif proxy and proxy.Parent then
            proxy.CFrame = part.CFrame
            proxy.Size = Vector3.new(
                math.max(part.Size.X, 0.05),
                math.max(part.Size.Y, 0.05),
                math.max(part.Size.Z, 0.05)
            )
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
                    local centerY = (minY + maxY) * 0.5 - inset.Y
                    frame.Position = UDim2.fromOffset(centerX, centerY)
                else
                    frame.Visible = false
                end
            else
                local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    frame.Visible = true
                    frame.Position = UDim2.fromOffset(screenPos.X, screenPos.Y - inset.Y)
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
        part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0)
    end)
end

local function refreshStickFaceSet()
    stickFaceSet = {}
    local total = #selectedParts
    if total < 3 then return end
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

local function selectPart(part, allowAnchored)
    if not part or not part:IsA("BasePart") then return end
    if part.Anchored and not allowAnchored then return end
    if part==workspace.Terrain then return end
    if isPlayerPart(part) then return end
    if isSelected(part) then return end
local r=math.random

    local spreadX = formSizeX
    local spreadZ = formSizeZ
    local liftY   = formSizeY
    partOffsets[part]=Vector3.new(
        (r()-.5)*0.4*spreadX,
        (r()-.5)*0.4*liftY,
        (r()-.5)*0.4*spreadZ
    )
    table.insert(selectedParts,part)
    addHL(part)
    if not partPhysProperties[part] then
        partPhysProperties[part] = {
            CustomPhysicalProperties = part.CustomPhysicalProperties
        }
    end
    pcall(function()
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        part.CanQuery = true
    end)
    
    if strengthenParts then
        pcall(function()
            part.CustomPhysicalProperties = PhysicalProperties.new(strengthenDensity, 0.3, 0.5) -- part.customphysicalproperties = killbrick = true
        end)
    end
    pcall(function() disableSelectedCollision(part) end)
    local seat = part:FindFirstChildOfClass("Seat")
    if seat then
        seat.Disabled = true
    end
    if part:IsA("Seat") then
        part.Disabled = true
    end

    partTouchConns[part] = part.Touched:Connect(function()
        if not allowedTouchModes[activeMode] then return end
        reclaimOnTouch(part)
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
        AP.MaxForce = math.huge
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
        AO.MaxTorque = math.huge
        AO.MaxAngularVelocity = math.huge
        AO.Responsiveness = 150
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
                response.Force = Vector3.new(0, part.AssemblyMass * workspace.Gravity * 0.08, 0)
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
end

local function cleanupPartState(part, destroyPart)
    if not part then return end
    partTargets[part] = nil
    networkRuleApplied[part] = nil
    partOffsets[part] = nil
    doUnfreeze(part)
    unfreezeBoost[part] = nil
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

    if partPhysProperties[part] then
        pcall(function()
            if part.Parent then
                part.CustomPhysicalProperties = partPhysProperties[part].CustomPhysicalProperties
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
    if boomerangConns[part] then
        pcall(function() boomerangConns[part]:Disconnect() end)
        boomerangConns[part] = nil
    end
    bridgeSlots[part] = nil

    restoreSelectedCollision(part)

    pcall(function()
        if part.Parent then
            local bp = part:FindFirstChild("NetBP")
            if bp then bp:Destroy() end
            local netBg = part:FindFirstChild("NetBG")
            if netBg then netBg:Destroy() end
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

            pcall(sethiddenproperty, part, "PhysicsRepRootPart", nil)

            if destroyPart then
                part:Destroy()
            end
        end
    end)
end

local function updatePhysPropertiesForSelected()
    for _, part in ipairs(selectedParts) do
        if part and part.Parent then
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
    partPhysProperties = {}
    partOffsets = {}
    frozenTargets = {}
    partTargets = {}
    satFired = {}
    partCollisionState = {}
    partCollisionConns = {}
    satTarget = Vector3.zero
    slinkyHistory = {}
    minigunIdx = 1
    minigunShotStart = 0
    minigunLastIdx = 0
end

local function deselectPart(part)
    for i,p in ipairs(selectedParts) do
        if p==part then
            table.remove(selectedParts,i)
            cleanupPartState(part, false)
            if activeMode == "Stickman" then pcall(refreshStickFaceSet) end
            return
        end
    end
end

local function clearSelection(destroyParts)
    for i=#selectedParts,1,-1 do
        cleanupPartState(selectedParts[i], destroyParts)
    end
    resetSelectionState()
end

local function selectAll()
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored
           and obj ~= workspace.Terrain
           and not isPlayerPart(obj) then
            selectPart(obj)
        end
    end
end
local function selectInRange(r)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then selectAll(); return end
    local myPos = root.Position
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored
           and obj ~= workspace.Terrain
           and not isPlayerPart(obj)
           and (obj.Position - myPos).Magnitude <= r then
            selectPart(obj)
        end
    end
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
        selectAll()
    elseif autoSelectNear then
        selectInRange(autoSelRange)
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

local RAY = { mouse = RaycastParams.new(), ground = RaycastParams.new() }
RAY.mouse.FilterType  = Enum.RaycastFilterType.Exclude
RAY.ground.FilterType = Enum.RaycastFilterType.Exclude
local _mouseRayParams  = RAY.mouse
local _groundRayParams = RAY.ground

local function getMouseExcludeList()
    local list, seen = {}, {}
    local function add(inst)
        if inst and not seen[inst] then
            seen[inst] = true
            table.insert(list, inst)
        end
    end
    for _, part in ipairs(selectedParts) do
        add(part)
        local parent = part.Parent
        if parent and (parent:IsA("Model") or parent:IsA("Folder")) then
            add(parent)
        end
    end
    if spcPart then add(spcPart) end
    local char = LP.Character
    if char then add(char) end
    for _, dot in ipairs(drawIndicators) do add(dot) end
    return list
end

local function getGroundYAt(x, z, defaultY, ignorePart)
    local exclude = getMouseExcludeList()
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

local function updateMouseHit()
    _mouseRayParams.FilterDescendantsInstances = getMouseExcludeList()


    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local x = mousePos.X
    local y = mousePos.Y - inset.Y

    local ray = Camera:ScreenPointToRay(x, y)
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000, _mouseRayParams)
    if not hit then
        local fallback = RaycastParams.new()
        fallback.FilterType = Enum.RaycastFilterType.Exclude
        fallback.FilterDescendantsInstances = {LP.Character}
        fallback.IgnoreWater = true
        hit = workspace:Raycast(ray.Origin, ray.Direction * 5000, fallback)
    end
    if hit then
        currentMouseHit = hit.Position
    else
        currentMouseHit = ray.Origin + ray.Direction * 1000
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
        local rMax = math.max(scX, scZ)
        local r=math.max(total*0.45,formRadius)*rMax; local a=angle+t*1.0
        return Vector3.new(mHit.X+math.cos(a)*r*scX,mHit.Y+1.5*scY+math.sin(t*1.2)*0.4,mHit.Z+math.sin(a)*r*scZ)

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
        local r=math.max(total*0.4,formRadius)*rMax; local a=angle+t*0.7
        return Vector3.new(rp.X+math.cos(a)*r*scX,rp.Y+7*scY+math.sin(t*2.2)*0.3,rp.Z+math.sin(a)*r*scZ)

    elseif activeMode=="Drone" then
        local off=partOffsets[part] or Vector3.zero
        local driftX=math.sin(t*1.6+index*1.1)*2*scX
        local driftY=math.sin(t*2.6+index*0.9)*1*scY
        local driftZ=math.cos(t*1.3+index*1.4)*2*scZ
        return mHit+Vector3.new(off.X*1.8*scX,off.Y*1.8,off.Z*1.8*scZ)+Vector3.new(driftX,driftY,driftZ)+Vector3.new(0,4*scY,0)

    elseif activeMode=="DroneV2" then
        if dv2Target then
            return dv2Target.Position+Vector3.new(
                math.sin(t*16+index*1.7)*0.6,math.sin(t*12+index*0.9)*0.6,math.cos(t*16+index*1.3)*0.6)
        end
        local rX=formRadius*scX; local rZ=formRadius*scZ; local a=angle+t*0.9
        return Vector3.new(rp.X+math.cos(a)*rX,rp.Y+5.5*scY+math.sin(t*2+index*0.65)*0.35,rp.Z+math.sin(a)*rZ)

    elseif activeMode=="Shield" then
        local phi=(1+math.sqrt(5))/2; local i=index-1
        local theta=2*math.pi*i/phi
        local cosY=math.clamp(-0.2+(i/math.max(total-1,1))*1.2,-1,1)
        local sinY=math.sqrt(1-cosY*cosY); local r=(formRadius+0.5)*scR
        return Vector3.new(rp.X+sinY*math.cos(theta)*r*scX,rp.Y+cosY*r+1.5*scY,rp.Z+sinY*math.sin(theta)*r*scZ)

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
        if dist < 0.01 then return startP end
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


        local rx = formRadius * scX
        local ry = formRadius * scY
        local rz = formRadius * scZ


        local yLatScale = 0.28
        return Vector3.new(
            mHit.X + sinY*math.cos(theta+t*0.4)*rx,
            mHit.Y + cosY*ry*yLatScale,
            mHit.Z + sinY*math.sin(theta+t*0.4)*rz)

    elseif activeMode=="Vortex" then
        local band=(index-1)%6; local h=math.floor((index-1)/6)*2.2*scY
        local spin=band/6*math.pi*2-t*tornadoSpeed*2
        local maxR = math.max(scX, scZ)
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
        local spZ=(part.Size.X+wallGap)*scZ
        return Vector3.new(mHit.X+col*spX,mHit.Y+4*scY,mHit.Z+row*spZ)

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
        local rot  = CFrame.Angles(t * 0.45, t * 0.32, 0)
        local out  = Vector3.new(v.X * half * scX, v.Y * half * scY, v.Z * half * scZ)
        return mHit + rot:VectorToWorldSpace(out) + Vector3.new(0, 4 * scY + half * scY, 0)

    elseif activeMode=="Scatter" then
        local scatter=(math.sin(t*1.5)+1)/2
        local off=(partOffsets[part] or Vector3.zero)
        local far=mHit+Vector3.new(off.X*14*scX,off.Y*14,off.Z*14*scZ)+Vector3.new(0,math.abs(off.Y)*4*scY,0)
        return mHit:Lerp(far,scatter)+Vector3.new(0,1*scY,0)

    elseif activeMode=="Star" then
        local isPoint=(index-1)%2==0
        local spoke=math.floor((index-1)/2)
        local sAngle=spoke/math.ceil(total/2)*math.pi*2+t*0.6
        local r=isPoint and formRadius*2*scR or formRadius*0.75*scR
        return Vector3.new(mHit.X+math.cos(sAngle)*r*scX,mHit.Y+2*scY,mHit.Z+math.sin(sAngle)*r*scZ)

    elseif activeMode=="Pendulum" then
        local swing=math.sin(t*4+index*0.55)*formRadius*scX
        local dip=-(1-math.cos(t*4+index*0.55))*formRadius*scY*0.5
        return Vector3.new(mHit.X+swing,mHit.Y+6*scY+dip,mHit.Z+(ratio-0.5)*4*scZ)

    elseif activeMode=="Rain" then
        local phase=(index-1)/math.max(total,1)*math.pi*2
        local off=partOffsets[part] or Vector3.zero
        local x = mHit.X + off.X * 3 * scX
        local z = mHit.Z + off.Z * 3 * scZ
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

        local cycle  = (t*1.5) % 1
        local pull   = math.max(0, 1 - cycle*2.2)          
        local r      = formRadius * pull
        local spin   = angle - t*10*(1.2 - pull*0.9)        
        local h      = pull * 4
        return Vector3.new(mHit.X+math.cos(spin)*r, mHit.Y+h, mHit.Z+math.sin(spin)*r)

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

        local isSpike = (index-1)%2 == 0
        local spokes  = math.ceil(total/2)
        local si      = math.floor((index-1)/2)
        local a       = si/math.max(spokes,1)*math.pi*2 + t*0.24
        local r       = formRadius * scR
        if isSpike then
            local sway = 0
            local pos = Vector3.new(rp.X+math.cos(a)*r*scX, rp.Y+10*scY+sway, rp.Z+math.sin(a)*r*scZ)
            if partTargets[part] then
                partTargets[part].position = pos
                partTargets[part].rotation = part.CFrame
            end
            return pos
        else
            local pos = Vector3.new(rp.X+math.cos(a)*r*0.65*scX, rp.Y+7*scY, rp.Z+math.sin(a)*r*0.65*scZ)
            if partTargets[part] then
                partTargets[part].position = pos
                partTargets[part].rotation = part.CFrame
            end
            return pos
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

        local high     = 20 * scY
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

        if index == minigunIdx then
            return mHit
        end
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return rp end
 
        local qp   = index < minigunIdx and index or (index - 1)
        local cols = math.max(math.min(3, total - 1), 1)
        local col  = ((qp - 1) % cols) - math.floor((cols - 1) / 2)
        local row  = math.floor((qp - 1) / cols)
        return rp
            + (-root.CFrame.LookVector) * (5 + row * 2.0)
            + root.CFrame.RightVector   * (col * 1.6)
            + Vector3.new(0, 1.5, 0)

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
        if stickBeamActive then
            local isArm = u >= 0.37 and u < 0.73
            local armMatch = stickArmIsLeft and u < 0.55 or (not stickArmIsLeft and u >= 0.55)
            if isArm and armMatch then
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
                return beamTarget + jitter
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
                    local gd    = blockedMouse - shW
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
        local layer = (index - 1) % 3
        local layerIdx = math.floor((index - 1) / 3)
        local layers = math.max(1, math.ceil(total / 3))

        local baseR = formRadius * scR * (1 + layer * 0.4)
        local spinSpeed = 2.4 + layer * 0.5
        local orbitSpeed = 1.6 + layer * 0.3
        local bobSpeed = 5.0 + layer * 0.8

        local orbitAngle = angle + t * orbitSpeed
        local spinAngle = angle * 2 + t * spinSpeed + index * 0.5
        local bobOffset = math.sin(t * bobSpeed + index * 0.7) * (1.5 + layer * 0.5) * scY

        local wobbleX = math.sin(t * 6 + index * 1.2) * 0.8 * scX
        local wobbleZ = math.cos(t * 5.0 + index * 0.9) * 0.8 * scZ

        local r = baseR * (0.85 + 0.15 * math.sin(spinAngle))

        return Vector3.new(
            mHit.X + math.cos(orbitAngle) * r * scX + wobbleX,
            mHit.Y + 3 * scY + bobOffset + layer * 1.5 * scY,
            mHit.Z + math.sin(orbitAngle) * r * scZ + wobbleZ)

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
            local res     = aimCF * Vector3.new(math.cos(aa) * rr, math.sin(aa) * rr * (hh0 / hw0), zi)
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
        
        local wingSide = index % 2 == 0 and 1 or -1
        local wingIndex = math.floor((index - 1) / 2)
        local wingTotal = math.ceil(total / 2)
        local wingRatio = wingIndex / math.max(wingTotal - 1, 1)
        
        local wingSpan = formRadius * 2.5 * scR
        local wingCurve = math.sin(wingRatio * math.pi * 0.5) * wingSpan
        local wingY = wingRatio * formRadius * 1.5 * scY
        local wingZ = math.sin(wingRatio * math.pi) * formRadius * 0.5 * scZ
        
        local flap = math.sin(t * 4 + wingRatio * 3) * 0.3
        local flapY = math.sin(t * 8 + wingRatio * 2) * 0.5 * scY
        local spread = wingSide * (wingCurve + flap * wingSpan * 0.2)
        local featherLayer = wingIndex % 3
        local featherOffset = featherLayer * 0.3 * scR
        local featherAngle = wingRatio * math.pi * 0.8 + featherLayer * 0.2
        
        local localPos = Vector3.new(spread + featherOffset, wingY + flapY, wingZ + math.sin(featherAngle) * featherOffset)
        local worldPos = origin + rightDir * localPos.X * scX + upDir * localPos.Y + lookDir * localPos.Z * scZ
        
        return worldPos

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
        local c1     = mHit + Vector3.new(math.cos(coreA) * orbitR, bob + 4 * scY, math.sin(coreA) * orbitR)
        local c2     = mHit + Vector3.new(math.cos(coreA + math.pi) * orbitR, -bob + 4 * scY, math.sin(coreA + math.pi) * orbitR)
        local slot   = (index - 1) % 6
        if slot == 0 then
            local off = partOffsets[part] or Vector3.zero
            return c1 + off * 0.55 + Vector3.new(
                math.sin(t * 9 + index) * 0.18,
                math.cos(t * 8 + index) * 0.18,
                math.sin(t * 7 + index) * 0.18)
        elseif slot == 1 then
            local off = partOffsets[part] or Vector3.zero
            return c2 + off * 0.55 + Vector3.new(
                math.sin(t * 9 + index * 1.3) * 0.18,
                math.cos(t * 8 + index * 1.1) * 0.18,
                math.sin(t * 7 + index * 1.7) * 0.18)
        end
        local u     = angle + t * 2.1
        local denom = 1 + math.sin(u) ^ 2
        local aK    = orbitR * 2.3
        local x = aK * math.cos(u) / denom
        local z = aK * math.cos(u) * math.sin(u) / denom
        local y = 4 * scY + math.sin(t * 2.6 + index * 0.7) * 1.1 * scY
        return mHit + Vector3.new(x * scX, y, z * scZ)

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
        local spinCF = CFrame.Angles(t * 0.19, t * 0.27, 0)
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
        local centerS = (rootN and rootN.Position or mHit) + Vector3.new(0, 8 * scY, 0)
        local ringR   = SNIPER_R * scR
        local faceCF  = rootN and rootN.CFrame or CFrame.identity
        local ca      = ((index - 1) / math.max(total, 1)) * math.pi * 2 + t * 2.4
        local slotP   = centerS
            + faceCF.RightVector * (math.cos(ca) * ringR)
            + Vector3.yAxis * (math.sin(ca) * ringR)
        local since = t - sniperFireTime
        local delay = ((index - 1) / math.max(total, 1)) * 0.35
        local tp    = since - delay
        local tgtP  = sniperTargetPos
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
        if bridgeSlots[part] then
            if typeof(bridgeSlots[part]) == "Vector3" then
                return bridgeSlots[part]
            elseif frozenTargets[part] then
                return frozenTargets[part]
            elseif partTargets[part] and partTargets[part].position then
                return partTargets[part].position
            end
        end
        if frozenTargets[part] then
            return frozenTargets[part]
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
            local stag = ratio * 0.22
            if strikeState == "descend" then
                local prog = math.clamp((age - stag) / STRIKE_DESCEND, 0, 1)
                local aa   = angle * 2 + t * 14
                local rr   = (2.5 * (1 - prog) + 0.6) * maxScL
                local pos  = (strikeTarget + Vector3.new(0, 70, 0)):Lerp(strikeTarget, prog * prog)
                return pos + Vector3.new(math.cos(aa) * rr, 0, math.sin(aa) * rr)
            elseif strikeState == "drill" then
                local ia = angle * 3 + t * 16
                local ir = (0.8 + ((index * 7) % 5) * 0.35) * maxScL + math.sin(t * 20 + index) * 0.4
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
        local perEdge = math.max(1, math.ceil(total/5))
        local eIdx = ((index-1) % 5) + 1
        local seg = math.floor((index-1)/5)
        local tEdge = perEdge>1 and seg/(perEdge-1) or 0.5
        local aIdx = order[eIdx]
        local bIdx = order[eIdx %5 +1]
        local pa = verts[aIdx]; local pb = verts[bIdx]
        local lx = pa.X + (pb.X - pa.X)*tEdge
        local ly = pa.Y + (pb.Y - pa.Y)*tEdge
        local pulse = 1 + 0.06*math.sin(t*2.5 + index*0.15)
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
        local idleCenter = rpS + Vector3.new(0, 6.5*scY, 0)
        local spin = t*0.85
        local swingP = 0
        local isSwing = scytheState=="swing"
        if isSwing then
            swingP = math.clamp((t - scytheStart)/SCYTHE_SWING,0,1)
        end
        local handleLen = formRadius*1.35*scY + 4.2
        local bladeR = formRadius*0.95*scR + 1.5
        local localPos
        local r = ratio
        if r < 0.62 then
            local hr = r/0.62
            localPos = Vector3.new(math.sin(spin*0.6 + index*0.4)*0.12, hr*handleLen - handleLen*0.5, math.cos(spin*0.4+index)*0.08)
        else
            local br = (r-0.62)/0.38
            local handleTip = Vector3.new(0, handleLen*0.5, 0)
            local tip = handleTip + Vector3.new(0, -bladeR*0.11, bladeR*1.42)
            local tt = math.pow(br, 0.90)
            local basePos = handleTip:Lerp(tip, tt)
            local belly = math.sin(br*math.pi) * bladeR*0.20
            localPos = basePos + Vector3.new(math.sin(br*math.pi*0.7)*bladeR*0.04, -belly*0.55, belly*0.22)
        end
        local baseCF
        if isSwing then
            local ease = swingP*swingP*(3-2*swingP)
            local yaw = -85 + ease*170
            local tilt = 90
            local swingCenter = scytheSwingPos
            if swingCenter == Vector3.zero then
                swingCenter = currentMouseHit + Vector3.new(0,0.4,0)
            end
            scytheCenter = swingCenter
            baseCF = CFrame.new(swingCenter) * CFrame.Angles(0, math.rad(yaw), math.rad(tilt))
        else
            local idleYaw = spin*18
            local idleTilt = 52 + math.sin(t*0.7)*6
            scytheCenter = idleCenter + Vector3.new(math.sin(t*0.9)*0.7, math.sin(t*1.3)*0.35, math.cos(t*0.9)*0.7)
            baseCF = CFrame.new(scytheCenter) * CFrame.Angles(math.rad(idleTilt), math.rad(idleYaw), 0)
        end
        return baseCF:PointToWorldSpace(localPos)
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
    end

    return mHit
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

local function tickParts()
    local t     = tick()
    local total = #selectedParts
    local char  = LP.Character
    

    local partsToUse = total

    local cRoot=char and char:FindFirstChild("HumanoidRootPart")
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


    if globalOwnership and cRoot then
        _bumpSign = -_bumpSign
        local bump   = Vector3.new(0, 0.008 * _bumpSign, 0)
        local myPos  = cRoot.Position
        local count  = 0
        local function tryBump(obj)
            if count >= 400 then return end
            if obj:IsA("BasePart") and not obj.Anchored and obj ~= workspace.Terrain
               and not (char and obj:IsDescendantOf(char))
               and not isPlayerPart(obj)
            and not frozenTargets[obj]
                and (obj.Position - myPos).Magnitude <= ownerRadius then
                count += 1
                pcall(function() obj.AssemblyLinearVelocity = obj.AssemblyLinearVelocity + bump end)
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            tryBump(obj)
            if obj:IsA("Model") or obj:IsA("Folder") then
                for _, child in ipairs(obj:GetChildren()) do tryBump(child) end
            end
        end
    end


    if spcActive and spcPart and spcPart.Parent then
        local tgt = currentMouseHit + Vector3.new(0, spcYOff, 0)
        local diff = tgt - spcPart.Position
        local dist = diff.Magnitude
        local agSPC = Vector3.new(0, workspace.Gravity / 60, 0)
        pcall(function()
            spcPart.AssemblyLinearVelocity = dist > 0.05
                and diff.Unit * (dist * partSpeed * 2) + agSPC  
                or  agSPC
            spcPart.AssemblyAngularVelocity = Vector3.zero
        end)
    end


    if activeMode=="DroneV2" and total>0 then
        local myRoot=char and char:FindFirstChild("HumanoidRootPart")
        dv2Target=nil
        if myRoot then
            local myPos=myRoot.Position; local best=flingRange+1
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr~=LP and plr.Character then
                    local tr=plr.Character:FindFirstChild("HumanoidRootPart")
                    if tr then local d=(tr.Position-myPos).Magnitude
                        if d<=flingRange and d<best then best=d; dv2Target=tr end end
                end
            end
            for _,model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and model~=char then
                    local h=model:FindFirstChildOfClass("Humanoid")
                    local tr=h and model:FindFirstChild("HumanoidRootPart")
                    if tr then local d=(tr.Position-myPos).Magnitude
                        if d<=flingRange and d<best then best=d; dv2Target=tr end end
                end
            end
        end
        if dv2Label then
            dv2Label.Text=dv2Target
                and "Target: "..(dv2Target.Parent and dv2Target.Parent.Name or "?")
                or  "Scanning… no target in range"
        end
    elseif dv2Label and activeMode~="DroneV2" then
        dv2Label.Text="Inactive"; dv2Target=nil
    end

    if activeMode=="Homing" and total>0 then
        if homingTarget and tick() >= homingEndTime then
            homingTarget = nil
        end
        if homingLabel then
            homingLabel.Text = homingTarget and tick() < homingEndTime
                and "Missile: "..(homingTarget.Parent and homingTarget.Parent.Name or "?")
                or "Click a player to lock"
        end
    elseif homingLabel and activeMode~="Homing" then
        homingLabel.Text="Inactive"; homingTarget=nil
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
                            part.AssemblyLinearVelocity = part.AssemblyLinearVelocity + burstDir * 3000
                            hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + burstDir * 9000
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
                    impactBurst(railgunHitPos, 28, 8500)
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
        if railgunLabel then
            if railgunCharging then
                railgunLabel.Text = "Charging: "..math.floor((now - railgunChargeStart) * 100).."%"
            elseif railgunFired then
                if railgunPhase == "firing" then railgunLabel.Text = "BEAM FIRING"
                elseif railgunPhase == "exploding" then railgunLabel.Text = "EXPLODING!"
                else railgunLabel.Text = "Returning..." end
            else
                railgunLabel.Text = "Hold click to charge"
            end
        end
    elseif railgunLabel and activeMode~="Railgun" then
        railgunLabel.Text="Inactive"; railgunCharging=false; railgunFired=false; railgunPhase="idle"; railgunHitPos=Vector3.zero
    end

    if activeMode=="Barrage" and total>0 then
        barrageActive = true
        if barrageLabel then
            barrageLabel.Text = "Barraging..."
        end
    elseif barrageLabel and activeMode~="Barrage" then
        barrageLabel.Text="Inactive"; barrageActive=false
    end


    if attracting then
        attractTimer+=1/60
        if attractTimer>=2 then attracting=false; attractTimer=0 end
    end


    if activeMode=="Minigun" and #selectedParts > 0 then
        if minigunIdx > #selectedParts then minigunIdx = 1 end
        if minigunIdx ~= minigunLastIdx then
            minigunShotStart = tick()
            minigunLastIdx = minigunIdx
        end
        local now      = tick()
        local firePart = selectedParts[minigunIdx]
        local reached  = false
        if firePart and firePart.Parent then
            local reachDist = math.max(5, firePart.Size.Magnitude * 1.25)
            reached = (firePart.Position - currentMouseHit).Magnitude < reachDist
        end
        local stuck = (now - minigunShotStart) >= MINIGUN_STUCK
        if reached or (stuck and firePart and firePart.Parent) then
            minigunIdx = (minigunIdx % #selectedParts) + 1
        end
    elseif minigunLastIdx ~= 0 then
        minigunLastIdx = 0
    end


    if activeMode=="Satellite" then
        local now = tick()
        for p, fireTime in pairs(satFired) do
            if p and p.Parent then
                local vel = p.AssemblyLinearVelocity
                local speed = vel.Magnitude
                if speed > 1200 then
                    p.AssemblyLinearVelocity = vel * (1200 / speed)
                end
                if (now - fireTime) > SAT_TTL
                    or (p.Position - satTarget).Magnitude < 3 then
                    satFired[p] = nil
                    if satTouchConns[p] then
                        pcall(function() satTouchConns[p]:Disconnect() end)
                        satTouchConns[p] = nil
                    end
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
            impactBurst(lightningTarget, 30, 9500)
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
            impactBurst(sniperTargetPos, 24, 16000)
        end
        if sniperBoomStage < 2 and age >= 0.62 then
            sniperBoomStage = 2
            impactBurst(sniperTargetPos, 14, 26000)
        end
        if not sniperCaught and age >= 0.5 then
            sniperCaught = true
            for _, p in ipairs(selectedParts) do
                pcall(function()
                    local ap = getNetAP(p); if ap then ap.Enabled = true end
                    local ao = getNetAO(p); if ao then ao.Enabled = true end
                    p.AssemblyLinearVelocity = Vector3.new(15, 15, 15)
                end)
            end
        end
        if age > SNIPER_CYCLE and next(sniperTouchConns) then
            for p, c in pairs(sniperTouchConns) do
                pcall(function() c:Disconnect() end)
            end
            sniperTouchConns = {}
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
            if age >= STRIKE_DESCEND then
                strikeState = "drill"
                strikeStart = tick()
                strikePulse = 0
                impactBurst(strikeTarget, 28, 7200)
            end
        elseif strikeState == "drill" then
            if age >= STRIKE_DRILL then
                strikeState = "return"
                strikeStart = tick()
            elseif age - strikePulse >= 0.28 then
                strikePulse = age
                impactBurst(strikeTarget, 24, 6400)
            end
        elseif strikeState == "return" and age >= STRIKE_RETURN then
            strikeState = "idle"
        end
    end

    if activeMode=="Scythe" then
        if scytheState=="swing" and (tick() - scytheStart) >= SCYTHE_SWING then
            scytheState = "idle"
            for p,c in pairs(scytheConns) do pcall(function() c:Disconnect() end) end
            scytheConns = {}
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

    for i=#selectedParts,1,-1 do
        local part=selectedParts[i]
        if not part or not part.Parent then
            removeHL(part); table.remove(selectedParts,i); frozenTargets[part]=nil; partTargets[part]=nil
        else
            local tgt
            if frozenTargets[part] then
                tgt = frozenTargets[part]
            elseif frozen then
                if not frozenTargets[part] then frozenTargets[part] = part.Position end
                tgt = frozenTargets[part]
            else
                tgt = getTarget(i, total, part, t)
            end

                if unfreezeBoost[part] then
                    if tick() < unfreezeBoost[part] then
pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
                        pcall(function()
                            local ap = getNetAP(part)
                            if ap then
                                ap.Enabled = true
                                ap.MaxForce = math.huge
                                ap.MaxVelocity = math.huge
                                ap.Position = tgt
                            end
                            local ao = getNetAO(part)
                            if ao then
                                ao.Enabled = true
                                ao.MaxTorque = math.huge
                            end
                            part.AssemblyLinearVelocity = Vector3.new(15, 15, 15)
                        end)
                    else
                        unfreezeBoost[part] = nil
                    end
                end

                local dist=(tgt-part.Position).Magnitude
                local targetRotation = part.CFrame
                local responsiveness = getMoveResponsiveness(1)


                if isMG and i==minigunIdx then
                    responsiveness = getMoveResponsiveness(4.8)
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

                if isSniper and (tick() - sniperFireTime) < SNIPER_CYCLE then
                    responsiveness = getMoveResponsiveness(40)
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


                if isDV2 then
                    local AP = getNetAP(part)
                    if AP then AP.Enabled = true end
                    local AO = getNetAO(part)
                    if AO then AO.Enabled = true end

                    if not partTargets[part] then partTargets[part] = {} end

                    if dv2Target and dv2Target.Parent then
                        local targetVel = dv2Target.AssemblyLinearVelocity
                        local planarVel = Vector3.new(targetVel.X, 0, targetVel.Z)
                        local planarLook = Vector3.new(dv2Target.CFrame.LookVector.X, 0, dv2Target.CFrame.LookVector.Z)
                        local lookBase = planarVel.Magnitude > 10 and planarVel.Unit or planarLook
                        if lookBase.Magnitude < 0.001 then
                            local fallbackDir = Vector3.new(part.Position.X - dv2Target.Position.X, 0, part.Position.Z - dv2Target.Position.Z)
                            lookBase = fallbackDir.Magnitude > 0.001 and fallbackDir.Unit or Vector3.new(0, 0, -1)
                        else
                            lookBase = lookBase.Unit
                        end
                        local attackClock = t * 34 + i * 1.05
                        local passSign = math.sin(attackClock) >= 0 and 1 or -1
                        local passDistance = 4.2 + math.sin(attackClock * 0.7) * 0.9
                        local passOffset = lookBase * (passDistance * passSign)
                        local verticalOffset = Vector3.new(0, math.cos(attackClock * 2.1) * 0.45, 0)
                        local leadOffset = planarVel.Magnitude > 0 and planarVel.Unit * math.min(planarVel.Magnitude * 0.012, 2.5) or Vector3.zero
                        tgt = dv2Target.Position + passOffset + verticalOffset + leadOffset

                        responsiveness = math.max(responsiveness, 200)
                        partTargets[part].rotResponsiveness = 200

                        local diff = tgt - part.Position
                        local dist = diff.Magnitude
                        local targetGap = (part.Position - dv2Target.Position).Magnitude
                        if targetGap > 140 then
                            tgt = dv2Target.Position - lookBase * 3.5
                            diff = tgt - part.Position
                            dist = diff.Magnitude
                        end
                        if dist > 0.05 then
                            targetRotation = CFrame.lookAt(part.Position, tgt)
                            part.AssemblyLinearVelocity = diff.Unit * math.min(1350, math.max(420, dist * 34))
                        else
                            part.AssemblyLinearVelocity = Vector3.zero
                        end

                        if dist < 18 then
                            local attackDir = dist > 0.001 and diff.Unit or part.CFrame.LookVector
                            local spinDir = Vector3.new(-attackDir.Z, 0, attackDir.X)
                            local closeAlpha = 1 - math.clamp(dist / 18, 0, 1)
                            local flingBoost = flingForce * (8.0 + closeAlpha * 14.0)
                            local spinBoost = flingForce * (5.0 + closeAlpha * 9.0)

                            pcall(function()
                                dv2Target.AssemblyLinearVelocity = dv2Target.AssemblyLinearVelocity
                                    + attackDir * flingBoost
                                    + spinDir * spinBoost
                                    + Vector3.new(0, flingForce * (2.0 + closeAlpha * 2.6), 0)
                                dv2Target.AssemblyAngularVelocity = dv2Target.AssemblyAngularVelocity
                                    + Vector3.new(
                                        (math.random() - 0.5) * spinBoost * 3.8,
                                        flingForce * (11.0 + closeAlpha * 12.0),
                                        (math.random() - 0.5) * spinBoost * 3.8
                                    )
                            end)
                        end
                        part.AssemblyAngularVelocity = Vector3.new(
                            math.sin(t * 9.2 + i) * 420,
                            math.cos(t * 8.4 + i * 1.3) * 520,
                            math.sin(t * 9.8 + i * 0.7) * 420
                        )
                    else
                        pcall(sethiddenproperty, part, "PhysicsRepRootPart", nil)
                    end

                    partTargets[part].position = tgt
                    partTargets[part].rotation = targetRotation
                    partTargets[part].responsiveness = responsiveness
                    syncAlignTarget(part, partTargets[part])
                elseif isHoming then
                    if homingTarget and homingTarget.Parent and tick() < homingEndTime then
                        local diff = tgt - part.Position
                        local dist = diff.Magnitude
                        if dist > 0.05 then
                            local AP = getNetAP(part)
                            if AP then AP.Enabled = false end
                            local AO = getNetAO(part)
                            if AO then AO.Enabled = false end
                            part.AssemblyLinearVelocity = diff.Unit * 350
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
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                        pcall(sethiddenproperty, part, "PhysicsRepRootPart", nil)
                    end
                elseif isRail and railgunFired then
                    pcall(function()
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
                elseif isSniper and not sniperCaught then
                    pcall(function()
                        local ap = getNetAP(part); if ap then ap.Enabled = true end
                        local ao = getNetAO(part); if ao then ao.Enabled = false end
                        if not partTargets[part] then partTargets[part] = {} end
                        partTargets[part].position = tgt
                        partTargets[part].responsiveness = getMoveResponsiveness(50)
                        syncAlignTarget(part, partTargets[part])
                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 3e5,
                            (math.random() - 0.5) * 3e5,
                            (math.random() - 0.5) * 3e5)
                    end)
                elseif isBarr then
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 3000,
                            (math.random() - 0.5) * 3000,
                            (math.random() - 0.5) * 3000
                        )
                        part.AssemblyLinearVelocity = Vector3.zero

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
                                        part.AssemblyLinearVelocity = burstDir.Unit * 88000 + Vector3.new(
                                            (math.random() - 0.5) * 1500,
                                            (math.random() - 0.5) * 1500,
                                            (math.random() - 0.5) * 1500
                                        )
                                    else
                                        part.AssemblyLinearVelocity = Vector3.new(
                                            (math.random() - 0.5) * 1500,
                                            (math.random() - 0.5) * 1500,
                                            (math.random() - 0.5) * 1500
                                        )
                                    end
                                end)

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
                        if ap then ap.MaxForce = math.huge; ap.MaxVelocity = math.huge; ap.Responsiveness = 420; ap.Enabled=true end
                        local ao = getNetAO(part)
                        if ao then ao.MaxTorque = math.huge; ao.MaxAngularVelocity = math.huge; ao.Responsiveness = 260; ao.Enabled=true end
                        part.AssemblyLinearVelocity = Vector3.new(15,15,15)
                    end)
                elseif isText then
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local look0 = root and root.CFrame.LookVector or Vector3.new(0,0,-1)
                    local lookDir = Vector3.new(look0.X, 0, look0.Z)
                    if lookDir.Magnitude < 0.01 then lookDir = Vector3.new(0,0,-1) else lookDir = lookDir.Unit end
                    local upDir = Vector3.new(0,1,0)
                    local ang = textPartAngles[part] or 0
                    targetRotation = CFrame.lookAt(tgt, tgt + lookDir, upDir) * CFrame.Angles(0, 0, math.rad(ang))
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
                    end)
                else
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.zero
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = targetRotation
                        partTargets[part].responsiveness = responsiveness
                        syncAlignTarget(part, partTargets[part])
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

local function isNPCModel(model)
    if model == LP.Character then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then return false end
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

        local d = (tr.Position - myPos).Magnitude

        local willAffect = (killAura and d <= killAuraRange) or (sitAura and d <= sitAuraRange) or (jumpAura and d <= jumpAuraRange) or (followAura and d <= followAuraRange) or (freezeAura and d <= freezeAuraRange) or (speedAuraEnabled and d <= speedAuraRange) or (spinAuraEnabled and d <= spinAuraRange)
        if willAffect then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    pcall(reinforceOwnershipConstraints, part, nil)
                    pcall(reinforceOwnershipHeartbeat, part, nil)
                    local origVel = part.AssemblyLinearVelocity
                    part.AssemblyLinearVelocity = Vector3.new(15, 15, 15)
                    part.AssemblyLinearVelocity = origVel
                    part.AssemblyLinearVelocity = Vector3.new(-15, -15, -15)
                    part.AssemblyLinearVelocity = origVel
                    part.AssemblyLinearVelocity = Vector3.new(15, -15, 15)
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
                            if rootPart.AssemblyLinearVelocity then
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
                if dir.Magnitude > 0.01 then
                    pcall(function()
                        tr.AssemblyLinearVelocity = tr.AssemblyLinearVelocity + dir.Unit * 10
                    end)
                end
            end
        end


        if spinAuraEnabled and d <= spinAuraRange then

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
                    if hrp then
                        pcall(function()
                            hrp.AssemblyLinearVelocity = dir.Unit * GRAB_TOSS_POWER + Vector3.new(0, 20, 0)
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
    P.BG      = Color3.fromRGB(12,  8, 14)
    P.SURFACE = Color3.fromRGB(22, 14, 26)
    P.BORDER  = Color3.fromRGB(62, 38, 66)
    P.TBAR    = Color3.fromRGB(28, 16, 34)
    P.ACC     = Color3.fromRGB(215, 125, 168)
    P.ACC2    = Color3.fromRGB(148,  92, 128) 
    P.B_DEF   = Color3.fromRGB(36,  22, 42)
    P.B_RED   = Color3.fromRGB(158,  30, 48)
    P.B_GRN   = Color3.fromRGB( 22,  90, 46)
    P.B_YEL   = Color3.fromRGB(115,  80, 18)
    P.B_BLU   = Color3.fromRGB( 28,  48, 105)
    P.DV2C    = Color3.fromRGB(205,  62, 18)
    P.T1      = Color3.fromRGB(242, 212, 228)
    P.T2      = Color3.fromRGB(152, 106, 138)
    P.T3      = Color3.fromRGB( 88,  58,  82)
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
    globalOwnership = false
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
    stampGui(b); b.Parent=parent; corner(b,4)
    local base=b.BackgroundColor3
    b.MouseEnter:Connect(function() b.BackgroundColor3=base:Lerp(Color3.new(1,1,1),.09) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3=base end)
    return b
end

function mkTab(props,parent)
    local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.BorderSizePixel=0
    for k,v in pairs(props) do b[k]=v end
    stampGui(b); b.Parent=parent; corner(b,4)
    return b
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
    local lbl=mkL({Size=UDim2.new(1,-8,0,16),Position=UDim2.new(0,8,0,3),
        Text=ltext.."  "..formatValue(def),TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left},wrap)
    local track=mkF({Size=UDim2.new(1,-16,0,4),Position=UDim2.new(0,8,0,28),
        BackgroundColor3=PAL.BORDER},wrap)
    corner(track,3)
    local r0=(def-lo)/(hi-lo)
    local fill=mkF({Size=UDim2.new(r0,0,1,0),BackgroundColor3=PAL.ACC},track); corner(fill,3)
    local thumb=mkB({Size=UDim2.new(0,11,0,11),Position=UDim2.new(r0,-5,0.5,-5),
        BackgroundColor3=Color3.fromRGB(195,195,210),Text="",ZIndex=GUI.Z+8},track)
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local sl=false
    local lastValue=def
    local lastMouseX=nil
    thumb.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            sl=true
            lastMouseX=i.Position.X
        end
    end)
    reg(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            sl=false
            lastMouseX=nil
        end
    end))
    reg(UserInputService.InputChanged:Connect(function(i)
        if not sl or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local ap=track.AbsolutePosition; local as=track.AbsoluteSize
        local r=math.clamp((i.Position.X-ap.X)/as.X,0,1)
        local raw=lo+(hi-lo)*r
        local isF=(hi-lo)<=5
        local val
        if step and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
            local deltaX=i.Position.X-(lastMouseX or i.Position.X)
            val=math.clamp(lastValue+deltaX*step,lo,hi)
            val=lo+math.floor((val-lo)/step+0.5)*step
        elseif step then
            val=lo+math.floor((raw-lo)/step+0.5)*step
            val=math.clamp(val,lo,hi)
        else
            val=isF and (math.floor(raw*10)/10) or math.floor(raw)
        end
        local valueRatio=(val-lo)/(hi-lo)
        fill.Size=UDim2.new(valueRatio,0,1,0); thumb.Position=UDim2.new(valueRatio,-5,0.5,-5)
        lbl.Text=ltext.."  "..formatValue(val); if onChange then onChange(val) end
        lastValue=val
        lastMouseX=i.Position.X
    end))
    return wrap
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

    local MinBtn = buildTitleBarButtons(TBar)

    return TBar, MinBtn
end

function setupDrag(Main, TBar)
    local dragging,dStart,dOrigin=false,nil,nil
    reg(TBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dStart=inp.Position; dOrigin=Main.Position
        end
    end))
    reg(UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-dStart
            Main.Position=UDim2.new(dOrigin.X.Scale,dOrigin.X.Offset+d.X,dOrigin.Y.Scale,dOrigin.Y.Offset+d.Y)
        end
    end))
    reg(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end))
end


function buildBody(Main, MinBtn, W, H, MINI, ResizeHandle)
    local Body=mkF({Size=UDim2.new(1,0,1,-MINI),Position=UDim2.new(0,0,0,MINI),BackgroundTransparency=1},Main)
    local minimized=false
    MinBtn.MouseButton1Click:Connect(function()
        minimized=not minimized; Body.Visible=not minimized
        Main.Size=UDim2.new(0,W,0,minimized and MINI or H); MinBtn.Text=minimized and "+" or "-"
        if ResizeHandle then
            ResizeHandle.Visible = Body.Visible
        end
    end)
    return Body, minimized
end


function buildMainFrame()
    local W,H,MINI=440,560,42

    local Main=mkF({Name="Main",Size=UDim2.new(0,W,0,H),
        Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=PAL.BG,ZIndex=GUI.Z},ScreenGui)
    corner(Main,8)

    local shdw=mkF({Size=UDim2.new(1,10,1,10),Position=UDim2.new(0,-5,0,5),
        BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.58,ZIndex=GUI.Z-1},Main)
    corner(shdw,11)

    local TBar, MinBtn = buildTitleBar(Main, MINI)
    setupDrag(Main, TBar)
    local ResizeHandle = Instance.new("TextButton")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
    ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
    ResizeHandle.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
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
    

    ResizeHandle.Visible = Body.Visible

    local resizing = false
    local resizeStart = Vector2.new()
    local startSize = Vector2.new(W, H)

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = Vector2.new(input.Position.X, input.Position.Y)
            startSize = Vector2.new(Main.AbsoluteSize.X, Main.AbsoluteSize.Y)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local currentPos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = currentPos - resizeStart
            local newSize = startSize + delta
            local clampedWidth = math.clamp(newSize.X, 300, 1200)
            local clampedHeight = math.clamp(newSize.Y, 400, 900)
            Main.Size = UDim2.new(0, clampedWidth, 0, clampedHeight)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
            mTabBtns[n].TextColor3=on and Color3.fromRGB(8,8,12) or PAL.T2
            if mPanels[n] then mPanels[n].Visible=on end
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
            sTabBtns[n].TextColor3=on and Color3.fromRGB(8,8,12) or PAL.T2
            if sPanels[n] then sPanels[n].Visible=on end
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

        local clickSelBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Click-Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=2},selP)
        clickSelBtn.MouseButton1Click:Connect(function()
            clickSelActive = not clickSelActive
            clickSelBtn.BackgroundColor3 = clickSelActive and Color3.fromRGB(18,55,24) or PAL.B_DEF
            clickSelBtn.TextColor3 = clickSelActive and Color3.fromRGB(110,210,130) or PAL.T1
            local base = "Click-Select: "..(clickSelActive and "ON" or "OFF")
            if buttonKeybinds[clickSelBtn] and buttonKeybinds[clickSelBtn].originalText then
                base = base .. " [" .. buttonKeybinds[clickSelBtn].key.Name .. "]"
            end
            clickSelBtn.Text = base
        end)

        local selectAllBtn, selectInRangeBtn = (function()
            local row,b1,b2=mkRow2(selP,3,
                {BackgroundColor3=PAL.B_DEF,Text="All",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham},
                {BackgroundColor3=PAL.B_DEF,Text="In Range",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham})
            b1.MouseButton1Click:Connect(function() selectAll() end)
            b2.MouseButton1Click:Connect(function() selectInRange(autoSelRange) end)
            return row,b1,b2
        end)()

        local selectUnweldedBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="select NDS unanchored",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},selP)
        selectUnweldedBtn.MouseButton1Click:Connect(function() selectFakeAnchored() end)

        local selectNDSRangeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Range Select NDS unanchored",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=5},selP)
        selectNDSRangeBtn.MouseButton1Click:Connect(function() selectNDSInRange(autoSelRange) end)

        local autoAllBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Auto Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=6},selP)
        local autoNearBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Auto Near Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},selP)

        local function refreshAutoSelectButtons()
            autoAllBtn.BackgroundColor3 = autoSelectAll and Color3.fromRGB(18,55,24) or PAL.B_DEF
            autoAllBtn.TextColor3 = autoSelectAll and Color3.fromRGB(110,210,130) or PAL.T1
            autoAllBtn.Text = "Auto Select: "..(autoSelectAll and "ON" or "OFF")

            autoNearBtn.BackgroundColor3 = autoSelectNear and Color3.fromRGB(22,38,75) or PAL.B_DEF
            autoNearBtn.TextColor3 = autoSelectNear and Color3.fromRGB(130,175,255) or PAL.T1
            autoNearBtn.Text = "Auto Near Select: "..(autoSelectNear and "ON" or "OFF")
        end

        autoAllBtn.MouseButton1Click:Connect(function()
            autoSelectAll = not autoSelectAll
            if autoSelectAll then
                autoSelectNear = false
                runAutoSelectScan()
            end
            refreshAutoSelectButtons()
        end)

        autoNearBtn.MouseButton1Click:Connect(function()
            autoSelectNear = not autoSelectNear
            if autoSelectNear then
                autoSelectAll = false
                runAutoSelectScan()
            end
            refreshAutoSelectButtons()
        end)

        mkSlider(selP,"Sel Range",5,300,autoSelRange,7,function(v) autoSelRange=v end)

        local clearBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_RED,
            Text="Clear Selection",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=8},selP)
        clearBtn.MouseButton1Click:Connect(function()
            autoSelectAll = false
            autoSelectNear = false
            spcPart = nil
            clearSelection(false)
            refreshAutoSelectButtons()
        end)
        refreshAutoSelectButtons()

        return selInfo, clickSelBtn, clearBtn, refreshAutoSelectButtons, selectAllBtn, selectInRangeBtn, selectUnweldedBtn, selectNDSRangeBtn
    end


    local function buildFormationSection(selP)
        mkDiv(selP,8)
        mkSec("FORMATION", selP, 9)

        local freezeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Formation Freeze: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=10},selP)
        freezeBtn.MouseButton1Click:Connect(function()
            frozen=not frozen
            if not frozen then
                local boostUntil = tick() + 0.75
                for _, p in ipairs(selectedParts) do unfreezeBoost[p] = boostUntil end
            end
            frozenTargets={}
            freezeBtn.BackgroundColor3=frozen and Color3.fromRGB(22,38,75) or PAL.B_DEF
            freezeBtn.TextColor3=frozen and Color3.fromRGB(130,175,255) or PAL.T1
            local base = "Formation Freeze: "..(frozen and "ON" or "OFF")
            if buttonKeybinds[freezeBtn] and buttonKeybinds[freezeBtn].originalText then
                base = base .. " [" .. buttonKeybinds[freezeBtn].key.Name .. "]"
            end
            freezeBtn.Text=base
        end)

        local attractBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Attract to Self (2s)",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=11},selP)
        attractBtn.MouseButton1Click:Connect(function() attracting=true; attractTimer=0 end)

        return freezeBtn
    end

    local function buildOwnershipSection(selP)
        mkDiv(selP,12)
        mkSec("OWNERSHIP", selP, 13)

        local gOwnBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Global Ownership: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=14},selP)
        gOwnBtn.MouseButton1Click:Connect(function()
            globalOwnership=not globalOwnership
            gOwnBtn.BackgroundColor3=globalOwnership and Color3.fromRGB(22,38,75) or PAL.B_DEF
            gOwnBtn.TextColor3=globalOwnership and Color3.fromRGB(130,175,255) or PAL.T1
            gOwnBtn.Text="Global Ownership: "..(globalOwnership and "ON" or "OFF")
        end)
        gOwnBtn.BackgroundColor3=globalOwnership and Color3.fromRGB(22,38,75) or PAL.B_DEF
        gOwnBtn.TextColor3=globalOwnership and Color3.fromRGB(130,175,255) or PAL.T1
        gOwnBtn.Text="Global Ownership: "..(globalOwnership and "ON" or "OFF")

        mkSlider(selP,"Owner Radius",10,300,ownerRadius,15,function(v) ownerRadius=v end)

        local fakeColBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Fake Collisions: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},selP)
        fakeColBtn.MouseButton1Click:Connect(function()
            fakeCollisions=not fakeCollisions
            fakeColBtn.BackgroundColor3=fakeCollisions and Color3.fromRGB(22,38,75) or PAL.B_DEF
            fakeColBtn.TextColor3=fakeCollisions and Color3.fromRGB(130,175,255) or PAL.T1
            fakeColBtn.Text="Fake Collisions: "..(fakeCollisions and "ON" or "OFF")

            for _, part in ipairs(selectedParts) do
                if fakeCollisions then
                    pcall(function() disableSelectedCollision(part) end)
                else
                    pcall(function() restoreSelectedCollision(part) end)
                end
            end
        end)
        fakeColBtn.BackgroundColor3=fakeCollisions and Color3.fromRGB(22,38,75) or PAL.B_DEF
        fakeColBtn.TextColor3=fakeCollisions and Color3.fromRGB(130,175,255) or PAL.T1
        fakeColBtn.Text="Fake Collisions: "..(fakeCollisions and "ON" or "OFF")
    end

        local selInfo, clickSelBtn, clearBtn, _refreshAutoSel, selectAllBtn, selectInRangeBtn, selectUnweldedBtn, selectNDSRangeBtn = buildSelSubPanel(spCont, sPanels)
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


        local mGrid=mkF({Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,LayoutOrder=1},modSF)
        local mgL=Instance.new("UIGridLayout",mGrid)
        local cellW=math.floor((W-18-9)/4)
        mgL.CellSize=UDim2.new(0,cellW,0,26); mgL.CellPadding=UDim2.new(0,3,0,3)
        mgL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            mGrid.Size=UDim2.new(1,0,0,mgL.AbsoluteContentSize.Y)
        end)

        local MODE_CAT = { -- i love cats i swear
            Tornado="red", Ring="blue", Orbit="blue", Spiral="blue", Wave="blue", Halo="blue",
            Drone="red", DroneV2="red", Shield="green", Comet="blue", Wall="green",
            Draw="blue", Beam="blue", Sphere="blue", Vortex="red", DNA="yellow", Pulse="blue", Grid="blue", Cube="green",
            Scatter="blue", Star="yellow", Pendulum="yellow", Rain="blue", Galaxy="yellow", Blackhole="red", Lemniscate="yellow", Blender="red",
            Crown="green", Swarm="blue", Minigun="red", Satellite="red",
            Seek="blue", Stickman="black", Slinky="blue", Fountain="blue", Bounce="blue", Ripple="blue", Juggle="blue", Constellation="yellow",
            Rose="yellow", OrbitSin="yellow", Liss="yellow", Swing="blue", Aura="blue", Homing="red", Railgun="red", Barrage="red",
            Sinewave="yellow", Heart="green", Wings="green", Crystal="yellow", TwinStars="yellow", Tesseract="yellow", Atom="yellow", Lightning="red",
            Sniper="red", Bridge="green", Strike="red", Boomerang="red",
            Text="green", Scythe="red", Pentagram="green",
            Chained="red", -- penisdingalingswingmode = "pink"
        }
        local CAT_COL = {
            red    = {bg=Color3.fromRGB(50,16,16), bgOn=Color3.fromRGB(148,30,30), tx=Color3.fromRGB(235,85,85)},
            blue   = {bg=Color3.fromRGB(16,24,50), bgOn=Color3.fromRGB(38,70,148), tx=Color3.fromRGB(110,145,235)},
            green  = {bg=Color3.fromRGB(16,40,16), bgOn=Color3.fromRGB(38,110,38), tx=Color3.fromRGB(110,195,110)},
            yellow = {bg=Color3.fromRGB(50,44,10), bgOn=Color3.fromRGB(168,148,30), tx=Color3.fromRGB(235,210,85)},
            black  = {bg=Color3.fromRGB(14,14,14), bgOn=Color3.fromRGB(38,38,38), tx=Color3.fromRGB(225,225,225)},
        }
        local MODE_DESC = {
            Mouse="Mouse\nTarget: Formation Target (default Mouse) - change in Modes > Formation Target\nParts cluster around Target plus offset*2.5 + up 1*scY\nControls: Move Target (move mouse by default, or set Formation Target to Player/ClosestNPC/ClickArea/Anchor/ClickedPlayer)\nMath: pos = Target + offset*2.5",
            Tornado="Tornado\nTarget: Formation Target - 6-band helical column with skirt, height = ceil(total/6)*2.2*scY\nControls: Move Target\nMath: band=(idx-1)%6 h=floor((idx-1)/6)*2.2*scY hf=h/totalH spin=band/6*2pi+t*tornadoSpeed*(1.25-hf*0.5) r=(3+sin)*rMax*(1-0.55*hf)*skirt",
            Ring="Ring\nTarget: Formation Target - single horizontal ring\nControls: Move Target\nMath: r=max(total*0.45,formRadius)*rMax a=angle+t*1 y=1.5*scY+sin(t*1.2)*0.4",
            Orbit="Orbit\nTarget: Formation Target - tilted orbit with vertical bob\nControls: Move Target\nMath: a=angle+t*3.2 vOff=sin(a*2+idx)*4*scY pos= Target+cos(a)*orbitRadius*scX, y=4*scY+vOff",
            Spiral="Spiral\nTarget: Formation Target - flat spiral rising\nControls: Move Target\nMath: a=ratio*2.5*2pi+t*1.2 r=ratio*8*maxSc y=ratio*spiralHeight*scY",
            Wave="Wave\nTarget: Formation Target - sine wave line along X\nControls: Move Target\nMath: x=(ratio-.5)*total*1.3*scX wY=sin(ratio*5pi+t*5)*waveAmp*scY wZ=cos(ratio*3pi+t*3)*1.2*scZ",
            Halo="Halo\nTarget: Around Player (not Formation Target) at 7*scY above root\nControls: Auto orbit around you\nMath: r=max(total*0.4,formRadius)*rMax a=angle+t*0.7 pos=rp.X+cos(a)*r*scX, y=rp.Y+7*scY+sin(t*2.2)*0.3",
            Drone="Drone\nTarget: Formation Target - jittery cloud + drift around Target\nControls: Move Target\nMath: pos=Target+off*1.8*sc + drift sin/cos*2 + up 4*scY",
            DroneV2="DroneV2\nTarget: Auto nearest player/NPC within flingRange, else orbit\nControls: Auto seek\nMath: passOffset=look*4.2*sign(sin(attackClock)) vertical cos*0.45 lead=vel*0.012 flingBoost=flingForce*8+close*14",
            Shield="Shield\nTarget: Around Player - Fibonacci sphere\nControls: Auto around you\nMath: phi=(1+sqrt5)/2 theta=2pi*i/phi cosY=-0.2+ (i/total)*1.2 r=(formRadius+0.5)*scR",
            Comet="Comet\nTarget: Your movement history (trail behind you)\nControls: Move character\nMath: cometHistory push if dist>0.45-0.8 histIdx = #history - ratio*trailLen",
            Wall="Wall\nTarget: In front of Player (wallDist in look dir, not Formation Target)\nControls: Face direction, wallDist/wallGap sliders pack by size via _wallSlots()\nMath: center=rp+look*wallDist*maxSc right*slot.r + up*slot.u",
            Draw="Draw\nTarget: Your drawn trail (mouse trail while holding)\nControls: Hold Mouse1 in Draw to draw path, Clear Draw Trail to reset\nMath: sampleDrawTrailPoint splits total across trails, lerp trail segment",
            Beam="Beam\nTarget: Line from Player to Formation Target - double helix\nControls: Move Target (beam follows)\nMath: start=rp+2*scY dir=Target-start dist=|dir| strand 0/1 turns=max(dist/6,2) aa=ratio*turns*2pi+t*6+strand*pi r=0.6+0.9*sin(ratio*pi)",
            Sphere="Sphere\nTarget: Formation Target - Fibonacci sphere, flat Y scale 0.28\nControls: Move Target\nMath: yLatScale 0.28 rx=formRadius*scX ry=formRadius*scY rz=formRadius*scZ pos=Target+ sinY*cos(theta+t*0.4)*rx etc y=cosY*ry*0.28",
            Vortex="Vortex\nTarget: Formation Target - inverted tornado (narrowing upward)\nControls: Move Target\nMath: spin=band/6*2pi -t*tornadoSpeed*2 r=(1+h/maxR*0.35)*maxR y=Target.Y+14*scY-h clamped",
            DNA="DNA\nTarget: Formation Target - double helix vertical 12*scY tall\nControls: Move Target\nMath: strand (idx%2) pr=pos/2 a=pr*3*2pi+t*1.6+strand*pi r=3*scR h=pr*12*scY",
            Pulse="Pulse\nTarget: Formation Target - expanding/contracting ring\nControls: Auto pulse\nMath: pulseR=formRadius*(1+sin(t*6)*0.45)*maxSc a=angle y=2*scY+sin(t*6)*0.5",
            Grid="Grid\nTarget: Formation Target - flat grid at Target y+4*scY\nControls: Move Target\nMath: cols=ceil(sqrt(total)) col=(idx%cols)-(cols-1)/2 row=floor(idx/cols) spacing=part.Size.X+wallGap",
            Cube="Cube\nTarget: Formation Target + 4*scY up, rotating cube edges\nControls: Move Target (cube follows)\nMath: 8 verts -1/1, 12 edges, perEdge=ceil(total/12) tEdge lerp, half=max(formRadius,2) rot Angles(t*0.45,t*0.32)",
            Scatter="Scatter\nTarget: Formation Target - expand/contract to far cloud\nControls: Auto\nMath: scatter=(sin(t*1.5)+1)/2 far=Target+off*14*scX+up*4*scY pos=Target:Lerp(far,scatter)",
            Star="Star\nTarget: Formation Target - 2 radii alternating point/inner\nControls: Move Target\nMath: isPoint=(idx%2==0) sAngle= spoke*2pi+ t*0.6 r=isPoint?formRadius*2:0.75",
            Pendulum="Pendulum\nTarget: Formation Target - swinging pendulum line\nControls: Auto\nMath: swing=sin(t*4+idx*0.55)*formRadius*scX dip=-(1-cos)*0.5*formRadius*scY",
            Rain="Rain\nTarget: Formation Target X/Z, Y is falling loop to ground\nControls: Move Target X/Z\nMath: topY=Target.Y+14*scY floorY=getGroundYAt(x,z) dropHeight=top-floor fall=(t*38+phase)%dropHeight y=top-fall",
            Galaxy="Galaxy\nTarget: Formation Target - 3-arm spiral\nControls: Move Target\nMath: arm=(idx-1)%3 ar=posInArm/(perArm-1) spiral=arm/3*2pi+ar*2.5pi+t*0.8 r=ar*formRadius*2 tilt sin*0.35*scY",
            Blackhole="Blackhole\nTarget: Formation Target - collapse then spin out\nControls: Auto cycle 1.5s\nMath: cycle=t*1.5%1 pull=1-cycle*2.2 r=formRadius*pull spin=angle -t*10*(1.2-pull*0.9) h=pull*4",
            Lemniscate="Lemniscate\nTarget: Formation Target - figure-8 infinity\nControls: Move Target\nMath: phase=ratio*2pi+t*1.3 denom=1+sin(phase)^2 a=formRadius*1.6*scR x=a*cos/denom z=a*sin*cos/denom y=sin*0.55*scY",
            Blender="Blender\nTarget: Formation Target - random axis spin per offset\nControls: Move Target\nMath: axis=sin(off*3.14) spd=5.6+idx%7*0.25 r=formRadius*maxR pos=Target+up 3*scY + p1*cos* r + p2*sin*r",
            Crown="Crown\nTarget: Around Player (rp) - spiked ring + inner ring\nControls: Auto around you\nMath: isSpike=(idx%2==0) a=spoke*2pi+t*0.24 r=formRadius outer 2x inner 0.65 y 10*scY /7*scY",
            Swarm="Swarm\nTarget: Formation Target - wander + jitter\nControls: Move Target\nMath: wander sin*formRadius + jitter sin*18*0.7",
            Minigun="Minigun\nTarget: Formation Target for firing, rest queue behind player\nControls: Auto cycles\nMath: firing idx=minigunIdx at Target, others behind -look* (5+row*2) + right*col*1.6 cycles when dist<reach or 12s",
            Satellite="Satellite\nTarget: High orbit 20*scY around player, on click fire cluster to Formation Target\nControls: Click to set satTarget (mouse)\nMath: idle ring 3.5*scX high 20*scY, fire vel 1000+ burst 8000, TTL 2s",
            Seek="Seek\nTarget: Nearest NPC within 200 else Formation Target\nControls: Auto chase\nMath: getNearestNPC 200 if found -> npcRoot+offset*0.5 else Target+offset",
            Stickman="Stickman/Billy\nFull stick figure with face, walk, arms, beam, dance, crawl\nTarget: Around Player\nControls:\n Move = walk (walkPhase+=dt*spd*0.35*sgn)\n J = switch arm\n T = TPose\n P = slap 0.5s burst\n C = beam hold\n Y = wave 1.9s\n U = dance toggle\n Z = crawl toggle\n Q = face mode 0-4\n Mouse = aim arm\nMath:\n walkPhase+=dt*spd*0.35*sgn\n u head 0.10-0.22 torso 0.22-0.37 arms 0.37-0.73 legs 0.73-1\n head/face tilt to mouse, legs sin/cos walk, face 10 parts eyes/brows/mouth",
            Slinky="Slinky\nTarget: Mouse trail history (like Comet but spaced by formRadius)\nControls: Move mouse to leave slinkyHistory\nMath: step=index*(formRadius*0.35+1.5) idx=#history-step pos=history[idx]+off*0.35",
            Fountain="Fountain\nTarget: Formation Target - parabolic jets up from Target\nControls: Move Target\nMath: jet=(t*4.4+ratio*1.8)%1 h=sin(jet*pi)*formRadius*2.8 +1.5*scY off*formRadius*0.35",
            Bounce="Bounce\nTarget: Lerp between Formation Target and player 7*scY\nControls: Auto\nMath: phase=t*2.8+idx*0.12 alpha=phase<1?phase:2-phase pos=Target:Lerp(rp+7*scY,alpha)",
            Ripple="Ripple\nTarget: Formation Target - expanding waves per part\nControls: Move Target\nMath: waveR=(t*4.8-idx*0.18)%(formRadius*2.2*maxR+1)+1 a=angle+t*0.5 pos=Target+cos(a)*waveR*scX",
            Juggle="Juggle\nTarget: Formation Target - toss in circle\nControls: Move Target\nMath: toss=sin(t*4.8+idx*0.75) h=(toss+1)*0.5*formRadius*2.2+2 spread 0.35*scX",
            Constellation="Constellation\nTarget: Formation Target - orbit with bob\nControls: Move Target\nMath: r=formRadius*scR*(0.85+0.15*sin) bob=sin(t*3.6)*0.4 y=2.5*scY+bob",
            Rose="Rose\nTarget: Formation Target - rose k=3+(total%4)-1\nControls: Move Target\nMath: k=3+... theta=angle+t*1.2 a=formRadius*scR*(0.75+0.25*sin) r=a*cos(k*theta) y=2*scY+sin*6*scY",
            OrbitSin="OrbitSin\nTarget: Formation Target - orbit radius pulses + Y sine\nControls: Move Target\nMath: baseR=formRadius*scR r=baseR*(0.75+0.25*sin(t*4.2+ratio*6)) y=2*scY+scY*2.5*sin(t*2.8+ratio*2pi)",
            Liss="Liss\nTarget: Formation Target - Lissajous 3D\nControls: Move Target\nMath: u=ratio*2pi+t*1.1 x=sin(3*u+t*0.6) y=cos(2*u -t*0.44) z=sin(4*u+t*0.36)",
            Swing="Swing\nTarget: Formation Target but follows cursor if far\nControls: Move Target\nMath: swingA=angle+sin(t*2.4)*0.35+t*0.5 swingLen=(formRadius*scR)*(0.7+0.3*sin) d>25 extra 0.18*scR lerp to Target+2*scY 0.35",
            Aura="Aura\nTarget: Formation Target - 3 layered orbits with wobble\nControls: Move Target\nMath: layer=index%3 baseR=formRadius*(1+layer*0.4) orbitSpeed 1.6+layer*0.3 bob 5+layer*0.8 wobble sin*0.8",
            Homing="Homing\nTarget: Locked player (click) for 3s, else Formation Target\nControls: Click player/NPC to lock\nMath: homingTarget valid? center=launch:Lerp(target,0.94) dir=CFrame.lookAt helix L=9*scR u 0-1 rr 1.5/2.6",
            Railgun="Railgun\nTarget: Barrel at player 11*scY aiming at Formation Target\nControls: Hold click 1s to charge (coil spin 1.4+charge^3*100) then fire to raycast hit\nMath: origin=rp+11*scY + sin*1.6 aimDir=Target-origin coilN=total*0.45 len=(formRadius*2.2+8)*maxSc firing prog ease->hitPos",
            Barrage="Barrage\nTarget: Formation Target ground - fall from sky bombard\nControls: Move Target (bombs follow)\nMath: groundY=getGroundYAt(Target) targetY=ground+size*0.5 launchHeight 35+maxSc*8 drop (t+idx*0.12)%0.5 height=launch*(1-progress) wobble sin*pi*2",
            Sinewave="Sinewave\nTarget: Formation Target - 2D plane wave interference 3 waves\nControls: Move Target\nMath: x=(ratio-.5)*formRadius*4 y=(sin(x*0.5+t*4)*cos(z*0.5+t*3)+cos(x*0.3-t*3.6)*sin(z*0.4+t*4.4)+sin((x+z)*0.2+t*5))*formRadius*0.8 y=Target.Y+3*scY+y",
            Heart="Heart\nTarget: In front of Player (not Formation Target) facing your look - classic heart\nControls: Auto in front of you\nMath: origin=rp look/right/up theta=ratio*2pi+t heartScale=formRadius*0.8 x=16*sin^3 y=13*cos-5*cos2-2*cos3-cos4 localPos*heartScale*0.05+5",
            Wings="Wings\nTarget: In front of Player - pair of wings off back flapping\nControls: Auto\nMath: origin=rp wingSide ±1 wingIndex wingCurves sin(ratio*pi*0.5)*span flap sin(t*4)*0.3",
            Crystal="Crystal\nTarget: Formation Target - 5 stacked fibonacci layers\nControls: Move Target\nMath: layer=index%5 scale 1-layer*0.15 radius=formRadius*scale y=layer*0.8*formRadius phi golden theta=2pi*idx/phi+t*0.6*(layer+1)",
            TwinStars="TwinStars\nTarget: Formation Target - two cores + lemniscate belt\nControls: Move Target\nMath: orbitR=(formRadius*1.1+4)*scR coreA=t*1.5 c1=Target+cos*orbitR bob sin*1.5*scY belt lemniscate denom=1+sin^2",
            Tesseract="Tesseract\nTarget: Formation Target +5*scY - 4D hypercube projection\nControls: Move Target\nMath: 16 verts 2^4 edges H=max(formRadius,5)*1.35 4D rotations a1 0.55 a2 0.34 a3 0.21 persp dist/(dist-w*H) spin 0.19/0.27",
            Atom="Atom\nTarget: Formation Target - nucleus 12% + 3 shells tilted\nControls: Move Target\nMath: nucleus pulse sin*0.12 shells 3 tilt=shell/3*pi+sin*0.25 spin 1.5+shell*0.65 r=formRadius*1.5+shell*3.2",
            Lightning="Lightning\nTarget: Cloud 34 above player to Formation Target bolt\nControls: Click to set lightningTarget\nMath: segs 8 bolt lerp cloud->target + rand*14 stagger ratio*0.08 prog=(age-stagger)/0.35 else explode ir=2+age*9",
            Sniper="Sniper\nTarget: Ring 8*scY in front of face, sequential fire to Formation Target\nControls: Click to set sniperTargetPos (hold to charge Railgun-style, but Sniper fires on click)\nMath: ringR=5*scR ca=(idx/total)*2pi+t*2.4 slotP=center+right*cos+up*sin delay=idx/total*0.35 prog lerp slot->target 0.3 explode 1.2",
            Bridge="Bridge\nTarget: Formation Target ground - two-click bridge\nControls: Click A then B to build (arch), third click reset\nMath: dir=(B-A).Unit sideU=-dir.Z,0,dir.X cols 2-3 rows ceil(n/cols) arch=sin(u*pi)*min(D*0.08,3.5) y=g+arch+1.4 freeze",
            Strike="Strike\nTarget: Idle atom around player (10% nucleus +4 shells), on click descend to Formation Target\nControls: Click to set strikeTarget\nMath: idle atom, descend lerp 70->0 prog^2 + spin rr 2.5*(1-prog) drill circle ir 0.8+rand*0.35 return lerp",
            Boomerang="Boomerang\nTarget: Disc home 7*scY around player, on click boomerang to Formation Target +42 extra\nControls: Click to set boomerangTarget\nMath: u=clamp((t-start)/1.45) D=|target-origin| center=origin+dir*s*(D+min*0.48) side -D*0.16 tilt 76->14 spin 22 ringR 0.45+ring*0.32",
            Text="Text\nTarget: Vertical wall 6 studs in front of Player facing outwards (world up, not Formation Target) - 5x7 font A-Z0-9 !?+-= Uppercase, spacing 2.2/4.2 adapts to avg part size (avg*0.78+0.22), long parts auto-assigned to stick letters (I/L/T) longest run first, parts rotated Z to match stroke 0/90/45/135 (C less closed: middle rows open)\nControls: Type in top bar (live, filtered [^%-A-Z0-9 !?+=])\nMath: points buildTextPointsData angle via 8-neighbor h/v/diag runLen, textScale= (0.78*avg+0.22)*(formRadius/7*0.38+0.62)*(maxSc*0.38+0.62)*1.1*0.92, pos=origin+right*X+up*(Y-midY)+jitter",
            Scythe="Scythe\nTarget: Idle hovers 6.5*scY above player, swing at Formation Target floor Y+0.4 flat 90° (horizontal)\nControls: Click to swing 0.6s (no cooldown) fling 38500+13200 stronger than Sniper\nMath: idle tilt 52 yaw spin*18, swing yaw -85->85 ease tilt 90 handle 1.35*scY bladeR 0.95*scR tip hook offZ 1.42*bladeR offY -0.34*bladeR, flat X-Z after 90° tilt",
            Pentagram="Pentagram\nTarget: In front of Player 5*scY facing your look (not Formation Target) - 5-point star {5/2}\nControls: Move with your look\nMath: r=formRadius*1.6 verts 5 order 1,3,5,2,4 perEdge ceil(total/5) tEdge lerp pulse 1+sin*0.06 right*X+up*Y",
            Chained="Chained\nTarget: Idle 2 horizontal chain rings at hands (±right*1.45*scR+up*0.45*scY) + crown 7.8*scY above head r 0.85*scR+1.9, firing to Formation Target\nControls: Hold click to shoot both chains from hands to Target as tangled helix 3.4 turns helixR 0.42*scR, fling 33500+11000 velimmune filtered\nMath: crown rPulse 1+sin*0.06 spike every 4th 1.4*scY, rings center hand±right*radius a=ratio*2pi+t*1.5 wobbleR 1+sin*0.05 linkLift ±0.16*scY, firing helix perp/binorm cos/sin*helixR + sag 0.6*scY",
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

        local function refreshModes()
            for name,mb in pairs(modeBtns) do
                local on=name==activeMode
                local cat = MODE_CAT[name] or "blue"
                local col = CAT_COL[cat]
                mb.BackgroundColor3=on and col.bgOn or col.bg
                mb.TextColor3=on and Color3.fromRGB(8,8,12) or col.tx
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
                if activeMode ~= name then
                    clearModeState(activeMode, name)
                    activeMode=name
                    refreshModes()
                end
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

        mkSec("SCALE & DRAW", modSF, 6)

        mkSlider(modSF,"Form Size X",0,100,formSizeX,7,function(v) formSizeX=v end,0.1)
        mkSlider(modSF,"Form Size Y",0,100,formSizeY,8,function(v) formSizeY=v end,0.1)
        mkSlider(modSF,"Form Size Z",0,100,formSizeZ,9,function(v) formSizeZ=v end,0.1)


mkSlider(modSF,"Form Offset Y",-20,20,formOffsetY,10,function(v) formOffsetY=v end)

         local clearDrawBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
             Text="Clear Draw Trail",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=8},modSF)
         clearDrawBtn.MouseButton1Click:Connect(function() clearDrawDots() end)
         mkL({Size=UDim2.new(1,0,0,14),
             Text="Hold Mouse1 while in Draw mode to trace a path",
             TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=9},modSF)
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
        dv2Label=mkL({Size=UDim2.new(1,0,0,14),Text="Inactive",TextColor3=PAL.DV2C,
            TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=15},parSF)
        mkSlider(parSF,"Fling Force",50,8000,flingForce,16,function(v) flingForce=v end)
        mkSlider(parSF,"Fling Range", 5, 500,flingRange,17,function(v) flingRange=v end) --funny if u set it to 500 nglll
        mkDiv(parSF,18)
        mkSec("HOMING", parSF, 19)
        homingLabel=mkL({Size=UDim2.new(1,0,0,14),Text="Inactive",TextColor3=Color3.fromRGB(255,100,100),
            TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=20},parSF)
        mkDiv(parSF,21)
        mkSec("RAILGUN", parSF, 22)
        railgunLabel=mkL({Size=UDim2.new(1,0,0,14),Text="Inactive",TextColor3=Color3.fromRGB(100,200,255),
            TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=23},parSF)
        mkDiv(parSF,24)
        mkSec("BARRAGE", parSF, 25)
        barrageLabel=mkL({Size=UDim2.new(1,0,0,14),Text="Inactive",TextColor3=Color3.fromRGB(255,200,100),
            TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=26},parSF)
    end

    buildParamsSubPanel(spCont, sPanels)

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

        local spcBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Single Part Control: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=3},toolP)
        local spcRelBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_RED,
            Text="Release Grabbed Part",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},toolP)
        mkSlider(toolP,"SPC Depth",3,60,spcDepth,5,function(v) spcDepth=v end)

        spcBtn.MouseButton1Click:Connect(function()
            spcActive=not spcActive
            if not spcActive then spcPart=nil; updateSpcHighlight(nil) end
            spcBtn.BackgroundColor3=spcActive and Color3.fromRGB(18,40,24) or PAL.B_DEF
            spcBtn.TextColor3=spcActive and Color3.fromRGB(110,210,130) or PAL.T1
            local base = "Single Part Control: "..(spcActive and "ON" or "OFF")
            if buttonKeybinds[spcBtn] and buttonKeybinds[spcBtn].originalText then
                base = base .. " [" .. buttonKeybinds[spcBtn].key.Name .. "]"
            end
            spcBtn.Text=base
        end)
        spcRelBtn.MouseButton1Click:Connect(function()
            if spcPart then pcall(function() spcPart.AssemblyLinearVelocity=Vector3.zero end) end
            spcPart=nil; updateSpcHighlight(nil)
        end)
        reg(UserInputService.InputChanged:Connect(function(inp)
            if not spcActive then return end
            if inp.UserInputType==Enum.UserInputType.MouseWheel then
                spcYOff=spcYOff+inp.Position.Z*1.5
            end
        end))

        mkDiv(toolP,6)
        mkSec("PART LIMITS [WIP]", toolP, 7)

        local limitsBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Limits: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},toolP)
        limitsBtn.MouseButton1Click:Connect(function()
            useLimits=not useLimits
            limitsBtn.BackgroundColor3=useLimits and Color3.fromRGB(44,28,8) or PAL.B_DEF
            limitsBtn.TextColor3=useLimits and Color3.fromRGB(255,180,80) or PAL.T1
            limitsBtn.Text="Limits: "..(useLimits and "ON (limit: "..partLimit..")" or "OFF")
        end)
        mkSlider(toolP,"Part Limit",1,100,partLimit,8,function(v) 
            partLimit=v
            if useLimits then 
                limitsBtn.Text="Limits: ON (limit: "..partLimit..")" 
            end
        end)

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
        physBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Strengthen Parts: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=12.3},toolP)
        
        physBtn.BackgroundColor3 = strengthenParts and Color3.fromRGB(18,55,24) or PAL.B_DEF
        physBtn.TextColor3       = strengthenParts and Color3.fromRGB(110,210,130) or PAL.T1
        physBtn.Text = "Strengthen Parts: "..(strengthenParts and "ON" or "OFF")

        physBtn.MouseButton1Click:Connect(function()
            strengthenParts = not strengthenParts
            physBtn.BackgroundColor3 = strengthenParts and Color3.fromRGB(18,55,24) or PAL.B_DEF
            physBtn.TextColor3       = strengthenParts and Color3.fromRGB(110,210,130) or PAL.T1
            physBtn.Text = "Strengthen Parts: "..(strengthenParts and "ON" or "OFF")
            updatePhysPropertiesForSelected()
        end)

        mkSlider(toolP,"Custom Density",1,1000,strengthenDensity,12.4,function(v)
            strengthenDensity = v
            updatePhysPropertiesForSelected()
        end)

        mkDiv(toolP,13)
        mkSec("HIGHLIGHT", toolP, 14)

        local espBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Mode: Highlight (through walls)",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=15},toolP)
        local espStyleBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Style: ESP Labels",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},toolP)


        espBtn.BackgroundColor3 = useESP and Color3.fromRGB(16,32,56) or PAL.B_DEF
        espBtn.TextColor3 = useESP and Color3.fromRGB(100,150,255) or PAL.T1
        espBtn.Text = "Mode: "..(useESP and "ESP UI" or "Highlight (through walls)")
        espStyleBtn.BackgroundColor3 = useESP and (espStyle == "Label" and PAL.B_DEF or Color3.fromRGB(16,32,56)) or PAL.B_DEF
        espStyleBtn.TextColor3 = useESP and (espStyle == "Label" and PAL.T1 or Color3.fromRGB(100,150,255)) or PAL.T1
        espStyleBtn.Text = "Style: "..(espStyle == "Label" and "ESP Labels" or "ESP Box")

        espBtn.MouseButton1Click:Connect(function()
            useESP = not useESP
            espBtn.BackgroundColor3 = useESP and Color3.fromRGB(16,32,56) or PAL.B_DEF
            espBtn.TextColor3 = useESP and Color3.fromRGB(100,150,255) or PAL.T1
            espBtn.Text = "Mode: "..(useESP and "ESP UI" or "Highlight (through walls)")
            espStyleBtn.BackgroundColor3 = useESP and (espStyle == "Label" and PAL.B_DEF or Color3.fromRGB(16,32,56)) or PAL.B_DEF
            espStyleBtn.TextColor3 = useESP and (espStyle == "Label" and PAL.T1 or Color3.fromRGB(100,150,255)) or PAL.T1
            espStyleBtn.Text = "Style: "..(espStyle == "Label" and "ESP Labels" or "ESP Box")
            for _,part in ipairs(selectedParts) do removeHL(part); addHL(part) end
        end)

        espStyleBtn.MouseButton1Click:Connect(function()
            if not useESP then return end
            espStyle = espStyle == "Label" and "Box" or "Label"
            espStyleBtn.BackgroundColor3 = espStyle == "Label" and PAL.B_DEF or Color3.fromRGB(16,32,56)
            espStyleBtn.TextColor3 = espStyle == "Label" and PAL.T1 or Color3.fromRGB(100,150,255)
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


        local hlOutlineBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Outline: ON",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=22},toolP)
        hlOutlineBtn.MouseButton1Click:Connect(function()
            HL.outlineTransparency = HL.outlineTransparency == 0 and 1 or 0
            local on = HL.outlineTransparency == 0
            hlOutlineBtn.BackgroundColor3 = on and Color3.fromRGB(18,55,24) or PAL.B_DEF
            hlOutlineBtn.TextColor3       = on and Color3.fromRGB(110,210,130) or PAL.T1
            hlOutlineBtn.Text = "Outline: "..(on and "ON" or "OFF")
            refreshAllHighlights()
        end)


        local hlDepthBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=Color3.fromRGB(18,55,24),
            Text="Through Walls: ON",TextColor3=Color3.fromRGB(110,210,130),
            TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=23},toolP)
        hlDepthBtn.MouseButton1Click:Connect(function()
            local throughWalls = HL.depthMode == Enum.HighlightDepthMode.AlwaysOnTop
            HL.depthMode = throughWalls
                and Enum.HighlightDepthMode.Occluded
                or  Enum.HighlightDepthMode.AlwaysOnTop
            local on = HL.depthMode == Enum.HighlightDepthMode.AlwaysOnTop
            hlDepthBtn.BackgroundColor3 = on and Color3.fromRGB(18,55,24) or PAL.B_DEF
            hlDepthBtn.TextColor3       = on and Color3.fromRGB(110,210,130) or PAL.T1
            hlDepthBtn.Text = "Through Walls: "..(on and "ON" or "OFF")
            refreshAllHighlights()
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
            pb.BackgroundColor3=on and Color3.fromRGB(18,55,24) or PAL.B_DEF
            pb.TextColor3=on and Color3.fromRGB(110,210,130) or PAL.T1
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
        npcCtrlBtn.BackgroundColor3 = npcControlEnabled and Color3.fromRGB(18,55,24) or PAL.B_DEF
        npcCtrlBtn.TextColor3 = npcControlEnabled and Color3.fromRGB(110,210,130) or PAL.T1
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
            fajBtn.BackgroundColor3=npcControlFreezeAutoJump and Color3.fromRGB(18,55,24) or PAL.B_DEF
            fajBtn.TextColor3=npcControlFreezeAutoJump and Color3.fromRGB(110,210,130) or PAL.T1
            fajBtn.Text="Freeze AutoJump: "..(npcControlFreezeAutoJump and "ON" or "OFF")
        end)
        local hmBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Halt MoveTo: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=23},npcControlPanel)
        hmBtn.MouseButton1Click:Connect(function()
            npcControlHaltMoveTo=not npcControlHaltMoveTo
            hmBtn.BackgroundColor3=npcControlHaltMoveTo and Color3.fromRGB(18,55,24) or PAL.B_DEF
            hmBtn.TextColor3=npcControlHaltMoveTo and Color3.fromRGB(110,210,130) or PAL.T1
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
        local btn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text=lbl..": OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=lo},npcAurasPanel)
        btn.MouseButton1Click:Connect(function()
            setF(not getF())
            btn.BackgroundColor3 = getF() and onBg or PAL.B_DEF
            btn.TextColor3       = getF() and onTc or PAL.T1
            btn.Text = lbl..": "..(getF() and "ON" or "OFF")
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
        local btn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text=lbl..": OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=lo},npcToolsPanel)
        btn.MouseButton1Click:Connect(function()
            setF(not getF())
            btn.BackgroundColor3 = getF() and onBg or PAL.B_DEF
            btn.TextColor3       = getF() and onTc or PAL.T1
            btn.Text = lbl..": "..(getF() and "ON" or "OFF")
        end)
    end

    local tkBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
        Text="Telekinesis Gun: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},npcToolsPanel)
    local fzBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
        Text="Freeze Gun: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=5},npcToolsPanel)
    local function refreshTKFZ()
        tkBtn.BackgroundColor3=NX.tkGun and Color3.fromRGB(90,40,120) or PAL.B_DEF
        tkBtn.TextColor3=NX.tkGun and Color3.fromRGB(220,170,255) or PAL.T1
        tkBtn.Text="Telekinesis Gun: "..(NX.tkGun and "ON" or "OFF")
        fzBtn.BackgroundColor3=NX.freezeGun and Color3.fromRGB(20,70,120) or PAL.B_DEF
        fzBtn.TextColor3=NX.freezeGun and Color3.fromRGB(150,210,255) or PAL.T1
        fzBtn.Text="Freeze Gun: "..(NX.freezeGun and "ON" or "OFF")
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
            npcSBtns[t].TextColor3 = (t==name) and Color3.fromRGB(8,8,12) or PAL.T2
            npcSPanels[t].Visible = (t==name)
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
        selectAllBtn = selectAllBtn,
        selectInRangeBtn = selectInRangeBtn,
        selectUnweldedBtn = selectUnweldedBtn,
        selectNDSRangeBtn = selectNDSRangeBtn,
    }
end)()
_G.importantButtons = {
    clickSelBtn = UI.clickSelBtn,
    clearBtn = UI.clearBtn,
    freezeBtn = UI.freezeBtn,
    spcBtn = UI.spcBtn,
    selectAllBtn = UI.selectAllBtn,
    selectInRangeBtn = UI.selectInRangeBtn,
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
                        if activeMode ~= modeName then
                            clearModeState(activeMode, modeName)
                            activeMode = modeName
                            if _G.refreshModes then
                                pcall(_G.refreshModes)
                            else
                                for name, mb in pairs(_G.modeButtons) do
                                    local on = name == activeMode
                                    local cat = (_G.MODE_CAT and _G.MODE_CAT[name] or "blue")
                                    local col = (_G.CAT_COL and _G.CAT_COL[cat] or {bg=Color3.fromRGB(16,24,50), bgOn=Color3.fromRGB(38,70,148), tx=Color3.fromRGB(110,145,235)})
                                    mb.BackgroundColor3 = on and col.bgOn or col.bg
                                    mb.TextColor3 = on and Color3.fromRGB(8,8,12) or col.tx
                                    if buttonKeybinds[mb] and buttonKeybinds[mb].originalText then
                                        local keyName = buttonKeybinds[mb].key.Name
                                        local originalText = buttonKeybinds[mb].originalText
                                        mb.Text = originalText .. " [" .. keyName .. "]"
                                    end
                                end
                            end
                        end
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
                            button.BackgroundColor3 = clickSelActive and Color3.fromRGB(18,55,24) or PAL.B_DEF
                            button.TextColor3 = clickSelActive and Color3.fromRGB(110,210,130) or PAL.T1
                            local originalText = buttonKeybinds[button] and buttonKeybinds[button].originalText or "Click-Select: OFF"
                            button.Text = "Click-Select: "..(clickSelActive and "ON" or "OFF")
                            button.BackgroundColor3 = clickSelActive and Color3.fromRGB(18,55,24) or PAL.B_DEF
                            button.TextColor3 = clickSelActive and Color3.fromRGB(110,210,130) or PAL.T1
                            local originalText = buttonKeybinds[button] and buttonKeybinds[button].originalText or "Click-Select: OFF"
                            button.Text = "Click-Select: "..(clickSelActive and "ON" or "OFF")
                            if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                                local keyName = buttonKeybinds[button].key.Name
                                button.Text = button.Text .. " [" .. keyName .. "]"
                            end
                        end)
                     elseif button == _G.importantButtons.spcBtn then
                         pcall(function()
                             spcActive = not spcActive
                             if not spcActive then spcPart = nil; updateSpcHighlight(nil) end
                             spcBtn.BackgroundColor3 = spcActive and Color3.fromRGB(18,40,24) or PAL.B_DEF
                             spcBtn.TextColor3 = spcActive and Color3.fromRGB(110,210,130) or PAL.T1
                             spcBtn.Text = "Single Part Control: "..(spcActive and "ON" or "OFF")
                             if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                                 local keyName = buttonKeybinds[button].key.Name
                                 spcBtn.Text = spcBtn.Text .. " [" .. keyName .. "]"
                             end
                         end)
                    elseif button == _G.importantButtons.selectAllBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(buttonKeybinds[button].originalText, "All")) then
                          pcall(function()
                              local before=#selectedParts
                              selectAll()
                          end)
                      elseif button == _G.importantButtons.selectInRangeBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(buttonKeybinds[button].originalText, "In Range")) then
                          pcall(function()
                              local before=#selectedParts
                              selectInRange(autoSelRange)
                          end)
                    elseif button == _G.importantButtons.selectUnweldedBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(string.lower(buttonKeybinds[button].originalText), "nds unanchored") and not string.find(string.lower(buttonKeybinds[button].originalText), "range")) or string.find(string.lower(button.Text), "select nds unanchored") and not string.find(string.lower(button.Text), "range") then
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
                      elseif button == _G.importantButtons.selectNDSRangeBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(string.lower(buttonKeybinds[button].originalText), "range select nds")) or string.find(string.lower(button.Text), "range select nds") then
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
                            spcPart = nil
                            clearSelection(false)
                            refreshAutoSelectButtons()
                        end)
                    elseif button == _G.importantButtons.freezeBtn then
                        pcall(function()
                            frozen = not frozen
                            if not frozen then
                                local boostUntil = tick() + 0.75
                                for _, p in ipairs(selectedParts) do unfreezeBoost[p] = boostUntil end
                            end
                            frozenTargets = {}
                            button.BackgroundColor3 = frozen and Color3.fromRGB(22,38,75) or PAL.B_DEF
                            button.TextColor3 = frozen and Color3.fromRGB(130,175,255) or PAL.T1
                            local originalText = buttonKeybinds[button] and buttonKeybinds[button].originalText or "Formation Freeze: OFF"
                            button.Text = "Formation Freeze: "..(frozen and "ON" or "OFF")
                            if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                                local keyName = buttonKeybinds[button].key.Name
                                button.Text = button.Text .. " [" .. keyName .. "]"
                            end
                        end)
                    else
                        local bt = string.lower(button.Text)
                        local ot = buttonKeybinds[button] and buttonKeybinds[button].originalText and string.lower(buttonKeybinds[button].originalText) or bt
                        if string.find(ot, "nds unanchored") or string.find(bt, "nds unanchored") then
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
                    if string.find(ot2, "nds unanchored") or string.find(bt2, "nds unanchored") then
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
    local restoredCount = 0
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
                    restoredCount = restoredCount + 1
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
                            if activeMode ~= name then
                                clearModeState(activeMode, name)
                                activeMode = name
                                if _G.refreshModes then
                                    pcall(_G.refreshModes)
                                else
                                    for nm, mbtn in pairs(_G.modeButtons) do
                                        local on = nm == activeMode
                                        local cat = (_G.MODE_CAT and _G.MODE_CAT[nm] or "blue")
                                        local col = (_G.CAT_COL and _G.CAT_COL[cat] or {bg=Color3.fromRGB(16,24,50), bgOn=Color3.fromRGB(38,70,148), tx=Color3.fromRGB(110,145,235)})
                                        mbtn.BackgroundColor3 = on and col.bgOn or col.bg
                                        mbtn.TextColor3 = on and Color3.fromRGB(8,8,12) or col.tx
                                        if buttonKeybinds[mbtn] and buttonKeybinds[mbtn].originalText then
                                            local keyName = buttonKeybinds[mbtn].key.Name
                                            local origText = buttonKeybinds[mbtn].originalText
                                            mbtn.Text = origText .. " [" .. keyName .. "]"
                                        end
                                    end
                                end
                            end
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
                        button.BackgroundColor3 = clickSelActive and Color3.fromRGB(18,55,24) or PAL.B_DEF
                        button.TextColor3 = clickSelActive and Color3.fromRGB(110,210,130) or PAL.T1
                        button.Text = "Click-Select: "..(clickSelActive and "ON" or "OFF")
                        if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                            button.Text = button.Text .. " [" .. buttonKeybinds[button].key.Name .. "]"
                        end
                    end)
                elseif button == _G.importantButtons.spcBtn then
                    pcall(function()
                        spcActive = not spcActive
                        if not spcActive then spcPart = nil; updateSpcHighlight(nil) end
                        spcBtn.BackgroundColor3 = spcActive and Color3.fromRGB(18,40,24) or PAL.B_DEF
                        spcBtn.TextColor3 = spcActive and Color3.fromRGB(110,210,130) or PAL.T1
                        spcBtn.Text = "Single Part Control: "..(spcActive and "ON" or "OFF")
                        if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                            spcBtn.Text = spcBtn.Text .. " [" .. buttonKeybinds[button].key.Name .. "]"
                        end
                    end)
                elseif button == _G.importantButtons.clearBtn then
                    pcall(function()
                        autoSelectAll = false
                        autoSelectNear = false
                        spcPart = nil
                        clearSelection(false)
                        refreshAutoSelectButtons()
                    end)
                elseif button == _G.importantButtons.freezeBtn then
                    pcall(function()
                        frozen = not frozen
                        if not frozen then
                            local boostUntil = tick() + 0.75
                            for _, p in ipairs(selectedParts) do unfreezeBoost[p] = boostUntil end
                        end
                        frozenTargets = {}
                        button.BackgroundColor3 = frozen and Color3.fromRGB(22,38,75) or PAL.B_DEF
                        button.TextColor3 = frozen and Color3.fromRGB(130,175,255) or PAL.T1
                        button.Text = "Formation Freeze: "..(frozen and "ON" or "OFF")
                        if buttonKeybinds[button] and buttonKeybinds[button].originalText then
                            button.Text = button.Text .. " [" .. buttonKeybinds[button].key.Name .. "]"
                        end
                    end)
                elseif button == _G.importantButtons.selectAllBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(buttonKeybinds[button].originalText, "All")) then
                    pcall(function()
                        local before=#selectedParts
                        selectAll()
                    end)
                elseif button == _G.importantButtons.selectInRangeBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(buttonKeybinds[button].originalText, "In Range")) then
                    pcall(function()
                        local before=#selectedParts
                        selectInRange(autoSelRange)
                    end)
                elseif button == _G.importantButtons.selectUnweldedBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(buttonKeybinds[button].originalText, "NDS unanchored") and not string.find(buttonKeybinds[button].originalText, "Range")) then
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
                elseif button == _G.importantButtons.selectNDSRangeBtn or (buttonKeybinds[button] and buttonKeybinds[button].originalText and string.find(buttonKeybinds[button].originalText, "Range Select NDS")) then
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
    end
end))


task.wait(0.2)
reg(UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        if UserInputService:GetFocusedTextBox() then return end
        
        local mousePos = UserInputService:GetMouseLocation() -- mouse stuffaslmda
        local guiInset = GuiService:GetGuiInset()
        

        local bestButton = nil
        local bestScore = -math.huge
        

        local guiParents = {}
        if UI and UI.ScreenGui then table.insert(guiParents, UI.ScreenGui) end
        if ScreenGui then table.insert(guiParents, ScreenGui) end -- table.insert(plate + math.huge of fried chicken) do bacon.head.mouth.eat(50 fried chickens) then do bacon.torso.digest(true) else bacon.torso.vomit(true) if bacon.torso.vomit(false) then bacon.torso.stomach(full)
        if gethui then
            local ok, hui = pcall(gethui)
            if ok and hui then table.insert(guiParents, hui) end
        end
        
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
        if dir.Magnitude > 0.001 then
            pcall(function()
                root.AssemblyLinearVelocity = dir.Unit * GRAB_TOSS_POWER + Vector3.new(0, 20, 0)
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
            pcall(function()
                root.AssemblyLinearVelocity = (target - root.Position) * NX.DRAG
                root.AssemblyAngularVelocity = Vector3.zero
            end)
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

    for part, storedPos in pairs(frozenTargets) do
        if not part or not part.Parent then
            doUnfreeze(part)
        else -- theres a fart trynna slip out my butt as i write this yo someone help me
            pcall(function()
                local currentPos = part.Position
                local diff = storedPos - currentPos
                local dist = diff.Magnitude

                if dist > 0.01 then
                    part.AssemblyLinearVelocity = diff.Unit * math.min(dist * 60, 500)
                else
                    part.AssemblyLinearVelocity = Vector3.zero
                end
                part.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
end))

reg(Mouse.Button1Down:Connect(function()
    if rotDrag.active then
        rotDrag.active = false
        return
    end
    local clickTarget = Mouse.Target
    if activeMode=="Draw" then 
        isDrawing=true
        currentTrail = {}
        table.insert(drawTrails, currentTrail)
    end

    if activeMode=="Homing" then -- i hate homing so much someone fucking kill it 
        local newTarget = nil
        if clickTarget then
            local model = clickTarget:FindFirstAncestorOfClass("Model")
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
                            local d = (tr.Position - clickTarget.Position).Magnitude
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
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            homingLaunchPos = (myRoot and myRoot.Position + Vector3.new(0, 4, 0)) or newTarget.Position
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
                if dir.Magnitude > 0.001 then
                    pcall(function()
                        grabbedRoot.AssemblyLinearVelocity = dir.Unit * GRAB_TOSS_POWER + Vector3.new(0, 20, 0)
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

    if activeMode=="Sniper" then
        if #selectedParts > 0 then
            sniperTargetPos = currentMouseHit
            sniperFireTime = tick()
            sniperBoomStage = 0
            sniperCaught = false
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
                            + d2 * 30000 + Vector3.new(0, 10000, 0)
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
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + d3 * 13200 + Vector3.new(0, 3200, 0)
                        hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*180, (math.random()-0.5)*180, (math.random()-0.5)*180)
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
                local n = #selectedParts
                local scXb = math.max(0, formSizeX) / 10
                local cols = math.min(3, math.max(2, math.ceil(n / 12)))
                local rows = math.ceil(n / cols)
                for i, p in ipairs(selectedParts) do
                    local row = math.floor((i - 1) / cols)
                    local col = (i - 1) % cols
                    local u = rows > 1 and row / (rows - 1) or 0.5
                    local side = (col - (cols - 1) / 2) * 2.4 * scXb
                    local arch = math.sin(u * math.pi) * math.min(D * 0.08, 3.5)
                    local pos = bridgeA:Lerp(bridgeB, u) + sideU * side + Vector3.new(0, arch + 1.4, 0)
                    pcall(function()
                        if not partPhysProperties[p] then partPhysProperties[p] = {CustomPhysicalProperties = p.CustomPhysicalProperties} end
                        p.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0)
                        p.AssemblyLinearVelocity = Vector3.zero
                        p.AssemblyAngularVelocity = Vector3.zero
                        p.CFrame = CFrame.lookAt(pos, pos + dirU)
                        p.CanCollide = true
                    end)
                    doFreeze(p, pos)
                    if not partTargets[p] then partTargets[p] = {} end
                    partTargets[p].position  = pos
                    partTargets[p].rotation  = CFrame.lookAt(pos, pos + dirU)
                    syncAlignTarget(p, partTargets[p])
                    bridgeSlots[p] = pos
                end
                if UI and UI.freezeBtn then
                    UI.freezeBtn.BackgroundColor3 = Color3.fromRGB(22,38,75)
                    UI.freezeBtn.TextColor3 = Color3.fromRGB(130,175,255)
                    UI.freezeBtn.Text = "Formation Freeze: ON"
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
                        part.AssemblyLinearVelocity = burstDir * 8000
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + burstDir * 9000
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
                        (math.random() - 0.5) * 5000,
                        (math.random() - 0.5) * 5000,
                        (math.random() - 0.5) * 5000
                    )

                    local toTarget = (satTarget - part.Position).Unit
                    part.AssemblyLinearVelocity = toTarget * 1000 + Vector3.new(
                        (math.random() - 0.5) * 200,
                        (math.random() - 0.5) * 200 + 100,
                        (math.random() - 0.5) * 200
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
                        local burstDir = (hit.Position - part.Position).Unit
                        part.AssemblyLinearVelocity = burstDir * 8000 + Vector3.new(
                            (math.random() - 0.5) * 500,
                            (math.random() - 0.5) * 500,
                            (math.random() - 0.5) * 500
                        )
                        if hitVel then
                            hit.AssemblyLinearVelocity = hitVel + burstDir * 4000
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
                    hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*38500 + Vector3.new(0, 13200, 0) + Vector3.new((math.random()-0.5)*2200,0,(math.random()-0.5)*2200)
                    hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*4800, (math.random()-0.5)*4800, (math.random()-0.5)*4800)
                    p.AssemblyAngularVelocity = Vector3.new((math.random()-0.5)*3400, (math.random()-0.5)*3400, (math.random()-0.5)*3400)
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
                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir*33500 + Vector3.new(0, 11000, 0) + Vector3.new((math.random()-0.5)*1800,0,(math.random()-0.5)*1800)
                        hit.AssemblyAngularVelocity = hit.AssemblyAngularVelocity + Vector3.new((math.random()-0.5)*4200, (math.random()-0.5)*4200, (math.random()-0.5)*4200)
                        p.AssemblyAngularVelocity = Vector3.new((math.random()-0.5)*3200, (math.random()-0.5)*3200, (math.random()-0.5)*3200)
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
                spcPart=clickTarget; updateSpcHighlight(spcPart); return
            end
        end
        return
    end

    if clickSelActive and clickTarget then
        if isSelected(clickTarget) then deselectPart(clickTarget) else selectPart(clickTarget) end
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
                npcCtrlBtn.BackgroundColor3=Color3.fromRGB(18,55,24)
                npcCtrlBtn.TextColor3=Color3.fromRGB(110,210,130)
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
        if railgunLabel then
            railgunLabel.Text = "Hold click to charge"
        end
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
        if spcPart then pcall(function() spcPart.AssemblyLinearVelocity=Vector3.zero end) end
        spcPart=nil; spcActive=false; updateSpcHighlight(nil)
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
                            local dir = (hit.Position - p.Position).Unit
                            local flingPower = 500000
                            hit.AssemblyLinearVelocity = dir * flingPower + Vector3.new(0, 150000, 0)
                            for i = 1, 5 do
                                task.delay(i * 0.02, function()
                                    if hit and hit.Parent then
                                        hit.AssemblyLinearVelocity = hit.AssemblyLinearVelocity + dir * (flingPower * 0.5) + Vector3.new(0, 50000, 0)
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
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000)

        if hit and hit.Instance and hit.Instance:IsA("BasePart") then
            local target = hit.Instance
            if not isSelected(target) then return end
            if target.Anchored or target == workspace.Terrain then return end
            if LP.Character and target:IsDescendantOf(LP.Character) then return end
            if frozenTargets[target] then
                doUnfreeze(target)
                unfreezeBoost[target] = tick() + 0.75
                pcall(function() target.CanTouch = true end)
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
            rotDrag.active = false
            return
        end

        local mousePos = UserInputService:GetMouseLocation()
        local inset = GuiService:GetGuiInset()
        local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y - inset.Y)
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000)
        if not hit or not hit.Instance or not hit.Instance:IsA("BasePart") then return end

        local part = hit.Instance
        if not frozenTargets[part] then return end

        rotDrag.active = true
        rotDrag.part = part
        rotDrag.axis = "X"
        rotDrag.pending = 0
    end
end))

reg(UserInputService.InputBegan:Connect(function(inp,gpe)
    if not rotDrag.active then return end
    if inp.KeyCode==Enum.KeyCode.K or inp.KeyCode==Enum.KeyCode.L then
        local order = { X=1, Y=2, Z=3 }
        local idx = order[rotDrag.axis] + (inp.KeyCode==Enum.KeyCode.L and 1 or -1)
        if idx > 3 then idx = 1 elseif idx < 1 then idx = 3 end
        rotDrag.axis = ({ "X", "Y", "Z" })[idx]
        rotDrag.pending = 0
    elseif inp.KeyCode==Enum.KeyCode.Escape then
        rotDrag.active = false
    end
end))

reg(UserInputService.InputChanged:Connect(function(input, gpe)
    if not rotDrag.active then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        rotDrag.pending += input.Delta.X * 0.45
    end
end))


reg(RunService.Heartbeat:Connect(function()
    updateMouseHit()

    if rotDrag.active and rotDrag.part then
        local part = rotDrag.part
        if not part.Parent or not frozenTargets[part] then
            rotDrag.active = false
        elseif math.abs(rotDrag.pending) > 0.0001 then
            pcall(function()
pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
                local pivot = CFrame.new(part.Position)
                local a = math.rad(rotDrag.pending)
                local r = CFrame.Angles(
                    rotDrag.axis == "X" and a or 0,
                    rotDrag.axis == "Y" and a or 0,
                    rotDrag.axis == "Z" and a or 0)
                part.CFrame = pivot * r * pivot:Inverse() * part.CFrame
                if isSelected(part) then
                    if not partTargets[part] then partTargets[part] = {} end
                    partTargets[part].rotation = part.CFrame
                    partTargets[part].position = frozenTargets[part]
                    syncAlignTarget(part, partTargets[part])
                end
            end)
            rotDrag.pending = 0
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


    if #selectedParts>0 or spcActive or globalOwnership or activeMode=="Comet" or activeMode=="Stickman" or activeMode=="Scythe" or activeMode=="Text" or activeMode=="Pentagram" or activeMode=="Chained" then
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
    pcall(function()
        ScreenGui.AncestryChanged:Connect(function(_, parent)
            if not parent then pcall(saveConfig, true) end
        end)
    end)
    pcall(function() game:BindToClose(function() pcall(saveConfig, true) end) end)
    pcall(function()
        if Players and Players.PlayerRemoving then
            Players.PlayerRemoving:Connect(function(plr) if plr == LP then pcall(saveConfig, true) end end)
        end
    end)
    pcall(function()
        if getgenv then
            getgenv()._catalystSave = function() pcall(saveConfig, true) end
        end
    end)
end

reg(RunService.Heartbeat:Connect(function()
    if #selectedParts == 0 then return end
    local now = tick()
    if now - lastAnchoredVelAudit < anchoredAuditInterval then return end
    lastAnchoredVelAudit = now
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
reg(RunService.RenderStepped:Connect(function()
    if next(espLabels) then updateESP() end
    syncSelectionProxyModel()
end))
penis = true
if penis == true then
print("catalyst loadeeed")
end
-- pickle
