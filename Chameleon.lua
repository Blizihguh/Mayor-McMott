local games = require("Games")
local misc = require("Misc")
local chameleon = {}

local displayWords, dmStatus

local WORDLISTS = {
	Presidents = {"Bill Clinton", "Ronald Reagan", "Franklin Roosevelt", "Dwight Eisenhower", "George W. Bush", "George Bush (Sr.)", "Barack Obama", "Donald Trump", "John Kennedy", "Abraham Lincoln", "George Washington", "Richard Nixon", "Theodore Roosevelt", "Thomas Jefferson", "John Adams (Sr.)", "Jimmy Carter"}
}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function chameleon.startGame(message)
	local state = {
		GameChannel = message.channel,
		Wordlist = nil,
		WordIdx = math.random(16),
		PlayerList = message.mentionedUsers,
		Chameleon = nil
	}
	state["Wordlist"] = misc.getRandomIndex(WORDLISTS)
	state["Chameleon"] = misc.getRandomIndex(message.mentionedUsers)
	dmStatus(state)
	games.registerGame(message.channel, "Chameleon", state, message.mentionedUsers)
end

function chameleon.commandHandler(message, state)
	local args = message.content:split(" ")
	if args[1] == "!quit" then
		games.deregisterGame(state["GameChannel"])
		message.channel:send("Quiting game...")
	end
end

function chameleon.dmHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function displayWords(state, bold)
	local output = "Category: " .. state["Wordlist"] .. "\nWords: "
	for idx,word in pairs(WORDLISTS[state["Wordlist"]]) do
		if bold and idx == state["WordIdx"] then output = output .. "**" .. word .. "**, "
		else output = output .. word .. ", " end
	end
	output = output:sub(1,-3)
	if not bold then output = output .. "\n**You are the Chameleon!**" end
	return output
end

function dmStatus(state)
	for id,player in pairs(state["PlayerList"]) do
		player:send(displayWords(state, not (id == state["Chameleon"])))
	end
end

return chameleon