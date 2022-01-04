local games = require("Games")
local misc = require("Misc")
local dreamcrush = {}

--IMPORTANT: Declare all function names (besides the startGame/commandHandler/dmHandler/optional reactHandler functions) as local variables here.
--           If you don't do this, they will be imported as global functions, possibly disrupting other games!
local quitGame, createDecks

-- Uncomment this if you want to import server-specific data
-- local SERVER_LIST = {}
-- if misc.fileExists("plugins/server-specific/dreamcrush-SP.lua") then
-- 	SERVER_LIST = require("plugins/server-specific/dreamcrush-SP")
-- end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function dreamcrush.startGame(message)
	-- Use the name as you formatted it in MayorMcMott.lua's GAME_LIST table
	local state = {
		Host = message.author,
		Crushes = {},
		Prompts = nil,
		Traits = nil,
		Round = 0,
		GameChannel = message.channel
	}
	createDecks(numChars, state)
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
	
	games.registerGame(message.channel, "DreamCrush", state, message.mentionedUsers)
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
			--if <CATCHPHRASE> in trait then
			----local catchphrase = table.remove(State.Catchp
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

function dreamcrush.dmHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function createDecks(n, state)
	print("Parsing trait tables")
	--local t1 = misc.parseCSV("words/dreamcrush/dreamcrush_traits1.csv")
	--print("and the rest")
	local trait_table = {
						misc.parseCSV("words/dreamcrush/dreamcrush_traits1.csv",";"),
					    misc.parseCSV("words/dreamcrush/dreamcrush_traits2.csv",";"),
					    misc.parseCSV("words/dreamcrush/dreamcrush_traits3.csv",";"),
						misc.parseCSV("words/dreamcrush/dreamcrush_traits4.csv",";"),
						misc.parseCSV("words/dreamcrush/dreamcrush_traits5.csv",";")
						}
	print("Parsing prompt tables")
	local prompt_table = {
						misc.parseCSV("words/dreamcrush/dreamcrush_round1.csv",";"),
					    misc.parseCSV("words/dreamcrush/dreamcrush_round2.csv",";"),
					    misc.parseCSV("words/dreamcrush/dreamcrush_round3.csv",";"),
						misc.parseCSV("words/dreamcrush/dreamcrush_round4.csv",";"),
						misc.parseCSV("words/dreamcrush/dreamcrush_round5.csv",";")
						}
	state.Prompts = prompt_table
	state.Traits = trait_table
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameChannel)	
end

return dreamcrush