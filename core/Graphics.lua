local function CreateCommandBar(screen)
    local container = Instance.new("Frame", screen)
    container.Size = UDim2.new(0.5, 0, 0, 36)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    container.BorderSizePixel = 0
    container.Visible = false

    local shadow = Instance.new("ImageLabel", container)
    shadow.Image = "rbxassetid://1316045217"
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, -6, 0, -6)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.5
    shadow.ZIndex = 0

    local CommandBar = Instance.new("TextBox", container)
    CommandBar.Size = UDim2.new(1, -40, 1, 0)
    CommandBar.Position = UDim2.new(0, 0, 0, 0)
    CommandBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    CommandBar.BorderSizePixel = 0
    CommandBar.TextColor3 = Color3.fromRGB(200, 200, 200)
    CommandBar.Font = Enum.Font.Code
    CommandBar.PlaceholderText = "Enter command..."
    CommandBar.TextSize = 16
    CommandBar.Text = ""
    CommandBar.ClearTextOnFocus = false
    CommandBar.ZIndex = 1

    local Close = Instance.new("TextButton", container)
    Close.Size = UDim2.new(0, 36, 1, 0)
    Close.Position = UDim2.new(1, -36, 0, 0)
    Close.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    Close.Text = "X"
    Close.TextColor3 = Color3.fromRGB(255, 80, 80)
    Close.Font = Enum.Font.SourceSansBold
    Close.TextSize = 18
    Close.ZIndex = 1
    Close.AutoButtonColor = true

    return {
        Container = container,
        CommandBar = CommandBar,
        Close = Close,
    }
end

local function CreateSmallIcon(screen)
    local Icon = Instance.new("Frame", screen)
    Icon.Name = "SmallIcon"
    Icon.Size = UDim2.new(0, 50, 0, 50)
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    Icon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Icon.Visible = true

    local stroke = Instance.new("UIStroke", Icon)
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Thickness = 2

    local corner = Instance.new("UICorner", Icon)
    corner.CornerRadius = UDim.new(0, 6)

    return Icon
end

local function CreateCommandUI(screen)
    local barParts = CreateCommandBar(screen)
    local icon = CreateSmallIcon(screen)

    local container = barParts.Container
    local CommandBar = barParts.CommandBar
    local Close = barParts.Close

    local function syncFromIcon()
        container.Position = icon.Position
    end

    local function syncFromContainer()
        icon.Position = container.Position
    end

    Close.MouseButton1Click:Connect(function()
        dev_log(0, "Close Button was clicked!")
        container.Visible = false
        icon.Visible = true
        CommandBar:ReleaseFocus()
        syncFromContainer()
    end)

    local MIN_DIST = 12
    local wasDragged = false
    icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wasDragged = false
            local startPos = input.Position
            local movedConn, endedConn

            movedConn = Services.UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput == input then
                    local delta = moveInput.Position - startPos
                    if delta.Magnitude > MIN_DIST then
                        wasDragged = true
                        movedConn:Disconnect()
                    end
                end
            end)

            endedConn = Services.UserInputService.InputEnded:Connect(function(endInput)
                if endInput == input then
                    endedConn:Disconnect()
                    if movedConn then
                        movedConn:Disconnect()
                    end

                    if not wasDragged then
                        dev_log(0, "Icon clicked!")
                        container.Position = icon.Position
                        container.Visible = true
                        icon.Visible = false
                        CommandBar:CaptureFocus()
                    end
                end
            end)
        end
    end)

    Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then
            return
        end
        if input.KeyCode == Enum.KeyCode.Semicolon then
            local showing = not container.Visible
            container.Visible = showing
            icon.Visible = not showing

            if showing then
                container.Position = icon.Position
                CommandBar:CaptureFocus()
            else
                icon.Position = container.Position
                CommandBar:ReleaseFocus()
            end
        end
    end)

    CommandBar.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local input = CommandBar.Text
            CommandBar.Text = ""
            dev_log(1, "Executing command:", input)
            CommandManager:Execute(input)
        end
    end)

    return container, icon
end

return CreateCommandBar, CreateSmallIcon, CreateCommandUI
