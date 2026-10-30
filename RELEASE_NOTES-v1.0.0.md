# Boo Knight — v1.0.0 release notes

First public release. Everything below is described from the shipped tree and the gates
recorded in [`LEDGER.md`](LEDGER.md), not from a plan.

## WHAT SHIPPED

- **3 levels + a boss.** Three hand-built side-scrolling levels; at the end of level 3 the
  **Vampire Lord** (10 HP) waits in a walled arena. Clearing the boss wins the game.
- **6 monster types**, each with its own health and touch damage: slime 2, ghost 3, zombie 4,
  skeleton 6, vampire 8, Vampire Lord 10 (touch damage 2 / 2 / 3 / 3 / 4 / 6).
- **4 swords found in chests.** You start with the wooden sword (damage 1); the chest in level
  1 holds **stone** (2), level 2's holds **iron** (3), level 3's holds **diamond** (5). A chest
  only ever upgrades — a weaker sword can't be picked up over a better one.
- **30 hearts + food.** Health is 30 HP shown as 15 hearts (2 HP each, with a half-heart HUD
  sprite). Apples heal 5, bread heals 10, never past full.
- **Death restarts the adventure.** Game over returns you to level 1 with the wooden sword and
  full hearts — deliberately the design, per the owner's rule law, not a missing save.
- **The 19-sprite RTX-3090 art set + 16 animation frames.** All 19 base sprites
  ([`docs/SPRITES.md`](docs/SPRITES.md)) were rendered locally on an RTX 3090; the animation
  pass added 16 QA-locked frames: hero walk A/B and attack A/B, slime squash/stretch, ghost
  float high/low, zombie, skeleton and vampire walk pairs, and the boss hover pair.
- **Facing and animation.** The hero and every monster flip to face the direction they move;
  the hero cycles a walk cycle and shows wind-up/follow-through attack frames, monsters cycle
  their two move frames while moving (the boss always hovers), hits flash white and deaths
  fade. Facing is code, not mirrored art.
- **Kid-friendly starts.** 3 seconds of contact immunity at the beginning of every run and
  every level, plus level 1's first slimes moved from 12 to 42 tiles away from the spawn.
- **Browser web build.** Godot 4.7.2 web export with threads off. The shipped build passes the
  rules gate (`sim.gd`, 24 assertions) and the headless smoke run that boots all three levels
  and the boss — which also prints `ANIM hero_walk=2 frames` and
  `FACING left_flip=true right_flip=false`, i.e. the animation and facing pass is asserted,
  not just present.

## KNOWN LIMITS

- **The level-exit door is a placeholder.** The exit marker reuses the treasure-chest sprite
  tinted green (`godot/src/level.gd`) until an art pass draws a real door. It works; it just
  looks like a green chest.
- **The web build needs a secure context.** Browsers refuse to start it from a plain
  `http://<LAN-IP>` address. Use `https://` (the home server answers on
  `https://192.168.5.231:8792/` with a self-signed certificate — accept the warning once) or
  `localhost` (e.g. `http://localhost:8791/`).
- **The tab is CPU-heavy while playing.** The render loop keeps running the whole time the
  game is open (≈45 rendered frames per second measured on the served build); on older laptops
  and tablets expect the fan to spin up.
- **Touch devices get on-screen buttons** (walk ◀ ▶, sword ⚔, jump ▲; multi-touch works).
  In portrait the view is cropped — play in **landscape**.
- There is no save or level select — the restart-from-level-1 rule above is the whole
  progress model.

## PROMISED-BUT-NOT-SHIPPED

Nothing. The acceptance list the game was promised against — **A1 through A7** in
[`docs/BRIEF-PARENT.md`](docs/BRIEF-PARENT.md) — shipped **and was verified**: A1, A5, A6 and
A7 in a real browser, A2–A5 also in the headless rules simulation, with the gate proven
red-capable (`--plant-bad` exits 1). This section is honestly empty.

Carried forward as open P-notes, not as broken promises:

- **P4 — door art.** The exit door still borrows the tinted chest sprite (see Known Limits).
  A door sprite is a small art task, nothing else depends on it.
- **P4/P3 — pit harshness, kept on purpose.** A blind synthetic play-through judged the mid-level
  pit jumps in level 1 as demanding for the age. A human child sees the pits before jumping
  into them, so the levels were left as built; the mitigation that *was* shipped is the 3-second
  spawn grace and the level-1 mob spacing. If a six-year-old keeps dying in the pits, that is
  the line to revisit first.
- **P4 — publishing.** The README and these notes are the GA docs promised in the build
  ledger; they ship with this release. The public play link
  <https://bryn1.github.io/boo-knight/> is published by this v1.0.0 release run — it was
  measured not-yet-live (HTTP 404) when these notes were written on 2026-10-30, and the
  home-network server was already serving the game.
