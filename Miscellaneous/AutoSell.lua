---@type string, addonMods
local _, addonMods = ...

local SELL_BELOW_ILVL = 200
local SELL_INTERVAL   = 0.15

local Ticker

---@return number?, number?
local function findItemToSell()
	for bag = 0, NUM_BAG_SLOTS do
		local numSlots = C_Container.GetContainerNumSlots(bag)
		for slot = 1, numSlots do
			local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
			if itemInfo and itemInfo.itemID and not itemInfo.isLocked then
				local itemLink = itemInfo.hyperlink
				local _,_,_, itemLevel, _,_,_,_,_,_, itemSellPrice = C_Item.GetItemInfo(itemLink)

				if itemLevel and C_Item.IsEquippableItem(itemLink) then
					local effectiveLevel = select(1, C_Item.GetDetailedItemLevelInfo(itemLink)) or itemLevel

					if effectiveLevel < SELL_BELOW_ILVL and itemSellPrice and itemSellPrice > 0 then
						return bag, slot
					end
				end
			end
		end
	end
end

local function stopSelling()
	if Ticker then
		Ticker:Cancel()
		Ticker = nil
	end
end

local function sellTick()
	if not MerchantFrame or not MerchantFrame:IsShown() then
		stopSelling()
		return
	end

	local bag, slot = findItemToSell()
	if bag then
		C_Container.UseContainerItem(bag, slot)
	else
		stopSelling()
	end
end

local function sellItems()
	if Ticker then return end
	Ticker = C_Timer.NewTicker(SELL_INTERVAL, sellTick)
end

-- Event Registration
addonMods.RegisterEventHandler('MERCHANT_SHOW', sellItems)
addonMods.RegisterEventHandler('MERCHANT_CLOSED', stopSelling)