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
}
local OOTMM_SHARED_PREV = {
  ["BombBags"] = {0},
  ["Bows"] = {0},
  ["Magic"] = {0},
  ["NutsSticks"] = {0, 0},
  ["Ocarina"] = {0},
  ["Wallets"] = {0},
}
local OOTMM_SKIP_STAGE = {
  ["fairyOcarinaMm_false"] = {
    ["item"] = "MM_OCARINA",
    ["rule"] = function () return Tracker:ProviderCountForCode("setting_sharedOcarina_false") > 0 end
  },
  ["progressiveGoronLullaby_single"] = {
    ["item"] = "MM_SONG_GORON",
    ["rule"] = function () return true end
  },
  ["shortHookshotMm_false"] = {
    ["item"] = "MM_HOOKSHOT",
    ["rule"] = function () return true end
  },
}
local OOTMM_SKIP_STAGE_PREV = {
  ["MM_OCARINA"] = 0,
  ["MM_SONG_GORON"] = 0,
  ["MM_HOOKSHOT"] = 0,
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

    local ootSmallKeyFire = Tracker:FindObjectForCode("OOT_SMALL_KEY_FIRE")
    if Tracker:ProviderCountForCode("setting_smallKeyShuffleOot_anywhere") > 0 then
      ootSmallKeyFire.MaxCount = 8
    else
      ootSmallKeyFire.MaxCount = 7
    end

    -- Reset internal logic for all worlds
    OOTMM_RESET_LOGIC()
  end
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
