local games = require("Games")
local misc = require("Misc")

local qe = {}
qe.desc = "TODO"
qe.rules = "TODO"

local quitGame, scoreGame, getTileCountry, getTileVP, getTileIndustry, advanceState

-- Uncomment this if you want to import server-specific data
-- local SERVER_LIST = {}
-- if misc.fileExists("plugins/server-specific/qe-SP.lua") then
-- 	SERVER_LIST = require("plugins/server-specific/qe-SP")
-- end
local COUNTRIES = {"US", "JP", "EU", "CN", "UK"}

local INDUSTRIES = {"Agriculture", "Housing", "Government", "Finance", "Manufacturing"}

local TILES_34 = {
	"CN_1_M", "CN_2_A", "CN_3_H", "CN_4_F",
	"JP_1_F", "JP_2_M", "JP_3_A", "JP_4_H",
	"US_1_H", "US_2_F", "US_3_M", "US_4_A",
	"EU_1_A", "EU_2_H", "EU_3_F", "EU_4_M"
}

local TILES_5 = {
	"CN_2_A", "CN_3_H", "CN_4_G",
	"JP_2_M", "JP_3_G", "JP_4_H",
	"US_2_F", "US_3_M", "US_4_A",
	"EU_2_H", "EU_3_F", "EU_4_M",
	"UK_2_G", "UK_3_A", "UK_4_F"
}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function qe.startGame(message, playerList)
	local args = message.content:split(" ")
	local players = {}
	local industries = misc.shuffleTable(misc.shallowCopy(INDUSTRIES))
	for idx,user in pairs(playerList) do
		table.insert(players, {User = user, Country = COUNTRIES[idx], Industry = industries[idx], Score = 0, Spent = 0, Bid = nil, BidZeroThisRound = false, Companies = {}})
	end

	local state = {
		GameChannel = message.channel,
		PlayerList = players,
		PlayerCt = #players,
		Deck = nil,
		Round = 1,
		Auctioneer = 1,
		Phase = 1
	}

	if state.PlayerCt == 5 then
		state.Deck = misc.shuffleTable(misc.shallowCopy(TILES_5))
	else 
		state.Deck = misc.shuffleTable(misc.shallowCopy(TILES_34))
		-- Remove government industry if it's been dealt
		for idx,playerInfo in pairs(state.PlayerList) do
			if playerInfo.Industry == "Government" then playerInfo.Industry = industries[5] end
		end
	end
	
	state.GameID = games.registerGame(message.channel, "QE", state, playerList)
end

function qe.commandHandler(message, state)
	local args = message.content:split(" ")
end

function qe.dmHandler(message, state)
	local args = message.content:split(" ")
end

function qe.reactHandler(reaction, user, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function advanceState(state)
	-- Auctioneer bid
	-- Secret bids
	-- If everyone has bid...
		-- Inform Auctioneer what everyone bid
		-- Reveal + award tile to winner
		-- Add winner's bid to their total
		-- Reveal all zero bids, award 2 VP to anyone who hasn't already bid zero this round, then set their BidZeroThisRound field to true
		-- Check for endgame
		-- Set Phase to 1, advance Auctioneer, advance Round if necessary
end

function getTileCountry(tile)
	return tile:sub(1,2)
end

function getTileVP(tile)
	return tonumber(tile:sub(4,4))
end

function getTileIndustry(tile)
	local industries = {A = "Agriculture", H = "Housing", G = "Government", F = "Finance", M = "Manufacturing"}
	return industries[tile:sub(6,6)]
end

function scoreGame(state)
	-- Calculate the most and least frugal players
	local mostSpent = 0
	local biggestSpenders = {}
	local leastSpent = 0
	local smallestSpenders = {}
	for idx,playerInfo in pairs(state.PlayerList) do
		if playerInfo.Spent > mostSpent then mostSpent = playerInfo.Spent end
		if playerInfo.Spent == leastSpent then leastSpent = playerInfo.Spent end
	end

	for idx,playerInfo in pairs(state.PlayerList) do
		-- Base tile VP
		local companyScore = 0
		-- Companies that match the player's country
		local natlMatches = 0
		-- Count for each industry
		local industries = {
			Agriculture = 0,
			Housing = 0,
			Government = 0,
			Finance = 0,
			Manufacturing = 0
		}
		industries[playerInfo.Industry] = 1
		-- Tabulate info for all companies
		for _,cmpy in pairs(playerInfo.Companies) do
			-- Base score
			companyScore = companyScore + getTileVP(cmpy)
			-- Country matches
			if getTileCountry(cmpy) == playerInfo.Country then natlMatches = natlMatches + 1 end
			-- Industry counting
			local i = getTileIndustry(cmpy)
			industries[i] = industries[i] + 1
		end

		-- Nationalization scoring
		local s = {}
		if state.PlayerCt == 5 then s = {3, 6, 10, 10} else s = {1, 3, 6, 10} end
		local natlScore = s[natlMatches]

		-- Monopolization scoring
		local s = {}
		if state.PlayerCt == 5 then s = {0, 6, 10, 16, 16} else s = {0, 3, 6, 10, 10} end
		local indScores = {
			Agriculture = 0,
			Housing = 0,
			Government = 0,
			Finance = 0,
			Manufacturing = 0
		}
		for i,ct in pairs(industries) do
			indScores[i] = s[industries[i]]
		end
		local monoScore = misc.sumTable(indScores)

		-- Diversification scoring
		local divScore = 0
		local s = {}
		if state.PlayerCt == 5 then s = {0, 0, 4, 8, 0} else s = {0, 0, 8, 12, 17} end
		-- For each number from 5 to 3...
		for i=5,3,-1 do
			-- Try to make a group of that many industries; if you can, decrement all industries and try again
			while misc.sumMap(industries, function (x) return x>0 end) == i do
				divScore = divScore + s[i]
				for k,v in pairs(industries) do pairs[k] = pairs[k] - 1 end
			end
		end

		-- Calculate subtotal
		local zeroBidScore = playerInfo.Score
		local subTotal = companyScore + zeroBidScore + natlScore + monoScore + divScore

		--If the player is the most frugal, apply the bonus; if they're the least frugal, apply the penalty
		local total = subTotal
		if state.PlayerCt == 5 then s = 7 else s = 6 end
		if mostSpent == playerInfo.Spent then local total = 0
		elseif leastSpent == playerInfo.Spent then total = total + s end

		local fstring = "```"
	end
end

function quitGame(state)
	state.GameChannel:send("Quitting game...")
	games.deregisterGame(state.GameID)	
end

return qe