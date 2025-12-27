-- 🔥 ULTIMATE MOBILE REMOTE SPY - PROFESSIONAL EDITION
-- ✅ Replay fonctionnel avec stockage des remotes
-- ✅ Interface moderne et clean
-- ✅ 100% optimisé mobile

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Services
local LocalPlayer = Players.LocalPlayer

-- Parent GUI avec protection
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
local remoteCache = {} -- STOCKAGE DES REMOTES POUR REPLAY
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

local function findRemoteByPath(path)
    -- Méthode 1: Recherche directe
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
    
    -- Méthode 2: Recherche dans le cache
    return remoteCache[path]
end

local function storeRemote(path, remote)
    if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
        remoteCache[path] = remote
    end
end

-- Notification moderne
local function showNotification(text, color, duration)
    if not config.enableNotifications then return end
    duration = duration or 2
    
    task.spawn(function()
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 240, 0, 50)
        notif.Position = UDim2.new(0.5, -120, 0, -60)
        notif.BackgroundColor3 = color or Color3.fromRGB(40, 40, 50)
        notif.BorderSizePixel = 0
        notif.ZIndex = 100
        notif.Parent = ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = notif
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.8
        stroke.Thickness = 1
        stroke.Parent = notif
        
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
        
        notif:TweenPosition(UDim2.new(0.5, -120, 0, 10), "Out", "Quad", 0.3, true)
        wait(duration)
        notif:TweenPosition(UDim2.new(0.5, -120, 0, -60), "In", "Quad", 0.3, true)
        wait(0.3)
        notif:Destroy()
    end)
end

-- === CRÉATION UI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoteSpy_" .. math.random(10000, 99999)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = GuiParent

-- Bouton minimisé
local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.new(0, 70, 0, 70)
MinButton.Position = UDim2.new(0, 15, 0.5, -35)
MinButton.BackgroundColor3 = Color3.fromRGB(255, 70, 150)
MinButton.BorderSizePixel = 0
MinButton.Text = "📡"
MinButton.TextColor3 = Color3.new(1, 1, 1)
MinButton.TextSize = 28
MinButton.Font = Enum.Font.GothamBold
MinButton.Visible = false
MinButton.ZIndex = 50
MinButton.Parent = ScreenGui

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinButton

local MinShadow = Instance.new("ImageLabel")
MinShadow.Size = UDim2.new(1, 10, 1, 10)
MinShadow.Position = UDim2.new(0, -5, 0, -5)
MinShadow.BackgroundTransparency = 1
MinShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
MinShadow.ImageColor3 = Color3.new(0, 0, 0)
MinShadow.ImageTransparency = 0.7
MinShadow.ZIndex = 49
MinShadow.Parent = MinButton

-- Frame principale (optimisée mobile - TAILLE RÉDUITE)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 520)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 70, 150)
MainStroke.Thickness = 2.5
MainStroke.Transparency = 0
MainStroke.Parent = MainFrame

-- Header moderne (RÉDUIT)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 20)
HeaderCorner.Parent = Header

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 32))
}
HeaderGradient.Rotation = 90
HeaderGradient.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 0, 25)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "📡 REMOTE SPY"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -120, 0, 18)
Subtitle.Position = UDim2.new(0, 15, 0, 30)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Professional Edition"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 160)
Subtitle.TextSize = 9
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local StatusBadge = Instance.new("Frame")
StatusBadge.Size = UDim2.new(0, 75, 0, 22)
StatusBadge.Position = UDim2.new(1, -130, 0, 14)
StatusBadge.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
StatusBadge.BorderSizePixel = 0
StatusBadge.Parent = Header

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 11)
StatusCorner.Parent = StatusBadge

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● ACTIVE"
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Parent = StatusBadge

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 38, 0, 38)
HideBtn.Position = UDim2.new(1, -44, 0, 6)
HideBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
HideBtn.BorderSizePixel = 0
HideBtn.Text = "─"
HideBtn.TextColor3 = Color3.new(1, 1, 1)
HideBtn.TextSize = 18
HideBtn.Font = Enum.Font.GothamBold
HideBtn.Parent = Header

