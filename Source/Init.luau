if not game:IsLoaded() then
  game.Loaded:Wait()
end

local Shared = (function()
  local Success, Env = pcall(getgenv)
  return (Success and Env) or _G or (warn("[Shared]: Failed to access a usable global environment.") or {})
end)()

local function GetService(Service)
  return cloneref(game:GetService(Service))
end

local Hui = (gethui and gethui()) or GetService("CoreGui")
local TweenService = GetService("TweenService")
local Players = GetService("Players")
local UserInputService = GetService("UserInputService")
local StarterGui = GetService("StarterGui")

local function Tween(Object, Speed, Properties, EasingStyle, EasingDirection)
  if EasingStyle == nil then
    EasingStyle = "Quad"
  end
  if EasingDirection == nil then
    EasingDirection = "Out"
  end
  local TweenInformation = TweenInfo.new(Speed, Enum.EasingStyle[EasingStyle], Enum.EasingDirection[EasingDirection])
  return TweenService:Create(Object, TweenInformation, Properties)
end

local function UID(Length)
  local Chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local Id = table.create(Length)
  for i = 1, Length do
    local Index = math.random(#Chars)
    Id[i] = Chars:sub(Index, Index)
  end
  return table.concat(Id)
end

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

local WriteFile = expect("function", writefile, function() return end)
local ReadFile = expect("function", readfile, function() return "" end)
local IsFile = expect("function", isfile, function() return false end)
local IsFolder = expect("function", isfolder, function() return false end)
local MakeFolder = expect("function", makefolder, function() return end)
local DelFile = expect("function", delfile, function() return end)
local DelFolder = expect("function", delfolder, function() return end)
local ListFiles = expect("function", listfiles, function() return {} end)
local LoadFile = expect("function", getcustomasset, expect("function", getsynasset, nil))

local VoidNotifs = loadstring(game.HttpGetAsync and game:HttpGetAsync("https://raw.githubusercontent.com/JustSomeGuest/VoidUI/Stable/Source/Notify.luau") or game:HttpGet("https://raw.githubusercontent.com/JustSomeGuest/VoidUI/Stable/Source/Notify.luau"))()

Shared.VoidUI = Shared.VoidUI or {}

if Shared.VoidUI.IsLoaded then
    StarterGui:SetCore("SendNotification", {
        Title = "VoidUI",
        Text = "VoidUI is already running!",
        Duration = 4
    })
    return
end

Shared.VoidUI.IsLoaded = true

local function Warn(reason)
    local msg = tostring(reason)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Duration = 5,
            Text = msg,
            Title = "VoidUI: Error"
        })
    end)
    warn(msg)
end

local Player = Players.LocalPlayer

if not IsFolder("VoidUI") then
    MakeFolder("VoidUI")
end

