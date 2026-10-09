<div align="center"><img src="Source/Assets/Banner.png" alt="VoidUI Library Banner"></div>
<p align="center">
A lightweight, modern Roblox UI library with a clean API, themes, settings, and notifications.
</p>

---

# Screenshots

<p align="center">
  <img src="Source/Assets/Elements.png" alt="VoidUI Elements">
</p>

<p align="center">
  <img src="Source/Assets/Settings-1.png" alt="VoidUI Settings">
  <img src="Source/Assets/Settings-2.png" alt="VoidUI Settings">
</p>

<p align="center">
  <img src="Source/Assets/Notifs.png" alt="VoidUI Notifications">
</p>

---

# Features

- Lightweight and optimized
- Simple API
- PC and mobile support
- Preset and custom themes
- Automatic settings saving
- Built-in Settings tab
- Notifications
- Smooth animations

---

# Installation

```lua
local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/JustSomeGuest/VoidUI/Main/Source/Init.lua"))()
```

---

# Themes

VoidUI includes preset themes that can be applied by passing the theme name to SetTheme().

## Preset Themes

- Midnight Blue (Default)
- Abyss
- Crimson
- Emerald
- Sunset
- Midnight
- Rose Gold
- Arctic
- Neon Green
- Amber
- Lavender Mist
- Blood Moon
- Slate
- Sakura
- Toxic
- Minimal

Your customized colors are saved automatically as the "User" theme (not a preset).
Old theme keys (`BackgroundColor`, `TextColor`, `NonSelectedTextColor`) still work and are mapped to `Background`, `Text`, `NonSelectedText`.

### Using a Preset Theme

```lua
VoidUI:SetTheme("Abyss")
```

Replace "Abyss" with any of the preset theme names listed above.

### Custom Themes

You can also create your own theme by passing a theme table to SetTheme().

```lua
VoidUI:SetTheme({
    Accent = "255, 0, 0",
    Secondary = "30, 30, 30",
    Text = "255, 255, 255",
    Background = "10, 10, 10",
    NonSelectedText = "150, 150, 150"
})
```

Custom themes support:

- Accent
- Background
- Secondary
- Text
- NonSelectedText

The theme values use RGB strings in the format "R, G, B". Hex strings like "#FF0000" and Color3 values also work.

### Logo

```lua
VoidUI:SetLogo("rbxassetid://1234567890")
-- URLs are downloaded and cached as VoidUI/Cache/<UUID>.png
VoidUI:SetLogo("https://example.com/logo.png")
```

# Usage

```lua
local Window = VoidUI:CreateWindow({
    Title = "My Script",
    Theme = "Midnight Blue",
    Logo = "rbxassetid://1234567890",
})

local Tab = Window:CreateTab("Main")

Tab:CreateButton({ Text = "Button", Callback = function() end })
Tab:CreateToggle({ Text = "Toggle", Default = false, Callback = function(state) end })
Tab:CreateSlider({ Text = "Slider", Min = 0, Max = 100, Default = 50, Callback = function(v) end })
Tab:CreateInputbox({ Text = "Inputbox", Placeholder = "Enter text...", Callback = function(t) end })
Tab:CreateDropdown({ Text = "Dropdown", Options = {"A", "B"}, Default = "A", Callback = function(o) end })
Tab:CreateColorPicker({ Text = "Color", Default = "80, 140, 255", Callback = function(c) end })
Tab:CreateLabel("Label")
Tab:CreateSection("Section")
Tab:CreateDivider()
```

`Text` also accepts `Name`. `SetTitle`, `SetTheme` and `SetLogo` still work on their own too.

### Corners

```lua
VoidUI:SetCorner(6, true)
```

First arg is the corner offset (`0` allowed for square). Second arg (`true`/`false`) also restyles the round toggle/slider knobs from `(1, 0)` to `(0, offset)`. Can also be set via `CreateWindow({ Corner = 6, CornerKnobs = true })` or in VoidUI Settings under Corners (inputbox + toggle). Notifications follow the same setting (`VoidUI:SetCorner(0)` gives square notifications too).

```lua
local offset, knobs = VoidUI:GetCorner()
```

### ColorPicker

```lua
Tab:CreateColorPicker({
    Text = "Accent",
    Default = "80, 140, 255",
    Callback = function(color)
        print(color)
    end
})
```

ColorPicker supports `Text` plus `Default` / `DefaultColor` / `Color` for the initial color. Clicking the preview opens a picker with a touch/mouse area, RGB fields, Hex field, Save and Cancel. Hex and RGB stay in sync.

---

# Example

See the [Example.lua](Source/Example.lua) file for setup, themes, notifications, and all available components.
