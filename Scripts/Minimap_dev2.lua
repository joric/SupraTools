-- map that uses 1:1 scaling and doesn't update point coordinates, just rotates the layer

local UEHelpers = require("UEHelpers")

local VISIBLE = 4
local HIDDEN = 2

local defaultVisibility = VISIBLE

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local defaultAlignment = 'center'
local mapSize = {X=400, Y=400}
local scaling = 0.01
local dotSize = 1000 * scaling
local playerDotSize = 1000 * scaling
local cachedPoints = nil

local mapWidget = FindObject("UserWidget", "mapWidget")

local pointTypes = {
    -- supraworld
    --SecretVolume_C = {FLinearColor(0,1,0,1), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    --RealCoinPickup_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    -- PresentBox_Lootpools_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    --ItemSpawner_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    -- PresentBox_C = {FLinearColor(1,0,0,1),FLinearColor(0,0,0,0)},
    PickupSpawner_C = {FLinearColor(0,0,1,1),FLinearColor(0,0,0,0)},

    -- supraland
    -- SecretFound_C = {FLinearColor(0,1,0,1), FLinearColor(0.5, 0.5, 0.5, 0.5)},
    -- Coin_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    -- PhysicalCoin_C = {FLinearColor(1,0.65,0,1),FLinearColor(0,0,0,0)},
    -- CoinBig_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
    -- CoinRed_C = {FLinearColor(1,0.5,0,1),FLinearColor(0,0,0,0)},
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
    image.Slot:SetPosition({X = loc.X*scaling  -size/2, Y = loc.Y*scaling - size/2})
    image.Slot:SetSize({X = size, Y = size})
    image.Slot:SetZOrder(math.floor(loc.Z))
    return image
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
    bg:SetBrushColor(FLinearColor(0, 0, 0, 0.1))

    local slot = canvas0:AddChildToCanvas(bg)
    slot:SetSize(mapSize)
    setAlignment(slot, defaultAlignment)

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), bg, FName("MapBaseCanvas"))
    bg:SetContent(canvas)

    local clipBox = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), canvas, FName("MapClipBox"))
    local clipSlot = canvas:AddChildToCanvas(clipBox)
    clipSlot:SetSize(mapSize)
    clipSlot:SetPosition({X = 0, Y = 0})
    clipSlot:SetZOrder(-1000)
    
    -- Enable clipping on the container
    pcall(function()
        -- clipBox:SetClipping(1) -- 1 = ClipToBounds
    end)

    -- Create a container for the map background that can be rotated and scaled
    local bgContainer = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), clipBox, FName("DotLayer"))
    local containerSlot = clipBox:AddChildToCanvas(bgContainer)

    containerSlot:SetSize(mapSize)

    -- Center the container in the clip box
    containerSlot:SetPosition({X = 0, Y = 0})
    containerSlot:SetZOrder(0)

    layer = bgContainer


    updateCachedPoints()

    for name, point in pairs(cachedPoints) do
        local color = pointTypes[point.type][point.found and 2 or 1]

        if name == 'PickupSpawner_C /Supraworld/Maps/Supraworld.Supraworld:PersistentLevel.PickupSpawner_C_UAID_FC3497C34610064D02_1268637352' then
            color=FLinearColor(1,0,0,1)
        end

        --print("--- ADDING", name)
        addPoint(layer, point.loc, color, dotSize, name .. ".Dot")
    end

    -- addPoint(layer, {X=0, Y=0, Z=0}, FLinearColor(1,1,1,.5), playerDotSize+2, "playerImage")
    -- addPoint(layer, {X=0, Y=0, Z=1}, FLinearColor(0,0,0,1), playerDotSize, "playerImage2")

    addPoint(layer, {X=0, Y=0, Z=0}, FLinearColor(0,0,0,0.5), playerDotSize, "playerImage")
    addPoint(layer, {X=0, Y=0, Z=0}, FLinearColor(1,1,1,0.5), playerDotSize, "centerDot")

    bg:SetVisibility(VISIBLE)
    widget:SetVisibility(defaultVisibility)
    widget:AddToViewport(99)

    mapWidget = widget
end

local function updateMinimap()
    if not mapWidget or not mapWidget:IsValid() or mapWidget:GetVisibility()==HIDDEN then return end

    local bgLayer = FindObject("CanvasPanel", "DotLayer")

    local pc = getCameraController and getCameraController() or UEHelpers.GetPlayerController()

    local clipBox = FindObject("CanvasPanel", "MapClipBox")

    pcall(function()
        clipBox:SetClipping(1) -- 1 = ClipToBounds
    end)


--------------------------------------

if pc and pc:IsValid() then
    local cam = pc.PlayerCameraManager
    if cam and cam:IsValid() then
        local loc = cam:GetCameraLocation()
        local rot = cam:GetCameraRotation()

        local size = mapSize.X

        local scale = 1
        local angle = -rot.Yaw + 270

        local cx = loc.X*scaling
        local cy = loc.Y*scaling

        local u = cx / size
        local v = cy / size

        bgLayer:SetRenderTransformPivot({X = u, Y = v})

        local tx = size * (0.5 - u)
        local ty = size * (0.5 - v)

        --tx = 0
        --ty = 0

        bgLayer:SetRenderTransform({
            Translation = {X = tx, Y = ty},
            Scale = {X = scale, Y = scale},
            Shear = {X = 0, Y = 0}, 
            Angle = angle
        })


        local playerImage = FindObject("Image", "playerImage")
        if playerImage and playerImage:IsValid() then
            playerImage.Slot:SetPosition({X = loc.X*scaling - playerDotSize/2, Y = loc.Y*scaling - playerDotSize/2})
            playerImage.Slot:SetZOrder(math.floor(loc.Z))
        end

    end
end

-------------------------------------------


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
                    print("removing point", image:GetFullName())
                    image:RemoveFromParent()
                end
            end

        end
    end
end

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
}

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(self, pawn)
    if pawn:get():GetFullName():find("DefaultPawn") then
        print("--- ignoring default pawn ---")
        return
    end

    createMinimap()
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

    --RegisterHook("/Game/FirstPersonBP/Blueprints/CharacterTextHUD.CharacterTextHUD_C:Tick", function() --works when you talk to characters
    RegisterHook("/Game/FirstPersonBP/Blueprints/HintText.HintText_C:Tick", function() -- works when there's a hint text on screen
        updateMinimap()
        return true
    end)


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

pcall(function()
    --RegisterHook("/Game/FirstPersonBP/Blueprints/CharacterTextHUD.CharacterTextHUD_C:Tick", function() --works when you talk to characters
    RegisterHook("/Game/FirstPersonBP/Blueprints/HintText.HintText_C:Tick", function() -- works when there's a hint text on screen
        updateMinimap()
        return true
    end)
end)
