-- map that uses 1:1 scaling and doesn't update point coordinates, just rotates the layer

-- I am currently having troubles with HDR textures in Supraworld
-- SW_PlayerMapWidget displays them somehow (probably uses HDR material)
-- I cannot find the way to display HDR images in widgets just yet
-- May be Package /PlayerMap/Materials/TextureBrush/M_TextureBrush

local UEHelpers = require("UEHelpers")

local VISIBLE = 4
local HIDDEN = 2

local defaultVisibility = HIDDEN

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local widgetAlignment = 'bottomright'
local widgetOpacity = 0.75
local backgroundColor = FLinearColor(0,0,0,0)
local widgetSize = {X=400, Y=400}
local mapSize = {X=200000, Y=200000}
local scaling = 0.05
local playerColor = FLinearColor(1,1,1,1)
local dotSize = 5.0/scaling
local showTiles = true
local useSpherify = false

local mapWidget = FindObject("UserWidget", "MinimapWidget")
local hooksRegistered = false
local cachedPoints = {}
local playerImage = FindObject("Image", "playerDot")

local pointTypes = {
    -- supraworld
    SecretVolume_C = {FLinearColor(0,1,0,1), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    RealCoinPickup_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    PresentBox_Lootpools_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    ItemSpawner_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    PresentBox_C = {FLinearColor(1,0,1,1),FLinearColor(0,0,0,0)},
    PickupSpawner_C = {FLinearColor(0,0,1,1),FLinearColor(0,0,0,0)},

    -- supraland
    SecretFound_C = {FLinearColor(0,1,0,1), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    Coin_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    PhysicalCoin_C = {FLinearColor(1,0.65,0,1),FLinearColor(0,0,0,0)},
    CoinBig_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    CoinRed_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    Chest_C = {FLinearColor(1,0,0,1),FLinearColor(1,0,0,0)},
    DestroyablePots_C = {FLinearColor(1,0,1,1),FLinearColor(1,0,0,0)},
}

local function setFound(hook, name, found)
    local point = name and cachedPoints and cachedPoints[name]
    if point then
        point.found = found
        if found then
            print("setFound", found, name:match(".*%.(.*)$"), "via", hook:match(".*%.(.*)$"))
            local image = FindObject("Image", name .. ".Dot")
            if image:IsValid() then
                -- print("removing point", image:GetFullName())
                image:RemoveFromParent()
            end
        end
    end
end


local function updateCachedPoints()
    print("-- Calling updateCachedPoints")

    local total = 0
    for type, color in pairs(pointTypes) do
        local count = 0
        for _, actor in ipairs(FindAllOf(type) or {}) do
            if actor:IsValid() then
                local name = actor:GetFullName()

                local found = (actor.bFound == true)  -- SecretVolume_C (supraworld)
                    or (actor.StartClosed == true) -- SecretFound_C (supraland)
                    or (actor.bItemIsTaken == true)
                    or (actor.bPickedUp == true)
                    or (actor.IsOpen == true)
                    or (actor.bHidden == true) -- some coins in Floortown are hidden
                    or (actor['Pickup has been collected'] == true)

                if (type == "Coin_C" or type=="PhysicalCoin_C" or type=="CoinBig_C" or type=="CoinRed_C") 
                    and not actor.Coin:IsValid() or (actor.Coin:IsValid() and not actor.Coin:IsVisible()) then -- the only reliable way I found
                    found = true
                end

                if found then
                    setFound('updateCachedPoints', name, true)
                end

                cachedPoints[name] = cachedPoints[name] or {}
                cachedPoints[name].loc = actor:K2_GetActorLocation() -- cannot cache, coordinates may caught up later
                cachedPoints[name].found = found
                cachedPoints[name].type = type

                count = count + 1
            end
        end
        if count>0 then
            print(string.format("%s: %d", type, count))
            total = total + count
        end
    end
    print(string.format("Total cached points: %d", total))

    -- this is really expensive for some reason (linear search across 1000+ dots?)
    playerImage = FindObject("Image", "playerDot")
end

local function setAlignment(slot, alignment)
    local b = 0

    local alignments = {
        center = {anchor = {0.5, 0.5}, align = {0.5, 0.5}, pos = {0, 0}},
        top = {anchor = {0.5, 0}, align = {0.5, 0}, pos = {0, b}},
        bottom = {anchor = {0.5, 1}, align = {0.5, 1}, pos = {0, -b}},
        topleft = {anchor = {0, 0}, align = {0, 0}, pos = {b, b}},
        topright = {anchor = {1, 0}, align = {1, 0}, pos = {-b, b}},
        bottomleft = {anchor = {0, 1}, align = {0, 1}, pos = {b, -b}},
        bottomright = {anchor = {1, 1}, align = {1, 1}, pos = {-b, -b}}
    }
    local a = alignments[alignment] or alignments.center
    slot:SetAnchors({Minimum = {X = a.anchor[1], Y = a.anchor[2]}, Maximum = {X = a.anchor[1], Y = a.anchor[2]}})
    slot:SetAlignment({X = a.align[1], Y = a.align[2]})
    slot:SetPosition({X = a.pos[1], Y = a.pos[2]})
end

local function addPoint(layer, loc, color, size, name)
    local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), layer, FName(name))
    local slot = layer:AddChildToCanvas(image)
    image:SetColorAndOpacity(color)
    image.Slot:SetAlignment({X = 0.5, Y = 0.5})
    image.Slot:SetPosition({X = loc.X, Y = loc.Y})
    image.Slot:SetSize({X = size, Y = size})
    image.Slot:SetZOrder(math.floor(loc.Z))
    return image
