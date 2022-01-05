local games = require("Games")
local misc = require("Misc")

local werewords = {}

local werewordsLoadWordlist, werewordsCreateGameInstance, werewordsMessageGame, werewordsMessagePlayer, werewordsGetTellerWord, werewordsAssignRoles
local werewordsSendWordOptions, werewordsFinishNight, werewordsCheckForEnd, werewordsExitGame, werewordsSendWordLists, werewordsPickWord, werewordsTokenStatus
local werewordsYes, werewordsNo, werewordsWhat, werewordsClose, werewordsWayOff, werewordsObjection, werewordsSuccess

--#############################################################################################################################################
--# Configurations                                                                                                                            #
--#############################################################################################################################################

local RULESETS = {
	W = {"Werewolf"},
	WF = {"Werewolf", "Fortune Teller"},
	WS = {"Werewolf", "Seer"},
	WSF = {"Werewolf", "Seer", "Fortune Teller"},
	WWS = {"Werewolf", "Werewolf", "Seer"},
	WWSF = {"Werewolf", "Werewolf", "Seer", "Fortune Teller"},
	["20Q"] = {}
}

local WORDLISTS = {
	"supereasy", "easy", "medium", "hard", "ridiculous"
}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function werewords.startGame(message, players)
	--[[Start a new Werewords game]]
	local args = message.content:split(" ")
	local state = werewordsCreateGameInstance()

	local playerList = {}

	for idx,playerObj in pairs(players) do playerList[playerObj.id] = playerObj end

	state["GameChannel"] = message.channel
	state["Mayor"] = message.author
	state["Mode"] = args[3]
	state["PlayerList"] = playerList
	ruleset = args[4]
	games.registerGame(message.channel, "Werewords", state, players)
	message.channel:send("Starting game...")
	-- Start game
	werewordsAssignRoles(state["PlayerList"], ruleset, state)
	werewordsSendWordOptions(state)
	message.channel:send("Roles sent out...")
end

function werewords.commandHandler(message, state)
	--[[Handle commands for a Werewords game]]
	local args = message.content:split(" ")
	local channel = message.channel
	local author = message.author

	-- Save the message as the last question, in case the mayor answers it
	if author ~= state["Mayor"] then
		state["LastQuestion"] = message
	end

	-- Anytime commands
	if args[1] == "!wordlists" then
		werewordsSendWordLists(channel)
		return
	elseif args[1] == "!end" or args[1] == "!quit" then
		werewordsExitGame(channel, state)
		return
	elseif args[1] == "!tokens" then
		werewordsTokenStatus(state)
		return
	end
	-- Mayor commands
	if author == state["Mayor"] then
		if args[1] == "!yes" then
			werewordsYes(message, state)
			return
		elseif args[1] == "!no" then
			werewordsNo(message, state)
			return
		elseif args[1] == "!what" then
			werewordsWhat(message, state)
			return
		elseif args[1] == "!close" then
			werewordsClose(message, state)
			return
		elseif args[1] == "!wayoff" then
			werewordsWayOff(message, args[2], state)
			return
		elseif args[1] == "!success" then
			werewordsSuccess(message, state)
			return
		end
	end
end

function werewords.dmHandler(message, state)
	--[[Handle commands that take place in DMs]]
	local args = message.content:split(" ")
	local author = message.author
	if author == state["Mayor"] then
		if args[1] == "!pick" then
			werewordsPickWord(state, args[2])
			return
		end
	end
	if author == state["Seer"] then
		if args[1] == "!objection" then
			werewordsObjection(state)
		end
	end		
end

--#############################################################################################################################################
--# Utility Functions                                                                                                                         #
--#############################################################################################################################################

function werewordsLoadWordlist(mode)
	local file = "words/words_" .. mode .. ".csv"
	if misc.fileExists(file) then
		return misc.parseCSV(file)
	else
		return nil
	end
end

