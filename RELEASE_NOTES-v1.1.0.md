# Boo Knight — v1.1.0 release notes

The **Boss-King Gauntlet** release, by owner request 2026-10-30: the Vampire Lord got
gentler, and the game now continues past him into an escalating run of kings.
Described from the shipped tree and the gates in [`LEDGER.md`](LEDGER.md).

## WHAT SHIPPED

- **A gentler Vampire Lord** — 6 hearts of health (was 10) and he bumps you for 3 (was 6),
  so a 6-year-old can actually beat him.
- **The Boss-King Gauntlet** — when the Vampire Lord goes down, the game does not end.
  The **Slime King**, **Ghost King**, **Zombie King** and **Skeleton King** arrive one
  after the other in the arena.
- **Every boss beaten hardens the ordinary monsters** — +1 heart of health and +1 bump
  for regular mobs per boss kill, capped at **Harder x3** so it stays playable; kings
  themselves keep their own fixed strength.
- **The kings return** — after the Skeleton King the ladder restarts at the Slime King,
  with whatever hardening is earned. There is no victory screen; it is one crown at a
  time, forever if you dare.
- **Four new boss kings drawn on the home 3090** — crowns, capes, a ghost whose crown
  floats because ghosts cannot wear one, and a Slime King who sceptered himself with a
  soup spoon (kept on purpose).
- Dying still resets everything (level 1, wooden sword, full hearts, Harder x0) — the
  house rule, unchanged.
- The HUD names the current boss and shows the Harder marker.
- Fix: slain monsters no longer spam engine errors into the browser console
  (physics teardown deferred out of the physics step).

## KNOWN LIMITS

- Everything still true from v1.0.0: the exit door reuses tinted chest art; plain
  `http://<LAN-IP>` is refused by browsers (use https or localhost); the tab is
  CPU-heavy while playing; touch devices should play in landscape.
- One visual leg (a king photographed inside a live browser run) was verified through
  the automated runtime gate instead of a screenshot — reaching the arena requires
  clearing two full levels, which the test driver cannot do reliably. The kings' art
  files load and animate through the same tested pipeline as every other sprite.

## PROMISED-BUT-NOT-SHIPPED

Nothing. The owner's request — easier lord, harder-after-each-boss run with the four
named kings, in his order — shipped exactly as asked and is law-tested (40 simulation
assertions on the numbers, cycle, caps and resets, with the gate proven red-capable).
