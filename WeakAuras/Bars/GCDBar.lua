---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture

-- Create visuals
local GCDBar, gcdStartTime, gcdDuration
local function updateBar()
	local time = 1 - (GetTime() - gcdStartTime) / gcdDuration

	if time <= 0 then
		GCDBar:RemoveCallback()
		GCDBar:Hide()
	else
		GCDBar:SetValue(time)
	end
end

local function createFrames()
	GCDBar = addonMods.NewBar({
		w                 = ECME_CDMBar_utility:GetWidth(),
		h                 = 5,
		anchorPoint       = 'TOP',
		relativeFrame     = ECME_CDMBar_utility,
		relativePoint     = 'BOTTOM',
		xOffset           = 0,
		yOffset           = -1,
		texture						= texture,
		color             = {1, 1, 1, 1},
		bgColor           = {0, 0, 0, 0.66},
		min               = 0,
		max               = 1,
		smoothProgress		= false,
		borders = {
			{
				inset       = 0,
				edgeFile    = texture,
				edgeSize    = 1,
				borderColor = {r = 0, g = 0, b = 0, a = 1},
				levelOffset = -1,
			},
		},
	})
	GCDBar:Hide()
	ECME_CDMBar_utility:HookScript('OnSizeChanged', function(_, width)
		if GCDBar and width and width > 0 then
			GCDBar:SetWidth(width)
		end
	end)
end

---@param unit string
local function unitSpellCastEvent(_, unit)
	if unit ~= 'player' or not GCDBar then return end

	local spellCooldownInfo = C_Spell.GetSpellCooldown(61304)
	if spellCooldownInfo and spellCooldownInfo.duration > 0 then
		gcdStartTime = spellCooldownInfo.startTime
		gcdDuration  = spellCooldownInfo.duration
		GCDBar:AddCallback(updateBar)
		GCDBar:Show()
	end
end

---@param unit string
local function spellCastStop(_, unit)
	if unit ~= 'player' or not GCDBar then return end
	GCDBar:RemoveCallback()
	GCDBar:Hide()
end

local function playerEnteringWorld()
	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
	local function tryCreate()
		if ECME_CDMBar_utility then
			C_Timer.After(1, createFrames)
		else
			C_Timer.After(0.5, tryCreate)
		end
	end
	tryCreate()
end

-- Event Registration
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_START', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_STOP', 'player', spellCastStop)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)