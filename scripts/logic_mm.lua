function mm_can_use_deku_bubble()
  return has("mm_dekumask") and has("mm_magic")
end

function mm_has_weapon_range()
  return has("mm_bow") or has("mm_hookshot") or has("mm_zoramask") or mm_can_use_deku_bubble()
end

function mm_has_weapon()
  return has("mm_sword") or has("mm_fairysword")
end

function mm_can_fight()
  return mm_has_weapon() or has("mm_zoramask") or has("mm_goronmask")
end

function mm_meet_anju()
  return has("mm_kafeimask") and (has("mm_roomkey") or has("mm_dekumask"))
end

function mm_has_paper()
  return has("mm_towndeed") or has("mm_woodfall_deed") or has("mm_snowhead_deed") or has("mm_great_bay_deed") or has("mm_lettertokafei") or has("mm_deliverytomama")
end

function mm_has_explosives()
  return has("mm_bombs") or (has("mm_blastmask") and has("mm_shield"))
end

function mm_can_play(song)
  return has("mm_ocarina") and has(song)
end

function mm_can_use_beans()
  return has("mm_beans") and (has("mm_bottle") or mm_can_play("mm_songofstorms"))
end

function mm_can_break_boulders()
  return has("mm_bombs") or has("mm_goron")
end

function mm_can_use_keg()
  return has("mm_goron") and has("mm_keg")
end

function mm_boat_ride()
  return has("mm_pictograph") or has("mm_bottle")
end

function mm_open_woodfall()
  return has("mm_deku") and mm_can_play("mm_sonata")
end

function mm_deku_princess()
  return mm_has_weapon() and has("mm_bottle")
end

function mm_can_use_fire_arrows()
  return has("mm_magic") and has("mm_bow") and has("mm_firearrows")
end

function mm_can_use_lens_strict()
  if has("mm_magic") and has("mm_lens") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function mm_can_use_lens()
  local ls_count, ls_level =  mm_can_use_lens_strict()
  if has("trick_mm_fewer_lens") then
    return 1, AccessibilityLevel.Normal
  else
    return ls_count, ls_level
  end
end

function mm_grab_water_in_graveyard()
  return has("mm_bottle") and has("mm_goron")
end

function mm_mountain_village_to_goron_graveyard()
  local ls_count, ls_level = mm_can_use_lens_strict()
  if has("mm_snowhead") and (has("mm_goron") or has("mm_zora")) then
    return 1, AccessibilityLevel.Normal
  else
    return ls_count, ls_level
  end    
end

function mm_to_mountain_village()
  return (mm_can_break_boulders() or mm_can_use_fire_arrows()) and has("mm_bow")
end

function mm_goron_graveyard_hot_water()
  return mm_grab_water_in_graveyard() and mm_mountain_village_to_goron_graveyard() and mm_to_mountain_village()
end

function mm_ikana_canyon_to_well_hot_water()
  if (mm_has_explosives() or has("mm_zora")) and (has("mm_gibdo") and has("mm_bottle") and has("mm_scents")) then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None  
  end
end

function mm_twin_island_hot_water()
  return mm_mountain_village_to_goron_graveyard() and mm_to_mountain_village() and (mm_can_use_fire_arrows() or has("mm_snowhead")) and has("mm_bottle")
end

function mm_ikana_valley_to_canyon()
  if (mm_can_use_ice_arrows() or has("trick_mm_iceless_ikana")) and has("mm_hookshot") then
    return 1, AccessibilityLevel.Normal
  elseif has("mm_hookshot") then
    return 1, AccessibilityLevel.SequenceBreak  
  else
    return 0, AccessibilityLevel.None  
  end
end

function mm_to_ikana_valley()
  local bj_count, bj_level = mm_can_goron_bomb_jump()
  if ((has("mm_garo") or has("mm_gibdo")) and has("mm_hookshot")) and mm_can_play("mm_epona") then
    return 1, AccessibilityLevel.Normal
  elseif (has("mm_garo") or has("mm_gibdo")) and has("mm_hookshot") then
    return bj_count, bj_level
  else
    return 0, AccessibilityLevel.None  
  end
end