local HideCorner = Instance.new("UICorner")
HideCorner.CornerRadius = UDim.new(0, 10)
HideCorner.Parent = HideBtn

-- Compteur moderne (COMPACT)
local CounterFrame = Instance.new("Frame")
CounterFrame.Size = UDim2.new(1, -20, 0, 35)
CounterFrame.Position = UDim2.new(0, 10, 0, 58)
CounterFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
CounterFrame.BorderSizePixel = 0
CounterFrame.Parent = MainFrame

local CounterCorner = Instance.new("UICorner")
CounterCorner.CornerRadius = UDim.new(0, 10)
CounterCorner.Parent = CounterFrame

local CounterIcon = Instance.new("TextLabel")
CounterIcon.Size = UDim2.new(0, 35, 1, 0)
CounterIcon.BackgroundTransparency = 1
CounterIcon.Text = "📊"
CounterIcon.TextSize = 16
CounterIcon.Parent = CounterFrame

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Size = UDim2.new(1, -40, 1, 0)
CounterLabel.Position = UDim2.new(0, 38, 0, 0)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "0 Remotes Captured"
CounterLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
CounterLabel.TextSize = 13
CounterLabel.Font = Enum.Font.GothamBold
CounterLabel.TextXAlignment = Enum.TextXAlignment.Left
CounterLabel.Parent = CounterFrame

-- Barre de recherche moderne (COMPACT)
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -20, 0, 35)
SearchFrame.Position = UDim2.new(0, 10, 0, 100)
SearchFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
SearchFrame.BorderSizePixel = 0
SearchFrame.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 10)
SearchCorner.Parent = SearchFrame

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 35, 1, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextSize = 14
SearchIcon.Parent = SearchFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -100, 1, -8)
SearchBox.Position = UDim2.new(0, 38, 0, 4)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Search remotes..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchFrame

local ClearSearchBtn = Instance.new("TextButton")
ClearSearchBtn.Size = UDim2.new(0, 25, 0, 25)
ClearSearchBtn.Position = UDim2.new(1, -32, 0.5, -12.5)
ClearSearchBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ClearSearchBtn.BackgroundTransparency = 1
ClearSearchBtn.BorderSizePixel = 0
ClearSearchBtn.Text = "✕"
ClearSearchBtn.TextColor3 = Color3.fromRGB(200, 60, 60)
ClearSearchBtn.TextSize = 14
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.Visible = false
ClearSearchBtn.Parent = SearchFrame

-- Filtres modernes (COMPACT)
local FilterContainer = Instance.new("Frame")
FilterContainer.Size = UDim2.new(1, -20, 0, 32)
FilterContainer.Position = UDim2.new(0, 10, 0, 142)
FilterContainer.BackgroundTransparency = 1
FilterContainer.Parent = MainFrame

local function createFilterButton(text, position, isActive)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.31, 0, 1, 0)
    btn.Position = position
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
    
    return btn
end

local FilterAllBtn = createFilterButton("ALL", UDim2.new(0, 0, 0, 0), true)
local FilterEventBtn = createFilterButton("EVENTS", UDim2.new(0.345, 0, 0, 0), false)
local FilterFuncBtn = createFilterButton("FUNCTIONS", UDim2.new(0.69, 0, 0, 0), false)

-- Liste de remotes (scroll optimisé - COMPACT)
local RemoteList = Instance.new("ScrollingFrame")
RemoteList.Size = UDim2.new(1, -20, 0, 200)
RemoteList.Position = UDim2.new(0, 10, 0, 182)
RemoteList.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
RemoteList.BorderSizePixel = 0
RemoteList.ScrollBarThickness = 4
RemoteList.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 150)
RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
RemoteList.ScrollingDirection = Enum.ScrollingDirection.Y
RemoteList.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 12)
ListCorner.Parent = RemoteList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = RemoteList

