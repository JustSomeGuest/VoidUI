--// Load VoidUI

local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/JustSomeGuest/VoidUI/Main/Source/Init.lua"))()

--// Window
--// Default Corner = 6
--// Default Theme = "Midnight Blue"
--// CornerKnobs controls whether toggle pills and sliders also use the corner setting.

local Window = VoidUI:CreateWindow({
    Title = "VoidUI Component Showcase",
    Theme = "Midnight Blue",
    --// Logo = "rbxassetid://1234567890",
    Corner = 6,
    CornerKnobs = true,
})

--[[
Window setters (also available through VoidUI):

    Window:SetTitle("New Title")
    VoidUI:SetTitle("New Title")

    Window:SetTheme("Abyss")
    VoidUI:SetTheme("Abyss")
    VoidUI:SetTheme({
        Accent = "255, 0, 0",
        Secondary = "30, 30, 30",
        Text = "255, 255, 255",
        Background = "10, 10, 10",
        NonSelectedText = "150, 150, 150",
    })
    VoidUI:SetTheme({ Accent = "#FF0000" })

    Window:SetLogo("rbxassetid://1234567890")
    VoidUI:SetLogo("https://example.com/logo.png")

    Window:SetCorner(6, true)
    VoidUI:SetCorner(6)

    local offset, knobs = Window:GetCorner()
    print(offset, knobs)

CornerKnobs:
    true  = Also apply corner settings to toggle pills and sliders.
    false = Keep their default corner styling.

Notifications follow the corner setting.
Corner = 0 produces square notifications.
]]

--// Tabs

local Tab = Window:CreateTab("Main")
--// local OtherTab = Window:CreateTab({ Text = "Other" })

--// Section

Tab:CreateSection("Section")
--// Tab:CreateSection({ Text = "Section via table" })

--// Label

Tab:CreateLabel("Label")
--// Tab:CreateLabel({ Text = "Label via table" })

--// Divider

Tab:CreateDivider()

--// Button

Tab:CreateButton({
    Text = "Button",
    Callback = function()
        VoidUI:Notify("Button", "Button Clicked", 5)
    end,
})
--// Tab:CreateButton({ Name = "Button via Name", Callback = function() end })

--// Toggle

Tab:CreateToggle({
    Text = "Toggle",
    Default = false,
    Callback = function(state)
        VoidUI:Notify("Toggle", state and "Toggle Enabled" or "Toggle Disabled", 5)
    end,
})

--// Slider

Tab:CreateSlider({
    Text = "Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Slider:", value)
    end,
})

--// Inputbox

Tab:CreateInputbox({
    Text = "Inputbox",
    Placeholder = "Enter text...",
    Callback = function(text)
        print("Inputbox:", text)
    end,
})

--// Dropdown

Tab:CreateDropdown({
    Text = "Dropdown",
    Options = { "Option 1", "Option 2", "Option 3", "Option 4" },
    Default = "Option 1",
    Callback = function(option)
        VoidUI:Notify("Dropdown", "Selected: " .. option, 5)
    end,
})

--// ColorPicker

local Picker = Tab:CreateColorPicker({
    Text = "ColorPicker",
    Default = "80, 140, 255",
    Callback = function(color)
        print("ColorPicker:", color)
    end,
})

--[[
Picker:SetColor("#FF0000")
Picker:SetColor("255, 0, 0")
print(Picker:GetColor())
]]

--// Notification

VoidUI:Notify("Notification", "This is a notification!", 5)

--[[
Window:Notify("Notification", "Via Window API", 5)

local Handle = VoidUI:Notify("Pinned", "Dismiss me early", 30)
Handle:Dismiss()
]]