local function HttpGet(url)
    local RequestFunc = expect("function", syn and syn.request, 
        expect("function", request, 
            expect("function", http_request, nil)))
    if not RequestFunc then
        return nil
    end
    local success, result = pcall(function()
        return RequestFunc({
            Method = "GET",
            Url = url
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

local CustomTheme = {
    Accent = "110, 94, 253",
    BackgroundColor = "14, 14, 14",
    NonSelectedTextColor = "141, 141, 141",
    Secondary = "29, 29, 29",
    TextColor = "255, 255, 255"
}

local SettingsData = "VoidUI/Settings.json"
local ThemeSettings = {
    Accent = "110, 94, 253",
    BackgroundColor = "14, 14, 14",
    NonSelectedTextColor = "141, 141, 141",
    Secondary = "29, 29, 29",
    TextColor = "255, 255, 255"
}

local IsCustomTheme = true

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
        IsCustomTheme = false
    end
end

LoadSettings()

local Defaults = {
    Accent = ParseColor(ThemeSettings.Accent) or Color3.fromRGB(110, 94, 253),
    BackgroundColor = ParseColor(ThemeSettings.BackgroundColor) or Color3.fromRGB(14, 14, 14),
    NonSelectedTextColor = ParseColor(ThemeSettings.NonSelectedTextColor) or Color3.fromRGB(141, 141, 141),
    Secondary = ParseColor(ThemeSettings.Secondary) or Color3.fromRGB(29, 29, 29),
    TextColor = ParseColor(ThemeSettings.TextColor) or Color3.fromRGB(255, 255, 255)
}

local SettingsRegistry = {}
local ElementRegistry = {}

local function Dragify(DragObject, MoveObject)
    MoveObject = MoveObject or DragObject
    local dragInput
    local dragStart
    local dragging = false
    local startPos
    DragObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            dragging = true
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
        local objectSize = MoveObject.AbsoluteSize
        local parent = MoveObject.Parent
        local parentSize = parent.AbsoluteSize
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
ScreenGui.DisplayOrder = 2147483646
ScreenGui.Name = UID(32)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Hui

ScreenGui.Destroying:Connect(function()
    Shared.VoidUI.IsLoaded = false
end)

local HasLogo = false

local Main = Instance.new("CanvasGroup")
Main.BackgroundColor3 = Defaults.BackgroundColor
Main.BorderSizePixel = 0
Main.GroupTransparency = 0
Main.Name = UID(32)
Main.Position = UDim2.new(0, 16, 0, 4)
Main.Size = UDim2.new(0.7, 0, 0.89, 0)
Main.Visible = true
Main.ZIndex = 2
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 4)
MainCorner.Name = UID(32)
MainCorner.Parent = Main

local MainLayout = Instance.new("UIListLayout")
MainLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
MainLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
MainLayout.Name = UID(32)
MainLayout.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Defaults.Accent
MainStroke.Name = UID(32)
MainStroke.Parent = Main

local Shadow = Instance.new("UIShadow")
Shadow.BlurRadius = UDim.new(0, 24)
Shadow.Color = CustomTheme.Accent
Shadow.Name = UID(32)
Shadow.Offset = UDim2.fromOffset(0, 0)
Shadow.Spread = UDim2.fromOffset(7, 7)
Shadow.Transparency = 0.25
Shadow.Parent = Main

local Topbar = Instance.new("Frame")
Topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Topbar.BackgroundTransparency = 1
Topbar.BorderSizePixel = 0
Topbar.LayoutOrder = 1
Topbar.Name = UID(32)
Topbar.Size = UDim2.new(0, 430, 0, 30)
Topbar.Parent = Main

local TopbarConstraint = Instance.new("UISizeConstraint")
TopbarConstraint.MinSize = Vector2.new(0, 34)
TopbarConstraint.MaxSize = Vector2.new(math.huge, 34)
TopbarConstraint.Name = UID(32)
TopbarConstraint.Parent = Topbar

local TopbarLayout = Instance.new("UIListLayout")
TopbarLayout.FillDirection = Enum.FillDirection.Horizontal
TopbarLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
TopbarLayout.Padding = UDim.new(0, 4)
TopbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
TopbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TopbarLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
TopbarLayout.Name = UID(32)
TopbarLayout.Parent = Topbar

local TopbarPadding = Instance.new("UIPadding")
TopbarPadding.PaddingBottom = UDim.new(0, 2)
TopbarPadding.PaddingLeft = UDim.new(0, 6)
TopbarPadding.PaddingRight = UDim.new(0, 2)
TopbarPadding.PaddingTop = UDim.new(0, 2)
TopbarPadding.Name = UID(32)
TopbarPadding.Parent = Topbar

local Logo = Instance.new("Frame")
Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Logo.BackgroundTransparency = 1
Logo.BorderSizePixel = 0
Logo.LayoutOrder = 1
Logo.Name = UID(32)
Logo.Size = UDim2.new(0.2, 0, 1, 0)
Logo.Visible = false
Logo.Parent = Topbar

local LogoIcon = Instance.new("ImageLabel")
LogoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
LogoIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LogoIcon.BackgroundTransparency = 1
LogoIcon.BorderSizePixel = 0
LogoIcon.Image = ""
LogoIcon.Name = UID(32)
LogoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
LogoIcon.Size = UDim2.new(1, 0, 1, 0)
LogoIcon.Parent = Logo

local LogoRatio = Instance.new("UIAspectRatioConstraint")
LogoRatio.Name = UID(32)
LogoRatio.Parent = Logo

local LogoConstraint = Instance.new("UISizeConstraint")
LogoConstraint.MinSize = Vector2.new(0, 28)
LogoConstraint.MaxSize = Vector2.new(math.huge, 28)
LogoConstraint.Name = UID(32)
LogoConstraint.Parent = Logo

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 4)
LogoCorner.Name = UID(32)
LogoCorner.Parent = Logo

local Title = Instance.new("TextLabel")
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
Title.LayoutOrder = 2
Title.Name = UID(32)
Title.Size = UDim2.new(0, 0, 1, 0)
Title.Text = "VoidUI"
Title.TextColor3 = Defaults.Accent
Title.TextScaled = false
Title.TextSize = 22
Title.TextTruncate = Enum.TextTruncate.AtEnd
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 0, 0, -2)
Title.Parent = Topbar

local Toggle = Instance.new("TextButton")
Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Toggle.BackgroundTransparency = 1
Toggle.BorderSizePixel = 0
Toggle.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
Toggle.LayoutOrder = 3
Toggle.Name = UID(32)
Toggle.Size = UDim2.new(0.2, 0, 1, 0)
Toggle.Text = ""
Toggle.TextColor3 = Defaults.Accent
Toggle.TextScaled = true
Toggle.TextWrapped = true
Toggle.Parent = Topbar

local TogglePadding = Instance.new("UIPadding")
TogglePadding.PaddingTop = UDim.new(0, 2)
TogglePadding.PaddingRight = UDim.new(0, 2)
TogglePadding.PaddingBottom = UDim.new(0, 2)
TogglePadding.Name = UID(32)
TogglePadding.Parent = Toggle

local ToggleRatio = Instance.new("UIAspectRatioConstraint")
ToggleRatio.Name = UID(32)
ToggleRatio.Parent = Toggle

local ToggleFrame = Instance.new("Frame")
ToggleFrame.BorderSizePixel = 0
ToggleFrame.BackgroundColor3 = Defaults.Accent
ToggleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleFrame.Size = UDim2.new(0, 2, 1, 0)
ToggleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
ToggleFrame.Name = UID(32)
ToggleFrame.Rotation = 90
ToggleFrame.Parent = Toggle