end

local function updateTiles()
    local mapBounds = FindFirstOf("PlayerMapActor_C")
    if not mapBounds:IsValid() then
        return
    end
    -- print("### MAP ACTOR FOUND ###", mapBounds.MapWorldSize, mapBounds.MapWorldCenter.X, mapBounds.MapWorldCenter.Y)
    -- Calculate tile size based on container

    local tileSize = mapBounds.MapWorldSize / 2
    local cx, cy = mapBounds.MapWorldCenter.X - tileSize, mapBounds.MapWorldCenter.Y - tileSize

    local pos = {{0,0},{1,0},{0,1},{1,1}}
    for i = 1, 4 do
        local image = FindObject("Image", "mapTile"..i)
        if image:IsValid() then
            -- Position tile in grid (centered in the larger container)
            image.Slot:SetPosition({X = pos[i][1] * tileSize + cx, Y = pos[i][2] * tileSize + cy})
            image.Slot:SetSize({X = tileSize, Y = tileSize})
            image:SetVisibility(showTiles and VISIBLE or HIDDEN)
            -- image:SetColorAndOpacity({R = 1, G = 1, B = 1, A = 0.5})
        end
    end
end

local function loadImages(bgContainer)
    local templates = {
        "/Game/Blueprints/PlayerMap/Textures/T_Downscale%d.T_Downscale%d",
        "/Game/Blueprints/PlayerMap/Textures/T_SIUMapV7Q%d.T_SIUMapV7Q%d",
        "/PlayerMap/Textures/T_SupraworldMapV4Q%d.T_SupraworldMapV4Q%d",
    }

    local material = StaticFindObject("/PlayerMap/Materials/TextureBrush/M_TextureBrush.M_TextureBrush")
    if material then
        print("-- loaded material", material and material:GetFullName())

        local matlib = StaticFindObject("/Script/Engine.Default__KismetMaterialLibrary")
        print("-- loaded library", matlib:GetFullName(), matlib.CreateDynamicMaterialInstance)

        local world = UEHelpers.GetWorld()
        local dmi = matlib:CreateDynamicMaterialInstance(world, material, FName("mapMaterial"), 0)

        if dmi and dmi:IsValid() then
            print("-- loaded dynamic material", dmi:GetFullName())
        end
    end

    for i = 1, 4 do
        for _,template in ipairs(templates) do
            local path = string.format(template, i-1, i-1)
            local texture = StaticFindObject(path)
            if texture and texture:IsValid() then
                print("Loaded " .. path, 'SRGB', texture.SRGB, 'Compression', texture.CompressionSettings)
                local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), bgContainer, FName("mapTile"..i))
                if not texture.SRGB and dmi and dmi:IsValid() then
                    -- dmi:SetTextureParameterValue("Texture", texture) -- crashes here
                    -- image:SetBrushFromMaterial(dmi)
                else
                    image:SetBrushFromTexture(texture, false)
                end
                local slot = bgContainer:AddChildToCanvas(image)
                slot:SetZOrder(-8000 + i)
                image:SetVisibility(HIDDEN) -- hide images before positioning
                break
            end
        end
    end
