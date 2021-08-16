local games = require("Games")
local misc = require("Misc")
local deception = {}

local WEAPONS = {
	"Hook", "Scarf", "Arsenic", "Saxophone", "Pistol", "Bat", "Lab Sample", "Wrench",
	"Rope", "Stone", "Surgery", "Chainsaw", "Locked Room", "Spork", "Hammer", "Arson", "Bamboo Tip",
	"Packing Tape", "Folding Chair", "Metal Chain", "Drown", "Explosives", "Liquid Drug", "Machine",
	"Belt", "Steel Pipe", "Virus", "Pillow", "Work", "Smoke", "Shipping Container", "Pesticide",
	"Unarmed", "Venomous Scorpion", "Brick", "Bite & Tear", "Overdose", "Trowel", "Machete", "Plastic Bag",
	"Kick", "Chemicals", "Electric Baton", "Kerosene", "Throat Slit", "Injection", "Whip", "Sniper",
	"Cutlery", "Dumbbell", "Video Game Console", "Blood Released", "Plague", "Illegal Pills", "Dirty Water",
	"Electric Current", "Trophy", "Towel", "Ice Skate", "Medical Pills", "Poisonous Gas", "Spoiled Food",
	"Sculpture", "Microphone", "Poisonous Mushroom", "Poisonous Needle", "Buried Alive", "Axe",
	"Powder Drug", "Sulfuric Acid", "Attack Dog", "Matches", "Amoeba", "Cleaver", "Gunpowder", "Razor Blade",
	"Electric Wire", "Dice Tower", "Lighter", "Alcohol", "Punch", "Webcam", "Potted Plant", "Anthrax",
	"Metal Wire", "Elevator Shaft", "Venomous Snake", "Starvation", "Blender", "Push", "Ladder", "Radiation",
	"Dismember", "Scissors", "Drill", "Cleaning Alcohol", "Dagger", "Mercury", "Game Pieces", "Candlestick",
	"Box Cutter", "Crutches", "Scooter"
}

local EVIDENCE = {
	"Magazine", "Herbal Medicine", "Eggs", "Gift", "Jewelry", "Dice", "Lipstick", "Book",
	"Stuffed Teddy", "Office Supplies", "Confidential Letter", "Sunglasses", "Rat", "Gloves", "Suit", "Cockroach",
	"Candy", "Skull", "Umbrella", "Password", "Numbers", "Uniform", "Hourglass", "Love Letter", "Spider",
	"Panties", "Table Lamp", "Cotton", "Coins", "Violin", "Helmet", "Website", "Cassette Tape", "Note", "USB Flash",
	"Ink", "Betting Chips", "Electric Circuit", "Postal Stamp", "Fingernails", "Cigarette Butt", "Newspaper",
	"Online Video", "Receipt", "Red Wine", "Paint", "Sack", "Diary", "Lunch Box", "Oil Painting", "Boxer Briefs",
	"Rubber Stamp", "Cleaning Cloth", "Calendar", "Photograph", "Watch", "Headset", "Antique", "Toy Model",
	"Table Bell", "Pocket Watch", "Surveillance Camera", "Toothpick", "Exam Paper", "Specimen", "Timber",
	"Lottery Ticket", "Flute", "Ice", "Bandage", "Peanut", "Spa Mask", "Bone", "Badge", "Sock", "Domino Pieces",
	"Earrings", "Lens", "Iron", "Vegetables", "Fiber Optics", "Leather Shoes", "Luggage", "Necklace",
	"Chalk", "Tie", "Blood", "Mask", "Yo-Yo", "Telephone", "I.O.U. Note", "Bread", "Trilby Hat", "Food Ingredients",
	"Computer", "Apple", "Dirt", "Sawdust", "Signature", "Dentures", "Riddle", "Dictionary", "Glue", "I.D. Card",
	"Cupcake", "Test Tube", "Ring", "Oil", "Air Conditioner", "Nail", "Cat", "Toy Blocks", "Stocking", "Safety Pin",
	"Mosquito", "Wallet", "Plant", "Comics", "Juice", "Seasoning", "Spring", "Jacket", "Ethernet Cable", "Take-Out",
	"Light Bulb", "Menu", "Mark", "Hair", "Coffee", "Map", "Leather Bag", "Banknote", "Envelope", "Dog Fur", "Leaf",
	"Puppet", "Certificate", "Cigar", "Mirror", "High Heels", "Fax Machine", "Cardboard Box", "Handcuffs", "Playing Cards",
	"Note Book", "Invitation Card", "Tripod", "Tissue", "Plastic Bottle", "Flyer", "Surgical Mask", "Lock", "Tool Box",
	"Cigarette Ash", "Sponge", "Toy Car", "Maze Puzzle", "Speakers", "Tweezers", "Diamond", "Needle and Thread",
	"Video Camera", "Floppy Disk", "Push Pin", "I.V. Bag", "Documents", "Wig", "Cup", "Bullet", "Raincoat", "Key",
	"Mosquito Coil", "Prescription Note", "Rose", "Fan", "Hanger", "Tea Leaves", "Hairpin", "Broom", "Gear", "Sand",
	"Curtains", "Button", "Perfume", "Mobile Phone", "Flashlight", "Hat", "Crate", "Tattoo", "Name Card", "Soft Drink",
	"Insect", "Dust", "Flip-Flop", "Soap", "Ants", "Syringe", "Computer Mouse", "Snacks", "Jigsaw Puzzle", "Powder",
	"Cake", "Bracelet", "Graffiti", "Switch"
}

