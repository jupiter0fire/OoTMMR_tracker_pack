-- NOTE: This file is auto-generated. Any changes will be overwritten.

-- SPDX-FileCopyrightText: 2023 Wilhelm Schürmann <wimschuermann@googlemail.com>
--
-- SPDX-License-Identifier: MIT

-- This is for namespacing only, because EmoTracker doesn't seem to properly support require()
function _mm_logic()
    local M = {
        EMO = EMO,
        AccessibilityLevel = AccessibilityLevel,
        Tracker = Tracker,
        os = os,
        pairs = pairs,
        print = print,
        string = string,
        tonumber = tonumber,
        tostring = tostring,
        table = table,
        debug = debug,
        assert = assert,
    }

    -- This is used for all items, events, settings, etc., but probably shouldn't be...
    setmetatable(M, {
        __index = function(table, key)
            if string.match(key, "^[A-Z0-9_]+$") and OOTMM_CORE_ITEMS[key] then
                -- TODO: The list above is not exhaustive, and should really be removed once debugging is done.
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

    OOTMM_DEBUG = false

    OOTMM_RUNTIME_ALL_TRICKS_ENABLED = false
    OOTMM_RUNTIME_ACCESSIBILITY = {}
    OOTMM_RUNTIME_ACTIVE_EVENTS = {}
    OOTMM_RUNTIME_CACHE = {}

    function reset()
        OOTMM_RUNTIME_CACHE = {}
    end

    function get_reachable_events()
        return OOTMM_RUNTIME_ACTIVE_EVENTS
    end

    OOTMM_ITEM_PREFIX = "MM"
    OOTMM_TRICK_PREFIX = "TRICK"

    -- Inject things into the module's namespace
    -- FIXME: Does this work for functions in functions? EmoTracker's Lua includes are weird, and/or my Lua knowledge is sorely lacking...
    function inject(trackerfuncs)
        for k, v in pairs(trackerfuncs) do
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
    if EMO then
        function has(item, min_count, use_prefix)
            if OOTMM_DEBUG then
                print("EMO has:", item, min_count)
            end

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
                item_code = item
            else
                -- Function got called from raw converted logic without an item prefix.
                -- EmoTracker knows these items as "OOT_*"" / "MM_*"
                item_code = OOTMM_ITEM_PREFIX .. "_" .. item
            end

            local count = get_tracker_count(item_code)

            if not min_count then
                return count > 0
            else
                return count >= min_count
            end
        end
    else
        function has(item, min_count, use_prefix)
            if OOTMM_DEBUG then
                print("Debug has:", item, min_count)
            end

            if use_prefix == nil then
                use_prefix = true
            end

            if min_count and OOTMM_HAS_OVERRIDES[item .. ":" .. min_count] then
                item = OOTMM_HAS_OVERRIDES[item .. ":" .. min_count]
                min_count = 1
            end

            if min_count == nil then
                min_count = 1
            end

            if items[item] == nil then
                return false
            end

            return items[item] >= min_count
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

    child = true
    adult = false

    function age(x)
        return x
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
        if OOTMM_DEBUG then
            print("set_trick_mode:", mode)
        end

        if mode == "all" then
            OOTMM_RUNTIME_ALL_TRICKS_ENABLED = true
        elseif mode == "selected" then
            OOTMM_RUNTIME_ALL_TRICKS_ENABLED = false
        else
            error("Invalid trick mode: " .. mode)
        end
    end

    function trick(x)
        if OOTMM_DEBUG then
            print("trick:", x, has(OOTMM_TRICK_PREFIX .. "_" .. x), OOTMM_RUNTIME_ALL_TRICKS_ENABLED)
        end

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

        if OOTMM_RUNTIME_ACTIVE_EVENTS[x] then
            return true
        end

        return false
    end

    function cond(x, y, z)
        if x then
            return y
        else
            return z
        end
    end

    OOTMM_SETTING_OVERRIDES = {
        -- FIXME
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

        if OOTMM_DEBUG then
            print("Checking for setting:", item_name)
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

    function trace(event, line)
        local s = debug.getinfo(2).short_src
        print(s .. ":" .. line)
    end

    function set_age(age)
        if age == "child" then
            child = true
            adult = false
        elseif age == "adult" then
            child = false
            adult = true
        else
            error("Invalid age: " .. age)
        end
    end

    -- Starting at the spawn location, check all places for available locations
    function find_available_locations(child_only)
        OOTMM_RUNTIME_ACTIVE_EVENTS = {}
        local places_to_check = { "SPAWN" }
        local places_available = { "SPAWN" } -- FIXME: Remove this, for debugging only
        local places_checked = {}
        local locations_available = {}

        set_age("child")

        while #places_to_check > 0 do
            local place = table.remove(places_to_check, 1)

            if places_checked[place] then
                -- NOTE:
                -- Preventing duplicates in the first place would be better, but it would also mean
                -- changing to an actual queue [e.g. PIL 11.4] instead of an array, or adding a
                -- "places_to_check_index" table.
                -- Unless this turns out to be a major performance bottleneck, it's not worth it.
                goto continue
            end

            places_checked[place] = true

            if OOTMM_DEBUG then
                print("checking place:", place)
            end

            if logic[place] then
                if logic[place].locations then
                    for k, v in pairs(logic[place].locations) do
                        if v() then
                            locations_available[k] = 1
                        end
                    end
                end

                if logic[place].exits then
                    for k, v in pairs(logic[place].exits) do
                        if not places_checked[k] and v() then
                            table.insert(places_to_check, k)
                            table.insert(places_available, k)
                        end
                    end
                end

                if logic[place].events then
                    for k, v in pairs(logic[place].events) do
                        if not OOTMM_RUNTIME_ACTIVE_EVENTS[k] and v() then
                            OOTMM_RUNTIME_ACTIVE_EVENTS[k] = true

                            -- Reset local state, and start over.
                            -- TODO: Handle events more efficiently (see README.md)
                            set_age("child")
                            places_to_check = { "SPAWN" }
                            places_available = { "SPAWN" } -- FIXME: Remove this, for debugging only
                            places_checked = {}
                            locations_available = {}

                            if OOTMM_DEBUG then
                                print("Event triggered:", k)
                            end

                            goto continue
                        end
                    end
                end
            end

            if #places_to_check == 0 and child and not child_only then
                -- Child places depleted, start over as adult
                set_age("adult")
                places_to_check = { "SPAWN" }
                places_available = { "SPAWN" } -- FIXME: Remove this, for debugging only
                places_checked = {}
            end

            ::continue::
        end

        return locations_available
    end

    	function has_bottle()
		return has(BOTTLE_EMPTY) or has(BOTTLE_POTION_RED) or has(BOTTLE_MILK) or event(GOLD_DUST_USED) or has(BOTTLE_CHATEAU)
	end

	function can_rescue_koume()
		return has_bottle()
	end

	function has_ocarina()
		return cond(setting(sharedOcarina), cond(setting(fairyOcarinaMm), has(OCARINA), has(OCARINA, 2)), has(OCARINA))
	end

	function can_play(song)
		return has_ocarina() and has(song)
	end

	function can_break_boulders()
		return has_explosives() or has(MASK_GORON)
	end

	function can_use_lens()
		return can_use_lens_strict() or trick(MM_LENS)
	end

	function can_use_lens_strict()
		return has(MAGIC_UPGRADE) and has(LENS)
	end

	function has_explosives()
		return has(BOMB_BAG) or (has(MASK_BLAST) and has_shield())
	end

	function can_use_fire_arrows()
		return has(MAGIC_UPGRADE) and has(BOW) and has(ARROW_FIRE)
	end

	function can_use_ice_arrows()
		return has(MAGIC_UPGRADE) and has(BOW) and has(ARROW_ICE)
	end

	function can_use_light_arrows()
		return has(MAGIC_UPGRADE) and has(BOW) and has(ARROW_LIGHT)
	end

	function can_use_keg()
		return has(MASK_GORON) and has(POWDER_KEG)
	end

	function has_mirror_shield()
		return cond(setting(progressiveShieldsMm, progressive), has(SHIELD, 2), has(SHIELD_MIRROR))
	end

	function can_use_elegy()
		return can_play(SONG_EMPTINESS)
	end

	function can_use_elegy2()
		return can_play(SONG_EMPTINESS) and (has(MASK_ZORA) or has(MASK_GORON))
	end

	function can_use_elegy3()
		return can_play(SONG_EMPTINESS) and has(MASK_ZORA) and has(MASK_GORON)
	end

	function has_bombchu()
		return has(BOMB_BAG)
	end

	function has_beans()
		return event(MAGIC_BEANS_PALACE) or event(MAGIC_BEANS_SWAMP)
	end

	function has_weapon()
		return has(SWORD) or has(GREAT_FAIRY_SWORD)
	end

	function can_use_beans()
		return has_beans() and (has_bottle() or can_play(SONG_STORMS))
	end

	function scarecrow_hookshot_short()
		return has_ocarina() and can_hookshot_short()
	end

	function scarecrow_hookshot()
		return has_ocarina() and can_hookshot()
	end

	function goron_fast_roll()
		return has(MASK_GORON) and has(MAGIC_UPGRADE)
	end

	function can_use_deku_bubble()
		return has(MASK_DEKU) and has(MAGIC_UPGRADE)
	end

	function has_weapon_range()
		return has(BOW) or can_hookshot_short() or has(MASK_ZORA) or can_use_deku_bubble()
	end

	function has_paper()
		return has(DEED_LAND) or has(DEED_SWAMP) or has(DEED_MOUNTAIN) or has(DEED_OCEAN) or has(LETTER_TO_KAFEI) or has(LETTER_TO_MAMA)
	end

	function can_fight()
		return has_weapon() or has(MASK_ZORA) or has(MASK_GORON)
	end

	function has_goron_song_half()
		return cond(setting(progressiveGoronLullaby, progressive), has(SONG_GORON_HALF), has(SONG_GORON))
	end

	function has_goron_song()
		return cond(setting(progressiveGoronLullaby, progressive), has(SONG_GORON_HALF, 2), has(SONG_GORON))
	end

	function can_lullaby_half()
		return has_ocarina() and has_goron_song_half() and has(MASK_GORON)
	end

	function can_lullaby()
		return has_ocarina() and has_goron_song() and has(MASK_GORON)
	end

	function has_shield()
		return has(SHIELD_HERO) or has_mirror_shield()
	end

	function can_activate_crystal()
		return can_break_boulders() or has_weapon() or has(BOW) or can_hookshot_short() or has(MASK_DEKU) or has(MASK_ZORA)
	end

	function can_evade_gerudo()
		return has(BOW) or can_hookshot_short() or has(MASK_ZORA) or has(MASK_STONE)
	end

	function has_hot_water()
		return can_play(SONG_SOARING) and (event(GORON_GRAVEYARD_HOT_WATER) or event(TWIN_ISLANDS_HOT_WATER) or event(WELL_HOT_WATER))
	end

	function can_goron_bomb_jump()
		return trick(MM_GORON_BOMB_JUMP) and has(MASK_GORON) and has(BOMB_BAG)
	end

	function can_hookshot_short()
		return has(HOOKSHOT)
	end

	function can_hookshot()
		return cond(setting(shortHookshotMm), has(HOOKSHOT, 2), has(HOOKSHOT))
	end

	function has_blue_potion()
		return has_bottle() and (event(BLUE_POTION) or has(POTION_BLUE))
	end

	function has_red_potion()
		return has_bottle() and has(POTION_RED)
	end

	function has_milk()
		return has_bottle() and (has(MILK) or event(MILK))
	end

	function has_red_or_blue_potion()
		return has_red_potion() or has_blue_potion()
	end


    logic = {
    ["Ancient Castle of Ikana Exterior"] = {
        ["exits"] = {
            ["Beneath the Well End"] = function () return can_use_light_arrows() end,
            ["Ancient Castle of Ikana Entrance"] = function () return can_use_light_arrows() end,
            ["Ancient Castle of Ikana Interior"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Entrance"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT_ENTRANCE"] = function () return can_activate_crystal() end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Exterior"] = function () return has_mirror_shield() and event(IKANA_CASTLE_LIGHT_ENTRANCE) or can_use_light_arrows() end,
            ["Ikana Canyon"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Interior"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Exterior"] = function () return true end,
            ["Ancient Castle of Ikana Interior North"] = function () return can_use_fire_arrows() end,
            ["Ancient Castle of Ikana Interior South"] = function () return can_use_fire_arrows() end,
            ["Ancient Castle of Ikana Pre-Boss"] = function () return has_mirror_shield() and event(IKANA_CASTLE_LIGHT2) or can_use_light_arrows() end,
        },
    },
    ["Ancient Castle of Ikana Interior North"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return true end,
            ["Ancient Castle of Ikana Interior North 2"] = function () return has(MASK_DEKU) end,
        },
    },
    ["Ancient Castle of Ikana Interior North 2"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior North"] = function () return has(MASK_DEKU) end,
            ["Ancient Castle of Ikana Roof Exterior"] = function () return can_use_lens() end,
        },
    },
    ["Ancient Castle of Ikana Roof Exterior"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT"] = function () return has(MASK_DEKU) end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Interior North 2"] = function () return true end,
            ["Ancient Castle of Ikana Exterior"] = function () return true end,
        },
        ["locations"] = {
            ["Ancient Castle of Ikana HP"] = function () return (has(BOW) or can_hookshot_short()) and has(MASK_DEKU) end,
        },
    },
    ["Ancient Castle of Ikana Interior South"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return true end,
            ["Ancient Castle of Ikana Wizzrobe"] = function () return has_mirror_shield() and event(IKANA_CASTLE_LIGHT) or can_use_light_arrows() end,
        },
    },
    ["Ancient Castle of Ikana Wizzrobe"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior South"] = function () return can_use_light_arrows() end,
            ["Ancient Castle of Ikana Roof Interior"] = function () return can_fight() or has(BOW) end,
        },
    },
    ["Ancient Castle of Ikana Roof Interior"] = {
        ["events"] = {
            ["IKANA_CASTLE_LIGHT2"] = function () return can_use_keg() end,
        },
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return event(IKANA_CASTLE_LIGHT2) end,
            ["Ancient Castle of Ikana Wizzrobe"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Pre-Boss"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana Interior"] = function () return true end,
            ["Ancient Castle of Ikana Throne Room"] = function () return true end,
        },
    },
    ["Ancient Castle of Ikana Throne Room"] = {
        ["exits"] = {
            ["Ancient Castle of Ikana After Boss"] = function () return has_mirror_shield() and can_use_fire_arrows() and can_fight() end,
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
    ["Beneath the Well Entrance"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
            ["Beneath the Well North Section"] = function () return has(MASK_GIBDO) and has_blue_potion() end,
            ["Beneath the Well East Section"] = function () return has(MASK_GIBDO) and has_beans() end,
        },
    },
    ["Beneath the Well North Section"] = {
        ["events"] = {
            ["WELL_HOT_WATER"] = function () return has_bottle() and (has_explosives() or has(MASK_ZORA)) end,
        },
        ["exits"] = {
            ["Beneath the Well Entrance"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath the Well Keese Chest"] = function () return can_use_lens() end,
        },
    },
    ["Beneath the Well East Section"] = {
        ["events"] = {
            ["WELL_BIG_POE"] = function () return has(MASK_GIBDO) and has_bottle() and has(BOMB_BAG) and (has(BOW) or has(ZORA)) end,
        },
        ["exits"] = {
            ["Beneath the Well Entrance"] = function () return true end,
            ["Beneath the Well End"] = function () return event(WELL_BIG_POE) and has_milk() end,
        },
        ["locations"] = {
            ["Beneath the Well Skulltulla Chest"] = function () return has(MASK_GIBDO) and has_bottle() end,
            ["Beneath the Well Cow"] = function () return has(MASK_GIBDO) and (event(WELL_HOT_WATER) or has_hot_water()) and can_play(SONG_EPONA) end,
        },
    },
    ["Beneath the Well End"] = {
        ["exits"] = {
            ["Beneath the Well East Section"] = function () return true end,
            ["Ancient Castle of Ikana Exterior"] = function () return has_mirror_shield() or can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Beneath the Well Mirror Shield"] = function () return can_use_fire_arrows() or event(WELL_BIG_POE) end,
        },
    },
    ["Great Bay Temple"] = {
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return event(TIME_TRAVEL) end,
            ["Zora Cape Peninsula"] = function () return can_hookshot() end,
        },
    },
    ["Great Bay Temple Entrance"] = {
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return true end,
            ["Great Bay Temple Water Wheel"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Entrance Chest"] = function () return true end,
        },
    },
    ["Great Bay Temple Water Wheel"] = {
        ["events"] = {
            ["GB_WATER_WHEEL"] = function () return event(GB_PIPE_RED) and event(GB_PIPE_RED2) and can_hookshot() end,
        },
        ["exits"] = {
            ["Great Bay Temple Entrance"] = function () return true end,
            ["Great Bay Temple Central Room"] = function () return has(MASK_ZORA) end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Water Wheel Platform"] = function () return has(MASK_ZORA) or (has(MASK_GREAT_FAIRY) and (has(BOW) or can_hookshot())) end,
            ["Great Bay Temple SF Water Wheel Skulltula"] = function () return true end,
        },
    },
    ["Great Bay Temple Central Room"] = {
        ["exits"] = {
            ["Great Bay Temple Water Wheel"] = function () return true end,
            ["Great Bay Temple Map Room"] = function () return true end,
            ["Great Bay Temple Red Pipe 1"] = function () return true end,
            ["Great Bay Temple Green Pipe 1"] = function () return can_use_ice_arrows() end,
            ["Great Bay Temple Compass Room"] = function () return event(GB_WATER_WHEEL) end,
            ["Great Bay Temple Pre-Boss"] = function () return event(GB_WATER_WHEEL) end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Central Room Barrel"] = function () return true end,
            ["Great Bay Temple SF Central Room Underwater Pot"] = function () return has(MASK_ZORA) or (has(BOW) and has(MASK_GREAT_FAIRY)) end,
        },
    },
    ["Great Bay Temple Map Room"] = {
        ["exits"] = {
            ["Great Bay Temple Baba Room"] = function () return true end,
            ["Great Bay Temple Red Pipe 2"] = function () return can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Great Bay Temple Map"] = function () return true end,
            ["Great Bay Temple SF Map Room Pot"] = function () return true end,
        },
    },
    ["Great Bay Temple Baba Room"] = {
        ["exits"] = {
            ["Great Bay Temple Compass Room"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Baba Chest"] = function () return true end,
        },
    },
    ["Great Bay Temple Compass Room"] = {
        ["exits"] = {
            ["Great Bay Temple Baba Room"] = function () return true end,
            ["Great Bay Temple Central Room"] = function () return true end,
            ["Great Bay Temple Boss Key Room"] = function () return can_use_ice_arrows() and can_use_fire_arrows() end,
            ["Great Bay Temple Green Pipe 2"] = function () return event(GB_WATER_WHEEL) end,
        },
        ["locations"] = {
            ["Great Bay Temple Compass"] = function () return true end,
            ["Great Bay Temple Compass Room Underwater"] = function () return true end,
            ["Great Bay Temple SF Compass Room Pot"] = function () return true end,
        },
    },
    ["Great Bay Temple Red Pipe 1"] = {
        ["events"] = {
            ["GB_PIPE_RED"] = function () return can_use_ice_arrows() end,
        },
        ["exits"] = {
            ["Great Bay Temple Ice Arrow Room"] = function () return has(SMALL_KEY_GB, 1) end,
        },
    },
    ["Great Bay Temple Ice Arrow Room"] = {
        ["exits"] = {
            ["Great Bay Temple Red Pipe 1"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Temple Ice Arrow"] = function () return true end,
        },
    },
    ["Great Bay Temple Red Pipe 2"] = {
        ["events"] = {
            ["GB_PIPE_RED2"] = function () return can_use_ice_arrows() end,
        },
        ["exits"] = {
            ["Great Bay Temple Map Room"] = function () return true end,
        },
    },
    ["Great Bay Temple Boss Key Room"] = {
        ["events"] = {
            ["FROG_4"] = function () return has(MASK_DON_GERO) end,
        },
        ["exits"] = {
            ["Great Bay Temple Compass Room"] = function () return true end,
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
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 1 Chest"] = function () return can_hookshot() end,
        },
    },
    ["Great Bay Temple Green Pipe 2"] = {
        ["exits"] = {
            ["Great Bay Temple Green Pipe 3"] = function () return can_use_ice_arrows() and can_use_fire_arrows() end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 2 Lower Chest"] = function () return can_hookshot() or (can_use_ice_arrows() and can_hookshot_short()) end,
            ["Great Bay Temple Green Pipe 2 Upper Chest"] = function () return can_hookshot() and can_use_ice_arrows() and can_use_fire_arrows() end,
        },
    },
    ["Great Bay Temple Green Pipe 3"] = {
        ["events"] = {
            ["GB_PIPE_GREEN2"] = function () return can_use_ice_arrows() and can_use_fire_arrows() end,
        },
        ["exits"] = {
            ["Great Bay Temple Green Pipe 2"] = function () return true end,
            ["Great Bay Temple Map Room"] = function () return can_use_fire_arrows() and can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Great Bay Temple Green Pipe 3 Chest"] = function () return can_use_ice_arrows() and can_use_fire_arrows() and can_hookshot() end,
            ["Great Bay Temple SF Green Pipe 3 Barrel"] = function () return true end,
        },
    },
    ["Great Bay Temple Pre-Boss"] = {
        ["exits"] = {
            ["Great Bay Temple Central Room"] = function () return true end,
            ["Great Bay Temple Boss"] = function () return has(BOSS_KEY_GB) and event(GB_PIPE_GREEN) and event(GB_PIPE_GREEN2) end,
        },
        ["locations"] = {
            ["Great Bay Temple SF Pre-Boss Above Water"] = function () return can_use_ice_arrows() or (has(MASK_GREAT_FAIRY) and (has(BOW) or can_hookshot())) end,
            ["Great Bay Temple SF Pre-Boss Underwater"] = function () return true end,
        },
    },
    ["Great Bay Temple Boss"] = {
        ["exits"] = {
            ["Great Bay Temple After Boss"] = function () return has(MAGIC_UPGRADE) and (has(MASK_ZORA) and has(BOW) or has(MASK_FIERCE_DEITY)) end,
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
        },
    },
    ["Moon"] = {
        ["exits"] = {
            ["Moon Trial Deku Entrance"] = function () return masks(1) end,
            ["Moon Trial Goron Entrance"] = function () return masks(2) end,
            ["Moon Trial Zora"] = function () return masks(3) end,
            ["Moon Trial Link Entrance"] = function () return masks(4) end,
            ["Moon Boss"] = function () return true end,
        },
        ["locations"] = {
            ["Moon Fierce Deity Mask"] = function () return masks(20) and event(MOON_TRIAL_DEKU) and event(MOON_TRIAL_GORON) and event(MOON_TRIAL_ZORA) and event(MOON_TRIAL_LINK) end,
        },
    },
    ["Moon Trial Deku Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Deku Exit"] = function () return has(MASK_DEKU) end,
        },
        ["locations"] = {
            ["Moon Trial Deku HP"] = function () return has(MASK_DEKU) end,
        },
    },
    ["Moon Trial Deku Exit"] = {
        ["events"] = {
            ["MOON_TRIAL_DEKU"] = function () return true end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Deku Entrance"] = function () return has(MASK_DEKU) end,
        },
    },
    ["Moon Trial Goron Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Goron Exit"] = function () return goron_fast_roll() end,
        },
        ["locations"] = {
            ["Moon Trial Goron HP"] = function () return goron_fast_roll() end,
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
            ["MOON_TRIAL_ZORA"] = function () return has(MASK_ZORA) end,
        },
        ["exits"] = {
            ["Moon"] = function () return true end,
        },
        ["locations"] = {
            ["Moon Trial Zora HP"] = function () return has(MASK_ZORA) end,
        },
    },
    ["Moon Trial Link Entrance"] = {
        ["exits"] = {
            ["Moon"] = function () return true end,
            ["Moon Trial Link Rest 1"] = function () return can_fight() or has(BOW) end,
        },
    },
    ["Moon Trial Link Rest 1"] = {
        ["exits"] = {
            ["Moon Trial Link Entrance"] = function () return can_fight() or can_use_deku_bubble() or has(BOW) end,
            ["Moon Trial Link Rest 2"] = function () return can_hookshot_short() and (can_fight() or has(BOW)) end,
        },
    },
    ["Moon Trial Link Rest 2"] = {
        ["exits"] = {
            ["Moon Trial Link Rest 1"] = function () return can_fight() or has(BOW) end,
            ["Moon Trial Link Rest 3"] = function () return has_bombchu() and has(BOW) end,
        },
        ["locations"] = {
            ["Moon Trial Link Chest 1"] = function () return true end,
            ["Moon Trial Link Chest 2"] = function () return can_fight() or has(BOMB_BAG) end,
        },
    },
    ["Moon Trial Link Rest 3"] = {
        ["exits"] = {
            ["Moon Trial Link Rest 2"] = function () return can_fight() or has(BOMB_BAG) end,
            ["Moon Trial Link Exit"] = function () return has_bombchu() and can_use_fire_arrows() end,
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
            ["MAJORA_PHASE_1"] = function () return has(BOW) or has(MASK_ZORA) or (has(MASK_FIERCE_DEITY) and has(MAGIC_UPGRADE)) end,
            ["MAJORA"] = function () return event(MAJORA_PHASE_1) and (has_weapon() or has(MASK_ZORA) or has(MASK_FIERCE_DEITY)) end,
        },
    },
    ["Ocean Spider House"] = {
        ["exits"] = {
            ["Ocean Spider House Front"] = function () return event(TIME_TRAVEL) end,
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Ocean Spider House Wallet"] = function () return has(GS_TOKEN_OCEAN, 30) end,
        },
    },
    ["Ocean Spider House Front"] = {
        ["exits"] = {
            ["Ocean Spider House"] = function () return true end,
            ["Ocean Spider House Back"] = function () return has_explosives() and (can_hookshot_short() or can_goron_bomb_jump()) end,
        },
        ["locations"] = {
            ["Ocean Skulltula Entrance Right Wall"] = function () return has_explosives() and can_hookshot_short() end,
            ["Ocean Skulltula Entrance Left Wall"] = function () return has_explosives() and can_hookshot_short() end,
            ["Ocean Skulltula Entrance Web"] = function () return has_explosives() and (can_hookshot_short() or (can_use_fire_arrows() and has(MASK_ZORA))) end,
        },
    },
    ["Ocean Spider House Back"] = {
        ["exits"] = {
            ["Ocean Spider House"] = function () return has(MASK_GORON) or can_play(SONG_SOARING) end,
        },
        ["locations"] = {
            ["Ocean Skulltula 2nd Room Ceiling Edge"] = function () return can_hookshot_short() or has(MASK_ZORA) end,
            ["Ocean Skulltula 2nd Room Ceiling Plank"] = function () return can_hookshot_short() or has(MASK_ZORA) end,
            ["Ocean Skulltula 2nd Room Jar"] = function () return true end,
            ["Ocean Skulltula 2nd Room Webbed Hole"] = function () return can_hookshot_short() end,
            ["Ocean Skulltula 2nd Room Behind Skull 1"] = function () return can_hookshot_short() or has(MASK_ZORA) end,
            ["Ocean Skulltula 2nd Room Behind Skull 2"] = function () return true end,
            ["Ocean Skulltula 2nd Room Webbed Pot"] = function () return true end,
            ["Ocean Skulltula 2nd Room Upper Pot"] = function () return true end,
            ["Ocean Skulltula 2nd Room Lower Pot"] = function () return true end,
            ["Ocean Skulltula Library Hole Behind Picture"] = function () return can_hookshot() end,
            ["Ocean Skulltula Library Hole Behind Cabinet"] = function () return can_hookshot_short() end,
            ["Ocean Skulltula Library On Corner Bookshelf"] = function () return true end,
            ["Ocean Skulltula Library Behind Picture"] = function () return can_hookshot_short() or has(BOW) or has(MASK_ZORA) or can_use_deku_bubble() end,
            ["Ocean Skulltula Library Behind Bookcase 1"] = function () return true end,
            ["Ocean Skulltula Library Behind Bookcase 2"] = function () return true end,
            ["Ocean Skulltula Library Ceiling Edge"] = function () return can_hookshot_short() or has(MASK_ZORA) end,
            ["Ocean Skulltula Colored Skulls Chandelier 1"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Chandelier 2"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Chandelier 3"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Behind Picture"] = function () return can_hookshot_short() or has(MASK_ZORA) or (has(MASK_GORON) and (has(BOW) or can_use_deku_bubble())) end,
            ["Ocean Skulltula Colored Skulls Pot"] = function () return true end,
            ["Ocean Skulltula Colored Skulls Ceiling Edge"] = function () return can_hookshot_short() or has(MASK_ZORA) end,
            ["Ocean Spider House Chest HP"] = function () return has(BOW) and (has(MASK_CAPTAIN) or trick(MM_CAPTAIN_SKIP)) end,
            ["Ocean Skulltula Storage Room Behind Boat"] = function () return true end,
            ["Ocean Skulltula Storage Room Ceiling Web"] = function () return can_use_fire_arrows() and (can_hookshot_short() or has(MASK_ZORA)) end,
            ["Ocean Skulltula Storage Room Behind Crate"] = function () return can_hookshot_short() or has(MASK_ZORA) or (has(MASK_GORON) and (has(BOW) or can_use_deku_bubble() or has_explosives())) end,
            ["Ocean Skulltula Storage Room Crate"] = function () return true end,
            ["Ocean Skulltula Storage Room Jar"] = function () return can_hookshot_short() end,
        },
    },
    ["SOARING"] = {
        ["exits"] = {
            ["SPAWN"] = function () return has(SONG_SOARING) end,
        },
    },
    ["SPAWN"] = {
        ["events"] = {
            ["TIME_TRAVEL"] = function () return can_play(SONG_TIME) end,
        },
        ["exits"] = {
            ["Clock Town South"] = function () return event(TIME_TRAVEL) end,
            ["OOT SONGS"] = function () return setting(crossWarpOot) and has_ocarina() end,
        },
        ["locations"] = {
            ["Initial Song of Healing"] = function () return true end,
        },
    },
    ["Oath to Order"] = {
        ["locations"] = {
            ["Oath to Order"] = function () return true end,
        },
    },
    ["Clock Town South"] = {
        ["events"] = {
            ["CLOCK_TOWN_SCRUB"] = function () return has(MOON_TEAR) end,
            ["CLOCK_TOWN_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town North"] = function () return true end,
            ["Clock Town West"] = function () return true end,
            ["Clock Town East"] = function () return true end,
            ["Clock Town Laundry Pool"] = function () return true end,
            ["Clock Tower Roof"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town South Chest Lower"] = function () return can_hookshot() or (has(MASK_DEKU) and event(CLOCK_TOWN_SCRUB)) or trick(MM_SCT_NOTHING) or can_goron_bomb_jump() end,
            ["Clock Town South Chest Upper"] = function () return can_hookshot() or (has(MASK_DEKU) and event(CLOCK_TOWN_SCRUB)) or (can_goron_bomb_jump() and can_hookshot_short()) end,
            ["Clock Town Platform HP"] = function () return true end,
            ["Clock Town Business Scrub"] = function () return event(CLOCK_TOWN_SCRUB) end,
            ["Clock Town Post Box"] = function () return has(MASK_POSTMAN) end,
        },
    },
    ["Clock Town North"] = {
        ["events"] = {
            ["BOMBER_CODE"] = function () return has_weapon_range() end,
            ["SAKON_BOMB_BAG"] = function () return can_fight() end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South"] = function () return true end,
            ["Clock Town East"] = function () return true end,
            ["Clock Town Fairy Fountain"] = function () return true end,
            ["Deku Playground"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Tree HP"] = function () return true end,
            ["Clock Town Bomber Notebook"] = function () return event(BOMBER_CODE) or event(GUESS_BOMBER) end,
            ["Clock Town Blast Mask"] = function () return event(SAKON_BOMB_BAG) end,
            ["Clock Town Keaton HP"] = function () return has(MASK_KEATON) end,
        },
    },
    ["Clock Town West"] = {
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South"] = function () return true end,
            ["Bomb Shop"] = function () return true end,
            ["Trading Post"] = function () return true end,
            ["Curiosity Shop"] = function () return true end,
            ["Post Office"] = function () return true end,
            ["Swordsman School"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Bank Reward 1"] = function () return true end,
            ["Clock Town Bank Reward 2"] = function () return has(WALLET, 1) end,
            ["Clock Town Bank Reward 3"] = function () return has(WALLET, 2) end,
            ["Clock Town Rosa Sisters HP"] = function () return has(MASK_KAMARO) end,
        },
    },
    ["Clock Town East"] = {
        ["events"] = {
            ["GUESS_BOMBER"] = function () return trick(MM_BOMBER_SKIP) end,
        },
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Clock Town South"] = function () return true end,
            ["Mayor's Office"] = function () return true end,
            ["Town Archery"] = function () return true end,
            ["Chest Game"] = function () return true end,
            ["Honey & Darling Game"] = function () return true end,
            ["Stock Pot Inn"] = function () return true end,
            ["Milk Bar"] = function () return true end,
            ["Astral Observatory"] = function () return event(BOMBER_CODE) or trick(MM_BOMBER_SKIP) end,
        },
        ["locations"] = {
            ["Clock Town Silver Rupee Chest"] = function () return true end,
            ["Clock Town Postman Hat"] = function () return event(POSTMAN_FREEDOM) end,
        },
    },
    ["Clock Town Laundry Pool"] = {
        ["events"] = {
            ["FROG_1"] = function () return has(MASK_DON_GERO) end,
        },
        ["exits"] = {
            ["Clock Town South"] = function () return true end,
            ["Curiosity Shop Back Room"] = function () return has(LETTER_TO_KAFEI) end,
        },
        ["locations"] = {
            ["Clock Town Guru Guru Mask Bremen"] = function () return true end,
            ["Clock Town Stray Fairy"] = function () return true end,
        },
    },
    ["Clock Town Fairy Fountain"] = {
        ["exits"] = {
            ["Clock Town North"] = function () return true end,
        },
        ["locations"] = {
            ["Clock Town Great Fairy"] = function () return has(STRAY_FAIRY_TOWN) end,
            ["Clock Town Great Fairy Alt"] = function () return has(STRAY_FAIRY_TOWN) and (has(MASK_DEKU) or has(MASK_GORON) or has(MASK_ZORA)) end,
        },
    },
    ["Clock Tower Roof"] = {
        ["exits"] = {
            ["Moon"] = function () return can_play(SONG_ORDER) and special(MOON) end,
        },
        ["locations"] = {
            ["Clock Tower Roof Skull Kid Ocarina"] = function () return has_weapon_range() end,
            ["Clock Tower Roof Skull Kid Song of Time"] = function () return has_weapon_range() end,
        },
    },
    ["Bomb Shop"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Bomb Shop Item 1"] = function () return true end,
            ["Bomb Shop Item 2"] = function () return true end,
            ["Bomb Shop Bomb Bag"] = function () return true end,
            ["Bomb Shop Bomb Bag 2"] = function () return event(SAKON_BOMB_BAG) end,
        },
    },
    ["Trading Post"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Trading Post Item 1"] = function () return true end,
            ["Trading Post Item 2"] = function () return true end,
            ["Trading Post Item 3"] = function () return true end,
            ["Trading Post Item 4"] = function () return true end,
            ["Trading Post Item 5"] = function () return true end,
            ["Trading Post Item 6"] = function () return true end,
            ["Trading Post Item 7"] = function () return true end,
            ["Trading Post Item 8"] = function () return true end,
        },
    },
    ["Curiosity Shop"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Bomb Shop Bomb Bag 2"] = function () return has(WALLET, 1) end,
            ["Curiosity Shop All-Night Mask"] = function () return event(SAKON_BOMB_BAG) and has(WALLET, 2) end,
        },
    },
    ["Curiosity Shop Back Room"] = {
        ["events"] = {
            ["MEET_KAFEI"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town Laundry Pool"] = function () return true end,
        },
        ["locations"] = {
            ["Curiosity Shop Back Room Pendant of Memories"] = function () return event(MEET_KAFEI) end,
            ["Curiosity Shop Back Room Owner Reward 1"] = function () return event(MEET_KAFEI) end,
            ["Curiosity Shop Back Room Owner Reward 2"] = function () return event(MEET_KAFEI) end,
        },
    },
    ["Post Office"] = {
        ["events"] = {
            ["POSTMAN_FREEDOM"] = function () return has(LETTER_TO_MAMA) end,
        },
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Post Office HP"] = function () return has(MASK_BUNNY) end,
        },
    },
    ["Swordsman School"] = {
        ["exits"] = {
            ["Clock Town West"] = function () return true end,
        },
        ["locations"] = {
            ["Swordsman School HP"] = function () return has(SWORD) end,
        },
    },
    ["Mayor's Office"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Mayor's Office Kafei's Mask"] = function () return true end,
            ["Mayor's Office HP"] = function () return has(MASK_COUPLE) end,
        },
    },
    ["Milk Bar"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Milk Bar Troupe Leader Mask"] = function () return has_ocarina() and has(MASK_DEKU) and has(MASK_ZORA) and has(MASK_GORON) and has(MASK_ROMANI) end,
            ["Milk Bar Madame Aroma Bottle"] = function () return has(MASK_KAFEI) and has(LETTER_TO_MAMA) end,
        },
    },
    ["Town Archery"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Town Archery Reward 1"] = function () return has(BOW) end,
            ["Town Archery Reward 2"] = function () return has(BOW) end,
        },
    },
    ["Chest Game"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Chest Game HP"] = function () return has(MASK_GORON) end,
        },
    },
    ["Honey & Darling Game"] = {
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Honey & Darling Reward 1"] = function () return has(BOW) or has(BOMB_BAG) or can_use_deku_bubble() end,
            ["Honey & Darling Reward 2"] = function () return has(BOW) and has(BOMB_BAG) end,
        },
    },
    ["Stock Pot Inn"] = {
        ["events"] = {
            ["MEET_ANJU"] = function () return has(MASK_KAFEI) and (has(ROOM_KEY) or has(MASK_DEKU)) end,
        },
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
        },
        ["locations"] = {
            ["Stock Pot Inn Guest Room Chest"] = function () return has(ROOM_KEY) end,
            ["Stock Pot Inn Staff Room Chest"] = function () return true end,
            ["Stock Pot Inn Room Key"] = function () return true end,
            ["Stock Pot Inn Letter to Kafei"] = function () return event(MEET_ANJU) end,
            ["Stock Pot Inn Couple's Mask"] = function () return event(SUN_MASK) and has(PENDANT_OF_MEMORIES) and event(MEET_ANJU) end,
            ["Stock Pot Inn Grandma HP 1"] = function () return has(MASK_ALL_NIGHT) end,
            ["Stock Pot Inn Grandma HP 2"] = function () return has(MASK_ALL_NIGHT) end,
            ["Stock Pot Inn ??? HP"] = function () return has_paper() end,
        },
    },
    ["Deku Playground"] = {
        ["exits"] = {
            ["Clock Town North"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Playground Reward 1"] = function () return has(MASK_DEKU) end,
            ["Deku Playground Reward 2"] = function () return has(MASK_DEKU) end,
        },
    },
    ["Astral Observatory"] = {
        ["events"] = {
            ["SCRUB_TELESCOPE"] = function () return true end,
            ["TEAR_TELESCOPE"] = function () return true end,
        },
        ["exits"] = {
            ["Clock Town East"] = function () return true end,
            ["Astral Observatory Balcony"] = function () return true end,
        },
        ["locations"] = {
            ["Astral Observatory Passage Chest"] = function () return has_explosives() end,
        },
    },
    ["Astral Observatory Balcony"] = {
        ["exits"] = {
            ["Termina Field"] = function () return can_use_beans() or can_goron_bomb_jump() end,
            ["Astral Observatory"] = function () return true end,
        },
        ["locations"] = {
            ["Astral Observatory Moon Tear"] = function () return event(TEAR_TELESCOPE) end,
        },
    },
    ["Termina Field"] = {
        ["exits"] = {
            ["Clock Town South"] = function () return true end,
            ["Clock Town North"] = function () return true end,
            ["Clock Town East"] = function () return true end,
            ["Clock Town West"] = function () return true end,
            ["Road to Southern Swamp"] = function () return true end,
            ["Mountain Village Path Lower"] = function () return has(BOW) end,
            ["Milk Road"] = function () return true end,
            ["Great Bay Fence"] = function () return can_play(SONG_EPONA) or can_goron_bomb_jump() end,
            ["Road to Ikana Front"] = function () return true end,
            ["Astral Observatory Balcony"] = function () return has(MASK_DEKU) or can_goron_bomb_jump() end,
        },
        ["locations"] = {
            ["Termina Field Water Chest"] = function () return has(MASK_ZORA) end,
            ["Termina Field Tall Grass Chest"] = function () return true end,
            ["Termina Field Tree Stump Chest"] = function () return can_hookshot_short() or can_use_beans() end,
            ["Termina Field Kamaro Mask"] = function () return can_play(SONG_HEALING) end,
            ["Termina Field Tall Grass Grotto"] = function () return true end,
            ["Termina Field Pillar Grotto"] = function () return true end,
            ["Termina Field Peahat Grotto"] = function () return can_fight() or has(BOW) or has(MASK_DEKU) end,
            ["Termina Field Dodongo Grotto"] = function () return has_weapon() or has(BOMB_BAG) or has(MASK_GORON) or has(BOW) end,
            ["Termina Field Bio Baba Grotto"] = function () return can_break_boulders() and has(MASK_ZORA) end,
            ["Termina Field Scrub"] = function () return event(SCRUB_TELESCOPE) and has(WALLET) end,
            ["Termina Field Gossip Stones HP"] = function () return has_ocarina() and (has(MASK_GORON) and has_goron_song() or (has(MASK_DEKU) and has(SONG_AWAKENING)) or (has(MASK_ZORA) and has(SONG_ZORA))) and can_break_boulders() end,
            ["Termina Field Cow Front"] = function () return has_explosives() and can_play(SONG_EPONA) end,
            ["Termina Field Cow Back"] = function () return has_explosives() and can_play(SONG_EPONA) end,
        },
    },
    ["Road to Southern Swamp"] = {
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
            ["Termina Field"] = function () return true end,
            ["Swamp Archery"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Southern Swamp HP"] = function () return has_weapon_range() end,
            ["Road to Southern Swamp Grotto"] = function () return true end,
        },
    },
    ["Swamp Archery"] = {
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Archery Reward 1"] = function () return has(BOW) end,
            ["Swamp Archery Reward 2"] = function () return has(BOW) end,
        },
    },
    ["Swamp Front"] = {
        ["events"] = {
            ["MAGIC_BEANS_SWAMP"] = function () return has(MAGIC_BEAN) and has(MASK_DEKU) end,
            ["FROG_3"] = function () return has(MASK_DON_GERO) end,
            ["SWAMP_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Road to Southern Swamp"] = function () return true end,
            ["Tourist Information"] = function () return true end,
            ["Swamp Back"] = function () return event(BOAT_RIDE) or has(MASK_ZORA) or event(CLEAN_SWAMP) or (has(MASK_DEKU) and (has(BOW) or can_hookshot_short())) end,
            ["Swamp Potion Shop"] = function () return true end,
            ["Woods of Mystery"] = function () return true end,
        },
        ["locations"] = {
            ["Southern Swamp HP"] = function () return has(DEED_LAND) and has(MASK_DEKU) end,
            ["Southern Swamp Scrub Deed"] = function () return has(DEED_LAND) end,
        },
    },
    ["Swamp Back"] = {
        ["exits"] = {
            ["Swamp Front"] = function () return event(BOAT_RIDE) or event(CLEAN_SWAMP) or (has(BOW) and (has(MASK_DEKU) or has(MASK_ZORA) or has(MASK_GORON))) end,
            ["Deku Palace"] = function () return true end,
            ["Swamp Spider House"] = function () return has(MASK_DEKU) or has(MASK_ZORA) or event(CLEAN_SWAMP) end,
            ["Swamp Canopy Back"] = function () return event(CLEAN_SWAMP) end,
        },
        ["locations"] = {
            ["Southern Swamp Grotto"] = function () return has(MASK_DEKU) or has(MASK_ZORA) or event(CLEAN_SWAMP) end,
        },
    },
    ["Tourist Information"] = {
        ["events"] = {
            ["BOAT_RIDE"] = function () return has(PICTOGRAPH_BOX) or event(KOUME) end,
        },
        ["locations"] = {
            ["Tourist Information Pictobox"] = function () return event(KOUME) end,
            ["Tourist Information Boat Cruise"] = function () return event(KOUME) and event(CLEAN_SWAMP) and has(BOW) end,
            ["Tourist Information Tingle Picture"] = function () return has(PICTOGRAPH_BOX) end,
        },
    },
    ["Woods of Mystery"] = {
        ["events"] = {
            ["KOUME"] = function () return has_red_or_blue_potion() end,
        },
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
        },
        ["locations"] = {
            ["Woods of Mystery Grotto"] = function () return true end,
            ["Swamp Potion Shop Kotake"] = function () return true end,
        },
    },
    ["Swamp Potion Shop"] = {
        ["exits"] = {
            ["Swamp Front"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Potion Shop Kotake"] = function () return true end,
            ["Swamp Potion Shop Item 1"] = function () return has_bottle() and has(MASK_SCENTS) end,
            ["Swamp Potion Shop Item 2"] = function () return true end,
            ["Swamp Potion Shop Item 3"] = function () return true end,
        },
    },
    ["Deku Palace"] = {
        ["events"] = {
            ["MAGIC_BEANS_PALACE"] = function () return has(MASK_DEKU) or trick(MM_PALACE_GUARD_SKIP) end,
        },
        ["exits"] = {
            ["Swamp Back"] = function () return true end,
            ["Swamp Canopy Front"] = function () return has(MASK_DEKU) end,
            ["Deku Shrine"] = function () return event(CLEAN_SWAMP) end,
        },
        ["locations"] = {
            ["Deku Palace HP"] = function () return has(MASK_DEKU) or (event(CLEAN_SWAMP) and can_use_beans()) or trick(MM_PALACE_GUARD_SKIP) end,
            ["Deku Palace Grotto Chest"] = function () return (has(MASK_DEKU) or trick(MM_PALACE_GUARD_SKIP)) and (can_use_beans() or can_hookshot() or (can_hookshot_short() and trick(MM_SHORT_HOOK_HARD))) or (event(CLEAN_SWAMP) and can_use_beans()) end,
            ["Deku Palace Sonata of Awakening"] = function () return has(MASK_DEKU) and has_ocarina() and (can_use_beans() or trick(MM_PALACE_BEAN_SKIP)) end,
        },
    },
    ["Swamp Canopy Front"] = {
        ["exits"] = {
            ["Swamp Back"] = function () return true end,
            ["Deku Palace"] = function () return true end,
            ["Swamp Canopy Back"] = function () return has(MASK_DEKU) end,
        },
    },
    ["Swamp Canopy Back"] = {
        ["exits"] = {
            ["Swamp Back"] = function () return has(MASK_DEKU) or has(MASK_ZORA) or event(CLEAN_SWAMP) end,
            ["Woodfall"] = function () return true end,
            ["Swamp Canopy Front"] = function () return has(MASK_DEKU) end,
        },
        ["locations"] = {
            ["Southern Swamp Song of Soaring"] = function () return has(MASK_DEKU) end,
        },
    },
    ["Woodfall"] = {
        ["exits"] = {
            ["Swamp Canopy Back"] = function () return true end,
            ["Woodfall Shrine"] = function () return has(MASK_DEKU) end,
            ["Woodfall Near Great Fairy Fountain"] = function () return has(MASK_DEKU) or event(CLEAN_SWAMP) end,
            ["Woodfall Temple Princess Jail"] = function () return event(CLEAN_SWAMP) and event(OPEN_WOODFALL_TEMPLE) end,
        },
        ["locations"] = {
            ["Woodfall Entrance Chest"] = function () return has(MASK_DEKU) or can_hookshot() or event(CLEAN_SWAMP) end,
            ["Woodfall HP Chest"] = function () return has(MASK_DEKU) or can_hookshot() end,
        },
    },
    ["Woodfall Front of Temple"] = {
        ["exits"] = {
            ["Woodfall Temple"] = function () return true end,
            ["Woodfall Shrine"] = function () return has(MASK_DEKU) end,
            ["Woodfall"] = function () return event(CLEAN_SWAMP) end,
        },
    },
    ["Woodfall Shrine"] = {
        ["events"] = {
            ["WOODFALL_OWL"] = function () return true end,
            ["OPEN_WOODFALL_TEMPLE"] = function () return has(MASK_DEKU) and can_play(SONG_AWAKENING) end,
        },
        ["exits"] = {
            ["Woodfall"] = function () return has(MASK_DEKU) or event(CLEAN_SWAMP) end,
            ["Woodfall Near Great Fairy Fountain"] = function () return has(MASK_DEKU) or event(CLEAN_SWAMP) end,
            ["Woodfall Front of Temple"] = function () return event(OPEN_WOODFALL_TEMPLE) end,
        },
        ["locations"] = {
            ["Woodfall Near Owl Chest"] = function () return has(MASK_DEKU) or can_hookshot() end,
        },
    },
    ["Woodfall Near Great Fairy Fountain"] = {
        ["exits"] = {
            ["Woodfall"] = function () return has(MASK_DEKU) or event(CLEAN_SWAMP) end,
            ["Woodfall Shrine"] = function () return has(MASK_DEKU) end,
            ["Woodfall Great Fairy Fountain"] = function () return has(MASK_DEKU) end,
        },
        ["locations"] = {
            ["Woodfall Near Owl Chest"] = function () return can_hookshot() end,
        },
    },
    ["Woodfall Great Fairy Fountain"] = {
        ["exits"] = {
            ["Woodfall Near Great Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Great Fairy"] = function () return has(STRAY_FAIRY_WF, 15) end,
        },
    },
    ["Deku Shrine"] = {
        ["exits"] = {
            ["Deku Palace"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Shrine Mask of Scents"] = function () return event(DEKU_PRINCESS) and has_weapon_range() end,
        },
    },
    ["Mountain Village Path Lower"] = {
        ["exits"] = {
            ["Termina Field"] = function () return has(BOW) end,
            ["Mountain Village Path Upper"] = function () return can_break_boulders() or can_use_fire_arrows() or event(BOSS_SNOWHEAD) end,
        },
    },
    ["Mountain Village Path Upper"] = {
        ["exits"] = {
            ["Mountain Village Path Lower"] = function () return can_break_boulders() or can_use_fire_arrows() or event(BOSS_SNOWHEAD) end,
            ["Mountain Village"] = function () return true end,
        },
    },
    ["Mountain Village"] = {
        ["events"] = {
            ["MOUNTAIN_VILLAGE_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Mountain Village Path Upper"] = function () return true end,
            ["Twin Islands"] = function () return true end,
            ["Goron Graveyard"] = function () return can_use_lens_strict() or trick(MM_DARMANI_WALL) or (event(BOSS_SNOWHEAD) and (has(MASK_GORON) or has(MASK_ZORA))) end,
            ["Path to Snowhead Front"] = function () return true end,
            ["Blacksmith"] = function () return true end,
        },
        ["locations"] = {
            ["Mountain Village Waterfall Chest"] = function () return event(BOSS_SNOWHEAD) and can_use_lens() end,
            ["Mountain Village Don Gero Mask"] = function () return event(GORON_FOOD) end,
            ["Mountain Village Frog Choir HP"] = function () return event(BOSS_SNOWHEAD) and event(FROG_1) and event(FROG_2) and event(FROG_3) and event(FROG_4) end,
            ["Mountain Village Tunnel Grotto"] = function () return event(BOSS_SNOWHEAD) and (has(MASK_GORON) or has(MASK_ZORA)) end,
        },
    },
    ["Blacksmith"] = {
        ["events"] = {
            ["BLACKSMITH_ENABLED"] = function () return event(BOSS_SNOWHEAD) or can_use_fire_arrows() or event(GORON_GRAVEYARD_HOT_WATER) or (event(WELL_HOT_WATER) and can_play(SONG_SOARING)) end,
            ["GOLD_DUST_USED"] = function () return has(WALLET) and has(BOTTLED_GOLD_DUST) and event(BLACKSMITH_ENABLED) end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
        },
        ["locations"] = {
            ["Blacksmith Razor Blade"] = function () return event(BLACKSMITH_ENABLED) and has(WALLET) end,
            ["Blacksmith Gilded Sword"] = function () return event(GOLD_DUST_USED) end,
        },
    },
    ["Twin Islands"] = {
        ["events"] = {
            ["TWIN_ISLANDS_HOT_WATER"] = function () return (event(GORON_GRAVEYARD_HOT_WATER) or can_use_fire_arrows() or event(BOSS_SNOWHEAD) or (event(WELL_HOT_WATER) and can_play(SONG_SOARING))) and has_bottle() end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Goron Village"] = function () return true end,
            ["Goron Race"] = function () return can_use_keg() or event(POWDER_KEG_TRIAL) end,
        },
        ["locations"] = {
            ["Twin Islands Underwater Chest 1"] = function () return event(BOSS_SNOWHEAD) and has(MASK_ZORA) end,
            ["Twin Islands Underwater Chest 2"] = function () return event(BOSS_SNOWHEAD) and has(MASK_ZORA) end,
            ["Twin Islands Frozen Grotto Chest"] = function () return (event(GORON_GRAVEYARD_HOT_WATER) or can_use_fire_arrows() or event(BOSS_SNOWHEAD) or (event(WELL_HOT_WATER) and can_play(SONG_SOARING))) and has_explosives() end,
            ["Twin Islands Ramp Grotto Chest"] = function () return has_explosives() and (has(MASK_GORON) or scarecrow_hookshot()) end,
            ["Goron Elder"] = function () return has(MASK_GORON) and (event(GORON_GRAVEYARD_HOT_WATER) or can_use_fire_arrows() or (event(WELL_HOT_WATER) and can_play(SONG_SOARING))) end,
        },
    },
    ["Goron Village"] = {
        ["events"] = {
            ["POWDER_KEG_TRIAL"] = function () return (event(BOSS_SNOWHEAD) or can_use_fire_arrows()) and has(MASK_GORON) end,
        },
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
            ["Front of Lone Peak Shrine"] = function () return true end,
            ["Goron Shrine"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Village HP"] = function () return has(DEED_SWAMP) and has(MASK_DEKU) end,
            ["Goron Village Scrub Deed"] = function () return has(DEED_SWAMP) and has(MASK_DEKU) end,
            ["Goron Village Scrub Bomb Bag"] = function () return has(MASK_GORON) and has(WALLET) end,
            ["Goron Powder Keg"] = function () return event(POWDER_KEG_TRIAL) end,
        },
    },
    ["Front of Lone Peak Shrine"] = {
        ["exits"] = {
            ["Goron Village"] = function () return can_use_lens() end,
            ["Lone Peak Shrine"] = function () return true end,
        },
    },
    ["Lone Peak Shrine"] = {
        ["exits"] = {
            ["Front of Lone Peak Shrine"] = function () return true end,
        },
        ["locations"] = {
            ["Lone Peak Shrine Lens Chest"] = function () return true end,
            ["Lone Peak Shrine Boulder Chest"] = function () return has_explosives() end,
            ["Lone Peak Shrine Invisible Chest"] = function () return can_use_lens() end,
        },
    },
    ["Goron Graveyard"] = {
        ["events"] = {
            ["GORON_GRAVEYARD_HOT_WATER"] = function () return has_bottle() and has(MASK_GORON) end,
        },
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Graveyard Mask"] = function () return can_use_lens_strict() and can_play(SONG_HEALING) end,
        },
    },
    ["Goron Shrine"] = {
        ["events"] = {
            ["GORON_FOOD"] = function () return has(MASK_GORON) and has(MAGIC_UPGRADE) and (can_use_fire_arrows() or can_lullaby_half()) end,
        },
        ["exits"] = {
            ["Goron Village"] = function () return true end,
            ["Goron Shop"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Baby"] = function () return has(MASK_GORON) and can_lullaby_half() end,
        },
    },
    ["Goron Shop"] = {
        ["exits"] = {
            ["Goron Shrine"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Shop Item 1"] = function () return true end,
            ["Goron Shop Item 2"] = function () return true end,
            ["Goron Shop Item 3"] = function () return true end,
        },
    },
    ["Path to Snowhead Front"] = {
        ["exits"] = {
            ["Mountain Village"] = function () return true end,
            ["Path to Snowhead Middle"] = function () return goron_fast_roll() end,
        },
    },
    ["Path to Snowhead Middle"] = {
        ["exits"] = {
            ["Path to Snowhead Front"] = function () return true end,
            ["Path to Snowhead Back"] = function () return true end,
        },
        ["locations"] = {
            ["Path to Snowhead HP"] = function () return can_use_lens() and scarecrow_hookshot() end,
        },
    },
    ["Path to Snowhead Back"] = {
        ["exits"] = {
            ["Path to Snowhead Middle"] = function () return goron_fast_roll() end,
            ["Snowhead Entrance"] = function () return true end,
        },
        ["locations"] = {
            ["Path to Snowhead Grotto"] = function () return has_explosives() end,
        },
    },
    ["Snowhead Entrance"] = {
        ["events"] = {
            ["SNOWHEAD_OWL"] = function () return true end,
            ["OPEN_SNOWHEAD_TEMPLE"] = function () return can_lullaby() or event(BOSS_SNOWHEAD) end,
        },
        ["exits"] = {
            ["Path to Snowhead Back"] = function () return true end,
            ["Snowhead"] = function () return event(OPEN_SNOWHEAD_TEMPLE) end,
            ["Snowhead Near Great Fairy Fountain"] = function () return event(OPEN_SNOWHEAD_TEMPLE) end,
        },
    },
    ["Snowhead"] = {
        ["exits"] = {
            ["Snowhead Entrance"] = function () return event(OPEN_SNOWHEAD_TEMPLE) end,
            ["Snowhead Temple"] = function () return true end,
        },
    },
    ["Snowhead Near Great Fairy Fountain"] = {
        ["exits"] = {
            ["Snowhead Entrance"] = function () return event(OPEN_SNOWHEAD_TEMPLE) end,
            ["Snowhead Great Fairy Fountain"] = function () return true end,
        },
    },
    ["Snowhead Great Fairy Fountain"] = {
        ["exits"] = {
            ["Snowhead Near Great Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Great Fairy"] = function () return has(STRAY_FAIRY_SH, 15) end,
        },
    },
    ["Goron Race"] = {
        ["exits"] = {
            ["Twin Islands"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Race Reward"] = function () return event(BOSS_SNOWHEAD) and goron_fast_roll() end,
        },
    },
    ["Milk Road"] = {
        ["events"] = {
            ["MILK_ROAD_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
            ["Termina Field"] = function () return true end,
            ["Gorman Track"] = function () return true end,
        },
    },
    ["Romani Ranch"] = {
        ["exits"] = {
            ["Milk Road"] = function () return true end,
            ["Cucco Shack"] = function () return true end,
            ["Doggy Racetrack"] = function () return true end,
            ["Stables"] = function () return true end,
        },
        ["locations"] = {
            ["Romani Ranch Epona Song"] = function () return can_use_keg() end,
            ["Romani Ranch Aliens"] = function () return can_use_keg() and has(BOW) end,
            ["Romani Ranch Cremia Escort"] = function () return can_use_keg() and has(BOW) end,
        },
    },
    ["Cucco Shack"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Cucco Shack Bunny Mask"] = function () return has(MASK_BREMEN) end,
        },
    },
    ["Doggy Racetrack"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Doggy Racetrack Chest"] = function () return can_use_beans() or has(MASK_ZORA) or can_hookshot_short() end,
            ["Doggy Racetrack HP"] = function () return has(MASK_TRUTH) end,
        },
    },
    ["Stables"] = {
        ["exits"] = {
            ["Romani Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Romani Ranch Barn Cow Left"] = function () return can_use_keg() and can_play(SONG_EPONA) end,
            ["Romani Ranch Barn Cow Right Front"] = function () return can_use_keg() and can_play(SONG_EPONA) end,
            ["Romani Ranch Barn Cow Right Back"] = function () return can_use_keg() and can_play(SONG_EPONA) end,
        },
    },
    ["Great Bay Fence"] = {
        ["exits"] = {
            ["Termina Field"] = function () return can_play(SONG_EPONA) or can_goron_bomb_jump() end,
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Great Bay Coast"] = {
        ["events"] = {
            ["GREAT_BAY_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Fisher's Hut"] = function () return true end,
            ["Great Bay Fence"] = function () return true end,
            ["Pirate Fortress Entrance"] = function () return has(MASK_ZORA) end,
            ["Pinnacle Rock Entrance"] = function () return has(MASK_ZORA) end,
            ["Laboratory"] = function () return true end,
            ["Zora Cape"] = function () return true end,
            ["Ocean Spider House"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Coast Zora Mask"] = function () return can_play(SONG_HEALING) end,
            ["Great Bay Coast HP"] = function () return can_use_beans() and scarecrow_hookshot() end,
            ["Great Bay Coast Fisherman HP"] = function () return can_hookshot_short() and event(BOSS_GREAT_BAY) end,
            ["Great Bay Coast Fisherman Grotto"] = function () return true end,
            ["Great Bay Coast Cow Front"] = function () return can_hookshot() and can_play(SONG_EPONA) end,
            ["Great Bay Coast Cow Back"] = function () return can_hookshot() and can_play(SONG_EPONA) end,
        },
    },
    ["Great Bay Coast Captured"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Fisher's Hut"] = {
        ["events"] = {
            ["SEAHORSE"] = function () return event(PHOTO_GERUDO) and has_bottle() end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Pinnacle Rock Entrance"] = {
        ["exits"] = {
            ["Pinnacle Rock"] = function () return has(MASK_ZORA) and (event(SEAHORSE) or trick(MM_NO_SEAHORSE)) end,
            ["Great Bay Coast"] = function () return true end,
        },
    },
    ["Pinnacle Rock"] = {
        ["events"] = {
            ["ZORA_EGGS_PINNACLE_ROCK"] = function () return has(MASK_ZORA) and has_bottle() end,
        },
        ["exits"] = {
            ["Pinnacle Rock Entrance"] = function () return true end,
        },
        ["locations"] = {
            ["Pinnacle Rock Chest 1"] = function () return has(MASK_ZORA) end,
            ["Pinnacle Rock Chest 2"] = function () return has(MASK_ZORA) end,
            ["Pinnacle Rock HP"] = function () return has(MASK_ZORA) and event(SEAHORSE) end,
        },
    },
    ["Laboratory"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
        },
        ["locations"] = {
            ["Laboratory Zora Song"] = function () return event(ZORA_EGGS_HOOKSHOT_ROOM) and event(ZORA_EGGS_BARREL_MAZE) and event(ZORA_EGGS_LONE_GUARD) and event(ZORA_EGGS_TREASURE_ROOM) and event(ZORA_EGGS_PINNACLE_ROCK) and has(MASK_ZORA) and has_ocarina() end,
            ["Laboratory Fish HP"] = function () return has_bottle() end,
        },
    },
    ["Zora Cape"] = {
        ["exits"] = {
            ["Great Bay Coast"] = function () return true end,
            ["Zora Hall Entrance"] = function () return has(MASK_ZORA) end,
            ["Zora Cape Peninsula"] = function () return has(MASK_ZORA) or trick(MM_ZORA_HALL_HUMAN) end,
            ["Waterfall Cliffs"] = function () return can_hookshot() end,
            ["Great Bay Near Fairy Fountain"] = function () return can_hookshot() end,
        },
        ["locations"] = {
            ["Zora Cape Underwater Chest"] = function () return has(MASK_ZORA) end,
            ["Zora Cape Waterfall HP"] = function () return has(MASK_ZORA) end,
            ["Zora Cape Grotto"] = function () return can_break_boulders() end,
        },
    },
    ["Great Bay Near Fairy Fountain"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return true end,
            ["Great Bay Fairy Fountain"] = function () return has_explosives() end,
        },
    },
    ["Great Bay Fairy Fountain"] = {
        ["exits"] = {
            ["Great Bay Near Fairy Fountain"] = function () return true end,
        },
        ["locations"] = {
            ["Great Bay Great Fairy"] = function () return has(STRAY_FAIRY_GB, 15) end,
        },
    },
    ["Waterfall Cliffs"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return true end,
            ["Waterfall Rapids"] = function () return can_hookshot() end,
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
            ["Waterfall Rapids Beaver Race 1"] = function () return has(MASK_ZORA) end,
            ["Waterfall Rapids Beaver Race 2"] = function () return has(MASK_ZORA) end,
        },
    },
    ["Zora Hall Entrance"] = {
        ["exits"] = {
            ["Zora Cape"] = function () return has(MASK_ZORA) end,
            ["Zora Hall"] = function () return has(MASK_ZORA) end,
        },
    },
    ["Zora Hall"] = {
        ["exits"] = {
            ["Zora Hall Entrance"] = function () return has(MASK_ZORA) end,
            ["Zora Cape Peninsula"] = function () return true end,
            ["Zora Shop"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Hall Scrub HP"] = function () return has(DEED_MOUNTAIN) and has(MASK_GORON) and has(MASK_DEKU) end,
            ["Zora Hall Scrub Deed"] = function () return has(DEED_MOUNTAIN) and has(MASK_GORON) end,
            ["Zora Hall Evan HP"] = function () return has(MASK_ZORA) and has_ocarina() end,
            ["Zora Hall Scene Lights"] = function () return can_use_fire_arrows() end,
        },
    },
    ["Zora Shop"] = {
        ["exits"] = {
            ["Zora Hall"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Shop Item 1"] = function () return true end,
            ["Zora Shop Item 2"] = function () return true end,
            ["Zora Shop Item 3"] = function () return true end,
        },
    },
    ["Zora Cape Peninsula"] = {
        ["events"] = {
            ["ZORA_CAPE_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Zora Cape"] = function () return has(MASK_ZORA) or trick(MM_ZORA_HALL_HUMAN) end,
            ["Zora Hall"] = function () return true end,
            ["Great Bay Temple"] = function () return has(MASK_ZORA) and can_hookshot() and can_play(SONG_ZORA) end,
        },
    },
    ["Gorman Track"] = {
        ["events"] = {
            ["MILK"] = function () return true end,
        },
        ["exits"] = {
            ["Milk Road"] = function () return true end,
        },
        ["locations"] = {
            ["Gorman Track Garo Mask"] = function () return can_play(SONG_EPONA) end,
        },
    },
    ["Road to Ikana Front"] = {
        ["exits"] = {
            ["Termina Field"] = function () return true end,
            ["Road to Ikana Center"] = function () return can_play(SONG_EPONA) or can_goron_bomb_jump() end,
        },
        ["locations"] = {
            ["Road to Ikana Chest"] = function () return can_hookshot() or (can_hookshot_short() and trick(MM_SHORT_HOOK_HARD)) end,
            ["Road to Ikana Grotto"] = function () return has(MASK_GORON) end,
        },
    },
    ["Road to Ikana Center"] = {
        ["exits"] = {
            ["Road to Ikana Front"] = function () return can_play(SONG_EPONA) or can_goron_bomb_jump() end,
            ["Road to Ikana Top"] = function () return (has(MASK_GARO) or has(MASK_GIBDO)) and (can_hookshot() or (can_hookshot_short() and trick(MM_SHORT_HOOK_HARD))) end,
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Road to Ikana Stone Mask"] = function () return can_use_lens_strict() and has_red_or_blue_potion() end,
        },
    },
    ["Ikana Graveyard"] = {
        ["exits"] = {
            ["Road to Ikana Center"] = function () return true end,
            ["Beneath The Graveyard Night 1"] = function () return has(MASK_CAPTAIN) end,
            ["Beneath The Graveyard Night 2"] = function () return has(MASK_CAPTAIN) end,
            ["Beneath The Graveyard Night 3"] = function () return has(MASK_CAPTAIN) end,
        },
        ["locations"] = {
            ["Ikana Graveyard Captain Mask"] = function () return can_play(SONG_AWAKENING) and has(BOW) and can_fight() end,
            ["Ikana Graveyard Grotto"] = function () return has_explosives() end,
        },
    },
    ["Beneath The Graveyard Night 1"] = {
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Graveyard Chest"] = function () return can_fight() or has_explosives() or has(BOW) or can_hookshot_short() or has(MASK_DEKU) end,
            ["Beneath The Graveyard Song of Storms"] = function () return can_fight() or has_explosives() end,
        },
    },
    ["Beneath The Graveyard Night 2"] = {
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Graveyard HP"] = function () return can_fight() and has_explosives() and can_use_lens() end,
        },
    },
    ["Beneath The Graveyard Night 3"] = {
        ["exits"] = {
            ["Ikana Graveyard"] = function () return true end,
        },
        ["locations"] = {
            ["Beneath The Graveyard Dampe Chest"] = function () return has_weapon_range() end,
        },
    },
    ["Road to Ikana Top"] = {
        ["exits"] = {
            ["Road to Ikana Center"] = function () return true end,
            ["Ikana Valley"] = function () return true end,
        },
    },
    ["Ikana Valley"] = {
        ["events"] = {
            ["BLUE_POTION"] = function () return has_bottle() and has(WALLET) end,
        },
        ["exits"] = {
            ["Road to Ikana Top"] = function () return true end,
            ["Ikana Canyon"] = function () return (can_use_ice_arrows() or trick(MM_ICELESS_IKANA)) and can_hookshot() end,
            ["Secret Shrine Entrance"] = function () return true end,
            ["Sakon Hideout"] = function () return event(MEET_KAFEI) end,
            ["Swamp Front"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Valley Scrub Rupee"] = function () return has(DEED_OCEAN) and has(MASK_ZORA) end,
            ["Ikana Valley Scrub HP"] = function () return has(DEED_OCEAN) and has(MASK_ZORA) and has(MASK_DEKU) end,
            ["Ikana Valley Grotto"] = function () return true end,
        },
    },
    ["Sakon Hideout"] = {
        ["events"] = {
            ["SUN_MASK"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
        },
    },
    ["Ikana Canyon"] = {
        ["events"] = {
            ["IKANA_CANYON_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
            ["Ikana Fairy Fountain"] = function () return true end,
            ["Ikana Spring Water Cave"] = function () return true end,
            ["Music Box House"] = function () return event(IKANA_CURSE_LIFTED) end,
            ["Ghost Hut"] = function () return true end,
            ["Beneath the Well Entrance"] = function () return true end,
            ["Ancient Castle of Ikana Entrance"] = function () return true end,
            ["Stone Tower"] = function () return true end,
        },
    },
    ["Ikana Fairy Fountain"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Ikana Great Fairy"] = function () return has(STRAY_FAIRY_ST, 15) end,
        },
    },
    ["Ikana Spring Water Cave"] = {
        ["events"] = {
            ["IKANA_CURSE_LIFTED"] = function () return can_play(SONG_STORMS) end,
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
            ["Music Box House Gibdo Mask"] = function () return can_play(SONG_HEALING) end,
        },
    },
    ["Ghost Hut"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
        },
        ["locations"] = {
            ["Ghost Hut HP"] = function () return has(BOW) or can_hookshot_short() or can_use_deku_bubble() end,
        },
    },
    ["Stone Tower"] = {
        ["exits"] = {
            ["Ikana Canyon"] = function () return true end,
            ["Stone Tower Top"] = function () return (can_use_elegy3() or (can_use_elegy2() and trick(MM_ONE_MASK_STONE_TOWER))) and can_hookshot() end,
        },
    },
    ["Stone Tower Top"] = {
        ["events"] = {
            ["STONE_TOWER_OWL"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
            ["Stone Tower Front of Temple"] = function () return can_use_elegy() end,
            ["Stone Tower Top Inverted"] = function () return can_use_elegy() and can_use_light_arrows() end,
        },
    },
    ["Stone Tower Front of Temple"] = {
        ["exits"] = {
            ["Stone Tower"] = function () return true end,
            ["Stone Tower Top"] = function () return can_use_elegy3() end,
            ["Stone Tower Top Inverted"] = function () return can_use_elegy() and can_use_light_arrows() end,
            ["Stone Tower Temple"] = function () return true end,
        },
    },
    ["Stone Tower Top Inverted"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted"] = function () return true end,
            ["Stone Tower Top"] = function () return can_use_light_arrows() end,
            ["Stone Tower Top Inverted Upper"] = function () return can_use_beans() end,
        },
    },
    ["Stone Tower Top Inverted Upper"] = {
        ["exits"] = {
            ["Stone Tower Top Inverted"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Inverted Chest 1"] = function () return true end,
            ["Stone Tower Inverted Chest 2"] = function () return true end,
            ["Stone Tower Inverted Chest 3"] = function () return true end,
        },
    },
    ["Pirate Fortress Entrance"] = {
        ["events"] = {
            ["PHOTO_GERUDO"] = function () return has(PICTOGRAPH_BOX) end,
        },
        ["exits"] = {
            ["Great Bay Coast"] = function () return has(MASK_ZORA) end,
            ["Great Bay Coast Captured"] = function () return true end,
            ["Pirate Fortress Sewers"] = function () return has(MASK_ZORA) and has(MASK_GORON) end,
            ["Pirate Fortress Entrance Balcony"] = function () return can_hookshot() or (can_hookshot_short() and trick(MM_PFI_BOAT_HOOK)) end,
            ["Pirate Fortress Entrance Lookout"] = function () return can_hookshot_short() and trick(MM_PFI_BOAT_HOOK) end,
        },
        ["locations"] = {
            ["Pirate Fortress Entrance Chest 1"] = function () return has(MASK_ZORA) end,
            ["Pirate Fortress Entrance Chest 2"] = function () return has(MASK_ZORA) end,
            ["Pirate Fortress Entrance Chest 3"] = function () return has(MASK_ZORA) end,
        },
    },
    ["Pirate Fortress Entrance Balcony"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers End"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Sewers"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return true end,
            ["Pirate Fortress Sewers End"] = function () return has(MASK_ZORA) end,
        },
        ["locations"] = {
            ["Pirate Fortress Sewers Chest 1"] = function () return has(MASK_ZORA) end,
            ["Pirate Fortress Sewers Chest 2"] = function () return has(MASK_ZORA) end,
            ["Pirate Fortress Sewers Chest 3"] = function () return has(MASK_ZORA) end,
            ["Pirate Fortress Sewers HP"] = function () return has(MASK_ZORA) end,
        },
    },
    ["Pirate Fortress Sewers End"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance"] = function () return has(MASK_ZORA) end,
            ["Pirate Fortress Entrance Balcony"] = function () return true end,
        },
    },
    ["Pirate Fortress Interior"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance Balcony"] = function () return true end,
            ["Pirate Fortress Hookshot Room Upper"] = function () return can_evade_gerudo() end,
            ["Pirate Fortress Hookshot Room Lower"] = function () return true end,
            ["Pirate Fortress Lone Guard Entry"] = function () return can_hookshot_short() end,
            ["Pirate Fortress Barrel Maze Entry"] = function () return can_hookshot_short() end,
            ["Pirate Fortress Entrance Captured"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Lower Chest"] = function () return true end,
            ["Pirate Fortress Interior Upper Chest"] = function () return can_hookshot() end,
        },
    },
    ["Pirate Fortress Hookshot Room Upper"] = {
        ["events"] = {
            ["FORTRESS_BEEHIVE"] = function () return has(BOW) or can_use_deku_bubble() end,
        },
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Hookshot Room Lower"] = {
        ["events"] = {
            ["FORTRESS_BEEHIVE"] = function () return has(MASK_STONE) and can_hookshot_short() and (has(BOW) or can_use_deku_bubble()) end,
            ["ZORA_EGGS_HOOKSHOT_ROOM"] = function () return can_hookshot_short() and has(MASK_ZORA) and has_bottle() and event(FORTRESS_BEEHIVE) end,
        },
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["Pirate Fortress Entrance Captured"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Hookshot"] = function () return event(FORTRESS_BEEHIVE) end,
        },
    },
    ["Pirate Fortress Barrel Maze Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["Pirate Fortress Entrance Lookout"] = function () return true end,
            ["Pirate Fortress Barrel Maze"] = function () return true end,
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
            ["Pirate Fortress Barrel Maze Aquarium"] = function () return has_weapon() and can_evade_gerudo() end,
            ["Pirate Fortress Entrance Captured"] = function () return true end,
        },
    },
    ["Pirate Fortress Barrel Maze Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_BARREL_MAZE"] = function () return can_hookshot_short() and has(MASK_ZORA) and has_bottle() end,
        },
        ["exits"] = {
            ["Pirate Fortress Barrel Maze"] = function () return has_weapon() end,
            ["Pirate Fortress Barrel Maze Exit"] = function () return true end,
        },
    },
    ["Pirate Fortress Barrel Maze Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Barrel Maze Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return true end,
            ["Pirate Fortress Lone Guard"] = function () return true end,
            ["Pirate Fortress Treasure Room Entry"] = function () return can_hookshot() end,
        },
    },
    ["Pirate Fortress Lone Guard"] = {
        ["exits"] = {
            ["Pirate Fortress Lone Guard Aquarium"] = function () return has_weapon() and can_evade_gerudo() end,
            ["Pirate Fortress Lone Guard Entry"] = function () return true end,
            ["Pirate Fortress Entrance Captured"] = function () return true end,
        },
    },
    ["Pirate Fortress Lone Guard Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_LONE_GUARD"] = function () return can_hookshot_short() and has(MASK_ZORA) and has_bottle() end,
        },
        ["exits"] = {
            ["Pirate Fortress Lone Guard"] = function () return has_weapon() end,
            ["Pirate Fortress Lone Guard Exit"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Aquarium"] = function () return has(MASK_ZORA) and can_hookshot_short() end,
        },
    },
    ["Pirate Fortress Lone Guard Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Lone Guard Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room Entry"] = {
        ["exits"] = {
            ["Pirate Fortress Interior"] = function () return can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room"] = function () return true end,
            ["Pirate Fortress Entrance Captured"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room"] = {
        ["exits"] = {
            ["Pirate Fortress Treasure Room Aquarium"] = function () return has_weapon() and can_evade_gerudo() end,
            ["Pirate Fortress Treasure Room Entry"] = function () return true end,
            ["Pirate Fortress Entrance Captured"] = function () return true end,
        },
        ["locations"] = {
            ["Pirate Fortress Interior Silver Rupee Chest"] = function () return can_evade_gerudo() end,
        },
    },
    ["Pirate Fortress Treasure Room Aquarium"] = {
        ["events"] = {
            ["ZORA_EGGS_TREASURE_ROOM"] = function () return can_hookshot_short() and has(MASK_ZORA) and has_bottle() end,
        },
        ["exits"] = {
            ["Pirate Fortress Treasure Room"] = function () return has_weapon() end,
            ["Pirate Fortress Treasure Room Exit"] = function () return true end,
        },
    },
    ["Pirate Fortress Treasure Room Exit"] = {
        ["exits"] = {
            ["Pirate Fortress Treasure Room Aquarium"] = function () return true end,
            ["Pirate Fortress Interior"] = function () return true end,
        },
    },
    ["Pirate Fortress Entrance Captured"] = {
        ["exits"] = {
            ["Pirate Fortress Entrance Balcony"] = function () return true end,
        },
    },
    ["Secret Shrine Entrance"] = {
        ["exits"] = {
            ["Ikana Valley"] = function () return true end,
            ["Secret Shrine Main"] = function () return can_use_light_arrows() end,
        },
    },
    ["Secret Shrine Main"] = {
        ["exits"] = {
            ["Secret Shrine Boss 1"] = function () return true end,
            ["Secret Shrine Boss 2"] = function () return true end,
            ["Secret Shrine Boss 3"] = function () return true end,
            ["Secret Shrine Boss 4"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine HP Chest"] = function () return event(SECRET_SHRINE_1) and event(SECRET_SHRINE_2) and event(SECRET_SHRINE_3) and event(SECRET_SHRINE_4) end,
        },
    },
    ["Secret Shrine Boss 1"] = {
        ["events"] = {
            ["SECRET_SHRINE_1"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Boss 1 Chest"] = function () return event(SECRET_SHRINE_1) end,
        },
    },
    ["Secret Shrine Boss 2"] = {
        ["events"] = {
            ["SECRET_SHRINE_2"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Boss 2 Chest"] = function () return event(SECRET_SHRINE_2) end,
        },
    },
    ["Secret Shrine Boss 3"] = {
        ["events"] = {
            ["SECRET_SHRINE_3"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Boss 3 Chest"] = function () return event(SECRET_SHRINE_3) end,
        },
    },
    ["Secret Shrine Boss 4"] = {
        ["events"] = {
            ["SECRET_SHRINE_4"] = function () return true end,
        },
        ["locations"] = {
            ["Secret Shrine Boss 4 Chest"] = function () return event(SECRET_SHRINE_4) end,
        },
    },
    ["Snowhead Temple"] = {
        ["exits"] = {
            ["Snowhead Temple Entrance"] = function () return event(TIME_TRAVEL) end,
            ["Snowhead"] = function () return true end,
        },
    },
    ["Snowhead Temple Entrance"] = {
        ["exits"] = {
            ["Snowhead Temple"] = function () return true end,
            ["Snowhead Temple Main"] = function () return has(MASK_GORON) or has(MASK_ZORA) end,
        },
    },
    ["Snowhead Temple Main"] = {
        ["exits"] = {
            ["Snowhead Temple Entrance"] = function () return true end,
            ["Snowhead Temple Compass Room"] = function () return has(SMALL_KEY_SH, 3) or (has_explosives() and has(SMALL_KEY_SH, 2)) end,
            ["Snowhead Temple Bridge Front"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return can_use_fire_arrows() or has_hot_water() end,
        },
    },
    ["Snowhead Temple Bridge Front"] = {
        ["exits"] = {
            ["Snowhead Temple Main"] = function () return true end,
            ["Snowhead Temple Bridge Back"] = function () return goron_fast_roll() or can_hookshot() end,
        },
        ["locations"] = {
            ["Snowhead Temple Bridge Room"] = function () return can_hookshot_short() end,
            ["Snowhead Temple SF Bridge Under Platform"] = function () return (has(BOW) or can_hookshot()) and has(MASK_GREAT_FAIRY) end,
            ["Snowhead Temple SF Bridge Pillar"] = function () return can_use_lens() and (has(BOW) or can_hookshot_short()) and has(MASK_GREAT_FAIRY) end,
        },
    },
    ["Snowhead Temple Bridge Back"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room"] = function () return true end,
            ["Snowhead Temple Bridge Front"] = function () return true end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Bridge Room"] = function () return can_use_fire_arrows() end,
            ["Snowhead Temple SF Bridge Under Platform"] = function () return has_weapon_range() and has(MASK_GREAT_FAIRY) end,
        },
    },
    ["Snowhead Temple Map Room"] = {
        ["exits"] = {
            ["Snowhead Temple Bridge Back"] = function () return true end,
            ["Snowhead Temple Map Room Upper"] = function () return can_use_fire_arrows() end,
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
            ["Snowhead Temple Center Level 2 Dual"] = function () return goron_fast_roll() end,
            ["Snowhead Temple Fire Arrow"] = function () return goron_fast_roll() or (can_use_lens() and scarecrow_hookshot() and has(MASK_DEKU)) end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return can_use_fire_arrows() end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return can_use_lens() and scarecrow_hookshot() end,
        },
        ["locations"] = {
            ["Snowhead Temple Map Alcove"] = function () return can_use_lens() or can_hookshot() end,
            ["Snowhead Temple Central Room Alcove"] = function () return scarecrow_hookshot() and can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 1"] = {
        ["exits"] = {
            ["Snowhead Temple Bridge Back"] = function () return true end,
            ["Snowhead Temple Center Level 0"] = function () return true end,
            ["Snowhead Temple Block Room"] = function () return true end,
            ["Snowhead Temple Pillars Room"] = function () return can_use_fire_arrows() end,
            ["Snowhead Temple Main"] = function () return can_use_fire_arrows() end,
            ["Snowhead Temple Map Room Upper"] = function () return scarecrow_hookshot() end,
        },
    },
    ["Snowhead Temple Pillars Room"] = {
        ["events"] = {
            ["SNOWHEAD_RAISE_PILLAR"] = function () return has(MASK_GORON) end,
        },
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Pillars Room"] = function () return true end,
        },
    },
    ["Snowhead Temple Center Level 0"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Bottom"] = function () return has(MASK_GORON) end,
        },
    },
    ["Snowhead Temple Block Room"] = {
        ["events"] = {
            ["SNOWHEAD_PUSH_BLOCK"] = function () return true end,
        },
        ["exits"] = {
            ["Snowhead Temple Center Level 1"] = function () return true end,
            ["Snowhead Temple Block Room Upper"] = function () return can_hookshot_short() or (event(SNOWHEAD_PUSH_BLOCK) and has(MASK_ZORA)) end,
        },
        ["locations"] = {
            ["Snowhead Temple Block Room"] = function () return true end,
        },
    },
    ["Snowhead Temple Block Room Upper"] = {
        ["exits"] = {
            ["Snowhead Temple Block Room"] = function () return true end,
            ["Snowhead Temple Compass Room"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Block Room Ledge"] = function () return event(SNOWHEAD_PUSH_BLOCK) end,
        },
    },
    ["Snowhead Temple Compass Room"] = {
        ["exits"] = {
            ["Snowhead Temple Main"] = function () return has(SMALL_KEY_SH, 3) or (has_explosives() and has(SMALL_KEY_SH, 2)) end,
            ["Snowhead Temple Block Room Upper"] = function () return can_use_fire_arrows() or can_hookshot_short() or can_goron_bomb_jump() end,
            ["Snowhead Temple Icicles"] = function () return has_explosives() end,
        },
        ["locations"] = {
            ["Snowhead Temple Compass"] = function () return true end,
            ["Snowhead Temple Compass Room Ledge"] = function () return can_use_fire_arrows() end,
            ["Snowhead Temple SF Compass Room Crate"] = function () return (can_use_fire_arrows() or can_hookshot_short()) and (has_explosives() or has(MASK_GORON)) or (has(MASK_GREAT_FAIRY) and has(BOMB_BAG)) or can_goron_bomb_jump() end,
        },
    },
    ["Snowhead Temple Icicles"] = {
        ["exits"] = {
            ["Snowhead Temple Compass Room"] = function () return has_explosives() end,
            ["Snowhead Temple Dual Switches"] = function () return has(SMALL_KEY_SH, 3) or (has_explosives() and has(SMALL_KEY_SH, 2)) end,
        },
        ["locations"] = {
            ["Snowhead Temple Icicle Room Alcove"] = function () return can_use_lens() end,
            ["Snowhead Temple Icicle Room"] = function () return (has(BOW) or has(MASK_ZORA) or can_use_lens()) and can_break_boulders() or (can_hookshot_short() and has_explosives()) end,
        },
    },
    ["Snowhead Temple Dual Switches"] = {
        ["exits"] = {
            ["Snowhead Temple Icicles"] = function () return has(SMALL_KEY_SH, 3) or (has_explosives() and has(SMALL_KEY_SH, 2)) end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return can_use_fire_arrows() or has(MASK_GORON) end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Dual Switches"] = function () return can_use_lens() and has(BOW) and has(MASK_GREAT_FAIRY) end,
        },
    },
    ["Snowhead Temple Center Level 2 Dual"] = {
        ["exits"] = {
            ["Snowhead Temple Dual Switches"] = function () return true end,
            ["Snowhead Temple Map Room Upper"] = function () return goron_fast_roll() or can_hookshot() end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
    },
    ["Snowhead Temple Fire Arrow"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return goron_fast_roll() or (can_use_lens() and scarecrow_hookshot() and has(MASK_DEKU)) end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return can_hookshot() end,
            ["Snowhead Temple Center Level 1"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Fire Arrow"] = function () return true end,
            ["Snowhead Temple Central Room Alcove"] = function () return scarecrow_hookshot() and can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 3 Snow"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return true end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return has(MASK_GORON) or can_hookshot() end,
            ["Snowhead Temple Snow Room"] = function () return has(SMALL_KEY_SH, 3) end,
            ["Snowhead Temple Fire Arrow"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Alcove"] = function () return can_use_lens() end,
        },
    },
    ["Snowhead Temple Center Level 3 Iced"] = {
        ["exits"] = {
            ["Snowhead Temple Map Room Upper"] = function () return true end,
            ["Snowhead Temple Center Level 2 Dual"] = function () return has_weapon() or has(MASK_ZORA) or has(MASK_GORON) end,
            ["Snowhead Temple Fire Arrow"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return has(MASK_GORON) or can_hookshot() end,
            ["Snowhead Temple Center Level 4"] = function () return event(SNOWHEAD_RAISE_PILLAR) end,
        },
        ["locations"] = {
            ["Snowhead Temple Central Room Alcove"] = function () return can_use_lens() end,
        },
    },
    ["Snowhead Temple Snow Room"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 3 Snow"] = function () return has(SMALL_KEY_SH, 3) end,
            ["Snowhead Temple Dinolfos Room"] = function () return can_use_fire_arrows() end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Snow Room"] = function () return can_use_lens() and (has(BOW) or can_hookshot_short()) and has(MASK_GREAT_FAIRY) end,
        },
    },
    ["Snowhead Temple Dinolfos Room"] = {
        ["exits"] = {
            ["Snowhead Temple Snow Room"] = function () return true end,
            ["Snowhead Temple Boss Key Room"] = function () return event(SNOWHEAD_RAISE_PILLAR) end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return true end,
        },
        ["locations"] = {
            ["Snowhead Temple SF Dinolfos 1"] = function () return true end,
            ["Snowhead Temple SF Dinolfos 2"] = function () return true end,
        },
    },
    ["Snowhead Temple Boss Key Room"] = {
        ["exits"] = {
            ["Snowhead Temple Dinolfos Room"] = function () return event(SNOWHEAD_RAISE_PILLAR) end,
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return event(SNOWHEAD_RAISE_PILLAR) end,
        },
        ["locations"] = {
            ["Snowhead Temple Boss Key"] = function () return true end,
        },
    },
    ["Snowhead Temple Center Level 4"] = {
        ["exits"] = {
            ["Snowhead Temple Center Level 3 Iced"] = function () return true end,
            ["Snowhead Temple Center Level 3 Snow"] = function () return true end,
            ["Snowhead Temple Boss"] = function () return goron_fast_roll() and has(BOSS_KEY_SH) end,
            ["Snowhead Temple Boss Key Room"] = function () return has(MASK_GORON) end,
            ["Snowhead Temple Dinolfos Room"] = function () return has(MASK_GORON) end,
        },
    },
    ["Snowhead Temple Boss"] = {
        ["exits"] = {
            ["Snowhead Temple After Boss"] = function () return can_use_fire_arrows() end,
        },
    },
    ["Snowhead Temple After Boss"] = {
        ["events"] = {
            ["BOSS_SNOWHEAD"] = function () return true end,
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
            ["Stone Tower Temple Entrance"] = function () return event(TIME_TRAVEL) end,
            ["Stone Tower Front of Temple"] = function () return true end,
        },
    },
    ["Stone Tower Temple Entrance"] = {
        ["exits"] = {
            ["Stone Tower Temple"] = function () return true end,
            ["Stone Tower Temple West"] = function () return true end,
            ["Stone Tower Temple Water Room"] = function () return can_use_light_arrows() or event(STONE_TOWER_EAST_ENTRY_BLOCK) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Entrance Chest"] = function () return has(BOW) end,
            ["Stone Tower Temple Entrance Switch Chest"] = function () return event(STONE_TOWER_ENTRANCE_CHEST_SWITCH) end,
        },
    },
    ["Stone Tower Temple West"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return true end,
            ["Stone Tower Temple West Garden"] = function () return can_play(SONG_EMPTINESS) and has(MASK_GORON) and has_explosives() end,
        },
    },
    ["Stone Tower Temple West Garden"] = {
        ["events"] = {
            ["STONE_TOWER_WEST_GARDEN_LIGHT"] = function () return has_explosives() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Under West Garden"] = function () return true end,
            ["Stone Tower Temple Center Ledge"] = function () return has(SMALL_KEY_ST, 4) or (has(SMALL_KEY_ST, 3) and has(MASK_ZORA)) end,
        },
    },
    ["Stone Tower Temple Under West Garden"] = {
        ["exits"] = {
            ["Stone Tower Temple West Garden"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Under West Garden Ledge Chest"] = function () return can_hookshot() end,
            ["Stone Tower Temple Under West Garden Lava Chest"] = function () return event(STONE_TOWER_WEST_GARDEN_LIGHT) and has_mirror_shield() or can_use_light_arrows() end,
            ["Stone Tower Temple Map"] = function () return event(STONE_TOWER_WEST_GARDEN_LIGHT) and has_mirror_shield() or can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Center Ledge"] = {
        ["exits"] = {
            ["Stone Tower Temple West Garden"] = function () return has(SMALL_KEY_ST, 4) or (has(SMALL_KEY_ST, 3) and has(MASK_GORON) and has_explosives() and can_play(SONG_EMPTINESS)) end,
            ["Stone Tower Temple Center"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Center Sun Block Chest"] = function () return (has(MASK_ZORA) or has(MASK_DEKU) or has_explosives() or (has(MAGIC_UPGRADE) and (has_weapon() and has(SPIN_UPGRADE))) or has(SWORD, 3) or has(GREAT_FAIRY_SWORD) or can_use_ice_arrows()) and can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Center"] = {
        ["exits"] = {
            ["Stone Tower Temple Water Room"] = function () return has(MASK_ZORA) end,
            ["Stone Tower Temple Center Ledge"] = function () return has(MASK_ZORA) end,
            ["Stone Tower Temple Water Bridge"] = function () return can_goron_bomb_jump() and can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Stone Tower Temple Center Across Water Chest"] = function () return true end,
        },
    },
    ["Stone Tower Temple Water Room"] = {
        ["events"] = {
            ["STONE_TOWER_WATER_CHEST_SWITCH"] = function () return has(MASK_ZORA) end,
            ["STONE_TOWER_EAST_ENTRY_BLOCK"] = function () return has_mirror_shield() or can_use_light_arrows() end,
        },
        ["exits"] = {
            ["Stone Tower Temple Center"] = function () return has(MASK_ZORA) end,
            ["Stone Tower Temple Mirrors Room"] = function () return has(SMALL_KEY_ST, 4) end,
            ["Stone Tower Temple Entrance"] = function () return event(STONE_TOWER_EAST_ENTRY_BLOCK) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Compass"] = function () return event(STONE_TOWER_EAST_ENTRY_BLOCK) end,
            ["Stone Tower Temple Water Sun Switch Chest"] = function () return has(MASK_ZORA) and event(STONE_TOWER_WATER_CHEST_SUN) end,
        },
    },
    ["Stone Tower Temple Mirrors Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Water Room"] = function () return has(SMALL_KEY_ST, 4) end,
            ["Stone Tower Temple Wind Room"] = function () return has(MASK_GORON) and has_mirror_shield() or can_use_light_arrows() end,
        },
        ["locations"] = {
            ["Stone Tower Temple Mirrors Room Center Chest"] = function () return has(MASK_GORON) and has_mirror_shield() or can_use_light_arrows() end,
            ["Stone Tower Temple Mirrors Room Right Chest"] = function () return has(MASK_GORON) and has_mirror_shield() or can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Wind Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Light Arrow Room"] = function () return has(MASK_DEKU) or can_use_light_arrows() end,
            ["Stone Tower Temple Mirrors Room"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Wind Room Ledge Chest"] = function () return has(MASK_DEKU) end,
            ["Stone Tower Temple Wind Room Jail Chest"] = function () return (has(MASK_DEKU) or can_use_light_arrows()) and has(MASK_GORON) end,
        },
    },
    ["Stone Tower Temple Light Arrow Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Before Water Bridge"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Light Arrow"] = function () return true end,
        },
    },
    ["Stone Tower Temple Before Water Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Water Bridge"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Temple Before Water Bridge Chest"] = function () return event(STONE_TOWER_BRIDGE_CHEST_SWITCH) or has_explosives() end,
        },
    },
    ["Stone Tower Temple Water Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Entrance"] = function () return true end,
            ["Stone Tower Temple Center"] = function () return can_goron_bomb_jump() end,
            ["Stone Tower Temple Center Ledge"] = function () return can_goron_bomb_jump() and can_use_ice_arrows() end,
        },
        ["locations"] = {
            ["Stone Tower Temple Water Bridge Chest"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Entrance"] = function () return event(TIME_TRAVEL) end,
            ["Stone Tower Top Inverted"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Entrance"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted"] = function () return true end,
            ["Stone Tower Temple Inverted East"] = function () return can_use_light_arrows() end,
            ["Stone Tower Temple Inverted Entrance Ledge"] = function () return trick(MM_ISTT_ENTRY_JUMP) and has(BOMB_BAG) end,
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
            ["Stone Tower Temple Inverted Entrance"] = function () return can_use_light_arrows() end,
            ["Stone Tower Temple Inverted Wizzrobe"] = function () return has(MASK_DEKU) and can_use_light_arrows() and has(SMALL_KEY_ST, 3) end,
            ["Stone Tower Temple Inverted Bridge"] = function () return trick(MM_ISTT_EYEGORE) and has_shield() and has_explosives() end,
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return trick(MM_ISTT_EYEGORE) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted East Lower Chest"] = function () return has(MASK_DEKU) and can_use_fire_arrows() end,
            ["Stone Tower Temple Inverted East Middle Chest"] = function () return has(MASK_DEKU) end,
            ["Stone Tower Temple Inverted East Upper Chest"] = function () return has(MASK_DEKU) and can_use_elegy() and event(STONE_TOWER_WATER_CHEST_SWITCH) end,
        },
    },
    ["Stone Tower Temple Inverted Wizzrobe"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Wizzrobe Ledge"] = function () return can_hookshot_short() end,
            ["Stone Tower Temple Inverted East"] = function () return can_use_light_arrows() and has(SMALL_KEY_ST, 4) end,
        },
    },
    ["Stone Tower Temple Inverted Wizzrobe Ledge"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Wizzrobe"] = function () return true end,
            ["Stone Tower Temple Inverted Death Armos Maze"] = function () return has(MASK_DEKU) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Wizrobe Chest"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Death Armos Maze"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Center"] = function () return true end,
            ["Stone Tower Temple Inverted Wizzrobe Ledge"] = function () return has(MASK_DEKU) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Under Wizrobe Chest"] = function () return can_use_elegy() end,
        },
    },
    ["Stone Tower Temple Inverted Center"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return has(MASK_DEKU) and has_weapon_range() end,
            ["Stone Tower Temple Inverted Entrance Ledge"] = function () return true end,
            ["Stone Tower Temple Inverted Death Armos Maze"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Boss Key Room"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Center"] = function () return has(MASK_DEKU) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Boss Key"] = function () return can_use_light_arrows() end,
        },
    },
    ["Stone Tower Temple Inverted Entrance Ledge"] = {
        ["events"] = {
            ["STONE_TOWER_ENTRANCE_CHEST_SWITCH"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Inverted Bridge"] = function () return has(SMALL_KEY_ST, 4) and can_hookshot() end,
            ["Stone Tower Temple Inverted Center"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Bridge"] = {
        ["exits"] = {
            ["Stone Tower Temple Inverted Bridge 2"] = function () return true end,
            ["Stone Tower Temple Inverted Boss Key Room"] = function () return trick(MM_ISTT_EYEGORE) and (has(MASK_GORON) or has_explosives()) end,
            ["Stone Tower Temple Inverted Center"] = function () return trick(MM_ISTT_EYEGORE) and (has(MASK_GORON) or has_explosives()) end,
        },
        ["locations"] = {
            ["Stone Tower Temple Inverted Giant Mask"] = function () return true end,
        },
    },
    ["Stone Tower Temple Inverted Bridge 2"] = {
        ["events"] = {
            ["STONE_TOWER_BRIDGE_CHEST_SWITCH"] = function () return true end,
        },
        ["exits"] = {
            ["Stone Tower Temple Boss"] = function () return can_hookshot_short() and has(BOSS_KEY_ST) end,
        },
    },
    ["Stone Tower Temple Boss"] = {
        ["exits"] = {
            ["Stone Tower After Boss"] = function () return has(MAGIC_UPGRADE) and (has(MASK_GIANT) and has(SWORD) or has(MASK_FIERCE_DEITY)) end,
        },
    },
    ["Stone Tower After Boss"] = {
        ["exits"] = {
            ["Oath to Order"] = function () return true end,
        },
        ["locations"] = {
            ["Stone Tower Boss HC"] = function () return true end,
            ["Stone Tower Boss"] = function () return true end,
        },
    },
    ["Swamp Spider House"] = {
        ["exits"] = {
            ["Swamp Back"] = function () return true end,
            ["Swamp Spider House Main"] = function () return event(TIME_TRAVEL) end,
        },
        ["locations"] = {
            ["Swamp Spider House Mask of Truth"] = function () return has(GS_TOKEN_SWAMP, 30) end,
        },
    },
    ["Swamp Spider House Main"] = {
        ["exits"] = {
            ["Swamp Spider House"] = function () return true end,
        },
        ["locations"] = {
            ["Swamp Skulltula Main Room Near Ceiling"] = function () return can_hookshot_short() or has(MASK_ZORA) or (has(MASK_DEKU) and (has(BOW) or has(MAGIC_UPGRADE) or has(BOMB_BAG))) end,
            ["Swamp Skulltula Main Room Lower Right Soft Soil"] = function () return has_bottle() end,
            ["Swamp Skulltula Main Room Lower Left Soft Soil"] = function () return has_bottle() end,
            ["Swamp Skulltula Main Room Upper Soft Soil"] = function () return has_bottle() end,
            ["Swamp Skulltula Main Room Upper Pillar"] = function () return true end,
            ["Swamp Skulltula Main Room Pillar"] = function () return true end,
            ["Swamp Skulltula Main Room Water"] = function () return true end,
            ["Swamp Skulltula Main Room Jar"] = function () return true end,
            ["Swamp Skulltula Gold Room Near Ceiling"] = function () return can_hookshot_short() or has(MASK_ZORA) or can_use_beans() end,
            ["Swamp Skulltula Gold Room Pillar"] = function () return true end,
            ["Swamp Skulltula Gold Room Wall"] = function () return true end,
            ["Swamp Skulltula Tree Room Hive"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Tree Room Grass 1"] = function () return true end,
            ["Swamp Skulltula Tree Room Grass 2"] = function () return true end,
            ["Swamp Skulltula Tree Room Tree 1"] = function () return true end,
            ["Swamp Skulltula Tree Room Tree 2"] = function () return true end,
            ["Swamp Skulltula Tree Room Tree 3"] = function () return true end,
            ["Swamp Skulltula Monument Room Lower Wall"] = function () return can_hookshot_short() or has(MASK_ZORA) or (can_use_beans() and can_break_boulders()) end,
            ["Swamp Skulltula Monument Room On Monument"] = function () return true end,
            ["Swamp Skulltula Monument Room Crate 1"] = function () return true end,
            ["Swamp Skulltula Monument Room Crate 2"] = function () return true end,
            ["Swamp Skulltula Monument Room Torch"] = function () return true end,
            ["Swamp Skulltula Gold Room Hive"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Pot Room Hive 1"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Pot Room Hive 2"] = function () return has_weapon_range() end,
            ["Swamp Skulltula Pot Room Behind Vines"] = function () return has_weapon() end,
            ["Swamp Skulltula Pot Room Pot 1"] = function () return true end,
            ["Swamp Skulltula Pot Room Pot 2"] = function () return true end,
            ["Swamp Skulltula Pot Room Jar"] = function () return true end,
            ["Swamp Skulltula Pot Room Wall"] = function () return true end,
        },
    },
    ["Woodfall Temple"] = {
        ["exits"] = {
            ["Woodfall Front of Temple"] = function () return true end,
            ["Woodfall Temple Entrance"] = function () return event(TIME_TRAVEL) end,
        },
    },
    ["Woodfall Temple Entrance"] = {
        ["exits"] = {
            ["Woodfall Temple"] = function () return true end,
            ["Woodfall Temple Main"] = function () return has(MASK_DEKU) or can_hookshot_short() end,
        },
        ["locations"] = {
            ["Woodfall Temple Entrance Chest"] = function () return has(MASK_DEKU) or can_hookshot_short() end,
            ["Woodfall Temple SF Entrance"] = function () return true end,
        },
    },
    ["Woodfall Temple Main"] = {
        ["events"] = {
            ["WOODFALL_TEMPLE_MAIN_FLOWER"] = function () return can_use_fire_arrows() end,
        },
        ["exits"] = {
            ["Woodfall Temple"] = function () return true end,
            ["Woodfall Temple Water Room"] = function () return true end,
            ["Woodfall Temple Maze"] = function () return has(SMALL_KEY_WF, 1) end,
            ["Woodfall Temple Main Ledge"] = function () return event(WOODFALL_TEMPLE_MAIN_FLOWER) or event(WOODFALL_TEMPLE_MAIN_LADDER) or can_hookshot_short() end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Main Pot"] = function () return true end,
            ["Woodfall Temple SF Main Deku Baba"] = function () return true end,
        },
    },
    ["Woodfall Temple Water Room"] = {
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Map Room"] = function () return has(MASK_DEKU) or can_hookshot_short() or can_use_ice_arrows() or event(WOODFALL_TEMPLE_MAIN_FLOWER) end,
            ["Woodfall Temple Water Room Upper"] = function () return has(BOW) and has(MASK_DEKU) end,
        },
        ["locations"] = {
            ["Woodfall Temple Water Chest"] = function () return has(MASK_DEKU) or can_hookshot() or (can_hookshot_short() and event(WOODFALL_TEMPLE_MAIN_FLOWER)) or can_use_ice_arrows() end,
            ["Woodfall Temple SF Water Room Beehive"] = function () return has(BOW) or can_use_deku_bubble() or (has(MASK_GREAT_FAIRY) and (has(BOMB_BAG) or has(MASK_ZORA) or can_hookshot())) end,
        },
    },
    ["Woodfall Temple Map Room"] = {
        ["exits"] = {
            ["Woodfall Temple Water Room"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Map"] = function () return has(MASK_DEKU) or has_explosives() or has(MASK_GORON) end,
        },
    },
    ["Woodfall Temple Maze"] = {
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Compass Room"] = function () return true end,
            ["Woodfall Temple Dark Room"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Maze Skulltula"] = function () return can_fight() or has(BOW) or can_use_deku_bubble() or has_explosives() end,
            ["Woodfall Temple SF Maze Beehive"] = function () return has_weapon_range() end,
            ["Woodfall Temple SF Maze Bubble"] = function () return has(MASK_GREAT_FAIRY) and (has(BOW) or can_hookshot_short()) or event(WOODFALL_TEMPLE_MAIN_FLOWER) end,
        },
    },
    ["Woodfall Temple Compass Room"] = {
        ["exits"] = {
            ["Woodfall Temple Maze"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Compass"] = function () return true end,
        },
    },
    ["Woodfall Temple Dark Room"] = {
        ["exits"] = {
            ["Woodfall Temple Maze"] = function () return true end,
            ["Woodfall Temple Pits Room"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Dark Chest"] = function () return true end,
        },
    },
    ["Woodfall Temple Pits Room"] = {
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Dark Room"] = function () return true end,
            ["Woodfall Temple Main Ledge"] = function () return has(MASK_DEKU) end,
        },
    },
    ["Woodfall Temple Main Ledge"] = {
        ["events"] = {
            ["WOODFALL_TEMPLE_MAIN_FLOWER"] = function () return has(BOW) end,
            ["WOODFALL_TEMPLE_MAIN_LADDER"] = function () return true end,
        },
        ["exits"] = {
            ["Woodfall Temple Main"] = function () return true end,
            ["Woodfall Temple Pits Room"] = function () return true end,
            ["Woodfall Temple Pre-Boss"] = function () return has(BOW) end,
        },
        ["locations"] = {
            ["Woodfall Temple Center Chest"] = function () return has(MASK_DEKU) end,
            ["Woodfall Temple SF Main Bubble"] = function () return true end,
        },
    },
    ["Woodfall Temple Water Room Upper"] = {
        ["exits"] = {
            ["Woodfall Temple Main Ledge"] = function () return true end,
            ["Woodfall Temple Water Room"] = function () return true end,
            ["Woodfall Temple Bow Room"] = function () return true end,
            ["Woodfall Temple Boss Key Room"] = function () return has(BOW) and has(MASK_DEKU) end,
        },
    },
    ["Woodfall Temple Bow Room"] = {
        ["exits"] = {
            ["Woodfall Temple Water Room Upper"] = function () return can_fight() or has(BOW) end,
        },
        ["locations"] = {
            ["Woodfall Temple Bow"] = function () return can_fight() or has(BOW) end,
        },
    },
    ["Woodfall Temple Boss Key Room"] = {
        ["events"] = {
            ["FROG_2"] = function () return has(MASK_DON_GERO) end,
        },
        ["exits"] = {
            ["Woodfall Temple Water Room Upper"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple Boss Key Chest"] = function () return true end,
        },
    },
    ["Woodfall Temple Pre-Boss"] = {
        ["exits"] = {
            ["Woodfall Temple Boss"] = function () return has(BOSS_KEY_WF) and (can_hookshot() or has(MASK_DEKU)) end,
            ["Woodfall Temple Main Ledge"] = function () return true end,
        },
        ["locations"] = {
            ["Woodfall Temple SF Pre-Boss Bottom Right"] = function () return true end,
            ["Woodfall Temple SF Pre-Boss Left"] = function () return has(MASK_DEKU) or has(MASK_GREAT_FAIRY) end,
            ["Woodfall Temple SF Pre-Boss Top Right"] = function () return true end,
            ["Woodfall Temple SF Pre-Boss Pillar"] = function () return has(MASK_DEKU) or has(MASK_GREAT_FAIRY) end,
        },
    },
    ["Woodfall Temple Princess Jail"] = {
        ["events"] = {
            ["DEKU_PRINCESS"] = function () return has_bottle() and has_weapon() end,
        },
        ["exits"] = {
            ["Woodfall"] = function () return true end,
        },
    },
    ["Woodfall Temple Boss"] = {
        ["exits"] = {
            ["Woodfall Temple After Boss"] = function () return has(MASK_FIERCE_DEITY) or (has(BOW) and has_weapon()) end,
        },
    },
    ["Woodfall Temple After Boss"] = {
        ["events"] = {
            ["CLEAN_SWAMP"] = function () return true end,
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
