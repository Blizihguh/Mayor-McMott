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


function misc.printTable(table)
	for key,value in pairs(table) do
		print(tostring(key) .. "\t" .. tostring(value))
	end
end

function misc.shuffleTable(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
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

function misc.fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

return misc