local SCENES = {
	["Victim's Build"] = {"Large/Overweight", "Small/Underweight", "Tall", "Short", "Healthy/Muscular", "Average"},
	["General Impression"] = {"Common", "Uncommon", "Suspicious", "Cruel", "Horrible", "Accident"},
	["Motive of Crime"] = {"Hatred", "Power", "Money", "Love", "Jealousy", "Justice"},
	["Victim's Expression"] = {"Peaceful", "Struggling", "Frightened", "In Pain", "Blank", "Angry"},
	["Discovered By"] = {"Relative", "Neighbor", "Friend", "Colleague", "Lover", "Stranger"},
	["Sudden Incident"] = {"Power Failure", "Fire", "Conflict", "Loss of Valuables", "Scream", "Nothing"},
	["Trace at the Scene"] = {"Fingerprint", "Footprint", "Bruise", "Blood Stain", "Bodily Fluid", "Scar"},
	["Noticed Because"] = {"Sudden Sound", "Prolonged Sound", "Smell", "Visual", "Physically", "Not Noticed"},
	["Social Relationship"] = {"Relatives", "Friends", "Colleagues", "Employer/Employee", "Lovers", "Strangers"},
	["Corpse Condition"] = {"Still Warm", "Stiff", "Decayed", "Incomplete", "Intact", "Twisted"},
	["State of the Scene"] = {"Bits and Pieces", "Ashes", "Water Stain", "Cracked", "Disorderly", "Tidy/Untouched"},
	["Duration of the Crime"] = {"Instantaneous", "Quick", "Gradual", "Prolonged", "Days", "Unclear"},
	["Action in Progress"] = {"Entertainment", "Relaxation", "Meeting/Visit", "Trading", "Work", "Dining"},
	["Victim's Identity"] = {"Child", "Young Adult", "Middle-Aged", "Senior", "Male", "Female"},
	["Hint on Corpse"] = {"Head", "Torso", "Limbs", "Face", "Partial", "All-Over"},
	["Time of Death"] = {"Dawn", "Morning", "Noon", "Afternoon", "Evening", "Late Night"},
	["Murderer's Personality"] = {"Arrogant", "Despicable", "Furious", "Greedy", "Desperate", "Perverted"},
	["Victim's Occupation"] = {"Boss", "Professional", "Worker", "Student", "Unemployed", "Retired"},
	["Weather"] = {"Sunny", "Stormy", "Dry", "Humid", "Cold", "Hot"},
	["Day of Crime"] = {"Weekday", "Weekend", "Spring", "Summer", "Autumn", "Winter"},
	["Time Until Discovery"] = {"Immediate", "Minutes", "Hours", "Days", "Weeks", "Months or More"}
	["Murderer's Build"] = {"Large/Overweight", "Small/Underweight", "Tall", "Short", "Healthy/Muscular", "Average"},
	["Evidence Left Behind"] = {"Natural", "Creative", "Written", "Synthetic", "Personal", "Unrelated"},
	["Victim's Clothes"] = {"Neat", "Untidy", "Formal", "Casual", "Bizarre", "Naked"},
	["Type of Killer"] = {"Amateur", "Serial Killer", "Contract Killer", "Sexual Deviant", "Conflicted", "Unrelated"}
}

local LOCATIONS = {
	{"Vacation Home", "Park", "Supermarket", "School", "Woods", "Bank"},
	{"Bar", "Bookstore", "Restaurant", "Hotel", "Hospital", "Building Site"},
	{"Playground", "Classroom", "Dormitory", "Cafeteria", "Elevator", "Public Toilet"},
	{"Living Room", "Bedroom", "Storeroom", "Bathroom", "Kitchen", "Balcony"}
}

local CAUSES = {
	{"Suffocation", "Severe Injury", "Loss of Blood", "Illness/Disease", "Poisoning", "Accident"}
}

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function deception.startGame(message)
end

function deception.commandHandler(message, state)
end

function deception.dmHandler(message, state)
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################



return deception