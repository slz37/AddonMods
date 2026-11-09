---@type string, addonMods
local _, addonMods = ...

local actionBarFont = addonMods.defaultFont
local fontFlags     = 'OUTLINE, SLUG'
---@cast fontFlags string

local BUTTONS = {
	-- Extra Action Button
	'ExtraActionButton1', 'ZoneAbilityFrame',

	-- Possess Buttons
	'PossessButton1', 'PossessButton2',

	-- Vehicle Button
	'MainMenuBarVehicleLeaveButton',
}

if Dominos then
	local dominosButtons = {
		-- ActionBar
		'DominosActionButton1', 'DominosActionButton2', 'DominosActionButton3', 'DominosActionButton4', 'DominosActionButton5', 'DominosActionButton6',
		'DominosActionButton7', 'DominosActionButton8', 'DominosActionButton9', 'DominosActionButton10', 'DominosActionButton11', 'DominosActionButton12',

		-- Dominos Action Buttons
		'DominosActionButton13', 'DominosActionButton14', 'DominosActionButton15', 'DominosActionButton16',
		'DominosActionButton17', 'DominosActionButton18', 'DominosActionButton19', 'DominosActionButton20',
		'DominosActionButton21', 'DominosActionButton22', 'DominosActionButton23', 'DominosActionButton24',

		-- PetBar
		'PetActionButton1', 'PetActionButton2', 'PetActionButton3', 'PetActionButton4', 'PetActionButton5',
		'PetActionButton6', 'PetActionButton7', 'PetActionButton8', 'PetActionButton9', 'PetActionButton10',
	}
	for _, Button in ipairs(dominosButtons) do
		table.insert(BUTTONS, Button)
	end
end

local borders   = setmetatable({}, {__mode = 'k'})
local bindTexts = setmetatable({}, {__mode = 'k'})

---@param Button table<string, any>
local function styleActionButton(Button)
	if not Button then return end

	local name 					= Button:GetName()
	local Icon   				= _G[name..'Icon']
	local NormalTexture = _G[name..'NormalTexture'] or Button.NormalTexture
	local IconMask 			= _G[name].IconMask or Button.IconMask
	local Style					= Button.style

	if name == 'ExtraActionButton1' then
		Icon = Button.icon
	elseif name == 'ZoneAbilityFrame' then
		Button = ZoneAbilityFrame.SpellButtonContainer

		if not Button:IsVisible() then return end
		for k,v in pairs(Button:GetChildren()) do
			if k == 'Icon' then
				Icon = v
			elseif k == 'NormalTexture' then
				v:SetAlpha(0)
			end
		end

		ZoneAbilityFrame.Style:SetAlpha(0)
	end

	if NormalTexture then NormalTexture:SetAlpha(0) end
	if IconMask then IconMask:SetAlpha(0) end
	if Style then Style:SetAlpha(0) end

	if Button.HotKey then
		Button.HotKey:SetFont(actionBarFont, 14, fontFlags)
		Button.HotKey:ClearAllPoints()
		Button.HotKey:SetPoint('TOPRIGHT', Button, 'TOPRIGHT', 4, -3)
	end
	if Button.Count then
		Button.Count:SetFont(actionBarFont, 16, fontFlags)
		Button.Count:ClearAllPoints()
		Button.Count:SetPoint('BOTTOMRIGHT', Button, 'BOTTOMRIGHT', 4, -3)
	end
	if Icon then
		addonMods.WA_UpdateTexCoords(Icon, Button:GetWidth(), Button:GetHeight(), 0.3, true, 1, 1, 0, 0)
	end

	local BindText = bindTexts[name]
	if name == 'ExtraActionButton1' and not BindText then
		ExtraActionButton1HotKey:SetAlpha(0)

		local keyBind  = GetBindingKey('EXTRAACTIONBUTTON1')
		BindText = Button:CreateFontString()

		BindText:SetFont(actionBarFont, 16, fontFlags)
		BindText:SetText(keyBind)
		BindText:ClearAllPoints()
		BindText:SetPoint('TOPRIGHT', Button, 'TOPRIGHT', 0, -1)
		bindTexts[name] = BindText
	end

	local Region = borders[name]
	if not Region then
		Region = CreateFrame('Frame', nil, Button, 'BackdropTemplate')
		Region:SetFrameStrata('HIGH')
		Region:SetFrameLevel(9999)

		local edgeFile  = 'Interface\\Buttons\\WHITE8X8'
		local inset		  = 0
		local hasSlotBg = Button.SlotBackground ~= nil

		if hasSlotBg then Button.SlotBackground:SetAlpha(0) end

		Region:SetBackdrop({
			bgFile   = hasSlotBg and edgeFile or nil,
			edgeFile = edgeFile,
			edgeSize = PixelUtil.GetNearestPixelSize(2, Region:GetEffectiveScale()),
			insets   = {left = inset, right = inset, top = inset, bottom = inset}
		})
		Region:SetBackdropBorderColor(0, 0, 0, 1)
		Region:SetBackdropColor(0, 0, 0, hasSlotBg and 0.5 or 0)
		Region:ClearAllPoints()

		local offset = 0
		PixelUtil.SetPoint(Region, 'BOTTOMLEFT', Button, 'BOTTOMLEFT', -offset, -offset)
		PixelUtil.SetPoint(Region, 'TOPRIGHT',   Button, 'TOPRIGHT',    offset,  offset)

		borders[name] = Region
	end
end

local zoneAbilityHooked = false
local function hookZoneAbility()
	if not ZoneAbilityFrame or not ZoneAbilityFrame.SpellButtonContainer or zoneAbilityHooked then return end

	ZoneAbilityFrame.SpellButtonContainer:HookScript('OnShow', function(self)
		RunNextFrame(function() styleActionButton(_G['ZoneAbilityFrame']) end)
		zoneAbilityHooked = true
	end)
end

local function playerEnteringWorld()
	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)

	for _, Button in pairs(BUTTONS) do styleActionButton(_G[Button]) end
	hookZoneAbility()
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)