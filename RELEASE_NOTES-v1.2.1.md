# Boo Knight — v1.2.1 release notes

The **One Sword** hotfix, by owner bug photo + two follow-up asks, 2026-10-31
(quoted verbatim in the repo briefs): *"Thr hero has a sword attatchex to his head.
This is bad. The sword that is wielded should be visable only"*, *"Also attack
animation should be a sword.pointing straight forward in a sweeping motion, not ad it
is now"*, *"Also attack ramge could be increased slightly"*.

## WHAT SHIPPED

- **Exactly one sword — the wielded one.** The hero's artwork used to paint its own
  wooden sword AND the game drew the wielded sword on top of it, stuck near his head.
  All five hero frames were redrawn empty-handed (same knight, fists), so the sword you
  see is always the sword he holds: wooden sword static, enchanted diamonds shimmering
  (ice/flame/lava/wind/storm) right in his fist.
- **Forward-sweeping attack.** The attack is now a lunge: the sword winds up and
  **sweeps straight forward** through the punching arm and holds there for the hit —
  verified frame-by-frame in the browser (burst capture shows wind-up → forward drive
  → hold → recover).
- **Slightly longer reach.** The sword now connects a bit further ahead of the hero
  (reach law pinned by boundary tests: 28 px away = hit, 30 px = miss while standing).
- Death, the multiplier, gauntlet levels and all enchanted swords work exactly as in
  v1.2.0 — this release changes only how the sword looks and lands.

## KNOWN LIMITS

- Everything still true from v1.0.0–v1.2.0 (door art reuses chest art; use https or
  localhost on the LAN IP; landscape on phones; deepest gauntlet levels are gate-proven
  rather than photographed).
- The sweep reads best at normal speed; in stills the wind-up frame shows the blade
  raised — that is the wind-up doing its job.

## PROMISED-BUT-NOT-SHIPPED

Nothing. One visible sword, the straight-forward sweep and the longer reach all shipped
and were verified in the live browser build (79 law-assertions incl. the sweep +
reach boundary tests, with mutation proofs on both constants).
