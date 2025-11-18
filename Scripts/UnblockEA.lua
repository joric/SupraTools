-- Disclaimer: teleporting to 0,0,0 is not related to unblocking EA volumes
-- Since 9016 the in-game "protection" triggers on vanilla UE4SS with no scripts whatsoever
-- I am just trying to mitigate this anti-UE4SS "protection"

local UEHelpers = require("UEHelpers")
local ksl = UEHelpers.GetKismetSystemLibrary()
local cachedEABlockers = {}

local function cacheEA()
    cachedEABlockers = {}
    for _, obj in ipairs(FindAllOf("SupraEABlockingVolume_C") or {}) do
        if obj:IsValid() then
            table.insert(cachedEABlockers, obj)
        end
    end
end

local function unblockEA()
    for _, obj in ipairs(cachedEABlockers) do
        if obj:IsValid() then
            obj:SetActorEnableCollision(false)
            -- obj:K2_DestroyActor() -- this works

            local handle = obj.Timer_StopScriptsTurningOffCollision
            if handle:IsValid() then
                ksl:K2_ClearTimerHandle(obj, {Handle = handle.Handle})
            end
        end
    end
end

local loc = {X=0,Y=0,Z=0}

local function isZero(vec)
    local d = 500
    return math.abs(vec.X) < d and math.abs(vec.Y) < d and math.abs(vec.Z) < d
end

local function checkPlayer()
    local pc = getPlayerController()
    local actor = pc.Pawn
    if not actor:IsValid() then return end

    local vec = actor:K2_GetActorLocation()

    if isZero(vec) then

        if not isZero(loc) then
            print(string.format("-- teleporting player to %.5f %.5f %.5f", loc.X, loc.Y, loc.Z))
            ExecuteWithDelay(250, function()
                ExecuteInGameThread(function()
                    -- actor:K2_TeleportTo(loc, rot)
                    actor:K2_SetActorLocation(loc, false, {}, true) -- safer maybe?
                end)
            end)
        end

    else
        loc = vec
        -- print(string.format("-- updated player, %.5f %.5f %.5f", vec.X, vec.Y, vec.Z))
    end

end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    cacheEA()
    unblockEA()
    LoopAsync(1000, checkPlayer)
end)

-- LoopAsync(1000, unblockEA) -- not needed if you K2_ClearTimerHandle on Timer_StopScriptsTurningOffCollision
