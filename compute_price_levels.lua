assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/blueprints.lua"))()
assert(loadfile("code/dbtools.lua"))()
assert(loadfile("code/reactions.lua"))()
assert(loadfile("code/sci.lua"))()
assert(loadfile("code/eiv.lua"))()
assert(loadfile("userdata/config.lua"))()

local marketDB = loadTabFile("data/cache/items_esi_sellorders_filtered.dat")

local namesDB = loadTabFile("data/cache/names.dat", { "id", "name" }, "\t" )
    database.indexByUnique(namesDB, "id")

local blueprintQuantityDB = loadTabFile("data/cache/blueprints_multiple_quantity.dat")
    database.indexByUnique(blueprintQuantityDB, "item")

local blueprintCategoryDB = loadTabFile("data/cache/blueprints_categories.dat")
	database.indexByUnique(blueprintCategoryDB, "item")

local categoryReductionDB = loadTabFile("userdata/facility_reductions.dat")
	database.indexByUnique(categoryReductionDB, "category")


local function main()

	local priceTable = config.priceOverrides

	for _,row in ipairs(marketDB.rows) do
		local itemName = row.item
		local price = row.price
		if priceTable[itemName] == nil then
			priceTable[itemName] = math.floor(price * 100.0 + 0.5) / 100
		end
	end

	local blueprintsLibrary = blueprints.load()

	local intermediatesF = io.open("outputs/intermediates.csv", "wb")
	intermediatesF:write("item\tmarketPrice\tbuildPrice\tsourcing\n")

	local intermediateUnprocessedSet = { }

	-- Compute intermediates
	local intermediateItemsDB = loadTabFile("userdata/items_intermediates.dat")

	for _,row in ipairs(intermediateItemsDB.rows) do
		intermediateUnprocessedSet[row.item] = true
	end

	local categoryWarnings = { }

	for _,row in ipairs(intermediateItemsDB.rows) do
		local item = row.item
		intermediateUnprocessedSet[row.item] = false

		local reactionRuns = 100

		local blueprint = blueprintsLibrary[item]
		local reaction = reactions.react(item, reactionRuns)
		local constructedPrice = nil
		local missingInput = false

		if blueprint ~= nil then
			local bpCategory = blueprintCategoryDB.keyBy.item[item].category
			local bpFacilityReduction = 0

			local reductionRow = categoryReductionDB.keyBy.category[bpCategory]
			if reductionRow == nil then
				if not categoryWarnings[bpCategory] then
					categoryWarnings[bpCategory] = true
					print("WARNING: userdata/facility_reductions.dat has no category reduction for blueprints of type "..bpCategory..".  This may be because the SDE category name was changed.")
				end
			else
				bpFacilityReduction = reductionRow.reduction
			end

			local eiv = blueprint:ConstructionCost(eivPriceTable, 1)
			local sci = sci.Find("manufacturing", bpCategory)
			local costFactor = (1.0 - config.structureManufacturingCostReduction / 100.0) * (1.0 + config.structureManufacturingTax / 100.0)

			blueprint = blueprint:Clone()
			blueprint.me = 10
			blueprint:ApplyWaste(config.structureMatRoleBonus, bpFacilityReduction)

			local outputQuantity = (blueprintQuantityDB.keyBy.item[item] or { quantity = 1 }).quantity
			local runs = 100

			constructedPrice = (blueprint:ConstructionCost(priceTable, runs) + eiv * sci * costFactor) / (outputQuantity * runs)

			for mat in pairs(blueprint.materials) do
				if intermediateUnprocessedSet[mat] then
					print("WARNING: Manufactured intermediate "..item.." was listed before input intermediate "..mat..", its value will be inaccurate!  Place "..mat.." higher in the intermediate list to prevent this.")
				end
			end
		elseif reaction ~= nil and config.enableReactionsInReport then
			constructedPrice = 0.0

			local sci = sci.Find("reaction", reaction.category)
			local costFactor = (1.0 + config.structureReactionTax / 100.0)

			if config.alchemy[item] then
				local unrefinedItem = reactions.alchemyUnrefinedItemFor(item)
				local unrefinedQuantity = 100

				reaction = reactions.react(unrefinedItem, unrefinedQuantity)
				local eiv = reactions.computeBaseItemCost(unrefinedItem, eivPriceTable) * unrefinedQuantity

				local reprocessed = reactions.alchemyReprocessUnrefined(unrefinedItem, unrefinedQuantity)

				local costs = reaction.inputs

				if reaction.outputQuantity ~= unrefinedQuantity then
					assert(false, "Reaction output for "..unrefinedItem.." was "..reaction.outputQuantity..", expected "..unrefinedQuantity)
				end

				-- Find the quantity produced and reduce inputs
				local reprocessedOutputQuantity = nil
				for item,quantity in pairs(reprocessed) do
					local inputQuantity = costs[item]
					if inputQuantity ~= nil then
						costs[item] = inputQuantity - quantity
					else
						assert(item == row.item, "Weird alchemy recipe")
						reprocessedOutputQuantity = quantity
					end
				end

				constructedPrice = 0.0
				for mat,quantity in pairs(costs) do
					if intermediateUnprocessedSet[mat] then
						print("WARNING: Manufactured intermediate "..row.item.." was listed before input intermediate "..mat..", its value will be inaccurate!  Place "..mat.." higher in the intermediate list to prevent this.")
					end

					constructedPrice = constructedPrice + priceTable[mat] * quantity
				end

				constructedPrice = (constructedPrice + eiv * sci * costFactor) / reprocessedOutputQuantity
			else
				local outputQuantity = reaction.outputQuantity
				local eiv = reactions.computeBaseItemCost(item, eivPriceTable) * reactionRuns

				constructedPrice = 0.0

				for mat,quantity in pairs(reaction.inputs) do
					if intermediateUnprocessedSet[mat] then
						print("WARNING: Manufactured intermediate "..row.item.." was listed before input intermediate "..mat..", its value will be inaccurate!  Place "..mat.." higher in the intermediate list to prevent this.")
					end

					local price = priceTable[mat]
					if price == nil then
						print("Input "..mat.." has no price!")
						missingInput = true
						price = 0
					end
					constructedPrice = constructedPrice + price * quantity
				end

				constructedPrice = (constructedPrice + eiv * sci * costFactor) / outputQuantity
			end
		else
			print("Unknown intermediate "..row.item)
			if priceTable[row.item] == nil then
				print("   No recipe or price available for "..row.item..", setting value to zero!")
				priceTable[row.item] = 0
			end
		end

		local marketPrice = priceTable[row.item]
		if constructedPrice == nil or missingInput then
			constructedPrice = marketPrice
		end

		if marketPrice == nil then
			print("No item price available for "..row.item..", forcing build")
			marketPrice = constructedPrice
			priceTable[row.item] = constructedPrice
		end

		intermediatesF:write(row.item.."\t"..marketPrice.."\t"..constructedPrice.."\t");

		if constructedPrice < marketPrice then
			intermediatesF:write("build")
			priceTable[row.item] = constructedPrice
		else
			intermediatesF:write("market")
		end
		intermediatesF:write("\n")
	end

	local mpf = io.open("data/cache/items_marketprices.dat", "w")
	mpf:write("item\tprice")
	for k,v in pairs(priceTable) do
		mpf:write("\n"..k.."\t"..v)
	end
	mpf:close()

	intermediatesF:close()
end



main()