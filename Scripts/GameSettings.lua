local UEHelpers = require("UEHelpers")

RegisterConsoleCommandHandler("gravity", function(FullCommand, Parameters, Ar)
    local pc = UEHelpers.GetPlayerController()
    local scale = tonumber(Parameters[1]) or 1.0
    pc.Pawn.CharacterMovement.GravityScale = scale
    Ar:Log(string.format("Gravity scale set to %.2f", scale))
    return true
end)


-- doesn't work for default controller, probably uses Lyra/GAS abilities
RegisterConsoleCommandHandler("jumpheight", function(FullCommand, Parameters, Ar)
    local pc = UEHelpers.GetPlayerController()
    local cm = pc.Pawn.CharacterMovement

    local value = tonumber(Parameters[1])
    if not value then
        Ar:Log(string.format("Current JumpZVelocity: %.1f", cm.JumpZVelocity))
        return true
    end

    cm.JumpZVelocity = value
    Ar:Log(string.format("Jump height set (JumpZVelocity = %.1f)", value))

    return true
end)


RegisterConsoleCommandHandler("speed", function(FullCommand, Parameters, Ar)
    local world = UEHelpers.GetWorld()
    local gs = UEHelpers.GetGameplayStatics()
    local value = tonumber(Parameters[1])

    if not value then
        Ar:Log(string.format("Current global time dilation: %.1f", gs:GetGlobalTimeDilation(world)))
        return true
    end

    gs:SetGlobalTimeDilation(world, value)
    Ar:Log(string.format("Speed set to %.1f", value))
    return true
end)
