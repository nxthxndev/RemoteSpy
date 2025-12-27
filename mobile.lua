-- 🔥 ULTIMATE MOBILE REMOTE SPY - RESTORED & FIXED
-- Version complète avec design original + correctif "Capability Plugin"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

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

-- Variables
local remoteLog = {}
local isCapturing = true
local selectedEntry = nil
local isMinimized = false
local uiQueue = {}

-- Fonction utilitaire
local function safeStringify(value)
    local t = typeof(value)
    if t == "Instance" then
        local s, name = pcall(function() return value:GetFullName() end)
        return s and name or tostring(value)
    elseif t == "table" then
        local str = "{"
        pcall(function()
            local count = 0
            for k, v in pairs(value) do
                count = count + 1
                if count > 15 then str = str .. "..." break end
                str = str .. tostring(k) .. "=" .. tostring(v) .. ", "
            end
        end)
        return str .. "}"
    else
        return tostring(value)
    end
end

-- === UI CREATION (DESIGN ORIGINAL RESTAURÉ) ===
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
MainFrame.Size = UDim2.new(0, 340, 0, 480)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -240)
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
Title.Text = "📡 MOBILE SPY"
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

local RemoteList = Instance.new("ScrollingFrame")
RemoteList.Size = UDim2.new(1, -20, 0, 220)
RemoteList.Position = UDim2.new(0, 10, 0, 60)
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
DetailsPanel.Position = UDim2.new(0, 10, 0, 290)
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

local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -20, 0, 45)
ButtonContainer.Position = UDim2.new(0, 10, 0, 430)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

local function createButton(text, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 1, 0)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.Parent = ButtonContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    return btn
end

local CaptureBtn = createButton("🔴 SPY ON", UDim2.new(0, 0, 0, 0), Color3.fromRGB(60, 200, 120))
local ClearBtn = createButton("🗑️ CLEAR", UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(200, 60, 60))

-- === FONCTIONS ===
local function updateCounter()
    CounterLabel.Text = tostring(#remoteLog)
end

local function formatArgs(args)
    if not args or #args == 0 then return "No arguments" end
    local result = ""
    for i, arg in ipairs(args) do
        result = result .. string.format("[%d] %s\n", i, safeStringify(arg))
    end
    return result
end

local function createRemoteItemUI(data)
    local entry = data.entry
    local Item = Instance.new("TextButton")
    Item.Size = UDim2.new(1, -10, 0, 55)
    Item.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Item.BorderSizePixel = 0
    Item.Text = ""
    Item.AutoButtonColor = false
    Item.LayoutOrder = -math.floor(entry.time * 100)
    Item.Parent = RemoteList
    
    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 10)
    ItemCorner.Parent = Item
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -70, 0, 22)
    NameLabel.Position = UDim2.new(0, 10, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = "🔹 " .. data.name
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Item
    
    local TypeBadge = Instance.new("TextLabel")
    TypeBadge.Size = UDim2.new(0, 55, 0, 20)
    TypeBadge.Position = UDim2.new(1, -60, 0, 8)
    TypeBadge.BackgroundColor3 = data.type == "Event" and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(255, 120, 50)
    TypeBadge.Text = data.type:sub(1, 3):upper()
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
    PathLabel.Position = UDim2.new(0, 10, 0, 32)
    PathLabel.BackgroundTransparency = 1
    PathLabel.Text = data.path
    PathLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    PathLabel.TextSize = 9
    PathLabel.Font = Enum.Font.Gotham
    PathLabel.TextXAlignment = Enum.TextXAlignment.Left
    PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    PathLabel.Parent = Item
    
    Item.MouseButton1Click:Connect(function()
        selectedEntry = entry
        for _, child in ipairs(RemoteList:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            end
        end
        Item.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        
        DetailsText.Text = string.format(
            "Name: %s\nType: %s\nPath: %s\nTime: %s\n\nArguments:\n%s",
            data.name, data.type, data.path,
            os.date("%H:%M:%S", entry.time),
            formatArgs(entry.args)
        )
        DetailsPanel.CanvasSize = UDim2.new(0, 0, 0, DetailsText.TextBounds.Y + 20)
    end)
    
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end

-- Processeur de file
RunService.Heartbeat:Connect(function()
    if #uiQueue > 0 then
        local data = table.remove(uiQueue, 1)
        pcall(createRemoteItemUI, data)
    end
end)

-- === LE HOOK (CORRECTIF CAPABILITY) ===
if hasHook then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newCC(function(self, ...)
        local method = getNamecall()
        
        if isCapturing and not checkCaller() and (method == "FireServer" or method == "InvokeServer") then
            -- EXTRACTION SYNCHRONE (Évite l'erreur Plugin Capability)
            local rName = tostring(self.Name)
            local rType = self:IsA("RemoteEvent") and "Event" or "Function"
            local rPath = ""
            local s, p = pcall(function() return self:GetFullName() end)
            rPath = s and p or rName
            
            local args = {...}
            local entry = {args = args, time = tick()}
            
            table.insert(remoteLog, 1, entry)
            if #remoteLog > 100 then table.remove(remoteLog, #remoteLog) end
            
            table.insert(uiQueue, {name = rName, type = rType, path = rPath, entry = entry})
            updateCounter()
        end
        
        return oldNamecall(self, ...)
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
    CaptureBtn.Text = isCapturing and "🔴 SPY ON" or "⏸️ PAUSED"
    CaptureBtn.BackgroundColor3 = isCapturing and Color3.fromRGB(60, 200, 120) or Color3.fromRGB(150, 150, 150)
    StatusLabel.Text = isCapturing and "✅ Active" or "⏸️ Paused"
end)

ClearBtn.MouseButton1Click:Connect(function()
    remoteLog = {}
    uiQueue = {}
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    selectedEntry = nil
    DetailsText.Text = "💡 Logs cleared!"
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
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

print("✅ Mobile Remote Spy Restored & Fixed")
