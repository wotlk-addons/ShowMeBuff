local _, o = ...

local smb = o.smb

local SimpleOptions = LibStub("LibSimpleOptions-1.0")
function smb:CreateOptions()
	if self.panel then return end

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
		'func', function() smb:Reset() end)
	reset:SetPoint("TOP",reload,"BOTTOM",0,0)
	
	local buffPanel, buffPanelSub = panel:MakeTitleTextAndSubText("Buff rules","Rules applied to buffs")
	buffPanel:ClearAllPoints()
	buffPanel:SetPoint("TOP",title,"BOTTOM", -10,-40)
	buffPanelSub:ClearAllPoints()
	buffPanelSub:SetPoint("TOP",buffPanel,"RIGHT",80, 5)

	local filter = panel:MakeToggle(
		'name', 'Filter out buffs',
		'description', 'Enable the filter list',
		'default', true,
		'current', ShowMeBuffDB.buffs.hideFiltered,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.hideFiltered = value
			smb.LoadBuffs()
		end)
	filter:SetPoint("TOPLEFT",buffPanel,"BOTTOMLEFT",0,-10)
	
	local consolidated = panel:MakeToggle(
		'name', 'Hide consolidated',
		'description', 'Hide consolidated buffs',
		'default', true,
		'current', ShowMeBuffDB.buffs.hideConsolidated,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.hideConsolidated = value
			smb.LoadBuffs()
		end)
	consolidated:SetPoint("TOPLEFT",filter,"BOTTOMLEFT",0,-5)
	
	local mounts = panel:MakeToggle(
		'name', 'Hide mounts',
		'description', 'Hide mounts',
		'default', true,
		'current', ShowMeBuffDB.buffs.hideMounts,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.hideMounts = value
			smb.LoadBuffs()
		end)
	mounts:SetPoint("TOPLEFT",consolidated,"BOTTOMLEFT",0,-5)
	
	local infinite = panel:MakeToggle(
		'name', 'Hide infinite',
		'description', 'Hide buffs with infinite duration',
		'default', false,
		'current', ShowMeBuffDB.buffs.hideInfinite,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.hideInfinite = value
			smb.LoadBuffs()
		end)
	infinite:SetPoint("TOPLEFT",mounts,"BOTTOMLEFT",0,-5)
	
	local player = panel:MakeToggle(
		'name', 'Hide non player',
		'description', 'Only shows buffs the player applied',
		'default', false,
		'current', ShowMeBuffDB.buffs.hideNonPlayer,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.hideNonPlayer = value
			smb.LoadBuffs()
		end)
	player:SetPoint("TOPLEFT",infinite,"BOTTOMLEFT",0,-5)

	local duration = panel:MakeSlider(
		'name', 'Hide longer than',
		'description', 'Time in minutes',
		'minText', '0',
		'maxText', '180',
		'minValue', 0,
		'maxValue', 180,
		'step', 5,
		'default', 10,
		'current', ShowMeBuffDB.buffs.hideDuration/180,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.hideDuration = value*180
			smb.LoadBuffs()
		end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	duration:SetPoint("TOP",reset,"BOTTOM",-10,-40)
	
	local size = panel:MakeSlider(
		'name', 'Buff size',
		'description', 'in pixels, requires reload',
		'minText', '15',
		'maxText', '50',
		'minValue', 15,
		'maxValue', 50,
		'step', 5,
		'default', ShowMeBuffDB.buffs.buffSize,
		'current', ShowMeBuffDB.buffs.buffSize,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.buffSize = value
			smb.LoadBuffs()
		end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	size:SetPoint("TOPLEFT",duration,"BOTTOMLEFT",0,-30)
	
	local numPerLine = panel:MakeSlider(
		'name', 'Buff per line',
		'description', 'Chose the number of buffs per line, requires reload',
		'minText', '1',
		'maxText', '10',
		'minValue', 1,
		'maxValue', 10,
		'step', 1,
		'default', 5,
		'current', ShowMeBuffDB.buffs.numPerLine,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.numPerLine = value
			smb.LoadBuffs()
		end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	numPerLine:SetPoint("TOPLEFT",size,"BOTTOMLEFT",0,-30)
	
	local numLines = panel:MakeSlider(
		'name', 'Lines of buffs',
		'description', 'Lines of buffs, requires reload',
		'minText', '1',
		'maxText', '4',
		'minValue', 1,
		'maxValue', 4,
		'step', 1,
		'default', 2,
		'current', ShowMeBuffDB.buffs.numLines,
		'setFunc', function(value)
			ShowMeBuffDB.buffs.numLines = value
			smb.LoadBuffs()
		end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	numLines:SetPoint("TOPLEFT",perLine,"BOTTOMLEFT",0,-30)
	
	local lowerOffset = panel:MakeToggle(
    'name', 'Lower buff offset for EasyFrames',
    'description', 'Move buffs slightly lower (good for EasyFrames party frames)',
    'default', false,
    'getFunc', function() 
        return ShowMeBuffDB and ShowMeBuffDB.buffs and ShowMeBuffDB.buffs.lowerBuffOffset or false 
    end,
    'setFunc', function(value)
        if ShowMeBuffDB and ShowMeBuffDB.buffs then
            ShowMeBuffDB.buffs.lowerBuffOffset = value
            smb.LoadBuffs()
        end
    end)
	lowerOffset:SetPoint("TOPLEFT", player, "BOTTOMLEFT", 0, -5)
	
	local buffsOnTop = panel:MakeToggle(
    'name', 'Player buffs on top',
    'description', 'Show player buffs above the player frame instead of below',
    'default', false,
    'getFunc', function() 
        return ShowMeBuffDB and ShowMeBuffDB.buffs and ShowMeBuffDB.buffs.buffsOnTop or false 
    end,
    'setFunc', function(value)
        if ShowMeBuffDB and ShowMeBuffDB.buffs then
            ShowMeBuffDB.buffs.buffsOnTop = value
            smb.LoadBuffs()
        end
    end)
	buffsOnTop:SetPoint("TOPLEFT", lowerOffset, "BOTTOMLEFT", 0, -5)
end

-- Slash commands
SLASH_SMB1 = "/smb";
SLASH_SMB2 = "/showmebuff";
SlashCmdList["SMB"] = function(cmd)
	cmd = cmd:lower() or ""
	if cmd == "reset" then
		smb:Reset()
	elseif cmd == "debug" then
		ShowMeBuff.debug = not ShowMeBuff.debug
	else
		smb:CreateOptions()
		InterfaceOptionsFrame_OpenToCategory("ShowMeBuff")
	end
end
