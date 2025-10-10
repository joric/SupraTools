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

local textWidget = nil
local textControl = nil

local function FLinearColor(R,G,B,A) return {R=R,G=G,B=B,A=A} end
local function FSlateColor(R,G,B,A) return {SpecifiedColor=FLinearColor(R,G,B,A), ColorUseRule=0} end

local function hasFTextConstructor()
    local f = io.open("ue4ss/UE4SS_Signatures/FText_Constructor.lua", "r")
    if f then f:close() end
    return f ~= nil
end

local function createTextWidget(text, alignment)

    if not UnrealVersion:IsBelow(5, 4) and not hasFTextConstructor() then
        print("[SupraTools] ERROR!!! ue4ss/UE4SS_Signatures/FText_Constructor.lua is not found! Use this AOB: 40 53 57 48 83 EC 38 48 89 6C 24 ?? 48 8B FA 48 89 74 24 ?? 48 8B D9 33 F6 4C 89 74 24 30 ?? ?? ?? ?? ?? ?? ?? ?? 7F ?? E8 ?? ?? 00 00 48 8B F0")
        return
    end

    -- alignment: "center", "top", "bottom", "topleft", "topright", "bottomleft", "bottomright"
    alignment = alignment or "center"
    
    local gi = UEHelpers.GetGameInstance()
    hud = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("SimpleHUD"))
    hud.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), hud, FName("SimpleTree"))
    
    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), hud.WidgetTree, FName("SimpleCanvas"))
    hud.WidgetTree.RootWidget = canvas
    
    local border = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), canvas, FName("SimpleBorder"))
    border:SetBrushColor(FLinearColor(0, 0, 0, .5))
    border:SetPadding({Left = 20, Top = 10, Right = 20, Bottom = 10})
    
    local textBlock = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), border, FName("SimpleText"))

    textBlock.Font.Size = 20
    textBlock:SetText(FText(text))
    textBlock:SetColorAndOpacity(FSlateColor(1,1,1,1))
    textBlock:SetShadowOffset({X = 1, Y = 1})
    textBlock:SetShadowColorAndOpacity(FLinearColor(0, 0, 0, 0.75))

    border:SetContent(textBlock)

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
    
    canvas.Visibility = 4
    border.Visibility = 4
    textBlock.Visibility = 4
    
    hud:AddToViewport(99)

    textWidget = canvas
    textControl = textBlock

    print("added text", textWidget and textWidget:IsValid())
end


local function addText()
    ExecuteInGameThread(function()
        createTextWidget('SupraTools 1.0.3 by Joric\nF for Fast Travel on the Map\nMMB for Debug Camera\nLMB to Teleport\nAlt+F to Fill Suit\nAlt+P for Pickup\nAlt+I for Inventory\nAlt+H to Toggle Help', 'center')
    end)
end

local function setText(text)
    if not textControl then return end
    textControl:SetText(FText(text))
end

local function setTextVisibility(visibility)
    if not textWidget or not textWidget:IsValid() then return end
    textWidget:SetVisibility(visibility)
end

local function toggleText()
    if not textWidget or not textWidget:IsValid() then return end
    local current = textWidget:GetVisibility()
    setTextVisibility(current == Visibility_SELFHITTESTINVISIBLE and Visibility_HIDDEN or Visibility_SELFHITTESTINVISIBLE)
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    addText()
end)

RegisterKeyBind(Key.O, {ModifierKey.ALT}, toggleText) -- Onscreen Objectives, thus "O"
RegisterKeyBind(Key.H, {ModifierKey.ALT}, toggleText)
RegisterKeyBind(Key.D, {ModifierKey.ALT}, function() setText("Hello World!") end )

RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, function() setTextVisibility(Visibility_HIDDEN) end )
