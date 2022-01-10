local games = {}

--#############################################################################################################################################
--# State/Globals                                                                                                                             #
--#############################################################################################################################################

-- {ID: {Channel, Name, State, Players}}
games.INSTANCES = {}

function games.registerGame(channel, name, state, players)
	--[[Add game to the instances table]]
	local id = math.random(10000)
	while idInUse(id) or (id < 1) do id = math.random(10000) end
	games.INSTANCES[id] = {channel, name, state, players}
	return id
end

function games.getGamesWithPlayer(player)
	-- This is an iterator (like pairs/ipairs)
	local function gamesWithPlayer_iter(player, gid)
		gid = next(games.INSTANCES, gid)
		return games.playerInGame(player, gid)
	end
	return gamesWithPlayer_iter, player, nil
end

function games.getGameName(id)
	return games.INSTANCES[id][2]
end

function games.getGameState(id)
	return games.INSTANCES[id][3]
end

function games.deregisterGame(id)
	--[[Remove game from the instances table]]
	games.INSTANCES[id] = nil
end

function games.playerInGame(person, id)
	--[[Check if player exists in any game, and return true if so. If id is passed, only check that game.]]
	if id == nil then
		for id, info in pairs(games.INSTANCES) do
			for idx, player in pairs(info[4]) do
				if player == person then return true end
			end
		end
		return false
	else
		local plist = games.INSTANCES[id][4]
		for idx, player in pairs(plist) do
			if player == person then return id end
		end
		return false
	end
end

function idInUse(id)
	--[[Check if the given game ID is in use]]
	return games.INSTANCES[id] ~= nil
end

function games.getState(id)
	return games.INSTANCES[id][2]
end

function games.getIDForChannel(channel)
	for id,info in pairs(games.INSTANCES) do
		if info[1] == channel then return id end
	end
	return nil
end

return games