--[[
╔════════════════════════════════════════════════════════════════════╗
║     ATOMIZER  —  LocalScript                                 ║
║  Gate:  sethiddenproperty required (silent exit if absent)   ║
║  40 formation modes · sub-tabbed compact UI                  ║
║  Ownership: SimRadius + alternating micro-bump every frame   ║
║  Draw: click-drag + neon 3D path indicators                  ║
║  Selection: unanchored parts only (never modifies .Anchored) ║
╚════════════════════════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────────────────────────
-- [0]  ENVIRONMENT CHECK
-- ─────────────────────────────────────────────────────────────
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
-- ─────────────────────────────────────────────────────────────
-- [1]  SERVICES
-- ─────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local CoreGui          = game:GetService("CoreGui")

local GUI_DISPLAY_ORDER = 100000
local GUI_ESP_ORDER     = 100001
local ESP_ACCENT        = Color3.fromRGB(80, 255, 210)

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return CoreGui
end

local EspScreenGui = Instance.new("ScreenGui")
EspScreenGui.Name             = "Atomizer_ESP"
EspScreenGui.ResetOnSpawn     = false
EspScreenGui.IgnoreGuiInset   = true
EspScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
EspScreenGui.DisplayOrder     = GUI_ESP_ORDER
EspScreenGui.Parent           = getGuiParent()

local LP     = Players.LocalPlayer
local Mouse  = LP:GetMouse()
local Camera = workspace.CurrentCamera

-- ─────────────────────────────────────────────────────────────
-- [2]  STATE & TUNABLE VALUES
-- ─────────────────────────────────────────────────────────────
local connections   = {}
local selectedParts = {}
local partOffsets   = {}    -- per-part Vector3 jitter
local highlights    = {}    -- SelectionBox per part

-- Part control
local activeMode   = "Tornado"
local partSpeed    = 25
local maxVelocity  = math.huge  -- Unlimited velocity (constraint-based movement)
local formRadius   = 7

-- Formation sizing controls (replace old single formScale)
local formSizeX    = 10
local formSizeY    = 3
local formSizeZ    = 10
local formOffsetY  = 0

-- Legacy: keep formScale name for config backwards compatibility
-- It is no longer used by getTarget().
local formScale    = 1.0
local wallDist     = 7
local wallGap      = 0.1
local flingForce   = 800
local flingRange   = 40
local tornadoSpeed = 4
local spiralHeight = 14
local waveAmp      = 3
local orbitRadius  = 9
local autoSelRange = 60
local autoSelectAll = false
local autoSelectNear = false
local autoSelectLastScan = 0
local AUTO_SELECT_INTERVAL = 5
local ownerRadius  = 100

-- Toggles
local frozen          = false
local frozenTargets   = {}
local globalOwnership = false
local attracting      = false
local attractTimer    = 0
local fakeCollisions  = false  -- Toggle for disabling collisions on selected parts

-- Smooth movement targets (for constraint-based interpolation)
local partTargets     = {}  -- part -> {position, rotation}

-- Ownership micro-bump (alternates sign every frame → zero net drift)
local _bumpSign = 1

-- Minigun mode state
local minigunIdx       = 1     -- which part is currently firing
local minigunShotStart = 0     -- when current shot began (stuck fallback only)
local minigunLastIdx   = 0
local MINIGUN_STUCK    = 12    -- max seconds per shot if part can't reach cursor

-- Satellite mode state
local satFired  = {}            -- part → tick() timestamp when fired; nil = in formation
local satTarget = Vector3.zero  -- world position the beam is aimed at
local SAT_TTL   = 2.0           -- seconds before fired parts snap back to formation
local satTouchConns = {}        -- Touched connections for satellite fling
local anchorBombAnchored = {}   -- parts auto-anchored by AnchorBomb so we can safely undo it

-- Single Part Control
local spcActive  = false
local spcPart    = nil
local spcDepth   = 15
local spcYOff    = 0

-- DroneV2
local dv2Target    = nil
local dv2Label     = nil   -- assigned after UI build

-- Draw mode
local drawTrail      = {}
local drawIndicators = {}  -- neon sphere Parts in workspace
local isDrawing      = false

-- Comet
local cometHistory = {}
local COMET_MAX    = 500

-- Slinky (position history chain)
local slinkyHistory = {}
local SLINKY_MAX    = 400

-- NPC
local npcTarget     = nil
local npcSaved      = {}
local npcConns      = {}
local npcCam        = { yaw=0, pitch=-0.25, dist=12 }

-- NPC Controlling (persistent stat enforcement + teleports)
local npcControlEnabled = false
local npcControlWalkSpeed = 16
local npcControlJumpPower = 50
local npcControlFreezeAutoJump = true
local npcControlHaltMoveTo = true

-- NPC Auras
local killAura      = false
local sitAura       = false
local jumpAura      = false
local followAura    = false
local freezeAura      = false -- fear aura behavior
local killAuraRange   = 25
local sitAuraRange    = 25
local jumpAuraRange   = 25
local followAuraRange = 40
local freezeAuraRange = 25

-- NPC Tools / Auras (new)
local speedAuraEnabled = false
local speedAuraRange    = 30
local speedAuraSpeed    = 30

local spinAuraEnabled = false
local spinAuraRange    = 30
local spinAuraSpeed    = 6 -- radians/sec-ish (we apply via angular velocity)

-- Tool toggles (NPC weapons/tools via mouse raycasts)
local fingerGunEnabled = false
local grabGunEnabled   = false
local sitGunEnabled    = false

-- Grab state (alternates: click to grab/hover, next click to toss)
local grabbedNPC  = nil
local grabbedRoot = nil
local localGrabArmed = false

-- Telekinesis Hold gun (press to grab + float NPC, release to toss)
local tkGunEnabled   = false
local tkHeld         = nil   -- currently held NPC model
local tkHeldRoot     = nil   -- its HumanoidRootPart
local tkSavedPlatform= nil   -- prior PlatformStand to restore on release
local TK_FLOAT_Y     = 6     -- studs above the cursor hit point to hover
local TK_DRAG        = 16    -- follow strength toward the cursor

-- Freeze gun (click to stun/freeze an NPC, click again to release)
local freezeGunEnabled = false
local frozenNPCs       = {}  -- [model] = { ws, jp, jh, ar, ps } saved stats

-- Targeting helpers for tools
local _npcToolsRayParams = RaycastParams.new()
_npcToolsRayParams.FilterType = Enum.RaycastFilterType.Exclude

local GRAB_HOVER_Y_OFFSET = 3 -- hover 3 studs above you
local GRAB_TOSS_POWER     = 720 -- huge-ish velocity impulse for toss
local GRAB_DRAG_POWER     = 180 -- hover/drag strength
local FINGER_GUN_RANGE    = 10000

-- rename in UI/text: freeze aura behaves like fear aura
-- (kept variable name freezeAura to minimize script edits)


-- Part Limits System
local useLimits     = false  -- false/off, true/on with limit
local partLimit     = 10     -- max parts to use when useLimits is true

-- Formation Type Selector
local formationType = "Mouse"  -- "Mouse", "Player", "NPC", "ClickArea"
local clickFormPos  = Vector3.zero

-- Highlight System
local useESP        = false  -- false = SelectionBox, true = ESP UI in CoreGui

-- Ownership Loss Detection
local lastVelWrite  = {}  -- part -> last velocity set for each part

-- ─────────────────────────────────────────────────────────────
-- [2.5]  CONFIG  (executor workspace: atomizer_saves.txt)
-- ─────────────────────────────────────────────────────────────
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

-- Mode list  (40 modes, 4-col grid)
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


-- ─────────────────────────────────────────────────────────────
-- [3]  OWNERSHIP HEARTBEAT  (SimulationRadius + ServerResponse BodyForce)
-- ─────────────────────────────────────────────────────────────
local ownerConn = RunService.Heartbeat:Connect(function()
    -- Massive SimulationRadius to claim ownership at distance
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)
    
    -- BodyForce manipulation: flip ServerResponse.Force every frame to assert ownership
    -- This is the "insane trick" from OWNERSHIP FUCKERY script
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(function()
                -- Assertion #1: velocity write
                part.AssemblyLinearVelocity = Vector3.new(0, 25.11, 0)
                
                -- Assertion #2: ServerResponse BodyForce flip (if it exists)
                local sr = part:FindFirstChild("ServerResponse")
                if sr and sr:IsA("BodyForce") then
                    sr.Force = sr.Force * Vector3.new(0, 0, -1)  -- flip Z every frame
                end
            end)
        end
    end
end)

-- RenderStepped fires before physics AND before Heartbeat each frame,
-- closing the window between steps where ownership can slip.
-- The tiny nudge is immediately overwritten by tickParts on Heartbeat,
-- so it causes zero visible drift — it just asserts ownership twice per frame.
local _renderBump = 1
local renderOwnerConn = RunService.RenderStepped:Connect(function()
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)  -- UPGRADED: match Heartbeat
    _renderBump = -_renderBump
    local bump = Vector3.new(0, 0.008 * _renderBump, 0)
    for _, part in ipairs(selectedParts) do
        if part and part.Parent and not part.Anchored then
            pcall(function()
                -- Velocity write asserts network ownership every render frame
                part.AssemblyLinearVelocity = part.AssemblyLinearVelocity + bump
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SMOOTH CONSTRAINT-BASED MOVEMENT (inspired by OWNERSHIP FUCKERY ownership pokes)
-- Uses AlignPosition/AlignOrientation with rigidity + infinite force for instant, all-parts-per-frame target snaps.
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
        AP.Mode = Enum.PositionAlignmentMode.OneAttachment
        AP.MaxForce = math.huge
        AP.MaxVelocity = math.huge
        AP.Responsiveness = 120
        AP.RigidityEnabled = false
        AP.ApplyAtCenterOfMass = true
        AP.Position = target.position or part.Position
    end

    local AO = getNetAO(part)
    if AO then
        AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        AO.MaxTorque = math.huge
        AO.MaxAngularVelocity = math.huge
        AO.Responsiveness = 80
        AO.RigidityEnabled = true
        AO.CFrame = target.rotation or part.CFrame
    end
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

-- ─────────────────────────────────────────────────────────────
-- [4]  SELECTION  (unanchored parts ONLY — never modifies .Anchored)
-- ─────────────────────────────────────────────────────────────
-- AlignOrientation rotation targets are optional for modes that need facing.
-- Keep disabled by default so position formations stay stable.
local useRotationTargets = false

-- Per-part Touched connections for instant ownership reclaim on contact
local partTouchConns = {}

-- Preserve original collision like OWNERSHIP FUCKERY, then keep selected parts non-collidable.
partCollisionState = {}
local partCollisionConns = {}

-- Fired the moment a selected part makes contact with anything.
-- Re-asserts SimulationRadius + bumps velocity + syncs constraints within the same physics step
-- that triggered the ownership heuristic — before the server confirms the transfer.
local function disableSelectedCollision(part)
    if not fakeCollisions then return end  -- Only disable if toggle is enabled
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
    pcall(sethiddenproperty, LP, "SimulationRadius", math.huge)  -- UPGRADED: use display
    local target = partTargets[part]
    pcall(function()
        part.AssemblyLinearVelocity = Vector3.new(0, 0, 5)  -- tiny nudge to assert ownership
        local AP = getNetAP(part)
        if AP then
            AP.MaxForce = math.huge
            AP.MaxVelocity = math.huge
            AP.Position = (target and target.position) or part.Position
        end
        local AO = getNetAO(part)
        if AO then
            AO.MaxTorque = math.huge
            AO.MaxAngularVelocity = math.huge
            AO.CFrame = (target and target.rotation) or part.CFrame
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

    -- Remove leftover spin/rotation carryover when changing movement families.
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

-- ESP UI tracker (part -> tag table)
local espLabels = {}

local function createEspTag(part)
    local tag = Instance.new("Frame")
    tag.Name = "ESP_" .. part.Name
    tag.Size = UDim2.new(0, 140, 0, 44)
    tag.AnchorPoint = Vector2.new(0.5, 1)
    tag.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    tag.BackgroundTransparency = 0.15
    tag.BorderSizePixel = 0
    tag.Visible = false
    tag.ZIndex = 20
    tag.Parent = EspScreenGui

    Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", tag)
    stroke.Color = ESP_ACCENT
    stroke.Thickness = 1.2
    stroke.Transparency = 0.15

    local bar = Instance.new("Frame", tag)
    bar.Size = UDim2.new(1, 0, 0, 3)
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = ESP_ACCENT
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
    nameLbl.TextColor3 = ESP_ACCENT
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
        local sb = Instance.new("SelectionBox")
        sb.Adornee = part
        sb.Color3 = Color3.fromRGB(200, 200, 215)
        sb.LineThickness = 0.04
        sb.SurfaceColor3 = Color3.fromRGB(170, 170, 195)
        sb.SurfaceTransparency = 0.83
        sb.Parent = workspace
        highlights[part] = sb
    end
end

local function removeHL(part)
    if highlights[part] then
        highlights[part]:Destroy()
        highlights[part] = nil
        espLabels[part] = nil
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
        if not part or not part.Parent or not frame or not frame.Parent then
            espLabels[part] = nil
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
    if isPlayerPart(part) then return end  -- skip ALL player characters
    if isSelected(part) then return end
local r=math.random
    -- Per-part jitter uses explicit XYZ sizing instead of a single scale.
    -- This keeps random micro-spread stable across modes.
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
    -- Touched fires client-side the moment contact happens, letting us
    -- reassert ownership inside the same physics step that triggered the transfer
    partTouchConns[part] = part.Touched:Connect(function()
        reclaimOnTouch(part)
    end)
    
    -- ════════════════════════════════════════════════════════════════
    -- OWNERSHIP FUCKERY WIZARDRY: Align constraint movement + ownership pokes
    -- ════════════════════════════════════════════════════════════════
pcall(function()
        -- Remove legacy movers if an older version left them behind.
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

        -- Match OWNERSHIP FUCKERY structure: part.NetAttach contains NetAP/NetAO.
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

        -- ServerResponse is deferred one render step like the reference script.
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

        -- Ensure movement target exists so newly selected parts never freeze.
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
            local bg = part:FindFirstChild("NetBG")
            if bg then bg:Destroy() end
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

-- ─────────────────────────────────────────────────────────────
-- [5]  DRAW INDICATORS
-- ─────────────────────────────────────────────────────────────
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

-- Cached mouse world position (updated each Heartbeat).
-- ScreenPointToRay + GuiInset-corrected coords; excludes all controlled parts.
local currentMouseHit = Vector3.zero
local _mouseRayParams = RaycastParams.new()
_mouseRayParams.FilterType = Enum.RaycastFilterType.Exclude
local _groundRayParams = RaycastParams.new()
_groundRayParams.FilterType = Enum.RaycastFilterType.Exclude

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

    -- Roblox’s GetMouseLocation() is in the top-left screen space.
    -- Camera:ScreenPointToRay expects coordinates in the same space (UI inset handled by WorldToScreen).
    -- The script previously used the raw pixel, which can feel vertically “low”.
    -- We correct using GuiService inset so the ray matches on-screen cursor.
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

-- ─────────────────────────────────────────────────────────────
-- [6]  MODE TARGET CALCULATORS
-- ─────────────────────────────────────────────────────────────
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
    -- Returns the center point for formation based on formationType
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
    else  -- "Mouse" or default
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
    
    -- Scaling based on form size sliders
    local scX = math.max(0, formSizeX) / 10
    local scZ = math.max(0, formSizeZ) / 10
    local scR = math.max(scX, scZ)  -- Use max for better responsive control
    local scY = math.max(0, formSizeY) / 3

    if attracting then
        return rp+(partOffsets[part] or Vector3.zero)*0.4+Vector3.new(0,2*scY,0)
    end

    -- ── existing modes ─────────────────────────────────────────
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
        -- index 1 = newest trail point, higher index = further back (tail)
        local trailLen = math.min(#cometHistory - 1, math.max(total * 3, 10))
        local histIdx  = math.max(1, #cometHistory - math.floor(ratio * trailLen))
        -- jitter stays fixed size — scR was pulling parts off the trail at high scale
        return cometHistory[histIdx] + (partOffsets[part] or Vector3.zero) * 0.6

    elseif activeMode=="Wall" then
        local root=char and char:FindFirstChild("HumanoidRootPart"); if not root then return mHit end
        local rootCF=root.CFrame

        -- Build a consistent edge-to-edge grid.
        -- Using per-part sizes causes visible gaps when selected parts differ.
        local totalX = 0
        local totalY = 0
        local n = math.max(total, 1)
        for i = 1, total do
            local p = selectedParts[i]
            if p and p.Parent then
                totalX += (p.Size.X or 0)
                totalY += (p.Size.Y or 0)
            end
        end
        local avgX = totalX / n
        local avgY = totalY / n

        -- Grid dims (centered)
        local cols = math.ceil(math.sqrt(total))
        local col  = ((index - 1) % cols) - (cols - 1) / 2
        local rows = math.ceil(total / cols)
        local row  = math.floor((index - 1) / cols) - (rows - 1) / 2

        -- Edge-to-edge spacing in studs.
        -- If parts are drifting with big gaps, it's almost always because the
        -- placement math adds extra separation (scaling + wallGap).
        -- Use *unscaled* average size for the grid, then only apply a small
        -- consistent padding from wallGap.
        local spacingX = avgX + wallGap
        local spacingY = avgY + wallGap

        local distScaleZ = math.max(scX, scZ)
        local ctr = rp + rootCF.LookVector * wallDist * distScaleZ

        return ctr
            + rootCF.RightVector * (col * spacingX)
            + Vector3.new(0, row * spacingY, 0)



    elseif activeMode=="Draw" then
        local trailPos = sampleDrawTrailPoint(index, total)
        if trailPos then
            return trailPos + Vector3.new(0, 1 * scY, 0)
        end
        return mHit + Vector3.new(0, 1 * scY, 0)

    elseif activeMode=="Beam" then
        return (rp+Vector3.new(0,2*scY,0)):Lerp(mHit,ratio)

    -- ── new modes ──────────────────────────────────────────────
    elseif activeMode=="Sphere" then
        -- Even “sphere-ish” distribution with symmetric scaling.
        -- Uses cosY as latitude and sinY as horizontal radius.
        local phi=(1+math.sqrt(5))/2; local i=index-1
        local theta=2*math.pi*i/phi
        local cosY=1-2*(i/math.max(total-1,1))
        local sinY=math.sqrt(math.max(0,1-cosY*cosY))

        -- Restore original sphere radii behavior (uses scX/scY/scZ directly).
        -- The previous normalization caused radius collapse/tightening.
        local rx = formRadius * scX
        local ry = formRadius * scY
        local rz = formRadius * scZ

        -- Reduce vertical exaggeration: keep “sphere” height closer to X/Z.
        -- cosY term is the latitude; scale it down slightly.
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
        -- 3-arm spiral galaxy rotating around cursor
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
        -- Parts spiral inward to a singularity then snap back, looping (not affected by size sliders)
        local cycle  = (t*0.75) % 1
        local pull   = math.max(0, 1 - cycle*2.2)          -- 1→0 in first half
        local r      = formRadius * pull
        local spin   = angle - t*5*(1.2 - pull*0.9)        -- faster at centre
        local h      = pull * 4
        return Vector3.new(mHit.X+math.cos(spin)*r, mHit.Y+h, mHit.Z+math.sin(spin)*r)

    elseif activeMode=="Lemniscate" then
        -- Smooth figure-8 / lemniscate of Bernoulli (ribbon of parts)
        local phase  = ratio * math.pi*2 + t*0.65
        local denom  = 1 + math.sin(phase)^2 + 0.001
        local a      = formRadius * scR * 1.6
        local x      = a * math.cos(phase) / denom * scX
        local z      = a * math.sin(phase)*math.cos(phase) / denom * scZ
        local y      = math.sin(t*1.6 + index*0.45) * 0.55 * scY
        return Vector3.new(mHit.X+x, mHit.Y+2*scY+y, mHit.Z+z)

    elseif activeMode=="Blender" then
        -- Each part orbits in its own unique random plane → chaotic sphere
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
        -- Alternating tall spikes and low ring arcs above player head
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
        -- Organic wandering swarm near cursor with insect-like micro-jitter
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
        -- First quarter of parts form spaced rings above the player.
        -- The rest orbit as a wide halo at the same height.
        -- Parts flagged in satFired fly straight to satTarget.
        local high     = 20 * scY
        local clusterN = math.max(1, math.ceil(total / 4))

        if satFired[part] then
            return satTarget   -- beam part: fly to fire position
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
            -- Halo ring: evenly spaced, slowly rotating
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
        -- Active part flies to cursor. All others stack behind player like a magazine.
        if index == minigunIdx then
            return mHit
        end
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return rp end
        -- Queue position — skip the slot of the currently firing part
        local qp   = index < minigunIdx and index or (index - 1)
        local cols = math.max(math.min(3, total - 1), 1)
        local col  = ((qp - 1) % cols) - math.floor((cols - 1) / 2)
        local row  = math.floor((qp - 1) / cols)
        return rp
            + (-root.CFrame.LookVector) * (5 + row * 2.0)
            + root.CFrame.RightVector   * (col * 1.6)
            + Vector3.new(0, 1.5, 0)

    elseif activeMode=="Seek" then
        -- Each part homes toward nearest NPC in workspace
        local npc = getNearestNPC(part.Position, 200)
        if npc then
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
            if npcRoot then return npcRoot.Position + (partOffsets[part] or Vector3.zero) * 0.5 end
        end
        return mHit + (partOffsets[part] or Vector3.zero)

    elseif activeMode=="AnchorBomb" then
        -- All parts fly to cursor at max speed then anchor themselves
        return mHit + (partOffsets[part] or Vector3.zero) * 0.3

    elseif activeMode=="Slinky" then
        -- Each part trails behind the previous link in recorded mouse history
        local step = math.max(2, math.floor(index * (formRadius * 0.35 + 1.5)))
        local idx  = math.max(1, #slinkyHistory - step)
        local pos  = slinkyHistory[idx] or mHit
        local off = partOffsets[part] or Vector3.zero
        return pos + Vector3.new(off.X*0.35*scX, off.Y*0.35, off.Z*0.35*scZ) + Vector3.new(0, 2 * scY, 0)

    elseif activeMode=="Fountain" then
        -- Parts cycle upward arcs from the cursor like a water jet
        local jet = (t * 2.2 + ratio * 1.8) % 1
        local h   = math.sin(jet * math.pi) * formRadius * 2.8 * scY
        local off = partOffsets[part] or Vector3.zero
        local offScaled = Vector3.new(off.X*formRadius*0.35*scX, 0, off.Z*formRadius*0.35*scZ)
        return mHit + offScaled + Vector3.new(0, h + 1.5 * scY, 0)

    elseif activeMode=="Bounce" then
        -- Ping-pong between cursor and a point above the player
        local phase = (t * 1.4 + index * 0.12) % 2
        local alpha = phase < 1 and phase or (2 - phase)
        local off   = partOffsets[part] or Vector3.zero
        local offScaled = Vector3.new(off.X*0.5*scX, 0, off.Z*0.5*scZ)
        return mHit:Lerp(rp + Vector3.new(0, 7 * scY, 0), alpha) + offScaled

    elseif activeMode=="Ripple" then
        -- Expanding ring waves emanating from the cursor
        local maxR = math.max(scX, scZ)
        local waveR = ((t * 2.4 - index * 0.18) % (formRadius * 2.2 * maxR + 1)) + 1
        local a     = angle + t * 0.25
        return Vector3.new(mHit.X + math.cos(a) * waveR * scX, mHit.Y + 2 * scY, mHit.Z + math.sin(a) * waveR * scZ)

    elseif activeMode=="Juggle" then
        -- Toss parts in parabolic arcs at staggered phases
        local toss = math.sin(t * 2.4 + index * 0.75)
        local h    = (toss + 1) * 0.5 * formRadius * scY * 2.2 + 2 * scY
        local spreadX = formRadius * 0.35 * scX
        local spreadZ = formRadius * 0.35 * scZ
        return Vector3.new(
            mHit.X + math.cos(angle) * spreadX,
            mHit.Y + h,
            mHit.Z + math.sin(angle) * spreadZ)

    elseif activeMode=="Constellation" then
        -- Fixed star pattern that slowly rotates around the formation center
        local a   = angle + t * 0.45
        local r   = formRadius * scR * (0.85 + 0.15 * math.sin(index * 1.9 + t))
        local bob = math.sin(t * 1.8 + index * 0.6) * 0.4 * scY
        return Vector3.new(mHit.X + math.cos(a) * r * scX, mHit.Y + 2.5 * scY + bob, mHit.Z + math.sin(a) * r * scZ)

    -- ── added short modes (pretty + some homing/fling feel) ──────────────
    elseif activeMode=="Rose" then
        -- Parametric rose curve r = a * cos(kθ): crisp petals.
        local k = 3 + ((total % 4) - 1)  -- 2..4 (variety)
        local theta = angle + t * 0.6
        local a = formRadius * scR * (0.75 + 0.25*math.sin(t*1.3 + ratio*6))
        local r = a * math.cos(k * theta)
        -- Lift with a second harmonic for depth
        local y = 2*scY + (math.sin(theta*0.5 + t*1.7 + index*0.12) * 0.8 + ratio*0.3) * (6*scY)
        return Vector3.new(mHit.X + math.cos(theta) * r * scX, mHit.Y + y, mHit.Z + math.sin(theta) * r * scZ)

    elseif activeMode=="OrbitSin" then
        -- Orbit with “breathing” radial sinusoid + gentle vertical sine.
        local a = angle + t*0.9
        local baseR = math.max(0.001, formRadius * scR)
        local r = baseR * (0.75 + 0.25*math.sin(t*2.1 + ratio*6 + index*0.08))
        local y = 2*scY + scY*2.5*math.sin(t*1.4 + ratio*math.pi*2) + (partOffsets[part] and partOffsets[part].Y or 0)*0.6
        return Vector3.new(mHit.X + math.cos(a)*r*scX, mHit.Y + y, mHit.Z + math.sin(a)*r*scZ)

    elseif activeMode=="Liss" then
        -- Clean 3D Lissajous curve using rational multipliers.
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
        -- Pendulum-like swing with rotating plane + small cursor “fling” bump when far.
        local swingA = angle + math.sin(t*1.2)*0.35 + t*0.25
        local swingLen = (formRadius*scR) * (0.7 + 0.3*math.sin(t*2.0 + ratio*5))
        local pos = Vector3.new(
            mHit.X + math.cos(swingA)*swingLen*scX,
            mHit.Y + (2.5*scY + math.sin(t*1.6 + index*0.08)*scY*3),
            mHit.Z + math.sin(swingA)*swingLen*scZ)
        -- fling-ish bias: move outward when far from cursor hit
        local toCursor = currentMouseHit - pos
        local d = toCursor.Magnitude
        if d > 25 then
            local extra = math.clamp((d-25)/60, 0, 2) * (0.18*scR)
            pos = pos + toCursor.Unit * extra
        end
        -- Keep formation target consistent with “under mouse” expectation.
        -- When using Mouse/ClickArea formation, explicitly blend toward cursor.
        if formationType == "Mouse" or formationType == "ClickArea" then
            local blend = math.clamp(d / 80, 0, 1) * 0.35
            pos = pos:Lerp(currentMouseHit + Vector3.new(0, 2*scY, 0), blend)
        end
        return pos
    end

    return mHit
end

-- ─────────────────────────────────────────────────────────────
-- [7]  PART CONTROL LOOP
-- ─────────────────────────────────────────────────────────────
local function tickParts()
    local t     = tick()
    local total = #selectedParts
    local char  = LP.Character
    
    -- Apply part limits
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

    -- Global ownership sweep — throttled to every 3 frames, 2-level scan only
    -- (avoids GetDescendants on a large map every single heartbeat)
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

    -- Single Part Control
    if spcActive and spcPart and spcPart.Parent then
        local tgt = currentMouseHit + Vector3.new(0, spcYOff, 0)
        local diff = tgt - spcPart.Position
        local dist = diff.Magnitude
        local agSPC = Vector3.new(0, workspace.Gravity / 60, 0)
        pcall(function()
            spcPart.AssemblyLinearVelocity = dist > 0.05
                and diff.Unit * (dist * partSpeed * 2) + agSPC  -- No velocity cap
                or  agSPC
            spcPart.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    -- DroneV2 target scan
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

    -- Attract timer
    if attracting then
        attractTimer+=1/60
        if attractTimer>=2 then attracting=false; attractTimer=0 end
    end

    -- Minigun: next shot only after the active part reaches the cursor (or stuck timeout)
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

    -- Satellite: expire beam parts back to formation once they arrive or time out
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

    -- Per-part movement now drives constraint targets directly.
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
            -- Skip part if part limits are active and we've exceeded them
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

                -- Minigun: active firing part launches at high speed
                if isMG and i==minigunIdx then
                    responsiveness = getMoveResponsiveness(4.8)
                end

                -- Satellite beam parts: high-speed travel toward satTarget
                if isSat and satFired[part] then
                    responsiveness = getMoveResponsiveness(55.0)
                end

                -- AnchorBomb: anchor part when it arrives at cursor
                if isAB then
                    if dist < 5 then
                        pcall(function() part.Anchored = true end)
                        anchorBombAnchored[part] = true
                    end
                end

                if isDV2 and dv2Target then
                    pcall(function()
                        part.AssemblyAngularVelocity = Vector3.new(
                            math.sin(t*3+i)*65,math.cos(t*2.5+i*1.3)*65,math.sin(t*3.5+i*0.7)*65)
                        -- Let AlignPosition do the movement; keep the spin effect only.
                        if not partTargets[part] then partTargets[part]={} end
                        partTargets[part].position = tgt
                        partTargets[part].rotation = part.CFrame
                        partTargets[part].responsiveness = getMoveResponsiveness(1.35)
                        syncAlignTarget(part, partTargets[part])
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

-- ─────────────────────────────────────────────────────────────
-- [8]  NPC CONTROL
-- ─────────────────────────────────────────────────────────────
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
    -- Reset control button UI
    if npcCtrlBtn then
        npcCtrlBtn.BackgroundColor3=B_DEF
        npcCtrlBtn.TextColor3=T1
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
    npcCam.dist = 12  -- Reset to default distance on take
    
    -- Apply control settings immediately
    hum.WalkSpeed = npcControlWalkSpeed
    hum.JumpPower = npcControlJumpPower
    hum.AutoRotate = npcControlFreezeAutoJump and false or true

    npcCam.yaw=math.atan2(root.CFrame.LookVector.X,root.CFrame.LookVector.Z)
    npcCam.pitch = -0.25  -- Start looking slightly downward

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

    -- Native-style right-click drag: rotate only while RMB is held. Cursor
    -- stays free; its position is pinned during the drag so MouseMovement.Delta
    -- is reliable, then restored to Default on release.
    local rotating=false
    local rcDown=UserInputService.InputBegan:Connect(function(inp,gpe)
        if not npcTarget then return end
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then
            rotating=true
            -- cursor stays free; rotation reads polled position deltas
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
          if rotating and false then -- handled in camera loop via polled mouse deltas
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
    -- Leave mouse behavior unchanged so shiftlock remains available
    return true
end

-- ─────────────────────────────────────────────────────────────
-- [9]  NPC AURAS
-- ─────────────────────────────────────────────────────────────
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
        return
    end

    -- Run every 8 frames (~7.5/sec) — plenty for auras/tools, avoids per-frame map scan
    _auraFrame = (_auraFrame + 1) % 8
    if _auraFrame ~= 0 then return end

    local char   = LP.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos  = myRoot.Position

    -- Tool targeting helpers
    local function getMouseRayHit(maxDist)
        -- Uses currentMouseHit updated by Heartbeat.
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

        -- Existing NPC Auras
        if killAura  and d <= killAuraRange  then pcall(function() h.Health = 0    end) end
        if sitAura   and d <= sitAuraRange   then pcall(function() h.Sit    = true end) end
        if jumpAura  and d <= jumpAuraRange  then pcall(function() h.Jump   = true end) end
        if followAura and d <= followAuraRange then pcall(function() h:MoveTo(myPos) end) end
        if freezeAura and d <= freezeAuraRange then 
            pcall(function()
                -- Fear-aura behavior:
                -- - Always keep NPCs retreating when inside the aura
                -- - If already at/near the edge, they effectively "freeze" (no further move)
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

        -- Speed Aura
        if speedAuraEnabled and d <= speedAuraRange then
            -- Boost (use max to avoid shrinking from other scripts)
            pcall(function()
                h.WalkSpeed = math.max(h.WalkSpeed, speedAuraSpeed)
            end)
            -- Tiny close-range push toward player so it feels responsive
            if d <= speedAuraRange * 0.35 then
                local dir = (myPos - tr.Position)
                if dir.Magnitude > 0.01 then
                    pcall(function()
                        tr.AssemblyLinearVelocity = tr.AssemblyLinearVelocity + dir.Unit * 10
                    end)
                end
            end
        end

        -- Spin Aura
        if spinAuraEnabled and d <= spinAuraRange then
            -- Yaw spin around world Y toward player.
            local toMe = (myPos - tr.Position)
            if toMe.Magnitude > 0.001 then
                local yaw = math.atan2(toMe.X, toMe.Z)
                -- Keep visual rotation stable: use angular velocity.
                -- Note: Roblox angular velocity is in radians/sec.
                pcall(function()
                    tr.AssemblyAngularVelocity = Vector3.new(0, spinAuraSpeed, 0)
                    -- Encourage facing when close
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

        -- Tools: only affect the currently controlled npcTarget
        if obj == npcTarget then
            local toolHit = nil
            if (fingerGunEnabled or grabGunEnabled or sitGunEnabled) then
                toolHit = getMouseRayHit(FINGER_GUN_RANGE)
            end

            if sitGunEnabled then
                -- sit when in broad tool range
                if d <= speedAuraRange * 10 then
                    pcall(function() h.Sit = true end)
                end
            end

            if fingerGunEnabled and toolHit and toolHit.Position then
                local lookDir = (toolHit.Position - tr.Position)
                if lookDir.Magnitude > 0.2 then
                    pcall(function()
                        tr.AssemblyLinearVelocity = tr.AssemblyLinearVelocity + lookDir.Unit * 25
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
                        end)
                    end
                end
            end
        end
    end

    -- 2-level scan covers direct workspace children + one folder/model deep
    for _, obj in ipairs(workspace:GetChildren()) do
        applyOneNPC(obj)
        if obj:IsA("Model") or obj:IsA("Folder") then
            for _, child in ipairs(obj:GetChildren()) do applyOneNPC(child) end
        end
    end
end

-- ─────────────────────────────────────────────────────────────
-- [10]  UI — PALETTE  (rose / dusty pink)
-- ─────────────────────────────────────────────────────────────
local BG      = Color3.fromRGB(12,  8, 14)
local SURFACE = Color3.fromRGB(22, 14, 26)
local BORDER  = Color3.fromRGB(62, 38, 66)
local TBAR    = Color3.fromRGB(28, 16, 34)
local ACC     = Color3.fromRGB(215, 125, 168)   -- rose pink  (active)
local ACC2    = Color3.fromRGB(148,  92, 128)   -- muted rose (secondary)
local B_DEF   = Color3.fromRGB(36,  22, 42)
local B_RED   = Color3.fromRGB(158,  30, 48)
local B_GRN   = Color3.fromRGB( 22,  90, 46)
local B_YEL   = Color3.fromRGB(115,  80, 18)
local B_BLU   = Color3.fromRGB( 28,  48, 105)
local DV2C    = Color3.fromRGB(205,  62, 18)
local T1      = Color3.fromRGB(242, 212, 228)   -- warm pinkish white
local T2      = Color3.fromRGB(152, 106, 138)   -- muted rose text
local T3      = Color3.fromRGB( 88,  58,  82)   -- dim rose

-- ─────────────────────────────────────────────────────────────
-- [10]  UI HELPERS  (CoreGui / gethui only — stays above in-game UI)
-- ─────────────────────────────────────────────────────────────
local GUI_Z = 64

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "Atomizer"
ScreenGui.ResetOnSpawn     = false
ScreenGui.IgnoreGuiInset   = true
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder     = GUI_DISPLAY_ORDER
ScreenGui.Parent           = getGuiParent()

local function stampGui(obj, z)
    if obj:IsA("GuiObject") then
        obj.ZIndex = math.max(obj.ZIndex, z or GUI_Z)
    end
end

local function reg(c) table.insert(connections,c); return c end
local unloaded = false
local function unloadScript()
    if unloaded then return end
    unloaded = true

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

    tkGunEnabled = false
    freezeGunEnabled = false
    if tkHeld then
        local h = tkHeld:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.PlatformStand = (tkSavedPlatform == true) end) end
    end
    tkHeld = nil; tkHeldRoot = nil; tkSavedPlatform = nil
    for model, s in pairs(frozenNPCs) do
        local h = model and model:FindFirstChildOfClass("Humanoid")
        if h then pcall(function()
            h.WalkSpeed = s.ws; h.JumpPower = s.jp
            pcall(function() h.JumpHeight = s.jh end)
            h.AutoRotate = s.ar; h.PlatformStand = s.ps
        end) end
    end
    frozenNPCs = {}

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

    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    pcall(function() if ownerConn then ownerConn:Disconnect() end end)
    pcall(function() if renderOwnerConn then renderOwnerConn:Disconnect() end end)
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
-- Tab / toggle buttons: no hover lerp (avoids fighting setSTab / refreshModes colors)
function mkTab(props,parent)
    local b=Instance.new("TextButton"); b.AutoButtonColor=false; b.BorderSizePixel=0
    for k,v in pairs(props) do b[k]=v end
    stampGui(b); b.Parent=parent; corner(b,4)
    return b
end
-- Merge two prop tables
local function mg(a,b2) local o={}; for k,v in pairs(a) do o[k]=v end; for k,v in pairs(b2) do o[k]=v end; return o end

-- Thin horizontal divider
function mkDiv(parent,order)
    return mkF({Size=UDim2.new(1,0,0,1),BackgroundColor3=BORDER,LayoutOrder=order},parent)
end
-- Section label
function mkSec(text,parent,order)
    return mkL({Size=UDim2.new(1,0,0,16),Text=text,TextColor3=ACC2,TextSize=9,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order},parent)
end

-- 2-column button row helper
function mkRow2(parent,order,p1,p2)
    local row=mkF({Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=order},parent)
    local b1=mkB(mg(p1,{Size=UDim2.new(0.5,-2,1,0),Position=UDim2.new(0,0,0,0)}),row)
    local b2=mkB(mg(p2,{Size=UDim2.new(0.5,-2,1,0),Position=UDim2.new(0.5,2,0,0)}),row)
    return row,b1,b2
end

-- Slider
function mkSlider(parent,ltext,lo,hi,def,order,onChange)
    local wrap=mkF({Size=UDim2.new(1,0,0,42),BackgroundColor3=SURFACE,LayoutOrder=order},parent)
    corner(wrap,5)
    local lbl=mkL({Size=UDim2.new(1,-8,0,16),Position=UDim2.new(0,8,0,3),
        Text=ltext.."  "..def,TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left},wrap)
    local track=mkF({Size=UDim2.new(1,-16,0,4),Position=UDim2.new(0,8,0,28),
        BackgroundColor3=BORDER},wrap)
    corner(track,3)
    local r0=(def-lo)/(hi-lo)
    local fill=mkF({Size=UDim2.new(r0,0,1,0),BackgroundColor3=ACC},track); corner(fill,3)
    local thumb=mkB({Size=UDim2.new(0,11,0,11),Position=UDim2.new(r0,-5,0.5,-5),
        BackgroundColor3=Color3.fromRGB(195,195,210),Text="",ZIndex=GUI_Z+8},track)
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

-- ─────────────────────────────────────────────────────────────
-- [11]  MAIN FRAME  (built in function — avoids 200 local register cap)
-- ─────────────────────────────────────────────────────────────
local UI
local function buildInterface()
local W,H,MINI=440,560,42

local Main=mkF({Name="Main",Size=UDim2.new(0,W,0,H),
    Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=BG,ZIndex=GUI_Z},ScreenGui)
corner(Main,8)

local shdw=mkF({Size=UDim2.new(1,10,1,10),Position=UDim2.new(0,-5,0,5),
    BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.58,ZIndex=GUI_Z-1},Main)
corner(shdw,11)

-- Title bar
local TBar=mkF({Size=UDim2.new(1,0,0,MINI),BackgroundColor3=TBAR,ZIndex=GUI_Z+1},Main)
corner(TBar,8)
mkF({Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=TBAR,ZIndex=GUI_Z+1},TBar)

mkL({Size=UDim2.new(1,-80,1,0),Position=UDim2.new(0,12,0,0),
    Text="Atomizer",TextColor3=T1,TextSize=13,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=GUI_Z+2},TBar)

local MinBtn=mkB({Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-58,0,9),
    BackgroundColor3=Color3.fromRGB(32,32,42),Text="-",TextColor3=T1,TextSize=13,
    Font=Enum.Font.GothamBold,ZIndex=GUI_Z+2},TBar)
local CloseBtn=mkB({Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,0,9),
    BackgroundColor3=B_RED,Text="X",TextColor3=Color3.new(1,1,1),TextSize=12,
    Font=Enum.Font.GothamBold,ZIndex=GUI_Z+2},TBar)
CloseBtn.MouseButton1Click:Connect(function()
    unloadScript()
end)

-- Drag
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

-- Body
local Body=mkF({Size=UDim2.new(1,0,1,-MINI),Position=UDim2.new(0,0,0,MINI),BackgroundTransparency=1},Main)
local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized; Body.Visible=not minimized
    Main.Size=UDim2.new(0,W,0,minimized and MINI or H); MinBtn.Text=minimized and "+" or "-"
end)

-- Main tab row
local mTabRow=mkF({Size=UDim2.new(1,-12,0,28),Position=UDim2.new(0,6,0,6),BackgroundTransparency=1},Body)
local mTabLL=Instance.new("UIListLayout",mTabRow)
mTabLL.FillDirection=Enum.FillDirection.Horizontal; mTabLL.Padding=UDim.new(0,4)
mTabLL.SortOrder = Enum.SortOrder.LayoutOrder

local mPanels={}; local mTabBtns={}
local function setMTab(name)
    for _,n in ipairs({"Parts","NPC"}) do
        local on=n==name
        mTabBtns[n].BackgroundColor3=on and ACC or B_DEF
        mTabBtns[n].TextColor3=on and Color3.fromRGB(8,8,12) or T2
        if mPanels[n] then mPanels[n].Visible=on end
    end
end
for i,name in ipairs({"Parts","NPC"}) do
    local b=mkTab({Size=UDim2.new(0,102,1,0),BackgroundColor3=B_DEF,Text=name,
        TextColor3=T2,TextSize=12,Font=Enum.Font.GothamBold,LayoutOrder=i},mTabRow)
    mTabBtns[name]=b; b.MouseButton1Click:Connect(function() setMTab(name) end)
end

-- Content area
local Cont=mkF({Size=UDim2.new(1,-12,1,-42),Position=UDim2.new(0,6,0,36),BackgroundTransparency=1},Body)

-- ─────────────────────────────────────────────────────────────
-- [12]  PARTS PANEL  (sub-tabbed)
-- ─────────────────────────────────────────────────────────────
local partsRoot=mkF({Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},Cont)
mPanels["Parts"]=partsRoot

-- Sub-tab row
local sTabRow=mkF({Size=UDim2.new(1,0,0,26),BackgroundColor3=SURFACE},partsRoot)
corner(sTabRow,5)
local sTabLL=Instance.new("UIListLayout",sTabRow)
sTabLL.FillDirection=Enum.FillDirection.Horizontal; sTabLL.Padding=UDim.new(0,2)
Instance.new("UIPadding",sTabRow).PaddingLeft=UDim.new(0,3)

local sPanels={}; local sTabBtns={}
local SUB_TABS={"Sel","Modes","Params","Tools"}
local function setSTab(name)
    for _,n in ipairs(SUB_TABS) do
        local on=n==name
        sTabBtns[n].BackgroundColor3=on and ACC or B_DEF
        sTabBtns[n].BackgroundTransparency=0
        sTabBtns[n].TextColor3=on and Color3.fromRGB(8,8,12) or T2
        if sPanels[n] then sPanels[n].Visible=on end
    end
end
for i,name in ipairs(SUB_TABS) do
    local b=mkTab({Size=UDim2.new(0,98,0,22),BackgroundColor3=B_DEF,
        BackgroundTransparency=0,Text=name,TextColor3=T2,
        TextSize=11,Font=Enum.Font.GothamBold,LayoutOrder=i},sTabRow)
    sTabBtns[name]=b; b.MouseButton1Click:Connect(function() setSTab(name) end)
end

-- Sub-panel container
local spCont=mkF({Size=UDim2.new(1,0,1,-30),Position=UDim2.new(0,0,0,28),BackgroundTransparency=1},partsRoot)

local function makeSubPanel(name)
    local p=mkF({Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},spCont)
    sPanels[name]=p
    return p
end

-- ── SEL sub-panel (scrollable) ─────────────────────────────────
local selSF=Instance.new("ScrollingFrame")
selSF.Size=UDim2.new(1,0,1,0); selSF.BackgroundTransparency=1; selSF.BorderSizePixel=0
selSF.ScrollBarThickness=2; selSF.ScrollBarImageColor3=ACC2; selSF.Visible=false; selSF.Parent=spCont
sPanels["Sel"]=selSF
local selLL=Instance.new("UIListLayout",selSF); selLL.SortOrder=Enum.SortOrder.LayoutOrder; selLL.Padding=UDim.new(0,6)
selLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    selSF.CanvasSize=UDim2.new(0,0,0,selLL.AbsoluteContentSize.Y+8)
end)
local selP=selSF

local selInfo=mkL({Size=UDim2.new(1,0,0,16),Text="#0 selected · Tornado",
    TextColor3=T2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},selP)

local clickSelActive = false
local clickSelBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Click-Select: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=2},selP)
clickSelBtn.MouseButton1Click:Connect(function()
    clickSelActive = not clickSelActive
    clickSelBtn.BackgroundColor3 = clickSelActive and Color3.fromRGB(18,55,24) or B_DEF
    clickSelBtn.TextColor3 = clickSelActive and Color3.fromRGB(110,210,130) or T1
    clickSelBtn.Text = "Click-Select: "..(clickSelActive and "ON ✓" or "OFF")
end)

local _,_,_ = (function()
    local row,b1,b2=mkRow2(selP,3,
        {BackgroundColor3=B_DEF,Text="All",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham},
        {BackgroundColor3=B_DEF,Text="In Range",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham})
    b1.MouseButton1Click:Connect(function() selectAll() end)
    b2.MouseButton1Click:Connect(function() selectInRange(autoSelRange) end)
    return row,b1,b2
end)()

local autoAllBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Auto Select: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},selP)
local autoNearBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Auto Near Select: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=5},selP)

local function refreshAutoSelectButtons()
    autoAllBtn.BackgroundColor3 = autoSelectAll and Color3.fromRGB(18,55,24) or B_DEF
    autoAllBtn.TextColor3 = autoSelectAll and Color3.fromRGB(110,210,130) or T1
    autoAllBtn.Text = "Auto Select: "..(autoSelectAll and "ON ✓" or "OFF")

    autoNearBtn.BackgroundColor3 = autoSelectNear and Color3.fromRGB(22,38,75) or B_DEF
    autoNearBtn.TextColor3 = autoSelectNear and Color3.fromRGB(130,175,255) or T1
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

local clearBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_RED,
    Text="Clear Selection",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},selP)
