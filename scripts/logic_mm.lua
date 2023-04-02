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
  return has("mm_magic") and has("mm_lens")
end  

function mm_can_use_lens()
  return mm_can_use_lens_strict() or has("trick_mm_fewer_lens")
end 

function mm_grab_water_in_graveyard()
  return has("mm_bottle") and has("mm_goron")
end

function mm_mountain_village_to_goron_graveyard()
  return mm_can_use_lens_strict() or (has("mm_snowhead") and (has("mm_goron") or has("mm_zora")))
end

function mm_to_mountain_village()
  return (mm_can_break_boulders() or mm_can_use_fire_arrows()) and has("mm_bow")
end

function mm_goron_graveyard_hot_water()
  return mm_grab_water_in_graveyard() and mm_mountain_village_to_goron_graveyard() and mm_to_mountain_village()
end

function mm_ikana_canyon_to_well_hot_water()
  return (mm_has_explosives() or has("mm_zora")) and (has("mm_gibdo") and has("mm_bottle") and has("mm_scents"))
end

function mm_twin_island_hot_water()
  return mm_mountain_village_to_goron_graveyard() and mm_to_mountain_village() and (mm_can_use_fire_arrows() or has("mm_snowhead")) and has("mm_bottle")
end

function  mm_ikana_valley_to_canyon()
  return mm_can_use_ice_arrows() or has("trick_mm_iceless_ikana") and has("mm_hookshot")
end

function mm_to_ikana_valley()
  return (has("mm_garo") or has("mm_gibdo") and has("mm_hookshot")) and (mm_can_play("mm_epona") or has("trick_mm_goron_bomb_jump"))
end

function mm_well_hot_water()
  return mm_ikana_canyon_to_well_hot_water() and mm_ikana_valley_to_canyon() and mm_to_ikana_valley()
end

function mm_has_hot_water()
  return mm_goron_graveyard_hot_water() or mm_well_hot_water() or mm_twin_island_hot_water()
end  

function mm_sun_mask()
  return has("mm_lettertokafei") and mm_to_ikana_valley()
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
  return has("trick_mm_goron_bomb_jump") and has("mm_goron") and has("bombs")
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

function mm_can_break_rocks()
  if has("mm_goronmask")
  then
    return 1
  else
    return mm_has_explosives()
  end
end

function mm_can_break_snowballs()
  if (has("mm_bow") and has("mm_firearrows"))
  then
    return 1
  else
    return mm_can_break_rocks()
  end
end

function mm_night_inn_access()
  if has("mm_deku")
  or has("mm_roomkey")
  or (has("mm_zora") and has("mm_gainer"))
  or (has("mm_zora") and has("mm_balconyzora"))
  or has("mm_$longjump")
  then
    return 1
  elseif has("mm_zora") then
    return 1, AccessibilityLevel.SequenceBreak
  else
    return 0
  end
end



function mm_longjump()
  if (has("mm_bombs")and has("mm_longjump") and has("mm_damage"))
  or (has("mm_blastmask") and has("mm_longjump") and has("mm_damage"))
  then
    return 1
  else
  return 0
  end
end

function mm_istteyegore()
  if (has("mm_istteyehook") and has("mm_isttuphuman"))
  or (has("mm_istteyehook") and has("mm_deku"))
  or (has("mm_deku") and has("mm_stonetower_small_keys", 2))
    or (has("mm_deku") and has("mm_stonetower_small_keys", 3))
    or (has("mm_deku") and has("mm_stonetower_small_keys", 4))
  then
    return 1
  else
  return 0
end
end


function mm_goron_fence_jump()
  if (has("mm_bombs") and has("mm_goron") and has("mm_goronfence"))
  then
    return 1
  else
  return 0
end
end



function mm_can_deal_damage()
  if has("mm_sword1")
  or (has("mm_sticks") and has("mm_stickfighting"))
  or has("mm_bow")
  or has("mm_fairysword")
  or has("mm_goronmask")
  or has("mm_zoramask")
  then
    return 1
  elseif has("mm_sticks") then
    return 1, AccessibilityLevel.SequenceBreak
  else
    return mm_has_explosives(), AccessibilityLevel.SequenceBreak
  end
