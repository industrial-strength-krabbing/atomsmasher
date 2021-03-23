function floodFill(startSystem, floodList, links, boundaryCheckFunc)
	floodList[startSystem] = 0

	continueFlood(floodList, links, boundaryCheckFunc)
end

function continueFlood(floodList, links, boundaryCheckFunc)
	for k in pairs(floodList) do
		floodList[k] = 0
	end

	local floodPoint = 0
	local newFloods
	local taggedAny
	repeat
		local nextFloodPoint = floodPoint+1

		newFloods = { }
		taggedAny = false

		-- Find new floods
		for pt, val in pairs(floodList) do
			if val == floodPoint then
				if links[pt] == nil then
					print("Failed to flood from "..pt)
				end
				for _,link in ipairs(links[pt]) do
					local connection = link.toSys

					if floodList[connection] == nil then
						if(boundaryCheckFunc(pt, connection, nextFloodPoint)) then
							newFloods[connection] = true
							taggedAny = true
						end
					end
				end
			end
		end

		-- Repopulate
		for point in pairs(newFloods) do
			floodList[point] = nextFloodPoint
		end

		floodPoint = nextFloodPoint
	until(taggedAny == false)
end
