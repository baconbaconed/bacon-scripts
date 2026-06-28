
do
    local ok = false
    if type(sethiddenproperty) == "function" then
        local lp = game:GetService("Players").LocalPlayer
        pcall(sethiddenproperty, lp, "ReplicationFocus", workspace)
        ok = pcall(sethiddenproperty,
            lp, "SimulationRadius", math.huge)
    end
    if not ok then return end
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local CoreGui          = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse  = LP:GetMouse()

local GUI = {
    DISPLAY_ORDER = 100000,
    ESP_ORDER     = 100001,
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


local connections   = {}
local selectedParts = {}
local partOffsets   = {}
local highlights    = {}
local npcHighlights = {} 
local spcHighlight  = nil  


local EspScreenGui = Instance.new("ScreenGui")
EspScreenGui.Name             = "AtomizerESP"
EspScreenGui.ResetOnSpawn     = false
EspScreenGui.IgnoreGuiInset   = true
EspScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
EspScreenGui.DisplayOrder     = GUI.ESP_ORDER
EspScreenGui.Parent           = getGuiParent()

local function reg(c) table.insert(connections,c); return c end


local activeMode   = "Tornado"
local partSpeed    = 25
local maxVelocity  = math.huge
local formRadius   = 7
local formSizeX    = 10
local formSizeY    = 3
local formSizeZ    = 10
local formOffsetY  = 0
local formScale    = 1.0
local wallDist     = 7
local wallGap      = 0.1
local flingForce   = 800
local flingRange   = 200
local tornadoSpeed = 4
local spiralHeight = 14
local waveAmp      = 3
local orbitRadius  = 9
local autoSelRange = 60
local ownerRadius  = 100

local autoSelectAll        = false
local autoSelectNear       = false
local autoSelectLastScan   = 0
local AUTO_SELECT_INTERVAL = 5


local frozen          = false
local frozenTargets   = {}
local globalOwnership = false
local attracting      = false
local attractTimer    = 0
local fakeCollisions  = false

local partTargets = {}
local _bumpSign   = 1

local minigunIdx       = 1
local minigunShotStart = 0
local minigunLastIdx   = 0
local MINIGUN_STUCK    = 12

local satFired           = {}
local satTarget          = Vector3.zero
local SAT_TTL            = 2.0
local satTouchConns      = {}
local anchorBombAnchored = {}

local spcActive = false
local spcPart   = nil
local spcDepth  = 15
local spcYOff   = 0

local dv2Target = nil
local dv2Label  = nil 


local drawTrail      = {}
local drawIndicators = {}
local isDrawing      = false
local cometHistory   = {}
local COMET_MAX      = 500
local slinkyHistory  = {}
local SLINKY_MAX     = 400


local npcTarget               = nil
local npcSaved                = {}
local npcConns                = {}
local npcCam                  = { yaw=0, pitch=-0.25, dist=12 }
local npcControlEnabled       = false
local npcControlWalkSpeed     = 16
local npcControlJumpPower     = 50
local npcControlFreezeAutoJump = true
local npcControlHaltMoveTo    = true


local killAura         = false  local killAuraRange   = 25
local sitAura          = false  local sitAuraRange    = 25
local jumpAura         = false  local jumpAuraRange   = 25
local followAura       = false  local followAuraRange = 40
local freezeAura       = false  local freezeAuraRange = 25
local speedAuraEnabled = false  local speedAuraRange  = 30  local speedAuraSpeed = 30
local spinAuraEnabled  = false  local spinAuraRange   = 30  local spinAuraSpeed  = 6


local fingerGunEnabled = false
local grabGunEnabled   = false
local sitGunEnabled    = false
local grabbedNPC       = nil
local grabbedRoot      = nil
local localGrabArmed   = false


local NX = {
    tkGun = false, held = nil, root = nil, savedPS = nil,
    FLOAT_Y = 2, DRAG = 16,
    freezeGun = false, frozen = {},
    dead = false,
}


local _npcToolsRayParams = RaycastParams.new()
_npcToolsRayParams.FilterType = Enum.RaycastFilterType.Exclude

local GRAB_HOVER_Y_OFFSET = 3
local GRAB_TOSS_POWER     = 720
local GRAB_DRAG_POWER     = 180
local FINGER_GUN_RANGE    = 10000

local useLimits    = false
local partLimit    = 10
local formationType = "Mouse"
local clickFormPos  = Vector3.zero
local useESP        = false
local lastVelWrite  = {}

local CONFIG_FILE = "atomizer_saves.txt"
local hasFileSystem = type(readfile) == "function" and type(writefile) == "function"
local _lastConfigSave = 0
local CONFIG_SAVE_INTERVAL = 2.5

local CONFIG_KEYS = {
    "partSpeed", "maxVelocity", "formRadius", "formScale", "formSizeX", "formSizeY", "formSizeZ", "formOffsetY",
    "wallDist", "wallGap", "flingForce", "flingRange", "tornadoSpeed", "spiralHeight", "waveAmp", "orbitRadius",
    "autoSelRange", "ownerRadius", "killAuraRange", "sitAuraRange", "jumpAuraRange",
    "followAuraRange", "freezeAuraRange", "useLimits", "partLimit",
    "formationType", "useESP", "activeMode",
}

local function encodeConfig(cfg)
    local lines = {
        "# Atomizer saves — edit values after the = sign",
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
    local cfg = {
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
        formationType=formationType, useESP=useESP, activeMode=activeMode,
    }
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
    if cfg.activeMode ~= nil then activeMode = cfg.activeMode end
end

loadConfig()


local MODES = {
    "Mouse",   "Tornado",    "Ring",      "Orbit",
    "Spiral",  "Wave",       "Halo",      "Drone",
    "DroneV2", "Shield",     "Comet",     "Wall",
    "Draw",    "Beam",       "Sphere",    "Vortex",
    "DNA",     "Pulse",      "Grid",      "Cube",
    "Scatter", "Star",       "Pendulum",  "Rain",
    "Galaxy",  "Blackhole",  "Lemniscate","Blender",
    "Crown",   "Swarm",      "Minigun",   "Satellite",
    "Seek",    "AnchorBomb", "Slinky",    "Fountain",
    "Bounce",  "Ripple",     "Juggle",    "Constellation",
    "Rose",    "OrbitSin",   "Liss",      "Swing",
}




local _OWN = { preSim=1, hb=1, render=1 }
local preSimConn = RunService.PreSimulation and
    RunService.PreSimulation:Connect(function()
        pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
        _OWN.preSim = -_OWN.preSim
        local jolt = _OWN.preSim * 0.006
        for _, part in ipairs(selectedParts) do
            if part and part.Parent and not part.Anchored then
                pcall(function()

                    local AP = getNetAP(part)
                    if AP then
                        AP.MaxForce    = math.huge
                        AP.MaxVelocity = math.huge

                        local tgt = partTargets[part]
                        AP.Position = (tgt and tgt.position) or part.Position
                    end
    
                    part.AssemblyLinearVelocity = part.AssemblyLinearVelocity
                        + Vector3.new(0, jolt, 0)
                end)
            end
        end
    end) or nil

local ownerConn = RunService.Heartbeat:Connect(function()
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    _OWN.hb = -_OWN.hb
    local jolt = _OWN.hb * 0.007
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(function()
                local AP = getNetAP(part)
                if AP then
                    AP.MaxForce    = math.huge
                    AP.MaxVelocity = math.huge
                    local tgt = partTargets[part]
                    AP.Position = (tgt and tgt.position) or part.Position
                end

                part.AssemblyLinearVelocity = part.AssemblyLinearVelocity
                    + Vector3.new(0, jolt, 0)

                local sr = part:FindFirstChild("ServerResponse")
                if sr and sr:IsA("BodyForce") then
                    sr.Force = Vector3.new(
                        (math.random() - 0.5) * 0.002,
                        part.AssemblyMass * 100000,
                        (math.random() - 0.5) * 0.002)
                end
            end)
        end
    end
end)


local renderOwnerConn = RunService.RenderStepped:Connect(function()
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    _OWN.render = -_OWN.render
    local bump = _OWN.render * 0.005
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(function()

                local AP = getNetAP(part)
                if AP then
                    AP.MaxForce    = math.huge
                    AP.MaxVelocity = math.huge
                    local tgt = partTargets[part]
                    AP.Position = (tgt and tgt.position) or part.Position
                end
                part.AssemblyLinearVelocity = part.AssemblyLinearVelocity
                    + Vector3.new(0, bump, 0)
            end)
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

function syncAlignTarget(part, target)
    if not (part and part.Parent and target) then return end

    local AP = getNetAP(part)
    if AP then
        AP.Mode               = Enum.PositionAlignmentMode.OneAttachment
        AP.MaxForce           = math.huge
        AP.MaxVelocity        = math.huge
        AP.Responsiveness     = 120
        AP.RigidityEnabled    = false
        AP.ApplyAtCenterOfMass = true
        AP.Position           = target.position or part.Position
    end

    local AO = getNetAO(part)
    if AO then
        AO.Mode               = Enum.OrientationAlignmentMode.OneAttachment
        AO.MaxTorque          = math.huge
        AO.MaxAngularVelocity = math.huge
        AO.Responsiveness     = 80
        AO.RigidityEnabled    = true
        AO.CFrame             = target.rotation or part.CFrame
    end


    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
end

local smoothMovementConn = RunService.RenderStepped:Connect(function()
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(function()
                syncAlignTarget(part, partTargets[part])
            end)
        end
    end
end)

local function getMoveResponsiveness(multiplier)
    local base = 20 + partSpeed * 4
    return math.clamp(base * (multiplier or 1), 30, 200)
end

local useRotationTargets = false

local partTouchConns = {}

partCollisionState = {}
local partCollisionConns = {}


local function disableSelectedCollision(part)
    if not fakeCollisions then return end 
    if not (part and part.Parent) then return end

    if partCollisionState[part] == nil then
        partCollisionState[part] = part.CanCollide
    end

    part.CanCollide = false

    if not partCollisionConns[part] then
        partCollisionConns[part] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
            if part and part.Parent then
                part.CanCollide = false
            end
        end)
    end
end

local function restoreSelectedCollision(part)
    if partCollisionConns[part] then
        pcall(function() partCollisionConns[part]:Disconnect() end)
        partCollisionConns[part] = nil
    end

    if part and part.Parent and partCollisionState[part] ~= nil then
        pcall(function() part.CanCollide = partCollisionState[part] end)
    end
    partCollisionState[part] = nil
end

local function reclaimOnTouch(part)
    if not part or not part.Parent then return end

    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    local target = partTargets[part]
    pcall(function()

        local AP = getNetAP(part)
        if AP then
            AP.MaxForce    = math.huge
            AP.MaxVelocity = math.huge
            AP.Position    = (target and target.position) or part.Position
        end
        local AO = getNetAO(part)
        if AO then
            AO.MaxTorque          = math.huge
            AO.MaxAngularVelocity = math.huge
            AO.CFrame             = (target and target.rotation) or part.CFrame
        end

        local sign = (tick() % 0.2 < 0.1) and 1 or -1
        part.AssemblyLinearVelocity = part.AssemblyLinearVelocity
            + Vector3.new(0, sign * 0.01, 0)

        part.AssemblyAngularVelocity = Vector3.zero

        local sr = part:FindFirstChild("ServerResponse")
        if sr and sr:IsA("BodyForce") then
            sr.Force = Vector3.new(0, part.AssemblyMass * 100000, 0)
        end
    end)
end

local function isSelected(p)
    for _,s in ipairs(selectedParts) do if s==p then return true end end
    return false
end

local clearDrawDots

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
    if prevMode == "Minigun" or nextMode ~= "Minigun" then
        minigunIdx = 1
        minigunShotStart = 0
        minigunLastIdx = 0
    end
    if prevMode == "DroneV2" or nextMode ~= "DroneV2" then
        dv2Target = nil
        if dv2Label and nextMode ~= "DroneV2" then
            dv2Label.Text = "Inactive"
        end
    end
    if prevMode == "AnchorBomb" and nextMode ~= "AnchorBomb" then
        for part in pairs(anchorBombAnchored) do
            if part and part.Parent and isSelected(part) then
                pcall(function() part.Anchored = false end)
            end
            anchorBombAnchored[part] = nil
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

local _wallCache = nil
local function _wallTarget(index, total, part, t)
    local char   = LP.Character
    local root   = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return currentMouseHit end

    local mHit   = getFormationCenterTarget()
    local rp     = root.Position
    local scX    = math.max(0, formSizeX) / 10
    local scZ    = math.max(0, formSizeZ) / 10
    local scR    = math.max(scX, scZ)
    local scY    = math.max(0, formSizeY) / 3

    local ck     = total
    local entry  = _wallCache
    if not entry or not entry[total] then
        local rootCF = root.CFrame
        local totalX = 0
        local totalY = 0
        local n      = math.max(total, 1)
        for i = 1, total do
            local p = selectedParts[i]
            if p and p.Parent then
                totalX += (p.Size.X or 0)
                totalY += (p.Size.Y or 0)
            end
        end
        local avgX   = totalX / n
        local avgY   = totalY / n
        local cols   = math.ceil(math.sqrt(total))
        local rows   = math.ceil(total / cols)
        local spacingX = avgX + wallGap
        local spacingY = avgY + wallGap
        local ctr    = rp + rootCF.LookVector * wallDist * math.max(scX, scZ)
        local xs     = { avgX = avgX, avgY = avgY, spacingX = spacingX, spacingY = spacingY, ctr = ctr, rows = rows, cols = cols }
        _wallCache  = { [total] = xs }
    end

    local info  = _wallCache[total]
    local cols  = info.cols
    local ctr   = info.ctr
    local spacingX = info.spacingX
    local spacingY = info.spacingY
    local col   = ((index - 1) % cols) - (cols - 1) / 2
    local rows  = info.rows
    local row   = math.floor((index - 1) / cols) - (rows - 1) / 2
    return ctr + root.CFrame.RightVector * (col * spacingX) + Vector3.new(0, row * spacingY, 0)
end

local espLabels = {}

local function createEspTag(part)
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

    return { frame = tag, nameLbl = nameLbl, distLbl = distLbl, modeLbl = modeLbl }
end

local function addHL(part)
    if highlights[part] then return end

    if useESP then
        local tag = createEspTag(part)
        espLabels[part] = tag
        highlights[part] = tag.frame
    else

        local hl = Instance.new("Highlight")
        hl.Adornee             = part
        hl.FillColor           = HL.fillColor
        hl.OutlineColor        = HL.outlineColor
        hl.FillTransparency    = HL.fillTransparency
        hl.OutlineTransparency = HL.outlineTransparency
        hl.DepthMode           = HL.depthMode
        hl.Parent              = part
        highlights[part] = hl
    end
end

local function refreshAllHighlights()
    for part, hl in pairs(highlights) do
        if hl:IsA("Highlight") then
            hl.FillColor           = HL.fillColor
            hl.OutlineColor        = HL.outlineColor
            hl.FillTransparency    = HL.fillTransparency
            hl.OutlineTransparency = HL.outlineTransparency
            hl.DepthMode           = HL.depthMode
        end
    end
end

local function removeHL(part)
    if highlights[part] then
        highlights[part]:Destroy()
        highlights[part] = nil
        espLabels[part] = nil
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
        hl.Parent = EspScreenGui
        spcHighlight = hl
    end
end

local function updateESP()
    if not useESP or not next(espLabels) then return end

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

local function isPlayerPart(part)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and part:IsDescendantOf(plr.Character) then
            return true
        end
    end
    return false
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

local function selectPart(part)
    if not part or not part:IsA("BasePart") then return end
    if part.Anchored then return end
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
    pcall(function() disableSelectedCollision(part) end)

    partTouchConns[part] = part.Touched:Connect(function()
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
        AP.Responsiveness = 120
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
        AO.Responsiveness = 80
        AO.CFrame = part.CFrame
        AO.Attachment0 = attach

        task.spawn(function()
            RunService.RenderStepped:Wait()
            if part.Parent and part:FindFirstChild("NetAttach") and not part:FindFirstChild("ServerResponse") then
                local SR = Instance.new("BodyForce", part)
                SR.Name = "ServerResponse"
                SR.Force = Vector3.new(0, 0, part.AssemblyMass * 100000)
            elseif part.Parent and part:FindFirstChild("ServerResponse") then
                part.ServerResponse.Force = Vector3.new(0, 0, part.AssemblyMass * 100000)
            end
        end)

        if not partTargets[part] then
            partTargets[part] = {
                position = part.Position,
                rotation = part.CFrame,
                responsiveness = getMoveResponsiveness(1),
            }
        end
        syncAlignTarget(part, partTargets[part])
    end)
end

local function cleanupPartState(part, destroyPart)
    if not part then return end

    removeHL(part)

    if partTouchConns[part] then
        pcall(function() partTouchConns[part]:Disconnect() end)
        partTouchConns[part] = nil
    end

    if satTouchConns[part] then
        pcall(function() satTouchConns[part]:Disconnect() end)
        satTouchConns[part] = nil
    end

    restoreSelectedCollision(part)

    pcall(function()
        if part.Parent then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero

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

            if destroyPart then
                part:Destroy()
            end
        end
    end)

    partOffsets[part] = nil
    frozenTargets[part] = nil
    partTargets[part] = nil
    anchorBombAnchored[part] = nil
    satFired[part] = nil
end

local function resetSelectionState()
    selectedParts = {}
    partOffsets = {}
    frozenTargets = {}
    partTargets = {}
    anchorBombAnchored = {}
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

local function runAutoSelectScan()
    if autoSelectAll then
        selectAll()
    elseif autoSelectNear then
        selectInRange(autoSelRange)
    end
    autoSelectLastScan = tick()
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
    drawIndicators={}; drawTrail={}
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
    return hit and hit.Position.Y or nil
end

local function updateMouseHit()
    _mouseRayParams.FilterDescendantsInstances = getMouseExcludeList()


    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local x = mousePos.X
    local y = mousePos.Y - inset.Y

    local ray = Camera:ScreenPointToRay(x, y)
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000, _mouseRayParams)
    if hit then
        currentMouseHit = hit.Position
    else
        currentMouseHit = ray.Origin + ray.Direction * 1000
    end
end


local function sampleDrawTrailPoint(index, total)
    local trailLen = #drawTrail
    if trailLen < 2 then
        return nil
    end

    local segLens = table.create(trailLen - 1)
    local totalDist = 0

    for i = 1, trailLen - 1 do
        local segLen = (drawTrail[i + 1] - drawTrail[i]).Magnitude
        segLens[i] = segLen
        totalDist += segLen
    end

    if totalDist < 0.001 then
        return drawTrail[trailLen]
    end

    local targetDist = ((index - 1) / math.max(total - 1, 1)) * totalDist
    local accum = 0

    for i = 1, trailLen - 1 do
        local segLen = segLens[i]
        if accum + segLen >= targetDist then
            local alpha = (targetDist - accum) / math.max(segLen, 0.001)
            return drawTrail[i]:Lerp(drawTrail[i + 1], alpha)
        end
        accum += segLen
    end

    return drawTrail[trailLen]
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
    else
        return currentMouseHit
    end
end

local function getTarget(index, total, part, t)
    local mHit   = getFormationCenterTarget()
    local char   = LP.Character
    local rp = (char and char:FindFirstChild("HumanoidRootPart"))
               and char.HumanoidRootPart.Position or Vector3.zero
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
        local spin=band/6*math.pi*2+t*tornadoSpeed
        local rMax = math.max(scX, scZ)
        local r=(2.5+math.sin(t*1.5+index*0.7)*0.8)*rMax
        return Vector3.new(mHit.X+math.cos(spin)*r*scX,mHit.Y+h,mHit.Z+math.sin(spin)*r*scZ)

    elseif activeMode=="Ring" then
        local rMax = math.max(scX, scZ)
        local r=math.max(total*0.45,formRadius)*rMax; local a=angle+t*0.5
        return Vector3.new(mHit.X+math.cos(a)*r*scX,mHit.Y+1.5*scY+math.sin(t*1.2)*0.4,mHit.Z+math.sin(a)*r*scZ)

    elseif activeMode=="Orbit" then
        local a=angle+t*1.6; local vOff=math.sin(a*2+index)*4*scY
        return Vector3.new(mHit.X+math.cos(a)*orbitRadius*scX,mHit.Y+4*scY+vOff,mHit.Z+math.sin(a)*orbitRadius*scZ)

    elseif activeMode=="Spiral" then
        local a=ratio*2.5*math.pi*2+t*0.6; local r=ratio*8*math.max(scX,scZ)
        return Vector3.new(mHit.X+math.cos(a)*r*scX,mHit.Y+ratio*spiralHeight*scY,mHit.Z+math.sin(a)*r*scZ)

    elseif activeMode=="Wave" then
        local x=(ratio-.5)*math.max(total,1)*1.3*scX
        local wY=math.sin(ratio*math.pi*5+t*2.5)*waveAmp*scY
        local wZ=math.cos(ratio*math.pi*3+t*1.5)*1.2*scZ
        return Vector3.new(mHit.X+x,mHit.Y+wY+2*scY,mHit.Z+wZ)

    elseif activeMode=="Halo" then
        local rMax = math.max(scX, scZ)
        local r=math.max(total*0.4,formRadius)*rMax; local a=angle+t*0.35
        return Vector3.new(rp.X+math.cos(a)*r*scX,rp.Y+7*scY+math.sin(t*2.2)*0.3,rp.Z+math.sin(a)*r*scZ)

    elseif activeMode=="Drone" then
        local off=partOffsets[part] or Vector3.zero
        local driftX=math.sin(t*0.8+index*1.1)*2*scX
        local driftY=math.sin(t*1.3+index*0.9)*1*scY
        local driftZ=math.cos(t*0.65+index*1.4)*2*scZ
        return mHit+Vector3.new(off.X*1.8*scX,off.Y*1.8,off.Z*1.8*scZ)+Vector3.new(driftX,driftY,driftZ)+Vector3.new(0,4*scY,0)

    elseif activeMode=="DroneV2" then
        if dv2Target then
            return dv2Target.Position+Vector3.new(
                math.sin(t*8+index*1.7)*0.6,math.sin(t*6+index*0.9)*0.6,math.cos(t*8+index*1.3)*0.6)
        end
        local rX=formRadius*scX; local rZ=formRadius*scZ; local a=angle+t*0.45
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
        return (rp+Vector3.new(0,2*scY,0)):Lerp(mHit,ratio)


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
            mHit.X + sinY*math.cos(theta+t*0.2)*rx,
            mHit.Y + cosY*ry*yLatScale,
            mHit.Z + sinY*math.sin(theta+t*0.2)*rz)

    elseif activeMode=="Vortex" then
        local band=(index-1)%6; local h=math.floor((index-1)/6)*2.2*scY
        local spin=band/6*math.pi*2-t*tornadoSpeed
        local maxR = math.max(scX, scZ)
        local r=(1+(h/maxR)*0.35)*maxR
        return Vector3.new(mHit.X+math.cos(spin)*r*scX,mHit.Y+14*scY-h,mHit.Z+math.sin(spin)*r*scZ)

    elseif activeMode=="DNA" then
        local strand=(index-1)%2; local pos=math.floor((index-1)/2)
        local pr=total>2 and pos/math.floor(total/2) or 0
        local a=pr*3*math.pi*2+t*0.8+strand*math.pi
        local r=3*scR; local h=pr*12*scY
        return Vector3.new(mHit.X+math.cos(a)*r*scX,mHit.Y+h,mHit.Z+math.sin(a)*r*scZ)

    elseif activeMode=="Pulse" then
        local pulseR=formRadius*(1+math.sin(t*3)*0.45)*math.max(scX,scZ)
        local a=angle
        return Vector3.new(
            mHit.X+math.cos(a)*pulseR*scX,
            mHit.Y+2*scY+math.sin(t*3)*0.5,
            mHit.Z+math.sin(a)*pulseR*scZ)

    elseif activeMode=="Grid" then
        local cols=math.ceil(math.sqrt(total))
        local col=((index-1)%cols)-(cols-1)/2
        local row=math.floor((index-1)/cols)-(math.ceil(total/cols)-1)/2
        local spX=(part.Size.X+wallGap)*scX
        local spZ=(part.Size.X+wallGap)*scZ
        return Vector3.new(mHit.X+col*spX,mHit.Y+4*scY,mHit.Z+row*spZ)

    elseif activeMode=="Cube" then
        local verts={
            Vector3.new(1,1,1),Vector3.new(-1,1,1),Vector3.new(1,-1,1),Vector3.new(-1,-1,1),
            Vector3.new(1,1,-1),Vector3.new(-1,1,-1),Vector3.new(1,-1,-1),Vector3.new(-1,-1,-1),
        }
        local vi=((index-1)%8)+1; local v=verts[vi]
        local szX=formRadius*scX; local szZ=formRadius*scZ; local szY=formRadius*scY
        local rot=CFrame.Angles(t*0.5,t*0.7,t*0.3)
        local sv=Vector3.new(v.X*szX, v.Y*szY, v.Z*szZ)
        local rv=rot:VectorToWorldSpace(sv)
        return mHit+rv+Vector3.new(0,3*scY,0)

    elseif activeMode=="Scatter" then
        local scatter=(math.sin(t*0.75)+1)/2
        local off=(partOffsets[part] or Vector3.zero)
        local far=mHit+Vector3.new(off.X*14*scX,off.Y*14,off.Z*14*scZ)+Vector3.new(0,math.abs(off.Y)*4*scY,0)
        return mHit:Lerp(far,scatter)+Vector3.new(0,1*scY,0)

    elseif activeMode=="Star" then
        local isPoint=(index-1)%2==0
        local spoke=math.floor((index-1)/2)
        local sAngle=spoke/math.ceil(total/2)*math.pi*2+t*0.3
        local r=isPoint and formRadius*2*scR or formRadius*0.75*scR
        return Vector3.new(mHit.X+math.cos(sAngle)*r*scX,mHit.Y+2*scY,mHit.Z+math.sin(sAngle)*r*scZ)

    elseif activeMode=="Pendulum" then
        local swing=math.sin(t*2+index*0.55)*formRadius*scX
        local dip=-(1-math.cos(t*2+index*0.55))*formRadius*scY*0.5
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
        local fall = (t * 19 + phase / (math.pi * 2) * dropHeight) % dropHeight
        return Vector3.new(x, topY - fall, z)

    elseif activeMode=="Galaxy" then

        local arms   = 3
        local arm    = (index-1) % arms
        local posInArm = math.floor((index-1) / arms)
        local tpa    = math.ceil(total / arms)
        local ar     = tpa>1 and posInArm/(tpa-1) or 0
        local base   = arm/arms * math.pi*2
        local spiral = base + ar*math.pi*2.5 + t*0.4
        local r      = ar * formRadius*2*scR
        local tilt   = math.sin(t*1.5 + index)*0.35*scY
        return Vector3.new(mHit.X+math.cos(spiral)*r*scX, mHit.Y+tilt+1*scY, mHit.Z+math.sin(spiral)*r*scZ)

    elseif activeMode=="Blackhole" then

        local cycle  = (t*0.75) % 1
        local pull   = math.max(0, 1 - cycle*2.2)          
        local r      = formRadius * pull
        local spin   = angle - t*5*(1.2 - pull*0.9)        
        local h      = pull * 4
        return Vector3.new(mHit.X+math.cos(spin)*r, mHit.Y+h, mHit.Z+math.sin(spin)*r)

    elseif activeMode=="Lemniscate" then

        local phase  = ratio * math.pi*2 + t*0.65
        local denom  = 1 + math.sin(phase)^2 + 0.001
        local a      = formRadius * scR * 1.6
        local x      = a * math.cos(phase) / denom * scX
        local z      = a * math.sin(phase)*math.cos(phase) / denom * scZ
        local y      = math.sin(t*1.6 + index*0.45) * 0.55 * scY
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
        local spd    = 2.8 + (index%7)*0.25
        local ph     = t*spd + index*1.37
        local maxR = math.max(scX, scZ)
        local r      = formRadius * maxR
        return mHit + Vector3.new(0,3*scY,0) + p1*(math.cos(ph)*r*scX) + p2*(math.sin(ph)*r*scZ)

    elseif activeMode=="Crown" then

        local isSpike = (index-1)%2 == 0
        local spokes  = math.ceil(total/2)
        local si      = math.floor((index-1)/2)
        local a       = si/math.max(spokes,1)*math.pi*2 + t*0.12
        local r       = formRadius * scR
        if isSpike then
            local sway = math.sin(t*2 + si*0.9) * 0.15
            return Vector3.new(rp.X+math.cos(a)*r*scX, rp.Y+10*scY+sway, rp.Z+math.sin(a)*r*scZ)
        else
            return Vector3.new(rp.X+math.cos(a)*r*0.65*scX, rp.Y+7*scY, rp.Z+math.sin(a)*r*0.65*scZ)
        end

    elseif activeMode=="Swarm" then

        local off    = partOffsets[part] or Vector3.zero
        local wanderX = math.sin(t*1.1 + index*2.3 + off.X) * formRadius*scX
        local wanderY = math.sin(t*0.9 + index*1.7 + off.Y) * formRadius*0.55*scY
        local wanderZ = math.cos(t*1.3 + index*2.1 + off.Z) * formRadius*scZ
        local jitter = Vector3.new(
            math.sin(t*9  + index*3.1) * 0.7,
            math.sin(t*7  + index*2.7) * 0.35,
            math.cos(t*8  + index*3.5) * 0.7)
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
            local a     = (slot / ringSlots) * math.pi * 2 + t * 0.2
            local r     = math.max(3.5 * scX, 3.5 * scZ)
            local y     = rp.Y + high + layer * (2.1 * scY)
            return Vector3.new(
                rp.X + math.cos(a) * r,
                y,
                rp.Z + math.sin(a) * r)
        else
      
            local hi = index - clusterN
            local hn = math.max(total - clusterN, 1)
            local a  = (hi - 1) / hn * math.pi * 2 + t * 0.28
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

    elseif activeMode=="AnchorBomb" then

        return mHit + (partOffsets[part] or Vector3.zero) * 0.3

    elseif activeMode=="Slinky" then

        local step = math.max(2, math.floor(index * (formRadius * 0.35 + 1.5)))
        local idx  = math.max(1, #slinkyHistory - step)
        local pos  = slinkyHistory[idx] or mHit
        local off = partOffsets[part] or Vector3.zero
        return pos + Vector3.new(off.X*0.35*scX, off.Y*0.35, off.Z*0.35*scZ) + Vector3.new(0, 2 * scY, 0)

    elseif activeMode=="Fountain" then

        local jet = (t * 2.2 + ratio * 1.8) % 1
        local h   = math.sin(jet * math.pi) * formRadius * 2.8 * scY
        local off = partOffsets[part] or Vector3.zero
        local offScaled = Vector3.new(off.X*formRadius*0.35*scX, 0, off.Z*formRadius*0.35*scZ)
        return mHit + offScaled + Vector3.new(0, h + 1.5 * scY, 0)

    elseif activeMode=="Bounce" then

        local phase = (t * 1.4 + index * 0.12) % 2
        local alpha = phase < 1 and phase or (2 - phase)
        local off   = partOffsets[part] or Vector3.zero
        local offScaled = Vector3.new(off.X*0.5*scX, 0, off.Z*0.5*scZ)
        return mHit:Lerp(rp + Vector3.new(0, 7 * scY, 0), alpha) + offScaled

    elseif activeMode=="Ripple" then

        local maxR = math.max(scX, scZ)
        local waveR = ((t * 2.4 - index * 0.18) % (formRadius * 2.2 * maxR + 1)) + 1
        local a     = angle + t * 0.25
        return Vector3.new(mHit.X + math.cos(a) * waveR * scX, mHit.Y + 2 * scY, mHit.Z + math.sin(a) * waveR * scZ)

    elseif activeMode=="Juggle" then

        local toss = math.sin(t * 2.4 + index * 0.75)
        local h    = (toss + 1) * 0.5 * formRadius * scY * 2.2 + 2 * scY
        local spreadX = formRadius * 0.35 * scX
        local spreadZ = formRadius * 0.35 * scZ
        return Vector3.new(
            mHit.X + math.cos(angle) * spreadX,
            mHit.Y + h,
            mHit.Z + math.sin(angle) * spreadZ)

    elseif activeMode=="Constellation" then

        local a   = angle + t * 0.45
        local r   = formRadius * scR * (0.85 + 0.15 * math.sin(index * 1.9 + t))
        local bob = math.sin(t * 1.8 + index * 0.6) * 0.4 * scY
        return Vector3.new(mHit.X + math.cos(a) * r * scX, mHit.Y + 2.5 * scY + bob, mHit.Z + math.sin(a) * r * scZ)


    elseif activeMode=="Rose" then

        local k = 3 + ((total % 4) - 1)  
        local theta = angle + t * 0.6
        local a = formRadius * scR * (0.75 + 0.25*math.sin(t*1.3 + ratio*6))
        local r = a * math.cos(k * theta)

        local y = 2*scY + (math.sin(theta*0.5 + t*1.7 + index*0.12) * 0.8 + ratio*0.3) * (6*scY)
        return Vector3.new(mHit.X + math.cos(theta) * r * scX, mHit.Y + y, mHit.Z + math.sin(theta) * r * scZ)

    elseif activeMode=="OrbitSin" then

        local a = angle + t*0.9
        local baseR = math.max(0.001, formRadius * scR)
        local r = baseR * (0.75 + 0.25*math.sin(t*2.1 + ratio*6 + index*0.08))
        local y = 2*scY + scY*2.5*math.sin(t*1.4 + ratio*math.pi*2) + (partOffsets[part] and partOffsets[part].Y or 0)*0.6
        return Vector3.new(mHit.X + math.cos(a)*r*scX, mHit.Y + y, mHit.Z + math.sin(a)*r*scZ)

    elseif activeMode=="Liss" then

        local u = ratio*math.pi*2 + t*0.55
        local x = math.sin(3*u + t*0.3 + index*0.02)
        local y = math.cos(2*u - t*0.22 + index*0.03)
        local z = math.sin(4*u + t*0.18 - index*0.01)
        local ampX = (formRadius * scR) * 1.0
        local ampY = (formRadius * scY) * 1.0
        local ampZ = (formRadius * scR) * 1.0
        return Vector3.new(mHit.X + x*ampX*scX,
            mHit.Y + y*ampY + 2*scY,
            mHit.Z + z*ampZ*scZ)

    elseif activeMode=="Swing" then

        local swingA = angle + math.sin(t*1.2)*0.35 + t*0.25
        local swingLen = (formRadius*scR) * (0.7 + 0.3*math.sin(t*2.0 + ratio*5))
        local pos = Vector3.new(
            mHit.X + math.cos(swingA)*swingLen*scX,
            mHit.Y + (2.5*scY + math.sin(t*1.6 + index*0.08)*scY*3),
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
    end

    return mHit
end


local function tickParts()
    local t     = tick()
    local total = #selectedParts
    local char  = LP.Character
    

    local partsToUse = total
    if useLimits and total > partLimit then
        partsToUse = partLimit
    end

    local cRoot=char and char:FindFirstChild("HumanoidRootPart")
    if cRoot then
        local p=cRoot.Position
        local step = (activeMode=="Comet") and 0.45 or 0.8
        if #cometHistory==0 or (cometHistory[#cometHistory]-p).Magnitude>step then
            table.insert(cometHistory,p)
            if #cometHistory>COMET_MAX then table.remove(cometHistory,1) end
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
            if not p or not p.Parent then
                satFired[p] = nil
                if satTouchConns[p] then
                    pcall(function() satTouchConns[p]:Disconnect() end)
                    satTouchConns[p] = nil
                end
            elseif (now - fireTime) > SAT_TTL
                or (p.Position - satTarget).Magnitude < 3 then
                satFired[p] = nil
                if satTouchConns[p] then
                    pcall(function() satTouchConns[p]:Disconnect() end)
                    satTouchConns[p] = nil
                end
            end
        end
    end


    local isWall   = activeMode=="Wall"
    local isMG     = activeMode=="Minigun"
    local isSat    = activeMode=="Satellite"
    local wallRoot = isWall and (char and char:FindFirstChild("HumanoidRootPart"))
    local isDV2    = activeMode=="DroneV2"
    local isAB     = activeMode=="AnchorBomb"

    for i=#selectedParts,1,-1 do
        local part=selectedParts[i]
        if not part or not part.Parent then
            removeHL(part); table.remove(selectedParts,i); frozenTargets[part]=nil; partTargets[part]=nil
        else

            if useLimits and i > partsToUse then
                pcall(function()
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end)
                partTargets[part] = {
                    position = part.Position,
                    rotation = part.CFrame,
                    responsiveness = getMoveResponsiveness(1),
                }
                syncAlignTarget(part, partTargets[part])
            else
                local tgt
                if frozen then
                    if not frozenTargets[part] then frozenTargets[part]=part.Position end
                    tgt=frozenTargets[part]
                else
                    frozenTargets[part]=nil; tgt=getTarget(i,total,part,t)
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


                if isAB then
                    if dist < 5 then
                        pcall(function() part.Anchored = true end)
                        anchorBombAnchored[part] = true
                    end
                end

                if isDV2 and dv2Target then
                    pcall(function()

                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 1500,
                            (math.random() - 0.5) * 1500,
                            (math.random() - 0.5) * 1500
                        )

                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = part.CFrame
                        partTargets[part].responsiveness = getMoveResponsiveness(3.5)
                        syncAlignTarget(part, partTargets[part])


                        if not satTouchConns[part] then
                            satTouchConns[part] = part.Touched:Connect(function(hit)
                                if not hit or not hit.Parent or hit.Anchored then return end
                                if hit == workspace.Terrain then return end

                                pcall(function()
                                    part.AssemblyAngularVelocity = Vector3.new(
                                        (math.random() - 0.5) * 1500,
                                        (math.random() - 0.5) * 1500,
                                        (math.random() - 0.5) * 1500
                                    )
                                end)
                            end)
                        end
                    end)
                elseif isWall and wallRoot then
                    local lv = wallRoot.CFrame.LookVector
                    targetRotation = CFrame.lookAt(part.Position, part.Position + lv)
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
local PAL = GUI.PAL



local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "Atomizer"
ScreenGui.ResetOnSpawn     = false
ScreenGui.IgnoreGuiInset   = true
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder     = GUI.DISPLAY_ORDER
ScreenGui.Parent           = getGuiParent()

local function unloadScript()

    pcall(function() if ownerConn then ownerConn:Disconnect() end end)
    pcall(function() if renderOwnerConn then renderOwnerConn:Disconnect() end end)
    pcall(function() if preSimConn then preSimConn:Disconnect() end end)
    pcall(function() if smoothMovementConn then smoothMovementConn:Disconnect() end end)
    pcall(function() if EspRenderConn then EspRenderConn:Disconnect() end end)
    pcall(function() if mainHeartbeatConn then mainHeartbeatConn:Disconnect() end end)
    pcall(function() if renderSteppedConn then renderSteppedConn:Disconnect() end end)
    if NX.dead then return end
    NX.dead = true

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
end
local function corner(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 5) end

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


function mkSlider(parent,ltext,lo,hi,def,order,onChange)
    local wrap=mkF({Size=UDim2.new(1,0,0,42),BackgroundColor3=PAL.SURFACE,LayoutOrder=order},parent)
    corner(wrap,5)
    local lbl=mkL({Size=UDim2.new(1,-8,0,16),Position=UDim2.new(0,8,0,3),
        Text=ltext.."  "..def,TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,
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
    thumb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=true end end)
    reg(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=false end end))
    reg(UserInputService.InputChanged:Connect(function(i)
        if not sl or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local ap=track.AbsolutePosition; local as=track.AbsoluteSize
        local r=math.clamp((i.Position.X-ap.X)/as.X,0,1)
        local isF=(hi-lo)<=5
        local val=isF and (math.floor((lo+(hi-lo)*r)*10)/10) or math.floor(lo+(hi-lo)*r)
        fill.Size=UDim2.new(r,0,1,0); thumb.Position=UDim2.new(r,-5,0.5,-5)
        lbl.Text=ltext.."  "..val; if onChange then onChange(val) end
    end))
    return wrap
end


UI = nil

function buildMinButton(TBar)
    local MinBtn=mkB({Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-58,0,9),
        BackgroundColor3=Color3.fromRGB(32,32,42),Text="-",TextColor3=PAL.T1,TextSize=13,
        Font=Enum.Font.GothamBold,ZIndex=GUI.Z+2},TBar)
    return MinBtn
