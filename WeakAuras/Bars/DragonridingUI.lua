---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture
local font    = addonMods.defaultFont

local SURGE_FORWARD_ID  = 372608
local SKYWARD_ASCENT_ID = 372610
local SECOND_WIND_ID    = 425782
local WHIRLING_SURGE_ID = 361584
local THRILL_BUFF_ID    = 377234
local ASCENT_DURATION   = 3.5
local MAX_SAMPLES       = 5
local POLL_RATE         = 1/10

local speedValue, SPEED_COLOR = 20, {196/255, 97/255, 0/255, 1}
local accelValue, ACCEL_COLOR = 10, {191/255, 0/255, 0/255, 1}
local vigorCharges, vigorMax, vigorStart, vigorDuration = 0, 6, 0, 0

local ascentStart						 = 0
local lastSpeed, smoothSpeed = 0, 0
local smoothAccel					   = 0
local accelSamples					 = 0
local isDragonriding				 = false

local cdTimers = {}
local BarTicker

---@param remaining number
---@return string
local function formatDuration(remaining)
	if remaining >= 3600 then
		return format('%dh', remaining / 3600)
	elseif remaining >= 60 then
		return format('%d:%02d', remaining / 60, remaining % 60)
	elseif remaining > 0 then
		return format('%d', remaining)
	else
		return ''
	end
end

