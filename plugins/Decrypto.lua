local games = require("Games")
local misc = require("Misc")
local decrypto = {}
decrypto.desc = "A word game for 4+ players. Players are split into teams, who each see a list of four words. Each team takes turns giving clues to their word list, without giving their words away to the other team."
decrypto.rules = "https://www.ultraboardgames.com/decrypto/game-rules.php"
decrypto.startInDMs = "vcOnly"

-- Local functions
local dmInfo, advancePhases, dmClue, checkClues, checkForEndgame, getRandomNumbers, quitGame, handleGimme, handleClue, handleGuess, getPlayerFromID

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function decrypto.startGame(message, players)
	-- Split players into teams
	local playerList = {}
	local team = "red"
	for idx,playerObject in pairs(players) do
		playerList[idx] = {Player = playerObject, Team = team}
		if team == "red" then team = "blue" else team = "red" end
	end

	local state = {
		GameChannel = message.channel,
		PlayerList = playerList, -- Player = player object, Team = team color
		Round = 1,
		BluePhase = 0, -- Claim cluegiver; Wait for blue clue; Guess blue clue; Wait for red clue; Guess red clue; Wait for round end
		RedPhase = 0,
		BlueClueGiver = nil,
		RedClueGiver = nil,
		HaveBlueClues = false,
		HaveRedClues = false,
		BlueNumbers = getRandomNumbers(),
		RedNumbers = getRandomNumbers(),
		BlueGuess = nil,
		RedGuess = nil,
		BlueWords = {},
		RedWords = {},
		BlueClues = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}, -- 1 = {Round = Clue, Round = Clue...}, 2 = {}, 3 = {}, 4 = {}
		RedClues = {[1] = {}, [2] = {}, [3] = {}, [4] = {}},
		BlueIntercepts = 0,
		BlueGoofs = 0,
		RedIntercepts = 0,
		RedGoofs = 0
	}

	-- Get eight random words
	local deck = misc.shuffleTable(misc.parseCSV("words/op_decrypto.csv"))
	for i=1,4 do table.insert(state.BlueWords, deck[i]) end
	for i=5,8 do table.insert(state.RedWords, deck[i]) end

	-- Send everybody the status
	for id,player in pairs(state.PlayerList) do
		dmInfo(state, player)
	end

	-- Create a new game and register it
	state.GameID = games.registerGame(message.channel, "Decrypto", state, players)
end

function decrypto.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end
end

function decrypto.dmHandler(message, state)
	local args = message.content:split(" ")

	if args[1] == "!quit" then 
		quitGame(state)
	elseif args[1] == "!gimme" then
		handleGimme(state, message.author)
	elseif args[1] == "!clue" then
		handleClue(state, message.author, message.content)
	elseif args[1] == "!guess" then
		handleGuess(state, message.author, args)
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function getPlayerFromID(state, user)
	for idx,player in pairs(state.PlayerList) do
		if player.Player.id == user.id then return player end
	end
	return nil
end

function handleGimme(state, user)
	-- If the user's team is on Phase 0, set cluegiver and advance phase
	local player = getPlayerFromID(state, user)
	if player.Team == "blue" then
		if state.BluePhase == 0 then
			state.BlueClueGiver = player
			advancePhases(state)
			for id,player in pairs(state.PlayerList) do
				if player.Team == "blue" and player.Player.id ~= state.BlueClueGiver.Player.id then
					player.Player:send(state.BlueClueGiver.Player.name .. " is preparing the clues!")
				end
			end
		end
	elseif player.Team == "red" then
		if state.RedPhase == 0 then
			state.RedClueGiver = player
			advancePhases(state)
			for id,player in pairs(state.PlayerList) do
				if player.Team == "red" and player.Player.id ~= state.RedClueGiver.Player.id then
					player.Player:send(state.RedClueGiver.Player.name .. " is preparing the clues!")
				end
			end
		end
	end
end

function handleClue(state, user, text)
	local player = getPlayerFromID(state, user)
	local isValid = false

	-- If the user is the cluegiver and their team is on Phase 1, set clues and advance state
	if (player.Team == "blue" and state.BlueClueGiver and state.BlueClueGiver.Player.id == user.id and state.BluePhase == 1) or (player.Team == "red" and state.RedClueGiver and state.RedClueGiver.Player.id == user.id and state.RedPhase == 1) then
		isValid = true
	end

	if isValid then
		-- Try to split on semicolons; if we don't get three clues out of it, split on spaces instead
		local clues = string.sub(text, 7):split("; ")
		if #clues ~= 3 then clues = string.sub(text, 7):split(" ") end
		if #clues ~= 3 then clues = nil end

		if clues == nil then
			player.Player:send("Invalid clues! Format: `!clue first clue; second clue; third clue` or `!clue first_clue second_clue third_clue`")
			return
		else
			local sortedClues = {1, 2, 3, 4}
			local numbers = player.Team == "blue" and state.BlueNumbers or state.RedNumbers
			local tbl = player.Team == "blue" and state.BlueClues or state.RedClues

			if player.Team == "blue" then state.HaveBlueClues = true else state.HaveRedClues = true end

			-- Associate clues with numbers
			sortedClues[math.floor(numbers/100)] = clues[1]
			sortedClues[(math.floor(numbers/10)) % 10] = clues[2]
			sortedClues[numbers % 10] = clues[3]

			-- Put clues into the state clue table
			for idx,clue in ipairs(sortedClues) do
				if type(clue) ~= "number" then table.insert(tbl[idx], state.Round, clue) end
			end
		end

		user:send("Clues received!")
		advancePhases(state)
	end
