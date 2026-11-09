---@type string, addonMods
local _, addonMods = ...
if not EllesmereUI then return end

local ns = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS['EllesmereUICooldownManager']
if not ns then return end

local PP    = EllesmereUI.PP
local onePx = PP.mult

local heightRatios = {
  ['Cooldowns']         = 68,
  ['Utility']           = 80,
  ['Utility Overlay 1'] = 80,
  ['Utility Overlay 2'] = 80,
  ['Buffs']             = 80.4,
  ['Defensives']        = 65,
  ['Trinkets']          = 66,
  ['Utility (Hidden)']  = 80,
  ['Starfall Stacks']   = 68,
  ['Floating Center']   = 77.6,
  ['Floating Left']     = 77.6,
  ['Floating Right']    = 77.6,
}

local function correctBarLayout(barKey, pct)
  local frame    = ns.cdmBarFrames and ns.cdmBarFrames[barKey]
  local allIcons = ns.cdmBarIcons and ns.cdmBarIcons[barKey]
  local barData  = ns.barDataByKey and ns.barDataByKey[barKey]
  if not (frame and allIcons and barData and #allIcons > 0) then return end
  if (barData.iconShape or 'none') ~= 'cropped' then return end

  local grow    = barData.growDirection or 'CENTER'
  local isHoriz = (grow == 'RIGHT' or grow == 'LEFT' or (grow == 'CENTER' and not barData.verticalOrientation))
  if not isHoriz then return end

  local fcCache = ns._ecmeFC
  local icons   = allIcons
  if fcCache then
    local filtered
    for i = 1, #allIcons do
      local sfc = fcCache[allIcons[i]]
      if sfc and (sfc._cdStateShiftHidden or sfc._missingActiveHidden) then
        if not filtered then
          filtered = {}
          for j = 1, i - 1 do filtered[j] = allIcons[j] end
        end
      elseif filtered then
        filtered[#filtered + 1] = allIcons[i]
      end
    end
    if filtered then icons = filtered end
  end
  if #icons == 0 then return end

  local ratio   = pct / 100
  local rawH    = math.floor((barData.iconSize or 36) * ratio + 0.5)
  local iconHPx = math.floor(rawH / onePx + 0.5)
  local iconH   = iconHPx * onePx

  local liveW = icons[1]:GetWidth()
  if not liveW or liveW < 1 then liveW = barData.iconSize or 36 end

  local iconWPx = math.floor(liveW / onePx + 0.5)
  local iconW   = iconWPx * onePx

  local spacingPx = math.floor((barData.spacing or 2) / onePx + 0.5)
  local spacing   = spacingPx * onePx

  local stride, effRows, topRowCount = ns.ComputeTopRowStride(barData, #icons)
  local rowsReversed = ns.CDMRowsReversed(barData)

  local stepW = iconW + spacing
  local stepH = iconH + spacing

  local bottomRowCount = #icons - topRowCount
  if bottomRowCount < 0 then bottomRowCount = 0 end
  local function RowIconCount(row)
    if row == 0 then return topRowCount end
    return bottomRowCount
  end

  for i, icon in ipairs(icons) do
    icon:SetHeight(iconH)

    local col, row
    if i <= topRowCount then
      col, row = i - 1, 0
    else
      local bIdx = i - topRowCount - 1
      col, row = bIdx % stride, 1 + math.floor(bIdx / stride)
    end
    local vRow = rowsReversed and (effRows - 1 - row) or row

    local rowCount  = RowIconCount(row)
    local rowOffset = 0
    if rowCount > 0 and rowCount < stride then rowOffset = math.floor((stride - rowCount) * stepW / 2 + 0.5) end

    icon:ClearAllPoints()
    icon:SetPoint('TOPLEFT', frame, 'TOPLEFT', col * stepW + rowOffset, -(vRow * stepH))
  end

  frame:SetHeight(effRows * iconH + (effRows - 1) * spacing)
end

local function applyCroppedHeightsNow()
  if not ns.cdmBarIcons or not ns.barDataByKey then return end
  for barKey in pairs(ns.cdmBarIcons) do
    local barData = ns.barDataByKey[barKey]
    local pct = barData and barData.name and heightRatios[barData.name]
    if pct then correctBarLayout(barKey, pct) end
  end
end

local pending = false
local function reapplyCroppedHeights()
  applyCroppedHeightsNow()
  if pending then return end
  pending = true
  C_Timer.After(1, function()
    pending = false
    applyCroppedHeightsNow()
  end)
end

local function playerEnteringWorld()
  addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
  C_Timer.After(2, applyCroppedHeightsNow)
end

if ns.BuildAllCDMBars then hooksecurefunc(ns, 'BuildAllCDMBars', reapplyCroppedHeights) end
if ns.LayoutCDMBar then hooksecurefunc(ns, 'LayoutCDMBar', reapplyCroppedHeights) end
if ns.CollectAndReanchor then hooksecurefunc(ns, 'CollectAndReanchor', reapplyCroppedHeights) end
if ns.FullCDMRebuild then hooksecurefunc(ns, 'FullCDMRebuild', reapplyCroppedHeights) end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)