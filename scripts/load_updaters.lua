ScriptHost:LoadScript("scripts/update_maps.lua")

function tracker_on_begin_loading_save_file()
  PACK_READY = false
end

function tracker_on_finish_loading_save_file()
  OOTMM_RESET_LOGIC()
end

function tracker_on_accessibility_updating()
  if PACK_READY then
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
