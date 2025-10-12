local UEHelpers = require("UEHelpers")

--[[
The map refreshes MUCH FASTER with the recursive updateMinimap call but it prevents debugging the mods.
Recursive call wrapped with ExecuteAsync hangs on "stopping mod for uninstall" when you reload UE4SS.
Scheduled loops apparently cannot be easily stopped too, unless it's like 250ms loops, i.e. 4 FPS.
Even 100 ms loops also hang indefinitely with "stopping mod for uninstall" when you try to reload mods.
]]

local VISIBLE = 4
local HIDDEN = 2

local defaultVisibility = HIDDEN

local defaultAlignment = 'bottomleft'
local mapSize = {X=320, Y=320}
local scaling = 0.02
local dotSize = 3
local playerDotSize = 4

local cachedPoints

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local mapWidget = FindObject("UserWidget", "mapWidget")

local pointTypes = {
    -- supraworld
    SecretVolume_C = {FLinearColor(0, 1, 0, 0.75), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    RealCoinPickup_C = {FLinearColor(1,0.65,0,1),FLinearColor(1,0.65,0,0)},

    -- supraland
    SecretFound_C = {FLinearColor(0, 1, 0, 0.75), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    Coin_C = {FLinearColor(1,0.65,0,1),FLinearColor(1,0.65,0,0)}, -- why the fuck it crashes so much? too many objects?
    PhysicalCoin_C = {FLinearColor(1,0.65,0,1),FLinearColor(1,0.65,0,0)},
    CoinBig_C = {FLinearColor(1,0.65,0,1),FLinearColor(1,0.65,0,0)},
    CoinRed_C = {FLinearColor(1,0.65,0,1),FLinearColor(1,0.65,0,0)},
    -- Chest_C = {FLinearColor(1,0,0,1),FLinearColor(1,0,0,0)}, -- same as secret areas
}

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

local function addPoint(layer, x, y, color, size, name)
    local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), layer)
    local slot = layer:AddChildToCanvas(image)
    image:SetColorAndOpacity(color)
    image.Slot:SetPosition({X = x - size / 2, Y = y - size / 2})
    image.Slot:SetSize({X = size, Y = size})
    return image
end

local function updateCachedPoints()
    cachedPoints = cachedPoints or {}
    local coinLimit = 500
    for type, color in pairs(pointTypes) do
        for _, actor in ipairs(FindAllOf(type) or {}) do
            if not (type == "Coin_C" and coinLimit == 0) then
                if type=="Coin_C" then
                    coinLimit = coinLimit - 1
                end

                if actor:IsValid() then
                    local name = actor:GetFullName() -- we may need area/location in SIU
                    local found = (actor.bFound == true) or (actor.StartClosed == true)

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
end

local function createmapWidget()
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
    for name, point in pairs(cachedPoints) do
        point.image = addPoint(layer, point.loc.X, point.loc.Y, FLinearColor(1,1,1,0.75), dotSize)
        count = count + 1
    end

    print("--- loaded", count, "points")

    addPoint(layer, mapSize.X/2, mapSize.Y/2, FLinearColor(1,1,1,0.75), playerDotSize)

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

        end
    end

    --ExecuteAsync(updateMinimap) -- max fps but not recommended ? async loops leak memory
    --ExecuteWithDelay(16, updateMinimap) -- 60 fps
    ExecuteWithDelay(33, updateMinimap) -- 30 fps (may be optimal)
    --ExecuteWithDelay(250, updateMinimap) -- 4 fps, allows lua scripts reloading without widget hiding
end

local function toggleMinimap()
    if mapWidget then
        mapWidget:SetVisibility(mapWidget:GetVisibility()==VISIBLE and HIDDEN or VISIBLE)
        updateMinimap()
    end
end

local function setFound(self, param, ...)
    --local name = self:get():GetFName():ToString()
    local name = self:get():GetFullName()
    local found = param and param:get() or true
    print("--- setFound", found, name)
    local point = cachedPoints[name]
    if point then
        point.found = found
    end
end

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(self, pawn)
    if pawn:get():GetFullName():find("DefaultPawn") then
        print("--- ignoring default pawn ---")
        return
    end

    createmapWidget()
    updateMinimap()

    -- don't really need hooks if we do updateCached points on a timer

    --[[
    -- supraworld
    pcall(function()
        RegisterHook("/SupraCore/Systems/Volumes/SecretVolume.SecretVolume_C:SetSecretFound", setFound)
        RegisterHook("/Supraworld/Levelobjects/PickupBase.PickupBase_C:SetPickedUp", setFound)
    end)

    -- supraland
    pcall(function()
        RegisterHook("/Game/Blueprints/Levelobjects/SecretFound.SecretFound_C:Activate", setFound)
    end)

    -- nothing fires in this section. i'll deal with it later
    pcall(function()
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:Open", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:Open2", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:Activate", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:ActivateOpenForever", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/PhysicalCoin.PhysicalCoin_C:ActivateOpenForever", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:Toggle", setFound)
        RegisterHook("/Game/Blueprints/Levelobjects/Coin.Coin_C:appear", setFound)
    end)
    ]]

end)

if mapWidget and mapWidget:IsValid() then
    updateMinimap()
end

LoopAsync(2500, function()
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end
    updateCachedPoints()
end)

RegisterKeyBind(Key.M, {ModifierKey.ALT}, toggleMinimap)