end


function buildCloseButton(TBar)
    local CloseBtn=mkB({Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,0,9),
        BackgroundColor3=PAL.B_RED,Text="X",TextColor3=Color3.new(1,1,1),TextSize=12,
        Font=Enum.Font.GothamBold,ZIndex=GUI.Z+2},TBar)
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
        Text="Atomizer",TextColor3=PAL.T1,TextSize=13,Font=Enum.Font.GothamBold,
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


function buildBody(Main, MinBtn, W, H, MINI)
    local Body=mkF({Size=UDim2.new(1,0,1,-MINI),Position=UDim2.new(0,0,0,MINI),BackgroundTransparency=1},Main)
    local minimized=false
    MinBtn.MouseButton1Click:Connect(function()
        minimized=not minimized; Body.Visible=not minimized
        Main.Size=UDim2.new(0,W,0,minimized and MINI or H); MinBtn.Text=minimized and "+" or "-"
    end)
    return Body
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
    local Body = buildBody(Main, MinBtn, W, H, MINI)

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
        local b=mkTab({Size=UDim2.new(0,102,1,0),BackgroundColor3=PAL.B_DEF,Text=name,
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
        local b=mkTab({Size=UDim2.new(0,98,0,22),BackgroundColor3=PAL.B_DEF,
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

        local clickSelActive = false
        local clickSelBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Click-Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=2},selP)
        clickSelBtn.MouseButton1Click:Connect(function()
            clickSelActive = not clickSelActive
            clickSelBtn.BackgroundColor3 = clickSelActive and Color3.fromRGB(18,55,24) or PAL.B_DEF
            clickSelBtn.TextColor3 = clickSelActive and Color3.fromRGB(110,210,130) or PAL.T1
            clickSelBtn.Text = "Click-Select: "..(clickSelActive and "ON ✓" or "OFF")
        end)

        local _,_,_ = (function()
            local row,b1,b2=mkRow2(selP,3,
                {BackgroundColor3=PAL.B_DEF,Text="All",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham},
                {BackgroundColor3=PAL.B_DEF,Text="In Range",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham})
            b1.MouseButton1Click:Connect(function() selectAll() end)
            b2.MouseButton1Click:Connect(function() selectInRange(autoSelRange) end)
            return row,b1,b2
        end)()

        local autoAllBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Auto Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},selP)
        local autoNearBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Auto Near Select: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=5},selP)

        local function refreshAutoSelectButtons()
            autoAllBtn.BackgroundColor3 = autoSelectAll and Color3.fromRGB(18,55,24) or PAL.B_DEF
            autoAllBtn.TextColor3 = autoSelectAll and Color3.fromRGB(110,210,130) or PAL.T1
            autoAllBtn.Text = "Auto Select: "..(autoSelectAll and "ON ✓" or "OFF")

            autoNearBtn.BackgroundColor3 = autoSelectNear and Color3.fromRGB(22,38,75) or PAL.B_DEF
            autoNearBtn.TextColor3 = autoSelectNear and Color3.fromRGB(130,175,255) or PAL.T1
            autoNearBtn.Text = "Auto Near Select: "..(autoSelectNear and "ON ✓" or "OFF")
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

        mkSlider(selP,"Sel Range",5,300,autoSelRange,6,function(v) autoSelRange=v end)

        local clearBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_RED,
            Text="Clear Selection",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},selP)
        clearBtn.MouseButton1Click:Connect(function()
            autoSelectAll = false
            autoSelectNear = false
            spcPart = nil
            clearSelection(false)
            refreshAutoSelectButtons()
        end)
        refreshAutoSelectButtons()

        return selInfo, clickSelBtn, clearBtn, refreshAutoSelectButtons, clickSelActive
    end


    local function buildFormationSection(selP)
        mkDiv(selP,8)
        mkSec("FORMATION", selP, 9)

        local freezeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Formation Freeze: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=10},selP)
        freezeBtn.MouseButton1Click:Connect(function()
            frozen=not frozen; frozenTargets={}
            freezeBtn.BackgroundColor3=frozen and Color3.fromRGB(22,38,75) or PAL.B_DEF
            freezeBtn.TextColor3=frozen and Color3.fromRGB(130,175,255) or PAL.T1
            freezeBtn.Text="Formation Freeze: "..(frozen and "ON ✓" or "OFF")
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
            gOwnBtn.Text="Global Ownership: "..(globalOwnership and "ON ✓" or "OFF")
        end)

        mkSlider(selP,"Owner Radius",10,300,ownerRadius,15,function(v) ownerRadius=v end)

        local fakeColBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Fake Collisions: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},selP)
        fakeColBtn.MouseButton1Click:Connect(function()
            fakeCollisions=not fakeCollisions
            fakeColBtn.BackgroundColor3=fakeCollisions and Color3.fromRGB(22,38,75) or PAL.B_DEF
            fakeColBtn.TextColor3=fakeCollisions and Color3.fromRGB(130,175,255) or PAL.T1
            fakeColBtn.Text="Fake Collisions: "..(fakeCollisions and "ON ✓" or "OFF")

            for _, part in ipairs(selectedParts) do
                if fakeCollisions then
                    pcall(function() disableSelectedCollision(part) end)
                else
                    pcall(function() restoreSelectedCollision(part) end)
                end
            end
        end)
    end

    local selInfo, clickSelBtn, clearBtn, _refreshAutoSel, clickSelActive = buildSelSubPanel(spCont, sPanels)
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

        local modeBtns={}
        for _,mn in ipairs(MODES) do
            local isDV2=mn=="DroneV2"
            local mb=mkTab({BackgroundColor3=isDV2 and Color3.fromRGB(44,15,6) or PAL.B_DEF,
                Text=mn,TextColor3=isDV2 and Color3.fromRGB(230,110,55) or PAL.T2,
                TextSize=10,Font=Enum.Font.Gotham},mGrid)
            modeBtns[mn]=mb
        end

        local function refreshModes()
            for name,mb in pairs(modeBtns) do
                local on=name==activeMode; local isDV2=name=="DroneV2"
                mb.BackgroundColor3=on and (isDV2 and PAL.DV2C or PAL.ACC) or (isDV2 and Color3.fromRGB(44,15,6) or PAL.B_DEF)
                mb.TextColor3=on and Color3.fromRGB(8,8,12) or (isDV2 and Color3.fromRGB(230,110,55) or PAL.T2)
            end
        end
        refreshModes()
        for name,mb in pairs(modeBtns) do
            mb.MouseButton1Click:Connect(function()
                if activeMode ~= name then
                    clearModeState(activeMode, name)
                    activeMode=name
                    refreshModes()
                end
            end)
        end

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

        formTypeBtns["Mouse"] = ftb1
        formTypeBtns["Player"] = ftb2
        formTypeBtns["ClosestNPC"] = ftb3
        formTypeBtns["ClickArea"] = ftb4

        local function refreshFormationType()
            for ftype, btn in pairs(formTypeBtns) do
                local on = (ftype == formationType) or (ftype == "Mouse" and formationType == "Mouse")
                btn.BackgroundColor3 = on and PAL.ACC or PAL.B_DEF
                btn.TextColor3 = on and Color3.fromRGB(8,8,12) or PAL.T1
            end
        end
        refreshFormationType()

        ftb1.MouseButton1Click:Connect(function() formationType="Mouse"; refreshFormationType() end)
        ftb2.MouseButton1Click:Connect(function() formationType="Player"; refreshFormationType() end)
        ftb3.MouseButton1Click:Connect(function() formationType="ClosestNPC"; refreshFormationType() end)
        ftb4.MouseButton1Click:Connect(function() formationType="ClickArea"; refreshFormationType() end)

        mkSec("SCALE & DRAW", modSF, 6)

        mkSlider(modSF,"Form Size X",0,100,formSizeX,7,function(v) formSizeX=v end)
        mkSlider(modSF,"Form Size Y",0,100,formSizeY,8,function(v) formSizeY=v end)
        mkSlider(modSF,"Form Size Z",0,100,formSizeZ,9,function(v) formSizeZ=v end)


        mkSlider(modSF,"Form Offset Y",-20,20,formOffsetY,10,function(v) formOffsetY=v end)

        mkL({Size=UDim2.new(1,0,0,14),
            Text="Hold Mouse1 while in Draw mode to trace a path",
            TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=8},modSF)
        local clearDrawBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Clear Draw Trail",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=9},modSF)
        clearDrawBtn.MouseButton1Click:Connect(function() clearDrawDots() end)
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
        mkSlider(parSF,"Fling Force",50,2000,flingForce,16,function(v) flingForce=v end)
        mkSlider(parSF,"Fling Range", 5, 200,flingRange,17,function(v) flingRange=v end)
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
        mkL({Size=UDim2.new(1,0,0,14),Text="Enable → click any unanchored part → follows camera ray",
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
            spcBtn.Text="Single Part Control: "..(spcActive and "ON ✓" or "OFF")
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
        mkSec("PART LIMITS", toolP, 7)

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
                {BackgroundColor3=PAL.B_GRN,Text=" Anchor",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham},
                {BackgroundColor3=PAL.B_BLU,Text=" Unanchor",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
            a1.MouseButton1Click:Connect(function()
                for _,p in ipairs(selectedParts) do pcall(function() p.Anchored=true end) end end)
            a2.MouseButton1Click:Connect(function()
                for _,p in ipairs(selectedParts) do pcall(function() p.Anchored=false end) end end)
        end
        local delBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_RED,
            Text="Delete Selected",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=12},toolP)
        delBtn.MouseButton1Click:Connect(function()
            clearSelection(true)
        end)

        mkDiv(toolP,13)
        mkSec("HIGHLIGHT", toolP, 14)

        local espBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Mode: Highlight (through walls)",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=15},toolP)
        espBtn.MouseButton1Click:Connect(function()
            useESP=not useESP
            espBtn.BackgroundColor3=useESP and Color3.fromRGB(16,32,56) or PAL.B_DEF
            espBtn.TextColor3=useESP and Color3.fromRGB(100,150,255) or PAL.T1
            espBtn.Text="Mode: "..(useESP and "ESP UI Labels" or "Highlight (through walls)")
            for _,part in ipairs(selectedParts) do removeHL(part); addHL(part) end
        end)

        mkSec("HIGHLIGHT COLOR", toolP, 16)
        mkL({Size=UDim2.new(1,0,0,12),Text="Preset colors (fill + outline)",
            TextColor3=PAL.T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=17},toolP)

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
            hlOutlineBtn.Text = "Outline: "..(on and "ON ✓" or "OFF")
            refreshAllHighlights()
        end)


        local hlDepthBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=Color3.fromRGB(18,55,24),
            Text="Through Walls: ON ✓",TextColor3=Color3.fromRGB(110,210,130),
            TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=23},toolP)
        hlDepthBtn.MouseButton1Click:Connect(function()
            local throughWalls = HL.depthMode == Enum.HighlightDepthMode.AlwaysOnTop
            HL.depthMode = throughWalls
                and Enum.HighlightDepthMode.Occluded
                or  Enum.HighlightDepthMode.AlwaysOnTop
            local on = HL.depthMode == Enum.HighlightDepthMode.AlwaysOnTop
            hlDepthBtn.BackgroundColor3 = on and Color3.fromRGB(18,55,24) or PAL.B_DEF
            hlDepthBtn.TextColor3       = on and Color3.fromRGB(110,210,130) or PAL.T1
            hlDepthBtn.Text = "Through Walls: "..(on and "ON ✓" or "OFF")
            refreshAllHighlights()
        end)

        return spcBtn
    end

    local spcBtn = buildToolsSubPanel(makeSubPanel)
    setSTab("Sel")
    return selInfo, clickSelBtn, clearBtn, freezeBtn, spcBtn, clickSelActive