clearBtn.MouseButton1Click:Connect(function()
    autoSelectAll = false
    autoSelectNear = false
    spcPart = nil
    clearSelection(false)
    refreshAutoSelectButtons()
end)

mkDiv(selP,8)
mkSec("FORMATION", selP, 9)

local freezeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Formation Freeze: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=10},selP)
freezeBtn.MouseButton1Click:Connect(function()
    frozen=not frozen; frozenTargets={}
    freezeBtn.BackgroundColor3=frozen and Color3.fromRGB(22,38,75) or B_DEF
    freezeBtn.TextColor3=frozen and Color3.fromRGB(130,175,255) or T1
    freezeBtn.Text="Formation Freeze: "..(frozen and "ON ✓" or "OFF")
end)

local attractBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Attract to Self (2s)",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=11},selP)
attractBtn.MouseButton1Click:Connect(function() attracting=true; attractTimer=0 end)

mkDiv(selP,12)
mkSec("OWNERSHIP", selP, 13)

local gOwnBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Global Ownership: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=14},selP)
gOwnBtn.MouseButton1Click:Connect(function()
    globalOwnership=not globalOwnership
    gOwnBtn.BackgroundColor3=globalOwnership and Color3.fromRGB(22,38,75) or B_DEF
    gOwnBtn.TextColor3=globalOwnership and Color3.fromRGB(130,175,255) or T1
    gOwnBtn.Text="Global Ownership: "..(globalOwnership and "ON ✓" or "OFF")
end)

