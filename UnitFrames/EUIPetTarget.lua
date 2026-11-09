---@type string, addonMods
local _, addonMods = ...
if not EllesmereUI then return end

local font = addonMods.defaultFont

local VALID_SPECS = {
	[252] = true, -- Unholy
	[265] = true, -- Affliction
	[266] = true, -- Demonology
	[267] = true, -- Destruction
}

local PetTarget
local function createText()
	local PetFrame = _G['EllesmereUIUnitFrames_Pet']._textOverlay

	PetTarget = PetFrame:CreateFontString()
	PetTarget:SetPoint('CENTER', PetFrame, 'CENTER', 0, 0)
	PetTarget:SetFont(font, 12, 'OUTLINE, SLUG')
end

local function checkPetTarget()
	local targetName = UnitName('pettarget')

	if targetName then
		PetTarget:SetText('» ' .. targetName)
	else
		PetTarget:SetText('')
	end
end

local function checkSpec()
	local specIndex 	= C_SpecializationInfo.GetSpecialization()
	local specId 			= C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local isValidSpec = VALID_SPECS[specId]

	if isValidSpec then
		addonMods.RegisterUnitEventHandler('UNIT_TARGET', 'pet', checkPetTarget)
		addonMods.RegisterUnitEventHandler('UNIT_PET', 'player', checkPetTarget)
		checkPetTarget()
	else
		PetTarget:SetText('')
		addonMods.UnregisterUnitEventHandler('UNIT_TARGET', 'pet', checkPetTarget)
		addonMods.UnregisterUnitEventHandler('UNIT_PET', 'player', checkPetTarget)
	end
end

---@param isLogin boolean
---@param isReload boolean
local function playerEnteringWorld(_, isLogin, isReload)
	if isLogin or isReload then createText() end
	checkSpec()
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)