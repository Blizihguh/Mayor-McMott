local games = require("Games")
local misc = require("Misc")
local asshole = {}
asshole.desc = "The ONLY card game to use the advertisement cards that you get with every deck!"
asshole.rules = "https://github.com/Blizihguh/Mayor-McMott/wiki/Asshole-Game"

local status, point, quitGame, checkForEnd

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function asshole.startGame(message, players)
	if #players ~= 4 then
		message.channel:send("The Asshole Game takes exactly four players, homie!")
		return
	end

	local playerlist = {}
	local cards = misc.shuffleTable({"King", "King", "Jack", "Jack", "Asshole", "Asshole", "Jester"})
	local idx = 1
	for id,playerObject in pairs(players) do
		playerlist[idx] = {Player = playerObject, Card = cards[idx], Pointed = false, Won = false, Status = nil}
		idx = idx + 1
	end

	local state = {
		GameChannel = message.channel,
		PlayerList = playerlist
	}

	-- Send everybody their info
	for idx,player in pairs(state.PlayerList) do
		status(state, player)
	end
	-- Add reactions to everybody's info message
	local emojis = {"0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣"}
	for idx,emote in pairs(emojis) do
		for id,player in pairs(state.PlayerList) do
			player.Status:addReaction(emote)
		end
	end

	games.registerGame(message.channel, "Asshole", state, players)
end

function asshole.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end
end

function asshole.reactHandler(reaction, user, state)
	-- Check if the message is the user's status message
	for idx,playerObject in pairs(state.PlayerList) do
		-- Check if the reaction was made by the user (not the bot) and is on the status message and the user hasn't pointed yet
		if playerObject.Pointed == false and playerObject.Player.id == user.id and playerObject.Status.id == reaction.message.id then
			-- The user has selected a number!
			point(state, user, reaction.emojiName)
		end
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameChannel)
end

function point(state, user, emoji)
	-- Get target number in a reasonable format
	local emojiTable = {["0️⃣"] = 0, ["1️⃣"] = 1, ["2️⃣"] = 2, ["3️⃣"] = 3, ["4️⃣"] = 4}
	local target_number = emojiTable[emoji]

	-- Get player info
	local my_number = 0
	local player = nil
	for idx,playerObject in pairs(state.PlayerList) do
		if playerObject.Player.id == user.id then
			my_number = idx
			player = playerObject
			break
		end
	end

	-- Set our win status (and return if we aren't actually pointing!)
	if target_number == nil then return
	elseif target_number == 0 then
		-- Win if we're the only King or the only Jack
		if state.PlayerList[my_number].Card == "King" or state.PlayerList[my_number].Card == "Jack" then
			local won = true
			for idx,playerObject in pairs(state.PlayerList) do
				if idx ~= my_number and playerObject.Card == state.PlayerList[my_number].Card then
					won = false
					break
				end
			end
			state.PlayerList[my_number].Won = won
		end
	else
		-- Win if the target player shares our card, as long as it's not a non-jester self-pointing
		if state.PlayerList[my_number].Card == state.PlayerList[target_number].Card then
			if state.PlayerList[my_number].Card == "Jester" or my_number ~= target_number then
				state.PlayerList[my_number].Won = true
			end
		end
		-- If target player is an asshole and not us and we lose by pointing at them, they win
		if my_number ~= target_number and state.PlayerList[target_number].Card == "Asshole" and state.PlayerList[my_number].Won == false then
			state.PlayerList[target_number].Won = true
		end
	end

	-- Set our point status
	state.PlayerList[my_number].Pointed = true

	-- Broadcast the point
	local roleEmojis = {King = ":large_blue_diamond:", Jack = ":red_circle:", Asshole = ":green_heart:", Jester = ":warning:", Self = ":grey_question:", Nobody = ":white_square_button:"}
	local numbers = {[0] = ":zero:", [1] = ":one:", [2] = ":two:", [3] = ":three:", [4] = ":four:"}
	local target_card = ":white_square_button:"
	local target_name = "Nobody"
	if target_number ~= 0 then 
		target_card = roleEmojis[state.PlayerList[target_number].Card]
		target_name = state.PlayerList[target_number].Player.name 
	end
	local pointString = string.format("%s%s **%s** points at %s%s **%s**!", roleEmojis[player.Card], numbers[my_number], user.name, target_card, emoji, target_name)

	for idx,playerObject in pairs(state.PlayerList) do
		if idx == target_number and target_number ~= my_number and not playerObject.Pointed then
			playerObject.Player:send(string.format("%s%s **%s** points at %s%s **%s**!", roleEmojis[player.Card], numbers[my_number], user.name, ":grey_question:", emoji, target_name))
		else
			playerObject.Player:send(pointString)
		end
	end

	-- Check for the end of the game
	checkForEnd(state)
end

function checkForEnd(state)
	-- Get game status
	local jesterWin = false
	local winningPlayers = {}
	local winnerCount = 0
	local pointCount = 0

	for idx,player in pairs(state.PlayerList) do
		if player.Card == "Jester" and player.Won then
			jesterWin = true
			winnerCount = 1
			winningPlayers = {}
			table.insert(winningPlayers, player.Player.name)
			break
		end
		if player.Won then 
			winnerCount = winnerCount + 1
			table.insert(winningPlayers, player.Player.name)
		end
		if player.Pointed then pointCount = pointCount + 1 end
	end

	-- Handle game overs
	local winStrings = {[0] = "**Game over!** Everybody lost! Which means the Assholes win :clap::clap::clap:", [1] = "**Game over!** %s won!", [2] = "**Game over!** %s and %s won!", [3] = "**Game over!** %s, %s, and %s won!", [4] = "**Game over!** Everybody won! ...wait, what? :flushed:"}
	if jesterWin or pointCount == 4 or winnerCount >= 2 then
		local output = string.format(winStrings[winnerCount], winningPlayers[1], winningPlayers[2], winningPlayers[3], winningPlayers[4])
		for idx,playerObject in pairs(state.PlayerList) do
			playerObject.Player:send(output)
		end
		quitGame(state)
	end
end

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

	for idx,playerObject in pairs(state.PlayerList) do
		if playerObject.Player.id == target.Player.id then
			state.PlayerList[idx].Status = message
		end
	end
end

return asshole