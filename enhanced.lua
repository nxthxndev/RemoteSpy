-- 🔥 ULTIMATE MOBILE REMOTE SPY - ENHANCED EDITION
-- Features: Replay, Edit, Export, Filters, Advanced Analysis

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Parent GUI (avec fallback mobile)
local GuiParent = (function()
    local success, coreGui = pcall(game.GetService, game, "CoreGui")
    return success and coreGui or Players.LocalPlayer:WaitForChild("PlayerGui")
end)()

-- Vérifier fonctions UNC
local hasHook = hookmetamethod ~= nil
local getNamecall = getnamecallmethod or function() return "" end
local checkCaller = checkcaller or function() return false end
local newCC = newcclosure or function(f) return f end

-- Variables principales
local remoteLog = {}
local isCapturing = true
local selectedEntry = nil
local isMinimized = false
local uiQueue = {}
local filterText = ""
local filterType = "All" -- All, Event, Function
local favorites = {}
local blockedRemotes = {}
local autoReplayList = {}

-- Configuration
local config = {
    maxLogs = 500,
    deduplicateTime = 0.1,
    enableNotifications = true,
    enableSound = false,
    highlightNew = true
}

-- Fonction utilitaire améliorée
local function safeStringify(value, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    
    local t = typeof(value)
    if t == "Instance" then
        local s, name = pcall(function() return value:GetFullName() end)
        return s and name or tostring(value)
    elseif t == "table" then
        local str = "{"
        local count = 0
        pcall(function()
            for k, v in pairs(value) do
                if count > 5 then
                    str = str .. "..."
                    break
                end
                str = str .. tostring(k) .. "=" .. safeStringify(v, depth + 1) .. ", "
                count = count + 1
            end
        end)
        return str .. "}"
    elseif t == "CFrame" then
        return string.format("CFrame(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
    elseif t == "Vector3" then
        return string.format("Vector3(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
    elseif t == "Color3" then
        return string.format("Color3(%d, %d, %d)", value.R*255, value.G*255, value.B*255)
    else
        return tostring(value)
    end
end

local function deepCopyArgs(args)
    local copy = {}
    for i, arg in ipairs(args) do
        local t = typeof(arg)
        if t == "table" then
            copy[i] = {}
            for k, v in pairs(arg) do
                copy[i][k] = v
            end
        else
            copy[i] = arg
        end
    end
    return copy
end

-- Notification system
local function showNotification(text, color)
    if not config.enableNotifications then return end
    
    task.spawn(function()
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 200, 0, 40)
        notif.Position = UDim2.new(1, -210, 0, 10)
        notif.BackgroundColor3 = color or Color3.fromRGB(50, 50, 60)
        notif.BorderSizePixel = 0
        notif.Parent = ScreenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = notif
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 1, 0)
        label.Position = UDim2.new(0, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.TextWrapped = true
        label.Parent = notif
        
        wait(2)
        notif:Destroy()
    end)
end

-- === UI CREATION ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileRemoteSpy_" .. math.random(1000, 9999)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.new(0, 60, 0, 60)
MinButton.Position = UDim2.new(0, 10, 0, 100)
MinButton.BackgroundColor3 = Color3.fromRGB(255, 50, 150)
MinButton.BorderSizePixel = 0
MinButton.Text = "📡"
MinButton.TextColor3 = Color3.new(1, 1, 1)
MinButton.TextSize = 24
MinButton.Font = Enum.Font.GothamBold
MinButton.Visible = false
MinButton.Parent = ScreenGui

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinButton

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 600)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 50, 150)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "📡 MOBILE SPY PRO"
Title.TextColor3 = Color3.fromRGB(255, 50, 150)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 80, 0, 20)
StatusLabel.Position = UDim2.new(0, 15, 0, 28)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "✅ Active"
StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Header

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 40, 0, 40)
HideBtn.Position = UDim2.new(1, -45, 0, 5)
HideBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
HideBtn.BorderSizePixel = 0
HideBtn.Text = "—"
HideBtn.TextColor3 = Color3.new(1, 1, 1)
HideBtn.TextSize = 20
HideBtn.Font = Enum.Font.GothamBold
HideBtn.Parent = Header

