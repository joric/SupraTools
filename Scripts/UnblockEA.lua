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

-- LoopAsync(1000, unblockEA) -- if removing timer doesn't work just call in a loop (no need really)

-- Looks like the issue that teleports player to 0,0,0 is unrelated to scripting but ue4ss in general

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    cacheEA()
    unblockEA()

    RegisterHook("/Script/Engine.Actor:K2_SetActorLocation", function(self, NewLocation, bSweep, SweepHitResult, bTeleport)
        local vec = NewLocation:get()
        local actor = self:get()
        local d = 10
        if math.abs(vec.X) < d and math.abs(vec.Y) < d and math.abs(vec.Z) < d then
            local loc = actor:K2_GetActorLocation()

            if actor:GetFullName():find('Player_ToyCharacter_C') then

                print(string.format("--- K2_SetActorLocation %.5f %.5f %.5f (was %.5f %.5f %.5f, %s)", vec.X, vec.Y, vec.Z, loc.X, loc.Y, loc.Z, actor:GetFName():ToString()))

                print("----- GOT PLAYER, TRYING TO RESET COORDS -----")

                NewLocation:Set(loc) -- this doesn't work for some reason

                -- maybe try teleporting back
                local x = loc.X
                local y = loc.Y
                local z = loc.Z
                local rot = actor:K2_GetActorRotation()
                ExecuteWithDelay(500, function()
                    ExecuteInGameThread(function()
                        print("-------- teleporting back ---------")
                        actor:K2_TeleportTo({X=x,Y=y,Z=z}, rot)
                    end)
                end)
            end
        end
    end)

end)

-- LoopAsync(1000, unblockEA)
-- ExecuteWithDelay(500, unblockEA)

