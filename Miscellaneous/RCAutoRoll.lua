---@type string, addonMods
local _, addonMods = ...
if not RCLootCouncil then return end

local lootFrame = RCLootCouncil.modules.RCLootFrame

local classes 		  = {'WARRIOR', 'PALADIN', 'HUNTER', 'ROGUE', 'PRIEST', 'DEATHKNIGHT', 'SHAMAN', 'MAGE', 'WARLOCK', 'MONK', 'DRUID', 'DEMONHUNTER', 'EVOKER'}
local rolledEntries = {}

local bisList            = {}
local upgradeList        = {}
local offspecBISList     = {}
local offspecUpgradeList = {}
local transmogList       = {}
local ignoreList         = {}
for _, class in pairs(classes) do
	bisList[class]            = {}
	upgradeList[class]        = {}
	offspecBISList[class]     = {}
	offspecUpgradeList[class] = {}
	transmogList[class]       = {}
	ignoreList[class]         = {}
end

bisList['PRIEST'] = {
	['Venomkeeper\'s Horrific Cowl'] = {['id'] = {271874}, ['track'] = '344', 	 ['equipped'] = false, ['slot'] = 'Head',  	 ['note'] = '', ['isSet'] = false},
	['Silken Voodoo Drape'] 				 = {['id'] = {268253}, ['track'] = '344', 	 ['equipped'] = false, ['slot'] = 'Back',  	 ['note'] = '', ['isSet'] = false},
	['Venomwoven Icon'] 						 = {['id'] = {270926}, ['track'] = 'Mythic', ['equipped'] = false, ['slot'] = 'Chest', 	 ['note'] = '', ['isSet'] = false},
	['Grasps of the Eternal Shadow'] = {['id'] = {268243}, ['track'] = '344', 	 ['equipped'] = false, ['slot'] = 'Hands', 	 ['note'] = '', ['isSet'] = false},
	['Hex Lord\'s Dooming Idol'] 	   = {['id'] = {270169}, ['track'] = '344', 	 ['equipped'] = false, ['slot'] = 'Trinket', ['note'] = 'bis ulatek', ['isSet'] = false},
	['Jan\'thrazet, the Soul Fang']  = {['id'] = {271092}, ['track'] = '344', 	 ['equipped'] = false, ['slot'] = 'MH',  	   ['note'] = '', ['isSet'] = false},
	['Spine of the Hissing Abyss']   = {['id'] = {268197}, ['track'] = '344', 	 ['equipped'] = false, ['slot'] = 'OH',  	   ['note'] = '', ['isSet'] = false},
}
bisList['DEMONHUNTER'] = {
	['Gaze of the Coiled Watcher']	= {['id'] = {271537}, ['track'] = '344', 	 	['equipped'] = false, ['slot'] = 'Head',  	  ['note'] = '', ['isSet'] = false},
	['Aqirbane Reliquary']					= {['id'] = {268265}, ['track'] = '344', 	 	['equipped'] = false, ['slot'] = 'Neck',  	  ['note'] = '', ['isSet'] = false},
	['Frothing Venom Spaulders']		= {['id'] = {271535}, ['track'] = '344', 	 	['equipped'] = false, ['slot'] = 'Shoulders', ['note'] = '', ['isSet'] = false},
	['Silken Voodoo Drape']					= {['id'] = {268253}, ['track'] = '344', 	 	['equipped'] = false, ['slot'] = 'Back',  	  ['note'] = '', ['isSet'] = false},
	['Venomcured Idol']							= {['id'] = {271538}, ['track'] = 'Mythic', ['equipped'] = false, ['slot'] = 'Hands', 	  ['note'] = '', ['isSet'] = false},
	['Sash of the Forlorn Vessel']	= {['id'] = {268256}, ['track'] = '344', 		['equipped'] = false, ['slot'] = 'Belt',  	  ['note'] = '', ['isSet'] = false},
	['Coiled Hex Legguards']				= {['id'] = {271536}, ['track'] = '344', 		['equipped'] = false, ['slot'] = 'Legs',  	  ['note'] = '', ['isSet'] = false},
	['Jan\'thrazet, the Soul Fang'] = {['id'] = {271092}, ['track'] = '344', 		['equipped'] = false, ['slot'] = 'MH',  	    ['note'] = '', ['isSet'] = false},
	['Baleful Hexblade'] 						= {['id'] = {268211}, ['track'] = '344', 		['equipped'] = false, ['slot'] = 'OH',  	    ['note'] = '', ['isSet'] = false},
}

