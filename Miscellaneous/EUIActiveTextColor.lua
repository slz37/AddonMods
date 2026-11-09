---@type string, addonMods
local _, addonMods = ...

local ACTIVE_COLOR = {0.52549022436142, 1, 0.46666669845581}
local ALLOWED_BAR_NAMES = {
  ['Cooldowns']         = true,
  ['Utility']           = true,
  ['Utility Overlay 1'] = true,
  ['Utility Overlay 2'] = true,
  ['Defensives']        = true,
  ['Utility (Hidden)']  = true,
  ['Starfall Stacks']   = true,
}

local watched 			 = setmetatable({}, { __mode = 'k' })
local overlayWatched = setmetatable({}, { __mode = 'k' })

---@return table<string, any>?
local function getCDMModule()
  return EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS['EllesmereUICooldownManager']
end

---@param cd table<string, any>
---@return table<string, any>?
local function findCountdownFontString(cd)
  if not (cd and cd.GetRegions) then return end
  local n = select('#', cd:GetRegions())
  for i = 1, n do
    local region = select(i, cd:GetRegions())
    if region and region.GetObjectType and region:GetObjectType() == 'FontString' then
      return region
    end
  end
end

---@param ns table<string, any>
---@param icon table<string, any>
---@return boolean?
local function isIconOnAllowedBar(ns, icon)
  local fc     = ns._ecmeFC and ns._ecmeFC[icon]
  local barKey = fc and fc.barKey
  if not barKey then return false end

  local bd = ns.barDataByKey and ns.barDataByKey[barKey]
  if not bd then return false end

  return ALLOWED_BAR_NAMES[bd.name]
end

---@param ns table<string, any>
---@param icon table<string, any>
---@return boolean?
local function isIconActive(ns, icon)
  local swipeColor = icon and icon.cooldownSwipeColor
  if swipeColor and type(swipeColor) ~= 'number' and swipeColor.GetRGBA then
    local r, g, b = swipeColor:GetRGBA()
    if type(r) == 'number' and not (issecretvalue and issecretvalue(r)) then
      if r ~= 0 or g ~= 0 or b ~= 0 then return true end
    end
  end
  if ns and icon and not icon._isPlaceholderFrame then
    local fc = ns._ecmeFC and ns._ecmeFC[icon]
    local fd = ns._hookFrameData and ns._hookFrameData[icon]
    local isHostedBuff = (fc and fc.isHostedBuff) or (fd and fd._isBuffViewerFrame)

    if isHostedBuff then return icon:IsShown() end
  end
end

---@param icon table<string, any>
---@param cd table<string, any>
---@param state table<string, any>
local function applyState(icon, cd, state)
  local ns       = getCDMModule()
  local isActive = isIconActive(ns, icon)
  if isActive == state.lastActive then return end
  state.lastActive = isActive

  local fs = state.fontString
  if not (fs and fs.IsObjectType and fs:IsObjectType('FontString')) then
    fs = findCountdownFontString(cd)
    state.fontString = fs
  end
  if not fs then return end

  if not state.colorHooked then
    state.colorHooked = true
    hooksecurefunc(fs, 'SetTextColor', function(self, r, g, b)
      if state.lastActive and (r ~= ACTIVE_COLOR[1] or g ~= ACTIVE_COLOR[2] or b ~= ACTIVE_COLOR[3]) then
        self:SetTextColor(ACTIVE_COLOR[1], ACTIVE_COLOR[2], ACTIVE_COLOR[3])
      end
    end)
  end

  if isActive then
    if not state.savedColor then
      local r, g, b = fs:GetTextColor()
      state.savedColor = { r or 1, g or 1, b or 1 }
    end
    fs:SetTextColor(ACTIVE_COLOR[1], ACTIVE_COLOR[2], ACTIVE_COLOR[3])
  else
    local saved = state.savedColor
    if saved then
      fs:SetTextColor(saved[1], saved[2], saved[3])
    end
    state.savedColor = nil
  end
end

