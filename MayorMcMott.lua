local discordia = require("discordia")
local fs = require("fs")
local games = require("Games")
local misc = require("Misc")
local client = discordia.Client()

discordia.extensions()

--#############################################################################################################################################
--#############################################################################################################################################
--####                                                              READ ME:                                                              #####
--####                                                  IF YOU'RE TRYING TO ADD NEW GAMES                                                 #####
--####                                                  YOU DO NOT NEED TO EDIT THIS FILE                                                 #####
--#############################################################################################################################################
--#############################################################################################################################################

--#############################################################################################################################################
--# Globals                                                                                                                                   #
--#############################################################################################################################################

LOG_MOTTBOT_MESSAGES = true

local currentGhostChannel = nil
local currentGhostFriend = nil

GAME_LIST = {}

--#############################################################################################################################################
--# Initialization                                                                                                                            #
--#############################################################################################################################################

function init()
	--[[Called when the bot initializes]]
	GAME_LIST = {}
	if games.INSTANCES ~= nil then
		for channel,info in pairs(games.INSTANCES) do
			games.deregisterGame(channel)
		end
	end

	local i = 0
	for filename,filetype in fs.scandirSync("plugins") do
		if filetype == "file" then
			if filename:sub(-4) == ".lua" then
				local gamename = filename:sub(1,-5)
				GAME_LIST[gamename] = dofile("plugins/" .. gamename .. ".lua") -- Using dofile instead of require to allow reloading after changes
				i = i + 1
			end
		end
	end
	print("Loaded " .. i .. " plugins!")
end

--#############################################################################################################################################
--# Command Handlers                                                                                                                          #
--#############################################################################################################################################

function gameCommands(message)
	--[[Called on new messages]]
	local content = message.content
	local channel = message.channel
	local author = message.author
	local args = content:split(" ")

	if misc.keyInTable(channel, games.INSTANCES) and (GAME_LIST[gameType].commandHandler ~= nil) then -- Channel has game already
		-- Run game-specific functions
		local gameType = games.INSTANCES[channel][2]
		local state = games.INSTANCES[channel][3]
		local stat, err, ret = xpcall(GAME_LIST[gameType].commandHandler, debug.traceback, message, state)
		if not stat then
			-- Game crashed
			print(tostring(nameOfGame) .. " crashed on public command") --TODO: Add id to output
			print(err)
			games.deregisterGame(channel)
		end
	elseif games.playerInGame(author) then -- User is in a game, call relevant handlers
		-- Check every game to see if the player is playing, and call the relevant event handler for that game
		for gamechannel, game in pairs(games.INSTANCES) do
			for idx, player in pairs(game[4]) do
				if author == player then
					if GAME_LIST[game[2]].dmHandler ~= nil then
						local stat, err, ret = xpcall(GAME_LIST[game[2]].dmHandler, debug.traceback, message, game[3])
						if not stat then
							-- Game crashed
							print(tostring(nameOfGame) .. " id " .. game[1] .. " crashed on DM command")
							print(err)
							games.deregisterGame(gamechannel)
						end
					end
				end
			end
		end
	else -- Channel does not have game already
		if message.channel.type ~= 1 and (args[1] == "!start" or args[1] == "!vc" or args[1] == "!vcr") and args[2] ~= nil then -- Don't allow game starting in DMs!
			local nameOfGame = misc.getKeyInTableInsensitive(args[2], GAME_LIST)
			if nameOfGame then
				-- Get the channel and a list of Users who will be playing
				local playerList = {}
				table.insert(playerList, message.author)
				-- What we do here will depend on how the command was called...
				if (args[1] == "!vc") or (args[1] == "!vcr") then
					-- Get the channel
					local vcchannel = nil
					for idx,voicechannel in pairs(message.guild.voiceChannels) do
						for id,user in pairs(voicechannel.connectedMembers) do
							if user.id == message.author.id then
								vcchannel = voicechannel
								goto vc_found
							end
						end
					end
					::vc_found::
					if vcchannel == nil then return end
					-- Get the User list
					for key,val in pairs(vcchannel.connectedMembers) do
						-- Skip users that are already in the table (eg message author who @ed themselves)
						if not misc.valueInList(val.user, playerList) then table.insert(playerList, val.user) end
					end
				elseif args[1] == "!start" then
					for key,val in pairs(message.mentionedUsers) do
						-- Skip users that are already in the table (eg message author who @ed themselves)
						if not misc.valueInList(val, playerList) then table.insert(playerList, val) end
					end
				end

				-- Randomize player order for !vcr only
				if args[1] == "!vcr" then misc.shuffleTable(playerList) end

				-- Call the function associated with the given game
				local stat, err, ret = xpcall(GAME_LIST[nameOfGame].startGame, debug.traceback, message, playerList)
				if not stat then
					-- Game crashed on startup
					print(tostring(nameOfGame) .. " crashed on startup") --TODO: Add id to output
					print(err)
					games.deregisterGame(channel)
				end
			else
				channel:send("Uh-oh! I don't know how to play that game, homie!")
			end
		end
	end
