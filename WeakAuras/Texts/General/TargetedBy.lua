---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'
---@cast fontFlags string

local VALID_ZONES = {
	['Dornogal']        = true,
	['Silvermoon City'] = true,
}

local Ticker

-- Create visuals
local BASE_TEXT    = 'Targeted by:'
local TargetedText = UIParent:CreateFontString(nil, 'OVERLAY')

TargetedText:SetPoint('CENTER', 600, 100)
TargetedText:SetFont(font, 24, fontFlags)
TargetedText:SetJustifyH('LEFT')

local function checkTargets()
	local nameplates = C_NamePlate.GetNamePlates()
  local numUnits   = #nameplates
	local display    = BASE_TEXT

	for i = 1, numUnits do
		local unit			 = nameplates[i].unitToken
		local unitExists = UnitIsUnit(unit .. 'target', 'player')
		if not issecretvalue(unitExists) and unitExists then
			local unitName        = UnitName(unit)
			local _, englishClass = UnitClass(unit)
			local color 					= RAID_CLASS_COLORS[englishClass]['colorStr']

			-- Guild Name/Rank
			local guildName, guildRankName = GetGuildInfo(unit)
			local guildFormatted
			if guildName then
				guildFormatted = ' <' .. guildName .. '>' .. ' - ' .. guildRankName
			else
				guildFormatted = ''
			end

			-- Mythic Prog/M+ Rating
			local rio  = RaiderIO.GetProfile(unit)
			local cur  = rio and rio.mythicKeystoneProfile and rio.mythicKeystoneProfile.currentScore
			local main = rio and rio.mythicKeystoneProfile and rio.mythicKeystoneProfile.mainCurrentScore

			local prog, diff
			if rio and rio.raidProfile and rio.raidProfile.progress then
				for _, tab in pairs(rio.raidProfile.progress) do
					local diffId    = tab.difficulty
					local maxBosses = tab.raid and tab.raid.bossCount
					if diffId == 3 and maxBosses then
						diff = 'M'
						prog = tab.progressCount .. '/' .. maxBosses .. diff
					end
				end
			end

			local mainProg, mainDiff
			if rio and rio.raidProfile and rio.raidProfile.mainProgress then
				for _, tab in pairs(rio.raidProfile.mainProgress) do
					local diffId    = tab.difficulty
					local maxBosses = tab.raid and tab.raid.bossCount
					if diffId == 3 and maxBosses then
						mainDiff = 'M'
						mainProg = tab.progressCount .. '/' .. maxBosses .. mainDiff
					end
				end
			end

			local rioText = ''
			if cur and cur > 0   then rioText = 'M+ ' .. cur																										 end
			if main and main > 0 then rioText = rioText .. (rioText ~= '' and '\n' or '') .. 'M+ Main ' .. main  end
			if prog 						 then rioText = rioText .. (rioText ~= '' and '\n' or '') .. prog								 end
			if mainProg 				 then rioText = rioText .. (rioText ~= '' and '\n' or '') .. 'Main ' .. mainProg end

			-- Add to display
			if string.len(display) > 0 then
				display = display .. '\n' .. '|c' .. color .. unitName .. '|r' .. guildFormatted .. '\n' .. rioText
			else
				display = '|c' .. color .. unitName .. '|r' .. guildFormatted .. '\n' .. rioText
			end
			display = display .. '\n'
		end
	end

	TargetedText:SetText(display)
end

local function cancelTicker()
  if not Ticker then return end
	Ticker:Cancel()
	Ticker = nil
end

local function startTicker()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(0.1, checkTargets)
end

local function checkZone()
	local zoneName = GetZoneText()

	if VALID_ZONES[zoneName] then
		TargetedText:Show()
		startTicker()
	else
		TargetedText:Hide()
		cancelTicker()
	end
end

-- Event Registration
addonMods.RegisterEventHandler('ZONE_CHANGED', checkZone)
addonMods.RegisterEventHandler('ZONE_CHANGED_NEW_AREA', checkZone)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkZone)