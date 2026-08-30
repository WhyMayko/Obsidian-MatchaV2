local WebhookManager = {
	Library = nil,
	Webhooks = {},
	Templates = {},
	DefaultWebhook = nil,
	AutoloadWebhook = nil,
}

local HttpService = game:GetService("HttpService")
local SettingsFolder = "Galax/Obsidian/Settings"
local WebhookFolder = SettingsFolder .. "/Webhooks"
local DefaultWebhookFile = SettingsFolder .. "/DefaultWebhook.txt"

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
	return tostring(name or "Webhook"):gsub("[^%w%s_%-]", "_") .. ".txt"
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
		error("WebhookManager: file read failed for " .. path .. "!", 2)
	end

	local ok, data = pcall(function() return HttpService:JSONDecode(source) end)
	if not ok or type(data) ~= "table" then
		return nil
	end

	return data
end

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local r = {}
	for k, v in pairs(t) do
		r[k] = deepCopy(v)
	end
	return r
end

local function compilePlaceholders(str, vars)
	if type(str) ~= "string" then return str end
	return str:gsub("%{(%w+)%}", function(key)
		local v = vars[key]
		if v ~= nil then return tostring(v) end
		return "{" .. key .. "}"
	end)
end

local function compileTable(t, vars)
	if type(t) ~= "table" then return compilePlaceholders(t, vars) end
	local r = {}
	for k, v in pairs(t) do
		r[k] = compileTable(v, vars)
	end
	return r
end

function WebhookManager:SetLibrary(library)
	self.Library = library
end

function WebhookManager:Add(name, url)
	if not name or not url or url == "" then
		return false, "Name and URL are required!"
	end
	self.Webhooks[name] = { Name = name, Url = url }

	local path = WebhookFolder .. "/" .. fileName(name)
	local ok, err = writeTable(path, { Name = name, Url = url })
	if not ok then
		self.Webhooks[name] = nil
		return false, err
	end

	if not self.LoadedWebhook then
		self.LoadedWebhook = self.Webhooks[name]
	end

	return true
end

function WebhookManager:AddTemplate(name, template)
	if not name or not template then
		return false, "Name and template are required!"
	end
	self.Templates[name] = deepCopy(template)
	return true
end

function WebhookManager:GetTemplate(name)
	return self.Templates[name]
end

function WebhookManager:GetCurrent()
	if self.LoadedWebhook then
		return self.LoadedWebhook
	end
	if self.AutoloadWebhook then
		local name = self.AutoloadWebhook.Name
		local data = self.Webhooks[name]
		if data then
			return data
		end
	end
	return nil
end

function WebhookManager:Compile(templateName, variables)
	local template = self.Templates[templateName]
	if not template then
		return nil, "Template not found: " .. tostring(templateName) .. "!"
	end

	local payload = compileTable(template, variables or {})

	if payload.embeds then
		for _, embed in ipairs(payload.embeds) do
			if type(embed) == "table" then
				if embed.footer and type(embed.footer) == "table" then
					embed.footer.text = compilePlaceholders(embed.footer.text, variables or {})
				end
				if embed.author and type(embed.author) == "table" then
					embed.author.name = compilePlaceholders(embed.author.name, variables or {})
				end
			end
		end
	end

	return payload
end

function WebhookManager:SendPayload(url, payload)
	if not url or url == "" then
		return false, "No webhook URL provided!"
	end

	local body = HttpService:JSONEncode(payload)
	local resp = httppost(url, body, "application/json", {
		["Content-Type"] = "application/json",
		["User-Agent"] = "Roblox/WinInet",
	})
	if resp == "" then
		return false, "Request failed or unreachable host!"
	end

	return true, "Sent successfully!"
end

function WebhookManager:Send(webhookName, templateName, variables)
	local current = webhookName and self.Webhooks[webhookName] or self:GetCurrent()
	if not current or not current.Url or current.Url == "" then
		return false, "No active webhook URL!"
	end

	local payload, err = self:Compile(templateName, variables)
	if not payload then
		return false, err
	end

	return self:SendPayload(current.Url, payload)
end

function WebhookManager:SendRaw(url, payload)
	return self:SendPayload(url, payload)
end

