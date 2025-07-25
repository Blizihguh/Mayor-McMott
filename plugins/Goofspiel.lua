local games = require("Games")
local misc = require("Misc")
local goofspiel = {}
goofspiel.desc = "The Game of Pure Strategy, also known as Psychological Jiu Jitsu."
goofspiel.rules = "https://en.wikipedia.org/wiki/Goofspiel"

local quitGame, advanceState, status, resolveBids, endGame, bidCmd, setupEmojis

local TIEBREAKS = {"discard", "split", "pass"}
local CARDS = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"}
local CARD_REACTS = {"🇦","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣","🔟","🇯","🇶","🇰"}
local CARD_NAMES = {
	A = "Ace",
	T = "10",
	J = "Jack",
	Q = "Queen",
	K = "King"
}
--TODO: three difficulties: other players' hands are public, memory mode, and blind bidding
--TODO: handle user removal of reactions/user pressing multiple reactions at once

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function goofspiel.startGame(message, players)
	local playerList = {}
	for idx,playerObj in pairs(players) do
		playerList[playerObj.id] = {Player = playerObj, Hand = misc.shallowCopy(CARDS), Points = 0, Bid = nil, LastBid = nil, Status = nil, HighBid = nil}
	end

	local args = message.content:split(" ")
	local tiebreak = "discard"
	args[3] = args[3]:lower()
	if misc.valueInList(args[3], TIEBREAKS) then tiebreak = args[3] end

	local state = {
		GameChannel = message.channel,
		PlayerList = playerList,
		Deck = misc.shuffleTable(misc.shallowCopy(CARDS)),
		CurrentCard = nil,
		Tiebreak = tiebreak,
	}


	state.GameID = games.registerGame(message.channel, "Goofspiel", state, players)

	for id,info in pairs(state.PlayerList) do
		info.Status = info.Player:send("**Dealing out cards...**")
	end

	setupEmojis(state)
	advanceState(state)
end

function goofspiel.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end
end

function goofspiel.dmHandler(message, state)
	-- local args = message.content:split(" ")
	-- if args[1] == "!bid" then bidCmd(state, args[2], message.author.id)
	-- end
end

function goofspiel.reactHandler(reaction, user, state, isAdding)
	-- We only care about add events
	if not isAdding then return end
	-- Check if the message is the user's status message
	for id,info in pairs(state.PlayerList) do
		-- Check if the reaction was made by the user (not the bot) and is on the status message
		if id == user.id and info.Status.id == reaction.message.id then
			-- Check if the emoji is in CARD_REACTS
			if misc.valueInList(reaction.emojiName, CARD_REACTS) then
				-- If it is, check if the user still has that card
				local bid = misc.getKey(reaction.emojiName, CARD_REACTS)
				if info.Hand[bid] ~= nil then
					-- Update bid to match this card
					info.Bid = info.Hand[bid]
					advanceState(state)
				end
			end
		end
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function setupEmojis(state)
	-- Add reactions to everybody's info message
	-- Iterating by emote first, instead of player first, is significantly faster due to Discord's rate-limiting
	for idx,emote in pairs(CARD_REACTS) do
		for id,info in pairs(state.PlayerList) do
			info.Status:addReaction(emote)
		end
	end
end

function endGame(state)
	local msg = "**The game is over!**"
	for playerID, playerInfo in pairs(state.PlayerList) do
		msg = msg .. "\n" .. playerInfo.Player.name .. ": " .. playerInfo.Points
		local last = playerInfo.LastBid
		if CARD_NAMES[last] ~= nil then last = CARD_NAMES[last] end
		if playerInfo.LastBid ~= nil and playerInfo.HighBid then msg = msg .. " (**__Last Bid: " .. last .. "__**)"
		elseif playerInfo.LastBid ~= nil then msg = msg .. " (Last Bid: " .. last ..")" end
	end
	msg = msg .. "\n----------"

	for playerID, playerInfo in pairs(state.PlayerList) do
		playerInfo.Status:setContent(msg)
	end

	quitGame(state)
end

