local HttpService = game:GetService("HttpService")

local EssentialsManager = {
	Library = nil,
	Folder = "Galax/Obsidian/Settings",
	Settings = {
		KeybindMenuOpen = false,
		InputBlock = true,
		NotificationSide = "Right",
		DPIScale = "100%",
		MenuKeybind = 0x70,
		CornerRadius = 4,
		UITransparency = 100,
	},
}

local function ensureFolder(path)
	if not isfolder(path) then
		makefolder(path)
	end
end

local function getFilePath()
	return EssentialsManager.Folder .. "/Essentials.json"
end

function EssentialsManager:SetLibrary(library)
	self.Library = library
end

function EssentialsManager:SetFolder(folder)
	self.Folder = tostring(folder or "Galax/Obsidian/Settings")
	ensureFolder(self.Folder)
end

function EssentialsManager:Save()
	ensureFolder(self.Folder)
	local filePath = getFilePath()
	local ok, json = pcall(function()
		return HttpService:JSONEncode(self.Settings)
	end)
	if ok and json then
		pcall(writefile, filePath, json)
	end
end

function EssentialsManager:AutoSave()
	self:Save()
end

function EssentialsManager:Load()
	local filePath = getFilePath()
	if not isfile(filePath) then
		return false
	end
	local ok, content = pcall(readfile, filePath)
	if not ok or not content or content == "" then
		return false
	end
	local okDec, decoded = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if okDec and type(decoded) == "table" then
		for k, v in pairs(decoded) do
			self.Settings[k] = v
		end
		return true
	end
	return false
end

function EssentialsManager:BuildSection(tab)
	local Library = self.Library
	assert(Library, "EssentialsManager: call SetLibrary first!")

	ensureFolder(self.Folder)
	self:Load()

	local MenuGroup = tab:AddLeftGroupbox("Menu", "wrench")
	local s = self.Settings

	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = s.KeybindMenuOpen == true,
		Text = "Open Keybind Menu",
		Callback = function(Value)
			s.KeybindMenuOpen = Value == true
			if Library.ActiveWindow then
				Library.ActiveWindow:SetKeybindMenuVisible(Value)
			end
			self:AutoSave()
		end,
	})

	MenuGroup:AddToggle("InputBlock", {
		Default = s.InputBlock ~= false,
		Text = "Input Block",
		Callback = function(Value)
			s.InputBlock = Value == true
			if Library.ActiveWindow then
				Library.ActiveWindow:SetInputBlocking(Value)
			end
			self:AutoSave()
		end,
	})

	MenuGroup:AddDropdown("NotificationSide", {
		Values = { "Left", "Right" },
		Default = s.NotificationSide or "Right",
		Text = "Notification Side",
		Callback = function(Value)
			s.NotificationSide = Value
			Library:SetNotifySide(Value)
			self:AutoSave()
		end,
	})

	MenuGroup:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%", "225%", "250%" },
		Default = s.DPIScale or "100%",
		Text = "DPI Scale",
		Callback = function(Value)
			s.DPIScale = Value
			if Library.ActiveWindow then
				local pct = tonumber(Value:match("%d+")) or 100
				Library.ActiveWindow:SetDPIScale(pct)
			end
			self:AutoSave()
		end,
	})

	MenuGroup:AddSlider("UICornerSlider", {
		Text = "Corner radius",
		Min = 0,
		Max = 12,
		Default = tonumber(s.CornerRadius) or 4,
		Rounding = 0,
		HideMax = true,
		Callback = function(Value)
			s.CornerRadius = Value
			if Library.ActiveWindow then
				Library.ActiveWindow:SetCornerRadius(Value)
			end
			Library.CornerRadius = Value
			self:AutoSave()
		end,
	})

	MenuGroup:AddSlider("UITransparencySlider", {
		Text = "UI transparency",
		Min = 10,
		Max = 100,
		Default = tonumber(s.UITransparency) or 100,
		Suffix = "%",
		Rounding = 0,
		HideMax = true,
		Callback = function(Value)
			s.UITransparency = Value
			if Library.ActiveWindow then
				Library.ActiveWindow:SetTransparency(Value / 100)
			end
			self:AutoSave()
		end,
	})

	MenuGroup:AddDivider()

	MenuGroup:AddLabel("Menu bind")
		:AddKeyPicker("MenuKeybind", {
			Default = s.MenuKeybind or 0x70,
			Mode = "Toggle",
			Popup = false,
			Text = "Menu keybind",
		})

	if Library.Options.MenuKeybind then
		Library.Options.MenuKeybind:OnChanged(function(Value)
			s.MenuKeybind = Value
			if Library.ActiveWindow then
				Library.ActiveWindow.MenuKey = Value
			end
			self:AutoSave()
		end)
	end

	Library.ToggleKeybind = Library.Options.MenuKeybind

	if Library.ActiveWindow then
		if s.KeybindMenuOpen then Library.ActiveWindow:SetKeybindMenuVisible(true) end
		if s.CornerRadius then Library.ActiveWindow:SetCornerRadius(s.CornerRadius) end
		if s.UITransparency then Library.ActiveWindow:SetTransparency(s.UITransparency / 100) end
		if s.DPIScale then
			local pct = tonumber(tostring(s.DPIScale):match("%d+")) or 100
			Library.ActiveWindow:SetDPIScale(pct)
		end
	end

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
_G.Galax.EssentialsManager = EssentialsManager

return EssentialsManager
