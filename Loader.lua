local Loader = {}

Loader.Repo = "https://raw.githubusercontent.com/WhyMayko/Obsidian-MatchaV2/refs/heads/main/"
Loader.CoreModules = {}
Loader.CoreAssets = {
    "assets/icons/check.png",
    "assets/icons/chevron-down.png",
    "assets/icons/chevron-up.png",
    "assets/icons/key.png",
    "assets/icons/move.png",
    "assets/icons/move-diagonal-2.png",
    "assets/icons/search.png",
    "assets/icons/settings.png",
    "assets/icons/user.png",
}

local function loadModule(path)
    _G.Galax = _G.Galax or {}
    local loaded = _G.Galax[path]
    if type(loaded) == "table" then
        return loaded
    end

    local ok, source = pcall(function()
        return game:HttpGet(Loader.Repo .. path)
    end)
    assert(ok and type(source) == "string" and source ~= "", "Loader.lua failed to download " .. path .. "!")

    local chunk, compileError = loadstring(source)
    assert(type(chunk) == "function", "Loader.lua failed to compile " .. path .. ": " .. tostring(compileError) .. "!")

    local ran, module = pcall(chunk)
    assert(ran, "Loader.lua failed to run " .. path .. ": " .. tostring(module) .. "!")

    if type(module) ~= "table" then
        module = _G.Galax[path]
    end
    assert(type(module) == "table", "Loader.lua received no module from " .. path .. "!")
    _G.Galax[path] = module
    return module
end

local function loadAsset(path)
    _G.Galax = _G.Galax or {}
    _G.Galax.Assets = _G.Galax.Assets or {}
    local data = _G.Galax.Assets[path]
    if type(data) == "string" and data ~= "" then return data end
    local ok, downloaded = pcall(function()
        return game:HttpGet(Loader.Repo .. path)
    end)
    assert(ok and type(downloaded) == "string" and downloaded:sub(1, 8) == "\137PNG\r\n\26\n", "Loader.lua failed to download PNG " .. path .. "!")
    _G.Galax.Assets[path] = downloaded
    return downloaded
end

function Loader:Load()
    for _, path in ipairs(self.CoreModules) do
        loadModule(path)
    end
    for _, path in ipairs(self.CoreAssets) do
        loadAsset(path)
    end
    return loadModule("Library.lua")
end

_G.Galax = _G.Galax or {}
_G.Galax["Loader.lua"] = Loader

local library = Loader:Load()
assert(type(library) == "table", "Loader.lua failed to return Library.lua!")
_G.Galax["Library.lua"] = library

return library
