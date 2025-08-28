local function print(...)
	for i=1,select('#',...) do
		local x = select(i,...)
		if x == nil then
			x = "nil"
		end
		ChatFrame1:AddMessage("|cff33ff99 ShowMeBuff|r: " .. x)
	end
end

-- Utils
local function array_contains(tab, val)
	-- V: no value given
	if not tab then return false end

    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local name, o = ...

smbDefaults = {
	buffOverDebuffs = true,
	buffs = {
		hideNames = {
			46705, --"Honorless Target",
			32727, --"Arena Preparation",
			32728, --"Arena Preparation",
			33795, --"Strength of the Halaani",
			57940, --"Essence of Wintergrasp",
			67759, --"Shard of Flame"
			44521, --"Preparation"
			--procs - keep powerful ones
			67750, -- "Energized", -- solace
			72416, -- Frostforged Sage,  ICC caster ring
			50402, -- Frostforged Champion, ICC melee ring
			55637, --"Lightweave", -- tailor back
			59626, -- Black Magic
			--Priest
			47515, -- "Divine Aegis",
			63944, -- "Renewed Hope",
			15363, -- "Inspiration",
			45244, -- "Focused Will",
			52800, -- "Borrowed Time",
			--Mage
			57669, --"Replenishment",
			--Lock
			47891, --"Shadow Ward",
			48018, --"Demonic Circle: Summon",
			57567, --"Fel Intelligence",
			--"Soul Link", -- keep it ?
			47260, --"Backdraft", -- same ?
			--"Backlash",
			--"Nether Protection",
			47197, --"Eradication",
			--"Shadow Trance",
			--Druid
			71184, --"Soothing", -- rdruid idol
			16246, --"Clearcasting",
			48412, --"Master Shapeshifter",
			33883, --"Natural Perfection",
			--Hunt
			61847, --"Aspect of the Dragonhawk",
			19506, --"Trueshot Aura",
			52858, --"Culling the Herd",
			--Pal
			32223, --"Crusader Aura"
		},
		hideInfinite = false,
		hideMounts = true,
		hideConsolidated = true,
		hideDuration = 600, -- 10min
		hideFiltered = true,
		hideNonPlayer = false,
		onlyCastable = false,

		numLines = 18,
		numPerLine = 6,
		buffSize = 15,
		playerBuffOffsetY = -67,
		playerBuffOffsetX = 110,
		growUpwards = false,
	},
	debuffs = {
		hideNames = {
			26013, -- Deserter
			-- War
			46857, -- Trauma
			30070, -- Blood Frenzy
			-- Rogue
			48660, -- Hemorrhage
			-- Warlock
			29341, --"Shadowburn",
		},
		hideFiltered = true,

		numLines = 18,
		numPerLine = 6,
		buffSize = 15,
		playerDebuffOffsetY = -100,
		playerDebuffOffsetX = -110,
	},
	debug = false,
	version = 1,
}

local mountIds = {
	17229, -- Winterspring Frostsaber
	60114, -- Armored Brown Bear
	60116, -- Armored Brown Bear
	72286, -- Invincible
	46628, -- Swift White Hawkstrider
	23338, -- Swift Stormsaber
	23219, -- Swift Mistsaber
	71342, -- Big Love Rocket
}

-- Returns info about weapon enchants using direct API calls (3.3.5 safe)
local function GetWeaponEnchantInfoByID()
    local mhTimeLeft, mhDuration, mhExpiration, ohTimeLeft, ohDuration, ohExpiration = GetWeaponEnchantInfo()
    local result = {}

    -- Spell icons for common enchants (fallbacks)
    local enchantIcons = {
        WINDFURY = "Interface\\Icons\\Spell_Nature_Windfury",
        FLAMETONGUE = "Interface\\Icons\\Spell_Fire_FlameTounge",
        FROSTBRAND = "Interface\\Icons\\Spell_Frost_FrostWeapon",
        EARTHLIVING = "Interface\\Icons\\Spell_Nature_EarthLiving",
        SHADOW_POWER = "Interface\\Icons\\Spell_Shadow_ShadowPact",
    }

    -- Main hand
    if mhDuration and mhDuration > 0 then
        local texture = GetInventoryItemTexture("player", 16)  -- 16 = main hand
        if not texture then
            texture = enchantIcons.WINDFURY  -- Fallback
        end
        table.insert(result, {
            name = "Main Hand Enchant",
            icon = texture,
            count = 0,
            debuffType = 0,
            duration = mhDuration / 1000,
            expirationTime = GetTime() + (mhTimeLeft / 1000),
            unitCaster = "player",
            spellId = 0,
            isStealable = false,
            shouldConsolidate = false,
            nameplateShowAll = false,
            timeMod = 0
        })
    end

    -- Off hand
    if ohDuration and ohDuration > 0 then
        local texture = GetInventoryItemTexture("player", 17)  -- 17 = off hand
        if not texture then
            texture = enchantIcons.FLAMETONGUE  -- Fallback
        end
        table.insert(result, {
            name = "Off Hand Enchant",
            icon = texture,
            count = 0,
            debuffType = 0,
            duration = ohDuration / 1000,
            expirationTime = GetTime() + (ohTimeLeft / 1000),
            unitCaster = "player",
            spellId = 0,
            isStealable = false,
            shouldConsolidate = false,
            nameplateShowAll = false,
            timeMod = 0
        })
    end

    return result
