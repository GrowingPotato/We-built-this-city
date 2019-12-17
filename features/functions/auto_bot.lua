local Callback = require 'utils.callback_token'
local Event = require 'utils.event'
local Roles = require 'utils.role.main'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'

Event.on_init(function()
    Callback.event_add{
        name='auto-message',
        timeout=54000, -- 3240000 = 15 hours dont make the mistake i did, 54000 is 15 minutes
        reopen=true,
        data={
            high_role= 'Root',
            low_role= 'Casual',
            low={
                {'chat-bot.join-us'},
                {'chat-bot.discord'},
                {'chat-bot.custom-commands'}
            }
        }
    }:on_event('timeout',function(self)
        local data = self.data
        if not data.high_role or not data.low_role
        or not data.low then self.reopen = false return end
        local _high = Roles.get_role(data.high_role)
        game.print{'chat-bot.message',{'chat-bot.players-online',#game.connected_players}}
        game.print{'chat-bot.message',{'chat-bot.map-time', Server.tick_to_display_format(game.tick)}}
        self.reopen = true
    end):on_event(defines.events.on_player_joined_game,function(self,event)
        local player = game.players[event.player_index]
        if not player then return end
        local data = self.data
        if not data.high_role or not data.low_role
        or not data.low then self.reopen = false return end
        --if Roles.get_role(player).power <= Roles.get_role(data.low_role).power then return end
        for _,message in pairs(data.low) do
            Server.player_return({'chat-bot.message',message},Color.success,player)
        end
    end):on_event('error',function(self,err)
        self.reopen = false
        self:close()
        log(err)
    end):open()
end)

local messages = {
    ['discord']={'chat-bot.discord'},
    ['command']={'chat-bot.custom-commands'},
    ['commands']={'chat-bot.custom-commands'},
    ['softmod']={'chat-bot.softmod'},
    ['script']={'chat-bot.softmod'},
    ['loop']={'chat-bot.loops'},
    ['loops']={'chat-bot.loops'},
    ['rhd']={'chat-bot.lhd'},
    ['roundabout']={'chat-bot.loops'},
    ['roundabouts']={'chat-bot.loops'},
    ['afk']=function(_player) local max=_player for _,player in pairs(game.connected_players) do if max.afk_time < player.afk_time then max=player end end return {'chat-bot.afk',max.name, Server.tick_to_display_format(max.afk_time)} end
}
local command_syntax = '!'
local commands = {
    ['online']=function() return {'chat-bot.players-online',#game.connected_players} end,
    ['playtime']=function() return {'chat-bot.map-time', Server.tick_to_display_format(game.tick)} end,
    ['players']=function() return {'chat-bot.players',#game.players} end,
    ['blame']=function() local names = {'Gerkiz', 'cko6o4ku', 'Userguide', 'Panterh3art', 'Lastfan'} return {'chat-bot.blame',names[math.random(#names)]} end,
    ['magic']={'chat-bot.magic'},
    ['aids']={'chat-bot.aids'},
    ['riot']={'chat-bot.riot'},
    ['lenny']={'chat-bot.lenny'},
    ['feedback']={'chat-bot.feedback'},
    ['hodor']=function() local options = {'?','.','!','!!!'} return {'chat-bot.hodor',options[math.random(#options)]} end,
    ['evolution']=function() return {'chat-bot.current-evolution',string.format('%.2f',game.forces['enemy'].evolution_factor)} end,
    --Jokes about food and drink
    ['foodpls']={'chat-bot.food'},
    ['popcorn']=function(player) Callback.event_add{
        timeout=math.floor(180*(math.random()+0.5)),data=player.name
    }:on_event('timeout',function(self)
        if self.data then game.print{'chat-bot.message',{'chat-bot.get-popcorn-2',self.data}} end
    end):open() return {'chat-bot.get-popcorn-1'} end,
    ['meadpls']=function(player) Callback.event_add{
        timeout=math.floor(180*(math.random()+0.5)),data=player.name
    }:on_event('timeout',function(self)
        if self.data then game.print{'chat-bot.message',{'chat-bot.get-mead-2',self.data}} end
    end):open() return {'chat-bot.get-mead-1'} end,
    ['beerpls']=function(player) Callback.event_add{
        timeout=math.floor(180*(math.random()+0.5)),data=player.name
    }:on_event('timeout',function(self)
        if self.data then game.print{'chat-bot.message',{'chat-bot.get-beer-2',self.data}} end
    end):open() return {'chat-bot.get-beer-1'} end
}

Event.add(defines.events.on_console_chat,function(event)
    local player = game.players[event.player_index]
    if not player then return end
    local player_message = event.message:lower():gsub("%s+", "")
    local allowed = Roles.get_role(player):allowed('global-chat')
    for to_find,message in pairs(messages) do
        if player_message:match(command_syntax..to_find) then
            if allowed then
                if Server.is_type(message,'function') then message=message(player) end
                game.print{'chat-bot.message',message}
            else Server.player_return({'chat-bot.role-error'},nil,player) end
        elseif player_message:match(to_find) then
            if Server.is_type(message,'function') then message=message(player) end
            Server.player_return({'chat-bot.message',message},nil,player)
        end
    end
    for to_find,message in pairs(commands) do
        if player_message:match(command_syntax..to_find) then
            if allowed then
                if Server.is_type(message,'function') then message=message(player) end
                game.print{'chat-bot.message',message}
            else Server.player_return({'chat-bot.role-error'},nil,player) end
        end
    end
end)
