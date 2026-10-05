# 04 — Eggs and Hatching

**Covers:** the 3 shop eggs, the Breeding Nest egg, and the hatch reveal · **Rules from:** `01_Art_Direction.md`

Prices and odds are unchanged from `GameConfig`. Odds stay visible in the shop before purchase.

---

## 1. Shop eggs

| Egg | Price | Size (studs) | Shell | Pattern | Stand / extra | Idle |
| --- | --- | --- | --- | --- | --- | --- |
| Hatchling Egg | 1,500 Ru | 1.6 | Cream `#F0E6C8`, SmoothPlastic | Brown speckles `#8C6A46` | Wrapped in a band of straw `#D8BE78` | Gentle wobble every few seconds |
| Mystic Egg | 250 Gems | 1.8 | Violet `#A06EFF` | Two glowing rune bands, Neon `#D8C4FF` | Floats 0.3 studs above a small mist cloud | Slow spin; runes pulse |
| Dragon Egg | 1,000 Gems | 2.0 | Crimson `#C83228`, scale-pattern decal | Glowing ember cracks, Neon `#FF8C3C` | Held in a gold claw stand `#FFBE28` | Heat shimmer; cracks pulse like breathing |

**Design logic:** each step up gets more magical. Hatchling = farmyard, Mystic = rune magic, Dragon = fire and treasure.

**Shop display:** each egg sits on a small pedestal at its shop with its name and the odds on a sign above it, coloured per tier.

---

## 2. Breeding Nest egg

- **Shape:** 3-stud egg resting in the nest.
- **Colour:** the result's rarity colour (already in the prototype), with a swirl decal so it doesn't look like a shop egg.
- **While breeding:** slow wobble; a countdown above it (already in the prototype).
- **Secret recipe:** a rune sigil circles the egg, so the player knows a hybrid is coming without spoiling which one.
- **Ready:** egg turns Neon and bounces; a small light beam rises from the nest so the owner can spot it from the village.

---

## 3. Hatch reveal sequence

Plays when a player hatches an egg or collects from the nest. Total about 3 seconds; tapping skips it.

1. **Spawn (0.0 s):** the egg appears in front of the camera on a dark vignette.
2. **Shake (0.0–1.5 s):** three shakes, each stronger. Higher tiers shake faster.
3. **Crack (1.5 s):** crack lines appear; light leaks out in the **pet's rarity colour** (the first hint).
4. **Burst (2.0 s):** shell pieces fly out. Legendary and up add a light beam; Mythic adds a screen shake; Divine adds a rainbow flash.
5. **Reveal (2.2–3.0 s):** the pet spins in, name and tier in big text (the current reveal text, kept).

| Tier | Crack light | Burst extra | Sound |
| --- | --- | --- | --- |
| Common / Uncommon | Grey / green | None | Soft pop |
| Rare | Blue | Sparkles | Chime |
| Epic | Purple | Motes swirl in | Bigger chime |
| Legendary | Gold | Light beam | Fanfare |
| Mythic | Red | Beam + screen shake | Roar + fanfare |
| Divine | Cyan | Beam + rainbow flash | Choir + fanfare |

---

## 4. Review checklist

| Item | Look OK | Notes |
| --- | --- | --- |
| Hatchling Egg | [ ] | |
| Mystic Egg | [ ] | |
| Dragon Egg | [ ] | |
| Breeding Nest egg | [ ] | |
| Hatch reveal sequence | [ ] | |
