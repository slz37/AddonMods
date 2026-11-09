---@type string, addonMods
local _, addonMods = ...

local texture = addonMods.defaultTexture

local function apply()
	local options = {
		backdropInfo = {
			bgFile = texture,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		},
		centerColor = {r = 0, g = 0, b = 0, a = 0.75},
	}

	AuraContainerInbound.SetTooltipBackdrop(options)
	addonMods.UnregisterEventHandler('PLAYER_ENTERING_WORLD', apply)
end

addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', apply)