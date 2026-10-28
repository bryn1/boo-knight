# Boo Knight — sprite manifest (contract between art pass and code)

All files land in `assets/sprites/` as PNG. Characters/items: **transparent background**.
Style: cute, friendly, 8-bit NES-inspired retro game art, thick dark outlines, saturated colors,
NO gore, NO horror-scary faces — goofy-cute spooky. Generated on vm100's RTX 3090.

The engine shows them at small display sizes with nearest-neighbor filtering (pixel look).

| file | subject | gen size | in-game display | notes |
|---|---|---|---|---|
| hero.png | kid knight, teal armor + round helmet, sword at side, facing RIGHT | 256x320 | ~48 px tall | idle/hero shot, legs slightly apart |
| slime.png | green goo slime blob, big goofy eyes | 256x256 | ~36 px | HP 2 |
| ghost.png | round white cartoon ghost, wavy bottom, cute surprised face | 256x256 | ~40 px | HP 3, floats |
| zombie.png | small green cartoon zombie, goofy grin, tattered purple shirt | 256x320 | ~44 px | HP 4, walks |
| skeleton.png | cartoon skeleton with rusty sword, hollow-eye grin | 256x320 | ~48 px | HP 6, walks |
| vampire.png | small vampire kid, purple cape, fangs, friendly-mischievous | 256x320 | ~48 px | HP 8, dashes |
| vampire_lord.png | BOSS: big vampire lord, crown + cape, imposing but cartoonish | 512x512 | ~110 px | HP 10 |
| sword_wood.png | brown wooden sword icon, blade pointing UP | 256x256 | HUD item 24 px | dmg 1 (start gear) |
| sword_stone.png | grey stone sword icon, blade UP | 256x256 | 24 px | dmg 2 |
| sword_iron.png | shiny steel sword icon, blade UP | 256x256 | 24 px | dmg 3 |
| sword_diamond.png| cyan diamond crystal sword icon, blade UP, sparkle | 256x256 | 24 px | dmg 5 (best) |
| heart.png | red pixel-style heart with highlight, FULL | 256x256 | 12 px in HUD grid | 30 HP shown as 15 hearts x2HP |
| heart_half.png | same heart half-filled (bottom-left half red, rest dark) | 256x256 | 12 px | HUD |
| food_apple.png | shiny red apple with leaf | 256x256 | ~22 px | heals +5 HP |
| food_bread.png | golden bread loaf | 256x256 | ~26 px | heals +10 HP |
| chest.png | closed wooden treasure chest with gold bands, glowing seam | 256x256 | ~40 px | gear pickup container |
| tile_ground.png | SEAMLESS TILEABLE dark-purple mossy stone/grass-top ground tile | 512x512 | 16 px tile | must tile without seams |
| bg_night.png | 8-bit parallax background: night sky, huge friendly moon, rolling hills, spooky-but-cute forest silhouettes, few stars | 1536x1024 | fullscreen, opaque | no characters |
| title.png | title screen art: hero facing a horde of goofy spooky monsters, moonlit graveyard | 1536x1024 | fullscreen, opaque | big readable title text "BOO KNIGHT" |

Naming is FIXED — the code loads exactly these paths and falls back to colored placeholders
when a file is missing (so build and art pass are independent).