end

function mm_has_projectile()
   if has("mm_hookshot")
   or has("mm_bow")
   or has("mm_zoramask")
   or (has("mm_dekumask") and has("mm_magic"))
  then
    return 1
  else
    return 0
  end
end

function mm_can_see_with_lens()
   if has("mm_lens") 
  and has("mm_magic") then
    return 1
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function mm_can_grow_magic_plant()
  if (has("mm_bottlesanity_no")  and has("mm_beans") and has("mm_bottle"))
  or (has("mm_bottlesanity_yes") and has("mm_beans") and has("mm_water"))
  or (has("mm_bottlesanity_yes") and has("mm_beans") and has("mm_hotspringwater"))
  or (has("mm_beans") and has("mm_songofstorms") and has("mm_ocarina"))
  then
    return 1
  else
    return 0
  end
end

function mm_can_bottle_hotspringwater()
  if (has("mm_bottlesanity_yes") and has("mm_hotspringwater"))
  or (has("mm_bottlesanity_no") and has("mm_bottle") and has("mm_goron") and has("mm_lens") and has("mm_magic"))
  or (has("mm_bottlesanity_no") and has("mm_bottle") and has("mm_goron") and has("mm_lens_climb"))
  or (has("mm_bottlesanity_no") and has("mm_firearrows") and has("mm_bow") and has("mm_magic"))
  then
  return 1
  elseif (has("mm_bottlesanity_no") and has("mm_bottle") and has("mm_goron"))
  then return 1,AccessibilityLevel.SequenceBreak
  else
	return 0
  end
end


function mm_has_greatbay_frog_access()
  if (has("mm_epona") and has("mm_zora") and has("mm_ocarina") and has("mm_nova") and has("mm_hookshot") and has ("icearrows") and has("mm_magic") and has("mm_bow") and has("mm_firearrows") and has("mm_gyorgbay"))
  or (has("mm_epona") and has("mm_zora") and has("mm_ocarina") and has("mm_nova") and has("mm_hookshot") and has ("bow") and has("mm_icearrows") and has("mm_magic") and has("mm_gbtbkfl")and has("mm_gyorgbay"))
  or (has("mm_deku") and has("mm_sonata") and has("mm_ocarina") and has("mm_bow") and has("mm_magic") and has("mm_icearrows") and has("mm_firearrows") and has("mm_zora") and has("mm_gyorgwood"))
  or (has("mm_deku") and has("mm_sonata") and has("mm_ocarina") and has("mm_bow") and has("mm_magic") and has("mm_icearrows") and has("mm_gbtbkfl") and has("mm_zora") and has("mm_gyorgwood"))
  or (has("mm_bow") and has("mm_goron") and has("mm_zora") and has("mm_lullaby") and has("mm_ocarina") and has("mm_magic") and has("mm_gyorgsnow") and has("mm_icearrows") and has("mm_firearrows"))
  or (has("mm_bow") and has("mm_goron") and has("mm_zora") and has("mm_lullaby") and has("mm_ocarina") and has("mm_magic") and has("mm_gyorgsnow") and has("mm_icearrows") and has("mm_gbtbkfl"))
  or (has("mm_ocarina") and has("mm_eponasong") and has("mm_hookshot") and has("mm_gibdomask") and has("mm_goron") and has("mm_icearrows") and has("mm_bow") and has("mm_firearrows") and has("mm_lightarrows") and has("mm_magic") and has("mm_zora") and has("mm_elegy") and has("mm_gyorgstone"))
  or (has("mm_ocarina") and has("mm_eponasong") and has("mm_hookshot") and has("mm_garomask") and has("mm_goron") and has("mm_icearrows") and has("mm_bow") and has("mm_firearrows") and has("mm_lightarrows") and has("mm_magic") and has("mm_zora") and has("mm_elegy") and has("mm_gyorgstone"))
  or (has("mm_ocarina") and has("mm_eponasong") and has("mm_hookshot") and has("mm_gibdomask") and has("mm_goron") and has("mm_icearrows") and has("mm_bow") and has("mm_gbtbkfl") and has("mm_lightarrows") and has("mm_magic") and has("mm_zora") and has("mm_elegy") and has("mm_gyorgstone"))
  or (has("mm_ocarina") and has("mm_eponasong") and has("mm_hookshot") and has("mm_garomask") and has("mm_goron") and has("mm_icearrows") and has("mm_bow") and has("mm_gbtbkfl") and has("mm_lightarrows") and has("mm_magic") and has("mm_zora") and has("mm_elegy") and has("mm_gyorgstone"))
    then
    return 1
  else
    return 0
  end
