local priceDB = loadTabFile("data/items_esi_prices.dat")

local priceTable = { }

for _,row in ipairs(priceDB.rows) do
	local activityData = { }
	priceTable[row.item] = row.adjustedPrice
end

eivPriceTable = priceTable