end

function reactionCommands(channel, reaction, user)
	if games.playerInGame(user) then -- User is in a game, call relevant handlers
		-- Check every game to see if the player is playing, and call the relevant event handler for that game
		for channel, game in pairs(games.INSTANCES) do
			-- Don't bother if the game doesn't have a reactHandler command
			if GAME_LIST[game[2]].reactHandler ~= nil then
				for idx, player in pairs(game[4]) do
					if user == player then
						local stat, err, ret = xpcall(GAME_LIST[game[2]].reactHandler, debug.traceback, reaction, user, game[3])
						if not stat then
							-- Game crashed
							print(tostring(nameOfGame) .. " id " .. game[1] .. " crashed on reaction")
							print(err)
							games.deregisterGame(channel)
						end
					end
				end
			end
		end
	end
end

function miscCommands(message)
	--[[Miscellaneous functionality goes here]]
	args = message.content:split(" ")
	if args[1] == "!hiddenharry" then
		local order = misc.shuffleTable(misc.indexifyTable(misc.shallowCopy(message.mentionedUsers)))
		for idx, user in pairs(order) do
			if idx == #order then
				order[idx]:send("You're giving a Hidden Hannukah Harry gift to: " .. order[1][10])
			else
				order[idx]:send("You're giving a Hidden Hannukah Harry gift to: " .. order[idx+1][10])
			end
		end
	elseif args[1] == "!vcc" then
		local vcchannel = nil
		for idx,voicechannel in pairs(message.guild.voiceChannels) do
			for id,user in pairs(voicechannel.connectedMembers) do
				if user.id == message.author.id then
					vcchannel = voicechannel
					goto vcc_found
				end
			end
		end
		::vcc_found::
		if vcchannel == nil then
			message.channel:send("You're not in a call. So uh, I choose you, homie!")
		else
			local u = misc.getRandomIndex(vcchannel.connectedMembers)
			message.channel:send("<@!" .. u .. ">, you're it!")
		end
	elseif args[1] == "!reload" then
		if args[2] ~= nil then
			if misc.getKeyInTableInsensitive(args[2], GAME_LIST) then
				-- Remove all loaded code relating to this game
				local gamename = misc.getKeyInTableInsensitive(args[2], GAME_LIST)
				GAME_LIST[gamename] = nil
				for channel,info in pairs(games.INSTANCES) do
					if info[2] == gamename then
						games.deregisterGame(channel)
					end
				end
				-- Reload the game
				GAME_LIST[gamename] = dofile("plugins/" .. gamename .. ".lua")
				message.channel:send("Reloaded " .. gamename)
			elseif args[2]:lower() == "all" then
				init()
				message.channel:send("Reloaded all plugins")
			end
		else
			message.channel:send("Do !reload [game] to reload one game, or !reload all to reload all plugins!")
		end
	end
	if string.match(message.content, "( ͡° ͜ʖ ͡°)") then
		if string.match(string.lower(message.content), "fast") then
			message.channel:send("( ͡° ͜ʖ ͡°)")
		end
	end
	if message.mentionsEveryone then
		local warning = "DON'T SHAKE THE BABY"
		if message.author.name == "Smogilski" then
			warning = warning .. ", SHAYNE!!!"
		end
		message.channel:send(warning)
	end
