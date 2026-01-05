

local _hookmetamethod = hookmetamethod
local _getnamecallmethod = getnamecallmethod
local _checkcaller = checkcaller
local _newcclosure = newcclosure

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local LocalPlayer = Players.LocalPlayer


local GuiParent = (function()
    local success, coreGui = pcall(game.GetService, game, "CoreGui")
    return success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
end)()


local hasHook = hookmetamethod ~= nil
local getNamecall = getnamecallmethod or function() return "" end
local checkCaller = checkcaller or function() return false end
local newCC = newcclosure or function(f) return f end


local remoteLog = {}
local remoteCache = {}
local isCapturing = true
local selectedEntry = nil
local isMinimized = false
local uiQueue = {}
local filterText = ""
local filterType = "All"
local favorites = {}
local blockedRemotes = {}

-- Configuration
local config = {
    maxLogs = 300,
    deduplicateTime = 0.05,
    enableNotifications = true,
    animationSpeed = 0.2
}


local function safeStringify(value, depth)
    depth = depth or 0
    if depth > 2 then return "..." end
    
    local t = typeof(value)
    if t == "Instance" then
        local s, name = pcall(function() return value:GetFullName() end)
        return s and name or tostring(value)
    elseif t == "table" then
        local str = "{"
        local count = 0
        pcall(function()
            for k, v in pairs(value) do
                if count > 3 then str = str .. "..." break end
                str = str .. tostring(k) .. "=" .. safeStringify(v, depth + 1) .. ", "
                count = count + 1
            end
        end)
        return str .. "}"
    elseif t == "CFrame" then
        return string.format("CFrame(%.1f,%.1f,%.1f)", value.X, value.Y, value.Z)
    elseif t == "Vector3" then
        return string.format("Vec3(%.1f,%.1f,%.1f)", value.X, value.Y, value.Z)
    elseif t == "number" then
        return string.format("%.2f", value)
    else
        return tostring(value)
    end
end

local function deepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function findRemoteByPath(path)
    local success, remote = pcall(function()
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end
        
        local current = game
        for i, part in ipairs(parts) do
            if i > 1 then
                current = current:FindFirstChild(part, true)
                if not current then return nil end
            else
                current = game:GetService(part)
            end
        end
        return current
    end)
    
    if success and remote then return remote end
    return remoteCache[path]
end

local function storeRemote(path, remote)
    if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
        remoteCache[path] = remote
    end
end


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoteSpy_" .. math.random(10000, 99999)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = GuiParent


local function showNotification(text, color, duration)
    if not config.enableNotifications then return end
    duration = duration or 2
    
    task.spawn(function()
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 260, 0, 55)
        notif.Position = UDim2.new(0.5, -130, 0, -65)
        notif.BackgroundColor3 = color or Color3.fromRGB(40, 40, 50)
        notif.BorderSizePixel = 0
        notif.ZIndex = 100
        notif.Parent = ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = notif
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.7
        stroke.Thickness = 1.5
        stroke.Parent = notif
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
        }
        gradient.Rotation = 90
        gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.95),
            NumberSequenceKeypoint.new(1, 0.98)
        }
        gradient.Parent = notif
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Parent = notif
        
        notif:TweenPosition(UDim2.new(0.5, -130, 0, 15), "Out", "Quad", 0.3, true)
        wait(duration)
        notif:TweenPosition(UDim2.new(0.5, -130, 0, -65), "In", "Quad", 0.3, true)
        wait(0.3)
        notif:Destroy()
    end)
end


local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.new(0, 65, 0, 65)
MinButton.Position = UDim2.new(0, 20, 0.5, -32.5)
MinButton.BackgroundColor3 = Color3.fromRGB(255, 70, 150)
MinButton.BorderSizePixel = 0
MinButton.Text = "📡"
MinButton.TextColor3 = Color3.new(1, 1, 1)
MinButton.TextSize = 26
MinButton.Font = Enum.Font.GothamBold
MinButton.Visible = false
MinButton.ZIndex = 50
MinButton.Parent = ScreenGui

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinButton

local MinGradient = Instance.new("UIGradient")
MinGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 170)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 150))
}
MinGradient.Rotation = 45
MinGradient.Parent = MinButton

-- Frame principale (AMÉLIORÉE - BIEN ALIGNÉE)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 540)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 22)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 70, 150)
MainStroke.Thickness = 3
MainStroke.Transparency = 0
MainStroke.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 150)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 150))
}
MainGradient.Rotation = 45
MainGradient.Parent = MainStroke


local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 22)
HeaderCorner.Parent = Header

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 32))
}
HeaderGradient.Rotation = 90
HeaderGradient.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 180, 0, 24)
Title.Position = UDim2.new(0, 18, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "📡 REMOTE SPY V1.0.4"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 180, 0, 16)
Subtitle.Position = UDim2.new(0, 18, 0, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "By Nxth9n"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
Subtitle.TextSize = 9
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local StatusBadge = Instance.new("Frame")
StatusBadge.Size = UDim2.new(0, 80, 0, 24)
StatusBadge.Position = UDim2.new(1, -190, 0, 15.5)
StatusBadge.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
StatusBadge.BorderSizePixel = 0
StatusBadge.Parent = Header

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 12)
StatusCorner.Parent = StatusBadge

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● ACTIVE"
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Parent = StatusBadge