function resolveBids(state)
	-- Get value of current auction
	local cardValue = misc.getKey(state.CurrentCard, CARDS)
	if cardValue == nil then -- If multiple cards are up for auction, get their values individually
		local sum = 0
		for i = 1, #state.CurrentCard do
			sum = sum + misc.getKey(state.CurrentCard:sub(i,i), CARDS)
		end
		cardValue = sum
	end

	-- Figure out who the winning player(s) are, as well as the tie status
	local highBid = 0
	local isTie = false
	local winners = {}

	for playerID, playerInfo in pairs(state.PlayerList) do

		local bid = misc.getKey(playerInfo.Bid, CARDS)
		-- Remove bid from player's hand and reset their bid
		playerInfo.LastBid = playerInfo.Bid
		playerInfo.Bid = nil
		playerInfo.Hand[bid] = nil
		-- Remove emoji
		-- Unfortunately, other users' emojis cannot be auto-removed in DM
		playerInfo.Status:removeReaction(CARD_REACTS[bid])

		if bid > highBid then
			highBid = bid
			isTie = false
			winners = {playerID}
		elseif bid == highBid then
			isTie = true
			table.insert(winners, playerID)
		end
	end

	for id,info in pairs(state.PlayerList) do
		if misc.valueInList(id, winners) then info.HighBid = true else info.HighBid = false end
	end

	if not isTie then
		-- Award points to winning player
		state.PlayerList[winners[1]].Points = state.PlayerList[winners[1]].Points + cardValue

		-- Set CurrentCard to nil and pass to advanceState
		state.CurrentCard = nil
		advanceState(state)
		return
	end

	-- In the case of a tie: determine what happens by the tiebreak method
	-- DISCARD: set CurrentCard to nil and pass to advanceState
	-- SPLIT: split the card points, then proceed as with DISCARD
	-- PASS: instead of passing to advanceState, flip a card ourselves and append it to CurrentCard
	if state.Tiebreak == "discard" then
		state.CurrentCard = nil
		advanceState(state)
	elseif state.Tiebreak == "split" then
		for idx, playerID in pairs(winners) do
			state.PlayerList[playerID].Points = state.PlayerList[playerID].Points + cardValue/#winners
		end
		state.CurrentCard = nil
		advanceState(state)
	elseif state.Tiebreak == "pass" then
		-- If the deck is empty, just discard
		if #state.Deck == 0 then
			state.CurrentCard = nil
			advanceState(state)
		else
			state.CurrentCard = state.CurrentCard .. state.Deck[#state.Deck]
			state.Deck[#state.Deck] = nil
			status(state)
		end
	end
end

function advanceState(state)
	-- If there's no card being auctioned and the deck is empty, end the game
	if state.CurrentCard == nil and #state.Deck == 0 then
		endGame(state)
		return
	end
	-- If there's no card being auctioned atm, flip a new card
	if state.CurrentCard == nil then
		-- Flip new card
		state.CurrentCard = state.Deck[#state.Deck]
		state.Deck[#state.Deck] = nil

		-- Send status message and return
		status(state)
		return
	end
	-- Otherwise, if everybody has bid, resolve bidding and flip a new card
	local waiting = false
	for playerID, playerInfo in pairs(state.PlayerList) do
		if playerInfo.Bid == nil then
			waiting = true
			break
		end
	end
	if not waiting then
		resolveBids(state)
	end
end

function status(state)
	-- Filter output for abbreviations
	local current = state.CurrentCard
	if CARD_NAMES[current] ~= nil then
		current = CARD_NAMES[current] 
	elseif #current > 1 then
		-- Multiple cards combined, display them separately
		local c = ""
		for i = 1, #current do
			if CARD_NAMES[current:sub(i,i)] == nil then
				c = c .. " - " .. current:sub(i,i)
			else
				c = c .. " - " .. CARD_NAMES[current:sub(i,i)]
			end
		end
		current = c:sub(4,-1)
	end

	local msg = "The card up for auction is: **" .. current .. "**"
	for playerID, playerInfo in pairs(state.PlayerList) do
		msg = msg .. "\n" .. playerInfo.Player.name .. ": " .. playerInfo.Points
		local last = playerInfo.LastBid
		if CARD_NAMES[last] ~= nil then last = CARD_NAMES[last] end
		if playerInfo.LastBid ~= nil and playerInfo.HighBid then msg = msg .. " (**__Last Bid: " .. last .. "__**)"
		elseif playerInfo.LastBid ~= nil then msg = msg .. " (Last Bid: " .. last ..")" end
	end

	for playerID, playerInfo in pairs(state.PlayerList) do
		-- Send message
		if playerInfo.Status == nil then
			playerInfo.Status = playerInfo.Player:send(msg)
		else
			playerInfo.Status:setContent(msg)
		end
	end
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameID)	
end

return goofspiel