local discordia = require("discordia")
local fs = require("fs")
local games = require("Games")
local misc = require("Misc")
local client = discordia.Client()
require("discordia-components")

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

-- Settings
LOG_MOTTBOT_MESSAGES = true  -- If true, all messages in the bot's DMs will be printed to console.
ECHO_ALLOWED_USERS = nil     -- List of allowed users for !setchannel and !echo. Leave nil to allow anyone to use them.
DEBUG_ALLOWED_USERS = nil    -- List of allowed users for !reload and !debug. Leave nil to allow anyone to use them.

-- You don't need to touch these, they're set by the bot automatically when appropriate
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
		for id,info in pairs(games.INSTANCES) do
			games.deregisterGame(id)
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
	-- We need to initialize this function here, because Misc.lua can't load discordia for some reason
	misc.createMutex = discordia.Mutex
	misc.createButton = discordia.Button
	misc.createComponents = discordia.Components
end

--#############################################################################################################################################
--# Command Handlers                                                                                                                          #
--#############################################################################################################################################

function safeCallHandler(gameName, gameid, handler, args, handlerType)
	-- If the handler is a start game handler, arg2 is player list; otherwise it's state
	local stat, result = xpcall(handler, debug.traceback, unpack(args))
	if not stat then
		-- Game crashed
		print("#=======================================#\n")
		print(tostring(gameName) .. " (id " .. tostring(gameid) .. ") crashed:")
		-- Print information about the crash
		if handlerType == "start" then
			print("Message: " .. tostring(args[1].content))
			print("Author: " .. tostring(args[1].author.name)  .. " ID:" .. tostring(args[1].author.id))
			print("PlayerList:")
			if type(args[2] == "table") then
				misc.printTable(args[2])
			else
				print(tostring(args[2]))
			end
		elseif handlerType == "message" then
			print("Message: " .. tostring(args[1].content))
			print("Author: " .. tostring(args[1].author.name)  .. " ID:" .. tostring(args[1].author.id))
			print("State:")
			if type(args[2] == "table") then
				misc.printTable(args[2])
			else
				print(tostring(args[2]))
			end
		elseif handlerType == "react" then
			print("Reaction: " .. tostring(args[1].emojiName))
			print("User: " .. tostring(args[2].name) .. " ID:" .. tostring(args[2].id))
			print("State: \n")
			if type(args[3] == "table") then
				misc.printTable(args[3])
			else
				print(tostring(args[3]))
			end
		elseif handlerType == "interact" then
			print("Interaction: " .. tostring(args[1]))
			print("User: " .. tostring(args[2].name) .. " ID: " ..tostring(args[2].id))
			print("State: \n")
			if type(args[4] == "table") then
				misc.printTable(args[4])
			else
				print(tostring(args[4]))
			end
		else
			print("Unknown handler type: " .. tostring(handlerType))
			print("args:")
			if type(args) == "table" then 
				misc.printTable(args)
			else
				print(tostring(args))
			end
		end
		-- Print traceback
		print("")
		print(result)
		if gameid ~= nil then
			games.deregisterGame(gameid)
		else
			gameid = games.getIDForChannel(args[1]) -- If there's no gameid, we were starting a game
			if gameid ~= nil then games.deregisterGame(gameid) end
		end
	end
end

