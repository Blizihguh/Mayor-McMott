local games = require("Games")
local misc = require("Misc")
local conspiracy = {}

local displayWords, yesConspiracy, noConspiracy



--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function conspiracy.startGame(message)
    -- It would be simpler to just use message.mentionedUsers. 
    -- However, I got an extremely strange error where printing message.mentionedUsers showed one table and accessing it showed another.
    -- (eg: print(message.mentionedUsers) shows "1234567890" = User: 1234567890, but message.mentionedUsers["1234567890"] is nil.)
    local playerList = {}
    for key,value in pairs(message.mentionedUsers) do
        table.insert(playerList, value)
    end

    local state = {
        GameChannel = message.channel,
        PlayerList = playerList,
        Innocent = nil
    }
    
    local roll = math.random(0, #state["PlayerList"])
    if roll == 0 then
        noConspiracy(state)
    else
        state["Innocent"] = roll
        yesConspiracy(state)
    end
    --games.registerGame(message.channel, "Conspiracy", state, message.mentionedUsers)
end

function conspiracy.commandHandler(message, state)
    local args = message.content:split(" ")
    if args[1] == "!quit" then
        games.deregisterGame(state["GameChannel"])
        message.channel:send("Quiting game...")
    end
end

function conspiracy.dmHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################


function displayWords(state, isConspirator)
    local output = ""
    if not isConspirator then output = "**You are not a conspirator.**" 
    else output = "You are a conspirator. You are trying to fool **" .. tostring(state.PlayerList[state.Innocent][10]) .. "**" end
    return output
end

function yesConspiracy(state)
    for id,player in pairs(state["PlayerList"]) do
        player:send(displayWords(state, not (id == state["Innocent"])))
    end
end

function noConspiracy(state)
    for id,player in pairs(state["PlayerList"]) do
        player:send(displayWords(state, false))
    end
end

return conspiracy