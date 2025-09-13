local UEHelpers = require("UEHelpers")

local function autoCollect()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end

    local counter = 0

    for _, obj in ipairs(FindAllOf("RealCoinPickup_C") or {}) do
        if obj:IsValid() then
            obj:Pickup(pc.Pawn)
            counter = counter + 1
        end
    end

    print("Collected", counter, "coins.")

    counter = 0

    for _, obj in ipairs(FindAllOf("ShopItemSpawner_C") or {}) do
        if obj:IsValid() then
            --- obj:Pickup(pc.Pawn) -- hangs
            counter = counter + 1
        end
    end

    print("Looted", counter, "spawners.")

    counter = 0

    for _, obj in ipairs(FindAllOf("SecretVolume_C") or {}) do
        if obj:IsValid() then
            obj:SetSecretFound(true, true, true, true)
            counter = counter + 1
        end
    end

    print("Found", counter, "secrets.")

end

RegisterKeyBind(Key.P, {ModifierKey.CONTROL}, autoCollect)
