# 01 — Art Direction

**Game:** Dragon Isle Farm · **Doc status:** Draft for review · **Date:** 5 Oct 2026

This file sets the rules every other design file follows: the overall look, colours, how rarity shows up visually, how mutations look, and the performance budget. Review this one first; if a rule here changes, the item files change with it.

---

## 1. What the research says

| Finding | What it means for us |
| --- | --- |
| Grow a Garden-style games use a **vibrant, low-poly** look; the popular asset packs for this genre are all low-poly vegetation and plots ([BuiltByBit garden map](https://builtbybit.com/resources/grow-a-garden-style-map.102181/)) | Chunky, flat-shaded shapes, bright saturated colours, no realistic textures |
| Low-poly Roblox environments are tuned for **mobile, where most players are**, and lean on Atmosphere, SunRays and ColorCorrection for a finished look ([BuiltByBit village](https://builtbybit.com/resources/low-poly-medieval-village-roblox.107604/)) | Keep part counts low; get "wow" from lighting and a few particles, not geometry |
| Simulator pet packs ship **several themed variants per pet** (normal, gold, crystal, obsidian) for rarity tiers and shiny versions ([BuiltByBit pet pack](https://builtbybit.com/resources/124-roblox-pets-icons-pack.112028/)) | Our crop mutations (Golden, Frozen, etc.) should be clear **material swaps**; same idea can later give pets shiny variants |
| Roblox devs critique simple pets on details like tail placement, real paw shapes, and pink inner ears ([DevForum](https://devforum.roblox.com/t/simple-simulator-pet/683936)) | Every pet spec below names its paws, ears and tail placement, not just the body |
| Games use a near-universal rarity colour ladder: grey/white, green, blue, purple, then gold/orange at the top ([Giant Bomb](https://giantbomb.com/item-rarity/3015-4702/)) | Our tiers already follow it; Mythic (red) and Divine (cyan/rainbow) extend the top |
| **Shape language:** circles read cute and friendly, squares read sturdy, triangles read dangerous ([21 Draw](https://www.21-draw.com/pl/why-is-shape-language-so-important/)); a strong design is recognisable in silhouette alone ([3dsense](https://3dsense.net/blogs/shape-language-in-character-design-communicating-through-geometry)) | Low-tier pets = round blobs; higher tiers add square strength and *small, rounded* triangles (spikes, horns) for "powerful" without scary. Every pet must pass a black-silhouette test |

---

## 2. Style pillars

1. **Cozy Viking fjord.** Warm wood, stone, woven straw, red-and-cream cloth, carved dragon heads. Late-afternoon golden light.
2. **Chunky and readable.** Big simple shapes, thick proportions, big heads on pets (chibi ratio about 1 : 1.2 head to body). Readable from 30 studs on a phone.
3. **Rarity you can see from across the map.** Higher tier = bigger, brighter, more glow, more motion (section 4).
4. **Original, not borrowed.** We take moods from Norse myth and dragon-rider films, never specific characters (section 7).

---

## 3. Master palette

| Use | Name | Hex |
| --- | --- | --- |
| Wood (light) | Pine plank | `#78502D` |
| Wood (dark) | Tarred beam | `#50341E` |
| Stone | Fjord slate | `#6E6E73` |
| Grass | Meadow | `#609646` |
| Grass (plot) | Farm green | `#50823A` |
| Soil | Tilled earth | `#69462D` |
| Sand | Beach | `#DCC896` |
| Cloth accent | Viking red | `#B41E28` |
| Cloth light | Wool cream | `#F2E6C8` |
| Metal | Iron | `#96969B` |
| Magic accent | Rune cyan | `#3CE6F0` |
| Warm light | Brazier amber | `#FFB04A` |

UI keeps the current dark-wood panels (`#2D2018` background, `#4E3A2A` rows) with FredokaOne text.

---

## 4. Rarity visual language

Every crop, pet and egg shows its tier the same way. Colours match `GameConfig.Rarities`.

| Tier | Colour | Pet size (studs tall) | Materials | Particles | Light | Ripe crop effect | Nameplate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Common | Grey `#AAAAAA` | 1.2–1.6 | SmoothPlastic | None | None | Slight bounce | Grey text |
| Uncommon | Green `#55C85A` | 1.6–1.8 | SmoothPlastic | Small puff on spawn only | None | Bounce + leaf flutter | Green text |
| Rare | Blue `#468CFF` | 2.0–2.2 | Plastic + small Neon details | Faint Sparkles | None | Soft glow ring on the soil | Blue text |
| Epic | Purple `#AA50F0` | 2.4–2.6 | Neon accents, Glass where icy | 3–4 orbiting motes | PointLight, range 6 | Glow ring + motes | Purple text + thin stroke |
| Legendary | Gold `#FFBE28` | 2.8–3.2 | Neon + Glass + Foil trims | Element trail (fire, frost, sparks) | PointLight, range 8 | Rising gold motes + light | Gold text + glow |
| Mythic | Red `#EB3C3C` | 3.2–3.6 | Neon cores, ForceField shimmer | Swirling aura + trail | PointLight, range 10 | Pulsing aura | Red text, slow pulse |
| Divine | Cyan `#3CE6F0` | 4.0 | Glass body with inner Neon | Constellation particles + light beam | PointLight, range 12 | Beam of light upward | **Animated rainbow gradient** |

Rules:

- A pet never gets particles from a higher tier than its own.
- Glow colour = the item's own element colour; the **nameplate** carries the tier colour.
- Hybrids (breed-only pets) get a small rune sigil floating behind the head, so players can spot them.

---

## 5. Crop mutation visuals

A mutation is a **material and effect swap on the harvested crop and on the ripe plant's fruit**. One mutation shows at a time (the highest value wins, as coded).

| Mutation | Multiplier | Look | Effects |
| --- | --- | --- | --- |
| Golden | x20 Ru, x2 Gems | Whole crop becomes `Foil` material, `#FFD700` | Gold Sparkles, short "ding" sound |
| Scorched | x3 | Charred base `#2B1B12` with glowing orange Neon cracks `#FF5A14` | Thin smoke + 2–3 embers |
| Frozen | x4 | Crop sits inside a translucent ice cube (`Glass`, `#AEE6FF`, 0.4 transparency) | Slow frost flakes |
| Shocked | x5 | Pale yellow tint `#FFFF78`, dark zigzag decal | Small Beam arc every 2 s, flickering light |
| Celestial | x10 | Neon violet `#C88CFF` with star decal | Star particles, floats and bobs 0.5 studs |

Optional idea (needs code): random **size variants** at harvest (0.85x to 1.25x) with value scaling, like Grow a Garden's big fruit.

---

## 6. Technical budget (mobile-first)

| Item | Max parts | Max triangles (if MeshPart) | Max ParticleEmitters | Notes |
| --- | --- | --- | --- | --- |
| Seed pouch (world drop / icon) | 4 | 300 | 0 | Icons are rendered to images for UI |
| Crop plant, per growth stage | 8 | 800 | 1 (Epic+) | 6 plots x 12 tiles = 72 plants on a full server |
| Harvested crop | 4 | 400 | 1 (mutated only) | |
| Pet | 15 | 2,000 | 1 below Legendary, 2 at Legendary+ | Up to 5 pets x 6 players = 30 pets |
| Egg | 5 | 600 | 1 | |
| Cosmetic | 25 | 3,000 | 1 | One per plot each |

**Build approach (recommended):**

1. **Now:** build everything from Roblox parts (balls, wedges, cylinders) so we can iterate fast and test the look.
2. **Later:** replace Epic-and-up pets and the hero crops with MeshParts modelled in Blender, keeping the same silhouettes and colours from these files.

---

## 7. Originality guardrails

The world is *inspired by* dragon-rider films and Norse myth. To keep it ours:

- No sleek all-black dragon with huge green eyes and ear flaps, and no dragon with a single prosthetic tail fin. Those read as one specific film character.
- No film names, places, logos, or character outfits. Our names stay as in `GameConfig`.
- Mythological creatures (unicorn, phoenix, hydra, kitsune, gryphon, leviathan, wyvern) are public folklore; our versions must still have our own palette and signature details.
- Real Norse runes are fine as decoration. Use the Elder Futhark letters, for example ᚱ (Raidō) on the Ru coin.
