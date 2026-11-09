---@type string, addonMods
local _, addonMods = ...

local LSM             = addonMods.LSM
local backdropTexture = LSM:Fetch('background', 'Blizzard Rock')

local INV_TYPE_TO_SLOT = {
    INVTYPE_HEAD           = {1},
    INVTYPE_NECK           = {2},
    INVTYPE_SHOULDER       = {3},
    INVTYPE_CHEST          = {5},
    INVTYPE_ROBE           = {5},
    INVTYPE_WAIST          = {6},
    INVTYPE_LEGS           = {7},
    INVTYPE_FEET           = {8},
    INVTYPE_WRIST          = {9},
    INVTYPE_HAND           = {10},
    INVTYPE_FINGER         = {11, 12},
    INVTYPE_TRINKET        = {13, 14},
    INVTYPE_CLOAK          = {15},
    INVTYPE_WEAPON         = {16, 17},
    INVTYPE_SHIELD         = {17},
    INVTYPE_2HWEAPON       = {16, 17},
    INVTYPE_WEAPONMAINHAND = {16},
    INVTYPE_WEAPONOFFHAND  = {16},
    INVTYPE_HOLDABLE       = {17},
    INVTYPE_RANGED         = {16},
    INVTYPE_RANGEDRIGHT    = {16},
    INVTYPE_THROWN         = {16},
}
local SHOULD_COMBINE_STATS = {
  INVTYPE_2HWEAPON = true,
}
local VALID_STATS = {
  ['damage per second'] = true,
  ['Armor']             = true,
  ['Strength']          = true,
  ['Intellect']         = true,
  ['Agility']           = true,
  ['Stamina']           = true,
  ['Haste']             = true,
  ['Mastery']           = true,
  ['Critical Strike']   = true,
  ['Versatility']  		  = true,
	['Leech'] 						= true,
	['Avoidance'] 				= true,
	['Speed'] 						= true,
}

local STAT_ORDER = {
  'damage per second', 'Armor', 'Strength', 'Agility', 'Intellect', 'Stamina',
  'Critical Strike', 'Haste', 'Mastery', 'Versatility', 'Leech', 'Avoidance', 'Speed',
  'EMPTY_SOCKET_META', 'EMPTY_SOCKET_RED', 'EMPTY_SOCKET_YELLOW', 'EMPTY_SOCKET_BLUE',
  'EMPTY_SOCKET_NO_COLOR', 'EMPTY_SOCKET_COGWHEEL',
}

local EMPTY_GEM_ICONS = {
  ['EMPTY_SOCKET_META']     = '|T' .. 'interface/itemsocketingframe/ui-emptysocket-meta.blp' .. ':12|t',
  ['EMPTY_SOCKET_RED']      = '|T' .. 'interface/itemsocketingframe/ui-emptysocket-red.blp' .. ':12|t',
  ['EMPTY_SOCKET_YELLOW']   = '|T' .. 'interface/itemsocketingframe/ui-emptysocket-yellow.blp '.. ':12|t',
  ['EMPTY_SOCKET_BLUE']     = '|T' .. 'interface/itemsocketingframe/ui-emptysocket-blue.blp' .. ':12|t',
  ['EMPTY_SOCKET_NO_COLOR'] = '|T' .. 'interface/itemsocketingframe/ui-emptysocket-prismatic.blp' .. ':12|t',
  ['EMPTY_SOCKET_COGWHEEL'] = '|T' .. 'interface/itemsocketingframe/ui-emptysocket-cogwheel.blp' .. ':12|t',
}

local EQUIPPED_HEADER_TEXT = 'Currently Equipped'
local REPLACE_HEADER_TEXT  = '\nIf you replace this item, the following stat changes will occur:'

---@param i number
---@return GameTooltipTemplate
local function createTooltip(i)
  local Tooltip = CreateFrame('GameTooltip', 'TooltipGearCompare' .. i, nil, 'GameTooltipTemplate')
	local BG      = CreateFrame('Frame', 'TooltipGearCompareBG' .. i, Tooltip)
  addonMods.KillFrame(Tooltip.NineSlice) -- GameTooltipTemplate is ugly

	-- Avoid BackdropTemplate tainting GetWidth() in SetupTextureCoordinates()
	local inset = 4
  local Tex = BG:CreateTexture(nil, 'BACKGROUND')
  Tex:SetTexture(backdropTexture)
  Tex:SetVertexColor(19 / 255, 19 / 255, 19 / 255, 0.7)
  Tex:SetPoint('TOPLEFT', BG, 'TOPLEFT', inset, -inset)
  Tex:SetPoint('BOTTOMRIGHT', BG, 'BOTTOMRIGHT', -inset, inset)
	BG:SetAllPoints()

  -- This is necessary to have the background above other UI elements while still behind the tooltip text
  Tooltip:HookScript('OnShow', function(self) BG:SetFrameLevel(self:GetFrameLevel()) end)
  Tooltip.BG = BG

  return Tooltip
