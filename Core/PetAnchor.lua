---@type string, addonMods
local _, addonMods = ...

local PetFrame, Timer
local parent, petXOffset, petYOffset, noPetXOffset, noPetYOffset

local function createFrame()
	PetFrame = CreateFrame('Frame', nil, UIParent)
	addonMods.PetFrame = PetFrame

	PetFrame:SetSize(200, 200)

	if UUFG then
		parent = _G['UUF_Player']
		petXOffset, petYOffset     = 1, -22
		noPetXOffset, noPetYOffset = 1, -11
	elseif EllesmereUI then
		parent = _G['EllesmereUIUnitFrames_Player']
		petXOffset, petYOffset     = 1, -22
		noPetXOffset, noPetYOffset = 1, -10
	end
end

local function checkPet()
	Timer = nil

	local hasPet = UnitExists('pet')
	if hasPet then
		PetFrame:SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', petXOffset, petYOffset)
	else
		PetFrame:SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', noPetXOffset, noPetYOffset)
	end
end

local function unitPet()
	if Timer then Timer:Cancel() end
	Timer = C_Timer.NewTimer(0.1, checkPet)
end

---@param isLogin boolean
---@param isReload boolean
local function playerEnteringWorld(_, isLogin, isReload)
	if isLogin or isReload then createFrame() end
	unitPet()
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
addonMods.RegisterUnitEventHandler('UNIT_PET', 'player', unitPet)