function WebhookManager:Test(webhookName, message)
	local current = webhookName and self.Webhooks[webhookName] or self:GetCurrent()
	if not current or not current.Url or current.Url == "" then
		return false, "No webhook loaded!"
	end

	local user = game:GetService("Players").LocalPlayer
	local payload = {
		content = tostring(message or "Hello from Obsidian Matcha V2!"),
		embeds = {
			{
				title = "Webhook Test",
				description = tostring(message or "Hello from Obsidian Matcha V2!"),
				color = 0x8aa2ff,
				fields = {
					{ name = "User", value = user and user.Name or "Unknown", inline = true },
					{ name = "UserId", value = user and tostring(user.UserId) or "0", inline = true },
					{ name = "PlaceId", value = tostring(game.PlaceId or 0), inline = true },
				},
				footer = { text = "Obsidian Matcha V2" },
			}
		}
	}

	return self:SendPayload(current.Url, payload)
end

function WebhookManager:Refresh()
	ensureFolder(WebhookFolder)

	for _, path in ipairs(listfiles(WebhookFolder) or {}) do
		local pathText = tostring(path)
		local baseName = pathText:match("([^/\\]+)$") or pathText
		if baseName:match("%.txt$") then
			local data = readTable(pathText)
			if data and data.Name and data.Url then
				self.Webhooks[data.Name] = { Name = data.Name, Url = data.Url }
			end
		end
	end

	local names = {}
	for name in pairs(self.Webhooks) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

function WebhookManager:Delete(name)
	if not name then
		return false, "No webhook name provided!"
	end

	self.Webhooks[name] = nil
	local path = WebhookFolder .. "/" .. fileName(name)
	if isfile(path) then
		delfile(path)
	end

	if self.AutoloadWebhook and self.AutoloadWebhook.Name == name then
		self:ResetDefault()
	end

	if self.LoadedWebhook and self.LoadedWebhook.Name == name then
		self.LoadedWebhook = nil
	end

	return true
end

function WebhookManager:GetAutoloadWebhook()
	local saved = readTable(DefaultWebhookFile)
	if saved and saved.Name and saved.Url then
		self.AutoloadWebhook = saved
	end

	if self.AutoloadWebhook then
		local name = self.AutoloadWebhook.Name
		if not self.Webhooks[name] then
			self:Refresh()
			if not self.Webhooks[name] then
				self:ResetDefault()
			end
		end
	end

	if not self.AutoloadWebhook then
		return nil
	end

	return self.AutoloadWebhook.Name
end

function WebhookManager:SetDefault(name)
	if not name then
		return false, "No webhook name provided!"
	end

	local data = self.Webhooks[name]
	if not data then
		return false, "Webhook not found!"
	end

	self.AutoloadWebhook = data
	return writeTable(DefaultWebhookFile, { Name = data.Name, Url = data.Url })
end

function WebhookManager:ResetDefault()
	self.AutoloadWebhook = nil
	if isfile(DefaultWebhookFile) then
		delfile(DefaultWebhookFile)
	end
	return true
end

function WebhookManager:LoadAutoload()
	self:GetAutoloadWebhook()
	if self.AutoloadWebhook then
		self.LoadedWebhook = self.AutoloadWebhook
		return self.AutoloadWebhook
	end
	return nil
end

