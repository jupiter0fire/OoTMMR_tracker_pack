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

function new_node(values)
    if not values then
        values = {}
    end

    local node = {
        ["type"] = nil,  -- "exit", "event", "location"
        ["name"] = nil,  -- name of the exit/event/location
        ["glitched"] = false,
        ["child"] = nil, -- mm_time index, 1 to #MM_TIME_SLICES; alternatively, { start = 1, stop = #MM_TIME_SLICES }
        ["adult"] = nil, -- mm_time index, 1 to #MM_TIME_SLICES; alternatively, { start = 1, stop = #MM_TIME_SLICES }
        ["rule"] = nil,  -- function from actual logic here!
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

-- require() isn't working in EmoTracker; look into this some more, but see README.md
-- This is a bad workaround, but it works for now
if EMO then
    ScriptHost:LoadScript("scripts/oot_logic.lua")
    ScriptHost:LoadScript("scripts/mm_logic.lua")
else
    dofile("generated/oot_logic.lua")
    dofile("generated/mm_logic.lua")
end
OOTMM.oot.state = _oot_logic()
OOTMM.mm.state = _mm_logic()

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

local function reset_logic()
    run_search("normal")
    run_search("glitched")
end

local function get_availability(type, world, name)
    if OOTMM_RESET_LOGIC_FLAG then
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

function mm(location)
    return get_availability("location", "mm", location)
end

-- Returns the "raw" availability of an event, without overrides
function oot_event_raw(event)
    return get_availability("event", "oot", event)
end

-- Returns the "raw" availability of an event, without overrides
function mm_event_raw(event)
    return get_availability("event", "mm", event)
end