local HideBtnCorner = Instance.new("UICorner")
HideBtnCorner.CornerRadius = UDim.new(0, 8)
HideBtnCorner.Parent = HideBtn

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Size = UDim2.new(0, 80, 0, 40)
CounterLabel.Position = UDim2.new(1, -90, 0, 5)
CounterLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
CounterLabel.BorderSizePixel = 0
CounterLabel.Text = "0"
CounterLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
CounterLabel.TextSize = 20
CounterLabel.Font = Enum.Font.GothamBold
CounterLabel.Parent = Header

local CounterCorner = Instance.new("UICorner")
CounterCorner.CornerRadius = UDim.new(0, 8)
CounterCorner.Parent = CounterLabel

-- Filter Bar
local FilterFrame = Instance.new("Frame")
FilterFrame.Size = UDim2.new(1, -20, 0, 40)
FilterFrame.Position = UDim2.new(0, 10, 0, 60)
FilterFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
FilterFrame.BorderSizePixel = 0
FilterFrame.Parent = MainFrame

local FilterCorner = Instance.new("UICorner")
FilterCorner.CornerRadius = UDim.new(0, 10)
FilterCorner.Parent = FilterFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(0.55, 0, 1, -10)
SearchBox.Position = UDim2.new(0, 5, 0, 5)
SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
SearchBox.BorderSizePixel = 0
SearchBox.PlaceholderText = "🔍 Search remotes..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.TextSize = 12
SearchBox.Font = Enum.Font.Gotham
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = FilterFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBox

local FilterAllBtn = Instance.new("TextButton")
FilterAllBtn.Size = UDim2.new(0.13, 0, 1, -10)
FilterAllBtn.Position = UDim2.new(0.57, 0, 0, 5)
FilterAllBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 150)
FilterAllBtn.BorderSizePixel = 0
FilterAllBtn.Text = "ALL"
FilterAllBtn.TextColor3 = Color3.new(1, 1, 1)
FilterAllBtn.TextSize = 10
FilterAllBtn.Font = Enum.Font.GothamBold
FilterAllBtn.Parent = FilterFrame

local FilterAllCorner = Instance.new("UICorner")
FilterAllCorner.CornerRadius = UDim.new(0, 6)
FilterAllCorner.Parent = FilterAllBtn

local FilterEventBtn = Instance.new("TextButton")
FilterEventBtn.Size = UDim2.new(0.13, 0, 1, -10)
FilterEventBtn.Position = UDim2.new(0.715, 0, 0, 5)
FilterEventBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
FilterEventBtn.BorderSizePixel = 0
FilterEventBtn.Text = "EVT"
FilterEventBtn.TextColor3 = Color3.new(1, 1, 1)
FilterEventBtn.TextSize = 10
FilterEventBtn.Font = Enum.Font.GothamBold
FilterEventBtn.Parent = FilterFrame

local FilterEventCorner = Instance.new("UICorner")
FilterEventCorner.CornerRadius = UDim.new(0, 6)
FilterEventCorner.Parent = FilterEventBtn

local FilterFuncBtn = Instance.new("TextButton")
FilterFuncBtn.Size = UDim2.new(0.13, 0, 1, -10)
FilterFuncBtn.Position = UDim2.new(0.86, 0, 0, 5)
FilterFuncBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
FilterFuncBtn.BorderSizePixel = 0
FilterFuncBtn.Text = "FNC"
FilterFuncBtn.TextColor3 = Color3.new(1, 1, 1)
FilterFuncBtn.TextSize = 10
FilterFuncBtn.Font = Enum.Font.GothamBold
FilterFuncBtn.Parent = FilterFrame

local FilterFuncCorner = Instance.new("UICorner")
FilterFuncCorner.CornerRadius = UDim.new(0, 6)
FilterFuncCorner.Parent = FilterFuncBtn

