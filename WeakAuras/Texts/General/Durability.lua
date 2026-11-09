---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local COLORS = {
	mid = {r = 179/255, g = 106/255, b = 54/255},
	low = {r = 179/255, g = 54/255,  b = 54/255},
}

-- Create visuals
local DurabilityText = UIParent:CreateFontString(nil, 'OVERLAY')
DurabilityText:Hide()

---@cast fontFlags string
DurabilityText:SetFont(font, 18, fontFlags)
DurabilityText:SetText('Low Durability')

local statusGroup = addonMods.GetOrCreateDynamicGroup('StatusText', {
	point         = 'BOTTOM',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 1,
	y             = -82,
	direction     = 'UP',
	spacing       = -4,
})
statusGroup:AddMember(DurabilityText, 1)
local durabilityFlash = addonMods.CreateFlash(DurabilityText)

local function hideText()
	DurabilityText:Hide()
	addonMods.RemoveFlash(durabilityFlash)
end

local function showText()
	DurabilityText:Show()
	addonMods.AddFlash(durabilityFlash)
end

---@return boolean
local function invalidStatus()
	local inCombat = InCombatLockdown()
	return inCombat
end

local function checkDurability()
	RunNextFrame(function()
		if invalidStatus() then return hideText() end

		local minDur = 100
		local curDur, maxDur = 0,  0

		for i = 1, 18 do
			local itemCur, itemMax = GetInventoryItemDurability(i)
			curDur = curDur + (itemCur or 0)
			maxDur = maxDur + (itemMax or 0)

			local newMinDur = ((itemCur or 1) / (itemMax or 1)) * 100
			if newMinDur < minDur then minDur = newMinDur end
		end

		if maxDur == 0 then return hideText() end -- Naked

		local averageDur = curDur / maxDur * 100
		if averageDur <= 20 or minDur <= 20 then
			DurabilityText:SetTextColor(COLORS.low.r, COLORS.low.g, COLORS.low.b)
			showText()
		elseif averageDur <= 40 or minDur <= 30 then
			DurabilityText:SetTextColor(COLORS.mid.r, COLORS.mid.g, COLORS.mid.b)
			showText()
		else
			hideText()
		end
	end)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkDurability)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', checkDurability)
addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', hideText)
addonMods.RegisterEventHandler('UPDATE_INVENTORY_DURABILITY', checkDurability)
addonMods.RegisterEventHandler('PLAYER_DEAD', checkDurability)
addonMods.RegisterEventHandler('PLAYER_ALIVE', checkDurability)