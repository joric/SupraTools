-- https://github.com/joric/supraworld/wiki/Modding

local UEHelpers = require("UEHelpers")

local function openThing()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end
    local cam = pc.PlayerCameraManager
    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())

    if hitObject and hitObject:IsValid() then
        print('--- hitObject---', hitObject:GetFullName())
        local parent = hitObject:GetOuter()
        if parent and parent:IsValid() then
            for _, methodName in ipairs({'Open', '_Flip', '_Press', 'PressUnpress', 'SetUnlocked'}) do
                local method = parent[methodName]
                if method and method:IsValid() then
                    if methodName == 'SetUnlocked' then
                        parent:SetUnlocked(true, true, true, true)
                    else
                        method(parent)
                    end
                    break
                end
            end
        end
    end
end

RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, openThing)
