-- The Games module contains the table of all currently running games. Most of its functionality is used by MayorMcMott.lua, and is not necessary
-- to touch, but games.registerGame() is used to add a game instance to that table, and games.deregisterGame() is used to remove it when it ends.
local games = require("Games")
-- Misc has utility functions (luvit took "utils")
local misc = require("Misc")
-- Lua modules work, of course, by abusing the fuck out of tables. All of the functions that are accessed from outside of the module must be named
-- tictactoe.functionName(), which will add them as fields to the table tictactoe; at the end of the file, we return tictactoe.
local tictactoe = {}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

-- There are three necessary functions for writing a Mottbot game plugin. They can be named anything.

function tictactoe.startGame(message)
	--[[tictactoe.startGame is called when a user attempts to start a new game of Tic-Tac-Toe.]]
	local playerList = message.mentionedUsers

	if #playerList ~= 2 then
		message.channel:send("Exactly two players are necessary to play Tic-Tac-Toe!")
		return
	end

	message.channel:send("Starting game...")
	local state = createGameInstance(message.channel, playerList)
	games.registerGame(message.channel, "TicTacToe", state, playerList)
	
	message.channel:send("It's Player One's turn!")
end

function tictactoe.commandHandler(message, state)
	--[[tictactoe.commandHandler is called when any message is sent in a channel with an active game of Tic-Tac-Toe running.]]
	local player = message.author.id
	local args = message.content:split(" ")

	--!move
	if (state["XTurn"] and player == state["X"]) or (not state["XTurn"] and player == state["O"]) then
		if args[1] == "!move" then
			if #args == 3 then
				local result = move(state, args[2], args[3])
				if result then
					return
				else
					message.channel:send("Invalid move!")
					return
				end
			else
				message.channel:send("Usage: !move x y")
			end
			return
		end
	end

	--!end
	if args[1] == "!end" then
		exitGame(state)
	elseif args[1] == "!board" then
		board(state)
	end
end

function tictactoe.dmHandler(message, state)
	--[[tictactoe.dmHandler is called when a player currently playing a Tic-Tac-Toe game sends Mottbot a DM. If the player happens to be playing
	multiple games, the command will be processed simultaneously by all of them(!). That said, Tic-Tac-Toe is a very simple game and does not
	require DMs, so this function is empty.]]
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function createGameInstance(channel, playerList)
	--[[Create a table containing the game state of the new game]]
	local instance = {
		GameChannel = channel,
		PlayerList = playerList,
		X = playerList[1][1],
		O = playerList[1][2],
		Board = {{"_", "_", "_"},{"_","_","_"},{"_","_","_"}},
		XTurn = true
	}
	return instance
end

function checkGameOver(state)
	--[[Checks if the game is over:
	If the game has been won, return "X" or "O" depending on who won.
	If the game has been tied, return "T".
	If the game is still in progress, return nil.]]
	local board = state["Board"]
	-- Check verticals and diagonals
	print("Diagnostics:\n")
	print(board[1][1], board[1][2], board[1][3], "\n")
	print(board[2][1], board[2][2], board[2][3], "\n")
	print(board[3][1], board[3][2], board[3][3], "\n")
	for i=1,3 do
		if board[i][1] == board[i][2] and board[i][2] == board[i][3] and board[i][1] ~= "_" then
			print("Check 1 return", i)
			return board[i][1]
		elseif board[1][i] == board[2][i] and board[2][i] == board[3][i] and board[i][1] ~= "_" then
			print("Check 2 return", i)
			return board[1][i]
		end
	end
	-- Check diagonals
	if board[1][1] == board[2][2] and board[2][2] == board[3][3] and board[2][2] ~= "_" then print("Check 3 return"); return board[2][2] end
	if board[3][1] == board[2][2] and board[2][2] == board[3][1] and board[2][2] ~= "_" then print("Check 4 return"); return board[2][2] end
	-- Check board full
	local full = true
	while full do
		for i=1,3 do
			for j=1,3 do
				if board[i][j] == "_" then
					full = false
				end
			end
		end
		break
	end
	if full then return "T" else return nil end
end

--#############################################################################################################################################
--# Commands                                                                                                                                  #
--#############################################################################################################################################

function board(state)
	--[[Output the board to game chat]]
	local channel = state["GameChannel"]
	local output = "```"
	print("Output\n")
	for row,tbl in pairs(state["Board"]) do
		for col,str in pairs(tbl) do
			print(row,col,str)
			output = output .. str
		end
		print("\n")
		output = output .. "\n"
	end
	output = output .. "```"
	channel:send(output)
end

function move(state, x, y)
	--[[Make a move on the game board]]
	local pos = {tonumber(x), tonumber(y)}
	-- Verify they're both numbers, in range, and that the tile isnt taken
	if pos[1] == nil or pos[2] == nil then return false
	elseif pos[1] > 3 or pos[1] < 1 or pos[2] > 3 or pos[1] < 1 then return false
	elseif state["Board"][pos[2]][pos[1]] ~= "_" then return false
	end
	-- Make the move
	if state["XTurn"] then state["Board"][pos[2]][pos[1]] = "X" else state["Board"][pos[2]][pos[1]] = "O" end 
	state["XTurn"] = not state["XTurn"]
	board(state)
	
	-- Check for game end
	local result = checkGameOver(state)
	print(result, "\n")
	if result == "X" then 
		state["GameChannel"]:send("Player One wins!")
		exitGame(state)
	elseif result == "O" then
		state["GameChannel"]:send("Player Two wins!")
		exitGame(state)
	elseif result == "T" then
		state["GameChannel"]:send("Tie game!")
		exitGame(state)
	end
	return true
end

function exitGame(state)
	--[[Close the game]]
	state["GameChannel"]:send("Quitting game...")
	games.deregisterGame(state["GameChannel"])
end

return tictactoe