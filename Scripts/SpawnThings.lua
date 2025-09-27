local UEHelpers = require("UEHelpers")

local SAVE_FILE = "ue4ss/Mods/SupraTools/Scripts/SpawnThings.txt"

-- Unified log of all actions
local actions = {}

-- ==============================================================
-- Utility
-- ==============================================================

local function serializeTransform(loc, rot, scale)
    return string.format("%f,%f,%f;%f,%f,%f;%f,%f,%f",
        loc.X, loc.Y, loc.Z,
        rot.Pitch, rot.Yaw, rot.Roll,
        scale.X, scale.Y, scale.Z)
end

local function deserializeTransform(str)
    local lx,ly,lz, p,y,r, sx,sy,sz =
        str:match("([^,;]+),([^,;]+),([^,;]+);([^,;]+),([^,;]+),([^,;]+);([^,;]+),([^,;]+),([^,;]+)")
    return {
        loc   = {X=tonumber(lx), Y=tonumber(ly), Z=tonumber(lz)},
        rot   = {Pitch=tonumber(p), Yaw=tonumber(y), Roll=tonumber(r)},
        scale = {X=tonumber(sx), Y=tonumber(sy), Z=tonumber(sz)}
    }
end

local function getBaseName(fullName)
    local name = fullName:match("^%S+%s+(.+)")
    return name or fullName
end

local function getClassName(fullName)
    return fullName:match("^(%S+)")
end

