local games = require("Games")
local misc = require("Misc")
local dreamcrush = {}
dreamcrush.desc = "Look into your heart and choose your favorite Crush, then guess who your friends are crushing on!"
dreamcrush.rules = "https://youtu.be/DWnM71e2ofc"
dreamcrush.startInDMs = true

local quitGame, createDecks

-- Uncomment this if you want to import server-specific data
-- local SERVER_LIST = {}
-- if misc.fileExists("plugins/server-specific/dreamcrush-SP.lua") then
-- 	SERVER_LIST = require("plugins/server-specific/dreamcrush-SP")
-- end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function dreamcrush.startGame(message, players)
	-- Use the name as you formatted it in MayorMcMott.lua's GAME_LIST table
	local state = {
		Host = message.author,
		Crushes = {},
		Prompts = nil,
		Traits = nil,
		Round = 0,
		GameChannel = message.channel
	}
	createDecks(state)
	local args = message.content:split(" ")
	
	local numCrushes = nil
	if #args > 2 then
		numCrushes = tonumber(args[3])
		if numCrushes == nil then
			message.channel:send("The first argument needs to be a number, homie!")
			return
		end
	else
		numCrushes = 5
	end
	print("Number of crushes: " .. numCrushes)
	
	print("Parsing name table")
	local names = misc.parseCSV("words/dreamcrush/female_names.csv")
	
	for index=1,numCrushes,1 do
		local randomIndex = misc.getRandomIndex(names)
		print("random index: " .. randomIndex)
		while misc.valueInList(names[randomIndex],state.Crushes) do
			randomIndex = misc.getRandomIndex(names)
			--print("random index: " .. randomIndex .. ", name: " .. names[randomIndex])
		end
		table.insert(state.Crushes,names[randomIndex])
		print("Adding " .. names[randomIndex])
	end
	print("Crushes:")
	--misc.printTable(state.Crushes)
	
	if #args > 3 then
		for index=1,#args-3,1 do
			state.Crushes[index] = args[index+3]
		end
	end
	print("Crushes after inserting argument names:")
	misc.printTable(state.Crushes)
	
	local crushIntro = "YOUR CRUSHES ARE:\n"
	
	for index=1,numCrushes,1 do
		crushIntro = crushIntro .. "||" .. state.Crushes[index] .. "||\n"
	end
	
	message.channel:send(crushIntro)
	
	state.GameID = games.registerGame(message.channel, "DreamCrush", state, players)
end

function dreamcrush.commandHandler(message, state)
	
	local args = message.content:split(" ")
	
	if args[1] == "!reveal" then
		state.Round = state.Round + 1
		
		if state.Round == 6 then
			message.channel:send("===FINAL ROUND===\nWho is your *Dream Crush*?")
			quitGame(state)
			return
		end
		
		local prompt = table.remove(state.Prompts[state.Round],misc.getRandomIndex(state.Prompts[state.Round]))
		print(prompt)
		
		
		message.channel:send("===ROUND " .. state.Round .. "===\n" .. prompt .. "\n")
		
		local traitsMessage = ""
		
		for index=1,#state.Crushes,1 do
			local trait = table.remove(state.Traits[state.Round],misc.getRandomIndex(state.Traits[state.Round]))
			print(trait)
			traitsMessage = traitsMessage .. state.Crushes[index] .. ": ||" .. trait .. "||\n"
		end
		
		
		message.channel:send(traitsMessage)
		
	end
	
	if args[1] == "!reroll" then
		if #args < 2 then
			message.channel:send("Usage: '!reroll <number>'")
			return
		end
		local rerollNum = tonumber(args[2])
		if rerollNum == nil then
			message.channel:send("Usage: '!reroll <number>'")
			return
		end
		
		local trait = table.remove(state.Traits[state.Round],misc.getRandomIndex(state.Traits[state.Round]))
		print(trait)
		message.channel:send(state.Crushes[rerollNum] .. ": ||" .. trait .. "||\n")
			
	end
	
	if args[1] == "!quit" then
		quitGame(state)
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function createDecks(state)
	local trait_format         = "words/dreamcrush/dreamcrush_traits%i.csv"
	local custom_trait_format  = "words/dreamcrush/dreamcrush_traits%i_custom.csv"
	local prompt_format        = "words/dreamcrush/dreamcrush_round%i.csv"
	local custom_prompt_format = "words/dreamcrush/dreamcrush_round%i_custom.csv"

	local trait_table  = {}
	local prompt_table = {}

	-- Get traits
	for i=1,5 do
		local traits = misc.parseCSV(string.format(trait_format,i),";")
		local custom = misc.parseCSV(string.format(custom_trait_format,i),";")
		misc.fuseLists(traits, custom)
		print("Loaded", tostring(#traits), "traits for deck", tostring(i))
		table.insert(trait_table, traits)
	end

	-- Get prompts
	for i=1,5 do
		local prompts = misc.parseCSV(string.format(prompt_format,i),";")
		local custom  = misc.parseCSV(string.format(custom_prompt_format,i),";")
		misc.fuseLists(prompts, custom)
		print("Loaded", tostring(#prompts), "prompts for deck", tostring(i))
		table.insert(prompt_table, prompts)
	end

	-- Save to state
	state.Traits  = trait_table
	state.Prompts = prompt_table
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameID)	
end

return dreamcrush