end

-- BUFFS
local function ShowThisBuff(rules, name, spellId, duration, expirationTime, unitCaster, shouldConsolidate)
	--print(name, debuffType, duration, expirationTime, "--")
	if rules.hideConsolidated and shouldConsolidate then
		-- consolidated buff
		--print(name..": consolidated")
		return
	end
	if rules.hideInfinite and expirationTime == 0 then
		-- infinite debuff
		--print(name..": infinite")
		return
	end
	if rules.hideFiltered and array_contains(rules.hideNames, name) then
		-- buff explicitly ignored
		--print(name..": ignored")
		return
	end
	if rules.hideNonPlayer and unitCaster ~= "player" then
		-- buff not casted by a player
		return
	end
	if rules.hideDuration and duration >= rules.hideDuration then
		-- buff too long
		--print(name..": "..duration.." too long")
		return
	end
	if rules.hideMounts and array_contains(mountIds, spellId) then
		-- mount buff
		--print(name..": mount")
		return
	end
	--print(name, duration, "ok")
	return true
end

-- V: Copy-pasted then modified
local function RefreshBuffsList(frame, friendly, unit, rules, checker)
	local numBuffs = rules.numLines * rules.numPerLine
	-- TODO detect suffix from isFriendly(unit)?
	local framePrefix = frame:GetName()..(friendly and "Buff" or "Debuff")
	local buffFn = friendly and UnitBuff or UnitDebuff

	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId;
	local buffI = 1

	-- Add weapon enchants first (they are not returned by UnitBuff)
	if unit == "player" and friendly then
		local enchants = GetWeaponEnchantInfoByID()
		for _, buff in ipairs(enchants) do
			if checker(rules, buff.name, buff.spellId, buff.duration, buff.expirationTime, buff.unitCaster, buff.shouldConsolidate) then
				local buffName = framePrefix .. buffI
				local c = _G[buffName]

				if c and buff.icon then
					local icon = _G[buffName.."Icon"]
					icon:SetTexture(buff.icon)

					local cooldown = _G[buffName.."Cooldown"]
					if cooldown then
						CooldownFrame_SetTimer(cooldown, buff.expirationTime - buff.duration, buff.duration, 1)
					end
					c:Show()
				end
				buffI = buffI + 1
			end
		end
	end
	
	
	local filter = rules.onlyCastable and friendly and "PLAYER" -- TODO use isFriendly() for "RAID" or not?
	for i=1, numBuffs do
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = buffFn(unit, i, filter)

		-- we ran out of buffs OR we have enough displayed
		if not name or buffI > numBuffs then
			break -- could even return
		end

		if checker(rules, name, spellId, duration, expirationTime, unitCaster, friendly and shouldConsolidate) then
			local buffName = framePrefix..buffI
			if ( icon ) then
				-- if we have an icon to show then proceed with setting up the aura

				-- set the icon
				local buffIcon = _G[buffName.."Icon"]
				buffIcon:SetTexture(icon)

				-- setup the cooldown
				local cooldown = _G[buffName.."Cooldown"]
				if cooldown then
					CooldownFrame_SetTimer(cooldown, expirationTime - duration, duration, 1)
				end

				-- show the aura
				_G[buffName]:Show()
			else
				-- no icon, hide the aura
				_G[buffName]:Hide()
			end
			buffI = buffI + 1
		end
	end

	-- hide all remaining buff frames
	-- "buffI" here is already 1 past the last displayed buff
	for i=buffI, 40 do
		local buffName = framePrefix..i
		_G[buffName]:Hide()
	end
