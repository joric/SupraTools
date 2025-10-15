-- currently Supraland only

-- adds "deploy" command to the game console (~)

-- to give weapons use summon to spawn shop items, e.g. summon BuyTranslocator_C
-- you can also use "deploy" shortcut to summon items using aliases
-- type "deploy" to list aliases

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


local function GetDeployAliases()
    local data = {}
    for name, value in pairs(Blueprints) do
        local str = string.format("%s (%s)", name,value)
        table.insert(data, str)
    end

    for name, values in pairs(Progressives) do
        for _, value in ipairs(values) do
            local str = string.format("%s (%s)", value, name)
            table.insert(data, str)
        end
    end

    local unique = {}

    for _, v in ipairs(data) do
        unique[v] = true
    end

    res = {}
    for k,v in pairs(unique) do table.insert(res, k) end

    table.sort(res)
    return res
end

local function GetItemName(alias)
    local key = alias:lower()

    for name, value in pairs(Blueprints) do
        if key==name:lower() or key==value:lower() then
            return value
        end
    end

    for name, values in pairs(Progressives) do
        for _, value in ipairs(values) do
            if key==name:lower() or key==value:lower() then
                return value
            end
        end
    end

    return false, string.format("%s not found", alias)
end


local function GiveItem(name)
    local pc = UEHelpers.GetPlayerController()
    if not pc:IsValid() or not pc.CheatManager or not pc.CheatManager:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return false, "could not find valid player controller"
    end

    LoadAsset(name)

    local object = FindObject('BlueprintGeneratedClass', name)
    if not object:IsValid() then
        return false, "could not find object"
    end

    local self = FindFirstOf("FirstPersonCharacter_C")
    if not self:IsValid() then
        return false, "could not find character"
    end

    local world = UEHelpers.GetWorld()
    --local loc = {X=0,Y=0,Z=0}
    local loc = pc.Pawn:K2_GetActorLocation()
    local rot = {Pitch=0,Yaw=0,Roll=0}

    local actor = world:SpawnActor(object, loc, rot)
    actor:SetActorScale3D({X=3,Y=3,Z=3}) -- make actor BIG so it highlights for use (e.g. shells are too small)

    print("Spawned actor:", actor:GetFullName())

    self:Using() -- and pick up item! this is very unreliable (object shapes are very different) but sometimes works

    return true
end

local function DeployItem(name)
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() or not pc.CheatManager or not pc.CheatManager:IsValid() then return end

    print("Deploying", name)

    local tryGiveItem = true

    if tryGiveItem then
        return GiveItem(name)
    else
        LoadAsset(name) -- need to preload item before cheat manager
        pc.CheatManager["summon"](name)
    end

    return true
end

RegisterConsoleCommandHandler("deploy", function(FullCommand, Parameters, Ar)
    local name = Parameters[1]
    if not name then
        local res = GetDeployAliases()
        for _, str in ipairs(res) do
            Ar:Log(str)
        end
        Ar:Log("Usage: deploy <alias or name>")
        return true
    end

    local name, err = GetItemName(name)

    if name then
        ok, err = DeployItem(name)
        if ok then
            Ar:Log(string.format("%s deployed.", name))
        else
            Ar:Log(err)
        end
    else
        Ar:Log(err)
    end

    return true
end)
