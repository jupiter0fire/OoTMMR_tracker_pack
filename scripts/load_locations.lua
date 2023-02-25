if HAS_MAP then
  ScriptHost:LoadScript("scripts/logic_helpers.lua")
  ScriptHost:LoadScript("scripts/logic_mm.lua")

  Tracker:AddMaps("maps/maps.json")

  Tracker:AddLocations("locations/overworld.json")
  Tracker:AddLocations("locations/dungeons.json")
end
