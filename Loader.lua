local Loader = {}

Loader.Repo = "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/"
Loader.CoreModules = {}
Loader.CoreAssets = {
    "assets/icons/check.png",
    "assets/icons/chevron-down.png",
    "assets/icons/chevron-up.png",
    "assets/icons/gift.png",
    "assets/icons/key.png",
    "assets/icons/move.png",
    "assets/icons/move-diagonal-2.png",
    "assets/icons/search.png",
    "assets/icons/settings.png",
    "assets/icons/user.png",
}

_G.Galax = _G.Galax or {}

local function loadModule(path)
    local loaded = _G.Galax[path]
    if type(loaded) == "table" then
        return loaded
    end

    local source = game:HttpGet(Loader.Repo .. path)
    assert(type(source) == "string" and source ~= "", "Loader.lua failed to download " .. path .. "!")

    local chunk = assert(loadstring(source), "Loader.lua failed to compile " .. path .. "!")
    local module = chunk()

    if type(module) ~= "table" then
        module = _G.Galax[path]
    end
    assert(type(module) == "table", "Loader.lua received no module from " .. path .. "!")
    _G.Galax[path] = module
    return module
end

local function loadAsset(path)
    _G.Galax.Assets = _G.Galax.Assets or {}
    local data = _G.Galax.Assets[path]
    if type(data) == "string" and data ~= "" then return data end
    local ok, downloaded = pcall(function()
        return game:HttpGet(Loader.Repo .. path)
    end)
    if ok and type(downloaded) == "string" and downloaded:sub(1, 8) == "\137PNG\r\n\26\n" then
        _G.Galax.Assets[path] = downloaded
        return downloaded
    end
    return nil
end

function Loader:Load()
    task.spawn(function()
        for _, path in ipairs(self.CoreAssets) do
            loadAsset(path)
        end
    end)

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

    _G.Galax["Library.lua"] = library
    _G.Galax["addons/ThemeManager.lua"] = thememanager
    _G.Galax["addons/SaveManager.lua"] = savemanager
    _G.Galax["addons/EssentialsManager.lua"] = essentialsmanager
    _G.Galax["addons/WebhookManager.lua"] = webhookmanager
    _G.Galax["addons/GroupGuard.lua"] = groupguard

    _G.Galax.Library = library
    _G.Galax.ThemeManager = thememanager
    _G.Galax.SaveManager = savemanager
    _G.Galax.EssentialsManager = essentialsmanager
    _G.Galax.WebhookManager = webhookmanager
    _G.Galax.GroupGuard = groupguard
    _G.Galax.Options = library.Options
    _G.Galax.Toggles = library.Toggles

    return library, thememanager, savemanager, essentialsmanager, webhookmanager, groupguard
end

_G.Galax["Loader.lua"] = Loader
_G.Galax.Get = function()
    return _G.Galax.Library, _G.Galax.ThemeManager, _G.Galax.SaveManager, _G.Galax.EssentialsManager, _G.Galax.WebhookManager, _G.Galax.GroupGuard
end

setmetatable(_G.Galax, {
    __call = function()
        return _G.Galax.Library, _G.Galax.ThemeManager, _G.Galax.SaveManager, _G.Galax.EssentialsManager, _G.Galax.WebhookManager, _G.Galax.GroupGuard
    end,
})

Loader:Load()

return _G.Galax
