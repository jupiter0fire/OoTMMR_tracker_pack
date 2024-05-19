-- SPDX-FileCopyrightText: 2023 Wilhelm Schürmann <wimschuermann@googlemail.com>
--
-- SPDX-License-Identifier: MIT

-- Just in case anyone actually reads this, I'm sorry for the mess.
-- There's basically nothing but anti-patterns here.
--
-- I decided very early on that I wanted to keep the OoTMM logic as close to the source as possible,
-- which resulted in a lot of weird workarounds and global variables EVERYWHERE.
-- Those global variables also make functions have side effects, so it's awesomeness^2.
--
-- Don't copy any of this to new projects unless you want to see the world burn, in which case, go ahead.

EMO = false
if Tracker then
    EMO = true
else
    -- Define globals normally provided by EmoTracker so local testing is possible
    Tracker = {}
    AccessibilityLevel = {
        -- These might not be the values used by EmoTracker, but they're never used directly
        None = "None",
        SequenceBreak = "SequenceBreak",
        Normal = "Normal",
    }
    PACK_READY = true
end

OOTMM_RESET_LOGIC_FLAG = true

function OOTMM_RESET_LOGIC()
    OOTMM_RESET_LOGIC_FLAG = true
end

function trace(event, line)
    local s = debug.getinfo(2).short_src
    print(s .. ":" .. line)
end

OOTMM = {
    ["oot"] = {
        ["state"] = nil,
        ["locations_normal"] = {},
        ["locations_glitched"] = {},
        ["events_normal"] = {},
        ["events_glitched"] = {}
    },
    ["mm"] = {
        ["state"] = nil,
        ["locations_normal"] = {},
        ["locations_glitched"] = {},
        ["events_normal"] = {},
        ["events_glitched"] = {},
    }
}

-- Adapted from OOTMM/packages/core/lib/combo/logic/expr.ts
-- TODO: This should probably be auto-generated from OOTMM's sources as well.
MM_TIME_SLICES = {
    'DAY1_AM_06_00',
    'DAY1_AM_07_00',
    'DAY1_AM_08_00',
    'DAY1_AM_10_00',
    'DAY1_PM_01_45',
    'DAY1_PM_03_00',
    'DAY1_PM_04_00',
    'NIGHT1_PM_06_00',
    'NIGHT1_PM_08_00',
    'NIGHT1_PM_09_00',
    'NIGHT1_PM_10_00',
    'NIGHT1_PM_11_00',
    'NIGHT1_AM_12_00',
    'NIGHT1_AM_02_30',
    'NIGHT1_AM_04_00',
    'NIGHT1_AM_05_00',
    'DAY2_AM_06_00',
    'DAY2_AM_07_00',
    'DAY2_AM_08_00',
    'DAY2_AM_10_00',
    'DAY2_AM_11_30',
    'DAY2_PM_02_00',
    'NIGHT2_PM_06_00',
    'NIGHT2_PM_08_00',
    'NIGHT2_PM_09_00',
    'NIGHT2_PM_10_00',
    'NIGHT2_PM_11_00',
    'NIGHT2_AM_12_00',
    'NIGHT2_AM_04_00',
    'NIGHT2_AM_05_00',
    'DAY3_AM_06_00',
    'DAY3_AM_07_00',
    'DAY3_AM_08_00',
    'DAY3_AM_10_00',
    'DAY3_AM_11_30',
    'DAY3_PM_01_00',
    'NIGHT3_PM_06_00',
    'NIGHT3_PM_08_00',
    'NIGHT3_PM_09_00',
    'NIGHT3_PM_10_00',
    'NIGHT3_PM_11_00',
    'NIGHT3_AM_12_00',
    'NIGHT3_AM_04_00',
    'NIGHT3_AM_05_00',
};
MM_TIME_SLICES_INDEX = {}
for i, v in ipairs(MM_TIME_SLICES) do
    MM_TIME_SLICES_INDEX[v] = i
