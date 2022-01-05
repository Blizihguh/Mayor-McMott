local games = require("Games")
local misc = require("Misc")
local codenames = {}

local getWords, displayWords, displayWordsInColor, displayWordsUnicode, displayWordsCondensed, displayWordsCaptain, giveClue, pickWord, endGame, quitGame

local WORD_LISTS = {
	en = "words/codenames-en.csv", 
	jp = "words/codenames-jp.csv"
}

-- Table definitions for injoke lists that only get pulled up on specific servers can be placed in a separate file
local SERVER_LIST = {}
if misc.fileExists("plugins/server-specific/Codenames-SP.lua") then
	SERVER_LIST = require("plugins/server-specific/Codenames-SP")
end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function codenames.startGame(message, players)
	-- Determine which team goes first
	local first
	if math.random(2) == 1 then first = "red" else first = "blue" end
	-- Initialize state
	local playerList = {}
	local team = "red"
	local rCaptain, bCaptain
	local i = 1
	for idx,playerObject in pairs(players) do
		playerList[playerObject.id] = {Player = playerObject, Team = team}
		if i == 1 then rCaptain = playerObject elseif i == 2 then bCaptain = playerObject end
		i = i + 1
		if team == "red" then team = "blue" else team = "red" end
	end

	-- Get custom wordlists
	for server,list in pairs(SERVER_LIST) do
		if message.guild.id == server then WORD_LISTS = list end
	end

	-- If a specific wordlist is requested, get that one
	local args = message.content:split(" ")
	local list = "words/codenames-en.csv"
	if WORD_LISTS[args[3]] ~= nil then list = WORD_LISTS[args[3]] end

	local state = {
		GameChannel = message.channel,
		RedCaptain = rCaptain.id,
		BlueCaptain = bCaptain.id,
		Words = getWords(first, list), -- Each word is a table {Word = "word", Team = "blue/red/white/black", Flipped = true/false}
		PlayerList = playerList, -- Player = player object, Team = team color
		CurrentTeam = first,     -- Which team's turn is it?
		Phase = 0,               -- 0 = Captain picks a clue, 1 = team picks words
		Guesses = 0,             -- Guesses left
		RedWords = 8,            -- Words left to guess
		BlueWords = 8
	}
	if first == "red" then state["RedWords"] = state["RedWords"] + 1 else state["BlueWords"] = state["BlueWords"] + 1 end

	-- Start game
	message.channel:send("Starting game...")
	displayWordsCondensed(state)
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
	games.registerGame(message.channel, "Codenames", state, players)
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
	state["GameChannel"]:send("**The game is over! The " .. winStr .. " team has won!**")
	--displayWordsCondensed(state)
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
	-- Message the channel what the color of the chosen word is
	local output = ""
	if info["Team"] == "red" then output = info["Word"] .. " was a 🟥 Red 🟥 word!" 
	elseif info["Team"] == "blue" then output = info["Word"] .. " was a 🟩 Green 🟩 word!" 
	elseif info["Team"] == "white" then output = info["Word"] .. " was a 🟫 Civilian 🟫 word!" 
	else output = info["Word"] .. " was the 💀 Assassin 💀!" 
	end
	state["GameChannel"]:send(output)
	
	-- Update words left for the team whose card was just flipped
	if info["Team"] == "red" then state["RedWords"] = state["RedWords"] - 1
	elseif info["Team"] == "blue" then state["BlueWords"] = state["BlueWords"] - 1
	end

	-- Update guesses left
	if info["Team"] == state["CurrentTeam"] then
		-- If the guess is correct, reduce guess counter by one (if not unlimited) and continue
		if state["Guesses"] ~= "unlimited" then state["Guesses"] = state["Guesses"] - 1 end
	else
		-- If the guess is incorrect, set guess counter to 0 and continue
		state["Guesses"] = 0
	end

	-- Check for end of game
	if info["Team"] == "black" then
		-- Card was the assassin
		endGame(state, state["CurrentTeam"] == "red" and "blue" or "red")
		return
	elseif state["RedWords"] == 0 then 
		endGame(state, "red")
		return
	elseif state["BlueWords"] == 0 then
		endGame(state, "blue")
		return
	end

	-- If the guess counter is 0, swap phase and current team
	if state["Guesses"] == 0 then
		local nextStr
		state["Phase"] = 0
		if state["CurrentTeam"] == "red" then state["CurrentTeam"] = "blue" else state["CurrentTeam"] = "red" end
		if state["CurrentTeam"] == "red" then nextStr = "Red" else nextStr = "Green" end
		state["GameChannel"]:send("Turn over! It is now " .. nextStr .. "'s turn!")
	end

	displayWordsCondensed(state)
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

function getWords(first, list)
	local deck = misc.shuffleTable(misc.parseCSV(list))
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

