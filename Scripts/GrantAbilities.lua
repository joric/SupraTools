local UEHelpers = require("UEHelpers")

-- hardcoded to supraworld, need to find better way to get lyra managers

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


local function getInventoryManager()
    for _, obj in ipairs(FindAllOf("LyraInventoryManagerComponent") or {}) do
        if obj:IsValid() and string.find(obj:GetFullName(), "SupraworldPlayerController_C") then return obj end
    end
end

local function getEquipmentManager()
    for _, obj in ipairs(FindAllOf("LyraEquipmentManagerComponent") or {}) do
        if obj:IsValid() and string.find(obj:GetFullName(), "Player_ToyCharacter") then return obj end
    end
end

local function addInventory(InvMgr, InvDef)
    local item = InvMgr:FindFirstItemStackByDefinition(InvDef)
    if item and item:IsValid() then
        print("Already granted, re-applying (effects may double)...") -- Inventory_JumpHeightDouble_C certainly doubles the height
        -- return false
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

    print("updateInventory", InvDefPath, doAdd);

    local InvMgr = getInventoryManager()

    if not InvMgr then
        print("Could not find inventory manager")
        return nil
    end

    local InvDef = StaticFindObject(InvDefPath)
    if not InvDef or not InvDef:IsValid() then
        InvDef = LoadAsset(InvDefPath)
    end

    if not InvDef or not InvDef:IsValid() then
        print("Could not load inventory definition", InvDefPath)
        return nil
    end

    -- let's try to activate/deactivate item using equipment manager
    local EquipMgr = getEquipmentManager()
    local EquipDefPath = InvDefPath:gsub("Inventory_","Equipment_")

    local ItemDef = StaticFindObject(EquipDefPath)
    if not ItemDef or not ItemDef:IsValid() then
        ItemDef = LoadAsset(EquipDefPath)
    end

    if EquipMgr:IsValid() and ItemDef:IsValid() then
        print("ItemDef", ItemDef:GetFullName())
        if doAdd then
            ItemInstance = EquipMgr:EquipItem(ItemDef)
            if ItemInstance:IsValid() then
                print("EquipItem", ItemInstance:GetFullName())
            end
        else
            for _,obj in ipairs(EquipMgr:GetEquipmentInstancesOfDefinitionType(ItemDef)or{}) do
                local ItemInstance = obj:get()
                if ItemInstance:IsValid() then
                    print("UnequipItem", ItemInstance:GetFullName())
                    ExecuteInGameThread(function()
                        EquipMgr:UnequipItem(ItemInstance)
                    end)
                end
            end
        end
    end

    return updateInventoryInternal(InvMgr, InvDef, doAdd)
end

local function grantAbilityInternal(InvDefPath)
    return updateInventory(InvDefPath, true)
end

local function revokeAbilityInternal(InvDefPath)
    return updateInventory(InvDefPath, false)
end

local function getInventoryPath(str)
    local obj = FindObject("BlueprintGeneratedClass", str)

    if not obj or not obj:IsValid() then
        obj = FindObject("BlueprintGeneratedClass", string.format("Inventory_%s_C", str))
    end

    if not obj or not obj:IsValid() then
        obj = StaticFindObject(str)
        if not obj or not obj:IsValid() then
            print("loading asset", str)
            obj = LoadAsset(str)
        end
    end

    if not obj or not obj:IsValid() then return nil end
    return obj:GetFullName():match("%s(.+)")
end

local function groupResults(items)
    table.sort(items)
    local res = {}
    local lastFirst = ""
    for _, name in ipairs(items) do
        local first = name:sub(1,1)
        if first ~= lastFirst and lastFirst ~= "" then
            table.insert(res, "\n")
        elseif lastFirst ~= "" then
            table.insert(res, " ")
        end
        table.insert(res, name)
        lastFirst = first
    end
    return table.concat(res)
end

local function getAllAbilities()
    local out = {}
    for _, obj in pairs(FindObjects(30000, "BlueprintGeneratedClass", "", 0, 0, false) or {}) do
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
    table.sort(out)

    local result = {}
    local lastFirst = ""
    for _, name in ipairs(out) do
        local first = name:sub(1,1)
        if first ~= lastFirst and lastFirst ~= "" then
            table.insert(result, "\n")
        elseif lastFirst ~= "" then
            table.insert(result, " ")
        end
        table.insert(result, name)
        lastFirst = first
    end

    return table.concat(result)
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