function werewordsCreateGameInstance()
	--[[Returns a new empty game instance]]
	local instance = {
		GameChannel = nil,
		Mayor = nil,
		Seer = nil,
		Mode = nil,
		PlayerList = nil,
		Word = nil,
		WordsTemp = nil,
		BasicToken = 36,
		QuestionToken = 10,
		WayOffToken = 1,
		SoCloseToken = 1,
		SeerToken = 1,
		LastQuestion = nil
	}
	return instance
end

function werewordsMessageGame(string, state)
	state["GameChannel"]:send(string)
end

function werewordsMessagePlayer(player, string)
	player:send(string)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function werewordsGetTellerWord(str)
	--[[Takes a string and returns a version of it with each letter replaced with a dash, except the first letter of each word.]]
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


function werewordsAssignRoles(players, ruleset, state)
	--[[Assigns roles to every player in the current game
		players: a list of players, as generated by message.mentionedUsers when the command to start the game is sent
		ruleset: the string corresponding to a ruleset (eg "WSF")]]
	-- Shuffle players
	-- If ruleset doesn't exist, error
	if RULESETS[ruleset] == nil then
		werewordsMessageGame("Error! Role list does not exist.", state)
		werewordsExitGame(state["GameChannel"], state)
		return
	end
	-- Assign player roles
	local shuffledPlayers = misc.shuffleTable(misc.shallowCopy(misc.indexifyTable(players)))
	local playerList = {}
	local specialRoles = misc.shallowCopy(RULESETS[ruleset])
	for i, player in pairs(shuffledPlayers) do
		if specialRoles[i] ~= nil then
			playerList[i] = {player, specialRoles[i]}
			-- If special role is Seer, save a reference to the player
			if specialRoles[i] == "Seer" then
				state["Seer"] = player
			end
		else
			playerList[i] = {player, "Vanilla Townie"}
		end
		werewordsMessagePlayer(player, "You are: " .. playerList[i][2])
	end
	state["PlayerList"] = misc.shuffleTable(playerList)
end

