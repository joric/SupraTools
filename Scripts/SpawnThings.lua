local UEHelpers = require("UEHelpers")

local function getSavePath()
    local gameName = UEHelpers.GetKismetSystemLibrary():GetGameName():ToString()
    local basePath = os.getenv("LOCALAPPDATA") or (os.getenv("HOME") .. "/.local/share")
    return basePath .. "/" .. gameName .. "/SpawnThings.txt"
end

-- Unified log of all actions
local actions = {}

local nameIndex = 0
local function getNextName()
    nameIndex = nameIndex + 1
    return string.format('SpawnedThings_%04d', nameIndex)
end

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

local function getName(actor)
    return actor and actor:IsValid() and actor:GetFName():ToString() or "";
end

local function getBaseName(fullName)
    local name = fullName:match("^%S+%s+(.+)")
    return name or fullName
end

local function getClassName(fullName)
    return fullName:match("^(%S+)")
end

local function getShortName(className)
    return className:match(".*%.(.+)") or className
end

local function addTag(actor, tag)
    actor.Tags[#actor.Tags + 1] = FName(tag)
    print("actor tagged", tag)
end

function getActorRotation(actor) -- UE4 doesn't seem to have it
    local rot = {Pitch=0, Yaw=0, Roll=0}
    -- local rot = actor.RootComponent.RelativeRotation
    return actor.K2_GetActorRotation:IsValid() and actor:K2_GetActorRotation() or rot
end

function getActorScale(actor)
    local scale = {X=1, Y=1, Z=1}
    return actor.GetActorScale3D:IsValid() and actor:GetActorScale3D() or scale
end

function getTargetLocation()
    local pc = UEHelpers.GetPlayerController()
    local cam = pc.PlayerCameraManager
    return getImpactPoint(pc.Pawn, cam:GetCameraLocation(), cam:GetCameraRotation())
end

local function getActorByTag(tag)
    local world = UEHelpers.GetWorld()
    if not world:IsValid() then return nil end
    local actors = {}
    UEHelpers.GetGameplayStatics():GetAllActorsWithTag(world, FName(tag), actors)
    if actors and #actors>0 then
        return actors[1]:Get()
    end
    return nil
end

local function getActorByAlias(name)
    local actor = StaticFindObject(name)
    if actor and actor:IsValid() then return actor end

    actor = getActorByTag(name)
    if actor and actor:IsValid() then return actor end

    actor = FindObject('BlueprintGeneratedClass', name)
    if actor and actor:IsValid() then return actor end

    actor = FindObject('StaticMesh', name)
    if actor and actor:IsValid() then return actor end

    actor = FindObject(nil, name)
    if actor and actor:IsValid() then return actor end

    actor = FindObject(name, nil)
    if actor and actor:IsValid() then return actor end

    return nil
end

local function getAlias(actor, instancesOnly)
    if actor.Tags:IsValid() and #actor.Tags>0 then
        local tag = actor.Tags[#actor.Tags]:ToString()
        if tag:find('SpawnedThings_') then
            return tag
        end
    end

    if instancesOnly then return getName(actor) end

    local className = getName(actor:GetClass())

    if className == 'StaticMeshActor' then
        return getName(actor:K2_GetRootComponent().StaticMesh)
    end

    return className
end

local function CloneStaticMeshActor(meshPath, location, rotation, scale)
    local world = UEHelpers.GetWorld()

    local staticMeshActorClass = StaticFindObject("/Script/Engine.StaticMeshActor")
    local staticMeshClass = StaticFindObject("/Script/Engine.StaticMesh")

    local actor = CreateInvalidObject() ---@cast actor AActor

    local loadedAsset = StaticFindObject(meshPath)
    if not loadedAsset:IsValid() then
        return actor
    end

    actor = world:SpawnActor(staticMeshActorClass, location, rotation)

    if not actor:IsValid() then
        print("world:SpawnActor actor is not valid");
    end

    actor:SetActorScale3D(scale)
    actor:SetReplicates(true)

    if loadedAsset:IsA(staticMeshClass) then
        actor:SetMobility(2)

        if not actor.StaticMeshComponent:SetStaticMesh(loadedAsset) then
            error("Failed to set " .. loadedAsset:GetFullName() .. " as static mesh")
            return actor
        end

        actor.StaticMeshComponent:SetIsReplicated(true)
    end

    return actor

end

function spawnActor(world, actorClass, loc, rot, scale)
    local transform = UEHelpers.GetKismetMathLibrary():MakeTransform(loc, rot, scale)

    if UnrealVersion:IsBelow(5, 0) then
        local actor = UEHelpers.GetGameplayStatics():BeginDeferredActorSpawnFromClass(world, actorClass, transform, 0, nil)
        return UEHelpers.GetGameplayStatics():FinishSpawningActor(actor, transform)
    else
        local actor = UEHelpers.GetGameplayStatics():BeginDeferredActorSpawnFromClass(world, actorClass, transform, 0, nil, 0)
        return UEHelpers.GetGameplayStatics():FinishSpawningActor(actor, transform, 0)
    end
end

function SpawnActorFromClassName(ActorClassName, Location, Rotation, Scale)
    local invalidActor = CreateInvalidObject() ---@cast invalidActor AActor
    if type(ActorClassName) ~= "string" or not Location then return invalidActor end

    LoadAsset(ActorClassName)

    local world = UEHelpers.GetWorld()
    if not world:IsValid() then return invalidActor end

    local actorClass = StaticFindObject(ActorClassName)
    if not actorClass:IsValid() then
        print("SpawnActorFromClassName: Couldn't find static object:", ActorClassName)
        return invalidActor
    end

    local actor = spawnActor(world, actorClass, Location, Rotation, Scale)

    if actor:IsValid() then
        return actor
    else
        return CloneStaticMeshActor(ActorClassName, Location, Rotation, Scale)
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
        return string.format("hide|%s", action.name)
    elseif action.type == "unhide" then
        return string.format("unhide|%s", action.name)
    elseif action.type == "rotate" then
        return string.format("rotate|%s|%f", action.name, action.yaw)
    elseif action.type == "cut" then
        return string.format("cut|%s", action.name)
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
    local savePath = getSavePath()
    print("Saving to " .. savePath)
    local f = io.open(savePath, "w")
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
    local savePath = getSavePath()
    print("Loading from " .. savePath)
    actions = {}
    local f = io.open(savePath, "r")
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

local function rotateActor(Object, yaw)
    if Object and Object:IsValid() then

        local root = Object.K2_GetRootComponent()
        if root and root:IsValid() and root.SetMobility and root.SetMobility:IsValid() then
            root:SetMobility(2) -- set as movable (mandatory, some blueprints don't have movable mesh)
        end

        if Object.K2_SetActorRotation and Object.K2_SetActorRotation:IsValid() then
            local rot = Object:K2_GetActorRotation()
            rot.Yaw = (rot.Yaw + yaw) % 360
            Object:K2_SetActorRotation(rot, true)
        end
    end
end

local function applyAction(act)
    ExecuteInGameThread(function()
        if act.type == "spawn" then

            local name = act.className

            -- className is either virtual or mesh actor or class

            local actor = getActorByAlias(name)
            if not actor or not actor:IsValid() then return end

            local className = getBaseName(actor:GetClass():GetFullName())

            print("spawning", name, "classname", className)

            if className == '/Script/Engine.StaticMesh' then
                print("this is mesh")
                className = getBaseName(actor:GetFullName())
            end

            if className == '/Script/Engine.StaticMeshActor' then
                print("this is mesh actor")
                className = getBaseName(actor:K2_GetRootComponent().StaticMesh:GetFullName())
            end

            if className == '/Script/Engine.BlueprintGeneratedClass' then
                print("this is blueprint")
                className = getBaseName(actor:GetFullName())
            end

            print("trying to spawn object from className", className)

            actor = SpawnActorFromClassName(className, act.loc, act.rot, act.scale)

            local tag = getNextName()
            actor.Tags[#actor.Tags + 1] = FName(tag)
            print("actor tagged", tag)
            act.result = actor

        elseif act.type == "hide" then
            local Object = getActorByAlias(act.name)
            if Object and Object:IsValid() and Object.SetActorHiddenInGame then
                print("hiding", act.name)
                Object:SetActorHiddenInGame(true)
                Object:SetActorEnableCollision(false)
            end
        elseif act.type == "unhide" then
            local Object = getActorByAlias(act.name)
            if Object and Object:IsValid() and Object.SetActorHiddenInGame then
                print("unhiding", act.name)
                Object:SetActorHiddenInGame(false)
                Object:SetActorEnableCollision(true)
            end
        elseif act.type == "rotate" then
            local Object = getActorByAlias(act.name)
            -- print("---------- trying to rotate", act.name, Object and Object:IsValid())
            if Object and Object:IsValid() then
                print("rotating class", act.name, Object:GetClass():GetFullName())
                rotateActor(Object, act.yaw)
            end
        end
    end)
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
    if #actions == 0 then
        print("No more actions to undo.")
        return
    end

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
        nameIndex = nameIndex - 1
    end

    saveActions()
end

-- ==============================================================
-- Editor Operations
-- ==============================================================

local selectedObject = nil

local function copyObject()
    local hitObject = getCameraHitObject()
    if not hitObject or not hitObject:IsValid() then return end
    selectedObject = hitObject
    if not selectedObject:IsValid() then return end
    print("Copied: " .. selectedObject:GetFullName())
    return selectedObject
end

local function pasteObject()
    if not selectedObject or not selectedObject:IsValid() then return end

    print("Pasting: " .. selectedObject:GetFullName())

    local actor = selectedObject:GetOuter()

    if getClassName(actor:GetFullName())=='Level' then
        actor = selectedObject
    end

    print("Outer: " .. actor:GetFullName())

    local loc = getCameraImpactPoint()
    local rot = getActorRotation(actor)
    local scale = getActorScale(actor)

    local alias = getAlias(actor)

    print("got Alias", alias)

    local act = {type="spawn", className=alias, loc=loc, rot=rot, scale=scale}
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

    selectedObject = hitObject

    local actor = hitObject:GetOuter()
    if not actor or not actor:IsValid() then return end

    local name = getAlias(actor, true)

    local act = {type="hide", name=name}
    applyAction(act)

    table.insert(actions, act)
    saveActions()
end

local function rotateObject()
    local hitObject = getCameraHitObject()
    if not hitObject or not hitObject:IsValid() then return end

    local actor = hitObject:GetOuter()
    if not actor or not actor:IsValid() then return end

    local name = getAlias(actor, true)

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
        nameIndex = 0
        loadActions()
        ExecuteWithDelay(250, function()
            applyActions()
        end)
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
RegisterKeyBind(Key.Z, {ModifierKey.CONTROL}, undoLastAction)

RegisterKeyBind(Key.C, {ModifierKey.ALT}, copyObject)
RegisterKeyBind(Key.V, {ModifierKey.ALT}, pasteObject)
RegisterKeyBind(Key.X, {ModifierKey.ALT}, cutObject)
RegisterKeyBind(Key.Z, {ModifierKey.ALT}, undoLastAction)

RegisterKeyBind(Key.R, {ModifierKey.ALT}, rotateObject)

RegisterKeyBind(Key.RIGHT_MOUSE_BUTTON, {ModifierKey.ALT}, copyObject)
RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, {ModifierKey.ALT}, pasteObject)

