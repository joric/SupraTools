local UEHelpers = require("UEHelpers")

local function findBestObject(keywords)
    local matches = {}

    for _, obj in pairs(FindAllOf("Object") or {}) do
        if obj.GetFullName then
            local ok, fullname = pcall(function() return obj:GetFullName() end)
            if ok and fullname then
                local lowered = fullname:lower()
                local match = true
                for _, kw in ipairs(keywords) do
                    if not lowered:find(kw:lower(), 1, true) then
                        match = false
                        break
                    end
                end
                if match then
                    table.insert(matches, fullname)
                end
            end
        end
    end

    if #matches == 0 then
        return nil
    end

    table.sort(matches, function(a, b)
        if #a ~= #b then
            return #a < #b  -- shorter first
        else
            return a:lower() < b:lower()  -- then alphabetically
        end
    end)

    return matches[1]  -- shortest & alphabetically lowest
end


local AssetRegistryHelpers = nil
local AssetRegistry = nil

local function CacheAssetRegistry()
    if AssetRegistryHelpers and AssetRegistry then return end

    AssetRegistryHelpers = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    if not AssetRegistryHelpers:IsValid() then Log("AssetRegistryHelpers is not valid\n") end

    if AssetRegistryHelpers then
        AssetRegistry = AssetRegistryHelpers:GetAssetRegistry()
        if AssetRegistry:IsValid() then return end
    end

    AssetRegistry = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryImpl")
    if AssetRegistry:IsValid() then return end

    error("AssetRegistry is not valid\n")
end


local function unwrapFName(val)
    if type(val) == "string" then
        return val
    end

    -- RemoteUnrealParam holding FName?
    if val.get then
        local ok, inner = pcall(val.get, val)
        if ok and inner and inner.ToString then
            local ok2, s = pcall(inner.ToString, inner)
            if ok2 and type(s) == "string" then
                return s
            end
        end
    end

    -- Direct FName?
    if val.ToString then
        local ok, s = pcall(val.ToString, val)
        if ok and type(s) == "string" then
            return s
        end
    end

    return tostring(val)
end


local function GetAssetPathsByKeywords(keywords)
    local results = {}
    local outPaths = {}

    AssetRegistry:GetAllCachedPaths(outPaths)

    for _, fstr in ipairs(outPaths) do
        local path = unwrapFName(fstr)
        local loweredPath = path:lower()
        local match = true

        for _, kw in ipairs(keywords) do
            if not loweredPath:find(kw:lower(), 1, true) then
                match = false
                break
            end
        end

        if match then
            table.insert(results, path)
        end
    end

    return results
end

local function GetAssetsByKeywords(keywords)
    local results = {}

    CacheAssetRegistry() -- ensure AssetRegistryHelpers and AssetRegistry are valid
    local outAssets = {}
    AssetRegistry:GetAllAssets(outAssets, false)

    for i, AssetData in ipairs(outAssets) do

        local path = AssetData.ObjectPath and AssetData.ObjectPath or ""

        print(AssetData, AssetData:get())

        local match = true

        --[[
        local loweredPath = path:lower()
        for _, kw in ipairs(keywords) do
            if not loweredPath:find(kw:lower(), 1, true) then
                match = false
                break
            end
        end
        ]]

        if i>5 then break end

        if match then
            table.insert(results, path)
        end
    end

    return results
end

local function FindAssetsByKeywords(keywords) -- see findobject.md
    results = {}
    local Object = FindObject(keywords[2] or 'BlueprintGeneratedClass', keywords[1])
    if Object then
        table.insert(results, Object:GetFullName())
    end
    return results
end

RegisterConsoleCommandHandler("find", function(FullCommand, Parameters, Ar)

    local matches = FindAssetsByKeywords(Parameters)
    for i, path in ipairs(matches) do
        Ar:Log(path)
    end

    -- local matches = findAssetsByKeyword({"Carriables", "ButtonBattery"})
    -- for i, path in ipairs(matches) do
    --    print("Match:", path)
    -- end

    -- local name = findBestObject(Parameters)
    -- if name then
    --     Ar:Log(name)
    -- end

    -- TODO find asset by substring
    -- see ue4ss\Mods\BPModLoaderMod\Scripts\main.lua
    -- see https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/AssetRegistry?application_version=4.27

    return true
end)