mkSlider(selP,"Owner Radius",10,300,ownerRadius,15,function(v) ownerRadius=v end)

local fakeColBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Fake Collisions: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},selP)
fakeColBtn.MouseButton1Click:Connect(function()
    fakeCollisions=not fakeCollisions
    fakeColBtn.BackgroundColor3=fakeCollisions and Color3.fromRGB(22,38,75) or B_DEF
    fakeColBtn.TextColor3=fakeCollisions and Color3.fromRGB(130,175,255) or T1
    fakeColBtn.Text="Fake Collisions: "..(fakeCollisions and "ON ✓" or "OFF")
    -- Re-apply collision state to all selected parts
    for _, part in ipairs(selectedParts) do
        if fakeCollisions then
            pcall(function() disableSelectedCollision(part) end)
        else
            pcall(function() restoreSelectedCollision(part) end)
        end
    end
end)
refreshAutoSelectButtons()

-- ── MODES sub-panel (scrollable) ───────────────────────────────
local modSF=Instance.new("ScrollingFrame")
modSF.Size=UDim2.new(1,0,1,0); modSF.BackgroundTransparency=1; modSF.BorderSizePixel=0
modSF.ScrollBarThickness=3; modSF.ScrollBarImageColor3=ACC2
modSF.ScrollingDirection=Enum.ScrollingDirection.Y
modSF.CanvasSize=UDim2.new(0,0,0,0); modSF.Visible=false; modSF.Parent=spCont
sPanels["Modes"]=modSF
local modLL=Instance.new("UIListLayout",modSF)
modLL.SortOrder=Enum.SortOrder.LayoutOrder; modLL.Padding=UDim.new(0,6)
modLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    modSF.CanvasSize=UDim2.new(0,0,0,modLL.AbsoluteContentSize.Y+8)
end)

