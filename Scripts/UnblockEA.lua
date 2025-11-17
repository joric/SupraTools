-- Disclaimer: teleporting to 0,0,0 is not related to unblocking EA volumes
-- There's a global sentinel since 9016 that reacts to clear ue4ss with no scripts whatsoever
-- I am just trying to mitigate this anti-ue4ss "protection"

local UEHelpers = require("UEHelpers")
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
                UEHelpers.GetKismetSystemLibrary():K2_ClearTimerHandle(obj, {Handle = handle.Handle})
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

    local pc = UEHelpers.GetPlayerController()
    local actor = pc.Pawn
    if not actor:IsValid() then return end

    local vec = actor:K2_GetActorLocation()
    local rot = actor:K2_GetActorRotation()

    if isZero(vec) then

        if not isZero(loc) then
            print(string.format("-- teleporting player to %.5f %.5f %.5f", loc.X, loc.Y, loc.Z))
            ExecuteWithDelay(250, function()
                ExecuteInGameThread(function()
                    actor:K2_TeleportTo(loc, rot)
                end)
            end)
        end

    else
        loc = vec
        -- print(string.format("-- updated player, %.5f %.5f %.5f", vec.X, vec.Y, vec.Z))
    end

end

-- Looks like the issue that teleports player to 0,0,0 is unrelated to scripting but ue4ss in general

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    cacheEA()
    unblockEA()
--[[
    RegisterHook("/Script/Engine.Actor:K2_TeleportTo", function(self, NewLocation, NewRotation)
        local vec = NewLocation:get()
        print(string.format("-- hooked K2_TeleportTo %.5f %.5f %.5f %s", vec.X, vec.Y, vec.Z, self:get():GetFullName() ))
    end)

    RegisterHook("/Script/Engine.Actor:K2_SetActorLocationAndRotation", function(self, NewLocation, NewRotation)
        local vec = NewLocation:get()
        print(string.format("-- hooked K2_TeleportTo %.5f %.5f %.5f %s", vec.X, vec.Y, vec.Z, self:get():GetFullName() ))
    end)

    local loc,rot = {}, {}
    local teleport = false

    RegisterHook("/Script/Engine.Actor:K2_SetActorLocation", function(self, NewLocation, bSweep, SweepHitResult, bTeleport)
        local vec = NewLocation:get()
        local actor = self:get()
        teleport = false
        local d = 10
        if math.abs(vec.X) < d and math.abs(vec.Y) < d and math.abs(vec.Z) < d then
            loc = actor:K2_GetActorLocation()
            rot = actor:K2_GetActorRotation()
            if actor:GetFullName():find('Player_ToyCharacter_C') then
                print(string.format("--- K2_SetActorLocation %.5f %.5f %.5f (was %.5f %.5f %.5f, %s)", vec.X, vec.Y, vec.Z, loc.X, loc.Y, loc.Z, actor:GetFName():ToString()))
                NewLocation:Set(loc) -- this doesn't work for some reason
                teleport = true
            end
        end
    end,
        function(self, NewLocation, bSweep, SweepHitResult, bTeleport)
            if teleport then
                print(string.format("-- teleporting back to %.5f %.5f %.5f --", loc.X, loc.Y, loc.Z))
                self:get():K2_TeleportTo(loc, rot)
            end
        end
    )
]]

    LoopAsync(1000, checkPlayer)

end)

-- LoopAsync(1000, unblockEA) -- not needed if you K2_ClearTimerHandle on Timer_StopScriptsTurningOffCollision
-- ExecuteWithDelay(500, unblockEA)

