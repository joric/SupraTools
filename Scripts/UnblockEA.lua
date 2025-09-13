-- https://github.com/joric/supraworld/wiki/Modding

local function unblockEA()
    for _, obj in ipairs(FindAllOf("SupraEABlockingVolume_C") or {}) do
        if obj:IsValid() then
            obj:SetActorEnableCollision(false)
        end
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    unblockEA()
end)
