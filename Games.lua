local games = {}

--#############################################################################################################################################
--# State/Globals                                                                                                                             #
--#############################################################################################################################################

-- {Channel : {ID, Name, State, Players}}
games.INSTANCES = {}

function games.registerGame(channel, name, state, players)
	--[[Add game to the instances table]]
	local id = math.random(10000)
	while idInUse(id) or (id < 1) do id = math.random(10000) end
	games.INSTANCES[channel] = {id, name, state, players}
end

function games.deregisterGame(channel)
	--[[Remove game from the instances table]]
	games.INSTANCES[channel] = nil
end

function games.deregisterByID(id)
	--[[Remove game from the instances table by game id]]
	for channel, game in pairs(games.INSTANCES) do
		if game[1] == id then 
			games.INSTANCES[channel] = nil
			return true
		else
			return false
		end
	end
end

function games.playerInGame(person)
	--[[Check if player exists in any game, and return the game id if so]]
	for game, info in pairs(games.INSTANCES) do
		for idx, player in pairs(info[4]) do
			if player == person then return info[1] end
		end
	end
	return false
end

function idInUse(id)
	--[[Check if the given game ID is in use]]
	for game, info in pairs(games.INSTANCES) do
		if info[1] == id then return true end
	end
	return false
end

function games.getState(channel)
	return games.INSTANCES[channel][2]
end

return games