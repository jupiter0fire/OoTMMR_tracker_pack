Tracker:AddMaps("maps/maps.json")


if HAS_ER then
    Tracker:AddLocations("variant_er/locations/exits_entrance.json")
	Tracker:AddLocations("variant_er/locations/oot_dungeons.json")
	Tracker:AddLocations("variant_er/locations/mm_dungeons.json")
else
	Tracker:AddLocations("locations/oot_dungeons.json")
	Tracker:AddLocations("locations/mm_dungeons.json")
end
Tracker:AddLocations("locations/overworld.json")