end

function logDMs(content, channel, author, args)
	--[[Logs private messages to console (messages from MottBot can be excluded, optionally)]]
	if channel.type == 1 then
		if args[1] ~= "!echo" and args[1] ~= "!setchannel" then
			if author.name ~= "MottBot" or LOG_MOTTBOT_MESSAGES == true then
				print(author.name .. ": " .. content)
			end
		end
	end
end

function echoCommands(content, channel, author, args)
	--[[Handles !setchannel and !echo]]
	if args[1] == "!setchannel" then
		local id = args[2]
		currentGhostChannel = client:getChannel(id)
		if currentGhostChannel == nil then
			local user = client:getUser(id)
			currentGhostChannel = user:getPrivateChannel()
			currentGhostFriend = user.name
		else
			currentGhostFriend = nil
		end
		print(currentGhostChannel)
		print(args[2])
	elseif args[1] == "!echo" then
		--print(message.content)
		--channel:send("<@!132092363098030080>")
		local message = ""
		for i, word in pairs(args) do
			if i == 2 then message = word end
			if i > 2 then message = message .. " " .. word end
		end
		if currentGhostChannel ~= nil then currentGhostChannel:send(message) else print("Error: nil channel") end
		if currentGhostFriend ~= nil then print("To: " .. currentGhostFriend .. ": " .. message) end
	end
end

function infoCommands(content, channel, author, args)
	--[[Informational functions]]
	if args[1] == "!games" then -- Print the list of games the bot can run
		local output = ""
		for key,value in pairs(GAME_LIST) do
			if value.desc ~= "TODO" then
				output = output .. key .. ", "
			end
		end
		output = output:sub(1,-3)
		channel:send(output)
	elseif args[1] == "!list" then -- Print a list of currently running games
		local noGames = true -- lua's table size operator is notoriously useless
		local output = ""
		for key,value in pairs(games.INSTANCES) do
			noGames = false
			local game = value[1] .. ": " .. value[2]
			output = output .. game .. "\n"
		end
		if noGames then channel:send("No games currently running.") else channel:send(output) end
	elseif args[1] == "!info" then -- Print info about a specific game
		for key,value in pairs(GAME_LIST) do
			if args[2]:lower() == key:lower() then
				local msg = value["desc"] .. "\nRules: <" .. value["rules"] .. ">"
				channel:send(msg)
			end
		end
	end
end

--#############################################################################################################################################
--# Bot Functions                                                                                                                             #
--#############################################################################################################################################

-- Login
client:on("ready", function()
	print("Logged in as " .. client.user.username)
	init()
end)


-- Handle new messages
client:on("messageCreate", function(message)

	local content = message.content
	local channel = message.channel
	local author = message.author
	local args = content:split(" ") -- split all arguments into a table

	logDMs(content, channel, author, args)
	echoCommands(content, channel, author, args)
	infoCommands(content, channel, author, args)
	gameCommands(message) -- Send the entire message, as some games might need additional information (eg mentionedUsers, reactions)
	miscCommands(message)
end)

-- Handle reacts too
client:on("reactionAdd", function(reaction, userId)

	local channel = reaction.message.channel
	local user = reaction.client._users:get(userId)

	reactionCommands(channel, reaction, user)
end)

function getBotString()
	for line in io.lines("BOT_TOKEN") do return "Bot " .. line end
end

if pcall(getBotString) then
	client:run(getBotString())
else
	print("To run MottBot, create a file named BOT_TOKEN and put your bot token in it!")
end
