---@type string, addonMods
local _, addonMods = ...
local animationManager = addonMods.animationManager

-- Pulse Functions
---@param percent number
---@param power number
---@return number
local function easeOutIn(percent, power)
	if percent < 0.5 then return (percent * 2)^power * 0.5 end
	return 1 - ((1 - percent) * 2)^power * 0.5
end

---@param progress number
---@param startR number
---@param startG number
---@param startB number
---@param startA number
---@param targetR number
---@param targetG number
---@param targetB number
---@param targetA number
---@return number, number, number, number
local function pulseColor(progress, startR, startG, startB, startA, targetR, targetG, targetB, targetA)
	local percent = progress * 2
	if percent > 1 then percent = 2 - percent end

	local r = startR + (targetR - startR) * percent
	local g = startG + (targetG - startG) * percent
	local b = startB + (targetB - startB) * percent
	local a = startA + (targetA - startA) * percent
	return r, g, b, a
end

-- Pulse Class
local pulse = {}
pulse.__index = pulse

---@param FontString FontString
---@param duration number
---@param targetColor table<string, number>
---@param easeStrength number
---@return table<string, any>
function pulse:New(FontString, duration, targetColor, easeStrength)
	local instance = setmetatable({}, pulse)

	instance.FontString = FontString
	instance.duration = duration or 1
	instance.progress = 0
	instance.easeStrength = easeStrength or 3

	instance.startR, instance.startG, instance.startB, instance.startA = FontString:GetTextColor()

	instance.targetR = targetColor.r or targetColor[1] or 1
	instance.targetG = targetColor.g or targetColor[2] or 0
	instance.targetB = targetColor.b or targetColor[3] or 0
	instance.targetA = targetColor.a or targetColor[4] or 1

	return instance
end

function pulse:UpdateStartColor()
	self.startR, self.startG, self.startB, self.startA = self.FontString:GetTextColor()
end

---@param elapsed number
---@return boolean
function pulse:Update(elapsed)
	if not self.FontString then return false end

	self.progress = self.progress + elapsed / self.duration
	if self.progress >= 1 then self.progress = self.progress - math.floor(self.progress) end

	local eased 		 = easeOutIn(self.progress, self.easeStrength)
	local r, g, b, a = pulseColor(eased, self.startR, self.startG, self.startB, self.startA, self.targetR, self.targetG, self.targetB, self.targetA)

	self.FontString:SetTextColor(r, g, b, a)
	return true
end

function pulse:Stop()
	if not self.FontString then return end
	self.FontString:SetTextColor(self.startR, self.startG, self.startB, self.startA)
end

-- External API
addonMods.WAPulse = pulse

---@param FontString FontString
---@param duration number
---@param targetColor table<string, number>
---@param easeStrength number
---@return table<string, any>
function addonMods.CreatePulse(FontString, duration, targetColor, easeStrength)
	local instance = pulse:New(FontString, duration, targetColor, easeStrength)
	return instance
end

---@param instance table<string, any>
function addonMods.AddPulse(instance)
	animationManager:Add(instance)
end

---@param instance table<string, any>
function addonMods.RemovePulse(instance)
	animationManager:Remove(instance)
end