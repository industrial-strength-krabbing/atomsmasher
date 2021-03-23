assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/dbtools.lua"))()
assert(loadfile("userdata/config.lua"))()

local namesDB = loadTabFile("data/cache/names.dat", { "id", "name" }, "\t" )
    database.indexByUnique(namesDB, "id")

local propertiesDB = loadTabFile("data/cache/items_properties.dat")
    database.indexByUnique(propertiesDB, "item")

local itemValueAdjustmentsDB = loadTabFile("userdata/items_value_adjustments.dat")
	database.indexByUnique(itemValueAdjustmentsDB, "item")

local valueAdjustmentProfilesDB = loadTabFile("userdata/value_adjustment_profiles.dat")

local adjustmentProfiles = { }

-----------------------------------------------------------------
local function getItemPriceLevel(collatedMarketOrders, typeID, itemName)
	local orderRows = collatedMarketOrders[typeID]

	local itemVolume = 0
	if propertiesDB.keyBy["item"][itemName] ~= nil then
		itemVolume = tonumber(propertiesDB.keyBy["item"][itemName].volume)
	end

	local allOrders = { }

	for _,row in ipairs(orderRows) do
		local price = tonumber(row.price)
		local locationType = row.locationType
		local adjustmentRow = itemValueAdjustmentsDB.keyBy["item"][itemName]

		if adjustmentRow ~= nil then
			local adjustmentProfile = adjustmentRow.valueAdjustmentProfile

			local profileLocationTypes = adjustmentProfiles[adjustmentProfile]
			if profileLocationTypes ~= nil then
				local adjustmentRow = profileLocationTypes[row.locationType]
				if adjustmentRow ~= nil then
					local adjustmentPerVolume = tonumber(adjustmentRow.adjustmentPerVolume)
					local adjustmentAmount = adjustmentPerVolume * itemVolume
					price = price + adjustmentAmount
				end
			end
		end

		allOrders[#allOrders+1] = { price = price, volume = tonumber(row.quantity) }
	end

	if not config.marketOrderOutlierFilter.enabled then
		local lowestPrice = nil
		for _,order in ipairs(allOrders) do
			local price = tonumber(order.price)
			if lowestPrice == nil or price < lowestPrice then
				lowestPrice = price
			end
		end

		return lowestPrice
	end

	table.sort(allOrders, function(a, b) return (a.price < b.price) end)

	local outlierFilterAggregationMultiplier = (100.0 + config.marketOrderOutlierFilter.aggregationThreshold) / 100.0

	local merged = { allOrders[1] }
	for i=2,#allOrders do
		local lastOrder = merged[#merged]
		local nextOrder = allOrders[i]

		if nextOrder.price < lastOrder.price * outlierFilterAggregationMultiplier then
			local combinedVolume = lastOrder.volume + nextOrder.volume
			local combinedValue = lastOrder.volume*lastOrder.price + nextOrder.volume*nextOrder.price
			lastOrder.volume = combinedVolume
			lastOrder.price = combinedValue / combinedVolume
		else
			merged[#merged+1] = nextOrder
		end
	end

	local premerged = allOrders
	allOrders = merged

	table.sort(allOrders, function(a, b) return (a.price < b.price) end)

	-- Total the volume of the first 5 orders
	local total = 0
	local scanDepth = config.marketOrderOutlierFilter.scanDepth
	local tolerance = config.marketOrderOutlierFilter.tolerance / 100.0

	local throwWarning = false

	if allOrders[scanDepth] == nil then
		scanDepth = #allOrders
		if (#premerged < scanDepth) then
			print("\nWARNING: Item "..itemName.." only has "..scanDepth.." entries!")
			local throwWarning = true
		end
	end

	for i=1,scanDepth do
		if allOrders[i] then
			total = total + allOrders[i].volume
		end
	end

	for i=1,scanDepth do
		if allOrders[i].volume / total > tolerance then
			if throwWarning then
				print("Exported price as "..allOrders[i].price.." ISK,\n   if this isn't correct you should fix it manually,\n   or override it in config.lua")
			end
			return allOrders[i].price
		end
	end

	assert(false, "Failed to find a price for item "..itemName..", probably because the outlier filter has bad settings.  Check config.lua and make sure that the outlier filter scanDepth multiplied by the tolerance is less than 100!")
end

local function main()
	local priceTable = { }
	local collatedMarketOrders = { }
	
	for _,row in ipairs(valueAdjustmentProfilesDB.rows) do
		local profileLocationTypes = adjustmentProfiles[row.valueAdjustmentProfile]
		if profileLocationTypes == nil then
			profileLocationTypes = { }
			adjustmentProfiles[row.valueAdjustmentProfile] = profileLocationTypes
		end
		profileLocationTypes[row.locationType] = row
	end

	local integrateDatabase = function(marketDB)
		for _,row in ipairs(marketDB.rows) do
			local typeID = row["typeID"]
			local typeRows = collatedMarketOrders[typeID]
			if typeRows == nil then
				typeRows = { }
				collatedMarketOrders[typeID] = typeRows
			end
			typeRows[#typeRows + 1] = row
		end
	end

	for _,pubMarket in ipairs(config.publicMarkets) do
		local regionID = pubMarket.regionID

		local marketDB = loadTabFile("data/cache/public_market_"..regionID..".dat")
		integrateDatabase(marketDB)
	end

	for _,citMarket in ipairs(config.citadelMarkets) do
		local locationID = citMarket.locationID

		local marketDB = loadTabFile("data/cache/citadel_market_"..locationID..".dat")
		integrateDatabase(marketDB)
	end

	for typeID in pairs(collatedMarketOrders) do
		local itemName

		local itemNameRow = namesDB.keyBy.id[typeID]
		if itemNameRow == nil then
			itemName = "UNKNOWN_ITEM_"..typeID
		else
			itemName = itemNameRow.name
		end

		local price = getItemPriceLevel(collatedMarketOrders, typeID, itemName)
		priceTable[itemName] = math.floor(price * 100 + 0.5) / 100
	end

	local mpf = io.open("data/cache/items_esi_sellorders_filtered.dat", "w")
	mpf:write("item\tprice")
	for k,v in pairs(priceTable) do
		mpf:write("\n"..k.."\t"..v)
	end
	mpf:close()
end



main()
