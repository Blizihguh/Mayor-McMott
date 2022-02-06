local games = require("Games")
local misc = require("Misc")

local REPLACE_GAME_NAME = {}
REPLACE_GAME_NAME.desc = "TODO"
REPLACE_GAME_NAME.rules = "TODO"

local quitGame

-- Uncomment this if you want to import server-specific data
-- local SERVER_LIST = {}
-- if misc.fileExists("plugins/server-specific/REPLACE_GAME_NAME-SP.lua") then
-- 	SERVER_LIST = require("plugins/server-specific/REPLACE_GAME_NAME-SP")
-- end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function REPLACE_GAME_NAME.startGame(message, playerList)
	local args = message.content:split(" ")

	local state = {
		GameChannel = message.channel,
		PlayerList = playerList
	}
	
	--state.GameID = games.registerGame(message.channel, "GameName", state, playerList)
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
	games.deregisterGame(state.GameID)	
end

return REPLACE_GAME_NAME