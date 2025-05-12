local salt = assert(require("salt"))

local function only_pos(text)
    return string.match(text, "%.([^%.]+)$")
end


-- Function to generate a unique key for a highlight
local function generate_key(highlight)
    local text_hash = tostring(string.len(highlight.text))  -- Can be improved using a real hash
    return string.format("%s%s",
        highlight.pageno or "?",
        --only_pos(highlight.pos0) or "?",
        --only_pos(highlight.pos1) or "?",
        text_hash
    )
end


-- Function to convert an array of highlights into a table indexed by unique keys
local function convert_to_map(highlights)
    local map = {}
    for _, h in ipairs(highlights or {}) do
        local key = generate_key(h)
        map[key] = h
    end
    return map
end

local function parse_datetime(str)
  local y, m, d, h, min, s = str:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
  return os.time{year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=tonumber(h), min=tonumber(min), sec=tonumber(s)}
end

local function get_datetime(item)
  return item.datetime_updated or item.datetime
end

local function get_newer(item1, item2)
  local t1 = parse_datetime(get_datetime(item1))
  local t2 = parse_datetime(get_datetime(item2))
  return t1 >= t2 and item1 or item2
end

-- Function to merge highlights from local, server, and last sync versions
function merge_highlights(local_annotations, server_annotations, last_sync_annotations)
    local merged = {}

    -- Convert lists into tables indexed by the unique key
    local local_map = convert_to_map(local_annotations)
    local server_map = convert_to_map(server_annotations)
    local last_sync_map = convert_to_map(last_sync_annotations)
    -- salt.save(server_map,SidecarDir .. "/anotation-server.lua")
    -- salt.save(local_map, SidecarDir .. "/anotation-local.lua")
    -- salt.save(last_sync_map, SidecarDir .. "/anotation-last-sync.lua")
    -- Process local highlights
    for key, local_highlight in pairs(local_map) do
        local server_highlight = server_map[key]
        local last_sync_highlight = last_sync_map[key]
        salt.save(server_map, SidecarDir .. "/key-server.lua")
        salt.save(local_map, SidecarDir .. "/key-local.lua")
        salt.save(last_sync_map, SidecarDir .. "/last-key.lua")

        if server_highlight == nil and last_sync_highlight ~= nil then
            -- ❌ If the highlight was in the last sync, still exists locally, but is missing from the server,
            -- it was deleted on another device and should NOT be included
        else
            -- ✅ Otherwise, keep the local highlight
            merged[key] = local_highlight
            --table.insert(merged, local_highlight)
        end
    end

    -- Process server highlights that are not in local
    for key, server_highlight in pairs(server_map) do
        if last_sync_map[key] ~= nil and local_map[key] == nil then
            -- ❌ If the highlight was in the last sync but is missing locally, it was deleted by the user
            -- and should NOT be added
        else
            -- ✅ Keep server highlight if it exists
            --table.insert(merged, server_highlight)
            if local_map[key] == nil then
                merged[key] = server_highlight
            else
                merged[key] = get_newer(server_highlight, local_map[key])
            end
        end
    end

    -- Convert the merged result back to an array
    local merged_annotations = {}
    for _, highlight in pairs(merged) do
        table.insert(merged_annotations, highlight)
    end

    table.sort(merged_annotations, function(a, b)
         -- Primary sort: by pageno in ascending order
        if a.pageno ~= b.pageno then
            return a.pageno < b.pageno
        end

        -- Secondary sort: within the same page, entries with pos0 == nil come first
        if a.pos0 == nil and b.pos0 ~= nil then
            return true
        elseif a.pos0 ~= nil and b.pos0 == nil then
            return false
        end

        -- Tertiary sort: fallback to original order (or add datetime comparison here if needed)
        return false
    end)


    --salt.save(merged_annotations, SidecarDir .. "/merged-key.lua") --Debug
    return merged_annotations
end

local M = {}

M.merge_highlights = merge_highlights

return M
