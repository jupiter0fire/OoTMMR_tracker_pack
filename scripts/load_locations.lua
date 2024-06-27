Tracker:AddMaps("maps/maps.json")

Tracker:AddLocations("locations/oot_overworld.json")
Tracker:AddLocations("locations/mm_overworld.json")
Tracker:AddLocations("locations/mm_dungeons.json")
Tracker:AddLocations("locations/oot_dungeons.json")
if HAS_ER then
    Tracker:AddLayouts("layouts/item_grids_er.json")
    Tracker:AddLocations("locations/exits_entrance.json")
end