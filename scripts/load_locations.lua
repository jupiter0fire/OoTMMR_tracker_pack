Tracker:AddMaps("maps/maps.json")

Tracker:AddLocations("locations/overworld.json")
Tracker:AddLocations("locations/mm_dungeons.json")
Tracker:AddLocations("locations/oot_dungeons.json")
if HAS_ER then
    Tracker:AddLocations("variant_er/locations/exits_entrance.json")
end