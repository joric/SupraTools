local UEHelpers = require("UEHelpers")

function getTargetLocation()
    local pc = UEHelpers.GetPlayerController()
    local cam = pc.PlayerCameraManager
    return getImpactPoint(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
end

function SpawnActorFromClass(ActorClassName, Location, Rotation)
    local invalidActor = CreateInvalidObject() ---@cast invalidActor AActor
    if type(ActorClassName) ~= "string" or not Location then return invalidActor end

    LoadAsset(ActorClassName)

    local world = UEHelpers.GetWorld()
    if not world:IsValid() then return invalidActor end

    local actorClass = StaticFindObject(ActorClassName)
    if not actorClass:IsValid() then
        print("SpawnActorFromClass: Couldn't find static object:", ActorClassName)
        return invalidActor
    end

    local Scale = {X=1, Y=1, Z=1}
    local transform = UEHelpers.GetKismetMathLibrary():MakeTransform(Location, Rotation, Scale)

    local deferredActor  = UEHelpers.GetGameplayStatics():BeginDeferredActorSpawnFromClass(world, actorClass, transform, 0, nil, 0)
    if deferredActor:IsValid() then
        return UEHelpers.GetGameplayStatics():FinishSpawningActor(deferredActor, transform, 0)
    else
        print("Deferred Actor failed", ActorClassName)
    end
    return invalidActor
end

local function spawnClass(className)
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            local loc = getTargetLocation()
            local rot = {Pitch=0, Yaw=0, Roll=0}
            SpawnActorFromClass(className, loc, rot)
        end)
    end)
end

local function dumpObjects()
    for _,obj in pairs(FindAllOf("Object")) do
        local name = obj:GetFullName()
        if name:find("Carriables") and name:find("Battery_C") then
            print(name)
        end
    end
end

local function grantAbility(InvDefPath)
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            -- Load the inventory definition
            LoadAsset(InvDefPath)
            local InvDef = StaticFindObject(InvDefPath)
            if InvDef == nil or not InvDef:IsValid() then
                print("Couldn't load inventory def:", InvDefPath)
                return
            end
            print("Loaded inventory def: ", InvDefPath)

            -- Get local player controller and pawn
            local PC = UEHelpers.GetPlayerController()
            if PC == nil or PC.Pawn == nil then
                print("No player pawn found")
                return
            end
            local Pawn = PC.Pawn

            -- Get the pawn's inventory manager using K2_GetComponentsByClass
            local InvMgrClass = StaticFindObject("/Script/LyraGame.LyraInventoryManagerComponent")
            local Comps = PC:K2_GetComponentsByClass(InvMgrClass)
            if Comps == nil or #Comps == 0 then
                print("Pawn has no inventory manager")
                return
            end
            local InvMgr = Comps[1]

            --[[
            if not InvMgr:CanAddItemDefinition(InvDef, 1) then
                print("Cannot add item: CanAddItemDefinition returned false")
                return
            end

            -- Add the inventory item
            local ItemInstance = InvMgr:AddItemDefinition(InvDef, 1)
            if ItemInstance ~= nil then
                print("Granted inventory item -> abilities and UI updated")
            else
                print("AddItemDefinition failed")
                return
            end
            ]]

            -- Dump the pawn's inventory
            local Items = InvMgr:GetAllItems()
            if Items == nil or #Items == 0 then
                print("Inventory is empty")
                return
            end

            print("Inventory dump:")
            for i, Item in ipairs(Items) do
                if Item ~= nil and Item:IsValid() then
                    print(i .. ": " .. Item:GetFullName())
                else
                    print(i .. ": invalid item")
                end
            end
        end)
    end)
end


local function spawnThings()
    -- dumpObjects()
    -- spawnClass('/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C') -- cant' really spawn abilities, need spawner
    -- spawnClass('/Supraworld/Levelobjects/Carriables/AluminumBall.AluminumBall_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/FourLeafClover.FourLeafClover_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Hats/JesterHat.JesterHat_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Die.Die_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/ButtonBattery.ButtonBattery_C')
    spawnClass('/Supraworld/Abilities/SpongeSuit/ShopItem_SpongeSuit.ShopItem_SpongeSuit_C')

    -- grantAbility('/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C')
    --grantAbility('/Supraworld/Abilities/SpongeSuit/Upgrades/Inventory_SpongeSuit.Inventory_SpongeSuit_C')
end

-- you can also use "summon" in console, e.g. "summon Bush_C"

RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, {ModifierKey.CONTROL}, spawnThings)

