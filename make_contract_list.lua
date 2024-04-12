assert(loadfile("userdata/config.lua"))()

assert(config, "Config failed to load")


assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/dbtools.lua"))()
assert(loadfile("code/blueprints.lua"))()
assert(loadfile("code/common.lua"))()

local contractObjectivesDB = loadTabFile("userdata/contract_objectives.csv", nil, ",")

local namesDB = loadTabFile("data/cache/names.dat", { "id", "name" }, "\t")
	database.indexByUnique(namesDB, "id")

local contractItemsDB = loadTabFile("data/cache/contracts_items.dat")

local contractStock = { }

local function main()
	local outFile = io.open("outputs/contracts_restock_list.csv", "w")
	outFile:write("item\tquantity\n")

	for _,row in ipairs(contractItemsDB.rows) do
		local itemName = namesDB.keyBy.id[row.itemID]
		if itemName == nil then
			itemName = "UNKNOWN_ITEM_"..row.itemID
		else
			itemName = itemName.name
		end
		contractStock[itemName] = (contractStock[itemName] or 0) + tonumber(row.quantity)
	end

	for _,row in ipairs(contractObjectivesDB.rows) do
		local expectedQuantity = tonumber(row.quantity)
		local existingQuantity = (contractStock[row.item] or 0)
		if expectedQuantity > existingQuantity then
			outFile:write(row.item.."\t"..(expectedQuantity - existingQuantity).."\n")
		end
	end

	outFile:close()
end

main()
