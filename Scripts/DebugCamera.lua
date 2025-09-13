local UEHelpers = require("UEHelpers")

-- fixes ue4ss toggledebugcamera issue, see https://github.com/UE4SS-RE/RE-UE4SS/issues/514
local function cheatable(PlayerController)
    if not PlayerController.CheatManager:IsValid() then
        print("Restoring CheatManager")
        local CheatManagerClass = StaticFindObject("/Script/Engine.CheatManager")
        if CheatManagerClass:IsValid() then
            local CreatedCheatManager = StaticConstructObject(CheatManagerClass, PlayerController)
            if CreatedCheatManager:IsValid() then
                PlayerController.CheatManager = CreatedCheatManager
            end
        end
    end
    return PlayerController
end

NotifyOnNewObject("/Script/Engine.PlayerController", function(PlayerController)
    return cheatable(PlayerController)
end)

local function getDebugCameraController()
    return FindFirstOf("DebugCameraController") or UEHelpers.GetPlayerController()
end

local function toggleDebugCamera()
    if not inDebugCamera then
        inDebugCamera = true
        cheatable(UEHelpers.GetPlayerController()).CheatManager:EnableDebugCamera()
    else
        inDebugCamera = false
        cheatable(getDebugCameraController()).CheatManager:DisableDebugCamera()
    end
end

local function teleportToTrace(PlayerPawn)
    local cam = getDebugCameraController().PlayerCameraManager
    local rot = cam:GetCameraRotation()
    local loc = getImpactPoint(PlayerPawn, cam:GetCameraLocation(), rot)
    loc.Z = loc.Z + 100 -- above the ground
    -- PlayerPawn:K2_SetActorLocation(loc, false, {}, true)
    PlayerPawn:K2_TeleportTo(loc, rot) -- also updates physics
end

local function teleportPlayer()
    if not inDebugCamera then return end

    local pc = UEHelpers.GetPlayerController()
    local cc = getDebugCameraController()
    local cam = cc.PlayerCameraManager

    pc:ClientFlushLevelStreaming()
    pc:ClientForceGarbageCollection()

    cc:ClientFlushLevelStreaming()
    cc:ClientForceGarbageCollection()

    local throttleMs = 300
    ExecuteWithDelay(throttleMs, function()
        ExecuteInGameThread(function()
        ExecuteInGameThread(function()
            if (os.clock() - (lastTime or 0)) * 1000 < throttleMs then return end
            lastTime = os.clock()
            -- pc.Pawn:K2_TeleportTo(cam:GetCameraLocation(), cam:GetCameraRotation()) -- teleport to debug camera position
            -- getDebugCameraController().CheatManager:Teleport() -- built-in teleport console command, needs line of sight
            teleportToTrace(pc.Pawn) -- teleport to impact point, may hit hidden volumes
        end)
        end)
    end)
end

RegisterKeyBind(Key.MIDDLE_MOUSE_BUTTON, toggleDebugCamera)
RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, teleportPlayer)
