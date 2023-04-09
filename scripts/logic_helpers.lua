function has(item, amount)
  local count = Tracker:ProviderCountForCode(item)
  amount = tonumber(amount)
  if not amount then
    return count > 0
  else
    return count >= amount
  end
end

function has_shield()
  return true
end

function has_shield_for_scrubs()
  if has("shield1") or has("shield2") then
    return 1, AccessibilityLevel.Normal
  end
  return 0, AccessibilityLevel.None
end

function has_shield_for_scrubs_child()
  if has("shield1") then
    return 1, AccessibilityLevel.Normal
  end
  return 0, AccessibilityLevel.None
end

function has_shield_for_scrubs_adult()
  if has("shield2") then
    return 1, AccessibilityLevel.Normal
  end
  return 0, AccessibilityLevel.None
end

function can_time_travel()
  if (has("setting_door_open") or (has("ocarina") and has("time"))) and has("mastersword") then
    return 1, AccessibilityLevel.Normal
  end
  return 0, AccessibilityLevel.None
end

function has_age(age)
  if not age then
    print("error! has_age - missing age")
  end

  if age == "child" then
    return 1, AccessibilityLevel.Normal
  elseif age == "adult" then
    return can_time_travel()
  elseif age == "both" then
    return can_time_travel()
  else
    print("error! has_age - invalid age:", age)
  end

  return 0, AccessibilityLevel.None
end

function can_play(song)
  return has("ocarina") and has(song)
end

function can_use_slingshot()
  return has_age("child") == 1 and has("slingshot")
end

function can_use_boomerang()
  return has_age("child") == 1 and has("boomerang")
end

function can_use_bow()
  return has_age("adult") == 1 and has("bow")
end

function can_use_hookshot()
  return has_age("adult") == 1 and has("hookshot")
end

function can_use_hammer()
  return has_age("adult") == 1 and has("hammer")
end

function has_ranged_weapon_child()
  return can_use_slingshot() or can_use_boomerang()
end

function has_ranged_weapon_adult()
  return can_use_bow() or can_use_hookshot()
end

function has_ranged_weapon()
  return has_ranged_weapon_child() or has_ranged_weapon_adult()
end

function has_explosives_bool()
  return has("bombs")
end

function has_explosives()
  local bombs = Tracker:ProviderCountForCode("bombs")
  local chus_count, chus_level = has_bombchus()
  if bombs > 0 then
    return bombs, AccessibilityLevel.Normal
  elseif chus_count > 0 then
    return chus_count, chus_level
  else
    return 0, AccessibilityLevel.None
  end
end

function has_bombflowers()
  return has_explosives_bool() or has("lift1")
end

function can_use_dins()
  return has("magic") and has("dinsfire")
end

function can_use_longshot()
  return has_age("adult") == 1 and has("longshot")
end

function has_iron_boots()
  return has_age("adult") == 1 and has("ironboots")
end

function can_dive_small()
  return has("silverscale") or has_iron_boots()
end

function can_dive_big()
  return has("goldscale") or has_iron_boots()
end

function has_hover_boots()
  return has_age("adult") == 1 and has("hoverboots")
end

function can_hit_triggers_distance()
  return can_use_bow() or can_use_slingshot()
end

function can_hit_triggers_distance_child()
  return can_use_slingshot()
end

function can_hit_triggers_distance_adult()
  return can_use_bow()
end

function has_explosives_or_hammer()
  return has_explosives_bool() or can_use_hammer()
end

function has_weapon()
  return (has_age("child") == 1 and has("sowrd1")) or has_age("adult") == 1
end

function has_weapon_child()
  if has_age("child") == 1 and has("sword1") then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function has_weapon_adult()
  if has_age("adult") == 1 then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function can_collect_distance()
  return can_use_hookshot() or can_use_boomerang()
end

function can_collect_distance_child()
  return can_use_boomerang()
end

function can_collect_distance_adult()
  return can_use_hookshot()
end

