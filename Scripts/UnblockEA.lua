local function unblockEA()
    for _, obj in ipairs(FindAllOf("SupraEABlockingVolume_C") or {}) do
        if obj:IsValid() then
            -- obj:SetActorEnableCollision(false) -- this is broken since 9016 (Timer_StopScriptsTurningOffCollision)
            obj:K2_DestroyActor() -- this works
        end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    unblockEA()
end)

-- Looks like the issue that teleports player to 0,0,0 is unrelated to scripting but ue4ss in general
-- I disabled all the scripts (including this one) and it still happens.

-- this works
RegisterHook("/Script/Engine.Actor:K2_SetActorLocation", function(self, NewLocation, bSweep, SweepHitResult, bTeleport)
    local vec = NewLocation:get()
    -- print("Actor:", self:get():GetFullName(), "X:", vec.X, "Y:", vec.Y, "Z:", vec.Z)
    if math.abs(vec.X) < 10 and math.abs(vec.Y) < 10 and math.abs(vec.Z) < 10 then
        -- block teleport to zero
        -- print("BLOCKED TELEPORT TO 0,0,0!!!")
        return false
    end
end)
