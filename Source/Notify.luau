if not game:IsLoaded() then 
    game.Loaded:Wait() 
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

local CloneRef = expect("function", cloneref, function(...) return ... end)

local Services = setmetatable({}, {
    __index = function(self, name)
        local success, cache = pcall(function()
            return CloneRef(game:GetService(name))
        end)
        if success then
            rawset(self, name, cache)
            return cache
        else
            error("Invalid Service: " .. tostring(name))
        end
    end
})

local Success, Hui = pcall(function()
    return gethui and gethui()
end)

local CoreGui = Success and typeof(Hui) == "Instance" and Hui or Services.CoreGui 
local TweenService = Services.TweenService

local VoidNotifs = {}
local SharedLogo = nil

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = "VoidNotifs"
ScreenGui.ResetOnSpawn = false
ScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Notifs = Instance.new("Frame")
Notifs.AnchorPoint = Vector2.new(1, 0.5)
Notifs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Notifs.BackgroundTransparency = 1
Notifs.BorderSizePixel = 0
Notifs.Name = "Notifs"
Notifs.Position = UDim2.new(1, 0, 0.5, 0)
Notifs.Size = UDim2.new(0.3, 0, 1, 0)
Notifs.Parent = ScreenGui

local NotifsLayout = Instance.new("UIListLayout")
NotifsLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
NotifsLayout.Name = "NotifsLayout"
NotifsLayout.Padding = UDim.new(0, 4)
NotifsLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifsLayout.Parent = Notifs

local NotifsPadding = Instance.new("UIPadding")
NotifsPadding.Name = "NotifsPadding"
NotifsPadding.PaddingBottom = UDim.new(0, 4)
NotifsPadding.PaddingLeft = UDim.new(0, 4)
NotifsPadding.PaddingRight = UDim.new(0, 4)
NotifsPadding.PaddingTop = UDim.new(0, 4)
NotifsPadding.Parent = Notifs

