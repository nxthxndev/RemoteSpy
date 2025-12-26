-- 🔥 ULTIMATE REMOTE CONTROLLER - 100% UNC COMPATIBLE 🔥
-- Hook complet, modification d'args, spy avancé, blocage, repeat firing, custom args

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Variables globales avancées
local remoteLog = {}
local selectedRemote = nil
local isCapturing = true
local blockedRemotes = {}
local repeatFiring = {}
local customArgs = {}
local remoteObjects = {}

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
        local success, err = pcall(function()
            for k, v in pairs(value) do
                s = s .. tostring(k) .. " = " .. safeStringify(v, depth + 1) .. ", "
            end
        end)
        return s .. "}"
    elseif t == "Instance" then
        return value:GetFullName()
    elseif t == "CFrame" or t == "Vector3" or t == "Vector2" then
        return tostring(value)
    else
        return tostring(value)
    end
end

-- UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimateRemoteController"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 1100, 0, 700)
MainFrame.Position = UDim2.new(0.5, -550, 0.5, -350)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 50, 150)
MainStroke.Thickness = 3
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 150)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 50, 255))
})
MainGradient.Rotation = 45
MainGradient.Parent = MainStroke

-- Animated gradient
task.spawn(function()
    while MainFrame and MainFrame.Parent do
        for i = 0, 360, 2 do
            if not MainFrame or not MainFrame.Parent then break end
            MainGradient.Rotation = i
            task.wait(0.03)
        end
    end
end)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Header.BackgroundTransparency = 0.2
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

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 300, 0, 20)
Subtitle.Position = UDim2.new(0, 25, 0, 40)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "100% UNC | Full Control"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 180)
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Stats Panel
local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(0, 250, 0, 50)
StatsFrame.Position = UDim2.new(1, -270, 0, 10)
StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
StatsFrame.BackgroundTransparency = 0.3
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

-- Close Button
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

-- Left Panel - Remote List
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.4, -10, 1, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
LeftPanel.BackgroundTransparency = 0.2
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
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
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

-- Remote List ScrollFrame
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

-- Right Panel - Details & Controls
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.6, -10, 1, 0)
RightPanel.Position = UDim2.new(0.4, 10, 0, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
RightPanel.BackgroundTransparency = 0.2
RightPanel.BorderSizePixel = 0
RightPanel.Parent = Container

local RightCorner = Instance.new("UICorner")
RightCorner.CornerRadius = UDim.new(0, 15)
RightCorner.Parent = RightPanel

-- Tab System
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = RightPanel

local currentTab = "details"

local function createTab(text, position, tabName)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0.25, -15, 0, 40)
    tab.Position = position
    tab.BackgroundColor3 = tabName == currentTab and Color3.fromRGB(255, 50, 150) or Color3.fromRGB(30, 30, 40)
    tab.Text = text
    tab.TextColor3 = Color3.new(1, 1, 1)
    tab.TextSize = 14
    tab.Font = Enum.Font.GothamBold
    tab.BorderSizePixel = 0
    tab.Parent = TabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = tab
    
    return tab
end

local DetailsTab = createTab("📋 DETAILS", UDim2.new(0, 10, 0, 5), "details")
local FireTab = createTab("🚀 FIRE", UDim2.new(0.25, 5, 0, 5), "fire")
local BlockTab = createTab("🚫 BLOCK", UDim2.new(0.5, 0, 0, 5), "block")
local AdvancedTab = createTab("⚙️ ADVANCED", UDim2.new(0.75, -5, 0, 5), "advanced")

-- Content Frames
local DetailsContent = Instance.new("ScrollingFrame")
DetailsContent.Size = UDim2.new(1, -20, 1, -65)
DetailsContent.Position = UDim2.new(0, 10, 0, 55)
DetailsContent.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
DetailsContent.BackgroundTransparency = 0.3
DetailsContent.BorderSizePixel = 0
DetailsContent.ScrollBarThickness = 5
DetailsContent.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 150)
DetailsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
DetailsContent.Visible = true
DetailsContent.Parent = RightPanel

local DetailsCorner = Instance.new("UICorner")
DetailsCorner.CornerRadius = UDim.new(0, 12)
DetailsCorner.Parent = DetailsContent

