if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local Shared = (function()
    local Success, Env = pcall(getgenv)
    return (Success and Env) or _G or (warn("[Shared]: Failed to access a usable global environment.") or {})
end)()

local function expect(expected, value, fallback)
    if type(value) == expected then
        return value
    end
    if fallback ~= nil then
        if type(fallback) == "function" then
            return function(...)
                return fallback(...)
            end
        end
    end
    return fallback
end

local cloneref = expect("function", cloneref, function(...) return ... end)
local WriteFile = expect("function", writefile, function() return end)
local ReadFile = expect("function", readfile, function() return "" end)
local IsFile = expect("function", isfile, function() return false end)
local IsFolder = expect("function", isfolder, function() return false end)
local MakeFolder = expect("function", makefolder, function() return end)
local DelFile = expect("function", delfile, function() return end)
local DelFolder = expect("function", delfolder, function() return end)
local ListFiles = expect("function", listfiles, function() return {} end)
local LoadFile = expect("function", getcustomasset, expect("function", getsynasset, nil))

local Services = setmetatable({}, {
    __index = function(self, name)
        local success, cache = pcall(function()
            return cloneref(game:GetService(name))
        end)
        if success then
            rawset(self, name, cache)
            return cache
        else
            error("Invalid Service: " .. tostring(name))
        end
    end
})

local StarterGui = Services.StarterGui

local function Warn(reason)
    local msg = tostring(reason)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "VoidUI: Error",
            Text = msg,
            Duration = 5
        })
    end)
    warn(msg)
end

local Success, Hui = pcall(function()
    return gethui and gethui()
end)

local CoreGui = Success and typeof(Hui) == "Instance" and Hui or Services.CoreGui 
local Players = Services.Players
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService

local Player = Players.LocalPlayer

if not IsFolder("VoidUI") then
    MakeFolder("VoidUI")
end

if IsFile("VoidUI/IsLoaded") and ReadFile("VoidUI/IsLoaded") == "true" then
    StarterGui:SetCore("SendNotification", {
        Title = "VoidUI",
        Text = "[VoidUI]: VoidUI is already running!",
        Duration = 4
    })
    return
end

WriteFile("VoidUI/IsLoaded", "true")

local function HttpGet(url)
    local RequestFunc = expect("function", syn and syn.request, 
        expect("function", request, 
            expect("function", http_request, nil)))
    
    if not RequestFunc then
        return nil
    end
    
    local success, result = pcall(function()
        return RequestFunc({
            Url = url,
            Method = "GET"
        })
    end)
    
    return success and result or nil
end

local function GetFile(url)
    if not LoadFile then
        Warn("[VoidUI]: No asset loading function available")
        return nil
    end

    if url:match("^rbxassetid://") then
        return url
    end

    local Path = "VoidUI/Assets/" .. url:gsub("[/:]", "_")

    if not IsFolder("VoidUI") then
        MakeFolder("VoidUI")
    end

    if not IsFolder("VoidUI/Assets") then
        MakeFolder("VoidUI/Assets")
    end

    if not IsFile(Path) then
        local success, Response = pcall(function()
            return HttpGet(url)
        end)

        if not success or not Response or not Response.Body then
            Warn("[VoidUI]: Failed to download asset: " .. url)
            return nil
        end

        WriteFile(Path, Response.Body)
    end

    return LoadFile(Path)
end

local function ParseColor(input)
    if type(input) == "string" then
        local r, g, b = input:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r and g and b then
            return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        end
    elseif typeof(input) == "Color3" then
        return input
    end
    Warn("[VoidUI]: Invalid color format: " .. tostring(input))
    return nil
end

local DevTheme = {
    Animations = true,
    BackgroundColor = "14, 14, 14",
    Accent = "110, 94, 253",
    Secondary = "29, 29, 29",
    TextColor = "255, 255, 255",
    NonSelectedTextColor = "141, 141, 141"
}

local SettingsData = "VoidUI/Settings.json"
local ThemeSettings = {
    Animations = true,
    BackgroundColor = "14, 14, 14",
    Accent = "110, 94, 253",
    Secondary = "29, 29, 29",
    TextColor = "255, 255, 255",
    NonSelectedTextColor = "141, 141, 141"
}

local IsDevTheme = true

local function SaveSettings()
    local data = {}
    for k, v in pairs(ThemeSettings) do
        data[k] = v
    end
    local success, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    if success then
        if not IsFolder("VoidUI") then
            MakeFolder("VoidUI")
        end
        pcall(function()
            WriteFile(SettingsData, encoded)
        end)
    end
end

local function LoadSettings()
    if not IsFile(SettingsData) then
        return
    end
    local success, content = pcall(function()
        return ReadFile(SettingsData)
    end)
    if not success or not content or content == "" then
        return
    end
    local ok, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    if ok and data then
        for k, v in pairs(data) do
            ThemeSettings[k] = v
        end
        IsDevTheme = false
    end
end

LoadSettings()

local Defaults = {
    BackgroundColor = ParseColor(ThemeSettings.BackgroundColor) or Color3.fromRGB(14, 14, 14),
    Accent = ParseColor(ThemeSettings.Accent) or Color3.fromRGB(110, 94, 253),
    Secondary = ParseColor(ThemeSettings.Secondary) or Color3.fromRGB(29, 29, 29),
    TextColor = ParseColor(ThemeSettings.TextColor) or Color3.fromRGB(255, 255, 255),
    NonSelectedTextColor = ParseColor(ThemeSettings.NonSelectedTextColor) or Color3.fromRGB(141, 141, 141)
}