end

GameTooltip_ShowCompareItem = function() end -- This is what causes lag from Blizzard's end
local TooltipCompare1 = createTooltip(1)
local TooltipCompare2 = createTooltip(2)

---@param number number
---@return string
local function breakUpLargeNumbers(number)
  number = math.floor(number * 10) / 10
  local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

  int = int:reverse():gsub('(%d%d%d)', '%1,')
  return minus .. int:reverse():gsub('^,', '') .. fraction
end

---@param destination table<string, any>
---@param source table<string, any>
local function mergeAndSumTables(destination, source)
  for k, v in pairs(source) do
    destination[k] = (destination[k] or 0) + v
  end
end

---@param Tooltip GameTooltipTemplate
local function clearTooltipTextures(Tooltip)
  -- Gem icons can persist across tooltips if not removed
  -- I had concerns about textures accumulating over time, but it seems FontStrings using '|T' properly pool textures
  for _, Region in ipairs({Tooltip:GetRegions()}) do
    if Region:IsObjectType('Texture') then
      ---@cast Region Texture
      Region:ClearAllPoints()
      Region:SetTexture(nil)
      Region:Hide()
    end
  end
end

---@param CompareTooltip GameTooltipTemplate
---@param compareLines table<string, any>
---@param compareStats table<string, number>
---@param mouseoverStats table<string, number>
local function formatTooltip(CompareTooltip, compareLines, compareStats, mouseoverStats)
  -- Reconstruct tooltip with stat comparisons added
	if next(compareLines) then
		CompareTooltip:ClearLines()
		clearTooltipTextures(CompareTooltip)
		CompareTooltip:AddLine(EQUIPPED_HEADER_TEXT, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
		for _, line in ipairs(compareLines) do
			if line.right and line.right ~= '' then
				CompareTooltip:AddDoubleLine(line.left, line.right, line.lr, line.lg, line.lb, line.rr, line.rg, line.rb)
			else
				local icon = line.icon and '|T' .. line.icon .. ':16|t  ' or ''
				CompareTooltip:AddLine(icon .. line.left, line.lr, line.lg, line.lb, true)
			end
		end

		local addedReplaceHeader = false
		for _, stat in ipairs(STAT_ORDER) do
			local before = compareStats[stat] or 0
			local after  = mouseoverStats[stat] or 0
			local delta  = after - before

			if delta ~= 0 then
				local sign  = delta > 0 and '+' or ''
				local color = delta > 0 and GREEN_FONT_COLOR:GenerateHexColor() or RED_FONT_COLOR:GenerateHexColor()

				-- Wait to add header until we're sure there's any changes in stats
				if not addedReplaceHeader then
					CompareTooltip:AddLine(REPLACE_HEADER_TEXT, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
					addedReplaceHeader = true
				end

				-- Gems require special formatting
				if stat:find('SOCKET') then
					local icon = EMPTY_GEM_ICONS[stat]
					stat = icon .. ' ' .. stat:gsub('^EMPTY_SOCKET_(.+)$', function(s) return s:sub(1,1) .. s:sub(2):lower() .. ' Socket' end)
				end
				CompareTooltip:AddLine(string.format('|c' .. color .. '%s%s|r %s', sign, breakUpLargeNumbers(delta), stat), 1, 1, 1)
			end
		end
	end

  CompareTooltip:Show()
  CompareTooltip:SetScale(0.65) -- Show() resizes the tooltip, so scale must be called afterwards
end

---@param statTable table<string, number>
---@param itemLink string
local function storeGemStats(statTable, itemLink)
  -- Count gem slots, regardless of whether they are empty, for comparison
  local stats = C_Item.GetItemStats(itemLink)
  for stat, amount in pairs(stats) do
    if stat:find('SOCKET') then statTable[stat] = (statTable[stat] or 0) + amount end
  end
end

---@param r number
---@param g number
---@param b number
---@return boolean
local function isActiveState(r, g, b)
  -- Active stat lines are white (1,1,1). Inactive/greyed lines use a dim gray.
  -- Treat any sufficiently dim, roughly-neutral color as "inactive".
  if not r then return false end
  return not (r < 0.9 and math.abs(r - g) < 0.05 and math.abs(g - b) < 0.05)
end

---@param text string
---@param statTable table<string, number>
---@param duplicateTable table<string, any>
---@param lr number
---@param lg number
---@param lb number
local function storeStats(text, statTable, duplicateTable, lr, lg, lb)
  local _, amount, stat = text:match('^(%+?%(?)([%d,.]+) ([%a%s]+)')
  stat = string.trim(stat or '')

  if VALID_STATS[stat] and not duplicateTable[stat] and isActiveState(lr, lg, lb) then
    amount = amount:gsub(',', '')
    amount = tonumber(amount)
    local reforgedFrom = text:match('Reforged from ([%a%s]+)')

    -- Reattribute reforged stats to the original stat
    if reforgedFrom then
      statTable[reforgedFrom] = (statTable[reforgedFrom] or 0) + tonumber(amount)
    else
      duplicateTable[stat] = true
      statTable[stat]      = (statTable[stat] or 0) + tonumber(amount)
    end
  end
end

---@param Tooltip GameTooltipTemplate
---@return Texture[]
local function buildLineIconMap(Tooltip)
  -- Builds a map that gets actual gem textures in the tooltip and only runs once per tooltip, so it shouldn't be too expensive
  local icons = {}
  for _, Region in ipairs({Tooltip:GetRegions()}) do
    if Region:IsObjectType('Texture') then
      ---@cast Region Texture
      for p = 1, Region:GetNumPoints() do
        local _, relativeTo = Region:GetPoint(p)

        if relativeTo then
          local line = relativeTo:GetName() and relativeTo:GetName():match('TextLeft(%d+)$')
          if line then icons[tonumber(line)] = Region:GetTexture() end
        end
      end
    end
  end

  return icons
end

---@param Tooltip GameTooltipTemplate
---@return fun(): number?, string?, number?, number?, number?, string?, number?, number?, number?
local function parseTooltip(Tooltip)
  local name     = Tooltip:GetName()
  local numLines = Tooltip:NumLines()
  local i = 0
  return function()
    i = i + 1
    if i > numLines then return end

    local left  = _G[name .. 'TextLeft' .. i]
    local right = _G[name .. 'TextRight' .. i]

    local leftText, lr, lg, lb
    if left then
      leftText   = left:GetText()
      lr, lg, lb = left:GetTextColor()
    end

    local rightText, rr, rg, rb
    if right then
      rightText  = right:GetText()
      rr, rg, rb = right:GetTextColor()
    end

    -- 1st return is i to avoid for loops breaking early due to empty lines
    return i, leftText, lr, lg, lb, rightText, rr, rg, rb
  end
end

---@param MouseoverTooltip GameTooltipTemplate
---@param mouseoverLink string
---@return table<string, number>
local function parseMouseoverStats(MouseoverTooltip, mouseoverLink)
  local mouseoverStats, duplicateTable = {}, {}
  for _, leftText, lr, lg, lb in parseTooltip(MouseoverTooltip) do
    storeStats(leftText, mouseoverStats, duplicateTable, lr, lg, lb)
  end
  storeGemStats(mouseoverStats, mouseoverLink)

  return mouseoverStats
end

---@param CompareTooltip GameTooltipTemplate
---@param compareLink string
---@param shouldRecordLines boolean
---@return table<string, any>, table<string, number>
local function parseCompareStats(CompareTooltip, compareLink, shouldRecordLines)
  -- The equipped tooltip needs to be completely rebuilt to add all of the lines
  local compareLines, compareStats, duplicateTable = {}, {}, {}
  local compareIconMap = buildLineIconMap(CompareTooltip)

  for i, leftText, lr, lg, lb, rightText, rr, rg, rb in parseTooltip(CompareTooltip) do
    storeStats(leftText, compareStats, duplicateTable, lr, lg, lb)
    if shouldRecordLines then
      table.insert(compareLines, {
        left  = leftText,  lr = lr, lg = lg, lb = lb,
        right = rightText, rr = rr, rg = rg, rb = rb,
        icon  = compareIconMap[i],
      })
    end
  end
  storeGemStats(compareStats, compareLink)

  return compareLines, compareStats
end

---@param AnchorTip GameTooltipTemplate
---@param CompareTooltip GameTooltipTemplate
---@param slot number
local function updateTooltipAnchors(AnchorTip, CompareTooltip, slot)
  -- When tooltip is on right-side of the screen, anchor to the left instead of the right
  local x                = GameTooltip:GetRect()
  local horizontalCenter = GetScreenWidth() / 2
	if not x or not horizontalCenter then return end

  CompareTooltip:ClearAllPoints()
  CompareTooltip:SetOwner(AnchorTip, 'ANCHOR_NONE')
  CompareTooltip:SetInventoryItem('player', slot)

  if x >= horizontalCenter then
    CompareTooltip:SetPoint('TOPRIGHT', AnchorTip, 'TOPLEFT', 0, 0)
  else
    CompareTooltip:SetPoint('TOPLEFT', AnchorTip, 'TOPRIGHT', 0, 0)
  end
end

---@param tip GameTooltipTemplate
GameTooltip:HookScript('OnShow', function(tip)
	-- Delay for AutoTooltipAnchor.lua to finish repositioning
	RunNextFrame(function()
		if tip:IsForbidden() or issecretvalue(tip:GetWidth()) then return end

		local _, mouseoverLink = tip:GetItem()
		if not mouseoverLink then return end

		local _,_,_,_,_,_,_,_, itemEquipLoc = C_Item.GetItemInfo(mouseoverLink)
		if not INV_TYPE_TO_SLOT[itemEquipLoc] then return end

		local AnchorTip      = GameTooltip
		local currentTooltip = TooltipCompare1
		local slotsToCompare = INV_TYPE_TO_SLOT[itemEquipLoc]

		if SHOULD_COMBINE_STATS[itemEquipLoc] then
			local mouseoverStats = parseMouseoverStats(tip, mouseoverLink)

			local compareLines, compareStats = {}, {}
			for _, slot in ipairs(slotsToCompare) do
				local equippedLink = GetInventoryItemLink('player', slot)
				if equippedLink then
					updateTooltipAnchors(AnchorTip, currentTooltip, slot)

					local currentLines, currentStats = parseCompareStats(currentTooltip, equippedLink, currentTooltip == TooltipCompare1)
					tAppendAll(compareLines, currentLines)
					mergeAndSumTables(compareStats, currentStats)

					AnchorTip      = TooltipCompare1
					currentTooltip = TooltipCompare2
				end
			end

			-- Need to wait until after for loop before formatting so that combined stats is finished
			formatTooltip(TooltipCompare1, compareLines, compareStats, mouseoverStats)
			formatTooltip(TooltipCompare2, {}, {}, {})
		else
			local mouseoverStats = parseMouseoverStats(tip, mouseoverLink)

			for _, slot in ipairs(slotsToCompare) do
				local equippedLink = GetInventoryItemLink('player', slot)
				if equippedLink then
					updateTooltipAnchors(AnchorTip, currentTooltip, slot)

					local compareLines, compareStats = parseCompareStats(currentTooltip, equippedLink, true)
					formatTooltip(currentTooltip, compareLines, compareStats, mouseoverStats)

					AnchorTip      = TooltipCompare1
					currentTooltip = TooltipCompare2
				end
			end
		end
	end)
end)

GameTooltip:HookScript('OnHide', function()
  TooltipCompare1:Hide()
  TooltipCompare2:Hide()
end)

-- This is a much simpler way to do it, but repeatedly mousing over items quickly will cause the same lag as before
--[[local function test(self, anchorFrame)
  if not IsModifiedClick("COMPAREITEMS") and not GetCVarBool("alwaysCompareItems") then return end
	local tooltip, shoppingTooltip1, shoppingTooltip2;
	tooltip, anchorFrame, shoppingTooltip1, shoppingTooltip2 = GameTooltip_InitializeComparisonTooltips(self, anchorFrame);

	local primaryItemShown, secondaryItemShown = shoppingTooltip1:SetCompareItem(shoppingTooltip2, tooltip);

	GameTooltip_AnchorComparisonTooltips(tooltip, anchorFrame, shoppingTooltip1, shoppingTooltip2, primaryItemShown, secondaryItemShown);

	-- We have to call this again because :SetOwner clears the tooltip.
	shoppingTooltip1:SetCompareItem(shoppingTooltip2, tooltip);
	shoppingTooltip1:Show();
end
GameTooltip:HookScript('OnShow', function(self, anchorFrame)
  test(self, anchorFrame)
end)
addonMods.RegisterEventHandler('MODIFIER_STATE_CHANGED', function() print('b') test() end)]]