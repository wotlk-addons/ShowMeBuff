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

-- TODO real config
ShowMeBuffDB = {
	buffOverDebuffs = true,
	buffs = {
		hideNames = {
			"Honorless Target",
			"Arena Preparation",
			"Strength of the Halaani",
			"Essence of Wintergrasp",
			-- procs - keep powerful ones
			"Energized", -- solace
			"Frostforged Sage"; -- icc ring
			"Lightweave", -- tailor back
			-- Priest
			"Divine Aegis",
			"Renewed Hope", -- 63944
			"Inspiration",
			"Focused Will",
			"Borrowed Time",
			-- Mage
			"Replenishment",
			-- Lock
			"Shadow Ward",
			"Demonic Circle: Summon",
			"Fel Intelligence",
			"Soul Link", -- keep it ?
			--"Backdraft", -- same ?
			--"Backlash",
			"Nether Protection",
			"Shadowburn",
			"Eradication",
			--"Shadow Trance",
			-- Druid
			"Soothing", -- rdruid idol
			"Clearcasting",
			"Master Shapeshifter",
			"Natural Perfection",
			-- Hunt
			"Aspect of the Dragonhawk",
			"Trueshot Aura",
			"Culling the Herd",
			-- War
			"Trauma",
			"Blood Frenzy",
		},
		hideInfinite = false,
		hideMounts = true,
		hideConsolidated = true,
		hideDuration = 600, -- 10min

		onlyCastable = false,
		displayNum = 14,
		buffsPerLine = 4,
	},
}

local mountIds = {
	17229, -- Winterspring Frostsaber
	60114, -- Armored Brown Bear
	72286, -- Invincible
	46628, -- Swift White Hawkstrider
}

local BUFF_POINT, DEBUFF_POINT
if ShowMeBuffDB.buffOverDebuffs then
	BUFF_POINT = -32
	DEBUFF_POINT = -64
else
	BUFF_POINT = -50
	DEBUFF_POINT = -32
end

-- DEBUFFS
for i=1,4 do
	local f = _G["PartyMemberFrame"..i]
	f:UnregisterEvent("UNIT_AURA")
	local g = CreateFrame("Frame")
	g:RegisterEvent("UNIT_AURA")
	g:SetScript("OnEvent",function(self,event,a1)
		if a1 == f.unit then
			RefreshDebuffs(f,a1,20,nil,true)
		else
			if a1 == f.unit.."pet" then
				PartyMemberFrame_RefreshPetDebuffs(f)
			end
		end
	end)
	for j=1,20 do
		local l = f:GetName().."Debuff"
		local n = l..j
		local c
		if _G[n] then -- first 5 (should) already exist
			c = _G[n]
		else
			c = CreateFrame("Frame",n,f,"PartyDebuffFrameTemplate")
			c:ClearAllPoints()
			c:SetPoint("BOTTOMLEFT", _G[l..(j-1)],"BOTTOMRIGHT", 3, 0)
			c:Show()
			c:EnableMouse(false)
		end
		-- V: we need to specifically create a cooldown frame inside of "c"
		--    because PartyDebuffFrameTemplate has none
		local cd = CreateFrame("Cooldown",n.."Cooldown",c,"CooldownFrameTemplate")
		cd:SetReverse(true)
		--cd:SetDrawEdge(true)
		cd:SetSize(20, 20) -- V: size needs to be AT LEAST 20
		cd:SetPoint("CENTER", 0, -1)
	end
	local b = _G[f:GetName().."Debuff1"]
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT",48,DEBUFF_POINT)
	RefreshDebuffs(f, f.unit, 20, nil,true)
end

-- BUFFS
local function ShowThisBuff(rules, name, spellId, duration, expirationTime, shouldConsolidate)
	--print(name, debuffType, duration, expirationTime, "--")
	if rules.hideConsolidated and shouldConsolidate then
		-- consolidated buff
		-- print(name..": consolidated")
		return
	end
	if rules.hideInfinite and expirationTime == 0 then
		-- infinite debuff
		--print(name..": infinite")
		return
	end
	if array_contains(rules.hideNames, name) then
		-- buff explicitly ignored
		--print(name..": ignored")
		return
	end
	if duration >= rules.hideDuration then
		-- buff too long
		--print(name, duration..": too long")
		return
	end
	if rules.hideMounts and array_contains(mountIds, spellId) then
		-- mount buff
		--print(name, duration..": mount")
		return
	end
	--print(name, duration, "ok")
	return true
end

-- V: Copy-pasted then modified
local function ShowMeBuff_RefreshBuffs(frame, unit, rules)
	local numBuffs = rules.displayNum or MAX_PARTY_BUFFS;
	local framePrefix = frame:GetName().."Buff";

	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId;
	local buffI = 1
	local filter = rules.onlyCastable and "RAID";
	for i=1, 40 do
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff(unit, i, filter);

		-- we ran out of buffs OR we have enough displayed
		if not name or buffI > numBuffs then
			break -- could even return
		end

		if ShowThisBuff(rules, name, spellId, duration, expirationTime, shouldConsolidate) then
			local buffName = framePrefix..buffI;
			if ( icon ) then
				-- if we have an icon to show then proceed with setting up the aura

				-- set the icon
				local buffIcon = _G[buffName.."Icon"];
				buffIcon:SetTexture(icon);

				-- setup the cooldown
				local coolDown = _G[buffName.."Cooldown"];
				if ( coolDown ) then
					CooldownFrame_SetTimer(coolDown, expirationTime - duration, duration, 1);
				end

				-- show the aura
				_G[buffName]:Show();
			else
				-- no icon, hide the aura
				_G[buffName]:Hide();
			end
			buffI = buffI + 1
		end
	end

	-- hide all remaining buff frames
	-- "buffI" here is already 1 past the last displayed buff
	for i=buffI, numBuffs do
		local buffName = framePrefix..i;
		_G[buffName]:Hide()
	end
end

local buffRules = ShowMeBuffDB.buffs
for i=1,4 do
	local f = _G["PartyMemberFrame"..i] -- PartyMemberFrame1
	f:UnregisterEvent("UNIT_AURA")
	local g = CreateFrame("Frame")
	g:RegisterEvent("UNIT_AURA")
	g:SetScript("OnEvent",function(self,event,a1)
		if a1 == f.unit then
			ShowMeBuff_RefreshBuffs(f, f.unit, buffRules)
		end
	end)
	for j=1,buffRules.displayNum do
		local l = f:GetName().."Buff"
		local n = l..j
		local c = CreateFrame("Frame",n,f,"TargetBuffFrameTemplate")
		c:SetSize(15,15)
		if j == 1 then
			c:SetPoint("TOPLEFT",47,BUFF_POINT)
		elseif ((j - 1) % buffRules.buffsPerLine) == 0 then
			c:SetPoint("TOPLEFT",_G[l..(j - buffRules.buffsPerLine)],"BOTTOMLEFT", 0, -1)
		else
			c:SetPoint("LEFT",_G[l..(j-1)],"RIGHT",1,0)
		end
		c:EnableMouse(false)
	end
	ShowMeBuff_RefreshBuffs(f, f.unit, buffRules)
end