local function Dragify(DragObject, MoveObject)
    MoveObject = MoveObject or DragObject

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    DragObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = MoveObject.AbsolutePosition

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    DragObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then
            return
        end

        local delta = input.Position - dragStart

        local parent = MoveObject.Parent
        local parentSize = parent.AbsoluteSize
        local objectSize = MoveObject.AbsoluteSize

        local padding = 3

        local newX = math.clamp(
            startPos.X + delta.X,
            padding,
            parentSize.X - objectSize.X - padding
        )

        local newY = math.clamp(
            startPos.Y + delta.Y,
            padding,
            parentSize.Y - objectSize.Y - padding
        )

        MoveObject.Position = UDim2.fromOffset(newX, newY)
    end)
end

local VoidUI = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VoidUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

ScreenGui.Destroying:Connect(function()
    pcall(function()
        WriteFile("VoidUI/IsLoaded", "false")
    end)
end)

local Show = Instance.new("TextButton")
Show.BackgroundColor3 = Defaults.BackgroundColor
Show.BorderSizePixel = 0
Show.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
Show.Name = "Show"
Show.Position = UDim2.new(0, 18, 0, 3)
Show.Size = UDim2.new(0, 38, 0, 38)
Show.Text = "V"
Show.TextColor3 = Defaults.Accent
Show.TextScaled = true
Show.TextWrapped = true
Show.Visible = false
Show.Parent = ScreenGui

local ShowCorner = Instance.new("UICorner")
ShowCorner.CornerRadius = UDim.new(0, 4)
ShowCorner.Parent = Show

local ShowRatio = Instance.new("UIAspectRatioConstraint")
ShowRatio.Parent = Show

local ShowStroke = Instance.new("UIStroke")
ShowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ShowStroke.Color = Defaults.Accent
ShowStroke.Parent = Show

local ShowIcon = Instance.new("ImageLabel")
ShowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
ShowIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ShowIcon.BackgroundTransparency = 1
ShowIcon.BorderColor3 = Color3.fromRGB(255, 255, 255)
ShowIcon.BorderSizePixel = 0
ShowIcon.Name = "ShowIcon"
ShowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
ShowIcon.Size = UDim2.new(1, -4, 1, -4)
ShowIcon.Visible = false
ShowIcon.Parent = Show

local Main = Instance.new("CanvasGroup")
Main.BackgroundColor3 = Defaults.BackgroundColor
Main.BorderSizePixel = 0
Main.GroupTransparency = 0
Main.Name = "Main"
Main.Position = UDim2.new(0, 60, 0, 2)
Main.Size = UDim2.new(0.7, 0, 0.9, 0)
Main.ZIndex = 2
Main.Visible = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 4)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Defaults.Accent
MainStroke.Parent = Main

local MainLayout = Instance.new("UIListLayout")
MainLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
MainLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
MainLayout.Parent = Main

local Topbar = Instance.new("Frame")
Topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Topbar.BackgroundTransparency = 1
Topbar.BorderSizePixel = 0
Topbar.LayoutOrder = 1
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0.1, 0)
Topbar.Parent = Main

local TopbarLayout = Instance.new("UIListLayout")
TopbarLayout.FillDirection = Enum.FillDirection.Horizontal
TopbarLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
TopbarLayout.Padding = UDim.new(0, 2)
TopbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
TopbarLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
TopbarLayout.Parent = Topbar

local Logo = Instance.new("Frame")
Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Logo.BackgroundTransparency = 1
Logo.BorderSizePixel = 0
Logo.LayoutOrder = 1
Logo.Name = "Logo"
Logo.Size = UDim2.new(0.2, 0, 1, 0)
Logo.Visible = false
Logo.Parent = Topbar

local LogoIcon = Instance.new("ImageLabel")
LogoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
LogoIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LogoIcon.BackgroundTransparency = 1
LogoIcon.BorderSizePixel = 0
LogoIcon.Image = ""
LogoIcon.Name = "LogoIcon"
LogoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
LogoIcon.Size = UDim2.new(1, 0, 1, 0)
LogoIcon.Parent = Logo

local LogoRatio = Instance.new("UIAspectRatioConstraint")
LogoRatio.Parent = Logo

local Title = Instance.new("TextLabel")
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
Title.LayoutOrder = 2
Title.Name = "Title"
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Text = "VoidUI Library"
Title.TextColor3 = Defaults.Accent
Title.TextScaled = true
Title.TextSize = 14
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

local TitlePadding = Instance.new("UIPadding")
TitlePadding.PaddingBottom = UDim.new(0, 4)
TitlePadding.PaddingLeft = UDim.new(0, 6)
TitlePadding.PaddingRight = UDim.new(0, 4)
TitlePadding.PaddingTop = UDim.new(0, 4)
TitlePadding.Parent = Title

local Hide = Instance.new("TextButton")
Hide.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Hide.BackgroundTransparency = 1
Hide.BorderSizePixel = 0
Hide.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
Hide.LayoutOrder = 3
Hide.Name = "Hide"
Hide.Size = UDim2.new(0.2, 0, 1, 0)
Hide.Text = "-"
Hide.TextColor3 = Defaults.Accent
Hide.TextScaled = true
Hide.TextWrapped = true
Hide.Parent = Topbar

local HideRatio = Instance.new("UIAspectRatioConstraint")
HideRatio.Parent = Hide

local Close = Instance.new("TextButton")
Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Close.BackgroundTransparency = 1
Close.BorderSizePixel = 0
Close.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
Close.LayoutOrder = 4
Close.Name = "Close"
Close.Size = UDim2.new(0.2, 0, 1, 0)
Close.Text = "×"
Close.TextColor3 = Defaults.Accent
Close.TextScaled = true
Close.TextWrapped = true
Close.Parent = Topbar

local CloseRatio = Instance.new("UIAspectRatioConstraint")
CloseRatio.Parent = Close

local Container = Instance.new("Frame")
Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.LayoutOrder = 2
Container.Name = "Container"
Container.Size = UDim2.new(1, 0, 0.9, 0)
Container.Parent = Main

local ContainerLayout = Instance.new("UIListLayout")
ContainerLayout.FillDirection = Enum.FillDirection.Horizontal
ContainerLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContainerLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
ContainerLayout.Parent = Container

