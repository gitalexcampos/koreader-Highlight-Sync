-- Add Syncthing to the Tools menu in File Manager, after cloud storage item
local filemanager_order = require("ui/elements/filemanager_menu_order")

local pos = 1
for index, value in ipairs(filemanager_order.tools) do
    if value == "statistics" then
        pos = index + 1
        break
    end
end
table.insert(filemanager_order.tools, pos, "highlight_sync")

local reader_order = require("ui/elements/reader_menu_order")


local pos = 1
for index, value in ipairs(reader_order.tools) do
    if value == "statistics" then
        pos = index + 1
        break
    end
end

table.insert(reader_order.tools, pos, "highlight_sync")