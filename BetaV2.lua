-- 🔥 ULTIMATE REMOTE CONTROLLER - FIXED VERSION
-- Capture garantie des remotes avec méthode multiple

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Variables globales
local remoteLog = {}
local selectedRemote = nil
local isCapturing = true
local blockedRemotes = {}
local repeatFiring = {}
local remoteObjects = {}
local logToConsole = false

-- Fonctions utilitaires
local function deepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for k, v in next, original, nil do
            copy[deepCopy(k)] = deepCopy(v)
        end
        setmetatable(copy, deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

local function safeStringify(value, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    
    local t = typeof(value)
    if t == "table" then
        local s = "{ "
        pcall(function()
            for k, v in pairs(value) do
                s = s .. tostring(k) .. " = " .. safeStringify(v, depth + 1) .. ", "
            end
        end)
        return s .. "}"
    elseif t == "Instance" then
        local success, fullname = pcall(function() return value:GetFullName() end)
        return success and fullname or tostring(value)
    else
        return tostring(value)
    end
end

local function safeGetFullName(instance)
    local success, result = pcall(function()
        return instance:GetFullName()
    end)
    return success and result or tostring(instance)
end

-- UI Creation (simplified for space)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimateRemoteController"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 1100, 0, 700)
MainFrame.Position = UDim2.new(0.5, -550, 0.5, -350)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 50, 150)
MainStroke.Thickness = 3
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 20)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 400, 1, 0)
Title.Position = UDim2.new(0, 25, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ ULTIMATE REMOTE SPY"
Title.TextColor3 = Color3.fromRGB(255, 50, 150)
Title.TextSize = 28
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(0, 250, 0, 50)
StatsFrame.Position = UDim2.new(1, -270, 0, 10)
StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
StatsFrame.BorderSizePixel = 0
StatsFrame.Parent = Header

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 10)
StatsCorner.Parent = StatsFrame

local CapturedLabel = Instance.new("TextLabel")
CapturedLabel.Size = UDim2.new(0.5, 0, 1, 0)
CapturedLabel.BackgroundTransparency = 1
CapturedLabel.Text = "📊 0 Captured"
CapturedLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
CapturedLabel.TextSize = 14
CapturedLabel.Font = Enum.Font.GothamBold
CapturedLabel.Parent = StatsFrame

local BlockedLabel = Instance.new("TextLabel")
BlockedLabel.Size = UDim2.new(0.5, 0, 1, 0)
BlockedLabel.Position = UDim2.new(0.5, 0, 0, 0)
BlockedLabel.BackgroundTransparency = 1
BlockedLabel.Text = "🚫 0 Blocked"
BlockedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
BlockedLabel.TextSize = 14
BlockedLabel.Font = Enum.Font.GothamBold
BlockedLabel.Parent = StatsFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 45, 0, 45)
CloseBtn.Position = UDim2.new(1, -60, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 24
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 10)
CloseBtnCorner.Parent = CloseBtn

-- Container
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -40, 1, -110)
Container.Position = UDim2.new(0, 20, 0, 80)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

-- Left Panel
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.4, -10, 1, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = Container

local LeftCorner = Instance.new("UICorner")
LeftCorner.CornerRadius = UDim.new(0, 15)
LeftCorner.Parent = LeftPanel

-- Toolbar
local Toolbar = Instance.new("Frame")
Toolbar.Size = UDim2.new(1, 0, 0, 55)
Toolbar.BackgroundTransparency = 1
Toolbar.Parent = LeftPanel