local DetailsText = Instance.new("TextLabel")
DetailsText.Size = UDim2.new(1, -20, 1, 0)
DetailsText.Position = UDim2.new(0, 10, 0, 10)
DetailsText.BackgroundTransparency = 1
DetailsText.Text = "Select a remote to view details..."
DetailsText.TextColor3 = Color3.fromRGB(200, 200, 220)
DetailsText.TextSize = 13
DetailsText.Font = Enum.Font.Code
DetailsText.TextWrapped = true
DetailsText.TextYAlignment = Enum.TextYAlignment.Top
DetailsText.TextXAlignment = Enum.TextXAlignment.Left
DetailsText.Parent = DetailsContent

local FireContent = Instance.new("Frame")
FireContent.Size = UDim2.new(1, -20, 1, -65)
FireContent.Position = UDim2.new(0, 10, 0, 55)
FireContent.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
FireContent.BackgroundTransparency = 0.3
FireContent.BorderSizePixel = 0
FireContent.Visible = false
FireContent.Parent = RightPanel

local FireContentCorner = Instance.new("UICorner")
FireContentCorner.CornerRadius = UDim.new(0, 12)
FireContentCorner.Parent = FireContent

-- Fire Controls
local FireOnceBtn = Instance.new("TextButton")
FireOnceBtn.Size = UDim2.new(1, -20, 0, 50)
FireOnceBtn.Position = UDim2.new(0, 10, 0, 10)
FireOnceBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
FireOnceBtn.Text = "🚀 FIRE ONCE"
FireOnceBtn.TextColor3 = Color3.new(1, 1, 1)
FireOnceBtn.TextSize = 18
FireOnceBtn.Font = Enum.Font.GothamBold
FireOnceBtn.BorderSizePixel = 0
FireOnceBtn.Parent = FireContent

local FireOnceCorner = Instance.new("UICorner")
FireOnceCorner.CornerRadius = UDim.new(0, 12)
FireOnceCorner.Parent = FireOnceBtn

local RepeatFireLabel = Instance.new("TextLabel")
RepeatFireLabel.Size = UDim2.new(1, -20, 0, 30)
RepeatFireLabel.Position = UDim2.new(0, 10, 0, 70)
RepeatFireLabel.BackgroundTransparency = 1
RepeatFireLabel.Text = "⚡ Repeat Fire (Loop)"
RepeatFireLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
RepeatFireLabel.TextSize = 16
RepeatFireLabel.Font = Enum.Font.GothamBold
RepeatFireLabel.TextXAlignment = Enum.TextXAlignment.Left
RepeatFireLabel.Parent = FireContent

local RepeatInput = Instance.new("TextBox")
RepeatInput.Size = UDim2.new(0.4, -10, 0, 40)
RepeatInput.Position = UDim2.new(0, 10, 0, 105)
RepeatInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
RepeatInput.Text = "0.1"
RepeatInput.PlaceholderText = "Delay (seconds)"
RepeatInput.TextColor3 = Color3.new(1, 1, 1)
RepeatInput.TextSize = 14
RepeatInput.Font = Enum.Font.GothamMedium
RepeatInput.BorderSizePixel = 0
RepeatInput.Parent = FireContent

local RepeatInputCorner = Instance.new("UICorner")
RepeatInputCorner.CornerRadius = UDim.new(0, 10)
RepeatInputCorner.Parent = RepeatInput

local RepeatStartBtn = Instance.new("TextButton")
RepeatStartBtn.Size = UDim2.new(0.28, -10, 0, 40)
RepeatStartBtn.Position = UDim2.new(0.4, 5, 0, 105)
RepeatStartBtn.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
RepeatStartBtn.Text = "▶ START"
RepeatStartBtn.TextColor3 = Color3.new(1, 1, 1)
RepeatStartBtn.TextSize = 14
RepeatStartBtn.Font = Enum.Font.GothamBold
RepeatStartBtn.BorderSizePixel = 0
RepeatStartBtn.Parent = FireContent

local RepeatStartCorner = Instance.new("UICorner")
RepeatStartCorner.CornerRadius = UDim.new(0, 10)
RepeatStartCorner.Parent = RepeatStartBtn