-- Create visuals
local SWIcon, WSIcon, AccelBar, SpeedBar, VigorBar, VigorChargeTex
local function createFrames()
	SpeedBar = addonMods.NewBar({
		w                 = 195,
		h                 = 17,
		anchorPoint       = 'CENTER',
		relativeFrame     = UIParent,
		relativePoint     = 'CENTER',
		xOffset           = 0.5,
		yOffset           = -150,
		texture						= texture,
		color             = {0/255, 136/255, 11/255, 1},
		bgColor           = {0, 0, 0, 0.66},
		min               = 20,
		max               = 100,
		smoothProgress		= true,
		borders = {
			{
				inset       = 0,
				edgeFile    = texture,
				edgeSize    = 1,
				borderColor = {r = 0, g = 0, b = 0, a = 1},
				levelOffset = -1,
			},
		},
		ticks = {
			{
				positions = {50},
				w         = 1,
				color     = {r = 0, g = 0, b = 0, a = 1},
			},
		},
	})
	AccelBar = addonMods.NewBar({
		w                 = 195,
		h                 = 9,
		anchorPoint       = 'TOP',
		relativeFrame     = SpeedBar,
		relativePoint     = 'BOTTOM',
		xOffset           = 0,
		yOffset           = -1,
		texture						= texture,
		color             = {191/255, 0/255, 0/255, 1},
		bgColor           = {0, 0, 0, 0.66},
		min               = 7,
		max               = 13,
		smoothProgress		= true,
		borders = {
			{
				inset       = 0,
				edgeFile    = texture,
				edgeSize    = 1,
				borderColor = {r = 0, g = 0, b = 0, a = 1},
				levelOffset = -1,
			},
		},
		ticks = {
			{
				positions = {10},
				w         = 1,
				color     = {r = 0, g = 0, b = 0, a = 1},
			},
		},
	})
	VigorBar = addonMods.NewBar({
		w                 = 195,
		h                 = 17,
		anchorPoint       = 'BOTTOM',
		relativeFrame     = SpeedBar,
		relativePoint     = 'TOP',
		xOffset           = 0,
		yOffset           = 1,
		texture						= texture,
		color             = {168/255, 77/255, 195/255, 1},
		bgColor           = {0, 0, 0, 0.66},
		min               = 0,
		max               = 6,
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
		ticks = {
			{
				positions = {1, 2, 2.97, 4, 4.96},
				w         = 1,
				color     = {r = 0, g = 0, b = 0, a = 1},
			},
		},
	})
	VigorChargeTex = VigorBar:CreateTexture(nil, 'ARTWORK', nil, 1)
	VigorChargeTex:SetColorTexture(46/255, 145/255, 197/255, 1)
	VigorChargeTex:Hide()

	SWIcon = addonMods.NewIcon({
		w               = 45,
		h               = 45,
		zoom            = 0.3,
		keepAspectRatio = true,
		scaleX          = 1,
		scaleY          = 1,
		texXOffset 			= 0,
		texYOffset 			= 0,
		anchorPoint     = 'RIGHT',
		relativeFrame   = SpeedBar,
		relativePoint   = 'LEFT',
		xOffset         = -1,
		yOffset         = 4,
		texture 				= 4640489,
		desaturated			= false,
		showSwipe 			= true,
		borders = {
			{
				inset       = 0,
				edgeFile    = texture,
				edgeSize    = 1,
				borderColor = {r = 0, g = 0, b = 0, a = 1},
				levelOffset = 2,
			},
		},
		texts = {
			duration = {
				font              = font,
				fontSize          = 16,
				fontFlags         = 'OUTLINE, SLUG',
				fontAnchorPoint   = 'CENTER',
				fontRelativePoint = 'CENTER',
				fontXOffset       = 0,
				fontYOffset       = 0,
				fontColor         = {r = 1, g = 1, b = 1, a = 1},
				parent						= 1
			},
			stacks = {
				font              = font,
				fontSize          = 14,
				fontFlags         = 'OUTLINE, SLUG',
				fontAnchorPoint   = 'BOTTOMRIGHT',
				fontRelativePoint = 'BOTTOMRIGHT',
				fontXOffset       = 2,
				fontYOffset       = 0,
				fontColor         = {r = 1, g = 1, b = 1, a = 1},
				parent						= 1
			},
		}
	})
	WSIcon = addonMods.NewIcon({
		w               = 45,
		h               = 45,
		zoom            = 0.3,
		keepAspectRatio = true,
		scaleX          = 1,
		scaleY          = 1,
		texXOffset 			= 0,
		texYOffset 			= 0,
		anchorPoint     = 'LEFT',
		relativeFrame   = SpeedBar,
		relativePoint   = 'RIGHT',
		xOffset         = 1,
		yOffset         = 4,
		texture 				= 4640477,
		desaturated			= false,
		showSwipe 			= true,
		borders = {
			{
				inset       = 0,
				edgeFile    = texture,
				edgeSize    = 1,
				borderColor = {r = 0, g = 0, b = 0, a = 1},
				levelOffset = 2,
			},
		},
		texts = {
			duration = {
				font              = font,
				fontSize          = 16,
				fontFlags         = 'OUTLINE, SLUG',
				fontAnchorPoint   = 'CENTER',
				fontRelativePoint = 'CENTER',
				fontXOffset       = 0,
				fontYOffset       = 0,
				fontColor         = {r = 1, g = 1, b = 1, a = 1},
				parent						= 1
			},
		}
	})
end

local function showUI()
	SWIcon:Show()
	WSIcon:Show()
	AccelBar:Show()
	SpeedBar:Show()
	VigorBar:Show()
end

local function hideUI()
	SWIcon:Hide()
	WSIcon:Hide()
	AccelBar:Hide()
	SpeedBar:Hide()
	VigorBar:Hide()
end

-- Update UI elements
---@param key string
---@param start number
---@param duration number
---@param callback fun(...)
local function scheduleIconRefresh(key, start, duration, callback)
	if cdTimers[key] then
		cdTimers[key]:Cancel()
		cdTimers[key] = nil
	end

	if duration and duration > 0 and start then
		local remaining = (start + duration) - GetTime()

		if remaining <= 0 then
			-- Cooldown already elapsed by the time we checked; refresh now
			callback()
			return
		end

		cdTimers[key] = C_Timer.NewTimer(remaining + 0.05, function()
			cdTimers[key] = nil
			callback()
		end)
	end
end

---@param self table<string, any>
local function iconOnUpdate(self)
	local start, duration = self.cdStart, self.cdDuration
	if not start or duration == 0 then
		self.texts.duration:SetText('')
		return
	end

	local remaining = (start + duration) - GetTime()
	if remaining <= 0 then
		self.texts.duration:SetText('')
		self.Cooldown:Hide()
		self:RemoveCallback()
	else
		self.texts.duration:SetText(formatDuration(remaining))
	end
