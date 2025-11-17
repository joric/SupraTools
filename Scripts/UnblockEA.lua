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

-- Looks like the issue that teleports player to 0,0,0 is unrelated to scripting but ue4ss in general

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    cacheEA()
    unblockEA()

    --[[
    RegisterHook("/Script/Engine.Actor:K2_SetActorLocation", function(self, NewLocation, bSweep, SweepHitResult, bTeleport)
        local vec = NewLocation:get()
        local actor = self:get()
        -- print("Actor:", actor:GetFullName(), "X:", vec.X, "Y:", vec.Y, "Z:", vec.Z)
        local d = 100
        if math.abs(vec.X) < d and math.abs(vec.Y) < d and math.abs(vec.Z) < d then
            -- block teleport to zero

            local loc = actor:K2_GetActorLocation()

            print(string.format("TELEPORTING TO %.5f %.5f %.5f (was %.5f %.5f %.5f, %s)", vec.X, vec.Y, vec.Z, loc.X, loc.Y, loc.Z, actor:GetFName():ToString()))

            -- do something here

            --NewLocation:set({X=loc.X,Y=loc.Y, Z=loc.Z}) -- crashes here
            bSweep:set(true) -- this doesn't crash but doesn't work either

            ExecuteWithDelay(300, function()
                --actor:K2_SetActorLocation(loc, false, {}, true)
                local rot = actor:K2_GetActorRotation()
                ExecuteInGameThread(function()
                    --actor:K2_TeleportTo(loc, rot)
                end)
            end)

            -- return false -- this doesn't seem to cancel the teleport at all 
        end
    end)
    ]]

    RegisterHook("/Script/Engine.Actor:K2_SetActorLocationAndRotation", function(self, NewLocation, NewRotation)
        local vec = NewLocation:get()
        local actor = self:get()
        local d = 10
        if math.abs(vec.X) < d and math.abs(vec.Y) < d and math.abs(vec.Z) < d then
            local loc = actor:K2_GetActorLocation()
            print(string.format("--- K2_SetActorAndRotation %.5f %.5f %.5f (was %.5f %.5f %.5f, %s)", vec.X, vec.Y, vec.Z, loc.X, loc.Y, loc.Z, actor:GetFName():ToString()))
            if actor:GetFullName():find('Player_ToyCharacter_C') then
                print("----- GOT PLAYER, TRYING TO RESET COORDS -----")
                NewLocation:Set(loc)
            end
        end
    end)

    RegisterHook("/Script/Engine.Actor:K2_SetActorLocation", function(self, NewLocation, bSweep, SweepHitResult, bTeleport)
        local vec = NewLocation:get()
        local actor = self:get()
        local d = 10
        if math.abs(vec.X) < d and math.abs(vec.Y) < d and math.abs(vec.Z) < d then
            local loc = actor:K2_GetActorLocation()
            print(string.format("--- K2_SetActorLocation %.5f %.5f %.5f (was %.5f %.5f %.5f, %s)", vec.X, vec.Y, vec.Z, loc.X, loc.Y, loc.Z, actor:GetFName():ToString()))
            if actor:GetFullName():find('Player_ToyCharacter_C') then
                print("----- GOT PLAYER, TRYING TO RESET COORDS -----")
                NewLocation:Set(loc)
            end
        end
    end)

end)


LoopAsync(1000, unblockEA)
-- ExecuteWithDelay(500, unblockEA)

