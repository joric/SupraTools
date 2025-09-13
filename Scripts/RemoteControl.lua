local UEHelpers = require("UEHelpers")

local function remoteControl()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return
    end

    local cam = pc.PlayerCameraManager
    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())

    if hitObject and hitObject:IsValid() then
        print('--- hitObject ---', hitObject:GetFullName())
        local parent = hitObject:GetOuter()
        if parent and parent:IsValid() then
            print('--- parent ---', parent:GetFullName())

            ExecuteWithDelay(250, function()
                ExecuteInGameThread(function()
                    for _, methodName in ipairs({'Open', '_Flip', '_Press', 'PressUnpress', 'SetUnlocked', 'SetIsOpen', 'ApplyPurchase'}) do
                        local method = parent[methodName]
                        if method and method:IsValid() then
                            print('executing', methodName)
                            if methodName == 'SetUnlocked' then 
                                parent:SetUnlocked(true, true, true, true)
                            elseif methodName == 'SetIsOpen' then 
                                parent:SetIsOpen(true, true, true, true)
                            elseif methodName == 'ApplyPurchase' then 
                                parent:ApplyPurchase()
                            else
                                method(parent)
                            end

                            break
                        end
                    end
                end)
            end)
        end
    end
end

RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, remoteControl)