local Sidebar = Instance.new("Frame")
Sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.LayoutOrder = 1
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0.25, 0, 1, 0)
Sidebar.Parent = Container

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingBottom = UDim.new(0, 4)
SidebarPadding.PaddingLeft = UDim.new(0, 4)
SidebarPadding.PaddingRight = UDim.new(0, 4)
SidebarPadding.PaddingTop = UDim.new(0, 4)
SidebarPadding.Parent = Sidebar

local Tabs = Instance.new("ScrollingFrame")
Tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Tabs.BackgroundTransparency = 1
Tabs.BorderSizePixel = 0
Tabs.CanvasSize = UDim2.new(0, 0, 0, 0)
Tabs.Name = "Tabs"
Tabs.ScrollBarThickness = 0
Tabs.ScrollingDirection = Enum.ScrollingDirection.Y
Tabs.Size = UDim2.new(1, 0, 1, 0)
Tabs.Parent = Sidebar

local TabsLayout = Instance.new("UIListLayout")
TabsLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
TabsLayout.Padding = UDim.new(0, 9)
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabsLayout.Parent = Tabs

local Pages = Instance.new("Frame")
Pages.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Pages.BackgroundTransparency = 1
Pages.BorderSizePixel = 0
Pages.LayoutOrder = 2
Pages.Name = "Pages"
Pages.Size = UDim2.new(0.75, 0, 1, 0)
Pages.Parent = Container

local PagesPadding = Instance.new("UIPadding")
PagesPadding.PaddingBottom = UDim.new(0, 4)
PagesPadding.PaddingLeft = UDim.new(0, 4)
PagesPadding.PaddingRight = UDim.new(0, 4)
PagesPadding.PaddingTop = UDim.new(0, 4)
PagesPadding.Parent = Pages

local function ApplyAccentColor(color)
    Defaults.Accent = color
    ThemeSettings.Accent = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
    
    Show.TextColor3 = color
    ShowStroke.Color = color
    Title.TextColor3 = color
    Hide.TextColor3 = color
    Close.TextColor3 = color
    MainStroke.Color = color
end

local function ApplySecondaryColor(color)
    Defaults.Secondary = color
    ThemeSettings.Secondary = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
end

local function ApplyTextColor(color)
    Defaults.TextColor = color
    ThemeSettings.TextColor = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
end

local function ApplyBackgroundColor(color)
    Defaults.BackgroundColor = color
    ThemeSettings.BackgroundColor = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
    
    Show.BackgroundColor3 = color
    Main.BackgroundColor3 = color
end

local function ApplyNonSelectedTextColor(color)
    Defaults.NonSelectedTextColor = color
    ThemeSettings.NonSelectedTextColor = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
end

local UserTabs = {}
local SettingsTab = nil
local FirstTab = nil

local function CreateContent()
    local sf = Instance.new("ScrollingFrame")
    sf.Active = true
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.ScrollBarThickness = 0
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.Parent = Pages

    local layout = Instance.new("UIListLayout")
    layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = sf

    return sf
end

local function SwitchTab(tabData)
    if not ThemeSettings.Animations then
        for _, data in pairs(UserTabs) do
            data.Content.Visible = false
            data.Underline.Size = UDim2.new(0, 0, 0, 2)
            data.Label.TextColor3 = Defaults.NonSelectedTextColor
        end
        
        if SettingsTab then
            SettingsTab.Content.Visible = false
            SettingsTab.Underline.Size = UDim2.new(0, 0, 0, 2)
            SettingsTab.Label.TextColor3 = Defaults.NonSelectedTextColor
        end
        
        tabData.Content.Visible = true
        tabData.Underline.Size = UDim2.new(1, 0, 0, 2)
        tabData.Label.TextColor3 = Defaults.Accent
        return
    end

    for _, data in pairs(UserTabs) do
        data.Content.Visible = false
        TweenService:Create(data.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 0, 2)
        }):Play()
        TweenService:Create(data.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextColor3 = Defaults.NonSelectedTextColor
        }):Play()
    end

    if SettingsTab then
        SettingsTab.Content.Visible = false
        TweenService:Create(SettingsTab.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 0, 2)
        }):Play()
        TweenService:Create(SettingsTab.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextColor3 = Defaults.NonSelectedTextColor
        }):Play()
    end

    tabData.Content.Visible = true
    TweenService:Create(tabData.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 2)
    }):Play()
    TweenService:Create(tabData.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextColor3 = Defaults.Accent
    }):Play()
end

