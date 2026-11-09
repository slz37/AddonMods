---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture
local font    = addonMods.defaultFont

local AltPowerBar = addonMods.NewBar({
  w              = 225,
  h              = 22.5,
  anchorPoint    = 'CENTER',
  relativePoint  = 'CENTER',
  relativeFrame  = UIParent,
  xOffset        = 0,
  yOffset        = -340,
  texture        = texture,
  color          = {0.573, 0.247, 0.247, 1},
  bgColor        = {0, 0, 0, 0.66},
  min            = 0,
  max            = 1,
  smoothProgress = false,
  spark = {
    w         = 2,
    texture   = texture,
    blendMode = 'ADD',
    color     = {r = 1, g = 1, b = 1, a = 1},
  },
  borders = {
    {
      inset       = 0,
      edgeFile    = texture,
      edgeSize    = 1,
      borderColor = {r = 0, g = 0, b = 0, a = 1},
      levelOffset = -1,
    },
  },
  texts = {
    name = {
      font              = font,
      fontSize          = 16,
      fontFlags         = 'OUTLINE, SLUG',
      fontAnchorPoint   = 'LEFT',
      fontRelativePoint = 'LEFT',
      fontXOffset       = 1,
      fontYOffset       = 0,
      fontColor         = {r = 1, g = 1, b = 1, a = 1},
      parent						= 1
    },
    duration = {
      font              = font,
      fontSize          = 16,
      fontFlags         = 'OUTLINE, SLUG',
      fontAnchorPoint   = 'RIGHT',
      fontRelativePoint = 'RIGHT',
      fontXOffset       = 0,
      fontYOffset       = 0,
      fontColor         = {r = 1, g = 1, b = 1, a = 1},
      parent						= 1
    },
    totalDuration = {
      font              = font,
      fontSize          = 16,
      fontFlags         = 'OUTLINE, SLUG',
      fontAnchorPoint   = 'RIGHT',
      fontRelativePoint = 'RIGHT',
      fontXOffset       = 0,
      fontYOffset       = 0,
      fontColor         = {r = 1, g = 1, b = 1, a = 1},
      parent						= 1
    },
  },
})

AltPowerBar.texts.duration:ClearAllPoints()
AltPowerBar.texts.duration:SetPoint('RIGHT', AltPowerBar.texts.totalDuration, 'LEFT', 3, 0)

-- Use alpha to avoid secret taint with GetWidth()
AltPowerBar:Show()
AltPowerBar:SetAlpha(0)

local sparkCurve = C_CurveUtil.CreateColorCurve()
sparkCurve:SetType(Enum.LuaCurveType.Step)

sparkCurve:AddPoint(0, CreateColor(1, 1, 1, 0))
sparkCurve:AddPoint(0.0001, CreateColor(1, 1, 1, 1))
sparkCurve:AddPoint(0.9999, CreateColor(1, 1, 1, 1))
sparkCurve:AddPoint(1, CreateColor(1, 1, 1, 0))

if AltPowerBar.Spark then
  AltPowerBar.Spark:ClearAllPoints()
  AltPowerBar.Spark:SetPoint('CENTER', AltPowerBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
end

---@param powerType string
local function checkAltPower(_,_, powerType)
  if powerType ~= 'ALTERNATE' then return end

  local power    = UnitPower('player', 10)
  local maxPower = UnitPowerMax('player', 10)
  local label    = GetUnitPowerBarStrings('player')

  if label and maxPower > 0 then
    AltPowerBar.texts.name:SetText(label)
    AltPowerBar.texts.duration:SetText(power)
    AltPowerBar.texts.totalDuration:SetText(' | ' .. maxPower)

    local percent      = UnitPowerPercent('player', 10, false, sparkCurve)
    local _,_,_, alpha = percent:GetRGBA()
    AltPowerBar.Spark:SetAlpha(alpha)

    AltPowerBar:SetMinMaxValues(0, maxPower)
    AltPowerBar:SetValue(power)
    AltPowerBar:SetAlpha(1)
  else
    AltPowerBar:SetAlpha(0)
  end
end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', function() checkAltPower(nil, nil, 'ALTERNATE') end)
addonMods.RegisterUnitEventHandler('UNIT_POWER_BAR_SHOW', 'player', function() checkAltPower(nil, nil, 'ALTERNATE') end)
addonMods.RegisterUnitEventHandler('UNIT_POWER_UPDATE', 'player', checkAltPower)
addonMods.RegisterUnitEventHandler('UNIT_POWER_BAR_HIDE', 'player', function() checkAltPower(nil, nil, 'ALTERNATE') end)
addonMods.KillFrame(PlayerPowerBarAlt)