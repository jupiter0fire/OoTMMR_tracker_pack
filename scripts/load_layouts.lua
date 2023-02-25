if HAS_KEYS then
  Tracker:AddLayouts("layouts/dungeon_grids_keysanity.json")
else
  Tracker:AddLayouts("layouts/dungeon_grids.json")
end
Tracker:AddLayouts("layouts/item_grids.json")
if HAS_MAP then
  Tracker:AddLayouts("layouts/options.json")
  Tracker:AddLayouts("layouts/layouts.json")
  Tracker:AddLayouts("layouts/capture_spawns.json")
  Tracker:AddLayouts("layouts/capture_items.json")
end
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")
