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
local dotSize = 4

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local mapWidget = FindObject("UserWidget", "mapWidget")

local function toggleMinimap()
    if mapWidget then
        mapWidget:SetVisibility(mapWidget:GetVisibility()==VISIBLE and HIDDEN or VISIBLE)
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

local function addDot(layer, x, y, color, size, name)
    local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), layer)
    local slot = layer:AddChildToCanvas(image)
    image:SetColorAndOpacity(color)
    image.Slot:SetPosition({X = x - size / 2, Y = y - size / 2})
    image.Slot:SetSize({X = size, Y = size})
    return image
end

local function getSecretsData()
    local data = {}
    local items = {
        SecretVolume_C = FLinearColor(0, 1, 0, 0.75),
        SecretFound_C = FLinearColor(0, 1, 0, 0.75),
        -- RealCoinPickup_C = FLinearColor(1,0.65,0,1),
        -- Coin_C = FLinearColor(1,0.65,0,1), -- too many items
    }

    for name, color in pairs(items) do
        for _, actor in ipairs(FindAllOf(name) or {}) do
            if actor and actor:IsValid() then
                local loc = actor:K2_GetActorLocation()
                local found = (actor.bFound == true) or (actor.StartClosed == true)
                table.insert(data, {loc=loc, found=found, color=color})
            end
        end
    end
    return data
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

    local secretsData = getSecretsData()

    for i, pt in ipairs(secretsData) do
        addDot(layer, pt.loc.X, pt.loc.Y, FLinearColor(1,1,1,0.75), dotSize)
    end

    addDot(layer, mapSize.X/2, mapSize.Y/2, FLinearColor(1,1,1,0.75), dotSize)

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
    local w, h = mapSize.X, mapSize.Y
    local scaling = 0.01

    if not mapWidget or not mapWidget:IsValid() then return end

    local pc = getCameraController and getCameraController() or UEHelpers.GetPlayerController()
    if pc and pc:IsValid() then
        local cam = pc.PlayerCameraManager
        if cam and cam:IsValid() then
            local loc = cam:GetCameraLocation()
            local rot = cam:GetCameraRotation()

            local secretsData = getSecretsData()
            for i, pt in ipairs(secretsData) do
                local px, py = projectDot(w,h, scaling, loc, rot, pt.loc, dotSize)
                local image = mapWidget.WidgetTree.RootWidget:GetChildAt(0):GetContent():GetChildAt(i-1)
                if image:IsValid() then
                    -- image:SetColorAndOpacity(FLinearColor(pt.color.R, pt.color.G, pt.color.B, pt.found and 0.25 or 0.95)) -- clusters are too opaque
                    image:SetColorAndOpacity(pt.found and FLinearColor(0.5,0.5,0.5,0.5) or pt.color)
                    image.Slot:SetPosition({X = px - dotSize / 2, Y = py - dotSize / 2})
                end
            end
        end
    end

    -- ExecuteAsync(updateMinimap) -- mods cannot be reloaded with that, hang on "stopping for uninstall"
end

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(self, pawn)
    if pawn:get():GetFullName():find("DefaultPawn") then
        print("--- ignoring default pawn ---")
        return
    end
    createmapWidget()
end)

if mapWidget and mapWidget:IsValid() then
    updateMinimap()
end

LoopAsync(250, updateMinimap) -- 250 ms because even 100 ms loop hangs mod reload indefinitely

RegisterKeyBind(Key.M, {ModifierKey.ALT}, toggleMinimap)