local RemoteList = Instance.new("ScrollingFrame")
RemoteList.Size = UDim2.new(1, -20, 0, 240)
RemoteList.Position = UDim2.new(0, 10, 0, 110)
RemoteList.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
RemoteList.BorderSizePixel = 0
RemoteList.ScrollBarThickness = 6
RemoteList.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 150)
RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
RemoteList.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 12)
ListCorner.Parent = RemoteList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = RemoteList

local DetailsPanel = Instance.new("ScrollingFrame")
DetailsPanel.Size = UDim2.new(1, -20, 0, 130)
DetailsPanel.Position = UDim2.new(0, 10, 0, 360)
DetailsPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
DetailsPanel.BorderSizePixel = 0
DetailsPanel.ScrollBarThickness = 6
DetailsPanel.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 150)
DetailsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
DetailsPanel.Parent = MainFrame

local DetailsCorner = Instance.new("UICorner")
DetailsCorner.CornerRadius = UDim.new(0, 12)
DetailsCorner.Parent = DetailsPanel

local DetailsText = Instance.new("TextLabel")
DetailsText.Size = UDim2.new(1, -20, 1, 0)
DetailsText.Position = UDim2.new(0, 10, 0, 10)
DetailsText.BackgroundTransparency = 1
DetailsText.Text = "💡 Select a remote to view details..."
DetailsText.TextColor3 = Color3.fromRGB(180, 180, 200)
DetailsText.TextSize = 11
DetailsText.Font = Enum.Font.Code
DetailsText.TextWrapped = true
DetailsText.TextXAlignment = Enum.TextXAlignment.Left
DetailsText.TextYAlignment = Enum.TextYAlignment.Top
DetailsText.Parent = DetailsPanel

-- Action Buttons (Enhanced)
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -20, 0, 95)
ButtonContainer.Position = UDim2.new(0, 10, 0, 500)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

