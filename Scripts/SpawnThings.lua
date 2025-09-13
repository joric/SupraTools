-- https://github.com/joric/supraworld/wiki/Modding

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

local function spawnThings()
    -- dumpObjects()
    -- spawnClass('/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C') -- cant' really spawn abilities, need spawner
    -- spawnClass('/Supraworld/Levelobjects/Carriables/AluminumBall.AluminumBall_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/FourLeafClover.FourLeafClover_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Hats/JesterHat.JesterHat_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Die.Die_C')
    spawnClass('/Supraworld/Levelobjects/Carriables/ButtonBattery.ButtonBattery_C')
end

-- you can also use "summon" in console, e.g. "summon Bush_C"

RegisterKeyBind(Key.G, spawnThings)