function getTargetLocation()
    local pc = UEHelpers.GetPlayerController()
    local cam = pc.PlayerCameraManager
    return getImpactPoint(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
end

function ExecuteInGameThreadSync(exec)
  local isProcessing = true
  ExecuteInGameThread(function()
    exec()
    isProcessing = false
  end)

  while isProcessing do
    Sleep(1)
  end
end

local function CloneStaticMeshActor(fullName, location, rotation, scale)
    local world = UEHelpers.GetWorld()
    local staticMeshActorClass = StaticFindObject("/Script/Engine.StaticMeshActor")
    local staticMeshClass = StaticFindObject("/Script/Engine.StaticMesh")
    local actor = CreateInvalidObject() ---@cast actor AActor

    local loadedAsset = StaticFindObject(fullName)
    if not loadedAsset:IsValid() then
        return actor
    end

    actor = world:SpawnActor(staticMeshActorClass, location, rotation)

    if not actor:IsValid() then
        print("world:SpawnActor actor is not valid");
    end

    loadedAsset = loadedAsset.StaticMesh

    if actor:IsValid() then

        actor:SetActorScale3D(scale)
        actor:SetReplicates(true)

        if loadedAsset:IsA(staticMeshClass) then

            -- local gameInstance = UEHelpers.GetGameInstance()
            -- gameInstance.ReferencedObjects[#gameInstance.ReferencedObjects + 1] = loadedAsset

            actor:SetMobility(2)

            if not actor.StaticMeshComponent:SetStaticMesh(loadedAsset) then
                error("Failed to set " .. loadedAsset:GetFullName() .. " as static mesh")
                return actor
            end

            actor.StaticMeshComponent:SetIsReplicated(true)
        end
    end

    return actor

end

function SpawnActorFromClassName(ActorClassName, Location, Rotation, Scale)
    local invalidActor = CreateInvalidObject() ---@cast invalidActor AActor
    if type(ActorClassName) ~= "string" or not Location then return invalidActor end

    if ActorClassName:find('StaticMeshActor') then
        return CloneStaticMeshActor(ActorClassName, Location, Rotation, Scale)
    end

    LoadAsset(ActorClassName)

    local world = UEHelpers.GetWorld()
    if not world:IsValid() then return invalidActor end

    local actorClass = StaticFindObject(ActorClassName)
    if not actorClass:IsValid() then
        print("SpawnActorFromClassName: Couldn't find static object:", ActorClassName)
        return invalidActor
    end


    local transform = UEHelpers.GetKismetMathLibrary():MakeTransform(Location, Rotation, Scale)

    local deferredActor = UEHelpers.GetGameplayStatics():BeginDeferredActorSpawnFromClass(world, actorClass, transform, 0, nil, 0)
    if deferredActor:IsValid() then
        return UEHelpers.GetGameplayStatics():FinishSpawningActor(deferredActor, transform, 0)
    else
        print("Deferred Actor failed", ActorClassName)
    end
    return invalidActor
end

-- ==============================================================
-- Unified File I/O (actions)
-- ==============================================================

local function serializeAction(action)
    if action.type == "spawn" then
        -- spawn|className|loc,rot,scale
        return string.format("spawn|%s|%s", action.className, serializeTransform(action.loc, action.rot, action.scale))
    elseif action.type == "hide" then
        return string.format("hide|%s|", action.name)
    elseif action.type == "unhide" then
        return string.format("unhide|%s|", action.name)
    elseif action.type == "rotate" then
        return string.format("rotate|%s|%f", action.name, action.yaw)
    elseif action.type == "cut" then
        return string.format("cut|%s|", action.name)
    end
    return ""
end

local function parseAction(line)
    local action, obj, params = line:match("^(%w+)%|([^|]+)%|?(.*)$")
    if not action or not obj then return nil end
    if action == "spawn" then
        local tf = deserializeTransform(params)
        return {type="spawn", className=obj, loc=tf.loc, rot=tf.rot, scale=tf.scale}
    elseif action == "hide" then
        return {type="hide", name=obj}
    elseif action == "unhide" then
        return {type="unhide", name=obj}
    elseif action == "rotate" then
        return {type="rotate", name=obj, yaw=tonumber(params)}
    elseif action == "cut" then
        return {type="cut", name=obj}
    end
    return nil
end

local function saveActions()
    local f = io.open(SAVE_FILE, "w")
    if not f then return end
    for _, action in ipairs(actions) do
        local line = serializeAction(action)
        if line and line ~= "" then
            f:write(line .. "\n")
        end
    end
    f:close()
end

local function loadActions()
    actions = {}
    local f = io.open(SAVE_FILE, "r")
    if not f then return end
    for line in f:lines() do
        local act = parseAction(line)
        if act then table.insert(actions, act) end
    end
    f:close()
end

-- ==============================================================
-- Action Application (Replay)
-- ==============================================================

local function applyAction(act)
    if act.type == "spawn" then
        print("spawning", act.className)

        ExecuteWithDelay(50, function()
            ExecuteInGameThread(function()
                act.result = SpawnActorFromClassName(act.className, act.loc, act.rot, act.scale)
            end)
        end)

    elseif act.type == "hide" then
        local Object = StaticFindObject(act.name)
        if Object and Object:IsValid() and Object.SetActorHiddenInGame then
            print("hiding", act.name)
            Object:SetActorHiddenInGame(true)
            Object:SetActorEnableCollision(false)
        end
    elseif act.type == "unhide" then
        local Object = StaticFindObject(act.name)
        if Object and Object:IsValid() and Object.SetActorHiddenInGame then
            print("unhiding", act.name)
            Object:SetActorHiddenInGame(false)
            Object:SetActorEnableCollision(true)
        end
    elseif act.type == "rotate" then
        local Object = StaticFindObject(act.name)
        if Object and Object:IsValid() and Object.K2_SetActorRotation then
            print("rotating", act.name, act.yaw)

            if Object.SetMobility and Object.SetMobility:IsValid() then
                Object:SetMobility(2) -- movable
            end

            local rot = Object:K2_GetActorRotation()
            rot.Yaw = (rot.Yaw + act.yaw) % 360
            Object:K2_SetActorRotation(rot, false)
        end
    end
end

local function applyActions()
    for _, act in ipairs(actions) do
        applyAction(act)
    end
end

-- ==============================================================
-- Undo Last Action
-- ==============================================================

local function undoLastAction()
    if #actions == 0 then return end
    local act = table.remove(actions)

    print("Undoing last action: " .. (act.type or "?"))

    if act.type == "hide" then
        act.type = "unhide"
        applyAction(act)
    end

    if act.type == "rotate" then
        act.yaw = -act.yaw
        applyAction(act)
    end

    if act.type == "spawn" then
        local actor = act.result
        if actor and actor:IsValid() then
            actor:K2_DestroyActor()
        end
    end

    saveActions()
    -- Reload and replay actions (simply re-applies all except the last)
    ExecuteInGameThread(function()
        -- applyActions()
    end)
end

-- ==============================================================
-- Editor Operations
-- ==============================================================

local selectedObject = nil

local function copyObject()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn then return end

    local cam = pc.PlayerCameraManager
    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
    if not hitObject or not hitObject:IsValid() then return end

    selectedObject = hitObject--:GetOuter()

    if not selectedObject:IsValid() then return end

    print("Copied: " .. selectedObject:GetFullName())
    return selectedObject
end

local function pasteObject()
    print("pasteObject", selectedObject and selectedObject:IsValid() and selectedObject:GetFullName())

    if not selectedObject or not selectedObject:IsValid() then return end

    local actor = selectedObject:GetOuter()

    local pc = UEHelpers.GetPlayerController()
    local cam = pc.PlayerCameraManager

    local loc = getImpactPoint(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
    local rot = actor:K2_GetActorRotation()
    local scale = actor:GetActorScale3D()
    local className = getBaseName(actor:GetClass():GetFullName())

    if className == '/Script/Engine.StaticMeshActor' then
        className = getBaseName(selectedObject:GetFullName())
    end

    -- Add to actions
    local act = {type="spawn", className=className, loc=loc, rot=rot, scale=scale}
    applyAction(act)

    table.insert(actions, act)
    saveActions()
end

local function cutObject()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn then return end

    local cam = pc.PlayerCameraManager
    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
    if not hitObject or not hitObject:IsValid() then return end

    local obj = hitObject:GetOuter()
    if not obj or not obj:IsValid() then return end

    local name = getBaseName(obj:GetFullName())

    local act = {type="hide", name=name}
    applyAction(act)

    table.insert(actions, act)
    saveActions()
end

local function rotateObject()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() then return end

    local cam = pc.PlayerCameraManager

    local hitObject = getHitObject(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
    if not hitObject or not hitObject:IsValid() then return end

    local actor = hitObject:GetOuter()
    if not actor or not actor:IsValid() then return end

    local name = getBaseName(actor:GetFullName())
    local rot = actor:K2_GetActorRotation()

    local yaw = 90
    rot.Yaw = (rot.Yaw + yaw) % 360

    local act = {type="rotate", name=name, yaw=yaw}

    applyAction(act)

    table.insert(actions, act)
    saveActions()
end

-- ==============================================================
-- Load and Replay
-- ==============================================================

local function loadSaves()
    ExecuteInGameThread(function()
        loadActions()
        applyActions()
    end)
end

local function spawnClass(className)
    ExecuteWithDelay(250, function()
        ExecuteInGameThread(function()
            local loc = getTargetLocation()
            local rot = {Pitch=0, Yaw=0, Roll=0}
            SpawnActorFromClass(className, loc, rot)
        end)
    end)
end

local function spawnThings()
    -- spawnClass('/Supraworld/Levelobjects/Carriables/AluminumBall.AluminumBall_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/FourLeafClover.FourLeafClover_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Hats/JesterHat.JesterHat_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/Die.Die_C')
    -- spawnClass('/Supraworld/Levelobjects/Carriables/ButtonBattery.ButtonBattery_C')
    spawnClass('/Supraworld/Abilities/SpongeSuit/ShopItem_SpongeSuit.ShopItem_SpongeSuit_C')
    -- you can also use cheats, e.g. "summon Bush_C" in game console (uses LoadAsset internally)
    -- UEHelpers.GetPlayerController().CheatManager['summon']('Bush_C')
    -- UEHelpers.GetPlayerController().CheatManager.Summon('Bush_C')
end

-- ==============================================================
-- Hooks & Keybinds
-- ==============================================================

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    loadSaves()
end)

RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, {ModifierKey.CONTROL}, spawnThings)
RegisterKeyBind(Key.C, {ModifierKey.CONTROL}, copyObject)
RegisterKeyBind(Key.V, {ModifierKey.CONTROL}, pasteObject)
RegisterKeyBind(Key.X, {ModifierKey.CONTROL}, cutObject)
RegisterKeyBind(Key.R, {ModifierKey.ALT}, rotateObject)
RegisterKeyBind(Key.Z, {ModifierKey.CONTROL}, undoLastAction)
