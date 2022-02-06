local games = require("Games")
local misc = require("Misc")
local chameleon = {}
chameleon.desc = "A social deduction word game for 3+ players. All players are given the same word in secret, except for the Chameleon, who must try to blend in -- at least until they figure out what the word is."
chameleon.rules = "https://bigpotato.com/blog/how-to-play-the-chameleon-instructions/> (see also: <https://github.com/Blizihguh/Mayor-McMott/wiki/Chameleon)"

local displayWords, dmStatus, oopsAllChameleons, removeUnderscores

local wl = require("words/Chameleon-Wordlists")
local WORDLISTS_VANILLA = wl[1]
local WORDLISTS_CUSTOM = wl[2]

-- Table definitions for injoke cards that only get pulled up on specific servers can be placed in a separate file
local SERVER_LIST = {}
if misc.fileExists("plugins/server-specific/Chameleon-SP.lua") then
	SERVER_LIST = require("plugins/server-specific/Chameleon-SP")
end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function chameleon.startGame(message, playerList)
	local state = {
		GameChannel = message.channel,
		Wordlist = nil,
		WordIdx = math.random(16),
		PlayerList = playerList,
		Chameleon = nil,
		Words = {}
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
	-- Do we want to just pick the card?
	if wordlistsForThisGame[args[3]] ~= nil then
		state["Wordlist"] = args[3]
	else
		state["Wordlist"] = misc.getRandomIndex(wordlistsForThisGame)
	end
	state["Words"] = wordlistsForThisGame[state["Wordlist"]]

	state["Chameleon"] = misc.getRandomIndex(playerList)
	local roll = math.random(1000)
	if roll < 15 then
		if message.guild.id == "353359832902008835" then
			dmStatus(state) -- Removed from server by request
		else
			oopsAllChameleons(state) -- 0.015% chance; if you're Chameleon, there is a ~5.5% chance it's this easter egg
		end
	elseif roll < 35 then
		if message.guild.id == "353359832902008835" then
			dmStatus(state)
		else
			oopsAlmostAllChameleons(state) -- 0.02% chance; if you're Chameleon, there is a ~5.5% chance it's this easter egg
		end
	elseif roll < 55 then
		if message.guild.id == "353359832902008835" then
			dmStatus(state)
		else
			-- Pick a different card for every player
			local cards = {}
			local ct = #playerList
			while ct > 0 do
				local newCard = misc.getRandomIndex(wordlistsForThisGame)
				if not misc.valueInList(newCard, cards) then
					table.insert(cards, newCard)
					ct = ct - 1
				end
			end
			misc.printTable(cards)
			oopsAllDifferentWords(state, cards, wordlistsForThisGame) -- Easter egg that doesn't actually affect the odds of being Chameleon
		end
	else
		dmStatus(state) -- If you're Chameleon, there is an ~11.0% chance it's an easter egg, and an ~89% chance it's normal
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function removeUnderscores(word)
	local o = ""
	for i = 1, #word do
    	local c = word:sub(i,i)
    	if c == "_" then o = o .. " " else o = o .. c end
	end
	return o
end

function displayWords(state, bold)
	local output = "Category: " .. removeUnderscores(state["Wordlist"]) .. "\nWords: "
	for idx,word in pairs(state["Words"]) do
		if bold and idx == state["WordIdx"] then output = output .. "**__[" .. word .. "]__**, "
		else output = output .. word .. ", " end
	end
	output = output:sub(1,-3)
	if not bold then output = output .. "\n**You are the Chameleon!**" end
	return output
end

function dmStatus(state)
	for id,player in pairs(state["PlayerList"]) do
		player:send(displayWords(state, not (id == state["Chameleon"])))
	end
end

function oopsAllDifferentWords(state, cards, wordlistsForThisGame)
	local ct = 1
	misc.printTable(cards)
	print(ct)
	print(cards[ct])
	for id,player in pairs(state["PlayerList"]) do
		state["Wordlist"] = cards[ct]
		state["Words"] = wordlistsForThisGame[state["Wordlist"]]
		ct = ct + 1
		player:send(displayWords(state, (id == state["Chameleon"])))
	end
end

function oopsAlmostAllChameleons(state)
	for id,player in pairs(state["PlayerList"]) do
		player:send(displayWords(state, (id == state["Chameleon"])))
	end
end

function oopsAllChameleons(state)
	for id,player in pairs(state["PlayerList"]) do
		player:send(displayWords(state, false))
	end
end

return chameleon