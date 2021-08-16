local games = require("Games")
local misc = require("Misc")

local madness = {}

local madnessCreateGameInstance, madnessGetUserIndex, madnessDeckOut, madnessLastOneStanding, madnessCompleted, madnessEndGame, madnessDrawCard
local madnessNextTurn, madnessTakeDamage, madnessAttack, madnessValidTarget, madnessShowCard, madnessPlayCard, madnessFreeAttack, madnessBecomeMad
local madnessEmptyMessageQueue, madnessBroadcast, madnessMessage, madnessName, madnessGetGameState, madnessMessageGameState

--#############################################################################################################################################
--# Configurations                                                                                                                            #
--#############################################################################################################################################

local DECK = {
	"Attack", "Attack", "Attack", "Attack", "Attack", "Attack", "Attack", "Attack", "Attack",
    "Heal", "Heal", "Heal", "Heal", "Defend", "Defend", "Defend", "Vision", "Vision", "Vision",
    "Truth", "Truth", "Chaos", "Chaos", "Regenerate", "Parry", "Slash", "Slash", "Escape",
	"Wrath", "Wrath", "Lethargy", "Blindness", "Madness"
}

local DESCRIPTIONS = {
	Attack = "Target a player. That player loses 1 life.",
	Heal = "Regain 1 life, up to a maximum of 3.",
	Defend = "When attacked, discard this to avoid the attack. Does nothing when played.",
	Vision = "Target a player and look at their card.",
	Truth = "Show your card to the other players.",
	Chaos = "Target a player and trade cards with them.",
	Regenerate = "Regain 1 life. This can put you over the maximum of 3.",
	Parry = "When attacked, discard this to avoid the attack and cause the attacker to lose 2 lives. Does nothing when played.",
	Slash = "Target two players. They each lose a life.",
	Escape = "Shuffle your card into the deck, then draw a card.",
	Wrath = "Lose a life. This is an evil card.",
	Lethargy = "The next card you play has no effect. This is an evil card.",
	Blindness = "Lose a life. You cannot regain life for the rest of the game. This is an evil card.",
	Madness = "Target a player. That player loses 1 life. Any player who sees this card becomes mad, and must eliminate every other player to win. This is an evil card."
}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function madness.startGame(message)
    local playerList = message.mentionedUsers

    message.channel:send("Starting game...")
    local state = madnessCreateGameInstance(message.channel, playerList, message)
    games.registerGame(message.channel, "Madness", state, playerList)
end

function madness.commandHandler(message, state)

end

function madness.dmHandler(message, state)
    local id = madnessGetUserIndex(state, message.author)
    if id > -1 then
		local did = false
        local args = message.content:split(" ")
        if state["Turn"] == id then
            -- Play a card
            for idx,card in pairs(state["PlayerList"][id]["Hand"]) do
                if string.lower(args[1]) == string.lower(string.sub(state["PlayerList"][id]["Hand"][idx], 1, 1)) then
                    madnessPlayCard(state, id, idx, args)
					did = true
					break
                end
            end

            -- Use a free attack
            if string.lower(args[1]) == "f" and state["PlayerList"][id]["FreeAttack"] then
                if #args == 2 then
                    madnessFreeAttack(state, id, args)
					did = true
					if state["PlayerList"][id]["Lives"] <= 0 then
						madnessNextTurn(state)
					end
					madnessEmptyMessageQueue(state)
					local madCount = 0
					for id,player in pairs(state["PlayerList"]) do
						if player["Lives"] > 0 and player["Mad"] then
							madCount = madCount + 1
						end
					end
					if state["PlayersLeft"] <= 1 then
						madnessLastOneStanding(state)
					elseif state["MadnessCount"] == 0 and madCount == 0 then
						madnessCompleted(state)
					end
                end
            end
        end
        -- Game state info
		if not did then
	        if string.lower(args[1]) == "info" then
	            madnessMessageGameState(state, id)
			elseif string.lower(args[1]) == "help" then
				if #args == 1 then
					madnessMessage(state, id, "During your turn, to play a card, type the first letter of the card then the number of the player(s) you want to target, if any, for example: **a 2** to play Attack on player #2.\n" ..
					"Use **f** to use your free attack on a player. To see the current game state, type **info**. To learn about a specific card, type **help [card name]**. To get a link to the rules, type **rules**.")
				else
					for card,desc in pairs(DESCRIPTIONS) do
						if string.lower(card) == string.lower(args[2]) or string.lower(string.sub(card, 1, 1)) == string.lower(args[2]) then
							madnessMessage(state, id, desc)
						end
					end
				end
			elseif string.lower(args[1]) == "rules" then
				madnessMessage(state, id, "The rules can be found here: https://docs.google.com/document/d/e/2PACX-1vTJP8VRGUJ8TfChFd1uFYkaLkAxxXjwjp-6T88hHcQbzA6JLJ--NoE2ns7Aiu0zfHPhhzsYjdMUoF8u/pub")
			else
				madnessMessage(state, id, "Invalid input.")
			end
		end
    end
	madnessEmptyMessageQueue(state)
