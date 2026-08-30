local ThemeFields = {
	"BackgroundColor",
	"MainColor",
	"AccentColor",
	"OutlineColor",
	"FontColor",
}

local BuiltInThemes = {
	{ name = "Default", FontColor = "#ffffff", MainColor = "#191919", AccentColor = "#7d55ff", BackgroundColor = "#111111", OutlineColor = "#282828" },
	{ name = "Ayu Dark", FontColor = "#b3b1ad", MainColor = "#0f1419", AccentColor = "#e6b450", BackgroundColor = "#0a0e14", OutlineColor = "#273747" },
	{ name = "BBot", FontColor = "#ffffff", MainColor = "#1e1e1e", AccentColor = "#7e48a3", BackgroundColor = "#232323", OutlineColor = "#141414" },
	{ name = "Blood Moon", FontColor = "#ffcccc", MainColor = "#1e0000", AccentColor = "#ff0000", BackgroundColor = "#140000", OutlineColor = "#330000" },
	{ name = "Catppuccin", FontColor = "#d9e0ee", MainColor = "#302d41", AccentColor = "#f5c2e7", BackgroundColor = "#1e1e2e", OutlineColor = "#575268" },
	{ name = "Cyberpunk", FontColor = "#f9f9f9", MainColor = "#262335", AccentColor = "#00ff9f", BackgroundColor = "#1a1a2e", OutlineColor = "#413c5e" },
	{ name = "Discord", FontColor = "#dbdee1", MainColor = "#2b2d31", AccentColor = "#5865f2", BackgroundColor = "#313338", OutlineColor = "#1e1f22" },
	{ name = "Dracula", FontColor = "#f8f8f2", MainColor = "#44475a", AccentColor = "#ff79c6", BackgroundColor = "#282a36", OutlineColor = "#6272a4" },
	{ name = "Everforest", FontColor = "#d3c6aa", MainColor = "#323c41", AccentColor = "#a7c080", BackgroundColor = "#2b3339", OutlineColor = "#4b565c" },
	{ name = "Fatality", FontColor = "#ffffff", MainColor = "#1e1842", AccentColor = "#c50754", BackgroundColor = "#191335", OutlineColor = "#3c355d" },
	{ name = "GitHub", FontColor = "#c9d1d9", MainColor = "#161b22", AccentColor = "#58a6ff", BackgroundColor = "#0d1117", OutlineColor = "#30363d" },
	{ name = "Gruvbox", FontColor = "#ebdbb2", MainColor = "#3c3836", AccentColor = "#fb4934", BackgroundColor = "#282828", OutlineColor = "#504945" },
	{ name = "Jester", FontColor = "#ffffff", MainColor = "#242424", AccentColor = "#db4467", BackgroundColor = "#1c1c1c", OutlineColor = "#373737" },
	{ name = "Material", FontColor = "#eeffff", MainColor = "#212121", AccentColor = "#82aaff", BackgroundColor = "#151515", OutlineColor = "#424242" },
	{ name = "Matrix", FontColor = "#00ff41", MainColor = "#111111", AccentColor = "#00ff41", BackgroundColor = "#0d0d0d", OutlineColor = "#003b00" },
	{ name = "Mint", FontColor = "#ffffff", MainColor = "#242424", AccentColor = "#3db488", BackgroundColor = "#1c1c1c", OutlineColor = "#373737" },
	{ name = "Monokai", FontColor = "#f8f8f2", MainColor = "#272822", AccentColor = "#f92672", BackgroundColor = "#1e1f1c", OutlineColor = "#49483e" },
	{ name = "Nebula", FontColor = "#e0e0e0", MainColor = "#1b1442", AccentColor = "#b06ab3", BackgroundColor = "#0f0c29", OutlineColor = "#302b63" },
	{ name = "Nord", FontColor = "#eceff4", MainColor = "#3b4252", AccentColor = "#88c0d0", BackgroundColor = "#2e3440", OutlineColor = "#4c566a" },
	{ name = "Oceanic Next", FontColor = "#d8dee9", MainColor = "#1b2b34", AccentColor = "#6699cc", BackgroundColor = "#16232a", OutlineColor = "#343d46" },
	{ name = "One Dark", FontColor = "#abb2bf", MainColor = "#282c34", AccentColor = "#c678dd", BackgroundColor = "#21252b", OutlineColor = "#5c6370" },
	{ name = "Outrun", FontColor = "#00ffff", MainColor = "#1a0a3a", AccentColor = "#ff007f", BackgroundColor = "#0d0221", OutlineColor = "#2b1154" },
	{ name = "Quartz", FontColor = "#ffffff", MainColor = "#232330", AccentColor = "#426e87", BackgroundColor = "#1d1b26", OutlineColor = "#27232f" },
	{ name = "Rosé Pine", FontColor = "#e0def4", MainColor = "#1f1d2e", AccentColor = "#c4a7e7", BackgroundColor = "#191724", OutlineColor = "#26233a" },
	{ name = "Royal", FontColor = "#ffffff", MainColor = "#24243e", AccentColor = "#e94560", BackgroundColor = "#1a1a2e", OutlineColor = "#3a3a5a" },
	{ name = "Solarized", FontColor = "#839496", MainColor = "#073642", AccentColor = "#cb4b16", BackgroundColor = "#002b36", OutlineColor = "#586e75" },
	{ name = "Spotify", FontColor = "#ffffff", MainColor = "#181818", AccentColor = "#1db954", BackgroundColor = "#121212", OutlineColor = "#282828" },
	{ name = "Synthwave", FontColor = "#f0f0f0", MainColor = "#2b213a", AccentColor = "#f92aad", BackgroundColor = "#262335", OutlineColor = "#36274e" },
	{ name = "Tokyo Night", FontColor = "#ffffff", MainColor = "#191925", AccentColor = "#6759b3", BackgroundColor = "#16161f", OutlineColor = "#323232" },
	{ name = "Twitch", FontColor = "#efeff1", MainColor = "#18181b", AccentColor = "#9146ff", BackgroundColor = "#0e0e10", OutlineColor = "#303032" },
	{ name = "Ubuntu", FontColor = "#ffffff", MainColor = "#3e3e3e", AccentColor = "#e2581e", BackgroundColor = "#323232", OutlineColor = "#191919" },
	{ name = "Vampire", FontColor = "#ffb3c6", MainColor = "#24141c", AccentColor = "#ff3366", BackgroundColor = "#1a0f14", OutlineColor = "#3d1f2d" },
	{ name = "Vercel", FontColor = "#ededed", MainColor = "#111111", AccentColor = "#ffffff", BackgroundColor = "#000000", OutlineColor = "#333333" },
}

