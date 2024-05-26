-- NOTE: This file is auto-generated. Any changes will be overwritten.

-- SPDX-FileCopyrightText: 2023 Wilhelm Schürmann <wimschuermann@googlemail.com>
--
-- SPDX-License-Identifier: MIT

-- The OoTMM logic is kept as-is, which means having global lowercase functions.
-- Disable warnings for this.
---@diagnostic disable: lowercase-global

-- This is for namespacing only, because EmoTracker doesn't seem to properly support require()
function _mm_logic()
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

    OOTMM_ITEM_PREFIX = "MM"
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
            ["MAGIC_BEANS_PALACE"] = { ["type"] = "has" },
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

	function clock_separate(x)
		return not setting('clocks') or (setting('progressiveClocks', 'separate') and has(x))
	end

	function clock_ascending(x)
		return not setting('clocks') or (setting('progressiveClocks', 'ascending') and has('CLOCK', x))
	end

	function clock_descending(x)
		return not setting('clocks') or (setting('progressiveClocks', 'descending') and has('CLOCK', x))
	end

	function clock_day1()
		return clock_separate(CLOCK1) or clock_ascending(0) or clock_descending(5)
	end

	function clock_night1()
		return clock_separate(CLOCK2) or clock_ascending(1) or clock_descending(4)
	end

	function clock_day2()
		return clock_separate(CLOCK3) or clock_ascending(2) or clock_descending(3)
	end

	function clock_night2()
		return clock_separate(CLOCK4) or clock_ascending(3) or clock_descending(2)
	end

	function clock_day3()
		return clock_separate(CLOCK5) or clock_ascending(4) or clock_descending(1)
	end

	function clock_night3()
		return clock_separate(CLOCK6) or clock_ascending(5) or clock_descending(0)
	end

	function raw_at(x)
		return mm_time('at', x)
	end

	function raw_after(x)
		return mm_time('after', x)
	end

	function raw_before(x)
		return mm_time('before', x)
	end

	function raw_between(a, b)
		return mm_time('between', a, b)
	end

	function is_day1()
		return raw_before(NIGHT1_PM_06_00) and clock_day1()
	end

	function is_night1()
		return raw_between(NIGHT1_PM_06_00, DAY2_AM_06_00) and clock_night1()
	end

	function is_day2()
		return raw_between(DAY2_AM_06_00, NIGHT2_PM_06_00) and clock_day2()
	end

	function is_night2()
		return raw_between(NIGHT2_PM_06_00, DAY3_AM_06_00) and clock_night2()
	end

	function is_day3()
		return raw_between(DAY3_AM_06_00, NIGHT3_PM_06_00) and clock_day3()
	end

	function is_night3()
		return raw_after(NIGHT3_PM_06_00) and clock_night3()
	end

	function clock_filter()
		return not setting('clocks') or is_day1() or is_night1() or is_day2() or is_night2() or is_day3() or is_night3()
	end

	function is_day()
		return is_day1() or is_day2() or is_day3()
	end

	function is_night()
		return is_night1() or is_night2() or is_night3()
	end

	function first_day()
		return is_day1() or is_night1()
	end

	function second_day()
		return is_day2() or is_night2()
	end

	function final_day()
		return is_day3() or is_night3()
	end

	function between(a, b)
		return raw_between(a, b) and clock_filter()
	end

	function after(a)
		return raw_after(a) and clock_filter()
	end

	function before(a)
		return raw_before(a) and clock_filter()
	end

	function at(a)
		return raw_at(a) and clock_filter()
	end

	function midnight()
		return between(NIGHT1_AM_12_00, DAY2_AM_06_00) or between(NIGHT2_AM_12_00, DAY3_AM_06_00) or after(NIGHT3_AM_12_00)
	end

	function is_winter()
		return flag_on(MM_REGION_NORTH_CURSED) and flag_off(MM_REGION_NORTH_CLEARED)
	end

	function is_spring()
		return flag_on(MM_REGION_NORTH_CLEARED) and flag_off(MM_REGION_NORTH_CURSED) and event('BOSS_SNOWHEAD')
	end

	function is_spring_or_winter()
		return flag_off(MM_REGION_NORTH_CLEARED) and flag_off(MM_REGION_NORTH_CURSED)
	end

	function is_swamp_poisoned()
		return flag_on(MM_REGION_SWAMP_CURSED) and flag_off(MM_REGION_SWAMP_CLEARED)
	end

	function is_swamp_cleared()
		return flag_on(MM_REGION_SWAMP_CLEARED) and flag_off(MM_REGION_SWAMP_CURSED) and event('BOSS_WOODFALL')
	end

	function is_ocean_cursed()
		return flag_on(MM_REGION_OCEAN_CURSED) and flag_off(MM_REGION_OCEAN_CLEARED)
	end

	function is_ocean_cleared()
		return flag_on(MM_REGION_OCEAN_CLEARED) and flag_off(MM_REGION_OCEAN_CURSED) and event('BOSS_GREAT_BAY')
	end

	function is_valley_cursed()
		return flag_on(MM_REGION_VALLEY_CURSED) and flag_off(MM_REGION_VALLEY_CLEARED)
	end

	function is_valley_cleared()
		return flag_on(MM_REGION_VALLEY_CLEARED) and flag_off(MM_REGION_VALLEY_CURSED) and event('BOSS_STONE_TOWER')
	end

	function is_child()
		return not setting('crossAge') or age('child')
	end

	function is_adult()
		return setting('crossAge') and age('adult')
	end

	function is_tall()
		return has_mask_zora() or is_adult()
	end

	function is_short()
		return has('MASK_DEKU') or is_child()
	end

	function can_use_din()
		return setting('spellFireMm') and can_use_din_raw()
	end

	function can_use_farore()
		return setting('spellWindMm') and can_use_farore_raw()
	end

	function can_use_nayru()
		return setting('spellLoveMm') and can_use_nayru_raw()
	end

	function has_iron_boots()
		return setting('bootsIronMm') and has_iron_boots_raw()
	end

	function has_hover_boots()
		return setting('bootsHoverMm') and has_hover_boots_raw()
	end

	function has_tunic_goron_strict()
		return setting('tunicGoronMm') and has_tunic_goron_raw()
	end

	function has_tunic_zora_strict()
		return setting('tunicZoraMm') and has_tunic_zora_raw()
	end

	function has_tunic_goron()
		return has_tunic_goron_strict() or trick('MM_TUNICS')
	end

	function has_tunic_zora()
		return has_tunic_zora_strict() or trick('MM_TUNICS')
	end

	function can_dive_small()
		return setting('scalesMm') and has_scale_raw(1)
	end

	function can_dive_big()
		return setting('scalesMm') and has_scale_raw(2)
	end

	function can_lift_bracelet()
		return not setting('strengthMm') or has_strength_raw(1)
	end

	function can_lift_silver()
		return setting('strengthMm') and has_strength_raw(2)
	end

	function can_lift_gold()
		return setting('strengthMm') and has_strength_raw(3)
	end

	function ocarina_button(x, y)
		return cond(setting('ocarinaButtonsShuffleMm'), cond(setting('sharedOcarinaButtons'), has(y), has(x)), true)
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

	function has_ocarina_n(x)
		return has('OCARINA', x) or has('SHARED_OCARINA', x)
	end

	function has_ocarina()
		return cond(setting('sharedOcarina'), cond(setting('fairyOcarinaMm'), has_ocarina_n(1), has_ocarina_n(2)), has_ocarina_n(1))
	end

	function can_play(song)
		return has_ocarina() and has(song)
	end

	function can_play_cross(x)
		return can_play(x) and setting('crossWarpOot')
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

	function can_play_healing()
		return can_play(SONG_HEALING) and ocarina_button_down() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_soaring()
		return can_play(SONG_SOARING) and ocarina_button_down() and ocarina_button_up() and ocarina_button_left()
	end

	function can_play_awakening()
		return can_play(SONG_AWAKENING) and ocarina_button_up() and ocarina_button_right() and ocarina_button_left() and ocarina_button_a()
	end

	function can_play_goron_half()
		return has_ocarina() and has_goron_song_half() and ocarina_button_a() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_goron()
		return has_ocarina() and has_goron_song() and ocarina_button_a() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_zora()
		return can_play(SONG_ZORA) and ocarina_button_left() and ocarina_button_right() and ocarina_button_up() and ocarina_button_down()
	end

	function can_play_emptiness()
		return has_ocarina() and has_elegy_raw() and ocarina_button_left() and ocarina_button_right() and ocarina_button_up() and ocarina_button_down()
	end

	function can_play_order()
		return can_play(SONG_ORDER) and ocarina_button_right() and ocarina_button_down() and ocarina_button_up() and ocarina_button_a()
	end

	function can_play_evan()
		return has_ocarina() and ocarina_button_a() and ocarina_button_right() and ocarina_button_down() and ocarina_button_left()
	end

	function can_play_minigame()
		return has_ocarina() and ocarina_button_a() and ocarina_button_right() and ocarina_button_down() and ocarina_button_left() and ocarina_button_up()
	end

	function can_play_scarecrow()
		return has_ocarina() and ocarina_button_any2()
	end

	function can_play_cross_tp_light()
		return can_play_cross(OOT_SONG_TP_LIGHT) and ocarina_button_up() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_cross_tp_forest()
		return can_play_cross(OOT_SONG_TP_FOREST) and ocarina_button_a() and ocarina_button_up() and ocarina_button_right() and ocarina_button_left()
	end

	function can_play_cross_tp_fire()
		return can_play_cross(OOT_SONG_TP_FIRE) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down()
	end

	function can_play_cross_tp_water()
		return can_play_cross(OOT_SONG_TP_WATER) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down() and ocarina_button_left()
	end

	function can_play_cross_tp_shadow()
		return can_play_cross(OOT_SONG_TP_SHADOW) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down() and ocarina_button_left()
	end

	function can_play_cross_tp_spirit()
		return can_play_cross(OOT_SONG_TP_SPIRIT) and ocarina_button_a() and ocarina_button_right() and ocarina_button_down()
	end

	function keaton_grass_easy()
		return has_weapon() and has_magic()
	end

	function keaton_grass_hard()
		return keaton_grass_easy() and (has('SPIN_UPGRADE') or has('GREAT_FAIRY_SWORD') or has_sword_level(3))
	end

	function has_sword_level(n)
		return cond(setting('sharedSwords'), has('SHARED_SWORD', n), has('SWORD', n))
	end

	function has_sword()
		return has_sword_level(1)
	end

	function has_weapon()
		return has_sword() or has('GREAT_FAIRY_SWORD')
	end

	function can_break_boulders()
		return has_explosives() or has_mask_goron()
	end

	function can_use_fire_short_range()
		return can_use_fire_arrows() or can_use_din()
	end

	function can_break_snowballs()
		return can_break_boulders() or can_use_fire_short_range()
	end

	function can_use_lens()
		return can_use_lens_strict() or trick('MM_LENS')
	end

	function can_use_lens_strict()
		return has_magic() and (has('LENS') or has('SHARED_LENS'))
	end

	function has_mask_stone()
		return cond(setting('sharedMaskStone'), has('SHARED_MASK_STONE'), has('MASK_STONE'))
	end

	function has_mask_blast()
		return cond(setting('sharedMaskBlast'), has('SHARED_MASK_BLAST'), has('MASK_BLAST'))
	end

	function has_explosives()
		return has_bombs() or has_mask_blast() or has_bombchu()
	end

	function can_use_fire_arrows()
		return has_magic() and has_arrows() and (has('ARROW_FIRE') or has('SHARED_ARROW_FIRE'))
	end

	function can_use_ice_arrows()
		return has_magic() and has_arrows() and (has('ARROW_ICE') or has('SHARED_ARROW_ICE'))
	end

	function can_use_light_arrows()
		return has_magic() and has_arrows() and (has('ARROW_LIGHT') or has('SHARED_ARROW_LIGHT'))
	end

	function can_use_keg()
		return event('BUY_KEG')
	end

	function has_mirror_shield_nonshared()
		return cond(setting('progressiveShieldsMm', 'progressive'), has('SHIELD', 2), has('SHIELD_MIRROR'))
	end

	function has_mirror_shield_shared()
		return cond(setting('progressiveShieldsMm', 'progressive'), has('SHARED_SHIELD', 3), has('SHARED_SHIELD_MIRROR'))
	end

	function has_mirror_shield()
		return cond(setting('sharedShields'), has_mirror_shield_shared(), has_mirror_shield_nonshared())
	end

	function can_use_elegy()
		return can_play_emptiness()
	end

	function can_use_elegy2()
		return can_play_emptiness() and (has_mask_zora() or has_mask_goron())
	end

	function can_use_elegy3()
		return can_play_emptiness() and has_mask_zora() and has_mask_goron()
	end

	function has_bomb_bag()
		return has('BOMB_BAG') or has('SHARED_BOMB_BAG')
	end

	function has_bombchu_source()
		return event('BOMBCHU') or renewable(BOMBCHU) or renewable(BOMBCHU_5) or renewable(BOMBCHU_10) or renewable(BOMBCHU_20) or (setting('bombchuBagMm') and event('BOMBS_OR_BOMBCHU')) or (setting('sharedBombchuBags') and (renewable(SHARED_BOMBCHU) or renewable(SHARED_BOMBCHU_5) or renewable(SHARED_BOMBCHU_10) or renewable(SHARED_BOMBCHU_20) or event('OOT_BOMBCHU') or event('OOT_BOMBS_OR_BOMBCHU')))
	end

	function has_bombchu_license_nonshared()
		return license(BOMBCHU) or license(BOMBCHU_5) or license(BOMBCHU_10) or license(BOMBCHU_20)
	end

	function has_bombchu_license_shared()
		return license(SHARED_BOMBCHU) or license(SHARED_BOMBCHU_5) or license(SHARED_BOMBCHU_10) or license(SHARED_BOMBCHU_20)
	end

	function has_bombchu_license()
		return cond(setting('bombchuBagMm'), cond(setting('sharedBombchuBags'), has_bombchu_license_shared(), has_bombchu_license_nonshared()), has_bomb_bag())
	end

	function has_bombchu()
		return has_bombchu_source() and has_bombchu_license()
	end

	function has_beans()
		return event('MAGIC_BEANS_PALACE') or (license(MAGIC_BEAN) and renewable(MAGIC_BEAN))
	end

	function can_use_beans()
		return has_beans() and (has_water() or can_play_storms())
	end

	function scarecrow_set()
		return event('SCARECROW') or setting('freeScarecrowMm')
	end

	function scarecrow_hookshot_short()
		return scarecrow_set() and has_ocarina() and can_hookshot_short()
	end

	function scarecrow_hookshot()
		return scarecrow_set() and has_ocarina() and can_hookshot()
	end

	function goron_fast_roll()
		return has_mask_goron() and has_magic()
	end

	function can_use_deku_bubble()
		return has('MASK_DEKU') and has_magic()
	end

	function has_weapon_range()
		return has_arrows() or can_hookshot_short() or has_mask_zora() or can_use_deku_bubble()
	end

	function has_paper()
		return has('DEED_LAND') or has('DEED_SWAMP') or has('DEED_MOUNTAIN') or has('DEED_OCEAN') or has('LETTER_TO_KAFEI') or has('LETTER_TO_MAMA')
	end

	function can_fight()
		return has_weapon() or has_mask_zora() or has_mask_goron()
	end

	function has_goron_song_half()
		return cond(setting('progressiveGoronLullaby', 'progressive'), has('SONG_GORON_HALF'), has('SONG_GORON'))
	end

	function has_goron_song()
		return cond(setting('progressiveGoronLullaby', 'progressive'), has('SONG_GORON_HALF', 2), has('SONG_GORON'))
	end

	function can_lullaby_half()
		return has_mask_goron() and can_play_goron_half()
	end

	function can_lullaby()
		return has_mask_goron() and can_play_goron()
	end

	function has_shield()
		return cond(setting('sharedShields'), renewable(SHARED_SHIELD_HYLIAN), renewable(SHIELD_HERO)) or has_mirror_shield()
	end

	function can_activate_crystal()
		return can_break_boulders() or has_weapon() or has_arrows() or can_hookshot_short() or has('MASK_DEKU') or has_mask_zora() or has_sticks()
	end

	function can_evade_gerudo()
		return has_arrows() or can_hookshot_short() or has_mask_zora() or has_mask_stone()
	end

	function can_goron_bomb_jump()
		return trick('MM_GORON_BOMB_JUMP') and has_mask_goron() and (has_bombs() or trick_keg_explosives())
	end

	function can_hookshot_n(x)
		return has('HOOKSHOT', x) or has('SHARED_HOOKSHOT', x)
	end

	function can_hookshot_short()
		return can_hookshot_n(1)
	end

	function can_hookshot()
		return cond(setting('shortHookshotMm'), can_hookshot_n(2), can_hookshot_n(1))
	end

	function trick_keg_explosives()
		return can_use_keg() and trick('MM_KEG_EXPLOSIVES')
	end

	function trick_sht_hot_water()
		return (has_hot_water_distance() and has('OWL_SNOWHEAD') or has_hot_water_er() or has_hot_water_farore()) and trick('MM_SHT_HOT_WATER')
	end

	function trick_sht_hot_water_er()
		return (has_hot_water_er() or has_hot_water_farore()) and trick('MM_SHT_HOT_WATER')
	end

	function can_reset_time()
		return setting('moonCrash', 'cycle') or can_play_time() or (event('MAJORA') and trick('MM_MAJORA_LOGIC') and (not is_goal_triforce()))
	end

	function can_reset_time_dungeon()
		return cond(setting('erMoon'), (trick('MM_MAJORA_LOGIC') and event('MAJORA') and (not is_goal_triforce()) or setting('moonCrash', 'cycle')) and (before(NIGHT3_AM_12_00) or can_use_farore() or setting('autoInvert', 'always')) or can_play_time(), can_reset_time())
	end

	function can_reset_time_on_moon()
		return can_play_time() or (event('MAJORA') and trick('MM_MAJORA_LOGIC') and (not is_goal_triforce()))
	end

	function has_sticks()
		return event('STICKS') or renewable(STICK) or renewable(SHARED_STICK) or renewable(SHARED_STICKS_5) or renewable(SHARED_STICKS_10) or (setting('sharedNutsSticks') and event('OOT_STICKS'))
	end

	function has_nuts()
		return event('NUTS') or renewable(NUT) or renewable(NUTS_5) or renewable(NUTS_10) or renewable(SHARED_NUT) or renewable(SHARED_NUTS_5) or renewable(SHARED_NUTS_10) or (setting('sharedNutsSticks') and event('OOT_NUTS'))
	end

	function has_bow()
		return has('BOW') or has('SHARED_BOW')
	end

	function has_arrows()
		return has_bow() and (event('ARROWS') or renewable(ARROWS_10) or renewable(ARROWS_30) or renewable(ARROWS_40) or renewable(SHARED_ARROWS_5) or renewable(SHARED_ARROWS_10) or renewable(SHARED_ARROWS_30) or renewable(SHARED_ARROWS_40))
	end

	function has_bombs()
		return has_bomb_bag() and (event('BOMBS') or event('BOMBS_OR_BOMBCHU') or (setting('sharedBombBags') and (event('OOT_BOMBS') or event('OOT_BOMBS_OR_BOMBCHU'))) or renewable(BOMBS_5) or renewable(BOMBS_10) or renewable(BOMBS_20) or renewable(BOMBS_30) or renewable(SHARED_BOMBS_5) or renewable(SHARED_BOMBS_10) or renewable(SHARED_BOMBS_20) or renewable(SHARED_BOMBS_30))
	end

	function has_magic()
		return (has('MAGIC_UPGRADE') or has('SHARED_MAGIC_UPGRADE')) and (event('MAGIC') or has_magic_jar() or has_green_potion() or has_blue_potion() or event('CHATEAU'))
	end

	function has_double_magic()
		return (has('MAGIC_UPGRADE', 2) or has('SHARED_MAGIC_UPGRADE', 2)) and (event('MAGIC') or has_green_potion() or has_blue_potion() or event('CHATEAU'))
	end

	function has_rupees()
		return event('RUPEES')
	end

	function can_kill_baba_nuts()
		return soul_deku_baba() and (can_fight() or has('MASK_DEKU') or can_hookshot_short() or has_explosives() or has_arrows())
	end

	function can_kill_baba_sticks()
		return soul_deku_baba() and (can_fight() or has('MASK_DEKU') or can_hookshot_short() or has_explosives() or has_arrows())
	end

	function can_kill_baba_both_sticks()
		return soul_deku_baba() and (has_weapon() or has('MASK_DEKU'))
	end

	function bombers1()
		return event('BOMBERS_NORTH1') and event('BOMBERS_EAST1') and event('BOMBERS_WEST1')
	end

	function bombers2()
		return event('BOMBERS_NORTH2') and event('BOMBERS_EAST2') and event('BOMBERS_WEST2')
	end

	function bombers3()
		return event('BOMBERS_NORTH3') and event('BOMBERS_EAST3') and event('BOMBERS_WEST3')
	end

	function has_fire_sticks()
		return has_sticks() or can_use_fire_short_range()
	end

	function can_pass_gibdo()
		return has('MASK_GIBDO') and soul_redead_gibdo()
	end

	function can_get_gossip_fairy()
		return can_play_healing() or can_play_epona()
	end

	function can_jumpslash()
		return has_weapon() or has_sticks() or has_mask_zora()
	end

	function can_enter_zora_door()
		return has_mask_zora() or is_ocean_cleared() or (short_hook_anywhere() and trick('MM_ZORA_HALL_DOORS'))
	end

	function woodfall_raised()
		return event('OPEN_WOODFALL_TEMPLE') or setting('openDungeonsMm', 'WF') or ((setting('clearStateDungeonsMm', 'WF') or setting('clearStateDungeonsMm', 'both')) and is_swamp_cleared())
	end

	function blizzard_stopped()
		return event('OPEN_SNOWHEAD_TEMPLE') or setting('openDungeonsMm', 'SH') or is_spring()
	end

	function turtle_woken()
		return can_play_zora() and has_mask_zora() or setting('openDungeonsMm', 'GB') or ((setting('clearStateDungeonsMm', 'GB') or setting('clearStateDungeonsMm', 'both')) and is_ocean_cleared())
	end

	function can_kill_freezard_short_range()
		return can_fight() or can_use_light_arrows() or can_use_fire_short_range() or has_explosives() or can_hookshot_short()
	end

	function underwater_walking()
		return has_mask_zora() or (has_tunic_zora() and has_iron_boots())
	end

	function underwater_walking_strict()
		return has_mask_zora() or (has_tunic_zora_strict() and has_iron_boots())
	end

	function has_hot_water_mtn()
		return has_bottle() and (event('HOT_WATER_NORTH') or (is_spring() and event('HOT_WATER_NORTH_SPRING')) or (is_winter() and event('HOT_WATER_NORTH_WINTER')))
	end

	function has_hot_water_well()
		return has_bottle() and (event('WELL_HOT_WATER') or (is_spring() and event('WELL_HOT_WATER_SPRING')) or (is_winter() and event('WELL_HOT_WATER_WINTER')))
	end

	function has_hot_water_distance()
		return (can_play_soaring() or can_use_farore()) and (has_hot_water_mtn() or has_hot_water_well())
	end

	function has_hot_water_er()
		return er_enabled() and (has_hot_water_mtn() or has_hot_water_well())
	end

	function has_hot_water_farore()
		return can_use_farore() and (has_hot_water_mtn() or has_hot_water_well())
	end

	function has_bottle()
		return has('BOTTLE_EMPTY') or has('BOTTLE_POTION_RED') or has('BOTTLE_POTION_GREEN') or has('BOTTLE_POTION_BLUE') or has('BOTTLE_MILK') or event('GOLD_DUST_USED') or has('BOTTLE_CHATEAU') or has('BOTTLE_FAIRY') or has('BOTTLE_POE') or has('BOTTLE_BIG_POE')
	end

	function has_blue_potion()
		return has_bottle() and (renewable(POTION_BLUE) or renewable(BOTTLE_POTION_BLUE))
	end

	function has_red_potion()
		return has_bottle() and (renewable(POTION_RED) or renewable(BOTTLE_POTION_RED))
	end

	function has_green_potion()
		return has_bottle() and (renewable(POTION_GREEN) or renewable(BOTTLE_POTION_GREEN))
	end

	function has_milk()
		return has_bottle() and (renewable(MILK) or renewable(BOTTLE_MILK))
	end

	function has_red_or_blue_potion()
		return has_red_potion() or has_blue_potion()
	end

	function has_zora_egg()
		return has_bottle() and (event('ZORA_EGGS_HOOKSHOT_ROOM') or event('ZORA_EGGS_BARREL_MAZE') or event('ZORA_EGGS_LONE_GUARD') or event('ZORA_EGGS_TREASURE_ROOM') or event('ZORA_EGGS_PINNACLE_ROCK'))
	end

	function has_all_zora_eggs()
		return has_bottle() and event('ZORA_EGGS_HOOKSHOT_ROOM') and event('ZORA_EGGS_BARREL_MAZE') and event('ZORA_EGGS_LONE_GUARD') and event('ZORA_EGGS_TREASURE_ROOM') and event('ZORA_EGGS_PINNACLE_ROCK')
	end

	function has_chateau()
		return has_bottle() and (renewable(CHATEAU) or renewable(BOTTLE_CHATEAU))
	end

	function has_big_poe()
		return has_bottle() and (event('WELL_BIG_POE') or event('DAMPE_BIG_POE') or renewable(BOTTLE_BIG_POE) or renewable(BIG_POE))
	end

	function has_bugs()
		return has_bottle() and event('BUGS')
	end

	function has_fish()
		return has_bottle() and event('FISH')
	end

	function has_water()
		return has_bottle() and event('WATER')
	end

	function has_mushroom()
		return has_bottle() and event('MUSHROOM')
	end

	function has_poe()
		return has_bottle() and event('POE')
	end

	function has_fairy()
		return has_bottle() and event('FAIRY')
	end

	function has_deku_princess()
		return has_bottle() and event('DEKU_PRINCESS')
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
		return wallet_price(MM_SHOPS, id)
	end

	function shop_ex_price(id)
		return wallet_price(MM_SHOPS_EX, id)
	end

	function tingle_price(id)
		return wallet_price(MM_TINGLE, id)
	end

	function has_skeleton_key()
		return setting('skeletonKeyMm') and cond(setting('sharedSkeletonKey'), has('SHARED_SKELETON_KEY'), has('SKELETON_KEY'))
	end

	function boss_key(x)
		return setting('bossKeyShuffleMm', 'removed') or has(x)
	end

	function small_keys(type, x, y, count)
		return has_skeleton_key() or (setting('smallKeyShuffleMm', 'removed') or cond(setting('smallKeyRingMm', type), has(y), has(x, count)))
	end

	function small_keys_wf(n)
		return small_keys('WF', 'SMALL_KEY_WF', 'KEY_RING_WF', n)
	end

	function small_keys_sh(n)
		return small_keys('SH', 'SMALL_KEY_SH', 'KEY_RING_SH', n)
	end

	function small_keys_gb(n)
		return small_keys('GB', 'SMALL_KEY_GB', 'KEY_RING_GB', n)
	end

	function small_keys_st(n)
		return small_keys('ST', 'SMALL_KEY_ST', 'KEY_RING_ST', n)
	end

	function has_mask_bunny()
		return has('MASK_BUNNY') or has('SHARED_MASK_BUNNY')
	end

	function has_mask_truth()
		return has('MASK_TRUTH') or has('SHARED_MASK_TRUTH')
	end

	function has_mask_keaton()
		return has('MASK_KEATON') or has('SHARED_MASK_KEATON')
	end

	function has_mask_zora()
		return has('MASK_ZORA') or has('SHARED_MASK_ZORA')
	end

	function has_mask_goron()
		return has('MASK_GORON') or has('SHARED_MASK_GORON')
	end

	function er_enabled()
		return setting('erMajorDungeons') or setting('erMinorDungeons') or setting('erSpiderHouses') or setting('erGanonCastle') or setting('erGanonTower') or setting('erBeneathWell') or setting('erPirateFortress') or setting('erSecretShrine') or setting('erIkanaCastle') or setting('erMoon') or setting('erIndoorsMajor') or setting('erIndoorsExtra') or (not setting('erRegions', 'none')) or (not setting('erOverworld', 'none')) or (not setting('erBoss', 'none')) or (not setting('erWarps', 'none')) or setting('erOneWaysMajor') or setting('erOneWaysIkana') or setting('erOneWaysSongs') or setting('erOneWaysStatues') or setting('erOneWaysOwls') or (not setting('erGrottos', 'none')) or (not setting('erWallmasters', 'none'))
	end

	function dungeon_er()
		return setting('erMajorDungeons') or setting('erSpiderHouses') or setting('erBeneathWell') or setting('erPirateFortress') or setting('erSecretShrine') or setting('erIkanaCastle') or (setting('erDungeons', 'full') and (setting('erMinorDungeons') or setting('erGanonCastle') or setting('erGanonTower')))
	end

	function soul_enemy(x)
		return not setting('soulsEnemyMm') or has(x)
	end

	function soul_boss(x)
		return not setting('soulsBossMm') or has(x)
	end

	function soul_npc(x)
		return not setting('soulsNpcMm') or has(x)
	end

	function soul_misc(x)
		return not setting('soulsMiscMm') or has(x)
	end

	function short_hook_anywhere()
		return can_hookshot_short() and setting('hookshotAnywhereMm', 'logical')
	end

	function hookshot_anywhere()
		return can_hookshot() and setting('hookshotAnywhereMm', 'logical')
	end

	function gs()
		return soul_gs()
	end


    logic = {
    ["Ancient Castle of Ikana"] = {
        ["exits"] = {
            ["Ikana Castle Exterior"] = function () return true end,
            ["Ancient Castle of Ikana Interior"] = function () return can_reset_time_dungeon() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Interior"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana"] = function () return true end,
            ["Ancient Castle of Ikana Interior North"] = function () return can_use_fire_short_range() end,
            ["Ancient Castle of Ikana Interior South"] = function () return can_use_fire_short_range() end,
            ["Ancient Castle of Ikana Behind Block"] = function () return has_mirror_shield() and event('IKANA_CASTLE_LIGHT2') or can_use_light_arrows() or short_hook_anywhere() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Pot Entrance 1"] = function () return true end,
            ["Ancient Castle of Ikana Pot Entrance 2"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Interior North"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return true end,
            ["Ancient Castle of Ikana Interior North 2"] = function () return has('MASK_DEKU') or short_hook_anywhere() or (can_use_nayru() and is_tall()) end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Pot Left First Room 1"] = function () return true end,
            ["Ancient Castle of Ikana Pot Left First Room 2"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Interior North 2"] = {
        ["events"] = {
            ["MAGIC"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
            ["FAIRY"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Interior North"] = function () return true end,
            ["Ancient Castle of Ikana Interior North 3"] = function () return can_use_lens() or short_hook_anywhere() or has_hover_boots() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Pot Left Second Room 1"] = function () return has('MASK_DEKU') or short_hook_anywhere() or has_hover_boots() end,
            ["Ancient Castle of Ikana Pot Left Second Room 2"] = function () return has('MASK_DEKU') or short_hook_anywhere() or has_hover_boots() end,
            ["Ancient Castle of Ikana Pot Left Second Room 3"] = function () return has('MASK_DEKU') or short_hook_anywhere() or has_hover_boots() end,
            ["Ancient Castle of Ikana Pot Left Second Room 4"] = function () return has('MASK_DEKU') or short_hook_anywhere() or has_hover_boots() end,
        },
    },
    ["Ancient Castle of Ikana Interior North 3"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior North 2"] = function () return true end,
            ["Ancient Castle of Ikana Roof Exterior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Pot Left Third Room 1"] = function () return true end,
            ["Ancient Castle of Ikana Pot Left Third Room 2"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Roof Exterior"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT"] = function () return true end,
            ["IKANA_CASTLE_LIGHT2"] = function () return can_use_keg() end,
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Interior North 3"] = function () return true end,
            ["Ancient Castle of Ikana Roof Interior"] = function () return can_goron_bomb_jump() or short_hook_anywhere() end,
            ["Ikana Castle Exterior"] = function () return true end,
            ["Ikana Castle Entrance"] = function () return has('MASK_DEKU') or has_hover_boots() or trick('MM_IKANA_PILLAR_TO_ENTRANCE') end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana HP"] = function () return (has_arrows() or can_hookshot_short()) and has('MASK_DEKU') or short_hook_anywhere() end,
        },
    },
    ["Ancient Castle of Ikana Interior South"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return true end,
            ["Ancient Castle of Ikana Wizzrobe"] = function () return can_reset_time() and ((has_mirror_shield() and event('IKANA_CASTLE_LIGHT') or can_use_light_arrows()) or short_hook_anywhere()) end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Wizzrobe"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior South"] = function () return soul_enemy(SOUL_ENEMY_WIZZROBE) and (can_use_light_arrows() or short_hook_anywhere()) and (can_fight() or has_arrows()) end,
            ["Ancient Castle of Ikana South Last"] = function () return soul_enemy(SOUL_ENEMY_WIZZROBE) and (can_fight() or has_arrows()) end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana South Last"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Wizzrobe"] = function () return true end,
            ["Ancient Castle of Ikana Roof Interior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Pot Right 1"] = function () return true end,
            ["Ancient Castle of Ikana Pot Right 2"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Roof Interior"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT2"] = function () return can_use_keg() end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana"] = function () return event('IKANA_CASTLE_LIGHT2') end,
            ["Ancient Castle of Ikana Interior South"] = function () return event('IKANA_CASTLE_LIGHT') end,
            ["Ancient Castle of Ikana South Last"] = function () return true end,
            ["Ancient Castle of Ikana Roof Exterior"] = function () return trick('MM_IKANA_ROOF_PARKOUR') or short_hook_anywhere() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Behind Block"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return can_use_light_arrows() or short_hook_anywhere() end,
            ["Ancient Castle of Ikana Pre-Boss"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Pre-Boss"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Behind Block"] = function () return true end,
            ["Ancient Castle of Ikana Throne Room"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Boss Pot 1"] = function () return true end,
            ["Ancient Castle of Ikana Boss Pot 2"] = function () return true end,
            ["Ancient Castle of Ikana Boss Pot 3"] = function () return true end,
            ["Ancient Castle of Ikana Boss Pot 4"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Throne Room"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana After Boss"] = function () return soul_boss(SOUL_BOSS_IGOS) and has_mirror_shield() and (can_use_fire_arrows() or (trick('MM_IGOS_DINS') and can_use_din())) and can_fight() end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Boss Pot 5"] = function () return true end,
            ["Ancient Castle of Ikana Boss Pot 6"] = function () return true end,
            ["Ancient Castle of Ikana Boss Pot 7"] = function () return true end,
            ["Ancient Castle of Ikana Boss Pot 8"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana After Boss"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Pre-Boss"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Song Emptiness"] = function () return true end,
        },
    },
    ["Beneath The Well Entrance"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
            ["Beneath The Well North Section"] = function () return can_pass_gibdo() and has_blue_potion() and can_reset_time_dungeon() end,
            ["Beneath The Well East Section"] = function () return can_pass_gibdo() and has_beans() and can_reset_time_dungeon() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Beneath The Well Wallmaster Near Entrance"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Beneath The Well Wallmaster Near Fountain"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Beneath The Well Wallmaster Near Exit"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Beneath The Well North Section"] = {
        ["events"] = {
            ["WELL_HOT_WATER_SPRING"] = function () return is_spring() and (has_fish() and (has_explosives() or has_mask_zora() or trick_keg_explosives() or trick('MM_WELL_HSW'))) end,
            ["WELL_HOT_WATER_WINTER"] = function () return is_winter() and (has_fish() and (has_explosives() or has_mask_zora() or trick_keg_explosives() or trick('MM_WELL_HSW'))) end,
            ["WELL_HOT_WATER"] = function () return is_spring_or_winter() and (has_fish() and (has_explosives() or has_mask_zora() or trick_keg_explosives() or trick('MM_WELL_HSW'))) end,
            ["WATER"] = function () return true end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return has_water() and has_fire_sticks() end,
            ["BOMBS_OR_BOMBCHU"] = function () return has_water() and has_fire_sticks() end,
            ["FAIRY"] = function () return has_water() and has_bugs() end,
            ["RUPEES"] = function () return has_water() and ((can_fight() or has_weapon_range() or has_explosives()) and soul_wallmaster() or (has_bugs() and can_use_light_arrows() and soul_keese())) end,
        },
        ["exits"] = {
            ["Beneath The Well Wallmaster Near Fountain"] = function () return soul_wallmaster() and has_water() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Well Keese Chest"] = function () return has_water() and has_bugs() and can_use_lens() end,
            ["Beneath The Well Pot Left Side 1"] = function () return has_water() and has_fire_sticks() end,
            ["Beneath The Well Pot Left Side 2"] = function () return has_water() and has_fire_sticks() end,
            ["Beneath The Well Pot Left Side 3"] = function () return has_water() and has_fire_sticks() end,
            ["Beneath The Well Pot Left Side 4"] = function () return has_water() and has_fire_sticks() end,
            ["Beneath The Well Pot Left Side 5"] = function () return has_water() and has_fire_sticks() end,
            ["Beneath The Well Grass Left Side 1"] = function () return has_water() and has_fire_sticks() end,
            ["Beneath The Well Grass Left Side 2"] = function () return has_water() and has_fire_sticks() end,
            ["Beneath The Well Fairy Fountain Fairy 1"] = function () return has_water() and has_bugs() end,
            ["Beneath The Well Fairy Fountain Fairy 2"] = function () return has_water() and has_bugs() end,
            ["Beneath The Well Fairy Fountain Fairy 3"] = function () return has_water() and has_bugs() end,
            ["Beneath The Well Fairy Fountain Fairy 4"] = function () return has_water() and has_bugs() end,
            ["Beneath The Well Fairy Fountain Fairy 5"] = function () return has_water() and has_bugs() end,
            ["Beneath The Well Fairy Fountain Fairy 6"] = function () return has_water() and has_bugs() end,
            ["Beneath The Well Fairy Fountain Fairy 7"] = function () return has_water() and has_bugs() end,
            ["Beneath The Well Fairy Fountain Fairy 8"] = function () return has_water() and has_bugs() end,
        },
    },
    ["Beneath The Well East Section"] = {
        ["events"] = {
            ["STICKS"] = function () return can_kill_baba_sticks() end,
            ["WATER"] = function () return true end,
            ["RUPEES"] = function () return (can_fight() or has_weapon_range() or has_explosives()) and soul_wallmaster() or (can_use_light_arrows() and soul_keese()) end,
        },
        ["exits"] = {
            ["Beneath The Well Wallmaster Near Entrance"] = function () return soul_wallmaster() end,
            ["Beneath The Well Entrance"] = function () return true end,
            ["Beneath The Well Middle Section"] = function () return can_pass_gibdo() and has_fish() end,
            ["Beneath The Well Cow Hall"] = function () return can_pass_gibdo() and has_nuts() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Beneath The Well Cow Hall"] = {
        ["events"] = {
            ["WELL_BIG_POE"] = function () return has_bombs() and has_weapon_range() end,
            ["BUGS"] = function () return true end,
        },
        ["exits"] = {
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Well Cow"] = function () return (has_hot_water_well() or (has_hot_water_distance() and has('OWL_IKANA_CANYON')) or has_hot_water_er()) and can_play_epona() end,
            ["Beneath The Well Grass Cow 1"] = function () return has_hot_water_well() or (has_hot_water_distance() and has('OWL_IKANA_CANYON')) or has_hot_water_er() end,
            ["Beneath The Well Grass Cow 2"] = function () return has_hot_water_well() or (has_hot_water_distance() and has('OWL_IKANA_CANYON')) or has_hot_water_er() end,
            ["Beneath The Well Grass Cow 3"] = function () return has_hot_water_well() or (has_hot_water_distance() and has('OWL_IKANA_CANYON')) or has_hot_water_er() end,
            ["Beneath The Well Pot Big Poe 1"] = function () return has_bombs() end,
            ["Beneath The Well Pot Big Poe 2"] = function () return has_bombs() end,
            ["Beneath The Well Pot Big Poe 3"] = function () return has_bombs() end,
            ["Beneath The Well Pot Big Poe 4"] = function () return has_bombs() end,
            ["Beneath The Well Grass Before Poe 1"] = function () return true end,
            ["Beneath The Well Grass Before Poe 2"] = function () return true end,
            ["Beneath The Well Grass Before Poe 3"] = function () return true end,
            ["Beneath The Well Grass Before Poe 4"] = function () return true end,
        },
    },
    ["Beneath The Well Middle Section"] = {
        ["events"] = {
            ["STICKS"] = function () return can_kill_baba_both_sticks() end,
            ["NUTS"] = function () return can_kill_baba_nuts() end,
        },
        ["exits"] = {
            ["Beneath The Well East Section"] = function () return true end,
            ["Beneath The Well Final Hall"] = function () return has_big_poe() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Well Skulltulla Chest"] = function () return can_pass_gibdo() and has_bugs() and has_fire_sticks() end,
            ["Beneath The Well Pot Middle 01"] = function () return true end,
            ["Beneath The Well Pot Middle 02"] = function () return true end,
            ["Beneath The Well Pot Middle 03"] = function () return true end,
            ["Beneath The Well Pot Middle 04"] = function () return true end,
            ["Beneath The Well Pot Middle 05"] = function () return true end,
            ["Beneath The Well Pot Middle 06"] = function () return true end,
            ["Beneath The Well Pot Middle 07"] = function () return true end,
            ["Beneath The Well Pot Middle 08"] = function () return true end,
            ["Beneath The Well Pot Middle 09"] = function () return true end,
            ["Beneath The Well Pot Middle 10"] = function () return true end,
        },
    },
    ["Beneath The Well Final Hall"] = {
        ["events"] = {
            ["RUPEES"] = function () return (can_fight() or has_weapon_range() or has_explosives()) and soul_wallmaster() end,
            ["BUGS"] = function () return can_use_fire_short_range() or (has_sticks() and has_big_poe() and can_pass_gibdo()) end,
        },
        ["exits"] = {
            ["Beneath The Well Wallmaster Near Exit"] = function () return soul_wallmaster() end,
            ["Beneath The Well Middle Section"] = function () return true end,
            ["Beneath The Well Sun Block"] = function () return can_pass_gibdo() and has_milk() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Well Grass Near End 1"] = function () return true end,
            ["Beneath The Well Grass Near End 2"] = function () return true end,
            ["Beneath The Well Grass Near End 3"] = function () return true end,
            ["Beneath The Well Grass Near End 4"] = function () return true end,
            ["Beneath The Well Grass Near End 5"] = function () return true end,
        },
    },
    ["Beneath The Well Sun Block"] = {
        ["exits"] = {
            ["Beneath The Well Final Hall"] = function () return true end,
            ["Beneath The Well End"] = function () return has_mirror_shield() or can_use_light_arrows() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Well Mirror Shield"] = function () return can_use_fire_short_range() or (has_sticks() and has_big_poe() and has_milk() and can_pass_gibdo()) end,
        },
    },
    ["Beneath The Well End"] = {
        ["exits"] = {
            ["Beneath The Well Sun Block"] = function () return can_use_light_arrows() and can_reset_time_dungeon() end,
            ["Ikana Castle Exterior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Great Bay Temple"] = {
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return can_reset_time_dungeon() end,
            ["Zora Cape Peninsula"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Great Bay Temple Entrance"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple"] = function () return true end,
            ["Great Bay Temple Water Wheel"] = function () return true end,
            ["Great Bay Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_GYORG') end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Entrance Chest"] = function () return has_sticks() or can_use_fire_short_range() or (has_arrows() and trick('MM_GBT_ENTRANCE_BOW')) end,
        },
    },
    ["Great Bay Temple Water Wheel"] = {
        ["events"] = {
            ["GB_WATER_WHEEL"] = function () return event('GB_PIPE_RED') and event('GB_PIPE_RED2') and (can_hookshot() or short_hook_anywhere() or has_hover_boots()) end,
        },
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return true end,
            ["Great Bay Temple Central Room"] = function () return underwater_walking() or (has_mask_goron() and trick('MM_GBT_WATERWHEEL_GORON')) or short_hook_anywhere() or (has_hover_boots() and trick('MM_GBT_WATERWHEEL_HOVERS')) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Water Wheel Platform"] = function () return can_dive_small() or underwater_walking() or (has('MASK_GREAT_FAIRY') and (has_arrows() or can_hookshot())) or (short_hook_anywhere() and trick('MM_GBT_FAIRY2_HOOK')) end,
            ["Great Bay Temple SF Water Wheel Skulltula"] = function () return soul_skulltula() and (can_fight() or has_weapon_range() or has_explosives()) end,
            ["Great Bay Temple Rupee Entrance 1"] = function () return true end,
            ["Great Bay Temple Rupee Entrance 2"] = function () return true end,
            ["Great Bay Temple Rupee Entrance 3"] = function () return true end,
            ["Great Bay Temple Rupee Entrance 4"] = function () return true end,
            ["Great Bay Temple Rupee Entrance 5"] = function () return true end,
        },
    },
    ["Great Bay Temple Central Room"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Water Wheel"] = function () return true end,
            ["Great Bay Temple Map Room"] = function () return underwater_walking() or hookshot_anywhere() or (trick('MM_GBT_CENTRAL_GEYSER') and (can_use_fire_arrows() and can_use_ice_arrows() or can_use_din() or can_use_farore() or can_use_nayru())) end,
            ["Great Bay Temple Red Pipe 1"] = function () return underwater_walking() or (trick('MM_GBT_CENTRAL_GEYSER') and (can_use_fire_arrows() and can_use_ice_arrows() or can_use_din() or can_use_farore() or can_use_nayru())) end,
            ["Great Bay Temple Green Pipe 1"] = function () return can_use_ice_arrows() or short_hook_anywhere() end,
            ["Great Bay Temple Compass Room"] = function () return (underwater_walking() or hookshot_anywhere() or (trick('MM_GBT_CENTRAL_GEYSER') and (can_use_fire_arrows() and can_use_ice_arrows() or can_use_din() or can_use_farore() or can_use_nayru()))) and event('GB_WATER_WHEEL') end,
            ["Great Bay Temple Pre-Boss"] = function () return (underwater_walking() or (trick('MM_GBT_CENTRAL_GEYSER') and (can_use_fire_arrows() and can_use_ice_arrows() or can_use_din() or can_use_farore() or can_use_nayru()))) and event('GB_WATER_WHEEL') end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Central Room Barrel"] = function () return true end,
            ["Great Bay Temple SF Central Room Underwater Pot"] = function () return has_mask_zora() or (has('MASK_GREAT_FAIRY') and (has_arrows() or (underwater_walking_strict() and has_mask_blast()))) or (underwater_walking_strict() and (has_mask_blast() or has_arrows()) and trick('MM_GBT_CENTER_POT_IRONS')) end,
            ["Great Bay Temple Pot Central Room 1"] = function () return true end,
            ["Great Bay Temple Pot Central Room 2"] = function () return true end,
        },
    },
    ["Great Bay Temple Map Room"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Baba Room"] = function () return has_mask_zora() or ((has_bombchu() or has_mask_blast()) and (short_hook_anywhere() or underwater_walking() or (can_dive_big() and has_tunic_zora()))) or hookshot_anywhere() end,
            ["Great Bay Temple Red Pipe 2"] = function () return can_use_ice_arrows() or short_hook_anywhere() end,
            ["Great Bay Temple Green Pipe 3"] = function () return short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Map"] = function () return has_mask_zora() or short_hook_anywhere() or can_use_ice_arrows() or can_hookshot() or has('MASK_DEKU') end,
            ["Great Bay Temple SF Map Room Pot"] = function () return has_mask_zora() or short_hook_anywhere() or can_use_ice_arrows() or has('MASK_DEKU') end,
            ["Great Bay Temple Pot Map Room Surface 1"] = function () return true end,
            ["Great Bay Temple Pot Map Room Surface 2"] = function () return true end,
            ["Great Bay Temple Pot Map Room Surface 3"] = function () return has_mask_zora() or short_hook_anywhere() or can_use_ice_arrows() or has('MASK_DEKU') end,
            ["Great Bay Temple Pot Map Room Water 1"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Map Room Water 2"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Map Room Water 3"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Map Room Water 4"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Map Room Water 5"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Map Room Water 6"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Map Room Water 7"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Map Room Water 8"] = function () return underwater_walking() or hookshot_anywhere() end,
        },
    },
    ["Great Bay Temple Baba Room"] = {
        ["exits"] = {
            ["Great Bay Temple Compass Room"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Baba Chest"] = function () return soul_enemy(SOUL_ENEMY_BIO_BABA) and (has_mask_zora() or has_arrows() or (has_mask_blast() and short_hook_anywhere())) end,
        },
    },
    ["Great Bay Temple Compass Room"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Baba Room"] = function () return true end,
            ["Great Bay Temple Central Room"] = function () return true end,
            ["Great Bay Temple Boss Key Room"] = function () return can_use_ice_arrows() and (can_use_fire_short_range() or has_hot_water_farore()) end,
            ["Great Bay Temple After Boss Key"] = function () return can_use_ice_arrows() and trick('MM_GBT_FIRELESS') and is_tall() or short_hook_anywhere() end,
            ["Great Bay Temple Green Pipe 2"] = function () return event('GB_WATER_WHEEL') end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Compass"] = function () return soul_enemy(SOUL_ENEMY_BIO_BABA) or can_hookshot() or can_use_ice_arrows() or short_hook_anywhere() end,
            ["Great Bay Temple Compass Room Underwater"] = function () return underwater_walking() end,
            ["Great Bay Temple SF Compass Room Pot"] = function () return has_mask_zora() or short_hook_anywhere() or ((has('MASK_GREAT_FAIRY') or underwater_walking() or soul_enemy(SOUL_ENEMY_DEXIHAND)) and (has_weapon_range() or has_bombchu())) or (underwater_walking() and has_mask_blast()) end,
            ["Great Bay Temple Pot Compass Room Surface 1"] = function () return true end,
            ["Great Bay Temple Pot Compass Room Surface 2"] = function () return true end,
            ["Great Bay Temple Pot Compass Room Surface 3"] = function () return true end,
            ["Great Bay Temple Pot Compass Room Surface 4"] = function () return true end,
            ["Great Bay Temple Pot Compass Room Water 1"] = function () return underwater_walking() or short_hook_anywhere() or (can_dive_small() and (has_weapon_range() or has_bombchu())) end,
            ["Great Bay Temple Pot Compass Room Water 2"] = function () return underwater_walking() or short_hook_anywhere() or (can_dive_small() and (has_weapon_range() or has_bombchu())) end,
            ["Great Bay Temple Pot Compass Room Water 3"] = function () return underwater_walking() or short_hook_anywhere() or (can_dive_small() and (has_weapon_range() or has_bombchu())) end,
            ["Great Bay Temple Rupee Compass Room 1"] = function () return underwater_walking() or short_hook_anywhere() end,
            ["Great Bay Temple Rupee Compass Room 2"] = function () return underwater_walking() or short_hook_anywhere() end,
        },
    },
    ["Great Bay Temple Red Pipe 1"] = {
        ["events"] = {
            ["GB_PIPE_RED"] = function () return soul_octorok() and can_use_ice_arrows() or short_hook_anywhere() or (has_hover_boots() and has_mask_bunny() and has_weapon() and trick('MM_GBT_RED1_HOVERS')) end,
        },
        ["exits"] = {
            ["Great Bay Temple Central Room"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Ice Arrow Room"] = function () return small_keys_gb(1) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Pot Red Pipe Before Wart 1"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Red Pipe Before Wart 2"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Red Pipe Before Wart 3"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Red Pipe Before Wart 4"] = function () return underwater_walking() or hookshot_anywhere() end,
        },
    },
    ["Great Bay Temple Ice Arrow Room"] = {
        ["events"] = {
            ["MAGIC"] = function () return soul_enemy(SOUL_ENEMY_CHUCHU) and (has_weapon() or has_mask_zora() or has('MASK_DEKU') or has_explosives()) end,
        },
        ["exits"] = {
            ["Great Bay Temple Red Pipe 1"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Ice Arrow"] = function () return soul_enemy(SOUL_ENEMY_WART) end,
            ["Great Bay Temple Pot Wart 1"] = function () return true end,
            ["Great Bay Temple Pot Wart 2"] = function () return true end,
            ["Great Bay Temple Pot Wart 3"] = function () return true end,
            ["Great Bay Temple Pot Wart 4"] = function () return true end,
            ["Great Bay Temple Pot Wart 5"] = function () return true end,
            ["Great Bay Temple Pot Wart 6"] = function () return true end,
            ["Great Bay Temple Pot Wart 7"] = function () return true end,
            ["Great Bay Temple Pot Wart 8"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 01"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 02"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 03"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 04"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 05"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 06"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 07"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 08"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 09"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 10"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 11"] = function () return true end,
            ["Great Bay Temple Pot Before Wart 12"] = function () return true end,
        },
    },
    ["Great Bay Temple Red Pipe 2"] = {
        ["events"] = {
            ["GB_PIPE_RED2"] = function () return soul_enemy(SOUL_ENEMY_CHUCHU) and can_use_ice_arrows() or short_hook_anywhere() end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Map Room"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Great Bay Temple Boss Key Room"] = {
        ["events"] = {
            ["FROG_4"] = function () return has('MASK_DON_GERO') and soul_enemy(SOUL_ENEMY_GEKKO) and can_use_ice_arrows() end,
        },
        ["exits"] = {
            ["Great Bay Temple After Boss Key"] = function () return soul_enemy(SOUL_ENEMY_GEKKO) and can_use_ice_arrows() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Great Bay Temple After Boss Key"] = {
        ["exits"] = {
            ["Great Bay Temple Boss Key Room"] = function () return true end,
            ["Great Bay Temple Compass Room"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Boss Key"] = function () return true end,
        },
    },
    ["Great Bay Temple Green Pipe 1"] = {
        ["events"] = {
            ["GB_PIPE_GREEN"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Temple Central Room"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 1 Chest"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Great Bay Temple Pot Green Pipe 1 1"] = function () return underwater_walking() or (can_use_ice_arrows() and hookshot_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 1 2"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Green Pipe 1 3"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Green Pipe 1 4"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Rupee Hookshot 1"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Great Bay Temple Rupee Hookshot 2"] = function () return can_hookshot() or short_hook_anywhere() end,
        },
    },
    ["Great Bay Temple Green Pipe 2"] = {
        ["exits"] = {
            ["Great Bay Temple Green Pipe 3"] = function () return can_use_ice_arrows() and (can_use_fire_arrows() or short_hook_anywhere() or trick('MM_GBT_FIRELESS')) or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 2 Lower Chest"] = function () return can_hookshot() or (can_use_ice_arrows() and can_hookshot_short()) or has_hover_boots() end,
            ["Great Bay Temple Green Pipe 2 Upper Chest"] = function () return can_hookshot() and can_use_ice_arrows() and (can_use_fire_arrows() or trick('MM_GBT_FIRELESS')) or short_hook_anywhere() or (has_hover_boots() and trick('MM_GBT_GREEN2_UPPER_HOVERS')) end,
            ["Great Bay Temple Pot Green Pipe 2 1"] = function () return can_dive_small() and (has_arrows() or has_bombchu() or can_hookshot()) or underwater_walking() or hookshot_anywhere() or (can_use_ice_arrows() and short_hook_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 2 2"] = function () return can_dive_small() and (has_arrows() or has_bombchu() or can_hookshot()) or underwater_walking() or hookshot_anywhere() or (can_use_ice_arrows() and short_hook_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 2 3"] = function () return can_dive_small() and (has_arrows() or has_bombchu() or can_hookshot()) or underwater_walking() or hookshot_anywhere() or (can_use_ice_arrows() and short_hook_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 2 4"] = function () return can_dive_small() and (has_arrows() or has_bombchu() or can_hookshot()) or underwater_walking() or hookshot_anywhere() or (can_use_ice_arrows() and short_hook_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 2 5"] = function () return can_dive_small() and (has_arrows() or has_bombchu() or can_hookshot()) or underwater_walking() or hookshot_anywhere() or (can_use_ice_arrows() and short_hook_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 2 6"] = function () return can_dive_small() and (has_arrows() or has_bombchu() or can_hookshot()) or underwater_walking() or hookshot_anywhere() or (can_use_ice_arrows() and short_hook_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 2 7"] = function () return can_dive_small() and (has_arrows() or has_bombchu()) or underwater_walking() or (can_use_ice_arrows() and short_hook_anywhere()) end,
            ["Great Bay Temple Pot Green Pipe 2 8"] = function () return can_dive_small() and (has_arrows() or has_bombchu()) or underwater_walking() or (can_use_ice_arrows() and short_hook_anywhere()) end,
        },
    },
    ["Great Bay Temple Green Pipe 3"] = {
        ["events"] = {
            ["GB_PIPE_GREEN2"] = function () return can_use_fire_arrows() and can_use_ice_arrows() or (trick('MM_GBT_FIRELESS') and has('MASK_DEKU') and (has_mask_zora() or (is_adult() and (has_weapon() or has_sticks())))) or short_hook_anywhere() or has_hover_boots() end,
        },
        ["exits"] = {
            ["Great Bay Temple Green Pipe 2"] = function () return true end,
            ["Great Bay Temple Map Room"] = function () return can_use_fire_arrows() and can_use_ice_arrows() or (trick('MM_GBT_FIRELESS') and has('MASK_DEKU') and (has_mask_zora() or (is_adult() and (has_weapon() or has_sticks())))) or short_hook_anywhere() or has_hover_boots() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 3 Chest"] = function () return can_use_fire_arrows() and can_use_ice_arrows() and is_tall() or (trick('MM_GBT_FIRELESS') and has('MASK_DEKU') and (has_mask_zora() or (is_adult() and (has_weapon() or has_sticks())))) or short_hook_anywhere() or has_hover_boots() end,
            ["Great Bay Temple SF Green Pipe 3 Barrel"] = function () return underwater_walking() or ((has_bombchu() or has_mask_blast()) and (short_hook_anywhere() or can_dive_small())) or (has('MASK_GREAT_FAIRY') and has_bombchu()) end,
            ["Great Bay Temple Pot Green Pipe 3 Upper 1"] = function () return can_use_fire_arrows() and can_use_ice_arrows() and is_tall() or (trick('MM_GBT_FIRELESS') and has('MASK_DEKU') and (has_mask_zora() or (is_adult() and (has_weapon() or has_sticks())))) or short_hook_anywhere() or has_hover_boots() end,
            ["Great Bay Temple Pot Green Pipe 3 Upper 2"] = function () return can_use_fire_arrows() and can_use_ice_arrows() and is_tall() or (trick('MM_GBT_FIRELESS') and has('MASK_DEKU') and (has_mask_zora() or (is_adult() and (has_weapon() or has_sticks())))) or short_hook_anywhere() or has_hover_boots() end,
            ["Great Bay Temple Pot Green Pipe 3 Lower"] = function () return true end,
        },
    },
    ["Great Bay Temple Pre-Boss"] = {
        ["exits"] = {
            ["Great Bay Temple Boss Access"] = function () return boss_key(BOSS_KEY_GB) and (event('GB_PIPE_GREEN') and event('GB_PIPE_GREEN2') or short_hook_anywhere()) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Pre-Boss Above Water"] = function () return can_use_ice_arrows() or (has('MASK_GREAT_FAIRY') and (has_arrows() or can_hookshot())) or short_hook_anywhere() end,
            ["Great Bay Temple SF Pre-Boss Underwater"] = function () return has_mask_zora() or (can_use_ice_arrows() and (has('MASK_GREAT_FAIRY') or short_hook_anywhere() or underwater_walking())) or (underwater_walking() and can_hookshot_short()) end,
            ["Great Bay Temple Pot Pre-Boss 1"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Pre-Boss 2"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Pre-Boss 3"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Pre-Boss 4"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Pre-Boss 5"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Pre-Boss 6"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Pre-Boss 7"] = function () return underwater_walking() or hookshot_anywhere() end,
            ["Great Bay Temple Pot Pre-Boss 8"] = function () return underwater_walking() or hookshot_anywhere() end,
        },
    },
    ["Great Bay Temple Boss Access"] = {
        ["exits"] = {
            ["Great Bay Temple Boss"] = function () return true end,
        },
    },
    ["Great Bay Temple Boss"] = {
        ["exits"] = {
            ["Great Bay Temple After Boss"] = function () return soul_boss(SOUL_BOSS_GYORG) and (has_magic() and (has_mask_zora() and has_arrows() or has('MASK_FIERCE_DEITY')) or (has_iron_boots() and has_tunic_zora_strict() and can_hookshot_short() and trick('MM_GYORG_IRONS'))) end,
            ["WARP_SONGS"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Great Bay Temple Boss Pot 1"] = function () return true end,
            ["Great Bay Temple Boss Pot 2"] = function () return true end,
            ["Great Bay Temple Boss Pot 3"] = function () return true end,
            ["Great Bay Temple Boss Pot 4"] = function () return true end,
            ["Great Bay Temple Boss Pot Underwater 1"] = function () return underwater_walking() end,
            ["Great Bay Temple Boss Pot Underwater 2"] = function () return underwater_walking() end,
            ["Great Bay Temple Boss Pot Underwater 3"] = function () return underwater_walking() end,
            ["Great Bay Temple Boss Pot Underwater 4"] = function () return underwater_walking() end,
        },
    },
    ["Great Bay Temple After Boss"] = {
        ["events"] = {
            ["BOSS_GREAT_BAY"] = function () return true end,
        },
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Boss HC"] = function () return true end,
            ["Great Bay Temple Boss"] = function () return true end,
            ["Great Bay Temple Boss Pot Underwater 1"] = function () return underwater_walking() or (has_mask_blast() and can_dive_big() and trick('MM_GYORG_POTS_DIVE')) end,
            ["Great Bay Temple Boss Pot Underwater 2"] = function () return underwater_walking() or (has_mask_blast() and can_dive_big() and trick('MM_GYORG_POTS_DIVE')) end,
            ["Great Bay Temple Boss Pot Underwater 3"] = function () return underwater_walking() or (has_mask_blast() and can_dive_big() and trick('MM_GYORG_POTS_DIVE')) end,
            ["Great Bay Temple Boss Pot Underwater 4"] = function () return underwater_walking() or (has_mask_blast() and can_dive_big() and trick('MM_GYORG_POTS_DIVE')) end,
        },
    },
    ["Clock Tower Roof"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Moon"] = function () return (can_play_order() or setting('openMoon')) and special(MOON) end,
            ["Clock Tower Platform"] = function () return false end,
        },
        ["locations"] = {
            ["Clock Tower Roof Skull Kid Ocarina"] = function () return cond(not setting('shufflePotsMm'), has('MASK_DEKU') and (has('MAGIC_UPGRADE') or has('SHARED_MAGIC_UPGRADE')) or has_weapon_range(), has_weapon_range()) and (can_play_time() or event('MAJORA') or (setting('erMoon') and dungeon_er()) or setting('moonCrash', 'cycle')) end,
            ["Clock Tower Roof Skull Kid Song of Time"] = function () return cond(not setting('shufflePotsMm'), has('MASK_DEKU') and (has('MAGIC_UPGRADE') or has('SHARED_MAGIC_UPGRADE')) or has_weapon_range(), has_weapon_range()) and (can_play_time() or event('MAJORA') or (setting('erMoon') and dungeon_er()) or setting('moonCrash', 'cycle')) end,
            ["Clock Tower Roof Pot 1"] = function () return can_play_time() or event('MAJORA') or (setting('erMoon') and dungeon_er()) or setting('moonCrash', 'cycle') end,
            ["Clock Tower Roof Pot 2"] = function () return can_play_time() or event('MAJORA') or (setting('erMoon') and dungeon_er()) or setting('moonCrash', 'cycle') end,
            ["Clock Tower Roof Pot 3"] = function () return can_play_time() or event('MAJORA') or (setting('erMoon') and dungeon_er()) or setting('moonCrash', 'cycle') end,
            ["Clock Tower Roof Pot 4"] = function () return can_play_time() or event('MAJORA') or (setting('erMoon') and dungeon_er()) or setting('moonCrash', 'cycle') end,
        },
    },
    ["Moon"] = {
        ["events"] = {
            ["MAJORA_PRE_BOSS"] = function () return true end,
        },
        ["exits"] = {
            ["Moon Trial Deku Entrance"] = function () return soul_npc(SOUL_NPC_MOON_CHILDREN) and can_reset_time_on_moon() and masks(1) end,
            ["Moon Trial Goron Entrance"] = function () return soul_npc(SOUL_NPC_MOON_CHILDREN) and can_reset_time_on_moon() and masks(2) end,
            ["Moon Trial Zora"] = function () return soul_npc(SOUL_NPC_MOON_CHILDREN) and can_reset_time_on_moon() and masks(3) end,
            ["Moon Trial Link Entrance"] = function () return soul_npc(SOUL_NPC_MOON_CHILDREN) and can_reset_time_on_moon() and masks(4) end,
            ["Moon Boss"] = function () return soul_npc(SOUL_NPC_MOON_CHILDREN) and (setting('majoraChild', 'none') or (setting('majoraChild', 'custom') and special(MAJORA))) end,
        },
        ["locations"] = {
            ["Moon Fierce Deity Mask"] = function () return soul_npc(SOUL_NPC_MOON_CHILDREN) and can_reset_time_on_moon() and masks(20) and event('MOON_TRIAL_DEKU') and event('MOON_TRIAL_GORON') and event('MOON_TRIAL_ZORA') and event('MOON_TRIAL_LINK') end,
        },
    },
    ["Moon Trial Deku Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Deku Exit"] = function () return has('MASK_DEKU') end,
        },
        ["locations"] = {
            ["Moon Trial Deku HP"] = function () return has('MASK_DEKU') or hookshot_anywhere() end,
        },
    },
    ["Moon Trial Deku Exit"] = {
        ["events"] = {
            ["MOON_TRIAL_DEKU"] = function () return true end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Deku Entrance"] = function () return has('MASK_DEKU') end,
        },
    },
    ["Moon Trial Goron Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Goron Exit"] = function () return goron_fast_roll() or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Moon Trial Goron HP"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot Early 1"] = function () return true end,
            ["Moon Trial Goron Pot Early 2"] = function () return true end,
            ["Moon Trial Goron Pot Early 3"] = function () return true end,
            ["Moon Trial Goron Pot Early 4"] = function () return true end,
            ["Moon Trial Goron Pot 01"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 02"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 03"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 04"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 05"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 06"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 07"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 08"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 09"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 10"] = function () return goron_fast_roll() or hookshot_anywhere() end,
            ["Moon Trial Goron Pot 11"] = function () return goron_fast_roll() or hookshot_anywhere() end,
        },
    },
    ["Moon Trial Goron Exit"] = {
        ["events"] = {
            ["MOON_TRIAL_GORON"] = function () return true end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Goron Entrance"] = function () return goron_fast_roll() end,
        },
    },
    ["Moon Trial Zora"] = {
        ["events"] = {
            ["MOON_TRIAL_ZORA"] = function () return underwater_walking() or can_dive_small() end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
        },
        ["locations"] = {
            ["Moon Trial Zora HP"] = function () return underwater_walking() or can_dive_small() end,
        },
    },
    ["Moon Trial Link Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Link Dinalfos Fight"] = function () return true end,
        },
        ["locations"] = {
            ["Moon Trial Link Pot 1"] = function () return true end,
            ["Moon Trial Link Pot 2"] = function () return true end,
            ["Moon Trial Link Pot 3"] = function () return true end,
            ["Moon Trial Link Pot 4"] = function () return true end,
            ["Moon Trial Link Pot 5"] = function () return true end,
            ["Moon Trial Link Pot 6"] = function () return true end,
            ["Moon Trial Link Pot 7"] = function () return true end,
            ["Moon Trial Link Pot 8"] = function () return true end,
        },
    },
    ["Moon Trial Link Dinalfos Fight"] = {
        ["exits"] = {
            ["Moon Trial Link Entrance"] = function () return soul_lizalfos_dinalfos() and (can_fight() or can_use_deku_bubble() or has_arrows()) end,
            ["Moon Trial Link Rest 1"] = function () return soul_lizalfos_dinalfos() and (can_fight() or can_use_deku_bubble() or has_arrows()) end,
        },
    },
    ["Moon Trial Link Rest 1"] = {
        ["exits"] = {
            ["Moon Trial Link Dinalfos Fight"] = function () return true end,
            ["Moon Trial Link Garo Fight"] = function () return true end,
        },
    },
    ["Moon Trial Link Garo Fight"] = {
        ["exits"] = {
            ["Moon Trial Link Rest 1"] = function () return soul_enemy(SOUL_ENEMY_GARO) and (has_weapon() or has_mask_goron() or can_use_deku_bubble() or has_arrows()) end,
            ["Moon Trial Link Rest 2"] = function () return soul_enemy(SOUL_ENEMY_GARO) and (has_weapon() or has_mask_goron() or can_use_deku_bubble() or has_arrows()) and can_hookshot_short() end,
        },
        ["locations"] = {
            ["Moon Trial Link Garo Master Chest"] = function () return soul_enemy(SOUL_ENEMY_GARO) and (has_weapon() or has_mask_goron() or can_use_deku_bubble() or has_arrows()) and can_hookshot_short() end,
        },
    },
    ["Moon Trial Link Rest 2"] = {
        ["exits"] = {
            ["Moon Trial Link Garo Fight"] = function () return true end,
            ["Moon Trial Link Iron Knuckle Fight"] = function () return true end,
        },
    },
    ["Moon Trial Link Iron Knuckle Fight"] = {
        ["exits"] = {
            ["Moon Trial Link Rest 2"] = function () return soul_iron_knuckle() and (has_weapon() or has_mask_goron() or has_bombs() or has_bombchu() or (has_mask_blast() and masks(5))) end,
            ["Moon Trial Link Rest 3"] = function () return soul_iron_knuckle() and (has_weapon() or has_mask_goron() or has_bombs() or has_bombchu() or (has_mask_blast() and masks(5))) and (has_bombchu() and has_arrows() or short_hook_anywhere()) end,
        },
        ["locations"] = {
            ["Moon Trial Link Iron Knuckle Chest"] = function () return soul_iron_knuckle() and (has_weapon() or has_mask_goron() or has_bombs() or has_bombchu() or (has_mask_blast() and masks(5))) end,
        },
    },
    ["Moon Trial Link Rest 3"] = {
        ["exits"] = {
            ["Moon Trial Link Iron Knuckle Fight"] = function () return true end,
            ["Moon Trial Link Exit"] = function () return (has_bombchu() or (short_hook_anywhere() and has_mask_blast() and masks(5))) and can_use_fire_arrows() end,
        },
        ["locations"] = {
            ["Moon Trial Link HP"] = function () return true end,
        },
    },
    ["Moon Trial Link Exit"] = {
        ["events"] = {
            ["MOON_TRIAL_LINK"] = function () return true end,
        },
        ["exits"] = {
            ["Moon Trial Link Rest 3"] = function () return true end,
            ["Moon"] = function () return true end,
        },
    },
    ["Moon Boss"] = {
        ["events"] = {
            ["MAJORA_PHASE_1"] = function () return has_arrows() or has_mask_zora() or (has('MASK_FIERCE_DEITY') and has_magic()) end,
            ["MAJORA"] = function () return not is_goal_triforce() and event('MAJORA_PHASE_1') and (has_weapon() or has_mask_zora() or (has('MASK_FIERCE_DEITY') and has_magic())) end,
        },
        ["locations"] = {
            ["Moon Majora Pot 1"] = function () return can_play_time() or event('MAJORA') end,
            ["Moon Majora Pot 2"] = function () return can_play_time() or event('MAJORA') end,
        },
    },
    ["Ocean Spider House"] = {
        ["exits"] = {
            ["Ocean Spider House Front"] = function () return (has_explosives() or trick_keg_explosives()) and can_reset_time_dungeon() end,
            ["Great Bay Coast"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ocean Spider House Wallet"] = function () return soul_citizen() and has('GS_TOKEN_OCEAN', 30) end,
        },
    },
    ["Ocean Spider House Front"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ocean Spider House"] = function () return true end,
            ["Ocean Spider House Back"] = function () return can_hookshot_short() or can_goron_bomb_jump() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ocean Skulltula Entrance Right Wall"] = function () return gs() and can_hookshot_short() end,
            ["Ocean Skulltula Entrance Left Wall"] = function () return gs() and can_hookshot_short() end,
            ["Ocean Skulltula Entrance Web"] = function () return gs() and (can_hookshot_short() or (can_use_fire_arrows() and has_mask_zora())) end,
            ["Ocean Spider House Pot Entrance 1"] = function () return true end,
            ["Ocean Spider House Pot Entrance 2"] = function () return true end,
            ["Ocean Spider House Pot Entrance 3"] = function () return true end,
            ["Ocean Spider House Pot Entrance 4"] = function () return true end,
        },
    },
    ["Ocean Spider House Back"] = {
        ["exits"] = {
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Ocean Skulltula 2nd Room Ceiling Edge"] = function () return gs() and (can_hookshot_short() or has_mask_zora()) end,
            ["Ocean Skulltula 2nd Room Ceiling Plank"] = function () return gs() and (can_hookshot_short() or has_mask_zora()) end,
            ["Ocean Skulltula 2nd Room Jar"] = function () return gs() end,
            ["Ocean Skulltula 2nd Room Webbed Hole"] = function () return gs() and has_fire_sticks() and can_hookshot_short() end,
            ["Ocean Skulltula 2nd Room Behind Skull 1"] = function () return gs() and (can_hookshot_short() or has_mask_zora()) end,
            ["Ocean Skulltula 2nd Room Behind Skull 2"] = function () return gs() end,
            ["Ocean Skulltula 2nd Room Webbed Pot"] = function () return gs() and has_fire_sticks() end,
            ["Ocean Skulltula 2nd Room Upper Pot"] = function () return gs() end,
            ["Ocean Skulltula 2nd Room Lower Pot"] = function () return gs() end,
            ["Ocean Skulltula Library Hole Behind Picture"] = function () return gs() and (has_arrows() or has_sticks()) and (can_hookshot() or short_hook_anywhere()) end,
            ["Ocean Skulltula Library Hole Behind Cabinet"] = function () return gs() and (has_arrows() or has_sticks()) and can_hookshot_short() end,
            ["Ocean Skulltula Library On Corner Bookshelf"] = function () return gs() and (has_arrows() or has_sticks()) end,
            ["Ocean Skulltula Library Behind Picture"] = function () return gs() and (has_arrows() or has_sticks()) and (can_hookshot_short() or has_arrows() or has_mask_zora() or can_use_deku_bubble()) end,
            ["Ocean Skulltula Library Behind Bookcase 1"] = function () return gs() and (has_arrows() or has_sticks()) end,
            ["Ocean Skulltula Library Behind Bookcase 2"] = function () return gs() and (has_arrows() or has_sticks()) end,
            ["Ocean Skulltula Library Ceiling Edge"] = function () return gs() and (has_arrows() or has_sticks()) and (can_hookshot_short() or has_mask_zora()) end,
            ["Ocean Skulltula Colored Skulls Chandelier 1"] = function () return gs() end,
            ["Ocean Skulltula Colored Skulls Chandelier 2"] = function () return gs() end,
            ["Ocean Skulltula Colored Skulls Chandelier 3"] = function () return gs() end,
            ["Ocean Skulltula Colored Skulls Behind Picture"] = function () return gs() and (can_hookshot_short() or has_mask_zora() or (has_mask_goron() and (has_arrows() or can_use_deku_bubble()))) end,
            ["Ocean Skulltula Colored Skulls Pot"] = function () return gs() end,
            ["Ocean Skulltula Colored Skulls Ceiling Edge"] = function () return gs() and (can_hookshot_short() or has_mask_zora()) end,
            ["Ocean Spider House Chest HP"] = function () return has_arrows() and (has('MASK_CAPTAIN') and soul_stalchild() or trick('MM_CAPTAIN_SKIP')) end,
            ["Ocean Skulltula Storage Room Behind Boat"] = function () return gs() and has_fire_sticks() end,
            ["Ocean Skulltula Storage Room Ceiling Web"] = function () return gs() and can_use_fire_short_range() and (can_hookshot_short() or has_mask_zora()) end,
            ["Ocean Skulltula Storage Room Behind Crate"] = function () return gs() and has_fire_sticks() and is_short() and (can_hookshot_short() or has_mask_zora() or (has_mask_goron() and (has_arrows() or can_use_deku_bubble() or has_explosives() or trick_keg_explosives()))) end,
            ["Ocean Skulltula Storage Room Crate"] = function () return gs() and has_fire_sticks() end,
            ["Ocean Skulltula Storage Room Jar"] = function () return gs() and has_fire_sticks() and can_hookshot_short() end,
            ["Ocean Spider House Pot Main Room Web"] = function () return true end,
            ["Ocean Spider House Pot Main Room Boe"] = function () return true end,
            ["Ocean Spider House Pot Main Room 1"] = function () return true end,
            ["Ocean Spider House Pot Main Room 2"] = function () return true end,
            ["Ocean Spider House Pot Colored Skulls 1"] = function () return true end,
            ["Ocean Spider House Pot Colored Skulls 2"] = function () return true end,
            ["Ocean Spider House Pot Storage 1"] = function () return has_fire_sticks() end,
            ["Ocean Spider House Pot Storage 2"] = function () return has_fire_sticks() and is_short() end,
            ["Ocean Spider House Pot Storage 3"] = function () return has_fire_sticks() and is_short() end,
            ["Ocean Spider House Pot Storage 4"] = function () return has_fire_sticks() end,
            ["Ocean Spider House Pot Storage Top 1"] = function () return has_fire_sticks() and can_hookshot_short() end,
            ["Ocean Spider House Pot Storage Top 2"] = function () return has_fire_sticks() and can_hookshot_short() end,
            ["Ocean Spider House Pot Storage Top 3"] = function () return has_fire_sticks() and can_hookshot_short() end,
        },
    },
    ["VOID"] = {
    },
    ["GLOBAL"] = {
        ["exits"] = {
            ["WARP_SONGS"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
        },
    },
    ["WARP_SONGS"] = {
        ["exits"] = {
            ["OOT SONG_TP_FOREST"] = function () return can_play_cross_tp_forest() end,
            ["OOT SONG_TP_FIRE"] = function () return can_play_cross_tp_fire() end,
            ["OOT SONG_TP_WATER"] = function () return can_play_cross_tp_water() end,
            ["OOT SONG_TP_SHADOW"] = function () return can_play_cross_tp_shadow() end,
            ["OOT SONG_TP_SPIRIT"] = function () return can_play_cross_tp_spirit() end,
            ["OOT SONG_TP_LIGHT"] = function () return can_play_cross_tp_light() end,
        },
    },
    ["Tingle Town"] = {
        ["locations"] = {
            ["Tingle Map Clock Town"] = function () return tingle_price(0) end,
            ["Tingle Map Woodfall"] = function () return tingle_price(1) end,
        },
    },
    ["Tingle Swamp"] = {
        ["locations"] = {
            ["Tingle Map Woodfall"] = function () return tingle_price(2) end,
            ["Tingle Map Snowhead"] = function () return tingle_price(3) end,
        },
    },
    ["Tingle Mountain"] = {
        ["locations"] = {
            ["Tingle Map Snowhead"] = function () return tingle_price(4) end,
            ["Tingle Map Ranch"] = function () return tingle_price(5) end,
        },
    },
    ["Tingle Ranch"] = {
        ["locations"] = {
            ["Tingle Map Ranch"] = function () return tingle_price(6) end,
            ["Tingle Map Great Bay"] = function () return tingle_price(7) end,
        },
    },
    ["Tingle Great Bay"] = {
        ["locations"] = {
            ["Tingle Map Great Bay"] = function () return tingle_price(8) end,
            ["Tingle Map Ikana"] = function () return tingle_price(9) end,
        },
    },
    ["Tingle Ikana"] = {
        ["locations"] = {
            ["Tingle Map Ikana"] = function () return tingle_price(10) end,
            ["Tingle Map Clock Town"] = function () return tingle_price(11) end,
        },
    },
    ["SOARING"] = {
        ["exits"] = {
            ["Owl Clock Town"] = function () return has('OWL_CLOCK_TOWN') end,
            ["Owl Milk Road"] = function () return has('OWL_MILK_ROAD') end,
            ["Owl Swamp"] = function () return has('OWL_SOUTHERN_SWAMP') end,
            ["Owl Woodfall"] = function () return has('OWL_WOODFALL') end,
            ["Owl Mountain"] = function () return has('OWL_MOUNTAIN_VILLAGE') end,
            ["Owl Snowhead"] = function () return has('OWL_SNOWHEAD') end,
            ["Owl Great Bay"] = function () return has('OWL_GREAT_BAY') end,
            ["Owl Zora Cape"] = function () return has('OWL_ZORA_CAPE') end,
            ["Owl Ikana"] = function () return has('OWL_IKANA_CANYON') end,
            ["Owl Stone Tower"] = function () return has('OWL_STONE_TOWER') end,
        },
    },
    ["Owl Clock Town"] = {
        ["exits"] = {
            ["Clock Town South"] = function () return can_reset_time() end,
            ["OOT Market"] = function () return true end,
            ["Clock Tower Platform"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Milk Road"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Milk Road"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Milk Road Owl Statue"] = function () return has_sticks() or has_weapon() end,
            ["Milk Road Grass 1"] = function () return true end,
            ["Milk Road Grass 2"] = function () return true end,
            ["Milk Road Grass 3"] = function () return true end,
        },
    },
    ["Owl Swamp"] = {
        ["events"] = {
            ["STICKS"] = function () return true end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["FAIRY"] = function () return true end,
            ["WATER"] = function () return true end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Southern Swamp Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Woodfall"] = {
        ["events"] = {
            ["STICKS"] = function () return true end,
            ["NUTS"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Shrine"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Woodfall Owl Statue"] = function () return has_sticks() or has_weapon() end,
            ["Woodfall Near Owl Chest"] = function () return has('MASK_DEKU') or can_hookshot() end,
            ["Woodfall Pot 1"] = function () return true end,
            ["Woodfall Pot 2"] = function () return true end,
            ["Woodfall Pot 3"] = function () return true end,
        },
    },
    ["Owl Mountain"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Mountain Village Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Snowhead"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Entrance"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Snowhead Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Great Bay"] = {
        ["events"] = {
            ["PICTURE_TINGLE"] = function () return soul_npc(SOUL_NPC_TINGLE) and has('PICTOGRAPH_BOX') end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return can_reset_time() end,
            ["Tingle Great Bay"] = function () return soul_npc(SOUL_NPC_TINGLE) and (can_hookshot() or has_arrows()) end,
        },
        ["locations"] = {
            ["Great Bay Coast Owl Statue"] = function () return has_sticks() or has_weapon() end,
        },
    },
    ["Owl Zora Cape"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Zora Cape Peninsula"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Zora Cape Owl Statue"] = function () return has_sticks() or has_weapon() end,
            ["Zora Cape Pot Near Owl Statue 1"] = function () return true end,
            ["Zora Cape Pot Near Owl Statue 2"] = function () return true end,
            ["Zora Cape Pot Near Owl Statue 3"] = function () return true end,
            ["Zora Cape Pot Near Owl Statue 4"] = function () return true end,
        },
    },
    ["Owl Ikana"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Canyon"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Ikana Canyon Owl Statue"] = function () return has_sticks() or has_weapon() end,
            ["Ikana Canyon Grass 1"] = function () return true end,
            ["Ikana Canyon Grass 2"] = function () return true end,
            ["Ikana Canyon Grass 3"] = function () return true end,
            ["Ikana Canyon Grass 4"] = function () return true end,
        },
    },
    ["Owl Stone Tower"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Top"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Stone Tower Owl Statue"] = function () return has_sticks() or has_weapon() end,
            ["Stone Tower Pot Owl Statue 1"] = function () return true end,
            ["Stone Tower Pot Owl Statue 2"] = function () return true end,
            ["Stone Tower Pot Owl Statue 3"] = function () return true end,
            ["Stone Tower Pot Owl Statue 4"] = function () return true end,
        },
    },
    ["Oath to Order"] = {
        ["locations"] = {
            ["Oath to Order"] = function () return true end,
        },
    },
    ["Clock Town"] = {
        ["exits"] = {
            ["GLOBAL"] = function () return true end,
            ["Clock Town South"] = function () return can_reset_time() end,
            ["Clock Tower Platform"] = function () return true end,
            ["Owl Clock Town"] = function () return true end,
        },
        ["locations"] = {
            ["Initial Song of Healing"] = function () return true end,
        },
    },
    ["Clock Tower Platform"] = {
        ["exits"] = {
            ["Clock Town South"] = function () return can_reset_time() end,
            ["Clock Tower Roof"] = function () return after(NIGHT3_AM_12_00) and cond(setting('erMoon'), trick('MM_CLOCK_TOWER_WAIT') or can_play_time() or can_play_sun(), true) end,
            ["Owl Clock Town"] = function () return true end,
            ["OOT Market"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Platform HP"] = function () return true end,
        },
    },
    ["Clock Town South"] = {
        ["events"] = {
            ["CLOCK_TOWN_SCRUB"] = function () return has('MOON_TEAR') end,
            ["MAIL_LETTER"] = function () return has('LETTER_TO_KAFEI') and before(DAY2_AM_11_30) end,
        },
        ["exits"] = {
            ["OOT Market"] = function () return true end,
            ["Clock Tower Platform"] = function () return true end,
            ["Termina Field"] = function () return true end,
            ["Clock Town South Upper West"] = function () return true end,
            ["Clock Town South Lower West"] = function () return true end,
            ["Clock Town South Upper East"] = function () return true end,
            ["Clock Town South Lower East"] = function () return true end,
            ["Clock Town North"] = function () return true end,
            ["Laundry Pool"] = function () return true end,
            ["Owl Clock Town"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town South Chest Lower"] = function () return can_hookshot() or (is_adult() and can_hookshot_short()) or short_hook_anywhere() or (has('MASK_DEKU') and event('CLOCK_TOWN_SCRUB')) or trick('MM_SCT_NOTHING') or can_goron_bomb_jump() end,
            ["Clock Town South Chest Upper"] = function () return (can_hookshot() or short_hook_anywhere() or (has('MASK_DEKU') and event('CLOCK_TOWN_SCRUB')) or (can_goron_bomb_jump() and can_hookshot_short())) and final_day() end,
            ["Clock Town Business Scrub"] = function () return soul_business_scrub() and event('CLOCK_TOWN_SCRUB') end,
            ["Clock Town Post Box"] = function () return has('MASK_POSTMAN') end,
        },
    },
    ["Clock Town South Upper West"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town South Lower West"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town South Upper East"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town South Lower East"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Clock Town South"] = function () return true end,
        },
    },
    ["Clock Town North"] = {
        ["events"] = {
            ["HIDE_SEEK1"] = function () return soul_bombers() and has_weapon_range() and first_day() end,
            ["HIDE_SEEK2"] = function () return soul_bombers() and has_weapon_range() and second_day() end,
            ["HIDE_SEEK3"] = function () return soul_bombers() and has_weapon_range() and final_day() end,
            ["BOMBERS_NORTH1"] = function () return event('HIDE_SEEK1') end,
            ["BOMBERS_NORTH2"] = function () return event('HIDE_SEEK2') end,
            ["BOMBERS_NORTH3"] = function () return event('HIDE_SEEK3') end,
            ["BOMBER_CODE"] = function () return bombers1() or bombers2() or bombers3() end,
            ["SAKON_BOMB_BAG"] = function () return can_fight() and at(NIGHT1_AM_12_00) end,
            ["SAKON_BOOM"] = function () return (has_arrows() or can_hookshot_short() or can_use_din()) and at(NIGHT1_AM_12_00) end,
            ["MAIL_LETTER"] = function () return has('LETTER_TO_KAFEI') and before(DAY2_AM_11_30) end,
            ["PICTURE_TINGLE"] = function () return soul_npc(SOUL_NPC_TINGLE) and has('PICTOGRAPH_BOX') and is_day() end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South"] = function () return true end,
            ["Clock Town East"] = function () return true end,
            ["Clock Town Fairy Fountain"] = function () return true end,
            ["Deku Playground"] = function () return true end,
            ["Tingle Town"] = function () return soul_npc(SOUL_NPC_TINGLE) and is_day() and (has_weapon_range() or (has_weapon() and (trick('MM_NCT_TINGLE') or has_hover_boots()))) end,
            ["Clock Town North Postbox"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Tree HP"] = function () return true end,
            ["Clock Town Bomber Notebook"] = function () return event('BOMBER_CODE') end,
            ["Clock Town Blast Mask"] = function () return event('SAKON_BOMB_BAG') end,
            ["Clock Town Keaton HP"] = function () return soul_npc(SOUL_NPC_KEATON) and has_mask_keaton() end,
            ["Clock Town Keaton Grass Reward 1"] = function () return true end,
            ["Clock Town Keaton Grass Reward 2"] = function () return keaton_grass_easy() end,
            ["Clock Town Keaton Grass Reward 3"] = function () return keaton_grass_easy() end,
            ["Clock Town Keaton Grass Reward 4"] = function () return keaton_grass_easy() end,
            ["Clock Town Keaton Grass Reward 5"] = function () return keaton_grass_easy() end,
            ["Clock Town Keaton Grass Reward 6"] = function () return keaton_grass_hard() end,
            ["Clock Town Keaton Grass Reward 7"] = function () return keaton_grass_hard() end,
            ["Clock Town Keaton Grass Reward 8"] = function () return keaton_grass_hard() end,
            ["Clock Town Keaton Grass Reward 9"] = function () return keaton_grass_hard() end,
        },
    },
    ["Clock Town North Postbox"] = {
        ["exits"] = {
            ["Clock Town North"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Post Box"] = function () return has('MASK_POSTMAN') end,
        },
    },
    ["Clock Town West"] = {
        ["events"] = {
            ["BOMBERS_WEST1"] = function () return event('HIDE_SEEK1') end,
            ["BOMBERS_WEST2"] = function () return event('HIDE_SEEK2') end,
            ["BOMBERS_WEST3"] = function () return event('HIDE_SEEK3') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South Upper West"] = function () return true end,
            ["Clock Town South Lower West"] = function () return true end,
            ["Bomb Shop"] = function () return true end,
            ["Trading Post"] = function () return true end,
            ["Curiosity Shop"] = function () return between(NIGHT1_PM_10_00, DAY2_AM_06_00) or between(NIGHT2_PM_10_00, DAY3_AM_06_00) or after(NIGHT3_PM_10_00) end,
            ["Post Office"] = function () return between(DAY1_PM_03_00, NIGHT1_AM_12_00) or (event('MAIL_LETTER') and between(NIGHT2_PM_06_00, NIGHT2_AM_12_00)) or is_night3() end,
            ["Swordsman School"] = function () return first_day() or second_day() or between(DAY3_AM_06_00, NIGHT3_PM_11_00) or after(NIGHT3_AM_12_00) end,
            ["Lottery"] = function () return is_day() or (event('PLAY_LOTTERY') and (before(NIGHT1_PM_11_00) or between(NIGHT2_PM_06_00, NIGHT2_PM_11_00) or between(NIGHT3_PM_06_00, NIGHT3_PM_11_00))) end,
        },
        ["locations"] = {
            ["Clock Town Bank Reward 1"] = function () return soul_banker() and can_use_wallet(1) end,
            ["Clock Town Bank Reward 2"] = function () return soul_banker() and (can_use_wallet(2) or (can_use_wallet(1) and (trick('MM_BANK_ONE_WALLET') or trick('MM_BANK_NO_WALLET')))) end,
            ["Clock Town Bank Reward 3"] = function () return soul_banker() and (can_use_wallet(3) or (can_use_wallet(2) and trick('MM_BANK_ONE_WALLET')) or (can_use_wallet(1) and trick('MM_BANK_NO_WALLET'))) end,
            ["Clock Town Rosa Sisters HP"] = function () return soul_citizen() and has('MASK_KAMARO') and (is_night1() or is_night2()) end,
        },
    },
    ["Clock Town East Main"] = {
        ["events"] = {
            ["BOMBERS_EAST1"] = function () return event('HIDE_SEEK1') end,
            ["BOMBERS_EAST2"] = function () return event('HIDE_SEEK2') end,
            ["BOMBERS_EAST3"] = function () return event('HIDE_SEEK3') end,
            ["MAIL_LETTER"] = function () return has('LETTER_TO_KAFEI') and before(DAY2_AM_11_30) end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town North"] = function () return true end,
            ["Clock Town South Upper East"] = function () return true end,
            ["Clock Town South Lower East"] = function () return true end,
            ["Mayor's Office"] = function () return between(DAY1_AM_10_00, NIGHT1_PM_08_00) or between(DAY2_AM_10_00, NIGHT2_PM_08_00) or after(DAY3_AM_10_00) end,
            ["Town Archery"] = function () return before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
            ["Chest Game"] = function () return before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
            ["Honey & Darling Game"] = function () return before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
            ["Stock Pot Inn"] = function () return has('ROOM_KEY') or between(DAY1_AM_08_00, NIGHT1_PM_08_00) or between(DAY2_AM_08_00, NIGHT2_PM_08_00) or after(DAY3_AM_08_00) end,
            ["Clock Town East SPI Roof"] = function () return has('MASK_DEKU') or short_hook_anywhere() or has_hover_boots() or event('SPI_ROOF_FARORE') end,
            ["Milk Bar"] = function () return between(DAY1_AM_10_00, NIGHT1_PM_09_00) or between(DAY2_AM_10_00, NIGHT2_PM_09_00) or between(DAY3_AM_10_00, NIGHT3_PM_09_00) or (has('MASK_ROMANI') and (between(NIGHT1_PM_10_00, NIGHT1_AM_05_00) or between(NIGHT2_PM_10_00, NIGHT2_AM_05_00) or after(NIGHT3_PM_10_00))) end,
            ["Astral Observatory Passage"] = function () return event('BOMBER_CODE') or event('GUESS_BOMBER') or trick('MM_BOMBER_BACKFLIP') or short_hook_anywhere() end,
            ["Clock Town East Postbox"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Silver Rupee Chest"] = function () return true end,
            ["Clock Town Postman Hat"] = function () return event('POSTMAN_FREEDOM') and between(NIGHT3_PM_06_00, NIGHT3_AM_05_00) end,
        },
    },
    ["Clock Town East Postbox"] = {
        ["exits"] = {
            ["Clock Town East Main"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Post Box"] = function () return has('MASK_POSTMAN') end,
        },
    },
    ["Clock Town East"] = {
        ["events"] = {
            ["GUESS_BOMBER"] = function () return soul_bombers() and trick('MM_BOMBER_GUESS') end,
        },
        ["exits"] = {
            ["Clock Town East Main"] = function () return true end,
        },
    },
    ["Clock Town East Near Hideout"] = {
        ["exits"] = {
            ["Clock Town East Main"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Bomber Notebook"] = function () return event('GUESS_BOMBER') end,
        },
    },
    ["Astral Observatory Passage"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town East Near Hideout"] = function () return true end,
            ["Astral Observatory Junction"] = function () return true end,
        },
        ["locations"] = {
            ["Astral Observatory Passage Chest"] = function () return has_explosives() or trick_keg_explosives() end,
            ["Astral Observatory Passage Pot 1"] = function () return true end,
            ["Astral Observatory Passage Pot 2"] = function () return true end,
            ["Astral Observatory Passage Pot 3"] = function () return true end,
            ["Astral Observatory Passage Pot 4"] = function () return true end,
            ["Astral Observatory Pot 1"] = function () return true end,
            ["Astral Observatory Pot 2"] = function () return true end,
            ["Astral Observatory Pot 3"] = function () return true end,
        },
    },
    ["Astral Observatory Junction"] = {
        ["exits"] = {
            ["Astral Observatory Passage"] = function () return true end,
            ["Astral Observatory"] = function () return true end,
        },
    },
    ["Laundry Pool"] = {
        ["events"] = {
            ["FROG_1"] = function () return has('MASK_DON_GERO') end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town South"] = function () return true end,
            ["Kafei Hideout"] = function () return event('MAIL_LETTER') and between(DAY2_PM_02_00, NIGHT2_PM_10_00) or (event('MEET_KAFEI') and between(DAY3_PM_01_00, NIGHT3_PM_10_00)) end,
        },
        ["locations"] = {
            ["Clock Town Guru Guru Mask Bremen"] = function () return soul_guru_guru() and (is_night1() or is_night2()) end,
            ["Clock Town Stray Fairy"] = function () return is_day() end,
            ["Clock Town Laundry Pool Grass 1"] = function () return true end,
            ["Clock Town Laundry Pool Grass 2"] = function () return true end,
            ["Clock Town Laundry Pool Grass 3"] = function () return true end,
            ["Clock Town Laundry Pool Rupee 1"] = function () return is_night2() end,
            ["Clock Town Laundry Pool Rupee 2"] = function () return is_night2() end,
            ["Clock Town Laundry Pool Rupee 3"] = function () return is_night2() end,
        },
    },
    ["Clock Town Fairy Fountain"] = {
        ["exits"] = {
            ["Clock Town North"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Great Fairy"] = function () return has('STRAY_FAIRY_TOWN') end,
            ["Clock Town Great Fairy Alt"] = function () return has('STRAY_FAIRY_TOWN') and (has('MASK_DEKU') or has_mask_goron() or has_mask_zora()) end,
        },
    },
    ["Bomb Shop"] = {
        ["events"] = {
            ["BUY_KEG"] = function () return soul_goron() and has_mask_goron() and has('POWDER_KEG') and can_use_wallet(1) end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Bomb Shop Item 1"] = function () return soul_bombchu_shopkeeper() and shop_price(0) end,
            ["Bomb Shop Item 2"] = function () return soul_bombchu_shopkeeper() and shop_price(1) end,
            ["Bomb Shop Bomb Bag"] = function () return soul_bombchu_shopkeeper() and shop_price(2) end,
            ["Bomb Shop Bomb Bag 2"] = function () return soul_bombchu_shopkeeper() and event('SAKON_BOMB_BAG') and shop_price(3) end,
        },
    },
    ["Trading Post"] = {
        ["events"] = {
            ["SCARECROW"] = function () return can_play_scarecrow() end,
            ["FISH"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
            ["Trading Post Items"] = function () return soul_fishing_pond_owner() and (before(NIGHT1_PM_09_00) or between(DAY2_AM_06_00, NIGHT2_PM_09_00)) or (soul_rooftop_man() and (between(NIGHT1_PM_09_00, DAY2_AM_06_00) or between(NIGHT2_PM_09_00, NIGHT3_PM_09_00))) end,
        },
        ["locations"] = {
            ["Trading Post Pot"] = function () return true end,
        },
        ["stay"] = {
            ["NIGHT1_PM_09_00"] = function () return false end,
            ["NIGHT1_PM_10_00"] = function () return false end,
            ["NIGHT2_PM_09_00"] = function () return false end,
            ["NIGHT2_PM_10_00"] = function () return false end,
            ["NIGHT3_PM_09_00"] = function () return false end,
        },
    },
    ["Trading Post Items"] = {
        ["locations"] = {
            ["Trading Post Item 1"] = function () return shop_price(5) end,
            ["Trading Post Item 2"] = function () return shop_price(6) end,
            ["Trading Post Item 3"] = function () return shop_price(7) end,
            ["Trading Post Item 4"] = function () return shop_price(8) end,
            ["Trading Post Item 5"] = function () return shop_price(9) end,
            ["Trading Post Item 6"] = function () return shop_price(10) end,
            ["Trading Post Item 7"] = function () return shop_price(11) end,
            ["Trading Post Item 8"] = function () return shop_price(12) end,
        },
    },
    ["Curiosity Shop"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
            ["Curiosity Shop 2"] = function () return true end,
        },
        ["locations"] = {
            ["Curiosity Shop All-Night Mask"] = function () return (event('SAKON_BOMB_BAG') or event('SAKON_BOOM')) and shop_price(4) and is_night3() end,
        },
    },
    ["Curiosity Shop 2"] = {
        ["locations"] = {
            ["Bomb Shop Bomb Bag 2"] = function () return shop_ex_price(0) and is_night3() end,
        },
    },
    ["Kafei Hideout"] = {
        ["events"] = {
            ["MEET_KAFEI"] = function () return soul_npc(SOUL_NPC_KAFEI) and event('MAIL_LETTER') and between(DAY2_PM_02_00, NIGHT2_PM_10_00) end,
        },
        ["exits"] = {
            ["Laundry Pool"] = function () return true end,
        },
        ["locations"] = {
            ["Kafei Hideout Pendant of Memories"] = function () return soul_npc(SOUL_NPC_KAFEI) and event('MAIL_LETTER') and between(DAY2_PM_02_00, NIGHT2_PM_10_00) end,
            ["Kafei Hideout Owner Reward 1"] = function () return between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
            ["Kafei Hideout Owner Reward 2"] = function () return between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
        },
    },
    ["Post Office"] = {
        ["events"] = {
            ["POSTMAN_FREEDOM"] = function () return soul_citizen() and has('LETTER_TO_MAMA') and is_night3() end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Post Office HP"] = function () return soul_citizen() and (has_mask_bunny() or trick('MM_POST_OFFICE_GAME')) and (between(DAY1_PM_03_00, NIGHT1_AM_12_00) or (event('MAIL_LETTER') and between(NIGHT2_PM_06_00, NIGHT2_AM_12_00))) end,
        },
    },
    ["Swordsman School"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Swordsman School HP"] = function () return soul_carpet_man() and has_sword() and can_use_wallet(1) and before(NIGHT3_PM_11_00) end,
            ["Swordsman School Pot 1"] = function () return has_sword() and after(NIGHT3_AM_12_00) end,
            ["Swordsman School Pot 2"] = function () return has_sword() and after(NIGHT3_AM_12_00) end,
            ["Swordsman School Pot 3"] = function () return has_sword() and after(NIGHT3_AM_12_00) end,
            ["Swordsman School Pot 4"] = function () return has_sword() and after(NIGHT3_AM_12_00) end,
            ["Swordsman School Pot 5"] = function () return has_sword() and after(NIGHT3_AM_12_00) end,
        },
        ["stay"] = {
            ["NIGHT3_PM_11_00"] = function () return false end,
        },
    },
    ["Lottery"] = {
        ["events"] = {
            ["PLAY_LOTTERY"] = function () return is_day() and can_use_wallet(1) end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
    },
    ["Mayor's Office"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Mayor's Office Kafei's Mask"] = function () return soul_npc(SOUL_NPC_AROMA) and (between(DAY1_AM_10_00, NIGHT1_PM_08_00) or between(DAY2_AM_10_00, NIGHT2_PM_08_00)) end,
            ["Mayor's Office HP"] = function () return soul_npc(SOUL_NPC_MAYOR_DOTOUR) and has('MASK_COUPLE') and (between(DAY1_AM_10_00, NIGHT1_PM_08_00) or between(DAY2_AM_10_00, NIGHT2_PM_08_00) or between(DAY3_AM_10_00, NIGHT3_PM_06_00)) end,
        },
    },
    ["Milk Bar"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Milk Bar Troupe Leader Mask"] = function () return has('MASK_ROMANI') and soul_npc(SOUL_NPC_TOTO) and soul_gorman() and can_play_minigame() and has('MASK_DEKU') and has_mask_zora() and has_mask_goron() and (between(NIGHT1_PM_10_00, NIGHT1_AM_05_00) or between(NIGHT2_PM_10_00, NIGHT2_AM_05_00)) end,
            ["Milk Bar Madame Aroma Bottle"] = function () return soul_npc(SOUL_NPC_AROMA) and has('MASK_KAFEI') and has('LETTER_TO_MAMA') and (between(NIGHT3_PM_06_00, NIGHT3_PM_09_00) or after(NIGHT3_PM_10_00)) end,
            ["Milk Bar Purchase Milk"] = function () return soul_talon() and has('MASK_ROMANI') and can_use_wallet(1) and (between(NIGHT1_PM_10_00, DAY2_AM_06_00) or between(NIGHT2_PM_10_00, DAY3_AM_06_00) or between(NIGHT3_PM_06_00, NIGHT3_PM_09_00) or after(NIGHT3_PM_10_00)) end,
            ["Milk Bar Purchase Chateau"] = function () return soul_talon() and has('MASK_ROMANI') and can_use_wallet(2) and (between(NIGHT1_PM_10_00, DAY2_AM_06_00) or between(NIGHT2_PM_10_00, DAY3_AM_06_00) or between(NIGHT3_PM_06_00, NIGHT3_PM_09_00) or after(NIGHT3_PM_10_00)) end,
        },
    },
    ["Town Archery"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Town Archery Reward 1"] = function () return soul_shooting_gallery_owner() and has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00)) end,
            ["Town Archery Reward 2"] = function () return soul_shooting_gallery_owner() and has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00)) end,
        },
    },
    ["Chest Game"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Chest Game HP"] = function () return soul_bombchu_bowling_lady() and has_mask_goron() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or is_day3()) end,
        },
    },
    ["Honey & Darling Game"] = {
        ["events"] = {
            ["HD_REWARD_1"] = function () return soul_honey_darling() and (has_bomb_bag() or has_bombchu_license()) and before(NIGHT1_PM_10_00) end,
            ["HD_REWARD_2"] = function () return soul_honey_darling() and has_bomb_bag() and between(DAY2_AM_06_00, NIGHT2_PM_10_00) end,
            ["HD_REWARD_3"] = function () return soul_honey_darling() and (has_bow() or can_use_deku_bubble()) and is_day3() end,
        },
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Honey & Darling Reward Any Day"] = function () return can_use_wallet(1) and (event('HD_REWARD_1') or event('HD_REWARD_2') or event('HD_REWARD_3')) end,
            ["Honey & Darling Reward All Days"] = function () return can_use_wallet(1) and has_bow() and event('HD_REWARD_1') and event('HD_REWARD_2') and event('HD_REWARD_3') end,
        },
    },
    ["Stock Pot Inn"] = {
        ["events"] = {
            ["SETUP_MEET"] = function () return soul_anju() and has('MASK_KAFEI') and between(DAY1_PM_01_45, NIGHT1_PM_09_00) end,
            ["MEET_ANJU"] = function () return soul_anju() and event('SETUP_MEET') and cond(setting('erIndoorsExtra'), between(NIGHT1_AM_12_00, DAY2_AM_06_00), between(NIGHT1_AM_12_00, DAY2_AM_06_00) and (has('ROOM_KEY') or has('MASK_DEKU') or has_hover_boots() or event('SPI_ROOF_FARORE') or trick('MM_STOCK_POT_WAIT'))) end,
            ["DELIVER_PENDANT"] = function () return soul_anju() and has('PENDANT_OF_MEMORIES') and (between(DAY2_AM_06_00, NIGHT2_PM_09_00) or between(DAY3_AM_06_00, DAY3_AM_11_30)) end,
            ["BUGS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Stock Pot Inn Roof"] = function () return true end,
        },
        ["locations"] = {
            ["Stock Pot Inn Guest Room Chest"] = function () return has('ROOM_KEY') end,
            ["Stock Pot Inn Staff Room Chest"] = function () return is_night3() end,
            ["Stock Pot Inn Room Key"] = function () return soul_anju() and between(DAY1_PM_01_45, DAY1_PM_04_00) end,
            ["Stock Pot Inn Letter to Kafei"] = function () return event('MEET_ANJU') end,
            ["Stock Pot Inn Couple's Mask"] = function () return event('SUN_MASK') and event('DELIVER_PENDANT') and event('MEET_ANJU') and after(NIGHT3_AM_04_00) end,
            ["Stock Pot Inn Grandma HP 1"] = function () return soul_old_hag() and has('MASK_ALL_NIGHT') and (is_day1() or is_day2()) end,
            ["Stock Pot Inn Grandma HP 2"] = function () return soul_old_hag() and has('MASK_ALL_NIGHT') and (is_day1() or is_day2()) end,
            ["Stock Pot Inn ??? HP"] = function () return soul_npc(SOUL_NPC_TOILET_HAND) and cond(setting('erIndoorsExtra'), has_paper() and midnight(), has_paper() and midnight() and (clock_night3() or has('ROOM_KEY') or has('MASK_DEKU') or has_hover_boots() or event('SPI_ROOF_FARORE') or trick('MM_STOCK_POT_WAIT'))) end,
        },
    },
    ["Clock Town East SPI Roof"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Stock Pot Inn"] = function () return true end,
        },
    },
    ["Stock Pot Inn Roof"] = {
        ["events"] = {
            ["SPI_ROOF_FARORE"] = function () return can_use_farore() end,
        },
        ["exits"] = {
            ["Clock Town East SPI Roof"] = function () return true end,
        },
    },
    ["Deku Playground"] = {
        ["events"] = {
            ["DEKU_REWARD_1"] = function () return soul_npc(SOUL_NPC_PLAYGROUND_SCRUBS) and between(DAY1_AM_06_00, NIGHT1_AM_12_00) end,
            ["DEKU_REWARD_2"] = function () return soul_npc(SOUL_NPC_PLAYGROUND_SCRUBS) and between(DAY2_AM_06_00, NIGHT2_AM_12_00) end,
            ["DEKU_REWARD_3"] = function () return soul_npc(SOUL_NPC_PLAYGROUND_SCRUBS) and between(DAY3_AM_06_00, NIGHT3_AM_12_00) end,
        },
        ["exits"] = {
            ["Clock Town North"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Playground Reward Any Day"] = function () return has('MASK_DEKU') and can_use_wallet(1) and (event('DEKU_REWARD_1') or event('DEKU_REWARD_2') or event('DEKU_REWARD_3')) end,
            ["Deku Playground Reward All Days"] = function () return has('MASK_DEKU') and can_use_wallet(1) and event('DEKU_REWARD_1') and event('DEKU_REWARD_2') and event('DEKU_REWARD_3') end,
        },
    },
    ["Astral Observatory"] = {
        ["events"] = {
            ["SCRUB_TELESCOPE"] = function () return soul_astronomer() and soul_business_scrub() end,
            ["TEAR_TELESCOPE"] = function () return soul_astronomer() end,
            ["SCARECROW"] = function () return can_play_scarecrow() end,
        },
        ["exits"] = {
            ["Astral Observatory Junction"] = function () return true end,
            ["Astral Observatory Balcony"] = function () return true end,
        },
    },
    ["Astral Observatory Balcony"] = {
        ["events"] = {
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return can_use_beans() or short_hook_anywhere() or (can_goron_bomb_jump() and has_bombs()) end,
            ["Astral Observatory"] = function () return true end,
        },
        ["locations"] = {
            ["Astral Observatory Moon Tear"] = function () return event('TEAR_TELESCOPE') end,
        },
    },
    ["Termina Field"] = {
        ["events"] = {
            ["STICKS"] = function () return can_kill_baba_both_sticks() end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["MAGIC"] = function () return soul_enemy(SOUL_ENEMY_CHUCHU) end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Clock Town South"] = function () return true end,
            ["Clock Town North"] = function () return true end,
            ["Clock Town East"] = function () return true end,
            ["Clock Town West"] = function () return true end,
            ["Road to Southern Swamp"] = function () return true end,
            ["Behind Large Icicles"] = function () return has_arrows() or (has_hot_water_distance() and has('OWL_CLOCK_TOWN')) or has_hot_water_farore() or has_hot_water_er() or short_hook_anywhere() or can_use_din() end,
            ["Milk Road"] = function () return true end,
            ["Great Bay Fence"] = function () return can_play_epona() or (can_goron_bomb_jump() and has_bombs()) or short_hook_anywhere() end,
            ["Road to Ikana Front"] = function () return true end,
            ["Astral Observatory Balcony"] = function () return has('MASK_DEKU') or short_hook_anywhere() or (can_goron_bomb_jump() and has_bombs()) end,
            ["Grass Grotto"] = function () return true end,
            ["Peahat Grotto"] = function () return true end,
            ["Bio Baba Grotto"] = function () return can_break_boulders() end,
            ["Dodongo Grotto"] = function () return true end,
            ["Pillar Grotto"] = function () return true end,
            ["Scrub Grotto"] = function () return true end,
            ["Termina Field Cow Grotto"] = function () return has_explosives() end,
            ["Swamp Gossip Grotto"] = function () return true end,
            ["Mountain Gossip Grotto"] = function () return true end,
            ["Ocean Gossip Grotto"] = function () return can_break_boulders() end,
            ["Canyon Gossip Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Water Chest"] = function () return underwater_walking() end,
            ["Termina Field Tall Grass Chest"] = function () return true end,
            ["Termina Field Tree Stump Chest"] = function () return can_hookshot_short() or can_use_beans() end,
            ["Termina Field Kamaro Mask"] = function () return soul_citizen() and can_play_healing() and midnight() end,
            ["Termina Field Pot"] = function () return can_use_beans() or has_bow() end,
            ["Termina Field Grass Pack 01 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 01 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 02 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 03 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 04 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 05 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 06 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 07 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 08 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 09 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 10 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 11 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 12 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 13 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 14 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 15 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 16 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 17 Grass 12"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 01"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 02"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 03"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 04"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 05"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 06"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 07"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 08"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 09"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 10"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 11"] = function () return true end,
            ["Termina Field Grass Pack 18 Grass 12"] = function () return true end,
            ["Termina Field Rupee"] = function () return true end,
        },
    },
    ["Grass Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Tall Grass Grotto"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 01"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 02"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 03"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 04"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 05"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 06"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 07"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 08"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 09"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 10"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 11"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 12"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 13"] = function () return true end,
            ["Termina Field Tall Grass Grotto Grass 14"] = function () return true end,
        },
    },
    ["Peahat Grotto"] = {
        ["events"] = {
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Peahat Grotto"] = function () return soul_peahat() and (can_fight() or has_arrows() or has('MASK_DEKU')) and is_day() end,
            ["Peahat Grotto Grass 01"] = function () return true end,
            ["Peahat Grotto Grass 02"] = function () return true end,
            ["Peahat Grotto Grass 03"] = function () return true end,
            ["Peahat Grotto Grass 04"] = function () return true end,
            ["Peahat Grotto Grass 05"] = function () return true end,
            ["Peahat Grotto Grass 06"] = function () return true end,
            ["Peahat Grotto Grass 07"] = function () return true end,
            ["Peahat Grotto Grass 08"] = function () return true end,
            ["Peahat Grotto Grass 09"] = function () return true end,
            ["Peahat Grotto Grass 10"] = function () return true end,
            ["Peahat Grotto Grass 11"] = function () return true end,
            ["Peahat Grotto Grass 12"] = function () return true end,
        },
    },
    ["Bio Baba Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Bio Baba Grotto"] = function () return has_mask_zora() or ((underwater_walking() or can_dive_big() or (trick('MM_BIO_BABA_LUCK') and soul_enemy(SOUL_ENEMY_BIO_BABA))) and (has_weapon_range() or (has_bombs() and soul_enemy(SOUL_ENEMY_BIO_BABA)) or (has_bombchu() and trick('MM_BIO_BABA_CHU')))) end,
            ["Bio Baba Grotto Grass 1"] = function () return true end,
            ["Bio Baba Grotto Grass 2"] = function () return true end,
        },
    },
    ["Dodongo Grotto"] = {
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Dodongo Grotto"] = function () return soul_dodongo() and (has_weapon() or has_explosives() or has_mask_goron() or has_arrows()) end,
        },
    },
    ["Pillar Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Pillar Grotto"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 01"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 02"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 03"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 04"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 05"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 06"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 07"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 08"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 09"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 10"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 11"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 12"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 13"] = function () return true end,
            ["Termina Field Pillar Grotto Grass 14"] = function () return true end,
        },
    },
    ["Scrub Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Scrub"] = function () return event('SCRUB_TELESCOPE') and can_use_wallet(2) end,
            ["Termina Field Scrub Pot"] = function () return true end,
        },
    },
    ["Termina Field Cow Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Cow Front"] = function () return can_play_epona() end,
            ["Termina Field Cow Back"] = function () return can_play_epona() end,
            ["Termina Field Cow Grotto Grass 01"] = function () return true end,
            ["Termina Field Cow Grotto Grass 02"] = function () return true end,
            ["Termina Field Cow Grotto Grass 03"] = function () return true end,
            ["Termina Field Cow Grotto Grass 04"] = function () return true end,
            ["Termina Field Cow Grotto Grass 05"] = function () return true end,
            ["Termina Field Cow Grotto Grass 06"] = function () return true end,
            ["Termina Field Cow Grotto Grass 07"] = function () return true end,
            ["Termina Field Cow Grotto Grass 08"] = function () return true end,
            ["Termina Field Cow Grotto Grass 09"] = function () return true end,
            ["Termina Field Cow Grotto Grass 10"] = function () return true end,
            ["Termina Field Cow Grotto Grass 11"] = function () return true end,
            ["Termina Field Cow Grotto Grass 12"] = function () return true end,
            ["Termina Field Cow Grotto Grass 13"] = function () return true end,
            ["Termina Field Cow Grotto Grass 14"] = function () return true end,
            ["Termina Field Cow Grotto Grass 15"] = function () return true end,
            ["Termina Field Cow Grotto Grass 16"] = function () return true end,
            ["Termina Field Cow Grotto Grass 17"] = function () return true end,
            ["Termina Field Cow Grotto Grass 18"] = function () return true end,
            ["Termina Field Cow Grotto Grass 19"] = function () return true end,
            ["Termina Field Cow Grotto Grass 20"] = function () return true end,
            ["Termina Field Cow Grotto Grass 21"] = function () return true end,
            ["Termina Field Cow Grotto Grass 22"] = function () return true end,
            ["Termina Field Cow Grotto Grass 23"] = function () return true end,
            ["Termina Field Cow Grotto Grass 24"] = function () return true end,
            ["Termina Field Cow Grotto Grass 25"] = function () return true end,
            ["Termina Field Cow Grotto Grass 26"] = function () return true end,
            ["Termina Field Cow Grotto Grass 27"] = function () return true end,
            ["Termina Field Cow Grotto Grass 28"] = function () return true end,
            ["Termina Field Cow Grotto Grass 29"] = function () return true end,
            ["Termina Field Cow Grotto Grass 30"] = function () return true end,
            ["Termina Field Cow Grotto Grass 31"] = function () return true end,
            ["Termina Field Cow Grotto Grass 32"] = function () return true end,
            ["Termina Field Cow Grotto Grass 33"] = function () return true end,
            ["Termina Field Cow Grotto Grass 34"] = function () return true end,
            ["Termina Field Cow Grotto Grass 35"] = function () return true end,
            ["Termina Field Cow Grotto Grass 36"] = function () return true end,
            ["Termina Field Cow Grotto Grass 37"] = function () return true end,
            ["Termina Field Cow Grotto Grass 38"] = function () return true end,
            ["Termina Field Cow Grotto Grass 39"] = function () return true end,
            ["Termina Field Cow Grotto Grass 40"] = function () return true end,
            ["Termina Field Cow Grotto Grass 41"] = function () return true end,
            ["Termina Field Cow Grotto Grass 42"] = function () return true end,
            ["Termina Field Cow Grotto Grass 43"] = function () return true end,
            ["Termina Field Cow Grotto Grass 44"] = function () return true end,
            ["Termina Field Cow Grotto Grass 45"] = function () return true end,
            ["Termina Field Cow Grotto Grass 46"] = function () return true end,
            ["Termina Field Cow Grotto Grass 47"] = function () return true end,
            ["Termina Field Cow Grotto Grass 48"] = function () return true end,
            ["Termina Field Cow Grotto Grass 49"] = function () return true end,
            ["Termina Field Cow Grotto Grass 50"] = function () return true end,
            ["Termina Field Cow Grotto Grass 51"] = function () return true end,
            ["Termina Field Cow Grotto Grass 52"] = function () return true end,
            ["Termina Field Cow Grotto Grass 53"] = function () return true end,
            ["Termina Field Cow Grotto Grass 54"] = function () return true end,
            ["Termina Field Cow Grotto Grass 55"] = function () return true end,
            ["Termina Field Cow Grotto Grass 56"] = function () return true end,
            ["Termina Field Cow Grotto Grass 57"] = function () return true end,
            ["Termina Field Cow Grotto Grass 58"] = function () return true end,
            ["Termina Field Cow Grotto Grass 59"] = function () return true end,
            ["Termina Field Cow Grotto Grass 60"] = function () return true end,
            ["Termina Field Cow Grotto Grass 61"] = function () return true end,
            ["Termina Field Cow Grotto Grass 62"] = function () return true end,
            ["Termina Field Cow Grotto Grass 63"] = function () return true end,
            ["Termina Field Cow Grotto Grass 64"] = function () return true end,
            ["Termina Field Cow Grotto Grass 65"] = function () return true end,
            ["Termina Field Cow Grotto Grass 66"] = function () return true end,
            ["Termina Field Cow Grotto Grass 67"] = function () return true end,
            ["Termina Field Cow Grotto Grass 68"] = function () return true end,
            ["Termina Field Cow Grotto Grass 69"] = function () return true end,
            ["Termina Field Cow Grotto Grass 70"] = function () return true end,
            ["Termina Field Cow Grotto Grass 71"] = function () return true end,
            ["Termina Field Cow Grotto Grass 72"] = function () return true end,
        },
    },
    ["Swamp Gossip Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
            ["SWAMP_SONG"] = function () return has_ocarina() and (has_mask_goron() and can_play_goron() or (has('MASK_DEKU') and can_play_awakening()) or (has_mask_zora() and can_play_zora())) end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
        },
    },
    ["Mountain Gossip Grotto"] = {
        ["events"] = {
            ["BUGS"] = function () return true end,
            ["MOUNTAIN_SONG"] = function () return has_ocarina() and (has_mask_goron() and can_play_goron() or (has('MASK_DEKU') and can_play_awakening()) or (has_mask_zora() and can_play_zora())) end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
        },
    },
    ["Ocean Gossip Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
            ["OCEAN_SONG"] = function () return has_ocarina() and (has_mask_goron() and can_play_goron() or (has('MASK_DEKU') and can_play_awakening()) or (has_mask_zora() and can_play_zora())) end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
            ["Ocean Gossip Grotto Grass 1"] = function () return true end,
            ["Ocean Gossip Grotto Grass 2"] = function () return true end,
            ["Ocean Gossip Grotto Grass 3"] = function () return true end,
            ["Ocean Gossip Grotto Grass 4"] = function () return true end,
            ["Ocean Gossip Grotto Grass 5"] = function () return true end,
        },
    },
    ["Canyon Gossip Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
            ["CANYON_SONG"] = function () return has_ocarina() and (has_mask_goron() and can_play_goron() or (has('MASK_DEKU') and can_play_awakening()) or (has_mask_zora() and can_play_zora())) end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
        },
        ["locations"] = {
            ["Termina Field Gossip Stones HP"] = function () return event('SWAMP_SONG') and event('MOUNTAIN_SONG') and event('OCEAN_SONG') and event('CANYON_SONG') end,
            ["Canyon Gossip Grotto Grass 1"] = function () return true end,
            ["Canyon Gossip Grotto Grass 2"] = function () return true end,
            ["Canyon Gossip Grotto Grass 3"] = function () return true end,
            ["Canyon Gossip Grotto Grass 4"] = function () return true end,
            ["Canyon Gossip Grotto Grass 5"] = function () return true end,
        },
    },
    ["Road to Southern Swamp"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
            ["WATER"] = function () return true end,
            ["PICTURE_TINGLE"] = function () return soul_npc(SOUL_NPC_TINGLE) and has('PICTOGRAPH_BOX') end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
            ["Termina Field"] = function () return true end,
            ["Swamp Archery"] = function () return before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00) end,
            ["Road to Southern Swamp Grotto"] = function () return true end,
            ["Tingle Swamp"] = function () return soul_npc(SOUL_NPC_TINGLE) and has_weapon_range() end,
        },
        ["locations"] = {
            ["Road to Southern Swamp HP"] = function () return has_weapon_range() or has_bombchu() end,
            ["Road to Southern Swamp Grass Pack 1 Grass 01"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 02"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 03"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 04"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 05"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 06"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 07"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 08"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 1 Grass 09"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 01"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 02"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 03"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 04"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 05"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 06"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 07"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 08"] = function () return true end,
            ["Road to Southern Swamp Grass Pack 2 Grass 09"] = function () return true end,
            ["Road to Southern Swamp Grass 1"] = function () return true end,
            ["Road to Southern Swamp Grass 2"] = function () return true end,
        },
    },
    ["Swamp Archery"] = {
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Archery Reward 1"] = function () return soul_bazaar_shopkeeper() and has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00)) end,
            ["Swamp Archery Reward 2"] = function () return soul_bazaar_shopkeeper() and has_bow() and can_use_wallet(1) and (before(NIGHT1_PM_10_00) or between(DAY2_AM_06_00, NIGHT2_PM_10_00) or between(DAY3_AM_06_00, NIGHT3_PM_10_00)) end,
        },
    },
    ["Road to Southern Swamp Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Southern Swamp Grotto"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 01"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 02"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 03"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 04"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 05"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 06"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 07"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 08"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 09"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 10"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 11"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 12"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 13"] = function () return true end,
            ["Road to Southern Swamp Grotto Grass 14"] = function () return true end,
        },
    },
    ["Swamp Front"] = {
        ["events"] = {
            ["FROG_3"] = function () return has('MASK_DON_GERO') end,
            ["PICTURE_SWAMP"] = function () return has('PICTOGRAPH_BOX') end,
            ["PICTURE_BIG_OCTO"] = function () return has('PICTOGRAPH_BOX') and soul_octorok() end,
            ["STICKS"] = function () return true end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["WATER"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
            ["Tourist Information"] = function () return true end,
            ["Swamp Back"] = function () return (event('BOAT_RIDE') or has_arrows() or can_hookshot_short() or can_use_din()) and (has('MASK_DEKU') or has_hover_boots() or can_use_nayru() or is_adult()) or is_swamp_cleared() or has_mask_zora() end,
            ["Swamp Potion Shop"] = function () return true end,
            ["Woods of Mystery"] = function () return true end,
            ["Owl Swamp"] = function () return true end,
        },
        ["locations"] = {
            ["Southern Swamp HP"] = function () return has('DEED_LAND') and has('MASK_DEKU') or (trick('MM_SOUTHERN_SWAMP_SCRUB_HP_GORON') and has_mask_goron()) or short_hook_anywhere() end,
            ["Southern Swamp Scrub Deed"] = function () return soul_business_scrub() and has('DEED_LAND') end,
            ["Southern Swamp Scrub Shop"] = function () return soul_business_scrub() and has('MASK_DEKU') and can_use_wallet(1) end,
            ["Southern Swamp Pot 1"] = function () return true end,
            ["Southern Swamp Pot 2"] = function () return true end,
            ["Southern Swamp Pot 3"] = function () return true end,
            ["Southern Swamp Grass Front 01"] = function () return true end,
            ["Southern Swamp Grass Front 02"] = function () return true end,
            ["Southern Swamp Grass Front 03"] = function () return true end,
            ["Southern Swamp Grass Front 04"] = function () return true end,
            ["Southern Swamp Grass Front 05"] = function () return true end,
            ["Southern Swamp Grass Front 06"] = function () return true end,
            ["Southern Swamp Grass Front 07"] = function () return true end,
            ["Southern Swamp Grass Front 08"] = function () return true end,
            ["Southern Swamp Grass Front 09"] = function () return true end,
            ["Southern Swamp Grass Front 10"] = function () return true end,
            ["Southern Swamp Grass Front 11"] = function () return true end,
            ["Southern Swamp Grass Front 12"] = function () return true end,
            ["Southern Swamp Grass Owl 1"] = function () return true end,
            ["Southern Swamp Grass Owl 2"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 01"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 02"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 03"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 04"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 05"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 06"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 07"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 08"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 1 Grass 09"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 01"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 02"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 03"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 04"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 05"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 06"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 07"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 08"] = function () return true end,
            ["Southern Swamp Grass Near Witch Pack 2 Grass 09"] = function () return true end,
            ["Southern Swamp Grass Near Witch 1"] = function () return true end,
            ["Southern Swamp Grass Near Witch 2"] = function () return true end,
            ["Southern Swamp Rupee 1"] = function () return has('MASK_DEKU') or is_tall() or short_hook_anywhere() or has_hover_boots() end,
            ["Southern Swamp Rupee 2"] = function () return has('MASK_DEKU') or is_tall() or short_hook_anywhere() or has_hover_boots() end,
        },
    },
    ["Swamp Back"] = {
        ["events"] = {
            ["PICTURE_SWAMP"] = function () return has('PICTOGRAPH_BOX') end,
            ["PICTURE_BIG_OCTO"] = function () return has('PICTOGRAPH_BOX') and soul_octorok() end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return (event('BOAT_RIDE') or has_arrows()) and (has('MASK_DEKU') or has_hover_boots() or can_use_nayru() or is_adult() or has_mask_goron()) or (has_hover_boots() and (can_hookshot_short() or can_use_din())) or (is_adult() and (can_use_din() or (can_use_nayru() and can_hookshot_short()))) or is_swamp_cleared() or has_mask_zora() end,
            ["Deku Palace Front"] = function () return true end,
            ["Near Swamp Spider House"] = function () return has('MASK_DEKU') or is_tall() or is_swamp_cleared() or short_hook_anywhere() or can_use_nayru() or has_hover_boots() end,
            ["Swamp Canopy Back"] = function () return is_swamp_cleared() or short_hook_anywhere() end,
            ["Swamp Canopy Front"] = function () return short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Southern Swamp Song of Soaring"] = function () return has_mask_zora() and has_explosives() and trick('MM_SOARING_ZORA') end,
        },
    },
    ["Near Swamp Spider House"] = {
        ["exits"] = {
            ["Swamp Spider House"] = function () return has_sticks() or has_arrows() end,
            ["Swamp Back"] = function () return has('MASK_DEKU') or is_tall() or is_swamp_cleared() or short_hook_anywhere() or can_use_nayru() or has_hover_boots() end,
            ["Near Swamp Grotto"] = function () return has('MASK_DEKU') or is_tall() or is_swamp_cleared() or short_hook_anywhere() or has_hover_boots() end,
            ["Swamp Canopy Front"] = function () return short_hook_anywhere() end,
        },
    },
    ["Near Swamp Grotto"] = {
        ["events"] = {
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return (has_arrows() or can_hookshot() or event('BOAT_RIDE')) and (has_mask_goron() or is_tall() or can_use_nayru()) or (is_adult() and can_use_din()) end,
            ["Near Swamp Spider House"] = function () return has('MASK_DEKU') or is_tall() or is_swamp_cleared() or can_hookshot_short() or can_use_nayru() or has_hover_boots() end,
            ["Southern Swamp Grotto"] = function () return true end,
            ["Swamp Canopy Front"] = function () return short_hook_anywhere() end,
        },
    },
    ["Southern Swamp Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Near Swamp Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Southern Swamp Grotto"] = function () return true end,
            ["Southern Swamp Grotto Grass 01"] = function () return true end,
            ["Southern Swamp Grotto Grass 02"] = function () return true end,
            ["Southern Swamp Grotto Grass 03"] = function () return true end,
            ["Southern Swamp Grotto Grass 04"] = function () return true end,
            ["Southern Swamp Grotto Grass 05"] = function () return true end,
            ["Southern Swamp Grotto Grass 06"] = function () return true end,
            ["Southern Swamp Grotto Grass 07"] = function () return true end,
            ["Southern Swamp Grotto Grass 08"] = function () return true end,
            ["Southern Swamp Grotto Grass 09"] = function () return true end,
            ["Southern Swamp Grotto Grass 10"] = function () return true end,
            ["Southern Swamp Grotto Grass 11"] = function () return true end,
            ["Southern Swamp Grotto Grass 12"] = function () return true end,
            ["Southern Swamp Grotto Grass 13"] = function () return true end,
            ["Southern Swamp Grotto Grass 14"] = function () return true end,
        },
    },
    ["Tourist Information"] = {
        ["events"] = {
            ["BOAT_RIDE"] = function () return (soul_npc(SOUL_NPC_TOURIST_CENTER) and event('PICTURE_SWAMP') or (event('KOUME') and (not setting('erIndoorsExtra') or can_use_wallet(1)))) and is_swamp_poisoned() end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
            ["Swamp Back"] = function () return event('BOAT_RIDE') end,
        },
        ["locations"] = {
            ["Tourist Information Pictobox"] = function () return event('KOUME') and is_swamp_poisoned() end,
            ["Tourist Information Boat Archery"] = function () return event('KOUME') and is_swamp_cleared() and has_bow() end,
            ["Tourist Information Tingle Picture"] = function () return soul_npc(SOUL_NPC_TOURIST_CENTER) and (event('PICTURE_TINGLE') or event('PICTURE_DEKU_KING')) and is_swamp_poisoned() end,
        },
    },
    ["Woods of Mystery"] = {
        ["events"] = {
            ["KOUME"] = function () return soul_npc(SOUL_NPC_KOUME_KOTAKE) and has_red_or_blue_potion() end,
            ["MEET_KOUME"] = function () return soul_npc(SOUL_NPC_KOUME_KOTAKE) end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Woods of Mystery Lost"] = function () return true end,
            ["Near Woods of Mystery Grotto"] = function () return second_day() end,
        },
        ["locations"] = {
            ["Swamp Potion Shop Kotake"] = function () return soul_npc(SOUL_NPC_KOUME_KOTAKE) end,
            ["Woods of Mystery Grass SW 1"] = function () return first_day() end,
            ["Woods of Mystery Grass SW 2"] = function () return first_day() end,
            ["Woods of Mystery Grass S 1"] = function () return true end,
            ["Woods of Mystery Grass S 2"] = function () return true end,
            ["Woods of Mystery Grass S 3"] = function () return true end,
            ["Woods of Mystery Grass W 1"] = function () return true end,
            ["Woods of Mystery Grass W 2"] = function () return true end,
            ["Woods of Mystery Grass Center 1"] = function () return true end,
            ["Woods of Mystery Grass Center 2"] = function () return true end,
            ["Woods of Mystery Grass Center 3"] = function () return true end,
            ["Woods of Mystery Grass Center 4"] = function () return true end,
            ["Woods of Mystery Grass E 1"] = function () return true end,
            ["Woods of Mystery Grass E 2"] = function () return true end,
            ["Woods of Mystery Grass NW 1"] = function () return final_day() end,
            ["Woods of Mystery Grass NW 2"] = function () return final_day() end,
            ["Woods of Mystery Grass N 1"] = function () return true end,
            ["Woods of Mystery Grass N 2"] = function () return true end,
            ["Woods of Mystery Grass NE 1"] = function () return true end,
            ["Woods of Mystery Grass NE 2"] = function () return true end,
            ["Woods of Mystery Grass NE 3"] = function () return true end,
            ["Woods of Mystery Grass NE 4"] = function () return true end,
            ["Woods of Mystery Grass NE 5"] = function () return true end,
        },
    },
    ["Near Woods of Mystery Grotto"] = {
        ["exits"] = {
            ["Woods of Mystery"] = function () return second_day() end,
            ["Woods of Mystery Lost"] = function () return true end,
            ["Woods of Mystery Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Woods of Mystery Grass SE"] = function () return true end,
        },
    },
    ["Woods of Mystery Lost"] = {
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
        },
    },
    ["Woods of Mystery Grotto"] = {
        ["events"] = {
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Near Woods of Mystery Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Woods of Mystery Grotto"] = function () return true end,
            ["Woods of Mystery Grotto Grass 01"] = function () return true end,
            ["Woods of Mystery Grotto Grass 02"] = function () return true end,
            ["Woods of Mystery Grotto Grass 03"] = function () return true end,
            ["Woods of Mystery Grotto Grass 04"] = function () return true end,
            ["Woods of Mystery Grotto Grass 05"] = function () return true end,
            ["Woods of Mystery Grotto Grass 06"] = function () return true end,
            ["Woods of Mystery Grotto Grass 07"] = function () return true end,
            ["Woods of Mystery Grotto Grass 08"] = function () return true end,
            ["Woods of Mystery Grotto Grass 09"] = function () return true end,
            ["Woods of Mystery Grotto Grass 10"] = function () return true end,
            ["Woods of Mystery Grotto Grass 11"] = function () return true end,
            ["Woods of Mystery Grotto Grass 12"] = function () return true end,
            ["Woods of Mystery Grotto Grass 13"] = function () return true end,
            ["Woods of Mystery Grotto Grass 14"] = function () return true end,
        },
    },
    ["Swamp Potion Shop"] = {
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Potion Shop Item 1"] = function () return soul_npc(SOUL_NPC_KOUME_KOTAKE) and has_mushroom() and shop_price(13) and (first_day() or event('MEET_KOUME')) end,
            ["Swamp Potion Shop Item 2"] = function () return soul_npc(SOUL_NPC_KOUME_KOTAKE) and shop_price(14) and (first_day() or event('MEET_KOUME')) end,
            ["Swamp Potion Shop Item 3"] = function () return soul_npc(SOUL_NPC_KOUME_KOTAKE) and shop_price(15) and (first_day() or event('MEET_KOUME')) end,
            ["Swamp Potion Shop Rupee"] = function () return true end,
        },
    },
    ["Deku Palace Front"] = {
        ["events"] = {
            ["NUTS"] = function () return soul_deku_baba() and (has('MASK_DEKU') or short_hook_anywhere() or ((is_swamp_cleared() or has_hover_boots()) and (can_fight() or has_arrows() or has_explosives() or can_hookshot_short()))) end,
        },
        ["exits"] = {
            ["Swamp Back"] = function () return true end,
            ["Deku Palace Cliff"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
            ["Near Deku Shrine"] = function () return is_swamp_cleared() or (can_use_nayru() and (has_mask_zora() or (is_adult() and (has_arrows() or can_hookshot_short() or can_use_din())))) or (has_hover_boots() and (has_arrows() or can_hookshot_short() or can_use_din())) end,
            ["Deku Palace Main"] = function () return has('MASK_DEKU') or trick('MM_PALACE_GUARD_SKIP') or short_hook_anywhere() end,
            ["Deku Palace Upper"] = function () return (is_swamp_cleared() or has('MASK_DEKU') or can_use_nayru()) and can_use_beans() end,
        },
    },
    ["Deku Palace Main"] = {
        ["exits"] = {
            ["Deku Palace Throne"] = function () return true end,
            ["Deku Palace Front"] = function () return true end,
            ["Deku Palace Grotto"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Upper"] = function () return trick('MM_PALACE_BEAN_SKIP') or short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Deku Palace HP"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Right 01"] = function () return true end,
            ["Deku Palace Rupee Right 02"] = function () return true end,
            ["Deku Palace Rupee Right 03"] = function () return true end,
            ["Deku Palace Rupee Right 04"] = function () return true end,
            ["Deku Palace Rupee Right 05"] = function () return true end,
            ["Deku Palace Rupee Right 06"] = function () return true end,
            ["Deku Palace Rupee Right 07"] = function () return true end,
            ["Deku Palace Rupee Right 08"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Right 09"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Right 10"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Right 11"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Right 12"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Right 13"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Left 01"] = function () return true end,
            ["Deku Palace Rupee Left 02"] = function () return true end,
            ["Deku Palace Rupee Left 03"] = function () return true end,
            ["Deku Palace Rupee Left 05"] = function () return true end,
            ["Deku Palace Rupee Left 06"] = function () return true end,
            ["Deku Palace Rupee Left 07"] = function () return true end,
            ["Deku Palace Rupee Left 08"] = function () return true end,
            ["Deku Palace Rupee Left 09"] = function () return true end,
            ["Deku Palace Rupee Left 10"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Left 11"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
            ["Deku Palace Rupee Left 12"] = function () return is_child() or has('MASK_DEKU') or trick('MM_PALACE_BEAN_SKIP') end,
        },
    },
    ["Deku Palace Upper"] = {
        ["events"] = {
            ["MAGIC"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
        },
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
            ["Deku Palace Near Cage"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Deku Palace Pot 1"] = function () return true end,
            ["Deku Palace Pot 2"] = function () return true end,
        },
    },
    ["Deku Palace Throne"] = {
        ["events"] = {
            ["PICTURE_DEKU_KING"] = function () return has('PICTOGRAPH_BOX') and has('MASK_DEKU') and soul_npc(SOUL_NPC_DEKU_KING) end,
            ["RETURN_PRINCESS"] = function () return is_swamp_cleared() and has_deku_princess() and has('MASK_DEKU') and soul_npc(SOUL_NPC_DEKU_KING) end,
        },
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
            ["Deku Palace Cage"] = function () return event('RETURN_PRINCESS') and short_hook_anywhere() end,
        },
    },
    ["Deku Palace Near Cage"] = {
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
            ["Deku Palace Upper"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
            ["Deku Palace Cage"] = function () return true end,
        },
    },
    ["Deku Palace Cage"] = {
        ["exits"] = {
            ["Deku Palace Near Cage"] = function () return true end,
            ["Deku Palace Throne"] = function () return short_hook_anywhere() and trick('MM_ESCAPE_CAGE') and has('MASK_DEKU') end,
        },
        ["locations"] = {
            ["Deku Palace Sonata of Awakening"] = function () return is_swamp_poisoned() and has('MASK_DEKU') and has_ocarina() end,
        },
    },
    ["Deku Palace Grotto"] = {
        ["events"] = {
            ["MAGIC_BEANS_PALACE"] = function () return soul_bean_salesman() and can_use_wallet(1) end,
            ["ARROWS"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["WATER"] = function () return true end,
        },
        ["exits"] = {
            ["Deku Palace Main"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Palace Grotto Chest"] = function () return can_use_beans() or can_hookshot_short() end,
            ["Deku Palace Grotto Grass 01"] = function () return true end,
            ["Deku Palace Grotto Grass 02"] = function () return true end,
            ["Deku Palace Grotto Grass 03"] = function () return true end,
            ["Deku Palace Grotto Grass 04"] = function () return true end,
            ["Deku Palace Grotto Grass 05"] = function () return true end,
            ["Deku Palace Grotto Grass 06"] = function () return true end,
            ["Deku Palace Grotto Grass 07"] = function () return true end,
            ["Deku Palace Grotto Grass 08"] = function () return true end,
            ["Deku Palace Grotto Grass 09"] = function () return true end,
            ["Deku Palace Grotto Grass 10"] = function () return true end,
            ["Deku Palace Grotto Grass 11"] = function () return true end,
            ["Deku Palace Grotto Grass 12"] = function () return true end,
        },
    },
    ["Deku Palace Cliff"] = {
        ["exits"] = {
            ["Deku Palace Front"] = function () return has('MASK_DEKU') or is_swamp_cleared() or short_hook_anywhere() or can_use_nayru() or has_hover_boots() end,
            ["Swamp Canopy Front"] = function () return true end,
        },
    },
    ["Swamp Canopy Front"] = {
        ["exits"] = {
            ["Swamp Back"] = function () return short_hook_anywhere() or has('MASK_DEKU') or is_tall() or has_hover_boots() end,
            ["Near Swamp Spider House"] = function () return short_hook_anywhere() or has('MASK_DEKU') or is_tall() or has_hover_boots() end,
            ["Near Swamp Grotto"] = function () return true end,
            ["Deku Palace Cliff"] = function () return true end,
            ["Swamp Canopy Back"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
        },
    },
    ["Swamp Canopy Back"] = {
        ["exits"] = {
            ["Swamp Front"] = function () return (has('MASK_DEKU') or has_mask_goron() or is_tall() or has_hover_boots() or can_use_nayru()) and (can_hookshot() or has_arrows() or event('BOAT_RIDE')) end,
            ["Swamp Back"] = function () return has('MASK_DEKU') or is_tall() or is_swamp_cleared() or can_use_nayru() or has_hover_boots() end,
            ["Woodfall"] = function () return true end,
            ["Swamp Canopy Front"] = function () return short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Southern Swamp Song of Soaring"] = function () return has('MASK_DEKU') or short_hook_anywhere() or (has_hover_boots() and has_mask_bunny() and (has_weapon() or has_explosives()) and trick('MM_SOARING_HOVERS')) or (has_mask_zora() and has_explosives() and trick('MM_SOARING_ZORA')) end,
        },
    },
    ["Woodfall"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Swamp Canopy Back"] = function () return true end,
            ["Woodfall Shrine"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or is_swamp_cleared()) or hookshot_anywhere() end,
            ["Woodfall Temple Princess Jail"] = function () return is_swamp_cleared() and woodfall_raised() end,
            ["Woodfall Near Fairy Fountain"] = function () return (is_swamp_cleared() or can_use_nayru()) and short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Woodfall Entrance Chest"] = function () return has('MASK_DEKU') or can_hookshot() or is_swamp_cleared() or can_use_nayru() or has_hover_boots() end,
            ["Woodfall HP Chest"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or is_swamp_cleared()) or can_hookshot() or (is_adult() and can_hookshot_short() and (is_swamp_cleared() or can_use_nayru())) end,
            ["Woodfall Near Owl Chest"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or is_swamp_cleared()) or (is_swamp_cleared() and can_hookshot()) or (is_adult() and can_hookshot_short() and (is_swamp_cleared() or can_use_nayru())) or hookshot_anywhere() end,
            ["Woodfall Grass 1"] = function () return true end,
            ["Woodfall Grass 2"] = function () return true end,
            ["Woodfall Grass 3"] = function () return true end,
            ["Woodfall Grass 4"] = function () return true end,
            ["Woodfall Grass 5"] = function () return true end,
            ["Woodfall Grass 6"] = function () return true end,
            ["Woodfall Rupee"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or is_swamp_cleared()) or hookshot_anywhere() or has_hover_boots() end,
        },
    },
    ["Woodfall Front of Temple"] = {
        ["exits"] = {
            ["Woodfall Temple"] = function () return woodfall_raised() end,
            ["Woodfall Shrine"] = function () return cond(setting('openDungeonsMm', 'WF') or setting('clearStateDungeonsMm', 'WF') or setting('clearStateDungeonsMm', 'both'), has('MASK_DEKU') or hookshot_anywhere(), true) end,
            ["Woodfall"] = function () return is_swamp_cleared() or can_use_nayru() end,
        },
    },
    ["Woodfall Shrine"] = {
        ["events"] = {
            ["OPEN_WOODFALL_TEMPLE"] = function () return has('MASK_DEKU') and can_play_awakening() end,
        },
        ["exits"] = {
            ["Woodfall"] = function () return has('MASK_DEKU') and soul_deku_scrub() or is_swamp_cleared() or hookshot_anywhere() or can_use_nayru() end,
            ["Woodfall Near Fairy Fountain"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or is_swamp_cleared() or short_hook_anywhere()) or hookshot_anywhere() end,
            ["Woodfall Front of Temple"] = function () return woodfall_raised() and (has('MASK_DEKU') or hookshot_anywhere()) end,
            ["Owl Woodfall"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Near Owl Chest"] = function () return short_hook_anywhere() or (has_hover_boots() and has_mask_bunny() and has_weapon() and trick('MM_WF_SHRINE_HOVERS')) end,
        },
    },
    ["Woodfall Near Fairy Fountain"] = {
        ["exits"] = {
            ["Woodfall"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or is_swamp_cleared()) or is_swamp_cleared() or hookshot_anywhere() or can_use_nayru() end,
            ["Woodfall Shrine"] = function () return has('MASK_DEKU') and (soul_deku_scrub() or is_swamp_cleared()) or hookshot_anywhere() end,
            ["Woodfall Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Near Owl Chest"] = function () return can_hookshot() or (is_adult() and can_hookshot_short() and (is_swamp_cleared() or can_use_nayru())) end,
        },
    },
    ["Woodfall Fairy Fountain"] = {
        ["exits"] = {
            ["Woodfall Near Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Great Fairy"] = function () return has('STRAY_FAIRY_WF', 15) end,
        },
    },
    ["Near Deku Shrine"] = {
        ["exits"] = {
            ["Deku Palace Front"] = function () return is_swamp_cleared() or has('MASK_DEKU') or can_use_nayru() or has_hover_boots() end,
            ["Deku Shrine"] = function () return true end,
        },
    },
    ["Deku Shrine"] = {
        ["exits"] = {
            ["Near Deku Shrine"] = function () return true end,
            ["Deku Shrine Main"] = function () return soul_npc(SOUL_NPC_BUTLER_DEKU) and event('RETURN_PRINCESS') end,
        },
    },
    ["Deku Shrine Main"] = {
        ["exits"] = {
            ["Deku Shrine End"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Shrine Pot 1"] = function () return true end,
            ["Deku Shrine Pot 2"] = function () return true end,
            ["Deku Shrine Rupee Main 01"] = function () return true end,
            ["Deku Shrine Rupee Main 02"] = function () return true end,
            ["Deku Shrine Rupee Main 03"] = function () return true end,
            ["Deku Shrine Rupee Main 04"] = function () return true end,
            ["Deku Shrine Rupee Main 05"] = function () return true end,
            ["Deku Shrine Rupee Main 06"] = function () return true end,
            ["Deku Shrine Rupee Main 07"] = function () return true end,
            ["Deku Shrine Rupee Main 08"] = function () return true end,
            ["Deku Shrine Rupee Main 09"] = function () return true end,
            ["Deku Shrine Rupee Main 10"] = function () return true end,
            ["Deku Shrine Rupee Main 11"] = function () return true end,
            ["Deku Shrine Rupee Main 12"] = function () return true end,
            ["Deku Shrine Rupee Main 13"] = function () return true end,
            ["Deku Shrine Rupee Main 14"] = function () return true end,
            ["Deku Shrine Rupee Main 15"] = function () return true end,
            ["Deku Shrine Rupee Main 16"] = function () return true end,
            ["Deku Shrine Rupee Main 17"] = function () return true end,
            ["Deku Shrine Rupee Main 18"] = function () return true end,
            ["Deku Shrine Rupee Main 19"] = function () return true end,
            ["Deku Shrine Rupee Main 20"] = function () return true end,
        },
    },
    ["Deku Shrine End"] = {
        ["locations"] = {
            ["Deku Shrine Mask of Scents"] = function () return true end,
            ["Deku Shrine Rupee End 01"] = function () return true end,
            ["Deku Shrine Rupee End 02"] = function () return true end,
            ["Deku Shrine Rupee End 03"] = function () return true end,
            ["Deku Shrine Rupee End 04"] = function () return true end,
            ["Deku Shrine Rupee End 05"] = function () return true end,
            ["Deku Shrine Rupee End 06"] = function () return true end,
            ["Deku Shrine Rupee End 07"] = function () return true end,
            ["Deku Shrine Rupee End 08"] = function () return true end,
            ["Deku Shrine Rupee End 09"] = function () return true end,
            ["Deku Shrine Rupee End 10"] = function () return true end,
        },
    },
    ["Behind Large Icicles"] = {
        ["exits"] = {
            ["Termina Field"] = function () return has_arrows() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE')) or has_hot_water_farore() or has_hot_water_mtn() or has_hot_water_er() or short_hook_anywhere() or can_use_din() end,
            ["Mountain Village Path Lower"] = function () return true end,
        },
    },
    ["Mountain Village Path Lower"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() and soul_tektite() and (is_day() or can_break_snowballs()) end,
            ["MAGIC"] = function () return is_spring() end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Behind Large Icicles"] = function () return true end,
            ["Mountain Village Path Upper"] = function () return can_break_snowballs() or is_spring() or short_hook_anywhere() end,
        },
    },
    ["Mountain Village Path Upper"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return can_use_light_arrows() and soul_tektite() and is_day() end,
        },
        ["exits"] = {
            ["Mountain Village Path Lower"] = function () return true end,
            ["Mountain Village"] = function () return true end,
        },
    },
    ["Mountain Village"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return is_spring() or (can_break_snowballs() and (second_day() or final_day())) or (can_break_snowballs() and can_use_light_arrows() and first_day() and soul_tektite()) end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Mountain Village Path Upper"] = function () return true end,
            ["Twin Islands"] = function () return true end,
            ["Mountain Village Cliff"] = function () return is_winter() and (can_use_lens_strict() or trick('MM_DARMANI_WALL')) or event('GORON_GRAVE_FARORE') or (is_spring() and (has_mask_goron() or has_mask_zora() or can_hookshot() or short_hook_anywhere())) end,
            ["Path to Snowhead Front"] = function () return true end,
            ["Blacksmith"] = function () return true end,
            ["Near Village Grotto"] = function () return is_spring() and (has_mask_goron() or short_hook_anywhere()) end,
            ["Owl Mountain"] = function () return true end,
            ["Mountain Village Elder"] = function () return true end,
            ["Mountain Village Keaton"] = function () return true end,
        },
        ["locations"] = {
            ["Mountain Village Waterfall Chest"] = function () return is_spring() and can_use_lens() end,
            ["Mountain Village Don Gero Mask"] = function () return is_winter() and soul_goron() and event('GORON_FOOD') end,
            ["Mountain Village Frog Choir HP"] = function () return is_spring() and event('FROG_1') and event('FROG_2') and event('FROG_3') and event('FROG_4') end,
            ["Mountain Village Pot"] = function () return scarecrow_hookshot() or short_hook_anywhere() end,
            ["Mountain Village Grass 1"] = function () return is_spring() end,
            ["Mountain Village Grass 2"] = function () return is_spring() end,
            ["Mountain Village Grass 3"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 1"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 2"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 3"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 4"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 5"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 6"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 7"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 8"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 1 Grass 9"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 1"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 2"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 3"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 4"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 5"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 6"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 7"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 8"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 2 Grass 9"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 1"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 2"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 3"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 4"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 5"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 6"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 7"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 8"] = function () return is_spring() end,
            ["Mountain Village Grass Pack 3 Grass 9"] = function () return is_spring() end,
            ["Mountain Village Keaton Grass Reward 1"] = function () return is_spring() end,
            ["Mountain Village Keaton Grass Reward 2"] = function () return is_spring() and keaton_grass_easy() end,
            ["Mountain Village Keaton Grass Reward 3"] = function () return is_spring() and keaton_grass_easy() end,
            ["Mountain Village Keaton Grass Reward 4"] = function () return is_spring() and keaton_grass_easy() end,
            ["Mountain Village Keaton Grass Reward 5"] = function () return is_spring() and keaton_grass_easy() end,
            ["Mountain Village Keaton Grass Reward 6"] = function () return is_spring() and keaton_grass_hard() end,
            ["Mountain Village Keaton Grass Reward 7"] = function () return is_spring() and keaton_grass_hard() end,
            ["Mountain Village Keaton Grass Reward 8"] = function () return is_spring() and keaton_grass_hard() end,
            ["Mountain Village Keaton Grass Reward 9"] = function () return is_spring() and keaton_grass_hard() end,
            ["Mountain Village Rupee"] = function () return is_spring() and has_mask_goron() end,
        },
    },
    ["Mountain Village Elder"] = {
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Elder"] = function () return soul_npc(SOUL_NPC_GORON_ELDER) and is_winter() and final_day() and has_mask_goron() and (can_use_fire_short_range() or has_hot_water_er() or has_hot_water_mtn() or has_hot_water_farore() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE'))) end,
        },
    },
    ["Mountain Village Keaton"] = {
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Keaton HP"] = function () return is_spring() and soul_npc(SOUL_NPC_KEATON) and has_mask_keaton() end,
        },
    },
    ["Near Village Grotto"] = {
        ["exits"] = {
            ["Mountain Village Grotto"] = function () return is_spring() end,
            ["Mountain Village"] = function () return true end,
            ["Mountain Village Cliff"] = function () return is_spring() and (has_mask_goron() or short_hook_anywhere()) end,
        },
    },
    ["Mountain Village Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["BUGS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Near Village Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Mountain Village Tunnel Grotto"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 01"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 02"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 03"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 04"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 05"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 06"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 07"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 08"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 09"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 10"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 11"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 12"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 13"] = function () return true end,
            ["Mountain Village Tunnel Grotto Grass 14"] = function () return true end,
        },
    },
    ["Blacksmith"] = {
        ["events"] = {
            ["BLACKSMITH_ENABLED"] = function () return is_spring() or (is_winter() and (can_use_fire_short_range() or has_hot_water_mtn() or has_hot_water_er() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE')))) end,
            ["GOLD_DUST_USED"] = function () return soul_npc(SOUL_NPC_BLACKSMITHS) and can_use_wallet(2) and has('BOTTLED_GOLD_DUST') and event('BLACKSMITH_ENABLED') end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
        },
        ["locations"] = {
            ["Blacksmith Razor Blade"] = function () return soul_npc(SOUL_NPC_BLACKSMITHS) and can_use_wallet(2) and event('BLACKSMITH_ENABLED') end,
            ["Blacksmith Gilded Sword"] = function () return event('GOLD_DUST_USED') end,
        },
    },
    ["Twin Islands"] = {
        ["events"] = {
            ["PICTURE_TINGLE"] = function () return soul_npc(SOUL_NPC_TINGLE) and has('PICTOGRAPH_BOX') end,
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return can_use_light_arrows() and (soul_tektite() or soul_wolfos() or (can_break_snowballs() and soul_enemy(SOUL_ENEMY_SNAPPER))) or is_spring() end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Goron Village"] = function () return true end,
            ["Near Goron Race"] = function () return has_mask_goron() or scarecrow_hookshot() or short_hook_anywhere() end,
            ["Near Ramp Grotto"] = function () return has_mask_goron() or short_hook_anywhere() end,
            ["Twin Islands Frozen Grotto"] = function () return is_spring() or (is_winter() and (can_use_fire_short_range() or has_hot_water_mtn() or has_hot_water_er() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE')))) end,
            ["Tingle Mountain"] = function () return soul_npc(SOUL_NPC_TINGLE) and has_weapon_range() end,
        },
        ["locations"] = {
            ["Twin Islands Underwater Chest 1"] = function () return is_spring() and underwater_walking() end,
            ["Twin Islands Underwater Chest 2"] = function () return is_spring() and underwater_walking() end,
            ["Goron Elder"] = function () return soul_npc(SOUL_NPC_GORON_ELDER) and is_winter() and (first_day() or second_day()) and has_mask_goron() and (can_use_fire_short_range() or has_hot_water_er() or has_hot_water_mtn() or has_hot_water_farore() or (has_hot_water_distance() and has('OWL_MOUNTAIN_VILLAGE'))) end,
            ["Twin Islands Grass 01"] = function () return is_spring() end,
            ["Twin Islands Grass 02"] = function () return is_spring() end,
            ["Twin Islands Grass 03"] = function () return is_spring() end,
            ["Twin Islands Grass 04"] = function () return is_spring() end,
            ["Twin Islands Grass 05"] = function () return is_spring() end,
            ["Twin Islands Grass 06"] = function () return is_spring() end,
            ["Twin Islands Grass 07"] = function () return is_spring() end,
            ["Twin Islands Grass 08"] = function () return is_spring() end,
            ["Twin Islands Grass 09"] = function () return is_spring() end,
            ["Twin Islands Grass 10"] = function () return is_spring() end,
            ["Twin Islands Grass 11"] = function () return is_spring() end,
            ["Twin Islands Grass 12"] = function () return is_spring() end,
            ["Twin Islands Rupee 1"] = function () return is_spring() and (underwater_walking() or can_dive_small()) end,
            ["Twin Islands Rupee 2"] = function () return is_spring() and (underwater_walking() or can_dive_small()) end,
            ["Twin Islands Rupee 3"] = function () return is_spring() and (underwater_walking() or can_dive_small()) end,
            ["Twin Islands Rupee 4"] = function () return is_spring() and (underwater_walking() or can_dive_small()) end,
        },
    },
    ["Twin Islands Ramp Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["BUGS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Near Ramp Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Twin Islands Ramp Grotto Chest"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 01"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 02"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 03"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 04"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 05"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 06"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 07"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 08"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 09"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 10"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 11"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 12"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 13"] = function () return true end,
            ["Twin Islands Ramp Grotto Grass 14"] = function () return true end,
        },
    },
    ["Twin Islands Frozen Grotto"] = {
        ["events"] = {
            ["HOT_WATER_NORTH_WINTER"] = function () return is_winter() end,
            ["HOT_WATER_NORTH_SPRING"] = function () return is_spring() end,
            ["HOT_WATER_NORTH"] = function () return is_spring_or_winter() end,
            ["WATER"] = function () return true end,
            ["STICKS"] = function () return can_kill_baba_sticks() end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
        },
        ["locations"] = {
            ["Twin Islands Frozen Grotto Chest"] = function () return has_explosives() or trick_keg_explosives() or (trick('MM_KEG_EXPLOSIVES') and event('POWDER_KEG_TRIAL')) end,
        },
    },
    ["Near Goron Race"] = {
        ["events"] = {
            ["TRIAL_BOULDER"] = function () return can_use_keg() or (setting('erOverworld', 'none') and event('POWDER_KEG_TRIAL')) end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
            ["Goron Race"] = function () return event('TRIAL_BOULDER') or (short_hook_anywhere() and trick('MM_HARD_HOOKSHOT')) end,
            ["Near Ramp Grotto"] = function () return true end,
        },
    },
    ["Near Ramp Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
            ["Twin Islands Ramp Grotto"] = function () return has_explosives() or trick_keg_explosives() or (trick('MM_KEG_EXPLOSIVES') and event('POWDER_KEG_TRIAL')) end,
        },
    },
    ["Goron Village"] = {
        ["events"] = {
            ["POWDER_KEG_TRIAL"] = function () return soul_medigoron() and (is_spring() or can_use_fire_short_range()) and has_mask_goron() end,
            ["BUY_KEG"] = function () return soul_medigoron() and event('POWDER_KEG_TRIAL') and event('TRIAL_BOULDER') and has('POWDER_KEG') and can_use_wallet(2) end,
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["NUTS"] = function () return true end,
            ["STICKS"] = function () return true end,
            ["RUPEES"] = function () return can_break_snowballs() or (can_use_light_arrows() and soul_tektite()) end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
            ["Front of Lone Peak Shrine"] = function () return is_winter() end,
            ["Goron Shrine"] = function () return soul_goron() and first_day() or has_mask_goron() end,
        },
        ["locations"] = {
            ["Goron Village HP"] = function () return has('DEED_SWAMP') and has('MASK_DEKU') or short_hook_anywhere() end,
            ["Goron Village Scrub Deed"] = function () return soul_business_scrub() and has('DEED_SWAMP') and has('MASK_DEKU') end,
            ["Goron Village Scrub Bomb Bag"] = function () return soul_business_scrub() and has_mask_goron() and can_use_wallet(2) end,
            ["Goron Powder Keg"] = function () return event('TRIAL_BOULDER') and (event('POWDER_KEG_TRIAL') or (short_hook_anywhere() and trick('MM_KEG_TRIAL_HEATLESS'))) end,
        },
    },
    ["Front of Lone Peak Shrine"] = {
        ["exits"] = {
            ["Goron Village"] = function () return is_winter() and can_use_lens() end,
            ["Lone Peak Shrine"] = function () return true end,
        },
    },
    ["Lone Peak Shrine"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["BUGS"] = function () return true end,
        },
        ["exits"] = {
            ["Front of Lone Peak Shrine"] = function () return true end,
        },
        ["locations"] = {
            ["Lone Peak Shrine Lens Chest"] = function () return true end,
            ["Lone Peak Shrine Boulder Chest"] = function () return has_explosives() or trick_keg_explosives() end,
            ["Lone Peak Shrine Invisible Chest"] = function () return can_use_lens() end,
            ["Lone Peak Shrine Grass Pack 1 Grass 01"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 02"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 03"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 04"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 05"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 06"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 07"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 08"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 09"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 10"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 11"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 1 Grass 12"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 01"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 02"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 03"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 04"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 05"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 06"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 07"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 08"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 09"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 10"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 11"] = function () return true end,
            ["Lone Peak Shrine Grass Pack 2 Grass 12"] = function () return true end,
        },
    },
    ["Mountain Village Cliff"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return is_spring() end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Goron Graveyard"] = function () return true end,
            ["Near Village Grotto"] = function () return is_spring() end,
        },
    },
    ["Near Goron Graveyard"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["GORON_GRAVE_FARORE"] = function () return can_use_farore() end,
        },
        ["exits"] = {
            ["Mountain Village Cliff"] = function () return true end,
        },
    },
    ["Goron Graveyard"] = {
        ["exits"] = {
            ["Near Goron Graveyard"] = function () return true end,
            ["Goron Graveyard Water"] = function () return has_mask_goron() or can_lift_gold() end,
        },
        ["locations"] = {
            ["Goron Graveyard Mask"] = function () return can_use_lens_strict() and can_play_healing() end,
        },
    },
    ["Goron Graveyard Water"] = {
        ["events"] = {
            ["WATER"] = function () return true end,
            ["HOT_WATER_NORTH_WINTER"] = function () return is_winter() end,
            ["HOT_WATER_NORTH_SPRING"] = function () return is_spring() end,
            ["HOT_WATER_NORTH"] = function () return is_spring_or_winter() end,
        },
        ["exits"] = {
            ["Goron Graveyard"] = function () return true end,
        },
    },
    ["Goron Shrine"] = {
        ["events"] = {
            ["GORON_FOOD"] = function () return is_winter() and goron_fast_roll() and (can_use_fire_arrows() or (can_lullaby_half() and soul_goron_child())) end,
            ["STICKS"] = function () return true end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Goron Village"] = function () return true end,
            ["Goron Shop"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Baby"] = function () return is_winter() and soul_goron_child() and has_mask_goron() and can_lullaby_half() end,
            ["Goron Shrine Pot 01"] = function () return true end,
            ["Goron Shrine Pot 02"] = function () return true end,
            ["Goron Shrine Pot 03"] = function () return true end,
            ["Goron Shrine Pot 04"] = function () return true end,
            ["Goron Shrine Pot 05"] = function () return true end,
            ["Goron Shrine Pot 06"] = function () return true end,
            ["Goron Shrine Pot 07"] = function () return true end,
            ["Goron Shrine Pot 08"] = function () return true end,
            ["Goron Shrine Pot 09"] = function () return true end,
            ["Goron Shrine Pot 10"] = function () return true end,
            ["Goron Shrine Pot 11"] = function () return true end,
        },
    },
    ["Goron Shrine From Shop"] = {
        ["exits"] = {
            ["Goron Shrine"] = function () return true end,
        },
    },
    ["Goron Shop"] = {
        ["exits"] = {
            ["Goron Shrine From Shop"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Shop Item 1"] = function () return soul_goron_shopkeeper() and shop_price(16) end,
            ["Goron Shop Item 2"] = function () return soul_goron_shopkeeper() and shop_price(17) end,
            ["Goron Shop Item 3"] = function () return soul_goron_shopkeeper() and shop_price(18) end,
        },
    },
    ["Path to Snowhead Front"] = {
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Path to Snowhead Middle"] = function () return goron_fast_roll() or hookshot_anywhere() or (has_hover_boots() and trick('MM_PATH_SNOWHEAD_HOVERS')) end,
        },
    },
    ["Path to Snowhead Middle"] = {
        ["exits"] = {
            ["Path to Snowhead Front"] = function () return true end,
            ["Path to Snowhead Back"] = function () return true end,
        },
        ["locations"] = {
            ["Path to Snowhead HP"] = function () return can_use_lens() and (scarecrow_hookshot() or hookshot_anywhere()) end,
        },
    },
    ["Path to Snowhead Back"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_break_boulders() end,
        },
        ["exits"] = {
            ["Path to Snowhead Middle"] = function () return goron_fast_roll() or hookshot_anywhere() or (has_hover_boots() and trick('MM_PATH_SNOWHEAD_HOVERS')) end,
            ["Snowhead Entrance"] = function () return true end,
            ["Path to Snowhead Grotto"] = function () return has_explosives() or trick_keg_explosives() end,
        },
    },
    ["Path to Snowhead Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["BUGS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["MUSHROOM"] = function () return has('MASK_SCENTS') end,
        },
        ["exits"] = {
            ["Path to Snowhead Back"] = function () return true end,
        },
        ["locations"] = {
            ["Path to Snowhead Grotto"] = function () return true end,
            ["Path to Snowhead Grotto Grass 01"] = function () return true end,
            ["Path to Snowhead Grotto Grass 02"] = function () return true end,
            ["Path to Snowhead Grotto Grass 03"] = function () return true end,
            ["Path to Snowhead Grotto Grass 04"] = function () return true end,
            ["Path to Snowhead Grotto Grass 05"] = function () return true end,
            ["Path to Snowhead Grotto Grass 06"] = function () return true end,
            ["Path to Snowhead Grotto Grass 07"] = function () return true end,
            ["Path to Snowhead Grotto Grass 08"] = function () return true end,
            ["Path to Snowhead Grotto Grass 09"] = function () return true end,
            ["Path to Snowhead Grotto Grass 10"] = function () return true end,
            ["Path to Snowhead Grotto Grass 11"] = function () return true end,
            ["Path to Snowhead Grotto Grass 12"] = function () return true end,
            ["Path to Snowhead Grotto Grass 13"] = function () return true end,
            ["Path to Snowhead Grotto Grass 14"] = function () return true end,
        },
    },
    ["Snowhead Entrance"] = {
        ["events"] = {
            ["OPEN_SNOWHEAD_TEMPLE"] = function () return soul_biggoron() and can_lullaby() and has_mask_goron() end,
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Path to Snowhead Back"] = function () return true end,
            ["Snowhead"] = function () return (blizzard_stopped() or (has_iron_boots() and trick('MM_LULLABY_SKIP_IRONS'))) and has_mask_goron() end,
            ["Snowhead Near Fairy Fountain"] = function () return (blizzard_stopped() or (has_iron_boots() and trick('MM_LULLABY_SKIP_IRONS'))) and has_mask_goron() end,
            ["Owl Snowhead"] = function () return true end,
        },
    },
    ["Snowhead"] = {
        ["exits"] = {
            ["Snowhead Entrance"] = function () return can_lullaby() and has_mask_goron() or blizzard_stopped() or has_iron_boots() end,
            ["Snowhead Temple"] = function () return true end,
            ["Snowhead Near Fairy Fountain"] = function () return blizzard_stopped() or has_iron_boots() end,
        },
    },
    ["Snowhead Near Fairy Fountain"] = {
        ["events"] = {
            ["MAGIC"] = function () return (blizzard_stopped() or has_iron_boots()) and can_break_boulders() or is_spring() end,
            ["RUPEES"] = function () return blizzard_stopped() and can_use_light_arrows() and soul_wolfos() end,
        },
        ["exits"] = {
            ["Snowhead Entrance"] = function () return blizzard_stopped() or has_iron_boots() end,
            ["Snowhead"] = function () return blizzard_stopped() or has_iron_boots() end,
            ["Snowhead Fairy Fountain"] = function () return true end,
        },
    },
    ["Snowhead Fairy Fountain"] = {
        ["exits"] = {
            ["Snowhead Near Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Great Fairy"] = function () return has('STRAY_FAIRY_SH', 15) end,
        },
    },
    ["Goron Race"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Near Goron Race"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Race Reward"] = function () return is_spring() and soul_goron_child() and goron_fast_roll() end,
            ["Goron Race Pot 01"] = function () return true end,
            ["Goron Race Pot 02"] = function () return true end,
            ["Goron Race Pot 03"] = function () return true end,
            ["Goron Race Pot 04"] = function () return true end,
            ["Goron Race Pot 05"] = function () return true end,
            ["Goron Race Pot 06"] = function () return true end,
            ["Goron Race Pot 07"] = function () return true end,
            ["Goron Race Pot 08"] = function () return true end,
            ["Goron Race Pot 09"] = function () return true end,
            ["Goron Race Pot 10"] = function () return true end,
            ["Goron Race Pot 11"] = function () return true end,
            ["Goron Race Pot 12"] = function () return true end,
            ["Goron Race Pot 13"] = function () return true end,
            ["Goron Race Pot 14"] = function () return true end,
            ["Goron Race Pot 15"] = function () return true end,
            ["Goron Race Pot 16"] = function () return true end,
            ["Goron Race Pot 17"] = function () return true end,
            ["Goron Race Pot 18"] = function () return true end,
            ["Goron Race Pot 19"] = function () return true end,
            ["Goron Race Pot 20"] = function () return true end,
            ["Goron Race Pot 21"] = function () return true end,
            ["Goron Race Pot 22"] = function () return true end,
            ["Goron Race Pot 23"] = function () return true end,
            ["Goron Race Pot 24"] = function () return true end,
            ["Goron Race Pot 25"] = function () return true end,
            ["Goron Race Pot 26"] = function () return true end,
            ["Goron Race Pot 27"] = function () return true end,
            ["Goron Race Pot 28"] = function () return true end,
            ["Goron Race Pot 29"] = function () return true end,
            ["Goron Race Pot 30"] = function () return true end,
        },
    },
    ["Milk Road"] = {
        ["events"] = {
            ["PICTURE_TINGLE"] = function () return soul_npc(SOUL_NPC_TINGLE) and has('PICTOGRAPH_BOX') end,
            ["RUPEES"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Gorman Track Front"] = function () return true end,
            ["Owl Milk Road"] = function () return true end,
            ["Near Romani Ranch"] = function () return after(DAY3_AM_06_00) or can_use_keg() or (short_hook_anywhere() and trick('MM_OOB_MOVEMENT')) end,
            ["Behind Gorman Fence"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or final_day() or short_hook_anywhere() end,
            ["Tingle Ranch"] = function () return soul_npc(SOUL_NPC_TINGLE) and has_weapon_range() end,
            ["Milk Road Keaton"] = function () return true end,
        },
        ["locations"] = {
            ["Milk Road Keaton Grass Reward 1"] = function () return true end,
            ["Milk Road Keaton Grass Reward 2"] = function () return keaton_grass_easy() end,
            ["Milk Road Keaton Grass Reward 3"] = function () return keaton_grass_easy() end,
            ["Milk Road Keaton Grass Reward 4"] = function () return keaton_grass_easy() end,
            ["Milk Road Keaton Grass Reward 5"] = function () return keaton_grass_easy() end,
            ["Milk Road Keaton Grass Reward 6"] = function () return keaton_grass_hard() end,
            ["Milk Road Keaton Grass Reward 7"] = function () return keaton_grass_hard() end,
            ["Milk Road Keaton Grass Reward 8"] = function () return keaton_grass_hard() end,
            ["Milk Road Keaton Grass Reward 9"] = function () return keaton_grass_hard() end,
        },
    },
    ["Milk Road Keaton"] = {
        ["exits"] = {
            ["Milk Road"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Keaton HP"] = function () return soul_npc(SOUL_NPC_KEATON) and has_mask_keaton() end,
        },
    },
    ["Near Romani Ranch"] = {
        ["exits"] = {
            ["Milk Road"] = function () return after(DAY3_AM_06_00) or can_use_keg() or (short_hook_anywhere() and trick('MM_OOB_MOVEMENT')) end,
            ["Romani Ranch"] = function () return true end,
        },
    },
    ["Romani Ranch"] = {
        ["events"] = {
            ["ALIENS"] = function () return soul_malon() and (at(NIGHT1_AM_02_30) or (trick('MM_RANCH_FARORE') and can_use_farore() and clock_night1())) and has_arrows() end,
            ["ARROWS"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Near Romani Ranch"] = function () return true end,
            ["Cucco Shack"] = function () return between(DAY1_AM_06_00, NIGHT1_PM_08_00) or between(DAY2_AM_06_00, NIGHT2_PM_08_00) or between(DAY3_AM_06_00, NIGHT3_PM_08_00) end,
            ["Doggy Racetrack"] = function () return between(DAY1_AM_06_00, NIGHT1_PM_08_00) or between(DAY2_AM_06_00, NIGHT2_PM_08_00) or between(DAY3_AM_06_00, NIGHT3_PM_08_00) end,
            ["Stables"] = function () return true end,
            ["Ranch House"] = function () return between(DAY1_AM_06_00, NIGHT1_PM_08_00) or between(DAY2_AM_06_00, NIGHT2_PM_08_00) or between(DAY3_AM_06_00, NIGHT3_PM_08_00) end,
        },
        ["locations"] = {
            ["Romani Ranch Epona Song"] = function () return soul_malon() and (before(NIGHT1_PM_06_00) or (trick('MM_RANCH_FARORE') and can_use_farore() and clock_day1())) end,
            ["Romani Ranch Aliens"] = function () return event('ALIENS') end,
            ["Romani Ranch Cremia Escort"] = function () return event('ALIENS') and (at(NIGHT2_PM_06_00) or (trick('MM_RANCH_FARORE') and can_use_farore() and clock_night2())) end,
            ["Romani Ranch Grass Pack 1 Grass 01"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 02"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 03"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 04"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 05"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 06"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 07"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 08"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 09"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 10"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 11"] = function () return true end,
            ["Romani Ranch Grass Pack 1 Grass 12"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 01"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 02"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 03"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 04"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 05"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 06"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 07"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 08"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 09"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 10"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 11"] = function () return true end,
            ["Romani Ranch Grass Pack 2 Grass 12"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 01"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 02"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 03"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 04"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 05"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 06"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 07"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 08"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 09"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 10"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 11"] = function () return true end,
            ["Romani Ranch Grass Pack 3 Grass 12"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 01"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 02"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 03"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 04"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 05"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 06"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 07"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 08"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 09"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 10"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 11"] = function () return true end,
            ["Romani Ranch Grass Pack 4 Grass 12"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 01"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 02"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 03"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 04"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 05"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 06"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 07"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 08"] = function () return true end,
            ["Romani Ranch Grass Pack 5 Grass 09"] = function () return true end,
        },
    },
    ["Cucco Shack"] = {
        ["events"] = {
            ["RUPEES"] = function () return has_weapon_range() or has_weapon() or can_break_boulders() end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Cucco Shack Bunny Mask"] = function () return soul_grog() and has('MASK_BREMEN') end,
        },
    },
    ["Doggy Racetrack"] = {
        ["events"] = {
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Doggy Racetrack Chest"] = function () return can_use_beans() or is_tall() or can_hookshot_short() or trick('MM_DOG_RACE_CHEST_NOTHING') end,
            ["Doggy Racetrack HP"] = function () return soul_dog_lady() and can_use_wallet(1) and has_mask_truth() end,
            ["Doggy Racetrack Pot 1"] = function () return true end,
            ["Doggy Racetrack Pot 2"] = function () return true end,
            ["Doggy Racetrack Pot 3"] = function () return true end,
            ["Doggy Racetrack Pot 4"] = function () return true end,
        },
    },
    ["Stables"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Romani Ranch Barn Cow Left"] = function () return (between(NIGHT1_PM_06_00, NIGHT1_AM_02_30) or event('ALIENS')) and can_play_epona() end,
            ["Romani Ranch Barn Cow Right Front"] = function () return (between(NIGHT1_PM_06_00, NIGHT1_AM_02_30) or event('ALIENS')) and can_play_epona() end,
            ["Romani Ranch Barn Cow Right Back"] = function () return (between(NIGHT1_PM_06_00, NIGHT1_AM_02_30) or event('ALIENS')) and can_play_epona() end,
        },
    },
    ["Ranch House"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
    },
    ["Great Bay Fence"] = {
        ["exits"] = {
            ["Termina Field"] = function () return can_play_epona() or (can_goron_bomb_jump() and has_bombs()) or short_hook_anywhere() end,
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Great Bay Coast"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["FISH"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Fisher's Hut"] = function () return true end,
            ["Great Bay Fence"] = function () return true end,
            ["Great Bay Coast Fortress"] = function () return underwater_walking() end,
            ["Pinnacle Rock Entrance"] = function () return true end,
            ["Laboratory"] = function () return true end,
            ["Zora Cape"] = function () return true end,
            ["Ocean Spider House"] = function () return true end,
            ["Great Bay Grotto"] = function () return true end,
            ["GBC Near Cow Grotto"] = function () return can_hookshot() end,
            ["Owl Great Bay"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Coast Zora Mask"] = function () return can_play_healing() end,
            ["Great Bay Coast HP"] = function () return can_use_beans() and scarecrow_hookshot() or short_hook_anywhere() end,
            ["Great Bay Coast Fisherman HP"] = function () return soul_chest_game_owner() and can_use_wallet(1) and (can_hookshot_short() or can_use_ice_arrows()) and is_ocean_cleared() and (between(DAY1_AM_07_00, NIGHT1_AM_04_00) or between(DAY2_AM_07_00, NIGHT2_AM_04_00) or between(DAY3_AM_07_00, NIGHT3_AM_04_00)) end,
            ["Great Bay Coast Pot Ledge 1"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Great Bay Coast Pot Ledge 2"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Great Bay Coast Pot Ledge 3"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Great Bay Coast Pot 01"] = function () return true end,
            ["Great Bay Coast Pot 02"] = function () return true end,
            ["Great Bay Coast Pot 03"] = function () return true end,
            ["Great Bay Coast Pot 04"] = function () return true end,
            ["Great Bay Coast Pot 05"] = function () return true end,
            ["Great Bay Coast Pot 06"] = function () return true end,
            ["Great Bay Coast Pot 07"] = function () return true end,
            ["Great Bay Coast Pot 08"] = function () return true end,
            ["Great Bay Coast Pot 09"] = function () return true end,
            ["Great Bay Coast Pot 10"] = function () return true end,
            ["Great Bay Coast Pot 11"] = function () return true end,
            ["Great Bay Coast Pot 12"] = function () return true end,
            ["Great Bay Coast Grass 1"] = function () return true end,
            ["Great Bay Coast Grass 2"] = function () return true end,
            ["Great Bay Coast Grass 3"] = function () return true end,
            ["Great Bay Coast Grass 4"] = function () return true end,
            ["Great Bay Coast Grass 5"] = function () return true end,
        },
    },
    ["Great Bay Coast Fortress"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return underwater_walking() end,
            ["Pirate Fortress"] = function () return true end,
        },
    },
    ["Great Bay Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["BUGS"] = function () return true end,
            ["FISH"] = function () return true end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Coast Fisherman Grotto"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 01"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 02"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 03"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 04"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 05"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 06"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 07"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 08"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 09"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 10"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 11"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 12"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 13"] = function () return true end,
            ["Great Bay Coast Fisherman Grotto Grass 14"] = function () return true end,
        },
    },
    ["GBC Near Cow Grotto"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
            ["Great Bay Cow Grotto"] = function () return true end,
        },
    },
    ["Great Bay Cow Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["GBC Near Cow Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Coast Cow Front"] = function () return can_play_epona() end,
            ["Great Bay Coast Cow Back"] = function () return can_play_epona() end,
            ["Great Bay Cow Grotto Grass 01"] = function () return true end,
            ["Great Bay Cow Grotto Grass 02"] = function () return true end,
            ["Great Bay Cow Grotto Grass 03"] = function () return true end,
            ["Great Bay Cow Grotto Grass 04"] = function () return true end,
            ["Great Bay Cow Grotto Grass 05"] = function () return true end,
            ["Great Bay Cow Grotto Grass 06"] = function () return true end,
            ["Great Bay Cow Grotto Grass 07"] = function () return true end,
            ["Great Bay Cow Grotto Grass 08"] = function () return true end,
            ["Great Bay Cow Grotto Grass 09"] = function () return true end,
            ["Great Bay Cow Grotto Grass 10"] = function () return true end,
            ["Great Bay Cow Grotto Grass 11"] = function () return true end,
            ["Great Bay Cow Grotto Grass 12"] = function () return true end,
            ["Great Bay Cow Grotto Grass 13"] = function () return true end,
            ["Great Bay Cow Grotto Grass 14"] = function () return true end,
            ["Great Bay Cow Grotto Grass 15"] = function () return true end,
            ["Great Bay Cow Grotto Grass 16"] = function () return true end,
            ["Great Bay Cow Grotto Grass 17"] = function () return true end,
            ["Great Bay Cow Grotto Grass 18"] = function () return true end,
            ["Great Bay Cow Grotto Grass 19"] = function () return true end,
            ["Great Bay Cow Grotto Grass 20"] = function () return true end,
            ["Great Bay Cow Grotto Grass 21"] = function () return true end,
            ["Great Bay Cow Grotto Grass 22"] = function () return true end,
            ["Great Bay Cow Grotto Grass 23"] = function () return true end,
            ["Great Bay Cow Grotto Grass 24"] = function () return true end,
            ["Great Bay Cow Grotto Grass 25"] = function () return true end,
            ["Great Bay Cow Grotto Grass 26"] = function () return true end,
            ["Great Bay Cow Grotto Grass 27"] = function () return true end,
            ["Great Bay Cow Grotto Grass 28"] = function () return true end,
            ["Great Bay Cow Grotto Grass 29"] = function () return true end,
            ["Great Bay Cow Grotto Grass 30"] = function () return true end,
            ["Great Bay Cow Grotto Grass 31"] = function () return true end,
            ["Great Bay Cow Grotto Grass 32"] = function () return true end,
            ["Great Bay Cow Grotto Grass 33"] = function () return true end,
            ["Great Bay Cow Grotto Grass 34"] = function () return true end,
            ["Great Bay Cow Grotto Grass 35"] = function () return true end,
            ["Great Bay Cow Grotto Grass 36"] = function () return true end,
            ["Great Bay Cow Grotto Grass 37"] = function () return true end,
            ["Great Bay Cow Grotto Grass 38"] = function () return true end,
            ["Great Bay Cow Grotto Grass 39"] = function () return true end,
            ["Great Bay Cow Grotto Grass 40"] = function () return true end,
            ["Great Bay Cow Grotto Grass 41"] = function () return true end,
            ["Great Bay Cow Grotto Grass 42"] = function () return true end,
            ["Great Bay Cow Grotto Grass 43"] = function () return true end,
            ["Great Bay Cow Grotto Grass 44"] = function () return true end,
            ["Great Bay Cow Grotto Grass 45"] = function () return true end,
            ["Great Bay Cow Grotto Grass 46"] = function () return true end,
            ["Great Bay Cow Grotto Grass 47"] = function () return true end,
            ["Great Bay Cow Grotto Grass 48"] = function () return true end,
            ["Great Bay Cow Grotto Grass 49"] = function () return true end,
            ["Great Bay Cow Grotto Grass 50"] = function () return true end,
            ["Great Bay Cow Grotto Grass 51"] = function () return true end,
            ["Great Bay Cow Grotto Grass 52"] = function () return true end,
            ["Great Bay Cow Grotto Grass 53"] = function () return true end,
            ["Great Bay Cow Grotto Grass 54"] = function () return true end,
            ["Great Bay Cow Grotto Grass 55"] = function () return true end,
            ["Great Bay Cow Grotto Grass 56"] = function () return true end,
            ["Great Bay Cow Grotto Grass 57"] = function () return true end,
            ["Great Bay Cow Grotto Grass 58"] = function () return true end,
            ["Great Bay Cow Grotto Grass 59"] = function () return true end,
            ["Great Bay Cow Grotto Grass 60"] = function () return true end,
            ["Great Bay Cow Grotto Grass 61"] = function () return true end,
            ["Great Bay Cow Grotto Grass 62"] = function () return true end,
            ["Great Bay Cow Grotto Grass 63"] = function () return true end,
            ["Great Bay Cow Grotto Grass 64"] = function () return true end,
            ["Great Bay Cow Grotto Grass 65"] = function () return true end,
            ["Great Bay Cow Grotto Grass 66"] = function () return true end,
            ["Great Bay Cow Grotto Grass 67"] = function () return true end,
            ["Great Bay Cow Grotto Grass 68"] = function () return true end,
            ["Great Bay Cow Grotto Grass 69"] = function () return true end,
            ["Great Bay Cow Grotto Grass 70"] = function () return true end,
            ["Great Bay Cow Grotto Grass 71"] = function () return true end,
            ["Great Bay Cow Grotto Grass 72"] = function () return true end,
        },
    },
    ["Fisher's Hut"] = {
        ["events"] = {
            ["SEAHORSE"] = function () return soul_chest_game_owner() and event('PHOTO_GERUDO') and has_bottle() end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Pinnacle Rock Entrance"] = {
        ["exits"] = {
            ["Pinnacle Rock"] = function () return underwater_walking_strict() and (event('SEAHORSE') or trick('MM_NO_SEAHORSE')) end,
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Pinnacle Rock"] = {
        ["events"] = {
            ["ZORA_EGGS_PINNACLE_ROCK"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["FISH"] = function () return true end,
        },
        ["exits"] = {
            ["Pinnacle Rock Entrance"] = function () return true end,
        },
        ["locations"] = {
            ["Pinnacle Rock Chest 1"] = function () return has_mask_zora() or can_hookshot_short() end,
            ["Pinnacle Rock Chest 2"] = function () return has_mask_zora() or can_hookshot_short() end,
            ["Pinnacle Rock HP"] = function () return soul_enemy(SOUL_ENEMY_DEEP_PYTHON) and event('SEAHORSE') and (has_mask_zora() or can_hookshot_short()) end,
            ["Pinnacle Rock Pot 01"] = function () return true end,
            ["Pinnacle Rock Pot 02"] = function () return true end,
            ["Pinnacle Rock Pot 03"] = function () return true end,
            ["Pinnacle Rock Pot 04"] = function () return has_mask_zora() or can_hookshot_short() end,
            ["Pinnacle Rock Pot 05"] = function () return has_mask_zora() or can_hookshot_short() end,
            ["Pinnacle Rock Pot 06"] = function () return has_mask_zora() or can_hookshot_short() end,
            ["Pinnacle Rock Pot 07"] = function () return has_mask_zora() or can_hookshot_short() end,
            ["Pinnacle Rock Pot 08"] = function () return has_mask_zora() or can_hookshot_short() end,
            ["Pinnacle Rock Pot 09"] = function () return true end,
            ["Pinnacle Rock Pot 10"] = function () return true end,
            ["Pinnacle Rock Pot 11"] = function () return true end,
        },
    },
    ["Laboratory"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Laboratory Zora Song"] = function () return soul_scientist() and has_all_zora_eggs() and has_mask_zora() and has_ocarina() end,
            ["Laboratory Fish HP"] = function () return has_fish() end,
        },
    },
    ["Zora Cape"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return (can_fight() or has_explosives() or has_arrows()) and is_night() and soul_like_like() end,
            ["FISH"] = function () return true end,
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
            ["Zora Cape Near Hall"] = function () return underwater_walking() or (can_dive_small() and trick('MM_ZORA_HALL_HUMAN')) end,
            ["Zora Cape Peninsula"] = function () return underwater_walking() or can_use_nayru() or trick('MM_ZORA_HALL_HUMAN') end,
            ["Waterfall Cliffs"] = function () return can_hookshot() end,
            ["Great Bay Near Fairy Fountain"] = function () return can_hookshot() and (has_explosives() or trick_keg_explosives() or short_hook_anywhere()) end,
            ["Zora Cape Grotto"] = function () return can_break_boulders() end,
            ["Zora Cape Pot Game"] = function () return soul_zora() and is_day() and (has_weapon() or has_mask_zora() or can_hookshot_short() or has_bow()) end,
        },
        ["locations"] = {
            ["Zora Cape Underwater Chest"] = function () return underwater_walking() end,
            ["Zora Cape Waterfall HP"] = function () return has_mask_zora() or (has_iron_boots() and has_tunic_zora() and (has_arrows() or has_bombchu() or has_mask_blast())) end,
            ["Zora Cape Pot Near Beavers 1"] = function () return true end,
            ["Zora Cape Pot Near Beavers 2"] = function () return true end,
        },
    },
    ["Zora Cape Pot Game"] = {
        ["locations"] = {
            ["Zora Cape Pot Game 1"] = function () return true end,
            ["Zora Cape Pot Game 2"] = function () return true end,
            ["Zora Cape Pot Game 3"] = function () return true end,
            ["Zora Cape Pot Game 4"] = function () return true end,
            ["Zora Cape Pot Game 5"] = function () return true end,
        },
    },
    ["Zora Cape Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
        },
        ["exits"] = {
            ["Zora Cape"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Cape Grotto"] = function () return true end,
            ["Zora Cape Grotto Grass 01"] = function () return true end,
            ["Zora Cape Grotto Grass 02"] = function () return true end,
            ["Zora Cape Grotto Grass 03"] = function () return true end,
            ["Zora Cape Grotto Grass 04"] = function () return true end,
            ["Zora Cape Grotto Grass 05"] = function () return true end,
            ["Zora Cape Grotto Grass 06"] = function () return true end,
            ["Zora Cape Grotto Grass 07"] = function () return true end,
            ["Zora Cape Grotto Grass 08"] = function () return true end,
            ["Zora Cape Grotto Grass 09"] = function () return true end,
            ["Zora Cape Grotto Grass 10"] = function () return true end,
            ["Zora Cape Grotto Grass 11"] = function () return true end,
            ["Zora Cape Grotto Grass 12"] = function () return true end,
            ["Zora Cape Grotto Grass 13"] = function () return true end,
            ["Zora Cape Grotto Grass 14"] = function () return true end,
        },
    },
    ["Great Bay Near Fairy Fountain"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return has_explosives() or trick_keg_explosives() or (not setting('erIndoorsMajor')) end,
            ["Great Bay Fairy Fountain"] = function () return true end,
        },
    },
    ["Great Bay Fairy Fountain"] = {
        ["exits"] = {
            ["Great Bay Near Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Great Fairy"] = function () return has('STRAY_FAIRY_GB', 15) end,
        },
    },
    ["Waterfall Cliffs"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return true end,
            ["Waterfall Rapids"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Cape Ledge Chest 1"] = function () return can_hookshot() end,
            ["Zora Cape Ledge Chest 2"] = function () return can_hookshot() end,
        },
    },
    ["Waterfall Rapids"] = {
        ["exits"] = {
            ["Waterfall Cliffs"] = function () return true end,
        },
        ["locations"] = {
            ["Waterfall Rapids Beaver Race 1"] = function () return has_mask_zora() end,
            ["Waterfall Rapids Beaver Race 2"] = function () return has_mask_zora() end,
        },
    },
    ["Zora Cape Near Hall"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return underwater_walking() or (can_dive_small() and trick('MM_ZORA_HALL_HUMAN')) end,
            ["Zora Hall Entrance"] = function () return underwater_walking() or can_dive_small() end,
        },
    },
    ["Zora Hall Entrance"] = {
        ["exits"] = {
            ["Zora Cape Near Hall"] = function () return underwater_walking() or can_dive_small() end,
            ["Zora Hall"] = function () return true end,
        },
    },
    ["Zora Hall"] = {
        ["exits"] = {
            ["Zora Hall Entrance"] = function () return true end,
            ["Zora Cape Peninsula"] = function () return true end,
            ["Zora Shop"] = function () return true end,
            ["Tijo's Room"] = function () return can_enter_zora_door() end,
            ["Japas' Room"] = function () return can_enter_zora_door() end,
            ["Evan's Room"] = function () return can_enter_zora_door() end,
            ["Lulu's Room"] = function () return can_enter_zora_door() end,
        },
        ["locations"] = {
            ["Zora Hall Scene Lights"] = function () return soul_zora() and (can_use_fire_arrows() or (trick('MM_STAGE_LIGHTS_DIN') and has_arrows() and can_use_din() and can_hookshot())) end,
        },
    },
    ["Zora Shop"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Shop Item 1"] = function () return soul_zora_shopkeeper() and shop_price(19) end,
            ["Zora Shop Item 2"] = function () return soul_zora_shopkeeper() and shop_price(20) end,
            ["Zora Shop Item 3"] = function () return soul_zora_shopkeeper() and shop_price(21) end,
        },
    },
    ["Tijo's Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
    },
    ["Japas' Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
    },
    ["Evan's Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Hall Evan HP"] = function () return soul_npc(SOUL_NPC_ZORA_MUSICIANS) and can_play_evan() and (is_ocean_cursed() or (trick('MM_EVAN_FARORE') and can_use_farore())) end,
        },
    },
    ["Lulu's Room"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Hall Scrub HP"] = function () return trick('MM_ZORA_HALL_SCRUB_HP_NO_DEKU') and (has_mask_goron() or is_tall()) or (has_mask_goron() and has('MASK_DEKU') and has('DEED_MOUNTAIN')) or short_hook_anywhere() end,
            ["Zora Hall Scrub Shop"] = function () return soul_business_scrub() and has_mask_zora() and can_use_wallet(1) end,
            ["Zora Hall Scrub Deed"] = function () return soul_business_scrub() and has('DEED_MOUNTAIN') and has_mask_goron() end,
        },
    },
    ["Zora Cape Peninsula"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return underwater_walking() or can_use_nayru() or trick('MM_ZORA_HALL_HUMAN') end,
            ["Zora Hall"] = function () return true end,
            ["Great Bay Temple"] = function () return turtle_woken() and can_hookshot() end,
            ["Owl Zora Cape"] = function () return true end,
        },
    },
    ["Behind Gorman Fence"] = {
        ["exits"] = {
            ["Milk Road"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or final_day() or short_hook_anywhere() end,
            ["Gorman Track Back"] = function () return true end,
        },
    },
    ["Gorman Track Front"] = {
        ["exits"] = {
            ["Milk Road"] = function () return true end,
            ["Gorman Track"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Gorman Track Garo Mask"] = function () return soul_gorman() and can_play_epona() and can_use_wallet(1) and is_day() end,
            ["Gorman Track Milk Purchase"] = function () return soul_gorman() and can_use_wallet(1) and is_day() end,
        },
    },
    ["Gorman Track Back"] = {
        ["exits"] = {
            ["Behind Gorman Fence"] = function () return true end,
            ["Gorman Track"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or short_hook_anywhere() end,
        },
    },
    ["Gorman Track"] = {
        ["exits"] = {
            ["Gorman Track Front"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or short_hook_anywhere() end,
            ["Gorman Track Back"] = function () return can_goron_bomb_jump() and has_bombs() or (is_night2() and event('ALIENS')) or short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Gorman Track Grass Pack 1 Grass 01"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 02"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 03"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 04"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 05"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 06"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 07"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 08"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 09"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 10"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 11"] = function () return true end,
            ["Gorman Track Grass Pack 1 Grass 12"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 01"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 02"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 03"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 04"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 05"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 06"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 07"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 08"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 09"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 10"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 11"] = function () return true end,
            ["Gorman Track Grass Pack 2 Grass 12"] = function () return true end,
        },
    },
    ["Road to Ikana Front"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() and soul_bubble() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Road to Ikana Grotto"] = function () return has_mask_goron() end,
            ["Road to Ikana Center"] = function () return can_play_epona() or short_hook_anywhere() or (can_goron_bomb_jump() and has_bombs()) end,
        },
        ["locations"] = {
            ["Road to Ikana Chest"] = function () return can_hookshot() or (can_hookshot_short() and trick('MM_HARD_HOOKSHOT')) end,
        },
    },
    ["Road to Ikana Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
        },
        ["exits"] = {
            ["Road to Ikana Front"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Ikana Grotto"] = function () return true end,
            ["Road to Ikana Grotto Grass 01"] = function () return true end,
            ["Road to Ikana Grotto Grass 02"] = function () return true end,
            ["Road to Ikana Grotto Grass 03"] = function () return true end,
            ["Road to Ikana Grotto Grass 04"] = function () return true end,
            ["Road to Ikana Grotto Grass 05"] = function () return true end,
            ["Road to Ikana Grotto Grass 06"] = function () return true end,
            ["Road to Ikana Grotto Grass 07"] = function () return true end,
            ["Road to Ikana Grotto Grass 08"] = function () return true end,
            ["Road to Ikana Grotto Grass 09"] = function () return true end,
            ["Road to Ikana Grotto Grass 10"] = function () return true end,
            ["Road to Ikana Grotto Grass 11"] = function () return true end,
            ["Road to Ikana Grotto Grass 12"] = function () return true end,
            ["Road to Ikana Grotto Grass 13"] = function () return true end,
            ["Road to Ikana Grotto Grass 14"] = function () return true end,
        },
    },
    ["Road to Ikana Center"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() and soul_bubble() end,
            ["FAIRY"] = function () return can_get_gossip_fairy() or scarecrow_hookshot() or short_hook_anywhere() end,
        },
        ["exits"] = {
            ["Road to Ikana Front"] = function () return can_play_epona() or short_hook_anywhere() or (can_goron_bomb_jump() and has_bombs()) end,
            ["Road to Ikana Top"] = function () return soul_poe_collector() and (has('MASK_GARO') or has('MASK_GIBDO')) and (can_hookshot() or (can_hookshot_short() and (trick('MM_HARD_HOOKSHOT') or is_adult()))) or short_hook_anywhere() end,
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Ikana Stone Mask"] = function () return can_use_lens_strict() and has_red_or_blue_potion() end,
            ["Road to Ikana Pot"] = function () return scarecrow_hookshot() or short_hook_anywhere() end,
        },
    },
    ["Ikana Graveyard"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Road to Ikana Center"] = function () return true end,
            ["Ikana Graveyard Grotto"] = function () return has_explosives() or trick_keg_explosives() end,
            ["Beneath The Graveyard Night 1"] = function () return soul_stalchild() and has('MASK_CAPTAIN') and is_night1() end,
            ["Beneath The Graveyard Night 2"] = function () return soul_stalchild() and has('MASK_CAPTAIN') and is_night2() end,
            ["Beneath The Graveyard Night 3"] = function () return soul_stalchild() and has('MASK_CAPTAIN') and is_night3() end,
        },
        ["locations"] = {
            ["Ikana Graveyard Captain Mask"] = function () return soul_enemy(SOUL_ENEMY_CAPTAIN_KEETA) and can_play_awakening() and has_arrows() and can_fight() end,
            ["Ikana Graveyard Grass 1"] = function () return true end,
            ["Ikana Graveyard Grass 2"] = function () return true end,
            ["Ikana Graveyard Grass 3"] = function () return true end,
            ["Ikana Graveyard Grass 4"] = function () return true end,
            ["Ikana Graveyard Grass 5"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 1"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 2"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 3"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 4"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 5"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 6"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 7"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 8"] = function () return true end,
            ["Ikana Graveyard Grass Pack Grass 9"] = function () return true end,
        },
    },
    ["Ikana Graveyard Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Graveyard Grotto"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 01"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 02"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 03"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 04"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 05"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 06"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 07"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 08"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 09"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 10"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 11"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 12"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 13"] = function () return true end,
            ["Ikana Graveyard Grotto Grass 14"] = function () return true end,
        },
    },
    ["Beneath The Graveyard Night 1"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
            ["Beneath The Graveyard Night 1/2 Exchange"] = function () return short_hook_anywhere() or has_hover_boots() end,
        },
        ["locations"] = {
            ["Beneath The Graveyard Chest"] = function () return soul_enemy(SOUL_ENEMY_BAD_BAT) and (can_fight() or has_explosives() or has_arrows() or can_hookshot_short() or has('MASK_DEKU')) end,
            ["Beneath The Graveyard Song of Storms"] = function () return soul_composer_bros() and soul_iron_knuckle() and (has_weapon() or has_mask_goron() or has_explosives()) and has_fire_sticks() end,
            ["Beneath The Graveyard Pot Night 1 Early 1"] = function () return true end,
            ["Beneath The Graveyard Pot Night 1 Early 2"] = function () return true end,
            ["Beneath The Graveyard Pot Night 1 Bats 1"] = function () return true end,
            ["Beneath The Graveyard Pot Night 1 Bats 2"] = function () return true end,
            ["Beneath The Graveyard Pot Night 1 Bats 3"] = function () return true end,
        },
    },
    ["Beneath The Graveyard Night 1/2 Exchange"] = {
        ["exits"] = {
            ["Beneath The Graveyard Night 1"] = function () return true end,
            ["Beneath The Graveyard Night 2"] = function () return true end,
        },
    },
    ["Beneath The Graveyard Night 2"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
            ["Beneath The Graveyard Night 1/2 Exchange"] = function () return short_hook_anywhere() or has_hover_boots() end,
        },
        ["locations"] = {
            ["Beneath The Graveyard HP"] = function () return soul_iron_knuckle() and (has_explosives() or trick_keg_explosives()) and (can_use_lens() or short_hook_anywhere()) end,
            ["Beneath The Graveyard Pot Night 2 Early"] = function () return true end,
            ["Beneath The Graveyard Pot Night 2 Before Pit 1"] = function () return can_use_lens() end,
            ["Beneath The Graveyard Pot Night 2 Before Pit 2"] = function () return can_use_lens() end,
            ["Beneath The Graveyard Pot Night 2 After Pit 1"] = function () return can_use_lens() or short_hook_anywhere() end,
            ["Beneath The Graveyard Pot Night 2 After Pit 2"] = function () return can_use_lens() or short_hook_anywhere() end,
            ["Beneath The Graveyard Pot Night 2 After Pit 3"] = function () return can_use_lens() or short_hook_anywhere() end,
            ["Beneath The Graveyard Pot Night 2 After Pit 4"] = function () return can_use_lens() or short_hook_anywhere() end,
            ["Beneath The Graveyard Rupee 1"] = function () return true end,
            ["Beneath The Graveyard Rupee 2"] = function () return true end,
            ["Beneath The Graveyard Rupee 3"] = function () return true end,
            ["Beneath The Graveyard Rupee 4"] = function () return true end,
            ["Beneath The Graveyard Rupee 5"] = function () return true end,
            ["Beneath The Graveyard Rupee 6"] = function () return true end,
            ["Beneath The Graveyard Rupee 7"] = function () return true end,
        },
    },
    ["Beneath The Graveyard Night 3 Fake Exit"] = {
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
    },
    ["Beneath The Graveyard Night 3"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return (can_fight() or has_weapon_range() or has_explosives()) and soul_wallmaster() end,
            ["DAMPE_BIG_POE"] = function () return soul_dampe() and has_weapon_range() and is_night3() end,
        },
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
            ["Beneath The Graveyard Night 3 Wallmaster"] = function () return soul_wallmaster() end,
        },
        ["locations"] = {
            ["Beneath The Graveyard Dampe Chest"] = function () return has_weapon_range() and is_night3() and soul_dampe() end,
            ["Beneath The Graveyard Pot Dampe 01"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 02"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 03"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 04"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 05"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 06"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 07"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 08"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 09"] = function () return true end,
            ["Beneath The Graveyard Pot Dampe 10"] = function () return true end,
        },
    },
    ["Beneath The Graveyard Night 3 Wallmaster"] = {
        ["exits"] = {
            ["VOID"] = function () return true end,
        },
    },
    ["Road to Ikana Top"] = {
        ["events"] = {
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() and soul_bubble() end,
        },
        ["exits"] = {
            ["Road to Ikana Center"] = function () return true end,
            ["Ikana Valley"] = function () return true end,
        },
    },
    ["Ikana Valley"] = {
        ["events"] = {
            ["FAIRY"] = function () return can_get_gossip_fairy() end,
        },
        ["exits"] = {
            ["Road to Ikana Top"] = function () return true end,
            ["Ikana Canyon"] = function () return (can_use_ice_arrows() and soul_octorok() or trick('MM_ICELESS_IKANA')) and can_hookshot() or short_hook_anywhere() end,
            ["Secret Shrine"] = function () return true end,
            ["Sakon Hideout"] = function () return event('MEET_KAFEI') and at(NIGHT3_PM_06_00) end,
            ["Ikana Valley Grotto"] = function () return true end,
            ["Swamp Front"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Valley Scrub Rupee"] = function () return soul_business_scrub() and has('DEED_OCEAN') and has_mask_zora() end,
            ["Ikana Valley Scrub HP"] = function () return has('DEED_OCEAN') and has_mask_zora() and has('MASK_DEKU') or hookshot_anywhere() end,
            ["Ikana Valley Scrub Shop"] = function () return soul_business_scrub() and can_use_wallet(2) end,
        },
    },
    ["Ikana Valley Grotto"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["STICKS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_sticks()) end,
            ["NUTS"] = function () return soul_deku_baba() and (can_lift_bracelet() or can_kill_baba_nuts()) end,
            ["FISH"] = function () return true end,
            ["BUGS"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Valley Grotto"] = function () return true end,
            ["Ikana Valley Grotto Grass 01"] = function () return true end,
            ["Ikana Valley Grotto Grass 02"] = function () return true end,
            ["Ikana Valley Grotto Grass 03"] = function () return true end,
            ["Ikana Valley Grotto Grass 04"] = function () return true end,
            ["Ikana Valley Grotto Grass 05"] = function () return true end,
            ["Ikana Valley Grotto Grass 06"] = function () return true end,
            ["Ikana Valley Grotto Grass 07"] = function () return true end,
            ["Ikana Valley Grotto Grass 08"] = function () return true end,
            ["Ikana Valley Grotto Grass 09"] = function () return true end,
            ["Ikana Valley Grotto Grass 10"] = function () return true end,
            ["Ikana Valley Grotto Grass 11"] = function () return true end,
            ["Ikana Valley Grotto Grass 12"] = function () return true end,
            ["Ikana Valley Grotto Grass 13"] = function () return true end,
            ["Ikana Valley Grotto Grass 14"] = function () return true end,
        },
    },
    ["Sakon Hideout"] = {
        ["events"] = {
            ["SUN_MASK"] = function () return (can_fight() or has_explosives() or has_arrows()) and soul_deku_baba() and soul_wolfos() end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
        },
        ["locations"] = {
            ["Sakon Hideout Pot First Room 1"] = function () return true end,
            ["Sakon Hideout Pot First Room 2"] = function () return true end,
            ["Sakon Hideout Pot Second Room 1"] = function () return soul_deku_baba() end,
            ["Sakon Hideout Pot Second Room 2"] = function () return soul_deku_baba() end,
            ["Sakon Hideout Pot Third Room"] = function () return soul_deku_baba() end,
        },
    },
    ["Ikana Canyon"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return can_use_light_arrows() and is_night() and soul_bubble() end,
            ["FAIRY"] = function () return true end,
            ["PICTURE_TINGLE"] = function () return soul_npc(SOUL_NPC_TINGLE) and has('PICTOGRAPH_BOX') end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
            ["Ikana Fairy Fountain"] = function () return true end,
            ["Ikana Spring Water Cave"] = function () return true end,
            ["Music Box House"] = function () return event('IKANA_CURSE_LIFTED') and (has_explosives() or has_mask_stone()) or is_valley_cleared() end,
            ["Ghost Hut"] = function () return true end,
            ["Beneath The Well Entrance"] = function () return true end,
            ["Ikana Castle Entrance"] = function () return true end,
            ["Stone Tower"] = function () return true end,
            ["Tingle Ikana"] = function () return soul_npc(SOUL_NPC_TINGLE) and has_weapon_range() end,
            ["Owl Ikana"] = function () return true end,
        },
    },
    ["Ikana Fairy Fountain"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Great Fairy"] = function () return has('STRAY_FAIRY_ST', 15) end,
        },
    },
    ["Ikana Spring Water Cave"] = {
        ["events"] = {
            ["IKANA_CURSE_LIFTED"] = function () return soul_composer_bros() and is_valley_cursed() and can_play_storms() end,
        },
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
    },
    ["Music Box House"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Music Box House Gibdo Mask"] = function () return is_valley_cursed() and can_play_healing() end,
        },
    },
    ["Ghost Hut"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Ghost Hut HP"] = function () return soul_poe_collector() and (has_arrows() or can_hookshot_short() or can_use_deku_bubble()) and can_use_wallet(1) and is_valley_cursed() end,
        },
    },
    ["Ikana Castle Entrance"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT_ENTRANCE"] = function () return can_activate_crystal() end,
        },
        ["exits"] = {
            ["Ikana Castle Exterior"] = function () return has_mirror_shield() and event('IKANA_CASTLE_LIGHT_ENTRANCE') or can_use_light_arrows() or short_hook_anywhere() end,
            ["Ikana Canyon"] = function () return true end,
        },
    },
    ["Ikana Castle Exterior"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Beneath The Well End"] = function () return true end,
            ["Ikana Castle Entrance"] = function () return can_use_light_arrows() or short_hook_anywhere() end,
            ["Ancient Castle of Ikana"] = function () return true end,
            ["Ancient Castle of Ikana Roof Exterior"] = function () return short_hook_anywhere() end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana Pot Exterior"] = function () return true end,
            ["Ancient Castle of Ikana Grass 01"] = function () return true end,
            ["Ancient Castle of Ikana Grass 02"] = function () return true end,
            ["Ancient Castle of Ikana Grass 03"] = function () return true end,
            ["Ancient Castle of Ikana Grass 04"] = function () return true end,
            ["Ancient Castle of Ikana Grass 05"] = function () return true end,
            ["Ancient Castle of Ikana Grass 06"] = function () return true end,
            ["Ancient Castle of Ikana Grass 07"] = function () return true end,
            ["Ancient Castle of Ikana Grass 08"] = function () return true end,
            ["Ancient Castle of Ikana Grass 09"] = function () return true end,
            ["Ancient Castle of Ikana Grass 10"] = function () return true end,
            ["Ancient Castle of Ikana Grass 11"] = function () return true end,
            ["Ancient Castle of Ikana Grass 12"] = function () return true end,
        },
    },
    ["Stone Tower"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
            ["Stone Tower Top"] = function () return (can_use_elegy3() or (can_use_elegy2() and trick('MM_ONE_MASK_STONE_TOWER'))) and can_hookshot() or (can_use_elegy3() and short_hook_anywhere() and trick('MM_OOB_MOVEMENT')) or hookshot_anywhere() or (setting('openDungeonsMm', 'ST') and (can_hookshot() or (short_hook_anywhere() and trick('MM_OOB_MOVEMENT')))) end,
            ["Stone Tower Lower Scarecrow Ledge"] = function () return (can_use_elegy3() or (can_use_elegy2() and trick('MM_ONE_MASK_STONE_TOWER'))) and scarecrow_hookshot() or hookshot_anywhere() end,
            ["Stone Tower Upper Scarecrow Ledge"] = function () return (can_use_elegy3() or (can_use_elegy2() and trick('MM_ONE_MASK_STONE_TOWER'))) and can_hookshot() or (can_use_elegy3() and short_hook_anywhere()) or hookshot_anywhere() end,
        },
        ["locations"] = {
            ["Stone Tower Pot Climb 1"] = function () return can_hookshot_short() end,
            ["Stone Tower Pot Climb 2"] = function () return can_hookshot_short() end,
        },
    },
    ["Stone Tower Top"] = {
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
            ["Stone Tower Front of Temple"] = function () return can_use_elegy() or (short_hook_anywhere() and trick('MM_OOB_MOVEMENT')) or hookshot_anywhere() or setting('openDungeonsMm', 'ST') end,
            ["Stone Tower Top Inverted"] = function () return can_use_elegy() and can_use_light_arrows() or setting('openDungeonsMm', 'ST') end,
            ["Stone Tower Lower Scarecrow Ledge"] = function () return has_mask_goron() or scarecrow_hookshot() or hookshot_anywhere() end,
            ["Stone Tower Upper Scarecrow Ledge"] = function () return scarecrow_hookshot() or short_hook_anywhere() or (has_hover_boots() and has_weapon()) end,
            ["Owl Stone Tower"] = function () return true end,
        },
    },
    ["Stone Tower Front of Temple"] = {
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
            ["Stone Tower Top"] = function () return can_use_elegy3() or (can_use_elegy2() and trick('MM_ONE_MASK_STONE_TOWER') and short_hook_anywhere()) or can_hookshot() or setting('openDungeonsMm', 'ST') end,
            ["Stone Tower Top Inverted"] = function () return can_use_elegy() and can_use_light_arrows() or setting('openDungeonsMm', 'ST') end,
            ["Stone Tower Temple"] = function () return true end,
            ["Stone Tower Lower Scarecrow Ledge"] = function () return has_mask_goron() or is_tall() or scarecrow_hookshot() or hookshot_anywhere() or has_hover_boots() or (short_hook_anywhere() and trick('MM_OOB_MOVEMENT')) end,
            ["Stone Tower Upper Scarecrow Ledge"] = function () return scarecrow_hookshot() or short_hook_anywhere() end,
        },
    },
    ["Stone Tower Lower Scarecrow Ledge"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["FAIRY"] = function () return true end,
            ["RUPEES"] = function () return can_use_light_arrows() and soul_keese() or (can_fight() and soul_redead_gibdo()) end,
        },
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Pot Lower Scarecrow 01"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 02"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 03"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 04"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 05"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 06"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 07"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 08"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 09"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 10"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 11"] = function () return true end,
            ["Stone Tower Pot Lower Scarecrow 12"] = function () return true end,
        },
    },
    ["Stone Tower Upper Scarecrow Ledge"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
            ["Stone Tower Front of Temple"] = function () return short_hook_anywhere() and trick('MM_OOB_MOVEMENT') end,
        },
        ["locations"] = {
            ["Stone Tower Pot Higher Scarecrow 1"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 2"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 3"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 4"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 5"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 6"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 7"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 8"] = function () return true end,
            ["Stone Tower Pot Higher Scarecrow 9"] = function () return true end,
        },
    },
    ["Stone Tower Top Inverted"] = {
        ["events"] = {
            ["BUGS"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted"] = function () return true end,
            ["Stone Tower Top"] = function () return can_use_light_arrows() or setting('openDungeonsMm', 'ST') end,
            ["Stone Tower Top Inverted Upper"] = function () return can_use_beans() or hookshot_anywhere() end,
        },
    },
    ["Stone Tower Top Inverted Upper"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Top Inverted"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Inverted Chest 1"] = function () return true end,
            ["Stone Tower Inverted Chest 2"] = function () return true end,
            ["Stone Tower Inverted Chest 3"] = function () return true end,
            ["Stone Tower Inverted Pot 1"] = function () return true end,
            ["Stone Tower Inverted Pot 2"] = function () return true end,
            ["Stone Tower Inverted Pot 3"] = function () return true end,
            ["Stone Tower Inverted Pot 4"] = function () return true end,
            ["Stone Tower Inverted Pot 5"] = function () return true end,
        },
    },
    ["Pirate Fortress"] = {
        ["exits"] = {
            ["Great Bay Coast Fortress"] = function () return underwater_walking() or can_dive_small() end,
            ["Pirate Fortress Entrance"] = function () return can_reset_time_dungeon() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Entrance"] = {
        ["events"] = {
            ["PHOTO_GERUDO"] = function () return has('PICTOGRAPH_BOX') end,
        },
        ["exits"] = {
            ["Pirate Fortress"] = function () return true end,
            ["Pirate Fortress Sewers"] = function () return underwater_walking() and has_mask_goron() end,
            ["Pirate Fortress Entrance Balcony"] = function () return can_hookshot() or (can_hookshot_short() and trick('MM_PFI_BOAT_HOOK')) end,
            ["Pirate Fortress Entrance Lookout"] = function () return can_hookshot_short() and trick('MM_PFI_BOAT_HOOK') end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Entrance Chest 1"] = function () return underwater_walking() end,
            ["Pirate Fortress Entrance Chest 2"] = function () return underwater_walking() end,
            ["Pirate Fortress Entrance Chest 3"] = function () return underwater_walking() end,
        },
    },
    ["Pirate Fortress Entrance Balcony"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers End"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Sewers"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers Cage Room"] = function () return has_mask_zora() or (underwater_walking_strict() and can_lift_silver()) end,
            ["SOARING"] = function () return underwater_walking() and can_play_soaring() end,
            ["WARP_SONGS"] = function () return underwater_walking() end,
        },
        ["locations"] = {
            ["Pirate Fortress Sewers Chest 1"] = function () return underwater_walking_strict() end,
        },
    },
    ["Pirate Fortress Sewers Cage Room"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers"] = function () return has_mask_zora() or (underwater_walking_strict() and can_lift_silver()) end,
            ["Pirate Fortress Sewers After Gate"] = function () return has_weapon_range() or (has_hover_boots() and can_activate_crystal()) end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Sewers Chest 2"] = function () return underwater_walking() end,
            ["Pirate Fortress Sewers Chest 3"] = function () return underwater_walking() end,
            ["Pirate Fortress Sewers HP"] = function () return true end,
            ["Pirate Fortress Sewers Pot Heart Piece Room 1"] = function () return true end,
            ["Pirate Fortress Sewers Pot Heart Piece Room 2"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Near Cage 1"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Near Cage 2"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Near Cage 3"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Near Cage 4"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Cage"] = function () return true end,
        },
    },
    ["Pirate Fortress Sewers After Gate"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers End"] = function () return has_weapon_range() or has_bombs() or has_bombchu() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Sewers Pot Waterway 1"] = function () return true end,
            ["Pirate Fortress Sewers Pot Waterway 2"] = function () return true end,
        },
    },
    ["Pirate Fortress Sewers End"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Entrance Balcony"] = function () return has_weapon_range() or (has_hover_boots() and can_activate_crystal()) end,
            ["Pirate Fortress Sewers After Gate"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Sewers Pot End 1"] = function () return true end,
            ["Pirate Fortress Sewers Pot End 2"] = function () return true end,
            ["Pirate Fortress Sewers Pot End 3"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Water Elevator 1"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Water Elevator 2"] = function () return true end,
            ["Pirate Fortress Sewers Rupee Water Elevator 3"] = function () return true end,
        },
    },
    ["Pirate Fortress Interior"] = {
        ["events"] = {
            ["RUPEES"] = function () return has_weapon_range() or has_explosives() or has_weapon() end,
        },
        ["exits"] = {
            ["Pirate Fortress Entrance Balcony"] = function () return true end,
            ["Pirate Fortress Hookshot Room Upper"] = function () return can_evade_gerudo() end,
            ["Pirate Fortress Hookshot Room Lower"] = function () return true end,
            ["Pirate Fortress Lone Guard Entry"] = function () return can_hookshot_short() end,
            ["Pirate Fortress Barrel Maze Entry"] = function () return can_hookshot_short() end,
            ["Pirate Fortress Lone Guard Exit"] = function () return short_hook_anywhere() end,
            ["Pirate Fortress Barrel Maze Exit"] = function () return short_hook_anywhere() or (can_hookshot() and has_hover_boots()) end,
            ["Pirate Fortress Treasure Room Exit"] = function () return short_hook_anywhere() or has_hover_boots() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Lower Chest"] = function () return true end,
            ["Pirate Fortress Interior Upper Chest"] = function () return can_hookshot() or short_hook_anywhere() or (has_mask_goron() and trick('MM_OOB_MOVEMENT')) end,
            ["Pirate Fortress Interior Heart 1"] = function () return can_hookshot() or short_hook_anywhere() or has_hover_boots() end,
            ["Pirate Fortress Interior Heart 2"] = function () return can_hookshot() or short_hook_anywhere() or has_hover_boots() end,
            ["Pirate Fortress Interior Heart 3"] = function () return can_hookshot() or short_hook_anywhere() or has_hover_boots() end,
        },
    },
    ["Pirate Fortress Hookshot Room Upper"] = {
        ["events"] = {
            ["FORTRESS_BEEHIVE"] = function () return has_arrows() or can_use_deku_bubble() end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Pot Beehive 1"] = function () return true end,
            ["Pirate Fortress Interior Pot Beehive 2"] = function () return true end,
        },
    },
    ["Pirate Fortress Hookshot Room Lower"] = {
        ["events"] = {
            ["FORTRESS_BEEHIVE"] = function () return has_mask_stone() and can_hookshot_short() and (has_arrows() or can_use_deku_bubble()) end,
            ["ZORA_EGGS_HOOKSHOT_ROOM"] = function () return can_hookshot_short() and underwater_walking() and event('FORTRESS_BEEHIVE') end,
        },
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Hookshot"] = function () return event('FORTRESS_BEEHIVE') end,
        },
    },
    ["Pirate Fortress Barrel Maze Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["Pirate Fortress Entrance Lookout"] = function () return true end,
            ["Pirate Fortress Barrel Maze"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Entrance Lookout"] = {
        ["exits"] = {
            ["Pirate Fortress Barrel Maze Entry"] = function () return true end,
            ["Pirate Fortress Entrance"] = function () return true end,
        },
    },
    ["Pirate Fortress Barrel Maze"] = {
        ["exits"] = {
            ["Pirate Fortress Barrel Maze Entry"] = function () return true end,
            ["Pirate Fortress Barrel Maze Aquarium"] = function () return can_fight() and can_evade_gerudo() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Barrel Maze Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_BARREL_MAZE"] = function () return can_hookshot_short() and underwater_walking() end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Barrel Maze"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Barrel Maze Exit"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Pot Barrel Maze 1"] = function () return true end,
            ["Pirate Fortress Interior Pot Barrel Maze 2"] = function () return true end,
            ["Pirate Fortress Interior Pot Barrel Maze 3"] = function () return true end,
        },
    },
    ["Pirate Fortress Barrel Maze Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Barrel Maze Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["Pirate Fortress Lone Guard"] = function () return true end,
            ["Pirate Fortress Treasure Room Entry"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard"] = {
        ["exits"] = {
            ["Pirate Fortress Lone Guard Aquarium"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Lone Guard Entry"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_LONE_GUARD"] = function () return can_hookshot_short() and underwater_walking() end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Lone Guard"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Lone Guard Exit"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Aquarium"] = function () return underwater_walking() and can_hookshot_short() end,
            ["Pirate Fortress Interior Pot Chest Aquarium 1"] = function () return true end,
            ["Pirate Fortress Interior Pot Chest Aquarium 2"] = function () return true end,
            ["Pirate Fortress Interior Pot Chest Aquarium 3"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Lone Guard Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room"] = {
        ["exits"] = {
            ["Pirate Fortress Treasure Room Aquarium"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room Entry"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Silver Rupee Chest"] = function () return can_evade_gerudo() end,
        },
    },
    ["Pirate Fortress Treasure Room Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_TREASURE_ROOM"] = function () return can_hookshot_short() and underwater_walking() end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Pirate Fortress Treasure Room"] = function () return can_fight() and can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room Exit"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Pot Guarded 1"] = function () return true end,
            ["Pirate Fortress Interior Pot Guarded 2"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Treasure Room Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Secret Shrine"] = {
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
            ["Secret Shrine Entrance"] = function () return can_reset_time_dungeon() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Secret Shrine Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["NUTS"] = function () return true end,
            ["WATER"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Secret Shrine Main"] = function () return can_use_light_arrows() end,
            ["Secret Shrine Rupees"] = function () return can_use_beans() or has_mask_zora() or hookshot_anywhere() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Grass Entrance 1"] = function () return true end,
            ["Secret Shrine Grass Entrance 2"] = function () return true end,
            ["Secret Shrine Grass Entrance 3"] = function () return true end,
            ["Secret Shrine Grass Entrance 4"] = function () return true end,
            ["Secret Shrine Grass Entrance 5"] = function () return true end,
            ["Secret Shrine Grass Entrance 6"] = function () return true end,
        },
    },
    ["Secret Shrine Rupees"] = {
        ["locations"] = {
            ["Secret Shrine Rupee 01"] = function () return true end,
            ["Secret Shrine Rupee 02"] = function () return true end,
            ["Secret Shrine Rupee 03"] = function () return true end,
            ["Secret Shrine Rupee 04"] = function () return true end,
            ["Secret Shrine Rupee 05"] = function () return true end,
            ["Secret Shrine Rupee 06"] = function () return true end,
            ["Secret Shrine Rupee 07"] = function () return true end,
            ["Secret Shrine Rupee 08"] = function () return true end,
            ["Secret Shrine Rupee 09"] = function () return true end,
            ["Secret Shrine Rupee 10"] = function () return true end,
            ["Secret Shrine Rupee 11"] = function () return true end,
            ["Secret Shrine Rupee 12"] = function () return true end,
            ["Secret Shrine Rupee 13"] = function () return true end,
            ["Secret Shrine Rupee 14"] = function () return true end,
            ["Secret Shrine Rupee 15"] = function () return true end,
            ["Secret Shrine Rupee 16"] = function () return true end,
            ["Secret Shrine Rupee 17"] = function () return true end,
        },
    },
    ["Secret Shrine Main"] = {
        ["events"] = {
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Secret Shrine Boss Dinalfos"] = function () return true end,
            ["Secret Shrine Boss Wizzrobe"] = function () return true end,
            ["Secret Shrine Boss Wart"] = function () return true end,
            ["Secret Shrine Boss Garo Master"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine HP Chest"] = function () return soul_poe_collector() and event('SECRET_SHRINE_DINALFOS') and event('SECRET_SHRINE_WIZZROBE') and event('SECRET_SHRINE_WART') and event('SECRET_SHRINE_GARO') end,
            ["Secret Shrine Pot 1"] = function () return true end,
            ["Secret Shrine Pot 2"] = function () return true end,
            ["Secret Shrine Pot 3"] = function () return true end,
            ["Secret Shrine Pot 4"] = function () return true end,
            ["Secret Shrine Pot 5"] = function () return true end,
            ["Secret Shrine Pot 6"] = function () return true end,
            ["Secret Shrine Pot 7"] = function () return true end,
            ["Secret Shrine Pot 8"] = function () return true end,
            ["Secret Shrine Pot 9"] = function () return true end,
        },
    },
    ["Secret Shrine Boss Dinalfos"] = {
        ["events"] = {
            ["SECRET_SHRINE_DINALFOS"] = function () return soul_lizalfos_dinalfos() end,
        },
        ["exits"] = {
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Dinalfos Chest"] = function () return event('SECRET_SHRINE_DINALFOS') end,
            ["Secret Shrine Grass Dinolfos 1"] = function () return true end,
            ["Secret Shrine Grass Dinolfos 2"] = function () return true end,
            ["Secret Shrine Grass Dinolfos 3"] = function () return true end,
            ["Secret Shrine Grass Dinolfos 4"] = function () return true end,
        },
    },
    ["Secret Shrine Boss Wizzrobe"] = {
        ["events"] = {
            ["SECRET_SHRINE_WIZZROBE"] = function () return soul_enemy(SOUL_ENEMY_WIZZROBE) end,
        },
        ["exits"] = {
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Wizzrobe Chest"] = function () return event('SECRET_SHRINE_WIZZROBE') end,
            ["Secret Shrine Grass Wizzrobe 1"] = function () return true end,
            ["Secret Shrine Grass Wizzrobe 2"] = function () return true end,
            ["Secret Shrine Grass Wizzrobe 3"] = function () return true end,
            ["Secret Shrine Grass Wizzrobe 4"] = function () return true end,
            ["Secret Shrine Grass Wizzrobe 5"] = function () return true end,
        },
    },
    ["Secret Shrine Boss Wart"] = {
        ["events"] = {
            ["SECRET_SHRINE_WART"] = function () return soul_enemy(SOUL_ENEMY_WART) end,
        },
        ["exits"] = {
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Wart Chest"] = function () return event('SECRET_SHRINE_WART') end,
            ["Secret Shrine Grass Wart 1"] = function () return true end,
            ["Secret Shrine Grass Wart 2"] = function () return true end,
            ["Secret Shrine Grass Wart 3"] = function () return true end,
            ["Secret Shrine Grass Wart 4"] = function () return true end,
            ["Secret Shrine Grass Wart 5"] = function () return true end,
            ["Secret Shrine Grass Wart 6"] = function () return true end,
            ["Secret Shrine Grass Wart 7"] = function () return true end,
            ["Secret Shrine Grass Wart 8"] = function () return true end,
        },
    },
    ["Secret Shrine Boss Garo Master"] = {
        ["events"] = {
            ["SECRET_SHRINE_GARO"] = function () return soul_enemy(SOUL_ENEMY_GARO) end,
        },
        ["exits"] = {
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Garo Master Chest"] = function () return event('SECRET_SHRINE_GARO') end,
            ["Secret Shrine Grass Garo Master 1"] = function () return true end,
            ["Secret Shrine Grass Garo Master 2"] = function () return true end,
            ["Secret Shrine Grass Garo Master 3"] = function () return true end,
            ["Secret Shrine Grass Garo Master 4"] = function () return true end,
            ["Secret Shrine Grass Garo Master 5"] = function () return true end,
            ["Secret Shrine Grass Garo Master 6"] = function () return true end,
        },
    },
    ["Snowhead Temple"] = {
        ["exits"] = {
            ["Snowhead Temple Entrance"] = function () return can_reset_time_dungeon() end,
            ["Snowhead"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Snowhead Temple Entrance"] = {
        ["exits"] = {
            ["Snowhead Temple"] = function () return true end,
            ["Snowhead Temple Main"] = function () return has_mask_goron() or has_mask_zora() or can_lift_silver() end,
            ["Snowhead Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_GOHT') end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Snowhead Temple Main"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Entrance"] = function () return true end,
            ["Snowhead Temple Compass Room"] = function () return small_keys_sh(3) or ((has_explosives() or trick_keg_explosives()) and small_keys_sh(2)) end,
            ["Snowhead Temple Bridge Front"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return can_use_fire_short_range() or trick_sht_hot_water() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Pot Entrance 1"] = function () return true end,
            ["Snowhead Temple Pot Entrance 2"] = function () return true end,
        },
    },
    ["Snowhead Temple Bridge Front"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Main"] = function () return true end,
            ["Snowhead Temple Bridge Back"] = function () return goron_fast_roll() or can_hookshot() or short_hook_anywhere() or has_hover_boots() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Bridge Room"] = function () return soul_freezard() and (can_hookshot_short() or (has_hover_boots() and can_kill_freezard_short_range())) end,
            ["Snowhead Temple SF Bridge Under Platform"] = function () return (has_arrows() or can_hookshot()) and has('MASK_GREAT_FAIRY') end,
            ["Snowhead Temple SF Bridge Pillar"] = function () return can_use_lens() and (has_arrows() or can_hookshot_short()) and has('MASK_GREAT_FAIRY') end,
            ["Snowhead Temple Pot Bridge Room 1"] = function () return true end,
            ["Snowhead Temple Pot Bridge Room 2"] = function () return true end,
            ["Snowhead Temple Pot Bridge Room 3"] = function () return true end,
            ["Snowhead Temple Pot Bridge Room 4"] = function () return true end,
            ["Snowhead Temple Pot Bridge Room 5"] = function () return true end,
        },
    },
    ["Snowhead Temple Bridge Back"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room"] = function () return true end,
            ["Snowhead Temple Bridge Front"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Bridge Room"] = function () return soul_freezard() and (can_use_fire_short_range() or (has_hover_boots() and can_kill_freezard_short_range())) end,
            ["Snowhead Temple SF Bridge Under Platform"] = function () return has_weapon_range() and has('MASK_GREAT_FAIRY') end,
            ["Snowhead Temple Pot Bridge Room After 1"] = function () return true end,
            ["Snowhead Temple Pot Bridge Room After 2"] = function () return true end,
        },
    },
    ["Snowhead Temple Map Room"] = {
        ["exits"] = {
            ["Snowhead Temple Bridge Back"] = function () return true end,
            ["Snowhead Temple Map Room Upper"] = function () return can_use_fire_arrows() or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Map"] = function () return true end,
            ["Snowhead Temple SF Map Room"] = function () return true end,
        },
    },
    ["Snowhead Temple Map Room Upper"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return goron_fast_roll() or short_hook_anywhere() or has_hover_boots() end,
            ["Snowhead Temple Fire Arrow"] = function () return goron_fast_roll() or (can_use_lens() and scarecrow_hookshot() and has('MASK_DEKU')) or short_hook_anywhere() or has_hover_boots() end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return can_use_fire_short_range() or (trick_sht_hot_water() and (scarecrow_hookshot() or short_hook_anywhere()) and has_mask_goron()) or trick_sht_hot_water_er() end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return can_use_lens() and scarecrow_hookshot() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Map Alcove"] = function () return can_use_lens() or can_hookshot() or short_hook_anywhere() end,
            ["Snowhead Temple Central Room Alcove"] = function () return (scarecrow_hookshot() or (short_hook_anywhere() and has_weapon()) or hookshot_anywhere()) and can_use_lens() end,
            ["Snowhead Temple Pot Central Room Scarecrow 1"] = function () return true end,
            ["Snowhead Temple Pot Central Room Scarecrow 2"] = function () return true end,
            ["Snowhead Temple Pot Central Room Level 2 1"] = function () return true end,
            ["Snowhead Temple Pot Central Room Level 2 2"] = function () return true end,
        },
    },
    ["Snowhead Temple Center Level 1"] = {
        ["exits"] = {
            ["Snowhead Temple Bridge Back"] = function () return true end,
            ["Snowhead Temple Center Level 0"] = function () return true end,
            ["Snowhead Temple Block Room"] = function () return true end,
            ["Snowhead Temple Pillars Room"] = function () return can_use_fire_short_range() or trick_sht_hot_water() end,
            ["Snowhead Temple Map Room Upper"] = function () return scarecrow_hookshot() or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Pot Central Room Scarecrow 1"] = function () return scarecrow_hookshot() or short_hook_anywhere() end,
            ["Snowhead Temple Pot Central Room Scarecrow 2"] = function () return scarecrow_hookshot() or short_hook_anywhere() end,
        },
    },
    ["Snowhead Temple Pillars Room"] = {
        ["events"] = {
            ["SNOWHEAD_RAISE_PILLAR"] = function () return has_mask_goron() and (can_use_fire_short_range() or (event('SHT_STICK_RUN') and trick('MM_SHT_STICKS_RUN')) or trick_sht_hot_water_er()) end,
        },
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Pillars Room"] = function () return soul_freezard() and can_kill_freezard_short_range() end,
            ["Snowhead Temple Pot Pillars Room Upper 1"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Upper 2"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Upper 3"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Upper 4"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Upper 5"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Upper 6"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Lower 1"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Lower 2"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Lower 3"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Lower 4"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Lower 5"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Lower 6"] = function () return true end,
            ["Snowhead Temple Pot Pillars Room Lower 7"] = function () return true end,
        },
    },
    ["Snowhead Temple Center Level 0"] = {
        ["events"] = {
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Bottom"] = function () return has_mask_goron() or has_iron_boots() end,
            ["Snowhead Temple Pot Central Room Bottom 1"] = function () return true end,
            ["Snowhead Temple Pot Central Room Bottom 2"] = function () return true end,
            ["Snowhead Temple Grass 01"] = function () return true end,
            ["Snowhead Temple Grass 02"] = function () return true end,
            ["Snowhead Temple Grass 03"] = function () return true end,
            ["Snowhead Temple Grass 04"] = function () return true end,
            ["Snowhead Temple Grass 05"] = function () return true end,
            ["Snowhead Temple Grass 06"] = function () return true end,
            ["Snowhead Temple Grass 07"] = function () return true end,
            ["Snowhead Temple Grass 08"] = function () return true end,
            ["Snowhead Temple Grass 09"] = function () return true end,
            ["Snowhead Temple Grass 10"] = function () return true end,
        },
    },
    ["Snowhead Temple Block Room"] = {
        ["events"] = {
            ["SNOWHEAD_PUSH_BLOCK"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["Snowhead Temple Block Room Upper"] = function () return can_hookshot_short() or (event('SNOWHEAD_PUSH_BLOCK') and is_tall()) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Block Room"] = function () return true end,
            ["Snowhead Temple Pot Block Room 1"] = function () return true end,
            ["Snowhead Temple Pot Block Room 2"] = function () return true end,
        },
    },
    ["Snowhead Temple Block Room Upper"] = {
        ["exits"] = {
            ["Snowhead Temple Block Room"] = function () return true end,
            ["Snowhead Temple Compass Room"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Block Room Ledge"] = function () return event('SNOWHEAD_PUSH_BLOCK') end,
            ["Snowhead Temple Flying Pot 1"] = function () return soul_flying_pot() end,
            ["Snowhead Temple Flying Pot 2"] = function () return soul_flying_pot() end,
        },
    },
    ["Snowhead Temple Compass Room"] = {
        ["exits"] = {
            ["Snowhead Temple Main"] = function () return small_keys_sh(3) or ((has_explosives() or trick_keg_explosives()) and small_keys_sh(2)) end,
            ["Snowhead Temple Block Room Upper"] = function () return can_use_fire_short_range() or trick_sht_hot_water() or can_hookshot_short() or can_goron_bomb_jump() end,
            ["Snowhead Temple Icicles"] = function () return has_explosives() or trick_keg_explosives() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Compass"] = function () return true end,
            ["Snowhead Temple Compass Room Ledge"] = function () return can_use_fire_short_range() or trick_sht_hot_water() end,
            ["Snowhead Temple SF Compass Room Crate"] = function () return ((can_use_fire_short_range() or trick_sht_hot_water()) or can_hookshot_short() or is_tall()) and (has_explosives() or has_mask_goron() or has_hover_boots()) or (has('MASK_GREAT_FAIRY') and (has_bombs() or trick_keg_explosives())) or can_goron_bomb_jump() end,
            ["Snowhead Temple Pot Compass Room 1"] = function () return true end,
            ["Snowhead Temple Pot Compass Room 2"] = function () return true end,
            ["Snowhead Temple Pot Compass Room 3"] = function () return true end,
            ["Snowhead Temple Pot Compass Room 4"] = function () return true end,
            ["Snowhead Temple Pot Compass Room 5"] = function () return true end,
        },
    },
    ["Snowhead Temple Icicles"] = {
        ["exits"] = {
            ["Snowhead Temple Compass Room"] = function () return has_explosives() or trick_keg_explosives() end,
            ["Snowhead Temple Dual Switches Locked"] = function () return small_keys_sh(3) or ((has_explosives() or trick_keg_explosives()) and small_keys_sh(2)) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Icicle Room Alcove"] = function () return can_use_lens() end,
            ["Snowhead Temple Icicle Room"] = function () return (has_arrows() or is_tall() or can_use_lens()) and can_break_boulders() or (can_hookshot_short() and (has_explosives() or trick_keg_explosives())) end,
            ["Snowhead Temple Rupee 1"] = function () return has_arrows() end,
            ["Snowhead Temple Rupee 2"] = function () return has_arrows() end,
            ["Snowhead Temple Rupee 3"] = function () return has_arrows() end,
        },
    },
    ["Snowhead Temple Dual Switches Locked"] = {
        ["exits"] = {
            ["Snowhead Temple Icicles"] = function () return small_keys_sh(3) or ((has_explosives() or trick_keg_explosives()) and small_keys_sh(2)) end,
            ["Snowhead Temple Dual Switches Unlocked"] = function () return has_mask_goron() or is_tall() or short_hook_anywhere() or can_hookshot() or has_hover_boots() or can_use_fire_short_range() or trick_sht_hot_water_er() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Dual Switches"] = function () return can_use_lens() and ((has_arrows() or can_hookshot()) and has('MASK_GREAT_FAIRY') or hookshot_anywhere()) end,
            ["Snowhead Temple Pot Dual Switches 1"] = function () return true end,
            ["Snowhead Temple Pot Dual Switches 2"] = function () return true end,
        },
    },
    ["Snowhead Temple Dual Switches Unlocked"] = {
        ["exits"] = {
            ["Snowhead Temple Dual Switches Locked"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Dual Switches"] = function () return can_use_lens() and ((has_arrows() or can_hookshot()) and has('MASK_GREAT_FAIRY')) end,
        },
    },
    ["Snowhead Temple Center Level 2 Dual"] = {
        ["exits"] = {
            ["Snowhead Temple Dual Switches Unlocked"] = function () return true end,
            ["Snowhead Temple Map Room Upper"] = function () return goron_fast_roll() or can_hookshot() or short_hook_anywhere() or has_hover_boots() end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Pot Central Room Scarecrow 1"] = function () return true end,
            ["Snowhead Temple Pot Central Room Scarecrow 2"] = function () return true end,
        },
    },
    ["Snowhead Temple Fire Arrow"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return goron_fast_roll() or (can_use_lens() and scarecrow_hookshot() and has('MASK_DEKU')) or short_hook_anywhere() or has_hover_boots() end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return can_hookshot() end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Fire Arrow"] = function () return soul_enemy(SOUL_ENEMY_WIZZROBE) end,
            ["Snowhead Temple Central Room Alcove"] = function () return (scarecrow_hookshot() or (short_hook_anywhere() and has_weapon())) and can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 3 Snow"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return true end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return has_mask_goron() or can_hookshot() or short_hook_anywhere() or has_hover_boots() end,
            ["Snowhead Temple Snow Room"] = function () return small_keys_sh(3) end,
            ["Snowhead Temple Fire Arrow"] = function () return true end,
            ["Snowhead Temple Center Level 4"] = function () return short_hook_anywhere() and (can_use_fire_arrows() or has_mask_blast() or has_bombchu()) end,
            ["Snowhead Temple Dinolfos Room"] = function () return hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Alcove"] = function () return can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 3 Iced"] = {
        ["events"] = {
            ["SHT_STICK_RUN"] = function () return has_sticks() end,
        },
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return has_weapon() or is_tall() or has_mask_goron() or has_hover_boots() end,
            ["Snowhead Temple Fire Arrow"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return has_mask_goron() or can_hookshot() or short_hook_anywhere() or has_hover_boots() end,
            ["Snowhead Temple Center Level 4"] = function () return event('SNOWHEAD_RAISE_PILLAR') end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Alcove"] = function () return can_use_lens() end,
        },
    },
    ["Snowhead Temple Snow Room"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 3 Snow"] = function () return true end,
            ["Snowhead Temple Dinolfos Room"] = function () return can_use_fire_short_range() or trick_sht_hot_water_er() or (trick_sht_hot_water() and can_use_farore()) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Snow Room"] = function () return can_use_lens() and ((has_arrows() or can_hookshot_short()) and has('MASK_GREAT_FAIRY') or short_hook_anywhere()) end,
        },
    },
    ["Snowhead Temple Dinolfos Room"] = {
        ["exits"] = {
            ["Snowhead Temple Snow Room"] = function () return can_use_fire_short_range() or trick_sht_hot_water_er() end,
            ["Snowhead Temple Boss Key Room"] = function () return event('SNOWHEAD_RAISE_PILLAR') or hookshot_anywhere() end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return true end,
            ["Snowhead Temple Center Level 4"] = function () return trick('MM_SHT_PILLARLESS') and (can_use_fire_arrows() or has_bombs()) or (short_hook_anywhere() and (has_bombs() or can_use_fire_arrows())) or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Dinolfos 1"] = function () return soul_lizalfos_dinalfos() and (can_fight() or has_arrows()) end,
            ["Snowhead Temple SF Dinolfos 2"] = function () return soul_lizalfos_dinalfos() and (can_fight() or has_arrows()) end,
        },
    },
    ["Snowhead Temple Boss Key Room"] = {
        ["exits"] = {
            ["Snowhead Temple Dinolfos Room"] = function () return event('SNOWHEAD_RAISE_PILLAR') or hookshot_anywhere() end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return event('SNOWHEAD_RAISE_PILLAR') or hookshot_anywhere() end,
            ["Snowhead Temple Center Level 4"] = function () return trick('MM_SHT_PILLARLESS') and (can_use_fire_arrows() or has_bombs()) or (short_hook_anywhere() and (has_bombs() or can_use_fire_arrows())) or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Boss Key"] = function () return soul_enemy(SOUL_ENEMY_WIZZROBE) end,
            ["Snowhead Temple Pot Central Room Near Boss Key 1"] = function () return true end,
            ["Snowhead Temple Pot Central Room Near Boss Key 2"] = function () return true end,
            ["Snowhead Temple Pot Wizzrobe 1"] = function () return true end,
            ["Snowhead Temple Pot Wizzrobe 2"] = function () return true end,
            ["Snowhead Temple Pot Wizzrobe 3"] = function () return true end,
            ["Snowhead Temple Pot Wizzrobe 4"] = function () return true end,
            ["Snowhead Temple Pot Wizzrobe 5"] = function () return true end,
        },
    },
    ["Snowhead Temple Center Level 4"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return true end,
            ["Snowhead Temple Boss Access"] = function () return (goron_fast_roll() or hookshot_anywhere()) and boss_key(BOSS_KEY_SH) end,
            ["Snowhead Temple Boss Key Room"] = function () return has_mask_goron() or short_hook_anywhere() end,
            ["Snowhead Temple Dinolfos Room"] = function () return has_mask_goron() or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Snowhead Temple Boss Access"] = {
        ["exits"] = {
            ["Snowhead Temple Boss"] = function () return true end,
        },
    },
    ["Snowhead Temple Boss"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple After Boss"] = function () return soul_boss(SOUL_BOSS_GOHT) and can_use_fire_short_range() end,
            ["WARP_SONGS"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Snowhead Temple Boss Pot Early 1"] = function () return true end,
            ["Snowhead Temple Boss Pot Early 2"] = function () return true end,
            ["Snowhead Temple Boss Pot Early 3"] = function () return true end,
            ["Snowhead Temple Boss Pot Early 4"] = function () return true end,
            ["Snowhead Temple Boss Pot 01"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 02"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 03"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 04"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 05"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 06"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 07"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 08"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 09"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
            ["Snowhead Temple Boss Pot 10"] = function () return can_use_fire_short_range() or short_hook_anywhere() end,
        },
    },
    ["Snowhead Temple After Boss"] = {
        ["events"] = {
            ["BOSS_SNOWHEAD"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Boss HC"] = function () return true end,
            ["Snowhead Temple Boss"] = function () return true end,
        },
    },
    ["Stone Tower Temple"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return can_reset_time_dungeon() end,
            ["Stone Tower Front of Temple"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Stone Tower Temple Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["ARROWS"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple"] = function () return true end,
            ["Stone Tower Temple West"] = function () return true end,
            ["Stone Tower Temple Water Room"] = function () return can_use_light_arrows() or event('STONE_TOWER_EAST_ENTRY_BLOCK') or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Entrance Chest"] = function () return has_arrows() end,
            ["Stone Tower Temple Entrance Switch Chest"] = function () return event('STONE_TOWER_ENTRANCE_CHEST_SWITCH') end,
            ["Stone Tower Temple Pot Entrance 1"] = function () return true end,
            ["Stone Tower Temple Pot Entrance 2"] = function () return true end,
            ["Stone Tower Temple Grass Entrance 1"] = function () return true end,
            ["Stone Tower Temple Grass Entrance 2"] = function () return true end,
            ["Stone Tower Temple Grass Entrance 3"] = function () return true end,
        },
    },
    ["Stone Tower Temple West"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return true end,
            ["Stone Tower Temple West Garden"] = function () return can_play_emptiness() and has_mask_goron() and (has_explosives() or trick_keg_explosives()) end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Stone Tower Temple West Garden"] = {
        ["events"] = {
            ["STONE_TOWER_WEST_GARDEN_LIGHT"] = function () return has_explosives() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Under West Garden"] = function () return true end,
            ["Stone Tower Temple Center Ledge"] = function () return small_keys_st(4) or (small_keys_st(3) and (has_mask_zora() or short_hook_anywhere())) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Grass Garden 1"] = function () return true end,
            ["Stone Tower Temple Grass Garden 2"] = function () return true end,
            ["Stone Tower Temple Grass Garden 3"] = function () return true end,
            ["Stone Tower Temple Grass Garden 4"] = function () return true end,
            ["Stone Tower Temple Grass Garden 5"] = function () return true end,
            ["Stone Tower Temple Grass Garden 6"] = function () return true end,
        },
    },
    ["Stone Tower Temple Under West Garden"] = {
        ["exits"] = {
            ["Stone Tower Temple West Garden"] = function () return true end,
            ["Stone Tower Temple Under West Garden After Block"] = function () return event('STONE_TOWER_WEST_GARDEN_LIGHT') and has_mirror_shield() or can_use_light_arrows() or short_hook_anywhere() or (can_hookshot() and has_hover_boots() and trick('MM_STT_LAVA_BLOCK_HOVERS') and (has_weapon() or has_mask_bunny())) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Under West Garden Ledge Chest"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Stone Tower Temple Pot Lava Room 1"] = function () return true end,
            ["Stone Tower Temple Pot Lava Room 2"] = function () return true end,
            ["Stone Tower Temple Pot Lava Room 3"] = function () return true end,
            ["Stone Tower Temple Pot Lava Room 4"] = function () return true end,
        },
    },
    ["Stone Tower Temple Under West Garden After Block"] = {
        ["exits"] = {
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Under West Garden Lava Chest"] = function () return soul_armos() and (can_fight() or has_explosives()) end,
            ["Stone Tower Temple Map"] = function () return true end,
            ["Stone Tower Temple Pot Lava Room After Block 1"] = function () return true end,
            ["Stone Tower Temple Pot Lava Room After Block 2"] = function () return true end,
            ["Stone Tower Temple Pot Lava Room After Block 3"] = function () return true end,
            ["Stone Tower Temple Pot Lava Room After Block 4"] = function () return true end,
        },
    },
    ["Stone Tower Temple Center Ledge"] = {
        ["exits"] = {
            ["Stone Tower Temple West Garden"] = function () return small_keys_st(4) or (small_keys_st(3) and has_mask_goron() and (has_explosives() or trick_keg_explosives()) and can_play_emptiness()) end,
            ["Stone Tower Temple Center"] = function () return has_mask_zora() or soul_enemy(SOUL_ENEMY_DEXIHAND) or (has_tunic_zora() and has_iron_boots() and can_hookshot()) or (has_tunic_zora() and has_iron_boots() and short_hook_anywhere()) end,
            ["Stone Tower Temple Water Bridge"] = function () return can_goron_bomb_jump() and can_use_ice_arrows() or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Center Sun Block Chest"] = function () return short_hook_anywhere() or (can_goron_bomb_jump() and can_use_ice_arrows() and can_use_light_arrows()) or (((has('MASK_DEKU') or has_explosives() or (has_magic() and (has_weapon() and has('SPIN_UPGRADE'))) or has_sword_level(3) or has('GREAT_FAIRY_SWORD') or can_use_ice_arrows()) and (has_mask_zora() or soul_enemy(SOUL_ENEMY_DEXIHAND))) and can_use_light_arrows()) end,
            ["Stone Tower Temple Rupee Center Room Left"] = function () return can_use_light_arrows() or short_hook_anywhere() end,
        },
    },
    ["Stone Tower Temple Center"] = {
        ["exits"] = {
            ["Stone Tower Temple Water Room"] = function () return underwater_walking() or short_hook_anywhere() or can_dive_small() end,
            ["Stone Tower Temple Center Ledge"] = function () return has_mask_zora() end,
            ["Stone Tower Temple Water Bridge"] = function () return can_goron_bomb_jump() and can_use_ice_arrows() or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Center Across Water Chest"] = function () return true end,
            ["Stone Tower Temple Center Sun Block Chest"] = function () return (has_mask_zora() or (can_goron_bomb_jump() and can_use_ice_arrows())) and can_use_light_arrows() or short_hook_anywhere() end,
            ["Stone Tower Temple Rupee Center Room Right"] = function () return (has_mask_zora() or has('MASK_DEKU') or can_use_ice_arrows()) and can_use_light_arrows() or short_hook_anywhere() end,
        },
    },
    ["Stone Tower Temple Water Room"] = {
        ["events"] = {
            ["STONE_TOWER_WATER_CHEST_SWITCH"] = function () return underwater_walking() end,
            ["STONE_TOWER_EAST_ENTRY_BLOCK"] = function () return has_mirror_shield() or can_use_light_arrows() end,
            ["STONE_TOWER_WATER_CHEST_SUN"] = function () return can_use_ice_arrows() and can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Center"] = function () return has_mask_zora() or (soul_enemy(SOUL_ENEMY_DEXIHAND) and (short_hook_anywhere() or can_dive_small() or (has_tunic_zora() and has_iron_boots()))) or (has_tunic_zora() and has_iron_boots() and (can_hookshot() or short_hook_anywhere())) end,
            ["Stone Tower Temple Mirrors Room"] = function () return small_keys_st(4) end,
            ["Stone Tower Temple Entrance"] = function () return event('STONE_TOWER_EAST_ENTRY_BLOCK') or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Compass"] = function () return event('STONE_TOWER_EAST_ENTRY_BLOCK') end,
            ["Stone Tower Temple Water Sun Switch Chest"] = function () return underwater_walking() and event('STONE_TOWER_WATER_CHEST_SUN') end,
            ["Stone Tower Temple Pot Water Room Underwater Lower 1"] = function () return underwater_walking() or (hookshot_anywhere() and can_use_ice_arrows()) end,
            ["Stone Tower Temple Pot Water Room Underwater Lower 2"] = function () return underwater_walking() or (hookshot_anywhere() and can_use_ice_arrows()) end,
            ["Stone Tower Temple Pot Water Room Underwater Lower 3"] = function () return underwater_walking() or (hookshot_anywhere() and can_use_ice_arrows()) end,
            ["Stone Tower Temple Pot Water Room Underwater Upper 1"] = function () return underwater_walking() or hookshot_anywhere() or (short_hook_anywhere() and can_use_ice_arrows()) or (can_dive_small() and (has_weapon_range() or (trick('MM_STT_POT_BOMBCHU_DIVE') and has_bombchu()))) end,
            ["Stone Tower Temple Pot Water Room Underwater Upper 2"] = function () return underwater_walking() or hookshot_anywhere() or (short_hook_anywhere() and can_use_ice_arrows()) or (can_dive_small() and (has_weapon_range() or (trick('MM_STT_POT_BOMBCHU_DIVE') and has_bombchu()))) end,
            ["Stone Tower Temple Pot Water Room Bridge 1"] = function () return true end,
            ["Stone Tower Temple Pot Water Room Bridge 2"] = function () return true end,
        },
    },
    ["Stone Tower Temple Mirrors Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Wind Room"] = function () return has_mask_goron() and has_mirror_shield() or can_use_light_arrows() or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Mirrors Room Center Chest"] = function () return has_mask_goron() and has_mirror_shield() or can_use_light_arrows() end,
            ["Stone Tower Temple Mirrors Room Right Chest"] = function () return has_mask_goron() and has_mirror_shield() or can_use_light_arrows() or short_hook_anywhere() end,
            ["Stone Tower Temple Pot Mirror Room 1"] = function () return true end,
            ["Stone Tower Temple Pot Mirror Room 2"] = function () return true end,
        },
    },
    ["Stone Tower Temple Wind Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Light Arrow Room"] = function () return has('MASK_DEKU') or can_use_light_arrows() or (short_hook_anywhere() and has_weapon() and trick('MM_ST_UPDRAFTS')) or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Wind Room Ledge Chest"] = function () return has('MASK_DEKU') or (trick('MM_ST_UPDRAFTS') and (short_hook_anywhere() or (has_hover_boots() and has_iron_boots()))) or hookshot_anywhere() end,
            ["Stone Tower Temple Wind Room Jail Chest"] = function () return (has('MASK_DEKU') or can_use_light_arrows() or (short_hook_anywhere() and has_weapon() and trick('MM_ST_UPDRAFTS')) or hookshot_anywhere()) and has_mask_goron() end,
            ["Stone Tower Temple Pot Wind Room 1"] = function () return has('MASK_DEKU') or can_use_light_arrows() or (short_hook_anywhere() and has_weapon() and trick('MM_ST_UPDRAFTS')) or hookshot_anywhere() end,
            ["Stone Tower Temple Pot Wind Room 2"] = function () return has('MASK_DEKU') or can_use_light_arrows() or (short_hook_anywhere() and has_weapon() and trick('MM_ST_UPDRAFTS')) or hookshot_anywhere() end,
            ["Stone Tower Temple Pot Wind Room 3"] = function () return has('MASK_DEKU') or can_use_light_arrows() or (short_hook_anywhere() and has_weapon() and trick('MM_ST_UPDRAFTS')) or hookshot_anywhere() end,
            ["Stone Tower Temple Pot Wind Room 4"] = function () return has('MASK_DEKU') or can_use_light_arrows() or (short_hook_anywhere() and has_weapon() and trick('MM_ST_UPDRAFTS')) or hookshot_anywhere() end,
            ["Stone Tower Temple Rupee Wind Room 1"] = function () return has('MASK_DEKU') or (trick('MM_ST_UPDRAFTS') and (short_hook_anywhere() or (has_hover_boots() and has_iron_boots()))) or hookshot_anywhere() end,
            ["Stone Tower Temple Rupee Wind Room 2"] = function () return has('MASK_DEKU') or (trick('MM_ST_UPDRAFTS') and (short_hook_anywhere() or (has_hover_boots() and has_iron_boots()))) or hookshot_anywhere() end,
            ["Stone Tower Temple Rupee Wind Room 3"] = function () return has('MASK_DEKU') or (trick('MM_ST_UPDRAFTS') and (short_hook_anywhere() or (has_hover_boots() and has_iron_boots()))) or hookshot_anywhere() end,
            ["Stone Tower Temple Rupee Wind Room 4"] = function () return has('MASK_DEKU') or (trick('MM_ST_UPDRAFTS') and (short_hook_anywhere() or (has_hover_boots() and has_iron_boots()))) or hookshot_anywhere() end,
            ["Stone Tower Temple Rupee Wind Room 5"] = function () return has('MASK_DEKU') or (trick('MM_ST_UPDRAFTS') and (short_hook_anywhere() or (has_hover_boots() and has_iron_boots()))) or hookshot_anywhere() end,
            ["Stone Tower Temple Rupee Wind Room 6"] = function () return has('MASK_DEKU') or (trick('MM_ST_UPDRAFTS') and (short_hook_anywhere() or (has_hover_boots() and has_iron_boots()))) or hookshot_anywhere() end,
        },
    },
    ["Stone Tower Temple Light Arrow Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Before Water Bridge"] = function () return soul_enemy(SOUL_ENEMY_GARO) and (has_weapon() or has_mask_goron() or can_use_deku_bubble() or has_arrows()) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Light Arrow"] = function () return soul_enemy(SOUL_ENEMY_GARO) and (has_weapon() or has_mask_goron() or can_use_deku_bubble() or has_arrows()) end,
        },
    },
    ["Stone Tower Temple Before Water Bridge"] = {
        ["events"] = {
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Water Bridge"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Before Water Bridge Chest"] = function () return event('STONE_TOWER_BRIDGE_CHEST_SWITCH') or (has_explosives() or trick_keg_explosives()) end,
            ["Stone Tower Temple Pot Before Water Bridge 1"] = function () return true end,
            ["Stone Tower Temple Pot Before Water Bridge 2"] = function () return true end,
            ["Stone Tower Temple Pot Before Water Bridge 3"] = function () return true end,
            ["Stone Tower Temple Pot Before Water Bridge 4"] = function () return true end,
            ["Stone Tower Temple Pot Before Water Bridge 5"] = function () return true end,
            ["Stone Tower Temple Pot Before Water Bridge 6"] = function () return true end,
            ["Stone Tower Temple Pot Before Water Bridge 7"] = function () return true end,
            ["Stone Tower Temple Pot Before Water Bridge 8"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 1"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 2"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 3"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 4"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 5"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 6"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 7"] = function () return true end,
            ["Stone Tower Temple Rupee Before Water Bridge 8"] = function () return true end,
        },
    },
    ["Stone Tower Temple Water Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return true end,
            ["Stone Tower Temple Center"] = function () return can_goron_bomb_jump() and (can_use_ice_arrows() or soul_enemy(SOUL_ENEMY_DEXIHAND) or has_mask_zora() or can_hookshot()) or short_hook_anywhere() end,
            ["Stone Tower Temple Center Ledge"] = function () return can_goron_bomb_jump() and (can_use_ice_arrows() or has_mask_zora()) or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Water Bridge Chest"] = function () return soul_enemy(SOUL_ENEMY_EYEGORE) and (has_explosives() or has_arrows() or can_hookshot_short() or has_mask_zora() or has_mask_goron()) end,
        },
    },
    ["Stone Tower Temple Inverted"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Entrance"] = function () return can_reset_time_dungeon() end,
            ["Stone Tower Top Inverted"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted"] = function () return true end,
            ["Stone Tower Temple Inverted East"] = function () return can_use_light_arrows() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Entrance Ledge"] = function () return trick('MM_ISTT_ENTRY_JUMP') and (has_bombs() or trick_keg_explosives()) or short_hook_anywhere() or (trick('MM_ISTT_ENTRY_HOVER') and has_hover_boots() and has_mask_bunny()) end,
            ["Stone Tower Temple Inverted Entrance Top"] = function () return short_hook_anywhere() end,
            ["Stone Tower Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_TWINMOLD') end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Entrance Chest"] = function () return can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Inverted East"] = {
        ["events"] = {
            ["STONE_TOWER_WATER_CHEST_SUN"] = function () return can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Entrance"] = function () return can_use_light_arrows() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted East Ledge"] = function () return has('MASK_DEKU') or hookshot_anywhere() end,
            ["Stone Tower Temple Inverted East Bridge"] = function () return has('MASK_DEKU') or trick('MM_ST_UPDRAFTS') or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted East Lower Chest"] = function () return (has('MASK_DEKU') or short_hook_anywhere()) and can_use_fire_short_range() end,
            ["Stone Tower Temple Inverted East Upper Chest"] = function () return (has('MASK_DEKU') or hookshot_anywhere()) and can_use_elegy() and event('STONE_TOWER_WATER_CHEST_SWITCH') end,
            ["Stone Tower Temple Inverted Rupee Alcove 1"] = function () return can_use_light_arrows() and can_hookshot_short() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Rupee Alcove 2"] = function () return can_use_light_arrows() and can_hookshot_short() or short_hook_anywhere() end,
        },
    },
    ["Stone Tower Temple Inverted East Bridge"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted East"] = function () return true end,
            ["Stone Tower Temple Inverted Center Bridge"] = function () return trick('MM_ISTT_EYEGORE') and (has_mask_zora() and has_bombs() or (has_shield() and has_explosives())) or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return trick('MM_ISTT_EYEGORE') or short_hook_anywhere() or has_hover_boots() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted East Middle Chest"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Updrafts Bridge 1"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Updrafts Bridge 2"] = function () return true end,
            ["Stone Tower Temple Inverted Rupee Dexihand 1"] = function () return true end,
            ["Stone Tower Temple Inverted Rupee Dexihand 2"] = function () return true end,
            ["Stone Tower Temple Inverted Rupee Dexihand 3"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted East Ledge"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted East"] = function () return true end,
            ["Stone Tower Temple Inverted East Bridge"] = function () return true end,
            ["Stone Tower Temple Inverted Wizzrobe"] = function () return (soul_enemy(SOUL_ENEMY_CHUCHU) or (trick('MM_ISTT_CHUCHU_LESS') and (has_chateau() or has_blue_potion() or has_green_potion() or has_double_magic()))) and can_use_light_arrows() and small_keys_st(4) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Pot Updrafts Ledge 1"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Updrafts Ledge 2"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Updrafts Ledge 3"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Updrafts Ledge 4"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Wizzrobe"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Wizzrobe Ledge"] = function () return soul_enemy(SOUL_ENEMY_WIZZROBE) and can_hookshot_short() and (can_fight() or has_arrows()) or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted East Ledge"] = function () return (can_use_light_arrows() or short_hook_anywhere()) and small_keys_st(3) or (can_goron_bomb_jump() and has_bombs() and small_keys_st(4)) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Pot Wizzrobe 1"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Pot Wizzrobe 2"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Pot Wizzrobe 3"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Pot Wizzrobe 4"] = function () return can_hookshot() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Pot Wizzrobe 5"] = function () return can_hookshot() or short_hook_anywhere() end,
        },
    },
    ["Stone Tower Temple Inverted Wizzrobe Ledge"] = {
        ["events"] = {
            ["POE"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Wizzrobe"] = function () return true end,
            ["Stone Tower Temple Inverted Death Armos Maze"] = function () return has('MASK_DEKU') or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Wizzrobe Chest"] = function () return soul_enemy(SOUL_ENEMY_WIZZROBE) and (can_fight() or has_arrows()) end,
            ["Stone Tower Temple Inverted Pot Poe Wizzrobe Side 1"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Poe Wizzrobe Side 2"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Death Armos Maze"] = {
        ["events"] = {
            ["POE"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Center"] = function () return true end,
            ["Stone Tower Temple Inverted Wizzrobe Ledge"] = function () return has('MASK_DEKU') or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Death Armos Chest"] = function () return can_use_elegy() end,
            ["Stone Tower Temple Inverted Pot Poe Maze Side 1"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Poe Maze Side 2"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Center"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return has('MASK_DEKU') and has_weapon_range() or hookshot_anywhere() end,
            ["Stone Tower Temple Inverted Entrance Ledge"] = function () return true end,
            ["Stone Tower Temple Inverted Death Armos Maze"] = function () return true end,
            ["Stone Tower Temple Inverted Center Bridge"] = function () return trick('MM_ISTT_EYEGORE') and can_use_light_arrows() and can_hookshot() or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Flying Pot Center 1"] = function () return (has('MASK_DEKU') and has_weapon_range() or hookshot_anywhere()) and soul_flying_pot() end,
            ["Stone Tower Temple Inverted Flying Pot Center 2"] = function () return (has('MASK_DEKU') and has_weapon_range() or hookshot_anywhere()) and soul_flying_pot() end,
        },
    },
    ["Stone Tower Temple Inverted Boss Key Room"] = {
        ["events"] = {
            ["ARROWS"] = function () return true end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Center"] = function () return has('MASK_DEKU') or hookshot_anywhere() end,
            ["Stone Tower Temple Inverted Center Bridge"] = function () return trick('MM_ISTT_EYEGORE') and can_use_light_arrows() and can_hookshot() or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Boss Key"] = function () return soul_enemy(SOUL_ENEMY_GOMESS) and can_use_light_arrows() and can_fight() end,
            ["Stone Tower Temple Inverted Pot Gomess 1"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Gomess 2"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Gomess 3"] = function () return true end,
            ["Stone Tower Temple Inverted Pot Gomess 4"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Entrance Ledge"] = {
        ["events"] = {
            ["STONE_TOWER_ENTRANCE_CHEST_SWITCH"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Entrance Top"] = function () return can_hookshot() end,
            ["Stone Tower Temple Inverted Center"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Entrance Top"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Center Bridge"] = function () return small_keys_st(4) end,
            ["Stone Tower Temple Inverted Entrance"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Center Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Pre-Boss"] = function () return soul_enemy(SOUL_ENEMY_EYEGORE) and (has_explosives() or has_arrows() or can_hookshot_short() or has_mask_zora() or has_mask_goron()) end,
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return trick('MM_ISTT_EYEGORE') and has_explosives() or has_mask_goron() or has_hover_boots() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Center"] = function () return trick('MM_ISTT_EYEGORE') and has_explosives() or has_mask_goron() or has_hover_boots() or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Entrance Top"] = function () return small_keys_st(4) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Giant Mask"] = function () return soul_enemy(SOUL_ENEMY_EYEGORE) and (has_explosives() or has_arrows() or can_hookshot_short() or has_mask_zora() or has_mask_goron()) end,
        },
    },
    ["Stone Tower Temple Inverted Pre-Boss"] = {
        ["events"] = {
            ["STONE_TOWER_BRIDGE_CHEST_SWITCH"] = function () return can_activate_crystal() end,
            ["MAGIC"] = function () return can_hookshot_short() end,
            ["BOMBS_OR_BOMBCHU"] = function () return can_hookshot_short() end,
            ["ARROWS"] = function () return can_hookshot_short() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Boss Access"] = function () return can_hookshot_short() and boss_key(BOSS_KEY_ST) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Pot Pre-Boss 1"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Pot Pre-Boss 2"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Pot Pre-Boss 3"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Pot Pre-Boss 4"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Pot Pre-Boss 5"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Pot Pre-Boss 6"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Pot Pre-Boss 7"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Pot Pre-Boss 8"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Flying Pot Pre-Boss 1"] = function () return soul_flying_pot() and can_hookshot_short() end,
            ["Stone Tower Temple Inverted Flying Pot Pre-Boss 2"] = function () return soul_flying_pot() and can_hookshot_short() end,
            ["Stone Tower Temple Inverted Flying Pot Pre-Boss 3"] = function () return soul_flying_pot() and can_hookshot_short() end,
            ["Stone Tower Temple Inverted Flying Pot Pre-Boss 4"] = function () return soul_flying_pot() and can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Top 1"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Top 2"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Top 3"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Front 1"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Front 2"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Front 3"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Front 4"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Back 1"] = function () return can_hookshot_short() and has_mask_zora() or (has_mask_goron() and trick('MM_ISTT_RUPEES_GORON')) or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Back 2"] = function () return can_hookshot_short() and has_mask_zora() or (has_mask_goron() and trick('MM_ISTT_RUPEES_GORON')) or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Back 3"] = function () return can_hookshot_short() and has_mask_zora() or (has_mask_goron() and trick('MM_ISTT_RUPEES_GORON')) or short_hook_anywhere() end,
            ["Stone Tower Temple Inverted Rupee Pre-Boss Back 4"] = function () return can_hookshot_short() and has_mask_zora() or (has_mask_goron() and trick('MM_ISTT_RUPEES_GORON')) or short_hook_anywhere() end,
        },
    },
    ["Stone Tower Temple Boss Access"] = {
        ["exits"] = {
            ["Stone Tower Temple Boss"] = function () return true end,
        },
    },
    ["Stone Tower Temple Boss"] = {
        ["exits"] = {
            ["Stone Tower After Boss"] = function () return soul_boss(SOUL_BOSS_TWINMOLD) and (has_magic() and (has('MASK_GIANT') and has_sword() or has('MASK_FIERCE_DEITY'))) end,
            ["WARP_SONGS"] = function () return can_reset_time() end,
        },
    },
    ["Stone Tower After Boss"] = {
        ["events"] = {
            ["BOSS_STONE_TOWER"] = function () return true end,
        },
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Boss HC"] = function () return true end,
            ["Stone Tower Temple Inverted Boss"] = function () return true end,
        },
    },
    ["Swamp Spider House"] = {
        ["exits"] = {
            ["Near Swamp Spider House"] = function () return true end,
            ["Swamp Spider House Main"] = function () return can_reset_time_dungeon() end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Spider House Mask of Truth"] = function () return soul_citizen() and has('GS_TOKEN_SWAMP', 30) end,
        },
    },
    ["Swamp Spider House Main"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return has_arrows() end,
            ["BUGS"] = function () return true end,
            ["WATER"] = function () return true end,
        },
        ["exits"] = {
            ["Swamp Spider House"] = function () return true end,
            ["SOARING"] = function () return can_play_soaring() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Skulltula Main Room Near Ceiling"] = function () return gs() and (can_hookshot_short() or has_mask_zora() or (has('MASK_DEKU') and (has_arrows() or has_magic() or (has_bombs() or has_bombchu() or trick_keg_explosives())))) end,
            ["Swamp Skulltula Main Room Lower Right Soft Soil"] = function () return gs() and has_bugs() end,
            ["Swamp Skulltula Main Room Lower Left Soft Soil"] = function () return gs() and has_bugs() end,
            ["Swamp Skulltula Main Room Upper Soft Soil"] = function () return gs() and has_bugs() end,
            ["Swamp Skulltula Main Room Upper Pillar"] = function () return gs() end,
            ["Swamp Skulltula Main Room Pillar"] = function () return gs() end,
            ["Swamp Skulltula Main Room Water"] = function () return gs() end,
            ["Swamp Skulltula Main Room Jar"] = function () return gs() end,
            ["Swamp Skulltula Gold Room Hive"] = function () return gs() and (has_weapon_range() or has_bombchu()) end,
            ["Swamp Skulltula Gold Room Near Ceiling"] = function () return gs() and (can_hookshot_short() or has_mask_zora() or can_use_beans()) end,
            ["Swamp Skulltula Gold Room Pillar"] = function () return gs() end,
            ["Swamp Skulltula Gold Room Wall"] = function () return gs() end,
            ["Swamp Skulltula Tree Room Hive"] = function () return gs() and (has_weapon_range() or has_bombchu()) end,
            ["Swamp Skulltula Tree Room Grass 1"] = function () return gs() end,
            ["Swamp Skulltula Tree Room Grass 2"] = function () return gs() end,
            ["Swamp Skulltula Tree Room Tree 1"] = function () return gs() end,
            ["Swamp Skulltula Tree Room Tree 2"] = function () return gs() end,
            ["Swamp Skulltula Tree Room Tree 3"] = function () return gs() end,
            ["Swamp Skulltula Monument Room Lower Wall"] = function () return gs() and (can_hookshot_short() or has_mask_zora() or (can_use_beans() and can_break_boulders()) or (has_hover_boots() and (has_weapon_range() or has_explosives() or has_weapon()))) end,
            ["Swamp Skulltula Monument Room On Monument"] = function () return gs() end,
            ["Swamp Skulltula Monument Room Crate 1"] = function () return gs() end,
            ["Swamp Skulltula Monument Room Crate 2"] = function () return gs() end,
            ["Swamp Skulltula Monument Room Torch"] = function () return gs() end,
            ["Swamp Skulltula Pot Room Hive 1"] = function () return gs() and (has_weapon_range() or has_bombchu()) end,
            ["Swamp Skulltula Pot Room Hive 2"] = function () return gs() and (has_weapon_range() or has_bombchu()) end,
            ["Swamp Skulltula Pot Room Behind Vines"] = function () return gs() and has_weapon() end,
            ["Swamp Skulltula Pot Room Pot 1"] = function () return gs() end,
            ["Swamp Skulltula Pot Room Pot 2"] = function () return gs() end,
            ["Swamp Skulltula Pot Room Jar"] = function () return gs() end,
            ["Swamp Skulltula Pot Room Wall"] = function () return gs() end,
            ["Swamp Spider House Pot Main Lower 1"] = function () return true end,
            ["Swamp Spider House Pot Main Lower 2"] = function () return true end,
            ["Swamp Spider House Pot Main Lower 3"] = function () return true end,
            ["Swamp Spider House Pot Main Upper Left 1"] = function () return true end,
            ["Swamp Spider House Pot Main Upper Left 2"] = function () return true end,
            ["Swamp Spider House Pot Main Upper Right 1"] = function () return true end,
            ["Swamp Spider House Pot Main Upper Right 2"] = function () return true end,
            ["Swamp Spider House Pot Gold Room Lower 1"] = function () return true end,
            ["Swamp Spider House Pot Gold Room Lower 2"] = function () return true end,
            ["Swamp Spider House Pot Gold Room Upper 1"] = function () return true end,
            ["Swamp Spider House Pot Gold Room Upper 2"] = function () return true end,
            ["Swamp Spider House Pot Gold Room Upper 3"] = function () return true end,
            ["Swamp Spider House Pot Gold Room Upper 4"] = function () return true end,
            ["Swamp Spider House Pot Monument Room 1"] = function () return true end,
            ["Swamp Spider House Pot Monument Room 2"] = function () return true end,
            ["Swamp Spider House Pot Jar Room 1"] = function () return true end,
            ["Swamp Spider House Pot Jar Room 2"] = function () return true end,
            ["Swamp Spider House Pot Jar Room 3"] = function () return true end,
            ["Swamp Spider House Pot Jar Room 4"] = function () return true end,
            ["Swamp Spider House Pot Jar Room 5"] = function () return true end,
            ["Swamp Spider House Pot Jar Room 6"] = function () return true end,
            ["Swamp Spider House Pot Jar Room 7"] = function () return true end,
        },
    },
    ["Woodfall Temple"] = {
        ["exits"] = {
            ["Woodfall Front of Temple"] = function () return true end,
            ["Woodfall Temple Entrance"] = function () return can_reset_time_dungeon() end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Woodfall Temple Entrance"] = {
        ["events"] = {
            ["MAGIC"] = function () return true end,
            ["RUPEES"] = function () return has_weapon_range() end,
            ["FAIRY"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple"] = function () return true end,
            ["Woodfall Temple Main"] = function () return has('MASK_DEKU') or can_hookshot_short() or (has_hover_boots() and has_weapon() and has_explosives() and has_mask_bunny() and (has_arrows() or has_mask_stone()) and trick('MM_WFT_LOBBY_HOVERS')) end,
            ["Woodfall Temple Boss Access"] = function () return setting('bossWarpPads', 'remains') and has('REMAINS_ODOLWA') end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Entrance Chest"] = function () return has('MASK_DEKU') or can_hookshot_short() end,
            ["Woodfall Temple SF Entrance"] = function () return true end,
            ["Woodfall Temple Pot Entrance"] = function () return true end,
            ["Woodfall Temple Grass Entrance Bottom 1"] = function () return true end,
            ["Woodfall Temple Grass Entrance Bottom 2"] = function () return true end,
            ["Woodfall Temple Grass Entrance Bottom 3"] = function () return true end,
            ["Woodfall Temple Grass Entrance Ledge 1"] = function () return has('MASK_DEKU') or can_hookshot_short() end,
            ["Woodfall Temple Grass Entrance Ledge 2"] = function () return has('MASK_DEKU') or can_hookshot_short() end,
        },
    },
    ["Woodfall Temple Main"] = {
        ["events"] = {
            ["WOODFALL_TEMPLE_MAIN_FLOWER"] = function () return can_use_fire_short_range() end,
            ["STICKS"] = function () return soul_deku_baba() and can_kill_baba_sticks() end,
            ["NUTS"] = function () return soul_deku_baba() and (has('MASK_DEKU') or has_arrows() or has_explosives() or can_fight()) end,
            ["BOMBS_OR_BOMBCHU"] = function () return true end,
            ["ARROWS"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple Entrance"] = function () return true end,
            ["Woodfall Temple Water Room"] = function () return true end,
            ["Woodfall Temple Maze"] = function () return small_keys_wf(1) end,
            ["Woodfall Temple Main Ledge"] = function () return event('WOODFALL_TEMPLE_MAIN_FLOWER') or event('WOODFALL_TEMPLE_MAIN_LADDER') or can_hookshot_short() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Main Pot"] = function () return true end,
            ["Woodfall Temple SF Main Deku Baba"] = function () return soul_deku_baba() end,
            ["Woodfall Temple Pot Main Room Lower 1"] = function () return true end,
            ["Woodfall Temple Pot Main Room Lower 2"] = function () return true end,
            ["Woodfall Temple Pot Main Room Lower 3"] = function () return true end,
            ["Woodfall Temple Pot Main Room Lower 4"] = function () return true end,
            ["Woodfall Temple Pot Main Room Lower 5"] = function () return true end,
            ["Woodfall Temple Pot Main Room Lower 6"] = function () return true end,
            ["Woodfall Temple Grass Main Room 1"] = function () return true end,
            ["Woodfall Temple Grass Main Room 2"] = function () return true end,
            ["Woodfall Temple Grass Main Room 3"] = function () return true end,
        },
    },
    ["Woodfall Temple Water Room"] = {
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Map Room"] = function () return has('MASK_DEKU') or can_hookshot_short() or can_use_ice_arrows() or event('WOODFALL_TEMPLE_MAIN_FLOWER') or (has_arrows() and (has_weapon() or has_mask_goron() or has_hover_boots())) end,
            ["Woodfall Temple Water Room Upper"] = function () return has_arrows() and (has('MASK_DEKU') or has_hover_boots()) or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Water Chest"] = function () return has('MASK_DEKU') or can_hookshot() or (can_hookshot_short() and event('WOODFALL_TEMPLE_MAIN_FLOWER')) or can_use_ice_arrows() end,
            ["Woodfall Temple SF Water Room Beehive"] = function () return has_arrows() or can_use_deku_bubble() or (has('MASK_GREAT_FAIRY') and (has_bombchu() or has_mask_zora() or can_hookshot())) end,
            ["Woodfall Temple Grass Water Room 1"] = function () return true end,
            ["Woodfall Temple Grass Water Room 2"] = function () return true end,
        },
    },
    ["Woodfall Temple Map Room"] = {
        ["exits"] = {
            ["Woodfall Temple Water Room"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Map"] = function () return soul_enemy(SOUL_ENEMY_SNAPPER) and (has('MASK_DEKU') or has_explosives() or has_mask_goron()) end,
            ["Woodfall Temple Grass Map Room 1"] = function () return true end,
            ["Woodfall Temple Grass Map Room 2"] = function () return true end,
            ["Woodfall Temple Grass Map Room 3"] = function () return true end,
            ["Woodfall Temple Grass Map Room 4"] = function () return true end,
            ["Woodfall Temple Grass Map Room 5"] = function () return true end,
        },
    },
    ["Woodfall Temple Maze"] = {
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Compass Room"] = function () return has_sticks() or can_use_fire_short_range() end,
            ["Woodfall Temple Dark Room"] = function () return has_sticks() or can_use_fire_short_range() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Maze Skulltula"] = function () return soul_skulltula() and (can_fight() or has_weapon_range() or has_explosives()) end,
            ["Woodfall Temple SF Maze Beehive"] = function () return has_weapon_range() or has_explosives() end,
            ["Woodfall Temple SF Maze Bubble"] = function () return has('MASK_GREAT_FAIRY') and (has_arrows() or can_hookshot_short()) or event('WOODFALL_TEMPLE_MAIN_FLOWER') or can_use_nayru() end,
            ["Woodfall Temple Pot Maze 1"] = function () return true end,
            ["Woodfall Temple Pot Maze 2"] = function () return true end,
        },
    },
    ["Woodfall Temple Compass Room"] = {
        ["exits"] = {
            ["Woodfall Temple Maze"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Compass"] = function () return soul_enemy(SOUL_ENEMY_DRAGONFLY) end,
            ["Woodfall Temple Grass Compass Room 1"] = function () return true end,
            ["Woodfall Temple Grass Compass Room 2"] = function () return true end,
            ["Woodfall Temple Grass Compass Room 3"] = function () return true end,
        },
    },
    ["Woodfall Temple Dark Room"] = {
        ["exits"] = {
            ["Woodfall Temple Maze"] = function () return has_sticks() or has_arrows() end,
            ["Woodfall Temple Pits Room"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Dark Chest"] = function () return soul_enemy(SOUL_ENEMY_BOE) end,
        },
    },
    ["Woodfall Temple Pits Room"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Dark Room"] = function () return true end,
            ["Woodfall Temple Main Ledge"] = function () return has('MASK_DEKU') or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Grass Pits Room 01"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 02"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 03"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 04"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 05"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 06"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 07"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 08"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 09"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 10"] = function () return true end,
            ["Woodfall Temple Grass Pits Room 11"] = function () return true end,
        },
    },
    ["Woodfall Temple Main Ledge"] = {
        ["events"] = {
            ["WOODFALL_TEMPLE_MAIN_FLOWER"] = function () return has_arrows() end,
            ["WOODFALL_TEMPLE_MAIN_LADDER"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Pits Room"] = function () return true end,
            ["Woodfall Temple Pre-Boss"] = function () return has_arrows() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Center Chest"] = function () return has('MASK_DEKU') or short_hook_anywhere() or has_hover_boots() end,
            ["Woodfall Temple SF Main Bubble"] = function () return true end,
            ["Woodfall Temple Pot Main Room Upper 1"] = function () return true end,
            ["Woodfall Temple Pot Main Room Upper 2"] = function () return true end,
        },
    },
    ["Woodfall Temple Water Room Upper"] = {
        ["exits"] = {
            ["Woodfall Temple Main Ledge"] = function () return true end,
            ["Woodfall Temple Water Room"] = function () return true end,
            ["Woodfall Temple Bow Room"] = function () return true end,
            ["Woodfall Temple Boss Key Room"] = function () return has_arrows() and has('MASK_DEKU') or (short_hook_anywhere() and event('WOODFALL_TEMPLE_MAIN_FLOWER')) or hookshot_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Water Chest"] = function () return has_hover_boots() end,
            ["Woodfall Temple Pot Water Room 1"] = function () return true end,
            ["Woodfall Temple Pot Water Room 2"] = function () return true end,
            ["Woodfall Temple Pot Water Room 3"] = function () return true end,
            ["Woodfall Temple Pot Water Room 4"] = function () return true end,
        },
    },
    ["Woodfall Temple Bow Room"] = {
        ["exits"] = {
            ["Woodfall Temple Water Room Upper"] = function () return can_fight() or has_arrows() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Bow"] = function () return soul_lizalfos_dinalfos() and (can_fight() or has_arrows()) end,
        },
    },
    ["Woodfall Temple Boss Key Room"] = {
        ["exits"] = {
            ["Woodfall Temple Boss Key Room Cage"] = function () return soul_enemy(SOUL_ENEMY_GEKKO) and has_arrows() and (has('MASK_DEKU') or has_mask_goron() or has_explosives()) end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Woodfall Temple Boss Key Room Cage"] = {
        ["events"] = {
            ["FROG_2"] = function () return has('MASK_DON_GERO') end,
        },
        ["exits"] = {
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Boss Key Chest"] = function () return true end,
            ["Woodfall Temple Pot Miniboss Room 1"] = function () return true end,
            ["Woodfall Temple Pot Miniboss Room 2"] = function () return true end,
            ["Woodfall Temple Pot Miniboss Room 3"] = function () return true end,
            ["Woodfall Temple Pot Miniboss Room 4"] = function () return true end,
        },
    },
    ["Woodfall Temple Pre-Boss"] = {
        ["exits"] = {
            ["Woodfall Temple Pre-Boss Ledge"] = function () return can_hookshot() or has('MASK_DEKU') or short_hook_anywhere() end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Pre-Boss Bottom Right"] = function () return true end,
            ["Woodfall Temple SF Pre-Boss Left"] = function () return has('MASK_DEKU') or has('MASK_GREAT_FAIRY') or short_hook_anywhere() end,
            ["Woodfall Temple SF Pre-Boss Top Right"] = function () return true end,
            ["Woodfall Temple SF Pre-Boss Pillar"] = function () return has('MASK_DEKU') or has('MASK_GREAT_FAIRY') or short_hook_anywhere() end,
            ["Woodfall Temple Grass Pre-Boss 1"] = function () return true end,
            ["Woodfall Temple Grass Pre-Boss 2"] = function () return true end,
            ["Woodfall Temple Grass Pre-Boss 3"] = function () return true end,
            ["Woodfall Temple Grass Pre-Boss 4"] = function () return true end,
            ["Woodfall Temple Grass Pre-Boss 5"] = function () return true end,
            ["Woodfall Temple Rupee Lower 1"] = function () return true end,
            ["Woodfall Temple Rupee Lower 2"] = function () return true end,
            ["Woodfall Temple Rupee Lower 3"] = function () return true end,
            ["Woodfall Temple Rupee Lower 4"] = function () return true end,
        },
    },
    ["Woodfall Temple Pre-Boss Ledge"] = {
        ["exits"] = {
            ["Woodfall Temple Boss Access"] = function () return boss_key(BOSS_KEY_WF) end,
            ["WARP_SONGS"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Pot Pre-Boss 1"] = function () return true end,
            ["Woodfall Temple Pot Pre-Boss 2"] = function () return true end,
            ["Woodfall Temple Rupee Upper Left"] = function () return has_mask_zora() or short_hook_anywhere() or (can_use_ice_arrows() and trick('MM_WFT_RUPEES_ICE')) or has_hover_boots() end,
            ["Woodfall Temple Rupee Upper Right"] = function () return has('MASK_DEKU') or has_mask_zora() or hookshot_anywhere() or (can_use_ice_arrows() and trick('MM_WFT_RUPEES_ICE')) or has_hover_boots() end,
        },
    },
    ["Woodfall Temple Princess Jail"] = {
        ["events"] = {
            ["DEKU_PRINCESS"] = function () return has_weapon() and soul_npc(SOUL_NPC_DEKU_PRINCESS) end,
        },
        ["exits"] = {
            ["Woodfall"] = function () return true end,
            ["WARP_SONGS"] = function () return true end,
        },
    },
    ["Woodfall Temple Boss Access"] = {
        ["exits"] = {
            ["Woodfall Temple Boss"] = function () return true end,
        },
    },
    ["Woodfall Temple Boss"] = {
        ["exits"] = {
            ["Woodfall Temple After Boss"] = function () return soul_boss(SOUL_BOSS_ODOLWA) and (has('MASK_FIERCE_DEITY') and has_magic() or (has_arrows() and can_fight())) end,
            ["WARP_SONGS"] = function () return can_reset_time() end,
        },
        ["locations"] = {
            ["Woodfall Temple Boss Grass 01"] = function () return true end,
            ["Woodfall Temple Boss Grass 02"] = function () return true end,
            ["Woodfall Temple Boss Grass 03"] = function () return true end,
            ["Woodfall Temple Boss Grass 04"] = function () return true end,
            ["Woodfall Temple Boss Grass 05"] = function () return true end,
            ["Woodfall Temple Boss Grass 06"] = function () return true end,
            ["Woodfall Temple Boss Grass 07"] = function () return true end,
            ["Woodfall Temple Boss Grass 08"] = function () return true end,
            ["Woodfall Temple Boss Grass 09"] = function () return true end,
            ["Woodfall Temple Boss Grass 10"] = function () return true end,
            ["Woodfall Temple Boss Grass 11"] = function () return true end,
            ["Woodfall Temple Boss Grass 12"] = function () return true end,
            ["Woodfall Temple Boss Grass 13"] = function () return true end,
            ["Woodfall Temple Boss Grass 14"] = function () return true end,
            ["Woodfall Temple Boss Grass 15"] = function () return true end,
            ["Woodfall Temple Boss Grass 16"] = function () return true end,
        },
    },
    ["Woodfall Temple After Boss"] = {
        ["events"] = {
            ["BOSS_WOODFALL"] = function () return true end,
        },
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Boss Container"] = function () return true end,
            ["Woodfall Temple Boss"] = function () return true end,
        },
    },
}

    return M
end
