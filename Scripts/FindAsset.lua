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


local function GetAssetsByKeywords(keywords)
    -- Ensure Asset Registry is cached
    local AssetRegistryHelpers = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    local AssetRegistry = AssetRegistryHelpers:GetAssetRegistry()

    local results = {}

    -- Get all assets (true = include unloaded assets)
    local AllAssets = AssetRegistry:GetAllAssets(true) -- that doesn't exist

    for _, data in ipairs(AllAssets) do
        local path = tostring(data.ObjectPath)
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

RegisterConsoleCommandHandler("find", function(FullCommand, Parameters, Ar)

    -- local matches = GetAssetsByKeywords(Parameters)
    -- for i, path in ipairs(matches) do
    --     print("Match:", path)
    -- end

    -- local matches = findAssetsByKeyword({"Carriables", "ButtonBattery"})
    -- for i, path in ipairs(matches) do
    --    print("Match:", path)
    -- end

    local name = findBestObject(Parameters)
    if name then
        Ar:Log(name)
    end

    -- TODO find asset by substring
    -- see ue4ss\Mods\BPModLoaderMod\Scripts\main.lua
    -- see https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/AssetRegistry?application_version=4.27

    return true
end)

