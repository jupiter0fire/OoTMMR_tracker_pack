local OOTMM_LOCATION_CHEST_LINKS = {
    tingle_swamp = {
        "@Clock Town Tingle Maps/Map: Swamp",
        "@Swamp Tingle Maps/Map: Swamp",
    },
    tingle_mountain = {
        "@Swamp Tingle Maps/Map: Mountain",
        "@Mountain Tingle Maps/Map: Mountain",
    },
    tingle_ocean = {
        "@Milk Road Tingle Maps/Map: Ocean",
        "@Ocean Tingle Maps/Map: Ocean",
    },
    tingle_canyon = {
        "@Ocean Tingle Maps/Map: Canyon",
        "@Ikana Canyon Tingle Maps/Map: Canyon",
    },
    tingle_ranch = {
        "@Mountain Tingle Maps/Map: Ranch",
        "@Milk Road Tingle Maps/Map: Ranch",
    },
    tingle_town = {
        "@Clock Town Tingle Maps/Map: Clock Town",
        "@Ikana Canyon Tingle Maps/Map: Clock Town",
    },
}
local OOTMM_LOCATION_CHEST_LINKS_PREV = {}
function on_update_location_chest_link()
    for group, locations in pairs(OOTMM_LOCATION_CHEST_LINKS) do
        local location_cache = {}
        for _, location_name in ipairs(locations) do
            local location = Tracker:FindObjectForCode(location_name)
            if not location then
                print("WARNING: location link '" .. location_name .. "' not found")
            else
                location_cache[location_name] = location
            end
        end

        -- If _PREV is set and one of the locations differs, set all others to this new value
        if OOTMM_LOCATION_CHEST_LINKS_PREV[group] then
            for _, location in pairs(location_cache) do
                if location.AvailableChestCount ~= OOTMM_LOCATION_CHEST_LINKS_PREV[group] then
                    for _, other_location in pairs(location_cache) do
                        other_location.AvailableChestCount = location.AvailableChestCount
                    end
                    break
                end
            end
        end

        OOTMM_LOCATION_CHEST_LINKS_PREV[group] = location_cache[locations[1]].AvailableChestCount
    end
end

local OOTMM_SHARED = {
    ["BombBags"] = { "BOMB_BAG" },
    ["BombchuBags"] = { "BOMBCHU" },
    ["Bows"] = { "BOW" },
    ["Magic"] = { "MAGIC_UPGRADE" },
    ["NutsSticks"] = { "NUT", "STICK" },
    ["Ocarina"] = { "OCARINA" },
    ["Wallets"] = { "WALLET" },
    ["MagicArrowFire"] = { "ARROW_FIRE" },
    ["MagicArrowIce"] = { "ARROW_ICE" },
    ["MagicArrowLight"] = { "ARROW_LIGHT" },
    ["SongEpona"] = { "SONG_EPONA" },
    ["SongStorms"] = { "SONG_STORMS" },
    ["SongTime"] = { "SONG_TIME" },
    ["Hookshot"] = { "HOOKSHOT" },
    ["Lens"] = { "LENS" },
    ["MaskGoron"] = { "MASK_GORON" },
    ["MaskZora"] = { "MASK_ZORA" },
    ["MaskBunny"] = { "MASK_BUNNY" },
    ["MaskKeaton"] = { "MASK_KEATON" },
    ["MaskTruth"] = { "MASK_TRUTH" },
    ["Shields"] = { "SHIELD_HYLIAN", "SHIELD_MIRROR"}
}
local OOTMM_SHARED_PREV = {
    ["BombBags"] = { 0 },
    ["BombchuBags"] = { 0 },
    ["Bows"] = { 0 },
    ["Magic"] = { 0 },
    ["NutsSticks"] = { 0, 0 },
    ["Ocarina"] = { 0 },
    ["Wallets"] = { 0 },
    ["MagicArrowFire"] = { 0 },
    ["MagicArrowIce"] = { 0 },
    ["MagicArrowLight"] = { 0 },
    ["SongEpona"] = { 0 },
    ["SongStorms"] = { 0 },
    ["SongTime"] = { 0 },
    ["Hookshot"] = { 0 },
    ["Lens"] = { 0 },
    ["MaskGoron"] = { 0 },
    ["MaskZora"] = { 0 },
    ["MaskBunny"] = { 0 },
    ["MaskKeaton"] = { 0 },
    ["MaskTruth"] = { 0 },
    ["Shields"] = { 0, 0 }
}
function on_update_shared_items()
    for setting, items in pairs(OOTMM_SHARED) do
        if Tracker:ProviderCountForCode("setting_shared" .. setting .. "_true") > 0 then
            for i, item in ipairs(items) do
                local oot_item = Tracker:FindObjectForCode("OOT_" .. item)
                local mm_item = Tracker:FindObjectForCode("MM_" .. item)
                if oot_item.CurrentStage ~= OOTMM_SHARED_PREV[setting][i] then
                    OOTMM_SHARED_PREV[setting][i] = oot_item.CurrentStage
                    mm_item.CurrentStage = oot_item.CurrentStage
                elseif mm_item.CurrentStage ~= OOTMM_SHARED_PREV[setting][i] then
                    OOTMM_SHARED_PREV[setting][i] = mm_item.CurrentStage
                    oot_item.CurrentStage = mm_item.CurrentStage
                end
            end
        end
    end
