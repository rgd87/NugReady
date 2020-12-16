local NugReady = CreateFrame("Frame", "NugReady", UIParent)

NugReady:SetScript("OnEvent", function(self, event, ...)
    -- print(GetTime(), event, unpack{...})
    return self[event](self, event, ...)
end)

NugReady:RegisterEvent("ADDON_LOADED")

local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitAura = UnitAura
local UnitExists = UnitExists
local GetSpellCooldown = GetSpellCooldown
local GetSpellCharges = GetSpellCharges
local IsPlayerSpell = IsPlayerSpell


local defaults = {
    point = "CENTER",
    posX = 0, posY = 0,
}

local function SetupDefaults(t, defaults)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if t[k] == nil then
                t[k] = CopyTable(v)
            else
                SetupDefaults(t[k], v)
            end
        else
            if t[k] == nil then t[k] = v end
        end
    end
end


local Masque = LibStub("Masque", true)
local MasqueIcon


local spellset = {}
function NugReady:LOAD_CLASS_SETTINGS()
    local _,class = UnitClass("player")
    -- if class == "PRIEST" then
        -- spellset = {
            -- ReadySpell()--
        -- }
    -- end
end


function NugReady.ADDON_LOADED(self,event,arg1)
    if arg1 == "NugReady" then

        NugReadyDB = NugReadyDB or {}

        SetupDefaults(NugReadyDB, defaults)

        -- self.db = NugReady

        -- self.anchor = self:CreateAnchor()
        self:CreateIcon()

        -- self.frame = CreateFrame("Frame", nil, UIParent)
        -- self.frame:SetPoint('TOPLEFT', self.anchor, "BOTTOMRIGHT", 0,0)
        -- for
            -- self:Create(self.frame)

        -- self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        self:RegisterEvent("SPELLS_CHANGED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("SPELL_UPDATE_COOLDOWN")

        SLASH_NUGREADY1= "/nugready"
        SlashCmdList["NUGREADY"] = function(msg)
            if msg == "unlock" then
                NugReady:EnableMouse(true)
                NugReady:Show()
            elseif msg == "lock" then
                NugReady:EnableMouse(false)
            else
                DEFAULT_CHAT_FRAME:AddMessage([[Usage:
                /nugready unlock
                /nugready lock
                ]], 0.6, 1, 0.6)
            end
        end
    end
end

function NugReady:SPELL_UPDATE_COOLDOWN()
    local start, duration = GetSpellCooldown(61304) -- Global Cooldown spell
end


local function FindAura(unit, spellID, filter)
    for i=1, 100 do
        -- rank will be removed in bfa
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, auraSpellID = UnitAura(unit, i, filter)
        if not name then return nil end
        if spellID == auraSpellID then
            return name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, auraSpellID
        end
    end
end

local function GetBuff(unit, spellID)
    local name, _, count, _, duration, expirationTime, caster, _,_, aura_spellID = FindAura(unit, spellID, "HELPFUL")
    if not name then return nil, 0 end
    return expirationTime - GetTime(), count
end
local function IsBuffUp(spellID)
    return GetBuff("player", spellID)
end

local function GetDebuff(unit, spellID)
    local name, _, count, _, duration, expirationTime, caster, _,_, aura_spellID = FindAura(unit, spellID, "HARMFUL")
    if not name then return nil, 0 end
    return expirationTime - GetTime(), count, duration
end
local function IsDebuffUp(spellID)
    return GetDebuff("target", spellID)
end

local function GetSpellCooldownNoCharge(spellID)
    local startTime, duration, enabled = GetSpellCooldown(spellID)
    local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID)
    if charges and charges ~= maxCharges then
        startTime = chargeStart
        duration = chargeDuration
    end
    return startTime, duration, enabled
end

local function GetCooldown(spellID)
    local startTime, duration, enabled = GetSpellCooldown(spellID)
    local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID)
    if charges and charges ~= maxCharges then
        startTime = chargeStart
        duration = chargeDuration
    end
    if duration == 0 then return 0 end
    local expirationTime = startTime + duration
    return expirationTime - GetTime(), duration
end

local GCDLeft = function()
    return GetCooldown(61304) -- Global Cooldown spell
end

local GCD = 0
function NugReady.SPELL_UPDATE_COOLDOWN(self, event)
    local startTime, duration, enabled = GetSpellCooldown(61304)
    if duration ~= 0 then GCD = duration end