local ThemeManager = {
	Library = nil,
	CustomThemes = {},
	BuiltInThemes = {},
	DefaultTheme = { Type = "web", Name = "Default" },
}

local HttpService = game:GetService("HttpService")
local SettingsFolder = "Galax/Obsidian/Settings"
local ThemeFolder = SettingsFolder .. "/Themes"
local DefaultThemeFile = SettingsFolder .. "/DefaultTheme.txt"

local function ensureFolder(path)
	local current = ""
	for part in tostring(path):gmatch("[^/\\]+") do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

local function fileName(name)
	return tostring(name or "Theme"):gsub("[^%w%s_%-]", "_") .. ".txt"
end

local function writeTable(path, data)
	local folder = tostring(path):match("^(.*)[/\\][^/\\]+$")
	ensureFolder(folder or SettingsFolder)

	local encoded
	local ok, _ = pcall(function()
		local parts = {}
		for k, v in pairs(data) do
			table.insert(parts, string.format('\t%q: %s', tostring(k), HttpService:JSONEncode(v)))
		end
		table.sort(parts)
		encoded = "{\n" .. table.concat(parts, ",\n") .. "\n}"
	end)
	if not encoded then
		encoded = HttpService:JSONEncode(data)
	end

	writefile(path, encoded)
	return true
end

local function readTable(path)
	if not isfile(path) then
		return nil
	end

	local source = readfile(path)
	if type(source) ~= "string" then
		error("ThemeManager readTable: file read failed for " .. path, 2)
	end

	local ok, data = pcall(function() return HttpService:JSONDecode(source) end)
	if not ok then
		error("ThemeManager readTable: failed to decode JSON from " .. path, 2)
	end

	if type(data) == "table" then
		return data
	end

	error("ThemeManager readTable: decoded JSON is not a table for " .. path, 2)
end

