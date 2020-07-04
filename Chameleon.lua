local games = require("Games")
local misc = require("Misc")
local chameleon = {}

local displayWords, dmStatus, easterEggStatus, removeUnderscores

local WORDLISTS = {
	Presidents = {"Bill Clinton", "Ronald Reagan", "Franklin Roosevelt", "Dwight Eisenhower", "George W. Bush", "George Bush (Sr.)", "Barack Obama", "Donald Trump", "John Kennedy", "Abraham Lincoln", "George Washington", "Richard Nixon", "Theodore Roosevelt", "Thomas Jefferson", "John Adams (Sr.)", "Jimmy Carter"},
	Fairy_Tales = {"Cinderella", "Goldilocks", "Jack and the Beanstalk", "The Tortoise and the Hare", "Snow White", "Rapunzel", "Aladdin", "The Princess and the Pea", "Peter Pan", "Little Red Riding Hood", "Pinocchio", "Beauty and the Beast", "Sleeping Beauty", "Hansel and Gretel", "Gingerbread Man", "The Three Little Pigs"},
	Countries = {"The UK", "Spain", "Japan", "Brazil", "France", "The United States", "Italy", "Australia", "Germany", "Mexico", "India", "Israel", "Canada", "China", "Russia", "Egypt"},
	Movies = {"Jurassic Park", "Jaws", "Raiders of the Lost Ark", "The Avengers", "Transformers", "Titanic", "Toy Story", "Home Alone", "E.T.", "The Wizard of Oz", "King Kong", "The Matrix", "Shrek", "The Godfather", "Finding Nemo", "Avatar"},
	Inventions = {"Matches", "Gunpowder", "Wheels", "Printing", "Computers", "The Internet", "Compasses", "Planes", "TV", "Electricity", "Writing", "The Steam Engine", "Cars", "Telephones", "Cameras", "Radio"},
	Mythical_Creatures = {"Cyclops", "Pegasus", "Medusa", "Sphnix", "Werewolf", "Unicorn", "Dragon", "Troll", "Loch Ness Monster", "Mermaid", "Phoenix", "Vampire", "Minotaur", "Hydra", "Yeti", "Centaur"},
	Cities = {"New York City", "Moscow", "Delhi", "London", "Paris", "Rome", "Rio de Janeiro", "Sydney", "Tokyo", "Athens", "Cairo", "Hong Kong", "Chicago", "L.A.", "San Francisco", "Jerusalem"},
	Hobbies = {"Philately", "Trains", "Model Making", "Knitting", "Fishing", "Reading", "Painting", "Gardening", "Sailing", "Travel", "Walking", "Pottery", "Cooking", "Yoga", "Photography", "Hiking"},
	Musicals = {"West Side Story", "Cats", "Jersey Boys", "School of Rock", "The Phantom of the Opera", "Les Misérables", "Oliver", "Hamilton", "Chicago", "42nd Street", "Annie", "The Book of Mormon", "The Lion King", "Wicked", "Hairspray", "Mamma Mia"},
	Toys = {"Lego", "Rocking Horse", "Super Soaker", "Cabbage Patch Dolls", "Rubik's Cube", "Etch-a-Sketch", "Teddy Bear", "Play Doh", "Yo-Yo", "Frisbee", "Hot Wheels", "Barbie", "Slinky", "G.I. Joe", "Hula Hoop", "Furby"},
	Sports = {"American Football", "Soccer", "Golf", "Baseball", "Basketball", "Ice Hockey", "Sailing", "Squash", "Tennis", "Badminton", "Motor Racing", "Wrestling", "Lacrosse", "Volleyball", "Triathalon", "Cycling"},
	The_Arts = {"Painting", "Sculpture", "Architecture", "Dance", "Literature", "Opera", "Stand-Up", "Comic Books", "Illustration", "Music", "Theatre", "Cinema", "Video Games", "Graffiti", "Fashion", "Photography"},
	Fictional_Characters = {"Indiana Jones", "Mary Poppins", "Spiderman", "Catwoman", "James Bond", "Wonder Woman", "Princess Leia", "The Little Mermaid", "Dracula", "Lara Croft", "Robin Hood", "Hermione Granger", "Super Mario", "Homer Simpson", "Hercules", "Katniss Everdeen"},
	Bands = {"The Beatles", "The Rolling Stones", "AC/DC", "Nirvana", "The Backstreet Boys", "One Direction", "Guns N' Roses", "Queen", "The Beach Boys", "Red Hot Chili Peppers", "KISS", "The Jackson 5", "ABBA", "The Eagles", "The Who", "U2"},
	Civilizations = {"Romans", "Egyptians", "Mayans", "Mongols", "Aztecs", "Japanese", "Persians", "Greeks", "Turks", "Vikings", "Incas", "Spanish", "Zulu", "Chinese", "Spartans", "Aliens"},
	Transport = {"Plane", "Car", "Tank", "Helicopter", "Cruise Ship", "Hovercraft", "Motorbike", "Bus", "Segway", "Cable Car", "Jet Ski", "Hot Air Balloon", "Train", "Spaceship", "Magic Carpet", "Broomstick"},
	Musical_Instruments = {"Electric Guitar", "Piano", "Violin", "Drums", "Bass Guitar", "Saxophone", "Cello", "Flute", "Clarinet", "Trumpet", "Voice", "Ukulele", "Harp", "Bagpipes", "Harmonica", "Banjo"},
	Under_The_Sea = {"Octopus", "Starfish", "Shark", "Jellyfish", "Lobster", "Seal", "Dolphin", "Killer Whale", "Crab", "Giant Squid", "Seahorse", "Stingray", "Sea Turtle", "Clownfish", "Swordfish", "Mermaid"},
	States = {"California", "Texas", "Alabama", "Hawaii", "Florida", "Montana", "Nevada", "Mississippi", "North Carolina", "New York", "Kentucky", "Tennessee", "Colorado", "Washington", "Illinois", "Alaska"},
	Rooms = {"Kitchen", "Hallway", "Greenhouse", "Bedroom", "Bathroom", "Dining Room", "Office", "Living Room", "Attic", "Basement", "Porch", "Nursery", "Den", "Bunker", "Shed", "Garage"},
	Authors = {"William Shakespeare", "J.R.R. Tolkien", "C.S. Lewis", "J.K. Rowling", "Stephen King", "Ernest Hemingway", "Edgar Allan Poe", "Charles Dickens", "T.S. Eliot", "Leo Tolstoy", "Jane Austen", "Mark Twain", "Danielle Steel", "John Grisham", "Dan Brown", "Agatha Christie"},
	Phobias = {"Ghosts", "Spiders", "Monsters", "Rats", "Toilets", "Snakes", "Germs", "Clowns", "Needles", "Dogs", "Birds", "Insects", "Children", "Shadows", "Roller Coasters", "Planes"},
	Wedding_Anniversaries = {"Wood", "China", "Paper", "Cotton", "Bronze", "Gold", "Ruby", "Diamond", "Crystal", "Flowers", "Silk", "Leather", "Pearl", "Coral", "Tin", "Wool"},
	TV_Shows = {"Friends", "Sex and the City", "Star Trek", "The Walking Dead", "Breaking Bad", "Days of our Lives", "Cheers", "Lost", "Happy Days", "The X-Files", "General Hospital", "Frasier", "Mad Men", "South Park", "Game of Thrones", "Golden Girls"},
	Drinks = {"Coffee", "Tea", "Lemonade", "Coca-Cola", "Wine", "Beer", "Punch", "Tequila", "Hot Chocolate", "Milkshake", "Root Beer", "Water", "Smoothie", "Orange Juice", "Milk", "Champagne"},
	Artists = {"Damien Hirst", "Salvador Dali", "Pablo Picasso", "Vincent Van Gogh", "Claude Monet", "Andy Warhol", "Leonardo da Vinci", "Michelangelo", "Banksy", "Mark Rothko", "Keith Haring", "Jeff Koons", "Rembrandt", "Jackson Pollock", "Edward Hopper", "Georgia O'Keefe"},
	Games = {"Monopoly", "Scrabble", "Mouse Trap", "Guess Who", "Risk", "Operation", "Twister", "Pictionary", "Battleship", "Backgammon", "Clue", "Chess", "Checkers", "Trivial Pursuit", "Jenga", "Hungry Hungry Hippos"},
	Geography = {"Lake", "Sea", "Valley", "Mountain", "River", "Desert", "Ocean", "Forest", "Jungle", "Island", "Glacier", "Waterfall", "Volcano", "Cave", "Arctic", "Swamp"},
	Film_Genres = {"Horror", "Action", "Thriller", "Sci-Fi", "Rom-Com", "Western", "Comedy", "Christmas", "Gangster", "Foreign Language", "War", "Documentary", "Musical", "Animation", "Zombie", "Sport"},
	SciFi_And_Fantasy = {"Star Wars", "Lord of the Rings", "Star Trek", "Blade Runner", "The Addams Family", "2001: A Space Odyssey", "Terminator", "His Dark Materials", "Dune", "The Princess Bride", "Alice's Adventures in Wonderland", "Gulliver's Travels", "The War of the Worlds", "The Martian", "WALL-E", "Edward Scissorhands"},
	World_Wonders = {"Pyramids", "Eiffel Tower", "Statue of Liberty", "Big Ben", "Stonehenge", "Golden Gate Bridge", "Colosseum", "Sydney Opera House", "Christ the Redeemer", "Machu Picchu", "Taj Mahal", "Hoover Dam", "Great Wall of China", "Mount Rushmore", "Empire State Building", "Leaning Tower of Pisa"},
	Sports_Stars = {"Tiger Woods", "Pele", "Michael Jordan", "LeBron James", "Michael Phelps", "Serena Williams", "Muhammad Ali", "Tom Brady", "Hope Solo", "Babe Ruth", "Wayne Gretzky", "Kelly Slater", "Tony Hawk", "Michael Johnson", "Usain Bolt", "Hulk Hogan"},
	Childrens_Books = {"The Hobbit", "Peter Pan", "The Very Hungry Caterpillar", "101 Dalmatians", "Matilda", "Harry Potter & the Sorcerer's Stone", "Alice in Wonderland", "The Lion, the Witch and the Wardrobe", "Stuart Little", "The Cat in the Hat", "Charlie and the Chocolate Factory", "Where the Wild Things Are", "Winnie-the-Pooh", "The Adventures of Tom Sawyer", "The Jungle Book", "Charlotte's Web"},
	Music = {"Rock", "Heavy Metal", "Classical", "Funk", "Hip Hop", "Pop", "Techno", "Blues", "Rap", "Punk", "Indie", "Christmas", "Country", "House", "Disco", "Reggae"},
	Jobs = {"Fisherman", "Lumberjack", "Nurse", "Waiter", "Janitor", "Secretary", "Accountant", "Teacher", "Truck Driver", "Security Guard", "Chef", "Architect", "Police Officer", "Lawyer", "Carpenter", "Butcher"},
	Cartoon_Animals = {"Garfield", "Scooby-Doo", "Yogi Bear", "Bugs Bunny", "Mickey Mouse", "Goofy", "Jiminy Cricket", "Kung Fu Panda", "Nemo", "Tony the Tiger", "Snoopy", "Bambi", "Dumbo", "Wile E. Coyote", "Simba", "Sonic the Hedgehog"},
	Food = {"Pizza", "Potatoes", "Fish", "Cake", "Pasta", "Salad", "Soup", "Bread", "Eggs", "Cheese", "Fruit", "Chicken", "Sausage", "Ice Cream", "Chocolate", "Beef"},
	Historical_Figures = {"Jesus", "Napoleon", "Stalin", "Hitler", "Darwin", "Martin Luther King Jr.", "Pocahontas", "Einstein", "Christopher Columbus", "Mother Teresa", "Ulysses Simpson Grant", "Casesar", "Mozart", "Cleopatra", "Buddha", "Churchill"},
	School = {"Mathematics", "Chemistry", "Physics", "Biology", "History", "Philosophy", "Geography", "English", "Economics", "Spanish", "Art", "Music", "Gym", "Latin", "Religion", "Technology"},
	Zoo = {"Elephant", "Giraffe", "Koala", "Tiger", "Lion", "Leopard", "Meerkat", "Buffalo", "Ostrich", "Owl", "Eagle", "Parrot", "Scorpion", "Alligator", "Zebra", "Gorilla"}
}

