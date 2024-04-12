mkdir release
mkdir release\code
mkdir release\SDEParser
mkdir release\SDEParser\SDEParser
copy /Y CHANGELOG.txt release
copy /Y build_objectives.csv release
copy /Y compute_price_levels.lua release
copy /Y collate_on_hand_inventory.lua release
copy /Y config.lua release
copy /Y download_prices.bat release
copy /Y download_prices.sh release
copy /Y esi_authenticate.bat release
copy /Y esi_authenticate.sh release
copy /Y esi_fetch_inventory.bat release
copy /Y esi_fetch_inventory.sh release
copy /Y esi_purge_auths.bat release
copy /Y esi_purge_auths.sh release
copy /Y filter_sell_orders.lua release
copy /Y INSTRUCTIONS.txt release
copy /Y lua54.dll release
copy /Y lua54.exe release
copy /Y make_shopping_list.bat release
copy /Y make_shopping_list.sh release
copy /Y make_shopping_list.lua release
copy /Y on_hand_inventory.csv release
copy /Y parse_db_dumps.lua release
copy /Y reparse_sde.bat release
copy /Y reparse_sde.sh release
copy /Y report_invention.lua release
copy /Y report_reactions.lua release
copy /Y copy_market_list.lua release
copy /Y runreport.bat release
copy /Y runreport.sh release
copy /Y uri_handler_uninstall.reg release
copy /Y code\* release\code
copy /Y data\items_inventables.dat release\data
copy /Y data\items_intermediates.dat release\data
copy /Y data\datacore_skills.dat release\data
copy /Y data\invention_decryptors.dat release\data
xcopy SDEParser\* release\SDEParser /Y /E
rmdir /S /Q release\SDEParser\SDEParser\bin\Debug
rmdir /S /Q release\SDEParser\SDEParser\obj
del /Q release\SDEParser\SDEParser\SDEParser.csproj.user
del /Q release\SDEParser\SDEParser\bin\Release\SDEParser.exe.config
del /Q release\SDEParser\SDEParser\bin\Release\SDEParser.pdb
del /Q release\SDEParser\SDEParser\bin\Release\YamlDotNet.pdb
del /Q release\SDEParser\SDEParser\bin\Release\YamlDotNet.xml

rmdir /S /Q release\SDEParser\AtomSmasherESITool\bin\Debug
rmdir /S /Q release\SDEParser\AtomSmasherESITool\obj
del /Q release\SDEParser\AtomSmasherESITool\AtomSmasherESITool.csproj.user
del /Q release\SDEParser\AtomSmasherESITool\bin\Release\AtomSmasherESITool.exe.config
del /Q release\SDEParser\AtomSmasherESITool\bin\Release\AtomSmasherESITool.pdb
del /Q release\SDEParser\AtomSmasherESITool\bin\Release\Newtonsoft.Json.xml
del /Q release\SDEParser\AtomSmasherESITool\bin\Release\YamlDotNet.xml
del /Q release\SDEParser\AtomSmasherESITool\bin\Release\YamlDotNet.pdb
del /Q release\SDEParser\AtomSmasherESITool\bin\Release\ESIHandler.pdb

rmdir /S /Q release\SDEParser\ESIHandler\obj
rmdir /S /Q release\SDEParser\ESIHandler\bin

rmdir /S /Q release\SDEParser\YamlDotNet\obj
rmdir /S /Q release\SDEParser\YamlDotNet\bin

rmdir /S /Q release\SDEParser\packages

pause
