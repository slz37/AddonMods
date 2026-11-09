---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

-- Create visuals
local FPSText = UIParent:CreateFontString(nil, 'OVERLAY')
local FPSIcon = UIParent:CreateTexture(nil, 'OVERLAY')

FPSIcon:SetTexture([[Interface\AddOns\AddonMods\Media\TitanPerformance.tga]])
FPSIcon:SetSize(16, 16)
FPSIcon:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)

FPSText:SetPoint('LEFT', FPSIcon, 'RIGHT', 1, 0)
---@cast fontFlags string
FPSText:SetFont(font, 12, fontFlags)

-- Color text by quality
local COLORS = {
	['high'] = '|cff1cba41',
	['med']  = '|cffffaf37',
	['low']  = '|cffe1462d',
}
local LOW_QUAL_PREFIX  = COLORS['low']
local MED_QUAL_PREFIX  = COLORS['med']
local HIGH_QUAL_PREFIX = COLORS['high']

---@param ping number
---@return string
local function dynamicColorPing(ping)
  if ping > 350 then
    return LOW_QUAL_PREFIX .. ping .. '|r'
  elseif ping > 100 then
    return MED_QUAL_PREFIX .. ping .. '|r'
  else
    return HIGH_QUAL_PREFIX .. ping .. '|r'
  end
end

---@param fps number
---@return string
local function dynamicColorFPS(fps)
  local fpsStr = string.format('%.1f', fps)
  if fps < 20 then
    return LOW_QUAL_PREFIX .. fpsStr .. '|r'
  elseif fps < 45 then
    return MED_QUAL_PREFIX .. fpsStr .. '|r'
  else
    return HIGH_QUAL_PREFIX .. fpsStr .. '|r'
  end
end

-- Update text when fps/ping changes
local lastHomePing, lastWorldPing, lastFPS
local function updateText()
	local curFPS = GetFramerate()
	local _,_, curHomePing, curWorldPing = GetNetStats()

  if curHomePing == lastHomePing and curWorldPing == lastWorldPing and curFPS == lastFPS then return end
	lastHomePing, lastWorldPing, lastFPS = curHomePing, curWorldPing, curFPS

	local homePing  = dynamicColorPing(curHomePing)
	local worldPing = dynamicColorPing(curWorldPing)
	local fps       = dynamicColorFPS(curFPS)

	FPSText:SetText(fps .. ' ' .. homePing .. 'ms/' .. worldPing .. 'ms')
end
C_Timer.NewTicker(3, updateText)