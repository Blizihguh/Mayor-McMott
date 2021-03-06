local games = require("Games")
local misc = require("Misc")
local twopeople = {}

local doReveal, pickArticle

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function twopeople.startGame(message)
	local state = {
		PlayerList = {},
		GameChannel = message.channel,
		TomScott = message.author
	}
	for id,user in pairs(message.mentionedUsers) do
		if state.TomScott.id ~= id then
			state.PlayerList[id] = {user, nil} -- idx = {user object, their article}
		end
	end
	message.channel:send("Started the game with " .. state.TomScott.name .. " as the Judge! Everybody else, DM me your article with the !pick command!")
	games.registerGame(message.channel, "Trickipedia", state, message.mentionedUsers)
end

function twopeople.commandHandler(message, state)
	local arg = message.content:split(" ")[1]
	if arg == "!reveal" then
		doReveal(state)
	elseif arg == "!quit" then
		quitGame(state)
	end
end

function twopeople.dmHandler(message, state)
	if message.content:split(" ")[1] == "!pick" then
		pickArticle(state, message)
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function quitGame(state)
	state.GameChannel:send("Exiting game.")
	games.deregisterGame(state.GameChannel)
end

function pickArticle(state, message)
	if message.author.id ~= state.TomScott.id then
		state.PlayerList[message.author.id][2] = string.sub(message.content, 7)
		message.author:send("Chosen article: " .. state.PlayerList[message.author.id][2])
	end
end

function doReveal(state)
	-- Check if everyone has submitted an article
	local done = true
	for id,dt in pairs(state.PlayerList) do
		if dt[2] == nil then
			done = false
			break
		end
	end
	-- Advance game if everyone is done submitting
	if done then
		-- Pick a random article
		local chosen = misc.getRandomIndex(state.PlayerList)
		state.GameChannel:send("The article is: " .. string.upper(state.PlayerList[chosen][2]))
		games.deregisterGame(state.GameChannel)
	else
		state.GameChannel:send("Someone hasn't submitted an article yet!")
	end
end

return twopeople