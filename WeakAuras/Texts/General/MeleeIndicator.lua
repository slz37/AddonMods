---@type string, addonMods
local _, addonMods = ...

local VALID_CLASSES = {
	['DEATHKNIGHT'] = true,
	['DEMONHUNTER'] = true,
}
if not VALID_CLASSES[addonMods.myClass] then return end

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local meleeSpellId
local VALID_SPECS = {
	[250] = 316239, -- Blood
	[251] = 316239, -- Frost
	[252] = 316239, -- Unholy
	[577] = 162794, -- Havoc
}

local Ticker
local FLASH_COLOR = {r = 216/255, g = 108/255, b = 108/255}
C_Item.RequestLoadItemDataByID(16114)

-- Create visuals
local MeleeRangeText = UIParent:CreateFontString(nil, 'OVERLAY')
MeleeRangeText:Hide()

---@cast fontFlags string
MeleeRangeText:SetFont(font, 18, fontFlags)

local statusGroup = addonMods.GetOrCreateDynamicGroup('StatusText', {
	point         = 'BOTTOM',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 1,
	y             = -82,
	direction     = 'UP',
	spacing       = -4,
})
statusGroup:AddMember(MeleeRangeText, 2)
local meleePulse = addonMods.CreatePulse(MeleeRangeText, 0.5, FLASH_COLOR, 1)

local function meleeTimerTick()
	local text, hasText = '', false
	if not C_Spell.IsCurrentSpell(6603) then
		text    = '-x-'
		hasText = true
	elseif C_Spell.IsSpellInRange(meleeSpellId, 'target') == false then -- Sometimes it returns nil even when you're in melee range
		text    = '-r-'
		hasText = true
	end

	MeleeRangeText:SetText(text)
	MeleeRangeText:SetShown(hasText)
	if hasText then
		addonMods.AddPulse(meleePulse)
	else
		addonMods.RemovePulse(meleePulse)
	end
end

local function cancelTicker()
	if not Ticker then return end
	Ticker:Cancel()
	Ticker = nil

	MeleeRangeText:SetText('')
	MeleeRangeText:Hide()
	addonMods.RemovePulse(meleePulse)
end

local function startTicker()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(0.5, meleeTimerTick)
end

local function invalidStatus()
	local isDead    = UnitIsDeadOrGhost('player')
	local isMounted = IsMounted()
	local hasTarget = UnitExists('target')
	local canAttack = UnitCanAttack('player', 'target')

	return isDead or isMounted or not hasTarget or not canAttack
end

local function enterCombat()
	if not invalidStatus() then
		startTicker()
	else
		cancelTicker()
	end
end

local function targetChanged()
	if not InCombatLockdown() or invalidStatus() then
		cancelTicker()
		return
	end
	enterCombat()
end

local function checkSpec()
	local specIndex   = C_SpecializationInfo.GetSpecialization()
	local specId      = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local isValidSpec = VALID_SPECS[specId]
	meleeSpellId 			= VALID_SPECS[specId]

	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)
	if isValidSpec then
		addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', targetChanged)
		addonMods.RegisterEventHandler('PLAYER_TARGET_CHANGED', targetChanged)
		addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', cancelTicker)
	else
		addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', targetChanged)
		addonMods.UnregisterEventHandler('PLAYER_TARGET_CHANGED', targetChanged)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_ENABLED', cancelTicker)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)