local function colorToHex(color, alpha)
	if not color or typeof(color) ~= "Color3" then
		return nil
	end

	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)

	if alpha and alpha > 0 then
		local a = math.floor((1 - alpha) * 255 + 0.5)
		return string.format("#%02x%02x%02x%02x", r, g, b, a)
	end

	return string.format("#%02x%02x%02x", r, g, b)
end

local function hexToColor3(hex)
	if typeof(hex) == "Color3" then
		return hex
	end

	if type(hex) ~= "string" then
		return nil
	end

	hex = hex:gsub("#", "")
	if #hex ~= 6 and #hex ~= 8 then
		return nil
	end

	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)

	if not r or not g or not b then
		return nil
	end

	return Color3.fromRGB(r, g, b)
end

local function currentThemeSnapshot(Library, name)
	local theme = { name = name }
	local window = Library.ActiveWindow
	local current = window and window:GetTheme() or {}

	theme.BackgroundColor = colorToHex(current.Background)
	theme.MainColor = colorToHex(current.Main)
	theme.AccentColor = colorToHex(current.Accent)
	theme.OutlineColor = colorToHex(current.Outline)
	theme.FontColor = colorToHex(current.Text)
	theme.Outline2 = colorToHex(current.Outline2)
	theme.Surface2 = colorToHex(current.Surface2)
	theme.Muted = colorToHex(current.Muted)
	theme.DimText = colorToHex(current.DimText)
	theme.PopupHover = colorToHex(current.PopupHover)
	theme.Bottombar = colorToHex(current.Bottombar)
	theme.BottombarBorder = colorToHex(current.BottombarBorder)
	theme.FooterText = colorToHex(current.FooterText)
	theme.Transparency = window and window:GetTransparency() or 1
	theme.CornerRadius = window and window:GetCornerRadius() or 4

	return theme
end

for index, entry in ipairs(BuiltInThemes) do
	entry.index = index
	ThemeManager.BuiltInThemes[entry.name] = entry
end

function ThemeManager:SetLibrary(library)
	self.Library = library
end

function ThemeManager:SetFolder(folder)
	folder = tostring(folder or ""):gsub("\\", "/"):gsub("/+$", "")
	assert(folder ~= "", "ThemeManager folder is required!")
	SettingsFolder = folder
	ThemeFolder = SettingsFolder .. "/Themes"
	DefaultThemeFile = SettingsFolder .. "/DefaultTheme.txt"
end

function ThemeManager:ThemeUpdate()
	local Library = self.Library
	if not Library then
		return
	end

	local theme = {}

	for _, field in ipairs(ThemeFields) do
		local option = Library.Options and Library.Options[field]
		if option and option.Get then
			theme[field] = option:Get()
		end
	end

	if Library.ActiveWindow then
		Library.ActiveWindow:SetTheme(theme)
	end
end

function ThemeManager:ApplyTheme(name, themeType)
	local Library = self.Library
	local data

	if themeType == "web" then
		data = self.BuiltInThemes[name]
	elseif themeType == "local" or themeType == "custom" then
		data = self.CustomThemes[name]
	else
		data = self.CustomThemes[name] or self.BuiltInThemes[name]
	end

	if not Library or not data then
		error("ThemeManager:ApplyTheme requires Library and theme data", 2)
		return false, "theme not found"
	end

	self._applyingTheme = true
	if Library.ActiveWindow then
		Library.ActiveWindow:SetTheme(data)
	end

	for _, field in ipairs(ThemeFields) do
		local option = Library.Options and Library.Options[field]
		local color = hexToColor3(data[field])
		if option and option.SetValueRGB and color then
			option:SetValueRGB(color)
		end
	end

	if Library.ActiveWindow and Library.ActiveWindow.SetSidebarImage then
		Library.ActiveWindow:SetSidebarImage(
			data.SidebarImage or nil,
			data.SidebarImageScale,
			data.SidebarImageX,
			data.SidebarImageY
		)
	end

	local win = Library.ActiveWindow
	if win then
		local transparency = tonumber(data.Transparency)
		if transparency then
			win:SetTransparency(math.max(0.1, math.min(1, transparency)))
		end
		if data.WindowIcon ~= nil then
			win:SetIconUrl(data.WindowIcon)
		end
		if type(data.WindowTitle) == "string" and data.WindowTitle ~= "" then
			win.Title = data.WindowTitle
		end
		if type(data.WindowFooter) == "string" then
			win.Footer = data.WindowFooter
		end
		local transparencyOption = Library.Options and Library.Options.ThemeManager_Transparency
		if transparencyOption and transparencyOption.SetValue then
			transparencyOption:SetValue(math.floor(win:GetTransparency() * 100 + 0.5))
		end
	end
	self._applyingTheme = false
	return true