function displayWordsCondensed(state)
	local output = {""}
	local fString = "%-12s "
	-- Survey results:
	-- 61, 59, 47, 43, 41, 41, 41, 31
	local line_length = 40
	-- Statistics
	local redFlipped   = 0
	local redTotal     = 0
	local blueFlipped  = 0
	local blueTotal    = 0
	local whiteFlipped = 0
	local assFlipped   = 0
	-- Get words
	for idx, word in pairs(state["Words"]) do
		if word["Flipped"] then
			-- Get statistics
			if word["Team"] == "blue" then
				blueFlipped = blueFlipped + 1
				blueTotal = blueTotal + 1
			elseif word["Team"] == "red" then
				redFlipped = redFlipped + 1
				redTotal = redTotal + 1
			elseif word["Team"] == "white" then
				whiteFlipped = whiteFlipped + 1
			else
				assFlipped = assFlipped + 1
			end
		else
			-- Get statistics
			if word["Team"] == "blue" then blueTotal = blueTotal + 1
			elseif word["Team"] == "red" then redTotal = redTotal + 1
			end
			-- Do output
			if string.len(output[#output]) + string.len(word["Word"]) > line_length then
				output[#output] = output[#output] .. "\n"
				table.insert(output, "")
			end
			output[#output] = output[#output] .. string.format(fString, word["Word"])
		end
	end

	-- Sort table by line length and add initial line
	table.sort(output, function(a,b) return #a>#b end)
	table.insert(output, 1, "```\n")

	-- Output words
	local outputString = "⬜ Words:\n"
	for idx,line in ipairs(output) do outputString = outputString .. line end
	outputString = outputString .. "```"

	-- Output stats
	outputString = outputString .. "🟥 `Red Words:      " .. redFlipped .. "/" .. redTotal .. "`\n"
	outputString = outputString .. "🟩 `Green Words:    " .. blueFlipped .. "/" .. blueTotal .. "`\n"
	outputString = outputString .. "🟫 `Civilians Baffled: " .. whiteFlipped .. "/7`"

	state["GameChannel"]:send(outputString)
end

function displayWordsUnicode(state)
	local output = "Words:\n```\n"
	local fString = "%-12s "
	local redFlipped = 0
	local redTotal = 0
	local blueFlipped = 0
	local blueTotal = 0
	for idx, word in pairs(state["Words"]) do
		if word["Flipped"] then
			if word["Team"] == "blue" then 
				output = output .. string.format(fString, "🟩🟩🟩🟩  ")
				blueFlipped = blueFlipped + 1
				blueTotal = blueTotal + 1
			elseif word["Team"] == "red" then 
				output = output .. string.format(fString, "🟥🟥🟥🟥  ")
				redFlipped = redFlipped + 1
				redTotal = redTotal + 1
			elseif word["Team"] == "white" then 
				output = output .. string.format(fString, "🟫🟫🟫🟫  ")
			else 
				output = output .. string.format(fString, "💀💀💀     ") 
			end
		else 
			output = output .. string.format(fString, word["Word"]) 
			if word["Team"] == "blue" then blueTotal = blueTotal + 1
			elseif word["Team"] == "red" then redTotal = redTotal + 1 end
		end
		if idx % 5 == 0 then output = output .. "\n" end
	end
	output = output .. "```"
	
	-- Show remaining word count
	local ctString = "```🟩 Green: %i/%i 🟩 \t 🟥 Red: %i/%i 🟥```"
	output = output .. string.format(ctString, blueFlipped, blueTotal, redFlipped, redTotal)

	state["GameChannel"]:send(output)
end

function displayWordsInColor(state)
	local output = "Words:\n```ml\n"
	local fString = "%-12s "
	local redFlipped = 0
	local redTotal = 0
	local blueFlipped = 0
	local blueTotal = 0
	for idx, word in pairs(state["Words"]) do
		if word["Flipped"] then
			if word["Team"] == "blue" then 
				output = output .. string.format(fString, "\"GREEN\"")
				blueFlipped = blueFlipped + 1
				blueTotal = blueTotal + 1
			elseif word["Team"] == "red" then 
				output = output .. string.format(fString, "'RED'")
				redFlipped = redFlipped + 1
				redTotal = redTotal + 1
			elseif word["Team"] == "white" then 
				output = output .. string.format(fString, "white")
			else 
				output = output .. string.format(fString, "ASSASSIN") 
			end
		else 
			output = output .. string.format(fString, word["Word"]) 
			if word["Team"] == "blue" then blueTotal = blueTotal + 1
			elseif word["Team"] == "red" then redTotal = redTotal + 1 end
		end
		if idx % 5 == 0 then output = output .. "\n" end
	end
	output = output .. "```"
	
	-- Show remaining word count
	local ctString = "```Green: %i/%i\tRed: %i/%i```"
	output = output .. string.format(ctString, blueFlipped, blueTotal, redFlipped, redTotal)

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
	local bWords = "🟩🟩🟩🟩:  "
	local rWords = "🟥🟥🟥🟥:  "
	local wWords = "🟫🟫🟫🟫:  "
	local aWord  = "💀💀💀💀:  "
	local fString = "%s, "
	-- Get words
	for idx, word in pairs(state["Words"]) do
		if not word["Flipped"] then
			if word["Team"] == "blue" then bWords = bWords .. string.format(fString, "\"" .. word["Word"] .. "\"")
			elseif word["Team"] == "red" then rWords = rWords .. string.format(fString, "'" .. string.gsub(word["Word"], "%s+", "_") .. "'") --Remove whitespace because ml
			elseif word["Team"] == "white" then wWords = wWords .. string.format(fString, word["Word"])
			else aWord = aWord .. string.format(fString, string.lower(word["Word"])) end
		end
	end
	-- Trim last comma
	bWords = bWords:sub(1, -3)
	rWords = rWords:sub(1, -3)
	wWords = wWords:sub(1, -3)
	aWord  = aWord:sub(1, -3)
	user:send("```ml\n" .. bWords .. "\n" .. rWords .. "\n" .. wWords .. "\n" .. aWord .. "```")
end

return codenames