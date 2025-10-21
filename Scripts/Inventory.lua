-- a newer version of inventory manager, possibly universal for all games
-- intended to replace grant and deploy commands with add/remove/list commands
-- pc.LyraInventoryManagerComponent and char.LyraEquipmentManagerComponent are nil accessors
-- to get valid ones you have to iterate through attached components

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

local function getName(fullpath)
    return fullpath:match("([^.]+)$")
end

local function getPath(fullpath)
    return fullpath:match("%s(.+)")
end

local function namefy(path)
    return getName(path)
end

local function tagify(name)
    name = namefy(name)
    for _, sub in ipairs({"Buy", "BP_Purchase", "Purchase", "Equipment", "Inventory", "_C$", "^_"}) do
        name = name:gsub(sub, "")
    end
    return name:lower()
end

local function ToggleEquipment(obj, pc, add)
    local eqm = pc.Character:K2_GetComponentsByClass(StaticFindObject('/Script/LyraGame.LyraEquipmentManagerComponent'))[1]:get()

    print("equipment", obj:GetFullName())

    if add then
        local item = eqm:EquipItem(obj)
        print("equipped", item:GetFullName())
    else
        for _,param in ipairs(eqm:GetEquipmentInstancesOfDefinitionType(obj) or {}) do
            local item = param:get()
            eqm:UnequipItem(item)
            print("unequipped", item:GetFullName())
        end
    end
end

local function ToggleInventory(name, obj, pc, add)
    local inv = pc:K2_GetComponentsByClass(StaticFindObject('/Script/LyraGame.LyraInventoryManagerComponent'))[1]:get()

    local cdo = obj:GetCDO()
    if cdo:IsValid() then
        for i = 1, #cdo.Fragments do
            local frag = cdo.Fragments[i]
            if frag.EquipmentDefinition:IsValid() then
                ToggleEquipment(frag.EquipmentDefinition, pc, add)
            end
        end
    end

    local item = inv:FindFirstItemStackByDefinition(obj)

    if add then
        if item:IsValid() then
            return false, "Already wearing this inventory"
        end
        inv:AddItemDefinition(obj, 1)
    else -- remove
        if not item:IsValid() then
            return false, "Not wearing this inventory"
        end
        inv:RemoveItemInstance(item)
    end

    return true, "OK"
end

local function ToggleItem(name, add)
    local pc = UEHelpers.GetPlayerController()
    if not pc:IsValid() or not pc.Pawn:IsValid() or not pc.Character:IsValid() then
        return false, "could not find valid player controller"
    end

    print("loading " .. name)
    LoadAsset(name)

    local obj = FindObject('BlueprintGeneratedClass', namefy(name))
    if not obj:IsValid() then
        return false, "could not find object"
    end

    if name:find("Inventory_") then
        return ToggleInventory(name, obj, pc, add)
    end

    local delta = {X=15,Y=50,Z=-30} -- shift object a little ({X=15,Y=50,Z=-30} works for shell and stomp)

    local cam = pc.PlayerCameraManager
    local pos, rot = cam:GetCameraLocation(), cam:GetCameraRotation()
    local dv = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(rot), delta.Y)
    local loc = UEHelpers.GetKismetMathLibrary():Add_VectorVector(pos, dv)

    loc.X = loc.X + delta.X
    loc.Z = loc.Z + delta.Z

    local actor = UEHelpers.GetWorld():SpawnActor(obj, loc, rot)

    actor:SetActorScale3D({X=1,Y=1,Z=1}) -- optionally make actor BIG so it has more surface to autoselect

    pc.Character:Using() -- and pick up item! this is very unreliable (object shapes are very different) but sometimes works

    ExecuteWithDelay(250, function() pc.Character:UseReleased() end)

    return true
end


local function RemoveItem(name)
    return ToggleItem(name, false)
end

local function AddItem(name)
    return ToggleItem(name, true)
end

local function consolefy2(data)
    local out = {}
    for _, name in ipairs(data) do
        table.insert(out, tagify(name))
    end
    table.sort(out)

    local result = {}
    local lastFirst, count = "", 0

    for _, name in ipairs(out) do
        local first = name:sub(1,1)
        if first ~= lastFirst then
            if lastFirst ~= "" then table.insert(result, "\n") end
            count = 0
        elseif count % 5 == 0 then
            table.insert(result, "\n")
        else
            table.insert(result, " ")
        end
        table.insert(result, name)
        lastFirst, count = first, count + 1
    end

    return table.concat(result)
end

local function hasSubstring(str, substrings)
    for _, sub in ipairs(substrings) do
        if str:find(sub) then
            return true
        end
    end
    return false
end

local function GetItems(filter)
    local out = {}

    -- load UE5 Lyra inventory items from registry (may not be loaded)

    CacheAssetRegistry()
    local assets = {}
    AssetRegistry:GetAllAssets(assets, false)

    for _, data in ipairs(assets) do
        local a_name  = data:get().AssetName:ToString()
        local p_name = data:get().PackageName:ToString()
        local path = p_name .. "." .. a_name
        if path:find("_C$") and path:find("/Inventory") then
            local name = path:match("([^.]+)$")
            if name and (not filter or name:lower():find(filter:lower())) then
                table.insert(out, path)
            end
        end
    end

    -- UE4 objects apparently don't have _C postfix

    for _, obj in pairs(FindObjects(65536, "BlueprintGeneratedClass", "", 0, 0, false) or {}) do
        if obj and obj:IsValid() then
            local path = getPath(obj:GetFullName())
            if hasSubstring(path, {"/Buy", "/BP_Purchase", "/Purchase"}) then
                local name = obj:GetFName():ToString()
                if name and (not filter or name:lower():find(filter:lower())) then
                    table.insert(out, name)
                end
            end
        end
    end

    table.sort(out, function(a, b)
        return tagify(a) < tagify(b)
    end)

    return out
end

local function findExactMatch(tbl, value)
    for _, v in ipairs(tbl) do
        if tagify(v) == value then
            return v
        end
    end
    return nil
end

RegisterConsoleCommandHandler("list", function(FullCommand, Parameters, Ar)
    local items = GetItems()
    for _,name in ipairs(items) do
        Ar:Log(string.format("%s (%s)", tagify(name), namefy(name)))
    end
    return true
end)

local function processItemCommand(FullCommand, Parameters, Ar, callback)
    local filter = Parameters[1]
    if not filter then
        local items = GetItems()
        Ar:Log(consolefy2(items))
        Ar:Log(string.format("Usage: %s <name, class name, or substring>", FullCommand))
        return true
    end

    local items = GetItems(filter)
    local name = #items==1 and items[1] or findExactMatch(items, filter)

    if name then
        ok, err = callback(name)
        if ok then
            Ar:Log(string.format("%s [%s] (%s)", err or "command succeeded", tagify(name), name))
        else
            Ar:Log(err)
        end
    else
        Ar:Log(consolefy2(items))
    end

    return true
end

RegisterConsoleCommandHandler("add", function(FullCommand, Parameters, Ar)
    return processItemCommand(FullCommand, Parameters, Ar, AddItem)
end)

RegisterConsoleCommandHandler("remove", function(FullCommand, Parameters, Ar)
    return processItemCommand(FullCommand, Parameters, Ar, RemoveItem)
end)

RegisterConsoleCommandHandler("give", function(FullCommand, Parameters, Ar)
    return processItemCommand(FullCommand, Parameters, Ar, AddItem)
end)

RegisterConsoleCommandHandler("drop", function(FullCommand, Parameters, Ar)
    return processItemCommand(FullCommand, Parameters, Ar, RemoveItem)
end)