---@param icon table<string, any>
---@param cd table<string, any>
local function hookIconCooldown(icon, cd)
  if not (icon and cd) then return end
  local state = watched[cd]
  if not state then
    state       = {lastActive = false, fontString = nil, savedColor = nil}
    watched[cd] = state
    hooksecurefunc(cd, 'SetSwipeColor', function() applyState(icon, cd, state) end)
  end
  applyState(icon, cd, state)
end

---@param ns table<string, any>
---@param icon table<string, any>
---@return table<string, any>
local function resolveCooldownWidget(ns, icon)
  local fd = ns._hookFrameData and ns._hookFrameData[icon]
  if fd and fd.cooldown then return fd.cooldown end
  return icon.Cooldown or icon._cooldown
end

local function scanBars()
  local ns = getCDMModule()
  if not (ns and ns.cdmBarIcons) then return end
  for _, icons in pairs(ns.cdmBarIcons) do
    for _, icon in ipairs(icons) do
      if isIconOnAllowedBar(ns, icon) then
        local cd = resolveCooldownWidget(ns, icon)
        if cd then hookIconCooldown(icon, cd) end
      end
    end
  end
end

---@param o table<string, any>
---@param isActive boolean?
local function overlayApplyState(o, isActive)
  local state = overlayWatched[o.cd]
  if not state then
    state = { lastActive = false, fontString = nil, savedColor = nil, colorHooked = false }
    overlayWatched[o.cd] = state
  end

  isActive = isActive and true or false
  if isActive == state.lastActive then return end
  state.lastActive = isActive

  local fs = state.fontString
  if not (fs and fs.IsObjectType and fs:IsObjectType('FontString')) then
    fs = findCountdownFontString(o.cd)
    state.fontString = fs
  end
  if not fs then return end

  if not state.colorHooked then
    state.colorHooked = true
    hooksecurefunc(fs, 'SetTextColor', function(self, r, g, b)
      if state.lastActive and (r ~= ACTIVE_COLOR[1] or g ~= ACTIVE_COLOR[2] or b ~= ACTIVE_COLOR[3]) then
        self:SetTextColor(ACTIVE_COLOR[1], ACTIVE_COLOR[2], ACTIVE_COLOR[3])
      end
    end)
  end

  if isActive then
    if not state.savedColor then
      local r, g, b = fs:GetTextColor()
      state.savedColor = { r or 1, g or 1, b or 1 }
    end
    fs:SetTextColor(ACTIVE_COLOR[1], ACTIVE_COLOR[2], ACTIVE_COLOR[3])
  else
    local saved = state.savedColor
    if saved then
      fs:SetTextColor(saved[1], saved[2], saved[3])
    end
    state.savedColor = nil
  end
end

local fakeActiveHookInstalled = false

---@return boolean
local function tryInstallFakeActiveHook()
  if fakeActiveHookInstalled then return true end
  local ns = getCDMModule()
  if not (ns and ns.ApplyActiveOverlays) then return false end

  fakeActiveHookInstalled = true
  hooksecurefunc(ns, 'ApplyActiveOverlays', function(frame, o, ss, isActive, bd)
    if not (o and o.cd) then return end
    overlayApplyState(o, isActive)
  end)
  return true
end

local hooksInstalled = false

---@return boolean
local function tryInstallHooks()
  if hooksInstalled then return true end

  local ns = getCDMModule()
  if not (ns and ns.CollectAndReanchor and ns.BuildAllCDMBars) then return false end

  hooksInstalled = true
  hooksecurefunc(ns, 'CollectAndReanchor', scanBars)
  hooksecurefunc(ns, 'BuildAllCDMBars', scanBars)
  if ns.RefreshCDMIconAppearance then hooksecurefunc(ns, 'RefreshCDMIconAppearance', scanBars) end
  scanBars()

  return true
end

local function playerEnteringWorld()
  local ok1 = tryInstallHooks()
  local ok2 = tryInstallFakeActiveHook()
  if ok1 and ok2 then
    addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)
  else
    C_Timer.After(1, function()
      tryInstallHooks()
      tryInstallFakeActiveHook()
    end)
  end
end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)