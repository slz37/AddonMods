---@type string, addonMods
local _, addonMods = ...
if not ExBoss then return end

local modules = {
  --[[
  ['FlashText']       = {'font_flash'},
  ['FlashTextMedium'] = {'font_flash'},
  ['IconAlert']       = {'font_text'},
  ['Countdown']       = {'font_label', 'font_cd'},
  ['CastProgressBar'] = {'font_name',  'font_time'},
  ['RingProgress']    = {'font_name',  'font_time'},
  ['ExtraShieldBar']  = {'font_name',  'font_time'},
  ['TimerBar']        = {'font_name',  'font_time'},

  ['Tools.MythicCast'] = {'font_spell', 'font_target', 'font_timer'},
  ['TargetAlert']      = {'font_spell', 'font_timer'},
  ]]

  ['FlashText']       = {},
  ['FlashTextMedium'] = {'font_text'},
  ['IconAlert']       = {'font_text',   'font_time', 'font_stacks'},
  ['Countdown']       = {'font_text',   'font_time'},
  ['CastProgressBar'] = {'font_spell',  'font_timer'},
  ['RingProgress']    = {'font_spell',  'font_timer'},
  ['ExtraShieldBar']  = {'font_spell',  'font_timer'},
  --['TimerBar']        = {},

  ['Tools.MythicCast']       = {'font_spell', 'font_target', 'font_timer'},
  ['Tools.InterruptTracker'] = {'font_spell', 'font_timer'},
  --['TargetAlert']      = {},
}

for module, texts in pairs(modules) do
  local moduleName = 'ExBoss.' .. module
  local db = ExwindTools.GetModuleDB(ExwindTools, moduleName)

  local changed = false
  for _, text in ipairs(texts) do
    if db and db[text] then
      db[text].outline = 'OUTLINE, SLUG'
      changed = true
    end
  end

  if changed then
    local ui = ExBoss.UI[module]
    if ui and ui.RefreshVisuals then
      ui:RefreshVisuals()
    else
      ExwindTools.UI:NotifyModuleValueChanged(moduleName, '*', 'committed')
    end
  end
end

--[[do
  ExBossDB 			 = ExBossDB or {}
  ExBossDB.timer = ExBossDB.timer or {}
  local styleDB  = ExBossDB.timer.trash248690AbsorbStyle

  if type(styleDB) == 'table' then
    local fontDB = nil
    if type(styleDB.font_percent) == 'table' then
      fontDB = styleDB.font_percent
    elseif type(styleDB.font_time) == 'table' then
      fontDB = styleDB.font_time
    end

    if fontDB then
			fontDB.outline = 'OUTLINE, SLUG'

			local trashAbsorb = ExBoss.Modules and ExBoss.Modules.Boss and ExBoss.Modules.Boss.MaisaraTrash248690Absorb
			if trashAbsorb and trashAbsorb.RefreshVisuals then trashAbsorb:RefreshVisuals() end
    end
  end
end]]