local function ResetTheme()
    for k, v in pairs(DevTheme) do
        ThemeSettings[k] = v
    end
    IsDevTheme = true
    
    local bgColor = ParseColor(DevTheme.BackgroundColor) or Color3.fromRGB(14, 14, 14)
    local accentColor = ParseColor(DevTheme.Accent) or Color3.fromRGB(110, 94, 253)
    local secondaryColor = ParseColor(DevTheme.Secondary) or Color3.fromRGB(29, 29, 29)
    local textColor = ParseColor(DevTheme.TextColor) or Color3.fromRGB(255, 255, 255)
    local nonSelectedTextColor = ParseColor(DevTheme.NonSelectedTextColor) or Color3.fromRGB(141, 141, 141)
    
    ApplyAccentColor(accentColor)
    ApplySecondaryColor(secondaryColor)
    ApplyTextColor(textColor)
    ApplyBackgroundColor(bgColor)
    ApplyNonSelectedTextColor(nonSelectedTextColor)

    if SettingsTab and SettingsTab.Content then
        for _, child in ipairs(SettingsTab.Content:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("Color") then
                local textBox = child:FindFirstChildOfClass("TextBox")
                if textBox then
                    textBox.Text = ""
                end
            end
        end
    end
    
    pcall(function()
        DelFile(SettingsData)
    end)
end

local function CreateSettingsTab()
    local content = CreateContent()
    content.Visible = false

    local tabButton = Instance.new("TextButton")
    tabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.BackgroundTransparency = 1
    tabButton.BorderSizePixel = 0
    tabButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    tabButton.Name = "SettingsTab"
    tabButton.Size = UDim2.new(1, 0, 0, 24)
    tabButton.Text = ""
    tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    tabButton.TextSize = 14
    tabButton.LayoutOrder = 2147483647
    tabButton.Parent = Tabs

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    tabLayout.Parent = tabButton

    local tabLabel = Instance.new("TextLabel")
    tabLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabLabel.BackgroundTransparency = 1
    tabLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    tabLabel.LayoutOrder = 1
    tabLabel.Name = "TabLabel"
    tabLabel.Position = UDim2.new(0, 4, 0, 4)
    tabLabel.Size = UDim2.new(1, 0, 1, 0)
    tabLabel.Text = "Settings"
    tabLabel.TextColor3 = Defaults.NonSelectedTextColor
    tabLabel.TextScaled = true
    tabLabel.TextSize = 14
    tabLabel.TextWrapped = true
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    tabLabel.Parent = tabButton

    local tabLabelPadding = Instance.new("UIPadding")
    tabLabelPadding.PaddingBottom = UDim.new(0, 3)
    tabLabelPadding.PaddingTop = UDim.new(0, 3)
    tabLabelPadding.Parent = tabLabel

    local underline = Instance.new("Frame")
    underline.BackgroundColor3 = Defaults.Accent
    underline.BorderSizePixel = 0
    underline.LayoutOrder = 2
    underline.Name = "TabUnderline"
    underline.Size = UDim2.new(0, 0, 0, 2)
    underline.Parent = tabButton

    local underlineCorner = Instance.new("UICorner")
    underlineCorner.CornerRadius = UDim.new(0, 6)
    underlineCorner.Parent = underline

    local customizationLabel = Instance.new("TextLabel")
    customizationLabel.BackgroundColor3 = Defaults.Secondary
    customizationLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    customizationLabel.LayoutOrder = 1
    customizationLabel.Name = "CustomizationLabel"
    customizationLabel.Size = UDim2.new(1, 0, 0, 34)
    customizationLabel.Text = "Customization"
    customizationLabel.TextColor3 = Defaults.TextColor
    customizationLabel.TextSize = 16
    customizationLabel.TextWrapped = true
    customizationLabel.TextXAlignment = Enum.TextXAlignment.Left
    customizationLabel.Parent = content

    local customizationLabelCorner = Instance.new("UICorner")
    customizationLabelCorner.CornerRadius = UDim.new(0, 4)
    customizationLabelCorner.Parent = customizationLabel

    local customizationLabelPadding = Instance.new("UIPadding")
    customizationLabelPadding.PaddingBottom = UDim.new(0, 8)
    customizationLabelPadding.PaddingLeft = UDim.new(0, 8)
    customizationLabelPadding.PaddingRight = UDim.new(0, 8)
    customizationLabelPadding.PaddingTop = UDim.new(0, 8)
    customizationLabelPadding.Parent = customizationLabel

    local divider1 = Instance.new("Frame")
    divider1.BackgroundColor3 = Defaults.Accent
    divider1.BorderSizePixel = 0
    divider1.LayoutOrder = 2
    divider1.Name = "Divider1"
    divider1.Size = UDim2.new(1, 0, 0, 3)
    divider1.Parent = content

    local divider1Corner = Instance.new("UICorner")
    divider1Corner.CornerRadius = UDim.new(0, 4)
    divider1Corner.Parent = divider1

    local animsFrame = Instance.new("Frame")
    animsFrame.BackgroundColor3 = Defaults.Secondary
    animsFrame.BorderSizePixel = 0
    animsFrame.LayoutOrder = 3
    animsFrame.Name = "AnimsToggle"
    animsFrame.Size = UDim2.new(1, 0, 0, 34)
    animsFrame.Parent = content

    local animsFrameCorner = Instance.new("UICorner")
    animsFrameCorner.CornerRadius = UDim.new(0, 4)
    animsFrameCorner.Parent = animsFrame

    local animsLayout = Instance.new("UIListLayout")
    animsLayout.FillDirection = Enum.FillDirection.Horizontal
    animsLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    animsLayout.Padding = UDim.new(0, 4)
    animsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    animsLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    animsLayout.Parent = animsFrame

    local animsPadding = Instance.new("UIPadding")
    animsPadding.PaddingBottom = UDim.new(0, 5)
    animsPadding.PaddingLeft = UDim.new(0, 8)
    animsPadding.PaddingRight = UDim.new(0, 5)
    animsPadding.PaddingTop = UDim.new(0, 5)
    animsPadding.Parent = animsFrame

    local animsLabel = Instance.new("TextLabel")
    animsLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    animsLabel.BackgroundTransparency = 1
    animsLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    animsLabel.LayoutOrder = 1
    animsLabel.Name = "ToggleLabel"
    animsLabel.Size = UDim2.new(1, 0, 1, 0)
    animsLabel.Text = "Animations"
    animsLabel.TextColor3 = Defaults.TextColor
    animsLabel.TextSize = 16
    animsLabel.TextWrapped = true
    animsLabel.TextXAlignment = Enum.TextXAlignment.Left
    animsLabel.Parent = animsFrame

    local animsSwitch = Instance.new("Frame")
    animsSwitch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    animsSwitch.BackgroundTransparency = 1
    animsSwitch.BorderSizePixel = 0
    animsSwitch.LayoutOrder = 2
    animsSwitch.Name = "ToggleSwitch"
    animsSwitch.Size = UDim2.new(0.2, 0, 0.3, 0)
    animsSwitch.Parent = animsFrame

    local animsSwitchCorner = Instance.new("UICorner")
    animsSwitchCorner.CornerRadius = UDim.new(0, 4)
    animsSwitchCorner.Parent = animsSwitch

    local animsStroke = Instance.new("UIStroke")
    animsStroke.Color = Color3.fromRGB(63, 63, 63)
    animsStroke.Parent = animsSwitch

    local animsSwitchPadding = Instance.new("UIPadding")
    animsSwitchPadding.PaddingBottom = UDim.new(0, 2)
    animsSwitchPadding.PaddingLeft = UDim.new(0, 2)
    animsSwitchPadding.PaddingRight = UDim.new(0, 2)
    animsSwitchPadding.PaddingTop = UDim.new(0, 2)
    animsSwitchPadding.Parent = animsSwitch

    local animsKnob = Instance.new("Frame")
    animsKnob.AnchorPoint = Vector2.new(1, 0.5)
    animsKnob.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
    animsKnob.BorderSizePixel = 0
    animsKnob.Name = "Knob"
    animsKnob.Position = UDim2.new(0, 0, 0.5, 0)
    animsKnob.Size = UDim2.new(1, 0, 1, 0)
    animsKnob.Parent = animsSwitch

    local animsKnobCorner = Instance.new("UICorner")
    animsKnobCorner.CornerRadius = UDim.new(0, 4)
    animsKnobCorner.Parent = animsKnob

    local animsKnobRatio = Instance.new("UIAspectRatioConstraint")
    animsKnobRatio.Parent = animsKnob

    local animsOnPos = UDim2.new(1, 0, 0.5, 0)
    local animsOffPos = UDim2.new(0, animsKnob.AbsoluteSize.X, 0.5, 0)
    local animsOnColor = Defaults.Accent
    local animsOffColor = Color3.fromRGB(63, 63, 63)

    local function updateAnimsKnob()
        if ThemeSettings.Animations then
            TweenService:Create(animsKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = animsOnColor,
                Position = animsOnPos
            }):Play()
            TweenService:Create(animsStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = animsOnColor
            }):Play()
        else
            animsKnob.BackgroundColor3 = animsOffColor
            animsKnob.Position = animsOffPos
            animsStroke.Color = animsOffColor
        end
    end

    if ThemeSettings.Animations then
        animsKnob.Position = animsOffPos
        animsKnob.BackgroundColor3 = animsOffColor
        animsStroke.Color = animsOffColor
        task.wait()
        updateAnimsKnob()
    else
        animsKnob.Position = animsOffPos
        animsKnob.BackgroundColor3 = animsOffColor
        animsStroke.Color = animsOffColor
    end

    animsSwitch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            ThemeSettings.Animations = not ThemeSettings.Animations
            updateAnimsKnob()
            if not IsDevTheme then
                SaveSettings()
            end
        end
    end)

    local function CreateColorSetting(name, layoutOrder, defaultPlaceholder, applyFunc)
        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Defaults.Secondary
        frame.BorderSizePixel = 0
        frame.LayoutOrder = layoutOrder
        frame.Name = name .. "Color"
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content

        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Parent = frame

        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Parent = frame

        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Parent = frame

        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = "InputboxLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = name .. " (RGB)"
        label.TextColor3 = Defaults.TextColor
        label.TextSize = 16
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local textBox = Instance.new("TextBox")
        textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        textBox.BackgroundTransparency = 1
        textBox.BorderSizePixel = 0
        textBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        textBox.LayoutOrder = 2
        textBox.PlaceholderColor3 = Color3.fromRGB(141, 141, 141)
        textBox.PlaceholderText = defaultPlaceholder
        textBox.Size = UDim2.new(0.2, 0, 0.3, 0)
        textBox.Text = ""
        textBox.TextColor3 = Defaults.Accent
        textBox.TextScaled = true
        textBox.TextWrapped = true
        textBox.Parent = frame

        local textBoxCorner = Instance.new("UICorner")
        textBoxCorner.CornerRadius = UDim.new(0, 4)
        textBoxCorner.Parent = textBox

        local textBoxStroke = Instance.new("UIStroke")
        textBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        textBoxStroke.Color = Defaults.Accent
        textBoxStroke.Parent = textBox

        local textBoxPadding = Instance.new("UIPadding")
        textBoxPadding.PaddingBottom = UDim.new(0, 4)
        textBoxPadding.PaddingLeft = UDim.new(0, 4)
        textBoxPadding.PaddingRight = UDim.new(0, 4)
        textBoxPadding.PaddingTop = UDim.new(0, 4)
        textBoxPadding.Parent = textBox

        textBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local color
                if textBox.Text == "" then
                    color = ParseColor(defaultPlaceholder)
                else
                    color = ParseColor(textBox.Text)
                end
                if color then
                    applyFunc(color)
                    IsDevTheme = false
                    SaveSettings()
                end
            end
        end)

        return frame
    end

    CreateColorSetting("Background", 4, ThemeSettings.BackgroundColor, ApplyBackgroundColor)
    CreateColorSetting("Accent", 5, ThemeSettings.Accent, ApplyAccentColor)
    CreateColorSetting("Secondary", 6, ThemeSettings.Secondary, ApplySecondaryColor)
    CreateColorSetting("Text", 7, ThemeSettings.TextColor, ApplyTextColor)
    CreateColorSetting("Unselected Text", 8, ThemeSettings.NonSelectedTextColor, ApplyNonSelectedTextColor)

    local resetThemeButton = Instance.new("TextButton")
    resetThemeButton.BackgroundColor3 = Defaults.Secondary
    resetThemeButton.BorderSizePixel = 0
    resetThemeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    resetThemeButton.LayoutOrder = 9
    resetThemeButton.Name = "ResetThemeButton"
    resetThemeButton.Size = UDim2.new(1, 0, 0, 34)
    resetThemeButton.Text = "Reset Theme"
    resetThemeButton.TextColor3 = Defaults.TextColor
    resetThemeButton.TextSize = 16
    resetThemeButton.TextXAlignment = Enum.TextXAlignment.Left
    resetThemeButton.Parent = content

    local resetThemeButtonCorner = Instance.new("UICorner")
    resetThemeButtonCorner.CornerRadius = UDim.new(0, 4)
    resetThemeButtonCorner.Parent = resetThemeButton

    local resetThemeButtonPadding = Instance.new("UIPadding")
    resetThemeButtonPadding.PaddingBottom = UDim.new(0, 8)
    resetThemeButtonPadding.PaddingLeft = UDim.new(0, 8)
    resetThemeButtonPadding.PaddingRight = UDim.new(0, 8)
    resetThemeButtonPadding.PaddingTop = UDim.new(0, 8)
    resetThemeButtonPadding.Parent = resetThemeButton

    resetThemeButton.MouseButton1Click:Connect(ResetTheme)

    local tabData = {
        Content = content,
        Underline = underline,
        Label = tabLabel,
        Tab = tabButton
    }

    SettingsTab = tabData

    tabButton.MouseButton1Click:Connect(function()
        SwitchTab(tabData)
    end)

    return tabData
