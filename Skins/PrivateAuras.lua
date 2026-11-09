---@type string, addonMods
local _, addonMods = ...

local ICON_SIZE = 48
local NUM_ICONS = 5
local SPACING   = 1
local icons     = {}

local function init()
  local Container = CreateFrame('Frame', 'MinimalPrivateAurasContainer', UIParent)
  Container:SetPoint('CENTER', UIParent, 'CENTER', -186.5, 50)
  Container:SetSize(ICON_SIZE * NUM_ICONS + SPACING * (NUM_ICONS - 1), ICON_SIZE)

  local BG = Container:CreateTexture(nil, 'BACKGROUND')
  BG:SetAllPoints()
  BG:SetColorTexture(1, 0.82, 0, 0.25)
  BG:Hide()
  Container.BG = BG

  local ts   = ICON_SIZE / 32
  local comp = 32

  for i = 1, NUM_ICONS do
    local Slot = CreateFrame('Frame', nil, Container)
    Slot:SetScale(ts)
    Slot:SetSize(comp, comp)

    icons[i] = Slot
    Slot:ClearAllPoints()
    if i == 1 then
      Slot:SetPoint('CENTER', Container, 'CENTER', 0, 0)
    else
      Slot:SetPoint('CENTER', icons[i - 1], 'CENTER', -(ICON_SIZE + SPACING) / ts, 0)
    end
    Slot:Show()

    C_UnitAuras.AddPrivateAuraAnchor({
      unitToken            = 'player',
      auraIndex            = i,
      parent               = Slot,
      isContainer          = false,
      showCountdownFrame   = true,
      showCountdownNumbers = true,
      iconInfo = {
				iconWidth  = comp,
				iconHeight = comp,
				iconAnchor = {
					point         = 'CENTER',
					relativeTo    = Slot,
					relativePoint = 'CENTER',
					offsetX       = 0,
					offsetY       = 0,
				},
				countdownFrameAnchor = {
					point         = 'CENTER',
					relativeTo    = Slot,
					relativePoint = 'CENTER',
					offsetX       = 0,
					offsetY       = 0,
				},
				countdownNumbersAnchor = {
					point         = 'CENTER',
					relativeTo    = Slot,
					relativePoint = 'CENTER',
					offsetX       = 0,
					offsetY       = 0,
				},
				borderScale = 2,
			},
    })
  end
end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', init)