end

function handleGuess(state, user, args)
	local player = getPlayerFromID(state, user)
	local phase = player.Team == "blue" and state.BluePhase or state.RedPhase
	local isValid = false
	local guess = nil
	if #args >= 2 then guess = tonumber(args[2]) end

	-- Check if this is a valid guess (ie, the phase/player is valid)
	if phase == 2 then
		-- If the player isn't cluegiver, accept the guess
		if (player.Team == "blue" and user.id ~= state.BlueClueGiver.Player.id) or (player.Team == "red" and user.id ~= state.RedClueGiver.Player.id) then
			isValid = true
		end
	elseif phase == 4 then
		-- Accept the guess
		isValid = true
	end

	-- If it's valid, handle the guess
	--TODO: Error handling if the guess isn't a three-digit number composed of unique digits from 1-4
	if isValid then
		if
			guess == nil then player.Player:send("Invalid guess! Format: `!guess 123`")
		else
			if player.Team == "blue" then state.BlueGuess = guess else state.RedGuess = guess end
			advancePhases(state)
		end
	end
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameID)
end

function advancePhases(state)
	-- Advance blue phase first
	if state.BluePhase == 0 then
		if state.BlueClueGiver ~= nil then
			state.BluePhase = 1
			local num1 = math.floor(state.BlueNumbers/100) 
			local num2 = math.floor(state.BlueNumbers/10)  % 10
			local num3 = math.floor(state.BlueNumbers)     % 10
			state.BlueClueGiver.Player:send(string.format("Your words are: [%i] %s / [%i] %s / [%i] %s", num1, state.BlueWords[num1], num2, state.BlueWords[num2], num3, state.BlueWords[num3]))
			--state.BlueClueGiver.Player:send("Your numbers are: " .. tostring(state.BlueNumbers))
		end
	elseif state.BluePhase == 1 then -- Advance if we have a clue from someone on blue team
		if state.HaveBlueClues == true then
			state.BluePhase = 2
			-- Ask all blue non-cluegivers to guess the numbers
			for id,player in pairs(state.PlayerList) do
				if player.Team == "blue" and player.Player.id ~= state.BlueClueGiver.Player.id then
					dmClue(state, player, false)
				end
			end
		end
	elseif state.BluePhase == 2 then -- Advance if we have a guess from someone on blue team
		if state.BlueGuess ~= nil then
			state.BluePhase = 3
			-- Check if guess is correct
			local result = checkClues(state, "blue", false)
			-- Handle score stuff
			if result then
				for id,player in pairs(state.PlayerList) do
					if player.Team == "blue" then player.Player:send("Guess correct!") end
				end
			else
				for id,player in pairs(state.PlayerList) do
					if player.Team == "blue" then player.Player:send("Guess incorrect :(") end
				end
				state.BlueGoofs = state.BlueGoofs + 1
			end
		end
	elseif state.BluePhase == 3 then -- Handle this simultaneously
	elseif state.BluePhase == 4 then -- Advance if we have a guess from someone on blue team
		if state.BlueGuess ~= nil then
			state.BluePhase = 5
			-- Check if the guess is correct
			local result = checkClues(state, "blue", true)
			-- Handle score stuff
			if result then
				for id,player in pairs(state.PlayerList) do
					if player.Team == "blue" then player.Player:send("Guess correct!") end
				end
				state.BlueIntercepts = state.BlueIntercepts + 1
			else
				for id,player in pairs(state.PlayerList) do
					if player.Team == "blue" then player.Player:send("Guess incorrect :(") end
				end
			end
		end
	elseif state.BluePhase == 5 then -- Do nothing
	end

	-- Advance red phase next
	if state.RedPhase == 0 then
		if state.RedClueGiver ~= nil then
			state.RedPhase = 1
			local num1 = math.floor(state.RedNumbers/100) 
			local num2 = math.floor(state.RedNumbers/10)  % 10
			local num3 = math.floor(state.RedNumbers)     % 10
			state.RedClueGiver.Player:send(string.format("Your words are: [%i] %s / [%i] %s / [%i] %s", num1, state.RedWords[num1], num2, state.RedWords[num2], num3, state.RedWords[num3]))
		end
	elseif state.RedPhase == 1 then -- Advance if we have a clue from someone on red team
		if state.HaveRedClues == true then
			state.RedPhase = 2
			-- Ask all red non-cluegivers to guess the numbers
			for id,player in pairs(state.PlayerList) do
				if player.Team == "red" and player.Player.id ~= state.RedClueGiver.Player.id then
					dmClue(state, player, false)
				end
			end
		end
	elseif state.RedPhase == 2 then -- Advance if we have a guess from someone on red team
		if state.RedGuess ~= nil then
			state.RedPhase = 3
			-- Check if guess is correct
			local result = checkClues(state, "red", false)
			-- Handle score stuff
			if result then
				for id,player in pairs(state.PlayerList) do
					if player.Team == "red" then player.Player:send("Guess correct!") end
				end
			else
				for id,player in pairs(state.PlayerList) do
					if player.Team == "red" then player.Player:send("Guess incorrect :(") end
				end
				state.RedGoofs = state.RedGoofs + 1
			end
		end
	elseif state.RedPhase == 3 then -- Handle this simultaneously
	elseif state.RedPhase == 4 then -- Advance if we have a guess from someone on red team
		if state.RedGuess ~= nil then
			state.RedPhase = 5
			-- Check if the guess is correct
			local result = checkClues(state, "red", true)
			-- Handle score stuff
			if result then
				for id,player in pairs(state.PlayerList) do
					if player.Team == "red" then player.Player:send("Guess correct!") end
				end
				state.RedIntercepts = state.RedIntercepts + 1
			else
				for id,player in pairs(state.PlayerList) do
					if player.Team == "red" then player.Player:send("Guess incorrect :(") end
				end
			end
		end
	elseif state.RedPhase == 5 then -- Handle this simultaneously
	end

	-- Advance both teams if they're ready for Phase 4
	if state.RedPhase == 3 and state.BluePhase == 3 then
		if state.Round == 1 then
			-- Lowkey think it would be cleaner to just goto down 20 lines here
			state.RedPhase = 5
			state.BluePhase = 5
		else
			-- Update state
			state.BluePhase = 4
			state.RedPhase = 4
			state.BlueGuess = nil
			state.RedGuess = nil
			-- Send everyone clues
			for id,player in pairs(state.PlayerList) do
				dmClue(state, player, true)
			end
		end
	end

	-- Advance both teams if they're on Phase 5
	if state.RedPhase == 5 and state.BluePhase == 5 then
		-- Set up for next round
		state.Round = state.Round + 1
		state.BluePhase = 0
		state.RedPhase = 0
		state.BlueClueGiver = nil
		state.RedClueGiver = nil
		state.HaveBlueClues = false
		state.HaveRedClues = false
		state.BlueNumbers = getRandomNumbers()
		state.RedNumbers = getRandomNumbers()
		state.BlueGuess = nil
		state.RedGuess = nil

		-- Send everybody the status
		for id,player in pairs(state.PlayerList) do
			dmInfo(state, player)
		end

		-- Check for endgame
		checkForEndgame(state)
	end
