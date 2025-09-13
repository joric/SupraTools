local UEHelpers = require("UEHelpers")

local function getFloorHeight(PlayerPawn, worldX, worldY, maxHeight)
    local StartVector = {X = worldX, Y = worldY, Z = maxHeight}
    local Rotation = { Pitch = -90, Yaw = 0, Roll = 0 }
    return getImpactPoint(PlayerPawn, StartVector, Rotation).Z
end

local function fastTravel()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end

    pc:ClientFlushLevelStreaming()
    pc:ClientForceGarbageCollection()

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()

            local widget = FindFirstOf("SW_PlayerMapWidget_C")
            if not widget:IsValid() then
                widget = FindFirstOf("PlayerMapWidget_C")
                if not widget:IsValid() then return end
            end

            local mapActor = FindFirstOf("PlayerMapActor_C")
            if not mapActor:IsValid() then return end

            local virtualMap = {}
            local mapLocation = {}
            local ok = widget:GetMousePositionOnVirtualMap(virtualMap, mapLocation)
            if not ok or (virtualMap.X==0 and virtualMap.Y==0) then return end

            local worldX = (mapLocation.X - 0.5) * mapActor.MapWorldSize + mapActor.MapWorldCenter.X
            local worldY = (mapLocation.Y - 0.5) * mapActor.MapWorldSize + mapActor.MapWorldCenter.Y

            local maxHeight = mapActor.CaptureHeight - mapActor.MapWorldCenter.Z + mapActor.MapWorldUpperLeft.Z

            local floorHeight = getFloorHeight(pc.Pawn, worldX, worldY, maxHeight)
            local loc = {X = worldX, Y = worldY, Z = floorHeight + 100}

            pc.Pawn:K2_TeleportTo(loc, pc.Pawn:K2_GetActorRotation())

            local comp = FindFirstOf("PlayerMapComponent_C")
            if comp:IsValid() then
                comp:UpdatePlayerLocationAndFog()
            end

        end)
    end)
end

RegisterKeyBind(Key.F, fastTravel)
