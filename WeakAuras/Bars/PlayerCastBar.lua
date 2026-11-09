---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture
local font    = addonMods.defaultFont

local CHANNEL_TICK_DATA = {
	-- Evoker
	[356995]  = {ticks = 4, modSpell = 1219723, modTicks = 5},   -- Disintegrate / Azure Celerity
	-- Priest
	[15407]   = {ticks = 6},                                     -- Mind Flay
	[48045]   = {ticks = 6},                                     -- Mind Sear
	[64843]   = {ticks = 4},                                     -- Divine Hymn
	[47757]   = {ticks = 3},                                     -- Penance (Heal)
	[47758]   = {ticks = 3},                                     -- Penance (DPS)
	[373129]  = {ticks = 3},                                     -- Penance / Dark Reprimand (DPS)
	[400171]  = {ticks = 3},                                     -- Penance / Dark Reprimand (Heal)
	[263165]  = {ticks = 3},                                     -- Void Torrent
	-- Mage
	[5143]    = {ticks = 5},                                     -- Arcane Missiles
	[12051]   = {ticks = 6},                                     -- Evocation
	[205021]  = {ticks = 5},                                     -- Ray of Frost
	-- Druid
	[740]     = {ticks = 4},                                     -- Tranquility
	-- Demon Hunter
	[198013]  = {tickInterval = 0.2},                            -- Eye Beam
	[473728]  = {tickInterval = 0.2},                            -- Void Ray (Devourer)
	[212084]  = {ticks = 10},                                    -- Fel Devastation
	-- Warlock
	[198590]  = {ticks = 5},                                     -- Drain Soul
	[755]     = {ticks = 5},                                     -- Health Funnel
	[234153]  = {ticks = 5},                                     -- Drain Life
	-- Death Knight
	[206931]  = {ticks = 3},                                     -- Blooddrinker
	-- Monk
	[113656]  = {ticks = 4},                                     -- Fists of Fury
	[115175]  = {ticks = 12},                                    -- Soothing Mist
	[443028]  = {ticks = 4},                                     -- Celestial Conduit
	-- Racial
	[291944]  = {ticks = 6},                                     -- Regeneratin (Zandalari)
}

-- Create visuals
local IS_CASTER = {
	['DRUID']   = true,
	['PRIEST']  = true,
	['WARLOCK'] = true,
}
local DEVOURER_SPEC_ID = 1480

---@return boolean
local function isCasterLayout()
	if IS_CASTER[addonMods.myClass] then return true end

	if addonMods.myClass == 'DEMONHUNTER' then
		local specIndex = C_SpecializationInfo.GetSpecialization()
		local specId    = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		return specId == DEVOURER_SPEC_ID
	end

	return false
end