local ToggleFrameCorner = Instance.new("UICorner")
ToggleFrameCorner.CornerRadius = UDim.new(0, 4)
ToggleFrameCorner.Name = UID(32)
ToggleFrameCorner.Parent = ToggleFrame

local ToggleFrame2 = Instance.new("Frame")
ToggleFrame2.BorderSizePixel = 0
ToggleFrame2.BackgroundColor3 = Defaults.Accent
ToggleFrame2.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleFrame2.Size = UDim2.new(0, 2, 1, 0)
ToggleFrame2.Position = UDim2.new(0.5, 0, 0.5, 0)
ToggleFrame2.Name = UID(32)
ToggleFrame2.Rotation = 0
ToggleFrame2.Parent = ToggleFrame

local ToggleFrame2Corner = Instance.new("UICorner")
ToggleFrame2Corner.CornerRadius = UDim.new(0, 4)
ToggleFrame2Corner.Name = UID(32)
ToggleFrame2Corner.Parent = ToggleFrame2

local Container = Instance.new("Frame")
Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.LayoutOrder = 2
Container.Name = UID(32)
Container.Size = UDim2.new(1, 0, 0.9, 0)
Container.Parent = Main

local ContainerLayout = Instance.new("UIListLayout")
ContainerLayout.FillDirection = Enum.FillDirection.Horizontal
ContainerLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContainerLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
ContainerLayout.Name = UID(32)
ContainerLayout.Parent = Container

local Pages = Instance.new("Frame")
Pages.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Pages.BackgroundTransparency = 1
Pages.BorderSizePixel = 0
Pages.LayoutOrder = 2
Pages.Name = UID(32)
Pages.Size = UDim2.new(0.75, 0, 1, 0)
Pages.Parent = Container

local PagesPadding = Instance.new("UIPadding")
PagesPadding.PaddingBottom = UDim.new(0, 4)
PagesPadding.PaddingLeft = UDim.new(0, 4)
PagesPadding.PaddingRight = UDim.new(0, 4)
PagesPadding.PaddingTop = UDim.new(0, 4)
PagesPadding.Name = UID(32)
PagesPadding.Parent = Pages

local Sidebar = Instance.new("Frame")
Sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.LayoutOrder = 1
Sidebar.Name = UID(32)
Sidebar.Size = UDim2.new(0.25, 0, 1, 0)
Sidebar.Parent = Container

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
SidebarLayout.Name = UID(32)
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingBottom = UDim.new(0, 4)
SidebarPadding.PaddingLeft = UDim.new(0, 4)
SidebarPadding.PaddingRight = UDim.new(0, 4)
SidebarPadding.PaddingTop = UDim.new(0, 4)
SidebarPadding.Name = UID(32)
SidebarPadding.Parent = Sidebar

local Tabs = Instance.new("ScrollingFrame")
Tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Tabs.BackgroundTransparency = 1
Tabs.BorderSizePixel = 0
Tabs.CanvasSize = UDim2.new(0, 0, 0, 0)
Tabs.Name = UID(32)
Tabs.ScrollBarThickness = 0
Tabs.ScrollingDirection = Enum.ScrollingDirection.Y
Tabs.Size = UDim2.new(1, 0, 1, 0)
Tabs.Parent = Sidebar

local TabsLayout = Instance.new("UIListLayout")
TabsLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
TabsLayout.Padding = UDim.new(0, 9)
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabsLayout.Name = UID(32)
TabsLayout.Parent = Tabs

local UserTabs = {}
local SettingsTab = nil
local FirstTab = nil
local ColorBoxes = {}

local MainClosed = false
local SavedTitle = Title.Text
local MainTweening = false
local OpenSize = Main.Size
local OpenPos = Main.Position
local ClosedPos = Main.Position

local UpdateSettingsTabColors
local UpdateUserTabsColors

local function ApplyAccentColor(color)
    Defaults.Accent = color
    ThemeSettings.Accent = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
    MainStroke.Color = color
    Title.TextColor3 = color
    ToggleFrame.BackgroundColor3 = color
    ToggleFrame2.BackgroundColor3 = color
    for _, tabData in pairs(UserTabs) do
        tabData.Underline.BackgroundColor3 = color
    end
    if SettingsTab then
        SettingsTab.Underline.BackgroundColor3 = color
    end
    UpdateSettingsTabColors()
    UpdateUserTabsColors()
end

local function ApplyBackgroundColor(color)
    Defaults.BackgroundColor = color
    ThemeSettings.BackgroundColor = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
    Main.BackgroundColor3 = color
end

local function ApplyNonSelectedTextColor(color)
    Defaults.NonSelectedTextColor = color
    ThemeSettings.NonSelectedTextColor = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
    for _, tabData in pairs(UserTabs) do
        if tabData.Content and not tabData.Content.Visible then
            tabData.Label.TextColor3 = color
        end
    end
    if SettingsTab and SettingsTab.Content and not SettingsTab.Content.Visible then
        SettingsTab.Label.TextColor3 = color
    end
end

local function ApplySecondaryColor(color)
    Defaults.Secondary = color
    ThemeSettings.Secondary = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
    UpdateSettingsTabColors()
    UpdateUserTabsColors()
end

local function ApplyTextColor(color)
    Defaults.TextColor = color
    ThemeSettings.TextColor = string.format("%d, %d, %d", color.R * 255, color.G * 255, color.B * 255)
    UpdateSettingsTabColors()
    UpdateUserTabsColors()
end

local function UpdateColorPlaceholders()
    for key, textBox in pairs(ColorBoxes) do
        if textBox and CustomTheme[key] then
            textBox.PlaceholderText = CustomTheme[key]
        end
    end
end

function UpdateSettingsTabColors()
    for _, entry in ipairs(SettingsRegistry) do
        if entry.Type == "ColorSetting" then
            entry.Frame.BackgroundColor3 = Defaults.Secondary
            entry.Label.TextColor3 = Defaults.TextColor
            entry.TextBox.PlaceholderColor3 = Defaults.NonSelectedTextColor
            entry.TextBox.TextColor3 = Defaults.Accent
            entry.Stroke.Color = Defaults.Accent
        elseif entry.Type == "Divider" then
            entry.Frame.BackgroundColor3 = Defaults.Accent
        elseif entry.Type == "Label" then
            entry.Label.BackgroundColor3 = Defaults.Secondary
            entry.Label.TextColor3 = Defaults.TextColor
        elseif entry.Type == "Button" then
            entry.Button.BackgroundColor3 = Defaults.Secondary
            entry.Button.TextColor3 = Defaults.TextColor
        end
    end
end

function UpdateUserTabsColors()
    for _, entry in ipairs(ElementRegistry) do
        if entry.Type == "Divider" then
            entry.Frame.BackgroundColor3 = Defaults.Accent
        elseif entry.Type == "Inputbox" then
            entry.Frame.BackgroundColor3 = Defaults.Secondary
            entry.Label.TextColor3 = Defaults.TextColor
            entry.TextBox.TextColor3 = Defaults.Accent
            entry.Stroke.Color = Defaults.Accent
        elseif entry.Type == "Slider" then
            entry.Frame.BackgroundColor3 = Defaults.Secondary
            entry.Knob.BackgroundColor3 = Defaults.Accent
            entry.Stroke.Color = Defaults.Accent
            entry.Label.TextColor3 = Defaults.TextColor
        elseif entry.Type == "Toggle" then
            entry.Frame.BackgroundColor3 = Defaults.Secondary
            entry.Label.TextColor3 = Defaults.TextColor
        elseif entry.Type == "Button" then
            entry.Frame.BackgroundColor3 = Defaults.Secondary
            entry.Frame.TextColor3 = Defaults.TextColor
        elseif entry.Type == "Label" then
            entry.Frame.BackgroundColor3 = Defaults.Secondary
            entry.Frame.TextColor3 = Defaults.TextColor
        elseif entry.Type == "Section" then
            entry.Frame.TextColor3 = Defaults.Accent
        end
    end
end

local function CreateContent()
    local sf = Instance.new("ScrollingFrame")
    sf.Active = true
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.Name = UID(32)
    sf.ScrollBarThickness = 0
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.Parent = Pages
    local layout = Instance.new("UIListLayout")
    layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Name = UID(32)
    layout.Parent = sf
    return sf
end

local function SwitchTab(tabData)
    for _, data in pairs(UserTabs) do
        data.Content.Visible = false
        TweenService:Create(data.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextColor3 = Defaults.NonSelectedTextColor
        }):Play()
        TweenService:Create(data.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 0, 2)
        }):Play()
    end
    if SettingsTab then
        SettingsTab.Content.Visible = false
        TweenService:Create(SettingsTab.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextColor3 = Defaults.NonSelectedTextColor
        }):Play()
        TweenService:Create(SettingsTab.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 0, 0, 2)
        }):Play()
    end
    tabData.Content.Visible = true
    TweenService:Create(tabData.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextColor3 = Defaults.Accent
    }):Play()
    TweenService:Create(tabData.Underline, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 2)
    }):Play()
end