-- Panel de détails moderne (COMPACT)
local DetailsPanel = Instance.new("ScrollingFrame")
DetailsPanel.Size = UDim2.new(1, -20, 0, 100)
DetailsPanel.Position = UDim2.new(0, 10, 0, 390)
DetailsPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
DetailsPanel.BorderSizePixel = 0
DetailsPanel.ScrollBarThickness = 4
DetailsPanel.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 150)
DetailsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
DetailsPanel.Parent = MainFrame

local DetailsCorner = Instance.new("UICorner")
DetailsCorner.CornerRadius = UDim.new(0, 12)
DetailsCorner.Parent = DetailsPanel

local DetailsText = Instance.new("TextLabel")
DetailsText.Size = UDim2.new(1, -20, 1, 0)
DetailsText.Position = UDim2.new(0, 10, 0, 10)
DetailsText.BackgroundTransparency = 1
DetailsText.Text = "💡 Select a remote\n▶️ Replay | ✏️ Edit"
DetailsText.TextColor3 = Color3.fromRGB(160, 160, 180)
DetailsText.TextSize = 10
DetailsText.Font = Enum.Font.Code
DetailsText.TextWrapped = true
DetailsText.TextXAlignment = Enum.TextXAlignment.Left
DetailsText.TextYAlignment = Enum.TextYAlignment.Top
DetailsText.Parent = DetailsPanel

-- Boutons d'action (COMPACT)
local ActionContainer = Instance.new("Frame")
ActionContainer.Size = UDim2.new(1, -20, 0, 70)
ActionContainer.Position = UDim2.new(0, 10, 0, 498)
ActionContainer.BackgroundTransparency = 1
ActionContainer.Parent = MainFrame

