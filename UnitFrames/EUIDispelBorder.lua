---@type string, addonMods
local _, addonMods = ...
if not EllesmereUI then return end

local VALID_CLASSES = {
  ['PRIEST']  = true,
  ['DRUID']   = true,
	['WARLOCK'] = true,
}
if not VALID_CLASSES[addonMods.myClass] then return end

local units      = {'player', 'target'}
local containers = {}
local slotKeys   = {}
local EDGES      = {'top', 'bottom', 'left', 'right'}

local DispelColorMap = {
  None    = DEBUFF_TYPE_NONE_COLOR,
  Magic   = DEBUFF_TYPE_MAGIC_COLOR,
  Curse   = DEBUFF_TYPE_CURSE_COLOR,
  Disease = DEBUFF_TYPE_DISEASE_COLOR,
  Poison  = DEBUFF_TYPE_POISON_COLOR,
  Enrage  = CreateColor(243/255, 95/255, 245/255),
  Bleed   = DEBUFF_TYPE_BLEED_COLOR,
}

local BorderOptions = {
  showWhenHarmful       = true,
  showWhenHelpful       = true,
  showWithoutDispelType = false,
  style                 = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
  customDispelColorMap  = DispelColorMap,
}

---@param unit string
---@return string?
local function getFilter(unit)
  if UnitCanAttack('player', unit) then
		return 'HELPFUL|RAID_PLAYER_DISPELLABLE'
	elseif UnitCanAssist('player', unit) then
		return 'HARMFUL|RAID_PLAYER_DISPELLABLE'
	end
end

---@param unit string
local function createBorder(unit)
  local Parent    = _G['EllesmereUIUnitFrames_' .. unit:gsub('^.', string.upper)].unifiedBorder
  local Container = CreateFrame('AuraContainer', nil, Parent, 'CustomAuraContainerTemplate')
  Container:SetUnit(unit)
  containers[unit] = Container

  local borderSize = PixelUtil.GetNearestPixelSize(2, Parent:GetEffectiveScale())
  slotKeys[unit] = {}
  for i, edgeName in ipairs(EDGES) do
    local slotKey = 'edge' .. i
    slotKeys[unit][i] = slotKey

		local Button = Container:AddAuraSlot(slotKey, getFilter(unit) or 'HELPFUL|RAID_PLAYER_DISPELLABLE', {
			sortMethod    = 0,
			sortDirection = 0,
		})

    Button:SetAllPoints(Parent)
    Button:SetFrameStrata(Parent:GetFrameStrata())
    Button:SetFrameLevel(Parent:GetFrameLevel() + 5)
    Button:EnableMouse(false)

    local Tex = Button:CreateTexture(nil, 'OVERLAY', nil, 7)
    Tex:SetColorTexture(1, 1, 1, 1)

    if edgeName == 'top' then
      Tex:SetPoint('TOPLEFT', Parent, 'TOPLEFT', 0, 0)
      Tex:SetPoint('TOPRIGHT', Parent, 'TOPRIGHT', 0, 0)
      Tex:SetHeight(borderSize)
    elseif edgeName == 'bottom' then
      Tex:SetPoint('BOTTOMLEFT', Parent, 'BOTTOMLEFT', 0, 0)
      Tex:SetPoint('BOTTOMRIGHT', Parent, 'BOTTOMRIGHT', 0, 0)
      Tex:SetHeight(borderSize)
    elseif edgeName == 'left' then
      Tex:SetPoint('TOPLEFT', Parent, 'TOPLEFT', 0, 0)
      Tex:SetPoint('BOTTOMLEFT', Parent, 'BOTTOMLEFT', 0, 0)
      Tex:SetWidth(borderSize)
    elseif edgeName == 'right' then
      Tex:SetPoint('TOPRIGHT', Parent, 'TOPRIGHT', 0, 0)
      Tex:SetPoint('BOTTOMRIGHT', Parent, 'BOTTOMRIGHT', 0, 0)
      Tex:SetWidth(borderSize)
    end
    Button:AddDispelTypeTexture(Tex, BorderOptions)
  end
end

---@param unit string
local function refreshFilter(unit)
  local Container = containers[unit]
  if not Container then return end

  local filter = getFilter(unit)
  Container:SetShown(filter ~= nil)
  if not filter then return end

  for _, slotKey in ipairs(slotKeys[unit]) do
    Container:SetAuraSlotFilterString(slotKey, filter)
  end
end

local function init()
  for _, unit in ipairs(units) do createBorder(unit) end
  addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', init)
end

addonMods.RegisterUnitEventHandler('UNIT_FACTION', 'target', function() refreshFilter('target') end)
addonMods.RegisterEventHandler('PLAYER_TARGET_CHANGED', function() refreshFilter('target') end)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', init)