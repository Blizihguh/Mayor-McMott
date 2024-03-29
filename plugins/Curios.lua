local games = require("Games")
local misc = require("Misc")
local curios = {}
curios.desc = "TODO" --"A bluffing game for 2-5 players. Players are dealt a hand of cards, providing partial information about the value of differently colored gems; each turn, everyone attempts to make the most money placing workers to acquire gems."
curios.rules = "TODO" --"https://www.alderac.com/wp-content/uploads/2019/04/Curio_Rulebook_Final-Feb2019.pdf"

local GEM_COUNTS = {0, 8, 10, 12, 14}
local HAND_SIZE = {0, 4, 4, 3, 2}

local curiosCreateGameInstance, curiosDrawSiteValue, curiosDrawCardsToHand, curiosDMHand

--[[--------------------------------------------------------
	Main Functions                                         |
--]]--------------------------------------------------------

function curios.startGame(message)
	local playerList = message.mentionedUsers

	-- Check for errors
	if #playerList < 2 then
		message.channel:send("You need at least two players to play Curios!")
		return
	elseif #playerList > 5 then
		message.channel:send("Too many players!")
		return
	end

	-- Create a new game and register it
	message.channel:send("Starting game...")
	local state = curiosCreateGameInstance(message.channel, playerList)
	state.GameID = games.registerGame(message.channel, "Curios", state, playerList)

	-- DM players their hands
	for idx,playerInfo in pairs(state["PlayerList"]) do
		curiosDMHand(state, idx)
	end
end

function curios.commandHandler(message, state)
end

function curios.curiosDMHandler(message, state)
end

--[[--------------------------------------------------------
	Game Functions                                         |
--]]--------------------------------------------------------

function curiosCreateGameInstance(channel, playerList)
	local state = {
		GameChannel = channel,
		PlayerList = {},
		PlayerCount = 0,
		Sites = {},
		Deck = {},
		FirstPlayer = nil,
		CurrentPlayer = nil
	}

	-- Create and shuffle deck
	state["Deck"] = {
		{1, "Red"}, {3, "Red"}, {5, "Red"}, {7, "Red"},
		{1, "Blue"}, {3, "Blue"}, {5, "Blue"}, {7, "Blue"},
		{1, "Green"}, {3, "Green"}, {5, "Green"}, {7, "Green"},
		{1, "Yellow"}, {3, "Yellow"}, {5, "Yellow"}, {7, "Yellow"}
	}
	misc.shuffleTable(state["Deck"])

	-- Create player instances
	local idx = 1
	for id,player in pairs(playerList) do
		state["PlayerList"][idx] = {Player = player, Hand = {}, Gems = {Red = 0, Blue = 0, Green = 0, Yellow = 0}, Workers = 5, MaxWorkers = 5}
		idx = idx + 1
	end
	state["PlayerCount"] = idx-1

	-- Randomly determine starting player
	state["CurrentPlayer"] = math.random(1,#state["PlayerList"])
	state["FirstPlayer"] = state["CurrentPlayer"]

	-- Create sites
	state["Sites"] = {
		{Color = "Red", Value = curiosDrawSiteValue(state, "Red"), Gems = GEM_COUNTS[state["PlayerCount"]]},
		{Color = "Blue", Value = curiosDrawSiteValue(state, "Blue"), Gems = GEM_COUNTS[state["PlayerCount"]]},
		{Color = "Green", Value = curiosDrawSiteValue(state, "Green"), Gems = GEM_COUNTS[state["PlayerCount"]]},
		{Color = "Yellow", Value = curiosDrawSiteValue(state, "Yellow"), Gems = GEM_COUNTS[state["PlayerCount"]]}
	}

	-- Deal cards to each player
	for idx,player in pairs(state["PlayerList"]) do curiosDrawCardsToHand(state, idx) end

	-- Return our finished state
	return state
end

function curiosDrawSiteValue(state, color)
	for idx,card in ipairs(state["Deck"]) do
		if card[2] == color then
			table.remove(state["Deck"], idx)
			return card[1]
		end
	end
end

function curiosDrawCardsToHand(state, playerIdx) 
	local playerHand = state["PlayerList"][playerIdx]["Hand"]
	while #playerHand < HAND_SIZE[state["PlayerCount"]] do
		local card = table.remove(state["Deck"], 1)
		playerHand[#playerHand+1] = card
	end
end

function curiosDMHand(state, playerIdx)
	-- TODO
end

return curios