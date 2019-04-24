local smb = CreateFrame("Frame")
local ShowMeBuff

-- local function print(...)
	-- for i=1,select('#',...) do
		-- local x = select(i,...)
		-- if x == nil then
			-- x = "nil"
		-- end
		-- ChatFrame1:AddMessage("|cff33ff99 ShowMeBuff|r: " .. x)
	-- end
-- end

local function prt(tab,s)
	if type(tab) == "table" then
		if s == nil then s = "" end
		for k,v in pairs(tab) do
			if type(tab[k]) == "table" then
				print(k)
				s = s.."  " -- BUG: shouldn't be each time, but each new level of recursion
				prt(tab[k],s)
			else
				print(s,k,v)
			end
		end
	else
		print(tab)
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
-- local defaultDB = {
local ShowMeBuffDefault = {
	buffOverDebuffs = false,
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
		hideFilteredList = true,
		hideConsolidated = true,
		hideMounts = true,
		hideInfinite = false,
		hideDuration = 600, -- 10min

		onlyCastable = false,
		displayNum = 14,
		buffsPerLine = 4,
		
		buffSize = 15,
		debuffLine = 1,
		buffLine = 2,
		hideNonPlayer = false,
	},
	debug = false,
	version = 1,
}

local allBuffsDB = {
	-- TODO hideSpellIds
	hideNames = {
	},
	hideFilteredList = false,
	hideInfinite = false,
	hideMounts = false,
	hideConsolidated = false,
	hideDuration = 60000, -- never
	numBuffs = 10,
	buffsPerLine = 100,
	buffSize = 15,
	buffOverDebuffs = false,
	debuffLine = 1,
	buffLine = 2,
	hideNonPlayer = false,
	movePetFrame = true,
	debug = false,
	version = 1,
}

local mountIds = {
	17229, -- Winterspring Frostsaber
	60114, -- Armored Brown Bear
	60116, -- Armored Brown Bear
	72286, -- Invincible
	46628, -- Swift White Hawkstrider
}

local function printd(...)
	for i=1,select('#',...) do
		local x = select(i,...)
		if x == nil then
			x = "nil"
		end
		if ShowMeBuff.debug == true then
			ChatFrame1:AddMessage("|cff33ff99 SMBd|r - " .. x)
		end
	end
end

ShowMeBuff = ShowMeBuffDefault -- L : pose problème clairement, mais si je le fous pas, le reste du code va être lu avant l'init... A débug

function smb:reset()
	smbDB = CopyTable(ShowMeBuffDefault)
	print("ShowMeBuff Reset")
end

-- Init

smb:RegisterEvent("ADDON_LOADED")

function smb:OnEvent(event,arg1)
	if event == "ADDON_LOADED" and arg1 == "ShowMeBuff" then
	-- prt(smbDB)
		if not smbDB or not smbDB.version or smbDB.version ~= ShowMeBuffDefault.version then -- besoin de les passer en _G.smbDB ?
			smb:reset()
		end
		ShowMeBuff = smbDB
		self:CreateOptions()
	end
end

local buffRules = ShowMeBuff.buffs

ShowMeBuff.movePetFrame = true
if ShowMeBuff.movePetFrame then
	for i=1,4 do
		local f = _G["PartyMemberFrame"..i.."PetFrame"]
		f:ClearAllPoints()
		f:SetPoint("BOTTOM", PartyMemberFrame1, -42, -19)
		f:SetScale(1.3)
		f.SetPoint = function() end
	end
end

if ShowMeBuff.buffOverDebuffs then
	ShowMeBuff.buffs.buffLine, ShowMeBuff.buffs.debuffLine = ShowMeBuff.buffs.debuffLine, ShowMeBuff.buffs.buffLine
end

-- error checking
-- if ShowMeBuff.buffs.buffsPerLine > ShowMeBuff.numBuffs then
	-- ShowMeBuff.buffs.buffsPerLine = ShowMeBuff.numBuffs
