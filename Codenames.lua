local games = require("Games")
local misc = require("Misc")
local codenames = {}

local getWords, displayWords, displayWordsInColor, displayWordsCaptain, giveClue, pickWord, endGame, quitGame

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function codenames.startGame(message)
	-- Determine which team goes first
	--TODO: always red?
	local first
	if math.random(2) == 1 then first = "red" else first = "blue" end
	-- Initialize state
	local playerList = {}
	local team = "red"
	local rCaptain, bCaptain
	local i = 1
	for id,playerObject in pairs(message.mentionedUsers) do
		playerList[id] = {Player = playerObject, Team = team}
		if i == 1 then rCaptain = playerObject elseif i == 2 then bCaptain = playerObject end
		i = i + 1
		if team == "red" then team = "blue" else team = "red" end
	end

	local state = {
		GameChannel = message.channel,
		RedCaptain = rCaptain.id,
		BlueCaptain = bCaptain.id,
		Words = getWords(first), -- Each word is a table {Word = "word", Team = "blue/red/white/black", Flipped = true/false}
		PlayerList = playerList, -- Player = player object, Team = team color
		CurrentTeam = first,     -- Which team's turn is it?
		Phase = 0,               -- 0 = Captain picks a clue, 1 = team picks words
		Guesses = 0              -- Guesses left
	}

	-- Start game
	message.channel:send("Starting game...")
	displayWordsInColor(state)
	displayWordsCaptain(state, rCaptain)
	displayWordsCaptain(state, bCaptain)
	local startStr
	if first == "red" then startStr = "Red" else startStr = "Green" end
	local blueStr = ""
	local redStr = ""
	for id, playerInfo in pairs(playerList) do
		if playerInfo["Team"] == "blue" then blueStr = blueStr .. playerInfo["Player"].name .. ", "
		else redStr = redStr .. playerInfo["Player"].name .. ", " end
	end
	blueStr = blueStr:sub(1,-3)
	redStr = redStr:sub(1, -3)
	message.channel:send("The Green team is: " .. blueStr .. "\nThe Red team is: " .. redStr .. "\nThe " .. startStr .. " team is starting!")

	-- Create a new game and register it
	games.registerGame(message.channel, "Codenames", state, message.mentionedUsers)
end

function codenames.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end

	-- If Phase 1 and user is current team's color and user is not team captain, !pick
	if state["Phase"] == 1 then
		local userID = message.author.id
		if state["PlayerList"][userID] == nil then -- Not a player
		elseif state["PlayerList"][userID]["Team"] == state["CurrentTeam"] then
			if state["BlueCaptain"] ~= userID and state["RedCaptain"] ~= userID then
				if args[1] == "!pick" then
					pickWord(message, state)
				elseif args[1] == "!pass" then
					local nextStr
					state["Phase"] = 0
					state["Guesses"] = 0
					if state["CurrentTeam"] == "red" then state["CurrentTeam"] = "blue" else state["CurrentTeam"] = "red" end
					if state["CurrentTeam"] == "red" then nextStr = "Red" else nextStr = "Green" end
					state["GameChannel"]:send("Turn over! It is now " .. nextStr .. "'s turn!")					
				end
			end
		end
	end
end

function codenames.dmHandler(message, state)
	local args = message.content:split(" ")
	-- If Phase 0 and the user is on the current team and the user is a team captain, !clue
	local userID = message.author.id
	if state["BlueCaptain"] == userID or state["RedCaptain"] == userID then
		if args[1] == "!status" then
			displayWordsCaptain(state, message.author)
		end
	end
	if state["Phase"] == 0 then
		if state["PlayerList"][userID] == nil then -- Not a player
		elseif state["PlayerList"][userID]["Team"] == state["CurrentTeam"] then
			if state["BlueCaptain"] == userID or state["RedCaptain"] == userID then
				if args[1] == "!clue" then
					giveClue(message, state)
				end
			end
		end
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function quitGame(state)
	state["GameChannel"]:send("Quitting game...")
	games.deregisterGame(state["GameChannel"])
end

function endGame(state, winningTeam)
	local winStr
	if winningTeam == "red" then winStr = "Red" else winStr = "Green" end
	state["GameChannel"]:send("The game is over! The " .. winStr .. " team has won!")
	quitGame(state)
end

