---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local BONUS_ROLL_ID = 3418

-- Create visuals
local BonusRollText = UIParent:CreateFontString(nil, 'OVERLAY')
BonusRollText:Hide()

---@cast fontFlags string
BonusRollText:SetFont(font, 18, fontFlags)

local statusGroup = addonMods.GetOrCreateDynamicGroup('TopText', {
  point         = 'BOTTOM',
  relativeTo    = UIParent,
  relativePoint = 'CENTER',
  x             = 1,
  y             = 88,
  direction     = 'UP',
  spacing       = -4,
})
statusGroup:AddMember(BonusRollText, 5)

local function hideText()
	BonusRollText:Hide()
end

local function checkRolls()
  local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(BONUS_ROLL_ID)
  local current      = currencyInfo.quantity
  local remaining    = currencyInfo.maxQuantity - currencyInfo.totalEarned + current

	if remaining > 0 then
		BonusRollText:SetText('Bonus Rolls - ' .. current .. '/' .. remaining)
		BonusRollText:Show()
	else
		hideText()
	end
end

---@param currencyType number
local function checkCurrency(_, currencyType)
  if currencyType ~= BONUS_ROLL_ID then return end
  checkRolls()
end

local function checkInstance()
	RunNextFrame(function()
		local _,_, difficultyId = GetInstanceInfo()
		local dungeonStarted    = C_ChallengeMode.IsChallengeModeActive()
		if (difficultyId == 8 and not dungeonStarted) or difficultyId == 23 or difficultyId == 15 or difficultyId == 16 or difficultyId == 233 then
			addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', checkRolls)
			addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', hideText)
			addonMods.RegisterEventHandler('CURRENCY_DISPLAY_UPDATE', checkCurrency)
			checkRolls()
		else
			addonMods.UnregisterEventHandler('PLAYER_REGEN_ENABLED', checkRolls)
			addonMods.UnregisterEventHandler('PLAYER_REGEN_DISABLED', hideText)
			addonMods.UnregisterEventHandler('CURRENCY_DISPLAY_UPDATE', checkCurrency)
			hideText()
		end
	end)
end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkInstance)
addonMods.RegisterEventHandler('CHALLENGE_MODE_START', checkInstance)
addonMods.RegisterEventHandler('CHALLENGE_MODE_COMPLETED', checkInstance)