local _, o = ...

local smb = o.smb
local buffRules = ShowMeBuffDB.buffs

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
		'current', buffRules.hideFiltered,
		'setFunc', function(value) buffRules.hideFiltered = value end)
	filter:SetPoint("TOPLEFT",buffPanel,"BOTTOMLEFT",0,-10)
	
	local consolidated = panel:MakeToggle(
		'name', 'Hide consolidated',
		'description', 'Hide consolidated buffs',
		'default', true,
		'current', buffRules.hideConsolidated,
		'setFunc', function(value) buffRules.hideConsolidated = value end)
	consolidated:SetPoint("TOPLEFT",filter,"BOTTOMLEFT",0,-5)
	
	local mounts = panel:MakeToggle(
		'name', 'Hide mounts',
		'description', 'Hide mounts',
		'default', true,
		'current', buffRules.hideMounts,
		'setFunc', function(value) buffRules.hideMounts = value end)
	mounts:SetPoint("TOPLEFT",consolidated,"BOTTOMLEFT",0,-5)
	
	local infinite = panel:MakeToggle(
		'name', 'Hide infinite',
		'description', 'Hide buffs with infinite duration',
		'default', false,
		'current', buffRules.hideInfinite,
		'setFunc', function(value) buffRules.hideInfinite = value end)
	infinite:SetPoint("TOPLEFT",mounts,"BOTTOMLEFT",0,-5)
	
	local player = panel:MakeToggle(
		'name', 'Hide non player',
		'description', 'Only shows buffs the player applied',
		'default', false,
		'current', buffRules.hideNonPlayer,
		'setFunc', function(value) buffRules.hideNonPlayer = value end)
	player:SetPoint("TOPLEFT",infinite,"BOTTOMLEFT",0,-5)

	local duration = panel:MakeSlider(
		'name', 'Hide longer than',
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
	duration:SetPoint("TOP",reset,"BOTTOM",-10,-40)
	
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
	
	local numPerLine = panel:MakeSlider(
		'name', 'Buff per line',
		'description', 'Chose the number of buffs per line, requires reload',
		'minText', '2',
		'maxText', '10',
		'minValue', 2,
		'maxValue', 10,
		'step', 1,
		'default', 5,
		'current', buffRules.numPerLine,
		'setFunc', function(value) buffRules.numPerLine = value end,
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
		'current', buffRules.numLines,
		'setFunc', function(value) buffRules.numLines = value end,
		'currentTextFunc', function(value) return ("%.0f"):format(value) end)
	numLines:SetPoint("TOPLEFT",perLine,"BOTTOMLEFT",0,-30)
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
		smb:CreateOptions()
		InterfaceOptionsFrame_OpenToCategory("ShowMeBuff")
	end
end