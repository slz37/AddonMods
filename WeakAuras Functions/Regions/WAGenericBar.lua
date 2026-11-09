---@type string, addonMods
local _, addonMods = ...

local activeBars   = {}
local tickerActive = false
local TickerFrame  = CreateFrame('FRAME')

local function onUpdate()
	for Bar in pairs(activeBars) do
		local callback = Bar.callback
		if callback then callback(Bar, unpack(Bar.callbackArgs)) end
	end
end

local function startTicker()
	if tickerActive then return end
	tickerActive = true
	TickerFrame:SetScript('OnUpdate', onUpdate)
end

local function stopTicker()
	if not tickerActive then return end
	tickerActive = false
	TickerFrame:SetScript('OnUpdate', nil)
end

---@param Bar table<string, any>
local function barFrameReset(_, Bar)
	Bar:Hide()
	Bar:ClearAllPoints()
	Bar:SetParent(UIParent)

	if Bar.Icon then Bar.Icon:Hide() end
	if Bar.Spark then Bar.Spark:Hide() end

	local borders = Bar.borders
	if borders then
		for _, Border in pairs(borders) do Border:Hide() end
	end

	local texts = Bar.texts
	if texts then
		for _, Text in pairs(texts) do Text:Hide() end
	end

	local ticks = Bar.ticks
	if ticks then
		for _, Tick in pairs(ticks) do Tick:Hide() end
	end

	if Bar.smoothProgress then
		for func in pairs(SmoothStatusBarMixin) do
			Bar[func] = nil
		end
	end

	Bar.callback     = nil
	Bar.callbackArgs = nil
	activeBars[Bar]  = nil
	if not next(activeBars) then stopTicker() end
end

local BarMixin     = {}
local BarFramePool = CreateFramePool('StatusBar', UIParent, nil, barFrameReset, false)

---@param config table<string, any>
---@param key string|number
---@return Frame, string|number
function BarMixin:AddBorder(config, key)
	self.borders    = self.borders or {}
	self.numBorders = self.numBorders or 0

	if key == nil then
		self.numBorders = self.numBorders + 1
		key = self.numBorders
	end

	local inset       = config.inset
	local edgeSize    = config.edgeSize
	local borderColor = config.borderColor

	local Border = self.borders[key]
	if not Border then
		Border = CreateFrame('Frame', nil, self)
		Border.edges = {}
		for _, side in ipairs({'top', 'bottom', 'left', 'right'}) do
			Border.edges[side] = Border:CreateTexture(nil, 'OVERLAY')
		end
		self.borders[key] = Border
	end
	Border:ClearAllPoints()

	if config.parent == 'icon' and self.Icon then
		Border:SetPoint('BOTTOMLEFT', self.Icon, 'BOTTOMLEFT', 0, 0)
		Border:SetPoint('TOPRIGHT', self.Icon, 'TOPRIGHT', 0, 0)
	else
		local leftAnchor = (self.Icon and self.Icon:IsShown()) and self.Icon or self
    Border:SetPoint('BOTTOMLEFT', leftAnchor, 'BOTTOMLEFT', 0, 0)
    Border:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
	end
	Border:SetFrameStrata('MEDIUM')
	
	local edges = Border.edges
	for _, tex in pairs(edges) do tex:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a) end

	edges.top:ClearAllPoints()
	edges.top:SetPoint('TOPLEFT', Border, 'TOPLEFT', inset, -inset)
	edges.top:SetPoint('TOPRIGHT', Border, 'TOPRIGHT', -inset, -inset)
	edges.top:SetHeight(edgeSize)

	edges.bottom:ClearAllPoints()
	edges.bottom:SetPoint('BOTTOMLEFT', Border, 'BOTTOMLEFT', inset, inset)
	edges.bottom:SetPoint('BOTTOMRIGHT', Border, 'BOTTOMRIGHT', -inset, inset)
	edges.bottom:SetHeight(edgeSize)

	edges.left:ClearAllPoints()
	edges.left:SetPoint('TOPLEFT', Border, 'TOPLEFT', inset, -inset)
	edges.left:SetPoint('BOTTOMLEFT', Border, 'BOTTOMLEFT', inset, inset)
	edges.left:SetWidth(edgeSize)

	edges.right:ClearAllPoints()
	edges.right:SetPoint('TOPRIGHT', Border, 'TOPRIGHT', -inset, -inset)
	edges.right:SetPoint('BOTTOMRIGHT', Border, 'BOTTOMRIGHT', -inset, inset)
	edges.right:SetWidth(edgeSize)

	-- Stack levels so multiple borders layer predictably instead of z-fighting
	local levelOffset = config.levelOffset
	Border:SetFrameLevel(self:GetFrameLevel() + 2 + levelOffset)

	Border:Show()
	self.borders[key] = Border
	return Border, key
end

---@param key string|number
function BarMixin:RemoveBorder(key)
	if key == nil then
		self:RemoveAllBorders()
		return
	end
	if self.borders and self.borders[key] then self.borders[key]:Hide() end
end

function BarMixin:RemoveAllBorders()
	if not self.borders then return end
	for _, Border in pairs(self.borders) do Border:Hide() end
end

---@param key string|number
---@return Frame
function BarMixin:GetBorder(key)
	return self.borders and self.borders[key]
end

---@param config table<string, any>
---@param key string|number
---@return FontString, string|number
function BarMixin:AddText(config, key)
	self.texts    = self.texts or {}
	self.numTexts = self.numTexts or 0

	if key == nil then
		self.numTexts = self.numTexts + 1
		key           = self.numTexts
	end

	local parent = self.borders[config.parent]

	local FontString = parent:CreateFontString(nil, 'OVERLAY')
	FontString:SetFont(config.font, config.fontSize, config.fontFlags)
	FontString:SetPoint(config.fontAnchorPoint, self, config.fontRelativePoint, config.fontXOffset, config.fontYOffset)

	local color = config.fontColor
	FontString:SetTextColor(color.r, color.g, color.b, color.a)

	self.texts[key] = FontString
	return FontString, key
