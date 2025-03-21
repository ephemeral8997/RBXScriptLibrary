__VERSION__ = "v1.0.0"
__TITLE__ = "@ephemeral8997's ADMIN"
__GUI_NAME__ = "EphGuiScriptProject8997"
__DESCRIPTION__ = "A script designed and programmed by @ephemeral8997 for harmless fun and with anti-cheat capabilities (working on that...)"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Configuration = {
    Players = game.Players,
    Player = game.Players.LocalPlayer,
    PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"),
}

local TaskManager = {}
function TaskManager:AddEntry(task, category)
    category = category and category ~= nil or "Untitled"
    TaskManager[category] = TaskManager[category] or {}
    table.insert(TaskManager[category], task)
end

function TaskManager:ClearTaskInCategory(category)
    category = category and category ~= nil or "Untitled"
    TaskManager:ClearTaskList(TaskManager[category])
    TaskManager[category] = {}
end

function TaskManager:ClearTaskList(tasks)
    if type(tasks) ~= "table" then
        return
    end
    for _, task in ipairs(TaskManager[category]) do
        task:Disconnect()
    end
end

function TaskManager:ClearAllTasks()
    for category, tasks in pairs(TaskManager:GetChildren()) do
        TaskManager:ClearTaskList(tasks)
        TaskManager[category] = {}
    end
end

local Services = setmetatable({}, {
    __index = function(self, key)
        local service = game:GetService(key)
        if service then
            rawset(self, key, service)
            return service
        end
        error("Service '" .. key .. "' not found", 2)
    end,
})

local MainScreen = Instance.new("ScreenGui", Configuration.PlayerGui)
MainScreen.Name = __GUI_NAME__

local GuiFrame = Instance.new("Frame", MainScreen)

local DraggableFrame = Instance.new("Frame", GuiFrame)
DraggableFrame.Draggable = true
DraggableFrame.Active = false

local CommandBar = Instance.new("TextBox", GuiFrame)

local MinimizeButton = Instance.new("TextButton", GuiFrame)
MinimizeButton.Active = false
