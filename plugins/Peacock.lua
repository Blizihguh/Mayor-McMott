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
local SERVER_LIST = {}
if misc.fileExists("plugins/server-specific/Chameleon-SP.lua") then
	SERVER_LIST = require("plugins/server-specific/Chameleon-SP")
end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function peacock.startGame(message, playerList)
	local args = message.content:split(" ")

	local state = {
		GameChannel = message.channel,
		PlayerList = playerList,
		Lists = nil,
		Cards = {},
		Wordlist = nil,
		Words = nil,
		Peacock = message.author
	}

	local wordlistsForThisGame = {}
	-- Do we want custom cards?
	local args = message.content:split(" ")
	if args[3] ~= "vanilla" then
		misc.fuseDicts(wordlistsForThisGame, WORDLISTS_CUSTOM)
		-- If so, do we have server cards?
		for server,list in pairs(SERVER_LIST) do
			if message.guild.id == server then misc.fuseDicts(wordlistsForThisGame, list) end
		end
	end
	-- Do we want vanilla cards?
	if args[3] ~= "custom" then
		misc.fuseDicts(wordlistsForThisGame, WORDLISTS_VANILLA)
	end

	state["Lists"] = misc.getRandomIndices(wordlistsForThisGame,10)
	state["Wordlist"] = misc.getRandomIndex(state["Lists"])
	state["Words"] = misc.shuffleTable(misc.shallowCopy(wordlistsForThisGame[state["Wordlist"]]))

	-- Slightly spaghetti, but easier than trying to store this info in some other way
	local idx = 1
	for name,list in pairs(state["Lists"]) do
		state["Cards"][idx] = name
		idx = idx + 1
	end

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
	elseif args[1] == "!card" then
		displayCard(state, message.author, args[2])
	elseif args[1] == "!status" then
		if state["Peacock"] == message.author then message.author:send(displayWords(state, true)) else message.author:send(displayWords(state, false)) end
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

function displayCard(state, author, cardIdx)
	cardIdx = tonumber(cardIdx)
	if state["Cards"][cardIdx] == nil then
		author:send("That card isn't in this game, homie!")
	else
		local output = "Category: " .. removeUnderscores(state["Cards"][cardIdx]) .. "\nWords: "
		for idx,word in pairs(state["Lists"][state["Cards"][cardIdx]]) do output = output .. word .. ", " end
		output = output:sub(1,-3)
		author:send(output)
	end
end

function displayWords(state, peacock)
	local output
	if not peacock then
		output = "Category: " .. removeUnderscores(state["Wordlist"]) .. "\nWords:\n"
		for idx,word in pairs(state["Words"]) do
			output = output .. "[" .. idx .. "] " .. word .. "\n"
		end
		output = output .. "Word Lists: "
		for idx,name in pairs(state["Cards"]) do
			output = output .. "[" .. idx .. "] __" .. removeUnderscores(name) .. "__ "
			idx = idx + 1
		end
	else
		output = "**You are the Peacock!** Word Lists:\n"
		for idx,name in pairs(state["Cards"]) do
			output = output .. "[" .. idx .. "] " .. removeUnderscores(name) .. "\n"
			idx = idx + 1
		end
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