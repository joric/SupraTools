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

    print('--- text client message ---')
    local pc = UEHelpers.GetPlayerController()
    pc:ClientMessage("Hello from ClientMessage", "None", 3.0)

    print('--- text ksl message ---')
    local ksl = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
    ksl:PrintString(nil, "Hello from PrintString", true, false, {R=0,G=255,B=0,A=255}, 5.0)

    print('--- text debug message ---')
    local engine = FindFirstOf("Engine")
    engine:AddOnScreenDebugMessage(-1, 5.0, {R=0,G=255,B=0,A=255}, "Hello from DebugMessage")

    print('--- text block ---')
    block:SetText(FText(text)) -- everything is valid but it crashes here

end

local function showText()
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            createTextWidget('Hello, World!')
        end)
    end)
end

RegisterKeyBind(Key.Z, {ModifierKey.ALT}, showText)
