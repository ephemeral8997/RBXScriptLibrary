if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not game:GetService("ReplicatedStorage").StarterGui.Area51Personnel then
    return
end

function profile(name, fn)
    local start = tick()
    local ok, result_or_err = pcall(fn)
    local elapsed = (tick() - start) * 1000

    if elapsed > 1 then
        print(string.format("[PROFILING WARNING] %s took %.2f ms", name, elapsed))
    end

    if not ok then
        warn(string.format("[ERROR] %s error: %s", name, result_or_err))
    end

    return result_or_err
end

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

function PlayerIsSurvivor()
    local player = Services.Players.LocalPlayer

    if (player.Team and player.Team.Name == "Survivors") or #Services.Teams:GetChildren() == 0 then
        return true
    end

    return false
end

function ApplySurvivorLogic()
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
    if not weaponsFolder then
        return
    end

    coroutine.wrap(function()
        for _, weapon in ipairs(weaponsFolder:GetChildren()) do
            local hitbox = weapon:FindFirstChild("Hitbox")
            if hitbox and hitbox:IsA("BasePart") then
                -- Store original state
                local originalCFrame = hitbox.CFrame
                local originalPosition = hitbox.Position
                local originalAnchored = hitbox.Anchored
                local originalCanCollide = hitbox.CanCollide
                local originalTransparency = hitbox.Transparency
                local originalSize = hitbox.Size
                local originalColor = hitbox.Color
                local originalMaterial = hitbox.Material

                -- Temporarily disable collision and move away from character
                hitbox.Anchored = true
                hitbox.CanCollide = false
                hitbox.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)

                -- Simulate touch safely
                firetouchinterest(hitbox, rootPart, 0)
                task.wait(0.1) -- Add delay between begin and end
                firetouchinterest(hitbox, rootPart, 1)

                -- Restore original state
                hitbox.CFrame = originalCFrame
                hitbox.Position = originalPosition
                hitbox.Anchored = originalAnchored
                hitbox.CanCollide = originalCanCollide
                hitbox.Transparency = originalTransparency
                hitbox.Size = originalSize
                hitbox.Color = originalColor
                hitbox.Material = originalMaterial

                task.wait(0.2) -- Delay before moving to next weapon
            end
        end
    end)()
end

function ApplyNonSurvivorLogic()
    local player = Services.Players.LocalPlayer

    if player.Character then
        return
    end
end

local function ApplyTeamLogic()
    profile("TeamLogic", function()
        if PlayerIsSurvivor() then
            ApplySurvivorLogic()
        else
            ApplyNonSurvivorLogic()
        end
    end)
end

local player = Services.Players.LocalPlayer

player.CharacterAdded:Connect(function()
    ApplyTeamLogic()
end)

if player.Character then
    ApplyTeamLogic()
end
