---@type string, addonMods
local _, addonMods = ...

local activeIcons = {}
local DURATION_UPDATE_INTERVAL = 0.1
local Ticker

local function onUpdate()
	for Icon in pairs(activeIcons) do
		local callback = Icon.callback
		if callback then callback(Icon, unpack(Icon.callbackArgs)) end
	end
end

local function startTicker()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(DURATION_UPDATE_INTERVAL, onUpdate)
end

local function stopTicker()
	if not Ticker then return end
	Ticker:Cancel()
	Ticker = nil
end

---@param Icon table<string, any>
local function iconFrameReset(_, Icon)
	Icon:Hide()
	Icon:ClearAllPoints()
	Icon:SetParent(UIParent)

	if Icon.Icon then
		Icon.Icon:SetDesaturated(false)
		Icon.Icon:SetTexture(134400)
	end

	local borders = Icon.borders
	if borders then
		for _, Border in pairs(borders) do Border:Hide() end
	end

	local texts = Icon.texts
	if texts then
		for _, Text in pairs(texts) do Text:Hide() end
	end

	Icon.callback      = nil
	Icon.callbackArgs  = nil
	activeIcons[Icon]  = nil
	if not next(activeIcons) then stopTicker() end
end

local iconMixin     = {}
local IconFramePool = CreateFramePool('Frame', UIParent, 'BackdropTemplate', iconFrameReset, false)

---@param config table<string, any>
---@param key string|number
---@return Frame, string|number
function iconMixin:AddBorder(config, key)
	self.borders    = self.borders or {}
	self.numBorders = self.numBorders or 0

	if key == nil then
		self.numBorders = self.numBorders + 1
		key = self.numBorders
	end

	local inset       = config.inset
	local edgeFile    = config.edgeFile
	local edgeSize    = config.edgeSize
	local borderColor = config.borderColor

	local Border = self.borders[key] or CreateFrame('Frame', nil, self, 'BackdropTemplate')
	Border:SetBackdrop({
		edgeFile = edgeFile,
		edgeSize = edgeSize,
		insets   = {left = inset, right = inset, top = inset, bottom = inset},
	})
	Border:SetBackdropColor(0, 0, 0, 0)
	Border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
	Border:ClearAllPoints()
	Border:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 0, 0)
	Border:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
	Border:SetFrameStrata('MEDIUM')

	-- Stack levels so multiple borders layer predictably instead of z-fighting.
	local levelOffset = config.levelOffset
	Border:SetFrameLevel(self:GetFrameLevel() + 2 + levelOffset)

	Border:Show()
	self.borders[key] = Border
	return Border, key
end

---@param key string|number
function iconMixin:RemoveBorder(key)
	if key == nil then
		self:RemoveAllBorders()
		return
	end
	if self.borders and self.borders[key] then
		self.borders[key]:Hide()
	end
end

function iconMixin:RemoveAllBorders()
	if not self.borders then return end
	for _, Border in pairs(self.borders) do
		Border:Hide()
	end
end

---@param key string|number
---@return table<string, any>
function iconMixin:GetBorder(key)
	return self.borders and self.borders[key]
end

---@param config table<string, any>
---@param key string|number
---@return FontString, string|number
function iconMixin:AddText(config, key)
	self.texts    = self.texts or {}
	self.numTexts = self.numTexts or 0

	if key == nil then
		self.numTexts = self.numTexts + 1
		key = self.numTexts
	end

	local parent = config.parent and self.borders[config.parent] or self

	local FontString = parent:CreateFontString(nil, 'OVERLAY')
	FontString:SetFont(config.font, config.fontSize, config.fontFlags)
	FontString:SetPoint(config.fontAnchorPoint, parent, config.fontRelativePoint, config.fontXOffset, config.fontYOffset)

	local color = config.fontColor
	FontString:SetTextColor(color.r, color.g, color.b, color.a)

	self.texts[key] = FontString
	return FontString, key
end

---@param key string|number
function iconMixin:RemoveText(key)
	if key == nil then
		self:RemoveAllTexts()
		return
	end
	if self.texts and self.texts[key] then self.texts[key]:Hide() end
end

function iconMixin:RemoveAllTexts()
	if not self.texts then return end
	for _, Text in pairs(self.texts) do Text:Hide() end
end

---@param key string|number
---@return FontString
function iconMixin:GetText(key)
	return self.texts and self.texts[key]
end

---@param callback fun(Icon: table<string, any>, ...: any)
---@vararg ...
function iconMixin:AddCallback(callback, ...)
	self.callback      = callback
	self.callbackArgs  = {...}
	activeIcons[self]  = true
	startTicker()
end

function iconMixin:RemoveCallback()
	self.callback      = nil
	self.callbackArgs  = nil
	activeIcons[self]  = nil
	if not next(activeIcons) then stopTicker() end
end

function iconMixin:Release()
	IconFramePool:Release(self)
end

function iconMixin:CreateSwipe()
	local Cooldown = CreateFrame('Cooldown', nil, self, 'CooldownFrameTemplate')
	Cooldown:SetAllPoints(self)
	Cooldown:SetDrawEdge(false)
	Cooldown:SetDrawBling(false)
	Cooldown:SetSwipeColor(0, 0, 0, 0.66)
	Cooldown:SetHideCountdownNumbers(true)
	Cooldown:SetReverse(true)
	self.Cooldown = Cooldown
end

---@param config table<string, any>
---@return table<string, any>
function addonMods.NewIcon(config)
	local Icon = IconFramePool:Acquire()
	Mixin(Icon, iconMixin)

	local w, h = config.w, config.h
	PixelUtil.SetSize(Icon, w, h)

	-- If the Icon is part of a dynamic group, let the group handle positioning
	if not config.inGroup then
		Icon:ClearAllPoints()
		Icon:SetPoint(config.anchorPoint, config.relativeFrame, config.relativePoint, config.xOffset, config.yOffset)
	end

	if not Icon.Icon then
		Icon.Icon = Icon:CreateTexture(nil, 'ARTWORK')
		Icon.Icon:SetAllPoints(Icon)
	end
	Icon.Icon:SetDesaturated(config.desaturated)
	Icon.Icon:SetTexture(config.texture)

	addonMods.WA_UpdateTexCoords(
		Icon.Icon,
		w,
		h,
		config.zoom,
		config.keepAspectRatio,
		config.scaleX,
		config.scaleY,
		config.texXOffset,
		config.texYOffset
	)

	local borders = config.borders
	if borders then
		for key, borderConfig in pairs(borders) do Icon:AddBorder(borderConfig, key) end
	end

	local texts = config.texts
	if texts then
		for key, textConfig in pairs(texts) do Icon:AddText(textConfig, key) end
	end

	if config.showSwipe then Icon:CreateSwipe() end

	return Icon
end