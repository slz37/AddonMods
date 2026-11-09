---@type string, addonMods
local _, addonMods = ...

local texture   = addonMods.defaultTexture
local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'
---@cast fontFlags string

local RAID_COOLDOWN_SPELL_IDS = {
	[81782]   = true,   -- Power Word: Barrier
	[145629]  = true,   -- Anti-Magic Zone
	[97463]   = true,   -- Rallying Cry
	[325174]  = true,   -- Spirit Link Totem
	[209426]  = true,   -- Darkness
	[196718]  = true,   -- Darkness
	[363534]  = true,   -- Rewind
	[374227]  = true,   -- Zephyr
	[31821]   = true,   -- Aura Mastery
	[317929]  = true,   -- Aura Mastery
	[102342]  = true,   -- Ironbark
	[47788]   = true,   -- Guardian Spirit
	[33206]   = true,   -- Pain Suppression
	[6940]    = true,   -- Blessing of Sacrifice
	[357170]  = true,   -- Time Dilation
	[740] 	  = true, 	-- Tranquility
	[157982]  = true, 	-- Tranquility
	[1264623] = true, 	-- Tranquility
	[64843]   = true, 	-- Divine Hymn
	[64844] 	= true, 	-- Divine Hymn
	[193065] 	= true, 	-- Protective Light
}

local DurationFormatter = C_StringUtil.CreateNumericRuleFormatter()
DurationFormatter:SetBreakpoints({
	{threshold = 0,     format = '%.1f'},
	{threshold = 10.01, format = '%d'},
	{threshold = 60,    format = '%d:%02d', components = {{div = 60}, {mod = 60}}},
	{threshold = 600,   format = '%dm',     components = {{div = 60}}},
	{threshold = 3600,  format = '%dh',     components = {{div = 3600}}},
	{threshold = 86400, format = '%dd',     components = {{div = 86400}}},
})

local Container = CreateFrame('AuraContainer', nil, UIParent, 'CustomAuraContainerTemplate')
Container:SetSize(1, 1)
Container:SetPoint('CENTER', UIParent, 'CENTER', 0.5, -138.5)
Container:SetUnit('player')

Container:AddAuraGroup('externals', 'HELPFUL', {
	maxFrameCount = 10,
	sortMethod    = AuraContainerSortMethod.Expiration,
	candidateFilters = {
		includeSpellIDs = RAID_COOLDOWN_SPELL_IDS,
	},
	layout = {
		elementSpacing = 1,
	},
	initializeFrame = function(auraButton)
		PixelUtil.SetSize(auraButton, 29, 23)

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
		
		-- Stacks text
		local Stacks = TextFrame:CreateFontString(nil, 'OVERLAY')
		Stacks:SetPoint('BOTTOMRIGHT', auraButton, 'BOTTOMRIGHT', 3, 0)
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