local games = require("Games")
local misc = require("Misc")
local conspiracy = {}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function conspiracy.startGame(message, players)
    local innocent = math.random(0, #players)
    
    for idx,player in pairs(players) do
        local output = ""
        if (innocent == 0) or (innocent == idx) then output = "**You are not a conspirator.**"
        else output = "You are a conspirator. You are trying to fool **" .. tostring(players[innocent].name) .. "**" end
        player:send(output)
    end
end

function conspiracy.commandHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

return conspiracy