-- Mode grid  (4 cols, auto height)
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
    local mb=mkTab({BackgroundColor3=isDV2 and Color3.fromRGB(44,15,6) or B_DEF,
        Text=mn,TextColor3=isDV2 and Color3.fromRGB(230,110,55) or T2,
        TextSize=10,Font=Enum.Font.Gotham},mGrid)
    modeBtns[mn]=mb
end

local function refreshModes()
    for name,mb in pairs(modeBtns) do
        local on=name==activeMode; local isDV2=name=="DroneV2"
        mb.BackgroundColor3=on and (isDV2 and DV2C or ACC) or (isDV2 and Color3.fromRGB(44,15,6) or B_DEF)
        mb.TextColor3=on and Color3.fromRGB(8,8,12) or (isDV2 and Color3.fromRGB(230,110,55) or T2)
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

-- Formation type buttons (2x2 grid)
local formTypeBtns = {}
local function mkFormBtn(props, parent, pos)
    local b = mkTab(mg(props, {Size=UDim2.new(0.5,-2,1,0), Position=pos}), parent)
    return b
end
local formTypeRow1 = mkF({Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, LayoutOrder=4}, modSF)
local ftb1 = mkFormBtn({BackgroundColor3=B_DEF, Text="Mouse", TextColor3=T1, TextSize=11, Font=Enum.Font.Gotham},
    formTypeRow1, UDim2.new(0,0,0,0))
