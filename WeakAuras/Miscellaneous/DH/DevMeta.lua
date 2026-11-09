---@type string, addonMods
local _, addonMods = ...
if addonMods.myClass ~= 'DEMONHUNTER' then return end

local META_ID 	 = 1217605
local SOUND_PATH = 'Interface\\Addons\\AddonMods\\Media\\Sounds\\Plater Wood.ogg'

---@param spellId number
local function checkUsable(_, spellId)
	if spellId ~= META_ID then return end

	local isUsable = C_Spell.IsSpellUsable(META_ID)
	if isUsable then PlaySoundFile(SOUND_PATH, 'Master') end
end

local function checkSpec()
	local specIndex = C_SpecializationInfo.GetSpecialization()
	local specId    = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	
	if specId == 1480 then
		addonMods.RegisterEventHandler('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW', checkUsable)
		checkUsable(nil, META_ID) -- Force check on PEW
	else
		addonMods.UnregisterEventHandler('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW', checkUsable)
	end
end

addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkSpec)