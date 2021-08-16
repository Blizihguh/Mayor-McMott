local games = require("Games")
local misc = require("Misc")

local wavelength = {}

local createGameInstance

--#############################################################################################################################################
--# Configurations                                                                                                                            #
--#############################################################################################################################################

local AXES = {"GOOD or BAD?", "HOT or COLD?"}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function wavelength.startGame(message)
	local playerList = message.mentionedUsers

	-- Check for errors
	if #playerList < 2 then
		message.channel:send("You need at least two players to play Medium!")
		return
	end

	-- Create a new game and register it
	message.channel:send("Starting game...")
	local state = createGameInstance(message.channel, playerList, message)
	games.registerGame(message.channel, "Wavelength", state, playerList)
end

function wavelength.commandHandler(message)
	--
end

function wavelength.dmHandler(message)
	--
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function createGameInstance(channel, playerList, message)
	--
end