local UEHelpers = require("UEHelpers")

local ACTIONS = {
    { name = "RealCoinPickup_C", call = function(actor, ctx) actor:Pickup(ctx.pc.Pawn) end },
    { name = "SecretVolume_C", call = function(actor, ctx) actor:SetSecretFound(true, false, true, true) end },
    { name = "ShopItemSpawner_C", call = function(actor, ctx)
        if not actor.bItemIsTaken and actor.ShopItem and actor.ShopItem.ItemName then
            -- print('shopItem', actor.ShopItem.ItemName:ToString()) -- does not have ToString
            -- actor.ShopItem:ApplyPurchase()
        end
    end },
    { name = "PresentBox_Lootpools_C", call = function(actor, ctx) actor:SetIsOpen(true, false, true, true) end },
}

local function autoCollect()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end

    local ctx = { pc = pc }

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            for _, action in ipairs(ACTIONS) do
                local counter = 0
                for _, actor in ipairs(FindAllOf(action.name) or {}) do
                    if actor:IsValid() then
                        if action.call then
                            action.call(actor, ctx)
                            counter = counter + 1
                        end
                    end
                end
                print("--- Collected ---", counter, action.name)
            end
        end)
    end)
end

RegisterKeyBind(Key.P, {ModifierKey.CONTROL}, autoCollect)
