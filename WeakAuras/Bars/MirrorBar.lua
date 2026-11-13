---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture
local font    = addonMods.defaultFont

local TIMER_COLOR = {
	EXHAUSTION = {0.65, 0.55, 0.20, 1},
	BREATH     = {0.20, 0.55, 0.85, 1},
	DEATH      = {0.70, 0.10, 0.10, 1},
	FEIGNDEATH = {0.55, 0.35, 0.75, 1},
}

local TIMER_PRIORITY = {
	BREATH     = 1,
	EXHAUSTION = 2,
	FEIGNDEATH = 3,
	DEATH      = 4,
}

local MirrorTimerGroup = addonMods.GetOrCreateDynamicGroup('MirrorTimers', {
	point         = 'CENTER',
	relativeTo    = UIParent,
	relativePoint = 'CENTER',
	x             = 0,
	y             = 234,
	direction     = 'UP',
	spacing       = 4,
})

local MirrorBarMixin = {}

local function onBarTick(Bar)
	Bar:UpdateProgress()
end

---@return boolean
function MirrorBarMixin:HasTimer()
	return self.timer ~= nil
end

---@param value number|nil
function MirrorBarMixin:UpdateProgress(value)
	local current = (value or GetMirrorTimerProgress(self.timer)) / 1000
	self:SetValue(current)

	local _, maxValue = self:GetMinMaxValues()
	local remaining = math.min(current, maxValue)
	self:GetText('duration'):SetText(string.format('%d:%02d', remaining / 60, remaining % 60))
end

function MirrorBarMixin:SetPaused(paused)
	if paused and paused ~= 0 then
		self:RemoveCallback()
	else
		self:AddCallback(onBarTick)
	end
end

function MirrorBarMixin:Setup(timer, value, maxvalue, paused, label)
	self.timer = timer
	self:SetStatusBarColor(unpack(TIMER_COLOR[timer] or {1, 1, 1, 1}))
	self:SetMinMaxValues(0, maxvalue / 1000)
	self:GetText('name'):SetText(label)
	self:UpdateProgress(value)
	self:SetPaused(paused)

	if not self.addedToGroup then
		MirrorTimerGroup:AddMember(self, TIMER_PRIORITY[timer] or 99)
		self.addedToGroup = true
	end

	self:UpdateShownState()
end

function MirrorBarMixin:Clear()
	self:RemoveCallback()
	self.timer = nil
	self:UpdateShownState()
end

---@return boolean
function MirrorBarMixin:ShouldShow()
	return self.isInEditMode or self.timer ~= nil
end

function MirrorBarMixin:SetIsInEditModeInternal(isInEditMode)
	self.isInEditMode = isInEditMode
end

function MirrorBarMixin:UpdateShownState()
	self:SetShown(self:ShouldShow())
end

---@return table<string, any>
local function createMirrorBar()
	local Bar = addonMods.NewBar({
		w              = 200,
		h              = 18,
		anchorPoint    = 'CENTER',
		relativePoint  = 'CENTER',
		relativeFrame  = UIParent,
		xOffset        = 0,
		yOffset        = 0,
		texture        = texture,
		color          = {1, 1, 1, 1},
		bgColor        = {0, 0, 0, 0.66},
		min            = 0,
		max            = 1,
		smoothProgress = true,
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
				fontSize          = 14,
				fontFlags         = 'OUTLINE, SLUG',
				fontAnchorPoint   = 'LEFT',
				fontRelativePoint = 'LEFT',
				fontXOffset       = 4,
				fontYOffset       = 0,
				fontColor         = {r = 1, g = 1, b = 1, a = 1},
				parent            = 1,
			},
			duration = {
				font              = font,
				fontSize          = 14,
				fontFlags         = 'OUTLINE, SLUG',
				fontAnchorPoint   = 'RIGHT',
				fontRelativePoint = 'RIGHT',
				fontXOffset       = -4,
				fontYOffset       = 0,
				fontColor         = {r = 1, g = 1, b = 1, a = 1},
				parent            = 1,
			},
		},
	})

  if Bar.Spark then
    Bar.Spark:ClearAllPoints()
    Bar.Spark:SetPoint('CENTER', Bar:GetStatusBarTexture(), 'RIGHT', 0, 0)
  end

	Mixin(Bar, MirrorBarMixin)
	Bar:Hide()
	return Bar
end

local MirrorTimers = Mixin(CreateFrame('Frame'), MirrorTimerContainerMixin)
MirrorTimers.mirrorTimers = {}

---@param timer string
---@return table<string, any>
function MirrorTimers:GetAvailableTimer(timer)
	local available = MirrorTimerContainerMixin.GetAvailableTimer(self, timer)
	if available then return available end

	local Bar = createMirrorBar()
	table.insert(self.mirrorTimers, Bar)
	return Bar
end

MirrorTimers:SetScript('OnEvent', function(self, event, ...) self:OnEvent(event, ...) end)
MirrorTimers:OnLoad()

addonMods.KillFrame(MirrorTimerContainer)