end

local IsUsableSpell = IsUsableSpell

READYSPELL = {}
local IsReadySpell = function(spellID)
    local startTime, duration, enabled = GetSpellCooldownNoCharge(spellID)
    if duration == 0 then return true end

    local remains = (startTime + duration) - GetTime()

    -- if (spellID == 205523) then
    --     READYSPELL.name = GetSpellInfo(spellID)
    --     READYSPELL.remains = remains
    --     READYSPELL.gcd = GCD
    --     READYSPELL.condition = remains <= GCD
    -- end

    if remains <= GCD+0.05 then return true end
    return false
end

local IsReadySpell2 = function(spellID) -- Treats spells that still have charges as ready
    local startTime, duration, enabled = GetSpellCooldown(spellID)
    if duration == 0 then return true end
    local remains = (startTime + duration) - GetTime()
    if remains <= GCD+0.05 then return true end
    return false
end

ISREADYSPELL = IsReadySpell

local function IsAvailable(spellID)
    return IsUsableSpell(spellID) and IsReadySpell(spellID)
end

local function IsAvailable2(spellID)
    return IsUsableSpell(spellID) and IsReadySpell2(spellID)
end

-------------------------
-- ESSENCES
-------------------------

local ConcentratedFlame = 295373



-------------------------
-- RANGE CHECKER
-------------------------

local RangeCheck = CreateFrame("Frame", nil, UIParent)
RangeCheck:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

local activeNameplateUnits = {}

local isAOE = false
local rangeCheckElapsed = 0
local rangeCheckSpellName = nil
local rangeCheckTargetCount = 4
local RangeCheckOnUpdate = function(self, elapsed)
    rangeCheckElapsed = rangeCheckElapsed + elapsed
    if rangeCheckElapsed < 0.3 then return end
    rangeCheckElapsed = 0

    local unitsInRange = 0
    for unit in pairs(activeNameplateUnits) do
        if IsSpellInRange(rangeCheckSpellName, unit) then
            unitsInRange = unitsInRange + 1
        end
    end

    isAOE = unitsInRange >= rangeCheckTargetCount
end



RangeCheck:RegisterEvent("NAME_PLATE_UNIT_ADDED")
RangeCheck:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
function RangeCheck:NAME_PLATE_UNIT_ADDED(event, unit)
    activeNameplateUnits[unit] = true
end
function RangeCheck:NAME_PLATE_UNIT_REMOVED(event, unit)
    activeNameplateUnits[unit] = nil
end

function RangeCheck:Configure(targetCount, spellID)
    rangeCheckTargetCount = targetCount
    rangeCheckSpellName = GetSpellInfo(spellID)
end
function RangeCheck:Enable()
    if not rangeCheckSpellName then return end
    rangeCheckElapsed = 5
    self:SetScript("OnUpdate", RangeCheckOnUpdate)
end
function RangeCheck:Disable()
    self:SetScript("OnUpdate", nil)
end




local Enrage = 184362
local function IsEnraged()
    local name = FindAura("player", Enrage, "HELPFUL")
    return name
end

local Rampage = 184367
local OdynsFury = 205545
local FuryExecute = 5308
local RagingBlow = 85288
local Bloodthirst = 23881
local DragonRoar = 118000
local FuriousSlash = 100130
local Whirlwind = 190411
local WhirlwindBuff = 85739

local LastTimeWhirlwindWasPresent = 0

