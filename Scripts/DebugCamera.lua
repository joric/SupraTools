local UEHelpers = require("UEHelpers")

-- https://github.com/UE4SS-RE/RE-UE4SS/pull/1050 may introduce a breaking change
-- so it uses getPlayerController(), getDebugCameraController() from main.lua

local function cheatable(PlayerController)
    if not PlayerController.CheatManager:IsValid() then
        print("Restoring CheatManager")
        local CheatManagerClass = StaticFindObject("/Script/Engine.CheatManager")
        if CheatManagerClass:IsValid() then
            PlayerController.CheatManager = StaticConstructObject(CheatManagerClass, PlayerController)
        end
    end
    return PlayerController
end

-- this hook fixes the toggledebugcamera issue, see https://github.com/UE4SS-RE/RE-UE4SS/issues/514
-- crashes UE4SS_v3.0.1-596-g96c34c5.zip no matter the return value (object/true/false/nil/empty body)
-- stable version returned object https://docs.ue4ss.com/lua-api/global-functions/notifyonnewobject.html
-- dev version returns true/false https://docs.ue4ss.com/dev/lua-api/global-functions/notifyonnewobject.html
-- Fixed in 599, see https://github.com/UE4SS-RE/RE-UE4SS/pull/1065

NotifyOnNewObject("/Script/Engine.PlayerController", function(PlayerController)
    cheatable(PlayerController)
    return false
end)

local function toggleDebugCamera()
    if not inDebugCamera then
        pcall(function() cheatable(getPlayerController()).CheatManager:EnableDebugCamera() end)
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
    if not PlayerPawn or not PlayerPawn:IsValid() then
        print("INVALID PAWN, CAN'T TELEPORT!!!")
        return
    end
    --PlayerPawn:K2_SetActorLocation(loc, false, {}, true)
    PlayerPawn:K2_TeleportTo(loc, { Pitch = 0, Yaw = rot.Yaw, Roll = 0 }) -- also updates physics
end

local lastTime = 0

local function teleportPlayer()
    if not inDebugCamera then return end

    local pc = getPlayerController()
    local cc = getDebugCameraController()
    local cam = cc.PlayerCameraManager

    cc:ClientFlushLevelStreaming()
    cc:ClientForceGarbageCollection()

    pc:ClientFlushLevelStreaming()
    pc:ClientForceGarbageCollection()

    local throttleMs = 300
    ExecuteWithDelay(throttleMs, function()
        ExecuteInGameThread(function()
            if (os.clock() - (lastTime or 0)) * 1000 < throttleMs then return end
            lastTime = os.clock()
            -- pc.Pawn:K2_TeleportTo(cam:GetCameraLocation(), cam:GetCameraRotation()) -- teleport to debug camera position
            -- getCameraController().CheatManager:Teleport() -- built-in teleport console command, but it needs line of sight / navmesh
            teleportToTrace(pc.Pawn) -- teleport to impact point, may hit hidden volumes
        end)
    end)
end

RegisterKeyBind(Key.MIDDLE_MOUSE_BUTTON, toggleDebugCamera)
RegisterKeyBind(Key.C, {ModifierKey.ALT}, toggleDebugCamera) -- since 9016 introduces "binoculars" on middle click
RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, teleportPlayer)
