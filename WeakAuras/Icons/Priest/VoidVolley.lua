---@type string, addonMods
local _, addonMods = ...
if addonMods.myClass ~= 'PRIEST' then return end

local texture   = addonMods.defaultTexture
local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'
---@cast fontFlags string

local VOLLEY_IDS = {
  [1279437] = true,
  [1242171] = true,
}

local DurationFormatter = C_StringUtil.CreateNumericRuleFormatter()
DurationFormatter:SetBreakpoints({
	{threshold = 0,     format = '%.1f'},
	{threshold = 3.01,  format = '%d'},
	{threshold = 60,    format = '%d:%02d', components = {{div = 60}, {mod = 60}}},
	{threshold = 600,   format = '%dm',     components = {{div = 60}}},
	{threshold = 3600,  format = '%dh',     components = {{div = 3600}}},
	{threshold = 86400, format = '%dd',     components = {{div = 86400}}},
})

local Container = CreateFrame('AuraContainer', nil, UIParent, 'CustomAuraContainerTemplate')
Container:SetSize(1, 1)
Container:SetPoint('CENTER', UIParent, 'CENTER', -128, -106)
Container:SetUnit('player')

Container:AddAuraGroup('voidvolley', 'HELPFUL|PLAYER', {
	maxFrameCount = 10,
	sortMethod    = AuraContainerSortMethod.Expiration,
	candidateFilters = {
		includeSpellIDs = VOLLEY_IDS,
	},
	layout = {
		elementSpacing = 1,
	},
	initializeFrame = function(auraButton)
		PixelUtil.SetSize(auraButton, 30, 24)
    auraButton:SetMouseMotionEnabled(false)

		-- Icon
		local Icon = auraButton:CreateTexture(nil, 'ARTWORK')
		Icon:SetAllPoints(auraButton)
		auraButton:SetIcon(Icon)
    Icon:SetTexCoord(0.04, 1 - 0.04, (0.04 + 0.1), 1 - (0.04 + 0.1))

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

    -- Stacks Text
		local Stacks = TextFrame:CreateFontString(nil, 'OVERLAY')
		Stacks:SetPoint('BOTTOMRIGHT', auraButton, 'BOTTOMRIGHT', 2, 0)
		Stacks:SetFont(font, 10, fontFlags)
		auraButton:SetApplicationCount(Stacks, {})

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
		Border:SetFrameStrata('MEDIUM')

		-- Stack levels so multiple borders layer predictably instead of z-fighting.
		local levelOffset = 2
		Border:SetFrameLevel(auraButton:GetFrameLevel() + 2 + levelOffset)
	end,
})

local function checkSpec()
	local specIndex   = C_SpecializationInfo.GetSpecialization()
	local specId      = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local isValidSpec = specId == 258

  Container:SetEnabled(isValidSpec)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_LOGIN', checkSpec)
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', checkSpec)