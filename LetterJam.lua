local games = require("Games")
local misc = require("Misc")

local letterjam = {}

--#############################################################################################################################################
--# Configurations                                                                                                                            #
--#############################################################################################################################################

local LETTERS = {
	"A", "A", "B", "B", "C", "C", "C", "D", "D", "D", "E", "E", "E", "E", "E", "E",
	"F", "F", "G", "G", "H", "H", "H", "I", "I", "I", "I", "K", "K", "L", "L", "M", "M",
	"N", "N", "N", "O", "O", "O", "O", "P", "P", "R", "R", "R", "R", "S", "S", "S", "S",
	"T", "T", "T", "U", "U", "U", "W", "W", "Y", "Y"
}

local TOKENSCHEMES = {
	nil, -- Letter Jam is not a one-player game
	{red = 6, green = 2, lockedGreen = 3},
	{red = 6, green = 2, lockedGreen = 3},
	{red = 4, green = 6, lockedGreen = 1},
	{red = 5, green = 5, lockedGreen = 1},
	{red = 6, green = 4, lockedGreen = 1}
}

local wordlist = "words/ae5.csv"

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function letterjam.startGame(message)
	local i = 1/0
	local playerList = message.mentionedUsers

	-- Check for errors
	if #playerList < 2 then
		message.channel:send("You need at least two players to play Letter Jam!")
		return
	end

	-- Create a new game and register it
	message.channel:send("Starting game...")
	local state = letterJamCreateGameInstance(message.channel, playerList, message)
	games.registerGame(message.channel, "LetterJam", state, playerList)
end

function letterjam.commandHandler(message, state)
	local args = message.content:split(" ")

	if state["Phase"] == 2 then
		if args[1] == "!flip" then
			if #args == 1 then 
				message.channel:send("You need to provide an order, eg !flip 12345")
				return
			end
			letterJamEndGameFlip(message.author, state, args[2])
		end
	end
	if args[1] == "!quit" then
		letterJamQuitGame(state)
	end
end

function letterjam.dmHandler(message, state)
	local args = message.content:split(" ")

	if state["Phase"] == 0 then
		if args[1] == "!pick" then
			letterJamPickWord(message.author, state, args[2])
		end
	elseif state["Phase"] == 1 then
		if args[1] == "!flip" then
			local guess = nil
			if #args > 1 then guess = args[2] end
			letterJamFlip(message.author, state, guess)
		elseif args[1] == "!noflip" then
			letterJamNoFlip(message.author, state)
		end
	elseif state["Phase"] == 2 then
		if args[1] == "!flip" then
			if #args == 1 then 
				message.channel:send("You need to provide an order, eg !flip 12345")
				return
			end
			letterJamEndGameFlip(message.author, state, args[2])
		end
	elseif state["Phase"] == -1 then
		-- Assign word
		local playerInfo = nil
		for idx,p in pairs(state["PlayerList"]) do
			if p["Player"] == message.author then playerInfo = p end
		end
		if playerInfo["Assignment"] then
			local assignmentInfo = state["PlayerList"][playerInfo["Assignment"]]
			if args[1] == "!pick" and #args > 1 then
				local chosenWord = string.upper(args[2])
				-- Validate that the word doesn't contain J, Q, V, X, or Z, and is alphabetic
				if letterJamValidateWord(chosenWord) then
					-- If the word is valid, give it that player and set Assignment to nil
					assignmentInfo["Intent"] = chosenWord
					assignmentInfo["Cards"] = misc.shuffleTable(letterJamTableifyWord(chosenWord))
					playerInfo["Assignment"] = nil
					message.author:send("You have chosen the word: " .. chosenWord)
					-- If everyone has given their word, move onto Phase 0
					local done = true
					for id,p in pairs(state["PlayerList"]) do
						if p["Assignment"] ~= nil then done = false end
					end
					-- Advance to Phase 0
					if done then
						state["Phase"] = 0
						for id,p in pairs(state["PlayerList"]) do
							letterJamGetStatus(p["Player"], state)
						end
					end
				else
					message.author:send("Pick a valid word (ie, a word without J, Q, V, X, or Z)")
				end
			else
				message.author:send("Pick a word with the !pick command, like this: `!pick PINGU`")
			end
		else
			message.author:send("You've already picked a word!")
		end
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function letterJamValidateWord(word)
	if word:match("[^ABCDEFGHIKLMNOPRSTUWY]") then return false else return true end
end