local ftb2 = mkFormBtn({BackgroundColor3=B_DEF, Text="Player", TextColor3=T1, TextSize=11, Font=Enum.Font.Gotham},
    formTypeRow1, UDim2.new(0.5,2,0,0))
local formTypeRow2 = mkF({Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, LayoutOrder=5}, modSF)
local ftb3 = mkFormBtn({BackgroundColor3=B_DEF, Text="Closest NPC", TextColor3=T1, TextSize=11, Font=Enum.Font.Gotham},
    formTypeRow2, UDim2.new(0,0,0,0))
local ftb4 = mkFormBtn({BackgroundColor3=B_DEF, Text="Click Area", TextColor3=T1, TextSize=11, Font=Enum.Font.Gotham},
    formTypeRow2, UDim2.new(0.5,2,0,0))

formTypeBtns["Mouse"] = ftb1
formTypeBtns["Player"] = ftb2
formTypeBtns["ClosestNPC"] = ftb3
formTypeBtns["ClickArea"] = ftb4

local function refreshFormationType()
    for ftype, btn in pairs(formTypeBtns) do
        local on = (ftype == formationType) or (ftype == "Mouse" and formationType == "Mouse")
        btn.BackgroundColor3 = on and ACC or B_DEF
        btn.TextColor3 = on and Color3.fromRGB(8,8,12) or T1
    end
end
refreshFormationType()

ftb1.MouseButton1Click:Connect(function() formationType="Mouse"; refreshFormationType() end)
ftb2.MouseButton1Click:Connect(function() formationType="Player"; refreshFormationType() end)
ftb3.MouseButton1Click:Connect(function() formationType="ClosestNPC"; refreshFormationType() end)
ftb4.MouseButton1Click:Connect(function() formationType="ClickArea"; refreshFormationType() end)

mkSec("SCALE & DRAW", modSF, 6)

-- Formation-axis sizing (primary control for all modes except Mouse/Blackhole)
mkSlider(modSF,"Form Size X",0,100,formSizeX,7,function(v) formSizeX=v end)
mkSlider(modSF,"Form Size Y",0,100,formSizeY,8,function(v) formSizeY=v end)
mkSlider(modSF,"Form Size Z",0,100,formSizeZ,9,function(v) formSizeZ=v end)

-- Offset/height bias used by all modes
mkSlider(modSF,"Form Offset Y",-20,20,formOffsetY,10,function(v) formOffsetY=v end)

mkL({Size=UDim2.new(1,0,0,14),
    Text="Hold Mouse1 while in Draw mode to trace a path",
    TextColor3=T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=8},modSF)
local clearDrawBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Clear Draw Trail",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=9},modSF)
clearDrawBtn.MouseButton1Click:Connect(function() clearDrawDots() end)
task.defer(function()
    if modLL.AbsoluteContentSize.Y > 0 then
        modSF.CanvasSize=UDim2.new(0,0,0,modLL.AbsoluteContentSize.Y+8)
    end
end)

-- ── PARAMS sub-panel (scrollable) ─────────────────────────────
local parSF=Instance.new("ScrollingFrame")
parSF.Size=UDim2.new(1,0,1,0); parSF.BackgroundTransparency=1; parSF.BorderSizePixel=0
parSF.ScrollBarThickness=2; parSF.ScrollBarImageColor3=ACC2; parSF.Visible=false; parSF.Parent=spCont
sPanels["Params"]=parSF
local parLL=Instance.new("UIListLayout",parSF); parLL.SortOrder=Enum.SortOrder.LayoutOrder; parLL.Padding=UDim.new(0,6)
parLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    parSF.CanvasSize=UDim2.new(0,0,0,parLL.AbsoluteContentSize.Y+6)
end)

mkSec("VELOCITY", parSF, 1)
mkSlider(parSF,"Part Speed",   1,120,partSpeed,   2,function(v) partSpeed=v end)
-- Max Velocity removed: now unlimited (math.huge) for smooth constraint-based movement
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
dv2Label=mkL({Size=UDim2.new(1,0,0,14),Text="Inactive",TextColor3=DV2C,
    TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=15},parSF)
mkSlider(parSF,"Fling Force",50,2000,flingForce,16,function(v) flingForce=v end)
mkSlider(parSF,"Fling Range", 5,  80,flingRange,17,function(v) flingRange=v end)

-- ── TOOLS sub-panel ────────────────────────────────────────────
local toolP=makeSubPanel("Tools")
local toolLL=Instance.new("UIListLayout",toolP); toolLL.SortOrder=Enum.SortOrder.LayoutOrder; toolLL.Padding=UDim.new(0,6)

mkSec("SINGLE PART CONTROL", toolP, 1)
mkL({Size=UDim2.new(1,0,0,14),Text="Enable → click any unanchored part → follows camera ray",
    TextColor3=T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=2},toolP)

local spcBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Single Part Control: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=3},toolP)
local spcRelBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_RED,
    Text="Release Grabbed Part",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},toolP)
mkSlider(toolP,"SPC Depth",3,60,spcDepth,5,function(v) spcDepth=v end)