function gameCommands(message)
	local content = message.content
	local channel = message.channel
	local author = message.author
	local authorvc = nil
	local gameName = nil
	local gameid = games.getIDForChannel(channel)
	local args = content:split(" ")

	if (args[1] == "!start") or (args[1] == "!vc") or (args[1] == "!vcr") then -- Are we trying to start a new game?
		-- args[2] should be the game name; if it's nonexistant or invalid, that's an error
		if #args == 1 then 
			channel:send("You need to tell me what game you want to play, homie...")
			return
		end
		gameName = misc.getKeyInTableInsensitive(args[2], GAME_LIST)
		if gameName == nil then
			channel:send("Uh-oh! I don't know how to play that game, homie!")
			return
		end
		-- Don't start a new game if there's already a new game in this channel
		if gameid ~= nil then
			channel:send("This channel already has a game in it, homie!")
			return
		end
		-- Only some games can be started in DM, and some must be started with !vc/!vcr
		if (channel.type == 1) and (GAME_LIST[gameName]["startInDMs"] == nil) then
			channel:send("That game can't be started in DMs, homie. But what's up? Wait wait, I know -- *the skyyyyy*. :point_right::sunglasses::point_right:")
			return
		elseif (channel.type == 1) and (GAME_LIST[gameName]["startInDMs"] == "vcOnly") and (args[1] == "!start") then
			channel:send("You have to be in a voice channel to start this game in DMs, homie. Otherwise you'd just be playing by yourself :sob:")
			return
		end
		-- Don't allow !vc/!vcr if the message author isn't in a voice channel
		if ((args[1] == "!vc") or (args[1] == "!vcr")) then
			for gid,guild in pairs(author.mutualGuilds) do
				authorvc = guild:getMember(author.id).voiceChannel
				if authorvc ~= nil then break end
			end
			if authorvc == nil then
				channel:send("You have to be in a voice channel to use !vc or !vcr, homie! (It would help if I was in the server whose call you're in, too...)")
				return
			end
		end
		--TODO: Should we allow one player to be in multiple games?
		-- If we've made it to this point, we're all good to start the game
		-- First, we get the player list for the game
		local playerList = {}
		table.insert(playerList, message.author)
		if args[1] == "!start" then
			for key,val in pairs(message.mentionedUsers) do
				-- Skip users that are already in the table (eg message author who @ed themselves)
				if not misc.valueInList(val, playerList) then table.insert(playerList, val) end
			end
		else -- !vc/!vcr
			for key,val in pairs(authorvc.connectedMembers) do
				-- Skip users that are already in the table (eg message author who @ed themselves)
				if not misc.valueInList(val.user, playerList) then table.insert(playerList, val.user) end
			end
		end
		-- Randomize player order for !vcr only
		if args[1] == "!vcr" then misc.shuffleTable(playerList) end
		-- Start the game
		safeCallHandler(gameName, nil, GAME_LIST[gameName].startGame, {message, playerList}, "start")
	else -- This message wasn't trying to start a game, so maybe it's in the middle of one!
		if games.playerInGame(author) then
			-- If this is the game channel, run the command handler for that game
			if gameid ~= nil and GAME_LIST[games.getGameName(gameid)].commandHandler ~= nil then
				gameName = games.getGameName(gameid)
				local state = games.getGameState(gameid)
				safeCallHandler(gameName, gameid, GAME_LIST[gameName].commandHandler, {message, state}, "message")
			end
			-- If this is a DM, run the DM handler for any games they're in
			if channel.type == 1 then
				-- Loop over all games that this player is in
				for player,gameid in games.getGamesWithPlayer(author) do
					gameName = games.getGameName(gameid)
					if gameName ~= nil then
						if GAME_LIST[gameName].dmHandler ~= nil then
							local state = games.getGameState(gameid)
							safeCallHandler(gameName, gameid, GAME_LIST[gameName].dmHandler, {message, state}, "message")
						end
					end
				end
			end
		end
	end
end

function reactionCommands(channel, reaction, user, isAdding)
	if games.playerInGame(user) then -- User is in a game, call relevant handlers
		-- Check every game the player is playing, and call the relevant event handler for that game, if it has one
		for gameid, game in games.getGamesWithPlayer(user) do
			local gameName = games.getGameName(gameid)
			local state = games.getGameState(gameid)
			-- Don't bother if the game doesn't have a reactHandler command
			if GAME_LIST[gameName].reactHandler ~= nil then
				safeCallHandler(gameName, gameid, GAME_LIST[gameName].reactHandler, {reaction, user, state, isAdding}, "react")
			end
		end
	end