local function createActionButton(text, emoji, position, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 32)
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = ActionContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Size = UDim2.new(0, 25, 1, 0)
    emojiLabel.Position = UDim2.new(0, 8, 0, 0)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Text = emoji
    emojiLabel.TextSize = 14
    emojiLabel.Parent = btn
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -38, 1, 0)
    textLabel.Position = UDim2.new(0, 33, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 11
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = btn
    
    return btn
end

local ReplayBtn = createActionButton("REPLAY", "▶️", UDim2.new(0, 0, 0, 0), Color3.fromRGB(100, 150, 255))
local EditBtn = createActionButton("EDIT", "✏️", UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(255, 180, 50))
local CaptureBtn = createActionButton("PAUSE", "⏸️", UDim2.new(0, 0, 0, 38), Color3.fromRGB(60, 200, 120))
local ClearBtn = createActionButton("CLEAR", "🗑️", UDim2.new(0.52, 0, 0, 38), Color3.fromRGB(220, 70, 70))

-- Modal Edit (moderne)
local EditModal = Instance.new("Frame")
EditModal.Size = UDim2.new(1, 0, 1, 0)
EditModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
EditModal.BackgroundTransparency = 0.6
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

-- === FONCTIONS PRINCIPALES ===

local function updateCounter()
    local filtered = 0
    for _, entry in ipairs(remoteLog) do
        if (filterType == "All" or entry.type == filterType) and
           (filterText == "" or string.find(string.lower(entry.name), string.lower(filterText))) then
            filtered = filtered + 1
        end
    end
    
    if filtered ~= #remoteLog then
        CounterLabel.Text = string.format("%d/%d Remotes", filtered, #remoteLog)
    else
        CounterLabel.Text = string.format("%d Remotes", #remoteLog)
    end
end

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
        local match = string.match(line, "%[%d+%]%s*(.+)")
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

-- FONCTION REPLAY AMÉLIORÉE (FIXÉE)
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
        showNotification("✅ " .. entry.name .. " fired!", Color3.fromRGB(60, 200, 120), 2)
        return true
    else
        showNotification("❌ Error: " .. tostring(result):sub(1, 50), Color3.fromRGB(220, 70, 70), 3)
        return false
    end
end

local function refreshList()
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for _, entry in ipairs(remoteLog) do
        if (filterType == "All" or entry.type == filterType) and
           (filterText == "" or string.find(string.lower(entry.name), string.lower(filterText))) then
            pcall(createRemoteItemUI, entry.name, entry.type, entry.path, entry)
        end
    end
end

-- Créer UI item moderne (COMPACT)
function createRemoteItemUI(remoteName, remoteType, remotePath, entry)
    local Item = Instance.new("Frame")
    Item.Size = UDim2.new(1, -10, 0, 65)
    Item.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    Item.BorderSizePixel = 0
    Item.LayoutOrder = -math.floor(entry.time * 100)
    Item.Parent = RemoteList
    
    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 12)
    ItemCorner.Parent = Item
    
    local ItemStroke = Instance.new("UIStroke")
    ItemStroke.Color = Color3.fromRGB(45, 45, 55)
    ItemStroke.Thickness = 1
    ItemStroke.Transparency = 0.5
    ItemStroke.Parent = Item
    
    -- Highlight nouveau
    if config.enableNotifications and tick() - entry.time < 0.8 then
        ItemStroke.Color = Color3.fromRGB(255, 70, 150)
        ItemStroke.Thickness = 2
        ItemStroke.Transparency = 0
        task.delay(0.8, function()
            if Item and Item.Parent then
                ItemStroke.Color = Color3.fromRGB(45, 45, 55)
                ItemStroke.Thickness = 1
                ItemStroke.Transparency = 0.5
            end
        end)
    end
    
    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = Item
    
    local FavIcon = Instance.new("TextLabel")
    FavIcon.Size = UDim2.new(0, 20, 0, 20)
    FavIcon.Position = UDim2.new(0, 8, 0, 6)
    FavIcon.BackgroundTransparency = 1
    FavIcon.Text = favorites[remotePath] and "⭐" or "☆"
    FavIcon.TextColor3 = favorites[remotePath] and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(100, 100, 120)
    FavIcon.TextSize = 13
    FavIcon.Parent = Item
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -120, 0, 20)
    NameLabel.Position = UDim2.new(0, 32, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = remoteName
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 12
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Item
    
    local TypeBadge = Instance.new("Frame")
    TypeBadge.Size = UDim2.new(0, 55, 0, 20)
    TypeBadge.Position = UDim2.new(1, -62, 0, 8)
    TypeBadge.BackgroundColor3 = remoteType == "Event" and Color3.fromRGB(70, 130, 255) or Color3.fromRGB(255, 140, 70)
    TypeBadge.BorderSizePixel = 0
    TypeBadge.Parent = Item
    
    local TypeCorner = Instance.new("UICorner")
    TypeCorner.CornerRadius = UDim.new(0, 5)
    TypeCorner.Parent = TypeBadge
    
    local TypeLabel = Instance.new("TextLabel")
    TypeLabel.Size = UDim2.new(1, 0, 1, 0)
    TypeLabel.BackgroundTransparency = 1
    TypeLabel.Text = remoteType == "Event" and "EVENT" or "FUNC"
    TypeLabel.TextColor3 = Color3.new(1, 1, 1)
    TypeLabel.TextSize = 9
    TypeLabel.Font = Enum.Font.GothamBold
    TypeLabel.Parent = TypeBadge
    
    local PathLabel = Instance.new("TextLabel")
    PathLabel.Size = UDim2.new(1, -45, 0, 14)
    PathLabel.Position = UDim2.new(0, 32, 0, 29)
    PathLabel.BackgroundTransparency = 1
    PathLabel.Text = "📍 " .. remotePath
    PathLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
    PathLabel.TextSize = 8
    PathLabel.Font = Enum.Font.Gotham
    PathLabel.TextXAlignment = Enum.TextXAlignment.Left
    PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    PathLabel.Parent = Item
    
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(0, 80, 0, 14)
    TimeLabel.Position = UDim2.new(0, 32, 0, 45)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Text = "🕐 " .. os.date("%H:%M:%S", entry.time)
    TimeLabel.TextColor3 = Color3.fromRGB(110, 110, 130)
    TimeLabel.TextSize = 8
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.Parent = Item
    
    local ArgsCount = Instance.new("TextLabel")
    ArgsCount.Size = UDim2.new(0, 70, 0, 14)
    ArgsCount.Position = UDim2.new(0, 115, 0, 45)
    ArgsCount.BackgroundTransparency = 1
    ArgsCount.Text = "📦 " .. #entry.args .. " args"
    ArgsCount.TextColor3 = Color3.fromRGB(110, 110, 130)
    ArgsCount.TextSize = 8
    ArgsCount.Font = Enum.Font.Gotham
    ArgsCount.TextXAlignment = Enum.TextXAlignment.Left
    ArgsCount.Parent = Item
    
    local ReplayQuickBtn = Instance.new("TextButton")
    ReplayQuickBtn.Size = UDim2.new(0, 28, 0, 28)
    ReplayQuickBtn.Position = UDim2.new(1, -35, 0.5, -14)
    ReplayQuickBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    ReplayQuickBtn.BorderSizePixel = 0
    ReplayQuickBtn.Text = "▶"
    ReplayQuickBtn.TextColor3 = Color3.new(1, 1, 1)
    ReplayQuickBtn.TextSize = 12
    ReplayQuickBtn.Font = Enum.Font.GothamBold
    ReplayQuickBtn.ZIndex = 2
    ReplayQuickBtn.Parent = Item
    
    local ReplayCorner = Instance.new("UICorner")
    ReplayCorner.CornerRadius = UDim.new(0, 7)
    ReplayCorner.Parent = ReplayQuickBtn
    
    -- Events
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
                end
            end
        end
        
        ItemStroke.Color = Color3.fromRGB(100, 150, 255)
        ItemStroke.Thickness = 2
        
        local details = string.format(
            "━━━━━━━━━━━━━━━━━━━━\n📋 REMOTE DETAILS\n━━━━━━━━━━━━━━━━━━━━\n\n" ..
            "🔹 Name: %s\n" ..
            "📦 Type: %s\n" ..
            "📍 Path: %s\n" ..
            "🕐 Time: %s\n" ..
            "⭐ Favorite: %s\n\n" ..
            "━━━━━━━━━━━━━━━━━━━━\n📝 ARGUMENTS (%d)\n━━━━━━━━━━━━━━━━━━━━\n\n%s\n" ..
            "━━━━━━━━━━━━━━━━━━━━\n💡 TIP: Use REPLAY or EDIT buttons",
            entry.name, 
            entry.type, 
            entry.path,
            os.date("%H:%M:%S", entry.time),
            favorites[entry.path] and "Yes" or "No",
            #entry.args,
            formatArgs(entry.args)
        )
        
        DetailsText.Text = details
        DetailsPanel.CanvasSize = UDim2.new(0, 0, 0, DetailsText.TextBounds.Y + 20)
    end)
    
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end

-- Ajouter à la file
local function queueRemoteCapture(remoteName, remoteType, args, remotePath, remoteObj)
    if blockedRemotes[remotePath] then return end
    
    for i = 1, math.min(3, #remoteLog) do
        if remoteLog[i] and remoteLog[i].path == remotePath and tick() - remoteLog[i].time < config.deduplicateTime then
            return
        end
    end
    
    -- STOCKER LE REMOTE OBJECT
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

-- Processeur de file
RunService.Heartbeat:Connect(function()
    if #uiQueue > 0 then
        local data = table.remove(uiQueue, 1)
        if (filterType == "All" or data[2] == filterType) and
           (filterText == "" or string.find(string.lower(data[1]), string.lower(filterText))) then
            pcall(createRemoteItemUI, data[1], data[2], data[3], data[4])
        end
    end
end)

-- === HOOK AMÉLIORÉ ===
if hasHook then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newCC(function(self, ...)
        local method = getNamecall()
        local args = {...}
        
        if (method == "FireServer" or method == "InvokeServer") and not checkCaller() and isCapturing then
            task.spawn(function()
                pcall(function()
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        local rType = self:IsA("RemoteEvent") and "Event" or "Function"
                        local rName = tostring(self.Name)
                        local rPath = ""
                        pcall(function() rPath = self:GetFullName() end)
                        if rPath == "" then rPath = tostring(self) end
                        
                        queueRemoteCapture(rName, rType, args, rPath, self)
                    end
                end)
            end)
        end
        
        return oldNamecall(self, unpack(args))
    end))
else
    showNotification("⚠️ Hooking not supported", Color3.fromRGB(255, 180, 50), 3)
end

-- === EVENTS UI ===

local function toggleMinimize()
    isMinimized = not isMinimized
    MainFrame.Visible = not isMinimized
    MinButton.Visible = isMinimized
    
    if isMinimized then
        showNotification("📡 Spy minimized", Color3.fromRGB(100, 100, 120), 1)
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

-- Filters
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

FilterAllBtn.MouseButton1Click:Connect(function()
    filterType = "All"
    FilterAllBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 150)
    FilterEventBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    FilterFuncBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    refreshList()
    updateCounter()
end)

