local Event = require 'utils.event'
local Token = require 'utils.token'

local Public = {}


local on_tick =
    Token.register(function()
	if game.tick % 2 == 0 then
	    local drivers = false
	    local moveReset = (game.tick % 40 == 0)
	    for _, player in pairs(game.connected_players) do
	      local pdata = global.players[player.index]
	      if pdata.driving and pdata.snap then
	        if not player.vehicle then
	          pdata.driving = false
	        else
	          drivers = true
	          if (pdata.eff_moves > 1) and (math.abs(player.vehicle.speed) > 0.03) then
	            local o = player.vehicle.orientation
	            if math.abs(o - pdata.last_orientation) < 0.001 then
	              if pdata.player_ticks > 1 then
	                local snap_o = math.floor(o * pdata.snap_amount + 0.5) / pdata.snap_amount
	                o = (o * 4.0 + snap_o) * 0.2
	                player.vehicle.orientation = o
	              else
	                pdata.player_ticks = pdata.player_ticks + 1
	              end
	            else
	              pdata.player_ticks = 0
	            end
	            pdata.last_orientation = o
	          end
	          if moveReset then
	            pdata.eff_moves = pdata.moves
	            pdata.moves = 0
	          end
	        end
	      end
	    end
	    if not drivers then
	      Public.ToggleEvents(false)
	    end
	end
end)

local changed_position =
    Token.register(function(event)
	local pdata = global.players[event.player_index]
	if pdata and pdata.driving then
		pdata.moves = pdata.moves + 1
		-- Debug player speed values
		--local player = game.players[event.player_index]
		--if player.vehicle then
		--  player.surface.create_entity{ name = "flying-text", position = player.position, text = player.vehicle.speed }
		--end
	end
end)

function Public.ToggleEvents(enable)
  global.RegisterEvents = enable
  if enable then
    Event.add_removable(defines.events.on_tick, on_tick)
    Event.add_removable(defines.events.on_player_changed_position, changed_position)
  else
    --Event.remove_removable(defines.events.on_tick, on_tick)
    Event.remove_removable(defines.events.on_player_changed_position, changed_position)
  end
end

local function CheckDrivingState(player)
  local pdata = global.players[player.index]
  local driving = false
  if player.vehicle and pdata.snap then
    driving = (player.vehicle.type == "car")
    pdata.moves = 0
    pdata.eff_moves = 0
    pdata.snap_amount = pdata.snap_amount or 16
  end
  pdata.driving = driving
  Public.ToggleEvents(true)
end


local function on_init()
  global.players = global.players or {}
  for i, player in (pairs(game.players)) do
    --game.players[i].print("VehicleSnap installed") -- Debug
    global.players[i] = global.players[i] or {
      snap = true,
      player_ticks = 0,
      last_orientation = 0,
      -- driving is only true if snapping is true and player is in a valid vehicle
      driving = false,
      moves = 0,
      eff_moves = 0, -- Effective tile moves from last time period
      snap_amount = 16
    }
    CheckDrivingState(player)
    player.set_shortcut_toggled("VehicleSnap-shortcut", global.players[i].snap)
  end
  Public.ToggleEvents(true)
end

-- Any time a new player is created run this.
Event.add(defines.events.on_player_created, function(event)
  global.players[event.player_index] = {
    snap = true,
    player_ticks = 0,
    last_orientation = 0,
    driving = false,
    moves = 0,
    eff_moves = 0,
    snap_amount = 16
  }
end)


Event.add(defines.events.on_player_driving_changed_state, function(event)
  CheckDrivingState(game.players[event.player_index])
end)

Event.add(defines.events.on_player_died, function(event)
  CheckDrivingState(game.players[event.player_index])
end)

Event.on_init(on_init)
script.on_configuration_changed(on_init)

Event.on_load(function()
  if global.RegisterEvents then
    Public.ToggleEvents(true)
  end
end)

return Public