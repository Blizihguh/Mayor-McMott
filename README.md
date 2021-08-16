# Mayor McMott
## What Is This?
Mayor McMott (née MottBot) is an extensible board game bot for [Discord](https://discord.com/) using the [Discordia bot framework](https://github.com/SinisterRectus/Discordia) by SinisterRectus. Mayor McMott can emulate various board games so you can play with anyone, anywhere, as long as they have a Discord account and internet access. Additionally, adding new games is as easy as writing a few lua functions, giving you the freedom to add any game you can imagine!

## How Do I Use It?
To run Mayor McMott, simply download the repository, create a file named BOT_TOKEN, and put your discord bot's token in it (make sure you don't have a newline at the end of the file). Once this is done, the bot can be started by running MayorMcMott.bat. 

For some games which support server-specific data (eg Chameleon), you can add your data in plugins/server-specific/. This allows you to add, for instance, Chameleon cards that will only appear when playing in a specific server. Games that support this will have example files in plugins/server-specific/; simply edit them to include your custom data, then rename them to remove the .example prefix.

## How Do I Add A Game?
Adding a new game to Mayor McMott is pretty simple. All you have to do is:
* Create a new file to hold your game, and require Games.lua in it.
* Create a local table named after your game, and implement three functions in it:
  * A start function, which will be called when a user attempts to start your game,
  * A command handler, which will handle any messages in your game's channel,
  * A DM handler, which will handle any DMs from people playing your game,
  * (Optionally) a reaction handler, which will handle any reactions from people playing your game.
* In your start game function, call games.registerGame() to create a new instance of the game.
* Finally, add your game to the table GAME_LIST in MayorMcMott.lua, and restart your bot!

Two reference files have also been provided: TicTacToe.lua, a thoroughly documented implementation of a simple game, and Template.lua, a template for creating new games.
