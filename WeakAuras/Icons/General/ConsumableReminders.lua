---@type string, addonMods
local _, addonMods = ...

local texture	= addonMods.defaultTexture
local font		= addonMods.defaultFont

local FLASK_BUFF_IDS = {
	1235110, -- Flask of the Blood Knights
	1235108, -- Flask of the Magisters
	1235111, -- Flask of the Shattered Sun
	1235057, -- Flask of Thalassian Resistance
	1239355, -- Vicious Thalassian Flask of Honor (PvP)
}
local AUGMENT_RUNE_BUFF_IDS = {1264426}
local PHOENIX_OIL_ENCH_IDS  = {[8051] = true, [8052] = true}
local FOOD_BUFF_NAMES  			= {'Well Fed', 'Hearty Well Fed'}

local icons = {}
local function createIcons()
	local consumableGroup = addonMods.GetOrCreateDynamicGroup('ConsumableIcons', {
		point         = 'CENTER',
		relativeTo    = UIParent,
		relativePoint = 'CENTER',
		x             = 0,
		y             = 200,
		direction     = 'CENTEREDHORIZONTAL',
		spacing       = 1,
	})

	---@param iconId number
	---@param useText boolean?
	---@return table<string, any>
	local function createIcon(iconId, useText)
		local config = {
			w               = 48,
			h               = 48,
			zoom            = 0.3,
			keepAspectRatio = true,
			scaleX          = 1,
			scaleY          = 1,
			texXOffset      = 0,
			texYOffset      = 0,
			inGroup         = true,
			texture         = iconId,
			desaturated     = true,
			borders = {
				{
					inset       = 0,
					edgeFile    = texture,
					edgeSize    = 2,
					borderColor = {r = 0, g = 0, b = 0, a = 1},
					levelOffset = 2,
				},
			},
		}
		if useText then
			config['texts'] = {
				label = {
					font              = font,
					fontSize          = 18,
					fontFlags         = 'OUTLINE, SLUG',
					fontAnchorPoint   = 'CENTER',
					fontRelativePoint = 'CENTER',
					fontXOffset       = 0,
					fontYOffset       = 0,
					fontColor         = {r = 1, g = 1, b = 1, a = 1},
				}
			}
		end
		return addonMods.NewIcon(config)
	end

	icons = {
		food  = createIcon(136000),
		flask = createIcon(7548902),
		rune  = createIcon(4549099),
		mh    = createIcon(7548987, true),
		oh    = createIcon(7548987, true),
	}

	icons.mh.texts.label:SetText('MH')
	icons.oh.texts.label:SetText('OH')

	consumableGroup:AddMember(icons.flask, 1)
	consumableGroup:AddMember(icons.food,  2)
	consumableGroup:AddMember(icons.mh,    3)
	consumableGroup:AddMember(icons.oh,    4)
	consumableGroup:AddMember(icons.rune,  5)
end

---@param auras table<string, any>
---@param checkName boolean?
---@return boolean
local function hasAnyAura(auras, checkName)
	for _, spell in pairs(auras) do
		if checkName and C_UnitAuras.GetAuraDataBySpellName('player', spell) then
			return true
		elseif C_UnitAuras.GetPlayerAuraBySpellID(spell) then
			return true
		end
	end
	return false
end

---@return boolean
local function validState()
	local _, instanceType = GetInstanceInfo()
	local inGroup 				= IsInGroup()
	local inInstance 			= instanceType and (instanceType == 'party' or instanceType == 'raid')
	local inCombat				= InCombatLockdown()
	local isDead 					= UnitIsDead('player')
	local inMythicPlus 		= C_ChallengeMode.IsChallengeModeActive()
	local aurasSecret 		= C_Secrets.ShouldAurasBeSecret()

	return inGroup and inInstance and not inCombat and not isDead and not inMythicPlus and not aurasSecret
end

---@param unit string
local function checkConsumables(_, unit)
	RunNextFrame(function()
		if unit ~= 'player' or not validState() then return end

		icons.food:SetShown(not hasAnyAura(FOOD_BUFF_NAMES, true))
		icons.flask:SetShown(not hasAnyAura(FLASK_BUFF_IDS, false))
		icons.rune:SetShown(not hasAnyAura(AUGMENT_RUNE_BUFF_IDS, false))

		local _,_,_, mhEnchId, _,_,_, ohEnchId = GetWeaponEnchantInfo()
		local hasMH = GetInventoryItemID('player', 16)
		local hasOH = GetInventoryItemID('player', 17)

		local isWeapon
		if hasOH then
			local _,_,_,_,_,_,_,_, itemEquipLoc = C_Item.GetItemInfo(hasOH)
			isWeapon = itemEquipLoc == 'INVTYPE_WEAPONOFFHAND' or itemEquipLoc == 'INVTYPE_WEAPON'
		end

		icons.mh:SetShown(hasMH and not PHOENIX_OIL_ENCH_IDS[mhEnchId])
		icons.oh:SetShown(hasOH and isWeapon and not PHOENIX_OIL_ENCH_IDS[ohEnchId])
	end)
end

local function checkWeapon()
	checkConsumables(nil, 'player')
end

---@param isLogin boolean?
---@param isReload boolean?
local function checkState(_, isLogin, isReload)
	if isLogin or isReload then createIcons() end -- Need to wait until PEW for unit frame to exist

	RunNextFrame(function() -- Must delay for InCombatLockdown()
		if validState() then
			addonMods.RegisterUnitEventHandler('UNIT_AURA', 'player', checkConsumables)
			addonMods.RegisterEventHandler('WEAPON_ENCHANT_CHANGED', checkWeapon)
			checkConsumables(nil, 'player')
		else
			addonMods.UnregisterUnitEventHandler('UNIT_AURA', 'player', checkConsumables)
			addonMods.UnregisterEventHandler('WEAPON_ENCHANT_CHANGED', checkWeapon)
			for _, icon in pairs(icons) do icon:Hide() end
		end
	end)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkState)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', checkState)
addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', checkState)
addonMods.RegisterEventHandler('PLAYER_ALIVE', checkState)

-- Force 0 args passed to checkState
addonMods.RegisterEventHandler('ENCOUNTER_START', function() checkState() end)
addonMods.RegisterEventHandler('ENCOUNTER_END', function() checkState() end)
addonMods.RegisterEventHandler('CHALLENGE_MODE_START', function() checkState() end)