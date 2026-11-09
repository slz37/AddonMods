---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture
local font    = addonMods.defaultFont

local fontFlags = 'OUTLINE, SLUG'
---@cast fontFlags string

local WRAP_AFTER = 14
local ICON_SIZE  = 31
local SPACING    = 1
local ROW_WIDTH  = WRAP_AFTER * (ICON_SIZE + SPACING) + SPACING

local buffAnchorPoint, buffRelativePoint, buffxOffset, buffyOffset
local debuffAnchorPoint, debuffRelativePoint, debuffxOffset, debuffyOffset
if BasicMinimap then
	buffAnchorPoint, buffRelativePoint, buffxOffset, buffyOffset 				 = 'TOPRIGHT', 'TOPLEFT', -2, 1
	debuffAnchorPoint, debuffRelativePoint, debuffxOffset, debuffyOffset = 'BOTTOMRIGHT', 'BOTTOMLEFT', -2, -1
elseif EllesmereUI then
	buffAnchorPoint, buffRelativePoint, buffxOffset, buffyOffset 				 = 'TOPRIGHT', 'TOPLEFT', -1, 0
	debuffAnchorPoint, debuffRelativePoint, debuffxOffset, debuffyOffset = 'BOTTOMRIGHT', 'BOTTOMLEFT', -1, 0
else
	return
end

local DurationFormatter = C_StringUtil.CreateNumericRuleFormatter()
DurationFormatter:SetBreakpoints({
	{threshold = 0,     format = '%.1f'},
	{threshold = 5.01,  format = '%d'},
	{threshold = 60,    format = '%dm', components = {{div = 60}}},
	{threshold = 3600,  format = '%dh', components = {{div = 3600}}},
	{threshold = 86400, format = '%dd', components = {{div = 86400}}},
})

---@param auraButton AuraButton
---@param isBuff boolean?
local function initializeAuraFrame(auraButton, isBuff)
	PixelUtil.SetSize(auraButton, ICON_SIZE, ICON_SIZE)

	-- Icon
	local Icon = auraButton:CreateTexture(nil, 'ARTWORK')
	Icon:SetAllPoints(auraButton)
	auraButton:SetIcon(Icon)

	-- Cooldown swipe
	local Cooldown = CreateFrame('Cooldown', nil, auraButton, 'CooldownFrameTemplate')
	Cooldown:SetReverse(true)
	Cooldown:SetAllPoints(auraButton)
	Cooldown:SetHideCountdownNumbers(true)
	Cooldown:SetDrawEdge(false)

	-- Text frame
	local TextFrame = CreateFrame('Frame', nil, auraButton)
	TextFrame:SetAllPoints(auraButton)
	TextFrame:SetFrameLevel(Cooldown:GetFrameLevel() + 6)

	-- Duration text
	local Duration = TextFrame:CreateFontString(nil, 'OVERLAY')
	Duration:SetAllPoints(auraButton)
	Duration:SetFont(font, 12, fontFlags)
	auraButton:SetDurationCooldown(Cooldown)
	auraButton:SetDurationText(Duration, {textFormatter = DurationFormatter})

	-- Stacks text
	local Stacks = TextFrame:CreateFontString(nil, 'OVERLAY')
	Stacks:SetPoint('BOTTOMRIGHT', auraButton, 'BOTTOMRIGHT', 2, 0)
	Stacks:SetFont(font, 10, fontFlags)
	auraButton:SetApplicationCount(Stacks, {})

	-- Border
	local Border = CreateFrame('Frame', nil, auraButton, 'BackdropTemplate')
	Border:SetBackdrop({
		edgeFile = texture,
		edgeSize = 2,
		insets   = {left = 0, right = 0, top = 0, bottom = 0},
	})
	Border:SetBackdropColor(0, 0, 0, 0)
	Border:SetBackdropBorderColor(0, 0, 0, 1)
	Border:ClearAllPoints()
	Border:SetPoint('BOTTOMLEFT', auraButton, 'BOTTOMLEFT', 0, 0)
	Border:SetPoint('TOPRIGHT', auraButton, 'TOPRIGHT', 0, 0)
	Border:SetFrameStrata('MEDIUM')
	Border:SetFrameLevel(auraButton:GetFrameLevel() + 2 + 2)

	if isBuff then auraButton:SetCancelAuraButtons('RightButtonUp') end
end

-- Delay creation because duration text won't show on initial login
local function skinAuras()
	-- Buffs
	local BuffContainer = CreateFrame('AuraContainer', nil, UIParent, 'CustomAuraContainerTemplate')
	BuffContainer:SetSize(1, 1)
	BuffContainer:SetPoint(buffAnchorPoint, Minimap, buffRelativePoint, buffxOffset, buffyOffset)
	BuffContainer:SetUnit('player')
	BuffContainer:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
	BuffContainer:SetFlowLayoutAnchorPoint('TOPRIGHT')
	BuffContainer:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)
	BuffContainer:SetFlowLayoutMaximumLineSize(ROW_WIDTH)

	BuffContainer:AddAuraGroup('buffs', 'HELPFUL', {
		sortMethod    = AuraContainerSortMethod.ExpirationOnly,
		sortDirection = AuraContainerSortDirection.Reverse,
		layout = {
			elementSpacing = SPACING,
			lineSpacing    = SPACING,
		},
		initializeFrame = function(auraButton) initializeAuraFrame(auraButton, true) end,
	})

	-- Temp weapon enchants
	BuffContainer:AddItemEnchantment(AuraContainerItemEnchantmentSlot.MainHand, {initializeFrame = function(auraButton) initializeAuraFrame(auraButton, true) end})
	BuffContainer:AddItemEnchantment(AuraContainerItemEnchantmentSlot.OffHand, {initializeFrame = function(auraButton) initializeAuraFrame(auraButton, true) end})
	BuffContainer:SetItemEnchantmentLayout({
		elementSpacing = SPACING,
		lineSpacing    = SPACING,
		groupSpacing   = SPACING,
	})

	-- Debuffs
	local DebuffContainer = CreateFrame('AuraContainer', nil, UIParent, 'CustomAuraContainerTemplate')
	DebuffContainer:SetSize(1, 1)
	DebuffContainer:SetPoint(debuffAnchorPoint, Minimap, debuffRelativePoint, debuffxOffset, debuffyOffset)
	DebuffContainer:SetUnit('player')
	DebuffContainer:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
	DebuffContainer:SetFlowLayoutAnchorPoint('BOTTOMRIGHT')
	DebuffContainer:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)
	DebuffContainer:SetFlowLayoutMaximumLineSize(ROW_WIDTH)

	DebuffContainer:AddAuraGroup('debuffs', 'HARMFUL', {
		sortMethod    = AuraContainerSortMethod.ExpirationOnly,
		sortDirection = AuraContainerSortDirection.Reverse,
		layout        = {
			elementSpacing  = SPACING,
			lineSpacing     = SPACING,
		},
		initializeFrame = function(auraButton) initializeAuraFrame(auraButton, false) end,
	})

	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', skinAuras)
end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', skinAuras)