spcBtn.MouseButton1Click:Connect(function()
    spcActive=not spcActive
    if not spcActive then spcPart=nil end
    spcBtn.BackgroundColor3=spcActive and Color3.fromRGB(18,40,24) or B_DEF
    spcBtn.TextColor3=spcActive and Color3.fromRGB(110,210,130) or T1
    spcBtn.Text="Single Part Control: "..(spcActive and "ON ✓" or "OFF")
end)
spcRelBtn.MouseButton1Click:Connect(function()
    if spcPart then pcall(function() spcPart.AssemblyLinearVelocity=Vector3.zero end) end
    spcPart=nil
end)
reg(UserInputService.InputChanged:Connect(function(inp)
    if not spcActive then return end
    if inp.UserInputType==Enum.UserInputType.MouseWheel then
        spcYOff=spcYOff+inp.Position.Z*1.5
    end
end))

mkDiv(toolP,6)
mkSec("PART LIMITS", toolP, 7)

local limitsBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Limits: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},toolP)
limitsBtn.MouseButton1Click:Connect(function()
    useLimits=not useLimits
    limitsBtn.BackgroundColor3=useLimits and Color3.fromRGB(44,28,8) or B_DEF
    limitsBtn.TextColor3=useLimits and Color3.fromRGB(255,180,80) or T1
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
        {BackgroundColor3=B_GRN,Text=" Anchor",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham},
        {BackgroundColor3=B_BLU,Text=" Unanchor",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
    a1.MouseButton1Click:Connect(function()
        for _,p in ipairs(selectedParts) do pcall(function() p.Anchored=true end) end end)
    a2.MouseButton1Click:Connect(function()
        for _,p in ipairs(selectedParts) do pcall(function() p.Anchored=false end) end end)
end
local delBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_RED,
    Text="Delete Selected",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=12},toolP)
delBtn.MouseButton1Click:Connect(function()
    clearSelection(true)
end)

mkDiv(toolP,13)
mkSec("DISPLAY", toolP, 14)

local espBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Highlight: SelectionBox",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=15},toolP)
espBtn.MouseButton1Click:Connect(function()
    useESP=not useESP
    espBtn.BackgroundColor3=useESP and Color3.fromRGB(16,32,56) or B_DEF
    espBtn.TextColor3=useESP and Color3.fromRGB(100,150,255) or T1
    espBtn.Text="Highlight: "..(useESP and "ESP UI" or "SelectionBox")
    -- Rebuild highlights for all selected parts
    for _,part in ipairs(selectedParts) do
        removeHL(part)
        addHL(part)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- [13]  NPC PANEL
-- ─────────────────────────────────────────────────────────────
local npcRoot=mkF({Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},Cont)
mPanels["NPC"]=npcRoot

-- Sub-tab row
local npcSTabRow = mkF({Size=UDim2.new(1,0,0,26),BackgroundColor3=SURFACE},npcRoot)
corner(npcSTabRow,5)
local npcSTabLL = Instance.new("UIListLayout",npcSTabRow)
npcSTabLL.FillDirection=Enum.FillDirection.Horizontal; npcSTabLL.Padding=UDim.new(0,2)
Instance.new("UIPadding",npcSTabRow).PaddingLeft=UDim.new(0,3)

local npcSTabs = {"Control","Auras","Guns"}
local npcSBtns = {}
local npcSPanels = {}

-- Sub-panel container (takes remaining space below tabs)
local npcSpCont=mkF({Size=UDim2.new(1,0,1,-26),Position=UDim2.new(0,0,0,26),BackgroundTransparency=1},npcRoot)

-- Control panel (scrollable for consistency)
local npcControlPanel=Instance.new("ScrollingFrame")
npcControlPanel.Size=UDim2.new(1,0,1,0); npcControlPanel.BackgroundTransparency=1
npcControlPanel.BorderSizePixel=0; npcControlPanel.ScrollBarThickness=2
npcControlPanel.ScrollBarImageColor3=ACC2; npcControlPanel.Visible=false
npcControlPanel.Parent=npcSpCont
npcSPanels["Control"]=npcControlPanel
local npcControlLL = Instance.new("UIListLayout", npcControlPanel)
npcControlLL.SortOrder = Enum.SortOrder.LayoutOrder
npcControlLL.Padding = UDim.new(0, 6)
npcControlLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    npcControlPanel.CanvasSize=UDim2.new(0,0,0,npcControlLL.AbsoluteContentSize.Y+8)
end)

-- ── NPC SEARCH BOX (pins to top of Control panel via negative LayoutOrder) ──
local npcSearchBox = Instance.new("TextBox")
npcSearchBox.Size = UDim2.new(1,0,0,24)
npcSearchBox.BackgroundColor3 = B_DEF
npcSearchBox.BorderSizePixel = 0
npcSearchBox.Text = ""
npcSearchBox.PlaceholderText = "🔍 Search NPCs..."
npcSearchBox.PlaceholderColor3 = T3
npcSearchBox.TextColor3 = T1
npcSearchBox.TextSize = 11
npcSearchBox.Font = Enum.Font.Gotham
npcSearchBox.ClearTextOnFocus = false
npcSearchBox.TextXAlignment = Enum.TextXAlignment.Left
npcSearchBox.LayoutOrder = -2
stampGui(npcSearchBox); corner(npcSearchBox,4)
Instance.new("UIPadding", npcSearchBox).PaddingLeft = UDim.new(0,6)
npcSearchBox.Parent = npcControlPanel

local npcSearchResults = Instance.new("ScrollingFrame")
npcSearchResults.Size = UDim2.new(1,0,0,0)
npcSearchResults.BackgroundColor3 = SURFACE
npcSearchResults.BorderSizePixel = 0
npcSearchResults.ScrollBarThickness = 3
npcSearchResults.ScrollBarImageColor3 = ACC2
npcSearchResults.CanvasSize = UDim2.new(0,0,0,0)
npcSearchResults.Visible = false
npcSearchResults.LayoutOrder = -1
stampGui(npcSearchResults); corner(npcSearchResults,4)
npcSearchResults.Parent = npcControlPanel
local npcSearchLL = Instance.new("UIListLayout", npcSearchResults)
npcSearchLL.SortOrder = Enum.SortOrder.LayoutOrder
npcSearchLL.Padding = UDim.new(0,2)

local _searchBtns = {}
local function _clearSearchResults()
    for _,b in ipairs(_searchBtns) do pcall(function() b:Destroy() end) end
    _searchBtns = {}
end
local function _collectNPCs()
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
local function _runNPCSearch(q)
    _clearSearchResults()
    q = string.lower(q or "")
    if q == "" then
        npcSearchResults.Visible = false
        npcSearchResults.Size = UDim2.new(1,0,0,0)
        return
    end
    local matched = {}
    for _,m in ipairs(_collectNPCs()) do
        if string.find(string.lower(m.Name), q, 1, true) then matched[#matched+1] = m end
    end
    table.sort(matched, function(a,b) return string.lower(a.Name) < string.lower(b.Name) end)
    local shown = 0
    for _,m in ipairs(matched) do
        shown += 1
        if shown > 40 then break end
        local rb = mkB({Size=UDim2.new(1,0,0,20),BackgroundColor3=B_DEF,
            Text="  "..m.Name,TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=shown}, npcSearchResults)
        rb.MouseButton1Click:Connect(function()
            pcall(function() takeNPC(m) end)
            npcSearchBox.Text = ""
            _runNPCSearch("")
        end)
        _searchBtns[#_searchBtns+1] = rb
    end
    npcSearchResults.Visible = (shown > 0)
    npcSearchResults.Size = UDim2.new(1,0,0, math.min(shown,6)*22 + 2)
    npcSearchResults.CanvasSize = UDim2.new(0,0,0, shown*22 + 2)
end
npcSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    _runNPCSearch(npcSearchBox.Text)
end)

-- Auras panel (scrollable for overflow)
local npcAurasPanel=Instance.new("ScrollingFrame")
npcAurasPanel.Size=UDim2.new(1,0,1,0); npcAurasPanel.BackgroundTransparency=1
npcAurasPanel.BorderSizePixel=0; npcAurasPanel.ScrollBarThickness=2
npcAurasPanel.ScrollBarImageColor3=ACC2; npcAurasPanel.Visible=false
npcAurasPanel.Parent=npcSpCont
npcSPanels["Auras"]=npcAurasPanel
local npcAurasLL = Instance.new("UIListLayout", npcAurasPanel)
npcAurasLL.SortOrder = Enum.SortOrder.LayoutOrder
npcAurasLL.Padding = UDim.new(0, 6)
npcAurasLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    npcAurasPanel.CanvasSize=UDim2.new(0,0,0,npcAurasLL.AbsoluteContentSize.Y+8)
end)

-- Tools panel (scrollable for overflow)
local npcToolsPanel=Instance.new("ScrollingFrame")
npcToolsPanel.Size=UDim2.new(1,0,1,0); npcToolsPanel.BackgroundTransparency=1
npcToolsPanel.BorderSizePixel=0; npcToolsPanel.ScrollBarThickness=2
npcToolsPanel.ScrollBarImageColor3=ACC2; npcToolsPanel.Visible=false
npcToolsPanel.Parent=npcSpCont
npcSPanels["Guns"]=npcToolsPanel
local npcToolsLL = Instance.new("UIListLayout", npcToolsPanel)
npcToolsLL.SortOrder = Enum.SortOrder.LayoutOrder
npcToolsLL.Padding = UDim.new(0, 6)
npcToolsLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    npcToolsPanel.CanvasSize=UDim2.new(0,0,0,npcToolsLL.AbsoluteContentSize.Y+8)
end)

local npcStat -- declared at top for UI table
-- CONTROL PANEL (NPC possession) - LayoutOrder 1-18
npcStat = mkL({Size=UDim2.new(1,0,0,16),Text="No NPC selected",
    TextColor3=T2,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},npcControlPanel)

