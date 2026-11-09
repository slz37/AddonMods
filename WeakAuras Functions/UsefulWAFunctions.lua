---@type string, addonMods
local _, addonMods = ...

---@param texWidth number
---@param aspectRatio number
---@param xOffset number
---@param yOffset number
---@return number, number, number, number, number, number, number, number
addonMods.WA_GetTexCoord = function(texWidth, aspectRatio, xOffset, yOffset)
	local currentCoord = {}
	currentCoord[1], currentCoord[2], currentCoord[3], currentCoord[4], currentCoord[5], currentCoord[6], currentCoord[7], currentCoord[8] = 0, 0, 0, 1, 1, 0, 1, 1

	local xRatio = aspectRatio < 1 and aspectRatio or 1
	local yRatio = aspectRatio > 1 and 1 / aspectRatio or 1
	for i, coord in ipairs(currentCoord) do
		if(i % 2 == 1) then
			currentCoord[i] = (coord - 0.5) * texWidth * xRatio + 0.5 - xOffset
		else
			currentCoord[i] = (coord - 0.5) * texWidth * yRatio + 0.5 - yOffset
		end
	end

	return unpack(currentCoord)
end

---@param icon Frame|Texture|FontString
---@param w number
---@param h number
---@param zoom number
---@param keepAspectRatio boolean
---@param scaleX number
---@param scaleY number
---@param texXOffset number
---@param texYOffset number
addonMods.WA_UpdateTexCoords = function(icon, w, h, zoom, keepAspectRatio, scaleX, scaleY, texXOffset, texYOffset)
	local texWidth = 1 - 0.5 * zoom
	local aspectRatio
	if not keepAspectRatio then
		aspectRatio = 1
	else
		local scaledW = w * math.abs(scaleX or 1)
		local scaledH = h * math.abs(scaleY or 1)
		aspectRatio = (scaledW == 0 or scaledH == 0) and 1 or (scaledW / scaledH)
	end

	local ulx, uly, llx, lly, urx, ury, lrx, lry = addonMods.WA_GetTexCoord(texWidth, aspectRatio, texXOffset, texYOffset)
	icon:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

---@param input string
---@param size number
---@return string
addonMods.WA_Utf8Sub = function(input, size)
	local output = ''
	input = tostring(input)
	if type(input) ~= 'string' then return output end

	local i = 1
	while size > 0 do
		local byte = input:byte(i)
		if not byte then return output end
		if byte < 128 then
			-- ASCII byte
			output = output .. input:sub(i, i)
			size = size - 1
		elseif byte < 192 then
			-- Continuation bytes
			output = output .. input:sub(i, i)
		elseif byte < 244 then
			-- Start bytes
			output = output .. input:sub(i, i)
			size = size - 1
		end
		i = i + 1
	end

	-- Add any bytes that are part of the sequence
	while true do
		local byte = input:byte(i)
		if byte and byte >= 128 and byte < 192 then
			output = output .. input:sub(i, i)
		else
			break
		end
		i = i + 1
	end

	return output
end

---@param unit string
---@param maxlen number?
---@return string
addonMods.WA_ClassColorName = function(unit, maxlen)
	if not unit or not UnitExists(unit) then return '' end

	local name = UnitName(unit)
	if maxlen and maxlen > 0 then name = addonMods.WA_Utf8Sub(name, maxlen) end

	local _, class = UnitClass(unit)
	if not class then
		return name
	else
		local classData = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
		local coloredName = ('|c%s%s|r'):format(classData.colorStr, name)
		return coloredName
	end
end