local games = require("Games")
local misc = require("Misc")

local peacock = {}
peacock.desc = "Chameleon, but in reverse"
peacock.rules = "TODO"

local quitGame, removeUnderscores, displayWords

local wl = require("words/Chameleon-Wordlists")
local WORDLISTS_VANILLA = wl[1]
local WORDLISTS_CUSTOM = wl[2]

-- Uncomment this if you want to import server-specific data
-- local SERVER_LIST = {}
-- if misc.fileExists("plugins/server-specific/peacock-SP.lua") then
-- 	SERVER_LIST = require("plugins/server-specific/peacock-SP")
-- end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function peacock.startGame(message, playerList)
	local args = message.content:split(" ")

	local state = {
		GameChannel = message.channel,
		PlayerList = playerList,
		Lists = nil,
		Wordlist = nil,
		Words = nil,
		Peacock = message.author
	}

	state["Lists"] = misc.getRandomIndices(WORDLISTS_VANILLA,10)
	state["Wordlist"] = misc.getRandomIndex(state["Lists"])
	state["Words"] = WORDLISTS_VANILLA[state["Wordlist"]]

	for idx,player in pairs(playerList) do
		if player.id == message.author.id then player:send(displayWords(state, true)) else player:send(displayWords(state, false)) end
	end
	
	state.GameID = games.registerGame(message.channel, "Peacock", state, playerList)
end

function peacock.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end
end

function peacock.dmHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!gimme" and message.author ~= state["Peacock"] then
		pickWord(state, message.author)
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameID)	
end

function removeUnderscores(word)
	local o = ""
	for i = 1, #word do
    	local c = word:sub(i,i)
    	if c == "_" then o = o .. " " else o = o .. c end
	end
	return o
end

function displayWords(state, peacock)
	local output
	if not peacock then
		output = "Category: " .. removeUnderscores(state["Wordlist"]) .. "\nWords:\n"
		for idx,word in pairs(state["Words"]) do
			output = output .. "[" .. idx .. "] " .. word .. "\n"
		end
	else
		output = "**You are the Peacock!** Word Lists:\n"
		for name,list in pairs(state["Lists"]) do
			output = output .. "__" .. removeUnderscores(name) .. "__, "
		end
		output = output:sub(1,-3)
	end

	return output
end

function pickWord(state, player)
	local i = math.random(1,16)
	player:send("Your word is: [" .. i .. "] " .. state["Words"][i])
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameID)	
end

return peacock