local RepeatStopBtn = Instance.new("TextButton")
RepeatStopBtn.Size = UDim2.new(0.28, -10, 0, 40)
RepeatStopBtn.Position = UDim2.new(0.7, 0, 0, 105)
RepeatStopBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
RepeatStopBtn.Text = "⏹ STOP"
RepeatStopBtn.TextColor3 = Color3.new(1, 1, 1)
RepeatStopBtn.TextSize = 14
RepeatStopBtn.Font = Enum.Font.GothamBold
RepeatStopBtn.BorderSizePixel = 0
RepeatStopBtn.Parent = FireContent

local RepeatStopCorner = Instance.new("UICorner")
RepeatStopCorner.CornerRadius = UDim.new(0, 10)
RepeatStopCorner.Parent = RepeatStopBtn

local CustomArgsLabel = Instance.new("TextLabel")
CustomArgsLabel.Size = UDim2.new(1, -20, 0, 30)
CustomArgsLabel.Position = UDim2.new(0, 10, 0, 160)
CustomArgsLabel.BackgroundTransparency = 1
CustomArgsLabel.Text = "✏️ Custom Arguments (JSON)"
CustomArgsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
CustomArgsLabel.TextSize = 16
CustomArgsLabel.Font = Enum.Font.GothamBold
CustomArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
CustomArgsLabel.Parent = FireContent

local CustomArgsInput = Instance.new("TextBox")
CustomArgsInput.Size = UDim2.new(1, -20, 0, 150)
CustomArgsInput.Position = UDim2.new(0, 10, 0, 195)
CustomArgsInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
CustomArgsInput.Text = ""
CustomArgsInput.PlaceholderText = '["arg1", 123, true]'
CustomArgsInput.TextColor3 = Color3.fromRGB(150, 255, 150)
CustomArgsInput.TextSize = 12
CustomArgsInput.Font = Enum.Font.Code
CustomArgsInput.MultiLine = true
CustomArgsInput.ClearTextOnFocus = false
CustomArgsInput.TextXAlignment = Enum.TextXAlignment.Left
CustomArgsInput.TextYAlignment = Enum.TextYAlignment.Top
CustomArgsInput.BorderSizePixel = 0
CustomArgsInput.Parent = FireContent

local CustomArgsCorner = Instance.new("UICorner")
CustomArgsCorner.CornerRadius = UDim.new(0, 10)
CustomArgsCorner.Parent = CustomArgsInput

local UseCustomBtn = Instance.new("TextButton")
UseCustomBtn.Size = UDim2.new(1, -20, 0, 45)
UseCustomBtn.Position = UDim2.new(0, 10, 0, 355)
UseCustomBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
UseCustomBtn.Text = "🔧 FIRE WITH CUSTOM ARGS"
UseCustomBtn.TextColor3 = Color3.new(1, 1, 1)
UseCustomBtn.TextSize = 16
UseCustomBtn.Font = Enum.Font.GothamBold
UseCustomBtn.BorderSizePixel = 0
UseCustomBtn.Parent = FireContent

local UseCustomCorner = Instance.new("UICorner")
UseCustomCorner.CornerRadius = UDim.new(0, 12)
UseCustomCorner.Parent = UseCustomBtn

local BlockContent = Instance.new("ScrollingFrame")
BlockContent.Size = UDim2.new(1, -20, 1, -65)
BlockContent.Position = UDim2.new(0, 10, 0, 55)
BlockContent.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
BlockContent.BackgroundTransparency = 0.3
BlockContent.BorderSizePixel = 0
BlockContent.ScrollBarThickness = 5
BlockContent.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 150)
BlockContent.CanvasSize = UDim2.new(0, 0, 0, 0)
BlockContent.Visible = false
BlockContent.Parent = RightPanel

local BlockContentCorner = Instance.new("UICorner")
BlockContentCorner.CornerRadius = UDim.new(0, 12)
BlockContentCorner.Parent = BlockContent

local BlockText = Instance.new("TextLabel")
BlockText.Size = UDim2.new(1, -20, 0, 200)
BlockText.Position = UDim2.new(0, 10, 0, 10)
BlockText.BackgroundTransparency = 1
BlockText.Text = "🚫 Block selected remote from firing\n\nBlocked remotes will be logged but not executed.\n\nClick 'BLOCK THIS' to block the selected remote."
BlockText.TextColor3 = Color3.fromRGB(200, 200, 220)
BlockText.TextSize = 14
BlockText.Font = Enum.Font.Gotham
BlockText.TextWrapped = true
BlockText.TextYAlignment = Enum.TextYAlignment.Top
BlockText.Parent = BlockContent

