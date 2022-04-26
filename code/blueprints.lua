local function nilzero(n)
	if n == 0 then
		return nil
	end
	return n
end

local createBlueprint

local bpMeta
local inventionMeta

local baseItemUnavailableWarnings =  { }

inventionMeta = {
	__index = {
		InventionCost = function(self, priceTable)
			local cost = 0
			for _,coreItem in pairs(self.inventionDatacores) do
				cost = cost + priceTable[coreItem.item] * coreItem.quantity
			end
			assert(self.class)
			if self.class == "loose" then
				if priceTable[self.inventedFrom] == nil then
					if not baseItemUnavailableWarnings[self.inventedFrom] then
						print("WARNING: No price available for "..self.inventedFrom)
						baseItemUnavailableWarnings[self.inventedFrom] = true
					end
					return nil
				end
				cost = cost + priceTable[self.inventedFrom]
			end
			return cost
		end,
		InventionInstallCost = function(self, sci)
			local eiv = 0.0
			for _,coreItem in pairs(self.inventionDatacores) do
				eiv = eiv + (eivPriceTable[coreItem.item] or 0) * coreItem.quantity
			end
			local costFactor = (1.0 - config.structureInventionCostReductionRig / 100.0) * (1.0 - config.structureInventionCostReductionRoleBonus / 100.0) * (1.0 + config.structureInventionTax / 100.0)
			return eiv * sci * costFactor
		end,
		InventionRuns = function(self, params)
			return assert(self.inventRuns) + assert(params.decryptor.runsModifier)
		end,
	}
}

