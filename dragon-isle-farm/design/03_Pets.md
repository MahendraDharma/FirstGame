# 03 — Pets

**Covers:** all 18 pets (13 from eggs, 5 breed-only hybrids) · **Rules from:** `01_Art_Direction.md`

Bonuses and rarities are unchanged from `GameConfig`. Each pet is described with the same fields so you can compare them side by side.

---

## 1. Shared pet rules

- **Chibi proportions:** big head, short body, short legs. Eyes are large black ovals with one white highlight; no realistic eyes.
- **Shape language by tier:** Common and Uncommon are round and soft. Rare adds gentle curves and flowing parts (manes, wings). Epic and up add square strength (chunky chests, plates) and **small rounded** spikes and horns. No pet looks scary.
- **Silhouette test:** each pet must be recognisable as a solid black shape. The "Signature" line in each spec is the part that makes the silhouette unique.
- **Follow behaviour:** pets float or hop beside the player (current system). Flying pets hover 1.5–2.5 studs up; ground pets hop at foot level.
- **Hybrids:** body plan of the first parent + the signature feature of the second, in a new palette, plus a small floating rune sigil behind the head.

**Quick view**

| Pet | Tier | Source | Height (studs) | Ground or flying | Signature |
| --- | --- | --- | --- | --- | --- |
| Imp | Common | Hatchling Egg | 1.3 | Flying | Spade-tipped tail, tiny bat wings |
| Fairy Sprite | Common | Hatchling Egg | 1.2 | Flying | Four dragonfly wings, petal skirt |
| Jackalope | Uncommon | Hatchling / Mystic | 1.6 | Ground (hops) | Antlers on a bunny |
| Kitsune Kit | Uncommon | Hatchling / Mystic | 1.6 | Ground | One huge white-tipped tail, fox-fire wisp |
| Gryphon Chick | Rare | All eggs | 2.0 | Ground (waddles) | Eagle head, lion tail tuft |
| Unicorn | Rare | All eggs | 2.2 | Ground (prances) | Spiral horn, pastel mane |
| Pegasus Foal | Rare | All eggs | 2.2 | Flying | Oversized feathered wings |
| Sky Kitsune | Rare | Breed only | 2.0 | Flying | Three cloud tails, feather ears |
| Fire Drake | Epic | Mystic / Dragon | 2.6 | Ground (stomps) | Four legs, flame-tip tail |
| Frost Wyvern | Epic | Mystic / Dragon | 2.6 | Flying | Wing-arms, ice-crystal spine |
| Thunder Dragon | Legendary | Mystic / Dragon | 3.2 (long) | Flying | Long serpent body, antlers |
| Phoenix | Legendary | Mystic / Dragon | 3.0 | Flying | Three-plume flame crest, long tail |
| Emberhorn | Legendary | Breed only | 2.8 | Ground | Flame mane, obsidian horn |
| Glacier Pegasus | Legendary | Breed only | 2.8 | Flying | Crystal ice wings |
| Hydra | Mythic | Dragon Egg | 3.4 | Ground | Three heads with three moods |
| Leviathan | Mythic | Dragon Egg | 3.6 | Flying (swims in air) | Coils around a floating water orb |
| Stormfire Dragon | Mythic | Breed only | 3.6 (long) | Flying | Serpent body with phoenix flame wings |
| Aether Dragon | Divine | Breed only | 4.0 | Flying | See-through star body, rune halo |

---

## 2. Common

### Imp
- **Myth:** Small mischievous spirits from European folklore. Pranksters, not villains.
- **Personality / shape:** Cheeky troublemaker. Round body, round head, two small cone horns.
- **Palette:** brick red `#B4463C`, belly peach `#E89A7A`, horns cream `#F2E6C8`, wings dark red `#7A2A24`.
- **Build:** ball body, ball head, 2 small cone horns, 2 bat-wing wedges, thin tail with a spade tip, wide grin decal.
- **Signature:** spade-tipped tail curling up behind it.
- **Idle:** bobs and flaps fast; every ~8 s does a little backflip.
- **Avoid:** fangs, pitchfork, or anything devil-scary.

### Fairy Sprite
- **Myth:** Light-elves and sprites of Norse and Celtic folklore.
- **Personality / shape:** Gentle and floaty. Teardrop body, round head.
- **Palette:** glow pink `#FFAAE6`, wings Glass `#E8F6FF`, leaf hat `#6FAF5A`, petal skirt `#FFD6F0`.
- **Build:** teardrop body, ball head, 4 thin Glass wing plates, 5-petal skirt, leaf cap.
- **Signature:** four transparent dragonfly wings.
- **Idle:** floats in a slow figure-8; a few pollen sparkles fall (its identity, even at Common).

---

## 3. Uncommon

### Jackalope
- **Myth:** The antlered rabbit of North American folk tales.
- **Personality / shape:** Bouncy and proud. Round bunny body.
- **Palette:** fur tan `#AA825A`, belly cream `#F2E2C4`, antlers `#D9C3A0`, inner ears pink `#F2A6B4`.
- **Build:** ball body, ball head, 2 long ears (pink inside), small branching antlers (3 cylinders each), big flat back feet, cotton tail.
- **Signature:** antlers sticking up between bunny ears.
- **Idle:** hops after the player; ears twitch; occasionally stops and thumps a foot.

### Kitsune Kit
- **Myth:** Japanese fox spirits that grow more tails as they gain power, and carry fox-fire (kitsunebi).
- **Personality / shape:** Curious and clever. Round head, slim body, one big tail.
- **Palette:** orange `#FF9640`, white chest and tail tip `#FFF6EC`, red forehead mark `#D23C3C`, fox-fire `#7FD4FF`.
- **Build:** ball head with 2 tall triangle ears (pink inside), small body, one oversized fluffy tail (3 stacked balls), tiny floating blue flame.
- **Signature:** a tail bigger than its body, with a white tip.
- **Idle:** trots beside the player; tail swishes; fox-fire wisp circles its head.

---

## 4. Rare

### Gryphon Chick
- **Myth:** The lion-eagle gryphon of Greek and medieval legend, as a baby.
- **Personality / shape:** Fluffy and clumsy. Very round.
- **Palette:** feathered head cream `#F0E2B8`, beak gold `#E8A33C`, lion back half tan `#DCBE78`, tail tuft `#A0784A`.
- **Build:** round fluffy chest, feathered ball head with a tuft, short hooked beak, stubby wings, lion hind legs with paws, thin tail ending in a tuft.
- **Signature:** eagle front, lion back, readable from the side.
- **Idle:** waddles; flaps stubby wings and fails to take off; tiny Sparkles.

### Unicorn
- **Myth:** The horned horse of European legend, symbol of purity.
- **Personality / shape:** Graceful and sweet. Soft curves.
- **Palette:** white coat `#FFFFFF`, mane gradient pink `#FFB3DE` to lavender `#C3A6FF`, horn gold `#FFD86B` with Neon tip, hooves gold.
- **Build:** chibi pony body, ball head, flowing mane (3 curved wedges), spiral horn (stacked cones), gold hooves, flowing tail.
- **Signature:** spiral horn and pastel mane.
- **Idle:** prances; a small rainbow sparkle where each hoof lands.

### Pegasus Foal
- **Myth:** The winged horse of Greek myth, as a foal.
- **Personality / shape:** Eager and light.
- **Palette:** coat pale blue-white `#E6F0FF`, wings white `#FFFFFF` with blue tips `#9CC8FF`, mane `#BCD8FF`.
- **Build:** foal body, ball head, wings bigger than the body (layered feather wedges), small cloud puffs under the hooves.
- **Signature:** oversized feathered wings.
- **Idle:** flies with slow wing beats; little cloud puff every few seconds.

