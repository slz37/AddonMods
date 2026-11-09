---@type string, addonMods
local _, addonMods = ...
if addonMods.myClass ~= 'PRIEST' then return end

local texture   = addonMods.defaultTexture
local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'
---@cast fontFlags string

local ns = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS['EllesmereUICooldownManager']
if not ns then return end

local BASE_SPELL_ID = 17
local AURA_ID       = 65081
local ICON_ID       = 135940

local DurationFormatter = C_StringUtil.CreateNumericRuleFormatter()
DurationFormatter:SetBreakpoints({
	{threshold = 0,     format = '%d'},
})

local Container = CreateFrame('AuraContainer', nil, UIParent, 'CustomAuraContainerTemplate')
Container:SetSize(1, 1)
Container:SetUnit('player')

Container:AddAuraGroup('pws', 'HELPFUL|PLAYER', {
	maxFrameCount = 1,
	sortMethod    = AuraContainerSortMethod.Expiration,
	candidateFilters = {
		includeSpellIDs = {[AURA_ID] = true},
	},
	layout = {
		elementSpacing = 1,
	},
	initializeFrame = function(auraButton)
		PixelUtil.SetSize(auraButton, 31, 25)
    auraButton:SetMouseMotionEnabled(false)
		auraButton:SetFrameStrata('HIGH')

		-- Icon
		local Icon = auraButton:CreateTexture(nil, 'ARTWORK')
		Icon:SetAllPoints(auraButton)
		Icon:SetTexture(ICON_ID)
    Icon:SetTexCoord(0.04, 1 - 0.04, (0.04 + 0.1), 1 - (0.04 + 0.1))

		-- Text frame
		local TextFrame = CreateFrame('Frame', nil, auraButton)
		TextFrame:SetAllPoints(auraButton)
		TextFrame:SetFrameLevel(auraButton:GetFrameLevel() + 6)

		-- Duration text
		local Duration = TextFrame:CreateFontString(nil, 'OVERLAY')
		Duration:SetPoint('BOTTOM', auraButton, 'BOTTOM', 0, 0)
		Duration:SetFont(font, 12, fontFlags)
    Duration:SetTextColor(0.52549022436142, 1, 0.46666669845581, 1)
		auraButton:SetDurationText(Duration, {textFormatter = DurationFormatter})

		-- Border
		local inset       = 0
		local edgeFile    = texture
		local edgeSize    = 2
		local borderColor = {r = 0, g = 0, b = 0, a = 1}

		local Border = CreateFrame('Frame', nil, auraButton, 'BackdropTemplate')
		Border:SetBackdrop({
			edgeFile = edgeFile,
			edgeSize = edgeSize,
			insets   = {left = inset, right = inset, top = inset, bottom = inset},
		})
		Border:SetBackdropColor(0, 0, 0, 0)
		Border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
		Border:ClearAllPoints()
		Border:SetPoint('BOTTOMLEFT', auraButton, 'BOTTOMLEFT', 0, 0)
		Border:SetPoint('TOPRIGHT', auraButton, 'TOPRIGHT', 0, 0)
		Border:SetFrameStrata('HIGH')

		-- Stack levels so multiple borders layer predictably instead of z-fighting.
		local levelOffset = 2
		Border:SetFrameLevel(auraButton:GetFrameLevel() + 2 + levelOffset)
	end,
})

---@param displayName string
---@return string?
local function findBarKeyByName(displayName)
  for key, barData in pairs(ns.barDataByKey) do
    if barData.name == displayName then return key end
  end
end

---@param barKey string
---@return table<string, any>?
local function findIconForSpell(barKey)
  local icons = ns.cdmBarIcons and ns.cdmBarIcons[barKey]
  if not icons then return end

  for _, icon in ipairs(icons) do
    local fc = ns._ecmeFC[icon]
    if fc and (fc.spellID == BASE_SPELL_ID or fc.baseSpellID == BASE_SPELL_ID or fc.resolvedSid == BASE_SPELL_ID) then
      return icon
    end
  end
end

local currentIcon = nil

local function anchorToIcon()
  local barKey = findBarKeyByName('Utility (Hidden)')
  if not barKey then return end

  local icon = findIconForSpell(barKey)
  if not icon then return end

  if icon ~= currentIcon then
    Container:ClearAllPoints()
    Container:SetPoint('BOTTOM', icon, 'BOTTOM', 0, 0)
    currentIcon = icon
  end
end

hooksecurefunc(ns, 'LayoutCDMBar', function(calledBarKey) anchorToIcon() end)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', anchorToIcon)