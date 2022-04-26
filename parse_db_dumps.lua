assert(loadfile("code/tabloader.lua"))()

print("Loading materials DB...")
local matDB = loadTabFile("data/blueprints_complex.csv", { "quantity", "material", "item" }, "\t" )

local t1File = io.open("data/cache/blueprints_t1.dat", "w")
local complexFile = io.open("data/cache/blueprints_complex.dat", "w")

local t1types = { "Tritanium", "Pyerite", "Mexallon", "Isogen", "Nocxium", "Zydrine", "Megacyte" }

local t1mats = { }

for _,itemName in ipairs(t1types) do
	t1mats[itemName] = true
end

local items = { }

-- Item format:
--    materials: Materials keyed by type
--    tools: Tool damage keyed by type
--    t1: Can be stored as a T1 item

local function getItem(name)
	local i = items[name]

	if i == nil then
		i = { materials = { }, tools = { }, t1 = true }
		items[name] = i
	end

	return i
end

for _,row in ipairs(matDB.rows) do
	local item = getItem(row.item)

	if not t1mats[row.material] then
		item.t1 = false
	end

	item.materials[row.material] = row.quantity
end

-- Dump T1
t1File:write("item\ttritanium\tpyerite\tmexallon\tisogen\tnocxium\tzydrine\tmegacyte\n")
for itemName,item in pairs(items) do
	if item.t1 then
		t1File:write(itemName)
		for _,itemName in ipairs(t1types) do
			t1File:write("\t"..(item.materials[itemName] or "0"))
		end
		t1File:write("\n")
	end
end
t1File:close()

-- Dump complex
complexFile:write("item\tmaterial\tquantity\n")
for itemName,item in pairs(items) do
	if not item.t1 then
		for matName,quantity in pairs(item.materials) do
			if quantity > 0 then
				complexFile:write(itemName.."\t"..matName.."\t"..quantity.."\n")
			end
		end
	end
end
complexFile:close()

local toolDB = nil
local matDB = nil

-- Dump multiple quantity
local mqDB = loadTabFile("data/blueprints_multiplequantity.csv", { "item", "quantity" }, "\t" )

local mqFile = io.open("data/cache/blueprints_multiple_quantity.dat", "w")
mqFile:write("item\tquantity\n")
for _,row in pairs(mqDB.rows) do
	mqFile:write(row.item.."\t"..row.quantity.."\n")
end
mqFile:close()
mqDB = nil

-- Dump properties
print("Loading properties DB...")
local propDB = loadTabFile("data/blueprints_properties.csv", { "item", "copyTime", "inventTime", "inventProbability", "inventRuns", "buildTime", "maxRuns", "productCategory", "blueprintID", "blueprintBasePrice" }, "\t" )

local propFile = io.open("data/cache/blueprints_properties.dat", "w")
propFile:write("item\tcopyTime\tinventTime\tinventedRuns\tbuildTime\tmaxRuns\tblueprintID\tblueprintBasePrice\n")
for _,item in ipairs(propDB.rows) do
	propFile:write(item.item.."\t"..item.copyTime.."\t"..item.inventTime.."\t"..item.inventRuns.."\t"..item.buildTime.."\t"..item.maxRuns.."\t"..item.blueprintID.."\t"..item.blueprintBasePrice.."\n")
end
propFile:close()

local t2DB = loadTabFile("data/blueprints_t2.csv", { "parentTypeName", "childTypeName", "groupName", "categoryName" }, "\t" )
local dcDB = loadTabFile("data/blueprints_datacores.csv", { "bpTypeName", "reqTypeName", "quantity", "encryptionSkill" }, "\t" )
local inventionLooseDB = loadTabFile("data/blueprints_invention_loose.csv", { "baseItem", "product", "inventProbability", "inventRuns", "inventTime" }, "\t" )

local reactionsNormalDB = loadTabFile("data/reactions_normal.csv", { "quantity", "material", "item" }, "\t" )
local reactionsAlchemyDB = loadTabFile("data/reactions_alchemy.csv", { "item", "quantity", "output" }, "\t" )
local reactionsPropertiesDB = loadTabFile("data/reactions_properties.csv", { "item", "quantity", "time", "blueprintID", "category" }, "\t" )

local t1inventReqs = { }

for _,row in ipairs(dcDB.rows) do
	local bp = t1inventReqs[row.bpTypeName]

	if bp == nil then
		bp = { inventedFrom = row.bpTypeName }
		t1inventReqs[row.bpTypeName] = bp
	end

	local interfaceType = string.match(row.reqTypeName, "(.-) .+")

	if interfaceType == "Datacore" then
		if bp.datacore1 == nil then
			bp.datacore1 = row.reqTypeName
			bp.datacore1quantity = row.quantity
		else
			bp.datacore2 = row.reqTypeName
			bp.datacore2quantity = row.quantity
		end
	end

	bp.encryptionSkill = row.encryptionSkill
end


local inventChances = { }
local inventRuns = { }
local inventTimes = { }

for _,item in ipairs(propDB.rows) do
	inventChances[item.item] = item.inventProbability
	inventRuns[item.item] = item.inventRuns
	inventTimes[item.item] = item.inventTime
end

