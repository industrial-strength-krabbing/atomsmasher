assert(loadfile("userdata/config.lua"))()


local mf = io.open("data/cache/markets.dat", "w")
mf:write(tostring(#config.publicMarkets))
mf:write("\n")
for _,market in ipairs(config.publicMarkets) do
	mf:write(market.regionID)
	mf:write("\n")
	
	mf:write(tostring(#market.locations))
	mf:write("\n")
	for _,loc in ipairs(market.locations) do
		mf:write(loc.locationID)
		mf:write("\n")
		if loc.locationType ~= nil then
			mf:write(loc.locationType)
		else
			mf:write("default")
		end
		mf:write("\n")
	end
end

mf:write(tostring(#config.citadelMarkets))
mf:write("\n")
for _,market in ipairs(config.citadelMarkets) do
	mf:write(market.authCharacterName)
	mf:write("\n")
	mf:write(market.locationID)
	mf:write("\n")
	if market.locationType ~= nil then
		mf:write(market.locationType)
	else
		mf:write("default")
	end
	mf:write("\n")
end

mf:close()