end

function dmClue(state, player, isOpposite)
	local fstring = "The clues are:\na. %s\nb. %s\nc. %s"
	local words = {}
	local clue_a = nil
	local clue_b = nil
	local clue_c = nil
	-- Get the right clues
	if (player.Team == "blue" and not isOpposite) or (player.Team == "red" and isOpposite) then
		clue_a = state.BlueClues[math.floor(state.BlueNumbers/100)][state.Round]
		clue_b = state.BlueClues[math.floor(state.BlueNumbers/10) % 10][state.Round]
		clue_c = state.BlueClues[state.BlueNumbers % 10][state.Round]
	else
		misc.deepPrintTable(state.RedClues)
		clue_a = state.RedClues[math.floor(state.RedNumbers/100)][state.Round]
		clue_b = state.RedClues[math.floor(state.RedNumbers/10) % 10][state.Round]
		clue_c = state.RedClues[state.RedNumbers % 10][state.Round]
	end
	-- Send the clues
	player.Player:send(string.format(fstring, clue_a, clue_b, clue_c))
end

function checkClues(state, team, isOpposite)
	if (team == "blue" and not isOpposite) or (team == "red" and isOpposite) then
		if team == "blue" then return state.BlueGuess == state.BlueNumbers
		else return state.RedGuess == state.BlueNumbers end
	else
		if team == "blue" then return state.BlueGuess == state.RedNumbers
		else return state.RedGuess == state.RedNumbers end
	end
end

