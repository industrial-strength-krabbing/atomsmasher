#! /bin/sh

mono SDEParser/SDEParser/bin/Release/SDEParser.exe
lua5.1 parse_db_dumps.lua