end
--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function madnessCreateGameInstance(channel, playerList, message)
    local state = {
        GameChannel = channel,
        PlayerList = {},
        Deck = misc.shuffleTable(misc.shallowCopy(DECK)),
        MadnessCount = 5,
		PlayersLeft = #playerList,
        Turn = 1,
		Deathmatch = false
    }

	local okay = true
	for id,player in pairs(playerList) do
		if state["Deck"][id] == "Madness" then
			okay = false
		end
	end

	while not okay do
		state["Deck"] = misc.shuffleTable(misc.shallowCopy(DECK))
		okay = true
		for id,player in pairs(playerList) do
			if state["Deck"][id] == "Madness" then
				okay = false
			end
		end
	end

    local idx = 1
    for id,player in pairs(playerList) do
        -- Player: A user object corresponding to the player
        -- Hand: A table containing the cards in the player's hand
        -- Lives: How many lives the player has
        -- FreeAttack: Does the player have their free strike?
        -- Blind: Is the player blind?
		-- Lethargic: Is the player lethargic?
        -- Mad: Is the player mad?
		-- DiedInnocent: Did the player die with a non-evil card in hand?
        state["PlayerList"][idx] = {
            Player = player,
            Hand = {},
            Lives = 3,
            FreeAttack = true,
            Blind = false,
			Lethargic = false,
            Mad = false,
			DiedInnocent = false,
			MessageQueue = ""
        }
        idx = idx + 1
    end

    -- Choose random starting player
    state["Turn"] = math.random(#state["PlayerList"])

    -- Deal initial cards
    for id,player in pairs(state["PlayerList"]) do
		local card = state["Deck"][#state["Deck"]]
		state["Deck"][#state["Deck"]] = nil
		state["PlayerList"][id]["Hand"][#state["PlayerList"][id]["Hand"] + 1] = card
		if card == "Madness" then
			madnessBecomeMad(state, id)
		end
    end

	-- Starting player draws a card
	madnessDrawCard(state, state["Turn"])

	-- Message initial game state
	for id,player in pairs(state["PlayerList"]) do
		madnessMessageGameState(state, id)
	end
	madnessEmptyMessageQueue(state)

    return state
end

function madnessGetUserIndex(state, user)
    for id,player in pairs(state["PlayerList"]) do
        if player["Player"] == user then
            return id
        end
    end
    return -1
end

function madnessDeckOut(state)
	madnessBroadcast(state, "The deck is empty and no living players are mad, so the game is over.")
	for id,player in pairs(state["PlayerList"]) do
		if player["Lives"] > 0 then
			if #player["Hand"] > 0 then
				local card = player["Hand"][1]
				madnessBroadcast(state, madnessName(state, id) .. " held " .. card .. ".")
				if (card == "Wrath" or card == "Lethargy" or card == "Blindness") then
					madnessBroadcast(state, madnessName(state, id) .. " has won!")
				end
			end
		end
	end
	madnessEndGame(state)
end

function madnessLastOneStanding(state)
	madnessBroadcast(state, "The game has ended.")
	for id,player in pairs(state["PlayerList"]) do
		if player["Lives"] > 0 then
			madnessBroadcast(state, madnessName(state, id) .. " has survived and won!")
		end
	end
	madnessEndGame(state)
end

function madnessCompleted(state)
	madnessBroadcast(state, "All of the evil cards have been eliminated and no living players are mad, so the game is over.")
	for id,player in pairs(state["PlayerList"]) do
		if player["Lives"] > 0 then
			if #player["Hand"] > 0 then
				local card = player["Hand"][1]
				madnessBroadcast(state, madnessName(state, id) .. " held " .. card .. ".")
			end
			madnessBroadcast(state, madnessName(state, id) .. " has won!")
		elseif player["DiedInnocent"] then
			madnessBroadcast(state, madnessName(state, id) .. " has won posthumously!")
		end
	end
	madnessEndGame(state)
end

function madnessEndGame(state)
	state["GameChannel"]:send("Quitting game...")
	games.deregisterGame(state["GameChannel"])
end

function madnessDrawCard(state, id)
	madnessBroadcast(state, madnessName(state, id) .. " draws a card.")
    local card = state["Deck"][#state["Deck"]]
    state["Deck"][#state["Deck"]] = nil
    state["PlayerList"][id]["Hand"][#state["PlayerList"][id]["Hand"] + 1] = card
	madnessMessage(state, id, "> You drew " .. card .. ".")
	if card == "Madness" then
		madnessBecomeMad(state, id)
	end
end

function madnessNextTurn(state)
	local madCount = 0
	for id,player in pairs(state["PlayerList"]) do
		if player["Lives"] > 0 and player["Mad"] then
			madCount = madCount + 1
		end
	end
	if state["PlayersLeft"] <= 1 then
		madnessLastOneStanding(state)
	elseif state["MadnessCount"] == 0 and madCount == 0 then
		madnessCompleted(state)
	else
		local turn = state["Turn"]
		if turn == #state["PlayerList"] then
			turn = 0
		end
		turn = turn + 1

		-- Skip over eliminated players
		while state["PlayerList"][turn]["Lives"] == 0 do
			if turn == #state["PlayerList"] then
				turn = 0
			end
			turn = turn + 1
		end

		state["Turn"] = turn

		-- Check if the deck is out
		if #state["Deck"] > 0 then
			madnessDrawCard(state, turn)
		else
			if madCount > 0 then
				state["Deathmatch"] = true
			else
				madnessDeckOut(state)
			end

			if state["Deathmatch"] then
				if #state["PlayerList"][turn]["Hand"] == 0 then
					state["PlayerList"][turn]["Hand"][1] = "Attack"
				end
			end
		end
		madnessMessageGameState(state, turn)
	end
	madnessEmptyMessageQueue(state)
end

function madnessTakeDamage(state, id, amount)
	local health = state["PlayerList"][id]["Lives"]
	if amount >= health then
		if amount == 1 then
			madnessBroadcast(state, madnessName(state, id) .. " loses a life.")
		elseif amount == 2 then
			madnessBroadcast(state, madnessName(state, id) .. " loses 2 lives.")
		end
		state["PlayersLeft"] = state["PlayersLeft"] - 1
		state["PlayerList"][id]["Lives"] = 0
		if #state["PlayerList"][id]["Hand"] > 1 then
			card1 = state["PlayerList"][id]["Hand"][1]
			card2 = state["PlayerList"][id]["Hand"][2]
			state["PlayerList"][id]["Hand"][1] = nil
			state["PlayerList"][id]["Hand"][2] = nil
			madnessBroadcast(state, madnessName(state, id) .. " dies and discards " .. card1 .. " and " .. card2 .. ".")
			if card1 == "Wrath" or card1 == "Blindness" or card1 == "Lethargy" or card1 == "Madness" then
				state["MadnessCount"] = state["MadnessCount"] - 1
			elseif not state["PlayerList"][id]["Mad"] then
				state["PlayerList"][id]["DiedInnocent"] = true
			end
			if card2 == "Wrath" or card2 == "Blindness" or card2 == "Lethargy" or card2 == "Madness" then
				state["MadnessCount"] = state["MadnessCount"] - 1
				state["PlayerList"][id]["DiedInnocent"] = false
			elseif not state["PlayerList"][id]["Mad"] then
				state["PlayerList"][id]["DiedInnocent"] = true
			end
			if card1 == "Madness" or card2 == "Madness" then
				for idx,player in pairs(state["PlayerList"]) do
					if player["Mad"] and idx ~= id and player["Lives"] > 0 then
						madnessTakeDamage(state, idx, 1)
					end
				end
			end
		elseif #state["PlayerList"][id]["Hand"] > 0 then
			card = state["PlayerList"][id]["Hand"][1]
			state["PlayerList"][id]["Hand"][1] = nil
			madnessBroadcast(state, madnessName(state, id) .. " dies and discards " .. card .. ".")
			if card == "Wrath" or card == "Blindness" or card == "Lethargy" or card == "Madness" then
				state["MadnessCount"] = state["MadnessCount"] - 1
			elseif not state["PlayerList"][id]["Mad"] then
				state["PlayerList"][id]["DiedInnocent"] = true
			end
			if card == "Madness" then
				for idx,player in pairs(state["PlayerList"]) do
					if player["Mad"] and idx ~= id and player["Lives"] > 0 then
						madnessTakeDamage(state, idx, 1)
					end
				end
			end
		else
			madnessBroadcast(state, madnessName(state, id) .. " dies.")
			state["PlayerList"][id]["DiedInnocent"] = true
		end

	else
		state["PlayerList"][id]["Lives"] = health - amount
		if amount == 1 then
			madnessBroadcast(state, madnessName(state, id) .. " loses a life (" .. state["PlayerList"][id]["Lives"] .. " left).")
		elseif amount == 2 then
			madnessBroadcast(state, madnessName(state, id) .. " loses 2 lives (" .. state["PlayerList"][id]["Lives"] .. " left).")
		end
	end
end

function madnessAttack(state, id, target)
	local card = state["PlayerList"][target]["Hand"][1]
	if card == "Defend" then
		madnessBroadcast(state, madnessName(state, target) .. " blocks with Defend.")
		state["PlayerList"][target]["Hand"][1] = nil
		if #state["Deck"] > 0 then
			madnessDrawCard(state, target)
		end
	elseif card == "Parry" then
		madnessBroadcast(state, madnessName(state, target) .. " blocks with Parry.")
		madnessTakeDamage(state, id, 2)
		state["PlayerList"][target]["Hand"][1] = nil
		if #state["Deck"] > 0 then
			madnessDrawCard(state, target)
		end
	else
		madnessTakeDamage(state, target, 1)
	end
end

function madnessValidTarget(state, id, target)
	local tgt = tonumber(target)
	if tgt ~= nil then
		if tgt ~= id and tgt > 0 and tgt <= #state["PlayerList"] and state["PlayerList"][tgt]["Lives"] > 0 then
			return true
		end
	end
	return false
end

function madnessShowCard(state, shower, id, card)
	madnessMessage(state, id, "> " .. madnessName(state, shower) .. " shows you " .. card .. ".")
	if card == "Madness" then
		madnessBecomeMad(state, id)
	end
end

function madnessPlayCard(state, id, cardIndex, args)
	local card = state["PlayerList"][id]["Hand"][cardIndex]
	if #args == 3 and card == "Slash" and state["PlayersLeft"] > 2 and madnessValidTarget(state, id, args[2]) and madnessValidTarget(state, id, args[3]) and args[2] ~= args[3] then
		table.remove(state["PlayerList"][id]["Hand"], cardIndex)
		local t1 = tonumber(args[2])
		local t2 = tonumber(args[3])
		madnessBroadcast(state, madnessName(state, id) .. " plays " .. card .. " on " .. madnessName(state, t1) .. " and " .. madnessName(state, t2) .. ".")
		if state["PlayerList"][id]["Lethargic"] then
			madnessBroadcast(state, "It has no effect due to Lethargy.")
			state["PlayerList"][id]["Lethargic"] = false
			if card == "Wrath" or card == "Lethargy" or card == "Blindness" or card == "Madness" then
				state["MadnessCount"] = state["MadnessCount"] - 1
			end
		else
			madnessAttack(state, id, t1)
			madnessAttack(state, id, t2)
		end
		madnessNextTurn(state)
	elseif #args == 2 and madnessValidTarget(state, id, args[2]) and (card == "Attack" or card == "Vision" or card == "Chaos" or card == "Madness" or (card == "Slash" and state["PlayersLeft"] == 2)) then
		table.remove(state["PlayerList"][id]["Hand"], cardIndex)
		local target = tonumber(args[2])
		madnessBroadcast(state, madnessName(state, id) .. " plays " .. card .. " on " .. madnessName(state, target) .. ".")
		if state["PlayerList"][id]["Lethargic"] then
			madnessBroadcast(state, "It has no effect due to Lethargy.")
			state["PlayerList"][id]["Lethargic"] = false
			if card == "Wrath" or card == "Lethargy" or card == "Blindness" or card == "Madness" then
				state["MadnessCount"] = state["MadnessCount"] - 1
			end
		elseif card == "Attack" or card == "Madness" or card == "Slash" then
			madnessAttack(state, id, target)
			if card == "Madness" then
				state["MadnessCount"] = state["MadnessCount"] - 1
			end
		elseif card == "Vision" then
			if state["PlayerList"][target]["Hand"][1] ~= nil then
				madnessShowCard(state, target, id, state["PlayerList"][target]["Hand"][1])
				madnessMessage(state, target, "> You show " .. madnessName(state, id) .. " " .. state["PlayerList"][target]["Hand"][1] .. ".")
			end
		elseif card == "Chaos" then
			if state["PlayerList"][id]["Hand"][1] ~= nil and state["PlayerList"][target]["Hand"][1] ~= nil then
				local myCard = state["PlayerList"][id]["Hand"][1]
				local theirCard = state["PlayerList"][target]["Hand"][1]
				state["PlayerList"][id]["Hand"][1] = theirCard
				madnessMessage(state, id, "> You received " .. theirCard .. ".")
				state["PlayerList"][target]["Hand"][1] = myCard
				madnessMessage(state, target, "> You received " .. myCard .. ".")
				if myCard == "Madness" then
					madnessBecomeMad(state, target)
				end
				if theirCard == "Madness" then
					madnessBecomeMad(state, id)
				end
			end
		end
		madnessNextTurn(state)
	elseif #args == 1 and (state["PlayerList"][id]["Lethargic"] or card == "Heal" or card == "Defend" or card == "Truth" or card == "Regenerate" or card == "Parry" or card == "Escape" or card == "Wrath" or card == "Blindness" or card == "Lethargy") then
		table.remove(state["PlayerList"][id]["Hand"], cardIndex)
		madnessBroadcast(state, madnessName(state, id) .. " plays " .. card .. ".")
		if state["PlayerList"][id]["Lethargic"] then
			madnessBroadcast(state, "It has no effect due to Lethargy.")
			state["PlayerList"][id]["Lethargic"] = false
			if card == "Wrath" or card == "Lethargy" or card == "Blindness" or card == "Madness" then
				state["MadnessCount"] = state["MadnessCount"] - 1
			end
		elseif card == "Heal" then
			if not state["PlayerList"][id]["Blind"] then
				local health = state["PlayerList"][id]["Lives"]
				if health < 3 then
					state["PlayerList"][id]["Lives"] = health + 1
					madnessBroadcast(state, madnessName(state, id) .. " regains 1 life.")
				end
			else
				madnessBroadcast(state, "It has no effect due to Blindness.")
			end
		elseif card == "Truth" then
			if state["PlayerList"][id]["Hand"][1] ~= nil then
				madnessMessage(state, id, "> You show everyone " .. state["PlayerList"][id]["Hand"][1] .. ".")
				local myCard = state["PlayerList"][id]["Hand"][1]
				for idx,player in pairs(state["PlayerList"]) do
					if id ~= idx and player["Lives"] > 0 then
						madnessShowCard(state, id, idx, myCard)
					end
				end
			end
		elseif card == "Regenerate" then
			if not state["PlayerList"][id]["Blind"] then
				local health = state["PlayerList"][id]["Lives"]
				state["PlayerList"][id]["Lives"] = health + 1
				madnessBroadcast(state, madnessName(state, id) .. " regains 1 life.")
			else
				madnessBroadcast(state, "It has no effect due to Blindness.")
			end
		elseif card == "Escape" then
			if state["PlayerList"][id]["Hand"][1] ~= nil then
				madnessBroadcast(state, madnessName(state, id) .. " shuffles their hand into the deck.")
				local myCard = state["PlayerList"][id]["Hand"][1]
				state["Deck"][#state["Deck"] + 1] = myCard
				state["PlayerList"][id]["Hand"][1] = nil
				state["Deck"] = misc.shuffleTable(misc.shallowCopy(state["Deck"]))
				madnessDrawCard(state, id)
			end
		elseif card == "Wrath" then
			madnessTakeDamage(state, id, 1)
			state["MadnessCount"] = state["MadnessCount"] - 1
			if state["PlayerList"][id]["DiedInnocent"] then
				state["PlayerList"][id]["DiedInnocent"] = false
			end
		elseif card == "Lethargy" then
			state["PlayerList"][id]["Lethargic"] = true
			state["MadnessCount"] = state["MadnessCount"] - 1
			madnessBroadcast(state, madnessName(state, id) .. " becomes lethargic.")
		elseif card == "Blindness" then
			madnessTakeDamage(state, id, 1)
			if state["PlayerList"][id]["DiedInnocent"] then
				state["PlayerList"][id]["DiedInnocent"] = false
			end
			state["PlayerList"][id]["Blind"] = true
			state["MadnessCount"] = state["MadnessCount"] - 1
			madnessBroadcast(state, madnessName(state, id) .. " becomes blind.")
		end
		madnessNextTurn(state)
	else
		madnessMessage(state, id, "Invalid input.")
	end
end

function madnessFreeAttack(state, id, args)
	if #args == 2 and madnessValidTarget(state, id, args[2]) then
		target = tonumber(args[2])
		madnessBroadcast(state, madnessName(state, id) .. " uses their free attack on " .. madnessName(state, target) .. ".")
		madnessAttack(state, id, target)
		state["PlayerList"][id]["FreeAttack"] = false
		if state["PlayerList"][id]["Lives"] > 0 then
			madnessMessageGameState(state, id)
		end
	end
end

function madnessBecomeMad(state, id)
	if not state["PlayerList"][id]["Mad"] then
		state["PlayerList"][id]["Mad"] = true
		madnessMessage(state, id, "> **You are now mad! You must eliminate all other players to win.**")
	end
end

function madnessEmptyMessageQueue(state)
	for id,player in pairs(state["PlayerList"]) do
		if player["MessageQueue"] ~= "" then
			player["Player"]:send(player["MessageQueue"])
			player["MessageQueue"] = ""
		end
	end
end

function madnessBroadcast(state, message)
	for id,player in pairs(state["PlayerList"]) do
		madnessMessage(state, id, message)
	end
end

function madnessMessage(state, id, message)
	state["PlayerList"][id]["MessageQueue"] = state["PlayerList"][id]["MessageQueue"] .. message .. "\n"
end

function madnessName(state, id)
	return "**" .. state["PlayerList"][id]["Player"].name .. "**"
end

function madnessGetGameState(state)
	local msg = "Cards in deck: " .. #state["Deck"] .. "\n```\n"
	for id,player in pairs(state["PlayerList"]) do
		msg = msg .. id .. ". "
		if id == state["Turn"] then
			msg = msg .. "["
		end
		msg = msg .. state["PlayerList"][id]["Player"].name
		if id == state["Turn"] then
			msg = msg .. "]"
		end
		msg = msg .. " (" .. state["PlayerList"][id]["Lives"] .. " Lives) "
		if state["PlayerList"][id]["FreeAttack"] then
			msg = msg .. "*"
		end
		if state["PlayerList"][id]["Blind"] then
			msg = msg .. "B"
		end
		if state["PlayerList"][id]["Lethargic"] then
			msg = msg .. "L"
		end
		msg = msg .. "\n"
	end
	msg = msg .. "There are " .. state["MadnessCount"] .. " evil cards remaining.```"
	return msg
end

function madnessMessageGameState(state, id)
	local msg = "Your hand: ["

	if state["PlayerList"][id]["Hand"][1] ~= nil then
		msg = msg .. state["PlayerList"][id]["Hand"][1]
	end
	if state["PlayerList"][id]["Hand"][2] ~= nil then
		msg = msg .. ", " .. state["PlayerList"][id]["Hand"][2]
	end
	msg = msg .. "]\n"

	local gs = madnessGetGameState(state)
	if state["PlayerList"][id]["Mad"] then
		gs = string.gsub(gs, state["PlayerList"][id]["Player"].name, "~" .. state["PlayerList"][id]["Player"].name .. "~")
	end
	madnessMessage(state, id, msg .. gs)
end

return madness