FilterEventBtn.MouseButton1Click:Connect(function()
    filterType = "Event"
    FilterAllBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    FilterEventBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 150)
    FilterFuncBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    refreshList()
    updateCounter()
end)

FilterFuncBtn.MouseButton1Click:Connect(function()
    filterType = "Function"
    FilterAllBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    FilterEventBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    FilterFuncBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 150)
    refreshList()
    updateCounter()
end)

-- Draggable (optimisé mobile)
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

-- Export si disponible (POSITION AJUSTÉE)
if setclipboard then
    local ExportBtn = Instance.new("TextButton")
    ExportBtn.Size = UDim2.new(0, 30, 0, 30)
    ExportBtn.Position = UDim2.new(1, -78, 0, 10)
    ExportBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    ExportBtn.BorderSizePixel = 0
    ExportBtn.Text = "📋"
    ExportBtn.TextSize = 13
    ExportBtn.Font = Enum.Font.GothamBold
    ExportBtn.Parent = Header
    
    local ExportCorner = Instance.new("UICorner")
    ExportCorner.CornerRadius = UDim.new(0, 7)
    ExportCorner.Parent = ExportBtn
    
    ExportBtn.MouseButton1Click:Connect(function()
        local export = "=== REMOTE SPY EXPORT ===\n"
        export = export .. string.format("Date: %s\n", os.date("%Y-%m-%d %H:%M:%S"))
        export = export .. string.format("Total: %d remotes\n\n", #remoteLog)
        
        for i, entry in ipairs(remoteLog) do
            export = export .. string.format("[%d] %s (%s)\n", i, entry.name, entry.type)
            export = export .. string.format("    Path: %s\n", entry.path)
            export = export .. string.format("    Time: %s\n", os.date("%H:%M:%S", entry.time))
            export = export .. "    Args: " .. formatArgs(entry.args):gsub("\n", "\n    ") .. "\n\n"
        end
        
        setclipboard(export)
        showNotification("📋 Copied to clipboard!", Color3.fromRGB(150, 100, 255), 2)
    end)
end

-- Initialisation
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔥 REMOTE SPY PRO - LOADED")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Hook: " .. (hasHook and "Active" or "Disabled"))
print("✅ Max logs: " .. config.maxLogs)
print("✅ Features: Replay, Edit, Filters")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

showNotification("🔥 Remote Spy PRO ready!", Color3.fromRGB(100, 255, 150), 2)
