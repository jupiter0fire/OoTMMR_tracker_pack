function mm_has(item, amount)
  local count = Tracker:ProviderCountForCode(item)
  amount = tonumber(amount)
  if not amount then
    return count > 0
  else
    return count == amount
  end
end

function mm_has_explosives()
  local bombs = Tracker:ProviderCountForCode("bombs")
  if bombs > 0 then
    return bombs
  elseif (mm_has("mm_blastmask") and mm_has("mm_shield1")) then
    return 1
  elseif (mm_has("mm_blastmask") and mm_has("mm_damage")) then
    return 1
  elseif mm_has("mm_blastmask") then
    return 1, AccessibilityLevel.SequenceBreak
  elseif (mm_has("mm_powderkeg") and mm_has("mm_goron")) then
    return 1, AccessibilityLevel.SequenceBreak
  else
    return 0
  end
end

function mm_can_break_rocks()
  if mm_has("mm_goronmask")
  then
    return 1
  else
    return mm_has_explosives()
  end
end

function mm_can_break_snowballs()
  if (mm_has("mm_bow") and mm_has("mm_firearrows"))
  then
    return 1
  else
    return mm_can_break_rocks()
  end
end

function mm_night_inn_access()
  if mm_has("mm_deku")
  or mm_has("mm_roomkey")
  or (mm_has("mm_zora") and mm_has("mm_gainer"))
  or (mm_has("mm_zora") and mm_has("mm_balconyzora"))
  or mm_has("mm_$longjump")
  then
    return 1
  elseif mm_has("mm_zora") then
    return 1, AccessibilityLevel.SequenceBreak
  else
    return 0
  end
end



function mm_longjump()
  if (mm_has("mm_bombs")and mm_has("mm_longjump") and mm_has("mm_damage"))
  or (mm_has("mm_blastmask") and mm_has("mm_longjump") and mm_has("mm_damage"))
  then
    return 1
  else
  return 0
  end
end

function mm_istteyegore()
  if (mm_has("mm_istteyehook") and mm_has("mm_isttuphuman"))
  or (mm_has("mm_istteyehook") and mm_has("mm_deku"))
  or (mm_has("mm_deku") and mm_has("mm_stonetower_small_keys", 2))
    or (mm_has("mm_deku") and mm_has("mm_stonetower_small_keys", 3))
    or (mm_has("mm_deku") and mm_has("mm_stonetower_small_keys", 4))
  then
    return 1
  else
  return 0
end
end


function mm_goron_fence_jump()
  if (mm_has("mm_bombs") and mm_has("mm_goron") and mm_has("mm_goronfence"))
  then
    return 1
  else
  return 0
end
end



function mm_can_deal_damage()
  if mm_has("mm_sword1")
  or (mm_has("mm_sticks") and mm_has("mm_stickfighting"))
  or mm_has("mm_bow")
  or mm_has("mm_fairysword")
  or mm_has("mm_goronmask")
  or mm_has("mm_zoramask")
  then
    return 1
  elseif mm_has("mm_sticks") then
    return 1, AccessibilityLevel.SequenceBreak
  else
    return mm_has_explosives(), AccessibilityLevel.SequenceBreak
  end
end

function mm_has_projectile()
   if mm_has("mm_hookshot")
   or mm_has("mm_bow")
   or mm_has("mm_zoramask")
   or (mm_has("mm_dekumask") and mm_has("mm_magic"))
  then
    return 1
  else
    return 0
  end
end

function mm_can_see_with_lens()
   if mm_has("mm_lens") 
  and mm_has("mm_magic") then
    return 1
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function mm_can_grow_magic_plant()
  if (mm_has("mm_bottlesanity_no")  and mm_has("mm_beans") and mm_has("mm_bottle"))
  or (mm_has("mm_bottlesanity_yes") and mm_has("mm_beans") and mm_has("mm_water"))
  or (mm_has("mm_bottlesanity_yes") and mm_has("mm_beans") and mm_has("mm_hotspringwater"))
  or (mm_has("mm_beans") and mm_has("mm_songofstorms") and mm_has("mm_ocarina"))
  then
    return 1
  else
    return 0
  end
end

function mm_can_bottle_hotspringwater()
  if (mm_has("mm_bottlesanity_yes") and mm_has("mm_hotspringwater"))
  or (mm_has("mm_bottlesanity_no") and mm_has("mm_bottle") and mm_has("mm_goron") and mm_has("mm_lens") and mm_has("mm_magic"))
  or (mm_has("mm_bottlesanity_no") and mm_has("mm_bottle") and mm_has("mm_goron") and mm_has("mm_lens_climb"))
  or (mm_has("mm_bottlesanity_no") and mm_has("mm_firearrows") and mm_has("mm_bow") and mm_has("mm_magic"))
  then
  return 1
  elseif (mm_has("mm_bottlesanity_no") and mm_has("mm_bottle") and mm_has("mm_goron"))
  then return 1,AccessibilityLevel.SequenceBreak
  else
	return 0
  end
