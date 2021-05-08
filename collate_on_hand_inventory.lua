assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/blueprints.lua"))()
assert(loadfile("code/dbtools.lua"))()
assert(loadfile("code/reactions.lua"))()
assert(loadfile("userdata/config.lua"))()

local bpdb, bpidToItem = blueprints.load()

local jobsDB = loadTabFile("data/cache/industry_jobs.dat")
local corpJobsDB = loadTabFile("data/cache/industry_jobs_corp.dat")
local assetsDB = loadTabFile("data/cache/assets.dat")
local corpAssetsDB = loadTabFile("data/cache/assets_corp.dat")
local locationsDB = loadTabFile("data/cache/asset_locations.dat")
local namesDB = loadTabFile("data/cache/names.dat", { "id", "name" }, "\t" )
	database.indexByUnique(namesDB, "id")

local reactionPropertiesDB = loadTabFile("data/cache/reactions_properties.dat")
	database.indexByUnique(reactionPropertiesDB, "blueprintID")

local blueprintQuantityDB = loadTabFile("data/cache/blueprints_multiple_quantity.dat")
    database.indexByUnique(blueprintQuantityDB, "item")

local itemQuantities = { }
local allowedSolarSystems = { }

for _,row in ipairs(config.collateSystems) do
	allowedSolarSystems[row] = true
end

local appendItem = function(item, quantity)
	itemQuantities[item] = (itemQuantities[item] or 0) + quantity
end

if config.collateIncludeIndustryProducts then
	local fuckedSDEWarning = false

	for _,db in ipairs({jobsDB, corpJobsDB}) do
		for _,row in ipairs(db.rows) do
			local solarSystem = row["output_solar_system"]

			local activity
			if row.activity_id == 9 then
				activity = "Reactions"
			elseif row.activity_id == 1 then
				activity = "Manufacturing"
			end

			local outputItem = nil
			local outputQuantity = nil

			if allowedSolarSystems[solarSystem] then
				if activity == "Manufacturing" then
					local runs = row.runs
					local productID = row.product_type_id

					local product = namesDB.keyBy.id[productID].name

					local qRow = blueprintQuantityDB.keyBy.item[product]
					local quantity = 1
					if qRow then
						quantity = qRow.quantity
					end

					appendItem(product, quantity * runs)
				elseif activity == "Reactions" then
					local reaction = reactionPropertiesDB.keyBy.blueprintID[row.blueprint_type_id]

					appendItem(reaction.item, reaction.outputQuantity * row.runs)
				end
			end
		end
	end
end

for _,row in ipairs(assetsDB.rows) do
	if row.is_singleton == "false" and row.location_flag == "Hangar" and allowedSolarSystems[row.solar_system_name] then
		local namesRow = namesDB.keyBy.id[row.type_id]
		if namesRow == nil then
			print("Unknown item ID "..row.type_id)
		else
			local itemName = namesRow.name
			appendItem(itemName, row.quantity)
		end
	end
end

local validCorpHangars = { }
for _,item in ipairs({"CorpDeliveries", "CorpSAG1", "CorpSAG2", "CorpSAG3", "CorpSAG4", "CorpSAG5", "CorpSAG6", "CorpSAG7"}) do
	validCorpHangars[item] = true
end

for _,row in ipairs(corpAssetsDB.rows) do
	if row.is_singleton == "false" and validCorpHangars[row.location_flag] and allowedSolarSystems[row.solar_system_name] then
		local namesRow = namesDB.keyBy.id[row.type_id]
		if namesRow == nil then
			print("Unknown item ID "..row.type_id)
		else
			local itemName = namesRow.name
			appendItem(itemName, row.quantity)
		end
	end
end

local sortedItemNames = { }

for k in pairs(itemQuantities) do
	sortedItemNames[#sortedItemNames + 1] = k
end

table.sort(sortedItemNames)

local assetFile = io.open("userdata/on_hand_inventory.csv", "w")
assetFile:write("item,quantity\n")

for _,itemName in ipairs(sortedItemNames) do
	-- HACK: Filter out items with commas like "Me, Myself, and Plunder"
	-- I don't think any of these are industry items, and they screw up the tab loader
	if string.find(itemName, ",") == nil then
		assetFile:write(itemName)
		assetFile:write(",")
		assetFile:write(itemQuantities[itemName])
		assetFile:write("\n")
	end
end

assetFile:close()
