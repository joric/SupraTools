-- Supraland only
-- so you basically can set any player variable with poke console command
-- to give weapons use summon to spawn shop items, e.g. summon BuyTranslocator_C

-- see https://github.com/DrNjitram/SuprAP/

local UEHelpers = require("UEHelpers")

Blueprints = {
    Map = "BP_UnlockMap_C",
    Buckle = "BuyBelt_C",
    ChestDetector = "BuyChestDetector_C",
    ChestDetectorRadius = "BuyChestDetectorRadius_C",
    GunCritDamage = "BuyGunCriticalDamage_C",
    GunCritChance = "BuyGunCriticalDamageChance_C",
    GunDamage15 = "BuyGunDamage+15_C",
    GunDamage5 = "BuyGunDamage+5_C",
    GunDamage1 = "BuyGunDamage+1_C",
    GunRefill = "BuyGunRefillSpeed+66_C",
    GunCooldown = "BuyGunRefireRate50_C",
    GunProjSpeed = "BuyGunSpeedx2_C",
    Health1 = "BuyHealth+1_C",
    Health2 = "BuyHealth+2_C",
    Health5 = "BuyHealth+5_C",
    Health15 = "BuyHealth+15_C",
    ShieldBreaker = "BuyShieldBreaker_C",
    ShowProgress = "BuyShowProgress_C",
    StompDamage = "BuySmashdownDamage+33_C",
    Stats = "BuyStats_C",
    SwordCriticalChance = "BuySwordCriticalDamageChance_C",
    SwordDamage1 = "BuySwordDamage+1_C",
    SwordDamage2 = "BuySwordDamage+2_C",
    SwordDamage3 = "BuySwordDamage+3_C",
    ChestCount = "BuyUpgradeChestNum_C",
    Wallet2 = "BuyWalletx2_C",
    Wallet15 = "BuyWalletx15_C",
    StompRadius = "BuySmashdownRadius+_C",
    GunComboDamage = "BuyGunComboDamage+25_C",
    CoinBundle = "Coin:Chest_C",
    EnemyHealth = "BuyNumberRising_C",
    TransDamage = "BuyTranslocatorDamagex3_C",
    TransCooldown = "BuyTranslocatorCoolDownHalf_C",
    GreenMoon = "MoonTake_C",
    RedMoon = "BuyCrystal_C",
    GunSplash = "BuyGunSplashDamage_C",
    Silent = "BuySilentFeet_C",
    GraveCount = "BuyGraveDetector_C",
    GraveDetector = "BuyUpgradeGraveNum_C",
    MoreLoot = "BuyMoreLoot_C",
    CubeTelefrag = "BuyForceBlockTelefrag_C",
    HealthRegenSpeed = "BuyHealthRegenSpeed_C",
    SwordRange = "BuySwordRange25_C",
    SwordCritical = "BuySwordCriticalDamageChance_C",
    Loot = "BuyEnemiesLoot_C",
    Stomp = "BuySmashdown_C",
    HealthBar = "BuyShowHealthbar_C",
    GunCoin = "BuyGunCoin_C",
    Armor = "BuyArmor1_C",
    SwordSpeed = "BuySwordRefireRate-33_C",
    LootLuck = "BuyHeartLuck_C",
    CoinMagnet = "BuyCoinMagnet_C",
    Coin = "Coin_C",
    BigCoin = "CoinBig_C",
    HeroAustin = "DeadHero2Austin",
    HeroLink = "DeadHero2Link",
    HeroHeman = "DeadHero3Heman",
    HeroAsh = "DeadHero3Pokemon",
    HeroPicard = "DeadHero4Picard",
    HeroSanta = "DeadHero4Santa",
    HeroVault = "DeadHero4Santa2",
    HeroStar = "DeadHero4Santa3",
    HeroMagic = "DeadHero_3",
    HeroGoku = "DeadHeroGoku",
    HeroGuy = "DeadHeroGuybrush",
    HeroIndy = "DeadHeroIndy",
    EnemySpawn1 = "EnemySpawn1_C",
    EnemySpawn2 = "EnemySpawn2_C",
    EnemySpawn3 = "EnemySpawn3_C",
    DoubleHealth = "BP_DoubleHealthLoot_C",
    Shell = "Shell_C",
    Strong = "BP_A3_StrengthQuest_C",
    Happiness = "UpgradeHappiness_C",
    StolenBuckle = "BuyBelt_C",
    StolenGun = "BuyGun1_C",
    StolenCube = "BuyForceBlock_C",
    StolenJump2 = "BuyDoubleJump_C",
    StolenJump3 = "BuyTripleJump_C",
    Health10 = "_BuyHealth+10_C"
}