end

local ElementCreators = {
    Button = function(content, layoutOrder, config)
        if not config.Text then
            Warn("[VoidUI]: Button requires Text in config")
            return
        end

        local button = Instance.new("TextButton")
        button.BackgroundColor3 = Defaults.Secondary
        button.BorderSizePixel = 0
        button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        button.LayoutOrder = layoutOrder
        button.Name = "Button"
        button.Size = UDim2.new(1, 0, 0, 34)
        button.Text = config.Text
        button.TextColor3 = Defaults.TextColor
        button.TextSize = 16
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = content

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button

        local buttonPadding = Instance.new("UIPadding")
        buttonPadding.PaddingBottom = UDim.new(0, 8)
        buttonPadding.PaddingLeft = UDim.new(0, 8)
        buttonPadding.PaddingRight = UDim.new(0, 8)
        buttonPadding.PaddingTop = UDim.new(0, 8)
        buttonPadding.Parent = button

        if config.Callback then
            button.MouseButton1Click:Connect(config.Callback)
        end

        return button
    end,

    Toggle = function(content, layoutOrder, config)
        if not config.Text then
            Warn("[VoidUI]: Toggle requires Text in config")
            return
        end

        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Defaults.Secondary
        frame.BorderSizePixel = 0
        frame.LayoutOrder = layoutOrder
        frame.Name = "Toggle"
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content

        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Parent = frame

        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Parent = frame

        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Parent = frame

        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = "ToggleLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = config.Text
        label.TextColor3 = Defaults.TextColor
        label.TextSize = 16
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local toggleSwitch = Instance.new("Frame")
        toggleSwitch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleSwitch.BackgroundTransparency = 1
        toggleSwitch.BorderSizePixel = 0
        toggleSwitch.LayoutOrder = 2
        toggleSwitch.Name = "ToggleSwitch"
        toggleSwitch.Size = UDim2.new(0.2, 0, 0.3, 0)
        toggleSwitch.Parent = frame

        local toggleSwitchCorner = Instance.new("UICorner")
        toggleSwitchCorner.CornerRadius = UDim.new(0, 4)
        toggleSwitchCorner.Parent = toggleSwitch

        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(63, 63, 63)
        toggleStroke.Parent = toggleSwitch

        local toggleSwitchPadding = Instance.new("UIPadding")
        toggleSwitchPadding.PaddingBottom = UDim.new(0, 2)
        toggleSwitchPadding.PaddingLeft = UDim.new(0, 2)
        toggleSwitchPadding.PaddingRight = UDim.new(0, 2)
        toggleSwitchPadding.PaddingTop = UDim.new(0, 2)
        toggleSwitchPadding.Parent = toggleSwitch

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(1, 0.5)
        knob.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
        knob.BorderSizePixel = 0
        knob.Name = "Knob"
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.Size = UDim2.new(1, 0, 1, 0)
        knob.Parent = toggleSwitch

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 4)
        knobCorner.Parent = knob

        local knobRatio = Instance.new("UIAspectRatioConstraint")
        knobRatio.Parent = knob

        local enabled = config.Default or false
        local onPos = UDim2.new(1, 0, 0.5, 0)
        local offPos = UDim2.new(0, knob.AbsoluteSize.X, 0.5, 0)
        local onColor = Defaults.Accent
        local offColor = Color3.fromRGB(63, 63, 63)

        local function update()
            if ThemeSettings.Animations then
                TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = enabled and onColor or offColor,
                    Position = enabled and onPos or offPos
                }):Play()
                TweenService:Create(toggleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Color = enabled and onColor or offColor
                }):Play()
            else
                knob.BackgroundColor3 = enabled and onColor or offColor
                knob.Position = enabled and onPos or offPos
                toggleStroke.Color = enabled and onColor or offColor
            end
        end

        if enabled then
            knob.Position = onPos
            knob.BackgroundColor3 = onColor
            toggleStroke.Color = onColor
        else
            knob.Position = offPos
            knob.BackgroundColor3 = offColor
            toggleStroke.Color = offColor
        end

        toggleSwitch.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                enabled = not enabled
                update()
                if config.Callback then
                    config.Callback(enabled)
                end
            end
        end)

        return frame
    end,

    Slider = function(content, layoutOrder, config)
        if not config.Text then
            Warn("[VoidUI]: Slider requires Text in config")
            return
        end

        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Defaults.Secondary
        frame.BorderSizePixel = 0
        frame.LayoutOrder = layoutOrder
        frame.Name = "Slider"
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content

        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Parent = frame

        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Parent = frame

        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Parent = frame

        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = "SliderLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = config.Text
        label.TextColor3 = Defaults.TextColor
        label.TextSize = 16
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local thumb = Instance.new("CanvasGroup")
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BackgroundTransparency = 1
        thumb.BorderSizePixel = 0
        thumb.LayoutOrder = 2
        thumb.Name = "Thumb"
        thumb.Size = UDim2.new(0.2, 0, 0.3, 0)
        thumb.Parent = frame

        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(0, 4)
        thumbCorner.Parent = thumb

        local thumbStroke = Instance.new("UIStroke")
        thumbStroke.Color = Defaults.Accent
        thumbStroke.Parent = thumb

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.BackgroundColor3 = Defaults.Accent
        knob.BorderSizePixel = 0
        knob.Name = "Knob"
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.Size = UDim2.new(0, 0, 1, 0)
        knob.Parent = thumb

        local dragging = false
        local minValue = config.Min or 0
        local maxValue = config.Max or 100

        local function UpdateKnob(input)
            local relativeX = input.Position.X - thumb.AbsolutePosition.X
            local percent = math.clamp(relativeX / thumb.AbsoluteSize.X, 0, 1)
            local currentValue = minValue + (maxValue - minValue) * percent
            knob.Size = UDim2.fromScale(percent, 1)
            if config.Callback then
                config.Callback(currentValue)
            end
        end

        thumb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                UpdateKnob(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateKnob(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        return frame
    end,

    Inputbox = function(content, layoutOrder, config)
        if not config.Text then
            Warn("[VoidUI]: Inputbox requires Text in config")
            return
        end

        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Defaults.Secondary
        frame.BorderSizePixel = 0
        frame.LayoutOrder = layoutOrder
        frame.Name = "Inputbox"
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content

        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Parent = frame

        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Parent = frame

        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Parent = frame

        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = "InputboxLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = config.Text
        label.TextColor3 = Defaults.TextColor
        label.TextSize = 16
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local textBox = Instance.new("TextBox")
        textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        textBox.BackgroundTransparency = 1
        textBox.BorderSizePixel = 0
        textBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        textBox.LayoutOrder = 2
        textBox.PlaceholderColor3 = Color3.fromRGB(141, 141, 141)
        textBox.PlaceholderText = config.Placeholder or "Value..."
        textBox.Size = UDim2.new(0.2, 0, 0.3, 0)
        textBox.Text = ""
        textBox.TextColor3 = Defaults.Accent
        textBox.TextScaled = true
        textBox.TextWrapped = true
        textBox.Parent = frame

        local textBoxCorner = Instance.new("UICorner")
        textBoxCorner.CornerRadius = UDim.new(0, 4)
        textBoxCorner.Parent = textBox

        local textBoxStroke = Instance.new("UIStroke")
        textBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        textBoxStroke.Color = Defaults.Accent
        textBoxStroke.Parent = textBox

        local textBoxPadding = Instance.new("UIPadding")
        textBoxPadding.PaddingBottom = UDim.new(0, 4)
        textBoxPadding.PaddingLeft = UDim.new(0, 4)
        textBoxPadding.PaddingRight = UDim.new(0, 4)
        textBoxPadding.PaddingTop = UDim.new(0, 4)
        textBoxPadding.Parent = textBox

        if config.Callback then
            textBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    config.Callback(textBox.Text)
                end
            end)
        end

        return textBox
    end,

    Label = function(content, layoutOrder, config)
        if not config.Text then
            Warn("[VoidUI]: Label requires Text in config")
            return
        end

        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Defaults.Secondary
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = layoutOrder
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 0, 34)
        label.Text = config.Text
        label.TextColor3 = Defaults.TextColor
        label.TextSize = 16
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = content

        local labelCorner = Instance.new("UICorner")
        labelCorner.CornerRadius = UDim.new(0, 4)
        labelCorner.Parent = label

        local labelPadding = Instance.new("UIPadding")
        labelPadding.PaddingBottom = UDim.new(0, 8)
        labelPadding.PaddingLeft = UDim.new(0, 8)
        labelPadding.PaddingRight = UDim.new(0, 8)
        labelPadding.PaddingTop = UDim.new(0, 8)
        labelPadding.Parent = label

        return label
    end,

    Section = function(content, layoutOrder, config)
        if not config.Text then
            Warn("[VoidUI]: Section requires Text in config")
            return
        end

        local section = Instance.new("TextLabel")
        section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        section.BackgroundTransparency = 1
        section.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
        section.LayoutOrder = layoutOrder
        section.Name = "Section"
        section.Size = UDim2.new(1, 0, 0, 34)
        section.Text = config.Text
        section.TextColor3 = Defaults.Accent
        section.TextSize = 16
        section.TextWrapped = true
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.Parent = content

        local sectionPadding = Instance.new("UIPadding")
        sectionPadding.PaddingBottom = UDim.new(0, 0)
        sectionPadding.PaddingLeft = UDim.new(0, 8)
        sectionPadding.PaddingRight = UDim.new(0, 8)
        sectionPadding.PaddingTop = UDim.new(0, 0)
        sectionPadding.Parent = section

        return section
    end,

    Divider = function(content, layoutOrder, config)
        local divider = Instance.new("Frame")
        divider.BackgroundColor3 = Defaults.Accent
        divider.BorderSizePixel = 0
        divider.LayoutOrder = layoutOrder
        divider.Name = "Divider"
        divider.Size = UDim2.new(1, 0, 0, 3)
        divider.Parent = content

        local dividerCorner = Instance.new("UICorner")
        dividerCorner.CornerRadius = UDim.new(0, 4)
        dividerCorner.Parent = divider

        return divider
    end
}

