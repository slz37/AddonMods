---@type string, addonMods
local _, addonMods = ...

local function checkPass()
	local shouldPass = IsInRaid() and InGuildParty()

	if GetOptOutOfLoot() == shouldPass then return end
	SetOptOutOfLoot(shouldPass)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkPass)
addonMods.RegisterEventHandler('GROUP_ROSTER_UPDATE', checkPass)