---@type string, addonMods
local _, addonMods = ...

local Timer

-- Helper Functions
local function summonPet()
  if Timer then Timer:Cancel() end

  Timer = C_Timer.NewTimer(0.5, function()
		local isFlying = IsFlying('player')
		local inCombat = InCombatLockdown()
		if isFlying or inCombat then return end

		local hasPet = C_PetJournal.GetSummonedPetGUID()
		if not hasPet then C_PetJournal.SummonPetByGUID('BattlePet-0-00000018F4FB') end
  end)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', summonPet)
addonMods.RegisterEventHandler('UPDATE_SHAPESHIFT_FORM', summonPet)
addonMods.RegisterEventHandler('COMPANION_UPDATE', summonPet)
addonMods.RegisterEventHandler('PLAYER_ALIVE', summonPet)
addonMods.RegisterEventHandler('CHALLENGE_MODE_START', summonPet)