local CastBar, currentIsCaster
local function createFrames()
	local isCaster = isCasterLayout()

	if CastBar then
		CastBar:Release()
		CastBar = nil
	end
	currentIsCaster = isCaster

	local anchorPoint, relativePoint, xOffset, yOffset, height, iconConfig, iconBorderConfig, nameXOffset, durationXOffset, fontYOffset
	if isCaster then
		xOffset           = 0
		yOffset           = 57
		anchorPoint       = 'BOTTOM'
		relativePoint     = 'TOP'
		height            = 10
		nameXOffset       = -1
		durationXOffset   = 2
		fontYOffset       = 13
	else
		xOffset       = 0
		yOffset       = -7
		anchorPoint   = 'TOP'
		relativePoint = 'BOTTOM'
		height        = 21
		iconConfig = {
			w               = height,
			h               = height,
			desaturated     = false,
			texture         = 134400,
			anchorPoint     = 'RIGHT',
			relativePoint   = 'LEFT',
			xOffset         = 0,
			yOffset         = 0,
			zoom            = 0.3,
			keepAspectRatio = true,
			scaleX          = 1,
			scaleY          = 1,
			texXOffset      = 0,
			texYOffset      = 0,
		}
		iconBorderConfig = {
			parent      = 'icon',
			inset       = 0,
			edgeFile    = texture,
			edgeSize    = 1,
			borderColor = {r = 0, g = 0, b = 0, a = 1},
			levelOffset = -1,
		}
		nameXOffset 		= 1
		durationXOffset = 1
		fontYOffset 		= 0
	end

	CastBar = addonMods.NewBar({
		w              = 286.99993896484, -- ECME_CDMBar_cooldowns:GetWidth(),
		h              = height,
		anchorPoint    = anchorPoint,
		relativePoint  = relativePoint,
		relativeFrame  = ECME_CDMBar_utility,
		xOffset        = xOffset,
		yOffset        = yOffset,
		texture        = texture,
		color          = {1, 1, 1, 1},
		bgColor        = {0, 0, 0, 0.66},
		min            = 0,
		max            = 1,
		smoothProgress = false,
		icon           = iconConfig,
    spark = {
      w         = 2,
      texture   = texture,
      blendMode = 'ADD',
      color     = {r = 146/255, g = 65/255, b = 65/255, a = 1},
    },
		borders = {
			{
				inset       = 0,
				edgeFile    = texture,
				edgeSize    = 1,
				borderColor = {r = 0, g = 0, b = 0, a = 1},
				levelOffset = -1,
			},
			iconBorderConfig,
		},
		texts = {
			name = {
				font              = font,
				fontSize          = 16,
				fontFlags         = 'OUTLINE, SLUG',
				fontAnchorPoint   = 'LEFT',
				fontRelativePoint = 'LEFT',
				fontXOffset       = nameXOffset,
				fontYOffset       = fontYOffset,
				fontColor         = {r = 1, g = 1, b = 1, a = 1},
				parent						= 1
			},
			duration = {
				font              = font,
				fontSize          = 16,
				fontFlags         = 'OUTLINE, SLUG',
				fontAnchorPoint   = 'RIGHT',
				fontRelativePoint = 'RIGHT',
				fontXOffset       = durationXOffset,
				fontYOffset       = fontYOffset,
				fontColor         = {r = 1, g = 1, b = 1, a = 1},
				parent						= 1
			},
		},
	})
	CastBar:Hide()

	if CastBar.Spark then
		CastBar.Spark:ClearAllPoints()
		CastBar.Spark:SetPoint('CENTER', CastBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
	end
end

---@param duration number?
---@param tickData table<string, number>
local function addTicks(duration, tickData)
	local barWidth  = CastBar:GetWidth()
	local barHeight = CastBar:GetHeight()
	if barWidth <= 0 or barHeight <= 0 then return end

	-- Pixel-snap helpers (same approach as empower pips)
	local effectiveScale = CastBar:GetEffectiveScale()

	local numTicks
	if tickData.tickInterval then
		if duration > 0 then
			numTicks = floor(duration / tickData.tickInterval)
		else
			numTicks = 0
		end
	else
		numTicks = tickData.ticks
		if tickData.modSpell and IsPlayerSpell(tickData.modSpell) then numTicks = tickData.modTicks end
	end

	for i = 1, numTicks - 1 do
		local Tick    = CastBar.ticks and CastBar.ticks[i]
		local xOffset = floor(barWidth * (numTicks - i) / numTicks * effectiveScale + 0.5) / effectiveScale
		if not Tick then
			CastBar:AddTicks({
				positions = {xOffset},
				w         = 2,
				color     = {r = 176/255, g = 84/255, b = 84/255, a = 1},
			})
			Tick = CastBar.ticks[i]
		else
			Tick:ClearAllPoints()
			Tick:SetPoint('TOPLEFT', CastBar, 'TOPLEFT', xOffset, 0)
			Tick:SetPoint('BOTTOMLEFT', CastBar, 'BOTTOMLEFT', xOffset, 0)
		end

		Tick:Show()
	end
end

local function hideTicks()
	local ticks = CastBar.ticks
	if ticks then
		for _, Tick in pairs(ticks) do Tick:Hide() end
	end
end

---@param self table<string, any>
---@param startTime number
---@param endTime number
---@param inverse boolean?
local function onUpdate(self, startTime, endTime, inverse)
	local progress  = GetTime() - startTime
	local duration  = endTime - startTime

	local time, isComplete
	if inverse then
		time       = 1 - progress / duration
		isComplete = time <= 0
	else
		time = progress / duration
		isComplete = time >= 1
	end

	if isComplete then
		self:Hide()
	else
		self:SetValue(time)
		self.texts.duration:SetText(string.format('%.1f', progress) .. '/' .. string.format('%.1f', duration))
	end
end

---@param unit string
local function unitSpellCastEvent(_, unit)
  if not unit then unit = 'player' end

	-- Delay to next frame for casting info to update
	RunNextFrame(function()
		if not CastBar then return end
		local name, iconId, startTimeMS, endTimeMS, startTime, endTime, spellId

		-- Casting
		name, _, iconId, startTimeMS, endTimeMS = UnitCastingInfo(unit)
		if name then
			startTime = startTimeMS / 1000
			endTime   = endTimeMS / 1000

			-- Ticks can still be visible if immediately transitioning from channel->cast
			local ticks = CastBar.ticks
			if ticks then for _, Tick in pairs(ticks) do Tick:Hide() end end

			CastBar.texts.name:SetText(name)
			if CastBar.Icon then CastBar.Icon:SetTexture(iconId) end
			CastBar:AddCallback(function(self) onUpdate(self, startTime, endTime) end)
			CastBar:Show()
			return
		end

		-- Channeling
		name, _, iconId, startTimeMS, endTimeMS, _,_, spellId = UnitChannelInfo(unit)
		if name then
			local tickData = CHANNEL_TICK_DATA[spellId]
			startTime 		 = startTimeMS / 1000
			endTime   		 = endTimeMS / 1000

			if tickData then
				addTicks(endTime - startTime, tickData)
			else
				hideTicks()
			end
			CastBar.texts.name:SetText(name)
			if CastBar.Icon then CastBar.Icon:SetTexture(iconId) end
			CastBar:AddCallback(function(self) onUpdate(self, startTime, endTime, true) end)
			CastBar:Show()
			return
		end

		hideTicks()
		CastBar:Hide()
		CastBar:RemoveCallback()
	end)
end

---@param unit string
local function specChanged(_, unit)
	if unit and unit ~= 'player' then return end
	if not CastBar then return end
	if isCasterLayout() == currentIsCaster then return end

	createFrames()
	unitSpellCastEvent(nil, 'player')
end

local function playerEnteringWorld()
	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
	local function tryCreate()
		if ECME_CDMBar_cooldowns then
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
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_DELAYED', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_STOP', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_FAILED', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_INTERRUPTED', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_CHANNEL_START', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_CHANNEL_STOP', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_CHANNEL_UPDATE', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_EMPOWER_START', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_EMPOWER_STOP', 'player', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_EMPOWER_UPDATE', 'player', unitSpellCastEvent)
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', specChanged)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)