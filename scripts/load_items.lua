
Tracker:AddItems("items/capture_spawns.json")
Tracker:AddItems("items/sequences.json")
Tracker:AddItems("items/capture_items.json")
if HAS_ER then
  Tracker:AddItems("items/capture_entrance.json")
end
Tracker:AddItems("items/tricks.json")
Tracker:AddItems("items/options.json")

Tracker:AddItems("items/quest.json")
Tracker:AddItems("items/mm_items.json")
Tracker:AddItems("items/equipment.json")
Tracker:AddItems("items/items.json")
Tracker:AddItems("items/dungeons.json")

--CUSTOM ITEMS
ScriptHost:LoadScript("scripts/sdk/class.lua")
ScriptHost:LoadScript("scripts/sdk/custom_item.lua")

ScriptHost:LoadScript("scripts/custom_prog_badge.lua")

ScriptHost:LoadScript("scripts/custom_dungeon_reward.lua")
for i = 1, 13 do
  DungeonReward(i)
end

ScriptHost:LoadScript("scripts/custom_presets.lua")
PresetLoader()
