---@type string, addonMods
local _, addonMods = ...

local texture	= addonMods.defaultTexture
local font		= addonMods.defaultFont

local Timer
local buffTracker, trackedUnits = {}, {}

local RAID_BUFFS = {
	['DRUID']   = 1126,   -- Mark of the Wild
	['MAGE']    = 1459,   -- Arcane Intellect
	['WARRIOR'] = 6673,   -- Battle Shout
	['PRIEST']  = 21562,  -- Power Word: Fortitude
	['SHAMAN']  = 462854, -- Skyfury
	['EVOKER']  = {       -- Blessing of the Bronze
		['DEATHKNIGHT'] = 381732,
		['DEMONHUNTER'] = 381741,
		['DRUID']       = 381746,
		['EVOKER']      = 381748,
		['HUNTER']      = 381749,
		['MAGE']        = 381750,
		['MONK']        = 381751,
		['PALADIN']     = 381752,
		['PRIEST']      = 381753,
		['ROGUE']       = 381754,
		['SHAMAN']      = 381756,
		['WARLOCK']     = 381757,
		['WARRIOR']     = 381758,
	},
}

local myBuff = RAID_BUFFS[addonMods.myClass]
if not myBuff then return end

local myBuffId = type(myBuff) == 'number' and myBuff or myBuff['EVOKER']
local iconId   = C_Spell.GetSpellTexture(myBuffId)
local Icon = addonMods.NewIcon({
	w               = 40,
	h               = 40,
	zoom            = 0.3,
	keepAspectRatio = true,
	scaleX          = 1,
	scaleY          = 1,
	texXOffset 			= 0,
	texYOffset 			= 0,
	anchorPoint     = 'CENTER',
	relativeFrame   = UIParent,
	relativePoint   = 'CENTER',
	xOffset         = 300,
	yOffset         = 120,
	texture 				= iconId,
	desaturated			= true,
	borders = {
		{
			inset       = 0,
			edgeFile    = texture,
			edgeSize    = 2,
			borderColor = {r = 0, g = 0, b = 0, a = 1},
			levelOffset = 2,
		},
	},
	texts = {
		count = {
			font              = font,
			fontSize          = 16,
			fontFlags         = 'OUTLINE, SLUG',
			fontAnchorPoint   = 'CENTER',
			fontRelativePoint = 'CENTER',
			fontXOffset       = 0,
			fontYOffset       = 0,
			fontColor         = {r = 1, g = 1, b = 1, a = 1},
			parent						= 1,
		},
	}
})

---@param unit string
---@return boolean
local function isValidUnit(unit)
	local unitExists  = UnitExists(unit)
	local isAlive     = not UnitIsDead(unit)
	local isConnected = UnitIsConnected(unit)

	local myMap      = C_Map.GetBestMapForUnit('player')
	local theirMap   = C_Map.GetBestMapForUnit(unit)
	local inSameZone = myMap == theirMap

	return unitExists and isAlive and isConnected and inSameZone
end

-- Add tooltip with names of players missing buff
local function showTooltip()
	GameTooltip:SetOwner(Icon, 'ANCHOR_RIGHT')

	local missing = {}
	for unit in pairs(trackedUnits) do
		if isValidUnit(unit) and not buffTracker[unit] then
			table.insert(missing, unit)
		end
	end
	if #missing == 0 then return end
	table.sort(missing, function(a, b) return (UnitName(a) or '') < (UnitName(b) or '') end)

	local text = ''
	for _, unit in ipairs(missing) do text = text .. addonMods.WA_ClassColorName(unit) .. '|n' end

	GameTooltip:AddLine(text)
	GameTooltip:Show()
end

Icon:EnableMouse(true)
Icon:SetScript('OnEnter', showTooltip)
Icon:SetScript('OnLeave', function() GameTooltip:Hide() end)

local function updateIcon()
	local currentCount, maxCount = 0, 0
	for unit in pairs(trackedUnits) do
		if isValidUnit(unit) then
			maxCount = maxCount + 1
			if buffTracker[unit] then
				currentCount = currentCount + 1
			end
		end
	end

	Icon.texts.count:SetText(currentCount .. '/' .. maxCount)
	Icon:SetShown(currentCount ~= maxCount)
end

---@param unit string
local function checkAuras(_, unit)
	local spellId
	if type(myBuff) == 'number' then
		spellId = myBuff
	else
		local _, class = UnitClass(unit)
		spellId = myBuff[class]
	end

	buffTracker[unit] = C_UnitAuras.GetUnitAuraBySpellID(unit, spellId) and true or false
	updateIcon()
end

---@return table<string, boolean>
local function registerRaidUnits()
	local newUnits = {}
	for i = 1, 30 do
		local unit = 'raid' .. i
		newUnits[unit] = true
	end

	return newUnits
end

---@return table<string, boolean>
local function registerPartyUnits()
	local newUnits = {}
	for i = 1, 4 do
		local unit = 'party' .. i
		newUnits[unit] = true
	end
	newUnits['player'] = true -- Player is not a party unit

	return newUnits
end

local function checkGroup()
	Timer = nil

	local _, instanceType = GetInstanceInfo()
	if IsInGroup() and instanceType and (instanceType == 'party' or instanceType == 'raid') then
		local newUnits = IsInRaid() and registerRaidUnits() or registerPartyUnits()

		-- Stop tracking units not relevant to group type (party->raid)
		for unit in pairs(trackedUnits) do
			if not newUnits[unit] then
				addonMods.UnregisterUnitEventHandler('UNIT_AURA', unit, checkAuras)
				trackedUnits[unit] = nil
				buffTracker[unit]  = nil
			end
		end

		-- Register new units and refresh Icon state
		for unit in pairs(newUnits) do
			if not trackedUnits[unit] then
				addonMods.RegisterUnitEventHandler('UNIT_AURA', unit, checkAuras)
				trackedUnits[unit] = true
			end
			if UnitExists(unit) then
				checkAuras(nil, unit)
			end
		end

		updateIcon()
	else
		for unit in pairs(trackedUnits) do
			addonMods.UnregisterUnitEventHandler('UNIT_AURA', unit, checkAuras)
		end
		wipe(trackedUnits)
		wipe(buffTracker)
		Icon:Hide()
	end
end

local function scheduleCheck()
	if Timer then Timer:Cancel() end
	Timer = C_Timer.NewTimer(1, checkGroup)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', scheduleCheck)
addonMods.RegisterEventHandler('GROUP_ROSTER_UPDATE', scheduleCheck)