end


function mm_has_greatbay_frog_access()
  if (mm_has("mm_epona") and mm_has("mm_zora") and mm_has("mm_ocarina") and mm_has("mm_nova") and mm_has("mm_hookshot") and has ("icearrows") and mm_has("mm_magic") and mm_has("mm_bow") and mm_has("mm_firearrows") and mm_has("mm_gyorgbay"))
  or (mm_has("mm_epona") and mm_has("mm_zora") and mm_has("mm_ocarina") and mm_has("mm_nova") and mm_has("mm_hookshot") and has ("bow") and mm_has("mm_icearrows") and mm_has("mm_magic") and mm_has("mm_gbtbkfl")and mm_has("mm_gyorgbay"))
  or (mm_has("mm_deku") and mm_has("mm_sonata") and mm_has("mm_ocarina") and mm_has("mm_bow") and mm_has("mm_magic") and mm_has("mm_icearrows") and mm_has("mm_firearrows") and mm_has("mm_zora") and mm_has("mm_gyorgwood"))
  or (mm_has("mm_deku") and mm_has("mm_sonata") and mm_has("mm_ocarina") and mm_has("mm_bow") and mm_has("mm_magic") and mm_has("mm_icearrows") and mm_has("mm_gbtbkfl") and mm_has("mm_zora") and mm_has("mm_gyorgwood"))
  or (mm_has("mm_bow") and mm_has("mm_goron") and mm_has("mm_zora") and mm_has("mm_lullaby") and mm_has("mm_ocarina") and mm_has("mm_magic") and mm_has("mm_gyorgsnow") and mm_has("mm_icearrows") and mm_has("mm_firearrows"))
  or (mm_has("mm_bow") and mm_has("mm_goron") and mm_has("mm_zora") and mm_has("mm_lullaby") and mm_has("mm_ocarina") and mm_has("mm_magic") and mm_has("mm_gyorgsnow") and mm_has("mm_icearrows") and mm_has("mm_gbtbkfl"))
  or (mm_has("mm_ocarina") and mm_has("mm_eponasong") and mm_has("mm_hookshot") and mm_has("mm_gibdomask") and mm_has("mm_goron") and mm_has("mm_icearrows") and mm_has("mm_bow") and mm_has("mm_firearrows") and mm_has("mm_lightarrows") and mm_has("mm_magic") and mm_has("mm_zora") and mm_has("mm_elegy") and mm_has("mm_gyorgstone"))
  or (mm_has("mm_ocarina") and mm_has("mm_eponasong") and mm_has("mm_hookshot") and mm_has("mm_garomask") and mm_has("mm_goron") and mm_has("mm_icearrows") and mm_has("mm_bow") and mm_has("mm_firearrows") and mm_has("mm_lightarrows") and mm_has("mm_magic") and mm_has("mm_zora") and mm_has("mm_elegy") and mm_has("mm_gyorgstone"))
  or (mm_has("mm_ocarina") and mm_has("mm_eponasong") and mm_has("mm_hookshot") and mm_has("mm_gibdomask") and mm_has("mm_goron") and mm_has("mm_icearrows") and mm_has("mm_bow") and mm_has("mm_gbtbkfl") and mm_has("mm_lightarrows") and mm_has("mm_magic") and mm_has("mm_zora") and mm_has("mm_elegy") and mm_has("mm_gyorgstone"))
  or (mm_has("mm_ocarina") and mm_has("mm_eponasong") and mm_has("mm_hookshot") and mm_has("mm_garomask") and mm_has("mm_goron") and mm_has("mm_icearrows") and mm_has("mm_bow") and mm_has("mm_gbtbkfl") and mm_has("mm_lightarrows") and mm_has("mm_magic") and mm_has("mm_zora") and mm_has("mm_elegy") and mm_has("mm_gyorgstone"))
    then
    return 1
  else
    return 0
  end
end

