#! /bin/sh

mono SDEParser/AtomSmasherESITool/bin/Release/AtomSmasherESITool.exe FetchOnHandInventory
lua5.1 collate_on_hand_inventory.lua
