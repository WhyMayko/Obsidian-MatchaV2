local Loader = {}

Loader.Repo = "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/"
Loader.CoreModules = {}
local function loadModule(path)
    local loaded = _G.Obsidian[path]
    if type(loaded) == "table" then
        return loaded
    end

    local source = game:HttpGet(Loader.Repo .. path)
    assert(type(source) == "string" and source ~= "", "Loader.lua failed to download " .. path .. "!")

    local chunk = assert(loadstring(source), "Loader.lua failed to compile " .. path .. "!")
    local module = chunk()

    if type(module) ~= "table" then
        module = _G.Obsidian[path]
    end
    assert(type(module) == "table", "Loader.lua received no module from " .. path .. "!")
    _G.Obsidian[path] = module
    return module
end

function Loader:Load()
    local library = loadModule("Library.lua")
    local thememanager = loadModule("addons/ThemeManager.lua")
    local savemanager = loadModule("addons/SaveManager.lua")
    local essentialsmanager = loadModule("addons/EssentialsManager.lua")
    local webhookmanager = loadModule("addons/WebhookManager.lua")
    local groupguard = loadModule("addons/GroupGuard.lua")

    library.ThemeManager = thememanager
    library.SaveManager = savemanager
    library.EssentialsManager = essentialsmanager
    library.WebhookManager = webhookmanager
    library.GroupGuard = groupguard

    _G.Obsidian["Library.lua"] = library
    _G.Obsidian["addons/ThemeManager.lua"] = thememanager
    _G.Obsidian["addons/SaveManager.lua"] = savemanager
    _G.Obsidian["addons/EssentialsManager.lua"] = essentialsmanager
    _G.Obsidian["addons/WebhookManager.lua"] = webhookmanager
    _G.Obsidian["addons/GroupGuard.lua"] = groupguard

    _G.Obsidian.Library = library
    _G.Obsidian.ThemeManager = thememanager
    _G.Obsidian.SaveManager = savemanager
    _G.Obsidian.EssentialsManager = essentialsmanager
    _G.Obsidian.WebhookManager = webhookmanager
    _G.Obsidian.GroupGuard = groupguard
    _G.Obsidian.Options = library.Options
    _G.Obsidian.Toggles = library.Toggles

    return library, thememanager, savemanager, essentialsmanager, webhookmanager, groupguard
end

_G.Obsidian["Loader.lua"] = Loader
_G.Obsidian.Get = function()
    return _G.Obsidian.Library, _G.Obsidian.ThemeManager, _G.Obsidian.SaveManager, _G.Obsidian.EssentialsManager, _G.Obsidian.WebhookManager, _G.Obsidian.GroupGuard
end

setmetatable(_G.Obsidian, {
    __call = function()
        return _G.Obsidian.Library, _G.Obsidian.ThemeManager, _G.Obsidian.SaveManager, _G.Obsidian.EssentialsManager, _G.Obsidian.WebhookManager, _G.Obsidian.GroupGuard
    end,
})

Loader:Load()

return _G.Obsidian