function VoidNotifs:Notify(Title, Text, Duration)
    local NotifyHolder = Instance.new("Frame")
    NotifyHolder.AutomaticSize = Enum.AutomaticSize.Y
    NotifyHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.BorderSizePixel = 0
    NotifyHolder.ClipsDescendants = true
    NotifyHolder.Name = "NotifyHolder"
    NotifyHolder.Size = UDim2.new(1, 0, 0, 0)
    NotifyHolder.Parent = Notifs

    local Notify = Instance.new("CanvasGroup")
    Notify.AutomaticSize = Enum.AutomaticSize.Y
    Notify.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    Notify.BorderSizePixel = 0
    Notify.GroupTransparency = 1
    Notify.Name = "Notify"
    Notify.Position = UDim2.new(0, NotifyHolder.AbsoluteSize.X + 100, 0, 0)
    Notify.Size = UDim2.new(1, 0, 0, 0)
    Notify.Parent = NotifyHolder

    local NotifyCorner = Instance.new("UICorner")
    NotifyCorner.CornerRadius = UDim.new(0, 4)
    NotifyCorner.Name = "NotifyCorner"
    NotifyCorner.Parent = Notify

    local NotifyLayout = Instance.new("UIListLayout")
    NotifyLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    NotifyLayout.Name = "NotifyLayout"
    NotifyLayout.Padding = UDim.new(0, 1)
    NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifyLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    NotifyLayout.Parent = Notify

    local NotifyStroke = Instance.new("UIStroke")
    NotifyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    NotifyStroke.Color = Color3.fromRGB(110, 94, 253)
    NotifyStroke.Name = "NotifyStroke"
    NotifyStroke.Thickness = 1
    NotifyStroke.Parent = Notify

    local Topbar = Instance.new("Frame")
    Topbar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Topbar.BorderSizePixel = 0
    Topbar.LayoutOrder = 1
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 36)
    Topbar.Parent = Notify

    local TopbarLayout = Instance.new("UIListLayout")
    TopbarLayout.FillDirection = Enum.FillDirection.Horizontal
    TopbarLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    TopbarLayout.Name = "TopbarLayout"
    TopbarLayout.Padding = UDim.new(0, 4)
    TopbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TopbarLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    TopbarLayout.Parent = Topbar

    local TopbarPadding = Instance.new("UIPadding")
    TopbarPadding.Name = "TopbarPadding"
    TopbarPadding.PaddingBottom = UDim.new(0, 4)
    TopbarPadding.PaddingLeft = UDim.new(0, 4)
    TopbarPadding.PaddingRight = UDim.new(0, 4)
    TopbarPadding.PaddingTop = UDim.new(0, 4)
    TopbarPadding.Parent = Topbar

    local TopbarSizeCons = Instance.new("UISizeConstraint")
    TopbarSizeCons.MaxSize = Vector2.new(9999, 36)
    TopbarSizeCons.MinSize = Vector2.new(50, 36)
    TopbarSizeCons.Name = "TopbarSizeCons"
    TopbarSizeCons.Parent = Topbar

    local TopbarStroke = Instance.new("UIStroke")
    TopbarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    TopbarStroke.Color = Color3.fromRGB(110, 94, 253)
    TopbarStroke.Name = "TopbarStroke"
    TopbarStroke.Thickness = 1
    TopbarStroke.Parent = Topbar

    local Logo = Instance.new("ImageLabel")
    Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.Image = ""
    Logo.LayoutOrder = 1
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0.2, 0, 0.3, 0)
    Logo.Visible = SharedLogo ~= nil
    Logo.Parent = Topbar

    local LogoRatio = Instance.new("UIAspectRatioConstraint")
    LogoRatio.Name = "LogoRatio"
    LogoRatio.Parent = Logo

    if SharedLogo then
        Logo.Image = SharedLogo
    end

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.BorderSizePixel = 0
    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    TitleLabel.LayoutOrder = 2
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0.2, 0, 0.3, 0)
    TitleLabel.Text = Title or "VoidNotifs"
    TitleLabel.TextColor3 = Color3.fromRGB(111, 95, 254)
    TitleLabel.TextScaled = true
    TitleLabel.TextWrapped = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    local Description = Instance.new("TextLabel")
    Description.AutomaticSize = Enum.AutomaticSize.Y
    Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Description.BackgroundTransparency = 1
    Description.BorderSizePixel = 0
    Description.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Description.LayoutOrder = 2
    Description.Name = "Description"
    Description.Size = UDim2.new(0, 38, 0, 0)
    Description.Text = Text or "Description..."
    Description.TextColor3 = Color3.fromRGB(255, 255, 255)
    Description.TextSize = 16
    Description.TextWrapped = true
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.TextYAlignment = Enum.TextYAlignment.Top
    Description.Parent = Notify

    local DescriptionPadding = Instance.new("UIPadding")
    DescriptionPadding.Name = "LogoPadding"
    DescriptionPadding.PaddingBottom = UDim.new(0, 4)
    DescriptionPadding.PaddingLeft = UDim.new(0, 4)
    DescriptionPadding.PaddingRight = UDim.new(0, 4)
    DescriptionPadding.PaddingTop = UDim.new(0, 3)
    DescriptionPadding.Parent = Description

    NotifyHolder.Size = UDim2.new(1, 0, 0, 0)
    Notify.Position = UDim2.new(0, NotifyHolder.AbsoluteSize.X + 100, 0, 0)
    Notify.GroupTransparency = 1

    local slideIn = TweenService:Create(Notify, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        GroupTransparency = 0,
        Position = UDim2.new(0, 0, 0, 0)
    })
    slideIn:Play()

    local actualDuration = Duration or 5
    task.delay(actualDuration, function()
        if not NotifyHolder or not NotifyHolder.Parent then
            return
        end
        
        local slideOut = TweenService:Create(Notify, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            GroupTransparency = 1,
            Position = UDim2.new(0, NotifyHolder.AbsoluteSize.X + 100, 0, 0)
        })
        slideOut:Play()
        slideOut.Completed:Connect(function()
            if NotifyHolder and NotifyHolder.Parent then
                NotifyHolder:Destroy()
            end
        end)
    end)
end

function VoidNotifs:SetLogo(image)
    if image then
        SharedLogo = image
    end
end

return VoidNotifs