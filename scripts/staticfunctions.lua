-- Just in case anyone actually reads this, I'm sorry for the mess.
-- There's basically nothing but anti-patterns here.
-- I decided very early on that I wanted to keep the OoTMM logic as close to the source as possible,
-- which resulted in a lot of weird workarounds and global variables EVERYWHERE.
-- Those global variables also make functions have side effects, so it's awesomeness^2.
--
-- Don't copy any of this to new projects unless you want to see the world burn, in which case, go ahead.

EMO = false
if Tracker then
    EMO = true
else
    -- Define globals normally provided by EmoTracker
    Tracker = {}
    AccessibilityLevel = {
        -- These might not be the values used by EmoTracker, but they're never used directly
        -- None = 0,
        -- SequenceBreak = 1,
        -- Normal = 2,
        None = "None",
        SequenceBreak = "SequenceBreak",
        Normal = "Normal",
    }
end

OOTMM_DEBUG = false

OOTMM_RESET_LOGIC_FLAG = {
    ["oot"] = true,
    ["mm"] = true,
}

function OOTMM_RESET_LOGIC()
    for k, v in pairs(OOTMM_RESET_LOGIC_FLAG) do
        OOTMM_RESET_LOGIC_FLAG[k] = true
    end
end

-- OoTMM_core$ find . -iname '*.yml' -print0 | xargs -0 cat | grep -oE 'has\([^),]*' | cut -d '(' -f 2 | sort | uniq | while read line; do echo "[\"$line\"] = \"$line\","; done
-- FIXME: This is incomplete, but useful for testing right now.
OOTMM_CORE_ITEMS = {
    ["ARROW_FIRE"] = "ARROW_FIRE",
    ["ARROW_ICE"] = "ARROW_ICE",
    ["ARROW_LIGHT"] = "ARROW_LIGHT",
    ["BLUE_FIRE"] = "BLUE_FIRE",
    ["BOMBCHU_10"] = "BOMBCHU_10",
    ["BOMBCHU_20"] = "BOMBCHU_20",
    ["BOMBCHU_5"] = "BOMBCHU_5",
    ["BOMB_BAG"] = "BOMB_BAG",
    ["BOOMERANG"] = "BOOMERANG",
    ["BOOTS_HOVER"] = "BOOTS_HOVER",
    ["BOOTS_IRON"] = "BOOTS_IRON",
    ["BOSS_KEY_FIRE"] = "BOSS_KEY_FIRE",
    ["BOSS_KEY_FOREST"] = "BOSS_KEY_FOREST",
    ["BOSS_KEY_GANON"] = "BOSS_KEY_GANON",
    ["BOSS_KEY_GB"] = "BOSS_KEY_GB",
    ["BOSS_KEY_SH"] = "BOSS_KEY_SH",
    ["BOSS_KEY_SHADOW"] = "BOSS_KEY_SHADOW",
    ["BOSS_KEY_SPIRIT"] = "BOSS_KEY_SPIRIT",
    ["BOSS_KEY_ST"] = "BOSS_KEY_ST",
    ["BOSS_KEY_WATER"] = "BOSS_KEY_WATER",
    ["BOSS_KEY_WF"] = "BOSS_KEY_WF",
    ["BOTTLED_GOLD_DUST"] = "BOTTLED_GOLD_DUST",
    ["BOTTLE_CHATEAU"] = "BOTTLE_CHATEAU",
    ["BOTTLE_EMPTY"] = "BOTTLE_EMPTY",
    ["BOTTLE_MILK"] = "BOTTLE_MILK",
    ["BOTTLE_POTION_RED"] = "BOTTLE_POTION_RED",
    ["BOW"] = "BOW",
    ["CHICKEN"] = "CHICKEN",
    ["DEED_LAND"] = "DEED_LAND",
    ["DEED_MOUNTAIN"] = "DEED_MOUNTAIN",
    ["DEED_OCEAN"] = "DEED_OCEAN",
    ["DEED_SWAMP"] = "DEED_SWAMP",
    ["GERUDO_CARD"] = "GERUDO_CARD",
    ["GREAT_FAIRY_SWORD"] = "GREAT_FAIRY_SWORD",
    ["GS_TOKEN"] = "GS_TOKEN",
    ["GS_TOKEN_OCEAN"] = "GS_TOKEN_OCEAN",
    ["GS_TOKEN_SWAMP"] = "GS_TOKEN_SWAMP",
    ["HAMMER"] = "HAMMER",
    ["HOOKSHOT"] = "HOOKSHOT",
    ["LENS"] = "LENS",
    ["LETTER_TO_KAFEI"] = "LETTER_TO_KAFEI",
    ["LETTER_TO_MAMA"] = "LETTER_TO_MAMA",
    ["MAGIC_BEAN"] = "MAGIC_BEAN",
    ["MAGIC_UPGRADE"] = "MAGIC_UPGRADE",
    ["MASK_ALL_NIGHT"] = "MASK_ALL_NIGHT",
    ["MASK_BLAST"] = "MASK_BLAST",
    ["MASK_BREMEN"] = "MASK_BREMEN",
    ["MASK_BUNNY"] = "MASK_BUNNY",
    ["MASK_CAPTAIN"] = "MASK_CAPTAIN",
    ["MASK_COUPLE"] = "MASK_COUPLE",
    ["MASK_DEKU"] = "MASK_DEKU",
    ["MASK_DON_GERO"] = "MASK_DON_GERO",
    ["MASK_FIERCE_DEITY"] = "MASK_FIERCE_DEITY",
    ["MASK_GARO"] = "MASK_GARO",
    ["MASK_GIANT"] = "MASK_GIANT",
    ["MASK_GIBDO"] = "MASK_GIBDO",
    ["MASK_GORON"] = "MASK_GORON",
    ["MASK_GREAT_FAIRY"] = "MASK_GREAT_FAIRY",
    ["MASK_KAFEI"] = "MASK_KAFEI",
    ["MASK_KAMARO"] = "MASK_KAMARO",
    ["MASK_KEATON"] = "MASK_KEATON",
    ["MASK_POSTMAN"] = "MASK_POSTMAN",
    ["MASK_ROMANI"] = "MASK_ROMANI",
    ["MASK_SCENTS"] = "MASK_SCENTS",
    ["MASK_SKULL"] = "MASK_SKULL",
    ["MASK_STONE"] = "MASK_STONE",
    ["MASK_TRUTH"] = "MASK_TRUTH",
    ["MASK_ZORA"] = "MASK_ZORA",
    ["MEDALLION_FIRE"] = "MEDALLION_FIRE",
    ["MEDALLION_FOREST"] = "MEDALLION_FOREST",
    ["MEDALLION_SHADOW"] = "MEDALLION_SHADOW",
    ["MEDALLION_SPIRIT"] = "MEDALLION_SPIRIT",
    ["MEDALLION_WATER"] = "MEDALLION_WATER",
    ["MILK"] = "MILK",
    ["MOON_TEAR"] = "MOON_TEAR",
    ["NUT"] = "NUT",
    ["NUTS_10"] = "NUTS_10",
    ["NUTS_5"] = "NUTS_5",
    ["OCARINA"] = "OCARINA",
    ["PENDANT_OF_MEMORIES"] = "PENDANT_OF_MEMORIES",
    ["PICTOGRAPH_BOX"] = "PICTOGRAPH_BOX",
    ["POCKET_EGG"] = "POCKET_EGG",
    ["POTION_BLUE"] = "POTION_BLUE",
    ["POTION_RED"] = "POTION_RED",
    ["POWDER_KEG"] = "POWDER_KEG",
    ["ROOM_KEY"] = "ROOM_KEY",
    ["RUTO_LETTER"] = "RUTO_LETTER",
    ["SCALE"] = "SCALE",
    ["SHIELD"] = "SHIELD",
    ["SHIELD_DEKU"] = "SHIELD_DEKU",
    ["SHIELD_HERO"] = "SHIELD_HERO",
    ["SHIELD_HYLIAN"] = "SHIELD_HYLIAN",
    ["SHIELD_MIRROR"] = "SHIELD_MIRROR",
    ["SLINGSHOT"] = "SLINGSHOT",
    ["SMALL_KEY_BOTW"] = "SMALL_KEY_BOTW",
    ["SMALL_KEY_FIRE"] = "SMALL_KEY_FIRE",
    ["SMALL_KEY_FOREST"] = "SMALL_KEY_FOREST",
    ["SMALL_KEY_GANON"] = "SMALL_KEY_GANON",
    ["SMALL_KEY_GB"] = "SMALL_KEY_GB",
    ["SMALL_KEY_GF"] = "SMALL_KEY_GF",
    ["SMALL_KEY_GTG"] = "SMALL_KEY_GTG",
    ["SMALL_KEY_SH"] = "SMALL_KEY_SH",
    ["SMALL_KEY_SHADOW"] = "SMALL_KEY_SHADOW",
    ["SMALL_KEY_SPIRIT"] = "SMALL_KEY_SPIRIT",
    ["SMALL_KEY_ST"] = "SMALL_KEY_ST",
    ["SMALL_KEY_WATER"] = "SMALL_KEY_WATER",
    ["SMALL_KEY_WF"] = "SMALL_KEY_WF",
    ["SONG_AWAKENING"] = "SONG_AWAKENING",
    ["SONG_GORON"] = "SONG_GORON",
    ["SONG_GORON_HALF"] = "SONG_GORON_HALF",
    ["SONG_SOARING"] = "SONG_SOARING",
    ["SONG_TP_FIRE"] = "SONG_TP_FIRE",
    ["SONG_TP_FOREST"] = "SONG_TP_FOREST",
    ["SONG_TP_LIGHT"] = "SONG_TP_LIGHT",
    ["SONG_TP_SHADOW"] = "SONG_TP_SHADOW",
    ["SONG_TP_SPIRIT"] = "SONG_TP_SPIRIT",
    ["SONG_TP_WATER"] = "SONG_TP_WATER",
    ["SONG_ZORA"] = "SONG_ZORA",
    ["SPELL_FIRE"] = "SPELL_FIRE",
    ["SPIN_UPGRADE"] = "SPIN_UPGRADE",
    ["STICK"] = "STICK",
    ["STICKS_10"] = "STICKS_10",
    ["STICKS_5"] = "STICKS_5",
    ["STONE_EMERALD"] = "STONE_EMERALD",
    ["STONE_OF_AGONY"] = "STONE_OF_AGONY",
    ["STONE_RUBY"] = "STONE_RUBY",
    ["STONE_SAPPHIRE"] = "STONE_SAPPHIRE",
    ["STRAY_FAIRY_GB"] = "STRAY_FAIRY_GB",
    ["STRAY_FAIRY_SH"] = "STRAY_FAIRY_SH",
    ["STRAY_FAIRY_ST"] = "STRAY_FAIRY_ST",
    ["STRAY_FAIRY_TOWN"] = "STRAY_FAIRY_TOWN",
    ["STRAY_FAIRY_WF"] = "STRAY_FAIRY_WF",
    ["STRENGTH"] = "STRENGTH",
    ["SWORD"] = "SWORD",
    ["SWORD_KOKIRI"] = "SWORD_KOKIRI",
    ["SWORD_MASTER"] = "SWORD_MASTER",
    ["TUNIC_GORON"] = "TUNIC_GORON",
    ["TUNIC_ZORA"] = "TUNIC_ZORA",
    ["WALLET"] = "WALLET",
    ["WEIRD_EGG"] = "WEIRD_EGG",
    ["ZELDA_LETTER"] = "ZELDA_LETTER",
    ["ZORA"] = "ZORA",
    -- FIXME: The following items were added by actually running a search; the list will need still more stuff in order to actually be useful for debugging.
    -- NOTE: This isn't actually needed for production use, it's strictly here so we notice missing items/events/tricks etc.
    ["BEAN_GRAVEYARD"] = "BEAN_GRAVEYARD",
    ["BEAN_LAKE_HYLIA"] = "BEAN_LAKE_HYLIA",
    ["BEAN_LOST_WOODS_EARLY"] = "BEAN_LOST_WOODS_EARLY",
    ["COJIRO"] = "COJIRO",
    ["DOOR_OF_TIME_OPEN"] = "DOOR_OF_TIME_OPEN",
    ["EYEBALL_FROG"] = "EYEBALL_FROG",
    ["GORON_CITY_SHORTCUT"] = "GORON_CITY_SHORTCUT",
    ["KING_ZORA_LETTER"] = "KING_ZORA_LETTER",
    ["MALON"] = "MALON",
    ["MEET_ZELDA"] = "MEET_ZELDA",
    ["NUTS"] = "NUTS",
    ["ODD_MUSHROOM"] = "ODD_MUSHROOM",
    ["ODD_POTION"] = "ODD_POTION",
    ["OOT_DEKU_SKIP"] = "OOT_DEKU_SKIP",
    ["OOT_HIDDEN_GROTTOS"] = "OOT_HIDDEN_GROTTOS",
    ["OOT_MAN_ON_ROOF"] = "OOT_MAN_ON_ROOF",
    ["OOT_NIGHT_GS"] = "OOT_NIGHT_GS",
    ["POCKET_CUCCO"] = "POCKET_CUCCO",
    ["SONG_EPONA"] = "SONG_EPONA",
    ["SONG_SARIA"] = "SONG_SARIA",
    ["SONG_STORMS"] = "SONG_STORMS",
    ["SONG_SUN"] = "SONG_SUN",
    ["SONG_ZELDA"] = "SONG_ZELDA",
    ["TALON_CHILD"] = "TALON_CHILD",
    ["progressive"] = "progressive",
    ["progressiveSwordsOot"] = "progressiveSwordsOot",
}

