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
    "assets/icons/lucide/swords.png",
    "assets/icons/lucide/crosshair.png",
    "assets/icons/lucide/layout-grid.png",
    "assets/icons/lucide/list.png",
    "assets/icons/lucide/eye.png",
    "assets/icons/lucide/zap.png",
    "assets/icons/lucide/compass.png",
    "assets/icons/lucide/shield.png",
    "assets/icons/send.png",
    "assets/icons/lucide/sparkles.png",
    "assets/icons/lucide/bell.png",
    "assets/icons/lucide/activity.png",
    "assets/icons/lucide/folder.png",
    "assets/icons/lucide/lock.png",
    "assets/icons/lucide/play.png",
    "assets/icons/lucide/target.png",
    "assets/icons/lucide/sliders-horizontal.png",
    "assets/icons/lucide/palette.png",
    "assets/icons/lucide/code.png",
    "assets/icons/lucide/terminal.png",
}

_G.Obsidian = _G.Obsidian or {}

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

local function loadAsset(path)
    _G.Obsidian.Assets = _G.Obsidian.Assets or {}
    local data = _G.Obsidian.Assets[path]
    if type(data) == "string" and data ~= "" then return data end
    local ok, downloaded = pcall(function()
        return game:HttpGet(Loader.Repo .. path)
    end)
    if ok and type(downloaded) == "string" and downloaded:sub(1, 8) == "\137PNG\r\n\26\n" then
        _G.Obsidian.Assets[path] = downloaded
        local shortName = path:match("([^/\\]+)%.png$")
        if shortName then
            _G.Obsidian.Assets[shortName] = downloaded
        end
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
