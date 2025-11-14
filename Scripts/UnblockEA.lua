local function unblockEA()
    for _, obj in ipairs(FindAllOf("SupraEABlockingVolume_C") or {}) do
        if obj:IsValid() then
            -- obj:SetActorEnableCollision(false) -- this teleports player to 0,0,0 since 9016 (Timer_StopScriptsTurningOffCollision)
            obj:K2_DestroyActor() -- this works
        end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    unblockEA()
end)
