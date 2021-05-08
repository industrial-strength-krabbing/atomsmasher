assert(loadfile("userdata/config.lua"))()

assert(config, "Config failed to load")

assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/dbtools.lua"))()
assert(loadfile("code/blueprints.lua"))()
assert(loadfile("code/common.lua"))()
assert(loadfile("code/reactions.lua"))()
assert(loadfile("code/sci.lua"))()
assert(loadfile("code/eiv.lua"))()

local reactionsComplexDB = loadTabFile("userdata/reactions_complex.dat")
    database.indexByUnique(reactionsComplexDB, "item")

local reactionsIntermediateDB = loadTabFile("userdata/reactions_intermediate.dat")
    database.indexByUnique(reactionsIntermediateDB, "item")

local itemsPropertiesDB = loadTabFile("data/cache/items_properties.dat")
	database.indexByUnique(itemsPropertiesDB, "item")

local priceTable = database.convertToDict(loadTabFile("data/cache/items_marketprices.dat"), "item", "price")
local marketTable = database.convertToDict(loadTabFile("data/cache/items_esi_sellorders_filtered.dat"), "item", "price")

local intermediateReactions = { }
local complexReactions = { }
local alchemyReactions = { }

local function findItemVolume(item)
	local matVolume = itemsPropertiesDB.keyBy.item[item]
	if matVolume ~= nil then
		return tonumber(matVolume.volume)
	end
	return 0.0
end

local function averageReaction(item)
	local sampleSize = 100

	local reaction = reactions.react(item, sampleSize)

	local averageInputs = { }

	for mat,quantity in pairs(reaction.inputs) do
		averageInputs[mat] = quantity / reaction.outputQuantity
	end

	return { inputs = averageInputs, eivInputs = averageInputs, time = reaction.time / reaction.outputQuantity, category = reaction.category }
end

local function averageIntermediateCosts(reaction, item)
	local cost = 0.0
	local eiv = 0.0

	local sci = sci.Find("reaction", reaction.category)

	for mat,quantity in pairs(reaction.inputs) do
		cost = cost + priceTable[mat] * quantity
	end
	for mat,quantity in pairs(reaction.eivInputs) do
		eiv = eiv + eivPriceTable[mat] * quantity
	end

	local taxFactor = 1 + config.structureReactionTax / 100

	return cost + eiv * sci * taxFactor
end

local function averageAlchemizedReaction(item)
	local sampleSize = 100

	local unrefinedItem = reactions.alchemyUnrefinedItemFor(item)

	if unrefinedItem == nil then
		return unrefinedItem
	end

	local reaction = reactions.react(unrefinedItem, sampleSize)
	assert(reaction.outputQuantity == sampleSize)

	local eivCosts = { }
	for mat,quantity in pairs(reaction.inputs) do
		eivCosts[mat] = quantity
	end

	local reprocessed = reactions.alchemyReprocessUnrefined(unrefinedItem, sampleSize)

	local outputQuantity = nil

	local costs = reaction.inputs

	for mat,quantity in pairs(reprocessed) do
		if mat == item then
			outputQuantity = quantity
		else
			local cost = costs[mat]
			assert(cost, "Weird alchemy recipe")
			costs[mat] = cost - quantity
		end
	end

	for mat,quantity in pairs(costs) do
		costs[mat] = costs[mat] / outputQuantity
	end
	for mat,quantity in pairs(eivCosts) do
		eivCosts[mat] = quantity / outputQuantity
	end

	return { inputs = costs, eivInputs = eivCosts, time = reaction.time / outputQuantity, category = reaction.category }
end

for _,row in ipairs(reactionsIntermediateDB.rows) do
	local item = row.item

	intermediateReactions[item] = averageReaction(item)

	intermediateReactions[item].alchemy = averageAlchemizedReaction(item)
end

for _,row in ipairs(reactionsComplexDB.rows) do
	local item = row.item

	complexReactions[item] = averageReaction(item)
