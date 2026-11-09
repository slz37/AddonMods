---@type string, addonMods
local _, addonMods = ...

local GroupMixin = {}
local DIRECTION_OFFSETS = {
	UP    = {point = 'BOTTOM', relativePoint = 'TOP',    xSign = 0,  ySign = 1},
	DOWN  = {point = 'TOP',    relativePoint = 'BOTTOM', xSign = 0,  ySign = -1},
	LEFT  = {point = 'RIGHT',  relativePoint = 'LEFT',   xSign = -1, ySign = 0},
	RIGHT = {point = 'LEFT',   relativePoint = 'RIGHT',  xSign = 1,  ySign = 0},
}
local CUSTOM_DIRECTIONS = {
	CENTEREDHORIZONTAL = true,
}

---@param a table<string, any>
---@param b table<string, any>
---@return boolean
function GroupMixin.SortFunc(a, b)
	return a.priority < b.priority
end

---@param Region table<string, any>
---@param priority number
function GroupMixin:AddMember(Region, priority)
	priority = priority or (#self.members + 1)

	-- Update priority/order if already registered
	for _, member in ipairs(self.members) do
		if member.Region == Region then
			member.priority = priority
			table.sort(self.members, self.SortFunc)
			self:Layout()
			return
		end
	end

	table.insert(self.members, {Region = Region, priority = priority})
	table.sort(self.members, self.SortFunc)

	if not self.hooked[Region] then
		self.hooked[Region] = true
		hooksecurefunc(Region, 'Show', function() self:Layout() end)
		hooksecurefunc(Region, 'Hide', function() self:Layout() end)
		hooksecurefunc(Region, 'SetShown', function() self:Layout() end)
	end

	self:Layout()
end

---@param Region table<string, any>
function GroupMixin:RemoveMember(Region)
	for i, member in ipairs(self.members) do
		if member.Region == Region then
			table.remove(self.members, i)
			self:Layout()
			return
		end
	end
end

---@param direction string
function GroupMixin:SetDirection(direction)
	self.direction = direction
	self:Layout()
end

---@param spacing number
function GroupMixin:SetSpacing(spacing)
	self.spacing = spacing
	self:Layout()
end

---@param point string
---@param relativeTo string
---@param relativePoint string
---@param x number
---@param y number
function GroupMixin:SetAnchor(point, relativeTo, relativePoint, x, y)
	self.point         = point
	self.relativeTo    = relativeTo or UIParent
	self.relativePoint = relativePoint
	self.x             = x or 0
	self.y             = y or 0
	self:Layout()
end

function GroupMixin:LayoutCenteredHorizontal()
	local shown = {}
	for _, member in ipairs(self.members) do
		if member.Region:IsShown() then table.insert(shown, member.Region) end
	end
	if #shown == 0 then return end

	local totalWidth = 0
	for _, Region in ipairs(shown) do totalWidth = totalWidth + Region:GetWidth() end
	totalWidth = totalWidth + self.spacing * (#shown - 1)

	local currentX = -totalWidth / 2
	for _, Region in ipairs(shown) do
		Region:ClearAllPoints()
		local width   = Region:GetWidth()
		local centerX = currentX + (width / 2)
		Region:SetPoint('CENTER', self.relativeTo, self.relativePoint, self.x + centerX, self.y)
		currentX = currentX + width + self.spacing
	end
end

function GroupMixin:Layout()
	if CUSTOM_DIRECTIONS[self.direction] then
		if self.direction == 'CENTEREDHORIZONTAL' then self:LayoutCenteredHorizontal() end
		return
	end

	local offset = DIRECTION_OFFSETS[self.direction] or DIRECTION_OFFSETS.DOWN
	local AnchorRegion

	for _, member in ipairs(self.members) do
		local Region = member.Region
		Region:ClearAllPoints()

		if Region:IsShown() then
			if not AnchorRegion then
				-- First visible member anchors to the group's configured point
				Region:SetPoint(self.point, self.relativeTo, self.relativePoint, self.x, self.y)
			else
				local x = self.spacing * offset.xSign
				local y = self.spacing * offset.ySign
				Region:SetPoint(offset.point, AnchorRegion, offset.relativePoint, x, y)
			end
			AnchorRegion = Region
		end
	end
end

---@param name string
---@param config table<string, any>
---@return table<string, any>
function addonMods.CreateDynamicGroup(name, config)
	config = config or {}

	local group = Mixin({
		name          = name,
		members       = {},
		hooked        = {},
		point         = config.point or 'CENTER',
		relativeTo    = config.relativeTo or UIParent,
		relativePoint = config.relativePoint or 'CENTER',
		x             = config.x or 0,
		y             = config.y or 0,
		direction     = config.direction or 'DOWN',
		spacing       = config.spacing or 4,
	}, GroupMixin)

	addonMods.dynamicGroups = addonMods.dynamicGroups or {}
	addonMods.dynamicGroups[name] = group

	return group
end

---@param name string
---@return table<string, any>
function addonMods.GetDynamicGroup(name)
	return addonMods.dynamicGroups and addonMods.dynamicGroups[name]
end

---@param name string
---@param config table<string, any>
---@return table<string, any>
function addonMods.GetOrCreateDynamicGroup(name, config)
	return (addonMods.dynamicGroups and addonMods.dynamicGroups[name]) or addonMods.CreateDynamicGroup(name, config)
end