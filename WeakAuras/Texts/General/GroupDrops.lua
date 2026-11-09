---@type string, addonMods
local _, addonMods = ...

local font      = addonMods.defaultFont
local fontFlags = 'OUTLINE, SLUG'

local DURATION    = 3
local HS_ID       = 5512
local NO_HS_COLOR = {r = 134/255, g = 255/255, b = 119/255}
local DROP_COLOR  = {r = 255/255, g = 255/255, b = 255/255}
local SOUND_PATH  = 'Interface\\AddOns\\AddonMods\\Media\\Sounds\\IM.ogg'

local timers = {}

-- Create visuals
---@param pos number
---@param color table<string, number>
---@return FontString
local function createText(pos, color)
	local text = UIParent:CreateFontString(nil, 'OVERLAY')
	text:Hide()

	---@cast fontFlags string
	text:SetFont(font, 18, fontFlags)
	text:SetText('')
	text:SetTextColor(color.r, color.g, color.b)

	local statusGroup = addonMods.GetOrCreateDynamicGroup('TopText', {
		point         = 'BOTTOM',
		relativeTo    = UIParent,
		relativePoint = 'CENTER',
		x             = 1,
		y             = 88,
		direction     = 'UP',
		spacing       = -4,
	})
	statusGroup:AddMember(text, pos)

	return text
end
local feastText  = createText(3, DROP_COLOR)
local cauldText  = createText(2, DROP_COLOR)
local hsText     = createText(1, NO_HS_COLOR)
local repairText = createText(4, DROP_COLOR)

local feastFlash  = addonMods.CreateFlash(feastText)
local cauldFlash  = addonMods.CreateFlash(cauldText)
local hsFlash     = addonMods.CreateFlash(hsText)
local repairFlash = addonMods.CreateFlash(repairText)

---@param event string
local function cancelTimer(event)
	if not timers[event] then return end
	timers[event]:Cancel()
	timers[event] = nil
end

---@param event string
---@param text FontString
---@param flash table<string, any>
---@param display string
local function showText(event, text, flash, display)
	if not text:IsShown() then PlaySoundFile(SOUND_PATH, 'Master') end -- Don't spam sounds
	text:Show()
	text:SetText(display)
	addonMods.AddFlash(flash)

	cancelTimer(event)
	timers[event] = C_Timer.NewTimer(DURATION, function()
		addonMods.RemoveFlash(flash)
		text:Hide()
	end)
end

---@param unitName string
---@param event string
local function handleEvent(unitName, event)
	if C_InstanceEncounter.IsEncounterInProgress() then return end
  if not UnitIsVisible(unitName) then return end
	if UnitIsUnit(unitName, 'player') then return end

	if event == 'FEAST' then
		showText(event, feastText, feastFlash, 'Feast')
	elseif event == 'CAULDRON' then
		showText(event, cauldText, cauldFlash, 'Cauldron')
	elseif event == 'SOULWELL' then
		local count = C_Item.GetItemCount(HS_ID, false, true)
		if count and count == 3 then return end

		showText(event, hsText, hsFlash, 'Cookies')
	elseif event == 'REPAIR' then
		showText(event, repairText, repairFlash, 'Tiny Man')
	end
end

---@param comm string
---@param msg string
---@param sender string
local function handleComm(_, comm, msg, _, sender)
	if comm ~= 'NSI_MSG' then return end

	local decodeSuccess, decoded = pcall(C_EncodingUtil.DecodeBase64, msg, Enum.Base64Variant.StandardUrlSafe)
	if not decodeSuccess or not decoded then return end

	local decompressSuccess, decompressed = pcall(C_EncodingUtil.DecompressString, decoded, Enum.CompressionMethod.Deflate)
	if not decompressSuccess or not decompressed then return end

	local deserializeSuccess, payload = pcall(C_EncodingUtil.DeserializeCBOR, decompressed)
	if not deserializeSuccess or type(payload) ~= 'table' or type(payload.event) ~= 'string' or type(payload.args) ~= 'table' then return end

	if (UnitExists(sender) and (UnitInRaid(sender) or UnitInParty(sender))) then -- block addon msg's from outside the raid, only exception being the guild nickname comms.
		local argTable = payload.args
		if type(argTable.n) ~= 'number' or argTable.n < 1 or argTable.n > 16 or argTable.n ~= math.floor(argTable.n) then return end
		handleEvent(unpack(argTable, 1, argTable.n))
	end
end

local function playerEnteringWorld()
	if IsInRaid() or IsInGroup() then
		addonMods.RegisterEventHandler('CHAT_MSG_ADDON', handleComm)
	else
		addonMods.UnregisterEventHandler('CHAT_MSG_ADDON', handleComm)
	end
end

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_ENTERING_WORLD', playerEnteringWorld)