-- https://github.com/joric/supraworld/wiki/Modding

local function suitRefill()
    local obj = FindFirstOf("Equippable_SpongeSuit_C")
    if obj and obj:IsValid() then
        obj:SetCurrentFill(1.0)
    end
end

RegisterKeyBind(Key.R, suitRefill)