-- end

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
	if ShowMeBuff.buffs.debuffLine == 1 then
		b:SetPoint("TOPLEFT",48,-32)
	else
		local y = -34 - (ShowMeBuff.buffs.buffSize + 1) * (ShowMeBuff.buffs.debuffLine - 1)
		b:SetPoint("TOPLEFT",48,y)
	end
	RefreshDebuffs(f, f.unit, 20, nil,true)
end

-- BUFFS
local function ShowThisBuff(rules, name, spellId, duration, expirationTime, unitCaster, shouldConsolidate)
	-- printd(name, debuffType, duration, expirationTime, "--")
	if rules.hideConsolidated and shouldConsolidate then
		-- consolidated buff
		printd(name.." - consolidated")
		return
	end
	if rules.hideNonPlayer and unitCaster ~= "player" then
		-- not cast by player
		printd(name.." - not player buff")
		return
	end
	if rules.hideInfinite and expirationTime == 0 then
		-- infinite debuff
		printd(name.." - infinite")
		return
	end
	if array_contains(rules.hideNames, name) and rules.hideFilteredList then
		-- buff explicitly ignored
		printd(name.." - ignore list")
		return
	end
	if duration >= rules.hideDuration then
		-- buff too long
		printd(name.." - "..duration.." - long buff")
		return
	end
	if rules.hideMounts and array_contains(mountIds, spellId) then
		-- mount buff
		printd(name.." - "..duration.." - mount")
		return
	end
	printd(name.." - "..duration.." sec")
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

		if ShowThisBuff(rules, name, spellId, duration, expirationTime, unitCaster, shouldConsolidate) then
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
		local size = buffRules.buffSize
		c:SetSize(size,size)
		if j == 1 then
			if buffRules.buffLine == 1 then
				c:SetPoint("TOPLEFT",48,-32)
			else
				local y = -34 - 16*(buffRules.buffLine - 1)
				c:SetPoint("TOPLEFT",48,y)
			end
		elseif ((j - 1) % buffRules.buffsPerLine) == 0 then
			c:SetPoint("TOPLEFT",_G[l..(j - buffRules.buffsPerLine)],"BOTTOMLEFT", 0, -1)
		else
			c:SetPoint("LEFT",_G[l..(j-1)],"RIGHT",1,0)
		end
		c:EnableMouse(false)
	end
	ShowMeBuff_RefreshBuffs(f, f.unit, buffRules)
end


-- Options