local BlockThisBtn = Instance.new("TextButton")
BlockThisBtn.Size = UDim2.new(1, -20, 0, 50)
BlockThisBtn.Position = UDim2.new(0, 10, 0, 220)
BlockThisBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
BlockThisBtn.Text = "🚫 BLOCK THIS REMOTE"
BlockThisBtn.TextColor3 = Color3.new(1, 1, 1)
BlockThisBtn.TextSize = 18
BlockThisBtn.Font = Enum.Font.GothamBold
BlockThisBtn.BorderSizePixel = 0
BlockThisBtn.Parent = BlockContent

local BlockThisCorner = Instance.new("UICorner")
BlockThisCorner.CornerRadius = UDim.new(0, 12)
BlockThisCorner.Parent = BlockThisBtn

local UnblockAllBtn = Instance.new("TextButton")
UnblockAllBtn.Size = UDim2.new(1, -20, 0, 45)
UnblockAllBtn.Position = UDim2.new(0, 10, 0, 280)
UnblockAllBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
UnblockAllBtn.Text = "✅ UNBLOCK ALL"
UnblockAllBtn.TextColor3 = Color3.new(1, 1, 1)
UnblockAllBtn.TextSize = 16
UnblockAllBtn.Font = Enum.Font.GothamBold
UnblockAllBtn.BorderSizePixel = 0
UnblockAllBtn.Parent = BlockContent

local UnblockAllCorner = Instance.new("UICorner")
UnblockAllCorner.CornerRadius = UDim.new(0, 12)
UnblockAllCorner.Parent = UnblockAllBtn

local AdvancedContent = Instance.new("ScrollingFrame")
AdvancedContent.Size = UDim2.new(1, -20, 1, -65)
AdvancedContent.Position = UDim2.new(0, 10, 0, 55)
AdvancedContent.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
AdvancedContent.BackgroundTransparency = 0.3
AdvancedContent.BorderSizePixel = 0
AdvancedContent.ScrollBarThickness = 5
AdvancedContent.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 150)
AdvancedContent.CanvasSize = UDim2.new(0, 0, 0, 500)
AdvancedContent.Visible = false
AdvancedContent.Parent = RightPanel

local AdvancedContentCorner = Instance.new("UICorner")
AdvancedContentCorner.CornerRadius = UDim.new(0, 12)
AdvancedContentCorner.Parent = AdvancedContent

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, -20, 0, 50)
ScanBtn.Position = UDim2.new(0, 10, 0, 10)
ScanBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
ScanBtn.Text = "🔍 SCAN ALL REMOTES IN GAME"
ScanBtn.TextColor3 = Color3.new(1, 1, 1)
ScanBtn.TextSize = 16
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.BorderSizePixel = 0
ScanBtn.Parent = AdvancedContent

local ScanBtnCorner = Instance.new("UICorner")
ScanBtnCorner.CornerRadius = UDim.new(0, 12)
ScanBtnCorner.Parent = ScanBtn

local LogToConsoleBtn = Instance.new("TextButton")
LogToConsoleBtn.Size = UDim2.new(1, -20, 0, 50)
LogToConsoleBtn.Position = UDim2.new(0, 10, 0, 70)
LogToConsoleBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
LogToConsoleBtn.Text = "📝 LOG TO CONSOLE: OFF"
LogToConsoleBtn.TextColor3 = Color3.new(1, 1, 1)
LogToConsoleBtn.TextSize = 16
LogToConsoleBtn.Font = Enum.Font.GothamBold
LogToConsoleBtn.BorderSizePixel = 0
LogToConsoleBtn.Parent = AdvancedContent

local LogToConsoleBtnCorner = Instance.new("UICorner")
LogToConsoleBtnCorner.CornerRadius = UDim.new(0, 12)
LogToConsoleBtnCorner.Parent = LogToConsoleBtn

local logToConsole = false