end

function mm_time_index_to_string(index)
    return MM_TIME_SLICES[index]
end

function new_node(values)
    if not values then
        values = {}
    end

    local node = {
        ["type"] = nil,    -- "exit", "event", "location"
        ["name"] = nil,    -- name of the exit/event/location
        ["glitched"] = false,
        ["child"] = nil,   -- mm_time index, 1 to #MM_TIME_SLICES; alternatively, { start = 1, stop = #MM_TIME_SLICES }
        ["adult"] = nil,   -- mm_time index, 1 to #MM_TIME_SLICES; alternatively, { start = 1, stop = #MM_TIME_SLICES }
        ["rule"] = nil,    -- function from actual logic here!
        ["mm_stay"] = nil, -- "stay" rule for mm_time; only relevant if type is "exit"
    }

    for k, v in pairs(values) do
        node[k] = v
    end

    assert(node["type"])
    assert(node["name"])
    assert(node["rule"])

    return node
end

function node_as_string(node)
    -- FIXME: This won't work if we save a "from" field that is a node in the other world
    --        Arguably, we should just save whether we were child or adult instead and avoid the whole issue altogether!
    return node.type ..
        ":" ..
        node.glitched ..
        ":" .. tostring(node.child) .. ":" .. tostring(node.adult) .. ":" .. node.rule .. ":" .. node.name
end

PRICE_HELPER = {
    index = {},
    range_index = {},
}

-- require() isn't working in EmoTracker; look into this some more, but see README.md
-- This is a bad workaround, but it works for now
if EMO then
    ScriptHost:LoadScript("scripts/oot_logic.lua")
    ScriptHost:LoadScript("scripts/mm_logic.lua")
    -- ScriptHost:LoadScript("scripts/includes/prices.lua")
else
    dofile("generated/oot_logic.lua")
    dofile("generated/mm_logic.lua")
    -- dofile("generated/includes/prices.lua")
end
OOTMM.oot.state = _oot_logic()
OOTMM.mm.state = _mm_logic()