end

local OOTMM_SKIP_STAGE = {
    ["fairyOcarinaMm_false"] = {
        ["item"] = "MM_OCARINA",
        ["rule"] = function() return Tracker:ProviderCountForCode("setting_sharedOcarina_false") > 0 end
    },
    ["progressiveGoronLullaby_single"] = {
        ["item"] = "MM_SONG_GORON",
        ["rule"] = function() return true end
    },
    ["shortHookshotMm_false"] = {
        ["item"] = "MM_HOOKSHOT",
        ["rule"] = function() return Tracker:ProviderCountForCode("setting_sharedHookshot_false") > 0 end
    },
}
local OOTMM_SKIP_STAGE_PREV = {
    ["MM_OCARINA"] = 0,
    ["MM_SONG_GORON"] = 0,
    ["MM_HOOKSHOT"] = 0,
}
function on_update_skip_stages()
    for setting, v in pairs(OOTMM_SKIP_STAGE) do
        if Tracker:ProviderCountForCode("setting_" .. setting) > 0 then
            if v.rule() then
                local item = Tracker:FindObjectForCode(v.item)
                if item.CurrentStage > OOTMM_SKIP_STAGE_PREV[v.item] then
                    item.CurrentStage = item.CurrentStage + 1
                    OOTMM_SKIP_STAGE_PREV[v.item] = item.CurrentStage
                elseif item.CurrentStage < OOTMM_SKIP_STAGE_PREV[v.item] then
                    item.CurrentStage = item.CurrentStage - 1
                    OOTMM_SKIP_STAGE_PREV[v.item] = item.CurrentStage
                end
            end
        end
    end
end

local OOTMM_SMALL_KEY_SHUFFLEOOT_REMOVED_PREV = false
local OOTMM_SMALL_KEY_AMOUNTS = {
    ["OOT_SMALL_KEY_FOREST"] = {
        dungeon_name = "Forest Temple",
        vanilla = 5,
        mq = 6,
    },
    ["OOT_SMALL_KEY_FIRE"] = {
        dungeon_name = "Fire Temple",
        vanilla = function()
            if Tracker:ProviderCountForCode("setting_smallKeyShuffleOot_anywhere") > 0 then
                return 8
            else
                return 7
            end
        end,
        mq = 5,
    },
    ["OOT_SMALL_KEY_WATER"] = {
        dungeon_name = "Water Temple",
        vanilla = 6,
        mq = 2,
    },
    ["OOT_SMALL_KEY_SPIRIT"] = {
        dungeon_name = "Spirit Temple",
        vanilla = 5,
        mq = 7,
    },
    ["OOT_SMALL_KEY_SHADOW"] = {
        dungeon_name = "Shadow Temple",
        vanilla = 5,
        mq = 6,
    },
    ["OOT_SMALL_KEY_BOTW"] = {
        dungeon_name = "Bottom of the Well",
        vanilla = 3,
        mq = 2,
    },
    ["OOT_SMALL_KEY_GTG"] = {
        dungeon_name = "Gerudo Training Grounds",
        vanilla = 9,
        mq = 3,
    },
    ["OOT_SMALL_KEY_GANON"] = {
        dungeon_name = "Ganon Castle",
        vanilla = 2,
        mq = 3,
    },
    ["OOT_SMALL_KEY_GF"] = {
        dungeon_name = "NONE",
        vanilla = function()
            if Tracker:ProviderCountForCode("setting_gerudoFortress_vanilla") > 0 then
                return 4
            elseif Tracker:ProviderCountForCode("setting_gerudoFortress_single") > 0 then
                return 1
            else
                return 0
            end
        end,
    },
}
function on_update_oot_small_key_amounts()
    local oot_smallkeysanity_active = Tracker:ProviderCountForCode("setting_smallKeyShuffleOot_removed") > 0
    for key_code, key_data in pairs(OOTMM_SMALL_KEY_AMOUNTS) do
        local item = Tracker:FindObjectForCode(key_code)
        local mq_setting_name = "setting_mq_" .. key_data.dungeon_name:gsub(" ", "") .. '_true'
        local is_mq = Tracker:ProviderCountForCode(mq_setting_name) > 0

        local max_amount = key_data.vanilla

        if is_mq then
            max_amount = key_data.mq
        end

        if type(max_amount) == "function" then
            max_amount = max_amount()
        end

        item.MaxCount = max_amount

        -- Handle keysanity; if active, set all keys to their max amount
        if oot_smallkeysanity_active ~= OOTMM_SMALL_KEY_SHUFFLEOOT_REMOVED_PREV or not HAS_KEYS then
            if (oot_smallkeysanity_active and item.AcquiredCount == 0) or not HAS_KEYS then
                item.AcquiredCount = item.MaxCount
            elseif not oot_smallkeysanity_active and item.AcquiredCount == item.MaxCount then
                -- Try to be smart about small key handling; users would not like having to manually
                -- reset these to 0 if they're just cycling through small key settings.
                item.AcquiredCount = 0
            end
        end
    end
    OOTMM_SMALL_KEY_SHUFFLEOOT_REMOVED_PREV = oot_smallkeysanity_active