local SimpleOptions = LibStub("LibSimpleOptions-1.0")
function smb:CreateOptions()
	local panel = SimpleOptions.AddOptionsPanel("ShowMeBuff", function() end)
	self.panel = panel
	local title, subText = panel:MakeTitleTextAndSubText("ShowMeBuff","Some changes require a reload")
	
	-- local scrollFrame = panel:MakeScrollFrame()
	
	local reload = panel:MakeButton(
		'name', 'Reload',
		'description', 'Reloads UI',
		'func', function() ReloadUI() end)
	reload:SetPoint("TOPLEFT",title,"TOPRIGHT",150,0)

	local reset = panel:MakeButton(
		'name', 'Reset',
		'description', 'Resets the configuration',
		'func', function() smb:reset() end)
	reset:SetPoint("TOP",reload,"BOTTOM",0,0)
	
	local filter = panel:MakeToggle(
		'name', 'Hide buffs from list',
		'description', 'Hides useless buffs in the list',
		'default', true,
		'current', buffRules.hideFilteredList,
		'setFunc', function(value) buffRules.hideFilteredList = value end)
	filter:SetPoint("TOPLEFT",subText,"BOTTOMLEFT",0,-20)
	
	local consolidated = panel:MakeToggle(
		'name', 'Hide consolidated buffs',
		'description', 'The thing nobody uses, if you know what it is, stop doing PvE',
		'default', true,
		'current', buffRules.hideConsolidated,
		'setFunc', function(value) buffRules.hideConsolidated = value end)
	consolidated:SetPoint("TOPLEFT",filter,"BOTTOMLEFT",0,-5)
	
	local mounts = panel:MakeToggle(
		'name', 'Hide mount buffs',
		'description', 'Did I rly create an option for that',
		'default', true,
		'current', buffRules.hideMounts,
		'setFunc', function(value) buffRules.hideMounts = value end)
	mounts:SetPoint("TOPLEFT",consolidated,"BOTTOMLEFT",0,-5)
	
	local infinite = panel:MakeToggle(
		'name', 'Hide inifinite buffs',
		'description', 'Another very useful option',
		'default', false,
		'current', buffRules.hideInfinite,
		'setFunc', function(value) buffRules.hideInfinite = value end)
	infinite:SetPoint("TOPLEFT",mounts,"BOTTOMLEFT",0,-5)
	
	local player = panel:MakeToggle(
		'name', 'Hide non player buffs',
		'description', 'Only shows buffs the player applied',
		'default', false,
		'current', buffRules.hideNonPlayer,
		'setFunc', function(value) buffRules.hideNonPlayer = value end)
	player:SetPoint("TOPLEFT",infinite,"BOTTOMLEFT",0,-5)

	local debug = panel:MakeToggle(
		'name', 'Debug mode',
		'description', 'Toggle debug mode - for devs',
		'default', false,
		'current', ShowMeBuff.debug,
		'setFunc', function(value) ShowMeBuff.debug = value end)
	debug:SetPoint("TOPLEFT",player,"BOTTOMLEFT",0,-50)
	smbDB = ShowMeBuff
	
	local duration = panel:MakeSlider(
		'name', 'Hide for buffs longer than',
		'description', 'Time in minutes',
		'minText', '0',
		'maxText', '60',
		'minValue', 0,
		'maxValue', 60,
		'step', 5,
		'default', 10,
		'current', buffRules.hideDuration/60,
		'setFunc', function(value) buffRules.hideDuration = value*60 end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	duration:SetPoint("TOP",reset,"BOTTOM",-10,-30)
	
	local size = panel:MakeSlider(
		'name', 'Buff size',
		'description', 'in pixels, requires reload',
		'minText', '15',
		'maxText', '50',
		'minValue', 15,
		'maxValue', 50,
		'step', 5,
		'default', buffRules.buffSize,
		'current', buffRules.buffSize,
		'setFunc', function(value) buffRules.buffSize = value end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	size:SetPoint("TOPLEFT",duration,"BOTTOMLEFT",0,-30)
	
	local perLine = panel:MakeSlider(
		'name', 'Buff per line',
		'description', 'Chose the number of buffs per line, requires reload',
		'minText', '2',
		'maxText', '10',
		'minValue', 2,
		'maxValue', 10,
		'step', 1,
		'default', 5,
		'current', buffRules.buffsPerLine,
		'setFunc', function(value) buffRules.buffsPerLine = value end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	perLine:SetPoint("TOPLEFT",size,"BOTTOMLEFT",0,-30)
	
	local buffLines = panel:MakeSlider(
		'name', 'Lines of buffs',
		'description', 'Lines of buffs, requires reload',
		'minText', '1',
		'maxText', '4',
		'minValue', 1,
		'maxValue', 4,
		'step', 1,
		'default', 2,
		'current', buffRules.buffLine,
		'setFunc', function(value) buffRules.buffLine = value end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	buffLines:SetPoint("TOPLEFT",perLine,"BOTTOMLEFT",0,-30)
	
	local debuffLines = panel:MakeSlider(
		'name', 'Lines of debuffs',
		'description', 'Lines of debuffs, requires reload',
		'minText', '0',
		'maxText', '4',
		'minValue', 0,
		'maxValue', 4,
		'step', 1,
		'default', 2,
		'current', buffRules.debuffLine,
		'setFunc', function(value) buffRules.debuffLine = value end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	debuffLines:SetPoint("TOPLEFT",buffLines,"BOTTOMLEFT",0,-30)
	
	-- smb:ApplySettings()
end

-- Slash commands

SLASH_SMB1 = "/smb";
SLASH_SMB2 = "/showmebuff";
SlashCmdList["SMB"] = function(cmd)
	cmd = cmd:lower() or ""
	if cmd == "reset" then
		smb:reset()
	elseif cmd == "debug" then
		ShowMeBuff.debug = not ShowMeBuff.debug
	else
		InterfaceOptionsFrame_OpenToCategory("ShowMeBuff")
	end
end


smb:SetScript("OnEvent", smb.OnEvent);
