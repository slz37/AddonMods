---@type string, addonMods
local _, addonMods = ...
if not ExwindTools then return end

local EXUI 		 = ExwindTools.UI
local original = EXUI.CreateIconWidget

EXUI.CreateIconWidget = function(self, parent, style)
	local widget = original(self, parent, style)
	hooksecurefunc(widget, 'ApplyStyle', function(w)
		if w._useSecretSafeBorder and w.border then w.border:Hide() end
	end)
	return widget
end