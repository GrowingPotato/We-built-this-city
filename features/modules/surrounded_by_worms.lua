-- this spawns additional worms around the center of the map_gen_settings
-- global.average_worm_amount_per_chunk sets the average amount of worms
-- (default = 1)

local Event = require 'utils.event'
local math_random = math.random
local turrets = {
	[1] = "small-worm-turret",
	[2] = "small-worm-turret",
	[3] = "small-worm-turret",
	[4] = "small-worm-turret",
	[5] = "small-worm-turret",
	[6] = "small-worm-turret",
	[7] = "small-worm-turret",
	[8] = "small-worm-turret",
	[9] = "medium-worm-turret",
	[10] = "medium-worm-turret",
	[11] = "medium-worm-turret",
	[12] = "medium-worm-turret",
	[13] = "medium-worm-turret",
	[14] = "medium-worm-turret",
	[15] = "medium-worm-turret",
	[16] = "medium-worm-turret",
	[17] = "medium-worm-turret",
	[18] = "medium-worm-turret",
	[19] = "big-worm-turret",
	[20] = "big-worm-turret",
	[21] = "big-worm-turret",
	[22] = "big-worm-turret",
	[23] = "big-worm-turret",
	[24] = "big-worm-turret",
	[25] = "big-worm-turret",
	[26] = "big-worm-turret",
	[27] = "big-worm-turret",
	[28] = "behemoth-worm-turret",
}

local tile_coords = {}
for x = 0, 31, 1 do
	for y = 0, 31, 1 do
		tile_coords[#tile_coords + 1] = {x, y}
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	local starting_distance = surface.map_gen_settings.starting_area * 800
	local left_top = event.area.left_top
	local chunk_distance_to_center = math.sqrt(left_top.x ^ 2 + left_top.y ^ 2)
	if starting_distance > chunk_distance_to_center then return end

	local highest_worm_tier = math.floor((chunk_distance_to_center - starting_distance) * 0.002) + 1
	--if highest_worm_tier > 4 then highest_worm_tier = 4 end

	if not global.average_worm_amount_per_chunk then global.average_worm_amount_per_chunk = 1 end
	local worm_amount = math_random(math.floor(global.average_worm_amount_per_chunk * 0.5), math.ceil(global.average_worm_amount_per_chunk * 1.5))

	for a = 1, worm_amount, 1 do
		local coord_modifier = tile_coords[math_random(1, #tile_coords)]
		local pos = {left_top.x + coord_modifier[1], left_top.y + coord_modifier[2]}
		local name = turrets[math_random(1, highest_worm_tier)]
		local position = surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
		if position then
			surface.create_entity({name = name, position = position, force = "enemy"})
		end
	end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)