end

---@param key string|number
function BarMixin:RemoveText(key)
	if key == nil then
		self:RemoveAllTexts()
		return
	end
	if self.texts and self.texts[key] then self.texts[key]:Hide() end
end

function BarMixin:RemoveAllTexts()
	if not self.texts then return end
	for _, Text in pairs(self.texts) do Text:Hide() end
end

---@param key string|number
---@return FontString
function BarMixin:GetText(key)
	return self.texts and self.texts[key]
end

---@param callback fun(icon: table<string, any>, ...: any)
---@vararg ...
function BarMixin:AddCallback(callback, ...)
	self.callback     = callback
	self.callbackArgs = {...}
	activeBars[self]  = true
	startTicker()
end

function BarMixin:RemoveCallback()
	self.callback     = nil
	self.callbackArgs = nil
	activeBars[self]  = nil
	if not next(activeBars) then stopTicker() end
end

---@param config table<string, any>
---@param key string|number
function BarMixin:AddTicks(config, key)
	local min, max = self:GetMinMaxValues()
	local range    = max - min
	local color 	 = config.color or {}

	if not self.ticks then self.ticks = {} end

	for _, pos in ipairs(config.positions) do
		local Tick = self:CreateTexture(nil, 'OVERLAY')
		Tick:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
		Tick:SetWidth(config.w)
		Tick:SetPoint('TOP', self, 'TOP', 0, 0)
		Tick:SetPoint('BOTTOM', self, 'BOTTOM', 0, 0)

		-- Calculate relative offset along the Bar's width based on value
		local relativeOffset = (pos - min) / range
		local xOffset = relativeOffset * self:GetWidth()

		Tick:ClearAllPoints()
		Tick:SetPoint('TOPLEFT', self, 'TOPLEFT', xOffset, 0)
		Tick:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', xOffset, 0)
		Tick:SetWidth(config.w)

		table.insert(self.ticks, Tick)
	end
end

function BarMixin:Release()
	BarFramePool:Release(self)
end

---@param config table<string, any>
function addonMods.NewBar(config)
	local Bar = BarFramePool:Acquire()
	Mixin(Bar, BarMixin)

	local w, h 		= config.w, config.h
	local texture = config.texture
	local icon    = config.icon

	Bar:ClearAllPoints()
	if icon then
		-- If using an icon, the icon will take some of the width
		Bar:SetSize(w - icon.w, h)

		local offset = (icon.anchorPoint == 'RIGHT' and icon.w or -icon.w) / 2
		Bar:SetPoint(config.anchorPoint, config.relativeFrame, config.relativePoint, config.xOffset + offset, config.yOffset)
	else
		Bar:SetSize(w, h)
		Bar:SetPoint(config.anchorPoint, config.relativeFrame, config.relativePoint, config.xOffset, config.yOffset)
	end
	Bar:SetStatusBarTexture(texture)
	Bar:SetStatusBarColor(unpack(config.color))
	Bar:SetMinMaxValues(config.min, config.max)
	
	if not Bar.bg then
		Bar.bg = Bar:CreateTexture(nil, 'BACKGROUND')
		Bar.bg:SetAllPoints(Bar)
	end
	Bar.bg:SetTexture(texture)
	Bar.bg:SetVertexColor(unpack(config.bgColor))

	if icon then
		Bar.Icon = Bar.Icon or Bar:CreateTexture(nil, 'ARTWORK')
		Bar.Icon:ClearAllPoints()
		Bar.Icon:Show()
		Bar.Icon:SetSize(icon.w, icon.h)
		Bar.Icon:SetDesaturated(icon.desaturated)
		Bar.Icon:SetTexture(icon.texture)
		Bar.Icon:SetPoint(icon.anchorPoint, icon.relativeFrame or Bar, icon.relativePoint, icon.xOffset, icon.yOffset)
		addonMods.WA_UpdateTexCoords(
			Bar.Icon,
			icon.w,
			icon.h,
			icon.zoom,
			icon.keepAspectRatio,
			icon.scaleX,
			icon.scaleY,
			icon.texXOffset,
			icon.texYOffset
		)
	end

	local borders = config.borders
	if borders then
		for key, borderConfig in pairs(borders) do Bar:AddBorder(borderConfig, key) end
	end

	local texts = config.texts
	if texts then
		for key, textConfig in pairs(texts) do Bar:AddText(textConfig, key) end
	end

	local ticks = config.ticks
	if ticks then
		for key, tickConfig in pairs(ticks) do Bar:AddTicks(tickConfig, key) end
	end

	local spark = config.spark
	if spark then
		local color = spark.color
		Bar.Spark = Bar.Spark or Bar:CreateTexture(nil, 'ARTWORK')
		Bar.Spark:Show()
		Bar.Spark:ClearAllPoints()
		Bar.Spark:SetSize(spark.w, Bar:GetHeight())
		Bar.Spark:SetTexture(spark.texture)
		Bar.Spark:SetVertexColor(color.r, color.g, color.b, color.a)
		Bar.Spark:SetPoint('CENTER', Bar, 'CENTER', 0, 0)
		Bar.Spark:SetBlendMode(spark.blendMode)
	end

	if config.smoothProgress then
		Bar.smoothProgress = true
		Mixin(Bar, SmoothStatusBarMixin)
	end

	return Bar
end