function mm_well_hot_water()
  local tc_count, tc_level = mm_ikana_valley_to_canyon()
  local tv_count, tv_level = mm_to_ikana_valley()
  local whw_count, whw_level = mm_ikana_canyon_to_well_hot_water()
  if math.min(tc_count,tv_count,whw_count) == 0 then
    return 0, AccessibilityLevel.None
  elseif tc_level == AccessibilityLevel.SequenceBreak or tv_level == AccessibilityLevel.SequenceBreak or whw_level == AccessibilityLevel.SequenceBreak then
    return 1, AccessibilityLevel.SequenceBreak
  else
    return 1, AccessibilityLevel.Normal    
  end
end

function mm_has_hot_water()
  return mm_goron_graveyard_hot_water() or mm_well_hot_water() or mm_twin_island_hot_water()
end

function mm_sun_mask()
  return has("mm_lettertokafei") and mm_to_ikana_valley() == 1
end

function mm_get_goron_food_in_goron_village()
  return has("mm_goron") and has("mm_magic") and (mm_can_use_fire_arrows() or mm_can_play("mm_lullaby_half"))
end

function mm_goron_food()
  return mm_to_mountain_village() and mm_get_goron_food_in_goron_village()
end

function mm_blacksmith_enabled()
  return has("mm_snowhead") or mm_can_use_fire_arrows() or mm_goron_graveyard_hot_water() or (mm_well_hot_water() and mm_can_play("mm_soaring"))
end

function mm_can_hookshot_scarecrow()
  return has("mm_ocarina") and has("mm_hookshot")
end

function mm_powder_keg_trial()
  return mm_to_mountain_village() and ((has("mm_snowhead") or mm_can_use_fire_arrows()) and has("mm_goron"))
end

function mm_goron_fast_roll()
  return has("mm_goron") and has("mm_magic")
end

function mm_can_goron_bomb_jump()
  if has("trick_mm_goron_bomb_jump") and has("mm_goron") and has("bombs") then
    return 1, AccessibilityLevel.Normal
  elseif has("mm_goron") and has("bombs") then
    return 1, AccessibilityLevel.SequenceBreak
  else
    return 0, AccessibilityLevel.None  
  end
end

function mm_can_evade_gerudo()
  return has("mm_bow") or has("mm_hookshot") or has("mm_zora") or has("mm_stone")
end

function mm_can_use_light_arrows()
  return has("mm_magic") and has("mm_bow") and has("mm_lightarrows")
end

function mm_has_bombchu()
  return has("mm_bombs")
end

function mm_can_use_ice_arrows()
  return has("mm_magic") and has("mm_bow") and has("mm_icearrows")
end

function mm_can_activate_crystal()
  return mm_can_break_boulders() or mm_has_weapon() or has("mm_bow") or has("mm_hookshot") or has("mm_deku") or has("mm_zora")
end

function mm_ikana_through_well_part1()
  return has("mm_gibdomask") and has("mm_beans")
end

function mm_ikana_through_well_part2()
  return has("mm_bottle") and has("mm_bombs") and (has("mm_bow") or has("mm_zora"))
end

function mm_ikana_through_well_part3()
  return has("mm_mirror") or mm_can_use_light_arrows()
end

function mm_ikana_through_well()
  return mm_ikana_through_well_part1() and mm_ikana_through_well_part2() and mm_ikana_through_well_part3()
end

function mm_moon_trial_link_part1()
  return mm_can_fight() or has("mm_bow")
end

function mm_moon_trial_link_part2()
  return has("mm_hookshot") and (mm_can_fight() or has("mm_bow"))
end

function mm_moon_trial_link_part3()
  return mm_has_bombchu() and has("mm_bow")
end

function mm_moon_trial_link_part4()
  return mm_has_bombchu() and mm_can_use_fire_arrows()
end

function mm_moon_trial_link()
  return mm_moon_trial_link_part1() and mm_moon_trial_link_part2() and mm_moon_trial_link_part3() and mm_moon_trial_link_part4()
end

function mm_can_use_elegy()
  return mm_can_play("mm_elegy")
end

function mm_can_use_elegy2()
  return mm_can_play("mm_elegy") or (has("mm_zora") or has("mm_goron"))
end

function mm_can_use_elegy3()
  return mm_can_play("mm_elegy") and has("mm_zora") and has("mm_goron")
end