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

- For best results use keysanity options to see the new checks and items added with the newest updates.
  
## Unsupported Settings

- Dungeon Reward Shuffle Anywhere - In Testing
- Boss Entrance Shuffle - In testing
- Dungeon Entrance Shuffle - In Testing

## TODOs:

- [ ] Delete unused lua/json parts
- [X] Add new items within tracker on MM side
- [X] Add new items within tracker on OOT side
- [X] Add Ocarina Buttons within tracker on both sides
- [X] Update OoT Logic for Stone Mask 
- [X] Update OoT Logic for Blast Mask
- [X] Add Fairy Fountain Shuffle Checks to map
- [X] Add OoT Grass Shuffle Checks to Map
- [X] Update Dungeon Checks (grass shuffle etc)
- [X] Add Coins, Add Skeleton Keys, Add Bottomless Wallet
- [X] Add Logic for Coins, Skeleton Keys, and Bottomless Wallet
- [X] Move half of Owl Statues to new row and increase text size so it is readable
- [X] MM keys/text could do with a size upgrade to make it readable
- [X] Fix Keysanity Key locations
- [X] Add Elegy of Emptiness to OoT
- [X] Add logic to grass and fairy fountain checks
- [X] Update MM Logic for Silver & Golden Scales
- [X] Update MM Logic for various Strength upgrades
- [X] Update MM Logic for various tunics
- [X] Update OoT Logic for Ocarina Buttons
- [ ] Update OoT Logic for Elegy of Emptiness
- [ ] Update OoT Logic for OoT Enemy Souls
- [ ] Update OoT Logic for OoT Boss Souls
- [ ] Update OoT Logic for Quick age swap option
- [ ] Update OoT Logic for Hookshoot anywhere option
- [ ] Update OoT Logic for Climb most surfaces option
- [ ] Update MM Logic for various boots
- [ ] Update MM Logic for Clocks As Items option
- [ ] Update MM Logic for Ocarina Buttons option
- [ ] Update MM Logic for Open Dungeon option
- [ ] Update MM Logic for Hookshoot Anywhere option
- [ ] Update OoT Logic for Climb Most Surfaces option
- [ ] Update MM Logic for MM Enemy Souls
- [ ] Update MM Logic for MM Boss Souls
- [ ] Update Shared options
- [ ] Update possible tricks for OoT
- [ ] Update possible tricks for MM
- [ ] Fix broadcast view item locations - mostly done - needs testing
- [ ] Update/add Entrance randomization options - In Progress
- [ ] Update MM Logic for Fierce Deity Anywhere option - not in OOTMM yet
- [ ] Update MM Logic for NPC Souls (EXPERIMENTAL, not a priority for now)
- [ ] Add new checks to the map (grass patches - OoT done - MM almost done, fairy Fountains - done, fishing shuffle - done, Big Fairy shuffle - done, freestanding hearts - done, beehives, snowballs, crates, freestanding rupees, (not all released by ootmm yet "wonder rupees" fall into this category), silver rupees, pots, bottle content)

## Credits

- Big thanks to [Hamsda](https://github.com/Hamsda/EmoTrackerPacks) and Pink Switch who let me use their OOTR/MMR tracker packs as the base for this tracker pack.
- JupiterFire anmd Wbsch for creating the OOTMM Tracker Map and all original work
- [That's Gotta Be Kane!](https://discord.com/users/843301460589936660)(https://github.com/ThatsGottaBeKane) - Shuffles, logic and misc updates
- PouhPouhh - Entrance Randomizer and misc updates
