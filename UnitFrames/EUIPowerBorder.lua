---@type string, addonMods
local _, addonMods = ...
if not EllesmereUI then return end

local BASE_FRAME_NAME = 'EllesmereUIUnitFrames_'
local units           = {'Target', 'Focus', 'Boss1', 'Boss2', 'Boss3', 'Boss4', 'Boss5'}

local function createTextures()
  for _, unit in pairs(units) do
    local frameName = BASE_FRAME_NAME .. unit
    local Frame     = _G[frameName]

    local Line = Frame:CreateLine(nil, 'ARTWORK')
    Line:SetColorTexture(0, 0, 0)
    Line:SetStartPoint('BOTTOMLEFT', 0, 4.5)
    Line:SetEndPoint('BOTTOMRIGHT', 0, 4.5)
    Line:SetThickness(1)
  end
  addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', createTextures)
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', createTextures)