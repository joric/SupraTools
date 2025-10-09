local UEHelpers = require("UEHelpers")

local function suitRefill(color)
    local obj = FindFirstOf("Equippable_SpongeSuit_C")
    if obj and obj:IsValid() then

        if color then
            ---@param Instigator AActor
            ---@param Type LiquidType::Type
            ---@param Color ESupraColors
            ---@param VolumeChange double
            ---function AEquippable_SpongeSuit_C:Liquid(Instigator, Type, Color, VolumeChange) end
            print("Exposing to liquid with color", color, "current color", obj.CurrentColor)
            -- see enums: 1 is water, 2 is paint, 3 is oil
            -- ESupraColors:Whilte is 16
            local pc = UEHelpers.GetPlayerController()
            obj:Liquid(pc, 2, 16, 0.0) -- paint, white. does not work. maybe use real paint volume as instigator?
        end

        obj:SetCurrentFill(1.0)
    end
    return true
end

-- RegisterKeyBind(Key.R, suitRefill) -- remove in version 1.0.1 (affects console commands)
-- cannot use Ctrl+R either (system bind on reload scripts)
-- cannot use Alt+R (bind on rotation)

RegisterKeyBind(Key.F, {ModifierKey.ALT}, function()
    suitRefill(1)
end)

RegisterKeyBind(Key.F, {ModifierKey.CONTROL}, function()
    suitRefill(1)
end)

RegisterConsoleCommandHandler("refill", function(FullCommand, Parameters, Ar)
    if suitRefill(Parameters[1]) then
        Ar:Log('suit refilled')
    end
    return true
end)
