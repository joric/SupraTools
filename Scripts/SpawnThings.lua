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

    local deferredActor = UEHelpers.GetGameplayStatics():BeginDeferredActorSpawnFromClass(world, actorClass, transform, 0, nil, 0)
    if deferredActor:IsValid() then
        return UEHelpers.GetGameplayStatics():FinishSpawningActor(deferredActor, transform, 0)
    else
        print("Deferred Actor failed", ActorClassName)
    end
    return invalidActor
end

-- Alternative function to spawn from an existing object's class
function SpawnActorFromObjectClass(Object, Location, Rotation)
    local invalidActor = CreateInvalidObject() ---@cast invalidActor AActor
    if not Object or not Object:IsValid() then return invalidActor end
    
    local actorClass = Object:GetClass()
    if not actorClass:IsValid() then
        print("SpawnActorFromObjectClass: Object has invalid class")
        return invalidActor
    end
    
    local world = UEHelpers.GetWorld()
    if not world:IsValid() then return invalidActor end

    local Scale = {X=1, Y=1, Z=1}
    local transform = UEHelpers.GetKismetMathLibrary():MakeTransform(Location, Rotation, Scale)

    local deferredActor = UEHelpers.GetGameplayStatics():BeginDeferredActorSpawnFromClass(world, actorClass, transform, 0, nil, 0)
    if deferredActor:IsValid() then
        return UEHelpers.GetGameplayStatics():FinishSpawningActor(deferredActor, transform, 0)
    else
        print("Deferred Actor failed for object class")
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
    -- UEHelpers.GetPlayerController().CheatManager['summon']('Bush_C')
    -- UEHelpers.GetPlayerController().CheatManager.Summon('Bush_C')
end

local function spawnFromObjectClass(obj)
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            local loc = getTargetLocation()
            local rot = {Pitch=0, Yaw=0, Roll=0}
            SpawnActorFromObjectClass(obj, loc, rot)
        end)
    end)
end

local selectedObject = nil
local hiddenObject = nil

local function copyObject()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end

    local cam = pc.PlayerCameraManager
    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
    if not hitObject or not hitObject:IsValid() then return end

    selectedObject = hitObject:GetOuter()
    print("Copied object: " .. selectedObject:GetFullName() .. " of class: " .. selectedObject:GetClass():GetFullName())
    return selectedObject
end

local function pasteObject()
    if not selectedObject then 
        print("No object copied to paste")
        return 
    end
    
    print("Pasting object of class: " .. selectedObject:GetClass():GetFullName())
    spawnFromObjectClass(selectedObject)
end

local function cutObject()
    hiddenObject = copyObject()
    if hiddenObject and hiddenObject:IsValid() then
        hiddenObject:SetActorEnableCollision(false)
        hiddenObject:SetActorHiddenInGame(true)
    end
end

local function undo()
    if hiddenObject and hiddenObject:IsValid() then
        hiddenObject:SetActorHiddenInGame(false)
        hiddenObject:SetActorEnableCollision(true)
    end
end

RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, {ModifierKey.CONTROL}, spawnThings)
RegisterKeyBind(Key.C, {ModifierKey.CONTROL}, copyObject)
RegisterKeyBind(Key.V, {ModifierKey.CONTROL}, pasteObject)
RegisterKeyBind(Key.X, {ModifierKey.CONTROL}, cutObject)
RegisterKeyBind(Key.Z, {ModifierKey.CONTROL}, undo)
