---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture
local font    = addonMods.defaultFont

local AFFIX_CD  = 75
local CAST_TIME = 3

local active      = false
local delaying    = false
local remaining   = AFFIX_CD
local startTime, ExpirationTimer, DelayTimer

local startTimer -- Necessary function upvalue

local AffixTimerBar = addonMods.NewBar({
	w              = 225,
  h              = 22.5,
  anchorPoint    = 'CENTER',
  relativePoint  = 'CENTER',
  relativeFrame  = UIParent,
  xOffset        = 0,
  yOffset        = 300,
  texture        = texture,
  color          = {0.573, 0.247, 0.247, 1},
  min            = 0,
  bgColor        = {0, 0, 0, 0.66},
  max            = 1,
  smoothProgress = false,
	spark = {
		w         = 2,
		texture   = texture,
		blendMode = 'ADD',
		color     = {r = 1, g = 1, b = 1, a = 1},
	},
	borders = {
		{
			inset       = 0,
			edgeFile    = texture,
			edgeSize    = 1,
			borderColor = {r = 0, g = 0, b = 0, a = 1},
			levelOffset = -1,
		},
	},
	texts = {
		name = {
			font              = font,
			fontSize          = 16,
			fontFlags         = 'OUTLINE, SLUG',
			fontAnchorPoint   = 'LEFT',
			fontRelativePoint = 'LEFT',
			fontXOffset       = 1,
			fontYOffset       = 0,
			fontColor         = {r = 1, g = 1, b = 1, a = 1},
			parent					  = 1
		},
		duration = {
			font              = font,
			fontSize          = 16,
			fontFlags         = 'OUTLINE, SLUG',
			fontAnchorPoint   = 'RIGHT',
			fontRelativePoint = 'RIGHT',
			fontXOffset       = 0,
			fontYOffset       = 0,
			fontColor         = {r = 1, g = 1, b = 1, a = 1},
			parent					  = 1
		},
		totalDuration = {
			font              = font,
			fontSize          = 16,
			fontFlags         = 'OUTLINE, SLUG',
			fontAnchorPoint   = 'RIGHT',
			fontRelativePoint = 'RIGHT',
			fontXOffset       = 0,
			fontYOffset       = 0,
			fontColor         = {r = 1, g = 1, b = 1, a = 1},
			parent					  = 1
		},
	},
})

local AFFIX_NAMES = {
	[160] = 'Heal Absorb', 	-- Devour
	[148] = 'CC Orbs', 			-- Ascendant
	[158] = 'Kill Add',		 	-- Voidbound
	[162] = 'Touch Orbs', 	-- Pulsar
}
local affixes = C_MythicPlus.GetCurrentAffixes()
for _, affixData in ipairs(affixes) do
	local affixId   = affixData.id
	local affixName = AFFIX_NAMES[affixId]
	if affixName then
		AffixTimerBar.texts.name:SetText(affixName)
		break
	end
end

AffixTimerBar.texts.duration:ClearAllPoints()
AffixTimerBar.texts.duration:SetPoint('RIGHT', AffixTimerBar.texts.totalDuration, 'LEFT', 3, 0)
AffixTimerBar.texts.totalDuration:SetText('/' .. '1:15')

-- Use alpha to avoid secret taint with GetWidth()
AffixTimerBar:Show()
AffixTimerBar:SetAlpha(0)

