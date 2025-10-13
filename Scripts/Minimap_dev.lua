local UEHelpers = require("UEHelpers")

local VISIBLE = 4
local HIDDEN = 2

local defaultVisibility = VISIBLE

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local defaultAlignment = 'bottomleft'
local mapSize = {X=512, Y=512}
local scaling = 0.03
local dotSize = 3
local playerDotSize = 5
local cachedPoints = nil
local playerColor = FLinearColor(0,0,0,1) -- must be visible despite z-order

-- Map background configuration
local mapTextureSize = 2048 -- actual texture size per tile (adjust if needed)
local mapWorldSize = 100000 -- world units covered by the entire map (adjust based on game world)
local mapScale = mapSize.X / (mapWorldSize * scaling) -- scale factor for map vs world

local mapWidget = nil -- FindObject("UserWidget", "mapWidget")
local bgLayer = nil
local playerImage = nil
local playerImage2 = nil

local pointTypes = {
    -- supraworld
    SecretVolume_C = {FLinearColor(0,1,0, 1), FLinearColor(0.5, 0.5, 0.5, 0.5)},
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
                    or (actor.bHidden == true) -- some coins in Floortown are hidden
                    or (actor['Pickup has been collected'] == true)

                if (type == "Coin_C" or type=="PhysicalCoin_C" or type=="CoinBig_C" or type=="CoinRed_C") 
                    and not actor.Coin:IsValid() or (actor.Coin:IsValid() and not actor.Coin:IsVisible()) then
                    found = true
                end

                cachedPoints[name] = cachedPoints[name] or {}
                cachedPoints[name].loc = actor:K2_GetActorLocation()
                cachedPoints[name].found = found
                cachedPoints[name].type = type
            end
        end
    end
end

local function setAlignment(slot, alignment)
    local alignments = {
        center = {anchor = {0.5, 0.5}, align = {0.5, 0.5}, pos = {0, 0}},
        top = {anchor = {0.5, 0}, align = {0.5, 0}, pos = {0, 10}},
        bottom = {anchor = {0.5, 1}, align = {0.5, 1}, pos = {0, -10}},
        topleft = {anchor = {0, 0}, align = {0, 0}, pos = {10, 10}},
        topright = {anchor = {1, 0}, align = {1, 0}, pos = {-10, 10}},
        bottomleft = {anchor = {0, 1}, align = {0, 1}, pos = {10, -10}},
        bottomright = {anchor = {1, 1}, align = {1, 1}, pos = {-10, -10}}
    }
    local a = alignments[alignment] or alignments.center
    slot:SetAnchors({Minimum = {X = a.anchor[1], Y = a.anchor[2]}, Maximum = {X = a.anchor[1], Y = a.anchor[2]}})
    slot:SetAlignment({X = a.align[1], Y = a.align[2]})
    slot:SetPosition({X = a.pos[1], Y = a.pos[2]})
end

local function addPoint(layer, loc, color, size, name)
    local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), layer)
    local slot = layer:AddChildToCanvas(image)
    image:SetColorAndOpacity(color)
    image.Slot:SetPosition({X = loc.X - size/2, Y = loc.Y-size/2})
    image.Slot:SetSize({X = size, Y = size})
    image.Slot:SetZOrder(math.floor(loc.Z))
    return image
end

