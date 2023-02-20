local games = require("Games")
local misc = require("Misc")

local fastlength = {}
fastlength.desc = "An implementation of exactly one round of Wavelength. One player is given a card with an axis on it, and a position on that axis, from -10 to 10. Their goal is to say a word that other players will place at roughly that position on the axis."
fastlength.rules = "https://www.ultraboardgames.com/wavelength/game-rules.php> but with no scoring"

local getAxisString

--#############################################################################################################################################
--# Configurations                                                                                                                            #
--#############################################################################################################################################

local AXES = {"GOOD or BAD?", "NOT ADDICTIVE or VERY ADDICTIVE?", "HOT or COLD?", "NORMAL or WEIRD?", "FEELS GOOD or FEELS BAD?", "UNNECESSARY or ESSENTIAL?", "RARE or COMMON?", 
"EMOJI NO SEXY or EMOJI SEXY?", "FAMOUS or OBSCURE?", "DIFFICULT TO USE or EASY TO USE?", "PEPPY or GRUMPY?", "FANTASY or SCI-FI?", "CASUAL or FORMAL?", "PROHIBITED or ENCOURAGED?", 
"SMELLS GOOD or SMELLS BAD?", "BAD MOVIE or GOOD MOVIE?", "NOT A SANDWICH or A SANDWICH?", "INTROVERT or EXTROVERT?","HAPPENS SLOWLY or HAPPENS SUDDENLY?","LOVED or HATED?",
"UNETHICAL or ETHICAL?","WORTHLESS or PRICELESS?","UNFASHIONABLE or FASHIONABLE?","ROLE MODEL or BAD INFLUENCE?","PEACEFUL or WARLIKE?","ROUGH or SMOOTH?","SUSTENANCE or HAUTE CUISINE?",
"HAS A BAD REPUTATION or HAS A GOOD REPUTATION?","BETTER HOT or BETTER COLD?","UNSEXY ANIMAL or SEXY ANIMAL?","ARTISANAL or MASS PRODUCED?","REPLACEABLE or IRREPLACEABLE?","INEFFECTIVE or EFFECTIVE?",
"ROUND or POINTY?","SAD MOVIE or HAPPY MOVIE?","TRASHY or CLASSY?","UNDERPAID or OVERPAID?","COMEDY or DRAMA?","SCARY ANIMAL or NICE ANIMAL?","DRY or WET?","NOBODY DOES IT or EVERYBODY DOES IT?",
"FORBIDDEN or ENCOURAGED?","STAR WARS or STAR TREK?","FRAGILE or DURABLE?","GOOD or EVIL?","LEAST EVIL COMPANY or MOST EVIL COMPANY?","BAD HABIT or GOOD HABIT?",
"GUILTY PLEASURE or OPENLY LOVE?","USELESS BODY PART or USEFUL BODY PART?","UNFORGIVABLE or FORGIVABLE?","HARMLESS or HARMFUL?","UNHYGENIC or HYGENIC?","USELESS or USEFUL?",
"UNIMPORTANT or IMPORTANT?","VICE or VIRTUE?","UNPOPULAR ACTIVITY or POPULAR ACTIVITY?","UNRELIABLE or RELIABLE?","TASTES BAD or TASTES GOOD?","UNCOOL or COOL?","UNDERRATED or OVERRATED?",
"WEAK or STRONG?","USELESS INVENTION or USEFUL INVENTION?","UNPOPULAR or POPULAR?","BORING or EXCITING?","VILLAIN or HERO?","USELESS IN AN EMERGENCY or USEFUL IN AN EMERGENCY?",
"WISE or INTELLIGENT?","DANGEROUS or SAFE?","BAD PIZZA TOPPING or GOOD PIZZA TOPPING?","NORMAL THING TO OWN or WEIRD THING TO OWN?","HARD TO REMEMBER or EASY TO REMEMBER?",
"UGLY MAN or BEAUTIFUL MAN?","UNCONTROVERSIAL TOPIC or CONTROVERSIAL TOPIC?","UNDERRATED MOVIE or OVERRATED MOVIE?","USELESS MAJOR or USEFUL MAJOR?",
"FREEDOM FIGHTER or TERRORIST?","NATURE or NURTURE?","BORING HOBBY or INTERESTING HOBBY?","LIGHT SIDE OF THE FORCE or DARK SIDE OF THE FORCE?",
"JOB or CAREER?","BOOK WAS BETTER or MOVIE WAS BETTER?","POORLY MADE or WELL MADE?","UGLY or BEAUTIFUL?","SNACK or MEAL?",
"SHORT LIVED or LONG LIVED?","MAINSTREAM or NICHE?","QUIET PLACE or LOUD PLACE?","WASTE OF TIME or GOOD USE OF TIME?",
"PROOF THAT GOD EXISTS or PROOF THAT GOD DOESN'T EXIST?","WORST ATHLETE OF ALL TIME or GREATEST ATHLETE OF ALL TIME?","LOW QUALITY or HIGH QUALITY?",
"PLAIN or FANCY?","BAD FOR YOU or GOOD FOR YOU?","CAT PERSON or DOG PERSON?","WORST DAY OF THE YEAR or BEST DAY OF THE YEAR?","GEEK or DORK?",
"SAD SONG or HAPPY SONG?","UNDERRATED SKILL or OVERRATED SKILL?","UNBELIEVABLE or BELIEVABLE?","BAD SUPERPOWER or GOOD SUPERPOWER?",
"STUPID or BRILLIANT?","SQUARE or ROUND?","SOFT or HARD?","DIVIDED or WHOLE?","UNDERRATED MUSICIAN or OVERRATED MUSICIAN?","EASY TO SPELL or HARD TO SPELL?",
"MOVIE THAT GODZILLA WOULD RUIN or MOVIE THAT GODZILLA WOULD IMPROVE?","BAD MUSIC or GOOD MUSIC?","GRYFFINDOR or SLYTHERIN?","FAILURE or MASTERPIECE?",
"FAD or CLASSIC?","UNTALENTED or TALENTED?","INESSENTIAL or ESSENTIAL?","UNDERRATED THING TO DO or OVERRATED THING TO DO?",
"SMELLY IN A BAD WAY or SMELLY IN A GOOD WAY?","FRIEND or ENEMY?","LIBERAL or CONSERVATIVE?","DISGUSTING CEREAL or DELICIOUS CEREAL?",
"MESSY FOOD or CLEAN FOOD?","WORST LIVING PERSON or GREATEST LIVING PERSON?","SPORT or GAME?","EASY TO KILL or HARD TO KILL?",
"MENTAL ACTIVITY or PHYSICAL ACTIVITY?","HARD TO FIND or EASY TO FIND?","LOWBROW or HIGHBROW?","STRAIGHT or CURVY?","DYSTOPIA or UTOPIA?",
"CULTURALLY SIGNIFICANT or CULTURALLY INSIGNIFICANT?","HARD TO DO or EASY TO DO?","FOR KIDS or FOR ADULTS?","UNDERRATED ACTOR or OVERRATED ACTOR?",
"BAD or GOOD?","HARD TO PRONOUNCE or EASY TO PRONOUNCE?","OPTIONAL or MANDATORY?","ETHICAL TO EAT or UNETHICAL TO EAT?","80S or 90S?",
"MATURE PERSON or IMMATURE PERSON?","MEAN PERSON or NICE PERSON?","TEMPORARY or PERMANENT?","TRADITIONALLY MASCULINE or TRADITIONALLY FEMININE?",
"ROUND ANIMAL or POINTY ANIMAL?","INFLEXIBLE or FLEXIBLE?","HAIRLESS or HAIRY?","UNHEALTHY or HEALTHY?","UNDERRATED WEAPON or OVERRATED WEAPON?",
"COLORLESS or COLORFUL?","UNKNOWN or FAMOUS?","BAD ACTOR or GOOD ACTOR?","FLAVORLESS or FLAVORFUL?",
"DIRTY or CLEAN?","DRY FOOD or WET FOOD?","BAD TV SHOW or GOOD TV SHOW?","LOOKS LIKE A PERSON or DOESN'T LOOK LIKE A PERSON?",
"ACTION MOVIE or ADVENTURE MOVIE?","UNDERRATED THING TO OWN or OVERRATED THING TO OWN?","BAD PERSON or GOOD PERSON?","MOVIE or FILM?",
"UNDERRATED LETTER OF THE ALPHABET or OVERRATED LETTER OF THE ALPHABET?","ORDINARY or EXTRAORDINARY?","MILDLY ADDICTIVE or HIGHLY ADDICTIVE?",
"DARK or LIGHT?","BORING TOPIC or FASCINATING TOPIC?","BASIC or HIPSTER?","DANGEROUS JOB or SAFE JOB?","TIRED or WIRED?",
"EASY SUBJECT or HARD SUBJECT?","LOW CALORIE or HIGH CALORIE?","CHEAP or EXPENSIVE?","BAD MAN or GOOD MAN?","NORMAL PET or EXOTIC PET?",
"UNSTABLE or STABLE?","NEED or WANT?","REQUIRES LUCK or REQUIRES SKILL?"}
local CUSTOM_AXES = {"BEST GIRL or SHIT TIER?", "PREFERS SUBS or PREFERS DUBS?", "PURE or CORRUPT?", "FIGHTER or WIZARD?", "DOMME or SUB?", "TOP or BOTTOM?", "PLEBIAN or PATRICIAN?",
"LOW QUALITY or HIGH QUALITY?", "SOFT or HARD?", "SOUR or SWEET?", "GAY or STRAIGHT?", "OLD or NEW?", "NERDY or HIP?", "FASHIONABLE or PRACTICAL?", "PRO GAMER or CASUAL SCRUB?",
"WORTHLESS or PRICELESS?", "UGLY or BEAUTIFUL?", "COWARDLY or BRAVE?", "HIGH or LOW?", "10 or -10?", "JIMMY BUFFETT or KENNY CHESNEY?", "SMALL or LARGE?", "WET or DRY?", "LEWD or PRUDE?",
"DAY or NIGHT?", "BREAKFAST or DINNER?", "RISKY or SAFE?", "DISGUSTING or ALLURING?", "SIMPLE or COMPLEX?", "NEAT or MESSY?", "CONTROVERSIAL or UNDISPUTED?", "BOAT or FRESH PRINCE?", "PRE- or POST-HUMPHREY?"}

