function update_gerudo_card()
  local setting_card = has("setting_shuffle_card_yes")
  local setting_open = has("gerudo_fortress_open")

  local item_card = get_object("gerudocard")
  if item_card and setting_open then
    if not setting_card then
      item_card.Active = true
    elseif
      not_like_cache("gerudo_fortress_open", setting_open) or not_like_cache("setting_shuffle_card_yes", setting_card)
     then
      item_card.Active = not setting_card
    end
  end
end

function get_first_free_bottle()
  for i = 1, 4 do
    local bottle = get_object("bottle" .. i)
    if bottle and bottle.CurrentStage == 0 then
      return bottle
    end
  end
  return nil
end
local capture_mappings = {
  ["capture_bottle"] = {
    1,
    get_first_free_bottle
  },
  ["capture_ruto"] = {
    2,
    get_first_free_bottle
  }
}
function update_collected_capture()
  for code, data in pairs(capture_mappings) do
    local capture = get_object(code)
    if capture and capture.Active then
      capture.Active = false
      local item = data[2]()
      if item then
        item.CurrentStage = data[1]
      end
    end
  end
end

function update_minimal_bottle()
  local minimal_bottle = get_object("bottleminimal")
  if minimal_bottle then
    if has("ruto") then
      minimal_bottle.CurrentStage = 2
    elseif has("bottle") then
      minimal_bottle.CurrentStage = 1
    else
      minimal_bottle.CurrentStage = 0
    end
  end
end

local vanilla_captures = {
  ["setting_shuffle_sword1_yes"] = {
    ["@KF Kokiri Sword Chest/Dodge Boulder"] = "sword1"
  },
  ["setting_shuffle_ocarinas_yes"] = {
    ["@LW Bridge From Forest/LW Gift from Saria"] = "ocarina",
    ["@HF Ocarina of Time/HF Ocarina of Time Item"] = "ocarina"
  },
  ["setting_shuffle_egg_yes"] = {
    ["@Malon at Castle/HC Malon Egg"] = "capture_childegg"
  },
  ["setting_shuffle_card_yes"] = {
    ["@Carpenter Rescue/Hideout Gerudo Membership Card"] = "gerudocard"
  },
  ["setting_shuffle_beans_yes"] = {
    ["@ZR Magic Bean Salesman/Buy Item"] = "beans"
  }
}
function update_vanilla_captures()
  for setting, captures in pairs(vanilla_captures) do
    local has_setting = has(setting)
    if not_like_cache(setting, has_setting) then
      for location, item in pairs(captures) do
        local location_object = get_object(location)
        local item_object = get_object(item)
        if location_object then
          if item_object and not has_setting then
            location_object.CapturedItem = item_object
          else
            location_object.CapturedItem = nil
          end
        end
      end
    end
  end
end

function update_maps()
  update_gerudo_card()
  update_collected_capture()
  update_minimal_bottle()
  update_vanilla_captures()
end