local function createBackgroundLayer(canvas)
    -- Create a clipping container to prevent map from showing outside bounds
    local clipBox = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), canvas, FName("MapClipBox"))
    local clipSlot = canvas:AddChildToCanvas(clipBox)
    clipSlot:SetSize(mapSize)
    clipSlot:SetPosition({X = 0, Y = 0})
    clipSlot:SetZOrder(-1000)
    
    -- Enable clipping on the container
    pcall(function()
        clipBox:SetClipping(1) -- 1 = ClipToBounds
    end)

    -- Create a container for the map background that can be rotated and scaled
    local bgContainer = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), clipBox, FName("MapBGContainer"))
    local containerSlot = clipBox:AddChildToCanvas(bgContainer)

    containerSlot:SetSize(mapSize)

    -- Center the container in the clip box
    containerSlot:SetPosition({X = 0, Y = 0})
    containerSlot:SetZOrder(0)

    -- Calculate tile size based on container
    local tileSize = mapSize.X / 2

    local pos = {{0,0},{1,0},{0,1},{1,1}}

    local templates = {
        "/Game/Blueprints/PlayerMap/Textures/T_Downscale%d.T_Downscale%d",
        "/Game/Blueprints/PlayerMap/Textures/T_SIUMapV7Q%d.T_SIUMapV7Q%d",
        "/PlayerMap/Textures/T_SupraworldMapV4Q%d.T_SupraworldMapV4Q%d",
    }

    for i = 1, 4 do
        for _,template in ipairs(templates) do
            local path = string.format(template, i-1, i-1)
            local texture = StaticFindObject(path)
            if texture and texture:IsValid() then
                print("Loaded " .. path)
                local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), bgContainer)
                local slot = bgContainer:AddChildToCanvas(image)
                image:SetBrushFromTexture(texture, false)

                -- image:SetColorAndOpacity({R = 0.05, G = 0.05, B = 0.05, A = 1.0})

                -- Position tile in grid (centered in the larger container)
                slot:SetPosition({X = pos[i][1] * tileSize, Y = pos[i][2] * tileSize})
                slot:SetSize({X = tileSize, Y = tileSize})
                slot:SetZOrder(-1000 + i)
                break
            end
        end
    end
    return bgContainer, clipBox
end

local function createMinimap()
    if mapWidget and mapWidget:IsValid() then
        print("Minimap already exists.")
        return
    end

    local gi = UEHelpers.GetGameInstance()
    local widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("mapWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("MinimapTree"))

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("MinimapCanvas"))
    widget.WidgetTree.RootWidget = canvas

    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("MinimapBG"))
    bg:SetBrushColor(FLinearColor(0.1, 0.1, 0.1, 0.5)) -- slight background

    local slot = canvas:AddChildToCanvas(bg)
    slot:SetSize(mapSize)
    setAlignment(slot, defaultAlignment)

    local layer = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), bg, FName("DotLayer"))
    bg:SetContent(layer)

    -- Create background layer with map tiles (now returns both bgContainer and clipBox)
    local bg1, clipBox = createBackgroundLayer(layer)

    updateCachedPoints()

    local count = 0
    local cx, cy = mapSize.X/2, mapSize.Y/2

    for name, point in pairs(cachedPoints) do
        point.image = addPoint(layer, {X=cx, Y=cy, Z=point.loc.Z}, FLinearColor(1,1,1,1), dotSize)
        count = count + 1
    end

    print("--- loaded", count, "points")

    playerImage = addPoint(layer, {X=cx, Y=cy, Z=0}, FLinearColor(1,1,1,1), playerDotSize+2)
    playerImage2 = addPoint(layer, {X=cx, Y=cy, Z=1}, FLinearColor(0,0,0,1), playerDotSize)

    bg:SetVisibility(VISIBLE)
    widget:SetVisibility(defaultVisibility)
    widget:AddToViewport(99)

    mapWidget = widget
    bgLayer = bg1
end

local function projectDot(w, h, scaling, camLoc, camRot, point, dotSize)
    dotSize = dotSize or 0
    local halfDot = dotSize / 2

    local yaw = math.rad(camRot.Yaw or 0)
    local cosY = math.cos(-yaw)
    local sinY = math.sin(-yaw)

    -- relative position to camera
    local dx = point.X - camLoc.X
    local dy = point.Y - camLoc.Y

    -- rotate around Z (yaw)
    local rx = dx * cosY - dy * sinY
    local ry = dx * sinY + dy * cosY

    -- map to widget coordinates
    local widgetX = w/2 + ry * scaling
    local widgetY = h/2 - rx * scaling

    -- circular clamp accounting for dot size
    local cx, cy = w/2, h/2
    local relX, relY = widgetX - cx, widgetY - cy
    local dist = math.sqrt(relX*relX + relY*relY)
    local radius = math.min(w, h) / 2 - halfDot
    if dist > radius then
        local scale = radius / dist
        relX = relX * scale
        relY = relY * scale
        widgetX = cx + relX
        widgetY = cy + relY
    end

    return widgetX, widgetY
end