end

local function createMinimap()

    mapWidget = FindObject("UserWidget", "MinimapWidget")

    if mapWidget and mapWidget:IsValid() then
        print("Minimap already exists.")
        widget:RemoveFromParent()
        --return
    end

    print("#### CREATING MINIMAP ####")

    local gi = UEHelpers.GetGameInstance()
    local widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("MinimapWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("MinimapTree"))

    local outerCanvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("MinimapOuterCanvas"))
    widget.WidgetTree.RootWidget = outerCanvas

    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), outerCanvas, FName("MinimapBG"))
    bg:SetBrushColor(backgroundColor)
    bg:SetPadding({0,0,0,0})

    local slot = outerCanvas:AddChildToCanvas(bg)
    slot:SetSize(widgetSize)
    setAlignment(slot, widgetAlignment)

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), bg, FName("MinimapCanvas"))
    bg:SetContent(canvas)

    local clipBox = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), canvas, FName("MinimapClipBox"))
    local clipSlot = canvas:AddChildToCanvas(clipBox)
    clipSlot:SetZOrder(-1000)
    clipSlot:SetPosition({X = 0, Y = 0})
    clipSlot:SetAnchors({Minimum = {X = 0, Y = 0}, Maximum = {X = 1, Y = 1}})
    clipSlot:SetOffsets({Left = 0, Top = 0, Right = 0, Bottom = 0})
    clipBox:SetClipping(1)

    -- Create a container for the map background that can be rotated and scaled
    local dotLayer = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), clipBox, FName("DotLayer"))
    local containerSlot = clipBox:AddChildToCanvas(dotLayer)
    containerSlot:SetZOrder(0)
    containerSlot:SetSize(mapSize)
    containerSlot:SetAnchors({ Minimum = {X=0.5, Y=0.5}, Maximum = {X=0.5, Y=0.5} })
    containerSlot:SetAlignment({X=0.5, Y=0.5})
    containerSlot:SetPosition({X = 0, Y = 0})

    loadImages(dotLayer)
    updateTiles()
    updateCachedPoints()

    for name, point in pairs(cachedPoints) do
        local color = pointTypes[point.type][point.found and 2 or 1]
        cachedPoints[name].image = addPoint(dotLayer, point.loc, color, dotSize, name .. ".Dot")
    end

    playerImage = addPoint(dotLayer, {X=0, Y=0, Z=0}, playerColor, dotSize, "playerDot")

    bg:SetVisibility(VISIBLE)
    widget:SetVisibility(defaultVisibility)
    widget:AddToViewport(99)

    widget:SetRenderOpacity(widgetOpacity)

    mapWidget = widget

    local widgetCompClass = StaticFindObject("/Script/UMG.WidgetComponent")
    local widgetComp = StaticConstructObject(widgetCompClass, gi, FName("MinimapWidgetComponent"))

    widgetComp:SetWidget(widget)
    widgetComp:SetTickMode(2)
    widgetComp:SetTickWhenOffscreen(true)


    --[[
    -- trying to tick

-- widget:Initialize()
-- widget.bCanEverTick = true
-- widget:SetVisibility(0) -- Visible

MyWidget:SetTickableWhenPaused(true)



    local widgetCompClass = StaticFindObject("/Script/UMG.WidgetComponent")
    local widgetComp = StaticConstructObject(widgetCompClass, gi, FName("MapWidgetComp"))

        -- widget:SetTickMode(2)  -- Try different values: 0=Disabled, 1=Enabled, 2=Automatic?

    widgetComp:SetDrawSize({X=512,Y=512})
    widgetComp:SetWidgetSpace(1)     -- 1 = screen space, 0 = world space
    widgetComp:SetTickMode(1)        -- ETickMode::Automatic (if exposed)
    widgetComp:SetTwoSided(true)

    -- 4. Assign your manually created widget


    -- 5. Register and attach
    -- gi:AddInstanceComponent(widgetComp)
    -- widgetComp:RegisterComponent()

    widgetComp:SetTickWhenOffscreen(true)

    widgetComp:SetWidget(widget)

    for _, comp in ipairs(FindAllOf("WidgetComponent")or{}) do
        --if comp:GetWidget() == widget then
            print("Found component", comp:GetFullName(), comp:GetWidget():GetFullName())
        --end
    end
    ]]

