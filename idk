-- 🔥 ULTIMATE MOBILE REMOTE SPY - ELITE EDITION
-- ✅ Interface Ultra Moderne & Clean
-- ✅ Optimisation Mobile Maximale
-- ✅ Système de Blocage Intelligent (Anti-Spam)
-- ✅ Replay & Edition d'Arguments

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Services & Variables
local LocalPlayer = Players.LocalPlayer
local GuiParent = (function()
    local success, coreGui = pcall(game.GetService, game, "CoreGui")
    return success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
end)()

-- Vérifications UNC
local hasHook = hookmetamethod ~= nil
local getNamecall = getnamecallmethod or function() return "" end
local checkCaller = checkcaller or function() return false end
local newCC = newcclosure or function(f) return f end

-- Variables globales
local remoteLog = {}
local remoteCache = {}
local isCapturing = true
local selectedEntry = nil
local isMinimized = false
local filterText = ""
local filterType = "All"
local favorites = {}
local blockedRemotes = {} -- Liste des remotes bloqués
local remoteStats = {} -- Pour détecter le spam

-- Configuration
local config = {
    maxLogs = 500,
    deduplicateTime = 0.05,
    enableNotifications = true,
    animationSpeed = 0.3,
    accentColor = Color3.fromRGB(0, 170, 255), -- Bleu moderne
    bgColor = Color3.fromRGB(10, 10, 12),
    secondaryColor = Color3.fromRGB(20, 20, 25),
    spamThreshold = 10 -- Nombre d'appels par seconde pour alerter
}

-- === UTILITAIRES ===
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

-- === CRÉATION UI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EliteRemoteSpy_" .. math.random(10000, 99999)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = GuiParent

-- Notification moderne
local function showNotification(text, color, duration)
    if not config.enableNotifications then return end
    duration = duration or 2
    
    task.spawn(function()
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 260, 0, 50)
        notif.Position = UDim2.new(0.5, -130, 0, -60)
        notif.BackgroundColor3 = config.secondaryColor
        notif.BorderSizePixel = 0
        notif.ZIndex = 1000
        notif.Parent = ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = notif
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = color or config.accentColor
        stroke.Thickness = 2
        stroke.Parent = notif
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 14
        label.Font = Enum.Font.GothamMedium
        label.TextWrapped = true
        label.Parent = notif
        
        TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -130, 0, 40)}):Play()
        task.wait(duration)
        TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -130, 0, -60)}):Play()
        task.wait(0.4)
        notif:Destroy()
    end)
end

-- Bouton minimisé (Flottant)
local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.new(0, 60, 0, 60)
MinButton.Position = UDim2.new(0, 20, 0.5, -30)
MinButton.BackgroundColor3 = config.accentColor
MinButton.Text = "📡"
MinButton.TextSize = 24
MinButton.TextColor3 = Color3.new(1, 1, 1)
MinButton.Visible = false
MinButton.ZIndex = 500
MinButton.Parent = ScreenGui

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinButton

local MinStroke = Instance.new("UIStroke")
MinStroke.Color = Color3.new(1, 1, 1)
MinStroke.Transparency = 0.8
MinStroke.Thickness = 2
MinStroke.Parent = MinButton

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 550)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -275)
MainFrame.BackgroundColor3 = config.bgColor
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 24)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = config.accentColor
MainStroke.Thickness = 2
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = config.secondaryColor
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 24)
HeaderCorner.Parent = Header

-- Cache pour arrondir seulement le haut
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 20)
HeaderFix.Position = UDim2.new(0, 0, 1, -20)
HeaderFix.BackgroundColor3 = config.secondaryColor
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "REMOTE SPY <font color='#00AAFF'>ELITE</font>"
Title.RichText = true
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -50, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 32
CloseBtn.Font = Enum.Font.GothamLight
CloseBtn.Parent = Header

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 40, 0, 40)
ClearBtn.Position = UDim2.new(1, -95, 0, 10)
ClearBtn.BackgroundTransparency = 1
ClearBtn.Text = "🗑️"
ClearBtn.TextColor3 = Color3.new(1, 1, 1)
ClearBtn.TextSize = 18
ClearBtn.Parent = Header

ClearBtn.MouseButton1Click:Connect(function()
    remoteLog = {}
    refreshDisplay()
    showNotification("Logs vidés !", config.accentColor)
end)

-- Conteneur Principal (Scrollable)
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, 0, 1, -60)
Content.Position = UDim2.new(0, 0, 0, 60)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 2
Content.ScrollBarImageColor3 = config.accentColor
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = Content

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 15)
UIPadding.PaddingBottom = UDim.new(0, 15)
UIPadding.Parent = Content

-- Barre de recherche & Filtres
local Controls = Instance.new("Frame")
Controls.Size = UDim2.new(0.9, 0, 0, 80)
Controls.BackgroundColor3 = config.secondaryColor
Controls.LayoutOrder = -10
Controls.Parent = Content

