---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.LSM:Fetch('font', 'Roboto Condensed Bold')
local fontFlags = 'OUTLINE, SLUG'

local BRText, Ticker
local inEncounter = false

-- Create visuals
local function createText()
	BRText = UIParent:CreateFontString(nil, 'OVERLAY')

	---@cast fontFlags string
	BRText:SetFont(font, 16, fontFlags)
	BRText:SetPoint('RIGHT', addonMods.PetFrame, 'TOPRIGHT', -43, 0)
end

local function brTimerTick()
	local time 			= '0:00'
	local spellInfo = C_Spell.GetSpellCharges(20484)

	local charges, maxCharges, cooldownStart, cooldownDuration
	if spellInfo then
		charges 				 = spellInfo.currentCharges
		maxCharges       = spellInfo.maxCharges
		cooldownStart    = spellInfo.cooldownStartTime
		cooldownDuration = spellInfo.cooldownDuration
	end
	if charges == nil then charges = 0 end

	if cooldownStart then
		local timer = cooldownDuration - (GetTime() - cooldownStart)
		time = ('%d:%02d'):format(floor(timer / 60), timer % 60)
	end

	local color = '|cFFFFFFFF'
	if charges < 1 then
		color = '|cFFFF0000'
	elseif charges >= 1 then
		color = '|cFF00FF00'
	end
	if charges == maxCharges then time = '0:00' end

	local text = '[CR:' .. color .. charges .. '|r' .. '||' .. time .. ']'
	BRText:SetText(text)
end

local function cancelTicker()
  if not Ticker then return end
	Ticker:Cancel()
	Ticker = nil
end

local function startTicker()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(0.5, brTimerTick)
end

local function checkState()
  local inMythicPlus = C_ChallengeMode.GetActiveChallengeMapID() and C_ChallengeMode.GetActiveKeystoneInfo()
  if inEncounter or inMythicPlus then
    startTicker()
    BRText:Show()
  else
    cancelTicker()
    BRText:SetText('')
    BRText:Hide()
  end
end

local function onEncounterStart()
  inEncounter = true
  checkState()
end

local function onEncounterEnd()
  inEncounter = false
  checkState()
end

---@param isLogin boolean
---@param isReload boolean
local function playerEnteringWorld(_, isLogin, isReload)
  if isLogin or isReload then createText() end
	inEncounter = IsEncounterInProgress()
  checkState()
end

addonMods.RegisterEventHandler('ENCOUNTER_START', onEncounterStart)
addonMods.RegisterEventHandler('ENCOUNTER_END', onEncounterEnd)
addonMods.RegisterEventHandler('CHALLENGE_MODE_START', checkState)
addonMods.RegisterEventHandler('CHALLENGE_MODE_COMPLETED', checkState)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)