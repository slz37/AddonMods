---@type string, addonMods
local _, addonMods = ...
if not EllesmereUI then return end

local Timers = {}

---@param cvar string
---@param value string|number
local function forceNameplates(_, cvar, value)
	value = tonumber(value)
	if value ~= 0 then return end
	if cvar ~= 'nameplateShowFriendlyPlayers' and cvar ~= 'nameplateShowFriendlyNpcs' then return end

	if Timers[cvar] then Timers[cvar]:Cancel() end

	Timers[cvar] = C_Timer.NewTimer(1, function()
		Timers[cvar] = nil
		pcall(C_CVar.SetCVar, cvar, 1)
	end)
end

addonMods.RegisterEventHandler('CVAR_UPDATE', forceNameplates)