local function FurySetup()

    local execute_range = IsPlayerSpell(206315) and 0.35 or 0.2 -- Massacre

    return function()
        local isEnraged = IsEnraged()
        local IsWhirlwindBuffOn = FindAura("player", WhirlwindBuff, "HELPFUL")

        local rage = UnitPower("player")

        local isExecutePhase = false
        if UnitExists('target') then
            local h, hm = UnitHealth("target"), UnitHealthMax("target")
            if hm == 0 then hm = 1 end
            isExecutePhase = h/hm < execute_range
        end

        if IsWhirlwindBuffOn then
            LastTimeWhirlwindWasPresent = GetTime()
        end

        local isAOE = (LastTimeWhirlwindWasPresent + 5 > GetTime())

        -- local isWreckingBallOn = (GetBuff("player", 215570) ~= nil)


        -- local startTime, duration, enabled = GetSpellCooldown(RagingBlow)
        -- local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(RagingBlow)
        -- local startTime1, duration1, enabled1 = GetSpellCooldownNoCharge(RagingBlow)
        -- print("-------------------------------------------")
        -- print("GetSpellCooldown", startTime, duration, enabled )
        -- print("GetSpellCooldownNoCharge", startTime1, duration1, enabled1 )
        -- print("GetSpellCharges", charges, maxCharges, chargeStart, chargeDuration )



        -- if IsAvailable(DragonRoar) then
            -- return DragonRoar
        -- else
        -- print(IsUsableSpell(280735), IsAvailable(280735), isEnraged)
        -- if IsAvailable(Rampage) and (not isEnraged or rage == 100) then
        if isAOE and not IsWhirlwindBuffOn then
            return Whirlwind
        elseif IsAvailable(Rampage) then
            return Rampage
        elseif isExecutePhase and IsAvailable(FuryExecute) then
            return FuryExecute
        elseif not isEnraged and IsReadySpell(Bloodthirst) then
            return Bloodthirst
        elseif IsAvailable(FuryExecute) and isEnraged then
            return FuryExecute
        elseif IsAvailable(Bloodthirst) then
            return Bloodthirst
        elseif IsAvailable2(RagingBlow) then
            return RagingBlow
            -- return FuriousSlash
        else
            return 7812
        end
    end
end

local ColossusSmash = 167105
local Warbreaker = 209577
local MortalStrike = 12294
local FocusedRage = 207982
local Execute = 163201
local Slam = 1464
local Rend = 772
local Skullsplitter = 260643
local Overpower = 7384

local function ArmsSetup()
    -- local _, FocusedRageStacks = GetBuff("player", FocusedRage)
    -- local MortalStrikeCooldown = GetCooldown(MortalStrike)

    local execute_range = IsPlayerSpell(281001) and 0.35 or 0.2 -- Arms Massacre
    local isRendKnown = IsPlayerSpell(Rend)
    local isSkullsplitterKnown = IsPlayerSpell(Skullsplitter)
    local MortalStrikeCooldown = GetCooldown(MortalStrike)

    return function()

        -- local IsColossusSmashApplied = false
        local _, ExecutionerPrecision = GetBuff("player", 272870)
        local _, OverpowerBuff = GetBuff("player", Overpower)
        local RendRemains = 0

        local rage = UnitPower("player")

        -- local ExecutePhase = IsAvailable(Execute)
        local isExecutePhase = false
        if UnitExists("target") then
            -- IsColossusSmashApplied = GetDebuff("target", 208086) or 0 > 1.5
            if isRendKnown then RendRemains = GetDebuff("target", Rend) or 0 end

            local h, hm = UnitHealth("target"), UnitHealthMax("target")
            if hm == 0 then hm = 1 end
            isExecutePhase = h/hm < execute_range
        end



        if isRendKnown and RendRemains < 4 and not ExecutePhase then
            return Rend
        elseif isSkullsplitterKnown and IsAvailable(Skullsplitter) and rage < 60 then
            return Skullsplitter
        elseif IsAvailable(ColossusSmash) then
            return ColossusSmash
        -- elseif IsAvailable(Warbreaker) and not IsColossusSmashApplied then
        --     return Warbreaker
        elseif IsAvailable(Execute) and not isExecutePhase and MortalStrikeCooldown > GCD + 0.1 then -- Sudden Death
            return Execute

        elseif not isExecutePhase and IsAvailable(MortalStrike) then
            return MortalStrike

        --- Crushing Assault here
        ---
        elseif isExecutePhase and IsReadySpell(MortalStrike) and OverpowerBuff >= 2 or ExecutionerPrecision >= 2 then
            return MortalStrike

        elseif IsAvailable(Execute) then
            return Execute

        elseif IsAvailable(Overpower) then
            return Overpower

        elseif not isExecutePhase and IsAvailable(Slam) and rage >= 70 then
            return Slam
        else
            return 7812
        end
    end
end

local FistsOfFury = 113656
local FistOfTheWhiteTiger = 261947
local WhirlingDragonPunch = 152175
local TigerPalm = 100780
local RisingSunKick = 107428
local BlackoutKick = 100784
local ChiBurst = 123986
local ExpelHarm = 322101
local SpinningCraneKick = 101546
local DanceOfChiJi = 325202
local FreeBlackoutKick = 116768
local ENUM_CHI = Enum.PowerType.Chi

local LastUsedAbility
local IsAvailableInCombo = function(spellID)
    if spellID == LastUsedAbility then
        return false
    else
        return IsAvailable(spellID)
    end
