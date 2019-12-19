local games = {}

--#############################################################################################################################################
--# State/Globals                                                                                                                             #
--#############################################################################################################################################

-- {Channel : {ID, Name, State}}
games.INSTANCES = {}

function games.registerGame(channel, name, state, players)
	--[[Add game to the instances table]]
	local id = math.random(10000)
	while idInUse(id) do id = math.random(10000) end
	games.INSTANCES[channel] = {id, name, state, players}
end

function games.deregisterGame(channel)
	--[[Remove game from the instances table]]
	games.INSTANCES[channel] = nil
end

function games.playerInGame(person)
	--[[Check if player exists in any game]]
	for game, info in pairs(games.INSTANCES) do
		for idx, player in pairs(info[4]) do
			if player == person then return true end
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