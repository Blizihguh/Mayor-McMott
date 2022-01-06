local games = require("Games")
local misc = require("Misc")

local REPLACE_GAME_NAME = {}

local quitGame

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function REPLACE_GAME_NAME.startGame(message, playerList)
	local args = message.content:split(" ")

	local state = {
		GameChannel = message.channel,
		PlayerList = playerList
	}
end

function REPLACE_GAME_NAME.commandHandler(message, state)
	local args = message.content:split(" ")
end

function REPLACE_GAME_NAME.dmHandler(message, state)
	local args = message.content:split(" ")
end

function REPLACE_GAME_NAME.reactHandler(reaction, user, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameChannel)	
end

return REPLACE_GAME_NAME