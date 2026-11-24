-------------------------------------------------
-- EventBanner.lua
-- Sleek slide-in banner for big world events:
--   * milestones: game year, first civ to a tech / unit / building
--   * wars declared
--   * declarations of friendship signed
--   * defensive pacts signed
--   * cities captured (+ "preparing a nuclear strike" warning)
--   * nuclear strikes on cities
--
-- Design notes (performance + multiplayer):
--  * 100% client-side UI. It only READS game state. It never changes
--    gameplay, never uses LuaEvents/network calls -> cannot desync.
--  * No per-frame work while idle. The update callback is only registered
--    while a banner is on screen and is cleared afterwards.
--  * Milestones, treaties and the city-population snapshot are handled by a
--    tiny poll once per turn. Wars, captures and nuclear strikes use events
--    the game already fires (no polling at all).
--  * Every client sees the same game state, so every client independently
--    reaches the same result.
--  * The first poll after load is silent, so loading a save never replays
--    old events.
--  * Random text uses math.random on the UI side only. It never touches the
--    gameplay RNG, so it cannot desync.
-------------------------------------------------
include("IconSupport")

-------------------------------------------------
-- CONFIG: timing / look
-------------------------------------------------
local SLIDE_TIME      = 1.5   -- seconds for slide in / out (match Speed in the XML)
local HOLD_TIME       = 11.0    -- seconds the banner stays fully shown
local GAP_TIME        = 0.80   -- pause between queued banners
local MAX_QUEUE       = 8      -- oldest queued banner is dropped beyond this
local CIV_ICON_SIZE   = 128    -- must match the civ icon images in EventBanner.xml
local EVENT_ICON_SIZE = 128    -- left icon size (falls back to 64 if the atlas has no 128)

-- Civs you have not met are still announced, but shown anonymously:
-- the name becomes UNKNOWN_CIV_NAME and the civ icon becomes the "?" icon.
-- true  = reveal the real civ even if you haven't met them.
-- false = hide unmet civs behind "Unknown Civ" (default).
local REVEAL_UNMET_CIVS = false
local UNKNOWN_CIV_ADJ = "Unknown"      -- adjective for civs you haven't met
local UNKNOWN_CIV_NAME  = "Unknown Civ"
local UNKNOWN_CITY_NAME = "an unknown city"   -- {CITY} for civs you haven't met (hides where it happened)
local CITY_FALLBACK     = "a city"            -- {CITY} when no city could be worked out

-------------------------------------------------
-- TREATY ICON (friendship + defensive pact)
--
-- Set this to the game's defensive pact icon. Two forms are supported:
--     local TREATY_ICON = { texture = "TheFileName.dds" }
--     local TREATY_ICON = { atlas = "SOME_ATLAS", index = 3 }
-- To find it: search the game's UI files (e.g. DiploList.xml / DiploOverview.xml,
-- in Assets/UI/InGame) for "DefensivePact" and copy the Texture / atlas it uses.
-- While this is nil, treaty banners show the two civ flags instead.
-------------------------------------------------
local TREATY_ICON = nil

-------------------------------------------------
-- NUKE ICON / NUKE DETECTION
--
-- Tsar Bomba icon. nil = auto-find the unit that uses UnitArtInfo ART_DEF_UNIT_ATOMIC_BOMB
-- with UnitFlagIconOffset 80. Set a unit key (e.g. "UNIT_TSAR_BOMBA") to force a specific
-- unit's icon (use this if your normal atomic bomb also uses flag offset 80).
-------------------------------------------------
local NUKE_ICON_UNIT = nil
-- Fallback list used to decide whether a civ "has nuclear weapons" if the game can't tell us.
local NUKE_UNIT_KEYS = { "UNIT_ATOMIC_BOMB", "UNIT_NUCLEAR_MISSILE" }

-------------------------------------------------
-- TEXT TOKENS (use inside any title / desc)
--   milestones : {CIV} {CIV_ADJ} {CITY}      ({CITY} = city the UNIT / BUILDING was built in, or a city of the civ for TECH; not set for YEAR)
--   war        : {AGGRESSOR} {DEFENDER}      ({CIV} = aggressor)   + {AGGRESSOR_ADJ} {DEFENDER_ADJ}
--   friendship : {CIV1} {CIV2}               (you are CIV1 if you are involved)   + {CIV1_ADJ} {CIV2_ADJ}
--   pact       : {CIV1} {CIV2}               + {CIV1_ADJ} {CIV2_ADJ}
--   capture    : {NEW} {OLD} {CITY}          ({CIV} = new owner)   + {NEW_ADJ} {OLD_ADJ}
--   nuke warn  : {OLD} {NEW} {CITY}          ({CIV} = old owner)   + {OLD_ADJ} {NEW_ADJ}
--   nuke strike: {LAUNCHER} {OWNER} {CITY} {CASUALTIES}   + {LAUNCHER_ADJ} {OWNER_ADJ}
-- Titles / descs may be plain text or TXT_KEYs.
-- Give a group several `variants` and one is picked at random each time
-- (never the same one twice in a row). A single title/desc also works:
--     { title = "...", desc = "..." }
-------------------------------------------------

