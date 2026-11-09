---@type string, addonMods
local _, addonMods = ...

local VALID_CLASSES = {
  ['DEATHKNIGHT'] = true,
  ['DRUID']       = true,
	['WARLOCK'] 		= true,
}
if not VALID_CLASSES[addonMods.myClass] then return end

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local VALID_SPELL_IDS = {
  [61999] = true,
  [20484] = true,
	[20707] = true,
}

-- Create visuals
local BRStatusText = UIParent:CreateFontString(nil, 'OVERLAY')

BRStatusText:SetPoint('CENTER', UIParent, 'CENTER', 1, -82)
---@cast fontFlags string
BRStatusText:SetFont(font, 18, fontFlags)
BRStatusText:Hide()

local function success(_,_,_, spellId)
  if not VALID_SPELL_IDS[spellId] then return end

  BRStatusText:SetText('BR Success')
  BRStatusText:Show()
  C_Timer.After(3, function() BRStatusText:Hide() end)
end

local function failed(_,_,_, spellId)
  if not VALID_SPELL_IDS[spellId] then return end

  BRStatusText:SetText('BR Failed')
  BRStatusText:Show()
  C_Timer.After(3, function() BRStatusText:Hide() end)
end

local function playerEnteringWorld()
	if IsInGroup() then
		addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', success)
		addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_FAILED', 'player', failed)
	else
		addonMods.UnregisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', success)
		addonMods.UnregisterUnitEventHandler('UNIT_SPELLCAST_FAILED', 'player', failed)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)