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

local function spawnThings()
    -- spawnClass('/Supraworld/Levelobjects/Carriables/AluminumBall.AluminumBall_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/FourLeafClover.FourLeafClover_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Hats/JesterHat.JesterHat_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Die.Die_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/ButtonBattery.ButtonBattery_C')
    spawnClass('/Supraworld/Abilities/SpongeSuit/ShopItem_SpongeSuit.ShopItem_SpongeSuit_C')

    -- you can also use cheats, e.g. "summon Bush_C" in game console (uses LoadAsset internally)
    -- UEHelpers.GetPlayerController().CheatManager.Summon('Bush_C')
end


RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, {ModifierKey.CONTROL}, spawnThings)

