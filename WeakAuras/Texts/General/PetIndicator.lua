---@type string, addonMods
local _, addonMods = ...

local VALID_CLASSES = {
	['DEATHKNIGHT'] = true,
	['WARLOCK']			= true,
}
if not VALID_CLASSES[addonMods.myClass] then return end

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local VALID_SPECS = {
	[252] = true, -- Unholy
	[265] = true, -- Affliction
	[266] = true, -- Demonology
	[267] = true, -- Destruction
}

local Ticker
local FLASH_COLOR = {r = 0/255, g = 119/255, b = 255/255}

-- Create visuals
local PetAttackText = UIParent:CreateFontString(nil, 'OVERLAY')
PetAttackText:Hide()

---@cast fontFlags string
PetAttackText:SetFont(font, 18, fontFlags)

local statusGroup = addonMods.GetOrCreateDynamicGroup('StatusText', {
	point         = 'BOTTOM',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 1,
	y             = -82,
	direction     = 'UP',
	spacing       = -4,
})
statusGroup:AddMember(PetAttackText, 3)
local petPulse = addonMods.CreatePulse(PetAttackText, 0.5, FLASH_COLOR, 1)

local function petTimerTick()
  local text, hasText = '', false
	if UnitExists('pet') and not UnitExists('pettarget') then
		text = '-x-'
		hasText = true
	end

	PetAttackText:SetText(text)
	PetAttackText:SetShown(hasText)
	if hasText then
		addonMods.AddPulse(petPulse)
	else
		addonMods.RemovePulse(petPulse)
	end
end

local function cancelTicker()
	if not Ticker then return end
	Ticker:Cancel()
	Ticker = nil

	PetAttackText:SetText('')
	PetAttackText:Hide()
	addonMods.RemovePulse(petPulse)
end

local function startTicker()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(0.5, petTimerTick)
end

---@return boolean
local function invalidStatus()
	local isDead    = UnitIsDeadOrGhost('player')
	local isMounted = IsMounted()

	return isDead or isMounted
end

local function enterCombat()
	if UnitExists('target') and not invalidStatus() then
		startTicker()
	else
		cancelTicker()
	end
end

local function exitCombat()
	cancelTicker()
end

local function checkSpec()
	local specIndex   = C_SpecializationInfo.GetSpecialization()
	local specId      = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local isValidSpec = VALID_SPECS[specId]

	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)
	if isValidSpec then
		addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', exitCombat)
	else
		addonMods.UnregisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_ENABLED', exitCombat)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)