require "pica"

local Event = require 'utils.event'
local t_insert = table.insert
local use_large_map = false
local scale = 2
local spawn = {
    x = 1920,
    y = 1080
}

--Terrain codes should be in sync with the ConvertMap code
local terrain_codes = {
    ["a"] = "concrete",
    ["b"] = "deepwater-green",
    ["c"] = "deepwater",
    ["d"] = "dirt-1",
    ["e"] = "dirt-2",
    ["f"] = "dirt-3",
    ["g"] = "dirt-4",
    ["h"] = "dirt-5",
    ["j"] = "dirt-6",
    ["k"] = "dirt-7",
    ["l"] = "dry-dirt",
    ["m"] = "grass-1",
    ["n"] = "grass-2",
    ["o"] = "grass-3",
    ["p"] = "grass-4",
    ["q"] = "hazard-concrete-left",
    ["r"] = "hazard-concrete-right",
    ["s"] = "lab-dark-1",
    ["t"] =  "lab-dark-2",
    ["g"] =  "lab-white",
    ["_"] = "out-of-map",
    ["A"] = "red-desert-0",
    ["B"] = "red-desert-1",
    ["C"] = "red-desert-2",
    ["D"] = "red-desert-3",
    ["E"] = "sand-1",
    ["F"] = "sand-2",
    ["G"] = "sand-3",
    ["H"] = "stone-path",
    ["J"] = "water-green",
    ["K"] = "water"
    --[[
    ["_"] = "out-of-map",
    ["o"] = "deepwater",--ocean
    ["O"] = "deepwater-green",
    ["w"] = "water",
    ["W"] = "water-green",
    ["g"] = "grass-1",
    ["m"] = "grass-3",
    ["G"] = "grass-2",
    ["d"] = "dirt-3",
    ["D"] = "dirt-6",
    ["s"] = "sand-1",
    ["S"] = "sand-3"]]--
}




local function decompress_map_data()
    --print("Decompressing, this can take a while...")
    local decompressed = {}
    local height = use_large_map and #map_data_large or #map_data
    local width = nil
    local last = -1
    for y = 0, height-1 do
        decompressed[y] = {}
        --debug info
        local work = math.floor(y * 100 / height)
        if work ~= last then --so it doesn't --print the same percent over and over.
            --print("... ", work, "%")
        end
        last = work
        --do decompression of this line
        local total_count = 0
        local line = use_large_map and map_data_large[y+1] or map_data[y+1]
        for letter, count in string.gmatch(line, "(%a+)(%d+)") do
            for x = total_count, total_count + count do
                decompressed[y][x] = letter
            end
            total_count = total_count + count
        end
        --check width (all lines must the equal in length)
        if width == nil then
            width = total_count
        elseif width ~= total_count then
            error()
        end
    end
    --print("Finished decompressing")
    return decompressed, width, height
end

local decompressed_map_data, width, height = decompress_map_data();

local function add_to_total(totals, weight, code)
    if totals[code] == nil then
        totals[code] = {code=code, weight=weight}
    else
        totals[code].weight = totals[code].weight + weight
    end
end

local function get_world_tile_name(x, y)
    --scaling
    x = x / scale
    y = y / scale
    --get cells you're between
    local top = math.floor(y)
    local bottom = (top + 1)
    local left = math.floor(x)
    local right = (left + 1)
    --calc weights
    local sqrt2 = math.sqrt(2)
    local w_top_left = 1 - math.sqrt((top - y)*(top - y) + (left - x)*(left - x)) / sqrt2
    local w_top_right = 1 - math.sqrt((top - y)*(top - y) + (right - x)*(right - x)) / sqrt2
    local w_bottom_left = 1 - math.sqrt((bottom - y)*(bottom - y) + (left - x)*(left - x)) / sqrt2
    local w_bottom_right = 1 - math.sqrt((bottom - y)*(bottom - y) + (right - x)*(right - x)) / sqrt2
    w_top_left = w_top_left * w_top_left + math.random() / math.max(scale / 2, 10)
    w_top_right = w_top_right * w_top_right + math.random() / math.max(scale / 2, 10)
    w_bottom_left = w_bottom_left * w_bottom_left + math.random() / math.max(scale / 2, 10)
    w_bottom_right = w_bottom_right * w_bottom_right + math.random() / math.max(scale / 2, 10)
    --get codes
    local c_top_left = decompressed_map_data[top % height][left % width]
    local c_top_right = decompressed_map_data[top % height][right % width]
    local c_bottom_left = decompressed_map_data[bottom % height][left % width]
    local c_bottom_right = decompressed_map_data[bottom % height][right % width]
    --calculate total weights for codes
    local totals = {}
    add_to_total(totals, w_top_left, c_top_left)
    add_to_total(totals, w_top_right, c_top_right)
    add_to_total(totals, w_bottom_left, c_bottom_left)
    add_to_total(totals, w_bottom_right, c_bottom_right)
    --choose final code
    local code = nil
    local weight = 0
    for _, total in pairs(totals) do
        if total.weight > weight then
            code = total.code
            weight = total.weight
        end
    end
    return terrain_codes[code]
end

local function on_chunk_generated(event)
    local surface = event.surface
    local lt = event.area.left_top
    local rb = event.area.right_bottom

    --local w = rb.x - lt.x
    --local h = rb.y - lt.y
    --print("Chunk generated: ", lt.x, lt.y, w, h)

    local tiles = {}
    for y = lt.y-1, rb.y do
        for x = lt.x-1, rb.x do
            t_insert(tiles, {name=get_world_tile_name(x + spawn.x, y + spawn.y), position={x,y}})
        end
    end
    surface.set_tiles(tiles)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
