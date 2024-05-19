ScriptHost:LoadScript("scripts/update_maps.lua")
ScriptHost:LoadScript("scripts/update_items.lua")

function tracker_on_begin_loading_save_file()
  PACK_READY = false
end

function tracker_on_finish_loading_save_file()
  OOTMM_RESET_LOGIC()
end

function tracker_on_accessibility_updating()
  if PACK_READY then
    -- Handle linked locations, mainly tingle maps, in EmoTracker's GUI
    on_update_location_chest_link()

    -- Handle shared items in EmoTracker's GUI
    on_update_shared_items()

    -- Handle skipped stages in EmoTracker's GUI
    on_update_skip_stages()

    -- Handle max amounts for OoT small keys in EmoTracker's GUI
    on_update_oot_small_key_amounts()

    -- Handle max amounts for OoT boss keys in EmoTracker's GUI
    on_update_oot_boss_key_amounts()

    -- Handle max amounts for MM small keys in EmoTracker's GUI
    on_update_mm_small_key_amounts()

    -- Handle max amounts for MM boss keys in EmoTracker's GUI
    on_update_mm_boss_key_amounts()
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
  PACK_READY = true
  OOTMM_RESET_LOGIC()
  get_object("dummy").Active = not get_object("dummy").Active
end
