local UEHelpers = require("UEHelpers")

-- experimental, under construction

--[[
For FText to work in UE5.4+, add this to ue4ss/UE4SS_Signatures/FText_Constructor.lua:

function Register()
    return "40 53 57 48 83 EC 38 48 89 6C 24 ?? 48 8B FA 48 89 74 24 ?? 48 8B D9 33 F6 4C 89 74 24 30 ?? ?? ?? ?? ?? ?? ?? ?? 7F ?? E8 ?? ?? 00 00 48 8B F0"
end

function OnMatchFound(MatchAddress)
    return MatchAddress
end

]]

local Visibility_VISIBLE = 0
local Visibility_COLLAPSED = 1
local Visibility_HIDDEN = 2
local Visibility_HITTESTINVISIBLE = 3
local Visibility_SELFHITTESTINVISIBLE = 4
local Visibility_ALL = 5

local widgetVisibilityMode = 4

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local function getBlock()
    local obj = FindObject("TextBlock", "SimpleText")
    if obj and obj:IsValid() then
        return obj
    end
end

local function getWidget()
    local obj = FindObject("UserWidget", "SimpleWidget")
    if obj and obj:IsValid() then
        return obj
    end
end

local function setText(text)
    local block = getBlock()
    if block then
        block:SetText(FText(text))
    end
end

local function getVisibility()
    local widget = getWidget()
    if widget then
        return widget:GetVisibility()~=Visibility_HIDDEN
    end
end

local function setVisibility(visible)
    local widget = getWidget()
    if widget then
        widget:SetVisibility(visible and widgetVisibilityMode or Visibility_HIDDEN)
    end
end

local function showWidget() setVisibility(true) end
local function hideWidget() setVisibility(false) end
local function toggleWidget() setVisibility(not getVisibility()) end

local function hasFTextConstructor()
    local f = io.open("ue4ss/UE4SS_Signatures/FText_Constructor.lua", "r")
    if f then f:close() end
    return f ~= nil
end

local textWidget = nil

local function createWidget(alignment)
    if getWidget() then return end

    if not UnrealVersion:IsBelow(5, 4) and not hasFTextConstructor() then
        print("ERROR!!! ue4ss/UE4SS_Signatures/FText_Constructor.lua is not found! Use this AOB: 40 53 57 48 83 EC 38 48 89 6C 24 ?? 48 8B FA 48 89 74 24 ?? 48 8B D9 33 F6 4C 89 74 24 30 ?? ?? ?? ?? ?? ?? ?? ?? 7F ?? E8 ?? ?? 00 00 48 8B F0")
        return
    end

    alignment = alignment or "center" -- "center", "top", "bottom", "topleft", "topright", "bottomleft", "bottomright"

    local gi = UEHelpers.GetGameInstance()
    widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("SimpleWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("SimpleTree"))

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("SimpleCanvas"))
    widget.WidgetTree.RootWidget = canvas

    local border = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("SimpleBorder"))
    border:SetBrushColor(FLinearColor(0, 0, 0, .5))
    border:SetPadding({Left = 15, Top = 10, Right = 15, Bottom = 10})

    local block = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), border, FName("SimpleText"))
    block.Font.Size = 24
    block:SetColorAndOpacity(FSlateColor(1,1,1,1))
    block:SetShadowOffset({X = 1, Y = 1})
    block:SetShadowColorAndOpacity(FLinearColor(0, 0, 0, 0.75))
    block:SetText(FText('Hello World!'))

    border:SetContent(block)

    local slot = canvas:AddChildToCanvas(border)
    slot:SetAutoSize(true)

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

    widget:AddToViewport(99)

    widget:SetVisibility(widgetVisibilityMode)
end

-- either show stats or help because we only have 1 widget
-- set to false on help because callback function overrides stats
showStats = false

local helpText = [[SupraTools 1.0.3 by Joric
F for Fast Travel (Map)
Alt+E for Remote Control
MMB for Debug Camera
LMB to Teleport
Alt+P to Pickup All
Alt+I to Equip All
Alt+F to Fill Suit
Alt+Z/X/C/V to Edit
Alt+O to Toggle Stats
Alt+H to Toggle Help]]

local function toggleHelp()
    showStats = false
    setText(helpText)
    toggleWidget()
end