end

---@param Icon table<string, any>
---@param start number?
---@param duration number
local function iconSetCooldown(Icon, start, duration)
	Icon.cdStart    = start
	Icon.cdDuration = duration

	if duration and duration > 0 then
		Icon.Cooldown:SetCooldown(start, duration)
		Icon.Cooldown:Show()
		Icon:AddCallback(iconOnUpdate)
	else
		Icon.Cooldown:Hide()
		Icon.texts.duration:SetText('')
		Icon:RemoveCallback()
	end
end

local function wsIconUpdate()
	if not WSIcon then return end
	local info = C_Spell.GetSpellCooldown(WHIRLING_SURGE_ID)
	if not info then return end

	iconSetCooldown(WSIcon, info.startTime, info.duration)
	WSIcon.Icon:SetDesaturated(info.duration and info.duration > 0)

	scheduleIconRefresh('WSIcon', info.startTime, info.duration, wsIconUpdate)
end

local function swIconUpdate()
	if not SWIcon then return end
	local info = C_Spell.GetSpellCharges(SECOND_WIND_ID)
	if not info then return end

	local currentCharges = info.currentCharges
	local maxCharges     = info.maxCharges
	local start          = info.cooldownStartTime
	local duration       = info.cooldownDuration

	SWIcon.texts.stacks:SetText(currentCharges > 0 and currentCharges or '')

	if currentCharges < maxCharges and duration > 0 then
		iconSetCooldown(SWIcon, start, duration)
	else
		iconSetCooldown(SWIcon, nil, 0)
	end
	SWIcon.Icon:SetDesaturated(currentCharges == 0)

	scheduleIconRefresh('SWIcon', start, (currentCharges < maxCharges) and duration or nil, swIconUpdate)
end

local function resetAndSyncIcons()
	for key, Timer in pairs(cdTimers) do
		Timer:Cancel()
		cdTimers[key] = nil
	end

	if SWIcon then swIconUpdate() end
	if WSIcon then wsIconUpdate() end
end

local function updateBars()
	SpeedBar:SetSmoothedValue(speedValue)
	SpeedBar:SetStatusBarColor(unpack(SPEED_COLOR))

	AccelBar:SetSmoothedValue(accelValue)
	AccelBar:SetStatusBarColor(unpack(ACCEL_COLOR))

	VigorBar:SetValue(vigorCharges)

	if vigorDuration and vigorDuration > 0 and vigorCharges < vigorMax then
		local progress = (GetTime() - vigorStart) / vigorDuration
		progress = math.max(0, math.min(1, progress))

		local min, max  = VigorBar:GetMinMaxValues()
		local range     = max - min
		local segWidth  = VigorBar:GetWidth() / range
		local xOffset   = (vigorCharges - min) * segWidth

		VigorChargeTex:ClearAllPoints()
		VigorChargeTex:SetPoint('TOPLEFT', VigorBar, 'TOPLEFT', xOffset, 0)
		VigorChargeTex:SetPoint('BOTTOMLEFT', VigorBar, 'BOTTOMLEFT', xOffset, 0)
		VigorChargeTex:SetWidth(math.max(0.01, segWidth * progress))
		VigorChargeTex:Show()
	else
		VigorChargeTex:Hide()
	end
end

local function speedBarUpdate()
	local _,_, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
	local speed = forwardSpeed or 0

	smoothSpeed = speed
	speedValue  = smoothSpeed

	local thrill   = C_UnitAuras.GetPlayerAuraBySpellID(THRILL_BUFF_ID)
	local boosting = thrill and GetTime() < ascentStart + ASCENT_DURATION

	if boosting then
		SPEED_COLOR = {0/255, 144/255, 155/255, 1}
	elseif thrill then
		SPEED_COLOR = {0/255, 136/255, 11/255, 1}
	else
		SPEED_COLOR = {196/255, 97/255, 0/255, 1}
	end
