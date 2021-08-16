local games = require("Games")
local misc = require("Misc")
local chameleon = {}

local displayWords, dmStatus, oopsAllChameleons, removeUnderscores

local WORDLISTS_VANILLA = {
	Presidents = {"Bill Clinton", "Ronald Reagan", "Franklin Roosevelt", "Dwight Eisenhower", "George W. Bush", "George Bush (Sr.)", "Barack Obama", "Donald Trump", "John Kennedy", "Abraham Lincoln", "George Washington", "Richard Nixon", "Theodore Roosevelt", "Thomas Jefferson", "John Adams (Sr.)", "Jimmy Carter"},
	Fairy_Tales = {"Cinderella", "Goldilocks", "Jack and the Beanstalk", "The Tortoise and the Hare", "Snow White", "Rapunzel", "Aladdin", "The Princess and the Pea", "Peter Pan", "Little Red Riding Hood", "Pinocchio", "Beauty and the Beast", "Sleeping Beauty", "Hansel and Gretel", "Gingerbread Man", "The Three Little Pigs"},
	Countries = {"The UK", "Spain", "Japan", "Brazil", "France", "The United States", "Italy", "Australia", "Germany", "Mexico", "India", "Israel", "Canada", "China", "Russia", "Egypt"},
	Movies = {"Jurassic Park", "Jaws", "Raiders of the Lost Ark", "The Avengers", "Transformers", "Titanic", "Toy Story", "Home Alone", "E.T.", "The Wizard of Oz", "King Kong", "The Matrix", "Shrek", "The Godfather", "Finding Nemo", "Avatar"},
	Inventions = {"Matches", "Gunpowder", "Wheels", "Printing", "Computers", "The Internet", "Compasses", "Planes", "TV", "Electricity", "Writing", "The Steam Engine", "Cars", "Telephones", "Cameras", "Radio"},
	Mythical_Creatures = {"Cyclops", "Pegasus", "Medusa", "Sphinx", "Werewolf", "Unicorn", "Dragon", "Troll", "Loch Ness Monster", "Mermaid", "Phoenix", "Vampire", "Minotaur", "Hydra", "Yeti", "Centaur"},
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
	Superheroes = {"Batman", "Superman", "Spider-Man", "Thor", "Wonder Woman", "The Incredible Hulk", "Iron Man", "Aquaman", "Wolverine", "Dr. Manhattan", "Doctor Strange", "Captain America", "Squirrel Girl", "Green Lantern", "The Flash", "Radioactive Man"},
	Swiss_Army_Knife = {"Knife", "Scissors", "Awl", "Toothpick", "Flashlight", "Bottle Opener", "Screwdriver", "Can Opener", "Magnifying Glass", "Keyring", "Nail File", "Pliers", "Tweezers", "Compass", "Laser Pointer", "Corkscrew"},
	Alcoholic_Beverages = {"Beer", "Sake", "Vodka", "Tequila", "Wine", "Rum", "Whiskey", "Schnapps", "Absinthe", "Mead", "Brandy", "Moonshine", "Champagne", "Soju", "Mike's Hard Lemonade", "Mouthwash"},
	Oops_All_Pikachu = {"Surfing Pikachu", "Partner Pikachu", "Rock Star Pikachu", "Belle Pikachu", "Pop Star Pikachu", "PhD Pikachu", "Pikachu Libre", "Ditto", "Pikachu In A Cap", "Gigantamax Pikachu", "Ash's Pikachu", "Ash Pikachu", "Mimikyu", "Festive Pikachu", "Detective Pikachu", "Fat Pikachu"},
	Anatomy = {"Feet", "Nose", "Heart", "Brain", "Lungs", "Skin", "Ears", "Liver", "Spine", "Vocal Cords", "Fingers", "Teeth", "Tongue", "Hair", "Genitalia", "Spleen"},
	Colors = {"Black", "White", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Brown", "Gray", "Teal", "Cyan", "Magenta", "Gold", "Silver"},
	Monster_Trucks = {"Grave Digger", "Bakugan Dragonoid", "Donkey Kong", "Megalodon", "Scooby-Doo", "Bigfoot", "Hot Wheels", "Iron Outlaw", "Outback Thunda", "Maximum Destruction", "Avenger", "El Toro Loco", "Black Stallion", "Blue Thunder", "Batman", "Monster Energy Nitro Menace"},
	Critically_Acclaimed_Games = {"Big Rigs: Over the Road Racing", "Superman 64", "Bubsy 3D", "Hong Kong '97", "Daikatana", "The WarZ", "No Man's Sky", "Fallout 76", "Link: The Faces of Evil", "E.T.", "Shaq Fu", "Action 52", "Sonic 2006", "Custer's Revenge", "Mario is Missing", "The Last of Us: Part II"},
	Things_Snoop_Dogg_Was_In = {"Scary Movie 5", "Mac & Devin Go to High School", "Racing Stripes", "Soul Plane", "Starsky & Hutch", "Beef", "Beef II", "Beef IV", "Futurama: Into the Wild Green Yonder", "Turbo", "King of the Hill", "The Boondocks", "Epic Rap Battles of History", "Tekken Tag Tournament 2", "Call of Duty: Ghosts", "Peter J. Pitchess Detention Center"},
	Obsolete_Tech = {"VCR", "Telegraph", "Floppy Disk", "Rotary Phone", "Typewriter", "DVD", "Vinyl Records", "Pager", "Fax", "Cassette", "Sundial", "Musket", "Payphone", "Abacus", "Sword", "CRT TV"},
	Captain = {"Kirk", "Ahab", "Hook", "Beefheart", "America", "& Tenille", "Picard", "Crunch", "Nemo", "Morgan", "Underpants", "Toad", "Planet", "Phillips", "Falcon", "Jack Sparrow"},
	Sitcoms = {"Seinfeld", "Friends", "It's Always Sunny In Philadelphia", "Everybody Hates Chris", "How I Met Your Mother", "Parks and Recreation", "The Office", "The Fresh Prince of Bel Air", "The Simpsons", "The Big Bang Theory", "Modern Family", "Family Guy", "Arrested Development", "Community", "Full House", "Curb Your Enthusiasm"},
	Birds = {"Penguin", "Robin", "Blue Jay", "Canary", "Parrot", "Shoebill", "Chicken", "Emu", "Vulture", "Eagle", "Hummingbird", "Owl", "Flamingo", "Dodo", "Swan", "Duck"},
	Bullshit = {"Ghosts", "Psychics", "Tarot", "Myers-Briggs", "Homeopathy", "UFOs", "Astrology", "Witchcraft", "Phrenology", "Chiropractic", "Feng Shui", "Hypnosis", "Creation Science", "Fan Death", "Flat Earth", "Acupuncture"},
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
	Letters_of_the_Alphabet = {"A", "B", "C", "E", "G", "H", "I", "J", "K", "M", "O", "Q", "R", "T", "X", "Z"},
	Things_You_Go_Through = {"Doors", "Cancer", "Airport Security", "School", "Depression", "Divorce", "Wormholes", "Emails", "Sex Change", "Tissues", "Pantry", "Money", "Hell", "Some Things", "Broker", "The Valley of the Shadow of Death"},
	Cubes = {"Ice", "Game", "Time", "Nissan", "Rubik's", "The", "Data", "Gelatinous", "Cosmic", "Lambda", "Borg", "Companion", "Sugar", "Hyper", "Unit", "Doubling"},
	Inferior_Knock_Offs = {"SimCoaster", "Cheese Nips", "Mega Blocks", "RoseArt", "Pepsi", "Mr. Pibb", "DC Cinematic Universe", "MadCatz", "Powerade", "Flavor-Aid", "Zune", "Waluigi", "Miracle Whip", "Burger King", "New Zealand", "Oreos"},
	TF2_Paint_Colors = {"A Color Similar to Slate", "Balaclavas Are Forever", "Waterlogged Lab Coat", "Color No. 216-190-216", "A Deep Commitment to Purple", "The Color of a Gentlemann's Business Pants", "Dark Salmon Injustice", "The Bitter Taste of Defeat and Lime", "Pink as Hell", "Muskelmannbraun", "Noble Hatter's Violet", "An Extraordinary Abundance of Tinge", "A Distinctive Lack of Hue", "Aged Moustache Grey", "Ye Olde Rustic Colour", "The Value of Teamwork"},
	More_States = {"Ohio", "New South Wales", "Solid", "Plasma", "Denial", "Ground", "Fail", "Chaos", "Panic", "Bose-Einstein Condensate", "Save", "Steady", "Deep", "W", "Free", "Emergency"},
	Squares = {"Meal", "Deal", "Space", "Rim", "Hole", "Root", "Enix", "Feet", "Meter", "Tire", "Knot", "Wave", "Number", "Lattice", "Screw", "Matrix"},
	Man_Versus = {"Man", "Nature", "Machine", "Woman", "God", "Self", "Society", "Reality", "Food", "Reader", "Author", "Time", "Wild", "Computer", "Government", "Luvdisc"},
	High_School_Lit = {"1984","Wuthering Heights","The Great Gatsby","Romeo and Juliet","Great Expectations","Catcher in the Rye","The Adventures of Huckleberry Finn","Lord of the Flies","Frankenstein","The Scarlet Letter","Pride and Prejudice","To Kill a Mockingbird","Fahrenheit 451", "Of Mice and Men", "Their Eyes Were Watching God", "A Streetcar Named Desire"},
	Laws = {"Common", "International", "Maritime", "Thermodynamics", "Copyright", "Averages", "Attraction", "Newton’s", "Moore’s", "Murphy’s", "Godwin’s", "Sharia", "Family", "Martial", "Bird", "Unthinkable Natural"},
	Oops_All_Luvdisc = {"Luvdisc is All You Need", "Compact Luvdisc", "Luvdisc thy Neighbor", "Luvdisc Golf", "Luvdiscworld", "Luvdisc and Hate", "rCSIDVULution", "HP Luvdiscraft", "Floppy Luvdisc", "Luvdiscord", "P.S. I Luvdisc You", "Tainted Luvdisc", "Crazy Little Thing Called Luvdisc", "Luvdisc in the Time of Cholera", "Luvdisc Galaxy", "Dr. Strangeluvdisc, or, How I Learned to Stop Worrying and Luv the Disc"},
	Fictional_Bands = {"Spın̈al Tap", "Sex Bob-omb", "The Blues Brothers", "The Beets", "Gorillaz", "Dr. Fünke's 100% Natural Good-Time Family Band Solution", "Jem and the Holograms", "The Hex Girls", "Dingoes Ate My Baby", "Drive Shaft", "Dethklok", "Scrantonicity", "Limozeen", "The Rutles", "Josie and the Pussycats", "TwaüghtHammër"},
	Air_Bud_Cinematic_Universe = {"Air Bud", "Air Bud: Golden Receiver", "Air Bud: World Pup", "Air Bud: Seventh Inning Fetch", "Air Bud: Spikes Back", "Air Buddies", "Snow Buddies", "Space Buddies", "Santa Buddies", "Spooky Buddies", "Treasure Buddies", "Super Buddies", "The Search for Santa Paws", "Santa Paws 2: The Santa Pups", "MVP: Most Valuable Primate", "MXP: Most Extreme Primate"},
	People_Widely_Reputed_to_be_Among_the_Worst_Ever = {"Adolf Hitler", "Joseph Stalin", "Mao Zedong", "Pol Pot", "Charles Manson", "Vlad the Impaler", "Elizabeth Bathory", "Genghis Khan", "Jim Jones", "Kim Jong-un", "Judas Iscariot", "Caligula", "Maximilien Robespierre", "Jeffrey Dahmer", "Ted Bundy", "Brutus"},
	Steamed_Hams = {"Superintendent Chalmers", "Seymour Skinner", "An Unforgettable Luncheon", "Ruined Roast", "Delightfully Devilish", "Isometric Exercise", "Steamed Clams", "Krustyburger", "A Regional Dialect", "Aurora Borealis", "House On Fire", "Steamed Hams", "Trouble In Town Tonight", "A Good Time Had By All", "Old Family Recipe", "Mouth-Watering Hamburgers"},
	Scooby_Doo_Clones = {"Josie and the Pussycats in Outer Space","The Amazing Chan and the Chan Clan","Speed Buggy","Butch Cassidy and the Sundance Kids","Goober and the Ghost Chasers","Inch High, Private Eye","Dynomutt, Dog Wonder","Jabberjaw","Captain Caveman and the Teen Angels","Woofer and Whimper, Dog Detectives","The Galloping Ghost","Casper and the Angels","The New Shmoo","Pebbles, Dino & Bamm-Bamm","Fangface & Fangpuss","The All New Adventures of Mr T"},
	Cozy = {"Blanket", "Socks", "Jammies", "Rain or snow outside", "Fireplace going", "Hot cocoa", "Pet in lap", "No work or school tomorrow", "Sleep til noon", "Snacks", "Freshly laundered sheets", "Favorite movie on", "Curled up with a good book", "Early evening", "Fluffy pillows", "Eskimo kisses"},
	Obsolete_Social_Media = {"Google Plus","Friendster","Vine","MySpace","MSN","AOL","LiveJournal","Flickr","Digg","Yik Yak","Planet Cancer","NeoPets","Club Penguin","8chan","Bebo","UseNet"},
	Urban_Legends = {"Bloody Mary", "Sewer Alligators", "JATO Rocket Car", "Paul is Dead", "Satanic Ritual Abuse", "QAnon", "Polybius", "Bunny man with an ax", "Firefighting airplane scoops up scuba diver", "Call coming from inside the house", "Hook man killing teens at makeout point", "Waking up in a bathtub full of ice after having organs harvested", "Rat kings", "Bermuda triangle", "Cow tipping", "in Limbo"},
	Fun_Words = {"Tautological", "Shimmy", "Defenestrate", "Poppycock", "Discombobulated", "Finagle", "Shenanigan", "Whippersnapper", "Kerfuffle", "Onomatopoeia", "Correctomundo", "Dongle", "Bodacious", "Canoodle", "Oeuvre", "Vajazzle"},
	Mario_64_Tech = {"Backwards Long Jump", "Hat-in-Hand Glitch", "Scuttlebug Raising", "Half A-Press", "Cloning", "Hyper Speed Walking", "Parallel Universes", "Spawning Displacement", "Vertical Speed Conservation", "Pause Buffering", "Indefinite Owl Flight", "Glitchy Wall Kick", "Astral Projection", "SheNaNigans", "Bully Battery", "Object Adoption"},
	Homophones = {"See","Sea","Si","C","Sense","Scents","Cents","Cense","Paws","Pause","Pores","Pours","Right","Rite","Wright","Write"},
	Google_Autocomplete_For_Why_Is = { "the sky blue?","it called Covid-19?","my eye twitching?","my period late?","biodiversity important?","420 Weed Day?","Pluto not a planet?","Australia in Eurovision?","everything made in China?","Ferrari so slow?","Jesus important?","Shakespeare relevant?","Vancouver so liveable?","Xbox download speed slow?","yawning contagious?","73 the best number?"},
	Touhou_Spell_Cards = {'\nTalisman "Exorcism of the Newspaper Subscription Solicitors"', '\nNative God "Froggy Braves the Wind and Rain"', '\nHeart Flower "Camera-Shy Rose"', '\nNew Impossible Request "Seamless Ceiling of Kinkaku-ji"', '\nLove Sign "Master Spark"', '\nIce Sign "Icicle Fall"', '\nSecret Barrage "And Then Will There Be None?"', '\nKappa "Exteeeending Aaaaarm"', '\n"Resurrection Butterfly -30% Reflowering-"', '\nWill-o\'-Wisp "Superdense Phosphorus Disaster Art"', '\n"Apollo Hoax Theory"', '\nCatfish "All-Electrical for Ecology!"', '\nAtomic Fire "Uncontainable Nuclear Reaction"', '\nThunderous Yell "A Scolding from a Traditional Old Man"', '\nInchling "One-Inch Samurai with a Half-Inch Soul"', '\nGun Sign "3D Printer Gun"'},
	Race_Horses = {"Potoooooooo", "Hoof Hearted", "Arrrrrrrrrrrrrrrr", "Bofa Deez Nuts", "Fiftyshadesofhay", "Flat Fleet Feet", "Luv Gov", "Notacatbutallama", "Panty Raid", "Citation", "The Last Sarami", "That's What She Said", "Definitly Red", "Whatamichoppedliver", "Atswhatimtalknbout", "Cat Thief"},
	Simpsons_Gags = {"Old Man Yells at Cloud", "Boo-urns", "Cromulent", "Works on contingency? No, money down!", "Lousy Smarch weather", "Steamed hams", "Lisa needs braces", "Stupid sexy Flanders", "TRAMAMPOLINE! TRABAPOLINE!", "Die Bart Die", "The goggles do nothing!", "Abortions for some, miniature American flags for others!", "Alf is back. In Pog form!", "My son's name is also Bort.", "You need to do some *serious* boning.", "Worst day of your life *so far*."},
	Wikipedia_Articles_Singable_To_The_TMNT_Theme = {"Legal Status of Alaska","San Francisco AIDS Foundation","Legends of the Hidden Temple","Texas Tax Reform Commission","Bridge Disasters in Palau","Stony Range Botanic Garden","Ace Venture: Pet Detective","Women Science Fiction Authors","Six Degrees of Kevin Bacon","Maple Syrup Urine Syndrome","Places Named for Adolf Hitler","Edgar Allan Poe Museum","List of Turkish Film Directors","Journal of Mundane Behaviour","Global Climate Action Summit","List of Postal Codes in Sweden"},
	Smash_Bros_Characters = {"Minecraft Steve", "Cloud Strife", "Ryu", "Ken", "Banjo & Kazooie", "Solid Snake", "Ridley", "King K. Rool", "Joker", "Simon Belmont", "Richter Belmont", "Bayonetta", "Pac Man", "Mega Man", "Sans Undertale", "Mario"},
	Nic_Cage_Films = {"National Treasure", "Face/Off", "The Wicker Man", "World Trade Center", "Kick-Ass", "Left Behind", "Con Air", "The Rock", "Honeymoon in Vegas", "Matchstick Men", "Lord of War", "Drive Angry", "Snake Eyes", "Vampire's Kiss", "Inconceivable", "The Unbearable Weight of Massive Talent"},
	Food_Mascots = {"Cheesasaurus Rex", "Koolaid Man", "Jolly Green Giant", "Mr. Delicious", "Chef Boyardee", "Mr. Peanut", "Colonel Sanders", "Count Chocula", "The Noid", "Chester Cheetah", "Aunt Jemimah", "Burger King King", "Snap Crackle & Pop", "Pillsbury Doughboy", "Charles Entertainment Cheese", "The Michelin Man", "Milkwalker"}
}

-- Table definitions for injoke cards that only get pulled up on specific servers can be placed in a separate file
local SERVER_LIST = {}
if misc.fileExists("plugins/server-specific/Chameleon-SP.lua") then
	SERVER_LIST = require("plugins/server-specific/Chameleon-SP")
end

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function chameleon.startGame(message)
	local state = {
		GameChannel = message.channel,
		Wordlist = nil,
		WordIdx = math.random(16),
		PlayerList = message.mentionedUsers,
		Chameleon = nil,
		Words = {}
	}

	local wordlistsForThisGame = {}
	-- Do we want custom cards?
	local args = message.content:split(" ")
	if args[3] ~= "vanilla" then
		misc.fuseDicts(wordlistsForThisGame, WORDLISTS_CUSTOM)
		-- If so, do we have server cards?
		for server,list in pairs(SERVER_LIST) do
			if message.guild.id == server then misc.fuseDicts(wordlistsForThisGame, list) end
		end
	end
	-- Do we want vanilla cards?
	if args[3] ~= "custom" then
		misc.fuseDicts(wordlistsForThisGame, WORDLISTS_VANILLA)
	end
	-- Do we want to just pick the card?
	if wordlistsForThisGame[args[3]] ~= nil then
		state["Wordlist"] = args[3]
	else
		state["Wordlist"] = misc.getRandomIndex(wordlistsForThisGame)
	end
	state["Words"] = wordlistsForThisGame[state["Wordlist"]]

	state["Chameleon"] = misc.getRandomIndex(message.mentionedUsers)
	local roll = math.random(1000)
	if roll < 15 then
		if message.guild.id == "353359832902008835" then
			dmStatus(state) -- Removed from server by request
		else
			oopsAllChameleons(state) -- 0.015% chance; if you're Chameleon, there is a ~5.5% chance it's this easter egg
		end
	elseif roll < 35 then
		if message.guild.id == "353359832902008835" then
			dmStatus(state)
		else
			oopsAlmostAllChameleons(state) -- 0.02% chance; if you're Chameleon, there is a ~5.5% chance it's this easter egg
		end
	else
		dmStatus(state) -- If you're Chameleon, there is an ~11.0% chance it's an easter egg, and an ~89% chance it's normal
	end
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
	for idx,word in pairs(state["Words"]) do
		if bold and idx == state["WordIdx"] then output = output .. "**__[" .. word .. "]__**, "
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

function oopsAllDifferentWords(state)
	words = {}
	for id,player in pairs(state["PlayerList"]) do
		-- Get random word that hasn't been picked yet
		-- 
	end
end

function oopsAlmostAllChameleons(state)
	for id,player in pairs(state["PlayerList"]) do
		player:send(displayWords(state, (id == state["Chameleon"])))
	end
end

function oopsAllChameleons(state)
	for id,player in pairs(state["PlayerList"]) do
		player:send(displayWords(state, false))
	end
end

return chameleon