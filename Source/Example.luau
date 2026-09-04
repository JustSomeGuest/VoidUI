local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/JustSomeGuest/VoidUI/Main/Source/Init.luau"))()

VoidUI:SetTitle("VoidUI Component Showcase")
VoidUI:SetTheme("Deep Ocean")
VoidUI:SetKey("123", "links.lootlabs.gg/idk")

local Tab = VoidUI:New("Tab", {
    Text = "Tab"
})

VoidUI:New("Section", {
    Parent = Tab,
    Text = "Section"
})

VoidUI:New("Label", {
    Parent = Tab,
    Text = "Label"
})

VoidUI:New("Divider", {
    Parent = Tab
})

VoidUI:New("Button", {
    Parent = Tab,
    Text = "Button",
    Callback = function()
        VoidUI:Notify("Button", "Button Clicked", 5)
    end
})

VoidUI:New("Toggle", {
    Parent = Tab,
    Text = "Toggle",
    Default = false,
    Callback = function(state)
        VoidUI:Notify("Toggle", state and "Toggle Enabled" or "Toggle Disabled", 5)
    end
})

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

VoidUI:New("Inputbox", {
    Parent = Tab,
    Text = "Inputbox",
    Placeholder = "Enter text...",
    Callback = function(text)
        print("Inputbox:", text)
    end
})

VoidUI:New("Dropdown", {
    Parent = Tab,
    Text = "Dropdown",
    Options = {"Option 1", "Option 2", "Option 3", "Option 4"},
    Default = "Option 1",
    Callback = function(option)
        VoidUI:Notify("Dropdown", "Selected: " .. option, 5)
    end
})