-- These are for testing basic child checks
local SWORD_KOKIRI = "SWORD_KOKIRI"
local SHIELD_DEKU = "SHIELD_DEKU"
-- These are for testing basic adult checks
local OCARINA = "OCARINA"
local SWORD_MASTER = "SWORD_MASTER"
local SONG_TIME = "SONG_TIME"
-- local HOOKSHOT = "HOOKSHOT"
local SLINGSHOT = "SLINGSHOT"
local BOMB_BAG = "BOMB_BAG"
local ZELDA_LETTER = "ZELDA_LETTER"
local GOLDSCALE = "GOLDSCALE"

local items = {
    -- [SWORD_KOKIRI] = 1,
    -- [SHIELD_DEKU] = 1,
    -- [OCARINA] = 1,
    -- [SWORD_MASTER] = 1,
    -- [SONG_TIME] = 1,
    [SLINGSHOT] = 1,
    [BOMB_BAG] = 1,
    [ZELDA_LETTER] = 1,
    [GOLDSCALE] = 1,
}

ToInject = {}

function trace(event, line)
    local s = debug.getinfo(2).short_src
    print(s .. ":" .. line)
end

-- require() isn't working in EmoTracker; look into this some more, but see README.md
-- This is a bad workaround, but it works for now
OOTMM = {
    ["oot"] = {
        ["state"] = nil,
        ["locations_normal"] = {},
        ["locations_glitched"] = {}
    },
    ["mm"] = {
        ["state"] = nil,
        ["locations_normal"] = {},
        ["locations_glitched"] = {}
    }
}