end

local function accelBarUpdate()
	local isGliding = C_PlayerInfo.GetGlidingInfo()

	accelSamples 		 = math.min(MAX_SAMPLES, accelSamples + 1)
	local lastWeight = (accelSamples - 1) / accelSamples
	local newWeight	 = 1 / accelSamples

	local newAccel = smoothSpeed - lastSpeed
	lastSpeed 		 = smoothSpeed

	smoothAccel = smoothAccel * lastWeight + newAccel * newWeight

	if smoothSpeed > 63 then smoothAccel = max(0, smoothAccel) end
	if not isGliding then smoothAccel = 0 end

	local val  = smoothAccel + 10
	accelValue = val

	if val >= 9.75 then
		ACCEL_COLOR = {0/255, 136/255, 4/255, 1}
	elseif val >= 9.5 then
		ACCEL_COLOR = {196/255, 96/255, 0/255, 1}
	else
		ACCEL_COLOR = {191/255, 0/255, 0/255, 1}
	end
end

local function vigorBarUpdate()
	local info = C_Spell.GetSpellCharges(SURGE_FORWARD_ID)
	if not info then return end

	vigorCharges  = info.currentCharges
	vigorMax      = info.maxCharges
	vigorStart    = info.cooldownStartTime
	vigorDuration = info.cooldownDuration
end

---@param unit string
---@param spellId number
local function unitSpellCastEvent(_, unit, _, spellId)
	if unit ~= 'player' then return end

	if spellId == SECOND_WIND_ID then
		RunNextFrame(swIconUpdate)
	elseif spellId == WHIRLING_SURGE_ID then
		RunNextFrame(wsIconUpdate)
	elseif spellId == SURGE_FORWARD_ID or spellId == SKYWARD_ASCENT_ID then
		if spellId == SKYWARD_ASCENT_ID then ascentStart = GetTime() end
		RunNextFrame(vigorBarUpdate)
	end
end

local function glideUpdate()
	RunNextFrame(speedBarUpdate)
	RunNextFrame(accelBarUpdate)
end

local function updateUI()
	if isDragonriding then
		showUI()
		addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', unitSpellCastEvent)
		addonMods.RegisterEventHandler('PLAYER_IS_GLIDING_CHANGED', glideUpdate)

		if not BarTicker then
			-- This is run on a separate ticker instead of using the bars' OnUpdate
			-- to give a proper dt for accel calculations
			BarTicker = C_Timer.NewTicker(POLL_RATE, function()
				speedBarUpdate()
				accelBarUpdate()
				vigorBarUpdate()
			end)
		end
		SpeedBar:AddCallback(updateBars)
		resetAndSyncIcons()
		vigorBarUpdate()
	else
		hideUI()
		addonMods.UnregisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'player', unitSpellCastEvent)
		addonMods.UnregisterEventHandler('PLAYER_IS_GLIDING_CHANGED', glideUpdate)

		if BarTicker then
			BarTicker:Cancel()
			BarTicker = nil
		end
		for key, Timer in pairs(cdTimers) do
			Timer:Cancel()
			cdTimers[key] = nil
		end
		SpeedBar:RemoveCallback()
		SWIcon:RemoveCallback()
		WSIcon:RemoveCallback()
	end
end

local function checkIsDragonriding()
	RunNextFrame(function()
		local _, canGlide = C_PlayerInfo.GetGlidingInfo()
		isDragonriding = canGlide
		updateUI()
	end)
end

---@param isLogin boolean
---@param isReload boolean
local function playerEnteringWorld(_, isLogin, isReload)
	if isLogin or isReload then createFrames() end
	checkIsDragonriding()
end

local function dragonridingUpdate(_, canGlide)
	isDragonriding = canGlide
	updateUI()
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
addonMods.RegisterEventHandler('PLAYER_CAN_GLIDE_CHANGED', dragonridingUpdate)
addonMods.RegisterEventHandler('PLAYER_MOUNT_DISPLAY_CHANGED', checkIsDragonriding)