function pickWord(message, state)
	-- !pick <word>
	local args = message.content:split(" ")
	-- Verify that there is a word chosen
	if #args < 2 then message.channel:send("Usage: !pick <word>"); return end
	-- Verify that the word chosen is a word that's in the game
	local word = ""
	local info = nil
	for idx,arg in pairs(args) do if idx >= 2 and idx < #args then word = word .. arg .. " " elseif idx == #args then word = word .. arg end end
	for idx,wordInfo in pairs(state["Words"]) do
		if string.upper(wordInfo["Word"]) == string.upper(word) then
			info = wordInfo
			goto pickWordLoopEnd
		end
	end
	::pickWordLoopEnd::
	if info == nil then message.channel:send(word .. " is not a word in the game, homie!"); return end
	-- Flip the chosen word
	info["Flipped"] = true
	-- If the guess is correct, reduce guess counter by one (if not unlimited) and continue
	if info["Team"] == state["CurrentTeam"] then
		if state["Guesses"] ~= "unlimited" then state["Guesses"] = state["Guesses"] - 1 end
		-- Check for end of game
		--TODO
	elseif info["Team"] == "black" then
		-- If the guess is the assassin, the game ends
		local winTeam
		if state["CurrentTeam"] == "red" then winTeam = "blue" else winTeam = "red" end
		endGame(state, winTeam)
		return
	else
		-- If the guess is incorrect, set guess counter to 0 and continue
		state["Guesses"] = 0
	end
	-- If the guess counter is 0, swap phase and current team
	if state["Guesses"] == 0 then
		local nextStr
		state["Phase"] = 0
		if state["CurrentTeam"] == "red" then state["CurrentTeam"] = "blue" else state["CurrentTeam"] = "red" end
		if state["CurrentTeam"] == "red" then nextStr = "Red" else nextStr = "Green" end
		state["GameChannel"]:send("Turn over! It is now " .. nextStr .. "'s turn!")
	end
	displayWordsInColor(state)
end

function giveClue(message, state)
	-- !clue # <rest of command is clue>
	local args = message.content:split(" ")
	if #args < 3 then message.channel:send("Usage: !clue <number> <clue>"); return end
	-- Validate second arg is either a number from 0 to 25 or "unlimited"
	local count = tonumber(args[2])
	if (count == nil and args[2] ~= "unlimited") or (count ~= nil and count < 0) or (count ~= nil and count > 25) then
		message.channel:send("Second arg must be a number from 0 to 25 or 'unlimited'!")
		return
	end
	--TODO: Confirm clue does not contain any of the words
	if count == nil or count == 0 then count = "unlimited" else count = count + 1 end
	-- Construct clue from all args >= 3
	local clue = ""
	for idx,arg in pairs(args) do if idx > 2 then clue = clue .. arg .. " " end end
	clue = clue .. "(" .. args[2] .. ")"
	-- Send clue, update guesses left, and advance Phase
	state["Guesses"] = count
	state["Phase"] = 1
	state["GameChannel"]:send("The clue is: " .. clue)
end

function getWords(first)
	local deck = misc.shuffleTable(misc.parseCSV("words/codenames-en.csv"))
	local words = {}
	local teams = {
		"blue", "blue", "blue", "blue", "blue", "blue", "blue", "blue",
		"red", "red", "red", "red", "red", "red", "red", "red", 
		"white", "white", "white", "white", "white", "white", "white", "black", first
	}
	for i=1,25 do
		local word = deck[i]
		words[i] = {Word = word, Team = teams[i], Flipped = false}
	end
	misc.shuffleTable(words)
	return words
end

function displayWordsInColor(state)
	local output = "Words:\n```ml\n"
	local fString = "%-12s "
	for idx, word in pairs(state["Words"]) do
		if word["Flipped"] then
			if word["Team"] == "blue" then output = output .. string.format(fString, "\"GREEN\"")
			elseif word["Team"] == "red" then output = output .. string.format(fString, "'RED'")
			elseif word["Team"] == "white" then output = output .. string.format(fString, "white")
			else output = output .. string.format(fString, "ASSASSIN") end
		else output = output .. string.format(fString, word["Word"]) end
		if idx % 5 == 0 then output = output .. "\n" end
	end
	output = output .. "```"
	state["GameChannel"]:send(output)
end

function displayWords(state)
	local output = "Words:\n```\n"
	local fString = "%-12s "
	for idx, word in pairs(state["Words"]) do
		if word["Flipped"] then output = output .. string.format(fString, string.upper(word["Team"]))
		else output = output .. string.format(fString, word["Word"]) end
		if idx % 5 == 0 then output = output .. "\n" end
	end
	output = output .. "```"
	state["GameChannel"]:send(output)
end

function displayWordsCaptain(state, user)
	local bWords = "Green Words:  "
	local rWords = "Red Words    "
	local wWords = "White Words: "
	local aWord  = "Assassin:    "
	local fString = "%s, "
	-- Get words
	for idx, word in pairs(state["Words"]) do
		if not word["Flipped"] then
			if word["Team"] == "blue" then bWords = bWords .. string.format(fString, word["Word"])
			elseif word["Team"] == "red" then rWords = rWords .. string.format(fString, word["Word"])
			elseif word["Team"] == "white" then wWords = wWords .. string.format(fString, word["Word"])
			else aWord = aWord .. string.format(fString, word["Word"]) end
		end
	end
	-- Trim last comma
	bWords = bWords:sub(1, -3)
	rWords = rWords:sub(1, -3)
	wWords = wWords:sub(1, -3)
	aWord  = aWord:sub(1, -3)
	user:send("```\n" .. bWords .. "\n" .. rWords .. "\n" .. wWords .. "\n" .. aWord .. "```")
end

return codenames