end

local IsReadyInCombo = function(spellID)
    if spellID == LastUsedAbility then
        return false
    else
        return IsReadySpell(spellID)
    end
end


local function WindwalkerSetup()

    local isFistOfTheWhiteTigerKnown = IsPlayerSpell(FistOfTheWhiteTiger)
    local isChiBurstKnown = IsPlayerSpell(ChiBurst)
    local isExpelHarmKnown = IsPlayerSpell(ExpelHarm)
    local isConcentratedFlameKnown = IsPlayerSpell(ConcentratedFlame)
    local ExpelHarmHealthThreshold = 0.95
    RangeCheck:Configure(3, 113656) -- FoF, 8 yards

    local WindwalkerSingleTarget = function()
        local chi = UnitPower("player", ENUM_CHI)
        local chimax = UnitPowerMax("player", ENUM_CHI)
        local energy = UnitPower("player")
        local energyMax = UnitPowerMax("player")
        local health = UnitHealth("player")
        local healthMax = UnitHealthMax("player")
        local healthPercent = health/healthMax
        -- local WDPSoon = GetCooldown(WhirlingDragonPunch) < 6
        local FOFSoon = GetCooldown(FistsOfFury) < 4
        local RSKSoon = GetCooldown(RisingSunKick) < 3
        local haste = UnitSpellHaste("player")
        local regen = (100+haste)/10  -- energy per second
        local timetocap = ((energyMax - 10) - energy) / regen

        local isFreeBlackout = IsBuffUp(FreeBlackoutKick)

        if isFistOfTheWhiteTigerKnown and IsReadyInCombo(FistOfTheWhiteTiger) and chimax - chi >= 3 and energy > 70 then
            return FistOfTheWhiteTiger

        elseif energy > 70 and IsReadyInCombo(ExpelHarm) and chimax - chi >= 1 then
            return ExpelHarm

        elseif energy > 80 and IsReadyInCombo(TigerPalm) and chimax - chi >= 2 then
            return TigerPalm

        elseif IsAvailableInCombo(WhirlingDragonPunch) then
            return WhirlingDragonPunch

        elseif IsAvailableInCombo(FistsOfFury) and timetocap > 2.9 then
            return FistsOfFury

        -- elseif isConcentratedFlameKnown and IsAvailableInCombo(ConcentratedFlame) then
        --     return ConcentratedFlame
        elseif IsAvailableInCombo(RisingSunKick) then
            return RisingSunKick

        elseif isChiBurstKnown and IsAvailableInCombo(ChiBurst) then
            return ChiBurst

        elseif IsAvailableInCombo(SpinningCraneKick) and IsBuffUp(DanceOfChiJi) and timetocap > 1.5 then
            return DanceOfChiJi

        elseif isExpelHarmKnown and IsReadyInCombo(ExpelHarm) and chimax - chi >= 1 then
            return ExpelHarm

        elseif isFistOfTheWhiteTigerKnown and IsReadyInCombo(FistOfTheWhiteTiger) and chimax - chi >= 3 then
            return FistOfTheWhiteTiger

        elseif IsAvailableInCombo(BlackoutKick) and
            (isFreeBlackout or not RSKSoon or chi >= 3) and
            (isFreeBlackout or not FOFSoon or chi >= 4)
        then
            return BlackoutKick
        elseif IsReadyInCombo(TigerPalm) and chimax - chi >= 2 then  -- to prioritize spending move below blackout kick
            return TigerPalm



        elseif IsAvailableInCombo(BlackoutKick) then
            return BlackoutKick
        elseif IsReadyInCombo(TigerPalm) then
            return TigerPalm
        end

    end


    local WindwalkerMultiTarget = function()
        local chi = UnitPower("player", ENUM_CHI)
        local chimax = UnitPowerMax("player", ENUM_CHI)
        local energy = UnitPower("player")
        local energyMax = UnitPowerMax("player")
        local health = UnitHealth("player")
        local healthMax = UnitHealthMax("player")
        local healthPercent = health/healthMax
        local WDPSoon = GetCooldown(WhirlingDragonPunch) < 6
        -- local FOFSoon = GetCooldown(FistsOfFury) < 6
        local FoFCD = GetCooldown(FistsOfFury)
        -- local RSKSoon = GetCooldown(RisingSunKick) < 3
        local haste = UnitSpellHaste("player")
        local regen = (100+haste)/10  -- energy per second
        local timetocap = ((energyMax - 10) - energy) / regen

        local isFreeBlackout = IsBuffUp(FreeBlackoutKick)

        if timetocap < 2 and IsReadyInCombo(ExpelHarm) and chimax - chi >= 1 then
            return ExpelHarm

        elseif timetocap < 2 and isFistOfTheWhiteTigerKnown and IsReadyInCombo(FistOfTheWhiteTiger) and chimax - chi >= 3 then
            return FistOfTheWhiteTiger

        elseif timetocap < 2 and IsReadyInCombo(TigerPalm) and chimax - chi >= 2 then
            return TigerPalm

        elseif IsAvailableInCombo(WhirlingDragonPunch) then
            return WhirlingDragonPunch

        elseif IsAvailableInCombo(SpinningCraneKick) and IsBuffUp(DanceOfChiJi) and timetocap > 1.5 then
            return DanceOfChiJi

        elseif IsAvailableInCombo(FistsOfFury) and timetocap > 2.9 then
            return FistsOfFury

        elseif WDPSoon and IsAvailableInCombo(RisingSunKick) then
            return RisingSunKick

        elseif isExpelHarmKnown and IsReadyInCombo(ExpelHarm) and chimax - chi >= 1 then
            return ExpelHarm

        elseif isChiBurstKnown and IsAvailableInCombo(ChiBurst) and chimax - chi >= 1 then
            return ChiBurst

        elseif IsAvailableInCombo(SpinningCraneKick) and timetocap > 2.5 and
            (chi >= 3 or FoFCD > 6) and
            (chi >= 5 or FoFCD > 2)
        then
            return SpinningCraneKick

        elseif IsAvailableInCombo(BlackoutKick) and isFreeBlackout then
            return BlackoutKick

        elseif IsAvailableInCombo(RisingSunKick) then
            return RisingSunKick

        elseif isFistOfTheWhiteTigerKnown and IsReadyInCombo(FistOfTheWhiteTiger) and chimax - chi >= 3 then
            return FistOfTheWhiteTiger

        elseif IsReadyInCombo(TigerPalm) then
            return TigerPalm

        -- elseif IsAvailableInCombo(BlackoutKick) then
        --     return BlackoutKick

        end

    end

    return function()
        if isAOE then
            return WindwalkerMultiTarget()
        else
            return WindwalkerSingleTarget()
        end
    end