bpMeta = {
	__index = {
		DumpMaterialExpenses = function(self, outFile, priceTable, formatNumber, params)
			local cost = 0
			for item,quantity in pairs(self.materials) do
				local totalQuantity = math.ceil(quantity * params.inventedBP.runs)
				if priceTable[item] == nil then
					outFile:write("<tr><td>"..item.."</td>"
						.."<td>UNKNOWN PRICE</td>"
						.."<td>x</td>"
						.."<td>"..formatNumber(totalQuantity).."</td>"
						.."<td></td>"
						.."<td></td>"
						.."<td>...</td><td>"..formatNumber(cost).."</td></tr>")
				else
					cost = cost + priceTable[item] * totalQuantity
					outFile:write("<tr><td>"..item.."</td>"
						.."<td>"..formatNumber(priceTable[item]).."</td>"
						.."<td>x</td>"
						.."<td>"..formatNumber(totalQuantity).."</td>"
						.."<td>=</td>"
						.."<td>"..formatNumber(priceTable[item] * totalQuantity).."</td>"
						.."<td>...</td><td>"..formatNumber(cost).."</td></tr>")
				end
			end

			local sci = sci.Find("manufacturing", self.item)

			local eiv = 0.0
			for item,quantity in pairs(self.eivMaterials) do
				eiv = eiv + (eivPriceTable[item] or 0) * quantity
			end

			local jobCost = self:ManufacturingInstallCost(params.inventedBP.runs, params.manufacturingSCI)

			cost = cost + jobCost

			outFile:write("<tr><td>Manufacturing Job Install Fee</td>"
				.."<td></td>"
				.."<td></td>"
				.."<td></td>"
				.."<td>=</td>"
				.."<td>"..formatNumber(jobCost).."</td>"
				.."<td>...</td><td>"..formatNumber(cost).."</td></tr>")

			outFile:write("<tr><td colspan='4'></td><td>Total:</td><td>"..formatNumber(cost).."</td></tr>")
			outFile:write("<tr><td colspan='4'></td><td>/ "..params.inventedBP.runs.." runs :</td><td>"..formatNumber(cost / params.inventedBP.runs).."</td></tr>")
			return cost / params.inventedBP.runs
		end,
		ConstructionCost = function(self, priceTable, runs)
			local cost = 0
			for item,quantity in pairs(self.materials) do
				if priceTable[item] == nil then
					print("WARNING: No price for item: "..item)
				else
					cost = cost + priceTable[item] * math.ceil(quantity * runs)
				end
			end
			return cost
		end,
		ManufacturingInstallCost = function(self, runs, sci)
			local eiv = 0.0
			for item,quantity in pairs(self.eivMaterials) do
				eiv = eiv + (eivPriceTable[item] or 0) * quantity
			end

			local costFactor = (1.0 - config.structureManufacturingCostReduction / 100.0) * (1.0 + config.structureManufacturingTax / 100.0)
			return eiv * runs * sci * costFactor
		end,
		ComponentConstructionTime = function(self, bpdb)
			local totalTime = 0
			for item,quantity in pairs(self.materials) do
				if bpdb[item] then
					totalTime = totalTime + bpdb[item].buildTime * quantity
				end
			end
			return totalTime
		end,
		DumpInventionExpenses = function(self, outFile, priceTable, formatNumber, params)
			local chance = params.inventedBP.chance
			local t2runs = params.inventedBP.runs
			local decryptor = params.parameters.decryptor.item
			local invention = params.invention
			local inventedFrom = params.invention.inventedFrom

			local cost = 0
			for _,coreItem in pairs(invention.inventionDatacores) do
				cost = cost + priceTable[coreItem.item] * coreItem.quantity
				outFile:write("<tr><td>"..coreItem.item.."</td>"
					.."<td>"..formatNumber(priceTable[coreItem.item]).."</td>"
					.."<td>x</td>"
					.."<td>"..formatNumber(coreItem.quantity).."</td>"
					.."<td>=</td>"
					.."<td>"..formatNumber(priceTable[coreItem.item] * coreItem.quantity).."</td>"
					.."<td>...</td><td>"..formatNumber(cost).."</td></tr>")
			end

			if decryptor ~= "No Decryptor" then
				cost = cost + priceTable[decryptor]
				outFile:write("<tr><td>"..decryptor.."</td>"
					.."<td>"..formatNumber(priceTable[decryptor]).."</td>"
					.."<td>x</td>"
					.."<td>1</td>"
					.."<td>=</td>"
					.."<td>"..formatNumber(priceTable[decryptor]).."</td>"
					.."<td>...</td><td>"..formatNumber(cost).."</td></tr>")
			end

			if params.invention.class == "loose" then
				cost = cost + priceTable[inventedFrom]
				outFile:write("<tr><td>"..inventedFrom.."</td>"
					.."<td>"..formatNumber(priceTable[inventedFrom]).."</td>"
					.."<td>x</td>"
					.."<td>1</td>"
					.."<td>=</td>"
					.."<td>"..formatNumber(priceTable[inventedFrom]).."</td>"
					.."<td>...</td><td>"..formatNumber(cost).."</td></tr>")
			end

			local installCost = params.invention:InventionInstallCost(params.inventionSCI)

			cost = cost + installCost
			outFile:write("<tr><td>Invention Job Install Fee</td>"
				.."<td></td>"
				.."<td></td>"
				.."<td></td>"
				.."<td>=</td>"
				.."<td>"..formatNumber(installCost).."</td>"
				.."<td>...</td><td>"..formatNumber(cost).."</td></tr>")

			outFile:write("<tr><td colspan='4'></td><td>Total:</td><td>"..formatNumber(cost).."</td></tr>")
			cost = cost / chance
			outFile:write("<tr><td colspan='4'></td><td>/ "..chance.." chance =</td><td>"..formatNumber(cost).."</td></tr>")

			if t2runs ~= 1 then
				cost = cost / t2runs
				outFile:write("<tr><td colspan='4'></td><td>/ "..t2runs.." runs =</td><td>"..formatNumber(cost).."</td></tr>")
			end
		end,
		Invent = function(self, invention, params, structureMatRoleBonus, structureRigBonus)
			assert(structureMatRoleBonus)
			assert(structureRigBonus)
			local resultRuns = invention:InventionRuns(params)
			local resultME = params.decryptor.meModifier + 2
			local resultPE = params.decryptor.peModifier + 4
			local resultSuccess = invention.inventionBaseChance * (1 + (params.encryptionSkill / 40) + (params.datacoreSkills / 30)) * params.decryptor.probModifier

			local bp = createBlueprint(self.item, self.materials, self.eivMaterials)
			bp.me = resultME
			bp.pe = resultPE
			bp.tools = self.tools
			bp.chance = resultSuccess
			bp.runs = resultRuns
			bp.buildTime = self.buildTime
			bp.copyTime = 0
			bp:ApplyWaste(structureMatRoleBonus, structureRigBonus)

			return bp
		end,
		ApplyWaste = function(self, structureMatRoleBonus, structureRigBonus)
			local newMaterials = { }
			local matMultiplierPct = 100
			local timeMultiplier = 1

			matMultiplierPct = 100 - self.me
			structureRolePct = 100 - structureMatRoleBonus
			structureRigPct = 100 - structureRigBonus
			timeMultiplier = 1 - 0.01 * self.pe

			for item,quantity in pairs(self.materials) do
				if quantity == 1 then
					newMaterials[item] = 1
				else
					newMaterials[item] = quantity * matMultiplierPct * structureRolePct * structureRigPct / 1000000
				end
			end
			self.materials = newMaterials

			assert(self.buildTime, "No build time defined for "..self.item)
			self.buildTime = self.buildTime * timeMultiplier
		end,
		GetMaterialsForRunCount = function(self, runs)
			local mats = { }
			for item,quantity in pairs(self.materials) do
				mats[item] = math.ceil(quantity * runs)
			end
			return mats
		end,
		Clone = function(self)
			local bp = {
				item = self.item,
				me = self.me,
				pe = self.pe,
				materials = self.materials,
				eivMaterials = self.eivMaterials,
				tools = self.tools,
				buildTime = self.buildTime,
				copyTime = self.copyTime,
				blueprintBasePrice = self.blueprintBasePrice,
				maxRuns = self.maxRuns,
			}

			setmetatable(bp, bpMeta)
			return bp
		end,
	}
}

