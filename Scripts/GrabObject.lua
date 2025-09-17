local UEHelpers = require("UEHelpers")

local function tryGrabbingObject(actor, ctx)
    if actor.bMovable then
        local comp = actor.RootComponent
        if comp and comp:IsValid() then

            local cam = ctx.pc.PlayerCameraManager
            local pos, rot = cam:GetCameraLocation(), cam:GetCameraRotation()
            local dv = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(rot), 100.0)
            local loc = UEHelpers.GetKismetMathLibrary():Add_VectorVector(pos, dv)

            if comp.bSimulatePhysics then
                print("Physics object, moving root component", actor:GetFullName())
                local HitResult = {}
                comp:K2_SetWorldLocation(loc, false, HitResult, true)
            else
                print("Movable, teleporting actor", actor:GetFullName())
                actor:K2_TeleportTo(loc, rot) 
            end
        else
            print("No valid root component")
        end
    else
        print('Object is not movable')
    end
end

local function grabObject()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end

    local cam = pc.PlayerCameraManager
    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
    if not hitObject or not hitObject:IsValid() then return end

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            if not tryGrabbingObject(hitObject, { pc = pc }) then
                local actor = hitObject:GetOuter()
                if not actor or not actor:IsValid() then return end
                if not tryGrabbingObject(actor, { pc = pc }) then
                    -- could not grab object
                end
            end
        end)
    end)
end

RegisterKeyBind(Key.G, grabObject)