function VoidUI:New(elementType, config)
    if type(elementType) ~= "string" then
        Warn("[VoidUI]: Invalid element type")
        return
    end

    if elementType == "Tab" then
        if not config or not config.Text then
            Warn("[VoidUI]: Tab requires Text in config")
            return
        end

        local tabName = config.Text
        if UserTabs[tabName] then
            return UserTabs[tabName]
        end

        local content = CreateContent()
        content.Visible = false

        local tabButton = Instance.new("TextButton")
        tabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.BackgroundTransparency = 1
        tabButton.BorderSizePixel = 0
        tabButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(1, 0, 0, 24)
        tabButton.Text = ""
        tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        tabButton.TextSize = 14
        tabButton.Parent = Tabs

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        tabLayout.Parent = tabButton

        local tabLabel = Instance.new("TextLabel")
        tabLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabLabel.BackgroundTransparency = 1
        tabLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        tabLabel.LayoutOrder = 1
        tabLabel.Name = "TabLabel"
        tabLabel.Position = UDim2.new(0, 4, 0, 4)
        tabLabel.Size = UDim2.new(1, 0, 1, 0)
        tabLabel.Text = tabName
        tabLabel.TextColor3 = Defaults.NonSelectedTextColor
        tabLabel.TextScaled = true
        tabLabel.TextSize = 14
        tabLabel.TextWrapped = true
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        tabLabel.Parent = tabButton

        local tabLabelPadding = Instance.new("UIPadding")
        tabLabelPadding.PaddingBottom = UDim.new(0, 3)
        tabLabelPadding.PaddingTop = UDim.new(0, 3)
        tabLabelPadding.Parent = tabLabel

        local underline = Instance.new("Frame")
        underline.BackgroundColor3 = Defaults.Accent
        underline.BorderSizePixel = 0
        underline.LayoutOrder = 2
        underline.Name = "TabUnderline"
        underline.Size = UDim2.new(0, 0, 0, 2)
        underline.Parent = tabButton

        local underlineCorner = Instance.new("UICorner")
        underlineCorner.CornerRadius = UDim.new(0, 6)
        underlineCorner.Parent = underline

        local tabData = {
            Content = content,
            Underline = underline,
            Label = tabLabel,
            Tab = tabButton
        }

        UserTabs[tabName] = tabData
        
        if not FirstTab then
            FirstTab = tabData
        end

        tabButton.MouseButton1Click:Connect(function()
            SwitchTab(tabData)
        end)

        return tabData
    end

    if not config or not config.Parent then
        Warn("[VoidUI]: Element requires Parent in config")
        return
    end

    local parentTab = config.Parent
    local content = parentTab.Content
    local layoutOrder = #content:GetChildren() + 1

    local creator = ElementCreators[elementType]
    if creator then
        return creator(content, layoutOrder, config)
    else
        Warn("[VoidUI]: Unknown element type: " .. elementType)
    end
