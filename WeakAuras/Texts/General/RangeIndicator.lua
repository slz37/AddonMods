---@type string, addonMods
local _, addonMods = ...

local VALID_CLASSES = {
	['DRUID']       = true,
	['PRIEST']      = true,
	['DEMONHUNTER'] = true,
	['WARLOCK'] 		= true,
}
if not VALID_CLASSES[addonMods.myClass] then return end

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local VALID_SPECS = {
	[102]  = 93402,   -- Balance	
	[258]  = 589,     -- Shadow	
	[1480] = 473662,  -- Devourer
	[265]  = 48181, 	-- Affliction
	[266]  = 105174, 	-- Demonology
	[267]  = 29722, 	-- Destruction
}

local Ticker, spellId
local FLASH_COLOR = {r = 216/255, g = 108/255, b = 108/255}

-- Create visuals
local RangeRangeText = UIParent:CreateFontString(nil, 'OVERLAY')
RangeRangeText:Hide()

---@cast fontFlags string
RangeRangeText:SetFont(font, 18, fontFlags)

local statusGroup = addonMods.GetOrCreateDynamicGroup('StatusText', {
	point         = 'BOTTOM',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 1,
	y             = -82,
	direction     = 'UP',
	spacing       = -4,
})
statusGroup:AddMember(RangeRangeText, 2)
local rangePulse = addonMods.CreatePulse(RangeRangeText, 0.5, FLASH_COLOR, 1)

local function rangeTimerTick()
	local text, hasText = '', false
	if not C_Spell.IsSpellInRange(spellId, 'target') then
		text = '-r-'
		hasText = true
	end

	RangeRangeText:SetText(text)
	RangeRangeText:SetShown(hasText)
	if hasText then
		addonMods.AddPulse(rangePulse)
	else
		addonMods.RemovePulse(rangePulse)
	end
end

local function cancelTicker()
	if not Ticker then return end
	Ticker:Cancel()
	Ticker = nil

	RangeRangeText:SetText('')
	RangeRangeText:Hide()
	addonMods.RemovePulse(rangePulse)
end

local function startTicker()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(0.5, rangeTimerTick)
end

---@return boolean
local function invalidStatus()
	local isDead    = UnitIsDeadOrGhost('player')
	local isMounted = IsMounted()
	local canAttack = UnitCanAttack('player', 'target')

	return isDead or isMounted or not canAttack
end

local function enterCombat()
	if UnitExists('target') and not invalidStatus() then
		startTicker()
	else
		cancelTicker()
	end
end

local function targetChanged()
	if (not InCombatLockdown() and not IsInInstance()) or invalidStatus() then
		cancelTicker()
		return
	end
  enterCombat()
end

local function checkSpec()
	local specIndex 	= C_SpecializationInfo.GetSpecialization()
	local specId			= C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local isValidSpec = VALID_SPECS[specId]

	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)
	if isValidSpec then
		spellId = isValidSpec
		addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', targetChanged)
		addonMods.RegisterEventHandler('PLAYER_TARGET_CHANGED', targetChanged)
		addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', cancelTicker)
	else
		spellId = nil
		addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', targetChanged)
		addonMods.UnregisterEventHandler('PLAYER_TARGET_CHANGED', targetChanged)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_ENABLED', cancelTicker)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)