end

function NugReady.UNIT_SPELLCAST_SUCCEEDED(self, event, unit, lineID, spellID)
    -- print(event, unit, spell, rank, lineID, spellID)
    if IsPlayerSpell(spellID) then
        LastUsedAbility = spellID
    end
end


local KegSmash = 121253
local BlackoutStrike = 205523
local BlackoutComboTalent = 196736
local BlackoutCombo = 228563
local RushingJadeWind = 116847
local BreathOfFire = 115181
local IronskinBrew = 115308

-- local return (1.5/(1+(UnitSpellHaste("player")/100)))

local function window(cd, pos, wlen)
    return cd > pos and cd < pos + wlen
end

local function BrewmasterBlackout()
    local IsBlackoutComboOn = GetBuff("player", BlackoutCombo)
    local energy = UnitPower("player")
    local maxenergy = UnitPowerMax("player")
    local KegSmashCD = GetCooldown(KegSmash)
    local BlackoutStrikeCD = GetCooldown(BlackoutStrike)
    local charges, maxcharges = GetSpellCharges(IronskinBrew)
    local haste = UnitSpellHaste("player")
    local regen = (100+haste)/10  -- energy per second
    local timetocap = ((maxenergy - 10) - energy) / regen
    local bscdlen = 3/(1+(haste/100))
    if timetocap < 0 then timetocap = 0 end

    -- print(KegSmashCD - BlackoutStrikeCD)

    if IsBlackoutComboOn and KegSmashCD < 1.7 then
        return KegSmash
    elseif not IsBlackoutComboOn and window(KegSmashCD, 1, 1) or window(KegSmashCD, 1+bscdlen, 1) and IsReadySpell(BlackoutStrike) then
        return BlackoutStrike
    -- elseif not IsBlackoutComboOn and KegSmashCD < 3 and (KegSmashCD - BlackoutStrikeCD > 0) then
        -- return BlackoutStrike
    elseif IsReadySpell(KegSmash) then
        return KegSmash
    -- elseif not IsBlackoutComboOn and IsReadySpell(BlackoutStrike) and energy < 70 then
    --     return BlackoutStrike
    elseif IsBlackoutComboOn and IsReadySpell(BreathOfFire) then
        return BreathOfFire
    elseif IsAvailable(TigerPalm) then
        local KSEnergyTime = ( 45 - (energy - 25) ) / regen
        if KegSmashCD < KSEnergyTime then
            return KegSmash
        else
            return TigerPalm
        end
    -- elseif IsAvailable(RushingJadeWind) then
        -- return RushingJadeWind
    -- elseif IsAvailable(BreathOfFire) then
        -- return BreathOfFire
    else
        return 7812
    end