end

function LoadUnitBuffs(rules, pointX, pointY, f)
    local g = f.smbBuffFrame
    if not g then
        f:UnregisterEvent("UNIT_AURA")
        g = CreateFrame("Frame")
        f.smbBuffFrame = g
        g:RegisterEvent("UNIT_AURA")
        g:SetScript("OnEvent", function(self, event, a1)
            if a1 == f.unit then
                RefreshBuffsList(f, true, f.unit, rules, ShowThisBuff)
            end
        end)
    end

    local framePrefix = f:GetName() .. "Buff"
    local buffSize = rules.buffSize
    local perLine = rules.numPerLine
    local totalBuffs = rules.numLines * perLine

    -- We'll create all frames first
    for j = 1, 40 do
        local n = framePrefix .. j
        local c = _G[n] or CreateFrame("Frame", n, f, "TargetBuffFrameTemplate")
        c:SetSize(buffSize, buffSize)
        c:ClearAllPoints()
        c:Hide()
        c:EnableMouse(false)

        -- Create or reuse cooldown
        local cd = _G[n .. "Cooldown"]
        if not cd then
            cd = CreateFrame("Cooldown", n .. "Cooldown", c, "CooldownFrameTemplate")
            cd:SetReverse(false)
            cd:SetAllPoints()
        end
    end

    -- Now position them based on growUpwards
    if rules.growUpwards then
        -- Grow upward: last buff at bottom, fill backwards
        local total = math.min(totalBuffs, 40)
        local startI = total

        for j = 1, total do
            local n = framePrefix .. j
            local c = _G[n]
            if j == 1 then
                -- Bottom-left of the block
                c:SetPoint("BOTTOMLEFT", pointX, pointY)
            elseif (j - 1) % perLine == 0 then
                -- New line above
                local ref = _G[framePrefix .. (j - perLine)]
                c:SetPoint("BOTTOMLEFT", ref, "TOPLEFT", 0, 1)
            else
                -- Next in row
                local ref = _G[framePrefix .. (j - 1)]
                c:SetPoint("LEFT", ref, "RIGHT", 1, 0)
            end
        end
    else
        -- Default: grow downward
        for j = 1, 40 do
            local n = framePrefix .. j
            local c = _G[n]
            if j == 1 then
                c:SetPoint("TOPLEFT", pointX, pointY)
            elseif (j - 1) % perLine == 0 then
                local ref = _G[framePrefix .. (j - perLine)]
                c:SetPoint("TOPLEFT", ref, "BOTTOMLEFT", 0, -1)
            else
                local ref = _G[framePrefix .. (j - 1)]
                c:SetPoint("LEFT", ref, "RIGHT", 1, 0)
            end
        end
    end

    RefreshBuffsList(f, true, f.unit, rules, ShowThisBuff)
end

-- DEBUFFS
local function LoadUnitDebuffs(rules, pointX, pointY, f)
	local g = f.smbDebuffFrame
	if not g then
		f:UnregisterEvent("UNIT_AURA")
		g = CreateFrame("Frame")
		f.smbDebuffFrame = g
		g:RegisterEvent("UNIT_AURA")
		g:SetScript("OnEvent",function(self,event,a1)
			if a1 == f.unit then
				RefreshBuffsList(f, false, f.unit, rules, ShowThisBuff)
			elseif a1 == f.unit.."pet" then
				-- V: todo integrate lawz's code
				--PartyMemberFrame_RefreshPetDebuffs(f)
			end
		end)
	end
	for j=1, 40 do
		local l = f:GetName().."Debuff"
		local n = l..j
		local c = _G[n] or CreateFrame("Frame",n,f,"PartyDebuffFrameTemplate")
		c:ClearAllPoints()
		if j == 1 then
			--c:SetPoint("BOTTOMLEFT", _G[l..(j-1)],"BOTTOMRIGHT", 3, 0)
			--c:SetPoint("TOPLEFT",pointX,pointY)
		elseif ((j - 1) % rules.numPerLine) == 0 then
			c:SetPoint("TOPLEFT",_G[l..(j - rules.numPerLine)],"BOTTOMLEFT", 0, -1)
		else
			c:SetPoint("LEFT",_G[l..(j-1)],"RIGHT",1,0)
		end
		c:SetSize(rules.buffSize, rules.buffSize)
		c:Hide()

		-- V: we need to specifically create a cooldown frame inside of "c"
		--    because PartyDebuffFrameTemplate has none
		local cd = _G[n.."Cooldown"]
		if not cd then
			cd = CreateFrame("Cooldown",n.."Cooldown",c,"CooldownFrameTemplate")
			cd:SetReverse(true)
			--cd:SetDrawEdge(true)
			cd:SetSize(rules.buffSize, rules.buffSize) -- ← Was 20, now dynamic
			cd:SetPoint("CENTER", 0, -1)
		end
	end
	local b = _G[f:GetName().."Debuff1"]
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT", pointX, pointY)
	RefreshBuffsList(f, false, f.unit, rules, ShowThisBuff)
