local csv = require("deps/csv")
local emotes = require("Emotes")

local misc = {}

-- Converts a string to blue emoji text (using the regional indicator block)
function misc.strToBlueEmote(str)
	local output = ""
	local zws = "​" -- Character combos that match a country code will combine into a flag if we don't put a zero-width space between them
	for i = 1, #str do
		local c = str:sub(i,i):lower()
		if string.match(c, "[abcdefghijklmnopqrstuvwxyz]") then output = output .. ":regional_indicator_" .. c .. ":" .. zws end
	end
	return output
end

-- Converts a string to red emoji text (using custom emotes and the blood type emoji block)
-- Custom emote IDs must be set in Emotes.lua for this to work
function misc.strToRedEmote(str)
	local output = ""
	for i = 1, #str do
		local c = str:sub(i,i):upper()
		if emotes.RedLetters[c] ~= nil then output = output .. emotes.RedLetters[c] end
	end
	return output
end

-- Converts a string to green emoji text (using custom emotes)
-- Custom emote IDs must be set in Emotes.lua for this to work
function misc.strToGreenEmote(str)
	local output = ""
	for i = 1, #str do
		local c = str:sub(i,i):upper()
		if emotes.GreenLetters[c] ~= nil then output = output .. emotes.GreenLetters[c] end
	end
	return output
end

-- Check if a string starts with a specific pattern
function misc.startsWith(str, pattern)
	for i = 1, #pattern do
		if str:sub(i,i) ~= pattern:sub(i,i) then return false end
	end
	return true
end

-- Parse a CSV file
-- See also: deps/csv.lua
function misc.parseCSV(filename, sep)
	-- THIS DOES NOT LIKE NEWLINES!!!
	if sep == nil then sep = "," end
	local tbl = {}
	local f = csv.open(filename, {separator = sep})
	for fields in f:lines() do
		for i,v in pairs(fields) do tbl[i] = v end
	end
	return tbl
end

-- Return the sum of values in a table
function misc.sumTable(table)
	-- This function is dedicated to Stack Overflow user katspaugh,
	-- whose infinite wisdom suggests that including a "primitive and specific"
	-- table-summing function in the Lua standard libraries would be redundant.
	local c = 0
	for key,value in pairs(table) do
		c = c + value
	end
	return c
end

-- Print the values in a table
-- This does not print keys, so if your table isn't a list, use printTable.
function misc.printList(table)
	local o = "{"

	for key,value in pairs(table) do
		o = o .. tostring(value) .. ", "
	end

	o = o:sub(1,-3)
	print(o .. "}")
end

-- Print the keys and values in a table
-- This only prints a reference to values that are tables. If you want to go deeper, use deepPrintTable.
function misc.printTable(table)
	for key,value in pairs(table) do
		print(tostring(key) .. "\t" .. tostring(value))
	end
end

-- Print the keys and values in a table, and expand values that are themselves tables
-- Indent is the starting indent value; you probably want to leave this empty.
-- This will go infinitely deep, so don't use it if your table has big objects in it! Instead, use printTableToLayer.
function misc.deepPrintTable(table, indent)
	indent = indent or 0
	for key,value in pairs(table) do
		if type(value) == "table" then
			misc.deepPrintTable(value, indent+1)
		else
			local tabs = string.rep("\t", indent)
			print(tabs .. tostring(key) .. ":\t" .. tostring(value))
		end 
	end
end

-- Print the keys and values in a table, and expand values that are themselves tables, but only up to a certain depth
-- Congratulations if you made it all the way here following the suggestion from printList!
-- Indent is the starting indent value; pass in nil or 0.
-- Max is the depth to print to. Tables at this level of recursion will be printed as a reference.
function misc.printTableToLayer(table, indent, max)
	indent = indent or 0
	for key,value in pairs(table) do
		if (type(value) == "table") and (indent < max) then
			local tabs = string.rep("\t", indent)
			print(tabs .. tostring(key) .. ":")
			misc.printTableToLayer(value, indent+1, max)
		else
			local tabs = string.rep("\t", indent)
			print(tabs .. tostring(key) .. ":\t" .. tostring(value))
		end 
	end
end

-- Shuffle a list in-place
-- Despite the name, this will not be well-behaved if your table isn't a list (ie, the keys aren't successive integers starting from 1)
function misc.shuffleTable(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

-- Get the size of a table
-- You might think that the #tbl operator does this, but nope! That only has defined behavior for lists.
function misc.sizeOfTable(tbl)
	local c = 0
	for k,v in pairs(tbl) do c = c + 1 end
	return c
end

-- Find the first nil value in a list and return its index
function misc.findNil(tbl)
	c = 1
	while c > 0 do
		if tbl[c] == nil then return c end
		c = c + 1
	end
end

-- Turn a table into a list, taking all the values and discarding all the keys
function misc.indexifyTable(tbl)
	local newTbl = {}
	i = 1
	for k,v in pairs(tbl) do
		newTbl[i] = v
		i = i + 1
	end
	return newTbl
end

-- Return a shallow copy of a table
function misc.shallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Return true if the provided key exists in the provided table
function misc.keyInTable(key, table)
	return table[key] ~= nil
end

-- Case-insensitive version of keyInTable
-- Returns the first key k in the table such that string.upper(key) == string.upper(k)
function misc.getKeyInTableInsensitive(key, table)
	for k,v in pairs(table) do
		if string.upper(k) == string.upper(key) then return k end
	end
	return nil
end

-- Return true if the provided value is in the provided table
function misc.valueInList(val, table)
	for k,v in pairs(table) do
		if v == val then return true end
	end
	return false
end

-- Return a copy of the provided table, with the function f applied to it
function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

-- Returns the sum of the result of map()
-- Equivalent to calling sumTable(map(tbl, f))
function sumMap(tbl, f)
	local t = map(tbl, f)
	return sumTable(t)
end

-- Get the key of the provided value. Returns nil if the value isn't found
-- Similar to misc.valueInList, but returns the key rather than the value
function misc.getKey(val, table)
	for k,v in pairs(table) do
		if v == val then return k end
	end
	return nil
end

-- Fuses two tables with the following constraints:
-- The tables must be indexed from 1 to N (ie, a list)
-- The values from tbl2 will be inserted at the end of tbl1
-- If any of the values in tbl2 exist in tbl1, they will be skipped
function misc.fuseLists(tbl1, tbl2)
	for k,v in pairs(tbl2) do
		if not misc.valueInList(v, tbl1) then tbl1[#tbl1+1] = v end
	end
end

-- Insert the key-value pairs from tbl2 into tbl1
function misc.fuseDicts(tbl1, tbl2)
	for k,v in pairs(tbl2) do
		tbl1[k] = v
	end
end

-- Return true if the given filename exists
function misc.fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- Get a random non-nil index from a table
function misc.getRandomIndex(t)
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    index = keys[math.random(1, #keys)]
    return index
end

-- Get n random non-nil indices from a table
function misc.getRandomIndices(t,n)
    local keys = {}
    local indices = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    misc.shuffleTable(keys)
    for i=1,n do indices[keys[i]] = t[keys[i]] end
    return indices
end

-- setn was deprecated in 5.2 but not replaced, and lua does not update table size when you do tbl[idx] = val
-- Therefore, if you want to use that syntax, you need to do this horribly ugly thing
-- You should probably use sizeOfTable instead of #tbl instead of using this.
function misc.setn(tbl,n)
	setmetatable(tbl,{__len=function() return n end})
end

return misc