end


local function buildNpcSearchBox(npcControlPanel)
    local SB = {}  
    SB.box = Instance.new("TextBox")
    SB.box.Size = UDim2.new(1,0,0,24)
    SB.box.BackgroundColor3 = PAL.B_DEF
    SB.box.BorderSizePixel = 0
    SB.box.Text = ""
    SB.box.PlaceholderText = "🔍 Search NPCs..."
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

local function buildNpcPanelFull()
    local ctx = getgenv()._atomizerNpcCtx
    if not ctx then return end
    local npcControlPanel = ctx.controlPanel
    local npcSpCont       = ctx.spCont
    local npcSPanels      = ctx.sPanels
    local npcSTabs        = ctx.sTabs
    local npcSBtns        = ctx.sBtns
    local npcSTabRow      = ctx.sTabRow
    local npcStat         = ctx.stat

    buildNpcSearchBox(npcControlPanel)


    local npcAurasPanel = Instance.new("ScrollingFrame")
    do
        npcAurasPanel.Size=UDim2.new(1,0,1,0); npcAurasPanel.BackgroundTransparency=1
        npcAurasPanel.BorderSizePixel=0; npcAurasPanel.ScrollBarThickness=2
        npcAurasPanel.ScrollBarImageColor3=PAL.ACC2; npcAurasPanel.Visible=false
        npcAurasPanel.Parent=npcSpCont
        npcSPanels["Auras"]=npcAurasPanel
        local ll = Instance.new("UIListLayout", npcAurasPanel)
        ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,6)
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            npcAurasPanel.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8)
        end)
    end

 
    local npcToolsPanel = Instance.new("ScrollingFrame")
    do
        npcToolsPanel.Size=UDim2.new(1,0,1,0); npcToolsPanel.BackgroundTransparency=1
        npcToolsPanel.BorderSizePixel=0; npcToolsPanel.ScrollBarThickness=2
        npcToolsPanel.ScrollBarImageColor3=PAL.ACC2; npcToolsPanel.Visible=false
        npcToolsPanel.Parent=npcSpCont
        npcSPanels["Guns"]=npcToolsPanel
        local ll = Instance.new("UIListLayout", npcToolsPanel)
        ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,6)
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            npcToolsPanel.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8)
        end)
    end


    do
        local _,pb,rb=mkRow2(npcControlPanel,2,
            {BackgroundColor3=PAL.B_DEF,Text=" Pick NPC",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham},
            {BackgroundColor3=PAL.B_RED,Text=" Release [Tab]",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
        local npcPickActive=false
        local function setNPCPick(on)
            npcPickActive=on
            pb.BackgroundColor3=on and Color3.fromRGB(18,55,24) or PAL.B_DEF
            pb.TextColor3=on and Color3.fromRGB(110,210,130) or PAL.T1
            pb.Text=on and " Pick NPC: ON ✓" or " Pick NPC"
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

    mkDiv(npcControlPanel,13); mkSec("LIFECYCLE",npcControlPanel,14)
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
        npcCtrlBtn.Text = "NPC Control: "..(npcControlEnabled and "ON ✓" or "OFF")
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
            fajBtn.Text="Freeze AutoJump: "..(npcControlFreezeAutoJump and "ON ✓" or "OFF")
        end)
        local hmBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Halt MoveTo: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=23},npcControlPanel)
        hmBtn.MouseButton1Click:Connect(function()
            npcControlHaltMoveTo=not npcControlHaltMoveTo
            hmBtn.BackgroundColor3=npcControlHaltMoveTo and Color3.fromRGB(18,55,24) or PAL.B_DEF
            hmBtn.TextColor3=npcControlHaltMoveTo and Color3.fromRGB(110,210,130) or PAL.T1
            hmBtn.Text="Halt MoveTo: "..(npcControlHaltMoveTo and "ON ✓" or "OFF")
        end)
    end


    do

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
                btn.Text = lbl..": "..(getF() and "ON ✓" or "OFF")
            end)
            mkSlider(npcAurasPanel,lbl:match("^%S+").." Range",3,rMax,getR(),lo+1,setR)

            if lbl=="Speed Aura" then
                mkSlider(npcAurasPanel,"Speed Amount",1,200,speedAuraSpeed,lo+2,function(v) speedAuraSpeed=v end)
            elseif lbl=="Spin Aura" then
                mkSlider(npcAurasPanel,"Spin Speed",1,40,spinAuraSpeed,lo+2,function(v) spinAuraSpeed=v end)
            end
        end
    end


    do
        local GUN_DEFS = {
            {"Finger Gun", function() return fingerGunEnabled end, function(v) fingerGunEnabled=v end,
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
                btn.Text = lbl..": "..(getF() and "ON ✓" or "OFF")
            end)
        end

        local tkBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Telekinesis Gun: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},npcToolsPanel)
        local fzBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=PAL.B_DEF,
            Text="Freeze Gun: OFF",TextColor3=PAL.T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=5},npcToolsPanel)
        local function refreshTKFZ()
            tkBtn.BackgroundColor3=NX.tkGun and Color3.fromRGB(90,40,120) or PAL.B_DEF
            tkBtn.TextColor3=NX.tkGun and Color3.fromRGB(220,170,255) or PAL.T1
            tkBtn.Text="Telekinesis Gun: "..(NX.tkGun and "ON ✓" or "OFF")
            fzBtn.BackgroundColor3=NX.freezeGun and Color3.fromRGB(20,70,120) or PAL.B_DEF
            fzBtn.TextColor3=NX.freezeGun and Color3.fromRGB(150,210,255) or PAL.T1
            fzBtn.Text="Freeze Gun: "..(NX.freezeGun and "ON ✓" or "OFF")
        end
        tkBtn.MouseButton1Click:Connect(function() NX.tkGun=not NX.tkGun; if NX.tkGun then NX.freezeGun=false end; refreshTKFZ() end)
        fzBtn.MouseButton1Click:Connect(function() NX.freezeGun=not NX.freezeGun; if NX.freezeGun then NX.tkGun=false end; refreshTKFZ() end)
    end


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

    getgenv()._atomizerNpcCtx = nil  