local function createButton(text, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = ButtonContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    return btn
end

local CaptureBtn = createButton("🔴 CAPTURE", UDim2.new(0, 0, 0, 0), Color3.fromRGB(60, 200, 120))
local ClearBtn = createButton("🗑️ CLEAR", UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(200, 60, 60))
local ReplayBtn = createButton("▶️ REPLAY", UDim2.new(0, 0, 0, 48), Color3.fromRGB(100, 150, 255))
local EditBtn = createButton("✏️ EDIT", UDim2.new(0.52, 0, 0, 48), Color3.fromRGB(255, 180, 50))

-- Modal pour Edit
local EditModal = Instance.new("Frame")
EditModal.Size = UDim2.new(1, 0, 1, 0)
EditModal.Position = UDim2.new(0, 0, 0, 0)
EditModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
EditModal.BackgroundTransparency = 0.5
EditModal.BorderSizePixel = 0
EditModal.Visible = false
EditModal.ZIndex = 10
EditModal.Parent = MainFrame

local EditFrame = Instance.new("Frame")
EditFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
EditFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
EditFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
EditFrame.BorderSizePixel = 0
EditFrame.ZIndex = 11
EditFrame.Parent = EditModal

local EditFrameCorner = Instance.new("UICorner")
EditFrameCorner.CornerRadius = UDim.new(0, 12)
EditFrameCorner.Parent = EditFrame

local EditTitle = Instance.new("TextLabel")
EditTitle.Size = UDim2.new(1, -20, 0, 40)
EditTitle.Position = UDim2.new(0, 10, 0, 10)
EditTitle.BackgroundTransparency = 1
EditTitle.Text = "✏️ Edit Arguments"
EditTitle.TextColor3 = Color3.fromRGB(255, 180, 50)
EditTitle.TextSize = 16
EditTitle.Font = Enum.Font.GothamBold
EditTitle.TextXAlignment = Enum.TextXAlignment.Left
EditTitle.ZIndex = 11
EditTitle.Parent = EditFrame

local EditArgsBox = Instance.new("TextBox")
EditArgsBox.Size = UDim2.new(1, -20, 1, -120)
EditArgsBox.Position = UDim2.new(0, 10, 0, 60)
EditArgsBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
EditArgsBox.BorderSizePixel = 0
EditArgsBox.Text = ""
EditArgsBox.TextColor3 = Color3.new(1, 1, 1)
EditArgsBox.TextSize = 11
EditArgsBox.Font = Enum.Font.Code
EditArgsBox.TextXAlignment = Enum.TextXAlignment.Left
EditArgsBox.TextYAlignment = Enum.TextYAlignment.Top
EditArgsBox.ClearTextOnFocus = false
EditArgsBox.MultiLine = true
EditArgsBox.TextWrapped = true
EditArgsBox.ZIndex = 11
EditArgsBox.Parent = EditFrame

local EditArgsCorner = Instance.new("UICorner")
EditArgsCorner.CornerRadius = UDim.new(0, 8)
EditArgsCorner.Parent = EditArgsBox

local EditSaveBtn = Instance.new("TextButton")
EditSaveBtn.Size = UDim2.new(0.45, 0, 0, 40)
EditSaveBtn.Position = UDim2.new(0, 10, 1, -50)
EditSaveBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
EditSaveBtn.BorderSizePixel = 0
EditSaveBtn.Text = "💾 SAVE & FIRE"
EditSaveBtn.TextColor3 = Color3.new(1, 1, 1)
EditSaveBtn.TextSize = 13
EditSaveBtn.Font = Enum.Font.GothamBold
EditSaveBtn.ZIndex = 11
EditSaveBtn.Parent = EditFrame

local EditSaveCorner = Instance.new("UICorner")
EditSaveCorner.CornerRadius = UDim.new(0, 8)
EditSaveCorner.Parent = EditSaveBtn

local EditCancelBtn = Instance.new("TextButton")
EditCancelBtn.Size = UDim2.new(0.45, 0, 0, 40)
EditCancelBtn.Position = UDim2.new(0.55, 0, 1, -50)
EditCancelBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
EditCancelBtn.BorderSizePixel = 0
EditCancelBtn.Text = "❌ CANCEL"
EditCancelBtn.TextColor3 = Color3.new(1, 1, 1)
EditCancelBtn.TextSize = 13
EditCancelBtn.Font = Enum.Font.GothamBold
EditCancelBtn.ZIndex = 11
EditCancelBtn.Parent = EditFrame

local EditCancelCorner = Instance.new("UICorner")
EditCancelCorner.CornerRadius = UDim.new(0, 8)
EditCancelCorner.Parent = EditCancelBtn

-- === FONCTIONS ===
local function updateCounter()
    local filtered = 0
    for _, entry in ipairs(remoteLog) do
        if (filterType == "All" or entry.type == filterType) and
           (filterText == "" or string.find(string.lower(entry.name), string.lower(filterText))) then
            filtered = filtered + 1
        end
    end
    CounterLabel.Text = string.format("%d/%d", filtered, #remoteLog)
end

local function formatArgs(args)
    if not args or #args == 0 then return "No arguments" end
    local result = ""
    for i, arg in ipairs(args) do
        result = result .. string.format("[%d] %s\n", i, safeStringify(arg))
    end
    return result
end

local function getRemoteObject(path)
    local success, obj = pcall(function()
        return game:GetService("Players"):FindFirstChild(path) or game:FindFirstChild(path, true)
    end)
    if success and obj then return obj end
    
    -- Try parsing path
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    
    local current = game
    for i, part in ipairs(parts) do
        if i > 1 then
            success, current = pcall(function() return current:FindFirstChild(part) end)
            if not success or not current then return nil end
        end
    end
    return current
end

local function fireRemote(entry, customArgs)
    local args = customArgs or entry.args
    local remote = getRemoteObject(entry.path)
    
    if not remote then
        showNotification("❌ Remote not found!", Color3.fromRGB(200, 60, 60))
        return false
    end
    
    local success, err = pcall(function()
        if entry.type == "Event" then
            remote:FireServer(unpack(args))
        else
            remote:InvokeServer(unpack(args))
        end
    end)
    
    if success then
        showNotification("✅ Remote fired!", Color3.fromRGB(60, 200, 120))
        return true
    else
        showNotification("❌ Error: " .. tostring(err), Color3.fromRGB(200, 60, 60))
        return false
    end
end

local function refreshList()
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("TextButton") then
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

local function parseEditedArgs(text)
    local args = {}
    for line in string.gmatch(text, "[^\n]+") do
        local match = string.match(line, "%[%d+%]%s*(.+)")
        if match then
            -- Try to parse as number
            local num = tonumber(match)
            if num then
                table.insert(args, num)
            elseif match == "true" then
                table.insert(args, true)
            elseif match == "false" then
                table.insert(args, false)
            else
                table.insert(args, match)
            end
        end
    end
    return args
end

-- Créer UI item avec actions
local function createRemoteItemUI(remoteName, remoteType, remotePath, entry)
    local Item = Instance.new("TextButton")
    Item.Size = UDim2.new(1, -10, 0, 70)
    Item.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Item.BorderSizePixel = 0
    Item.Text = ""
    Item.AutoButtonColor = false
    Item.LayoutOrder = -math.floor(entry.time * 100)
    Item.Parent = RemoteList
    
    if config.highlightNew and tick() - entry.time < 1 then
        Item.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        task.delay(1, function()
            if Item and Item.Parent then
                Item.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            end
        end)
    end
    
    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 10)
    ItemCorner.Parent = Item
    
    if favorites[remotePath] then
        local favIcon = Instance.new("TextLabel")
        favIcon.Size = UDim2.new(0, 20, 0, 20)
        favIcon.Position = UDim2.new(0, 5, 0, 5)
        favIcon.BackgroundTransparency = 1
        favIcon.Text = "⭐"
        favIcon.TextSize = 14
        favIcon.Parent = Item
    end
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -100, 0, 22)
    NameLabel.Position = UDim2.new(0, favorites[remotePath] and 30 or 10, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = "🔹 " .. remoteName
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Item
    
    local TypeBadge = Instance.new("TextLabel")
    TypeBadge.Size = UDim2.new(0, 55, 0, 20)
    TypeBadge.Position = UDim2.new(1, -60, 0, 8)
    TypeBadge.BackgroundColor3 = remoteType == "Event" and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(255, 120, 50)
    TypeBadge.Text = remoteType:sub(1, 3):upper()
    TypeBadge.TextColor3 = Color3.new(1, 1, 1)
    TypeBadge.TextSize = 10
    TypeBadge.Font = Enum.Font.GothamBold
    TypeBadge.BorderSizePixel = 0
    TypeBadge.Parent = Item
    
    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 5)
    BadgeCorner.Parent = TypeBadge
    
    local PathLabel = Instance.new("TextLabel")
    PathLabel.Size = UDim2.new(1, -20, 0, 18)
    PathLabel.Position = UDim2.new(0, favorites[remotePath] and 30 or 10, 0, 32)
    PathLabel.BackgroundTransparency = 1
    PathLabel.Text = remotePath
    PathLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    PathLabel.TextSize = 9
    PathLabel.Font = Enum.Font.Gotham
    PathLabel.TextXAlignment = Enum.TextXAlignment.Left
    PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    PathLabel.Parent = Item
    
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(1, -20, 0, 15)
    TimeLabel.Position = UDim2.new(0, 10, 0, 52)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Text = "⏰ " .. os.date("%H:%M:%S", entry.time)
    TimeLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    TimeLabel.TextSize = 9
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.Parent = Item
    
    local QuickReplayBtn = Instance.new("TextButton")
    QuickReplayBtn.Size = UDim2.new(0, 25, 0, 25)
    QuickReplayBtn.Position = UDim2.new(1, -95, 0, 38)
    QuickReplayBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    QuickReplayBtn.BorderSizePixel = 0
    QuickReplayBtn.Text = "▶️"
    QuickReplayBtn.TextSize = 10
    QuickReplayBtn.Font = Enum.Font.GothamBold
    QuickReplayBtn.Parent = Item
    
    local QRCorner = Instance.new("UICorner")
    QRCorner.CornerRadius = UDim.new(0, 5)
    QRCorner.Parent = QuickReplayBtn
    
    local FavBtn = Instance.new("TextButton")
    FavBtn.Size = UDim2.new(0, 25, 0, 25)
    FavBtn.Position = UDim2.new(1, -65, 0, 38)
    FavBtn.BackgroundColor3 = favorites[remotePath] and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(60, 60, 70)
    FavBtn.BorderSizePixel = 0
    FavBtn.Text = "⭐"
    FavBtn.TextSize = 10
    FavBtn.Font = Enum.Font.GothamBold
    FavBtn.Parent = Item
    
    local FavCorner = Instance.new("UICorner")
    FavCorner.CornerRadius = UDim.new(0, 5)
    FavCorner.Parent = FavBtn
    
    local BlockBtn = Instance.new("TextButton")
    BlockBtn.Size = UDim2.new(0, 25, 0, 25)
    BlockBtn.Position = UDim2.new(1, -35, 0, 38)
    BlockBtn.BackgroundColor3 = blockedRemotes[remotePath] and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(60, 60, 70)
    BlockBtn.BorderSizePixel = 0
    BlockBtn.Text = "🚫"
    BlockBtn.TextSize = 10
    BlockBtn.Font = Enum.Font.GothamBold
    BlockBtn.Parent = Item
    
    local BlockCorner = Instance.new("UICorner")
    BlockCorner.CornerRadius = UDim.new(0, 5)
    BlockCorner.Parent = BlockBtn
    
    QuickReplayBtn.MouseButton1Click:Connect(function()
        fireRemote(entry)
    end)
    
    FavBtn.MouseButton1Click:Connect(function()
        favorites[remotePath] = not favorites[remotePath]
        FavBtn.BackgroundColor3 = favorites[remotePath] and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(60, 60, 70)
        refreshList()
        showNotification(favorites[remotePath] and "⭐ Added to favorites" or "❌ Removed from favorites", 
                        favorites[remotePath] and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 150))
    end)
    
    BlockBtn.MouseButton1Click:Connect(function()
        blockedRemotes[remotePath] = not blockedRemotes[remotePath]
        BlockBtn.BackgroundColor3 = blockedRemotes[remotePath] and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(60, 60, 70)
        showNotification(blockedRemotes[remotePath] and "🚫 Remote blocked" or "✅ Remote unblocked",
                        blockedRemotes[remotePath] and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(60, 200, 120))
    end)
    
    Item.MouseButton1Click:Connect(function()
        selectedEntry = entry
        for _, child in ipairs(RemoteList:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            end
        end
        Item.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        
        local details = string.format(
            "📋 Name: %s\n📦 Type: %s\n📍 Path: %s\n⏰ Time: %s\n⭐ Favorite: %s\n🚫 Blocked: %s\n\n📝 Arguments:\n%s\n\n💡 Tip: Use REPLAY to fire this remote again, or EDIT to modify arguments!",
            entry.name, entry.type, entry.path,
            os.date("%H:%M:%S", entry.time),
            favorites[entry.path] and "Yes" or "No",
            blockedRemotes[entry.path] and "Yes" or "No",
            formatArgs(entry.args)
        )
        DetailsText.Text = details
        DetailsPanel.CanvasSize = UDim2.new(0, 0, 0, DetailsText.TextBounds.Y + 20)
    end)
    
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end

-- Ajouter à la file
local function queueRemoteCapture(remoteName, remoteType, args, remotePath)
    if blockedRemotes[remotePath] then return end
    
    for i = 1, math.min(3, #remoteLog) do
        if remoteLog[i] and remoteLog[i].path == remotePath and tick() - remoteLog[i].time < config.deduplicateTime then
            return
        end
    end
    
    local entry = {
        name = remoteName,
        type = remoteType,
        args = deepCopyArgs(args),
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

-- === HOOK ===
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
                        
                        queueRemoteCapture(rName, rType, args, rPath)
                    end
                end)
            end)
        end
        
        return oldNamecall(self, unpack(args))
    end))
