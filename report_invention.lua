assert(loadfile("userdata/config.lua"))()

assert(config, "Config failed to load")

assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/dbtools.lua"))()
assert(loadfile("code/blueprints.lua"))()
assert(loadfile("code/common.lua"))()
assert(loadfile("code/sci.lua"))()
assert(loadfile("code/eiv.lua"))()

local inventableDB = loadTabFile("userdata/items_inventables.dat")
local inventionBlueprintsDB = loadTabFile("data/cache/blueprints_invention.dat")
    database.indexByUnique(inventionBlueprintsDB, "item")
local decryptorDB = loadTabFile("data/invention_decryptors.dat")

local blueprintQuantityDB = loadTabFile("data/cache/blueprints_multiple_quantity.dat")
    database.indexByUnique(blueprintQuantityDB, "item")

local datacoreSkillDB = loadTabFile("data/datacore_skills.dat" )
    database.indexByUnique(datacoreSkillDB, "item")

local blueprintCategoryDB = loadTabFile("data/cache/blueprints_categories.dat")
	database.indexByUnique(blueprintCategoryDB, "item")

local categoryReductionDB = loadTabFile("userdata/facility_reductions.dat")
	database.indexByUnique(categoryReductionDB, "category")

local priceTable = database.convertToDict(loadTabFile("data/cache/items_marketprices.dat"), "item", "price")

local bpdb = blueprints.load()

local exchangeReport = io.open("outputs/exchange.csv", "w")
exchangeReport:write('"item","BPC Value","BPC Profit","Kit Value","Kit Profit","CPU Management V","Power Grid Management V","Mechanics V","Skill 1","Skill 2","Build Time"\n')

local function formatTime(seconds)
	local days = math.floor(seconds / 86400)
	seconds = math.fmod(seconds, 86400)
	local hours = math.floor(seconds / 3600)
	seconds = math.fmod(seconds, 3600)
	local minutes = math.floor(seconds / 60)
	seconds = math.floor(math.fmod(seconds, 60))

	if days > 0 then
		return days.."d "..hours.."h "..minutes.."m "..seconds.."s"
	end
	if hours > 0 then
		return hours.."h "..minutes.."m "..seconds.."s"
	end
	if minutes > 0 then
		return minutes.."m "..seconds.."s"
	end
	return seconds.."s"
end

local function roundToHundredth(n)
	return math.floor(n*100+0.5)/100
end

local function roundTo10k(n)
	return math.floor(n/10000+0.5)*10000
end

local function padNumber(n)
	if(n >= 100) then return n end
	if(n >= 10) then return "0"..n end
	return "00"..n
end

local function formatNumber(n, suffix)
	n = tonumber(n)
	if suffix == nil then
		suffix = ""
	else
		suffix = " "..suffix
	end
	local negate = false
	if n < 0 then
		negate = true
		n = -n
	end
	n = roundToHundredth(n)

	local result = ""
	local high = math.floor(n / 1000)
	local low = roundToHundredth(n % 1000)

	while high > 0 do
		result = ","..padNumber(low)..result
		low = roundToHundredth(high % 1000)
		high = math.floor(high / 1000)
	end
	result = low..result..suffix
	if negate then
		result = "<span style='color:red'>-"..result.."</span>"
	end
	return result
end

local NUM_COLUMNS	= 11

local numIDs = 0
local function newID()
	numIDs = numIDs + 1
	return "docObject_"..numIDs
end

local function skillMaskForInvention(invention)
	local masks = { invention.inventionDatacores[1].item, invention.inventionDatacores[2].item }
	local reqs = { Electronics = '"No"', Engineering = '"No"', Mechanic = '"No"' }

	for _,mask in ipairs(masks) do
		for skillName in pairs(reqs) do
			if datacoreSkillDB.keyBy.item[mask][skillName] == 1 then
				reqs[skillName] = '"Yes"'
			end
		end
	end

	if masks[1] > masks[2] then
		masks = { masks[2], masks[1] }
	end

	return reqs.Electronics..","..reqs.Engineering..","..reqs.Mechanic..',"'..string.sub(masks[1], 12)..'","'..string.sub(masks[2], 12)..'"'
end