end


local LastTimeUsedRJW = 0

local function Brewmaster()
    local energy = UnitPower("player")
    local haste = UnitSpellHaste("player")
    local regen = (100+haste)/10  -- energy per second

    local KegSmashCD = GetCooldown(KegSmash)
    -- local BlackoutCD = GetCooldown(BlackoutStrike)
    -- local KegSmashCharges, KegSmashMaxCharges = GetSpellCharges(KegSmash)
    -- local charges, maxcharges = GetSpellCharges(IronskinBrew)

    -- if LastUsedAbility == RushingJadeWind then
    --     LastTimeUsedRJW = GetTime()
    -- end

    -- local isAOE = (LastTimeUsedRJW + 13 > GetTime())

    if IsReadySpell(KegSmash) then
        return KegSmash
    elseif IsAvailable(TigerPalm) and energy >= 75 then
        return TigerPalm
    elseif IsAvailable(BlackoutStrike) then
        return BlackoutStrike
    elseif IsAvailable(BreathOfFire) then
        return BreathOfFire
    elseif IsAvailable(RushingJadeWind) then
        return RushingJadeWind
    elseif IsAvailable(TigerPalm) then
        local KSEnergyTime = ( 45 - (energy - 25) ) / regen
        if KegSmashCD < KSEnergyTime then
            return KegSmash
        else
            return TigerPalm
        end

    -- elseif IsReadySpell(BreathOfFire) then
        -- return BreathOfFire
        -- elseif IsAvailable(RushingJadeWind) then
            -- return RushingJadeWind
    else
        return 7812
    end
end

local Zeal = 217020
local TemplarsVerdict = 85256
local BladeOfJustice = 184575
local Judgement = 20271

local function Retribution()
    local IsJudgementOn = GetDebuff("target", 197277)
    local hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
    -- local KegSmashCD = GetCooldown(KegSmash)
    local ZealCharges = GetSpellCharges(Zeal)
    -- local charges, maxcharges = GetSpellCharges(IronskinBrew)

    if hp <= 4 and ZealCharges >= 2 then
        return Zeal
    elseif hp <= 3 and IsReadySpell(BladeOfJustice) then
        return BladeOfJustice
    elseif IsJudgementOn and hp >= 3 then
        return TemplarsVerdict
    elseif hp <= 4 and ZealCharges >= 1 then
        return Zeal
    elseif IsReadySpell(Judgement) then
        return Judgement
    else
        return 7812
    end
end

local Rake = 1822
local RakeDebuff = 155722
local Rip = 1079
local Shred = 5221
local BrutalSlash = 202028
local FerociousBite = 22568
local Bloodtalons = 145152
local PredatorySwiftness = 69369
local Regrowth = 8936
local TigersFury = 5217
local SavageRoar = 52610
local FeralFrenzy = 274837

local math_max = math.max
local ENUM_CP = Enum.PowerType.ComboPoints


