-- NOTE: This file is auto-generated. Any changes will be overwritten.

-- SPDX-FileCopyrightText: 2023 Wilhelm Schürmann <wimschuermann@googlemail.com>
--
-- SPDX-License-Identifier: MIT

-- The OoTMM logic is kept as-is, which means having global lowercase functions.
-- Disable warnings for this.
---@diagnostic disable: lowercase-global

-- This is for namespacing only, because EmoTracker doesn't seem to properly support require()
function _oot_logic()
    OOTMM_DEBUG = false

    local M = {
        EMO = EMO,
        AccessibilityLevel = AccessibilityLevel,
        Tracker = Tracker,
        OOTMM_DEBUG = OOTMM_DEBUG,
        MM_TIME_SLICES = MM_TIME_SLICES,
        MM_TIME_SLICES_INDEX = MM_TIME_SLICES_INDEX,
        PRICE_HELPER = PRICE_HELPER,
        os = os,
        pairs = pairs,
        ipairs = ipairs,
        new_node = new_node,
        print = print,
        setmetatable = setmetatable,
        string = string,
        tonumber = tonumber,
        tostring = tostring,
        table = table,
        debug = debug,
        assert = assert,
        error = error,
    }

    -- This is used for all items, events, settings, etc., but probably shouldn't be...
    setmetatable(M, {
        __index = function(table, key)
            if string.match(key, "^[A-Z0-9_]+$") then
                return tostring(key)
            else
                if OOTMM_DEBUG then
                    print("Unknown attribute accessed: " .. key)
                end

                return tostring(key)
            end
        end
    })

    local _ENV = M

    OOTMM_RUNTIME_ALL_GLITCHES_ENABLED = false
    OOTMM_RUNTIME_ALL_TRICKS_ENABLED = false
    OOTMM_RUNTIME_ACCESSIBILITY = {}
    OOTMM_RUNTIME_CACHE = {}
    OOTMM_RUNTIME_STATE = {}
    SearchQueue = {}

    if not EMO then
        -- This is for testing only; items gets injected by tests
        function Tracker:ProviderCountForCode(code)
            local count = items[code]
            if count == nil then
                count = 0
            end
            return count
        end
    end

    local Queue = {}
    function Queue:new()
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o._queue = {}
        o._prioritizedQueue = {} -- "Priority Queue" is a commonly used data structure; this is not exactly that, hence "prioritized".
        return o
    end

    function Queue:push(node)
        if node.type == "event" then
            self:push_prioritized(node)
        else
            self:push_normal(node)
        end
    end

    function Queue:push_normal(node)
        table.insert(self._queue, node)
    end

    function Queue:push_prioritized(node)
        table.insert(self._prioritizedQueue, node)
    end

    function Queue:pop()
        local node = table.remove(self._prioritizedQueue)
        if not node then
            node = table.remove(self._queue)
        end

        return node
    end

    function Queue:is_empty()
        return #self._queue == 0 and #self._prioritizedQueue == 0
    end

    function Queue:clear()
        self._queue = {}
        self._prioritizedQueue = {}
    end

    function Queue:print()
        for _, node in pairs(self._prioritizedQueue) do
            print(node.name, node.type, node.child, node.adult)
        end
        for _, node in pairs(self._queue) do
            print(node.name, node.type, node.child, node.adult)
        end
    end

    function reset()
        OOTMM_RUNTIME_CACHE = {}
        OOTMM_RUNTIME_STATE = {
            -- Previously checked, available places (list of nodes, source: internal)
            ["places_available"] = {}, -- { "place_1": node_1, "place_2": node_2, ... }

            -- Available locations (list of nodes, source: internal)
            ["locations_available"] = {}, -- { "location_1": node_1, "location_2": node_2, ... }

            -- Previously seen and already active events (source: internal)
            ["events_active"] = {}, -- { "event_1": node_1, "event_2": node_2, ... }

            -- exits/events/locations that need to be revisited if a new event is found (source: internal)
            ["events_to_revisit"] = {}, -- { "event_name": { node1, node2, ...}, ... }

            -- custom "event items" - whenever these are encountered, their amount is increased and an event with the name "CUSTOM_EVENT_FOO:amount" is activated (source: internal)
            ["custom_event_items"] = {}, -- { "item_name": amount, ... }
        }
        SearchQueue = Queue:new()        -- List of nodes, source: internal and external
    end

    function get_reachable_events()
        return OOTMM_RUNTIME_STATE.events_active
    end

    OOTMM_ITEM_PREFIX = "OOT"
    OOTMM_TRICK_PREFIX = "TRICK"
    OOTMM_GLITCH_PREFIX = "GLITCH"

    -- Inject things into the module's namespace
    function inject(stuff)
        for k, v in pairs(stuff) do
            M[k] = v
        end
    end

    -- "STRENGTH:3" ---> STRENGTH, 3
    -- "HOOKSHOT" ---> HOOKSHOT, 1
    local function parse_item_override(item)
        local min_count = 1

        if string.find(item, ":") then
            item, min_count = string.match(item, "([^:]+):?(%d+)")
        end

        return item, assert(tonumber(min_count))
    end

    OOTMM_HAS_OVERRIDES = {
        ["HOOKSHOT:2"] = "LONGSHOT",
        ["SCALE:2"] = "GOLDSCALE",
        ["STRENGTH:2"] = "STRENGTH2",
        ["STRENGTH:3"] = "STRENGTH3",
        ["WALLET:0"] = "WALLET0",
        ["WALLET:1"] = "WALLET1",
        ["WALLET:2"] = "WALLET2",
        ["WALLET:3"] = "WALLET3",
        ["SONG_GORON_HALF:2"] = "SONG_GORON",
        ["STONE_EMERALD"] = "SPIRITUAL_STONE:1",  -- FIXME: This is entirely arbitrary; if individual stones end up being relevant,
        ["STONE_RUBY"] = "SPIRITUAL_STONE:2",     -- FIXME: this will need to be changed to something more sensible or the
        ["STONE_SAPPHIRE"] = "SPIRITUAL_STONE:3", -- FIXME: has_spiritual_stones() macro will have to be adjusted on the fly.
        ["MEDALLION_FIRE"] = "NOCTURNE_MED:1",
        ["MEDALLION_WATER"] = "NOCTURNE_MED:2",
        ["MEDALLION_SPIRIT"] = "LACS_MED:1",
        ["MEDALLION_SHADOW"] = "LACS_MED:2",
        ["OCARINA:2"] = "OCARINA2",
    }
    OOTMM_HAS_PREFIXES = {
        ["setting"] = true,
        ["TRICK"] = true,
        ["EVENT"] = true,
        ["OOT"] = true,
        ["MM"] = true,
    }
    local CUSTOM_EVENT_ITEMS = {
        ["RUPEE_SILVER_BOTW"] = true,
        ["RUPEE_SILVER_DC"] = true,
        ["RUPEE_SILVER_GANON_FIRE"] = true,
        ["RUPEE_SILVER_GANON_FOREST"] = true,
        ["RUPEE_SILVER_GANON_LIGHT"] = true,
        ["RUPEE_SILVER_GANON_SHADOW"] = true,
        ["RUPEE_SILVER_GANON_SPIRIT"] = true,
        ["RUPEE_SILVER_GANON_WATER"] = true,
        ["RUPEE_SILVER_GTG_LAVA"] = true,
        ["RUPEE_SILVER_GTG_SLOPES"] = true,
        ["RUPEE_SILVER_GTG_WATER"] = true,
        ["RUPEE_SILVER_IC_BLOCK"] = true,
        ["RUPEE_SILVER_IC_SCYTHE"] = true,
        ["RUPEE_SILVER_SHADOW_BLADES"] = true,
        ["RUPEE_SILVER_SHADOW_PIT"] = true,
        ["RUPEE_SILVER_SHADOW_SCYTHE"] = true,
        ["RUPEE_SILVER_SHADOW_SPIKES"] = true,
        ["RUPEE_SILVER_SPIRIT_ADULT"] = true,
        ["RUPEE_SILVER_SPIRIT_BOULDERS"] = true,
        ["RUPEE_SILVER_SPIRIT_CHILD"] = true,
        ["RUPEE_SILVER_SPIRIT_LOBBY"] = true,
        ["RUPEE_SILVER_SPIRIT_SUN"] = true,
    }
    function has(item, min_count, use_prefix)
        if use_prefix == nil then
            use_prefix = true
        end

        if CUSTOM_EVENT_ITEMS[item] then
            min_count = min_count or 1
            return event("CUSTOM_EVENT_" .. item .. ":" .. tostring(min_count))
        end

        if min_count and OOTMM_HAS_OVERRIDES[item .. ":" .. min_count] then
            item, min_count = parse_item_override(OOTMM_HAS_OVERRIDES[item .. ":" .. min_count])
        elseif min_count == nil and OOTMM_HAS_OVERRIDES[item] then
            item, min_count = parse_item_override(OOTMM_HAS_OVERRIDES[item])
        end

        local prefix = string.match(item, "^([^_]+)_")
        if prefix and OOTMM_HAS_PREFIXES[prefix] then
            -- These are already prefixed as needed
            use_prefix = false
        end

        local count = 0
        if use_prefix then
            -- Function got called from raw converted logic without an item prefix.
            -- EmoTracker knows these items as "OOT_*"" / "MM_*"
            count = get_tracker_count(OOTMM_ITEM_PREFIX .. "_" .. item)
        else
            count = get_tracker_count(item)
        end

        if not min_count then
            return count > 0
        else
            return count >= min_count
        end
    end

    -- Tracker:ProviderCountForCode() calls are excruciatingly slow, this caches the results.
    function get_tracker_count(item_code)
        if OOTMM_DEBUG then
            return Tracker:ProviderCountForCode(item_code)
        end

        local cache_key = "RAW:" .. item_code

        if OOTMM_RUNTIME_CACHE[cache_key] == nil then
            OOTMM_RUNTIME_CACHE[cache_key] = Tracker:ProviderCountForCode(item_code)
        end

        return OOTMM_RUNTIME_CACHE[cache_key]
    end

    function renewable(item)
        -- FIXME: Make sure this is actually OK!
        return has(item)
    end

    function license(item)
        -- FIXME: Make sure this is actually OK!
        return has(item)
    end

    OOTMM_RUNTIME_CURRENT_AGE = "child"
    function age(x)
        return OOTMM_RUNTIME_CURRENT_AGE == x
    end

    function set_age(age)
        if age == "child" or age == "adult" then
            OOTMM_RUNTIME_CURRENT_AGE = age
        else
            error("Invalid age: " .. age)
        end
    end

    OOTMM_ACCESS_LEVELS = {
        -- NOTE: Don't rely on these indexes, they are entirely arbitrary and might change.
        [0] = AccessibilityLevel.None,
        [1] = AccessibilityLevel.SequenceBreak,
        [2] = AccessibilityLevel.Normal,
        [AccessibilityLevel.None] = 0,
        [AccessibilityLevel.SequenceBreak] = 1,
        [AccessibilityLevel.Normal] = 2,
    }
    function update_accessibility(reachable, accessibility)
        -- FIXME: This is currently unused; might be useful in find_available_locations()

        -- These values are used by EmoTracker to color the map squares.
        --
        -- reachable:
        --   0: unreachable
        --   1: reachable
        -- accessibility:
        --   AccessibilityLevel.None (red)
        --   AccessibilityLevel.SequenceBreak (yellow)
        --   AccessibilityLevel.Normal (green)

        if reachable > OOTMM_RUNTIME_ACCESSIBILITY["reachable"] then
            OOTMM_RUNTIME_ACCESSIBILITY["reachable"] = reachable
            OOTMM_RUNTIME_ACCESSIBILITY["accessibility"] = accessibility
        elseif reachable == OOTMM_RUNTIME_ACCESSIBILITY["reachable"] and OOTMM_ACCESS_LEVELS[accessibility] > OOTMM_ACCESS_LEVELS[OOTMM_RUNTIME_ACCESSIBILITY["accessibility"]] then
            OOTMM_RUNTIME_ACCESSIBILITY["accessibility"] = accessibility
        end

        return reachable, accessibility
    end

    function get_trick_mode()
        if OOTMM_RUNTIME_ALL_TRICKS_ENABLED then
            return "all"
        else
            return "selected"
        end
    end

    -- Yet another global with  side effects...
    function set_trick_mode(mode)
        if mode == "all" then
            OOTMM_RUNTIME_ALL_TRICKS_ENABLED = true
        elseif mode == "selected" then
            OOTMM_RUNTIME_ALL_TRICKS_ENABLED = false
        else
            error("Invalid trick mode: " .. mode)
        end
    end

    function trick(x)
        return has(OOTMM_TRICK_PREFIX .. "_" .. x) or OOTMM_RUNTIME_ALL_TRICKS_ENABLED
    end

    function glitch(x)
        return has(OOTMM_GLITCH_PREFIX .. "_" .. x) or OOTMM_RUNTIME_ALL_GLITCHES_ENABLED
    end

    -- Events are active if they CAN LOGICALLY BE reached, not when they HAVE BEEN reached.
    -- Checks show up as green when you actually need to do other things first,
    -- and the sequence of tasks necessary is not obvious unless you're intimately familiar
    -- with the randomizer's logic.
    --
    -- These are used to override the default behavior, and make the tracker more
    -- user friendly.
    OOTMM_EVENT_OVERRIDES = {
        ["OOT"] = {
            ["ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["BOMBCHU"] = { ["type"] = "has" },
            ["BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["MALON"] = { ["type"] = "has" },
            ["MEET_ZELDA"] = { ["type"] = "has" },
            ["MM_ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["MM_BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["NUTS"] = { ["type"] = "return", ["value"] = false },
            ["MM_NUTS"] = { ["type"] = "return", ["value"] = false },
            ["STICKS"] = { ["type"] = "return", ["value"] = false },
            ["MM_STICKS"] = { ["type"] = "return", ["value"] = false },
            ["SEEDS"] = { ["type"] = "return", ["value"] = true },
        },
        ["MM"] = {
            ["ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["BOMBCHU"] = { ["type"] = "has" },
            ["BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["BOMBER_CODE"] = { ["type"] = "has" },
            ["FROG_1"] = { ["type"] = "has" },
            ["FROG_2"] = { ["type"] = "has" },
            ["FROG_3"] = { ["type"] = "has" },
            ["FROG_4"] = { ["type"] = "has" },
            ["NUTS"] = { ["type"] = "return", ["value"] = false },
            ["OOT_NUTS"] = { ["type"] = "return", ["value"] = false },
            ["SEAHORSE"] = { ["type"] = "has" },
            ["STICKS"] = { ["type"] = "return", ["value"] = false },
            ["OOT_STICKS"] = { ["type"] = "return", ["value"] = false },
            ["OOT_ARROWS"] = { ["type"] = "return", ["value"] = true },
            ["OOT_BOMBS"] = { ["type"] = "return", ["value"] = true },
            ["ZORA_EGGS_BARREL_MAZE"] = { ["type"] = "has" },
            ["ZORA_EGGS_HOOKSHOT_ROOM"] = { ["type"] = "has" },
            ["ZORA_EGGS_LONE_GUARD"] = { ["type"] = "has" },
            ["ZORA_EGGS_PINNACLE_ROCK"] = { ["type"] = "has" },
            ["ZORA_EGGS_TREASURE_ROOM"] = { ["type"] = "has" },
        },
    }
    function event(x)
        local override = OOTMM_EVENT_OVERRIDES[OOTMM_ITEM_PREFIX][x]
        if override then
            if override["type"] == "return" then
                return override["value"]
            elseif override["type"] == "has" then
                return has("EVENT_" .. OOTMM_ITEM_PREFIX .. '_' .. x)
            end
        end

        if OOTMM_RUNTIME_STATE.events_active[x] then
            return true
        else
            -- Save the event to a lovely global variable so we can have some side effects in the side effects affecting side effects.
            -- Note that we just care about the events queried for, not whether they're active.
            -- We also don't care about the overrides above, since those don't change during runtime.
            OOTMM_RUNTIME_STATE["_check_rule_events_used"][x] = true
            return false
        end
    end

    function cond(x, y, z)
        if x then
            return y
        else
            return z
        end
    end

    local OOTMM_SETTING_OVERRIDES = {
        ["childWallets"] = true,
        ["progressiveShieldsMm_progressive"] = false,
        ["progressiveShieldsOot_progressive"] = false,
        ["progressiveSwordsOot_goron"] = true,
        ["progressiveSwordsOot_progressive"] = false,
        ["erBoss_none"] = true,
        ["erDungeons_none"] = true,
        ["erIndoors_none"] = true,
        ["erRegions_none"] = true,
        ["erIkanaCastle"] = false,
        ["smallKeyShuffleChestGame_vanilla"] = true,
        ["ageChange_none"] = true,
        ["progressiveSwordsOot_separate"] = true,
        ["progressiveShieldsMm_separate"] = true,
        ["progressiveGFS_separate"] = true,
        ["progressiveShieldsOot_separate"] = true,
        ["colossalWallets"] = true,
    }
    function setting(name, state)
        -- Settings are made available as Tracker items, e.g. for
        -- setting(crossWarpMm, full) -> check if has(setting_crossWarpMm_full)
        local item_name = name
        if state then
            item_name = name .. "_" .. state
        end

        if OOTMM_SETTING_OVERRIDES[item_name] ~= nil then
            return OOTMM_SETTING_OVERRIDES[item_name]
        end

        -- EmoTracker knows boolean settings as progressive items with codes "setting_name_true" and "setting_name_false"
        if not state then
            item_name = item_name .. "_true"
        end

        return has("setting_" .. item_name)
    end

    OOTMM_SPECIAL_ACCESS_CASES = {
        ["BRIDGE"] = true,
        ["LACS"] = true,
        ["MAJORA"] = true,
        ["MOON"] = true,
    }
    function special(case)
        if not OOTMM_SPECIAL_ACCESS_CASES[case] then
            print("Unknown special name: " .. case)
            return false
        end

        local item_names = {
            "OOT_SPIRITUAL_STONE",
            "OOT_MEDALLION",
            "MM_BOSS_REMAIN",
            "OOT_GS_TOKEN",
            "MM_GS_TOKEN_SWAMP",
            "MM_GS_TOKEN_OCEAN",
            "MM_STRAY_FAIRY_TOWN",
            "MM_STRAY_FAIRY_WF",
            "MM_STRAY_FAIRY_SH",
            "MM_STRAY_FAIRY_GB",
            "MM_STRAY_FAIRY_ST",
            "MM_MASK_REGULAR",
            "MM_MASK_TRANSFORM",
            "OOT_MASK",
        }

        local sum = 0
        for _, item_name in pairs(item_names) do
            local setting_name = "setting_" .. case .. "_" .. item_name

            if get_tracker_count(setting_name) == 1 then
                sum = sum + get_tracker_count(item_name)
            end
        end

        local needed = get_tracker_count(case)

        return sum >= needed
    end

    function masks(amount)
        return get_tracker_count(OOTMM_ITEM_PREFIX .. "_" .. "MASK") >= amount
    end

    function oot_time(x) -- FIXME
        return true
    end

    function flag_on(flag) -- FIXME
        return true
    end

    function flag_off(flag) -- FIXME
        return true
    end

    local OOTMM_RUNTIME_CURRENT_TIME = nil
    function mm_time(case, time_a, time_b)
        OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] = true

        if OOTMM_DEBUG then
            print("case", case, "time_a", time_a, "time_b", time_b, "index", MM_TIME_SLICES_INDEX[time_a], "earliest_time",
                OOTMM_RUNTIME_CURRENT_TIME)
        end
        local r = _mm_time(case, time_a, time_b)
        if OOTMM_DEBUG then
            print("mm_time:", case, time_a, time_b, r)
        end
        return r
    end

    function _mm_time(case, time_a, time_b)
        -- Return whether the current time index fits the given case.
        -- The current index is yet another global variable which is "set elsewhere(tm)".
        if OOTMM_RUNTIME_CURRENT_TIME == nil then
            error("Current time slice not set!")
        end

        if OOTMM_RUNTIME_CURRENT_TIME == -1 then
            -- Special case for check_rule()'s event collection
            return false
        end

        if case == "at" then
            return OOTMM_RUNTIME_CURRENT_TIME == MM_TIME_SLICES_INDEX[time_a]
        elseif case == "before" then
            return MM_TIME_SLICES_INDEX[time_a] > OOTMM_RUNTIME_CURRENT_TIME
        elseif case == "after" then
            return MM_TIME_SLICES_INDEX[time_a] <= OOTMM_RUNTIME_CURRENT_TIME
        elseif case == "between" then
            return MM_TIME_SLICES_INDEX[time_a] >= OOTMM_RUNTIME_CURRENT_TIME and OOTMM_RUNTIME_CURRENT_TIME < MM_TIME_SLICES_INDEX[time_b]
        else
            print(case)
            error("Invalid case: " .. case)
        end
    end

    local function set_time(time_index)
        OOTMM_RUNTIME_CURRENT_TIME = time_index
    end

    local OOTMM_RANGE_TO_SETTING = {
        OOT_SHOPS = "priceOotShops",
        OOT_SCRUBS = "priceOotScrubs",
        MM_SHOPS = "priceMmShops",
        MM_SHOPS_EX = "priceMmShops",
        MM_TINGLE = "priceMmTingle",
    }
    function price(range, id, value)
        local price = PRICE_HELPER.default_prices[id + PRICE_HELPER.range_index[range]]

        if not OOTMM_RANGE_TO_SETTING[range] then
            print("price(): Unknown range " .. range)
        end

        if OOTMM_RANGE_TO_SETTING[range] then
            if setting(OOTMM_RANGE_TO_SETTING[range], "affordable") then
                price = 10
            elseif setting(OOTMM_RANGE_TO_SETTING[range], "weighted") then
                price = 0
            elseif setting(OOTMM_RANGE_TO_SETTING[range], "random") then
                price = 0
            elseif not setting(OOTMM_RANGE_TO_SETTING[range], "vanilla") then
                return true
            end
        end

        return price <= value
    end

    function trace(event, line)
        local s = debug.getinfo(2).short_src
        print(s .. ":" .. line)
    end

    -- We need to be able to inject new places into already running find() calls.
    -- We also need to be able to do this in any direction, i.e. from OOT into MM
    -- and vice versa, at any time, and without having to worry about the order.
    -- Lua is pass by reference (by value, but the value is a reference), so we
    -- can just pass the whole state into the find() function every time it is called.

    -- Additionally, we need places in the queue and "restart if event activated" lists to know whether
    -- they were reached as child or adult for easier continuation.

    -- TODO: Turn these into class methods instead, maybe?
    local function add_event_queue_entry(event_queue, event_name, node)
        if not event_queue[event_name] then
            event_queue[event_name] = {}
        end

        table.insert(event_queue[event_name], node)
    end

    local function check_event_queue_entries(event_queue, event_name)
        if not event_queue[event_name] then
            return
        end

        for _, node in pairs(event_queue[event_name]) do
            -- TODO: This might lead to HUGE queues, there's definitely room for optimization here!
            SearchQueue:push(node)
        end

        event_queue[event_name] = nil
    end

    local function add_active_event(node)
        OOTMM_RUNTIME_STATE.events_active[node.name] = node
    end

    -- Update node in-place if "other" is better.
    -- This is yet another big no-no, but it fits in nicely with the other no-nos littered all over this codebase.
    local function update_node_if_better(node, other)
        local other_is_better = false

        -- update if other is better
        -- "better" means it is a lower number if both are numbers,
        -- or it is a number when the local value is nil
        if other.child ~= nil and ((node.child == nil) or (other.child < node.child)) then
            -- other can be reached earlier as child
            node.child = other.child
            other_is_better = true
        end
        if other.adult ~= nil and ((node.adult == nil) or (other.adult < node.adult)) then
            -- other can be reached earlier as adult
            node.adult = other.adult
            other_is_better = true
        end

        return other_is_better
    end

    local CUSTOM_EVENT_ITEMS_LOCATIONS = {
        ["Bottom of the Well SR 1"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 2"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 3"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 4"] = "RUPEE_SILVER_BOTW",
        ["Bottom of the Well SR 5"] = "RUPEE_SILVER_BOTW",
        ["Ganon Castle SR Fire Back Right"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Black Pillar"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Far Right"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Front Right"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Fire Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["Ganon Castle SR Forest Back Middle"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Back Right"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Center Left"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Center Right"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Forest Front"] = "RUPEE_SILVER_GANON_FOREST",
        ["Ganon Castle SR Light Alcove Left"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Alcove Right"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Center Left"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Center Right"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Light Center Top"] = "RUPEE_SILVER_GANON_LIGHT",
        ["Ganon Castle SR Spirit Back Left"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Back Right"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Center Bottom"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Center Midair"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Ganon Castle SR Spirit Front Right"] = "RUPEE_SILVER_GANON_SPIRIT",
        ["Gerudo Training Grounds SR Lava Back Center"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Back Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Back Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Front Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Lava Front Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["Gerudo Training Grounds SR Slope Back"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Center"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Front Above"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Front Left"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Slope Front Right"] = "RUPEE_SILVER_GTG_SLOPES",
        ["Gerudo Training Grounds SR Water 1"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 2"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 3"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 4"] = "RUPEE_SILVER_GTG_WATER",
        ["Gerudo Training Grounds SR Water 5"] = "RUPEE_SILVER_GTG_WATER",
        ["Ice Cavern SR Blocks Alcove"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Back Left"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Back Right"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Center"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Blocks Front Left"] = "RUPEE_SILVER_IC_BLOCK",
        ["Ice Cavern SR Scythe Back"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Center Left"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Center Right"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Left"] = "RUPEE_SILVER_IC_SCYTHE",
        ["Ice Cavern SR Scythe Midair"] = "RUPEE_SILVER_IC_SCYTHE",
        ["MQ Dodongo Cavern SR Beamos"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Crate"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Upper Corner High"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Upper Corner Low"] = "RUPEE_SILVER_DC",
        ["MQ Dodongo Cavern SR Vines"] = "RUPEE_SILVER_DC",
        ["MQ Ganon Castle SR Fire Back-Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire Center-Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire Front-Left"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire High Above Lava"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Fire Under Pillar"] = "RUPEE_SILVER_GANON_FIRE",
        ["MQ Ganon Castle SR Shadow Back-Center"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Back-Left"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Front-Center"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Front-Right"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Shadow Middle"] = "RUPEE_SILVER_GANON_SHADOW",
        ["MQ Ganon Castle SR Water Above Ground"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Alcove"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Deep Hole"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Shallow Hole"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Ganon Castle SR Water Under Alcove"] = "RUPEE_SILVER_GANON_WATER",
        ["MQ Gerudo Training Grounds SR Lava Back-Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Back-Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Center"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Front"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Front-Left"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Lava Front-Right"] = "RUPEE_SILVER_GTG_LAVA",
        ["MQ Gerudo Training Grounds SR Slopes Front"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Front-Left"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Front-Right"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Middle"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Slopes Top Right"] = "RUPEE_SILVER_GTG_SLOPES",
        ["MQ Gerudo Training Grounds SR Water Bottom-Right"] = "RUPEE_SILVER_GTG_WATER",
        ["MQ Gerudo Training Grounds SR Water Center"] = "RUPEE_SILVER_GTG_WATER",
        ["MQ Gerudo Training Grounds SR Water Top-Left"] = "RUPEE_SILVER_GTG_WATER",
        ["MQ Shadow Temple SR Invisible Blades Ground 1"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 2"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 3"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 4"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 5"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 6"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 7"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 8"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Ground 9"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Invisible Blades Time Block"] = "RUPEE_SILVER_SHADOW_BLADES",
        ["MQ Shadow Temple SR Pit Back"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Front"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Midair High"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Midair Low"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Pit Right"] = "RUPEE_SILVER_SHADOW_PIT",
        ["MQ Shadow Temple SR Scythe 1"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 2"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 3"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 4"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Scythe 5"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["MQ Shadow Temple SR Spikes Center Ground"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Center Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Center Platforms"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Front Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Left Corner"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Left Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Left Wall"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Right Back Wall"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Right Ground"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Shadow Temple SR Spikes Right Lateral Wall"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["MQ Spirit Temple SR Adult Bottom"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Bottom-Center"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Center-Top"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Skulltula"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Adult Top"] = "RUPEE_SILVER_SPIRIT_ADULT",
        ["MQ Spirit Temple SR Lobby After Water Near Door"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby After Water Near Stairs"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby In Water"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby Rock Left"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["MQ Spirit Temple SR Lobby Rock Right"] = "RUPEE_SILVER_SPIRIT_LOBBY",
        ["Shadow Temple SR Pit 1"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 2"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 3"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 4"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Pit 5"] = "RUPEE_SILVER_SHADOW_PIT",
        ["Shadow Temple SR Scythe 1"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 2"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 3"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 4"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Scythe 5"] = "RUPEE_SILVER_SHADOW_SCYTHE",
        ["Shadow Temple SR Spikes Back Left"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Center"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Front Left"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Midair"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Shadow Temple SR Spikes Right"] = "RUPEE_SILVER_SHADOW_SPIKES",
        ["Spirit Temple SR Boulders 1"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 2"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 3"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 4"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Boulders 5"] = "RUPEE_SILVER_SPIRIT_BOULDERS",
        ["Spirit Temple SR Child 1"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 2"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 3"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 4"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Child 5"] = "RUPEE_SILVER_SPIRIT_CHILD",
        ["Spirit Temple SR Sun 1"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 2"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 3"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 4"] = "RUPEE_SILVER_SPIRIT_SUN",
        ["Spirit Temple SR Sun 5"] = "RUPEE_SILVER_SPIRIT_SUN",
    }
    local function check_rule(node, earliest_time, used_events)
        -- Check the rule and return its result as well as all used events.
        OOTMM_RUNTIME_STATE["_check_rule_events_used"] = {}
        OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] = false

        if earliest_time == nil then
            earliest_time = 1
        end

        -- Find the earliest time for which the rule is true by iterating over all possible times, starting at the previous earliest_time.
        set_time(earliest_time)
        local result = node.rule()

        -- Make sure we're actually allowed to stay in this time slice.
        -- node.mm_stay is a dict with time slice keys with further rules for each of them.
        -- If node.mm_stay is nil, or node.mm_stay[earliest_time] is nil, there are no restrictions.
        -- if node.mm_stay[earliest_time]() is true, we can stay.
        -- If node.mm_stay[earliest_time]() is false, we're not allowed to stay.
        -- if node.mm_stay then
        --     print("mm_stay", earliest_time, node.mm_stay)
        --     for k, v in pairs(node.mm_stay) do
        --         print(k, v)
        --     end
        --     -- -- print("mm_stay", earliest_time, node.mm_stay[earliest_time])
        -- end

        local can_stay = (not node.mm_stay or not node.mm_stay[MM_TIME_SLICES[earliest_time]] or node.mm_stay[MM_TIME_SLICES[earliest_time]]())
        result = result and can_stay

        -- FIXME: If this is false because of an mm_stay rule, we should not try to increase earliest_time in the loop below, but abort here! (this is fixed, but doesn't actually fix the logic - there's a new problem now!)

        -- FIXME: We'll probably need to start saving all time slices for which the current place/location/whatever is true. Keeping track of only the earliest one is not enough anymore ever since "stay" was added to the randomizer's logic.

        while can_stay and not result and OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] and earliest_time < #MM_TIME_SLICES do
            earliest_time = earliest_time + 1
            set_time(earliest_time)
            result = node.rule()
            can_stay = (not node.mm_stay or not node.mm_stay[MM_TIME_SLICES[earliest_time]] or node.mm_stay[MM_TIME_SLICES[earliest_time]]())
            result = result and can_stay
        end

        -- Try to find events used even for rules like this (an exit):
        --   ["Near Romani Ranch"] = function () return after(DAY3_AM_06_00) or can_use_keg() end,
        -- where, if can_use_keg() is true, the time at which we can reach "Near Romani Ranch" could be earlier than DAY3_AM_06_00.
        -- This means that this node will have to revisited once the BUY_KEG event is active, but if we first reach this
        -- node at DAY3_AM_06_00, we will never trigger the BUY_KEG event check.
        --
        -- TODO: Make sure there is no combination of rules for which this STILL won't return used events...
        set_time(-1)                 -- Make all time checks return false
        local _ignored = node.rule() -- We don't care about the result, we just want to check which events were used.

        if not result then
            earliest_time = nil
        end

        if used_events == nil then
            used_events = {}
        end

        for k, _ in pairs(OOTMM_RUNTIME_STATE["_check_rule_events_used"]) do
            used_events[k] = true
        end

        -- Handle special "custom event items"
        if result and CUSTOM_EVENT_ITEMS_LOCATIONS[node.name] then
            local item = CUSTOM_EVENT_ITEMS_LOCATIONS[node.name]
            local amount = OOTMM_RUNTIME_STATE["custom_event_items"][item] or 0
            amount = amount + 1

            OOTMM_RUNTIME_STATE["custom_event_items"][item] = amount

            -- Add custom event to the queue so normal event handling takes care of the rest
            SearchQueue:push(new_node({
                type = "event",
                name = "CUSTOM_EVENT_" .. item .. ":" .. amount,
                child = 1, -- FIXME: This is questionable at best...
                adult = 1, -- FIXME: Also questionable...
                rule = function() return true end
            }))
        end

        -- TODO: Saving tricks, we could probably save a lot of time here by not starting from scratch for sequence breaks?
        return result, earliest_time, used_events, OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"]
    end

    local function get_logic(name)
        return logic[name]
    end

    function search()
        -- Run until a new event is found, or all places have been checked.
        -- Only searching until a new event is found will lead to slightly lowered runtime, because we need to add
        -- fewer places/locations to the queue in total. Whether it's actually measurably faster is questionable,
        -- but we'll do it anyway.

        -- If the incoming node is an exit node, run its checks for the ages the node has been seen as. Save that info, then add it to any exits/events/locations for the new place if node.rule() is true.
        -- If we don't save the info, but instead add two nodes for any exit that is valid for both child and adult, nothing breaks. It's just a bit more work later on.

        local result = {
            -- ["events_found"] = {},     -- newly found events (possibly some for different worlds!)
            ["activated_nodes"] = {},                                          -- newly active nodes, possibly for different worlds!
            ["places_available"] = OOTMM_RUNTIME_STATE.places_available,       -- all available places for this logic module
            ["locations_available"] = OOTMM_RUNTIME_STATE.locations_available, -- all available locations for this logic module
            ["events_active"] = OOTMM_RUNTIME_STATE.events_active,             -- all known active events for this logic module
        }

        local current = SearchQueue:pop()
        while current ~= nil do
            local events_used = {}
            local active = { child = false, adult = false, }
            local earliest_child = nil       -- earliest time index at which this node's rule() is true; nil otherwise
            local earliest_adult = nil
            local mm_time_used_child = false -- true if rule() made use of mm_time
            local mm_time_used_adult = false

            if current.child then
                set_age("child")
                active.child, earliest_child, events_used, mm_time_used_child = check_rule(current, current.child,
                    events_used)
            end
            if current.adult then
                set_age("adult")
                active.adult, earliest_adult, events_used, mm_time_used_adult = check_rule(current, current.adult,
                    events_used)
            end

            if active.child or active.adult then
                local activated_current = new_node(current)
                activated_current.child = earliest_child
                activated_current.adult = earliest_adult
                table.insert(result["activated_nodes"], activated_current)
                if current.type == "exit" then
                    local place_logic = get_logic(current.name) -- can be nil!
                    local saved_place = result.places_available[current.name]
                    if place_logic and (saved_place == nil or update_node_if_better(saved_place, activated_current)) then
                        for new_type, new_rules in pairs(place_logic) do
                            if new_type ~= "exits" and new_type ~= "events" and new_type ~= "locations" then
                                -- Ignore anything but these three; they're special cases.
                                -- At the time of writing, the only other type is "mm_stay",
                                -- but reversing this rule would potentially lead to problems
                                -- in the future.
                                goto continue
                            end
                            for new_name, new_rule in pairs(new_rules) do
                                local node = new_node(activated_current)
                                node.type = string.sub(new_type, 1, -2) -- exits -> exit; events -> event; locations -> location
                                node.name = new_name
                                node.rule = new_rule
                                node.child = earliest_child
                                node.adult = earliest_adult
                                node.mm_stay = place_logic["stay"] -- nil is fine here

                                -- node.prev = current
                                SearchQueue:push(node)
                            end
                            ::continue::
                        end
                    end
                    if saved_place == nil then
                        -- This will mark "OOT Foo" / "MM Bar" as available, too.
                        -- That is not correct, but we can just ignore that for now because places_available is never actually passed to the EmoTracker layer.
                        result.places_available[current.name] = activated_current
                    end
                elseif current.type == "event" then
                    add_active_event(activated_current)
                    check_event_queue_entries(OOTMM_RUNTIME_STATE["events_to_revisit"], current.name)
                    -- break -- TODO: Maybe reactivate this for speed of event juggling?
                elseif current.type == "location" then
                    -- Setting the location to the current node will allow for "upgrades",
                    -- i.e. when encountering a location as adult that has only been reached as child before.
                    -- Keeping this info is not strictly necessary, but it's nice for debugging.
                    local prev = result.locations_available[current.name]
                    if prev then
                        update_node_if_better(prev, activated_current)
                    else
                        result.locations_available[current.name] = activated_current
                    end
                end
            end

            -- FIXME: Handle "both failed" and "only one of them failed" cases.
            --        For now, just re-check the whole node for all used events regardless of age().
            if not active.child or not active.adult or (mm_time_used_child and earliest_child > 1) or (mm_time_used_adult and earliest_adult > 1) then
                -- If events were checked during rule application, make sure to revisit
                -- this node if any of them get activated later.
                for event_name, _ in pairs(events_used) do
                    add_event_queue_entry(OOTMM_RUNTIME_STATE["events_to_revisit"], event_name, current)
                end
            end

            current = SearchQueue:pop()
        end

        return result
    end

    	function has_magic_jar()
		return cond(setting('sharedMagic'), renewable(SHARED_MAGIC_JAR_SMALL) or renewable(SHARED_MAGIC_JAR_LARGE), renewable(MAGIC_JAR_SMALL) or renewable(MAGIC_JAR_LARGE))
	end

	function can_use_din_raw()
		return has_magic() and cond(setting('sharedSpellFire'), has('SHARED_SPELL_FIRE'), has('SPELL_FIRE'))
	end

	function can_use_farore_raw()
		return has_magic() and cond(setting('sharedSpellWind'), has('SHARED_SPELL_WIND'), has('SPELL_WIND'))
	end

	function can_use_nayru_raw()
		return has_magic() and cond(setting('sharedSpellLove'), has('SHARED_SPELL_LOVE'), has('SPELL_LOVE'))
	end

	function has_iron_boots_raw()
		return cond(setting('sharedBootsIron'), has('SHARED_BOOTS_IRON'), has('BOOTS_IRON'))
	end

	function has_hover_boots_raw()
		return cond(setting('sharedBootsHover'), has('SHARED_BOOTS_HOVER'), has('BOOTS_HOVER'))
	end

	function has_tunic_goron_raw()
		return cond(setting('sharedTunicGoron'), has('SHARED_TUNIC_GORON'), has('TUNIC_GORON'))
	end

	function has_tunic_zora_raw()
		return cond(setting('sharedTunicZora'), has('SHARED_TUNIC_ZORA'), has('TUNIC_ZORA'))
	end

	function has_elegy_raw()
		return cond(setting('sharedSongElegy'), has('SHARED_SONG_EMPTINESS'), has('SONG_EMPTINESS'))
	end

	function has_scale_raw(x)
		return cond(setting('sharedScales'), has('SHARED_SCALE', x), has('SCALE', x))
	end

	function has_strength_raw(x)
		return cond(setting('sharedStrength'), has('SHARED_STRENGTH', x), has('STRENGTH', x))
	end

	function soul_octorok()
		return soul_enemy(SOUL_ENEMY_OCTOROK) or soul_enemy(SHARED_SOUL_ENEMY_OCTOROK)
	end

	function soul_wallmaster()
		return soul_enemy(SOUL_ENEMY_WALLMASTER) or soul_enemy(SHARED_SOUL_ENEMY_WALLMASTER)
	end

	function soul_dodongo()
		return soul_enemy(SOUL_ENEMY_DODONGO) or soul_enemy(SHARED_SOUL_ENEMY_DODONGO)
	end

	function soul_keese()
		return soul_enemy(SOUL_ENEMY_KEESE) or soul_enemy(SHARED_SOUL_ENEMY_KEESE)
	end

	function soul_tektite()
		return soul_enemy(SOUL_ENEMY_TEKTITE) or soul_enemy(SHARED_SOUL_ENEMY_TEKTITE)
	end

	function soul_peahat()
		return soul_enemy(SOUL_ENEMY_PEAHAT) or soul_enemy(SHARED_SOUL_ENEMY_PEAHAT)
	end

	function soul_lizalfos_dinalfos()
		return soul_enemy(SOUL_ENEMY_LIZALFOS_DINALFOS) or soul_enemy(SHARED_SOUL_ENEMY_LIZALFOS_DINALFOS)
	end

	function soul_skulltula()
		return soul_enemy(SOUL_ENEMY_SKULLTULA) or soul_enemy(SHARED_SOUL_ENEMY_SKULLTULA)
	end

	function soul_armos()
		return soul_enemy(SOUL_ENEMY_ARMOS) or soul_enemy(SHARED_SOUL_ENEMY_ARMOS)
	end

	function soul_deku_baba()
		return soul_enemy(SOUL_ENEMY_DEKU_BABA) or soul_enemy(SHARED_SOUL_ENEMY_DEKU_BABA)
	end

	function soul_deku_scrub()
		return soul_enemy(SOUL_ENEMY_DEKU_SCRUB) or soul_enemy(SHARED_SOUL_ENEMY_DEKU_SCRUB)
	end

	function soul_bubble()
		return soul_enemy(SOUL_ENEMY_BUBBLE) or soul_enemy(SHARED_SOUL_ENEMY_BUBBLE)
	end

	function soul_beamos()
		return soul_enemy(SOUL_ENEMY_BEAMOS) or soul_enemy(SHARED_SOUL_ENEMY_BEAMOS)
	end

	function soul_redead_gibdo()
		return soul_enemy(SOUL_ENEMY_REDEAD_GIBDO) or soul_enemy(SHARED_SOUL_ENEMY_REDEAD_GIBDO)
	end

	function soul_skullwalltula()
		return soul_enemy(SOUL_ENEMY_SKULLWALLTULA) or soul_enemy(SHARED_SOUL_ENEMY_SKULLWALLTULA)
	end

	function soul_shell_blade()
		return soul_enemy(SOUL_ENEMY_SHELL_BLADE) or soul_enemy(SHARED_SOUL_ENEMY_SHELL_BLADE)
	end

	function soul_like_like()
		return soul_enemy(SOUL_ENEMY_LIKE_LIKE) or soul_enemy(SHARED_SOUL_ENEMY_LIKE_LIKE)
	end

	function soul_iron_knuckle()
		return soul_enemy(SOUL_ENEMY_IRON_KNUCKLE) or soul_enemy(SHARED_SOUL_ENEMY_IRON_KNUCKLE)
	end

	function soul_freezard()
		return soul_enemy(SOUL_ENEMY_FREEZARD) or soul_enemy(SHARED_SOUL_ENEMY_FREEZARD)
	end

	function soul_wolfos()
		return soul_enemy(SOUL_ENEMY_WOLFOS) or soul_enemy(SHARED_SOUL_ENEMY_WOLFOS)
	end

	function soul_guay()
		return soul_enemy(SOUL_ENEMY_GUAY) or soul_enemy(SHARED_SOUL_ENEMY_GUAY)
	end

	function soul_flying_pot()
		return soul_enemy(SOUL_ENEMY_FLYING_POT) or soul_enemy(SHARED_SOUL_ENEMY_FLYING_POT)
	end

	function soul_floormaster()
		return soul_enemy(SOUL_ENEMY_FLOORMASTER) or soul_enemy(SHARED_SOUL_ENEMY_FLOORMASTER)
	end

	function soul_leever()
		return soul_enemy(SOUL_ENEMY_LEEVER) or soul_enemy(SHARED_SOUL_ENEMY_LEEVER)
	end

	function soul_stalchild()
		return soul_enemy(SOUL_ENEMY_STALCHILD) or soul_enemy(SHARED_SOUL_ENEMY_STALCHILD)
	end

	function shared_soul_misc(a, b)
		return cond(setting('sharedSoulsMisc'), soul_misc(b), soul_misc(a))
	end

	function soul_gs()
		return shared_soul_misc(SOUL_MISC_GS, SHARED_SOUL_MISC_GS)
	end

	function soul_business_scrub()
		return shared_soul_misc(SOUL_MISC_BUSINESS_SCRUB, SHARED_SOUL_MISC_BUSINESS_SCRUB)
	end

	function shared_soul_npc(a, b)
		return cond(setting('sharedSoulsNpc'), soul_npc(b), soul_npc(a))
	end

	function soul_banker()
		return shared_soul_npc(SOUL_NPC_BANKER, SHARED_SOUL_NPC_BANKER)
	end

	function soul_astronomer()
		return shared_soul_npc(SOUL_NPC_ASTRONOMER, SHARED_SOUL_NPC_ASTRONOMER)
	end

	function soul_gorman()
		return shared_soul_npc(SOUL_NPC_GORMAN, SHARED_SOUL_NPC_GORMAN)
	end

	function soul_honey_darling()
		return shared_soul_npc(SOUL_NPC_HONEY_DARLING, SHARED_SOUL_NPC_HONEY_DARLING)
	end

	function soul_composer_bros()
		return shared_soul_npc(SOUL_NPC_COMPOSER_BROS, SHARED_SOUL_NPC_COMPOSER_BROS)
	end

	function soul_citizen()
		return shared_soul_npc(SOUL_NPC_CITIZEN, SHARED_SOUL_NPC_CITIZEN)
	end

	function soul_bombers()
		return shared_soul_npc(SOUL_NPC_BOMBERS, SHARED_SOUL_NPC_BOMBERS)
	end

	function soul_fishing_pond_owner()
		return shared_soul_npc(SOUL_NPC_FISHING_POND_OWNER, SHARED_SOUL_NPC_FISHING_POND_OWNER)
	end

	function soul_zora_shopkeeper()
		return shared_soul_npc(SOUL_NPC_ZORA_SHOPKEEPER, SHARED_SOUL_NPC_ZORA_SHOPKEEPER)
	end

	function soul_zora()
		return shared_soul_npc(SOUL_NPC_ZORA, SHARED_SOUL_NPC_ZORA)
	end

	function soul_goron_shopkeeper()
		return shared_soul_npc(SOUL_NPC_GORON_SHOPKEEPER, SHARED_SOUL_NPC_GORON_SHOPKEEPER)
	end

	function soul_medigoron()
		return shared_soul_npc(SOUL_NPC_MEDIGORON, SHARED_SOUL_NPC_MEDIGORON)
	end

	function soul_goron()
		return shared_soul_npc(SOUL_NPC_GORON, SHARED_SOUL_NPC_GORON)
	end

	function soul_goron_child()
		return shared_soul_npc(SOUL_NPC_GORON_CHILD, SHARED_SOUL_NPC_GORON_CHILD)
	end

	function soul_biggoron()
		return shared_soul_npc(SOUL_NPC_BIGGORON, SHARED_SOUL_NPC_BIGGORON)
	end

	function soul_dampe()
		return shared_soul_npc(SOUL_NPC_DAMPE, SHARED_SOUL_NPC_DAMPE)
	end

	function soul_guru_guru()
		return shared_soul_npc(SOUL_NPC_GURU_GURU, SHARED_SOUL_NPC_GURU_GURU)
	end

	function soul_talon()
		return shared_soul_npc(SOUL_NPC_TALON, SHARED_SOUL_NPC_TALON)
	end

	function soul_malon()
		return shared_soul_npc(SOUL_NPC_MALON, SHARED_SOUL_NPC_MALON)
	end

	function soul_bombchu_bowling_lady()
		return shared_soul_npc(SOUL_NPC_BOMBCHU_BOWLING_LADY, SHARED_SOUL_NPC_BOMBCHU_BOWLING_LADY)
	end

	function soul_shooting_gallery_owner()
		return shared_soul_npc(SOUL_NPC_SHOOTING_GALLERY_OWNER, SHARED_SOUL_NPC_SHOOTING_GALLERY_OWNER)
	end

	function soul_poe_collector()
		return shared_soul_npc(SOUL_NPC_POE_COLLECTOR, SHARED_SOUL_NPC_POE_COLLECTOR)
	end

	function soul_bazaar_shopkeeper()
		return shared_soul_npc(SOUL_NPC_BAZAAR_SHOPKEEPER, SHARED_SOUL_NPC_BAZAAR_SHOPKEEPER)
	end

	function soul_bombchu_shopkeeper()
		return shared_soul_npc(SOUL_NPC_BOMBCHU_SHOPKEEPER, SHARED_SOUL_NPC_BOMBCHU_SHOPKEEPER)
	end

	function soul_ruto()
		return shared_soul_npc(SOUL_NPC_RUTO, SHARED_SOUL_NPC_RUTO)
	end

	function soul_anju()
		return shared_soul_npc(SOUL_NPC_ANJU, SHARED_SOUL_NPC_ANJU)
	end

	function soul_carpenters()
		return shared_soul_npc(SOUL_NPC_CARPENTERS, SHARED_SOUL_NPC_CARPENTERS)
	end

	function soul_chest_game_owner()
		return shared_soul_npc(SOUL_NPC_CHEST_GAME_OWNER, SHARED_SOUL_NPC_CHEST_GAME_OWNER)
	end

	function soul_rooftop_man()
		return shared_soul_npc(SOUL_NPC_ROOFTOP_MAN, SHARED_SOUL_NPC_ROOFTOP_MAN)
	end

	function soul_bean_salesman()
		return shared_soul_npc(SOUL_NPC_BEAN_SALESMAN, SHARED_SOUL_NPC_BEAN_SALESMAN)
	end

	function soul_scientist()
		return shared_soul_npc(SOUL_NPC_SCIENTIST, SHARED_SOUL_NPC_SCIENTIST)
	end

	function soul_grog()
		return shared_soul_npc(SOUL_NPC_GROG, SHARED_SOUL_NPC_GROG)
	end

	function soul_dog_lady()
		return shared_soul_npc(SOUL_NPC_DOG_LADY, SHARED_SOUL_NPC_DOG_LADY)
	end

	function soul_carpet_man()
		return shared_soul_npc(SOUL_NPC_CARPET_MAN, SHARED_SOUL_NPC_CARPET_MAN)
	end

	function soul_old_hag()
		return shared_soul_npc(SOUL_NPC_OLD_HAG, SHARED_SOUL_NPC_OLD_HAG)
	end

	function is_goal_triforce()
		return setting('goal', 'triforce') or setting('goal', 'triforce3')
	end

	function is_child()
		return age('child')
	end

	function is_adult()
		return age('adult')
	end

	function is_day()
		return oot_time('day') or can_play_sun()
	end

	function is_night()
		return oot_time('night') or can_play_sun()
	end

	function is_dusk()
		return oot_time('day') and oot_time('night')
	end

	function time_travel_at_will()
		return not setting('ageChange', 'none') and event('TIME_TRAVEL_AT_WILL')
	end

	function can_use_din()
		return can_use_din_raw()
	end

	function can_use_farore()
		return can_use_farore_raw()
	end

	function can_use_nayru()
		return can_use_nayru_raw()
	end

	function ocarina_button(x, y)
		return cond(setting('ocarinaButtonsShuffleOot'), cond(setting('sharedOcarinaButtons'), has(y), has(x)), true)
	end

	function ocarina_button_a()
		return ocarina_button(BUTTON_A, SHARED_BUTTON_A)
	end

	function ocarina_button_right()
		return ocarina_button(BUTTON_C_RIGHT, SHARED_BUTTON_C_RIGHT)
	end

	function ocarina_button_left()
		return ocarina_button(BUTTON_C_LEFT, SHARED_BUTTON_C_LEFT)
	end

	function ocarina_button_up()
		return ocarina_button(BUTTON_C_UP, SHARED_BUTTON_C_UP)
	end

	function ocarina_button_down()
		return ocarina_button(BUTTON_C_DOWN, SHARED_BUTTON_C_DOWN)
	end

	function ocarina_button_any2()
		return ocarina_button_any2_a() or ocarina_button_any2_right() or ocarina_button_any2_left() or ocarina_button_any2_up()
	end

	function ocarina_button_any2_a()
		return ocarina_button_a() and (ocarina_button_right() or ocarina_button_left() or ocarina_button_up() or ocarina_button_down())
	end

	function ocarina_button_any2_right()
		return ocarina_button_right() and (ocarina_button_left() or ocarina_button_up() or ocarina_button_down())
	end

	function ocarina_button_any2_left()
		return ocarina_button_left() and (ocarina_button_up() or ocarina_button_down())
	end

	function ocarina_button_any2_up()
		return ocarina_button_up() and ocarina_button_down()
	end

	function has_ocarina()
		return glitch_ocarina_items() or has('OCARINA') or has('SHARED_OCARINA')
	end

	function has_ocarina_of_time()
		return has('OCARINA', 2) or has('SHARED_OCARINA', 2)
	end

	function can_play(x)
		return has_ocarina() and has(x)
	end

	function can_play_cross(x)
		return can_play(x) and (setting('crossWarpMm', 'full') or (setting('crossWarpMm', 'childOnly') and is_child()))
	end

	function can_play_sun()
		return (can_play(SONG_SUN) or can_play(SHARED_SONG_SUN)) and ocarina_button_right() and ocarina_button_down() and ocarina_button_up()
	end

	function can_play_time()
		return (can_play(SONG_TIME) or can_play(SHARED_SONG_TIME)) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down()
	end

	function can_play_epona()
		return (can_play(SONG_EPONA) or can_play(SHARED_SONG_EPONA)) and ocarina_button_up() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_storms()
		return (can_play(SONG_STORMS) or can_play(SHARED_SONG_STORMS)) and ocarina_button_a() and ocarina_button_down() and ocarina_button_up()
	end

	function can_play_zelda()
		return can_play(SONG_ZELDA) and ocarina_button_up() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_saria()
		return can_play(SONG_SARIA) and ocarina_button_down() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_tp_light()
		return can_play(SONG_TP_LIGHT) and ocarina_button_up() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_tp_forest()
		return can_play(SONG_TP_FOREST) and ocarina_button_a() and ocarina_button_up() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_tp_fire()
		return can_play(SONG_TP_FIRE) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down()
	end

	function can_play_tp_water()
		return can_play(SONG_TP_WATER) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down() and ocarina_button_left()
	end

	function can_play_tp_shadow()
		return can_play(SONG_TP_SHADOW) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down() and ocarina_button_left()
	end

	function can_play_tp_spirit()
		return can_play(SONG_TP_SPIRIT) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down()
	end

	function can_play_elegy()
		return has_ocarina() and has_elegy_raw() and ocarina_button_down() and ocarina_button_left() and ocarina_button_right() and ocarina_button_up()
	end

	function can_play_minigame()
		return has_ocarina() and ocarina_button_a() and ocarina_button_right() and ocarina_button_down() and ocarina_button_left() and ocarina_button_up()
	end

	function can_play_scarecrow()
		return has_ocarina() and ocarina_button_any2()
	end

	function can_play_cross_soaring()
		return can_play_cross(MM_SONG_SOARING) and ocarina_button_up() and ocarina_button_down() and ocarina_button_left()
	end

	function has_sticks()
		return event('STICKS') or renewable(STICK) or renewable(STICKS_5) or renewable(STICKS_10) or renewable(SHARED_STICK) or renewable(SHARED_STICKS_5) or renewable(SHARED_STICKS_10) or (setting('sharedNutsSticks') and event('MM_STICKS'))
	end

	function has_nuts()
		return event('NUTS') or renewable(NUTS_5) or renewable(NUTS_10) or renewable(SHARED_NUT) or renewable(SHARED_NUTS_5) or renewable(SHARED_NUTS_10) or (setting('sharedNutsSticks') and event('MM_NUTS'))
	end

	function can_use_sticks()
		return age_sticks() and has_sticks()
	end

	function has_bomb_bag()
		return has('BOMB_BAG') or has('SHARED_BOMB_BAG')
	end

	function has_bombs()
		return has_bomb_bag() and (event('BOMBS') or event('BOMBS_OR_BOMBCHU') or (setting('sharedBombBags') and (event('MM_BOMBS') or event('MM_BOMBS_OR_BOMBCHU'))) or renewable(BOMBS_5) or renewable(BOMBS_10) or renewable(BOMBS_20) or renewable(BOMBS_30) or renewable(SHARED_BOMBS_5) or renewable(SHARED_BOMBS_10) or renewable(SHARED_BOMBS_20) or renewable(SHARED_BOMBS_30))
	end

	function has_bombchu_source()
		return event('BOMBCHU') or renewable(BOMBCHU_5) or renewable(BOMBCHU_10) or renewable(BOMBCHU_20) or (setting('bombchuBagOot') and event('BOMBS_OR_BOMBCHU')) or (setting('sharedBombchuBags') and (renewable(SHARED_BOMBCHU) or renewable(SHARED_BOMBCHU_5) or renewable(SHARED_BOMBCHU_10) or renewable(SHARED_BOMBCHU_20) or event('MM_BOMBCHU') or event('MM_BOMBS_OR_BOMBCHU')))
	end

	function has_bombchu_license_nonshared()
		return license(BOMBCHU_5) or license(BOMBCHU_10) or license(BOMBCHU_20)
	end

	function has_bombchu_license_shared()
		return license(SHARED_BOMBCHU) or license(SHARED_BOMBCHU_5) or license(SHARED_BOMBCHU_10) or license(SHARED_BOMBCHU_20)
	end

	function has_bombchu_license()
		return cond(setting('bombchuBagOot'), cond(setting('sharedBombchuBags'), has_bombchu_license_shared(), has_bombchu_license_nonshared()), has_bomb_bag())
	end

	function has_bombchu()
		return has_bombchu_source() and has_bombchu_license()
	end

	function can_use_slingshot()
		return has('SLINGSHOT') and (is_child() and (event('SEEDS') or renewable(DEKU_SEEDS_30)) or (is_adult() and glitch_equip_swap() and can_use_bow()))
	end

	function has_bow()
		return has('BOW') or has('SHARED_BOW')
	end

	function has_arrows()
		return has_bow() and (event('ARROWS') or renewable(ARROWS_5) or renewable(ARROWS_10) or renewable(ARROWS_30) or renewable(SHARED_ARROWS_5) or renewable(SHARED_ARROWS_10) or renewable(SHARED_ARROWS_30) or renewable(SHARED_ARROWS_40) or (setting('sharedBows') and event('MM_ARROWS')))
	end

	function can_use_bow()
		return is_adult() and has_arrows()
	end

	function has_hookshot(x)
		return has('HOOKSHOT', x) or has('SHARED_HOOKSHOT', x)
	end

	function can_hookshot_n(x)
		return age_hookshot() and has_hookshot(x)
	end

	function can_hookshot()
		return can_hookshot_n(1)
	end

	function can_longshot()
		return can_hookshot_n(2)
	end

	function can_boomerang()
		return age_boomerang() and has('BOOMERANG')
	end

	function can_hammer()
		return age_hammer() and has('HAMMER')
	end

	function has_bottle()
		return has('BOTTLE_EMPTY') or has('BOTTLE_MILK') or has('BOTTLE_POTION_RED') or has('BOTTLE_POTION_GREEN') or has('BOTTLE_POTION_BLUE') or (event('KING_ZORA_LETTER') and soul_npc(SOUL_NPC_KING_ZORA)) or has('BOTTLE_FAIRY') or has('BOTTLE_POE') or has('BOTTLE_BIG_POE') or has('BOTTLE_BLUE_FIRE')
	end

	function has_big_poe()
		return has_bottle() and (event('BIG_POE') or renewable(BOTTLE_BIG_POE) or renewable(BIG_POE))
	end

	function can_use_beans()
		return is_child() and has('MAGIC_BEAN')
	end

	function age_sticks()
		return glitch_equip_swap() or is_child() or setting('agelessSticks')
	end

	function age_boomerang()
		return glitch_equip_swap() or is_child() or setting('agelessBoomerang')
	end

	function age_boomerang_anyage()
		return glitch_equip_swap_anyage() or setting('agelessBoomerang')
	end

	function age_hammer()
		return glitch_equip_swap() or is_adult() or setting('agelessHammer')
	end

	function age_hookshot()
		return glitch_equip_swap() or is_adult() or setting('agelessHookshot')
	end

	function age_hookshot_anyage()
		return glitch_equip_swap_anyage() or setting('agelessHookshot')
	end

	function age_sword_child()
		return is_child() or setting('agelessSwords')
	end

	function age_sword_adult()
		return is_adult() or setting('agelessSwords')
	end

	function age_shield_child()
		return is_child() or setting('agelessShields')
	end

	function age_shield_adult()
		return is_adult() or setting('agelessShields')
	end

	function age_tunics()
		return is_adult() or setting('agelessTunics')
	end

	function age_boots()
		return is_adult() or setting('agelessBoots')
	end

	function age_child_trade()
		return glitch_equip_swap() or is_child() or setting('agelessChildTrade')
	end

	function starts_with_master_sword()
		return setting('startingAge', 'adult') and (not setting('swordlessAdult'))
	end

	function has_sword_child(n)
		return setting('extraChildSwordsOot') and cond(setting('sharedSwords'), has('SHARED_SWORD', n), has('SWORD', n))
	end

	function has_sword_kokiri()
		return cond(setting('progressiveSwordsOot', 'progressive'), has('SWORD'), cond(setting('extraChildSwordsOot'), has_sword_child(1), has('SWORD_KOKIRI')))
	end

	function has_sword_razor()
		return has_sword_child(2)
	end

	function has_sword_gilded()
		return has_sword_child(3)
	end

	function has_sword_master()
		return starts_with_master_sword() or cond(setting('progressiveSwordsOot', 'progressive'), has('SWORD', 2), has('SWORD_MASTER'))
	end

	function has_sword_goron()
		return cond(setting('progressiveSwordsOot', 'progressive'), cond(starts_with_master_sword(), has('SWORD', 2), has('SWORD', 3)), cond(setting('progressiveSwordsOot', 'goron'), has('SWORD_GORON'), has('SWORD_KNIFE') or has('SWORD_BIGGORON')))
	end

	function has_weapon()
		return can_use_sword()
	end

	function can_use_sword_kokiri()
		return age_sword_child() and has_sword_kokiri()
	end

	function can_use_sword_razor()
		return age_sword_child() and has_sword_razor()
	end

	function can_use_sword_gilded()
		return age_sword_child() and has_sword_gilded()
	end

	function can_use_sword_master()
		return age_sword_adult() and has_sword_master()
	end

	function can_use_sword_goron()
		return age_sword_adult() and has_sword_goron()
	end

	function can_use_sword()
		return can_use_sword_kokiri() or can_use_sword_master() or can_use_sword_goron()
	end

	function has_shield_hylian()
		return cond(setting('sharedShields'), renewable(SHARED_SHIELD_HYLIAN), renewable(SHIELD_HYLIAN))
	end

	function has_shield()
		return has_shield_hylian() or has_mirror_shield() or (age_shield_child() and renewable(SHIELD_DEKU))
	end

	function has_shield_for_scrubs()
		return is_adult() and has_shield_hylian() or (age_shield_child() and renewable(SHIELD_DEKU))
	end

	function has_mirror_shield_raw_nonshared()
		return cond(setting('progressiveShieldsOot', 'progressive'), has('SHIELD', 3), has('SHIELD_MIRROR'))
	end

	function has_mirror_shield_raw_shared()
		return cond(setting('progressiveShieldsOot', 'progressive'), has('SHARED_SHIELD', 3), has('SHARED_SHIELD_MIRROR'))
	end

	function has_mirror_shield()
		return age_shield_adult() and cond(setting('sharedShields'), has_mirror_shield_raw_shared(), has_mirror_shield_raw_nonshared())
	end

	function has_one_hand_shield()
		return has_shield_for_scrubs() or has_mirror_shield()
	end

	function can_reflect_light()
		return has_sunlight_arrows() or has_mirror_shield()
	end

	function has_rupees()
		return event('RUPEES') or (setting('sharedWallets') and event('MM_RUPEES'))
	end

	function stone_of_agony()
		return has('STONE_OF_AGONY') or trick('OOT_HIDDEN_GROTTOS')
	end

	function has_tunic_goron_strict()
		return age_tunics() and has_tunic_goron_raw()
	end

	function has_tunic_zora_strict()
		return age_tunics() and has_tunic_zora_raw()
	end

	function has_tunic_goron()
		return has_tunic_goron_strict() or trick('OOT_TUNICS')
	end

	function has_tunic_zora()
		return has_tunic_zora_strict() or trick('OOT_TUNICS')
	end

	function has_iron_boots()
		return age_boots() and has_iron_boots_raw()
	end

	function has_hover_boots()
		return age_boots() and has_hover_boots_raw()
	end

	function has_goron_bracelet()
		return has_strength_raw(1)
	end

	function can_lift_silver()
		return (is_adult() or setting('agelessStrength')) and has_strength_raw(2)
	end

	function can_lift_gold()
		return (is_adult() or setting('agelessStrength')) and has_strength_raw(3)
	end

	function has_green_potion()
		return has_bottle() and (renewable(POTION_GREEN) or renewable(BOTTLE_POTION_GREEN))
	end

	function has_blue_potion()
		return has_bottle() and (renewable(POTION_BLUE) or renewable(BOTTLE_POTION_BLUE))
	end

	function has_magic()
		return (has('MAGIC_UPGRADE') or has('SHARED_MAGIC_UPGRADE')) and (event('MAGIC') or has_magic_jar() or (setting('sharedMagic') and event('MM_MAGIC')) or has_green_potion() or has_blue_potion())
	end

	function has_light_arrow()
		return cond(setting('sharedMagicArrowLight'), has('SHARED_ARROW_LIGHT'), has('ARROW_LIGHT'))
	end

	function has_ice_arrow()
		return cond(setting('sharedMagicArrowIce'), has('SHARED_ARROW_ICE'), has('ARROW_ICE'))
	end

	function can_use_light_arrows()
		return has_light_arrow() and has_magic() and can_use_bow()
	end

	function has_blue_fire_arrows()
		return setting('blueFireArrows') and has_ice_arrow() and has_magic() and can_use_bow()
	end

	function has_blue_fire_arrows_mudwall()
		return trick('OOT_BFA_MUDWALLS') and has_blue_fire_arrows()
	end

	function has_sunlight_arrows()
		return setting('sunlightArrows') and can_use_light_arrows()
	end

	function has_fire_arrows()
		return can_use_bow() and (has('ARROW_FIRE') or has('SHARED_ARROW_FIRE')) and has_magic()
	end

	function has_lens_strict()
		return has_magic() and (has('LENS') or has('SHARED_LENS'))
	end

	function has_explosives()
		return has_bombs() or has_bombchu()
	end

	function has_bombflowers()
		return has_explosives() or has_strength_raw(1)
	end

	function has_explosives_or_hammer()
		return has_explosives() or can_hammer() or can_use_mask_blast()
	end

	function can_hit_triggers_distance()
		return can_use_slingshot() or can_use_bow()
	end

	function has_ranged_weapon_child()
		return can_use_slingshot() or can_boomerang()
	end

	function has_ranged_weapon_adult()
		return can_use_bow() or can_hookshot()
	end

	function has_ranged_weapon()
		return has_ranged_weapon_child() or has_ranged_weapon_adult()
	end

	function can_collect_distance()
		return can_hookshot() or can_boomerang()
	end

	function scarecrow_hookshot()
		return has_ocarina() and can_hookshot() and (event('SCARECROW') or setting('freeScarecrowOot'))
	end

	function scarecrow_longshot()
		return has_ocarina() and can_longshot() and (event('SCARECROW') or setting('freeScarecrowOot'))
	end

	function has_fire()
		return has_fire_arrows() or can_use_din()
	end

	function has_fire_or_sticks()
		return can_use_sticks() or has_fire()
	end

	function can_dive_small()
		return has_scale_raw(1) or has_iron_boots()
	end

	function can_dive_big()
		return has_scale_raw(2) or has_iron_boots()
	end

	function hidden_grotto_bomb()
		return stone_of_agony() and has_explosives_or_hammer()
	end

	function hidden_grotto_storms()
		return stone_of_agony() and can_play_storms()
	end

	function has_spiritual_stones()
		return has('STONE_EMERALD') and has('STONE_RUBY') and has('STONE_SAPPHIRE')
	end

	function can_jump_slash()
		return has_weapon() or can_use_sticks() or can_hammer()
	end

	function has_bugs()
		return has_bottle() and (renewable(BUG) or event('BUGS'))
	end

	function has_fish()
		return has_bottle() and (renewable(FISH) or event('FISH'))
	end

	function gs()
		return soul_gs()
	end

	function gs_soil()
		return gs() and is_child() and has_bugs()
	end

	function gs_night()
		return gs() and is_night() and (trick('OOT_NIGHT_GS') or can_play_sun())
	end

	function can_ride_epona()
		return is_adult() and can_play_epona()
	end

	function adult_trade(x)
		return is_adult() and has(x)
	end

	function has_blue_fire()
		return has_blue_fire_arrows() or (has_bottle() and (event('BLUE_FIRE') or renewable(BLUE_FIRE) or renewable(BOTTLE_BLUE_FIRE)))
	end

	function can_ride_bean(x)
		return is_adult() and event(x)
	end

	function can_damage()
		return has_weapon() or can_use_sticks() or has_explosives() or can_use_slingshot() or can_use_din()
	end

	function can_damage_skull()
		return can_damage() or can_collect_distance()
	end

	function can_cut_grass_no_c_button()
		return has_weapon() or has_strength_raw(1) or can_use_mask_blast()
	end

	function can_cut_grass()
		return can_cut_grass_no_c_button() or can_boomerang() or has_explosives() or can_hammer()
	end

	function can_kill_baba_sticks()
		return soul_deku_baba() and (can_boomerang() or (has_weapon() and (is_child() or has_nuts() or can_hookshot() or can_hammer())))
	end

	function can_kill_baba_nuts()
		return soul_deku_baba() and (has_weapon() or has_explosives() or can_use_slingshot())
	end

	function can_hit_scrub()
		return has_nuts() or can_hit_triggers_distance() or has_shield_for_scrubs() or can_collect_distance() or can_hammer() or has_explosives()
	end

	function can_rescue_carpenter()
		return small_keys_hideout_all() and (has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks())) and soul_carpenters()
	end

	function carpenters_rescued()
		return setting('gerudoFortress', 'open') or (event('CARPENTER_1') and (setting('gerudoFortress', 'single') or (event('CARPENTER_2') and event('CARPENTER_3') and event('CARPENTER_4'))))
	end

	function has_lens()
		return has_lens_strict() or trick('OOT_LENS')
	end

	function trick_mido()
		return trick('OOT_MIDO_SKIP') and (has_bow() or has_hookshot(1) or has('SHARED_ARROW_FIRE') or has('ARROW_FIRE') or has('SHARED_ARROW_LIGHT') or has('ARROW_LIGHT'))
	end

	function can_move_mido_reqs()
		return is_child() and has_sword_kokiri() and renewable(SHIELD_DEKU)
	end

	function can_move_mido()
		return can_move_mido_reqs() and soul_npc(SOUL_NPC_MIDO)
	end

	function can_bypass_mido()
		return setting('dekuTree', 'open') or is_adult() or climb_anywhere() or hookshot_anywhere() or can_move_mido_reqs()
	end

	function met_zelda()
		return event('MEET_ZELDA') or setting('skipZelda')
	end

	function woke_talon_child()
		return event('TALON_CHILD') or setting('skipZelda')
	end

	function has_fire_spirit_ageless()
		return has_magic() and (has_arrows() and (has('ARROW_FIRE') or has('SHARED_ARROW_FIRE')) and has_sticks() or can_use_din()) and cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and can_reflect_light() or small_keys_spirit(3), has_explosives() or small_keys_spirit(2))
	end

	function has_fire_spirit()
		return time_travel_at_will() and has_fire_or_sticks() or has_fire_spirit_ageless()
	end

	function has_ranged_weapon_both_ageless()
		return has_explosives() or ((has('SLINGSHOT') and (event('SEEDS') or renewable(DEKU_SEEDS_30)) or has('BOOMERANG')) and (has_hookshot(1) or has_arrows()))
	end

	function has_ranged_weapon_both()
		return time_travel_at_will() and has_ranged_weapon() or has_ranged_weapon_both_ageless()
	end

	function can_collect_ageless_raw()
		return has_hookshot(1) and has('BOOMERANG') or (age_boomerang_anyage() and has('BOOMERANG')) or (age_hookshot_anyage() and has_hookshot(1))
	end

	function can_collect_ageless()
		return time_travel_at_will() and can_collect_distance() or can_collect_ageless_raw()
	end

	function king_zora_moved()
		return event('KING_ZORA_LETTER') or setting('zoraKing', 'open') or (setting('zoraKing', 'adult') and is_adult())
	end

	function business_scrub(id)
		return soul_business_scrub() and can_hit_scrub() and scrub_price(id)
	end

	function has_wallet(n)
		return cond(setting('childWallets'), has('WALLET', n) or has('SHARED_WALLET', n), has('WALLET', n - 1) or has('SHARED_WALLET', n - 1))
	end

	function can_use_wallet(n)
		return has_rupees() and has_wallet(n)
	end

	function wallet_price(range, id)
		return price(range, id, 0) or (has_rupees() and (price(range, id, 99) and has_wallet(1) or (price(range, id, 200) and has_wallet(2)) or (price(range, id, 500) and has_wallet(3)) or (setting('colossalWallets') and price(range, id, 999) and has_wallet(4)) or (setting('bottomlessWallets') and price(range, id, 9999) and has_wallet(5))))
	end

	function shop_price(id)
		return wallet_price(OOT_SHOPS, id)
	end

	function scrub_price(id)
		return wallet_price(OOT_SCRUBS, id)
	end

	function has_skeleton_key()
		return setting('skeletonKeyOot') and cond(setting('sharedSkeletonKey'), has('SHARED_SKELETON_KEY'), has('SKELETON_KEY'))
	end

	function boss_key(x)
		return setting('bossKeyShuffleOot', 'removed') or has(x)
	end

	function small_keys(type, x, y, count)
		return has_skeleton_key() or (setting('smallKeyShuffleOot', 'removed') or cond(setting('smallKeyRingOot', type), has(y), has(x, count)))
	end

	function small_keys_extra(type, x, y, count)
		return has_skeleton_key() or (setting('smallKeyShuffleOot', 'removed') or cond(setting('smallKeyRingOot', type), has(y), has(x, count + 1)))
	end

	function small_keys_forest(n)
		return small_keys('Forest', 'SMALL_KEY_FOREST', 'KEY_RING_FOREST', n)
	end

	function small_keys_fire(n)
		return cond(setting('smallKeyShuffleOot', 'anywhere'), small_keys_extra('Fire', 'SMALL_KEY_FIRE', 'KEY_RING_FIRE', n), small_keys('Fire', 'SMALL_KEY_FIRE', 'KEY_RING_FIRE', n))
	end

	function small_keys_fire_mq(n)
		return small_keys('Fire', 'SMALL_KEY_FIRE', 'KEY_RING_FIRE', n)
	end

	function small_keys_water(n)
		return small_keys('Water', 'SMALL_KEY_WATER', 'KEY_RING_WATER', n)
	end

	function small_keys_shadow(n)
		return small_keys('Shadow', 'SMALL_KEY_SHADOW', 'KEY_RING_SHADOW', n)
	end

	function small_keys_spirit(n)
		return small_keys('Spirit', 'SMALL_KEY_SPIRIT', 'KEY_RING_SPIRIT', n)
	end

	function small_keys_hideout(n)
		return has_skeleton_key() or has('KEY_RING_GF') or has('SMALL_KEY_GF', n)
	end

	function small_keys_tcg(n)
		return cond(setting('smallKeyShuffleChestGame', 'vanilla'), has_lens_strict() and can_use_wallet(1) and soul_chest_game_owner(), has_skeleton_key() or has('KEY_RING_TCG') or has('SMALL_KEY_TCG', n))
	end

	function small_keys_hideout_all()
		return setting('gerudoFortress', 'open') or cond(setting('gerudoFortress', 'single'), small_keys_hideout(1), small_keys_hideout(4))
	end

	function small_keys_botw(n)
		return small_keys('BotW', 'SMALL_KEY_BOTW', 'KEY_RING_BOTW', n)
	end

	function small_keys_gtg(n)
		return small_keys('GTG', 'SMALL_KEY_GTG', 'KEY_RING_GTG', n)
	end

	function small_keys_ganon(n)
		return small_keys('Ganon', 'SMALL_KEY_GANON', 'KEY_RING_GANON', n)
	end

	function silver_rupees(type, rupee, pouch, count)
		return setting('magicalRupee') and has('RUPEE_MAGICAL') or cond(setting('silverRupeePouches', type), has(pouch), has(rupee, count))
	end

	function silver_rupees_ganon_light()
		return silver_rupees('Ganon_Light', 'RUPEE_SILVER_GANON_LIGHT', 'POUCH_SILVER_GANON_LIGHT', 5)
	end

	function silver_rupees_ganon_forest()
		return silver_rupees('Ganon_Forest', 'RUPEE_SILVER_GANON_FOREST', 'POUCH_SILVER_GANON_FOREST', 5)
	end

	function silver_rupees_ganon_fire()
		return silver_rupees('Ganon_Fire', 'RUPEE_SILVER_GANON_FIRE', 'POUCH_SILVER_GANON_FIRE', 5)
	end

	function silver_rupees_ganon_spirit()
		return silver_rupees('Ganon_Spirit', 'RUPEE_SILVER_GANON_SPIRIT', 'POUCH_SILVER_GANON_SPIRIT', 5)
	end

	function silver_rupees_ganon_water()
		return silver_rupees('Ganon_Water', 'RUPEE_SILVER_GANON_WATER', 'POUCH_SILVER_GANON_WATER', 5)
	end

	function silver_rupees_ganon_shadow()
		return silver_rupees('Ganon_Shadow', 'RUPEE_SILVER_GANON_SHADOW', 'POUCH_SILVER_GANON_SHADOW', 5)
	end

	function silver_rupees_gtg_slopes()
		return silver_rupees('GTG_Slopes', 'RUPEE_SILVER_GTG_SLOPES', 'POUCH_SILVER_GTG_SLOPES', 5)
	end

	function silver_rupees_gtg_lava()
		return silver_rupees('GTG_Lava', 'RUPEE_SILVER_GTG_LAVA', 'POUCH_SILVER_GTG_LAVA', 5)
	end

	function silver_rupees_gtg_water()
		return silver_rupees('GTG_Water', 'RUPEE_SILVER_GTG_WATER', 'POUCH_SILVER_GTG_WATER', 5)
	end

	function silver_rupees_gtg_lava_mq()
		return silver_rupees('GTG_Lava', 'RUPEE_SILVER_GTG_LAVA', 'POUCH_SILVER_GTG_LAVA', 6)
	end

	function silver_rupees_gtg_water_mq()
		return silver_rupees('GTG_Water', 'RUPEE_SILVER_GTG_WATER', 'POUCH_SILVER_GTG_WATER', 3)
	end

	function silver_rupees_ic_scythe()
		return silver_rupees('IC_Scythe', 'RUPEE_SILVER_IC_SCYTHE', 'POUCH_SILVER_IC_SCYTHE', 5)
	end

	function silver_rupees_ic_block()
		return silver_rupees('IC_Block', 'RUPEE_SILVER_IC_BLOCK', 'POUCH_SILVER_IC_BLOCK', 5)
	end

	function silver_rupees_shadow_scythe()
		return silver_rupees('Shadow_Scythe', 'RUPEE_SILVER_SHADOW_SCYTHE', 'POUCH_SILVER_SHADOW_SCYTHE', 5)
	end

	function silver_rupees_shadow_pit()
		return silver_rupees('Shadow_Pit', 'RUPEE_SILVER_SHADOW_PIT', 'POUCH_SILVER_SHADOW_PIT', 5)
	end

	function silver_rupees_shadow_spikes()
		return silver_rupees('Shadow_Spikes', 'RUPEE_SILVER_SHADOW_SPIKES', 'POUCH_SILVER_SHADOW_SPIKES', 5)
	end

	function silver_rupees_shadow_blades()
		return silver_rupees('Shadow_Blades', 'RUPEE_SILVER_SHADOW_BLADES', 'POUCH_SILVER_SHADOW_BLADES', 10)
	end

	function silver_rupees_shadow_spikes_mq()
		return silver_rupees('Shadow_Spikes', 'RUPEE_SILVER_SHADOW_SPIKES', 'POUCH_SILVER_SHADOW_SPIKES', 10)
	end

	function silver_rupees_dc()
		return silver_rupees('DC', 'RUPEE_SILVER_DC', 'POUCH_SILVER_DC', 5)
	end

	function silver_rupees_spirit_child()
		return silver_rupees('Spirit_Child', 'RUPEE_SILVER_SPIRIT_CHILD', 'POUCH_SILVER_SPIRIT_CHILD', 5)
	end

	function silver_rupees_spirit_sun()
		return silver_rupees('Spirit_Sun', 'RUPEE_SILVER_SPIRIT_SUN', 'POUCH_SILVER_SPIRIT_SUN', 5)
	end

	function silver_rupees_spirit_boulders()
		return silver_rupees('Spirit_Boulders', 'RUPEE_SILVER_SPIRIT_BOULDERS', 'POUCH_SILVER_SPIRIT_BOULDERS', 5)
	end

	function silver_rupees_spirit_lobby()
		return silver_rupees('Spirit_Lobby', 'RUPEE_SILVER_SPIRIT_LOBBY', 'POUCH_SILVER_SPIRIT_LOBBY', 5)
	end

	function silver_rupees_spirit_adult()
		return silver_rupees('Spirit_Adult', 'RUPEE_SILVER_SPIRIT_ADULT', 'POUCH_SILVER_SPIRIT_ADULT', 5)
	end

	function has_mask_truth()
		return has('MASK_TRUTH') or has('SHARED_MASK_TRUTH')
	end

	function has_mask_stone()
		return setting('stoneMaskOot') and cond(setting('sharedMaskStone'), has('SHARED_MASK_STONE'), has('MASK_STONE'))
	end

	function can_use_mask_stone()
		return age_child_trade() and has_mask_stone()
	end

	function has_mask_blast()
		return setting('blastMaskOot') and cond(setting('sharedMaskBlast'), has('SHARED_MASK_BLAST'), has('MASK_BLAST'))
	end

	function can_use_mask_blast()
		return age_child_trade() and has_mask_blast()
	end

	function glitch_equip_swap()
		return trick('GLITCH_OOT_EQUIP_SWAP') and ((has('SPELL_FIRE') or has('SHARED_SPELL_FIRE')) or (has_sticks() and (is_child() or setting('agelessSticks'))))
	end

	function glitch_equip_swap_anyage()
		return trick('GLITCH_OOT_EQUIP_SWAP') and ((has('SPELL_FIRE') or has('SHARED_SPELL_FIRE')) or (has_sticks() and setting('agelessSticks')))
	end

	function glitch_ocarina_items()
		return trick('GLITCH_OOT_OCARINA_ITEMS') and (has_bugs() or has_fish())
	end

	function glitch_megaflip()
		return trick('GLITCH_OOT_MEGAFLIP') and has_explosives() and has_one_hand_shield()
	end

	function soul_enemy(x)
		return not setting('soulsEnemyOot') or has(x)
	end

	function soul_boss(x)
		return not setting('soulsBossOot') or has(x)
	end

	function soul_npc(x)
		return not setting('soulsNpcOot') or has(x)
	end

	function soul_misc(x)
		return not setting('soulsMiscOot') or has(x)
	end

	function climb_anywhere()
		return setting('climbMostSurfacesOot', 'logical')
	end

	function hookshot_anywhere()
		return can_hookshot() and setting('hookshotAnywhereOot', 'logical')
	end

	function longshot_anywhere()
		return can_longshot() and setting('hookshotAnywhereOot', 'logical')
	end

	function evade_gerudo()
		return can_use_bow() or can_hookshot() or has('GERUDO_CARD') or can_use_mask_stone()
	end

	function ganon_trial_light()
		return not setting('ganonTrials', 'Light') or event('GANON_TRIAL_LIGHT')
	end

	function ganon_trial_forest()
		return not setting('ganonTrials', 'Forest') or event('GANON_TRIAL_FOREST')
	end

	function ganon_trial_fire()
		return not setting('ganonTrials', 'Fire') or event('GANON_TRIAL_FIRE')
	end

	function ganon_trial_water()
		return not setting('ganonTrials', 'Water') or event('GANON_TRIAL_WATER')
	end

	function ganon_trial_shadow()
		return not setting('ganonTrials', 'Shadow') or event('GANON_TRIAL_SHADOW')
	end

	function ganon_trial_spirit()
		return not setting('ganonTrials', 'Spirit') or event('GANON_TRIAL_SPIRIT')
	end

	function ganon_barrier()
		return ganon_trial_light() and ganon_trial_forest() and ganon_trial_fire() and ganon_trial_water() and ganon_trial_shadow() and ganon_trial_spirit()
	end

	function rainbow_bridge_vanilla()
		return has('MEDALLION_SPIRIT') and has('MEDALLION_SHADOW') and (has('ARROW_LIGHT') or has('SHARED_ARROW_LIGHT'))
	end

	function rainbow_bridge_medallions()
		return has('MEDALLION_LIGHT') and has('MEDALLION_FOREST') and has('MEDALLION_FIRE') and has('MEDALLION_WATER') and has('MEDALLION_SHADOW') and has('MEDALLION_SPIRIT')
	end

	function rainbow_bridge()
		return setting('rainbowBridge', 'open') or (setting('rainbowBridge', 'vanilla') and rainbow_bridge_vanilla()) or (setting('rainbowBridge', 'medallions') and rainbow_bridge_medallions()) or (setting('rainbowBridge', 'custom') and special(BRIDGE))
	end


    logic = {
    ["Deku Tree Boss"] = {
        ["exits"] = {
            ["Deku Tree After Boss"] = function () return soul_boss(SOUL_BOSS_QUEEN_GOHMA) and (has_nuts() or can_use_slingshot()) and (can_use_sticks() or has_weapon()) end,
        },
        ["locations"] = {
            ["Deku Tree Boss Grass 1"] = function () return can_cut_grass() end,
            ["Deku Tree Boss Grass 2"] = function () return can_cut_grass() end,
            ["Deku Tree Boss Grass 3"] = function () return can_cut_grass() end,
            ["Deku Tree Boss Grass 4"] = function () return can_cut_grass() end,
            ["Deku Tree Boss Grass 5"] = function () return can_cut_grass() end,
            ["Deku Tree Boss Grass 6"] = function () return can_cut_grass() end,
            ["Deku Tree Boss Grass 7"] = function () return can_cut_grass() end,
            ["Deku Tree Boss Grass 8"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree After Boss"] = {
        ["locations"] = {
            ["Deku Tree Boss Container"] = function () return true end,
            ["Deku Tree Boss"] = function () return true end,
        },
    },
    ["Dodongo Cavern Boss"] = {
        ["exits"] = {
            ["Dodongo Cavern After Boss"] = function () return (has_bombs() or (has_explosives() and has_strength_raw(1))) and soul_boss(SOUL_BOSS_KING_DODONGO) and (can_use_sticks() or has_weapon()) end,
        },
        ["locations"] = {
            ["Dodongo Cavern Boss Chest"] = function () return true end,
        },
    },
    ["Dodongo Cavern After Boss"] = {
        ["locations"] = {
            ["Dodongo Cavern Boss Container"] = function () return true end,
            ["Dodongo Cavern Boss"] = function () return true end,
        },
    },
    ["Jabu-Jabu Boss"] = {
        ["exits"] = {
            ["Jabu-Jabu After Boss"] = function () return soul_boss(SOUL_BOSS_BARINADE) and can_boomerang() and (can_use_sticks() or has_weapon()) end,
        },
        ["locations"] = {
            ["Jabu-Jabu Boss Pot 1"] = function () return true end,
            ["Jabu-Jabu Boss Pot 2"] = function () return true end,
            ["Jabu-Jabu Boss Pot 3"] = function () return true end,
            ["Jabu-Jabu Boss Pot 4"] = function () return true end,
            ["Jabu-Jabu Boss Pot 5"] = function () return true end,
            ["Jabu-Jabu Boss Pot 6"] = function () return true end,
        },
    },
    ["Jabu-Jabu After Boss"] = {
        ["locations"] = {
            ["Jabu-Jabu Boss Container"] = function () return true end,
            ["Jabu-Jabu Boss"] = function () return true end,
        },
    },
    ["Forest Temple Boss"] = {
        ["exits"] = {
            ["Forest Temple After Boss"] = function () return soul_boss(SOUL_BOSS_PHANTOM_GANON) and (has_ranged_weapon_adult() or can_use_slingshot()) and has_weapon() end,
        },
    },
    ["Forest Temple After Boss"] = {
        ["locations"] = {
            ["Forest Temple Boss"] = function () return true end,
            ["Forest Temple Boss Container"] = function () return true end,
        },
    },
    ["Fire Temple Boss"] = {
        ["exits"] = {
            ["Fire Temple After Boss"] = function () return soul_boss(SOUL_BOSS_VOLVAGIA) and can_hammer() and has_tunic_goron_strict() end,
        },
    },
    ["Fire Temple After Boss"] = {
        ["locations"] = {
            ["Fire Temple Boss Container"] = function () return true end,
            ["Fire Temple Boss"] = function () return true end,
        },
    },
    ["Water Temple Boss"] = {
        ["exits"] = {
            ["Water Temple After Boss"] = function () return soul_boss(SOUL_BOSS_MORPHA) and can_hookshot() and has_weapon() end,
        },
    },
    ["Water Temple After Boss"] = {
        ["events"] = {
            ["WATER_TEMPLE_CLEARED"] = function () return true end,
        },
        ["locations"] = {
            ["Water Temple Boss HC"] = function () return true end,
            ["Water Temple Boss"] = function () return true end,
        },
    },
    ["Spirit Temple Boss"] = {
        ["exits"] = {
            ["Spirit Temple After Boss"] = function () return soul_boss(SOUL_BOSS_TWINROVA) and soul_iron_knuckle() and has_mirror_shield() and has_weapon() end,
        },
    },
    ["Spirit Temple After Boss"] = {
        ["locations"] = {
            ["Spirit Temple Boss HC"] = function () return true end,
            ["Spirit Temple Boss"] = function () return true end,
        },
    },
    ["Shadow Temple Boss"] = {
        ["exits"] = {
            ["Shadow Temple After Boss"] = function () return soul_boss(SOUL_BOSS_BONGO_BONGO) and has_weapon() and has_lens() and (can_use_bow() or can_use_slingshot()) end,
        },
    },
    ["Shadow Temple After Boss"] = {
        ["locations"] = {
            ["Shadow Temple Boss HC"] = function () return true end,
            ["Shadow Temple Boss"] = function () return true end,
        },
    },
    ["Bottom of the Well"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Bottom of the Well Main"] = function () return is_child() and (has_nuts() or has_weapon() or has_explosives_or_hammer() or has_ranged_weapon() or can_use_din()) or time_travel_at_will() end,
        },
    },
    ["Bottom of the Well Wallmaster Main"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Bottom of the Well Main"] = {
        ["events"] = {
            ["STICKS"] = function () return true end,
        },
        ["exits"] = {
            ["Bottom of the Well"] = function () return true end,
            ["Bottom of the Well Wallmaster Main"] = function () return soul_wallmaster() and has_lens() end,
            ["Bottom of the Well Basement Platform"] = function () return has_lens() or climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Bottom of the Well Coffin"] = function () return true end,
            ["Bottom of the Well Compass"] = function () return has_lens() end,
            ["Bottom of the Well Under Debris"] = function () return has_explosives() end,
            ["Bottom of the Well Back West"] = function () return has_explosives() and has_lens() end,
            ["Bottom of the Well East"] = function () return has_lens() end,
            ["Bottom of the Well Front West"] = function () return has_lens() end,
            ["Bottom of the Well Underwater"] = function () return can_play_zelda() end,
            ["Bottom of the Well East Cage"] = function () return (small_keys_botw(3) or climb_anywhere()) and has_lens() end,
            ["Bottom of the Well Blood Chest"] = function () return has_lens() end,
            ["Bottom of the Well Underwater 2"] = function () return can_play_zelda() end,
            ["Bottom of the Well Map"] = function () return has_explosives_or_hammer() or (has_bombflowers() and (small_keys_botw(3) or can_use_din())) or climb_anywhere() or hookshot_anywhere() end,
            ["Bottom of the Well Pits"] = function () return (small_keys_botw(3) or climb_anywhere()) and has_lens() end,
            ["Bottom of the Well Lens"] = function () return soul_enemy(SOUL_ENEMY_DEAD_HAND) and can_play_zelda() and (has_weapon() or (can_use_sticks() and trick('OOT_DEAD_HAND_STICKS'))) end,
            ["Bottom of the Well Lens Side Chest"] = function () return can_play_zelda() and has_lens() end,
            ["Bottom of the Well GS East Cage"] = function () return gs() and (small_keys_botw(3) or climb_anywhere()) and has_lens() and (can_collect_distance() or (climb_anywhere() and (can_use_sword_master() or has_ranged_weapon() or has_explosives() or can_use_sticks() or can_use_din() or (age_sword_adult() and has('SWORD_BIGGORON'))))) end,
            ["Bottom of the Well GS Inner West"] = function () return gs() and small_keys_botw(3) and has_lens() and (can_collect_distance() or (climb_anywhere() and (can_use_sword_master() or has_ranged_weapon() or has_explosives() or can_use_sticks() or can_use_din() or (age_sword_adult() and has('SWORD_BIGGORON'))))) end,
            ["Bottom of the Well GS Inner East"] = function () return gs() and (small_keys_botw(3) or climb_anywhere()) and has_lens() and (can_collect_distance() or (climb_anywhere() and (can_use_sword_master() or has_ranged_weapon() or has_explosives() or can_use_sticks() or can_use_din() or (age_sword_adult() and has('SWORD_BIGGORON'))))) end,
            ["Bottom of the Well SR 1"] = function () return true end,
            ["Bottom of the Well SR 2"] = function () return true end,
            ["Bottom of the Well SR 3"] = function () return true end,
            ["Bottom of the Well SR 4"] = function () return true end,
            ["Bottom of the Well SR 5"] = function () return true end,
            ["Bottom of the Well Pot Main Roon 1"] = function () return true end,
            ["Bottom of the Well Pot Main Roon 2"] = function () return true end,
            ["Bottom of the Well Pot Main Roon 3"] = function () return true end,
            ["Bottom of the Well Pot Main Roon 4"] = function () return true end,
            ["Bottom of the Well Pot Main Roon 5"] = function () return true end,
            ["Bottom of the Well Pot Main Roon Underwater"] = function () return can_play_zelda() or has_ranged_weapon() or has_bombchu() end,
            ["Bottom of the Well Pot Basement 01"] = function () return true end,
            ["Bottom of the Well Pot Basement 02"] = function () return true end,
            ["Bottom of the Well Pot Basement 03"] = function () return true end,
            ["Bottom of the Well Pot Basement 04"] = function () return true end,
            ["Bottom of the Well Pot Basement 05"] = function () return true end,
            ["Bottom of the Well Pot Basement 06"] = function () return true end,
            ["Bottom of the Well Pot Basement 07"] = function () return true end,
            ["Bottom of the Well Pot Basement 08"] = function () return true end,
            ["Bottom of the Well Pot Basement 09"] = function () return true end,
            ["Bottom of the Well Pot Basement 10"] = function () return true end,
            ["Bottom of the Well Pot Basement 11"] = function () return true end,
            ["Bottom of the Well Pot Basement 12"] = function () return true end,
            ["Bottom of the Well Pot Side Room"] = function () return has_lens() and (small_keys_botw(3) or climb_anywhere()) end,
            ["Bottom of the Well Flying Pot 1"] = function () return has_lens() and small_keys_botw(3) and soul_flying_pot() end,
            ["Bottom of the Well Flying Pot 2"] = function () return has_lens() and small_keys_botw(3) and soul_flying_pot() end,
            ["Bottom of the Well Flying Pot 3"] = function () return has_lens() and small_keys_botw(3) and soul_flying_pot() end,
            ["Bottom of the Well Grass 01"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 02"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 03"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 04"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 05"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 06"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 07"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 08"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 09"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 10"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 11"] = function () return can_cut_grass() end,
            ["Bottom of the Well Grass 12"] = function () return can_cut_grass() end,
            ["Bottom of the Well Heart 1"] = function () return true end,
            ["Bottom of the Well Heart 2"] = function () return true end,
            ["Bottom of the Well Basement Big Fairy"] = function () return can_play_sun() end,
        },
    },
    ["Bottom of the Well Basement Platform"] = {
        ["locations"] = {
            ["Bottom of the Well Rupee 1"] = function () return true end,
            ["Bottom of the Well Rupee 2"] = function () return true end,
            ["Bottom of the Well Rupee 3"] = function () return true end,
            ["Bottom of the Well Rupee 4"] = function () return true end,
            ["Bottom of the Well Rupee 5"] = function () return true end,
        },
    },
    ["Deku Tree"] = {
        ["exits"] = {
            ["Kokiri Forest Near Deku Tree"] = function () return true end,
            ["Deku Tree Lobby"] = function () return true end,
        },
    },
    ["Deku Tree Lobby"] = {
        ["events"] = {
            ["STICKS"] = function () return can_kill_baba_sticks() end,
            ["NUTS"] = function () return can_kill_baba_nuts() end,
        },
        ["exits"] = {
            ["Deku Tree Slingshot Room"] = function () return soul_deku_scrub() and (has_shield_for_scrubs() or can_hammer()) end,
            ["Deku Tree Basement"] = function () return has_fire() or has_nuts() or has_weapon() or has_explosives_or_hammer() or has_ranged_weapon() or can_use_sticks() end,
        },
        ["locations"] = {
            ["Deku Tree Map Chest"] = function () return true end,
            ["Deku Tree Compass Chest"] = function () return true end,
            ["Deku Tree Compass Room Side Chest"] = function () return true end,
            ["Deku Tree GS Compass"] = function () return gs() and can_damage_skull() end,
            ["Deku Tree Grass Lobby 1"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Lobby 2"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Lobby 3"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Lobby 4"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Lobby 5"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Compass Room 1"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Compass Room 2"] = function () return can_cut_grass() end,
            ["Deku Tree Heart Main Room Lower"] = function () return true end,
            ["Deku Tree Heart Main Room Upper"] = function () return has_fire() or has_nuts() or has_weapon() or has_explosives_or_hammer() or has_ranged_weapon() or can_use_sticks() end,
        },
    },
    ["Deku Tree Slingshot Room"] = {
        ["exits"] = {
            ["Deku Tree Lobby"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Tree Slingshot Chest"] = function () return true end,
            ["Deku Tree Slingshot Side Chest"] = function () return true end,
            ["Deku Tree Grass Slingshot Room 1"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Slingshot Room 2"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Slingshot Room 3"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Slingshot Room 4"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree Basement"] = {
        ["events"] = {
            ["DEKU_BURN_WEB"] = function () return has_fire_or_sticks() end,
        },
        ["exits"] = {
            ["Deku Tree Lobby"] = function () return true end,
            ["Deku Tree Basement Back Room"] = function () return can_hit_triggers_distance() and event('DEKU_BURN_WEB') end,
            ["Deku Tree Basement Ledge"] = function () return trick('OOT_DEKU_SKIP') or is_adult() or has_hover_boots() or climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Deku Tree Basement Chest"] = function () return true end,
            ["Deku Tree GS Basement Gate"] = function () return gs() and can_damage_skull() end,
            ["Deku Tree GS Basement Vines"] = function () return gs() and (has_ranged_weapon() or can_use_din() or has_explosives()) end,
            ["Deku Tree Grass Basement Main 1"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Basement Main 2"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Eye Switch Room 1"] = function () return can_cut_grass() and event('DEKU_BURN_WEB') end,
            ["Deku Tree Grass Eye Switch Room 2"] = function () return can_cut_grass() and event('DEKU_BURN_WEB') end,
            ["Deku Tree Grass Eye Switch Room 3"] = function () return can_cut_grass() and event('DEKU_BURN_WEB') end,
            ["Deku Tree Grass Eye Switch Room 4"] = function () return can_cut_grass() and event('DEKU_BURN_WEB') end,
        },
    },
    ["Deku Tree Basement Back Room"] = {
        ["events"] = {
            ["DEKU_MUD_WALL"] = function () return has_explosives_or_hammer() end,
        },
        ["exits"] = {
            ["Deku Tree Basement Ledge"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Deku Tree GS Basement Back Room"] = function () return gs() and event('DEKU_MUD_WALL') and event('DEKU_BURN_WEB') and (can_collect_distance() or (climb_anywhere() and (has_explosives() or has_ranged_weapon() or can_use_din() or (age_sword_adult() and has('SWORD_BIGGORON'))))) end,
            ["Deku Tree Grass Larva Room 1"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Larva Room 2"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Water Room 1"] = function () return can_cut_grass() and event('DEKU_BURN_WEB') end,
            ["Deku Tree Grass Water Room 2"] = function () return can_cut_grass() and event('DEKU_BURN_WEB') end,
            ["Deku Tree Grass Torch Room 1"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Torch Room 2"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree Basement Ledge"] = {
        ["exits"] = {
            ["Deku Tree Basement"] = function () return true end,
            ["Deku Tree Basement Back Room"] = function () return is_child() end,
            ["Deku Tree Before Boss"] = function () return has_fire_or_sticks() end,
        },
    },
    ["Deku Tree Before Boss"] = {
        ["exits"] = {
            ["Deku Tree Basement Ledge"] = function () return true end,
            ["Deku Tree Boss"] = function () return soul_deku_scrub() and has_shield_for_scrubs() end,
        },
        ["locations"] = {
            ["Deku Tree Grass Pre-Boss Room 1"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Pre-Boss Room 2"] = function () return can_cut_grass() end,
            ["Deku Tree Grass Pre-Boss Room 3"] = function () return can_cut_grass() end,
            ["Deku Tree Heart Pre-Boss 1"] = function () return true end,
            ["Deku Tree Heart Pre-Boss 2"] = function () return true end,
            ["Deku Tree Heart Pre-Boss 3"] = function () return true end,
        },
    },
    ["Dodongo Cavern"] = {
        ["exits"] = {
            ["Death Mountain"] = function () return true end,
            ["Dodongo Cavern Main"] = function () return has_bombflowers() or can_hammer() or has_blue_fire_arrows_mudwall() end,
        },
    },
    ["Dodongo Cavern Main"] = {
        ["exits"] = {
            ["Dodongo Cavern"] = function () return true end,
            ["Dodongo Cavern Right Corridor"] = function () return true end,
            ["Dodongo Cavern Main Ledge"] = function () return is_adult() or climb_anywhere() or hookshot_anywhere() end,
            ["Dodongo Cavern Stairs"] = function () return event('DC_MAIN_SWITCH') end,
            ["Dodongo Cavern Skull"] = function () return event('DC_BOMB_EYES') end,
        },
        ["locations"] = {
            ["Dodongo Cavern Map Chest"] = function () return true end,
            ["Dodongo Cavern Lobby Scrub"] = function () return business_scrub(31) end,
        },
    },
    ["Dodongo Cavern Right Corridor"] = {
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Side Room"] = function () return soul_enemy(SOUL_ENEMY_BABY_DODONGO) and (has_weapon() or can_use_sticks()) or has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Dodongo Cavern Miniboss 1"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Scarecrow"] = function () return gs() and (is_adult() and scarecrow_hookshot() or (climb_anywhere() and can_damage_skull()) or hookshot_anywhere()) end,
            ["Dodongo Cavern Pot Right Corridor Pot 1"] = function () return true end,
            ["Dodongo Cavern Pot Right Corridor Pot 2"] = function () return true end,
            ["Dodongo Cavern Pot Right Corridor Pot 3"] = function () return true end,
            ["Dodongo Cavern Pot Right Corridor Pot 4"] = function () return true end,
            ["Dodongo Cavern Pot Right Corridor Pot 5"] = function () return true end,
            ["Dodongo Cavern Pot Right Corridor Pot 6"] = function () return true end,
        },
    },
    ["Dodongo Cavern Side Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Right Corridor"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Side Room"] = function () return gs() and can_damage_skull() end,
            ["Dodongo Cavern Grass East Corridor Side Room"] = function () return can_cut_grass() end,
        },
    },
    ["Dodongo Cavern Miniboss 1"] = {
        ["exits"] = {
            ["Dodongo Cavern Right Corridor"] = function () return soul_lizalfos_dinalfos() and (can_use_sticks() or has_weapon() or can_use_slingshot() or can_hammer()) end,
            ["Dodongo Cavern Green Room"] = function () return soul_lizalfos_dinalfos() and (can_use_sticks() or has_weapon() or can_use_slingshot() or can_hammer()) end,
            ["Dodongo Cavern Miniboss 2"] = function () return time_travel_at_will() and (climb_anywhere() or (is_adult() and hookshot_anywhere()) or longshot_anywhere()) end,
        },
        ["locations"] = {
            ["Dodongo Cavern Pot Miniboss 1"] = function () return true end,
            ["Dodongo Cavern Pot Miniboss 2"] = function () return true end,
            ["Dodongo Cavern Pot Miniboss 3"] = function () return true end,
            ["Dodongo Cavern Pot Miniboss 4"] = function () return true end,
            ["Dodongo Cavern Heart Miniboss Lava"] = function () return true end,
        },
    },
    ["Dodongo Cavern Green Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Miniboss 1"] = function () return true end,
            ["Dodongo Cavern Green Side Room"] = function () return true end,
            ["Dodongo Cavern Main Ledge"] = function () return has_fire_or_sticks() end,
        },
        ["locations"] = {
            ["Dodongo Cavern Pot Green Roon Pot 1"] = function () return true end,
            ["Dodongo Cavern Pot Green Roon Pot 2"] = function () return true end,
            ["Dodongo Cavern Pot Green Roon Pot 3"] = function () return true end,
            ["Dodongo Cavern Pot Green Roon Pot 4"] = function () return true end,
        },
    },
    ["Dodongo Cavern Green Side Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Green Room"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern Green Side Room Scrub"] = function () return business_scrub(29) end,
        },
    },
    ["Dodongo Cavern Main Ledge"] = {
        ["events"] = {
            ["DC_MAIN_SWITCH"] = function () return true end,
        },
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Green Room"] = function () return true end,
        },
    },
    ["Dodongo Cavern Stairs"] = {
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Compass Room"] = function () return true end,
            ["Dodongo Cavern Stairs Top"] = function () return has_bombflowers() or can_use_din() or climb_anywhere() or hookshot_anywhere() end,
        },
    },
    ["Dodongo Cavern Stairs Top"] = {
        ["exits"] = {
            ["Dodongo Cavern Stairs"] = function () return true end,
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Stairs Vines"] = function () return gs() end,
            ["Dodongo Cavern GS Stairs Top"] = function () return gs() and (can_collect_distance() and event('DC_SHORTCUT') or hookshot_anywhere() or (climb_anywhere() and (has_explosives() or has_ranged_weapon() or can_use_din()))) end,
            ["Dodongo Cavern Pot Stairs Pot 1"] = function () return true end,
            ["Dodongo Cavern Pot Stairs Pot 2"] = function () return true end,
            ["Dodongo Cavern Pot Stairs Pot 3"] = function () return true end,
            ["Dodongo Cavern Pot Stairs Pot 4"] = function () return true end,
            ["Dodongo Cavern Grass Lobby"] = function () return can_cut_grass() end,
        },
    },
    ["Dodongo Cavern Compass Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Stairs"] = function () return soul_armos() end,
        },
        ["locations"] = {
            ["Dodongo Cavern Compass Chest"] = function () return true end,
        },
    },
    ["Dodongo Cavern Bomb Bag Room 1"] = {
        ["exits"] = {
            ["Dodongo Cavern Stairs Top"] = function () return true end,
            ["Dodongo Cavern Bomb Bag Room 2"] = function () return can_longshot() or has_hover_boots() or (is_adult() and trick('OOT_DC_JUMP')) or climb_anywhere() or hookshot_anywhere() end,
            ["Dodongo Cavern Miniboss 2"] = function () return can_hit_triggers_distance() or climb_anywhere() or hookshot_anywhere() end,
            ["Dodongo Cavern Bomb Bag Side Room"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
        },
        ["locations"] = {
            ["Dodongo Cavern Bomb Bag Side Chest"] = function () return true end,
            ["Dodongo Cavern Pot Room Before Miniboss 1"] = function () return true end,
            ["Dodongo Cavern Pot Room Before Miniboss 2"] = function () return true end,
            ["Dodongo Cavern Grass Bomb Bag Room"] = function () return can_cut_grass() end,
            ["Dodongo Cavern Grass Pre-Miniboss"] = function () return can_cut_grass() end,
            ["Dodongo Cavern Heart Bomb Bag Room"] = function () return true end,
        },
    },
    ["Dodongo Cavern Bomb Bag Side Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern Bomb Bag Side Room Left Scrub"] = function () return business_scrub(30) end,
            ["Dodongo Cavern Bomb Bag Side Room Right Scrub"] = function () return business_scrub(28) end,
        },
    },
    ["Dodongo Cavern Miniboss 2"] = {
        ["exits"] = {
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return soul_lizalfos_dinalfos() and (can_use_sticks() or has_weapon() or can_use_slingshot() or can_hammer()) end,
            ["Dodongo Cavern Bomb Bag Room 2"] = function () return soul_lizalfos_dinalfos() and (can_use_sticks() or has_weapon() or can_use_slingshot() or can_hammer()) end,
            ["Dodongo Cavern Miniboss 1"] = function () return time_travel_at_will() end,
        },
        ["locations"] = {
            ["Dodongo Cavern Pot Miniboss 1"] = function () return true end,
            ["Dodongo Cavern Pot Miniboss 2"] = function () return true end,
            ["Dodongo Cavern Pot Miniboss 3"] = function () return true end,
            ["Dodongo Cavern Pot Miniboss 4"] = function () return true end,
            ["Dodongo Cavern Heart Miniboss Upper 1"] = function () return true end,
            ["Dodongo Cavern Heart Miniboss Upper 2"] = function () return true end,
        },
    },
    ["Dodongo Cavern Bomb Bag Room 2"] = {
        ["exits"] = {
            ["Dodongo Cavern Miniboss 2"] = function () return true end,
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return true end,
            ["Dodongo Cavern Main Bridge"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern Bomb Bag Chest"] = function () return true end,
            ["Dodongo Cavern Pot Bomb Bag Room 1"] = function () return true end,
            ["Dodongo Cavern Pot Bomb Bag Room 2"] = function () return true end,
            ["Dodongo Cavern Pot Room After Miniboss 1"] = function () return true end,
            ["Dodongo Cavern Pot Room After Miniboss 2"] = function () return true end,
        },
    },
    ["Dodongo Cavern Main Bridge"] = {
        ["events"] = {
            ["DC_SHORTCUT"] = function () return true end,
            ["DC_BOMB_EYES"] = function () return has_explosives() end,
        },
        ["exits"] = {
            ["Dodongo Cavern Bomb Bag Room 2"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern Bridge Chest"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
        },
    },
    ["Dodongo Cavern Skull"] = {
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Boss"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Near Boss"] = function () return gs() end,
            ["Dodongo Cavern Pot Skull 1"] = function () return true end,
            ["Dodongo Cavern Pot Skull 2"] = function () return true end,
            ["Dodongo Cavern Pot Skull 3"] = function () return true end,
            ["Dodongo Cavern Pot Skull 4"] = function () return true end,
            ["Dodongo Cavern Grass Pre-Boss"] = function () return can_cut_grass() end,
        },
    },
    ["Fire Temple"] = {
        ["exits"] = {
            ["Death Mountain Crater Near Temple"] = function () return true end,
            ["Fire Temple Lava Room"] = function () return small_keys_fire(1) end,
            ["Fire Temple Boss Key Loop Start"] = function () return cond(setting('smallKeyShuffleOot', 'anywhere'), small_keys_fire(7), true) and can_hammer() end,
            ["Fire Temple Pre-Boss"] = function () return true end,
        },
    },
    ["Fire Temple Pre-Boss"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return has_tunic_goron() end,
        },
        ["exits"] = {
            ["Fire Temple"] = function () return true end,
            ["Fire Temple Boss"] = function () return boss_key(BOSS_KEY_FIRE) and has_tunic_goron() and ((is_adult() or time_travel_at_will()) and event('FIRE_TEMPLE_PILLAR_HAMMER') or has_hover_boots() or climb_anywhere() or hookshot_anywhere()) end,
        },
        ["locations"] = {
            ["Fire Temple Jail 1 Chest"] = function () return has_tunic_goron() end,
            ["Fire Temple Pot Pre-Boss Room 1"] = function () return has_tunic_goron() and (is_adult() and (has_hover_boots() or can_hookshot() or glitch_megaflip()) or climb_anywhere() or hookshot_anywhere()) end,
            ["Fire Temple Pot Pre-Boss Room 2"] = function () return has_tunic_goron() and (is_adult() and (has_hover_boots() or can_hookshot() or glitch_megaflip()) or climb_anywhere() or hookshot_anywhere()) end,
            ["Fire Temple Pot Pre-Boss Room 3"] = function () return has_tunic_goron() and (is_adult() and (has_hover_boots() or can_hookshot() or glitch_megaflip()) or climb_anywhere() or hookshot_anywhere()) end,
            ["Fire Temple Pot Pre-Boss Room 4"] = function () return has_tunic_goron() and (is_adult() and (has_hover_boots() or can_hookshot() or glitch_megaflip()) or climb_anywhere() or hookshot_anywhere()) end,
        },
    },
    ["Fire Temple Boss Key Loop Start"] = {
        ["exits"] = {
            ["Fire Temple"] = function () return true end,
            ["Fire Temple Boss Key Loop Floor Tiles"] = function () return soul_keese() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) end,
        },
    },
    ["Fire Temple Boss Key Loop Floor Tiles"] = {
        ["exits"] = {
            ["Fire Temple Boss Key Loop Start"] = function () return true end,
            ["Fire Temple Boss Key Loop Flare Dancer"] = function () return true end,
        },
        ["locations"] = {
            ["Fire Temple GS Hammer Statues"] = function () return gs() end,
        },
    },
    ["Fire Temple Boss Key Loop Flare Dancer"] = {
        ["exits"] = {
            ["Fire Temple Boss Key Loop Floor Tiles"] = function () return soul_enemy(SOUL_ENEMY_FLARE_DANCER) end,
            ["Fire Temple Boss Key Loop End"] = function () return soul_enemy(SOUL_ENEMY_FLARE_DANCER) end,
        },
        ["locations"] = {
            ["Fire Temple Boss Key Side Chest"] = function () return soul_enemy(SOUL_ENEMY_FLARE_DANCER) and (is_adult() or can_hookshot() or climb_anywhere()) end,
        },
    },
    ["Fire Temple Boss Key Loop End"] = {
        ["locations"] = {
            ["Fire Temple Boss Key Chest"] = function () return true end,
        },
    },
    ["Fire Temple Lava Room"] = {
        ["exits"] = {
            ["Fire Temple Maze"] = function () return small_keys_fire(3) and has_tunic_goron_strict() and (hookshot_anywhere() or (((is_adult() or time_travel_at_will()) and has_goron_bracelet() or climb_anywhere()) and (has_ranged_weapon() or has_explosives()))) end,
        },
        ["locations"] = {
            ["Fire Temple Lava Room North Jail Chest"] = function () return has_tunic_goron() end,
            ["Fire Temple Lava Room South Jail Chest"] = function () return (is_adult() or climb_anywhere() or hookshot_anywhere()) and has_tunic_goron() and has_explosives() end,
            ["Fire Temple GS Lava Side Room"] = function () return gs() and has_tunic_goron() and (climb_anywhere() or hookshot_anywhere() or (is_adult() and can_play_time())) and can_damage_skull() end,
            ["Fire Temple Pot Lava Room 1"] = function () return has_tunic_goron() end,
            ["Fire Temple Pot Lava Room 2"] = function () return has_tunic_goron() end,
            ["Fire Temple Pot Lava Room 3"] = function () return has_tunic_goron() end,
            ["Fire Temple Heart Elevator 1"] = function () return small_keys_fire(2) and has_tunic_goron_strict() end,
            ["Fire Temple Heart Elevator 2"] = function () return small_keys_fire(2) and has_tunic_goron_strict() end,
            ["Fire Temple Heart Elevator 3"] = function () return small_keys_fire(2) and has_tunic_goron_strict() end,
        },
    },
    ["Fire Temple Maze"] = {
        ["exits"] = {
            ["Fire Temple Maze Upper"] = function () return small_keys_fire(5) or climb_anywhere() or hookshot_anywhere() end,
            ["Fire Temple Ledge Above Main"] = function () return small_keys_fire(4) or climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Fire Temple Maze Chest"] = function () return true end,
            ["Fire Temple Maze Jail Chest"] = function () return true end,
            ["Fire Temple GS Maze"] = function () return gs() and has_explosives() and (climb_anywhere() or can_collect_distance()) end,
            ["Fire Temple Map"] = function () return can_hit_triggers_distance() and small_keys_fire(4) end,
        },
    },
    ["Fire Temple Ledge Above Main"] = {
        ["locations"] = {
            ["Fire Temple Heart Ledge Above Main 1"] = function () return true end,
            ["Fire Temple Heart Ledge Above Main 2"] = function () return true end,
            ["Fire Temple Heart Ledge Above Main 3"] = function () return true end,
        },
    },
    ["Fire Temple Maze Upper"] = {
        ["exits"] = {
            ["Fire Temple Ring"] = function () return small_keys_fire(6) and (is_adult() or climb_anywhere() or hookshot_anywhere()) end,
            ["Fire Temple Scarecrow"] = function () return scarecrow_hookshot() or hookshot_anywhere() or climb_anywhere() end,
        },
        ["locations"] = {
            ["Fire Temple Map"] = function () return true end,
            ["Fire Temple Above Maze Chest"] = function () return true end,
            ["Fire Temple Below Maze Chest"] = function () return has_explosives() end,
            ["Fire Temple Heart Map Room 1"] = function () return is_adult() or climb_anywhere() or hookshot_anywhere() or can_boomerang() end,
            ["Fire Temple Heart Map Room 2"] = function () return is_adult() or climb_anywhere() or hookshot_anywhere() or can_boomerang() end,
            ["Fire Temple Heart Map Room 3"] = function () return true end,
        },
    },
    ["Fire Temple Scarecrow"] = {
        ["locations"] = {
            ["Fire Temple Scarecrow Chest"] = function () return true end,
            ["Fire Temple GS Scarecrow Wall"] = function () return gs() and (has_weapon() or has_ranged_weapon() or has_explosives() or can_use_sticks() or can_use_din()) end,
            ["Fire Temple GS Scarecrow Top"] = function () return gs() and (can_hookshot() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_din()))) end,
        },
    },
    ["Fire Temple Ring"] = {
        ["exits"] = {
            ["Fire Temple Before Miniboss"] = function () return small_keys_fire(7) or hookshot_anywhere() or climb_anywhere() end,
            ["Fire Temple Pillar Ledge"] = function () return has_hover_boots() or hookshot_anywhere() or climb_anywhere() end,
        },
        ["locations"] = {
            ["Fire Temple Compass"] = function () return true end,
            ["Fire Temple Pot Ring 1"] = function () return true end,
            ["Fire Temple Pot Ring 2"] = function () return true end,
            ["Fire Temple Pot Ring 3"] = function () return true end,
            ["Fire Temple Pot Ring 4"] = function () return true end,
        },
    },
    ["Fire Temple Before Miniboss"] = {
        ["exits"] = {
            ["Fire Temple After Miniboss"] = function () return soul_enemy(SOUL_ENEMY_FLARE_DANCER) and has_explosives() and (has_weapon() or can_hammer() or can_use_sticks()) end,
            ["Fire Temple Pillar Ledge"] = function () return can_play_time() or hookshot_anywhere() or climb_anywhere() end,
        },
        ["locations"] = {
            ["Fire Temple Ring Jail"] = function () return can_hammer() and can_play_time() end,
            ["Fire Temple Pot Before Miniboss 1"] = function () return true end,
            ["Fire Temple Pot Before Miniboss 2"] = function () return true end,
            ["Fire Temple Pot Before Miniboss 3"] = function () return true end,
            ["Fire Temple Pot Before Miniboss 4"] = function () return true end,
        },
    },
    ["Fire Temple Pillar Ledge"] = {
        ["events"] = {
            ["FIRE_TEMPLE_PILLAR_HAMMER"] = function () return can_hammer() end,
        },
        ["exits"] = {
            ["Fire Temple Before Miniboss"] = function () return can_hammer() end,
            ["Fire Temple Ring"] = function () return true end,
        },
        ["locations"] = {
            ["Fire Temple Ring Jail"] = function () return can_hammer() and trick('OOT_HAMMER_WALLS') end,
        },
    },
    ["Fire Temple After Miniboss"] = {
        ["exits"] = {
            ["Fire Temple Pillar Ledge"] = function () return can_hammer() end,
        },
        ["locations"] = {
            ["Fire Temple Hammer"] = function () return true end,
        },
    },
    ["Forest Temple"] = {
        ["exits"] = {
            ["Sacred Meadow"] = function () return true end,
            ["Forest Temple Main"] = function () return is_adult() or has_nuts() or has_weapon() or has_explosives_or_hammer() or has_ranged_weapon_child() end,
        },
        ["locations"] = {
            ["Forest Temple Tree Small Key"] = function () return true end,
            ["Forest Temple GS Entrance"] = function () return gs() and (has_ranged_weapon() or has_explosives() or can_use_din()) end,
        },
    },
    ["Forest Temple Wallmaster West"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Forest Temple Wallmaster East"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Forest Temple Main"] = {
        ["events"] = {
            ["FOREST_POE_4"] = function () return event('FOREST_POE_1') and event('FOREST_POE_2') and event('FOREST_POE_3') end,
        },
        ["exits"] = {
            ["Forest Temple"] = function () return true end,
            ["Forest Temple Mini-Boss"] = function () return true end,
            ["Forest Temple Garden West"] = function () return is_child() or can_play_time() end,
            ["Forest Temple Garden East"] = function () return can_hit_triggers_distance() end,
            ["Forest Temple Maze"] = function () return small_keys_forest(1) end,
            ["Forest Temple Antichamber"] = function () return event('FOREST_POE_4') end,
            ["Forest Temple Poe 3"] = function () return climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Forest Temple GS Main"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_din()))) end,
            ["Forest Temple Pot Main Room 1"] = function () return true end,
            ["Forest Temple Pot Main Room 2"] = function () return true end,
            ["Forest Temple Pot Main Room 3"] = function () return true end,
            ["Forest Temple Pot Main Room 4"] = function () return true end,
            ["Forest Temple Pot Main Room 5"] = function () return true end,
            ["Forest Temple Pot Main Room 6"] = function () return true end,
        },
    },
    ["Forest Temple Mini-Boss"] = {
        ["locations"] = {
            ["Forest Temple Mini-Boss Key"] = function () return has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["Forest Temple Pot Miniboss Lower 1"] = function () return true end,
            ["Forest Temple Pot Miniboss Lower 2"] = function () return true end,
        },
    },
    ["Forest Temple Garden West"] = {
        ["events"] = {
            ["STICKS"] = function () return can_hookshot() or can_hammer() or can_boomerang() or (has_nuts() and has_weapon()) end,
            ["NUTS"] = function () return is_adult() or has_weapon() or has_explosives() or can_use_slingshot() end,
        },
        ["exits"] = {
            ["Forest Temple Main"] = function () return true end,
            ["Forest Temple Map Room"] = function () return true end,
            ["Forest Temple Well"] = function () return event('FOREST_WELL') or can_dive_big() end,
            ["Forest Temple Garden West Ledge"] = function () return climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Forest Temple GS Garden West"] = function () return gs() and ((can_longshot() or (climb_anywhere() and has_bombchu())) or (event('FOREST_LEDGE_REACHED') and (can_collect_distance() or (climb_anywhere() and has_ranged_weapon())))) end,
        },
    },
    ["Forest Temple Garden West Ledge"] = {
        ["events"] = {
            ["FOREST_LEDGE_REACHED"] = function () return true end,
        },
        ["exits"] = {
            ["Forest Temple Garden West"] = function () return true end,
            ["Forest Temple Floormaster"] = function () return true end,
            ["Forest Temple Maze"] = function () return true end,
            ["Forest Temple Twisted 1 Alt"] = function () return event('FOREST_TWISTED_HALL') and hookshot_anywhere() and climb_anywhere() end,
        },
        ["locations"] = {
            ["Forest Temple Heart Garden 1"] = function () return true end,
            ["Forest Temple Heart Garden 2"] = function () return true end,
        },
    },
    ["Forest Temple Floormaster"] = {
        ["locations"] = {
            ["Forest Temple Floormaster"] = function () return soul_floormaster() and (has_weapon() or can_use_sticks()) end,
        },
    },
    ["Forest Temple Map Room"] = {
        ["exits"] = {
            ["Forest Temple Garden West"] = function () return soul_bubble() and (can_use_bow() or has_explosives() or ((can_hookshot() or has_nuts() or can_boomerang() or has_shield()) and (has_weapon() or can_use_slingshot() or can_use_sticks()))) end,
            ["Forest Temple Garden East Ledge"] = function () return soul_bubble() and (can_use_bow() or has_explosives() or ((can_hookshot() or has_nuts() or can_boomerang() or has_shield()) and (has_weapon() or can_use_slingshot() or can_use_sticks()))) end,
        },
        ["locations"] = {
            ["Forest Temple Map"] = function () return soul_bubble() and (can_use_bow() or has_explosives() or ((can_hookshot() or has_nuts() or can_boomerang() or has_shield()) and (has_weapon() or can_use_slingshot() or can_use_sticks()))) end,
        },
    },
    ["Forest Temple Garden East Ledge"] = {
        ["events"] = {
            ["FOREST_WELL"] = function () return true end,
        },
        ["exits"] = {
            ["Forest Temple Garden East"] = function () return true end,
            ["Forest Temple Map Room"] = function () return true end,
        },
    },
    ["Forest Temple Garden East"] = {
        ["events"] = {
            ["STICKS"] = function () return can_hookshot() or can_hammer() or can_boomerang() or (has_nuts() and has_weapon()) end,
            ["NUTS"] = function () return is_adult() or has_weapon() or has_explosives() or can_use_slingshot() end,
        },
        ["exits"] = {
            ["Forest Temple Well"] = function () return event('FOREST_WELL') or can_dive_big() end,
            ["Forest Temple Garden East Ledge"] = function () return can_longshot() or (can_hookshot() and trick('OOT_FOREST_HOOK')) or climb_anywhere() end,
            ["Forest Temple Checkerboard"] = function () return climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Forest Temple Garden"] = function () return can_hookshot() or climb_anywhere() end,
            ["Forest Temple GS Garden East"] = function () return gs() and (can_hookshot() or (climb_anywhere() and (has_ranged_weapon() or can_use_sword_master() or has_explosives() or can_use_din() or (age_sword_adult() and has('SWORD_BIGGORON')) or can_use_sticks() or (can_use_sword_kokiri() and has_hover_boots())))) end,
        },
    },
    ["Forest Temple Well"] = {
        ["exits"] = {
            ["Forest Temple Garden West"] = function () return true end,
            ["Forest Temple Garden East"] = function () return true end,
        },
        ["locations"] = {
            ["Forest Temple Well"] = function () return event('FOREST_WELL') end,
            ["Forest Temple Heart Well 1"] = function () return event('FOREST_WELL') or has_iron_boots() end,
            ["Forest Temple Heart Well 2"] = function () return event('FOREST_WELL') or has_iron_boots() end,
        },
    },
    ["Forest Temple Maze"] = {
        ["events"] = {
            ["FOREST_TWISTED_HALL"] = function () return ((is_adult() or time_travel_at_will()) and has_goron_bracelet() or climb_anywhere() or hookshot_anywhere()) and can_hit_triggers_distance() end,
        },
        ["exits"] = {
            ["Forest Temple Main"] = function () return true end,
            ["Forest Temple Garden West Ledge"] = function () return has_hover_boots() or climb_anywhere() or hookshot_anywhere() end,
            ["Forest Temple Twisted 1 Normal"] = function () return ((is_adult() or time_travel_at_will()) and has_goron_bracelet() or climb_anywhere() or hookshot_anywhere()) and cond(not setting('hookshotAnywhereOot', 'off') and (not setting('ageChange', 'none')), small_keys_forest(5), small_keys_forest(2)) end,
            ["Forest Temple Twisted 1 Alt"] = function () return event('FOREST_TWISTED_HALL') and cond(not setting('hookshotAnywhereOot', 'off') and (not setting('ageChange', 'none')), small_keys_forest(5), small_keys_forest(2)) end,
        },
        ["locations"] = {
            ["Forest Temple Maze"] = function () return (has_goron_bracelet() or climb_anywhere() or hookshot_anywhere()) and can_hit_triggers_distance() end,
        },
    },
    ["Forest Temple Twisted 1 Normal"] = {
        ["exits"] = {
            ["Forest Temple Wallmaster West"] = function () return soul_wallmaster() end,
            ["Forest Temple Poe 1"] = function () return cond(not setting('hookshotAnywhereOot', 'off') and (not setting('ageChange', 'none')), small_keys_forest(5), small_keys_forest(3)) end,
        },
    },
    ["Forest Temple Twisted 1 Alt"] = {
        ["exits"] = {
            ["Forest Temple Wallmaster West"] = function () return soul_wallmaster() end,
            ["Forest Temple Garden West Ledge"] = function () return soul_bubble() and (can_use_bow() or can_hammer() or has_explosives() or has_nuts() or can_collect_distance() or has_shield()) end,
        },
        ["locations"] = {
            ["Forest Temple Boss Key"] = function () return true end,
        },
    },
    ["Forest Temple Poe 1"] = {
        ["events"] = {
            ["FOREST_POE_1"] = function () return can_use_bow() end,
        },
        ["exits"] = {
            ["Forest Temple Mini-Boss 2"] = function () return true end,
        },
        ["locations"] = {
            ["Forest Temple Poe Key"] = function () return event('FOREST_POE_1') end,
        },
    },
    ["Forest Temple Mini-Boss 2"] = {
        ["exits"] = {
            ["Forest Temple Poe 2"] = function () return has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
        },
        ["locations"] = {
            ["Forest Temple Bow"] = function () return has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["Forest Temple Pot Miniboss Upper 1"] = function () return true end,
            ["Forest Temple Pot Miniboss Upper 2"] = function () return true end,
            ["Forest Temple Pot Miniboss Upper 3"] = function () return true end,
            ["Forest Temple Pot Miniboss Upper 4"] = function () return true end,
        },
    },
    ["Forest Temple Poe 2"] = {
        ["events"] = {
            ["FOREST_POE_2"] = function () return can_use_bow() end,
        },
        ["exits"] = {
            ["Forest Temple Twisted 2 Normal"] = function () return small_keys_forest(4) end,
        },
        ["locations"] = {
            ["Forest Temple Compass"] = function () return event('FOREST_POE_2') end,
            ["Forest Temple Pot Blue Poe 1"] = function () return true end,
            ["Forest Temple Pot Blue Poe 2"] = function () return true end,
            ["Forest Temple Pot Blue Poe 3"] = function () return true end,
        },
    },
    ["Forest Temple Twisted 2 Normal"] = {
        ["exits"] = {
            ["Forest Temple Wallmaster East"] = function () return soul_wallmaster() end,
            ["Forest Temple Rotating Room"] = function () return small_keys_forest(5) end,
        },
    },
    ["Forest Temple Rotating Room"] = {
        ["exits"] = {
            ["Forest Temple Twisted 2 Alt"] = function () return can_use_bow() or can_use_din() end,
        },
        ["locations"] = {
            ["Forest Temple Pot Rotating Room 1"] = function () return true end,
            ["Forest Temple Pot Rotating Room 2"] = function () return true end,
        },
    },
    ["Forest Temple Twisted 2 Alt"] = {
        ["exits"] = {
            ["Forest Temple Wallmaster East"] = function () return soul_wallmaster() end,
            ["Forest Temple Checkerboard"] = function () return true end,
        },
    },
    ["Forest Temple Checkerboard"] = {
        ["exits"] = {
            ["Forest Temple Poe 3"] = function () return true end,
            ["Forest Temple Garden East"] = function () return true end,
        },
        ["locations"] = {
            ["Forest Temple Checkerboard"] = function () return true end,
            ["Forest Temple Garden"] = function () return true end,
            ["Forest Temple GS Garden East"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or can_use_sword_master() or has_explosives() or can_use_din() or (age_sword_adult() and has('SWORD_BIGGORON')) or can_use_sticks() or (can_use_sword_kokiri() and has_hover_boots())))) end,
        },
    },
    ["Forest Temple Poe 3"] = {
        ["events"] = {
            ["FOREST_POE_3"] = function () return can_use_bow() end,
        },
        ["exits"] = {
            ["Forest Temple Checkerboard"] = function () return true end,
        },
        ["locations"] = {
            ["Forest Temple Pot Green Poe Pot 1"] = function () return true end,
            ["Forest Temple Pot Green Poe Pot 2"] = function () return true end,
        },
    },
    ["Forest Temple Antichamber"] = {
        ["exits"] = {
            ["Forest Temple Boss"] = function () return boss_key(BOSS_KEY_FOREST) end,
        },
        ["locations"] = {
            ["Forest Temple Antichamber"] = function () return true end,
            ["Forest Temple GS Antichamber"] = function () return gs() and (can_collect_distance() or climb_anywhere()) end,
        },
    },
    ["Ganon Castle"] = {
        ["exits"] = {
            ["Ganon Castle Exterior After Bridge"] = function () return true end,
            ["Ganon Castle Light"] = function () return can_lift_gold() end,
            ["Ganon Castle Forest"] = function () return true end,
            ["Ganon Castle Fire"] = function () return true end,
            ["Ganon Castle Water"] = function () return true end,
            ["Ganon Castle Spirit"] = function () return true end,
            ["Ganon Castle Shadow"] = function () return true end,
            ["Ganon Castle Stairs"] = function () return true end,
            ["Ganon Castle Fairy Fountain"] = function () return has_lens() end,
        },
    },
    ["Ganon Castle Spirit Wallmaster"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Ganon Castle Light Wallmaster"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Ganon Castle Fairy Fountain"] = {
        ["locations"] = {
            ["Ganon Castle Leftmost Scrub"] = function () return business_scrub(33) end,
            ["Ganon Castle Left-Center Scrub"] = function () return business_scrub(34) end,
            ["Ganon Castle Right-Center Scrub"] = function () return business_scrub(35) end,
            ["Ganon Castle Rightmost Scrub"] = function () return business_scrub(36) end,
            ["Ganon Castle Fairy Fountain Fairy 1"] = function () return true end,
            ["Ganon Castle Fairy Fountain Fairy 2"] = function () return true end,
            ["Ganon Castle Fairy Fountain Fairy 3"] = function () return true end,
            ["Ganon Castle Fairy Fountain Fairy 4"] = function () return true end,
            ["Ganon Castle Fairy Fountain Fairy 5"] = function () return true end,
            ["Ganon Castle Fairy Fountain Fairy 6"] = function () return true end,
            ["Ganon Castle Fairy Fountain Fairy 7"] = function () return true end,
            ["Ganon Castle Fairy Fountain Fairy 8"] = function () return true end,
        },
    },
    ["Ganon Castle Light"] = {
        ["exits"] = {
            ["Ganon Castle Light 2"] = function () return small_keys_ganon(2) end,
        },
        ["locations"] = {
            ["Ganon Castle Light Chest Around 1"] = function () return true end,
            ["Ganon Castle Light Chest Around 2"] = function () return true end,
            ["Ganon Castle Light Chest Around 3"] = function () return true end,
            ["Ganon Castle Light Chest Around 4"] = function () return true end,
            ["Ganon Castle Light Chest Around 5"] = function () return true end,
            ["Ganon Castle Light Chest Around 6"] = function () return true end,
            ["Ganon Castle Light Chest Center"] = function () return soul_keese() and soul_skulltula() and has_lens() and (has_weapon() or has_explosives_or_hammer() or can_use_slingshot() or can_use_sticks()) end,
            ["Ganon Castle Light Chest Lullaby"] = function () return small_keys_ganon(1) and can_play_zelda() end,
        },
    },
    ["Ganon Castle Light 2"] = {
        ["exits"] = {
            ["Ganon Castle Light Wallmaster"] = function () return true end,
            ["Ganon Castle Light End"] = function () return silver_rupees_ganon_light() and has_lens() end,
        },
        ["locations"] = {
            ["Ganon Castle SR Light Alcove Right"] = function () return true end,
            ["Ganon Castle SR Light Alcove Left"] = function () return true end,
            ["Ganon Castle SR Light Center Top"] = function () return can_hookshot() or climb_anywhere() end,
            ["Ganon Castle SR Light Center Right"] = function () return true end,
            ["Ganon Castle SR Light Center Left"] = function () return true end,
            ["Ganon Castle Pot Light"] = function () return true end,
        },
    },
    ["Ganon Castle Light End"] = {
        ["events"] = {
            ["GANON_TRIAL_LIGHT"] = function () return can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Pot Light End 1"] = function () return true end,
            ["Ganon Castle Pot Light End 2"] = function () return true end,
        },
    },
    ["Ganon Castle Forest"] = {
        ["exits"] = {
            ["Ganon Castle Forest 2"] = function () return has_fire_arrows() or (can_use_din() and (has_ranged_weapon_adult() or climb_anywhere())) end,
        },
        ["locations"] = {
            ["Ganon Castle Forest Chest"] = function () return soul_wolfos() and (has_weapon() or has_explosives_or_hammer() or can_hit_triggers_distance() or can_use_sticks() or can_use_din()) end,
        },
    },
    ["Ganon Castle Forest 2"] = {
        ["exits"] = {
            ["Ganon Castle Forest End"] = function () return silver_rupees_ganon_forest() end,
        },
        ["locations"] = {
            ["Ganon Castle SR Forest Center Right"] = function () return true end,
            ["Ganon Castle SR Forest Front"] = function () return true end,
            ["Ganon Castle SR Forest Back Right"] = function () return true end,
            ["Ganon Castle SR Forest Back Middle"] = function () return true end,
            ["Ganon Castle SR Forest Center Left"] = function () return is_adult() or climb_anywhere() or can_hookshot() end,
        },
    },
    ["Ganon Castle Forest End"] = {
        ["events"] = {
            ["GANON_TRIAL_FOREST"] = function () return can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Pot Forest End 1"] = function () return true end,
            ["Ganon Castle Pot Forest End 2"] = function () return true end,
        },
    },
    ["Ganon Castle Fire"] = {
        ["exits"] = {
            ["Ganon Castle Fire End"] = function () return silver_rupees_ganon_fire() and has_tunic_goron_strict() and (can_longshot() or climb_anywhere()) end,
        },
        ["locations"] = {
            ["Ganon Castle SR Fire Back Right"] = function () return has_tunic_goron() end,
            ["Ganon Castle SR Fire Left"] = function () return has_tunic_goron() end,
            ["Ganon Castle SR Fire Far Right"] = function () return has_tunic_goron_strict() and (can_lift_gold() or climb_anywhere() or hookshot_anywhere() or glitch_megaflip()) end,
            ["Ganon Castle SR Fire Front Right"] = function () return has_tunic_goron() end,
            ["Ganon Castle SR Fire Black Pillar"] = function () return has_tunic_goron() and can_lift_gold() end,
            ["Ganon Castle Heart Fire"] = function () return has_tunic_goron() end,
        },
    },
    ["Ganon Castle Fire End"] = {
        ["events"] = {
            ["GANON_TRIAL_FIRE"] = function () return can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Pot Fire End 1"] = function () return true end,
            ["Ganon Castle Pot Fire End 2"] = function () return true end,
        },
    },
    ["Ganon Castle Water"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return has_bottle() and (has_weapon() or has_explosives_or_hammer() or can_use_sticks()) end,
        },
        ["exits"] = {
            ["Ganon Castle Water 2"] = function () return soul_freezard() and has_blue_fire() and (can_use_sword_master() or can_use_sword_goron() or can_use_sticks() or has_explosives_or_hammer() or can_use_din()) end,
        },
        ["locations"] = {
            ["Ganon Castle Water Chest 1"] = function () return true end,
            ["Ganon Castle Water Chest 2"] = function () return true end,
        },
    },
    ["Ganon Castle Water 2"] = {
        ["exits"] = {
            ["Ganon Castle Water End"] = function () return can_hammer() and (is_adult() or climb_anywhere() or hookshot_anywhere()) end,
        },
        ["locations"] = {
            ["Ganon Castle Pot Water"] = function () return true end,
        },
    },
    ["Ganon Castle Water End"] = {
        ["events"] = {
            ["GANON_TRIAL_WATER"] = function () return can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Pot Water End 1"] = function () return true end,
            ["Ganon Castle Pot Water End 2"] = function () return true end,
        },
    },
    ["Ganon Castle Spirit"] = {
        ["exits"] = {
            ["Ganon Castle Spirit 2"] = function () return silver_rupees_ganon_spirit() end,
        },
        ["locations"] = {
            ["Ganon Castle SR Spirit Center Midair"] = function () return can_hookshot() end,
            ["Ganon Castle SR Spirit Front Right"] = function () return true end,
            ["Ganon Castle SR Spirit Center Bottom"] = function () return true end,
            ["Ganon Castle SR Spirit Back Left"] = function () return true end,
            ["Ganon Castle SR Spirit Back Right"] = function () return true end,
            ["Ganon Castle Heart Spirit"] = function () return true end,
            ["Ganon Castle Spirit Big Fairy"] = function () return can_play_sun() end,
        },
    },
    ["Ganon Castle Spirit 2"] = {
        ["exits"] = {
            ["Ganon Castle Spirit Wallmaster"] = function () return (has_bombchu() or climb_anywhere() or hookshot_anywhere()) and soul_wallmaster() and can_reflect_light() end,
            ["Ganon Castle Spirit End"] = function () return (has_bombchu() or climb_anywhere() or hookshot_anywhere()) and can_reflect_light() and can_use_bow() end,
        },
        ["locations"] = {
            ["Ganon Castle Spirit Chest 1"] = function () return can_use_sticks() or can_use_sword() or has_bombchu() or hookshot_anywhere() or (climb_anywhere() and (has_ranged_weapon() or has_explosives())) end,
            ["Ganon Castle Spirit Chest 2"] = function () return (has_bombchu() or climb_anywhere() or hookshot_anywhere()) and has_lens() end,
        },
    },
    ["Ganon Castle Spirit End"] = {
        ["events"] = {
            ["GANON_TRIAL_SPIRIT"] = function () return can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Pot Spirit End 1"] = function () return true end,
            ["Ganon Castle Pot Spirit End 2"] = function () return true end,
        },
    },
    ["Ganon Castle Shadow"] = {
        ["exits"] = {
            ["Ganon Castle Shadow End"] = function () return can_hammer() and ((can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) and (has_lens() or (can_longshot() and has_hover_boots())) or (climb_anywhere() and (has_hover_boots() or hookshot_anywhere() or has_lens()))) end,
        },
        ["locations"] = {
            ["Ganon Castle Shadow Chest 1"] = function () return can_play_time() or can_hookshot() or has_hover_boots() or has_fire_arrows() end,
            ["Ganon Castle Shadow Chest 2"] = function () return (can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) or (climb_anywhere() and (has_hover_boots() or hookshot_anywhere() or has_lens())) end,
            ["Ganon Castle Pot Shadow 1"] = function () return (can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) or (climb_anywhere() and (has_hover_boots() or hookshot_anywhere() or (has_lens() and has_fire_arrows()))) end,
            ["Ganon Castle Pot Shadow 2"] = function () return (can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) or (climb_anywhere() and (has_hover_boots() or hookshot_anywhere() or (has_lens() and has_fire_arrows()))) end,
            ["Ganon Castle Heart Shadow 1"] = function () return ((can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) or climb_anywhere()) and has_lens() end,
            ["Ganon Castle Heart Shadow 2"] = function () return ((can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) or climb_anywhere()) and has_lens() end,
            ["Ganon Castle Heart Shadow 3"] = function () return ((can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) or climb_anywhere()) and has_lens() end,
        },
    },
    ["Ganon Castle Shadow End"] = {
        ["events"] = {
            ["GANON_TRIAL_SHADOW"] = function () return can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Pot Shadow End 1"] = function () return true end,
            ["Ganon Castle Pot Shadow End 2"] = function () return true end,
        },
    },
    ["Ganon Castle Stairs"] = {
        ["exits"] = {
            ["Ganon Castle"] = function () return true end,
            ["Ganon Castle Tower"] = function () return ganon_barrier() end,
        },
    },
    ["Ganon Castle Tower"] = {
        ["exits"] = {
            ["Ganon Castle Stairs"] = function () return true end,
            ["Ganon Castle Tower Pre-Boss"] = function () return has_weapon() and soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_STALFOS) and soul_iron_knuckle() end,
        },
        ["locations"] = {
            ["Ganon Castle Boss Key"] = function () return has_weapon() and soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_STALFOS) end,
        },
    },
    ["Ganon Castle Tower Pre-Boss"] = {
        ["events"] = {
            ["GANON_PRE_BOSS"] = function () return true end,
        },
        ["exits"] = {
            ["Ganon Castle Tower Boss"] = function () return setting('ganonBossKey', 'removed') or has('BOSS_KEY_GANON') or (setting('ganonBossKey', 'custom') and special(GANON_BK)) end,
        },
    },
    ["Ganon Castle Tower Boss"] = {
        ["events"] = {
            ["GANON_START"] = function () return not is_goal_triforce() end,
            ["GANON"] = function () return event('GANON_START') and can_use_light_arrows() and soul_npc(SOUL_NPC_ZELDA) and can_use_sword_master() end,
        },
        ["locations"] = {
            ["Ganon Tower Pot 01"] = function () return true end,
            ["Ganon Tower Pot 02"] = function () return true end,
            ["Ganon Tower Pot 03"] = function () return true end,
            ["Ganon Tower Pot 04"] = function () return true end,
            ["Ganon Tower Pot 05"] = function () return true end,
            ["Ganon Tower Pot 06"] = function () return true end,
            ["Ganon Tower Pot 07"] = function () return true end,
            ["Ganon Tower Pot 08"] = function () return true end,
            ["Ganon Tower Pot 09"] = function () return true end,
            ["Ganon Tower Pot 10"] = function () return true end,
            ["Ganon Tower Pot 11"] = function () return true end,
            ["Ganon Tower Pot 12"] = function () return true end,
            ["Ganon Tower Pot 13"] = function () return true end,
            ["Ganon Tower Pot 14"] = function () return true end,
            ["Ganon Tower Pot 15"] = function () return true end,
            ["Ganon Tower Pot 16"] = function () return true end,
            ["Ganon Tower Pot 17"] = function () return true end,
            ["Ganon Tower Pot 18"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 1 Left"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["ARROWS"] = function () return is_adult() end,
            ["SEEDS"] = function () return is_child() end,
            ["CARPENTER_1"] = function () return can_rescue_carpenter() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Carpenter 1 Right"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Jail 1"] = function () return (has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks())) and soul_carpenters() end,
            ["Gerudo Member Card"] = function () return carpenters_rescued() end,
            ["Gerudo Fortress Pot Jail 1 1"] = function () return true end,
            ["Gerudo Fortress Pot Jail 1 2"] = function () return true end,
            ["Gerudo Fortress Pot Jail 1 3"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 1 Right"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Carpenter 1 Left"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 2 Bottom"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["CARPENTER_2"] = function () return can_rescue_carpenter() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Carpenter 2 Top"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Jail 2"] = function () return (has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks())) and soul_carpenters() end,
            ["Gerudo Member Card"] = function () return carpenters_rescued() end,
            ["Gerudo Fortress Pot Jail 2 1"] = function () return true end,
            ["Gerudo Fortress Pot Jail 2 2"] = function () return true end,
            ["Gerudo Fortress Pot Jail 2 3"] = function () return true end,
            ["Gerudo Fortress Pot Jail 2 4"] = function () return true end,
            ["Gerudo Fortress Pot Jail 2 5"] = function () return true end,
            ["Gerudo Fortress Pot Jail 2 6"] = function () return true end,
            ["Gerudo Fortress Pot Jail 2 7"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 2 Top"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 2 Bottom"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 4 Bottom"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Right Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 4 Top"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 4 Top"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["CARPENTER_4"] = function () return can_rescue_carpenter() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 4 Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Jail 4"] = function () return (has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks())) and soul_carpenters() end,
            ["Gerudo Member Card"] = function () return carpenters_rescued() end,
        },
    },
    ["Gerudo Fortress Kitchen Tunnel End"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Kitchen Tunnel Mid"] = function () return true end,
        },
    },
    ["Gerudo Fortress Kitchen Tunnel Mid"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Right Ledge"] = function () return true end,
            ["Gerudo Fortress Kitchen Tunnel End"] = function () return true end,
            ["Gerudo Fortress Kitchen Bottom"] = function () return evade_gerudo() end,
        },
    },
    ["Gerudo Fortress Kitchen Bottom"] = {
        ["exits"] = {
            ["Gerudo Fortress Kitchen Tunnel Mid"] = function () return evade_gerudo() end,
            ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = function () return evade_gerudo() end,
            ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = function () return evade_gerudo() end,
        },
        ["locations"] = {
            ["Gerudo Fortress Pot Kitchen 1"] = function () return true end,
            ["Gerudo Fortress Pot Kitchen 2"] = function () return true end,
            ["Gerudo Fortress Kitchen Big Fairy"] = function () return can_play_sun() end,
        },
    },
    ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Kitchen Bottom"] = function () return evade_gerudo() end,
            ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = function () return can_hookshot() or has_hover_boots() or climb_anywhere() end,
        },
    },
    ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = {
        ["exits"] = {
            ["Gerudo Fortress Upper-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Kitchen Bottom"] = function () return evade_gerudo() end,
            ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = function () return can_hookshot() or has_hover_boots() or climb_anywhere() end,
        },
    },
    ["Gerudo Fortress Carpenter 3"] = {
        ["events"] = {
            ["CARPENTER_3"] = function () return can_rescue_carpenter() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Center Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Jail 3"] = function () return (has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks())) and soul_carpenters() end,
            ["Gerudo Member Card"] = function () return carpenters_rescued() end,
            ["Gerudo Fortress Pot Jail 3 1"] = function () return true end,
            ["Gerudo Fortress Pot Jail 3 2"] = function () return true end,
        },
    },
    ["Gerudo Fortress Break Room Bottom"] = {
        ["events"] = {
            ["MAGIC"] = function () return evade_gerudo() end,
            ["ARROWS"] = function () return is_adult() and (has('GERUDO_CARD') or can_hookshot()) end,
            ["SEEDS"] = function () return is_child() and has('GERUDO_CARD') end,
        },
        ["exits"] = {
            ["Gerudo Fortress Lower-Left Ledge"] = function () return true end,
            ["Gerudo Fortress Break Room Top"] = function () return can_hookshot() or climb_anywhere() end,
        },
        ["locations"] = {
            ["Gerudo Fortress Pot Break Room 1"] = function () return true end,
            ["Gerudo Fortress Pot Break Room 2"] = function () return true end,
        },
    },
    ["Gerudo Fortress Break Room Top"] = {
        ["exits"] = {
            ["Gerudo Fortress Above Prison"] = function () return true end,
            ["Gerudo Fortress Break Room Bottom"] = function () return can_hookshot() or climb_anywhere() end,
        },
    },
    ["Gerudo Training Grounds"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Training Grounds Slopes"] = function () return has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["Gerudo Training Grounds Right Side"] = function () return has_explosives() and has_weapon() and soul_beamos() and soul_lizalfos_dinalfos() end,
            ["Gerudo Training Grounds Maze"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Entrance 1"] = function () return can_hit_triggers_distance() end,
            ["Gerudo Training Grounds Entrance 2"] = function () return can_hit_triggers_distance() end,
            ["Gerudo Training Grounds Stalfos"] = function () return has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["Gerudo Training Grounds Heart 1"] = function () return true end,
            ["Gerudo Training Grounds Heart 2"] = function () return true end,
            ["Gerudo Training Grounds Entrance Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Gerudo Training Grounds Wallmaster"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Slopes"] = {
        ["exits"] = {
            ["Gerudo Training Grounds"] = function () return true end,
            ["Gerudo Training Grounds Slopes End"] = function () return can_hookshot() or climb_anywhere() end,
            ["Gerudo Training Grounds Wallmaster"] = function () return soul_wallmaster() end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds SR Slope Front Right"] = function () return true end,
            ["Gerudo Training Grounds SR Slope Front Left"] = function () return true end,
            ["Gerudo Training Grounds SR Slope Front Above"] = function () return is_adult() and can_hookshot() or can_longshot() end,
            ["Gerudo Training Grounds SR Slope Center"] = function () return true end,
            ["Gerudo Training Grounds SR Slope Back"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Slopes End"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Slopes"] = function () return can_hookshot() or climb_anywhere() end,
            ["Gerudo Training Grounds Left Side"] = function () return silver_rupees_gtg_slopes() end,
        },
    },
    ["Gerudo Training Grounds Left Side"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Slopes End"] = function () return true end,
            ["Gerudo Training Grounds After Block"] = function () return can_lift_silver() and event('GTG_LIKE_LIKE_ROOM') end,
            ["Gerudo Training Grounds Upper"] = function () return (can_hookshot() or climb_anywhere()) and has_lens() end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Near Block"] = function () return soul_wolfos() and (has_weapon() or can_use_sticks() or has_explosives_or_hammer() or can_hit_triggers_distance() or can_use_din()) end,
        },
    },
    ["Gerudo Training Grounds After Block"] = {
        ["locations"] = {
            ["Gerudo Training Grounds Behind Block Invisible"] = function () return has_lens() end,
            ["Gerudo Training Grounds Behind Block Visible"] = function () return true end,
            ["Gerudo Training Grounds Behind Block Enemy Back"] = function () return soul_like_like() and (has_weapon() or can_use_sticks() or has_explosives_or_hammer() or can_hit_triggers_distance()) end,
            ["Gerudo Training Grounds Behind Block Enemy Front"] = function () return soul_like_like() and (has_weapon() or can_use_sticks() or has_explosives_or_hammer() or can_hit_triggers_distance()) end,
        },
    },
    ["Gerudo Training Grounds Upper"] = {
        ["events"] = {
            ["GTG_LIKE_LIKE_ROOM"] = function () return true end,
        },
        ["exits"] = {
            ["Gerudo Training Grounds Left Side"] = function () return has_lens() end,
            ["Gerudo Training Grounds Statue"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Training Maze Upper Cage"] = function () return can_use_bow() end,
        },
    },
    ["Gerudo Training Grounds Right Side"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Lava"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Lizalfos"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Lava"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Maze Side"] = function () return can_play_time() or is_child() or climb_anywhere() or hookshot_anywhere() end,
            ["Gerudo Training Grounds Hammer"] = function () return can_hookshot() and (can_longshot() or has_hover_boots() or can_play_time() or hookshot_anywhere() or is_child()) or climb_anywhere() end,
            ["Gerudo Training Grounds Water"] = function () return silver_rupees_gtg_lava() end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds SR Lava Front Left"] = function () return true end,
            ["Gerudo Training Grounds SR Lava Front Right"] = function () return true end,
            ["Gerudo Training Grounds SR Lava Back Left"] = function () return has_hover_boots() or can_play_time() or climb_anywhere() or hookshot_anywhere() or is_child() end,
            ["Gerudo Training Grounds SR Lava Back Center"] = function () return can_hookshot() and (can_longshot() or has_hover_boots() or can_play_time() or hookshot_anywhere() or is_child()) or climb_anywhere() end,
            ["Gerudo Training Grounds SR Lava Back Right"] = function () return can_longshot() or has_hover_boots() or can_play_time() or is_child() or climb_anywhere() or hookshot_anywhere() end,
        },
    },
    ["Gerudo Training Grounds Maze Side"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Lava"] = function () return true end,
            ["Gerudo Training Grounds Hammer"] = function () return can_hookshot() end,
        },
        ["locations"] = {
            ["Gerudo Training Freestanding Key"] = function () return true end,
            ["Gerudo Training Maze Side Chest 1"] = function () return true end,
            ["Gerudo Training Maze Side Chest 2"] = function () return true end,
            ["Gerudo Training Grounds SR Lava Back Center"] = function () return can_hookshot() end,
            ["Gerudo Training Grounds SR Lava Back Right"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Water"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Underwater"] = function () return can_play_time() and has_tunic_zora() and has_iron_boots() end,
        },
        ["locations"] = {
            ["Gerudo Training Water"] = function () return silver_rupees_gtg_water() end,
        },
    },
    ["Gerudo Training Grounds Underwater"] = {
        ["locations"] = {
            ["Gerudo Training Grounds SR Water 1"] = function () return true end,
            ["Gerudo Training Grounds SR Water 2"] = function () return true end,
            ["Gerudo Training Grounds SR Water 3"] = function () return true end,
            ["Gerudo Training Grounds SR Water 4"] = function () return true end,
            ["Gerudo Training Grounds SR Water 5"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Hammer"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Lava"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and soul_keese() and (has_weapon() or can_use_sticks() or can_hammer() or can_use_bow()) end,
            ["Gerudo Training Grounds Statue"] = function () return can_hammer() and can_hit_triggers_distance() end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Hammer Room Switch"] = function () return can_hammer() end,
            ["Gerudo Training Grounds Hammer Room"] = function () return soul_keese() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (has_weapon() or can_use_sticks() or can_hammer() or can_use_bow()) end,
            ["Gerudo Training Grounds SR Lava Back Center"] = function () return soul_keese() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (has_weapon() or can_use_sticks() or can_hammer() or can_use_bow()) and can_hookshot() end,
            ["Gerudo Training Grounds SR Lava Back Right"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Statue"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Hammer"] = function () return true end,
            ["Gerudo Training Grounds Upper"] = function () return climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Eye Statue"] = function () return can_use_bow() end,
        },
    },
    ["Gerudo Training Grounds Maze"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Maze Side"] = function () return small_keys_gtg(9) end,
        },
        ["locations"] = {
            ["Gerudo Training Maze Upper Fake Ceiling"] = function () return small_keys_gtg(3) and has_lens() end,
            ["Gerudo Training Maze Chest 1"] = function () return small_keys_gtg(4) end,
            ["Gerudo Training Maze Chest 2"] = function () return small_keys_gtg(6) end,
            ["Gerudo Training Maze Chest 3"] = function () return small_keys_gtg(7) end,
            ["Gerudo Training Maze Chest 4"] = function () return small_keys_gtg(9) end,
        },
    },
    ["Ice Cavern"] = {
        ["exits"] = {
            ["Zora Fountain Frozen"] = function () return true end,
            ["Ice Cavern Scythe"] = function () return soul_freezard() and (can_use_sword_master() or can_use_sword_goron() or can_use_sticks() or has_explosives()) end,
            ["Ice Cavern End"] = function () return has_iron_boots() and (climb_anywhere() or hookshot_anywhere()) end,
        },
        ["locations"] = {
            ["Ice Cavern Rupee Ice"] = function () return has_blue_fire() end,
            ["Ice Cavern Entrance Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Ice Cavern Scythe"] = {
        ["exits"] = {
            ["Ice Cavern HP Room"] = function () return has_blue_fire() end,
            ["Ice Cavern Block Room"] = function () return has_blue_fire() end,
            ["Ice Cavern First Fire Room"] = function () return (is_adult() or climb_anywhere() or hookshot_anywhere()) and silver_rupees_ic_scythe() end,
        },
        ["locations"] = {
            ["Ice Cavern GS Scythe Room"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_weapon() or can_use_sticks() or has_ranged_weapon() or has_explosives() or can_use_din()))) end,
            ["Ice Cavern SR Scythe Left"] = function () return true end,
            ["Ice Cavern SR Scythe Center Left"] = function () return true end,
            ["Ice Cavern SR Scythe Back"] = function () return true end,
            ["Ice Cavern SR Scythe Center Right"] = function () return true end,
            ["Ice Cavern SR Scythe Midair"] = function () return is_adult() or climb_anywhere() or hookshot_anywhere() end,
            ["Ice Cavern Pot First Corridor 1"] = function () return true end,
            ["Ice Cavern Pot First Corridor 2"] = function () return true end,
            ["Ice Cavern Pot Scythe Room 1"] = function () return true end,
            ["Ice Cavern Pot Scythe Room 2"] = function () return true end,
            ["Ice Cavern Pot Scythe Room 3"] = function () return true end,
            ["Ice Cavern Flying Pot Scythe Room"] = function () return soul_flying_pot() end,
        },
    },
    ["Ice Cavern HP Room"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return has_bottle() end,
        },
        ["locations"] = {
            ["Ice Cavern Compass"] = function () return true end,
            ["Ice Cavern HP"] = function () return true end,
            ["Ice Cavern GS HP Room"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_weapon() or can_use_sticks() or has_ranged_weapon() or has_explosives() or can_use_din()))) end,
        },
    },
    ["Ice Cavern First Fire Room"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return has_bottle() end,
        },
        ["locations"] = {
            ["Ice Cavern Map"] = function () return has_blue_fire() end,
            ["Ice Cavern Pot Map Room"] = function () return has_blue_fire() end,
            ["Ice Cavern Heart 1"] = function () return true end,
            ["Ice Cavern Heart 2"] = function () return true end,
            ["Ice Cavern Heart 3"] = function () return true end,
        },
    },
    ["Ice Cavern Block Room"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Ice Cavern Scythe"] = function () return true end,
            ["Ice Cavern End"] = function () return silver_rupees_ic_block() end,
        },
        ["locations"] = {
            ["Ice Cavern GS Block Room"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_din()))) end,
            ["Ice Cavern SR Blocks Back Left"] = function () return true end,
            ["Ice Cavern SR Blocks Back Right"] = function () return true end,
            ["Ice Cavern SR Blocks Center"] = function () return true end,
            ["Ice Cavern SR Blocks Alcove"] = function () return has_blue_fire() end,
            ["Ice Cavern SR Blocks Front Left"] = function () return true end,
            ["Ice Cavern Pot Red Ice 1"] = function () return silver_rupees_ic_block() end,
            ["Ice Cavern Pot Red Ice 2"] = function () return silver_rupees_ic_block() end,
            ["Ice Cavern Rupee Midair 1"] = function () return can_play_time() end,
            ["Ice Cavern Rupee Midair 2"] = function () return can_play_time() end,
            ["Ice Cavern Rupee Midair 3"] = function () return can_play_time() end,
        },
    },
    ["Ice Cavern End"] = {
        ["exits"] = {
            ["Ice Cavern Block Room"] = function () return (climb_anywhere() or hookshot_anywhere() or has_blue_fire()) and soul_wolfos() and (has_weapon() or can_hit_triggers_distance() or has_explosives_or_hammer() or can_use_din() or can_use_sticks()) end,
        },
        ["locations"] = {
            ["Ice Cavern Iron Boots"] = function () return soul_wolfos() and (has_weapon() or can_hit_triggers_distance() or has_explosives_or_hammer() or can_use_din() or can_use_sticks()) end,
            ["Ice Cavern Sheik Song"] = function () return soul_wolfos() and soul_npc(SOUL_NPC_SHEIK) and (has_weapon() or can_hit_triggers_distance() or has_explosives_or_hammer() or can_use_din() or can_use_sticks()) end,
            ["Ice Cavern Pot Red Ice 1"] = function () return soul_wolfos() and has_blue_fire() and (has_weapon() or can_hit_triggers_distance() or has_explosives_or_hammer() or can_use_din() or can_use_sticks()) end,
            ["Ice Cavern Pot Red Ice 2"] = function () return soul_wolfos() and has_blue_fire() and (has_weapon() or can_hit_triggers_distance() or has_explosives_or_hammer() or can_use_din() or can_use_sticks()) end,
        },
    },
    ["Jabu-Jabu"] = {
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
            ["Jabu-Jabu Main"] = function () return has_ranged_weapon() or has_explosives() end,
        },
    },
    ["Jabu-Jabu Main"] = {
        ["events"] = {
            ["BIG_OCTO"] = function () return soul_octorok() and event('PARASITE') and soul_ruto() and (has_weapon() or can_use_sticks()) end,
            ["PARASITE"] = function () return soul_enemy(SOUL_ENEMY_PARASITE) and can_boomerang() and (soul_ruto() or can_play_elegy()) end,
        },
        ["exits"] = {
            ["Jabu-Jabu"] = function () return true end,
            ["Jabu-Jabu Pre-Boss"] = function () return event('BIG_OCTO') or (has_hover_boots() and (trick('OOT_JABU_BOSS_HOVER') or can_play_elegy())) or climb_anywhere() or (glitch_megaflip() and (trick('OOT_JJB_BOXLESS') and can_jump_slash() or can_play_elegy())) end,
        },
        ["locations"] = {
            ["Jabu-Jabu Map Chest"] = function () return event('PARASITE') end,
            ["Jabu-Jabu Compass Chest"] = function () return event('PARASITE') and soul_enemy(SOUL_ENEMY_SHABOM) end,
            ["Jabu-Jabu Boomerang Chest"] = function () return soul_enemy(SOUL_ENEMY_STINGER) and soul_ruto() end,
            ["Jabu-Jabu GS Bottom Lower"] = function () return gs() and (can_collect_distance() or climb_anywhere()) end,
            ["Jabu-Jabu GS Bottom Upper"] = function () return gs() and (can_collect_distance() or climb_anywhere()) end,
            ["Jabu-Jabu GS Water Switch"] = function () return gs() end,
            ["Jabu-Jabu Scrub"] = function () return (is_child() or can_dive_small() or time_travel_at_will()) and business_scrub(32) end,
            ["Jabu-Jabu Pot Big Octo Room 1"] = function () return event('BIG_OCTO') or climb_anywhere() end,
            ["Jabu-Jabu Pot Big Octo Room 2"] = function () return event('BIG_OCTO') or climb_anywhere() end,
            ["Jabu-Jabu Pot Big Octo Room 3"] = function () return event('BIG_OCTO') or climb_anywhere() end,
            ["Jabu-Jabu Pot Muscle Block Room 1"] = function () return can_boomerang() or climb_anywhere() end,
            ["Jabu-Jabu Pot Muscle Block Room 2"] = function () return can_boomerang() or climb_anywhere() end,
            ["Jabu-Jabu Pot Muscle Block Room 3"] = function () return can_boomerang() or climb_anywhere() end,
            ["Jabu-Jabu Pot Muscle Block Room 4"] = function () return can_boomerang() or climb_anywhere() end,
            ["Jabu-Jabu Pot Muscle Block Room 5"] = function () return can_boomerang() or climb_anywhere() end,
            ["Jabu-Jabu Pot Alcove 1"] = function () return true end,
            ["Jabu-Jabu Pot Alcove 2"] = function () return true end,
            ["Jabu-Jabu Pot Alcove 3"] = function () return true end,
        },
    },
    ["Jabu-Jabu Pre-Boss"] = {
        ["exits"] = {
            ["Jabu-Jabu Boss"] = function () return can_boomerang() or (trick('OOT_JABU_BOSS_HIGH_SWITCH') and (has_hover_boots() and has_bombs() or can_hit_triggers_distance() or can_longshot() or has_bombchu())) or (climb_anywhere() and (has_weapon() or can_use_sticks() or has_ranged_weapon() or has_explosives_or_hammer())) end,
            ["Jabu-Jabu Main"] = function () return true end,
        },
        ["locations"] = {
            ["Jabu-Jabu GS Near Boss"] = function () return gs() end,
        },
    },
    ["VOID"] = {
    },
    ["SPAWN"] = {
        ["exits"] = {
            ["SPAWN CHILD"] = function () return is_child() and (setting('startingAge', 'child') or event('TIME_TRAVEL')) end,
            ["SPAWN ADULT"] = function () return is_adult() and (setting('startingAge', 'adult') or event('TIME_TRAVEL')) end,
        },
    },
    ["SPAWN CHILD"] = {
        ["exits"] = {
            ["GLOBAL"] = function () return true end,
            ["Link's House"] = function () return true end,
        },
    },
    ["SPAWN ADULT"] = {
        ["exits"] = {
            ["GLOBAL"] = function () return true end,
            ["Temple of Time"] = function () return true end,
        },
    },
    ["GLOBAL"] = {
        ["exits"] = {
            ["SONG_TP_FOREST"] = function () return can_play_tp_forest() end,
            ["SONG_TP_FIRE"] = function () return can_play_tp_fire() end,
            ["SONG_TP_WATER"] = function () return can_play_tp_water() end,
            ["SONG_TP_SHADOW"] = function () return can_play_tp_shadow() end,
            ["SONG_TP_SPIRIT"] = function () return can_play_tp_spirit() end,
            ["SONG_TP_LIGHT"] = function () return can_play_tp_light() end,
            ["MM SOARING"] = function () return can_play_cross_soaring() end,
            ["EGGS"] = function () return true end,
        },
    },
    ["SONG_TP_FOREST"] = {
        ["exits"] = {
            ["Sacred Meadow"] = function () return true end,
        },
    },
    ["SONG_TP_FIRE"] = {
        ["exits"] = {
            ["Death Mountain Crater Warp"] = function () return true end,
        },
    },
    ["SONG_TP_WATER"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
    },
    ["SONG_TP_SHADOW"] = {
        ["exits"] = {
            ["Graveyard Upper"] = function () return true end,
        },
    },
    ["SONG_TP_SPIRIT"] = {
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
    },
    ["SONG_TP_LIGHT"] = {
        ["exits"] = {
            ["Temple of Time"] = function () return true end,
        },
    },
    ["EGGS"] = {
        ["locations"] = {
            ["Hatch Chicken"] = function () return age_child_trade() and has('WEIRD_EGG') end,
            ["Hatch Pocket Cucco"] = function () return is_adult() and has('POCKET_EGG') end,
        },
    },
    ["Link's House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Kokiri Forest Cow"] = function () return is_adult() and event('MALON_COW') and can_play_epona() end,
            ["Link's House Pot"] = function () return true end,
        },
    },
    ["Kokiri Forest"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return true end,
            ["MIDO_MOVED"] = function () return can_move_mido() end,
            ["BEAN_KOKIRI_FOREST"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Kokiri Forest Grass"] = function () return can_cut_grass() end,
            ["Link's House"] = function () return true end,
            ["Mido's House"] = function () return true end,
            ["Saria's House"] = function () return true end,
            ["House of Twins"] = function () return true end,
            ["Know It All House"] = function () return true end,
            ["Lost Woods"] = function () return true end,
            ["Lost Woods Bridge from Forest"] = function () return true end,
            ["Kokiri Shop"] = function () return true end,
            ["Kokiri Forest Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Kokiri Forest Near Deku Tree"] = function () return can_bypass_mido() end,
            ["Kokiri Forest Adult Rupees"] = function () return can_ride_bean(BEAN_KOKIRI_FOREST) or (is_adult() and (has_hover_boots() or hookshot_anywhere() or climb_anywhere())) end,
        },
        ["locations"] = {
            ["Kokiri Forest Kokiri Sword Chest"] = function () return is_child() end,
            ["Kokiri Forest GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Kokiri Forest GS Night Child"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Kokiri Forest GS Night Adult"] = function () return is_adult() and (can_collect_distance() or climb_anywhere()) and gs_night() end,
            ["Kokiri Forest Rupee Child 1"] = function () return is_child() end,
            ["Kokiri Forest Rupee Child 2"] = function () return is_child() end,
            ["Kokiri Forest Rupee Crawl 1"] = function () return is_child() end,
            ["Kokiri Forest Rupee Crawl 2"] = function () return is_child() end,
            ["Kokiri Forest Heart 1"] = function () return is_child() end,
            ["Kokiri Forest Heart 2"] = function () return is_child() end,
            ["Kokiri Forest Heart 3"] = function () return is_child() end,
        },
    },
    ["Kokiri Forest Grass"] = {
        ["exits"] = {
            ["Kokiri Forest Grass Child"] = function () return is_child() end,
            ["Kokiri Forest Grass Adult"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Kokiri Forest Grass 1"] = function () return true end,
            ["Kokiri Forest Grass 2"] = function () return true end,
            ["Kokiri Forest Grass 3"] = function () return true end,
            ["Kokiri Forest Grass 4"] = function () return true end,
            ["Kokiri Forest Grass 5"] = function () return true end,
            ["Kokiri Forest Grass 6"] = function () return true end,
            ["Kokiri Forest Grass 7"] = function () return true end,
            ["Kokiri Forest Grass 8"] = function () return true end,
        },
    },
    ["Kokiri Forest Grass Child"] = {
        ["locations"] = {
            ["Kokiri Forest Grass Child 1"] = function () return true end,
            ["Kokiri Forest Grass Child 2"] = function () return true end,
            ["Kokiri Forest Grass Child 3"] = function () return true end,
            ["Kokiri Forest Grass Child 4"] = function () return true end,
            ["Kokiri Forest Grass Child Kokiri"] = function () return true end,
            ["Kokiri Forest Grass Child Crawl 1"] = function () return true end,
            ["Kokiri Forest Grass Child Crawl 2"] = function () return true end,
            ["Kokiri Forest Grass Child Crawl 3"] = function () return true end,
        },
    },
    ["Kokiri Forest Grass Adult"] = {
        ["locations"] = {
            ["Kokiri Forest Grass Adult 01"] = function () return true end,
            ["Kokiri Forest Grass Adult 02"] = function () return true end,
            ["Kokiri Forest Grass Adult 03"] = function () return true end,
            ["Kokiri Forest Grass Adult 04"] = function () return true end,
            ["Kokiri Forest Grass Adult 05"] = function () return true end,
            ["Kokiri Forest Grass Adult 06"] = function () return true end,
            ["Kokiri Forest Grass Adult 07"] = function () return true end,
            ["Kokiri Forest Grass Adult 08"] = function () return true end,
            ["Kokiri Forest Grass Adult 09"] = function () return true end,
            ["Kokiri Forest Grass Adult 10"] = function () return true end,
            ["Kokiri Forest Grass Adult 11"] = function () return true end,
            ["Kokiri Forest Grass Adult 12"] = function () return true end,
        },
    },
    ["Kokiri Forest Adult Rupees"] = {
        ["locations"] = {
            ["Kokiri Forest Rupee Adult 1"] = function () return true end,
            ["Kokiri Forest Rupee Adult 2"] = function () return true end,
            ["Kokiri Forest Rupee Adult 3"] = function () return true end,
            ["Kokiri Forest Rupee Adult 4"] = function () return true end,
            ["Kokiri Forest Rupee Adult 5"] = function () return true end,
            ["Kokiri Forest Rupee Adult 6"] = function () return true end,
            ["Kokiri Forest Rupee Adult 7"] = function () return true end,
        },
    },
    ["Kokiri Forest Near Deku Tree"] = {
        ["events"] = {
            ["STICKS"] = function () return is_child() and soul_deku_baba() and (can_boomerang() or has_weapon()) end,
            ["MIDO_MOVED"] = function () return can_move_mido() end,
        },
        ["exits"] = {
            ["Kokiri Forest"] = function () return can_bypass_mido() end,
            ["Deku Tree"] = function () return (setting('dekuTree', 'open') or (is_child() and setting('dekuTree', 'vanilla')) or event('MIDO_MOVED')) and (is_child() or setting('dekuTreeAdult')) end,
        },
    },
    ["Kokiri Shop"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
            ["Kokiri Shop Items"] = function () return soul_npc(SOUL_NPC_KOKIRI_SHOPKEEPER) end,
        },
    },
    ["Kokiri Shop Items"] = {
        ["locations"] = {
            ["Kokiri Shop Item 1"] = function () return shop_price(0) end,
            ["Kokiri Shop Item 2"] = function () return shop_price(1) end,
            ["Kokiri Shop Item 3"] = function () return shop_price(2) end,
            ["Kokiri Shop Item 4"] = function () return shop_price(3) end,
            ["Kokiri Shop Item 5"] = function () return shop_price(4) end,
            ["Kokiri Shop Item 6"] = function () return shop_price(5) end,
            ["Kokiri Shop Item 7"] = function () return shop_price(6) end,
            ["Kokiri Shop Item 8"] = function () return shop_price(7) end,
        },
    },
    ["Mido's House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Mido's House Top Left"] = function () return true end,
            ["Mido's House Top Right"] = function () return true end,
            ["Mido's House Bottom Left"] = function () return true end,
            ["Mido's House Bottom Right"] = function () return true end,
        },
    },
    ["Saria's House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Saria's House Heart 1"] = function () return true end,
            ["Saria's House Heart 2"] = function () return true end,
            ["Saria's House Heart 3"] = function () return true end,
            ["Saria's House Heart 4"] = function () return true end,
        },
    },
    ["House of Twins"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Twins House Pot 1"] = function () return true end,
            ["Twins House Pot 2"] = function () return true end,
        },
    },
    ["Know It All House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Know It All House Pot 1"] = function () return true end,
            ["Know It All House Pot 2"] = function () return true end,
        },
    },
    ["Kokiri Forest Storms Grotto"] = {
        ["events"] = {
            ["FISH"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
            ["Kokiri Forest Storms Grotto Grass"] = function () return can_cut_grass() end,
        },
        ["locations"] = {
            ["Kokiri Forest Storms Grotto"] = function () return true end,
        },
    },
    ["Kokiri Forest Storms Grotto Grass"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return true end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["locations"] = {
            ["Kokiri Forest Storms Grotto Grass 1"] = function () return true end,
            ["Kokiri Forest Storms Grotto Grass 2"] = function () return true end,
            ["Kokiri Forest Storms Grotto Grass 3"] = function () return true end,
            ["Kokiri Forest Storms Grotto Grass 4"] = function () return true end,
        },
    },
    ["Hyrule Field"] = {
        ["events"] = {
            ["BIG_POE"] = function () return can_ride_epona() and can_use_bow() and has_bottle() end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Lost Woods Bridge"] = function () return true end,
            ["Market Entryway"] = function () return true end,
            ["Kakariko"] = function () return true end,
            ["Zora River Front"] = function () return true end,
            ["Lake Hylia"] = function () return true end,
            ["Gerudo Valley"] = function () return true end,
            ["Lon Lon Ranch"] = function () return true end,
            ["Hyrule Field Grass"] = function () return can_cut_grass() end,
            ["Hyrule Field Scrub Grotto"] = function () return hidden_grotto_bomb() end,
            ["Hyrule Field Open Grotto"] = function () return true end,
            ["Hyrule Field Southeast Grotto"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Field Grotto Near Market"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Field Tektite Grotto"] = function () return hidden_grotto_bomb() end,
            ["Hyrule Field Grotto Near GV"] = function () return is_child() and hidden_grotto_bomb() or (can_hammer() and stone_of_agony()) end,
            ["Hyrule Field Grotto Near Kak"] = function () return hidden_grotto_bomb() end,
            ["Hyrule Field Fairy Grotto"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Hyrule Field Ocarina of Time"] = function () return is_child() and has_spiritual_stones() end,
            ["Hyrule Field Song of Time"] = function () return is_child() and has_spiritual_stones() end,
            ["Hyrule Field River Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Hyrule Field Grass"] = {
        ["locations"] = {
            ["Hyrule Field Grass Pack 1 Bush 01"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 02"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 03"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 04"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 05"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 06"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 07"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 08"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 09"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 10"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 11"] = function () return true end,
            ["Hyrule Field Grass Pack 1 Bush 12"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 01"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 02"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 03"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 04"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 05"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 06"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 07"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 08"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 09"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 10"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 11"] = function () return true end,
            ["Hyrule Field Grass Pack 2 Bush 12"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 01"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 02"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 03"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 04"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 05"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 06"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 07"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 08"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 09"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 10"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 11"] = function () return true end,
            ["Hyrule Field Grass Pack 3 Bush 12"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 01"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 02"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 03"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 04"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 05"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 06"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 07"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 08"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 09"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 10"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 11"] = function () return true end,
            ["Hyrule Field Grass Pack 4 Bush 12"] = function () return true end,
        },
    },
    ["Hyrule Field Drawbridge"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
    },
    ["Hyrule Field Scrub Grotto"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Scrub HP"] = function () return business_scrub(7) end,
            ["Hyrule Field Grotto Scrub Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Hyrule Field Open Grotto"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Open"] = function () return true end,
            ["Hyrule Field Grotto Open Grass 1"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Open Grass 2"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Open Grass 3"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Open Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Hyrule Field Southeast Grotto"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Southeast"] = function () return true end,
            ["Hyrule Field Grotto Southeast Grass 1"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Southeast Grass 2"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Southeast Grass 3"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Southeast Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Hyrule Field Grotto Near Market"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Market"] = function () return true end,
            ["Hyrule Field Grotto Market Grass 1"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Market Grass 2"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Market Grass 3"] = function () return can_cut_grass() end,
            ["Hyrule Field Grotto Market Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Hyrule Field Tektite Grotto"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Tektite HP"] = function () return can_dive_big() end,
        },
    },
    ["Hyrule Field Grotto Near GV"] = {
        ["events"] = {
            ["NUTS"] = function () return has_fire() end,
            ["BUGS"] = function () return has_fire() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Near Gerudo GS"] = function () return gs() and (can_collect_distance() or climb_anywhere()) and has_fire() end,
            ["Hyrule Field Cow"] = function () return has_fire() and can_play_epona() end,
            ["Hyrule Field Cow Grotto Pot 1"] = function () return has_fire() end,
            ["Hyrule Field Cow Grotto Pot 2"] = function () return has_fire() end,
            ["Hyrule Field Grotto Near Gerudo Grass 1"] = function () return has_fire() and can_cut_grass() end,
            ["Hyrule Field Grotto Near Gerudo Grass 2"] = function () return has_fire() and can_cut_grass() end,
        },
    },
    ["Hyrule Field Grotto Near Kak"] = {
        ["events"] = {
            ["SEEDS"] = function () return has_sword_kokiri() end,
            ["ARROWS"] = function () return is_adult() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Near Kakariko GS"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_din()))) end,
        },
    },
    ["Hyrule Field Fairy Grotto"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Fairy Fountain Fairy 1"] = function () return true end,
            ["Hyrule Field Fairy Fountain Fairy 2"] = function () return true end,
            ["Hyrule Field Fairy Fountain Fairy 3"] = function () return true end,
            ["Hyrule Field Fairy Fountain Fairy 4"] = function () return true end,
            ["Hyrule Field Fairy Fountain Fairy 5"] = function () return true end,
            ["Hyrule Field Fairy Fountain Fairy 6"] = function () return true end,
            ["Hyrule Field Fairy Fountain Fairy 7"] = function () return true end,
            ["Hyrule Field Fairy Fountain Fairy 8"] = function () return true end,
        },
    },
    ["Market Entryway"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return is_day() or is_adult() end,
            ["Market"] = function () return true end,
            ["Market Pot House"] = function () return true end,
        },
    },
    ["Market"] = {
        ["events"] = {
            ["RICHARD"] = function () return is_night() and is_child() end,
            ["RUPEES"] = function () return is_child() end,
        },
        ["exits"] = {
            ["Market Entryway"] = function () return true end,
            ["Market Grass"] = function () return is_child() and can_cut_grass_no_c_button() end,
            ["Back Alley"] = function () return is_child() end,
            ["Market Castle Entry"] = function () return true end,
            ["Temple of Time Entryway"] = function () return true end,
            ["Bombchu Bowling"] = function () return is_child() end,
            ["Treasure Chest Game"] = function () return is_night() and is_child() end,
            ["Shooting Gallery Child"] = function () return is_day() and is_child() end,
            ["Market Bazaar"] = function () return is_day() and is_child() end,
            ["Market Potion Shop"] = function () return is_day() and is_child() end,
            ["MM Clock Town"] = function () return is_child() and (is_day() or setting('openMaskShop')) end,
        },
    },
    ["Market Grass"] = {
        ["locations"] = {
            ["Market Grass 1"] = function () return true end,
            ["Market Grass 2"] = function () return true end,
            ["Market Grass 3"] = function () return true end,
            ["Market Grass 4"] = function () return true end,
            ["Market Grass 5"] = function () return true end,
            ["Market Grass 6"] = function () return true end,
            ["Market Grass 7"] = function () return true end,
            ["Market Grass 8"] = function () return true end,
        },
    },
    ["Market Castle Entry"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Hyrule Castle"] = function () return is_child() end,
            ["Ganon Castle Exterior"] = function () return is_adult() end,
        },
    },
    ["Market Bazaar"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Market Bazaar Items"] = function () return soul_bazaar_shopkeeper() end,
        },
    },
    ["Market Bazaar Items"] = {
        ["locations"] = {
            ["Market Bazaar Item 1"] = function () return shop_price(32) end,
            ["Market Bazaar Item 2"] = function () return shop_price(33) end,
            ["Market Bazaar Item 3"] = function () return shop_price(34) end,
            ["Market Bazaar Item 4"] = function () return shop_price(35) end,
            ["Market Bazaar Item 5"] = function () return shop_price(36) end,
            ["Market Bazaar Item 6"] = function () return shop_price(37) end,
            ["Market Bazaar Item 7"] = function () return shop_price(38) end,
            ["Market Bazaar Item 8"] = function () return shop_price(39) end,
        },
    },
    ["Market Potion Shop"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Market Potion Shop Items"] = function () return soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
        },
    },
    ["Market Potion Shop Items"] = {
        ["locations"] = {
            ["Market Potion Shop Item 1"] = function () return shop_price(40) end,
            ["Market Potion Shop Item 2"] = function () return shop_price(41) end,
            ["Market Potion Shop Item 3"] = function () return shop_price(42) end,
            ["Market Potion Shop Item 4"] = function () return shop_price(43) end,
            ["Market Potion Shop Item 5"] = function () return shop_price(44) end,
            ["Market Potion Shop Item 6"] = function () return shop_price(45) end,
            ["Market Potion Shop Item 7"] = function () return shop_price(46) end,
            ["Market Potion Shop Item 8"] = function () return shop_price(47) end,
        },
    },
    ["Market Bombchu Shop"] = {
        ["exits"] = {
            ["Back Alley"] = function () return true end,
            ["Market Bombchu Shop Items"] = function () return soul_bombchu_shopkeeper() end,
        },
    },
    ["Market Bombchu Shop Items"] = {
        ["locations"] = {
            ["Market Bombchu Shop Item 1"] = function () return shop_price(8) end,
            ["Market Bombchu Shop Item 2"] = function () return shop_price(9) end,
            ["Market Bombchu Shop Item 3"] = function () return shop_price(10) end,
            ["Market Bombchu Shop Item 4"] = function () return shop_price(11) end,
            ["Market Bombchu Shop Item 5"] = function () return shop_price(12) end,
            ["Market Bombchu Shop Item 6"] = function () return shop_price(13) end,
            ["Market Bombchu Shop Item 7"] = function () return shop_price(14) end,
            ["Market Bombchu Shop Item 8"] = function () return shop_price(15) end,
        },
    },
    ["Market Pot House"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Market Entryway"] = function () return true end,
            ["Market Pot House Child"] = function () return is_child() end,
            ["Market Pot House Adult"] = function () return is_adult() end,
        },
    },
    ["Market Pot House Child"] = {
        ["locations"] = {
            ["Market Pot House GS"] = function () return gs() end,
            ["Market Pot House Child Pot Ground 1"] = function () return true end,
            ["Market Pot House Child Pot Ground 2"] = function () return true end,
            ["Market Pot House Child Pot Ground 3"] = function () return true end,
            ["Market Pot House Child Pot Ground 4"] = function () return true end,
            ["Market Pot House Child Pot Ground 5"] = function () return true end,
            ["Market Pot House Child Pot Ground 6"] = function () return true end,
            ["Market Pot House Child Pot Ground 7"] = function () return true end,
            ["Market Pot House Child Pot Ground 8"] = function () return true end,
            ["Market Pot House Child Pot Ground 9"] = function () return true end,
            ["Market Pot House Child Pot Ground 10"] = function () return true end,
            ["Market Pot House Child Pot Ground 11"] = function () return true end,
            ["Market Pot House Child Pot Ground 12"] = function () return true end,
            ["Market Pot House Child Pot Ground 13"] = function () return true end,
            ["Market Pot House Child Pot Ground 14"] = function () return true end,
            ["Market Pot House Child Pot Ground 15"] = function () return true end,
            ["Market Pot House Child Pot Ground 16"] = function () return true end,
            ["Market Pot House Child Pot Ground 17"] = function () return true end,
            ["Market Pot House Child Pot Ground 18"] = function () return true end,
            ["Market Pot House Child Pot Ground 19"] = function () return true end,
            ["Market Pot House Child Pot Ground 20"] = function () return true end,
            ["Market Pot House Child Pot Ground 21"] = function () return true end,
            ["Market Pot House Child Pot Ground 22"] = function () return true end,
            ["Market Pot House Child Pot Ground 23"] = function () return true end,
            ["Market Pot House Child Pot Ground 24"] = function () return true end,
            ["Market Pot House Child Pot Ground 25"] = function () return true end,
            ["Market Pot House Child Pot Ground 26"] = function () return true end,
            ["Market Pot House Child Pot Ground 27"] = function () return true end,
            ["Market Pot House Child Pot Ground 28"] = function () return true end,
            ["Market Pot House Child Pot Ground 29"] = function () return true end,
            ["Market Pot House Child Pot Ground 30"] = function () return true end,
            ["Market Pot House Child Pot Ground 31"] = function () return true end,
            ["Market Pot House Child Pot Ground 32"] = function () return true end,
            ["Market Pot House Child Pot Ground 33"] = function () return true end,
            ["Market Pot House Child Pot Ground 34"] = function () return true end,
            ["Market Pot House Child Pot Ground 35"] = function () return true end,
            ["Market Pot House Child Pot Ground 36"] = function () return true end,
            ["Market Pot House Child Pot Ground 37"] = function () return true end,
            ["Market Pot House Child Pot Ground 38"] = function () return true end,
            ["Market Pot House Child Pot Ground 39"] = function () return true end,
            ["Market Pot House Child Pot Ground 40"] = function () return true end,
            ["Market Pot House Child Pot Ground 41"] = function () return true end,
            ["Market Pot House Child Pot Ground 42"] = function () return true end,
            ["Market Pot House Child Pot Above 1"] = function () return true end,
            ["Market Pot House Child Pot Above 2"] = function () return true end,
        },
    },
    ["Market Pot House Adult"] = {
        ["locations"] = {
            ["Market Pot House Big Poes"] = function () return has_big_poe() and soul_poe_collector() end,
            ["Market Pot House Adult Pot 1"] = function () return true end,
            ["Market Pot House Adult Pot 2"] = function () return true end,
            ["Market Pot House Adult Pot 3"] = function () return true end,
            ["Market Pot House Adult Pot 4"] = function () return true end,
            ["Market Pot House Adult Pot 5"] = function () return true end,
            ["Market Pot House Adult Pot 6"] = function () return true end,
            ["Market Pot House Adult Pot 7"] = function () return true end,
            ["Market Pot House Adult Pot 8"] = function () return true end,
            ["Market Pot House Adult Pot 9"] = function () return true end,
            ["Market Pot House Adult Pot 10"] = function () return true end,
            ["Market Pot House Adult Pot 11"] = function () return true end,
        },
    },
    ["Back Alley"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Dog Lady House"] = function () return true end,
            ["Market Bombchu Shop"] = function () return is_night() end,
            ["Market Back Alley East Home"] = function () return is_night() end,
        },
    },
    ["Dog Lady House"] = {
        ["exits"] = {
            ["Back Alley"] = function () return true end,
        },
        ["locations"] = {
            ["Market Dog Lady HP"] = function () return event('RICHARD') and is_night() and soul_dog_lady() end,
        },
    },
    ["Market Back Alley East Home"] = {
        ["exits"] = {
            ["Back Alley"] = function () return true end,
        },
        ["locations"] = {
            ["Market Back Alley East House Pot 1"] = function () return true end,
            ["Market Back Alley East House Pot 2"] = function () return true end,
            ["Market Back Alley East House Pot 3"] = function () return true end,
        },
    },
    ["Bombchu Bowling"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Bombchu Bowling Rewards"] = function () return (has_bomb_bag() or has_bombchu_license()) and can_use_wallet(1) and soul_bombchu_bowling_lady() end,
        },
    },
    ["Bombchu Bowling Rewards"] = {
        ["events"] = {
            ["BOMBCHU"] = function () return true end,
            ["BOMBS"] = function () return can_use_wallet(2) end,
        },
        ["locations"] = {
            ["Bombchu Bowling Reward 1"] = function () return true end,
            ["Bombchu Bowling Reward 2"] = function () return true end,
        },
    },
    ["Shooting Gallery Child"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
        },
        ["locations"] = {
            ["Shooting Gallery Child"] = function () return is_child() and can_use_wallet(1) and soul_shooting_gallery_owner() end,
        },
    },
    ["Temple of Time Entryway"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Temple of Time"] = function () return true end,
        },
    },
    ["Lon Lon Ranch"] = {
        ["events"] = {
            ["EPONA"] = function () return true end,
            ["MALON_COW"] = function () return can_ride_epona() and event('EPONA') and is_day() and soul_malon() end,
            ["RUPEES"] = function () return is_child() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Lon Lon Ranch Pots"] = function () return is_child() end,
            ["Lon Lon Ranch Silo"] = function () return true end,
            ["Lon Lon Ranch Stables"] = function () return true end,
            ["Lon Lon Ranch House"] = function () return is_day() end,
            ["Lon Lon Ranch Grotto"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Malon Song"] = function () return is_child() and has_ocarina() and event('MALON') and is_day() end,
            ["Lon Lon Ranch GS Tree"] = function () return gs() and is_child() end,
            ["Lon Lon Ranch GS House"] = function () return is_child() and gs_night() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_sword() or can_use_sticks() or can_use_din()))) end,
            ["Lon Lon Ranch GS Rain Shed"] = function () return is_child() and gs_night() end,
            ["Lon Lon Ranch GS Back Wall"] = function () return is_child() and gs_night() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_din()))) end,
        },
    },
    ["Lon Lon Ranch Pots"] = {
        ["locations"] = {
            ["Lon Lon Ranch Pot 1"] = function () return true end,
            ["Lon Lon Ranch Pot 2"] = function () return true end,
            ["Lon Lon Ranch Pot 3"] = function () return true end,
            ["Lon Lon Ranch Pot 4"] = function () return true end,
            ["Lon Lon Ranch Pot 5"] = function () return true end,
            ["Lon Lon Ranch Pot 6"] = function () return true end,
            ["Lon Lon Ranch Pot 7"] = function () return true end,
        },
    },
    ["Lon Lon Ranch Stables"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Stables Cow Left"] = function () return can_play_epona() end,
            ["Lon Lon Ranch Stables Cow Right"] = function () return can_play_epona() end,
        },
    },
    ["Lon Lon Ranch Silo"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Silo HP"] = function () return is_child() end,
            ["Lon Lon Ranch Silo Cow Front"] = function () return can_play_epona() end,
            ["Lon Lon Ranch Silo Cow Back"] = function () return can_play_epona() end,
        },
    },
    ["Lon Lon Ranch House"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Talon Bottle"] = function () return is_child() and woke_talon_child() and can_use_wallet(1) and is_day() and soul_talon() end,
            ["Lon Lon Ranch Talon House Pot 1"] = function () return true end,
            ["Lon Lon Ranch Talon House Pot 2"] = function () return true end,
            ["Lon Lon Ranch Talon House Pot 3"] = function () return true end,
        },
    },
    ["Lon Lon Ranch Grotto"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Grotto Left Scrub"] = function () return is_child() and business_scrub(8) end,
            ["Lon Lon Ranch Grotto Center Scrub"] = function () return is_child() and business_scrub(9) end,
            ["Lon Lon Ranch Grotto Right Scrub"] = function () return is_child() and business_scrub(10) end,
        },
    },
    ["Hyrule Castle"] = {
        ["events"] = {
            ["MALON"] = function () return soul_malon() end,
            ["TALON_CHILD"] = function () return has('CHICKEN') and soul_talon() end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["MAGIC"] = function () return true end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Market Castle Entry"] = function () return true end,
            ["Near Fairy Fountain Din"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Castle Courtyard"] = function () return woke_talon_child() or (has_hover_boots() and (soul_talon() or setting('skipZelda'))) or climb_anywhere() or hookshot_anywhere() end,
            ["Hyrule Castle Near Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Malon Egg"] = function () return event('MALON') end,
            ["Hyrule Castle GS Tree"] = function () return gs() and can_damage_skull() end,
            ["Hyrule Castle Grass 1"] = function () return can_cut_grass() end,
            ["Hyrule Castle Grass 2"] = function () return can_cut_grass() end,
            ["Hyrule Castle Pot 1"] = function () return true end,
            ["Hyrule Castle Pot 2"] = function () return true end,
        },
    },
    ["Hyrule Castle Near Grotto"] = {
        ["exits"] = {
            ["Hyrule Castle"] = function () return is_child() end,
            ["Hyrule Castle Grotto"] = function () return is_child() and hidden_grotto_storms() end,
            ["Ganon Castle Exterior"] = function () return is_adult() end,
        },
    },
    ["Hyrule Castle Courtyard"] = {
        ["events"] = {
            ["MEET_ZELDA"] = function () return soul_npc(SOUL_NPC_ZELDA) end,
        },
        ["exits"] = {
            ["Hyrule Castle"] = function () return true end,
        },
        ["locations"] = {
            ["Zelda's Letter"] = function () return met_zelda() end,
            ["Zelda's Song"] = function () return met_zelda() end,
        },
    },
    ["Near Fairy Fountain Din"] = {
        ["exits"] = {
            ["Hyrule Castle"] = function () return is_child() end,
            ["Fairy Fountain Din"] = function () return is_child() and has_explosives_or_hammer() end,
            ["Near Fairy Fountain Defense"] = function () return is_adult() end,
        },
    },
    ["Fairy Fountain Din"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Near Fairy Fountain Din"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Din's Fire"] = function () return can_play_zelda() end,
        },
    },
    ["Hyrule Castle Grotto"] = {
        ["events"] = {
            ["RUPEES"] = function () return has_explosives_or_hammer() end,
            ["NUTS"] = function () return has_explosives_or_hammer() end,
            ["SEEDS"] = function () return has_explosives_or_hammer() and is_child() end,
            ["ARROWS"] = function () return has_explosives_or_hammer() and is_adult() end,
            ["BOMBS_OR_BOMBCHU"] = function () return can_hammer() end,
            ["BUGS"] = function () return has_explosives_or_hammer() and has_bottle() end,
        },
        ["exits"] = {
            ["Hyrule Castle Near Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Castle GS Grotto"] = function () return gs() and has_explosives_or_hammer() and can_collect_distance() end,
            ["Hyrule Castle Grotto Pot 1"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Castle Grotto Pot 2"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Castle Grotto Pot 3"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Castle Grotto Pot 4"] = function () return has_explosives_or_hammer() end,
        },
    },
    ["Ganon Castle Exterior"] = {
        ["exits"] = {
            ["Market Castle Entry"] = function () return true end,
            ["Ganon Castle Exterior After Bridge"] = function () return rainbow_bridge() or (longshot_anywhere() and trick('OOT_GANON_CASTLE_ENTRY')) end,
            ["Near Fairy Fountain Defense"] = function () return can_lift_gold() end,
        },
        ["locations"] = {
            ["Ganon Castle Exterior GS"] = function () return gs() end,
        },
    },
    ["Ganon Castle Exterior After Bridge"] = {
        ["exits"] = {
            ["Ganon Castle Exterior"] = function () return is_adult() and rainbow_bridge() end,
            ["Hyrule Castle Courtyard"] = function () return is_child() and trick('OOT_COURTYARD_FROM_GANON') end,
            ["Ganon Castle"] = function () return true end,
        },
    },
    ["Near Fairy Fountain Defense"] = {
        ["exits"] = {
            ["Ganon Castle Exterior"] = function () return is_adult() end,
            ["Fairy Fountain Defense"] = function () return is_adult() and (can_lift_gold() or (not setting('erIndoorsMajor') and trick('OOT_GANON_FAIRY_TT'))) end,
            ["Near Fairy Fountain Din"] = function () return is_child() end,
        },
    },
    ["Fairy Fountain Defense"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Near Fairy Fountain Defense"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Defense Upgrade"] = function () return can_play_zelda() end,
        },
    },
    ["Lost Woods Lost North"] = {
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
        },
    },
    ["Lost Woods Lost East"] = {
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
        },
    },
    ["Lost Woods Lost South"] = {
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
        },
    },
    ["Lost Woods Lost West"] = {
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
        },
    },
    ["Lost Woods"] = {
        ["events"] = {
            ["BEAN_LOST_WOODS_EARLY"] = function () return can_use_beans() end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
            ["Lost Woods Bridge"] = function () return can_longshot() or has_hover_boots() or can_ride_bean(BEAN_LOST_WOODS_EARLY) or climb_anywhere() or hookshot_anywhere() end,
            ["Lost Woods Deep"] = function () return is_child() or can_play_saria() or trick_mido() or hookshot_anywhere() or climb_anywhere() end,
            ["Lost Woods Generic Grotto"] = function () return has_explosives_or_hammer() end,
            ["Goron City Shortcut"] = function () return true end,
            ["Zora River"] = function () return can_dive_small() or hookshot_anywhere() end,
            ["Lost Woods Rupee Arrow"] = function () return is_child() and (can_dive_small() or hookshot_anywhere() or can_boomerang()) end,
            ["Lost Woods Lost North"] = function () return true end,
            ["Lost Woods Lost South"] = function () return true end,
            ["Lost Woods Lost West"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Target"] = function () return can_use_slingshot() end,
            ["Lost Woods Skull Kid"] = function () return is_child() and can_play_saria() end,
            ["Lost Woods Memory Game"] = function () return is_child() and can_play_minigame() end,
            ["Lost Woods Scrub Sticks Upgrade"] = function () return is_child() and business_scrub(0) end,
            ["Lost Woods Odd Mushroom"] = function () return soul_grog() and adult_trade(COJIRO) end,
            ["Lost Woods Poacher's Saw"] = function () return adult_trade(ODD_POTION) and soul_npc(SOUL_NPC_KOKIRI) end,
            ["Lost Woods GS Soil Bridge"] = function () return gs_soil() and can_damage_skull() end,
            ["Lost Woods Grass 1"] = function () return can_cut_grass() end,
            ["Lost Woods Grass 2"] = function () return can_cut_grass() end,
            ["Lost Woods Grass 3"] = function () return can_cut_grass() end,
            ["Lost Woods Pool Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Lost Woods Rupee Arrow"] = {
        ["locations"] = {
            ["Lost Woods Rupee Arrow 1"] = function () return true end,
            ["Lost Woods Rupee Arrow 2"] = function () return true end,
            ["Lost Woods Rupee Arrow 3"] = function () return true end,
            ["Lost Woods Rupee Arrow 4"] = function () return true end,
            ["Lost Woods Rupee Arrow 5"] = function () return true end,
            ["Lost Woods Rupee Arrow 6"] = function () return true end,
            ["Lost Woods Rupee Arrow 7"] = function () return true end,
            ["Lost Woods Rupee Arrow 8"] = function () return true end,
        },
    },
    ["Lost Woods Generic Grotto"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Grotto Generic"] = function () return true end,
            ["Lost Woods Grotto Generic Grass 1"] = function () return can_cut_grass() end,
            ["Lost Woods Grotto Generic Grass 2"] = function () return can_cut_grass() end,
            ["Lost Woods Grotto Generic Grass 3"] = function () return can_cut_grass() end,
            ["Lost Woods Grotto Generic Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Lost Woods Bridge"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
            ["Hyrule Field"] = function () return true end,
            ["Lost Woods"] = function () return can_longshot() or hookshot_anywhere() end,
        },
    },
    ["Lost Woods Bridge from Forest"] = {
        ["exits"] = {
            ["Lost Woods Bridge"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Gift from Saria"] = function () return soul_npc(SOUL_NPC_SARIA) end,
        },
    },
    ["Lost Woods Deep"] = {
        ["events"] = {
            ["BEAN_LOST_WOODS_LATE"] = function () return can_use_beans() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Lost Woods"] = function () return is_child() or can_play_saria() or (climb_anywhere() and has_hover_boots()) or hookshot_anywhere() end,
            ["Sacred Meadow Entryway"] = function () return true end,
            ["Deku Theater"] = function () return true end,
            ["Lost Woods Scrub Grotto"] = function () return has_explosives_or_hammer() end,
            ["Kokiri Forest"] = function () return not setting('alterLostWoodsExits') end,
            ["Lost Woods Lost North"] = function () return true end,
            ["Lost Woods Lost East"] = function () return true end,
            ["Lost Woods Lost South"] = function () return true end,
            ["Lost Woods Lost West"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Scrub Near Theater Left"] = function () return is_child() and business_scrub(1) end,
            ["Lost Woods Scrub Near Theater Right"] = function () return is_child() and business_scrub(2) end,
            ["Lost Woods GS Soil Theater"] = function () return gs_soil() and can_damage_skull() end,
            ["Lost Woods GS Bean Ride"] = function () return is_adult() and gs_night() and (can_ride_bean(BEAN_LOST_WOODS_LATE) or climb_anywhere() or hookshot_anywhere() or (trick('OOT_LOST_WOODS_ADULT_GS') and can_collect_distance() and (can_longshot() or can_use_bow() or has_bombchu() or can_use_din()))) end,
            ["Lost Woods Grass Deep 1"] = function () return can_cut_grass() end,
            ["Lost Woods Grass Deep 2"] = function () return can_cut_grass() end,
            ["Lost Woods Grass Deep 3"] = function () return can_cut_grass() end,
            ["Lost Woods Grass Deep 4"] = function () return can_cut_grass() end,
            ["Lost Woods Grass Deep 5"] = function () return can_cut_grass() end,
            ["Lost Woods Grass Deep 6"] = function () return can_cut_grass() end,
            ["Lost Woods Rupee Boulder"] = function () return has_explosives_or_hammer() end,
        },
    },
    ["Deku Theater"] = {
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Theater Sticks Upgrade"] = function () return age_child_trade() and has('MASK_SKULL') end,
            ["Deku Theater Nuts Upgrade"] = function () return age_child_trade() and has_mask_truth() end,
        },
    },
    ["Lost Woods Scrub Grotto"] = {
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Grotto Scrub Nuts Upgrade"] = function () return business_scrub(3) end,
            ["Lost Woods Grotto Scrub Back"] = function () return business_scrub(4) end,
            ["Lost Woods Grotto Scrub Big Fairy"] = function () return can_play_sun() end,
        },
    },
    ["Sacred Meadow Entryway"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
            ["Sacred Meadow"] = function () return is_child() and can_damage() and soul_wolfos() or is_adult() or climb_anywhere() or hookshot_anywhere() end,
            ["Wolfos Grotto"] = function () return hidden_grotto_bomb() end,
        },
    },
    ["Wolfos Grotto"] = {
        ["exits"] = {
            ["Sacred Meadow Entryway"] = function () return true end,
        },
        ["locations"] = {
            ["Sacred Meadow Grotto"] = function () return soul_wolfos() and can_damage() end,
        },
    },
    ["Sacred Meadow"] = {
        ["exits"] = {
            ["Sacred Meadow Entryway"] = function () return true end,
            ["Forest Temple"] = function () return can_hookshot() or (has_hookshot(1) and time_travel_at_will()) or climb_anywhere() end,
            ["Sacred Meadow Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Sacred Meadow Fairy Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Saria's Song"] = function () return met_zelda() and is_child() and soul_npc(SOUL_NPC_SARIA) end,
            ["Sacred Meadow Sheik Song"] = function () return is_adult() and soul_npc(SOUL_NPC_SHEIK) end,
            ["Sacred Meadow GS Night Adult"] = function () return is_adult() and gs_night() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_din()))) end,
        },
    },
    ["Sacred Meadow Storms Grotto"] = {
        ["exits"] = {
            ["Sacred Meadow"] = function () return true end,
        },
        ["locations"] = {
            ["Sacred Meadow Storms Grotto Front Scrub"] = function () return business_scrub(5) end,
            ["Sacred Meadow Storms Grotto Back Scrub"] = function () return business_scrub(6) end,
        },
    },
    ["Sacred Meadow Fairy Grotto"] = {
        ["exits"] = {
            ["Sacred Meadow"] = function () return true end,
        },
        ["locations"] = {
            ["Sacred Meadow Fairy Fountain Fairy 1"] = function () return true end,
            ["Sacred Meadow Fairy Fountain Fairy 2"] = function () return true end,
            ["Sacred Meadow Fairy Fountain Fairy 3"] = function () return true end,
            ["Sacred Meadow Fairy Fountain Fairy 4"] = function () return true end,
            ["Sacred Meadow Fairy Fountain Fairy 5"] = function () return true end,
            ["Sacred Meadow Fairy Fountain Fairy 6"] = function () return true end,
            ["Sacred Meadow Fairy Fountain Fairy 7"] = function () return true end,
            ["Sacred Meadow Fairy Fountain Fairy 8"] = function () return true end,
        },
    },
    ["Kakariko"] = {
        ["events"] = {
            ["KAKARIKO_GATE_OPEN"] = function () return is_child() and has('ZELDA_LETTER') and soul_npc(SOUL_NPC_HYLIAN_GUARD) end,
            ["BUGS"] = function () return has_bottle() end,
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Kakariko Trail Start"] = function () return setting('kakarikoGate', 'open') or event('KAKARIKO_GATE_OPEN') or is_adult() or climb_anywhere() or hookshot_anywhere() end,
            ["Graveyard"] = function () return true end,
            ["Bottom of the Well"] = function () return event('WELL_DRAIN') and cond(setting('wellAdult'), true, is_child()) or (is_child() and (has_iron_boots() or longshot_anywhere() or time_travel_at_will())) or (time_travel_at_will() and trick('OOT_WELL_ADULT_TT')) end,
            ["Skulltula House"] = function () return true end,
            ["Shooting Gallery Adult"] = function () return is_adult() and is_day() or (time_travel_at_will() and trick('OOT_ADULT_GALLERY_TT')) end,
            ["Kakariko Rooftop"] = function () return is_child() and is_day() or can_hookshot() or (is_adult() and trick('OOT_PASS_COLLISION')) or climb_anywhere() end,
            ["Kakariko Back"] = function () return can_hookshot() or has_hover_boots() or (is_day() and is_child()) or (trick('OOT_MAN_ON_ROOF') and (is_adult() or can_use_slingshot() or has_bombchu())) or climb_anywhere() end,
            ["Kakariko Bazaar"] = function () return is_adult() and is_day() end,
            ["Kakariko Potion Shop"] = function () return is_day() end,
            ["Windmill"] = function () return true end,
            ["Kakariko Carpenter House"] = function () return true end,
            ["Impa House Front"] = function () return true end,
            ["ReDead Grotto"] = function () return hidden_grotto_bomb() end,
        },
        ["locations"] = {
            ["Kakariko Anju Bottle"] = function () return is_child() and is_day() and soul_anju() end,
            ["Kakariko Anju Egg"] = function () return is_adult() and is_day() and soul_anju() end,
            ["Kakariko Anju Cojiro"] = function () return event('TALON_AWAKE') and is_day() and soul_anju() end,
            ["Kakariko Song Shadow"] = function () return is_adult() and soul_npc(SOUL_NPC_SHEIK) and has('MEDALLION_FOREST') and has('MEDALLION_FIRE') and has('MEDALLION_WATER') end,
            ["Kakariko Man on Roof"] = function () return (can_hookshot() or trick('OOT_MAN_ON_ROOF') or climb_anywhere()) and soul_rooftop_man() end,
            ["Kakariko GS Shooting Gallery"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Tree"] = function () return gs_night() and is_child() end,
            ["Kakariko GS House of Skulltula"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Bazaar"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Ladder"] = function () return gs_night() and is_child() and (can_use_slingshot() or has_bombchu() or can_longshot() or (climb_anywhere() and ((has_weapon() or can_use_sticks()) or can_use_din())) or (time_travel_at_will() and can_use_din())) end,
            ["Kakariko Pot 01"] = function () return is_child() end,
            ["Kakariko Pot 02"] = function () return is_child() end,
            ["Kakariko Pot 03"] = function () return is_child() end,
            ["Kakariko Pot 04"] = function () return is_child() end,
            ["Kakariko Pot 05"] = function () return is_child() end,
            ["Kakariko Pot 06"] = function () return is_child() end,
            ["Kakariko Pot 07"] = function () return is_child() end,
            ["Kakariko Pot 08"] = function () return is_child() end,
            ["Kakariko Pot 09"] = function () return is_child() end,
            ["Kakariko Pot 10"] = function () return is_child() end,
            ["Kakariko Pot 11"] = function () return is_child() end,
            ["Kakariko Grass 1"] = function () return can_cut_grass() end,
            ["Kakariko Grass 2"] = function () return can_cut_grass() end,
            ["Kakariko Grass 3"] = function () return can_cut_grass() end,
            ["Kakariko Grass 4"] = function () return can_cut_grass() end,
            ["Kakariko Grass 5"] = function () return can_cut_grass() end,
            ["Kakariko Grass 6"] = function () return can_cut_grass() end,
            ["Kakariko Grass 7"] = function () return can_cut_grass() end,
            ["Kakariko Grass 8"] = function () return can_cut_grass() end,
        },
    },
    ["Kakariko Rooftop"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Impa House Back"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko GS Roof"] = function () return is_adult() and gs_night() and (can_hookshot() or climb_anywhere()) end,
        },
    },
    ["Kakariko Trail Start"] = {
        ["exits"] = {
            ["Kakariko"] = function () return setting('kakarikoGate', 'open') or event('KAKARIKO_GATE_OPEN') or is_adult() or trick('OOT_PASS_COLLISION') or climb_anywhere() or hookshot_anywhere() end,
            ["Death Mountain"] = function () return true end,
        },
    },
    ["Kakariko Back"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Kakariko Potion Shop Back"] = function () return is_adult() and is_day() end,
            ["Kakariko Granny Shop"] = function () return is_adult() end,
            ["Kakariko Generic Grotto"] = function () return true end,
        },
    },
    ["Kakariko Bazaar"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Bazaar Item 1"] = function () return shop_price(48) and soul_bazaar_shopkeeper() end,
            ["Kakariko Bazaar Item 2"] = function () return shop_price(49) and soul_bazaar_shopkeeper() end,
            ["Kakariko Bazaar Item 3"] = function () return shop_price(50) and soul_bazaar_shopkeeper() end,
            ["Kakariko Bazaar Item 4"] = function () return shop_price(51) and soul_bazaar_shopkeeper() end,
            ["Kakariko Bazaar Item 5"] = function () return shop_price(52) and soul_bazaar_shopkeeper() end,
            ["Kakariko Bazaar Item 6"] = function () return shop_price(53) and soul_bazaar_shopkeeper() end,
            ["Kakariko Bazaar Item 7"] = function () return shop_price(54) and soul_bazaar_shopkeeper() end,
            ["Kakariko Bazaar Item 8"] = function () return shop_price(55) and soul_bazaar_shopkeeper() end,
        },
    },
    ["Kakariko Potion Shop"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Kakariko Potion Shop Junction"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Potion Shop Item 1"] = function () return is_adult() and shop_price(56) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
            ["Kakariko Potion Shop Item 2"] = function () return is_adult() and shop_price(57) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
            ["Kakariko Potion Shop Item 3"] = function () return is_adult() and shop_price(58) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
            ["Kakariko Potion Shop Item 4"] = function () return is_adult() and shop_price(59) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
            ["Kakariko Potion Shop Item 5"] = function () return is_adult() and shop_price(60) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
            ["Kakariko Potion Shop Item 6"] = function () return is_adult() and shop_price(61) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
            ["Kakariko Potion Shop Item 7"] = function () return is_adult() and shop_price(62) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
            ["Kakariko Potion Shop Item 8"] = function () return is_adult() and shop_price(63) and soul_npc(SOUL_NPC_POTION_SHOPKEEPER) end,
        },
    },
    ["Kakariko Potion Shop Junction"] = {
        ["exits"] = {
            ["Kakariko Potion Shop"] = function () return true end,
            ["Kakariko Potion Shop Back"] = function () return is_adult() or climb_anywhere() end,
        },
    },
    ["Kakariko Potion Shop Back"] = {
        ["exits"] = {
            ["Kakariko Back"] = function () return is_adult() end,
            ["Kakariko Potion Shop Junction"] = function () return true end,
        },
    },
    ["Kakariko Granny Shop"] = {
        ["events"] = {
            ["MAGIC"] = function () return adult_trade(ODD_MUSHROOM) and can_use_wallet(2) and has_bottle() end,
        },
        ["exits"] = {
            ["Kakariko Back"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Potion Shop Odd Potion"] = function () return soul_old_hag() and adult_trade(ODD_MUSHROOM) end,
        },
    },
    ["Shooting Gallery Adult"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Shooting Gallery Adult"] = function () return is_adult() and can_use_bow() and can_use_wallet(1) and soul_shooting_gallery_owner() end,
        },
    },
    ["Impa House Front"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Cow"] = function () return can_play_epona() end,
        },
    },
    ["Impa House Back"] = {
        ["exits"] = {
            ["Kakariko Rooftop"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Cow"] = function () return can_play_epona() end,
            ["Kakariko Impa House HP"] = function () return true end,
        },
    },
    ["Windmill"] = {
        ["events"] = {
            ["WELL_DRAIN"] = function () return is_child() and can_play_storms() end,
        },
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Windmill Exit"] = function () return climb_anywhere() or hookshot_anywhere() or (is_adult() and trick('OOT_WINDMILL_HP_NOTHING')) end,
        },
        ["locations"] = {
            ["Windmill HP"] = function () return can_boomerang() or event('WINDMILL_TOP') or (is_adult() and trick('OOT_WINDMILL_HP_NOTHING')) or climb_anywhere() or hookshot_anywhere() end,
            ["Windmill Song of Storms"] = function () return is_adult() and has_ocarina() and soul_guru_guru() end,
        },
    },
    ["Windmill Exit"] = {
        ["exits"] = {
            ["Windmill"] = function () return true end,
            ["Dampe Grave Entrance"] = function () return trick('OOT_REVERSE_DAMPE') and (climb_anywhere() and (is_child() or can_play_time()) or time_travel_at_will()) end,
        },
    },
    ["Kakariko Carpenter House"] = {
        ["events"] = {
            ["TALON_AWAKE"] = function () return adult_trade(POCKET_CUCCO) and soul_talon() end,
        },
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
    },
    ["Skulltula House"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Skulltula House 10 Tokens"] = function () return has('GS_TOKEN', 10) end,
            ["Skulltula House 20 Tokens"] = function () return has('GS_TOKEN', 20) end,
            ["Skulltula House 30 Tokens"] = function () return has('GS_TOKEN', 30) end,
            ["Skulltula House 40 Tokens"] = function () return has('GS_TOKEN', 40) end,
            ["Skulltula House 50 Tokens"] = function () return has('GS_TOKEN', 50) end,
        },
    },
    ["ReDead Grotto"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Grotto Front"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_sticks() or can_use_din() or can_hammer()) end,
        },
    },
    ["Kakariko Generic Grotto"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Kakariko Back"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Grotto Back"] = function () return true end,
            ["Kakariko Grotto Back Grass 1"] = function () return can_cut_grass() end,
            ["Kakariko Grotto Back Grass 2"] = function () return can_cut_grass() end,
            ["Kakariko Grotto Back Grass 3"] = function () return can_cut_grass() end,
            ["Kakariko Grotto Back Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Graveyard"] = {
        ["events"] = {
            ["BEAN_GRAVEYARD"] = function () return can_use_beans() end,
            ["BUGS"] = function () return has_bottle() end,
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
        },
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Graveyard Royal Tomb"] = function () return can_play_zelda() end,
            ["Graveyard Shield Grave"] = function () return is_adult() or is_night() end,
            ["Graveyard ReDead Grave"] = function () return is_adult() or is_night() end,
            ["Dampe Grave"] = function () return is_adult() end,
            ["Dampe House"] = function () return is_adult() or is_dusk() end,
            ["Graveyard Upper"] = function () return climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Graveyard Dampe Game"] = function () return is_child() and can_use_wallet(1) and is_dusk() and soul_dampe() end,
            ["Graveyard Crate HP"] = function () return can_ride_bean(BEAN_GRAVEYARD) or can_longshot() or climb_anywhere() or hookshot_anywhere() end,
            ["Graveyard GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Graveyard GS Wall"] = function () return is_child() and gs_night() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_din()))) end,
            ["Graveyard Grass 01"] = function () return can_cut_grass() end,
            ["Graveyard Grass 02"] = function () return can_cut_grass() end,
            ["Graveyard Grass 03"] = function () return can_cut_grass() end,
            ["Graveyard Grass 04"] = function () return can_cut_grass() end,
            ["Graveyard Grass 05"] = function () return can_cut_grass() end,
            ["Graveyard Grass 06"] = function () return can_cut_grass() end,
            ["Graveyard Grass 07"] = function () return can_cut_grass() end,
            ["Graveyard Grass 08"] = function () return can_cut_grass() end,
            ["Graveyard Grass 09"] = function () return can_cut_grass() end,
            ["Graveyard Grass 10"] = function () return can_cut_grass() end,
            ["Graveyard Grass 11"] = function () return can_cut_grass() end,
            ["Graveyard Grass 12"] = function () return can_cut_grass() end,
        },
    },
    ["Graveyard Upper"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
            ["Shadow Temple"] = function () return can_use_din() or (has_fire_arrows() and (trick('OOT_SHADOW_FIRE_ARROW') or (trick('OOT_SHADOW_TEMPLE_STICKS') and can_use_sticks()))) end,
        },
    },
    ["Graveyard Royal Tomb"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Graveyard Royal Tomb Song"] = function () return soul_keese() and (has_ranged_weapon() or can_use_sword() or has_explosives() or can_hammer() or can_use_sticks()) end,
            ["Graveyard Royal Tomb Chest"] = function () return has_fire() end,
            ["Graveyard Royal Tomb Big Fairy"] = function () return can_play_sun() end,
        },
    },
    ["Graveyard Shield Grave"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Graveyard Fairy Tomb"] = function () return true end,
            ["Graveyard Fairy Fountain Fairy 1"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Graveyard Fairy Fountain Fairy 2"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Graveyard Fairy Fountain Fairy 3"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Graveyard Fairy Fountain Fairy 4"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Graveyard Fairy Fountain Fairy 5"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Graveyard Fairy Fountain Fairy 6"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Graveyard Fairy Fountain Fairy 7"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Graveyard Fairy Fountain Fairy 8"] = function () return has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
        },
    },
    ["Graveyard ReDead Grave"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Graveyard ReDead Tomb"] = function () return can_play_sun() end,
        },
    },
    ["Dampe Grave"] = {
        ["events"] = {
            ["NUTS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["WINDMILL_TOP"] = function () return is_adult() and can_play_time() and soul_dampe() end,
        },
        ["exits"] = {
            ["Dampe Grave Entrance"] = function () return true end,
            ["Windmill Exit"] = function () return is_adult() and can_play_time() and soul_dampe() end,
        },
        ["locations"] = {
            ["Graveyard Dampe Tomb Reward 1"] = function () return soul_dampe() end,
            ["Graveyard Dampe Tomb Reward 2"] = function () return is_adult() and soul_dampe() end,
            ["Graveyard Dampe Tomb Pot 1"] = function () return true end,
            ["Graveyard Dampe Tomb Pot 2"] = function () return true end,
            ["Graveyard Dampe Tomb Pot 3"] = function () return true end,
            ["Graveyard Dampe Tomb Pot 4"] = function () return true end,
            ["Graveyard Dampe Tomb Pot 5"] = function () return true end,
            ["Graveyard Dampe Tomb Pot 6"] = function () return true end,
            ["Graveyard Dampe Tomb Rupee 1"] = function () return true end,
            ["Graveyard Dampe Tomb Rupee 2"] = function () return true end,
            ["Graveyard Dampe Tomb Rupee 3"] = function () return true end,
            ["Graveyard Dampe Tomb Rupee 4"] = function () return soul_dampe() end,
            ["Graveyard Dampe Tomb Rupee 5"] = function () return soul_dampe() end,
            ["Graveyard Dampe Tomb Rupee 6"] = function () return soul_dampe() end,
            ["Graveyard Dampe Tomb Rupee 7"] = function () return soul_dampe() end,
            ["Graveyard Dampe Tomb Rupee 8"] = function () return soul_dampe() end,
        },
    },
    ["Dampe Grave Entrance"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
    },
    ["Dampe House"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
    },
    ["Death Mountain"] = {
        ["events"] = {
            ["BEAN_DEATH_MOUNTAIN"] = function () return can_use_beans() and has_bombflowers() end,
            ["BOULDER_DEATH_MOUNTAIN"] = function () return has_explosives_or_hammer() end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Goron City"] = function () return true end,
            ["Dodongo Cavern"] = function () return has_bombflowers() or is_adult() or (trick('OOT_DC_BOULDER') and hookshot_anywhere()) or time_travel_at_will() end,
            ["Kakariko Trail Start"] = function () return true end,
            ["Death Mountain Summit"] = function () return event('BOULDER_DEATH_MOUNTAIN') or can_ride_bean(BEAN_DEATH_MOUNTAIN) or climb_anywhere() or hookshot_anywhere() end,
            ["Death Mountain Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Death Mountain Cow Grotto"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Death Mountain Trail Chest"] = function () return has_explosives_or_hammer() end,
            ["Death Mountain Trail HP"] = function () return true end,
            ["Death Mountain Trail GS Entrance"] = function () return gs() and (has_explosives() or (can_hammer() and (is_adult() or can_use_sticks() or (age_sword_adult() and has('SWORD_BIGGORON')) or has_ranged_weapon_child() or can_use_din()))) end,
            ["Death Mountain Trail GS Soil"] = function () return gs_soil() and has_bombflowers() and can_damage_skull() end,
            ["Death Mountain Trail GS Above Dodongo"] = function () return gs_night() and is_adult() and (can_hammer() or trick('OOT_DMT_RED_ROCK_GS')) end,
            ["Death Mountain Trail Rupee Upper"] = function () return is_child() and event('BOULDER_DEATH_MOUNTAIN') end,
            ["Death Mountain Trail Rupee Lower"] = function () return is_child() and has_explosives_or_hammer() end,
            ["Death Mountain Trail Big Fairy"] = function () return can_play_sun() end,
        },
    },
    ["Death Mountain Summit"] = {
        ["exits"] = {
            ["Death Mountain"] = function () return true end,
            ["Kakariko Rooftop"] = function () return is_child() end,
            ["Death Mountain Crater Top"] = function () return true end,
            ["Fairy Fountain Magic"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Death Mountain Trail Prescription"] = function () return adult_trade(BROKEN_GORON_SWORD) and soul_biggoron() end,
            ["Death Mountain Trail Claim Check"] = function () return adult_trade(EYE_DROPS) and soul_biggoron() end,
            ["Death Mountain Trail Biggoron Sword"] = function () return adult_trade(CLAIM_CHECK) and soul_biggoron() end,
            ["Death Mountain Trail GS Before Climb"] = function () return is_adult() and gs_night() and (can_hammer() or trick('OOT_DMT_RED_ROCK_GS')) end,
        },
    },
    ["Death Mountain Storms Grotto"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Death Mountain"] = function () return true end,
        },
        ["locations"] = {
            ["Death Mountain Trail Grotto"] = function () return true end,
            ["Death Mountain Trail Grotto Grass 1"] = function () return can_cut_grass() end,
            ["Death Mountain Trail Grotto Grass 2"] = function () return can_cut_grass() end,
            ["Death Mountain Trail Grotto Grass 3"] = function () return can_cut_grass() end,
            ["Death Mountain Trail Grotto Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Death Mountain Cow Grotto"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Death Mountain"] = function () return true end,
        },
        ["locations"] = {
            ["Death Mountain Trail Cow"] = function () return can_play_epona() end,
            ["Death Mountain Trail Cow Grotto Grass 1"] = function () return can_cut_grass() end,
            ["Death Mountain Trail Cow Grotto Grass 2"] = function () return can_cut_grass() end,
            ["Death Mountain Trail Cow Grotto Rupee 1"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Rupee 2"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Rupee 3"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Rupee 4"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Rupee 5"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Rupee 6"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Rupee 7"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Heart 1"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Heart 2"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Heart 3"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Heart 4"] = function () return true end,
            ["Death Mountain Trail Cow Grotto Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Fairy Fountain Magic"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Death Mountain Summit"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Magic Upgrade"] = function () return can_play_zelda() end,
        },
    },
    ["Goron City Shortcut"] = {
        ["events"] = {
            ["GORON_CITY_SHORTCUT"] = function () return has_explosives_or_hammer() or can_use_din() end,
        },
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
            ["Goron City"] = function () return event('GORON_CITY_SHORTCUT') or climb_anywhere() or hookshot_anywhere() end,
        },
    },
    ["Goron City"] = {
        ["events"] = {
            ["GORON_CITY_SHORTCUT"] = function () return has_bombflowers() or can_hammer() or can_use_bow() or can_use_din() or event('DARUNIA_TORCH') end,
            ["STICKS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["BUGS"] = function () return has_bottle() and (has_explosives_or_hammer() or can_lift_silver()) end,
        },
        ["exits"] = {
            ["Goron City Shortcut"] = function () return event('GORON_CITY_SHORTCUT') or climb_anywhere() or hookshot_anywhere() end,
            ["Death Mountain"] = function () return true end,
            ["Darunia Chamber"] = function () return is_adult() and (has_explosives() or can_use_bow() or has_goron_bracelet()) and soul_goron_child() or (is_child() and can_play_zelda()) end,
            ["Goron Shop"] = function () return has_bombflowers() and (is_child() or time_travel_at_will() or (is_adult() and soul_goron_child())) or (can_use_bow() and soul_goron_child() and (is_adult() or time_travel_at_will())) or ((can_use_din() or event('DARUNIA_TORCH')) and (is_child() or time_travel_at_will())) end,
            ["Goron City Grotto"] = function () return is_adult() and can_play_time() or (can_hookshot() and (has_tunic_goron_strict() or can_use_nayru())) or climb_anywhere() end,
        },
        ["locations"] = {
            ["Goron City Maze Center 1"] = function () return has_explosives_or_hammer() or can_lift_silver() or climb_anywhere() or hookshot_anywhere() end,
            ["Goron City Maze Center 2"] = function () return has_explosives_or_hammer() or can_lift_silver() or climb_anywhere() or hookshot_anywhere() end,
            ["Goron City Maze Left"] = function () return can_hammer() or can_lift_silver() or climb_anywhere() or hookshot_anywhere() end,
            ["Goron City Big Pot HP"] = function () return is_child() and has_bombs() and (event('DARUNIA_TORCH') or has_fire()) end,
            ["Goron City Tunic"] = function () return is_adult() and (has_explosives() or can_use_bow() or has_goron_bracelet()) and soul_goron_child() end,
            ["Goron City Bomb Bag"] = function () return is_child() and has_explosives() and soul_goron() end,
            ["Goron City Medigoron Giant Knife"] = function () return is_adult() and (has_bombflowers() or can_hammer()) and can_use_wallet(2) and soul_medigoron() end,
            ["Goron City GS Platform"] = function () return gs() and is_adult() end,
            ["Goron City GS Maze"] = function () return gs() and is_child() and (has_explosives_or_hammer() or (climb_anywhere() and can_damage_skull()) or hookshot_anywhere()) end,
            ["Goron City Pot Stairs 1"] = function () return true end,
            ["Goron City Pot Stairs 2"] = function () return true end,
            ["Goron City Pot Stairs 3"] = function () return true end,
            ["Goron City Pot Stairs 4"] = function () return true end,
            ["Goron City Pot Stairs 5"] = function () return true end,
            ["Goron City Pot Medigoron Room"] = function () return has_bombflowers() or can_hammer() end,
        },
    },
    ["Darunia Chamber"] = {
        ["events"] = {
            ["DARUNIA_TORCH"] = function () return is_child() and can_use_sticks() end,
            ["STICKS"] = function () return is_child() end,
            ["RUPEES"] = function () return is_adult() end,
        },
        ["exits"] = {
            ["Death Mountain Crater Bottom"] = function () return is_adult() or time_travel_at_will() end,
            ["Goron City"] = function () return true end,
        },
        ["locations"] = {
            ["Darunia"] = function () return is_child() and can_play_saria() and soul_npc(SOUL_NPC_DARUNIA) end,
            ["Goron City Pot Darunia Room 1"] = function () return true end,
            ["Goron City Pot Darunia Room 2"] = function () return true end,
            ["Goron City Pot Darunia Room 3"] = function () return true end,
        },
    },
    ["Goron Shop"] = {
        ["exits"] = {
            ["Goron City"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Shop Item 1"] = function () return shop_price(24) and soul_goron_shopkeeper() end,
            ["Goron Shop Item 2"] = function () return shop_price(25) and soul_goron_shopkeeper() end,
            ["Goron Shop Item 3"] = function () return shop_price(26) and soul_goron_shopkeeper() end,
            ["Goron Shop Item 4"] = function () return shop_price(27) and soul_goron_shopkeeper() end,
            ["Goron Shop Item 5"] = function () return shop_price(28) and soul_goron_shopkeeper() end,
            ["Goron Shop Item 6"] = function () return shop_price(29) and soul_goron_shopkeeper() end,
            ["Goron Shop Item 7"] = function () return shop_price(30) and soul_goron_shopkeeper() end,
            ["Goron Shop Item 8"] = function () return shop_price(31) and soul_goron_shopkeeper() end,
        },
    },
    ["Goron City Grotto"] = {
        ["exits"] = {
            ["Goron City"] = function () return true end,
        },
        ["locations"] = {
            ["Goron City Grotto Left Scrub"] = function () return business_scrub(11) end,
            ["Goron City Grotto Center Scrub"] = function () return business_scrub(12) end,
            ["Goron City Grotto Right Scrub"] = function () return business_scrub(13) end,
        },
    },
    ["Zora River Front"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Zora River"] = function () return is_adult() or has_explosives_or_hammer() or has_hover_boots() or climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Zora River GS Tree"] = function () return gs() and is_child() and can_damage_skull() end,
            ["Zora River Grass Pack Bush 01"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 02"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 03"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 04"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 05"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 06"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 07"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 08"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 09"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 10"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 11"] = function () return can_cut_grass() end,
            ["Zora River Grass Pack Bush 12"] = function () return can_cut_grass() end,
        },
    },
    ["Zora River"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Zora River Front"] = function () return true end,
            ["Zora River Behind Falls"] = function () return can_play_zelda() or (trick('OOT_ZR_FALLS_HOOK') and hookshot_anywhere()) or (trick('OOT_DOMAIN_CUCCO') and is_child()) or (trick('OOT_DOMAIN_HOVER') and has_hover_boots()) end,
            ["Lost Woods"] = function () return can_dive_small() or hookshot_anywhere() end,
            ["Zora River Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Zora River Open Grotto"] = function () return true end,
            ["Zora River Boulder Grotto"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Zora River Bean Seller"] = function () return is_child() and can_use_wallet(1) and soul_bean_salesman() end,
            ["Zora River HP Pillar"] = function () return is_child() or has_hover_boots() or climb_anywhere() or hookshot_anywhere() or glitch_megaflip() end,
            ["Zora River HP Platform"] = function () return is_child() or has_hover_boots() or climb_anywhere() or hookshot_anywhere() or glitch_megaflip() end,
            ["Zora River Frogs Storms"] = function () return is_child() and can_play_storms() end,
            ["Zora River Frogs Game"] = function () return is_child() and can_play_zelda() and can_play_saria() and can_play_epona() and can_play_sun() and can_play_time() and can_play_storms() and can_play_minigame() end,
            ["Zora River GS Ladder"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Zora River GS Near Grotto"] = function () return is_adult() and gs_night() and (can_collect_distance() or climb_anywhere()) end,
            ["Zora River GS Near Bridge"] = function () return is_adult() and gs_night() and (can_hookshot() or (climb_anywhere() and (has_ranged_weapon() or has_bombchu()))) end,
            ["Zora River Grass"] = function () return (is_child() or has_hover_boots() or hookshot_anywhere() or climb_anywhere()) and can_cut_grass() end,
            ["Zora River Rupee 1"] = function () return is_adult() end,
            ["Zora River Rupee 2"] = function () return is_adult() end,
            ["Zora River Rupee 3"] = function () return is_adult() end,
            ["Zora River Rupee 4"] = function () return is_adult() end,
        },
    },
    ["Zora River Behind Falls"] = {
        ["exits"] = {
            ["Zora River"] = function () return true end,
            ["Zora Domain"] = function () return true end,
        },
    },
    ["Zora River Storms Grotto"] = {
        ["exits"] = {
            ["Zora River"] = function () return true end,
        },
        ["locations"] = {
            ["Zora River Storms Grotto Front Scrub"] = function () return business_scrub(18) end,
            ["Zora River Storms Grotto Back Scrub"] = function () return business_scrub(19) end,
        },
    },
    ["Zora River Open Grotto"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Zora River"] = function () return true end,
        },
        ["locations"] = {
            ["Zora River Grotto"] = function () return true end,
            ["Zora River Grotto Grass 1"] = function () return can_cut_grass() end,
            ["Zora River Grotto Grass 2"] = function () return can_cut_grass() end,
            ["Zora River Grotto Grass 3"] = function () return can_cut_grass() end,
            ["Zora River Grotto Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Zora River Boulder Grotto"] = {
        ["exits"] = {
            ["Zora River"] = function () return true end,
        },
        ["locations"] = {
            ["Zora River Fairy Fountain Fairy 1"] = function () return true end,
            ["Zora River Fairy Fountain Fairy 2"] = function () return true end,
            ["Zora River Fairy Fountain Fairy 3"] = function () return true end,
            ["Zora River Fairy Fountain Fairy 4"] = function () return true end,
            ["Zora River Fairy Fountain Fairy 5"] = function () return true end,
            ["Zora River Fairy Fountain Fairy 6"] = function () return true end,
            ["Zora River Fairy Fountain Fairy 7"] = function () return true end,
            ["Zora River Fairy Fountain Fairy 8"] = function () return true end,
        },
    },
    ["Zora Domain"] = {
        ["events"] = {
            ["KING_ZORA_LETTER"] = function () return is_child() and has('RUTO_LETTER') end,
            ["STICKS"] = function () return is_child() end,
            ["NUTS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["FISH"] = function () return is_child() and has_bottle() end,
        },
        ["exits"] = {
            ["Zora River Behind Falls"] = function () return true end,
            ["Lake Hylia"] = function () return is_child() and (can_dive_small() or longshot_anywhere() or (trick('OOT_LAKE_SHORTCUT') and hookshot_anywhere())) end,
            ["Zora Domain Back"] = function () return king_zora_moved() or (is_adult() and trick('OOT_KZ_SKIP')) or climb_anywhere() or hookshot_anywhere() end,
            ["Zora Shop"] = function () return is_child() or has_blue_fire() end,
            ["Zora Domain Grotto"] = function () return hidden_grotto_storms() end,
        },
        ["locations"] = {
            ["Zora Domain Waterfall Chest"] = function () return is_child() end,
            ["Zora Domain Diving Game"] = function () return is_child() and can_use_wallet(1) and soul_zora() end,
            ["Zora Domain Diving Game Green Rupee"] = function () return is_child() and can_use_wallet(1) and soul_zora() end,
            ["Zora Domain Diving Game Blue Rupee"] = function () return is_child() and can_use_wallet(1) and soul_zora() end,
            ["Zora Domain Diving Game Red Rupee"] = function () return is_child() and can_use_wallet(1) and soul_zora() end,
            ["Zora Domain Diving Game Purple Rupee"] = function () return is_child() and can_use_wallet(1) and soul_zora() end,
            ["Zora Domain Diving Game Huge Rupee"] = function () return is_child() and can_use_wallet(1) and soul_zora() end,
            ["Zora Domain Tunic"] = function () return is_adult() and has_blue_fire() and soul_npc(SOUL_NPC_KING_ZORA) end,
            ["Zora Domain Eyeball Frog"] = function () return has_blue_fire() and adult_trade(PRESCRIPTION) and soul_npc(SOUL_NPC_KING_ZORA) end,
            ["Zora Domain GS Waterfall"] = function () return is_adult() and gs_night() and (has_ranged_weapon() or has_magic() or has_explosives()) end,
            ["Zora Domain Pot 1"] = function () return true end,
            ["Zora Domain Pot 2"] = function () return true end,
            ["Zora Domain Pot 3"] = function () return true end,
            ["Zora Domain Pot 4"] = function () return true end,
            ["Zora Domain Pot 5"] = function () return true end,
        },
    },
    ["Zora Domain Back"] = {
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
            ["Zora Domain"] = function () return king_zora_moved() or climb_anywhere() or hookshot_anywhere() end,
        },
    },
    ["Zora Shop"] = {
        ["exits"] = {
            ["Zora Domain"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Shop Item 1"] = function () return shop_price(16) and soul_zora_shopkeeper() end,
            ["Zora Shop Item 2"] = function () return shop_price(17) and soul_zora_shopkeeper() end,
            ["Zora Shop Item 3"] = function () return shop_price(18) and soul_zora_shopkeeper() end,
            ["Zora Shop Item 4"] = function () return shop_price(19) and soul_zora_shopkeeper() end,
            ["Zora Shop Item 5"] = function () return shop_price(20) and soul_zora_shopkeeper() end,
            ["Zora Shop Item 6"] = function () return shop_price(21) and soul_zora_shopkeeper() end,
            ["Zora Shop Item 7"] = function () return shop_price(22) and soul_zora_shopkeeper() end,
            ["Zora Shop Item 8"] = function () return shop_price(23) and soul_zora_shopkeeper() end,
        },
    },
    ["Zora Domain Grotto"] = {
        ["exits"] = {
            ["Zora Domain"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Domain Fairy Fountain Fairy 1"] = function () return true end,
            ["Zora Domain Fairy Fountain Fairy 2"] = function () return true end,
            ["Zora Domain Fairy Fountain Fairy 3"] = function () return true end,
            ["Zora Domain Fairy Fountain Fairy 4"] = function () return true end,
            ["Zora Domain Fairy Fountain Fairy 5"] = function () return true end,
            ["Zora Domain Fairy Fountain Fairy 6"] = function () return true end,
            ["Zora Domain Fairy Fountain Fairy 7"] = function () return true end,
            ["Zora Domain Fairy Fountain Fairy 8"] = function () return true end,
        },
    },
    ["Lake Hylia"] = {
        ["events"] = {
            ["SCARECROW_CHILD"] = function () return is_child() and can_play_scarecrow() end,
            ["SCARECROW"] = function () return is_adult() and event('SCARECROW_CHILD') end,
            ["BEAN_LAKE_HYLIA"] = function () return can_use_beans() end,
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() and is_child() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Hyrule Field Drawbridge"] = function () return is_child() end,
            ["Zora Domain"] = function () return is_child() and (can_dive_small() or longshot_anywhere() or (trick('OOT_LAKE_SHORTCUT') and hookshot_anywhere())) or time_travel_at_will() or (is_adult() and setting('openZdShortcut')) end,
            ["Laboratory"] = function () return true end,
            ["Water Temple"] = function () return has_iron_boots() and has_tunic_zora() and can_hookshot() or (trick('OOT_WATER_GOLD_SCALE') and is_adult() and can_longshot() and has_scale_raw(2)) end,
            ["Fishing Pond"] = function () return is_child() or event('WATER_TEMPLE_CLEARED') or (is_adult() and scarecrow_hookshot()) or can_ride_bean(BEAN_LAKE_HYLIA) or hookshot_anywhere() or climb_anywhere() or time_travel_at_will() end,
            ["Lake Hylia Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Lake Hylia Underwater Bottle"] = function () return is_child() and can_dive_small() end,
            ["Lake Hylia Fire Arrow"] = function () return can_use_bow() and (event('WATER_TEMPLE_CLEARED') or (is_adult() and (scarecrow_longshot() or longshot_anywhere())) or climb_anywhere()) end,
            ["Lake Hylia HP"] = function () return can_ride_bean(BEAN_LAKE_HYLIA) or (is_adult() and scarecrow_hookshot()) or hookshot_anywhere() end,
            ["Lake Hylia GS Lab Wall"] = function () return is_child() and gs_night() and (can_collect_distance() or (trick('OOT_LAB_WALL_GS') and (can_use_sword() or can_use_sticks())) or (time_travel_at_will() and (scarecrow_hookshot() or hookshot_anywhere() or can_ride_bean(BEAN_LAKE_HYLIA)) and (has_explosives_or_hammer() or can_use_din() or can_use_slingshot()))) end,
            ["Lake Hylia GS Island"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Lake Hylia GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Lake Hylia GS Big Tree"] = function () return is_adult() and gs_night() and (can_longshot() or climb_anywhere()) end,
            ["Lake Hylia Island Big Fairy"] = function () return can_play_sun() and (is_child() or scarecrow_longshot() or longshot_anywhere() or climb_anywhere()) end,
            ["Lake Hylia Pot 1"] = function () return is_child() end,
            ["Lake Hylia Pot 2"] = function () return is_child() end,
            ["Lake Hylia Grass 1"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass 2"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Child 1"] = function () return is_child() and can_cut_grass() end,
            ["Lake Hylia Grass Child 2"] = function () return is_child() and can_cut_grass() end,
            ["Lake Hylia Grass Child 3"] = function () return is_child() and can_cut_grass() end,
            ["Lake Hylia Grass Child 4"] = function () return is_child() and can_cut_grass() end,
            ["Lake Hylia Grass Child 5"] = function () return is_child() and can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 01"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 02"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 03"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 04"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 05"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 06"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 07"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 08"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 09"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 10"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 11"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 1 Bush 12"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 01"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 02"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 03"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 04"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 05"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 06"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 07"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 08"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 09"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 10"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 11"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 2 Bush 12"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 01"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 02"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 03"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 04"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 05"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 06"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 07"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 08"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 09"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 10"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 11"] = function () return can_cut_grass() end,
            ["Lake Hylia Grass Pack 3 Bush 12"] = function () return can_cut_grass() end,
            ["Lake Hylia Rupee 1"] = function () return is_child() end,
            ["Lake Hylia Rupee 2"] = function () return is_child() and can_dive_small() end,
            ["Lake Hylia Rupee 3"] = function () return is_child() and can_dive_small() end,
        },
    },
    ["Laboratory"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
        ["locations"] = {
            ["Laboratory Dive"] = function () return soul_scientist() and (has_scale_raw(2) or (trick('OOT_LAB_DIVE_NO_GOLD_SCALE') and has_iron_boots() and can_hookshot())) end,
            ["Laboratory Eye Drops"] = function () return soul_scientist() and adult_trade(EYEBALL_FROG) end,
            ["Laboratory GS Crate"] = function () return gs() and has_iron_boots() and can_hookshot() end,
            ["Laboratory Rupee 1"] = function () return can_dive_big() end,
            ["Laboratory Rupee 2"] = function () return can_dive_big() end,
            ["Laboratory Rupee 3"] = function () return can_dive_big() end,
        },
    },
    ["Fishing Pond"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
        ["locations"] = {
            ["Fishing Pond Child"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() and (not setting('pondFishShuffle') or has_pond_fish(CHILD_FISH, 7, 14) or has_pond_fish(CHILD_LOACH, 14, 19)) end,
            ["Fishing Pond Adult"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() and (not setting('pondFishShuffle') or has_pond_fish(ADULT_FISH, 8, 25) or has_pond_fish(ADULT_LOACH, 29, 36)) end,
            ["Fishing Pond Child Fish 1"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 2"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 3"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 4"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 5"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 6"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 7"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 8"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 9"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 10"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 11"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 12"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 13"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 14"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Fish 15"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Loach 1"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Child Loach 2"] = function () return is_child() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 1"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 2"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 3"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 4"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 5"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 6"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 7"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 8"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 9"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 10"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 11"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 12"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 13"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 14"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Fish 15"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
            ["Fishing Pond Adult Loach"] = function () return is_adult() and can_use_wallet(1) and soul_fishing_pond_owner() end,
        },
    },
    ["Lake Hylia Grotto"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
        ["locations"] = {
            ["Lake Hylia Grotto Left Scrub"] = function () return business_scrub(20) end,
            ["Lake Hylia Grotto Center Scrub"] = function () return business_scrub(21) end,
            ["Lake Hylia Grotto Right Scrub"] = function () return business_scrub(22) end,
        },
    },
    ["Zora Fountain"] = {
        ["events"] = {
            ["SEEDS"] = function () return is_child() end,
        },
        ["exits"] = {
            ["Zora Domain Back"] = function () return true end,
            ["Jabu-Jabu"] = function () return is_child() and (has_fish() or (trick('OOT_ENTER_JABU') and (climb_anywhere() or hookshot_anywhere() or has_weapon() or can_use_sticks() or time_travel_at_will()))) end,
            ["Zora Fountain Frozen"] = function () return is_adult() or climb_anywhere() or longshot_anywhere() end,
            ["Fairy Fountain Farore"] = function () return has_explosives() end,
            ["Zora Fountain Deep"] = function () return is_adult() and has_tunic_zora() and has_iron_boots() end,
        },
        ["locations"] = {
            ["Zora Fountain Iceberg HP"] = function () return is_adult() end,
            ["Zora Fountain GS Wall"] = function () return is_child() and gs_night() and (can_collect_distance() or (climb_anywhere() and (can_use_sword() or can_use_sticks() or has_ranged_weapon() or has_explosives() or can_use_din()))) end,
            ["Zora Fountain GS Tree"] = function () return gs() and is_child() and can_damage_skull() end,
            ["Zora Fountain GS Upper"] = function () return is_adult() and gs_night() and (has_explosives_or_hammer() and can_collect_distance() and can_lift_silver() or (climb_anywhere() and (has_explosives() or has('SWORD_BIGGORON') or has_ranged_weapon() or can_use_din()))) end,
            ["Zora Fountain Child Pot 1"] = function () return is_child() end,
            ["Zora Fountain Child Pot 2"] = function () return is_child() end,
            ["Zora Fountain Child Pot 3"] = function () return is_child() end,
            ["Zora Fountain Child Pot 4"] = function () return is_child() end,
            ["Zora Fountain Adult Pot 1"] = function () return is_adult() and (can_lift_silver() and has_explosives_or_hammer() or climb_anywhere()) end,
            ["Zora Fountain Adult Pot 2"] = function () return is_adult() and (can_lift_silver() and has_explosives_or_hammer() or climb_anywhere()) end,
            ["Zora Fountain Adult Pot 3"] = function () return is_adult() and (can_lift_silver() and has_explosives_or_hammer() or climb_anywhere()) end,
        },
    },
    ["Zora Fountain Deep"] = {
        ["locations"] = {
            ["Zora Fountain Bottom HP"] = function () return true end,
            ["Zora Fountain Rupee 01"] = function () return true end,
            ["Zora Fountain Rupee 02"] = function () return true end,
            ["Zora Fountain Rupee 03"] = function () return true end,
            ["Zora Fountain Rupee 04"] = function () return true end,
            ["Zora Fountain Rupee 05"] = function () return true end,
            ["Zora Fountain Rupee 06"] = function () return true end,
            ["Zora Fountain Rupee 07"] = function () return true end,
            ["Zora Fountain Rupee 08"] = function () return true end,
            ["Zora Fountain Rupee 09"] = function () return true end,
            ["Zora Fountain Rupee 10"] = function () return true end,
            ["Zora Fountain Rupee 11"] = function () return true end,
            ["Zora Fountain Rupee 12"] = function () return true end,
            ["Zora Fountain Rupee 13"] = function () return true end,
            ["Zora Fountain Rupee 14"] = function () return true end,
            ["Zora Fountain Rupee 15"] = function () return true end,
            ["Zora Fountain Rupee 16"] = function () return true end,
            ["Zora Fountain Rupee 17"] = function () return true end,
            ["Zora Fountain Rupee 18"] = function () return true end,
        },
    },
    ["Zora Fountain Frozen"] = {
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
            ["Ice Cavern"] = function () return true end,
        },
    },
    ["Fairy Fountain Farore"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Farore's Wind"] = function () return can_play_zelda() end,
        },
    },
    ["Temple of Time"] = {
        ["events"] = {
            ["DOOR_OF_TIME_OPEN"] = function () return setting('doorOfTime', 'open') or can_play_time() end,
            ["TIME_TRAVEL"] = function () return event('DOOR_OF_TIME_OPEN') and (has_sword_master() or not setting('timeTravelSword')) end,
            ["TIME_TRAVEL_AT_WILL"] = function () return not setting('ageChange', 'none') and event('TIME_TRAVEL') and can_play_time() and (not setting('ageChange', 'oot') or has_ocarina_of_time()) end,
        },
        ["exits"] = {
            ["Temple of Time Entryway"] = function () return true end,
            ["Sacred Realm"] = function () return is_adult() and event('DOOR_OF_TIME_OPEN') end,
        },
        ["locations"] = {
            ["Temple of Time Master Sword"] = function () return is_child() and event('DOOR_OF_TIME_OPEN') end,
            ["Temple of Time Sheik Song"] = function () return is_adult() and soul_npc(SOUL_NPC_SHEIK) and event('DOOR_OF_TIME_OPEN') and has('MEDALLION_FOREST') end,
            ["Temple of Time Light Arrows"] = function () return is_adult() and soul_npc(SOUL_NPC_SHEIK) and soul_npc(SOUL_NPC_ZELDA) and (setting('lacs', 'vanilla') and has('MEDALLION_SPIRIT') and has('MEDALLION_SHADOW') or (setting('lacs', 'custom') and special(LACS))) end,
        },
    },
    ["Sacred Realm"] = {
        ["locations"] = {
            ["Temple of Time Medallion"] = function () return true end,
        },
    },
    ["Death Mountain Crater Top"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return has_tunic_goron_strict() or can_hammer() end,
            ["RUPEES"] = function () return has_tunic_goron_strict() or has_explosives_or_hammer() end,
            ["ARROWS"] = function () return has_tunic_goron_strict() or has_explosives_or_hammer() end,
            ["MAGIC"] = function () return has_tunic_goron_strict() or has_explosives_or_hammer() end,
        },
        ["exits"] = {
            ["Death Mountain Summit"] = function () return true end,
            ["Death Mountain Crater Bottom"] = function () return is_adult() and event('RED_BOULDER_BROKEN') or (has_hover_boots() and (has_weapon() or can_hammer() or can_use_sticks())) or climb_anywhere() or hookshot_anywhere() end,
            ["Death Mountain Crater Warp"] = function () return has_tunic_goron_strict() and (is_adult() and scarecrow_longshot() or longshot_anywhere() or glitch_megaflip()) end,
            ["Death Mountain Crater Generic Grotto"] = function () return has_explosives_or_hammer() end,
            ["Fairy Fountain Double Magic"] = function () return glitch_megaflip() end,
            ["Death Mountain Crater Bottom Adult Rupees"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Death Mountain Crater GS Crate"] = function () return gs() and is_child() and can_damage_skull() end,
            ["Death Mountain Crater Alcove HP"] = function () return true end,
            ["Death Mountain Crater Scrub Child"] = function () return is_child() and business_scrub(14) end,
        },
    },
    ["Death Mountain Crater Bottom"] = {
        ["events"] = {
            ["RED_BOULDER_BROKEN"] = function () return is_adult() and can_hammer() end,
        },
        ["exits"] = {
            ["Darunia Chamber"] = function () return true end,
            ["Death Mountain Crater Warp"] = function () return (can_hookshot() or has_hover_boots()) and (is_adult() or has_tunic_goron_strict() or can_hammer() or hookshot_anywhere() or climb_anywhere()) end,
            ["Death Mountain Crater Top"] = function () return is_adult() or has_tunic_goron_strict() end,
            ["Death Mountain Crater Scrub Grotto"] = function () return can_hammer() end,
            ["Fairy Fountain Double Magic"] = function () return can_hammer() or climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Death Mountain Crater Volcano HP"] = function () return trick('OOT_VOLCANO_HOVERS') and (has_hover_boots() or hookshot_anywhere()) or glitch_megaflip() end,
            ["Death Mountain Crater Pot 1"] = function () return true end,
            ["Death Mountain Crater Pot 2"] = function () return true end,
            ["Death Mountain Crater Pot 3"] = function () return true end,
            ["Death Mountain Crater Pot 4"] = function () return true end,
        },
    },
    ["Death Mountain Crater Bottom Child"] = {
        ["locations"] = {
            ["Death Mountain Crater Rupee Child 1"] = function () return true end,
            ["Death Mountain Crater Rupee Child 2"] = function () return true end,
            ["Death Mountain Crater Rupee Child 3"] = function () return true end,
            ["Death Mountain Crater Rupee Child 4"] = function () return true end,
            ["Death Mountain Crater Rupee Child 5"] = function () return true end,
            ["Death Mountain Crater Rupee Child 6"] = function () return true end,
            ["Death Mountain Crater Rupee Child 7"] = function () return true end,
            ["Death Mountain Crater Rupee Child 8"] = function () return true end,
        },
    },
    ["Death Mountain Crater Bottom Adult Rupees"] = {
        ["locations"] = {
            ["Death Mountain Crater Rupee Adult 1"] = function () return true end,
            ["Death Mountain Crater Rupee Adult 2"] = function () return true end,
            ["Death Mountain Crater Rupee Adult 3"] = function () return true end,
            ["Death Mountain Crater Rupee Adult 4"] = function () return true end,
            ["Death Mountain Crater Rupee Adult 5"] = function () return true end,
            ["Death Mountain Crater Rupee Adult 6"] = function () return true end,
            ["Death Mountain Crater Rupee Adult 7"] = function () return true end,
        },
    },
    ["Death Mountain Crater Warp"] = {
        ["events"] = {
            ["BEAN_DEATH_MOUNTAIN_CRATER"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Death Mountain Crater Near Temple"] = function () return has_tunic_goron() and (is_adult() or setting('fireChild') or has_hover_boots() or climb_anywhere() or hookshot_anywhere()) end,
            ["Death Mountain Crater Bottom"] = function () return can_hookshot() or has_hover_boots() or can_ride_bean(BEAN_DEATH_MOUNTAIN_CRATER) end,
            ["Death Mountain Crater Bottom Child"] = function () return is_child() end,
            ["Death Mountain Crater Bottom Adult Rupees"] = function () return is_adult() and scarecrow_longshot() end,
        },
        ["locations"] = {
            ["Death Mountain Crater Volcano HP"] = function () return can_ride_bean(BEAN_DEATH_MOUNTAIN_CRATER) or climb_anywhere() end,
            ["Death Mountain Crater Sheik Song"] = function () return is_adult() and soul_npc(SOUL_NPC_SHEIK) end,
            ["Death Mountain Crater GS Soil"] = function () return gs_soil() and can_damage_skull() end,
        },
    },
    ["Death Mountain Crater Near Temple"] = {
        ["exits"] = {
            ["Fire Temple"] = function () return true end,
            ["Death Mountain Crater Warp"] = function () return has_tunic_goron_strict() and (is_adult() or setting('fireChild') or has_hover_boots() or climb_anywhere() or hookshot_anywhere()) end,
        },
    },
    ["Death Mountain Crater Generic Grotto"] = {
        ["events"] = {
            ["BOMBS_OR_BOMBCHU"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Death Mountain Crater Top"] = function () return true end,
        },
        ["locations"] = {
            ["Death Mountain Crater Grotto"] = function () return true end,
            ["Death Mountain Crater Grotto Grass 1"] = function () return can_cut_grass() end,
            ["Death Mountain Crater Grotto Grass 2"] = function () return can_cut_grass() end,
            ["Death Mountain Crater Grotto Grass 3"] = function () return can_cut_grass() end,
            ["Death Mountain Crater Grotto Grass 4"] = function () return can_cut_grass() end,
        },
    },
    ["Death Mountain Crater Scrub Grotto"] = {
        ["exits"] = {
            ["Death Mountain Crater Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Death Mountain Crater Grotto Left Scrub"] = function () return business_scrub(15) end,
            ["Death Mountain Crater Grotto Center Scrub"] = function () return business_scrub(16) end,
            ["Death Mountain Crater Grotto Right Scrub"] = function () return business_scrub(17) end,
        },
    },
    ["Fairy Fountain Double Magic"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Death Mountain Crater Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Magic Upgrade 2"] = function () return can_play_zelda() end,
        },
    },
    ["Gerudo Valley"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return is_child() end,
            ["SEEDS"] = function () return is_child() end,
            ["MAGIC"] = function () return is_child() end,
            ["BUGS"] = function () return is_child() and has_bottle() end,
        },
        ["exits"] = {
            ["Gerudo Valley Falls"] = function () return true end,
            ["Hyrule Field"] = function () return true end,
            ["Gerudo Valley After Bridge"] = function () return can_longshot() or can_ride_epona() or (is_adult() and carpenters_rescued()) or (is_child() and (has_hover_boots() and trick('OOT_VALLEY_GATE_HOVER') or can_hookshot())) or time_travel_at_will() end,
            ["Octorok Grotto Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Valley Crate HP"] = function () return is_child() or can_longshot() or climb_anywhere() end,
            ["Gerudo Valley Waterfall HP"] = function () return true end,
            ["Gerudo Valley GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Gerudo Valley GS Wall"] = function () return is_child() and gs_night() and (can_collect_distance() or (climb_anywhere() and (can_use_sword_master() or (age_sword_adult() and has('SWORD_BIGGORON')) or has_explosives() or can_use_din() or can_use_sticks() or can_use_slingshot()))) end,
            ["Gerudo Valley Cow"] = function () return is_child() and can_play_epona() end,
        },
    },
    ["Gerudo Valley After Bridge"] = {
        ["exits"] = {
            ["Gerudo Valley Falls"] = function () return true end,
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Valley"] = function () return is_child() or can_longshot() or can_ride_epona() or (is_adult() and carpenters_rescued()) or climb_anywhere() end,
            ["Gerudo Valley Storms Grotto"] = function () return hidden_grotto_storms() and is_adult() end,
            ["Gerudo Valley Tent"] = function () return is_adult() or trick('OOT_TENT_CHILD') end,
        },
        ["locations"] = {
            ["Gerudo Valley Chest"] = function () return is_adult() and (can_hammer() or hookshot_anywhere() or climb_anywhere()) or time_travel_at_will() end,
            ["Gerudo Valley Broken Goron Sword"] = function () return adult_trade(POACHER_SAW) and soul_carpenters() end,
            ["Gerudo Valley GS Tent"] = function () return is_adult() and gs_night() and (can_collect_distance() or (climb_anywhere() and (has_explosives() or has('SWORD_BIGGORON') or has_ranged_weapon() or can_use_din()))) end,
            ["Gerudo Valley GS Pillar"] = function () return is_adult() and can_collect_distance() and gs_night() end,
            ["Gerudo Valley Crate HP"] = function () return climb_anywhere() end,
        },
    },
    ["Octorok Grotto Ledge"] = {
        ["exits"] = {
            ["Gerudo Valley Falls"] = function () return true end,
            ["Gerudo Valley"] = function () return climb_anywhere() end,
            ["Octorok Grotto"] = function () return can_lift_silver() end,
        },
        ["locations"] = {
            ["Gerudo Valley Crate HP"] = function () return can_longshot() end,
        },
    },
    ["Octorok Grotto"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Octorok Grotto Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Valley Octorok Grotto Rupee 1"] = function () return true end,
            ["Gerudo Valley Octorok Grotto Rupee 2"] = function () return true end,
            ["Gerudo Valley Octorok Grotto Rupee 3"] = function () return true end,
            ["Gerudo Valley Octorok Grotto Rupee 4"] = function () return true end,
            ["Gerudo Valley Octorok Grotto Rupee 5"] = function () return true end,
            ["Gerudo Valley Octorok Grotto Rupee 6"] = function () return true end,
            ["Gerudo Valley Octorok Grotto Rupee 7"] = function () return true end,
            ["Gerudo Valley Octorok Grotto Rupee 8"] = function () return true end,
        },
    },
    ["Gerudo Valley Falls"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
    },
    ["Gerudo Valley Storms Grotto"] = {
        ["exits"] = {
            ["Gerudo Valley After Bridge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Valley Grotto Front Scrub"] = function () return business_scrub(23) end,
            ["Gerudo Valley Grotto Back Scrub"] = function () return business_scrub(24) end,
        },
    },
    ["Gerudo Valley Tent"] = {
        ["exits"] = {
            ["Gerudo Valley After Bridge"] = function () return true end,
        },
    },
    ["Gerudo Fortress Exterior"] = {
        ["events"] = {
            ["OPEN_FORTRESS_GATE"] = function () return has('GERUDO_CARD') and is_adult() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Carpenter 1 Left"] = function () return true end,
            ["Gerudo Fortress Carpenter 1 Right"] = function () return true end,
            ["Gerudo Fortress Kitchen Tunnel End"] = function () return true end,
            ["Gerudo Fortress Carpenter 2 Bottom"] = function () return true end,
            ["Gerudo Valley After Bridge"] = function () return true end,
            ["Fortress Near Wasteland"] = function () return event('OPEN_FORTRESS_GATE') or climb_anywhere() or hookshot_anywhere() end,
            ["Gerudo Training Grounds"] = function () return has('GERUDO_CARD') and can_use_wallet(1) and (is_adult() or (time_travel_at_will() and trick('OOT_GTG_CHILD_TT'))) end,
            ["Gerudo Fortress Grotto"] = function () return is_adult() and hidden_grotto_storms() end,
            ["Gerudo Fortress Lower-Right Ledge"] = function () return is_child() or evade_gerudo() end,
        },
        ["locations"] = {
            ["Gerudo Fortress Archery Reward 1"] = function () return can_ride_epona() and can_use_bow() and has('GERUDO_CARD') and can_use_wallet(1) and is_day() end,
            ["Gerudo Fortress Archery Reward 2"] = function () return can_ride_epona() and can_use_bow() and has('GERUDO_CARD') and can_use_wallet(1) and is_day() end,
            ["Gerudo Fortress GS Target"] = function () return is_adult() and gs_night() and (has('GERUDO_CARD') or time_travel_at_will()) and (can_collect_distance() or climb_anywhere()) end,
        },
    },
    ["Gerudo Fortress Lower-Right Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Kitchen Tunnel Mid"] = function () return true end,
            ["Gerudo Fortress Carpenter 4 Bottom"] = function () return true end,
        },
    },
    ["Gerudo Fortress Lower-Center Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Lower-Right Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 2 Top"] = function () return true end,
            ["Gerudo Fortress Carpenter 4 Top"] = function () return true end,
            ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = function () return true end,
            ["Gerudo Fortress Upper-Right Ledge"] = function () return trick('OOT_FORTRESS_JUMPS') and is_adult() or climb_anywhere() or hookshot_anywhere() end,
        },
    },
    ["Gerudo Fortress Upper-Center Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = function () return true end,
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Upper-Right Ledge"] = function () return is_adult() or trick('OOT_FORTRESS_JUMPS') or climb_anywhere() or hookshot_anywhere() end,
            ["Gerudo Fortress Upper-Left Ledge"] = function () return can_longshot() or climb_anywhere() or hookshot_anywhere() end,
            ["Gerudo Fortress Center Ledge"] = function () return true end,
        },
    },
    ["Gerudo Fortress Upper-Right Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Lower-Right Ledge"] = function () return true end,
            ["Gerudo Fortress Upper-Left Ledge"] = function () return is_adult() and scarecrow_hookshot() or can_longshot() or has_hover_boots() or climb_anywhere() or hookshot_anywhere() or glitch_megaflip() end,
            ["Gerudo Fortress Center Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress GS Wall"] = function () return is_adult() and gs_night() and (can_collect_distance() or climb_anywhere()) end,
        },
    },
    ["Gerudo Fortress Upper-Left Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Left Ledge"] = function () return true end,
            ["Gerudo Fortress Center Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Chest"] = function () return true end,
        },
    },
    ["Gerudo Fortress Center Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Carpenter 3"] = function () return true end,
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
        },
    },
    ["Gerudo Fortress Lower-Left Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Break Room Bottom"] = function () return true end,
            ["Gerudo Fortress Above Prison"] = function () return climb_anywhere() or longshot_anywhere() end,
        },
    },
    ["Gerudo Fortress Above Prison"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Lower-Left Ledge"] = function () return true end,
        },
    },
    ["Fortress Near Wasteland"] = {
        ["events"] = {
            ["OPEN_FORTRESS_GATE"] = function () return has('GERUDO_CARD') and is_adult() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return event('OPEN_FORTRESS_GATE') or climb_anywhere() or hookshot_anywhere() end,
            ["Haunted Wasteland Start"] = function () return true end,
        },
    },
    ["Gerudo Fortress Grotto"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Fairy Fountain Fairy 1"] = function () return true end,
            ["Gerudo Fortress Fairy Fountain Fairy 2"] = function () return true end,
            ["Gerudo Fortress Fairy Fountain Fairy 3"] = function () return true end,
            ["Gerudo Fortress Fairy Fountain Fairy 4"] = function () return true end,
            ["Gerudo Fortress Fairy Fountain Fairy 5"] = function () return true end,
            ["Gerudo Fortress Fairy Fountain Fairy 6"] = function () return true end,
            ["Gerudo Fortress Fairy Fountain Fairy 7"] = function () return true end,
            ["Gerudo Fortress Fairy Fountain Fairy 8"] = function () return true end,
        },
    },
    ["Haunted Wasteland Start"] = {
        ["exits"] = {
            ["Fortress Near Wasteland"] = function () return true end,
            ["Haunted Wasteland Structure"] = function () return can_longshot() or has_hover_boots() or trick('OOT_SAND_RIVER_NOTHING') end,
        },
    },
    ["Haunted Wasteland Structure"] = {
        ["events"] = {
            ["BOMBCHU"] = function () return soul_carpet_man() and can_use_wallet(2) end,
        },
        ["exits"] = {
            ["Haunted Wasteland Start"] = function () return can_longshot() or has_hover_boots() or trick('OOT_SAND_RIVER_NOTHING') end,
            ["Haunted Wasteland End"] = function () return has_lens_strict() or trick('OOT_BLIND_WASTELAND') end,
        },
        ["locations"] = {
            ["Haunted Wasteland Chest"] = function () return has_fire() end,
            ["Haunted Wasteland GS"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_explosives() or can_use_sword() or can_use_sticks() or can_use_din()))) end,
            ["Haunted Wasteland Pot 1"] = function () return true end,
            ["Haunted Wasteland Pot 2"] = function () return true end,
            ["Haunted Wasteland Pot 3"] = function () return true end,
            ["Haunted Wasteland Pot 4"] = function () return true end,
        },
    },
    ["Haunted Wasteland End"] = {
        ["exits"] = {
            ["Haunted Wasteland Structure"] = function () return trick('OOT_BLIND_WASTELAND') end,
            ["Desert Colossus"] = function () return true end,
        },
    },
    ["Desert Colossus"] = {
        ["events"] = {
            ["BEAN_DESERT_COLOSSUS"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Spirit Temple"] = function () return true end,
            ["Haunted Wasteland End"] = function () return true end,
            ["Fairy Fountain Nayru"] = function () return has_explosives() end,
            ["Desert Colossus Grotto"] = function () return can_lift_silver() end,
            ["Spirit Temple Adult Hand"] = function () return climb_anywhere() end,
            ["Spirit Temple Child Hand"] = function () return climb_anywhere() end,
            ["Desert Colossus Oasis"] = function () return can_play_storms() end,
        },
        ["locations"] = {
            ["Desert Colossus HP"] = function () return can_ride_bean(BEAN_DESERT_COLOSSUS) end,
            ["Desert Colossus GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Desert Colossus GS Tree"] = function () return is_adult() and gs_night() and (can_collect_distance() or (climb_anywhere() and (has_explosives() or has_ranged_weapon() or can_use_din()))) end,
            ["Desert Colossus GS Plateau"] = function () return is_adult() and gs_night() and (can_collect_distance() and trick('OOT_COLOSSUS_GS_NO_BEAN') or can_ride_bean(BEAN_DESERT_COLOSSUS)) end,
        },
    },
    ["Desert Colossus Oasis"] = {
        ["locations"] = {
            ["Desert Colossus Oasis Fairy 1"] = function () return true end,
            ["Desert Colossus Oasis Fairy 2"] = function () return true end,
            ["Desert Colossus Oasis Fairy 3"] = function () return true end,
            ["Desert Colossus Oasis Fairy 4"] = function () return true end,
            ["Desert Colossus Oasis Fairy 5"] = function () return true end,
            ["Desert Colossus Oasis Fairy 6"] = function () return true end,
            ["Desert Colossus Oasis Fairy 7"] = function () return true end,
            ["Desert Colossus Oasis Fairy 8"] = function () return true end,
        },
    },
    ["Desert Colossus Spirit Exit"] = {
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Desert Colossus Song Spirit"] = function () return soul_npc(SOUL_NPC_SHEIK) end,
        },
    },
    ["Fairy Fountain Nayru"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Nayru's Love"] = function () return can_play_zelda() end,
        },
    },
    ["Desert Colossus Grotto"] = {
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Desert Colossus Grotto Front Scrub"] = function () return business_scrub(25) end,
            ["Desert Colossus Grotto Back Scrub"] = function () return business_scrub(26) end,
        },
    },
    ["Shadow Temple"] = {
        ["exits"] = {
            ["Graveyard Upper"] = function () return true end,
            ["Shadow Temple Pit"] = function () return has_hover_boots() or can_hookshot() or climb_anywhere() or glitch_megaflip() end,
        },
    },
    ["Shadow Temple Wallmaster"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Shadow Temple Pit"] = {
        ["events"] = {
            ["MAGIC"] = function () return trick('OOT_LENS') end,
        },
        ["exits"] = {
            ["Shadow Temple Main"] = function () return (has_hover_boots() or hookshot_anywhere() or glitch_megaflip()) and has_lens() end,
        },
        ["locations"] = {
            ["Shadow Temple Map"] = function () return soul_redead_gibdo() and soul_keese() and has_lens() and (has_weapon() or can_use_sticks() or can_use_din() or can_hammer()) end,
            ["Shadow Temple Hover Boots"] = function () return soul_enemy(SOUL_ENEMY_DEAD_HAND) and has_lens() and (has_weapon() or (can_use_sticks() and trick('OOT_DEAD_HAND_STICKS'))) end,
            ["Shadow Temple Pot Early Maze 1"] = function () return has_lens() end,
            ["Shadow Temple Pot Early Maze 2"] = function () return has_lens() end,
            ["Shadow Temple Pot Early Maze 3"] = function () return has_lens() end,
            ["Shadow Temple Pot Early Maze 4"] = function () return has_lens() end,
            ["Shadow Temple Pot Early Maze 5"] = function () return has_lens() end,
            ["Shadow Temple Pot Early Maze 6"] = function () return has_lens() end,
            ["Shadow Temple Pot Map Room 1"] = function () return has_lens() end,
            ["Shadow Temple Pot Map Room 2"] = function () return has_lens() end,
            ["Shadow Temple Flying Pot Early Maze"] = function () return has_lens() and soul_flying_pot() end,
        },
    },
    ["Shadow Temple Main"] = {
        ["exits"] = {
            ["Shadow Temple Open"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), small_keys_shadow(4), small_keys_shadow(1)) and has_explosives() end,
            ["Shadow Temple Scythe Silver Rupees"] = function () return true end,
        },
        ["locations"] = {
            ["Shadow Temple Compass"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_sticks() or can_use_din() or can_hammer()) end,
            ["Shadow Temple Beamos Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Shadow Temple Scythe Silver Rupees"] = {
        ["exits"] = {
            ["Shadow Temple Main"] = function () return true end,
            ["Shadow Temple Boat"] = function () return climb_anywhere() and trick('OOT_SHADOW_BOAT_EARLY') or event('SHADOW_SHORTCUT') end,
        },
        ["locations"] = {
            ["Shadow Temple SR Scythe 1"] = function () return true end,
            ["Shadow Temple SR Scythe 2"] = function () return can_hookshot() or (is_adult() and has_hover_boots()) or climb_anywhere() end,
            ["Shadow Temple SR Scythe 3"] = function () return true end,
            ["Shadow Temple SR Scythe 4"] = function () return true end,
            ["Shadow Temple SR Scythe 5"] = function () return true end,
            ["Shadow Temple Silver Rupees"] = function () return silver_rupees_shadow_scythe() end,
        },
    },
    ["Shadow Temple Open"] = {
        ["events"] = {
            ["SHADOW_INVISIBLE_SCYTHE_GATE"] = function () return soul_like_like() and soul_keese() and (has_ranged_weapon_adult() or can_use_slingshot() or can_use_sticks() or has_explosives_or_hammer() or has_weapon()) end,
        },
        ["exits"] = {
            ["Shadow Temple Falling Spikes"] = function () return silver_rupees_shadow_pit() end,
            ["Shadow Temple Invisible Spikes"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), small_keys_shadow(4), small_keys_shadow(2)) end,
            ["Shadow Temple Wallmaster"] = function () return soul_wallmaster() end,
        },
        ["locations"] = {
            ["Shadow Temple Spinning Blades Visible"] = function () return event('SHADOW_INVISIBLE_SCYTHE_GATE') end,
            ["Shadow Temple Spinning Blades Invisible"] = function () return event('SHADOW_INVISIBLE_SCYTHE_GATE') end,
            ["Shadow Temple GS Invisible Scythe"] = function () return gs() and event('SHADOW_INVISIBLE_SCYTHE_GATE') and (can_collect_distance() or climb_anywhere()) end,
            ["Shadow Temple SR Pit 1"] = function () return true end,
            ["Shadow Temple SR Pit 2"] = function () return true end,
            ["Shadow Temple SR Pit 3"] = function () return true end,
            ["Shadow Temple SR Pit 4"] = function () return true end,
            ["Shadow Temple SR Pit 5"] = function () return true end,
            ["Shadow Temple Stalfos Big Fairy"] = function () return can_play_storms() end,
            ["Shadow Temple Heart Scythe 1"] = function () return can_play_time() and is_adult() or can_boomerang() or hookshot_anywhere() or climb_anywhere() end,
            ["Shadow Temple Heart Scythe 2"] = function () return can_play_time() and is_adult() or can_boomerang() or hookshot_anywhere() or climb_anywhere() end,
        },
    },
    ["Shadow Temple Falling Spikes"] = {
        ["locations"] = {
            ["Shadow Temple Falling Spikes Lower"] = function () return true end,
            ["Shadow Temple Falling Spikes Upper 1"] = function () return is_adult() and has_goron_bracelet() or climb_anywhere() or hookshot_anywhere() end,
            ["Shadow Temple Falling Spikes Upper 2"] = function () return is_adult() and has_goron_bracelet() or climb_anywhere() or hookshot_anywhere() end,
            ["Shadow Temple GS Falling Spikes"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and can_damage_skull())) end,
            ["Shadow Temple Pot Falling Spikes Bottom 1"] = function () return true end,
            ["Shadow Temple Pot Falling Spikes Bottom 2"] = function () return true end,
            ["Shadow Temple Pot Falling Spikes Top 1"] = function () return is_adult() and has_goron_bracelet() or climb_anywhere() or hookshot_anywhere() end,
            ["Shadow Temple Pot Falling Spikes Top 2"] = function () return is_adult() and has_goron_bracelet() or climb_anywhere() or hookshot_anywhere() end,
        },
    },
    ["Shadow Temple Invisible Spikes"] = {
        ["exits"] = {
            ["Shadow Temple Open"] = function () return small_keys_shadow(4) end,
            ["Shadow Temple Wind Front"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), small_keys_shadow(4), small_keys_shadow(3) and (is_adult() and soul_redead_gibdo() and can_hookshot() or can_longshot())) end,
            ["Shadow Temple Skull Pot"] = function () return silver_rupees_shadow_spikes() end,
        },
        ["locations"] = {
            ["Shadow Temple SR Spikes Back Left"] = function () return has_lens() and (can_hookshot() or climb_anywhere()) end,
            ["Shadow Temple SR Spikes Right"] = function () return can_hookshot() or climb_anywhere() end,
            ["Shadow Temple SR Spikes Center"] = function () return true end,
            ["Shadow Temple SR Spikes Front Left"] = function () return can_hookshot() or climb_anywhere() end,
            ["Shadow Temple SR Spikes Midair"] = function () return has_lens() and (can_hookshot() or climb_anywhere()) and (has_weapon() or can_use_sticks() or can_hammer() or has_hover_boots() or longshot_anywhere()) end,
            ["Shadow Temple Invisible Spike Room"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_sticks() or can_use_din() or can_hammer()) end,
        },
    },
    ["Shadow Temple Skull Pot"] = {
        ["locations"] = {
            ["Shadow Temple Skull"] = function () return has_bombflowers() end,
            ["Shadow Temple GS Skull Pot"] = function () return gs() and (can_damage_skull() or has_goron_bracelet()) end,
        },
    },
    ["Shadow Temple Wind Front"] = {
        ["exits"] = {
            ["Shadow Temple Wind Back"] = function () return true end,
            ["Shadow Temple Invisible Spikes"] = function () return small_keys_shadow(4) end,
        },
    },
    ["Shadow Temple Wind Back"] = {
        ["exits"] = {
            ["Shadow Temple Wind Gibdo"] = function () return true end,
            ["Shadow Temple Wind Front"] = function () return climb_anywhere() or can_hookshot() end,
        },
        ["locations"] = {
            ["Shadow Temple Wind Room Hint"] = function () return true end,
        },
    },
    ["Shadow Temple Wind Gibdo"] = {
        ["exits"] = {
            ["Shadow Temple Boat"] = function () return small_keys_shadow(4) end,
            ["Shadow Temple Wind Back"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_din() or can_use_sticks() or can_hammer()) end,
        },
        ["locations"] = {
            ["Shadow Temple After Wind"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_din() or can_use_sticks() or can_hammer()) end,
            ["Shadow Temple After Wind Invisible"] = function () return has_explosives() end,
            ["Shadow Temple Pot After Wind 1"] = function () return true end,
            ["Shadow Temple Pot After Wind 2"] = function () return true end,
            ["Shadow Temple Flying Pot After Wind 1"] = function () return soul_flying_pot() end,
            ["Shadow Temple Flying Pot After Wind 2"] = function () return soul_flying_pot() end,
            ["Shadow Temple Big Fairy After Wind"] = function () return can_play_sun() end,
        },
    },
    ["Shadow Temple Boat"] = {
        ["events"] = {
            ["SHADOW_SHORTCUT"] = function () return has_goron_bracelet() end,
        },
        ["exits"] = {
            ["Shadow Temple After Boat"] = function () return can_play_zelda() and (can_hookshot() or climb_anywhere() or (is_adult() and event('SHADOW_SHORTCUT'))) end,
            ["Shadow Temple Wind Gibdo"] = function () return small_keys_shadow(4) end,
            ["Shadow Temple Scythe Silver Rupees"] = function () return event('SHADOW_SHORTCUT') or (climb_anywhere() and trick('OOT_SHADOW_BOAT_EARLY')) end,
        },
        ["locations"] = {
            ["Shadow Temple GS Near Boat"] = function () return gs() and (can_longshot() or hookshot_anywhere() or (climb_anywhere() and (has_weapon() or has_ranged_weapon() or has_explosives() or can_use_din()))) end,
            ["Shadow Temple Heart Shortcut 1"] = function () return scarecrow_longshot() or hookshot_anywhere() or climb_anywhere() end,
            ["Shadow Temple Heart Shortcut 2"] = function () return scarecrow_longshot() or hookshot_anywhere() or climb_anywhere() end,
        },
    },
    ["Shadow Temple After Boat"] = {
        ["events"] = {
            ["SHADOW_PILLAR"] = function () return can_use_bow() or (has_bombflowers() and (scarecrow_longshot() or climb_anywhere() or longshot_anywhere())) end,
        },
        ["exits"] = {
            ["Shadow Temple Boss"] = function () return small_keys_shadow(5) and boss_key(BOSS_KEY_SHADOW) and (can_use_bow() or scarecrow_longshot() or climb_anywhere() or event('SHADOW_PILLAR')) and (has_hover_boots() or climb_anywhere() or hookshot_anywhere() or glitch_megaflip()) end,
        },
        ["locations"] = {
            ["Shadow Temple Boss Key Room 1"] = function () return can_use_din() or climb_anywhere() or hookshot_anywhere() end,
            ["Shadow Temple Boss Key Room 2"] = function () return can_use_din() or climb_anywhere() or hookshot_anywhere() end,
            ["Shadow Temple Invisible Floormaster"] = function () return soul_floormaster() and (has_weapon() or can_hit_triggers_distance() or can_use_din() or can_use_sticks() or can_hammer()) end,
            ["Shadow Temple GS Triple Skull Pot"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (has_ranged_weapon() or has_weapon() or can_use_sticks() or can_use_din() or has_bombflowers()))) end,
            ["Shadow Temple Pot Boss Key Room"] = function () return true end,
            ["Shadow Temple Pot Invisible Floormaster Room 1"] = function () return true end,
            ["Shadow Temple Pot Invisible Floormaster Room 2"] = function () return true end,
            ["Shadow Temple Pot Boat Before Bridge 1"] = function () return true end,
            ["Shadow Temple Pot Boat Before Bridge 2"] = function () return true end,
            ["Shadow Temple Pot Boat After Bridge 1"] = function () return can_use_bow() or scarecrow_longshot() or climb_anywhere() end,
            ["Shadow Temple Pot Boat After Bridge 2"] = function () return can_use_bow() or scarecrow_longshot() or climb_anywhere() end,
            ["Shadow Temple Heart Pre-Boss 1"] = function () return scarecrow_longshot() or climb_anywhere() end,
            ["Shadow Temple Heart Pre-Boss 2"] = function () return scarecrow_longshot() or climb_anywhere() end,
            ["Shadow Temple Heart Pre-Boss 3"] = function () return scarecrow_longshot() or climb_anywhere() end,
        },
    },
    ["Spirit Temple"] = {
        ["events"] = {
            ["SPIRIT_CHILD_DOOR"] = function () return is_child() and small_keys_spirit(5) end,
            ["SPIRIT_ADULT_DOOR"] = function () return can_lift_silver() and cond(setting('agelessBoots') or setting('agelessHookshot') or setting('agelessStrength') or (not setting('climbMostSurfacesOot', 'off')) or (not setting('ageChange', 'none')), small_keys_spirit(5), small_keys_spirit(3)) end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Desert Colossus Spirit Exit"] = function () return true end,
            ["Spirit Temple Child Entrance"] = function () return is_child() end,
            ["Spirit Temple Adult Entrance"] = function () return can_lift_silver() end,
        },
        ["locations"] = {
            ["Spirit Temple Pot Lobby 1"] = function () return true end,
            ["Spirit Temple Pot Lobby 2"] = function () return true end,
            ["Spirit Temple Flying Pot Lobby 1"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Lobby 2"] = function () return soul_flying_pot() end,
        },
    },
    ["Spirit Temple Wallmaster Child Rupees"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Spirit Temple Wallmaster Adult Climb"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Spirit Temple Child Entrance"] = {
        ["exits"] = {
            ["Spirit Temple"] = function () return is_child() end,
            ["Spirit Temple Child Climb"] = function () return is_child() and cond(not setting('climbMostSurfacesOot', 'off'), small_keys_spirit(1) and can_reflect_light() and has_explosives() or small_keys_spirit(2), small_keys_spirit(1)) end,
            ["Spirit Temple Child Left"] = function () return soul_keese() and soul_armos() and (can_use_sticks() or has_explosives_or_hammer() or ((can_boomerang() or has_nuts()) and (has_weapon() or can_use_slingshot())) or time_travel_at_will()) end,
            ["Spirit Temple Child Right"] = function () return soul_keese() and soul_armos() and (can_use_sticks() or has_explosives_or_hammer() or ((can_boomerang() or has_nuts()) and (has_weapon() or can_use_slingshot())) or time_travel_at_will()) end,
        },
    },
    ["Spirit Temple Child Left"] = {
        ["exits"] = {
            ["Spirit Temple Child Entrance"] = function () return true end,
            ["Spirit Temple Child Back Left"] = function () return has_ranged_weapon_child() or hookshot_anywhere() or climb_anywhere() or (can_hookshot() and can_jump_slash()) or can_longshot() end,
        },
    },
    ["Spirit Temple Child Right"] = {
        ["events"] = {
            ["SPIRIT_CHEST_CHILD"] = function () return has_fire_or_sticks() end,
        },
        ["exits"] = {
            ["Spirit Temple Child Entrance"] = function () return true end,
            ["Spirit Temple Child Back Right"] = function () return silver_rupees_spirit_child() end,
        },
        ["locations"] = {
            ["Spirit Temple GS Child Fence"] = function () return gs() and (can_collect_distance() or (climb_anywhere() and (can_use_din() or has_ranged_weapon() or has_explosives()))) end,
        },
    },
    ["Spirit Temple Child Back Left"] = {
        ["exits"] = {
            ["Spirit Temple Child Back Right"] = function () return soul_enemy(SOUL_ENEMY_ANUBIS) end,
        },
        ["locations"] = {
            ["Spirit Temple Child First Chest"] = function () return true end,
            ["Spirit Temple Flying Pot Child After Bridge 1"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Child After Bridge 2"] = function () return soul_flying_pot() end,
            ["Spirit Temple Pot Child Anubis Room 1"] = function () return true end,
            ["Spirit Temple Pot Child Anubis Room 2"] = function () return true end,
            ["Spirit Temple Pot Child Anubis Room 3"] = function () return true end,
            ["Spirit Temple Pot Child Anubis Room 4"] = function () return true end,
        },
    },
    ["Spirit Temple Child Back Right"] = {
        ["exits"] = {
            ["Spirit Temple Child Back Left"] = function () return soul_enemy(SOUL_ENEMY_ANUBIS) end,
            ["Spirit Temple Wallmaster Child Rupees"] = function () return soul_wallmaster() end,
        },
        ["locations"] = {
            ["Spirit Temple Child Second Chest"] = function () return event('SPIRIT_CHEST_CHILD') end,
            ["Spirit Temple GS Child Fence"] = function () return gs() and ((has_ranged_weapon() or has_explosives() or can_use_din() or can_use_sticks() or can_use_sword_master() or (age_sword_adult() and has('SWORD_BIGGORON'))) and silver_rupees_spirit_child()) end,
            ["Spirit Temple SR Child 1"] = function () return true end,
            ["Spirit Temple SR Child 2"] = function () return true end,
            ["Spirit Temple SR Child 3"] = function () return true end,
            ["Spirit Temple SR Child 4"] = function () return true end,
            ["Spirit Temple SR Child 5"] = function () return true end,
            ["Spirit Temple Pot Child Anubis Room 1"] = function () return true end,
            ["Spirit Temple Pot Child Anubis Room 2"] = function () return true end,
            ["Spirit Temple Pot Child Anubis Room 3"] = function () return true end,
            ["Spirit Temple Pot Child Anubis Room 4"] = function () return true end,
        },
    },
    ["Spirit Temple Child Climb"] = {
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return has_explosives() end,
        },
        ["locations"] = {
            ["Spirit Temple Child Climb 1"] = function () return has_ranged_weapon_both() or (climb_anywhere() and (has_weapon() or can_use_sticks() or can_hammer())) or (event('SPIRIT_CHILD_DOOR') and (has_ranged_weapon_child() or can_hookshot())) or (event('SPIRIT_ADULT_DOOR') and (has_ranged_weapon_adult() or can_boomerang())) end,
            ["Spirit Temple Child Climb 2"] = function () return has_ranged_weapon_both() or (climb_anywhere() and (has_weapon() or can_use_sticks() or can_hammer())) or (event('SPIRIT_CHILD_DOOR') and (has_ranged_weapon_child() or can_hookshot())) or (event('SPIRIT_ADULT_DOOR') and (has_ranged_weapon_adult() or can_boomerang())) end,
            ["Spirit Temple GS Child Climb"] = function () return gs() and (has_weapon() or has_ranged_weapon() or has_explosives() or can_use_sticks() or can_use_din() or (has_hover_boots() and can_hammer())) end,
            ["Spirit Temple Pot Child Climb"] = function () return true end,
        },
    },
    ["Spirit Temple Child Upper"] = {
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return true end,
            ["Spirit Temple Child Hand"] = function () return small_keys_spirit(5) and soul_iron_knuckle() end,
        },
        ["locations"] = {
            ["Spirit Temple Sun Block Room Torches"] = function () return event('SPIRIT_CHILD_DOOR') and can_use_sticks() and silver_rupees_spirit_sun() or (has_fire_spirit() and silver_rupees_spirit_sun()) or can_use_din() or (has_fire_arrows() and event('SPIRIT_ADULT_DOOR')) end,
            ["Spirit Temple SR Sun 1"] = function () return true end,
            ["Spirit Temple SR Sun 2"] = function () return true end,
            ["Spirit Temple SR Sun 3"] = function () return true end,
            ["Spirit Temple SR Sun 4"] = function () return true end,
            ["Spirit Temple SR Sun 5"] = function () return true end,
            ["Spirit Temple GS Iron Knuckle"] = function () return gs() and (event('SPIRIT_CHILD_DOOR') and has_explosives() and can_collect_distance() or (event('SPIRIT_ADULT_DOOR') and can_collect_distance()) or cond(not setting('climbMostSurfacesOot', 'off'), (has_explosives() and can_reflect_light() and small_keys_spirit(1) or small_keys_spirit(3)) and (can_collect_distance() or has_ranged_weapon() or has_explosives() or can_use_din()), can_collect_ageless() and (has_explosives() or small_keys_spirit(2)))) end,
            ["Spirit Temple Pot Child Hand Stairway 1"] = function () return true end,
            ["Spirit Temple Pot Child Hand Stairway 2"] = function () return true end,
        },
    },
    ["Spirit Temple Child Hand"] = {
        ["exits"] = {
            ["Spirit Temple Child Upper"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and can_reflect_light() and small_keys_spirit(1) or small_keys_spirit(3), small_keys_spirit(5)) end,
            ["Spirit Temple Adult Hand"] = function () return longshot_anywhere() end,
            ["Desert Colossus"] = function () return true end,
            ["Spirit Temple"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Silver Gauntlets"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Entrance"] = {
        ["exits"] = {
            ["Spirit Temple Adult Climb"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and can_reflect_light() and small_keys_spirit(1) or small_keys_spirit(3), small_keys_spirit(1)) end,
            ["Spirit Temple Adult Boulders"] = function () return has_ranged_weapon() or can_boomerang() or has_bombchu() end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Lullaby"] = function () return can_play_zelda() and (can_hookshot() or climb_anywhere()) end,
        },
    },
    ["Spirit Temple Adult Boulders"] = {
        ["locations"] = {
            ["Spirit Temple GS Boulders"] = function () return gs() and can_play_time() end,
            ["Spirit Temple Adult Silver Rupees"] = function () return silver_rupees_spirit_boulders() end,
            ["Spirit Temple Adult Silver Rupees Big Fairy"] = function () return silver_rupees_spirit_boulders() and can_play_sun() end,
            ["Spirit Temple SR Boulders 1"] = function () return true end,
            ["Spirit Temple SR Boulders 2"] = function () return true end,
            ["Spirit Temple SR Boulders 3"] = function () return true end,
            ["Spirit Temple SR Boulders 4"] = function () return true end,
            ["Spirit Temple SR Boulders 5"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Climb"] = {
        ["exits"] = {
            ["Spirit Temple Wallmaster Adult Climb"] = function () return soul_wallmaster() end,
            ["Spirit Temple Statue Adult"] = function () return true end,
            ["Spirit Temple Adult Entrance"] = function () return small_keys_spirit(5) end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Suns on Wall 1"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and (has_mirror_shield() or small_keys_spirit(2)) or small_keys_spirit(3) or (has_explosives() and small_keys_spirit(2)), (setting('agelessBoots') and trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots_raw() or (setting('agelessHookshot') and has_hookshot(1))) and has_explosives() or event('SPIRIT_ADULT_DOOR') or (event('SPIRIT_CHILD_DOOR') and (trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots() or can_hookshot())) or (time_travel_at_will() and has_explosives() and (has_hookshot(1) or (has_hover_boots_raw() and trick('OOT_SPIRIT_CHILD_HOVER'))))) end,
            ["Spirit Temple Adult Suns on Wall 2"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and (has_mirror_shield() or small_keys_spirit(2)) or small_keys_spirit(3) or (has_explosives() and small_keys_spirit(2)), (setting('agelessBoots') and trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots_raw() or (setting('agelessHookshot') and has_hookshot(1))) and has_explosives() or event('SPIRIT_ADULT_DOOR') or (event('SPIRIT_CHILD_DOOR') and (trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots() or can_hookshot())) or (time_travel_at_will() and has_explosives() and (has_hookshot(1) or (has_hover_boots_raw() and trick('OOT_SPIRIT_CHILD_HOVER'))))) end,
            ["Spirit Temple Flying Pot Adult Climb 1"] = function () return soul_flying_pot() and cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and (has_mirror_shield() or small_keys_spirit(2)) or small_keys_spirit(3) or (has_explosives() and small_keys_spirit(2)), (setting('agelessBoots') and trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots_raw() or (setting('agelessHookshot') and has_hookshot(1))) and has_explosives() or event('SPIRIT_ADULT_DOOR') or (event('SPIRIT_CHILD_DOOR') and (trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots() or can_hookshot())) or (time_travel_at_will() and has_explosives() and (has_hookshot(1) or (has_hover_boots_raw() and trick('OOT_SPIRIT_CHILD_HOVER'))))) end,
            ["Spirit Temple Flying Pot Adult Climb 2"] = function () return soul_flying_pot() and cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and (has_mirror_shield() or small_keys_spirit(2)) or small_keys_spirit(3) or (has_explosives() and small_keys_spirit(2)), (setting('agelessBoots') and trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots_raw() or (setting('agelessHookshot') and has_hookshot(1))) and has_explosives() or event('SPIRIT_ADULT_DOOR') or (event('SPIRIT_CHILD_DOOR') and (trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots() or can_hookshot())) or (time_travel_at_will() and has_explosives() and (has_hookshot(1) or (has_hover_boots_raw() and trick('OOT_SPIRIT_CHILD_HOVER'))))) end,
        },
    },
    ["Spirit Temple Statue"] = {
        ["exits"] = {
            ["Spirit Temple Statue Adult"] = function () return trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots() or can_hookshot() or climb_anywhere() end,
            ["Spirit Temple Child Climb"] = function () return true end,
            ["Spirit Temple Child Upper"] = function () return true end,
            ["Spirit Temple Boss"] = function () return boss_key(BOSS_KEY_SPIRIT) and event('SPIRIT_LIGHT_STATUE') and (can_hookshot() or (climb_anywhere() and has_hover_boots() and can_jump_slash() and trick('OOT_SPIRIT_BOSS_CLIMB_NO_HOOK'))) end,
        },
        ["locations"] = {
            ["Spirit Temple Statue Base"] = function () return event('SPIRIT_CHILD_DOOR') and has_explosives() and can_use_sticks() or has_fire_spirit() or can_use_din() or (has_fire_arrows() and event('SPIRIT_ADULT_DOOR')) end,
            ["Spirit Temple GS Statue"] = function () return gs() and (event('SPIRIT_ADULT_DOOR') and (is_adult() and scarecrow_hookshot() or has_hover_boots() or can_longshot() or climb_anywhere()) or (event('SPIRIT_CHILD_DOOR') and has_explosives() and (has_hover_boots() or can_hookshot() or climb_anywhere())) or (climb_anywhere() and can_damage_skull())) end,
            ["Spirit Temple Silver Gauntlets"] = function () return small_keys_spirit(3) and has_hookshot(2) and has_explosives() and soul_iron_knuckle() and soul_enemy(SOUL_ENEMY_ANUBIS) and soul_beamos() and (soul_armos() or can_play_elegy()) end,
            ["Spirit Temple Pot Statue Room 1"] = function () return true end,
            ["Spirit Temple Pot Statue Room 2"] = function () return true end,
            ["Spirit Temple Pot Statue Room 3"] = function () return true end,
            ["Spirit Temple Pot Statue Room 4"] = function () return true end,
            ["Spirit Temple Pot Statue Room 5"] = function () return true end,
            ["Spirit Temple Pot Statue Room 6"] = function () return true end,
            ["Spirit Temple Flying Pot Statue Room 1"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Statue Room 2"] = function () return soul_flying_pot() end,
        },
    },
    ["Spirit Temple Statue Adult"] = {
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return true end,
            ["Spirit Temple Adult Climb"] = function () return true end,
            ["Spirit Temple Adult Upper"] = function () return small_keys_spirit(4) end,
        },
        ["locations"] = {
            ["Spirit Temple Statue Hands"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and (has_mirror_shield() or small_keys_spirit(2)) or small_keys_spirit(3) or (has_explosives() and small_keys_spirit(2)), (setting('agelessBoots') and trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots_raw() or (setting('agelessHookshot') and has_hookshot(1))) and has_explosives() or event('SPIRIT_ADULT_DOOR') or (event('SPIRIT_CHILD_DOOR') and (trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots() or can_hookshot())) or (time_travel_at_will() and has_explosives() and (has_hookshot(1) or (has_hover_boots_raw() and trick('OOT_SPIRIT_CHILD_HOVER'))))) and can_play_zelda() end,
            ["Spirit Temple Statue Upper Right"] = function () return cond(not setting('climbMostSurfacesOot', 'off'), has_explosives() and (has_mirror_shield() or small_keys_spirit(2)) or small_keys_spirit(3) or (has_explosives() and small_keys_spirit(2)), (setting('agelessBoots') and trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots_raw() or (setting('agelessHookshot') and has_hookshot(1))) and has_explosives() or (event('SPIRIT_ADULT_DOOR') and (has_hover_boots() or has_hookshot(1))) or (event('SPIRIT_CHILD_DOOR') and (trick('OOT_SPIRIT_CHILD_HOVER') and has_hover_boots() or can_hookshot())) or (time_travel_at_will() and has_explosives() and (has_hookshot(1) or (has_hover_boots_raw() and trick('OOT_SPIRIT_CHILD_HOVER'))))) and can_play_zelda() end,
            ["Spirit Temple Pot Adult Upper"] = function () return small_keys_spirit(4) end,
        },
    },
    ["Spirit Temple Adult Upper"] = {
        ["exits"] = {
            ["Spirit Temple Adult Upper 2"] = function () return has_explosives() and soul_beamos() and soul_enemy(SOUL_ENEMY_ANUBIS) end,
            ["Spirit Temple Adult Climb 2"] = function () return small_keys_spirit(5) end,
            ["Spirit Temple Statue Adult"] = function () return has_explosives() and soul_beamos() and soul_enemy(SOUL_ENEMY_ANUBIS) and (small_keys_spirit(1) and can_reflect_light() or small_keys_spirit(2)) end,
        },
        ["locations"] = {
            ["Spirit Temple Pot Adult Upper"] = function () return has_explosives() and soul_beamos() and soul_enemy(SOUL_ENEMY_ANUBIS) end,
        },
    },
    ["Spirit Temple Adult Upper 2"] = {
        ["exits"] = {
            ["Spirit Temple Adult Upper"] = function () return true end,
            ["Spirit Temple Adult Hand"] = function () return (soul_armos() or can_play_elegy()) and soul_iron_knuckle() end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Late Sun on Wall"] = function () return can_reflect_light() end,
            ["Spirit Temple Adult Invisible 1"] = function () return has_lens() and (soul_armos() or can_play_elegy()) end,
            ["Spirit Temple Adult Invisible 2"] = function () return has_lens() and (soul_armos() or can_play_elegy()) end,
            ["Spirit Temple Adult Sunlight Big Fairy"] = function () return can_play_sun() end,
        },
    },
    ["Spirit Temple Adult Hand"] = {
        ["exits"] = {
            ["Spirit Temple Adult Upper 2"] = function () return soul_iron_knuckle() and (has_weapon() or has_explosives() or can_use_sticks()) end,
            ["Spirit Temple Child Hand"] = function () return can_longshot() end,
            ["Desert Colossus"] = function () return true end,
            ["Spirit Temple"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Mirror Shield"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Climb 2"] = {
        ["events"] = {
            ["SPIRIT_LIGHT_STATUE"] = function () return has_mirror_shield() and has_explosives() end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Boss Key Chest"] = function () return can_play_zelda() and (can_hookshot() and can_hit_triggers_distance() or climb_anywhere() or hookshot_anywhere()) end,
            ["Spirit Temple Adult Topmost Sun on Wall"] = function () return can_reflect_light() end,
            ["Spirit Temple Flying Pot Topmost 1"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Topmost 2"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Topmost 3"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Topmost 4"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Topmost 5"] = function () return soul_flying_pot() end,
            ["Spirit Temple Flying Pot Topmost 6"] = function () return soul_flying_pot() end,
            ["Spirit Temple Heart 1"] = function () return can_hookshot() end,
            ["Spirit Temple Heart 2"] = function () return can_hookshot() end,
        },
    },
    ["Treasure Chest Game"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Treasure Chest Game Room 1"] = function () return small_keys_tcg(1) end,
        },
        ["locations"] = {
            ["Treasure Chest Game Buy Key"] = function () return can_use_wallet(1) and soul_chest_game_owner() end,
        },
    },
    ["Treasure Chest Game Room 1"] = {
        ["exits"] = {
            ["Treasure Chest Game Room 2"] = function () return small_keys_tcg(2) end,
        },
        ["locations"] = {
            ["Treasure Chest Game Room 1 Chest Left"] = function () return true end,
            ["Treasure Chest Game Room 1 Chest Right"] = function () return true end,
        },
    },
    ["Treasure Chest Game Room 2"] = {
        ["exits"] = {
            ["Treasure Chest Game Room 3"] = function () return small_keys_tcg(3) end,
        },
        ["locations"] = {
            ["Treasure Chest Game Room 2 Chest Left"] = function () return true end,
            ["Treasure Chest Game Room 2 Chest Right"] = function () return true end,
        },
    },
    ["Treasure Chest Game Room 3"] = {
        ["exits"] = {
            ["Treasure Chest Game Room 4"] = function () return small_keys_tcg(4) end,
        },
        ["locations"] = {
            ["Treasure Chest Game Room 3 Chest Left"] = function () return true end,
            ["Treasure Chest Game Room 3 Chest Right"] = function () return true end,
        },
    },
    ["Treasure Chest Game Room 4"] = {
        ["exits"] = {
            ["Treasure Chest Game Room 5"] = function () return small_keys_tcg(5) end,
        },
        ["locations"] = {
            ["Treasure Chest Game Room 4 Chest Left"] = function () return true end,
            ["Treasure Chest Game Room 4 Chest Right"] = function () return true end,
        },
    },
    ["Treasure Chest Game Room 5"] = {
        ["exits"] = {
            ["Treasure Chest Game Room 6"] = function () return small_keys_tcg(6) end,
        },
        ["locations"] = {
            ["Treasure Chest Game Room 5 Chest Left"] = function () return true end,
            ["Treasure Chest Game Room 5 Chest Right"] = function () return true end,
        },
    },
    ["Treasure Chest Game Room 6"] = {
        ["locations"] = {
            ["Treasure Chest Game HP"] = function () return true end,
        },
    },
    ["Water Temple"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
            ["Water Temple Main"] = function () return true end,
        },
    },
    ["Water Temple Main"] = {
        ["exits"] = {
            ["Water Temple"] = function () return true end,
            ["Water Temple Ruto Room"] = function () return has_tunic_zora() and (has_iron_boots() or (can_longshot() and trick('OOT_WATER_LONGSHOT'))) end,
            ["Water Temple Center Bottom"] = function () return event('WATER_LEVEL_LOW') and small_keys_water(5) end,
            ["Water Temple Center Middle"] = function () return event('WATER_LEVEL_LOW') and (can_use_din() or can_use_bow()) end,
            ["Water Temple Compass Room"] = function () return has_tunic_zora() and has_iron_boots() and can_hookshot() or (event('WATER_LEVEL_LOW') and (can_hookshot() or climb_anywhere())) end,
            ["Water Temple Dragon Room"] = function () return event('WATER_LEVEL_LOW') and has_goron_bracelet() and can_dive_small() and (has_weapon() or has_ranged_weapon() or has_explosives_or_hammer()) end,
            ["Water Temple Elevator"] = function () return small_keys_water(5) and (can_hookshot() or climb_anywhere()) or can_use_bow() or can_use_din() end,
            ["Water Temple Corridor"] = function () return (can_longshot() or has_hover_boots() or hookshot_anywhere()) and can_hit_triggers_distance() and event('WATER_LEVEL_LOW') end,
            ["Water Temple Waterfalls"] = function () return has_tunic_zora() and small_keys_water(4) and (can_longshot() or climb_anywhere() or hookshot_anywhere()) and (has_iron_boots() or event('WATER_LEVEL_LOW')) end,
            ["Water Temple Large Pit"] = function () return small_keys_water(4) and event('WATER_LEVEL_RESET') end,
            ["Water Temple Antichamber"] = function () return can_longshot() and event('WATER_LEVEL_RESET') or climb_anywhere() end,
            ["Water Temple Cage Room"] = function () return has_tunic_zora() and event('WATER_LEVEL_LOW') and has_explosives() and can_dive_small() end,
            ["Water Temple Main Ledge"] = function () return is_adult() and has_hover_boots() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Water Temple Pot Main Room Near Block 1"] = function () return event('WATER_LEVEL_LOW') or (has_iron_boots() and can_hookshot()) end,
            ["Water Temple Pot Main Room Near Block 2"] = function () return event('WATER_LEVEL_LOW') or (has_iron_boots() and can_hookshot()) end,
            ["Water Temple Pot Main Room Near Boss 1"] = function () return can_longshot() and event('WATER_LEVEL_RESET') or climb_anywhere() end,
            ["Water Temple Pot Main Room Near Boss 2"] = function () return can_longshot() and event('WATER_LEVEL_RESET') or climb_anywhere() end,
        },
    },
    ["Water Temple Main Ledge"] = {
        ["events"] = {
            ["WATER_LEVEL_RESET"] = function () return true end,
        },
        ["exits"] = {
            ["Water Temple Main"] = function () return true end,
        },
    },
    ["Water Temple Ruto Room"] = {
        ["events"] = {
            ["WATER_LEVEL_LOW"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Water Temple Map Room"] = function () return event('WATER_LEVEL_RESET') or climb_anywhere() or longshot_anywhere() end,
            ["Water Temple Shell Room"] = function () return event('WATER_LEVEL_LOW') and (can_use_bow() or has_fire()) end,
        },
        ["locations"] = {
            ["Water Temple Bombable Chest"] = function () return (event('WATER_LEVEL_MIDDLE') or (event('WATER_LEVEL_LOW') and (climb_anywhere() or longshot_anywhere()))) and has_explosives() end,
            ["Water Temple Pot Ruto Room 1"] = function () return event('WATER_LEVEL_LOW') or (has_iron_boots() and can_hookshot()) end,
            ["Water Temple Pot Ruto Room 2"] = function () return event('WATER_LEVEL_LOW') or (has_iron_boots() and can_hookshot()) end,
        },
    },
    ["Water Temple Map Room"] = {
        ["locations"] = {
            ["Water Temple Map"] = function () return soul_enemy(SOUL_ENEMY_SPIKE) end,
        },
    },
    ["Water Temple Shell Room"] = {
        ["locations"] = {
            ["Water Temple Shell Chest"] = function () return soul_shell_blade() end,
        },
    },
    ["Water Temple Center Bottom"] = {
        ["exits"] = {
            ["Water Temple Under Center"] = function () return event('WATER_LEVEL_MIDDLE') and has_iron_boots() and has_tunic_zora_strict() end,
            ["Water Temple Center Middle"] = function () return can_hookshot() or climb_anywhere() end,
        },
    },
    ["Water Temple Center Middle"] = {
        ["events"] = {
            ["WATER_LEVEL_MIDDLE"] = function () return can_play_zelda() end,
        },
        ["exits"] = {
            ["Water Temple Center Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Water Temple GS Center"] = function () return gs() and (can_longshot() or hookshot_anywhere() or (climb_anywhere() and (has_ranged_weapon() or has_bombchu()))) end,
        },
    },
    ["Water Temple Under Center"] = {
        ["locations"] = {
            ["Water Temple Under Center"] = function () return can_hookshot() and soul_enemy(SOUL_ENEMY_SPIKE) and soul_shell_blade() end,
        },
    },
    ["Water Temple Compass Room"] = {
        ["locations"] = {
            ["Water Temple Compass"] = function () return has_weapon() or can_use_sticks() or has_ranged_weapon() or has_explosives_or_hammer() end,
            ["Water Temple Pot Compass Room 1"] = function () return true end,
            ["Water Temple Pot Compass Room 2"] = function () return true end,
            ["Water Temple Pot Compass Room 3"] = function () return true end,
        },
    },
    ["Water Temple Dragon Room"] = {
        ["exits"] = {
            ["Water Temple Dragon Room Ledge"] = function () return climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Water Temple Dragon Chest"] = function () return can_hookshot() and has_iron_boots() end,
        },
    },
    ["Water Temple Elevator"] = {
        ["exits"] = {
            ["Water Temple Main Ledge"] = function () return has_ranged_weapon() or has_explosives() end,
        },
    },
    ["Water Temple Corridor"] = {
        ["locations"] = {
            ["Water Temple Corridor Chest"] = function () return has_goron_bracelet() end,
            ["Water Temple Pot Corridor 1"] = function () return has_goron_bracelet() end,
            ["Water Temple Pot Corridor 2"] = function () return has_goron_bracelet() end,
        },
    },
    ["Water Temple Waterfalls"] = {
        ["exits"] = {
            ["Water Temple Blocks"] = function () return true end,
            ["Water Temple Waterfalls Ledge"] = function () return is_adult() and (has_hover_boots() or climb_anywhere() or hookshot_anywhere()) or (is_child() and (has_iron_boots() and (climb_anywhere() or hookshot_anywhere()))) end,
        },
    },
    ["Water Temple Blocks"] = {
        ["exits"] = {
            ["Water Temple Waterfalls Ledge"] = function () return has_explosives() and has_goron_bracelet() or climb_anywhere() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Water Temple Pot Blocks Room 1"] = function () return true end,
            ["Water Temple Pot Blocks Room 2"] = function () return true end,
        },
    },
    ["Water Temple Waterfalls Ledge"] = {
        ["exits"] = {
            ["Water Temple Boss Key Room"] = function () return small_keys_water(5) and (is_adult() and can_dive_small() or has_iron_boots() or hookshot_anywhere()) end,
        },
        ["locations"] = {
            ["Water Temple GS Waterfalls"] = function () return gs() and (is_adult() or can_collect_distance() or ((can_use_sword_master() or (age_sword_adult() and has('SWORD_BIGGORON')) or can_use_sticks() or has_ranged_weapon() or can_use_din() or (has_hover_boots() and (can_use_sword_kokiri() or can_use_sword_goron() or has_explosives()))) and (has_hover_boots() or climb_anywhere()))) end,
        },
    },
    ["Water Temple Boss Key Room"] = {
        ["locations"] = {
            ["Water Temple Boss Key Chest"] = function () return true end,
            ["Water Temple Pot Boss Key Room 1"] = function () return true end,
            ["Water Temple Pot Boss Key Room 2"] = function () return true end,
        },
    },
    ["Water Temple Large Pit"] = {
        ["exits"] = {
            ["Water Temple Before Dark Link"] = function () return small_keys_water(5) and can_hookshot() end,
        },
        ["locations"] = {
            ["Water Temple GS Large Pit"] = function () return gs() and (can_longshot() or (can_hit_triggers_distance() and climb_anywhere()) or (climb_anywhere() and has_bombchu() and trick('OOT_WATER_PIT_GS_CHU'))) end,
        },
    },
    ["Water Temple Before Dark Link"] = {
        ["exits"] = {
            ["Water Temple Dark Link"] = function () return true end,
        },
        ["locations"] = {
            ["Water Temple Pot Before Dark Link 1"] = function () return true end,
            ["Water Temple Pot Before Dark Link 2"] = function () return true end,
        },
    },
    ["Water Temple Dark Link"] = {
        ["exits"] = {
            ["Water Temple Longshot Room"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() end,
            ["Water Temple Before Dark Link"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() end,
        },
    },
    ["Water Temple Longshot Room"] = {
        ["events"] = {
            ["LONGSHOT_TIME_BLOCK"] = function () return can_play_time() end,
        },
        ["exits"] = {
            ["Water Temple River"] = function () return event('LONGSHOT_TIME_BLOCK') or is_child() end,
            ["Water Temple Dark Link"] = function () return true end,
        },
        ["locations"] = {
            ["Water Temple Longshot"] = function () return true end,
        },
    },
    ["Water Temple River"] = {
        ["exits"] = {
            ["Water Temple Dragon Room Ledge"] = function () return can_hit_triggers_distance() end,
            ["Water Temple Longshot Room"] = function () return longshot_anywhere() and climb_anywhere() and (is_child() or event('LONGSHOT_TIME_BLOCK')) end,
        },
        ["locations"] = {
            ["Water Temple GS River"] = function () return gs() and has_iron_boots() end,
            ["Water Temple Pot River 1"] = function () return true end,
            ["Water Temple Pot River 2"] = function () return true end,
            ["Water Temple Heart 1"] = function () return true end,
            ["Water Temple Heart 2"] = function () return true end,
            ["Water Temple Heart 3"] = function () return true end,
            ["Water Temple Heart 4"] = function () return true end,
        },
    },
    ["Water Temple Dragon Room Ledge"] = {
        ["exits"] = {
            ["Water Temple Dragon Room"] = function () return true end,
            ["Water Temple River"] = function () return hookshot_anywhere() and trick('OOT_WATER_REVERSE_RIVER') end,
        },
        ["locations"] = {
            ["Water Temple River Chest"] = function () return true end,
        },
    },
    ["Water Temple Cage Room"] = {
        ["exits"] = {
            ["Water Temple Inside Cage"] = function () return can_hookshot() or (is_adult() and has_hover_boots()) or climb_anywhere() end,
        },
    },
    ["Water Temple Inside Cage"] = {
        ["locations"] = {
            ["Water Temple GS Cage"] = function () return gs() and (has_weapon() or can_use_sticks()) end,
            ["Water Temple Pot Skull Cage 1"] = function () return has_weapon() or can_use_sticks() end,
            ["Water Temple Pot Skull Cage 2"] = function () return has_weapon() or can_use_sticks() end,
            ["Water Temple Pot Skull Cage 3"] = function () return has_weapon() or can_use_sticks() end,
            ["Water Temple Pot Skull Cage 4"] = function () return has_weapon() or can_use_sticks() end,
        },
    },
    ["Water Temple Antichamber"] = {
        ["exits"] = {
            ["Water Temple Boss"] = function () return boss_key(BOSS_KEY_WATER) end,
        },
    },
}

    MQlogic = {
    ["Bottom of the Well"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Bottom of the Well Main"] = function () return is_child() end,
        },
    },
    ["Bottom of the Well Wallmaster Main"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Bottom of the Well Wallmaster Basement"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Bottom of the Well Wallmaster Pit"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Bottom of the Well Main"] = {
        ["exits"] = {
            ["Bottom of the Well Wallmaster Main"] = function () return soul_wallmaster() and (can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots())) end,
            ["Bottom of the Well Wallmaster Basement"] = function () return soul_wallmaster() end,
            ["Bottom of the Well Wallmaster Pit"] = function () return soul_wallmaster() and (can_hit_triggers_distance() or can_boomerang() or has_explosives() or can_hookshot()) end,
            ["Bottom of the Well"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Bottom of the Well Map Chest"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well Compass Chest"] = function () return soul_enemy(SOUL_ENEMY_DEAD_HAND) and ((has_weapon() or (can_use_sticks() and trick('OOT_DEAD_HAND_STICKS'))) and (has_ranged_weapon_child() or has_explosives() or can_play_zelda())) end,
            ["MQ Bottom of the Well Lens Chest"] = function () return (can_play_zelda() or has_hover_boots()) and small_keys_botw(2) and has_explosives() and (has_weapon() or can_use_sticks() or can_use_din() or has_iron_boots() or can_play_sun()) end,
            ["MQ Bottom of the Well Dead Hand Key"] = function () return has_explosives() end,
            ["MQ Bottom of the Well East Middle Room Key"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well GS Basement"] = function () return gs() and can_damage_skull() end,
            ["MQ Bottom of the Well GS West Middle Room"] = function () return gs() and (can_play_zelda() or has_hover_boots()) and has_explosives() end,
            ["MQ Bottom of the Well GS Coffin Room"] = function () return gs() and can_damage_skull() and small_keys_botw(2) end,
            ["MQ Bottom of the Well Pot Lobby Cage 1"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well Pot Lobby Cage 2"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well Pot Lobby Cage 3"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well Lobby Cage Big Fairy"] = function () return can_play_sun() and (can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots())) end,
            ["MQ Bottom of the Well Basement Big Fairy"] = function () return can_play_sun() end,
            ["MQ Bottom of the Well Pot Side Room 1"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well Pot Side Room 2"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well Pot Side Room 3"] = function () return can_play_zelda() or (has_explosives_or_hammer() and has_hover_boots()) end,
            ["MQ Bottom of the Well Pot Lobby Alcove"] = function () return has_explosives_or_hammer() and can_hit_triggers_distance() end,
            ["MQ Bottom of the Well Grass Dead-Hand 1"] = function () return can_cut_grass() and (has_ranged_weapon() or has_explosives_or_hammer() or can_use_sticks() or can_use_sword()) end,
            ["MQ Bottom of the Well Grass Dead-Hand 2"] = function () return can_cut_grass() and (has_ranged_weapon() or has_explosives_or_hammer() or can_use_sticks() or can_use_sword()) end,
            ["MQ Bottom of the Well Grass Dead-Hand 3"] = function () return can_cut_grass() and (has_ranged_weapon() or has_explosives_or_hammer() or can_use_sticks() or can_use_sword()) end,
            ["MQ Bottom of the Well Grass Dead-Hand 4"] = function () return can_cut_grass() and (has_ranged_weapon() or has_explosives_or_hammer() or can_use_sticks() or can_use_sword()) end,
            ["MQ Bottom of the Well Heart Main Room 1"] = function () return has_explosives() end,
            ["MQ Bottom of the Well Heart Main Room 2"] = function () return has_explosives() end,
            ["MQ Bottom of the Well Heart Basement 1"] = function () return true end,
            ["MQ Bottom of the Well Heart Basement 2"] = function () return true end,
            ["MQ Bottom of the Well Heart Basement 3"] = function () return true end,
            ["MQ Bottom of the Well Heart Coffin 1"] = function () return small_keys_botw(2) end,
            ["MQ Bottom of the Well Heart Coffin 2"] = function () return small_keys_botw(2) end,
        },
    },
    ["Deku Tree"] = {
        ["exits"] = {
            ["Kokiri Forest Near Deku Tree"] = function () return true end,
            ["Deku Tree Lobby"] = function () return true end,
        },
    },
    ["Deku Tree Lobby"] = {
        ["events"] = {
            ["STICKS"] = function () return has_weapon() or can_boomerang() end,
            ["NUTS"] = function () return can_kill_baba_nuts() end,
        },
        ["exits"] = {
            ["Deku Tree Compass Room"] = function () return can_use_bow() or (can_use_slingshot() and (can_use_sticks() or can_use_din())) end,
            ["Deku Tree Water Room"] = function () return (can_use_slingshot() or can_use_bow()) and (can_use_sticks() or has_fire()) end,
            ["Deku Tree Basement Ledge"] = function () return is_adult() or event('DEKU_BLOCK') or trick('OOT_DEKU_SKIP') or has_hover_boots() end,
        },
        ["locations"] = {
            ["MQ Deku Tree Map Chest"] = function () return true end,
            ["MQ Deku Tree Slingshot Chest"] = function () return soul_deku_baba() and soul_enemy(SOUL_ENEMY_GOHMA_LARVA) and (has_weapon() or can_use_sticks() or has_ranged_weapon_child()) end,
            ["MQ Deku Tree Slingshot Room Far Chest"] = function () return can_use_sticks() or has_fire() end,
            ["MQ Deku Tree Basement Chest"] = function () return can_use_sticks() or has_fire() end,
            ["MQ Deku Tree GS Lobby Crate"] = function () return gs() and can_damage_skull() end,
            ["MQ Deku Tree Grass Entrance Lower 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Entrance Lower 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Entrance Lower 3"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Entrance Lower 4"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Entrance Lower 5"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Entrance Upper 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Entrance Upper 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Slingshot Room Front 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Slingshot Room Front 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Slingshot Room Back 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Slingshot Room Back 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Room Before Compass 1"] = function () return can_cut_grass() and (can_use_bow() or can_use_sticks() or can_use_din()) end,
            ["MQ Deku Tree Grass Room Before Compass 2"] = function () return can_cut_grass() and (can_use_bow() or can_use_sticks() or can_use_din()) end,
            ["MQ Deku Tree Grass Room Before Compass 3"] = function () return can_cut_grass() and (can_use_bow() or can_use_sticks() or can_use_din()) end,
            ["MQ Deku Tree Grass Room Before Compass 4"] = function () return can_cut_grass() and (can_use_bow() or can_use_sticks() or can_use_din()) end,
            ["MQ Deku Tree Grass Room Before Compass 5"] = function () return can_cut_grass() and (can_use_bow() or can_use_sticks() or can_use_din()) end,
            ["MQ Deku Tree Grass Room Before Compass 6"] = function () return can_cut_grass() and (can_use_bow() or can_use_sticks() or can_use_din()) end,
            ["MQ Deku Tree Grass Room Before Compass 7"] = function () return can_cut_grass() and (can_use_bow() or can_use_sticks() or can_use_din()) end,
            ["MQ Deku Tree Grass Basement Lower 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Basement Lower 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Basement Lower 3"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Basement Lower 4"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Room Before Spike 1"] = function () return can_cut_grass() and (can_use_bow() or (can_use_slingshot() and (can_use_sticks() or has_fire()))) end,
            ["MQ Deku Tree Grass Room Before Spike 2"] = function () return can_cut_grass() and (can_use_bow() or (can_use_slingshot() and (can_use_sticks() or has_fire()))) end,
            ["MQ Deku Tree Grass Room Before Spike 3"] = function () return can_cut_grass() and (can_use_bow() or (can_use_slingshot() and (can_use_sticks() or has_fire()))) end,
            ["MQ Deku Tree Grass Room Before Spike 4"] = function () return can_cut_grass() and (can_use_bow() or (can_use_slingshot() and (can_use_sticks() or has_fire()))) end,
            ["MQ Deku Tree Heart Lobby"] = function () return true end,
            ["MQ Deku Tree Heart Before Compass"] = function () return can_use_bow() or can_use_sticks() or can_use_din() end,
            ["MQ Deku Tree Heart Slingshot Room"] = function () return true end,
        },
    },
    ["Deku Tree Compass Room"] = {
        ["exits"] = {
            ["Deku Tree Lobby"] = function () return true end,
            ["Deku Tree Compass Room Alcove"] = function () return has_bombchu() or has_mask_blast() or (can_play_time() and has_explosives_or_hammer()) end,
        },
        ["locations"] = {
            ["MQ Deku Tree Compass Chest"] = function () return true end,
            ["MQ Deku Tree Grass Compass Room 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Compass Room 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Compass Room 3"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Compass Room 4"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree Compass Room Alcove"] = {
        ["exits"] = {
            ["Deku Tree Compass Room"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Deku Tree GS Compass Room"] = function () return gs() and can_collect_distance() end,
            ["MQ Deku Tree Heart Compass Room"] = function () return true end,
        },
    },
    ["Deku Tree Water Room"] = {
        ["events"] = {
            ["MQ_DEKU_WATER_TORCHES"] = function () return is_child() and has_shield() and can_use_sticks() or (can_use_bow() and can_play_elegy()) end,
        },
        ["exits"] = {
            ["Deku Tree Lobby"] = function () return true end,
            ["Deku Tree Water Room Back"] = function () return is_child() and has_shield() or can_longshot() or (can_hookshot() and has_iron_boots()) end,
        },
        ["locations"] = {
            ["MQ Deku Tree Before Water Platform Chest"] = function () return true end,
            ["MQ Deku Tree Grass Spike Room Front 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Spike Room Front 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Spike Room Front 3"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree Water Room Back"] = {
        ["events"] = {
            ["MQ_DEKU_WATER_TORCHES"] = function () return has_fire() end,
        },
        ["exits"] = {
            ["Deku Tree Backrooms"] = function () return soul_keese() and soul_deku_scrub() and soul_enemy(SOUL_ENEMY_GOHMA_LARVA) and (has_weapon() or has_ranged_weapon_child()) and event('MQ_DEKU_WATER_TORCHES') end,
        },
        ["locations"] = {
            ["MQ Deku Tree After Water Platform Chest"] = function () return can_play_time() end,
            ["MQ Deku Tree Before Water Platform Chest"] = function () return true end,
            ["MQ Deku Tree Grass Spike Room Back 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Spike Room Back 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Larvae Room 1"] = function () return can_cut_grass() and event('MQ_DEKU_WATER_TORCHES') end,
            ["MQ Deku Tree Grass Larvae Room 2"] = function () return can_cut_grass() and event('MQ_DEKU_WATER_TORCHES') end,
            ["MQ Deku Tree Grass Spike Room Front 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Spike Room Front 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Spike Room Front 3"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree Backrooms"] = {
        ["exits"] = {
            ["Deku Tree Water Room Back"] = function () return soul_keese() and soul_deku_scrub() and soul_enemy(SOUL_ENEMY_GOHMA_LARVA) and (has_weapon() or has_ranged_weapon_child()) end,
            ["Deku Tree Basement Ledge"] = function () return is_child() and can_use_sticks() or can_use_din() end,
        },
        ["locations"] = {
            ["MQ Deku Tree GS Song of Time Blocks"] = function () return gs() and (can_play_time() and can_collect_distance() or can_longshot()) end,
            ["MQ Deku Tree GS Back Room"] = function () return gs() and (can_use_sticks() or has_fire()) and can_collect_distance() end,
            ["MQ Deku Tree Grass Gravestone Room 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Gravestone Room 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Gravestone Room 3"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Gravestone Room 4"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Gravestone Room 5"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Back Room 1"] = function () return can_cut_grass() and (can_use_sticks() or has_fire()) end,
            ["MQ Deku Tree Grass Back Room 2"] = function () return can_cut_grass() and (can_use_sticks() or has_fire()) end,
            ["MQ Deku Tree Grass Back Room 3"] = function () return can_cut_grass() and (can_use_sticks() or has_fire()) end,
            ["MQ Deku Tree Grass Larvae Room 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Larvae Room 2"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree Basement Ledge"] = {
        ["events"] = {
            ["DEKU_BLOCK"] = function () return true end,
        },
        ["exits"] = {
            ["Deku Tree Before Boss"] = function () return can_use_sticks() or has_fire() end,
            ["Deku Tree Backrooms"] = function () return is_child() end,
        },
        ["locations"] = {
            ["MQ Deku Tree Scrub"] = function () return business_scrub(27) end,
            ["MQ Deku Tree Grass Basement Upper 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Basement Upper 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Basement Upper 3"] = function () return can_cut_grass() end,
        },
    },
    ["Deku Tree Before Boss"] = {
        ["exits"] = {
            ["Deku Tree Basement Ledge"] = function () return true end,
            ["Deku Tree Boss"] = function () return has_shield_for_scrubs() and soul_deku_scrub() end,
        },
        ["locations"] = {
            ["MQ Deku Tree Grass Room Before Boss 1"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Room Before Boss 2"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Grass Room Before Boss 3"] = function () return can_cut_grass() end,
            ["MQ Deku Tree Heart Before Boss 1"] = function () return true end,
            ["MQ Deku Tree Heart Before Boss 2"] = function () return true end,
            ["MQ Deku Tree Heart Before Boss 3"] = function () return true end,
        },
    },
    ["Dodongo Cavern"] = {
        ["exits"] = {
            ["Death Mountain"] = function () return true end,
            ["Dodongo Cavern Main"] = function () return has_bombflowers() or can_hammer() or has_blue_fire_arrows_mudwall() end,
        },
    },
    ["Dodongo Cavern Main"] = {
        ["events"] = {
            ["STICKS"] = function () return (has_bombflowers() or can_hammer()) and (has_weapon() or can_boomerang()) end,
        },
        ["exits"] = {
            ["Dodongo Cavern"] = function () return true end,
            ["Dodongo Cavern Skull"] = function () return has_explosives() end,
            ["Dodongo Cavern Staircase"] = function () return has_bombflowers() or can_hammer() end,
            ["Dodongo Cavern Upper Ledges"] = function () return has_explosives_or_hammer() or can_use_din() end,
            ["Dodongo Cavern Lower Tunnel"] = function () return has_explosives_or_hammer() or (event('DC_MQ_SHORTCUT') and has_goron_bracelet()) end,
            ["Dodongo Cavern Bomb Bag Ledge"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Map Chest"] = function () return has_bombflowers() or can_hammer() or has_blue_fire_arrows_mudwall() end,
            ["MQ Dodongo Cavern Lobby Scrub Front"] = function () return business_scrub(28) end,
            ["MQ Dodongo Cavern Lobby Scrub Back"] = function () return business_scrub(29) end,
        },
    },
    ["Dodongo Cavern Staircase"] = {
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Upper Staircase"] = function () return has_bombflowers() end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern GS Time Blocks"] = function () return gs() and can_play_time() and can_damage_skull() end,
            ["MQ Dodongo Cavern SR Beamos"] = function () return true end,
            ["MQ Dodongo Cavern SR Crate"] = function () return true end,
            ["MQ Dodongo Cavern Pot Stairs 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Stairs 2"] = function () return true end,
            ["MQ Dodongo Cavern Pot Stairs 3"] = function () return true end,
            ["MQ Dodongo Cavern Pot Stairs 4"] = function () return true end,
        },
    },
    ["Dodongo Cavern Upper Staircase"] = {
        ["exits"] = {
            ["Dodongo Cavern After Staircase"] = function () return silver_rupees_dc() end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern SR Upper Corner Low"] = function () return true end,
            ["MQ Dodongo Cavern SR Vines"] = function () return true end,
            ["MQ Dodongo Cavern SR Upper Corner High"] = function () return true end,
            ["MQ Dodongo Cavern Staircase Scrub"] = function () return business_scrub(31) end,
        },
    },
    ["Dodongo Cavern After Staircase"] = {
        ["exits"] = {
            ["Dodongo Cavern Upper Staircase"] = function () return true end,
            ["Dodongo Cavern Torch Room"] = function () return soul_dodongo() end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Compass Chest"] = function () return soul_dodongo() end,
            ["MQ Dodongo Cavern Grass Compass Room 1"] = function () return can_cut_grass() end,
            ["MQ Dodongo Cavern Grass Compass Room 2"] = function () return can_cut_grass() end,
            ["MQ Dodongo Cavern Grass Compass Room 3"] = function () return can_cut_grass() end,
            ["MQ Dodongo Cavern Grass Compass Room 4"] = function () return can_cut_grass() end,
        },
    },
    ["Dodongo Cavern Torch Room"] = {
        ["exits"] = {
            ["Dodongo Cavern After Staircase"] = function () return true end,
            ["Dodongo Cavern Upper Ledges"] = function () return can_hookshot() or has_hover_boots() or (is_adult() and trick('OOT_DC_JUMP')) end,
            ["Dodongo Cavern Room Before Upper Lizalfos"] = function () return can_use_sticks() or has_fire() end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Larvae Room Chest"] = function () return soul_enemy(SOUL_ENEMY_GOHMA_LARVA) and (can_use_sticks() or has_fire()) end,
            ["MQ Dodongo Cavern GS Larve Room"] = function () return gs() and (can_use_sticks() or has_fire()) end,
            ["MQ Dodongo Cavern Heart Vanilla Bomb Bag Room"] = function () return true end,
        },
    },
    ["Dodongo Cavern Upper Lizalfos"] = {
        ["exits"] = {
            ["Dodongo Cavern Upper Ledges"] = function () return soul_lizalfos_dinalfos() and (can_use_sticks() or has_weapon() or can_use_slingshot()) end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern GS Upper Lizalfos"] = function () return gs() and has_explosives_or_hammer() end,
            ["MQ Dodongo Cavern Pot Miniboss 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Miniboss 2"] = function () return true end,
            ["MQ Dodongo Cavern Pot Miniboss 3"] = function () return true end,
            ["MQ Dodongo Cavern Pot Miniboss 4"] = function () return true end,
        },
    },
    ["Dodongo Cavern Upper Ledges"] = {
        ["events"] = {
            ["DC_MQ_SHORTCUT"] = function () return true end,
        },
        ["exits"] = {
            ["Dodongo Cavern Room After Upper Lizalfos"] = function () return true end,
            ["Dodongo Cavern Torch Room"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Upper Ledge Chest"] = function () return true end,
            ["MQ Dodongo Cavern Pot Vanilla Bomb Bag Room 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Vanilla Bomb Bag Room 2"] = function () return true end,
            ["MQ Dodongo Cavern Grass Vanilla Bomb Bag Room"] = function () return can_cut_grass() end,
        },
    },
    ["Dodongo Cavern Lower Tunnel"] = {
        ["exits"] = {
            ["Dodongo Cavern Lower Lizalfos"] = function () return can_use_bow() or ((has_bombflowers() or can_use_din()) and can_use_slingshot()) end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Tunnel Side Scrub"] = function () return business_scrub(30) end,
            ["MQ Dodongo Cavern Pot East Corridor 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot East Corridor 2"] = function () return true end,
            ["MQ Dodongo Cavern Pot East Corridor 3"] = function () return true end,
            ["MQ Dodongo Cavern Pot East Corridor 4"] = function () return true end,
        },
    },
    ["Dodongo Cavern Lower Lizalfos"] = {
        ["exits"] = {
            ["Dodongo Cavern Lower Tunnel"] = function () return soul_lizalfos_dinalfos() and (can_use_sticks() or has_weapon() or can_use_slingshot()) end,
            ["Dodongo Cavern Poe Room"] = function () return soul_lizalfos_dinalfos() and (can_use_sticks() or has_weapon() or can_use_slingshot()) end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Heart Lizalfos Room"] = function () return true end,
        },
    },
    ["Dodongo Cavern Poe Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Lower Lizalfos"] = function () return true end,
            ["Dodongo Cavern Bomb Bag Ledge"] = function () return can_use_bow() or has_bombflowers() or can_use_din() end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern GS Poe Room Side"] = function () return gs() and can_collect_distance() and (can_use_bow() or has_bombflowers() or can_use_din()) end,
            ["MQ Dodongo Cavern Pot Green Room 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Green Room 2"] = function () return true end,
            ["MQ Dodongo Cavern Pot Green Room 3"] = function () return true end,
            ["MQ Dodongo Cavern Pot Green Room 4"] = function () return true end,
            ["MQ Dodongo Cavern Grass Green Corridor Side Room 1"] = function () return (can_use_bow() or has_bombflowers() or can_use_din()) and can_cut_grass() end,
            ["MQ Dodongo Cavern Grass Green Corridor Side Room 2"] = function () return (can_use_bow() or has_bombflowers() or can_use_din()) and can_cut_grass() end,
        },
    },
    ["Dodongo Cavern Bomb Bag Ledge"] = {
        ["exits"] = {
            ["Dodongo Cavern Poe Room"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Bomb Bag Chest"] = function () return true end,
        },
    },
    ["Dodongo Cavern Skull"] = {
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Boss"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Chest Under Grave"] = function () return true end,
            ["MQ Dodongo Cavern GS Near Boss"] = function () return gs() end,
            ["MQ Dodongo Cavern Pot Before Boss 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Boss 2"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Boss Loop 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Boss Loop 2"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Boss Loop 3"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Boss Loop 4"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Boss Loop Side Room 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Boss Loop Side Room 2"] = function () return true end,
            ["MQ Dodongo Cavern Grass Boss Loop"] = function () return can_cut_grass() end,
            ["MQ Dodongo Cavern Grass Boss Loop Side Room"] = function () return can_cut_grass() end,
        },
    },
    ["Dodongo Cavern Room Before Upper Lizalfos"] = {
        ["exits"] = {
            ["Dodongo Cavern Upper Lizalfos"] = function () return can_use_sticks() and has_goron_bracelet() or has_explosives_or_hammer() or has_blue_fire_arrows_mudwall() end,
            ["Dodongo Cavern Torch Room"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Pot Before Miniboss 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot Before Miniboss 2"] = function () return true end,
            ["MQ Dodongo Cavern Grass Room Before Miniboss"] = function () return can_cut_grass() end,
        },
    },
    ["Dodongo Cavern Room After Upper Lizalfos"] = {
        ["exits"] = {
            ["Dodongo Cavern Upper Lizalfos"] = function () return true end,
            ["Dodongo Cavern Upper Ledges"] = function () return has_goron_bracelet() and (has_weapon() or can_use_sticks() or has_ranged_weapon()) or has_explosives_or_hammer() or is_adult() end,
        },
        ["locations"] = {
            ["MQ Dodongo Cavern Pot After Miniboss 1"] = function () return true end,
            ["MQ Dodongo Cavern Pot After Miniboss 2"] = function () return true end,
        },
    },
    ["Fire Temple"] = {
        ["exits"] = {
            ["Death Mountain Crater Near Temple"] = function () return true end,
            ["Fire Temple Upper Lobby"] = function () return is_adult() and has_tunic_goron() end,
            ["Fire Temple Vanilla Hammer Loop"] = function () return small_keys_fire_mq(5) end,
        },
        ["locations"] = {
            ["MQ Fire Temple Early Lower Left Chest"] = function () return can_damage() and soul_like_like() end,
            ["MQ Fire Temple Pot Entrance 1"] = function () return true end,
            ["MQ Fire Temple Pot Entrance 2"] = function () return true end,
        },
    },
    ["Fire Temple Upper Lobby"] = {
        ["exits"] = {
            ["Fire Temple Pre-Boss"] = function () return has_fire() end,
            ["Fire Temple 1f Lava Room"] = function () return can_hammer() end,
        },
    },
    ["Fire Temple Pre-Boss"] = {
        ["exits"] = {
            ["Fire Temple Upper Lobby"] = function () return true end,
            ["Fire Temple Boss"] = function () return has_tunic_goron() and boss_key(BOSS_KEY_FIRE) and (is_adult() and event('FIRE_TEMPLE_PILLAR_HAMMER') or has_hover_boots()) end,
        },
        ["locations"] = {
            ["MQ Fire Temple Pre-Boss Chest"] = function () return has_tunic_goron() and has_fire() and (can_use_bow() or has_hover_boots() or (has_tunic_goron_strict() and is_adult())) end,
            ["MQ Fire Temple Pot Pre-Boss 1"] = function () return has_tunic_goron() and (has_hover_boots() or can_hookshot()) end,
            ["MQ Fire Temple Pot Pre-Boss 2"] = function () return has_tunic_goron() and (has_hover_boots() or can_hookshot()) end,
        },
    },
    ["Fire Temple Vanilla Hammer Loop"] = {
        ["locations"] = {
            ["MQ Fire Temple Hammer Chest"] = function () return (is_adult() or can_hookshot() or climb_anywhere()) and has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) and soul_iron_knuckle() and soul_enemy(SOUL_ENEMY_FLARE_DANCER) and (has_bombs() or can_hammer() or can_hookshot()) end,
            ["MQ Fire Temple Map Chest"] = function () return can_hammer() and has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) and soul_iron_knuckle() and soul_enemy(SOUL_ENEMY_FLARE_DANCER) end,
            ["MQ Fire Temple Pot Hammer Loop 1"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Pot Hammer Loop 2"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Pot Hammer Loop 3"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Pot Hammer Loop 4"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Pot Hammer Loop 5"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Pot Hammer Loop 6"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Pot Hammer Loop 7"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Pot Hammer Loop 8"] = function () return has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Fire Temple Hammer Loop Stalfos Big Fairy"] = function () return can_play_sun() end,
            ["MQ Fire Temple Hammer Loop Iron Knuckle Big Fairy"] = function () return can_play_sun() and has_weapon() and soul_keese() and soul_enemy(SOUL_ENEMY_STALFOS) end,
        },
    },
    ["Fire Temple 1f Lava Room"] = {
        ["exits"] = {
            ["Fire Temple Upper Lobby"] = function () return true end,
            ["Fire Temple Maze Lower"] = function () return has_tunic_goron_strict() and small_keys_fire_mq(2) and has_fire() end,
        },
        ["locations"] = {
            ["MQ Fire Temple Boss Key Chest"] = function () return has_tunic_goron() and has_fire() and can_hookshot() end,
            ["MQ Fire Temple 1f Lava Room Goron Chest"] = function () return has_tunic_goron() and has_fire() and can_hookshot() and has_explosives() end,
            ["MQ Fire Temple GS 1f Lava Room"] = function () return gs() and has_tunic_goron() end,
            ["MQ Fire Temple Pot Lava Room Left"] = function () return has_tunic_goron() end,
            ["MQ Fire Temple Pot Lava Room Alcove"] = function () return has_tunic_goron() end,
            ["MQ Fire Temple Pot Lava Room Right"] = function () return has_tunic_goron() and can_hookshot() end,
            ["MQ Fire Temple Pot Boss Key Room 1"] = function () return has_tunic_goron() and has_fire() and can_hookshot() end,
            ["MQ Fire Temple Pot Boss Key Room 2"] = function () return has_tunic_goron() and has_fire() and can_hookshot() end,
            ["MQ Fire Temple Heart 1"] = function () return has_tunic_goron_strict() and small_keys_fire_mq(2) end,
            ["MQ Fire Temple Heart 2"] = function () return has_tunic_goron_strict() and small_keys_fire_mq(2) end,
            ["MQ Fire Temple Heart 3"] = function () return has_tunic_goron_strict() and small_keys_fire_mq(2) end,
        },
    },
    ["Fire Temple Maze Lower"] = {
        ["exits"] = {
            ["Fire Temple 1f Lava Room"] = function () return true end,
            ["Fire Temple Maze Upper"] = function () return can_hookshot() and (trick('OOT_HAMMER_WALLS') or has_explosives()) end,
        },
        ["locations"] = {
            ["MQ Fire Temple Maze Lower Chest"] = function () return true end,
            ["MQ Fire Temple Maze Side Room Chest"] = function () return can_play_elegy() end,
        },
    },
    ["Fire Temple Maze Upper"] = {
        ["exits"] = {
            ["Fire Temple Burning Block"] = function () return can_play_time() or can_longshot() end,
            ["Fire Temple 3f Lava Room"] = function () return small_keys_fire_mq(3) end,
        },
        ["locations"] = {
            ["MQ Fire Temple Maze Upper Chest"] = function () return true end,
            ["MQ Fire Temple Maze Side Room Chest"] = function () return true end,
            ["MQ Fire Temple Compass Chest"] = function () return has_explosives() end,
        },
    },
    ["Fire Temple Burning Block"] = {
        ["locations"] = {
            ["MQ Fire Temple GS Burning Block"] = function () return gs() end,
        },
    },
    ["Fire Temple 3f Lava Room"] = {
        ["exits"] = {
            ["Fire Temple Fire Walls"] = function () return can_use_bow() end,
        },
        ["locations"] = {
            ["MQ Fire Temple Pot Grids Above Lava 1"] = function () return true end,
            ["MQ Fire Temple Pot Grids Above Lava 2"] = function () return true end,
            ["MQ Fire Temple Pot Bridge Above Lava Room 1"] = function () return true end,
            ["MQ Fire Temple Pot Bridge Above Lava Room 2"] = function () return true end,
            ["MQ Fire Temple Pot Bridge Above Lava Room 3"] = function () return true end,
        },
    },
    ["Fire Temple Fire Walls"] = {
        ["events"] = {
            ["FIRE_TEMPLE_PILLAR_HAMMER"] = function () return true end,
        },
        ["exits"] = {
            ["Fire Temple Top"] = function () return small_keys_fire_mq(4) end,
        },
        ["locations"] = {
            ["MQ Fire Temple Flare Dancer Key"] = function () return soul_enemy(SOUL_ENEMY_FLARE_DANCER) end,
            ["MQ Fire Temple GS Fire Walls Side Room"] = function () return gs() and (has_hover_boots() or can_play_time()) end,
            ["MQ Fire Temple GS Fire Walls Middle"] = function () return gs() and has_explosives() end,
            ["MQ Fire Temple Pot Fire Maze Room Left 1"] = function () return true end,
            ["MQ Fire Temple Pot Fire Maze Room Left 2"] = function () return true end,
            ["MQ Fire Temple Pot Fire Maze Room Right 1"] = function () return has_hover_boots() or can_play_time() end,
            ["MQ Fire Temple Pot Fire Maze Room Right 2"] = function () return has_hover_boots() or can_play_time() end,
            ["MQ Fire Temple Pot Fire Maze Room Back Right 1"] = function () return can_hookshot() and can_hammer() end,
            ["MQ Fire Temple Pot Fire Maze Room Back Right 2"] = function () return can_hookshot() and can_hammer() end,
        },
    },
    ["Fire Temple Top"] = {
        ["locations"] = {
            ["MQ Fire Temple Topmost Chest"] = function () return true end,
            ["MQ Fire Temple GS Topmost"] = function () return gs() and small_keys_fire_mq(5) end,
        },
    },
    ["Forest Temple"] = {
        ["exits"] = {
            ["Sacred Meadow"] = function () return true end,
            ["Forest Temple Main"] = function () return small_keys_forest(1) and (is_adult() or (has_nuts() or has_weapon() or has_explosives() or has_ranged_weapon_child())) end,
        },
        ["locations"] = {
            ["MQ Forest Temple First Room Chest"] = function () return can_hit_triggers_distance() or can_hookshot() or has_explosives() or has_hover_boots() or can_use_din() or (has_weapon() and (has('MAGIC_UPGRADE') or has('SHARED_MAGIC_UPGRADE'))) end,
            ["MQ Forest Temple GS Entryway"] = function () return gs() and can_collect_distance() end,
        },
    },
    ["Forest Temple Wallmaster West"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Forest Temple Wallmaster East"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Forest Temple Main"] = {
        ["events"] = {
            ["FOREST_POE_4"] = function () return event('FOREST_POE_1') and event('FOREST_POE_2') and event('FOREST_POE_3') end,
        },
        ["exits"] = {
            ["Forest Temple"] = function () return true end,
            ["Forest Temple Antichamber"] = function () return event('FOREST_POE_4') end,
            ["Forest Temple West Wing"] = function () return has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["Forest Temple West Garden"] = function () return can_hit_triggers_distance() end,
            ["Forest Temple East Garden"] = function () return can_hit_triggers_distance() end,
        },
        ["locations"] = {
            ["MQ Forest Temple Wolfos Chest"] = function () return soul_wolfos() and can_play_time() and (has_weapon() or can_use_slingshot() or has_explosives() or can_use_din() or can_use_sticks()) end,
            ["MQ Forest Temple Pot Main Room 1"] = function () return true end,
            ["MQ Forest Temple Pot Main Room 2"] = function () return true end,
            ["MQ Forest Temple Pot Main Room 3"] = function () return true end,
            ["MQ Forest Temple Pot Main Room 4"] = function () return true end,
            ["MQ Forest Temple Pot Main Room 5"] = function () return true end,
            ["MQ Forest Temple Pot Main Room 6"] = function () return true end,
            ["MQ Forest Temple Pot Bow Room Lower 1"] = function () return can_play_time() end,
            ["MQ Forest Temple Pot Bow Room Lower 2"] = function () return can_play_time() end,
        },
    },
    ["Forest Temple West Wing"] = {
        ["exits"] = {
            ["Forest Temple Main"] = function () return has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["Forest Temple Straightened Hallway"] = function () return small_keys_forest(3) and is_adult() and has_goron_bracelet() end,
            ["Forest Temple West Garden"] = function () return soul_floormaster() and small_keys_forest(2) and is_adult() and has_goron_bracelet() end,
            ["Forest Temple Twisted Hallway"] = function () return small_keys_forest(3) and is_adult() and has_goron_bracelet() and event('FOREST_TWIST_SWITCH') end,
        },
        ["locations"] = {
            ["MQ Forest Temple GS Climb Room"] = function () return gs() and can_damage_skull() end,
        },
    },
    ["Forest Temple Straightened Hallway"] = {
        ["exits"] = {
            ["Forest Temple Wallmaster West"] = function () return soul_wallmaster() end,
            ["Forest Temple West Garden Ledge"] = function () return soul_floormaster() end,
        },
        ["locations"] = {
            ["MQ Forest Temple Boss Key Chest"] = function () return true end,
        },
    },
    ["Forest Temple West Garden Ledge"] = {
        ["events"] = {
            ["FOREST_TWIST_SWITCH"] = function () return true end,
        },
        ["exits"] = {
            ["Forest Temple West Garden"] = function () return true end,
            ["Forest Temple West Wing"] = function () return event('FOREST_TWIST_SWITCH') end,
        },
        ["locations"] = {
            ["MQ Forest Temple ReDead Chest"] = function () return soul_redead_gibdo() end,
        },
    },
    ["Forest Temple West Garden"] = {
        ["exits"] = {
            ["Forest Temple Main"] = function () return true end,
            ["Forest Temple East Garden"] = function () return can_dive_big() end,
            ["Forest Temple Garden Ledges"] = function () return has_fire_arrows() end,
        },
        ["locations"] = {
            ["MQ Forest Temple GS West Garden"] = function () return gs() end,
        },
    },
    ["Forest Temple East Garden"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() and (can_hookshot() or can_hammer() or can_boomerang() or (has_nuts() and has_weapon())) end,
            ["NUTS"] = function () return soul_deku_baba() and (has_weapon() or has_explosives() or can_use_slingshot()) end,
        },
        ["exits"] = {
            ["Forest Temple Main"] = function () return true end,
            ["Forest Temple Garden Ledges"] = function () return can_longshot() or (can_hookshot() and (trick('OOT_FOREST_HOOK') or can_play_time())) end,
            ["Forest Temple East Garden Ledge"] = function () return can_longshot() end,
        },
        ["locations"] = {
            ["MQ Forest Temple Well Chest"] = function () return can_hit_triggers_distance() end,
            ["MQ Forest Temple GS East Garden"] = function () return gs() and can_collect_distance() end,
            ["MQ Forest Temple GS Well"] = function () return gs() and (can_hit_triggers_distance() or (has_iron_boots() and (can_hookshot() or has_mask_blast()))) end,
            ["MQ Forest Temple Heart Well 1"] = function () return can_hit_triggers_distance() or has_iron_boots() end,
            ["MQ Forest Temple Heart Well 2"] = function () return can_hit_triggers_distance() or has_iron_boots() end,
            ["MQ Forest Temple Heart Well 3"] = function () return can_hit_triggers_distance() or has_iron_boots() end,
        },
    },
    ["Forest Temple Garden Ledges"] = {
        ["exits"] = {
            ["Forest Temple West Garden"] = function () return can_use_bow() or can_use_din() end,
            ["Forest Temple East Garden"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Forest Temple East Garden High Ledge Chest"] = function () return true end,
            ["MQ Forest Temple GS East Garden"] = function () return gs() and can_play_time() end,
            ["MQ Forest Temple Heart Garden 1"] = function () return true end,
            ["MQ Forest Temple Heart Garden 2"] = function () return true end,
            ["MQ Forest Temple Heart Garden 3"] = function () return true end,
        },
    },
    ["Forest Temple East Garden Ledge"] = {
        ["exits"] = {
            ["Forest Temple East Garden"] = function () return true end,
            ["Forest Temple Falling Ceiling"] = function () return can_play_time() end,
        },
        ["locations"] = {
            ["MQ Forest Temple East Garden Ledge Chest"] = function () return true end,
        },
    },
    ["Forest Temple Twisted Hallway"] = {
        ["exits"] = {
            ["Forest Temple Wallmaster West"] = function () return soul_wallmaster() end,
            ["Forest Temple Bow Region"] = function () return small_keys_forest(4) end,
        },
    },
    ["Forest Temple Bow Region"] = {
        ["events"] = {
            ["FOREST_POE_1"] = function () return can_use_bow() end,
            ["FOREST_POE_2"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_wolfos() and can_use_bow() end,
        },
        ["exits"] = {
            ["Forest Temple Wallmaster East"] = function () return soul_wallmaster() and soul_enemy(SOUL_ENEMY_STALFOS) and soul_wolfos() and has_weapon() and small_keys_forest(5) end,
            ["Forest Temple Falling Ceiling"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_wolfos() and has_weapon() and small_keys_forest(5) and (can_use_bow() or can_use_din()) end,
        },
        ["locations"] = {
            ["MQ Forest Temple Map Chest"] = function () return event('FOREST_POE_1') end,
            ["MQ Forest Temple Bow Chest"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_wolfos() and has_weapon() end,
            ["MQ Forest Temple Compass Chest"] = function () return event('FOREST_POE_2') end,
            ["MQ Forest Temple Pot Bow Room Upper 1"] = function () return true end,
            ["MQ Forest Temple Pot Bow Room Upper 2"] = function () return true end,
            ["MQ Forest Temple Pot Bow Room Upper 3"] = function () return true end,
            ["MQ Forest Temple Pot Bow Room Upper 4"] = function () return true end,
            ["MQ Forest Temple Pot Blue Poe 1"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_wolfos() end,
            ["MQ Forest Temple Pot Blue Poe 2"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_wolfos() end,
            ["MQ Forest Temple Pot Blue Poe 3"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_wolfos() end,
        },
    },
    ["Forest Temple Falling Ceiling"] = {
        ["events"] = {
            ["FOREST_POE_3"] = function () return small_keys_forest(6) and can_use_bow() end,
        },
        ["locations"] = {
            ["MQ Forest Temple Falling Ceiling Chest"] = function () return true end,
            ["MQ Forest Temple East Garden Ledge Chest"] = function () return true end,
            ["MQ Forest Temple Pot Green Poe 1"] = function () return small_keys_forest(6) end,
            ["MQ Forest Temple Pot Green Poe 2"] = function () return small_keys_forest(6) end,
        },
    },
    ["Forest Temple Antichamber"] = {
        ["exits"] = {
            ["Forest Temple Boss"] = function () return boss_key(BOSS_KEY_FOREST) end,
        },
        ["locations"] = {
            ["MQ Forest Temple Antichamber"] = function () return true end,
            ["MQ Forest Temple Pot Antichamber 1"] = function () return true end,
            ["MQ Forest Temple Pot Antichamber 2"] = function () return true end,
            ["MQ Forest Temple Pot Antichamber 3"] = function () return true end,
            ["MQ Forest Temple Pot Antichamber 4"] = function () return true end,
        },
    },
    ["Ganon Castle"] = {
        ["exits"] = {
            ["Ganon Castle Exterior After Bridge"] = function () return true end,
            ["Ganon Castle Main"] = function () return soul_iron_knuckle() and soul_armos() and soul_bubble() and (can_use_sword_master() or can_use_sword_goron() or (can_use_sticks() and (has_ranged_weapon_child() or can_use_bow())) or has_explosives_or_hammer()) end,
        },
    },
    ["Ganon Castle Spirit Wallmaster"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Ganon Castle Main"] = {
        ["exits"] = {
            ["Ganon Castle"] = function () return true end,
            ["Ganon Castle Light"] = function () return can_lift_gold() end,
            ["Ganon Castle Forest"] = function () return true end,
            ["Ganon Castle Fire"] = function () return true end,
            ["Ganon Castle Water"] = function () return true end,
            ["Ganon Castle Spirit"] = function () return true end,
            ["Ganon Castle Shadow"] = function () return true end,
            ["Ganon Castle Stairs"] = function () return ganon_barrier() end,
            ["Ganon Castle Fairy Fountain"] = function () return has_lens() end,
        },
    },
    ["Ganon Castle Fairy Fountain"] = {
        ["locations"] = {
            ["MQ Ganon Castle Leftmost Scrub"] = function () return business_scrub(33) end,
            ["MQ Ganon Castle Left-Center Scrub"] = function () return business_scrub(34) end,
            ["MQ Ganon Castle Center Scrub"] = function () return business_scrub(35) end,
            ["MQ Ganon Castle Right-Center Scrub"] = function () return business_scrub(36) end,
            ["MQ Ganon Castle Rightmost Scrub"] = function () return business_scrub(37) end,
            ["MQ Ganon Castle Fairy Fountain Fairy 1"] = function () return true end,
            ["MQ Ganon Castle Fairy Fountain Fairy 2"] = function () return true end,
            ["MQ Ganon Castle Fairy Fountain Fairy 3"] = function () return true end,
            ["MQ Ganon Castle Fairy Fountain Fairy 4"] = function () return true end,
            ["MQ Ganon Castle Fairy Fountain Fairy 5"] = function () return true end,
            ["MQ Ganon Castle Fairy Fountain Fairy 6"] = function () return true end,
            ["MQ Ganon Castle Fairy Fountain Fairy 7"] = function () return true end,
            ["MQ Ganon Castle Fairy Fountain Fairy 8"] = function () return true end,
        },
    },
    ["Ganon Castle Light"] = {
        ["events"] = {
            ["GANON_TRIAL_LIGHT"] = function () return soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and can_use_light_arrows() and has_lens() and can_hookshot() and small_keys_ganon(3) end,
        },
        ["locations"] = {
            ["MQ Ganon Castle Light Trial Chest"] = function () return soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and can_play_zelda() and has_weapon() end,
            ["MQ Ganon Pot Light End 1"] = function () return soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and has_lens() and can_hookshot() and small_keys_ganon(3) end,
            ["MQ Ganon Pot Light End 2"] = function () return soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and has_lens() and can_hookshot() and small_keys_ganon(3) end,
            ["MQ Ganon Castle Heart Light 1"] = function () return small_keys_ganon(2) and soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and can_play_zelda() and has_weapon() end,
            ["MQ Ganon Castle Heart Light 2"] = function () return small_keys_ganon(2) and soul_lizalfos_dinalfos() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) and can_play_zelda() and has_weapon() end,
        },
    },
    ["Ganon Castle Forest"] = {
        ["events"] = {
            ["GANON_TRIAL_FOREST"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and (can_play_time() or can_play_elegy()) and can_use_light_arrows() end,
        },
        ["locations"] = {
            ["MQ Ganon Castle Forest Trial Key"] = function () return can_hookshot() end,
            ["MQ Ganon Castle Forest Trial First Chest"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and can_hit_triggers_distance() end,
            ["MQ Ganon Castle Forest Trial Second Chest"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and has_fire() end,
            ["MQ Ganon Pot Forest End 1"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and (can_play_time() or can_play_elegy()) end,
            ["MQ Ganon Pot Forest End 2"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and (can_play_time() or can_play_elegy()) end,
        },
    },
    ["Ganon Castle Fire"] = {
        ["events"] = {
            ["GANON_TRIAL_FIRE"] = function () return can_use_light_arrows() and has_tunic_goron_strict() and (can_longshot() or has_hover_boots()) and silver_rupees_ganon_fire() end,
        },
        ["locations"] = {
            ["MQ Ganon Castle SR Fire Under Pillar"] = function () return has_tunic_goron() and can_lift_gold() end,
            ["MQ Ganon Castle SR Fire Center-Left"] = function () return has_tunic_goron_strict() end,
            ["MQ Ganon Castle SR Fire Back-Left"] = function () return has_tunic_goron_strict() end,
            ["MQ Ganon Castle SR Fire High Above Lava"] = function () return has_tunic_goron() end,
            ["MQ Ganon Castle SR Fire Front-Left"] = function () return has_tunic_goron_strict() end,
            ["MQ Ganon Pot Fire End 1"] = function () return has_tunic_goron_strict() and (can_longshot() or has_hover_boots()) and silver_rupees_ganon_fire() end,
            ["MQ Ganon Pot Fire End 2"] = function () return has_tunic_goron_strict() and (can_longshot() or has_hover_boots()) and silver_rupees_ganon_fire() end,
        },
    },
    ["Ganon Castle Water"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return has_bottle() and (has_weapon() or can_use_sticks() or has_explosives_or_hammer()) end,
        },
        ["exits"] = {
            ["Ganon Castle Water Silver Rupees"] = function () return has_blue_fire() and small_keys_ganon(3) end,
        },
        ["locations"] = {
            ["MQ Ganon Castle Water Trial Chest"] = function () return has_blue_fire() end,
            ["MQ Ganon Castle Heart Water"] = function () return has_blue_fire() end,
        },
    },
    ["Ganon Castle Water Silver Rupees"] = {
        ["events"] = {
            ["GANON_TRIAL_WATER"] = function () return silver_rupees_ganon_water() and can_use_light_arrows() end,
        },
        ["locations"] = {
            ["MQ Ganon Castle SR Water Shallow Hole"] = function () return true end,
            ["MQ Ganon Castle SR Water Above Ground"] = function () return true end,
            ["MQ Ganon Castle SR Water Alcove"] = function () return is_adult() end,
            ["MQ Ganon Castle SR Water Deep Hole"] = function () return true end,
            ["MQ Ganon Castle SR Water Under Alcove"] = function () return true end,
            ["MQ Ganon Pot Water End 1"] = function () return silver_rupees_ganon_water() end,
            ["MQ Ganon Pot Water End 2"] = function () return silver_rupees_ganon_water() end,
        },
    },
    ["Ganon Castle Spirit"] = {
        ["events"] = {
            ["GANON_TRIAL_SPIRIT"] = function () return can_use_light_arrows() and has_fire_arrows() and can_reflect_light() and can_hammer() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
        },
        ["exits"] = {
            ["Ganon Castle Spirit Wallmaster"] = function () return soul_wallmaster() and can_hammer() and has_fire_arrows() and can_reflect_light() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
        },
        ["locations"] = {
            ["MQ Ganon Castle Spirit Trial First Chest"] = function () return can_hammer() and (can_use_bow() and soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
            ["MQ Ganon Castle Spirit Trial Second Chest"] = function () return can_hammer() and (can_use_bow() and soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) and has_bombchu() and has_lens() end,
            ["MQ Ganon Castle Spirit Trial Back Right Sun Chest"] = function () return can_hammer() and has_fire_arrows() and can_reflect_light() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
            ["MQ Ganon Castle Spirit Trial Back Left Sun Chest"] = function () return can_hammer() and has_fire_arrows() and can_reflect_light() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
            ["MQ Ganon Castle Spirit Trial Front Left Sun Chest"] = function () return can_hammer() and has_fire_arrows() and can_reflect_light() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
            ["MQ Ganon Castle Spirit Trial Gold Gauntlets Chest"] = function () return can_hammer() and has_fire_arrows() and can_reflect_light() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
            ["MQ Ganon Pot Spirit End 1"] = function () return has_fire_arrows() and can_reflect_light() and can_hammer() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
            ["MQ Ganon Pot Spirit End 2"] = function () return has_fire_arrows() and can_reflect_light() and can_hammer() and has_bombchu() and (soul_iron_knuckle() or trick('OOT_HAMMER_WALLS')) end,
        },
    },
    ["Ganon Castle Shadow"] = {
        ["events"] = {
            ["GANON_TRIAL_SHADOW"] = function () return has_lens() and can_use_light_arrows() and (has_hover_boots() or (can_hookshot() and has_fire() and can_use_bow())) and silver_rupees_ganon_shadow() end,
        },
        ["locations"] = {
            ["MQ Ganon Castle Shadow Trial Bomb Flower Chest"] = function () return (can_hookshot() or has_hover_boots()) and (can_use_bow() or (has_lens() and has_hover_boots() and (can_use_din() or has_bombflowers()))) end,
            ["MQ Ganon Castle Shadow Trial Switch Chest"] = function () return can_use_bow() and has_lens() and (has_hover_boots() or (can_hookshot() and has_fire())) end,
            ["MQ Ganon Castle SR Shadow Front-Right"] = function () return has_lens() and (has_hover_boots() or (can_use_bow() and can_hookshot())) end,
            ["MQ Ganon Castle SR Shadow Middle"] = function () return has_lens() and (has_hover_boots() or (can_use_bow() and can_hookshot())) end,
            ["MQ Ganon Castle SR Shadow Back-Left"] = function () return has_lens() and (has_hover_boots() or (can_use_bow() and can_hookshot() and has_fire())) end,
            ["MQ Ganon Castle SR Shadow Back-Center"] = function () return has_lens() and (has_hover_boots() or (can_use_bow() and can_hookshot() and has_fire())) end,
            ["MQ Ganon Castle SR Shadow Front-Center"] = function () return has_lens() and (has_hover_boots() or (can_use_bow() and can_hookshot())) end,
            ["MQ Ganon Pot Shadow End 1"] = function () return has_lens() and (has_hover_boots() or (can_hookshot() and has_fire() and can_use_bow())) and silver_rupees_ganon_shadow() end,
            ["MQ Ganon Pot Shadow End 2"] = function () return has_lens() and (has_hover_boots() or (can_hookshot() and has_fire() and can_use_bow())) and silver_rupees_ganon_shadow() end,
        },
    },
    ["Ganon Castle Stairs"] = {
        ["exits"] = {
            ["Ganon Castle Main"] = function () return true end,
            ["Ganon Castle Tower"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds"] = {
        ["events"] = {
            ["GTG_RIGHT_SIDE"] = function () return can_hit_triggers_distance() end,
            ["GTG_LEFT_SIDE"] = function () return has_fire() end,
            ["GTG_ICE_ARROWS"] = function () return small_keys_gtg(3) and can_hammer() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Training Grounds Right Path"] = function () return event('GTG_RIGHT_SIDE') and is_adult() end,
            ["Gerudo Training Grounds Left Path"] = function () return event('GTG_LEFT_SIDE') end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds Entryway Left Chest"] = function () return true end,
            ["MQ Gerudo Training Grounds Entryway Right Chest"] = function () return true end,
            ["MQ Gerudo Training Grounds Maze First Chest"] = function () return has_lens() end,
            ["MQ Gerudo Training Grounds Maze Second Chest"] = function () return true end,
            ["MQ Gerudo Training Grounds Maze Third Chest"] = function () return true end,
            ["MQ Gerudo Training Grounds Maze Fourth Chest"] = function () return small_keys_gtg(1) end,
            ["MQ Gerudo Training Grounds Pot 1"] = function () return true end,
            ["MQ Gerudo Training Grounds Pot 2"] = function () return true end,
            ["MQ Gerudo Training Grounds Pot 3"] = function () return true end,
            ["MQ Gerudo Training Grounds Pot 4"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Wallmaster"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Right Path"] = {
        ["exits"] = {
            ["Gerudo Training Grounds"] = function () return true end,
            ["Gerudo Training Grounds Lava Room"] = function () return soul_lizalfos_dinalfos() and soul_armos() and soul_dodongo() and (can_use_sword_master() or can_use_sword_goron()) end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds Right Side Dinolfos Chest"] = function () return soul_lizalfos_dinalfos() and soul_armos() and soul_dodongo() and (can_use_sword_master() or can_use_sword_goron()) end,
        },
    },
    ["Gerudo Training Grounds Lava Room"] = {
        ["events"] = {
            ["GTG_LAVA_TARGETS"] = function () return silver_rupees_gtg_lava_mq() end,
        },
        ["exits"] = {
            ["Gerudo Training Grounds Right Path"] = function () return true end,
            ["Gerudo Training Grounds Water Room"] = function () return silver_rupees_gtg_lava_mq() and (can_longshot() or can_use_bow() or (trick('OOT_MQ_GTG_FLAMES') and (can_hookshot() or has_hover_boots()))) end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds SR Lava Back-Left"] = function () return (has_hover_boots() or event('GTG_LAVA_TARGETS')) and (can_use_bow() or ((can_longshot() or (trick('OOT_MQ_GTG_FLAMES') and can_hookshot())) and has_fire()) or (trick('OOT_MQ_GTG_FLAMES') and has_hover_boots() and has_fire_or_sticks())) end,
            ["MQ Gerudo Training Grounds SR Lava Back-Right"] = function () return (has_hover_boots() or event('GTG_LAVA_TARGETS')) and (can_use_bow() or ((can_longshot() or (trick('OOT_MQ_GTG_FLAMES') and can_hookshot())) and has_fire()) or (trick('OOT_MQ_GTG_FLAMES') and has_hover_boots() and has_fire_or_sticks())) end,
            ["MQ Gerudo Training Grounds SR Lava Center"] = function () return (has_hover_boots() or event('GTG_LAVA_TARGETS')) and (can_use_bow() or ((can_longshot() or (trick('OOT_MQ_GTG_FLAMES') and can_hookshot())) and has_fire()) or (trick('OOT_MQ_GTG_FLAMES') and has_hover_boots() and has_fire_or_sticks())) end,
            ["MQ Gerudo Training Grounds SR Lava Front-Right"] = function () return can_use_bow() or (can_longshot() and has_fire()) or (can_hookshot() and trick('OOT_MQ_GTG_FLAMES')) or (has_hover_boots() and trick('OOT_MQ_GTG_FLAMES') and has_fire_or_sticks()) end,
            ["MQ Gerudo Training Grounds SR Lava Front-Left"] = function () return can_use_bow() or ((can_longshot() or (can_hookshot() and trick('OOT_MQ_GTG_FLAMES'))) and has_fire()) or (has_hover_boots() and trick('OOT_MQ_GTG_FLAMES') and has_fire_or_sticks()) or ((has_weapon() or can_use_sticks() or can_hammer()) and trick('OOT_MQ_GTG_FLAMES')) end,
            ["MQ Gerudo Training Grounds SR Lava Front"] = function () return can_use_bow() or (can_longshot() and has_fire()) or (can_hookshot() and trick('OOT_MQ_GTG_FLAMES')) or (has_hover_boots() and trick('OOT_MQ_GTG_FLAMES') and has_fire_or_sticks()) end,
            ["MQ Gerudo Training Grounds Maze Right Side Middle Chest"] = function () return can_use_bow() and can_hookshot() and event('GTG_LAVA_HAMMER') end,
            ["MQ Gerudo Training Grounds Maze Right Side Right Chest"] = function () return can_use_bow() and can_hookshot() and event('GTG_LAVA_HAMMER') end,
        },
    },
    ["Gerudo Training Grounds Water Room"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Lava Room"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds Water Room Chest"] = function () return silver_rupees_gtg_water_mq() end,
            ["MQ Gerudo Training Grounds SR Water Top-Left"] = function () return has_iron_boots() and has_tunic_zora() and has_fire() end,
            ["MQ Gerudo Training Grounds SR Water Center"] = function () return has_iron_boots() and has_tunic_zora() and has_fire() end,
            ["MQ Gerudo Training Grounds SR Water Bottom-Right"] = function () return has_iron_boots() and has_tunic_zora() and has_fire() end,
        },
    },
    ["Gerudo Training Grounds Left Path"] = {
        ["events"] = {
            ["GTG_IRON_KNUCKLE"] = function () return soul_iron_knuckle() and (has_weapon() or can_use_sticks()) and (has_shield() or is_adult()) end,
        },
        ["exits"] = {
            ["Gerudo Training Grounds"] = function () return true end,
            ["Gerudo Training Grounds Slopes"] = function () return event('GTG_IRON_KNUCKLE') end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds Left Side Iron Knuckle Chest"] = function () return event('GTG_IRON_KNUCKLE') end,
        },
    },
    ["Gerudo Training Grounds Slopes"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Wallmaster"] = function () return soul_wallmaster() end,
            ["Gerudo Training Grounds Left Path"] = function () return true end,
            ["Gerudo Training Grounds Stalfos Room"] = function () return silver_rupees_gtg_slopes() end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds SR Slopes Top Right"] = function () return true end,
            ["MQ Gerudo Training Grounds SR Slopes Middle"] = function () return true end,
            ["MQ Gerudo Training Grounds SR Slopes Front"] = function () return can_longshot() end,
            ["MQ Gerudo Training Grounds SR Slopes Front-Left"] = function () return true end,
            ["MQ Gerudo Training Grounds SR Slopes Front-Right"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Stalfos Room"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Gerudo Training Grounds Spinning Statue Room"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_skulltula() and has_blue_fire() and can_play_time() and has_lens() and is_adult() end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds Stalfos Room Chest"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_skulltula() end,
            ["MQ Gerudo Training Grounds Silver Block Room Chest"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and soul_skulltula() and can_lift_silver() and soul_enemy(SOUL_ENEMY_SPIKE) and soul_freezard() end,
        },
    },
    ["Gerudo Training Grounds Spinning Statue Room"] = {
        ["events"] = {
            ["GTG_LAVA_HAMMER"] = function () return can_hammer() end,
            ["GTG_LAVA_TARGETS"] = function () return silver_rupees_gtg_lava_mq() end,
        },
        ["exits"] = {
            ["Gerudo Training Grounds Lava Room"] = function () return can_longshot() or (can_hookshot() and (has_fire_arrows() or trick('OOT_MQ_GTG_FLAMES'))) or (has_hover_boots() and trick('OOT_MQ_GTG_FLAMES') and event('GTG_LAVA_TARGETS')) end,
            ["Gerudo Training Grounds Water Room"] = function () return silver_rupees_gtg_lava_mq() and event('GTG_LAVA_TARGETS') and (can_hookshot() or has_hover_boots() or trick('OOT_MQ_GTG_FLAMES')) end,
        },
        ["locations"] = {
            ["MQ Gerudo Training Grounds Spinning Statue Chest"] = function () return can_use_bow() end,
            ["MQ Gerudo Training Grounds Torch Slug Room Clear Chest"] = function () return soul_iron_knuckle() and soul_enemy(SOUL_ENEMY_TORCH_SLUG) end,
            ["MQ Gerudo Training Grounds Torch Slug Room Switch Chest"] = function () return has_ranged_weapon() end,
            ["MQ Gerudo Training Grounds Maze Right Side Middle Chest"] = function () return event('GTG_LAVA_HAMMER') and (can_longshot() or (can_hookshot() and (has_fire_arrows() or (has_hover_boots() and event('GTG_LAVA_TARGETS')) or trick('OOT_MQ_GTG_FLAMES')))) end,
            ["MQ Gerudo Training Grounds Maze Right Side Right Chest"] = function () return event('GTG_LAVA_HAMMER') and (can_longshot() or (can_hookshot() and (has_fire_arrows() or (has_hover_boots() and event('GTG_LAVA_TARGETS')) or trick('OOT_MQ_GTG_FLAMES')))) end,
            ["MQ Gerudo Training Grounds Ice Arrows Chest"] = function () return event('GTG_ICE_ARROWS') end,
            ["MQ Gerudo Training Grounds SR Lava Back-Right"] = function () return has_fire_arrows() end,
            ["MQ Gerudo Training Grounds SR Lava Center"] = function () return has_fire_arrows() end,
        },
    },
    ["Ice Cavern"] = {
        ["exits"] = {
            ["Zora Fountain Frozen"] = function () return true end,
            ["Ice Cavern Main"] = function () return has_ranged_weapon() or has_explosives() end,
        },
        ["locations"] = {
            ["MQ Ice Cavern Pot Entrance"] = function () return true end,
        },
    },
    ["Ice Cavern Main"] = {
        ["exits"] = {
            ["Ice Cavern Map Room"] = function () return soul_wolfos() and soul_freezard() and (has_weapon() or can_use_sticks() or has_explosives()) end,
            ["Ice Cavern Compass Room"] = function () return is_adult() and has_blue_fire() end,
            ["Ice Cavern Big Room"] = function () return has_blue_fire() end,
        },
        ["locations"] = {
            ["MQ Ice Cavern Pot First Room 1"] = function () return true end,
            ["MQ Ice Cavern Pot First Room 2"] = function () return true end,
            ["MQ Ice Cavern Pot Main Room 1"] = function () return true end,
            ["MQ Ice Cavern Pot Main Room 2"] = function () return true end,
            ["MQ Ice Cavern Pot Main Room 3"] = function () return true end,
            ["MQ Ice Cavern Pot Main Room 4"] = function () return true end,
        },
    },
    ["Ice Cavern Map Room"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return has_bottle() end,
        },
        ["locations"] = {
            ["MQ Ice Cavern Map Chest"] = function () return has_blue_fire() end,
        },
    },
    ["Ice Cavern Compass Room"] = {
        ["locations"] = {
            ["MQ Ice Cavern Compass Chest"] = function () return true end,
            ["MQ Ice Cavern Piece of Heart"] = function () return has_explosives() end,
            ["MQ Ice Cavern GS Compass Room"] = function () return gs() and (can_play_time() or has_blue_fire_arrows() or can_boomerang()) end,
            ["MQ Ice Cavern Pot Compass Room 1"] = function () return true end,
            ["MQ Ice Cavern Pot Compass Room 2"] = function () return true end,
        },
    },
    ["Ice Cavern Big Room"] = {
        ["locations"] = {
            ["MQ Ice Cavern Iron Boots"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and (is_adult() or (can_play_time() and has_hover_boots())) end,
            ["MQ Ice Cavern Sheik Song"] = function () return soul_npc(SOUL_NPC_SHEIK) and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and (is_adult() or (can_play_time() and has_hover_boots())) end,
            ["MQ Ice Cavern GS Scarecrow"] = function () return gs() and (scarecrow_hookshot() or (has_hover_boots() and (can_longshot() or (is_adult() and trick('OOT_MQ_ICE_SCARE_HOVER')))) or (is_adult() and trick('OOT_MQ_ICE_SCARE_NOTHING'))) end,
            ["MQ Ice Cavern GS Clear Blocks"] = function () return gs() and (has_ranged_weapon() or has_explosives()) end,
            ["MQ Ice Cavern Pot Final Corridor 1"] = function () return is_adult() or (can_play_time() and has_hover_boots()) end,
            ["MQ Ice Cavern Pot Final Corridor 2"] = function () return is_adult() or (can_play_time() and has_hover_boots()) end,
        },
    },
    ["Jabu-Jabu"] = {
        ["events"] = {
            ["JABU_MQ_START"] = function () return can_use_slingshot() end,
        },
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
            ["Jabu-Jabu Main"] = function () return event('JABU_MQ_START') end,
        },
        ["locations"] = {
            ["MQ Jabu-Jabu Map Chest"] = function () return has_explosives_or_hammer() end,
            ["MQ Jabu-Jabu Entry Chest"] = function () return can_use_slingshot() end,
            ["MQ Jabu-Jabu Pot Entrance 1"] = function () return true end,
            ["MQ Jabu-Jabu Pot Entrance 2"] = function () return true end,
            ["MQ Jabu-Jabu Grass Entrance 1"] = function () return can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Entrance 2"] = function () return can_cut_grass() end,
        },
    },
    ["Jabu-Jabu Main"] = {
        ["events"] = {
            ["JABU_BIG_OCTO"] = function () return event('JABU_TENTACLE_GREEN') and soul_octorok() and (can_use_sticks() or has_weapon()) and soul_ruto() end,
            ["JABU_MQ_BACK"] = function () return can_use_slingshot() and has_explosives() end,
        },
        ["exits"] = {
            ["Jabu-Jabu"] = function () return true end,
            ["Jabu-Jabu Back"] = function () return can_boomerang() and event('JABU_MQ_BACK') end,
            ["Jabu-Jabu Pre-Boss"] = function () return event('JABU_TENTACLE_RED') and (event('JABU_BIG_OCTO') or can_hookshot() or has_hover_boots()) end,
            ["Jabu-Jabu Basement Side Room"] = function () return event('JABU_TENTACLE_RED') end,
        },
        ["locations"] = {
            ["MQ Jabu-Jabu Compass Chest"] = function () return can_use_slingshot() and (is_child() or (is_adult() and can_dive_small())) end,
            ["MQ Jabu-Jabu Second Room B1 Chest"] = function () return true end,
            ["MQ Jabu-Jabu Second Room 1F Chest"] = function () return can_use_slingshot() and (has_hover_boots() or can_hookshot() or event('JABU_BIG_OCTO')) end,
            ["MQ Jabu-Jabu Third Room West Chest"] = function () return can_use_slingshot() and (is_child() or (is_adult() and can_dive_small())) end,
            ["MQ Jabu-Jabu Third Room East Chest"] = function () return can_use_slingshot() and (is_child() or (is_adult() and can_dive_small())) end,
            ["MQ Jabu-Jabu SoT Room Lower Chest"] = function () return (soul_ruto() or can_play_elegy()) and (is_child() or (is_adult() and can_dive_small())) end,
            ["MQ Jabu-Jabu Boomerang Chest"] = function () return (soul_ruto() or can_play_elegy()) and soul_lizalfos_dinalfos() and soul_like_like() and soul_enemy(SOUL_ENEMY_STINGER) end,
            ["MQ Jabu-Jabu GS SoT Block"] = function () return gs() and (soul_ruto() or can_play_elegy()) and can_play_time() and (is_child() or (is_adult() and can_dive_small())) end,
            ["MQ Jabu-Jabu Cow"] = function () return can_play_epona() and event('JABU_BIG_OCTO') and can_use_slingshot() end,
            ["MQ Jabu-Jabu Pot Underwater Alcove 1"] = function () return is_child() or (is_adult() and can_dive_small()) end,
            ["MQ Jabu-Jabu Pot Underwater Alcove 2"] = function () return is_child() or (is_adult() and can_dive_small()) end,
            ["MQ Jabu-Jabu Pot Boomerang Room 1"] = function () return (soul_ruto() or can_play_elegy()) and (is_child() or (is_adult() and can_dive_small())) end,
            ["MQ Jabu-Jabu Pot Boomerang Room 2"] = function () return (soul_ruto() or can_play_elegy()) and (is_child() or (is_adult() and can_dive_small())) end,
            ["MQ Jabu-Jabu Grass Main Room Top 1"] = function () return (is_child() or (is_adult() and can_dive_small())) and can_cut_grass() and has_explosives_or_hammer() end,
            ["MQ Jabu-Jabu Grass Main Room Top 2"] = function () return (is_child() or (is_adult() and can_dive_small())) and can_cut_grass() and has_explosives_or_hammer() end,
            ["MQ Jabu-Jabu Grass Main Room Bottom 1"] = function () return (is_child() or (is_adult() and can_dive_small())) and can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Main Room Bottom 2"] = function () return (is_child() or (is_adult() and can_dive_small())) and can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Main Room Bottom 3"] = function () return (is_child() or (is_adult() and can_dive_small())) and can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Boomerang Room"] = function () return (is_child() or (is_adult() and can_dive_small())) and can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Big Octo Top 1"] = function () return event('JABU_BIG_OCTO') and can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Big Octo Top 2"] = function () return event('JABU_BIG_OCTO') and can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Room After Big Octo"] = function () return event('JABU_BIG_OCTO') and can_cut_grass() and can_use_slingshot() end,
            ["MQ Jabu-Jabu Rupee Bottom"] = function () return is_child() and can_dive_small() or can_dive_big() end,
            ["MQ Jabu-Jabu Rupee Middle"] = function () return can_dive_small() end,
            ["MQ Jabu-Jabu Rupee Top"] = function () return is_child() or can_dive_small() end,
            ["MQ Jabu-Jabu Heart 1"] = function () return true end,
            ["MQ Jabu-Jabu Heart 2"] = function () return true end,
        },
    },
    ["Jabu-Jabu Back"] = {
        ["events"] = {
            ["JABU_TENTACLE_BLUE"] = function () return (can_use_sticks() and soul_like_like() and can_use_slingshot() or has_fire()) and can_boomerang() and soul_enemy(SOUL_ENEMY_PARASITE) end,
            ["JABU_TENTACLE_RED"] = function () return can_boomerang() and soul_enemy(SOUL_ENEMY_PARASITE) end,
            ["JABU_TENTACLE_GREEN"] = function () return event('JABU_TENTACLE_BLUE') end,
        },
        ["exits"] = {
            ["Jabu-Jabu Main"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Jabu-Jabu Back Chest"] = function () return soul_like_like() and can_use_slingshot() end,
            ["MQ Jabu-Jabu GS Back"] = function () return gs() and event('JABU_TENTACLE_BLUE') end,
            ["MQ Jabu-Jabu Pot Like-Like Room 1"] = function () return true end,
            ["MQ Jabu-Jabu Pot Like-Like Room 2"] = function () return true end,
            ["MQ Jabu-Jabu Grass Torch Room"] = function () return can_cut_grass() end,
        },
    },
    ["Jabu-Jabu Basement Side Room"] = {
        ["exits"] = {
            ["Jabu-Jabu Main"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Jabu-Jabu GS Basement Side Room"] = function () return gs() and (has_lens() and soul_keese() and soul_enemy(SOUL_ENEMY_STINGER) or (has_hover_boots() and can_collect_distance()) or (has_fire_arrows() and can_longshot())) end,
        },
    },
    ["Jabu-Jabu Pre-Boss"] = {
        ["events"] = {
            ["JABU_MQ_END"] = function () return can_use_slingshot() end,
        },
        ["exits"] = {
            ["Jabu-Jabu Boss"] = function () return event('JABU_MQ_END') end,
            ["Jabu-Jabu Main"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Jabu-Jabu Pre-Boss Chest"] = function () return can_use_slingshot() end,
            ["MQ Jabu-Jabu GS Pre-Boss"] = function () return gs() and can_boomerang() end,
            ["MQ Jabu-Jabu Pot Before Boss"] = function () return true end,
            ["MQ Jabu-Jabu Grass Before Boss 1"] = function () return can_cut_grass() end,
            ["MQ Jabu-Jabu Grass Before Boss 2"] = function () return can_cut_grass() end,
        },
    },
    ["Shadow Temple"] = {
        ["exits"] = {
            ["Graveyard Upper"] = function () return true end,
            ["Shadow Temple Truth Spinner"] = function () return has_lens() and (can_hookshot() or has_hover_boots() or glitch_megaflip()) end,
        },
    },
    ["Shadow Temple Truth Spinner"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Shadow Temple First Locked Door"] = function () return has_explosives() and small_keys_shadow(6) end,
            ["Shadow Temple First Beamos"] = function () return has_fire_arrows() or has_hover_boots() or glitch_megaflip() end,
        },
    },
    ["Shadow Temple First Locked Door"] = {
        ["locations"] = {
            ["MQ Shadow Temple Compass Chest"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_sticks() or can_use_din()) end,
            ["MQ Shadow Temple Hover Boots Chest"] = function () return can_play_time() and can_hit_triggers_distance() and soul_enemy(SOUL_ENEMY_DEAD_HAND) and (has_weapon() or (can_use_sticks() and trick('OOT_DEAD_HAND_STICKS'))) end,
            ["MQ Shadow Temple Pot Entrance Maze 1"] = function () return true end,
            ["MQ Shadow Temple Pot Entrance Maze 2"] = function () return true end,
            ["MQ Shadow Temple Flying Pot Entrance Maze 1"] = function () return soul_flying_pot() end,
            ["MQ Shadow Temple Flying Pot Entrance Maze 2"] = function () return soul_flying_pot() end,
            ["MQ Shadow Temple Flying Pot Entrance Maze 3"] = function () return soul_flying_pot() and can_play_time() end,
            ["MQ Shadow Temple Flying Pot Entrance Maze 4"] = function () return soul_flying_pot() and can_play_time() end,
            ["MQ Shadow Temple Pot Compass Room 1"] = function () return has_weapon() or can_use_sticks() or can_use_din() or can_play_sun() end,
            ["MQ Shadow Temple Pot Compass Room 2"] = function () return has_weapon() or can_use_sticks() or can_use_din() or can_play_sun() end,
        },
    },
    ["Shadow Temple First Beamos"] = {
        ["exits"] = {
            ["Shadow Temple Upper Huge Pit"] = function () return has_explosives() and small_keys_shadow(2) end,
            ["Shadow Temple Scythe Room"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Shadow Temple First Gibdos Chest"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_sticks() or can_use_din()) end,
            ["MQ Shadow Temple Boat Passage Chest"] = function () return true end,
            ["MQ Shadow Temple Beamos Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Shadow Temple Scythe Room"] = {
        ["exits"] = {
            ["Shadow Temple First Beamos"] = function () return silver_rupees_shadow_blades() and soul_skulltula() and (can_damage() or has_ranged_weapon_adult() or can_use_slingshot() or can_hammer()) end,
        },
        ["locations"] = {
            ["MQ Shadow Temple SR Scythe 1"] = function () return true end,
            ["MQ Shadow Temple SR Scythe 2"] = function () return can_hookshot() or (is_adult() and has_hover_boots()) end,
            ["MQ Shadow Temple SR Scythe 3"] = function () return true end,
            ["MQ Shadow Temple SR Scythe 4"] = function () return true end,
            ["MQ Shadow Temple SR Scythe 5"] = function () return true end,
            ["MQ Shadow Temple Map Chest"] = function () return silver_rupees_shadow_scythe() end,
        },
    },
    ["Shadow Temple Upper Huge Pit"] = {
        ["events"] = {
            ["SHADOW_PIT_FIRE"] = function () return has_fire() end,
        },
        ["exits"] = {
            ["Shadow Temple Lower Huge Pit"] = function () return event('SHADOW_PIT_FIRE') end,
            ["Shadow Temple Invisible Blades Room"] = function () return true end,
        },
    },
    ["Shadow Temple Invisible Blades Room"] = {
        ["exits"] = {
            ["Shadow Temple Upper Huge Pit"] = function () return true end,
        },
        ["locations"] = {
            ["MQ Shadow Temple SR Invisible Blades Ground 1"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 2"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 3"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 4"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 5"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 6"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 7"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 8"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Ground 9"] = function () return true end,
            ["MQ Shadow Temple SR Invisible Blades Time Block"] = function () return can_play_time() and is_adult() end,
            ["MQ Shadow Temple Second Silver Rupee Visible Chest"] = function () return silver_rupees_shadow_blades() end,
            ["MQ Shadow Temple Second Silver Rupee Invisible Chest"] = function () return silver_rupees_shadow_blades() end,
            ["MQ Shadow Temple Heart Invisible Blades 1"] = function () return can_play_time() and is_adult() or hookshot_anywhere() or climb_anywhere() or can_boomerang() end,
            ["MQ Shadow Temple Heart Invisible Blades 2"] = function () return can_play_time() and is_adult() or hookshot_anywhere() or climb_anywhere() or can_boomerang() end,
        },
    },
    ["Shadow Temple Lower Huge Pit"] = {
        ["exits"] = {
            ["Shadow Temple Invisible Spike Floor"] = function () return small_keys_shadow(3) and has_hover_boots() end,
        },
        ["locations"] = {
            ["MQ Shadow Temple Huge Pit Silver Rupee Chest"] = function () return silver_rupees_shadow_pit() end,
            ["MQ Shadow Temple Spike Curtain Ground Chest"] = function () return true end,
            ["MQ Shadow Temple Spike Curtain Upper Cage Chest"] = function () return has_goron_bracelet() and is_adult() end,
            ["MQ Shadow Temple Spike Curtain Upper Switch Chest"] = function () return has_goron_bracelet() and is_adult() end,
            ["MQ Shadow Temple GS Spike Curtain"] = function () return gs() and can_collect_distance() end,
            ["MQ Shadow Temple SR Pit Back"] = function () return true end,
            ["MQ Shadow Temple SR Pit Midair Low"] = function () return can_longshot() end,
            ["MQ Shadow Temple SR Pit Midair High"] = function () return can_longshot() end,
            ["MQ Shadow Temple SR Pit Right"] = function () return true end,
            ["MQ Shadow Temple SR Pit Front"] = function () return true end,
            ["MQ Shadow Temple Pot Guillotines Room Lower 1"] = function () return true end,
            ["MQ Shadow Temple Pot Guillotines Room Lower 2"] = function () return true end,
            ["MQ Shadow Temple Pot Guillotines Room Upper 1"] = function () return has_goron_bracelet() and is_adult() end,
            ["MQ Shadow Temple Pot Guillotines Room Upper 2"] = function () return has_goron_bracelet() and is_adult() end,
            ["MQ Shadow Temple Guillotines Room Big Fairy"] = function () return can_play_storms() end,
        },
    },
    ["Shadow Temple Invisible Spike Floor"] = {
        ["exits"] = {
            ["Shadow Temple Wind Tunnel"] = function () return small_keys_shadow(4) and can_hookshot() end,
        },
        ["locations"] = {
            ["MQ Shadow Temple Invisible Spike Floor Chest"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_sticks() or can_use_din()) end,
            ["MQ Shadow Temple Stalfos Room Chest"] = function () return silver_rupees_shadow_spikes_mq() and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() end,
            ["MQ Shadow Temple SR Spikes Left Corner"] = function () return can_hookshot() end,
            ["MQ Shadow Temple SR Spikes Left Wall"] = function () return can_hookshot() end,
            ["MQ Shadow Temple SR Spikes Left Midair"] = function () return can_hookshot() end,
            ["MQ Shadow Temple SR Spikes Center Platforms"] = function () return can_hookshot() end,
            ["MQ Shadow Temple SR Spikes Center Ground"] = function () return true end,
            ["MQ Shadow Temple SR Spikes Center Midair"] = function () return can_hookshot() end,
            ["MQ Shadow Temple SR Spikes Front Midair"] = function () return can_hookshot() end,
            ["MQ Shadow Temple SR Spikes Right Ground"] = function () return true end,
            ["MQ Shadow Temple SR Spikes Right Back Wall"] = function () return can_hookshot() end,
            ["MQ Shadow Temple SR Spikes Right Lateral Wall"] = function () return can_hookshot() end,
        },
    },
    ["Shadow Temple Wind Tunnel"] = {
        ["exits"] = {
            ["Shadow Temple After Boat"] = function () return small_keys_shadow(5) and can_play_zelda() and is_adult() and (can_hookshot() or has_goron_bracelet()) end,
        },
        ["locations"] = {
            ["MQ Shadow Temple Wind Hint Chest"] = function () return true end,
            ["MQ Shadow Temple After Wind Gibdos Chest"] = function () return soul_redead_gibdo() and (has_weapon() or can_use_sticks() or can_use_din()) end,
            ["MQ Shadow Temple After Wind Bomb Chest"] = function () return has_explosives() end,
            ["MQ Shadow Temple GS Wind Hint"] = function () return gs() end,
            ["MQ Shadow Temple GS After Wind Bomb"] = function () return gs() and has_explosives() end,
            ["MQ Shadow Temple Pot Room Before Boat 1"] = function () return has_weapon() or can_use_sticks() or can_use_din() or can_play_sun() end,
            ["MQ Shadow Temple Pot Room Before Boat 2"] = function () return has_weapon() or can_use_sticks() or can_use_din() or can_play_sun() end,
            ["MQ Shadow Temple Flying Pot Room Before Boat 1"] = function () return soul_flying_pot() and ((has_weapon() or can_use_sticks() or can_use_din()) or can_play_sun()) end,
            ["MQ Shadow Temple Flying Pot Room Before Boat 2"] = function () return soul_flying_pot() and ((has_weapon() or can_use_sticks() or can_use_din()) or can_play_sun()) end,
            ["MQ Shadow Temple Big Fairy After Wind"] = function () return can_play_sun() end,
            ["MQ Shadow Temple Heart Shortcut 1"] = function () return small_keys_shadow(5) and (scarecrow_longshot() or hookshot_anywhere() or climb_anywhere()) end,
            ["MQ Shadow Temple Heart Shortcut 2"] = function () return small_keys_shadow(5) and (scarecrow_longshot() or hookshot_anywhere() or climb_anywhere()) end,
        },
    },
    ["Shadow Temple After Boat"] = {
        ["exits"] = {
            ["Shadow Temple Boss"] = function () return boss_key(BOSS_KEY_SHADOW) and can_use_bow() or longshot_anywhere() or climb_anywhere() end,
            ["Shadow Temple Final Side Rooms"] = function () return can_use_bow() and (can_play_time() and can_longshot() or hookshot_anywhere()) or longshot_anywhere() or climb_anywhere() end,
        },
        ["locations"] = {
            ["MQ Shadow Temple GS After Boat"] = function () return gs() end,
            ["MQ Shadow Temple GS Pre-Boss"] = function () return gs() and can_use_bow() end,
            ["MQ Shadow Temple Pot After Boat Before Bridge 1"] = function () return true end,
            ["MQ Shadow Temple Pot After Boat Before Bridge 2"] = function () return true end,
            ["MQ Shadow Temple Pot After Boat After Bridge 1"] = function () return can_use_bow() end,
            ["MQ Shadow Temple Pot After Boat After Bridge 2"] = function () return can_use_bow() end,
            ["MQ Shadow Temple Heart Pre-Boss Upper 1"] = function () return can_use_bow() and (can_play_time() and can_longshot() or hookshot_anywhere()) or longshot_anywhere() or climb_anywhere() end,
            ["MQ Shadow Temple Heart Pre-Boss Upper 2"] = function () return can_use_bow() and (can_play_time() and can_longshot() or hookshot_anywhere()) or longshot_anywhere() or climb_anywhere() end,
            ["MQ Shadow Temple Heart Pre-Boss Lower"] = function () return can_use_bow() or longshot_anywhere() or climb_anywhere() end,
        },
    },
    ["Shadow Temple Final Side Rooms"] = {
        ["locations"] = {
            ["MQ Shadow Temple Hidden Dead Hand Chest"] = function () return has_bombflowers() and soul_enemy(SOUL_ENEMY_DEAD_HAND) end,
            ["MQ Shadow Temple Triple Pot Key"] = function () return has_bombflowers() end,
            ["MQ Shadow Temple Boss Key Chest"] = function () return small_keys_shadow(6) and can_use_din() end,
            ["MQ Shadow Temple Crushing Wall Left Chest"] = function () return small_keys_shadow(6) and can_use_din() end,
            ["MQ Shadow Temple Pot Bomb Flowers Room 1"] = function () return true end,
            ["MQ Shadow Temple Pot Bomb Flowers Room 2"] = function () return true end,
            ["MQ Shadow Temple Pot Boss Key Room"] = function () return small_keys_shadow(6) end,
        },
    },
    ["Spirit Temple"] = {
        ["events"] = {
            ["SPIRIT_LOBBY_BOULDERS"] = function () return has_explosives_or_hammer() end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Desert Colossus Spirit Exit"] = function () return true end,
            ["Spirit Temple Child Side"] = function () return is_child() end,
            ["Spirit Temple Statue"] = function () return can_longshot() and has_bombchu() and can_lift_silver() end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Entrance Initial Chest"] = function () return true end,
            ["MQ Spirit Temple Lobby Back-Left Chest"] = function () return event('SPIRIT_LOBBY_BOULDERS') and can_hit_triggers_distance() end,
            ["MQ Spirit Temple Lobby Back-Right Chest"] = function () return can_hit_triggers_distance() or has_bombchu() or can_hookshot() end,
            ["MQ Spirit Temple Compass Chest"] = function () return can_use_slingshot() and has_bow() and small_keys_spirit(2) and has_bombchu() end,
            ["MQ Spirit Temple Sun Block Room Chest"] = function () return small_keys_spirit(2) and has_bombchu() and (can_play_time() or can_play_elegy()) and is_child() end,
            ["MQ Spirit Temple Lobby Front-Right Chest"] = function () return silver_rupees_spirit_lobby() end,
            ["Spirit Temple Silver Gauntlets"] = function () return small_keys_spirit(4) and has_explosives() and (can_play_time() or can_play_elegy()) and is_child() and soul_iron_knuckle() and (has_weapon() or can_use_sticks()) and has_lens() end,
            ["MQ Spirit Temple SR Lobby Rock Right"] = function () return has_explosives_or_hammer() end,
            ["MQ Spirit Temple SR Lobby Rock Left"] = function () return has_explosives_or_hammer() end,
            ["MQ Spirit Temple Pot Entrance 1"] = function () return true end,
            ["MQ Spirit Temple Pot Entrance 2"] = function () return true end,
            ["MQ Spirit Temple Pot Entrance 3"] = function () return true end,
            ["MQ Spirit Temple Pot Entrance 4"] = function () return true end,
        },
    },
    ["Spirit Temple Wallmaster Child Sun"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Spirit Temple Wallmaster Adult Climb"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Spirit Temple Wallmaster Statue"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Spirit Temple Child Side"] = {
        ["events"] = {
            ["SPIRIT_PARADOX"] = function () return has_bombchu() and can_hammer() end,
        },
        ["exits"] = {
            ["Spirit Temple Child Upper"] = function () return has_bombchu() and small_keys_spirit(6) end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Map Chest"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and (can_use_sticks() or has_weapon() or (has_explosives() and has_nuts())) end,
            ["MQ Spirit Temple Map Room Back Chest"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and soul_redead_gibdo() and soul_enemy(SOUL_ENEMY_STALFOS) and soul_keese() and soul_enemy(SOUL_ENEMY_ANUBIS) and has_weapon() and has_bombchu() and can_use_slingshot() and can_use_din() end,
            ["MQ Spirit Temple Paradox Chest"] = function () return event('SPIRIT_PARADOX') end,
            ["MQ Spirit Temple Pot Child Entrance"] = function () return true end,
            ["MQ Spirit Temple Pot Child Boulders 1"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and (can_use_sticks() or has_weapon() or (has_explosives() and has_nuts())) and has_bombchu() and can_use_slingshot() end,
            ["MQ Spirit Temple Pot Child Boulders 2"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and (can_use_sticks() or has_weapon() or (has_explosives() and has_nuts())) and has_bombchu() and can_use_slingshot() end,
            ["MQ Spirit Temple Pot Child Back 1"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and soul_redead_gibdo() and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and has_bombchu() and can_use_slingshot() end,
            ["MQ Spirit Temple Pot Child Back 2"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and soul_redead_gibdo() and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and has_bombchu() and can_use_slingshot() end,
            ["MQ Spirit Temple Pot Child Back 3"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and soul_redead_gibdo() and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and has_bombchu() and can_use_slingshot() end,
            ["MQ Spirit Temple Pot Child Back 4"] = function () return soul_enemy(SOUL_ENEMY_TORCH_SLUG) and (not setting('restoreBrokenActors') or soul_keese()) and soul_redead_gibdo() and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() and has_bombchu() and can_use_slingshot() end,
            ["MQ Spirit Temple Heart 1"] = function () return can_hit_triggers_distance() end,
            ["MQ Spirit Temple Heart 2"] = function () return can_hit_triggers_distance() end,
        },
    },
    ["Spirit Temple Child Upper"] = {
        ["events"] = {
            ["SPIRIT_PARADOX"] = function () return can_hammer() and small_keys_spirit(7) end,
        },
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return small_keys_spirit(7) end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Child Upper Ground Chest"] = function () return soul_like_like() and soul_beamos() and soul_enemy(SOUL_ENEMY_BABY_DODONGO) end,
            ["MQ Spirit Temple Child Upper Ledge Chest"] = function () return can_hookshot() end,
            ["MQ Spirit Temple Pot Child Climb"] = function () return true end,
        },
    },
    ["Spirit Temple Statue"] = {
        ["events"] = {
            ["SPIRIT_STATUE_FIRE"] = function () return has_fire() end,
        },
        ["exits"] = {
            ["Spirit Temple Wallmaster Statue"] = function () return soul_wallmaster() end,
            ["Spirit Temple Wallmaster Adult Climb"] = function () return has_fire_arrows() and can_reflect_light() and soul_wallmaster() end,
            ["Spirit Temple Child Upper"] = function () return small_keys_spirit(7) end,
            ["Spirit Temple Sun Block Room"] = function () return is_adult() or (can_play_time() or can_play_elegy()) or has_hover_boots() end,
            ["Spirit Temple Adult Lower"] = function () return has_fire_arrows() and can_reflect_light() and soul_enemy(SOUL_ENEMY_STALFOS) and soul_wallmaster() and has_weapon() end,
            ["Spirit Temple Adult Upper"] = function () return is_adult() and small_keys_spirit(5) end,
            ["Spirit Temple Boss"] = function () return event('SPIRIT_TEMPLE_LIGHT') and has_mirror_shield() and boss_key(BOSS_KEY_SPIRIT) and is_adult() end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Silver Block Room Target Chest"] = function () return event('SPIRIT_STATUE_FIRE') and can_use_slingshot() end,
            ["MQ Spirit Temple Compass Chest"] = function () return can_use_slingshot() or can_use_bow() end,
            ["MQ Spirit Temple Chest in Box"] = function () return can_play_zelda() and (is_adult() or (has_hover_boots() and trick('OOT_SPIRIT_CHILD_HOVER'))) end,
            ["MQ Spirit Temple Statue Room Ledge Chest"] = function () return (is_adult() or (has_hover_boots() and trick('OOT_SPIRIT_CHILD_HOVER'))) and has_lens() end,
            ["MQ Spirit Temple Pot Statue Room Lower 1"] = function () return true end,
            ["MQ Spirit Temple Pot Statue Room Lower 2"] = function () return true end,
            ["MQ Spirit Temple Pot Statue Room Lower 3"] = function () return true end,
            ["MQ Spirit Temple Flying Pot Statue Room Lower"] = function () return soul_flying_pot() end,
            ["MQ Spirit Temple Flying Pot Statue Room Stairs"] = function () return soul_flying_pot() end,
            ["MQ Spirit Temple Flying Pot Statue Room Upper"] = function () return soul_flying_pot() and (can_play_time() or has_hover_boots()) end,
            ["MQ Spirit Temple Pot Statue Room Upper 1"] = function () return can_play_time() or has_hover_boots() end,
            ["MQ Spirit Temple Pot Statue Room Upper 2"] = function () return can_play_time() or has_hover_boots() end,
        },
    },
    ["Spirit Temple Sun Block Room"] = {
        ["exits"] = {
            ["Spirit Temple Wallmaster Child Sun"] = function () return soul_wallmaster() end,
            ["Spirit Temple Child Hand"] = function () return soul_iron_knuckle() and (small_keys_spirit(7) and (has_weapon() or can_use_sticks())) or (is_adult() and small_keys_spirit(4) and has_lens() and (can_play_time() or can_play_elegy()) and soul_floormaster()) end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Sun Block Room Chest"] = function () return true end,
            ["MQ Spirit Temple GS Sun Block Room"] = function () return gs() and is_adult() end,
            ["MQ Spirit Temple Pot Child Sun Room 1"] = function () return true end,
            ["MQ Spirit Temple Pot Child Sun Room 2"] = function () return true end,
        },
    },
    ["Spirit Temple Child Hand"] = {
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Silver Gauntlets"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Lower"] = {
        ["locations"] = {
            ["MQ Spirit Temple Purple Leever Chest"] = function () return can_collect_distance() and soul_leever() end,
            ["MQ Spirit Temple Symphony Room Chest"] = function () return small_keys_spirit(7) and can_hammer() and can_play_time() and can_play_epona() and can_play_sun() and can_play_storms() and can_play_zelda() end,
            ["MQ Spirit Temple GS Leever Room"] = function () return gs() end,
            ["MQ Spirit Temple GS Symphony Room"] = function () return gs() and can_collect_distance() and small_keys_spirit(7) and can_hammer() and can_play_time() and can_play_epona() and can_play_sun() and can_play_storms() and can_play_zelda() end,
            ["MQ Spirit Temple SR Lobby In Water"] = function () return can_hammer() end,
            ["MQ Spirit Temple SR Lobby After Water Near Stairs"] = function () return true end,
            ["MQ Spirit Temple SR Lobby After Water Near Door"] = function () return true end,
            ["MQ Spirit Temple Pot Adult Climb 1"] = function () return true end,
            ["MQ Spirit Temple Pot Adult Climb 2"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Upper"] = {
        ["exits"] = {
            ["Spirit Temple Adult Upper 2"] = function () return can_play_time() end,
            ["Spirit Temple Adult Climb"] = function () return small_keys_spirit(6) end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Beamos Room Chest"] = function () return soul_beamos() end,
        },
    },
    ["Spirit Temple Adult Upper 2"] = {
        ["exits"] = {
            ["Spirit Temple Adult Hand"] = function () return has_lens() and soul_iron_knuckle() and soul_floormaster() end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Dinolfos Room Chest"] = function () return true end,
            ["MQ Spirit Temple Dinolfos Room Big Fairy"] = function () return can_play_sun() end,
            ["MQ Spirit Temple Boss Key Chest"] = function () return can_reflect_light() end,
            ["Spirit Temple Mirror Shield"] = function () return has_lens() and soul_iron_knuckle() and soul_floormaster() end,
        },
    },
    ["Spirit Temple Adult Hand"] = {
        ["exits"] = {
            ["Spirit Temple Child Hand"] = function () return can_longshot() end,
            ["Spirit Temple Adult Upper 2"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Mirror Shield"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Climb"] = {
        ["exits"] = {
            ["Spirit Temple Top Floor"] = function () return silver_rupees_spirit_adult() end,
        },
        ["locations"] = {
            ["MQ Spirit Temple SR Adult Bottom"] = function () return true end,
            ["MQ Spirit Temple SR Adult Bottom-Center"] = function () return true end,
            ["MQ Spirit Temple SR Adult Center-Top"] = function () return true end,
            ["MQ Spirit Temple SR Adult Top"] = function () return true end,
            ["MQ Spirit Temple SR Adult Skulltula"] = function () return true end,
            ["MQ Spirit Temple Pot Topmost Climb 1"] = function () return true end,
            ["MQ Spirit Temple Pot Topmost Climb 2"] = function () return true end,
        },
    },
    ["Spirit Temple Top Floor"] = {
        ["events"] = {
            ["SPIRIT_TEMPLE_LIGHT"] = function () return can_play_zelda() and can_hammer() and has_mirror_shield() end,
        },
        ["locations"] = {
            ["MQ Spirit Temple Topmost Chest"] = function () return can_play_zelda() and can_hammer() and has_lens() end,
            ["MQ Spirit Temple GS Top Floor Left Wall"] = function () return gs() and small_keys_spirit(7) and soul_iron_knuckle() end,
            ["MQ Spirit Temple GS Top Floor Back Wall"] = function () return gs() and small_keys_spirit(7) and soul_iron_knuckle() end,
            ["MQ Spirit Temple Pot Top Near Triforce Symbol 1"] = function () return true end,
            ["MQ Spirit Temple Pot Top Near Triforce Symbol 2"] = function () return true end,
            ["MQ Spirit Temple Pot Top Near Lowering Platform 1"] = function () return can_play_zelda() end,
            ["MQ Spirit Temple Pot Top Near Lowering Platform 2"] = function () return can_play_zelda() end,
            ["MQ Spirit Temple Pot Top Near Lowering Platform 3"] = function () return can_play_zelda() end,
            ["MQ Spirit Temple Pot Top Near Lowering Platform 4"] = function () return can_play_zelda() end,
        },
    },
    ["Water Temple"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
            ["Water Temple Main"] = function () return true end,
        },
    },
    ["Water Temple Main"] = {
        ["events"] = {
            ["WATER_LEVEL_LOW"] = function () return has_iron_boots() and has_tunic_zora() and can_play_zelda() end,
            ["WATER_LEVEL_HIGH"] = function () return can_hookshot() or (is_adult() and has_hover_boots()) end,
        },
        ["exits"] = {
            ["Water Temple"] = function () return true end,
            ["Water Temple Dark Link"] = function () return small_keys_water(1) and event('WATER_LEVEL_HIGH') and can_longshot() end,
            ["Water Temple Three Torch Room"] = function () return event('WATER_GATES') end,
            ["Water Temple Side Loop"] = function () return event('WATER_GATES') and can_longshot() and (scarecrow_longshot() or has_hover_boots()) end,
            ["Water Temple Antichamber"] = function () return can_longshot() and event('WATER_LEVEL_HIGH') end,
        },
        ["locations"] = {
            ["MQ Water Temple Map Chest"] = function () return has_iron_boots() and has_tunic_zora() and has_fire() and can_hookshot() and event('WATER_LEVEL_HIGH') end,
            ["MQ Water Temple Compass Chest"] = function () return soul_enemy(SOUL_ENEMY_SPIKE) and soul_lizalfos_dinalfos() and event('WATER_LEVEL_LOW') and (can_use_bow() or has_fire()) and event('WATER_LEVEL_HIGH') end,
            ["MQ Water Temple Longshot Chest"] = function () return event('WATER_LEVEL_LOW') and can_hookshot() end,
            ["MQ Water Temple Central Pillar Chest"] = function () return can_play_time() and can_use_din() and can_hookshot() and has_iron_boots() and has_tunic_zora_strict() end,
            ["MQ Water Temple GS Lizalfos Hallway"] = function () return gs() and event('WATER_LEVEL_LOW') and can_use_din() end,
            ["MQ Water Temple GS High Water Changer"] = function () return gs() and event('WATER_LEVEL_LOW') and can_longshot() end,
            ["MQ Water Temple Pot Ruto 1"] = function () return has_iron_boots() and has_tunic_zora() and (can_hookshot() or event('WATER_LEVEL_LOW')) end,
            ["MQ Water Temple Pot Ruto 2"] = function () return has_iron_boots() and has_tunic_zora() and (can_hookshot() or event('WATER_LEVEL_LOW')) end,
            ["MQ Water Temple Pot Storage Room 1"] = function () return has_iron_boots() and has_tunic_zora() and can_hookshot() end,
            ["MQ Water Temple Pot Storage Room 2"] = function () return has_iron_boots() and has_tunic_zora() and can_hookshot() end,
            ["MQ Water Temple Pot Storage Room 3"] = function () return has_iron_boots() and has_tunic_zora() and can_hookshot() end,
            ["MQ Water Temple Pot Twisted Room Entrance"] = function () return has_iron_boots() and has_tunic_zora() and (can_hookshot() or event('WATER_LEVEL_LOW')) end,
            ["MQ Water Temple Pot Twisted Room Right 1"] = function () return has_iron_boots() and has_tunic_zora() and (can_hookshot() or event('WATER_LEVEL_LOW')) end,
            ["MQ Water Temple Pot Twisted Room Right 2"] = function () return has_iron_boots() and has_tunic_zora() and (can_hookshot() or event('WATER_LEVEL_LOW')) end,
            ["MQ Water Temple Pot Twisted Room Cage 1"] = function () return event('WATER_LEVEL_LOW') and can_use_din() end,
            ["MQ Water Temple Pot Twisted Room Cage 2"] = function () return event('WATER_LEVEL_LOW') and can_use_din() end,
            ["MQ Water Temple Pot Room Before High Water 1"] = function () return event('WATER_LEVEL_LOW') and (can_hookshot() or can_play_elegy()) end,
            ["MQ Water Temple Pot Room Before High Water 2"] = function () return event('WATER_LEVEL_LOW') and (can_hookshot() or can_play_elegy()) end,
            ["MQ Water Temple Pot Room Before High Water 3"] = function () return event('WATER_LEVEL_LOW') and (can_hookshot() or can_play_elegy()) end,
        },
    },
    ["Water Temple Dark Link"] = {
        ["events"] = {
            ["WATER_GATES"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() and can_use_din() and has_iron_boots() and has_tunic_zora() and soul_enemy(SOUL_ENEMY_STALFOS) end,
        },
        ["locations"] = {
            ["MQ Water Temple Boss Key Chest"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() and can_use_din() and can_dive_small() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Water Temple GS River"] = function () return gs() and soul_enemy(SOUL_ENEMY_STALFOS) and soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() end,
            ["MQ Water Temple Pot Before Dark Link Ledge 1"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() or has_hover_boots() end,
            ["MQ Water Temple Pot Before Dark Link Ledge 2"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() or has_hover_boots() end,
            ["MQ Water Temple Pot Before Dark Link Ledge 3"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() or has_hover_boots() end,
            ["MQ Water Temple Big Fairy Before Dark Link Ledge"] = function () return can_play_sun() and (soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon()) or has_hover_boots() end,
            ["MQ Water Temple Pot Before Dark Link Near Door 1"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() end,
            ["MQ Water Temple Pot Before Dark Link Near Door 2"] = function () return soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() end,
            ["MQ Water Temple Pot After Dark Link 1"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Water Temple Pot After Dark Link 2"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Water Temple Pot River 1"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Water Temple Pot River 2"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Water Temple Pot Boss Key Room"] = function () return soul_enemy(SOUL_ENEMY_DARK_LINK) and has_weapon() and can_use_din() and can_dive_small() and soul_enemy(SOUL_ENEMY_STALFOS) end,
            ["MQ Water Temple Big Fairy Before Dark Link Near Door 1"] = function () return can_play_sun() and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() end,
            ["MQ Water Temple Big Fairy Before Dark Link Near Door 2"] = function () return can_play_storms() and soul_enemy(SOUL_ENEMY_STALFOS) and has_weapon() end,
        },
    },
    ["Water Temple Three Torch Room"] = {
        ["locations"] = {
            ["MQ Water Temple GS Three Torch"] = function () return gs() and has_fire_arrows() and (scarecrow_hookshot() or has_hover_boots()) end,
            ["MQ Water Temple Pot Skull Cage 1"] = function () return has_fire_arrows() and (scarecrow_hookshot() or has_hover_boots()) end,
            ["MQ Water Temple Pot Skull Cage 2"] = function () return has_fire_arrows() and (scarecrow_hookshot() or has_hover_boots()) end,
            ["MQ Water Temple Pot Skull Cage 3"] = function () return has_fire_arrows() and (scarecrow_hookshot() or has_hover_boots()) end,
            ["MQ Water Temple Pot Skull Cage 4"] = function () return has_fire_arrows() and (scarecrow_hookshot() or has_hover_boots()) end,
        },
    },
    ["Water Temple Side Loop"] = {
        ["locations"] = {
            ["MQ Water Temple Side Loop Key"] = function () return true end,
            ["MQ Water Temple GS Side Loop"] = function () return gs() and has_fire() and small_keys_water(2) and soul_dodongo() end,
            ["MQ Water Temple Pot Stalfos Room 1"] = function () return true end,
            ["MQ Water Temple Pot Stalfos Room 2"] = function () return true end,
            ["MQ Water Temple Pot Loop 1"] = function () return has_fire() and small_keys_water(2) end,
            ["MQ Water Temple Pot Loop 2"] = function () return has_fire() and small_keys_water(2) end,
        },
    },
    ["Water Temple Antichamber"] = {
        ["exits"] = {
            ["Water Temple Boss"] = function () return boss_key(BOSS_KEY_WATER) end,
        },
    },
}

    return M
end
