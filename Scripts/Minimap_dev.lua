-- map that uses 1:1 scaling and doesn't update point coordinates, just rotates the layer

-- I am currently having troubles with HDR textures in Supraworld
-- SW_PlayerMapWidget displays them somehow (probably uses HDR material)
-- I cannot find the way to display HDR images in widgets just yet
-- May be Package /PlayerMap/Materials/TextureBrush/M_TextureBrush

local UEHelpers = require("UEHelpers")

local VISIBLE = 4
local HIDDEN = 2

local defaultVisibility = VISIBLE

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local widgetAlignment = 'bottomright'
local widgetOpacity = 0.75
local widgetSize = {X=400, Y=400}
local mapSize = {X=200000, Y=200000}
local scaling = 0.05
local cachedPoints = nil
local playerColor = FLinearColor(1,1,1,1)
local dotSize = 5.0/scaling

local mapWidget = FindObject("UserWidget", "mapWidget")

local pointTypes = {
    -- supraworld
    SecretVolume_C = {FLinearColor(0,1,0,1), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    RealCoinPickup_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    PresentBox_Lootpools_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    ItemSpawner_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    PresentBox_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    PickupSpawner_C = {FLinearColor(0,0,1,1),FLinearColor(0,0,0,0)},

    -- supraland
    SecretFound_C = {FLinearColor(0,1,0,1), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    Coin_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    PhysicalCoin_C = {FLinearColor(1,0.65,0,1),FLinearColor(0,0,0,0)},
    CoinBig_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    CoinRed_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    Chest_C = {FLinearColor(1,0,0,1),FLinearColor(1,0,0,0)},
}

local function updateCachedPoints()
    cachedPoints = cachedPoints or {}
    for type, color in pairs(pointTypes) do
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

                cachedPoints[name] = cachedPoints[name] or {}
                cachedPoints[name].loc = actor:K2_GetActorLocation() -- cannot cache, coordinates may caught up later
                cachedPoints[name].found = found
                cachedPoints[name].type = type
            end
        end
    end
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
    image.Slot:SetPosition({X = loc.X  -size/2, Y = loc.Y - size/2})
    image.Slot:SetSize({X = size, Y = size})
    image.Slot:SetZOrder(math.floor(loc.Z))
    return image
end

local function positionImages()
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
            image:SetVisibility(VISIBLE)
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
                    print("Setting texture to material (crashes here)")
                    -- dmi:SetTextureParameterValue("Texture", texture) -- crashes here
                    image:SetBrushFromMaterial(dmi)
                else
                    image:SetBrushFromTexture(texture, false)
                end

                local slot = bgContainer:AddChildToCanvas(image)
                slot:SetZOrder(-8000 + i)
                break
            end
        end
    end
end

local function createMinimap()
    if mapWidget and mapWidget:IsValid() then
        print("Minimap already exists.")
        return
    end

    print("### CREATING MINIMAP ###")

    local gi = UEHelpers.GetGameInstance()
    local widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("mapWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("MinimapTree"))

    local canvas0 = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("MinimapCanvas"))
    widget.WidgetTree.RootWidget = canvas0

    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas0, FName("MinimapBG"))
    bg:SetBrushColor(FLinearColor(1,1,1,0.5))
    bg:SetPadding({0,0,0,0})

    local slot = canvas0:AddChildToCanvas(bg)
    slot:SetSize(widgetSize)
    setAlignment(slot, widgetAlignment)

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), bg, FName("MapBaseCanvas"))
    bg:SetContent(canvas)

    local clipBox = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), canvas, FName("MapClipBox"))
    local clipSlot = canvas:AddChildToCanvas(clipBox)
    clipSlot:SetZOrder(-1000)
    clipSlot:SetSize(widgetSize)
    clipSlot:SetPosition({X = 0, Y = 0})
    clipBox:SetClipping(1)

    -- Create a container for the map background that can be rotated and scaled
    local bgContainer = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), clipBox, FName("DotLayer"))
    local containerSlot = clipBox:AddChildToCanvas(bgContainer)
    containerSlot:SetZOrder(0)
    containerSlot:SetSize(mapSize)
    containerSlot:SetPosition({X = 0, Y = 0})
    containerSlot:SetAlignment({X = 0.5, Y = 0.5})

    loadImages(bgContainer)
    positionImages()
    updateCachedPoints()

    layer = bgContainer

    for name, point in pairs(cachedPoints) do
        local color = pointTypes[point.type][point.found and 2 or 1]
        addPoint(layer, point.loc, color, dotSize, name .. ".Dot")
    end

    addPoint(layer, {X=0, Y=0, Z=0}, playerColor, dotSize, "playerDot")
    addPoint(layer, {X=0, Y=0, Z=0}, FLinearColor(1,1,1,0.5), dotSize, "centerDot")

    bg:SetVisibility(VISIBLE)
    widget:SetVisibility(defaultVisibility)
    widget:AddToViewport(99)

    widget:SetRenderOpacity(widgetOpacity)

    mapWidget = widget

    --[[
    -- trying to tick

-- widget:Initialize()
-- widget.bCanEverTick = true
-- widget:SetVisibility(0) -- Visible


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

local function updateMinimap()
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end

    -- print("tick!")

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

            local tx = size * (0.5 - u) + widgetSize.X/2
            local ty = size * (0.5 - v) + widgetSize.Y/2

            bgLayer:SetRenderTransform({
                Translation = {X = tx, Y = ty},
                Scale = {X = scale, Y = scale},
                Shear = {X = 0, Y = 0}, 
                Angle = angle
            })

            local playerImage = FindObject("Image", "playerDot")
            if playerImage and playerImage:IsValid() then
                playerImage.Slot:SetPosition({X = loc.X - dotSize/2, Y = loc.Y - dotSize/2})
                playerImage.Slot:SetZOrder(math.floor(loc.Z))
            end

        end
    end

--[[
    ExecuteWithDelay(16,function()
        ExecuteInGameThread(updateMinimap) -- seems much more stable this way!
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
        updateCachedPoints()
        updateMinimap()
    end
end

local function setFound(hook, name, found)
    local point = cachedPoints and cachedPoints[name]
    if point then
        point.found = found
        if found then
            -- print("setFound", found, name:match(".*%.(.*)$"), "via", hook:match(".*%.(.*)$"))

            if name ~= nil then
                local image = FindObject("Image", name .. ".Dot")

                if image:IsValid() then
                    -- print("removing point", image:GetFullName())
                    image:RemoveFromParent()
                end
            end

        end
    end
end

local function registerHooks()
    local hooks = {
        -- supraworld
        { hook = "/SupraCore/Systems/Volumes/SecretVolume.SecretVolume_C:SetSecretFound", call = function(hook,name,param) setFound(hook,name,param) end },
        { hook = "/Supraworld/Levelobjects/PickupBase.PickupBase_C:SetPickedUp", call = function(hook,name,param) setFound(hook,name,param) end },
        { hook = "/Supraworld/Levelobjects/PickupBase.PickupBase_C:ItemPickedup", call = function(hook,name,param) setFound(hook,name,param) end },
        { hook = "/Supraworld/Levelobjects/PickupSpawner.PickupSpawner_C:SetPickedUp", call = function(hook,name,param) setFound(hook,name,param) end },
        { hook = "/Supraworld/Levelobjects/PickupSpawner.PickupSpawner_C:OnSpawnedItemPickedUp", call = function(hook,name,param) setFound(hook,name,param) end }, -- works for hay
        { hook = "/Supraworld/Levelobjects/RespawnablePickupSpawner.RespawnablePickupSpawner_C:SetPickedUp", call = function(hook,name,param) setFound(hook,name,param) end },
        { hook = "/Supraworld/Systems/Shop/ShopItemSpawner.ShopItemSpawner_C:SetItemIsTaken", call = function(hook,name,param) setFound(hook,name,param) end },

        -- supraland
        { hook = "/Game/Blueprints/Levelobjects/SecretFound.SecretFound_C:Activate" },
        { hook = "/Game/Blueprints/Levelobjects/Coin.Coin_C:Timeline_0__FinishedFunc" },
        { hook = "/Game/Blueprints/Levelobjects/CoinBig.CoinBig_C:Timeline_0__FinishedFunc" },
        { hook = "/Game/Blueprints/Levelobjects/CoinRed.CoinRed_C:Timeline_0__FinishedFunc" },
        { hook = "/Game/Blueprints/Levelobjects/Coin.Coin_C:DestroyAllComponents" },
        { hook = "/Game/Blueprints/Levelobjects/PhysicalCoin.PhysicalCoin_C:DestroyAllComponents" },
        { hook = "/Game/Blueprints/Levelobjects/Chest.chest_C:ActivateOpenForever"},
        { hook = "/Game/Blueprints/Levelobjects/Chest.chest_C:Activate"},
        { hook = "/Game/Blueprints/Levelobjects/Chest.chest_C:NPCStealsStuffFromChest"},
        { hook = "/Game/Blueprints/Levelobjects/Chest.chest_C:Timeline_0__FinishedFunc" },


        { hook = '/Game/FirstPersonBP/Blueprints/HintText.HintText_C:Tick', call=updateMinimap },
        { hook = '/Supraworld/Systems/Talk/Widgets/TextTalkBubbleWidget.TextTalkBubbleWidget_C:Tick', call=updateMinimap },

    }

    for _, hook in ipairs(hooks) do
        ok, err = pcall(function()
            RegisterHook(hook.hook, function(self, param, ...)
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

    createMinimap()
    updateMinimap()
    registerHooks()

end)


LoopAsync(60000, function()  -- let's see if hooks work
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end
    --updateCachedPoints()
    --updateMinimap()
end)

RegisterKeyBind(Key.M, {ModifierKey.ALT}, toggleMinimap)

RegisterConsoleCommandHandler("minimap", function(FullCommand, Parameters, Ar)
    Ar:Log(supraToolsAttribution)
    Ar:Log("toggling minimap")
    toggleMinimap()
    return true
end)

registerHooks()
