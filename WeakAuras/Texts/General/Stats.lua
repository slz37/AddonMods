---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'
---@cast fontFlags string

local labelText = UIParent:CreateFontString(nil, 'OVERLAY')
labelText:SetPoint('BOTTOMLEFT', 369, 0)
labelText:SetFont(font, 14, fontFlags)
labelText:SetJustifyH('LEFT')
labelText:SetText('|cff55aaffM:|r\n|cff2ecc71H:|r\n|cffffd100C:|r')

local valueText = UIParent:CreateFontString(nil, 'OVERLAY')
valueText:SetPoint('TOPLEFT', labelText, 'TOPRIGHT', -1, 0)
valueText:SetFont(font, 14, fontFlags)
valueText:SetJustifyH('LEFT')

local function checkStats()
	local mastery = GetCombatRating(CR_MASTERY)
	local haste   = GetCombatRating(CR_HASTE_SPELL)
	local crit    = GetCombatRating(CR_CRIT_SPELL)

	valueText:SetText(string.format('%d\n%d\n%d', mastery, haste, crit))
end

addonMods.RegisterEventHandler('COMBAT_RATING_UPDATE', checkStats)
addonMods.RegisterUnitEventHandler('UNIT_STATS', 'player', checkStats)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkStats)