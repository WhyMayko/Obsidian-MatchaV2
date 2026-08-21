# Obsidian Matcha

Obsidian Matcha is a Drawing API UI library for Matcha.

## Quick Start

```lua
local repo = "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/"
local Library = loadstring(game:HttpGet(repo .. "Loader.lua"))()

local Window = Library:CreateWindow({
    Title = "My Script",
    Footer = "example",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowSearch = true,
    Resizable = true,
    MenuKey = 0x70,
})

local Main = Window:AddTab("Main", "user")
local Group = Main:AddLeftGroupbox("Main")

Group:AddToggle("Enabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

Run the full example:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/Example.lua"))()
```

## Loading Addons

```lua
local function loadAddon(path)
    local chunk = assert(loadstring(game:HttpGet(repo .. path)))
    return chunk()
end

local ThemeManager = loadAddon("addons/ThemeManager.lua")
local SaveManager = loadAddon("addons/SaveManager.lua")
local EssentialsManager = loadAddon("addons/EssentialsManager.lua")
local WebhookManager = loadAddon("addons/WebhookManager.lua")
```

`Loader.lua` loads the core modules and only the essential PNG assets before it loads `Library.lua`. Missing Lucide icons are downloaded on first use and cached for the session. TextManager, AnimationManager, DialogManager and NotificationManager are integrated into the core; ThemeManager and the persistence managers remain opt-in.

### WebhookManager

Load a webhook URL from your script:
```lua
webhook.load("Name", "https://discord.com/api/webhooks/...")
```

Build the webhook UI section on a tab:
```lua
WebhookManager:SetLibrary(Library)
WebhookManager:BuildWebhookSection(tab)
```

## Supported UI

- Windows, tabs, groupboxes and tabboxes
- Toggles and checkboxes
- Buttons and sub-buttons
- Labels and dividers
- Sliders with presets
- Inputs/textboxes
- Dropdowns, searchable dropdowns and multi dropdowns
- Color pickers and color picker pairs
- Key pickers and key tab/key box
- Notifications, configurable dialogs and loading overlay
- Draggable labels, buttons and Drawing-native menus
- Dependency boxes and dependency groupboxes
- Runtime Window title, footer, sidebar width, compact mode and animation controls
- ThemeManager, SaveManager and EssentialsManager

## Common Patterns

Toggle with addons:

```lua
Group:AddToggle("Aim", { Text = "Aim", Default = false })
    :AddColorPicker("AimColor", { Default = Color3.fromRGB(255, 0, 0) })
    :AddKeyPicker("AimKey", { Default = 0x02, Mode = "Hold", Popup = true })
```

Slider:

```lua
Group:AddSlider("Speed", {
    Text = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = " studs",
    Presets = { 0, 25, 50, 75, 100 },
})
```

Dropdown:

```lua
Group:AddDropdown("Mode", {
    Text = "Mode",
    Values = { "A", "B", "C" },
    Default = "A",
    Searchable = true,
})
```

Dependency box:

```lua
local Enabled = Group:AddToggle("Advanced", { Text = "Advanced" })
local Box = Group:AddDependencyBox()
Box:AddSlider("Amount", { Text = "Amount", Min = 0, Max = 100 })
Box:SetupDependencies({ { Enabled, true } })
```

Window and managers:

```lua
Window:ChangeTitle("New title")
Window:SetFooter("v2")
Window:SetSidebarWidth(220)
Window:SetCompact(false)
Window:SetAnimations(true)

ThemeManager:SetFolder("Galax/Obsidian/Settings")
SaveManager:SetFolder("Galax/Obsidian/Settings")
```

Managers:

```lua
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
EssentialsManager:SetLibrary(Library)

EssentialsManager:BuildSection(Tabs.Settings)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
```

## Notes

- Keybinds use Win32 virtual-key codes, for example `0x02` for right mouse and `0x70` for F1.
- The library always uses `Monospace`; themes cannot change the font.
- UI icons are local white Lucide PNGs. Idle and hover share the same asset and use image transparency.
- Configs are saved under `Galax/Obsidian/Settings/Configs/`.
- Themes are saved under `Galax/Obsidian/Settings/Themes/`.
