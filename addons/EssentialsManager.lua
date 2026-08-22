
local EssentialsManager = {
	Library = nil,
}

function EssentialsManager:SetLibrary(library)
	self.Library = library
end

function EssentialsManager:BuildSection(tab)
	local Library = self.Library
	assert(Library, "EssentialsManager: call SetLibrary first")

	local MenuGroup = tab:AddLeftGroupbox("Menu", "wrench")

	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = false,
		Text = "Open Keybind Menu",
		Callback = function(Value)
			if not Library.ActiveWindow then
				error("EssentialsManager: no active window for KeybindMenuOpen", 2)
			end
			Library.ActiveWindow:SetKeybindMenuVisible(Value)
		end,
	})

	MenuGroup:AddToggle("Input", {
		Default = true,
		Text = "Input",
		Callback = function(Value)
			if not Library.ActiveWindow then
				error("EssentialsManager: no active window for Input!", 2)
			end
			Library.ActiveWindow:SetInputBlocking(Value)
		end,
	})

	MenuGroup:AddDropdown("NotificationSide", {
		Values = { "Left", "Right" },
		Default = "Right",
		Text = "Notification Side",
		Callback = function(Value)
			Library:SetNotifySide(Value)
		end,
	})

	MenuGroup:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%", "225%", "250%" },
		Default = "100%",
		Text = "DPI Scale",
		Callback = function(Value)
			if not Library.ActiveWindow then
				error("EssentialsManager: no active window for DPIDropdown", 2)
			end
			local pct = tonumber(Value:match("%d+")) or 100
			Library.ActiveWindow:SetDPIScale(pct)
		end,
	})

	MenuGroup:AddSlider("UICornerSlider", {
		Text = "Corner Radius",
		Default = 4,
		Min = 0,
		Max = 10,
		Rounding = 0,
		Callback = function(Value)
			if not Library.ActiveWindow then
				error("EssentialsManager: no active window for UICornerSlider", 2)
			end
			Library.CornerRadius = Value
			Library.ActiveWindow:SetCornerRadius(Value)
		end,
	})

	MenuGroup:AddDivider()

	MenuGroup:AddLabel("Menu bind")
		:AddKeyPicker("MenuKeybind", {
			Default = 0x70,
			Mode = "Toggle",
			Popup = false,
			Text = "Menu keybind",
		})

	Library.Options.MenuKeybind:OnChanged(function(Value)
		if Library.ActiveWindow then
			Library.ActiveWindow.MenuKey = Value
		end
	end)

	Library.ToggleKeybind = Library.Options.MenuKeybind

	MenuGroup:AddButton("Unload", {
		Text = "Unload",
		DoubleClick = true,
		Callback = function()
			Library:Unload()
		end,
	})

	return MenuGroup
end

_G.Galax = _G.Galax or {}
_G.Galax["addons/EssentialsManager.lua"] = EssentialsManager

return EssentialsManager
