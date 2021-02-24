local games = require("Games")
local misc = require("Misc")
local mafia = {}

local ROLES = {"Vanilla Townie", "Mayor", "Super Saint", "Oracle", "Jester"}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function mafia.startGame(message)
    local roles = misc.shuffleTable(misc.shallowCopy(ROLES))
    local players = misc.shuffleTable(misc.indexifyTable(misc.shallowCopy(message.mentionedUsers)))

    misc.printTable(players)

    local state = {
        GameChannel = message.channel,
        Scum = players[1],
        Town1 = players[2],
        Town2 = players[3],
        Role1 = roles[1],
        Role2 = roles[2],
        Unused = roles[3]
    }

    state["Scum"]:send("You are scum!")
    state["Town1"]:send("You are " .. state["Role1"])
    state["Town2"]:send("You are " .. state["Role2"])

    if state["Role1"] == "Oracle" then
        state["Town1"]:send("You see: " .. state["Unused"])
    end
    
    if state["Role2"] == "Oracle" then
        state["Town2"]:send("You see: " .. state["Unused"])
    end
    --games.registerGame(message.channel, "Conspiracy", state, message.mentionedUsers)
end

function mafia.commandHandler(message, state)
    local args = message.content:split(" ")
    if args[1] == "!quit" then
        games.deregisterGame(state["GameChannel"])
        message.channel:send("Quiting game...")
    end
end

function mafia.dmHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

return mafia