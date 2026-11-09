---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.LSM:Fetch('font', 'Roboto Condensed Bold')
local fontFlags = 'OUTLINE, SLUG'

local Ticker, activated, endTime
local startTime        = 0
local currentEncounter = false

-- Create visuals
local TimerText
local function createText()
	TimerText = addonMods.PetFrame:CreateFontString(nil, 'OVERLAY')
	---@cast fontFlags string
	TimerText:SetFont(font, 16, fontFlags)
	TimerText:SetPoint('CENTER', addonMods.PetFrame, 'TOPRIGHT', -17, 0)
end

local function setColor()
	if activated then
		TimerText:SetTextColor(1, 1, 1, 1)
	else
		TimerText:SetTextColor(157/255, 157/255, 157/255, 0.32)
	end
end

local function updateText()
	if activated == nil then
		TimerText:SetText('[00:00]')
		return
	end

	startTime 		= startTime or GetTime()
	local elapsed = (activated and GetTime() or endTime) - startTime
	local total   = elapsed + 0.5
	local text    = format('[%02.f:%02.f]', floor(total / 60), floor(total % 60))
	TimerText:SetText(text)
end

local function cancelTicker()
	if not Ticker then return end
	Ticker:Cancel()
	Ticker = nil
end

local function startTicker()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(0.5, updateText)
end

local function startTimer(a)
	startTime = GetTime()
	activated = true
	startTicker()
	setColor()
end

local function stopTimer()
	endTime   = GetTime()
	startTime = 0
	activated = false
	cancelTicker()
	setColor()
end

local function enterCombat()
	if not currentEncounter then startTimer() end
end

local function exitCombat()
	if not currentEncounter then stopTimer() end
end

local function encounterStart()
	if not InCombatLockdown() then startTimer() end
	currentEncounter = true
end

local function encounterEnd()
	if not InCombatLockdown() then stopTimer() end
	currentEncounter = false
end

---@param isLogin boolean
---@param isReload boolean
local function playerEnteringWorld(_, isLogin, isReload)
	-- Delay creation of text until PEW to anchor correctly
	if isLogin or isReload then createText() end
	currentEncounter = UnitExists('boss1') -- Check if in encounter

	if InCombatLockdown() then
		activated = true
		startTicker()
	else
		TimerText:SetText('[00:00]')
		setColor()
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', enterCombat)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', exitCombat)
addonMods.RegisterEventHandler('ENCOUNTER_START', encounterStart)
addonMods.RegisterEventHandler('ENCOUNTER_END', encounterEnd)