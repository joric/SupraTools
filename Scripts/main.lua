local UEHelpers = require("UEHelpers")

local function getHitResult(WorldObject, StartVector, Rotation)
    local AddValue = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(Rotation), 90000.0)
    local EndVector = UEHelpers.GetKismetMathLibrary():Add_VectorVector(StartVector, AddValue)
    local Color, HitResult = {R=0, G=0, B=0, A=0}, {}
    local WasHit = UEHelpers.GetKismetSystemLibrary():LineTraceSingle(WorldObject, StartVector, EndVector, 0, false, {}, 0, HitResult, true, Color, Color, 0.0)
    if WasHit then return HitResult end
    return nil
end

function getImpactPoint(WorldObject, StartVector, Rotation)
    return (getHitResult(WorldObject, StartVector, Rotation) or { ImpactPoint = StartVector }).ImpactPoint
end

function getHitObject(WorldObject, StartVector, Rotation)
    return UEHelpers.GetActorFromHitResult(getHitResult(WorldObject, StartVector, Rotation))
end

require("UnblockEA")
require("DebugCamera")
require("SuitRefill")
require("FastTravel")
require("SpawnThings")
require("RemoteControl")
require("SkipCutscenes")
require("AutoCollect")
require("GameStats")
require("GrabObject")
require("GrantAbilities")
require("FindAsset")
require("GameSettings")