end

function mm_has_woodfall_frog_access()
  if (has("mm_deku") and has("mm_ocarina") and has("mm_sonata") and has("mm_bow") and has("mm_odolwawood"))
  or (has("mm_epona") and has("mm_zora") and has("mm_ocarina") and has("mm_hookshot") and has("mm_nova") and has("mm_deku") and has("mm_bow") and has("mm_odolwabay"))
  or (has("mm_goron") and has("mm_ocarina") and has("mm_lullaby") and has("mm_magic") and has("mm_deku") and has("mm_bow") and has("mm_odolwasnow"))
  or (has("mm_ocarina") and has("mm_eponasong") and has("mm_hookshot") and has("mm_gibdomask") and has("mm_goron") and has("mm_icearrows") and has("mm_bow") and has("mm_lightarrows") and has("mm_magic") and has("mm_zora") and has("mm_elegy") and has("mm_deku") and has("mm_odolwastone"))
  or (has("mm_ocarina") and has("mm_eponasong") and has("mm_hookshot") and has("mm_garomask") and has("mm_goron") and has("mm_icearrows") and has("mm_bow") and has("mm_lightarrows") and has("mm_magic") and has("mm_zora") and has("mm_elegy") and has("mm_deku") and has("mm_odolwastone"))
      then
        return 1
      else
        return 0
      end
end


function mm_inverted_access()
  if (has("mm_deku") and has("mm_ocarina") and has("mm_sonata") and has("mm_bow") and has("mm_twinwood"))
  or (has("mm_goron") and has("mm_lullaby") and has("mm_bow") and has("mm_magic") and has("mm_ocarina") and has("mm_twinsnow"))
  or (has("mm_zora") and has("mm_nova") and has("mm_ocarina") and has("mm_hookshot") and has("mm_eponasong") and has("mm_twinbay"))
  then
    return 1
  else
    return 0
  end
end


function mm_can_LA()
   if has("mm_magic")
  and has("mm_bow")
  and has("mm_lightarrows")
  then
    return 1
  else
    return 0
  end
end

function mm_has_fire()
   if has("mm_magic")
  and has("mm_bow")
  and has("mm_firearrows")
  then
    return 1
  else
    return 0
  end
end

function mm_can_IA()
   if has("mm_magic")
  and has("mm_bow")
  and has("mm_icearrows")
  then
    return 1
  else
    return 0
  end
end



function mm_woodfall_not_known_but_odolwa_found()
  if has("mm_odolwawood") or has("mm_gohtwood") or has("mm_gyorgwood") or has("mm_twinwood")then
      return 0
  elseif has("mm_odolwawood") or has("mm_odolwasnow") or has("mm_odolwabay") or has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_woodfall_not_known_but_goht_found()
  if has("mm_odolwawood") or has("mm_gohtwood") or has("mm_gyorgwood") or has("mm_twinwood")then
      return 0
  elseif has("mm_gohtwood") or has("mm_gohtsnow") or has("mm_gohtbay") or has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end
function mm_woodfall_not_known_but_gyorg_found()
  if has("mm_odolwawood") or has("mm_gohtwood") or has("mm_gyorgwood") or has("mm_twinwood")then
      return 0
  elseif has("mm_gyorgwood") or has("mm_gyorgsnow") or has("mm_gyorgbay") or has("mm_gyorgstone") then
    return 0
  else
      return 1
  end
end
function mm_woodfall_not_known_but_twinmold_found()
  if has("mm_odolwawood") or has("mm_gohtwood") or has("mm_gyorgwood") or has("mm_twinwood")then
      return 0
  elseif has("mm_twingwood") or has("mm_twinsnow") or has("mm_twinbay") or has("mm_twinstone") then
    return 0
  else
      return 1
  end
