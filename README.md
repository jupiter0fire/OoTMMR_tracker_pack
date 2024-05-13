# EmoTracker Pack (map + items) for OoTMM

## Usage

- Install [EmoTracker](https://emotracker.net/download/).
- Download the current tracker pack version from EmoTracker's package manager (cloud symbol) in the "Others" section at the bottom.
- Open EmoTracker and select "OotMM Randomizer" under `"Installed Packages" -> "Others"` in the settings menu.

Green markings indicate that a check is logically reachable. Yellow markings mean that the check is reachable with a trick that is not enabled in the settings. Orange markings indicate that at a location some checks are reachable and others are not.

## Notes

- The events for **OOT Malon**, **OOT Zelda's Letter**, **MM Bomber's Notebook**, **MM Seahorse**, **MM Zora Eggs** and **MM Frogs** are depicted as locations in the tracker pack and must be manually tracked before the checks that depend on these events are shown as reachable (e.g. checks in Pinnacle Rock depending on getting MM Seahorse).

- **Goron Lullaby** is a progressive item if the respective setting (progressive Goron Lullaby) is enabled.

- **MM Hookshot** is a progressive item if the respective setting (MM Short Hookshot) is enabled.

- **MM Ocarina** is a progressive item if the respective setting (MM Fairy Ocarina) is enabled.

- If you play with the setting **shared Ocarinas** but without the **MM Fairy Ocarina**, once you receive the Fairy Ocarina, it will be displayed for Majora's Mask. However, you can only use an Ocarina in Majora's Mask once you have found the Ocarina of Time for both games.

- **Small Key Sanity** is a tracker setting because OOT Fire Temple logic depends on that setting. You still need to track your Small Keys manually even if Small Key Sanity is not activated.

- Having **MM Spin Attack** can be tracked by right clicking on the MM Kokiri Sword.

- If you are playing with **Child Wallets**, right click on the respective wallet. The tracker pack starts with the 99 rupee wallet by default.

- Click on a dungeon name to mark it as a mq dungeon (white letters = regular dungeon, red letters = mq dungeon).

## Unsupported Settings

- Chest Game Small Key Shuffle
- Owl Statue Shuffle
- Pot Shuffle
- Grass Shuffle
- Freestanding Rupees Shuffle
- Freestanding Hearts Shuffle
- Fishing Pond Shuffle
- Entrance Shuffle

## TODOs:

- [ ] Write MEET_ANJU rule for non-ER-cases
- [ ] Add Silver Rupees to the item grid
- [ ] Implemend flags for cleared/uncleared dungeon states

## Credits

Big thanks to [Hamsda](https://github.com/Hamsda/EmoTrackerPacks) and Pink Switch who let me use their OOTR/MMR tracker packs as the base for this tracker pack.