local function deep_copy_table(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deep_copy_table(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Prepare local copies of the original logic so we can reset later for MQ and/or ER
OOTMM.original_logic = {}
OOTMM.original_logic.oot = deep_copy_table(OOTMM.oot.state.logic)
OOTMM.original_logic.mm = deep_copy_table(OOTMM.mm.state.logic)

local function run_search(mode)
    local worlds = { "oot", "mm" }
    for _, world in ipairs(worlds) do
        OOTMM[world].state.reset()
    end

    -- We start as child + adult in OOT at SPAWN. All other places should become available from there.
    -- OOT SPAWN checks for age(adult) and event(TIME_TRAVEL), so adding adult to the queue this early is fine.
    -- By setting both child and adult to 1, we force the logic to check for both child and adult starting from SPAWN.
    OOTMM["oot"].state.SearchQueue:push(new_node({
        type = "exit",
        child = 1,
        adult = 1,
        name = "SPAWN",
        rule = function() return true end,
    }))

    local opposite = { oot = "mm", mm = "oot", OOT = "MM", MM = "OOT" }
    local more_to_go = true
    while more_to_go do
        more_to_go = false
        for _, world in ipairs(worlds) do
            if mode == "normal" then
                OOTMM[world].state.set_trick_mode("selected")
            elseif mode == "glitched" then
                OOTMM[world].state.set_trick_mode("all")
            end

            local search_results = OOTMM[world].state.search()
            OOTMM[world]["locations_" .. mode] = search_results.locations_available
            OOTMM[world]["events_" .. mode] = search_results.events_active

            if #search_results.activated_nodes > 0 then
                -- This logic module probably wasn't finished and needs to be called again.
                -- Since it can produce new nodes for other worlds, those will need to be kept active as well.
                more_to_go = true
            end

            for _, node in pairs(search_results.activated_nodes) do
                if node.type == "exit" then
                    -- search() returns newly reachable places as exit nodes
                    -- We need to add cross-world exits to the corresponding queues
                    -- Cross-world places start with OOT / MM, so we can just check for that
                    local split = node.name:find(" ")
                    if split then
                        local node_world = node.name:sub(1, split - 1):lower()
                        if node_world == "oot" or node_world == "mm" then -- FIXME: worlds are hardcoded here
                            -- Insert into other world's queue
                            local new_node = new_node(node)
                            new_node.name = node.name:sub(split + 1)
                            new_node.rule = function() return true end
                            OOTMM[node_world].state.SearchQueue:push(new_node)
                        end
                    end
                elseif node.type == "event" then
                    -- We need to inject all events from e.g. OOT into MM with an OOT_ prefix in order for checks like event(MM_ARROWS) to work in MM's logic
                    -- Only add events that are not already prefixed with a world name
                    local split = node.name:find("_")
                    if split and node.name:sub(1, split - 1):upper() ~= "OOT" and node.name:sub(1, split - 1):upper() ~= "MM" then
                        local new_node = new_node(node)
                        new_node.name = world:upper() .. "_" .. node.name
                        new_node.rule = function() return true end
                        OOTMM[opposite[world]].state.SearchQueue:push(new_node)
                    end
                end
            end
        end
    end
end

-- Recursively replace all places reachable through exits with their MQ counterparts
local function replace_with_mq_logic(place, replaced)
    if replaced == nil then
        replaced = {}
    end

    if replaced[place] then
        -- Already replaced, infinite recursion go brrr
        return
    end

    if not OOTMM.oot.state.MQlogic[place] then
        -- No MQ counterpart, nothing to do here (e.g. exit back to overworld)
        return
    end

    OOTMM.oot.state.logic[place] = OOTMM.oot.state.MQlogic[place]
    replaced[place] = true

    if OOTMM.oot.state.MQlogic[place]["exits"] then
        for exit, _ in pairs(OOTMM.oot.state.MQlogic[place]["exits"]) do
            if OOTMM.oot.state.MQlogic[exit] then
                replace_with_mq_logic(exit, replaced)
            end
        end
    end
end

-- This is needed for testing; we could overwrite Tracker:ProviderCountForCode() here already instead, but then we'd lose the ability to override items per world
local function get_provider_count(code)
    if EMO then
        return Tracker:ProviderCountForCode(code)
    else
        local count = items[code]
        if count == nil then
            count = 0
        end
        return count
    end
end

local OOTMM_MQ_SETTING_PREVIOUS = {}
local OOTMM_MQ_DUNGEON_NAMES = {
    ["Deku Tree"] = "DT",
    ["Dodongo Cavern"] = "DC",
    ["Jabu-Jabu"] = "JJ",
    ["Ganon Castle"] = "Ganon",
}
local OOTMM_DUNGEON_ENTRANCE_NAMES = {
    { from = "OOT Kokiri Forest Near Deku Tree",       to = "OOT Deku Tree" },
    { from = "OOT Death Mountain",                     to = "OOT Dodongo Cavern" },
    { from = "OOT Zora Fountain",                      to = "OOT Jabu-Jabu" },
    { from = "OOT Sacred Meadow",                      to = "OOT Forest Temple" },
    { from = "OOT Fire Temple Entry",                  to = "OOT Fire Temple" },
    { from = "OOT Lake Hylia",                         to = "OOT Water Temple" },
    { from = "OOT Graveyard Upper",                    to = "OOT Shadow Temple" },
    { from = "OOT Desert Colossus",                    to = "OOT Spirit Temple" },
    { from = "OOT Zora Fountain Frozen",               to = "OOT Ice Cavern" },
    { from = "OOT Kakariko",                           to = "OOT Bottom of the Well" },
    { from = "OOT Gerudo Fortress Exterior",           to = "OOT Gerudo Training Grounds" },
    { from = "OOT Ganon Castle Exterior After Bridge", to = "OOT Ganon Castle" },
    { from = "OOT Ganon Castle Stairs",                to = "OOT Ganon Castle Tower" },
    { from = "MM Woodfall Front of Temple",            to = "MM Woodfall Temple" },
    { from = "MM Snowhead",                            to = "MM Snowhead Temple" },
    { from = "MM Zora Cape Peninsula",                 to = "MM Great Bay Temple" },
    { from = "MM Stone Tower Front of Temple",         to = "MM Stone Tower Temple" },
    { from = "MM Stone Tower Top Inverted",            to = "MM Stone Tower Temple Inverted" },
    { from = "MM Great Bay Coast",                     to = "MM Ocean Spider House" },
    { from = "MM Near Swamp Spider House",             to = "MM Swamp Spider House" },
    { from = "MM Great Bay Coast Fortress",            to = "MM Pirate Fortress" },
    { from = "MM Ikana Canyon",                        to = "MM Beneath the Well Entrance" },
    { from = "MM Ikana Castle Exterior",               to = "MM Ancient Castle of Ikana" },
    { from = "MM Ikana Valley",                        to = "MM Secret Shrine" },
}
local function reset_logic()
    -- TODO: MQ override should be moved entirely into the OoT module instead of yanking logic out and replacing it here!
    local mq_dungeons = {}
    local mq_reset_needed = false
    local mq_price_params = {}

    -- Check whether any MQ dungeons are active
    for k, v in pairs(OOTMM.oot.state.MQlogic) do
        local setting = "setting_mq_" .. k:gsub(" ", "") .. "_true"
        local mq_active = get_provider_count(setting) > 0
        if OOTMM_MQ_SETTING_PREVIOUS[setting] == nil then
            OOTMM_MQ_SETTING_PREVIOUS[setting] = mq_active
            mq_reset_needed = true
        else
            if OOTMM_MQ_SETTING_PREVIOUS[setting] ~= mq_active then
                OOTMM_MQ_SETTING_PREVIOUS[setting] = mq_active
                mq_reset_needed = true
            end
        end
        if mq_active then
            mq_dungeons[k] = mq_active
            if OOTMM_MQ_DUNGEON_NAMES[k] then
                mq_price_params[OOTMM_MQ_DUNGEON_NAMES[k]] = true
            end
        end
    end

    -- Overwrite OoT logic MQ dungeons where needed, and adjust scrub prices
    if mq_reset_needed then
        OOTMM.oot.state.logic = deep_copy_table(OOTMM.original_logic.oot)
        OOTMM.mm.state.logic = deep_copy_table(OOTMM.original_logic.mm)

        for k, v in pairs(mq_dungeons) do
            replace_with_mq_logic(k)
        end

        -- FIXME: Replace this hardcoded mess with auto-converted logic from prices.ts
        -- Note to future self: You tried to auto convert this, you used typescript-to-lua. It fails in subtle ways. Use something else.
        PRICE_HELPER.default_prices = { 10, 20, 60, 30, 15, 30, 10, 40, 180, 180, 180, 180, 100, 100, 100, 100, 50, 90,
            200, 15, 20, 60, 300, 10, 10, 10, 40, 200, 25, 50, 80, 120, 20, 60, 90, 10, 35, 10, 15, 80, 200, 50, 30, 15,
            300, 50, 30, 30, 20, 60, 90, 10, 35, 10, 15, 80, 200, 50, 30, 15, 300, 50, 30, 30, 40, 15, 20, 40, 40, 40,
            40, 10, 20, 40, 40, 20, 40, 40, 40, 20, 40, 40, 40, 40, 20, 40, 40, 40, 40, 40, 40, 0, 40, 15, 20, 50, 20,
            40, 40, 70, 40, 0, 30, 40, 50, 90, 500, 30, 80, 80, 50, 10, 30, 30, 30, 60, 10, 20, 40, 40, 80, 90, 20, 60,
            100, 5, 40, 20, 40, 20, 40, 20, 40, 20, 40, 20, 40 }
        PRICE_HELPER.range_index = {
            ["OOT_SHOPS"] = 1,
            ["OOT_SCRUBS"] = 65,
            ["MM_SHOPS"] = 103,
            ["MM_SHOPS_EX"] = 125,
            ["MM_TINGLE"] = 126,
            ["MAX"] = 138,
        }

        -- NOTE: This is partially translated from lib/combo/logic/price.ts
        local OOT_SCRUBS_OVERWORLD = { 40, 15, 20, 40, 40, 40, 40, 10, 20, 40, 40, 20, 40, 40, 40, 20, 40, 40, 40, 40,
            20, 40, 40, 40, 40, 40, 40 };
        local OOT_SCRUBS_DT = { 0 };
        local OOT_SCRUBS_DT_MQ = { 50 };
        local OOT_SCRUBS_DC = { 40, 15, 20, 50 };
        local OOT_SCRUBS_DC_MQ = { 40, 15, 50, 40 };
        local OOT_SCRUBS_JJ = { 20 };
        local OOT_SCRUBS_JJ_MQ = { 0 };
        local OOT_SCRUBS_GC = { 40, 40, 70, 40, 0 };
        local OOT_SCRUBS_GC_MQ = { 40, 40, 70, 40, 20 };

        local ootScrubs = {}
        table.insert(ootScrubs, OOT_SCRUBS_OVERWORLD)

        if mq_price_params['DT'] then
            table.insert(ootScrubs, OOT_SCRUBS_DT_MQ)
        else
            table.insert(ootScrubs, OOT_SCRUBS_DT)
        end

        if mq_price_params['DC'] then
            table.insert(ootScrubs, OOT_SCRUBS_DC_MQ)
        else
            table.insert(ootScrubs, OOT_SCRUBS_DC)
        end

        if mq_price_params['JJ'] then
            table.insert(ootScrubs, OOT_SCRUBS_JJ_MQ)
        else
            table.insert(ootScrubs, OOT_SCRUBS_JJ)
        end

        if mq_price_params['Ganon'] then
            table.insert(ootScrubs, OOT_SCRUBS_GC_MQ)
        else
            table.insert(ootScrubs, OOT_SCRUBS_GC)
        end

        local ootScrubsFlat = {}
        for i, v in ipairs(ootScrubs) do
            for j, w in ipairs(v) do
                table.insert(ootScrubsFlat, w)
            end
        end

        for i, price in ipairs(ootScrubsFlat) do
            PRICE_HELPER.default_prices[PRICE_HELPER.range_index.OOT_SCRUBS + i - 1] = price
        end
    end

    -- If there are no active MQ dungeons, this is all that's needed:
    run_search("normal")
    run_search("glitched")
end

local function get_availability(type, world, name)
    if PACK_READY and OOTMM_RESET_LOGIC_FLAG then
        reset_logic()
        OOTMM_RESET_LOGIC_FLAG = false
    end

    local reachable = false
    local accessibility = AccessibilityLevel.None

    reachable = OOTMM[world][type .. "s_normal"][name] ~= nil or OOTMM[world][type .. "s_glitched"][name] ~= nil

    if reachable and OOTMM[world][type .. "s_normal"][name] ~= nil then
        accessibility = AccessibilityLevel.Normal
    elseif reachable and OOTMM[world][type .. "s_glitched"][name] ~= nil then
        accessibility = AccessibilityLevel.SequenceBreak
    end

    return reachable, accessibility
end

function oot(location)
    return get_availability("location", "oot", location)
end

function ootmq(location)
    return get_availability("location", "oot", location)
end

function mm(location)
    return get_availability("location", "mm", location)
end

-- Returns the "raw" availability of an event, without overrides
function oot_event_raw(event)
    return get_availability("event", "oot", event)
end

function ootmq_event_raw(event)
    return get_availability("event", "oot", event)
end

function mm_event_raw(event)
    return get_availability("event", "mm", event)
end