end



function mm_snowhead_not_known_but_odolwa_found()
  if has("mm_odolwasnow") or has("mm_gohtsnow") or has("mm_gyorgsnow") or has("mm_twinsnow")then
      return 0
  elseif has("mm_odolwawood") or has("mm_odolwasnow") or has("mm_odolwabay") or has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_snowhead_not_known_but_goht_found()
  if has("mm_odolwasnow") or has("mm_gohtsnow") or has("mm_gyorgsnow") or has("mm_twinsnow")then
      return 0
  elseif has("mm_gohtwood") or has("mm_gohtsnow") or has("mm_gohtbay") or has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end

function mm_snowhead_not_known_but_gyorg_found()
  if has("mm_odolwasnow") or has("mm_gohtsnow") or has("mm_gyorgsnow") or has("mm_twinsnow")then
      return 0
  elseif has("mm_gyorgwood") or has("mm_gyorgsnow") or has("mm_gyorgbay") or has("mm_gyorg4") then
    return 0
  else
      return 1
  end
end
function mm_snowhead_not_known_but_twinmold_found()
  if has("mm_odolwasnow") or has("mm_gohtsnow") or has("mm_gyorgsnow") or has("mm_twinsnow")then
      return 0
  elseif has("mm_twinwood") or has("mm_twinsnow") or has("mm_twinbay") or has("mm_twinstone") then
    return 0
  else
      return 1
  end
end
function mm_bay_not_known_but_odolwa_found()
  if has("mm_odolwabay") or has("mm_gohtbay") or has("mm_gyorgbay") or has("mm_twinbay")then
      return 0
  elseif has("mm_odolwawood") or has("mm_odolwasnow") or has("mm_odolwabay") or has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_bay_not_known_but_goht_found()
  if has("mm_odolwabay") or has("mm_gohtbay") or has("mm_gyorgbay") or has("mm_twinbay")then
      return 0
  elseif has("mm_gohtwood") or has("mm_gohtsnow") or has("mm_gohtbay") or has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end

function mm_bay_not_known_but_gyorg_found()
  if has("mm_odolwabay") or has("mm_gohtbay") or has("mm_gyorgbay") or has("mm_twinbay")then
      return 0
  elseif has("mm_gyorgwood") or has("mm_gyorgsnow") or has("mm_gyorgbay") or has("mm_gyorg4") then
    return 0
  else
      return 1
  end
end
function mm_bay_not_known_but_twinmold_found()
  if has("mm_odolwabay") or has("mm_gohtbay") or has("mm_gyorgbay") or has("mm_twinbay")then
      return 0
  elseif has("mm_twinwood") or has("mm_twinsnow") or has("mm_twinbay") or has("mm_twinstone") then
    return 0
  else
      return 1
  end
end
function mm_stone_not_known_but_odolwa_found()
  if has("mm_odolwastone") or has("mm_gohtstone") or has("mm_gyorgstone") or has("mm_twinstone")then
      return 0
  elseif has("mm_odolwawood") or has("mm_odolwasnow") or has("mm_odolwabay") or has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_stone_not_known_but_goht_found()
  if has("mm_odolwastone") or has("mm_gohtstone") or has("mm_gyorgstone") or has("mm_twinstone")then
      return 0
  elseif has("mm_gohtwood") or has("mm_gohtsnow") or has("mm_gohtbay") or has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end

function mm_stone_not_known_but_gyorg_found()
  if has("mm_odolwastone") or has("mm_gohtstone") or has("mm_gyorgstone") or has("mm_twinstone")then
      return 0
  elseif has("mm_gyorgwood") or has("mm_gyorgsnow") or has("mm_gyorgbay") or has("mm_gyorg4") then
    return 0
  else
      return 1
  end
end
function mm_stone_not_known_but_twinmold_found()
  if has("mm_odolwastone") or has("mm_gohtstone") or has("mm_gyorgstone") or has("mm_twinstone")then
      return 0
  elseif has("mm_twinwood") or has("mm_twinsnow") or has("mm_twinbay") or has("mm_twinstone") then
    return 0
  else
      return 1
  end
