---@type string, addonMods
local _, addonMods = ...
if not Grid2 then return end

local SOFT = 'Soft'
local THIN = 'Thin'
local SLUG = 'Slug'

---@param loadedAddon string
local function addGridSlugOptions(_, loadedAddon)
	if loadedAddon ~= 'Grid2Options' then return end
	addonMods.UnregisterEventHandler('ADDON_LOADED', addGridSlugOptions)

	Grid2Options.fontFlagsValues['SLUG'] = SLUG
	Grid2Options.fontFlagsValues['OUTLINE, SLUG'] = string.format('%s,%s,%s', SOFT, THIN, SLUG)

	Grid2Options.fontFlagsShadowValues['0;SLUG'] = SLUG
	Grid2Options.fontFlagsShadowValues['0;OUTLINE, SLUG'] = string.format('%s,%s,%s', SOFT, THIN, SLUG)

	Grid2Options.fontFlagsShadowDefValues['0;SLUG'] = SLUG
	Grid2Options.fontFlagsShadowDefValues['0;OUTLINE, SLUG'] = string.format('%s,%s,%s', SOFT, THIN, SLUG)
end

-- Event Registration
addonMods.RegisterEventHandler('ADDON_LOADED', addGridSlugOptions)