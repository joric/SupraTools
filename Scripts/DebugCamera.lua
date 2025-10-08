local UEHelpers = require("UEHelpers")

-- fixes ue4ss toggledebugcamera issue, see https://github.com/UE4SS-RE/RE-UE4SS/issues/514
local function cheatable(PlayerController)
    if not PlayerController.CheatManager:IsValid() then
        print("Restoring CheatManager")
        local CheatManagerClass = StaticFindObject("/Script/Engine.CheatManager")
        if CheatManagerClass:IsValid() then
            PlayerController.CheatManager = StaticConstructObject(CheatManagerClass, PlayerController)
        end

        if not PlayerController.CheatManager:IsValid() then
            print("re-creating cheat manager")
            PlayerController.CheatManager = LoadAsset("/Script/Engine.CheatManager")
        end

    end
    return PlayerController
end

NotifyOnNewObject("/Script/Engine.PlayerController", function(PlayerController)
    return cheatable(PlayerController)
end)

local function toggleDebugCamera()
    if not inDebugCamera then
        pcall(function() cheatable(UEHelpers.GetPlayerController()).CheatManager:EnableDebugCamera() end)
        inDebugCamera = true
    else
        pcall(function() cheatable(getDebugCameraController()).CheatManager:DisableDebugCamera() end)
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