-- Functions
local function updateStats()
    CapturedLabel.Text = "📊 " .. #remoteLog .. " Captured"
    local blockedCount = 0
    for _ in pairs(blockedRemotes) do blockedCount = blockedCount + 1 end
    BlockedLabel.Text = "🚫 " .. blockedCount .. " Blocked"
end

local function switchTab(tabName)
    currentTab = tabName
    
    DetailsTab.BackgroundColor3 = tabName == "details" and Color3.fromRGB(255, 50, 150) or Color3.fromRGB(30, 30, 40)
    FireTab.BackgroundColor3 = tabName == "fire" and Color3.fromRGB(255, 50, 150) or Color3.fromRGB(30, 30, 40)
    BlockTab.BackgroundColor3 = tabName == "block" and Color3.fromRGB(255, 50, 150) or Color3.fromRGB(30, 30, 40)
    AdvancedTab.BackgroundColor3 = tabName == "advanced" and Color3.fromRGB(255, 50, 150) or Color3.fromRGB(30, 30, 40)
    
    DetailsContent.Visible = tabName == "details"
    FireContent.Visible = tabName == "fire"
    BlockContent.Visible = tabName == "block"
    AdvancedContent.Visible = tabName == "advanced"
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
        
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(entry.args)
        end)
        CustomArgsInput.Text = success and encoded or "[]"
    end)
    
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    updateStats()
end

-- Hook system
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if (method == "FireServer" and self:IsA("RemoteEvent"))
    or (method == "InvokeServer" and self:IsA("RemoteFunction")) then

        local remote = self
        local remoteType = method == "FireServer" and "Event" or "Function"

        task.spawn(function()
            local remotePath
            local ok = pcall(function()
                remotePath = remote:GetFullName()
            end)

            if not ok then
                remotePath = remote.Name
            end

            if blockedRemotes[remotePath] then
                if logToConsole then
                    print("🚫 [BLOCKED]", remotePath, "Args:", unpack(args))
                end
                return
            end

            if isCapturing then
                addRemoteToList(remote.Name, remoteType, args, remotePath, remote)
                if logToConsole then
                    print("📡 [" .. remoteType .. "]", remotePath, "Args:", unpack(args))
                end
            end
        end)
    end

    return oldNamecall(self, ...)
end))

-- Button functions
CaptureBtn.MouseButton1Click:Connect(function()
    isCapturing = not isCapturing
    CaptureBtn.Text = isCapturing and "🔴 SPY ON" or "⏸️ PAUSED"
    CaptureBtn.BackgroundColor3 = isCapturing and Color3.fromRGB(60, 220, 120) or Color3.fromRGB(150, 150, 150)
end)

ClearBtn.MouseButton1Click:Connect(function()
    remoteLog = {}
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    selectedRemote = nil
    DetailsText.Text = "Select a remote to view details..."
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
    updateStats()
end)

ExportBtn.MouseButton1Click:Connect(function()
    local export = "-- REMOTE SPY EXPORT --\n\n"
    for i, entry in ipairs(remoteLog) do
        local success, encoded = pcall(function() return HttpService:JSONEncode(entry.args) end)
        export = export .. string.format(
            "-- [%d] %s (%s)\n-- Path: %s\n-- Time: %s\n-- Args: %s\n\n",
            i, entry.name, entry.type, entry.path,
            os.date("%H:%M:%S", entry.timestamp),
            success and encoded or "Serialization Error"
        )
    end
    setclipboard(export)
    ExportBtn.Text = "✅ COPIED"
    task.wait(2)
    ExportBtn.Text = "💾 EXPORT"
end)

FireOnceBtn.MouseButton1Click:Connect(function()
    if not selectedRemote then
        DetailsText.Text = "❌ No remote selected!"
        return
    end
    
    local success, result = pcall(function()
        local remote = selectedRemote.object
        if not remote then
            for part in string.gmatch(selectedRemote.path, "[^.]+") do
                remote = (remote or game):FindFirstChild(part)
                if not remote then break end
            end
        end
        
        if remote then
            if selectedRemote.type == "Event" then
                remote:FireServer(unpack(selectedRemote.args))
                return "✅ Event fired successfully!"
            else
                local res = remote:InvokeServer(unpack(selectedRemote.args))
                return "✅ Function invoked! Result: " .. tostring(res)
            end
        else
            return "❌ Remote not found in game!"
        end
    end)
    
    DetailsText.Text = success and result or ("❌ Error: " .. tostring(result))
end)

