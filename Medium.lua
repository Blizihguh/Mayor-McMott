local games = require("Games")
local misc = require("Misc")

local medium = {}

--#############################################################################################################################################
--# Configurations                                                                                                                            #
--#############################################################################################################################################

local HANDSIZE = 6

local WEREWORDLISTS = {
	"supereasy", "easy", "medium", "hard", "ridiculous", "test"
}

local WORDLISTS = {
	-- TODO: Add Medium wordlists
}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function medium.startGame(message)
	local playerList = message.mentionedUsers
	local channelList = message.mentionedChannels

	-- Check for errors
	if #playerList < 2 then
		message.channel:send("You need at least two players to play Medium!")
		return
	end

	if #channelList > 1 then
		message.channel:send("You only need to mention one channel (for spectating other players' turns)!")
		return
	elseif #channelList == 1 and (channelList[1][1] == message.channel.id) then
		message.channel:send("Mention a channel for players to spectate in (ie, not the game channel itself)!")
		return
	end

	-- Create a new game and register it
	message.channel:send("Starting game...")
	local state = nil
	if #channelList == 1 then
		state = mediumCreateGameInstance(message.channel, message.guild:getChannel(channelList[1][1]), playerList, message)
	else
		state = mediumCreateGameInstance(message.channel, nil, playerList, message)
	end
	games.registerGame(message.channel, "Medium", state, playerList)

	-- DM players their hands
	for idx,playerInfo in pairs(state["PlayerList"]) do
		mediumDMHand(state, idx)
	end

	mediumSendStatusMessage(state)
end

function medium.commandHandler(message, state)
	local args = message.content:split(" ")

	if args[1] == "!status" then
		misc.printTable(state)
		mediumSendStatusMessage(state)
	elseif args[1] == "!score" then
		mediumSendScoreMessage(state)
	elseif args[1] == "!quit" then
		mediumQuitGame(state)
	elseif args[1] == "!ready" then
		if mediumIsPlayerIdx(state, message.author, state["CurrentPlayer"]) or mediumIsPlayerIdx(state, message.author, state["NextPlayer"]) then
			if state["Guess1"] ~= nil and state["Guess2"] ~= nil and state["Revealed"] ~= true then
				mediumDoGuesses(state)
			elseif state["Revealed"] == true then
				message.channel.send("You already revealed your guesses! (Use !success or !failure to proceed)")
			else
				message.channel:send("Someone hasn't picked a word yet! (Presumably not you? :thinking:)")
			end
		else
			message.channel:send("It's not your turn!")
		end
	elseif args[1] == "!success" then
		if state["Revealed"] == true then
			mediumUpdatePhase(state, true)
		else
			message.channel:send("You have to reveal before you can tell if you succeeded...")
		end
	elseif args[1] == "!failure" then
		if state["Revealed"] == true then
			mediumUpdatePhase(state, false)
		else
			message.channel:send("You have to reveal before you can tell if you failed...")
		end
	end
end

