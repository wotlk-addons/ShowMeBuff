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
local ShowMeBuff = {
	hideInfinite = false,
	-- TODO hideSpellIds
	hideBuffNames = {
		-- TODO check which one of these consolidates
		"Honorless Target",
		"Arena Preparation",
		"Energized", -- solace
		"Strength of the Halaani",
		-- Priest
		"Divine Aegis",
		"Renewed Hope", -- 63944
		"Inspiration",
		"Focused Will",
		-- Mage
		"Replenishment"
	},
	hideMounts = true,
	hideConsolidated = true,
	hideDuration = 600, -- 10min
	numBuffs = 12
}

local mountIds = {
	17229, -- Winterspring Frostsaber
	60114, -- Armored Brown Bear
}

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
		--cd:SetDrawEdge(true)
		cd:SetSize(20, 20) -- V: size needs to be AT LEAST 20
		cd:SetPoint("CENTER", 0, -1)
	end
	local b = _G[f:GetName().."Debuff1"]
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT",48,-32)
	RefreshDebuffs(f, f.unit, 20, nil,true)
end

-- BUFFS
local function ShowThisBuff(name, spellId, duration, expirationTime, shouldConsolidate)
	--print(name, debuffType, duration, expirationTime, "--")
	if ShowMeBuff.hideConsolidated and shouldConsolidate then
		-- consolidated buff
		-- print(name, "consolidated")
		return
	end
	if ShowMeBuff.hideInfinite and expirationTime == 0 then
		-- infinite debuff
		--print(name, "infinite")
		return
	end
	if array_contains(ShowMeBuff.hideBuffNames, name) then
		-- buff explicitly ignored
		--print(name, "ignored")
		return
	end
	if duration >= ShowMeBuff.hideDuration then
		-- buff too long
		--print(name, duration, "too long")
		return
	end
	if ShowMeBuff.hideMounts and array_contains(mountIds, spellId) then
		-- mount buff
		--print(name, duration, "mount")
		return
	end
	--print(name, duration, "ok")
	return true
end

-- V: Copy-pasted then modified
local allBuffs = {}
local function ShowMeBuff_RefreshBuffs(frame, unit, suffix, checkCVar)
	local frameName = frame:GetName();

	numBuffs = ShowMeBuff.numBuffs or MAX_PARTY_BUFFS;
	suffix = suffix or "Buff";

	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId;
	local buffI = 1
	for i=1, numBuffs do
		local filter;
		if ( checkCVar and GetCVarBool("showCastableBuffs") ) then
			filter = "RAID";
		end
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff(unit, i, filter);

		if name and ShowThisBuff(name, spellId, duration, expirationTime, shouldConsolidate) then
			local buffName = frameName..suffix..buffI;
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
	for i=buffI, #allBuffs do
		allBuffs[i]:Hide()
	end
end

for i=1,4 do
	local f = _G["PartyMemberFrame"..i] -- PartyMemberFrame1
	f:UnregisterEvent("UNIT_AURA")
	local g = CreateFrame("Frame")
	g:RegisterEvent("UNIT_AURA")
	g:SetScript("OnEvent",function(self,event,a1)
		if a1 == f.unit then
			ShowMeBuff_RefreshBuffs(f,a1,nil,true)
		end
	end)
	for j=1,ShowMeBuff.numBuffs do
		local l = f:GetName().."Buff"
		local n = l..j
		local c = CreateFrame("Frame",n,f,"TargetBuffFrameTemplate")
		c:SetSize(15,15)
		if j == 1 then
			c:SetPoint("TOPLEFT",47,-50)
		elseif j == 7 then
			c:SetPoint("TOPLEFT",_G[l..(j-6)],"BOTTOMLEFT", 0, -1)
		else
			c:SetPoint("LEFT",_G[l..(j-1)],"RIGHT",1,0)
		end
		c:EnableMouse(false)
		tinsert(allBuffs, c)
	end
	ShowMeBuff_RefreshBuffs(f,f.unit,nil,true)
end