end


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
    getgenv()._atomizerNpcCtx = {
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

local function buildInterface()
    local Main, Body = buildMainFrame()
    local Cont, mPanels, setMTab = buildMainTabs(Body)
    local selInfo, clickSelBtn, clearBtn, freezeBtn, spcBtn, clickSelActive = buildPartsPanel(Cont, mPanels)
    local npcStat = buildNpcPanel(Cont, mPanels)


    buildNpcPanelFull()

    setMTab("Parts")

    return {
        ScreenGui=ScreenGui, selInfo=selInfo, clickSelBtn=clickSelBtn,
        clearBtn=clearBtn, freezeBtn=freezeBtn, spcBtn=spcBtn, npcStat=npcStat,
        getClickSelActive=function() return clickSelActive end,
        unload=unloadScript,
    }
end
UI = buildInterface()


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
    end
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
            local h = model:FindFirstChildOfClass("Humanoid")
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

reg(Mouse.Button1Down:Connect(function()
    local clickTarget = Mouse.Target
    if activeMode=="Draw" then isDrawing=true end


    if fingerGunEnabled or sitGunEnabled or grabGunEnabled then
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


    if NX.freezeGun then
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

    if formationType == "ClickArea" then
        clickFormPos = currentMouseHit
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
                        (math.random() - 0.5) * 2000,
                        (math.random() - 0.5) * 2000,
                        (math.random() - 0.5) * 2000
                    )

                    local toTarget = (satTarget - part.Position).Unit
                    part.AssemblyLinearVelocity = toTarget * 500 + Vector3.new(
                        (math.random() - 0.5) * 100,
                        (math.random() - 0.5) * 100 + 50,
                        (math.random() - 0.5) * 100
                    )
                end)


                if satTouchConns[part] then
                    pcall(function() satTouchConns[part]:Disconnect() end)
                end
                satTouchConns[part] = part.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if hit == workspace.Terrain then return end

                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 2000,
                            (math.random() - 0.5) * 2000,
                            (math.random() - 0.5) * 2000
                        )
                    end)
                end)
            end
        end
        return
    end

    if spcActive then
        if clickTarget and clickTarget:IsA("BasePart") and not clickTarget.Anchored then
            local char=LP.Character
            if not (char and clickTarget:IsDescendantOf(char)) then
                spcPart=clickTarget; updateSpcHighlight(spcPart); return
            end
        end
        return
    end

    if UI.getClickSelActive() and clickTarget then
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
                npcCtrlBtn.Text="NPC Control: ON ✓"
            end
        end
    end