local WORDLISTS_CUSTOM = {
	Bands_Custom = {"The Ramones", "Mili", "Anamanaguchi", "The Beastie Boys", "The Reverend Horton Heat", "Sublime", "The B-52s", "King Crimson", "Outkast", "The Strokes", "IOSYS", "Linkin Park", "Weezer", "Babymetal", "Wu-Tang Clan", "Hello! Project"},
	Musicians = {"Janelle Monae", "Macintosh Plus", "Kanye West", "Neil Cicierega", "Mariya Takeuchi", "King Khan", "Rob Zombie", "David Bowie", "Lady Gaga", "Johnny Cash", "Jimi Hendrix", "Koji Kondo", "Kyary Pamyu Pamyu", "Snoop Dogg", "Jimmy Buffett", "Weird Al Yankovich"},
	Historical_World_Leaders = {"Queen Elizabeth II", "Tony Abbott", "Joseph Stalin", "Adolf Hitler", "Napoleon Bonaparte", "George W. Bush", "Mao Zedong", "Kim Jong-Il", "Julius Caesar", "Emperor Hirohito", "Fidel Castro", "Nelson Mandela", "Shaka Zulu", "Alexander the Great", "Ruhollah Khomeini", "Saddam Hussein"},
	Contemporary_World_Leaders = {"Justin Trudeau", "Angela Merkel", "Donald Trump", "Xi Jinping", "Boris Johnson", "Jair Bolsonaro", "Emmanuel Macron", "Vladimir Putin", "Kim Jong-Un", "Shinzo Abe", "Scott Morrison", "Rodrigo Duerte", "Silvio Berlusconi", "Pope Francis", "Dalai Lama", "Vicente Fox"},
	Pokemon = {"Mewtwo", "Garbodor", "Wailord", "Shedinja", "Marshadow", "Ditto", "Arceus", "Torterra", "Scizor", "Goomy", "Ludicolo", "Tapu Koko", "Klefki", "Slowpoke", "Feraligatr", "Sirfetch'd"},
	Miscellaneous_Historical_Figures_With_Nothing_Particular_In_Common = {"King Arthur", "Heracles", "Gilgamesh", "Jeanne d'Arc", "Nero", "Astolfo", "Paul Bunyan", "Oda Nobunaga", "Gawain", "Edmond Dantes", "Shuten Douji", "Tamamo-no-Mae", "Cu Chulainn", "Edward Teach", "Caligula", "Hans Christian Anderson"},
	Completely_Unrelated_Objects = {"Couch", "Ohio", "Squid", "The Sun", "Aspirin", "Pepper", "Ficus", "Elbow", "Skateboard", "Dildo", "Clock", "Stop Sign", "Shopping Cart", "Drill", "Tuxedo", "Cocaine"},
	Fictional_Lands = {"Middle-Earth", "Westeros", "The Mushroom Kingdom", "Narnia", "Alice's Wonderland", "Never-Never Land", "Atlantis", "Wakanda", "Discworld", "Oz", "The Galaxy From Star Wars", "Hyrule", "Tamriel", "Valhalla", "Earthsea", "Dune"},
	Nineties_Kid_Cartoons = {"Pokemon", "CatDog", "The Angry Beavers", "Captain Planet", "The Powerpuff Girls", "Dragonball Z", "Teen Titans", "Rugrats", "Dexter's Lab", "Doug", "Codename: Kids Next Door", "Yu-Gi-Oh!", "Totally Spies", "Ren & Stimpy", "Rocco's Modern Life", "The Simpsons"},
	Religion = {"Paganism", "Christianity", "Sikhism", "Scientology", "Judaism", "Hinduism", "Zoroastrianism", "Islam", "Confucianism", "Wicca", "Buddhism", "Atheism", "Shinto", "Baha'i", "Taoism", "Satanism"},
	Chemical_Elements = {"Tungsten", "Bismuth", "Phosphorus", "Sodium", "Neon", "Oxygen", "Zinc", "Uranium", "Calcium", "Hydrogen", "Nitrogen", "Carbon", "Plutonium", "Lead", "Iron", "Chlorine"},
	Smash_Bros_Memes = {"Final Destination", "Mew2King", "Items", "Bayonetta", "Clacking", "Wavedashing", "Mashed Potato", "Soccer Guys", "Fox", "Hungrybox", "Too Big", "Falcon Punch", "Meta Knight", "Gamecube", "Waluigi", "Personal Hygiene"},
	Games_Of_Luck = {"Poker", "Roulette", "Russian Roulette", "Coin Toss", "Slots", "Bingo", "Lottery", "Craps", "Blackjack", "Rock-Paper-Scissors", "Pachinko", "Candyland", "The Royal Game of Ur", "War", "Backgammon", "Gacha"},
	Superheroes = {"Batman", "Superman", "Spider-Man", "Thor", "Wonder Woman", "The Incredible Hulk", "Iron Man", "Aquaman", "Wovlerine", "Dr. Manhattan", "Doctor Strange", "Captain America", "Squirrel Girl", "Green Lantern", "The Flash", "Radioactive Man"},
	Swiss_Army_Knife = {"Knife", "Scissors", "Awl", "Toothpick", "Flashlight", "Bottle Opener", "Screwdriver", "Can Opener", "Magnifying Glass", "Keyring", "Nail File", "Pliers", "Tweezers", "Compass", "Laser Pointer", "Corkscrew"},
	Alcoholic_Beverages = {"Beer", "Sake", "Vodka", "Tequila", "Wine", "Rum", "Whiskey", "Schnapps", "Absinthe", "Mead", "Brandy", "Moonshine", "Champagne", "Soju", "Mike's Hard Lemonade", "Mouthwash"},
	Oops_All_Pikachu = {"Surfing Pikachu", "Partner Pikachu", "Rock Star Pikachu", "Belle Pikachu", "Pop Star Pikachu", "PhD Pikachu", "Pikachu Libre", "Ditto", "Pikachu In A Cap", "Gigantamax Pikachu", "Ash's Pikachu", "Ash Pikachu", "Mimikyu", "Festive Pikachu", "Detective Pikachu", "Fat Pikachu"},
	Anatomy = {"Feet", "Nose", "Heart", "Brain", "Lungs", "Skin", "Ears", "Liver", "Spine", "Vocal Chords", "Fingers", "Teeth", "Tongue", "Hair", "Genitalia", "Spleen"},
	Colors = {"Black", "White", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Brown", "Gray", "Teal", "Cyan", "Magenta", "Gold", "Silver"},
	Monster_Trucks = {"Grave Digger", "Bakugan Dragonoid", "Donkey Kong", "Megalodon", "Scooby-Doo", "Bigfoot", "Hot Wheels", "Iron Outlaw", "Outback Thunda", "Maximum Destruction", "Avenger", "El Toro Loco", "Black Stallion", "Blue Thunder", "Batman", "Monster Energy Nitro Menace"},
	Critically_Acclaimed_Games = {"Big Rigs: Over the Road Racing", "Superman 64", "Bubsy 3D", "Hong Kong '97", "Daikatana", "The WarZ", "No Man's Sky", "Fallout 76", "Link: The Faces of Evil", "E.T.", "Shaq Fu", "Action 52", "Sonic 2006", "Custer's Revenge", "Mario is Missing", "The Last of Us: Part II"},
	Things_Snoop_Dogg_Was_In = {"Scary Movie 5", "Mac & Devin Go to High School", "Racing Stripes", "Soul Plane", "Starsky & Hutch", "Beef", "Beef II", "Beef IV", "Futurama: Into the Wild Green Yonder", "Turbo", "King of the Hill", "The Boondocks", "Epic Rap Battles of History", "Tekken Tag Tournament 2", "Call of Duty: Ghosts", "Peter J. Pitchess Detention Center"},
	Obsolete_Tech = {"VCR", "Telegraph", "Floppy Disk", "Rotary Phone", "Typewriter", "DVD", "Vinyl Records", "Pager", "Fax", "Cassette", "Sundial", "Musket", "Payphone", "Abacus", "Sword", "CRT TV"},
	Captain = {"Kirk", "Ahab", "Hook", "Beefheart", "America", "& Tenille", "Picard", "Crunch", "Nemo", "Morgan", "Underpants", "Toad", "Planet", "Phillips", "Falcon", "Jack Sparrow"},
	Sitcoms = {"Seinfeld", "Friends", "It's Always Sunny In Philadelphia", "Everybody Hates Chris", "How I Met Your Mother", "Parks and Recreation", "The Office", "The Fresh Prince of Bel Air", "The Simpsons", "The Big Bang Theory", "Modern Family", "Family Guy", "Arrested Development", "Community", "Full House", "Curb Your Enthusiasm"},
	Birds = {"Penguin", "Robin", "Blue Jay", "Canary", "Parrot", "Shoebill", "Chicken", "Emu", "Vulture", "Eagle", "Hummingbird", "Owl", "Flamingo", "Dodo", "Swan", "Duck"},
	Australians = {"Harold Holt", "Rupert Murdoch", "Clive Palmer", "Steve Irwin", "Julian Assange", "Scott Morrison", "Anthony Albanese", "Tony Abbott", "Saxton Hale", "Bob Hawke", "Kylie Minogue", "Steve", "Robert Menzies", "Mel Gibson", "Karl Stefanovic", "Kyle Sandilands"},
	Bullshit = {"Ghosts", "Psychics", "Tarot", "MBTI", "Homeopathy", "UFOs", "Astrology", "Witchcraft", "Phrenology", "Chiropractic", "Feng Shui", "Hypnosis", "Creation Science", "Fan Death", "Flat Earth", "Acupuncture"},
	Appliances = {"Oven", "Washer", "Dishwasher", "Refrigerator", "Toaster", "Dryer", "Electric Fan", "Water Heater", "Coffee Maker", "Blowdryer", "Vacuum Cleaner", "Air Conditioner", "Microwave", "Space Heater", "Garbage Disposal", "Blender"},
	Disasters = {"Flood", "Hurricane", "Wildfire", "Earthquake", "Nuclear War", "Tornado", "Tsunami", "Plague", "Volcanic Eruption", "Blizzard", "Drought", "Avalanche", "Riot", "Blackout", "Hailstorm", "Terror Attack"},
	Comics = {"Peanuts", "XKCD", "Penny Arcade", "Dilbert", "Garfield", "Ctrl+Alt+Del", "The Far Side", "Marmaduke", "SMBC", "Calvin and Hobbes", "Oglaf", "Achewood", "Cyanide & Happiness", "Ziggy", "Dennis the Menace", "Hark! A Vagrant"},
	Retro_Games = {"Pac-Man", "Contra", "Metroid", "Super Mario Bros.", "Gauntlet", "Excitebike", "Pong", "Punch-Out!!", "Zork", "Ghosts 'n Goblins", "Tetris", "Paperboy", "Castlevania", "Ninja Gaiden", "Donkey Kong", "Battletoads"},
	Meme_Songs = {"Running in the 90s", "Caramelldansen", "You Spin Me Right Round", "Astronomia (Coffin Dance)", "Never Gonna Give You Up", "Shooting Stars", "Sanctuary Guardian - Earthbound", "Friday", "Numa Numa", "What is Love?", "Marisa Stole the Precious Thing", "Space Jam Theme", "All Star", "Megalovania", "Big Enough (Screaming Cowboy)", "Crab Rave"},
	Pokemon_That_Nobody_Cares_About = {"Silcoon", "Gothita", "Eelektrik", "Yungoos", "Exeggcute", "Baltoy", "Skorupi", "Patrat", "Sewaddle", "Trumbeak", "Cosmoem", "Barboach", "Phione", "Binacle", "Wimpod", "Skiploom"},
	Fantasy_Monsters = {"Slime", "Succubus", "Dragon", "Chimera", "Manticore", "Orc", "Halfling", "Fairy", "Mermaid", "Kappa", "Tengu", "Beholder", "Unicorn", "Lich", "Wyvern", "Golem"},
	Fruits = {"Coconut", "Cherry", "Pear", "Apple", "Peach", "Orange", "Banana", "Watermelon", "Grape", "Kiwi", "Cucumber", "Mango", "Pineapple", "Lemon", "Tomato", "Durian"},
	Kentucky_Derby_Winners = {"Country House", "Always Dreaming", "American Pharoah", "Orb", "Super Saver", "War Emblem", "Real Quiet", "Sea Hero", "Spend a Buck", "Genuine Risk", "Spectacular Bid", "Burgoo King", "Black Gold", "Behave Yourself", "Pink Star", "Jet Pilot"},
	Methods_of_Execution = {"Electric Chair", "Hanging", "Firing Squad", "Lethal Injection", "Gas Chamber", "Stoning", "Impalement", "Burning at Stake", "Brazen Bull", "Immurement", "Drawn and Quartered", "Walk the Plank", "Guillotine", "Lingchi", "Crucifixion", "Snu Snu"},
	Vegetables = {"Celery", "Eggplant", "Onion", "Potato", "Carrot", "Broccoli", "Spinach", "Lettuce", "Brussels Sprout", "Cabbage", "Beet", "Zucchini", "Pea", "Corn", "Radish", "Asparagus"},
	Only_The_Best_Smash_Bros_Stages = {"75m", "Dream Land GB", "Gaur Plain", "The Great Cave Offensive", "Great Plateau Tower (Hazards Off)", "Hanenbow", "Icicle Mountain", "Mushroomy Kingdom", "Pac-Land", "Wrecking Crew", "Mario Bros.", "The Scoop", "Baby Park 200cc", "Samus x Ridley", "Switch Zone", "Shaq's Hot Wing"},
	Letters_of_the_Alphabet = {"A", "B", "C", "E", "G", "H", "I", "J", "K", "M", "O", "Q", "R", "T", "X", "Z"}
}

-- Table definitions for injoke cards that only get pulled up on specific servers can be placed in a separate file
require("Chameleon-Special-Cards")
local SERVER_LIST = {
	["698458922268360714"] = WORDLISTS_FQ,
	["353359832902008835"] = WORDLISTS_RIT
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
	-- Custom cards are on by default
	local args = message.content:split(" ")
	if args[3] ~= "vanilla" then
		misc.fuseDicts(WORDLISTS, WORDLISTS_CUSTOM)
	end
	-- Or maybe we only want customs?
	if args[3] == "custom" then
		WORDLISTS = WORDLISTS_CUSTOM
	end
	-- Server-relevant cards
	for server,list in pairs(SERVER_LIST) do
		if message.guild.id == server and args[3] ~= "vanilla" then misc.fuseDicts(WORDLISTS, list); misc.printTable(WORDLISTS) end
	end
	print(args[3])
	-- Optionally, pick the card
	if WORDLISTS[args[3]] ~= nil then
		state["Wordlist"] = args[3]
	else
		state["Wordlist"] = misc.getRandomIndex(WORDLISTS)
	end
	state["Chameleon"] = misc.getRandomIndex(message.mentionedUsers)
	if math.random(100) == 1 then easterEggStatus(state) else dmStatus(state) end
	--games.registerGame(message.channel, "Chameleon", state, message.mentionedUsers)
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

function removeUnderscores(word)
	local o = ""
	for i = 1, #word do
    	local c = word:sub(i,i)
    	if c == "_" then o = o .. " " else o = o .. c end
	end
	return o
end

function displayWords(state, bold)
	local output = "Category: " .. removeUnderscores(state["Wordlist"]) .. "\nWords: "
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

function easterEggStatus(state)
	for id,player in pairs(state["PlayerList"]) do
		player:send(displayWords(state, false))
	end
end

return chameleon