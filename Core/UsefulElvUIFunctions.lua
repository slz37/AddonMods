---@type string, addonMods
local _, addonMods = ...

addonMods.HiddenFrame = CreateFrame('Frame', nil, UIParent)
addonMods.HiddenFrame:SetPoint('BOTTOM')
addonMods.HiddenFrame:SetSize(1,1)
addonMods.HiddenFrame:Hide()

---@param object Frame
addonMods.KillFrame = function(object)
	if not object then return end

	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(addonMods.HiddenFrame)
	else
		object.Show = object.Hide
	end

	object:Hide()
end

---@param fs FontString
---@param font string?
---@param size number?
---@param style string?
addonMods.FontTemplate = function(fs, font, size, style)
	-- grab values from profile before conversion
	if not style then style = 'OUTLINE, SLUG' end
	if not size then size = 12 end

	if style and strsub(style, 0, 6) == 'SHADOW' then
		style = strsub(style, 7) -- shadow isnt a real style
		fs:SetShadowOffset(1, -1)
		fs:SetShadowColor(0, 0, 0, style == '' and 1 or 0.6)
	else
		fs:SetShadowOffset(0, 0)
		fs:SetShadowColor(0, 0, 0, 0)
	end

	if style == 'NONE' or not style then style = '' end -- none isnt a real style

	---@cast style string
	fs:SetFont(font or addonMods.LSM:Fetch('font', 'Numen'), size, style)
end

---@param x number
---@return number
addonMods.Scale = function(x)
	local _, physicalHeight = GetPhysicalScreenSize()
	local perfect 					= 768 / physicalHeight
	local mult    					= perfect / 0.8

	local m = mult
	if m == 1 or x == 0 then
		return x
	else
		local y = m > 1 and m or -m
		return x - x % (x < 0 and y or -y)
	end
end

---@param obj Frame|FontString
---@param point string
---@param xOffset number
---@param yOffset number
addonMods.Point = function(obj, point, xOffset, yOffset)
	xOffset = addonMods.Scale(xOffset)
	yOffset = addonMods.Scale(yOffset)

	obj:SetPoint(point, xOffset, yOffset)
end