local TRACKS	   = {Adventurer = 1, Veteran = 2, Champion = 3, Hero = 4, Mythic = 5, ['344'] = 6}
local trackCache = {}

---@param link string
---@return string?
local function getTrack(link)
	if not link then return end

	local cached = trackCache[link]
	if cached ~= nil then return cached end

	local data = C_TooltipInfo and C_TooltipInfo.GetHyperlink(link)
	if not data then return end

	local track
	for _, line in ipairs(data.lines or {}) do
		if TooltipUtil and TooltipUtil.SurfaceArgs then TooltipUtil.SurfaceArgs(line) end
		local text = line.leftText
		if text and text:find('%d+/%d+') then
			for name in pairs(TRACKS) do
				if name ~= '344' and text:find(name) then
					track = name
					break
				end
			end
		end
		if track then break end
	end

	if not track then
		local ilvl = C_Item.GetDetailedItemLevelInfo(link)
		if not ilvl then return end
		if ilvl == 344 then track = '344' end
	end

	trackCache[link] = track
	return track
end

---@return table<number, string>?
local function buildOwned()
	local owned = {}
	local function add(link)
		if not link then return end

		local id = C_Item.GetItemInfoInstant(link)
		if not id then return end

		local rank = TRACKS[getTrack(link) or ''] or 0
		if rank > (owned[id] or -1) then owned[id] = rank end
	end

	for slot = 1, 19 do
		add(GetInventoryItemLink('player', slot))
	end
	for bag = 0, NUM_BAG_SLOTS + 1 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			add(C_Container.GetContainerItemLink(bag, slot))
		end
	end
	return owned
end

---@param entry table<string, any>
---@param dropRank number
---@return table<string, any>?
local function trackMatches(entry, dropRank)
	if not entry then return end
	local minRank = TRACKS[entry.track or '']
	if minRank and (not dropRank or dropRank < minRank) then return end
	return entry
end

