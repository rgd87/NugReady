local NugReady = CreateFrame("Frame", "NugReady", UIParent)

NugReady:SetScript("OnEvent", function(self, event, ...)
    -- print(GetTime(), event, unpack{...})
    return self[event](self, event, ...)
end)

NugReady:RegisterEvent("ADDON_LOADED")

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


local function GetBuff(unit, spellID)
    local name, _,_, count, _, duration, expirationTime, caster, _,_, aura_spellID = UnitAura(unit, GetSpellInfo(spellID), nil, "HELPFUL")
    if not name then return nil, 0 end
    return expirationTime - GetTime(), count
end

local function GetDebuff(unit, spellID)
    local name, _,_, count, _, duration, expirationTime, caster, _,_, aura_spellID = UnitAura(unit, GetSpellInfo(spellID), nil, "HARMFUL")
    if not name then return nil, 0 end
    return expirationTime - GetTime(), count
end

local function GetCooldown(spellID)
    local startTime, duration, enabled = GetSpellCooldown(spellID)
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
    local startTime, duration, enabled = GetSpellCooldown(spellID)
    if duration == 0 then return true end

    local remains = (startTime + duration) - GetTime()

    if (spellID == 205523) then
        READYSPELL.name = GetSpellInfo(spellID)
        READYSPELL.remains = remains
        READYSPELL.gcd = GCD
        READYSPELL.condition = remains <= GCD
    end

    if remains <= GCD+0.05 then return true end
    return false
end

ISREADYSPELL = IsReadySpell

function IsAvailable(spellID)
    return IsUsableSpell(spellID) and IsReadySpell(spellID)
end

local Enrage = 184362
local function IsEnraged()
    local name = UnitAura("player", GetSpellInfo(Enrage), nil, "HELPFUL")
    return name
end

local Rampage = 184367
local OdynsFury = 205545
local Execute = 5308
local RagingBlow = 85288
local Bloodthirst = 23881
local DragonRoar = 118000
local FuriousSlash = 100130

local function Fury()
    local isEnraged = IsEnraged()
    local rage = UnitPower("player", "RAGE")

    if IsAvailable(DragonRoar) then
        return DragonRoar
    elseif IsAvailable(Rampage) and (not isEnraged or rage == 100) then
        return Rampage
    elseif not isEnraged and IsReadySpell(Bloodthirst) then
        return Bloodthirst
    elseif IsAvailable(OdynsFury) then
        return OdynsFury
    elseif IsUsableSpell(Execute) and isEnraged then
        return Execute
    elseif IsAvailable(RagingBlow) then
        return RagingBlow
    elseif IsAvailable(Bloodthirst) then
        return Bloodthirst
    else
        return FuriousSlash
    end
end

local ColossusSmash = 167105
local Warbreaker = 209577
local MortalStrike = 12294
local FocusedRage = 207982
local Slam = 1464

local function Arms()
    local _, FocusedRageStacks = GetBuff("player", FocusedRage)
    local MortalStrikeCooldown = GetCooldown(MortalStrike)

    local IsColossusSmashApplied = false
    if UnitExists("target") then
        local remains = GetDebuff("target", 208086)
        IsColossusSmashApplied = remains or 0 > 1.5
    end

    if IsAvailable(ColossusSmash) and not IsColossusSmashApplied then
        return ColossusSmash
    elseif IsAvailable(Warbreaker) and not IsColossusSmashApplied and MortalStrikeCooldown < 2.5 then
        return Warbreaker
    elseif IsReadySpell(MortalStrike) then
        return MortalStrike
    elseif IsAvailable(FocusedRage) and FocusedRageStacks < 3 then
        return FocusedRage
    elseif IsAvailable(Slam) and FocusedRageStacks == 3 then
        return Slam
    else
        return 7812
    end
end

local FistsOfFury = 113656
local StrikeOfTheWindlord = 205320
local WhirlingDragonPunch = 152175
local TigerPalm = 100780
local RisingSunKick = 107428
local BlackoutKick = 100784

local LastUsedAbility
local IsAvailableInCombo = function(spellID)
    if spellID == LastUsedAbility then
        return false
    else
        return IsAvailable(spellID)
    end
end

local function Windwalker()
    local chi = UnitPower("player", SPELL_POWER_CHI)
    local energy = UnitPower("player")
    local energyMax = UnitPowerMax("player")

    if IsAvailableInCombo(FistsOfFury) then
        return FistsOfFury
    elseif IsAvailableInCombo(StrikeOfTheWindlord) then
        return StrikeOfTheWindlord
    elseif IsAvailableInCombo(WhirlingDragonPunch) then
        return WhirlingDragonPunch
    elseif IsAvailableInCombo(TigerPalm) and chi <= 3 then
        return TigerPalm
    elseif IsAvailableInCombo(RisingSunKick) then
        return RisingSunKick
    elseif IsAvailableInCombo(BlackoutKick) then
        return BlackoutKick
    else
        return TigerPalm
    end
end

function NugReady.UNIT_SPELLCAST_SUCCEEDED(self, event, unit, spell, rank, lineID, spellID)
    -- print(event, unit, spell, rank, lineID, spellID)
    LastUsedAbility = spellID
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
        -- print(KegSmashCD, KSEnergyTime)
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

local function Brewmaster()
    local energy = UnitPower("player")
    local haste = UnitSpellHaste("player")
    local regen = (100+haste)/10  -- energy per second

    local KegSmashCD = GetCooldown(KegSmash)
    -- local charges, maxcharges = GetSpellCharges(IronskinBrew)

    if IsReadySpell(KegSmash) then
        return KegSmash
    elseif IsAvailable(TigerPalm) and energy > 55 then
        return TigerPalm
    -- elseif KegSmashCD < 1.5 and IsBlackoutComboOn then
    --     return KegSmash, 3
    elseif IsReadySpell(BlackoutStrike) then
        return BlackoutStrike
    -- elseif IsReadySpell(BreathOfFire) then
        -- return BreathOfFire
        -- elseif IsAvailable(RushingJadeWind) then
            -- return RushingJadeWind
    else
        return 7812
    end
end


local DecideCurrentAction = Windwalker

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


function NugReady.CreateIcon(self, parent)
    -- local f = CreateFrame("Frame", nil, parent)
    local f = self
    local width = 40
    local height = 40
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

    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true, tileSize = 0,
        insets = {left = -2, right = -2, top = -2, bottom = -2},
    }
    f:SetBackdrop(backdrop)
    f:SetBackdropColor(0, 0, 0, 0.7)


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
    if class == "WARRIOR" then
        if spec == 2 then
            DecideCurrentAction = Fury
        elseif spec == 1 then
            DecideCurrentAction = Arms
        else
            self.disabled = true
            self:Hide()
        end
    elseif class == "MONK" then
        if spec == 3 then
            DecideCurrentAction = Windwalker
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
    else
        self.disabled = true
        self:Hide()
    end
end

function NugReady:PLAYER_REGEN_DISABLED()
    if self.disabled then self:Hide(); return end

    self:Show()
end

function NugReady:PLAYER_REGEN_ENABLED()
    self:Hide()
end