end))

reg(Mouse.Button1Up:Connect(function()
    isDrawing=false
end))


reg(UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Tab and npcTarget then
        releaseNPC(); UI.npcStat.Text="Released via Tab"
    end
    if inp.KeyCode==Enum.KeyCode.Escape and spcActive then
        if spcPart then pcall(function() spcPart.AssemblyLinearVelocity=Vector3.zero end) end
        spcPart=nil; spcActive=false; updateSpcHighlight(nil)
        UI.spcBtn.BackgroundColor3=PAL.B_DEF; UI.spcBtn.TextColor3=PAL.T1
        UI.spcBtn.Text="Single Part Control: OFF"
    end
end))


reg(RunService.Heartbeat:Connect(function()
    updateMouseHit()

    if autoSelectAll or autoSelectNear then
        local now = tick()
        if (now - autoSelectLastScan) >= AUTO_SELECT_INTERVAL then
            runAutoSelectScan()
        end
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
        if #drawTrail==0 or (drawTrail[#drawTrail]-pos).Magnitude>1.0 then
            table.insert(drawTrail,pos)
            if #drawTrail>600 then table.remove(drawTrail,1) end
            if #drawTrail%8==0 then addDrawDot(pos) end  
        end
    end


    if #selectedParts>0 or spcActive or globalOwnership or activeMode=="Comet" then
        tickParts()
    end


    tickAuras()


    UI.selInfo.Text="#"..#selectedParts.." selected · "..activeMode
        ..(frozen and " [FROZEN]" or "")..(attracting and " [ATTRACT]" or "")
        ..(hasFileSystem and " · cfg" or "")


    saveConfig()
end))

reg(RunService.RenderStepped:Connect(function()
    if useESP then updateESP() end
end))


