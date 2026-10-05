# 02 — Seeds and Crops

**Covers:** 11 seed pouches, 11 plants (4 growth stages each), 11 harvested crops · **Rules from:** `01_Art_Direction.md`

Prices, grow times and Gem rewards are unchanged from `GameConfig`. Only the look is designed here.

---

## 1. Seed pouch (shared design)

Every seed is sold as a **Viking rune pouch**: a small drawstring bag with the crop's picture stamped on the front. The pouch material climbs with rarity, so a player can tell a seed's tier from its icon alone.

| Tier | Pouch material and colour | Tie | Extra detail |
| --- | --- | --- | --- |
| Common | Burlap, tan `#C8AA78` | Plain twine | None |
| Uncommon | Green-dyed linen `#6FAF5A` | Twine | Small leaf stitched on |
| Rare | Blue wool `#4A78C8` | Leather cord | Silver rune stamp |
| Epic | Purple velvet `#7D3CB4` | Gold cord | Glowing rune stamp (Neon) |
| Legendary | Cream leather with gold trim `#F2E6C8` / `#FFBE28` | Gold chain | Gold clasp shaped like a leaf |
| Mythic | Deep red scale-leather `#8C141E` | Dragon-claw clasp | Ember motes |
| Divine | Silver-white silk `#E8F4FF` | Light-beam cord | A tiny star floats above it |

**Build:** pouch = squashed ball + small cylinder neck + torus-like tie (2 thin cylinders). Crop picture = Decal on the front.
**UI icon:** pouch at three-quarter angle on a rarity-coloured round frame; seed count bottom-right.

---

## 2. Growth stages (shared rules)

Each plant has four stages, keyed to growth progress:

| Stage | Progress | What changes |
| --- | --- | --- |
| 1. Sprout | 0–24% | Two tiny leaves in a soil mound |
| 2. Young | 25–59% | The plant's real silhouette appears at half size |
| 3. Mature | 60–99% | Full size, fruit visible but small and dull |
| 4. Ripe | 100% | Fruit full size, colour saturates, tier effect turns on (see Art Direction §4), plant does a little "pop" bounce once |

The current prototype grows one stem and a ball; these designs replace that with per-crop models swapped at each stage.

---

## 3. Crops

### Carrot — Common
- **Concept:** The starter crop. Chunky and cheerful.
- **Seed:** tiny orange-brown specks; pouch picture = carrot.
- **Stages:** 1. two round leaves · 2. feathery 5-leaf tuft · 3. tall tuft, orange shoulder peeks out of the soil · 4. carrot pops half out of the ground, tuft sways.
- **Harvested:** low-poly cone carrot, 1.2 studs, orange `#FF8C1E` with three dark ring grooves, green leafy top `#4CAF50`.
- **Ripe effect:** bounce.

### Wheat — Common
- **Concept:** A Viking staple; a golden sheaf.
- **Seed:** pale grains; pouch picture = wheat ear.
- **Stages:** 1. three blades of grass · 2. green stalk clump · 3. tall stalks, green ears · 4. ears turn gold and droop slightly, sway in the wind.
- **Harvested:** sheaf of 5 stalks tied with twine, gold `#E6C864`, ears `#C9A13E`.
- **Ripe effect:** bounce + slow sway.

### Potato — Uncommon
- **Concept:** Bushy and humble, with a surprise underground.
- **Seed:** small seed potato; pouch picture = potato.
- **Stages:** 1. sprout · 2. bushy leaves · 3. bush with small white-purple flowers `#E6D2FF` · 4. three potato lumps visible at the base, soil cracked around them.
- **Harvested:** lumpy oval potato `#B48C5A` with darker eye spots `#7A5A36`, 1.1 studs.
- **Ripe effect:** bounce + leaf flutter.

### Sweetcorn — Uncommon
- **Concept:** The tallest common crop; good silhouette on the plot.
- **Seed:** yellow kernels; pouch picture = corn cob.
- **Stages:** 1. sprout · 2. single stalk, long leaves · 3. tall stalk with tassel on top · 4. husk peels back to show bright kernels.
- **Harvested:** cob with kernel-pattern decal `#FFDC3C`, half-open husk `#8BC34A`, 1.4 studs.
- **Ripe effect:** bounce + tassel flutter.

### Frostberry — Rare
- **Concept:** A berry bush that grows in the fjord's cold; always lightly frosted.
- **Seed:** pale blue seeds with a white frost speck; pouch picture = berry cluster.
- **Stages:** 1. silver sprout · 2. small round shrub, silver-teal leaves `#5FA8A0` · 3. shrub with pale berries · 4. berries turn ice-blue `#8CD2FF` and glow faintly, white frost tips on leaves.
- **Harvested:** cluster of 5 berries on a twig, 1.0 studs, ice-blue with white highlight.
- **Ripe effect:** soft blue glow ring + a slow cold mist.