### Sky Kitsune (breed only: Kitsune Kit x Gryphon Chick)
- **Hybrid rule:** Kitsune body + Gryphon's feathers.
- **Palette:** sky blue `#78C8FF`, white cloud tails `#F4FAFF`, feather ears `#E0EEFF`.
- **Build:** kitsune body, **three** cloud-puff tails, ears ending in small feather tufts, little feathered wings, rune sigil behind the head.
- **Signature:** three cloud tails.
- **Idle:** glides on the wind; tails leave short cloud wisps.

---

## 5. Epic

### Fire Drake
- **Myth:** In folklore, a "drake" is a four-legged dragon.
- **Personality / shape:** Sturdy little furnace. Square chest, round snout, small rounded spikes.
- **Palette:** crimson `#DC3C14`, belly plates amber `#FFB04A`, spikes dark red `#8C2810`, flame Neon `#FFB04A`.
- **Build:** chunky four-legged body, round snout, belly plates, row of rounded back spikes, small leathery wings, thick tail with a flame tip.
- **Signature:** four legs plus a flame on the tail tip.
- **Idle:** stomps along; puffs smoke rings; sneezes sparks every ~6 s. 3–4 ember motes, warm PointLight.

### Frost Wyvern
- **Myth:** In heraldry, a wyvern is a two-legged dragon whose wings are its arms.
- **Personality / shape:** Sleek and cool. Long neck, arrow-head shape kept soft.
- **Palette:** ice blue `#96DCFF`, frost crest white `#FFFFFF`, ice crystals Glass `#CFF2FF`.
- **Build:** slim body, two hind legs, wing-arms, long neck, crest on the head, a line of Glass ice crystals down the spine, tail ending in a crystal.
- **Signature:** wing-arms and an ice-crystal spine.
- **Idle:** glides in slow circles; light snowflake trail; cold blue PointLight.

---

## 6. Legendary

### Thunder Dragon
- **Myth:** Storm dragons of Asian legend and the thunder spirits of many cultures.
- **Personality / shape:** Majestic and wise. Long S-curve body.
- **Palette:** storm grey `#4A4E6E`, lightning stripes `#FFE14A` Neon, belly `#9AA0C8`, whiskers `#FFF2A0`.
- **Build:** long serpent body in 6–8 segments, four small legs with storm-cloud puffs under the feet, deer-like antlers, long whiskers, a crackling Neon mane.
- **Signature:** long serpent body with antlers.
- **Idle:** swims through the air in an S-curve; small lightning arcs every 3 s; spark trail.
- **Avoid:** making it black or sleek (see Art Direction §7).

### Phoenix
- **Myth:** The firebird that is reborn from its own ashes.
- **Personality / shape:** Proud and radiant.
- **Palette:** body orange `#FF7800`, wings gradient to gold `#FFC832`, tail feathers Neon `#FFE08A`, crest red `#FF3C1E`.
- **Build:** round bird body, curved beak, wide flame-shaped wings, three long tail feathers, crest of three flame plumes.
- **Signature:** three-plume crest and long tail feathers.
- **Idle:** hovers; every 10 s flares its wings in a burst of embers. Fire trail.
- **Hatch moment:** appears from a small burst of ash and fire.

### Emberhorn (breed only: Fire Drake x Unicorn)
- **Hybrid rule:** Unicorn body + Fire Drake's scales and flame.
- **Palette:** rose coat `#FF5078`, ember scales on the legs `#FF8C3C`, flame mane Neon `#FFB04A`, obsidian horn `#2A1A22` with a molten core.
- **Build:** unicorn body, scale patches on legs, mane and tail made of flame wedges, dark horn with Neon cracks, rune sigil.
- **Signature:** flame mane plus a dark molten horn.
- **Idle:** prances; leaves small fire hoofprints that fade.

