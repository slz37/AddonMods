---@type string, addonMods
local _, addonMods = ...

addonMods.animationManager  = addonMods.animationManager or {}
local animationManager  = addonMods.animationManager
animationManager.active = {}

-- Event Frame
local Frame = CreateFrame('Frame')
Frame:Hide()
Frame:SetScript('OnUpdate', function(_, elapsed)
	for anim in pairs(animationManager.active) do
		if not anim:Update(elapsed) then animationManager:Remove(anim) end
	end
end)

-- External Functions
---@param anim table<string, any>
function animationManager:Add(anim)
	self.active[anim] = true
	Frame:Show()
end

---@param anim table<string, any>
function animationManager:Remove(anim)
	self.active[anim] = nil
	if anim.Stop then anim:Stop() end
	if not next(self.active) then Frame:Hide() end
end

function animationManager:Clear()
	for anim in pairs(self.active) do
		if anim.Stop then anim:Stop() end
	end
	wipe(self.active)
	Frame:Hide()
end