end

local function updatePoints(loc)
    for name, point in pairs(cachedPoints) do
        local image = cachedPoints[name].image
        if image and image:IsValid() and image.Slot and image.Slot:IsValid() then

            local x, y = point.loc.X, point.loc.Y

            if useSpherify and loc then
                local cx, cy = loc.X, loc.Y

                local w = widgetSize.X / scaling
                local h = widgetSize.Y / scaling

                local relX, relY = x - cx, y - cy
                local dist = math.sqrt(relX*relX + relY*relY)
                local radius = math.min(w, h) / 2 - dotSize / 2

                if dist > radius then
                    local scale = radius / dist
                    relX = relX * scale
                    relY = relY * scale
                    x = cx + relX
                    y = cy + relY
                end
            end

            image.Slot:SetPosition({X = x, Y = y})
        end
    end
end


local throttleMs = 33
local lastTime = 0

local function updateMinimap(hook, name, param)
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end
    -- print("tick!", hook, name, param)

    --if (os.clock() - (lastTime or 0)) * 1000 < throttleMs then return end
    --lastTime = os.clock()

    local bgLayer = FindObject("CanvasPanel", "DotLayer")
    local pc = getCameraController and getCameraController() or UEHelpers.GetPlayerController()

    if pc and pc:IsValid() then
        local cam = pc.PlayerCameraManager
        if cam and cam:IsValid() then
            local loc = cam:GetCameraLocation()
            local rot = cam:GetCameraRotation()

            local size = mapSize.X

            local scale = scaling
            local angle = -rot.Yaw + 270

            local cx = loc.X
            local cy = loc.Y

            local u = cx / size
            local v = cy / size

            bgLayer:SetRenderTransformPivot({X = u, Y = v})

            local tx = size * (0.5 - u)
            local ty = size * (0.5 - v)

            bgLayer:SetRenderTransform({
                Translation = {X = tx, Y = ty},
                Scale = {X = scale, Y = scale},
                Shear = {X = 0, Y = 0}, 
                Angle = angle
            })

            if useSpherify then updatePoints(loc) end

            if playerImage and playerImage:IsValid() then
                playerImage.Slot:SetPosition({X = loc.X, Y = loc.Y})
                playerImage.Slot:SetZOrder(math.floor(loc.Z))
            end
        end
    end

--[[
    ExecuteWithDelay(33,function()
        ExecuteInGameThread(updateMinimap) -- almost stable but hangs on scripts reloading by Ctrl+R
    end)
]]

end

local function toggleMinimap()
    if not mapWidget or not mapWidget:IsValid() then
        createMinimap()
    end

    local visible = mapWidget:GetVisibility()~=VISIBLE

    mapWidget:SetVisibility(visible and VISIBLE or HIDDEN)
    if visible then
        ExecuteAsync(function()
            updateCachedPoints()
            updateMinimap()
        end)
    end
end

local hookInfo = {}

