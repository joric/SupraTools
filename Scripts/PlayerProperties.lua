-- currently Supraland only

-- see https://github.com/DrNjitram/SuprAP/

-- adds "poke" command to the game console (~)

-- so you basically can set any player variable with "poke" console command
-- type "poke" in console without parameters to see player properties
-- player properties persistent for example poke Happy? true works but not writes in saves

player = {}

player.Status = {
    -- Health
    MaxHealth = 25,
    HealthRegenerateToX = 0,
    HealthRegenerateSpeed = 0,
    DoubleHealth = false, -- Double health regen ceiling?
    -- Sword
    SkillHasSword = false,
    SkillHasSword2 = false,
    Sworddamagex2 = false,
    SkillHasSwordCriticalDamage = false,
    SkillHasSwordCriticalDamageChance = 0,
    SkillHasSwordCriticalDamageAmount = 0,
    SwordRefireRate = 0,
    SwordDamage = 0,
    SwordRange = 0.0,
    SkillSwordKillGrave1 = false,
    SkillSwordKillGrave2 = false,
    -- Cube
    ["SkillHasForceBlock?"] = false,
    SkillHasForceCubeTelefrag = false,
    SkillForceCubeStomp = false,
    SkillKillGrave3 = false,
    -- Movement
    SkillMultijump1 = false,
    SkillMultijump2 = false,
    JumpHeightPlus = false,
    SkillWalkSpeedx2 = false,
    SkillWalkSpeedx15 = false,
    ["Happy?"] = false,
    -- Gun
    SkillHasGun = false,
    SkillHasGunAlt = false,
    GunPicksUpCoins = false,
    SkillHasFiregun = false,
    GunRefireRate = 0.0,
    GunAltRefireRate = 0.0,
    GunAmmo = 0.0,
    GunAmmoRefillSpeed = 0.0,
    Projectile1Damage = 0.0,
    Projectile1Speed = 0.0,
    Projectile1Radius = 0.0,
    SkillHasGunCriticalDamage = false,
    SkillHasGunCriticalDamageChance = 0.0,
    ["Skill Gun Kill Grave 1"] = false,
    ["Skill Gun Kill Grave 2"] = false,
    -- Belt
    SkillHasBelt = false,
    MagnetRepelUpgrade = false,
    -- Utility
    SkillCoinMagnet = false,
    SkillShieldBreaker = false,
    SkillHasShield = false,
    SkillSeeChestNum = false,
    SkillSeeGraveNum = false,
    HasGraveDetector = false,
    Strong = false, -- Strength upgrade
    -- Grapple Gun
    SkillHasGrapple = false,
    SkillGrappleForceCube = false,
    SkillGrappleGold = false,
    -- Translocator
    SkillHasTranslocator = false,
    TranslocatorDamage = 0.0,
    TranslocatorCooldown = 0.0,
    -- Shoes
    HasSilentFeet = false, -- Stomp Shoes
    SkillHasSmashDown = false,
    -- Dev tools?
    bGodMode = false,
    bBuddhaMode = false,
    -- Kill Tracking (Maybe do checks for kills later?)
    KilledGrunts = 0,
    KilledGhoulSimple = 0,
    KilledGhoulBoss = 0,
    KilledSkeletonShieldWarrior = 0,
    KilledSkeletonMorningStar = 0,
    KilledSkeletonMagician = 0,
    KilledGolem = 0,
    KilledStump = 0,
    KilledWarriors = 0,
    KilledMages = 0,
    KilledKings = 0,
    KilledDemonBombs = 0,
    KilledDemonGrunts = 0,
    KilledDemonBoss = 0,
    KilledArcher = 0,
    KilledFatty = 0
}

-- unused for now
function player.SetupHooks()
    --- This works well enough
    --- GetStatus can't be run as part of the client restart because the player status isn't fully loaded
    RegisterCustomEvent("ChangePlayerBool", function(self, Name, State)
        print(string.format("Updating player status with %s: %s", Name:get():ToString(), State:get()))
        player.UpdateStatus(Name:get():ToString(), State:get())
    end)
    RegisterCustomEvent("ChangePlayerInt", function(self, Name, Value)
        player.UpdateStatus(Name:get():ToString(), Value:get())
    end)
    RegisterCustomEvent("ChangePlayerFloat", function(self, Name, Value)
        player.UpdateStatus(Name:get():ToString(), Value:get())
    end)
    RegisterCustomEvent("Lua_ModInitialized", function (ModActor)
        if ModActor:get() ~= nil and ModActor:get():IsValid() then
            APUtil.ModActor = ModActor:get()
            print("AP ModActor loaded in LUA")
        end
        player.UpdateStatus("SkillHasSword", true)
    end)

end

-- unused for now
function player.Heal()
    player.Player.Health = player.Player.MaxHealth
end


local function coerceValue(obj, name, value)
    local prop = obj[name]
    if prop == nil then
        return nil
    end

    local ptype = type(prop)
    if ptype == "number" then
        return tonumber(value)
    elseif ptype == "boolean" then
        return value == "true" or value == "1"
    elseif ptype == "FVector" then
        local x, y, z = value:match("([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
        if x then return {X=tonumber(x), Y=tonumber(y), Z=tonumber(z)} end
    elseif ptype == "FRotator" then
        local p, y, r = value:match("([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
        if p then return {Pitch=tonumber(p), Yaw=tonumber(y), Roll=tonumber(r)} end
    elseif ptype:match("FString") then
        return value
    else
        print("Unhandled type:", ptype)
    end
    return nil
end


local function GetPlayerProperties()
    local obj = FindFirstOf("FirstPersonCharacter_C")
    if not obj or not obj:IsValid() then
        return {}
    end

    local data = {}
    for name, value in pairs(player.Status) do
        local str = string.format("%s: %s [%s]", name, tostring(obj[name]), type(obj[name]))
        table.insert(data, str)
    end
    table.sort(data)
    return data
end

local function SetPlayerProperty(name, stringValue)
    local obj = FindFirstOf("FirstPersonCharacter_C")
    if not obj or not obj:IsValid() then
        return false, "not found"
    end

    local value = coerceValue(obj, name, stringValue)

    if value~=nil then
        obj[name] = value -- setting value
        return true
    end

    return false, "not found or could not find type"
end

RegisterConsoleCommandHandler("poke", function(FullCommand, Parameters, Ar)
    local name = Parameters[1]

    if not name then
        local res = GetPlayerProperties()
        for _, str in ipairs(res) do
            print(str)
            Ar:Log(str)
        end
        Ar:Log("Usage: poke <PropertyName> <Value>")
        return true
    end

    local stringValue = table.concat(Parameters, " ", 2)
    local ok, err = SetPlayerProperty(name, stringValue)

    if ok then
        Ar:Log(string.format("%s set to %s", name, stringValue))
    else
        Ar:Log(err)
    end

    return true
end)

RegisterConsoleCommandHandler("peek", function(FullCommand, Parameters, Ar)
    local name = Parameters[1]

    if not name then
        local res = GetPlayerProperties()
        for _, str in ipairs(res) do
            print(str)
            Ar:Log(str)
        end
        Ar:Log("Usage: peek <PropertyName>")
        return true
    end

    local obj = FindFirstOf("FirstPersonCharacter_C")
    if not obj or not obj:IsValid() then
        Ar:Log("Character not found")
        return true
    end

    if obj[name] ~= nil then
        Ar:Log(string.format("%s is %s", name, obj[name]))
    else
        Ar:Log(string.format("Property %s not found.", name))
    end

    return true
end)