Progressives = {
    ProgSword = {"BuySword_C", "BuySword2_C"},
    ProgSpeedJump = {"BuySpeedx2_C", "BuySpeedx15_C", "BuyDoubleJump_C", "BuyTripleJump_C"},
    ProgForceBeam = {"BuyForceBeam_C", "BuyForceBeamGold_C", "BuyForceCubeBeam_C"},
    ProgCube = {"BuyForceCube_C", "BuyForceCubeStomp_C", "BuyForceCubeStompGrave3_C"},
    ProgGun = {"BuyGun1_C", "BuyGunAlt_C", "BuyGunAltDamagex2_C", "BuyGunAltDamagex2_C", "BuyGunAltDamagex2_C", "BuyGunAltDamagex2_C", "BuyGunAltDamagex2_C"},
    ProgTrans = {"BuyTranslocator_C", "BuyTranslocatorShotForce_C"},
    ProgGraveGun = {"BuyGunHoly1_C", "BuyGunHoly2_C"},
    ProgGraveSword = {"BuySwordHoly1_C", "BuySwordHoly2_C"},
    ProgHealthRegen = {"BuyHealthRegen_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax5_C", "BuyHealthRegenMax10_C"}
}


local player = {}

---@class AFirstPersonCharacter_C
player.Player = nil

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

function player.Heal()
    player.Player.Health = player.Player.MaxHealth
end


    --[[
    local cls = obj:GetClass()

    print("Class:", cls:GetFName():ToString())

    local props = cls:GetProperties()
    for i, prop in ipairs(props) do
        print(i, prop:GetFullName())
    end
    ]]

--[[
    local data = {}
    for stat, _ in pairs(player.Status) do
        -- player.Status[stat] = player.Player[stat]

        local str = string.format("%s: %s", stat, player.Status[stat])

        print(str)
        table.insert(data, str)
    end
    return data
]]

-- local cls = obj:GetClass()
-- print("cls", cls:GetFName():ToString())
-- local prop = obj:GetClass():GetProperties()
-- print("prop", prop and prop:IsValid())
-- for k,v in pairs(obj) do print(k,v) end


local function coerceValue(obj, name, value)
    local prop = obj[name]
    if prop == nil then
        return nil
    end

    local ptype = type(prop)
    if ptype == "float" or ptype == "double" then
        return tonumber(value)
    elseif ptype == "int32" or ptype == "int" then
        return math.floor(tonumber(value))
    elseif ptype == "boolean" then
        return value == "true" or value == "1"
    elseif ptype == "FVector" then
        local x, y, z = value:match("([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
        if x then return FVector(tonumber(x), tonumber(y), tonumber(z)) end
    elseif ptype == "FRotator" then
        local p, y, r = value:match("([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
        if p then return FRotator(tonumber(p), tonumber(y), tonumber(r)) end
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
        return true, "all good"
    end

    return false, "not found or could not find type"
end

RegisterConsoleCommandHandler("poke", function(FullCommand, Parameters, Ar)
    local name = Parameters[1]
    if not name then
        Ar:Log("Usage: poke <PropertyName> <Value>")
        -- Ar:Log("Type 'status' to list all properties.")

        local res = GetPlayerProperties()
        for _, str in ipairs(res) do
            print(str)
            Ar:Log(str)
        end

        return true
    end

    local stringValue = table.concat(Parameters, " ", 2)

    local ok, err = SetPlayerProperty(name, stringValue)

    if ok then
        Ar:Log(string.format("Setting %s to %s", name, stringValue))
    else
        Ar:Log(err)
    end

    return true
end)

RegisterConsoleCommandHandler("status", function(FullCommand, Parameters, Ar)
    local res = GetPlayerProperties()
    for _, str in ipairs(res) do
        Ar:Log(str)
    end
    return true
end)

-- ok, err = SetPlayerProperty("Happy?", "true")
-- print(ok, err)


