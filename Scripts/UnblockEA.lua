local function unblockEA()
    for _, obj in ipairs(FindAllOf("SupraEABlockingVolume_C") or {}) do
        if obj:IsValid() then
            -- obj:SetActorEnableCollision(false) -- this teleports player to 0,0,0 since 9016 (Timer_StopScriptsTurningOffCollision)
            local root = obj.K2_GetRootComponent()
            if root and root:IsValid() and root.SetMobility and root.SetMobility:IsValid() then
                root:SetMobility(2)
                obj:K2_TeleportTo({X=-100000,Y=-100000,Z=-100000}, {})
            end
        end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    unblockEA()
end)

-- RegisterKeyBind(Key.C, {ModifierKey.ALT}, unblockEA)
