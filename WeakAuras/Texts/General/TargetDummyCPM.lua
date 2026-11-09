---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'
---@cast fontFlags string

local SHADOWMELD_ID 		= 58984
local HEADER            = 'Spell Counter'
local PRECOMBAT_WINDOW  = 1
local COMBAT_END_GRACE  = 30
local VALID_ZONES = {
	['Dornogal']        = true,
	['Silvermoon City'] = true,
}

local CPMText = UIParent:CreateFontString(nil, 'OVERLAY')

CPMText:SetPoint('CENTER', -600, 100)
CPMText:SetFont(font, 24, fontFlags)
CPMText:SetJustifyH('LEFT')
CPMText:SetText(HEADER)

local spellCounter  = {}
local trackedSpells = {}
local pendingCasts  = {}
local inGrace 			= false
local Ticker, combatStartTime, EndTimer

local blacklist = {
	[15286]   = true, -- Vampiric Embrace
	[1250533] = true, -- Freighrunner's Flask
	[1263768] = true, -- Lightspire Core
}

---@param spellId number
local function countSpell(spellId)
	if not spellCounter[spellId] then table.insert(trackedSpells, spellId) end
	spellCounter[spellId] = (spellCounter[spellId] or 0) + 1
end

local function updateText()
	local combatTimeSeconds = GetTime() - combatStartTime
	local combatTimeMinutes = (combatTimeSeconds) / 60

	local minutes = floor(combatTimeMinutes)
	local seconds = combatTimeSeconds % 60
	local text = HEADER .. ' ' .. string.format('%02d:%04.1f', minutes, seconds)

	-- Sort by CPM
	table.sort(trackedSpells, function(a, b)
		local cpmA = spellCounter[a] / combatTimeMinutes
		local cpmB = spellCounter[b] / combatTimeMinutes
		return cpmA > cpmB
	end)

	for _, spellId in ipairs(trackedSpells) do
		local count     = spellCounter[spellId]
		local spellName = C_Spell.GetSpellName(spellId)
		local cpm       = count / combatTimeMinutes

		text = text .. '\n' .. spellName .. ' - ' .. count .. '(' .. string.format('%.1f', cpm) .. ')'
	end
	CPMText:SetText(text)
end

local function resetText()
	wipe(spellCounter)
	wipe(trackedSpells)

	local now = GetTime()
	combatStartTime = now

	-- Check spell buffer
	for _, cast in ipairs(pendingCasts) do
		if now - cast.t <= PRECOMBAT_WINDOW then
			countSpell(cast.id)
			if cast.t < combatStartTime then combatStartTime = cast.t end
		end
	end
	wipe(pendingCasts)

	CPMText:SetText(HEADER)
	Ticker = C_Timer.NewTicker(0.1, updateText)
end

local function stopCombat()
	if Ticker then
		Ticker:Cancel()
		Ticker = nil
	end
	combatStartTime = nil
	wipe(pendingCasts)
end

local function enterCombat()
	if inGrace then return end
	resetText()
end

local function leaveCombat()
	if inGrace then return end

	inGrace = true
	if Ticker then
		Ticker:Cancel()
		Ticker = nil
	end

	-- Set grace timer to prevent entering/leaving combat multiple times and wiping counter
	EndTimer = C_Timer.NewTimer(COMBAT_END_GRACE, function()
		EndTimer = nil
		inGrace  = false
		stopCombat()
	end)
end

---@param unit string
---@param spellId number
local function addSpell(_, unit, _, spellId)
	if inGrace or unit ~= 'player' or blacklist[spellId] then return end

	-- Force stop counter if shadowmeld is cast
	if spellId == SHADOWMELD_ID then
		leaveCombat()
		return
	end

	-- Buffer spells cast 1s before PLAYER_REGEN_DISABLED
	if not combatStartTime then
		local now = GetTime()
		for i = #pendingCasts, 1, -1 do
			if now - pendingCasts[i].t > PRECOMBAT_WINDOW then
				table.remove(pendingCasts, i)
			end
		end
		table.insert(pendingCasts, {id = spellId, t = now})
		return
	end

	countSpell(spellId)
end

local function checkZone()
	local zoneName = GetZoneText()

	if VALID_ZONES[zoneName] then
		addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', addSpell)
		addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', leaveCombat)
		CPMText:Show()
	else
		addonMods.UnregisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', addSpell)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_ENABLED', leaveCombat)
		CPMText:Hide()

		EndTimer = nil
		inGrace  = false

		wipe(spellCounter)
		wipe(trackedSpells)
		wipe(pendingCasts)

		if Ticker then
			Ticker:Cancel()
			Ticker = nil
		end
		if EndTimer then
			EndTimer:Cancel()
			EndTimer = nil
		end
	end
end

-- Event Registration
addonMods.RegisterEventHandler('ZONE_CHANGED', checkZone)
addonMods.RegisterEventHandler('ZONE_CHANGED_NEW_AREA', checkZone)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkZone)