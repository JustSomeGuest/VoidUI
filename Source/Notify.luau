if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Shared = (type(getgenv) == "function" and getgenv()) or shared or _G

local function GetService(Service)
    local Service = game:GetService(Service)
    return cloneref and cloneref(Service) or Service
end

local Hui = gethui and gethui() or GetService("CoreGui")
local StarterGui = GetService("StarterGui")
local TweenService = GetService("TweenService")

local function Tween(Object, Speed, Props, Style, Dir)
    return TweenService:Create(
        Object,
        TweenInfo.new(
            Speed,
            Enum.EasingStyle[Style or "Quad"],
            Enum.EasingDirection[Dir or "Out"]
        ),
        Props
    )
end

local function UID(Length)
    Length = Length or 32

    local Chars = [[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~]]
    local Id = table.create(Length)

    for i = 1, Length do
        local Rand = math.random(1, #Chars)
        Id[i] = Chars:sub(Rand, Rand)
    end

    return table.concat(Id)
end

Shared.VoidNotifs = Shared.VoidNotifs or {}

if Shared.VoidNotifs.IsLoaded then
    StarterGui:SetCore("SendNotification", {
        Title = "VoidNotifs",
        Text = "VoidNotifs is already running!",
        Duration = 4
    })
    return
end

Shared.VoidNotifs.IsLoaded = true

local VoidNotifs = {}
local SharedLogo = nil

local Settings = {
    Theme = {
        Accent = Color3.fromRGB(110, 94, 253),
        Secondary = Color3.fromRGB(14, 14, 14),
        Text = Color3.fromRGB(255, 255, 255),
    },
    Fonts = {
        Title = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Description = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    },
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.DisplayOrder = 2147483647
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = UID(32)
ScreenGui.ResetOnSpawn = false
ScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Hui

local Notifs = Instance.new("Frame")
Notifs.AnchorPoint = Vector2.new(1, 0.5)
Notifs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Notifs.BackgroundTransparency = 1
Notifs.BorderSizePixel = 0
Notifs.Name = UID(32)
Notifs.Position = UDim2.new(1, 0, 0.5, 0)
Notifs.Size = UDim2.new(0.3, 0, 1, 0)
Notifs.Parent = ScreenGui

local NotifsLayout = Instance.new("UIListLayout")
NotifsLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
NotifsLayout.Name = UID(32)
NotifsLayout.Padding = UDim.new(0, 6)
NotifsLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifsLayout.Parent = Notifs

local NotifsPadding = Instance.new("UIPadding")
NotifsPadding.Name = UID(32)
NotifsPadding.PaddingBottom = UDim.new(0, 4)
NotifsPadding.PaddingLeft = UDim.new(0, 4)
NotifsPadding.PaddingRight = UDim.new(0, 4)
NotifsPadding.PaddingTop = UDim.new(0, 4)
NotifsPadding.Parent = Notifs

local function SlideIn(Notify, NotifyHolder)
    Notify.GroupTransparency = 1
    Notify.Position = UDim2.new(0, NotifyHolder.AbsoluteSize.X + 100, 0, 0)
    Notify.Visible = true

    Tween(Notify, 0.5, {
        GroupTransparency = 0,
        Position = UDim2.new(0, 0, 0, 0)
    }, "Back", "Out"):Play()
end

local function SlideOut(Notify, NotifyHolder)
    local slideOut = Tween(Notify, 0.4, {
        GroupTransparency = 1,
        Position = UDim2.new(0, NotifyHolder.AbsoluteSize.X + 100, 0, 0)
    }, "Back", "In")

    Notify.Visible = true
    slideOut:Play()
    slideOut.Completed:Wait()

    Notify.GroupTransparency = 1
    Notify.Position = UDim2.new(0, NotifyHolder.AbsoluteSize.X + 100, 0, 0)
    Notify.Visible = false
end

function VoidNotifs:Notify(Title, Text, Duration)
    local currentSettings = self.Settings or Settings
    local currentTheme = currentSettings.Theme
    local currentFonts = currentSettings.Fonts
    
    local NotifyHolder = Instance.new("Frame")
    NotifyHolder.AutomaticSize = Enum.AutomaticSize.Y
    NotifyHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.BorderSizePixel = 0
    NotifyHolder.Name = UID(32)
    NotifyHolder.Size = UDim2.new(1, 0, 0, 0)
    NotifyHolder.Parent = Notifs

    local Notify = Instance.new("CanvasGroup")
    Notify.AutomaticSize = Enum.AutomaticSize.Y
    Notify.BackgroundColor3 = currentTheme.Secondary
    Notify.BorderSizePixel = 0
    Notify.Name = UID(32)
    Notify.Size = UDim2.new(1, 0, 0, 0)
    Notify.Parent = NotifyHolder

    local NotifyCorner = Instance.new("UICorner")
    NotifyCorner.CornerRadius = UDim.new(0, 4)
    NotifyCorner.Name = UID(32)
    NotifyCorner.Parent = Notify

    local NotifyLayout = Instance.new("UIListLayout")
    NotifyLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    NotifyLayout.Name = UID(32)
    NotifyLayout.Padding = UDim.new(0, 1)
    NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifyLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    NotifyLayout.Parent = Notify

    local NotifyStroke = Instance.new("UIStroke")
    NotifyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    NotifyStroke.Color = currentTheme.Accent
    NotifyStroke.Name = UID(32)
    NotifyStroke.Thickness = 1
    NotifyStroke.Parent = Notify

    local Topbar = Instance.new("Frame")
    Topbar.BackgroundColor3 = currentTheme.Secondary
    Topbar.BorderSizePixel = 0
    Topbar.LayoutOrder = 1
    Topbar.Name = UID(32)
    Topbar.Size = UDim2.new(1, 0, 0, 36)
    Topbar.Parent = Notify

    local TopbarLayout = Instance.new("UIListLayout")
    TopbarLayout.FillDirection = Enum.FillDirection.Horizontal
    TopbarLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    TopbarLayout.Name = UID(32)
    TopbarLayout.Padding = UDim.new(0, 4)
    TopbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TopbarLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    TopbarLayout.Parent = Topbar

    local TopbarPadding = Instance.new("UIPadding")
    TopbarPadding.Name = UID(32)
    TopbarPadding.PaddingBottom = UDim.new(0, 4)
    TopbarPadding.PaddingLeft = UDim.new(0, 4)
    TopbarPadding.PaddingRight = UDim.new(0, 4)
    TopbarPadding.PaddingTop = UDim.new(0, 4)
    TopbarPadding.Parent = Topbar

    local TopbarSizeCons = Instance.new("UISizeConstraint")
    TopbarSizeCons.MaxSize = Vector2.new(8000, 36)
    TopbarSizeCons.MinSize = Vector2.new(100, 34)
    TopbarSizeCons.Name = UID(32)
    TopbarSizeCons.Parent = Topbar

    local TopbarStroke = Instance.new("UIStroke")
    TopbarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    TopbarStroke.Color = currentTheme.Accent
    TopbarStroke.Name = UID(32)
    TopbarStroke.Thickness = 1
    TopbarStroke.Parent = Topbar

    local Logo = Instance.new("ImageLabel")
    Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.Image = SharedLogo or ""
    Logo.LayoutOrder = 1
    Logo.Name = UID(32)
    Logo.Size = UDim2.new(0.2, 0, 0.3, 0)
    Logo.Visible = SharedLogo ~= nil and SharedLogo ~= ""
    Logo.Parent = Topbar

    local LogoRatio = Instance.new("UIAspectRatioConstraint")
    LogoRatio.Name = UID(32)
    LogoRatio.Parent = Logo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.BorderSizePixel = 0
    TitleLabel.FontFace = currentFonts.Title
    TitleLabel.LayoutOrder = 2
    TitleLabel.Name = UID(32)
    TitleLabel.Size = UDim2.new(0.2, 0, 0.3, 0)
    TitleLabel.Text = Title or "VoidUI"
    TitleLabel.TextColor3 = currentTheme.Accent
    TitleLabel.TextScaled = true
    TitleLabel.TextWrapped = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    local Description = Instance.new("TextLabel")
    Description.AutomaticSize = Enum.AutomaticSize.Y
    Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Description.BackgroundTransparency = 1
    Description.BorderSizePixel = 0
    Description.FontFace = currentFonts.Description
    Description.LayoutOrder = 2
    Description.Name = UID(32)
    Description.RichText = true
    Description.Size = UDim2.new(1, 0, 0, 0)
    Description.Text = Text or "Description..."
    Description.TextColor3 = currentTheme.Text
    Description.TextSize = 16
    Description.TextWrapped = true
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.TextYAlignment = Enum.TextYAlignment.Top
    Description.Parent = Notify

    local DescriptionPadding = Instance.new("UIPadding")
    DescriptionPadding.Name = UID(32)
    DescriptionPadding.PaddingBottom = UDim.new(0, 4)
    DescriptionPadding.PaddingLeft = UDim.new(0, 4)
    DescriptionPadding.PaddingRight = UDim.new(0, 4)
    DescriptionPadding.PaddingTop = UDim.new(0, 3)
    DescriptionPadding.Parent = Description

    SlideIn(Notify, NotifyHolder)

    local actualDuration = Duration or 5
    task.delay(actualDuration, function()
        if not NotifyHolder or not NotifyHolder.Parent then
            return
        end

        SlideOut(Notify, NotifyHolder)

        if NotifyHolder and NotifyHolder.Parent then
            NotifyHolder:Destroy()
        end
    end)
end

function VoidNotifs:SetLogo(image)
    if image and image ~= "" then
        SharedLogo = image
    else
        SharedLogo = nil
    end
end

VoidNotifs.Settings = Settings

return VoidNotifs