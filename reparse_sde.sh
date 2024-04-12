#! /bin/sh

mono SDEParser/SDEParser/bin/Release/SDEParser.exe
lua54 parse_db_dumps.lua