function distance(p1, p2)
    local dx = p2.X - p1.X
    local dy = p2.Y - p1.Y
    local dz = p2.Z - p1.Z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function getStats()
    local total = 0
    local found = 0

    local minDist = 1000000

    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then return end

    local ploc = pc.Pawn:K2_GetActorLocation()

    for _, actor in ipairs(FindAllOf("SecretVolume_C") or {}) do
        if actor:IsValid() then
            total = total + 1

            if actor.bFound then
                found = found + 1
            else
                local loc = actor:K2_GetActorLocation()
                local dist = distance(ploc, loc)
                if dist<minDist then
                    minDist = dist
                end
            end

        end
    end

    -- supraland volumes don't seen to work.
    -- SecretFound_C has "Active?" field but they are all true
    -- investigate why it doesn't work, e.g.
    -- SecretFound5_2279 -- activated
    -- SecretFound4_1232 -- not activated
    -- probably supraland uses global log called ThingsToActivate
    -- maybe it's on the collision box
    --[[
    local total=0
    local found=0
    for _, actor in ipairs(FindAllOf("SecretFound_C") or {}) do
        if actor:IsValid() then
            total = total + 1

            if actor:GetPropertyValue("Active?") then -- always true 
                found = found + 1
            end

            local name = actor:GetFName():ToString()
            if name=='SecretFound5_2279' or name=='SecretFound4_1232' then
                -- investigated actor.Box:GetCollisionEnabled() -- nope
                -- probably internal game variable, that sucks
            end
        end
    end
    ]]


    if total==found then
        minDist = 0
    end

    return(string.format("Secrets found: %d of %d\nClosest: %.1f m", found, total, minDist/1000))
end

local function toggleStats()
    setText(getStats())
    toggleWidget()
    showStats = true
end

local function updateStats()
    if not showStats then return end
    setText(getStats())
end

function checkObject()
    local actor = getCameraHitObject()
    if not actor or not actor:IsValid() then return end
    setText(actor:GetOuter():GetFullName())
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    createWidget('topleft')
    setText(helpText)

    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            -- LoopAsync(250, checkObject) -- crashes!
            LoopAsync(1000, updateStats)
        end)
    end)

end)

RegisterKeyBind(Key.O, {ModifierKey.ALT}, toggleStats ) -- Onscreen Objectives, thus "O"
RegisterKeyBind(Key.H, {ModifierKey.ALT}, toggleHelp)

-- RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, hideWidget) -- fires too early
-- RegisterKeyBind(Key.W, hideWidget)
-- RegisterKeyBind(Key.A, hideWidget)
-- RegisterKeyBind(Key.S, hideWidget)
-- RegisterKeyBind(Key.D, hideWidget)


--/SupraworldMenu/UI/Menu/W_SupraPauseMenu.W_SupraPauseMenu_C:CloseMenu Self: W_SupraPauseMenu_C_2147469280
--/Script/LyraGame.LyraHUDLayout:HandleEscapeAction Self:


-- search functions/scripts in Live View substring, e.g. W_SupraPauseMenu_C:CloseMenu

local function onMenuClose(self, ...)
    hideWidget()
end

local function onMenuOpen(self, ...)
    setText(getStats())
    showStats = true
    showWidget()
    -- hook to closemenu here
    pcall(function()RegisterHook("/SupraworldMenu/UI/Menu/W_SupraPauseMenu.W_SupraPauseMenu_C:CloseMenu", onMenuClose)end)
end

-- Hooks table: hook path + optional call function, use LiveView search :FunctionName to find hooks
local hooks = {
    { hook = "/Script/LyraGame.LyraHUDLayout:HandleEscapeAction", call = onMenuOpen },
    { hook = "/SupraworldMenu/UI/Menu/W_SupraPauseMenu.W_SupraPauseMenu_C:CloseMenu", call = onMenuClose }, -- only fires when hooked later?
    { hook = "/Script/Engine.Controller:Possess" },
}

for _, entry in ipairs(hooks) do
    local ok, err = pcall(function()
        RegisterHook(entry.hook, function(self, ...)
            local fname = self:get():GetFName():ToString()
            print("Hook fired:", entry.hook, "Self:", fname)
            if entry.call then
                entry.call(self, ...)
            end
        end)
    end)
    if not ok then
        print("Warning: Could not register hook for", entry.hook)
    end
end