if AffixTimerBar.Spark then
	AffixTimerBar.Spark:ClearAllPoints()
	AffixTimerBar.Spark:SetPoint('CENTER', AffixTimerBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
end

---@param time number
---@return string
local function formatTime(time)
	if time < 10.01 then return string.format('%.1f', time) end
	if time < 60 then return string.format('%d', time) end
	return string.format('%d:%02d', math.floor(time / 60), math.floor(time % 60))
end

local function onUpdate()
	if not startTime then return end
	local left = math.max(0, remaining - (GetTime() - startTime))
	AffixTimerBar:SetValue(left / AFFIX_CD)
	AffixTimerBar.texts.duration:SetText(formatTime(left))
end

local function showPaused()
	AffixTimerBar:SetValue(remaining / AFFIX_CD)
	AffixTimerBar.texts.duration:SetText(formatTime(remaining))
end

---@return boolean
local function partyInCombat()
	if UnitAffectingCombat('player') then return true end
	for i = 1, 4 do
		local unit = 'party' .. i
		if UnitExists(unit) and UnitAffectingCombat(unit) then return true end
	end
	return false
end

local function restartTimer()
	DelayTimer = nil
	delaying   = false
	remaining  = AFFIX_CD
	showPaused()

	if active and partyInCombat() then startTimer() end
end

local function onExpire()
	ExpirationTimer = nil
	startTime       = nil
	remaining       = 0
	delaying        = true
	AffixTimerBar:RemoveCallback()
	showPaused() -- shows 0.0 during the delay

	if DelayTimer then DelayTimer:Cancel() end
	DelayTimer = C_Timer.NewTimer(CAST_TIME, restartTimer)
end

function startTimer()
	if startTime or delaying then return end
	startTime = GetTime()

	AffixTimerBar:AddCallback(onUpdate)

	if ExpirationTimer then
		ExpirationTimer:Cancel()
		ExpirationTimer = nil
	end
	ExpirationTimer = C_Timer.NewTimer(remaining, onExpire)
end

local function pauseTimer()
	if not startTime then return end

	if ExpirationTimer then
		ExpirationTimer:Cancel()
		ExpirationTimer = nil
	end

	remaining = math.max(0, remaining - (GetTime() - startTime))
	startTime = nil

	AffixTimerBar:RemoveCallback()
	showPaused()
end

local function stopTimer()
	if ExpirationTimer then
		ExpirationTimer:Cancel()
		ExpirationTimer = nil
	end
	if DelayTimer then
		DelayTimer:Cancel()
		DelayTimer = nil
	end

	delaying  = false
	startTime = nil
	remaining = AFFIX_CD
	AffixTimerBar:RemoveCallback()
	showPaused()
end

---@param e string
---@param unit string
local function checkCombat(e, unit)
	if e == 'UNIT_FLAGS' then
		if unit ~= 'player' and not (unit and unit:find('^party%d$')) then return end
	end

	if partyInCombat() then
		startTimer()
	else
		pauseTimer()
	end
end

local function startDungeon()
	local currentLevel = C_ChallengeMode.GetActiveKeystoneInfo()
	if currentLevel <= 4 or currentLevel >= 12 then return end

	if active then return end
	active = true

	addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', checkCombat)
	addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', checkCombat)
	addonMods.RegisterEventHandler('GROUP_ROSTER_UPDATE', checkCombat)
	addonMods.RegisterEventHandler('UNIT_FLAGS', checkCombat)

	AffixTimerBar:SetAlpha(1)
	showPaused()
end

local function endDungeon()
	if active then
		active = false

		addonMods.UnregisterEventHandler('PLAYER_REGEN_DISABLED', checkCombat)
		addonMods.UnregisterEventHandler('PLAYER_REGEN_ENABLED', checkCombat)
		addonMods.UnregisterEventHandler('GROUP_ROSTER_UPDATE', checkCombat)
		addonMods.UnregisterEventHandler('UNIT_FLAGS', checkCombat)
	end

	stopTimer()
	AffixTimerBar:SetAlpha(0)
end

---@return boolean
local function validState()
	local _, instanceType = GetInstanceInfo()
	local inInstance 			= instanceType and instanceType == 'party'
	return inInstance
end

local function checkState()
	if validState() then
		addonMods.RegisterEventHandler('CHALLENGE_MODE_START', startDungeon)
		addonMods.RegisterEventHandler('CHALLENGE_MODE_COMPLETED', endDungeon)
	else
		addonMods.UnregisterEventHandler('CHALLENGE_MODE_START', startDungeon)
		addonMods.UnregisterEventHandler('CHALLENGE_MODE_COMPLETED', endDungeon)

		endDungeon()
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkState)