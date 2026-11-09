---@type string, addonMods
local _, addonMods = ...
local animationManager = addonMods.animationManager

-- Flash Functions
---@param progress number
---@param start number
---@param delta number
---@return number
local function defaultFlashFunc(progress, start, delta)
	local angle = (progress * 2 * math.pi) - (math.pi / 2)
	return start + (((math.sin(angle) + 1)/2) * delta)
end

-- Flash Class
local flash = {}
flash.__index = flash

---@param Region Region
---@param flashFunc fun(...)
---@param duration number
---@param delta number
---@return table<string, any>
function flash:New(Region, flashFunc, duration, delta)
	local instance 		 = setmetatable({}, flash)
	instance.Region    = Region
	instance.elapsed   = 0
	instance.flashFunc = flashFunc or defaultFlashFunc

	instance.startAlpha = Region:GetAlpha()
	instance.duration   = duration or 0.5
	instance.delta      = delta or -0.5

	return instance
end

---@param elapsed number
---@return boolean
function flash:Update(elapsed)
	if not self.Region then return false end

	self.elapsed	 = self.elapsed + elapsed
	local progress = self.elapsed / self.duration

	if progress >= 1 then
		self.elapsed = self.elapsed - math.floor(progress)
		progress = self.elapsed / self.duration
	end

	local alpha = self.flashFunc(progress, self.startAlpha, self.delta)
	self.Region:SetAlpha(alpha)

	return true
end

function flash:Stop()
	if not self.Region then return end
	self.Region:SetAlpha(self.startAlpha)
end

-- External API
addonMods.WAFlash = flash

---@param FontString FontString
---@param flashFunc fun(...)?
---@param duration number?
---@param delta number?
---@return table<string, any>
function addonMods.CreateFlash(FontString, flashFunc, duration, delta)
	local instance = flash:New(FontString, flashFunc, duration, delta)
	return instance
end

---@param instance table<string, any>
function addonMods.AddFlash(instance)
	animationManager:Add(instance)
end

---@param instance table<string, any>
function addonMods.RemoveFlash(instance)
	animationManager:Remove(instance)
end
