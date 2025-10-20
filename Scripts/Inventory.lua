-- a newer version of inventory manager, possibly universal for all games
-- intended to replace grant and deploy commands with add/remove/list commands

-- the issue with lyra managers is that they are unpopulated, e.g.
-- pc.LyraInventoryManagerComponent and char.LyraEquipmentManagerComponent are not valid
-- to get valid ones you have to iterate through attached components
-- you can't even assign them, e.g. pc.LyraInventoryManagerComponent = manager becomes invalid

local UEHelpers = require("UEHelpers")

local function tagify(name)
    for _, sub in ipairs({"Buy", "BP_Purchase", "Purchase", "Equipment", "_C$", "^_"}) do
        name = name:gsub(sub, "")
    end
    return name:lower()
end

local function ToggleInventory(eq_name, pc, add)
    local comp = pc:K2_GetComponentsByClass(StaticFindObject('/Script/LyraGame.LyraInventoryManagerComponent'))
    local manager = #comp>0 and comp[1]:get()
    if not manager or not manager:IsValid() then
        return false, "could not find inventory manager"
    end

    -- print("Inventory Manager", manager:IsValid(), manager:IsValid(), pc.LyraInventoryManagerComponent:IsValid())

    local name = eq_name:gsub("Equipment", "Inventory")

    LoadAsset(name)

    local obj = FindObject('BlueprintGeneratedClass', name)
    if not obj:IsValid() then
        return false, "could not find inventory"
    end

    if add then
        local item = manager:FindFirstItemStackByDefinition(obj)
        if item and item:IsValid() then
            print(name .. " already granted, re-applying (effects may double)...")
        end

        if not manager:CanAddItemDefinition(obj, 1) then
            return false, "Cannot add item, CanAddItemDefinition returned false"
        end

        local newItem = manager:AddItemDefinition(obj, 1)
        if not newItem then
            return false, "AddItemDefinition failed"
        end
        return true, "Inventory item added"
    else -- remove
        local item = manager:FindFirstItemStackByDefinition(obj)
        if not item or not item:IsValid() then
            return false, "Inventory item not found"
        end
        manager:RemoveItemInstance(item)
        return true, "Inventory item removed"
    end

    return true, "OK"
end

local function ToggleEquipment(name, pc, char, obj, add)
    local comp = char:K2_GetComponentsByClass(StaticFindObject('/Script/LyraGame.LyraEquipmentManagerComponent'))
    local manager = #comp>0 and comp[1]:get()
    if not manager or not manager:IsValid() then
        return false, "could not find equipment manager"
    end

    -- print("Equipment Manager", manager:IsValid(), char.LyraEquipmentManagerComponent:IsValid())

    local items = manager:GetEquipmentInstancesOfDefinitionType(obj)or{}

    if add then
        local item = manager:EquipItem(obj)
        if not item:IsValid() then
            return false, "Could not equip, invalid item"
        end
    else -- remove
        if #items>0 then
            for _,obj in ipairs(items) do
                local item = obj:get()
                if item:IsValid() then
                    manager:UnequipItem(item)
                end
            end
        end
    end

    return ToggleInventory(name, pc, add)
end

local function ToggleItemInternal(name, pc, char, obj, add)
    if name:find("Equipment_") then
        return ToggleEquipment(name, pc, char, obj, add)
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

    char:Using() -- and pick up item! this is very unreliable (object shapes are very different) but sometimes works

    ExecuteWithDelay(250, function() self:UseReleased() end)

    return true
end

local function ToggleItem(name, add)
    local pc = UEHelpers.GetPlayerController()
    if not pc:IsValid() or not pc.CheatManager or not pc.CheatManager:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return false, "could not find valid player controller"
    end

    local char = pc.Character
    if not char or not char:IsValid() then
        return false, "could not find character"
    end

    LoadAsset(name)

    local obj = FindObject('BlueprintGeneratedClass', name)
    if not obj:IsValid() then
        return false, "could not find object"
    end

    return ToggleItemInternal(name, pc, char, obj, add)
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
    for _, obj in pairs(FindObjects(30000, "BlueprintGeneratedClass", "", 0, 0, false) or {}) do
        if obj and obj:IsValid() then
            local path = tostring(obj:GetFullName())
            if hasSubstring(path, {"/Buy", "/BP_Purchase", "/Purchase", ".Equipment_"}) then
                local name = obj:GetFName():ToString()
                if name then
                    if not filter or name:lower():find(filter:lower()) then
                        table.insert(out, name)
                    end
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


