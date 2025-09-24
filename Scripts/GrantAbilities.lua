local UEHelpers = require("UEHelpers")

local function addInventory(InvMgr, InvDef)
    local item = InvMgr:FindFirstItemStackByDefinition(InvDef)
    if item and item:IsValid() then
        print("Already granted")
        return false
    end

    if not InvMgr:CanAddItemDefinition(InvDef, 1) then
        print("Cannot add item: CanAddItemDefinition returned false")
        return false
    end

    local newItem = InvMgr:AddItemDefinition(InvDef, 1)
    if not newItem then
        print("AddItemDefinition failed")
        return false
    end

    return true
end

local function removeInventory(InvMgr, InvDef)
    local item = InvMgr:FindFirstItemStackByDefinition(InvDef)
    if not item or not item:IsValid() then
        print("Not found")
        return false
    end

    InvMgr:RemoveItemInstance(item)
    return true
end

local function updateInventoryInternal(InvMgr, InvDef, doAdd)
    if doAdd then
        return addInventory(InvMgr, InvDef)
    else
        return removeInventory(InvMgr, InvDef)
    end
end

local function updateInventory(InvDefPath, doAdd)
    local InvMgr
    for _, obj in ipairs(FindAllOf("LyraInventoryManagerComponent") or {}) do
        if obj:IsValid() and string.find(obj:GetFullName(), "SupraworldPlayerController_C") then
            InvMgr = obj
            break
        end
    end

    if not InvMgr then
        print("Could not find inventory manager")
        return nil
    end

    LoadAsset(InvDefPath)
    local InvDef = StaticFindObject(InvDefPath)

    if not InvDef or not InvDef:IsValid() then
        print("Could not load inventory definition", InvDefPath)
        return nil
    end

    return updateInventoryInternal(InvMgr, InvDef, doAdd)
end

local function grantAbilityInternal(InvDefPath)
    return updateInventory(InvDefPath, true)
end

local function revokeAbilityInternal(InvDefPath)
    return updateInventory(InvDefPath, false)
end

local function grantAbility(InvDefPath)
    ExecuteInGameThread(function()
        grantAbilityInternal(InvDefPath)
    end)
end

local function getInventoryPath(str)
    local obj = FindObject("BlueprintGeneratedClass", str)
    if not obj or not obj:IsValid() then
        obj = FindObject("BlueprintGeneratedClass", string.format("Inventory_%s_C", str))
    end
    if not obj or not obj:IsValid() then return nil end
    return obj:GetFullName():match("%s(.+)")
end

local function getAllAbilities()
    local out = {}
    for _, obj in pairs(FindObjects(10000, "BlueprintGeneratedClass", "", 0, 0, false) or {}) do
        if obj and obj:IsValid() then
            local path = tostring(obj:GetFullName())
            if path:find("/Abilities/") and path:find("/Inventory") then
                local name = path:match("Inventory_([^%.]+)")
                if name then
                    table.insert(out, name:lower())
                end
            end
        end
    end
    return table.concat(out, "\n")
end

local function inventoryHandler(fn, actionVerb, usageMsg, failMsg)
    return function(_, params, Ar)
        local arg = params[1]
        if not arg then
            Ar:Log(usageMsg)
            Ar:Log(getAllAbilities())
            return true
        end

        local path = getInventoryPath(arg)
        if not path then
            Ar:Log(string.format("could not find %s", arg))
        elseif fn(path) then
            Ar:Log(string.format("%s %s", actionVerb, path))
        else
            Ar:Log(string.format("%s %s", failMsg, path))
        end

        return true
    end
end

local function grantAbilities()
    grantAbility("/Supraworld/Abilities/Walk/Inventory_Walk.Inventory_Walk_C")
    grantAbility("/Supraworld/Abilities/Crouch/Inventory_Crouch.Inventory_Crouch_C")
    grantAbility("/Supraworld/Abilities/Run/Inventory_Run.Inventory_Run_C")
    grantAbility("/Supraworld/Abilities/Jump/Jumps/Inventory_Jump.Inventory_Jump_C")
    grantAbility("/Supraworld/Abilities/Jump/JumpHeight/Inventory_JumpHeightDouble.Inventory_JumpHeightDouble_C")
    grantAbility("/Supraworld/Abilities/Strength/Inventory_Strength.Inventory_Strength_C")

    grantAbility("/Supraworld/Abilities/BlowGun/Core/Inventory_BlowGun.Inventory_BlowGun_C")
    grantAbility("/Supraworld/Abilities/Toothpick/Lyra/Inventory_Toothpick.Inventory_Toothpick_C")
    grantAbility("/Supraworld/Abilities/Toothpick/Upgrades/ToothpickDart/Inventory_Toothpin_Dart.Inventory_Toothpin_Dart_C")

    grantAbility("/Supraworld/Abilities/ThoughtReading/Inventory_ThoughtReading.Inventory_ThoughtReading_C")
    grantAbility("/Supraworld/Abilities/Ghost/Inventory_ThirdEye.Inventory_ThirdEye_C")
    grantAbility("/Supraworld/Abilities/Dash/Inventory_Dash.Inventory_Dash_C")
    grantAbility("/Supraworld/Abilities/PlayerMap/Inventory_PlayerMap.Inventory_PlayerMap_C")
    grantAbility("/Supraworld/Abilities/SpongeSuit/Upgrades/Inventory_SpongeSuit.Inventory_SpongeSuit_C")

    grantAbility("/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C")  -- doesn't seem to work
    grantAbility("/Supraworld/Abilities/LaserWalk/Inventory_LaserWalk.Inventory_LaserWalk_C")
    -- grantAbility("/Supraworld/Abilities/MindControl/Inventory_MindControl.Inventory_MindControl_C") -- unfinished, breaks saves
    grantAbility("/Supraworld/Abilities/MindVision/Inventory_MindVision.Inventory_MindVision_C")
    grantAbility("/Supraworld/Abilities/Shield/Inventory_Shield.Inventory_Shield_C")

    grantAbility("/Supraworld/Abilities/SmellImmunity/Inventory_SmellImmunity.Inventory_SmellImmunity_C") -- not player compatible
end

RegisterKeyBind(Key.G, {ModifierKey.ALT}, grantAbilities)

RegisterConsoleCommandHandler("grant", inventoryHandler(grantAbilityInternal, "granted", "usage: grant <inventory>, e.g. grant spongesuit", "already have"))
RegisterConsoleCommandHandler("revoke", inventoryHandler(revokeAbilityInternal, "revoked", "usage: revoke <inventory>", "not carrying"))