end

local OOTMM_BOSS_KEY_SHUFFLEOOT_REMOVED_PREV = false
function on_update_oot_boss_key_amounts()
    local oot_bosskeysanity_active = Tracker:ProviderCountForCode("setting_bossKeyShuffleOot_removed") > 0
    for _, key_code in pairs({ "OOT_BOSS_KEY_FOREST", "OOT_BOSS_KEY_FIRE", "OOT_BOSS_KEY_WATER", "OOT_BOSS_KEY_SPIRIT",
        "OOT_BOSS_KEY_SHADOW" }) do
        local item = Tracker:FindObjectForCode(key_code)
        if oot_bosskeysanity_active ~= OOTMM_BOSS_KEY_SHUFFLEOOT_REMOVED_PREV or not HAS_KEYS then
            if (oot_bosskeysanity_active and item.Active == false) or not HAS_KEYS then
                item.Active = true
            elseif not oot_bosskeysanity_active and item.Active == true then
                item.Active = false
            end
        end
    end
    OOTMM_BOSS_KEY_SHUFFLEOOT_REMOVED_PREV = oot_bosskeysanity_active
end

local OOTMM_SMALL_KEY_SHUFFLEMM_REMOVED_PREV = false
function on_update_mm_small_key_amounts()
    local mm_smallkeysanity_active = Tracker:ProviderCountForCode("setting_smallKeyShuffleMm_removed") > 0
    for _, key_code in pairs({ "MM_SMALL_KEY_WF", "MM_SMALL_KEY_SH", "MM_SMALL_KEY_GB", "MM_SMALL_KEY_ST" }) do
        local item = Tracker:FindObjectForCode(key_code)
        if mm_smallkeysanity_active ~= OOTMM_SMALL_KEY_SHUFFLEMM_REMOVED_PREV or not HAS_KEYS then
            if (mm_smallkeysanity_active and item.AcquiredCount == 0) or not HAS_KEYS then
                item.AcquiredCount = item.MaxCount
            elseif not mm_smallkeysanity_active and item.AcquiredCount == item.MaxCount then
                item.AcquiredCount = 0
            end
        end
    end
    OOTMM_SMALL_KEY_SHUFFLEMM_REMOVED_PREV = mm_smallkeysanity_active
end

local OOTMM_BOSS_KEY_SHUFFLEMM_REMOVED_PREV = false
function on_update_mm_boss_key_amounts()
    local mm_bosskeysanity_active = Tracker:ProviderCountForCode("setting_bossKeyShuffleMM_removed") > 0
    for _, key_code in pairs({ "MM_BOSS_KEY_WF", "MM_BOSS_KEY_SH", "MM_BOSS_KEY_GB", "MM_BOSS_KEY_ST" }) do
        local item = Tracker:FindObjectForCode(key_code)
        if mm_bosskeysanity_active ~= OOTMM_BOSS_KEY_SHUFFLEMM_REMOVED_PREV or not HAS_KEYS then
            if (mm_bosskeysanity_active and item.Active == false) or not HAS_KEYS then
                item.Active = true
            elseif not mm_bosskeysanity_active and item.Active == true then
                item.Active = false
            end
        end
    end
    OOTMM_BOSS_KEY_SHUFFLEMM_REMOVED_PREV = mm_bosskeysanity_active
end
