---@type string, addonMods
local _, addonMods = ...
if addonMods.myClass ~= 'PRIEST' then return end

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local macros = {
  ['PI'] = function(n)
    return '#showtooltip\n/cast [@mouseover,help,nodead][@' .. n .. ',exists,nodead][] Power Infusion\n/use 13\n/use 14\n/cast Vampiric Embrace'
  end,
  ['PI (Ula)'] = function(n)
    return '/cleartarget\n/targetexact Venomous Heart\n/stopmacro [noexists]\n/cast [@mouseover,help,nodead][@' .. n .. ',exists,nodead][] Power Infusion\n/use 13\n/use 14\n/cast Vampiric Embrace\n/cast Tentacle Slam'
  end,
}
local ConfirmTimer
local showingConfirm = false

local PIReminderText = UIParent:CreateFontString(nil, 'OVERLAY')
PIReminderText:Hide()
PIReminderText:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)

---@cast fontFlags string
PIReminderText:SetFont(font, 32, fontFlags)

---@return string?
local function getMacroTarget()
  local index = GetMacroIndexByName('PI')
  if not index or index == 0 then return end

  local body = GetMacroBody(index)
  return body and body:match('%[@([^,%]]+),exists')
end

---@param name string
---@return boolean
local function targetInGroup(name)
  return UnitInParty(name) or UnitInRaid(name) or UnitIsUnit(name, 'player')
end

---@return boolean
local function validState()
	local _, instanceType = GetInstanceInfo()
	local inGroup 				= IsInGroup()
	local inInstance 			= instanceType and (instanceType == 'party' or instanceType == 'raid')
	local inCombat				= InCombatLockdown()
	local isDead 					= UnitIsDead('player')
	local inMythicPlus 		= C_ChallengeMode.IsChallengeModeActive()

	return inGroup and inInstance and not inCombat and not isDead and not inMythicPlus
end

local function checkPI()
	RunNextFrame(function()
		if showingConfirm then return end
		if not validState() then PIReminderText:Hide() return end

		local name = getMacroTarget()
		if name and targetInGroup(name) then
			PIReminderText:Hide()
		else
			PIReminderText:SetText('Set PI')
			PIReminderText:SetTextColor(1, 1, 1)
			PIReminderText:Show()
		end
	end)
end

-- Binding
_G['BINDING_NAME_CLICK ' .. 'AddonModsPIReminder' .. ':LeftButton'] = 'PI Reminder'
local Button = CreateFrame('Button', 'AddonModsPIReminder', nil, 'SecureActionButtonTemplate')
Button:RegisterForClicks('AnyUp', 'AnyDown')

Button:HookScript('PreClick', function()
  local n = UnitName('target')
  if not n or InCombatLockdown() then return end
  for name, build in pairs(macros) do
    local index = GetMacroIndexByName(name)
    if index and index > 0 then
      EditMacro(index, nil, nil, build(n))
    end
  end
end)
Button:HookScript('PostClick', function()
  local target = UnitName('target')
  if not target or InCombatLockdown() then return end

  C_Timer.After(0.1, function()
    if getMacroTarget() ~= target then return end

    if ConfirmTimer then ConfirmTimer:Cancel() end
    showingConfirm = true
    PIReminderText:SetText('PI Set: ' .. addonMods.WA_ClassColorName(target))
    PIReminderText:SetTextColor(1, 1, 1)
    PIReminderText:Show()

    ConfirmTimer = C_Timer.NewTimer(3, function()
      showingConfirm = false
      ConfirmTimer   = nil
      checkPI()
    end)
  end)
end)

-- Event Registration
addonMods.RegisterEventHandler('CHALLENGE_MODE_START', checkPI)
addonMods.RegisterEventHandler('PLAYER_REGEN_ENABLED', checkPI)
addonMods.RegisterEventHandler('PLAYER_REGEN_DISABLED', checkPI)
addonMods.RegisterEventHandler('GROUP_ROSTER_UPDATE', checkPI)
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', checkPI)