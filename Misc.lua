local csv = require("deps/csv")

local misc = {}

function misc.parseCSV(filename)
	local tbl = {}
	local f = csv.open(filename)
	for fields in f:lines() do
		for i,v in pairs(fields) do tbl[i] = v end
	end
	return tbl
end

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

function misc.printTable(table)
	for key,value in pairs(table) do
		print(tostring(key) .. "\t" .. tostring(value))
	end
end

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

function misc.shuffleTable(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

function misc.sizeOfTable(tbl)
	local c = 0
	for k,v in pairs(tbl) do c = c + 1 end
	return c
end

function misc.findNil(tbl)
	-- Finds the first nil value in a table that indexes from 1 to N
	c = 1
	while c > 0 do
		if tbl[c] == nil then return c end
		c = c + 1
	end
end

function misc.indexifyTable(tbl)
	local newTbl = {}
	i = 1
	for k,v in pairs(tbl) do
		newTbl[i] = v
		i = i + 1
	end
	return newTbl
end

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

function misc.keyInTable(key, table)
	return table[key] ~= nil
end

function misc.getKeyInTableInsensitive(key, table)
	-- Case-insensitive version of keyInTable
	-- Returns the first key k in the table such that string.upper(key) == string.upper(k)
	for k,v in pairs(table) do
		if string.upper(k) == string.upper(key) then return k end
	end
	return nil
end

function misc.valueInList(val, table)
	-- ONLY WORKS ON TABLES INDEXING FROM 1 TO N
	for k,v in pairs(table) do
		if v == val then return true end
	end
	return false
end

function misc.getKey(val, table)
	-- misc.valueInList but it returns the position
	for k,v in pairs(table) do
		if v == val then return k end
	end
	return nil
end

function misc.fuseLists(tbl1, tbl2)
	-- Fuses two tables with the following constraints:
	-- The tables must be indexed from 1 to N
	-- The values from tbl2 will be inserted at the end of tbl1
	-- If any of the values in tbl2 exist in tbl1, they will be skipped
	for k,v in pairs(tbl2) do
		if not misc.valueInList(v, tbl1) then tbl1[#tbl1+1] = v end
	end
end

function misc.fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

return misc