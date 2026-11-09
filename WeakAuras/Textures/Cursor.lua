---@type string, addonMods
local _, addonMods = ...

-- Create frame to anchor to mouse
local MouseFrame = CreateFrame('Frame', nil, UIParent)
addonMods.MouseFrame = MouseFrame
MouseFrame:SetSize(1, 1)
MouseFrame.moveWithMouse = function()
	local scale = 1 / UIParent:GetEffectiveScale()
	local x, y  =  GetCursorPosition()
	MouseFrame:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', x * scale, y * scale)
end
MouseFrame:SetScript('OnUpdate', MouseFrame.moveWithMouse)

-- Create visuals
local Cursor = MouseFrame:CreateTexture(nil, 'OVERLAY')
local size   = 38.53

Cursor:SetTexture([[Interface\AddOns\AddonMods\Media\Aura73.tga]])
Cursor:SetSize(size, size)
Cursor:SetPoint('CENTER', MouseFrame, 'CENTER', 0, 0)
Cursor:SetBlendMode('ADD')

---@param mouseButtonDown boolean
local function recolorCursor(mouseButtonDown)
	if mouseButtonDown then
		Cursor:SetVertexColor(133/255, 0, 0)
	else
		Cursor:SetVertexColor(1, 1, 1)
	end
end

local function mouseUp()
	local mouseButtonDown = IsMouseButtonDown('LeftButton') or IsMouseButtonDown('RightButton')
	recolorCursor(mouseButtonDown)
end

local function mouseDown()
	recolorCursor(true)
end

-- Event Registration
addonMods.RegisterEventHandler('GLOBAL_MOUSE_UP', mouseUp)
addonMods.RegisterEventHandler('GLOBAL_MOUSE_DOWN', mouseDown)