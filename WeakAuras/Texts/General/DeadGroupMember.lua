---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

-- Create visuals
local DeadGroupText = UIParent:CreateFontString(nil, 'OVERLAY')

DeadGroupText:SetPoint('CENTER', UIParent, 'CENTER', 1, -82)
---@cast fontFlags string
DeadGroupText:SetFont(font, 18, fontFlags)
DeadGroupText:Hide()

---@param unitGUID string
local function unitDied(_, unitGUID)
	local _,_,_,_,_, unitName = GetPlayerInfoByGUID(unitGUID)
	if not unitName then return end
	
	-- This can occur when someone leaves your group and then dies
	if issecretvalue(unitGUID) or issecretvalue(unitName) then return end

	unitName = Ambiguate(unitName, 'short')
	if unitName == addonMods.me or not IsGUIDInGroup(unitGUID) or UnitIsFeignDeath(unitName) then return end

	local colorName = addonMods.WA_ClassColorName(unitName)
	DeadGroupText:SetText(colorName .. ' has died')
	DeadGroupText:Show()

	C_Timer.After(3, function() DeadGroupText:Hide() end)
end

local function playerEnteringWorld()
	if IsInGroup() then
		addonMods.RegisterEventHandler('UNIT_DIED', unitDied)
	else
		addonMods.UnregisterEventHandler('UNIT_DIED', unitDied)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)