T4b-code (Boo Knight animation wiring + facing). Repo /home/claudecode/Games/boo-knight, Godot 4.7.2 at /home/claudecode/Games/.tools/godot/Godot_v4.7.2-stable_linux.x86_64, project in godot/. Read godot/src/art.gd (single-texture loader + placeholder VIS fallback), player.gd, mob.gd, game.gd BEFORE editing.

Deliver ONE commit that:
1. Extends the art loader to load FRAME LISTS (assets/sprites/<key>_walk_a.png etc.) while keeping the existing single-texture + placeholder behavior when a frame file is missing (headless/no-art must still run).
2. Hero: cycles the 2 walk frames while grounded and moving (~6-8 fps is enough for 8-bit feel); holds hero_attack_a then hero_attack_b during the attack action window; idle frame when standing.
3. Hero FACES THE DIRECTION IT IS WALKING: horizontal input sets facing (right default, matching the art); facing persists while attacking/jumping so the swing direction matches the sprite; visual flip only — do NOT change hitbox math or any rules.gd number.
4. Mobs (slime/ghost/zombie/skeleton/vampire) cycle their 2 move frames while moving; vampire_lord cycles its float frames always; mobs face their movement direction (same flip_h mechanism).
5. Gates stay green: sim exit 0 and sim -- --plant-bad exit 1 (rule numbers untouched, so this must hold); smoke scene exit 0, and ADD a smoke assertion that a walk frame LIST is real when the art is present (frames>1 for hero walk) and that flip state follows a simulated left input; mutation-prove the new assertion goes RED, then revert.
6. Web export exit 0, fresh files copied into /home/claudecode/Games/boo-knight/build/web/ (the systemd boo-knight.service serves that dir — do not restart it, the pck is picked up on next page load).
Evidence /home/claudecode/Games/boo-knight/.audits/T4-CODE-RESULT.md with the gate exit codes measured WITHOUT PIPES (redirect + echo $?) and the commit SHA, ending "# VERDICT: PASS". Commit author: git -c user.name="code (11612)" -c user.email="code@agent-town.local" commit.
DoD: that evidence file exists, ends "# VERDICT: PASS", and the named commit is on master.