end

-- === EVENTS ===
local function toggleMinimize()
    isMinimized = not isMinimized
    MainFrame.Visible = not isMinimized
    MinButton.Visible = isMinimized
end

HideBtn.MouseButton1Click:Connect(toggleMinimize)
MinButton.MouseButton1Click:Connect(toggleMinimize)

CaptureBtn.MouseButton1Click:Connect(function()
    isCapturing = not isCapturing
    CaptureBtn.Text = isCapturing and "🔴 CAPTURE" or "⏸️ PAUSED"
    CaptureBtn.BackgroundColor3 = isCapturing and Color3.fromRGB(60, 200, 120) or Color3.fromRGB(150, 150, 150)
    StatusLabel.Text = isCapturing and "✅ Active" or "⏸️ Paused"
    StatusLabel.TextColor3 = isCapturing and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 180, 100)
end)

ClearBtn.MouseButton1Click:Connect(function()
    remoteLog = {}
    uiQueue = {}
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    selectedEntry = nil
    DetailsText.Text = "💡 Logs cleared! Ready to capture new remotes..."
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
    updateCounter()
    showNotification("🗑️ All logs cleared", Color3.fromRGB(200, 60, 60))
end)

ReplayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then
        showNotification("⚠️ Select a remote first!", Color3.fromRGB(255, 180, 50))
        return
    end
    fireRemote(selectedEntry)
