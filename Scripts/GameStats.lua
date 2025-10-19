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

local helpText = [[
SupraTools 1.0.3 by Joric
F for Fast Travel
Alt+E for Remote Control
MMB for Debug Camera
LMB to Teleport
Alt+P to Pickup All
Alt+I to Equip All
Alt+F to Fill Suit
Alt+Z/X/C/V to Edit
Alt+M to Toggle Minimap
Alt+O to Toggle Stats
Alt+H to Toggle Help
]]

useStats = false

local VISIBLE = 4
local HIDDEN = 2

local statsWidget = FindObject("UserWidget", "StatsWidget")
local textBlock = FindObject("TextBlock", "StatsTextBlock")

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local function setText(text)
    if textBlock and textBlock:IsValid() then
        textBlock:SetText(FText(text))
    end
end

local function getVisibility()
    if statsWidget and statsWidget:IsValid() then
        return statsWidget:GetVisibility() ~= HIDDEN
    end
end

local function setVisibility(visible)
    if statsWidget and statsWidget:IsValid() then
        statsWidget:SetVisibility(visible and VISIBLE or HIDDEN)
    end
end

local function showWidget() setVisibility(true) end
local function hideWidget() if not useStats then setVisibility(false) end end -- do not hide stats
local function toggleWidget() setVisibility(not getVisibility()) end

local function hasFTextConstructor()
    local f = io.open("ue4ss/UE4SS_Signatures/FText_Constructor.lua", "r")
    if f then f:close() end
    return f ~= nil
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

local function createTextWidget()
    useStats = false

    if statsWidget and statsWidget:IsValid() then
        statsWidget:RemoveFromParent()
        statsWidget:ConditionalBeginDestroy()
        statsWidget = nil
    end

    print("#### CREATING STATS ####")

    if not UnrealVersion:IsBelow(5, 4) and not hasFTextConstructor() then
        print("ERROR!!! ue4ss/UE4SS_Signatures/FText_Constructor.lua is not found!")
        return
    end

    local gi = UEHelpers.GetGameInstance()
    widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("StatsWidget"))
    widget.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget, FName("StatsSimpleTree"))

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), widget.WidgetTree, FName("StatsCanvas"))
    widget.WidgetTree.RootWidget = canvas

    local bg = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("StatsBG"))
    bg:SetBrushColor(FLinearColor(0, 0, 0, 0.25))
    bg:SetPadding({Left = 15, Top = 10, Right = 15, Bottom = 10})

    local text = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), bg, FName("StatsTextBlock"))
    text.Font.Size = 24
    text:SetColorAndOpacity(FSlateColor(1,1,1,1))
    text:SetShadowOffset({X = 1, Y = 1})
    text:SetShadowColorAndOpacity(FLinearColor(0,0,0,0.5))
    text:SetText(FText('Hello World!'))

    bg:SetContent(text)

    local slot = canvas:AddChildToCanvas(bg)
    slot:SetAutoSize(true)

    setAlignment(slot, alignment or "topleft")

    bg:SetVisibility(VISIBLE)
    text:SetVisibility(VISIBLE)
    widget:SetVisibility(VISIBLE)

    widget:AddToViewport(9999)

    statsWidget = widget
    textBlock = text

    print("stats created", statsWidget:GetFullName(), textBlock:GetFullName())
end

local function toggleHelp()
    useStats = false
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

    local pc = getCameraController()
    if not pc or not pc:IsValid() then return end

    local ploc = pc.PlayerCameraManager:GetCameraLocation()

    local entries = {"SecretVolume_C", "SecretFound_C"};

    -- print("--- updating stats ---")

    for _, entry in ipairs(entries) do

        for _, actor in ipairs(FindAllOf(entry) or {}) do
            if actor:IsValid() then
                total = total + 1

                -- local name = actor:GetFName():ToString()
                -- print(actor.StartClosed, name)

                if actor.bFound==true or actor.StartClosed==true then
                    found = found + 1
                else

                    -- not found, check coordinates
                    local loc = actor:K2_GetActorLocation()
                    local dist = distance(ploc, loc)
                    if dist<minDist then
                        minDist = dist
                    end
                end

            end
        end
    end

    if total==found then
        minDist = 0
    end

    local res = string.format("Secrets found: %d of %d\nClosest: %.1f m", found, total, minDist/1000)

    -- print(res)


    return(res)
end

local function toggleStats()
    setText(getStats())
    toggleWidget()
    useStats = true
end

local function updateStats()
    if not getVisibility() then return end
    if not useStats then return end
    setText(getStats())
end

--/SupraworldMenu/UI/Menu/W_SupraPauseMenu.W_SupraPauseMenu_C:CloseMenu Self: W_SupraPauseMenu_C_2147469280
--/Script/LyraGame.LyraHUDLayout:HandleEscapeAction Self:

-- search functions/scripts in Live View substring, e.g. W_SupraPauseMenu_C:CloseMenu

local function onMenuClose(self, ...)
    --hideWidget()
end

local function onMenuOpen(self, ...)
    --setText(getStats())
    --useStats = true
    --showWidget()
    -- hook to closemenu here
--    pcall(function()RegisterHook("/SupraworldMenu/UI/Menu/W_SupraPauseMenu.W_SupraPauseMenu_C:CloseMenu", onMenuClose)end)
end

-- Hooks table: hook path + optional call function, use LiveView search :FunctionName to find hooks
local hooks = {
    --{ hook = "/Script/LyraGame.LyraHUDLayout:HandleEscapeAction", call = onMenuOpen },
    --{ hook = "/SupraworldMenu/UI/Menu/W_SupraPauseMenu.W_SupraPauseMenu_C:CloseMenu", call = onMenuClose }, -- only fires when hooked later?
    --{ hook = "/Script/Engine.Controller:Possess" }, -- not firing
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

RegisterHook("/Script/Engine.PlayerController:ServerAcknowledgePossession", function(self, pawn)
    if pawn:get():GetFullName():find("DefaultPawn") then
        print("--- ignoring default pawn ---")
        return
    end

    ExecuteWithDelay(2000, function()
        createTextWidget()
        setText(helpText)
    end)
end)

LoopAsync(1000, updateStats)

RegisterKeyBind(Key.O, {ModifierKey.ALT}, toggleStats ) -- Onscreen Objectives, thus "O"
RegisterKeyBind(Key.H, {ModifierKey.ALT}, toggleHelp)

RegisterKeyBind(Key.W, hideWidget)
RegisterKeyBind(Key.A, hideWidget)
RegisterKeyBind(Key.S, hideWidget)
RegisterKeyBind(Key.D, hideWidget)


