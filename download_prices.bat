lua5.1.exe copy_market_list.lua
SDEParser\AtomSmasherESITool\bin\Release\AtomSmasherESITool.exe FetchMarketOrders "data\cache\markets.dat"
SDEParser\AtomSmasherESITool\bin\Release\AtomSmasherESITool.exe FetchItemValues
SDEParser\AtomSmasherESITool\bin\Release\AtomSmasherESITool.exe FetchSCI
lua5.1.exe filter_sell_orders.lua
rem 1DQ is 1022734985679
pause
