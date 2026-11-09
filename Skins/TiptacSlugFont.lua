---@type string, addonMods
local _, addonMods = ...
if not TipTac then return end

---@param flags string
---@param newFlag string
local function addFontFlag(flags, newFlag)
	flags = flags or ''

	-- Avoid adding it twice
	for flag in flags:gmatch('[^,%s]+') do
		if flag == newFlag then return flags end
	end

	if flags == '' then
		return newFlag
	else
		return flags .. ', ' .. newFlag
	end
end

local function reapplySlugFlag()
	local GTT  = GameTooltipText
	local GTHT = GameTooltipHeaderText
	local GTTS = GameTooltipTextSmall

	local face, size, flags = GTT:GetFont()
	GTT:SetFont(face, size, addFontFlag(flags, 'SLUG'))

	face, size, flags = GTHT:GetFont()
	GTHT:SetFont(face, size, addFontFlag(flags, 'SLUG'))

	face, size, flags = GTTS:GetFont()
	GTTS:SetFont(face, size, addFontFlag(flags, 'SLUG'))
end

hooksecurefunc(TipTac, 'SetFontToGameTooltip', reapplySlugFlag)