local function dumpTime(outFile, params, exportToCSV)
	local psh = function(time)
		if time == 0 then
			return "No activity"
		else
			return formatNumber(params.profit * 3600 / time, "ISK").." per slot-hour"
		end
	end

	local buildTime = params.inventedBP.buildTime
	local componentTime = params.inventedBP:ComponentConstructionTime(bpdb)
	local totalBuildTime = buildTime + componentTime

	local copyTime = 0
	if params.baseBP then
		copyTime = params.baseBP.copyTime * params.parameters.baseRuns / params.t2runsPerAttempt
	end
	local inventTime = params.invention.inventTime / params.t2runsPerAttempt

	local totalTime = totalBuildTime + copyTime + inventTime
	local researchFrac = (copyTime+inventTime) / totalTime
	local componentFrac = componentTime / totalTime

	local bpcValue = (params.profit*researchFrac + params.inventCostPerRun) * params.inventedBP.runs
	local componentKitValue = (params.profit*researchFrac + params.inventCostPerRun + params.buildCost) * params.inventedBP.runs
	local kitValue = bpcValue + (params.profit*componentFrac + params.buildCost) * params.inventedBP.runs
	local kitMarketValue = priceTable[params.item] * params.inventedBP.runs * (blueprintQuantityDB.keyBy.item[params.item] or { quantity = 1 }).quantity

	if exportToCSV then
		local roundedBPCValue = roundTo10k(bpcValue)
		local roundedKitValue = roundTo10k(kitValue)
		local bpcProfit = roundedBPCValue - (params.inventCostPerRun * params.inventedBP.runs)
		local kitProfit = kitMarketValue - roundedKitValue

		local skillReqs = skillMaskForInvention(params.invention)
		exchangeReport:write('"'..params.item..'",'..roundedBPCValue..","..bpcProfit..","..roundedKitValue..","..kitProfit..","..skillReqs..","..(params.inventedBP.buildTime*params.inventedBP.runs).."\n")
	end

	local bpcRuns = params.inventedBP.runs
	local bpcRunSuffix = bpcRuns and " run" or "runs"

	outFile:write("<table>")
	  outFile:write("<tr>")
	    outFile:write("<td colspan='4'><b>Exchange Fees and Prices:</b></td>")
	  outFile:write("<tr>")
	  outFile:write("<tr>")
	    outFile:write("<td>BPC ("..bpcRuns..bpcRunSuffix.."):</td><td>"..formatNumber(bpcValue).."</td>")
	  outFile:write("</tr>")
	  outFile:write("<tr>")
	    outFile:write("<td>Component kit:</td><td>"..formatNumber(componentKitValue).."</td>")
	  outFile:write("</tr>")
	  outFile:write("<tr>")
	    outFile:write("<td>Ready-to-go kit:</td><td>"..formatNumber(kitValue).."</td>")
	  outFile:write("</tr>")
	outFile:write("</table>")

	outFile:write("<table>")
	  outFile:write("<tr>")
	    outFile:write("<td colspan='4'><b>Construction Slot Efficiency</b></td>")
	  outFile:write("<tr>")
	  outFile:write("</tr>")
	    outFile:write("<td>Item alone</td><td>"..formatTime(buildTime).."</td><td> &nbsp; </td><td>"..psh(buildTime).."</td>")
	  outFile:write("</tr>")
	  outFile:write("<tr>")
	    outFile:write("<td>Item + components</td><td>"..formatTime(totalBuildTime).."</td><td> &nbsp; </td><td>"..psh(totalBuildTime).."</td>")
	  outFile:write("</tr>")
	  outFile:write("<tr>")
	    outFile:write("<td colspan='4'><b>Research Slot Efficiency (per produced unit)</b></td>")
	  outFile:write("<tr>")
	  outFile:write("<tr>")
	    outFile:write("<td>Copy (P/U)</td><td>"..formatTime(copyTime).."</td><td> &nbsp; </td><td>"..psh(copyTime).."</td>")
	  outFile:write("</tr>")
	  outFile:write("<tr>")
	    outFile:write("<td>Invention (P/U)</td><td>"..formatTime(inventTime).."</td><td> &nbsp; </td><td>"..psh(inventTime).."</td>")
	  outFile:write("</tr>")
	  outFile:write("<tr>")
	    outFile:write("<td>All research (P/U)</td><td>"..formatTime(copyTime+inventTime).."</td><td> &nbsp; </td><td>"..psh(copyTime+inventTime).."</td>")
	  outFile:write("</tr>")
	outFile:write("</table>")

