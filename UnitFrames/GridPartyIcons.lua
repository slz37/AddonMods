---@type string, addonMods
local _, addonMods = ...
if not Grid2 then return end

local ANCHOR_POINT   = 'TOPLEFT'
local RELATIVE_POINT = 'TOPLEFT'

---@return boolean
local function checkShowPlayer()
	return Grid2.db:GetCurrentProfile() == 'Healer'
end

local function partyIcons()
	local showPlayer = checkShowPlayer()
	local maxFrames  = showPlayer and (MAX_PARTY_MEMBERS + 1) or MAX_PARTY_MEMBERS

	for frameIndex = 1, maxFrames do
		local unit
		if showPlayer then
			unit = (frameIndex == 1 and 'player') or ('party' .. (frameIndex - 1))
		else
			unit = 'party' .. frameIndex
		end

		local role       = UnitGroupRolesAssigned(unit)
		local UnitButton = _G['Grid2LayoutHeader1UnitButton' .. frameIndex]
		local UnitText   = UnitButton and UnitButton['party-name']
		local RoleIcon   = _G['GridPartyIcon' .. frameIndex .. 'Role']
		if role and not IsInRaid() and UnitText then
			if not RoleIcon then
				RoleIcon = CreateFrame('Frame', 'GridPartyIcon' .. frameIndex .. 'Role', UIParent)
				RoleIcon:SetSize(17, 17)
				RoleIcon.Texture = RoleIcon:CreateTexture()
			end
			if role == 'TANK' then
				RoleIcon.Texture:SetTexture('Interface\\GroupFrame\\UI-Group-MainTankIcon')
				RoleIcon.Texture:SetTexCoord(0, 1, 0, 1)
				RoleIcon.Texture:SetSize(12, 12)
				RoleIcon.Texture:SetVertexColor(1, 1, 1, 1)
				RoleIcon.Texture:SetPoint(ANCHOR_POINT, UnitText, RELATIVE_POINT, -1, 0)
			elseif role == 'DAMAGER' then
				RoleIcon.Texture:SetTexture('Interface\\GroupFrame\\UI-Group-MainAssistIcon')
				RoleIcon.Texture:SetTexCoord(0, 1, 0, 1)
				RoleIcon.Texture:SetSize(12, 12)
				RoleIcon.Texture:SetVertexColor(1, 1, 1, 1)
				RoleIcon.Texture:SetPoint(ANCHOR_POINT, UnitText, RELATIVE_POINT, -1, 0)
			elseif role == 'HEALER' then
				RoleIcon.Texture:SetTexture('Interface\\Addons\\AddonMods\\Media\\newaura.tga')
				RoleIcon.Texture:SetSize(9, 9)
				RoleIcon.Texture:SetVertexColor(1, .839, .027, 1)
				RoleIcon.Texture:SetPoint(ANCHOR_POINT, UnitText, RELATIVE_POINT, 0, -2)
			end

			RoleIcon:SetParent(UnitText)
			RoleIcon.Texture:Show()
			RoleIcon:Show()
		elseif RoleIcon then
			RoleIcon:Hide()
			RoleIcon.Texture:Hide()
		end
	end

	-- Hide leftover icon when showPlayer is toggled off
	local RoleIcon = _G['GridPartyIcon' .. (MAX_PARTY_MEMBERS + 1) .. 'Role']
	if not showPlayer and RoleIcon then
		RoleIcon:Hide()
		RoleIcon.Texture:Hide()
	end
end

local function setIcons()
	RunNextFrame(function() partyIcons() end)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', setIcons)
addonMods.RegisterEventHandler('PLAYER_ROLES_ASSIGNED', setIcons)