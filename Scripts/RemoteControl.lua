local UEHelpers = require("UEHelpers")

local ACTIONS = {
    { name = "PressIt" },
    { name = "StartPress", call = function(actor, ctx) if actor.bIsOn then actor:EndPress(ctx.pc.Pawn) else actor:StartPress(ctx.pc.Pawn) end end },
    { name = "UseInteraction" },
    { name = "_Flip" },
    { name = "_Press" },
    { name = "ApplyPurchase" },
    { name = "ButtonPress" },
    { name = "Open", call = function(actor, ctx) if actor.bOpen then actor:Close() else actor:Open() end end },
    { name = "Pickup",     call = function(actor, ctx) actor:Pickup(ctx.pc.Pawn) end },
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
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end

    local cam = pc.PlayerCameraManager
    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
    if not hitObject or not hitObject:IsValid() then return end

    print("--- hitObject ---", hitObject:GetFullName())

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            if not runFirstAvailableAction(hitObject, { pc = pc }) then
                local actor = hitObject:GetOuter()
                if not actor or not actor:IsValid() then return end
                runFirstAvailableAction(actor, { pc = pc })
            end
        end)
    end)
end

RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, remoteControl)