-- Centralized ability table
local AbilityTable = {
    "/Supraworld/Abilities/Walk/Inventory_Walk.Inventory_Walk_C",
    "/Supraworld/Abilities/Crouch/Inventory_Crouch.Inventory_Crouch_C",
    "/Supraworld/Abilities/Run/Inventory_Run.Inventory_Run_C",
    "/Supraworld/Abilities/Jump/Jumps/Inventory_Jump.Inventory_Jump_C",
    "/Supraworld/Abilities/Strength/Inventory_Strength.Inventory_Strength_C",
    "/Supraworld/Abilities/Jump/JumpHeight/Inventory_JumpHeightDouble.Inventory_JumpHeightDouble_C",
    "/Supraworld/Abilities/BlowGun/Core/Inventory_BlowGun.Inventory_BlowGun_C",
    "/Supraworld/Abilities/ThoughtReading/Inventory_ThoughtReading.Inventory_ThoughtReading_C",
    "/Supraworld/Abilities/Ghost/Inventory_ThirdEye.Inventory_ThirdEye_C",
    "/Supraworld/Abilities/Dash/Inventory_Dash.Inventory_Dash_C",
    "/Supraworld/Abilities/PlayerMap/Inventory_PlayerMap.Inventory_PlayerMap_C",
    "/Supraworld/Abilities/SpongeSuit/Upgrades/Inventory_SpongeSuit.Inventory_SpongeSuit_C",
    "/Supraworld/Abilities/LaserWalk/Inventory_LaserWalk.Inventory_LaserWalk_C",
    "/Supraworld/Abilities/MindVision/Inventory_MindVision.Inventory_MindVision_C",
    "/Supraworld/Abilities/Shield/Inventory_Shield.Inventory_Shield_C",
    "/Supraworld/Abilities/Toothpick/Lyra/Inventory_Toothpick.Inventory_Toothpick_C", -- not loaded at start
    "/Supraworld/Abilities/Toothpick/Upgrades/ToothpickDart/Inventory_Toothpin_Dart.Inventory_Toothpin_Dart_C",
    "/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C",  -- doesn't seem to work
    "/Supraworld/Abilities/SmellImmunity/Inventory_SmellImmunity.Inventory_SmellImmunity_C", -- not loaded at start
    -- "/Supraworld/Abilities/MindControl/Inventory_MindControl.Inventory_MindControl_C", -- unfinished, breaks saves


    -- "/Supraworld/Abilities/Toothpick/Upgrades/ToothpickWedge/Equipment_ToothpickStake.Equipment_ToothpickStake_C"
    -- "/Supraworld/Abilities/Shield/Equipment_Shield.Equipment_Shield_C",
    -- "/Supraworld/Abilities/BlowGun/Upgrades/Time/Inventory_BlowgunBlowTimeUnlimited.Inventory_BlowgunBlowTimeUnlimited_C"
}

local function grantAllAbilities()
    ExecuteInGameThread(function()
        for i, abilityPath in ipairs(AbilityTable) do
            grantAbilityInternal(abilityPath)
        end
    end)
end

local function revokeAllAbilities()
    ExecuteInGameThread(function()
        for i, abilityPath in ipairs(AbilityTable) do
            revokeAbilityInternal(abilityPath)
        end
    end)
end

-- Register keybinds
RegisterKeyBind(Key.I, {ModifierKey.ALT}, grantAllAbilities) -- Alt+I to grant all abilities
RegisterKeyBind(Key.I, {ModifierKey.ALT, ModifierKey.SHIFT}, revokeAllAbilities) -- Shift+Alt+I to revoke all abilities -- HANGS!!!

RegisterConsoleCommandHandler("grant", inventoryHandler(grantAbilityInternal, "granted", "usage: grant <inventory>, e.g. grant spongesuit", "already have"))
RegisterConsoleCommandHandler("revoke", inventoryHandler(revokeAbilityInternal, "revoked", "usage: revoke <inventory>", "not carrying"))


    --[[
        local path = fstr:get():ToString()
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
     ]]

local function FindAssetsByKeywords(keywords)
    local results = {}
    CacheAssetRegistry()

    local assets = {}
    AssetRegistry:GetAllAssets(assets, false) -- (table in, bool onDiskOnly)

    table.insert(keywords, "/Inventory_")
    table.insert(keywords, "_C")

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
            str = a_name
            str = str:gsub("Inventory_","")
            str = str:gsub("_C","")
            str = str:lower()

            table.insert(results, str)

            i = i + 1
            if i==100 then break end
        end

    end
    return results
end


RegisterConsoleCommandHandler("give", function(FullCommand, Parameters, Ar)
    local results = FindAssetsByKeywords(Parameters)
        Ar:Log(groupResults(results))
    -- for i, str in ipairs(results) do
    --     Ar:Log(str)
    -- end
    return true
end)


-- check volumes

local function overlaps(loc, box)
    return math.abs(loc.X - box.Center.X) <= box.Size.X / 2
       and math.abs(loc.Y - box.Center.Y) <= box.Size.Y / 2
       and math.abs(loc.Z - box.Center.Z) <= box.Size.Z / 2
end

local defaultSize = { X = 1000, Y = 1000, Z = 1000 } -- size in mm

local volumes = {
    {
        inside = false,
        Box = {Center={ X = 0, Y = 0, Z = 0 }, Size = defaultSize},
        onEnter = function() print("entered box1"); end,
        onLeave = function() print("left box1"); end
    },
    {
        inside = false,
        Box = {Center={ X = -1000, Y = 0, Z = 0 }, Size = defaultSize},
        onEnter = function() print("entered box2") end,
        onLeave = function() print("left box2") end
    },
}

local function checkVolumes()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then return end
    local loc = pc.Pawn:K2_GetActorLocation()
    for _, vol in ipairs(volumes) do
        local currentlyInside = overlaps(loc, vol.Box)
        if currentlyInside and not vol.inside then
            vol.inside = true
            if vol.onEnter then vol.onEnter() end
        elseif not currentlyInside and vol.inside then
            vol.inside = false
            if vol.onLeave then vol.onLeave() end
        end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    print("-- initialize checkVolumes loop --")
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            -- LoopAsync(100, checkVolumes)
        end)
    end)
end)

