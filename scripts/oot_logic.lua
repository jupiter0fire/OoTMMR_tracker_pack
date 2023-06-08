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
        }
        SearchQueue = Queue:new() -- List of nodes, source: internal and external
    end

    function get_reachable_events()
        return OOTMM_RUNTIME_STATE.events_active
    end

    OOTMM_ITEM_PREFIX = "OOT"
    OOTMM_TRICK_PREFIX = "TRICK"

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
    }

    function has(item, min_count, use_prefix)
        if use_prefix == nil then
            use_prefix = true
        end

        if min_count and OOTMM_HAS_OVERRIDES[item .. ":" .. min_count] then
            item, min_count = parse_item_override(OOTMM_HAS_OVERRIDES[item .. ":" .. min_count])
        elseif min_count == nil and OOTMM_HAS_OVERRIDES[item] then
            item, min_count = parse_item_override(OOTMM_HAS_OVERRIDES[item])
        end

        local item_code = ""
        if not use_prefix or string.match(item, "^setting_") or string.match(item, "^TRICK_") or string.match(item, "^EVENT_") then
            -- These are already prefixed as needed
            -- FIXME: There are now MM_* or OOT_* has() calls, so we will need to allow those as well.
            item_code = item
        else
            -- Function got called from raw converted logic without an item prefix.
            -- EmoTracker knows these items as "OOT_*"" / "MM_*"
            item_code = OOTMM_ITEM_PREFIX .. "_" .. item
        end

        local count = 0
        count = get_tracker_count(item_code)

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

    -- Events are active if they CAN LOGICALLY BE reached, not when they HAVE BEEN reached.
    -- Checks show up as green when you actually need to do other things first,
    -- and the sequence of tasks necessary is not obvious unless you're intimately familiar
    -- with the randomizer's logic.
    --
    -- These are used to override the default behavior, and make the tracker more
    -- user friendly.
    OOTMM_EVENT_OVERRIDES = {
        ["BOMBER_CODE"] = { ["type"] = "has" },
        ["FROG_1"] = { ["type"] = "has" },
        ["FROG_2"] = { ["type"] = "has" },
        ["FROG_3"] = { ["type"] = "has" },
        ["FROG_4"] = { ["type"] = "has" },
        ["MALON"] = { ["type"] = "has" },
        ["MEET_ZELDA"] = { ["type"] = "has" },
        ["NUTS"] = { ["type"] = "return", ["value"] = false },
        ["SEAHORSE"] = { ["type"] = "has" },
        ["STICKS"] = { ["type"] = "return", ["value"] = false },
        ["ZORA_EGGS_BARREL_MAZE"] = { ["type"] = "has" },
        ["ZORA_EGGS_HOOKSHOT_ROOM"] = { ["type"] = "has" },
        ["ZORA_EGGS_LONE_GUARD"] = { ["type"] = "has" },
        ["ZORA_EGGS_PINNACLE_ROCK"] = { ["type"] = "has" },
        ["ZORA_EGGS_TREASURE_ROOM"] = { ["type"] = "has" },
    }
    function event(x)
        if OOTMM_EVENT_OVERRIDES[x] then
            if OOTMM_EVENT_OVERRIDES[x]["type"] == "return" then
                return OOTMM_EVENT_OVERRIDES[x]["value"]
            elseif OOTMM_EVENT_OVERRIDES[x]["type"] == "has" then
                return has("EVENT_" .. x)
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

    OOTMM_SETTING_OVERRIDES = {
        ["childWallets"] = false,
        ["crossWarpMm_childOnly"] = false,
        ["crossWarpMm_full"] = false,
        ["fairyOcarinaMm"] = false,
        ["progressiveGoronLullaby_progressive"] = true,
        ["progressiveShieldsMm_progressive"] = false,
        ["progressiveShieldsOot_progressive"] = false,
        ["progressiveSwordsOot_progressive"] = false,
        ["sharedOcarina"] = false,
        ["shortHookshotMm"] = true,
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

        return has("setting_" .. item_name)
    end

    OOTMM_SPECIAL_ACCESS_CASES = {
        ["BRIDGE"] = true,
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

    function oot_time(x)
        -- FIXME
        return true
    end

    local OOTMM_RUNTIME_CURRENT_TIME = nil
    function mm_time(case, time)
        OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] = true

        if OOTMM_DEBUG then
            print("case", case, "time", time, "index", MM_TIME_SLICES_INDEX[time], "earliest_time",
                OOTMM_RUNTIME_CURRENT_TIME)
        end
        local r = _mm_time(case, time)
        if OOTMM_DEBUG then
            print("mm_time:", case, time, r)
        end
        return r
    end

    function _mm_time(case, time)
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
            return OOTMM_RUNTIME_CURRENT_TIME == MM_TIME_SLICES_INDEX[time]
        elseif case == "before" then
            return MM_TIME_SLICES_INDEX[time] > OOTMM_RUNTIME_CURRENT_TIME
        elseif case == "after" then
            return MM_TIME_SLICES_INDEX[time] <= OOTMM_RUNTIME_CURRENT_TIME
        else
            print(case)
            error("Invalid case: " .. case)
        end
    end

    local function set_time(time_index)
        OOTMM_RUNTIME_CURRENT_TIME = time_index
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

    local function check_rule(rule, earliest_time, used_events)
        -- Check the rule and return its result as well as all used events.
        OOTMM_RUNTIME_STATE["_check_rule_events_used"] = {}
        OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] = false

        if earliest_time == nil then
            earliest_time = 1
        end

        -- Find the earliest time for which the rule is true by iterating over all possible times, starting at the previous earliest_time.
        set_time(earliest_time)
        local result = rule()

        while not result and OOTMM_RUNTIME_STATE["_check_rule_mm_time_used"] and earliest_time < #MM_TIME_SLICES do
            earliest_time = earliest_time + 1
            set_time(earliest_time)
            result = rule()
        end

        -- Try to find events used even for rules like this (an exit):
        --   ["Near Romani Ranch"] = function () return after(DAY3_AM_06_00) or can_use_keg() end,
        -- where, if can_use_keg() is true, the time at which we can reach "Near Romani Ranch" could be earlier than DAY3_AM_06_00.
        -- This means that this node will have to revisited once the BUY_KEG event is active, but if we first reach this
        -- node at DAY3_AM_06_00, we will never trigger the BUY_KEG event check.
        --
        -- TODO: Make sure there is no combination of rules for which this STILL won't return used events...
        set_time(-1)            -- Make all time checks return false
        local _ignored = rule() -- We don't care about the result, we just want to check which events were used.

        if not result then
            earliest_time = nil
        end

        if used_events == nil then
            used_events = {}
        end

        for k, _ in pairs(OOTMM_RUNTIME_STATE["_check_rule_events_used"]) do
            used_events[k] = true
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
                active.child, earliest_child, events_used, mm_time_used_child = check_rule(current.rule, current.child,
                    events_used)
            end
            if current.adult then
                set_age("adult")
                active.adult, earliest_adult, events_used, mm_time_used_adult = check_rule(current.rule, current.adult,
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
                            for new_name, new_rule in pairs(new_rules) do
                                local node = new_node(activated_current)
                                node.type = string.sub(new_type, 1, -2) -- exits -> exit; events -> event; locations -> location
                                node.name = new_name
                                node.rule = new_rule
                                node.child = earliest_child
                                node.adult = earliest_adult

                                SearchQueue:push(node)
                            end
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

    	function is_child()
		return age('child')
	end

	function is_adult()
		return age('adult')
	end

	function is_day()
		return oot_time('day') or can_play(SONG_SUN)
	end

	function is_night()
		return oot_time('night') or can_play(SONG_SUN)
	end

	function is_dusk()
		return oot_time('day') and oot_time('night')
	end

	function can_play(x)
		return has('OCARINA') and has(x)
	end

	function has_sticks()
		return event('STICKS') or renewable(STICK) or renewable(STICKS_5) or renewable(STICKS_10) or (setting('sharedNutsSticks') and event('MM_STICKS'))
	end

	function has_nuts()
		return event('NUTS') or renewable(NUT) or renewable(NUTS_5) or renewable(NUTS_10) or (setting('sharedNutsSticks') and event('MM_NUTS'))
	end

	function can_use_sticks()
		return age_sticks() and has_sticks()
	end

	function has_bombs()
		return has('BOMB_BAG') and (event('BOMBS') or renewable(BOMBS_5) or renewable(BOMBS_10) or renewable(BOMBS_20) or renewable(BOMBS_30) or (setting('sharedBombBags') and event('MM_BOMBS')))
	end

	function has_bombchu()
		return has('BOMB_BAG') and (event('BOMBCHUS') or renewable(BOMBCHU_1) or renewable(BOMBCHU_5) or renewable(BOMBCHU_10) or renewable(BOMBCHU_20))
	end

	function can_use_slingshot()
		return is_child() and has('SLINGSHOT') and (event('SEEDS') or renewable(DEKU_SEEDS_30))
	end

	function can_use_bow()
		return is_adult() and has('BOW') and (event('ARROWS') or renewable(ARROWS_5) or renewable(ARROWS_10) or renewable(ARROWS_30) or renewable(ARROWS_40) or (setting('sharedBows') and event('MM_ARROWS')))
	end

	function can_hookshot()
		return is_adult() and has('HOOKSHOT')
	end

	function can_longshot()
		return is_adult() and has('HOOKSHOT', 2)
	end

	function can_boomerang()
		return age_boomerang() and has('BOOMERANG')
	end

	function can_hammer()
		return age_hammer() and has('HAMMER')
	end

	function has_bottle()
		return has('BOTTLE_EMPTY') or has('BOTTLE_MILK') or event('KING_ZORA_LETTER')
	end

	function can_use_beans()
		return is_child() and has('MAGIC_BEAN')
	end

	function age_sticks()
		return is_child() or setting('agelessSticks')
	end

	function age_boomerang()
		return is_child() or setting('agelessBoomerang')
	end

	function age_hammer()
		return is_adult() or setting('agelessHammer')
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

	function has_sword_kokiri()
		return cond(setting('progressiveSwordsOot', 'progressive'), has('SWORD'), has('SWORD_KOKIRI'))
	end

	function has_sword_master()
		return cond(setting('progressiveSwordsOot', 'progressive'), has('SWORD', 2), has('SWORD_MASTER'))
	end

	function has_sword_goron()
		return cond(setting('progressiveSwordsOot', 'progressive'), has('SWORD', 3), cond(setting('progressiveSwordsOot', 'goron'), has('SWORD_GORON'), has('SWORD_KNIFE') or has('SWORD_BIGGORON')))
	end

	function has_weapon()
		return can_use_sword()
	end

	function can_use_sword()
		return age_sword_child() and has_sword_kokiri() or (age_sword_adult() and (has_sword_master() or has_sword_goron()))
	end

	function has_shield()
		return renewable(SHIELD_HYLIAN) or has_mirror_shield() or (age_shield_child() and renewable(SHIELD_DEKU))
	end

	function has_shield_for_scrubs()
		return is_adult() and renewable(SHIELD_HYLIAN) or (age_shield_child() and renewable(SHIELD_DEKU))
	end

	function has_mirror_shield()
		return age_shield_adult() and cond(setting('progressiveShieldsOot', 'progressive'), has('SHIELD', 3), has('SHIELD_MIRROR'))
	end

	function has_rupees()
		return event('RUPEES') or (setting('sharedWallets') and event('MM_RUPEES'))
	end

	function stone_of_agony()
		return has('STONE_OF_AGONY') or trick('OOT_HIDDEN_GROTTOS')
	end

	function has_tunic_goron_strict()
		return age_tunics() and has('TUNIC_GORON')
	end

	function has_tunic_zora_strict()
		return age_tunics() and has('TUNIC_ZORA')
	end

	function has_tunic_goron()
		return has_tunic_goron_strict() or trick('OOT_TUNICS')
	end

	function has_tunic_zora()
		return has_tunic_zora_strict() or trick('OOT_TUNICS')
	end

	function has_iron_boots()
		return age_boots() and has('BOOTS_IRON')
	end

	function has_hover_boots()
		return age_boots() and has('BOOTS_HOVER')
	end

	function can_lift_silver()
		return is_adult() and has('STRENGTH', 2)
	end

	function can_lift_gold()
		return is_adult() and has('STRENGTH', 3)
	end

	function has_magic()
		return has('MAGIC_UPGRADE') and (event('MAGIC') or (setting('sharedMagic') and event('MM_MAGIC')) or (has_bottle() and (renewable(POTION_GREEN) or renewable(POTION_BLUE) or renewable(CHATEAU))))
	end

	function can_use_din()
		return has_magic() and has('SPELL_FIRE')
	end

	function can_use_nayru()
		return has_magic() and has('SPELL_LOVE')
	end

	function has_light_arrows()
		return can_use_bow() and has('ARROW_LIGHT') and has_magic()
	end

	function has_fire_arrows()
		return can_use_bow() and has('ARROW_FIRE') and has_magic()
	end

	function has_lens_strict()
		return has_magic() and has('LENS')
	end

	function has_explosives()
		return has_bombs() or has_bombchu()
	end

	function has_bombflowers()
		return has_explosives() or has('STRENGTH')
	end

	function has_explosives_or_hammer()
		return has_explosives() or can_hammer()
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
		return can_hookshot() and event('SCARECROW')
	end

	function scarecrow_longshot()
		return can_longshot() and event('SCARECROW')
	end

	function has_fire()
		return has_fire_arrows() or can_use_din()
	end

	function has_fire_or_sticks()
		return can_use_sticks() or has_fire()
	end

	function can_dive_small()
		return has('SCALE') or has_iron_boots()
	end

	function can_dive_big()
		return has('SCALE', 2) or has_iron_boots()
	end

	function hidden_grotto_bomb()
		return stone_of_agony() and has_explosives_or_hammer()
	end

	function hidden_grotto_storms()
		return stone_of_agony() and can_play(SONG_STORMS)
	end

	function has_spiritual_stones()
		return has('STONE_EMERALD') and has('STONE_RUBY') and has('STONE_SAPPHIRE')
	end

	function can_ride_epona()
		return is_adult() and can_play(SONG_EPONA)
	end

	function gs_soil()
		return is_child() and has_bottle() and (renewable(BUGS) or event('BUGS'))
	end

	function adult_trade(x)
		return is_adult() and has(x)
	end

	function has_blue_fire()
		return has_bottle() and (event('BLUE_FIRE') or renewable(BLUE_FIRE))
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

	function can_cut_grass()
		return has_weapon() or can_boomerang() or has('STRENGTH')
	end

	function can_kill_baba_sticks()
		return can_boomerang() or (has_weapon() and (is_child() or has_nuts() or can_hookshot() or can_hammer()))
	end

	function can_kill_baba_nuts()
		return has_weapon() or has_explosives() or can_use_slingshot()
	end

	function can_hit_scrub()
		return has_nuts() or can_hit_triggers_distance() or has_shield_for_scrubs() or can_collect_distance() or can_hammer()
	end

	function has_small_key_gerudo()
		return setting('gerudoFortress', 'open') or cond(setting('gerudoFortress', 'single'), has('SMALL_KEY_GF', 1), has('SMALL_KEY_GF', 4))
	end

	function can_rescue_carpenter()
		return has_small_key_gerudo() and (has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks()))
	end

	function carpenters_rescued()
		return setting('gerudoFortress', 'open') or (event('CARPENTER_1') and (setting('gerudoFortress', 'single') or (event('CARPENTER_2') or event('CARPENTER_3') or event('CARPENTER_4'))))
	end

	function gs_night()
		return is_night() and (trick('OOT_NIGHT_GS') or can_play(SONG_SUN))
	end

	function has_lens()
		return has_lens_strict() or trick('OOT_LENS')
	end

	function trick_mido()
		return trick('OOT_MIDO_SKIP') and (has('BOW') or has('HOOKSHOT') or has('ARROW_FIRE') or has('ARROW_LIGHT'))
	end

	function met_zelda()
		return event('MEET_ZELDA') or setting('skipZelda')
	end

	function woke_talon_child()
		return event('TALON_CHILD') or setting('skipZelda')
	end

	function has_fire_spirit()
		return has_magic() and (has('BOW') and has('ARROW_FIRE') and has_sticks() and (event('ARROWS') or renewable(ARROWS_5) or renewable(ARROWS_10) or renewable(ARROWS_30) or renewable(ARROWS_40) or (setting('sharedBows') and event('MM_ARROWS'))) or has('SPELL_FIRE')) and (has_explosives() or small_keys(SMALL_KEY_SPIRIT, 2))
	end

	function has_ranged_weapon_both()
		return has_explosives() or ((has('SLINGSHOT') and (event('SEEDS') or renewable(DEKU_SEEDS_30)) or has('BOOMERANG')) and (has('HOOKSHOT') or (has('BOW') or (event('ARROWS') or renewable(ARROWS_5) or renewable(ARROWS_10) or renewable(ARROWS_30) or renewable(ARROWS_40) or (setting('sharedBows') and event('MM_ARROWS'))))))
	end

	function can_collect_ageless()
		return has('HOOKSHOT') and has('BOOMERANG')
	end

	function has_small_keys_fire(x)
		return setting('smallKeyShuffleOot', 'removed') or cond(setting('smallKeyShuffleOot', 'anywhere'), has('SMALL_KEY_FIRE', x + 1), has('SMALL_KEY_FIRE', x))
	end

	function king_zora_moved()
		return event('KING_ZORA_LETTER') or setting('zoraKing', 'open') or (setting('zoraKing', 'adult') and is_adult())
	end

	function can_move_mido()
		return is_child() and has_sword_kokiri() and renewable(SHIELD_DEKU)
	end

	function mido_moved()
		return setting('dekuTree', 'open') or is_adult() or event('MIDO_MOVED')
	end

	function has_wallet(n)
		return cond(setting('childWallets'), has('WALLET', n), has('WALLET', n - 1))
	end

	function can_use_wallet(n)
		return has_rupees() and has_wallet(n)
	end

	function boss_key(x)
		return setting('bossKeyShuffleOot', 'removed') or has(x)
	end

	function small_keys(x, count)
		return setting('smallKeyShuffleOot', 'removed') or has(x, count)
	end


    logic = {
    ["Deku Tree Boss"] = {
        ["locations"] = {
            ["Deku Tree Boss Container"] = function () return (has_nuts() or can_use_slingshot()) and (can_use_sticks() or has_weapon()) end,
            ["Deku Tree Boss"] = function () return (has_nuts() or can_use_slingshot()) and (can_use_sticks() or has_weapon()) end,
        },
    },
    ["Dodongo Cavern Boss"] = {
        ["exits"] = {
            ["Dodongo Cavern After Boss"] = function () return has_explosives() end,
        },
        ["locations"] = {
            ["Dodongo Cavern Boss Chest"] = function () return true end,
        },
    },
    ["Dodongo Cavern After Boss"] = {
        ["locations"] = {
            ["Dodongo Cavern Boss Container"] = function () return (has_bombs() or has('STRENGTH')) and (can_use_sticks() or has_weapon()) end,
            ["Dodongo Cavern Boss"] = function () return (has_bombs() or has('STRENGTH')) and (can_use_sticks() or has_weapon()) end,
        },
    },
    ["Jabu-Jabu Boss"] = {
        ["exits"] = {
            ["Jabu-Jabu After Boss"] = function () return can_boomerang() and (can_use_sticks() or has_weapon()) end,
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
            ["Forest Temple After Boss"] = function () return (has_ranged_weapon_adult() or can_use_slingshot()) and has_weapon() end,
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
            ["Fire Temple After Boss"] = function () return can_hammer() and has_tunic_goron_strict() end,
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
            ["Water Temple After Boss"] = function () return can_hookshot() and has_weapon() end,
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
            ["Spirit Temple After Boss"] = function () return has_mirror_shield() end,
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
            ["Shadow Temple After Boss"] = function () return has_weapon() and has_lens() and (can_use_bow() or can_use_slingshot()) end,
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
            ["Bottom of the Well Main"] = function () return is_child() and (has_nuts() or has_weapon() or has_explosives() or has_ranged_weapon_child()) end,
        },
    },
    ["Bottom of the Well Main"] = {
        ["events"] = {
            ["STICKS"] = function () return true end,
        },
        ["exits"] = {
            ["Bottom of the Well"] = function () return true end,
        },
        ["locations"] = {
            ["Bottom of the Well Compass"] = function () return has_lens() end,
            ["Bottom of the Well Under Debris"] = function () return has_explosives() end,
            ["Bottom of the Well Back West"] = function () return has_explosives() and has_lens() end,
            ["Bottom of the Well East"] = function () return has_lens() end,
            ["Bottom of the Well Front West"] = function () return has_lens() end,
            ["Bottom of the Well Underwater"] = function () return can_play(SONG_ZELDA) end,
            ["Bottom of the Well East Cage"] = function () return small_keys(SMALL_KEY_BOTW, 3) and has_lens() end,
            ["Bottom of the Well Blood Chest"] = function () return has_lens() end,
            ["Bottom of the Well Underwater 2"] = function () return can_play(SONG_ZELDA) end,
            ["Bottom of the Well Map"] = function () return has_explosives() or (has_bombflowers() and (small_keys(SMALL_KEY_BOTW, 3) or can_use_din())) end,
            ["Bottom of the Well Coffin"] = function () return true end,
            ["Bottom of the Well Pits"] = function () return has_lens() and small_keys(SMALL_KEY_BOTW, 3) end,
            ["Bottom of the Well Lens"] = function () return can_play(SONG_ZELDA) and (has_weapon() or (can_use_sticks() and trick('OOT_DEAD_HAND_STICKS'))) end,
            ["Bottom of the Well Lens Side Chest"] = function () return can_play(SONG_ZELDA) and has_lens() end,
            ["Bottom of the Well GS East Cage"] = function () return small_keys(SMALL_KEY_BOTW, 3) and has_lens() and can_boomerang() end,
            ["Bottom of the Well GS Inner West"] = function () return small_keys(SMALL_KEY_BOTW, 3) and has_lens() and can_boomerang() end,
            ["Bottom of the Well GS Inner East"] = function () return small_keys(SMALL_KEY_BOTW, 3) and has_lens() and can_boomerang() end,
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
            ["Deku Tree Slingshot Room"] = function () return has_shield_for_scrubs() end,
            ["Deku Tree Basement"] = function () return has_fire() or has_nuts() or has_weapon() or has_explosives() or has_ranged_weapon_child() end,
        },
        ["locations"] = {
            ["Deku Tree Map Chest"] = function () return true end,
            ["Deku Tree Compass Chest"] = function () return true end,
            ["Deku Tree Compass Room Side Chest"] = function () return true end,
            ["Deku Tree GS Compass"] = function () return can_damage_skull() end,
        },
    },
    ["Deku Tree Slingshot Room"] = {
        ["exits"] = {
            ["Deku Tree Lobby"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Tree Slingshot Chest"] = function () return true end,
            ["Deku Tree Slingshot Side Chest"] = function () return true end,
        },
    },
    ["Deku Tree Basement"] = {
        ["exits"] = {
            ["Deku Tree Lobby"] = function () return true end,
            ["Deku Tree Basement Back Room"] = function () return can_hit_triggers_distance() end,
            ["Deku Tree Basement Ledge"] = function () return trick('OOT_DEKU_SKIP') or is_adult() end,
        },
        ["locations"] = {
            ["Deku Tree Basement Chest"] = function () return true end,
            ["Deku Tree GS Basement Gate"] = function () return can_damage_skull() end,
            ["Deku Tree GS Basement Vines"] = function () return has_ranged_weapon() or can_use_din() or has('BOMB_BAG') end,
        },
    },
    ["Deku Tree Basement Back Room"] = {
        ["exits"] = {
            ["Deku Tree Basement Ledge"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Deku Tree GS Basement Back Room"] = function () return has_explosives_or_hammer() and can_collect_distance() end,
        },
    },
    ["Deku Tree Basement Ledge"] = {
        ["exits"] = {
            ["Deku Tree Basement Back Room"] = function () return is_child() end,
            ["Deku Tree Before Boss"] = function () return has_fire_or_sticks() end,
        },
    },
    ["Deku Tree Before Boss"] = {
        ["exits"] = {
            ["Deku Tree Basement Ledge"] = function () return true end,
            ["Deku Tree Boss"] = function () return has_shield_for_scrubs() end,
        },
    },
    ["Dodongo Cavern"] = {
        ["exits"] = {
            ["Death Mountain"] = function () return true end,
            ["Dodongo Cavern Main"] = function () return has_bombflowers() or can_hammer() end,
        },
    },
    ["Dodongo Cavern Main"] = {
        ["exits"] = {
            ["Dodongo Cavern"] = function () return true end,
            ["Dodongo Cavern Right Corridor"] = function () return true end,
            ["Dodongo Cavern Main Ledge"] = function () return is_adult() end,
            ["Dodongo Cavern Stairs"] = function () return event('DC_MAIN_SWITCH') end,
            ["Dodongo Cavern Skull"] = function () return event('DC_BOMB_EYES') end,
        },
        ["locations"] = {
            ["Dodongo Cavern Map Chest"] = function () return has_bombflowers() or can_hammer() end,
            ["Dodongo Cavern Lobby Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Dodongo Cavern Right Corridor"] = {
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Side Room"] = function () return true end,
            ["Dodongo Cavern Miniboss 1"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Scarecrow"] = function () return scarecrow_hookshot() end,
        },
    },
    ["Dodongo Cavern Side Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Right Corridor"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Side Room"] = function () return can_damage_skull() end,
        },
    },
    ["Dodongo Cavern Miniboss 1"] = {
        ["exits"] = {
            ["Dodongo Cavern Right Corridor"] = function () return can_use_sticks() or has_weapon() or can_use_slingshot() end,
            ["Dodongo Cavern Green Room"] = function () return can_use_sticks() or has_weapon() or can_use_slingshot() end,
        },
    },
    ["Dodongo Cavern Green Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Miniboss 1"] = function () return true end,
            ["Dodongo Cavern Green Side Room"] = function () return true end,
            ["Dodongo Cavern Main Ledge"] = function () return is_child() or has_fire() end,
        },
    },
    ["Dodongo Cavern Green Side Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Green Room"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern Green Side Room Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
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
            ["Dodongo Cavern Stairs Top"] = function () return has_bombflowers() or can_use_din() end,
        },
    },
    ["Dodongo Cavern Stairs Top"] = {
        ["exits"] = {
            ["Dodongo Cavern Stairs"] = function () return true end,
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Stairs Vines"] = function () return true end,
            ["Dodongo Cavern GS Stairs Top"] = function () return (can_hookshot() or can_boomerang()) and event('DC_SHORTCUT') end,
        },
    },
    ["Dodongo Cavern Compass Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Stairs"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern Compass Chest"] = function () return true end,
        },
    },
    ["Dodongo Cavern Bomb Bag Room 1"] = {
        ["exits"] = {
            ["Dodongo Cavern Stairs Top"] = function () return true end,
            ["Dodongo Cavern Bomb Bag Room 2"] = function () return can_longshot() or has_hover_boots() or (is_adult() and trick('OOT_DC_JUMP')) end,
            ["Dodongo Cavern Miniboss 2"] = function () return can_hit_triggers_distance() end,
            ["Dodongo Cavern Bomb Bag Side Room"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Dodongo Cavern Bomb Bag Side Chest"] = function () return true end,
        },
    },
    ["Dodongo Cavern Bomb Bag Side Room"] = {
        ["exits"] = {
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern Bomb Bag Side Room Left Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Dodongo Cavern Bomb Bag Side Room Right Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Dodongo Cavern Miniboss 2"] = {
        ["exits"] = {
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return can_use_sticks() or has_weapon() or can_use_slingshot() end,
            ["Dodongo Cavern Bomb Bag Room 2"] = function () return can_use_sticks() or has_weapon() or can_use_slingshot() end,
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
            ["Dodongo Cavern Bridge Chest"] = function () return has_explosives_or_hammer() end,
        },
    },
    ["Dodongo Cavern Skull"] = {
        ["exits"] = {
            ["Dodongo Cavern Main"] = function () return true end,
            ["Dodongo Cavern Boss"] = function () return true end,
        },
        ["locations"] = {
            ["Dodongo Cavern GS Near Boss"] = function () return true end,
        },
    },
    ["Fire Temple"] = {
        ["exits"] = {
            ["Fire Temple Entry"] = function () return true end,
            ["Fire Temple Lava Room"] = function () return has_small_keys_fire(1) end,
            ["Fire Temple Boss Key Loop"] = function () return cond(setting('smallKeyShuffleOot', 'anywhere'), small_keys(SMALL_KEY_FIRE, 8), true) and can_hammer() end,
            ["Fire Temple Pre-Boss"] = function () return true end,
        },
    },
    ["Fire Temple Pre-Boss"] = {
        ["events"] = {
            ["BOMBS"] = function () return has_tunic_goron() end,
        },
        ["exits"] = {
            ["Fire Temple"] = function () return true end,
            ["Fire Temple Boss"] = function () return boss_key(BOSS_KEY_FIRE) and (event('FIRE_TEMPLE_PILLAR_HAMMER') or has_hover_boots()) and has_tunic_goron() end,
        },
        ["locations"] = {
            ["Fire Temple Jail 1 Chest"] = function () return has_tunic_goron() end,
        },
    },
    ["Fire Temple Boss Key Loop"] = {
        ["locations"] = {
            ["Fire Temple Boss Key Side Chest"] = function () return true end,
            ["Fire Temple Boss Key Chest"] = function () return true end,
            ["Fire Temple GS Hammer Statues"] = function () return true end,
        },
    },
    ["Fire Temple Lava Room"] = {
        ["exits"] = {
            ["Fire Temple Maze"] = function () return has_small_keys_fire(3) and has_tunic_goron_strict() and has('STRENGTH') and (has_ranged_weapon_adult() or has_explosives()) end,
        },
        ["locations"] = {
            ["Fire Temple Jail 2 Chest"] = function () return is_adult() and has_tunic_goron() or (is_child() and trick('OOT_TUNICS') and can_play(SONG_TIME)) end,
            ["Fire Temple Jail 3 Chest"] = function () return is_adult() and has_tunic_goron() and has_explosives() end,
            ["Fire Temple GS Lava Side Room"] = function () return is_adult() and has_tunic_goron() and can_play(SONG_TIME) end,
        },
    },
    ["Fire Temple Maze"] = {
        ["exits"] = {
            ["Fire Temple Maze Upper"] = function () return has_small_keys_fire(5) end,
        },
        ["locations"] = {
            ["Fire Temple Maze Chest"] = function () return true end,
            ["Fire Temple Jail 4 Chest"] = function () return true end,
            ["Fire Temple GS Maze"] = function () return has_explosives() end,
            ["Fire Temple Map"] = function () return can_use_bow() and has_small_keys_fire(4) end,
        },
    },
    ["Fire Temple Maze Upper"] = {
        ["exits"] = {
            ["Fire Temple Ring"] = function () return has_small_keys_fire(6) end,
            ["Fire Temple Scarecrow"] = function () return scarecrow_hookshot() end,
        },
        ["locations"] = {
            ["Fire Temple Map"] = function () return true end,
            ["Fire Temple Above Maze Chest"] = function () return true end,
            ["Fire Temple Below Maze Chest"] = function () return has_explosives() end,
        },
    },
    ["Fire Temple Scarecrow"] = {
        ["locations"] = {
            ["Fire Temple Scarecrow Chest"] = function () return true end,
            ["Fire Temple GS Scarecrow Wall"] = function () return true end,
            ["Fire Temple GS Scarecrow Top"] = function () return true end,
        },
    },
    ["Fire Temple Ring"] = {
        ["exits"] = {
            ["Fire Temple Before Miniboss"] = function () return has_small_keys_fire(7) end,
            ["Fire Temple Pillar Ledge"] = function () return has_hover_boots() end,
        },
        ["locations"] = {
            ["Fire Temple Compass"] = function () return true end,
        },
    },
    ["Fire Temple Before Miniboss"] = {
        ["exits"] = {
            ["Fire Temple After Miniboss"] = function () return has_explosives() and (has_bombs() or can_hammer() or can_hookshot()) end,
            ["Fire Temple Pillar Ledge"] = function () return can_play(SONG_TIME) end,
        },
        ["locations"] = {
            ["Fire Temple Ring Jail"] = function () return can_hammer() and can_play(SONG_TIME) end,
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
            ["Forest Temple Main"] = function () return is_adult() or (has_nuts() or has_weapon() or has_explosives() or has_ranged_weapon_child()) end,
        },
        ["locations"] = {
            ["Forest Temple Tree Small Key"] = function () return true end,
            ["Forest Temple GS Entrance"] = function () return has_ranged_weapon() or has_explosives() or can_use_din() end,
        },
    },
    ["Forest Temple Main"] = {
        ["events"] = {
            ["FOREST_POE_4"] = function () return event('FOREST_POE_1') and event('FOREST_POE_2') and event('FOREST_POE_3') and can_use_bow() end,
        },
        ["exits"] = {
            ["Forest Temple"] = function () return true end,
            ["Forest Temple Mini-Boss"] = function () return true end,
            ["Forest Temple Garden West"] = function () return can_play(SONG_TIME) end,
            ["Forest Temple Garden East"] = function () return can_hit_triggers_distance() end,
            ["Forest Temple Maze"] = function () return small_keys(SMALL_KEY_FOREST, 1) end,
            ["Forest Temple Antichamber"] = function () return event('FOREST_POE_4') end,
        },
        ["locations"] = {
            ["Forest Temple GS Main"] = function () return can_collect_distance() end,
        },
    },
    ["Forest Temple Mini-Boss"] = {
        ["locations"] = {
            ["Forest Temple Mini-Boss Key"] = function () return has_weapon() end,
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
        },
        ["locations"] = {
            ["Forest Temple GS Garden West"] = function () return can_longshot() or (event('FOREST_LEDGE_REACHED') and can_collect_distance()) end,
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
        },
    },
    ["Forest Temple Floormaster"] = {
        ["locations"] = {
            ["Forest Temple Floormaster"] = function () return true end,
        },
    },
    ["Forest Temple Map Room"] = {
        ["exits"] = {
            ["Forest Temple Garden West"] = function () return can_use_bow() or has_explosives() or ((can_hookshot() or has_nuts() or can_boomerang() or has_shield()) and (has_weapon() or can_use_slingshot() or can_use_sticks())) end,
            ["Forest Temple Garden East Ledge"] = function () return can_use_bow() or has_explosives() or ((can_hookshot() or has_nuts() or can_boomerang() or has_shield()) and (has_weapon() or can_use_slingshot() or can_use_sticks())) end,
        },
        ["locations"] = {
            ["Forest Temple Map"] = function () return can_use_bow() or has_explosives() or ((can_hookshot() or has_nuts() or can_boomerang() or has_shield()) and (has_weapon() or can_use_slingshot() or can_use_sticks())) end,
        },
    },
    ["Forest Temple Garden East Ledge"] = {
        ["events"] = {
            ["FOREST_WELL"] = function () return true end,
        },
        ["exits"] = {
            ["Forest Temple Garden East"] = function () return true end,
        },
    },
    ["Forest Temple Garden East"] = {
        ["events"] = {
            ["STICKS"] = function () return can_hookshot() or can_hammer() or can_boomerang() or (has_nuts() and has_weapon()) end,
            ["NUTS"] = function () return is_adult() or has_weapon() or has_explosives() or can_use_slingshot() end,
        },
        ["exits"] = {
            ["Forest Temple Well"] = function () return event('FOREST_WELL') or can_dive_big() end,
            ["Forest Temple Garden East Ledge"] = function () return can_longshot() or (can_hookshot() and trick('OOT_FOREST_HOOK')) end,
        },
        ["locations"] = {
            ["Forest Temple Garden"] = function () return can_hookshot() end,
            ["Forest Temple GS Garden East"] = function () return can_hookshot() end,
        },
    },
    ["Forest Temple Well"] = {
        ["exits"] = {
            ["Forest Temple Garden West"] = function () return true end,
            ["Forest Temple Garden East"] = function () return true end,
        },
        ["locations"] = {
            ["Forest Temple Well"] = function () return event('FOREST_WELL') end,
        },
    },
    ["Forest Temple Maze"] = {
        ["exits"] = {
            ["Forest Temple Main"] = function () return true end,
            ["Forest Temple Garden West Ledge"] = function () return has_hover_boots() end,
            ["Forest Temple Twisted 1 Normal"] = function () return is_adult() and small_keys(SMALL_KEY_FOREST, 2) and has('STRENGTH') end,
            ["Forest Temple Twisted 1 Alt"] = function () return is_adult() and small_keys(SMALL_KEY_FOREST, 2) and has('STRENGTH') and can_hit_triggers_distance() end,
        },
        ["locations"] = {
            ["Forest Temple Maze"] = function () return has('STRENGTH') and can_hit_triggers_distance() end,
        },
    },
    ["Forest Temple Twisted 1 Normal"] = {
        ["exits"] = {
            ["Forest Temple Poe 1"] = function () return small_keys(SMALL_KEY_FOREST, 3) end,
        },
    },
    ["Forest Temple Twisted 1 Alt"] = {
        ["exits"] = {
            ["Forest Temple Garden West Ledge"] = function () return true end,
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
            ["Forest Temple Poe Key"] = function () return can_use_bow() end,
        },
    },
    ["Forest Temple Mini-Boss 2"] = {
        ["exits"] = {
            ["Forest Temple Poe 2"] = function () return has_weapon() end,
        },
        ["locations"] = {
            ["Forest Temple Bow"] = function () return has_weapon() end,
        },
    },
    ["Forest Temple Poe 2"] = {
        ["events"] = {
            ["FOREST_POE_2"] = function () return can_use_bow() end,
        },
        ["exits"] = {
            ["Forest Temple Twisted 2 Normal"] = function () return small_keys(SMALL_KEY_FOREST, 4) end,
        },
        ["locations"] = {
            ["Forest Temple Compass"] = function () return can_use_bow() end,
        },
    },
    ["Forest Temple Twisted 2 Normal"] = {
        ["exits"] = {
            ["Forest Temple Rotating Room"] = function () return small_keys(SMALL_KEY_FOREST, 5) end,
        },
    },
    ["Forest Temple Rotating Room"] = {
        ["exits"] = {
            ["Forest Temple Twisted 2 Alt"] = function () return can_use_bow() or can_use_din() end,
        },
    },
    ["Forest Temple Twisted 2 Alt"] = {
        ["exits"] = {
            ["Forest Temple Checkerboard"] = function () return true end,
        },
    },
    ["Forest Temple Checkerboard"] = {
        ["exits"] = {
            ["Forest Temple Poe 3"] = function () return true end,
        },
        ["locations"] = {
            ["Forest Temple Checkerboard"] = function () return true end,
        },
    },
    ["Forest Temple Poe 3"] = {
        ["events"] = {
            ["FOREST_POE_3"] = function () return can_use_bow() end,
        },
    },
    ["Forest Temple Antichamber"] = {
        ["exits"] = {
            ["Forest Temple Boss"] = function () return boss_key(BOSS_KEY_FOREST) end,
        },
        ["locations"] = {
            ["Forest Temple Antichamber"] = function () return true end,
            ["Forest Temple GS Antichamber"] = function () return can_collect_distance() end,
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
        },
        ["locations"] = {
            ["Ganon Castle Leftmost Scrub"] = function () return has_lens() and can_hit_scrub() and can_use_wallet(1) end,
            ["Ganon Castle Left-Center Scrub"] = function () return has_lens() and can_hit_scrub() and can_use_wallet(1) end,
            ["Ganon Castle Right-Center Scrub"] = function () return has_lens() and can_hit_scrub() and can_use_wallet(1) end,
            ["Ganon Castle Rightmost Scrub"] = function () return has_lens() and can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Ganon Castle Light"] = {
        ["events"] = {
            ["GANON_TRIAL_LIGHT"] = function () return small_keys(SMALL_KEY_GANON, 2) and can_hookshot() and has_lens() and has_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Light Chest Around 1"] = function () return true end,
            ["Ganon Castle Light Chest Around 2"] = function () return true end,
            ["Ganon Castle Light Chest Around 3"] = function () return true end,
            ["Ganon Castle Light Chest Around 4"] = function () return true end,
            ["Ganon Castle Light Chest Around 5"] = function () return true end,
            ["Ganon Castle Light Chest Around 6"] = function () return true end,
            ["Ganon Castle Light Chest Center"] = function () return has_lens() end,
            ["Ganon Castle Light Chest Lullaby"] = function () return small_keys(SMALL_KEY_GANON, 1) and can_play(SONG_ZELDA) end,
        },
    },
    ["Ganon Castle Forest"] = {
        ["events"] = {
            ["GANON_TRIAL_FOREST"] = function () return (has_fire_arrows() or (can_use_din() and has_ranged_weapon_adult())) and has_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Forest Chest"] = function () return true end,
        },
    },
    ["Ganon Castle Fire"] = {
        ["events"] = {
            ["GANON_TRIAL_FIRE"] = function () return has_tunic_goron_strict() and can_longshot() and can_lift_gold() and has_light_arrows() end,
        },
    },
    ["Ganon Castle Water"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return true end,
            ["GANON_TRIAL_WATER"] = function () return has_blue_fire() and can_hammer() and has_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Water Chest 1"] = function () return true end,
            ["Ganon Castle Water Chest 2"] = function () return true end,
        },
    },
    ["Ganon Castle Spirit"] = {
        ["events"] = {
            ["GANON_TRIAL_SPIRIT"] = function () return can_hookshot() and has_bombchu() and has_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Spirit Chest 1"] = function () return can_hookshot() end,
            ["Ganon Castle Spirit Chest 2"] = function () return can_hookshot() and has_bombchu() and has_lens() end,
        },
    },
    ["Ganon Castle Shadow"] = {
        ["events"] = {
            ["GANON_TRIAL_SHADOW"] = function () return can_hammer() and has_light_arrows() and (can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) and (has_lens() or (can_longshot() and has_hover_boots())) end,
        },
        ["locations"] = {
            ["Ganon Castle Shadow Chest 1"] = function () return can_play(SONG_TIME) or can_hookshot() or has_hover_boots() or has_fire_arrows() end,
            ["Ganon Castle Shadow Chest 2"] = function () return (can_longshot() or has_fire_arrows()) and (has_hover_boots() or has_fire()) end,
        },
    },
    ["Ganon Castle Stairs"] = {
        ["exits"] = {
            ["Ganon Castle"] = function () return true end,
            ["Ganon Castle Tower"] = function () return true end,
        },
    },
    ["Ganon Castle Tower"] = {
        ["exits"] = {
            ["Ganon Castle Stairs"] = function () return true end,
            ["Ganon Castle Tower Boss"] = function () return setting('ganonBossKey', 'removed') or has('BOSS_KEY_GANON') or (setting('ganonBossKey', 'custom') and special(GANON_BK)) end,
        },
        ["locations"] = {
            ["Ganon Castle Boss Key"] = function () return has_weapon() end,
        },
    },
    ["Ganon Castle Tower Boss"] = {
        ["events"] = {
            ["GANON"] = function () return has_light_arrows() end,
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
            ["Gerudo Fortress Jail 1"] = function () return has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks()) end,
            ["Gerudo Member Card"] = function () return carpenters_rescued() end,
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
            ["Gerudo Fortress Jail 2"] = function () return has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks()) end,
            ["Gerudo Member Card"] = function () return carpenters_rescued() end,
        },
    },
    ["Gerudo Fortress Carpenter 2 Top"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 2 Bottom"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 3 Bottom"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Right Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 3 Top"] = function () return true end,
        },
    },
    ["Gerudo Fortress Carpenter 3 Top"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["CARPENTER_3"] = function () return can_rescue_carpenter() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 3 Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Jail 3"] = function () return has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks()) end,
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
            ["Gerudo Fortress Kitchen Bottom"] = function () return can_use_bow() or has('GERUDO_CARD') end,
        },
    },
    ["Gerudo Fortress Kitchen Bottom"] = {
        ["exits"] = {
            ["Gerudo Fortress Kitchen Tunnel Mid"] = function () return can_use_bow() or has('GERUDO_CARD') end,
            ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = function () return can_use_bow() or has('GERUDO_CARD') end,
            ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = function () return can_use_bow() or has('GERUDO_CARD') end,
        },
    },
    ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Kitchen Bottom"] = function () return can_use_bow() or has('GERUDO_CARD') end,
            ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = function () return can_hookshot() or has_hover_boots() end,
        },
    },
    ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = {
        ["exits"] = {
            ["Gerudo Fortress Upper-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Kitchen Bottom"] = function () return can_use_bow() or has('GERUDO_CARD') end,
            ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = function () return can_hookshot() or has_hover_boots() end,
        },
    },
    ["Gerudo Fortress Carpenter 4"] = {
        ["events"] = {
            ["CARPENTER_4"] = function () return can_rescue_carpenter() end,
        },
        ["exits"] = {
            ["Gerudo Fortress Center Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Jail 4"] = function () return has_weapon() or ((can_boomerang() or has_nuts()) and can_use_sticks()) end,
            ["Gerudo Member Card"] = function () return carpenters_rescued() end,
        },
    },
    ["Gerudo Fortress Break Room Bottom"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_use_bow() or can_hookshot() or has('GERUDO_CARD') end,
            ["ARROWS"] = function () return is_adult() and (has('GERUDO_CARD') or can_hookshot()) end,
            ["SEEDS"] = function () return is_child() and has('GERUDO_CARD') end,
        },
        ["exits"] = {
            ["Gerudo Fortress Lower-Left Ledge"] = function () return true end,
            ["Gerudo Fortress Break Room Top"] = function () return can_hookshot() end,
        },
    },
    ["Gerudo Fortress Break Room Top"] = {
        ["exits"] = {
            ["Gerudo Fortress Above Prison"] = function () return true end,
            ["Gerudo Fortress Break Room Bottom"] = function () return can_hookshot() end,
        },
    },
    ["Gerudo Training Grounds"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Training Grounds Left Side"] = function () return can_hookshot() and has_weapon() end,
            ["Gerudo Training Grounds Right Side"] = function () return has_explosives() and has_weapon() end,
            ["Gerudo Training Grounds Maze"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Entrance 1"] = function () return can_use_bow() or can_use_slingshot() end,
            ["Gerudo Training Grounds Entrance 2"] = function () return can_use_bow() or can_use_slingshot() end,
            ["Gerudo Training Grounds Stalfos"] = function () return has_weapon() end,
        },
    },
    ["Gerudo Training Grounds Left Side"] = {
        ["exits"] = {
            ["Gerudo Training Grounds After Block"] = function () return can_lift_silver() and has_lens() and can_hookshot() end,
            ["Gerudo Training Grounds Upper"] = function () return can_hookshot() and has_lens() end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Near Block"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds After Block"] = {
        ["locations"] = {
            ["Gerudo Training Grounds Behind Block Invisible"] = function () return has_lens() end,
            ["Gerudo Training Grounds Behind Block Visible 1"] = function () return true end,
            ["Gerudo Training Grounds Behind Block Visible 2"] = function () return true end,
            ["Gerudo Training Grounds Behind Block Visible 3"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Upper"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Left Side"] = function () return true end,
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
            ["Gerudo Training Grounds Maze Side"] = function () return can_play(SONG_TIME) or is_child() end,
            ["Gerudo Training Grounds Hammer"] = function () return can_hookshot() and (can_longshot() or has_hover_boots() or can_play(SONG_TIME)) end,
            ["Gerudo Training Grounds Water"] = function () return can_hookshot() and (has_hover_boots() or can_play(SONG_TIME)) end,
        },
    },
    ["Gerudo Training Grounds Maze Side"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Lava"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Training Freestanding Key"] = function () return true end,
            ["Gerudo Training Maze Side Chest 1"] = function () return true end,
            ["Gerudo Training Maze Side Chest 2"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Water"] = {
        ["locations"] = {
            ["Gerudo Training Water"] = function () return can_play(SONG_TIME) and has_tunic_zora() and has_iron_boots() end,
        },
    },
    ["Gerudo Training Grounds Hammer"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Lava"] = function () return true end,
            ["Gerudo Training Grounds Statue"] = function () return can_hammer() and can_use_bow() end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Hammer Room Switch"] = function () return can_hammer() end,
            ["Gerudo Training Grounds Hammer Room"] = function () return true end,
        },
    },
    ["Gerudo Training Grounds Statue"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Hammer"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Training Grounds Eye Statue"] = function () return can_use_bow() end,
        },
    },
    ["Gerudo Training Grounds Maze"] = {
        ["exits"] = {
            ["Gerudo Training Grounds Maze Side"] = function () return small_keys(SMALL_KEY_GTG, 9) end,
        },
        ["locations"] = {
            ["Gerudo Training Maze Upper Fake Ceiling"] = function () return small_keys(SMALL_KEY_GTG, 3) and has_lens() end,
            ["Gerudo Training Maze Chest 1"] = function () return small_keys(SMALL_KEY_GTG, 4) end,
            ["Gerudo Training Maze Chest 2"] = function () return small_keys(SMALL_KEY_GTG, 6) end,
            ["Gerudo Training Maze Chest 3"] = function () return small_keys(SMALL_KEY_GTG, 7) end,
            ["Gerudo Training Maze Chest 4"] = function () return small_keys(SMALL_KEY_GTG, 9) end,
        },
    },
    ["Ice Cavern"] = {
        ["events"] = {
            ["BLUE_FIRE"] = function () return is_adult() end,
        },
        ["exits"] = {
            ["Zora Fountain Frozen"] = function () return true end,
        },
        ["locations"] = {
            ["Ice Cavern Iron Boots"] = function () return has_blue_fire() end,
            ["Ice Cavern Map"] = function () return has_blue_fire() and is_adult() end,
            ["Ice Cavern Compass"] = function () return has_blue_fire() end,
            ["Ice Cavern HP"] = function () return has_blue_fire() end,
            ["Ice Cavern Sheik Song"] = function () return has_blue_fire() end,
            ["Ice Cavern GS Scythe Room"] = function () return can_collect_distance() end,
            ["Ice Cavern GS Block Room"] = function () return has_blue_fire() and can_collect_distance() end,
            ["Ice Cavern GS HP Room"] = function () return has_blue_fire() and can_collect_distance() end,
        },
    },
    ["Jabu-Jabu"] = {
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
            ["Jabu-Jabu Main"] = function () return has_ranged_weapon() or has_explosives() end,
        },
    },
    ["Jabu-Jabu Main"] = {
        ["exits"] = {
            ["Jabu-Jabu"] = function () return true end,
            ["Jabu-Jabu Pre-Boss"] = function () return can_boomerang() and (has_weapon() or can_use_sticks()) end,
        },
        ["locations"] = {
            ["Jabu-Jabu Map Chest"] = function () return can_boomerang() end,
            ["Jabu-Jabu Compass Chest"] = function () return can_boomerang() end,
            ["Jabu-Jabu Boomerang Chest"] = function () return true end,
            ["Jabu-Jabu Scrub"] = function () return can_hit_scrub() and (is_child() or can_dive_small()) and can_use_wallet(1) end,
            ["Jabu-Jabu GS Bottom Lower"] = function () return can_collect_distance() end,
            ["Jabu-Jabu GS Bottom Upper"] = function () return can_collect_distance() end,
            ["Jabu-Jabu GS Water Switch"] = function () return true end,
            ["Jabu-Jabu GS Near Boss"] = function () return can_boomerang() and (has_weapon() or can_use_sticks()) end,
        },
    },
    ["Jabu-Jabu Pre-Boss"] = {
        ["exits"] = {
            ["Jabu-Jabu Boss"] = function () return true end,
            ["Jabu-Jabu Main"] = function () return true end,
        },
    },
    ["SPAWN"] = {
        ["exits"] = {
            ["SPAWN CHILD"] = function () return is_child() end,
            ["SPAWN ADULT"] = function () return is_adult() and event('TIME_TRAVEL') end,
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
            ["SONGS"] = function () return has('OCARINA') end,
            ["EGGS"] = function () return true end,
        },
    },
    ["SONGS"] = {
        ["exits"] = {
            ["Temple of Time"] = function () return has('SONG_TP_LIGHT') end,
            ["Sacred Meadow"] = function () return has('SONG_TP_FOREST') end,
            ["Death Mountain Crater Warp"] = function () return has('SONG_TP_FIRE') end,
            ["Lake Hylia"] = function () return has('SONG_TP_WATER') end,
            ["Graveyard Upper"] = function () return has('SONG_TP_SHADOW') end,
            ["Desert Colossus"] = function () return has('SONG_TP_SPIRIT') end,
            ["MM SOARING"] = function () return setting('crossWarpMm', 'full') or (setting('crossWarpMm', 'childOnly') and is_child()) end,
        },
    },
    ["EGGS"] = {
        ["locations"] = {
            ["Hatch Chicken"] = function () return is_child() and has('WEIRD_EGG') end,
            ["Hatch Pocket Cucco"] = function () return is_adult() and has('POCKET_EGG') end,
        },
    },
    ["Link's House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Kokiri Forest Cow"] = function () return is_adult() and event('MALON_COW') and can_play(SONG_EPONA) end,
        },
    },
    ["Kokiri Forest"] = {
        ["events"] = {
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return true end,
            ["MIDO_MOVED"] = function () return can_move_mido() end,
        },
        ["exits"] = {
            ["Link's House"] = function () return true end,
            ["Mido's House"] = function () return true end,
            ["Saria's House"] = function () return true end,
            ["House of Twins"] = function () return true end,
            ["Know It All House"] = function () return true end,
            ["Lost Woods"] = function () return true end,
            ["Lost Woods Bridge"] = function () return true end,
            ["Kokiri Shop"] = function () return true end,
            ["Kokiri Forest Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Kokiri Forest Near Deku Tree"] = function () return mido_moved() end,
        },
        ["locations"] = {
            ["Kokiri Forest Kokiri Sword Chest"] = function () return is_child() end,
            ["Kokiri Forest GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Kokiri Forest GS Night Child"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Kokiri Forest GS Night Adult"] = function () return can_hookshot() and gs_night() end,
        },
    },
    ["Kokiri Forest Near Deku Tree"] = {
        ["events"] = {
            ["STICKS"] = function () return can_boomerang() or (is_child() and has_weapon()) end,
            ["MIDO_MOVED"] = function () return can_move_mido() end,
        },
        ["exits"] = {
            ["Kokiri Forest"] = function () return mido_moved() end,
            ["Deku Tree"] = function () return is_child() or (is_adult() and setting('dekuTreeAdult') and mido_moved()) end,
        },
    },
    ["Kokiri Shop"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Kokiri Shop Item 1"] = function () return can_use_wallet(1) end,
            ["Kokiri Shop Item 2"] = function () return can_use_wallet(1) end,
            ["Kokiri Shop Item 3"] = function () return can_use_wallet(1) end,
            ["Kokiri Shop Item 4"] = function () return can_use_wallet(1) end,
            ["Kokiri Shop Item 5"] = function () return can_use_wallet(1) end,
            ["Kokiri Shop Item 6"] = function () return can_use_wallet(1) end,
            ["Kokiri Shop Item 7"] = function () return can_use_wallet(1) end,
            ["Kokiri Shop Item 8"] = function () return can_use_wallet(1) end,
        },
    },
    ["Mido's House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Kokiri Forest Mido Top Left"] = function () return true end,
            ["Kokiri Forest Mido Top Right"] = function () return true end,
            ["Kokiri Forest Mido Bottom Left"] = function () return true end,
            ["Kokiri Forest Mido Bottom Right"] = function () return true end,
        },
    },
    ["Saria's House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
    },
    ["House of Twins"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
    },
    ["Know It All House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
    },
    ["Kokiri Forest Storms Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["FISH"] = function () return has_bottle() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Kokiri Forest Storms Grotto"] = function () return true end,
        },
    },
    ["Hyrule Field"] = {
        ["events"] = {
            ["BIG_POE"] = function () return can_ride_epona() and can_use_bow() and has_bottle() end,
            ["BOMBS"] = function () return true end,
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
            ["Hyrule Field Scrub Grotto"] = function () return hidden_grotto_bomb() end,
            ["Hyrule Field Open Grotto"] = function () return true end,
            ["Hyrule Field Southeast Grotto"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Field Grotto Near Market"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Field Tektite Grotto"] = function () return hidden_grotto_bomb() end,
            ["Hyrule Field Grotto Near GV"] = function () return is_child() and hidden_grotto_bomb() or can_hammer() end,
            ["Hyrule Field Grotto Near Kak"] = function () return hidden_grotto_bomb() end,
            ["Hyrule Field Fairy Grotto"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Hyrule Field Ocarina of Time"] = function () return has_spiritual_stones() end,
            ["Hyrule Field Song of Time"] = function () return has_spiritual_stones() end,
        },
    },
    ["Hyrule Field Scrub Grotto"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Scrub HP"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Hyrule Field Open Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
        },
    },
    ["Hyrule Field Southeast Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
        },
    },
    ["Hyrule Field Grotto Near Market"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
            ["Hyrule Field Grotto Near Gerudo GS"] = function () return can_collect_distance() and has_fire() end,
            ["Hyrule Field Cow"] = function () return has_fire() and can_play(SONG_EPONA) end,
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
            ["Hyrule Field Grotto Near Kakariko GS"] = function () return can_collect_distance() end,
        },
    },
    ["Hyrule Field Fairy Grotto"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
        },
    },
    ["Market Entryway"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return is_day() or is_adult() end,
            ["Market"] = function () return is_child() end,
            ["Market Destroyed"] = function () return is_adult() end,
            ["Market Pot House"] = function () return true end,
        },
    },
    ["Market"] = {
        ["events"] = {
            ["RICHARD"] = function () return is_night() end,
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Market Entryway"] = function () return true end,
            ["Back Alley"] = function () return true end,
            ["Hyrule Castle"] = function () return is_child() end,
            ["Temple of Time Entryway"] = function () return true end,
            ["Bombchu Bowling"] = function () return true end,
            ["Treasure Game"] = function () return is_night() end,
            ["Shooting Gallery Child"] = function () return is_day() end,
            ["Market Bazaar"] = function () return is_day() end,
            ["Market Potion Shop"] = function () return is_day() end,
            ["MM Clock Town"] = function () return is_child() and is_day() end,
        },
    },
    ["Market Bazaar"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Market Bazaar Item 1"] = function () return can_use_wallet(1) end,
            ["Market Bazaar Item 2"] = function () return can_use_wallet(1) end,
            ["Market Bazaar Item 3"] = function () return can_use_wallet(1) end,
            ["Market Bazaar Item 4"] = function () return can_use_wallet(1) end,
            ["Market Bazaar Item 5"] = function () return can_use_wallet(1) end,
            ["Market Bazaar Item 6"] = function () return can_use_wallet(1) end,
            ["Market Bazaar Item 7"] = function () return can_use_wallet(1) end,
            ["Market Bazaar Item 8"] = function () return can_use_wallet(1) end,
        },
    },
    ["Market Potion Shop"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Market Potion Shop Item 1"] = function () return can_use_wallet(2) end,
            ["Market Potion Shop Item 2"] = function () return can_use_wallet(1) end,
            ["Market Potion Shop Item 3"] = function () return can_use_wallet(1) end,
            ["Market Potion Shop Item 4"] = function () return can_use_wallet(1) end,
            ["Market Potion Shop Item 5"] = function () return can_use_wallet(3) end,
            ["Market Potion Shop Item 6"] = function () return can_use_wallet(1) end,
            ["Market Potion Shop Item 7"] = function () return can_use_wallet(1) end,
            ["Market Potion Shop Item 8"] = function () return can_use_wallet(1) end,
        },
    },
    ["Market Bombchu Shop"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Market Bombchu Shop Item 1"] = function () return can_use_wallet(2) end,
            ["Market Bombchu Shop Item 2"] = function () return can_use_wallet(2) end,
            ["Market Bombchu Shop Item 3"] = function () return can_use_wallet(2) end,
            ["Market Bombchu Shop Item 4"] = function () return can_use_wallet(2) end,
            ["Market Bombchu Shop Item 5"] = function () return can_use_wallet(2) end,
            ["Market Bombchu Shop Item 6"] = function () return can_use_wallet(2) end,
            ["Market Bombchu Shop Item 7"] = function () return can_use_wallet(2) end,
            ["Market Bombchu Shop Item 8"] = function () return can_use_wallet(2) end,
        },
    },
    ["Market Pot House"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Market Entryway"] = function () return true end,
        },
        ["locations"] = {
            ["Market Pot House Big Poes"] = function () return is_adult() and event('BIG_POE') end,
            ["Market Pot House GS"] = function () return is_child() end,
        },
    },
    ["Back Alley"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
            ["Market Destroyed"] = function () return is_adult() end,
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
            ["Market Dog Lady HP"] = function () return event('RICHARD') and is_night() end,
        },
    },
    ["Market Back Alley East Home"] = {
        ["exits"] = {
            ["Back Alley"] = function () return true end,
        },
    },
    ["Bombchu Bowling"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_use_wallet(2) end,
            ["BOMBCHUS"] = function () return can_use_wallet(1) end,
        },
        ["exits"] = {
            ["Market"] = function () return true end,
        },
        ["locations"] = {
            ["Bombchu Bowling Reward 1"] = function () return has('BOMB_BAG') and can_use_wallet(1) end,
            ["Bombchu Bowling Reward 2"] = function () return has('BOMB_BAG') and can_use_wallet(1) end,
        },
    },
    ["Shooting Gallery Child"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Shooting Gallery Child"] = function () return is_child() and can_use_wallet(1) end,
        },
    },
    ["Treasure Game"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
        },
        ["locations"] = {
            ["Treasure Game HP"] = function () return has_lens_strict() and can_use_wallet(1) end,
        },
    },
    ["Market Destroyed"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Market Pot House"] = function () return true end,
            ["Temple of Time"] = function () return true end,
            ["Ganon Castle Exterior"] = function () return true end,
        },
    },
    ["Temple of Time Entryway"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
            ["Market Destroyed"] = function () return is_adult() end,
            ["Temple of Time"] = function () return true end,
        },
    },
    ["Lon Lon Ranch"] = {
        ["events"] = {
            ["EPONA"] = function () return true end,
            ["MALON_COW"] = function () return can_ride_epona() and event('EPONA') and is_day() end,
            ["RUPEES"] = function () return is_child() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Lon Lon Ranch Silo"] = function () return true end,
            ["Lon Lon Ranch Stables"] = function () return true end,
            ["Lon Lon Ranch House"] = function () return is_day() end,
            ["Lon Lon Ranch Grotto"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Malon Song"] = function () return is_child() and has('OCARINA') and event('MALON') and is_day() end,
            ["Lon Lon Ranch GS Tree"] = function () return is_child() end,
            ["Lon Lon Ranch GS House"] = function () return can_boomerang() and gs_night() end,
            ["Lon Lon Ranch GS Rain Shed"] = function () return is_child() and gs_night() end,
            ["Lon Lon Ranch GS Back Wall"] = function () return can_boomerang() and gs_night() end,
        },
    },
    ["Lon Lon Ranch Stables"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Stables Cow Left"] = function () return can_play(SONG_EPONA) end,
            ["Lon Lon Ranch Stables Cow Right"] = function () return can_play(SONG_EPONA) end,
        },
    },
    ["Lon Lon Ranch Silo"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Silo HP"] = function () return is_child() end,
            ["Lon Lon Ranch Silo Cow Front"] = function () return can_play(SONG_EPONA) end,
            ["Lon Lon Ranch Silo Cow Back"] = function () return can_play(SONG_EPONA) end,
        },
    },
    ["Lon Lon Ranch House"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Talon Bottle"] = function () return is_child() and woke_talon_child() and can_use_wallet(1) and is_day() end,
        },
    },
    ["Lon Lon Ranch Grotto"] = {
        ["exits"] = {
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Grotto Left Scrub"] = function () return is_child() and can_use_wallet(1) and can_hit_scrub() end,
            ["Lon Lon Ranch Grotto Center Scrub"] = function () return is_child() and can_use_wallet(1) and can_hit_scrub() end,
            ["Lon Lon Ranch Grotto Right Scrub"] = function () return is_child() and can_use_wallet(1) and can_hit_scrub() end,
        },
    },
    ["Hyrule Castle"] = {
        ["events"] = {
            ["MALON"] = function () return true end,
            ["TALON_CHILD"] = function () return has('CHICKEN') end,
            ["MEET_ZELDA"] = function () return woke_talon_child() end,
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["MAGIC"] = function () return true end,
            ["BUGS"] = function () return has_bottle() end,
        },
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Fairy Fountain Din"] = function () return has_explosives() end,
            ["Hyrule Castle Grotto"] = function () return hidden_grotto_storms() end,
        },
        ["locations"] = {
            ["Malon Egg"] = function () return event('MALON') end,
            ["Zelda's Letter"] = function () return met_zelda() end,
            ["Zelda's Song"] = function () return met_zelda() end,
            ["Hyrule Castle GS Tree"] = function () return can_damage_skull() end,
        },
    },
    ["Fairy Fountain Din"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Hyrule Castle"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Din's Fire"] = function () return can_play(SONG_ZELDA) end,
        },
    },
    ["Hyrule Castle Grotto"] = {
        ["events"] = {
            ["RUPEES"] = function () return has_explosives_or_hammer() end,
            ["NUTS"] = function () return has_explosives_or_hammer() end,
            ["SEEDS"] = function () return has_explosives() and is_child() end,
            ["ARROWS"] = function () return has_explosives_or_hammer() and is_adult() end,
            ["BOMBS"] = function () return can_hammer() end,
            ["BUGS"] = function () return has_explosives_or_hammer() and has_bottle() end,
        },
        ["exits"] = {
            ["Hyrule Castle"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Castle GS Grotto"] = function () return has_explosives_or_hammer() and can_collect_distance() end,
        },
    },
    ["Ganon Castle Exterior"] = {
        ["exits"] = {
            ["Market Destroyed"] = function () return true end,
            ["Ganon Castle Exterior After Bridge"] = function () return special(BRIDGE) end,
            ["Fairy Fountain Defense"] = function () return can_lift_gold() end,
        },
        ["locations"] = {
            ["Ganon Castle Exterior GS"] = function () return true end,
        },
    },
    ["Ganon Castle Exterior After Bridge"] = {
        ["exits"] = {
            ["Ganon Castle Exterior"] = function () return is_adult() and special(BRIDGE) end,
            ["Hyrule Castle"] = function () return is_child() end,
            ["Ganon Castle"] = function () return true end,
        },
    },
    ["Fairy Fountain Defense"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Ganon Castle Exterior"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Defense Upgrade"] = function () return can_play(SONG_ZELDA) end,
        },
    },
    ["Lost Woods"] = {
        ["events"] = {
            ["BEAN_LOST_WOODS_EARLY"] = function () return can_use_beans() end,
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
            ["Lost Woods Bridge"] = function () return can_longshot() or has_hover_boots() or can_ride_bean(BEAN_LOST_WOODS_EARLY) end,
            ["Lost Woods Deep"] = function () return is_child() or can_play(SONG_SARIA) or trick_mido() end,
            ["Lost Woods Generic Grotto"] = function () return has_explosives_or_hammer() end,
            ["Goron City Shortcut"] = function () return true end,
            ["Zora River"] = function () return can_dive_small() end,
        },
        ["locations"] = {
            ["Lost Woods Target"] = function () return can_use_slingshot() end,
            ["Lost Woods Skull Kid"] = function () return is_child() and can_play(SONG_SARIA) end,
            ["Lost Woods Memory Game"] = function () return is_child() and has('OCARINA') end,
            ["Lost Woods Scrub Sticks Upgrade"] = function () return is_child() and can_hit_scrub() and can_use_wallet(1) end,
            ["Lost Woods Odd Mushroom"] = function () return adult_trade(COJIRO) end,
            ["Lost Woods Poacher's Saw"] = function () return adult_trade(ODD_POTION) end,
            ["Lost Woods GS Soil Bridge"] = function () return gs_soil() and can_damage_skull() end,
        },
    },
    ["Lost Woods Generic Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
        },
    },
    ["Lost Woods Bridge"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
            ["Hyrule Field"] = function () return true end,
            ["Lost Woods"] = function () return can_longshot() end,
        },
        ["locations"] = {
            ["Lost Woods Gift from Saria"] = function () return true end,
        },
    },
    ["Lost Woods Deep"] = {
        ["events"] = {
            ["BEAN_LOST_WOODS_LATE"] = function () return can_use_beans() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["BOMBS"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() end,
        },
        ["exits"] = {
            ["Lost Woods"] = function () return is_child() or can_play(SONG_SARIA) end,
            ["Sacred Meadow Entryway"] = function () return true end,
            ["Deku Theater"] = function () return true end,
            ["Lost Woods Scrub Grotto"] = function () return has_explosives_or_hammer() end,
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Scrub Near Theater Left"] = function () return is_child() and can_hit_scrub() and can_use_wallet(1) end,
            ["Lost Woods Scrub Near Theater Right"] = function () return is_child() and can_hit_scrub() and can_use_wallet(1) end,
            ["Lost Woods GS Soil Theater"] = function () return gs_soil() and can_damage_skull() end,
            ["Lost Woods GS Bean Ride"] = function () return gs_night() and (can_ride_bean(BEAN_LOST_WOODS_LATE) or (trick('OOT_LOST_WOODS_ADULT_GS') and can_hookshot() and (can_longshot() or can_use_bow() or has_bombchu() or can_use_din()))) end,
        },
    },
    ["Deku Theater"] = {
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Theater Sticks Upgrade"] = function () return is_child() and has('MASK_SKULL') end,
            ["Deku Theater Nuts Upgrade"] = function () return is_child() and has('MASK_TRUTH') end,
        },
    },
    ["Lost Woods Scrub Grotto"] = {
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Grotto Scrub Nuts Upgrade"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Lost Woods Grotto Scrub Back"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Sacred Meadow Entryway"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
            ["Sacred Meadow"] = function () return can_damage() end,
            ["Wolfos Grotto"] = function () return hidden_grotto_bomb() end,
        },
    },
    ["Wolfos Grotto"] = {
        ["exits"] = {
            ["Sacred Meadow Entryway"] = function () return true end,
        },
        ["locations"] = {
            ["Sacred Meadow Grotto"] = function () return can_damage() end,
        },
    },
    ["Sacred Meadow"] = {
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
            ["Forest Temple"] = function () return can_hookshot() end,
            ["Sacred Meadow Storms Grotto"] = function () return hidden_grotto_storms() end,
        },
        ["locations"] = {
            ["Saria's Song"] = function () return met_zelda() and is_child() end,
            ["Sacred Meadow Sheik Song"] = function () return is_adult() end,
            ["Sacred Meadow GS Night Adult"] = function () return can_hookshot() and gs_night() end,
        },
    },
    ["Sacred Meadow Storms Grotto"] = {
        ["exits"] = {
            ["Sacred Meadow"] = function () return true end,
        },
        ["locations"] = {
            ["Sacred Meadow Storms Grotto Front Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Sacred Meadow Storms Grotto Back Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Kakariko"] = {
        ["events"] = {
            ["KAKARIKO_GATE_OPEN"] = function () return is_child() and has('ZELDA_LETTER') end,
            ["BUGS"] = function () return has_bottle() end,
            ["BOMBS"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Kakariko Trail Start"] = function () return setting('kakarikoGate', 'open') or event('KAKARIKO_GATE_OPEN') or is_adult() end,
            ["Graveyard"] = function () return true end,
            ["Bottom of the Well"] = function () return (is_child() or (is_adult() and setting('wellAdult'))) and event('WELL_DRAIN') end,
            ["Skulltula House"] = function () return true end,
            ["Shooting Gallery Adult"] = function () return is_adult() and is_day() end,
            ["Kakariko Rooftop"] = function () return is_child() and is_day() or can_hookshot() or (is_adult() and trick('OOT_PASS_COLLISION')) end,
            ["Kakariko Back"] = function () return can_hookshot() or has_hover_boots() or (is_day() and is_child()) or (trick('OOT_MAN_ON_ROOF') and (is_adult() or can_use_slingshot() or has_bombchu())) end,
            ["Kakariko Bazaar"] = function () return is_adult() and is_day() end,
            ["Kakariko Potion Shop"] = function () return is_day() end,
            ["Windmill"] = function () return true end,
            ["Kakariko Carpenter House"] = function () return true end,
            ["Impa House Front"] = function () return true end,
            ["ReDead Grotto"] = function () return hidden_grotto_bomb() end,
        },
        ["locations"] = {
            ["Kakariko Anju Bottle"] = function () return is_child() and is_day() end,
            ["Kakariko Anju Egg"] = function () return is_adult() and is_day() end,
            ["Kakariko Anju Cojiro"] = function () return event('TALON_AWAKE') and is_day() end,
            ["Kakariko Song Shadow"] = function () return is_adult() and has('MEDALLION_FOREST') and has('MEDALLION_FIRE') and has('MEDALLION_WATER') end,
            ["Kakariko Man on Roof"] = function () return can_hookshot() or trick('OOT_MAN_ON_ROOF') end,
            ["Kakariko GS Roof"] = function () return gs_night() and can_hookshot() end,
            ["Kakariko GS Shooting Gallery"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Tree"] = function () return gs_night() and is_child() end,
            ["Kakariko GS House of Skulltula"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Bazaar"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Ladder"] = function () return gs_night() and is_child() and (can_use_slingshot() or has_bombchu()) end,
        },
    },
    ["Kakariko Rooftop"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Impa House Back"] = function () return true end,
        },
    },
    ["Kakariko Trail Start"] = {
        ["exits"] = {
            ["Kakariko"] = function () return setting('kakarikoGate', 'open') or event('KAKARIKO_GATE_OPEN') or is_adult() or trick('OOT_PASS_COLLISION') end,
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
            ["Kakariko"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Kakariko Bazaar Item 1"] = function () return can_use_wallet(1) end,
            ["Kakariko Bazaar Item 2"] = function () return can_use_wallet(1) end,
            ["Kakariko Bazaar Item 3"] = function () return can_use_wallet(1) end,
            ["Kakariko Bazaar Item 4"] = function () return can_use_wallet(1) end,
            ["Kakariko Bazaar Item 5"] = function () return can_use_wallet(1) end,
            ["Kakariko Bazaar Item 6"] = function () return can_use_wallet(1) end,
            ["Kakariko Bazaar Item 7"] = function () return can_use_wallet(1) end,
            ["Kakariko Bazaar Item 8"] = function () return can_use_wallet(1) end,
        },
    },
    ["Kakariko Potion Shop"] = {
        ["exits"] = {
            ["Kakariko"] = function () return is_adult() end,
            ["Kakariko Potion Shop Back"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Kakariko Potion Shop Item 1"] = function () return can_use_wallet(2) and is_adult() end,
            ["Kakariko Potion Shop Item 2"] = function () return can_use_wallet(1) and is_adult() end,
            ["Kakariko Potion Shop Item 3"] = function () return can_use_wallet(1) and is_adult() end,
            ["Kakariko Potion Shop Item 4"] = function () return can_use_wallet(1) and is_adult() end,
            ["Kakariko Potion Shop Item 5"] = function () return can_use_wallet(3) and is_adult() end,
            ["Kakariko Potion Shop Item 6"] = function () return can_use_wallet(1) and is_adult() end,
            ["Kakariko Potion Shop Item 7"] = function () return can_use_wallet(1) and is_adult() end,
            ["Kakariko Potion Shop Item 8"] = function () return can_use_wallet(1) and is_adult() end,
        },
    },
    ["Kakariko Potion Shop Back"] = {
        ["exits"] = {
            ["Kakariko Back"] = function () return is_adult() end,
            ["Kakariko Potion Shop"] = function () return true end,
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
            ["Kakariko Potion Shop Odd Potion"] = function () return adult_trade(ODD_MUSHROOM) end,
        },
    },
    ["Shooting Gallery Adult"] = {
        ["exits"] = {
            ["Kakariko"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Shooting Gallery Adult"] = function () return can_use_bow() and can_use_wallet(1) end,
        },
    },
    ["Impa House Front"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Cow"] = function () return can_play(SONG_EPONA) end,
        },
    },
    ["Impa House Back"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Cow"] = function () return can_play(SONG_EPONA) end,
            ["Kakariko Impa House HP"] = function () return true end,
        },
    },
    ["Windmill"] = {
        ["events"] = {
            ["WELL_DRAIN"] = function () return is_child() and can_play(SONG_STORMS) end,
        },
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Windmill HP"] = function () return can_boomerang() or event('WINDMILL_TOP') or (is_adult() and trick('OOT_WINDMILL_HP_NOTHING')) end,
            ["Windmill Song of Storms"] = function () return is_adult() and has('OCARINA') end,
        },
    },
    ["Kakariko Carpenter House"] = {
        ["events"] = {
            ["TALON_AWAKE"] = function () return adult_trade(POCKET_CUCCO) end,
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
            ["Kakariko Grotto Front"] = function () return has_weapon() or can_use_sticks() end,
        },
    },
    ["Kakariko Generic Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
        },
    },
    ["Graveyard"] = {
        ["events"] = {
            ["BEAN_GRAVEYARD"] = function () return can_use_beans() end,
            ["BUGS"] = function () return has_bottle() end,
            ["BOMBS"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
        },
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Graveyard Royal Tomb"] = function () return can_play(SONG_ZELDA) end,
            ["Graveyard Shield Grave"] = function () return is_adult() or is_night() end,
            ["Graveyard ReDead Grave"] = function () return is_adult() or is_night() end,
            ["Dampe Grave"] = function () return is_adult() end,
            ["Dampe House"] = function () return is_adult() or is_dusk() end,
        },
        ["locations"] = {
            ["Graveyard Dampe Game"] = function () return is_child() and can_use_wallet(1) and is_dusk() end,
            ["Graveyard Crate HP"] = function () return can_ride_bean(BEAN_GRAVEYARD) or can_longshot() end,
            ["Graveyard GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Graveyard GS Wall"] = function () return can_boomerang() and gs_night() end,
        },
    },
    ["Graveyard Upper"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
            ["Shadow Temple"] = function () return can_use_din() or (has_fire_arrows() and trick('OOT_SHADOW_FIRE_ARROW')) end,
        },
    },
    ["Graveyard Royal Tomb"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Graveyard Royal Tomb Song"] = function () return true end,
            ["Graveyard Royal Tomb Chest"] = function () return has_fire() end,
        },
    },
    ["Graveyard Shield Grave"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Graveyard Fairy Tomb"] = function () return true end,
        },
    },
    ["Graveyard ReDead Grave"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Graveyard ReDead Tomb"] = function () return can_play(SONG_SUN) end,
        },
    },
    ["Dampe Grave"] = {
        ["events"] = {
            ["NUTS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["MAGIC"] = function () return true end,
            ["BOMBS"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["WINDMILL_TOP"] = function () return is_adult() and can_play(SONG_TIME) end,
        },
        ["exits"] = {
            ["Graveyard"] = function () return true end,
            ["Windmill"] = function () return is_adult() and can_play(SONG_TIME) end,
        },
        ["locations"] = {
            ["Graveyard Dampe Tomb Reward 1"] = function () return true end,
            ["Graveyard Dampe Tomb Reward 2"] = function () return is_adult() end,
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
            ["Dodongo Cavern"] = function () return has_bombflowers() or is_adult() end,
            ["Kakariko Trail Start"] = function () return true end,
            ["Death Mountain Summit"] = function () return event('BOULDER_DEATH_MOUNTAIN') or can_ride_bean(BEAN_DEATH_MOUNTAIN) end,
            ["Death Mountain Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Death Mountain Cow Grotto"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Death Mountain Chest"] = function () return has_explosives_or_hammer() end,
            ["Death Mountain HP"] = function () return true end,
            ["Death Mountain GS Entrance"] = function () return has_explosives_or_hammer() end,
            ["Death Mountain GS Soil"] = function () return gs_soil() and has_bombflowers() and can_damage_skull() end,
            ["Death Mountain GS Above Dodongo"] = function () return gs_night() and (can_hammer() or trick('OOT_DMT_RED_ROCK_GS')) end,
        },
    },
    ["Death Mountain Summit"] = {
        ["events"] = {
            ["BEAN_DEATH_MOUNTAIN"] = function () return can_use_beans() end,
            ["BOULDER_DEATH_MOUNTAIN"] = function () return has_explosives_or_hammer() end,
        },
        ["exits"] = {
            ["Death Mountain"] = function () return true end,
            ["Kakariko Rooftop"] = function () return is_child() end,
            ["Death Mountain Crater Top"] = function () return true end,
            ["Fairy Fountain Magic"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Death Mountain Prescription"] = function () return adult_trade(BROKEN_GORON_SWORD) end,
            ["Death Mountain Claim Check"] = function () return adult_trade(EYE_DROPS) end,
            ["Death Mountain Biggoron Sword"] = function () return adult_trade(CLAIM_CHECK) end,
            ["Death Mountain GS Before Climb"] = function () return gs_night() and (can_hammer() or trick('OOT_DMT_RED_ROCK_GS')) end,
        },
    },
    ["Death Mountain Storms Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
            ["Death Mountain Grotto"] = function () return true end,
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
            ["Death Mountain Cow"] = function () return can_play(SONG_EPONA) end,
        },
    },
    ["Fairy Fountain Magic"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Death Mountain Summit"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Magic Upgrade"] = function () return can_play(SONG_ZELDA) end,
        },
    },
    ["Goron City Shortcut"] = {
        ["events"] = {
            ["GORON_CITY_SHORTCUT"] = function () return has_explosives() or can_hammer() or can_use_din() end,
        },
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
            ["Goron City"] = function () return event('GORON_CITY_SHORTCUT') end,
        },
    },
    ["Goron City"] = {
        ["exits"] = {
            ["Goron City Shortcut"] = function () return event('GORON_CITY_SHORTCUT') end,
            ["Death Mountain"] = function () return true end,
            ["Death Mountain Crater Bottom"] = function () return is_adult() and (has_explosives() or can_use_bow() or has('STRENGTH')) end,
            ["Goron Shop"] = function () return is_adult() and (has_explosives() or can_use_bow() or has('STRENGTH')) or (is_child() and has_bombflowers()) end,
            ["Goron City Grotto"] = function () return is_adult() and (can_play(SONG_TIME) or (can_hookshot() and (has_tunic_goron_strict() or can_use_nayru()))) end,
        },
        ["locations"] = {
            ["Darunia"] = function () return can_play(SONG_ZELDA) and can_play(SONG_SARIA) end,
            ["Goron City Maze Center 1"] = function () return has_explosives_or_hammer() or can_lift_silver() end,
            ["Goron City Maze Center 2"] = function () return has_explosives_or_hammer() or can_lift_silver() end,
            ["Goron City Maze Left"] = function () return can_hammer() or can_lift_silver() end,
            ["Goron City Big Pot HP"] = function () return is_child() and has_bombs() and (can_play(SONG_ZELDA) or has_fire()) end,
            ["Goron City Tunic"] = function () return is_adult() and (has_explosives() or can_use_bow() or has('STRENGTH')) end,
            ["Goron City Bomb Bag"] = function () return is_child() and has_explosives() end,
            ["Goron City Medigoron Giant Knife"] = function () return is_adult() and (has_bombflowers() or can_hammer()) and can_use_wallet(2) end,
            ["Goron City GS Platform"] = function () return is_adult() end,
            ["Goron City GS Maze"] = function () return is_child() and has_explosives() end,
        },
    },
    ["Goron Shop"] = {
        ["exits"] = {
            ["Goron City"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Shop Item 1"] = function () return can_use_wallet(1) end,
            ["Goron Shop Item 2"] = function () return can_use_wallet(1) end,
            ["Goron Shop Item 3"] = function () return can_use_wallet(1) end,
            ["Goron Shop Item 4"] = function () return can_use_wallet(2) end,
            ["Goron Shop Item 5"] = function () return can_use_wallet(1) end,
            ["Goron Shop Item 6"] = function () return can_use_wallet(1) end,
            ["Goron Shop Item 7"] = function () return can_use_wallet(1) end,
            ["Goron Shop Item 8"] = function () return can_use_wallet(2) end,
        },
    },
    ["Goron City Grotto"] = {
        ["exits"] = {
            ["Goron City"] = function () return true end,
        },
        ["locations"] = {
            ["Goron City Grotto Left Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Goron City Grotto Center Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Goron City Grotto Right Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Zora River Front"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Zora River"] = function () return is_adult() or (is_child() and has_explosives()) end,
        },
        ["locations"] = {
            ["Zora River GS Tree"] = function () return is_child() and can_damage_skull() end,
        },
    },
    ["Zora River"] = {
        ["events"] = {
            ["BOMBS"] = function () return true end,
            ["RUPEES"] = function () return true end,
            ["SEEDS"] = function () return is_child() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Zora River Front"] = function () return true end,
            ["Zora Domain"] = function () return can_play(SONG_ZELDA) or (is_child() and trick('OOT_CHILD_DOMAIN')) or (has_hover_boots() and trick('OOT_ADULT_DOMAIN')) end,
            ["Lost Woods"] = function () return can_dive_small() end,
            ["Zora River Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Zora River Open Grotto"] = function () return true end,
            ["Zora River Boulder Grotto"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Zora River Bean Seller"] = function () return is_child() and can_use_wallet(1) end,
            ["Zora River HP Pillar"] = function () return is_child() or has_hover_boots() end,
            ["Zora River HP Platform"] = function () return is_child() or has_hover_boots() end,
            ["Zora River Frogs Storms"] = function () return is_child() and can_play(SONG_STORMS) end,
            ["Zora River Frogs Game"] = function () return is_child() and can_play(SONG_ZELDA) and can_play(SONG_SARIA) and can_play(SONG_EPONA) and can_play(SONG_SUN) and can_play(SONG_TIME) and can_play(SONG_STORMS) end,
            ["Zora River GS Ladder"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Zora River GS Near Grotto"] = function () return is_adult() and gs_night() and can_hookshot() end,
            ["Zora River GS Near Bridge"] = function () return is_adult() and gs_night() and can_hookshot() end,
        },
    },
    ["Zora River Storms Grotto"] = {
        ["exits"] = {
            ["Zora River"] = function () return true end,
        },
        ["locations"] = {
            ["Zora River Storms Grotto Front Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Zora River Storms Grotto Back Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Zora River Open Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
        },
    },
    ["Zora River Boulder Grotto"] = {
        ["exits"] = {
            ["Zora River"] = function () return true end,
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
            ["Zora River"] = function () return true end,
            ["Lake Hylia"] = function () return is_child() and has('SCALE') end,
            ["Zora Domain Back"] = function () return king_zora_moved() or (is_adult() and trick('OOT_KZ_SKIP')) end,
            ["Zora Shop"] = function () return is_child() or has_blue_fire() end,
            ["Zora Domain Grotto"] = function () return hidden_grotto_storms() end,
        },
        ["locations"] = {
            ["Zora Domain Waterfall Chest"] = function () return is_child() end,
            ["Zora Domain Diving Game"] = function () return is_child() and can_use_wallet(1) end,
            ["Zora Domain Tunic"] = function () return is_adult() and has_blue_fire() end,
            ["Zora Domain Eyeball Frog"] = function () return has_blue_fire() and adult_trade(PRESCRIPTION) end,
            ["Zora Domain GS Waterfall"] = function () return is_adult() and gs_night() and (has_ranged_weapon_adult() or has('MAGIC_UPGRADE')) end,
        },
    },
    ["Zora Domain Back"] = {
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
            ["Zora Domain"] = function () return king_zora_moved() end,
        },
    },
    ["Zora Shop"] = {
        ["exits"] = {
            ["Zora Domain"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Shop Item 1"] = function () return can_use_wallet(1) end,
            ["Zora Shop Item 2"] = function () return can_use_wallet(1) end,
            ["Zora Shop Item 3"] = function () return can_use_wallet(2) end,
            ["Zora Shop Item 4"] = function () return can_use_wallet(1) end,
            ["Zora Shop Item 5"] = function () return can_use_wallet(1) end,
            ["Zora Shop Item 6"] = function () return can_use_wallet(1) end,
            ["Zora Shop Item 7"] = function () return can_use_wallet(3) end,
            ["Zora Shop Item 8"] = function () return can_use_wallet(1) end,
        },
    },
    ["Zora Domain Grotto"] = {
        ["exits"] = {
            ["Zora Domain"] = function () return true end,
        },
    },
    ["Lake Hylia"] = {
        ["events"] = {
            ["SCARECROW_CHILD"] = function () return is_child() and has('OCARINA') end,
            ["SCARECROW"] = function () return is_adult() and event('SCARECROW_CHILD') end,
            ["BEAN_LAKE_HYLIA"] = function () return can_use_beans() end,
            ["BOMBS"] = function () return can_cut_grass() end,
            ["RUPEES"] = function () return can_cut_grass() end,
            ["SEEDS"] = function () return is_child() and can_cut_grass() end,
            ["ARROWS"] = function () return is_adult() end,
            ["MAGIC"] = function () return can_cut_grass() end,
            ["BUGS"] = function () return has_bottle() and can_cut_grass() and is_child() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Zora Domain"] = function () return is_child() and has('SCALE') end,
            ["Laboratory"] = function () return true end,
            ["Water Temple"] = function () return has_iron_boots() and has_tunic_zora() and can_hookshot() end,
            ["Fishing Pond"] = function () return is_child() or event('WATER_TEMPLE_CLEARED') or scarecrow_hookshot() or can_ride_bean(BEAN_LAKE_HYLIA) end,
            ["Lake Hylia Grotto"] = function () return true end,
        },
        ["locations"] = {
            ["Lake Hylia Underwater Bottle"] = function () return is_child() and has('SCALE') end,
            ["Lake Hylia Fire Arrow"] = function () return can_use_bow() and (event('WATER_TEMPLE_CLEARED') or scarecrow_longshot()) end,
            ["Lake Hylia HP"] = function () return can_ride_bean(BEAN_LAKE_HYLIA) or scarecrow_hookshot() end,
            ["Lake Hylia GS Lab Wall"] = function () return gs_night() and (can_boomerang() or (trick('OOT_LAB_WALL_GS') and (has_sword_kokiri() or can_use_sticks()))) end,
            ["Lake Hylia GS Island"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Lake Hylia GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Lake Hylia GS Big Tree"] = function () return gs_night() and can_longshot() end,
        },
    },
    ["Laboratory"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
        ["locations"] = {
            ["Laboratory Dive"] = function () return has('SCALE', 2) or (trick('OOT_LAB_DIVE_NO_GOLD_SCALE') and has_iron_boots() and can_hookshot()) end,
            ["Laboratory Eye Drops"] = function () return adult_trade(EYEBALL_FROG) end,
            ["Laboratory GS Crate"] = function () return has_iron_boots() and can_hookshot() end,
        },
    },
    ["Fishing Pond"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
        ["locations"] = {
            ["Fishing Pond Child"] = function () return is_child() and can_use_wallet(1) end,
            ["Fishing Pond Adult"] = function () return is_adult() and can_use_wallet(1) end,
        },
    },
    ["Lake Hylia Grotto"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
        ["locations"] = {
            ["Lake Hylia Grotto Left Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Lake Hylia Grotto Center Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Lake Hylia Grotto Right Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Zora Fountain"] = {
        ["events"] = {
            ["SEEDS"] = function () return is_child() end,
        },
        ["exits"] = {
            ["Zora Domain Back"] = function () return true end,
            ["Jabu-Jabu"] = function () return is_child() and has_bottle() and (has('FISH') or event('FISH')) end,
            ["Zora Fountain Frozen"] = function () return is_adult() end,
            ["Fairy Fountain Farore"] = function () return has_explosives() end,
        },
        ["locations"] = {
            ["Zora Fountain Iceberg HP"] = function () return is_adult() end,
            ["Zora Fountain Bottom HP"] = function () return has_tunic_zora() and has_iron_boots() end,
            ["Zora Fountain GS Wall"] = function () return gs_night() and can_boomerang() end,
            ["Zora Fountain GS Tree"] = function () return is_child() and can_damage_skull() end,
            ["Zora Fountain GS Upper"] = function () return gs_night() and has_explosives_or_hammer() and can_hookshot() and can_lift_silver() end,
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
            ["MAGIC"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Farore's Wind"] = function () return can_play(SONG_ZELDA) end,
        },
    },
    ["Temple of Time"] = {
        ["events"] = {
            ["DOOR_OF_TIME_OPEN"] = function () return setting('doorOfTime', 'open') or can_play(SONG_TIME) end,
            ["TIME_TRAVEL"] = function () return event('DOOR_OF_TIME_OPEN') and has_sword_master() end,
        },
        ["exits"] = {
            ["Temple of Time Entryway"] = function () return true end,
            ["Sacred Realm"] = function () return is_adult() and event('DOOR_OF_TIME_OPEN') end,
        },
        ["locations"] = {
            ["Temple of Time Master Sword"] = function () return is_child() and event('DOOR_OF_TIME_OPEN') end,
            ["Temple of Time Sheik Song"] = function () return is_adult() and event('DOOR_OF_TIME_OPEN') and has('MEDALLION_FOREST') end,
            ["Temple of Time Light Arrows"] = function () return is_adult() and (setting('lacs', 'vanilla') and has('MEDALLION_SPIRIT') and has('MEDALLION_SHADOW') or (setting('lacs', 'custom') and special(LACS))) end,
        },
    },
    ["Sacred Realm"] = {
        ["locations"] = {
            ["Temple of Time Medallion"] = function () return true end,
        },
    },
    ["Death Mountain Crater Top"] = {
        ["events"] = {
            ["BOMBS"] = function () return has_tunic_goron_strict() end,
            ["RUPEES"] = function () return has_tunic_goron_strict() end,
            ["ARROWS"] = function () return has_tunic_goron_strict() end,
            ["MAGIC"] = function () return has_tunic_goron_strict() end,
        },
        ["exits"] = {
            ["Death Mountain Summit"] = function () return true end,
            ["Death Mountain Crater Bottom"] = function () return event('RED_BOULDER_BROKEN') or has_hover_boots() end,
            ["Death Mountain Crater Warp"] = function () return has_tunic_goron_strict() and scarecrow_longshot() end,
            ["Death Mountain Crater Generic Grotto"] = function () return has_explosives_or_hammer() end,
        },
        ["locations"] = {
            ["Death Mountain Crater GS Crate"] = function () return is_child() and can_damage_skull() end,
            ["Death Mountain Crater Alcove HP"] = function () return true end,
            ["Death Mountain Crater Scrub Child"] = function () return is_child() and can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Death Mountain Crater Bottom"] = {
        ["events"] = {
            ["RED_BOULDER_BROKEN"] = function () return can_hammer() end,
        },
        ["exits"] = {
            ["Goron City"] = function () return true end,
            ["Death Mountain Crater Warp"] = function () return can_hookshot() or has_hover_boots() end,
            ["Death Mountain Crater Top"] = function () return is_adult() end,
            ["Death Mountain Crater Scrub Grotto"] = function () return can_hammer() end,
            ["Fairy Fountain Double Magic"] = function () return can_hammer() end,
        },
    },
    ["Death Mountain Crater Warp"] = {
        ["events"] = {
            ["BEAN_DEATH_MOUNTAIN_CRATER"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Fire Temple Entry"] = function () return is_adult() and has_tunic_goron() or (is_child() and setting('fireChild')) end,
            ["Death Mountain Crater Bottom"] = function () return can_hookshot() or has_hover_boots() or can_ride_bean(BEAN_DEATH_MOUNTAIN_CRATER) end,
        },
        ["locations"] = {
            ["Death Mountain Crater Volcano HP"] = function () return can_ride_bean(BEAN_DEATH_MOUNTAIN_CRATER) or (trick('OOT_VOLCANO_HOVERS') and has_hover_boots()) end,
            ["Death Mountain Crater Sheik Song"] = function () return is_adult() end,
            ["Death Mountain Crater GS Soil"] = function () return gs_soil() and can_damage_skull() end,
        },
    },
    ["Fire Temple Entry"] = {
        ["exits"] = {
            ["Fire Temple"] = function () return true end,
            ["Death Mountain Crater Warp"] = function () return has_tunic_goron_strict() end,
        },
    },
    ["Death Mountain Crater Generic Grotto"] = {
        ["events"] = {
            ["BOMBS"] = function () return can_cut_grass() end,
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
        },
    },
    ["Death Mountain Crater Scrub Grotto"] = {
        ["exits"] = {
            ["Death Mountain Crater Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Death Mountain Crater Grotto Left Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Death Mountain Crater Grotto Center Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Death Mountain Crater Grotto Right Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Fairy Fountain Double Magic"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Death Mountain Crater Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Magic Upgrade 2"] = function () return can_play(SONG_ZELDA) end,
        },
    },
    ["Gerudo Valley"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
            ["BOMBS"] = function () return is_child() end,
            ["SEEDS"] = function () return is_child() end,
            ["MAGIC"] = function () return is_child() end,
            ["BUGS"] = function () return is_child() and has_bottle() end,
        },
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
            ["Hyrule Field"] = function () return true end,
            ["Gerudo Valley After Bridge"] = function () return can_longshot() or can_ride_epona() or (is_adult() and carpenters_rescued()) end,
            ["Octorok Grotto"] = function () return can_lift_silver() end,
        },
        ["locations"] = {
            ["Gerudo Valley Crate HP"] = function () return is_child() or can_longshot() end,
            ["Gerudo Valley Waterfall HP"] = function () return true end,
            ["Gerudo Valley GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Gerudo Valley GS Wall"] = function () return can_boomerang() and gs_night() end,
            ["Gerudo Valley Cow"] = function () return is_child() and can_play(SONG_EPONA) end,
        },
    },
    ["Gerudo Valley After Bridge"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Valley"] = function () return can_longshot() or can_ride_epona() or (is_adult() and carpenters_rescued()) end,
            ["Gerudo Valley Storms Grotto"] = function () return hidden_grotto_storms() and is_adult() end,
            ["Gerudo Valley Tent"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Gerudo Valley Chest"] = function () return can_hammer() end,
            ["Gerudo Valley Broken Goron Sword"] = function () return adult_trade(POACHER_SAW) end,
            ["Gerudo Valley GS Tent"] = function () return can_hookshot() and gs_night() end,
            ["Gerudo Valley GS Pillar"] = function () return can_hookshot() and gs_night() end,
        },
    },
    ["Octorok Grotto"] = {
        ["events"] = {
            ["RUPEES"] = function () return true end,
        },
        ["exits"] = {
            ["Gerudo Valley"] = function () return true end,
        },
    },
    ["Gerudo Valley Storms Grotto"] = {
        ["exits"] = {
            ["Gerudo Valley After Bridge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Valley Grotto Front Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Gerudo Valley Grotto Back Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
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
            ["Fortress Near Wasteland"] = function () return event('OPEN_FORTRESS_GATE') end,
            ["Gerudo Training Grounds"] = function () return has('GERUDO_CARD') and is_adult() and can_use_wallet(1) end,
            ["Gerudo Fortress Grotto"] = function () return is_adult() and hidden_grotto_storms() end,
            ["Gerudo Fortress Lower-Right Ledge"] = function () return is_child() or can_use_bow() or can_hookshot() or has('GERUDO_CARD') end,
        },
        ["locations"] = {
            ["Gerudo Fortress Archery Reward 1"] = function () return can_ride_epona() and can_use_bow() and has('GERUDO_CARD') and can_use_wallet(1) and is_day() end,
            ["Gerudo Fortress Archery Reward 2"] = function () return can_ride_epona() and can_use_bow() and has('GERUDO_CARD') and can_use_wallet(1) and is_day() end,
            ["Gerudo Fortress GS Target"] = function () return can_hookshot() and gs_night() and has('GERUDO_CARD') end,
        },
    },
    ["Gerudo Fortress Lower-Right Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Kitchen Tunnel Mid"] = function () return true end,
            ["Gerudo Fortress Carpenter 3 Bottom"] = function () return true end,
        },
    },
    ["Gerudo Fortress Lower-Center Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Lower-Right Ledge"] = function () return true end,
            ["Gerudo Fortress Carpenter 2 Top"] = function () return true end,
            ["Gerudo Fortress Carpenter 3 Top"] = function () return true end,
            ["Gerudo Fortress Kitchen Ledge Near Tunnel"] = function () return true end,
            ["Gerudo Fortress Upper-Right Ledge"] = function () return false end,
        },
    },
    ["Gerudo Fortress Upper-Center Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Kitchen Ledge Away from Tunnel"] = function () return true end,
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Upper-Right Ledge"] = function () return is_adult() end,
            ["Gerudo Fortress Upper-Left Ledge"] = function () return can_longshot() end,
            ["Gerudo Fortress Center Ledge"] = function () return true end,
        },
    },
    ["Gerudo Fortress Upper-Right Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
            ["Gerudo Fortress Lower-Right Ledge"] = function () return true end,
            ["Gerudo Fortress Upper-Left Ledge"] = function () return scarecrow_hookshot() or can_longshot() or has_hover_boots() end,
            ["Gerudo Fortress Center Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress GS Wall"] = function () return can_hookshot() and gs_night() end,
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
            ["Gerudo Fortress Carpenter 4"] = function () return true end,
            ["Gerudo Fortress Lower-Center Ledge"] = function () return true end,
        },
    },
    ["Gerudo Fortress Lower-Left Ledge"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Break Room Bottom"] = function () return true end,
        },
    },
    ["Gerudo Fortress Above Prison"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
            ["Gerudo Fortress Lower-Left Ledge"] = function () return true end,
        },
    },
    ["Fortress Near Wasteland"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return event('OPEN_FORTRESS_GATE') end,
            ["Haunted Wasteland Start"] = function () return true end,
        },
    },
    ["Gerudo Fortress Grotto"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
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
            ["BOMBCHUS"] = function () return can_use_wallet(2) end,
        },
        ["exits"] = {
            ["Haunted Wasteland Start"] = function () return can_longshot() or has_hover_boots() or trick('OOT_SAND_RIVER_NOTHING') end,
            ["Haunted Wasteland End"] = function () return has_lens_strict() or trick('OOT_BLIND_WASTELAND') end,
        },
        ["locations"] = {
            ["Haunted Wasteland Chest"] = function () return has_fire() end,
            ["Haunted Wasteland GS"] = function () return can_collect_distance() end,
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
        },
        ["locations"] = {
            ["Desert Colossus HP"] = function () return can_ride_bean(BEAN_DESERT_COLOSSUS) end,
            ["Desert Colossus GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Desert Colossus GS Tree"] = function () return can_hookshot() and gs_night() end,
            ["Desert Colossus GS Plateau"] = function () return gs_night() and (can_longshot() or can_ride_bean(BEAN_DESERT_COLOSSUS)) end,
        },
    },
    ["Desert Colossus Spirit Exit"] = {
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Desert Colossus Song Spirit"] = function () return true end,
        },
    },
    ["Fairy Fountain Nayru"] = {
        ["events"] = {
            ["MAGIC"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Great Fairy Nayru's Love"] = function () return can_play(SONG_ZELDA) end,
        },
    },
    ["Desert Colossus Grotto"] = {
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Desert Colossus Grotto Front Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
            ["Desert Colossus Grotto Back Scrub"] = function () return can_hit_scrub() and can_use_wallet(1) end,
        },
    },
    ["Shadow Temple"] = {
        ["exits"] = {
            ["Graveyard Upper"] = function () return true end,
            ["Shadow Temple Pit"] = function () return has_hover_boots() or can_hookshot() end,
        },
    },
    ["Shadow Temple Pit"] = {
        ["events"] = {
            ["MAGIC"] = function () return trick('OOT_LENS') end,
        },
        ["exits"] = {
            ["Shadow Temple Main"] = function () return has_hover_boots() and has_lens() end,
        },
        ["locations"] = {
            ["Shadow Temple Map"] = function () return has_lens() end,
            ["Shadow Temple Hover Boots"] = function () return has_lens() end,
        },
    },
    ["Shadow Temple Main"] = {
        ["exits"] = {
            ["Shadow Temple Open"] = function () return small_keys(SMALL_KEY_SHADOW, 1) and has_explosives() end,
        },
        ["locations"] = {
            ["Shadow Temple Silver Rupees"] = function () return can_hookshot() or has_hover_boots() end,
            ["Shadow Temple Compass"] = function () return true end,
        },
    },
    ["Shadow Temple Open"] = {
        ["exits"] = {
            ["Shadow Temple Wind"] = function () return small_keys(SMALL_KEY_SHADOW, 3) and can_hookshot() and has_lens() end,
        },
        ["locations"] = {
            ["Shadow Temple Spinning Blades Visible"] = function () return true end,
            ["Shadow Temple Spinning Blades Invisible"] = function () return has_lens() end,
            ["Shadow Temple Falling Spikes Lower"] = function () return true end,
            ["Shadow Temple Falling Spikes Upper 1"] = function () return has('STRENGTH') and has_lens() end,
            ["Shadow Temple Falling Spikes Upper 2"] = function () return has('STRENGTH') and has_lens() end,
            ["Shadow Temple Invisible Spike Room"] = function () return small_keys(SMALL_KEY_SHADOW, 2) and can_hookshot() and has_lens() end,
            ["Shadow Temple Skull"] = function () return small_keys(SMALL_KEY_SHADOW, 2) and can_hookshot() and has_bombs() and has_lens() end,
            ["Shadow Temple GS Skull Pot"] = function () return small_keys(SMALL_KEY_SHADOW, 2) and can_hookshot() and has_lens() end,
            ["Shadow Temple GS Falling Spikes"] = function () return can_hookshot() end,
            ["Shadow Temple GS Invisible Scythe"] = function () return true end,
        },
    },
    ["Shadow Temple Wind"] = {
        ["exits"] = {
            ["Shadow Temple Boat"] = function () return small_keys(SMALL_KEY_SHADOW, 4) and can_play(SONG_ZELDA) end,
        },
        ["locations"] = {
            ["Shadow Temple Wind Room Hint"] = function () return has_lens() end,
            ["Shadow Temple After Wind"] = function () return true end,
            ["Shadow Temple After Wind Invisible"] = function () return has_explosives() and has_lens() end,
            ["Shadow Temple GS Near Boat"] = function () return small_keys(SMALL_KEY_SHADOW, 4) and can_longshot() end,
        },
    },
    ["Shadow Temple Boat"] = {
        ["exits"] = {
            ["Shadow Temple Boss"] = function () return small_keys(SMALL_KEY_SHADOW, 5) and boss_key(BOSS_KEY_SHADOW) and (can_use_bow() or scarecrow_longshot()) end,
        },
        ["locations"] = {
            ["Shadow Temple Boss Key Room 1"] = function () return can_use_din() end,
            ["Shadow Temple Boss Key Room 2"] = function () return can_use_din() end,
            ["Shadow Temple Invisible Floormaster"] = function () return true end,
            ["Shadow Temple GS Triple Skull Pot"] = function () return can_hookshot() end,
        },
    },
    ["Spirit Temple"] = {
        ["events"] = {
            ["SPIRIT_CHILD_DOOR"] = function () return is_child() and small_keys(SMALL_KEY_SPIRIT, 5) end,
            ["SPIRIT_ADULT_DOOR"] = function () return small_keys(SMALL_KEY_SPIRIT, 3) and can_lift_silver() end,
            ["MAGIC"] = function () return true end,
        },
        ["exits"] = {
            ["Desert Colossus Spirit Exit"] = function () return true end,
            ["Spirit Temple Child Entrance"] = function () return is_child() end,
            ["Spirit Temple Adult Entrance"] = function () return can_lift_silver() end,
        },
    },
    ["Spirit Temple Child Entrance"] = {
        ["exits"] = {
            ["Spirit Temple"] = function () return is_child() end,
            ["Spirit Temple Child Climb"] = function () return is_child() and small_keys(SMALL_KEY_SPIRIT, 1) end,
            ["Spirit Temple Child Back"] = function () return can_use_sticks() or has_explosives() or ((can_boomerang() or has_nuts()) and (has_weapon() or can_use_slingshot())) end,
        },
    },
    ["Spirit Temple Child Back"] = {
        ["locations"] = {
            ["Spirit Temple Child First Chest"] = function () return has_ranged_weapon_child() end,
            ["Spirit Temple Child Second Chest"] = function () return has_ranged_weapon_child() and (can_use_sticks() or can_use_din()) end,
            ["Spirit Temple GS Child Fence"] = function () return has_ranged_weapon_child() end,
        },
    },
    ["Spirit Temple Child Climb"] = {
        ["exits"] = {
            ["Spirit Temple Child Entrance"] = function () return is_child() and small_keys(SMALL_KEY_SPIRIT, 1) end,
            ["Spirit Temple Statue"] = function () return has_explosives() end,
        },
        ["locations"] = {
            ["Spirit Temple Child Climb 1"] = function () return has_ranged_weapon_both() or (event('SPIRIT_CHILD_DOOR') and has_ranged_weapon_child()) or (event('SPIRIT_ADULT_DOOR') and has_ranged_weapon_adult()) end,
            ["Spirit Temple Child Climb 2"] = function () return has_ranged_weapon_both() or (event('SPIRIT_CHILD_DOOR') and has_ranged_weapon_child()) or (event('SPIRIT_ADULT_DOOR') and has_ranged_weapon_adult()) end,
            ["Spirit Temple GS Child Climb"] = function () return can_damage_skull() end,
        },
    },
    ["Spirit Temple Child Upper"] = {
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return true end,
            ["Spirit Temple Child Hand"] = function () return small_keys(SMALL_KEY_SPIRIT, 5) end,
        },
        ["locations"] = {
            ["Spirit Temple Sun Block Room Torches"] = function () return event('SPIRIT_CHILD_DOOR') and can_use_sticks() and has_explosives() or has_fire_spirit() or (has_fire_arrows() and small_keys(SMALL_KEY_SPIRIT, 4)) end,
            ["Spirit Temple GS Iron Knuckle"] = function () return event('SPIRIT_CHILD_DOOR') and can_boomerang() or (event('SPIRIT_ADULT_DOOR') and can_hookshot()) or (can_collect_ageless() and (has_explosives() or small_keys(SMALL_KEY_SPIRIT, 2))) end,
        },
    },
    ["Spirit Temple Child Hand"] = {
        ["exits"] = {
            ["Spirit Temple Child Upper"] = function () return small_keys(SMALL_KEY_SPIRIT, 5) end,
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Silver Gauntlets"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Entrance"] = {
        ["exits"] = {
            ["Spirit Temple Adult Climb"] = function () return small_keys(SMALL_KEY_SPIRIT, 1) end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Silver Rupees"] = function () return has_ranged_weapon_adult() or has_explosives() end,
            ["Spirit Temple Adult Lullaby"] = function () return can_play(SONG_ZELDA) and can_hookshot() end,
            ["Spirit Temple GS Boulders"] = function () return can_play(SONG_TIME) and (has_ranged_weapon_adult() or has_explosives()) end,
        },
    },
    ["Spirit Temple Adult Climb"] = {
        ["exits"] = {
            ["Spirit Temple Statue Adult"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Suns on Wall 1"] = function () return event('SPIRIT_ADULT_DOOR') end,
            ["Spirit Temple Adult Suns on Wall 2"] = function () return event('SPIRIT_ADULT_DOOR') end,
        },
    },
    ["Spirit Temple Statue"] = {
        ["exits"] = {
            ["Spirit Temple Statue Adult"] = function () return can_hookshot() end,
            ["Spirit Temple Child Climb"] = function () return true end,
            ["Spirit Temple Child Upper"] = function () return true end,
            ["Spirit Temple Boss"] = function () return boss_key(BOSS_KEY_SPIRIT) and event('SPIRIT_LIGHT_STATUE') and can_hookshot() end,
        },
        ["locations"] = {
            ["Spirit Temple Statue Base"] = function () return event('SPIRIT_CHILD_DOOR') and has_explosives() and can_use_sticks() or has_fire_spirit() or (has_fire_arrows() and small_keys(SMALL_KEY_SPIRIT, 4)) end,
            ["Spirit Temple GS Statue"] = function () return event('SPIRIT_ADULT_DOOR') and (can_hookshot() or has_hover_boots()) end,
            ["Spirit Temple Silver Gauntlets"] = function () return small_keys(SMALL_KEY_SPIRIT, 3) and has('HOOKSHOT', 2) and has_explosives() end,
        },
    },
    ["Spirit Temple Statue Adult"] = {
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return true end,
            ["Spirit Temple Adult Upper"] = function () return small_keys(SMALL_KEY_SPIRIT, 4) end,
        },
        ["locations"] = {
            ["Spirit Temple Statue Hands"] = function () return event('SPIRIT_ADULT_DOOR') and can_play(SONG_ZELDA) end,
            ["Spirit Temple Statue Upper Right"] = function () return event('SPIRIT_ADULT_DOOR') and can_play(SONG_ZELDA) and (has_hover_boots() or can_hookshot()) end,
        },
    },
    ["Spirit Temple Adult Upper"] = {
        ["exits"] = {
            ["Spirit Temple Adult Upper 2"] = function () return has_explosives() end,
            ["Spirit Temple Adult Climb 2"] = function () return small_keys(SMALL_KEY_SPIRIT, 5) end,
        },
    },
    ["Spirit Temple Adult Upper 2"] = {
        ["exits"] = {
            ["Spirit Temple Adult Hand"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Late Sun on Wall"] = function () return has_mirror_shield() end,
        },
    },
    ["Spirit Temple Adult Hand"] = {
        ["exits"] = {
            ["Spirit Temple Adult Upper"] = function () return true end,
            ["Spirit Temple Child Hand"] = function () return can_longshot() end,
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Invisible 1"] = function () return has_lens() end,
            ["Spirit Temple Adult Invisible 2"] = function () return has_lens() end,
            ["Spirit Temple Mirror Shield"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Climb 2"] = {
        ["events"] = {
            ["SPIRIT_LIGHT_STATUE"] = function () return has_mirror_shield() and has_explosives() end,
        },
        ["locations"] = {
            ["Spirit Temple Adult Boss Key Chest"] = function () return can_play(SONG_ZELDA) and can_hookshot() and can_use_bow() end,
            ["Spirit Temple Adult Topmost Sun on Wall"] = function () return has_mirror_shield() end,
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
            ["Water Temple Center Bottom"] = function () return event('WATER_LEVEL_LOW') and small_keys(SMALL_KEY_WATER, 5) end,
            ["Water Temple Center Middle"] = function () return event('WATER_LEVEL_LOW') and (can_use_din() or can_use_bow()) end,
            ["Water Temple Compass Room"] = function () return (has_tunic_zora() and has_iron_boots() or event('WATER_LEVEL_LOW')) and can_hookshot() end,
            ["Water Temple Dragon Room"] = function () return event('WATER_LEVEL_LOW') and has('STRENGTH') and can_dive_small() end,
            ["Water Temple Elevator"] = function () return small_keys(SMALL_KEY_WATER, 5) and can_hookshot() or can_use_bow() or can_use_din() end,
            ["Water Temple Corridor"] = function () return (can_longshot() or has_hover_boots()) and can_use_bow() and event('WATER_LEVEL_LOW') end,
            ["Water Temple Waterfalls"] = function () return has_tunic_zora() and small_keys(SMALL_KEY_WATER, 4) and can_longshot() and (has_iron_boots() or event('WATER_LEVEL_LOW')) end,
            ["Water Temple Large Pit"] = function () return small_keys(SMALL_KEY_WATER, 4) and event('WATER_LEVEL_RESET') end,
            ["Water Temple Antichamber"] = function () return can_longshot() and event('WATER_LEVEL_RESET') end,
            ["Water Temple Cage Room"] = function () return has_tunic_zora() and event('WATER_LEVEL_LOW') and has_explosives() and can_dive_small() end,
            ["Water Temple Main Ledge"] = function () return has_hover_boots() end,
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
            ["WATER_LEVEL_LOW"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Water Temple Map Room"] = function () return event('WATER_LEVEL_RESET') end,
            ["Water Temple Shell Room"] = function () return event('WATER_LEVEL_LOW') and (can_use_bow() or has_fire()) end,
        },
        ["locations"] = {
            ["Water Temple Bombable Chest"] = function () return event('WATER_LEVEL_MIDDLE') and has_explosives() end,
        },
    },
    ["Water Temple Map Room"] = {
        ["locations"] = {
            ["Water Temple Map"] = function () return true end,
        },
    },
    ["Water Temple Shell Room"] = {
        ["locations"] = {
            ["Water Temple Shell Chest"] = function () return true end,
        },
    },
    ["Water Temple Center Bottom"] = {
        ["exits"] = {
            ["Water Temple Under Center"] = function () return event('WATER_LEVEL_MIDDLE') and has_iron_boots() and has_tunic_zora_strict() end,
            ["Water Temple Center Middle"] = function () return can_hookshot() end,
        },
    },
    ["Water Temple Center Middle"] = {
        ["events"] = {
            ["WATER_LEVEL_MIDDLE"] = function () return can_play(SONG_ZELDA) end,
        },
        ["exits"] = {
            ["Water Temple Center Bottom"] = function () return true end,
        },
        ["locations"] = {
            ["Water Temple GS Center"] = function () return can_longshot() end,
        },
    },
    ["Water Temple Under Center"] = {
        ["locations"] = {
            ["Water Temple Under Center"] = function () return can_hookshot() end,
        },
    },
    ["Water Temple Compass Room"] = {
        ["locations"] = {
            ["Water Temple Compass"] = function () return true end,
        },
    },
    ["Water Temple Dragon Room"] = {
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
            ["Water Temple Corridor Chest"] = function () return has('STRENGTH') end,
        },
    },
    ["Water Temple Waterfalls"] = {
        ["exits"] = {
            ["Water Temple Blocks"] = function () return true end,
            ["Water Temple Waterfalls Ledge"] = function () return has_hover_boots() end,
        },
    },
    ["Water Temple Blocks"] = {
        ["exits"] = {
            ["Water Temple Waterfalls Ledge"] = function () return has_explosives() and has('STRENGTH') end,
        },
    },
    ["Water Temple Waterfalls Ledge"] = {
        ["exits"] = {
            ["Water Temple Boss Key Room"] = function () return small_keys(SMALL_KEY_WATER, 5) end,
        },
        ["locations"] = {
            ["Water Temple GS Waterfalls"] = function () return can_hookshot() end,
        },
    },
    ["Water Temple Boss Key Room"] = {
        ["locations"] = {
            ["Water Temple Boss Key Chest"] = function () return true end,
        },
    },
    ["Water Temple Large Pit"] = {
        ["exits"] = {
            ["Water Temple Before Dark Link"] = function () return small_keys(SMALL_KEY_WATER, 5) and can_hookshot() end,
        },
        ["locations"] = {
            ["Water Temple GS Large Pit"] = function () return can_longshot() end,
        },
    },
    ["Water Temple Before Dark Link"] = {
        ["exits"] = {
            ["Water Temple Dark Link"] = function () return can_hookshot() end,
        },
    },
    ["Water Temple Dark Link"] = {
        ["exits"] = {
            ["Water Temple Longshot Room"] = function () return has_weapon() end,
        },
    },
    ["Water Temple Longshot Room"] = {
        ["exits"] = {
            ["Water Temple River"] = function () return can_play(SONG_TIME) end,
        },
        ["locations"] = {
            ["Water Temple Longshot"] = function () return true end,
        },
    },
    ["Water Temple River"] = {
        ["exits"] = {
            ["Water Temple Dragon Room Ledge"] = function () return can_use_bow() end,
        },
        ["locations"] = {
            ["Water Temple River Chest"] = function () return can_use_bow() end,
            ["Water Temple GS River"] = function () return has_iron_boots() end,
        },
    },
    ["Water Temple Dragon Room Ledge"] = {
        ["exits"] = {
            ["Water Temple Dragon Room"] = function () return true end,
        },
    },
    ["Water Temple Cage Room"] = {
        ["locations"] = {
            ["Water Temple GS Cage"] = function () return can_hookshot() or has_hover_boots() end,
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