end

local function dumpCostBreakdown(outFile, params, exportToCSV)
	local buttonID = newID()
	local breakdownTableID = newID()

	outFile:write("<form>\n")
	outFile:write("<input type='button' id='"..buttonID.."' value='Show Breakdown' onClick='toggleBreakdown(\""..buttonID.."\", \""..breakdownTableID.."\")'/>\n")
	outFile:write("<div id='"..breakdownTableID.."' style='visibility:hidden;position:absolute;display:inline'>\n")

	dumpTime(outFile, params, exportToCSV)

	outFile:write("<table>")
	  outFile:write("<tr>")
	    outFile:write("<td colspan='5'><b>Invention Expenses</b></td>")
	  outFile:write("</tr>")

	-- Dump datacore breakdown
	bpdb[params.item]:DumpInventionExpenses(outFile, priceTable, formatNumber, params)
	outFile:write("</table>")

	outFile:write("<table>")
	outFile:write("<tr>")
	  outFile:write("<td colspan='5'><b>Material Expenses</b></td>")
	outFile:write("</tr>")

	params.inventedBP:DumpMaterialExpenses(outFile, priceTable, formatNumber, params)
	outFile:write("</table>")

	outFile:write("<table>")
	outFile:write("<tr>")
	  outFile:write("<td colspan='5'><b>Total expense rundown:</b></td>")
	outFile:write("</tr>")


	local bpQuantity = blueprintQuantityDB.keyBy.item[params.item]

	outFile:write("<tr><td>Market value:</td><td></td><td>"..formatNumber(priceTable[params.item]).."</td></tr>")

	if bpQuantity ~= nil then
		outFile:write("<tr><td>x "..bpQuantity.quantity.."</td><td>=</td><td>"..formatNumber(priceTable[params.item] * bpQuantity.quantity).."</td></tr>")
	end

	outFile:write("<tr>")
	  outFile:write("<td>Invention cost:</td><td>-</td><td>"..formatNumber(params.inventCostPerRun).."</td>")
	outFile:write("</tr>")
	outFile:write("<tr>")
	  outFile:write("<td>Material cost:</td><td>-</td><td>"..formatNumber(params.buildCost).."</td>")
	outFile:write("</tr>")
	outFile:write("<tr>")
	  outFile:write("<td>Profit:</td><td></td><td>"..formatNumber(params.profit).."</td>")
	outFile:write("</tr>")


	outFile:write("</table>")
	outFile:write("</div>\n")
	outFile:write("</form>\n")
end

local function dumpParams(outFile, caption, params, exportToCSV)
	local bpQuantityRow = blueprintQuantityDB.keyBy.item[params.item]
	local bpQuantity = 1
	if bpQuantityRow ~= nil then
		bpQuantity = bpQuantityRow.quantity
	end

	outFile:write("<tr>")
	outFile:write("<td>"..caption.."</td>")
	outFile:write("<td>"..formatNumber(params.profit / bpQuantity).."</td>")
	outFile:write("<td>"..formatNumber(params.profitPerCopy).."</td>")
	outFile:write("<td>"..formatNumber(params.profitPerBuild).."</td>")
	outFile:write("<td>"..formatNumber(params.totalProfit).."</td>")
	outFile:write("<td>"..params.inventedBP.runs.."</td>")
	outFile:write("<td>"..params.t2runsPerAttempt.."</td>")
	outFile:write("<td>"..params.inventedBP.chance.."</td>")
	outFile:write("<td>"..formatNumber(params.inventCostPerRun).."</td>")
	outFile:write("<td>"..formatNumber(params.buildCost).."</td>")
	outFile:write("<td>"..params.parameters.decryptor.item.."</td>")
	if params.invention.class == "loose" then
		outFile:write("<td>"..params.invention.inventedFrom.."</td>")
	end
	outFile:write("</tr>")

	outFile:write("<tr><td colspan="..NUM_COLUMNS..">")
	dumpCostBreakdown(outFile, params, exportToCSV)

	outFile:write("</td></td>")
