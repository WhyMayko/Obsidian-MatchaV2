local repo = "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/"

loadstring(game:HttpGet(repo .. "Loader.lua"))()

local Library, ThemeManager, SaveManager, EssentialsManager = _G.Galax()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "mspaint",
    Footer = "version: example",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowSearch = true,
})

local startupLoading = Library:CreateLoading({
    Title = "mspaint",
    Icon = 95816097006870,
    Message = "Loading...",
    Description = "Preparing interface...",
    CurrentStep = 0,
    TotalSteps = 4,
    ShowSidebar = false,
    WindowWidth = 450,
    WindowHeight = 275,
    ContentWidth = 450,
    SidebarWidth = 250,
})

startupLoading:SetErrorButtons({
    Retry = {
        Title = "Retry",
        Variant = "Primary",
        Order = 1,
        Callback = function(loading)
            loading:ShowErrorPage(false)
            loading:ShowSidebarPage(true)
        end,
    },
    Close = {
        Title = "Close",
        Variant = "Secondary",
        Order = 2,
        Callback = function(loading)
            loading:Destroy()
        end,
    },
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    Key = Window:AddKeyTab("Key System"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local MainLeft = Tabs.Main:AddLeftGroupbox("Groupbox", "boxes")
local MainRight = Tabs.Main:AddRightGroupbox("Dropdowns")

MainLeft:AddToggle("MyToggle", {
    Text = "This is a toggle",
    Default = true,
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
    Risky = false,
    Callback = function(value)
        print("[cb] MyToggle:", value)
    end,
})
    :AddColorPicker("ColorPicker1", {
        Default = Color3.fromRGB(255, 0, 0),
        Title = "Some color1",
        Transparency = 0,
        Callback = function(value, transparency)
            print("[cb] ColorPicker1:", value, transparency)
        end,
    })
    :AddColorPicker("ColorPicker2", {
        Default = Color3.fromRGB(0, 255, 0),
        Title = "Some color2",
        Callback = function(value)
            print("[cb] ColorPicker2:", value)
        end,
    })

Toggles.MyToggle:OnChanged(function()
    print("MyToggle changed:", Toggles.MyToggle.Value)
end)

MainLeft:AddCheckbox("MyCheckbox", {
    Text = "This is a checkbox",
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    Default = true,
    Disabled = false,
    Visible = true,
    Risky = false,
    Callback = function(value)
        print("[cb] MyCheckbox:", value)
    end,
})

local Button = MainLeft:AddButton({
    Text = "Button",
    Func = function()
        print("You clicked a button!")
    end,
    Tooltip = "This is the main button",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
    Risky = false,
})

Button:AddButton({
    Text = "Sub button",
    DoubleClick = true,
    Func = function()
        print("You clicked a sub button!")
    end,
    Tooltip = "This is the sub button",
    DisabledTooltip = "I am disabled!",
})

MainLeft:AddButton({
    Text = "Disabled Button",
    Func = function()
        print("You somehow clicked a disabled button!")
    end,
    Tooltip = "This is a disabled button",
    DisabledTooltip = "I am disabled!",
    Disabled = true,
})

MainLeft:AddLabel("This is a label")
MainLeft:AddLabel("This is a label\n\nwhich wraps its text!", true)
MainLeft:AddLabel("This is a label exposed to Options", true, "TestLabel")
MainLeft:AddLabel("SecondTestLabel", {
    Text = "This is a label that doesn't wrap it's own text",
    DoesWrap = false,
})

MainLeft:AddDivider({
    Text = "Sliders",
    MarginTop = 6,
    MarginBottom = 6,
})

MainLeft:AddSlider("MySlider", {
    Text = "This is my slider!",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = "I am a slider!",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
    Callback = function(value)
        print("[cb] MySlider was changed! New value:", value)
    end,
})

Options.MySlider:OnChanged(function()
    print("MySlider was changed! New value:", Options.MySlider.Value)
end)

Options.MySlider:SetValue(3)

MainLeft:AddSlider("CompactSlider", {
    Text = "Compact view",
    Default = 16,
    Min = 0,
    Max = 250,
    Rounding = 0,
    Prefix = "",
    Suffix = "",
    Compact = true,
    AllowRightClickInput = true,
})

MainLeft:AddSlider("MySlider2", {
    Text = "This is my custom display slider!",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 0,
    Compact = false,
    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return "Everything" end
        if value == slider.Min then return "Nothing" end
    end,
    Tooltip = "I am a slider!",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
})

MainLeft:AddInput("MyTextbox", {
    Text = "This is a textbox",
    Default = "My textbox!",
    Numeric = false,
    Finished = false,
    Placeholder = "Placeholder text",
    ClearTextOnFocus = true,
    Tooltip = "This is a tooltip",
    Callback = function(value)
        print("[cb] Textbox:", value)
    end,
})

MainLeft:AddLabel("Color"):AddColorPicker("ColorPicker", {
    Default = Color3.new(0, 1, 0),
    Title = "Some color",
    Transparency = 0,
    Callback = function(value, transparency)
        print("[cb] Label color:", value, transparency)
    end,
})

Options.ColorPicker:OnChanged(function()
    print("Color changed!", Options.ColorPicker.Value)
    print("Transparency changed!", Options.ColorPicker.Transparency)
end)

Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

MainLeft:AddLabel("Keybind"):AddKeyPicker("KeyPicker", {
    Default = 0x02,
    SyncToggleState = false,
    Mode = "Toggle",
    Text = "Auto lockpick safes",
    Popup = true,
    Callback = function(active)
        print("[cb] Keybind active:", active)
    end,
    ChangedCallback = function(key)
        print("[cb] Keybind changed:", key)
    end,
})

Options.KeyPicker:OnClick(function()
    print("Keybind state:", Options.KeyPicker:GetState())
end)

local KeybindNumber = 0

MainLeft:AddLabel("Press Keybind"):AddKeyPicker("KeyPicker2", {
    Default = 0x58,
    Mode = "Press",
    Text = "Increase Number",
    Popup = { "Press" },
    Callback = function()
        KeybindNumber = KeybindNumber + 1
        print("[cb] Keybind clicked! Number increased to:", KeybindNumber)
    end,
})

MainRight:AddDropdown("MyDropdown", {
    Text = "A dropdown",
    Values = { "This", "is", "a", "dropdown" },
    Default = 1,
    Multi = false,
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    Searchable = false,
    Disabled = false,
    Visible = true,
    Callback = function(value)
        print("[cb] Dropdown:", value)
    end,
})

Options.MyDropdown:SetValue("This")

MainRight:AddDropdown("MySearchableDropdown", {
    Text = "A searchable dropdown",
    Values = { "This", "is", "a", "searchable", "dropdown" },
    Default = 1,
    Multi = false,
    Searchable = true,
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
})

MainRight:AddDropdown("MyDisplayFormattedDropdown", {
    Text = "A display formatted dropdown",
    Values = { "This", "is", "a", "formatted", "dropdown" },
    Default = 1,
    Multi = false,
    Searchable = false,
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    FormatDisplayValue = function(value)
        if value == "formatted" then
            return "display formatted"
        end
        return value
    end,
    Callback = function(value)
        print("[cb] Display formatted dropdown:", value)
    end,
})

MainRight:AddDropdown("MyMultiDropdown", {
    Text = "A multi dropdown",
    Values = { "This", "is", "a", "dropdown" },
    Default = { "This" },
    Multi = true,
    Tooltip = "This is a tooltip",
    Callback = function(values)
        print("[cb] Multi dropdown:")
        for value, enabled in pairs(values) do
            print(value, enabled)
        end
    end,
})

Options.MyMultiDropdown:SetValue({ "This", "is" })

MainRight:AddDropdown("MyDisabledDropdown", {
    Text = "A disabled dropdown",
    Values = { "This", "is", "a", "dropdown" },
    Default = 1,
    Multi = false,
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    Disabled = true,
    Visible = true,
})

MainRight:AddDropdown("MyDisabledValueDropdown", {
    Text = "A dropdown with disabled value",
    Values = { "This", "is", "a", "dropdown", "with", "disabled", "value" },
    DisabledValues = { "disabled" },
    Default = 1,
    Multi = false,
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
})

MainRight:AddDropdown("MyVeryLongDropdown", {
    Text = "A very long dropdown",
    Values = {
        "This", "is", "a", "very", "long", "dropdown", "with", "a", "lot", "of",
        "values", "but", "you", "can", "see", "more", "than", "8", "values",
    },
    Default = 1,
    Multi = false,
    MaxVisibleDropdownItems = 12,
    Searchable = false,
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
})

MainRight:AddDropdown("MyPlayerDropdown", {
    Text = "A player dropdown",
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Tooltip = "This is a tooltip",
})

MainRight:AddDropdown("MyTeamDropdown", {
    Text = "A team dropdown",
    SpecialType = "Team",
    Tooltip = "This is a tooltip",
})

local TabBox = Tabs.Main:AddRightTabbox()
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

local ScrollGroup = Tabs.Main:AddLeftGroupbox("Groupbox #2")
ScrollGroup:AddLabel("This label spans multiple lines! We're gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!", true)

local DependencyToggle = ScrollGroup:AddToggle("ShowAdvanced", {
    Text = "Show advanced controls",
    Default = false,
})

local DependencyBox = ScrollGroup:AddDependencyBox()
DependencyBox:AddSlider("AdvancedAmount", {
    Text = "Advanced amount",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
})
DependencyBox:SetupDependencies({ { DependencyToggle, true } })

ScrollGroup:AddButton({
    Text = "Open dialog",
    Func = function()
        Window:AddDialog("ExampleDialog", {
            Title = "Test Dialog",
            Description = "This dialog has configurable buttons.",
            Buttons = {
                { Id = "Cancel", Text = "Cancel", Order = 1, Variant = "Secondary" },
                { Id = "Delete", Text = "Delete", Order = 2, Variant = "Destructive" },
                { Id = "Confirm", Text = "Confirm", Order = 3, Variant = "Primary" },
            },
        })
    end,
})

ScrollGroup:AddButton({
    Text = "Show loading",
    Func = function()
        local Loading = Library:CreateLoading({ Message = "Obsidian Matcha", Description = "Loading features...", TotalSteps = 3 })
        task.spawn(function()
            for step = 1, 3 do
                Loading:SetCurrentStep(step)
                task.wait(0.35)
            end
            Loading:Destroy()
        end)
    end,
})

Tabs.Key:AddLabel({
    Text = "Key: Banana",
    DoesWrap = true,
    Size = 16,
})

Tabs.Key:AddKeyBox(function(receivedKey)
    local success = receivedKey == "Banana"
    Library:Notify({
        Title = "Key check",
        Description = "Received: " .. tostring(receivedKey) .. "\nSuccess: " .. tostring(success),
        Time = 4,
    })
end)

Library:AddDraggableLabel("Obsidian Matcha | overlay")
Library:AddDraggableButton("Toggle UI", function()
    Library:Toggle()
end, false, "panel-left")

local StatsMenu, StatsContainer = Library:AddDraggableMenu("Stats")
StatsContainer:AddLabel("Drawing overlay")
local performanceValue = StatsContainer:AddValue("0 fps | 0 ms")
StatsContainer:AddValue("Lucide: lazy")
StatsContainer:AddButton("Close", function()
    StatsMenu:SetVisible(false)
end)

local frameCount = 0
local lastPerformanceUpdate = tick()
local performanceConnection = game:GetService("RunService").RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    local elapsed = now - lastPerformanceUpdate
    if elapsed >= 1 then
        local fps = math.floor(frameCount / elapsed + 0.5)
        local ping = math.floor(GetPingValue() + 0.5)
        performanceValue:SetText(tostring(fps) .. " fps | " .. tostring(ping) .. " ms")
        frameCount = 0
        lastPerformanceUpdate = now
    end
end)

task.spawn(function()
    local steps = {
        "Loading configuration...",
        "Loading Lucide icons...",
        "Preparing Drawing overlays...",
        "Ready!",
    }
    for step, description in ipairs(steps) do
        if step == 2 then
            startupLoading:ShowSidebarPage(true)
            startupLoading.Sidebar:AddLabel("Obsidian Matcha")
            startupLoading.Sidebar:AddDivider()
            startupLoading.Sidebar:AddValue("Version: v2")
            startupLoading.Sidebar:AddValue("User: " .. tostring(game:GetService("Players").LocalPlayer.Name))
        end
        startupLoading:SetDescription(description)
        startupLoading:SetCurrentStep(step)
        task.wait(1)
    end
    startupLoading:Continue()
end)

Library:OnUnload(function()
    performanceConnection:Disconnect()
    print("Unloaded")
end)

EssentialsManager:SetLibrary(Library)
EssentialsManager:BuildSection(Tabs["UI Settings"])

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("Galax/Obsidian/Settings")
SaveManager:SetFolder("Galax/Obsidian/Settings")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
