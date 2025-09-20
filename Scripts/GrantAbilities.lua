local UEHelpers = require("UEHelpers")

local function grantAbility(InvDefPath)
    ExecuteWithDelay(50, function()
        ExecuteInGameThread(function()

            local InvMgr = nil

            for _, obj in ipairs(FindAllOf("LyraInventoryManagerComponent") or {}) do
                if obj:IsValid() then
                    if string.find(obj:GetFullName(), 'SupraworldPlayerController_C') then
                        InvMgr = obj
                        break
                    end
                end
            end

            if not InvMgr then 
                print("Could not find inventory manager")
                return
            end

            -- Load the inventory definition
            LoadAsset(InvDefPath)
            local InvDef = StaticFindObject(InvDefPath)
            if InvDef == nil or not InvDef:IsValid() then
                print("Couldn't load inventory def:", InvDefPath)
                return
            end

            -- Check if the item is already granted
            local it = InvMgr:FindFirstItemStackByDefinition(InvDef)
            if it and it:IsValid() then
                print("Item already granted:", InvDefPath)
                return
            end

            if not InvMgr:CanAddItemDefinition(InvDef, 1) then
                print("Cannot add item: CanAddItemDefinition returned false")
                return
            end

            -- Add the inventory item
            local ItemInstance = InvMgr:AddItemDefinition(InvDef, 1)
            if ItemInstance ~= nil then
                print("Granted inventory item", InvDefPath)
            else
                print("AddItemDefinition failed")
                return
            end

        end)
    end)
end

local function grantAbilities()
    grantAbility('/Supraworld/Abilities/Walk/Inventory_Walk.Inventory_Walk_C')
    grantAbility('/Supraworld/Abilities/Crouch/Inventory_Crouch.Inventory_Crouch_C')
    grantAbility('/Supraworld/Abilities/Run/Inventory_Run.Inventory_Run_C')
    grantAbility('/Supraworld/Abilities/Jump/Jumps/Inventory_Jump.Inventory_Jump_C')
    grantAbility('/Supraworld/Abilities/Jump/JumpHeight/Inventory_JumpHeightDouble.Inventory_JumpHeightDouble_C')
    grantAbility('/Supraworld/Abilities/Strength/Inventory_Strength.Inventory_Strength_C')

    grantAbility('/Supraworld/Abilities/BlowGun/Core/Inventory_BlowGun.Inventory_BlowGun_C')

    grantAbility('/Supraworld/Abilities/Toothpick/Lyra/Inventory_Toothpick.Inventory_Toothpick_C')
    grantAbility('/Supraworld/Abilities/Toothpick/Upgrades/ToothpickDart/Inventory_Toothpin_Dart.Inventory_Toothpin_Dart_C')

    grantAbility('/Supraworld/Abilities/ThoughtReading/Inventory_ThoughtReading.Inventory_ThoughtReading_C')
    grantAbility('/Supraworld/Abilities/Ghost/Inventory_ThirdEye.Inventory_ThirdEye_C')
    grantAbility('/Supraworld/Abilities/Dash/Inventory_Dash.Inventory_Dash_C')

    grantAbility('/Supraworld/Abilities/PlayerMap/Inventory_PlayerMap.Inventory_PlayerMap_C')

    grantAbility('/Supraworld/Abilities/SpongeSuit/Upgrades/Inventory_SpongeSuit.Inventory_SpongeSuit_C')

    -- act 2 abilities

    grantAbility('/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C')  -- not sure if works

    grantAbility('/Supraworld/Abilities/LaserWalk/Inventory_LaserWalk.Inventory_LaserWalk_C')

    -- grantAbility('/Supraworld/Abilities/MindControl/Inventory_MindControl.Inventory_MindControl_C') -- unfinished, breaks control/saves

    grantAbility('/Supraworld/Abilities/MindVision/Inventory_MindVision.Inventory_MindVision_C')
    grantAbility('/Supraworld/Abilities/Shield/Inventory_Shield.Inventory_Shield_C')

    -- misc

    grantAbility('/Supraworld/Abilities/SmellImmunity/Inventory_SmellImmunity.Inventory_SmellImmunity_C') -- doesn't seem player compatible

end

-- experimental, does not work yet

RegisterKeyBind(Key.G, {ModifierKey.CONTROL}, grantAbilities)
