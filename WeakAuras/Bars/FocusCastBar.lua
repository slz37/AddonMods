---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture
local font    = addonMods.defaultFont

local DEFAULT_SPARK_COLOR = {r = 146/255, g = 65/255,  b = 65/255}
local INTERRUPT_CD_COLOR  = {r = 255/255, g = 0/255,   b = 136/255}
local INTERRUPT_COLOR     = {r = 62/255,  g = 255/255, b = 0/255}

local INTERRUPT_SPELLS = {
  ['DEATHKNIGHT'] = 47528,
  ['DRUID']       = 78675,
  ['PRIEST']      = 15487,
  ['DEMONHUNTER'] = 183752,
  ['WARLOCK']		  = 19647,
}

local CastBar
local DurationBinding
local DurationFormatter

local function createFrames()
	CastBar = addonMods.NewBar({
		w              = 272,
		h              = 19,
		anchorPoint    = 'CENTER',
		relativePoint  = 'CENTER',
		relativeFrame  = UIParent,
		xOffset        = 0,
		yOffset        = 180,
		texture        = texture,
		color          = {1, 1, 1, 1},
		bgColor        = {0, 0, 0, 0.66},
		min            = 0,
		max            = 1,
		smoothProgress = false,
		icon = {
			w               = 19,
			h               = 19,
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
		},
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
			{
        parent      = 'icon',
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
				parent						= 1
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
				parent						= 1
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
				parent						= 1
			},
		},
	})

	CastBar.texts.duration:ClearAllPoints()
	CastBar.texts.duration:SetPoint('RIGHT', CastBar.texts.totalDuration, 'LEFT', 3, 0)

	-- Use alpha to avoid secret taint with GetWidth()
	CastBar:Show()
	CastBar:SetAlpha(0)

	if CastBar.Spark then
		CastBar.Spark:ClearAllPoints()
		CastBar.Spark:SetPoint('CENTER', CastBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
	end

	DurationFormatter = C_StringUtil.CreateNumericRuleFormatter()
	DurationFormatter:SetBreakpoints({
		{threshold = 0,     format = '%.1f'},
		{threshold = 10.01, format = '%d'},
		{threshold = 60,    format = '%d:%02d', components = {{div = 60}, {mod = 60}}},
		{threshold = 600,   format = '%dm',     components = {{div = 60}}},
		{threshold = 3600,  format = '%dh',     components = {{div = 3600}}},
		{threshold = 86400, format = '%dd',     components = {{div = 86400}}},
	})

	-- Use DurationBinding for channels
	DurationBinding = C_DurationUtil.CreateDurationTextBinding()
	DurationBinding:SetFontString(CastBar.texts.duration)
	DurationBinding:SetFormatter(DurationFormatter)
	DurationBinding:SetExpiredText('')
	DurationBinding:SetZeroDurationText('')
	DurationBinding:SetEnabled(false)
end

---@return boolean
local function interruptSpellReady()
  if not UnitExists('focus') then return false end

  local spellId = INTERRUPT_SPELLS[addonMods.myClass]
  if not spellId then return false end

  local usable     = C_Spell.IsSpellUsable(spellId)
  local spellKnown = C_SpellBook.IsSpellInSpellBook(spellId)
  local spellInfo  = C_Spell.GetSpellCooldown(spellId)
  ---@diagnostic disable-next-line: undefined-field
  local isActive   = spellInfo and spellInfo.isActive

  return usable and spellKnown and not isActive
end

---@param canAttack boolean
---@param spellReady boolean
---@param notInterruptible boolean
local function applyCastBarColor(canAttack, spellReady, notInterruptible)
  if not canAttack then
    CastBar.texts.name:SetTextColor(1, 1, 1)
    CastBar.Spark:SetVertexColor(DEFAULT_SPARK_COLOR.r, DEFAULT_SPARK_COLOR.g, DEFAULT_SPARK_COLOR.b)
  elseif not spellReady then
    CastBar.texts.name:SetTextColor(INTERRUPT_CD_COLOR.r, INTERRUPT_CD_COLOR.g, INTERRUPT_CD_COLOR.b)
    CastBar.Spark:SetVertexColor(INTERRUPT_CD_COLOR.r, INTERRUPT_CD_COLOR.g, INTERRUPT_CD_COLOR.b)
  else
    CastBar.texts.name:SetVertexColorFromBoolean(
      notInterruptible,
      CreateColor(1, 1, 1, 1),
      CreateColor(INTERRUPT_COLOR.r, INTERRUPT_COLOR.g, INTERRUPT_COLOR.b, 1)
    )
    CastBar.Spark:SetVertexColorFromBoolean(
      notInterruptible,
      CreateColor(DEFAULT_SPARK_COLOR.r, DEFAULT_SPARK_COLOR.g, DEFAULT_SPARK_COLOR.b, 1),
      CreateColor(INTERRUPT_COLOR.r, INTERRUPT_COLOR.g, INTERRUPT_COLOR.b, 1)
    )
  end
end

---@param duration DurationObject
local function onUpdate(_, duration)
	-- Use onUpdate for casts since DurationBinding only counts down
	---@diagnostic disable-next-line: undefined-field
	local elapsed = duration:FormatElapsedDuration(DurationFormatter)

	CastBar.texts.duration:SetText(elapsed)
end

---@param unit string
local function unitSpellCastEvent(_, unit)
  if not unit then unit = 'focus' end

	-- Delay to next frame for casting info to update
	RunNextFrame(function()
		if not CastBar then return end

		-- This needs to be reset immediately every time to avoid
		-- collision between onUpdate and DurationBinding when changing focus
		CastBar:RemoveCallback()
		DurationBinding:SetEnabled(false)
		CastBar:SetAlpha(0)

		local name, iconId, notInterruptible

		-- Casting
		name, _, iconId, _,_,_,_, notInterruptible = UnitCastingInfo(unit)
		if name then
      local canAttack  = UnitCanAttack('player', unit)
      local spellReady = canAttack and interruptSpellReady()

      applyCastBarColor(canAttack, spellReady, notInterruptible)
			CastBar.texts.name:SetText(name)
			if CastBar.Icon then CastBar.Icon:SetTexture(iconId) end

			CastBar:SetAlpha(1)

			local duration = UnitCastingDuration(unit)
  		---@diagnostic disable-next-line: undefined-field
			local totalDuration = duration:FormatTotalDuration(DurationFormatter)
			CastBar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)
			CastBar.texts.totalDuration:SetText('/' .. totalDuration)
			CastBar:AddCallback(onUpdate, duration)
			return
		end

		-- Channeling
		name, _, iconId, _,_,_, notInterruptible = UnitChannelInfo(unit)
		if name then
      local canAttack  = UnitCanAttack('player', unit)
      local spellReady = canAttack and interruptSpellReady()

      applyCastBarColor(canAttack, spellReady, notInterruptible)
			CastBar.texts.name:SetText(name)
			if CastBar.Icon then CastBar.Icon:SetTexture(iconId) end

			CastBar:SetAlpha(1)

			local duration = UnitChannelDuration(unit)
  		---@diagnostic disable-next-line: undefined-field
			local totalDuration = duration:FormatTotalDuration(DurationFormatter)
			CastBar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
			CastBar.texts.totalDuration:SetText('/' .. totalDuration)
			DurationBinding:SetDuration(duration)
			DurationBinding:SetEnabled(true)
			return
		end
	end)
end

local function playerEnteringWorld()
	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
	createFrames()
end

-- Event Registration
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_START', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_SUCCEEDED', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_DELAYED', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_STOP', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_FAILED', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_INTERRUPTED', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_CHANNEL_START', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_CHANNEL_UPDATE', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_CHANNEL_STOP', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_EMPOWER_START', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_EMPOWER_UPDATE', 'focus', unitSpellCastEvent)
addonMods.RegisterUnitEventHandler('UNIT_SPELLCAST_EMPOWER_STOP', 'focus', unitSpellCastEvent)
addonMods.RegisterEventHandler('PLAYER_FOCUS_CHANGED', unitSpellCastEvent)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)