function mm_has_woodfall_frog_access()
  if (mm_has("mm_deku") and mm_has("mm_ocarina") and mm_has("mm_sonata") and mm_has("mm_bow") and mm_has("mm_odolwawood"))
  or (mm_has("mm_epona") and mm_has("mm_zora") and mm_has("mm_ocarina") and mm_has("mm_hookshot") and mm_has("mm_nova") and mm_has("mm_deku") and mm_has("mm_bow") and mm_has("mm_odolwabay"))
  or (mm_has("mm_goron") and mm_has("mm_ocarina") and mm_has("mm_lullaby") and mm_has("mm_magic") and mm_has("mm_deku") and mm_has("mm_bow") and mm_has("mm_odolwasnow"))
  or (mm_has("mm_ocarina") and mm_has("mm_eponasong") and mm_has("mm_hookshot") and mm_has("mm_gibdomask") and mm_has("mm_goron") and mm_has("mm_icearrows") and mm_has("mm_bow") and mm_has("mm_lightarrows") and mm_has("mm_magic") and mm_has("mm_zora") and mm_has("mm_elegy") and mm_has("mm_deku") and mm_has("mm_odolwastone"))
  or (mm_has("mm_ocarina") and mm_has("mm_eponasong") and mm_has("mm_hookshot") and mm_has("mm_garomask") and mm_has("mm_goron") and mm_has("mm_icearrows") and mm_has("mm_bow") and mm_has("mm_lightarrows") and mm_has("mm_magic") and mm_has("mm_zora") and mm_has("mm_elegy") and mm_has("mm_deku") and mm_has("mm_odolwastone"))
      then
        return 1
      else
        return 0
      end
end


function mm_inverted_access()
  if (mm_has("mm_deku") and mm_has("mm_ocarina") and mm_has("mm_sonata") and mm_has("mm_bow") and mm_has("mm_twinwood"))
  or (mm_has("mm_goron") and mm_has("mm_lullaby") and mm_has("mm_bow") and mm_has("mm_magic") and mm_has("mm_ocarina") and mm_has("mm_twinsnow"))
  or (mm_has("mm_zora") and mm_has("mm_nova") and mm_has("mm_ocarina") and mm_has("mm_hookshot") and mm_has("mm_eponasong") and mm_has("mm_twinbay"))
  then
    return 1
  else
    return 0
  end
end


function mm_can_LA()
   if mm_has("mm_magic")
  and mm_has("mm_bow")
  and mm_has("mm_lightarrows")
  then
    return 1
  else
    return 0
  end
end

function mm_has_fire()
   if mm_has("mm_magic")
  and mm_has("mm_bow")
  and mm_has("mm_firearrows")
  then
    return 1
  else
    return 0
  end
end

function mm_can_IA()
   if mm_has("mm_magic")
  and mm_has("mm_bow")
  and mm_has("mm_icearrows")
  then
    return 1
  else
    return 0
  end
end



function mm_woodfall_not_known_but_odolwa_found()
  if mm_has("mm_odolwawood") or mm_has("mm_gohtwood") or mm_has("mm_gyorgwood") or mm_has("mm_twinwood")then
      return 0
  elseif mm_has("mm_odolwawood") or mm_has("mm_odolwasnow") or mm_has("mm_odolwabay") or mm_has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_woodfall_not_known_but_goht_found()
  if mm_has("mm_odolwawood") or mm_has("mm_gohtwood") or mm_has("mm_gyorgwood") or mm_has("mm_twinwood")then
      return 0
  elseif mm_has("mm_gohtwood") or mm_has("mm_gohtsnow") or mm_has("mm_gohtbay") or mm_has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end
function mm_woodfall_not_known_but_gyorg_found()
  if mm_has("mm_odolwawood") or mm_has("mm_gohtwood") or mm_has("mm_gyorgwood") or mm_has("mm_twinwood")then
      return 0
  elseif mm_has("mm_gyorgwood") or mm_has("mm_gyorgsnow") or mm_has("mm_gyorgbay") or mm_has("mm_gyorgstone") then
    return 0
  else
      return 1
  end
end
function mm_woodfall_not_known_but_twinmold_found()
  if mm_has("mm_odolwawood") or mm_has("mm_gohtwood") or mm_has("mm_gyorgwood") or mm_has("mm_twinwood")then
      return 0
  elseif mm_has("mm_twingwood") or mm_has("mm_twinsnow") or mm_has("mm_twinbay") or mm_has("mm_twinstone") then
    return 0
  else
      return 1
  end
end