end

local function processInventable(outFile, outTable, item)
	local bpData = inventionBlueprintsDB.keyBy.item[item]
	assert(bpData, "Could not find invention properties for "..item)
	local decryptors = decryptorDB.rows
	local t2bp = bpdb[item]
	local inventions = t2bp.inventions

	local bpCategory = blueprintCategoryDB.keyBy.item[item].category
	if bpCategory == nil then
		print("Unknown category: "..item)
	end
	if categoryReductionDB.keyBy.category[bpCategory] == nil then
		print("No facility reduction defined for "..bpCategory)
	end
	local bpFacilityReduction = categoryReductionDB.keyBy.category[bpCategory].reduction

	local structureMatRoleBonus = config.structureMatRoleBonus

	if not config.reportFacilityBonuses then
		structureMatRoleBonus = 0
		bpFacilityReduction = 0
	end

	local core1skill
	local core2skill
	local encryptionSkill

	if config.neverUseDecryptors then
		decryptors = {
			{
				item = "No Decryptor",
				runsModifier = 0,
				probModifier = 1,
				meModifier = 0,
				peModifier = 0,
			}
		}
	end

	local bestProfitByUnit = nil
	local bestProfitByInvention = nil
	local bestProfitByManufacturing = nil
	local manufacturingSCI = sci.Find("manufacturing", item)
	local inventionSCI = sci.FindInvention(item)

	for _,invention in ipairs(inventions) do
		do
			local coreItems = { invention.inventionDatacores[1].item, invention.inventionDatacores[2].item }
			local assocTable = config.inventionSkills
			local skillLevels = { assocTable[coreItems[1]], assocTable[coreItems[2]] }

			assert(skillLevels[1], "Unknown skill "..coreItems[1])
			assert(skillLevels[2], "Unknown skill "..coreItems[2])
			
			encryptionSkill = assocTable[bpData.encryptionSkill]
			assert(encryptionSkill, "Unknown encryption skill "..tostring(bpData.encryptionSkill))

			core1skill = skillLevels[1]
			core2skill = skillLevels[2]
		end

		for _,decryptor in ipairs(decryptors) do
			local t1bp = bpdb[invention.inventedFrom]

			local inventionCost = invention:InventionCost(priceTable)
			if inventionCost ~= nil then	-- Relic isn't available
				local attemptCost = invention:InventionCost(priceTable) + invention:InventionInstallCost(inventionSCI) + (priceTable[decryptor.item] or 0)

				local baseRuns=1

				assert(core1skill)
				assert(core2skill)
				local inventParams = blueprints.inventionParameters(baseRuns, t1bp, decryptor, encryptionSkill, core1skill, core2skill, 0)
				local t2bpRuns = invention:InventionRuns(inventParams)

				assert(structureMatRoleBonus)

				local inventedBP = t2bp:Invent(invention, inventParams, structureMatRoleBonus, bpFacilityReduction)
				local buildCost = (inventedBP:ConstructionCost(priceTable, inventedBP.runs) + inventedBP:ManufacturingInstallCost(inventedBP.runs, manufacturingSCI)) / inventedBP.runs
				local inventCost = (attemptCost / inventedBP.chance) / inventedBP.runs
				local totalCost = buildCost + inventCost
				local bpQuantity = blueprintQuantityDB.keyBy.item[item]
				if bpQuantity == nil then
					bpQuantity = 1
				else
					bpQuantity = bpQuantity.quantity
				end

				if priceTable[item] == nil then
					print("Could not compute profit for "..item.." because its price wasn't available")
					return
				end

				local profit = priceTable[item] * bpQuantity - totalCost

				local unitsProduced = inventedBP.runs * inventedBP.chance
				local profitPerCopy = profit * unitsProduced / baseRuns
				local totalProfit = profit * unitsProduced

				local theseParams = {
					item = item,
					profit = profit,
					totalProfit = totalProfit,
					profitPerCopy = profitPerCopy,
					profitPerBuild = profit * inventedBP.runs,
					inventCostPerRun = inventCost,
					buildCost = buildCost,
					t2runsPerAttempt = inventedBP.runs * inventedBP.chance,
					parameters = inventParams,
					inventedBP = inventedBP,
					baseBP = t1bp,
					invention = invention,
					manufacturingSCI = manufacturingSCI,
					inventionSCI = inventionSCI,
				}

				-- See if this is tolerable
				local threshold = 0
				local copyTime = 0
				local t1buildTime = 0
				if t1bp ~= nil then
					local buildTime = inventedBP.buildTime
					copyTime = t1bp.copyTime * baseRuns / inventedBP.runs / inventedBP.chance

					threshold = (copyTime / buildTime)
					t1buildTime = t1bp.buildTime
				end

				theseParams.copyToBuildRatio = threshold

				local compete = function(candidate, field)
					local comparison = theseParams[field]

					if candidate == nil then
						return true
					end
					if comparison > 0 and candidate[field] <= 0 then
						return true	-- Profitable, candidate isn't
					end
					if comparison <= 0 and candidate[field] > 0 then
						return false	-- Not profitable, current is
					end

					if threshold < config.maximumCopyToBuildRatio then
						if candidate.copyToBuildRatio < config.maximumCopyToBuildRatio then
							-- Both are valid, compete on price
							return (candidate[field] < comparison)
						else
							return true	-- This one's under threshold, old one isn't
						end
					else
						if candidate.copyToBuildRatio < config.maximumCopyToBuildRatio then
							return false	-- Existing one's under the limit, this one isn't
						else
							-- Neither is, try to get closer
							return (candidate.copyToBuildRatio > threshold)
						end
					end
				end

				if compete(bestProfitByUnit, "profit") then
					bestProfitByUnit = theseParams
				end

				if compete(bestProfitByManufacturing, "profitPerBuild") then
					bestProfitByManufacturing = theseParams
				end

				if compete(bestProfitByInvention, "totalProfit") then
					bestProfitByInvention = theseParams
				end

				outTable:write(item)
				outTable:write("\t")
				outTable:write(decryptor.item)
				outTable:write("\t")
				outTable:write(invention.inventedFrom)
				outTable:write("\t")
				outTable:write(profit)
				outTable:write("\t")
				outTable:write(totalProfit)
				outTable:write("\t")
				outTable:write(inventCost)
				outTable:write("\t")
				outTable:write(buildCost)
				outTable:write("\t")
				outTable:write(priceTable[item])
				outTable:write("\t")
				outTable:write(inventedBP.runs)
				outTable:write("\t")
				outTable:write(inventedBP.chance)
				outTable:write("\t")
				outTable:write(inventedBP.buildTime)
				outTable:write("\t")
				outTable:write(inventedBP:ComponentConstructionTime(bpdb))
				outTable:write("\t")
				outTable:write(copyTime)
				outTable:write("\t")
				outTable:write(invention.inventTime)
				outTable:write("\n")
			end
		end
	end

	outFile:write("<table>")
	outFile:write("<tr><td><b>Item:</b></td><td colspan='"..NUM_COLUMNS.."'>"..item.."</td></tr>")
	outFile:write("<tr><td><b>Market value:</b></td><td>"..formatNumber(priceTable[item], "ISK").."</td></tr>")

	if bestProfitByUnit == nil then
		outFile:write("<tr><td>No base item price available!</td></tr>")
	else
		-- Fix me: This is stupid
		local class = bestProfitByUnit.invention.class

		outFile:write("<tr><td></td><td>Profit/unit</td><td>Profit/BPO copy</td><td>Profit/BPC</td><td>Profit/invention attempt</td><td>Runs</td><td>Runs per attempt</td><td>Success rate</td><td>Invention cost</td><td>Build cost</td><td>Decryptor</td>")
		if class == "loose" then
			outFile:write("<td>Base item</td>")
		end
		outFile:write("</tr>")
		if bestProfitByUnit == bestProfitByInvention and bestProfitByUnit == bestProfitByManufacturing then
			dumpParams(outFile, "High universal", bestProfitByUnit, true)
		else
			if bestProfitByUnit == bestProfitByInvention then
				dumpParams(outFile, "High per unit produced<br/>High per invention attempt", bestProfitByUnit, true)
				dumpParams(outFile, "", bestProfitByInvention, false)
			elseif bestProfitByUnit == bestProfitByManufacturing then
				dumpParams(outFile, "High per unit produced<br/>High per manufacturing job", bestProfitByUnit, true)
				dumpParams(outFile, "High per invention attempt", bestProfitByInvention, false)
			elseif bestProfitByInvention == bestProfitByManufacturing then
				dumpParams(outFile, "High per unit produced", bestProfitByUnit, true)
				dumpParams(outFile, "High per invention attempt<br/>High per manufacturing job", bestProfitByInvention, false)
			else
				dumpParams(outFile, "High per unit produced", bestProfitByUnit, true)
				dumpParams(outFile, "High per invention attempt", bestProfitByInvention, false)
				dumpParams(outFile, "High per manufacturing job", bestProfitByManufacturing, false)
			end
		end
	end

	outFile:write("</table>")
	outFile:write("<hr/>")