end)

EditBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then
        showNotification("⚠️ Select a remote first!", Color3.fromRGB(255, 180, 50))
        return
    end
    
    EditArgsBox.Text = formatArgs(selectedEntry.args)
    EditModal.Visible = true
end)

EditSaveBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    
    local newArgs = parseEditedArgs(EditArgsBox.Text)
    if #newArgs > 0 then
        fireRemote(selectedEntry, newArgs)
        EditModal.Visible = false
    else
        showNotification("⚠️ Invalid arguments!", Color3.fromRGB(255, 180, 50))
    end
end)

EditCancelBtn.MouseButton1Click:Connect(function()
    EditModal.Visible = false
end)

-- Filter events
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterText = SearchBox.Text
    refreshList()
    updateCounter()
end)

FilterAllBtn.MouseButton1Click:Connect(function()
    filterType = "All"
    FilterAllBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 150)
    FilterEventBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    FilterFuncBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    refreshList()
    updateCounter()
end)

FilterEventBtn.MouseButton1Click:Connect(function()
    filterType = "Event"
    FilterAllBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    FilterEventBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 150)
    FilterFuncBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    refreshList()
    updateCounter()
end)

FilterFuncBtn.MouseButton1Click:Connect(function()
    filterType = "Function"
    FilterAllBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    FilterEventBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    FilterFuncBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 150)
    refreshList()
    updateCounter()
