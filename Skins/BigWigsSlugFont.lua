---@type string, addonMods
local _, addonMods = ...
if not BigWigsAPI then return end

-- ElvUI Style Bars with slug font flags added
local E = ElvUI and ElvUI[1]
local backdropBorder = {
	bgFile   = 'Interface\\Buttons\\WHITE8X8',
	edgeFile = 'Interface\\Buttons\\WHITE8X8',
	tile     = false, tileSize = 0, edgeSize = 1,
	insets   = {left = 0, right = 0, top = 0, bottom = 0}
}

---@param Bar table<string, any>
local function removeStyle(Bar)
	local BD = Bar.candyBarBackdrop
	BD:Hide()
	if BD.iborder then
		BD.iborder:Hide()
		BD.oborder:Hide()
	end

	local restore = Bar:Get('bigwigs:restoreicon')
	if restore then
		local IconBd = Bar.candyBarIconFrameBackdrop
		IconBd:Hide()
		if IconBd.iborder then
			IconBd.iborder:Hide()
			IconBd.oborder:Hide()
		end
	end
end

---@param Bar table<string, any>
local function styleBar(Bar)
	local BD = Bar.candyBarBackdrop
	BD:ClearAllPoints()
	if E then
		BD:SetTemplate('Transparent')
		BD:SetOutside(Bar)
		if not E.PixelMode and BD.iborder then
			BD.iborder:Show()
			BD.oborder:Show()
		end
	else
		BD:SetBackdrop(backdropBorder)
		BD:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
		BD:SetBackdropBorderColor(0, 0, 0)
		BD:SetPoint('TOPLEFT', Bar, 'TOPLEFT', -1, 1)
		BD:SetPoint('BOTTOMRIGHT', Bar, 'BOTTOMRIGHT', 1, -1)
	end
	BD:Show()

	local label = Bar.candyBarLabel
	if label then label:SetFont(addonMods.defaultFont, 14, 'OUTLINE, SLUG') end

	local Duration = Bar.candyBarDuration
	if Duration then Duration:SetFont(addonMods.defaultFont, 14, 'OUTLINE, SLUG') end

	local IconTexture = Bar:GetIcon()
	if IconTexture then
		local reApplyIcon = false
		local Statusbar   = Bar.candyBarBar
		local IconFrame   = Bar.candyBarIconFrame
		local IconBd      = Bar.candyBarIconFrameBackdrop
		if IconFrame.IsAnchoringSecret and IconFrame:IsAnchoringSecret() then
			IconFrame:SetToDefaults()
			IconBd:SetToDefaults()
			IconBd:SetFrameLevel(0)
			reApplyIcon = true
		end
		Statusbar:ClearAllPoints()
		IconFrame:ClearAllPoints()
		IconBd:ClearAllPoints()

		if Bar:GetIconPosition() == 'RIGHT' then
			--IconFrame:SetPoint('BOTTOMLEFT', Bar, 'BOTTOMRIGHT', E and (E.PixelMode and 1 or 5) or 1, 0)
			IconFrame:SetPoint('TOPRIGHT', Bar, 'TOPRIGHT', 0, 0)
			IconFrame:SetPoint('BOTTOMRIGHT', Bar, 'BOTTOMRIGHT', 0, 0)

			Statusbar:SetPoint('TOPRIGHT', IconFrame, 'TOPLEFT', -1, 0)
			Statusbar:SetPoint('BOTTOMLEFT', Bar, 'BOTTOMLEFT', 0, 0)
		else
			--IconFrame:SetPoint('BOTTOMRIGHT', Bar, 'BOTTOMLEFT', E and (E.PixelMode and -1 or -5) or -1, 0)
			IconFrame:SetPoint('TOPLEFT', Bar, 'TOPLEFT', 0, 0)
			IconFrame:SetPoint('BOTTOMLEFT', Bar, 'BOTTOMLEFT', 0, 0)

			Statusbar:SetPoint('TOPLEFT', IconFrame, 'TOPRIGHT', 1, 0)
			Statusbar:SetPoint('BOTTOMRIGHT', Bar, 'BOTTOMRIGHT', 0, 0)
		end
		IconFrame:SetSize(Bar:GetHeight(), Bar:GetHeight())

		Bar:Set('bigwigs:restoreicon', true)
		if E then
			IconBd:SetTemplate('Transparent')
			IconBd:SetOutside(IconFrame)
			if not E.PixelMode and IconBd.iborder then
				IconBd.iborder:Show()
				IconBd.oborder:Show()
			end
		else
			IconBd:SetBackdrop(backdropBorder)
			IconBd:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
			IconBd:SetBackdropBorderColor(0, 0, 0)
			IconBd:SetPoint('TOPLEFT', IconFrame, 'TOPLEFT', -1, 1)
			IconBd:SetPoint('BOTTOMRIGHT', IconFrame, 'BOTTOMRIGHT', 1, -1)
		end
		IconBd:Show()

		if reApplyIcon then
			IconFrame:SetTexture(IconTexture)
			IconFrame:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end
	end
end

BigWigsAPI:RegisterBarStyle('ElvUI+Slug', {
	apiVersion            = 1,
	version               = 10,
	barSpacing            = E and (E.PixelMode and 4 or 8) or 4,
	barHeight             = 20,
	spellIndicatorsOffset = 2,
	ApplyStyle            = styleBar,
	BarStopped            = removeStyle,
	GetStyleName          = function() return 'ElvUI+Slug' end,
})

-- Countdown text
local flags = 'OUTLINE, SLUG'
local function overrideCountdownFlags()
	local profile = BigWigs:GetPlugin('Countdown', true)
	if not profile.db then
		C_Timer.After(0.1, overrideCountdownFlags)
		return
	end
	profile.db.profile.outline          = flags
	profile.db.defaults.profile.outline = flags
	BigWigs:SendMessage('BigWigs_ProfileUpdate')
end

local function overrideMessagesFlags()
	local profile = BigWigs:GetPlugin('Messages', true)
	if not profile.db then
		C_Timer.After(0.1, overrideMessagesFlags)
		return
	end
	profile.db.profile.outline          = flags
	profile.db.defaults.profile.outline = flags
	BigWigs:SendMessage('BigWigs_ProfileUpdate')
end

local function addonLoaded(self, addonName)
	if addonName ~= 'BigWigs_Plugins' then return end

	addonMods.UnregisterEventHandler('ADDON_LOADED', addonLoaded)
	C_Timer.After(2, overrideCountdownFlags)
	C_Timer.After(2, overrideMessagesFlags)
end

-- Event Registration
addonMods.RegisterEventHandler('ADDON_LOADED', addonLoaded)