### Honeyroot — Rare
- **Concept:** A root that stores sweet amber sap; bees love it.
- **Seed:** amber droplet seed; pouch picture = honeyroot bulb.
- **Stages:** 1. sprout · 2. squat plant, amber-veined leaves · 3. bulb top visible, glowing faintly through the soil · 4. bulb half out, amber drip at its tip.
- **Harvested:** round bulb `#F0AA28` with a shiny Glass "honey" drip, 1.1 studs.
- **Ripe effect:** glow ring + 2 tiny bee motes circling.

### Ember Pepper — Epic
- **Concept:** Grown near dragon nests; the peppers are warm to the touch.
- **Seed:** small seeds that glow orange; pouch picture = flame pepper.
- **Stages:** 1. dark-green sprout · 2. bush · 3. bush with green peppers · 4. peppers turn red-orange `#FF4620`, curled tips shaped like flames, tips Neon.
- **Harvested:** curved pepper with flame-shaped tip, Neon tip `#FFB04A`, 1.2 studs.
- **Ripe effect:** small flame particle at each pepper tip, orange PointLight.

### Moonmelon — Epic
- **Concept:** A melon that drinks moonlight. Glows brighter at night.
- **Seed:** pale lavender seeds; pouch picture = melon with crescent.
- **Stages:** 1. sprout · 2. spreading vine · 3. vine with a small melon · 4. large melon, lavender `#C8C8FF` with crescent-moon stripes `#8C8CDC`.
- **Harvested:** round melon with crescent stripes, 1.6 studs.
- **Ripe effect:** moonlight glow; PointLight brightness doubles when `ClockTime` is night.

### Thunder Squash — Legendary
- **Concept:** Grows only after storms; hums with stored lightning.
- **Seed:** yellow seeds with a zigzag mark; pouch picture = squash with bolt.
- **Stages:** 1. sprout · 2. broad spiky leaves · 3. green squash · 4. bright yellow squash `#FFE600` with dark navy zigzag stripes `#3A3A70`.
- **Harvested:** fat ribbed squash, 1.6 studs, Neon stripes.
- **Ripe effect:** small lightning Beam arcs between the squash and the ground every 2–3 s; rising gold motes.

### Dragonheart Fruit — Mythic
- **Concept:** A fruit said to grow where a dragon once slept. It beats like a heart.
- **Seed:** a dark red seed with a scale pattern; pouch picture = heart fruit.
- **Stages:** 1. thorny sprout on a small rock · 2. twisting dark vine `#3C1E28` · 3. vine with a closed bud · 4. heart-shaped fruit `#C8143C` with a scale texture.
- **Harvested:** heart-shaped fruit, 1.4 studs, scale decal, Neon core visible through a crack.
- **Ripe effect:** fruit pulses (scale 1.00 → 1.08 → 1.00, once per second) with a red aura and embers.

### Starbloom Lotus — Divine
- **Concept:** A lotus that grows on a pool of starlight. The rarest crop.
- **Seed:** a small glowing star; pouch picture = lotus.
- **Stages:** 1. a small glowing pool appears on the tile · 2. lily pads float on it · 3. a closed bud rises · 4. petals open, cyan-white gradient `#78FFFF` → `#FFFFFF`, gold centre `#FFD86B`.
- **Harvested:** open lotus flower floating above a tiny pad, 1.5 studs, Glass petals with Neon edges.
- **Ripe effect:** beam of light upward, constellation particles, slow petal rotation.

---

## 4. Review checklist

| Crop | Seed pouch OK | Stages OK | Harvested look OK | Notes |
| --- | --- | --- | --- | --- |
| Carrot | [ ] | [ ] | [ ] | |
| Wheat | [ ] | [ ] | [ ] | |
| Potato | [ ] | [ ] | [ ] | |
| Sweetcorn | [ ] | [ ] | [ ] | |
| Frostberry | [ ] | [ ] | [ ] | |
| Honeyroot | [ ] | [ ] | [ ] | |
| Ember Pepper | [ ] | [ ] | [ ] | |
| Moonmelon | [ ] | [ ] | [ ] | |
| Thunder Squash | [ ] | [ ] | [ ] | |
| Dragonheart Fruit | [ ] | [ ] | [ ] | |
| Starbloom Lotus | [ ] | [ ] | [ ] | |
