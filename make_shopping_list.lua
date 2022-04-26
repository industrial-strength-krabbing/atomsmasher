assert(loadfile("userdata/config.lua"))()

assert(config, "Config failed to load")


assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/dbtools.lua"))()
assert(loadfile("code/blueprints.lua"))()
assert(loadfile("code/common.lua"))()

local buildObjectivesDB = loadTabFile("userdata/build_objectives.csv", nil, ",")

local presetsDB = loadTabFile("userdata/build_objective_presets.csv", nil, ",")
	database.indexByMultiple(presetsDB, "preset")

local onHandInventory = loadTabFile("userdata/on_hand_inventory.csv", nil, ",")

local intermediateItemsDB = loadTabFile("userdata/items_intermediates.dat")
	database.indexByUnique(intermediateItemsDB, "item")

local blueprintCategoryDB = loadTabFile("data/cache/blueprints_categories.dat")
	database.indexByUnique(blueprintCategoryDB, "item")

local categoryReductionDB = loadTabFile("userdata/facility_reductions.dat")
	database.indexByUnique(categoryReductionDB, "category")

local inventionBlueprintsDB = loadTabFile("data/cache/blueprints_invention.dat")
    database.indexByUnique(inventionBlueprintsDB, "item")

local decryptorDB = loadTabFile("data/invention_decryptors.dat")

local blueprintQuantityDB = loadTabFile("data/cache/blueprints_multiple_quantity.dat")
    database.indexByUnique(blueprintQuantityDB, "item")

local datacoreSkillDB = loadTabFile("data/datacore_skills.dat" )
    database.indexByUnique(datacoreSkillDB, "item")

local reactionsDB = loadTabFile("data/cache/reactions.dat")
	database.indexByMultiple(reactionsDB, "item")

local reactionsPropertiesDB = loadTabFile("data/cache/reactions_properties.dat")
	database.indexByUnique(reactionsPropertiesDB, "item")

local alchemyReprocessDB = loadTabFile("data/cache/alchemy_reprocess.dat")
	database.indexByMultiple(alchemyReprocessDB, "item")

local alchemyParentDB = loadTabFile("data/cache/alchemy_parent.dat")
	database.indexByUnique(alchemyParentDB, "item")
	
local autoBuyDB = loadTabFile("userdata/items_autobuy.dat")
	database.indexByUnique(autoBuyDB, "item")

local intermediatesSourcingDB

if #autoBuyDB.rows > 0 then
	intermediatesSourcingDB = loadTabFile("outputs/intermediates.csv")
		database.indexByUnique(intermediatesSourcingDB, "item")
end

local bpdb = blueprints.load()

local function writeCompensatedItem(item, quantity, surplus, buildTime, outFile)
	outFile:write(item.."\t"..quantity)
	if config.showExpenditures then
		surplus = surplus or 0
		local expenditure = quantity - surplus
		if surplus == 0 then
			surplus = ""
		end
		outFile:write("\t"..surplus.."\t"..expenditure)
	end
	if config.showRecipeBuildTimes then
		outFile:write("\t")
		if buildTime then
			outFile:write(buildTime)
		end
	end
	outFile:write("\n")
end

local function IsAutoBuild(item)
	if not config.enableAutoBuild then
		return true
	end

	if intermediateItemsDB.keyBy.item[item] then
		if intermediatesSourcingDB ~= nil and autoBuyDB.keyBy.item[item] and intermediatesSourcingDB.keyBy.item[item].sourcing == "market" then
			return false
		end

		return true
	end

	return false
end

local function FindDependencies(tree, item, isPrimary)
	local deps = tree[item]
	if deps ~= nil then
		return deps
	end

	deps = { }
	tree[item] = deps
	if isPrimary or IsAutoBuild(item) then
		local blueprint = bpdb[item]
		local reaction = reactionsDB.keyBy.item[item]

		if blueprint ~= nil then
			for mat,quantity in pairs(blueprint.materials) do
				deps[mat] = FindDependencies(tree, mat)
			end
		elseif reaction ~= nil then
			if config.enableReactionsInShoppingLists then
				if config.alchemy[item]  then
					local parent = alchemyParentDB.keyBy.item[item].parent
					deps[parent] = FindDependencies(tree, parent)
				else
					for _,matRow in ipairs(reaction) do
						deps[matRow.material] = FindDependencies(tree, matRow.material)
					end
				end
			end
		else
			if isPrimary then
				print("Couldn't find materials for intermediate "..item)
			end
		end
	end

	return deps
end

local function PhaseItem(phases, tree, item, phase)
	local highestPhase = phase

	local currentPhase = phases[item]

	if currentPhase == nil or currentPhase < phase then
		phases[item] = phase
		local deps = tree[item]
		for dep in pairs(deps) do
			PhaseItem(phases, tree, dep, phase + 1)
		end
	end
end