local function FeralSetup()
    local isSavageRoarKnown = IsPlayerSpell(SavageRoar)
    local SavageRoarRefreshWindow = 36*0.3
    local SavageRoarRemains, SavageRoarNeedsRefreshing

    local isSabertoothKnown = IsPlayerSpell(202031)

    local isJaggedWounds = IsPlayerSpell(202032)
    local jwm = isJaggedWounds and 0.8 or 1
    local RakeRefreshWindow = 15*jwm*0.3
    local RipRefreshWindow = 24*jwm*0.3

    local isBrutalSlashKnown = IsPlayerSpell(BrutalSlash)
    local BrutalSlashCharges, BrutalSlashMaxCharges

    local isFeralFrenzyKnown = IsPlayerSpell(FeralFrenzy)

    local isBloodtalonsKnown = IsPlayerSpell(155672)

    return function()
        local RipRemains = GetDebuff("target", Rip) or 0
        local RakeRemains = GetDebuff("target", RakeDebuff) or 0
        local isPredatorySwiftnessOn = GetBuff("player", PredatorySwiftness)
        -- local _, BloodtalonsCount = GetBuff("player", Bloodtalons)
        if isSavageRoarKnown then
            SavageRoarRemains = GetBuff("player", SavageRoar) or 0
            SavageRoarNeedsRefreshing = SavageRoarRemains <= SavageRoarRefreshWindow
        end

        if isBrutalSlashKnown then
            BrutalSlashCharges, BrutalSlashMaxCharges = GetSpellCharges(BrutalSlash)
        end

        local cp = UnitPower("player", ENUM_CP )
        local energy = UnitPower("player")
        local haste = UnitSpellHaste("player")
        local regen = (100+haste)/10  -- energy per second
        local ttc = (90-energy)/regen
        local isExecutePhase = false
        if UnitExists('target') then
            local h, hm = UnitHealth("target"), UnitHealthMax("target")
            if hm == 0 then hm = 1 end
            isExecutePhase = h/hm < 0.25
        end

        local RakeNeedsRefreshing = RakeRemains <= RakeRefreshWindow + math_max(ttc - 2, 0)
        local RakeNeedsRefreshingALittle = RakeNeedsRefreshing  and RakeRemains > 2.5
        local RipNeedsRefreshing =  RipRemains <= RipRefreshWindow + math_max(ttc - 2, 0)
        local RipNeedsRefreshingWithTigersFury = RipRemains <= RipRefreshWindow + 6

        if isBloodtalonsKnown and cp >= (RakeNeedsRefreshing and 4 or 5) and isPredatorySwiftnessOn then
            return Regrowth

        elseif energy <= 30 and IsAvailable(TigersFury) and RipNeedsRefreshingWithTigersFury then
            return TigersFury

        elseif isFeralFrenzyKnown and cp == 0 and IsAvailable(FeralFrenzy) then
            return FeralFrenzy

        elseif RipNeedsRefreshing and cp == 5 then
            return (isExecutePhase or isSabertoothKnown) and FerociousBite or Rip

        elseif RakeNeedsRefreshingALittle and cp == 2 or cp == 3 then
            return Shred

        elseif RakeNeedsRefreshing and cp <= 4 then
            return Rake

        elseif isSavageRoarKnown and SavageRoarNeedsRefreshing and cp == 5 then
            return SavageRoar


        elseif cp == 5 then
            return FerociousBite


        elseif isBrutalSlashKnown and BrutalSlashCharges >= 2 and IsAvailable2(BrutalSlash) then
            return BrutalSlash


        elseif IsAvailable(Shred) then
            return Shred
        else
            return 7812
        end
    end
end


local DecideCurrentAction = Retribution

local _elapsed = 0
function NugReady_OnUpdate(self, time)
    _elapsed = _elapsed + time
    if _elapsed < 0.1 then return end


    local spellID, condition = DecideCurrentAction()
    if NugActionBar then NugActionBar:HighlightSpell(spellID) end
    local texture = GetSpellTexture(spellID)
    if condition then
        self.text:SetText(condition)
    end
    self.icon:SetTexture(texture)
end

local MakeBorder = function(self, tex, left, right, top, bottom, level)
    local t = self:CreateTexture(nil,"BORDER",nil,level)
    t:SetTexture(tex)
    t:SetPoint("TOPLEFT", self, "TOPLEFT", left, -top)
    t:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -right, bottom)
    return t
end

