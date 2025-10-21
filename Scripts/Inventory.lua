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

local function tagify(name)
    for _, sub in ipairs({"Buy", "BP_Purchase", "Purchase", "Equipment", "Inventory", "_C$", "^_"}) do
        name = name:gsub(sub, "")
    end
    return name:lower()
end

local function ToggleEquipment(eqDef, pc, add)
    local eqm = pc.Character:K2_GetComponentsByClass(StaticFindObject('/Script/LyraGame.LyraEquipmentManagerComponent'))[1]:get()

    local instances = eqm:GetEquipmentInstancesOfDefinitionType(eqDef)

    if add then
        local eqInst = eqm:EquipItem(eqDef)
        print("equipped", eqInst:GetFullName())
    else
        for _,param in ipairs(instances or {}) do
            local eqInst = param:get()
            eqm:UnequipItem(eqInst)
            print("unequipped", eqInst:GetFullName())
        end
    end
end

local function ToggleInventory(name, pc, add)
    local inv = pc:K2_GetComponentsByClass(StaticFindObject('/Script/LyraGame.LyraInventoryManagerComponent'))[1]:get()

    local obj = FindObject('BlueprintGeneratedClass', name)
    if not obj:IsValid() then
        return false, "could not find object"
    end

    local cdo = StaticFindObject(obj:GetFullName():gsub(name, "Default__" .. name):match("%s+(.*)")) -- maybe try GetDefaultObject instead
    if not cdo:IsValid() then
        return false, "could not find cdo"
    end

    local eqDef = nil
    for i = 1, #cdo.Fragments do
        local frag = cdo.Fragments[i]
        if frag.EquipmentDefinition:IsValid() then
            ToggleEquipment(frag.EquipmentDefinition, pc, add)
        end
    end

    local invInst = inv:FindFirstItemStackByDefinition(obj)

    if add then
        if invInst:IsValid() then
            return false, "Already wearing this inventory"
        end
        inv:AddItemDefinition(obj, 1)
    else -- remove
        if not invInst:IsValid() then
            return false, "Not wearing this inventory"
        end
        inv:RemoveItemInstance(invInst)
    end

    return true, "OK"
end

local function ToggleItem(name, add)
    local pc = UEHelpers.GetPlayerController()
    if not pc:IsValid() or not pc.Pawn:IsValid() or not pc.Character:IsValid() then
        return false, "could not find valid player controller"
    end

    if name:find("Inventory_") then
        return ToggleInventory(name, pc, add)
    end

    LoadAsset(name)

    local obj = FindObject('BlueprintGeneratedClass', name)
    if not obj:IsValid() then
        return false, "could not find object"
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

local function addItem(out, obj, filter, substrings)
    if not obj or not obj:IsValid() then return end
    if not hasSubstring(obj:GetFullName(), substrings) then return end
    local name = obj:GetFName():ToString()
    if name and (not filter or name:lower():find(filter:lower())) then
        table.insert(out, name)
    end
end

local function GetItems(filter)
    local maxobj = 65535
    local out = {}

    for _, obj in pairs(FindObjects(maxobj, "BlueprintGeneratedClass", "", 0, 0, false) or {}) do
        addItem(out, obj, filter, {"/Buy", "/BP_Purchase", "/Purchase", "/Inventory"})
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
        Ar:Log(string.format("%s (%s)", tagify(name), name))
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


