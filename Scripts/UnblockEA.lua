local UEHelpers = require("UEHelpers")
local KismetSystem = UEHelpers.GetKismetSystemLibrary()

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

            local handle = obj.Timer_StopScriptsTurningOffCollision
            if handle:IsValid() then
                -- KismetSystem:K2_ClearTimerHandle(obj, handle) -- crashes, investigate this call
            end

        end
    end

    -- LoopAsync(500, unblockEA)
    ExecuteWithDelay(500, unblockEA)
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    cacheEA()

    pcall(function()
        RegisterHook("/SupraCore/Systems/Volumes/SupraEABlockingVolume.SupraEABlockingVolume_C:StartTimer_StopScriptsTurningOffCollision", function(self)
            -- print("--- StartTimer_StopScriptsTurningOffCollision called!")
            return false   -- swallow the restart
        end)
    end)

    pcall(function()
        RegisterHook("/SupraCore/Systems/Volumes/SupraEABlockingVolume.SupraEABlockingVolume_C:Proc_StopScriptsTurningOffCollision", function(self)
            -- print("--- Proc_StopScriptsTurningOffCollision called!")
            return false   -- swallow the restart
        end)
    end)

end)

-- if you get teleported to 0,0,0 before pressing Alt+C it means it's not the UnblockEA collision state-based "protection" but something else

RegisterKeyBind(Key.C, {ModifierKey.ALT}, unblockEA)

