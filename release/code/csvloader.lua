local function dynParse(v)
	local asNumber = tonumber(v)
	if tostring(asNumber) == v then
		return asNumber
	end
	return v
end

local function parseRow(line, header, lineNum, delimiter)
	local index = 1
	local row = { }
	while true do
		local tabIndex = string.find(line, delimiter, 1, true)
		local storageLocation = index

		if header then
			storageLocation = header[index]
		end

		assert(storageLocation, "Failed to store column "..index.." on line "..lineNum..":\n"..line)

		if tabIndex == nil then
			row[storageLocation] = dynParse(line)
			return row;
		else
			row[storageLocation] = dynParse(string.sub(line, 1, tabIndex-1))
			line = string.sub(line, tabIndex+(#delimiter))
			index = index + 1
		end
	end
end

function loadTabFile(fileName, header, delimiter, sigilSize)
	if delimiter == nil then
		delimiter = "\t"
	end

	local f = assert(io.open(fileName, "r"))

	if sigilSize then
		f:read(sigilSize)
	end

	local db = { keyBy = { }, rows = { } }
	local index = 1
	local lineNum = 0

	print("Loading tab file "..fileName)

	for line in f:lines() do
		lineNum = lineNum + 1
		if string.sub(line, 1, 2) ~= "@@" and line ~= "" then
			if header then
				local line = parseRow(line, header, lineNum, delimiter)
				db.rows[index] = line
				index = index+1
			else
				header = parseRow(line, nil, lineNum, delimiter)
				db.columns = header
			end
		end
	end

	f:close()

	return db
end
