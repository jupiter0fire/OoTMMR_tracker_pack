# Releases

## v1.11.0.2

Added Master Quest dungeons.

Added items only variant.

Fixed the issue where pinned locations don't resize the map in fullscreen.
## v1.11.0.1

Logic updated to version 1.11.0 of the OOTMM Randomizer.

Major new settings:

- Ageless items
- Owl statue shuffle
- MM merchants shuffle
- MM scrub shuffle
- Triforce hunt

Fixed some mislabled checks.

Credits to: @V0rwArd

## v1.9.0.2

The item grid is now scrollable.

Bugfixes for:

- MM Skull checks showing even when token shuffle is disabled
- Vanished Bombers check

## v1.9.0.1

Logic updated to version 1.9.0 of the OOTMM Randomizer.

Major new settings:

- Scrubs shuffle
- Cross game warp songs
- Tingle maps shuffle
- Special conditions for LACS and Majora Child
- Shared items supported and visually linked in the tracker
- Skip unused item stages in the item grid (e.g. MM Short Hookshot) when the respective setting is disabled
## v1.6.1.4

- Add Great Bay Cows
- Fix MM_WALLET item code
## v1.6.1.3

Bugfixes for:

- Fix Snowhead Temple Dungeon boss hosted item
- Add broadcast view to the tracker pack
- Delete unused scarecrow icon for OOT
## v1.6.1.2

Bugfixes for:

- OOT Zora and Goron shops are not displayed when shop sanity is selected
- Increase the maximum amount for Rainbow Bridge and Moon to 266
## v1.6.1.1

This is as close to a complete rewrite of the tracker pack as it's going to get without also changing its looks:

- Auto-generate ~90% of all required logic from OoTMM's logic YAML files
  - This _should_ mean way easier maintenance and less bugs when OoTMM's logic changes
  - This _should_ also mean that the logic is now 100% in sync with OoTMM's logic
- Throw away a whole lot of manually created logic previously present in the JSON files
- Update logic, tricks, settings, (...) to OoTMM v1.6.1 (latest stable soon, hopefully)
- Switch to new versioning scheme tracking OoTMM's version
- Added sequence break as an accessibility level for unselected tricks

Newly supported settings:
- Shop Shuffle (OoT + MM)
- Cow Shuffle (OoT + MM)
- Special Conditions for Rainbow Bridge and Moon

No ER for now, because building an intuitive interface for this in EmoTracker is a bit of a headache. Suggestions welcome!

## v0.1.1

Bug fixes for:

- Ruto's Letter without Zora's Domain access as child isn't considered as a usable bottle
- Fix Termina Field Stump Chest logic
- Add check for Poacher's Saw
- Remove Kak Potion Shop checks
- Fix overlapping Lost Woods locations
- Add check for Prescription
- Switch icons for Goron Elder and Twin Island Hot Water Grotto

## v0.1.0

This version is still based on the logic of version v1.2.0 of the OOTMM-Randomizer. It covers all checks and settings which are relevant for the logic of this version. It's not a perfect fit for the current stable version, but better than not having a map tracker :-).