end

function VoidUI:SetTitle(newTitle)
    Title.Text = tostring(newTitle)
end

function VoidUI:SetLogo(image)
    if not image then
        Warn("[VoidUI]: No image provided for SetLogo")
        return
    end
    local asset = GetFile(image)
    if asset then
        Logo.Visible = true
        LogoIcon.Image = asset
        ShowIcon.Visible = true
        ShowIcon.Image = asset
        Show.Text = ""
    end
end

function VoidUI:SetTheme(theme)
    if not theme then
        Warn("[VoidUI]: No theme table provided for SetTheme")
        return
    end
    
    for k, v in pairs(theme) do
        DevTheme[k] = v
    end
    
    if theme.Accent then
        local color = ParseColor(theme.Accent)
        if color then
            ApplyAccentColor(color)
        end
    end
    if theme.Secondary then
        local color = ParseColor(theme.Secondary)
        if color then
            ApplySecondaryColor(color)
        end
    end
    if theme.TextColor then
        local color = ParseColor(theme.TextColor)
        if color then
            ApplyTextColor(color)
        end
    end
    if theme.BackgroundColor then
        local color = ParseColor(theme.BackgroundColor)
        if color then
            ApplyBackgroundColor(color)
        end
    end
    if theme.NonSelectedTextColor then
        local color = ParseColor(theme.NonSelectedTextColor)
        if color then
            ApplyNonSelectedTextColor(color)
        end
    end
    
    if not IsDevTheme then
        SaveSettings()
    end
