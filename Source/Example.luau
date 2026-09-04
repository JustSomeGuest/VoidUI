-- Load VoidUI

local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/JustSomeGuest/VoidUI/Main/Source/Init.luau"))()


-- Setup

VoidUI:SetTitle("VoidUI Component Showcase")

-- Use a preset theme name. See the README for all available preset themes.
VoidUI:SetTheme("Deep Ocean")

-- Or use a custom theme table.
VoidUI:SetTheme({
    Accent = "255, 0, 0",
    Secondary = "30, 30, 30",
    TextColor = "255, 255, 255",
    BackgroundColor = "10, 10, 10",
    NonSelectedTextColor = "150, 150, 150"
})

-- SetKey("Key", "Ad Link URL")
-- The first argument is the actual key the user must receive.
-- The second argument is the URL where the user can get the key.
VoidUI:SetKey("123", "links.lootlabs.gg/idk")


-- Tab

local Tab = VoidUI:New("Tab", {
    Text = "Tab"
})


-- Section

VoidUI:New("Section", {
    Parent = Tab,
    Text = "Section"
})


-- Label

VoidUI:New("Label", {
    Parent = Tab,
    Text = "Label"
})


-- Divider

VoidUI:New("Divider", {
    Parent = Tab
})


-- Button

VoidUI:New("Button", {
    Parent = Tab,
    Text = "Button",
    Callback = function()
        VoidUI:Notify("Button", "Button Clicked", 5)
    end
})


-- Toggle

VoidUI:New("Toggle", {
    Parent = Tab,
    Text = "Toggle",
    Default = false,
    Callback = function(state)
        VoidUI:Notify("Toggle", state and "Toggle Enabled" or "Toggle Disabled", 5)
    end
})


-- Slider

VoidUI:New("Slider", {
    Parent = Tab,
    Text = "Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Slider:", value)
    end
})


-- Inputbox

VoidUI:New("Inputbox", {
    Parent = Tab,
    Text = "Inputbox",
    Placeholder = "Enter text...",
    Callback = function(text)
        print("Inputbox:", text)
    end
})


-- Dropdown

VoidUI:New("Dropdown", {
    Parent = Tab,
    Text = "Dropdown",
    Options = {"Option 1", "Option 2", "Option 3", "Option 4"},
    Default = "Option 1",
    Callback = function(option)
        VoidUI:Notify("Dropdown", "Selected: " .. option, 5)
    end
})


-- Notification

-- Notify("Title", "Text", Duration)
-- The first argument is the notification title.
-- The second argument is the notification text.
-- The third argument is how long the notification stays visible, in seconds.
VoidUI:Notify("Notification", "This is a notification!", 5)