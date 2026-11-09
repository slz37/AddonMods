---@type string, addonMods
local _, addonMods = ...
if addonMods.myClass ~= 'DEATHKNIGHT' then return end

local texture	= addonMods.defaultTexture
local font		= addonMods.defaultFont

local SR_ID = 343294

local Icon = addonMods.NewIcon({
	w               = 31,
	h               = 25,
	zoom            = 0.3,
	keepAspectRatio = true,
	scaleX          = 1,
	scaleY          = 1,
	texXOffset 			= 0,
	texYOffset 			= 0,
	anchorPoint     = 'CENTER',
	relativeFrame   = UIParent,
	relativePoint   = 'CENTER',
	xOffset         = 1,
	yOffset         = -106,
	texture 				= 636333,
	desaturated			= true,
	borders = {
		{
			inset       = 0,
			edgeFile    = texture,
			edgeSize    = 2,
			borderColor = {r = 0, g = 0, b = 0, a = 1},
			levelOffset = 2,
		},
		{
			inset       = 1,
			edgeFile    = texture,
			edgeSize    = 1,
			borderColor = {r = 244/255, g = 255/255, b = 161/255, a = 1},
			levelOffset = 3,
		},
	},
	texts = {
		duration = {
			font              = font,
			fontSize          = 12,
			fontFlags         = 'OUTLINE, SLUG',
			fontAnchorPoint   = 'CENTER',
			fontRelativePoint = 'CENTER',
			fontXOffset       = 0,
			fontYOffset       = 0,
			fontColor         = {r = 1, g = 1, b = 1, a = 1},
			parent						= 1
		},
	},
})

---@param remaining number
---@return string
local function formatDuration(remaining)
	if remaining >= 3600 then
		return format('%dh', remaining / 3600)
	elseif remaining >= 60 then
		return format('%d:%02d', remaining / 60, remaining % 60)
	elseif remaining > 0 then
		return format('%d', remaining)
	else
		return ''
	end
end

---@return boolean
local function isSoulReaperOnCD()
	local cd = C_Spell.GetSpellCooldown(SR_ID)
	---@diagnostic disable-next-line: undefined-field
	return (cd and cd.isActive and not cd.isOnGCD) or false
end

---@return boolean
local function isSoulReaperCastable()
	local usable = C_Spell.IsSpellUsable and C_Spell.IsSpellUsable(SR_ID)
	return usable == true
end

local function updateSoulReaperVisibility()
	local onCD 			 = isSoulReaperOnCD()
	local isCastable = isSoulReaperCastable()
	local hasTarget	 = UnitExists('target')

	Icon.Icon:SetDesaturated(onCD)
	Icon.borders[2]:SetShown(isCastable and not onCD)
	Icon:SetShown(onCD or (hasTarget and isCastable))

	if not onCD then
		Icon.texts.duration:SetText('')
		Icon:RemoveCallback()
	end
end

---@param self table<string, any>
local function iconOnUpdate(self)
	local start, duration = self.cdStart, self.cdDuration
	if not start or duration == 0 then
		self.texts.duration:SetText('')
		return
	end

	local remaining = (start + duration) - GetTime()
	if remaining <= 0 then
		updateSoulReaperVisibility()
	else
		self.texts.duration:SetText(formatDuration(remaining))
	end
end

---@param unit string
---@param spellId number
local function setCD(_, unit, _, spellId)
	if unit ~= 'player' or spellId ~= SR_ID then return end

	Icon.cdStart    = GetTime()
	Icon.cdDuration = 15
	Icon:AddCallback(iconOnUpdate)
end

local function checkSR()
	if C_SpellBook.IsSpellInSpellBook(SR_ID) then
		addonMods.RegisterEventHandler('PLAYER_TARGET_CHANGED', updateSoulReaperVisibility)
		addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', setCD)
		addonMods.RegisterEventHandler('SPELL_UPDATE_USABLE', updateSoulReaperVisibility)
		updateSoulReaperVisibility()
	else
		addonMods.UnregisterEventHandler('PLAYER_TARGET_CHANGED', updateSoulReaperVisibility)
		addonMods.UnregisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', setCD)
		addonMods.UnregisterEventHandler('SPELL_UPDATE_USABLE', updateSoulReaperVisibility)
		Icon:Hide()
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_LOGIN', checkSR)
addonMods.RegisterEventHandler('TRAIT_CONFIG_UPDATED', checkSR)
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSR)