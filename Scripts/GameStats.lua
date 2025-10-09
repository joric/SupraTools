local UEHelpers = require("UEHelpers")

-- experimental, under construction

local function createTextWidget(text)
    local gi = UEHelpers.GetGameInstance()

    local hud = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), gi, FName("HUDWidget"))
    hud.WidgetTree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), hud, FName("HUDWidgetTree"))

    local canvas = StaticConstructObject(StaticFindObject("/Script/UMG.CanvasPanel"), hud.WidgetTree, FName("HUDCanvas"))
    hud.WidgetTree.RootWidget = canvas

    local vbox = StaticConstructObject(StaticFindObject("/Script/UMG.VerticalBox"), canvas, FName("HUDVBox"))
    local block = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), vbox, FName("MyTextBlock"))

    vbox:AddChildToVerticalBox(block)

    hud:SetVisibility(0)
    hud:AddToViewport(10000)

    print("adding text")
    block:SetText(FText(text))

end

local function showText()
    ExecuteInGameThread(function()
        createTextWidget('Hello, World!')
    end)
end

RegisterKeyBind(Key.O, {ModifierKey.ALT}, showText) -- Onscreen Objectives, thus "O"

-- RegisterKeyBind(Key.D, {ModifierKey.ALT}, showText) -- debug

--[[
-- added this to ue4ss\UE4SS_Signatures\FText_Constructor.lua
function Register()
    return "40 53 57 48 83 EC 38 48 89 6C 24 ?? 48 8B FA 48 89 74 24 ?? 48 8B D9 33 F6 4C 89 74 24 30 ?? ?? ?? ?? ?? ?? ?? ?? 7F ?? E8 ?? ?? 00 00 48 8B F0"
end
function OnMatchFound(MatchAddress)
    return MatchAddress
end
]]

RegisterHook("/Script/UMG.TextBlock:SetText", function(Context, InText)
  -- Context:get():SetText(FText("Hello!")) -- stack overflow (probably recursion)
  -- print(FText("Hello"):ToString()) -- this doesn't crash now
  -- print("SetText", InText:get(), Context:get():GetFName():ToString()) -- prints FText: 000002B1B8086268 ReasonTextWidget
  -- InText:Set(FText("Hello!")) -- does not crash but doesn't change text either
  -- print("TextContent", InText:get():ToString()) -- still crashes if InText is not set in a line above
end)