end

function ThemeManager:SaveCustomTheme(name)
	local Library = self.Library

	if not Library then
		return false, "library not set"
	end

	if not name or name:gsub(" ", "") == "" then
		return false, "no name"
	end

	local existingTheme = self.CustomThemes[name] or {}
	local theme = currentThemeSnapshot(Library, name)

	theme.SidebarImage = existingTheme.SidebarImage or (Library.ActiveWindow and Library.ActiveWindow.SidebarImage)
	theme.SidebarImageScale = existingTheme.SidebarImageScale or (Library.ActiveWindow and Library.ActiveWindow.SidebarImageScale)
	theme.SidebarImageX = existingTheme.SidebarImageX or (Library.ActiveWindow and Library.ActiveWindow.SidebarImageX)
	theme.SidebarImageY = existingTheme.SidebarImageY or (Library.ActiveWindow and Library.ActiveWindow.SidebarImageY)
	theme.WindowIcon = existingTheme.WindowIcon or (Library.ActiveWindow and Library.ActiveWindow.IconUrl)
	theme.WindowTitle = existingTheme.WindowTitle
	theme.WindowFooter = existingTheme.WindowFooter

	for _, field in ipairs(ThemeFields) do
		local option = Library.Options and Library.Options[field]
		if option and option.Get then
			theme[field] = colorToHex(option:Get()) or theme[field]
		end
	end

	self.CustomThemes[name] = theme
	local ok, err = writeTable(ThemeFolder .. "/" .. fileName(name), theme)
	if not ok then
		self.CustomThemes[name] = nil
		return false, err
	end

	return true
end

function ThemeManager:Delete(name)
	self.CustomThemes[name] = nil
	local path = ThemeFolder .. "/" .. fileName(name)
	if isfile(path) then
		delfile(path)
	end
	if self.DefaultTheme.Type == "local" and self.DefaultTheme.Name == name then
		self.DefaultTheme = { Type = "web", Name = "Default" }
		writeTable(DefaultThemeFile, self.DefaultTheme)
	end
	return true
end