local ControlsCorner = Instance.new("UICorner")
ControlsCorner.CornerRadius = UDim.new(0, 12)
ControlsCorner.Parent = Controls

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -40, 0, 35)
SearchBox.Position = UDim2.new(0, 15, 0, 5)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Rechercher un remote..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
SearchBox.TextSize = 14
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.Parent = Controls

local FilterContainer = Instance.new("Frame")
FilterContainer.Size = UDim2.new(1, -20, 0, 30)
FilterContainer.Position = UDim2.new(0, 10, 0, 40)
FilterContainer.BackgroundTransparency = 1
FilterContainer.Parent = Controls

local FilterList = Instance.new("UIListLayout")
FilterList.FillDirection = Enum.FillDirection.Horizontal
FilterList.Padding = UDim.new(0, 8)
FilterList.Parent = FilterContainer

local function createFilterBtn(text, type)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 1, 0)
    btn.BackgroundColor3 = config.bgColor
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = FilterContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        filterType = type
        for _, b in ipairs(FilterContainer:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = config.bgColor end
        end
        btn.BackgroundColor3 = config.accentColor
        refreshDisplay()
    end)
end

createFilterBtn("TOUT", "All")
createFilterBtn("EVENTS", "Event")
createFilterBtn("FUNCS", "Function")

-- Section Statistiques & Blocage
local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(0.9, 0, 0, 80)
StatsFrame.BackgroundColor3 = config.secondaryColor
StatsFrame.LayoutOrder = -9
StatsFrame.Parent = Content

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 12)
StatsCorner.Parent = StatsFrame

local StatsTitle = Instance.new("TextLabel")
StatsTitle.Size = UDim2.new(1, -20, 0, 30)
StatsTitle.Position = UDim2.new(0, 10, 0, 5)
StatsTitle.BackgroundTransparency = 1
StatsTitle.Text = "🛡️ PROTECTION ANTI-SPAM"
StatsTitle.TextColor3 = config.accentColor
StatsTitle.TextSize = 12
StatsTitle.Font = Enum.Font.GothamBold
StatsTitle.TextXAlignment = Enum.TextXAlignment.Left
StatsTitle.Parent = StatsFrame

local BlockInfo = Instance.new("TextLabel")
BlockInfo.Size = UDim2.new(1, -20, 0, 40)
BlockInfo.Position = UDim2.new(0, 10, 0, 35)
BlockInfo.BackgroundTransparency = 1
BlockInfo.Text = "Remotes bloqués: 0\nDétection de spam active"
BlockInfo.TextColor3 = Color3.fromRGB(180, 180, 190)
BlockInfo.TextSize = 11
BlockInfo.Font = Enum.Font.Gotham
BlockInfo.TextXAlignment = Enum.TextXAlignment.Left
BlockInfo.Parent = StatsFrame

-- Liste des Logs
local LogContainer = Instance.new("Frame")
LogContainer.Size = UDim2.new(0.9, 0, 0, 300)
LogContainer.BackgroundTransparency = 1
LogContainer.LayoutOrder = 1
LogContainer.Parent = Content

local LogList = Instance.new("UIListLayout")
LogList.SortOrder = Enum.SortOrder.LayoutOrder
LogList.Padding = UDim.new(0, 8)
LogList.Parent = LogContainer

-- === LOGIQUE DE BLOCAGE & FILTRAGE ===
local function refreshDisplay()
    for _, child in ipairs(LogContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local count = 0
    for _, entry in ipairs(remoteLog) do
        if (filterType == "All" or entry.type == filterType) and
           (filterText == "" or string.find(string.lower(entry.name), string.lower(filterText))) then
            createLogItem(entry)
            count = count + 1
        end
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterText = SearchBox.Text
    refreshDisplay()
end)

local function toggleBlockRemote(path)
    if blockedRemotes[path] then
        blockedRemotes[path] = nil
        showNotification("🔓 Débloqué: " .. path:match("[^%.]+$"), Color3.fromRGB(100, 255, 100))
    else
        blockedRemotes[path] = true
        showNotification("🚫 Bloqué: " .. path:match("[^%.]+$"), Color3.fromRGB(255, 100, 100))
    end
    
    local count = 0
    for _ in pairs(blockedRemotes) do count = count + 1 end
    BlockInfo.Text = string.format("Remotes bloqués: %d\nDétection de spam active", count)
    refreshDisplay()
end

-- === HOOKING ===
local function onRemoteCalled(remote, args, type)
    if not isCapturing then return end
    
    local path = remote:GetFullName()
    if blockedRemotes[path] then return end
    
    -- Détection de spam
    remoteStats[path] = (remoteStats[path] or 0) + 1
    task.delay(1, function()
        remoteStats[path] = remoteStats[path] - 1
    end)
    
    if remoteStats[path] > config.spamThreshold then
        if not blockedRemotes[path] then
            showNotification("⚠️ Spam détecté: " .. remote.Name, Color3.fromRGB(255, 150, 0))
            -- Optionnel: auto-block si trop de spam
            -- toggleBlockRemote(path)
        end
    end

    local entry = {
        name = remote.Name,
        path = path,
        args = deepCopy(args),
        time = tick(),
        type = type,
        remote = remote
    }
    
    table.insert(remoteLog, 1, entry)
    if #remoteLog > config.maxLogs then
        table.remove(remoteLog)
    end
    
    createLogItem(entry)