do
    local _,pb,rb=mkRow2(npcControlPanel,2,
        {BackgroundColor3=B_DEF,Text=" Pick NPC",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham},
        {BackgroundColor3=B_RED,Text=" Release [Tab]",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
    local npcPickActive=false
    local function setNPCPick(on)
        npcPickActive=on
        pb.BackgroundColor3=on and Color3.fromRGB(18,55,24) or B_DEF
        pb.TextColor3=on and Color3.fromRGB(110,210,130) or T1
        pb.Text=on and " Pick NPC: ON ✓" or " Pick NPC"
        _G._npcPickActive=on
    end
    pb.MouseButton1Click:Connect(function() setNPCPick(not npcPickActive) end)
    rb.MouseButton1Click:Connect(function() 
        releaseNPC()
        npcStat.Text="Released"
        setNPCPick(false)
    end)
    _G._setNPCPick=setNPCPick
    _G._getNPCPickActive=function() return npcPickActive end
end

mkL({Size=UDim2.new(1,0,0,28),
    Text="WASD → Move  ·  Space → Jump  ·  Tab → Release\nMouse → Camera  ·  Scroll → Zoom",
    TextColor3=T3,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
    TextWrapped=true,LayoutOrder=3},npcControlPanel)

mkDiv(npcControlPanel,4)
mkSec("MOVEMENT", npcControlPanel, 5)
do
    local _,wb,jb=mkRow2(npcControlPanel,6,
        {BackgroundColor3=B_DEF,Text=" Walk to Mouse",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham},
        {BackgroundColor3=B_DEF,Text=" Jump",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham})
    local _,sb,wmb=mkRow2(npcControlPanel,7,
        {BackgroundColor3=B_DEF,Text=" Sit Toggle",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham},
        {BackgroundColor3=B_BLU,Text=" Warp→Mouse",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
    local wmeBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_BLU,
        Text="  Warp NPC to Me",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=8},npcControlPanel)
    wb.MouseButton1Click:Connect(function()
        if not npcTarget then return end
        updateMouseHit()
        local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h:MoveTo(currentMouseHit) end end)
    jb.MouseButton1Click:Connect(function()
        if not npcTarget then return end
        local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.Jump=true end end)
    sb.MouseButton1Click:Connect(function()
        if not npcTarget then return end
        local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.Sit=not h.Sit end end)
    wmb.MouseButton1Click:Connect(function()
        if not npcTarget then return end
        updateMouseHit()
        local r=npcTarget:FindFirstChild("HumanoidRootPart")
        if r then pcall(function() r.CFrame=CFrame.new(currentMouseHit+Vector3.new(0,3,0)) end) end end)
    wmeBtn.MouseButton1Click:Connect(function()
        if not npcTarget then return end
        local c=LP.Character; local mr=c and c:FindFirstChild("HumanoidRootPart")
        local nr=npcTarget:FindFirstChild("HumanoidRootPart")
        if mr and nr then pcall(function() nr.CFrame=mr.CFrame*CFrame.new(3,0,0) end) end end)
end

mkDiv(npcControlPanel,9)
mkSec("STATS", npcControlPanel, 10)
mkSlider(npcControlPanel,"Walk Speed",1,100,16,11,function(v)
    if npcTarget then local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=v end end end)
mkSlider(npcControlPanel,"Jump Power",0,200,50,12,function(v)
    if npcTarget then local h=npcTarget:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=v end end end)

mkDiv(npcControlPanel,13)
mkSec("LIFECYCLE", npcControlPanel, 14)
do
    local _,hb,kb=mkRow2(npcControlPanel,16,
        {BackgroundColor3=B_GRN,Text=" Heal",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham},
        {BackgroundColor3=B_RED,Text=" Kill",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
    local _,rsb,db=mkRow2(npcControlPanel,17,
        {BackgroundColor3=B_YEL,Text=" Reset",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham},
        {BackgroundColor3=B_RED,Text=" Delete",TextColor3=Color3.new(1,1,1),TextSize=11,Font=Enum.Font.Gotham})
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

-- NPC Control toggle
npcCtrlBtn = mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="NPC Control: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=18},npcControlPanel)
npcCtrlBtn.MouseButton1Click:Connect(function()
    npcControlEnabled = not npcControlEnabled
    npcCtrlBtn.BackgroundColor3 = npcControlEnabled and Color3.fromRGB(18,55,24) or B_DEF
    npcCtrlBtn.TextColor3 = npcControlEnabled and Color3.fromRGB(110,210,130) or T1
    npcCtrlBtn.Text = "NPC Control: "..(npcControlEnabled and "ON ✓" or "OFF")
    if npcControlEnabled and npcTarget then
        local h = npcTarget:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed = npcControlWalkSpeed
            h.JumpPower = npcControlJumpPower
            h.AutoRotate = not npcControlFreezeAutoJump
        end
    end
end)

mkSlider(npcControlPanel,"Ctrl WalkSpd",1,100,npcControlWalkSpeed,19,function(v)
    npcControlWalkSpeed = v
    if npcControlEnabled and npcTarget then
        local h = npcTarget:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
end)
mkSlider(npcControlPanel,"Ctrl JumpPwr",0,200,npcControlJumpPower,20,function(v)
    npcControlJumpPower = v
    if npcControlEnabled and npcTarget then
        local h = npcTarget:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = v end
    end
end)

mkDiv(npcControlPanel,21)

local npcFreezeAJBtn = mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Freeze AutoJump: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=22},npcControlPanel)
npcFreezeAJBtn.MouseButton1Click:Connect(function()
    npcControlFreezeAutoJump = not npcControlFreezeAutoJump
    npcFreezeAJBtn.BackgroundColor3 = npcControlFreezeAutoJump and Color3.fromRGB(18,55,24) or B_DEF
    npcFreezeAJBtn.TextColor3 = npcControlFreezeAutoJump and Color3.fromRGB(110,210,130) or T1
    npcFreezeAJBtn.Text = "Freeze AutoJump: "..(npcControlFreezeAutoJump and "ON ✓" or "OFF")
end)

local npcHaltMBtn = mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Halt MoveTo: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=23},npcControlPanel)
npcHaltMBtn.MouseButton1Click:Connect(function()
    npcControlHaltMoveTo = not npcControlHaltMoveTo
    npcHaltMBtn.BackgroundColor3 = npcControlHaltMoveTo and Color3.fromRGB(18,55,24) or B_DEF
    npcHaltMBtn.TextColor3 = npcControlHaltMoveTo and Color3.fromRGB(110,210,130) or T1
    npcHaltMBtn.Text = "Halt MoveTo: "..(npcControlHaltMoveTo and "ON ✓" or "OFF")
end)

-- AURAS PANEL - LayoutOrder 1+ (starts fresh in its own panel)
local killAuraBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Kill Aura: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=1},npcAurasPanel)
killAuraBtn.MouseButton1Click:Connect(function()
    killAura=not killAura
    killAuraBtn.BackgroundColor3 = killAura and Color3.fromRGB(95,12,12) or B_DEF
    killAuraBtn.TextColor3       = killAura and Color3.fromRGB(255,90,90) or T1
    killAuraBtn.Text = "Kill Aura: "..(killAura and "ON ✓" or "OFF")
end)
mkSlider(npcAurasPanel,"Kill Range",3,300,killAuraRange,2,function(v) killAuraRange=v end)

local sitAuraBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Sit Aura: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},npcAurasPanel)
sitAuraBtn.MouseButton1Click:Connect(function()
    sitAura=not sitAura
    sitAuraBtn.BackgroundColor3 = sitAura and Color3.fromRGB(14,32,88) or B_DEF
    sitAuraBtn.TextColor3       = sitAura and Color3.fromRGB(100,148,255) or T1
    sitAuraBtn.Text = "Sit Aura: "..(sitAura and "ON ✓" or "OFF")
end)
mkSlider(npcAurasPanel,"Sit Range",3,300,sitAuraRange,5,function(v) sitAuraRange=v end)

local jumpAuraBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Jump Aura: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=7},npcAurasPanel)
jumpAuraBtn.MouseButton1Click:Connect(function()
    jumpAura=not jumpAura
    jumpAuraBtn.BackgroundColor3 = jumpAura and Color3.fromRGB(12,52,22) or B_DEF
    jumpAuraBtn.TextColor3       = jumpAura and Color3.fromRGB(90,215,115) or T1
    jumpAuraBtn.Text = "Jump Aura: "..(jumpAura and "ON ✓" or "OFF")
end)
mkSlider(npcAurasPanel,"Jump Range",3,300,jumpAuraRange,8,function(v) jumpAuraRange=v end)

local followAuraBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Follow Aura: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=10},npcAurasPanel)
followAuraBtn.MouseButton1Click:Connect(function()
    followAura=not followAura
    followAuraBtn.BackgroundColor3 = followAura and Color3.fromRGB(65,20,90) or B_DEF
    followAuraBtn.TextColor3       = followAura and Color3.fromRGB(200,120,255) or T1
    followAuraBtn.Text = "Follow Aura: "..(followAura and "ON ✓" or "OFF")
end)
mkSlider(npcAurasPanel,"Follow Range",3,300,followAuraRange,11,function(v) followAuraRange=v end)

local freezeAuraBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Fear Aura: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=14},npcAurasPanel)
freezeAuraBtn.MouseButton1Click:Connect(function()
    freezeAura=not freezeAura
    freezeAuraBtn.BackgroundColor3 = freezeAura and Color3.fromRGB(32,32,95) or B_DEF
    freezeAuraBtn.TextColor3       = freezeAura and Color3.fromRGB(140,140,255) or T1
    freezeAuraBtn.Text = "Fear Aura: "..(freezeAura and "ON ✓" or "OFF")
end)
mkSlider(npcAurasPanel,"Fear Range",3,1000,freezeAuraRange,14,function(v) freezeAuraRange=v end)

local speedAuraBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Speed Aura: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=16},npcAurasPanel)
speedAuraBtn.MouseButton1Click:Connect(function()
    speedAuraEnabled = not speedAuraEnabled
    speedAuraBtn.BackgroundColor3 = speedAuraEnabled and Color3.fromRGB(26,80,30) or B_DEF
    speedAuraBtn.TextColor3       = speedAuraEnabled and Color3.fromRGB(120,255,150) or T1
    speedAuraBtn.Text = "Speed Aura: "..(speedAuraEnabled and "ON ✓" or "OFF")
end)
mkSlider(npcAurasPanel,"Speed Range",3,300,speedAuraRange,17,function(v) speedAuraRange=v end)
mkSlider(npcAurasPanel,"Speed Amount",1,200,speedAuraSpeed,18,function(v) speedAuraSpeed=v end)

local spinAuraBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Spin Aura: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=20},npcAurasPanel)
spinAuraBtn.MouseButton1Click:Connect(function()
    spinAuraEnabled = not spinAuraEnabled
    spinAuraBtn.BackgroundColor3 = spinAuraEnabled and Color3.fromRGB(70,30,90) or B_DEF
    spinAuraBtn.TextColor3       = spinAuraEnabled and Color3.fromRGB(210,145,255) or T1
    spinAuraBtn.Text = "Spin Aura: "..(spinAuraEnabled and "ON ✓" or "OFF")
end)
mkSlider(npcAurasPanel,"Spin Range",3,300,spinAuraRange,21,function(v) spinAuraRange=v end)
mkSlider(npcAurasPanel,"Spin Speed",1,40,spinAuraSpeed,22,function(v) spinAuraSpeed=v end)

-- ─────────────────────────────────────────────
-- TOOLS PANEL
-- ─────────────────────────────────────────────

local fingerGunBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Finger Gun: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=1},npcToolsPanel)
fingerGunBtn.MouseButton1Click:Connect(function()
    fingerGunEnabled = not fingerGunEnabled
    fingerGunBtn.BackgroundColor3 = fingerGunEnabled and Color3.fromRGB(60,60,140) or B_DEF
    fingerGunBtn.TextColor3       = fingerGunEnabled and Color3.fromRGB(170,190,255) or T1
    fingerGunBtn.Text = "Finger Gun: "..(fingerGunEnabled and "ON ✓" or "OFF")
end)

local grabGunBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Grab Gun: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=2},npcToolsPanel)
grabGunBtn.MouseButton1Click:Connect(function()
    grabGunEnabled = not grabGunEnabled
    grabGunBtn.BackgroundColor3 = grabGunEnabled and Color3.fromRGB(110,70,20) or B_DEF
    grabGunBtn.TextColor3       = grabGunEnabled and Color3.fromRGB(255,210,120) or T1
    grabGunBtn.Text = "Grab Gun: "..(grabGunEnabled and "ON ✓" or "OFF")
end)

local sitGunBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Sit Gun: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=3},npcToolsPanel)
sitGunBtn.MouseButton1Click:Connect(function()
    sitGunEnabled = not sitGunEnabled
    sitGunBtn.BackgroundColor3 = sitGunEnabled and Color3.fromRGB(20,90,110) or B_DEF
    sitGunBtn.TextColor3       = sitGunEnabled and Color3.fromRGB(120,240,255) or T1
    sitGunBtn.Text = "Sit Gun: "..(sitGunEnabled and "ON ✓" or "OFF")
end)

local tkGunBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Telekinesis Gun: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=4},npcToolsPanel)
local freezeGunBtn=mkB({Size=UDim2.new(1,0,0,28),BackgroundColor3=B_DEF,
    Text="Freeze Gun: OFF",TextColor3=T1,TextSize=11,Font=Enum.Font.Gotham,LayoutOrder=5},npcToolsPanel)

