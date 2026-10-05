# 06 — World, NPCs and UI

**Covers:** the two shop NPCs, shop buildings, farm plots, Breeding Nest, village and island, lighting, currency icons and UI · **Rules from:** `01_Art_Direction.md`

---

## 1. NPCs

### Trader Brann — NPC Market (Ru)
- **Role:** Friendly merchant who buys your harvest and sells basic seeds and Hatchling Eggs.
- **Look:** stocky and broad (square shape = reliable). Big red braided beard `#B4501E` with two bronze beads, leather apron `#78502D` covered in seed pouches, green wool tunic `#5A6E3C`, rolled sleeves, a bronze Ru coin purse on his belt.
- **Hat:** round fur cap, not a horned helmet (horned helmets are a myth, and this makes him look more like a merchant).
- **Idle:** weighs produce on a hanging scale; waves when a player gets close.
- **Lines (speech bubble):** "Fresh from the fields? I'll pay fair Ru!" · "Carrots again? Ha! Bring me something golden."

### Runekeeper Sigrid — Gem Store (Gems)
- **Role:** Mystic who sells rare seeds, eggs and enchanted gear for Gems.
- **Look:** tall and slim (elegant, magical). Hooded blue-violet robe `#463C82` with silver rune embroidery, long silver braids `#DCDCE6`, staff topped with a floating cyan crystal `#3CE6F0`, three small crystals orbiting her.
- **Idle:** taps her staff; the crystals swirl faster when a player opens the store.
- **Lines:** "The runes favour the patient farmer." · "A Dragon Egg... are you ready for what hatches?"

---

## 2. Shop buildings

| Building | Shape | Materials and colours | Signature details |
| --- | --- | --- | --- |
| NPC Market stall | Open timber stall, 14 x 10 studs | Pine plank `#78502D`, red-and-cream striped awning `#B41E28` / `#F2E6C8` | Crates showing produce, hanging scale, carved dragon heads on the corner posts, chalkboard with today's prices |
| Gem Store | Small round stone hut with a turf roof | Slate `#6E6E73`, turf `#609646`, purple banners `#7D3CB4` | Big glowing crystal on the roof, rune-carved stone arch over the door, egg pedestals out front |

---

## 3. Farm plot

| Part | Design |
| --- | --- |
| Fence | Split-rail wood `#50341E`; the two gate posts are carved dragon heads facing out |
| Owner sign | Rune stone (grey slate) with the player's name carved in and glowing faintly cyan |
| Soil tiles | Raised beds with a wooden edge (one stud), tilled soil `#69462D` with furrow lines; edge glows in the selected seed's tier colour when you stand near it |
| Breeding Nest | Giant woven twig nest `#8C6A3C` lined with straw `#D8BE78` and a few big feathers, with a lantern on a hook; glows when an egg is ready |
| Free space | Grass with a small path of stepping stones from the gate to the beds |
| Cosmetic spots | BannerSpot by the gate, StatueSpot near the nest (as in the prototype) |

---

## 4. Village and island

- **Village square:** cobblestone circle with a central **Dragon Well** (a stone well with a carved dragon curled around it) as the meeting point. Spawn stays here.
- **Longhouses:** turf-roofed longhouses with dragon-head carvings at both ends of the roof ridge, round shields on the walls.
- **Watchtower:** keep the tower with the brazier; add a flag in Viking red.
- **Docks:** a wooden pier on the beach with two small boats (striped sails), as a future spot for a fishing feature or event boats.
- **Edges:** low cliffs and pine forest so the island feels sheltered; sea all around.
- **Trading plaza (future):** benches and market tables near the square where players meet to trade.

---

## 5. Lighting preset

| Setting | Value |
| --- | --- |
| ClockTime | 15.5 (golden afternoon); later a slow day/night cycle |
| Atmosphere | Density 0.3, Haze 1.5, Color `#C8D7E6` |
| SunRays | Intensity 0.08, Spread 0.6 |
| ColorCorrection | Saturation 0.15, Contrast 0.05, TintColor `#FFF4E6` |
| Bloom | Intensity 0.6, Size 24, Threshold 1.6 (makes Neon glows pop) |

---

## 6. Currency icons and UI

| Element | Design |
| --- | --- |
| **Ru** icon | Bronze coin `#C8823C` with the rune ᚱ (Raidō, an "R" sound, matching "Ru") stamped in the centre |
| **Gems** icon | Faceted cyan gem `#3CE6F0` with a small rune spark |
| HUD pills | Keep current dark-wood pills; add the icons to the left of each number |
| Panels | Keep the dark-wood panels; add a thin carved-wood border image and a small dragon-head corner ornament |
| Rarity tags | Keep the coloured [Tier] text; Divine gets an animated rainbow UIGradient |
| Item icons | 3/4 view renders of each item on a round frame in its tier colour; used in hotbar, inventory, shops and trade |
| Buttons | Rounded, coloured by action: green = buy/confirm, red = sell/cancel, purple = hatch, cyan = Gem purchases |

---

## 7. Review checklist

| Item | Look OK | Notes |
| --- | --- | --- |
| Trader Brann | [ ] | |
| Runekeeper Sigrid | [ ] | |
| NPC Market stall | [ ] | |
| Gem Store building | [ ] | |
| Farm plot (fence, sign, beds) | [ ] | |
| Breeding Nest | [ ] | |
| Village and island | [ ] | |
| Lighting preset | [ ] | |
| Ru and Gems icons | [ ] | |
| UI panels and icons | [ ] | |
