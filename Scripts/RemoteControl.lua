local UEHelpers = require("UEHelpers")

local ACTIONS = { -- ordered by priority
    { name = "PressIt" },
    { name = "StartPress", call = function(actor, ctx) if actor.bIsOn then actor:EndPress(ctx.pc.Pawn) else actor:StartPress(ctx.pc.Pawn) end end },
    { name = "UseInteraction" },
    { name = "_Flip" },
    { name = "_Press" },
    { name = "ApplyPurchase" },
    { name = "ButtonPress" },
    { name = "Set_Active",  call = function(actor) actor:Set_Active(true, false, false, false) end }, -- enables jumppads
    -- { name = "Activate" }, -- supraland jumppads, needs 0 paremeters in supraland and 1 parameter in supraworld
    { name = "Open", call = function(actor, ctx) if actor.bOpen then actor:Close() else actor:Open() end end },
    { name = "Heat", call = function(actor, ctx) actor:Heat(ctx.pc.Pawn, true) end }, -- melts chocolate eggs
    { name = "Pickup", call = function(actor, ctx) actor:Pickup(ctx.pc.Pawn) end },
    { name = "SetUnlocked", call = function(actor) actor:SetUnlocked(true, true, true, true) end },
    { name = "SetIsOpen",  call = function(actor) actor:SetIsOpen(true, true, true, true) end },
}

local function runFirstAvailableAction(actor, ctx)
    for _, action in ipairs(ACTIONS) do
        local method = actor[action.name]
        if method and method:IsValid() then
            print("--- Calling ---", action.name, actor:GetFullName())
            if action.call then
                action.call(actor, ctx)
            else
                method(actor)
            end
            return true
        end
    end
    return false
end

local function remoteControl()
    local hitObject = getCameraHitObject()
    if not hitObject or not hitObject:IsValid() then return end

    print("--- hitObject ---", hitObject:GetFullName())

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            local pc = UEHelpers.GetPlayerController()
            if not runFirstAvailableAction(hitObject, { pc = pc }) then
                local actor = hitObject:GetOuter()
                if not actor or not actor:IsValid() then return end
                print("hitObject outer", actor:GetFullName())
                if not runFirstAvailableAction(actor, { pc = pc }) then
                    -- out of actions
                end
            end
        end)
    end)
end

RegisterKeyBind(Key.E, {ModifierKey.ALT}, remoteControl)
RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, {ModifierKey.CONTROL}, remoteControl)