function can_hookshot_scarecrow()
  return can_use_hookshot() and has("scarecrow")
end

function can_longshot_scarecrow()
  return can_use_longshot() and has("scarecrow")
end

function has_fire_arrows()
  return can_use_bow() and has("firearrow") and has("magic")
end

function spirit_child_door()
  return has_age("child") == 1 and has("spirit_small_keys", 5)
end

function spirit_adult_door()
  return has_age("adult") == 1 and adult_colossus() == 1 and has("spirit_small_keys", 3) and has("lift2")
end

function has_fire_spirit()
  return has("magic") and ((has("bow") and has("firearrow") and has("sticks")) or has("dins")) and
      (has_explosives_bool() or has("spirit_small_keys", 2))
end

function can_collect_ageless()
  return can_use_hookshot() and can_use_boomerang()
end

function water_level_low()
  return has("ironboots") and can_play("lullaby")
end

function water_level_middle()
  return can_use_hookshot() and can_play("lullaby")
end

function stone_of_agony()
  if has("agony") or has("trick_oot_hidden_grottos") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function gs_soil()
  return has_age("child") == 1 and has_bottle() == 1
end

function gs_night()
  if has("trick_oot_night_skull_sun_song") or can_play("sun") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function hidden_grotto_storms()
  local sa_count, sa_level = stone_of_agony()

  if not (can_play("storm")) then
    return 0, AccessibilityLevel.None
  else
    return sa_count, sa_level
  end
end

function hidden_grotto_bomb()
  local sa_count, sa_level = stone_of_agony()

  if not (has_explosives_or_hammer()) then
    return 0, AccessibilityLevel.None
  else
    return sa_count, sa_level
  end
end

function hidden_grotto_bomb_child()
  local sa_count, sa_level = stone_of_agony()

  if not (has_explosives_bool()) then
    return 0, AccessibilityLevel.None
  else
    return sa_count, sa_level
  end
end

function hidden_grotto_bomb_adult()
  local sa_count, sa_level = stone_of_agony()

  if not (has_explosives_or_hammer()) then
    return 0, AccessibilityLevel.None
  else
    return sa_count, sa_level
  end
end

function dodongo_cavern_child_access()
  return has_age("child") == 1 and (has("letter") or has_explosives_bool()) and has_bombflowers()
end

function dodongo_cavern_adult_access()
  return has_age("adult") == 1 and (has_bombflowers() or can_use_hammer())
end

function spawn_access(region, age)
  region = region or ""
  age = age or ""

  if has_age(age) == 0 then
    return 0, AccessibilityLevel.None
  end

  local spawn_object = nil

  if
      spawn_object and spawn_object.CapturedItem and spawn_object.CapturedItem.Name and
      spawn_object.CapturedItem.Name == region
  then
    return 1, AccessibilityLevel.Normal
  end

  return 0, AccessibilityLevel.None
end

function hidden_grotto()
  if has("trick_oot_hidden_grottos") or has("agony") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function hintable()
  return 1, AccessibilityLevel.Normal
end

function has_bombchus()
  local bombs = Tracker:ProviderCountForCode("bombs")
  local chus = Tracker:ProviderCountForCode("bombchu")
  if has("setting_logic_chus_yes") then
    if chus > 0 then
      return chus, AccessibilityLevel.Normal
    else
      return 0, AccessibilityLevel.None
    end
  else
    if bombs > 0 then
      return bombs, AccessibilityLevel.Normal
    elseif chus > 0 then
      return chus, AccessibilityLevel.SequenceBreak
    end
  end
  return 0, AccessibilityLevel.None
end

function can_blast()
  if has_age("adult") == 1 and has("hammer") then
    return 1, AccessibilityLevel.Normal
  else
    return has_explosives()
  end
end

