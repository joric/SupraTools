local UEHelpers = require("UEHelpers")

local function grantAbility(InvDefPath)
    ExecuteWithDelay(50, function()
        ExecuteInGameThread(function()
            -- Load the inventory definition
            LoadAsset(InvDefPath)
            local InvDef = StaticFindObject(InvDefPath)
            if InvDef == nil or not InvDef:IsValid() then
                print("Couldn't load inventory def:", InvDefPath)
                return
            end
            print("Loaded inventory def: ", InvDefPath)

            -- Get local player controller and pawn
            local PC = UEHelpers.GetPlayerController()
            if PC == nil or PC.Pawn == nil then
                print("No player pawn found")
                return
            end

            print('PC:', PC:GetFullName())
            local Pawn = PC.Pawn

            -- Get the pawn's inventory manager using K2_GetComponentsByClass
            local InvMgrClass = StaticFindObject("/Script/LyraGame.LyraInventoryManagerComponent")
            local Comps = PC:K2_GetComponentsByClass(InvMgrClass)
            if Comps == nil or #Comps == 0 then
                print("Pawn has no inventory manager")
                return
            end
            local InvMgr = Comps[1]
            print('InvMgr:', InvMgr:GetFullName())

            for _, obj in ipairs(FindAllOf("LyraInventoryManagerComponent") or {}) do
                if obj:IsValid() then
                    if string.find(obj:GetFullName(), 'SupraworldPlayerController') then
                        InvMgr = obj
                        print('obj:', obj:GetFullName())
                        break
                    end
                end
            end

            if not InvMgr:CanAddItemDefinition(InvDef, 1) then
                print("Cannot add item: CanAddItemDefinition returned false")
                return
            end

            -- Add the inventory item
            local ItemInstance = InvMgr:AddItemDefinition(InvDef, 1)
            if ItemInstance ~= nil then
                print("Granted inventory item -> abilities and UI updated")
            else
                print("AddItemDefinition failed")
                return
            end

            --[[
            -- Dump the pawn's inventory
            local Items = InvMgr:GetAllItems()
            if Items == nil or #Items == 0 then
                print("Inventory is empty")
                return
            end

            print("Inventory dump:")
            for i, Item in ipairs(Items) do
                if Item ~= nil and Item:IsValid() then
                    print(i .. ": " .. Item:GetFullName())
                else
                    print(i .. ": invalid item")
                end
            end
            ]]

        end)
    end)
end

local function grantAbilities()
    grantAbility('/Supraworld/Abilities/MindControl/Inventory_MindControl.Inventory_MindControl_C')
    grantAbility('/Supraworld/Abilities/Walk/Inventory_Walk.Inventory_Walk_C')
    grantAbility('/Supraworld/Abilities/Run/Inventory_Run.Inventory_Run_C')
    grantAbility('/Supraworld/Abilities/LaserWalk/Inventory_LaserWalk.Inventory_LaserWalk_C')
    grantAbility('/Supraworld/Abilities/Jump/JumpHeight/Inventory_JumpHeightDouble.Inventory_JumpHeightDouble_C')
    grantAbility('/Supraworld/Abilities/Jump/Jumps/Inventory_Jump.Inventory_Jump_C')
    grantAbility('/Supraworld/Abilities/Ghost/Inventory_ThirdEye.Inventory_ThirdEye_C')
    grantAbility('/Supraworld/Abilities/Crouch/Inventory_Crouch.Inventory_Crouch_C')
    grantAbility('/Supraworld/Abilities/Dash/Inventory_Dash.Inventory_Dash_C')
    grantAbility('/Supraworld/Abilities/Strength/Inventory_Strength.Inventory_Strength_C')
    grantAbility('/Supraworld/Abilities/Toothpick/Lyra/Inventory_Toothpick.Inventory_Toothpick_C')
    grantAbility('/Supraworld/Abilities/Toothpick/Upgrades/ToothpickDart/Inventory_Toothpin_Dart.Inventory_Toothpin_Dart_C')
    grantAbility('/Supraworld/Abilities/MindControl/Inventory_MindControl.Inventory_MindControl_C')
    grantAbility('/Supraworld/Abilities/MindVision/Inventory_MindVision.Inventory_MindVision_C')
    grantAbility('/Supraworld/Abilities/PlayerMap/Inventory_PlayerMap.Inventory_PlayerMap_C')
    grantAbility('/Supraworld/Abilities/Shield/Inventory_Shield.Inventory_Shield_C')
    grantAbility('/Supraworld/Abilities/SmellImmunity/Inventory_SmellImmunity.Inventory_SmellImmunity_C')
    grantAbility('/Supraworld/Abilities/ThoughtReading/Inventory_ThoughtReading.Inventory_ThoughtReading_C')
    grantAbility('/Supraworld/Abilities/BlowGun/Core/Inventory_BlowGun.Inventory_BlowGun_C')
    grantAbility('/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C')
    grantAbility('/Supraworld/Abilities/SpongeSuit/Upgrades/Inventory_SpongeSuit.Inventory_SpongeSuit_C')
end

-- experimental, does not work yet

RegisterKeyBind(Key.G, {ModifierKey.CONTROL}, grantAbilities)