### Glacier Pegasus (breed only: Frost Wyvern x Pegasus Foal)
- **Hybrid rule:** Pegasus body + Frost Wyvern's ice crystals.
- **Palette:** frost blue `#B4F0FF`, wings Glass `#DFF8FF`, mane white `#FFFFFF`, icicle hooves `#9ADCF2`.
- **Build:** pegasus body, wings made of Glass crystal feathers, frosty mane, icicle hooves, rune sigil.
- **Signature:** crystal ice wings.
- **Idle:** flies; wing beats scatter snowflakes.

---

## 7. Mythic

### Hydra
- **Myth:** The many-headed serpent of Greek legend that grew back its heads.
- **Personality / shape:** Funny and chaotic. Plump body, three heads that disagree.
- **Palette:** green `#288C50`, belly `#A8D88A`, fins `#1E6E3C`, eyes gold `#FFD86B`.
- **Build:** plump four-legged body, three necks and heads, small fins on each head, short tail.
- **Signature:** three heads with three moods: sleepy, happy, grumpy (different eye decals).
- **Idle:** heads bob out of sync; now and then two heads bonk each other. Swirling green aura.

### Leviathan
- **Myth:** The great sea serpent of ancient legend, cousin to the Norse world serpent.
- **Personality / shape:** Calm and enormous. Coils in a circle.
- **Palette:** deep blue `#143CA0`, glowing spots `#3CE6F0` Neon, fins `#2A5AC8`, water orb Glass `#7FD4FF`.
- **Build:** long serpent body coiled in a ring around a floating Glass water orb, fan fins, glowing spots along the body.
- **Signature:** the ring of coils around a water orb.
- **Idle:** slowly circles its orb; bubbles rise; blue aura and light.

### Stormfire Dragon (breed only: Thunder Dragon x Phoenix)
- **Hybrid rule:** Thunder Dragon body + Phoenix wings.
- **Palette:** red-orange `#FF3C00`, lightning stripes `#FFE14A`, flame wings Neon `#FFB04A`, dark belly `#5A1E14`.
- **Build:** serpent body with antlers, two large phoenix flame wings, lightning stripes, rune sigil.
- **Signature:** serpent dragon with flame wings.
- **Idle:** S-curve flight; embers and lightning sparks mixed in its trail.

---

## 8. Divine

### Aether Dragon (breed only: Stormfire Dragon x Leviathan)
- **Concept:** A dragon made of the upper sky. The top chase pet in the game.
- **Palette:** see-through lavender-white body `#C8AAFF`, inner star particles, rune halo gold `#FFD86B`, light wings Neon `#E8DCFF`.
- **Build:** Glass serpent-dragon body with stars drifting inside it, gold rune ring behind the head (Elder Futhark runes), wings made of light planes, long flowing tail.
- **Signature:** you can see stars inside its body.
- **Idle:** slow, graceful flight; constellation trail; light beam on spawn; animated rainbow nameplate.

---

## 9. Review checklist

| Pet | Concept OK | Palette OK | Signature OK | Notes |
| --- | --- | --- | --- | --- |
| Imp | [ ] | [ ] | [ ] | |
| Fairy Sprite | [ ] | [ ] | [ ] | |
| Jackalope | [ ] | [ ] | [ ] | |
| Kitsune Kit | [ ] | [ ] | [ ] | |
| Gryphon Chick | [ ] | [ ] | [ ] | |
| Unicorn | [ ] | [ ] | [ ] | |
| Pegasus Foal | [ ] | [ ] | [ ] | |
| Sky Kitsune | [ ] | [ ] | [ ] | |
| Fire Drake | [ ] | [ ] | [ ] | |
| Frost Wyvern | [ ] | [ ] | [ ] | |
| Thunder Dragon | [ ] | [ ] | [ ] | |
| Phoenix | [ ] | [ ] | [ ] | |
| Emberhorn | [ ] | [ ] | [ ] | |
| Glacier Pegasus | [ ] | [ ] | [ ] | |
| Hydra | [ ] | [ ] | [ ] | |
| Leviathan | [ ] | [ ] | [ ] | |
| Stormfire Dragon | [ ] | [ ] | [ ] | |
| Aether Dragon | [ ] | [ ] | [ ] | |
