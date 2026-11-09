---@type string, addonMods
local _, addonMods = ...
_G.AddonMods = addonMods

local _, class    = UnitClass('player')
addonMods.me      = UnitName('player')
addonMods.myGUID  = UnitGUID('player')
addonMods.myClass = class

---@type EventFrame
local EventFrame    = CreateFrame('Frame', nil, UIParent)
EventFrame.handlers = {}

addonMods.unitEventData = addonMods.unitEventData or {}
addonMods.unitFramePool = addonMods.unitFramePool or {}

---@param self EventFrame
---@param event string
---@vararg ...
EventFrame:SetScript('OnEvent', function(self, event, ...)
	local handler = self.handlers[event]
	if not handler then return end

	local snapshot = {}
	for i, func in ipairs(handler.list) do snapshot[i] = func end

	-- Iterate over a snapshot of the callbacks to avoid deregistration conflicts
	for _, func in ipairs(snapshot) do
		if handler.lookup[func] then func(event, ...) end
	end
end)

---@param event string
---@param func fun()
function addonMods.RegisterEventHandler(event, func)
	local handler = EventFrame.handlers[event]
	if not handler then
		handler = {list = {}, lookup = {}}
		EventFrame.handlers[event] = handler
		EventFrame:RegisterEvent(event)
	end

	if handler.lookup[func] then return end

	handler.lookup[func] = true
	handler.list[#handler.list + 1] = func
end

---@param event string
---@param func fun()
function addonMods.UnregisterEventHandler(event, func)
	local handler = EventFrame.handlers[event]
	if not handler then return end
	if not handler.lookup[func] then return end

	handler.lookup[func] = nil
	for i = #handler.list, 1, -1 do
		if handler.list[i] == func then
			table.remove(handler.list, i)
			break
		end
	end

	if #handler.list == 0 then
		EventFrame:UnregisterEvent(event)
		EventFrame.handlers[event] = nil
	end
end

---@param event string
---@param unit string
---@vararg any
local function unitEventOnEvent(_, event, unit, ...)
	local data = addonMods.unitEventData[event]
	if not data then return end

	local handler = data.handlers[unit]
	if not handler then return end

	local snapshot = {}
	for i, func in ipairs(handler.list) do snapshot[i] = func end

	-- Iterate over a snapshot of the callbacks to avoid deregistration conflicts
	for _, func in ipairs(snapshot) do
		if handler.lookup[func] then func(event, unit, ...) end
	end
end

---@param event string
---@return UnitEventFrame
local function acquireUnitEventFrame(event)
	for _, frame in ipairs(addonMods.unitFramePool) do
		local count = frame.unitEventCounts[event] or 0
		if count < 4 then return frame end
	end

	---@type UnitEventFrame
	local frame						= CreateFrame('Frame', nil, UIParent)
	frame.unitEventList   = {}
	frame.unitEventCounts = {}
	frame:SetScript('OnEvent', unitEventOnEvent)
	addonMods.unitFramePool[#addonMods.unitFramePool + 1] = frame
	return frame
end

---@param data table<string, any>
---@param event string
---@param unit string
local function releaseUnitFromFrame(data, event, unit)
	local frame = data.unitFrame[unit]
	if not frame then return end

	local unitList = frame.unitEventList[event]
	if unitList then
		for i = #unitList, 1, -1 do
			if unitList[i] == unit then
				table.remove(unitList, i)
				break
			end
		end
		frame.unitEventCounts[event] = math.max((frame.unitEventCounts[event] or 1) - 1, 0)

		if #unitList > 0 then
			frame:RegisterUnitEvent(event, unpack(unitList))
		else
			frame:UnregisterEvent(event)
			frame.unitEventList[event]   = nil
			frame.unitEventCounts[event] = nil
		end
	end

	data.unitFrame[unit] = nil
end

---@param event string
---@param unit string
---@param func fun()
function addonMods.RegisterUnitEventHandler(event, unit, func)
	if not unit then
		addonMods.RegisterEventHandler(event, func)
		return
	end

	local data = addonMods.unitEventData[event]
	if not data then
		data = {
			unitFrame = {},
			handlers  = {},
		}
		addonMods.unitEventData[event] = data
	end

	local handler = data.handlers[unit]
	if not handler then
		handler = {list = {}, lookup = {}}
		data.handlers[unit] = handler
	end
	if handler.lookup[func] then return end
	handler.lookup[func] = true
	handler.list[#handler.list + 1] = func

	if not data.unitFrame[unit] then
		local frame          = acquireUnitEventFrame(event)
		data.unitFrame[unit] = frame

		local unitList               = frame.unitEventList[event] or {}
		frame.unitEventList[event]   = unitList
		unitList[#unitList + 1]      = unit
		frame.unitEventCounts[event] = (frame.unitEventCounts[event] or 0) + 1

		frame:RegisterUnitEvent(event, unpack(unitList))
	end
end

---@param event string
---@param unit string
---@param func fun()
function addonMods.UnregisterUnitEventHandler(event, unit, func)
	if not unit then
		addonMods.UnregisterEventHandler(event, func)
		return
	end

	local data = addonMods.unitEventData[event]
	if not data then return end

	local handler = data.handlers[unit]
	if not handler then return end
	if not handler.lookup[func] then return end

	handler.lookup[func] = nil
	for i = #handler.list, 1, -1 do
		if handler.list[i] == func then
			table.remove(handler.list, i)
			break
		end
	end

	if #handler.list == 0 then
		data.handlers[unit] = nil
		releaseUnitFromFrame(data, event, unit)
	end
end

addonMods.KillFrame(PlayerCastingBarFrame)
addonMods.KillFrame(DurabilityFrame)
addonMods.KillFrame(QuickJoinToastButton)
addonMods.KillFrame(TextToSpeechButtonFrame)
addonMods.KillFrame(CompactRaidFrameManager)
addonMods.KillFrame(TalkingHeadFrame)