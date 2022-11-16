# Mayor McMott
## What Is This?
Mayor McMott (née MottBot) is an extensible board game bot for [Discord](https://discord.com/) using the [Discordia bot framework](https://github.com/SinisterRectus/Discordia) by SinisterRectus. Mayor McMott can emulate various board games so you can play with anyone, anywhere, as long as they have a Discord account and internet access. Additionally, adding new games is as easy as writing a few lua functions, giving you the freedom to add any game you can imagine!

## How Do I Use It?
To run Mayor McMott, simply download the repository, create a file named BOT_TOKEN, and put your discord bot's token in it (make sure you don't have a newline at the end of the file). Once this is done, the bot can be started by running MayorMcMott.bat. 

For some games which support server-specific data (eg Chameleon), you can add your data in plugins/server-specific/. This allows you to add, for instance, Chameleon cards that will only appear when playing in a specific server. Games that support this will have example files in plugins/server-specific/; simply edit them to include your custom data, then rename them to remove the .example prefix.

There are two other .example files that you may want to use. Debug.lua.example returns an empty function. Rename it to Debug.lua and modify the function to run it with the !debug command. The !debug function will be updated every time you run it, so there's no need to restart the bot. Emotes.lua.example returns a table of custom emojis. If you want to use functions that include custom emojis, add the IDs for your emojis here. Misc already implements two such functions, which can be used to write words in using custom red and green letter emojis. If you do not update this with the IDs to your custom emojis, those functions will return mostly empty strings. The files for these emojis can be found in the emotes/ folder if you'd like to add them to your server. Discord bots can use their servers' custom emojis in any server, just like a Nitro user, so you can make a new server and add Mayor McMott there to avoid using up emoji slots on a server you care about.

## How Do I Add A Game?
Adding a new game to Mayor McMott is pretty simple. All you have to do is:
* Create a new file to hold your game, and require Games.lua in it.
* Create a local table named after your game, and implement three functions in it:
  * A start function, which will be called when a user attempts to start your game,
  * A command handler, which will handle any messages in your game's channel,
  * (Optionally) a DM handler, which will handle any DMs from people playing your game,
  * (Optionally) a reaction handler, which will handle any reactions from people playing your game.
* In your start game function, call games.registerGame() to create a new instance of the game.
* Make sure your code is in the Plugins folder, and it should load automatically when starting the bot!

Two reference files have also been provided: TicTacToe.lua, a thoroughly documented implementation of a simple game, and Template.lua, a template for creating new games.
