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
        end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    cacheEA()
    unblockEA()
end)

LoopAsync(500, unblockEA)

--[[
    --- investigate other methods

    local UEHelpers = require("UEHelpers")
    local KismetSystem = UEHelpers.GetKismetSystemLibrary()

    local handle = obj.Timer_StopScriptsTurningOffCollision
    if handle:IsValid() then
        -- KismetSystem:K2_ClearTimerHandle(obj, handle) -- crashes, investigate this call
    end

    RegisterHook("/SupraCore/Systems/Volumes/SupraEABlockingVolume.SupraEABlockingVolume_C:StartTimer_StopScriptsTurningOffCollision",
    function(self)
        return false   -- swallow the restart
    end
]]


