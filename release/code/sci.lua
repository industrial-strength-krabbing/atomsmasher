local buildSystemsDB = loadTabFile("userdata/build_systems.dat")
	database.indexByUnique(buildSystemsDB, "category")

local sciDB = loadTabFile("data/sci.dat")
	database.indexByMultiple(sciDB, "activity")

local sciData = { }

for activity,rows in pairs(sciDB.keyBy.activity) do
	local activityData = { }
	for _,row in ipairs(rows) do
		activityData[row.solarSystemName] = assert(row.costIndex)
	end
	sciData[activity] = activityData
end

sciDB = nil

sci =
{
	Find = function(activity, category)
		assert(activity)
		assert(category)

		local solarSystemRow = buildSystemsDB.keyBy.category[category]
		if solarSystemRow == nil then
			solarSystemRow = buildSystemsDB.keyBy.category.Default
		end

		if solarSystemRow == nil then
			return 0
		end

		local solarSystemName = solarSystemRow.solarSystemName

		local costIndex = sciData[activity][solarSystemName]
		assert(costIndex, "No SCI for system "..solarSystemName);

		return costIndex
	end,
	FindInvention = function()
		local costIndex = sciData["invention"][config.inventionSystem]
		if costIndex == nil then
			assert(nil, "No invention SCI for system "..config.inventionSystem)
		end

		return costIndex
	end,
}
