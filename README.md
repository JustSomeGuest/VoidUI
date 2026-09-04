<div align="center">

<img src="Source/Assets/Banner.png" alt="VoidUI Library">

</div>

<p align="center">
A lightweight, modern Roblox UI library with a clean API, built-in theme customization, automatic settings saving, and robust notification/key systems.
</p>

---

# Screenshots

<p align="center">
  <img src="Source/Assets/Screenshot-1.png" alt="VoidUI Elements">
</p>

<p align="center">
  <img src="Source/Assets/Screenshot-2.png" alt="VoidUI Settings">
</p>

---

# Why Choose VoidUI?

- Lightweight and optimized performance
- Clean and intuitive API design
- Built-in theme customization & presets (e.g., "Deep Ocean")
- Automatic settings persistence and saving
- Built-in Settings tab with real-time RGB color customization
- Built-in Notification and Key System support
- Smooth tweens and animations
- Designed for both PC and mobile platforms
- Easy integration into existing scripts and projects

---

# Installation

```luau
local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/JustSomeGuest/VoidUI/Main/Source/Init.luau"))()
```

---

# API Documentation

## Window & Setup

```luau
VoidUI:SetTitle("VoidUI Component Showcase")
VoidUI:SetTheme("Deep Ocean") -- Or pass a custom theme table
VoidUI:SetKey("123", "example.com") -- Optional Key System
```

### Custom Theme Configuration

```luau
VoidUI:SetTheme({
    Accent = "255, 0, 0",
    Secondary = "30, 30, 30",
    TextColor = "255, 255, 255",
    BackgroundColor = "10, 10, 10",
    NonSelectedTextColor = "150, 150, 150"
})
```

## Notifications

```luau
VoidUI:Notify("Title", "Notification message here!", 5)
```

---

## Elements

### Tab

```luau
local Tab = VoidUI:New("Tab", {
    Text = "Tab"
})
```

### Section

```luau
VoidUI:New("Section", {
    Parent = Tab,
    Text = "Section"
})
```

### Label

```luau
VoidUI:New("Label", {
    Parent = Tab,
    Text = "Label"
})
```

### Divider

```luau
VoidUI:New("Divider", {
    Parent = Tab
})
```

### Button

```luau
VoidUI:New("Button", {
    Parent = Tab,
    Text = "Button",
    Callback = function()
        print("Clicked")
    end
})
```

### Toggle

```luau
VoidUI:New("Toggle", {
    Parent = Tab,
    Text = "Toggle",
    Default = false,
    Callback = function(state)
        print(state)
    end
})
```

### Slider

```luau
VoidUI:New("Slider", {
    Parent = Tab,
    Text = "Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print(value)
    end
})
```

### Input Box

```luau
VoidUI:New("Inputbox", {
    Parent = Tab,
    Text = "Input Box",
    Placeholder = "Enter text...",
    Callback = function(text)
        print(text)
    end
})
```

### Dropdown

```luau
VoidUI:New("Dropdown", {
    Parent = Tab,
    Text = "Dropdown",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Callback = function(option)
        print(option)
    end
})
```

---

# Built-in Settings

Every window automatically includes a **Settings** tab with the following features:

- Reset Theme to default
- Background Color (RGB)
- Accent Color (RGB)
- Secondary Color (RGB)
- Text Color (RGB)
- Unselected Text Color (RGB)
- Automatic saving and loading of user settings
