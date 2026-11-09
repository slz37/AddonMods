---@type string, addonMods
local _, addonMods = ...

local SOUND = 'Interface\\AddOns\\AddonMods\\Media\\Sounds\\Sonar.ogg'

local function checkStatus(_,_, status)
  if status ~= 'invited' then return end
  PlaySoundFile(SOUND, 'Master')
end

addonMods.RegisterEventHandler('LFG_LIST_APPLICATION_STATUS_UPDATED', checkStatus)