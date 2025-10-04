if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not workspace:FindFirstChild("AREA51") then
    return
end

-- Singleton setup
local RS = game:GetService("ReplicatedStorage")
local SCRIPT_ID = "SurvivorESPController"

local existing = RS:FindFirstChild(SCRIPT_ID)
if existing and existing:IsA("BindableEvent") then
    existing:Fire()
    existing:Destroy()
end

local shutdownSignal = Instance.new("BindableEvent")
shutdownSignal.Name = SCRIPT_ID
shutdownSignal.Parent = RS

-- Service wrapper
Services = setmetatable({}, {
    __index = function(self, key)
        local service = game:GetService(key)
        if service then
            rawset(self, key, service)
            return service
        end
        error("Service '" .. key .. "' not found", 2)
    end
})

-- State
local shuttingDown = false
local activeHighlights = {}
local espCache = {}
local connections = {}
local ammoTouchStarted = false

-- Shutdown handler
shutdownSignal.Event:Connect(function()
    shuttingDown = true
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    connections = {}
    for _, highlight in ipairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    activeHighlights = {}
    espCache = {}
    print("Previous instance shut down.")
end)

-- Utility
local function PlayerIsSurvivor()
    local player = Services.Players.LocalPlayer
    return (player.Team and player.Team.Name == "Survivors") or #Services.Teams:GetChildren() == 0
end

local function CreateOrUpdateESP(target, color)
    if not target:IsA("Model") or espCache[target] then
        return
    end

    local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
    if root then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = target
        highlight.FillColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = color
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = target
        espCache[target] = highlight
        table.insert(activeHighlights, highlight)
    end
end

local function ClearESP()
    for target, highlight in pairs(espCache) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    espCache = {}
    activeHighlights = {}
end

local function FindAmmoBox()
    local area51 = workspace:FindFirstChild("AREA51")
    if not area51 then
        return nil
    end

    for _, descendant in ipairs(area51:GetDescendants()) do
        if descendant.Name == "Box of Shells" and descendant:IsA("Model") then
            local box = descendant:FindFirstChild("Box")
            if box and box:IsA("BasePart") and box:FindFirstChild("TouchInterest") then
                return box
            end
        end
    end
    return nil
end

local function SimulateTouch(partA, partB)
    firetouchinterest(partA, partB, 0)
end

local ammoTouchLoopRunning = false

local function SustainAmmoTouch(rootPart)
    if ammoTouchLoopRunning then
        return
    end
    ammoTouchLoopRunning = true

    task.spawn(function()
        while not shuttingDown do
            local box = FindAmmoBox()
            if box then
                box.CanCollide = false
                SimulateTouch(box, rootPart)
            end
            task.wait(1.5)
        end
    end)
end

-- Logic
local recentlyDroppedWeapons = {}

local function TrackDroppedWeapons()
    local backpack = Services.Players.LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        return
    end

    for _, tool in ipairs(backpack:GetChildren()) do
        recentlyDroppedWeapons[tool.Name] = os.clock()
    end
end

local function IsPlayerInPackAPunchRoom()
    local player = Services.Players.LocalPlayer
    local character = player and player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    local room = workspace:FindFirstChild("AREA51") and workspace.AREA51:FindFirstChild("SecretTeleportRoom")
    if not room then
        return false
    end

    local front = room:GetChildren()[12]
    local back = room:FindFirstChild("Part")
    local right = room:GetChildren()[11]
    local left = room:GetChildren()[10]
    local roof = room:GetChildren()[14]
    local ground = room:GetChildren()[13]

    if not (front and back and right and left and roof and ground) then
        return false
    end

    local minX = math.min(left.Position.X, right.Position.X)
    local maxX = math.max(left.Position.X, right.Position.X)
    local minY = ground.Position.Y
    local maxY = roof.Position.Y
    local minZ = math.min(front.Position.Z, back.Position.Z)
    local maxZ = math.max(front.Position.Z, back.Position.Z)

    local pos = root.Position

    return (pos.X >= minX and pos.X <= maxX) and (pos.Y >= minY and pos.Y <= maxY) and (pos.Z >= minZ and pos.Z <= maxZ)
end

local function ShouldSkipDrop(weapon)
    local inRoom = IsPlayerInPackAPunchRoom()
    if inRoom then
        print("Skipping drop for", weapon.Name, "because player is in Pack-a-Punch room")
    end
    return inRoom
end

local function ApplySurvivorLogic()
    TrackDroppedWeapons()

    local player = Services.Players.LocalPlayer
    local character = player.Character
    if not character then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local weaponsFolder = workspace:FindFirstChild("Weapons")
    local killersFolder = workspace:FindFirstChild("Killers")
    if not weaponsFolder or not killersFolder then
        return
    end

    ClearESP()

    local killers = killersFolder:GetChildren()
    for i = 1, #killers do
        CreateOrUpdateESP(killers[i], Color3.fromRGB(255, 0, 0))
    end

    local weapons = weaponsFolder:GetChildren()
    for i = 1, #weapons do
        local weapon = weapons[i]
        if not ShouldSkipDrop(weapon) then
            local hitbox = weapon:FindFirstChild("Hitbox")
            if hitbox and hitbox:IsA("BasePart") then
                hitbox.CanCollide = false
                task.defer(SimulateTouch, hitbox, rootPart)
            end
        end
    end
end

local function ApplyNonSurvivorLogic()
    local player = Services.Players.LocalPlayer
    if not player.Character then
        return
    end

    local survivorsTeam = Services.Teams:FindFirstChild("Survivors")
    if survivorsTeam then
        ClearESP()
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr.Team == survivorsTeam and plr.Character then
                CreateOrUpdateESP(plr.Character, Color3.fromRGB(0, 255, 0))
            end
        end
    end

    local killername, killermodel

    for _, killer in ipairs(workspace.Killers:GetChildren()) do
        local humanoid = killer:FindFirstChild("Humanoid")
        if humanoid and humanoid:IsA("Humanoid") and humanoid.DisplayName == player.Name then
            killername = killer.Name
            killermodel = killer
            humanoid.WalkSpeed = 25
            break
        end
    end
end

local function ApplyTeamLogic()
    if shuttingDown then
        return
    end
    if PlayerIsSurvivor() then
        ApplySurvivorLogic()
    else
        ApplyNonSurvivorLogic()
    end
end

-- Connections
local player = Services.Players.LocalPlayer

local function SetupPlayerEvents(plr)
    table.insert(connections, plr.CharacterAdded:Connect(function()
        if plr == player or not PlayerIsSurvivor() then
            ApplyTeamLogic()
        end
    end))
end

SetupPlayerEvents(player)
table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(ApplyTeamLogic))

table.insert(connections, Services.Players.PlayerAdded:Connect(function(plr)
    SetupPlayerEvents(plr)
end))

if player.Character then
    ApplyTeamLogic()
end

-- Periodic refresh
task.spawn(function()
    while not shuttingDown do
        ApplyTeamLogic()
        task.wait(3)
    end
end)