function WebhookManager:BuildWebhookSection(tab)
	local Library = self.Library
	if not Library then
		error("WebhookManager:BuildWebhookSection requires Library (call SetLibrary first)!", 2)
	end

	local saveManager = _G.Galax and _G.Galax.SaveManager
	if saveManager then
		saveManager:SetIgnoreIndexes({ "WebhookManager_TestMessage" })
	end

	local Options = Library.Options

	local setupSection = tab:AddLeftGroupbox("Webhook Setup")

	setupSection:AddLabel("Copy the code below, paste it into your script with your Discord webhook URL and execute it.", true)

	setupSection:AddButton({
		Text = "Copy Webhook Addon Code",
		Func = function()
			local snippet = [[WebhookManager:Add("MyWebhook", "PASTE_YOUR_DISCORD_WEBHOOK_URL_HERE")]]
			pcall(function() setclipboard(snippet) end)
			Library:Notify({
				Title = "Webhook Addon",
				Description = "Copied setup code to clipboard!",
				Time = 4,
			})
		end,
	})

	setupSection:AddDivider({ Text = "Test Webhook" })

	setupSection:AddInput("WebhookManager_TestMessage", {
		Text = "Test Message",
		Placeholder = "Hello from Obsidian Matcha V2!",
	})

	setupSection:AddButton({
		Text = "Send Test Message",
		Func = function()
			local current = self:GetCurrent()
			if not current then
				Library:Notify({
					Title = "Webhook",
					Description = "No webhook loaded! Load a webhook first.",
					Time = 4,
				})
				return
			end

			local message = Options and Options.WebhookManager_TestMessage and Options.WebhookManager_TestMessage.Value or "Hello from Obsidian Matcha V2!"
			if not message or message == "" then
				message = "Hello from Obsidian Matcha V2!"
			end

			local ok, err = self:Test(nil, message)
			if ok then
				Library:Notify({
					Title = "Webhook",
					Description = "Test sent successfully!",
					Time = 4,
				})
			else
				Library:Notify({
					Title = "Webhook Error",
					Description = "Failed to send: " .. tostring(err),
					Time = 5,
				})
			end
		end,
	})

	local function refreshWebhookList()
		if Options.WebhookManager_WebhookList then
			Options.WebhookManager_WebhookList:SetValues(self:Refresh())
			Options.WebhookManager_WebhookList:SetValue(nil)
		end
	end

	local function updateCurrentLabel()
		if self.WebhookCurrentLabel then
			local current = self:GetCurrent()
			local name = current and current.Name or "None"
			self.WebhookCurrentLabel:SetText("Current: " .. tostring(name))
		end
	end

	local webhookSection = tab:AddRightGroupbox("Saved Webhooks")

	self.WebhookCurrentLabel = webhookSection:AddLabel("Current: " .. tostring(self:GetCurrent() and self:GetCurrent().Name or "None"))

	webhookSection:AddDropdown("WebhookManager_WebhookList", {
		Text = "Webhook list",
		Values = self:Refresh(),
		AllowNull = true,
	})

	webhookSection:AddButton("Load Webhook", function()
		local name = Options.WebhookManager_WebhookList:Get()
		if not name then
			Library:Notify({ Title = "Webhook", Description = "No webhook selected!", Time = 3 })
			return
		end

		local data = self.Webhooks[name]
		if not data then
			Library:Notify({ Title = "Webhook", Description = "Webhook not found!", Time = 3 })
			return
		end

		self.LoadedWebhook = data
		Library:Notify({ Title = "Webhook", Description = string.format("Loaded webhook %q", name), Time = 4 })
		updateCurrentLabel()
	end)

	webhookSection:AddButton({
		Text = "Delete Webhook",
		DoubleClick = true,
		Func = function()
			local name = Options.WebhookManager_WebhookList:Get()
			if not name then
				return
			end

			local ok, err = self:Delete(name)
			if not ok then
				Library:Notify({ Title = "Webhook Error", Description = "Failed to delete: " .. tostring(err), Time = 4 })
				return
			end

			Library:Notify({ Title = "Webhook", Description = string.format("Deleted webhook %q", name), Time = 4 })
			refreshWebhookList()
			updateCurrentLabel()
		end,
	})

	webhookSection:AddButton("Refresh List", function()
		refreshWebhookList()
	end)

	webhookSection:AddButton("Set as Autoload", function()
		local name = Options.WebhookManager_WebhookList:Get()
		if not name then
			Library:Notify({ Title = "Webhook", Description = "No webhook selected!", Time = 3 })
			return
		end

		local ok, err = self:SetDefault(name)
		if not ok then
			Library:Notify({ Title = "Webhook Error", Description = "Failed to set autoload: " .. tostring(err), Time = 4 })
			return
		end

		Library:Notify({ Title = "Webhook", Description = string.format("Autoload set to %q", name), Time = 4 })
		updateCurrentLabel()
	end)

	webhookSection:AddButton("Reset Autoload", function()
		self:ResetDefault()
		Library:Notify({ Title = "Webhook", Description = "Autoload reset.", Time = 4 })
		updateCurrentLabel()
	end)

	self:LoadAutoload()
end

WebhookManager.BuildSection = WebhookManager.BuildWebhookSection

_G.Galax = _G.Galax or {}
_G.Galax["addons/WebhookManager.lua"] = WebhookManager
_G.Galax.WebhookManager = WebhookManager

ensureFolder(WebhookFolder)

return WebhookManager