local function createHeaderButton(text, position, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Header
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    return btn
end

local HideBtn = createHeaderButton("—", UDim2.new(1, -95, 0, 7.5), Color3.fromRGB(60, 60, 75))
local BlockedListBtn = createHeaderButton("🚫", UDim2.new(1, -50, 0, 7.5), Color3.fromRGB(220, 70, 70))


local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -30, 0, 40)
SearchFrame.Position = UDim2.new(0, 15, 0, 65)
SearchFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
SearchFrame.BorderSizePixel = 0
SearchFrame.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 12)
SearchCorner.Parent = SearchFrame

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 35, 1, 0)
SearchIcon.Position = UDim2.new(0, 5, 0, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextSize = 14
SearchIcon.Parent = SearchFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -75, 1, 0)
SearchBox.Position = UDim2.new(0, 40, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search remotes..."
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
SearchBox.TextSize = 13
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.Parent = SearchFrame

local ClearSearchBtn = Instance.new("TextButton")
ClearSearchBtn.Size = UDim2.new(0, 30, 0, 30)
ClearSearchBtn.Position = UDim2.new(1, -35, 0.5, -15)
ClearSearchBtn.BackgroundTransparency = 1
ClearSearchBtn.BorderSizePixel = 0
ClearSearchBtn.Text = "✕"
ClearSearchBtn.TextColor3 = Color3.fromRGB(200, 60, 60)
ClearSearchBtn.TextSize = 16
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.Visible = false
ClearSearchBtn.Parent = SearchFrame


local FilterContainer = Instance.new("Frame")
FilterContainer.Size = UDim2.new(1, -30, 0, 35)
FilterContainer.Position = UDim2.new(0, 15, 0, 115)
FilterContainer.BackgroundTransparency = 1
FilterContainer.Parent = MainFrame

local FilterLayout = Instance.new("UIListLayout")
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
FilterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
FilterLayout.Padding = UDim.new(0, 8)
FilterLayout.Parent = FilterContainer

local function createFilterButton(text, isActive)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.31, -6, 1, 0)
    btn.BackgroundColor3 = isActive and Color3.fromRGB(255, 70, 150) or Color3.fromRGB(35, 35, 45)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = FilterContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = isActive and Color3.fromRGB(255, 100, 170) or Color3.fromRGB(50, 50, 60)
    stroke.Thickness = isActive and 2 or 1
    stroke.Transparency = 0.3
    stroke.Parent = btn
    
    return btn
end

local FilterAllBtn = createFilterButton("ALL", true)
local FilterEventBtn = createFilterButton("EVENTS", false)
local FilterFuncBtn = createFilterButton("FUNCTIONS", false)


local RemoteList = Instance.new("ScrollingFrame")
RemoteList.Size = UDim2.new(1, -30, 0, 200)
RemoteList.Position = UDim2.new(0, 15, 0, 160)
RemoteList.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
RemoteList.BorderSizePixel = 0
RemoteList.ScrollBarThickness = 5
RemoteList.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 150)
RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
RemoteList.ScrollingDirection = Enum.ScrollingDirection.Y
RemoteList.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 13)
ListCorner.Parent = RemoteList

local ListStroke = Instance.new("UIStroke")
ListStroke.Color = Color3.fromRGB(50, 50, 60)
ListStroke.Thickness = 1
ListStroke.Transparency = 0.5
ListStroke.Parent = RemoteList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = RemoteList


local DetailsPanel = Instance.new("ScrollingFrame")
DetailsPanel.Size = UDim2.new(1, -30, 0, 90)
DetailsPanel.Position = UDim2.new(0, 15, 0, 370)
DetailsPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
DetailsPanel.BorderSizePixel = 0
DetailsPanel.ScrollBarThickness = 5
DetailsPanel.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 150)
DetailsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
DetailsPanel.Parent = MainFrame

local DetailsCorner = Instance.new("UICorner")
DetailsCorner.CornerRadius = UDim.new(0, 13)
DetailsCorner.Parent = DetailsPanel

local DetailsStroke = Instance.new("UIStroke")
DetailsStroke.Color = Color3.fromRGB(50, 50, 60)
DetailsStroke.Thickness = 1
DetailsStroke.Transparency = 0.5
DetailsStroke.Parent = DetailsPanel

local DetailsText = Instance.new("TextLabel")
DetailsText.Size = UDim2.new(1, -20, 1, 0)
DetailsText.Position = UDim2.new(0, 10, 0, 10)
DetailsText.BackgroundTransparency = 1
DetailsText.Text = "💡 Select a remote to view details\n▶️ Replay | ✏️ Edit | 🚫 Block"
DetailsText.TextColor3 = Color3.fromRGB(160, 160, 180)
DetailsText.TextSize = 11
DetailsText.Font = Enum.Font.Code
DetailsText.TextWrapped = true
DetailsText.TextXAlignment = Enum.TextXAlignment.Left
DetailsText.TextYAlignment = Enum.TextYAlignment.Top
DetailsText.Parent = DetailsPanel