local function createToolbarButton(text, position, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 95, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = Toolbar
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    return btn
end

local CaptureBtn = createToolbarButton("🔴 SPY ON", UDim2.new(0, 10, 0, 7), Color3.fromRGB(60, 220, 120))
local ClearBtn = createToolbarButton("🗑️ CLEAR", UDim2.new(0, 115, 0, 7), Color3.fromRGB(220, 60, 60))
local ExportBtn = createToolbarButton("💾 EXPORT", UDim2.new(0, 220, 0, 7), Color3.fromRGB(100, 150, 255))

-- Remote List
local RemoteList = Instance.new("ScrollingFrame")
RemoteList.Size = UDim2.new(1, -20, 1, -65)
RemoteList.Position = UDim2.new(0, 10, 0, 60)
RemoteList.BackgroundTransparency = 1
RemoteList.BorderSizePixel = 0
RemoteList.ScrollBarThickness = 5
RemoteList.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 150)
RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
RemoteList.Parent = LeftPanel

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = RemoteList

-- Right Panel
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.6, -10, 1, 0)
RightPanel.Position = UDim2.new(0.4, 10, 0, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = Container

local RightCorner = Instance.new("UICorner")
RightCorner.CornerRadius = UDim.new(0, 15)
RightCorner.Parent = RightPanel

-- Details Content
local DetailsContent = Instance.new("ScrollingFrame")
DetailsContent.Size = UDim2.new(1, -20, 1, -20)
DetailsContent.Position = UDim2.new(0, 10, 0, 10)
DetailsContent.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
DetailsContent.BorderSizePixel = 0
DetailsContent.ScrollBarThickness = 5
DetailsContent.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 150)
DetailsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
DetailsContent.Parent = RightPanel

local DetailsCorner = Instance.new("UICorner")
DetailsCorner.CornerRadius = UDim.new(0, 12)
DetailsCorner.Parent = DetailsContent

local DetailsText = Instance.new("TextLabel")
DetailsText.Size = UDim2.new(1, -20, 1, 0)
DetailsText.Position = UDim2.new(0, 10, 0, 10)
DetailsText.BackgroundTransparency = 1
DetailsText.Text = "🎯 Waiting for remote calls...\n\n💡 TIP: Interact with the game to capture remotes!"
DetailsText.TextColor3 = Color3.fromRGB(200, 200, 220)
DetailsText.TextSize = 13
DetailsText.Font = Enum.Font.Code
DetailsText.TextWrapped = true
DetailsText.TextYAlignment = Enum.TextYAlignment.Top
DetailsText.TextXAlignment = Enum.TextXAlignment.Left
DetailsText.Parent = DetailsContent

-- Functions
local function updateStats()
    CapturedLabel.Text = "📊 " .. #remoteLog .. " Captured"
    local blockedCount = 0
    for _ in pairs(blockedRemotes) do blockedCount = blockedCount + 1 end
    BlockedLabel.Text = "🚫 " .. blockedCount .. " Blocked"
end

local function formatArgs(args)
    if not args or #args == 0 then return "No arguments" end
    local formatted = ""
    for i, arg in ipairs(args) do
        formatted = formatted .. string.format("[%d] (%s) %s\n", i, typeof(arg), safeStringify(arg))
    end
    return formatted
end

