---@type string, addonMods
local _, addonMods = ...

local specColors = {
	[102]  = {255/255, 124/255, 10/255},    -- Balance
	[103]  = {255/255, 124/255, 10/255},    -- Feral

	[250]  = {255/255, 97/255,  112/255},   -- Blood
	[251]  = {104/255, 223/255, 255/255},   -- Frost
	[252]  = {127/255, 255/255, 110/255},   -- Unholy

	[258]  = {108/255, 51/255, 131/255},    -- Shadow

	[577]  = {163/255, 48/255, 201/255},    -- Havoc
	[581]  = {163/255, 48/255, 201/255},    -- Vengeance
	[1480] = {131/255, 31/255, 53/255},     -- Devourer
	
	[265] = {163/255, 95/255, 235/255}, 		-- Affliction
	[266] = {163/255, 95/255, 235/255}, 		-- Demonology
	[267] = {163/255, 95/255, 235/255}, 		-- Destruction
}

local SQRT2 = sqrt(2)
---@param degrees number
---@param scaleForFullRotate boolean?
---@return number, number, number, number, number, number, number, number
local function getRotatedPoints(degrees, scaleForFullRotate)
  degrees			 = degrees or 0
  local angle  = rad(135 - degrees)
  local factor = scaleForFullRotate and 1 or SQRT2
  local vx 		 = math.cos(angle) / factor
  local vy 		 = math.sin(angle) / factor

  return 0.5+vx,0.5-vy , 0.5-vy,0.5-vx , 0.5+vy,0.5+vx , 0.5-vx,0.5+vy
end

local LocationIcon
local function colorIcon()
	-- Spec based colors
	local specIndex = C_SpecializationInfo.GetSpecialization()
	local specId    = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	local colors    = specColors[specId] or {1, 1, 1}	
	local r, g, b 	= unpack(colors)

	LocationIcon:SetVertexColor(r, g, b)
end

local function createIcon()
	LocationIcon = UIParent:CreateTexture(nil, 'OVERLAY')
	LocationIcon:SetTexture([[Interface\AddOns\AddonMods\Media\Aura104.tga]])
	LocationIcon:SetSize(170.15, 170.15)
	LocationIcon:SetPoint('CENTER', 0.5, -43)

	local ulx,uly, llx,lly, urx,ury, lrx,lry = getRotatedPoints(0, true)
	LocationIcon:SetTexCoord(ulx,uly, llx,lly, urx,ury, lrx,lry);
	colorIcon()
end

-- Need to wait for PEW to get specId or it returns 0
local function playerEnteringWorld()
	createIcon()
	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
addonMods.RegisterEventHandler('PLAYER_SPECIALIZATION_CHANGED', colorIcon)