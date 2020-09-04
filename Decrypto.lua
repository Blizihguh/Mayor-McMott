local games = require("Games")
local misc = require("Misc")
local decrypto = {}

-- Enum for teams
local teams = {GREEN = 0, RED = 1}
-- Local functions
local dmYourSheet, dmTheirClues

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function decrypto.startGame(message)
	-- Assign players to teams
	local playerList = {}
	local greenList = {}
	local redList = {}
	local team = teams.GREEN
	for idx,player in pairs(message.mentionedUsers) do
		table.insert(playerList, {player, team})
		if team == teams.GREEN then
			table.insert(greenList, player)
			team = teams.RED 
		else
			table.insert(redList, player)
			team = teams.GREEN
		end
	end
	-- Set up gamestate
	local state = {
		GameChannel = message.channel,
		PlayerList = playerList,
		GreenTeam = greenList,
		RedTeam = redList,
		GreenWords = {}, -- The secret words for each team
		RedWords = {},
		GreenMisses = 0, -- Times each team guessed the wrong numbers for their own clues
		RedMisses = 0,
		GreenWins = 0, -- Times each team successfully intercepted the opposing team's clues
		RedWins = 0,
		GreenGuesses = {}, -- {Round = {Word Number = {Word, Real#, Guessed#}, ...}, ...} 
		RedGuesses = {},
		GreenIntercepts = {}, -- {Round = {Word1, Word2, Word3, GuessString, GuessVeracity}}
		RedIntercepts = {}
	}
	-- DEBUG
	state.GreenGuesses = {
		[1] = {[1] = {"Fog", 1,1}, [2] = {"Fata Morgana", 2,3}, [3] = {"Traipsing", 4,2}},
		[2] = {[1] = {"Schlepping", 2,2}, [2] = {"Spooky", 3,3}, [3] = {"Dew", 1,1}}
	}
	state.RedGuesses = {
		[1] = {[1] = {"Garfield", 1, 1}, [2] = {"Bandage", 2, 2}, [3] = {"Coatrack", 3, 3}},
		[2] = {[1] = {"Nixon", 1, 1}, [2] = {"Tumor", 2, 2}, [3] = {"House Arrest", 4, 4}}
	}
	state.GreenWords = {"Mist", "Walking", "Horror", "Kirinji"}
	state.RedWords = {"President", "Medical", "Hat", "Police"}
	state.GreenIntercepts = {
		[1] = {"Garfield", "Bandage", "Coatrack", "432", false},
		[2] = {"Nixon", "Tumor", "House Arrest", "124", true}
	}
	dmYourSheet(state, teams.GREEN, message.author)
	dmTheirClues(state, teams.GREEN, message.author)
end

function decrypto.commandHandler(message, state)
end

function decrypto.dmHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function dmYourSheet(state, team, user)
	-- DM the private info for the player's team (secret words, clues, guesses, answers, and list of clues for each word)
	local words = (team == teams.GREEN and state.GreenWords or state.RedWords)
	local guesses = (team == teams.GREEN and state.GreenGuesses or state.RedGuesses)
	local output = "Your top secret words:\n"
	-- Secret words
	misc.printTable(words)
	local commaCounter = 0
	for idx, val in ipairs(words) do
		output = output .. idx .. ": **" .. val .. "**"
		if commaCounter < 3 then output = output .. ", "; commaCounter = commaCounter + 1 end
	end
	output = output .. "\n```"
	-- Clues so far, guesses, and answers
	for round, info in ipairs(guesses) do
		output = output .. "Round " .. round .. ": "
		commaCounter = 0
		for idx, wordInfo in ipairs(info) do
			output = output .. wordInfo[1] .. " [" .. wordInfo[2] .. "/" .. wordInfo[3] .. "]"
			if commaCounter < 2 then output = output .. ", "; commaCounter = commaCounter + 1 end
		end
		output = output .. "\n"
	end
	output = output .. "```"
	-- List of clues for each word
	local clueLists = {{}, {}, {}, {}}
	for round, info in ipairs(guesses) do
		for idx, wordInfo in ipairs(info) do
			local target = wordInfo[3]
			-- If it's been revealed which word the clue is for, append it to the proper list
			if target ~= "-" then table.insert(clueLists[target], wordInfo[1]) end
		end
	end
	output = output .. "```"
	for idx,list in ipairs(clueLists) do
		output = output .. words[idx] .. ": "
		commaCounter = 0
		for i,word in ipairs(list) do
			output = output .. word
			if commaCounter < #list-1 then output = output .. ", "; commaCounter = commaCounter + 1 end
		end
		output = output .. "\n"
	end
	-- Send output to user who needs it
	output = output .. "```"
	user:send(output)
end

function dmTheirClues(state, team, user)
	-- DM the public info for the other team (set of clues in each round and your guesses for them, and whether your guesses were right)
	local info = (team == teams.GREEN and state.GreenIntercepts or state.RedIntercepts)
	local output = "Their clues:\n"
	for round,data in ipairs(info) do
		local fString = (data[5] and "Round %i: **%s, %s, %s: [%s]**\n" or "Round %i: %s, %s, %s: [%s]\n")
		output = output .. string.format(fString, round, data[1], data[2], data[3], data[4])
	end
	user:send(output)
end

return decrypto