end

SettingsTab = CreateSettingsTab()

Dragify(Show)
Dragify(Topbar, Main)

local function HideMain()
    if ThemeSettings.Animations then
        Main.Visible = true
        Show.Visible = false
        local slideOut = TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            GroupTransparency = 1,
            Position = UDim2.new(0, Main.Position.X.Offset + 100, 0, Main.Position.Y.Offset)
        })
        slideOut:Play()
        slideOut.Completed:Wait()
        Main.Visible = false
        Show.Visible = true
        Main.Position = UDim2.new(0, 60, 0, 2)
        Main.GroupTransparency = 1
    else
        Main.Visible = false
        Show.Visible = true
    end
end

local function ShowMain()
    if ThemeSettings.Animations then
        Main.Visible = true
        Show.Visible = false
        Main.GroupTransparency = 1
        Main.Position = UDim2.new(0, Main.Position.X.Offset + 100, 0, Main.Position.Y.Offset)
        TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            GroupTransparency = 0,
            Position = UDim2.new(0, 60, 0, 2)
        }):Play()
    else
        Main.Visible = true
        Show.Visible = false
        Main.GroupTransparency = 0
    end
end

Hide.MouseButton1Click:Connect(HideMain)
Show.MouseButton1Click:Connect(ShowMain)

Close.MouseButton1Click:Connect(function()
    if ThemeSettings.Animations then
        local slideOut = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            GroupTransparency = 1,
            Position = UDim2.new(0, Main.Position.X.Offset + 100, 0, Main.Position.Y.Offset)
        })
        slideOut:Play()
        slideOut.Completed:Wait()
    end
    ScreenGui:Destroy()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer ~= Player then
        return
    end

    if IsFolder("VoidUI") then
        pcall(function()
            DelFolder("VoidUI")
        end)
    end
end)

if FirstTab then
    repeat task.wait() until Tabs.AbsoluteSize.X > 0 and Tabs.AbsoluteSize.Y > 0
    SwitchTab(FirstTab)
end

return VoidUI