function ThemeManager:ReloadCustomThemes()
	ensureFolder(ThemeFolder)

	for _, path in ipairs(listfiles(ThemeFolder) or {}) do
		local pathText = tostring(path)
		local baseName = pathText:match("([^/\\]+)$") or pathText
		if baseName:match("%.txt$") then
			local data = readTable(pathText)
			if data and data.name then
				self.CustomThemes[data.name] = data
			end
		end
	end

	local names = {}

	for name in pairs(self.CustomThemes) do
		names[#names + 1] = name
	end

	table.sort(names)
	return names
end

function ThemeManager:GetDefaultTheme()
	local saved = readTable(DefaultThemeFile)
	if saved and saved.Type and saved.Name then
		self.DefaultTheme = saved
	end

	local themeType = self.DefaultTheme.Type or "web"
	local themeName = self.DefaultTheme.Name or "Default"

	if themeType == "custom" then
		themeType = "local"
	end

	if themeType == "web" then
		if not self.BuiltInThemes[themeName] then
			themeName = "Default"
		end
	elseif themeType == "local" then
		self:ReloadCustomThemes()
		if not self.CustomThemes[themeName] then
			self:ResetDefault()
			themeType = "web"
			themeName = "Default"
		end
	else
		themeType = "web"
		themeName = "Default"
	end

	return themeType, themeName
end

function ThemeManager:LoadDefault()
	local themeType, themeName = self:GetDefaultTheme()
	self:ApplyTheme(themeName, themeType)
end

function ThemeManager:SaveDefault(name, themeType)
	local resolvedType = themeType == "custom" and "local" or (themeType or (self.CustomThemes[name] and "local" or "web"))
	local resolvedName = name or "Default"

	if resolvedType == "web" and not self.BuiltInThemes[resolvedName] then
		return false, "web theme not found"
	end
	if resolvedType == "local" and not self.CustomThemes[resolvedName] then
		self:ReloadCustomThemes()
		if not self.CustomThemes[resolvedName] then
			return false, "local theme not found"
		end
	end

	self.DefaultTheme = {
		Type = resolvedType,
		Name = resolvedName,
	}

	return writeTable(DefaultThemeFile, self.DefaultTheme)
end

function ThemeManager:ResetDefault()
	self.DefaultTheme = { Type = "web", Name = "Default" }

	writeTable(DefaultThemeFile, self.DefaultTheme)

	self:ApplyTheme("Default", "web")

	return true, "web", "Default"
end

function ThemeManager:CreateGroupBox(tab)
	return tab:AddLeftGroupbox("Themes")
end

function ThemeManager:CreateThemeManager(groupbox)
	local Library = self.Library
	if not Library then
		error("ThemeManager:CreateThemeManager requires Library (call SetLibrary first)", 2)
	end

	local function refreshCustomThemeList()
		if Library.Options.ThemeManager_CustomThemeList then
			Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
		end
	end

	local function resetDefaultTheme()
		local themeType, themeName = self:GetDefaultTheme()
		self:ApplyTheme(themeName, themeType)

		if themeType == "local" then
			if Library.Options.ThemeManager_CustomThemeList then
				Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
				Library.Options.ThemeManager_CustomThemeList:SetValue(themeName)
			end
			if Library.Options.ThemeManager_ThemeList then
				Library.Options.ThemeManager_ThemeList:SetValue(nil)
			end
		else
			if Library.Options.ThemeManager_ThemeList then
				Library.Options.ThemeManager_ThemeList:SetValue(themeName)
			end
			if Library.Options.ThemeManager_CustomThemeList then
				Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
			end
		end

		Library:Notify(string.format("Loaded default theme: %q", tostring(themeName)), 4)
	end

	groupbox:AddLabel("Background color"):AddColorPicker("BackgroundColor", { Default = Color3.fromRGB(17, 17, 17) })
	groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = Color3.fromRGB(25, 25, 25) })
	groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = Color3.fromRGB(125, 85, 255) })
	groupbox:AddLabel("Outline color"):AddColorPicker("OutlineColor", { Default = Color3.fromRGB(40, 40, 40) })
	groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = Color3.fromRGB(255, 255, 255) })
	groupbox:AddSlider("ThemeManager_Transparency", {
		Text = "UI transparency",
		Min = 10,
		Max = 100,
		Default = Library.ActiveWindow and math.floor(Library.ActiveWindow:GetTransparency() * 100 + 0.5) or 100,
		Suffix = "%",
		Rounding = 0,
		Callback = function(value)
			if Library.ActiveWindow then
				Library.ActiveWindow:SetTransparency(value / 100)
			end
		end,
	})

	groupbox:AddSlider("ThemeManager_CornerRadius", {
		Text = "Corner radius",
		Min = 0,
		Max = 12,
		Default = Library.ActiveWindow and Library.ActiveWindow:GetCornerRadius() or 4,
		Rounding = 0,
		Callback = function(value)
			if Library.ActiveWindow then
				Library.ActiveWindow:SetCornerRadius(value)
			end
			Library.CornerRadius = value
		end,
	})

	local themeNames = {}
	for name in pairs(self.BuiltInThemes) do
		themeNames[#themeNames + 1] = name
	end
	table.sort(themeNames, function(a, b)
		return (self.BuiltInThemes[a].index or 99) < (self.BuiltInThemes[b].index or 99)
	end)

	groupbox:AddDivider()

	groupbox:AddDropdown("ThemeManager_ThemeList", {
		Text = "Theme list",
		Values = themeNames,
		Default = themeNames[1],
	})

	groupbox:AddButton("Set as default", function()
		local themeName = Library.Options.ThemeManager_ThemeList.Value
		local ok, err = self:SaveDefault(themeName, "web")
		if not ok then
			Library:Notify("Failed to set default theme: " .. tostring(err), 4)
			return
		end
		Library:Notify(string.format("Set default theme to %q", tostring(themeName)), 4)
	end)

	if Library.Options.ThemeManager_ThemeList then
		Library.Options.ThemeManager_ThemeList:OnChanged(function()
			local themeName = Library.Options.ThemeManager_ThemeList.Value
			if not themeName then
				return
			end
			if Library.Options.ThemeManager_CustomThemeList then
				Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
			end
			self:ApplyTheme(themeName, "web")
		end)
	end

	groupbox:AddDivider()

	groupbox:AddInput("ThemeManager_CustomThemeName", {
		Text = "Custom theme name",
	})

	groupbox:AddButton("Create theme", function()
		local name = Library.Options.ThemeManager_CustomThemeName.Value

		if not name or name:gsub(" ", "") == "" then
			Library:Notify("Invalid theme name (empty)", 4)
			return
		end

		local ok, err = self:SaveCustomTheme(name)
		if not ok then
			Library:Notify("Failed to create theme: " .. tostring(err), 4)
			return
		end

		Library:Notify(string.format("Created theme %q", name), 4)
		refreshCustomThemeList()
	end)

	groupbox:AddDivider()

	groupbox:AddDropdown("ThemeManager_CustomThemeList", {
		Text = "Custom themes",
		Values = self:ReloadCustomThemes(),
		AllowNull = true,
	})

	groupbox:AddButton("Load theme", function()
		local name = Library.Options.ThemeManager_CustomThemeList.Value
		if name then
			self:ApplyTheme(name, "local")
			Library:Notify(string.format("Loaded theme %q", name), 4)
		end
	end)

	groupbox:AddButton("Overwrite theme", function()
		local name = Library.Options.ThemeManager_CustomThemeList.Value
		if name then
			local ok, err = self:SaveCustomTheme(name)
			if not ok then
				Library:Notify("Failed to overwrite theme: " .. tostring(err), 4)
				return
			end
			Library:Notify(string.format("Overwrote theme %q", name), 4)
		end
	end)

	groupbox:AddButton({
		Text = "Delete theme",
		DoubleClick = true,
		Func = function()
			local name = Library.Options.ThemeManager_CustomThemeList.Value
			if not name then
				return
			end

			local ok, err = self:Delete(name)
			if not ok then
				Library:Notify("Failed to delete theme: " .. tostring(err), 4)
				return
			end

			Library:Notify(string.format("Deleted theme %q", name), 4)
			refreshCustomThemeList()
		end
	})

	groupbox:AddButton("Refresh list", function()
		refreshCustomThemeList()
	end)

	groupbox:AddButton("Set as default", function()
		local name = Library.Options.ThemeManager_CustomThemeList.Value
		if not name then
			Library:Notify("No custom theme selected", 4)
			return
		end

		local ok, err = self:SaveDefault(name, "local")
		if not ok then
			Library:Notify("Failed to set default theme: " .. tostring(err), 4)
			return
		end
		Library:Notify(string.format("Set default local theme to %q", name), 4)
	end)

	groupbox:AddButton("Reset default", resetDefaultTheme)

	local function updateTheme()
		if self._applyingTheme then
			return
		end
		self:ThemeUpdate()
	end

	for _, field in ipairs({ "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor" }) do
		if Library.Options[field] then
			Library.Options[field]:OnChanged(updateTheme)
		end
	end

	self:LoadDefault()
end

function ThemeManager:ApplyToTab(tab)
	self:CreateThemeManager(self:CreateGroupBox(tab))
end

function ThemeManager:ApplyToGroupbox(groupbox)
	self:CreateThemeManager(groupbox)
end

_G.Galax = _G.Galax or {}
_G.Galax["addons/ThemeManager.lua"] = ThemeManager
_G.Galax.ThemeManager = ThemeManager

local CommunityRepo = "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/community/"

_G.community = _G.community or {}

_G.community.loadTheme = function(name)
	if not name or name == "" then
		warn("community.loadTheme: name is required")
		return
	end
	local url = CommunityRepo .. "themes/" .. tostring(name) .. ".txt"
	local ok, source = pcall(game.HttpGet, game, url)
	if not ok or not source or source == "" then
		warn("community.loadTheme: failed to download '" .. name .. "'")
		return
	end
	local path = ThemeFolder .. "/" .. tostring(name):gsub("[^%w%s_%-]", "_") .. ".txt"
	local writeOk = pcall(writefile, path, source)
	if not writeOk then
		warn("community.loadTheme: failed to save file")
		return
	end
	local HttpService = game:GetService("HttpService")
	local data = HttpService:JSONDecode(source)
	if type(data) == "table" then
		data.name = data.name or name
		ThemeManager.CustomThemes[data.name] = data
		ThemeManager:ApplyTheme(data.name, "local")
	end
end

return ThemeManager