local function addRemoteToList(remoteName, remoteType, args, remotePath, remoteObject)
    -- Vérifier si déjà ajouté récemment (éviter doublons)
    for i = 1, math.min(5, #remoteLog) do
        local entry = remoteLog[i]
        if entry.path == remotePath and os.time() - entry.timestamp < 1 then
            return -- Ignorer si trop récent
        end
    end
    
    local entry = {
        name = remoteName,
        type = remoteType,
        args = deepCopy(args),
        path = remotePath,
        object = remoteObject,
        timestamp = os.time(),
        id = #remoteLog + 1
    }
    table.insert(remoteLog, 1, entry)
    remoteObjects[remotePath] = remoteObject
    
    local RemoteItem = Instance.new("Frame")
    RemoteItem.Size = UDim2.new(1, -10, 0, 85)
    RemoteItem.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    RemoteItem.BorderSizePixel = 0
    RemoteItem.Parent = RemoteList
    
    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 12)
    ItemCorner.Parent = RemoteItem
    
    local ItemStroke = Instance.new("UIStroke")
    ItemStroke.Color = remoteType == "Event" and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 150, 50)
    ItemStroke.Thickness = 2
    ItemStroke.Transparency = 0.5
    ItemStroke.Parent = RemoteItem
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -75, 0, 25)
    NameLabel.Position = UDim2.new(0, 12, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = "🔹 " .. remoteName
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 15
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = RemoteItem
    
    local TypeBadge = Instance.new("TextLabel")
    TypeBadge.Size = UDim2.new(0, 65, 0, 22)
    TypeBadge.Position = UDim2.new(1, -70, 0, 10)
    TypeBadge.BackgroundColor3 = remoteType == "Event" and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(255, 120, 50)
    TypeBadge.Text = remoteType
    TypeBadge.TextColor3 = Color3.new(1, 1, 1)
    TypeBadge.TextSize = 11
    TypeBadge.Font = Enum.Font.GothamBold
    TypeBadge.BorderSizePixel = 0
    TypeBadge.Parent = RemoteItem
    
    local TypeBadgeCorner = Instance.new("UICorner")
    TypeBadgeCorner.CornerRadius = UDim.new(0, 6)
    TypeBadgeCorner.Parent = TypeBadge
    
    local PathLabel = Instance.new("TextLabel")
    PathLabel.Size = UDim2.new(1, -75, 0, 18)
    PathLabel.Position = UDim2.new(0, 12, 0, 35)
    PathLabel.BackgroundTransparency = 1
    PathLabel.Text = "📍 " .. remotePath
    PathLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    PathLabel.TextSize = 11
    PathLabel.Font = Enum.Font.Gotham
    PathLabel.TextXAlignment = Enum.TextXAlignment.Left
    PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    PathLabel.Parent = RemoteItem
    
    local ArgsLabel = Instance.new("TextLabel")
    ArgsLabel.Size = UDim2.new(0.5, 0, 0, 18)
    ArgsLabel.Position = UDim2.new(0, 12, 0, 55)
    ArgsLabel.BackgroundTransparency = 1
    ArgsLabel.Text = "📦 Args: " .. #args
    ArgsLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    ArgsLabel.TextSize = 11
    ArgsLabel.Font = Enum.Font.GothamMedium
    ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgsLabel.Parent = RemoteItem
    
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(0.5, -12, 0, 18)
    TimeLabel.Position = UDim2.new(0.5, 0, 0, 55)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Text = "⏰ " .. os.date("%H:%M:%S", entry.timestamp)
    TimeLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    TimeLabel.TextSize = 11
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.Parent = RemoteItem
    
    local SelectBtn = Instance.new("TextButton")
    SelectBtn.Size = UDim2.new(1, 0, 1, 0)
    SelectBtn.BackgroundTransparency = 1
    SelectBtn.Text = ""
    SelectBtn.Parent = RemoteItem
    
    SelectBtn.MouseButton1Click:Connect(function()
        selectedRemote = entry
        
        for _, item in ipairs(RemoteList:GetChildren()) do
            if item:IsA("Frame") then
                TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 35)}):Play()
            end
        end
        
        TweenService:Create(RemoteItem, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
        
        local details = string.format(
            "🎯 REMOTE NAME: %s\n⚙️ TYPE: %s\n📍 FULL PATH: %s\n⏰ TIMESTAMP: %s\n🆔 CALL ID: #%d\n\n📦 ARGUMENTS:\n%s",
            entry.name,
            entry.type,
            entry.path,
            os.date("%H:%M:%S", entry.timestamp),
            entry.id,
            formatArgs(entry.args)
        )
        DetailsText.Text = details
        DetailsContent.CanvasSize = UDim2.new(0, 0, 0, DetailsText.TextBounds.Y + 30)
    end)
    
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    updateStats()
end

-- TRIPLE HOOK METHOD - Garantit la capture
local capturedRemotes = {}

