local GroupGuard = {
	Library = nil,
	GroupId = nil,
	Running = false,
	Busy = false,
	Fetched = {},
	Queue = {},
	Acted = {},
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local function fetchJson(url)
	local ok, raw = pcall(function() return game:HttpGet(url) end)
	if not (ok and type(raw) == "string") or raw == "" then
		return nil
	end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(data) == "table" then
		return data
	end
	return nil
end

local function spGetPlayers()
	local ok, list = pcall(function() return Players:GetPlayers() end)
	return ok and list or {}
end

local function safeName(uid)
	for _, plr in ipairs(spGetPlayers()) do
		local ok, pid = pcall(function() return plr.UserId end)
		if ok and pid == uid then
			local okName, name = pcall(function() return plr.Name end)
			return okName and name or tostring(uid)
		end
	end
	return tostring(uid)
end

local function guarantee(o, name)
	if not o then
		assert(false, string.format("GroupGuard: %s is required!", tostring(name)))
	end
end

local function requireGroup(self)
	guarantee(self.GroupId, "SetGroup(groupId) before use")
end

function GroupGuard:SetLibrary(library)
	self.Library = library
end

function GroupGuard:SetGroup(groupId)
	local gid = type(groupId) == "number" and groupId or tonumber(tostring(groupId or ""))
	if not gid then
		error("GroupGuard: SetGroup needs a group id!", 2)
	end
	self.GroupId = gid
	self:ResetState()
	if self.Library and self.Library.Options and self.Library.Options.GroupGuard_Ranks then
		self:RefreshRanks()
	end
end

function GroupGuard:ResetState()
	self.Fetched = {}
	self.Queue = {}
	self.Acted = {}
end

function GroupGuard:Ranks()
	requireGroup(self)
	local data = fetchJson(string.format("https://groups.roblox.com/v1/groups/%d/roles", self.GroupId))
	local out = {}
	if data and type(data.roles) == "table" then
		for _, role in ipairs(data.roles) do
			if type(role) == "table" and type(role.name) == "string" then
				out[#out + 1] = role.name
			end
		end
		table.sort(out)
	end
	return out
end

function GroupGuard:MembershipRole(userId)
	requireGroup(self)
	local data = fetchJson(string.format("https://groups.roblox.com/v1/users/%d/groups/roles", userId))
	if data and type(data.data) == "table" then
		for _, entry in ipairs(data.data) do
			local group = (type(entry) == "table") and entry.group
			local role = (type(entry) == "table") and entry.role
			if type(group) == "table" and group.id == self.GroupId and type(role) == "table" and type(role.name) == "string" then
				return role.name
			end
		end
	end
	return nil
end

function GroupGuard:Trigger(name, role)
	self.Library:Notify(string.format("%s ( %s )", name, role), 5)
end

function GroupGuard:handleMember(uid, role)
	if self.Acted[uid] then
		return
	end
	local Options = self.Library and self.Library.Options
	local selected = Options and Options.GroupGuard_Ranks and Options.GroupGuard_Ranks:Get()
	local match = false
	if selected then
		for _, rank in ipairs(selected) do
			if rank == role then
				match = true
				break
			end
		end
	end
	if not match then
		return
	end
	self.Acted[uid] = true
	self:Trigger(safeName(uid), role)
end

function GroupGuard:Start()
	if self.Running then
		return
	end
	requireGroup(self)
	self:ResetState()
	self.Running = true
	self.Busy = false

	task.spawn(function()
		while self.Running do
			for _, plr in ipairs(spGetPlayers()) do
				local ok, uid = pcall(function() return plr.UserId end)
				if ok and uid and not self.Fetched[uid] then
					self.Fetched[uid] = false
					self.Queue[#self.Queue + 1] = uid
				end
			end
			task.wait(3)
		end
	end)

	task.spawn(function()
		while self.Running do
			if not self.Busy and #self.Queue > 0 then
				self.Busy = true
				local uid = table.remove(self.Queue, 1)
				local role = self:MembershipRole(uid)
				self.Fetched[uid] = true
				if role then
					self:handleMember(uid, role)
				end
				self.Busy = false
			end
			task.wait(1)
		end
	end)
end

function GroupGuard:Stop()
	self.Running = false
end

function GroupGuard:BuildSection(tab)
	local Library = self.Library
	if not Library then
		error("GroupGuard: call SetLibrary first!", 2)
	end

	local detector = tab:AddLeftGroupbox("Rank Detector")
	local settings = tab:AddRightGroupbox("Settings")

	detector:AddMultiDropdown("GroupGuard_Ranks", {
		Text = "Watch these ranks",
		Values = {},
		Searchable = true,
		Min = 0,
	})

	detector:AddButton("Refresh ranks", function()
		self:RefreshRanks()
	end)

	detector:AddButton("Test", function()
		self:Trigger("User", "Test")
	end)

	settings:AddToggle("GroupGuard_Enabled", {
		Text = "Enabled",
		Default = false,
		Callback = function(value)
			if value then
				self:Start()
			else
				self:Stop()
			end
		end,
	})

	self:RefreshRanks()
end

function GroupGuard:RefreshRanks()
	local handle = self.Library.Options and self.Library.Options.GroupGuard_Ranks
	if not handle then
		return
	end
	handle:SetValues(self:Ranks())
end

_G.Galax = _G.Galax or {}
_G.Galax["addons/GroupGuard.lua"] = GroupGuard

return GroupGuard