end

-- Création d'un item de log
function createLogItem(entry)
    local Item = Instance.new("Frame")
    Item.Size = UDim2.new(1, 0, 0, 70)
    Item.BackgroundColor3 = config.secondaryColor
    Item.BorderSizePixel = 0
    Item.Parent = LogContainer
    
    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 12)
    ItemCorner.Parent = Item
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -100, 0, 25)
    NameLabel.Position = UDim2.new(0, 15, 0, 10)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = entry.name
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Item
    
    local TypeLabel = Instance.new("TextLabel")
    TypeLabel.Size = UDim2.new(0, 60, 0, 20)
    TypeLabel.Position = UDim2.new(1, -75, 0, 12)
    TypeLabel.BackgroundColor3 = entry.type == "Event" and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(255, 120, 0)
    TypeLabel.Text = entry.type
    TypeLabel.TextColor3 = Color3.new(1, 1, 1)
    TypeLabel.TextSize = 10
    TypeLabel.Font = Enum.Font.GothamBold
    TypeLabel.Parent = Item
    
    local TypeCorner = Instance.new("UICorner")
    TypeCorner.CornerRadius = UDim.new(0, 6)
    TypeCorner.Parent = TypeLabel
    
    local ArgsLabel = Instance.new("TextLabel")
    ArgsLabel.Size = UDim2.new(1, -30, 0, 20)
    ArgsLabel.Position = UDim2.new(0, 15, 0, 35)
    ArgsLabel.BackgroundTransparency = 1
    ArgsLabel.Text = safeStringify(entry.args):sub(1, 50)
    ArgsLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    ArgsLabel.TextSize = 12
    ArgsLabel.Font = Enum.Font.Code
    ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgsLabel.Parent = Item

    -- Boutons d'action rapides
    local Actions = Instance.new("Frame")
    Actions.Size = UDim2.new(0, 100, 0, 30)
    Actions.Position = UDim2.new(1, -110, 1, -35)
    Actions.BackgroundTransparency = 1
    Actions.Parent = Item
    
    local BlockBtn = Instance.new("TextButton")
    BlockBtn.Size = UDim2.new(0, 30, 0, 30)
    BlockBtn.Position = UDim2.new(0, 0, 0, 0)
    BlockBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    BlockBtn.Text = "🚫"
    BlockBtn.TextSize = 14
    BlockBtn.Parent = Actions
    
    local BlockCorner = Instance.new("UICorner")
    BlockCorner.CornerRadius = UDim.new(0, 8)
    BlockCorner.Parent = BlockBtn
    
    local ReplayBtn = Instance.new("TextButton")
    ReplayBtn.Size = UDim2.new(0, 30, 0, 30)
    ReplayBtn.Position = UDim2.new(0, 40, 0, 0)
    ReplayBtn.BackgroundColor3 = Color3.fromRGB(70, 255, 70)
    ReplayBtn.Text = "▶️"
    ReplayBtn.TextSize = 14
    ReplayBtn.Parent = Actions
    
    local ReplayCorner = Instance.new("UICorner")
    ReplayCorner.CornerRadius = UDim.new(0, 8)
    ReplayCorner.Parent = ReplayBtn

    BlockBtn.MouseButton1Click:Connect(function()
        toggleBlockRemote(entry.path)
        Item:Destroy()
    end)
    
    ReplayBtn.MouseButton1Click:Connect(function()
        if entry.type == "Event" then
            entry.remote:FireServer(unpack(entry.args))
        else
            entry.remote:InvokeServer(unpack(entry.args))
        end
        showNotification("Replay envoyé !", config.accentColor)
    end)
    
    -- Ajuster la taille du conteneur
    LogContainer.Size = UDim2.new(0.9, 0, 0, #LogContainer:GetChildren() * 80)
    Content.CanvasSize = UDim2.new(0, 0, 0, LogContainer.Size.Y.Offset + 200)
end

-- === HOOKS RÉELS ===
if hasHook then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newCC(function(self, ...)
        local args = {...}
        local method = getNamecall()
        
        if not checkCaller() then
            if method == "FireServer" or method == "fireServer" then
                onRemoteCalled(self, args, "Event")
            elseif method == "InvokeServer" or method == "invokeServer" then
                onRemoteCalled(self, args, "Function")
            end
        end
        
        return oldNamecall(self, ...)
    end))
    
    local oldFireServer
    oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newCC(function(self, ...)
        if not checkCaller() then
            onRemoteCalled(self, {...}, "Event")
        end
        return oldFireServer(self, ...)
    end))
end

-- Drag & Drop
local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(MainFrame, Header)
makeDraggable(MinButton, MinButton)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinButton.Visible = true
end)

MinButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinButton.Visible = false
end)

showNotification("🚀 Remote Spy ELITE Chargé !", config.accentColor, 3)