end

function interactionCommands(channel, interId, user, interaction)
	if games.playerInGame(user) then
		for gameid, game in games.getGamesWithPlayer(user) do
			local gameName = games.getGameName(gameid)
			local state = games.getGameState(gameid)
			if GAME_LIST[gameName].buttonHandler ~= nil then
				safeCallHandler(gameName, gameid, GAME_LIST[gameName].buttonHandler, {interId, user, channel, state, interaction}, "interact")
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
		-- Check if we're allowed to do this
		if DEBUG_ALLOWED_USERS ~= nil then
			if not misc.valueInList(message.author.id, DEBUG_ALLOWED_USERS) then
				message.channel:send("YOU DON'T HAVE ENOUGH BADGES TO TRAIN ME!")
				return
			end
		end

		if args[2] ~= nil then
			if misc.getKeyInTableInsensitive(args[2], GAME_LIST) then
				-- Reload the game
				local gamename = misc.getKeyInTableInsensitive(args[2], GAME_LIST)
				local stat, result = xpcall(dofile, debug.traceback, "plugins/" .. gamename .. ".lua")
				if not stat then
					print(result)
					message.channel:send("Reload failed; see console for details")
				else
					-- Remove all loaded code relating to this game, and force-end all copies of the game
					-- We only do this when we can successfully reload, otherwise we end up with no copy of the game loaded
					GAME_LIST[gamename] = nil
					for gid,info in pairs(games.INSTANCES) do
						if info[2] == gamename then
							games.deregisterGame(gid)
						end
					end
					-- Replace the game code with the new code
					GAME_LIST[gamename] = result
					message.channel:send("Successfully reloaded " .. gamename)
				end
			elseif args[2]:lower() == "all" then
				init()
				message.channel:send("Reloaded all plugins")
			end
		else
			message.channel:send("Do !reload [game] to reload one game, or !reload all to reload all plugins!")
		end
	elseif args[1] == "!debug" then
		-- Check if we're allowed to do this
		if DEBUG_ALLOWED_USERS ~= nil then
			if not misc.valueInList(message.author.id, DEBUG_ALLOWED_USERS) then
				message.channel:send("YOU DON'T HAVE ENOUGH BADGES TO TRAIN ME!")
				return
			end
		end

		local stat, result = xpcall(dofile("Debug.lua"), debug.traceback, message)
		if not stat then
			print("Debug crashed")
			print(result)
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
	-- Check if we're allowed to do this
	if ECHO_ALLOWED_USERS ~= nil then
		if not misc.valueInList(author.id, ECHO_ALLOWED_USERS) then
			return
		end
	end

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
		for id,gameinfo in pairs(games.INSTANCES) do
			noGames = false
			local game = id .. ": " .. games.getGameName(id)
			output = output .. game .. "\n"
		end
		if noGames then channel:send("No games currently running.") else channel:send(output) end
	elseif args[1] == "!info" then -- Print info about a specific game
		if args[2] == nil then channel:send("What game do you want info for?"); return end
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
	gameCommands(message)
	miscCommands(message)
end)

-- Handle reacts too
client:on("reactionAdd", function(reaction, userId)

	local channel = reaction.message.channel
	local user = reaction.client._users:get(userId)

	reactionCommands(channel, reaction, user, true)
end)

client:on("reactionRemove", function(reaction, userId)

	local channel = reaction.message.channel
	local user = reaction.client._users:get(userId)

	reactionCommands(channel, reaction, user, false)
end)

client:on("interactionCreate", function(interaction)

	local channel = interaction.channel
	local userId = interaction.user
	local interId = interaction.data.custom_id

	interactionCommands(channel, interId, userId, interaction)
end)

function getBotString()
	for line in io.lines("BOT_TOKEN") do return "Bot " .. line end
end

if pcall(getBotString) then
	client:run(getBotString())
else
	print("To run MottBot, create a file named BOT_TOKEN and put your bot token in it!")
end
