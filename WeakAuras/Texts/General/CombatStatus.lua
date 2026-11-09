---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local Timer

-- Create visuals
local StatusText = UIParent:CreateFontString(nil, 'OVERLAY')
---@cast fontFlags string
StatusText:SetFont(font, 18, fontFlags)
StatusText:Hide()

local statusGroup = addonMods.GetOrCreateDynamicGroup('TopText', {
  point         = 'BOTTOM',
  relativeTo    = UIParent,
  relativePoint = 'CENTER',
  x             = 1,
  y             = 88,
  direction     = 'UP',
  spacing       = -4,
})
statusGroup:AddMember(StatusText, 5)

local function cancelTimer()
	if not Timer then return end
	Timer:Cancel()
	Timer = nil
end

local function displayText()
	cancelTimer()

	StatusText:SetAlpha(0)
	StatusText:Show()
	addonMods.FadeIn(StatusText, 0.25)

	Timer = C_Timer.NewTimer(1.5, function()
		addonMods.FadeOut(StatusText, 0.25)
		C_Timer.After(0.25, function() StatusText:Hide() end)
	end)
end

local function enterCombat()
	StatusText:SetText('|cFFad4c4c+Combat|r')
	displayText()
end

local function exitCombat()
	StatusText:SetText('|cFF6a7aea-Combat|r')
	displayText()
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', exitCombat)