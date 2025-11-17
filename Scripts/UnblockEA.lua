local function unblockEA()
    for _, obj in ipairs(FindAllOf("SupraEABlockingVolume_C") or {}) do
        if obj:IsValid() then
            -- obj:SetActorEnableCollision(false) -- this is broken since 9016 (Timer_StopScriptsTurningOffCollision)
            obj:K2_DestroyActor() -- this works
        end
    end
end

-- Looks like the issue that teleports player to 0,0,0 is unrelated to scripting but ue4ss in general

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    unblockEA()

    RegisterHook("/Script/Engine.Actor:K2_SetActorLocation", function(self, NewLocation, bSweep, SweepHitResult, bTeleport)
        local vec = NewLocation:get()
        -- print("Actor:", self:get():GetFullName(), "X:", vec.X, "Y:", vec.Y, "Z:", vec.Z)
        local d = 100
        if math.abs(vec.X) < d and math.abs(vec.Y) < d and math.abs(vec.Z) < d then
            -- block teleport to zero
            print(string.format("TELEPORTING TO %.5f %.5f %.5f (%s)", vec.X, vec.Y, vec.Z, self:get():GetFName():ToString()))
            return false -- this doesn't seem to work
        end
    end)

end)