function has_projectile(age)
  local sling = has("sling")
  local rang = has("boomerang")
  local bow = has("bow")
  local hook = has("hookshot")

  if age == "child" then
    if sling or rang then
      return 1, AccessibilityLevel.Normal
    end
  elseif age == "adult" then
    if bow or hook then
      return 1, AccessibilityLevel.Normal
    end
  elseif age == "both" then
    if (bow or hook) and (sling or rang) then
      return 1, AccessibilityLevel.Normal
    end
  else
    if (bow or hook) or (sling or rang) then
      return 1, AccessibilityLevel.Normal
    end
  end

  return has_explosives()
end

function can_child_attack()
  if has_age("child") == 0 then
    return 0, AccessibilityLevel.None
  end

  if has("sling") or has("boomerang") or has("sticks") or has("sword1") or (has("dinsfire") and has("magic")) then
    return 1, AccessibilityLevel.Normal
  else
    return has_explosives()
  end
end

function can_stun_deku()
  if has_age("adult") == 1 or has("nuts") or has("shield1") then
    return 1, AccessibilityLevel.Normal
  else
    return can_child_attack()
  end
end

function can_use_lens()
  if has("lens") and has("magic") then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function can_LA()
  if has_age("adult") == 1 and has("magic") and has("bow") and has("lightarrow") then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function can_use_sticks()
  return has_age("child") == 1 and has("sticks")
end

function has_fire()
  return has("firearrow") or can_use_dins()
end

function has_fire_or_sticks()
  return can_use_sticks() or has_fire()
end

function beyond_mido()
  if
      (has("ocarina") and (has("saria") or has("minuet"))) or has("trick_oot_mido_skip") or
      spawn_access("Sacred Forest Meadow", "adult") > 0
  then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function gerudo_card()
  if has("card") then
    return 1, AccessibilityLevel.Normal
  end
  return 0, AccessibilityLevel.None
end

function _gerudo_bridge()
  if has_age("adult") == 0 then
    return 0, AccessibilityLevel.None
  end
  if
      has("longshot") or has("ocarina") and has("epona") or has("gerudo_fortress_open") or
      (has("setting_shuffle_card_no") and has("card")) or
      spawn_access("Gerudo Fortress", "adult") > 0
  then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function _quicksand()
  if has("longshot") or has("hoverboots") or has("trick_oot_blind_wasteland") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function _wasteland_forward()
  if has("trick_oot_fewer_lens") or has("lens") and has("magic") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function _wasteland_reverse()
  if has("logic_reverse_wasteland") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function gerudo_valley_far_side()
  if has_age("adult") == 0 then
    return 0, AccessibilityLevel.None
  end

  if _gerudo_bridge() > 0 then
    return 1, AccessibilityLevel.Normal
  end

  if has("ocarina") and has("requiem") then
    local _, reverse_level = _wasteland_reverse()
    local _, quicksand_level = _quicksand()

    if reverse_level == AccessibilityLevel.SequenceBreak or quicksand_level == AccessibilityLevel.SequenceBreak then
      return 1, AccessibilityLevel.SequenceBreak
    else
      return 1, AccessibilityLevel.Normal
    end
  end

  return 0, AccessibilityLevel.None
end

function wasteland()
  local forward_count = 0
  local forward_level = AccessibilityLevel.Normal

  local bridge_count = _gerudo_bridge()
  local card_count, card_level = gerudo_card()
  local _, quicksand_level = _quicksand()

  if bridge_count > 0 and card_count > 0 then
    forward_count = 1

    if card_level == AccessibilityLevel.SequenceBreak or quicksand_level == AccessibilityLevel.SequenceBreak then
      forward_level = AccessibilityLevel.SequenceBreak
    else
      return 1, AccessibilityLevel.Normal
    end
  end

  if has("ocarina") and has("requiem") then
    return _wasteland_reverse()
  end

  return forward_count, forward_level
end