end)

-- Draggable
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainFrame, Header)
makeDraggable(MinButton, MinButton)

-- Export to clipboard (si disponible)
if setclipboard then
    local ExportBtn = createButton("📋 EXPORT", UDim2.new(0, 0, 0, 96), Color3.fromRGB(150, 100, 255))
    ExportBtn.Size = UDim2.new(1, 0, 0, 40)
    
    ExportBtn.MouseButton1Click:Connect(function()
        local export = "=== REMOTE SPY EXPORT ===\n"
        export = export .. string.format("Total Logs: %d\n", #remoteLog)
        export = export .. string.format("Captured: %s\n\n", os.date("%Y-%m-%d %H:%M:%S"))
        
        for i, entry in ipairs(remoteLog) do
            export = export .. string.format("[%d] %s (%s)\n", i, entry.name, entry.type)
            export = export .. string.format("Path: %s\n", entry.path)
            export = export .. string.format("Time: %s\n", os.date("%H:%M:%S", entry.time))
            export = export .. "Args: " .. formatArgs(entry.args) .. "\n\n"
        end
        
        setclipboard(export)
        showNotification("📋 Exported to clipboard!", Color3.fromRGB(150, 100, 255))
    end)
end

print("✅ Mobile Remote Spy PRO Loaded!")
print("📡 Features: Replay, Edit, Filter, Favorites, Block, Export")
print("🔥 Enhanced by Claude - Ready to spy!")

showNotification("📡 Remote Spy PRO Active!", Color3.fromRGB(100, 255, 150))
