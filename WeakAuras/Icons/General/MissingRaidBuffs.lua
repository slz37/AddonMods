---@type string, addonMods
local _, addonMods = ...

local texture	= addonMods.defaultTexture

local EVOKER_BUFFS = {
	['DEATHKNIGHT'] = 381732,
	['DEMONHUNTER'] = 381741,
	['DRUID']       = 381746,
	['EVOKER']      = 381748,
	['HUNTER']      = 381749,
	['MAGE']        = 381750,
	['MONK']        = 381751,
	['PALADIN']     = 381752,
	['PRIEST']      = 381753,
	['ROGUE']       = 381754,
	['SHAMAN']      = 381756,
	['WARLOCK']     = 381757,
	['WARRIOR']     = 381758,
}

local RAID_BUFFS = {
	['MAGE']    = 1459,
	['PRIEST']  = 21562,
	['DRUID']   = 1126,
	['SHAMAN']  = 462854,
	['WARRIOR'] = 6673,
	['EVOKER']  = EVOKER_BUFFS[addonMods.myClass]
}
local classesInGroup  = {}
local _, instanceType = GetInstanceInfo()

local icons = {}

---@param unit string
local function checkAuras(_, unit)
	if unit ~= 'player' then return end

	for class, spellId in pairs(RAID_BUFFS) do
		icons[spellId]:SetShown(classesInGroup[class] and not C_UnitAuras.GetPlayerAuraBySpellID(spellId))
	end
end

local function checkRoster()
	wipe(classesInGroup)

	for i = 1, GetNumGroupMembers() do
		local unit
		if instanceType == 'party' then
			unit = 'party' .. i
		else
			unit = 'raid' .. i
		end

		local _, class = UnitClass(unit)
		if UnitIsPlayer(unit) and RAID_BUFFS[class] and not classesInGroup[class] then classesInGroup[class] = true end
	end

	-- Only track auras once someone that provides a buff is in group
	if next(classesInGroup) then
		addonMods.RegisterUnitEventHandler('UNIT_AURA', 'player', checkAuras)
		checkAuras(nil, 'player')
	else
		addonMods.UnregisterUnitEventHandler('UNIT_AURA', 'player', checkAuras)
	end
end

---@return boolean
local function validState()
	local _, newInstanceType = GetInstanceInfo()
	instanceType 						 = newInstanceType

	local inGroup			= IsInGroup()
	local inInstance	= instanceType and (instanceType == 'party' or instanceType == 'raid')

	return inGroup and inInstance
end

---@param isLogin boolean
---@param isReload boolean
local function checkState(_, isLogin, isReload)
	if isLogin or isReload then
		local raidBuffGroup = addonMods.GetOrCreateDynamicGroup('RaidBuffIcons', {
			point         = 'RIGHT',
			relativeTo    = EllesmereUIUnitFrames_Player,
			relativePoint = 'LEFT',
			x             = -1,
			y             = 0,
			direction     = 'LEFT',
			spacing       = 1,
		})

		local i = 1
		for _, spellId in pairs(RAID_BUFFS) do
			local iconId = C_Spell.GetSpellTexture(spellId)
			local config = {
				w               = 32,
				h               = 32,
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
			local Icon = addonMods.NewIcon(config)
			icons[spellId] = Icon
			raidBuffGroup:AddMember(Icon, i)
			i = i + 1
		end
	end

	if validState() then
		checkRoster()
		addonMods.RegisterEventHandler('PLAYER_ROLES_ASSIGNED', checkRoster) -- Just listen for changes to group for now
	else
		addonMods.UnregisterUnitEventHandler('UNIT_AURA', 'player', checkAuras)
		addonMods.UnregisterEventHandler('PLAYER_ROLES_ASSIGNED', checkRoster)
		for _, Icon in pairs(icons) do Icon:Hide() end
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkState)