---@type string, addonMods
local _, addonMods = ...

local font    = addonMods.defaultFont
local texture = addonMods.defaultTexture

local done = setmetatable({}, {__mode = 'k'})
local hide = {'BGLeft', 'BGRight', 'BGCenter', 'BorderLeft', 'BorderRight', 'BorderCenter', 'Spark'}

local TITLE_SIZE = 14
local VALUE_SIZE = 14
local FLAGS      = 'OUTLINE, SLUG'

local BORDER_SIZE 			= 1
local BORDER_MIN_PIXELS = 1
local BORDER_R, BORDER_G, BORDER_B, BORDER_A = 0, 0, 0, 1

---@param Text FontString?
---@param size number
local function setFont(Text, size)
  if not Text or not Text.SetFont then return end
  Text:SetFont(font, size, FLAGS)
end

---@param bar table<string, any>
local function createBorder(bar)
  local top = bar:CreateTexture(nil, 'BACKGROUND', nil, -8)
  PixelUtil.SetPoint(top, 'TOPLEFT', bar, 'TOPLEFT', -BORDER_SIZE, BORDER_SIZE, BORDER_MIN_PIXELS, BORDER_MIN_PIXELS)
  PixelUtil.SetPoint(top, 'TOPRIGHT', bar, 'TOPRIGHT', BORDER_SIZE, BORDER_SIZE, BORDER_MIN_PIXELS, BORDER_MIN_PIXELS)
  PixelUtil.SetHeight(top, BORDER_SIZE, BORDER_MIN_PIXELS)

  local bottom = bar:CreateTexture(nil, 'BACKGROUND', nil, -8)
  PixelUtil.SetPoint(bottom, 'BOTTOMLEFT', bar, 'BOTTOMLEFT', -BORDER_SIZE, -BORDER_SIZE, BORDER_MIN_PIXELS, BORDER_MIN_PIXELS)
  PixelUtil.SetPoint(bottom, 'BOTTOMRIGHT', bar, 'BOTTOMRIGHT', BORDER_SIZE, -BORDER_SIZE, BORDER_MIN_PIXELS, BORDER_MIN_PIXELS)
  PixelUtil.SetHeight(bottom, BORDER_SIZE, BORDER_MIN_PIXELS)

  local left = bar:CreateTexture(nil, 'BACKGROUND', nil, -8)
  PixelUtil.SetPoint(left, 'TOPLEFT', bar, 'TOPLEFT', -BORDER_SIZE, 0, BORDER_MIN_PIXELS, 0)
  PixelUtil.SetPoint(left, 'BOTTOMLEFT', bar, 'BOTTOMLEFT', -BORDER_SIZE, 0, BORDER_MIN_PIXELS, 0)
  PixelUtil.SetWidth(left, BORDER_SIZE, BORDER_MIN_PIXELS)

  local right = bar:CreateTexture(nil, 'BACKGROUND', nil, -8)
  PixelUtil.SetPoint(right, 'TOPRIGHT', bar, 'TOPRIGHT', BORDER_SIZE, 0, BORDER_MIN_PIXELS, 0)
  PixelUtil.SetPoint(right, 'BOTTOMRIGHT', bar, 'BOTTOMRIGHT', BORDER_SIZE, 0, BORDER_MIN_PIXELS, 0)
  PixelUtil.SetWidth(right, BORDER_SIZE, BORDER_MIN_PIXELS)

  top:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
  bottom:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
  left:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
  right:SetColorTexture(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
end

---@param bar table<string, any>
local function skinTicks(bar)
  local pool = bar.partitionPool
  if not pool then return end

  for part in pool:EnumerateActive() do
    if part.Texture then part.Texture:SetAlpha(0) end
    for i = 1, select('#', part:GetRegions()) do
      local region = select(i, part:GetRegions())
      if region ~= part.line and region.SetAlpha then
        region:SetAlpha(0)
      end
    end

    if not part.line then
      local line = part:CreateTexture(nil, 'OVERLAY')
      line:SetColorTexture(176/255, 84/255, 84/255, 1)
      line:SetWidth(1)
      line:SetPoint('CENTER', part, 'CENTER')
      part.line = line
    end

    part.line:SetHeight(bar:GetHeight())
    part.line:Show()
  end
end

---@param self table<string, any>
local function skin(self)
  if self:IsForbidden() then return end
  local bar = self.Bar
  if not bar then return end

  for i = 1, #hide do
    local tex = bar[hide[i]]
    if tex then tex:SetAlpha(0) end
  end

  if not done[bar] then
    done[bar] = true

    createBorder(bar)

    local bg = bar:CreateTexture(nil, 'BACKGROUND', nil, -7)
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    bg:SetAllPoints()
  end

  bar:SetStatusBarTexture(texture)
  bar:SetStatusBarColor(1, 1, 1)
	setFont(self.Label, TITLE_SIZE)
  setFont(bar.Label, VALUE_SIZE)
  skinTicks(bar)
end

hooksecurefunc(UIWidgetTemplateStatusBarMixin, 'Setup', skin)