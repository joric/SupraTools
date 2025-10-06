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

inDebugCamera = false -- global variable

function getCameraController()
    local pc = UEHelpers.GetPlayerController()
    if inDebugCamera then
        for _, Controller in ipairs(FindAllOf("DebugCameraController") or {}) do
            if Controller:IsValid() and (Controller.IsPlayerController and Controller:IsPlayerController() or Controller:IsLocalPlayerController()) then
                return Controller
            end
        end
    end
    return pc
end

function getCameraHitObject()
    local pc = UEHelpers.GetPlayerController()
    local cam = getCameraController().PlayerCameraManager
    return getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
end

function getCameraImpactPoint()
    local pc = UEHelpers.GetPlayerController()
    local cam = getCameraController().PlayerCameraManager
    return getImpactPoint(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
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
