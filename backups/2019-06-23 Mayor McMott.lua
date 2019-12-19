local discordia = require("discordia")
local csv = require("csv")
local client = discordia.Client()

discordia.extensions() -- load all helpful extensions


--#############################################################################################################################################
--# State/Globals                                                                                                                             #
--#############################################################################################################################################
local currentGame = {
	InProgress = false,
	Mayor = nil,
	Seer = nil,
	Mode = nil,
	PlayerList = nil,
	Word = nil,
	WordsTemp = nil,
	NightOver = false,
	BasicToken = 36,
	QuestionToken = 10,
	WayOffToken = 1,
	SoCloseToken = 1,
	SeerToken = 1,
	LastQuestion = nil
}

local rulesets = {
	WS = {"Werewolf", "Seer"},
	WSF = {"Werewolf", "Seer", "Fortune Teller"}
}

local wordlists = {}

--#############################################################################################################################################
--# Functions                                                                                                                                 #
--#############################################################################################################################################
function parseCSV(filename)
	local tbl = {}
	local f = csv.open(filename)
	for fields in f:lines() do
		for i,v in pairs(fields) do tbl[i] = v end
	end
	return tbl
end

function getTellerWord(str)
	local output = ""
	local first = true
	for i=1, #str do
		local char = str:sub(i,i)
		if first == true then
			output = output .. char
			first = false
		elseif char == " " then
			output = output .. " "
			first = true
		elseif first == false then
			output = output .. "-"
		end
	end
	return output
end

function printTable(table)
	for key,value in pairs(table) do
		print(tostring(key) .. "\t" .. tostring(value))
	end
end

