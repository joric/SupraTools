local UEHelpers = require("UEHelpers")

local function grantAbility(InvDefPath)
    ExecuteWithDelay(250, function()
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
            local Pawn = PC.Pawn

            -- Get the pawn's inventory manager using K2_GetComponentsByClass
            local InvMgrClass = StaticFindObject("/Script/LyraGame.LyraInventoryManagerComponent")
            local Comps = PC:K2_GetComponentsByClass(InvMgrClass)
            if Comps == nil or #Comps == 0 then
                print("Pawn has no inventory manager")
                return
            end
            local InvMgr = Comps[1]

            --[[
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
            ]]

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
        end)
    end)
end

local function grantAbilities()
    -- grantAbility('/Supraworld/Abilities/Spark/Inventory_Spark.Inventory_Spark_C')
    grantAbility('/Supraworld/Abilities/SpongeSuit/Upgrades/Inventory_SpongeSuit.Inventory_SpongeSuit_C')
end

-- experimental, does not work yet

RegisterKeyBind(Key.G, {ModifierKey.CONTROL}, grantAbilities)
