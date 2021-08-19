local games = require("Games")
local misc = require("Misc")
local goofspiel = {}

local quitGame, advanceState, status, resolveBids, endGame, bidCmd, handCmd

local TIEBREAKS = {"discard", "split", "pass"}
local CARDS = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"}
local CARD_NAMES = {
	A = "Ace",
	T = "10",
	J = "Jack",
	Q = "Queen",
	K = "King"
}
--TODO: use CARD_NAMES for output messages
--TODO: display bids at end of auction, unless playing in blind mode
--TODO: (optional) tracking of other players' hands

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function goofspiel.startGame(message)
	local playerList = {}
	for playerID,playerObj in pairs(message.mentionedUsers) do
		playerList[playerID] = {Player = playerObj, Hand = misc.shallowCopy(CARDS), Points = 0, Bid = nil}
	end

	local args = message.content:split(" ")
	local tiebreak = "discard"
	args[3] = args[3]:lower()
	if TIEBREAKS[args[3]] ~= nil then tiebreak = args[3] end

	local state = {
		GameChannel = message.channel,
		PlayerList = playerList,
		Deck = misc.shuffleTable(misc.shallowCopy(CARDS)),
		CurrentCard = nil,
		Tiebreak = tiebreak
	}

	games.registerGame(message.channel, "Goofspiel", state, message.mentionedUsers)

	advanceState(state)
end

function goofspiel.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end
end

function goofspiel.dmHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!bid" then bidCmd(state, args[2], message.author.id)
	elseif args[1] == "!hand" then handCmd(state, message.author.id)
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function handCmd(state, pid)
	local hand = state.PlayerList[pid].Hand
	local msg = "Your hand: {"

	for idx,card in pairs(CARDS) do
		if hand[idx] ~= nil then msg = msg .. card .. ", " end
	end

	msg = msg:sub(1,-3) .. "}"

	state.PlayerList[pid].Player:send(msg)
end

function bidCmd(state, bid, pid)
	-- Check if player actually has that card to bid
	local idx = misc.getKey(bid:upper(), CARDS)
	if state.PlayerList[pid].Hand[idx] ~= nil then
		state.PlayerList[pid].Bid = bid:upper()
		state.PlayerList[pid].Player:send("Bid " .. bid:upper() .. ".")
		advanceState(state)
	else
		state.PlayerList[pid].Player:send("Invalid bid! Are you sure you have that card in hand?")
	end
end

function endGame(state)
	local msg = "**The game is over!**"
	for playerID, playerInfo in pairs(state.PlayerList) do
		msg = msg .. "\n" .. playerInfo.Player.name .. ": " .. playerInfo.Points
	end

	for playerID, playerInfo in pairs(state.PlayerList) do
		playerInfo.Player:send(msg)
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
	end

	-- Figure out who the winning player(s) are, as well as the tie status
	local highBid = 0
	local isTie = false
	local winners = {}

	for playerID, playerInfo in pairs(state.PlayerList) do

		local bid = misc.getKey(playerInfo.Bid, CARDS)
		-- Remove bid from player's hand and reset their bid
		playerInfo.Bid = nil
		playerInfo.Hand[bid] = nil

		if bid > highBid then
			highBid = bid
			isTie = false
			winners = {playerID}
		elseif bid == highBid then
			isTie = true
			table.insert(winners, playerID)
		end
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
	for playerID,playerInfo in pairs(state.PlayerList) do
		print(playerInfo.Player.name)
		print(playerInfo.Bid)
		misc.printList(playerInfo.Hand)
	end

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
		--TODO: print player bids
		resolveBids(state)
	end
end

function status(state)
	local msg = "The card up for auction is: **" .. state.CurrentCard .. "**"
	for playerID, playerInfo in pairs(state.PlayerList) do
		msg = msg .. "\n" .. playerInfo.Player.name .. ": " .. playerInfo.Points
	end

	for playerID, playerInfo in pairs(state.PlayerList) do
		handCmd(state, playerID)
		playerInfo.Player:send(msg)
	end
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameChannel)	
end

return goofspiel