local ActionContainer = Instance.new("Frame")
ActionContainer.Size = UDim2.new(1, -30, 0, 70)
ActionContainer.Position = UDim2.new(0, 15, 1, -80)
ActionContainer.BackgroundTransparency = 1
ActionContainer.Parent = MainFrame

local ActionLayout = Instance.new("UIGridLayout")
ActionLayout.CellSize = UDim2.new(0.485, 0, 0, 32)
ActionLayout.CellPadding = UDim2.new(0.03, 0, 0, 6)
ActionLayout.FillDirection = Enum.FillDirection.Horizontal
ActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ActionLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ActionLayout.SortOrder = Enum.SortOrder.LayoutOrder
ActionLayout.Parent = ActionContainer

local function createActionButton(text, emoji, color, order)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = ActionContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 1
    stroke.Transparency = 0.8
    stroke.Parent = btn
    
    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Size = UDim2.new(0, 28, 1, 0)
    emojiLabel.Position = UDim2.new(0, 8, 0, 0)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Text = emoji
    emojiLabel.TextSize = 16
    emojiLabel.Parent = btn
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -40, 1, 0)
    textLabel.Position = UDim2.new(0, 36, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = btn
    
    return btn
end

local ReplayBtn = createActionButton("REPLAY", "▶️", Color3.fromRGB(100, 150, 255), 1)
local EditBtn = createActionButton("EDIT", "✏️", Color3.fromRGB(255, 180, 50), 2)
local BlockBtn = createActionButton("BLOCK", "🚫", Color3.fromRGB(220, 70, 70), 3)
local CaptureBtn = createActionButton("PAUSE", "⏸️", Color3.fromRGB(60, 200, 120), 4)
local ClearBtn = createActionButton("CLEAR", "🗑️", Color3.fromRGB(180, 60, 100), 5)

local EditModal = Instance.new("Frame")
EditModal.Size = UDim2.new(1, 0, 1, 0)
EditModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
EditModal.BackgroundTransparency = 0.5
EditModal.BorderSizePixel = 0
EditModal.Visible = false
EditModal.ZIndex = 100
EditModal.Parent = MainFrame

local EditFrame = Instance.new("Frame")
EditFrame.Size = UDim2.new(0.92, 0, 0.75, 0)
EditFrame.Position = UDim2.new(0.04, 0, 0.125, 0)
EditFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
EditFrame.BorderSizePixel = 0
EditFrame.ZIndex = 101
EditFrame.Parent = EditModal

local EditFrameCorner = Instance.new("UICorner")
EditFrameCorner.CornerRadius = UDim.new(0, 16)
EditFrameCorner.Parent = EditFrame

local EditFrameStroke = Instance.new("UIStroke")
EditFrameStroke.Color = Color3.fromRGB(255, 180, 50)
EditFrameStroke.Thickness = 2
EditFrameStroke.Parent = EditFrame

local EditHeader = Instance.new("Frame")
EditHeader.Size = UDim2.new(1, 0, 0, 50)
EditHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
EditHeader.BorderSizePixel = 0
EditHeader.ZIndex = 101
EditHeader.Parent = EditFrame

local EditHeaderCorner = Instance.new("UICorner")
EditHeaderCorner.CornerRadius = UDim.new(0, 16)
EditHeaderCorner.Parent = EditHeader

local EditTitle = Instance.new("TextLabel")
EditTitle.Size = UDim2.new(1, -60, 1, 0)
EditTitle.Position = UDim2.new(0, 15, 0, 0)
EditTitle.BackgroundTransparency = 1
EditTitle.Text = "✏️ Edit Arguments"
EditTitle.TextColor3 = Color3.fromRGB(255, 180, 50)
EditTitle.TextSize = 18
EditTitle.Font = Enum.Font.GothamBold
EditTitle.TextXAlignment = Enum.TextXAlignment.Left
EditTitle.ZIndex = 101
EditTitle.Parent = EditHeader

local EditCloseBtn = Instance.new("TextButton")
EditCloseBtn.Size = UDim2.new(0, 40, 0, 40)
EditCloseBtn.Position = UDim2.new(1, -45, 0, 5)
EditCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
EditCloseBtn.BorderSizePixel = 0
EditCloseBtn.Text = "✕"
EditCloseBtn.TextColor3 = Color3.new(1, 1, 1)
EditCloseBtn.TextSize = 18
EditCloseBtn.Font = Enum.Font.GothamBold
EditCloseBtn.ZIndex = 101
EditCloseBtn.Parent = EditHeader

local EditCloseBtnCorner = Instance.new("UICorner")
EditCloseBtnCorner.CornerRadius = UDim.new(0, 8)
EditCloseBtnCorner.Parent = EditCloseBtn

local EditInfo = Instance.new("TextLabel")
EditInfo.Size = UDim2.new(1, -20, 0, 40)
EditInfo.Position = UDim2.new(0, 10, 0, 60)
EditInfo.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
EditInfo.BorderSizePixel = 0
EditInfo.Text = "💡 Edit each line, keep format: [1] value"
EditInfo.TextColor3 = Color3.new(1, 1, 1)
EditInfo.TextSize = 11
EditInfo.Font = Enum.Font.Gotham
EditInfo.TextWrapped = true
EditInfo.ZIndex = 101
EditInfo.Parent = EditFrame

local EditInfoCorner = Instance.new("UICorner")
EditInfoCorner.CornerRadius = UDim.new(0, 8)
EditInfoCorner.Parent = EditInfo

local EditArgsBox = Instance.new("TextBox")
EditArgsBox.Size = UDim2.new(1, -20, 1, -170)
EditArgsBox.Position = UDim2.new(0, 10, 0, 110)
EditArgsBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
EditArgsBox.BorderSizePixel = 0
EditArgsBox.Text = ""
EditArgsBox.TextColor3 = Color3.new(1, 1, 1)
EditArgsBox.TextSize = 12
EditArgsBox.Font = Enum.Font.Code
EditArgsBox.TextXAlignment = Enum.TextXAlignment.Left
EditArgsBox.TextYAlignment = Enum.TextYAlignment.Top
EditArgsBox.ClearTextOnFocus = false
EditArgsBox.MultiLine = true
EditArgsBox.TextWrapped = true
EditArgsBox.ZIndex = 101
EditArgsBox.Parent = EditFrame

local EditArgsCorner = Instance.new("UICorner")
EditArgsCorner.CornerRadius = UDim.new(0, 10)
EditArgsCorner.Parent = EditArgsBox

local EditSaveBtn = Instance.new("TextButton")
EditSaveBtn.Size = UDim2.new(1, -20, 0, 45)
EditSaveBtn.Position = UDim2.new(0, 10, 1, -55)
EditSaveBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
EditSaveBtn.BorderSizePixel = 0
EditSaveBtn.Text = "💾 SAVE & FIRE REMOTE"
EditSaveBtn.TextColor3 = Color3.new(1, 1, 1)
EditSaveBtn.TextSize = 15
EditSaveBtn.Font = Enum.Font.GothamBold
EditSaveBtn.ZIndex = 101
EditSaveBtn.Parent = EditFrame

local EditSaveCorner = Instance.new("UICorner")
EditSaveCorner.CornerRadius = UDim.new(0, 10)
EditSaveCorner.Parent = EditSaveBtn


local BlockedModal = Instance.new("Frame")
BlockedModal.Size = UDim2.new(1, 0, 1, 0)
BlockedModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlockedModal.BackgroundTransparency = 0.5
BlockedModal.BorderSizePixel = 0
BlockedModal.Visible = false
BlockedModal.ZIndex = 100
BlockedModal.Parent = MainFrame

local BlockedFrame = Instance.new("Frame")
BlockedFrame.Size = UDim2.new(0.92, 0, 0.7, 0)
BlockedFrame.Position = UDim2.new(0.04, 0, 0.15, 0)
BlockedFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
BlockedFrame.BorderSizePixel = 0
BlockedFrame.ZIndex = 101
BlockedFrame.Parent = BlockedModal

local BlockedFrameCorner = Instance.new("UICorner")
BlockedFrameCorner.CornerRadius = UDim.new(0, 16)
BlockedFrameCorner.Parent = BlockedFrame

local BlockedFrameStroke = Instance.new("UIStroke")
BlockedFrameStroke.Color = Color3.fromRGB(220, 70, 70)
BlockedFrameStroke.Thickness = 2
BlockedFrameStroke.Parent = BlockedFrame

local BlockedHeader = Instance.new("Frame")
BlockedHeader.Size = UDim2.new(1, 0, 0, 50)
BlockedHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
BlockedHeader.BorderSizePixel = 0
BlockedHeader.ZIndex = 101
BlockedHeader.Parent = BlockedFrame

local BlockedHeaderCorner = Instance.new("UICorner")
BlockedHeaderCorner.CornerRadius = UDim.new(0, 16)
BlockedHeaderCorner.Parent = BlockedHeader

local BlockedTitle = Instance.new("TextLabel")
BlockedTitle.Size = UDim2.new(1, -60, 1, 0)
BlockedTitle.Position = UDim2.new(0, 15, 0, 0)
BlockedTitle.BackgroundTransparency = 1
BlockedTitle.Text = "🚫 Blocked Remotes List"
BlockedTitle.TextColor3 = Color3.fromRGB(220, 70, 70)
BlockedTitle.TextSize = 18
BlockedTitle.Font = Enum.Font.GothamBold
BlockedTitle.TextXAlignment = Enum.TextXAlignment.Left
BlockedTitle.ZIndex = 101
BlockedTitle.Parent = BlockedHeader

local BlockedCloseBtn = Instance.new("TextButton")
BlockedCloseBtn.Size = UDim2.new(0, 40, 0, 40)
BlockedCloseBtn.Position = UDim2.new(1, -45, 0, 5)
BlockedCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
BlockedCloseBtn.BorderSizePixel = 0
BlockedCloseBtn.Text = "✕"
BlockedCloseBtn.TextColor3 = Color3.new(1, 1, 1)
BlockedCloseBtn.TextSize = 18
BlockedCloseBtn.Font = Enum.Font.GothamBold
BlockedCloseBtn.ZIndex = 101
BlockedCloseBtn.Parent = BlockedHeader

local BlockedCloseBtnCorner = Instance.new("UICorner")
BlockedCloseBtnCorner.CornerRadius = UDim.new(0, 8)
BlockedCloseBtnCorner.Parent = BlockedCloseBtn

local BlockedInfo = Instance.new("TextLabel")
BlockedInfo.Size = UDim2.new(1, -20, 0, 35)
BlockedInfo.Position = UDim2.new(0, 10, 0, 60)
BlockedInfo.BackgroundColor3 = Color3.fromRGB(220, 150, 50)
BlockedInfo.BorderSizePixel = 0
BlockedInfo.Text = "💡 Blocked remotes won't appear in the list"
BlockedInfo.TextColor3 = Color3.new(1, 1, 1)
BlockedInfo.TextSize = 11
BlockedInfo.Font = Enum.Font.Gotham
BlockedInfo.TextWrapped = true
BlockedInfo.ZIndex = 101
BlockedInfo.Parent = BlockedFrame

local BlockedInfoCorner = Instance.new("UICorner")
BlockedInfoCorner.CornerRadius = UDim.new(0, 8)
BlockedInfoCorner.Parent = BlockedInfo

local BlockedList = Instance.new("ScrollingFrame")
BlockedList.Size = UDim2.new(1, -20, 1, -160)
BlockedList.Position = UDim2.new(0, 10, 0, 105)
BlockedList.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
BlockedList.BorderSizePixel = 0
BlockedList.ScrollBarThickness = 4
BlockedList.ZIndex = 101
BlockedList.Parent = BlockedFrame

local BlockedListLayout = Instance.new("UIListLayout")
BlockedListLayout.Padding = UDim.new(0, 5)
BlockedListLayout.Parent = BlockedList

local ClearAllBlockedBtn = Instance.new("TextButton")
ClearAllBlockedBtn.Size = UDim2.new(1, -20, 0, 40)
ClearAllBlockedBtn.Position = UDim2.new(0, 10, 1, -50)
ClearAllBlockedBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
ClearAllBlockedBtn.BorderSizePixel = 0
ClearAllBlockedBtn.Text = "🗑️ UNBLOCK ALL REMOTES"
ClearAllBlockedBtn.TextColor3 = Color3.new(1, 1, 1)
ClearAllBlockedBtn.TextSize = 14
ClearAllBlockedBtn.Font = Enum.Font.GothamBold
ClearAllBlockedBtn.ZIndex = 101
ClearAllBlockedBtn.Parent = BlockedFrame

local ClearAllBlockedCorner = Instance.new("UICorner")
ClearAllBlockedCorner.CornerRadius = UDim.new(0, 10)
ClearAllBlockedCorner.Parent = ClearAllBlockedBtn



local function formatArgs(args)
    if not args or #args == 0 then return "No arguments" end
    local result = ""
    for i, arg in ipairs(args) do
        result = result .. string.format("[%d] %s\n", i, safeStringify(arg))
    end
    return result
end

local function parseEditedArgs(text)
    local args = {}
    for line in string.gmatch(text, "[^\n]+") do
        local match = string.match(line, "%%[%d+%]%s*(.+)") or string.match(line, "%[%d+%]%s*(.+)")
        if match then
            local num = tonumber(match)
            if num then
                table.insert(args, num)
            elseif match == "true" then
                table.insert(args, true)
            elseif match == "false" then
                table.insert(args, false)
            elseif string.match(match, "^Vector3%(") then
                local x, y, z = string.match(match, "Vector3%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)")
                if x then table.insert(args, Vector3.new(tonumber(x), tonumber(y), tonumber(z))) end
            elseif string.match(match, "^CFrame%(") then
                local x, y, z = string.match(match, "CFrame%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)")
                if x then table.insert(args, CFrame.new(tonumber(x), tonumber(y), tonumber(z))) end
            else
                table.insert(args, match)
            end
        end
    end
    return args
end

local function fireRemote(entry, customArgs)
    if not entry then 
        showNotification("❌ No entry selected", Color3.fromRGB(220, 70, 70), 2)
        return false 
    end
    
    local args = customArgs or entry.args
    local remote = findRemoteByPath(entry.path)
    
    if not remote then
        showNotification("❌ Remote not found: " .. entry.name, Color3.fromRGB(220, 70, 70), 3)
        return false
    end
    
    if not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
        showNotification("❌ Invalid remote object", Color3.fromRGB(220, 70, 70), 2)
        return false
    end
    
    local success, result = pcall(function()
        if entry.type == "Event" then
            remote:FireServer(unpack(args))
            return "Event fired"
        else
            return remote:InvokeServer(unpack(args))
        end
    end)
    
    if success then
        showNotification("✅ Remote fired successfully!", Color3.fromRGB(60, 200, 120), 2)
    else
        showNotification("❌ Error: " .. tostring(result), Color3.fromRGB(220, 70, 70), 3)
    end
    return success
end

local function updateCounter()
    local count = 0
    for _ in pairs(blockedRemotes) do count = count + 1 end
    Subtitle.Text = string.format("https://github.com/nxthxndev • %d Logs • %d Blocked", #remoteLog, count)
end

local function refreshBlockedList()
    for _, child in ipairs(BlockedList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for path, name in pairs(blockedRemotes) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 35)
        item.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        item.BorderSizePixel = 0
        item.Parent = BlockedList
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = item
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -45, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 11
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = item
        
        local unblock = Instance.new("TextButton")
        unblock.Size = UDim2.new(0, 30, 0, 25)
        unblock.Position = UDim2.new(1, -35, 0.5, -12.5)
        unblock.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
        unblock.Text = "✓"
        unblock.TextColor3 = Color3.new(1, 1, 1)
        unblock.Parent = item
        
        local uCorner = Instance.new("UICorner")
        uCorner.CornerRadius = UDim.new(0, 6)
        uCorner.Parent = unblock
        
        unblock.MouseButton1Click:Connect(function()
            blockedRemotes[path] = nil
            refreshBlockedList()
            updateCounter()
        end)
    end
    BlockedList.CanvasSize = UDim2.new(0, 0, 0, BlockedListLayout.AbsoluteContentSize.Y)
end

local function createRemoteItemUI(remoteName, remoteType, remotePath, entry)
    local Item = Instance.new("Frame")
    Item.Size = UDim2.new(1, -12, 0, 68)
    Item.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    Item.BorderSizePixel = 0
    Item.LayoutOrder = -math.floor(entry.time * 100)
    Item.Parent = RemoteList
    
    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 13)
    ItemCorner.Parent = Item
    
    local ItemStroke = Instance.new("UIStroke")
    ItemStroke.Color = Color3.fromRGB(45, 45, 55)
    ItemStroke.Thickness = 1
    ItemStroke.Transparency = 0.4
    ItemStroke.Parent = Item
    
    if config.enableNotifications and tick() - entry.time < 0.8 then
        ItemStroke.Color = Color3.fromRGB(255, 70, 150)
        ItemStroke.Thickness = 2
        ItemStroke.Transparency = 0
        task.delay(0.8, function()
            if Item and Item.Parent then
                ItemStroke.Color = Color3.fromRGB(45, 45, 55)
                ItemStroke.Thickness = 1
                ItemStroke.Transparency = 0.4
            end
        end)
    end
    
    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = Item
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -125, 0, 22)
    NameLabel.Position = UDim2.new(0, 12, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = remoteName
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Item
    
    local TypeBadge = Instance.new("Frame")
    TypeBadge.Size = UDim2.new(0, 58, 0, 22)
    TypeBadge.Position = UDim2.new(1, -65, 0, 8)
    TypeBadge.BackgroundColor3 = remoteType == "Event" and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(255, 140, 70)
    TypeBadge.BorderSizePixel = 0
    TypeBadge.Parent = Item
    
    local TypeCorner = Instance.new("UICorner")
    TypeCorner.CornerRadius = UDim.new(0, 6)
    TypeCorner.Parent = TypeBadge
    
    local TypeLabel = Instance.new("TextLabel")
    TypeLabel.Size = UDim2.new(1, 0, 1, 0)
    TypeLabel.BackgroundTransparency = 1
    TypeLabel.Text = remoteType == "Event" and "EVENT" or "FUNC"
    TypeLabel.TextColor3 = Color3.new(1, 1, 1)
    TypeLabel.TextSize = 10
    TypeLabel.Font = Enum.Font.GothamBold
    TypeLabel.Parent = TypeBadge
    
    local PathLabel = Instance.new("TextLabel")
    PathLabel.Size = UDim2.new(1, -48, 0, 15)
    PathLabel.Position = UDim2.new(0, 12, 0, 32)
    PathLabel.BackgroundTransparency = 1
    PathLabel.Text = "📍 " .. remotePath
    PathLabel.TextColor3 = Color3.fromRGB(130, 130, 155)
    PathLabel.TextSize = 9
    PathLabel.Font = Enum.Font.Gotham
    PathLabel.TextXAlignment = Enum.TextXAlignment.Left
    PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    PathLabel.Parent = Item
    
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(0, 85, 0, 15)
    TimeLabel.Position = UDim2.new(0, 12, 0, 49)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Text = "🕐 " .. os.date("%H:%M:%S", entry.time)
    TimeLabel.TextColor3 = Color3.fromRGB(110, 110, 135)
    TimeLabel.TextSize = 9
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.Parent = Item
    
    local ArgsCount = Instance.new("TextLabel")
    ArgsCount.Size = UDim2.new(0, 75, 0, 15)
    ArgsCount.Position = UDim2.new(0, 100, 0, 49)
    ArgsCount.BackgroundTransparency = 1
    ArgsCount.Text = "📦 " .. #entry.args .. " args"
    ArgsCount.TextColor3 = Color3.fromRGB(110, 110, 135)
    ArgsCount.TextSize = 9
    ArgsCount.Font = Enum.Font.Gotham
    ArgsCount.TextXAlignment = Enum.TextXAlignment.Left
    ArgsCount.Parent = Item
    
    local ReplayQuickBtn = Instance.new("TextButton")
    ReplayQuickBtn.Size = UDim2.new(0, 32, 0, 32)
    ReplayQuickBtn.Position = UDim2.new(1, -38, 0.5, -16)
    ReplayQuickBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    ReplayQuickBtn.BorderSizePixel = 0
    ReplayQuickBtn.Text = "▶"
    ReplayQuickBtn.TextColor3 = Color3.new(1, 1, 1)
    ReplayQuickBtn.TextSize = 14
    ReplayQuickBtn.Font = Enum.Font.GothamBold
    ReplayQuickBtn.ZIndex = 2
    ReplayQuickBtn.Parent = Item
    
    local ReplayCorner = Instance.new("UICorner")
    ReplayCorner.CornerRadius = UDim.new(0, 8)
    ReplayCorner.Parent = ReplayQuickBtn
    
    local ReplayStroke = Instance.new("UIStroke")
    ReplayStroke.Color = Color3.new(1, 1, 1)
    ReplayStroke.Thickness = 1
    ReplayStroke.Transparency = 0.8
    ReplayStroke.Parent = ReplayQuickBtn
    
    ReplayQuickBtn.MouseButton1Click:Connect(function()
        fireRemote(entry)
    end)
    
    ClickBtn.MouseButton1Click:Connect(function()
        selectedEntry = entry
        
        for _, child in ipairs(RemoteList:GetChildren()) do
            if child:IsA("Frame") then
                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then
                    stroke.Color = Color3.fromRGB(45, 45, 55)
                    stroke.Thickness = 1
                    stroke.Transparency = 0.4
                end
            end
        end
        
        ItemStroke.Color = Color3.fromRGB(100, 150, 255)
        ItemStroke.Thickness = 2
        ItemStroke.Transparency = 0
        
        local details = string.format(
            "━━━━━━━━━━━━━━━━━━━━━━━━━\n📋 REMOTE DETAILS\n━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" ..
            "🔹 Name: %s\n" ..
            "📦 Type: %s\n" ..
            "📍 Path: %s\n" ..
            "🕐 Time: %s\n\n" ..
            "━━━━━━━━━━━━━━━━━━━━━━━━━\n📝 ARGUMENTS (%d)\n━━━━━━━━━━━━━━━━━━━━━━━━━\n\n%s\n" ..
            "━━━━━━━━━━━━━━━━━━━━━━━━━\n💡 TIP: Use buttons below",
            entry.name, 
            entry.type, 
            entry.path,
            os.date("%H:%M:%S", entry.time),
            #entry.args,
            formatArgs(entry.args)
        )
        
        DetailsText.Text = details
        DetailsPanel.CanvasSize = UDim2.new(0, 0, 0, DetailsText.TextBounds.Y + 20)
    end)
    
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end

local function refreshList()
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, entry in ipairs(remoteLog) do
        if not blockedRemotes[entry.path] and
           (filterType == "All" or entry.type == filterType) and
           (filterText == "" or string.find(string.lower(entry.name), string.lower(filterText))) then
            pcall(createRemoteItemUI, entry.name, entry.type, entry.path, entry)
        end
    end
end

local function queueRemoteCapture(remoteName, remoteType, args, remotePath, remoteObj)
    if blockedRemotes[remotePath] then return end
    local lp = remotePath:lower()
    if string.find(lp, "analytics") or string.find(lp, "telemetry") or string.find(lp, "bugreport") then return end
    local lowerPath = remotePath:lower()
    if string.find(lowerPath, "analytics") or string.find(lowerPath, "telemetry") or string.find(lowerPath, "bugreport") then return end
    
    for i = 1, math.min(3, #remoteLog) do
        if remoteLog[i] and remoteLog[i].path == remotePath and tick() - remoteLog[i].time < config.deduplicateTime then
            return
        end
    end
    
    storeRemote(remotePath, remoteObj)
    
    local entry = {
        name = remoteName,
        type = remoteType,
        args = deepCopy(args),
        path = remotePath,
        time = tick()
    }
    
    table.insert(remoteLog, 1, entry)
    if #remoteLog > config.maxLogs then
        table.remove(remoteLog, #remoteLog)
    end
    
    table.insert(uiQueue, {remoteName, remoteType, remotePath, entry})
    updateCounter()
end

RunService.Heartbeat:Connect(function()
    if #uiQueue > 0 then
        local data = table.remove(uiQueue, 1)
        if not blockedRemotes[data[3]] and
           (filterType == "All" or data[2] == filterType) and
           (filterText == "" or string.find(string.lower(data[1]), string.lower(filterText))) then
            pcall(createRemoteItemUI, data[1], data[2], data[3], data[4])
        end
    end
end)

if hasHook then
    local oldNamecall
    oldNamecall = _hookmetamethod(game, "__namecall", _newcclosure(function(self, ...)
        local method = _getnamecallmethod()
        local args = {...}
        
        
        if not _checkcaller() and (method == "FireServer" or method == "InvokeServer") and isCapturing then
            task.spawn(function()
                local rPath = ""
                local s, e = pcall(function() rPath = self:GetFullName() end)
                if s and rPath ~= "" then
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        queueRemoteCapture(tostring(self.Name), self:IsA("RemoteEvent") and "Event" or "Function", args, rPath, self)
                    end
                end
            end)
        end
        
        
        return oldNamecall(self, ...)
    end))
else
    showNotification("⚠️ Hooking not supported", Color3.fromRGB(255, 180, 50), 3)
end



local function toggleMinimize()
    isMinimized = not isMinimized
    MainFrame.Visible = not isMinimized
    MinButton.Visible = isMinimized
    
    if isMinimized then
        showNotification("📡 Spy minimized", Color3.fromRGB(100, 100, 120), 1.5)
    end
end

HideBtn.MouseButton1Click:Connect(toggleMinimize)
MinButton.MouseButton1Click:Connect(toggleMinimize)

CaptureBtn.MouseButton1Click:Connect(function()
    isCapturing = not isCapturing
    
    if isCapturing then
        CaptureBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
        CaptureBtn:FindFirstChild("TextLabel").Text = "PAUSE"
        StatusLabel.Text = "● ACTIVE"
        StatusBadge.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
        showNotification("✅ Capture activated", Color3.fromRGB(60, 200, 120), 1.5)
    else
        CaptureBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        CaptureBtn:FindFirstChild("TextLabel").Text = "RESUME"
        StatusLabel.Text = "● PAUSED"
        StatusBadge.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        showNotification("⏸️ Capture paused", Color3.fromRGB(150, 150, 150), 1.5)
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    remoteLog = {}
    remoteCache = {}
    uiQueue = {}
    
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    selectedEntry = nil
    DetailsText.Text = "💡 Logs cleared!\n\n🎯 Ready to capture new remotes..."
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
    updateCounter()
    showNotification("🗑️ All logs cleared", Color3.fromRGB(220, 70, 70), 2)
end)

ReplayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then
        showNotification("⚠️ Select a remote first!", Color3.fromRGB(255, 180, 50), 2)
        return
    end
    fireRemote(selectedEntry)
end)

EditBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then
        showNotification("⚠️ Select a remote first!", Color3.fromRGB(255, 180, 50), 2)
        return
    end
    
    EditArgsBox.Text = formatArgs(selectedEntry.args)
    EditModal.Visible = true
end)

BlockBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then
        showNotification("⚠️ Select a remote first!", Color3.fromRGB(255, 180, 50), 2)
        return
    end
    
    blockedRemotes[selectedEntry.path] = selectedEntry.name
    
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    refreshList()
    updateCounter()
    selectedEntry = nil
    DetailsText.Text = "💡 Remote blocked!\n\n🚫 It won't appear anymore"
    showNotification("🚫 Remote blocked from display!", Color3.fromRGB(220, 70, 70), 2)
end)

EditSaveBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    
    local newArgs = parseEditedArgs(EditArgsBox.Text)
    
    if #newArgs > 0 then
        EditModal.Visible = false
        task.wait(0.1)
        fireRemote(selectedEntry, newArgs)
    else
        showNotification("⚠️ Invalid arguments format!", Color3.fromRGB(255, 180, 50), 2)
    end
end)

EditCloseBtn.MouseButton1Click:Connect(function()
    EditModal.Visible = false
end)

BlockedListBtn.MouseButton1Click:Connect(function()
    refreshBlockedList()
    BlockedModal.Visible = true
end)

BlockedCloseBtn.MouseButton1Click:Connect(function()
    BlockedModal.Visible = false
end)

ClearAllBlockedBtn.MouseButton1Click:Connect(function()
    blockedRemotes = {}
    refreshBlockedList()
    refreshList()
    updateCounter()
    showNotification("✅ All remotes unblocked!", Color3.fromRGB(60, 200, 120), 2)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterText = SearchBox.Text
    ClearSearchBtn.Visible = filterText ~= ""
    refreshList()
    updateCounter()
end)

ClearSearchBtn.MouseButton1Click:Connect(function()
    SearchBox.Text = ""
    filterText = ""
    ClearSearchBtn.Visible = false
    refreshList()
    updateCounter()
end)

