-- If you're editing this file into a plugin, be sure to put it in the plugins folder! It won't be loaded unless it's in there.

-- Every game imports the Games module, which acts as an intermediary between MayorMcMott and your plugin.
-- You should only need to use games.registerGame() and games.deregisterGame().
local games = require("Games")
-- The Misc module contains general utility functions. You'll probably want it for convenience's sake
local misc = require("Misc")

-- Lua modules work by returning a table containing all their functions. MayorMcMott plugins work the same!
-- When you define the handlers your game uses, you'll do it as part of this table (see the "Main Functions" section below)
-- Note that you do not need to, and should not, include other functions as part of this table.
local REPLACE_GAME_NAME = {}
-- Replace these with the description and a link to the rules of the game, respectively
REPLACE_GAME_NAME.desc = "TODO"
REPLACE_GAME_NAME.rules = "TODO"
-- The following option(s) should be set only if you need them. If you don't set them, they will default to nil.
-- startInDMs takes three options: nil (not allowed), true (allowed), and "vcOnly" (only allowed if the user is in a voice channel)
--REPLACE_GAME_NAME.startInDMs = true

--IMPORTANT: Declare all function names (besides the startGame/commandHandler/optional dmHandler and reactHandler functions) as local variables here.
--           If you don't do this, they will be imported as global functions, possibly disrupting other games!
local quitGame

-- Uncomment this if you want to import server-specific data
-- local SERVER_LIST = {}
-- if misc.fileExists("plugins/server-specific/REPLACE_GAME_NAME-SP.lua") then
-- 	SERVER_LIST = require("plugins/server-specific/REPLACE_GAME_NAME-SP")
-- end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function REPLACE_GAME_NAME.startGame(message, playerList, channel)
	-- args[1] will be !start/!vc, and args[2] will be the game name.
	-- The actual arguments, if the game takes them, will start at args[3]
	local args = message.content:split(" ")

	-- Any state that your game tracks between commands needs to be stored to this table
	-- When you finish initializing the game, you save the state table with games.registerGame (see below)
	-- When players call commands, a reference to this table will be passed to the command handler, so that you can use or modify the game's state
	local state = {
		GameChannel = channel,
		PlayerList = playerList -- You may want to create a new list with more information tracked per player, and save that to state
	}

	-- Use the name as it appears in MayorMcMott.lua's GAME_LIST table, and the same player list from the function args (don't modify it!)
	-- For very simple games that don't need commands (eg Chameleon), just delete this line, as well as the quitGame function
	--state.GameID = games.registerGame(channel, "GameName", state, playerList)
end

function REPLACE_GAME_NAME.commandHandler(message, state)
	-- args[1] will be the command name
	local args = message.content:split(" ")

	-- You can use whatever command names you want. But MottBot uses some command names frequently.
	-- If you'd like to stick to convention, here are the most common MottBot command names:

	--!pick: The most common command for MottBot. Good for picking from a list, or just when there's no better command name
	--!clue: Generally for giving clues in word games (like Decrypto or Codenames)
	--!reveal: For revealing something publicly (eg: the article in Trickipedia, each player's guess in Medium)
	--!quit: For quitting the game early
end

--OPTIONAL: Do not include this function if you don't need it!
function REPLACE_GAME_NAME.dmHandler(message, state)
	-- args[1] will be the command name
	local args = message.content:split(" ")
end

--OPTIONAL: Do not include this function if you don't need it!
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