local function ResetTheme()
    for k, v in pairs(CustomTheme) do
        ThemeSettings[k] = v
    end
    IsCustomTheme = true
    local accentColor = ParseColor(CustomTheme.Accent) or Color3.fromRGB(110, 94, 253)
    local bgColor = ParseColor(CustomTheme.BackgroundColor) or Color3.fromRGB(14, 14, 14)
    local nonSelectedTextColor = ParseColor(CustomTheme.NonSelectedTextColor) or Color3.fromRGB(141, 141, 141)
    local secondaryColor = ParseColor(CustomTheme.Secondary) or Color3.fromRGB(29, 29, 29)
    local textColor = ParseColor(CustomTheme.TextColor) or Color3.fromRGB(255, 255, 255)
    ApplyAccentColor(accentColor)
    ApplyBackgroundColor(bgColor)
    ApplyNonSelectedTextColor(nonSelectedTextColor)
    ApplySecondaryColor(secondaryColor)
    ApplyTextColor(textColor)
    for _, entry in ipairs(SettingsRegistry) do
        if entry.Type == "ColorSetting" then
            entry.TextBox.Text = ""
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
    tabButton.LayoutOrder = 2147483647
    tabButton.Name = UID(32)
    tabButton.Size = UDim2.new(1, 0, 0, 24)
    tabButton.Text = ""
    tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    tabButton.TextSize = 14
    tabButton.Parent = Tabs
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    tabLayout.Name = UID(32)
    tabLayout.Parent = tabButton
    local tabLabel = Instance.new("TextLabel")
    tabLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabLabel.BackgroundTransparency = 1
    tabLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    tabLabel.LayoutOrder = 1
    tabLabel.Name = UID(32)
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
    tabLabelPadding.Name = UID(32)
    tabLabelPadding.Parent = tabLabel
    local underline = Instance.new("Frame")
    underline.BackgroundColor3 = Defaults.Accent
    underline.BorderSizePixel = 0
    underline.LayoutOrder = 2
    underline.Name = UID(32)
    underline.Size = UDim2.new(0, 0, 0, 2)
    underline.Parent = tabButton
    local underlineCorner = Instance.new("UICorner")
    underlineCorner.CornerRadius = UDim.new(0, 6)
    underlineCorner.Name = UID(32)
    underlineCorner.Parent = underline
    local customizationLabel = Instance.new("TextLabel")
    customizationLabel.BackgroundColor3 = Defaults.Secondary
    customizationLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    customizationLabel.LayoutOrder = 1
    customizationLabel.Name = UID(32)
    customizationLabel.Size = UDim2.new(1, 0, 0, 34)
    customizationLabel.Text = "Customization"
    customizationLabel.TextColor3 = Defaults.TextColor
    customizationLabel.TextSize = 16
    customizationLabel.TextWrapped = true
    customizationLabel.TextXAlignment = Enum.TextXAlignment.Left
    customizationLabel.Parent = content
    local customizationLabelCorner = Instance.new("UICorner")
    customizationLabelCorner.CornerRadius = UDim.new(0, 4)
    customizationLabelCorner.Name = UID(32)
    customizationLabelCorner.Parent = customizationLabel
    local customizationLabelPadding = Instance.new("UIPadding")
    customizationLabelPadding.PaddingBottom = UDim.new(0, 8)
    customizationLabelPadding.PaddingLeft = UDim.new(0, 8)
    customizationLabelPadding.PaddingRight = UDim.new(0, 8)
    customizationLabelPadding.PaddingTop = UDim.new(0, 8)
    customizationLabelPadding.Name = UID(32)
    customizationLabelPadding.Parent = customizationLabel
    table.insert(SettingsRegistry, {Type = "Label", Label = customizationLabel})
    local divider1 = Instance.new("Frame")
    divider1.BackgroundColor3 = Defaults.Accent
    divider1.BorderSizePixel = 0
    divider1.LayoutOrder = 2
    divider1.Name = UID(32)
    divider1.Size = UDim2.new(1, 0, 0, 3)
    divider1.Parent = content
    local divider1Corner = Instance.new("UICorner")
    divider1Corner.CornerRadius = UDim.new(0, 4)
    divider1Corner.Name = UID(32)
    divider1Corner.Parent = divider1
    table.insert(SettingsRegistry, {Type = "Divider", Frame = divider1})
    local function CreateColorSetting(name, layoutOrder, key, applyFunc)
        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Defaults.Secondary
        frame.BorderSizePixel = 0
        frame.LayoutOrder = layoutOrder
        frame.Name = UID(32)
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Name = UID(32)
        frameCorner.Parent = frame
        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Name = UID(32)
        frameLayout.Parent = frame
        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Name = UID(32)
        framePadding.Parent = frame
        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = UID(32)
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
        textBox.PlaceholderColor3 = Defaults.NonSelectedTextColor
        textBox.PlaceholderText = CustomTheme[key]
        textBox.Name = UID(32)
        textBox.Size = UDim2.new(0.2, 0, 0.3, 0)
        textBox.Text = ""
        textBox.TextColor3 = Defaults.Accent
        textBox.TextScaled = true
        textBox.TextWrapped = true
        textBox.Parent = frame
        local textBoxCorner = Instance.new("UICorner")
        textBoxCorner.CornerRadius = UDim.new(0, 4)
        textBoxCorner.Name = UID(32)
        textBoxCorner.Parent = textBox
        local textBoxPadding = Instance.new("UIPadding")
        textBoxPadding.PaddingBottom = UDim.new(0, 4)
        textBoxPadding.PaddingLeft = UDim.new(0, 4)
        textBoxPadding.PaddingRight = UDim.new(0, 4)
        textBoxPadding.PaddingTop = UDim.new(0, 4)
        textBoxPadding.Name = UID(32)
        textBoxPadding.Parent = textBox
        local textBoxStroke = Instance.new("UIStroke")
        textBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        textBoxStroke.Color = Defaults.Accent
        textBoxStroke.Name = UID(32)
        textBoxStroke.Parent = textBox
        textBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local color
                if textBox.Text == "" then
                    color = ParseColor(CustomTheme[key])
                else
                    color = ParseColor(textBox.Text)
                end
                if color then
                    applyFunc(color)
                    IsCustomTheme = false
                    SaveSettings()
                end
            end
        end)
        ColorBoxes[key] = textBox
        table.insert(SettingsRegistry, {
            Type = "ColorSetting",
            Frame = frame,
            Label = label,
            TextBox = textBox,
            Stroke = textBoxStroke
        })
        return frame
    end
    CreateColorSetting("Accent", 5, "Accent", ApplyAccentColor)
    CreateColorSetting("Background", 4, "BackgroundColor", ApplyBackgroundColor)
    CreateColorSetting("Secondary", 6, "Secondary", ApplySecondaryColor)
    CreateColorSetting("Text", 7, "TextColor", ApplyTextColor)
    CreateColorSetting("Unselected Text", 8, "NonSelectedTextColor", ApplyNonSelectedTextColor)
    local resetThemeButton = Instance.new("TextButton")
    resetThemeButton.BackgroundColor3 = Defaults.Secondary
    resetThemeButton.BorderSizePixel = 0
    resetThemeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    resetThemeButton.LayoutOrder = 9
    resetThemeButton.Name = UID(32)
    resetThemeButton.Size = UDim2.new(1, 0, 0, 34)
    resetThemeButton.Text = "Reset Theme"
    resetThemeButton.TextColor3 = Defaults.TextColor
    resetThemeButton.TextSize = 16
    resetThemeButton.TextXAlignment = Enum.TextXAlignment.Left
    resetThemeButton.Parent = content
    local resetThemeButtonCorner = Instance.new("UICorner")
    resetThemeButtonCorner.CornerRadius = UDim.new(0, 4)
    resetThemeButtonCorner.Name = UID(32)
    resetThemeButtonCorner.Parent = resetThemeButton
    local resetThemeButtonPadding = Instance.new("UIPadding")
    resetThemeButtonPadding.PaddingBottom = UDim.new(0, 8)
    resetThemeButtonPadding.PaddingLeft = UDim.new(0, 8)
    resetThemeButtonPadding.PaddingRight = UDim.new(0, 8)
    resetThemeButtonPadding.PaddingTop = UDim.new(0, 8)
    resetThemeButtonPadding.Name = UID(32)
    resetThemeButtonPadding.Parent = resetThemeButton
    resetThemeButton.MouseButton1Click:Connect(ResetTheme)
    table.insert(SettingsRegistry, {Type = "Button", Button = resetThemeButton})
    local tabData = {
        Content = content,
        Label = tabLabel,
        Tab = tabButton,
        Underline = underline
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
        button.Name = UID(32)
        button.Size = UDim2.new(1, 0, 0, 34)
        button.Text = config.Text
        button.TextColor3 = Defaults.TextColor
        button.TextSize = 16
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = content
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Name = UID(32)
        buttonCorner.Parent = button
        local buttonPadding = Instance.new("UIPadding")
        buttonPadding.PaddingBottom = UDim.new(0, 8)
        buttonPadding.PaddingLeft = UDim.new(0, 8)
        buttonPadding.PaddingRight = UDim.new(0, 8)
        buttonPadding.PaddingTop = UDim.new(0, 8)
        buttonPadding.Name = UID(32)
        buttonPadding.Parent = button
        if config.Callback then
            button.MouseButton1Click:Connect(config.Callback)
        end
        table.insert(ElementRegistry, {Type = "Button", Frame = button})
        return button
    end,

    Divider = function(content, layoutOrder, config)
        local divider = Instance.new("Frame")
        divider.BackgroundColor3 = Defaults.Accent
        divider.BorderSizePixel = 0
        divider.LayoutOrder = layoutOrder
        divider.Name = UID(32)
        divider.Size = UDim2.new(1, 0, 0, 3)
        divider.Parent = content
        local dividerCorner = Instance.new("UICorner")
        dividerCorner.CornerRadius = UDim.new(0, 4)
        dividerCorner.Name = UID(32)
        dividerCorner.Parent = divider
        table.insert(ElementRegistry, {Type = "Divider", Frame = divider})
        return divider
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
        frame.Name = UID(32)
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Name = UID(32)
        frameCorner.Parent = frame
        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Name = UID(32)
        frameLayout.Parent = frame
        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Name = UID(32)
        framePadding.Parent = frame
        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = UID(32)
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
        textBox.Name = UID(32)
        textBox.Size = UDim2.new(0.2, 0, 0.3, 0)
        textBox.Text = ""
        textBox.TextColor3 = Defaults.Accent
        textBox.TextScaled = true
        textBox.TextWrapped = true
        textBox.Parent = frame
        local textBoxCorner = Instance.new("UICorner")
        textBoxCorner.CornerRadius = UDim.new(0, 4)
        textBoxCorner.Name = UID(32)
        textBoxCorner.Parent = textBox
        local textBoxPadding = Instance.new("UIPadding")
        textBoxPadding.PaddingBottom = UDim.new(0, 4)
        textBoxPadding.PaddingLeft = UDim.new(0, 4)
        textBoxPadding.PaddingRight = UDim.new(0, 4)
        textBoxPadding.PaddingTop = UDim.new(0, 4)
        textBoxPadding.Name = UID(32)
        textBoxPadding.Parent = textBox
        local textBoxStroke = Instance.new("UIStroke")
        textBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        textBoxStroke.Color = Defaults.Accent
        textBoxStroke.Name = UID(32)
        textBoxStroke.Parent = textBox
        if config.Callback then
            textBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    config.Callback(textBox.Text)
                end
            end)
        end
        table.insert(ElementRegistry, {
            Type = "Inputbox",
            Frame = frame,
            Label = label,
            TextBox = textBox,
            Stroke = textBoxStroke
        })
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
        label.Name = UID(32)
        label.Size = UDim2.new(1, 0, 0, 34)
        label.Text = config.Text
        label.TextColor3 = Defaults.TextColor
        label.TextSize = 16
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = content
        local labelCorner = Instance.new("UICorner")
        labelCorner.CornerRadius = UDim.new(0, 4)
        labelCorner.Name = UID(32)
        labelCorner.Parent = label
        local labelPadding = Instance.new("UIPadding")
        labelPadding.PaddingBottom = UDim.new(0, 8)
        labelPadding.PaddingLeft = UDim.new(0, 8)
        labelPadding.PaddingRight = UDim.new(0, 8)
        labelPadding.PaddingTop = UDim.new(0, 8)
        labelPadding.Name = UID(32)
        labelPadding.Parent = label
        table.insert(ElementRegistry, {Type = "Label", Frame = label})
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
        section.Name = UID(32)
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
        sectionPadding.Name = UID(32)
        sectionPadding.Parent = section
        table.insert(ElementRegistry, {Type = "Section", Frame = section})
        return section
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
        frame.Name = UID(32)
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Name = UID(32)
        frameCorner.Parent = frame
        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Name = UID(32)
        frameLayout.Parent = frame
        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Name = UID(32)
        framePadding.Parent = frame
        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = UID(32)
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
        thumb.Name = UID(32)
        thumb.Size = UDim2.new(0.2, 0, 0.3, 0)
        thumb.Parent = frame
        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(0, 4)
        thumbCorner.Name = UID(32)
        thumbCorner.Parent = thumb
        local thumbStroke = Instance.new("UIStroke")
        thumbStroke.Color = Defaults.Accent
        thumbStroke.Name = UID(32)
        thumbStroke.Parent = thumb
        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.BackgroundColor3 = Defaults.Accent
        knob.BorderSizePixel = 0
        knob.Name = UID(32)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.Size = UDim2.new(0, 0, 1, 0)
        knob.Parent = thumb
        local dragging = false
        local maxValue = config.Max or 100
        local minValue = config.Min or 0
        local function UpdateKnob(input)
            local percent = math.clamp((input.Position.X - thumb.AbsolutePosition.X) / thumb.AbsoluteSize.X, 0, 1)
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
        table.insert(ElementRegistry, {
            Type = "Slider",
            Frame = frame,
            Label = label,
            Knob = knob,
            Stroke = thumbStroke
        })
        return frame
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
        frame.Name = UID(32)
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.Parent = content
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Name = UID(32)
        frameCorner.Parent = frame
        local frameLayout = Instance.new("UIListLayout")
        frameLayout.FillDirection = Enum.FillDirection.Horizontal
        frameLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Padding = UDim.new(0, 4)
        frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        frameLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        frameLayout.Name = UID(32)
        frameLayout.Parent = frame
        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingBottom = UDim.new(0, 5)
        framePadding.PaddingLeft = UDim.new(0, 8)
        framePadding.PaddingRight = UDim.new(0, 5)
        framePadding.PaddingTop = UDim.new(0, 5)
        framePadding.Name = UID(32)
        framePadding.Parent = frame
        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        label.LayoutOrder = 1
        label.Name = UID(32)
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
        toggleSwitch.Name = UID(32)
        toggleSwitch.Size = UDim2.new(0.2, 0, 0.3, 0)
        toggleSwitch.Parent = frame
        local toggleSwitchCorner = Instance.new("UICorner")
        toggleSwitchCorner.CornerRadius = UDim.new(0, 4)
        toggleSwitchCorner.Name = UID(32)
        toggleSwitchCorner.Parent = toggleSwitch
        local toggleSwitchPadding = Instance.new("UIPadding")
        toggleSwitchPadding.PaddingBottom = UDim.new(0, 2)
        toggleSwitchPadding.PaddingLeft = UDim.new(0, 2)
        toggleSwitchPadding.PaddingRight = UDim.new(0, 2)
        toggleSwitchPadding.PaddingTop = UDim.new(0, 2)
        toggleSwitchPadding.Name = UID(32)
        toggleSwitchPadding.Parent = toggleSwitch
        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(63, 63, 63)
        toggleStroke.Name = UID(32)
        toggleStroke.Parent = toggleSwitch
        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(1, 0.5)
        knob.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
        knob.BorderSizePixel = 0
        knob.Name = UID(32)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.Size = UDim2.new(1, 0, 1, 0)
        knob.Parent = toggleSwitch
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 4)
        knobCorner.Name = UID(32)
        knobCorner.Parent = knob
        local knobRatio = Instance.new("UIAspectRatioConstraint")
        knobRatio.Name = UID(32)
        knobRatio.Parent = knob
        local enabled = config.Default or false
        local offColor = Color3.fromRGB(63, 63, 63)
        local offPos = UDim2.new(0, knob.AbsoluteSize.X, 0.5, 0)
        local onColor = Defaults.Accent
        local onPos = UDim2.new(1, 0, 0.5, 0)
        local function update()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = enabled and onColor or offColor,
                Position = enabled and onPos or offPos
            }):Play()
            TweenService:Create(toggleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = enabled and onColor or offColor
            }):Play()
        end
        if enabled then
            knob.BackgroundColor3 = onColor
            knob.Position = onPos
            toggleStroke.Color = onColor
        else
            knob.BackgroundColor3 = offColor
            knob.Position = offPos
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
        table.insert(ElementRegistry, {
            Type = "Toggle",
            Frame = frame,
            Label = label,
            Knob = knob,
            Stroke = toggleStroke
        })
        return frame
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
        tabButton.Name = UID(32)
        tabButton.Size = UDim2.new(1, 0, 0, 24)
        tabButton.Text = ""
        tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        tabButton.TextSize = 14
        tabButton.Parent = Tabs
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
        tabLayout.Name = UID(32)
        tabLayout.Parent = tabButton
        local tabLabel = Instance.new("TextLabel")
        tabLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabLabel.BackgroundTransparency = 1
        tabLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        tabLabel.LayoutOrder = 1
        tabLabel.Name = UID(32)
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
        tabLabelPadding.Name = UID(32)
        tabLabelPadding.Parent = tabLabel
        local underline = Instance.new("Frame")
        underline.BackgroundColor3 = Defaults.Accent
        underline.BorderSizePixel = 0
        underline.LayoutOrder = 2
        underline.Name = UID(32)
        underline.Size = UDim2.new(0, 0, 0, 2)
        underline.Parent = tabButton
        local underlineCorner = Instance.new("UICorner")
        underlineCorner.CornerRadius = UDim.new(0, 6)
        underlineCorner.Name = UID(32)
        underlineCorner.Parent = underline
        local tabData = {
            Content = content,
            Label = tabLabel,
            Tab = tabButton,
            Underline = underline
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
    local content = config.Parent.Content
    local layoutOrder = #content:GetChildren() + 1
    local creator = ElementCreators[elementType]
    if creator then
        return creator(content, layoutOrder, config)
    else
        Warn("[VoidUI]: Unknown element type: " .. elementType)
    end
end

function VoidUI:Notify(Title, Text, Duration)
    return VoidNotifs:Notify(Title, Text, Duration)
end

function VoidUI:SetLogo(image)
    if not image then
        Warn("[VoidUI]: No image provided for SetLogo")
        return
    end
    local asset = GetFile(image)
    if asset then
        HasLogo = true
        Logo.Visible = true
        LogoIcon.Image = asset
        VoidNotifs:SetLogo(asset)
    end
end

function VoidUI:SetTheme(theme)
    if not theme then
        Warn("[VoidUI]: No theme table provided for SetTheme")
        return
    end
    for k, v in pairs(theme) do
        local parsed = ParseColor(v)
        if parsed then
            CustomTheme[k] = string.format("%d, %d, %d", parsed.R * 255, parsed.G * 255, parsed.B * 255)
        end
    end
    if theme.Accent then
        local color = ParseColor(theme.Accent)
        if color then
            ApplyAccentColor(color)
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
    UpdateColorPlaceholders()
    if not IsCustomTheme then
        SaveSettings()
    end
end

function VoidUI:SetTitle(newTitle)
    Title.Text = tostring(newTitle)
end

SettingsTab = CreateSettingsTab()

Dragify(Topbar, Main)

Toggle.MouseButton1Click:Connect(function()
    if MainTweening then return end
    MainTweening = true
    MainClosed = not MainClosed
    if MainClosed then
        OpenSize = Main.Size
        OpenPos = Main.Position
        SavedTitle = Title.Text
        Title.Text = "VoidUI"
        local topbarH = Topbar.AbsoluteSize.Y
        local closedW
        if HasLogo then
            closedW = 134
        else
            closedW = 104
        end
        TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(closedW, topbarH),
            Position = ClosedPos
        }):Play()
        TweenService:Create(ToggleFrame2, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Rotation = 90
        }):Play()
        task.delay(0.15, function()
            Container.Visible = false
        end)
        task.delay(0.55, function()
            MainTweening = false
        end)
    else
        ClosedPos = Main.Position
        Title.Text = SavedTitle
        Container.Visible = true
        TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Size = OpenSize,
            Position = OpenPos
        }):Play()
        TweenService:Create(ToggleFrame2, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Rotation = 0
        }):Play()
        task.delay(0.55, function()
            MainTweening = false
        end)
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer ~= Player then
        return
    end
    Shared.VoidUI.IsLoaded = false
    if IsFolder("VoidUI") then
        pcall(function()
            DelFolder("VoidUI")
        end)
    end
end)

if FirstTab then
    repeat task.wait() until Main.AbsoluteSize.X > 0 and Pages.AbsoluteSize.X > 0
    SwitchTab(FirstTab)
end

return VoidUI