-- Method 1: __namecall hook
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if method == "FireServer" or method == "InvokeServer" then
        task.spawn(function()
            pcall(function()
                if (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) and isCapturing then
                    local remoteType = self:IsA("RemoteEvent") and "Event" or "Function"
                    local remotePath = safeGetFullName(self)
                    local remoteName = self.Name
                    
                    if not capturedRemotes[remotePath] then
                        capturedRemotes[remotePath] = true
                        addRemoteToList(remoteName, remoteType, args, remotePath, self)
                        
                        if logToConsole then
                            print("📡 [CAPTURED via __namecall]", remotePath)
                        end
                    end
                end
            end)
        end)
    end
    
    return oldNamecall(self, ...)
end)

-- Method 2: __index hook (backup)
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    local value = oldIndex(self, key)
    
    if (key == "FireServer" or key == "InvokeServer") and typeof(value) == "function" then
        return function(...)
            task.spawn(function()
                pcall(function()
                    if (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) and isCapturing then
                        local args = {...}
                        local remoteType = self:IsA("RemoteEvent") and "Event" or "Function"
                        local remotePath = safeGetFullName(self)
                        local remoteName = self.Name
                        
                        if not capturedRemotes[remotePath] then
                            capturedRemotes[remotePath] = true
                            addRemoteToList(remoteName, remoteType, args, remotePath, self)
                            
                            if logToConsole then
                                print("📡 [CAPTURED via __index]", remotePath)
                            end
                        end
                    end
                end)
            end)
            
            return value(...)
        end
    end
    
    return value
end)

-- Method 3: Direct scan on load
task.spawn(function()
    wait(2) -- Attendre que le jeu charge
    
    local function scanForRemotes()
        for _, descendant in ipairs(game:GetDescendants()) do
            pcall(function()
                if (descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction")) then
                    local remoteType = descendant:IsA("RemoteEvent") and "Event" or "Function"
                    local remotePath = safeGetFullName(descendant)
                    
                    if not capturedRemotes[remotePath] then
                        capturedRemotes[remotePath] = true
                        addRemoteToList(descendant.Name, remoteType, {}, remotePath, descendant)
                    end
                end
            end)
        end
    end
    
    scanForRemotes()
    
    -- Re-scan toutes les 10 secondes
    while true do
        wait(10)
        scanForRemotes()
    end
end)

-- Button events
CaptureBtn.MouseButton1Click:Connect(function()
    isCapturing = not isCapturing
    CaptureBtn.Text = isCapturing and "🔴 SPY ON" or "⏸️ PAUSED"
    CaptureBtn.BackgroundColor3 = isCapturing and Color3.fromRGB(60, 220, 120) or Color3.fromRGB(150, 150, 150)
end)

ClearBtn.MouseButton1Click:Connect(function()
    remoteLog = {}
    capturedRemotes = {}
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    selectedRemote = nil
    DetailsText.Text = "🎯 Log cleared! Waiting for new remotes..."
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
    updateStats()
end)

ExportBtn.MouseButton1Click:Connect(function()
    local export = "-- REMOTE SPY EXPORT --\n-- Total captured: " .. #remoteLog .. "\n\n"
    for i, entry in ipairs(remoteLog) do
        local success, encoded = pcall(function() return HttpService:JSONEncode(entry.args) end)
        export = export .. string.format(
            "-- [%d] %s (%s)\n-- Path: %s\n-- Args: %s\n\n",
            i, entry.name, entry.type, entry.path,
            success and encoded or "[]"
        )
    end
    setclipboard(export)
    ExportBtn.Text = "✅ COPIED"
    task.wait(2)
    ExportBtn.Text = "💾 EXPORT"
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Draggable
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Notification
print("🔥 ULTIMATE REMOTE SPY LOADED!")
print("✅ Triple hook method active")
print("⚡ Auto-scanning every 10 seconds")
print("💡 TIP: Interact with the game to capture remotes!")

-- Message dans l'interface
task.spawn(function()
    wait(3)
    if #remoteLog == 0 then
        DetailsText.Text = "⚠️ No remotes captured yet!\n\n💡 TIPS:\n• Try interacting with the game\n• Click buttons, open menus, etc.\n• Some games use delayed remotes\n• Auto-scan is running in background"
    end
end)