function letterJamCreateGameInstance(channel, playerList, message)
	local state = {
		GameChannel = channel,
		PlayerList = {},
		Tokens = {red = 0, green = 0, lockedGreen = 0},
		Deck = misc.shuffleTable(misc.shallowCopy(LETTERS)),
		Stands = {},
		BonusLetters = {"*"},
		CurrentWord = nil,
		Phase = 0 -- 0 = Someone picks a word, 1 = Everyone decides whether to flip, -1 = start of game word assignment
	}
	-- Populate each player reference table
	local idx = 1
	for id,player in pairs(playerList) do
		-- Player: 	A User object corresponding to the player
		-- Cards: 	A table containing the cards the player has in front of them, in order (not necessarily in an order that spells a word)
		-- Tokens: 	The number of tokens the player has received
		-- CardIdx: The index of the current card the player is on
		-- Flip:    Do they need to flip or noflip?
		-- BonusC.: Are they on a bonus card?
		-- Intent:  What word are they meant to be spelling?
		-- Assgnm.: Who are they assigning to?
		-- LOTS of terribly inefficient coding in this file is due to the fact that I chose to id based on user id rather than something useful. Too late to change
		state["PlayerList"][idx] = {Player = player, Cards = nil, Tokens = 0, CardIdx = 1, Flip = false, BonusCard = nil, Intent = nil, Assignment = nil}
		idx = idx + 1
	end
	-- Optionally, the players can assign each other words
	--TODO: In either case, remove the cards used from the deck
	local args = message.content:split(" ")
	if args[3] == "pick" then
		-- Let players pick words
		state["Phase"] = -1
		-- Assign everyone a player to give a word to
		for i=1,#state["PlayerList"] do
			if i == #state["PlayerList"] then state["PlayerList"][i]["Assignment"] = 1
			else state["PlayerList"][i]["Assignment"] = i+1 end
			state["PlayerList"][i]["Player"]:send("Pick a word for " .. state["PlayerList"][state["PlayerList"][i]["Assignment"]]["Player"].name .. "!")
		end
	else
		local wordsTable = misc.parseCSV(wordlist)
		local idx = 1
		for id,player in pairs(playerList) do
			state["PlayerList"][idx]["Intent"] = wordsTable[math.random(#wordsTable)]
			state["PlayerList"][idx]["Cards"] = misc.shuffleTable(letterJamTableifyWord(state["PlayerList"][idx]["Intent"]))
			idx = idx + 1
		end
	end
	-- Populate stands
	local standCt = 6 - #state["PlayerList"]
	local standSize = 7
	while standCt > 0 do
		local newStand = {Current = nil, Reserve = {}, Marked = false}
		-- Get cards out of deck and place them in reserve
		local idx = 1
		while idx <= standSize do
			newStand["Reserve"][idx] = state["Deck"][#state["Deck"]]
			state["Deck"][#state["Deck"]] = nil
			idx = idx + 1
		end
		-- Move last letter from reserve to current
		newStand["Current"] = newStand["Reserve"][#newStand["Reserve"]]
		newStand["Reserve"][#newStand["Reserve"]] = nil
		-- Assign stand to state and continue
		state["Stands"][standCt] = newStand
		standSize = standSize + 1
		standCt = standCt - 1
	end
	-- Populate tokens
	state["Tokens"] = misc.shallowCopy(TOKENSCHEMES[#state["PlayerList"]])
	-- Only give status if everyone has a word
	if state["Phase"] ~= -1 then
		for id,player in pairs(playerList) do
			letterJamGetStatus(player, state)
		end
	end
	return state
end

function letterJamTableifyWord(word)
	wordTbl = {}
	for i = 1, #word do
    	local c = word:sub(i,i)
    	wordTbl[i] = c
	end
	return wordTbl
end

function letterJamGetStatus(user, state)
	local msg = "Status:\n```\n"
	-- A player is allowed to see the following:
	-- The current letter of every other player in the game, their token count, and which card they're on
	local pString = "%-15s [%d/%d] %s {%s} %s\n"
	local sString = "Stand #%d        [%d]   %s {%s}\n"
	local tString = "Tokens Remaining: %d Red, %d Green (%d Locked)"
	local idx = 1
	for player,info in pairs(state["PlayerList"]) do
		local tokens = string.rep("X", info["Tokens"])
		if info["Player"] == user then
			msg = msg .. string.format(pString, info["Player"].name, info["CardIdx"], #info["Cards"], "-", "-", tokens)
		else
			local letter = ""
			if info["CardIdx"] > #info["Cards"] then letter = string.upper(info["BonusCard"])
			else letter = string.upper(info["Cards"][info["CardIdx"]]) end
			msg = msg .. string.format(pString, info["Player"].name, info["CardIdx"], #info["Cards"], letter, tostring(idx), tokens)
			idx = idx + 1
		end
	end
	-- What letter is currently on every stand, and how many cards are remaining in the stand's deck
	for stand,contents in pairs(state["Stands"]) do
		msg = msg .. string.format(sString, stand, #contents["Reserve"], contents["Current"], tostring(idx))
		idx = idx + 1
	end
	-- Any bonus letters which have been acquired
	msg = msg .. "Bonus Letters:       "
	if state["BonusLetters"] then
		for i,letter in pairs(state["BonusLetters"]) do msg = msg .. " " .. string.upper(letter) end
	end
	msg = msg .. "\n"
	-- The current tokens remaining, broken down by color
	msg = msg .. string.format(tString, state["Tokens"]["red"], state["Tokens"]["green"]+state["Tokens"]["lockedGreen"], state["Tokens"]["lockedGreen"])
	-- The positions of the chips, if any have been doled out (and what the chips spell, with relevant omissions)
	msg = msg .. "```"
	user:send(msg)
end

function letterJamPickWord(user, state, word)
	-- Check if there are tokens the player can take
	if state["Tokens"]["green"] == 0 then
		for player,info in pairs(state["PlayerList"]) do
			if info["Player"] == user then
				if info["Tokens"] == 0 or (info["Tokens"] < 3 and #state["PlayerList"] == 2) or (info["Tokens"] < 2 and #state["PlayerList"] == 3) then
					goto next
				else
					user:send("You can't pick a word, there are no more green tokens to take!")
					return
				end
			end
		end
	end
	::next::
	-- Get letters by number
	local lettersTbl = {}
	local playersTbl = {}
	local standsTbl = {}
	idx = 1
	for player,info in pairs(state["PlayerList"]) do
		if info["Player"] ~= user then
			local letter = ""
			if info["CardIdx"] > #info["Cards"] then letter = string.upper(info["BonusCard"])
			else letter = string.upper(info["Cards"][info["CardIdx"]]) end
			lettersTbl[idx] = letter
			playersTbl[idx] = player
			idx = idx + 1
		end
	end
	for stand,contents in pairs(state["Stands"]) do
		lettersTbl[idx] = contents["Current"]
		standsTbl[idx] = stand
		idx = idx + 1
	end
	-- Validate word is entirely numbers in range and wildcard, and at least one player was used
	--TODO: Use bonus letters for word
	local valid = true
	local playerUsed = false
	for i=1, #word do
		local c = word:sub(i,i)
		if c == "*" then goto continue end
		d = tonumber(c)
		if d == nil or d > #lettersTbl or d < 1 then
			user:send("Error: " .. c .. " is not a number!")
			valid = false
			i = #word
			goto continue
		end
		if playersTbl[d] ~= nil then playerUsed = true end
		::continue::
	end
	if not playerUsed then valid = false end
	if valid then
		state["CurrentWord"] = word
		for n,stand in pairs(state["Stands"]) do
			for i=1, #word do
				if standsTbl[tonumber(word:sub(i,i))] == n then
					stand["Marked"] = true
				end
			end
		end
		-- Give the player a token
		for player,info in pairs(state["PlayerList"]) do
			if info["Player"] == user then
				if info["Tokens"] == 0 or (info["Tokens"] < 3 and #state["PlayerList"] == 2) or (info["Tokens"] < 2 and #state["PlayerList"] == 3) then
					state["Tokens"]["red"] = state["Tokens"]["red"] - 1
				else
					state["Tokens"]["green"] = state["Tokens"]["green"] - 1
				end
				info["Tokens"] = info["Tokens"] + 1
			end
		end
		-- Construct word for every player and send it to them
		for player,info in pairs(state["PlayerList"]) do
			local outputWord = ""
			for i=1, #word do
				if playersTbl[tonumber(word:sub(i,i))] == player then
					outputWord = outputWord .. "-"
					info["Flip"] = true
				elseif word:sub(i,i) == "*" then outputWord = outputWord .. "*"
				else outputWord = outputWord .. lettersTbl[tonumber(word:sub(i,i))] end
			end
			--TODO: Get number representation of the word for each player and send it to each player, so that they know which letters are whose
			info["Player"]:send("The word is: `" .. outputWord .. "`")
		end
		-- Advance to next phase
		letterJamAdvancePhase(state)
	else
		user:send("Invalid word! Did you use at least one player's letter?")
	end
end

function letterJamAdvancePhase(state)
	if state["Phase"] == 0 then
		state["CurrentWord"] = nil
		state["Phase"] = 1
	elseif state["Phase"] == 1 then
		for i,stand in pairs(state["Stands"]) do
			if stand["Marked"] then
				-- Advance stand
				if #stand["Reserve"] > 0 then
					stand["Current"] = stand["Reserve"][#stand["Reserve"]]
					stand["Reserve"][#stand["Reserve"]] = nil
					if #stand["Reserve"] == 0 then state["Tokens"]["green"] = state["Tokens"]["green"] + 1 end
				else 
					stand["Current"] = state["Deck"][#state["Deck"]]
					state["Deck"][#state["Deck"]] = nil
				end
				stand["Marked"] = false
			end
		end
		if state["Tokens"]["red"] == 0 then
			state["Tokens"]["green"] = state["Tokens"]["green"] + state["Tokens"]["lockedGreen"]
			state["Tokens"]["lockedGreen"] = 0
		end
		if state["Tokens"]["red"] == 0 and state["Tokens"]["green"] == 0 then
			state["Phase"] = 2
			for player,info in pairs(state["PlayerList"]) do info["Flip"] = false end
			letterJamDoEndGame(state)
		else
			state["Phase"] = 0
		end
		for id,info in pairs(state["PlayerList"]) do letterJamGetStatus(info["Player"], state) end
	end
end

function letterJamFlip(user, state, guess)
	local found = false
	for player,info in pairs(state["PlayerList"]) do
		if user == info["Player"] and info["Flip"] == true then
			found = true
			if info["CardIdx"] > #info["Cards"] then
				if guess then
					if string.upper(guess) == info["BonusCard"] then
						user:send("Your guess was correct!")
						state["BonusLetters"][#state["BonusLetters"]+1] = info["BonusCard"]
					else
						user:send("Your guess was incorrect!")
					end
				else
					user:send("You need to guess a letter, since you're on a bonus card!")
					return
				end
			end
			info["CardIdx"] = info["CardIdx"] + 1
			if info["CardIdx"] > #info["Cards"] then
				-- Draw a new bonus card
				info["BonusCard"] = state["Deck"][#state["Deck"]]
				state["Deck"][#state["Deck"]] = nil
			end
			user:send("Card flipped!")
			letterJamNoFlip(user, state, true)
		end
	end
	if not found then user:send("It's not your turn to flip!") end
end

function letterJamNoFlip(user, state, flipped)
	flipped = flipped or false
	if not flipped then user:send("Card not flipped!") end
	-- Update player flip status
	local unflipped = false
	for player,info in pairs(state["PlayerList"]) do
		if user == info["Player"] then
			info["Flip"] = false
		end
		if info["Flip"] then unflipped = true end
	end
	-- Send confirmation message
	-- If no players left to flip, advance to the next phase
	if not unflipped then letterJamAdvancePhase(state) end
end

function letterJamDoEndGame(state)
	for player,info in pairs(state["PlayerList"]) do
		info["Player"]:send("It's time for the final round!")
		info["Player"]:send("Reveal your cards in the right order with the !flip command!")
	end
end

function letterJamEndGameFlip(user, state, order)
	-- Validate that the order is indeed a permutation of the numbers 1 through #cards
	local result = ""
	local bonuses = misc.shallowCopy(state["BonusLetters"])
	local used = {}
	local playerInfo = nil
	for player, info in pairs(state["PlayerList"]) do
		if info["Player"] == user then playerInfo = info end
	end
	if #order < #playerInfo["Intent"] then
		user:send("You need to flip at least " .. #playerInfo["Intent"] .. " cards!")
		return
	end
	for i=1, #order do
		num = tonumber(order:sub(i,i))
		if num and num > 0 and num <= #playerInfo["Cards"] and not used[num] then
			result = result .. playerInfo["Cards"][num]
			used[num] = true
		elseif num and used[num] then
			user:send(order:sub(i,i) .. " was used more than once!")
			return
		elseif not num and misc.valueInList(string.upper(order:sub(i,i)), bonuses) then
			result = result .. string.upper(order:sub(i,i))
			table.remove(bonuses, misc.getKey(string.upper(order:sub(i,i)), bonuses))
		else
			user:send(order:sub(i,i) .. " isn't a number or is out of bounds!")
			return
		end
	end
	local bonusString = ""
	state["BonusLetters"] = bonuses
	for k,c in pairs(bonuses) do bonusString = bonusString .. c end
	state["GameChannel"]:send(user.name .. " flipped their cards and revealed... " .. string.upper(result) .. "! (Original word: " .. playerInfo["Intent"] .. ")\nRemaining bonus letters: " .. bonusString)
	playerInfo["Flip"] = true
	-- Check if everyone has flipped
	local done = true
	for player,info in pairs(state["PlayerList"]) do if not info["Flip"] then done = false end end
	if done then
		state["GameChannel"]:send("Game over! And remember: if mostly everyone spelled a word, then you mostly won!")
		letterJamQuitGame(state)
	end
end

function letterJamQuitGame(state)
	state["GameChannel"]:send("Quitting game...")
	games.deregisterGame(state["GameChannel"])
end

return letterjam