-------------------------------------------------
-- MILESTONES  (edit this list)
--
--  kind     "YEAR"     year = number                     (fires once when game year >= year)
--           "TECH"     key = "TECH_xxx"                  (first civ to know the tech; always shows the tech's own icon)
--           "UNIT"     key = "UNIT_xxx"                  (first civ to own one; matches by unit class)
--           "BUILDING" key = "BUILDING_xxx"              (first civ to have one; matches by building class)
--  icon     optional custom .dds. YEAR events need one. UNIT / BUILDING use the game's own icon
--           when you leave it out. TECH ignores it (tech icon is always used).
--  showCiv  false hides the civ icon (YEAR events never show one)
-------------------------------------------------
local EVENTS = {
    --------------------------------------------------
    -- YEAR
    --[[ disabled until textures are set 
    {
      id = "ZERO_AD",
      kind = "YEAR", year = 0,
      icon = "EB_ZeroAD.dds",
      title = "The Dawn of a New Age",
      desc  = "The world has reached 0 AD." },
    
    {
      id = "2000_AD",
      kind = "YEAR", year = 2000,
      icon = "EB_ZeroAD.dds",
      title = "A New Millenium",
      desc  = "The world has reached 2000 AD." },
    ]]--

    --------------------------------------------------
    -- TECHS
    -- TECH_THE_WHEEL TECH_IRON_WORKING 
    --  TECH_CURRENCY  TECH_HORSEBACK_RIDING    
    --  TECH_STEEL TECH_ASTRONOMY  TECH_EDUCATION   
    --  TECH_SCIENTIFIC_THEORY TECH_GUNPOWDER   TECH_ECONOMICS
    -- TECH_STEAM_POWER TECH_INDUSTRIALIZATION  TECH_RAILROAD     
    -- TECH_FLIGHT  TECH_COMBUSTION TECH_DYNAMITE
    --  TECH_ATOMIC_THEORY  TECH_ELECTRONICS    TECH_REFRIGERATION
    --  TECH_NUCLEAR_FISSION    TECH_COMPUTERS  TECH_TELECOM
    --  TECH_INTERNET   TECH_LASERS TECH_NUCLEAR_FUSION TECH_GLOBALIZATION
    --  TECH_SPACE_TECHNOLOGY   TECH_INTERSTELLAR_TRAVEL    TECH_CLONING    TECH_ORBITAL_DEV    TECH_IMPLANTS
    --  TECH_ARCOLOGIES TECH_AUTONOMOUS_SYSTEMS TECH_ARTIFICIAL_INTELLIGENCE    TECH_HYPERSTRUCTURES    TECH_SPACE_COLONIZATION
    --  
    { id = "TECH_THE_WHEEL",
      kind = "TECH", key = "TECH_THE_WHEEL",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "A New Shape?",
      desc  = "Citizens in {CITY} have begun the use of strange objects to ease their burdens. Our people suggest this may need to be reinvented later." },

    { id = "TECH_IRON_WORKING",
      kind = "TECH", key = "TECH_IRON_WORKING",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Strange Metal Appears",
      desc  = "A new metal called 'Iron' has been spotted along trade routes originating from {CITY}. Many citizens suggest our Bronze will always be superior!" },

    { id = "TECH_CURRENCY",
      kind = "TECH", key = "TECH_CURRENCY",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Traders Reject Barter!",
      desc  = "In the markets of {CITY} traders no longer accept bartered goods and demand shiny trinkets instead. Will this barbarism spread to our towns too?" },

    { id = "TECH_HORSEBACK_RIDING",
      kind = "TECH", key = "TECH_HORSEBACK_RIDING",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Horses Enlisted",
      desc  = "The uncultured citizens of {CITY} have begun using horses for hunting. Many claim this is due to their inferior prowess." },

    { id = "TECH_STEEL",
      kind = "TECH", key = "TECH_STEEL",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Strange Metal Appears, Again?",
      desc  = "The forges of {CITY} churn a hardy new metal called 'Steel'. Many call for the regulation of this 'dangerous' new metal and call it a 'gimmick'." },

    { id = "TECH_ASTRONOMY",
      kind = "TECH", key = "TECH_ASTRONOMY",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Don't Look Up!",
      desc  = "Many people in {CITY} have begun strange traditions observing the night sky. Our council of priests claim nothing good will ever come of this." },

    { id = "TECH_EDUCATION",
      kind = "TECH", key = "TECH_EDUCATION",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Learning to Learn",
      desc  = "The citizens of {CITY} have opened the first schools to teach the youth. Critics claim the youth should be working the fields and barracks instead." },

    { id = "TECH_SCIENTIFIC_THEORY",
      kind = "TECH", key = "TECH_SCIENTIFIC_THEORY",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Thesis & Antithesis!",
      desc  = "Fledgling schools in {CITY} have evolved into advanced hubs of learning. Students however allege the burden of work taken home is 'too much!'." },

    { id = "TECH_GUNPOWDER",
      kind = "TECH", key = "TECH_GUNPOWDER",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Black Powder",
      desc  = "Reports of a strange black powder with immense powers have been coming out of {CITY}. Our Military confidently states this is a passing fad." },

    { id = "TECH_ECONOMICS",
      kind = "TECH", key = "TECH_ECONOMICS",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Buy High, Sell Low?",
      desc  = "Traders in {CITY} have begun offering 'shares' of their business for sale. Confused citizens say it is impossible to purchase a fraction of a store." },

    { id = "TECH_STEAM_POWER",
      kind = "TECH", key = "TECH_STEAM_POWER",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "The Future is a Kettle",
      desc  = "Innovators in {CITY} claim their new 'Steam Donkey' does the work of ten men. Our advisors state such 'toys' will fall into irrelevance soon." },

    { id = "TECH_INDUSTRIALIZATION",
      kind = "TECH", key = "TECH_INDUSTRIALIZATION",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Goodbye, Blue Sky",
      desc  = "Reports claim the sun has been blotted out by smoke in the town of {CITY}. Some claim this 'Industrial Revolution' may be a disaster for the human race." },

    { id = "TECH_RAILROAD",
      kind = "TECH", key = "TECH_RAILROAD",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "A Carriage of Steam",
      desc  = "A peculiar carriage has appeared in {CITY} that appears to run without horses. Our advisors state these are mere kettles on wheels." },

    { id = "TECH_FLIGHT",
      kind = "TECH", key = "TECH_FLIGHT",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Humanity's Dream Achieved",
      desc  = "Rumors of the first manned flight taking place in {CITY} has reached our shores. Have we finally entered an era of miracles?" },

    { id = "TECH_COMBUSTION",
      kind = "TECH", key = "TECH_COMBUSTION",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Infernal Engines",
      desc  = "Innovators in {CITY} claim their new engines require no steam! These new machines run on a sticky black liquid they claim causes no pollution." },

    { id = "TECH_DYNAMITE",
      kind = "TECH", key = "TECH_DYNAMITE",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "It All Started With a Bang",
      desc  = "Thunderous explosions are being heard in the mines outside {CITY}. The military is assessing if this may be put to less peaceful purposes." },

    { id = "TECH_ATOMIC_THEORY",
      kind = "TECH", key = "TECH_ATOMIC_THEORY",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "The Atom Split",
      desc  = "Scientists working for years in utmost secrecy in {CITY} have announced the splitting of the atom. Will this usher in an age of infinite energy?" },

    { id = "TECH_ELECTRONICS",
      kind = "TECH", key = "TECH_ELECTRONICS",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Electronic, Not Electric",
      desc  = "Advancements in circuitry are making nothing short of miracles possible. Researchers in {CITY} proclaim the future is now." },

    { id = "TECH_REFRIGERATION",
      kind = "TECH", key = "TECH_REFRIGERATION",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Atrophy Defeated",
      desc  = "At a conference in {CITY}, a jubilant researcher prepared to give a speech and wiped sweat off his brow: 'That won't be happening again'" },

    { id = "TECH_NUCLEAR_FISSION",
      kind = "TECH", key = "TECH_NUCLEAR_FISSION",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "I Am Become Death",
      desc  = "Many cheered, but a quiet {CIV_ADJ} scientist shuddered watching the nuclear test. He softly uttered, 'The last human will see what we saw'" },

    { id = "TECH_COMPUTERS",
      kind = "TECH", key = "TECH_COMPUTERS",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Machine in the Likeness of Man",
      desc  = "Researchers in {CITY} announce the invention of a machine that thinks like man. Quite fittingly its first application will be as missile guidance." },

    { id = "TECH_TELECOM",
      kind = "TECH", key = "TECH_TELECOM",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "The World Shrinks",
      desc  = "The first wireless networks have been established in {CITY}. Some critics suggest constant connectivity will bring about the death of intimacy." },

    { id = "TECH_INTERNET",
      kind = "TECH", key = "TECH_INTERNET",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "A Series of Tubes",
      desc  = "A network of computers has been established in {CITY} allowing instant connectivity. Critics claims this expensive system is not commercially viable." },

    { id = "TECH_NUCLEAR_FUSION",
      kind = "TECH", key = "TECH_NUCLEAR_FUSION",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "A {CIV_ADJ} Sun",
      desc  = "'We knew the world would not be the same. A few people laughed, a few people cried. Most people were silent.'" },

    { id = "TECH_SPACE_TECHNOLOGY",
      kind = "TECH", key = "TECH_SPACE_TECHNOLOGY",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "The Final Frontier?",
      desc  = "An unannounced launch was detected over the skies of {CITY}. The flaming hunk of metal broke through our atomspheric prison, man was now truly free." },
    
    --[[
    { id = "TECH_INTERSTELLAR_TRAVEL",
      kind = "TECH", key = "TECH_INTERSTELLAR_TRAVEL",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "First Manmade Object in Space",
      desc  = "A launch was detected over the skies of Do Not Go Gentle into that Good Night." },
    
    { id = "TECH_IMPLANTS",
      kind = "TECH", key = "TECH_IMPLANTS",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Philosophy Discovered",
      desc  = "{1_Civ} is the first to master philosophy." },

    { id = "TECH_AUTONOMOUS_SYSTEMS",
      kind = "TECH", key = "TECH_AUTONOMOUS_SYSTEMS",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Philosophy Discovered",
      desc  = "{1_Civ} is the first to master philosophy." },

    { id = "TECH_ARTIFICIAL_INTELLIGENCE",
      kind = "TECH", key = "TECH_ARTIFICIAL_INTELLIGENCE",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Philosophy Discovered",
      desc  = "{1_Civ} is the first to master philosophy." },

    { id = "TECH_SPACE_COLONIZATION",
      kind = "TECH", key = "TECH_SPACE_COLONIZATION",       -- custom .dds image
      icon = "EB_Philosophy.dds",
      title = "Philosophy Discovered",
      desc  = "{1_Civ} is the first to master philosophy." },
    ]]--

    --------------------------------------------------
    -- UNITS
    --  UNIT_SPARTAN300    UNIT_SWORDSMAN
    --  UNIT_TEUTONIC_KNIGHT    
    --  UNIT_CARAVEL    UNIT_TREBUCHET  UNIT_KNIGHT UNIT_CROSSBOWMAN
    --  UNIT_SHIP_OF_THE_LINE   UNIT_CULVERIN   UNIT_MUSKETMAN  UNIT_VOLLEY_GUN
    --  UNIT_DREADNOUGHT    UNIT_RIFLEMAN   UNIT_GATLINGGUN
    --  UNIT_ARTILLERY  UNIT_WWI_TANK   UNIT_TRIPLANE   UNIT_PARATROOPER
    --  UNIT_BATTLESHIP UNIT_CARRIER    UNIT_SUBMARINE  UNIT_BOMBER 
    -- UNIT_NUCLEAR_CARRIER UNIT_HELICOPTER_GUNSHIP UNIT_ATOMIC_BOMB    UNIT_SSBN   UNIT_MECHANIZED_INFANTRY
    --  UNIT_STEALTH_ATTACK_AIRCRAFT    UNIT_FW_MECH_ARTILLERY  UNIT_FW_BATTLESUIT  UNIT_FW_ROBOT_INFANTRY  UNIT_ICBM_MISSILE
    
    --[[
    { id = "UNIT_SPARTAN300",
      kind = "UNIT", key = "UNIT_SPARTAN300",           -- shows the Knight's own icon
      title = "Knights Take the Field",
      desc  = "{1_Civ} fields the first armored knights." },
    

    { id = "UNIT_SWORDSMAN",
      kind = "UNIT", key = "UNIT_SWORDSMAN",           -- shows the Knight's own icon
      title = "A Clash of Steel",   {CIV_ADJ}   {CITY}
      desc  = "{1_Civ} have begun construction of a new class of naval behemoths. According to reports sailors nationwide are refusing to report for duty." },
    ]]--

    { id = "UNIT_TEUTONIC_KNIGHT",
      kind = "UNIT", key = "UNIT_TEUTONIC_KNIGHT",           -- shows the Knight's own icon
      title = "Crusader Kings",
      desc  = "{CIV_ADJ} soldiers pick up arms fueled by religious fervor and a thirst for vengeance. Many wonder who they will target with their 'righteous' fury." },

    { id = "UNIT_CARAVEL",
      kind = "UNIT", key = "UNIT_CARAVEL",           -- shows the Knight's own icon
      title = "A New World",
      desc  = "A new class of light ships have been put to sea from {CITY}. These ships are filled with explorers and traders who seek to chart unknown lands." },

    { id = "UNIT_TREBUCHET",
      kind = "UNIT", key = "UNIT_TREBUCHET",           -- shows the Knight's own icon
      title = "Projectile Siege",
      desc  = "{CIV_ADJ} engineers in {CITY} have been hard at work perfecting a long range siege weapon to tear down city walls." },

    { id = "UNIT_KNIGHT",
      kind = "UNIT", key = "UNIT_KNIGHT",           -- shows the Knight's own icon
      title = "{CIV_ADJ} Chivalry",
      desc  = "Noblemen in {CITY} have begun taking a liking to cavalry and heavy armor. According to reports these amoured beasts are almost unstoppable in battle." },
    
    { id = "UNIT_CROSSBOWMAN",
      kind = "UNIT", key = "UNIT_CROSSBOWMAN",           -- shows the Knight's own icon
      title = "Bolt and Bow",
      desc  = "A new class of ranged weapons have been sighted in {CIV_ADJ} armies. Rumors suggest these weapons rain terror without even the pull of a bow." },

    { id = "UNIT_SHIP_OF_THE_LINE",
      kind = "UNIT", key = "UNIT_SHIP_OF_THE_LINE",           -- shows the Knight's own icon
      title = "A Hundred {CIV_ADJ} Guns",
      desc  = "{CIV_ADJ} naval planners have laid the first hundred gun capital ships to sea. Our advisors suggest maintaining cordial relations with the {CIV_ADJ}." },

    { id = "UNIT_CULVERIN",
      kind = "UNIT", key = "UNIT_CULVERIN",           -- shows the Knight's own icon
      title = "Unstoppable Force",
      desc  = "Loud thunderous roars filled the air as {CIV_ADJ} cannons fired above. A lone general was heard saying: 'God is on the side of the heaviest cannon'" },

    { id = "UNIT_MUSKETMAN",
      kind = "UNIT", key = "UNIT_MUSKETMAN",           -- shows the Knight's own icon
      title = "{CIV_ADJ} Boomsticks",
      desc  = "{CIV_ADJ} soldiers fired into a thick formation of cavalry on the battlefield, when the smoke cleared all that remained were the crimes of men." },
    
    { id = "UNIT_VOLLEY_GUN",
      kind = "UNIT", key = "UNIT_VOLLEY_GUN",           -- shows the Knight's own icon
      title = "Machinery of Death",
      desc  = "The roar of screams and a thousand shrieking projectiles filled a lonely valley. They say {CIV_ADJ} death had finally been succesfully industrialized." },

    { id = "UNIT_DREADNOUGHT",
      kind = "UNIT", key = "UNIT_DREADNOUGHT",           -- shows the Knight's own icon
      title = "Floating Fortresses Sighted",
      desc  = "{1_Civ} have begun construction of a new class of naval behemoths. According to reports sailors nationwide are refusing to report for duty." },
    
    --pikeman needed - pike and shot    Principle, sometimes that seems to be nothing more than just a word.

    { id = "UNIT_RIFLEMAN",
      kind = "UNIT", key = "UNIT_RIFLEMAN",           -- shows the Knight's own icon
      title = "A Thousand {CIV_ADJ} Bullets",
      desc  = "'The rifle has no moral stature, it has no will of its own. Naturally, it must be used by evil men for evil purposes'- Unnamed {CIV_ADJ} General" },

      --[[
    { id = "UNIT_GATLINGGUN",
      kind = "UNIT", key = "UNIT_GATLINGGUN",           -- shows the Knight's own icon
      title = "Floating Fortresses Sighted",
      desc  = "{1_Civ} have begun construction of a new class of naval behemoths. According to reports sailors nationwide are refusing to report for duty." },
    ]]--

    --[[
    { id = "UNIT_ARTILLERY",
      kind = "UNIT", key = "UNIT_ARTILLERY",           -- shows the Knight's own icon
      title = "Beyond Visual Range",
      desc  = "{1_Civ} fields the first armored knights." },
    ]]--

    { id = "UNIT_WWI_TANK",
      kind = "UNIT", key = "UNIT_WWI_TANK",           -- shows the Knight's own icon
      title = "{CIV_ADJ} Land Ships",
      desc  = "{CIV_ADJ} landships pushed over trenches, through a hail of bullets and artillery. The landship is a steaming steel beast of industrial warfare." },

    { id = "UNIT_TRIPLANE",
      kind = "UNIT", key = "UNIT_TRIPLANE",           -- shows the Knight's own icon
      title = "Death From Above",
      desc  = "A squadron of {CIV_ADJ} aircraft flew overhead dropping bombs and bullets. A new dimension of death had been achieved." },

    { id = "UNIT_WWI_PARATROOPER",
      kind = "UNIT", key = "UNIT_WWI_PARATROOPER",           -- shows the Knight's own icon
      title = "Who Dares, Wins",
      desc  = "A starry moonlit night over the bunkers was suddenly filled by thousands of {CIV_ADJ} men in the sky. There was truly nowhere left to hide." },
    
      --[[
    { id = "UNIT_BATTLESHIP",
      kind = "UNIT", key = "UNIT_BATTLESHIP",           -- shows the Knight's own icon
      title = "Knights Take the Field",
      desc  = "{1_Civ} fields the first armored knights." },
    ]]--

    { id = "UNIT_CARRIER",
      kind = "UNIT", key = "UNIT_CARRIER",           -- shows the Knight's own icon
      title = "Floating {CIV_ADJ} Airfields",
      desc  = "A new class of {CIV_ADJ} capital ships takes to the seas. No longer is naval combat restrained to the range of what one can see." },
    
      --[[
    { id = "UNIT_SUBMARINE",
      kind = "UNIT", key = "UNIT_SUBMARINE",           -- shows the Knight's own icon
      title = "Knights Take the Field",
      desc  = "{1_Civ} fields the first armored knights." },
    
    { id = "UNIT_BOMBER",
      kind = "UNIT", key = "UNIT_BOMBER",           -- shows the Knight's own icon
      title = "Floating Fortresses Sighted",
      desc  = "{1_Civ} have begun construction of a new class of naval behemoths. According to reports sailors nationwide are refusing to report for duty." },
    ]]--

      --[[
    { id = "UNIT_NUCLEAR_CARRIER",
      kind = "UNIT", key = "UNIT_NUCLEAR_CARRIER",           -- shows the Knight's own icon
      title = "Knights Take the Field",
      desc  = "{1_Civ} fields the first armored knights." },
    
    { id = "UNIT_HELICOPTER_GUNSHIP",
      kind = "UNIT", key = "UNIT_HELICOPTER_GUNSHIP",           -- shows the Knight's own icon
      title = "Floating Fortresses Sighted",
      desc  = "{1_Civ} have begun construction of a new class of naval behemoths. According to reports sailors nationwide are refusing to report for duty." },
    ]]--

    { id = "UNIT_ATOMIC_BOMB",
      kind = "UNIT", key = "UNIT_ATOMIC_BOMB",           -- shows the Knight's own icon
      title = "Destroyer of Worlds",
      desc  = "A solemn {CIV_ADJ} scientist remarked as a blinding flash filled the sky, 'Now, I am become Death, the destroyer of worlds'" },

    --[[
    { id = "UNIT_SSBN",
      kind = "UNIT", key = "UNIT_SSBN",           -- shows the Knight's own icon
      title = "Floating Fortresses Sighted",
      desc  = "{1_Civ} have begun construction of a new class of naval behemoths. According to reports sailors nationwide are refusing to report for duty." },
    
    { id = "UNIT_MECHANIZED_INFANTRY",
      kind = "UNIT", key = "UNIT_MECHANIZED_INFANTRY",           -- shows the Knight's own icon
      title = "Knights Take the Field",
      desc  = "{1_Civ} fields the first armored knights." },
    ]]--
    { id = "UNIT_STEALTH_ATTACK_AIRCRAFT",
      kind = "UNIT", key = "UNIT_STEALTH_ATTACK_AIRCRAFT",           -- shows the Knight's own icon
      title = "A Cloaked {CIV_ADJ} Dagger",
      desc  = "The {CIV_ADJ} aircraft flies undetected over enemy territory only to turn as night turns to day behind it. Peace was signed the next day." },
    
    { id = "UNIT_ICBM_MISSILE",
    kind = "UNIT", key = "UNIT_ICBM_MISSILE",           -- shows the Knight's own icon
    title = "Nuclear Hellfire",
    desc  = "A blinding flash sparked across the entire sky, and in that moment everyone knew, civilization on Earth had retreated a thousand years." },

      --[[
    { id = "UNIT_FW_MECH_ARTILLERY",
      kind = "UNIT", key = "UNIT_FW_MECH_ARTILLERY",           -- shows the Knight's own icon
      title = "Knights Take the Field",
      desc  = "{1_Civ} fields the first armored knights." },

    { id = "UNIT_FW_BATTLESUIT",
      kind = "UNIT", key = "UNIT_FW_BATTLESUIT",           -- shows the Knight's own icon
      title = "Floating Fortresses Sighted",
      desc  = "{1_Civ} have begun construction of a new class of naval behemoths. According to reports sailors nationwide are refusing to report for duty." },
    
    { id = "UNIT_FW_ROBOT_INFANTRY",
      kind = "UNIT", key = "UNIT_FW_ROBOT_INFANTRY",           -- shows the Knight's own icon
      title = "Knights Take the Field",
      desc  = "{1_Civ} fields the first armored knights." },

    ]]--
   
    
    --------------------------------------------------
    -- WONDERS  
    --  BUILDING_VOYAGERONE BUILDING_UNITED_NATIONS_HQ  BUILDING_LARGE_HADRON_COLLIDER  BUILDING_COLOSSEUM  BUILDING_SISTINE_CHAPEL
    --  BUILDING_PYRAMID    BUILDING_STOCK_EXCHANGE	BUILDING_UNIVERSITY	BUILDING_OIL_REFINERY	BUILDING_SPACESHIP_FACTORY	BUILDING_FACTORY
    --[[
    { id = "BUILDING_PYRAMID",
      kind = "BUILDING", key = "BUILDING_PYRAMID", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_VOYAGERONE",
      kind = "BUILDING", key = "BUILDING_VOYAGERONE", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_UNITED_NATIONS_HQ",
      kind = "BUILDING", key = "BUILDING_UNITED_NATIONS_HQ", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_LARGE_HADRON_COLLIDER",
      kind = "BUILDING", key = "BUILDING_LARGE_HADRON_COLLIDER", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_COLOSSEUM",
      kind = "BUILDING", key = "BUILDING_COLOSSEUM", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_SISTINE_CHAPEL",
      kind = "BUILDING", key = "BUILDING_SISTINE_CHAPEL", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_AIRPORT",
      kind = "BUILDING", key = "BUILDING_AIRPORT", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_STOCK_EXCHANGE",
      kind = "BUILDING", key = "BUILDING_STOCK_EXCHANGE", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_UNIVERSITY",
      kind = "BUILDING", key = "BUILDING_UNIVERSITY", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_OIL_REFINERY",
      kind = "BUILDING", key = "BUILDING_OIL_REFINERY", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_SPACESHIP_FACTORY",
      kind = "BUILDING", key = "BUILDING_SPACESHIP_FACTORY", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },

    { id = "BUILDING_FACTORY",
      kind = "BUILDING", key = "BUILDING_FACTORY", -- shows the Pyramids' own icon
      title = "The Pyramids Are Complete",
      desc  = "{1_Civ} has raised the Pyramids in {CITY}." },
    ]]--
}

-------------------------------------------------
-- WORLD EVENTS
--  enabled            true / false
--  scope              "ALL" = announce everything (unmet civs show as Unknown)
--                     "ME"  = only when you are one of the civs involved
--  includeCityStates  also announce events involving city-states
-------------------------------------------------
local WORLD = {
    WAR = {
        enabled = true, scope = "ALL", includeCityStates = false,
        -- WarStateChanged(team1, team2, true): team1 is assumed to be the declarer.
        -- If aggressor / defender show up swapped in your game, set this to false.
        firstTeamIsAggressor = true,
        variants = {
            { title = "War Declared!",         desc = "{AGGRESSOR} has declared war on {DEFENDER}." },
            { title = "The Drums of War",      desc = "{AGGRESSOR} marches against {DEFENDER}." },
            { title = "Hostilities Begin",     desc = "Blood will be spilled between {AGGRESSOR} and {DEFENDER}." },
            { title = "Peace Shattered",       desc = "{AGGRESSOR} turns its armies on {DEFENDER}." },
        },
    },

    FRIENDSHIP = {
        enabled = true, scope = "ALL", icon = TREATY_ICON,
        variants = {
            { title = "A Bond of Friendship",   desc = "{CIV1} and {CIV2} have declared friendship." },
            { title = "Friends and Allies",     desc = "{CIV1} and {CIV2} pledge their goodwill." },
            { title = "A Hand Extended",        desc = "{CIV1} and {CIV2} grow closer." },
        },
    },

    PACT = {
        enabled = true, scope = "ALL", icon = TREATY_ICON,
        variants = {
            { title = "Defensive Pact Signed",  desc = "{CIV1} and {CIV2} vow to defend each other." },
            { title = "Shields Raised Together", desc = "{CIV1} and {CIV2} stand united against aggression." },
            { title = "An Alliance Forged",     desc = "{CIV1} and {CIV2} are bound by a defensive pact." },
        },
    },

    CAPTURE = {
        enabled = true, scope = "ALL", includeCityStates = false,
        -- SerialEventCityCaptured(hexPos, oldOwnerID, cityID, newOwnerID). If old / new show up
        -- swapped in your game, set this to false.
        oldOwnerIsFirst = true,
        variants = {
            { title = "City Captured!",         desc = "{NEW} has taken {CITY} from {OLD}." },
            { title = "{CITY} Has Fallen",      desc = "{OLD} loses {CITY} to {NEW}." },
            { title = "A Flag Changes Hands",   desc = "{CITY} now flies the banner of {NEW}." },
            { title = "Conquest",               desc = "The armies of {NEW} seize {CITY}." },
        },
    },

    -- shown right after a capture, if the civ that lost the city still owns nuclear weapons
    NUKE_WARNING = {
        enabled = true, scope = "ALL",
        variants = {
            { title = "Nuclear Retaliation Looms", desc = "After losing {CITY}, {OLD} is preparing a nuclear strike on {NEW}." },
            { title = "The Sky Darkens",           desc = "{OLD} readies its nuclear arsenal against {NEW}." },
            { title = "Pushed Too Far",            desc = "The loss of {CITY} has {OLD} preparing a nuclear strike on {NEW}." },
        },
    },

    -- shown when a nuclear weapon detonates over a city (needs GameEvents.NuclearDetonation, see notes)
    NUKE_STRIKE = {
        enabled = true, scope = "ALL", includeCityStates = true,
        casualtiesPerPop = 1,     -- 1 = show the raw population lost; e.g. 100000 for dramatic flavour numbers  Casualties: {CASUALTIES}.
        variants = {
            { title = "Nuclear Strike!",           desc = "A nuclear weapon launched by {LAUNCHER} has struck {CITY}." },
            { title = "Nuclear Attack on {CITY}",  desc = "{LAUNCHER} detonated a nuclear weapon over {CITY}." },
            { title = "Ground Zero",               desc = "{CITY} was hit by a {LAUNCHER_ADJ} nuclear weapon." },
        },
    },
}

-------------------------------------------------
-- STATE
-------------------------------------------------
local watching   = {}      -- milestones nobody has won yet
local feed       = {}      -- world facts to announce: { kind = ..., ... } (milestones + treaties)
local cursor     = {}      -- activePlayerID -> how much of `feed` they have been told about
local dofState   = {}      -- "a:b" -> true while a declaration of friendship is active
local pactState  = {}      -- "teamA:teamB" -> true while a defensive pact is active
local treatyBroken = {}    -- feature name -> true if an API call failed (feature disabled)
local baselined  = false   -- first poll is silent
local g_ready    = false   -- war / capture / nuke events are ignored until the game finished loading
local queue      = {}      -- banners waiting to be shown
local current    = nil     -- the banner item currently on screen
local state      = "IDLE"  -- IDLE | IN | HOLD | OUT | GAP
local timer      = 0
local g_seenTurn = -1
local g_seen     = {}      -- de-dupe war / capture / nuke events per turn
local popSnap    = {}      -- "x:y" -> city population at the last turn start (for nuclear casualty numbers)
local nukeCache  = {}      -- playerID -> { turn = n, has = bool } (does this civ own nuclear weapons?)

-------------------------------------------------
-- SETUP: resolve database keys once
-------------------------------------------------
local function ResolveEvents()
    watching = {}
    for _, ev in ipairs(EVENTS) do
        local ok = true
        if ev.kind == "TECH" then
            ev.ref  = GameInfoTypes[ev.key]
            ev.info = GameInfo.Technologies[ev.key]
            ok = (ev.ref ~= nil)
        elseif ev.kind == "UNIT" then
            local info = GameInfo.Units[ev.key]
            ev.info = info
            ev.ref  = info and GameInfoTypes[info.Class] or nil
            ok = (ev.ref ~= nil)
        elseif ev.kind == "BUILDING" then
            local info = GameInfo.Buildings[ev.key]
            ev.info = info
            ev.ref  = info and GameInfoTypes[info.BuildingClass] or nil
            ok = (ev.ref ~= nil)
        elseif ev.kind == "YEAR" then
            ok = (ev.year ~= nil)
        else
            ok = false
        end

        if ok then
            table.insert(watching, ev)
        else
            print("EventBanner: skipping event '" .. tostring(ev.id) .. "' (bad kind/key)")
        end
    end
end

-------------------------------------------------
-- VIEWER HELPERS (read-only)
-------------------------------------------------
-- true if the viewer is allowed to see WHICH civ did it (themselves, same team, or met)
local function CanSee(activePlayerID, pid)
    if REVEAL_UNMET_CIVS then return true end
    local myTeam    = Players[activePlayerID]:GetTeam()
    local theirTeam = Players[pid]:GetTeam()
    return myTeam == theirTeam or Teams[myTeam]:IsHasMet(theirTeam)
end

local function IsUnknown(activePlayerID, pid)
    return not CanSee(activePlayerID, pid)
end

local function Involves(activePlayerID, a, b)
    local myTeam = Players[activePlayerID]:GetTeam()
    return Players[a]:GetTeam() == myTeam or (b ~= nil and Players[b]:GetTeam() == myTeam)
end

-- order a pair so the viewer is first when involved, otherwise lowest ID first
local function OrderPair(activePlayerID, a, b)
    local myTeam = Players[activePlayerID]:GetTeam()
    if Players[b]:GetTeam() == myTeam and Players[a]:GetTeam() ~= myTeam then
        return b, a
    end
    return a, b
end

local function CivAdj(pid, unknown)
    if unknown then return UNKNOWN_CIV_ADJ end
    return Locale.ConvertTextKey(Players[pid]:GetCivilizationAdjectiveKey())
end

local function CivName(pid, unknown)
    if unknown then return UNKNOWN_CIV_NAME end
    return Locale.ConvertTextKey(Players[pid]:GetCivilizationShortDescriptionKey())
end

-------------------------------------------------
-- TEXT: random variant + token filling
-------------------------------------------------
local function Pick(group)
    local list = group.variants
    if not list then
        list = { { title = group.title, desc = group.desc } }
        group.variants = list
    end
    local n = #list
    if n == 0 then return { title = "", desc = "" } end
    local i = 1
    if n > 1 then
        i = math.random(n)
        if i == group._last then i = (i % n) + 1 end   -- never the same twice in a row
    end
    group._last = i
    return list[i]
end

local function Fill(str, tokens)
    if str == nil then return "" end
    if string.sub(str, 1, 7) == "TXT_KEY" then
        str = Locale.ConvertTextKey(str)
    end
    -- unknown {TOKENS} are left untouched (the function returns nil)
    return (string.gsub(str, "{([%w_]+)}", function(k) return tokens[k] end))
end

local function FormatNumber(n)
    local s = tostring(math.floor(n + 0.5))
    local k
    repeat
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return s
end

-------------------------------------------------
-- NUKE HELPERS
-------------------------------------------------
local function FindTsarInfo()
    if NUKE_ICON_UNIT and GameInfo.Units[NUKE_ICON_UNIT] then
        return GameInfo.Units[NUKE_ICON_UNIT]
    end
    for row in GameInfo.Units() do
        if row.UnitArtInfo == "ART_DEF_UNIT_ATOMIC_BOMB" and row.UnitFlagIconOffset == 80 then
            return row
        end
    end
    print("EventBanner: no unit uses ART_DEF_UNIT_ATOMIC_BOMB with flag offset 80, falling back to UNIT_ATOMIC_BOMB")
    return GameInfo.Units["UNIT_ATOMIC_BOMB"]
end

local okTsar, TSAR_INFO = pcall(FindTsarInfo)
if not okTsar then
    print("EventBanner: Tsar icon lookup failed: " .. tostring(TSAR_INFO))
    TSAR_INFO = nil
end

local NUKE_TYPE_SET = nil

-- does this civ own any nuclear weapon right now? (cached per turn so a string of
-- captures in one turn doesn't rescan the civ's units every time)
local function OwnerHasNukes(pid)
    local pPlayer = Players[pid]
    if not pPlayer then return false end

    local turn = Game.GetGameTurn()
    local cached = nukeCache[pid]
    if cached and cached.turn == turn then return cached.has end

    if not NUKE_TYPE_SET then
        NUKE_TYPE_SET = {}
        for _, key in ipairs(NUKE_UNIT_KEYS) do
            local id = GameInfoTypes[key]
            if id then NUKE_TYPE_SET[id] = true end
        end
        if TSAR_INFO then NUKE_TYPE_SET[TSAR_INFO.ID] = true end
    end

    local ok, result = pcall(function()
        for unit in pPlayer:Units() do
            if NUKE_TYPE_SET[unit:GetUnitType()] then return true end
            local okL, lvl = pcall(unit.NukeDamageLevel, unit)
            if okL and lvl and lvl > 0 then return true end
        end
        return false
    end)

    local has = (ok and result) and true or false
    nukeCache[pid] = { turn = turn, has = has }
    return has
end

-- remembers every city's population once per turn, so the strike banner can show the real loss
local function SnapshotPopulations()
    local maxP = GameDefines.MAX_CIV_PLAYERS or (GameDefines.MAX_MAJOR_CIVS + GameDefines.MAX_MINOR_CIVS)
    for pid = 0, maxP - 1 do
        local p = Players[pid]
        if p and p:IsAlive() then
            for city in p:Cities() do
                popSnap[city:GetX() .. ":" .. city:GetY()] = city:GetPopulation()
            end
        end
    end
end

-------------------------------------------------
-- ICONS
-------------------------------------------------
local RIGHT = { box = Controls.CivIconBox, bg = Controls.CivIconBG,
                shadow = Controls.CivIconShadow, icon = Controls.CivIcon }
local LEFT  = { box = Controls.LeftCivBox, bg = Controls.LeftCivIconBG,
                shadow = Controls.LeftCivIconShadow, icon = Controls.LeftCivIcon }

local function PlayerColorVec(pid, which)
    local colorSet = GameInfo.PlayerColors[Players[pid]:GetPlayerColor()]
    local c = GameInfo.Colors[colorSet[which]]
    return Vector4(c.Red, c.Green, c.Blue, 1)
end

-- "?" placeholder for civs the viewer hasn't met. The unknown-civ icon is the game's
-- CIVILIZATION_RANDOM entry (index 22 of CIV_COLOR_ATLAS), a complete round badge,
-- so the BG and shadow images are hidden.
local function SetUnknownFlag(f)
    f.bg:SetHide(true)
    f.shadow:SetHide(true)
    pcall(function() f.icon:SetColor(Vector4(1, 1, 1, 1)) end)   -- clear any civ tint
    IconHookup(23, CIV_ICON_SIZE, "CIV_COLOR_ATLAS", f.icon)
end

-- Round civ flag via the game's own CivIconHookup (same call shape the base UI uses).
local function SetKnownFlag(f, pid)
    f.bg:SetHide(false)
    f.shadow:SetHide(false)
    CivIconHookup(pid, CIV_ICON_SIZE, f.icon, f.bg, f.shadow, false, true)
end

local function SetFlag(f, pid, unknown)
    f.box:SetHide(false)
    if unknown then SetUnknownFlag(f) else SetKnownFlag(f, pid) end
end

local function SetAccent(spec)
    local ok = false
    if spec then
        if spec.unknown then
            ok = pcall(function() Controls.Accent:SetColor(Vector4(0.6, 0.66, 0.76, 1)) end)
        else
            ok = pcall(function() Controls.Accent:SetColor(PlayerColorVec(spec.pid, "PrimaryColor")) end)
        end
    end
    if not ok then
        pcall(function() Controls.Accent:SetColor(Vector4(1, 0.82, 0.47, 1)) end)
    end
end

local function ShowAtlasIcon(index, atlas)
    local size = EVENT_ICON_SIZE
    local shown = IconHookup(index, size, atlas, Controls.EventIcon)
    if not shown then                       -- atlas has no icon at this size: try 64
        size = 64
        shown = IconHookup(index, size, atlas, Controls.EventIcon)
    end
    Controls.EventIcon:SetSizeVal(size, size)
    return shown
end

local function ShowTextureIcon(texture)
    pcall(function() Controls.EventIcon:SetTextureOffsetVal(0, 0) end)   -- clear any atlas offset
    Controls.EventIcon:SetTexture(texture)
    Controls.EventIcon:SetSizeVal(EVENT_ICON_SIZE, EVENT_ICON_SIZE)
    return true
end

-- left slot spec: nil | {type="civ",pid,unknown} | {type="game",info,fallback} |
--                 {type="custom",texture} | {type="treaty",icon}
local function ApplyLeft(spec)
    Controls.EventIcon:SetHide(true)
    LEFT.box:SetHide(true)
    if not spec then return end

    if spec.type == "civ" then
        SetFlag(LEFT, spec.pid, spec.unknown)
        return
    end

    local shown = false
    if spec.type == "custom" then
        shown = ShowTextureIcon(spec.texture)
    elseif spec.type == "treaty" then
        local t = spec.icon
        if t and t.texture then
            shown = ShowTextureIcon(t.texture)
        elseif t and t.atlas and t.index then
            shown = ShowAtlasIcon(t.index, t.atlas)
        end
    elseif spec.type == "game" then
        local info = spec.info
        if info and info.IconAtlas and info.PortraitIndex then
            shown = ShowAtlasIcon(info.PortraitIndex, info.IconAtlas)
        end
        if not shown and spec.fallback then
            shown = ShowTextureIcon(spec.fallback)
        end
    end
    Controls.EventIcon:SetHide(not shown)
end

local function ApplyRight(spec)
    if spec then
        SetFlag(RIGHT, spec.pid, spec.unknown)
    else
        RIGHT.box:SetHide(true)
    end
end

-------------------------------------------------
-- BANNER: build items
-- item = { group, tokens, left, right, accent, plot, nuke, variant }
-------------------------------------------------
local function BuildMilestone(active, ev, pid, city)
    local unknown = (pid ~= nil) and IsUnknown(active, pid) or false
    local name = pid and CivName(pid, unknown) or ""

    local left
    if ev.kind == "TECH" then
        left = { type = "game", info = ev.info, fallback = ev.icon }      -- tech icon first
    elseif ev.icon then
        left = { type = "custom", texture = ev.icon }
    else
        left = { type = "game", info = ev.info }
    end

    local right = nil
    if pid and ev.showCiv ~= false then right = { pid = pid, unknown = unknown } end

    local cityName = CITY_FALLBACK
    if unknown then
        cityName = UNKNOWN_CITY_NAME
    elseif city then
        cityName = city
    end

    return { group = ev, tokens = { CIV = name, ["1_Civ"] = name, CITY = cityName,
                                    CIV_ADJ = pid and CivAdj(pid, unknown) or "" },
             left = left, right = right,
             accent = pid and { pid = pid, unknown = unknown } or nil }
end

local function BuildPair(active, cfg, a, b)
    local ua, ub = IsUnknown(active, a), IsUnknown(active, b)
    local na, nb = CivName(a, ua), CivName(b, ub)

    local left
    if cfg.icon then
        left = { type = "treaty", icon = cfg.icon }
    else
        left = { type = "civ", pid = a, unknown = ua }       -- no treaty icon configured: show both flags
    end
    return { group = cfg, tokens = { CIV1 = na, CIV2 = nb, CIV = na,
                                    CIV1_ADJ = CivAdj(a, ua), CIV2_ADJ = CivAdj(b, ub) },
             left = left, right = { pid = b, unknown = ub },
             accent = { pid = a, unknown = ua } }
end

local function BuildWar(active, cfg, aggressor, defender)
    local ua, ud = IsUnknown(active, aggressor), IsUnknown(active, defender)
    local na, nd = CivName(aggressor, ua), CivName(defender, ud)
    return { group = cfg,
             tokens = { AGGRESSOR = na, DEFENDER = nd, CIV = na, CIV1 = na, CIV2 = nd,
                        AGGRESSOR_ADJ = CivAdj(aggressor, ua), DEFENDER_ADJ = CivAdj(defender, ud) },
             left  = { type = "civ", pid = aggressor, unknown = ua },
             right = { pid = defender, unknown = ud },
             accent = { pid = aggressor, unknown = ua } }
end

local function BuildCapture(active, cfg, oldID, newID, gx, gy)
    local uo, un = IsUnknown(active, oldID), IsUnknown(active, newID)
    local no, nn = CivName(oldID, uo), CivName(newID, un)
    return { group = cfg,
             tokens = { OLD = no, NEW = nn, CIV = nn, CIV1 = no, CIV2 = nn, CITY = "a city",
                        NEW_ADJ = CivAdj(newID, un), OLD_ADJ = CivAdj(oldID, uo) },
             left  = { type = "civ", pid = oldID, unknown = uo },
             right = { pid = newID, unknown = un },
             accent = { pid = newID, unknown = un },
             plot = { x = gx, y = gy } }
end

-- city captured from a civ that still owns nuclear weapons: "preparing a nuclear strike"
local function BuildNukeWarning(active, cfg, oldID, newID, gx, gy)
    local uo, un = IsUnknown(active, oldID), IsUnknown(active, newID)
    local no, nn = CivName(oldID, uo), CivName(newID, un)
    return { group = cfg,
             tokens = { OLD = no, NEW = nn, CIV = no, CITY = "a city",
                        OLD_ADJ = CivAdj(oldID, uo), NEW_ADJ = CivAdj(newID, un) },
             left   = { type = "game", info = TSAR_INFO },
             right  = { pid = oldID, unknown = uo },          -- the civ preparing the strike
             accent = { pid = oldID, unknown = uo },
             plot   = { x = gx, y = gy } }
end

-- a nuclear weapon hit a city
local function BuildNukeStrike(active, cfg, launcherID, ownerID, cx, cy, before)
    local ul, uo = IsUnknown(active, launcherID), IsUnknown(active, ownerID)
    local nl, no = CivName(launcherID, ul), CivName(ownerID, uo)
    return { group = cfg,
             tokens = { LAUNCHER = nl, OWNER = no, CIV = nl,
                        CITY = uo and UNKNOWN_CITY_NAME or CITY_FALLBACK, CASUALTIES = "0",
                        LAUNCHER_ADJ = CivAdj(launcherID, ul), OWNER_ADJ = CivAdj(ownerID, uo) },
             left   = { type = "game", info = TSAR_INFO },
             right  = { pid = launcherID, unknown = ul },     -- the civ that launched it
             accent = { pid = launcherID, unknown = ul },
             plot   = (not uo) and { x = cx, y = cy } or nil, -- hides the city name if you haven't met its owner
             nuke   = { x = cx, y = cy, before = before, perPop = cfg.casualtiesPerPop or 1 } }
end

-- the city name is looked up when the banner is shown (the city exists by then)
local function ResolveCityName(plot)
    local ok, name = pcall(function()
        local p = Map.GetPlot(plot.x, plot.y)
        local city = p and p:GetPlotCity()
        if city then
            return Locale.ConvertTextKey(city:GetNameKey())
        end
        return nil
    end)
    if ok and name and name ~= "" then return name end
    return nil
end

-------------------------------------------------
-- BANNER: populate + animate
-------------------------------------------------
-- (re)writes the headline / description. For nuclear strikes this is called a second time
-- once the slide-in has finished, so the casualty number reflects the completed blast.
local function SetTexts(item)
    local tokens = item.tokens
    if item.plot then
        local city = ResolveCityName(item.plot)
        if city then tokens.CITY = city end
    end

    if item.nuke then                                   -- real loss = population before - population now
        local n = item.nuke
        local lost = 0
        local ok, after = pcall(function()
            local city = Map.GetPlot(n.x, n.y):GetPlotCity()
            return city and city:GetPopulation() or nil
        end)
        if ok and after then lost = math.max(0, n.before - after) end
        tokens.CASUALTIES = FormatNumber(lost * n.perPop)
    end

    local v = item.variant
    Controls.Headline:SetText(Fill(v.title, tokens))
    Controls.Desc:SetText(Fill(v.desc, tokens))
end

local function Populate(item)
    item.variant = Pick(item.group)
    SetTexts(item)
    ApplyLeft(item.left)
    ApplyRight(item.right)
    SetAccent(item.accent)
end

local OnUpdate -- forward declaration

local function ShowNext()
    local item = table.remove(queue, 1)
    if not item then
        state = "IDLE"
        current = nil
        ContextPtr:ClearUpdate()            -- zero cost while idle
        Controls.BannerAlpha:SetHide(true)
        return
    end

    local ok, err = pcall(Populate, item)
    if not ok then
        print("EventBanner populate error: " .. tostring(err))
        return ShowNext()                   -- skip the broken item, try the next one
    end
    current = item
    Controls.BannerAlpha:SetHide(false)
    Controls.BannerAlpha:SetToBeginning()
    Controls.BannerSlide:SetToBeginning()
    Controls.BannerAlpha:Play()
    Controls.BannerSlide:Play()

    state = "IN"
    timer = SLIDE_TIME
    ContextPtr:SetUpdate(OnUpdate)
end

-- Runs only while a banner is active.
OnUpdate = function(dt)
    timer = timer - (dt or 0.033)
    if timer > 0 then return end

    if state == "IN" then
        state = "HOLD"
        timer = HOLD_TIME
        if current and current.nuke then pcall(SetTexts, current) end   -- blast has landed: refresh casualties
    elseif state == "HOLD" then
        state = "OUT"
        timer = SLIDE_TIME
        Controls.BannerAlpha:Reverse()
        Controls.BannerSlide:Reverse()
    elseif state == "OUT" then
        state = "GAP"
        timer = GAP_TIME
        Controls.BannerAlpha:SetHide(true)
    elseif state == "GAP" then
        ShowNext()
    end
end

local function Enqueue(item)
    if #queue >= MAX_QUEUE then
        table.remove(queue, 1)              -- drop the oldest
    end
    table.insert(queue, item)
    if state == "IDLE" then
        ShowNext()
    end
end

-------------------------------------------------
-- DETECTION: milestones (read-only)
-------------------------------------------------
local function PlayerHas(ev, pPlayer)
    local kind = ev.kind
    if kind == "TECH" then
        return Teams[pPlayer:GetTeam()]:IsHasTech(ev.ref)
    elseif kind == "UNIT" then
        return pPlayer:GetUnitClassCount(ev.ref) > 0
    elseif kind == "BUILDING" then
        return pPlayer:GetBuildingClassCount(ev.ref) > 0
    end
    return false
end

-- returns the lowest-ID major civ that has it, or nil
local function FindFirst(ev)
    for pid = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local pPlayer = Players[pid]
        if pPlayer and pPlayer:IsAlive() and PlayerHas(ev, pPlayer) then
            return pid
        end
    end
    return nil
end

-- localized name of a city object, or nil
local function CityNameOf(city)
    if not city then return nil end
    local name = Locale.ConvertTextKey(city:GetNameKey())
    if name == nil or name == "" then return nil end
    return name
end

-- The city a winning BUILDING / UNIT is in. Runs once, when the event is won.
-- BUILDING: the city that has it.
-- TECH: a stable "random" city of the civ (same pick on every client).
-- UNIT: the city its first unit is standing in, otherwise the owner's nearest city
--       (a unit can't be traced back to the city that built it once it has moved).
local function FindCity(ev, pid)
    local ok, name = pcall(function()
        local pPlayer = Players[pid]
        if ev.kind == "BUILDING" then
            -- check the building itself and any unique replacement sharing its building class
            local ids = { ev.info.ID }
            for row in GameInfo.Buildings{ BuildingClass = ev.info.BuildingClass } do
                ids[#ids + 1] = row.ID
            end
            for city in pPlayer:Cities() do
                for _, bid in ipairs(ids) do
                    if city:IsHasBuilding(bid) then return CityNameOf(city) end
                end
            end
        elseif ev.kind == "TECH" then
            local cities = {}
            for city in pPlayer:Cities() do cities[#cities + 1] = city end
            if #cities == 0 then return CityNameOf(pPlayer:GetCapitalCity()) end
            table.sort(cities, function(a, b) return a:GetID() < b:GetID() end)   -- same order on every client
            local index = ((ev.ref * 31 + pid * 17) % #cities) + 1                 -- stable "random" pick
            return CityNameOf(cities[index])
        elseif ev.kind == "UNIT" then
            for unit in pPlayer:Units() do
                if unit:GetUnitClassType() == ev.ref then
                    local plotCity = unit:GetPlot():GetPlotCity()
                    if plotCity then return CityNameOf(plotCity) end
                    local best, bestDist = nil, nil
                    for city in pPlayer:Cities() do
                        local d = Map.PlotDistance(unit:GetX(), unit:GetY(), city:GetX(), city:GetY())
                        if not bestDist or d < bestDist then best, bestDist = city, d end
                    end
                    return CityNameOf(best)
                end
            end
        end
        return nil
    end)
    if ok then return name end
    print("EventBanner: city lookup failed for " .. tostring(ev.id) .. ": " .. tostring(name))
    return nil
end

-------------------------------------------------
-- DETECTION: treaties (polled once per turn)
-- Records the current state of every pair of major civs and adds a feed entry
-- when a friendship / pact appears that wasn't there last turn.
-------------------------------------------------
local function PollTreaties(silent)
    local cfgF, cfgP = WORLD.FRIENDSHIP, WORLD.PACT
    local wantF = cfgF.enabled and not treatyBroken.FRIENDSHIP
    local wantP = cfgP.enabled and not treatyBroken.PACT
    if not (wantF or wantP) then return end

    local ids = {}
    for pid = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local p = Players[pid]
        if p and p:IsAlive() then ids[#ids + 1] = pid end
    end

    local seenTeamPair = {}
    for i = 1, #ids - 1 do
        local a = ids[i]
        for j = i + 1, #ids do
            local b = ids[j]

            if wantF then
                local ok, now = pcall(function() return Players[a]:IsDoF(b) end)
                if not ok then
                    treatyBroken.FRIENDSHIP = true
                    wantF = false
                    print("EventBanner: Player:IsDoF unavailable, friendship banners disabled")
                else
                    local key = a .. ":" .. b
                    now = now and true or false
                    if now and not dofState[key] and not silent then
                        feed[#feed + 1] = { kind = "FRIENDSHIP", a = a, b = b }
                    end
                    dofState[key] = now
                end
            end

            if wantP then
                local ta, tb = Players[a]:GetTeam(), Players[b]:GetTeam()
                if ta ~= tb then
                    local tkey = math.min(ta, tb) .. ":" .. math.max(ta, tb)
                    if not seenTeamPair[tkey] then
                        seenTeamPair[tkey] = true
                        local ok, now = pcall(function() return Teams[ta]:IsDefensivePact(tb) end)
                        if not ok then
                            treatyBroken.PACT = true
                            wantP = false
                            print("EventBanner: Team:IsDefensivePact unavailable, pact banners disabled")
                        else
                            now = now and true or false
                            if now and not pactState[tkey] and not silent then
                                feed[#feed + 1] = { kind = "PACT", a = a, b = b }
                            end
                            pactState[tkey] = now
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------------
-- ANNOUNCE a feed entry to the current viewer
-------------------------------------------------
local function Announce(active, f)
    if f.kind == "MILESTONE" then
        Enqueue(BuildMilestone(active, f.ev, f.pid, f.city))
        return
    end

    local cfg = WORLD[f.kind]
    if not cfg or not cfg.enabled then return end
    if cfg.scope == "ME" and not Involves(active, f.a, f.b) then return end

    local a, b = OrderPair(active, f.a, f.b)
    Enqueue(BuildPair(active, cfg, a, b))
end

-------------------------------------------------
-- POLL (once per turn)
-------------------------------------------------
local function Poll()
    local active = Game.GetActivePlayer()
    if active == nil or active < 0 or Players[active] == nil then return end

    local silent = not baselined

    -- 1) milestones: find winners (shared by every viewer; the watch list shrinks as events are won)
    if #watching > 0 then
        local year = Game.GetGameTurnYear()
        local stillWatching = {}
        for _, ev in ipairs(watching) do
            local fired, pid = false, nil
            if ev.kind == "YEAR" then
                fired = (year >= ev.year)
            else
                pid = FindFirst(ev)
                fired = (pid ~= nil)
            end

            if fired then
                if not silent then                           -- already true at load: stay silent
                    local city = pid and FindCity(ev, pid) or nil
                    feed[#feed + 1] = { kind = "MILESTONE", ev = ev, pid = pid, city = city }
                end
            else
                stillWatching[#stillWatching + 1] = ev
            end
        end
        watching = stillWatching
    end

    -- 2) treaties
    PollTreaties(silent)
    baselined = true

    -- 3) city populations, so a nuclear strike banner can show the real casualties
    if WORLD.NUKE_STRIKE.enabled then SnapshotPopulations() end

    -- 4) tell THIS viewer about anything they haven't heard yet (per-viewer, so hotseat works)
    local from = (cursor[active] or 0) + 1
    for i = from, #feed do
        Announce(active, feed[i])
    end
    cursor[active] = #feed
end

local function SafePoll()
    local ok, err = pcall(Poll)
    if not ok then print("EventBanner poll error: " .. tostring(err)) end
end

-------------------------------------------------
-- EVENT-DRIVEN: wars
-------------------------------------------------
local function GetTeamPlayerID(teamID)
    local team = Teams[teamID]
    if not team then return nil end
    local pid = team:GetLeaderID()
    if pid == nil or pid < 0 or Players[pid] == nil then return nil end
    return pid
end

-- one de-dupe table per turn, shared by wars, captures and nuclear strikes
local function SeenThisTurn(key)
    local turn = Game.GetGameTurn()
    if turn ~= g_seenTurn then
        g_seenTurn = turn
        g_seen = {}
    end
    if g_seen[key] then return true end
    g_seen[key] = true
    return false
end

local function OnWarStateChanged(teamA, teamB, isAtWar)
    local cfg = WORLD.WAR
    if not cfg.enabled or not g_ready or not isAtWar then return end
    if teamA == teamB then return end

    -- the event can fire once per direction; announce each pair once per turn
    if SeenThisTurn("W" .. math.min(teamA, teamB) .. ":" .. math.max(teamA, teamB)) then return end

    local idA, idB = GetTeamPlayerID(teamA), GetTeamPlayerID(teamB)
    if not idA or not idB then return end
    local pA, pB = Players[idA], Players[idB]
    if pA:IsBarbarian() or pB:IsBarbarian() then return end
    if not cfg.includeCityStates and (pA:IsMinorCiv() or pB:IsMinorCiv()) then return end

    local active = Game.GetActivePlayer()
    if active == nil or active < 0 or Players[active] == nil then return end
    if cfg.scope == "ME" and not Involves(active, idA, idB) then return end

    local aggressor, defender = idA, idB
    if not cfg.firstTeamIsAggressor then aggressor, defender = idB, idA end

    print("EventBanner: war declared", Game.GetGameTurn(), teamA, teamB)   -- check Lua.log to verify who the aggressor is
    Enqueue(BuildWar(active, cfg, aggressor, defender))
end

-------------------------------------------------
-- EVENT-DRIVEN: city captured (+ nuclear retaliation warning)
-------------------------------------------------
local function OnCityCaptured(hexPos, firstID, cityID, secondID)
    local cfg, warn = WORLD.CAPTURE, WORLD.NUKE_WARNING
    if not (cfg.enabled or warn.enabled) or not g_ready then return end

    local oldID, newID = firstID, secondID
    if not cfg.oldOwnerIsFirst then oldID, newID = secondID, firstID end
    if oldID == nil or newID == nil or oldID == newID then return end
    local pOld, pNew = Players[oldID], Players[newID]
    if not pOld or not pNew then return end
    if pOld:IsBarbarian() or pNew:IsBarbarian() then return end
    if not cfg.includeCityStates and (pOld:IsMinorCiv() or pNew:IsMinorCiv()) then return end

    local ok, gx, gy = pcall(ToGridFromHex, hexPos.x, hexPos.y)
    if not ok then return end
    if SeenThisTurn("C" .. gx .. ":" .. gy) then return end

    local active = Game.GetActivePlayer()
    if active == nil or active < 0 or Players[active] == nil then return end

    print("EventBanner: city captured", Game.GetGameTurn(), oldID, newID)   -- check Lua.log to verify old / new owner

    if cfg.enabled and not (cfg.scope == "ME" and not Involves(active, oldID, newID)) then
        Enqueue(BuildCapture(active, cfg, oldID, newID, gx, gy))
    end

    -- the civ that lost the city still has nuclear weapons: warn that a strike is coming
    if warn.enabled and not pOld:IsMinorCiv()
       and not (warn.scope == "ME" and not Involves(active, oldID, newID))
       and OwnerHasNukes(oldID) then
        Enqueue(BuildNukeWarning(active, warn, oldID, newID, gx, gy))
    end
end

-------------------------------------------------
-- EVENT-DRIVEN: nuclear strike on a city
-- GameEvents.NuclearDetonation(playerID, x, y, bWar, bBystander)
-------------------------------------------------
local function OnNuclearDetonation(launcherID, x, y, bWar, bBystander)
    local cfg = WORLD.NUKE_STRIKE
    if not cfg.enabled or not g_ready then return end
    if launcherID == nil or x == nil or y == nil then return end
    if SeenThisTurn("N" .. x .. ":" .. y) then return end

    local pLauncher = Players[launcherID]
    if not pLauncher or pLauncher:IsBarbarian() then return end

    -- the city that was hit: on the target plot, otherwise the nearest one inside the blast radius
    local radius = GameDefines.NUKE_BLAST_RADIUS or 2
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if not city then
        local bestDist
        for dx = -radius, radius do
            for dy = -radius, radius do
                local p = Map.GetPlot(x + dx, y + dy)
                local c = p and p:GetPlotCity()
                if c then
                    local d = Map.PlotDistance(x, y, c:GetX(), c:GetY())
                    if d <= radius and (not bestDist or d < bestDist) then city, bestDist = c, d end
                end
            end
        end
    end
    if not city then return end

    local ownerID = city:GetOwner()
    local pOwner = Players[ownerID]
    if not pOwner or pOwner:IsBarbarian() then return end
    if not cfg.includeCityStates and pOwner:IsMinorCiv() then return end

    local active = Game.GetActivePlayer()
    if active == nil or active < 0 or Players[active] == nil then return end
    if cfg.scope == "ME" and not Involves(active, launcherID, ownerID) then return end

    local cx, cy = city:GetX(), city:GetY()
    local before = math.max(popSnap[cx .. ":" .. cy] or 0, city:GetPopulation())
    print("EventBanner: nuclear strike", Game.GetGameTurn(), launcherID, ownerID, cx, cy)
    Enqueue(BuildNukeStrike(active, cfg, launcherID, ownerID, cx, cy, before))
end

-------------------------------------------------
-- HOOKUP
-------------------------------------------------
local function OnActivePlayerChanged()
    -- hotseat / observer switch: clear anything on screen
    queue = {}
    current = nil
    state = "IDLE"
    ContextPtr:ClearUpdate()
    Controls.BannerAlpha:SetHide(true)
end

ResolveEvents()
Controls.BannerAlpha:SetHide(true)

Events.ActivePlayerTurnStart.Add(SafePoll)
Events.LoadScreenClose.Add(function()
    g_ready = true
    SafePoll()                                       -- silent baseline after loading a save / new game
end)

-- optional hooks: wrapped so a missing event can never stop the rest of the script loading
local function SafeHook(eventName, fn)
    local ok, err = pcall(function() Events[eventName].Add(fn) end)
    if not ok then print("EventBanner: could not hook Events." .. eventName .. ": " .. tostring(err)) end
end

-- GameEvents are game-core events. They only reach this UI script if your game / DLL exposes
-- them in the UI state; the print below tells you in Lua.log whether it worked.
local function SafeGameEventHook(name, fn)
    local ok, err = pcall(function() GameEvents[name].Add(fn) end)
    print("EventBanner: GameEvents." .. name .. (ok and " hooked" or (" NOT hooked: " .. tostring(err))))
end

SafeHook("SequenceGameInitComplete", function() g_ready = true end)
SafeHook("GameplaySetActivePlayer", OnActivePlayerChanged)
SafeHook("WarStateChanged", OnWarStateChanged)
SafeHook("SerialEventCityCaptured", OnCityCaptured)

SafeGameEventHook("NuclearDetonation", function(...)
    local ok, err = pcall(OnNuclearDetonation, ...)
    if not ok then print("EventBanner nuclear strike error: " .. tostring(err)) end
end)