end


function mm_tracker_on_accessibility_updated()
    local swampmap1 = Tracker:FindObjectForCode("@Clock Town Tingle Maps/Map: Swamp")
    local swampmap2 = Tracker:FindObjectForCode("@Swamp Tingle Maps/Map: Swamp")
	
    local mountainmap1 = Tracker:FindObjectForCode("@Swamp Tingle Maps/Map: Mountain")
    local mountainmap2 = Tracker:FindObjectForCode("@Mountain Tingle Maps/Map: Mountain")
	
    local oceanmap1 = Tracker:FindObjectForCode("@Milk Road Tingle Maps/Map: Ocean")
    local oceanmap2 = Tracker:FindObjectForCode("@Ocean Tingle Maps/Map: Ocean")
	
    local canyonmap1 = Tracker:FindObjectForCode("@Ocean Tingle Maps/Map: Canyon")
    local canyonmap2 = Tracker:FindObjectForCode("@Ikana Canyon Tingle Maps/Map: Canyon")
	
    local ranchmap1 = Tracker:FindObjectForCode("@Mountain Tingle Maps/Map: Ranch")
    local ranchmap2 = Tracker:FindObjectForCode("@Milk Road Tingle Maps/Map: Ranch")
	
    local townmap1 = Tracker:FindObjectForCode("@Clock Town Tingle Maps/Map: Clock Town")
    local townmap2 = Tracker:FindObjectForCode("@Ikana Canyon Tingle Maps/Map: Clock Town")
	
    local woodfall_oath = Tracker:FindObjectForCode("@Woodfall Temple/Oath to Order")
    local snowhead_oath = Tracker:FindObjectForCode("@Snowhead Temple/Oath to Order")
    local greatbay_oath = Tracker:FindObjectForCode("@Great Bay Temple/Oath to Order")
    local stonetower_oath = Tracker:FindObjectForCode("@Stone Tower Temple/Oath to Order")
	
    if swampmap1 and swampmap2 then
        if (swampmap1.AvailableChestCount == 0) or (swampmap2.AvailableChestCount == 0) then
            swampmap1.AvailableChestCount = 0
            swampmap2.AvailableChestCount = 0
        end
    end
	
	if mountainmap1 and mountainmap2 then
        if (mountainmap1.AvailableChestCount == 0) or (mountainmap2.AvailableChestCount == 0) then
            mountainmap1.AvailableChestCount = 0
            mountainmap2.AvailableChestCount = 0
        end
    end
	
    if oceanmap1 and oceanmap2 then
        if (oceanmap1.AvailableChestCount == 0) or (oceanmap2.AvailableChestCount == 0) then
            oceanmap1.AvailableChestCount = 0
            oceanmap2.AvailableChestCount = 0
        end
    end
	
    if canyonmap1 and canyonmap2 then
        if (canyonmap1.AvailableChestCount == 0) or (canyonmap2.AvailableChestCount == 0) then
            canyonmap1.AvailableChestCount = 0
            canyonmap2.AvailableChestCount = 0
        end
    end
	
    if ranchmap1 and ranchmap2 then
        if (ranchmap1.AvailableChestCount == 0) or (ranchmap2.AvailableChestCount == 0) then
            ranchmap1.AvailableChestCount = 0
            ranchmap2.AvailableChestCount = 0
        end
    end
	
    if townmap1 and townmap2 then
        if (townmap1.AvailableChestCount == 0) or (townmap2.AvailableChestCount == 0) then
            townmap1.AvailableChestCount = 0
            townmap2.AvailableChestCount = 0
        end
    end
	
    if woodfall_oath and snowhead_oath and greatbay_oath and stonetower_oath then
        if (woodfall_oath.AvailableChestCount == 0)
		or (snowhead_oath.AvailableChestCount == 0)
		or (greatbay_oath.AvailableChestCount == 0)
		or (stonetower_oath.AvailableChestCount == 0) then
            woodfall_oath.AvailableChestCount = 0
            snowhead_oath.AvailableChestCount = 0
            greatbay_oath.AvailableChestCount = 0
            stonetower_oath.AvailableChestCount = 0
        end
    end
	
end