# Boo Knight — v1.2.0 release notes

The **Gauntlet Levels & Enchanted Swords** release, by owner requests 2026-10-31
(quoted verbatim in the repo briefs): levels between bosses, a ×1.25 multiplier,
and five animated enchanted diamond swords. Described from the shipped tree and
the gates in [`LEDGER.md`](LEDGER.md).

## WHAT SHIPPED

- **A new level after every boss** — when a boss falls, a generated **gauntlet level**
  of upgraded monsters stands between you and the next king. Reach its exit door and
  the next king is waiting in the arena.
- **Every gauntlet level is 25 % tougher, compounding, with no ceiling** — monster
  health AND damage multiply by 1.25 each level (your ruling, quoted in the law tests:
  the deep levels get genuinely beefy on purpose). The HUD shows the current multiplier
  (*Harder x1.3, x1.6, x2.0 …*).
- **Five enchanted diamond swords, one per gauntlet level**: **Ice +1**, **Flame +2**,
  **Lava +3**, **Wind +4**, **Storm +5** (damage 6 through 10, above the plain diamond's 5).
  Each has its own animated art — twinkling snowflakes, flickering flame, pulsing molten
  cracks, orbiting wind wisps, crackling lightning — shimmering in the hero's hand.
  (You named four elements for five swords; **Storm** is the closer's choice for the +5,
  disclosed and easy to swap.)
- **Levels are seeded per depth** — the same gauntlet depth always lays out the same
  level, so it's learnable, not random soup.
- Fix: the browser console is silent during play now — every engine warning about physics
  state during mob deaths, sword swings and level rebuilds was swept and deferred
  (re-measured live: ~190 warnings per 40 s of combat → 0).
- Death still resets everything: level 1, wooden sword, full hearts, multiplier and all
  enchanted swords. The house rule, unchanged.

## KNOWN LIMITS

- Everything still true from v1.0.0/v1.1.0: exit-door reuses tinted chest art; plain
  `http://<LAN-IP>` is refused by browsers (use https or localhost); heavy CPU while
  playing; play touch devices in landscape; a live-browser photo of the deepest gauntlet
  levels is gate-proven rather than photographed (reaching them needs a skilled run —
  your kids are the acceptance team).
- The uncapped multiplier means a very deep runner can meet monsters that take many,
  many swings — that is exactly what was asked for; the reset-on-death law is the brake.

## PROMISED-BUT-NOT-SHIPPED

Nothing. Levels-between-bosses, the uncapped ×1.25 on health and damage, and the five
+1…+5 enchanted swords with animated ice/flame/lava/wind (+ storm) art all shipped as
asked and are law-tested (68 sim assertions incl. the uncapped table, with the gate
proven red-capable).
