local games = require("Games")
local misc = require("Misc")

local favethings = {}
favethings.desc = "A trick-taking game where the suits are arbitrary categories and the numbers are your opinions."
favethings.rules = "https://github.com/Blizihguh/Mayor-McMott/wiki/Eye-My-Favorite-Things"
favethings.startInDMs = "vcOnly"

local ANIMALS = {":frog:", ":fox:", ":rat:", ":dog:", ":raccoon:", ":horse:", ":pig:", ":hamster:", ":bear:", ":panda_face:", ":koala:", ":chicken:", ":turtle:", ":dragon_face:", ":whale:", ":tropical_fish:", ":octopus:", ":shark:", ":crab:", ":squid:", ":monkey_face:", ":orangutan:", ":cat:", ":tiger:", ":lion_face:", ":unicorn:", ":cow:", ":boar:", ":mouse:", ":rabbit:", ":polar_bear:", ":sloth:"}
local CARD_REACTS = {"🇦", "🇧", "🇨", "🇩", "🇪", "🇫"}


local playCard, setupEmojis, advanceState, checkForEnd, endRound, sendStatusMessages, giveCards, giveCategory, getPlayerIdxFromID, quitGame, askForCategories

-- Uncomment this if you want to import server-specific data
local PLAYER_LIST = {}
if misc.fileExists("plugins/server-specific/MyFavoriteThings-SP.lua") then
 	PLAYER_LIST = require("plugins/server-specific/MyFavoriteThings-SP")
end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function favethings.startGame(message, playerList)
	local args = message.content:split(" ")

	local players = misc.indexifyTable(playerList)

	for idx,playerObject in pairs(players) do
		players[idx] = {
		Player = playerObject, 
		Emoji = nil,                  -- The player's corresponding emoji
		Score = 0,                    -- How many hands the player has won
		Cards = nil,                  -- The cards that were given to the player. Looks like {Card = <str>, Value = <int>, Played = <bool>}
		YourCategory = nil,           -- The category you asked for (which will be on your cards)
		TheirCategory = nil,          -- The category you've been given (which will be on their cards)
		WhoHasYourCards = nil,        -- Who gave you a category? (whose cards did you write on?)
		WhoseCardsDoYouHaveIdx = nil, -- Who are you giving a category to? (whose cards do you have?)
		WhoseCardsDoYouHaveName = "", -- Name of above
		StatusMsgCategories = nil,    -- The player's status message, split into three messages: one for the categories,
		StatusMsgRound = nil,         --     one for the current round info,
		StatusMsgHand = nil,          --     and one to display the player's hand.
		CardPlayedLastHand = nil,     -- The card the player played last hand
		CardPlayedThisHand = nil      -- The card the player has chosen for this hand
		}
	end

	-- Assign everyone an emoji
	local assignedEmojis = {}
	for idx,player in pairs(players) do
		if PLAYER_LIST[player.Player.id] ~= nil then -- If we have an entry for this player, use their pre-assigned animal
			player.Emoji = PLAYER_LIST[player.Player.id]
			table.insert(assignedEmojis, player.Emoji)
		else -- Otherwise, pick one based on their id
			local tempEmoji = misc.getRandomItem(ANIMALS)
			while misc.valueInList(tempEmoji, assignedEmojis) do tempEmoji = misc.GetRandomItem(ANIMALS) end
			table.insert(assignedEmojis, tempEmoji)
			player.Emoji = tempEmoji
		end 
	end

	local state = {
		GameChannel = message.channel,
		PlayerList = players,
		Round = 1,
		Phase = 1,
		Turn = nil,
		LastRoundWinner = nil
	}
	
	state.GameID = games.registerGame(message.channel, "MyFavoriteThings", state, playerList)
	askForCategories(state)
end

function favethings.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end
end

function favethings.dmHandler(message, state)
	local args = message.content:split(" ")

	local playerIdx = getPlayerIdxFromID(state, message.author.id)

	if args[1] == "!quit" then quitGame(state)
	elseif args[1] == "!pick" and state.Phase == 1 then giveCategory(state, message, playerIdx)
	elseif args[1] == "!pick" and state.Phase == 2 then giveCards(state, message, playerIdx)
	end

	-- Check if the phase needs to be advanced
	advanceState(state)
