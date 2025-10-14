local UEHelpers = require("UEHelpers")

local VISIBLE = 4
local HIDDEN = 2

local defaultVisibility = HIDDEN

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local defaultAlignment = 'bottomleft'
local mapSize = {X=320, Y=320}
local scaling = 0.02
local dotSize = 3
local playerDotSize = 5
local cachedPoints = {}
local playerImage = nil
local playerImage2 = nil

local mapWidget = FindObject("UserWidget", "mapWidget")

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
    -- Chest_C = {FLinearColor(1,0,0,1),FLinearColor(1,0,0,0)}, -- same as secret areas
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
    image.Slot:SetPosition({X = loc.X-size/2, Y = loc.Y-size/2})
    image.Slot:SetSize({X = size, Y = size})
    image.Slot:SetZOrder(math.floor(loc.Z))
    return image
end

local function createMapWidget()
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
    bg:SetBrushColor(FLinearColor(0, 0, 0, 0))

    local slot = canvas:AddChildToCanvas(bg)
    slot:SetSize(mapSize)

    setAlignment(slot, defaultAlignment)

    local layer = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), bg, FName("DotLayer"))
    bg:SetContent(layer)

    updateCachedPoints()

    local count = 0
    local cx,cy = mapSize.X/2, mapSize.Y/2

    for name, point in pairs(cachedPoints) do
        point.image = addPoint(layer, {X=cx, Y=cy, Z=point.loc.Z}, FLinearColor(1,1,1,1), dotSize)
        count = count + 1
    end

    print("--- loaded", count, "points")

    playerImage = addPoint(layer, {X=cx, Y=cy, Z=0}, FLinearColor(1,1,1,.5), playerDotSize+2)
    playerImage2 = addPoint(layer, {X=cx, Y=cy, Z=1}, FLinearColor(0,0,0,1), playerDotSize)

    bg:SetVisibility(VISIBLE)
    widget:SetVisibility(defaultVisibility)
    widget:AddToViewport(99)

    mapWidget = widget
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
    local widgetX = w/2 + ry * scaling  -- UE Y = -widget X
    local widgetY = h/2 - rx * scaling  -- UE X = -widget Y

    -- circular clamp accounting for dot size
    local cx, cy = w/2, h/2
    local relX, relY = widgetX - cx, widgetY - cy
    local dist = math.sqrt(relX*relX + relY*relY)
    local radius = math.min(w, h) / 2 - halfDot  -- subtract half dot size
    if dist > radius then
        local scale = radius / dist
        relX = relX * scale
        relY = relY * scale
        widgetX = cx + relX
        widgetY = cy + relY
    end

    return widgetX, widgetY
end

local function updateMinimap()
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end

    local pc = getCameraController and getCameraController() or UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then
        local cam = pc.PlayerCameraManager
        if cam and cam:IsValid() then
            local loc = cam:GetCameraLocation()
            local rot = cam:GetCameraRotation()
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
        ExecuteInGameThread(updateMinimap) -- seems much more stable this way!
    end)
end

local function toggleMinimap()
    if not mapWidget or not mapWidget:IsValid() then
        createMapWidget()
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
            print("setFound", found, name:match(".*%.(.*)$"), "via", hook:match(".*%.(.*)$"))
        end
    end
end

local hooks = {
    -- supraworld
    { hook = "/SupraCore/Systems/Volumes/SecretVolume.SecretVolume_C:SetSecretFound", call = function(hook,name,param) setFound(hook,name,param) end },
    { hook = "/Supraworld/Levelobjects/PickupBase.PickupBase_C:SetPickedUp", call = function(hook,name,param) setFound(hook,name,param) end },
    { hook = "/Supraworld/Systems/Shop/ShopItemSpawner.ShopItemSpawner_C:SetItemIsTaken", call = function(hook,name,param) setFound(hook,name,param) end },
    -- supraland
    { hook = "/Game/Blueprints/Levelobjects/SecretFound.SecretFound_C:Activate" },
    { hook = "/Game/Blueprints/Levelobjects/Coin.Coin_C:Timeline_0__FinishedFunc" },
    { hook = "/Game/Blueprints/Levelobjects/CoinBig.CoinBig_C:Timeline_0__FinishedFunc" },
    { hook = "/Game/Blueprints/Levelobjects/CoinRed.CoinRed_C:Timeline_0__FinishedFunc" },
    { hook = "/Game/Blueprints/Levelobjects/Coin.Coin_C:DestroyAllComponents" },
    { hook = "/Game/Blueprints/Levelobjects/PhysicalCoin.PhysicalCoin_C:DestroyAllComponents" },
}

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(self, pawn)
    if pawn:get():GetFullName():find("DefaultPawn") then
        print("--- ignoring default pawn ---")
        return
    end

    createMapWidget()
    updateMinimap()

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
        print(ok and "REGISTERED" or "NOT FOUND", hook.hook)
    end

end)

if mapWidget and mapWidget:IsValid() then
    updateMinimap()
end

LoopAsync(60000, function()  -- let's see if hooks work
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end
    updateCachedPoints()
end)

RegisterKeyBind(Key.M, {ModifierKey.ALT}, toggleMinimap)

RegisterConsoleCommandHandler("minimap", function(FullCommand, Parameters, Ar)
    Ar:Log(supraToolsAttribution)
    Ar:Log("toggling minimap")
    toggleMinimap()
    return true
end)