local inventFile = io.open("data/cache/blueprints_invention.dat", "w")
inventFile:write("item\tinventedFrom\tbaseChance\tdatacore1\tdatacore1quantity\tdatacore2\tdatacore2quantity\tencryptionSkill\tinventedRuns\tinventTime\tclass\n")
for _,row in ipairs(t2DB.rows) do
	local t2item = { item = row.childTypeName }

	-- Clone the T1 table
	local parentTable = t1inventReqs[row.parentTypeName]

	-- Might be nil if the base item isn't actually inventable (i.e. Micro Capacitor Batteries)
	if parentTable ~= nil then
		for k,v in pairs(parentTable) do
			t2item[k] = v
		end

		t2item.baseChance = inventChances[row.parentTypeName]
		t2item.inventedRuns = inventRuns[row.parentTypeName]
		t2item.inventTime = inventTimes[row.parentTypeName]

		-- Might be nil race for civilian datacore items (i.e. Perpetual Motion Machines)
		inventFile:write(
			t2item.item.."\t"..
			t2item.inventedFrom.."\t"..
			t2item.baseChance.."\t"..
			t2item.datacore1.."\t"..
			t2item.datacore1quantity.."\t"..
			t2item.datacore2.."\t"..
			t2item.datacore2quantity.."\t"..
			t2item.encryptionSkill.."\t"..
			t2item.inventedRuns.."\t"..
			t2item.inventTime.."\t"..
			"t2\n")
	end
end

for _,row in ipairs(inventionLooseDB.rows) do
	local t3item = { item = row.product }

	-- Clone the T1 table
	local parentTable = t1inventReqs[row.baseItem]

	-- Might be nil if the base item isn't actually inventable (i.e. Micro Capacitor Batteries)
	if parentTable ~= nil then
		for k,v in pairs(parentTable) do
			t3item[k] = v
		end

		t3item.baseChance = row.inventProbability
		t3item.inventedRuns = row.inventRuns
		t3item.inventTime = row.inventTime

		inventFile:write(
			t3item.item.."\t"..
			t3item.inventedFrom.."\t"..
			t3item.baseChance.."\t"..
			t3item.datacore1.."\t"..
			t3item.datacore1quantity.."\t"..
			t3item.datacore2.."\t"..
			t3item.datacore2quantity.."\t"..
			t3item.encryptionSkill.."\t"..
			t3item.inventedRuns.."\t"..
			t3item.inventTime.."\t"..
			"loose\n")
	end
end
local inventionLooseDB = loadTabFile("data/blueprints_invention_loose.csv", { "baseItem", "product", "inventProbability", "inventRuns", "inventTime" }, "\t" )

inventFile:close()

inventionJobs = nil

print("Loading names...")

local namesDB = loadTabFile("data/cache/names.dat", { "id", "name" }, "\t" )

local idToName = { }

for _,row in ipairs(namesDB.rows) do
	idToName[row.id] = row.name
end

namesDB = nil

print("Writing caches...")

local allCategories = { }

local blueprintCategoryFile = io.open("data/cache/blueprints_categories.dat", "w")
blueprintCategoryFile:write("item\tcategory\n")
for _,row in ipairs(propDB.rows) do
	blueprintCategoryFile:write(row.item)
	blueprintCategoryFile:write("\t")
	blueprintCategoryFile:write(row.productCategory)
	blueprintCategoryFile:write("\n")

	allCategories[row.productCategory] = true
end
blueprintCategoryFile:close()

local reactionItemsSet = { }
for _,row in ipairs(reactionsNormalDB.rows) do
	reactionItemsSet[row.item] = true
end

local reactionsFile = io.open("data/cache/reactions.dat", "w")
reactionsFile:write("item\tmaterial\tquantity\n")
for _,row in ipairs(reactionsNormalDB.rows) do

	reactionsFile:write(row.item)
	reactionsFile:write("\t")
	reactionsFile:write(row.material)
	reactionsFile:write("\t")
	reactionsFile:write(row.quantity)
	reactionsFile:write("\n")
end
reactionsFile:close()

local reactionsPropertiesFile = io.open("data/cache/reactions_properties.dat", "w")
reactionsPropertiesFile:write("item\toutputQuantity\ttime\tblueprintID\tcategory\n")
for _,row in ipairs(reactionsPropertiesDB.rows) do

	reactionsPropertiesFile:write(row.item)
	reactionsPropertiesFile:write("\t")
	reactionsPropertiesFile:write(row.quantity)
	reactionsPropertiesFile:write("\t")
	reactionsPropertiesFile:write(row.time)
	reactionsPropertiesFile:write("\t")
	reactionsPropertiesFile:write(row.blueprintID)
	reactionsPropertiesFile:write("\t")
	reactionsPropertiesFile:write(row.category)
	reactionsPropertiesFile:write("\n")
end
reactionsPropertiesFile:close()

local alchemyReprocessFile = io.open("data/cache/alchemy_reprocess.dat", "w")
alchemyReprocessFile:write("item\toutput\tquantity\n")
for _,row in ipairs(reactionsAlchemyDB.rows) do

	alchemyReprocessFile:write(row.item)
	alchemyReprocessFile:write("\t")
	alchemyReprocessFile:write(row.output)
	alchemyReprocessFile:write("\t")
	alchemyReprocessFile:write(row.quantity)
	alchemyReprocessFile:write("\n")
end
alchemyReprocessFile:close()

local alchemyParentFile = io.open("data/cache/alchemy_parent.dat", "w")
alchemyParentFile:write("item\tparent\n")
for _,row in ipairs(reactionsAlchemyDB.rows) do
	if reactionItemsSet[row.output] then
		alchemyParentFile:write(row.output)
		alchemyParentFile:write("\t")
		alchemyParentFile:write(row.item)
		alchemyParentFile:write("\n")
	end
end
alchemyParentFile:close()
