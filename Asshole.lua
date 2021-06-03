local games = require("Games")
local misc = require("Misc")
local asshole = {}

local status

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function asshole.startGame(message)
	if #message.mentionedUsers ~= 4 then
		message.channel:send("The Asshole Game takes exactly four players, homie!")
		return
	end

	local playerlist = {}
	local cards = misc.shuffleTable({"King", "King", "Jack", "Jack", "Asshole", "Asshole", "Jester"})
	local idx = 1
	for id,playerObject in pairs(message.mentionedUsers) do
		playerlist[idx] = {Player = playerObject, Card = cards[idx], Pointed = false}
		idx = idx + 1
	end

	local state = {
		GameChannel = message.channel,
		PlayerList = playerlist
	}

	for idx,player in pairs(state.PlayerList) do
		status(state, player)
	end

	games.registerGame(message.channel, "Asshole", state, message.mentionedUsers)
end

function asshole.commandHandler(message, state)
end

function asshole.dmHandler(message, state)
end

function asshole.reactHandler(reaction, user, state)
	print("Hello!")
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function status(state, target)
	local border_string = "+===============================+\n"
	local table_string = "%s %s  `[ %-7s ] %-21s`\n"
	local emojis = {King = ":large_blue_diamond:", Jack = ":red_circle:", Asshole = ":green_heart:", Jester = ":warning:", Self = ":grey_question:", Nobody = ":white_square_button:"}
	local numbers = {":zero:", ":one:", ":two:", ":three:", ":four:"}

	local output = border_string .. string.format(table_string, emojis["Nobody"], numbers[1], "-------", "Nobody")
	for idx,playerObject in pairs(state.PlayerList) do
		if playerObject.Player.id == target.Player.id then
			output = output .. string.format(table_string, emojis["Self"], numbers[idx+1], "???????", playerObject.Player.name)
		else
			output = output .. string.format(table_string, emojis[playerObject.Card], numbers[idx+1], playerObject.Card, playerObject.Player.name)
		end
	end
	output = output .. border_string

	local message = target.Player:send(output)
	message:addReaction("0️⃣")
	message:addReaction("1️⃣")
	message:addReaction("2️⃣")
	message:addReaction("3️⃣")
	message:addReaction("4️⃣")
end

return asshole