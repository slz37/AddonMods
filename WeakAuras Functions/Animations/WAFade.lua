---@type string, addonMods
local _, addonMods = ...
local animationManager = addonMods.animationManager

-- Fade Class
local fade = {}
fade.__index = fade

---@param Region table<string, any>
---@param startAlpha number
---@param targetAlpha number
---@param duration number
---@return table<string, any>
function fade:New(Region, startAlpha, targetAlpha, duration)
	local instance = setmetatable({}, fade)

	instance.Region      = Region
	instance.startAlpha  = startAlpha
	instance.targetAlpha = targetAlpha
	instance.duration    = duration or 0.25
	instance.elapsed     = 0

	return instance
end

---@param elapsed number
---@return boolean
function fade:Update(elapsed)
	if not self.Region then return false end

	self.elapsed = self.elapsed + elapsed
	local progress = self.elapsed / self.duration

	if progress >= 1 then
		self.Region:SetAlpha(self.targetAlpha)
		return false
	end

	local alpha = self.startAlpha + progress * (self.targetAlpha - self.startAlpha)

	self.Region:SetAlpha(alpha)
	return true
end

-- External API
addonMods.WAFade = fade

---@param Region table<string, any>
---@param duration number
---@return table<string, any>
function addonMods.FadeIn(Region, duration)
	Region:SetAlpha(0)
	local instance = fade:New(Region, 0, 1, duration)
	animationManager:Add(instance)
	return instance
end

---@param Region table<string, any>
---@param duration number
---@return table<string, any>
function addonMods.FadeOut(Region, duration)
	local instance = fade:New(Region, Region:GetAlpha(), 0, duration)
	animationManager:Add(instance)
	return instance
end