createBlueprint = function(item, mats, eivMats)
	local bp = {
		item = item,
		me = 0,
		pe = 0,
		materials = mats,
		eivMaterials = eivMats,
		blueprintBasePrice = 0,
		maxRuns = 1,
	}

	setmetatable(bp, bpMeta)
	return bp
end

blueprints =
{
	inventionParameters = function(baseRuns, t1bp, decryptor, encryptionSkill, datacore1Skill, datacore2Skill, metaItemLevel)
		assert(datacore1Skill ~= nil, "No datacore 1 skill")
		assert(datacore2Skill ~= nil, "No datacore 2 skill")
		assert(encryptionSkill ~= nil, "No encryption skill")
		return {
			baseRuns = baseRuns,
			t1bp = t1bp,
			decryptor = decryptor,
			encryptionSkill = encryptionSkill,
			datacoreSkills = datacore1Skill + datacore2Skill,
			metaItemLevel = metaItemLevel
		}
	end,

	load = function()
		local blueprints = { }
		local t1blueprints = loadTabFile("data/cache/blueprints_t1.dat")

		print("Loading BPs...")
		for _,row in ipairs(t1blueprints.rows) do
			local mats = {
				Tritanium = nilzero(row.tritanium),
				Pyerite = nilzero(row.pyerite),
				Mexallon = nilzero(row.mexallon),
				Isogen = nilzero(row.isogen),
				Nocxium = nilzero(row.nocxium),
				Zydrine = nilzero(row.zydrine),
				Megacyte = nilzero(row.megacyte),
			}
			blueprints[row.item] = createBlueprint(row.item, mats, mats)
		end

		local complexBlueprints = loadTabFile("data/cache/blueprints_complex.dat")

		local itemMaterials = { }

		for _,row in ipairs(complexBlueprints.rows) do
			local im = itemMaterials[row.item]
			if im == nil then
				im = { }
				itemMaterials[row.item] = im
			end
			im[row.material] = row.quantity
		end

		for k,v in pairs(itemMaterials) do
			blueprints[k] = createBlueprint(k, v, v)
		end

		local idToItem = { }

		local bpDB = loadTabFile("data/cache/blueprints_properties.dat")

		for _,row in pairs(bpDB.rows) do
			if blueprints[row.item] then
				blueprints[row.item].copyTime = row.copyTime
				blueprints[row.item].maxRuns = row.maxRuns
				blueprints[row.item].buildTime = row.buildTime
				blueprints[row.item].inventTime = row.inventTime
				blueprints[row.item].blueprintBasePrice = assert(row.blueprintBasePrice)
				idToItem[row.blueprintID] = row.item
			end
		end

		local ibpDB = loadTabFile("data/cache/blueprints_invention.dat")

		for _,row in pairs(ibpDB.rows) do
			if blueprints[row.item] ~= nil then
				local bp = blueprints[row.item]

				local inventions = bp.inventions
				if inventions == nil then
					inventions = { }
					bp.inventions = inventions
				end

				local inv = { }
				inv.inventedFrom = row.inventedFrom
				inv.inventionBaseChance = row.baseChance
				inv.inventRuns = row.inventedRuns
				inv.inventTime = row.inventTime
				inv.inventionDatacores = {
					{ item = row.datacore1, quantity = row.datacore1quantity },
					{ item = row.datacore2, quantity = row.datacore2quantity },
				}
				inv.class = row.class
				setmetatable(inv, inventionMeta)
				inventions[#inventions + 1] = inv
			end
		end

		return blueprints, idToItem
	end,
}
