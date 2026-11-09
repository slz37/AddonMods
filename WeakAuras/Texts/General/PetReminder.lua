---@type string, addonMods
local _, addonMods = ...

local VALID_CLASSES = {
	['DEATHKNIGHT'] = true,
	['WARLOCK'] 		= true,
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
local FLASH_COLOR = {r = 216/255, g = 108/255, b = 108/255}

-- Create visuals
local PetText = UIParent:CreateFontString(nil, 'OVERLAY')
PetText:Hide()

---@cast fontFlags string
PetText:SetFont(font, 18, fontFlags)
PetText:SetText('No Pet')

local statusGroup = addonMods.GetOrCreateDynamicGroup('StatusText', {
	point         = 'BOTTOM',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 1,
	y             = -82,
	direction     = 'UP',
	spacing       = -4,
})
statusGroup:AddMember(PetText, 1)
local petPulse = addonMods.CreatePulse(PetText, 0.5, FLASH_COLOR, 1)

local function hideText()
	PetText:Hide()
	addonMods.RemovePulse(petPulse)
end

local function showText()
	PetText:Show()
	addonMods.AddPulse(petPulse)
end

---@return boolean
local function invalidStatus()
	local isDead    = UnitIsDeadOrGhost('player')
	local isMounted = IsMounted()

	return isDead or isMounted
end

local function checkPet()
	if invalidStatus() then hideText() return end

	local hasPet = UnitExists('pet')
	if hasPet then
		hideText()
	else
		showText()
	end
end

local function checkSpec()
	local specIndex 	= C_SpecializationInfo.GetSpecialization()
	local specId 			= C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local isValidSpec = VALID_SPECS[specId]

	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)
	if isValidSpec then
		addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkPet)
		addonMods.RegisterEventHandler('PLAYER_MOUNT_DISPLAY_CHANGED', checkPet)
		addonMods.RegisterUnitEventHandler('UNIT_PET', 'player', checkPet)
		checkPet()
	else
		hideText()
		addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', checkPet)
		addonMods.UnregisterEventHandler('PLAYER_MOUNT_DISPLAY_CHANGED', checkPet)
		addonMods.UnregisterUnitEventHandler('UNIT_PET', 'player', checkPet)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)