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

function update_maps()
  update_collected_capture()
end

function hintable()
  if has("gossip_stone") then
    return AccessibilityLevel.Normal
  else  
    return AccessibilityLevel.None
  end
end