local function registerHooks()
    local hooks = {
        -- supraworld
        { hook = "/SupraCore/Systems/Volumes/SecretVolume.SecretVolume_C:SetSecretFound", call = setFound },
        { hook = "/Supraworld/Levelobjects/PickupBase.PickupBase_C:SetPickedUp", call = setFound },
        { hook = "/Supraworld/Levelobjects/PickupBase.PickupBase_C:ItemPickedup", call = setFound },
        { hook = "/Supraworld/Levelobjects/PickupSpawner.PickupSpawner_C:SetPickedUp", call = setFound },
        { hook = "/Supraworld/Levelobjects/PickupSpawner.PickupSpawner_C:OnSpawnedItemPickedUp", call = setFound }, -- works for hay
        { hook = "/Supraworld/Levelobjects/RespawnablePickupSpawner.RespawnablePickupSpawner_C:SetPickedUp", call = setFound },
        { hook = "/Supraworld/Systems/Shop/ShopItemSpawner.ShopItemSpawner_C:SetItemIsTaken", call = setFound },

        -- this is very CPU intensive but the only I found. Needs checking if UseAndCarry works at start
        { hook = '/Supraworld/Abilities/Interact/Ability_UseAndCarry.Ability_UseAndCarry_C:BndEvt__Ability_UseAndCarry_Tick_PostPhysics_K2Node_ComponentBoundEvent_0_OnTick__DelegateSignature', call = updateMinimap},

        --[[
        -- neither of those fire
        { hook = "/Supraworld/Systems/Talk/Widgets/TalkTextWidget.TalkTextWidget_C:Tick" },
        { hook = "/PlayerMap/SW_PlayerMapWidget.SW_PlayerMapWidget_C:Tick" },
        { hook = "/Supraworld/Core/UserInterface/HUD/W_EquipmentBarSlot.W_EquipmentBarSlot_C:Tick" },
        { hook = "/Supraworld/Abilities/BlowGun/UI/W_Reticle_BlowGun.W_Reticle_BlowGun_C:Tick" },
        { hook = "/SupraworldMenu/UI/Menu/W_UserWatermark.W_UserWatermark_C:Tick" },
        -- these fire ocasionally
        { hook = '/Supraworld/Systems/Talk/Widgets/TextTalkBubbleWidget.TextTalkBubbleWidget_C:Tick', call=updateMinimap }, -- only works in supraworld when bubbles
        { hook = '/Supraworld/Abilities/ToyCharacterIK_Toothpick.ToyCharacterIK_Toothpick_C:Tick_UpdateHandLocations', call=updateMinimap }, -- only works for toothpick
        { hook = '/SupraCore/Core/SupraRotationComponent.SupraRotationComponent_C:Tick_RotateToLocation', call=updateMinimap }, -- slow! super many objects
        { hook = '/Supraworld/Core/PostProcessManagerControllerComponent.PostProcessManagerControllerComponent_C:ReceiveTick', call=updateMinimap}, -- never called
        { hook = '/Script/SupraCore.PlayerStatSubsystem:TickPlaytime', call=updateMinimap},
        { hook = '/Supraworld/Abilities/Interact/Ability_UseAndCarry.Ability_UseAndCarry_C:BndEvt__Ability_UseAndCarry_Tick_PostUpdateWork_K2Node_ComponentBoundEvent_1_OnTick__DelegateSignature', call=function(hook,name,param) updateMinimap(hook,name,param) end},
        { hook = '/SupraCore/Systems/CustomPhysicsHandleActor/PhysicsHandle_Control.PhysicsHandle_Control_C:BndEvt__CustomPhysicsHandleActor_Control_TickComponent_K2Node_ComponentBoundEvent_0_OnTick__DelegateSignature',call=updateMinimap},
        { hook = '/Script/UMG.UserWidget:Tick', call=updateMinimap}, -- never fires, need to set up widget
        ]]

        -- supraland
        { hook = "/Game/Blueprints/Levelobjects/SecretFound.SecretFound_C:Activate" }, -- Supraland
        { hook = "/Game/Blueprints/Levelobjects/SecretFound.SecretFound_C:BndEvt__Box_K2Node_ComponentBoundEvent_0_ComponentBeginOverlapSignature__DelegateSignature" }, -- SIU

        { hook = "/Game/Blueprints/Levelobjects/Coin.Coin_C:Timeline_0__FinishedFunc" },
        { hook = "/Game/Blueprints/Levelobjects/Coin.Coin_C:DestroyAllComponents" },
        { hook = "/Game/Blueprints/Levelobjects/CoinBig.CoinBig_C:Timeline_0__FinishedFunc" },
        { hook = "/Game/Blueprints/Levelobjects/CoinRed.CoinRed_C:Timeline_0__FinishedFunc" },
        { hook = "/Game/Blueprints/Levelobjects/PhysicalCoin.PhysicalCoin_C:DestroyAllComponents" },

        { hook = "/Game/Blueprints/Levelobjects/Chest.chest_C:Timeline_0__FinishedFunc" }, -- Supraland
        { hook = "/Game/Blueprints/Levelobjects/Chest.Chest_C:Timeline_0__FinishedFunc" }, -- SIU

        { hook = "/Game/Blueprints/Levelobjects/DestroyablePots.DestroyablePots_C:ReceiveAnyDamage" },
        { hook = '/Game/FirstPersonBP/Blueprints/HintText.HintText_C:Tick', call=updateMinimap }, -- works in supraland and/or siu pretty reliably (not in supraworld)
    }

    for _, hook in ipairs(hooks) do
        ok, err = pcall(function()
            local p = hookInfo[hook.hook]
            if p then
                UnregisterHook(hook.hook, preId, postId)
            end
            local preId, postId = RegisterHook(hook.hook, function(self, param, ...)
                hookInfo[hook.hook] = {}
                hookInfo[hook.hook].preId = preId
                hookInfo[hook.hook].postId = postId
                local name = self:get():GetFullName()
                -- print("Hook fired:", hook.hook, "Self:", self:get():GetFName():ToString(), "param", param and param:get())
                if hook.call then
                    hook.call(hook.hook, name, param and param:get())
                else
                    setFound(hook.hook, name, true)
                end
            end)
        end)
        -- print(ok and "REGISTERED" or "NOT FOUND", hook.hook)
    end