local function updateFilterButtons(activeBtn)
    for _, btn in ipairs({FilterAllBtn, FilterEventBtn, FilterFuncBtn}) do
        if btn == activeBtn then
            btn.BackgroundColor3 = Color3.fromRGB(255, 70, 150)
            btn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(255, 100, 170)
            btn:FindFirstChildOfClass("UIStroke").Thickness = 2
        else
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            btn:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(50, 50, 60)
            btn:FindFirstChildOfClass("UIStroke").Thickness = 1
        end
    end
end

FilterAllBtn.MouseButton1Click:Connect(function()
    filterType = "All"
    updateFilterButtons(FilterAllBtn)
    refreshList()
    updateCounter()
end)

FilterEventBtn.MouseButton1Click:Connect(function()
    filterType = "Event"
    updateFilterButtons(FilterEventBtn)
    refreshList()
    updateCounter()
end)

FilterFuncBtn.MouseButton1Click:Connect(function()
    filterType = "Function"
    updateFilterButtons(FilterFuncBtn)
    refreshList()
    updateCounter()
end)

local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(MainFrame, Header)
makeDraggable(MinButton, MinButton)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔥 REMOTESPY V 1.0.4 - LOADED")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Hook: " .. (hasHook and "Active" or "Disabled"))
print("✅ Max logs: " .. config.maxLogs)
print("✅ Features: Replay, Edit, Block, Filters")
print("✅ Interface: Optimized & Aligned")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

showNotification("🔥 Remote Spy OK", Color3.fromRGB(100, 255, 150), 2.5)
updateCounter()