if EMO then
    ScriptHost:LoadScript("scripts/oot_logic.lua")
    ScriptHost:LoadScript("scripts/mm_logic.lua")
else
    dofile("generated/oot_logic.lua")
    dofile("generated/mm_logic.lua")
end
OOTMM.oot.state = _oot_logic()
OOTMM.mm.state = _mm_logic()

OOTMM.oot.state.inject({
    items = items,
})
OOTMM.mm.state.inject({
    items = items,
})

-- inject everything from ToInject
for k, v in pairs(ToInject) do
    OOTMM.oot.state.inject({ [k] = v })
    OOTMM.mm.state.inject({ [k] = v })
end

local function reset_logic(world)
    OOTMM[world].state.reset()

    OOTMM[world].state.set_trick_mode("selected")
    if world == "mm" then
        -- child only
        OOTMM[world].locations_normal = OOTMM[world].state.find_available_locations(true)
    else
        -- child + adult
        OOTMM[world].locations_normal = OOTMM[world].state.find_available_locations()
    end

    OOTMM[world].state.set_trick_mode("all")
    if world == "mm" then
        -- child only
        OOTMM[world].locations_glitched = OOTMM[world].state.find_available_locations(true)
    else
        -- child + adult
        OOTMM[world].locations_glitched = OOTMM[world].state.find_available_locations()
    end

    OOTMM_RESET_LOGIC_FLAG[world] = false
end

local function get_availability(world, location)
    if OOTMM_RESET_LOGIC_FLAG[world] then
        reset_logic(world)
    end

    local reachable = false
    local accessibility = AccessibilityLevel.None

    reachable = OOTMM[world].locations_normal[location] ~= nil or OOTMM[world].locations_glitched[location] ~= nil

    if reachable and OOTMM[world].locations_normal[location] ~= nil then
        accessibility = AccessibilityLevel.Normal
    elseif reachable and OOTMM[world].locations_glitched[location] ~= nil then
        accessibility = AccessibilityLevel.SequenceBreak
    end

    return reachable, accessibility
end

function oot(location)
    if OOTMM_DEBUG then
        print("oot:", location)
    end

    return get_availability("oot", location)
end

function mm(location)
    if OOTMM_DEBUG then
        print("mm:", location)
    end

    return get_availability("mm", location)
end
