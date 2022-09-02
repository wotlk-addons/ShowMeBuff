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
	},
	debug = false,
	verson = 1,
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
		--print(name.." buff not casted by a player")
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

	local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId;
	local buffI = 1
	local filter = rules.onlyCastable and friendly and "RAID" -- TODO use isFriendly() for "RAID" or not?
	for i=1, numBuffs do
		name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = buffFn(unit, i, filter)

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
					cooldown:SetCooldown(expirationTime - duration, duration, 1)
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
		g:SetScript("OnEvent",function(self,event,a1)
			if a1 == f.unit then
				RefreshBuffsList(f, true, f.unit, rules, ShowThisBuff)
			end
		end)
	end

	for j=1, 40 do
		local l = f:GetName().."Buff"
		local n = l..j
		local c = _G[n] or CreateFrame("Frame", n, f, "TargetBuffFrameTemplate")
		c:SetSize(rules.buffSize, rules.buffSize)
		c:ClearAllPoints()
		if j == 1 then
			c:SetPoint("TOPLEFT",pointX,pointY)
		elseif ((j - 1) % rules.numPerLine) == 0 then
			c:SetPoint("TOPLEFT",_G[l..(j - rules.numPerLine)],"BOTTOMLEFT", 0, -1)
		else
			c:SetPoint("LEFT",_G[l..(j-1)],"RIGHT",1,0)
		end
		c:Hide()
		c:EnableMouse(false)
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
			cd:SetSize(20, 20) -- V: size needs to be AT LEAST 20
							   --    ...does that mean rules.buffSize should be >=20?
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
		BUFF_POINT = -32
	else
		BUFF_POINT = -50
	end

	LoadPartyBuffs(ShowMeBuffDB.buffs, 48, BUFF_POINT)
	--LoadUnitBuffs(ShowMeBuffDB.buffs, -100, 0, PlayerFrame)
end

local function LoadDebuffs()
	local DEBUFF_POINT
	if ShowMeBuffDB.buffOverDebuffs then
		DEBUFF_POINT = -64
	else
		DEBUFF_POINT = -32
	end
	
	LoadPartyDebuffs(ShowMeBuffDB.debuffs, 48, DEBUFF_POINT)
	--LoadUnitDebuffs(ShowMeBuffDB.debuffs, -100, -50, PlayerFrame)
end

local function SmbLoaded(self)
	self:SetScript("OnEvent", function(self,event,...) if self[event] then self[event](self,...) end end)

	ShowMeBuffDB = ShowMeBuffDB or smbDefaults
	if ShowMeBuffDB.version ~= smbDefaults.version then
		smb:MigrateDB()
	end

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
