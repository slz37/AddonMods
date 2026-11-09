---@type string, addonMods
local _, addonMods = ...
if not EllesmereUI then return end

local RestTexture, CombatTexture
local function createTextures()
	local PlayerFrame = _G['EllesmereUIUnitFrames_Player']

	RestTexture = PlayerFrame:CreateTexture()
	RestTexture:SetPoint('LEFT', PlayerFrame, 'LEFT', 2, 9)
	RestTexture:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
	RestTexture:SetTexCoord(0.13, 0.37, 0.16, 0.25)
	RestTexture:SetSize(20, 10)

	CombatTexture = PlayerFrame:CreateTexture()
	CombatTexture:SetPoint('LEFT', PlayerFrame, 'LEFT', -1, 9)
	CombatTexture:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
	CombatTexture:SetTexCoord(0.50, 1.0, 0.0, 0.49)
	CombatTexture:SetSize(24, 24)
end

---@param isLogin boolean
---@param isReload boolean
local function playerEnteringWorld(_, isLogin, isReload)
	if isLogin or isReload then createTextures() end

	if UnitAffectingCombat('player') then
		CombatTexture:Show()
		RestTexture:Hide()
	elseif IsResting() then
		CombatTexture:Hide()
		RestTexture:Show()
	else
		CombatTexture:Hide()
		RestTexture:Hide()
	end
end

local function playerRegenDisabled()
	CombatTexture:Show()
	RestTexture:Hide()
end

local function playerRegenEnabled()
	CombatTexture:Hide()
	if IsResting() then
		RestTexture:Show()
	end
end

local function playerUpdateResting()
	if not IsResting() then
		RestTexture:Hide()
	else
		RestTexture:Show()
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
addonMods.RegisterEventHandler('PLAYER_UPDATE_RESTING', playerUpdateResting)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', playerRegenEnabled)
addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', playerRegenDisabled)