local function updateMinimap(force)
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end

    local pc = getCameraController and getCameraController() or UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then
        local cam = pc.PlayerCameraManager
        if cam and cam:IsValid() then
            local loc = cam:GetCameraLocation()
            local rot = cam:GetCameraRotation()

            -- Rotate and scale background map
            if bgLayer and bgLayer:IsValid() then
                local mapBounds = FindFirstOf("PlayerMapActor_C")
                if mapBounds:IsValid() then
                    local scale = (scaling * mapBounds.MapWorldSize) / mapSize.X
                    local angle = -rot.Yaw + 270

                    local center = mapBounds.MapWorldCenter
                    local size = mapBounds.MapWorldSize
                    local dx = loc.X - center.X
                    local dy = loc.Y - center.Y
                    local pivotX = 0.5 + dx / size
                    local pivotY = 0.5 + dy / size

                    bgLayer:SetRenderTransformPivot({X = pivotX, Y = pivotY})

                    -- The pivot is in normalized coordinates (0-1), so we need to:
                    -- 1. Convert pivot position to pixels: pivotX * mapSize.X, pivotY * mapSize.Y
                    -- 2. Subtract half the widget size to center it: mapSize.X/2, mapSize.Y/2
                    -- 3. Negate because we're moving the map, not the viewport

                    local tx = mapSize.X * (0.5 - pivotX)
                    local ty = mapSize.Y * (0.5 - pivotY)

                    bgLayer:SetRenderTransform({
                        Translation = {X = tx, Y = ty}, 
                        Scale = {X = scale, Y = scale}, 
                        Shear = {X = 0, Y = 0}, 
                        Angle = angle
                    })
                end
            end

            for name, point in pairs(cachedPoints) do
                local px, py = projectDot(mapSize.X, mapSize.Y, scaling, loc, rot, point.loc, dotSize)
                if point.image and point.image:IsValid() then
                    point.image.Slot:SetPosition({X = px - dotSize / 2, Y = py - dotSize / 2})
                    point.image:SetColorAndOpacity(pointTypes[point.type][point.found and 2 or 1])
                end
            end

            if playerImage and playerImage:IsValid() then
                playerImage.Slot:SetZOrder(math.floor(loc.Z))
            end

            if playerImage2 and playerImage:IsValid() then
                playerImage2.Slot:SetZOrder(math.floor(loc.Z)+1)
            end

        end
    end

    ExecuteWithDelay(33,function()
        ExecuteInGameThread(updateMinimap)
    end)
end

local function toggleMinimap()
    if not mapWidget or not mapWidget:IsValid() then
        createMinimap()
    end

    local visible = mapWidget:GetVisibility()==VISIBLE
    mapWidget:SetVisibility(visible and HIDDEN or VISIBLE)
    if not visible then
        updateCachedPoints()
        updateMinimap()
    end
end

local function setFound(self, param, ...)
    local name = self:get():GetFullName()
    local found = param and param:get() or true
    local point = cachedPoints and cachedPoints[name]
    if point then
        point.found = found
    end
end

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(self, pawn)
    if pawn:get():GetFullName():find("DefaultPawn") then
        print("--- ignoring default pawn ---")
        return
    end

    createMinimap()
    updateMinimap()

    -- supraworld
    pcall(function()
        RegisterHook("/SupraCore/Systems/Volumes/SecretVolume.SecretVolume_C:SetSecretFound", setFound)
        RegisterHook("/Supraworld/Levelobjects/PickupBase.PickupBase_C:SetPickedUp", setFound)
        RegisterHook("/Supraworld/Systems/Shop/ShopItemSpawner.ShopItemSpawner_C:SetItemIsTaken", setFound)
    end)

    -- supraland
    pcall(function()
        RegisterHook("/Game/Blueprints/Levelobjects/SecretFound.SecretFound_C:Activate", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:Timeline_0__FinishedFunc", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/CoinBig.CoinBig_C:Timeline_0__FinishedFunc", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/CoinRed.CoinRed_C:Timeline_0__FinishedFunc", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:DestroyAllComponents", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/PhysicalCoin.PhysicalCoin_C:DestroyAllComponents", setFound)
    end)

    LoopAsync(60000, function()
        if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end
        ExecuteAsync(updateCachedPoints)
    end)

end)

RegisterKeyBind(Key.M, {ModifierKey.ALT}, toggleMinimap)

