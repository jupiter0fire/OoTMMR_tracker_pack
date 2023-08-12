local OOTMM_LOCATION_CHEST_LINKS = {
    tingle_swamp = {
        "@Clock Town Tingle Maps/Map: Swamp",
        "@Swamp Tingle Maps/Map: Swamp",
    },
}
local OOTMM_LOCATION_CHEST_LINKS_PREV = {}
function on_update_location_chest_link()
    for group, locations in pairs(OOTMM_LOCATION_CHEST_LINKS) do
        local location_cache = {}
        for _, location_name in ipairs(locations) do
            local location = Tracker:FindObjectForCode(location_name)
            if not location then
                print("WARNING: location link '" .. location_name .. "' not found")
            else
                location_cache[location_name] = location
            end
        end

        -- If _PREV is set and one of the locations differs, set all others to this new value
        if OOTMM_LOCATION_CHEST_LINKS_PREV[group] then
            for _, location in pairs(location_cache) do
                if location.AvailableChestCount ~= OOTMM_LOCATION_CHEST_LINKS_PREV[group] then
                    for _, other_location in pairs(location_cache) do
                        other_location.AvailableChestCount = location.AvailableChestCount
                    end
                    break
                end
            end
        end

        OOTMM_LOCATION_CHEST_LINKS_PREV[group] = location_cache[locations[1]].AvailableChestCount
    end
end