function medium.dmHandler(message, state)
	local args = message.content:split(" ")
	local idx = mediumGetIdxFromPlayer(state, message.author)

	-- Anytime commands
	if args[1] == "!hand" then
		if idx == 0 then
			misc.printTable(state)
			message.channel:send("You're... not a player? How did you even get this message?")
		else
			mediumDMHand(state, idx)
		end
		return
	elseif args[1] == "!score" then
		mediumDMScore(state, idx)
		return
	end
	-- Phase-specific commands
	if state["Phase"] == -2 or state["Phase"] == -1 then
		-- DM author is attempting to pick a card out of their hand
		if args[1] == "!pick" then
			mediumPickCard(state, idx, args[2], message.channel)
		end
	elseif state["Phase"] == 1 or state["Phase"] == 2 or state["Phase"] == 3 then
		-- Melding phase
		if mediumIsPlayerIdx(state, message.author, state["CurrentPlayer"]) then
			-- DM author is current player
			if args[1] == "!pick" then
				state["Guess1"] = args[2]
				message.channel:send("Your guess is: " .. state["Guess1"])
			end
		elseif mediumIsPlayerIdx(state, message.author, state["NextPlayer"]) then
			-- DM author is next player
			if args[1] == "!pick" then
				state["Guess2"] = args[2]
				message.channel:send("Your guess is: " .. state["Guess2"])
			end
		end
	else
		-- Error?
		print("ERROR: Game Phase " .. state["Phase"])
		misc.printTable(state)
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function mediumCreateGameInstance(channel, specChannel, playerList, message)
	local instance = {
		GameChannel = channel,
		SpecChannel = specChannel,
		PlayerList = {},			-- Each player is a table containing a player reference, a table holding their hand, and a table holding their score chips
		Deck = nil,
		Balls = 0, 					-- How many crystal balls have been drawn?
		StartingPlayer = nil, 		-- The starting player goes first, as per Tanto Cuore tradition
		CurrentPlayer = nil,
		NextPlayer = nil,
		Phase = -2,					-- -2: First player picking card; -1: Second player picking card; 1-3: 1st, 2nd, 3rd guesses
		Revealed = false, 			-- Have the guesses been revealed yet?
		Word1 = nil,				-- The first public word
		Word2 = nil,				-- The second public word
		Guess1 = nil,				-- The first private word (becomes Word1 if not matched to Guess2)
		Guess2 = nil 				-- The second private word (becomes Word2 if not matched to Guess1)
	}
	-- Create deck
	-- TODO: Get the decks and pass them in here
	instance["Deck"] = mediumCreateDeck(channel, {"supereasy"})
	-- Create playerlist with individual hands
	local idx = 1
	for id,player in pairs(playerList) do
		-- Score = {Left Player Score, Right Player Score}
		-- These are stored as tables instead of ints because the number of chips is public,
		-- but the value of each chip is private
		instance["PlayerList"][idx] = {Player = player, Hand = {}, Score = {Left = {}, Right = {}}}
		mediumDrawCards(instance, idx)
		idx = idx + 1
	end
	-- Pick starting player randomly
	instance["CurrentPlayer"] = math.random(1,#instance["PlayerList"])
	instance["StartingPlayer"] = instance["CurrentPlayer"]
	instance["NextPlayer"] = instance["CurrentPlayer"] + 1
	if instance["NextPlayer"] > #instance["PlayerList"] then instance["NextPlayer"] = 1 end
	return instance
end

function mediumCreateDeck(channel, deckList)
	deck = {}

	for idx,name in pairs(deckList) do
		if misc.valueInList(name, WEREWORDLISTS) then
			-- It's a werewords list
			local new = misc.parseCSV("words/words_" .. name .. ".csv")
			misc.fuseLists(deck, new)
		elseif misc.valueInList(name, WORDLISTS) then
			-- It's a medium list
			-- TODO
			local new = {}
			misc.fuseLists(deck, new)
		else
			channel:send("Word list " .. name .. " not found!")
		end
	end
	misc.shuffleTable(deck)
	-- Shuffle crystal balls in (represented by the integer -1, since, well... "Crystal Ball" is a valid word)
	local bound = (#deck*2)/3
	table.insert(deck, math.random(bound, #deck), -1)
	table.insert(deck, math.random(bound, #deck), -1)
	table.insert(deck, math.random(bound, #deck), -1)
	return deck
end

function mediumDrawCards(state, idx)
	-- Get the first card. If it's the crystal ball, tell everyone and repeat
	local deck = state["Deck"]
	local playerHand = state["PlayerList"][idx]["Hand"]
	-- Draw up to hand size
	while misc.sizeOfTable(playerHand) < HANDSIZE do
		local card = table.remove(deck, 1)
		if card == -1 then
			-- Card is crystal ball
			state["Balls"] = state["Balls"] + 1
			state["GameChannel"]:send("Crystal ball #" .. state["Balls"] .. " has been drawn!")
		else
			playerHand[misc.findNil(playerHand)] = card
		end
	end
end

function mediumIsPlayerIdx(state, player, idx)
	if state["PlayerList"][idx]["Player"] == player then return true else return false end
end

function mediumGetPlayerFromIdx(state, idx)
	return state["PlayerList"][idx]["Player"]
end

function mediumGetIdxFromPlayer(state, player)
	for idx,playerInfo in pairs(state["PlayerList"]) do
		if mediumGetPlayerFromIdx(state, idx) == player then return idx end
	end
	return 0
end

function mediumPickCard(state, playerIdx, cardIdx, channel)
	-- Make sure the player is going this turn
	local isFirstPlayer = true
	if state["Phase"] == -2 and state["CurrentPlayer"] == playerIdx then
	elseif state["Phase"] == -1 and state["NextPlayer"] == playerIdx then isFirstPlayer = false
	else channel:send("It's not your turn to pick a card!"); return end

	-- Make sure the cardIdx is a number and in range
	cardIdx = tonumber(cardIdx)
	if cardIdx == nil then 
		channel:send("That's not a number! Use !pick [#] to pick a card from your hand.")
		return
	elseif cardIdx < 1 or cardIdx > HANDSIZE then
		print("h")
		channel:send("Pick a number between 1 and " .. HANDSIZE .. "!")
		return
	end

	-- Pick the card
	if isFirstPlayer then
		-- Player 1 picking
		state["Word1"] = state["PlayerList"][playerIdx]["Hand"][cardIdx]
	else
		-- Player 2 is picking
		state["Word2"] = state["PlayerList"][playerIdx]["Hand"][cardIdx]
	end
	state["PlayerList"][playerIdx]["Hand"][cardIdx] = nil
	mediumUpdatePhase(state, false)
end

function mediumDMHand(state, idx)
	local output = "Your hand is: "
	for num,card in pairs(state["PlayerList"][idx]["Hand"]) do
		output = output .. num .. ": " .. card
		if num ~= #state["PlayerList"][idx]["Hand"] then output = output .. ", " end
	end
	mediumDMPlayer(state, idx, output)
end

function mediumDMScore(state, idx)
	local scores = state["PlayerList"][idx]["Score"]
	local leftIdx, rightIdx = 0, 0
	if idx == 1 then leftIdx = #state["PlayerList"] else leftIdx = idx-1 end
	if idx == #state["PlayerList"] then rightIdx = 1 else rightIdx = idx+1 end

	local leftOutput = "Score with " .. state["PlayerList"][leftIdx]["Player"].name .. ":"
	local rightOutput = "Score with " .. state["PlayerList"][rightIdx]["Player"].name .. ":"
	local finalOutput = "Total: "
	local leftSum, rightSum = 0, 0

	for idx,score in pairs(scores["Left"]) do
		leftSum = leftSum + score
		leftOutput = leftOutput .. " " .. score
	end
	leftOutput = leftOutput .. " -> " .. leftSum

	for idx,score in pairs(scores["Right"]) do
		rightSum = rightSum + score
		rightOutput = rightOutput .. " " .. score
	end
	rightOutput = rightOutput .. " -> " .. rightSum

	finalOutput = finalOutput .. leftSum+rightSum
	state["PlayerList"][idx]["Player"]:send(leftOutput .. "\n" .. rightOutput .. "\n" .. finalOutput)
end

function mediumDMPlayer(state, idx, msg)
	state["PlayerList"][idx]["Player"]:send(msg)
end

function mediumDoGuesses(state)
	output = mediumGetPlayerFromIdx(state, state["CurrentPlayer"]).name .. "'s word: " .. state["Guess1"] .. "\n"
	output = output .. mediumGetPlayerFromIdx(state, state["NextPlayer"]).name .. "'s word: " .. state["Guess2"]
	state["GameChannel"]:send(output)
	state["Revealed"] = true
end

function mediumUpdatePhase(state, success)
	if state["Phase"] == -2 then
		-- Next player's turn to pick
		state["Word2"] = nil
		state["Phase"] = -1
	elseif state["Phase"] == -1 then
		-- Begin the melding phase
		state["Guess1"] = nil
		state["Guess2"] = nil
		state["Phase"] = 1
	elseif state["Phase"] == 1 or state["Phase"] == 2 or state["Phase"] == 3 then
		if success or state["Phase"] == 3 then
			-- If success, award score
			if success then
				-- Get the appropriate token
				local score = 0
				if state["Phase"] == 1 then
					score = math.random(5,6)
				elseif state["Phase"] == 2 then
					score = math.random(3,4)
				else
					score = math.random(1,2)
				end
				-- Award the token to both players
				table.insert(state["PlayerList"][state["CurrentPlayer"]]["Score"]["Right"], score)
				table.insert(state["PlayerList"][state["NextPlayer"]]["Score"]["Left"], score)
			end
			-- Clear words
			state["Word1"] = nil
			state["Word2"] = nil
			state["Guess1"] = nil
			state["Guess2"] = nil
			-- Have each player draw up
			mediumDrawCards(state, state["CurrentPlayer"])
			mediumDrawCards(state, state["NextPlayer"])
			mediumDMHand(state, state["CurrentPlayer"])
			mediumDMHand(state, state["NextPlayer"])
			-- Update players
			state["CurrentPlayer"] = state["NextPlayer"]
			state["NextPlayer"] = state["NextPlayer"] + 1
			if state["NextPlayer"] > #state["PlayerList"] then state["NextPlayer"] = 1 end
			-- If we've found three crystal balls already, and are just getting back to the starting player, game is over
			if state["Balls"] == 3 and state["CurrentPlayer"] == state["StartingPlayer"] then
				mediumEndGame(state)
				return
			end
			-- Update state
			state["Phase"] = -2
		else
			-- Continue the round with new words
			state["Word1"] = state["Guess1"]
			state["Word2"] = state["Guess2"]
			state["Guess1"] = nil
			state["Guess2"] = nil
			state["Phase"] = state["Phase"] + 1
		end
	else
		print("ERROR: Game Phase " .. state["Phase"])
		misc.printTable(state)
		mediumSendStatusMessage(state)
		return
	end
	state["Revealed"] = false
	mediumSendStatusMessage(state)
end

function mediumSendStatusMessage(state)
	local output = ""
	if state["Phase"] == -2 then
		-- First player picking card
		output = "It's " .. mediumGetPlayerFromIdx(state, state["CurrentPlayer"]).name .. "'s turn to pick a word!"
		state["GameChannel"]:send(output)
	elseif state["Phase"] == -1 then
		-- Second player picking card
		output = mediumGetPlayerFromIdx(state, state["CurrentPlayer"]).name .. " picked " .. state["Word1"] .. "!\n"
		output = output .. "It's " .. mediumGetPlayerFromIdx(state, state["NextPlayer"]).name .. "'s turn to pick a word!"
		state["GameChannel"]:send(output)
	elseif state["Phase"] == 1 or state["Phase"] == 2 or state["Phase"] == 3 then
		-- Melding phase
		output = "It's the matching phase! " .. mediumGetPlayerFromIdx(state, state["CurrentPlayer"]).name .. " and "
		output = output .. mediumGetPlayerFromIdx(state, state["NextPlayer"]).name .. " are attempting to match words!\n"
		output = output .. "The words are: " .. state["Word1"] .. " and " .. state["Word2"] .. "!"
		state["GameChannel"]:send(output)
	else
		-- Error?
		print("ERROR: Game Phase " .. state["Phase"])
		misc.printTable(state)
	end
end

function mediumEndGame(state)
	state["GameChannel"]:send("The game has ended!")

	-- Acquire individual player scores
	local scores = {}
	for idx,player in ipairs(state["PlayerList"]) do
		local leftScore = misc.sumTable(player["Score"]["Left"])
		local rightScore = misc.sumTable(player["Score"]["Right"])
		local totalScore = leftScore + rightScore
		table.insert(scores, {player["Player"].name, totalScore, leftScore, rightScore})
	end
	-- Sorting an array in Lua is an Orwellian nightmare
	table.sort(scores, function(a,b) return a[2] < b[2] end)
	-- Output the scores in order
	local output = ""
	for idx,tbl in ipairs(scores) do
		output = output .. tbl[1] .. ": " .. tbl[3] .. " + " .. tbl[4] .. " = **" .. tbl[2] .. "**\n" 
	end
	state["GameChannel"]:send(output)

	-- Exit game
	games.deregisterGame(state["GameChannel"])
end

function mediumQuitGame(state)
	state["GameChannel"]:send("Quitting game...")
	games.deregisterGame(state["GameChannel"])
end

function mediumSendScoreMessage(state)
	local output = "Scores:\n"
	for idx=1,#state["PlayerList"],1 do
		-- Get index of next player
		local nextIdx = idx+1
		if nextIdx > #state["PlayerList"] then nextIdx = 1 end
		-- Prepare new line of output
		output = output .. state["PlayerList"][idx]["Player"].name .. " and " 
		output = output .. state["PlayerList"][nextIdx]["Player"].name .. "'s score: "
		-- Get the count of each type of token
		local highTokenCt, medTokenCt, lowTokenCt = 0, 0, 0
		local scores = state["PlayerList"][idx]["Score"]["Right"]
		for idx,token in pairs(scores) do
			if token == 1 or token == 2 then lowTokenCt = lowTokenCt + 1
			elseif token == 3 or token == 4 then medTokenCt = medTokenCt + 1
			else highTokenCt = highTokenCt + 1 end
		end
		-- Amend output
		output = output .. highTokenCt .. "x 1st Attempt, " .. medTokenCt .. "x 2nd Attempt, " .. lowTokenCt .. "x 3rd Attempt\n"
	end
	-- Send output
	state["GameChannel"]:send(output)
end

return medium