function NugReady.CreateIcon(self, parent)
    -- local f = CreateFrame("Frame", nil, parent)
    local f = self
    local width = 35
    local height = 35
    f:SetWidth(width); f:SetHeight(height);
    f:SetPoint("CENTER","UIParent","CENTER",NugReadyDB.posX, NugReadyDB.posY)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(.1, .9, .1, .9)
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_SacrificialShield")
    icon:SetWidth(height)
    icon:SetHeight(height)
    icon:SetPoint("TOP", 0, 0)
    icon:SetPoint("LEFT", 0, 0)
    f.icon = icon

    -- local cross = f:CreateTexture(nil, "ARTWORK", nil, 1)
    -- cross:SetTexture[[Interface\PetBattles\DeadPetIcon]]--[[Interface\AddOns\NugReady\cross]]
    -- -- cross:SetPoint("CENTER", icon, "CENTER",0,0)
    -- -- cross:SetWidth(height/2)
    -- -- cross:SetHeight(height/2)
    -- cross:SetAllPoints(icon)
    -- cross:SetVertexColor(1,0,0, 0.8)
    -- cross:Hide()
    -- f.cross = cross

    -- f.SetFailed = function(self, enable)
    --     if enable then
    --         self.cross:Show()
    --         self.icon:SetVertexColor(0.3, 0.3, 0.3)
    --     else
    --         self.cross:Hide()
    --         self.icon:SetVertexColor(1,1,1)
    --     end
    -- end

    -- local backdrop = {
    --     bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    --     tile = true, tileSize = 0,
    --     insets = {left = -2, right = -2, top = -2, bottom = -2},
    -- }
    -- f:SetBackdrop(backdrop)
    -- f:SetBackdropColor(0, 0, 0, 0.7)
    local border = 1

    local outline = MakeBorder(f, "Interface\\BUTTONS\\WHITE8X8", -border, -border, -border, -border, -2)
    outline:SetVertexColor(0,0,0)


        local text = f:CreateFontString(nil, "OVERLAY")
        local font = [[Interface\AddOns\NugEnergy\Emblem.ttf]]
        local fontSize = 25
        text:SetFont(font,fontSize)
        text:SetPoint("RIGHT", f, "LEFT", -10, 0)
        f.text = text


    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:EnableMouse(false)

    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
            self:StopMovingOrSizing();
            _,_, NugReadyDB.point,  NugReadyDB.posX, NugReadyDB.posY = self:GetPoint(1)
    end)

    f:SetScript("OnUpdate", NugReady_OnUpdate)

    f:Hide()

    return f
end

function NugReady:CreateAnchor()
    local f = CreateFrame("Frame","NugThreatAnchor",UIParent)
    f:SetHeight(20)
    f:SetWidth(20)
    f:SetPoint("CENTER","UIParent","CENTER",NugReadyDB.posX, NugReadyDB.posY)

    f:RegisterForDrag("LeftButton")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:Hide()

    local t = f:CreateTexture(f:GetName().."Icon1","BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0,0.25,0,1)
    t:SetAllPoints(f)

    t = f:CreateTexture(f:GetName().."Icon","BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0.25,0.49,0,1)
    t:SetVertexColor(1, 0, 0)
    t:SetAllPoints(f)

    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
            self:StopMovingOrSizing();
            _,_, NugReadyDB.point,  NugReadyDB.x, NugReadyDB.y = self:GetPoint(1)
    end)
    return f
end


function NugReady:SPELLS_CHANGED()
    local _, class = UnitClass('player')
    local spec = GetSpecialization()
    self.disabled = false
    RangeCheck:Configure(nil, nil)
    if class == "WARRIOR" then
        if spec == 2 then
            DecideCurrentAction = FurySetup()
        elseif spec == 1 then
            DecideCurrentAction = ArmsSetup()
        else
            self.disabled = true
            self:Hide()
        end
    elseif class == "MONK" then
        if spec == 3 then
            DecideCurrentAction = WindwalkerSetup()
        elseif spec == 1 then
            if IsPlayerSpell(196736) then
                DecideCurrentAction = BrewmasterBlackout
            else
                DecideCurrentAction = Brewmaster
            end
        else
            self.disabled = true
            self:Hide()
        end
    elseif class == "DRUID" then
        if spec == 2 then
            DecideCurrentAction = FeralSetup()
        else
            self.disabled = true
            self:Hide()
        end
    elseif class == "PALADIN" then
        if spec == 3 then
            DecideCurrentAction = Retribution
        -- elseif spec == 1 then
        --     if IsPlayerSpell(196736) then
        --         DecideCurrentAction = BrewmasterBlackout
        --     else
        --         DecideCurrentAction = Brewmaster
        --     end
        else
            self.disabled = true
            self:Hide()
        end
    else
        self.disabled = true
        self:Hide()
    end

    if not rangeCheckSpellName then
        RangeCheck:Disable()
    end
end

function NugReady:PLAYER_REGEN_DISABLED()
    if self.disabled then self:Hide(); return end

    RangeCheck:Enable()
    self:Show()
end

function NugReady:PLAYER_REGEN_ENABLED()
    RangeCheck:Disable()
    self:Hide()
end
