local games = require("Games")
local misc = require("Misc")

local fastlength = {}

local getAxisString

--#############################################################################################################################################
--# Configurations                                                                                                                            #
--#############################################################################################################################################

local AXES = {"GOOD or BAD?", "NOT ADDICTIVE or VERY ADDICTIVE?", "HOT or COLD?", "NORMAL or WEIRD?", "FEELS GOOD or FEELS BAD?", "UNNECESSARY or ESSENTIAL?", "RARE or COMMON?", 
"EMOJI NO SEXY or EMOJI SEXY?", "FAMOUS or OBSCURE?", "DIFFICULT TO USE or EASY TO USE?", "PEPPY or GRUMPY?", "FANTASY or SCI-FI?", "CASUAL or FORMAL?", "PROHIBITED or ENCOURAGED?", 
"SMELLS GOOD or SMELLS BAD?"}
local CUSTOM_AXES = {"BEST GIRL or SHIT TIER?", "PREFERS SUBS or PREFERS DUBS?", "PURE or CORRUPT?", "FIGHTER or WIZARD?", "DOMME or SUB?", "TOP or BOTTOM?", "PLEBIAN or PATRICIAN?",
"LOW QUALITY or HIGH QUALITY?", "SOFT or HARD?", "SOUR or SWEET?", "GAY or STRAIGHT?", "OLD or NEW?", "NERDY or HIP?", "FASHIONABLE or PRACTICAL?", "PRO GAMER or CASUAL SCRUB?",
"WORTHLESS or PRICELESS?", "UGLY or BEAUTIFUL?", "COWARDLY or BRAVE?", "HIGH or LOW?", "10 or -10?", "JIMMY BUFFETT or KENNY CHESNEY?", "SMALL or LARGE?", "WET or DRY?", "LEWD or PRUDE?",
"DAY or NIGHT?", "BREAKFAST or DINNER?", "RISKY or SAFE?", "DISGUSTING or ALLURING?", "SIMPLE or COMPLEX?", "NEAT or MESSY?", "CONTROVERSIAL or UNDISPUTED?", "BOAT or FRESH PRINCE?"}

-- Custom axes are ON by default
misc.fuseLists(AXES, CUSTOM_AXES)

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function fastlength.startGame(message)
	local state = {
		Psychic = message.author,
		Axis = AXES[math.random(#AXES)],
		Axis2 = AXES[math.random(#AXES)],
		HardMode = false,
		Value = math.random(-10,10),
		Value2 = math.random(-10,10),
		GameChannel = message.channel
	}

	args = message.content:split(" ")
	if #args > 2 and string.upper(args[3]) == "2D" then state["HardMode"] = true end

	-- DM the author to let them know
	if state["HardMode"] then
		-- Two axes
		local valuesMsg = "Your target values are: " .. state["Value"] .. " and " .. state["Value2"] .. "\n"
		local axesMsg = "The axes are: " .. state["Axis"] .. " and " .. state["Axis2"] .. "\n"
		local axesGraph = getAxisString(state["Value"], state["Axis"]) .. "\n" .. getAxisString(state["Value2"], state["Axis2"])
		message.author:send(valuesMsg .. axesMsg .. axesGraph)
		message.channel:send(axesMsg)
	else
		message.author:send("Your target value is: " .. state["Value"] .. "\n" .. "The axis is: " .. state["Axis"] .. "\n" .. getAxisString(state["Value"], state["Axis"]))
		message.channel:send("The axis is: " .. state["Axis"])
	end

	-- Create a new game and register it
	games.registerGame(message.channel, "Fastlength", state, {message.author})
end

function fastlength.commandHandler(message, state)
	local args = message.content:split(" ")

	if args[1] == "!reveal" then
		if state["HardMode"] then
			local outputMsg = "The target values are: " .. state["Value"] .. " and " .. state["Value2"] .. "\n"
			outputMsg = outputMsg .. getAxisString(state["Value"], state["Axis"]) .. "\n" .. getAxisString(state["Value2"], state["Axis2"])
			message.channel:send(outputMsg)
		else
			message.channel:send("The target value is... " .. state["Value"] .. "\n" .. getAxisString(state["Value"], state["Axis"]))
		end
		games.deregisterGame(state["GameChannel"])
	end
end

function fastlength.dmHandler(message, state)
	-- This game has nothing to DM
	-- TODO: Maybe DM the word choice to the bot?
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function getAxisString(pos, axis)
	local orPos = axis:find("or")
	local words = {axis:sub(1,orPos-2), "or", axis:sub(orPos+3,-1)}
	local output = words[1] .. " <"
	
	if pos == nil then output = output .. "----------|----------"
	elseif pos == 0 then output = output .. "----------X----------"
	else
		adjPos = pos + 10
		if adjPos < 10 then adjPos = adjPos + 1 end -- Don't ask me why. 
		for i=1,20 do
			if i == adjPos then output = output .. "X" else output = output .. "-" end
			if i == 10 then output = output .. "|" end
		end
	end

	output = output .. "> " .. words[3]:sub(1,-2)
	return output
end

return fastlength