---@param items table<string, any>
local function setNoteEquipped(items)
	local equipped = 0
	local setItems = {}

	for _, itemData in pairs(items) do
		if itemData.isSet then
			setItems[#setItems + 1] = itemData
			if itemData.equipped then
				equipped = equipped + 1
			end
		end
	end

	local note = equipped .. '/4'
	for i = 1, #setItems do
		if setItems[i].note == '' then
			setItems[i].setNote = note
		else
			setItems[i].setNote = setItems[i].note .. ' - ' .. note
		end
	end
end

---@param list table<string, any>
---@param owned table<number, string>
local function updateList(list, owned)
	for _, entry in pairs(list) do
		local ids = type(entry.id) == 'table' and entry.id or {entry.id}
		local minRank = TRACKS[entry.track or ''] or 0

		entry.equipped = false
		for _, itemId in ipairs(ids) do
			local rank = owned[itemId]
			if rank and rank >= minRank then
				entry.equipped = true
				break
			end
		end
	end
	setNoteEquipped(list)
end

local function updateGear()
	local owned = buildOwned()
	updateList(bisList[addonMods.myClass], owned)
	updateList(upgradeList[addonMods.myClass], owned)
	updateList(offspecBISList[addonMods.myClass], owned)
	updateList(offspecUpgradeList[addonMods.myClass], owned)
	updateList(transmogList[addonMods.myClass], owned)
end

---@param matchText string
---@param default number
---@param buttons table<string, any>
---@param numButtons number
---@return number
local function findButtonIndex(matchText, default, buttons, numButtons)
	for i = 1, numButtons do
		local text = buttons[i].text
		if text and text:find(matchText) then return i end
	end
	return default
end

---@param entry table<string, any>
---@param button number|string
---@param msg string
---@param note string?
---@param itemLink string
local function autoRoll(entry, button, msg, note, itemLink)
	print(msg .. itemLink)
	if note and note ~= '' then entry.item.note = note end

	rolledEntries[entry.item.sessions] = true -- This seems to be unique to each entry in the session
	lootFrame:OnRoll(entry, button)
end

---@param slot string
---@param bis table<string, any>
---@param upgrade table<string, any>
---@return boolean?
local function slotIsEquipped(slot, bis, upgrade)
	local twoSlot = (slot == 'Ring' or slot == 'Trinket')
	local equippedCount = 0

	for _, list in pairs({bis[addonMods.myClass], upgrade[addonMods.myClass]}) do
		for _, v in pairs(list) do
			if v.slot == slot and v.equipped then
				if twoSlot then
					equippedCount = equippedCount + 1
				else
					return true
				end
			end
		end
	end

	if twoSlot then return equippedCount >= 2 end
end

-- Override RCLC update method for loot frame
hooksecurefunc(RCLootCouncil, 'OnLootTableReceived', function() wipe(rolledEntries) end)
hooksecurefunc(lootFrame, 'Update', function(self)
	if not self.EntryManager or not self.EntryManager.entries then return end

	for _, entry in ipairs(self.EntryManager.entries) do
		if entry and not entry.rolled and entry.item and not rolledEntries[entry.item.sessions] then
			rolledEntries[entry.item.sessions] = true
			C_Timer.After(1, function()
				if not entry or entry.rolled or not entry.item then return end
				if not lootFrame.EntryManager or not lootFrame.EntryManager.entries then return end

				local stillExists = false
				for _, activeEntry in ipairs(lootFrame.EntryManager.entries) do
					if activeEntry == entry then
						stillExists = true
						break
					end
				end
				if not stillExists then return end

				local itemLink = entry.item.link
				local itemName = C_Item.GetItemInfo(itemLink)
				if not itemName then return end

				local numButtons = RCLootCouncil:GetNumButtons(entry.type)
				local buttons    = RCLootCouncil:GetButtons(entry.type)

				local dropRank = TRACKS[getTrack(itemLink) or '']

				local bisEntry            = trackMatches(bisList[addonMods.myClass][itemName], dropRank)
				local upgradeEntry        = trackMatches(upgradeList[addonMods.myClass][itemName], dropRank)
				local transmogEntry       = trackMatches(transmogList[addonMods.myClass][itemName], dropRank)
				local offspecBISEntry     = trackMatches(offspecBISList[addonMods.myClass][itemName], dropRank)
				local offspecUpgradeEntry = trackMatches(offspecUpgradeList[addonMods.myClass][itemName], dropRank)
				local ignoreEntry         = ignoreList[addonMods.myClass][itemName]

				-- Ignore
				if ignoreEntry then return end
				-- BIS
				if bisEntry then
					if not bisEntry.equipped then
						local button = findButtonIndex('BIS (Have Crests)', 1, buttons, numButtons)
						autoRoll(entry, button, '|Cff00ff00Auto-need on|r ', bisEntry.setNote or bisEntry.note, itemLink)
						return
					end
				end
				-- UPGRADE
				if upgradeEntry then
					if not upgradeEntry.equipped and not slotIsEquipped(upgradeEntry.slot, bisList, upgradeList) then
						local button = findButtonIndex('Upgrade', 3, buttons, numButtons)
						autoRoll(entry, button, '|CffFFFFC5Auto-upgrade on |r ', upgradeEntry.setNote or upgradeEntry.note, itemLink)
						return
					end
				end
				-- OFFSPEC BIS
				if offspecBISEntry then
					if not offspecBISEntry.equipped then
						local button = findButtonIndex('Offspec', 5, buttons, numButtons)
						autoRoll(entry, button, '|CffFFFFC5Auto-offspec BIS on |r ', offspecBISEntry.setNote or offspecBISEntry.note, itemLink)
						return
					end
				end
				-- OFFSPEC UPGRADE
				if offspecUpgradeEntry then
					if not offspecUpgradeEntry.equipped and not slotIsEquipped(offspecUpgradeEntry.slot, offspecBISList, offspecUpgradeList) then
						local button = findButtonIndex('Offspec', 5, buttons, numButtons)
						autoRoll(entry, button, '|CffFFFFC5Auto-offspec Upgrade on |r ', offspecUpgradeEntry.setNote or offspecUpgradeEntry.note, itemLink)
						return
					end
				end
				-- TRANSMOG
				if transmogEntry then
					if not transmogEntry.equipped then
						local button = findButtonIndex('Misc', 6, buttons, numButtons)
						autoRoll(entry, button, '|Cff90D5FFAuto-roll Misc on|r ', transmogEntry.note, itemLink)
						return
					end
				end
				autoRoll(entry, 'PASS', '|Cffff0000Auto-passed on|r ', nil, itemLink)
			end)
			return
		end
	end
end)

-- Event Registration
addonMods.RegisterEventHandler('PLAYER_EQUIPMENT_CHANGED', updateGear)
addonMods.RegisterEventHandler('BAG_UPDATE', updateGear)
updateGear()