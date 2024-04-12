#! /bin/sh

lua54 copy_market_list.lua
mono SDEParser/AtomSmasherESITool/bin/Release/AtomSmasherESITool.exe FetchMarketOrders "data/cache/markets.dat"
mono SDEParser/AtomSmasherESITool/bin/Release/AtomSmasherESITool.exe FetchItemValues
mono SDEParser/AtomSmasherESITool/bin/Release/AtomSmasherESITool.exe FetchSCI
lua54 filter_sell_orders.lua
echo "Thetastar is 1022734985679"
echo "Imperial Palace is 1030049082711"
