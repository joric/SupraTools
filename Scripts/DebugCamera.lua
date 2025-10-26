local UEHelpers = require("UEHelpers")

-- https://github.com/UE4SS-RE/RE-UE4SS/pull/1050 may introduce a breaking change
-- so it uses getPlayerController(), getDebugCameraController() from main.lua

-- fixes ue4ss toggledebugcamera issue, see https://github.com/UE4SS-RE/RE-UE4SS/issues/514
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

--[[
-- this crashes UE4SS_v3.0.1-596-g96c34c5.zip no matter the return value
-- it's supposed to return true/false? https://docs.ue4ss.com/dev/lua-api/global-functions/notifyonnewobject.html
-- as opposed to stable version that returns object https://docs.ue4ss.com/lua-api/global-functions/notifyonnewobject.html
-- I don't really need it (I think so it can be commented out)
NotifyOnNewObject("/Script/Engine.PlayerController", function(PlayerController)
    return cheatable(PlayerController)
end)
]]

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
            -- getCameraController().CheatManager:Teleport() -- built-in teleport console command, needs line of sight
            teleportToTrace(pc.Pawn) -- teleport to impact point, may hit hidden volumes
        end)
    end)
end

RegisterKeyBind(Key.MIDDLE_MOUSE_BUTTON, toggleDebugCamera)
RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, teleportPlayer)