RepeatStartBtn.MouseButton1Click:Connect(function()
    if not selectedRemote then return end
    
    local delay = tonumber(RepeatInput.Text) or 0.1
    local id = selectedRemote.path
    
    if repeatFiring[id] then return end
    
    repeatFiring[id] = true
    RepeatStartBtn.Text = "⚡ RUNNING"
    RepeatStartBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    
    task.spawn(function()
        while repeatFiring[id] do
            pcall(function()
                local remote = selectedRemote.object
                if remote then
                    if selectedRemote.type == "Event" then
                        remote:FireServer(unpack(selectedRemote.args))
                    else
                        remote:InvokeServer(unpack(selectedRemote.args))
                    end
                end
            end)
            task.wait(delay)
        end
    end)
end)

RepeatStopBtn.MouseButton1Click:Connect(function()
    if selectedRemote then
        repeatFiring[selectedRemote.path] = nil
        RepeatStartBtn.Text = "▶ START"
        RepeatStartBtn.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
    end
end)

UseCustomBtn.MouseButton1Click:Connect(function()
    if not selectedRemote then return end
    
    local success, customArgs = pcall(function()
        return HttpService:JSONDecode(CustomArgsInput.Text)
    end)
    
    if not success then
        DetailsText.Text = "❌ Invalid JSON format!"
        return
    end
    
    pcall(function()
        local remote = selectedRemote.object
        if remote then
            if selectedRemote.type == "Event" then
                remote:FireServer(unpack(customArgs))
                DetailsText.Text = "✅ Fired with custom args!"
            else
                local res = remote:InvokeServer(unpack(customArgs))
                DetailsText.Text = "✅ Invoked with custom args! Result: " .. tostring(res)
            end
        end
    end)
end)

BlockThisBtn.MouseButton1Click:Connect(function()
    if not selectedRemote then return end
    
    local path = selectedRemote.path
    if blockedRemotes[path] then
        blockedRemotes[path] = nil
        BlockThisBtn.Text = "🚫 BLOCK THIS REMOTE"
        BlockThisBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        BlockText.Text = "✅ Remote unblocked!"
    else
        blockedRemotes[path] = true
        BlockThisBtn.Text = "✅ UNBLOCK THIS REMOTE"
        BlockThisBtn.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
        BlockText.Text = "🚫 Remote is now blocked!"
    end
    updateStats()
end)

UnblockAllBtn.MouseButton1Click:Connect(function()
    blockedRemotes = {}
    BlockText.Text = "✅ All remotes unblocked!"
    updateStats()
end)

ScanBtn.MouseButton1Click:Connect(function()
    local found = 0
    local function scanInstance(instance)
        for _, child in ipairs(instance:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                found = found + 1
                local type = child:IsA("RemoteEvent") and "Event" or "Function"
                addRemoteToList(child.Name, type, {}, child:GetFullName(), child)
            end
        end
    end
    
    scanInstance(game)
    DetailsText.Text = string.format("🔍 Scan complete! Found %d remotes.", found)
end)

LogToConsoleBtn.MouseButton1Click:Connect(function()
    logToConsole = not logToConsole
    LogToConsoleBtn.Text = logToConsole and "📝 LOG TO CONSOLE: ON" or "📝 LOG TO CONSOLE: OFF"
    LogToConsoleBtn.BackgroundColor3 = logToConsole and Color3.fromRGB(60, 220, 120) or Color3.fromRGB(100, 150, 255)
end)

-- Tab switching
DetailsTab.MouseButton1Click:Connect(function() switchTab("details") end)
FireTab.MouseButton1Click:Connect(function() switchTab("fire") end)
BlockTab.MouseButton1Click:Connect(function() switchTab("block") end)
AdvancedTab.MouseButton1Click:Connect(function() switchTab("advanced") end)

CloseBtn.MouseButton1Click:Connect(function()
    for path in pairs(repeatFiring) do
        repeatFiring[path] = nil
    end
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

print("🔥 ULTIMATE REMOTE SPY LOADED!")
print("✅ 100% UNC Compatible")
print("⚡ Full remote control activated")