end

local function LoadPartyBuffs(rules, pointX, pointY)
	for i=1,4 do
		local f = _G["PartyMemberFrame"..i] -- PartyMemberFrame1
		LoadUnitBuffs(rules, pointX, pointY, f)
	end
end

local function LoadPartyDebuffs(rules, pointX, pointY)
	for i=1, 4 do
		local f = _G["PartyMemberFrame"..i]
		LoadUnitDebuffs(rules, pointX, pointY, f)
	end
end

local smb = CreateFrame("Frame")
smb:Show()
o.smb = smb

function smb:Reset()
	ShowMeBuffDB = smbDefaults
	print("Resetting options!")
end

local function LoadBuffs()
    local BUFF_POINT
    if ShowMeBuffDB.buffOverDebuffs then
        if ShowMeBuffDB.buffs.lowerBuffOffset then
            BUFF_POINT = -40
        else
            BUFF_POINT = -32
        end
    else
        BUFF_POINT = -50
    end

    -- Load party buffs: always use normal layout (grow downward)
    local partyRules = {}
    for k, v in pairs(ShowMeBuffDB.buffs) do
        partyRules[k] = v
    end
    partyRules.growUpwards = false  -- Force downward for party

    LoadPartyBuffs(partyRules, 48, BUFF_POINT)

    -- Load player buffs: respect growUpwards
    local playerBuffX = ShowMeBuffDB.buffs.playerBuffOffsetX
    local playerBuffY = ShowMeBuffDB.buffs.playerBuffOffsetY
    LoadUnitBuffs(ShowMeBuffDB.buffs, playerBuffX, playerBuffY, PlayerFrame)
end

local function LoadDebuffs()
	local DEBUFF_POINT
	if ShowMeBuffDB.buffOverDebuffs then
		DEBUFF_POINT = -64
	else
		DEBUFF_POINT = -32
	end
	
	LoadPartyDebuffs(ShowMeBuffDB.debuffs, 48, DEBUFF_POINT)
	
	local playerDebuffX = ShowMeBuffDB.debuffs.playerDebuffOffsetX
    local playerDebuffY = ShowMeBuffDB.debuffs.playerDebuffOffsetY
    LoadUnitDebuffs(ShowMeBuffDB.debuffs, playerDebuffX, playerDebuffY, PlayerFrame)
end

local function SmbLoaded(self)
	self:SetScript("OnEvent", function(self,event,...) if self[event] then self[event](self,...) end end)

	ShowMeBuffDB = ShowMeBuffDB or smbDefaults
	if ShowMeBuffDB.version ~= smbDefaults.version then
		smb:MigrateDB()
	end
	self:CreateOptions()

	convertspellids(ShowMeBuffDB.buffs.hideNames)
	convertspellids(ShowMeBuffDB.debuffs.hideNames)

	LoadBuffs()
	smb.LoadBuffs = LoadBuffs
	LoadDebuffs()
	smb.LoadDebuffs = LoadDebuffs
end

function convertspellids(list)
	for k, v in pairs(list) do
		local name = GetSpellInfo(v)
		if name then
			list[k] = name
		end
	end
end

smb:RegisterEvent("VARIABLES_LOADED")
smb:SetScript("OnEvent", SmbLoaded)

function smb:MigrateDB()
	--if ShowMeBuffDB.version == 0 then
	--	ShowMeBuffDB.version = 1
	--end
end
