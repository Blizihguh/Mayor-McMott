local games = require("Games")
local misc = require("Misc")
local mafia = {}

local jester3, chicagoPD, jungle
local known_setups = "Jester3 (!start Mafia Jester3)\nChicago PD (!start Mafia Chicago)\nJungle of Bullshit (!start Mafia Jungle)\nWin Lose Banana (!start Mafia Banana)"

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function mafia.startGame(message)
    local players = misc.shuffleTable(misc.indexifyTable(misc.shallowCopy(message.mentionedUsers)))
    local args = message.content:split(" ")
    args[3] = string.lower(args[3])
    
    if     args[3] == "jester3" then jester3(message.channel, players)
    elseif args[3] == "chicago" then chicagoPD(message.channel, players)
    elseif args[3] == "jungle" then jungle(message.channel, players)
    elseif args[3] == "banana" then banana(message.channel, players)
    else message.channel:send("I don't know that setup, homie!\nKnown setups:\n" .. known_setups)
    end
end

function mafia.commandHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function banana(channel, players)
    if #players ~= 3 then
        channel:send("Win Lose Banana takes exactly 3 players!")
        return
    end
    players[1]:send("You are the Banana! 🍌")
    players[2]:send("You are the Loser! 😖")
    channel:send(players[3].name .. " is the Winner! Try to pick the Banana!")
end

function jungle(channel, players)
    if #players < 5 then
        channel:send("Jungle of Bullshit takes at least 5 players!")
        return
    end

    local scumlist = ""
    for idx,player in pairs(players) do
        if idx > 2 then scumlist = scumlist .. ", " .. player.name end
    end
    scumlist = scumlist:sub(3)

    for idx,player in pairs(players) do
        if idx == 1 or idx == 2 then
            player:send("You are a **Townie**! You win when all mafiosi are dead.\nIf you get lynched on Day 1, you are not killed and instead kill all but two other players.")
        else
            player:send("You are a **Mafia Goon**! You win if a townie is lynched on Day 2, or if nothing can stop this from happening.\nIf you get lynched on Day 1, you must confirm one townie as being town, and kill all but one of your fellow mafiosi.")
            player:send("Your fellow scum are: " .. scumlist)
        end
    end
end

function jester3(channel, players)
    if #players ~= 3 then
        channel:send("Jester3 takes exactly 3 players!")
        return
    end

    local roles = misc.shuffleTable({"Vanilla Townie", "Mayor", "Super Saint", "Oracle", "Jester"})
    local descs = {
        ["Mafia Goon"] = "You are a **Mafia Goon**! You win if a townie is lynched.",
        ["Vanilla Townie"] = "You are a **Vanilla Townie**! You win if the Mafia Goon is lynched.",
        ["Mayor"] = "You are a **Mayor**! You win if the Mafia Goon is lynched. You can reveal yourself as Mayor; if you've been revealed, your vote instantly lynches the player it's on.",
        ["Super Saint"] = "You are a **Super Saint**! You win if the Mafia Goon is lynched. If you're lynched, the last player to vote for you is lynched instead.",
        ["Oracle"] = "You are an **Oracle**! You win if the Mafia Goon is lynched. You get to see one role that isn't in the game.",
        ["Jester"] = "You are a **Jester**! You win (and everyone else loses) if you're lynched."
    }
    local jesterRule = "\nIf there's a Jester, and the other two players vote for each other, both players win and the Jester loses."
    local oracleText = "**There is no " .. roles[3] .. " in this game.**"

    players[1]:send(descs["Mafia Goon"] .. jesterRule)
    players[2]:send(descs[roles[1]] .. jesterRule)
    players[3]:send(descs[roles[2]] .. jesterRule)

    if roles[1] == "Oracle" then
        players[2]:send(oracleText)
    elseif roles[2] == "Oracle" then
        players[3]:send(oracleText)
    end
end

function chicagoPD(channel, players)
    if #players ~= 4 then
        channel:send("Chicago PD takes exactly 3 players!")
        return
    end

    local roles = misc.shuffleTable({"Secret Agent", "Cop", "Cop", "Goon", "Gunner", "Dealer"})
    local descs = {
        ["Police Chief"] = "You are the **Police Chief**, aligned with the police.",
        ["Secret Agent"] = "You are a **Secret Agent**, aligned with the police. You can reveal yourself as Secret Agent; if you've been revealed, your vote instantly lynches the player it's on, and other players cannot vote.",
        ["Cop"] = "You are a **Cop**, aligned with the police.",
        ["Goon"] = "You are a **Goon**, aligned with the mafia.",
        ["Gunner"] = "You are a **Gunner**, aligned with the mafia. With a Gunner in the game, players are lynched with only two votes instead of three; **you must reveal yourself when this happens!**",
        ["Dealer"] = "You are a **Dealer**, aligned with the mafia. If there's a Goon/Gunner and a Cop in the game, the Cop is aligned with the mafia (but is not informed of this)."
    }

    players[1]:send(descs["Police Chief"])
    players[2]:send(descs[roles[1]])
    players[2]:send(descs[roles[2]])
    players[2]:send(descs[roles[3]])
end

return mafia