function child_colossus()
  if has("ocarina") and has("requiem") and has_age("child") == 1 then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function adult_colossus()
  if has("ocarina") and has("requiem") then
    return 1, AccessibilityLevel.Normal
  end

  local bridge_count = _gerudo_bridge()
  if bridge_count == 0 then
    return 0, AccessibilityLevel.None
  end

  local card_count, card_level = gerudo_card()
  if card_count == 0 then
    return 0, AccessibilityLevel.None
  end
  local level = card_level

  local _, quicksand_level = _quicksand()
  local _, forward_level = _wasteland_forward()
  if quicksand_level == AccessibilityLevel.SequenceBreak or forward_level == AccessibilityLevel.SequenceBreak then
    level = AccessibilityLevel.SequenceBreak
  end

  return 1, level
end

function link_the_goron()
  if has_age("adult") == 0 then
    return 0, AccessibilityLevel.None
  end

  if has("lift1") or has("bow") then
    return 1, AccessibilityLevel.Normal
  end

  local count = 0
  local level = AccessibilityLevel.None

  if has("dinsfire") and has("magic") then
    if has("logic_link_goron_dins") then
      return 1, AccessibilityLevel.Normal
    else
      count = 1
      level = AccessibilityLevel.SequenceBreak
    end
  end

  local explo_count, explo_level = has_explosives()
  if explo_count > 0 then
    return explo_count, explo_level
  end

  return count, level
end

function goron_tunic()
  if has("redtunic") then
    return 1, AccessibilityLevel.Normal
  elseif has("wallet") then
    if spawn_access("GC Shop", "adult") > 0 then
      return 1, AccessibilityLevel.Normal
    end
    return link_the_goron()
  end
  return 0, AccessibilityLevel.None
end

function has_goron_tunic()
  if has("trick_oot_fewer_tunic") or (has("redtunic") and has_age("adult") == 1) then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function has_goron_tunic_strict()
  if has("redtunic") and has_age("adult") == 1 then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function has_zora_tunic()
  if (has("trick_oot_fewer_tunic") or has("bluetunic")) and has_age("adult") == 1 then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function has_zora_tunic_strict()
  if has("bluetunic") and has_age("adult") == 1 then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function has_lens_strict()
  if has("magic") and has("lens") then
    return 1, AccessibilityLevel.Normal
  else
    return 1, AccessibilityLevel.SequenceBreak
  end
end

function has_lens()
  local ls_count, ls_level = has_lens_strict()
  if has("trick_oot_fewer_lens") then
    return 1, AccessibilityLevel.Normal
  else
    return ls_count, ls_level
  end
end

function open_door_of_time()
  return has("setting_door_open") or can_play("time")
end

function can_damage_child()
  if has_weapon_child() == 1 or has("sticks") or has_explosives_bool() or can_use_slingshot() or can_use_dins() then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function can_damage_adult()
  if has_weapon_adult() == 1 or has_explosives_bool() == 1 or can_use_dins() then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function can_damage_skulls_child()
  if can_damage_child() == 1 or can_collect_distance_child() then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function can_damage_skulls_adult()
  if can_damage_adult() == 1 or can_collect_distance_adult() then
    return 1, AccessibilityLevel.Normal
  else
    return 0, AccessibilityLevel.None
  end
end

function child_river()
  if has_age("child") == 0 then
    return 0, AccessibilityLevel.None
  end

  if has("scale1") or spawn_access("Zora River", "child") > 0 or spawn_access("Zoras Domain", "child") > 0 then
    return 1, AccessibilityLevel.Normal
  end

  return has_explosives()
end

function child_domain()
  if has_age("child") == 0 then
    return 0, AccessibilityLevel.None
  end

  if has("scale1") or spawn_access("Zoras Domain", "child") > 0 then
    return 1, AccessibilityLevel.Normal
  end

  local river_count, river_level = child_river()
  if river_count > 0 then
    if (has("ocarina") and has("lullaby")) or has("logic_zora_with_cucco") then
      return river_count, river_level
    end
    return 1, AccessibilityLevel.SequenceBreak
  end

  return 0, AccessibilityLevel.None
end

function child_fountain()
  if has_age("child") == 0 then
    return 0, AccessibilityLevel.None
  end

  if has_exact("ruto", 0) then
    return 0, AccessibilityLevel.None
  end

  return child_domain()
