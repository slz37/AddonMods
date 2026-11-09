---@type string, addonMods
local _, addonMods = ...
if addonMods.myClass ~= 'PRIEST' then return end

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local FLASH_COLOR   = {r = 216/255, g = 108/255, b = 108/255}

-- Create visuals
local FormText = UIParent:CreateFontString(nil, 'OVERLAY')
FormText:Hide()

---@cast fontFlags string
FormText:SetFont(font, 18, fontFlags)

local statusGroup = addonMods.GetOrCreateDynamicGroup('StatusText', {
	point         = 'BOTTOM',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 1,
	y             = -82,
	direction     = 'UP',
	spacing       = -4,
})
statusGroup:AddMember(FormText, 3)
local formPulse = addonMods.CreatePulse(FormText, 0.5, FLASH_COLOR, 1)

local function checkForm()
	if UnitIsDead('player') then return end
	local form = GetShapeshiftForm()

	local text, hasText = '', false
	if form == 0 then
		text = 'Shadowform'
		hasText = true
	end

	FormText:SetText(text)
	FormText:SetShown(hasText)
	if hasText then
		addonMods.AddPulse(formPulse)
	else
		addonMods.RemovePulse(formPulse)
	end
end

local function checkSpec()
	local specIndex   = C_SpecializationInfo.GetSpecialization()
	local specId      = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local isValidSpec = specId == 258

	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)
	if isValidSpec then
		addonMods.RegisterEventHandler('UPDATE_SHAPESHIFT_FORM', checkForm)
		addonMods.RegisterEventHandler('PLAYER_ALIVE', checkForm)
		checkForm()
	else
		addonMods.UnregisterEventHandler('UPDATE_SHAPESHIFT_FORM', checkForm)
		addonMods.UnregisterEventHandler('PLAYER_ALIVE', checkForm)
		FormText:Hide()
		addonMods.RemovePulse(formPulse)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)