local function refreshTKFreezeBtns()
    tkGunBtn.BackgroundColor3 = tkGunEnabled and Color3.fromRGB(90,40,120) or B_DEF
    tkGunBtn.TextColor3       = tkGunEnabled and Color3.fromRGB(220,170,255) or T1
    tkGunBtn.Text = "Telekinesis Gun: "..(tkGunEnabled and "ON ✓" or "OFF")
    freezeGunBtn.BackgroundColor3 = freezeGunEnabled and Color3.fromRGB(20,70,120) or B_DEF
    freezeGunBtn.TextColor3       = freezeGunEnabled and Color3.fromRGB(150,210,255) or T1
    freezeGunBtn.Text = "Freeze Gun: "..(freezeGunEnabled and "ON ✓" or "OFF")
end

tkGunBtn.MouseButton1Click:Connect(function()
    tkGunEnabled = not tkGunEnabled
    if tkGunEnabled then freezeGunEnabled = false end   -- both use LMB; keep one active
    refreshTKFreezeBtns()
end)
freezeGunBtn.MouseButton1Click:Connect(function()
    freezeGunEnabled = not freezeGunEnabled
    if freezeGunEnabled then tkGunEnabled = false end
    refreshTKFreezeBtns()
end)

local npcActiveSTab = "Control"
local function setNpcSTab(name)
    npcActiveSTab = name
    for _,t in ipairs(npcSTabs) do
        npcSBtns[t].BackgroundColor3 = (t==name) and ACC or B_DEF
        npcSBtns[t].TextColor3 = (t==name) and Color3.fromRGB(8,8,12) or T2
        npcSPanels[t].Visible = (t==name)
    end
end

for i,tname in ipairs(npcSTabs) do
    local b = mkTab({Size=UDim2.new(0,98,0,22),BackgroundColor3=B_DEF,BackgroundTransparency=0,
        Text=tname,TextColor3=T2,TextSize=11,Font=Enum.Font.GothamBold,LayoutOrder=i},npcSTabRow)
    npcSBtns[tname]=b
    b.MouseButton1Click:Connect(function() setNpcSTab(tname) end)
end

setNpcSTab("Control")

setMTab("Parts"); setSTab("Sel")

return {
    ScreenGui=ScreenGui, selInfo=selInfo, clickSelBtn=clickSelBtn,
    clearBtn=clearBtn, freezeBtn=freezeBtn, spcBtn=spcBtn, npcStat=npcStat,
    getClickSelActive=function() return clickSelActive end,
}
end
UI = buildInterface()

-- Write initial config to executor workspace (atomizer_saves.txt)
if hasFileSystem then saveConfig(true) end

-- ─────────────────────────────────────────────────────────────
-- [15]  CLICK HANDLER  (select parts / SPC / pick NPC)
-- ─────────────────────────────────────────────────────────────
-- Telekinesis: release LMB to toss the held NPC toward the cursor
reg(Mouse.Button1Up:Connect(function()
    if not tkHeld then return end
    local model, root = tkHeld, tkHeldRoot
    tkHeld = nil; tkHeldRoot = nil
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
        if h then pcall(function() h.PlatformStand = (tkSavedPlatform == true) end) end
    end
    tkSavedPlatform = nil
end))

-- Per-frame enforcement: float a telekinesis-held NPC, and keep frozen NPCs pinned
reg(RunService.Heartbeat:Connect(function()
    -- Telekinesis float toward the cursor hit point
    if tkHeld then
        local root = tkHeldRoot
        if not root or not root.Parent then
            tkHeld = nil; tkHeldRoot = nil
        else
            local target = currentMouseHit + Vector3.new(0, TK_FLOAT_Y, 0)
            pcall(function()
                root.AssemblyLinearVelocity = (target - root.Position) * TK_DRAG
                root.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
    -- Keep every frozen NPC at zero velocity, stunned, walk/jump disabled
    for model, _ in pairs(frozenNPCs) do
        if not model.Parent then
            frozenNPCs[model] = nil
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

    -- One-shot NPC tool firing (click-based)
    if fingerGunEnabled or sitGunEnabled or grabGunEnabled then
        local function raycastNpc()
            -- Inline raycast so this click handler never depends on getMouseRayHit scope.
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

        -- Finger Gun: kill first NPC humanoid hit
        if fingerGunEnabled then
            local model = raycastNpc()
            if model then
                local npcModel, _ = model, nil
                local h = (npcModel and npcModel:FindFirstChildOfClass("Humanoid")) or nil
                if h then pcall(function() h.Health = 0 end) end
            end
        end

        -- Sit Gun: set Humanoid.Sit=true
        if sitGunEnabled then
            local model = raycastNpc()
            if model then
                local npcModel, _ = model, nil
                local h = (npcModel and npcModel:FindFirstChildOfClass("Humanoid")) or nil
                if h then pcall(function() h.Sit = true end) end
            end
        end

        -- Grab Gun: click-grab/drag, next click toss, repeat
        if grabGunEnabled then
            if not grabbedRoot or not grabbedNPC or not grabbedRoot.Parent then
                local res = raycastNpc()
                if res then
                    grabbedNPC  = res
                    grabbedRoot = grabbedNPC and grabbedNPC:FindFirstChild("HumanoidRootPart") or nil
                    if grabbedRoot then
                        -- start "armed" hover immediately
                        grabbedRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    end
                end
            else
                -- toss toward clicked point
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

    -- Telekinesis Hold Gun: press to grab & float an NPC (release tosses it)
    if tkGunEnabled then
        local origin = Camera.CFrame.Position
        local dir = (currentMouseHit - origin)
        if dir.Magnitude > 0.001 then
            local hit = workspace:Raycast(origin, dir.Unit * FINGER_GUN_RANGE, _npcToolsRayParams)
            if hit and hit.Instance then
                local model = hit.Instance:FindFirstAncestorOfClass("Model") or hit.Instance.Parent
                if model and isNPCModel(model) then
                    tkHeld     = model
                    tkHeldRoot = model:FindFirstChild("HumanoidRootPart")
                    local h = model:FindFirstChildOfClass("Humanoid")
                    if h then tkSavedPlatform = h.PlatformStand; pcall(function() h.PlatformStand = true end) end
                    if tkHeldRoot then pcall(function() tkHeldRoot.AssemblyLinearVelocity = Vector3.zero end) end
                end
            end
        end
        return
    end

    -- Freeze Gun: click an NPC to stun/freeze it; click again to release it
    if freezeGunEnabled then
        local origin = Camera.CFrame.Position
        local dir = (currentMouseHit - origin)
        if dir.Magnitude > 0.001 then
            local hit = workspace:Raycast(origin, dir.Unit * FINGER_GUN_RANGE, _npcToolsRayParams)
            if hit and hit.Instance then
                local model = hit.Instance:FindFirstAncestorOfClass("Model") or hit.Instance.Parent
                if model and isNPCModel(model) then
                    local h = model:FindFirstChildOfClass("Humanoid")
                    if frozenNPCs[model] then
                        -- already frozen → restore saved stats and release
                        local s = frozenNPCs[model]
                        if h then pcall(function()
                            h.WalkSpeed = s.ws; h.JumpPower = s.jp
                            pcall(function() h.JumpHeight = s.jh end)
                            h.AutoRotate = s.ar; h.PlatformStand = s.ps
                        end) end
                        frozenNPCs[model] = nil
                    elseif h then
                        -- freeze → save current stats, then zero everything + stun
                        local jh = 0; pcall(function() jh = h.JumpHeight end)
                        frozenNPCs[model] = {ws=h.WalkSpeed, jp=h.JumpPower, jh=jh, ar=h.AutoRotate, ps=h.PlatformStand}
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

    -- Click Area mode: set the formation center point
    if formationType == "ClickArea" then
        clickFormPos = currentMouseHit
        return
    end

    -- Satellite: fire the cluster (first quarter of parts) toward the cursor
    if activeMode=="Satellite" and #selectedParts > 0 then
        local clusterN = math.max(1, math.ceil(#selectedParts / 4))
        local now = tick()
        satTarget = currentMouseHit
        for i = 1, clusterN do
            if selectedParts[i] then
                local part = selectedParts[i]
                satFired[part] = now

                -- Spin the part REALLY fast for fling effect
                pcall(function()
                    part.AssemblyAngularVelocity = Vector3.new(
                        (math.random() - 0.5) * 500,
                        (math.random() - 0.5) * 500,
                        (math.random() - 0.5) * 500
                    )
                end)

                -- Add fling Touched connection
                if satTouchConns[part] then
                    pcall(function() satTouchConns[part]:Disconnect() end)
                end
                satTouchConns[part] = part.Touched:Connect(function(hit)
                    if not hit or not hit.Parent or hit.Anchored then return end
                    if hit == workspace.Terrain then return end

                    -- Apply unstable fling force to parts and players
                    pcall(function()
                        local flingDir = (hit.Position - part.Position).Unit
                        local instability = Vector3.new(
                            (math.random() - 0.5) * 8,
                            (math.random() - 0.5) * 8 + 4,  -- stronger upward bias
                            (math.random() - 0.5) * 8
                        )
                        local flingForce = (flingDir + instability * 0.8).Unit * 3000
                        hit.AssemblyLinearVelocity = flingForce
                        hit.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * 300,
                            (math.random() - 0.5) * 300,
                            (math.random() - 0.5) * 300
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
                spcPart=clickTarget; return
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

-- Tab/Escape release
reg(UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Tab and npcTarget then
        releaseNPC(); UI.npcStat.Text="Released via Tab"
    end
    if inp.KeyCode==Enum.KeyCode.Escape and spcActive then
        if spcPart then pcall(function() spcPart.AssemblyLinearVelocity=Vector3.zero end) end
        spcPart=nil; spcActive=false
        UI.spcBtn.BackgroundColor3=B_DEF; UI.spcBtn.TextColor3=T1
        UI.spcBtn.Text="Single Part Control: OFF"
    end
end))

-- ─────────────────────────────────────────────────────────────
-- [16]  MAIN HEARTBEAT
-- ─────────────────────────────────────────────────────────────
reg(RunService.Heartbeat:Connect(function()
    updateMouseHit()

    if autoSelectAll or autoSelectNear then
        local now = tick()
        if (now - autoSelectLastScan) >= AUTO_SELECT_INTERVAL then
            runAutoSelectScan()
        end
    end

    -- Slinky: record mouse path for chain delay
    if activeMode=="Slinky" and #selectedParts>0 then
        local pos=currentMouseHit
        if #slinkyHistory==0 or (slinkyHistory[#slinkyHistory]-pos).Magnitude>0.12 then
            table.insert(slinkyHistory,pos)
            if #slinkyHistory>SLINKY_MAX then table.remove(slinkyHistory,1) end
        end
    end

    -- Draw trail recording (only while mouse held)
    if activeMode=="Draw" and isDrawing and #selectedParts>0 then
        local pos=currentMouseHit
        if #drawTrail==0 or (drawTrail[#drawTrail]-pos).Magnitude>1.0 then
            table.insert(drawTrail,pos)
            if #drawTrail>600 then table.remove(drawTrail,1) end
            if #drawTrail%8==0 then addDrawDot(pos) end  -- neon indicator every 8 pts
        end
    end

    -- Main part control
    if #selectedParts>0 or spcActive or globalOwnership or activeMode=="Comet" then
        tickParts()
    end

    -- NPC auras
    tickAuras()

    -- Selection info
    UI.selInfo.Text="#"..#selectedParts.." selected · "..activeMode
        ..(frozen and " [FROZEN]" or "")..(attracting and " [ATTRACT]" or "")
        ..(hasFileSystem and " · cfg" or "")

    -- Auto-save config
    saveConfig()
end))

reg(RunService.RenderStepped:Connect(function()
    if useESP then updateESP() end
end))
