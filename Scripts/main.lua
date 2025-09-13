local UEHelpers = require("UEHelpers")

function getImpactPoint(WorldObject, StartVector, Rotation)
    local AddValue = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(Rotation), 60000.0)
    local EndVector = UEHelpers.GetKismetMathLibrary():Add_VectorVector(StartVector, AddValue)
    local Color, HitResult = {R=0, G=0, B=0, A=0}, {}
    local WasHit = UEHelpers.GetKismetSystemLibrary():LineTraceSingle(WorldObject, StartVector, EndVector, 0, false, {}, 0, HitResult, true, Color, Color, 0.0)
    if WasHit then return HitResult.ImpactPoint end
    return {X=0, Y=0, Z=0}
end

function getHitObject(WorldObject, StartVector, Rotation)
    local AddValue = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(Rotation), 60000.0)
    local EndVector = UEHelpers.GetKismetMathLibrary():Add_VectorVector(StartVector, AddValue)
    local Color, HitResult = {R=0, G=0, B=0, A=0}, {}
    local WasHit = UEHelpers.GetKismetSystemLibrary():LineTraceSingle(WorldObject, StartVector, EndVector, 0, false, {}, 0, HitResult, true, Color, Color, 0.0)
    if WasHit then
        if UnrealVersion:IsBelow(5, 0) then
            return HitResult.Actor:Get()
        elseif UnrealVersion:IsBelow(5, 4) then
            return HitResult.HitObjectHandle.Actor:Get()
        else
            return HitResult.HitObjectHandle.ReferenceObject:Get()
        end
    end
    return nil
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