local function main()
	local outFile = io.open("outputs/shopping_list.csv", "w")

	local itemDependencyTree = { }

	local buildObjectives = { }
	local buildObjectiveRequestedItems = { }
	local buildObjectiveME = { }
	local itemGranularity = { }

	for _,row in ipairs(buildObjectivesDB.rows) do
		if string.len(row.item) > 10 then
			if string.sub(row.item, -10, -1) == " Blueprint" then
				local oldName = row.item
				row.item = string.sub(row.item, 1, -11)
			end
		end
		local preset = presetsDB.keyBy.preset[row.item]
		if preset ~= nil then
			local presetQuantity = row.quantity
			for _,presetRow in ipairs(preset) do
				local me = presetRow.me
				if me == "defer" then
					me = buildObjectiveME[presetRow.item]
					if me == nil then
						assert(false, "Preset "..row.item.." input "..presetRow.item.." has ME listed as 'defer' but no ME was specified in the build objectives table!")
					end
				else
					buildObjectiveME[presetRow.item] = tonumber(me)
				end

				local granularity = presetRow.runsPerBlueprint
				if granularity == "defer" then
					granularity = itemGranularity[presetRow.item]
					if granularity == nil then
						assert(false, "Preset "..row.item.." input "..presetRow.item.." has runs per blueprint listed as 'defer' but no runs per blueprint was specified in the build objectives table!")
					end
				else
					itemGranularity[presetRow.item] = tonumber(granularity)
				end

				local importedRow =
				{
					item = assert(presetRow.item),
					quantity = presetRow.quantity * presetQuantity,
					me = assert(me),
					runsPerBlueprint = assert(granularity)
				}
				buildObjectives[#buildObjectives+1] = importedRow
				buildObjectiveRequestedItems[presetRow.item] = true
			end
		else
			buildObjectiveRequestedItems[row.item] = true
			buildObjectiveME[row.item] = tonumber(row.me)
			buildObjectives[#buildObjectives+1] = row

			itemGranularity[row.item] = tonumber(row.runsPerBlueprint)
		end
	end

	do
		local condemnedGranularity = { }
		for item,granularity in pairs(itemGranularity) do
			if granularity == 0 then
				condemnedGranularity[item] = true
			end
		end
		for item in pairs(condemnedGranularity) do
			itemGranularity[item] = nil
		end
		condemnedGranularity = nil
	end

	for _,row in ipairs(buildObjectives) do
		FindDependencies(itemDependencyTree, row.item, true)
	end

	local itemPhases = { }

	for _,row in ipairs(buildObjectives) do
		PhaseItem(itemPhases, itemDependencyTree, row.item, 1)
	end

	local numPhases = 0

	for item,phase in pairs(itemPhases) do
		if phase > numPhases then
			numPhases = phase
		end
	end

	local itemQuantities = { }

	for _,row in ipairs(buildObjectives) do
		local q = itemQuantities[row.item]
		if q == nil then
			q = 0
		end
		itemQuantities[row.item] = q + tonumber(row.quantity)
	end

	for _,row in ipairs(onHandInventory.rows) do
		local q = itemQuantities[row.item]
		if q == nil then
			q = 0
		end
		itemQuantities[row.item] = q - tonumber(row.quantity)
	end

	local leafItems = { }
	local itemsInPhases = { }
	local itemSurplus = { }
	local itemBuildTimes = { }

	for phase=1,numPhases do
		local itemsInPhase = { }

		for item,candidatePhase in pairs(itemPhases) do
			if candidatePhase == phase then
				itemsInPhase[#itemsInPhase + 1] = item
			end
		end

		itemsInPhases[phase] = itemsInPhase

		for _,item in ipairs(itemsInPhase) do
			local isRequestedOrIntermediate = (buildObjectiveRequestedItems[item] or IsAutoBuild(item))
			local quantity = itemQuantities[item]

			local itemIsNotLeaf = false

			if isRequestedOrIntermediate and quantity ~= nil and quantity > 0 then
				local blueprint = bpdb[item]
				local reactionMats = reactionsDB.keyBy.item[item]
				local reactionProps = reactionsPropertiesDB.keyBy.item[item]

				if blueprint then
					local blueprintME = 10
					if buildObjectiveRequestedItems[item] then
						blueprintME = assert(buildObjectiveME[item])
					elseif config.blueprintLevels[item] then
						blueprintME = assert(config.blueprintLevels[item].me)
					end

					local bpCategory = blueprintCategoryDB.keyBy.item[item].category
					local bpFacilityReduction = categoryReductionDB.keyBy.category[bpCategory].reduction

					blueprint = blueprint:Clone()
					blueprint.me = blueprintME
					blueprint:ApplyWaste(config.structureMatRoleBonus, bpFacilityReduction)

					if quantity ~= nil then
						local bpRuns = 0
						local blueprintQuantity = (blueprintQuantityDB.keyBy.item[item] or { quantity = 1 }).quantity
						if quantity > 0 then
							bpRuns = math.ceil(quantity / blueprintQuantity)
						end
						
						local blueprintGranularity = itemGranularity[item]
						local runsPerGranule = bpRuns
						local numGranules = 1

						if blueprintGranularity then
							numGranules = math.ceil(bpRuns / blueprintGranularity)
							runsPerGranule = blueprintGranularity
						end

						local newQuantity = numGranules * runsPerGranule * blueprintQuantity
						itemSurplus[item] = (itemSurplus[item] or 0) + (newQuantity - itemQuantities[item])
						itemQuantities[item] = newQuantity

						local mats = blueprint:GetMaterialsForRunCount(runsPerGranule)

						for mat,quantity in pairs(mats) do
							itemQuantities[mat] = (itemQuantities[mat] or 0) + quantity * numGranules
						end

						itemBuildTimes[item] = numGranules * runsPerGranule * blueprint.buildTime

						itemIsNotLeaf = true
					end
				elseif reactionMats and reactionProps and config.enableReactionsInShoppingLists then
					if config.alchemy[item] then
						local alchemyParent = alchemyParentDB.keyBy.item[item].parent
						local reprocess = alchemyReprocessDB.keyBy.item[alchemyParent]

						local foundAlchemyOutput = false

						local runsNeeded = nil
						local quantityProduced = nil
						for _,rp in ipairs(reprocess) do
							if rp.output == item then
								-- Reprocessing efficiency is applied after item count multiplication and rounded down.
								-- That means we need to round the runs needed up.
								local reprocessedQuantity = rp.quantity * config.scrapmetalReprocessingEfficiency / 100.0
								runsNeeded = math.ceil(quantity / reprocessedQuantity)
								quantityProduced = math.floor(runsNeeded * reprocessedQuantity)
								break
							end
						end

						if runsNeeded then
							itemSurplus[item] = (itemSurplus[item] or 0) + (quantityProduced - itemQuantities[item])
							itemQuantities[item] = 0	-- Completely replace it
							itemQuantities[alchemyParent] = (itemQuantities[alchemyParent] or 0) + runsNeeded

							for _,rp in ipairs(reprocess) do
								if rp.output ~= item then
									local reprocessedQuantity = math.floor(runsNeeded * rp.quantity * config.scrapmetalReprocessingEfficiency / 100.0)
									itemSurplus[rp.output] = (itemSurplus[rp.output] or 0) + reprocessedQuantity
								end
							end

							itemIsNotLeaf = true
						end
					elseif reactionMats then
						local reactionOutputQuantity = reactionProps.outputQuantity
						local reactionRuns = math.ceil(quantity / reactionProps.outputQuantity)

						local newQuantity = reactionProps.outputQuantity * reactionRuns
						itemSurplus[item] = (itemSurplus[item] or 0) + (newQuantity - itemQuantities[item])
						itemQuantities[item] = newQuantity

						for _,matRow in ipairs(reactionMats) do
							local numRequired = math.ceil(reactionRuns * matRow.quantity * (100 - config.structureReactionMatReduction) / 100)
							if numRequired < reactionRuns then
								numRequired = reactionRuns
							end

							local mat = matRow.material
							itemQuantities[mat] = (itemQuantities[mat] or 0) + numRequired
						end

						itemBuildTimes[item] = reactionRuns * reactionProps.time

						itemIsNotLeaf = true
					end
				end
			end
			
			if not itemIsNotLeaf then
				leafItems[item] = true
			end
		end
	end

	outFile:write("item\tquantity")
	if config.showExpenditures then
		outFile:write("\tsurplus\texpenditure")
	end
	if config.showRecipeBuildTimes then
		outFile:write("\tbuildTime")
	end
	outFile:write("\n")
	for phase=1,numPhases do
		local itemsInPhase = itemsInPhases[phase]
		table.sort(itemsInPhase)
		for _,item in ipairs(itemsInPhase) do
			if leafItems[item] == nil then
				if itemQuantities[item] and itemQuantities[item] > 0 then
					writeCompensatedItem(item, itemQuantities[item], itemSurplus[item], itemBuildTimes[item], outFile)
				end
			end
		end

		outFile:write("\n")
	end

	local leafItemsSorted = { }
	for item in pairs(leafItems) do
		leafItemsSorted[#leafItemsSorted + 1] = item
	end

	table.sort(leafItemsSorted)
	
	local surplusItemsSorted = { }
	for item in pairs(itemSurplus) do
		surplusItemsSorted[#surplusItemsSorted + 1] = item
	end

	table.sort(surplusItemsSorted)

	for _,item in ipairs(leafItemsSorted) do
		if itemQuantities[item] and itemQuantities[item] > 0 then
			writeCompensatedItem(item, itemQuantities[item], itemSurplus[item], nil, outFile)
		end
	end

	local anySurplus = false

	for _,item in ipairs(surplusItemsSorted) do
		if itemSurplus[item] and itemSurplus[item] > 0 then
			if not anySurplus then
				anySurplus = true

				outFile:write("\nSurplus and recovery:\n\n")
			end
			outFile:write(item.."\t-"..itemSurplus[item].."\n")
		end
	end

	outFile:close()
end

main()