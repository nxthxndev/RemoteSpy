-- 🔥 ULTIMATE REMOTE SPY - ULTRA COMPATIBLE MOBILE 🔥
-- Cette version est conçue pour fonctionner même sur les exécuteurs mobiles limités.

local function safeGet(service)
    local success, s = pcall(game.GetService, game, service)
    return success and s or nil
end

local TweenService = safeGet("TweenService")
local UserInputService = safeGet("UserInputService")
local CoreGui = safeGet("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local HttpService = safeGet("HttpService")

-- Fallbacks pour les fonctions UNC (évite l'erreur "call a nil value")
local hookMeta = hookmetamethod or (debug and debug.setmetatable) or function() warn("hookmetamethod non supporté") end
local getMethod = getnamecallmethod or function() return "" end
local checkCaller = checkcaller or function() return false end
local newCClosure = newcclosure or function(f) return f end
local setClipboard = setclipboard or toclipboard or print

-- Variables globales
local remoteLog = {}
local isCapturing = true
local blockedRemotes = {}
local isMinimized = false

-- UI Creation (Sécurisée)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltraMobileSpy"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 50, 0, 50)
MinBtn.Position = UDim2.new(0, 10, 0, 10)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 150)
MinBtn.Text = "📡"
MinBtn.Visible = false
MinBtn.Parent = ScreenGui
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 15)
MainCorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Header.Parent = MainFrame
local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 15)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MOBILE SPY (SAFE)"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = Header

local function toggleMin()
    isMinimized = not isMinimized
    MainFrame.Visible = not isMinimized
    MinBtn.Visible = isMinimized
end

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 35, 0, 35)
HideBtn.Position = UDim2.new(1, -40, 0, 5)
HideBtn.Text = "—"
HideBtn.Parent = Header
HideBtn.MouseButton1Click:Connect(toggleMin)
MinBtn.MouseButton1Click:Connect(toggleMin)

-- List
local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, -20, 0, 180)
List.Position = UDim2.new(0, 10, 0, 55)
List.BackgroundTransparency = 1
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.Parent = MainFrame
local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 5)
ListLayout.Parent = List

-- Details
local Details = Instance.new("ScrollingFrame")
Details.Size = UDim2.new(1, -20, 0, 100)
Details.Position = UDim2.new(0, 10, 0, 245)
Details.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Details.Parent = MainFrame
local DetailsText = Instance.new("TextLabel")
DetailsText.Size = UDim2.new(1, -10, 1, 0)
DetailsText.Position = UDim2.new(0, 5, 0, 5)
DetailsText.BackgroundTransparency = 1
DetailsText.Text = "Logs..."
DetailsText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
DetailsText.TextSize = 10
DetailsText.TextWrapped = true
DetailsText.TextXAlignment = Enum.TextXAlignment.Left
DetailsText.TextYAlignment = Enum.TextYAlignment.Top
DetailsText.Parent = Details

-- Controls
local CapBtn = Instance.new("TextButton")
CapBtn.Size = UDim2.new(0.45, 0, 0, 35)
CapBtn.Position = UDim2.new(0, 10, 0, 355)
CapBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
CapBtn.Text = "SPY: ON"
CapBtn.Parent = MainFrame

local ClrBtn = Instance.new("TextButton")
ClrBtn.Size = UDim2.new(0.45, 0, 0, 35)
ClrBtn.Position = UDim2.new(0.55, -10, 0, 355)
ClrBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ClrBtn.Text = "CLEAR"
ClrBtn.Parent = MainFrame

-- Logic
local function addLog(name, type, args, path)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = " [" .. type .. "] " .. name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = List
    
    btn.MouseButton1Click:Connect(function()
        local s = "PATH: " .. path .. "\nARGS: "
        pcall(function()
            for i, v in ipairs(args) do s = s .. tostring(v) .. ", " end
        end)
        DetailsText.Text = s
        Details.CanvasSize = UDim2.new(0, 0, 0, DetailsText.TextBounds.Y + 10)
    end)
    List.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

-- Hook (Ultra Safe)
local success, err = pcall(function()
    local oldNamecall
    oldNamecall = hookMeta(game, "__namecall", newCClosure(function(self, ...)
        local method = getMethod()
        if (method == "FireServer" or method == "InvokeServer") and isCapturing and not checkCaller() then
            local name = tostring(self)
            local args = {...}
            local path = "Unknown"
            pcall(function() path = self:GetFullName() end)
            task.spawn(addLog, name, method:sub(1, 1), args, path)
        end
        return oldNamecall(self, ...)
    end))
end)

if not success then
    warn("Hook failed: " .. tostring(err))
    DetailsText.Text = "⚠️ Hook Error: Votre exécuteur ne supporte pas l'interception des Remotes."
end

-- Draggable (Safe)
local function makeDrag(f, h)
    local d, start, fstart
    h.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            d = true start = i.Position fstart = f.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - start
            f.Position = UDim2.new(fstart.X.Scale, fstart.X.Offset + delta.X, fstart.Y.Scale, fstart.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i) d = false end)
end

makeDrag(MainFrame, Header)
makeDrag(MinBtn, MinBtn)

CapBtn.MouseButton1Click:Connect(function()
    isCapturing = not isCapturing
    CapBtn.Text = isCapturing and "SPY: ON" or "SPY: OFF"
    CapBtn.BackgroundColor3 = isCapturing and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(150, 150, 150)
end)

ClrBtn.MouseButton1Click:Connect(function()
    for _, v in ipairs(List:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    DetailsText.Text = "Logs cleared."
end)

print("✅ ULTRA COMPATIBLE MOBILE SPY LOADED")

