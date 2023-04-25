-- NOTE: This file is auto-generated. Any changes will be overwritten.

-- This is for namespacing only, because EmoTracker doesn't seem to properly support require()
function _oot_logic()
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
    }

    -- This is used for all items, events, settings, etc., but probably shouldn't be...
    setmetatable(M, {
        __index = function(table, key)
            if string.match(key, "^[A-Z0-9_]+$") and OOTMM_CORE_ITEMS[key] then
                -- FIXME: This will break for items that are not in the list yet. Those exist.
                --        We might just have to generate that list from python, too.
                return tostring(key)
            else
                if OOTMM_DEBUG then
                    print("Unknown attribute accessed: " .. key)
                end
                return tostring(key)
            end

            return nil
        end
    })

    local _ENV = M

    OOTMM_DEBUG = false

    OOTMM_RUNTIME_ALL_TRICKS_ENABLED = false
    OOTMM_RUNTIME_ACCESSIBILITY = {}
    OOTMM_RUNTIME_ACTIVE_EVENTS = {}
    OOTMM_RUNTIME_CACHE = {}

    OOTMM_ITEM_PREFIX = "OOT"
    OOTMM_TRICK_PREFIX = "TRICK"

    -- Inject things into the module's namespace
    -- FIXME: Does this work for functions in functions? EmoTracker's Lua includes are weird, and/or my Lua knowledge is sorely lacking...
    function inject(trackerfuncs)
        for k, v in pairs(trackerfuncs) do
            M[k] = v
        end
    end

    OOTMM_HAS_EXCEPTIONS = {
        ["HOOKSHOT:2"] = "LONGSHOT",
        ["SCALE:2"] = "GOLDSCALE",
        ["STRENGTH:2"] = "STRENGTH2",
        ["STRENGTH:3"] = "STRENGTH3",
        ["WALLET:1"] = "WALLET1",
        ["WALLET:2"] = "WALLET2",
        ["WALLET:3"] = "WALLET3",
    }
    if EMO then
        function _has(item, amount)
            if OOTMM_DEBUG then
                print("EMO has:", item, amount)
            end

            if amount and OOTMM_HAS_EXCEPTIONS[item .. ":" .. amount] then
                item = OOTMM_HAS_EXCEPTIONS[item .. ":" .. amount]
            end

            local count = Tracker:ProviderCountForCode(OOTMM_ITEM_PREFIX .. "_" .. item)
            amount = tonumber(amount)

            if not amount then
                return count > 0
            else
                return count >= amount
            end
        end
    else
        function _has(item, count)
            if OOTMM_DEBUG then
                print("Debug has:", item, count)
            end
            if count == nil then
                count = 1
            end

            if items[item] == nil then
                return false
            end

            return items[item] >= count
        end
    end
    function has(item, count)
        return _has(item, count)
    end

    -- FIXME: This works, but is untested; reactivate it for a huge speedup in EmoTracker.
    --        Tracker:ProviderCountForCode() seems to be excruciatingly slow, this caches the results.
    -- function has(item, count)
    --     if count == nil then
    --         if OOTMM_RUNTIME_CACHE[item] == nil then
    --             OOTMM_RUNTIME_CACHE[item] = _has(item, count)
    --         end
    --         return OOTMM_RUNTIME_CACHE[item]
    --     else
    --         if OOTMM_RUNTIME_CACHE[item .. ":" .. count] == nil then
    --             OOTMM_RUNTIME_CACHE[item .. ":" .. count] = _has(item, count)
    --         end
    --         return OOTMM_RUNTIME_CACHE[item .. ":" .. count]
    --     end
    -- end

    child = true
    adult = not child

    function age(x)
        -- FIXME
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
        -- FIXME: This is curretly unused; might be useful in find_available_locations()

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

    function trick(x)
        return has(OOTMM_TRICK_PREFIX .. "_" .. x) or OOTMM_RUNTIME_ALL_TRICKS_ENABLED
    end

    function event(x)
        -- FIXME
        if OOTMM_RUNTIME_ACTIVE_EVENTS[x] then
            return true
        end
        if x == "TIME_TRAVEL" then
            return true
        end
        return false
    end

    function cond(x, y, z)
        -- print("cond:", x, y, z)
        if x then
            return y
        else
            return z
        end
    end

    OOTMM_SETTING_EXCEPTIONS = {
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
        -- setting(crossWarpMm, full) -> check if has(crossWarpMm_full)
        local item_name = name
        if state then
            item_name = name .. "_" .. state
        end

        if OOTMM_DEBUG then
            print("Checking for setting:", item_name)
        end

        if OOTMM_SETTING_EXCEPTIONS[item_name] ~= nil then
            return OOTMM_SETTING_EXCEPTIONS[item_name]
        end

        return has(item_name)
    end

    function oot_time(x)
        -- FIXME
        return true
    end

    -- Starting at the spawn location, check all places for available locations
    function find_available_locations(logic)
        -- Measure time taken in this function:
        -- local start_time = os.clock()

        -- FIXME: "logic" should be available without passing it from the outside,
        --        but it doesn't work; investigate!
        --        Once this is fixed, re-add the "local" keyword to it in main.py
        OOTMM_RUNTIME_ACTIVE_EVENTS = {}
        local places_to_check = { "SPAWN" }
        local places_available = { "SPAWN" } -- FIXME: Remove this, for debugging only
        local places_checked = {}
        local locations_available = {}
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
            -- table.insert(places_checked, place = true)
            places_checked[place] = true

            if OOTMM_DEBUG then
                print("checking place:", place)
            end

            if logic[place] then
                if logic[place].locations then
                    for k, v in pairs(logic[place].locations) do
                        if v() then
                            -- table.insert(locations_available, k)
                            -- This will need to be mapped to accessibility levels later
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
                            places_to_check = { "SPAWN" }
                            places_available = { "SPAWN" } -- FIXME: Remove this, for debugging only
                            places_checked = {}
                            locations_available = {}

                            goto continue
                        end
                    end
                end
            end
            ::continue::
        end

        -- print("Time taken in oot_logic:find_available_locations():", os.clock() - start_time, "seconds")

        return locations_available
    end

    	function is_child()
		return age(child)
	end

	function is_adult()
		return age(adult)
	end

	function can_play(x)
		return has(OCARINA) and has(x)
	end

	function has_explosives()
		return has(BOMB_BAG)
	end

	function has_bombflowers()
		return has_explosives() or has(STRENGTH)
	end

	function can_use_slingshot()
		return is_child() and has(SLINGSHOT)
	end

	function can_use_bow()
		return is_adult() and has(BOW)
	end

	function can_hit_triggers_distance()
		return can_use_slingshot() or can_use_bow()
	end

	function has_bottle()
		return has(BOTTLE_EMPTY) or has(BOTTLE_MILK) or event(KING_ZORA_LETTER)
	end

	function has_spiritual_stones()
		return has(STONE_EMERALD) and has(STONE_RUBY) and has(STONE_SAPPHIRE)
	end

	function can_hookshot()
		return is_adult() and has(HOOKSHOT)
	end

	function can_longshot()
		return is_adult() and has(HOOKSHOT, 2)
	end

	function can_hammer()
		return is_adult() and has(HAMMER)
	end

	function has_explosives_or_hammer()
		return has_explosives() or can_hammer()
	end

	function scarecrow_hookshot()
		return can_hookshot() and event(SCARECROW)
	end

	function scarecrow_longshot()
		return can_longshot() and event(SCARECROW)
	end

	function has_fire()
		return has_fire_arrows() or can_use_din()
	end

	function has_fire_or_sticks()
		return can_use_sticks() or has_fire()
	end

	function has_fire_spirit()
		return has(MAGIC_UPGRADE) and (has(BOW) and has(ARROW_FIRE) and has_sticks() or has(SPELL_FIRE)) and (has_explosives() or has(SMALL_KEY_SPIRIT, 2))
	end

	function has_lens()
		return has_lens_strict() or trick(OOT_LENS)
	end

	function has_lens_strict()
		return has(MAGIC_UPGRADE) and has(LENS)
	end

	function has_bombchu()
		return has(BOMBCHU_10) or has(BOMBCHU_20) or has(BOMBCHU_5)
	end

	function can_use_din()
		return has(MAGIC_UPGRADE) and has(SPELL_FIRE)
	end

	function can_boomerang()
		return is_child() and has(BOOMERANG)
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

	function has_ranged_weapon_both()
		return has_explosives() or ((has(SLINGSHOT) or has(BOOMERANG)) and (has(HOOKSHOT) or has(BOW)))
	end

	function has_mirror_shield()
		return is_adult() and cond(setting(progressiveShieldsOot, progressive), has(SHIELD, 3), has(SHIELD_MIRROR))
	end

	function has_light_arrows()
		return can_use_bow() and has(ARROW_LIGHT) and has(MAGIC_UPGRADE)
	end

	function has_fire_arrows()
		return can_use_bow() and has(ARROW_FIRE) and has(MAGIC_UPGRADE)
	end

	function can_use_beans()
		return is_child() and has(MAGIC_BEAN)
	end

	function stone_of_agony()
		return has(STONE_OF_AGONY) or trick(OOT_HIDDEN_GROTTOS)
	end

	function hidden_grotto_bomb()
		return stone_of_agony() and has_explosives_or_hammer()
	end

	function hidden_grotto_storms()
		return stone_of_agony() and can_play(SONG_STORMS)
	end

	function can_collect_distance()
		return can_hookshot() or can_boomerang()
	end

	function can_collect_ageless()
		return has(HOOKSHOT) and has(BOOMERANG)
	end

	function gs_night()
		return trick(OOT_NIGHT_GS) or can_play(SONG_SUN)
	end

	function gs_soil()
		return is_child() and has_bottle()
	end

	function has_sword_kokiri()
		return cond(setting(progressiveSwordsOot, progressive), has(SWORD), has(SWORD_KOKIRI))
	end

	function has_sword_master()
		return cond(setting(progressiveSwordsOot, progressive), has(SWORD, 2), has(SWORD_MASTER))
	end

	function has_weapon()
		return is_child() and has_sword_kokiri() or is_adult()
	end

	function has_tunic_goron()
		return is_adult() and has(TUNIC_GORON) or trick(OOT_TUNICS)
	end

	function has_tunic_goron_strict()
		return is_adult() and has(TUNIC_GORON)
	end

	function has_tunic_zora()
		return is_adult() and (has(TUNIC_ZORA) or trick(OOT_TUNICS))
	end

	function has_tunic_zora_strict()
		return is_adult() and has(TUNIC_ZORA)
	end

	function has_iron_boots()
		return is_adult() and has(BOOTS_IRON)
	end

	function has_hover_boots()
		return is_adult() and has(BOOTS_HOVER)
	end

	function can_dive_small()
		return has(SCALE) or has_iron_boots()
	end

	function can_dive_big()
		return has(SCALE, 2) or has_iron_boots()
	end

	function has_shield_for_scrubs()
		return cond(is_adult(), has(SHIELD_HYLIAN), has(SHIELD_DEKU))
	end

	function has_shield()
		return has(SHIELD_HYLIAN) or has_mirror_shield() or (is_child() and has(SHIELD_DEKU))
	end

	function can_lift_silver()
		return is_adult() and has(STRENGTH, 2)
	end

	function can_lift_gold()
		return is_adult() and has(STRENGTH, 3)
	end

	function can_ride_bean(x)
		return is_adult() and event(x)
	end

	function adult_trade(x)
		return is_adult() and has(x)
	end

	function has_small_keys_fire(x)
		return cond(setting(smallKeyShuffle, anywhere), has(SMALL_KEY_FIRE, x + 1), has(SMALL_KEY_FIRE, x))
	end

	function trick_mido()
		return trick(OOT_MIDO_SKIP) and (has(BOW) or has(HOOKSHOT) or has(ARROW_FIRE) or has(ARROW_LIGHT))
	end

	function has_sticks()
		return event(STICKS) or has(STICK) or has(STICKS_5) or has(STICKS_10)
	end

	function has_nuts()
		return event(NUTS) or has(NUT) or has(NUTS_5) or has(NUTS_10)
	end

	function can_use_sticks()
		return is_child() and has_sticks()
	end

	function has_blue_fire()
		return has_bottle() and (event(BLUE_FIRE) or has(BLUE_FIRE))
	end

	function can_kill_baba_sticks()
		return can_boomerang() or (has_weapon() and (is_child() or has_nuts() or can_hookshot() or can_hammer()))
	end

	function can_kill_baba_nuts()
		return has_weapon() or has_explosives() or can_use_slingshot()
	end

	function can_damage()
		return has_weapon() or can_use_sticks() or has_explosives() or can_use_slingshot() or can_use_din()
	end

	function can_damage_skull()
		return can_damage() or can_collect_distance()
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
            ["Dodongo Cavern Boss Container"] = function () return can_use_sticks() or has_weapon() end,
            ["Dodongo Cavern Boss"] = function () return can_use_sticks() or has_weapon() end,
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
            ["Bottom of the Well East Cage"] = function () return has(SMALL_KEY_BOTW, 3) and has_lens() end,
            ["Bottom of the Well Blood Chest"] = function () return has_lens() end,
            ["Bottom of the Well Underwater 2"] = function () return can_play(SONG_ZELDA) end,
            ["Bottom of the Well Map"] = function () return has_explosives() or (has_bombflowers() and (has(SMALL_KEY_BOTW, 3) or can_use_din())) end,
            ["Bottom of the Well Coffin"] = function () return true end,
            ["Bottom of the Well Pits"] = function () return has_lens() and has(SMALL_KEY_BOTW, 3) end,
            ["Bottom of the Well Lens"] = function () return can_play(SONG_ZELDA) and has_weapon() end,
            ["Bottom of the Well Lens Side Chest"] = function () return can_play(SONG_ZELDA) and has_lens() end,
            ["Bottom of the Well GS East Cage"] = function () return has(SMALL_KEY_BOTW, 3) and has_lens() and can_boomerang() end,
            ["Bottom of the Well GS Inner West"] = function () return has(SMALL_KEY_BOTW, 3) and has_lens() and can_boomerang() end,
            ["Bottom of the Well GS Inner East"] = function () return has(SMALL_KEY_BOTW, 3) and has_lens() and can_boomerang() end,
        },
    },
    ["Deku Tree"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
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
            ["Deku Tree Basement Ledge"] = function () return trick(OOT_DEKU_SKIP) or is_adult() end,
        },
        ["locations"] = {
            ["Deku Tree Basement Chest"] = function () return true end,
            ["Deku Tree GS Basement Gate"] = function () return can_damage_skull() end,
            ["Deku Tree GS Basement Vines"] = function () return has_ranged_weapon() or can_use_din() or has(BOMB_BAG) end,
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
            ["Dodongo Cavern Stairs"] = function () return event(DC_MAIN_SWITCH) end,
            ["Dodongo Cavern Skull"] = function () return event(DC_BOMB_EYES) end,
        },
        ["locations"] = {
            ["Dodongo Cavern Map Chest"] = function () return has_bombflowers() or can_hammer() end,
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
            ["Dodongo Cavern Right Corridor"] = function () return true end,
            ["Dodongo Cavern Green Room"] = function () return true end,
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
            ["Dodongo Cavern GS Stairs Top"] = function () return (can_hookshot() or can_boomerang()) and event(DC_SHORTCUT) end,
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
            ["Dodongo Cavern Bomb Bag Room 2"] = function () return can_longshot() or has_hover_boots() or (is_adult() and trick(OOT_DC_JUMP)) end,
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
    },
    ["Dodongo Cavern Miniboss 2"] = {
        ["exits"] = {
            ["Dodongo Cavern Bomb Bag Room 1"] = function () return true end,
            ["Dodongo Cavern Bomb Bag Room 2"] = function () return true end,
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
            ["Fire Temple Boss Key Loop"] = function () return cond(setting(smallKeyShuffle, anywhere), has(SMALL_KEY_FIRE, 8), true) and can_hammer() end,
            ["Fire Temple Pre-Boss"] = function () return true end,
        },
    },
    ["Fire Temple Pre-Boss"] = {
        ["exits"] = {
            ["Fire Temple"] = function () return true end,
            ["Fire Temple Boss"] = function () return has(BOSS_KEY_FIRE) and (event(FIRE_TEMPLE_PILLAR_HAMMER) or has_hover_boots()) and has_tunic_goron() end,
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
            ["Fire Temple Maze"] = function () return has_small_keys_fire(3) and has_tunic_goron_strict() and has(STRENGTH) and (has_ranged_weapon_adult() or has_explosives()) end,
        },
        ["locations"] = {
            ["Fire Temple Jail 2 Chest"] = function () return is_adult() and has_tunic_goron() or (is_child() and trick(OOT_TUNICS) and can_play(SONG_TIME)) end,
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
            ["Fire Temple After Miniboss"] = function () return has_explosives_or_hammer() end,
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
            ["Fire Temple Ring Jail"] = function () return can_hammer() and trick(OOT_HAMMER_WALLS) end,
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
            ["FOREST_POE_4"] = function () return event(FOREST_POE_1) and event(FOREST_POE_2) and event(FOREST_POE_3) and can_use_bow() end,
        },
        ["exits"] = {
            ["Forest Temple"] = function () return true end,
            ["Forest Temple Mini-Boss"] = function () return true end,
            ["Forest Temple Garden West"] = function () return can_play(SONG_TIME) end,
            ["Forest Temple Garden East"] = function () return can_hit_triggers_distance() end,
            ["Forest Temple Maze"] = function () return has(SMALL_KEY_FOREST, 1) end,
            ["Forest Temple Antichamber"] = function () return event(FOREST_POE_4) end,
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
            ["Forest Temple Well"] = function () return event(FOREST_WELL) or can_dive_big() end,
        },
        ["locations"] = {
            ["Forest Temple GS Garden West"] = function () return can_longshot() or (event(FOREST_LEDGE_REACHED) and can_collect_distance()) end,
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
            ["Forest Temple Well"] = function () return event(FOREST_WELL) or can_dive_big() end,
            ["Forest Temple Garden East Ledge"] = function () return can_longshot() or (can_hookshot() and trick(OOT_FOREST_HOOK)) end,
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
            ["Forest Temple Well"] = function () return event(FOREST_WELL) end,
        },
    },
    ["Forest Temple Maze"] = {
        ["exits"] = {
            ["Forest Temple Main"] = function () return true end,
            ["Forest Temple Garden West Ledge"] = function () return has_hover_boots() end,
            ["Forest Temple Twisted 1 Normal"] = function () return is_adult() and has(SMALL_KEY_FOREST, 2) and has(STRENGTH) end,
            ["Forest Temple Twisted 1 Alt"] = function () return is_adult() and has(SMALL_KEY_FOREST, 2) and has(STRENGTH) and can_hit_triggers_distance() end,
        },
        ["locations"] = {
            ["Forest Temple Maze"] = function () return has(STRENGTH) and can_hit_triggers_distance() end,
        },
    },
    ["Forest Temple Twisted 1 Normal"] = {
        ["exits"] = {
            ["Forest Temple Poe 1"] = function () return has(SMALL_KEY_FOREST, 3) end,
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
            ["Forest Temple Twisted 2 Normal"] = function () return has(SMALL_KEY_FOREST, 4) end,
        },
        ["locations"] = {
            ["Forest Temple Compass"] = function () return can_use_bow() end,
        },
    },
    ["Forest Temple Twisted 2 Normal"] = {
        ["exits"] = {
            ["Forest Temple Rotating Room"] = function () return has(SMALL_KEY_FOREST, 5) end,
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
            ["Forest Temple Boss"] = function () return has(BOSS_KEY_FOREST) end,
        },
        ["locations"] = {
            ["Forest Temple Antichamber"] = function () return true end,
            ["Forest Temple GS Antichamber"] = function () return can_collect_distance() end,
        },
    },
    ["Ganon Castle Main"] = {
        ["exits"] = {
            ["Ganon Castle Light"] = function () return has(STRENGTH, 3) end,
            ["Ganon Castle Forest"] = function () return true end,
            ["Ganon Castle Fire"] = function () return true end,
            ["Ganon Castle Water"] = function () return true end,
            ["Ganon Castle Spirit"] = function () return true end,
            ["Ganon Castle Shadow"] = function () return true end,
            ["Ganon Castle Tower"] = function () return true end,
        },
    },
    ["Ganon Castle Light"] = {
        ["events"] = {
            ["GANON_TRIAL_LIGHT"] = function () return has(SMALL_KEY_GANON, 2) and can_hookshot() and has_lens() and has_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Light Chest Around 1"] = function () return true end,
            ["Ganon Castle Light Chest Around 2"] = function () return true end,
            ["Ganon Castle Light Chest Around 3"] = function () return true end,
            ["Ganon Castle Light Chest Around 4"] = function () return true end,
            ["Ganon Castle Light Chest Around 5"] = function () return true end,
            ["Ganon Castle Light Chest Around 6"] = function () return true end,
            ["Ganon Castle Light Chest Center"] = function () return has_lens() end,
            ["Ganon Castle Light Chest Lullaby"] = function () return has(SMALL_KEY_GANON, 1) and can_play(SONG_ZELDA) end,
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
            ["GANON_TRIAL_FIRE"] = function () return has_tunic_goron_strict() and can_longshot() and has(STRENGTH, 3) and has_light_arrows() end,
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
            ["GANON_TRIAL_SPIRIT"] = function () return can_hookshot() and has_explosives() and has_light_arrows() end,
        },
        ["locations"] = {
            ["Ganon Castle Spirit Chest 1"] = function () return can_hookshot() end,
            ["Ganon Castle Spirit Chest 2"] = function () return can_hookshot() and has_explosives() and has_lens() end,
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
    ["Ganon Castle Tower"] = {
        ["exits"] = {
            ["Ganon Castle Tower Boss"] = function () return setting(ganonBossKey, removed) or has(BOSS_KEY_GANON) end,
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
    ["Gerudo Fortress"] = {
        ["events"] = {
            ["CARPENTERS_RESCUE"] = function () return has_weapon() and has(SMALL_KEY_GF, 4) and (can_hookshot() or can_use_bow() or has_hover_boots() or has(GERUDO_CARD)) end,
        },
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return true end,
        },
        ["locations"] = {
            ["Gerudo Fortress Jail 1"] = function () return has_weapon() end,
            ["Gerudo Fortress Jail 2"] = function () return has_weapon() end,
            ["Gerudo Fortress Jail 3"] = function () return has_weapon() end,
            ["Gerudo Fortress Jail 4"] = function () return has_weapon() and (can_hookshot() or can_use_bow() or has_hover_boots() or has(GERUDO_CARD)) end,
            ["Gerudo Member Card"] = function () return event(CARPENTERS_RESCUE) end,
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
            ["Gerudo Training Grounds Maze Side"] = function () return has(SMALL_KEY_GTG, 9) end,
        },
        ["locations"] = {
            ["Gerudo Training Maze Upper Fake Ceiling"] = function () return has(SMALL_KEY_GTG, 3) and has_lens() end,
            ["Gerudo Training Maze Chest 1"] = function () return has(SMALL_KEY_GTG, 4) end,
            ["Gerudo Training Maze Chest 2"] = function () return has(SMALL_KEY_GTG, 6) end,
            ["Gerudo Training Maze Chest 3"] = function () return has(SMALL_KEY_GTG, 7) end,
            ["Gerudo Training Maze Chest 4"] = function () return has(SMALL_KEY_GTG, 9) end,
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
            ["Jabu-Jabu Pre-Boss"] = function () return can_boomerang() end,
        },
        ["locations"] = {
            ["Jabu-Jabu Map Chest"] = function () return can_boomerang() end,
            ["Jabu-Jabu Compass Chest"] = function () return can_boomerang() end,
            ["Jabu-Jabu Boomerang Chest"] = function () return true end,
            ["Jabu-Jabu GS Bottom Lower"] = function () return can_collect_distance() end,
            ["Jabu-Jabu GS Bottom Upper"] = function () return can_collect_distance() end,
            ["Jabu-Jabu GS Water Switch"] = function () return true end,
            ["Jabu-Jabu GS Near Boss"] = function () return can_boomerang() end,
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
            ["SPAWN ADULT"] = function () return is_adult() and event(TIME_TRAVEL) end,
        },
    },
    ["SPAWN CHILD"] = {
        ["exits"] = {
            ["SPAWN COMMON"] = function () return true end,
            ["Link's House"] = function () return true end,
        },
    },
    ["SPAWN ADULT"] = {
        ["exits"] = {
            ["SPAWN COMMON"] = function () return true end,
            ["Temple of Time"] = function () return true end,
        },
    },
    ["SPAWN COMMON"] = {
        ["exits"] = {
            ["SONGS"] = function () return has(OCARINA) end,
            ["EGGS"] = function () return true end,
        },
    },
    ["SONGS"] = {
        ["exits"] = {
            ["Temple of Time"] = function () return has(SONG_TP_LIGHT) end,
            ["Sacred Meadow"] = function () return has(SONG_TP_FOREST) end,
            ["Death Mountain Crater Warp"] = function () return has(SONG_TP_FIRE) end,
            ["Lake Hylia"] = function () return has(SONG_TP_WATER) end,
            ["Graveyard Upper"] = function () return has(SONG_TP_SHADOW) end,
            ["Desert Colossus"] = function () return has(SONG_TP_SPIRIT) end,
            ["MM SOARING"] = function () return setting(crossWarpMm, full) or (setting(crossWarpMm, childOnly) and is_child()) end,
        },
    },
    ["EGGS"] = {
        ["locations"] = {
            ["Hatch Chicken"] = function () return is_child() and has(WEIRD_EGG) end,
            ["Hatch Pocket Cucco"] = function () return is_adult() and has(POCKET_EGG) end,
        },
    },
    ["Link's House"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Kokiri Forest Cow"] = function () return is_adult() and event(MALON_COW) and can_play(SONG_EPONA) end,
        },
    },
    ["Kokiri Forest"] = {
        ["events"] = {
            ["STICKS"] = function () return can_boomerang() or (is_child() and has_weapon()) end,
        },
        ["exits"] = {
            ["Link's House"] = function () return true end,
            ["Mido's House"] = function () return true end,
            ["Lost Woods"] = function () return true end,
            ["Lost Woods Bridge"] = function () return true end,
            ["Kokiri Shop"] = function () return true end,
            ["Deku Tree"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Kokiri Forest Kokiri Sword Chest"] = function () return is_child() end,
            ["Kokiri Forest Storms Grotto"] = function () return hidden_grotto_storms() end,
            ["Kokiri Forest GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Kokiri Forest GS Night Child"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Kokiri Forest GS Night Adult"] = function () return can_hookshot() and gs_night() end,
        },
    },
    ["Kokiri Shop"] = {
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Kokiri Shop Item 1"] = function () return true end,
            ["Kokiri Shop Item 2"] = function () return true end,
            ["Kokiri Shop Item 3"] = function () return true end,
            ["Kokiri Shop Item 4"] = function () return true end,
            ["Kokiri Shop Item 5"] = function () return true end,
            ["Kokiri Shop Item 6"] = function () return true end,
            ["Kokiri Shop Item 7"] = function () return true end,
            ["Kokiri Shop Item 8"] = function () return true end,
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
    ["Hyrule Field"] = {
        ["events"] = {
            ["BIG_POE"] = function () return event(EPONA) and can_use_bow() and has_bottle() end,
        },
        ["exits"] = {
            ["Lost Woods Bridge"] = function () return true end,
            ["Market"] = function () return is_child() end,
            ["Market Destroyed"] = function () return is_adult() end,
            ["Kakariko"] = function () return true end,
            ["Zora River Front"] = function () return true end,
            ["Lake Hylia"] = function () return true end,
            ["Gerudo Valley"] = function () return true end,
            ["Lon Lon Ranch"] = function () return true end,
        },
        ["locations"] = {
            ["Hyrule Field Grotto Scrub HP"] = function () return hidden_grotto_bomb() and (has_nuts() or has_shield_for_scrubs() or can_hammer()) end,
            ["Hyrule Field Ocarina of Time"] = function () return has_spiritual_stones() end,
            ["Hyrule Field Song of Time"] = function () return has_spiritual_stones() end,
            ["Hyrule Field Grotto Southeast"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Field Grotto Open"] = function () return true end,
            ["Hyrule Field Grotto Market"] = function () return has_explosives_or_hammer() end,
            ["Hyrule Field Grotto Tektite HP"] = function () return hidden_grotto_bomb() and can_dive_big() end,
            ["Hyrule Field Grotto Near Kakariko GS"] = function () return hidden_grotto_bomb() and can_collect_distance() end,
            ["Hyrule Field Grotto Near Gerudo GS"] = function () return (is_child() and hidden_grotto_bomb() or can_hammer()) and can_collect_distance() and has_fire() end,
            ["Hyrule Field Cow"] = function () return (is_child() and hidden_grotto_bomb() or can_hammer()) and has_fire() and can_play(SONG_EPONA) end,
        },
    },
    ["Market"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Market Pot House"] = function () return true end,
            ["Back Alley"] = function () return true end,
            ["Hyrule Castle"] = function () return true end,
            ["Temple of Time"] = function () return true end,
            ["Bombchu Bowling"] = function () return true end,
            ["Treasure Game"] = function () return true end,
            ["Shooting Gallery Child"] = function () return true end,
            ["Market Bazaar"] = function () return true end,
            ["Market Potion Shop"] = function () return true end,
            ["Market Bombchu Shop"] = function () return true end,
            ["MM SPAWN"] = function () return is_child() end,
        },
    },
    ["Market Bazaar"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Market Bazaar Item 1"] = function () return true end,
            ["Market Bazaar Item 2"] = function () return true end,
            ["Market Bazaar Item 3"] = function () return true end,
            ["Market Bazaar Item 4"] = function () return true end,
            ["Market Bazaar Item 5"] = function () return true end,
            ["Market Bazaar Item 6"] = function () return true end,
            ["Market Bazaar Item 7"] = function () return true end,
            ["Market Bazaar Item 8"] = function () return true end,
        },
    },
    ["Market Potion Shop"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Market Potion Shop Item 1"] = function () return has(WALLET, 1) end,
            ["Market Potion Shop Item 2"] = function () return true end,
            ["Market Potion Shop Item 3"] = function () return true end,
            ["Market Potion Shop Item 4"] = function () return true end,
            ["Market Potion Shop Item 5"] = function () return has(WALLET, 2) end,
            ["Market Potion Shop Item 6"] = function () return true end,
            ["Market Potion Shop Item 7"] = function () return true end,
            ["Market Potion Shop Item 8"] = function () return true end,
        },
    },
    ["Market Bombchu Shop"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Market Bombchu Shop Item 1"] = function () return has(WALLET, 1) end,
            ["Market Bombchu Shop Item 2"] = function () return has(WALLET, 1) end,
            ["Market Bombchu Shop Item 3"] = function () return has(WALLET, 1) end,
            ["Market Bombchu Shop Item 4"] = function () return has(WALLET, 1) end,
            ["Market Bombchu Shop Item 5"] = function () return has(WALLET, 1) end,
            ["Market Bombchu Shop Item 6"] = function () return has(WALLET, 1) end,
            ["Market Bombchu Shop Item 7"] = function () return has(WALLET, 1) end,
            ["Market Bombchu Shop Item 8"] = function () return has(WALLET, 1) end,
        },
    },
    ["Market Pot House"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
            ["Market Destroyed"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Market Pot House Big Poes"] = function () return is_adult() and event(BIG_POE) end,
            ["Market Pot House GS"] = function () return is_child() end,
        },
    },
    ["Back Alley"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
            ["Dog Lady House"] = function () return true end,
        },
    },
    ["Dog Lady House"] = {
        ["exits"] = {
            ["Back Alley"] = function () return true end,
        },
        ["locations"] = {
            ["Market Dog Lady HP"] = function () return true end,
        },
    },
    ["Bombchu Bowling"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
        },
        ["locations"] = {
            ["Bombchu Bowling Reward 1"] = function () return has_explosives() end,
            ["Bombchu Bowling Reward 2"] = function () return has_explosives() end,
        },
    },
    ["Shooting Gallery Child"] = {
        ["exits"] = {
            ["Market"] = function () return is_child() end,
        },
        ["locations"] = {
            ["Shooting Gallery Child"] = function () return is_child() end,
        },
    },
    ["Treasure Game"] = {
        ["exits"] = {
            ["Market"] = function () return true end,
        },
        ["locations"] = {
            ["Treasure Game HP"] = function () return has_lens_strict() end,
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
    ["Lon Lon Ranch"] = {
        ["events"] = {
            ["EPONA"] = function () return is_adult() and can_play(SONG_EPONA) end,
            ["MALON_COW"] = function () return is_adult() and event(EPONA) end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Lon Lon Ranch Silo"] = function () return true end,
            ["Lon Lon Ranch Stables"] = function () return true end,
            ["Lon Lon Ranch House"] = function () return true end,
        },
        ["locations"] = {
            ["Lon Lon Ranch Malon Song"] = function () return is_child() and has(OCARINA) and event(MALON) end,
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
            ["Lon Lon Ranch Talon Bottle"] = function () return is_child() and event(TALON_CHILD) end,
        },
    },
    ["Hyrule Castle"] = {
        ["events"] = {
            ["MALON"] = function () return true end,
            ["TALON_CHILD"] = function () return has(CHICKEN) end,
            ["MEET_ZELDA"] = function () return event(TALON_CHILD) end,
        },
        ["exits"] = {
            ["Market"] = function () return true end,
        },
        ["locations"] = {
            ["Malon Egg"] = function () return event(MALON) end,
            ["Zelda's Letter"] = function () return event(MEET_ZELDA) end,
            ["Zelda's Song"] = function () return event(MEET_ZELDA) end,
            ["Great Fairy Din's Fire"] = function () return has_explosives() and can_play(SONG_ZELDA) end,
            ["Hyrule Castle GS Tree"] = function () return can_damage_skull() end,
            ["Hyrule Castle GS Grotto"] = function () return hidden_grotto_storms() and has_explosives() and can_boomerang() end,
        },
    },
    ["Ganon Castle Exterior"] = {
        ["exits"] = {
            ["Market Destroyed"] = function () return true end,
            ["Ganon Castle Main"] = function () return special(BRIDGE) end,
        },
        ["locations"] = {
            ["Great Fairy Defense Upgrade"] = function () return can_lift_gold() and can_play(SONG_ZELDA) end,
            ["Ganon Castle Exterior GS"] = function () return true end,
        },
    },
    ["Lost Woods"] = {
        ["events"] = {
            ["BEAN_LOST_WOODS_EARLY"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Kokiri Forest"] = function () return true end,
            ["Lost Woods Bridge"] = function () return can_longshot() or has_hover_boots() or can_ride_bean(BEAN_LOST_WOODS_EARLY) end,
            ["Lost Woods Deep"] = function () return is_child() or can_play(SONG_SARIA) or trick_mido() end,
            ["Goron City Shortcut"] = function () return true end,
            ["Zora River"] = function () return can_dive_small() end,
        },
        ["locations"] = {
            ["Lost Woods Target"] = function () return can_use_slingshot() end,
            ["Lost Woods Skull Kid"] = function () return is_child() and can_play(SONG_SARIA) end,
            ["Lost Woods Memory Game"] = function () return is_child() and has(OCARINA) end,
            ["Lost Woods Scrub Sticks Upgrade"] = function () return is_child() and (has_nuts() or has_shield_for_scrubs()) end,
            ["Lost Woods Odd Mushroom"] = function () return adult_trade(COJIRO) end,
            ["Lost Woods Poacher's Saw"] = function () return adult_trade(ODD_POTION) end,
            ["Lost Woods Grotto Generic"] = function () return has_explosives_or_hammer() end,
            ["Lost Woods GS Soil Bridge"] = function () return gs_soil() and can_damage_skull() end,
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
        },
        ["exits"] = {
            ["Lost Woods"] = function () return is_child() or can_play(SONG_SARIA) end,
            ["Sacred Meadow"] = function () return true end,
            ["Deku Theater"] = function () return true end,
            ["Kokiri Forest"] = function () return true end,
        },
        ["locations"] = {
            ["Lost Woods Grotto Scrub Nuts Upgrade"] = function () return has_explosives_or_hammer() and (has_nuts() or has_shield_for_scrubs() or can_hammer()) end,
            ["Lost Woods GS Soil Theater"] = function () return gs_soil() and can_damage_skull() end,
            ["Lost Woods GS Bean Ride"] = function () return gs_night() and can_ride_bean(BEAN_LOST_WOODS_LATE) end,
        },
    },
    ["Deku Theater"] = {
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
        },
        ["locations"] = {
            ["Deku Theater Sticks Upgrade"] = function () return is_child() and has(MASK_SKULL) end,
            ["Deku Theater Nuts Upgrade"] = function () return is_child() and has(MASK_TRUTH) end,
        },
    },
    ["Sacred Meadow"] = {
        ["exits"] = {
            ["Lost Woods Deep"] = function () return true end,
            ["Forest Temple"] = function () return can_hookshot() end,
        },
        ["locations"] = {
            ["Saria's Song"] = function () return event(MEET_ZELDA) and is_child() and (can_play(SONG_TP_FOREST) or can_damage()) end,
            ["Sacred Meadow Sheik Song"] = function () return is_adult() end,
            ["Sacred Meadow Grotto"] = function () return hidden_grotto_bomb() end,
            ["Sacred Meadow GS Night Adult"] = function () return can_hookshot() and gs_night() end,
        },
    },
    ["Kakariko"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Death Mountain"] = function () return has(ZELDA_LETTER) or is_adult() end,
            ["Graveyard"] = function () return true end,
            ["Bottom of the Well"] = function () return is_child() and can_play(SONG_STORMS) end,
            ["Skulltula House"] = function () return true end,
            ["Shooting Gallery Adult"] = function () return is_adult() end,
            ["Kakariko Rooftop"] = function () return is_child() or can_hookshot() end,
            ["Kakariko Bazaar"] = function () return is_adult() end,
            ["Kakariko Potion Shop"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Kakariko Anju Bottle"] = function () return is_child() end,
            ["Kakariko Anju Egg"] = function () return is_adult() end,
            ["Kakariko Anju Cojiro"] = function () return adult_trade(POCKET_CUCCO) end,
            ["Windmill HP"] = function () return can_boomerang() or (is_adult() and can_play(SONG_TIME)) end,
            ["Windmill Song of Storms"] = function () return is_adult() and has(OCARINA) end,
            ["Kakariko Song Shadow"] = function () return is_adult() and has(MEDALLION_FOREST) and has(MEDALLION_FIRE) and has(MEDALLION_WATER) end,
            ["Kakariko Man on Roof"] = function () return can_hookshot() or trick(OOT_MAN_ON_ROOF) end,
            ["Kakariko Potion Shop Odd Potion"] = function () return adult_trade(ODD_MUSHROOM) end,
            ["Kakariko Grotto Front"] = function () return hidden_grotto_bomb() end,
            ["Kakariko Grotto Back"] = function () return true end,
            ["Kakariko GS Roof"] = function () return gs_night() and can_hookshot() end,
            ["Kakariko GS Shooting Gallery"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Tree"] = function () return gs_night() and is_child() end,
            ["Kakariko GS House of Skulltula"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Bazaar"] = function () return gs_night() and is_child() end,
            ["Kakariko GS Ladder"] = function () return gs_night() and is_child() and (can_use_slingshot() or has_explosives()) end,
            ["Kakariko Cow"] = function () return can_play(SONG_EPONA) end,
        },
    },
    ["Kakariko Rooftop"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Kakariko Impa House HP"] = function () return true end,
        },
    },
    ["Kakariko Bazaar"] = {
        ["exits"] = {
            ["Kakariko"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Kakariko Bazaar Item 1"] = function () return true end,
            ["Kakariko Bazaar Item 2"] = function () return true end,
            ["Kakariko Bazaar Item 3"] = function () return true end,
            ["Kakariko Bazaar Item 4"] = function () return true end,
            ["Kakariko Bazaar Item 5"] = function () return true end,
            ["Kakariko Bazaar Item 6"] = function () return true end,
            ["Kakariko Bazaar Item 7"] = function () return true end,
            ["Kakariko Bazaar Item 8"] = function () return true end,
        },
    },
    ["Kakariko Potion Shop"] = {
        ["exits"] = {
            ["Kakariko"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Kakariko Potion Shop Item 1"] = function () return has(WALLET, 1) end,
            ["Kakariko Potion Shop Item 2"] = function () return true end,
            ["Kakariko Potion Shop Item 3"] = function () return true end,
            ["Kakariko Potion Shop Item 4"] = function () return true end,
            ["Kakariko Potion Shop Item 5"] = function () return has(WALLET, 2) end,
            ["Kakariko Potion Shop Item 6"] = function () return true end,
            ["Kakariko Potion Shop Item 7"] = function () return true end,
            ["Kakariko Potion Shop Item 8"] = function () return true end,
        },
    },
    ["Shooting Gallery Adult"] = {
        ["exits"] = {
            ["Kakariko"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Shooting Gallery Adult"] = function () return can_use_bow() end,
        },
    },
    ["Graveyard"] = {
        ["events"] = {
            ["BEAN_GRAVEYARD"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Kakariko"] = function () return true end,
            ["Graveyard Royal Tomb"] = function () return can_play(SONG_ZELDA) end,
        },
        ["locations"] = {
            ["Graveyard Dampe Game"] = function () return is_child() end,
            ["Graveyard ReDead Tomb"] = function () return can_play(SONG_SUN) end,
            ["Graveyard Fairy Tomb"] = function () return true end,
            ["Graveyard Dampe Tomb Reward 1"] = function () return is_adult() end,
            ["Graveyard Dampe Tomb Reward 2"] = function () return is_adult() end,
            ["Graveyard Crate HP"] = function () return can_ride_bean(BEAN_GRAVEYARD) or can_longshot() end,
            ["Graveyard GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Graveyard GS Wall"] = function () return can_boomerang() and gs_night() end,
        },
    },
    ["Graveyard Upper"] = {
        ["exits"] = {
            ["Graveyard"] = function () return true end,
            ["Shadow Temple"] = function () return can_use_din() end,
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
    ["Skulltula House"] = {
        ["exits"] = {
            ["Kakariko"] = function () return true end,
        },
        ["locations"] = {
            ["Skulltula House 10 Tokens"] = function () return has(GS_TOKEN, 10) end,
            ["Skulltula House 20 Tokens"] = function () return has(GS_TOKEN, 20) end,
            ["Skulltula House 30 Tokens"] = function () return has(GS_TOKEN, 30) end,
            ["Skulltula House 40 Tokens"] = function () return has(GS_TOKEN, 40) end,
            ["Skulltula House 50 Tokens"] = function () return has(GS_TOKEN, 50) end,
        },
    },
    ["Death Mountain"] = {
        ["events"] = {
            ["BEAN_DEATH_MOUNTAIN"] = function () return can_use_beans() and has_bombflowers() end,
            ["BOULDER_DEATH_MOUNTAIN"] = function () return has_explosives_or_hammer() end,
        },
        ["exits"] = {
            ["Goron City"] = function () return true end,
            ["Dodongo Cavern"] = function () return has_bombflowers() or is_adult() end,
            ["Kakariko"] = function () return has(ZELDA_LETTER) or is_adult() end,
            ["Death Mountain Summit"] = function () return event(BOULDER_DEATH_MOUNTAIN) or can_ride_bean(BEAN_DEATH_MOUNTAIN) end,
        },
        ["locations"] = {
            ["Death Mountain Chest"] = function () return has_explosives_or_hammer() end,
            ["Death Mountain HP"] = function () return true end,
            ["Death Mountain Grotto"] = function () return hidden_grotto_storms() end,
            ["Death Mountain GS Entrance"] = function () return has_explosives_or_hammer() end,
            ["Death Mountain GS Soil"] = function () return gs_soil() and has_bombflowers() and can_damage_skull() end,
            ["Death Mountain GS Above Dodongo"] = function () return gs_night() and can_hammer() end,
            ["Death Mountain Cow"] = function () return has_explosives_or_hammer() and can_play(SONG_EPONA) end,
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
        },
        ["locations"] = {
            ["Death Mountain Prescription"] = function () return adult_trade(BROKEN_GORON_SWORD) end,
            ["Death Mountain Claim Check"] = function () return adult_trade(EYE_DROPS) end,
            ["Death Mountain Biggoron Sword"] = function () return adult_trade(CLAIM_CHECK) end,
            ["Great Fairy Magic Upgrade"] = function () return has_explosives_or_hammer() and can_play(SONG_ZELDA) end,
            ["Death Mountain GS Before Climb"] = function () return gs_night() and can_hammer() end,
        },
    },
    ["Goron City Shortcut"] = {
        ["events"] = {
            ["GORON_CITY_SHORTCUT"] = function () return has_explosives() or can_hammer() or can_use_din() end,
        },
        ["exits"] = {
            ["Lost Woods"] = function () return true end,
            ["Goron City"] = function () return event(GORON_CITY_SHORTCUT) end,
        },
    },
    ["Goron City"] = {
        ["exits"] = {
            ["Goron City Shortcut"] = function () return event(GORON_CITY_SHORTCUT) end,
            ["Death Mountain"] = function () return true end,
            ["Death Mountain Crater Bottom"] = function () return is_adult() and (has_explosives() or can_use_bow() or has(STRENGTH)) end,
            ["Goron Shop"] = function () return cond(is_adult(), has_explosives() or can_use_bow() or has(STRENGTH), has_bombflowers()) end,
        },
        ["locations"] = {
            ["Darunia"] = function () return can_play(SONG_ZELDA) and can_play(SONG_SARIA) end,
            ["Goron City Maze Center 1"] = function () return has_explosives_or_hammer() or can_lift_silver() end,
            ["Goron City Maze Center 2"] = function () return has_explosives_or_hammer() or can_lift_silver() end,
            ["Goron City Maze Left"] = function () return can_hammer() or can_lift_silver() end,
            ["Goron City Big Pot HP"] = function () return is_child() and has_explosives() and (can_play(SONG_ZELDA) or has_fire()) end,
            ["Goron City Tunic"] = function () return is_adult() and (has_explosives() or can_use_bow() or has(STRENGTH)) end,
            ["Goron City Bomb Bag"] = function () return is_child() and has_explosives() end,
            ["Goron City Medigoron Giant Knife"] = function () return is_adult() and has(WALLET) and (has_bombflowers() or can_hammer()) end,
            ["Goron City GS Platform"] = function () return is_adult() end,
            ["Goron City GS Maze"] = function () return is_child() and has_explosives() end,
        },
    },
    ["Goron Shop"] = {
        ["exits"] = {
            ["Goron City"] = function () return true end,
        },
        ["locations"] = {
            ["Goron Shop Item 1"] = function () return true end,
            ["Goron Shop Item 2"] = function () return true end,
            ["Goron Shop Item 3"] = function () return true end,
            ["Goron Shop Item 4"] = function () return has(WALLET, 1) end,
            ["Goron Shop Item 5"] = function () return true end,
            ["Goron Shop Item 6"] = function () return true end,
            ["Goron Shop Item 7"] = function () return true end,
            ["Goron Shop Item 8"] = function () return has(WALLET, 1) end,
        },
    },
    ["Zora River Front"] = {
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Zora River"] = function () return is_adult() or (is_child() and has_explosives()) end,
        },
        ["locations"] = {
            ["Zora River GS Tree"] = function () return is_child() and can_damage_skull() end,
        },
    },
    ["Zora River"] = {
        ["exits"] = {
            ["Zora River Front"] = function () return true end,
            ["Zora Domain"] = function () return can_play(SONG_ZELDA) or (is_child() and trick(OOT_CHILD_DOMAIN)) or (has_hover_boots() and trick(OOT_ADULT_DOMAIN)) end,
            ["Lost Woods"] = function () return can_dive_small() end,
        },
        ["locations"] = {
            ["Zora River Bean Seller"] = function () return is_child() end,
            ["Zora River HP Pillar"] = function () return is_child() or has_hover_boots() end,
            ["Zora River HP Platform"] = function () return is_child() or has_hover_boots() end,
            ["Zora River Frogs Storms"] = function () return is_child() and can_play(SONG_STORMS) end,
            ["Zora River Frogs Game"] = function () return is_child() and can_play(SONG_ZELDA) and can_play(SONG_SARIA) and can_play(SONG_EPONA) and can_play(SONG_SUN) and can_play(SONG_TIME) and can_play(SONG_STORMS) end,
            ["Zora River Grotto"] = function () return true end,
            ["Zora River GS Ladder"] = function () return is_child() and gs_night() and can_damage_skull() end,
            ["Zora River GS Near Grotto"] = function () return is_adult() and gs_night() and can_hookshot() end,
            ["Zora River GS Near Bridge"] = function () return is_adult() and gs_night() and can_hookshot() end,
        },
    },
    ["Zora Domain"] = {
        ["events"] = {
            ["KING_ZORA_LETTER"] = function () return is_child() and has(RUTO_LETTER) end,
            ["STICKS"] = function () return is_child() end,
            ["NUTS"] = function () return true end,
        },
        ["exits"] = {
            ["Zora River"] = function () return true end,
            ["Lake Hylia"] = function () return is_child() and has(SCALE) end,
            ["Zora Domain Back"] = function () return event(KING_ZORA_LETTER) end,
            ["Zora Shop"] = function () return is_child() or has_blue_fire() end,
        },
        ["locations"] = {
            ["Zora Domain Waterfall Chest"] = function () return is_child() end,
            ["Zora Domain Diving Game"] = function () return is_child() end,
            ["Zora Domain Tunic"] = function () return is_adult() and has_blue_fire() end,
            ["Zora Domain Eyeball Frog"] = function () return has_blue_fire() and adult_trade(PRESCRIPTION) end,
            ["Zora Domain GS Waterfall"] = function () return is_adult() and gs_night() and (has_ranged_weapon_adult() or has(MAGIC_UPGRADE)) end,
        },
    },
    ["Zora Domain Back"] = {
        ["exits"] = {
            ["Zora Fountain"] = function () return true end,
            ["Zora Domain"] = function () return event(KING_ZORA_LETTER) end,
        },
    },
    ["Zora Shop"] = {
        ["exits"] = {
            ["Zora Domain"] = function () return true end,
        },
        ["locations"] = {
            ["Zora Shop Item 1"] = function () return true end,
            ["Zora Shop Item 2"] = function () return true end,
            ["Zora Shop Item 3"] = function () return has(WALLET, 1) end,
            ["Zora Shop Item 4"] = function () return true end,
            ["Zora Shop Item 5"] = function () return true end,
            ["Zora Shop Item 6"] = function () return true end,
            ["Zora Shop Item 7"] = function () return has(WALLET, 2) end,
            ["Zora Shop Item 8"] = function () return true end,
        },
    },
    ["Lake Hylia"] = {
        ["events"] = {
            ["SCARECROW_CHILD"] = function () return is_child() and has(OCARINA) end,
            ["SCARECROW"] = function () return is_adult() and event(SCARECROW_CHILD) end,
            ["BEAN_LAKE_HYLIA"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Hyrule Field"] = function () return true end,
            ["Zora Domain"] = function () return is_child() and has(SCALE) end,
            ["Laboratory"] = function () return true end,
            ["Water Temple"] = function () return has_iron_boots() and has_tunic_zora() and can_hookshot() end,
            ["Fishing Pond"] = function () return is_child() or event(WATER_TEMPLE_CLEARED) or scarecrow_hookshot() or can_ride_bean(BEAN_LAKE_HYLIA) end,
        },
        ["locations"] = {
            ["Lake Hylia Underwater Bottle"] = function () return is_child() and has(SCALE) end,
            ["Lake Hylia Fire Arrow"] = function () return can_use_bow() and (event(WATER_TEMPLE_CLEARED) or scarecrow_longshot()) end,
            ["Lake Hylia HP"] = function () return can_ride_bean(BEAN_LAKE_HYLIA) or scarecrow_hookshot() end,
            ["Lake Hylia GS Lab Wall"] = function () return gs_night() and can_boomerang() end,
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
            ["Laboratory Dive"] = function () return has(SCALE, 2) end,
            ["Laboratory Eye Drops"] = function () return adult_trade(EYEBALL_FROG) end,
            ["Laboratory GS Crate"] = function () return has_iron_boots() and can_hookshot() end,
        },
    },
    ["Fishing Pond"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
        },
        ["locations"] = {
            ["Fishing Pond Child"] = function () return is_child() end,
            ["Fishing Pond Adult"] = function () return is_adult() end,
        },
    },
    ["Zora Fountain"] = {
        ["exits"] = {
            ["Zora Domain Back"] = function () return true end,
            ["Jabu-Jabu"] = function () return is_child() and has_bottle() end,
            ["Zora Fountain Frozen"] = function () return is_adult() end,
        },
        ["locations"] = {
            ["Great Fairy Farore's Wind"] = function () return has_explosives() and can_play(SONG_ZELDA) end,
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
    ["Temple of Time"] = {
        ["events"] = {
            ["DOOR_OF_TIME_OPEN"] = function () return setting(doorOfTime, open) or can_play(SONG_TIME) end,
            ["TIME_TRAVEL"] = function () return event(DOOR_OF_TIME_OPEN) and has_sword_master() end,
        },
        ["exits"] = {
            ["Market"] = function () return is_child() end,
            ["Market Destroyed"] = function () return is_adult() end,
            ["Sacred Realm"] = function () return is_adult() and event(DOOR_OF_TIME_OPEN) end,
        },
        ["locations"] = {
            ["Temple of Time Master Sword"] = function () return is_child() and event(DOOR_OF_TIME_OPEN) end,
            ["Temple of Time Sheik Song"] = function () return is_adult() and event(DOOR_OF_TIME_OPEN) and has(MEDALLION_FOREST) end,
            ["Temple of Time Light Arrows"] = function () return is_adult() and has(MEDALLION_SPIRIT) and has(MEDALLION_SHADOW) end,
        },
    },
    ["Sacred Realm"] = {
        ["locations"] = {
            ["Temple of Time Medallion"] = function () return true end,
        },
    },
    ["Death Mountain Crater Top"] = {
        ["exits"] = {
            ["Death Mountain Summit"] = function () return true end,
            ["Death Mountain Crater Bottom"] = function () return event(RED_BOULDER_BROKEN) or has_hover_boots() end,
            ["Death Mountain Crater Warp"] = function () return has_tunic_goron_strict() and scarecrow_longshot() end,
        },
        ["locations"] = {
            ["Death Mountain Crater GS Crate"] = function () return is_child() and can_damage_skull() end,
            ["Death Mountain Crater Grotto"] = function () return has_explosives_or_hammer() end,
            ["Death Mountain Crater Alcove HP"] = function () return true end,
        },
    },
    ["Death Mountain Crater Bottom"] = {
        ["events"] = {
            ["RED_BOULDER_BROKEN"] = function () return can_hammer() end,
        },
        ["exits"] = {
            ["Goron City"] = function () return true end,
            ["Death Mountain Crater Warp"] = function () return can_hookshot() or has_hover_boots() end,
            ["Death Mountain Crater Top"] = function () return event(RED_BOULDER_BROKEN) end,
        },
        ["locations"] = {
            ["Great Fairy Magic Upgrade 2"] = function () return can_hammer() and can_play(SONG_ZELDA) end,
        },
    },
    ["Death Mountain Crater Warp"] = {
        ["events"] = {
            ["BEAN_DEATH_MOUNTAIN_CRATER"] = function () return can_use_beans() end,
        },
        ["exits"] = {
            ["Fire Temple Entry"] = function () return is_adult() and has_tunic_goron() end,
            ["Death Mountain Crater Bottom"] = function () return can_hookshot() or has_hover_boots() or can_ride_bean(BEAN_DEATH_MOUNTAIN_CRATER) end,
        },
        ["locations"] = {
            ["Death Mountain Crater Volcano HP"] = function () return can_ride_bean(BEAN_DEATH_MOUNTAIN_CRATER) or (trick(OOT_VOLCANO_HOVERS) and has_hover_boots()) end,
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
    ["Gerudo Valley"] = {
        ["exits"] = {
            ["Lake Hylia"] = function () return true end,
            ["Hyrule Field"] = function () return true end,
            ["Gerudo Valley After Bridge"] = function () return can_longshot() or (is_adult() and event(EPONA)) end,
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
        },
        ["locations"] = {
            ["Gerudo Valley Chest"] = function () return can_hammer() end,
            ["Gerudo Valley Broken Goron Sword"] = function () return adult_trade(POACHER_SAW) end,
            ["Gerudo Valley GS Tent"] = function () return can_hookshot() and gs_night() end,
            ["Gerudo Valley GS Pillar"] = function () return can_hookshot() and gs_night() end,
        },
    },
    ["Gerudo Fortress Exterior"] = {
        ["events"] = {
            ["OPEN_FORTRESS_GATE"] = function () return has(GERUDO_CARD) and is_adult() end,
        },
        ["exits"] = {
            ["Gerudo Fortress"] = function () return true end,
            ["Gerudo Valley After Bridge"] = function () return true end,
            ["Fortress Near Wasteland"] = function () return event(OPEN_FORTRESS_GATE) end,
            ["Gerudo Training Grounds"] = function () return has(GERUDO_CARD) and is_adult() end,
        },
        ["locations"] = {
            ["Gerudo Fortress Chest"] = function () return has_hover_boots() or can_longshot() or scarecrow_hookshot() end,
            ["Gerudo Fortress Archery Reward 1"] = function () return event(EPONA) and can_use_bow() and has(GERUDO_CARD) end,
            ["Gerudo Fortress Archery Reward 2"] = function () return event(EPONA) and can_use_bow() and has(GERUDO_CARD) end,
            ["Gerudo Fortress GS Wall"] = function () return can_hookshot() and gs_night() end,
            ["Gerudo Fortress GS Target"] = function () return can_hookshot() and gs_night() and has(GERUDO_CARD) end,
        },
    },
    ["Fortress Near Wasteland"] = {
        ["exits"] = {
            ["Gerudo Fortress Exterior"] = function () return event(OPEN_FORTRESS_GATE) end,
            ["Haunted Wasteland Start"] = function () return true end,
        },
    },
    ["Haunted Wasteland Start"] = {
        ["exits"] = {
            ["Fortress Near Wasteland"] = function () return true end,
            ["Haunted Wasteland Structure"] = function () return can_longshot() or has_hover_boots() or trick(OOT_SAND_RIVER_NOTHING) end,
        },
    },
    ["Haunted Wasteland Structure"] = {
        ["exits"] = {
            ["Haunted Wasteland Start"] = function () return can_longshot() or has_hover_boots() or trick(OOT_SAND_RIVER_NOTHING) end,
            ["Haunted Wasteland End"] = function () return has_lens_strict() or trick(OOT_BLIND_WASTELAND) end,
        },
        ["locations"] = {
            ["Haunted Wasteland Chest"] = function () return has_fire() end,
            ["Haunted Wasteland GS"] = function () return can_collect_distance() end,
        },
    },
    ["Haunted Wasteland End"] = {
        ["exits"] = {
            ["Haunted Wasteland Structure"] = function () return trick(OOT_BLIND_WASTELAND) end,
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
        },
        ["locations"] = {
            ["Desert Colossus HP"] = function () return can_ride_bean(BEAN_DESERT_COLOSSUS) end,
            ["Desert Colossus Song Spirit"] = function () return true end,
            ["Great Fairy Nayru's Love"] = function () return has_explosives() and can_play(SONG_ZELDA) end,
            ["Desert Colossus GS Soil"] = function () return gs_soil() and can_damage_skull() end,
            ["Desert Colossus GS Tree"] = function () return can_hookshot() and gs_night() end,
            ["Desert Colossus GS Plateau"] = function () return gs_night() and (can_longshot() or can_ride_bean(BEAN_DESERT_COLOSSUS)) end,
        },
    },
    ["Shadow Temple"] = {
        ["exits"] = {
            ["Graveyard Upper"] = function () return true end,
            ["Shadow Temple Pit"] = function () return has_hover_boots() or can_hookshot() end,
        },
    },
    ["Shadow Temple Pit"] = {
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
            ["Shadow Temple Open"] = function () return has(SMALL_KEY_SHADOW, 1) and has_explosives() end,
        },
        ["locations"] = {
            ["Shadow Temple Silver Rupees"] = function () return can_hookshot() or has_hover_boots() end,
            ["Shadow Temple Compass"] = function () return true end,
        },
    },
    ["Shadow Temple Open"] = {
        ["exits"] = {
            ["Shadow Temple Wind"] = function () return has(SMALL_KEY_SHADOW, 3) and can_hookshot() and has_lens() end,
        },
        ["locations"] = {
            ["Shadow Temple Spinning Blades Visible"] = function () return true end,
            ["Shadow Temple Spinning Blades Invisible"] = function () return has_lens() end,
            ["Shadow Temple Falling Spikes Lower"] = function () return true end,
            ["Shadow Temple Falling Spikes Upper 1"] = function () return has(STRENGTH) and has_lens() end,
            ["Shadow Temple Falling Spikes Upper 2"] = function () return has(STRENGTH) and has_lens() end,
            ["Shadow Temple Invisible Spike Room"] = function () return has(SMALL_KEY_SHADOW, 2) and can_hookshot() and has_lens() end,
            ["Shadow Temple Skull"] = function () return has(SMALL_KEY_SHADOW, 2) and can_hookshot() and has_explosives() and has_lens() end,
            ["Shadow Temple GS Skull Pot"] = function () return has(SMALL_KEY_SHADOW, 2) and can_hookshot() and has_lens() end,
            ["Shadow Temple GS Falling Spikes"] = function () return can_hookshot() end,
            ["Shadow Temple GS Invisible Scythe"] = function () return true end,
        },
    },
    ["Shadow Temple Wind"] = {
        ["exits"] = {
            ["Shadow Temple Boat"] = function () return has(SMALL_KEY_SHADOW, 4) and can_play(SONG_ZELDA) end,
        },
        ["locations"] = {
            ["Shadow Temple Wind Room Hint"] = function () return has_lens() end,
            ["Shadow Temple After Wind"] = function () return true end,
            ["Shadow Temple After Wind Invisible"] = function () return has_explosives() and has_lens() end,
            ["Shadow Temple GS Near Boat"] = function () return has(SMALL_KEY_SHADOW, 4) and can_longshot() end,
        },
    },
    ["Shadow Temple Boat"] = {
        ["exits"] = {
            ["Shadow Temple Boss"] = function () return has(SMALL_KEY_SHADOW, 5) and has(BOSS_KEY_SHADOW) and (can_use_bow() or scarecrow_longshot()) end,
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
            ["SPIRIT_CHILD_DOOR"] = function () return is_child() and has(SMALL_KEY_SPIRIT, 5) end,
            ["SPIRIT_ADULT_DOOR"] = function () return has(SMALL_KEY_SPIRIT, 3) and can_lift_silver() end,
        },
        ["exits"] = {
            ["Desert Colossus"] = function () return true end,
            ["Spirit Temple Child Entrance"] = function () return is_child() end,
            ["Spirit Temple Adult Entrance"] = function () return can_lift_silver() end,
        },
    },
    ["Spirit Temple Child Entrance"] = {
        ["exits"] = {
            ["Spirit Temple"] = function () return is_child() end,
            ["Spirit Temple Child Climb"] = function () return is_child() and has(SMALL_KEY_SPIRIT) end,
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
            ["Spirit Temple Child Entrance"] = function () return is_child() and has(SMALL_KEY_SPIRIT) end,
            ["Spirit Temple Statue"] = function () return has_explosives() end,
        },
        ["locations"] = {
            ["Spirit Temple Child Climb 1"] = function () return has_ranged_weapon_both() or (event(SPIRIT_CHILD_DOOR) and has_ranged_weapon_child()) or (event(SPIRIT_ADULT_DOOR) and has_ranged_weapon_adult()) end,
            ["Spirit Temple Child Climb 2"] = function () return has_ranged_weapon_both() or (event(SPIRIT_CHILD_DOOR) and has_ranged_weapon_child()) or (event(SPIRIT_ADULT_DOOR) and has_ranged_weapon_adult()) end,
            ["Spirit Temple GS Child Climb"] = function () return can_damage_skull() end,
        },
    },
    ["Spirit Temple Child Upper"] = {
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return true end,
            ["Spirit Temple Child Hand"] = function () return has(SMALL_KEY_SPIRIT, 5) end,
        },
        ["locations"] = {
            ["Spirit Temple Sun Block Room Torches"] = function () return event(SPIRIT_CHILD_DOOR) and can_use_sticks() and has_explosives() or has_fire_spirit() or (has_fire_arrows() and has(SMALL_KEY_SPIRIT, 4)) end,
            ["Spirit Temple GS Iron Knuckle"] = function () return event(SPIRIT_CHILD_DOOR) and can_boomerang() or (event(SPIRIT_ADULT_DOOR) and can_hookshot()) or (can_collect_ageless() and (has_explosives() or has(SMALL_KEY_SPIRIT, 2))) end,
        },
    },
    ["Spirit Temple Child Hand"] = {
        ["exits"] = {
            ["Spirit Temple Child Upper"] = function () return has(SMALL_KEY_SPIRIT, 5) end,
            ["Desert Colossus"] = function () return true end,
        },
        ["locations"] = {
            ["Spirit Temple Silver Gauntlets"] = function () return true end,
        },
    },
    ["Spirit Temple Adult Entrance"] = {
        ["exits"] = {
            ["Spirit Temple Adult Climb"] = function () return has(SMALL_KEY_SPIRIT) end,
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
            ["Spirit Temple Adult Suns on Wall 1"] = function () return event(SPIRIT_ADULT_DOOR) end,
            ["Spirit Temple Adult Suns on Wall 2"] = function () return event(SPIRIT_ADULT_DOOR) end,
        },
    },
    ["Spirit Temple Statue"] = {
        ["exits"] = {
            ["Spirit Temple Statue Adult"] = function () return can_hookshot() end,
            ["Spirit Temple Child Climb"] = function () return true end,
            ["Spirit Temple Child Upper"] = function () return true end,
            ["Spirit Temple Boss"] = function () return has(BOSS_KEY_SPIRIT) and event(SPIRIT_LIGHT_STATUE) and can_hookshot() end,
        },
        ["locations"] = {
            ["Spirit Temple Statue Base"] = function () return event(SPIRIT_CHILD_DOOR) and has_explosives() and can_use_sticks() or has_fire_spirit() or (has_fire_arrows() and has(SMALL_KEY_SPIRIT, 4)) end,
            ["Spirit Temple GS Statue"] = function () return event(SPIRIT_ADULT_DOOR) and (can_hookshot() or has_hover_boots()) end,
            ["Spirit Temple Silver Gauntlets"] = function () return has(SMALL_KEY_SPIRIT, 3) and has(HOOKSHOT, 2) and has_explosives() end,
        },
    },
    ["Spirit Temple Statue Adult"] = {
        ["exits"] = {
            ["Spirit Temple Statue"] = function () return true end,
            ["Spirit Temple Adult Upper"] = function () return has(SMALL_KEY_SPIRIT, 4) end,
        },
        ["locations"] = {
            ["Spirit Temple Statue Hands"] = function () return event(SPIRIT_ADULT_DOOR) and can_play(SONG_ZELDA) end,
            ["Spirit Temple Statue Upper Right"] = function () return event(SPIRIT_ADULT_DOOR) and can_play(SONG_ZELDA) and (has_hover_boots() or can_hookshot()) end,
        },
    },
    ["Spirit Temple Adult Upper"] = {
        ["exits"] = {
            ["Spirit Temple Adult Upper 2"] = function () return has_explosives() end,
            ["Spirit Temple Adult Climb 2"] = function () return has(SMALL_KEY_SPIRIT, 5) end,
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
            ["Water Temple Ruto Room"] = function () return has_tunic_zora() and (has_iron_boots() or (can_longshot() and trick(OOT_WATER_LONGSHOT))) end,
            ["Water Temple Center Bottom"] = function () return event(WATER_LEVEL_LOW) and has(SMALL_KEY_WATER, 5) end,
            ["Water Temple Center Middle"] = function () return event(WATER_LEVEL_LOW) and (can_use_din() or can_use_bow()) end,
            ["Water Temple Compass Room"] = function () return (has_tunic_zora() and has_iron_boots() or event(WATER_LEVEL_LOW)) and can_hookshot() end,
            ["Water Temple Dragon Room"] = function () return event(WATER_LEVEL_LOW) and has(STRENGTH) and can_dive_small() end,
            ["Water Temple Elevator"] = function () return has(SMALL_KEY_WATER, 5) and can_hookshot() or can_use_bow() or can_use_din() end,
            ["Water Temple Corridor"] = function () return (can_longshot() or has_hover_boots()) and can_use_bow() and event(WATER_LEVEL_LOW) end,
            ["Water Temple Waterfalls"] = function () return has_tunic_zora() and has(SMALL_KEY_WATER, 4) and can_longshot() and (has_iron_boots() or event(WATER_LEVEL_LOW)) end,
            ["Water Temple Large Pit"] = function () return has(SMALL_KEY_WATER, 4) and event(WATER_LEVEL_RESET) end,
            ["Water Temple Antichamber"] = function () return can_longshot() and event(WATER_LEVEL_RESET) end,
            ["Water Temple Cage Room"] = function () return has_tunic_zora() and event(WATER_LEVEL_LOW) and has_explosives() and can_dive_small() end,
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
            ["Water Temple Map Room"] = function () return event(WATER_LEVEL_RESET) end,
            ["Water Temple Shell Room"] = function () return event(WATER_LEVEL_LOW) and (can_use_bow() or has_fire()) end,
        },
        ["locations"] = {
            ["Water Temple Bombable Chest"] = function () return event(WATER_LEVEL_MIDDLE) and has_explosives() end,
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
            ["Water Temple Under Center"] = function () return event(WATER_LEVEL_MIDDLE) and has_iron_boots() and has_tunic_zora_strict() end,
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
            ["Water Temple Corridor Chest"] = function () return has(STRENGTH) end,
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
            ["Water Temple Waterfalls Ledge"] = function () return has_explosives() and has(STRENGTH) end,
        },
    },
    ["Water Temple Waterfalls Ledge"] = {
        ["exits"] = {
            ["Water Temple Boss Key Room"] = function () return has(SMALL_KEY_WATER, 5) end,
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
            ["Water Temple Before Dark Link"] = function () return has(SMALL_KEY_WATER, 5) and can_hookshot() end,
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
            ["Water Temple Boss"] = function () return has(BOSS_KEY_WATER) end,
        },
    },
}

    return M
end