end

for item,row in pairs(intermediateReactions) do
	row.cost = averageIntermediateCosts(row, item)
	if row.alchemy then
		row.alchemy.cost = averageIntermediateCosts(row.alchemy, item)
	end
end


local alchemyFile = io.open("outputs/reactions_alchemy.csv", "w")
alchemyFile:write("item\tnormalCost\talchemyCost\tcostSavings\tcostSavingsPerExtraHour\n")

for _,row in ipairs(reactionsIntermediateDB.rows) do
	local item = row.item

	local reaction = intermediateReactions[item]

	if reaction.alchemy then
		local savings = reaction.cost - reaction.alchemy.cost
		alchemyFile:write(item)
		alchemyFile:write("\t")
		alchemyFile:write(reaction.cost)
		alchemyFile:write("\t")
		alchemyFile:write(reaction.alchemy.cost)
		alchemyFile:write("\t")
		alchemyFile:write(savings)
		alchemyFile:write("\t")
		alchemyFile:write(savings * 3600.0 / (reaction.alchemy.time - reaction.time))
		alchemyFile:write("\n")
	end
end
alchemyFile:close()

local mostAlchInputs = 0

local reactionInfos = { }
for _,row in ipairs(reactionsComplexDB.rows) do
	local item = row.item

	local reaction = complexReactions[item]

	local alchemizeInput = { }

	local uncheckedAlchemizableInputs = { }

	for item in pairs(reaction.inputs) do
		if intermediateReactions[item] and intermediateReactions[item].alchemy then
			uncheckedAlchemizableInputs[item] = true
		end
	end

	local time = complexReactions[item].time
	local cost = 0.0
	local missingItem = false
	local volume = 0.0
	local nonFuelBlockInputVolume = 0.0

	for inputItem,quantity in pairs(reaction.inputs) do
		local intermediateReaction = intermediateReactions[inputItem]
		if intermediateReaction then
			time = time + intermediateReaction.time * quantity
			cost = cost + intermediateReaction.cost * quantity
		else
			if priceTable[inputItem] == nil then
				print("WARNING: Missing price for input "..inputItem..", reaction "..item.." will be skipped")
				missingItem = true
			else
				cost = cost + priceTable[inputItem] * quantity
			end
		end
		local inputVolume = findItemVolume(inputItem) * quantity
		volume = volume + inputVolume
		if not string.find(inputItem, "Fuel Block") then
			nonFuelBlockInputVolume = nonFuelBlockInputVolume + inputVolume
		end
	end

	if not missingItem then
		local eiv = 0.0

		for mat,quantity in pairs(reaction.eivInputs) do
			eiv = eiv + eivPriceTable[mat] * quantity
		end

		local sci = sci.Find("reaction", reaction.category)
		local taxFactor = 1 + config.structureReactionTax / 100
		local installFee = eiv * sci * taxFactor

		cost = cost + installFee

		local bestCostCost = cost
		local bestTimeEfficientCost = cost

		local sellPrice = marketTable[item]
		if sellPrice == nil then
			print("Missing sell price for item "..item..", forcing it to "..tostring(cost).." (its cost)")
			sellPrice = cost
		end

		local bestTimeEfficientTime = time
		local bestCostTime = time
		local bestProfitPerSecond = (sellPrice - cost) / time

		while next(uncheckedAlchemizableInputs) do
			local bestAlchemy = nil
			local bestSavingsPerSecond = nil

			for item in pairs(uncheckedAlchemizableInputs) do
				local inputReaction = intermediateReactions[item]
				local savingsPerSecond = (inputReaction.cost - inputReaction.alchemy.cost) / (inputReaction.alchemy.time - inputReaction.time)

				if bestSavingsPerSecond == nil or bestSavingsPerSecond < savingsPerSecond then
					bestAlchemy = item
					bestSavingsPerSecond = savingsPerSecond
				end
			end

			if bestSavingsPerSecond <= 0.0 then
				uncheckedAlchemizableInputs = { }
			else
				local inputQuantity = reaction.inputs[bestAlchemy]

				uncheckedAlchemizableInputs[bestAlchemy] = nil

				local timeDifference = (intermediateReactions[bestAlchemy].alchemy.time - intermediateReactions[bestAlchemy].time) * inputQuantity
				local costDifference = (intermediateReactions[bestAlchemy].alchemy.cost - intermediateReactions[bestAlchemy].cost) * inputQuantity

				bestCostCost = bestCostCost + costDifference
				bestCostTime = bestCostTime + timeDifference

				if bestSavingsPerSecond > bestProfitPerSecond then
					alchemizeInput[bestAlchemy] = "always"

					bestTimeEfficientCost = bestTimeEfficientCost + costDifference
					bestTimeEfficientTime = bestTimeEfficientTime + timeDifference

					bestProfitPerSecond = (sellPrice - bestTimeEfficientCost) / bestTimeEfficientTime
				else
					alchemizeInput[bestAlchemy] = "slower"
				end
			end
		end

		local sortedAlchInputs = { }

		for input in pairs(reaction.inputs) do
			if alchemizeInput[input] then
				sortedAlchInputs[#sortedAlchInputs + 1] = input
			end
		end

		table.sort(sortedAlchInputs)

		local numAlchInputs = #sortedAlchInputs
		if numAlchInputs > mostAlchInputs then
			mostAlchInputs = numAlchInputs
		end

		reactionInfos[#reactionInfos + 1] = {
			item = item,
			bestCostCost = bestCostCost,
			bestTimeEfficientCost = bestTimeEfficientCost,
			bestCostTime = bestCostTime,
			bestTimeEfficientTime = bestTimeEfficientTime,
			sellPrice = sellPrice,
			sortedAlchInputs = sortedAlchInputs,
			alchemizeInput = alchemizeInput,
			inputVolume = volume,
			nonFuelBlockInputVolume = nonFuelBlockInputVolume
		}
	end
end

local complexF = io.open("outputs/reactions_complex.csv", "w")
complexF:write("item\tsellPrice\tslotTimeEfficientCost\tslotTimeEfficientTime\tslotTimeEfficientProfitPerSlotHour\tcheapestCost\tcheapestTime\tcheapestProfitPerSlotHour\tinputVolume\tinputVolumeWithoutFuelBlocks")
for i=1,mostAlchInputs do
	complexF:write("\talchInput"..i.."\talchType"..i)
end
complexF:write("\n")

for _,row in ipairs(reactionInfos) do
	local item = row.item

	complexF:write(row.item)
	complexF:write("\t")
	complexF:write(row.sellPrice)
	complexF:write("\t")
	complexF:write(row.bestTimeEfficientCost)
	complexF:write("\t")
	complexF:write(row.bestTimeEfficientTime)
	complexF:write("\t")
	complexF:write((row.sellPrice - row.bestTimeEfficientCost) * 3600.0 / row.bestTimeEfficientTime)
	complexF:write("\t")
	complexF:write(row.bestCostCost)
	complexF:write("\t")
	complexF:write(row.bestCostTime)
	complexF:write("\t")
	complexF:write((row.sellPrice - row.bestCostCost) * 3600.0 / row.bestCostTime)
	complexF:write("\t")
	complexF:write(row.inputVolume)
	complexF:write("\t")
	complexF:write(row.nonFuelBlockInputVolume)

	for i=1,mostAlchInputs do
		local inputItem = row.sortedAlchInputs[i]
		if inputItem == nil then
			complexF:write("\t\t")
		else
			complexF:write("\t")
			complexF:write(inputItem)
			complexF:write("\t")
			complexF:write(row.alchemizeInput[inputItem] or "never")
		end
	end
	complexF:write("\n")
end
