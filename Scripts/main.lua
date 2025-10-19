local UEHelpers = require("UEHelpers")

supraToolsVersion = "1.0.3"
supraToolsAttribution = string.format("SupraTools version %s", supraToolsVersion)

local function getHitResult(WorldObject, StartVector, Rotation)
    local AddValue = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(Rotation), 90000.0)
    local EndVector = UEHelpers.GetKismetMathLibrary():Add_VectorVector(StartVector, AddValue)
    local Color, HitResult = {R=0, G=0, B=0, A=0}, {}
    --[[
    ECollisionChannel
    ECC_WorldStatic = 0,
    ECC_WorldDynamic = 1,
    ECC_Pawn = 2,
    ECC_Visibility = 3,
    ECC_Camera = 4,
    ECC_PhysicsBody = 5,
    ECC_Vehicle = 6,
    ECC_Destructible = 7,
    ]]
    local TraceChannel = 1
    local WasHit = UEHelpers.GetKismetSystemLibrary():LineTraceSingle(WorldObject, StartVector, EndVector, TraceChannel, false, {}, 0, HitResult, true, Color, Color, 0.0)
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

function getDebugCameraController()
    for _, Controller in ipairs(FindAllOf("DebugCameraController") or {}) do
        if Controller:IsValid() and (Controller.IsPlayerController and Controller:IsPlayerController() or Controller:IsLocalPlayerController()) then
            return Controller
        end
    end
    return UEHelpers.GetPlayerController()
end

function getCameraController()
    if inDebugCamera then
        return getDebugCameraController()
    end
    return UEHelpers.GetPlayerController()
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

local old_print = print

function print(...)
  local info = debug.getinfo(2, "S")      -- caller info
  local src = info and info.short_src or "?"
  local name = src:match("([^/\\]+)%.lua$") or src
  local args = {}
  for i = 1, select("#", ...) do
    args[#args+1] = tostring(select(i, ...))
  end
  old_print(("[%s] %s"):format(name, table.concat(args, " ")))
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
require("DeployItems")
require("PlayerProperties")
require("Minimap")
require("Give")
