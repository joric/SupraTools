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

local function toggleDebugCamera()
    if not inDebugCamera then
        cheatable(UEHelpers.GetPlayerController()).CheatManager:EnableDebugCamera()
        inDebugCamera = true
    else
        cheatable(getDebugCameraController()).CheatManager:DisableDebugCamera()
        inDebugCamera = false
    end
end

local function teleportToTrace(PlayerPawn)
    local cam = getCameraController().PlayerCameraManager
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

    cc:ClientFlushLevelStreaming()
    cc:ClientForceGarbageCollection()

    pc:ClientFlushLevelStreaming()
    pc:ClientForceGarbageCollection()

    local throttleMs = 300
    ExecuteWithDelay(throttleMs, function()
        ExecuteInGameThread(function()
            ExecuteInGameThread(function()
                if (os.clock() - (lastTime or 0)) * 1000 < throttleMs then return end
                lastTime = os.clock()
                -- pc.Pawn:K2_TeleportTo(cam:GetCameraLocation(), cam:GetCameraRotation()) -- teleport to debug camera position
                -- getCameraController().CheatManager:Teleport() -- built-in teleport console command, needs line of sight
                teleportToTrace(pc.Pawn) -- teleport to impact point, may hit hidden volumes
            end)
        end)
    end)
end

RegisterKeyBind(Key.MIDDLE_MOUSE_BUTTON, toggleDebugCamera)
RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, teleportPlayer)
