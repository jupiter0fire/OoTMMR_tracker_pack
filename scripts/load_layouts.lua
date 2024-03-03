if HAS_ER then
    Tracker:AddLayouts("variant_er/layouts/capture_entrance.json")
    Tracker:AddLayouts("variant_er/layouts/options.json")
else
	Tracker:AddLayouts("layouts/options.json")
	end

Tracker:AddLayouts("layouts/item_grids.json")
Tracker:AddLayouts("layouts/layouts.json")
Tracker:AddLayouts("layouts/capture_spawns.json")
Tracker:AddLayouts("layouts/capture_items.json")
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")