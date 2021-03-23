database =
{
	indexByUnique = function(db, key)
		local idxTable = { }
		for i=1,#db.rows do
			local row = db.rows[i]
			local kVal = row[key]
			idxTable[kVal] = row
		end
		db.keyBy[key] = idxTable
	end,

	indexByMultiple = function(db, key)
		local idxTable = { }
		for i=1,#db.rows do
			local row = db.rows[i]
			local kVal = row[key]

			local lookupSeries = idxTable[kVal] or { }
			lookupSeries[#lookupSeries+1] = row
			idxTable[kVal] = lookupSeries
		end
		db.keyBy[key] = idxTable
	end,

	convertToDict = function(db, keyKey, valueKey)
		local idxTable = { }
		for i=1,#db.rows do
			local row = db.rows[i]
			local kVal = row[keyKey]
			idxTable[kVal] = row[valueKey]
		end
		return idxTable
	end,
}
