---@type string, addonMods
local _, addonMods = ...
if not NorthernSkyRaidTools then return end

---@param show boolean
local function updateVisibility(show)
  for _, name in ipairs({'ReminderFrame', 'PersonalReminderFrame', 'ExtraReminderFrame'}) do
    local note  = NorthernSkyRaidTools[name]
    local mover = NorthernSkyRaidTools[name .. 'Mover']

    if note and mover then
      local settings = NSRT.ReminderSettings[name]
      if show then
        NorthernSkyRaidTools:UpdateNoteFrame(name, settings, 'skip')
      else
        note:Hide()
        mover:Hide()
      end
    end
  end
end

---@param e string
local function checkEncounter(e)
  local inEncounter = e == 'PLAYER_REGEN_DISABLED'
  updateVisibility(not inEncounter)
end

addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', checkEncounter)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', checkEncounter)