---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local FLASH_COLOR 			= {r = 255/255, g = 108/255, b = 108/255}
local DISPLAY_TYPE_NONE = 0

-- Create visuals
-- Template to get max width of string for centering
local WidthTemplate = UIParent:CreateFontString(nil, 'OVERLAY')
---@cast fontFlags string
WidthTemplate:SetFont(font, 18, fontFlags)
WidthTemplate:SetText('60s')
local maxDurationWidth = WidthTemplate:GetStringWidth() + 1
WidthTemplate:Hide()

-- Container to anchor everything relative to screen center
local Container = CreateFrame('Frame', nil, UIParent)
Container:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
Container:SetSize(1, 20)

-- Loss type
local LossLabel = UIParent:CreateFontString(nil, 'OVERLAY')
LossLabel:SetFont(font, 18, fontFlags)
LossLabel:SetJustifyH('RIGHT')
LossLabel:SetText('')

-- Loss duration
local LossDuration = UIParent:CreateFontString(nil, 'OVERLAY')
LossDuration:SetFont(font, 18, fontFlags)
LossDuration:SetJustifyH('LEFT')
LossDuration:SetWidth(maxDurationWidth)
LossDuration:SetText('')

local durationPulse = addonMods.CreatePulse(LossDuration, 0.5, FLASH_COLOR, 1)
local labelPulse    = addonMods.CreatePulse(LossLabel, 0.5, FLASH_COLOR, 1)

local SecondsFormatter = C_StringUtil.CreateSecondsFormatter()
SecondsFormatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
SecondsFormatter:SetStripIntervalWhitespace(Enum.SecondsFormatterIntervalWhitespace.Strip)

local DurationBinding = C_DurationUtil.CreateDurationTextBinding()
DurationBinding:SetFontString(LossDuration)
DurationBinding:SetFormatter(SecondsFormatter)
DurationBinding:SetExpiredText('')
DurationBinding:SetZeroDurationText('')
DurationBinding:SetEnabled(false)

-- Use alpha to avoid secret taint with GetWidth()
LossLabel:Show()
LossDuration:Show()
LossLabel:SetAlpha(0)
LossDuration:SetAlpha(0)

---@param hasDuration boolean
local function layout(hasDuration)
  local labelWidth = LossLabel:GetStringWidth()
  local totalWidth = labelWidth + (hasDuration and maxDurationWidth or 0)
  Container:SetWidth(totalWidth)

  LossLabel:ClearAllPoints()
  LossLabel:SetPoint('LEFT', Container, 'LEFT', 0, 0)

  LossDuration:ClearAllPoints()
  LossDuration:SetPoint('LEFT', LossLabel, 'RIGHT', 0, 0)
end

---@return table<string, any>?, number?
local function getDisplayedEffect()
  local count = C_LossOfControl.GetActiveLossOfControlDataCount()
  for i = 1, count do
    local data = C_LossOfControl.GetActiveLossOfControlData(i)
    if data and data.displayType ~= DISPLAY_TYPE_NONE then return data, i end
  end
end

local function refresh()
  -- Must delay for C_LossOfControl to update
  RunNextFrame(function()
    local locData, index = getDisplayedEffect()
    if not locData then
      DurationBinding:SetEnabled(false)
      addonMods.RemovePulse(durationPulse)
      addonMods.RemovePulse(labelPulse)

      -- On hide, must set alpha after pulse
      LossLabel:SetAlpha(0)
      LossDuration:SetAlpha(0)
      return
    end

    local duration = C_LossOfControl.GetActiveLossOfControlDuration('player', index)

    if duration then
      LossLabel:SetText((locData.displayText or '') .. ' - ')
      DurationBinding:SetDuration(duration)
      DurationBinding:SetEnabled(true)
    else
      LossLabel:SetText(locData.displayText or '')
      DurationBinding:SetEnabled(false)
      LossDuration:SetText('')
    end

    layout(duration ~= nil)

    -- On show, must set alpha before pulse
    LossLabel:SetAlpha(1)
    LossDuration:SetAlpha(1)
    addonMods.AddPulse(durationPulse)
    addonMods.AddPulse(labelPulse)
  end)
end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', refresh)
addonMods.RegisterEventHandler('PLAYER_CONTROL_GAINED', refresh)
addonMods.RegisterEventHandler('PLAYER_CONTROL_LOST', refresh)
addonMods.RegisterEventHandler('LOSS_OF_CONTROL_ADDED', refresh)
addonMods.RegisterEventHandler('LOSS_OF_CONTROL_UPDATE', refresh)