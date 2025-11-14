local function unblockEA()
    for _, obj in ipairs(FindAllOf("SupraEABlockingVolume_C") or {}) do
        if obj:IsValid() then
            -- obj:SetActorEnableCollision(false) -- this is broken since 9016 (Timer_StopScriptsTurningOffCollision)
            obj:K2_DestroyActor() -- this works

            -- Looks like the issue that teleports player to 0,0,0 is unrelated to this script, probably ue4ss in general
            -- I disabled all the scripts (including this one) and it still happens. Will investigate.
        end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    unblockEA()
end)
