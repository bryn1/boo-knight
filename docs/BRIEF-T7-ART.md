T7a (MC 11781) — Five ENCHANTED DIAMOND SWORDS, animated, on the vm100 3090. Owner ask 2026-10-31 verbatim: "When ine boss has died, a new level with upgraded monsters come before the next boss. Multiplyer of 1.25 per level, also introduce enchanted diamondswords with +1, +2,, +3, +4, +5, one per level with unique art including ice flames, lava, wind animations of the sword".

The named elements are ice, flames, lava, wind (four) + a fifth the closer chose and disclosed: STORM (lightning) for +5. Each sword = 3 frames: base (calm enchantment, = HUD icon + idle), _a and _b (animation cycle — only the ELEMENT EFFECT changes between frames; blade silhouette, angle and handle MUST be pixel-identical across the trio — this is the pair-consistency QA gate from T4a/T6a, here triple-consistency).

Style lock: imagegen EDIT mode, refs=[/home/claudecode/design-lab/library/2026/10/boo-knight/sword_diamond-1.png], prompt always begins "Keep this EXACT same sword shape, angle, outline, gold crossguard and handle; change only ..." background=transparent, 256x256, card=boo-knight. Never overwrite library files (bump -N suffix).

Elements (in depth order the code will use):
- ice (+1): frost-blue aura, tiny snowflake sparkles, blade edges rimed white; _a/_b sparkles twinkle (different pixels), rime constant.
- flame (+2): orange flame licks along the blade edge; _a/_b flame shape shifts (flicker), no color drift on the blade core.
- lava (+3): darkened blade with glowing molten cracks; _a/_b crack glow pulses (bright/dim), drips frozen (no gore-ish splatter, kid-friendly).
- wind (+4): teal-green swirl wisps curling around the blade; _a/_b swirl phase rotates half a turn.
- storm (+5): violet-white lightning arcs crackling between tip and guard; _a/_b arc jumps to a different branch.
All: cute retro game item icon, thick dark outline, saturated, single item centered, generous margins, no text.

Publish: assets/sprites/sword_diamond_<el>.png + _a/_b (15 files), byte-faithful from the accepted masters (same pipeline as kings: nearest-neighbour downscale to the 48x48 source the 24px in-game size needs — follow exactly how the king pngs were published). SPRITES.md manifest rows same commit (accepted masters + any dated rejects, replace-not-delete). Contact sheet .audits/swords-contact.png (all 15 in one image) read by the closer for QA: triple-consistency + no palette drift + correct element per sword.

DoD: 15 png files committed under assets/sprites/, SPRITES.md manifest updated in the same commit, contact sheet exists, evidence .audits/T7a-CLOSE.md carries sha256sum PROBE lines for the contact sheet (final state) and ends VERIFY_EXIT=0. GPU window closed after the batch.
