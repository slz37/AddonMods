---@type string, addonMods
local _, addonMods = ...

---@param name string
---@param command string
---@param description string
local function make(name, command, description)
	_G['BINDING_NAME_CLICK ' .. name .. ':LeftButton'] = description
	local Button = CreateFrame('Button', name, nil, 'SecureActionButtonTemplate')
	Button:SetAttribute('type', 'macro')
	Button:SetAttribute('macrotext', command)
	Button:RegisterForClicks('AnyUp', 'AnyDown')
end

for i = 1, 8 do
	make('AddonModsWM' .. i .. 'CURSOR', _G['SLASH_WORLD_MARKER1'] ..' [@cursor] ' .. i, _G['WORLD_MARKER' .. i] ..' @ ' .. _G['MOUSE_LABEL'])
end
make('AddonModsCWMAll', '/cwm all', 'Clear All')