end

function adult_domain()
  if has_age("adult") == 0 then
    return 0, AccessibilityLevel.None
  end

  if
      (has("ocarina") and has("lullaby")) or spawn_access("Zoras Domain", "adult") > 0 or
      spawn_access("ZD Shop", "adult") > 0
  then
    return 1, AccessibilityLevel.Normal
  elseif has("hoverboots") then
    if has("logic_zora_with_hovers") then
      return 1, AccessibilityLevel.Normal
    end
    return 1, AccessibilityLevel.SequenceBreak
  end

  return 0, AccessibilityLevel.None
end

function adult_fountain()
  if has_age("adult") == 0 then
    return 0, AccessibilityLevel.None
  end

  local domain, level = adult_domain()
  if domain == 0 then
    return 0, AccessibilityLevel.None
  end

  --handing in letter
  local child_count, child_level = child_fountain()
  if child_count > 0 and child_level == AccessibilityLevel.Normal then
    return 1, level
  end

  --KZ skip
  if has("logic_king_zora_skip") then
    return 1, level
  end
  return 1, AccessibilityLevel.SequenceBreak
end

function has_bottle()
  local bottles = Tracker:ProviderCountForCode("bottle")
  local ruto = Tracker:ProviderCountForCode("ruto")
  local kz_count, kz_level = child_fountain()
  local level = AccessibilityLevel.Normal

  local usable_bottles = bottles - ruto

  if kz_count > 0 and ruto > 0 then
    if usable_bottles == 0 then
      level = kz_level
    end
    usable_bottles = usable_bottles + ruto
  end

  return usable_bottles, level
end

blue_fire_locations = {
  "@Ganons Castle/Water Trial Chests"
}
function has_blue_fire()
  local bottle_count, bottle_level = has_bottle()

  if bottle_count == 0 then
    return 0, AccessibilityLevel.None
  end

  if has("wallet2") then
    return 1, bottle_level
  end

  local zf_count, zf_level = adult_fountain()
  if zf_count > 0 and zf_level == AccessibilityLevel.Normal then
    return 1, bottle_level
  end

  for _, location in ipairs(blue_fire_locations) do
    local location_object = get_object(location)
    if
        location_object and location_object.AccessibilityLevel and
        location_object.AccessibilityLevel == AccessibilityLevel.Normal
    then
      --TODO: trigger dummy update
      return 1, bottle_level
    end
  end

  return 1, AccessibilityLevel.SequenceBreak
end

function zora_tunic()
  if has("bluetunic") then
    return 1, AccessibilityLevel.Normal
  elseif has("wallet2") then
    if spawn_access("ZD Shop", "adult") > 0 then
      return 1, AccessibilityLevel.Normal
    end
    local bottle_count, bottle_level = has_bottle()
    local domain_count, domain_level = adult_domain()
    if bottle_count > 0 and domain_count > 0 then
      if bottle_level == AccessibilityLevel.SequenceBreak or domain_level == AccessibilityLevel.SequenceBreak then
        return 1, AccessibilityLevel.SequenceBreak
      else
        return 1, AccessibilityLevel.Normal
      end
    end
  end
  return 0, AccessibilityLevel.None
end

function damage_below_quadruple()
  return 1, AccessibilityLevel.Normal
end

function damage_below_ohko()
  return 1, AccessibilityLevel.Normal
end

function damage_single_instance_quadruple()
  if damage_below_quadruple() > 0 or has("nayrus") and has("magic") then
    return 1, AccessibilityLevel.Normal
  else
    return has_bottle()
  end
end

function damage_single_instance_ohko()
  if damage_below_ohko() > 0 or has("nayrus") and has("magic") then
    return 1, AccessibilityLevel.Normal
  else
    return has_bottle()
  end
end

function can_spawn_rainbow_bridge()
  return has("forestmed") and has("noct_meds", 2) and has("lacs_meds", 2) and has("lightmed")
end
