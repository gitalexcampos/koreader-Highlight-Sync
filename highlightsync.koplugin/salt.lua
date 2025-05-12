--[[ Save and Load Tables (SALT) ]]--
--
--Url: http://github.com/VaiN474/salt.git
--
--Author: VaiN474 - http://github.com/VaiN474
--Last Update: Aug 15, 2017
--Description: Recursively saves table data to a file, human-readable and
--             indented. Tables are loaded using loadfile().
--             Supported types: number, string, boolean, sub-tables of same.
--
--License: MIT (read LICENSE for more details)
--
--Example Usage:
--
--salt = require("salt")
--salt.save(my_table,"/path/to/file")
--
--my_table,err = salt.load("/path/to/file")
--

local salt = {}

-- compressed is optional, if true it will not include unneccesary spaces, indentation, or line endings
function salt.save(tbl,file,compressed)

    local f,err = io.open(file,"w")
    if err then print(err) return end
    local indent = 1

    -- local functions to make things easier
    local function exportstring(s)
        s=string.format("%q",s)
        s=s:gsub("\\\n","\\n")
        s=s:gsub("\r","")
        s=s:gsub(string.char(26),"\"..string.char(26)..\"")
        return s
    end
    local function serialize(o)
        if type(o) == "number" then
            f:write(o)
        elseif type(o) == "boolean" then
            if o then f:write("true") else f:write("false") end
        elseif type(o) == "string" then
            f:write(exportstring(o))
        elseif type(o) == "table" then
            f:write("{" .. (compressed and "" or "\n"))
            indent = indent + 1
            local tab = ""
            for i=1,indent do tab = tab .. "    " end
            for k,v in pairs(o) do
                f:write((compressed and "" or tab) .. "[")
                serialize(k)
                f:write("]" .. (compressed and "=" or " = "))
                serialize(v)
                f:write("," .. (compressed and "" or "\n"))
            end
            indent = indent - 1
            tab = ""
            for i=1,indent do tab = tab .. "    " end
            f:write((compressed and "" or tab) .. "}")
        else
            print("unable to serialzie data: "..tostring(o))
            f:write("nil," .. (compressed and "" or " -- ***ERROR: unsupported data type: "..type(o).."!***"))
        end
    end

    f:write("return {" .. (compressed and "" or "\n"))
    local tab = "    "
    for k,v in pairs(tbl) do
        f:write((compressed and "" or tab) .. "[")
        serialize(k)
        f:write("]" .. (compressed and "=" or " = "))
        serialize(v)
        f:write("," .. (compressed and "" or "\n"))
    end
    f:write("}")
    f:close()
end

function salt.load(file)
    local data,err = loadfile(file)
    if err then return nil,err else return data() end
end

return salt
