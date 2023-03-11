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

function update_maps()
  update_collected_capture()
  update_minimal_bottle()
end
