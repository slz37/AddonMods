---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local ITEM_ID = 188152
local COLOR   = {r = 135/255, g = 136/255, b = 238/255}

-- Create visuals
---@param pos number
---@param color table<string, number>
---@return FontString
local function createText(pos, color)
	local text = UIParent:CreateFontString(nil, 'OVERLAY')
	text:Hide()

	---@cast fontFlags string
	text:SetFont(font, 18, fontFlags)
	text:SetText('Gate Usable')
	text:SetTextColor(color.r, color.g, color.b)

	local statusGroup = addonMods.GetOrCreateDynamicGroup('TopText', {
		point         = 'BOTTOM',
		relativeTo    = UIParent,
		relativePoint = 'CENTER',
		x             = 1,
		y             = 88,
		direction     = 'UP',
		spacing       = -4,
	})
	statusGroup:AddMember(text, pos)

	return text
end
local gatewayText = createText(5, COLOR)

local function actionBarUpdateUsable()
	local canUse = C_Item.IsUsableItem(ITEM_ID)

	if canUse then
		gatewayText:Show()
	else
		gatewayText:Hide()
	end
end

-- Event Registration
addonMods.RegisterEventHandler('ACTIONBAR_UPDATE_USABLE', actionBarUpdateUsable)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', actionBarUpdateUsable)