function mm_snowhead_not_known_but_odolwa_found()
  if mm_has("mm_odolwasnow") or mm_has("mm_gohtsnow") or mm_has("mm_gyorgsnow") or mm_has("mm_twinsnow")then
      return 0
  elseif mm_has("mm_odolwawood") or mm_has("mm_odolwasnow") or mm_has("mm_odolwabay") or mm_has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_snowhead_not_known_but_goht_found()
  if mm_has("mm_odolwasnow") or mm_has("mm_gohtsnow") or mm_has("mm_gyorgsnow") or mm_has("mm_twinsnow")then
      return 0
  elseif mm_has("mm_gohtwood") or mm_has("mm_gohtsnow") or mm_has("mm_gohtbay") or mm_has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end

function mm_snowhead_not_known_but_gyorg_found()
  if mm_has("mm_odolwasnow") or mm_has("mm_gohtsnow") or mm_has("mm_gyorgsnow") or mm_has("mm_twinsnow")then
      return 0
  elseif mm_has("mm_gyorgwood") or mm_has("mm_gyorgsnow") or mm_has("mm_gyorgbay") or mm_has("mm_gyorg4") then
    return 0
  else
      return 1
  end
end
function mm_snowhead_not_known_but_twinmold_found()
  if mm_has("mm_odolwasnow") or mm_has("mm_gohtsnow") or mm_has("mm_gyorgsnow") or mm_has("mm_twinsnow")then
      return 0
  elseif mm_has("mm_twinwood") or mm_has("mm_twinsnow") or mm_has("mm_twinbay") or mm_has("mm_twinstone") then
    return 0
  else
      return 1
  end
end
function mm_bay_not_known_but_odolwa_found()
  if mm_has("mm_odolwabay") or mm_has("mm_gohtbay") or mm_has("mm_gyorgbay") or mm_has("mm_twinbay")then
      return 0
  elseif mm_has("mm_odolwawood") or mm_has("mm_odolwasnow") or mm_has("mm_odolwabay") or mm_has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_bay_not_known_but_goht_found()
  if mm_has("mm_odolwabay") or mm_has("mm_gohtbay") or mm_has("mm_gyorgbay") or mm_has("mm_twinbay")then
      return 0
  elseif mm_has("mm_gohtwood") or mm_has("mm_gohtsnow") or mm_has("mm_gohtbay") or mm_has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end

function mm_bay_not_known_but_gyorg_found()
  if mm_has("mm_odolwabay") or mm_has("mm_gohtbay") or mm_has("mm_gyorgbay") or mm_has("mm_twinbay")then
      return 0
  elseif mm_has("mm_gyorgwood") or mm_has("mm_gyorgsnow") or mm_has("mm_gyorgbay") or mm_has("mm_gyorg4") then
    return 0
  else
      return 1
  end
end
function mm_bay_not_known_but_twinmold_found()
  if mm_has("mm_odolwabay") or mm_has("mm_gohtbay") or mm_has("mm_gyorgbay") or mm_has("mm_twinbay")then
      return 0
  elseif mm_has("mm_twinwood") or mm_has("mm_twinsnow") or mm_has("mm_twinbay") or mm_has("mm_twinstone") then
    return 0
  else
      return 1
  end
end
function mm_stone_not_known_but_odolwa_found()
  if mm_has("mm_odolwastone") or mm_has("mm_gohtstone") or mm_has("mm_gyorgstone") or mm_has("mm_twinstone")then
      return 0
  elseif mm_has("mm_odolwawood") or mm_has("mm_odolwasnow") or mm_has("mm_odolwabay") or mm_has("mm_odolwastone") then
    return 0
  else
      return 1
  end
end

function mm_stone_not_known_but_goht_found()
  if mm_has("mm_odolwastone") or mm_has("mm_gohtstone") or mm_has("mm_gyorgstone") or mm_has("mm_twinstone")then
      return 0
  elseif mm_has("mm_gohtwood") or mm_has("mm_gohtsnow") or mm_has("mm_gohtbay") or mm_has("mm_gohtstone") then
    return 0
  else
      return 1
  end
end

function mm_stone_not_known_but_gyorg_found()
  if mm_has("mm_odolwastone") or mm_has("mm_gohtstone") or mm_has("mm_gyorgstone") or mm_has("mm_twinstone")then
      return 0
  elseif mm_has("mm_gyorgwood") or mm_has("mm_gyorgsnow") or mm_has("mm_gyorgbay") or mm_has("mm_gyorg4") then
    return 0
  else
      return 1
  end
end
function mm_stone_not_known_but_twinmold_found()
  if mm_has("mm_odolwastone") or mm_has("mm_gohtstone") or mm_has("mm_gyorgstone") or mm_has("mm_twinstone")then
      return 0
  elseif mm_has("mm_twinwood") or mm_has("mm_twinsnow") or mm_has("mm_twinbay") or mm_has("mm_twinstone") then
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