function shuffleTable(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

function indexifyTable(tbl)
	local newTbl = {}
	i = 1
	for k,v in pairs(tbl) do
		newTbl[i] = v
		i = i + 1
	end
	return newTbl
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function createGameInstance()
	local instance = {
		InProgress = false,
		GameChannel = nil,
		Mayor = nil,
		Seer = nil,
		Mode = nil,
		PlayerList = nil,
		Word = nil,
		WordsTemp = nil,
		NightOver = false,
		BasicToken = 36,
		QuestionToken = 10,
		WayOffToken = 1,
		SoCloseToken = 1,
		SeerToken = 1,
		LastQuestion = nil
	}
	return instance
end

function assignRoles(players, ruleset)
	-- Shuffle players
	-- If ruleset doesn't exist, error
	if rulesets[ruleset] == nil then
		messageGame("Error! Role list does not exist.")
		exitGame()
		return
	end
	-- Assign player roles
	local shuffledPlayers = shuffleTable(shallowcopy(indexifyTable(players)))
	local playerList = {}
	local specialRoles = shallowcopy(rulesets[ruleset])
	for i, player in pairs(shuffledPlayers) do
		if specialRoles[i] ~= nil then
			playerList[i] = {player, specialRoles[i]}
			-- If special role is Seer, save a reference to the player
			if specialRoles[i] == "Seer" then
				currentGame["Seer"] = player
			end
		else
			playerList[i] = {player, "Vanilla Townie"}
		end
		messagePlayer(player, "You are: " .. playerList[i][2])
	end
	currentGame["PlayerList"] = shuffleTable(playerList)
end

function sendWordOptions()
	-- If word list doesn't exist, error
	if wordlists[currentGame["Mode"]] == nil then
		messageGame("Error! Word list does not exist.")
		sendWordLists(currentGame["GameChannel"])
		exitGame()
	end
	-- Pick four words at random and send them to the mayor
	local list = wordlists[currentGame["Mode"]]
	local words = {list[math.random(#list)],list[math.random(#list)],list[math.random(#list)],list[math.random(#list)]}
	output = "Your word choices are:\n1: " .. words[1] .. "\n2: " .. words[2] .. "\n3: " .. words[3] .. "\n4: " .. words[4]
	currentGame["WordsTemp"] = words
	messagePlayer(currentGame["Mayor"], output)
end

--##########################
--######## ADD ROLES HERE ##
--##########################
function finishNight()
	for idx,playerInfo in pairs(currentGame["PlayerList"]) do
		local player = playerInfo[1]
		-- WEREWOLF:
		if playerInfo[2] == "Werewolf" then
			-- Inform of word
			messagePlayer(player, "The word is: " .. currentGame["Word"])
			-- Inform of all other werewolves
			for idx2,playerInfo2 in pairs(currentGame["PlayerList"]) do
				if idx ~= idx2 and playerInfo2[2] == "Werewolf" then
					messagePlayer(player, playerInfo2[1].name .. " is a werewolf!")
				end
			end
		-- SEER:
		elseif playerInfo[2] == "Seer" then
			messagePlayer(player, "The word is: " .. currentGame["Word"])
		-- APPRENTICE:
		elseif playerInfo[2] == "Fortune Teller" then
			local censoredWord = getTellerWord(currentGame["Word"])
			messagePlayer(player, "The word is: " .. censoredWord)
		end
	end
	currentGame["NightOver"] = true
	messageGame("The game has begun!")
end

function checkForEnd()
	-- Check for Wolf Win end and if it's the case, have Town vote on wolves
end

function messageGame(string)
	if currentGame["InProgress"] then 
		currentGame["GameChannel"]:send(string)
	else 
		print("Attempted to send string to nonexistant game: " .. string) 
	end
end

function messagePlayer(player, string)
	player:send(string)
end

--#############################################################################################################################################
--# Commands                                                                                                                                  #
--#############################################################################################################################################
function createGame(mayor, mode, players, ruleset, channel)
	-- Initialize variables
	currentGame = createGameInstance()
	currentGame["InProgress"] = true
	currentGame["GameChannel"] = channel
	currentGame["Mayor"] = mayor
	currentGame["Mode"] = mode
	messageGame("Starting game...")
	-- Assign roles
	assignRoles(players, ruleset)
	messageGame("Roles sent out...")
	-- Send Mayor some words
	sendWordOptions()
end

function exitGame()
	messageGame("Quitting game...")
	currentGame = createGameInstance()
end

function sendWordLists(channel)
	local output = "Currently loaded wordlists:\n"
	for name,tbl in pairs(wordlists) do
		output = output .. name .. " (" .. #tbl .. ")\n"
	end
	channel:send(output)
end

function pickWord(idx)
	local tempWords = currentGame["WordsTemp"]
	local mayor = currentGame["Mayor"]
	if tempWords == nil then
		messagePlayer(mayor, "Error: It's not time to pick a word!")
	elseif idx == "mulligan" then
		messagePlayer(mayor, "Picking new words...")
		sendWordOptions()
		return
	elseif idx == "1" or idx == "2" or idx == "3" or idx == "4" then
		currentGame["Word"] = tempWords[tonumber(idx)]
		currentGame["WordsTemp"] = nil
		messagePlayer(mayor, "The word is: " .. currentGame["Word"])
		finishNight()
	else
		messagePlayer(mayor, "Usage: !pick [1-4 or mulligan]")
	end
end

function tokenStatus()
	output = "Yes/No: " .. currentGame["BasicToken"] .. " Maybe: " .. currentGame["QuestionToken"] 
		.. " So Close: " .. currentGame["SoCloseToken"] .. " Way Off: " .. currentGame["WayOffToken"]
		.. " Seer: " .. currentGame["SeerToken"]
	messageGame(output)
end

function yes(message)
	message:delete()
	currentGame["LastQuestion"]:addReaction("✅")
	currentGame["BasicToken"] = currentGame["BasicToken"] - 1
	checkForEnd()
end

function no(message)
	message:delete()
	currentGame["LastQuestion"]:addReaction("❌")
	currentGame["BasicToken"] = currentGame["BasicToken"] - 1
	checkForEnd()
end

function what(message)
	message:delete()
	-- If there's no question toknes left, quietly inform the mayor that they fucked up and hope nobody notices!
	if currentGame["QuestionToken"] > 0 then
		currentGame["LastQuestion"]:addReaction("🤔")
		currentGame["QuestionToken"] = currentGame["QuestionToken"] - 1
	else
		messagePlayer(currentGame["Mayor"], "You have no Maybe tokens left! Answer with something else.")
	end
end

function close(message)
	message:delete()
	-- If the token is used up, substitute a yes instead
	if currentGame["SoCloseToken"] > 0 then
		currentGame["LastQuestion"]:addReaction("❕")
		currentGame["SoCloseToken"] = currentGame["SoCloseToken"] - 1
	else
		currentGame["LastQuestion"]:addReaction("✅")
		currentGame["BasicToken"] = currentGame["BasicToken"] - 1
		checkForEnd()
	end
end

function wayoff(message, target)
	message:delete()
	-- If target is nil, way off is played to the table; otherwise, it's to a specific player
	if currentGame["WayOffToken"] > 0 then
		if target == nil then
			messageGame("Y'all are way off!")
		else
			messageGame(target .. " is way off!")
		end
		currentGame["WayOffToken"] = currentGame["WayOffToken"] - 1
	else
		messagePlayer(currentGame["Mayor"], "You have already used your Way Off token!")
	end
end

function objection()
	if currentGame["SeerToken"] > 0 then
		messageGame("https://www.clipartmax.com/png/middle/5-52205_clipart-info-phoenix-wright-objection-png.png")
		currentGame["SeerToken"] = currentGame["SeerToken"] - 1
	else
		messagePlayer(currentGame["Seer"], "You have no Seer tokens left!")
	end
end

function success(message)
	-- Handle Town Win end (have Wolves guess seer/teller)
end

-- Login
client:on("ready", function()
	print("Logged in as " .. client.user.username)
	print("Loading word lists...")
	wordlists["supereasy"] = parseCSV("words/words_supereasy.csv")
	wordlists["easy"] = parseCSV("words/words_easy.csv")
	wordlists["medium"] = parseCSV("words/words_medium.csv")
	wordlists["hard"] = parseCSV("words/words_hard.csv")
	wordlists["ridiculous"] = parseCSV("words/words_ridiculous.csv")
	print("Loaded!")
end)


-- Handle new messages
client:on("messageCreate", function(message)

	local content = message.content
	local channel = message.channel
	local author = message.author
	local args = content:split(" ") -- split all arguments into a table
	-- Anytime commands
	if args[1] == "!wordlists" then
		sendWordLists(channel)
	elseif args[1] == "!mott" then
		-- Put test command here (debug info? last message etc)
		local mottisms = {
			"Oh boy homies, my buns are ready to play some Werewords! I just hope I get to be a good wolf boi! You know, I don't think "
			.. "werewolves are bad, they're just misunderstood. I mean sure, they want to eat people, but really don't we all?"
		}
		channel:send(mottisms[math.random(#mottisms)])
	elseif args[1] == "!test" then
		--print(message.content)
		--channel:send("<@!132092363098030080>")
	end
 	-- If game is running, only process ingame commands
	if currentGame["InProgress"] then
		-- Seer-only command
		if author == currentGame["Seer"] then
			-- If the command was sent in DM, process it
			-- TODO ^
			if args[1] == "!objection" then
				objection()
			end
		end
		if author ~= currentGame["Mayor"] then
			-- Save the message as the last question, in case the mayor answers it
			if channel == currentGame["GameChannel"] then
				currentGame["LastQuestion"] = message
			end
		-- Mayor-only commands
		else
			-- Pick word
			if args[1] == "!pick" then
				pickWord(args[2])
			elseif args[1] == "!yes" then
				yes(message)
			elseif args[1] == "!no" then
				no(message)
			elseif args[1] == "!what" then
				what(message)
			elseif args[1] == "!close" then
				close(message)
			elseif args[1] == "!wayoff" then
				wayoff(message, args[2])
			elseif args[1] == "!success" then
				success(message)
			end
		end
		-- Exit game
		if args[1] == "!exit" then
			if channel == currentGame["GameChannel"] then
				exitGame()
			end
		elseif args[1] == "!tokens" then
			tokenStatus()
		end
	-- If game is NOT running, only process out of game commands
	else
		-- Start game
		if args[1] == "!start" then
			local mayor = message.author
			local mode = args[2]
			local ruleset = args[3]
			local playerList = message.mentionedUsers
			createGame(mayor, mode, playerList, ruleset, message.channel)
		end
	end
end)


client:run("Bot NDgzMDk4NjU3OTE5MzM2NDU5.XQxfww.ADyJ_eU5oaITvr_xZRvTcnZcs5s") -- replace BOT_TOKEN with your bot token

--TODO:
--yes, no, what, close, wayoff, success
--have each of those call checkForEnd