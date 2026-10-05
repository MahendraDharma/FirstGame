# Dragon Isle Farm — project brief for Claude Code

A Roblox farming + mythic-pet game inspired by Grow a Garden (farming loop) and Growtopia (player trading),
set on a cozy Viking island. All names, creatures and art are original (no film IP).

## Where the game lives

**The Roblox place is the source of truth**: "Untitled Experience" (placeId 91025778867984).
Work on it through the Roblox Studio MCP tools. This folder holds the design docs, a copy of the model
code, and an offline test. If `models/*.lua` and Studio disagree, Studio wins; copy Studio's version here.

| What | Studio path |
| --- | --- |
| All tunable data: rarities, crops, pets, eggs, recipes, Gem Store | `ReplicatedStorage.Shared.GameConfig` |
| Model builders (crops, pets, eggs, items) | `ReplicatedStorage.Shared.Models.{ModelKit, CropModels, PetModels, ItemModels}` |
| Save/load (DataStore, never overwrites a failed load) | `ServerScriptService.DataService` |
| All server logic: farming, market, Gem Store, eggs, pets, breeding, trading | `ServerScriptService.GameServer` |
| All UI: HUD, hotbar, Inventory, Pets, Market, Gem Store, Nest, Trade | `StarterPlayer.StarterPlayerScripts.ClientUI` |
| Idle animations: pets, eggs, crops (client-only, copy in `scripts/IdleAnimations.lua`) | `StarterPlayer.StarterPlayerScripts.IdleAnimations` |
| Map: village, 2 shops, 6 plots (12 tiles + nest each), egg displays | `Workspace.Village`, `Workspace.Plots` |
| Review gallery of every model (delete before publishing) | `Workspace.Showcase` |

## Game rules (keep these true)

- Two currencies: **Ru** (NPC Market, tradeable) and **Gems** (earned by harvesting and breeding, by rarity;
  spent only in the Gem Store; never tradeable).
- 7 rarity tiers: Common, Uncommon, Rare, Epic, Legendary, Mythic, Divine. Colours in `GameConfig.Rarities`.
- Everything is validated on the server. Trades re-check both inventories and swap atomically.
- Holding and dropping: one held item (seed, crop, egg or unequipped pet) shows in the right hand as a Tool
  named `HeldItem` (the default Backpack bar is hidden). Dropped items go to `Workspace.Drops` with an F "Pick up"
  prompt; anyone can take them after 5 s. Untaken drops return to the owner after 5 min, when they leave, or
  on shutdown, so items are never lost. Tunables are at the top of "held items & drops" in GameServer.
- Egg odds are always shown before purchase (Roblox requires this if Gems become buyable with Robux).
- No gambling features, no real-money trading.
- Originality: no sleek black dragon with big green eyes / ear flaps / prosthetic tail fin, no film names.

## Design docs (`design/`)

`00_README` → `01_Art_Direction` (style, palette, rarity visuals, mutation looks, budget) → `02_Seeds_and_Crops`,
`03_Pets`, `04_Eggs_and_Hatching`, `05_Gem_Store_Items`, `06_World_NPCs_and_UI`.
The game design doc (economy, breeding, trading) is a Claude Doc:
https://claude.ai/code/artifact/2b758d44-e5e3-4e0b-8ddb-1c23527bbb84

## Model code conventions

- Models are built from parts in code, authored around the origin, front faces **-Z**.
- Ellipsoids use a Block part + `SpecialMesh` (Sphere), so avoid `Model:ScaleTo`; use `Kit:scale`,
  `Kit:fitHeight` or `Kit:fitMax` before `Kit:finish`.
- `Kit:finish(true)` anchors everything (crops, props, showcase); `finish(false)` welds to `Root` (following pets).
- Pets set attributes `Rarity`, `Flying`, `Height`, `BottomOffset`; GameServer uses them to place pets.
- Plants are built at 1x and scaled by `PLANT_SCALE = 1.6` in GameServer for the 8-stud tiles.
- When running builders from Studio's Edit mode, `require` caches modules. Clone `ReplicatedStorage.Shared`
  into ServerStorage, require the clone, then destroy it.

## Testing

- Offline: `tools/model-test/build.sh` builds all 105 models against a mock Roblox API and reports part counts
  (needs the Luau CLI from https://github.com/luau-lang/luau/releases).
- In Studio (Studio only, disabled on live servers): `Request:InvokeServer("DevGrant")` for +100k Ru / +10k Gems,
  `"DevGrantAll"` for one of everything (seeds, every crop + mutation, eggs, one pet per species, Gem Store
  items, max slots, a ripe plant of each crop on empty tiles), `"DevTile", i` to plant/harvest tile i,
  `"DevFinishTimers"` to finish growth and breeding. The side menu has buttons for DevGrant, DevGrantAll
  ("All items") and DevFinishTimers ("Grow all");
  `PlayerGui.MainUI.DevOpenPanel:Fire("Market" | "GemStore" | "Inventory" | "Pets" | "Breed" | "Trade")`.
- DataStore errors in Studio are expected until Game Settings > Security > "Enable Studio Access to API Services" is on.
- Trading has not been tested with two players yet (Test tab > Clients and Servers > 2 players).

## Status and next steps

Done: core loop, both currencies, NPC Market, Gem Store, eggs, 18 pets, breeding with 5 secret recipes,
trading, mutations, all 105 item models wired into the game, idle animations for pets, eggs and crops
(hover, wing flap, tail swish, leg walk cycle, ear twitch, per-pet signature moves from `03_Pets.md`;
egg and nest motion; crop sway, ripe bounce/pop, flutter, bees, petals, lightning, Dragonheart pulse).

Idle animation notes: models are found by attribute (`Pet`, `Egg`, `Crop`+`Stage`, nest `Shell`+`Rarity`)
under `ActivePets`, `Plots`, `Village.EggDisplays`, `Showcase`. Parts are grouped by name: `*Wing*`, `*Tail*`,
legs (`*Leg*`/`*Foot*`/`*Paw*`/`*Hoof*`, ground pets only), `Ear*`, Hydra neck+head by nearest `Head`.
Per-pet speeds, gaits and signature moves are in the `PETS` table. The walk cycle follows the pet root's
velocity. On following pets the client swaps moving parts' `WeldConstraint` for a local `Weld`; your own
pets bob, hop and flip through `AlignPosition.Attachment0`. Particles, hoofprints, beams are client-only.
Renaming model parts in the builders can silently turn these animations off.

Next, in rough order:
1. Hatch reveal sequence (`04_Eggs_and_Hatching.md` section 3).
2. NPC, shop building, plot and village redesigns plus the lighting preset (`06_World_NPCs_and_UI.md`).
3. Item icons for the UI (ViewportFrames of the models).
4. Weather events that apply mutations server-wide; weekly update cadence.
5. Economy sinks and anti-macro limits (lessons from Growtopia's decline).
6. Two-player test: trading, how another player's pets animate, picking up someone else's drop (5 s owner
   window), drops returning when the owner leaves; enable DataStore access and test saving.

Known: part counts are above the budget table in `01_Art_Direction.md` (pets 17–64 parts);
a stray "Hello world!" script exists in the place (not part of the game).
