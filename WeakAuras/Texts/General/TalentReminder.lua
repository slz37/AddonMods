---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local FLASH_COLOR = {r = 216/255, g = 108/255, b = 108/255}
local SOUND_PATH  = 'Interface\\AddOns\\AddonMods\\Media\\Sounds\\IM.ogg'

local INSTANCE_LOADOUTS = {
	['MP']   = 'M+',
	['Raid'] = {
		['The Tidebound Grotto'] 		  = 'Nymrissa',
		['The Soulcoil Well']         = 'Nekzali',
		['The Venomducts']            = 'Sentinels',
		['The Chamber of Virulence']  = 'Vashnik',
		['Mor\'zahi\'s Tomb']         = 'Explorers',
		['Altar of the Six Winds']    = 'Sszorak',
		['Pit of Fangs']              = 'Fangs',
		['The Coiled Altar']          = 'Altar',
		['The Tomb of Ula\'tek']      = 'Ulatek',
		['The Unbinding of Kith\'ix'] = 'Kithix',
	},
}

-- Create visuals
local TalentText = UIParent:CreateFontString(nil, 'OVERLAY')
TalentText:Hide()

---@cast fontFlags string
TalentText:SetFont(font, 18, fontFlags)
TalentText:SetText('Check Talents')

local statusGroup = addonMods.GetOrCreateDynamicGroup('StatusText', {
	point         = 'BOTTOM',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 1,
	y             = -82,
	direction     = 'UP',
	spacing       = -4,
})
statusGroup:AddMember(TalentText, 1)
local talentPulse = addonMods.CreatePulse(TalentText, 0.5, FLASH_COLOR, 1)

local function checkTalents()
	RunNextFrame(function()
		local _,_, difficultyId  = GetInstanceInfo()

		local specIndex = C_SpecializationInfo.GetSpecialization()
		if not specIndex then return end

		local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		if not specId or specId == 0 then return end

		local configId = C_ClassTalents.GetLastSelectedSavedConfigID(specId)
		if not configId then return end

		local configInfo = C_Traits.GetConfigInfo(configId)
		if not configInfo then return end

		local currentLoadoutName = configInfo.name

		local loadoutName
		if difficultyId == 23 then -- Can't change talents in M+, so just look for mythic dungeon
			loadoutName = INSTANCE_LOADOUTS['MP']
		elseif difficultyId == 15 or difficultyId == 16 or difficultyId == 233 then
			local zoneText    = GetZoneText()
			local subzoneText = GetSubZoneText()
			if not zoneText and not subzoneText then return end

			local loadouts = INSTANCE_LOADOUTS['Raid']
			loadoutName 	 = loadouts[zoneText] or loadouts[subzoneText]
		else
			TalentText:Hide()
			addonMods.RemovePulse(talentPulse)
			return
		end

		if loadoutName and currentLoadoutName ~= loadoutName and not InCombatLockdown() then
			if not TalentText:IsShown() then PlaySoundFile(SOUND_PATH, 'Master') end -- Don't spam sounds
			TalentText:Show()
			addonMods.AddPulse(talentPulse)
		else
			TalentText:Hide()
			addonMods.RemovePulse(talentPulse)
		end
	end)
end

addonMods.RegisterEventHandler('CHALLENGE_MODE_START', checkTalents)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', checkTalents)
addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', checkTalents)
addonMods.RegisterEventHandler('PLAYER_TALENT_UPDATE', checkTalents)
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkTalents)
addonMods.RegisterEventHandler('TRAIT_CONFIG_UPDATED', checkTalents)
addonMods.RegisterEventHandler('ZONE_CHANGED', checkTalents)
addonMods.RegisterEventHandler('ZONE_CHANGED_INDOORS', checkTalents)
addonMods.RegisterEventHandler('ZONE_CHANGED_NEW_AREA', checkTalents)