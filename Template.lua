local games = require("Games")
local misc = require("Misc")
local REPLACE_GAME_NAME = {}

--IMPORTANT: Declare all function names (besides the startGame/commandHandler/dmHandler/optional reactHandler functions) as local variables here.
--           If you don't do this, they will be imported as global functions, possibly disrupting other games!
local quitGame

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function REPLACE_GAME_NAME.startGame(message)
	-- Use the name as you formatted it in MayorMcMott.lua's GAME_LIST table
	--games.registerGame(message.channel, "GameName", state, message.mentionedUsers)
end

function REPLACE_GAME_NAME.commandHandler(message, state)
end

function REPLACE_GAME_NAME.dmHandler(message, state)
end

--OPTIONAL: Do not include this function if you don't need it!
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