end

local function dumpJavascript(outFile)
	outFile:write("<script type='text/javascript'>\n")
	outFile:write([[
function toggleBreakdown(buttonID, divID)
{
	var buttonElement = document.getElementById(buttonID);
	var divElement = document.getElementById(divID);

	if(divElement.visible)
	{
		buttonElement.value = "Show Breakdown"
		divElement.visible = false
		divElement.style.visibility = "hidden"
		divElement.style.display = "inline"
		divElement.style.position = "absolute"
	}
	else
	{
		buttonElement.value = "Hide Breakdown"
		divElement.visible = true
		divElement.style.visibility = "visible"
		divElement.style.display = "block"
		divElement.style.position = "relative"
	}
}
]])
	outFile:write("</script>\n")

end

local function dumpPriceTable(outFile)
	local buttonID = newID()
	local priceTableID = newID()

	outFile:write("<form>\n")
	outFile:write("<input type='button' id='"..buttonID.."' value='Show Master Price Table' onClick='toggleBreakdown(\""..buttonID.."\", \""..priceTableID.."\")'/>\n")
	outFile:write("<div id='"..priceTableID.."' style='visibility:hidden;position:absolute;display:inline'>\n")

	outFile:write("<table><tr><td colspan='2'><b>Master price table</b></td></tr>")

	local itemsList = { }

	for itemName,_ in pairs(priceTable) do
		itemsList[#itemsList+1] = itemName
	end

	table.sort(itemsList)

	for _,itemName in ipairs(itemsList) do
		outFile:write("<tr><td>"..itemName.."</td><td> = </td><td>"..formatNumber(priceTable[itemName], "ISK").."</td></tr>")
	end


	outFile:write("</table></div></form>")
end

local function main()
	local outTable = io.open("outputs/invention.csv", "w")
	outTable:write("item\tdecryptor\tbaseItem\tprofitPerManufacturingRun\tprofitPerT2Blueprint\tinventCost\tbuildCost\tmarketValue\tinventedBPRuns\tinventionSuccessRate\tbuildTime\tcomponentBuildTime\tsingleCopyTime\tinventTime\n")	

	local outFile = io.open("outputs/invention.html", "w")

	-- Write header
	outFile:write("<html>")
	outFile:write("<head>")
	outFile:write("<style type='text/css'>")
	outFile:write("body { font-size: 75% }\n")
	outFile:write("td { font-size: 75% }\n")
	outFile:write("input { font-size: 75% }\n")
	outFile:write("</style>")
	outFile:write("<title>Invention data report</title>")
	dumpJavascript(outFile)
	outFile:write("</head>")
	outFile:write("<body>")

	outFile:write("<h2><b>Maximum copy:build time ratio: "..config.maximumCopyToBuildRatio.."</b></h2>")

	outFile:write("<h2><b>Downloaded market price table</b></h2>")
	dumpPriceTable(outFile)

	outFile:write("<h2><b>Invention report</b></h2>")
	for _,row in ipairs(inventableDB.rows) do
		processInventable(outFile, outTable, row.item)
	end

	outFile:write("</body>")
	outFile:write("</html>")
	outFile:close()

	outTable:close()
end

main()