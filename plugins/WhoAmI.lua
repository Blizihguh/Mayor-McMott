local games = require("Games")
local misc = require("Misc")

local whoami = {}
whoami.desc = "TODO"
whoami.rules = "TODO"
whoami.startInDMs = "vcOnly"

local quitGame, setupPlayers, getCategories, setupCounters, pickCharacter, handleRejection, confirmPick, playerFinished, playerResigned

-- Uncomment this if you want to import server-specific data
-- local SERVER_LIST = {}
-- if misc.fileExists("plugins/server-specific/whoami-SP.lua") then
-- 	SERVER_LIST = require("plugins/server-specific/whoami-SP")
-- end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function whoami.startGame(message, playerList)
	local args = message.content:split(" ")

	local state = {
		GameChannel = message.channel,
		PlayerList = {}
	}
	
	setupPlayers(state, playerList)
	getCategories(state)

	state.GameID = games.registerGame(message.channel, "WhoAmI", state, playerList)
end

function whoami.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state) end
end

function whoami.dmHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then quitGame(state)
	elseif args[1] == "!pick" then pickCharacter(state, message) 
	elseif args[1] == "!success" then playerFinished(state, message.author) 
	elseif args[1] == "!failure" then playerResigned(state, message.author) end
end

function whoami.buttonHandler(interId, user, channel, state, interaction)
	if interId == "counter_up" then
		state.PlayerList[user.id].Counter = state.PlayerList[user.id].Counter + 1
		interaction:update("Counter: " .. tostring(state.PlayerList[user.id].Counter))
	elseif interId == "counter_down" then
		state.PlayerList[user.id].Counter = state.PlayerList[user.id].Counter - 1
		interaction:update("Counter: " .. tostring(state.PlayerList[user.id].Counter))
	elseif interId == "reject" then
		handleRejection(state, user)
	elseif interId == "confirm" then
		confirmPick(state, user)
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function playerFinished(state, user)
	local player = state.PlayerList[user.id]
	player.StatusMsg:setComponents(nil)
	player.Finished = true
	for id,otherPlayer in pairs(state.PlayerList) do
		otherPlayer.PlayerObj:send(player.Name .. " guessed their character in " .. tostring(player.Counter) .. " questions! (" .. player.Character .. ")")
	end
	-- Check if everyone is finished
	for id,thisPlayer in pairs(state.PlayerList) do
		if not thisPlayer.Finished then return end
	end
	-- If we get to this point, everyone is finished
	quitGame(state)
end

function playerFinished(state, user)
	local player = state.PlayerList[user.id]
	player.StatusMsg:setComponents(nil)
	player.Finished = true
	for id,otherPlayer in pairs(state.PlayerList) do
		otherPlayer.PlayerObj:send(player.Name .. " gave up guessing their character after " .. tostring(player.Counter) .. " questions... (" .. player.Character .. ")")
	end
	-- Check if everyone is finished
	for id,thisPlayer in pairs(state.PlayerList) do
		if not thisPlayer.Finished then return end
	end
	-- If we get to this point, everyone is finished
	quitGame(state)
end

function handleRejection(state, user)
	local player = state.PlayerList[user.id]
	local targetPlayer = state.PlayerList[player.GivingTo]
	targetPlayer.Character = nil
	player.StatusMsg:update("You are giving a character to " .. targetPlayer.Name .. "!")
	player.StatusMsg:setComponents(nil)
end

function confirmPick(state, user)
	local player = state.PlayerList[user.id]
	local targetPlayer = state.PlayerList[player.GivingTo]
	targetPlayer.Confirmed = true
	--player.StatusMsg:update(player.StatusMsg.content) -- Send an empty update to remove the "interaction failed" message
	player.StatusMsg:setComponents(nil)
	-- Check if everyone is confirmed
	for id,player in pairs(state.PlayerList) do
		if not player.Confirmed then return end
	end
	-- If we get to this point, everyone is confirmed
	setupCounters(state)
end

function pickCharacter(state, message)
	local player = state.PlayerList[message.author.id]
	local targetPlayer = state.PlayerList[player.GivingTo]
	local character = message.content:sub(7)
	local components = misc.createComponents {
		misc.createButton { id = "reject", emoji = "✖️", style = "primary" },
		misc.createButton { id = "confirm", emoji = "✔️", style = "primary" }
	}
	-- Update info
	targetPlayer.Character = character
	player.StatusMsg:setContent("You've given \"" .. character .. "\" to " .. targetPlayer.Name .. "!")
	player.StatusMsg:setComponents(components)
	-- Tell everyone
	for id,otherPlayer in pairs(state.PlayerList) do
		if id ~= message.author.id and id ~= player.GivingTo then
			otherPlayer.PlayerObj:send(player.Name .. " has given \"" .. character .. "\" to " .. targetPlayer.Name .. "!")
		end
	end
end

function getCategories(state)
	-- Randomize player order
	local players = misc.indexifyTable(state.PlayerList)
	--misc.shuffleTable(players)
	-- Tell each player to pick a character
	for idx,player in pairs(players) do
		-- Get next player
		local nextPlayer = players[idx+1]
		if nextPlayer == nil then nextPlayer = players[1] end
		-- Assign the association info
		nextPlayer.GivenBy = player.PlayerObj.id
		player.GivingTo = nextPlayer.PlayerObj.id
		-- Tell the player to make an assignment
		player.StatusMsg:setContent("You are giving a character to " .. nextPlayer.Name .. "!")
	end
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	for id,player in pairs(state.PlayerList) do
		player.StatusMsg:setComponents(nil)
	end
	games.deregisterGame(state.GameID)	
end

function setupCounters(state)
	for id,player in pairs(state.PlayerList) do
		local components = misc.createComponents {
			misc.createButton { id = "counter_down", emoji = "➖", style = "primary" },
			misc.createButton { id = "counter_up", emoji = "➕", style = "primary" },
		}
		player.StatusMsg:setContent("Counter: 0")
		player.StatusMsg:setComponents(components)
	end
end

function setupPlayers(state, playerList)
	local players = {}
	for idx, player in pairs(playerList) do
		players[player.id] = { Name = player.name, StatusMsg = nil, StatusMsg2 = nil, Counter = 0, PlayerObj = player, Character = nil, Confirmed = false, GivenBy = nil, GivingTo = nil, Finished = false }


		players[player.id].StatusMsg = player:send("...")
	end
	state.PlayerList = players
end

return whoami