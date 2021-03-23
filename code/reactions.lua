local reactionsDB = loadTabFile("data/cache/reactions.dat")
	database.indexByMultiple(reactionsDB, "item")

local reactionsPropertiesDB = loadTabFile("data/cache/reactions_properties.dat")
	database.indexByUnique(reactionsPropertiesDB, "item")

local alchemyReprocessDB = loadTabFile("data/cache/alchemy_reprocess.dat")
	database.indexByMultiple(alchemyReprocessDB, "item")

local alchemyParentDB = loadTabFile("data/cache/alchemy_parent.dat")
	database.indexByUnique(alchemyParentDB, "item")

reactions =
{
	computeBaseItemCost = function(item, priceTable)
		local reactionMats = reactionsDB.keyBy.item[item]
		local eiv = 0.0
		for _,matRow in ipairs(reactionMats) do
			eiv = eiv + matRow.quantity * priceTable[matRow.material]
		end
		return eiv
	end,
	react = function(item, runs)
		local reactionMats = reactionsDB.keyBy.item[item]
		local reactionProps = reactionsPropertiesDB.keyBy.item[item]

		if reactionMats == nil or reactionProps == nil then
			return
		end

		local reactionOutputQuantity = reactionProps.outputQuantity

		local inputs = { }

		for _,matRow in ipairs(reactionMats) do
			local numRequired = math.ceil(runs * matRow.quantity * (100 - config.structureReactionMatReduction) / 100)
			if numRequired < runs then
				numRequired = runs
			end

			inputs[matRow.material] = numRequired
		end

		return { inputs = inputs, outputQuantity = reactionProps.outputQuantity * runs, time = reactionProps.time * runs, category = reactionProps.category }
	end,

	alchemyUnrefinedItemFor = function(item)
		local alchemyParentRow = alchemyParentDB.keyBy.item[item]
		if alchemyParentRow == nil then
			return nil
		end

		return alchemyParentRow.parent
	end,

	alchemyRunsForItem = function(item, quantity)
		local alchemyParentRow = alchemyParentDB.keyBy.item[item]
		if alchemyParentRow == nil then
			return nil
		end

		local alchemyParent = alchemyParentRow.parent
		local reprocess = alchemyReprocessDB.keyBy.item[alchemyParent]

		for _,rp in ipairs(reprocess) do
			if rp.output == item then
				-- Reprocessing efficiency is applied after item count multiplication and rounded down.
				-- That means we need to round the runs needed up.
				local reprocessedQuantity = rp.quantity * config.scrapmetalReprocessingEfficiency / 100.0
				return math.ceil(quantity / reprocessedQuantity)
			end
		end

		return nil
	end,

	alchemyReprocessUnrefined = function(item, quantity)
		local reprocessRows = alchemyReprocessDB.keyBy.item[item]

		local result = { }

		for _,rp in ipairs(reprocessRows) do
			result[rp.output] = math.floor(rp.quantity * config.scrapmetalReprocessingEfficiency * quantity / 100.0)
		end

		return result
	end,
}
