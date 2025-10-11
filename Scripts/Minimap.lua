local UEHelpers = require("UEHelpers")

local VISIBLE = 4
local HIDDEN = 2

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local defaultVisibility = HIDDEN
local mapSize = {X=300, Y=300}
local dotSize = 6
local cachedWidget = nil
local cachedLayer = nil

local function getMinimapWidget()
    if cachedWidget and cachedWidget:IsValid() then return cachedWidget end
    local obj = FindObject("UserWidget", "MinimapWidget")
    if obj and obj:IsValid() then
        cachedWidget = obj
        return obj
    end
end

local function getDotLayer()
    if cachedLayer and cachedLayer:IsValid() then return cachedLayer end
    local obj = FindObject("CanvasPanel", "DotLayer")
    if obj and obj:IsValid() then
        cachedLayer = obj
        return obj
    end
end

local function hideMinimap()
    local obj = getMinimapWidget()
    if obj then
        defaultVisibility = HIDDEN
        obj:SetVisibility(defaultVisibility)
    end
end

local function setAlignment(slot, alignment)
    -- Alignment presets
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

------------------------------------

local minimapDots = {}
local playerSlot = nil

-- helper: return table of all valid secrets with current coordinates and found state
local function getSecretsData()
    local data = {}
    local entries = {"SecretVolume_C", "SecretFound_C"}
    for _, entry in ipairs(entries) do
        for _, actor in ipairs(FindAllOf(entry) or {}) do
            if actor and actor:IsValid() then
                local loc = actor:K2_GetActorLocation()
                local found = (actor.bFound == true) or (actor.StartClosed == true)
                table.insert(data, {loc = loc, found = found})
            end
        end
    end
    return data
end

local function project(w, h, scaling, camLoc, camRot, point, dotSize)
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
    local widgetX = w/2 + ry * scaling  -- UE Y → widget X
    local widgetY = h/2 - rx * scaling  -- UE X → widget Y

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

    return widgetX-5, widgetY-5 --account for slot border
end

-- main update function
local function updateMinimap()

    local widget = getMinimapWidget()
    if not widget then return end

    if widget:GetVisibility()==HIDDEN then
        return -- do not update if invisible
    end

    local dotLayer = getDotLayer()
    if not dotLayer then return end

    local w, h = mapSize.X, mapSize.Y

    local scaling = 0.01

    local pc = getCameraController()
    if not pc or not pc:IsValid() then return end
    local cam = pc.PlayerCameraManager
    if not cam or not cam:IsValid() then return end

    local loc = cam:GetCameraLocation()
    local rot = cam:GetCameraRotation()

    local secretsData = getSecretsData()

    -- create dot widgets if needed
    if #minimapDots < #secretsData then
        for i = #minimapDots + 1, #secretsData do
            local dot = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), dotLayer, FName("SecretDot"..i))
            dot:SetBrushFromTexture(nil, false)
            local slot = dotLayer:AddChildToCanvas(dot)
            slot:SetSize({X = dotSize, Y = dotSize})
            minimapDots[i] = {dot = dot, slot = slot}
        end
    end

    -- update each dot
    for i, s in ipairs(secretsData) do
        local d = minimapDots[i]
        if d and d.dot and d.slot then

            local px, py = project(w,h, scaling, loc, rot, s.loc, dotSize)

            if px >= 0 and px <= w and py >= 0 and py <= h then
                d.slot:SetPosition({X = px - dotSize / 2, Y = py - dotSize / 2})
                d.dot:SetColorAndOpacity(s.found and FLinearColor(0.5, 0.5, 0.5, 0.9) or FLinearColor(1, 0, 0, 0.95))
                -- d.dot:SetVisibility(VISIBLE)
            else
                -- d.dot:SetVisibility(HIDDEN)
            end

        end
    end

    ExecuteAsync(updateMinimap)
end

local function toggleMinimap()
    local obj = getMinimapWidget()
    if obj then
        defaultVisibility = obj:GetVisibility()==VISIBLE and HIDDEN or VISIBLE
        obj:SetVisibility(defaultVisibility)
        updateMinimap()
    end
end

------------------------------------

local function addDot(dotLayer, x, y, color)
    local dotSize = 6
    local dot = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), dotLayer, FName("PlayerDot"))
    dot:SetColorAndOpacity(color)
    local slot = dotLayer:AddChildToCanvas(dot)
    slot:SetSize({X = dotSize, Y = dotSize})
    slot:SetPosition({X=x, Y=y})
end

local function createMinimapWidget()
    if getMinimapWidget() then return end

    local gi = UEHelpers.GetGameInstance()
    local widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("MinimapWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("MinimapTree"))

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("MinimapCanvas"))
    widget.WidgetTree.RootWidget = canvas

    -- background
    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("MinimapBG"))
    bg:SetBrushColor(FLinearColor(0, 0, 0, 0.25))

    local slot = canvas:AddChildToCanvas(bg)
    slot:SetAnchors({Minimum={X=0.85,Y=0.05},Maximum={X=0.85,Y=0.05}})
    slot:SetSize(mapSize)
    slot:SetAlignment({X=0.5,Y=0})
    slot:SetPosition({X=0,Y=0})

    setAlignment(slot, 'bottomleft')

    -- container for dots
    local dotLayer = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), bg, FName("DotLayer"))
    bg:SetContent(dotLayer)

    bg:SetVisibility(VISIBLE)
    dotLayer:SetVisibility(VISIBLE)
    widget:SetVisibility(defaultVisibility)

    widget:AddToViewport(99)

    addDot(dotLayer, mapSize.X/2 - dotSize/2, mapSize.Y/2 - dotSize/2, FLinearColor(0,1,0,1));

    print("### CREATED MINIMAP ###")

    minimapDots = {}
    cachedWidget = nil
    cachedLayer = nil

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            updateMinimap()
        end)
    end)
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    createMinimapWidget()
end)

RegisterKeyBind(Key.M, {ModifierKey.ALT}, toggleMinimap)

