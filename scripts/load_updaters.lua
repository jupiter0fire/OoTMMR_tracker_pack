ScriptHost:LoadScript("scripts/update_maps.lua")

function tracker_on_begin_loading_save_file()
  PACK_READY = false
end

function tracker_on_finish_loading_save_file()
  OOTMM_RESET_LOGIC()
end

local OOTMM_SHARED = {
  ["BombBags"] = { "BOMB_BAG" },
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
  ["Lens"] = { "LENS" }
}
local OOTMM_SHARED_PREV = {
  ["BombBags"] = { 0 },
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
  ["Lens"] = { 0 }
}
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
local OOTMM_SMALL_KEY_SHUFFLEOOT_REMOVED_PREV = false
local OOTMM_SMALL_KEY_SHUFFLEMM_REMOVED_PREV = false
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
function tracker_on_accessibility_updating()
  if PACK_READY then
    -- Handle shared items in EmoTracker's GUI
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

    -- Handle max amounts for small keys in EmoTracker's GUI
    local oot_keysanity_active = Tracker:ProviderCountForCode("setting_smallKeyShuffleOot_removed") > 0
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
      if oot_keysanity_active ~= OOTMM_SMALL_KEY_SHUFFLEOOT_REMOVED_PREV then
        if oot_keysanity_active and item.AcquiredCount == 0 then
          item.AcquiredCount = item.MaxCount
        elseif not oot_keysanity_active and item.AcquiredCount == item.MaxCount then
          -- Try to be smart about small key handling; users would not like having to manually
          -- reset these to 0 if they're just cycling through small key settings.
          item.AcquiredCount = 0
        end
      end
    end
    OOTMM_SMALL_KEY_SHUFFLEOOT_REMOVED_PREV = oot_keysanity_active

    local mm_keysanity_active = Tracker:ProviderCountForCode("setting_smallKeyShuffleMm_removed") > 0
    for _, key_code in pairs({ "MM_SMALL_KEY_WF", "MM_SMALL_KEY_SH", "MM_SMALL_KEY_GB", "MM_SMALL_KEY_ST" }) do
      local item = Tracker:FindObjectForCode(key_code)
      if mm_keysanity_active ~= OOTMM_SMALL_KEY_SHUFFLEMM_REMOVED_PREV then
        if mm_keysanity_active and item.AcquiredCount == 0 then
          item.AcquiredCount = item.MaxCount
        elseif not mm_keysanity_active and item.AcquiredCount == item.MaxCount then
          item.AcquiredCount = 0
        end
      end
    end
    OOTMM_SMALL_KEY_SHUFFLEMM_REMOVED_PREV = mm_keysanity_active
  end

  -- Reset internal logic for all worlds
  OOTMM_RESET_LOGIC()
end

function tracker_on_accessibility_updated()
  if PACK_READY then
    clear_amount_cache()

    if update_maps then
      update_maps()
    end
    if update_version_specific then
      update_version_specific()
    end

    apply_queued_changes()

    get_object("dummy").Active = not get_object("dummy").Active
  end
end

function tracker_on_pack_ready()
  OOTMM_RESET_LOGIC()
  get_object("dummy").Active = not get_object("dummy").Active


  PACK_READY = true
end
