local UEHelpers = require("UEHelpers")

local function DropItem(name)
end

local function GiveItem(name)
    local pc = UEHelpers.GetPlayerController()
    if not pc:IsValid() or not pc.CheatManager or not pc.CheatManager:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return false, "could not find valid player controller"
    end

    local self = FindFirstOf("FirstPersonCharacter_C")
    if not self:IsValid() then
        return false, "could not find character"
    end

    --local loc = {X=0,Y=0,Z=0}
    --local loc = pc.Pawn:K2_GetActorLocation()
    --local rot = {Pitch=0,Yaw=0,Roll=0}

    local delta = {X=15,Y=50,Z=-30} -- shift object a little ({X=15,Y=50,Z=-30} works for shell and stomp)

    local cam = pc.PlayerCameraManager
    local pos, rot = cam:GetCameraLocation(), cam:GetCameraRotation()
    local dv = UEHelpers.GetKismetMathLibrary():Multiply_VectorInt(UEHelpers.GetKismetMathLibrary():GetForwardVector(rot), delta.Y)
    local loc = UEHelpers.GetKismetMathLibrary():Add_VectorVector(pos, dv)

    loc.X = loc.X + delta.X
    loc.Z = loc.Z + delta.Z

    LoadAsset(name)

    local object = FindObject('BlueprintGeneratedClass', name)
    if not object:IsValid() then
        return false, "could not find object"
    end

    local actor = UEHelpers.GetWorld():SpawnActor(object, loc, rot)
    actor:SetActorScale3D({X=1,Y=1,Z=1}) -- optionally make actor BIG so it has more surface to autoselect

    print("Spawned actor:", actor:GetFullName())

    self:Using() -- and pick up item! this is very unreliable (object shapes are very different) but sometimes works

    ExecuteWithDelay(500, function() self:UseReleased() end)

    return true
end


local function tagify(name)
    for _, sub in ipairs({"Buy", "BP_Purchase", "Purchase", "_C$", "^_"}) do
        name = name:gsub(sub, "")
    end
    return name:lower()
end

local function consolefy2(data)
    local out = {}
    for _, name in ipairs(data) do
        table.insert(out, tagify(name))
    end
    table.sort(out)

    local result = {}
    local lastFirst, count = "", 0

    for _, name in ipairs(out) do
        local first = name:sub(1,1)
        if first ~= lastFirst then
            if lastFirst ~= "" then table.insert(result, "\n") end
            count = 0
        elseif count % 5 == 0 then
            table.insert(result, "\n")
        else
            table.insert(result, " ")
        end
        table.insert(result, name)
        lastFirst, count = first, count + 1
    end

    return table.concat(result)
end

local function hasSubstring(str, substrings)
    for _, sub in ipairs(substrings) do
        if str:find(sub) then
            return true
        end
    end
    return false
end

local function GetItems(filter)
    local out = {}
    for _, obj in pairs(FindObjects(30000, "BlueprintGeneratedClass", "", 0, 0, false) or {}) do
        if obj and obj:IsValid() then
            local path = tostring(obj:GetFullName())
            if hasSubstring(path, {"/Buy", "/BP_Purchase", "/Purchase"}) then
                local name = obj:GetFName():ToString()
                if name then
                    if not filter or name:lower():find(filter:lower()) then
                        table.insert(out, name)
                    end
                end
            end
        end
    end

    table.sort(out, function(a, b)
        return tagify(a) < tagify(b)
    end)

    return out
end

local function findExactMatch(tbl, value)
    for _, v in ipairs(tbl) do
        if tagify(v) == value then
            return v
        end
    end
    return nil
end

RegisterConsoleCommandHandler("list", function(FullCommand, Parameters, Ar)
    local items = GetItems()
    for _,name in ipairs(items) do
        Ar:Log(string.format("%s (%s)", tagify(name), name))
    end
    return true
end)

local function processItemCommand(FullCommand, Parameters, Ar, callback)
    local filter = Parameters[1]
    if not filter then
        local items = GetItems()
        Ar:Log(consolefy2(items))
        Ar:Log(string.format("Usage: %s <name, class name, or substring>", FullCommand))
        return true
    end

    local items = GetItems(filter)
    local name = #items==1 and items[1] or findExactMatch(items, filter)

    if name then
        ok, err = callback(name)
        if ok then
            Ar:Log(string.format("%s (%s) succeed.", name, tagify(name)))
        else
            Ar:Log(err)
        end
    else
        Ar:Log(consolefy2(items))
    end

    return true
end

RegisterConsoleCommandHandler("drop", function(FullCommand, Parameters, Ar)
    return processItemCommand(FullCommand, Parameters, Ar, DropItem)
end)

RegisterConsoleCommandHandler("give", function(FullCommand, Parameters, Ar)
    return processItemCommand(FullCommand, Parameters, Ar, GiveItem)
end)