function werewordsSendWordOptions(state)
	-- If word list doesn't exist, error
	-- It pains me to do this on every game startup, but it avoids me having to put a werewords-specific global in Games.lua
	local list = werewordsLoadWordlist(state["Mode"])
	if list == nil then
		werewordsMessageGame("Error! Word list does not exist.", state)
		werewordsSendWordLists(state["GameChannel"])
		werewordsExitGame(state["GameChannel"], state)
	end
	-- Pick four words at random and send them to the mayor
	local words = {list[math.random(#list)],list[math.random(#list)],list[math.random(#list)],list[math.random(#list)]}
	output = "Your word choices are:\n1: " .. words[1] .. "\n2: " .. words[2] .. "\n3: " .. words[3] .. "\n4: " .. words[4]
	state["WordsTemp"] = words
	werewordsMessagePlayer(state["Mayor"], output)
end

--##########################
--######## ADD ROLES HERE ##
--##########################
function werewordsFinishNight(state)
	for idx,playerInfo in pairs(state["PlayerList"]) do
		local player = playerInfo[1]
		-- WEREWOLF:
		if playerInfo[2] == "Werewolf" then
			-- Inform of word
			werewordsMessagePlayer(player, "The word is: " .. state["Word"])
			-- Inform of all other werewolves
			for idx2,playerInfo2 in pairs(state["PlayerList"]) do
				if idx ~= idx2 and playerInfo2[2] == "Werewolf" then
					werewordsMessagePlayer(player, playerInfo2[1].name .. " is a werewolf!")
				end
			end
		-- SEER:
		elseif playerInfo[2] == "Seer" then
			werewordsMessagePlayer(player, "The word is: " .. state["Word"])
		-- APPRENTICE:
		elseif playerInfo[2] == "Fortune Teller" then
			local censoredWord = werewordsGetTellerWord(state["Word"])
			werewordsMessagePlayer(player, "The word is: " .. censoredWord)
		end
	end
	werewordsMessageGame("The game has begun!", state)
end

function werewordsCheckForEnd()
	-- Check for Wolf Win end and if it's the case, have Town vote on wolves
end

--#############################################################################################################################################
--# Commands                                                                                                                                  #
--#############################################################################################################################################

function werewordsExitGame(channel, state)
	werewordsMessageGame("Quitting game...", state)
	games.deregisterGame(channel)

end

function werewordsSendWordLists(channel)
	local output = "Currently available wordlists:\n"
	for idx,name in pairs(WORDLISTS) do
		output = output .. name .. "\n"
	end
	channel:send(output)
end

function werewordsPickWord(state, idx)
	local tempWords = state["WordsTemp"]
	local mayor = state["Mayor"]
	if tempWords == nil then
		werewordsMessagePlayer(mayor, "Error: It's not time to pick a word!")
	elseif idx == "mulligan" then
		werewordsMessagePlayer(mayor, "Picking new words...")
		werewordsSendWordOptions()
		return
	elseif idx == "1" or idx == "2" or idx == "3" or idx == "4" then
		state["Word"] = tempWords[tonumber(idx)]
		state["WordsTemp"] = nil
		werewordsMessagePlayer(mayor, "The word is: " .. state["Word"])
		werewordsFinishNight(state)
	else
		werewordsMessagePlayer(mayor, "Usage: !pick [1-4 or mulligan]")
	end
end

function werewordsTokenStatus(state)
	output = "Yes/No: " .. state["BasicToken"] .. " Maybe: " .. state["QuestionToken"] 
		.. " So Close: " .. state["SoCloseToken"] .. " Way Off: " .. state["WayOffToken"]
		.. " Seer: " .. state["SeerToken"]
	werewordsMessageGame(output, state)
end

function werewordsYes(message, state)
	message:delete()
	state["LastQuestion"]:addReaction("✅") --%E2%9C%85
	state["BasicToken"] = state["BasicToken"] - 1
	werewordsCheckForEnd()
end

function werewordsNo(message, state)
	message:delete()
	state["LastQuestion"]:addReaction("❌") --%E2%9D%8C
	state["BasicToken"] = state["BasicToken"] - 1
	werewordsCheckForEnd()
end

function werewordsWhat(message, state)
	message:delete()
	-- If there's no question toknes left, quietly inform the mayor that they fucked up and hope nobody notices!
	if state["QuestionToken"] > 0 then
		state["LastQuestion"]:addReaction("🤔") --%F0%9F%A4%94
		state["QuestionToken"] = state["QuestionToken"] - 1
	else
		werewordsMessagePlayer(state["Mayor"], "You have no Maybe tokens left! Answer with something else.")
	end
end

function werewordsClose(message, state)
	message:delete()
	-- If the token is used up, substitute a werewordsYes instead
	if state["SoCloseToken"] > 0 then
		state["LastQuestion"]:addReaction("❕") --%E2%9D%95
		state["SoCloseToken"] = state["SoCloseToken"] - 1
	else
		state["LastQuestion"]:addReaction("✅") --%E2%9C%85
		state["BasicToken"] = state["BasicToken"] - 1
		werewordsCheckForEnd()
	end
end

function werewordsWayOff(message, target, state)
	message:delete()
	-- If target is nil, way off is played to the table; otherwise, it's to a specific player
	if state["WayOffToken"] > 0 then
		if target == nil then
			werewordsMessageGame("Y'all are way off!", state)
		else
			werewordsMessageGame(target .. " is way off!", state)
		end
		state["WayOffToken"] = state["WayOffToken"] - 1
	else
		werewordsMessagePlayer(state["Mayor"], "You have already used your Way Off token!")
	end
end

function werewordsObjection(state)
	if state["SeerToken"] > 0 then
		werewordsMessageGame("https://www.clipartmax.com/png/middle/5-52205_clipart-info-phoenix-wright-objection-png.png", state)
		state["SeerToken"] = state["SeerToken"] - 1
	else
		werewordsMessagePlayer(state["Seer"], "You have no Seer tokens left!")
	end
end

function werewordsSuccess(message, state)
	-- Handle Town Win end (have Wolves guess seer/teller)
end

return werewords