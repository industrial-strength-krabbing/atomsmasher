#! /bin/sh

mono SDEParser/AtomSmasherESITool/bin/Release/AtomSmasherESITool.exe FetchOnHandInventory
lua54 collate_on_hand_inventory.lua