-- Custom axes are ON by default
misc.fuseLists(AXES, CUSTOM_AXES)

--#############################################################################################################################################
--# Main Functions                                                                                                                            #
--#############################################################################################################################################

function fastlength.startGame(message, players)
	local state = {
		Psychic = message.author,
		Axis = AXES[math.random(#AXES)],
		Axis2 = AXES[math.random(#AXES)],
		HardMode = false,
		Value = math.random(-10,10),
		Value2 = math.random(-10,10),
		GameChannel = message.channel
	}

	args = message.content:split(" ")
	if #args > 2 and string.upper(args[3]) == "2D" then state["HardMode"] = true end

	-- DM the author to let them know
	if state["HardMode"] then
		-- Two axes
		local valuesMsg = "Your target values are: " .. state["Value"] .. " and " .. state["Value2"] .. "\n"
		local axesMsg = "The axes are: " .. state["Axis"] .. " and " .. state["Axis2"] .. "\n"
		local axesGraph = getAxisString(state["Value"], state["Axis"]) .. "\n" .. getAxisString(state["Value2"], state["Axis2"])
		message.author:send(valuesMsg .. axesMsg .. axesGraph)
		message.channel:send(axesMsg)
	else
		message.author:send("Your target value is: " .. state["Value"] .. "\n" .. "The axis is: " .. state["Axis"] .. "\n" .. getAxisString(state["Value"], state["Axis"]))
		message.channel:send("The axis is: " .. state["Axis"])
	end

	-- Create a new game and register it
	state.GameID = games.registerGame(message.channel, "Fastlength", state, {message.author})
end

function fastlength.commandHandler(message, state)
	local args = message.content:split(" ")

	if args[1] == "!reveal" then
		if state["HardMode"] then
			local outputMsg = "The target values are: " .. state["Value"] .. " and " .. state["Value2"] .. "\n"
			outputMsg = outputMsg .. getAxisString(state["Value"], state["Axis"]) .. "\n" .. getAxisString(state["Value2"], state["Axis2"])
			message.channel:send(outputMsg)
		else
			message.channel:send("The target value is... " .. state["Value"] .. "\n" .. getAxisString(state["Value"], state["Axis"]))
		end
		games.deregisterGame(state["GameID"])
	end
end

--#############################################################################################################################################
--# Game Functions                                                                                                                            #
--#############################################################################################################################################

function getAxisString(pos, axis)
	local orPos = axis:find("or")
	local words = {axis:sub(1,orPos-2), "or", axis:sub(orPos+3,-1)}
	local output = words[1] .. " <"
	
	if pos == nil then output = output .. "----------|----------"
	elseif pos == 0 then output = output .. "----------X----------"
	else
		adjPos = pos + 10
		if adjPos < 10 then adjPos = adjPos + 1 end -- Don't ask me why. 
		for i=1,20 do
			if i == adjPos then output = output .. "X" else output = output .. "-" end
			if i == 10 then output = output .. "|" end
		end
	end

	output = output .. "> " .. words[3]:sub(1,-2)
	return output
end

return fastlength