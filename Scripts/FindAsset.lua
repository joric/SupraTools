local UEHelpers = require("UEHelpers")

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

local function FindBlueprintsByKeywords(keywords) -- see findobject.md
    results = {}
    local Object = FindObject(keywords[2] or 'BlueprintGeneratedClass', keywords[1])
    if Object then
        table.insert(results, Object:GetFullName())
    end
    return results
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

-- FName ObjectPath; -- error
-- FName PackagePath; -- works
-- FName PackageName; --works
-- FName AssetName; -- works
-- FName AssetClass; -- always outputs "none"

local function FindAssetsByKeywords(keywords)
    local results = {}
    CacheAssetRegistry()

    local assets = {}
    ---@param OutAssetData TArray<FAssetData>
    ---@param bIncludeOnlyOnDiskAssets boolean
    ---@return boolean
    AssetRegistry:GetAllAssets(assets, false)

    -- table.insert(keywords, "/Inventory_")
    -- table.insert(keywords, "_C")

    i = 0
    for _, data in ipairs(assets) do
        local a_name  = data:get().AssetName:ToString()
        local a_class = data:get().AssetClass:ToString()
        local p_name = data:get().PackageName:ToString()
        local p_path = data:get().PackagePath:ToString()

        local path = p_name .. "." .. a_name

        local loweredPath = path:lower()
        local match = true

        for _, kw in ipairs(keywords) do
            if not loweredPath:find(kw:lower(), 1, true) then
                match = false
                break
            end
        end

        if match then
            -- print(path)
            table.insert(results, path)

            i = i + 1
            if i==100 then break end
        end

    end
    table.sort(results)
    return results
end

RegisterConsoleCommandHandler("find", function(FullCommand, Parameters, Ar)
    local matches = FindAssetsByKeywords(Parameters)
    for i, path in ipairs(matches) do
        Ar:Log(path)
    end
    return true
end)