function getRandomNumbers(state)
	local tbl = {1, 2, 3, 4}
	misc.shuffleTable(tbl)
	return tbl[1]*100 + tbl[2]*10 + tbl[3]
end

function checkForEndgame(state)
	local winner = nil
	local isTie = false
	-- Check for endgame
	if state.BlueIntercepts == 2 or state.RedIntercepts == 2 or state.BlueGoofs == 2 or state.RedGoofs == 2 then
		-- The end of the game has been reached! Now check for ties
		isTie = (state.BlueIntercepts + state.BlueGoofs == 4) or (state.RedIntercepts + state.RedGoofs == 4)
		isTie = isTie or (state.RedIntercepts + state.BlueIntercepts == 4) or (state.RedGoofs + state.BlueGoofs == 4)

		-- Handle ties
		if isTie then
			local blueScore = state.BlueIntercepts - state.BlueGoofs
			local redScore = state.RedIntercepts - state.RedGoofs
			if blueScore > redScore then winner = "blue"
			elseif redScore > blueScore then winner = "red"
			else winner = "tie" end
		else
			if state.BlueIntercepts == 2 or state.RedGoofs == 2 then winner = "blue" else winner = "red" end
		end
	end

	-- If the game is over, handle that
	if winner == "red" or winner == "blue" then
		-- Reveal the words
		local fstring = "Blue words: ||1. %s; 2. %s; 3. %s; 4. %s||\nRed words: ||1. %s; 2. %s; 3. %s; 4. %s||"
		local output = string.format(fstring, state.BlueWords[1], state.BlueWords[2], state.BlueWords[3], state.BlueWords[4], state.RedWords[1], state.RedWords[2], state.RedWords[3], state.RedWords[4])

		-- Inform everyone the game is over
		state.GameChannel:send("**The game is over! The " .. winner .. " team has won!**\n" .. output)
		for idx,player in pairs(state.PlayerList) do
			player.Player:send("**The game is over! The " .. winner .. " team has won!**\n" .. output)
		end
		quitGame(state)
	elseif winner == "tie" then
		state.GameChannel:send("**The game is over, but it's a tie! For the ultimate tiebreaker, each team can take a stab at guessing the other's words!**")
		for idx,player in pairs(state.PlayerList) do
			player.Player:send("**The game is over, but it's a tie! For the ultimate tiebreaker, each team can take a stab at guessing the other's words!**")
		end
		quitGame(state)
	end
end

function dmInfo(state, player)
	local string_bluestart = "```asciidoc\n===== BLUE WORDS =====\n"
	local string_blueword = "= <%i> %s =\n"

	local string_redstart = "```asciidoc\n[===== RED WORDS =====]\n"
	local string_redword = "[ <%i> %s ]\n"

	local string_clue = "\t(%i) %s\n"
	local string_score = "```asciidoc\n= BLUE TEAM =\nPlayers: %s\nInterceptions: %i\nMiscommunications: %i\n\n[  RED TEAM  ]\nPlayers: %s\nInterceptions: %i\nMiscommunications: %i\n```"

	local output = ""

	-- Display blue words
	output = output .. string_bluestart
	for i=1,4 do
		-- Display secret word
		if player.Team == "blue" then
			output = output .. string.format(string_blueword, i, state.BlueWords[i])
		else
			output = output .. string.format(string_blueword, i, "???")
		end
		-- Display clues
		for idx,clues in pairs(state.BlueClues) do
			-- Is this our word?
			if idx == i then
				-- Print each clue
				for round,clue in pairs(clues) do
					output = output .. string.format(string_clue, round, clue)
				end
			end
		end
	end
	output = output .. "```"

	-- Display red words
	output = output .. string_redstart
	for i=1,4 do
		-- Display secret word
		if player.Team == "red" then
			output = output .. string.format(string_redword, i, state.RedWords[i])
		else
			output = output .. string.format(string_redword, i, "???")
		end
		-- Display clues
		for idx,clues in pairs(state.RedClues) do
			-- Is this our word?
			if idx == i then
				-- Print each clue
				for round,clue in pairs(clues) do
					output = output .. string.format(string_clue, round, clue)
				end
			end
		end
	end
	output = output .. "```"

	-- Get player lists
	local bluePlayers = ""
	local redPlayers = ""
	for idx,player in pairs(state.PlayerList) do
		if player.Team == "blue" then bluePlayers = bluePlayers .. ", " .. player.Player.name
		else redPlayers = redPlayers .. ", " .. player.Player.name
		end 
	end

	local bluePlayers = string.sub(bluePlayers, 3)
	local redPlayers = string.sub(redPlayers, 3)

	-- Display score
	output = output .. string.format(string_score, bluePlayers, state.BlueIntercepts, state.BlueGoofs, redPlayers, state.RedIntercepts, state.RedGoofs)

	player.Player:send(output)
end

return decrypto