end

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(self, pawn)
    if pawn:get():GetFullName():find("DefaultPawn") then
        print("--- ignoring default pawn ---")
        return
    end

    -- need delay to load things
    ExecuteWithDelay(1000, function()
        createMinimap()
        updateMinimap()
        registerHooks()
    end)

end)

LoopAsync(60000, function()  -- let's see if hooks work
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end
    updateCachedPoints()
    updateMinimap()
end)

print("-- mapWidget", mapWidget and mapWidget:IsValid())

if mapWidget and mapWidget:IsValid() then
    print("-- re-registering hooks -- ")
    registerHooks()
    ExecuteAsync(updateCachedPoints)
end

local widgetPosition = 0

local widgetPositions = {
    {align='bottomright', size={X=400,Y=400}},
    {align='bottomleft', size={X=400,Y=400}},
    {align='topleft', size={X=400,Y=400}},
    {align='topright', size={X=400,Y=400}},
    {align='center', size={X=800,Y=800}},
}

local function updateMinimapWidget()
    if not mapWidget or not mapWidget:IsValid() then return end
    local obj = FindObject("Border", "MinimapBG")
    if not obj:IsValid() then return end
    obj.Slot:SetSize(widgetSize)
    setAlignment(obj.Slot, widgetAlignment)
    updateTiles()
    updatePoints()
end

local function cycleMinimapPosition()
    widgetPosition = (widgetPosition + 1) % #widgetPositions
    local p = widgetPositions[widgetPosition+1]
    widgetAlignment = p.align
    widgetSize = p.size
    updateMinimapWidget()
end

local function toggleSpherify()
    useSpherify = not useSpherify
    updateMinimapWidget()
end

local function toggleTiles()
    showTiles = not showTiles
    updateMinimapWidget()
end

-- RegisterKeyBind(Key.R, {}, updateCachedPoints)

RegisterKeyBind(Key.M, {ModifierKey.ALT}, toggleMinimap)
RegisterKeyBind(Key.M, {ModifierKey.ALT, ModifierKey.CONTROL}, cycleMinimapPosition)
RegisterKeyBind(Key.M, {ModifierKey.SHIFT}, toggleTiles)
RegisterKeyBind(Key.M, {ModifierKey.CONTROL}, toggleSpherify)

RegisterConsoleCommandHandler("minimap", function(FullCommand, Parameters, Ar)
    Ar:Log(supraToolsAttribution)
    Ar:Log("toggling minimap")
    toggleMinimap()
    return true
end)


