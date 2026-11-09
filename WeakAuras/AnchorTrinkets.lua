---@type string, addonMods
local _, addonMods = ...

local Timer
local guard = false

---@param self table<string, any>>
local function repositionECME(self)
	guard = true
	self:ClearAllPoints()
	self:SetPoint('TOPLEFT', addonMods.PetFrame, 'TOPLEFT', -1, 9)
	guard = false
end

local function hookECME()
	local frame = ECME_CDMBar_custom_7_182093_94
	if not frame or frame._eui_hooked then return end

	frame._eui_hooked = true
	hooksecurefunc(frame, 'SetPoint', function(self)
		if guard then return end
		if Timer then Timer:Cancel() end
		Timer = C_Timer.NewTimer(0.1, function()
			Timer = nil
			repositionECME(self)
		end)
	end)
end

local function anchorFrame()
	if BCDM_TrinketBar then
		BCDM_TrinketBar:ClearAllPoints()
		BCDM_TrinketBar:SetPoint('TOPLEFT', addonMods.PetFrame, 'TOPLEFT', -1, 10.5)
	elseif CDMGroups_Trinkets then
		CDMGroups_Trinkets:ClearAllPoints()
		CDMGroups_Trinkets:SetPoint('TOPLEFT', addonMods.PetFrame, 'TOPLEFT', -2.8, 12.5)
	elseif ECME_CDMBar_custom_7_182093_94 then
		hookECME()
	end
end

local function playerEnteringWorld()
	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
	C_Timer.After(1, anchorFrame)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)