end

function favethings.reactHandler(reaction, user, state)
	-- Check if the reaction is from the player whose turn it is
	local idx = getPlayerIdxFromID(state, user.id)
	if idx ~= state.Turn then return end

	-- Check if the reaction is on the player's status message
	local playerInfo = state.PlayerList[idx]
	if playerInfo.StatusMsgHand.id ~= reaction.message.id then return end

	-- Check if the emoji is in CARD_REACTS
	if not misc.valueInList(reaction.emojiName, CARD_REACTS) then return end

	-- Check if the player still has that card
	local card = misc.getKey(reaction.emojiName, CARD_REACTS)
	if playerInfo.Cards[card].Played then return end

	-- All good to play the card
	playCard(state, idx, card)
	advanceState(state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function playCard(state, playerIdx, cardIdx)
	state.PlayerList[playerIdx].Cards[cardIdx].Played = true
	state.PlayerList[playerIdx].CardPlayedThisHand = cardIdx
end

function setupEmojis(state)
	-- Add reactions to everybody's info message
	-- Iterating by emote first, instead of player first, is significantly faster due to Discord's rate-limiting
	for idx,emote in pairs(CARD_REACTS) do
		for id,info in pairs(state.PlayerList) do
			info.StatusMsgHand:addReaction(emote)
		end
	end
end

function advanceState(state)
	if state.Phase == 1 then
		-- Check if everyone has input a category, and if they have, advance to the card-writing phase
		local goodToGo = true
		for idx,player in pairs(state.PlayerList) do
			if player.YourCategory == nil then goodToGo = false; break end
		end
		if goodToGo then
			for idx,player in pairs(state.PlayerList) do
				local p = player.WhoseCardsDoYouHaveIdx
				local givingTo = state.PlayerList[p]

				givingTo.Player:send(player.Player.name .. " wants you to rank: " .. player.YourCategory .. "!")
			end
			state.Phase = 2
		end
	elseif state.Phase == 2 then
		-- Check if everyone has input cards, and if they have, advance to the trick-taking phase
		local goodToGo = true
		for idx,player in pairs(state.PlayerList) do
			if player.Cards == nil then goodToGo = false; break end
		end
		if goodToGo then
			-- If this is the first round, pick a random person to start
			if state.LastRoundWinner == nil then
				state.LastRoundWinner = misc.getRandomIndex(state.PlayerList)
			end
			state.Turn = state.LastRoundWinner --TODO: Is this supposed to carry between sets? I'm going to say yes but I'm not sure it's established in the rules
			state.Phase = 3
			sendStatusMessages(state)
		end
	elseif state.Phase == 3 then
		-- If the player whose turn it is has already played their card, advance to the next player's turn
		local card = state.PlayerList[state.Turn].CardPlayedThisHand
		if card == nil then return end
		state.Turn = state.Turn + 1
		if state.PlayerList[state.Turn] == nil then state.Turn = 1 end

		-- If the next player has ALSO played their card, that's everybody! End the round and move onto the next one
		if state.PlayerList[state.Turn].CardPlayedThisHand ~= nil then 
			-- Set up next round
			endRound(state)
			-- Check for end of game
			checkForEnd(state)
		end

		sendStatusMessages(state)
	end
end

function checkForEnd(state)
	--TODO: Go for more than one set of cards? The game only says to go for two rounds, which seems kind of silly
	-- If it's round seven, the game is over
	if state.Round >= 7 then
		sendStatusMessages(state)
		-- Send end-of-game message
		--TODO: An actual end-of-game message
		local msg = ""
		for idx,player in pairs(state.PlayerList) do
			msg = msg .. player.Player.name .. ": " .. player.Score .. " points\n"
		end
		for idx,player in pairs(state.PlayerList) do
			player.Player:send(msg)
		end
		quitGame(state)
	end
end

function endRound(state)
	-- Score previous round
	local thisHandCards = {}
	local p = state.LastRoundWinner
	local winner = nil
	while true do
		local player = state.PlayerList[p]
		local val = player.Cards[player.CardPlayedThisHand].Value

		-- If somebody else has already played a card with this value, they take precedence for ties, so this player cannot possibly win. We skip them.
		-- This is why we're iterating in play order, rather than just going over the player list in any arbitrary order.
		if thisHandCards[val] == nil then
			thisHandCards[val] = p
		end

		p = p + 1
		if state.PlayerList[p] == nil then p = 1 end
		if p == state.LastRoundWinner then break end
	end

	-- If somebody played a zero and somebody played a one, the zero player wins. Otherwise, the player with the lowest nonzero number wins.
	if (thisHandCards[0] ~= nil) and (thisHandCards[1] ~= nil) then
		winner = thisHandCards[0]
	else
		for i=1,5 do
			if thisHandCards[i] ~= nil then
				winner = thisHandCards[i]
				break
			end
		end
	end
	-- If we get here and there's no winner, it means everyone played a zero, so the first person to play zero wins
	if winner == nil then winner = thisHandCards[0] end

	-- Move cards played this hand to last hand
	for idx,player in pairs(state.PlayerList) do
		player.CardPlayedLastHand = player.CardPlayedThisHand
		player.CardPlayedThisHand = nil
	end

	-- Update player score, round, turn, and last round winner
	state.LastRoundWinner = winner
	state.Turn = state.LastRoundWinner
	state.PlayerList[winner].Score = state.PlayerList[winner].Score + 1
	state.Round = state.Round + 1
end

function sendStatusMessages(state)
	-- CARD CATEGORIES
	-- This can be handled once and sent to everyone, since it's all public info
	-- Build the message
	local msg = ".\n`+-- Categories ------------------------+`"
	for idx,player in pairs(state.PlayerList) do
		msg = msg .. "\n"
		msg = msg .. player.Emoji .. " " .. player.Player.name .. " | Playing **" .. player.WhoseCardsDoYouHaveName .. "**'s *__" .. player.YourCategory .. "__*"
	end

	-- Send the message to everyone
	for idx,player in pairs(state.PlayerList) do
		if player.StatusMsgCategories == nil then
			local err
			player.StatusMsgCategories,err = player.Player:send(msg)
			-- Once in a blue moon, sending one of these status messages will fail, even though the message sent
			-- http-codec.lua:256: chunk-size field too large
			print("################################################### Diagnostic A ############################")
			print(player.StatusMsgCategories)
			print(err)
			print("#############################################################################################")
		else
			player.StatusMsgCategories:setContent(msg)
		end
	end

	-- ROUND INFO
	-- This can also be handled once and sent to everyone, since it's all public info
	-- Build the previous hand portion
	local msg2 = ".\n`+-- Previous Hand ---------------------+`\n"
	-- Get all the cards that were played last round, and the info about them that we'll need to display
	local lastHandCards = {}
	for playerIdx,player in pairs(state.PlayerList) do
		if player.CardPlayedLastHand == nil then break end -- Ignore this section on round one
		table.insert(lastHandCards, {Idx = playerIdx, Emoji = player.Emoji, Name = player.Player.name, Card = player.Cards[player.CardPlayedLastHand].Card, Value = player.Cards[player.CardPlayedLastHand].Value})
	end
	-- Add last round's info to display
	for _,info in pairs(lastHandCards) do
		--TODO: Nicer formatting
		--TODO: Put this in the order the cards were played
		if info.Idx == state.LastRoundWinner then msg2 = msg2 .. "**" end
		msg2 = msg2 .. info.Emoji .. " " .. info.Card .. " (" .. info.Value .. ")\n"
		if info.Idx == state.LastRoundWinner then msg2 = msg2 .. "**" end
	end

	-- Build the current hand portion
	msg2 = msg2 .. "`+-- Current Hand ----------------------+`\n"
	-- Get all the cards that have been played this round, and the info about them that we'll need to display
	local thisHandCards = {}
	local p = state.LastRoundWinner
	while true do
		local player = state.PlayerList[p]

		if player.CardPlayedThisHand == nil then -- Player hasn't chosen a card yet
			table.insert(thisHandCards, {Emoji = player.Emoji, Name = player.Player.name, Card = ""})
		else
			table.insert(thisHandCards, {Emoji = player.Emoji, Name = player.Player.name, Card = player.Cards[player.CardPlayedThisHand].Card})
		end

		p = p + 1
		if state.PlayerList[p] == nil then p = 1 end
		if p == state.LastRoundWinner then break end
	end
	-- Add this round's info to display
	for _,info in pairs(thisHandCards) do
		msg2 = msg2 .. info.Emoji .. " " .. info.Card .. "\n"
	end


	-- Send the message to everyone
	for idx,player in pairs(state.PlayerList) do
		if player.StatusMsgRound == nil then
			local err
			player.StatusMsgRound,err = player.Player:send(msg2)
			print("################################################### Diagnostic B ############################")
			print(player.StatusMsgRound)
			print(err)
			print("#############################################################################################")
		else
			player.StatusMsgRound:setContent(msg2)
		end
	end


	-- PLAYER HANDS
	local needsEmojis = false
	for idx,player in pairs(state.PlayerList) do
		local cards = player.Cards
		local fstr = ".\n`+-- Your Cards ------------------------+`\n:regional_indicator_a: %s\n:regional_indicator_b: %s\n:regional_indicator_c: %s\n:regional_indicator_d: %s\n:regional_indicator_e: %s\n:regional_indicator_f: %s"
		local msg3 = string.format(fstr, cards[1].Card, cards[2].Card, cards[3].Card, cards[4].Card, cards[5].Card, cards[6].Card)
		if player.StatusMsgHand == nil then
			local err
			player.StatusMsgHand,err = player.Player:send(msg3)
			needsEmojis = true
			print("################################################### Diagnostic C ############################")
			print(player.StatusMsgHand)
			print(err)
			print("#############################################################################################")
		else
			player.StatusMsgHand:setContent(msg3)
		end
	end
	if needsEmojis then
		setupEmojis(state)
	end
end

function giveCards(state, message, playerIdx)
	print(message.content)
	local cards = message.content:split(",")
	misc.printTable(cards)
	if #cards ~= 6 then
		message.author:send("Usage: !pick [best card], [second best], [third best], [fourth], [fifth], [trump card]")
		return
	end

	-- Update info
	--TODO: Strip leading spaces from each card, if present
	local player = state.PlayerList[playerIdx].WhoHasYourCards
	cards[1] = cards[1]:sub(6)
	state.PlayerList[player].Cards = {
		{Card = cards[6], Value = 0, Played = false}, 
		{Card = cards[1], Value = 1, Played = false}, 
		{Card = cards[2], Value = 2, Played = false},
		{Card = cards[3], Value = 3, Played = false},
		{Card = cards[4], Value = 4, Played = false},
		{Card = cards[5], Value = 5, Played = false}
	}

	misc.shuffleTable(state.PlayerList[player].Cards)
end

function giveCategory(state, message, playerIdx)
	-- Get category name
	local category = ""
	for idx,arg in pairs(message.content:split(" ")) do if idx > 1 then category = category .. arg .. " " end end
	category = category:sub(1, -2)
	local playerObj = state.PlayerList[playerIdx]

	-- Update info
	playerObj.YourCategory = category
	message.author:send("Category chosen: " .. category)
end

function getPlayerIdxFromID(state, id)
	for idx,playerObject in pairs(state.PlayerList) do
		if playerObject.Player.id == id then return idx end
	end
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	for idx,playerInfo in pairs(state.PlayerList) do
		playerInfo.Player:send("Quitting game...")
	end
	games.deregisterGame(state.GameID)	
end

function askForCategories(state)
	for idx,playerObject in pairs(state.PlayerList) do

		-- Get next penpal
		local new_penpal = idx + state.Round
		if new_penpal > #state.PlayerList then new_penpal = 1 end
		if new_penpal == idx then new_penpal = new_penpal + 1 end

		state.PlayerList[new_penpal].WhoHasYourCards = idx
		playerObject.WhoseCardsDoYouHaveIdx = new_penpal
		playerObject.WhoseCardsDoYouHaveName = state.PlayerList[new_penpal].Player.name

		playerObject.Player:send("Pick a category for " .. playerObject.WhoseCardsDoYouHaveName .. " to rank!")
	end
end

return favethings